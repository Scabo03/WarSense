import XCTest
@testable import Dati
import Contenuti

/// Il CONTROLLO delle frasi accordate al genere (02 §4.6, decisione del titolare del 2026-11-21,
/// incarico 29). Rifiuta:
/// 1. un termine che fa da soggetto — archetipo, nome di gruppo, e ogni categoria di
///    `CategoriaSoggetto` — senza il proprio genere dichiarato nel vocabolario, o con un genere fuori
///    dai quattro;
/// 2. una frase accordata a cui manca la forma per uno dei quattro generi (anche nelle varianti di
///    verbosità), o che conserva la forma unica di prima;
/// 3. un sorgente che legge un termine soggetto senza passare da `Testi.soggetto` (una chiave
///    `"unita.…"` o `"gruppo.nome.…"` scritta nel codice), che ne fa uscire il nome da solo fuori dai
///    luoghi dichiarati, o che dà a una frase un soggetto con una chiave che non ha le forme accordate.
/// Ogni categoria può ricevere ciascuno dei quattro generi (un archetipo nuovo, un gruppo nuovo, un
/// titolo di campione): per questo le frasi si scrivono e si pretendono per tutti e quattro.
final class AccordoDiGenereTest: XCTestCase {

    private static let livelli = Verbosita.allCases.map(\.rawValue)
    private static let generi = Genere.allCases.map(\.rawValue)

    private var cartellaLingua: URL { Contenuti.testiDiFabbrica.appendingPathComponent("it.lproj") }

    private func tavola(_ nome: String) throws -> [String: Any] {
        let url = cartellaLingua.appendingPathComponent(nome)
        return try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: Any], "\(nome) leggibile")
    }

    /// Le chiavi di tutte le frasi (.strings e .stringsdict) degli annunci.
    private func chiaviDegliAnnunci() throws -> Set<String> {
        Set(try tavola("Annunci.strings").keys).union(try tavola("Annunci.stringsdict").keys)
    }

    // MARK: - 1. Ogni termine soggetto dichiara il proprio genere

    func test_ogni_termine_soggetto_dichiara_genere_e_numero() throws {
        let vocabolario = try tavola("Vocabolario.strings")
        var difetti: [String] = []
        for categoria in CategoriaSoggetto.allCases {
            let termini = vocabolario.keys.filter { $0.hasPrefix(categoria.prefisso) }.sorted()
            if termini.isEmpty { difetti.append("la categoria «\(categoria.rawValue)» non ha termini nel vocabolario") }
            for termine in termini {
                guard let genere = vocabolario[Testi.chiaveDelGenere(termine)] as? String else {
                    difetti.append("«\(termine)» non dichiara il genere (\(Testi.chiaveDelGenere(termine)))")
                    continue
                }
                if Genere(rawValue: genere) == nil {
                    difetti.append("«\(termine)» dichiara un genere fuori dai quattro: «\(genere)»")
                }
            }
        }
        // E ogni dichiarazione di genere riguarda un termine che esiste.
        for chiave in vocabolario.keys where chiave.hasPrefix("genere.") {
            let termine = String(chiave.dropFirst("genere.".count))
            if vocabolario[termine] == nil { difetti.append("«\(chiave)» dichiara il genere di un termine che non c'è") }
            if !CategoriaSoggetto.allCases.contains(where: { termine.hasPrefix($0.prefisso) }) {
                difetti.append("«\(chiave)» non appartiene a una categoria di soggetti")
            }
        }
        XCTAssertEqual(difetti, [], "termini soggetto senza genere:\n" + difetti.joined(separator: "\n"))
    }

    // MARK: - 2. Ogni frase accordata ha la forma per ciascun genere

    /// Le frasi accordate: per ciascuna base, le forme trovate (genere, livello di verbosità o nulla).
    private func frasiAccordate(_ chiavi: Set<String>) -> [String: Set<String>] {
        var esito: [String: Set<String>] = [:]
        for chiave in chiavi {
            var parti = chiave.components(separatedBy: ".")
            var livello = ""
            if let ultima = parti.last, Self.livelli.contains(ultima) { livello = ultima; parti.removeLast() }
            guard let genere = parti.last, Self.generi.contains(genere) else { continue }
            parti.removeLast()
            esito[parti.joined(separator: "."), default: []].insert(genere + "|" + livello)
        }
        return esito
    }

    func test_ogni_frase_accordata_ha_la_forma_per_ciascun_genere() throws {
        let chiavi = try chiaviDegliAnnunci()
        let accordate = frasiAccordate(chiavi)
        XCTAssertFalse(accordate.isEmpty, "nessuna frase accordata trovata: il controllo non morderebbe")
        var difetti: [String] = []
        for (base, forme) in accordate.sorted(by: { $0.key < $1.key }) {
            let livelli = Set(forme.map { String($0.split(separator: "|", omittingEmptySubsequences: false)[1]) })
            for livello in livelli.sorted() {
                for genere in Self.generi where !forme.contains(genere + "|" + livello) {
                    let manca = livello.isEmpty ? "\(base).\(genere)" : "\(base).\(genere).\(livello)"
                    difetti.append("«\(base)»: manca la forma per il genere \(genere)\(livello.isEmpty ? "" : " al livello \(livello)") (\(manca))")
                }
            }
            // La forma unica di prima non deve sopravvivere: chi la usasse incollerebbe il soggetto.
            if chiavi.contains(base) { difetti.append("«\(base)»: resta la forma unica, senza genere") }
            for livello in Self.livelli where chiavi.contains(base + "." + livello) {
                difetti.append("«\(base).\(livello)»: resta la forma unica, senza genere")
            }
        }
        print("ACCORDO-DI-GENERE frasi=\(accordate.count) forme=\(accordate.values.reduce(0) { $0 + $1.count })")
        XCTAssertEqual(difetti, [], "frasi accordate incomplete:\n" + difetti.joined(separator: "\n"))
    }

    // MARK: - 3. Il codice passa dal genere

    /// La radice del repository, dal percorso di questo file: Codice/Tests/DatiTest/<file>.
    private var radice: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
    }

    /// I sorgenti Swift del gioco: il pacchetto e l'applicazione, prove escluse.
    private func sorgenti() throws -> [(String, String)] {
        var esito: [(String, String)] = []
        for cartella in ["Codice/Sources", "Applicazione/Sorgenti"] {
            let base = radice.appendingPathComponent(cartella)
            let enumeratore = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil)
            while let url = enumeratore?.nextObject() as? URL {
                guard url.pathExtension == "swift" else { continue }
                let relativo = String(url.path.dropFirst(radice.path.count + 1))
                esito.append((relativo, try String(contentsOf: url, encoding: .utf8)))
            }
        }
        XCTAssertGreaterThan(esito.count, 20, "sorgenti trovati in \(radice.path)")
        return esito
    }

    /// I soli luoghi dove il nome di un soggetto può uscire da solo, senza frase: l'etichetta della
    /// tessera del deck e l'iniziale del gruppo disegnata sulla casella.
    private static let usciteIsolateAmmesse: Set<String> = [
        "Applicazione/Sorgenti/CostruttoreAnnunci.swift",
        "Applicazione/Sorgenti/CostruttoreAnnunciCampagna.swift",
    ]
    /// Il solo luogo dove la chiave di una frase con soggetto non è scritta per esteso: il registro della
    /// campagna, che la riceve dal fatto (`VoceRegistro.Fatto.chiaveTesto`). Le sue frasi le copre
    /// `TraduttoreCampagnaTest.test_incarico_29_le_voci_del_registro_si_accordano_al_genere`.
    private static let chiaviNonLetteraliAmmesse: Set<String> = ["Codice/Sources/Segnali/SignificatiCampagna.swift"]
    /// Il modulo che legge i termini soggetto dal vocabolario.
    private static let lettoriDeiSoggetti: Set<String> = ["Codice/Sources/Dati/Genere.swift", "Codice/Sources/Dati/Testi.swift"]

    func test_il_codice_inserisce_i_soggetti_soltanto_nelle_forme_accordate() throws {
        let chiavi = try chiaviDegliAnnunci()
        let accordate = Set(frasiAccordate(chiavi).keys)
        let letterale = try NSRegularExpression(pattern: #""(unita|gruppo\.nome)\."#)
        let conSoggetto = try NSRegularExpression(pattern: #"frase\(\s*("([^"]+)"|[^,]+?)\s*,\s*soggetto:"#)
        var difetti: [String] = []
        var chiamate = 0
        for (file, testo) in try sorgenti() {
            let tutto = NSRange(testo.startIndex..., in: testo)
            if !Self.lettoriDeiSoggetti.contains(file), letterale.firstMatch(in: testo, range: tutto) != nil {
                difetti.append("\(file): legge un termine soggetto senza Testi.soggetto (chiave «unita.…» o «gruppo.nome.…» nel codice)")
            }
            if testo.contains("nomeIsolato("), !Self.usciteIsolateAmmesse.contains(file),
               !Self.lettoriDeiSoggetti.contains(file) {
                difetti.append("\(file): fa uscire il nome di un soggetto da solo fuori dai luoghi dichiarati")
            }
            // Il modulo che definisce `frase(_:soggetto:…)` non è un luogo di chiamata.
            if Self.lettoriDeiSoggetti.contains(file) { continue }
            for corrispondenza in conSoggetto.matches(in: testo, range: tutto) {
                chiamate += 1
                if let r = Range(corrispondenza.range(at: 2), in: testo) {
                    let chiave = String(testo[r])
                    if !accordate.contains(chiave) {
                        difetti.append("\(file): «\(chiave)» riceve un soggetto ma non ha le forme accordate")
                    }
                } else if !Self.chiaviNonLetteraliAmmesse.contains(file) {
                    difetti.append("\(file): una frase con soggetto ha una chiave non scritta per esteso")
                }
            }
        }
        print("ACCORDO-DI-GENERE chiamate-con-soggetto=\(chiamate)")
        XCTAssertGreaterThan(chiamate, 20, "le chiamate con soggetto sono state trovate")
        XCTAssertEqual(difetti, [], "il codice incolla soggetti fuori dalle forme accordate:\n" + difetti.joined(separator: "\n"))
    }

    // MARK: - 4. Le forme si risolvono, e si accordano

    /// Le frasi dell'esempio della decisione, risolte davvero per i generi che il vocabolario porta.
    func test_le_frasi_si_risolvono_nella_forma_del_genere() throws {
        let testi = try Testi.carica(albero: Contenuti.testiDiFabbrica, lingua: "it")
        let fanteria = testi.soggetto(.unita, "fanteria_leggera")
        let tiratori = testi.soggetto(.unita, "tiratori")
        XCTAssertEqual(fanteria.genere, .femminile)
        XCTAssertEqual(tiratori.genere, .maschilePlurale)
        XCTAssertEqual(testi.frase("battaglia.contatto_subito", soggetto: fanteria, "A", "x", "y").testo,
                       "La tua fanteria leggera A è stata ingaggiata, x, y")
        XCTAssertEqual(testi.frase("battaglia.contatto_subito", soggetto: tiratori, "C", "x", "y").testo,
                       "I tuoi tiratori C sono stati ingaggiati, x, y")
        let aquila = testi.soggetto(.gruppo, "aquila")
        let corvo = testi.soggetto(.gruppo, "corvo")
        XCTAssertEqual(testi.frase("campagna.marcia_compiuta", soggetto: aquila, verbosita: .normale, 2, 3).testo,
                       "Aquila è arrivata in riga 2, casella 3")
        XCTAssertEqual(testi.frase("campagna.marcia_compiuta", soggetto: corvo, verbosita: .sintetico, 2, 3).testo,
                       "Corvo in riga 2, casella 3")
        XCTAssertEqual(testi.frase("divisione.reparto", soggetto: fanteria, 1).testo, "1 atomo di fanteria leggera")
        XCTAssertEqual(testi.frase("divisione.reparto", soggetto: tiratori, 6).testo, "6 atomi di tiratori")
        // Il termine soggetto non si legge più come termine qualunque: passa dal genere.
        XCTAssertEqual(testi.termine("unita.tiratori").testo, Testi.segnaposto)
        XCTAssertEqual(testi.termine("gruppo.nome.corvo").testo, Testi.segnaposto)
    }
}
