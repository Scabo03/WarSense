import Foundation

/// Una cella della griglia esagonale, con esagoni a punta in alto e righe orizzontali
/// continue (01 §7.1). La riga 1 è la retrolinea avversaria, la riga più alta quella
/// del giocatore (01 §7.3). Le colonne crescono da ovest a est.
public struct Cella: Hashable, Codable, Sendable, Comparable {
    public let riga: Int
    public let colonna: Int
    public init(riga: Int, colonna: Int) { self.riga = riga; self.colonna = colonna }

    /// Ordine di lettura: da ovest a est e dall'alto in basso (00 §11.5).
    public static func < (a: Cella, b: Cella) -> Bool {
        a.riga != b.riga ? a.riga < b.riga : a.colonna < b.colonna
    }
}

/// Geometria della griglia: adiacenza e distanza in celle.
/// Disposizione a righe sfalsate: le righe pari sono spostate di mezzo passo verso est.
public struct Griglia: Hashable, Codable, Sendable {
    public let righe: Int
    public let colonne: Int
    public init(righe: Int, colonne: Int) { self.righe = righe; self.colonne = colonne }

    public func contiene(_ cella: Cella) -> Bool {
        cella.riga >= 1 && cella.riga <= righe && cella.colonna >= 1 && cella.colonna <= colonne
    }

    /// I sei vicini, in ordine fisso: est, ovest, nord-est, nord-ovest, sud-est, sud-ovest (02 §2.2).
    public func vicini(di cella: Cella) -> [Cella] {
        let r = cella.riga, c = cella.colonna
        let sfalsata = r % 2 == 0
        let candidati: [Cella] = [
            Cella(riga: r, colonna: c + 1),
            Cella(riga: r, colonna: c - 1),
            Cella(riga: r - 1, colonna: sfalsata ? c + 1 : c),
            Cella(riga: r - 1, colonna: sfalsata ? c : c - 1),
            Cella(riga: r + 1, colonna: sfalsata ? c + 1 : c),
            Cella(riga: r + 1, colonna: sfalsata ? c : c - 1),
        ]
        return candidati.filter(contiene)
    }

    public func adiacenti(_ a: Cella, _ b: Cella) -> Bool { vicini(di: a).contains(b) }

    /// Distanza esagonale in celle, via coordinate cubiche (interna, deterministica).
    public func distanza(_ a: Cella, _ b: Cella) -> Int {
        let (ax, ay, az) = cubo(a)
        let (bx, by, bz) = cubo(b)
        return max(abs(ax - bx), abs(ay - by), abs(az - bz))
    }

    private func cubo(_ cella: Cella) -> (Int, Int, Int) {
        // Da coordinate a scaffale (riga/colonna, base 0) a cubiche, disposizione a righe pari sfalsate.
        let riga0 = cella.riga - 1
        let colonna0 = cella.colonna - 1
        let x = colonna0 - (riga0 - (riga0 & 1)) / 2
        let z = riga0
        let y = -x - z
        return (x, y, z)
    }

    /// Le due celle arretrate rispetto alla parte, in ordine deterministico
    /// (prima verso ovest, poi verso est). Servono al disingaggio (01 §9.8.2).
    public func celleArretrate(di cella: Cella, per parte: Parte) -> [Cella] {
        let versoIlBasso = parte == .giocatore // le retrovie del giocatore sono la riga più alta (01 §7.3)
        let r = cella.riga + (versoIlBasso ? 1 : -1)
        let sfalsata = cella.riga % 2 == 0
        let ovest = Cella(riga: r, colonna: sfalsata ? cella.colonna : cella.colonna - 1)
        let est = Cella(riga: r, colonna: sfalsata ? cella.colonna + 1 : cella.colonna)
        return [ovest, est].filter(contiene)
    }

    /// Avanzamento di una cella rispetto alla retrolinea della parte: 0 sulla propria retrolinea.
    public func avanzamento(di cella: Cella, per parte: Parte) -> Int {
        parte == .giocatore ? righe - cella.riga : cella.riga - 1
    }

    /// Le righe della zona di piazzamento della parte (01 §8.2.1).
    public func righeDiPiazzamento(per parte: Parte, quante: Int) -> ClosedRange<Int> {
        parte == .giocatore ? (righe - quante + 1)...righe : 1...quante
    }

    /// Tutte le celle nell'ordine di lettura (00 §11.5).
    public var tutteLeCelle: [Cella] {
        (1...righe).flatMap { r in (1...colonne).map { Cella(riga: r, colonna: $0) } }
    }
}

// Nota: `Parte` è definita in Dati ed è riesportata qui per comodità del Motore.
@_exported import enum Dati.Parte
