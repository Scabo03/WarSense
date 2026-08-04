import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// Collaudo della Sessione e criterio di uscita della fase A (05 §15.2):
/// una battaglia si gioca da collaudo, senza interfaccia, con giornale riproducibile.
final class SessioneBattagliaTest: XCTestCase {

    var valori: ValoriDiGioco!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
    }

    func cartellaProva() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("slot-prova-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    func scenario() -> ScenarioBattaglia {
        ScenarioBattaglia(
            formato: "quindici", caratteristica: "campo_aperto",
            primoOccupante: .giocatore, imboscata: false,
            deckGiocatore: [.init(archetipo: "fanteria_pesante", protezione: .antiPerforazione,
                                  atomi: 3, esemplari: 2)],
            deckAvversario: [.init(archetipo: "fanteria_leggera", protezione: .antiSaturazione,
                                   atomi: 3, esemplari: 2)])
    }

    @discardableResult
    func esegui(_ sessione: SessioneBattaglia, _ comando: ComandoBattaglia, _ parte: Parte,
                file: StaticString = #filePath, linea: UInt = #line) async throws -> [EventoBattaglia] {
        let (esito, eventi) = try await sessione.esegui(comando, parte: parte)
        XCTAssertTrue(esito.eValido, "comando non valido: \(String(describing: esito.motivo))",
                      file: file, line: linea)
        return eventi
    }

    /// Gioca una battaglia intera sul formato piccolo: schieramento, avanzata,
    /// ingaggio, mischie fino all'annientamento di una parte. Restituisce la sessione.
    func giocaBattagliaCompleta(in cartella: URL) async throws -> SessioneBattaglia {
        let sessione = try await SessioneBattaglia(
            nuova: scenario(), valori: valori, versioneTesti: "0.1.0",
            cartella: cartella, seme: 42, identificatore: "prova-fase-a")

        // Schieramento del giocatore: due fanterie pesanti nella propria zona (righe 3 e 4).
        try await esegui(sessione, .seleziona(indiceDeck: 0), .giocatore)
        try await esegui(sessione, .piazza(cella: Cella(riga: 3, colonna: 2)), .giocatore)
        try await esegui(sessione, .piazza(cella: Cella(riga: 3, colonna: 3)), .giocatore)
        try await esegui(sessione, .fineTurno, .giocatore)

        // Schieramento avversario nelle righe 1 e 2.
        try await esegui(sessione, .seleziona(indiceDeck: 0), .avversario)
        try await esegui(sessione, .piazza(cella: Cella(riga: 2, colonna: 2)), .avversario)
        try await esegui(sessione, .piazza(cella: Cella(riga: 2, colonna: 3)), .avversario)
        try await esegui(sessione, .fineTurno, .avversario)

        // Da qui un minimo guidatore tattico: ogni parte, nel proprio turno, ingaggia
        // l'adiacente quando può e altrimenti avanza verso il nemico più vicino.
        var giriDiSicurezza = 0
        while await sessione.stato.esito == nil && giriDiSicurezza < 300 {
            var stato = await sessione.stato
            let parte = stato.parteDiTurno
            for sciame in stato.sciamiOrdinati where sciame.parte == parte
                && !stato.impegnato(sciame.id) && !sciame.azioneSpesa {
                let nemici = stato.sciamiOrdinati.filter { $0.parte == parte.avversaria }
                guard !nemici.isEmpty else { break }
                let vicino = nemici.min {
                    stato.griglia.distanza(sciame.posizione, $0.posizione)
                        < stato.griglia.distanza(sciame.posizione, $1.posizione) }!
                if stato.griglia.distanza(sciame.posizione, vicino.posizione) == 1,
                   await sessione.anteprima(.ingaggia(sciame: sciame.id, bersaglio: vicino.id),
                                            parte: parte).eValido {
                    _ = try await sessione.esegui(.ingaggia(sciame: sciame.id, bersaglio: vicino.id),
                                                  parte: parte)
                } else if let passo = stato.griglia.vicini(di: sciame.posizione)
                    .filter({ stato.occupante(di: $0) == nil })
                    .min(by: { stato.griglia.distanza($0, vicino.posizione)
                        < stato.griglia.distanza($1, vicino.posizione) }),
                    stato.griglia.distanza(passo, vicino.posizione)
                        < stato.griglia.distanza(sciame.posizione, vicino.posizione),
                    await sessione.anteprima(.muovi(sciame: sciame.id, percorso: [passo]),
                                             parte: parte).eValido {
                    _ = try await sessione.esegui(.muovi(sciame: sciame.id, percorso: [passo]),
                                                  parte: parte)
                }
                stato = await sessione.stato
                if stato.esito != nil { break }
            }
            if await sessione.stato.esito == nil {
                try await esegui(sessione, .fineTurno, await sessione.stato.parteDiTurno)
            }
            giriDiSicurezza += 1
        }
        let esito = await sessione.stato.esito
        XCTAssertNotNil(esito, "la battaglia deve concludersi")
        XCTAssertEqual(esito?.modo, .annientamento,
                       "senza resa, la battaglia finisce per annientamento (01 §15.2.3)")
        return sessione
    }

    // MARK: - Criterio di uscita della fase A

    func test_criterio_di_uscita_battaglia_completa_con_giornale_riproducibile() async throws {
        let cartella = cartellaProva()
        let sessione = try await giocaBattagliaCompleta(in: cartella)
        let improntaFinale = await sessione.impronta()

        // Il giornale riproduce esattamente la partita (05 §4.5, §6.3).
        let ripresa = try await SessioneBattaglia(riprendi: cartella, valori: valori)
        let improntaRipresa = await ripresa.impronta()
        XCTAssertEqual(improntaFinale, improntaRipresa,
                       "stato iniziale più comandi del giornale: questa è l'intera definizione della partita")
    }

    // MARK: - Salvataggio a ogni azione (00 §3.5)

    func test_00_3_5_ripresa_esatta_a_meta_scontro() async throws {
        let cartella = cartellaProva()
        let sessione = try await SessioneBattaglia(
            nuova: scenario(), valori: valori, versioneTesti: "0.1.0",
            cartella: cartella, seme: 7, identificatore: "meta-scontro")
        try await esegui(sessione, .seleziona(indiceDeck: 0), .giocatore)
        try await esegui(sessione, .piazza(cella: Cella(riga: 4, colonna: 1)), .giocatore)
        // Interruzione in qualunque istante: anche la selezione vive nello stato (01 §6.6).
        let impronta = await sessione.impronta()
        let ripresa = try await SessioneBattaglia(riprendi: cartella, valori: valori)
        let improntaRipresa = await ripresa.impronta()
        XCTAssertEqual(impronta, improntaRipresa)
        let selezione = await ripresa.stato.selezione[.giocatore]
        XCTAssertEqual(selezione, 0, "l'elemento selezionato sopravvive alla ripresa (01 §6.6)")
    }

    // MARK: - Annullamento e azzeramento (05 §6.4, RDA-05)

    func test_00_13_8_annullamento_ultima_operazione() async throws {
        let cartella = cartellaProva()
        let sessione = try await SessioneBattaglia(
            nuova: scenario(), valori: valori, versioneTesti: "0.1.0",
            cartella: cartella, seme: 7, identificatore: "annulla")
        try await esegui(sessione, .seleziona(indiceDeck: 0), .giocatore)
        let improntaPrima = await sessione.impronta()
        try await esegui(sessione, .piazza(cella: Cella(riga: 4, colonna: 2)), .giocatore)
        try await sessione.annulla(parte: .giocatore)
        let improntaDopo = await sessione.impronta()
        XCTAssertEqual(improntaPrima, improntaDopo, "l'annullamento ritira l'ultimo comando")
        // Il giornale contiene soltanto le scelte effettive (RDA-05).
        let ripresa = try await SessioneBattaglia(riprendi: cartella, valori: valori)
        let improntaRipresa = await ripresa.impronta()
        XCTAssertEqual(improntaRipresa, improntaPrima)
    }

    func test_05_6_5_l_annullamento_non_scavalca_la_fine_del_turno() async throws {
        let cartella = cartellaProva()
        let sessione = try await SessioneBattaglia(
            nuova: scenario(), valori: valori, versioneTesti: "0.1.0",
            cartella: cartella, seme: 7, identificatore: "conferma")
        try await esegui(sessione, .seleziona(indiceDeck: 0), .giocatore)
        try await esegui(sessione, .piazza(cella: Cella(riga: 4, colonna: 2)), .giocatore)
        try await esegui(sessione, .fineTurno, .giocatore)
        do {
            try await sessione.annulla(parte: .giocatore)
            XCTFail("la fine del turno è un punto di conferma (05 §6.5)")
        } catch { /* atteso */ }
    }

    func test_00_13_8_azzeramento_dello_schieramento_del_turno() async throws {
        let cartella = cartellaProva()
        let sessione = try await SessioneBattaglia(
            nuova: scenario(), valori: valori, versioneTesti: "0.1.0",
            cartella: cartella, seme: 7, identificatore: "azzera")
        let improntaIniziale = await sessione.impronta()
        try await esegui(sessione, .seleziona(indiceDeck: 0), .giocatore)
        try await esegui(sessione, .piazza(cella: Cella(riga: 4, colonna: 1)), .giocatore)
        try await esegui(sessione, .piazza(cella: Cella(riga: 4, colonna: 2)), .giocatore)
        try await sessione.azzera(parte: .giocatore)
        let improntaDopo = await sessione.impronta()
        XCTAssertEqual(improntaIniziale, improntaDopo,
                       "l'azzeramento riporta al marcatore di inizio turno (05 §6.4)")
    }

    // MARK: - Salvataggi versionati (00 §15)

    func test_00_15_2_salvataggio_incompatibile_dichiarato_e_non_aperto() async throws {
        let cartella = cartellaProva()
        _ = try await giocaBattagliaCompleta(in: cartella)

        // Valori di una versione futura che non dichiara compatibilità con 0.1.0.
        let copia = FileManager.default.temporaryDirectory
            .appendingPathComponent("valori-futuri-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: Contenuti.valoriDiFabbrica, to: copia)
        addTeardownBlock { try? FileManager.default.removeItem(at: copia) }
        // La versione futura si ricava da quella corrente e non si scrive a mano:
        // così la prova non va ritoccata a ogni incremento della versione dei valori
        // (03 §9.2.1, che ne prescrive uno a ogni cambiamento di regole).
        let manifestURL = copia.appendingPathComponent("manifest.json")
        var manifesto = try JSONSerialization.jsonObject(
            with: Data(contentsOf: manifestURL)) as! [String: Any]
        let versioneCorrente = valori.versione
        let futura = versioneCorrente + ".futura"
        manifesto["versione"] = futura
        manifesto["versioni_compatibili"] = [futura]
        try JSONSerialization.data(withJSONObject: manifesto).write(to: manifestURL)
        let valoriFuturi = try CaricatoreValori.carica(da: copia)
        XCTAssertEqual(valoriFuturi.versione, futura)
        XCTAssertFalse(valoriFuturi.versioniCompatibili.contains(versioneCorrente),
                       "la versione futura non dichiara compatibilità con quella corrente")

        do {
            _ = try await SessioneBattaglia(riprendi: cartella, valori: valoriFuturi)
            XCTFail("un salvataggio incompatibile non si apre (00 §15.2)")
        } catch let errore as SessioneBattaglia.ErroreSessione {
            guard case .salvataggioIncompatibile(let attesa, let trovata) = errore else {
                return XCTFail("errore sbagliato: \(errore)")
            }
            // L'annuncio nomina le versioni attesa e trovata (05 §6.6). Le impronte
            // della copia non coincidono più con il manifest riscritto, quindi la
            // versione attesa porta il suffisso locale di RDA-45: si confronta la base.
            XCTAssertTrue(attesa.hasPrefix(futura), "attesa: \(attesa)")
            XCTAssertTrue(trovata.hasPrefix(versioneCorrente), "trovata: \(trovata)")
        }
    }

    // MARK: - Robustezza del giornale (05 §6.8)

    func test_05_6_8_riga_finale_corrotta_troncata_alla_ultima_integra() async throws {
        let cartella = cartellaProva()
        let sessione = try await SessioneBattaglia(
            nuova: scenario(), valori: valori, versioneTesti: "0.1.0",
            cartella: cartella, seme: 7, identificatore: "robustezza")
        try await esegui(sessione, .seleziona(indiceDeck: 0), .giocatore)
        try await esegui(sessione, .piazza(cella: Cella(riga: 4, colonna: 1)), .giocatore)
        let improntaPrima = await sessione.impronta()

        // Un guasto lascia una riga tronca in coda al giornale.
        let giornaleURL = cartella.appendingPathComponent("giornale.jsonl")
        let maniglia = try FileHandle(forWritingTo: giornaleURL)
        try maniglia.seekToEnd()
        try maniglia.write(contentsOf: Data("{\"numero\":99,\"voce\":{\"com".utf8))
        try maniglia.close()

        let ripresa = try await SessioneBattaglia(riprendi: cartella, valori: valori)
        let improntaRipresa = await ripresa.impronta()
        XCTAssertEqual(improntaRipresa, improntaPrima,
                       "la perdita massima possibile è l'ultimo comando, mai la partita (05 §6.8)")
    }
}
