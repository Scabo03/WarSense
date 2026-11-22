import XCTest

/// Il PILOTA della sessione da tester (incarico 28, seconda parte). Non è una prova che giudica: è un
/// canale a passi brevi. Resta acceso sul simulatore e legge i comandi, uno per riga JSON, dal file
/// `comandi.jsonl` di una cartella del Mac (`TEST_RUNNER_INTERATTIVO_CARTELLA`); per ciascuno esegue
/// l'azione con i servizi di XCUITest — il servizio VoiceOver per leggere ciò che si pronuncia, i
/// tocchi e i gesti sintetici, la tastiera — e scrive l'esito in `esiti.jsonl`: che cosa VoiceOver ha
/// pronunciato prima e dopo, le pronunce distinte nei secondi successivi (dove compaiono anche gli
/// annunci, quando coincidono con ciò che VoiceOver dice), l'albero essenziale e, a richiesta, una
/// schermata. Chi guida legge l'esito e decide il passo seguente. Vive nel bersaglio
/// dell'esplorazione: il collaudo non lo esegue, e l'app non ne sa nulla.
@available(iOS 27.0, *)
@MainActor
final class SessioneInterattivaTest: XCTestCase {

    private var app = XCUIApplication()
    private var vo: XCUIVoiceOverService { XCUIDevice.shared.voiceOverService }
    private var cartella: URL!
    private var prossimo = 0

    override func setUp() async throws {
        continueAfterFailure = true
        let ambiente = ProcessInfo.processInfo.environment
        let percorso = ambiente["INTERATTIVO_CARTELLA"] ?? "/tmp/warsense-interattivo"
        cartella = URL(fileURLWithPath: percorso)
    }

    /// All'uscita VoiceOver si spegne SEMPRE (incarico 30). Lasciato acceso resta acceso anche a
    /// pilota uscito, e sul medesimo simulatore le prove d'interfaccia falliscono poi tutte: col
    /// lettore acceso il tocco semplice mette a fuoco e non attiva. Visto con `FumoRegnoTest`.
    override func tearDown() async throws {
        if vo.isEnabled { try? vo.disable() }
    }

    // MARK: - Il canale dei file

    private var fileComandi: URL { cartella.appendingPathComponent("comandi.jsonl") }
    private var fileEsiti: URL { cartella.appendingPathComponent("esiti.jsonl") }

    private func leggiComandi() -> [[String: Any]] {
        guard let testo = try? String(contentsOf: fileComandi, encoding: .utf8) else { return [] }
        return testo.split(separator: "\n").compactMap {
            (try? JSONSerialization.jsonObject(with: Data($0.utf8))) as? [String: Any]
        }
    }

    private func scrivi(_ esito: [String: Any]) {
        guard let dati = try? JSONSerialization.data(withJSONObject: esito, options: [.sortedKeys]) else { return }
        let riga = dati + Data("\n".utf8)
        if let maniglia = try? FileHandle(forWritingTo: fileEsiti) {
            maniglia.seekToEndOfFile(); maniglia.write(riga); try? maniglia.close()
        } else {
            try? riga.write(to: fileEsiti)
        }
    }

    // MARK: - VoiceOver

    private func parla() -> String {
        do { return try vo.currentSpeech().utterance } catch { return "<nessuna pronuncia: \(error.localizedDescription)>" }
    }

    /// Le pronunce distinte nei `secondi` successivi, a passi di un quarto di secondo: un annuncio che
    /// VoiceOver dice dopo un'azione vi compare quando è ciò che VoiceOver sta dicendo.
    private func ascolta(_ secondi: Double) -> [String] {
        var viste: [String] = []
        let fine = Date().addingTimeInterval(secondi)
        while Date() < fine {
            let u = parla()
            if viste.last != u { viste.append(u) }
            Thread.sleep(forTimeInterval: 0.25)
        }
        return viste
    }

    // MARK: - Gli elementi

    /// L'elemento indicato per etichetta esatta, prefisso o contenuto, del tipo indicato o di qualunque.
    private func elemento(_ c: [String: Any]) -> XCUIElement? {
        let query: XCUIElementQuery
        switch c["tipo"] as? String {
        case "pulsante": query = app.buttons
        case "testo": query = app.staticTexts
        case "cella": query = app.cells
        default: query = app.descendants(matching: .any)
        }
        let predicato: NSPredicate
        if let e = c["etichetta"] as? String { predicato = NSPredicate(format: "label == %@", e) }
        else if let p = c["prefisso"] as? String { predicato = NSPredicate(format: "label BEGINSWITH %@", p) }
        else if let p = c["contiene"] as? String { predicato = NSPredicate(format: "label CONTAINS %@", p) }
        else { return nil }
        let indice = c["indice"] as? Int ?? 0
        let trovati = query.matching(predicato)
        guard trovati.count > indice else { return nil }
        return trovati.element(boundBy: indice)
    }

    /// L'albero essenziale: gli elementi con etichetta, nell'ordine dell'albero (che NON è l'ordine di
    /// lettura dichiarato), con cornice e raggiungibilità al tocco.
    private func albero(massimo: Int = 400) -> [String] {
        guard let radice = try? app.snapshot() else { return ["<istantanea non disponibile>"] }
        var righe: [String] = []
        func scendi(_ n: XCUIElementSnapshot) {
            guard righe.count < massimo else { return }
            if !n.label.isEmpty {
                let f = n.frame
                righe.append("\(n.label) [\(Int(f.minX)),\(Int(f.minY)) \(Int(f.width))x\(Int(f.height))]\(n.value.map { " =\($0)" } ?? "")")
            }
            for figlio in n.children { scendi(figlio) }
        }
        scendi(radice)
        return righe
    }

    private func schermata(_ nome: String) -> String {
        let url = cartella.appendingPathComponent("schermate").appendingPathComponent(nome + ".png")
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: url)
        return url.lastPathComponent
    }

    private func modificatori(_ nomi: [String]) -> XCUIElement.KeyModifierFlags {
        var f: XCUIElement.KeyModifierFlags = []
        for n in nomi {
            switch n {
            case "control": f.insert(.control)
            case "option": f.insert(.option)
            case "command": f.insert(.command)
            case "shift": f.insert(.shift)
            case "capslock": f.insert(.capsLock)
            case "function": f.insert(.function)
            default: break
            }
        }
        return f
    }

    private func tasto(_ nome: String) -> String {
        switch nome {
        case "destra": return XCUIKeyboardKey.rightArrow.rawValue
        case "sinistra": return XCUIKeyboardKey.leftArrow.rawValue
        case "su": return XCUIKeyboardKey.upArrow.rawValue
        case "giu": return XCUIKeyboardKey.downArrow.rawValue
        case "spazio": return XCUIKeyboardKey.space.rawValue
        case "esc": return XCUIKeyboardKey.escape.rawValue
        case "invio": return XCUIKeyboardKey.return.rawValue
        case "tab": return XCUIKeyboardKey.tab.rawValue
        default: return nome
        }
    }

    // MARK: - L'esecuzione di un comando

    private func esegui(_ c: [String: Any]) -> [String: Any] {
        var esito: [String: Any] = ["n": c["n"] ?? -1, "azione": c["azione"] ?? ""]
        let azione = c["azione"] as? String ?? ""
        let ascolto = c["ascolto"] as? Double ?? 2.0
        if vo.isEnabled { esito["prima"] = parla() }
        let inizio = Date()
        switch azione {
        case "avvia":
            app = XCUIApplication()
            if let argomenti = c["argomenti"] as? [String] { app.launchArguments = argomenti }
            app.launch()
            esito["stato_app"] = app.state.rawValue
        case "riattiva":
            app.activate(); esito["stato_app"] = app.state.rawValue
        case "termina":
            app.terminate(); esito["stato_app"] = app.state.rawValue
        case "vo_accendi":
            do { try vo.enable() } catch { esito["errore"] = "\(error)" }
            for _ in 0..<20 where (try? vo.currentSpeech()) == nil { Thread.sleep(forTimeInterval: 0.5) }
        case "vo_spegni":
            do { try vo.disable() } catch { esito["errore"] = "\(error)" }
        case "avanti", "indietro":
            var pronunce: [String] = []
            for _ in 0..<(c["volte"] as? Int ?? 1) {
                do { pronunce.append(try (azione == "avanti" ? vo.moveForward() : vo.moveBackward()).utterance) }
                catch { pronunce.append("<errore: \(error.localizedDescription)>"); break }
            }
            esito["pronunce"] = pronunce
        case "giro":
            // Dall'inizio della schermata alla fine: indietro finché la pronuncia si ripete, poi avanti.
            var ultima = parla(), salite = 0
            while salite < 300 {
                let t = Date()
                guard let u = try? vo.moveBackward().utterance else { break }
                if u == ultima && Date().timeIntervalSince(t) > 1.5 { break }
                ultima = u; salite += 1
            }
            var pronunce = [parla()]
            while pronunce.count < 300 {
                let t = Date()
                guard let u = try? vo.moveForward().utterance else { break }
                if u == pronunce.last && Date().timeIntervalSince(t) > 1.5 { break }
                pronunce.append(u)
            }
            esito["pronunce"] = pronunce
        case "tocca", "doppio_tocco", "attiva", "multi_tocco", "rotazione", "scorri", "pressione":
            // Senza bersaglio, la finestra dell'app: sull'iPad l'intera applicazione non ha coordinate
            // calcolabili per i gesti («unable to compute coordinates»), la finestra sì.
            guard let e = (c["etichetta"] ?? c["prefisso"] ?? c["contiene"]) != nil ? elemento(c) : app.windows.firstMatch,
                  e.exists else { esito["errore"] = "elemento non trovato"; break }
            esito["elemento"] = e.label
            switch azione {
            case "tocca": e.tap()
            case "doppio_tocco": e.doubleTap()
            case "attiva": e.tap(); Thread.sleep(forTimeInterval: 0.6); esito["fuoco"] = parla(); e.doubleTap()
            case "multi_tocco":
                e.tap(withNumberOfTaps: c["tocchi"] as? Int ?? 2, numberOfTouches: c["dita"] as? Int ?? 2)
            case "rotazione":
                e.rotate(CGFloat(c["angolo"] as? Double ?? 1.0), withVelocity: CGFloat(c["velocita"] as? Double ?? 2.0))
            case "scorri":
                switch c["verso"] as? String {
                case "su": e.swipeUp()
                case "giu": e.swipeDown()
                case "sinistra": e.swipeLeft()
                default: e.swipeRight()
                }
            case "pressione": e.press(forDuration: c["secondi"] as? Double ?? 1.0)
            default: break
            }
        case "tocca_punto", "doppio_tocco_punto":
            let punto = app.coordinate(withNormalizedOffset: CGVector(dx: c["x"] as? Double ?? 0.5, dy: c["y"] as? Double ?? 0.5))
            if azione == "tocca_punto" { punto.tap() } else { punto.doubleTap() }
        case "tasto":
            app.typeKey(tasto(c["tasto"] as? String ?? ""), modifierFlags: modificatori(c["modificatori"] as? [String] ?? []))
        case "orientamento":
            switch c["verso"] as? String {
            case "orizzontale": XCUIDevice.shared.orientation = .landscapeLeft
            case "orizzontale_destra": XCUIDevice.shared.orientation = .landscapeRight
            default: XCUIDevice.shared.orientation = .portrait
            }
        case "pulsante_fisico":
            XCUIDevice.shared.press(c["pulsante"] as? String == "home" ? .home : .home)
        case "attendi":
            Thread.sleep(forTimeInterval: c["secondi"] as? Double ?? 1.0)
        case "parla", "albero", "schermata":
            break
        default:
            esito["errore"] = "azione sconosciuta"
        }
        esito["durata_azione_s"] = (Date().timeIntervalSince(inizio) * 100).rounded() / 100
        if vo.isEnabled {
            esito["ascoltate"] = ascolta(ascolto)
            esito["dopo"] = parla()
        }
        if azione == "albero" || c["con_albero"] as? Bool == true { esito["albero"] = albero() }
        if azione == "schermata" || c["con_schermata"] as? Bool == true {
            esito["schermata"] = schermata(c["nome"] as? String ?? "passo-\(c["n"] ?? 0)")
        }
        esito["vo_acceso"] = vo.isEnabled
        return esito
    }

    // MARK: - Il ciclo

    /// Esegue i comandi man mano che arrivano, finché arriva «fine» o per `INTERATTIVO_INERZIA`
    /// secondi (predefinito venti minuti) non arriva nulla.
    func test_sessione_da_tester() throws {
        try? FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        scrivi(["n": 0, "azione": "pronto", "cartella": cartella.path])
        let inerzia = Double(ProcessInfo.processInfo.environment["INTERATTIVO_INERZIA"] ?? "") ?? 1200
        var ultimoArrivo = Date()
        while Date().timeIntervalSince(ultimoArrivo) < inerzia {
            let comandi = leggiComandi()
            if prossimo < comandi.count {
                let c = comandi[prossimo]
                prossimo += 1
                ultimoArrivo = Date()
                if c["azione"] as? String == "fine" { scrivi(["n": c["n"] ?? -1, "azione": "fine"]); return }
                scrivi(esegui(c))
            } else {
                Thread.sleep(forTimeInterval: 0.2)
            }
        }
        scrivi(["n": -1, "azione": "inerzia", "secondi": inerzia])
    }
}
