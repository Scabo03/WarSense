import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// Collaudo della Sessione di campagna (05 §6): il giornale è la verità, le
/// istantanee sono soltanto velocità, la ripresa restituisce il punto di
/// interruzione, l'annullamento non retrocede oltre un punto di conferma.
final class SessioneCampagnaTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
    }

    private func slot() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("campagna-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func scenario(gruppi: [(Int, Int)] = [(10, 6), (10, 5), (9, 6)]) -> ScenarioCampagna {
        ScenarioCampagna(mappa: "pianura_lunga",
                         gruppiGiocatore: gruppi.map { .init(riga: $0.0, colonna: $0.1) })
    }

    private func nuova(_ cartella: URL, _ s: ScenarioCampagna) throws -> SessioneCampagna {
        try SessioneCampagna(nuova: s, valori: valori, valoriCampagna: valoriCampagna,
                             versioneTesti: "0.1.1", cartella: cartella,
                             seme: 4242, identificatore: "prova-campagna")
    }

    // MARK: - 05 §6.1 — il giornale è il salvataggio a ogni azione

    func test_05_6_1_ogni_ordine_e_appeso_al_giornale_prima_di_diventare_visibile() async throws {
        let cartella = try slot()
        let sessione = try await nuova(cartella, scenario())
        let righeIniziali = await sessione.numeroRigheGiornale
        let id = await sessione.stato.gruppiOrdinati[0].id
        _ = try await sessione.esegui(.presidio(gruppo: id), parte: .giocatore)
        let dopo = await sessione.numeroRigheGiornale
        XCTAssertEqual(dopo, righeIniziali + 1, "un ordine, una riga")
        // La riga è già su disco: il file la contiene senza chiudere la sessione.
        let contenuto = try String(contentsOf: cartella.appendingPathComponent("giornale.jsonl"),
                                   encoding: .utf8)
        XCTAssertTrue(contenuto.contains("presidio"), "la scrittura è confermata, non differita")
    }

    func test_05_6_1_un_ordine_non_valido_non_viene_ne_applicato_ne_registrato() async throws {
        let sessione = try await nuova(try slot(), scenario())
        let id = await sessione.stato.gruppiOrdinati[0].id
        _ = try await sessione.esegui(.presidio(gruppo: id), parte: .giocatore)
        let righe = await sessione.numeroRigheGiornale
        let (esito, eventi) = try await sessione.esegui(.presidio(gruppo: id), parte: .giocatore)
        XCTAssertEqual(esito.motivo, .azioneGiaSpesa)
        XCTAssertTrue(eventi.isEmpty)
        let dopo = await sessione.numeroRigheGiornale
        XCTAssertEqual(dopo, righe, "il giornale contiene le scelte effettive, non i tentativi")
    }

    // MARK: - 05 §6.3 — la ripresa restituisce il punto di interruzione

    func test_05_6_3_il_giornale_rigiocato_produce_lo_stesso_stato_registrato() async throws {
        let cartella = try slot()
        let sessione = try await nuova(cartella, scenario(gruppi: [(10, 6), (10, 5), (9, 6), (9, 5)]))
        // Alcune giornate intere, con marce e presidi alternati.
        for _ in 0..<3 {
            for gruppo in await sessione.stato.gruppiOrdinati {
                let vista = await sessione.vista(per: .giocatore)
                let destinazioni = vista.destinazioniValide(per: gruppo.id)
                let comando: ComandoCampagna = destinazioni.isEmpty
                    ? .presidio(gruppo: gruppo.id)
                    : .marcia(gruppo: gruppo.id, a: destinazioni[gruppo.id.numero % destinazioni.count])
                _ = try await sessione.esegui(comando, parte: .giocatore)
            }
        }
        let attesa = await sessione.impronta()
        let giorno = await sessione.stato.giorno
        XCTAssertGreaterThan(giorno, 1, "sono passate giornate intere")

        // Le istantanee si cancellano: la ripresa deve reggere sul solo giornale.
        for url in try FileManager.default.contentsOfDirectory(at: cartella, includingPropertiesForKeys: nil)
        where url.lastPathComponent.hasPrefix("istantanea-") {
            try FileManager.default.removeItem(at: url)
        }
        let ripresa = try await SessioneCampagna(riprendi: cartella, valori: valori,
                                                 valoriCampagna: valoriCampagna)
        let improntaRipresa = await ripresa.impronta()
        XCTAssertEqual(improntaRipresa, attesa,
                       "il giornale rigiocato produce uno stato diverso da quello registrato")
        let giornoRipresa = await ripresa.stato.giorno
        XCTAssertEqual(giornoRipresa, giorno)
    }

    func test_05_6_2_le_istantanee_sono_soltanto_velocita_e_la_verita_e_il_giornale() async throws {
        let cartella = try slot()
        let sessione = try await nuova(cartella, scenario(gruppi: [(10, 6), (10, 5)]))
        for gruppo in await sessione.stato.gruppiOrdinati {
            _ = try await sessione.esegui(.presidio(gruppo: gruppo.id), parte: .giocatore)
        }
        let attesa = await sessione.impronta()
        // Un'istantanea corrotta fa scalare alla precedente (05 §6.8).
        for url in try FileManager.default.contentsOfDirectory(at: cartella, includingPropertiesForKeys: nil)
        where url.lastPathComponent.hasPrefix("istantanea-") {
            try Data("guasta".utf8).write(to: url)
        }
        let ripresa = try await SessioneCampagna(riprendi: cartella, valori: valori,
                                                 valoriCampagna: valoriCampagna)
        let improntaRipresa = await ripresa.impronta()
        XCTAssertEqual(improntaRipresa, attesa)
    }

    // MARK: - 00 §15.2 — salvataggi versionati

    func test_00_15_2_un_salvataggio_con_versione_incompatibile_e_dichiarato_e_non_aperto() async throws {
        let cartella = try slot()
        _ = try await nuova(cartella, scenario())
        // Valori di una versione successiva, che non elenca fra le compatibili
        // quella del salvataggio: è il caso reale della taratura che avanza.
        let copia = FileManager.default.temporaryDirectory
            .appendingPathComponent("valori-avanti-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: Contenuti.valoriDiFabbrica, to: copia)
        addTeardownBlock { try? FileManager.default.removeItem(at: copia) }
        let manifest = copia.appendingPathComponent("manifest.json")
        var testo = try String(contentsOf: manifest, encoding: .utf8)
        testo = testo.replacingOccurrences(of: "\"" + valori.versione + "\"", with: "\"9.9.9\"")
        try testo.write(to: manifest, atomically: true, encoding: .utf8)
        let altri = try CaricatoreValori.carica(da: copia)
        XCTAssertEqual(altri.versione, "9.9.9")
        do {
            _ = try await SessioneCampagna(riprendi: cartella, valori: altri,
                                           valoriCampagna: valoriCampagna)
            XCTFail("il salvataggio incompatibile andava rifiutato")
        } catch let errore as SessioneCampagna.ErroreSessione {
            guard case .salvataggioIncompatibile(let attesa, let trovata) = errore else {
                return XCTFail("motivo di rifiuto sbagliato: \(errore)")
            }
            XCTAssertEqual(attesa, altri.versioneEffettiva)
            XCTAssertEqual(trovata, valori.versioneEffettiva)
        }
    }

    // MARK: - 05 §6.4, 00 §13.8 — annullamento e azzeramento

    func test_05_6_4_l_annullamento_ritira_l_ultimo_ordine_e_ricostruisce_lo_stato() async throws {
        let sessione = try await nuova(try slot(), scenario())
        let prima = await sessione.impronta()
        let id = await sessione.stato.gruppiOrdinati[0].id
        _ = try await sessione.esegui(.marcia(gruppo: id, a: Cella(riga: 10, colonna: 7)),
                                      parte: .giocatore)
        let dopo = await sessione.impronta()
        XCTAssertNotEqual(dopo, prima)
        try await sessione.annulla(parte: .giocatore)
        let ripristinata = await sessione.impronta()
        XCTAssertEqual(ripristinata, prima, "l'annullamento riporta esattamente allo stato di prima")
    }

    func test_05_6_4_l_azzeramento_ritira_tutti_gli_ordini_della_giornata() async throws {
        let sessione = try await nuova(try slot(), scenario(gruppi: [(10, 6), (10, 5), (9, 6)]))
        let apertura = await sessione.impronta()
        let ids = await sessione.stato.gruppiOrdinati.map(\.id)
        _ = try await sessione.esegui(.presidio(gruppo: ids[0]), parte: .giocatore)
        _ = try await sessione.esegui(.presidio(gruppo: ids[1]), parte: .giocatore)
        try await sessione.azzera(parte: .giocatore)
        let dopo = await sessione.impronta()
        XCTAssertEqual(dopo, apertura, "la giornata torna com'era all'apertura")
    }

    /// SOSTITUITA. Questa prova pretendeva che l'annullamento si fermasse alla
    /// chiusura della giornata, per la lettura letterale di 05 §6.5. Era la
    /// realizzazione di un difetto: l'ordine più esposto all'errore — l'ultimo
    /// della giornata, che la chiude come effetto non richiesto — era l'unico
    /// che non si potesse ritirare, contro 00 §13.8. Il comportamento voluto è ora
    /// in `AnnullamentoGiornataTest`; qui resta il solo caso che continua a valere.
    func test_05_6_4_l_annullamento_ritira_un_ordine_per_volta() async throws {
        let sessione = try await nuova(try slot(), scenario(gruppi: [(10, 6), (10, 5), (9, 6)]))
        let ids = await sessione.stato.gruppiOrdinati.map(\.id)
        _ = try await sessione.esegui(.presidio(gruppo: ids[0]), parte: .giocatore)
        let dopoIlPrimo = await sessione.impronta()
        _ = try await sessione.esegui(.presidio(gruppo: ids[1]), parte: .giocatore)
        try await sessione.annulla(parte: .giocatore)
        let dopoAnnullamento = await sessione.impronta()
        XCTAssertEqual(dopoAnnullamento, dopoIlPrimo,
                       "si ritira l'ultimo ordine, non due")
    }

    func test_05_6_4_dopo_l_annullamento_il_giornale_contiene_le_mosse_e_non_i_ripensamenti() async throws {
        let cartella = try slot()
        let sessione = try await nuova(cartella, scenario())
        let id = await sessione.stato.gruppiOrdinati[0].id
        _ = try await sessione.esegui(.marcia(gruppo: id, a: Cella(riga: 10, colonna: 7)),
                                      parte: .giocatore)
        try await sessione.annulla(parte: .giocatore)
        let contenuto = try String(contentsOf: cartella.appendingPathComponent("giornale.jsonl"),
                                   encoding: .utf8)
        XCTAssertFalse(contenuto.contains("marcia"),
                       "il ritiro è una riscrittura: la rigiocatura vede le mosse, non i ripensamenti (RDA-05)")
    }

    // MARK: - Il giornale di campagna e quello di battaglia convivono

    func test_00_15_il_giornale_di_campagna_non_disturba_quello_di_battaglia() async throws {
        // Slot distinti: una campagna aperta non tocca in alcun modo la ripresa di
        // uno scontro salvato, che è il vincolo dell'incarico.
        let cartellaCampagna = try slot()
        _ = try await nuova(cartellaCampagna, scenario())
        let cartellaBattaglia = try slot()
        try FileManager.default.createDirectory(at: cartellaBattaglia, withIntermediateDirectories: true)
        try FileManager.default.copyItem(
            at: SalvataggioBuildDistribuitaTest.cartellaFixture.appendingPathComponent("giornale.jsonl"),
            to: cartellaBattaglia.appendingPathComponent("giornale.jsonl"))
        let battaglia = try await SessioneBattaglia(riprendi: cartellaBattaglia, valori: valori)
        let impronta = await battaglia.impronta()
        let attesa = try String(contentsOf: SalvataggioBuildDistribuitaTest.cartellaFixture
            .appendingPathComponent("impronta.txt"), encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(impronta, attesa)
    }
}
