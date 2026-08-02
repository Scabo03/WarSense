import Foundation

/// Numero a virgola fissa: intero scalato per mille (05 §2.2.1, RDA-44).
/// Nel Motore la virgola mobile è vietata: i coefficienti decimali dei file
/// diventano `Scalato` al caricamento e ogni formula opera su interi.
/// Convenzione dei file: al più tre cifre decimali.
public struct Scalato: Hashable, Sendable, Codable {
    /// Fattore di scala fisso e dichiarato.
    public static let fattore: Int64 = 1000

    /// Il valore scalato: `grezzo == valore reale × 1000`.
    public let grezzo: Int64

    public init(grezzo: Int64) { self.grezzo = grezzo }

    /// Un intero esatto (senza parte decimale).
    public init(intero: Int64) { self.grezzo = intero * Scalato.fattore }

    /// Millesimi espliciti: `Scalato(millesimi: 1300)` è 1,3.
    public init(millesimi: Int64) { self.grezzo = millesimi }

    public static let zero = Scalato(grezzo: 0)
    public static let uno = Scalato(intero: 1)

    // MARK: Aritmetica a virgola fissa, deterministica su ogni piattaforma.

    public static func + (a: Scalato, b: Scalato) -> Scalato { Scalato(grezzo: a.grezzo + b.grezzo) }
    public static func - (a: Scalato, b: Scalato) -> Scalato { Scalato(grezzo: a.grezzo - b.grezzo) }
    public static func * (a: Scalato, b: Scalato) -> Scalato {
        Scalato(grezzo: a.grezzo.multipliedReportingOverflow(by: b.grezzo).partialValue / Scalato.fattore)
    }
    /// Divisione con troncamento verso lo zero, coerente con 00 §13.5.
    public static func / (a: Scalato, b: Scalato) -> Scalato {
        Scalato(grezzo: (a.grezzo * Scalato.fattore) / b.grezzo)
    }
    public static func < (a: Scalato, b: Scalato) -> Bool { a.grezzo < b.grezzo }
    public static func <= (a: Scalato, b: Scalato) -> Bool { a.grezzo <= b.grezzo }
    public static func > (a: Scalato, b: Scalato) -> Bool { a.grezzo > b.grezzo }
    public static func >= (a: Scalato, b: Scalato) -> Bool { a.grezzo >= b.grezzo }

    /// Moltiplica un intero per questo coefficiente, troncando per difetto (00 §13.5).
    public func applicato(a intero: Int64) -> Int64 { (intero * grezzo) / Scalato.fattore }

    /// Parte intera per troncamento (00 §13.5).
    public var parteIntera: Int64 { grezzo / Scalato.fattore }

    // MARK: Codifica: nei file JSON il valore compare come numero decimale ordinario.

    public init(from decoder: Decoder) throws {
        let contenitore = try decoder.singleValueContainer()
        // Decodifica per via testuale per evitare che la virgola mobile decida il valore.
        if let d = try? contenitore.decode(Double.self) {
            // Convenzione: al più tre cifre decimali nei file; l'arrotondamento al millesimo
            // è quindi esatto per ogni valore ammesso.
            self.grezzo = Int64((d * 1000).rounded())
        } else {
            throw DecodingError.dataCorruptedError(in: contenitore, debugDescription: "valore.non.numerico")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var contenitore = encoder.singleValueContainer()
        try contenitore.encode(Double(grezzo) / 1000.0)
    }
}
