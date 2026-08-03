import XCTest
import Dati
import Motore
import Sessione
@testable import WarSense

/// Le prove del comportamento del fuoco e degli annunci (05 §14.4, incarico fase B):
/// automatiche, non per constatazione manuale. Ospitate nell'applicazione vera.
@MainActor
final class AnnunciEFuocoTest: XCTestCase {

    var ambiente: Ambiente!

    override func setUpWithError() throws {
        ambiente = try Ambiente()
    }

    private func statoDiProva() throws -> StatoBattaglia {
        let scenario = try PartitaCorrente.scenarioDiProva()
        return try FabbricaBattaglia.crea(scenario: scenario, valori: ambiente.valori).0
    }

    private func costruttore(_ stato: StatoBattaglia, _ verbosita: Verbosita) -> CostruttoreAnnunci {
        CostruttoreAnnunci(testi: ambiente.testi, motore: MotoreBattaglia(valori: ambiente.valori),
                           stato: stato, verbosita: verbosita)
    }

    // MARK: - Annunci di cella (02 §3)

    func test_02_3_2_testa_fissa_sempre_presente_mai_tagliata() throws {
        let stato = try statoDiProva()
        for verbosita in Verbosita.allCases {
            let c = costruttore(stato, verbosita)
            for cella in [Cella(riga: 1, colonna: 1), Cella(riga: 5, colonna: 5),
                          Cella(riga: 10, colonna: 10)] {
                let etichetta = c.etichettaCella(cella)
                let testa = ambiente.testi.frase("cella.testa", cella.riga, cella.colonna).testo
                XCTAssertTrue(etichetta.contains(testa),
                              "la testa fissa non si taglia mai (02 §3.9): \(etichetta)")
            }
        }
    }

    func test_02_3_3_con_selezione_la_disponibilita_precede_la_testa() throws {
        var stato = try statoDiProva()
        stato.selezione[.giocatore] = 0
        let c = costruttore(stato, .normale)
        // Cella valida della zona di schieramento: il costo precede la testa.
        let valida = c.etichettaCella(Cella(riga: 10, colonna: 1))
        let costoPrefisso = ambiente.testi.frase("cella.disponibile", 0, 0).testo.prefix(5)
        XCTAssertTrue(valida.hasPrefix(String(costoPrefisso)),
                      "prima la disponibilità, poi la testa (02 §3.3): \(valida)")
        // Cella fuori zona: il motivo chiuso precede la testa (02 §3.5).
        let fuoriZona = c.etichettaCella(Cella(riga: 5, colonna: 1))
        XCTAssertTrue(fuoriZona.hasPrefix(ambiente.testi.termine("cella.troppo_avanzata").testo),
                      "il motivo apre l'annuncio: \(fuoriZona)")
        // L'ostacolo usa il suo termine chiuso (02 §3.5.1).
        let ostacolo = c.etichettaCella(Cella(riga: 5, colonna: 5))
        XCTAssertTrue(ostacolo.hasPrefix(ambiente.testi.termine("cella.ostacolo").testo))
    }

    func test_02_3_10_nel_sintetico_la_cella_vuota_e_poche_parole() throws {
        let stato = try statoDiProva()
        let sintetico = costruttore(stato, .sintetico).etichettaCella(Cella(riga: 7, colonna: 3))
        XCTAssertEqual(sintetico, ambiente.testi.frase("cella.testa", 7, 3).testo,
                       "cella vuota nel sintetico: la sola testa (02 §3.10)")
        let normale = costruttore(stato, .normale).etichettaCella(Cella(riga: 7, colonna: 3))
        XCTAssertTrue(normale.count > sintetico.count,
                      "i livelli tagliano dalla coda (00 §9.5)")
    }

    func test_01_15_3_1_il_resoconto_ha_le_voci_in_ordine_fisso() throws {
        var stato = try statoDiProva()
        stato.esito = EsitoBattaglia(sconfitto: .avversario, modo: .annientamento, turni: 12)
        let voci = costruttore(stato, .normale).vociResoconto()
        XCTAssertEqual(voci.count, 7, "le voci del resoconto applicabili allo scontro singolo")
        XCTAssertTrue(voci[0].contains(ambiente.testi.frase("resoconto.modo_annientamento").testo),
                      "la prima voce è l'esito (01 §15.3.1)")
        for voce in voci {
            XCTAssertFalse(voce.contains(Testi.segnaposto), "chiave irrisolta: \(voce)")
        }
    }

    // MARK: - Elementi persistenti e fuoco (00 §11, RDA-03)

    func test_00_11_1_elementi_persistenti_e_fuoco_mai_mosso_senza_richiesta() async throws {
        let partita = try await PartitaCorrente(nuova: ambiente)
        let schermata = SchermataBattaglia(partita: partita)
        let finestra = UIWindow(frame: UIScreen.main.bounds)
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        // L'avvio è asincrono: si attende la creazione degli elementi.
        for _ in 0..<100 where schermata.elementiPerProva.isEmpty {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertEqual(schermata.elementiPerProva.count, 100, "una griglia da cento celle")

        // Identità: gli elementi si creano una volta sola (05 §10.1).
        let identitaPrima = schermata.elementiPerProva.mapValues { ObjectIdentifier($0) }
        XCTAssertEqual(schermata.registroFuocoPerProva.last, .schermataAperta,
                       "l'unico movimento del fuoco è l'apertura della schermata (02 §2.9)")
        Fuoco.azzeraRegistro()

        // Una sequenza di gioco vera: selezione e piazzamento.
        _ = try await partita.esegui(.seleziona(indiceDeck: 0))
        _ = try await partita.esegui(.piazza(cella: Cella(riga: 10, colonna: 1)))
        try await Task.sleep(nanoseconds: 200_000_000) // l'aggiornamento è sul posto

        let identitaDopo = schermata.elementiPerProva.mapValues { ObjectIdentifier($0) }
        XCTAssertEqual(identitaPrima, identitaDopo,
                       "gli elementi non si ricreano mai durante l'uso (00 §11.1, RDA-03)")
        XCTAssertTrue(schermata.registroFuocoPerProva.isEmpty,
                       "dopo il piazzamento il fuoco resta dove l'utente lo ha lasciato (00 §11.3)")

        // L'etichetta della cella piazzata è stata aggiornata sul posto.
        let etichetta = schermata.elementiPerProva[Cella(riga: 10, colonna: 1)]?.accessibilityLabel ?? ""
        XCTAssertTrue(etichetta.contains(ambiente.testi.frase("unita.fanteria_leggera").testo),
                      "aggiornamento sul posto: \(etichetta)")
    }

    func test_00_11_3_esaurimento_del_deck_senza_spostare_il_fuoco() async throws {
        let partita = try await PartitaCorrente(nuova: ambiente)
        let schermata = SchermataBattaglia(partita: partita)
        let finestra = UIWindow(frame: UIScreen.main.bounds)
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        for _ in 0..<100 where schermata.elementiPerProva.isEmpty {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        // Esaurisce l'elemento con due esemplari (i tiratori, indice 2).
        Fuoco.azzeraRegistro()
        _ = try await partita.esegui(.seleziona(indiceDeck: 2))
        _ = try await partita.esegui(.piazza(cella: Cella(riga: 10, colonna: 4)))
        _ = try await partita.esegui(.piazza(cella: Cella(riga: 10, colonna: 5)))
        try await Task.sleep(nanoseconds: 200_000_000)
        let stato = await partita.stato
        XCTAssertNil(stato.selezione[.giocatore], "deselezione automatica (01 §8.4)")
        XCTAssertTrue(schermata.registroFuocoPerProva.isEmpty,
                       "l'esaurimento non muove il fuoco (00 §11.3, 02 §5.3)")
    }
}
