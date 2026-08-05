import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// Il confine dell'annullamento alla giornata (00 §13.8, 05 §6.5).
///
/// Dentro la giornata l'annullamento è pieno, perché la giornata è un budget che si
/// consuma e 00 §13.8 vuole che ogni budget che si consuma abbia l'annullamento
/// dell'ultima operazione: «senza annullamento il giocatore paga un errore di
/// manovra come se fosse stata una scelta tattica». Vi rientra l'ordine impartito
/// all'ultimo gruppo, quello la cui conferma chiude la giornata: annullarlo riapre
/// la giornata appena chiusa e riporta il giorno indietro.
///
/// Oltre quel confine, cioè per gli ordini appartenenti a giornate precedenti,
/// l'annullamento è rifiutato con il proprio motivo dichiarato: annullare dopo la
/// chiusura, quando esisteranno le mosse avversarie e le risoluzioni di fine
/// giornata, equivarrebbe alla prova a rovescio (decisione del titolare, RDA-73).
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

    /// La partita, senza il registro: posizioni, azioni spese e giorno. È ciò che
    /// l'annullamento deve riportare com'era. Il registro invece CRESCE, perché
    /// l'annullamento è a sua volta un fatto avvenuto e va annotato (01 §5.17).
    private func partita(_ stato: StatoCampagna) -> String {
        stato.gruppiOrdinati
            .map { "\($0.id.numero)@\($0.posizione.riga)-\($0.posizione.colonna):\($0.azioneSpesa)" }
            .joined(separator: "|") + "#giorno=\(stato.giorno)"
    }

    // MARK: - 00 §13.8 — l'ordine che chiude la giornata si annulla e la riapre

    func test_00_13_8_annullare_l_ordine_che_ha_chiuso_la_giornata_la_riapre() async throws {
        let cartella = try slot()
        let sessione = try await nuova(cartella, gruppi: [(10, 6), (10, 5)])
        let ids = await sessione.stato.gruppiOrdinati.map(\.id)

        _ = try await sessione.esegui(.presidio(gruppo: ids[0]), parte: .giocatore)
        let partitaPrima = await partita(sessione.stato)
        let vociPrima = await sessione.stato.registro.count
        let giornoPrima = await sessione.stato.giorno
        XCTAssertEqual(giornoPrima, 1)

        _ = try await sessione.esegui(.presidio(gruppo: ids[1]), parte: .giocatore)
        let giornoDopo = await sessione.stato.giorno
        XCTAssertEqual(giornoDopo, 2, "l'ultimo ordine ha chiuso la giornata")

        let esito = try await sessione.annulla(parte: .giocatore)
        XCTAssertTrue(esito.giornataRiaperta, "l'annullamento dichiara di aver riaperto la giornata")
        XCTAssertEqual(esito.giorno, 1)

        let dopo = await sessione.stato
        XCTAssertEqual(dopo.giorno, 1, "il giorno torna indietro con l'ordine annullato")
        XCTAssertEqual(partita(dopo), partitaPrima,
                       "l'annullamento riporta la partita ESATTAMENTE com'era prima dell'ordine")
        XCTAssertEqual(dopo.gruppiInAttesa().map(\.id), [ids[1]],
                       "torna in attesa il solo gruppo il cui ordine è stato ritirato")
        // Il registro non torna indietro: l'annullamento è un fatto avvenuto.
        XCTAssertEqual(dopo.registro.count, vociPrima + 1)
        XCTAssertEqual(dopo.registro.last?.fatto, .ordineAnnullato)
        XCTAssertEqual(dopo.registro.last?.giorno, 1, "la voce dichiara il giorno riaperto")
    }

    // MARK: - 05 §6.5 — oltre la giornata in corso l'annullamento è rifiutato

    /// Il confine morde qui: nella giornata nuova è già accaduto qualcosa, e
    /// l'ordine con cui la precedente si è chiusa appartiene ormai al passato.
    func test_05_6_5_un_ordine_di_una_giornata_precedente_non_si_annulla() async throws {
        let sessione = try await nuova(try slot(), gruppi: [(10, 6)])
        let id = await sessione.stato.gruppiOrdinati[0].id
        _ = try await sessione.esegui(.presidio(gruppo: id), parte: .giocatore) // chiude il giorno 1
        _ = try await sessione.esegui(.presidio(gruppo: id), parte: .giocatore) // chiude il giorno 2
        let giorno = await sessione.stato.giorno
        XCTAssertEqual(giorno, 3)

        // Il primo annullamento ritira l'ordine del giorno 2 e riapre il giorno 2.
        let primo = try await sessione.annulla(parte: .giocatore)
        XCTAssertEqual(primo.giorno, 2)
        // Il secondo pretenderebbe l'ordine del giorno 1: rifiutato.
        await XCTAssertRifiutaOltreLaGiornata { try await sessione.annulla(parte: .giocatore) }
        let fermo = await sessione.stato.giorno
        XCTAssertEqual(fermo, 2, "il rifiuto non muove nulla")
        // E lo stesso vale per l'azzeramento: stessa regola (05 §6.5).
        await XCTAssertRifiutaOltreLaGiornata { try await sessione.azzera(parte: .giocatore) }
    }

    /// Il confine non è il ripristino del comportamento della build 11: l'ordine che
    /// chiude la giornata resta annullabile, perché lo è per la sua natura e non per
    /// la sua posizione nella sequenza (00 §13.8). Vale finché la giornata nuova è
    /// intatta, ed è precisamente il caso del giocatore che si accorge subito.
    func test_05_6_5_il_confine_non_rende_irreversibile_l_ordine_dell_ultimo_gruppo() async throws {
        let sessione = try await nuova(try slot(), gruppi: [(10, 6), (10, 5)])
        let ids = await sessione.stato.gruppiOrdinati.map(\.id)
        for id in ids { _ = try await sessione.esegui(.presidio(gruppo: id), parte: .giocatore) }
        let chiusa = await sessione.stato.giorno
        XCTAssertEqual(chiusa, 2)
        let esito = try await sessione.annulla(parte: .giocatore)
        XCTAssertTrue(esito.giornataRiaperta, "l'ordine che chiude la giornata NON è irreversibile")
    }

    // MARK: - 00 §13.8 — l'azzeramento svuota la giornata corrente e non oltre

    func test_00_13_8_azzerare_dopo_la_chiusura_riapre_la_giornata_e_la_svuota() async throws {
        let cartella = try slot()
        let sessione = try await nuova(cartella, gruppi: [(10, 6), (10, 5), (9, 6)])
        let apertura = await partita(sessione.stato)
        let ids = await sessione.stato.gruppiOrdinati.map(\.id)
        for id in ids { _ = try await sessione.esegui(.presidio(gruppo: id), parte: .giocatore) }
        let giornoDopo = await sessione.stato.giorno
        XCTAssertEqual(giornoDopo, 2)

        let esito = try await sessione.azzera(parte: .giocatore)
        XCTAssertTrue(esito.giornataRiaperta)
        XCTAssertEqual(esito.giorno, 1)
        let dopo = await sessione.stato
        XCTAssertEqual(partita(dopo), apertura, "la giornata torna com'era all'apertura")
        XCTAssertEqual(dopo.gruppiInAttesa().count, 3, "tutti i gruppi tornano ad attendere")
        XCTAssertEqual(dopo.registro.last?.fatto, .giornataAzzerata)
    }

    /// L'azzeramento non oltrepassa il confine: svuota la giornata corrente e si
    /// ferma. Le giornate precedenti restano com'erano.
    func test_00_13_8_l_azzeramento_si_ferma_alla_giornata_corrente() async throws {
        let sessione = try await nuova(try slot(), gruppi: [(10, 6), (10, 5)])
        let ids = await sessione.stato.gruppiOrdinati.map(\.id)
        for id in ids { _ = try await sessione.esegui(.presidio(gruppo: id), parte: .giocatore) }
        // Giorno 2: un ordine solo, la giornata resta aperta.
        _ = try await sessione.esegui(.presidio(gruppo: ids[0]), parte: .giocatore)
        let esito = try await sessione.azzera(parte: .giocatore)
        XCTAssertFalse(esito.giornataRiaperta, "si azzera la giornata in corso, non la precedente")
        let dopo = await sessione.stato
        XCTAssertEqual(dopo.giorno, 2)
        XCTAssertEqual(dopo.gruppiInAttesa().count, 2, "il giorno 2 è tornato vuoto")
        // Gli ordini del giorno 1 sono ancora nel registro, e non si annullano più.
        XCTAssertTrue(dopo.registro.contains { $0.giorno == 1 })
        await XCTAssertRifiutaOltreLaGiornata { try await sessione.annulla(parte: .giocatore) }
    }

    // MARK: - 05 §6.3 — il giornale rigiocato dà lo stesso stato

    /// Il giornale è la verità (05 §6.2): dopo l'annullamento, riaprire lo slot dal
    /// solo giornale deve dare lo stesso stato, REGISTRO COMPRESO. Senza questa
    /// prova l'annullamento potrebbe aggiustare lo stato in memoria e lasciare sul
    /// disco una partita diversa, difetto che si manifesta soltanto al riavvio.
    func test_05_6_3_il_giornale_rigiocato_dopo_l_annullamento_da_lo_stesso_stato() async throws {
        let cartella = try slot()
        let sessione = try await nuova(cartella, gruppi: [(10, 6), (10, 5), (9, 6)])
        let ids = await sessione.stato.gruppiOrdinati.map(\.id)
        _ = try await sessione.esegui(.marcia(gruppo: ids[0], a: Cella(riga: 10, colonna: 7), giorni: 1),
                                      parte: .giocatore)
        _ = try await sessione.esegui(.presidio(gruppo: ids[1]), parte: .giocatore)
        let partitaPrima = await partita(sessione.stato)
        _ = try await sessione.esegui(.presidio(gruppo: ids[2]), parte: .giocatore)
        _ = try await sessione.annulla(parte: .giocatore)
        let improntaMemoria = await sessione.impronta()
        let dopo = await sessione.stato
        XCTAssertEqual(partita(dopo), partitaPrima, "la partita è tornata dov'era")

        // Le istantanee si cancellano: la ripresa deve reggere sul solo giornale.
        for url in try FileManager.default.contentsOfDirectory(at: cartella, includingPropertiesForKeys: nil)
        where url.lastPathComponent.hasPrefix("istantanea-") {
            try FileManager.default.removeItem(at: url)
        }
        let ripresa = try await SessioneCampagna(riprendi: cartella, valori: valori,
                                                 valoriCampagna: valoriCampagna)
        let improntaDisco = await ripresa.impronta()
        XCTAssertEqual(improntaDisco, improntaMemoria,
                       "sul disco è rimasta una partita diversa da quella in memoria")
        let giorno = await ripresa.stato.giorno
        XCTAssertEqual(giorno, 1)
        // La voce di annullamento sopravvive alla ripresa: è un fatto, non un
        // effetto collaterale della sessione in corso.
        let vociRipresa = await ripresa.stato.registro
        XCTAssertEqual(vociRipresa.last?.fatto, .ordineAnnullato)
    }

    /// Il confine si legge dal giornale e non dallo stato: deve valere identico
    /// dopo un riavvio, altrimenti chi chiude e riapre l'applicazione si ritrova la
    /// libertà che il confine toglie.
    func test_05_6_5_il_confine_sopravvive_alla_ripresa_della_campagna() async throws {
        let cartella = try slot()
        let sessione = try await nuova(cartella, gruppi: [(10, 6)])
        let id = await sessione.stato.gruppiOrdinati[0].id
        _ = try await sessione.esegui(.presidio(gruppo: id), parte: .giocatore)
        _ = try await sessione.esegui(.presidio(gruppo: id), parte: .giocatore)
        _ = try await sessione.annulla(parte: .giocatore) // riapre il giorno 2

        let ripresa = try await SessioneCampagna(riprendi: cartella, valori: valori,
                                                 valoriCampagna: valoriCampagna)
        await XCTAssertRifiutaOltreLaGiornata { try await ripresa.annulla(parte: .giocatore) }
    }

    // MARK: - Casi ordinari

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

    /// Non c'è nulla da annullare quando nessun ordine è stato impartito: è un
    /// motivo DIVERSO dal rifiuto al confine, e i due non si confondono.
    func test_05_6_4_senza_ordini_non_c_e_nulla_da_annullare() async throws {
        let sessione = try await nuova(try slot(), gruppi: [(10, 6)])
        for operazione in [{ try await sessione.annulla(parte: .giocatore) },
                           { try await sessione.azzera(parte: .giocatore) }] {
            do {
                _ = try await operazione()
                XCTFail("non c'era alcun ordine")
            } catch let errore as SessioneCampagna.ErroreSessione {
                guard case .operazioneNonDisponibile = errore else {
                    return XCTFail("motivo sbagliato: \(errore)")
                }
            }
        }
    }
}

/// Il rifiuto al confine ha il proprio motivo e non si confonde con «niente da
/// annullare»: c'è qualcosa da annullare, ed è fuori portata.
func XCTAssertRifiutaOltreLaGiornata(_ operazione: () async throws -> SessioneCampagna.EsitoAnnullamento,
                                     file: StaticString = #filePath, line: UInt = #line) async {
    do {
        _ = try await operazione()
        XCTFail("l'annullamento doveva essere rifiutato al confine della giornata", file: file, line: line)
    } catch let errore as SessioneCampagna.ErroreSessione {
        guard case .oltreLaGiornataInCorso = errore else {
            return XCTFail("motivo sbagliato: \(errore)", file: file, line: line)
        }
    } catch {
        XCTFail("errore inatteso: \(error)", file: file, line: line)
    }
}
