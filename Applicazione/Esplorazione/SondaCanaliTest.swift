import XCTest

/// Sonde minime dei canali di automazione (incarico 27, prima parte). NON sono
/// prove del collaudo: vivono nel bersaglio `WarSenseEsplorazione`, che lo schema
/// `WarSense` non esegue, e non asseriscono nulla sul gioco. Accertano soltanto che
/// cosa ciascun canale sa fare davvero su questo simulatore, e lo stampano con il
/// prefisso «SONDA|» perché l'uscita si legga dal registro della corsa.
final class SondaCanaliTest: XCTestCase {

    override func setUp() {
        continueAfterFailure = true
    }

    private func stampa(_ riga: String) { print("SONDA|\(riga)") }

    /// Il servizio VoiceOver delle prove d'interfaccia (iOS 27): accensione,
    /// spostamento del fuoco nei due versi, lettura della pronuncia, ingresso e
    /// uscita da un contenitore, spegnimento.
    @MainActor
    func test_sonda_1_servizio_voiceover() throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("servizio VoiceOver solo da iOS 27") }
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons.firstMatch.waitForExistence(timeout: 15))
        let vo = XCUIDevice.shared.voiceOverService
        stampa("prima dell'accensione: isEnabled=\(vo.isEnabled)")
        let t0 = Date()
        try vo.enable()
        stampa("accensione: isEnabled=\(vo.isEnabled) in \(String(format: "%.2f", Date().timeIntervalSince(t0)))s")
        do { stampa("corrente all'avvio: «\(try vo.currentSpeech().utterance)»") }
        catch { stampa("corrente all'avvio: ERRORE \(error)") }
        var pronunce: [String] = []
        for passo in 1...12 {
            let t = Date()
            do {
                let u = try vo.moveForward().utterance
                pronunce.append(u)
                stampa("avanti \(passo): «\(u)» (\(String(format: "%.2f", Date().timeIntervalSince(t)))s)")
            } catch {
                stampa("avanti \(passo): ERRORE \(error)")
            }
        }
        do { stampa("corrente: «\(try vo.currentSpeech().utterance)»") } catch { stampa("corrente: ERRORE \(error)") }
        do { stampa("indietro: «\(try vo.moveBackward().utterance)»") } catch { stampa("indietro: ERRORE \(error)") }
        do { stampa("dentro: «\(try vo.moveIn().utterance)»") } catch { stampa("dentro: ERRORE \(error)") }
        do { stampa("fuori: «\(try vo.moveOut().utterance)»") } catch { stampa("fuori: ERRORE \(error)") }
        stampa("descrizione del servizio: \(vo.debugDescription)")
        let istantanea = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        istantanea.name = "sonda-voiceover-acceso"; istantanea.lifetime = .keepAlways; add(istantanea)
        try vo.disable()
        stampa("spegnimento: isEnabled=\(vo.isEnabled)")
        XCTAssertFalse(pronunce.isEmpty, "il servizio ha restituito almeno una pronuncia")
    }

    /// Con VoiceOver acceso, l'attivazione dell'elemento a fuoco: il servizio non
    /// ha un comando di attivazione, quindi si prova il doppio tocco sintetico,
    /// che con VoiceOver acceso dovrebbe attivare l'elemento a fuoco.
    @MainActor
    func test_sonda_2_attivazione_col_doppio_tocco() throws {
        guard #available(iOS 27.0, *) else { throw XCTSkip("servizio VoiceOver solo da iOS 27") }
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons.firstMatch.waitForExistence(timeout: 15))
        let vo = XCUIDevice.shared.voiceOverService
        try vo.enable()
        defer { try? vo.disable() }
        var trovato = false
        for _ in 1...20 {
            guard let u = try? vo.moveForward().utterance else { continue }
            if u.contains("mappa piccola") { trovato = true; stampa("fuoco su: «\(u)»"); break }
        }
        guard trovato else { stampa("pulsante della mappa piccola non raggiunto"); XCTFail("non raggiunto"); return }
        app.doubleTap()
        let casella = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "riga 1, casella 1")).firstMatch
        let aperta = casella.waitForExistence(timeout: 10)
        stampa("doppio tocco con VoiceOver acceso: mappa aperta=\(aperta)")
        do { stampa("pronuncia dopo l'attivazione: «\(try vo.currentSpeech().utterance)»") }
        catch { stampa("pronuncia dopo l'attivazione: ERRORE \(error)") }
        let istantanea = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        istantanea.name = "sonda-attivazione"; istantanea.lifetime = .keepAlways; add(istantanea)
    }

    /// Le verifiche di accessibilità automatiche di Xcode, sulla schermata
    /// d'avvio: si raccolgono i rilievi invece di fallire, perché la sonda accerta
    /// il canale, non giudica la schermata.
    @MainActor
    func test_sonda_3_verifica_automatica_di_accessibilita() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons.firstMatch.waitForExistence(timeout: 15))
        var rilievi = 0
        try app.performAccessibilityAudit(for: .all) { rilievo in
            rilievi += 1
            self.stampa("verifica: tipo=\(rilievo.auditType.rawValue) «\(rilievo.compactDescription)» elemento=\(rilievo.element?.label ?? "-")")
            return true
        }
        stampa("verifica automatica conclusa: \(rilievi) rilievi sulla schermata d'avvio")
    }
}
