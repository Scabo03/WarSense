import Foundation
import Dati

/// I comandi discreti della battaglia (05 §3.4). Codifica stabile e versionata:
/// i casi si aggiungono, non si rinominano (05 §13.1).
public enum ComandoBattaglia: Hashable, Codable, Sendable {
    case seleziona(indiceDeck: Int)
    case deseleziona
    case piazza(cella: Cella)
    /// Percorso di una o al massimo due celle adiacenti (01 §9.5.0.3).
    case muovi(sciame: IdSciame, percorso: [Cella])
    case tira(sciame: IdSciame, bersaglio: IdSciame, proiettile: TipoOffesa)
    case ingaggia(sciame: IdSciame, bersaglio: IdSciame)
    case dichiaraResa
    /// Durante la ritirata combattuta: evacua un'unità non impegnata (01 §10.4).
    case ritiraUnita(sciame: IdSciame)
    case fineTurno
}

/// I motivi chiusi di non ammissibilità (05 §3.2). Ogni caso corrisponde a un termine
/// del vocabolario chiuso; i tre motivi di cella sono quelli, e soltanto quelli, di 01 §8.9.
public enum MotivoNonValido: String, Codable, Hashable, Sendable, CaseIterable {
    // I tre motivi di cella (01 §8.9, 02 §4.3).
    case troppoAvanzata = "cella.troppo_avanzata"
    case occupata = "cella.occupata"
    case ostacolo = "cella.ostacolo"
    // Motivi di comando.
    case azioneGiaSpesa = "comando.non_valido.azione_gia_spesa"
    case volumeInsufficiente = "comando.non_valido.volume_insufficiente"
    case fuoriTiro = "comando.non_valido.fuori_tiro"
    case impegnato = "comando.non_valido.impegnato"
    case munizioniEsaurite = "comando.non_valido.munizioni_esaurite"
    case nonIlTurno = "comando.non_valido.non_e_il_turno"
    case resaNonDisponibile = "comando.non_valido.resa_non_disponibile"
    case nessunaSelezione = "comando.non_valido.nessuna_selezione"
    case bersaglioNonValido = "comando.non_valido.bersaglio_non_valido"
    case battagliaConclusa = "comando.non_valido.battaglia_conclusa"
}

/// Costi che verrebbero pagati, dichiarati prima della conferma (00 §9.2, 05 §3.2).
public struct CostiDichiarati: Hashable, Codable, Sendable {
    public let volume: Int64
    public let residuoDopo: Int64
    public static let nessuno = CostiDichiarati(volume: 0, residuoDopo: 0)
}

/// Esito della validazione: la validazione e l'anteprima annunciata sono la stessa cosa (05 §3.2).
public enum EsitoValidazione: Hashable, Sendable {
    case valido(CostiDichiarati)
    case nonValido(MotivoNonValido)

    public var eValido: Bool { if case .valido = self { return true } else { return false } }
    public var motivo: MotivoNonValido? { if case .nonValido(let m) = self { return m } else { return nil } }
    public var costi: CostiDichiarati? { if case .valido(let c) = self { return c } else { return nil } }
}

/// L'esito qualitativo dell'accoppiamento offesa-protezione (01 §9.9.1, 02 §4.4.1.3).
public enum EfficaciaQualitativa: String, Codable, Hashable, Sendable {
    case efficace = "efficacia.efficace"
    case pocoEfficace = "efficacia.poco_efficace"
}

/// L'esito di un contatto in un giro, per l'annuncio complessivo (01 §9.7.1).
public struct EsitoContatto: Hashable, Codable, Sendable {
    public let cellaPrimo: Cella
    public let cellaSecondo: Cella
    public let dannoAlPrimo: Int64
    public let dannoAlSecondo: Int64
}

/// Gli eventi astratti del Motore (05 §3.7): fatti, mai annunci (00 §3.2).
public enum EventoBattaglia: Hashable, Codable, Sendable {
    case turnoIniziato(parte: Parte, numeroGiro: Int)
    case piazzamentoConfermato(parte: Parte, sciame: IdSciame, cella: Cella, costo: Int64, residuo: Int64)
    case elementoDeckEsaurito(parte: Parte, indice: Int)
    case spostamentoEseguito(sciame: IdSciame, a: Cella, costo: Int64, residuo: Int64)
    case tiroEseguito(sciame: IdSciame, bersaglio: IdSciame, danno: Int64, efficacia: EfficaciaQualitativa)
    case contattoAvviato(cella: Cella)
    /// Evento aggregato con l'esito di tutti i contatti del giro (05 §3.9).
    case esitoMischiaComplessivo([EsitoContatto])
    case disingaggio(sciame: IdSciame, da: Cella, a: Cella)
    case sciameDisfatto(sciame: IdSciame, cella: Cella, parte: Parte)
    case munizioniEsaurite(sciame: IdSciame, cella: Cella)
    case resaDichiarata(parte: Parte)
    case unitaEvacuata(sciame: IdSciame, costo: Int64)
    case sorpresaConclusa
    case battagliaConclusa(EsitoBattaglia)
}
