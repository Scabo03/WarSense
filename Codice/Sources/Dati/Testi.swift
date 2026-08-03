import Foundation

/// Un testo risolto con la propria lingua dichiarata (00 §14.4, 05 §8.3).
/// Nessun testo raggiunge la voce o lo schermo senza passare da questo tipo.
public struct TestoLocalizzato: Hashable, Sendable {
    public let testo: String
    public let lingua: String
    public init(testo: String, lingua: String) {
        self.testo = testo
        self.lingua = lingua
    }
}

/// I tre livelli di verbosità (00 §9.5). Preferenza locale, mai parte dello stato.
public enum Verbosita: String, Codable, Sendable, CaseIterable {
    case sintetico, normale, dettagliato
}

/// Caricatore dei testi (05 §8). Carica da una cartella sostituibile attraverso una
/// copia di lavoro a percorso unico per sessione: la prova sul campo ha mostrato che
/// i Bundle sono memorizzati per percorso e la sostituzione dei file sullo stesso
/// percorso restituisce contenuto stantio (CatenaTestiEsterniTest, prova 4).
public struct Testi: Sendable {
    public let lingua: String
    public let versione: String
    private let percorsoBundle: String

    /// Marcatore inequivocabile di chiave irrisolta: mai mostrato in un prodotto corretto,
    /// intercettato dal collaudo di completezza delle chiavi (05 §7.8, §14.3).
    public static let segnaposto = "‼️"

    public struct ManifestTesti: Codable, Sendable {
        public let versione: String
        public let lingue: [String]
        /// Impronte dei file di testo, come nel manifest dei valori: la copia in
        /// Documenti si rinfresca quando i byte del manifest cambiano, quindi ogni
        /// modifica ai testi DEVE rigenerarle. La versione resta ferma: si cambia
        /// solo su richiesta del titolare (memoria di infrastruttura, regola 5).
        public let impronte: [String: String]?
    }

    /// Carica il pacchetto della lingua indicata dall'albero Testi.
    /// - Parameters:
    ///   - albero: la cartella Testi (di fabbrica o in Documenti).
    ///   - lingua: identificatore della lingua (es. "it").
    public static func carica(albero: URL, lingua: String) throws -> Testi {
        let manifestDati: Data
        do { manifestDati = try Data(contentsOf: albero.appendingPathComponent("manifest.json")) }
        catch { throw ErroreDati(chiave: "errore.testi.manifest_mancante", file: "manifest.json") }
        guard let manifest = try? JSONDecoder().decode(ManifestTesti.self, from: manifestDati) else {
            throw ErroreDati(chiave: "errore.testi.manifest_malformato", file: "manifest.json")
        }
        guard manifest.lingue.contains(lingua) else {
            throw ErroreDati(chiave: "errore.testi.lingua_assente", file: "manifest.json", voce: lingua)
        }
        let sorgente = albero.appendingPathComponent(lingua + ".lproj")
        // Copia di lavoro a percorso unico: aggira la cache dei Bundle.
        let copia = FileManager.default.temporaryDirectory
            .appendingPathComponent("testi-\(lingua)-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: sorgente, to: copia)
        guard Bundle(url: copia) != nil else {
            throw ErroreDati(chiave: "errore.testi.pacchetto_illeggibile", file: lingua + ".lproj")
        }
        return Testi(lingua: lingua, versione: manifest.versione, percorsoBundle: copia.path)
    }

    private var bundle: Bundle? { Bundle(path: percorsoBundle) }

    /// Risolve una chiave in una frase intera con segnaposto riempiti (00 §14.2).
    /// I plurali passano dal meccanismo di sistema (00 §14.3): il formato viene
    /// da .stringsdict e la regola plurale dalla lingua dichiarata.
    public func frase(_ chiave: String, tavola: String = "Annunci", _ argomenti: any CVarArg...) -> TestoLocalizzato {
        risolvi(chiave, tavola: tavola, argomenti: argomenti)
    }

    /// Variante di verbosità: cerca `chiave.livello` e ripiega sulla chiave base (05 §8.5).
    public func frase(_ chiave: String, verbosita: Verbosita, tavola: String = "Annunci",
                      _ argomenti: any CVarArg...) -> TestoLocalizzato {
        let specifica = chiave + "." + verbosita.rawValue
        let esito = risolvi(specifica, tavola: tavola, argomenti: argomenti)
        if esito.testo != Testi.segnaposto { return esito }
        return risolvi(chiave, tavola: tavola, argomenti: argomenti)
    }

    /// Un termine del vocabolario chiuso (02 §4, 05 §8.4): tavola dedicata, mai variato.
    public func termine(_ chiave: String) -> TestoLocalizzato {
        risolvi(chiave, tavola: "Vocabolario", argomenti: [])
    }

    /// Vero se la chiave esiste nel pacchetto: usato dal collaudo di completezza.
    public func esiste(_ chiave: String, tavola: String = "Annunci") -> Bool {
        guard let bundle else { return false }
        return bundle.localizedString(forKey: chiave, value: Testi.segnaposto, table: tavola) != Testi.segnaposto
    }

    private func risolvi(_ chiave: String, tavola: String, argomenti: [any CVarArg]) -> TestoLocalizzato {
        guard let bundle else { return TestoLocalizzato(testo: Testi.segnaposto, lingua: lingua) }
        let formato = bundle.localizedString(forKey: chiave, value: Testi.segnaposto, table: tavola)
        guard formato != Testi.segnaposto else { return TestoLocalizzato(testo: Testi.segnaposto, lingua: lingua) }
        if argomenti.isEmpty { return TestoLocalizzato(testo: formato, lingua: lingua) }
        let testo = String(format: formato, locale: Locale(identifier: lingua), arguments: argomenti)
        return TestoLocalizzato(testo: testo, lingua: lingua)
    }
}
