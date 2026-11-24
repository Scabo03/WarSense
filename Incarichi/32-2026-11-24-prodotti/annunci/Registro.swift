import Foundation
#if canImport(UIKit)
import UIKit
/// LABORATORIO (incarico 32), soltanto nella copia di prova: il REGISTRO di ciò che accade agli annunci
/// e al fuoco, senza cambiare nulla di ciò che il gioco fa. Non entra nel gioco.
@MainActor public enum Lab {
    private static var maniglia: FileHandle? = {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("lab.log")
        if !FileManager.default.fileExists(atPath: url.path) { FileManager.default.createFile(atPath: url.path, contents: nil) }
        let h = try? FileHandle(forWritingTo: url); h?.seekToEndOfFile(); return h
    }()
    public static func scrivi(_ s: String) {
        maniglia?.write(Data((String(format: "%.2f ", Date().timeIntervalSince1970) + s + "\n").utf8))
    }
    private static func nome(_ o: Any?) -> String {
        guard let o = o as? NSObject else { return "nulla" }
        return String((o.accessibilityLabel ?? (o as? UILabel)?.text ?? (o as? UIButton)?.currentTitle ?? String(describing: type(of: o))).prefix(60))
    }
    private static var installato = false
    static func installa() {
        guard !installato else { return }
        installato = true
        scrivi("AVVIO VoiceOver=\(UIAccessibility.isVoiceOverRunning)")
        NotificationCenter.default.addObserver(forName: UIAccessibility.elementFocusedNotification, object: nil, queue: nil) { n in
            let nuovo = n.userInfo?[UIAccessibility.focusedElementUserInfoKey] as AnyObject?
            nonisolated(unsafe) let a = nuovo
            MainActor.assumeIsolated { if a != nil { scrivi("FUOCO «\(nome(a))»") } }
        }
        NotificationCenter.default.addObserver(forName: UIAccessibility.announcementDidFinishNotification, object: nil, queue: nil) { n in
            let v = n.userInfo?[UIAccessibility.announcementStringValueUserInfoKey]
            let testo = (v as? String) ?? (v as? NSAttributedString)?.string ?? "?"
            let ok = (n.userInfo?[UIAccessibility.announcementWasSuccessfulUserInfoKey] as? NSNumber)?.boolValue
            MainActor.assumeIsolated { scrivi("CONCLUSO riuscito=\(ok.map { "\($0)" } ?? "?") «\(testo)»") }
        }
        for (n, s) in [(UIAccessibility.voiceOverStatusDidChangeNotification, "VOICEOVER cambia"), (UIApplication.didEnterBackgroundNotification, "SFONDO"), (UIApplication.didBecomeActiveNotification, "ATTIVA")] {
            NotificationCenter.default.addObserver(forName: n, object: nil, queue: nil) { _ in MainActor.assumeIsolated { scrivi(s) } }
        }
    }
    static func pubblicato(_ a: NSAttributedString) {
        let p = a.length > 0 ? a.attribute(.accessibilitySpeechAnnouncementPriority, at: 0, effectiveRange: nil) as? UIAccessibilityPriority : nil
        scrivi("PUBBLICA \(p == .high ? "alta" : "ordinaria") (\(a.length)) «\(a.string)»")
    }
}
#endif
