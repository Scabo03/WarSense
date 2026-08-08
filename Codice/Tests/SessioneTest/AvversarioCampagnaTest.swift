import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// Collaudo dell'avversario attraverso la Sessione (incarico 18): i suoi comandi si
/// appendono allo stesso giornale del giocatore (RDA-42), una partita salvata e ripresa
/// dà lo stesso stato, e due partite con lo stesso giornale producono le stesse mosse
/// avversarie. La Sessione è l'unica via: nessuna seconda forma per i comandi avversari.
final class AvversarioCampagnaTest: XCTestCase {
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

    /// Uno scenario con avversario: giocatore in basso, avversario in alto.
    private func scenario() -> ScenarioCampagna {
        ScenarioCampagna(mappa: "pianura_lunga",
            gruppiGiocatore: [
                .init(riga: 9, colonna: 5, composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)]),
                .init(riga: 9, colonna: 6, composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)])],
            gruppiAvversario: [
                .init(riga: 2, colonna: 5, composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)]),
                .init(riga: 2, colonna: 6, composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)])])
    }

    private func nuova(_ cartella: URL) throws -> SessioneCampagna {
        try SessioneCampagna(nuova: scenario(), valori: valori, valoriCampagna: valoriCampagna,
                             versioneTesti: "0.1.1", cartella: cartella,
                             seme: 4242, identificatore: "prova-avversario")
    }

    /// Gioca `n` giornate presidiando ogni gruppo del giocatore in attesa: conclusa la
    /// giornata del giocatore, l'avversario muove e la giornata si chiude.
    private func giocaGiornate(_ sessione: SessioneCampagna, _ n: Int) async throws {
        for _ in 0..<n {
            let giornoPrima = await sessione.stato.giorno
            while true {
                let attesa = await sessione.stato.gruppiInAttesa(di: .giocatore)
                guard let g = attesa.first else { break }
                _ = try await sessione.esegui(.presidio(gruppo: g.id), parte: .giocatore)
                if await sessione.stato.giorno != giornoPrima { break }
            }
        }
    }

    // MARK: - L'avversario si muove e passa dal giornale (01 §5.6.11, RDA-42)

    func test_incarico_18_l_avversario_si_muove() async throws {
        let cartella = try slot()
        let sessione = try nuova(cartella)
        let inizialiAvv = await sessione.stato.gruppi(di: .avversario).map(\.posizione)
        try await giocaGiornate(sessione, 8)
        let finaliAvv = await sessione.stato.gruppi(di: .avversario).map(\.posizione)
        XCTAssertNotEqual(inizialiAvv, finaliAvv, "l'avversario non si è mosso in otto giornate")
        // Il giornale è cresciuto oltre i soli comandi del giocatore e i marcatori: vi
        // sono i comandi dell'avversario (non c'è un secondo giornale).
        let righe = await sessione.numeroRigheGiornale
        XCTAssertGreaterThan(righe, 8, "il giornale non contiene le mosse avversarie")
    }

    // MARK: - Due partite con lo stesso giornale danno le stesse mosse (01 §12.1)

    func test_incarico_18_stesso_giornale_stesse_mosse() async throws {
        let a = try nuova(try slot())
        try await giocaGiornate(a, 10)
        let improntaA = await a.impronta()

        let b = try nuova(try slot())
        try await giocaGiornate(b, 10)
        let improntaB = await b.impronta()

        XCTAssertEqual(improntaA, improntaB,
                       "due partite con gli stessi comandi divergono: l'avversario non è deterministico")
    }

    // MARK: - Una partita salvata e ripresa dà lo stesso stato (05 §6.3, RDA-42)

    func test_incarico_18_salvata_e_ripresa_da_lo_stesso_stato() async throws {
        let cartella = try slot()
        let a = try nuova(cartella)
        try await giocaGiornate(a, 10)
        let improntaViva = await a.impronta()

        // Ripresa dal solo giornale su disco: le mosse avversarie si riapplicano senza
        // reinterrogare l'avversario (RDA-42), e lo stato deve coincidere.
        let ripresa = try SessioneCampagna(riprendi: cartella, valori: valori,
                                           valoriCampagna: valoriCampagna)
        let improntaRipresa = await ripresa.impronta()
        XCTAssertEqual(improntaViva, improntaRipresa,
                       "la partita ripresa dal giornale non riproduce lo stato, comprese le mosse avversarie")
    }
}
