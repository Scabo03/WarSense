import XCTest
import Foundation
import Contenuti

/// Il cancello del termine dello stato di conoscenza (incarico 27, decisione del titolare del
/// 2026-11-20; 02 §4.2 dalla versione 2.6, 00 §9.4 dalla versione 1.3).
///
/// Lo stato di conoscenza che fino al documento 02 versione 2.5 si chiamava «avvistato» si chiama
/// «osservato». La decisione vale nei testi del gioco e nei documenti; questa prova rende
/// IMPOSSIBILE che il termine vecchio sopravviva come stato di conoscenza. Rifiuta:
/// - un termine degli stati di conoscenza (le voci `conoscenza.*` dei testi, comprese le forme col
///   plurale dello `.stringsdict`) diverso dai quattro chiusi, o che contenga il termine vecchio;
/// - qualunque occorrenza di «avvistat…» in qualunque testo del gioco fuori dall'unica frase in
///   cui il termine dice che un nemico è stato visto davvero, «formazione avversaria avvistata»;
/// - qualunque occorrenza di «avvistat…» nei documenti consolidati e nel documento della
///   modalità a campioni fuori dalle frasi ammesse qui sotto, che sono l'avvistamento vero e la
///   notizia stessa del cambio di termine.
/// I nomi interni del codice (`StatoConoscenza.avvistato`, la chiave `conoscenza.avvistato`) non
/// sono testi e non si toccano: la prova legge i VALORI, mai le chiavi.
final class VocabolarioOsservatoTest: XCTestCase {

    /// I quattro termini chiusi degli stati di conoscenza (02 §4.2).
    private static let terminiDellaConoscenza: Set<String> = ["inesplorato", "presunto", "osservato", "confermato"]

    /// Le sole frasi dei testi del gioco in cui il termine vecchio può comparire.
    private static let frasiAmmesseNeiTesti = ["formazione avversaria avvistata"]

    /// Le sole frasi dei documenti in cui il termine vecchio può comparire: l'avvistamento vero
    /// (01 §5.9.1.6, 02 §4.2) e le note che danno notizia del cambio di termine.
    private static let frasiAmmesseNeiDocumenti = [
        "formazione avversaria avvistata",
        "l'esercitazione avvistata",
        "stato di conoscenza «avvistato» diventa «osservato»",
        "stato di conoscenza avvistato diventa osservato",
        "il terzo termine era «avvistato»",
    ]

    private static let termineVecchio = try! NSRegularExpression(pattern: "avvistat[a-zàèéìòù]*",
                                                                  options: [.caseInsensitive])

    // MARK: - I testi del gioco

    private var cartellaTesti: URL { Contenuti.testiDiFabbrica.appendingPathComponent("it.lproj") }

    /// Tutte le foglie di testo di un file di testi (`.strings` o `.stringsdict`), con la chiave
    /// di primo livello da cui vengono.
    private func foglie(_ file: URL) throws -> [(chiave: String, testo: String)] {
        let dati = try Data(contentsOf: file)
        let radice = try PropertyListSerialization.propertyList(from: dati, format: nil)
        var esito: [(String, String)] = []
        func scendi(_ nodo: Any, _ chiave: String) {
            if let testo = nodo as? String { esito.append((chiave, testo)) }
            else if let dizionario = nodo as? [String: Any] { for (_, figlio) in dizionario { scendi(figlio, chiave) } }
            else if let elenco = nodo as? [Any] { for figlio in elenco { scendi(figlio, chiave) } }
        }
        guard let tavola = radice as? [String: Any] else { return [] }
        for (chiave, valore) in tavola { scendi(valore, chiave) }
        return esito
    }

    private func fileDeiTesti() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: cartellaTesti, includingPropertiesForKeys: nil)
            .filter { ["strings", "stringsdict"].contains($0.pathExtension) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    func test_02_4_2_gli_stati_di_conoscenza_sono_i_quattro_termini_chiusi() throws {
        let vocabolario = try foglie(cartellaTesti.appendingPathComponent("Vocabolario.strings"))
        let termini = vocabolario.filter { $0.chiave.hasPrefix("conoscenza.") }
        XCTAssertFalse(termini.isEmpty, "il vocabolario contiene gli stati di conoscenza")
        for (chiave, testo) in termini {
            XCTAssertTrue(Self.terminiDellaConoscenza.contains(testo),
                          "lo stato di conoscenza «\(chiave)» vale «\(testo)», che non è uno dei quattro termini chiusi "
                          + "\(Self.terminiDellaConoscenza.sorted()) (02 §4.2)")
        }
        // Le forme col numero di turni stanno nello .stringsdict: ognuna comincia con il proprio
        // termine chiuso, e nessuna con il termine vecchio.
        let plurali = try foglie(cartellaTesti.appendingPathComponent("Annunci.stringsdict"))
            .filter { $0.chiave.hasPrefix("conoscenza.") }
        for (chiave, testo) in plurali {
            let intervallo = NSRange(testo.startIndex..., in: testo)
            XCTAssertNil(Self.termineVecchio.firstMatch(in: testo, range: intervallo),
                         "la forma «\(testo)» di «\(chiave)» usa il termine vecchio dello stato di conoscenza")
        }
    }

    func test_00_9_4_nessun_testo_del_gioco_usa_il_termine_vecchio_come_stato() throws {
        var violazioni: [String] = []
        for file in try fileDeiTesti() {
            for (chiave, testo) in try foglie(file) {
                violazioni += Self.occorrenzeNonAmmesse(in: testo, ammesse: Self.frasiAmmesseNeiTesti)
                    .map { "\(file.lastPathComponent) «\(chiave)»: …\($0)…" }
            }
        }
        XCTAssertTrue(violazioni.isEmpty,
                      "il termine vecchio «avvistato» sopravvive nei testi del gioco fuori dall'avvistamento vero:\n"
                      + violazioni.joined(separator: "\n"))
    }

    // MARK: - I documenti

    /// La radice del repository, dal percorso di questo file: `Codice/Tests/DatiTest/…`.
    private var radice: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
    }

    func test_documenti_consolidati_chiamano_osservato_lo_stato_di_conoscenza() throws {
        let fondamenta = radice.appendingPathComponent("Fondamenta")
        let documenti = try FileManager.default.contentsOfDirectory(at: fondamenta, includingPropertiesForKeys: nil)
            .filter { nome in
                let n = nome.lastPathComponent
                // I consolidati 00, 01, 02, 03, 05 e il documento della modalità a campioni. Restano
                // fuori il 04, che è ricerca storica e usa «avvistamento» nel senso storico, e i
                // registri e i documenti di lavoro, che conservano la storia com'era.
                return n.hasSuffix(".md") && (n.range(of: "^0[0-35]-", options: .regularExpression) != nil
                                              || n == "modalita-a-campioni.md")
            }
        XCTAssertEqual(documenti.count, 6, "i cinque consolidati e il documento della modalità a campioni")
        var violazioni: [String] = []
        for documento in documenti.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let testo = try String(contentsOf: documento, encoding: .utf8)
            violazioni += Self.occorrenzeNonAmmesse(in: testo, ammesse: Self.frasiAmmesseNeiDocumenti)
                .map { "\(documento.lastPathComponent): …\($0)…" }
        }
        XCTAssertTrue(violazioni.isEmpty,
                      "il termine vecchio «avvistato» sopravvive nei documenti fuori dalle frasi ammesse:\n"
                      + violazioni.joined(separator: "\n"))
    }

    // MARK: - Ausiliaria

    /// Le occorrenze del termine vecchio che non cadono dentro una delle frasi ammesse, ciascuna
    /// con un po' di contesto.
    private static func occorrenzeNonAmmesse(in testo: String, ammesse: [String]) -> [String] {
        let nsTesto = testo as NSString
        let tutto = NSRange(location: 0, length: nsTesto.length)
        var coperti: [NSRange] = []
        for frase in ammesse {
            var cerca = tutto
            while true {
                let trovato = nsTesto.range(of: frase, options: [.caseInsensitive], range: cerca)
                if trovato.location == NSNotFound { break }
                coperti.append(trovato)
                let inizio = trovato.location + trovato.length
                cerca = NSRange(location: inizio, length: nsTesto.length - inizio)
            }
        }
        return termineVecchio.matches(in: testo, range: tutto).compactMap { m in
            let dentro = coperti.contains { NSLocationInRange(m.range.location, $0)
                && m.range.location + m.range.length <= $0.location + $0.length }
            if dentro { return nil }
            let da = max(0, m.range.location - 40), a = min(nsTesto.length, m.range.location + m.range.length + 40)
            return nsTesto.substring(with: NSRange(location: da, length: a - da)).replacingOccurrences(of: "\n", with: " ")
        }
    }
}
