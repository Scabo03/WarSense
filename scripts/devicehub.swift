// Device Hub come canale (incarico 28, seconda parte): legge la finestra di Device Hub con l'accesso
// d'assistenza di macOS (Device Hub vi espone anche l'albero d'accessibilità dell'apparecchio) e la guida.
// Due vie d'ingresso: eventi inviati al SOLO processo di Device Hub (clic, trascina, tasto: NON hanno
// effetto sull'apparecchio, accertato) ed eventi globali (clicg, trascinag, tastog), che il sistema
// consegna alla finestra sotto il punto. Per gli eventi globali: Device Hub in primo piano, la sua
// finestra sopra tutte nel punto, la finestra che mostra un apparecchio di WarSense; altrimenti rifiuta.
// Il puntatore torna dov'era. Prima di usarlo: nessuna prova d'interfaccia di macOS di altri progetti in
// corso (pgrep), perché gli eventi globali vanno all'applicazione in primo piano.
// Compilazione: swiftc -O scripts/devicehub.swift -o <cartella di lavoro>/devicehub
// Uso: DH_PID=$(pgrep -x DeviceHub) <eseguibile> albero|righe|scegli <testo>|premi <descr>|valore <descr>|
//      clicg x y [volte] [alt]|trascinag x1 y1 x2 y2 [passi]|tastog codice [ctrl+alt+cmd+shift]|davanti
import AppKit
import ApplicationServices
import Foundation

let a = CommandLine.arguments
// NSWorkspace dà -1 per Device Hub: il processo si passa da fuori (pgrep -x DeviceHub).
guard let pid = pid_t(ProcessInfo.processInfo.environment["DH_PID"] ?? "") else { print("manca DH_PID"); exit(1) }
let app = AXUIElementCreateApplication(pid)

func attr(_ e: AXUIElement, _ n: String) -> AnyObject? { var v: CFTypeRef?; AXUIElementCopyAttributeValue(e, n as CFString, &v); return v }
func s(_ e: AXUIElement, _ n: String) -> String { (attr(e, n) as? String) ?? "" }
func figli(_ e: AXUIElement) -> [AXUIElement] { (attr(e, kAXChildrenAttribute) as? [AXUIElement]) ?? [] }
func cornice(_ e: AXUIElement) -> CGRect {
    var p = CGPoint.zero, z = CGSize.zero
    if let v = attr(e, kAXPositionAttribute) { AXValueGetValue(v as! AXValue, .cgPoint, &p) }
    if let v = attr(e, kAXSizeAttribute) { AXValueGetValue(v as! AXValue, .cgSize, &z) }
    return CGRect(origin: p, size: z)
}
func finestre() -> [AXUIElement] { (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? [] }
func scendi(_ e: AXUIElement, _ p: Int = 0, _ f: (AXUIElement, Int) -> Void) { f(e, p); for c in figli(e) { scendi(c, p + 1, f) } }
func testi(_ e: AXUIElement) -> [String] {
    var t: [String] = []
    scendi(e) { x, _ in for n in [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute] { let v = s(x, n); if !v.isEmpty { t.append(v) } } }
    return t
}
func trova(_ cond: (AXUIElement) -> Bool) -> AXUIElement? {
    var r: AXUIElement?
    for w in finestre() { scendi(w) { x, _ in if r == nil && cond(x) { r = x } } }
    return r
}
func numeroFinestra() -> Int {
    let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
    return info.first { ($0[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == pid && ($0[kCGWindowLayer as String] as? NSNumber)?.intValue == 0 }?[kCGWindowNumber as String] as? Int ?? 0
}
func modificatori(_ t: String) -> CGEventFlags {
    var f: CGEventFlags = []
    if t.contains("ctrl") { f.insert(.maskControl) }
    if t.contains("alt") { f.insert(.maskAlternate) }
    if t.contains("cmd") { f.insert(.maskCommand) }
    if t.contains("shift") { f.insert(.maskShift) }
    return f
}
let sorgente = CGEventSource(stateID: .hidSystemState)
func mouse(_ tipo: CGEventType, _ p: CGPoint, _ clic: Int, _ f: CGEventFlags) {
    guard let e = CGEvent(mouseEventSource: sorgente, mouseType: tipo, mouseCursorPosition: p, mouseButton: .left) else { return }
    e.setIntegerValueField(.mouseEventClickState, value: Int64(clic))
    let w = Int64(numeroFinestra())
    e.setIntegerValueField(.mouseEventWindowUnderMousePointer, value: w)
    e.setIntegerValueField(.mouseEventWindowUnderMousePointerThatCanHandleThisEvent, value: w)
    e.flags = f
    e.postToPid(pid)
}

/// Eventi globali (HID): il sistema li consegna alla finestra sotto il punto, cioè a Device Hub in primo
/// piano; il puntatore torna dov'era alla fine. Prima di ogni invio si controlla che la finestra più in
/// alto sotto il punto sia quella di Device Hub, e che Device Hub sia in primo piano.
func controllaPunto(_ p: CGPoint) {
    let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
    let sopra = info.first { w in
        guard (w[kCGWindowLayer as String] as? NSNumber)?.intValue == 0, let b = w[kCGWindowBounds as String] as? NSDictionary,
              let r = CGRect(dictionaryRepresentation: b) else { return false }
        return r.contains(p)
    }
    let ok = (sopra?[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == pid
        && NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.dt.Devices"
    if !ok { print("RIFIUTO: sotto il punto c'è", sopra?[kCGWindowOwnerName as String] ?? "nulla", "o Device Hub non è in primo piano"); exit(2) }
    // Solo le finestre degli apparecchi di WarSense (CLAUDE.md, convivenza): il titolo della finestra
    // di Device Hub nomina l'apparecchio mostrato.
    let titolo = finestre().map { s($0, kAXTitleAttribute) }.first ?? ""
    if !titolo.hasPrefix("WarSense") { print("RIFIUTO: la finestra di Device Hub mostra «\(titolo)», non un apparecchio di WarSense"); exit(2) }
}
func mouseG(_ tipo: CGEventType, _ p: CGPoint, _ clic: Int, _ f: CGEventFlags) {
    guard let e = CGEvent(mouseEventSource: sorgente, mouseType: tipo, mouseCursorPosition: p, mouseButton: .left) else { return }
    e.setIntegerValueField(.mouseEventClickState, value: Int64(clic))
    e.flags = f
    e.post(tap: .cghidEventTap)
}
let puntatore = CGEvent(source: nil)?.location ?? .zero
func rimettiPuntatore() { CGWarpMouseCursorPosition(puntatore); CGAssociateMouseAndMouseCursorPosition(1) }

switch a.count > 1 ? a[1] : "" {
case "clicg":
    let p = CGPoint(x: Double(a[2])!, y: Double(a[3])!)
    controllaPunto(p)
    let volte = a.count > 4 ? Int(a[4])! : 1
    let f = modificatori(a.count > 5 ? a[5] : "")
    if !f.isEmpty { let k = CGEvent(keyboardEventSource: sorgente, virtualKey: 58, keyDown: true)!; k.flags = f; k.post(tap: .cghidEventTap); usleep(80_000) }
    mouseG(.mouseMoved, p, 0, f); usleep(60_000)
    for i in 1...volte {
        mouseG(.leftMouseDown, p, i, f); usleep(50_000)
        mouseG(.leftMouseUp, p, i, f); usleep(90_000)
    }
    if !f.isEmpty { let k = CGEvent(keyboardEventSource: sorgente, virtualKey: 58, keyDown: false)!; k.flags = []; k.post(tap: .cghidEventTap) }
    usleep(100_000); rimettiPuntatore()
    print("clic globale", volte, "a", p, f.isEmpty ? "" : "con modificatori")
case "trascinag":
    let p1 = CGPoint(x: Double(a[2])!, y: Double(a[3])!), p2 = CGPoint(x: Double(a[4])!, y: Double(a[5])!)
    controllaPunto(p1); controllaPunto(p2)
    let passi = a.count > 6 ? Int(a[6])! : 12
    let f = modificatori(a.count > 7 ? a[7] : "")
    mouseG(.mouseMoved, p1, 0, f); usleep(60_000)
    mouseG(.leftMouseDown, p1, 1, f)
    for i in 1...passi {
        let t = Double(i) / Double(passi)
        mouseG(.leftMouseDragged, CGPoint(x: p1.x + (p2.x - p1.x) * t, y: p1.y + (p2.y - p1.y) * t), 1, f); usleep(16_000)
    }
    mouseG(.leftMouseUp, p2, 1, f)
    usleep(100_000); rimettiPuntatore()
    print("trascinato (globale)")
case "tastog":
    guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.dt.Devices" else { print("RIFIUTO: Device Hub non è in primo piano"); exit(2) }
    let f = modificatori(a.count > 3 ? a[3] : "")
    for giu in [true, false] {
        let e = CGEvent(keyboardEventSource: sorgente, virtualKey: CGKeyCode(Int(a[2])!), keyDown: giu)!
        e.flags = f
        e.post(tap: .cghidEventTap)
        usleep(60_000)
    }
    print("tasto globale", a[2], a.count > 3 ? a[3] : "")
case "albero":
    var righe = 0
    for w in finestre() {
        scendi(w) { x, p in
            guard righe < 400 else { return }
            let r = cornice(x)
            let t = [s(x, kAXTitleAttribute), s(x, kAXDescriptionAttribute), String(s(x, kAXValueAttribute).prefix(50))].filter { !$0.isEmpty }.joined(separator: " / ")
            print(String(repeating: " ", count: p) + s(x, kAXRoleAttribute), s(x, kAXSubroleAttribute), "|", t, "|", Int(r.minX), Int(r.minY), Int(r.width), Int(r.height))
            righe += 1
        }
    }
case "righe":
    guard let o = trova({ s($0, kAXRoleAttribute) == "AXOutline" }) else { print("nessuna barra laterale"); exit(1) }
    for (i, r) in ((attr(o, kAXRowsAttribute) as? [AXUIElement]) ?? []).enumerated() {
        print(i, (attr(r, kAXSelectedAttribute) as? Bool) == true ? "[scelta]" : "", testi(r).joined(separator: " | "))
    }
case "scegli":
    guard let o = trova({ s($0, kAXRoleAttribute) == "AXOutline" }),
          let r = ((attr(o, kAXRowsAttribute) as? [AXUIElement]) ?? []).first(where: { testi($0).contains(a[2]) }) else { print("riga non trovata"); exit(1) }
    let e = AXUIElementSetAttributeValue(o, kAXSelectedRowsAttribute as CFString, [r] as CFArray)
    print("scelta:", e.rawValue)
case "premi":
    guard let x = trova({ s($0, kAXDescriptionAttribute) == a[2] || s($0, kAXTitleAttribute) == a[2] }) else { print("non trovato"); exit(1) }
    print("premi:", AXUIElementPerformAction(x, kAXPressAction as CFString).rawValue, "valore:", attr(x, kAXValueAttribute) ?? "nil" as AnyObject)
case "valore":
    guard let x = trova({ s($0, kAXDescriptionAttribute) == a[2] || s($0, kAXTitleAttribute) == a[2] }) else { print("non trovato"); exit(1) }
    print(attr(x, kAXValueAttribute) ?? "nil" as AnyObject)
case "clic":
    // clic x y [volte] [modificatori]: posizione globale in punti dello schermo del Mac.
    let p = CGPoint(x: Double(a[2])!, y: Double(a[3])!)
    let volte = a.count > 4 ? Int(a[4])! : 1
    let f = modificatori(a.count > 5 ? a[5] : "")
    for i in 1...volte {
        mouse(.leftMouseDown, p, i, f); usleep(50_000)
        mouse(.leftMouseUp, p, i, f); usleep(90_000)
    }
    print("clic", volte, "a", p, "finestra", numeroFinestra())
case "trascina":
    // trascina x1 y1 x2 y2 [passi] [modificatori]
    let p1 = CGPoint(x: Double(a[2])!, y: Double(a[3])!), p2 = CGPoint(x: Double(a[4])!, y: Double(a[5])!)
    let passi = a.count > 6 ? Int(a[6])! : 12
    let f = modificatori(a.count > 7 ? a[7] : "")
    mouse(.leftMouseDown, p1, 1, f)
    for i in 1...passi {
        let t = Double(i) / Double(passi)
        mouse(.leftMouseDragged, CGPoint(x: p1.x + (p2.x - p1.x) * t, y: p1.y + (p2.y - p1.y) * t), 1, f); usleep(16_000)
    }
    mouse(.leftMouseUp, p2, 1, f)
    print("trascinato")
case "tasto":
    // tasto codice [modificatori]
    let f = modificatori(a.count > 3 ? a[3] : "")
    for giu in [true, false] {
        let e = CGEvent(keyboardEventSource: sorgente, virtualKey: CGKeyCode(Int(a[2])!), keyDown: giu)!
        e.flags = f
        e.postToPid(pid)
        usleep(60_000)
    }
    print("tasto", a[2], a.count > 3 ? a[3] : "")
case "davanti":
    print("in primo piano:", NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "?", "finestra DH:", numeroFinestra())
default:
    print("uso: dh albero|righe|scegli <testo>|premi <descr>|valore <descr>|clic x y [n] [mod]|trascina x1 y1 x2 y2 [passi] [mod]|tasto codice [mod]|davanti")
}
