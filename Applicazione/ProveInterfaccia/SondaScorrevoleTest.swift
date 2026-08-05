import XCTest
final class SondaScorrevoleTest: XCTestCase {
    func test_sonda() throws {
        let app = XCUIApplication(); app.launch()
        app.buttons["Nuova campagna, mappa grande"].tap()
        let gruppo = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "in attesa")).firstMatch
        XCTAssertTrue(gruppo.waitForExistence(timeout: 15))
        let finestra = app.windows.firstMatch.frame
        let bordoComandi = app.buttons["Registro della campagna"].frame.minY
        print("SONDA finestra=\(finestra) bordoComandi=\(bordoComandi)")
        for tentativo in 0..<8 {
            let g = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS %@", "in attesa")).firstMatch
            guard g.exists else { print("SONDA t\(tentativo) gruppo sparito"); break }
            print("SONDA t\(tentativo) etichetta=\(g.label.prefix(40)) frame=\(g.frame)")
            g.tap()
            let aperto = app.buttons["Chiudi il pannello"].waitForExistence(timeout: 2)
            print("SONDA t\(tentativo) pannello=\(aperto)")
            if aperto { app.buttons["Chiudi il pannello"].tap(); break }
            app.swipeUp()
        }
    }
}
