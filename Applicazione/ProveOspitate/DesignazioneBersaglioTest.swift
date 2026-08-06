import XCTest
import Dati
import Motore
@testable import WarSense

/// Le prove della designazione del bersaglio (02 §9.2.1, §9.3): i due modificatori
/// devono arrivare al giocatore nel momento in cui servono a decidere, cioè quando
/// si designa un bersaglio, in termini del vocabolario chiuso e senza alcuna cifra
/// (01 §9.10.1, §9.10.2). Un modificatore che non si annuncia è un numero invisibile.
@MainActor
final class DesignazioneBersaglioTest: XCTestCase {

    var ambiente: Ambiente!
    var motore: MotoreBattaglia!

    override func setUpWithError() throws {
        ambiente = try Ambiente()
        motore = MotoreBattaglia(valori: ambiente.valori)
    }

    private func costruttore(_ stato: StatoBattaglia) -> CostruttoreAnnunci {
        CostruttoreAnnunci(testi: ambiente.testi, motore: motore, stato: stato, verbosita: .normale)
    }

    /// Un campo costruito reparto per reparto, come nelle prove del Motore.
    private func campo(_ posti: [(Parte, IdentificatoreDati, TipoProtezione, Cella)]) throws
        -> (StatoBattaglia, [IdSciame]) {
        let riserva = ScenarioBattaglia.ElementoScenario(
            archetipo: "fanteria_leggera", protezione: .antiSaturazione, atomi: 5, esemplari: 1)
        let scenario = ScenarioBattaglia(formato: "cento", caratteristica: "campo_aperto",
                                         primoOccupante: .giocatore, imboscata: false,
                                         deckGiocatore: [riserva], deckAvversario: [riserva])
        var stato = try FabbricaBattaglia.crea(scenario: scenario, valori: ambiente.valori).0
        var ids: [IdSciame] = []
        for (parte, archetipo, protezione, cella) in posti {
            let id = IdSciame(stato.prossimoIdSciame)
            stato.prossimoIdSciame += 1
            let lettera = stato.prossimaLettera[parte] ?? 1
            stato.prossimaLettera[parte] = lettera + 1
            let a = ambiente.valori.archetipi[archetipo]!
            stato.sciami[id] = Sciame(id: id, parte: parte, archetipo: archetipo,
                                      protezione: protezione, lettera: lettera, atomiIniziali: 5,
                                      serbatoio: 5 * a.puntiVitaPerAtomo, munizioni: a.dotazioneMunizioni,
                                      posizione: cella, azioneSpesa: false, rinforzo: false)
            ids.append(id)
        }
        return (stato, ids)
    }

    // MARK: - Vicinanza nel tiro (01 §9.10.1)

    /// La voce di tiro dichiara la vicinanza con il termine chiuso che compete alla
    /// distanza, e il termine cambia man mano che il bersaglio si avvicina.
    func test_02_9_3_la_voce_di_tiro_dichiara_la_vicinanza_con_il_termine_chiuso() throws {
        let gittata = ambiente.valori.archetipi["tiratori"]!.gittata
        var termini: [String] = []
        for distanza in stride(from: gittata, through: 1, by: -1) {
            let (stato, ids) = try campo([
                (.giocatore, "tiratori", .antiSaturazione, Cella(riga: 9, colonna: 5)),
                (.avversario, "fanteria_pesante", .antiSaturazione, Cella(riga: 9 - distanza, colonna: 5)),
            ])
            let bersaglio = stato.sciami[ids[1]]!
            let voce = try XCTUnwrap(costruttore(stato).voceTiro(da: ids[0], su: bersaglio),
                                     "il bersaglio a portata offre la voce di tiro")
            let atteso = ambiente.testi.termine(
                motore.fasciaVicinanza(distanza: distanza, gittata: gittata).rawValue).testo
            XCTAssertTrue(voce.contains(atteso),
                          "distanza \(distanza): la voce dichiara «\(atteso)» — \(voce)")
            XCTAssertFalse(voce.contains(Testi.segnaposto), "chiave irrisolta: \(voce)")
            termini.append(atteso)
        }
        XCTAssertEqual(Set(termini).count, FasciaVicinanza.allCases.count,
                       "avvicinandosi il termine cambia davvero: \(termini)")
    }

    /// La voce di tiro non contiene alcuna cifra: le fasce sostituiscono i numeri
    /// (01 §9.7.2 per gli esiti, §9.10.1 e §9.10.2 per i modificatori).
    func test_01_9_10_la_voce_di_tiro_non_contiene_alcuna_cifra() throws {
        let (stato, ids) = try campo([
            (.giocatore, "tiratori", .antiSaturazione, Cella(riga: 9, colonna: 5)),
            (.avversario, "fanteria_pesante", .antiPerforazione, Cella(riga: 8, colonna: 5)),
            (.giocatore, "fanteria_pesante", .antiSaturazione, Cella(riga: 9, colonna: 6)),
        ])
        let voce = try XCTUnwrap(costruttore(stato).voceTiro(da: ids[0], su: stato.sciami[ids[1]]!))
        XCTAssertNil(voce.rangeOfCharacter(from: .decimalDigits), "nessuna cifra nella voce: \(voce)")
    }

    // MARK: - Accerchiamento (01 §9.10.2)

    /// Il bersaglio isolato non si annuncia come tale: la condizione ordinaria non
    /// si dichiara (02 §8.7.1). Il bersaglio stretto e quello circondato sì, con i
    /// due termini distinti del vocabolario chiuso.
    func test_02_4_4_5_l_accerchiamento_si_annuncia_solo_quando_c_e() throws {
        let bersaglio = Cella(riga: 5, colonna: 5)
        // I vicini di (5,5) sono (5,4), (5,6), (4,4), (4,5), (6,4), (6,5).
        let poste = [Cella(riga: 6, colonna: 5), Cella(riga: 6, colonna: 4), Cella(riga: 5, colonna: 4)]
        let stretto = ambiente.testi.termine(FasciaAccerchiamento.stretto.rawValue).testo
        let circondato = ambiente.testi.termine(FasciaAccerchiamento.circondato.rawValue).testo
        XCTAssertNotEqual(stretto, circondato, "due termini distinti e non confondibili")

        for quanti in 1...3 {
            let (stato, ids) = try campo(
                (0..<quanti).map { (Parte.giocatore, "fanteria_pesante",
                                    TipoProtezione.antiSaturazione, poste[$0]) }
                + [(.avversario, "guardia_elite", .antiSaturazione, bersaglio)])
            let idBersaglio = ids.last!
            let voce = try XCTUnwrap(costruttore(stato).voceIngaggio(da: ids[0],
                                                                    su: stato.sciami[idBersaglio]!))
            switch quanti {
            case 1:
                XCTAssertFalse(voce.contains(stretto), "isolato non si annuncia: \(voce)")
                XCTAssertFalse(voce.contains(circondato), "isolato non si annuncia: \(voce)")
            case 2:
                XCTAssertTrue(voce.contains(stretto), "due concorrenti: stretto — \(voce)")
            default:
                XCTAssertTrue(voce.contains(circondato), "tre concorrenti: circondato — \(voce)")
            }
            XCTAssertFalse(voce.contains(Testi.segnaposto), "chiave irrisolta: \(voce)")
        }
    }

    /// L'accerchiamento condotto con i tiratori si vede nell'annuncio: è la manovra
    /// che il modificatore esiste per premiare (01 §9.10.2).
    func test_01_9_10_2_l_accerchiamento_coi_tiratori_si_annuncia() throws {
        func voceIngaggio(conTiratore: Bool) throws -> String {
            var posti: [(Parte, IdentificatoreDati, TipoProtezione, Cella)] = [
                (.giocatore, "fanteria_pesante", .antiSaturazione, Cella(riga: 6, colonna: 5)),
                (.avversario, "guardia_elite", .antiSaturazione, Cella(riga: 5, colonna: 5)),
            ]
            if conTiratore {
                posti.append((.giocatore, "tiratori", .antiSaturazione, Cella(riga: 9, colonna: 5)))
            }
            let (stato, ids) = try campo(posti)
            return try XCTUnwrap(costruttore(stato).voceIngaggio(da: ids[0],
                                                                 su: stato.sciami[ids[1]]!))
        }
        let stretto = ambiente.testi.termine(FasciaAccerchiamento.stretto.rawValue).testo
        XCTAssertFalse(try voceIngaggio(conTiratore: false).contains(stretto))
        XCTAssertTrue(try voceIngaggio(conTiratore: true).contains(stretto),
                      "il tiratore che tiene il bersaglio sotto tiro si vede nell'annuncio")
    }

    // MARK: - Risposta del bersaglio (01 §9.11.3, 02 §4.4.5)

    /// La voce di ingaggio dichiara SEMPRE quale risposta il bersaglio opporrebbe,
    /// e i tre termini si succedono man mano che il bersaglio viene impegnato:
    /// risposta piena, risposta di lato, nessuna risposta.
    func test_01_9_11_3_la_voce_di_ingaggio_dichiara_sempre_la_risposta() throws {
        let bersaglio = Cella(riga: 5, colonna: 5)
        // I vicini di (5,5): (5,4), (5,6), (4,4), (4,5), (6,4), (6,5).
        let poste = [Cella(riga: 6, colonna: 5), Cella(riga: 6, colonna: 4),
                     Cella(riga: 5, colonna: 4), Cella(riga: 5, colonna: 6)]
        var termini: [String] = []
        // Con zero, uno e due nemici già a contatto, chi designa riceverebbe
        // rispettivamente risposta piena, ridotta e nessuna.
        for giaImpegnati in 0...2 {
            var (stato, ids) = try campo(
                (0...giaImpegnati).map { (Parte.giocatore, "fanteria_pesante",
                                          TipoProtezione.antiSaturazione, poste[$0]) }
                + [(.avversario, "guardia_elite", .antiSaturazione, bersaglio)])
            let idBersaglio = ids.removeLast()
            // Il designante è l'ULTIMO dell'elenco: gli altri hanno già ingaggiato.
            let designante = ids.removeLast()
            for id in ids {
                stato = motore.applica(ComandoBattaglia.ingaggia(sciame: id, bersaglio: idBersaglio),
                                       parte: Parte.giocatore, stato: stato).0
            }
            let voce = try XCTUnwrap(costruttore(stato).voceIngaggio(
                da: designante, su: stato.sciami[idBersaglio]!))
            let atteso = ambiente.testi.termine(
                motore.rispostaAttesa(ingaggiando: idBersaglio, stato: stato).rawValue).testo
            XCTAssertTrue(voce.contains(atteso),
                          "con \(giaImpegnati) già a contatto la voce dichiara «\(atteso)»: \(voce)")
            XCTAssertFalse(voce.contains(Testi.segnaposto), "chiave irrisolta: \(voce)")
            termini.append(atteso)
        }
        XCTAssertEqual(Set(termini).count, TipoRisposta.allCases.count,
                       "i tre termini si succedono davvero: \(termini)")
        // La condizione ordinaria si annuncia anch'essa, in deroga dichiarata a 02 §8.7:
        // il silenzio non sarebbe distinguibile dal non aver sentito (01 §9.11.3).
        XCTAssertEqual(termini[0], ambiente.testi.termine(TipoRisposta.piena.rawValue).testo)
    }

    /// I tre termini sono distinti l'uno dall'altro: sono segnali, non frasi (02 §4.1).
    func test_02_4_4_5_i_tre_termini_della_risposta_sono_distinti() throws {
        let termini = TipoRisposta.allCases.map { ambiente.testi.termine($0.rawValue).testo }
        XCTAssertEqual(Set(termini).count, termini.count, "nessun termine ripetuto: \(termini)")
        for termine in termini {
            XCTAssertFalse(termine.isEmpty)
            XCTAssertNil(termine.rangeOfCharacter(from: .decimalDigits), "nessuna cifra: \(termine)")
        }
    }

    /// Il tiro non porta la risposta: la risposta è di mischia e il tiro non ne
    /// provoca alcuna (02 §9.3.1).
    func test_02_9_3_1_la_voce_di_tiro_non_porta_la_risposta() throws {
        let (stato, ids) = try campo([
            (.giocatore, "tiratori", .antiSaturazione, Cella(riga: 9, colonna: 5)),
            (.avversario, "fanteria_pesante", .antiPerforazione, Cella(riga: 8, colonna: 5)),
        ])
        let voce = try XCTUnwrap(costruttore(stato).voceTiro(da: ids[0], su: stato.sciami[ids[1]]!))
        for risposta in TipoRisposta.allCases {
            XCTAssertFalse(voce.contains(ambiente.testi.termine(risposta.rawValue).testo),
                           "la voce di tiro non dichiara risposte: \(voce)")
        }
    }

    // MARK: - Ordine fisso delle informazioni (02 §3.8, §9.2.1)

    /// L'ordine è dichiarato e identico nelle due voci: bersaglio, efficacia,
    /// poi i modificatori. L'efficacia compare in entrambe, come 02 §9.2.1 prescrive
    /// per ogni azione con bersaglio.
    func test_02_9_2_1_ordine_fisso_bersaglio_efficacia_modificatori() throws {
        let (stato, ids) = try campo([
            (.giocatore, "tiratori", .antiSaturazione, Cella(riga: 6, colonna: 5)),
            (.avversario, "fanteria_pesante", .antiPerforazione, Cella(riga: 5, colonna: 5)),
            (.giocatore, "fanteria_pesante", .antiSaturazione, Cella(riga: 5, colonna: 4)),
        ])
        let c = costruttore(stato)
        let bersaglio = stato.sciami[ids[1]]!
        let nome = ambiente.testi.frase("unita.fanteria_pesante").testo
        let efficace = ambiente.testi.termine(EfficaciaQualitativa.efficace.rawValue).testo
        let stretto = ambiente.testi.termine(FasciaAccerchiamento.stretto.rawValue).testo

        for voce in [try XCTUnwrap(c.voceTiro(da: ids[0], su: bersaglio)),
                     try XCTUnwrap(c.voceIngaggio(da: ids[0], su: bersaglio))] {
            let posizioneNome = try XCTUnwrap(voce.range(of: nome)).lowerBound
            let posizioneEfficacia = try XCTUnwrap(voce.range(of: efficace)).lowerBound
            let posizioneStretto = try XCTUnwrap(voce.range(of: stretto)).lowerBound
            XCTAssertLessThan(posizioneNome, posizioneEfficacia, "prima il bersaglio: \(voce)")
            XCTAssertLessThan(posizioneEfficacia, posizioneStretto,
                              "poi l'efficacia, infine i modificatori: \(voce)")
        }
        // Nella voce di ingaggio la risposta chiude la frase: prima ciò che si
        // infligge, poi ciò che si riceve (02 §9.3.1).
        let ingaggio = try XCTUnwrap(c.voceIngaggio(da: ids[0], su: bersaglio))
        let risposta = ambiente.testi.termine(
            motore.rispostaAttesa(ingaggiando: bersaglio.id, stato: stato).rawValue).testo
        let posizioneRisposta = try XCTUnwrap(ingaggio.range(of: risposta)).lowerBound
        let posizioneStretto = try XCTUnwrap(ingaggio.range(of: stretto)).lowerBound
        XCTAssertLessThan(posizioneStretto, posizioneRisposta,
                          "la risposta chiude la voce di ingaggio: \(ingaggio)")
    }

    /// Un'azione non ammissibile non produce alcuna voce: non si offre (02 §9.5).
    func test_02_9_5_nessuna_voce_per_un_bersaglio_fuori_portata() throws {
        let (stato, ids) = try campo([
            (.giocatore, "tiratori", .antiSaturazione, Cella(riga: 10, colonna: 1)),
            (.avversario, "fanteria_pesante", .antiSaturazione, Cella(riga: 1, colonna: 10)),
        ])
        let bersaglio = stato.sciami[ids[1]]!
        XCTAssertNil(costruttore(stato).voceTiro(da: ids[0], su: bersaglio), "fuori portata")
        XCTAssertNil(costruttore(stato).voceIngaggio(da: ids[0], su: bersaglio), "non adiacente")
    }

    // MARK: - Il pannello vero (02 §9.2.1)

    /// Le voci arrivano davvero nel pannello della cella, non solo nel costruttore.
    func test_02_9_2_1_le_voci_del_pannello_portano_i_modificatori() async throws {
        let radice = UIViewController()
        let finestra = UIWindow(frame: UIScreen.main.bounds)
        finestra.rootViewController = radice
        finestra.makeKeyAndVisible()

        let partita = try await PartitaCorrente(nuova: ambiente)
        let schermata = SchermataBattaglia(partita: partita)
        schermata.modalPresentationStyle = .fullScreen
        radice.present(schermata, animated: false)
        for _ in 0..<250 where schermata.elementiPerProva.isEmpty {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        // I tiratori del giocatore (indice 2 del mazzo di prova) scendono in campo,
        // poi si passano turni finché l'avversario — che è deterministico (01 §12.1)
        // e avanza — non porta un reparto entro la gittata. Nessuna attesa aleatoria:
        // la stessa partita produce sempre lo stesso numero di turni.
        let cella = Cella(riga: 8, colonna: 5)
        let gittata = ambiente.valori.archetipi["tiratori"]!.gittata
        _ = try await partita.esegui(.seleziona(indiceDeck: 2))
        _ = try await partita.esegui(.piazza(cella: cella))
        _ = try await partita.esegui(.deseleziona)

        var stato = await partita.stato
        var turni = 0
        func bersaglioAPortata(_ stato: StatoBattaglia) -> Sciame? {
            stato.sciamiOrdinati.first {
                $0.parte == .avversario && stato.griglia.distanza(cella, $0.posizione) <= gittata
            }
        }
        while bersaglioAPortata(stato) == nil && turni < 20 && stato.esito == nil {
            _ = try await partita.esegui(.fineTurno)
            stato = await partita.stato
            turni += 1
        }
        try await Task.sleep(nanoseconds: 300_000_000)
        let bersaglio = try XCTUnwrap(bersaglioAPortata(stato),
                                      "in venti turni l'avversario deve entrare nella gittata")
        XCTAssertTrue(schermata.attiva(cella), "l'attivazione della propria unità apre il pannello")
        for _ in 0..<250 where !(schermata.presentedViewController is UIAlertController) {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        let attesa = try XCTUnwrap(costruttore(stato).voceTiro(da: stato.occupante(di: cella)!.id,
                                                              su: bersaglio))
        XCTAssertTrue(schermata.vociPannelloPerProva.contains { $0.titolo == attesa },
                      "il pannello offre la voce di tiro completa: \(schermata.vociPannelloPerProva.map(\.titolo))")
    }

    /// Incarico 11, terza decisione: il reparto élite della fase è annunciato fra le sue
    /// informazioni, riconoscibile prima di ingaggiare, per la ragione dell'addestramento
    /// superiore. In antica l'élite è `guardia_elite`; un reparto ordinario non porta
    /// l'annuncio. Prima decisione: la soglia di disingaggio NON si annuncia in alcuna forma.
    func test_incarico11_l_elite_e_annunciata_e_la_soglia_no() throws {
        let (stato, ids) = try campo([
            (.giocatore, "fanteria_pesante", .antiSaturazione, Cella(riga: 6, colonna: 5)),
            (.avversario, "guardia_elite", .antiSaturazione, Cella(riga: 5, colonna: 5)),
        ])
        let frase = ambiente.testi.frase("battaglia.reparto_elite").testo
        let cellaElite = stato.sciami[ids[1]]!.posizione
        let cellaOrdinaria = stato.sciami[ids[0]]!.posizione
        let annuncioElite = costruttore(stato).etichettaCella(cellaElite)
        let annuncioOrdinario = costruttore(stato).etichettaCella(cellaOrdinaria)
        XCTAssertTrue(annuncioElite.contains(frase),
                      "il reparto élite della fase è annunciato: \(annuncioElite)")
        XCTAssertFalse(annuncioOrdinario.contains(frase),
                       "un reparto ordinario non è annunciato come élite: \(annuncioOrdinario)")
        // La soglia (fanteria_pesante 0,9 = 900 permille) non compare in alcuna forma.
        for annuncio in [annuncioElite, annuncioOrdinario] {
            XCTAssertFalse(annuncio.contains("900") || annuncio.contains("0,9") || annuncio.contains("0.9"),
                           "la soglia di disingaggio non si annuncia (incarico 11, prima decisione): \(annuncio)")
        }
    }
}
