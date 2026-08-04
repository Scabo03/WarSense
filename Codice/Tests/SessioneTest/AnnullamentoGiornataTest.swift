import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// L'annullamento dell'ordine che ha chiuso la giornata (00 §13.8).
///
/// La giornata è un budget che si consuma: ogni gruppo ha un'azione e quando
/// l'ultima è spesa la giornata si chiude da sé (01 §5.6.0.6). 00 §13.8 vuole che
/// ogni budget che si consuma abbia l'annullamento dell'ultima operazione e
/// l'azzeramento completo — «senza annullamento il giocatore paga un errore di
/// manovra come se fosse stata una scelta tattica».
///
/// L'ordine più esposto all'errore è precisamente l'ULTIMO della giornata, perché
/// il giocatore lo impartisce per muovere un gruppo e ne ottiene per soprammercato
/// un passaggio di giornata che non ha chiesto. Se quell'ordine non si annulla, il
/// gesto compiuto per fare una cosa ne produce un'altra, irreversibile, e per chi
/// ascolta è la combinazione peggiore possibile.
final class AnnullamentoGiornataTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
    }

    private func slot() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("annullamento-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func nuova(_ cartella: URL, gruppi: [(Int, Int)]) throws -> SessioneCampagna {
        try SessioneCampagna(
            nuova: ScenarioCampagna(mappa: "pianura_lunga",
                                    gruppiGiocatore: gruppi.map { .init(riga: $0.0, colonna: $0.1) }),
            valori: valori, valoriCampagna: valoriCampagna, versioneTesti: "0.1.1",
            cartella: cartella, seme: 4242, identificatore: "prova-annullamento")
    }

    // MARK: - 00 §13.8 — l'ordine che chiude la giornata si annulla

    func test_00_13_8_annullare_l_ordine_che_ha_chiuso_la_giornata_la_riapre() async throws {
        let cartella = try slot()
        let sessione = try await nuova(cartella, gruppi: [(10, 6), (10, 5)])
        let ids = await sessione.stato.gruppiOrdinati.map(\.id)

        _ = try await sessione.esegui(.presidio(gruppo: ids[0]), parte: .giocatore)
        // Lo stato immediatamente PRIMA dell'ultimo ordine: è dove l'annullamento
        // deve riportare, esattamente.
        let improntaPrima = await sessione.impronta()
        let giornoPrima = await sessione.stato.giorno
        XCTAssertEqual(giornoPrima, 1)

        _ = try await sessione.esegui(.presidio(gruppo: ids[1]), parte: .giocatore)
        let giornoDopo = await sessione.stato.giorno
        XCTAssertEqual(giornoDopo, 2, "l'ultimo ordine ha chiuso la giornata")

        let esito = try await sessione.annulla(parte: .giocatore)
        XCTAssertTrue(esito.giornataRiaperta, "l'annullamento deve dichiarare di aver riaperto la giornata")
        XCTAssertEqual(esito.giorno, 1)

        let giornoRipristinato = await sessione.stato.giorno
        XCTAssertEqual(giornoRipristinato, 1, "il giorno torna indietro con l'ordine annullato")
        let improntaDopo = await sessione.impronta()
        XCTAssertEqual(improntaDopo, improntaPrima,
                       "l'annullamento riporta ESATTAMENTE allo stato che precedeva l'ordine")
        // Il gruppo torna ad attendere una decisione, e il primo resta con l'azione spesa.
        let attesa = await sessione.stato.gruppiInAttesa().map(\.id)
        XCTAssertEqual(attesa, [ids[1]], "torna in attesa il solo gruppo il cui ordine è stato ritirato")
    }

    /// Il giornale è la verità (05 §6.2): dopo l'annullamento, riaprire lo slot dal
    /// solo giornale deve dare lo stesso stato. Senza questa prova l'annullamento
    /// potrebbe aggiustare lo stato in memoria e lasciare sul disco una partita
    /// diversa, che è il difetto peggiore perché si manifesta al riavvio.
    func test_05_6_3_il_giornale_rigiocato_dopo_l_annullamento_da_lo_stesso_stato() async throws {
        let cartella = try slot()
        let sessione = try await nuova(cartella, gruppi: [(10, 6), (10, 5), (9, 6)])
        let ids = await sessione.stato.gruppiOrdinati.map(\.id)
        _ = try await sessione.esegui(.marcia(gruppo: ids[0], a: Cella(riga: 10, colonna: 7)),
                                      parte: .giocatore)
        _ = try await sessione.esegui(.presidio(gruppo: ids[1]), parte: .giocatore)
        let improntaPrima = await sessione.impronta()
        _ = try await sessione.esegui(.presidio(gruppo: ids[2]), parte: .giocatore)
        _ = try await sessione.annulla(parte: .giocatore)
        let improntaMemoria = await sessione.impronta()
        XCTAssertEqual(improntaMemoria, improntaPrima)

        // Le istantanee si cancellano: la ripresa deve reggere sul solo giornale.
        for url in try FileManager.default.contentsOfDirectory(at: cartella, includingPropertiesForKeys: nil)
        where url.lastPathComponent.hasPrefix("istantanea-") {
            try FileManager.default.removeItem(at: url)
        }
        let ripresa = try await SessioneCampagna(riprendi: cartella, valori: valori,
                                                 valoriCampagna: valoriCampagna)
        let improntaDisco = await ripresa.impronta()
        XCTAssertEqual(improntaDisco, improntaPrima,
                       "sul disco è rimasta una partita diversa da quella in memoria")
        let giorno = await ripresa.stato.giorno
        XCTAssertEqual(giorno, 1)
    }

    /// L'azzeramento della giornata appena chiusa la riapre e ne toglie tutti gli
    /// ordini: è l'altra metà di 00 §13.8.
    func test_00_13_8_azzerare_dopo_la_chiusura_riapre_la_giornata_e_la_svuota() async throws {
        let cartella = try slot()
        let sessione = try await nuova(cartella, gruppi: [(10, 6), (10, 5), (9, 6)])
        let apertura = await sessione.impronta()
        let ids = await sessione.stato.gruppiOrdinati.map(\.id)
        for id in ids { _ = try await sessione.esegui(.presidio(gruppo: id), parte: .giocatore) }
        let giornoDopo = await sessione.stato.giorno
        XCTAssertEqual(giornoDopo, 2)

        let esito = try await sessione.azzera(parte: .giocatore)
        XCTAssertTrue(esito.giornataRiaperta)
        XCTAssertEqual(esito.giorno, 1)
        let dopo = await sessione.impronta()
        XCTAssertEqual(dopo, apertura, "la giornata torna com'era all'apertura")
        let attesa = await sessione.stato.gruppiInAttesa().count
        XCTAssertEqual(attesa, 3, "tutti i gruppi tornano ad attendere una decisione")
    }

    /// L'annullamento di un ordine che NON ha chiuso la giornata non la riapre e
    /// lo dichiara: il giocatore deve poter distinguere i due casi.
    func test_00_13_8_l_annullamento_ordinario_non_riapre_alcuna_giornata() async throws {
        let sessione = try await nuova(try slot(), gruppi: [(10, 6), (10, 5), (9, 6)])
        let ids = await sessione.stato.gruppiOrdinati.map(\.id)
        _ = try await sessione.esegui(.presidio(gruppo: ids[0]), parte: .giocatore)
        let esito = try await sessione.annulla(parte: .giocatore)
        XCTAssertFalse(esito.giornataRiaperta)
        XCTAssertEqual(esito.giorno, 1)
    }

    /// Non c'è nulla da annullare quando nessun ordine è stato impartito: la
    /// prima apertura non si ritira.
    func test_05_6_4_senza_ordini_non_c_e_nulla_da_annullare() async throws {
        let sessione = try await nuova(try slot(), gruppi: [(10, 6)])
        do {
            _ = try await sessione.annulla(parte: .giocatore)
            XCTFail("non c'era alcun ordine da annullare")
        } catch let errore as SessioneCampagna.ErroreSessione {
            guard case .operazioneNonDisponibile = errore else {
                return XCTFail("motivo sbagliato: \(errore)")
            }
        }
        do {
            _ = try await sessione.azzera(parte: .giocatore)
            XCTFail("non c'era alcun ordine da azzerare")
        } catch let errore as SessioneCampagna.ErroreSessione {
            guard case .operazioneNonDisponibile = errore else {
                return XCTFail("motivo sbagliato: \(errore)")
            }
        }
    }

    /// Annullando a ritroso si torna indietro di più giornate, un ordine per volta,
    /// fino all'inizio della campagna. Non esiste alcun punto oltre il quale
    /// l'annullamento si ferma, FINCHÉ non esisteranno le mosse avversarie e le
    /// risoluzioni di fine giornata: allora la chiusura tornerà a essere il punto
    /// di conferma che 05 §6.5 prevede, perché ci sarà qualcosa di giocato da
    /// disfare. Oggi non c'è nulla.
    func test_05_6_5_si_torna_indietro_di_piu_giornate_finche_ci_sono_ordini() async throws {
        let sessione = try await nuova(try slot(), gruppi: [(10, 6)])
        let id = await sessione.stato.gruppiOrdinati[0].id
        let iniziale = await sessione.impronta()
        for _ in 0..<3 { _ = try await sessione.esegui(.presidio(gruppo: id), parte: .giocatore) }
        let giorno = await sessione.stato.giorno
        XCTAssertEqual(giorno, 4, "tre giornate chiuse")
        for atteso in [3, 2, 1] {
            let esito = try await sessione.annulla(parte: .giocatore)
            XCTAssertTrue(esito.giornataRiaperta)
            XCTAssertEqual(esito.giorno, atteso)
        }
        let finale = await sessione.impronta()
        XCTAssertEqual(finale, iniziale, "si torna al principio della campagna")
    }
}
