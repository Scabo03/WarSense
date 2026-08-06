import XCTest
import Verifica
import Motore
import Dati
import Contenuti

/// La misura del corpo a corpo (incarico 09). Ogni prova è intestata al punto
/// dell'incarico che verifica. Le prove che contano non sono le misure — quelle sono
/// numeri da leggere — ma i CANCELLI: il riepilogo che pareggia con il dettaglio
/// (RDA-71), la soglia disattivata che davvero non fa disingaggiare, la provenienza
/// che non perde né inventa una perdita, l'insieme degli accoppiamenti senza buchi.
final class MisuraMischiaTest: XCTestCase {

    func programma() -> ProgrammaDiVerifica {
        // Senza campagna: la mischia non dipende dalla campagna, e la corsa è più breve.
        ProgrammaDiVerifica(cartellaValori: Contenuti.valoriDiFabbrica,
                            cartellaScenari: Contenuti.scenariDiVerifica,
                            cartellaScenariCampagna: nil, fumo: false)
    }

    private func banchi(valori: ValoriDiGioco) throws -> BanchiDiMisura {
        let parametri = try CartellaScenari.carica(da: Contenuti.scenariDiVerifica).banchi
        return BanchiDiMisura(motore: MotoreBattaglia(valori: valori), banchi: parametri)
    }

    private func soglieReali(_ valori: ValoriDiGioco) -> [IdentificatoreDati: Scalato?] {
        valori.archetipi.mapValues { $0.sogliaDisingaggio }
    }

    // MARK: - RDA-71: il riepilogo pareggia con le righe di dettaglio

    /// Il blocco `mischia_riepilogo` è ciò da cui il resoconto copia i numeri: se i suoi
    /// totali potessero discostarsi dalle righe, l'errore sarebbe solo spostato dal capo
    /// al programma. Questa prova li pareggia, come già per la campagna (RDA-71).
    func test_incarico09_il_riepilogo_mischia_pareggia_con_le_righe_di_dettaglio() throws {
        let rapporto = try programma().esegui()
        func sezione(_ nome: String) throws -> Rapporto.Sezione {
            try XCTUnwrap(rapporto.sezioni.first { $0.nome == nome }, "sezione mancante: \(nome)")
        }
        let riepilogo = try sezione("mischia_riepilogo")
        func valore(_ voce: String) throws -> Int {
            let riga = try XCTUnwrap(riepilogo.righe.first { $0[0] == voce }, "voce mancante: \(voce)")
            return try XCTUnwrap(Int(riga[1]))
        }
        let fotografia = try sezione("mischia_fotografia")
        let accoppiamenti = try sezione("mischia_accoppiamenti")
        let provenienza = try sezione("provenienza_perdite")

        func colonna(_ s: Rapporto.Sezione, _ nome: String) throws -> Int {
            try XCTUnwrap(s.intestazione.firstIndex(of: nome), "colonna mancante: \(nome)")
        }

        // Fotografia: i conteggi degli esiti pareggiano le righe e sommano al totale.
        XCTAssertEqual(try valore("accoppiamenti_totali"), fotografia.righe.count)
        XCTAssertEqual(try valore("accoppiamenti_totali"), accoppiamenti.righe.count)
        let cEsitoFoto = try colonna(fotografia, "esito")
        let cChiSfila = try colonna(fotografia, "chi_si_sfila")
        let disingaggi = fotografia.righe.filter { $0[cChiSfila] != "" }.count
        XCTAssertEqual(try valore("fotografia_disingaggio"), disingaggi)
        let disfattaB = fotografia.righe.filter { $0[cEsitoFoto] == "disfatta_bersaglio" }.count
        let disfattaA = fotografia.righe.filter { $0[cEsitoFoto] == "disfatta_attaccante" }.count
        let disfattaR = fotografia.righe.filter { $0[cEsitoFoto] == "disfatta_reciproca" }.count
        let tetto = fotografia.righe.filter { $0[cEsitoFoto] == "tetto" }.count
        XCTAssertEqual(try valore("fotografia_disfatta_bersaglio"), disfattaB)
        XCTAssertEqual(try valore("fotografia_disfatta_attaccante"), disfattaA)
        XCTAssertEqual(try valore("fotografia_disfatta_reciproca"), disfattaR)
        XCTAssertEqual(try valore("fotografia_tetto"), tetto)
        XCTAssertEqual(disingaggi + disfattaB + disfattaA + disfattaR + tetto,
                       try valore("accoppiamenti_totali"),
                       "ogni accoppiamento ha uno e un solo esito")

        // Distruzione (soglia disattivata): i conteggi pareggiano le righe della crux.
        let cVincitore = try colonna(accoppiamenti, "vincitore")
        let cTurniSoglia = try colonna(accoppiamenti, "turni_soglia_bersaglio")
        let cTurniDistr = try colonna(accoppiamenti, "turni_distruzione_bersaglio")
        let vinceAttaccante = accoppiamenti.righe.filter { $0[cVincitore] == "attaccante" }.count
        let vinceBersaglio = accoppiamenti.righe.filter { $0[cVincitore] == "bersaglio" }.count
        let reciproca = accoppiamenti.righe.filter { $0[cVincitore] == "nessuno" }.count
        let alTetto = accoppiamenti.righe.filter { $0[cVincitore] == "nessuno_al_tetto" }.count
        XCTAssertEqual(try valore("distruzione_bersaglio_conteggio"), vinceAttaccante)
        XCTAssertEqual(try valore("distruzione_attaccante_conteggio"), vinceBersaglio)
        XCTAssertEqual(try valore("distruzione_reciproca_conteggio"), reciproca)
        XCTAssertEqual(try valore("distruzione_tetto_conteggio"), alTetto)
        XCTAssertEqual(vinceAttaccante + vinceBersaglio + reciproca + alTetto,
                       accoppiamenti.righe.count)
        let scattaPrima = accoppiamenti.righe.filter { riga -> Bool in
            let s = Int(riga[cTurniSoglia]) ?? 0, d = Int(riga[cTurniDistr]) ?? 0
            return s > 0 && (d == 0 || s < d)
        }.count
        XCTAssertEqual(try valore("accoppiamenti_soglia_scatta_prima_della_distruzione"), scattaPrima)

        // Provenienza: i totali pareggiano la somma delle righe, e tiro + mischia = totale.
        XCTAssertEqual(try valore("battaglie_generate_totali"), provenienza.righe.count)
        func colonnaProv(_ nome: String) throws -> Int { try colonna(provenienza, nome) }
        let cTiroG = try colonnaProv("perdite_tiro_giocatore")
        let cTiroA = try colonnaProv("perdite_tiro_avversario")
        let cMisG = try colonnaProv("perdite_mischia_giocatore")
        let cMisA = try colonnaProv("perdite_mischia_avversario")
        let cDist = try colonnaProv("distruzioni_in_mischia")
        let tiro = provenienza.righe.reduce(0) { $0 + (Int($1[cTiroG]) ?? 0) + (Int($1[cTiroA]) ?? 0) }
        let mischia = provenienza.righe.reduce(0) { $0 + (Int($1[cMisG]) ?? 0) + (Int($1[cMisA]) ?? 0) }
        XCTAssertEqual(try valore("perdite_da_tiro_totali"), tiro)
        XCTAssertEqual(try valore("perdite_da_mischia_totali"), mischia)
        XCTAssertEqual(try valore("perdite_totali"), tiro + mischia)
        let senzaDist = provenienza.righe.filter { (Int($0[cDist]) ?? 0) == 0 }.count
        let conDist = provenienza.righe.filter { (Int($0[cDist]) ?? 0) > 0 }.count
        XCTAssertEqual(try valore("battaglie_senza_distruzione_in_mischia"), senzaDist)
        XCTAssertEqual(try valore("battaglie_con_distruzione_in_mischia"), conDist)
        XCTAssertEqual(senzaDist + conDist, provenienza.righe.count)
        let cReingaggi = try colonnaProv("reingaggi")
        let cDisingaggi = try colonnaProv("disingaggi")
        XCTAssertEqual(try valore("reingaggi_totali"),
                       provenienza.righe.reduce(0) { $0 + (Int($1[cReingaggi]) ?? 0) })
        XCTAssertEqual(try valore("disingaggi_automatici_totali"),
                       provenienza.righe.reduce(0) { $0 + (Int($1[cDisingaggi]) ?? 0) })
        XCTAssertEqual(try valore("battaglie_con_almeno_un_reingaggio"),
                       provenienza.righe.filter { (Int($0[cReingaggi]) ?? 0) > 0 }.count)
    }

    // MARK: - Terzo punto: la soglia disattivata è un artificio di misura che davvero disattiva

    /// Il cancello dell'artificio: a soglia portata a 1,0 su ogni archetipo, nessuna
    /// corsa di mischia finisce per disingaggio; a soglia attiva, molte sì. Se
    /// l'artificio non cambiasse nulla, non sarebbe un artificio ma un'illusione.
    func test_incarico09_soglia_disattivata_nessun_disingaggio() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let soglie = soglieReali(valori)

        // Soglia attiva: esistono disingaggi.
        let attive = try banchi(valori: valori).corseMischia(soglieReali: soglie)
        XCTAssertTrue(attive.contains { $0.esito.hasPrefix("disingaggio") },
                      "a soglia attiva la mischia deve poter finire per disingaggio")

        // Soglia disattivata: nessun disingaggio, in alcun accoppiamento.
        try ValoriVariati.con(base: Contenuti.valoriDiFabbrica,
                              inElenco: ValoriVariati.disingaggioDisattivato) { valoriV in
            let disattivate = try self.banchi(valori: valoriV).corseMischia(soglieReali: soglie)
            XCTAssertFalse(disattivate.contains { $0.esito.hasPrefix("disingaggio") },
                           "a soglia disattivata nessun contatto si sfila: prosegue fino alla distruzione")
            // E ogni corsa conclude entro il tetto: nessun accoppiamento resta al tetto.
            XCTAssertFalse(disattivate.contains { $0.esito == "tetto" },
                           "il tetto degli scambi è scelto sopra il serbatoio più grosso")
        }
    }

    /// L'artificio è ciò che dichiara di essere: `disingaggioDisattivato` porta la soglia
    /// di OGNI archetipo a 1,0, passa dal caricatore vero senza essere respinta (05 §7.8
    /// ammette la soglia in (0, 1]), e la fabbrica di gioco resta intatta (le soglie di
    /// fabbrica sono minori di 1). Non tocca il Motore né i file di gioco.
    func test_incarico09_disingaggio_disattivato_porta_la_soglia_a_uno() throws {
        let fabbrica = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        XCTAssertTrue(fabbrica.archetipi.values.allSatisfy { ($0.sogliaDisingaggio.map { $0 < .uno }) ?? true },
                      "di fabbrica ogni soglia presente è minore di uno: c'è qualcosa da disattivare")

        try ValoriVariati.con(base: Contenuti.valoriDiFabbrica,
                              inElenco: ValoriVariati.disingaggioDisattivato) { valoriV in
            XCTAssertEqual(valoriV.archetipi.count, fabbrica.archetipi.count,
                           "nessun archetipo perso o aggiunto dall'artificio")
            // Anche l'elitario, che di fabbrica non ha soglia, riceve 1,0: a soglia
            // disattivata ogni corsa prosegue fino alla distruzione.
            for (id, a) in valoriV.archetipi {
                XCTAssertEqual(try XCTUnwrap(a.sogliaDisingaggio), .uno, "soglia non disattivata per \(id)")
            }
        }

        // La fabbrica su disco non è stata toccata: riletta, ha ancora le soglie originali.
        let riletta = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        XCTAssertTrue(riletta.archetipi.values.allSatisfy { ($0.sogliaDisingaggio.map { $0 < .uno }) ?? true })
    }

    // MARK: - Nessun accoppiamento è un buco

    /// «Un accoppiamento mai provato è un buco della misura e non un risultato»: la misura
    /// copre ogni protezione, ogni attaccante, ogni bersaglio, senza omissioni.
    func test_incarico09_ogni_accoppiamento_fra_tipi_di_reparto_compare() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let corse = try banchi(valori: valori).corseMischia(soglieReali: soglieReali(valori))
        let archetipi = valori.archetipi.keys.sorted()
        let protezioni = TipoProtezione.allCases
        XCTAssertEqual(corse.count, archetipi.count * archetipi.count * protezioni.count)
        var visti = Set<String>()
        for c in corse { visti.insert(c.attaccante + "|" + c.bersaglio + "|" + c.protezione.rawValue) }
        for p in protezioni {
            for a in archetipi {
                for b in archetipi {
                    XCTAssertTrue(visti.contains(a + "|" + b + "|" + p.rawValue),
                                  "accoppiamento mancante: \(a) vs \(b) con \(p.rawValue)")
                }
            }
        }
    }

    // MARK: - Quarto punto: la provenienza non perde né inventa una perdita

    /// Il cancello della provenienza: la somma delle perdite attribuite al tiro e alla
    /// mischia eguaglia esattamente `perditeSubite` dello stato finale (RDA-46), per
    /// ciascuna parte. Se un canale di sola misura contasse due volte, o perdesse una
    /// perdita, o contasse un'evacuazione come perdita, questa prova lo rifiuterebbe.
    func test_incarico09_la_provenienza_eguaglia_le_perdite_subite_dello_stato() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let motore = MotoreBattaglia(valori: valori)
        let ufficiale = valori.ufficiali["ufficiale_prova"]!
        // Una battaglia con tiro e mischia: mazzi misti, così entrambe le provenienze compaiono.
        let deck: [ScenarioBattaglia.ElementoScenario] = [
            .init(archetipo: "fanteria_pesante", protezione: .antiSaturazione, atomi: 5, esemplari: 2),
            .init(archetipo: "tiratori", protezione: .antiSaturazione, atomi: 5, esemplari: 2),
        ]
        let scenario = ScenarioBattaglia(
            formato: "cento", caratteristica: "campo_aperto",
            primoOccupante: .giocatore, imboscata: false,
            deckGiocatore: deck, deckAvversario: deck, ufficialeAvversario: "ufficiale_prova")
        let stato = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
        let tattici: [Parte: TatticoBattaglia] = [
            .giocatore: TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .giocatore),
            .avversario: TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .avversario),
        ]

        let esito = ProvenienzaBattaglia(motore: motore).replica(stato: stato, tattici: tattici,
                                                                 giriMassimi: 80)
        // La stessa battaglia rigiocata, per leggere il `perditeSubite` finale.
        var s = stato
        var comandi = 0
        while s.esito == nil && s.giro <= 80 && comandi < 80 * 200 {
            let parte = s.parteDiTurno
            s = motore.applica(tattici[parte]!.prossimoComando(stato: s), parte: parte, stato: s).0
            comandi += 1
        }
        for parte in Parte.allCases {
            let attribuite = (esito.perditeTiro[parte] ?? 0) + (esito.perditeMischia[parte] ?? 0)
            XCTAssertEqual(attribuite, s.perditeSubite[parte] ?? 0,
                           "la provenienza di \(parte.rawValue) non pareggia perditeSubite")
        }
        // La battaglia ha davvero esercitato entrambe le provenienze.
        let tiro = (esito.perditeTiro[.giocatore] ?? 0) + (esito.perditeTiro[.avversario] ?? 0)
        let mischia = (esito.perditeMischia[.giocatore] ?? 0) + (esito.perditeMischia[.avversario] ?? 0)
        XCTAssertGreaterThan(tiro, 0, "nessuna perdita da tiro: la prova non copre il caso")
        XCTAssertGreaterThan(mischia, 0, "nessuna perdita da mischia: la prova non copre il caso")
    }

    // MARK: - Quinto punto: i due modificatori lavorano nella stessa direzione e si sommano

    /// Il cancello del quinto punto: crescendo gli assalitori, il coefficiente di
    /// accerchiamento non cala mai (formula del Motore, 01 §9.10.2) e gli scambi per
    /// distruggere il bersaglio calano (misura del compounding con il limite dei
    /// bersagli). Se un modificatore fosse neutralizzato, l'una o l'altra proprietà
    /// cadrebbe: la prova rifiuta quello stato.
    func test_incarico09_accerchiamento_e_limite_bersagli_si_sommano() throws {
        try ValoriVariati.con(base: Contenuti.valoriDiFabbrica,
                              inElenco: ValoriVariati.disingaggioDisattivato) { valoriV in
            let passi = try self.banchi(valori: valoriV).mischiaAccerchiata()
            XCTAssertGreaterThanOrEqual(passi.count, 2)
            for (prima, dopo) in zip(passi, passi.dropFirst()) {
                XCTAssertGreaterThanOrEqual(dopo.coefficienteAccerchiamentoPermille,
                                            prima.coefficienteAccerchiamentoPermille,
                                            "il coefficiente di accerchiamento non cresce con gli assalitori")
                XCTAssertGreaterThanOrEqual(dopo.inflittoPrimoGiro, prima.inflittoPrimoGiro,
                                            "più assalitori, non meno danno al bersaglio")
            }
            let uno = try XCTUnwrap(passi.first { $0.assalitori == 1 })
            let massimo = try XCTUnwrap(passi.last)
            XCTAssertGreaterThan(uno.scambiPerDistruggere, massimo.scambiPerDistruggere,
                                 "l'ammassamento non accorcia la distruzione: i modificatori non si sommano?")
        }
    }

    // MARK: - Incarico 10: le tre fasce restano separate

    /// Il cancello della taratura sulle tre fasce (incarico 10, prima decisione): le fasce
    /// devono essere distinguibili ascoltando, non solo diverse sulla carta. La mediana degli
    /// scambi in cui la soglia scatta cresce di almeno due fra fasce adiacenti; se due fasce
    /// si sfilano a scambi contigui la differenza non esiste per chi gioca, e la prova
    /// rifiuta quello stato. Il reparto elitario non scatta mai.
    func test_incarico10_le_fasce_di_disingaggio_restano_separate() throws {
        let rapporto = try programma().esegui()
        let fasce = try XCTUnwrap(rapporto.sezioni.first { $0.nome == "mischia_fasce" })
        func col(_ n: String) throws -> Int { try XCTUnwrap(fasce.intestazione.firstIndex(of: n)) }
        let cSoglia = try col("soglia_permille")
        let cMediana = try col("scatta_mediana")
        let cN = try col("accoppiamenti_che_scattano")
        let conSoglia = fasce.righe.filter { $0[cSoglia] != "assente" }
            .sorted { (Int($0[cSoglia]) ?? 0) < (Int($1[cSoglia]) ?? 0) }
        XCTAssertGreaterThanOrEqual(conSoglia.count, 3, "almeno tre fasce distinte di soglia")
        let mediane = try conSoglia.map { try XCTUnwrap(Int($0[cMediana])) }
        for (prima, dopo) in zip(mediane, mediane.dropFirst()) {
            XCTAssertGreaterThanOrEqual(dopo - prima, 2,
                "fasce adiacenti separate di almeno due scambi: se no, non distinguibili ascoltando (incarico 10)")
        }
        let elite = try XCTUnwrap(fasce.righe.first { $0[cSoglia] == "assente" },
                                  "manca la riga del reparto elitario a soglia assente")
        XCTAssertEqual(Int(elite[cN]), 0,
                       "il reparto elitario non raggiunge mai la propria soglia perché non ne ha")
    }

    // MARK: - Incarico 10: l'interruttore del secondo contatto cambia il comportamento

    /// Il cancello dell'interruttore del secondo contatto (01 §9.8.3, incarico 10): con la
    /// regola presente (falso) una coppia già staccata che riattacca non ha più soglia e si
    /// combatte fino alla dispersione; con la regola tolta (vero) la soglia opera di nuovo e
    /// il reparto può sfilarsi. Se l'interruttore non cambiasse nulla, non sarebbe un
    /// interruttore: la prova lo vede rifiutare entrambi gli stati.
    func test_incarico10_l_interruttore_del_secondo_contatto_cambia_il_disingaggio() throws {
        func siSfilaAlSecondoContatto(regolaTolta: Bool) throws -> Bool {
            let sost = [ValoriVariati.Sostituzione(file: "combattimento.json",
                                                   chiave: "soglia_al_secondo_contatto", valore: regolaTolta)]
            return try ValoriVariati.con(base: Contenuti.valoriDiFabbrica, sostituendo: sost) { valori in
                let motore = MotoreBattaglia(valori: valori)
                let scenario = ScenarioBattaglia(formato: "cento", caratteristica: "campo_aperto",
                                                 primoOccupante: .giocatore, imboscata: false,
                                                 deckGiocatore: [], deckAvversario: [])
                var s = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
                let a = valori.archetipi["fanteria_leggera"]!
                func poni(_ id: Int, _ p: Parte, _ cella: Cella) {
                    s.sciami[IdSciame(id)] = Sciame(id: IdSciame(id), parte: p, archetipo: "fanteria_leggera",
                                                    protezione: .antiSaturazione, lettera: id, atomiIniziali: 5,
                                                    serbatoio: 5 * a.puntiVitaPerAtomo, munizioni: 0,
                                                    posizione: cella, azioneSpesa: false, rinforzo: false)
                    s.forzeImpegnate[p, default: 0] += 5 * a.puntiVitaPerAtomo
                }
                poni(1, .giocatore, Cella(riga: 6, colonna: 5))
                poni(2, .avversario, Cella(riga: 5, colonna: 5))
                s.prossimoIdSciame = 3
                s.prossimaLettera = [.giocatore: 2, .avversario: 2]
                // La coppia si è GIÀ staccata: questo è il secondo contatto (01 §9.8.3).
                s.coppieStaccate.insert(Coppia(IdSciame(1), IdSciame(2)))
                s = motore.applica(.ingaggia(sciame: IdSciame(1), bersaglio: IdSciame(2)),
                                   parte: .giocatore, stato: s).0
                var giri = 0
                while s.sciami[IdSciame(1)] != nil && s.sciami[IdSciame(2)] != nil
                        && s.esito == nil && giri < 40 {
                    let (dopo, eventi) = motore.applica(.fineTurno, parte: s.parteDiTurno, stato: s)
                    s = dopo
                    if eventi.contains(where: { if case .disingaggio = $0 { return true }; return false }) {
                        return true
                    }
                    giri += 1
                }
                return false
            }
        }
        XCTAssertFalse(try siSfilaAlSecondoContatto(regolaTolta: false),
                       "regola presente: al secondo contatto nessuna soglia, si combatte fino alla dispersione")
        XCTAssertTrue(try siSfilaAlSecondoContatto(regolaTolta: true),
                      "regola tolta: al secondo contatto la soglia opera di nuovo e il reparto si sfila")
    }
}
