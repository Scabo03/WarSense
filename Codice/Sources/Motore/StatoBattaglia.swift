import Foundation
import Dati

/// Identificatore stabile di uno sciame, assegnato dal Motore in modo deterministico (05 §2.8).
public struct IdSciame: Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    public let numero: Int
    public init(_ numero: Int) { self.numero = numero }
    public static func < (a: IdSciame, b: IdSciame) -> Bool { a.numero < b.numero }
    public var description: String { "sciame-\(numero)" }
}

/// Uno sciame in campo (01 §4). Il serbatoio è la verità; gli atomi presenti si derivano.
public struct Sciame: Hashable, Codable, Sendable {
    public let id: IdSciame
    public let parte: Parte
    public let archetipo: IdentificatoreDati
    public let protezione: TipoProtezione
    /// La lettera del reparto in ordine di piazzamento dentro il proprio
    /// schieramento, mai riusata (01 §9.4.3): ordinale che la Presentazione
    /// risolve nel termine chiuso del vocabolario.
    public let lettera: Int
    /// Atomi con cui l'assetto è stato formato.
    public let atomiIniziali: Int64
    /// Punti vita residui (01 §4.2).
    public var serbatoio: Int64
    /// Scariche di munizioni residue (01 §3.4.3); zero per chi non tira.
    public var munizioni: Int
    public var posizione: Cella
    /// Vero se l'azione del turno è stata spesa (01 §9.5.0).
    public var azioneSpesa: Bool
    /// Vero se giunto come rinforzo (01 §11.6). Sempre falso nella fase A.
    public var rinforzo: Bool

    public init(id: IdSciame, parte: Parte, archetipo: IdentificatoreDati,
                protezione: TipoProtezione, lettera: Int, atomiIniziali: Int64, serbatoio: Int64,
                munizioni: Int, posizione: Cella, azioneSpesa: Bool, rinforzo: Bool) {
        self.id = id; self.parte = parte; self.archetipo = archetipo
        self.protezione = protezione; self.lettera = lettera; self.atomiIniziali = atomiIniziali
        self.serbatoio = serbatoio; self.munizioni = munizioni
        self.posizione = posizione; self.azioneSpesa = azioneSpesa; self.rinforzo = rinforzo
    }

    /// Atomi presenti: divisione con troncamento e minimo di uno finché vivo (01 §4.3).
    public func atomiPresenti(puntiVitaPerAtomo: Int64, minimo: Int64) -> Int64 {
        guard serbatoio > 0 else { return 0 }
        return max(minimo, serbatoio / puntiVitaPerAtomo)
    }
}

/// Un elemento del deck (01 §8.3): un tipo di sciame pronto, con gli esemplari restanti.
public struct ElementoDeck: Hashable, Codable, Sendable {
    public let archetipo: IdentificatoreDati
    public let protezione: TipoProtezione
    public let atomi: Int64
    public var esemplari: Int
}

/// Un contatto di mischia in corso (01 §9.7), con le consistenze d'ingresso (01 §9.8).
public struct Contatto: Hashable, Codable, Sendable {
    public let primo: IdSciame
    public let secondo: IdSciame
    public let consistenzaIngressoPrimo: Int64
    public let consistenzaIngressoSecondo: Int64
    public func coinvolge(_ id: IdSciame) -> Bool { primo == id || secondo == id }
    public func altro(rispettoA id: IdSciame) -> IdSciame { primo == id ? secondo : primo }
}

/// Coppia non ordinata di sciami, per la memoria dei disingaggi (01 §9.8.3).
public struct Coppia: Hashable, Codable, Sendable {
    public let minore: IdSciame
    public let maggiore: IdSciame
    public init(_ a: IdSciame, _ b: IdSciame) {
        minore = min(a, b); maggiore = max(a, b)
    }
}

/// La fase della sorpresa in una battaglia da imboscata (01 §9.3.2.1).
public enum FaseSorpresa: Hashable, Codable, Sendable {
    /// Turni consecutivi di vantaggio residui dell'imboscante.
    case vantaggio(restanti: Int)
    /// Il turno di chi subisce, che non vede nulla dell'avversario.
    case opacita
    /// Trasparenza piena (anche per le battaglie senza imboscata).
    case trasparente
}

/// Stato del bilancio di volume di una parte nel turno (01 §9.3).
public struct BilancioVolume: Hashable, Codable, Sendable {
    /// Base del turno corrente (già maggiorata se primo turno).
    public var baseTurno: Int64
    /// Volume riportato dal turno precedente: si somma ma non genera riporto (01 §9.3.4).
    public var riportoEntrante: Int64
    /// Quanto è stato speso in questo turno.
    public var spesa: Int64
    public var disponibile: Int64 { baseTurno + riportoEntrante - spesa }
}

/// Esito di una battaglia conclusa (01 §15.2.2, §15.2.3).
public struct EsitoBattaglia: Hashable, Codable, Sendable {
    public enum Modo: String, Codable, Sendable {
        case ritirataCompiuta = "ritirata_compiuta"
        case annientamento
    }
    public let sconfitto: Parte
    public let modo: Modo
    public let turni: Int
    public init(sconfitto: Parte, modo: Modo, turni: Int) {
        self.sconfitto = sconfitto
        self.modo = modo
        self.turni = turni
    }
}

/// Lo stato completo di una battaglia (05 §2.7). Un valore, interamente Codable,
/// senza alcun riferimento a schermate o annunci (00 §3.2).
public struct StatoBattaglia: Hashable, Codable, Sendable {
    // Impianto fisso dello scontro.
    public let formato: IdentificatoreDati
    public let griglia: Griglia
    public let caratteristica: IdentificatoreDati
    public let ostacoli: Set<Cella>
    /// Chi occupava per primo la casella e agisce per primo (01 §9.4.1).
    public let primoOccupante: Parte

    // Forze.
    public var sciami: [IdSciame: Sciame]
    public var deck: [Parte: [ElementoDeck]]
    /// Contatore per gli identificatori, deterministico (05 §2.8).
    public var prossimoIdSciame: Int
    /// La prossima lettera per parte (01 §9.4.3): cresce a ogni discesa in campo
    /// e non torna mai indietro, così una lettera non si riusa.
    public var prossimaLettera: [Parte: Int]
    /// Elemento del deck selezionato per parte (01 §6.6: anche l'interazione si salva).
    public var selezione: [Parte: Int]

    // Turni.
    public var parteDiTurno: Parte
    /// Numero di giri completi cominciati.
    public var giro: Int
    /// Turni giocati da ciascuna parte (per il primo turno maggiorato: 01 §9.3.1).
    public var turniGiocati: [Parte: Int]
    public var bilancio: [Parte: BilancioVolume]
    public var sorpresa: FaseSorpresa

    // Mischie.
    public var contatti: [Contatto]
    /// Coppie che si sono già staccate: al nuovo contatto nessuna soglia (01 §9.8.3).
    public var coppieStaccate: Set<Coppia>
    /// Divieto di nuovo ingaggio della coppia fino al giro indicato incluso (01 §9.8.2).
    public var divietoIngaggio: [Coppia: Int]

    // Ritirata combattuta (01 §10).
    public var resaDichiarataDa: Parte?
    public var evacuati: [Parte: [IdSciame]]

    // Perdite cumulative per la soglia della resa (01 §10.2).
    public var perditeSubite: [Parte: Int64]
    /// Forze effettivamente impiegate sul campo: la somma dei punti vita con cui
    /// ogni sciame è sceso in campo, riserve del deck escluse (01 §10.2, decisione
    /// del titolare in revisione delle chiusure). Cresce a ogni piazzamento,
    /// rinforzi compresi quando verranno; è la base di ogni soglia che dipende
    /// dalle perdite subite in battaglia.
    public var forzeImpegnate: [Parte: Int64]

    public var esito: EsitoBattaglia?

    /// Vero se lo sciame è impegnato a contatto e quindi non controllabile (01 §9.5).
    public func impegnato(_ id: IdSciame) -> Bool {
        contatti.contains { $0.coinvolge(id) }
    }

    /// Lo sciame che occupa una cella, se esiste. Derivato dai fatti, mai duplicato.
    public func occupante(di cella: Cella) -> Sciame? {
        sciami.values.first { $0.posizione == cella }
    }

    /// Ordine deterministico degli sciami (per risoluzioni e impronte).
    public var sciamiOrdinati: [Sciame] {
        sciami.values.sorted { $0.id < $1.id }
    }
}
