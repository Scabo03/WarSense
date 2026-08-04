import XCTest
import Verifica
import Motore
import Dati
import Contenuti

/// Il fumo delle simulazioni (05 §14.7): una corsa breve del programma di verifica
/// fa parte del collaudo, perché Motore e Dati restino simulabili senza interfaccia,
/// che è un requisito e non un accessorio (00 §16.1).
final class FumoDelleSimulazioniTest: XCTestCase {

    func programma(fumo: Bool = true) -> ProgrammaDiVerifica {
        ProgrammaDiVerifica(cartellaValori: Contenuti.valoriDiFabbrica,
                            cartellaScenari: Contenuti.scenariDiVerifica,
                            cartellaScenariCampagna: Verifica.Ambiente.scenariCampagnaDiFabbrica,
                            fumo: fumo)
    }

    func test_05_14_7_il_fumo_delle_simulazioni_corre_e_produce_ogni_sezione() throws {
        let rapporto = try programma().esegui()
        let nomi = rapporto.sezioni.map(\.nome)
        for atteso in ["versione", "scontri", "riepilogo_scontri", "soglie_di_resa",
                       "composizioni", "bersagli_di_schieramento", "modificatori",
                       "curva_del_tiro", "accerchiamento",
                       // La campagna entra nel fumo come gli scontri (05 §14.7).
                       "campagna_invarianti", "campagna_passi_per_giornata",
                       "campagna_attraversamento", "campagna_caselle_raggiungibili"] {
            XCTAssertTrue(nomi.contains(atteso), "sezione mancante: \(atteso)")
        }
        for sezione in rapporto.sezioni {
            XCTAssertFalse(sezione.righe.isEmpty, "sezione vuota: \(sezione.nome)")
            for riga in sezione.righe {
                XCTAssertEqual(riga.count, sezione.intestazione.count,
                               "riga disallineata in \(sezione.nome): \(riga)")
            }
        }
    }

    /// L'uscita è riproducibile: a parità di valori e di scenari due corse danno
    /// esattamente lo stesso testo (05 §12.6). È possibile perché la battaglia non
    /// contiene alcuna estrazione del caso (01 §12.1).
    func test_05_12_6_l_uscita_e_riproducibile() throws {
        let prima = try programma().esegui().testo
        let seconda = try programma().esegui().testo
        XCTAssertEqual(prima, seconda, "due corse identiche devono dare lo stesso rapporto")
        XCTAssertFalse(prima.isEmpty)
    }

    /// La sezione degli invarianti di campagna non ammette eccezioni: la colonna
    /// delle violazioni vale zero su ogni scenario, altrimenti la corsa ha trovato
    /// un difetto e il collaudo lo dichiara qui, non in un rapporto da leggere.
    func test_incarico_6_il_fumo_non_trova_alcuna_violazione_di_campagna() throws {
        let rapporto = try programma().esegui()
        let sezione = try XCTUnwrap(rapporto.sezioni.first { $0.nome == "campagna_invarianti" })
        let colonna = try XCTUnwrap(sezione.intestazione.firstIndex(of: "violazioni"))
        let dettaglio = try XCTUnwrap(sezione.intestazione.firstIndex(of: "dettaglio"))
        for riga in sezione.righe {
            XCTAssertEqual(riga[colonna], "0",
                           "violazione di invariante nello scenario \(riga[0]): \(riga[dettaglio])")
        }
    }

    /// Gli scenari sono file dichiarativi: aggiungerne uno non richiede di toccare
    /// il programma (03 §9.6, 05 §12.2), e un asse ignoto è respinto in caricamento.
    func test_05_12_2_gli_scenari_sono_dichiarativi_e_sostituibili() throws {
        let caricati = try CartellaScenari.carica(da: Contenuti.scenariDiVerifica)
        XCTAssertGreaterThanOrEqual(caricati.scenari.count, 2)
        XCTAssertTrue(caricati.scenari.allSatisfy { !$0.assi.isEmpty })

        // Una cartella con uno scenario aggiunto a mano viene letta senza ricompilare.
        let cartella = FileManager.default.temporaryDirectory
            .appendingPathComponent("scenari-" + UUID().uuidString)
        try FileManager.default.copyItem(at: Contenuti.scenariDiVerifica, to: cartella)
        addTeardownBlock { try? FileManager.default.removeItem(at: cartella) }
        let originale = try Data(contentsOf: cartella.appendingPathComponent("scontro-speculare.json"))
        var voce = try JSONSerialization.jsonObject(with: originale) as! [String: Any]
        voce["identificatore"] = "aggiunto_a_mano"
        try JSONSerialization.data(withJSONObject: voce)
            .write(to: cartella.appendingPathComponent("zz-aggiunto.json"))
        let dopo = try CartellaScenari.carica(da: cartella)
        XCTAssertEqual(dopo.scenari.count, caricati.scenari.count + 1)
        XCTAssertTrue(dopo.scenari.contains { $0.identificatore == "aggiunto_a_mano" })

        // Un asse fuori dall'insieme chiuso è respinto, non ignorato in silenzio.
        voce["assi"] = ["asse_inesistente"]
        try JSONSerialization.data(withJSONObject: voce)
            .write(to: cartella.appendingPathComponent("zz-aggiunto.json"))
        XCTAssertThrowsError(try CartellaScenari.carica(da: cartella))
    }

    /// I vantaggi nascosti sono noti al programma e disattivabili da esso (01 §13.1,
    /// 03 §7.1, 05 §12.5): spenti, ogni interruttore è falso e ogni riduzione neutra.
    func test_05_12_5_i_vantaggi_nascosti_sono_disattivabili() throws {
        let accesi = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        XCTAssertTrue(accesi.vantaggi.ritirataAvversariaSoloUltimaRiga)
        XCTAssertTrue(accesi.vantaggi.annientamentoSimultaneoAlGiocatore)
        XCTAssertLessThan(accesi.vantaggi.riduzionePropensioneRitirataAvversaria, .uno)

        try ValoriVariati.con(base: Contenuti.valoriDiFabbrica,
                              sostituendo: ValoriVariati.vantaggiSpenti) { spenti in
            XCTAssertFalse(spenti.vantaggi.ritirataAvversariaSoloUltimaRiga)
            XCTAssertFalse(spenti.vantaggi.annientamentoSimultaneoAlGiocatore)
            XCTAssertEqual(spenti.vantaggi.riduzionePropensioneRitirataAvversaria, .uno)
            // Spenti, le due parti hanno la medesima soglia di resa: è la condizione
            // in cui si misura la probabilità reale sottostante.
            let motore = MotoreBattaglia(valori: spenti)
            let ufficiale = spenti.ufficiali.values.sorted { $0.identificatore < $1.identificatore }[0]
            let soglie = Parte.allCases.map {
                TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: $0).sogliaDiResa
            }
            XCTAssertEqual(soglie[0], soglie[1])
        }
    }

    /// La taratura della fase C ha reso raggiungibile la soglia di resa di ogni
    /// ufficiale e per entrambe le parti (03 §6.1, §6.5): senza, ogni battaglia
    /// dovrebbe concludersi per annientamento.
    func test_03_6_5_la_resa_e_raggiungibile_per_ogni_ufficiale() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let motore = MotoreBattaglia(valori: valori)
        for identificatore in valori.ufficiali.keys.sorted() {
            for parte in Parte.allCases {
                let tattico = TatticoBattaglia(motore: motore,
                                               ufficiale: valori.ufficiali[identificatore]!, parte: parte)
                XCTAssertLessThan(tattico.sogliaDiResa, .uno,
                                  "\(identificatore)/\(parte.rawValue): soglia irraggiungibile")
            }
        }
    }

    /// Ogni scenario conclude entro il proprio tetto di giri: una corsa che non
    /// conclude non misura nulla (05 §12.6).
    func test_05_12_6_ogni_configurazione_conclude() throws {
        let caricati = try CartellaScenari.carica(da: Contenuti.scenariDiVerifica)
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let motore = MotoreBattaglia(valori: valori)
        let ufficiali = valori.ufficiali.keys.sorted()
        for scenario in caricati.scenari {
            let banco = BancoScontri(motore: motore, scenario: scenario)
            for configurazione in BancoScontri.configurazioni(di: scenario, ufficiali: ufficiali) {
                let corsa = try banco.gioca(configurazione)
                XCTAssertTrue(corsa.concluso,
                              "\(scenario.identificatore) non conclude: \(configurazione)")
                XCTAssertNotNil(corsa.modo)
            }
        }
    }
}
