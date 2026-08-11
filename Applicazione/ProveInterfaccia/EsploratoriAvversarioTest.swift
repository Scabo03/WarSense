import XCTest

/// La prova d'interfaccia NERA sull'interfaccia reale del simulatore (05 §14.4): apre la
/// campagna toccando il pulsante che il giocatore tocca, e legge la schermata attraverso
/// il servizio di accessibilità vero.
///
/// Accerta, sullo scenario che arriva in mano al giocatore, ciò che il programma di
/// verifica interno non poteva vedere (incarico 23): che fra le proprie formazioni ci
/// siano esploratori, e che il pannello di un esploratore offra l'esplorazione mentre
/// quello di un gruppo armato no. Fallisce sullo scenario privo di esploratori.
///
/// L'avvistamento dell'avversario e il riempimento arancione della sua casella — che
/// esigono di percorrere più giornate e di leggere il COLORE del disegno, che il servizio
/// nero non espone — sono accertati dalla prova ospitata gemella
/// `EsploratoriAvversarioInterfacciaTest`, che apre lo stesso scenario giocabile.
final class EsploratoriAvversarioTest: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    private func apriLaMappaPiccola() {
        let nuova = app.buttons["Nuova campagna, mappa piccola"]
        XCTAssertTrue(nuova.waitForExistence(timeout: 15),
                      "la schermata di avvio espone l'ingresso alla mappa")
        nuova.tap()
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "riga 1, casella 1")).firstMatch
            .waitForExistence(timeout: 15), "la mappa si apre e le caselle sono elementi")
    }

    /// (1) Fra le proprie formazioni esiste un esploratore: la sua casella si annuncia come
    /// «formazione di ricognizione». All'avvio nessun avversario è avvistato, sicché una
    /// casella con «ricognizione» e senza «avversaria» è una PROPRIA formazione di ricognizione.
    func test_incarico_23_esiste_una_formazione_di_ricognizione_del_giocatore() {
        apriLaMappaPiccola()
        let ricognizione = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@ AND NOT (label CONTAINS %@)",
                        "formazione di ricognizione", "avversaria")).firstMatch
        XCTAssertTrue(ricognizione.waitForExistence(timeout: 10),
                      "lo scenario giocabile non schiera alcuna formazione di ricognizione "
                      + "fra quelle del giocatore")
    }

    /// (2) Il pannello di un esploratore offre l'esplorazione; quello di un gruppo armato no.
    func test_incarico_23_il_pannello_dell_esploratore_offre_l_esplorazione_quello_armato_no() {
        apriLaMappaPiccola()

        // L'esploratore, in attesa e non avversario.
        let esploratore = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@ AND NOT (label CONTAINS %@)",
                        "formazione di ricognizione", "in attesa", "avversaria")).firstMatch
        XCTAssertTrue(esploratore.waitForExistence(timeout: 10),
                      "un esploratore del giocatore attende una decisione")
        esploratore.tap()
        XCTAssertTrue(app.buttons["Esplora la zona"].waitForExistence(timeout: 10),
                      "il pannello dell'esploratore offre l'esplorazione (01 §5.6.8.1)")
        app.buttons["Chiudi il pannello"].tap()

        // Un gruppo armato in attesa: «tuo …, in attesa», senza «ricognizione» né «non armata».
        let armato = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@ AND NOT (label CONTAINS %@) AND NOT (label CONTAINS %@)",
                        "in attesa", "ricognizione", "non armata")).firstMatch
        XCTAssertTrue(armato.waitForExistence(timeout: 10), "un gruppo armato attende una decisione")
        armato.tap()
        XCTAssertTrue(app.buttons["Presidia: resta fermo in guardia"].waitForExistence(timeout: 10),
                      "il pannello di un gruppo armato si è aperto")
        XCTAssertFalse(app.buttons["Esplora la zona"].exists,
                       "un gruppo armato NON offre l'esplorazione (01 §5.6.8.1)")
        app.buttons["Chiudi il pannello"].tap()
    }
}
