import XCTest

/// Fumo dell'interfaccia del regno (05 §14.4; incarico 30), gemello di quelli dello scontro e della
/// mappa: qui risponde il servizio di accessibilità VERO del simulatore, e ciò che si prova è il
/// comportamento col tocco vero — il tocco apre la patria, l'inverno arriva, la leva si ordina e la
/// riserva scende, la primavera comincia, la campagna si apre e si torna in patria —, non la sola
/// geometria, che le prove ospitate già coprono (`PatriaTest`, `AnnoDelRegnoTest`).
final class FumoRegnoTest: XCTestCase {

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
    }

    private func elemento(_ app: XCUIApplication, cheComincia prefisso: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", prefisso)).firstMatch
    }

    @MainActor
    func test_dalla_patria_all_inverno_alla_primavera_e_alla_campagna() throws {
        let app = XCUIApplication()
        app.launch()

        let nuovo = app.buttons["Nuovo regno"]
        XCTAssertTrue(nuovo.waitForExistence(timeout: 10), "l'avvio espone l'ingresso al regno")
        nuovo.tap()

        // La patria: la data, le riserve voce per voce, le forze, i comandi dell'anno.
        XCTAssertTrue(app.staticTexts["Patria"].waitForExistence(timeout: 10), "si apre la patria")
        XCTAssertTrue(app.staticTexts["Anno 1, primavera"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["monete di bronzo: 20"].exists, "il riquadro delle riserve, voce per voce")
        XCTAssertTrue(elemento(app, cheComincia: "gruppo armato: ").exists, "le forze del regno")
        XCTAssertTrue(app.buttons["Apri la campagna"].exists)

        // L'inverno arriva col suo comando, e il bilancio nasce.
        app.buttons["Attendi l'inverno"].tap()
        XCTAssertTrue(app.staticTexts["Anno 1, inverno, schermata 1 di 4"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["monete di bronzo: 220"].waitForExistence(timeout: 5),
                      "l'entrata dell'anno si aggiunge alle riserve")

        // Una leva: il costo è dichiarato sulla riserva, e ordinandola la riserva scende.
        let leva = elemento(app, cheComincia: "Leva di fanteria leggera. Costa: monete di bronzo 30 su 220")
        XCTAssertTrue(leva.waitForExistence(timeout: 5), "la voce dichiara quanto costa su quanto se ne possiede")
        leva.tap()
        XCTAssertTrue(app.staticTexts["monete di bronzo: 190"].waitForExistence(timeout: 5),
                      "la spesa si vede nella riserva")
        XCTAssertTrue(app.staticTexts["Leva di fanteria leggera, pronta in primavera"].waitForExistence(timeout: 5),
                      "il lavoro ordinato entra in elenco")

        // L'annullamento restituisce le risorse; poi la leva si riordina.
        app.buttons["Annulla l'ultima spesa"].tap()
        XCTAssertTrue(app.staticTexts["monete di bronzo: 220"].waitForExistence(timeout: 5))
        elemento(app, cheComincia: "Leva di fanteria leggera. Costa: monete di bronzo 30 su 220").tap()
        XCTAssertTrue(app.staticTexts["monete di bronzo: 190"].waitForExistence(timeout: 5))

        // Le quattro schermate, poi la primavera con le reclute.
        for stazione in 2...4 {
            let prosegui = app.buttons["Prosegui alla schermata \(stazione) di 4"]
            XCTAssertTrue(prosegui.waitForExistence(timeout: 5))
            prosegui.tap()
            XCTAssertTrue(app.staticTexts["Anno 1, inverno, schermata \(stazione) di 4"].waitForExistence(timeout: 5))
        }
        app.buttons["Prosegui alla primavera"].tap()
        XCTAssertTrue(app.staticTexts["Anno 2, primavera"].waitForExistence(timeout: 5), "comincia la primavera")
        XCTAssertTrue(app.staticTexts["monete di bronzo: 20"].waitForExistence(timeout: 5),
                      "avanza un decimo dell'entrata dell'anno")

        // La campagna dell'anno si apre scegliendo il fronte, e dalla mappa si torna in patria.
        app.buttons["Apri la campagna"].tap()
        let fronte = app.buttons["fronte del guado, mappa 4 per 4"]
        XCTAssertTrue(fronte.waitForExistence(timeout: 5), "la scelta del fronte, una voce per fronte")
        fronte.tap()
        let primaCasella = elemento(app, cheComincia: "riga 1, casella 1")
        XCTAssertTrue(primaCasella.waitForExistence(timeout: 10), "si entra nella mappa del fronte")
        let torna = app.buttons["Torna in patria"]
        XCTAssertTrue(torna.waitForExistence(timeout: 5), "il comando d'uscita dice dove porta")
        torna.tap()
        XCTAssertTrue(app.buttons["Entra nel fronte del guado"].waitForExistence(timeout: 5),
                      "la patria dichiara la campagna aperta")
        XCTAssertTrue(app.staticTexts["Anno 2, primavera, giorno 1 di 90"].waitForExistence(timeout: 5),
                      "con la campagna aperta la data è quella del fronte")
    }

    /// In ORIZZONTALE e a TESTO MASSIMO, col tocco vero: la patria d'inverno si percorre fino
    /// all'ultimo comando, una leva si ordina, la schermata successiva si apre e si torna all'inizio.
    /// Il tocco di XCUITest porta in vista l'elemento con l'azione di scorrimento d'accessibilità,
    /// come VoiceOver: dove non ci riuscisse la prova fallirebbe con «Failed to scroll to visible».
    /// Il pilota con VoiceOver legge la patria in orizzontale ma non vi sa attivare nulla (il doppio
    /// tocco sintetico arriva soltanto in verticale): questa prova copre l'attivazione col dito.
    @MainActor
    func test_in_orizzontale_a_testo_massimo_l_inverno_si_percorre_e_la_leva_si_ordina() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                                "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()

        let nuovo = app.buttons["Nuovo regno"]
        XCTAssertTrue(nuovo.waitForExistence(timeout: 15), "l'avvio espone l'ingresso al regno")
        nuovo.tap()
        let inverno = app.buttons["Attendi l'inverno"]
        XCTAssertTrue(inverno.waitForExistence(timeout: 10), "il comando dell'inverno esiste")
        inverno.tap()
        XCTAssertTrue(app.staticTexts["Anno 1, inverno, schermata 1 di 4"].waitForExistence(timeout: 5))

        let leva = elemento(app, cheComincia: "Leva di cavalleria manovrata. Costa: monete di bronzo 72 su 220")
        XCTAssertTrue(leva.waitForExistence(timeout: 5), "la voce esiste con il costo sulla riserva")
        leva.tap()
        XCTAssertTrue(app.staticTexts["animali: 7"].waitForExistence(timeout: 5), "la spesa si vede nella riserva")

        let prosegui = app.buttons["Prosegui alla schermata 2 di 4"]
        XCTAssertTrue(prosegui.waitForExistence(timeout: 5))
        prosegui.tap()
        XCTAssertTrue(app.staticTexts["Anno 1, inverno, schermata 2 di 4"].waitForExistence(timeout: 5))

        let torna = app.buttons["Torna all'inizio"]
        XCTAssertTrue(torna.waitForExistence(timeout: 5), "l'ultimo comando della colonna esiste")
        torna.tap()
        XCTAssertTrue(app.buttons["Riprendi il regno"].waitForExistence(timeout: 10),
                      "tornati all'inizio, il regno in corso si può riprendere")
    }
}
