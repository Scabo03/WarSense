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

        // Le tessere del deck sono elementi propri e davvero raggiungibili
        // (00 §1.2, 02 §8.2): qui risponde il servizio di accessibilità vero, e la
        // prova è il comportamento — il tocco seleziona — non la sola geometria.
        for nome in ["fanteria leggera", "fanteria pesante", "tiratori"] {
            let tessera = app.descendants(matching: .any)[nome]
            XCTAssertTrue(tessera.waitForExistence(timeout: 10),
                          "la tessera «\(nome)» è un elemento a sé")
            tessera.tap()
            let selezionata = NSPredicate(format: "value CONTAINS %@", "selezionato")
            XCTAssertTrue(app.descendants(matching: .any).matching(selezionata)
                            .firstMatch.waitForExistence(timeout: 5),
                          "il tocco della tessera «\(nome)» la seleziona davvero")
        }

        // I comandi globali esistono, sono raggiungibili e agganciabili (02 §8.4).
        for titolo in ["Annulla l'ultima operazione", "Azzera lo schieramento del turno",
                       "Dichiara la resa", "Fine del turno"] {
            let comando = app.buttons[titolo]
            XCTAssertTrue(comando.exists, "il comando «\(titolo)» esiste")
            XCTAssertTrue(comando.isHittable, "il comando «\(titolo)» è agganciabile")
        }
    }
}
