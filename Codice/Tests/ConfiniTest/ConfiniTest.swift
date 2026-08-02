import XCTest

/// Collaudo dei confini (05 §14.5, 05 §1.3): le regole di dipendenza fra i bersagli
/// sono verificate dal collaudo, non affidate alla disciplina di chi scrive.
/// Verifica anche che nessuna stringa di testo utente viva nel codice (00 §14.1).
final class ConfiniTest: XCTestCase {

    static let radiceSorgenti: URL = {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // ConfiniTest
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // Codice
            .appendingPathComponent("Sources")
    }()

    /// Le regole di dipendenza di 05 §1.3, come insiemi di moduli importabili.
    /// Segnali può importare Motore (il solo tipo degli eventi), Dati e i framework
    /// di piattaforma; mai Sessione né Presentazione (05 §1.3, RDA-48).
    static let importAmmessi: [String: Set<String>] = [
        "Dati": ["Foundation"],
        "Motore": ["Foundation", "Dati"],
        "Sessione": ["Foundation", "Motore", "Dati"],
        "Contenuti": ["Foundation"],
        "Segnali": ["Foundation", "Motore", "Dati", "UIKit", "CoreHaptics", "AVFoundation"],
        "Verifica": ["Foundation", "Sessione", "Motore", "Dati", "Contenuti"],
    ]

    func fileSwift(di bersaglio: String) throws -> [URL] {
        let cartella = Self.radiceSorgenti.appendingPathComponent(bersaglio)
        let contenuti = try FileManager.default.contentsOfDirectory(at: cartella,
                                                                    includingPropertiesForKeys: nil)
        return contenuti.filter { $0.pathExtension == "swift" }.sorted { $0.path < $1.path }
    }

    func test_05_1_3_regole_di_dipendenza_fra_i_bersagli() throws {
        for (bersaglio, ammessi) in Self.importAmmessi.sorted(by: { $0.key < $1.key }) {
            for file in try fileSwift(di: bersaglio) {
                let testo = try String(contentsOf: file, encoding: .utf8)
                for riga in testo.split(separator: "\n") {
                    let pulita = riga.trimmingCharacters(in: .whitespaces)
                    guard pulita.contains("import ") && !pulita.hasPrefix("//") else { continue }
                    // Forme: "import X", "@_exported import enum X.Y", "import struct X.Y".
                    let parole = pulita.split(separator: " ").map(String.init)
                    guard let posizione = parole.firstIndex(of: "import"), posizione + 1 < parole.count
                    else { continue }
                    var modulo = parole[posizione + 1]
                    if ["enum", "struct", "class", "func", "typealias"].contains(modulo),
                       posizione + 2 < parole.count {
                        modulo = parole[posizione + 2]
                    }
                    modulo = String(modulo.split(separator: ".")[0])
                    XCTAssertTrue(ammessi.contains(modulo),
                                  "confine violato: \(bersaglio) importa \(modulo) in \(file.lastPathComponent) (05 §1.3)")
                }
            }
        }
    }

    /// Nessuna stringa di testo utente nel codice (00 §14.1): le stringhe letterali dei
    /// bersagli sono chiavi e identificatori, riconoscibili perché prive di spazi.
    func test_00_14_1_nessuna_stringa_di_testo_utente_nel_codice() throws {
        let letterale = try NSRegularExpression(pattern: "\"((?:[^\"\\\\]|\\\\.)*)\"")
        for bersaglio in Self.importAmmessi.keys.sorted() {
            for file in try fileSwift(di: bersaglio) {
                let testo = try String(contentsOf: file, encoding: .utf8)
                for riga in testo.split(separator: "\n", omittingEmptySubsequences: false) {
                    let senzaCommento = riga.components(separatedBy: "//")[0]
                    let ns = senzaCommento as NSString
                    for corrispondenza in letterale.matches(in: senzaCommento,
                                                            range: NSRange(location: 0, length: ns.length)) {
                        let contenuto = ns.substring(with: corrispondenza.range(at: 1))
                        XCTAssertFalse(contenuto.contains(" "),
                                       "possibile testo utente nel codice di \(bersaglio)/\(file.lastPathComponent): \(contenuto) (00 §14.1)")
                    }
                }
            }
        }
    }

    /// La virgola mobile è vietata nel Motore (05 §2.2.1, RDA-44).
    func test_05_2_2_1_nessuna_virgola_mobile_nel_motore() throws {
        for file in try fileSwift(di: "Motore") {
            let testo = try String(contentsOf: file, encoding: .utf8)
            for (numero, riga) in testo.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                let senzaCommento = riga.components(separatedBy: "//")[0]
                XCTAssertFalse(senzaCommento.contains("Double") || senzaCommento.contains("Float"),
                               "virgola mobile nel Motore: \(file.lastPathComponent):\(numero + 1) (RDA-44)")
            }
        }
    }
}
