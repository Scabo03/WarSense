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
        "StrumentoVerifica": ["Foundation", "Verifica"],
    ]

    /// Anche la Presentazione rispetta confini dichiarati (05 §1.3): vive nel
    /// progetto applicativo ma il collaudo la sorveglia dalla stessa sede.
    static let sorgentiApplicazione = radiceSorgenti
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Applicazione/Sorgenti")
    static let importAmmessiApplicazione: Set<String> =
        ["Foundation", "UIKit", "Dati", "Motore", "Sessione", "Segnali", "Contenuti"]

    func test_05_1_3_confini_della_presentazione() throws {
        let contenuti = try FileManager.default.contentsOfDirectory(
            at: Self.sorgentiApplicazione, includingPropertiesForKeys: nil)
        for file in contenuti.filter({ $0.pathExtension == "swift" }).sorted(by: { $0.path < $1.path }) {
            let testo = try String(contentsOf: file, encoding: .utf8)
            for riga in testo.split(separator: "\n") {
                let pulita = riga.trimmingCharacters(in: .whitespaces)
                guard pulita.hasPrefix("import ") else { continue }
                let modulo = String(pulita.dropFirst(7).split(separator: " ")[0].split(separator: ".")[0])
                XCTAssertTrue(Self.importAmmessiApplicazione.contains(modulo),
                              "confine violato: Presentazione importa \(modulo) in \(file.lastPathComponent)")
            }
        }
    }

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

    /// IL REGNO È IDENTICO NELLE DUE MODALITÀ DI BATTAGLIA (01 §1.2; documento della modalità a
    /// campioni, 1.3; incarico 30, RDA-166): lo stato e le regole del regno non nominano nulla che
    /// appartenga a una modalità. Le forze sono un valore opaco e ciò che una voce militare dà è un
    /// gancio: reparti, atomi, archetipi, gruppi e formazioni stanno soltanto in `ForzeDelRegno.swift`
    /// e nel ponte con la campagna. Senza questo cancello la regola sarebbe una prescrizione, e la
    /// modalità a campioni troverebbe il regno da rifare.
    static let fileDelRegnoComune = ["Motore/StatoRegno.swift", "Motore/MotoreRegno.swift"]
    static let paroleDellaModalita = ["Reparto", "Gruppo", "Sciame", "Formazione", "atomi", "archetipo",
                                      "sciami", "reclutaReparto"]

    func test_01_1_2_il_regno_comune_non_nomina_la_modalita_di_battaglia() throws {
        let parola = try NSRegularExpression(pattern: "[A-Za-z_][A-Za-z0-9_]*")
        var esaminati = 0
        for nome in Self.fileDelRegnoComune {
            let testo = try String(contentsOf: Self.radiceSorgenti.appendingPathComponent(nome), encoding: .utf8)
            for (numero, riga) in testo.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                let codice = riga.components(separatedBy: "//")[0]
                let ns = codice as NSString
                for corrispondenza in parola.matches(in: codice, range: NSRange(location: 0, length: ns.length)) {
                    esaminati += 1
                    let identificatore = ns.substring(with: corrispondenza.range)
                    for vietata in Self.paroleDellaModalita {
                        XCTAssertFalse(identificatore.range(of: vietata, options: .caseInsensitive) != nil,
                                       "il regno comune nomina la modalità di battaglia: «\(identificatore)» in \(nome):\(numero + 1) (01 §1.2, RDA-166)")
                    }
                }
            }
        }
        XCTAssertGreaterThan(esaminati, 500, "i file del regno comune sono stati letti")
    }

    /// GLI ANNUNCI E IL FUOCO (RDA-183, incarico 32). Le notifiche del sistema d'accessibilità hanno un
    /// punto solo ciascuna: gli annunci escono dal punto dei segnali, che ne decide la priorità (00
    /// §5.3), e il fuoco si sposta dal suo registro (00 §11.2). Fino alla build 32 la schermata di
    /// divisione annunciava da sé, fuori dalla coda e senza la lingua dichiarata.
    static let notificheAmmesse: [String: Set<String>] = [
        "PuntoSegnali.swift": ["announcement"],
        "Servizi.swift": ["screenChanged", "layoutChanged"],
    ]

    func test_00_5_3_le_notifiche_di_accessibilita_hanno_un_punto_solo() throws {
        let invio = try NSRegularExpression(pattern: "UIAccessibility\\.post\\(notification: \\.([A-Za-z]+)")
        var inviate: [String: Set<String>] = [:]
        for file in try fileDellApplicazione() + fileSwift(di: "Segnali") {
            let testo = try String(contentsOf: file, encoding: .utf8)
            for riga in testo.split(separator: "\n") {
                let codice = riga.components(separatedBy: "//")[0]
                let ns = codice as NSString
                let trovate = invio.matches(in: codice, range: NSRange(location: 0, length: ns.length))
                if codice.contains("UIAccessibility.post") {
                    XCTAssertEqual(trovate.count, 1, "notifica non riconosciuta in \(file.lastPathComponent): \(codice)")
                }
                for corrispondenza in trovate {
                    let quale = ns.substring(with: corrispondenza.range(at: 1))
                    inviate[file.lastPathComponent, default: []].insert(quale)
                    XCTAssertTrue(Self.notificheAmmesse[file.lastPathComponent]?.contains(quale) == true,
                                  "\(file.lastPathComponent) invia da sé la notifica «\(quale)»: gli annunci escono dal punto dei segnali e il fuoco dal suo registro (00 §5.3, RDA-183)")
                }
            }
        }
        XCTAssertEqual(inviate, Self.notificheAmmesse, "le notifiche ammesse sono tutte in uso, e nessun'altra")
    }

    /// L'ANNUNCIO CHE ACCOMPAGNA UNO SPOSTAMENTO DEL FUOCO SEGUE LA RICHIESTA (RDA-183, incarico 32).
    /// La priorità dell'annuncio si decide quando esce: se il fuoco è chiesto dopo, l'annuncio esce a
    /// priorità predefinita e la lettura dell'elemento lo taglia dopo otto decimi di secondo, che è il
    /// difetto corretto. Il cancello legge il codice dell'applicazione: dentro una funzione, un annuncio
    /// a cui segue uno spostamento del fuoco — chiesto, o portato da un pannello che si chiude o da una
    /// schermata che compare — dev'essere preceduto dalla sua dichiarazione. L'annuncio di un rifiuto,
    /// che precede un'uscita dalla funzione, non accompagna nulla.
    func test_02_5_5_1_l_annuncio_che_accompagna_uno_spostamento_segue_la_richiesta_del_fuoco() throws {
        let funzione = try NSRegularExpression(pattern: "^    (?:@objc |private |public |fileprivate |override |static |@discardableResult )*(?:func |init\\()")
        let annuncio = try NSRegularExpression(pattern: "segnali\\.annuncia\\(|\\bannuncia\\(|\\bsegnala\\(")
        let dichiarazione = try NSRegularExpression(pattern: "Fuoco\\.(?:sposta|staPerSpostarsi)\\(")
        let spostamento = try NSRegularExpression(pattern: "Fuoco\\.sposta\\(|chiudiPannello\\(|presentaIlFronte\\(|(?<![A-Za-z.])present\\(|\\bdismiss\\(")
        func vale(_ espressione: NSRegularExpression, _ riga: String) -> Bool {
            espressione.firstMatch(in: riga, range: NSRange(location: 0, length: (riga as NSString).length)) != nil
        }
        var esaminati = 0
        for file in try fileDellApplicazione() {
            let righe = try String(contentsOf: file, encoding: .utf8)
                .split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
            var corpo: [(numero: Int, testo: String)] = []
            for (indice, riga) in righe.enumerated() {
                if vale(funzione, riga) { corpo = [] }
                corpo.append((indice + 1, riga.components(separatedBy: "//")[0]))
                guard riga == "    }" else { continue }
                for (posizione, voce) in corpo.enumerated() where vale(annuncio, voce.testo) && !voce.testo.contains("func ") {
                    esaminati += 1
                    let seguito = corpo[posizione..<min(posizione + 3, corpo.count)]
                        .map { $0.testo.trimmingCharacters(in: .whitespaces) }
                    if seguito.contains(where: { $0.hasPrefix("return") || $0.contains(" return") }) { continue }
                    let dopo = corpo[(posizione + 1)...].first { vale(spostamento, $0.testo) && !$0.testo.contains("func ") }
                    let prima = corpo[..<posizione].contains { vale(dichiarazione, $0.testo) }
                    XCTAssertTrue(dopo == nil || prima,
                                  "\(file.lastPathComponent):\(voce.numero) annuncia prima che alla riga \(dopo?.numero ?? 0) il fuoco si sposti: lo si chiede, o lo si dichiara, prima di annunciare (RDA-183)")
                }
                corpo = []
            }
        }
        XCTAssertGreaterThan(esaminati, 10, "gli annunci dell'applicazione sono stati letti")
    }

    private func fileDellApplicazione() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: Self.sorgentiApplicazione, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }.sorted { $0.path < $1.path }
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
