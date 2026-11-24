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
///
/// Dall'incarico 31: «elementi» dà gli elementi col loro tipo (comando o testo) e, se l'istantanea
/// li porta, coi tratti; «sonda» elenca ciò che il servizio VoiceOver e l'istantanea portano oltre
/// l'interfaccia pubblica; «quiete» accorcia l'ascolto quando la voce tace; «pausa_fuoco» fa
/// ascoltare l'elemento prima di attivarlo; ogni esito porta l'istante «t» e la durata dell'ascolto.
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

    /// La pronuncia corrente, come la restituisce il servizio: troncata a 64 caratteri. Dopo una copia
    /// negli appunti (vedi `interaDagliAppunti`) VoiceOver accoda alla pronuncia «copiato negli
    /// appunti»: finché la pronuncia è la stessa di prima della copia, con quella coda, si restituisce
    /// quella di prima.
    private func parla() -> String {
        let grezza: String
        do { grezza = try vo.currentSpeech().utterance } catch { return "<nessuna pronuncia: \(error.localizedDescription)>" }
        return ripulita(grezza)
    }
    /// La pronuncia che era corrente quando si è chiesta l'ultima copia negli appunti.
    private var baseDellaCopia: String?

    /// Toglie a una pronuncia la coda che VoiceOver le accoda dopo una copia negli appunti: se è
    /// quella di prima della copia seguita soltanto da quella coda — ripetuta, o tagliata dai 64
    /// caratteri — è quella di prima. Una pronuncia diversa è nuova, e la coda non c'è più.
    private func ripulita(_ pronuncia: String) -> String {
        guard let base = baseDellaCopia else { return pronuncia }
        if !base.isEmpty, pronuncia.hasPrefix(base) {
            var resto = pronuncia.dropFirst(base.count)
            while resto.hasPrefix(Self.codaDellaCopia) { resto = resto.dropFirst(Self.codaDellaCopia.count) }
            if Self.codaDellaCopia.hasPrefix(resto) { return base }
        }
        baseDellaCopia = nil
        return pronuncia
    }

    // MARK: - La pronuncia intera, dagli appunti (incarico 31)

    /// Ciò che VoiceOver accoda alla pronuncia quando copia: è una frase sua, non del gioco, nella
    /// lingua in cui VoiceOver parla sul simulatore.
    private static let codaDellaCopia = " copiato negli appunti"
    private var richiesteAgliAppunti = 0
    private var appuntiMuti = 0

    /// LA PRONUNCIA INTERA. Il servizio VoiceOver delle prove tronca ogni pronuncia a 64 caratteri, e
    /// oltre quel punto stanno la coda di una riga lunga, il suo tratto («Pulsante», «Intestazione»),
    /// il suo suggerimento, e la coda degli annunci lunghi. VoiceOver ha però un comando che copia
    /// negli appunti l'ultima cosa detta, per intero (da tastiera Control, Opzione, Maiuscole, C): lo
    /// si dà qui, e gli appunti del simulatore li legge il lato Mac (`scripts/interattivo.py
    /// --appunti`, con `xcrun simctl pbpaste`), a cui si chiede con un file nella cartella dei
    /// comandi. Nulla se il lato Mac non risponde: dopo due silenzi non lo si chiede più.
    private func interaDagliAppunti() -> String? {
        guard appuntiMuti < 2, vo.isEnabled else { return nil }
        let base = parla()
        app.typeKey("c", modifierFlags: [.control, .option, .shift])
        baseDellaCopia = base
        Thread.sleep(forTimeInterval: 0.15)
        let appunti = cartella.appendingPathComponent("appunti")
        try? FileManager.default.createDirectory(at: appunti, withIntermediateDirectories: true)
        richiesteAgliAppunti += 1
        let richiesta = appunti.appendingPathComponent("richiesta-\(richiesteAgliAppunti)")
        let risposta = appunti.appendingPathComponent("risposta-\(richiesteAgliAppunti).txt")
        try? Data().write(to: richiesta)
        let limite = Date().addingTimeInterval(3)
        while Date() < limite {
            if let testo = try? String(contentsOf: risposta, encoding: .utf8) {
                try? FileManager.default.removeItem(at: risposta)
                appuntiMuti = 0
                var intera = testo
                if let coda = testo.range(of: Self.codaDellaCopia) { intera = String(testo[..<coda.lowerBound]) }
                // Ciò che si è copiato è ciò che VoiceOver stava dicendo nell'istante della copia, che
                // può essere già la pronuncia successiva a quella letta un momento prima: la base
                // per riconoscere la coda è l'inizio di ciò che si è copiato davvero.
                if !intera.isEmpty { baseDellaCopia = String(intera.prefix(64)) }
                return intera
            }
            Thread.sleep(forTimeInterval: 0.03)
        }
        try? FileManager.default.removeItem(at: richiesta)
        appuntiMuti += 1
        return nil
    }

    /// Ciò che un ascolto ha sentito: le pronunce distinte, l'istante in cui ciascuna è comparsa
    /// (secondi dall'inizio dell'ascolto) e, se richieste, le pronunce intere lette dagli appunti.
    private struct Ascolto {
        var pronunce: [String] = []
        var istanti: [Double] = []
        var intere: [[String: Any]] = []
    }

    /// Le pronunce distinte nei `secondi` successivi, a passi di un quarto di secondo: un annuncio che
    /// VoiceOver dice dopo un'azione vi compare quando è ciò che VoiceOver sta dicendo.
    ///
    /// Con `quiete` (incarico 31) l'ascolto finisce prima, appena la pronuncia non cambia più da
    /// quei secondi: serve dove gli annunci arrivano in fila e non si sa quanti siano — la chiusura
    /// di una giornata che apre una stagione dice la giornata, la stagione e chi è arrivato dalla
    /// patria —, senza pagare ogni volta l'ascolto più lungo. La quiete va scelta più lunga della
    /// frase più lunga: mentre VoiceOver la sta dicendo la pronuncia non cambia.
    ///
    /// Con `intere` si chiede anche la pronuncia intera: «ogni» a ogni pronuncia nuova, appena
    /// compare; «fine» una volta sola, in coda all'ascolto, per l'ultima.
    private func ascolta(_ secondi: Double, quiete: Double? = nil, intere: String? = nil) -> Ascolto {
        var esito = Ascolto()
        let inizio = Date()
        let fine = inizio.addingTimeInterval(secondi)
        var ultimoCambio = inizio
        var copiataLUltima = false
        var ultimaIntera: String?
        func istante() -> Double { (Date().timeIntervalSince(inizio) * 100).rounded() / 100 }
        func copia() {
            let richiesta = istante()
            guard let intera = interaDagliAppunti() else { return }
            // «t_richiesta» è l'istante in cui si è dato il comando di copia, «t» quello in cui gli
            // appunti sono tornati: ciò che si è copiato era la pronuncia corrente fra i due.
            esito.intere.append(["t_richiesta": richiesta, "t": istante(), "testo": intera])
            ultimaIntera = intera
            copiataLUltima = true
            // Mentre si copia non si ascolta: se ciò che si è copiato non è la pronuncia che aveva
            // fatto chiedere la copia, è una pronuncia arrivata nel frattempo, e va in elenco.
            let inizioDellaCopiata = String(intera.prefix(64))
            if !intera.isEmpty, esito.pronunce.last != inizioDellaCopiata {
                esito.pronunce.append(inizioDellaCopiata)
                esito.istanti.append(istante())
                ultimoCambio = Date()
            }
        }
        while Date() < fine {
            let u = parla()
            if esito.pronunce.last != u {
                esito.pronunce.append(u)
                esito.istanti.append((Date().timeIntervalSince(inizio) * 100).rounded() / 100)
                ultimoCambio = Date()
                // Se la copia precedente aveva già preso questa pronuncia — arrivata mentre si
                // copiava quella di prima — non la si copia due volte.
                copiataLUltima = ultimaIntera.map { String($0.prefix(64)) == u } ?? false
                if intere == "ogni", !copiataLUltima { copia() }
            }
            if let quiete, Date().timeIntervalSince(ultimoCambio) >= quiete { break }
            Thread.sleep(forTimeInterval: 0.25)
        }
        if intere != nil, !copiataLUltima { copia() }
        return esito
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

    // MARK: - Gli elementi con il loro tipo (incarico 31)

    /// Il nome del tipo che XCUITest attribuisce a un elemento: un comando è «pulsante», una riga di
    /// testo è «testo». Serve a dire se una riga è un comando o soltanto testo, cosa che l'albero
    /// essenziale non dice.
    private func nomeDelTipo(_ tipo: XCUIElement.ElementType) -> String {
        switch tipo {
        case .button: return "pulsante"
        case .staticText: return "testo"
        case .other: return "altro"
        case .application: return "applicazione"
        case .window: return "finestra"
        case .scrollView: return "scorrimento"
        case .alert: return "avviso"
        case .cell: return "cella"
        case .image: return "immagine"
        default: return "tipo-\(tipo.rawValue)"
        }
    }

    /// I tratti d'accessibilità di un nodo dell'istantanea, se l'istantanea li porta. L'interfaccia
    /// pubblica di XCUITest non li espone (`XCUIElementAttributes` ha etichetta, valore, tipo, cornice
    /// e poco altro, senza tratti né suggerimento): si chiede all'oggetto concreto se risponde a
    /// «traits», e soltanto allora lo si legge. Nulla se non risponde.
    private func tratti(_ nodo: XCUIElementSnapshot) -> UInt64? {
        guard let oggetto = nodo as? NSObject,
              oggetto.responds(to: NSSelectorFromString("traits")),
              let numero = oggetto.value(forKey: "traits") as? NSNumber else { return nil }
        return numero.uint64Value
    }

    /// I nomi dei tratti che contano per le prove: i valori sono quelli di `UIAccessibilityTraits`.
    private func nomiDeiTratti(_ tratti: UInt64) -> [String] {
        var nomi: [String] = []
        if tratti & 0x1 != 0 { nomi.append("pulsante") }
        if tratti & 0x8 != 0 { nomi.append("selezionato") }
        if tratti & 0x40 != 0 { nomi.append("testo statico") }
        if tratti & 0x100 != 0 { nomi.append("non abilitato") }
        if tratti & 0x10000 != 0 { nomi.append("intestazione") }
        return nomi
    }

    /// Gli elementi con etichetta, nell'ordine dell'albero, ciascuno con tipo, identificatore, valore,
    /// cornice, e i tratti quando l'istantanea li porta. Con «prefisso» o «contiene» soltanto quelli
    /// la cui etichetta corrisponde.
    private func elementi(_ c: [String: Any]) -> [[String: Any]] {
        guard let radice = try? app.snapshot() else { return [] }
        let prefisso = c["prefisso"] as? String, contiene = c["contiene"] as? String
        var righe: [[String: Any]] = []
        func scendi(_ n: XCUIElementSnapshot) {
            guard righe.count < 600 else { return }
            let scelto = prefisso.map { n.label.hasPrefix($0) } ?? contiene.map { n.label.contains($0) } ?? true
            if !n.label.isEmpty, scelto {
                let f = n.frame
                var riga: [String: Any] = [
                    "etichetta": n.label, "tipo": nomeDelTipo(n.elementType), "identificatore": n.identifier,
                    "cornice": [Int(f.minX), Int(f.minY), Int(f.width), Int(f.height)],
                    "abilitato": n.isEnabled, "selezionato": n.isSelected,
                ]
                if let valore = n.value { riga["valore"] = "\(valore)" }
                if let t = tratti(n) { riga["tratti"] = t; riga["nomi_dei_tratti"] = nomiDeiTratti(t) }
                righe.append(riga)
            }
            for figlio in n.children { scendi(figlio) }
        }
        scendi(radice)
        return righe
    }

    /// Le classi, le proprietà e i metodi di un oggetto, letti dall'ambiente di esecuzione: la sonda
    /// con cui si accerta che cosa il servizio VoiceOver delle prove e l'istantanea portano oltre
    /// l'interfaccia pubblica (la pronuncia intera, i tratti, il suggerimento).
    private func anatomia(_ oggetto: AnyObject) -> [String: Any] {
        var classi: [String] = [], proprieta: [String] = [], metodi: [String] = []
        var classe: AnyClass? = type(of: oggetto)
        while let c = classe, NSStringFromClass(c) != "NSObject" {
            classi.append(NSStringFromClass(c))
            var quanti: UInt32 = 0
            if let elenco = class_copyPropertyList(c, &quanti) {
                for i in 0..<Int(quanti) { proprieta.append(String(cString: property_getName(elenco[i]))) }
                free(elenco)
            }
            quanti = 0
            if let elenco = class_copyMethodList(c, &quanti) {
                for i in 0..<Int(quanti) { metodi.append(NSStringFromSelector(method_getName(elenco[i]))) }
                free(elenco)
            }
            classe = class_getSuperclass(c)
        }
        return ["classi": classi, "proprieta": proprieta, "metodi": metodi]
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
            // Con «intere» (incarico 31) ogni pronuncia si legge anche per intero, dagli appunti.
            var pronunce: [String] = [], intere: [String] = []
            for _ in 0..<(c["volte"] as? Int ?? 1) {
                do { pronunce.append(ripulita(try (azione == "avanti" ? vo.moveForward() : vo.moveBackward()).utterance)) }
                catch { pronunce.append("<errore: \(error.localizedDescription)>"); break }
                if c["intere"] as? Bool == true { intere.append(interaDagliAppunti() ?? "") }
            }
            esito["pronunce"] = pronunce
            if c["intere"] as? Bool == true { esito["pronunce_intere"] = intere }
        case "giro":
            // Dall'inizio della schermata alla fine: indietro finché la pronuncia si ripete, poi avanti.
            // Con «intere» (incarico 31) ogni elemento si legge anche per intero, dagli appunti:
            // l'etichetta fino in fondo, il tratto, il suggerimento.
            var ultima = parla(), salite = 0
            while salite < 300 {
                let t = Date()
                guard let u = try? vo.moveBackward().utterance else { break }
                if u == ultima && Date().timeIntervalSince(t) > 1.5 { break }
                ultima = u; salite += 1
            }
            let conIntere = c["intere"] as? Bool == true
            var pronunce = [parla()], intere: [String] = []
            if conIntere { intere.append(interaDagliAppunti() ?? "") }
            while pronunce.count < 300 {
                let t = Date()
                guard let grezza = try? vo.moveForward().utterance else { break }
                let u = ripulita(grezza)
                if u == pronunce.last && Date().timeIntervalSince(t) > 1.5 { break }
                pronunce.append(u)
                if conIntere { intere.append(interaDagliAppunti() ?? "") }
            }
            esito["pronunce"] = pronunce
            if conIntere { esito["pronunce_intere"] = intere }
        case "copia":
            // L'ultima cosa che VoiceOver ha detto, per intero, dagli appunti (incarico 31).
            if let intera = interaDagliAppunti() { esito["intera"] = intera }
            else { esito["errore"] = "gli appunti non rispondono: il lato Mac li serve con scripts/interattivo.py --appunti" }
        case "tocca", "doppio_tocco", "attiva", "multi_tocco", "rotazione", "scorri", "pressione":
            // Senza bersaglio, la finestra dell'app: sull'iPad l'intera applicazione non ha coordinate
            // calcolabili per i gesti («unable to compute coordinates»), la finestra sì.
            guard let e = (c["etichetta"] ?? c["prefisso"] ?? c["contiene"]) != nil ? elemento(c) : app.windows.firstMatch,
                  e.exists else { esito["errore"] = "elemento non trovato"; break }
            esito["elemento"] = e.label
            switch azione {
            case "tocca": e.tap()
            case "doppio_tocco": e.doubleTap()
            case "attiva":
                // Il tocco porta il fuoco sull'elemento, il doppio tocco lo attiva. Con «pausa_fuoco»
                // (incarico 31) fra i due si ascolta più a lungo, e «fuoco_ascoltate» riporta ciò che
                // VoiceOver dice dell'elemento prima che lo si attivi.
                e.tap()
                if let pausa = c["pausa_fuoco"] as? Double {
                    let dette = ascolta(pausa, intere: c["fuoco_intero"] as? Bool == true ? "fine" : nil)
                    esito["fuoco_ascoltate"] = dette.pronunce
                    esito["fuoco"] = dette.pronunce.last ?? ""
                    if let intera = dette.intere.last?["testo"] { esito["fuoco_intero"] = intera }
                } else {
                    Thread.sleep(forTimeInterval: 0.6); esito["fuoco"] = parla()
                }
                // Quanto dura il doppio tocco (incarico 31): ciò che l'attivazione fa dire comincia
                // dentro questo tempo, prima che l'ascolto cominci, e chi misura quanto un annuncio
                // resta la pronuncia corrente deve contarlo.
                let primaDelDoppioTocco = Date()
                e.doubleTap()
                esito["doppio_tocco_s"] = (Date().timeIntervalSince(primaDelDoppioTocco) * 100).rounded() / 100
            case "multi_tocco":
                // Un elemento senza coordinate calcolabili — accade di rado, appena tornati da un'altra
                // schermata — farebbe cadere il pilota (incarico 32): si dichiara, e chi guida sceglie altro.
                guard e.isHittable else { esito["errore"] = "elemento non toccabile"; break }
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
        case "parla", "albero", "schermata", "elementi":
            break
        case "sonda":
            // Che cosa portano, oltre l'interfaccia pubblica, il servizio VoiceOver, la sua uscita e
            // l'istantanea di un elemento (incarico 31): si elencano classi, proprietà e metodi.
            esito["servizio"] = anatomia(vo)
            esito["servizio_descrizione"] = vo.debugDescription
            if let uscita = try? vo.currentSpeech() {
                esito["uscita"] = anatomia(uscita)
                esito["uscita_descrizione"] = (uscita as NSObject).debugDescription
            }
            if let radice = try? app.snapshot() { esito["istantanea"] = anatomia(radice as AnyObject) }
        default:
            esito["errore"] = "azione sconosciuta"
        }
        esito["durata_azione_s"] = (Date().timeIntervalSince(inizio) * 100).rounded() / 100
        if vo.isEnabled {
            let inizioAscolto = Date()
            let sentito = ascolta(ascolto, quiete: c["quiete"] as? Double, intere: c["intere"] as? String)
            esito["ascoltate"] = sentito.pronunce
            esito["ascoltate_t"] = sentito.istanti
            if !sentito.intere.isEmpty { esito["intere"] = sentito.intere }
            esito["ascolto_s"] = (Date().timeIntervalSince(inizioAscolto) * 100).rounded() / 100
            esito["dopo"] = parla()
        }
        esito["t"] = (Date().timeIntervalSince1970 * 10).rounded() / 10
        if azione == "elementi" { esito["elementi"] = elementi(c) }
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
