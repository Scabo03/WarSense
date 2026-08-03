import Foundation

// Le definizioni dei segnali tattili e sonori vivono nei file di dati, con nomi
// parlanti e parametri modificabili senza ricompilare (00 §5.5, 02 §11.8).

/// Un impulso di un pattern tattile: attesa dall'inizio, intensità, nitidezza.
public struct ImpulsoAptico: Codable, Hashable, Sendable {
    public let attesa: Int // millesimi di secondo
    public let intensita: Scalato
    public let nitidezza: Scalato
}

public struct PatternAptico: Codable, Hashable, Sendable {
    public let impulsi: [ImpulsoAptico]
}

/// Le definizioni caricate dei segnali: pattern per significato e suono per significato.
public struct DefinizioniSegnali: Sendable {
    public let pattern: [String: PatternAptico]
    public let suoni: [String: String]

    private struct FileAptica: Codable { let pattern: [String: PatternAptico] }
    private struct FileSuoni: Codable { let assegnazioni: [String: String] }

    /// Carica aptica.json e suoni.json dall'albero dei valori (05 §7.5).
    public static func carica(da cartella: URL) throws -> DefinizioniSegnali {
        func leggi<T: Decodable>(_ tipo: T.Type, _ nome: String) throws -> T {
            guard let dati = try? Data(contentsOf: cartella.appendingPathComponent(nome)) else {
                throw ErroreDati(chiave: "errore.dati.file_mancante", file: nome)
            }
            guard let esito = try? JSONDecoder().decode(tipo, from: dati) else {
                throw ErroreDati(chiave: "errore.dati.file_malformato", file: nome)
            }
            return esito
        }
        let aptica = try leggi(FileAptica.self, "aptica.json")
        let suoni = try leggi(FileSuoni.self, "suoni.json")
        // Il tetto dei significati tattili (02 §11.5): quindici, più la sola
        // variante d'intensità del cambio di riga (02 §11.7.1).
        guard aptica.pattern.count <= 16 else {
            throw ErroreDati(chiave: "errore.dati.troppi_significati_tattili", file: "aptica.json")
        }
        return DefinizioniSegnali(pattern: aptica.pattern, suoni: suoni.assegnazioni)
    }
}
