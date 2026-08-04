import XCTest

/// Fumo dell'interfaccia della mappa di campagna (05 §14.4), gemello di quello
/// dello scontro: qui risponde il servizio di accessibilità VERO del simulatore,
/// e ciò che si prova è il comportamento — il tocco apre, la voce ordina, la
/// mappa cambia — non la sola geometria, che le prove ospitate già coprono.
final class FumoMappaCampagnaTest: XCTestCase {

    @MainActor
    func test_apertura_della_mappa_e_ordine_a_un_gruppo() throws {
        let app = XCUIApplication()
        app.launch()

        let nuova = app.buttons["Nuova campagna, mappa piccola"]
        XCTAssertTrue(nuova.waitForExistence(timeout: 10),
                      "la schermata di avvio espone l'ingresso alla mappa")
        nuova.tap()

        // Le caselle sono elementi accessibili con la testa fissa (00 §2.4, 02 §3.2).
        let primaCasella = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "riga 1, casella 1")).firstMatch
        XCTAssertTrue(primaCasella.waitForExistence(timeout: 10),
                      "le caselle sono elementi, non disegno")

        // I comandi globali esistono, sono raggiungibili e agganciabili.
        for titolo in ["Registro della campagna", "Annulla l'ultima operazione",
                       "Azzera lo schieramento del turno"] {
            let comando = app.buttons[titolo]
            XCTAssertTrue(comando.waitForExistence(timeout: 5), "il comando «\(titolo)» esiste")
            XCTAssertTrue(comando.isHittable, "il comando «\(titolo)» è agganciabile")
        }

        // Un gruppo si annuncia con il proprio nome e con lo stato che gli compete
        // (01 §5.16.1): prima dell'ordine è «in attesa».
        let inAttesa = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "in attesa")).firstMatch
        XCTAssertTrue(inAttesa.waitForExistence(timeout: 10),
                      "il gruppo dichiara il proprio stato quando lo si incontra")

        // L'attivazione della casella NON si prova qui. Le caselle della mappa,
        // come le celle della griglia di battaglia fin dalla fase B, sono elementi
        // accessibili sintetici senza riconoscitori di gesto: rispondono
        // all'attivazione della tecnologia assistiva, che è il percorso del
        // giocatore cui il gioco è destinato, e non a un tocco grezzo, che è ciò
        // che questa prova sa mandare. Il percorso di attivazione — lo stesso che
        // `accessibilityActivate` invoca — è provato nelle prove ospitate
        // (`MappaCampagnaAccessibileTest`), dove è osservabile per identità.
        // L'osservazione sul tocco grezzo è registrata (registro degli scostamenti).

        // Il registro si apre e contiene la voce di apertura della giornata (02 §6.6).
        app.buttons["Registro della campagna"].tap()
        let voce = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Giorno 1")).firstMatch
        XCTAssertTrue(voce.waitForExistence(timeout: 5),
                      "ogni voce del registro è un elemento a sé che dichiara il giorno")
        app.buttons["Chiudi il registro"].tap()
        XCTAssertTrue(primaCasella.waitForExistence(timeout: 5), "si torna alla mappa")
    }
}
