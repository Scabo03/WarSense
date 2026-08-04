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
    /// Il proiettile è proprietà fissa del reparto (01 §3.3.1, versione 3.3):
    /// il comando non lo trasporta più. Schema del giornale alla versione 2.
    case tira(sciame: IdSciame, bersaglio: IdSciame)
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

/// La fascia descrittiva delle perdite (01 §9.7.2, 02 §4.4.5): l'annuncio non
/// riporta mai numeri di danno. Le soglie sono nei valori (03 §5.14).
public enum FasciaPerdite: String, Codable, Hashable, Sendable, CaseIterable {
    case nessuna, lievi, significative, gravi
}

/// La fascia descrittiva della vicinanza al bersaglio nel tiro (01 §9.10.1, 02 §4.4.5):
/// il modificatore di vicinanza si annuncia così, mai con una cifra. Le soglie
/// stanno nei valori (03 §5.15).
public enum FasciaVicinanza: String, Codable, Hashable, Sendable, CaseIterable {
    case lontano = "vicinanza.lontano"
    case ravvicinato = "vicinanza.ravvicinato"
    case aRidosso = "vicinanza.a_ridosso"
}

/// La risposta che un bersaglio opporrebbe a chi lo ingaggia (01 §9.11, 02 §4.4.5).
/// Un reparto risponde ad al massimo due nemici: al primo per intero, al secondo
/// con la resa ridotta, dal terzo in poi per nulla. Tutte e tre le condizioni si
/// annunciano, perché tutte e tre cambiano la decisione.
public enum TipoRisposta: String, Codable, Hashable, Sendable, CaseIterable {
    case piena = "risposta.piena"
    case ridotta = "risposta.ridotta"
    case nessuna = "risposta.nessuna"

    /// La condizione che compete a chi occupa quel posto nella mischia del bersaglio.
    public init(posto: Int) {
        switch posto {
        case 0: self = .piena
        case 1: self = .ridotta
        default: self = .nessuna
        }
    }
}

/// La fascia descrittiva dell'accerchiamento di un bersaglio (01 §9.10.2, 02 §4.4.5).
/// `isolato` è la condizione ordinaria e non si annuncia (02 §8.7.1).
public enum FasciaAccerchiamento: String, Codable, Hashable, Sendable, CaseIterable {
    case isolato = "accerchiamento.isolato"
    case stretto = "accerchiamento.stretto"
    case circondato = "accerchiamento.circondato"
}

/// L'esito di un contatto in un giro, per l'annuncio complessivo (01 §9.7.1):
/// i numeri restano fatti interni, le fasce sono ciò che si annuncia (01 §9.7.2).
public struct EsitoContatto: Hashable, Codable, Sendable {
    public let partePrimo: Parte
    public let cellaPrimo: Cella
    public let cellaSecondo: Cella
    public let dannoAlPrimo: Int64
    public let dannoAlSecondo: Int64
    public let fasciaAlPrimo: FasciaPerdite
    public let fasciaAlSecondo: FasciaPerdite

    public init(partePrimo: Parte, cellaPrimo: Cella, cellaSecondo: Cella,
                dannoAlPrimo: Int64, dannoAlSecondo: Int64,
                fasciaAlPrimo: FasciaPerdite, fasciaAlSecondo: FasciaPerdite) {
        self.partePrimo = partePrimo
        self.cellaPrimo = cellaPrimo
        self.cellaSecondo = cellaSecondo
        self.dannoAlPrimo = dannoAlPrimo
        self.dannoAlSecondo = dannoAlSecondo
        self.fasciaAlPrimo = fasciaAlPrimo
        self.fasciaAlSecondo = fasciaAlSecondo
    }

    /// Le perdite subite dalla parte indicata in questo contatto.
    public func perdite(di parte: Parte) -> Int64 {
        partePrimo == parte ? dannoAlPrimo : dannoAlSecondo
    }

    /// La fascia delle perdite subite dalla parte indicata.
    public func fascia(di parte: Parte) -> FasciaPerdite {
        partePrimo == parte ? fasciaAlPrimo : fasciaAlSecondo
    }

    /// Stallo: nessuna perdita da ambo i lati (02 §4.4.5).
    public var stallo: Bool { fasciaAlPrimo == .nessuna && fasciaAlSecondo == .nessuna }
}

/// Gli eventi astratti del Motore (05 §3.7): fatti, mai annunci (00 §3.2).
/// Gli eventi che nominano un reparto trasportano archetipo e lettera (01 §9.4.3),
/// perché l'annuncio designi senza dover interrogare lo stato.
public enum EventoBattaglia: Hashable, Codable, Sendable {
    case turnoIniziato(parte: Parte, numeroGiro: Int)
    case piazzamentoConfermato(parte: Parte, sciame: IdSciame, archetipo: IdentificatoreDati,
                               lettera: Int, cella: Cella, costo: Int64, residuo: Int64)
    case elementoDeckEsaurito(parte: Parte, indice: Int)
    case spostamentoEseguito(parte: Parte, sciame: IdSciame, archetipo: IdentificatoreDati,
                             lettera: Int, a: Cella, costo: Int64, residuo: Int64)
    case tiroEseguito(parte: Parte, sciame: IdSciame, bersaglio: IdSciame,
                      bersaglioArchetipo: IdentificatoreDati, bersaglioLettera: Int,
                      danno: Int64, fascia: FasciaPerdite, efficacia: EfficaciaQualitativa)
    /// Il contatto si è formato e si è RISOLTO nell'istante stesso (01 §9.7.1):
    /// l'evento porta con sé il suo esito, come già fa il tiro, perché l'annuncio
    /// segua immediatamente l'azione che lo ha causato (02 §8.9.2).
    case contattoRisolto(parte: Parte, bersaglioArchetipo: IdentificatoreDati,
                         bersaglioLettera: Int, esito: EsitoContatto)
    /// Evento aggregato con l'esito di tutti i contatti del giro (05 §3.9).
    case esitoMischiaComplessivo([EsitoContatto])
    case disingaggio(sciame: IdSciame, da: Cella, a: Cella)
    case sciameDisfatto(sciame: IdSciame, archetipo: IdentificatoreDati, lettera: Int,
                        cella: Cella, parte: Parte)
    case munizioniEsaurite(sciame: IdSciame, cella: Cella)
    case resaDichiarata(parte: Parte)
    case unitaEvacuata(parte: Parte, sciame: IdSciame, costo: Int64)
    case sorpresaConclusa
    case battagliaConclusa(EsitoBattaglia)
}
