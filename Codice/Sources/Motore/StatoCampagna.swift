import Foundation
import Dati

/// Identificatore stabile di un gruppo, assegnato dal Motore in modo deterministico
/// (05 §2.8): contatore nello stato, mai valori casuali né orologio.
public struct IdGruppo: Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    public let numero: Int
    public init(_ numero: Int) { self.numero = numero }
    public static func < (a: IdGruppo, b: IdGruppo) -> Bool { a.numero < b.numero }
    public var description: String { "gruppo-\(numero)" }
}

/// Un gruppo sulla mappa di campagna (01 §5.6.0): l'oggetto che dispone di
/// un'azione al giorno. In questa unità porta la sola identità, il nome, la
/// posizione e l'azione spesa; composizione, provviste, marcia lunga e imboscata
/// appartengono alle unità successive.
public struct Gruppo: Hashable, Codable, Sendable {
    public let id: IdGruppo
    public let parte: Parte
    /// La chiave del nome, presa dall'elenco chiuso e ordinato dei dati
    /// (01 §5.6.0.4): breve, stabile, conservata per tutta l'esistenza del gruppo.
    /// Il nome parlato lo risolve il pacchetto dei testi, perché è testo (00 §14.1).
    /// Vive nello stato e non si ricalcola dall'elenco: un gruppo conserva il
    /// proprio nome anche se l'elenco dei dati cambia.
    public let nome: IdentificatoreDati
    public var posizione: Cella
    /// Vero se l'azione della giornata è stata spesa (01 §5.6).
    public var azioneSpesa: Bool

    public init(id: IdGruppo, parte: Parte, nome: IdentificatoreDati,
                posizione: Cella, azioneSpesa: Bool) {
        self.id = id; self.parte = parte; self.nome = nome
        self.posizione = posizione; self.azioneSpesa = azioneSpesa
    }

    /// Lo stato che il gruppo dichiara quando lo si incontra (01 §5.16.1, 02 §4.4.1.1).
    /// In questa unità il vocabolario è ridotto a ciò che esiste: gli altri stati
    /// appartengono alle unità che li introducono e non si annunciano a vuoto.
    public var statoDichiarato: StatoGruppo { azioneSpesa ? .haAgito : .inAttesa }
}

/// I termini chiusi degli stati di un gruppo realizzati in questa unità
/// (02 §4.4.5: «in attesa», «ha agito»). Gli altri termini dell'insieme — in
/// marcia, in agguato, scatto disponibile, e gli stati di rifornimento — esistono
/// nei documenti e si aggiungono qui quando la regola che li produce esiste.
public enum StatoGruppo: String, Codable, Hashable, Sendable, CaseIterable {
    case inAttesa = "gruppo.in_attesa"
    case haAgito = "gruppo.ha_agito"
}

/// Una voce del registro degli eventi della campagna (01 §5.17, 02 §6.6).
/// Vi entrano soltanto i fatti che il giocatore non ha deciso (01 §5.17.1).
public struct VoceRegistro: Hashable, Codable, Sendable {
    public let numero: Int
    /// Il giorno cui la voce si riferisce, dichiarato nell'annuncio (02 §6.6).
    public let giorno: Int
    public let fatto: FattoRegistrato
    /// Il luogo del fatto, quando ne ha uno: attivando la voce il fuoco vi si porta
    /// (02 §6.6). I fatti di calendario non ne hanno, e la voce non si attiva.
    public let luogo: Cella?

    public init(numero: Int, giorno: Int, fatto: FattoRegistrato, luogo: Cella?) {
        self.numero = numero; self.giorno = giorno; self.fatto = fatto; self.luogo = luogo
    }
}

/// I fatti che il registro sa annotare. Insieme chiuso, come ogni vocabolario del
/// gioco: in questa unità ne esiste uno solo, perché i fatti non decisi dal
/// giocatore — mosse avversarie, rifornimento interrotto, imboscata scattata,
/// marcia lunga compiuta — appartengono tutti a unità successive (01 §5.17.1).
public enum FattoRegistrato: String, Codable, Hashable, Sendable, CaseIterable {
    case giornataAperta = "registro.giornata_aperta"
}

/// Lo stato completo di una campagna (05 §2.6). Un valore, interamente Codable,
/// senza alcun riferimento a schermate o annunci (00 §3.2).
public struct StatoCampagna: Hashable, Codable, Sendable {
    /// La mappa: riferimento alla definizione nei Contenuti più ciò che ne serve
    /// al Motore. In questa unità le caselle non hanno stato mutevole.
    public let mappa: MappaCampagna
    /// La data propria della campagna (01 §5.6.9.1): il giorno È il turno (05 §2.2.2).
    public var giorno: Int
    public var gruppi: [IdGruppo: Gruppo]
    /// Contatore per gli identificatori, deterministico (05 §2.8).
    public var prossimoIdGruppo: Int
    /// Indice del prossimo nome da assegnare: i nomi non si riusano (01 §5.6.0.4).
    public var prossimoIndiceNome: Int
    /// Il registro cronologico, dal più recente al meno recente in presentazione;
    /// qui si conserva in ordine di accadimento e si legge al contrario (02 §6.6).
    public var registro: [VoceRegistro]
    public var prossimoNumeroVoce: Int

    public init(mappa: MappaCampagna, giorno: Int, gruppi: [IdGruppo: Gruppo],
                prossimoIdGruppo: Int, prossimoIndiceNome: Int,
                registro: [VoceRegistro], prossimoNumeroVoce: Int) {
        self.mappa = mappa; self.giorno = giorno; self.gruppi = gruppi
        self.prossimoIdGruppo = prossimoIdGruppo
        self.prossimoIndiceNome = prossimoIndiceNome
        self.registro = registro; self.prossimoNumeroVoce = prossimoNumeroVoce
    }

    public var griglia: GrigliaCampagna { mappa.griglia }

    /// Ordine deterministico dei gruppi (per risoluzioni, rotori e impronte).
    public var gruppiOrdinati: [Gruppo] { gruppi.values.sorted { $0.id < $1.id } }

    /// Il gruppo che occupa una casella, se esiste. Derivato dai fatti, mai duplicato.
    /// Ogni casella contiene al massimo una formazione per parte (01 §5.6.0.2).
    public func occupante(di casella: Cella, parte: Parte = .giocatore) -> Gruppo? {
        gruppi.values.first { $0.posizione == casella && $0.parte == parte }
    }

    /// I propri gruppi che non hanno ancora agito, in ordine di lettura della
    /// casella: alimenta il conteggio dello stato e il salto diretto (02 §6.5.1, §7.3).
    public func gruppiInAttesa(di parte: Parte = .giocatore) -> [Gruppo] {
        gruppi.values
            .filter { $0.parte == parte && !$0.azioneSpesa }
            .sorted { $0.posizione == $1.posizione ? $0.id < $1.id : $0.posizione < $1.posizione }
    }

    public func gruppi(di parte: Parte) -> [Gruppo] {
        gruppi.values.filter { $0.parte == parte }
            .sorted { $0.posizione == $1.posizione ? $0.id < $1.id : $0.posizione < $1.posizione }
    }
}
