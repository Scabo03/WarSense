import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// La presa del quartier generale e il richiamo dell'esercito attraverso la Sessione (01 §5.18.2, §5.18.3;
/// incarico 32): i fatti che il giocatore riceve, il giornale che li rigioca identici, l'avversario che usa
/// la regola e se ne difende, l'annullamento che non li scavalca.
final class CompletamentoDellaCampagnaTest: XCTestCase {

    private var valori: ValoriDiGioco!
    private var valoriCampagna: ValoriCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
    }

    private let mio = Cella(riga: 4, colonna: 2), suo = Cella(riga: 1, colonna: 2)

    private func slot() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("campagna-32-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func armato(_ riga: Int, _ colonna: Int, _ atomi: Int = 6) -> ScenarioCampagna.GruppoIniziale {
        .init(riga: riga, colonna: colonna, composizione: [.init(archetipo: "fanteria_leggera", atomi: atomi)])
    }

    private func nuova(_ cartella: URL, _ giocatore: [ScenarioCampagna.GruppoIniziale],
                       _ avversario: [ScenarioCampagna.GruppoIniziale]) throws -> SessioneCampagna {
        try SessioneCampagna(
            nuova: ScenarioCampagna(mappa: "guado", gruppiGiocatore: giocatore, gruppiAvversario: avversario,
                                    calendario: CalendarioDiCampagna(anno: 1, giornatePerStagione: 30),
                                    regole: RegoleDiCampagna(giornatePerLaPresa: 3)),
            valori: valori, valoriCampagna: valoriCampagna, versioneTesti: "0.1.1", cartella: cartella,
            seme: 32, identificatore: "completamento")
    }

    private func riprendi(_ cartella: URL, senzaIstantanee: Bool) throws -> SessioneCampagna {
        if senzaIstantanee {
            for url in try FileManager.default.contentsOfDirectory(at: cartella, includingPropertiesForKeys: nil)
            where url.lastPathComponent.hasPrefix("istantanea-") { try FileManager.default.removeItem(at: url) }
        }
        return try SessioneCampagna(riprendi: cartella, valori: valori, valoriCampagna: valoriCampagna)
    }

    private func presa(_ eventi: [EventoCampagna]) -> [EventoCampagna] {
        eventi.filter {
            switch $0 {
            case .quartierGeneraleOccupato, .occupazioneProsegue, .occupazioneInterrotta, .quartierGeneralePreso,
                 .campagnaConclusa: return true
            default: return false
            }
        }
    }

    /// L'avversario entra nel quartier generale del giocatore, lo tiene e lo prende: il giocatore sente ogni
    /// passo, e in ogni momento il giornale rigiocato dà lo stesso stato.
    func test_01_5_18_3_l_avversario_prende_il_quartier_generale_e_il_giocatore_sente_ogni_passo() async throws {
        let cartella = try slot()
        var campagna = try nuova(cartella, [armato(1, 4)], [armato(3, 2)])
        var sentiti: [EventoCampagna] = []
        var giri = 0
        while await campagna.stato.conclusione == nil, giri < 20 {
            giri += 1
            let esito = try await campagna.chiudiGiornata()
            sentiti += presa(esito.eventi)
            let impronta = await campagna.impronta()
            campagna = try riprendi(cartella, senzaIstantanee: giri % 2 == 0)
            let ripresa = await campagna.impronta()
            XCTAssertEqual(ripresa, impronta, "giro \(giri)")
        }
        XCTAssertEqual(sentiti, [
            .quartierGeneraleOccupato(casella: mio, occupante: .avversario, mancano: 3),
            .occupazioneProsegue(casella: mio, occupante: .avversario, mancano: 2),
            .occupazioneProsegue(casella: mio, occupante: .avversario, mancano: 1),
            .campagnaConclusa(modo: .presa, vincitore: .avversario)])
        let stato = await campagna.stato
        XCTAssertEqual(stato.conclusione?.vincitore, .avversario)
        do {
            _ = try await campagna.chiudiGiornata()
            XCTFail("conclusa, la giornata non si chiude")
        } catch SessioneCampagna.ErroreSessione.campagnaConclusa {}
    }

    /// Il giocatore prende quello dell'avversario, e l'avversario torna a difenderlo: se vi entra nasce la
    /// battaglia, e vinta dall'occupante il conteggio riprende; il ritorno dalla battaglia lo dice.
    func test_01_5_18_3_2_l_avversario_torna_a_riprendere_il_proprio_e_la_battaglia_decide() async throws {
        let cartella = try slot()
        let campagna = try nuova(cartella, [armato(1, 2, 12), armato(4, 4)], [armato(3, 2)])
        var sentiti: [EventoCampagna] = []
        var giri = 0
        while await campagna.stato.battaglieInSospeso.isEmpty, await campagna.stato.conclusione == nil, giri < 10 {
            giri += 1
            sentiti += presa(try await campagna.chiudiGiornata().eventi)
        }
        XCTAssertEqual(sentiti.first, .quartierGeneraleOccupato(casella: suo, occupante: .giocatore, mancano: 3))
        let stato = await campagna.stato
        let battaglia = try XCTUnwrap(stato.battaglieInSospeso.first, "l'avversario entra nel proprio quartier generale a riprenderlo")
        XCTAssertEqual(battaglia.casella, suo)
        let mioGruppo = try XCTUnwrap(stato.gruppi[battaglia.gruppoGiocatore]), suoGruppo = try XCTUnwrap(stato.gruppi[battaglia.gruppoAvversario])
        // L'occupante perde e ripiega: il conteggio si azzera, e il ritorno dalla battaglia lo dice.
        let eventi = try await campagna.concludiBattaglia(EsitoInCampagna(
            identificatore: battaglia.identificatore, casella: suo, sconfitto: .giocatore, modo: .ritirataCompiuta,
            gruppoGiocatore: mioGruppo.id, gruppoAvversario: suoGruppo.id, composizioneGiocatore: mioGruppo.composizione,
            composizioneAvversario: suoGruppo.composizione, posizioneGiocatore: Cella(riga: 2, colonna: 1), posizioneAvversario: suo))
        XCTAssertEqual(presa(eventi).first, .occupazioneInterrotta(casella: suo, occupante: .giocatore))
        XCTAssertTrue(eventi.contains(.battagliaConclusa(casella: suo, giocatoreSconfitto: true)))
        let impronta = await campagna.impronta()
        let ripresa = try riprendi(cartella, senzaIstantanee: true)
        let improntaRipresa = await ripresa.impronta()
        XCTAssertEqual(improntaRipresa, impronta)
    }

    /// Il passo di un'occupazione sigilla la giornata (RDA-102): sentito, l'ordine che l'ha chiusa non si
    /// annulla più.
    func test_05_6_5_il_passo_di_un_occupazione_non_si_annulla() async throws {
        let cartella = try slot()
        // L'avversario ha soltanto un gruppo in marcia lunga: non agisce, e la chiusura non la sigillerebbe lui.
        let campagna = try nuova(cartella, [armato(1, 2)], [armato(4, 4)])
        let mioGruppo = await campagna.stato.gruppi(di: .giocatore)[0]
        let esito = try await campagna.esegui(.presidio(gruppo: mioGruppo.id), parte: .giocatore)
        XCTAssertEqual(presa(esito.eventi).first, .quartierGeneraleOccupato(casella: suo, occupante: .giocatore, mancano: 3))
        do {
            _ = try await campagna.annulla(parte: .giocatore)
            XCTFail("il passo dell'occupazione è stato sentito")
        } catch SessioneCampagna.ErroreSessione.oltreLaGiornataInCorso {}
    }

    // MARK: - Il richiamo (01 §5.18.2)

    func test_01_5_18_2_il_richiamo_conclude_la_campagna_sta_nel_giornale_e_non_si_annulla() async throws {
        let cartella = try slot()
        let campagna = try nuova(cartella, [armato(4, 2), armato(4, 4)], [armato(1, 2)])
        _ = try await campagna.chiudiGiornata()
        let impedimento = await campagna.impedimentoDelRichiamo
        XCTAssertNil(impedimento)
        let giorno = await campagna.stato.giorno
        let eventi = try await campagna.richiamaLEsercito()
        XCTAssertEqual(eventi, [.campagnaConclusa(modo: .richiamo, vincitore: .avversario)])
        let stato = await campagna.stato
        XCTAssertEqual(stato.conclusione, ConclusioneCampagna(modo: .richiamo, vincitore: .avversario, giorno: giorno))
        XCTAssertEqual(stato.gruppi(di: .giocatore).count, 2)
        // Sta nel giornale, e vi si rigioca, anche senza istantanee.
        let righe = try String(contentsOf: cartella.appendingPathComponent("giornale.jsonl"), encoding: .utf8)
        XCTAssertTrue(righe.contains("\"richiamoDellEsercito\":{\"giorno\":\(giorno)}"))
        let impronta = await campagna.impronta()
        for senza in [false, true] {
            let ripresa = try riprendi(cartella, senzaIstantanee: senza)
            let improntaRipresa = await ripresa.impronta()
            XCTAssertEqual(improntaRipresa, impronta)
        }
        // Non si annulla, e non si ripete.
        do { _ = try await campagna.annulla(parte: .giocatore); XCTFail("non si annulla") }
        catch SessioneCampagna.ErroreSessione.campagnaConclusa {}
        do { _ = try await campagna.richiamaLEsercito(); XCTFail("non si ripete") }
        catch SessioneCampagna.ErroreSessione.richiamoImpedito(let perche) { XCTAssertEqual(perche, .campagnaConclusa) }
    }

    func test_01_5_18_2_il_richiamo_impedito_si_rifiuta_col_motivo_e_non_scrive_nulla() async throws {
        let cartella = try slot()
        let campagna = try nuova(cartella, [armato(4, 1), armato(2, 2)], [armato(3, 2)])
        let righePrima = await campagna.numeroRigheGiornale
        let nome = await campagna.stato.occupante(di: Cella(riga: 2, colonna: 2))!.nome
        do { _ = try await campagna.richiamaLEsercito(); XCTFail("un gruppo ha il rifornimento tagliato") }
        catch SessioneCampagna.ErroreSessione.richiamoImpedito(let perche) {
            XCTAssertEqual(perche, .rifornimentoTagliato(gruppo: nome, casella: Cella(riga: 2, colonna: 2)))
        }
        let righeDopo = await campagna.numeroRigheGiornale
        XCTAssertEqual(righeDopo, righePrima)
        let conclusione = await campagna.stato.conclusione
        XCTAssertNil(conclusione)
    }

    /// Un giornale manomesso che richiama l'esercito quando non si può è rifiutato, non applicato.
    func test_05_6_8_un_richiamo_impossibile_nel_giornale_lo_dichiara_corrotto() async throws {
        let cartella = try slot()
        _ = try nuova(cartella, [armato(4, 1), armato(2, 2)], [armato(3, 2)])
        let url = cartella.appendingPathComponent("giornale.jsonl")
        var testo = try String(contentsOf: url, encoding: .utf8)
        let numero = testo.split(separator: "\n").count
        testo += "{\"numero\":\(numero),\"voce\":{\"richiamoDellEsercito\":{\"giorno\":1}}}\n"
        try testo.write(to: url, atomically: true, encoding: .utf8)
        XCTAssertThrowsError(try riprendi(cartella, senzaIstantanee: true)) {
            guard case SessioneCampagna.ErroreSessione.giornaleCorrotto = $0 else { return XCTFail("\($0)") }
        }
    }
}
