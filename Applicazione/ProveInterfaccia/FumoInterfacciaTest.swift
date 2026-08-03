import XCTest

/// Fumo dell'interfaccia (05 §14.4): l'applicazione parte, lo scontro si apre,
/// gli elementi dichiarati esistono con le loro etichette. Le verifiche fini del
/// fuoco stanno nelle prove ospitate, dove l'identità degli elementi è osservabile.
final class FumoInterfacciaTest: XCTestCase {

    @MainActor
    func test_avvio_e_apertura_dello_scontro() throws {
        let app = XCUIApplication()
        app.launch()

        let nuovo = app.buttons["Nuovo scontro di prova"]
        XCTAssertTrue(nuovo.waitForExistence(timeout: 10), "la schermata di avvio espone i comandi")
        nuovo.tap()

        let intestazione = app.staticTexts["Riserve da schierare"]
        XCTAssertTrue(intestazione.waitForExistence(timeout: 10),
                      "il deck ha l'intestazione dichiarata (02 §2.9)")

        // Le celle della griglia sono elementi accessibili con la testa fissa (00 §2.4, 02 §3.2).
        let cella = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "riga 1, cella 1")).firstMatch
        XCTAssertTrue(cella.waitForExistence(timeout: 10), "le celle sono elementi, non disegno")

        // I comandi globali esistono e sono raggiungibili (02 §8.4).
        XCTAssertTrue(app.buttons["Annulla l'ultima operazione"].exists)
        XCTAssertTrue(app.buttons["Azzera lo schieramento del turno"].exists)
        XCTAssertTrue(app.buttons["Fine del turno"].exists)
    }
}
