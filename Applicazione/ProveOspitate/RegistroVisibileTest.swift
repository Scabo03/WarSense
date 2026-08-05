import XCTest
import Dati
import Motore
@testable import WarSense

/// La prova di CLASSE del registro (00 §1.2): per ogni elemento del registro,
/// raggiungibilità da VoiceOver e presenza di testo visibile sono equivalenti nelle
/// due direzioni.
///
/// Nasce dal difetto riferito da chi ha usato il gioco: il registro non presentava
/// testo visibile pur contenendo un elemento per giornata, agganciabile e letto da
/// VoiceOver. La causa era che le voci prive di luogo erano pulsanti DISABILITATI,
/// e il colore dello stato inattivo su fondo di sistema dà un contrasto intorno a
/// 1,7 contro 1. È l'immagine speculare delle tessere accessibili di altezza zero
/// della fase B, e in entrambi i casi la divergenza fra i due piani.
///
/// La prova non guarda le proprietà degli oggetti — quelle erano tutte a posto —
/// ma i PIXEL disegnati: rende la schermata e misura, nella cornice di ciascun
/// elemento, il contrasto fra il fondo e il pixel che più se ne discosta. Una
/// prova sulle proprietà avrebbe lasciato passare esattamente questo difetto.
@MainActor
final class RegistroVisibileTest: XCTestCase {

    private static let schermoPiccolo = CGRect(x: 0, y: 0, width: 375, height: 667)

    /// La soglia sotto la quale un testo non si può dire visibile. Non è un numero
    /// di gioco e non sta nei file dei valori: è il criterio della prova.
    ///
    /// Vale tre contro uno, che è la soglia di WCAG AA per il testo grande e per i
    /// componenti d'interfaccia. Non quattro e mezzo, che è quella del testo
    /// ordinario, perché il colore di tinta di sistema — quello dei pulsanti — vale
    /// 3,22 su fondo chiaro e la prova respingerebbe la convenzione della
    /// piattaforma anziché il difetto. Il difetto misurato valeva 1,68: la soglia
    /// lo coglie con quasi il doppio di margine. La sensibilità della prova è
    /// fissata dalla prova che segue, che le mette davanti il difetto vero.
    private static let contrastoMinimo: Double = 3.0

    private func registroAperto(_ voci: [SchermataRegistro.Voce])
        throws -> (SchermataRegistro, UIWindow) {
        let ambiente = try Ambiente()
        let schermata = SchermataRegistro(voci: voci, testi: ambiente.testi)
        let finestra = UIWindow(frame: Self.schermoPiccolo)
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        finestra.layoutIfNeeded()
        return (schermata, finestra)
    }

    /// Le due voci che il registro sa produrre: una con luogo, una senza.
    private static let vociDiProva: [SchermataRegistro.Voce] = [
        .init(frase: "Giorno 2: ordine annullato", luogo: nil),
        .init(frase: "Giorno 1: Corvo marcia in riga 9, casella 6", luogo: Cella(riga: 9, colonna: 6)),
    ]

    // MARK: - Prima direzione: ciò che si aggancia si vede

    func test_00_1_2_ogni_elemento_agganciabile_del_registro_ha_testo_visibile() throws {
        let (schermata, finestra) = try registroAperto(Self.vociDiProva)
        let ordine = LettoreAccessibilita.ordineDiLettura(radice: schermata.view!)
        XCTAssertFalse(ordine.isEmpty)
        let quadro = Quadro(finestra: finestra)
        var difetti: [String] = []
        for elemento in ordine {
            let etichetta = LettoreAccessibilita.etichetta(di: elemento)
            let cornice = LettoreAccessibilita.cornice(di: elemento)
            let contrasto = quadro.contrastoMassimo(in: cornice)
            if contrasto < Self.contrastoMinimo {
                difetti.append(String(format: "«%@»: contrasto %.2f contro %.1f richiesto",
                                      etichetta, contrasto, Self.contrastoMinimo))
            }
        }
        XCTAssertTrue(difetti.isEmpty,
                      "elementi letti dalla voce e non visibili all'occhio (00 §1.2):\n"
                      + difetti.joined(separator: "\n"))
    }

    // MARK: - Seconda direzione: ciò che si vede si aggancia

    func test_00_1_2_ogni_testo_visibile_del_registro_e_agganciabile() throws {
        let (schermata, _) = try registroAperto(Self.vociDiProva)
        let ordine = Set(LettoreAccessibilita.ordineDiLettura(radice: schermata.view!)
            .map { ObjectIdentifier($0) })
        var difetti: [String] = []
        func percorri(_ vista: UIView) {
            let portaTesto = (vista as? UILabel)?.text?.isEmpty == false
                || (vista as? UIButton)?.currentTitle?.isEmpty == false
            // L'etichetta interna di un pulsante non è un elemento a sé: è il
            // pulsante a essere agganciabile, ed è quello che si cerca.
            let dentroUnPulsante = vista.superview is UIButton
            if portaTesto, !dentroUnPulsante, !ordine.contains(ObjectIdentifier(vista)) {
                difetti.append("testo visibile fuori dal percorso di lettura: "
                               + LettoreAccessibilita.etichetta(di: vista))
            }
            for sotto in vista.subviews { percorri(sotto) }
        }
        percorri(schermata.view)
        XCTAssertTrue(difetti.isEmpty, difetti.joined(separator: "\n"))
    }

    /// Il registro vuoto lo dichiara, e lo dichiara in modo visibile: il silenzio
    /// non è distinguibile da un difetto (00 §9.1).
    func test_00_9_1_il_registro_vuoto_lo_dichiara_e_si_vede() throws {
        let (schermata, finestra) = try registroAperto([])
        let ordine = LettoreAccessibilita.ordineDiLettura(radice: schermata.view!)
        let quadro = Quadro(finestra: finestra)
        for elemento in ordine {
            XCTAssertGreaterThanOrEqual(quadro.contrastoMassimo(in: LettoreAccessibilita.cornice(di: elemento)),
                                        Self.contrastoMinimo,
                                        "«\(LettoreAccessibilita.etichetta(di: elemento))» non si vede")
        }
    }

    /// IL MUTANTE della prova: la forma che il difetto aveva. Un pulsante
    /// disabilitato con la stessa frase deve risultare INVISIBILE alla misura,
    /// altrimenti la prova non coglie ciò per cui è stata scritta e passerebbe
    /// anche se il difetto tornasse. È la stessa disciplina degli invarianti della
    /// campagna: un controllo che non si è mai visto fallire non è un controllo.
    func test_00_1_2_la_misura_coglie_il_difetto_da_cui_nasce() throws {
        let contenitore = UIViewController()
        contenitore.view.backgroundColor = .systemBackground
        let pulsante = UIButton(type: .system)
        pulsante.setTitle("Giorno 2: ordine annullato", for: .normal)
        pulsante.isEnabled = false // la forma che aveva il difetto
        pulsante.frame = CGRect(x: 24, y: 100, width: 327, height: 44)
        contenitore.view.addSubview(pulsante)
        let finestra = UIWindow(frame: Self.schermoPiccolo)
        finestra.rootViewController = contenitore
        finestra.makeKeyAndVisible()
        finestra.layoutIfNeeded()

        let contrasto = Quadro(finestra: finestra).contrastoMassimo(in: pulsante.frame)
        XCTAssertLessThan(contrasto, Self.contrastoMinimo,
                          "la misura non coglie più il difetto da cui nasce: contrasto \(contrasto)")
    }

    /// La distinzione fra le due specie di voce resta quella di RDA-67: quella con
    /// un luogo si attiva, quella senza no e lo dichiara. Ciò che cambia è che la
    /// seconda non è più un pulsante disabilitato ma testo statico.
    func test_02_6_6_la_voce_senza_luogo_e_testo_statico_e_non_un_pulsante_spento() throws {
        let (schermata, _) = try registroAperto(Self.vociDiProva)
        let ordine = LettoreAccessibilita.ordineDiLettura(radice: schermata.view!)
        let senzaLuogo = try XCTUnwrap(ordine.first {
            LettoreAccessibilita.etichetta(di: $0).contains("annullato") })
        XCTAssertFalse(senzaLuogo is UIButton, "una voce senza luogo non è un pulsante")
        XCTAssertTrue(senzaLuogo.accessibilityTraits.contains(.staticText))
        XCTAssertNotNil(senzaLuogo.accessibilityHint, "dichiara perché non si attiva (00 §9.1)")

        let conLuogo = try XCTUnwrap(ordine.first {
            LettoreAccessibilita.etichetta(di: $0).contains("Corvo") })
        XCTAssertEqual((conLuogo as? UIButton)?.isEnabled, true,
                       "la voce con un luogo consente di saltarvi (02 §6.6)")
    }
}

/// Il quadro disegnato: i pixel veri della schermata, non le proprietà degli
/// oggetti. Serve a misurare che un testo si veda, cosa che nessuna proprietà dice.
@MainActor
struct Quadro {
    private let pixel: [UInt8]
    private let larghezza: Int
    private let altezza: Int
    private let scala: CGFloat

    init(finestra: UIWindow) {
        // Si rende con il disegnatore di sistema, che imposta da sé il ribaltamento
        // delle coordinate: un contesto costruito a mano disegnerebbe capovolto e
        // la prova misurerebbe pixel vuoti, dichiarando invisibile ogni testo.
        let formato = UIGraphicsImageRendererFormat()
        formato.scale = 1
        let immagine = UIGraphicsImageRenderer(bounds: finestra.bounds, format: formato).image { c in
            finestra.layer.render(in: c.cgContext)
        }
        let cg = immagine.cgImage!
        let larghezza = cg.width, altezza = cg.height
        var byte = [UInt8](repeating: 0, count: larghezza * altezza * 4)
        let contesto = CGContext(data: &byte, width: larghezza, height: altezza,
                                 bitsPerComponent: 8, bytesPerRow: larghezza * 4,
                                 space: CGColorSpaceCreateDeviceRGB(),
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        contesto.draw(cg, in: CGRect(x: 0, y: 0, width: larghezza, height: altezza))
        self.pixel = byte
        self.larghezza = larghezza
        self.altezza = altezza
        self.scala = 1
    }

    /// La luminanza relativa di WCAG.
    private static func luminanza(_ r: UInt8, _ g: UInt8, _ b: UInt8) -> Double {
        func canale(_ v: UInt8) -> Double {
            let x = Double(v) / 255
            return x <= 0.03928 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * canale(r) + 0.7152 * canale(g) + 0.0722 * canale(b)
    }

    private static func contrasto(_ a: Double, _ b: Double) -> Double {
        let chiaro = max(a, b), scuro = min(a, b)
        return (chiaro + 0.05) / (scuro + 0.05)
    }

    /// Il contrasto fra il colore di fondo della cornice — quello più frequente —
    /// e il pixel che più se ne discosta. Un elemento che porti testo visibile lo
    /// supera largamente; un elemento muto, o scritto in un colore che sul fondo
    /// non si stacca, resta a uno.
    func contrastoMassimo(in cornice: CGRect) -> Double {
        let x0 = max(0, Int(cornice.minX * scala)), x1 = min(larghezza, Int(cornice.maxX * scala))
        let y0 = max(0, Int(cornice.minY * scala)), y1 = min(altezza, Int(cornice.maxY * scala))
        guard x1 > x0, y1 > y0 else { return 1 }
        var conteggi: [Double: Int] = [:]
        var luminanze: [Double] = []
        for y in y0..<y1 {
            for x in x0..<x1 {
                let i = (y * larghezza + x) * 4
                let l = Self.luminanza(pixel[i], pixel[i + 1], pixel[i + 2])
                conteggi[l, default: 0] += 1
                luminanze.append(l)
            }
        }
        guard let fondo = conteggi.max(by: { $0.value < $1.value })?.key else { return 1 }
        return luminanze.reduce(1.0) { max($0, Self.contrasto(fondo, $1)) }
    }
}
