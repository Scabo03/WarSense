import Foundation

/// L'uscita del programma di verifica (05 §12.6): righe separate da virgole, una
/// sezione per famiglia di misura, ogni riga riproducibile. L'uscita è per la
/// persona che sviluppa, in forma di dati: non è testo di prodotto e non passa
/// dai testi localizzati (00 §14.1 riguarda ciò che il giocatore ascolta).
public struct Rapporto: Sendable {

    public struct Sezione: Sendable {
        public let nome: String
        public let intestazione: [String]
        public let righe: [[String]]
        public init(nome: String, intestazione: [String], righe: [[String]]) {
            self.nome = nome; self.intestazione = intestazione; self.righe = righe
        }
    }

    public private(set) var sezioni: [Sezione] = []
    public init() {}

    public mutating func aggiungi(_ sezione: Sezione) { sezioni.append(sezione) }

    static let separatore = ","
    static let marcatore = "#"

    /// Il testo completo. A parità di valori e di scenari è identico fra una corsa
    /// e l'altra: è la riproducibilità che 05 §12.6 richiede.
    public var testo: String {
        var righe: [String] = []
        for sezione in sezioni {
            righe.append(Self.marcatore + sezione.nome)
            righe.append(sezione.intestazione.joined(separator: Self.separatore))
            for riga in sezione.righe { righe.append(riga.joined(separator: Self.separatore)) }
            righe.append("")
        }
        return righe.joined(separator: "\n")
    }

    /// Scrive una sezione per file dentro una cartella, più il rapporto intero.
    public func scrivi(in cartella: URL) throws {
        try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        for sezione in sezioni {
            var righe = [sezione.intestazione.joined(separator: Self.separatore)]
            righe.append(contentsOf: sezione.righe.map { $0.joined(separator: Self.separatore) })
            try (righe.joined(separator: "\n") + "\n")
                .write(to: cartella.appendingPathComponent(sezione.nome + ".csv"),
                       atomically: true, encoding: .utf8)
        }
        try (testo + "\n").write(to: cartella.appendingPathComponent("rapporto.csv"),
                                 atomically: true, encoding: .utf8)
    }
}

/// Statistiche su una serie di interi, tutte in aritmetica intera perché la misura
/// si ripeta identica ovunque (05 §2.2.1 vale per il Motore; qui è una scelta di
/// prudenza sulla riproducibilità dell'uscita).
public struct Distribuzione: Sendable {
    public let quanti: Int
    public let minimo: Int
    public let mediana: Int
    public let massimo: Int
    public let media: Int

    public init(_ valori: [Int]) {
        let ordinati = valori.sorted()
        quanti = ordinati.count
        minimo = ordinati.first ?? 0
        massimo = ordinati.last ?? 0
        mediana = ordinati.isEmpty ? 0 : ordinati[ordinati.count / 2]
        media = ordinati.isEmpty ? 0 : ordinati.reduce(0, +) / ordinati.count
    }
}
