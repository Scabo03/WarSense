import Foundation
#if canImport(UIKit)
import UIKit

/// LABORATORIO (incarico 32), soltanto nella copia di prova: registra su file ciò che accade agli
/// annunci e al fuoco, e prova le vie candidate. Non entra nel gioco.
@MainActor public enum Lab {
    public static let via: String = {
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-via"), i + 1 < a.count { return a[i + 1] }
        return "S0"
    }()
    private static let inizio = Date()
    private static var maniglia: FileHandle? = {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("lab.log")
        if !FileManager.default.fileExists(atPath: url.path) { FileManager.default.createFile(atPath: url.path, contents: nil) }
        let h = try? FileHandle(forWritingTo: url); h?.seekToEndOfFile(); return h
    }()
    public static func scrivi(_ s: String) {
        let t = String(format: "%.2f", Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 100000))
        maniglia?.write(Data("\(t) \(s)\n".utf8))
    }
    private static func nome(_ o: Any?) -> String {
        guard let o = o as? NSObject else { return "nulla" }
        let e = o.accessibilityLabel ?? (o as? UILabel)?.text ?? (o as? UIButton)?.currentTitle ?? String(describing: type(of: o))
        return String(e.prefix(48))
    }
    private static var installato = false
    static func installa() {
        guard !installato else { return }
        installato = true
        scrivi("== avvio, via \(via), VoiceOver \(UIAccessibility.isVoiceOverRunning)")
        NotificationCenter.default.addObserver(forName: UIAccessibility.elementFocusedNotification, object: nil, queue: nil) { n in
            let nuovo = n.userInfo?[UIAccessibility.focusedElementUserInfoKey]
            let vecchio = n.userInfo?[UIAccessibility.unfocusedElementUserInfoKey]
            let a = nuovo as AnyObject?, b = vecchio as AnyObject?
            nonisolated(unsafe) let aa = a; nonisolated(unsafe) let bb = b
            MainActor.assumeIsolated {
                scrivi("FUOCO su «\(nome(aa))» (da «\(nome(bb))»)")
                if aa != nil { arrivato() }
            }
        }
        NotificationCenter.default.addObserver(forName: UIAccessibility.announcementDidFinishNotification, object: nil, queue: nil) { n in
            let v = n.userInfo?[UIAccessibility.announcementStringValueUserInfoKey]
            let testo = (v as? String) ?? (v as? NSAttributedString)?.string ?? "?"
            let ok = (n.userInfo?[UIAccessibility.announcementWasSuccessfulUserInfoKey] as? NSNumber)?.boolValue
            MainActor.assumeIsolated { scrivi("CONCLUSO riuscito=\(ok.map { "\($0)" } ?? "?") «\(testo.prefix(48))»") }
        }
    }
    private static var chiesto: Date?
    private static var attesa: [NSAttributedString] = []
    private static var generazione = 0

    public static func fuocoChiesto(_ el: Any?) {
        scrivi("FUOCO CHIESTO a «\(nome(el))»")
        chiesto = Date()
        generazione += 1
        let g = generazione
        // Scadenza: se il fuoco non arriva, si pubblica comunque.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { if g == generazione, chiesto != nil { scrivi("SCADENZA del fuoco"); chiesto = nil; rilascia() } }
    }
    /// S8: il testo come argomento della notifica di cambio schermata; S9: lo porta l'elemento. In
    /// entrambe la notifica si ritarda di un decimo, per raccogliere l'annuncio della stessa azione.
    private static var raccolti: [NSAttributedString] = []
    public static func notificaCambio(_ el: Any?) {
        fuocoChiesto(el)
        guard via == "S8" || via == "S9" else { UIAccessibility.post(notification: .screenChanged, argument: el); return }
        nonisolated(unsafe) let e = el
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let testi = raccolti; raccolti = []; chiesto = nil
            guard !testi.isEmpty else { UIAccessibility.post(notification: .screenChanged, argument: e); return }
            if via == "S8" {
                let m = NSMutableAttributedString()
                for x in testi { m.append(x); m.append(NSAttributedString(string: " ")) }
                scrivi("S8 cambio di schermata col testo (\(m.length))")
                UIAccessibility.post(notification: .screenChanged, argument: m)
            } else {
                let o = e as? NSObject
                let prima = o?.accessibilityLabel ?? (o as? UILabel)?.text ?? ""
                let vecchia = o?.accessibilityLabel
                o?.accessibilityLabel = testi.map(\.string).joined(separator: " ") + " " + prima
                scrivi("S9 l'elemento porta il testo (\((o?.accessibilityLabel ?? "").count))")
                UIAccessibility.post(notification: .screenChanged, argument: e)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { o?.accessibilityLabel = (o is UILabel) ? nil : vecchia }
            }
        }
    }
    private static func arrivato() {
        guard chiesto != nil else { return }
        let ritardo: Double = via == "S3b" ? 0.0 : 0.15
        generazione += 1
        let g = generazione
        DispatchQueue.main.asyncAfter(deadline: .now() + ritardo) { if g == generazione { chiesto = nil; rilascia() } }
    }
    private static func rilascia() {
        let tutti = attesa; attesa = []
        for a in tutti { manda(a) }
    }
    private static func manda(_ a: NSAttributedString) {
        let m = NSMutableAttributedString(attributedString: a)
        let tutto = NSRange(location: 0, length: m.length)
        var priorita = "default"
        switch via {
        case "S1", "S5", "S1c1", "S1c2", "S1c3", "S1c4", "S1c5", "S1c6", "S1c7", "S1c8": m.addAttribute(.accessibilitySpeechAnnouncementPriority, value: UIAccessibilityPriority.high, range: tutto); priorita = "alta"
        case "S2", "S3", "S3b": m.addAttribute(.accessibilitySpeechAnnouncementPriority, value: UIAccessibilityPriority.low, range: tutto); priorita = "bassa"
        case "S7": m.addAttribute(.accessibilitySpeechQueueAnnouncement, value: true, range: tutto); priorita = "coda"
        default: break
        }
        scrivi("PUBBLICA \(priorita) «\(m.string.prefix(48))» (\(m.length))")
        UIAccessibility.post(notification: .announcement, argument: m)
    }
    private static var primoDelFascio: Date?
    /// Senza la coda: tutti gli annunci di un fascio consegnati subito a VoiceOver.
    public static func diretto(_ a: NSAttributedString) -> Bool {
        guard via.hasPrefix("M") else { return false }
        installa()
        let primo = primoDelFascio.map { Date().timeIntervalSince($0) > 1.0 } ?? true
        if primo { primoDelFascio = Date() }
        let m = NSMutableAttributedString(attributedString: a)
        let p: UIAccessibilityPriority
        switch via {
        case "M1": p = .high
        case "M2": p = primo ? .high : .low
        case "M3": p = .low
        default: p = .default
        }
        m.addAttribute(.accessibilitySpeechAnnouncementPriority, value: p, range: NSRange(location: 0, length: m.length))
        scrivi("DIRETTO \(p.rawValue) «\(a.string.prefix(48))» (\(a.length))")
        UIAccessibility.post(notification: .announcement, argument: m)
        return true
    }
    /// Le prove del taglio: come un annuncio interrompente può fermarne uno a priorità alta.
    public static func pubblicaInterrompente(_ a: NSAttributedString) {
        installa()
        scrivi("INTERROMPENTE «\(a.string.prefix(48))» (\(a.length))")
        func attr(_ p: UIAccessibilityPriority?, coda: Bool? = nil, testo: String? = nil) -> NSAttributedString {
            let m = NSMutableAttributedString(attributedString: testo.map { NSAttributedString(string: $0) } ?? a)
            let tutto = NSRange(location: 0, length: m.length)
            if let p { m.addAttribute(.accessibilitySpeechAnnouncementPriority, value: p, range: tutto) }
            if let coda { m.addAttribute(.accessibilitySpeechQueueAnnouncement, value: coda, range: tutto) }
            return m
        }
        switch via {
        case "S1c1": UIAccessibility.post(notification: .announcement, argument: attr(nil))
        case "S1c2": UIAccessibility.post(notification: .announcement, argument: attr(.high, coda: false))
        case "S1c3":
            UIAccessibility.post(notification: .announcement, argument: attr(.high, testo: ""))
            UIAccessibility.post(notification: .announcement, argument: attr(.high))
        case "S1c4": UIAccessibility.post(notification: .screenChanged, argument: attr(.high))
        case "S1c5": UIAccessibility.post(notification: .pageScrolled, argument: attr(.high))
        case "S1c6": UIAccessibility.post(notification: .layoutChanged, argument: attr(.high))
        case "S1c7": UIAccessibility.post(notification: .announcement, argument: a.string)
        case "S1c8":
            let e = UIAccessibility.focusedElement(using: .notificationVoiceOver)
            UIAccessibility.post(notification: .layoutChanged, argument: e)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { UIAccessibility.post(notification: .announcement, argument: attr(.high)) }
        default: UIAccessibility.post(notification: .announcement, argument: attr(.high))
        }
    }
    public static func pubblica(_ a: NSAttributedString) {
        installa()
        scrivi("ANNUNCIO «\(a.string.prefix(48))» (\(a.length))")
        switch via {
        case "S3", "S3b", "S4", "S5":
            // Un breve attesa per vedere se il fuoco si sposta nella stessa azione.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if chiesto != nil { scrivi("TRATTENUTO «\(a.string.prefix(30))»"); attesa.append(a) } else { manda(a) }
            }
        case "S8", "S9":
            raccolti.append(a)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                // Nessun cambio di schermata in questa azione: annuncio ordinario.
                if let i = raccolti.firstIndex(where: { $0 === a }) { raccolti.remove(at: i); manda(a) }
            }
        case "S6":
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { manda(a) }
        default:
            manda(a)
        }
    }
}
#endif
