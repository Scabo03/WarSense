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
        XCTAssertTrue(elemento(app, cheComincia: "Corvo, gruppo armato: ").exists,
                      "le forze del regno, ciascuna col suo nome")
        XCTAssertTrue(app.buttons["Apri la campagna"].exists)

        // Chi parte si sceglie col dito (incarico 31): toccata, la formazione resta in patria; toccata
        // di nuovo, riparte. La riga dice sempre dove va.
        let cervo = elemento(app, cheComincia: "Cervo, formazione non armata: ")
        XCTAssertTrue(cervo.exists)
        XCTAssertTrue(cervo.label.hasSuffix("Parte per il fronte"), cervo.label)
        cervo.tap()
        XCTAssertTrue(elemento(app, cheComincia: "Cervo, formazione non armata: 4 atomi di fanteria leggera. Resta in patria")
            .waitForExistence(timeout: 5), "la formazione toccata resta in patria")
        elemento(app, cheComincia: "Cervo, formazione non armata: ").tap()
        XCTAssertTrue(elemento(app, cheComincia: "Cervo, formazione non armata: 4 atomi di fanteria leggera. Parte per il fronte")
            .waitForExistence(timeout: 5), "toccata di nuovo, riparte")

        // L'inverno arriva col suo comando, e il bilancio nasce.
        app.buttons["Attendi l'inverno"].tap()
        XCTAssertTrue(app.staticTexts["Anno 1, inverno, schermata 1 di 4"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["monete di bronzo: 193"].waitForExistence(timeout: 5),
                      "l'entrata dell'anno si aggiunge alle riserve, e il mantenimento ne esce")
        XCTAssertTrue(app.staticTexts["Mantenimento dell'esercito, prelevato all'inizio dell'inverno: monete di bronzo 27"].exists,
                      "la prima schermata dichiara il mantenimento (01 §4.14.1.1)")
        // Le linguette, per durata: le più lunghe per prime (01 §5.9.1.3).
        for linguetta in ["Lavori lunghi", "Lavori di media durata", "Lavori brevi"] {
            XCTAssertTrue(app.staticTexts[linguetta].exists, linguetta)
        }

        // Una leva: il costo è dichiarato sulla riserva, e ordinandola la riserva scende.
        let leva = elemento(app, cheComincia: "Leva di fanteria leggera. Costa: monete di bronzo 30 su 193")
        XCTAssertTrue(leva.waitForExistence(timeout: 5), "la voce dichiara quanto costa su quanto se ne possiede")
        leva.tap()
        XCTAssertTrue(app.staticTexts["monete di bronzo: 163"].waitForExistence(timeout: 5),
                      "la spesa si vede nella riserva")
        XCTAssertTrue(app.staticTexts["Leva di fanteria leggera, pronta in primavera"].waitForExistence(timeout: 5),
                      "il lavoro ordinato entra in elenco")

        // L'annullamento restituisce le risorse; poi la leva si riordina.
        app.buttons["Annulla l'ultima spesa"].tap()
        XCTAssertTrue(app.staticTexts["monete di bronzo: 193"].waitForExistence(timeout: 5))
        elemento(app, cheComincia: "Leva di fanteria leggera. Costa: monete di bronzo 30 su 193").tap()
        XCTAssertTrue(app.staticTexts["monete di bronzo: 163"].waitForExistence(timeout: 5))

        // L'addestramento mirato si ordina su un reparto scelto da un elenco (01 §4.13): ogni
        // scelta dichiara il proprio costo sulla riserva.
        elemento(app, cheComincia: "Addestramento mirato. Si sceglie il reparto.").tap()
        XCTAssertTrue(app.staticTexts["Per quale reparto?"].waitForExistence(timeout: 5), "si apre la scelta del reparto")
        let reparto = elemento(app, cheComincia: "Lupo: 8 atomi di fanteria pesante. Costa: monete di bronzo 32 su 163")
        XCTAssertTrue(reparto.waitForExistence(timeout: 5), "la scelta dichiara il costo sulla riserva")
        reparto.tap()
        XCTAssertTrue(app.staticTexts["monete di bronzo: 131"].waitForExistence(timeout: 5),
                      "scelto il reparto, il lavoro è ordinato e pagato")
        XCTAssertTrue(app.staticTexts["Addestramento mirato per 8 atomi di fanteria pesante di Lupo, pronto in primavera"]
            .waitForExistence(timeout: 5))

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
        // Le formazioni hanno i nomi di prima; le reclute ne hanno uno nuovo e dicono dove entrano; il
        // reparto addestrato lo dichiara.
        XCTAssertTrue(elemento(app, cheComincia: "Lince, gruppo armato, reclute dell'inverno: 6 atomi di fanteria leggera. Entra sul fronte in primavera").exists)
        XCTAssertTrue(elemento(app, cheComincia: "Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante con addestramento mirato").exists)

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

        let leva = elemento(app, cheComincia: "Leva di cavalleria manovrata. Costa: monete di bronzo 72 su 193")
        XCTAssertTrue(leva.waitForExistence(timeout: 5), "la voce esiste con il costo sulla riserva")
        leva.tap()
        XCTAssertTrue(app.staticTexts["animali: 7"].waitForExistence(timeout: 5), "la spesa si vede nella riserva")

        // La scelta del reparto, in orizzontale e a testo massimo: si apre, la scelta si tocca, si torna.
        elemento(app, cheComincia: "Addestramento mirato. Si sceglie il reparto.").tap()
        XCTAssertTrue(app.staticTexts["Per quale reparto?"].waitForExistence(timeout: 5))
        let reparto = elemento(app, cheComincia: "Cervo: 4 atomi di fanteria leggera. Costa: monete di bronzo 16 su 121")
        XCTAssertTrue(reparto.waitForExistence(timeout: 5), "l'ultima scelta dell'elenco esiste")
        reparto.tap()
        XCTAssertTrue(app.staticTexts["monete di bronzo: 105"].waitForExistence(timeout: 5),
                      "la scelta in fondo all'elenco si raggiunge e si ordina")

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
