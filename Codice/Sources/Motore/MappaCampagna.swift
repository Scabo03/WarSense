import Foundation
import Dati

/// La geometria della mappa di campagna: caselle quadrate con adiacenza ortogonale,
/// quattro vicini per casella e nessuna diagonale (01 §5.1, 02 §2.3).
///
/// La cella è la stessa `Cella` del campo di battaglia, ed è voluto: il principio 7
/// ammette una sola differenza fra i due piani, cioè il numero di celle vicine.
/// Riga e colonna significano la stessa cosa, l'ordine di lettura è lo stesso, e
/// chi ha imparato a muoversi su un piano si muove sull'altro (00 §7.3).
public struct GrigliaCampagna: Hashable, Codable, Sendable {
    public let righe: Int
    public let colonne: Int
    public init(righe: Int, colonne: Int) { self.righe = righe; self.colonne = colonne }

    public func contiene(_ casella: Cella) -> Bool {
        casella.riga >= 1 && casella.riga <= righe && casella.colonna >= 1 && casella.colonna <= colonne
    }

    /// I quattro vicini, in ordine fisso: est, ovest, nord, sud (02 §2.3).
    /// Est e ovest sono ciò che lo scorrimento orizzontale percorre (02 §2.4);
    /// nord e sud sono le due azioni personalizzate della mappa (02 §2.5).
    public func vicini(di casella: Cella) -> [Cella] {
        let r = casella.riga, c = casella.colonna
        return [
            Cella(riga: r, colonna: c + 1),
            Cella(riga: r, colonna: c - 1),
            Cella(riga: r - 1, colonna: c),
            Cella(riga: r + 1, colonna: c),
        ].filter(contiene)
    }

    public func adiacenti(_ a: Cella, _ b: Cella) -> Bool { vicini(di: a).contains(b) }

    /// Distanza in caselle senza diagonali: la somma degli scarti (01 §5.1).
    public func distanza(_ a: Cella, _ b: Cella) -> Int {
        abs(a.riga - b.riga) + abs(a.colonna - b.colonna)
    }

    /// Tutte le caselle nell'ordine di lettura: da ovest a est e dall'alto in basso
    /// (00 §11.5, 02 §2.8), identico a quello della griglia di battaglia.
    public var tutteLeCaselle: [Cella] {
        (1...righe).flatMap { r in (1...colonne).map { Cella(riga: r, colonna: $0) } }
    }
}

/// La mappa come il Motore la usa: la geometria più ciò che ogni casella dichiara.
/// Nasce dalla definizione nei Contenuti (05 §2.6: riferimento più stato mutevole);
/// in questa unità le caselle non hanno ancora stato mutevole.
public struct MappaCampagna: Hashable, Codable, Sendable {
    public let identificatore: IdentificatoreDati
    public let formato: IdentificatoreDati
    public let griglia: GrigliaCampagna
    /// Le sole caselle che si scostano dalla condizione ordinaria.
    public let qualificazioni: [Cella: Qualificazione]
    /// La strettoia, al più una per mappa e non presente in ogni mappa (01 §5.1.3).
    public let strettoia: Cella?
    public let quartierGeneraleGiocatore: Cella
    public let quartierGeneraleAvversario: Cella

    public struct Qualificazione: Hashable, Codable, Sendable {
        public let terreno: TerrenoCasella
        public let strada: TipoStrada
        public init(terreno: TerrenoCasella, strada: TipoStrada) {
            self.terreno = terreno; self.strada = strada
        }
    }

    public func terreno(di casella: Cella) -> TerrenoCasella {
        qualificazioni[casella]?.terreno ?? .aperto
    }
    public func strada(di casella: Cella) -> TipoStrada {
        qualificazioni[casella]?.strada ?? .nessuna
    }
    public func quartierGenerale(di parte: Parte) -> Cella {
        parte == .giocatore ? quartierGeneraleGiocatore : quartierGeneraleAvversario
    }
    /// La parte cui appartiene il quartier generale eventualmente presente.
    public func quartierGeneraleSu(_ casella: Cella) -> Parte? {
        if casella == quartierGeneraleGiocatore { return .giocatore }
        if casella == quartierGeneraleAvversario { return .avversario }
        return nil
    }

    /// Costruisce la mappa dalla definizione dichiarativa già validata (05 §7.6).
    public init(definizione: DefinizioneMappa, formato: FormatoMappa) {
        self.identificatore = definizione.identificatore
        self.formato = formato.identificatore
        self.griglia = GrigliaCampagna(righe: formato.righe, colonne: formato.colonne)
        var mappa: [Cella: Qualificazione] = [:]
        for casella in definizione.caselle {
            mappa[Cella(riga: casella.riga, colonna: casella.colonna)] =
                Qualificazione(terreno: casella.terreno, strada: casella.strada)
        }
        self.qualificazioni = mappa
        self.strettoia = definizione.strettoia.map { Cella(riga: $0.riga, colonna: $0.colonna) }
        self.quartierGeneraleGiocatore = Cella(riga: definizione.quartierGenerali.giocatore.riga,
                                               colonna: definizione.quartierGenerali.giocatore.colonna)
        self.quartierGeneraleAvversario = Cella(riga: definizione.quartierGenerali.avversario.riga,
                                                colonna: definizione.quartierGenerali.avversario.colonna)
    }
}
