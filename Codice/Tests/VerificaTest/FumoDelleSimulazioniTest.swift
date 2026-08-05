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
                       "campagna_distanze", "campagna_uscite_libere",
                       "campagna_distribuzione_gruppi", "campagna_riepilogo"] {
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


    /// Il blocco di riepilogo è ciò da cui il resoconto copia i numeri: se i suoi
    /// totali potessero discostarsi dalle righe di dettaglio, avrei soltanto
    /// spostato l'errore dalla mia testa al programma. Questa prova li pareggia.
    func test_incarico_il_riepilogo_pareggia_con_le_righe_di_dettaglio() throws {
        let rapporto = try programma(fumo: false).esegui()
        func sezione(_ nome: String) throws -> Rapporto.Sezione {
            try XCTUnwrap(rapporto.sezioni.first { $0.nome == nome })
        }
        let riepilogo = try sezione("campagna_riepilogo")
        func valore(_ voce: String) throws -> Int {
            let riga = try XCTUnwrap(riepilogo.righe.first { $0[0] == voce }, "voce mancante: \(voce)")
            return try XCTUnwrap(Int(riga[1]))
        }
        let invarianti = try sezione("campagna_invarianti")
        func colonna(_ nome: String) throws -> Int { try XCTUnwrap(invarianti.intestazione.firstIndex(of: nome)) }
        let cGiornate = try colonna("giornate"), cOrdini = try colonna("ordini")
        let cViolazioni = try colonna("violazioni"), cSenza = try colonna("senza_destinazione")

        XCTAssertEqual(try valore("scenari_di_campagna_generati"), invarianti.righe.count)
        XCTAssertEqual(try valore("giornate_generate_in_totale"),
                       invarianti.righe.reduce(0) { $0 + (Int($1[cGiornate]) ?? 0) })
        XCTAssertEqual(try valore("ordini_impartiti_in_totale"),
                       invarianti.righe.reduce(0) { $0 + (Int($1[cOrdini]) ?? 0) })
        XCTAssertEqual(try valore("violazioni_trovate_in_totale"),
                       invarianti.righe.reduce(0) { $0 + (Int($1[cViolazioni]) ?? 0) })
        XCTAssertEqual(try valore("ordini_a_gruppi_senza_alcuna_destinazione"),
                       invarianti.righe.reduce(0) { $0 + (Int($1[cSenza]) ?? 0) })
        XCTAssertEqual(try valore("invarianti_sorvegliati"),
                       SondaInvariantiCampagna.codiciNoti.count)

        // La distribuzione pareggia anch'essa con il dettaglio.
        let distribuzione = try sezione("campagna_distribuzione_gruppi")
        XCTAssertEqual(distribuzione.righe.reduce(0) { $0 + (Int($1[2]) ?? 0) },
                       try valore("giornate_generate_in_totale"))
    }

    /// La generazione deve coprire la parte alta della distribuzione: gli invarianti
    /// che si rompono con molti gruppi sparpagliati non sono provati da giornate con
    /// due gruppi vicini. Nella prima unità la generazione si fermava a cinque
    /// gruppi e non esercitava mai lo stipamento; questa prova impedisce che ci si
    /// torni riducendo gli scenari.
    func test_incarico_6_la_generazione_copre_la_parte_alta_della_distribuzione() throws {
        let rapporto = try programma(fumo: false).esegui()
        let distribuzione = try XCTUnwrap(
            rapporto.sezioni.first { $0.nome == "campagna_distribuzione_gruppi" })
        let conteggi = distribuzione.righe.compactMap { Int($0[0]) }
        XCTAssertTrue(conteggi.contains { $0 >= 8 },
                      "nessuna giornata generata con otto o più gruppi")
        XCTAssertTrue(conteggi.contains(1), "manca il caso del gruppo solo")
        XCTAssertGreaterThanOrEqual(Set(conteggi).count, 6,
                                    "la distribuzione deve toccare almeno sei conteggi diversi")
        // E lo stipamento va davvero esercitato: se nessun gruppo resta mai senza
        // destinazione, il caso in cui la marcia non si offre non è stato provato.
        let riepilogo = try XCTUnwrap(rapporto.sezioni.first { $0.nome == "campagna_riepilogo" })
        let senza = try XCTUnwrap(riepilogo.righe.first { $0[0] == "ordini_a_gruppi_senza_alcuna_destinazione" })
        XCTAssertGreaterThan(try XCTUnwrap(Int(senza[1])), 0,
                             "nessuna corsa ha esercitato lo stipamento")
    }

    /// La misura del costo di chiusura di una giornata è una CURVA e non un punto:
    /// deve coprire tutto l'intervallo dei gruppi generati e le due disposizioni,
    /// perché il numero dei gruppi e la loro dispersione sono cause distinte. Nella
    /// prima unità di questa misura esisteva un punto solo.
    func test_incarico_7_la_misura_dei_passi_e_una_curva_e_non_un_punto() throws {
        let rapporto = try programma(fumo: false).esegui()
        let sezione = try XCTUnwrap(rapporto.sezioni.first { $0.nome == "campagna_passi_per_giornata" })
        func colonna(_ nome: String) throws -> Int {
            try XCTUnwrap(sezione.intestazione.firstIndex(of: nome), "colonna mancante: \(nome)")
        }
        let cMappa = try colonna("mappa"), cDisposizione = try colonna("disposizione")
        let cGruppi = try colonna("gruppi")
        let cConIlSalto = try colonna("con_il_salto"), cSenza = try colonna("senza_il_salto")

        let gruppi = Set(sezione.righe.compactMap { Int($0[cGruppi]) })
        XCTAssertGreaterThanOrEqual(gruppi.count, 12,
                                    "la curva deve avere almeno dodici punti in ascissa")
        XCTAssertEqual(gruppi.min(), 1)
        XCTAssertEqual(gruppi.max(), 12)
        XCTAssertEqual(Set(sezione.righe.map { $0[cDisposizione] }),
                       Set(BancoCampagna.Disposizione.allCases.map(\.rawValue)),
                       "entrambe le disposizioni, raccolti e sparpagliati")

        // Il costo con il salto è lineare nel numero dei gruppi e indifferente alla
        // dispersione: è ciò che il salto diretto compra, e va misurato, non detto.
        for riga in sezione.righe {
            let n = try XCTUnwrap(Int(riga[cGruppi]))
            XCTAssertEqual(Int(riga[cConIlSalto]), n * 3,
                           "con il salto ogni gruppo costa tre passi, \(riga[cMappa])")
            XCTAssertGreaterThanOrEqual(try XCTUnwrap(Int(riga[cSenza])), n * 2)
        }
        // Senza il salto la dispersione non fa mai risparmiare, e sulla mappa grande
        // — dove c'è spazio perché le due disposizioni differiscano davvero — costa
        // strettamente di più. Sul quattro per quattro con molti gruppi le due
        // disposizioni coincidono, perché i gruppi riempiono la mappa: non è una
        // smentita, è il caso limite dello stipamento.
        var almenoUnaDifferenzaStretta = false
        for mappa in Set(sezione.righe.map { $0[cMappa] }) {
            for n in gruppi where n > 1 {
                let righe = sezione.righe.filter { $0[cMappa] == mappa && Int($0[cGruppi]) == n }
                guard righe.count == 2 else { continue }
                let raccolti = try XCTUnwrap(righe.first { $0[cDisposizione] == "raccolti" })
                let sparsi = try XCTUnwrap(righe.first { $0[cDisposizione] == "sparpagliati" })
                let costoSparsi = try XCTUnwrap(Int(sparsi[cSenza]))
                let costoRaccolti = try XCTUnwrap(Int(raccolti[cSenza]))
                XCTAssertGreaterThanOrEqual(costoSparsi, costoRaccolti,
                                            "\(mappa) con \(n) gruppi: la dispersione fa risparmiare?")
                if costoSparsi > costoRaccolti { almenoUnaDifferenzaStretta = true }
            }
        }
        XCTAssertTrue(almenoUnaDifferenzaStretta,
                      "la dispersione non pesa in alcun punto della curva: la misura non la vede")
    }

    /// Le colonne dichiarano la grandezza che stampano. La distanza fra i due
    /// quartier generali non è la traversata della mappa, e le due compaiono
    /// affiancate proprio perché non si possano leggere l'una per l'altra.
    func test_incarico_7_le_colonne_delle_distanze_nominano_cio_che_misurano() throws {
        let rapporto = try programma(fumo: false).esegui()
        let sezione = try XCTUnwrap(rapporto.sezioni.first { $0.nome == "campagna_distanze" })
        XCTAssertEqual(sezione.intestazione,
                       ["mappa", "formato", "lato", "distanza_fra_quartier_generali",
                        "distanza_massima_fra_due_caselle", "giornate_per_congiungerli"])
        let cLato = try XCTUnwrap(sezione.intestazione.firstIndex(of: "lato"))
        let cQg = try XCTUnwrap(sezione.intestazione.firstIndex(of: "distanza_fra_quartier_generali"))
        let cMax = try XCTUnwrap(sezione.intestazione.firstIndex(of: "distanza_massima_fra_due_caselle"))
        for riga in sezione.righe {
            let lato = try XCTUnwrap(Int(riga[cLato]))
            XCTAssertEqual(Int(riga[cMax]), (lato - 1) * 2,
                           "la distanza massima è quella fra angoli opposti")
            XCTAssertLessThanOrEqual(try XCTUnwrap(Int(riga[cQg])), try XCTUnwrap(Int(riga[cMax])),
                                     "i due quartier generali non possono distare più del massimo")
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
