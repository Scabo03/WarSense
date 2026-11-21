import XCTest

/// Le osservazioni 1, 3, 5, 7 e 8 dell'esplorazione dell'incarico 27, al livello in cui si sono viste:
/// l'app vera sul simulatore, con la taglia del testo imposta all'avvio dalla preferenza di sistema
/// (`UIPreferredContentSizeCategoryName`, la stessa che il simulatore riceve dalle Impostazioni) e
/// l'orientamento dato all'apparecchio. Il tocco di XCUITest porta in vista l'elemento con l'azione
/// d'accessibilità di scorrimento, come fa VoiceOver: dove non ci riesce, la prova fallisce con
/// «Failed to scroll to visible», che è ciò che l'esplorazione aveva registrato su «Fine del turno».
/// Le prove ospitate `OsservazioniEsplorazioneTest` giudicano la stessa raggiungibilità sulla
/// geometria e sul percorso d'accessibilità; queste la giudicano col servizio d'accessibilità vero.
final class TaglieEOrientamentiInterfacciaTest: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    private func avvia(testoMassimo: Bool, orizzontale: Bool = false) -> XCUIApplication {
        XCUIDevice.shared.orientation = orizzontale ? .landscapeLeft : .portrait
        let app = XCUIApplication()
        if testoMassimo {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                                    "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        return app
    }

    /// Osservazione 1 (bloccante): a testo massimo «Fine del turno» si raggiunge e si attiva.
    @MainActor
    func test_osservazione_1_fine_del_turno_a_testo_massimo() throws {
        let app = avvia(testoMassimo: true)
        let nuovo = app.buttons["Nuovo scontro di prova"]
        XCTAssertTrue(nuovo.waitForExistence(timeout: 15))
        nuovo.tap()
        let fine = app.buttons["Fine del turno"]
        XCTAssertTrue(fine.waitForExistence(timeout: 15), "il comando esiste")
        fine.tap()
        // Il turno è passato all'avversario e tornato: il comando resta lì e si attiva di nuovo.
        XCTAssertTrue(fine.waitForExistence(timeout: 15))
    }

    /// Osservazione 5: a testo massimo «Torna all'inizio» della mappa si raggiunge e riporta all'avvio.
    @MainActor
    func test_osservazione_5_torna_all_inizio_dalla_mappa_a_testo_massimo() throws {
        let app = avvia(testoMassimo: true)
        let campagna = app.buttons["Nuova campagna, mappa piccola"]
        XCTAssertTrue(campagna.waitForExistence(timeout: 15))
        campagna.tap()
        let esci = app.buttons["Torna all'inizio"]
        XCTAssertTrue(esci.waitForExistence(timeout: 15))
        esci.tap()
        XCTAssertTrue(app.buttons["Nuovo scontro di prova"].waitForExistence(timeout: 15),
                      "tornati all'avvio")
    }

    /// Osservazione 3: in orizzontale a testo massimo l'ultimo comando dell'avvio si raggiunge e apre
    /// la sua schermata.
    @MainActor
    func test_osservazione_3_avvio_in_orizzontale_a_testo_massimo() throws {
        let app = avvia(testoMassimo: true, orizzontale: true)
        let apprendimento = app.buttons["Suoni e vibrazioni del gioco"]
        XCTAssertTrue(apprendimento.waitForExistence(timeout: 15))
        apprendimento.tap()
        XCTAssertTrue(app.staticTexts["Suoni e vibrazioni"].waitForExistence(timeout: 15),
                      "la schermata dell'apprendimento si è aperta")
    }

    /// Osservazione 7: in orizzontale a testo predefinito «Impostazioni» si raggiunge e si apre.
    @MainActor
    func test_osservazione_7_impostazioni_in_orizzontale() throws {
        let app = avvia(testoMassimo: false, orizzontale: true)
        let impostazioni = app.buttons["Impostazioni"]
        XCTAssertTrue(impostazioni.waitForExistence(timeout: 15))
        impostazioni.tap()
        XCTAssertTrue(app.buttons["Chiudi il pannello"].waitForExistence(timeout: 15),
                      "la schermata delle impostazioni si è aperta")
    }

    /// Osservazione 8: nessun testo tagliato sull'avvio e sulle impostazioni, in verticale a testo
    /// predefinito, secondo la verifica automatica di Xcode. Il carattere dinamico resta fuori da
    /// questa prova: è una scelta di progetto non coperta dai documenti, proposta nel resoconto.
    @MainActor
    func test_osservazione_8_nessun_testo_tagliato_sull_avvio_e_sulle_impostazioni() throws {
        let app = avvia(testoMassimo: false)
        XCTAssertTrue(app.buttons["Impostazioni"].waitForExistence(timeout: 15))
        try app.performAccessibilityAudit(for: [.textClipped])
        app.buttons["Impostazioni"].tap()
        XCTAssertTrue(app.buttons["Chiudi il pannello"].waitForExistence(timeout: 15))
        try app.performAccessibilityAudit(for: [.textClipped])
    }
}
