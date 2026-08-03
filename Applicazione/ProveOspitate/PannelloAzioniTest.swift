import XCTest
import Dati
import Motore
@testable import WarSense

/// Le prove del pannello delle azioni (02 §9.2.1, RDA-49): l'avviso di sistema si
/// congeda da solo al tocco di una voce, e la chiusura della voce corre DOPO quel
/// congedo. La prova riproduce la sequenza reale del dispositivo, che il primo
/// collaudo sul campo ha mostrato capace di congedare la schermata dello scontro.
@MainActor
final class PannelloAzioniTest: XCTestCase {

    private var finestra: UIWindow!
    private var radice: UIViewController!

    override func setUp() {
        super.setUp()
        radice = UIViewController()
        finestra = UIWindow(frame: UIScreen.main.bounds)
        finestra.rootViewController = radice
        finestra.makeKeyAndVisible()
    }

    private func attendi(_ descrizione: String,
                         _ condizione: @MainActor () -> Bool) async throws {
        for _ in 0..<250 where !condizione() {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertTrue(condizione(), "attesa scaduta: \(descrizione)")
    }

    /// Apre lo scontro come nell'uso vero (schermata presentata dalla radice),
    /// piazza una truppa e passa un turno perché l'azione torni disponibile (01 §8.1.2).
    private func schermataConTruppaPronta(_ ambiente: Ambiente) async throws
        -> (SchermataBattaglia, PartitaCorrente, Cella) {
        let partita = try await PartitaCorrente(nuova: ambiente)
        let schermata = SchermataBattaglia(partita: partita)
        schermata.modalPresentationStyle = .fullScreen
        radice.present(schermata, animated: false)
        try await attendi("creazione degli elementi") { !schermata.elementiPerProva.isEmpty }

        let cella = Cella(riga: 10, colonna: 1)
        _ = try await partita.esegui(.seleziona(indiceDeck: 0))
        _ = try await partita.esegui(.piazza(cella: cella))
        _ = try await partita.esegui(.deseleziona)
        _ = try await partita.esegui(.fineTurno) // l'avversario agisce, l'azione torna
        let stato = await partita.stato
        XCTAssertEqual(stato.parteDiTurno, .giocatore)
        try await Task.sleep(nanoseconds: 200_000_000)
        return (schermata, partita, cella)
    }

    func test_02_9_2_1_la_voce_del_pannello_agisce_e_lo_scontro_prosegue() async throws {
        let ambiente = try Ambiente()
        let (schermata, partita, cella) = try await schermataConTruppaPronta(ambiente)

        XCTAssertTrue(schermata.attiva(cella), "l'attivazione della propria truppa apre il pannello")
        try await attendi("apertura del pannello") {
            schermata.presentedViewController is UIAlertController
        }
        let pannello = schermata.presentedViewController as! UIAlertController
        let titoloDesigna = ambiente.testi.frase("pannello.designa_movimento").testo
        guard let voce = schermata.vociPannelloPerProva.first(where: { $0.titolo == titoloDesigna }) else {
            XCTFail("il pannello offre la designazione del movimento (02 §9.2.1)")
            return
        }

        // La sequenza reale del tocco: il sistema congeda l'avviso, POI esegue la voce.
        pannello.dismiss(animated: false)
        try await attendi("congedo automatico dell'avviso") {
            schermata.presentedViewController == nil
        }
        Fuoco.azzeraRegistro()
        voce.esegui()
        try await Task.sleep(nanoseconds: 500_000_000)

        // Lo scontro prosegue: la schermata resta presentata, non si torna all'avvio.
        XCTAssertNotNil(schermata.presentingViewController,
                        "la voce non congeda la schermata dello scontro (02 §9.2.1, 00 §1.2)")
        // Il fuoco è tornato alla cella d'origine su richiesta (05 §10.3).
        XCTAssertEqual(schermata.registroFuocoPerProva, [.richiesto],
                       "alla chiusura del pannello il fuoco torna alla cella d'origine")

        // La designazione è davvero attiva: l'attivazione della destinazione muove.
        let destinazione = Cella(riga: 10, colonna: 2)
        XCTAssertTrue(schermata.attiva(destinazione), "la destinazione designata si conferma")
        var mosso = false
        for _ in 0..<100 where !mosso {
            let stato = await partita.stato
            mosso = stato.occupante(di: destinazione)?.parte == .giocatore
            if !mosso { try await Task.sleep(nanoseconds: 20_000_000) }
        }
        XCTAssertTrue(mosso, "il movimento designato è eseguito (02 §9.2.1)")
    }

    func test_02_9_5_lo_spostamento_non_si_offre_senza_alcuna_destinazione() async throws {
        let ambiente = try Ambiente()
        let partita = try await PartitaCorrente(nuova: ambiente)
        let schermata = SchermataBattaglia(partita: partita)
        schermata.modalPresentationStyle = .fullScreen
        radice.present(schermata, animated: false)
        try await attendi("creazione degli elementi") { !schermata.elementiPerProva.isEmpty }

        // L'angolo (10,1) circondato dai propri: (10,2), (9,1), (9,2) occupate.
        // Nessuna destinazione esiste, nemmeno a due celle: le intermedie sono piene.
        _ = try await partita.esegui(.seleziona(indiceDeck: 0))
        _ = try await partita.esegui(.piazza(cella: Cella(riga: 10, colonna: 1)))
        _ = try await partita.esegui(.piazza(cella: Cella(riga: 10, colonna: 2)))
        _ = try await partita.esegui(.piazza(cella: Cella(riga: 9, colonna: 1)))
        _ = try await partita.esegui(.seleziona(indiceDeck: 1))
        _ = try await partita.esegui(.piazza(cella: Cella(riga: 9, colonna: 2)))
        _ = try await partita.esegui(.deseleziona)
        _ = try await partita.esegui(.fineTurno) // l'azione torna al turno nuovo
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(schermata.attiva(Cella(riga: 10, colonna: 1)))
        try await attendi("apertura del pannello") {
            schermata.presentedViewController is UIAlertController
        }
        let titoli = schermata.vociPannelloPerProva.map(\.titolo)
        let titoloDesigna = ambiente.testi.frase("pannello.designa_movimento").testo
        XCTAssertFalse(titoli.contains(titoloDesigna),
                       "l'azione impossibile in ogni sua forma non si offre (02 §9.5)")
        XCTAssertTrue(titoli.contains(ambiente.testi.frase("pannello.chiudi").testo))

        // Il reparto con destinazioni, invece, la offre: la regola non si estende oltre.
        schermata.presentedViewController?.dismiss(animated: false)
        try await attendi("congedo del pannello") { schermata.presentedViewController == nil }
        XCTAssertTrue(schermata.attiva(Cella(riga: 9, colonna: 2)))
        try await attendi("apertura del secondo pannello") {
            schermata.presentedViewController is UIAlertController
        }
        XCTAssertTrue(schermata.vociPannelloPerProva.map(\.titolo).contains(titoloDesigna),
                      "chi ha destinazioni conserva l'azione di spostamento")
        schermata.presentedViewController?.dismiss(animated: false)
        try await attendi("congedo finale") { schermata.presentedViewController == nil }
    }

    func test_02_9_2_1_anche_la_chiusura_del_pannello_non_congeda_la_schermata() async throws {
        let ambiente = try Ambiente()
        let (schermata, _, cella) = try await schermataConTruppaPronta(ambiente)

        XCTAssertTrue(schermata.attiva(cella))
        try await attendi("apertura del pannello") {
            schermata.presentedViewController is UIAlertController
        }
        let pannello = schermata.presentedViewController as! UIAlertController
        let titoloChiudi = ambiente.testi.frase("pannello.chiudi").testo
        guard let voce = schermata.vociPannelloPerProva.first(where: { $0.titolo == titoloChiudi }) else {
            XCTFail("il pannello offre la voce di chiusura")
            return
        }
        pannello.dismiss(animated: false)
        try await attendi("congedo automatico dell'avviso") {
            schermata.presentedViewController == nil
        }
        voce.esegui()
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertNotNil(schermata.presentingViewController,
                        "la chiusura del pannello non congeda la schermata dello scontro")
    }
}
