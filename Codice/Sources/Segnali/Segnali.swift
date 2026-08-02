import Foundation
import Dati
import enum Motore.EventoBattaglia

// Il punto centrale unico dei segnali (00 §5.3, 05 §11): riceve gli eventi in forma
// astratta e decide i canali. Questo bersaglio compila su ogni piattaforma: il nucleo
// di decisione è puro; la parte che tocca aptica, suono e annunci di sistema è
// confinata dietro la compilazione condizionale e prende corpo nella fase B (RDA-48).

/// I tre canali (02 §11, §12): l'annuncio c'è sempre, gli altri dipendono
/// da preferenze e apparecchio; ogni segnale aptico ha controparte (00 §5.2).
public enum CanaleSegnale: String, Codable, Sendable, CaseIterable {
    case annuncio, suono, aptica
}

/// Le preferenze locali dei canali (02 §14.2). Mai parte dello stato di partita.
public struct PreferenzeSegnali: Sendable {
    public var suoniAttivi: Bool
    public var apticaAttiva: Bool
    public init(suoniAttivi: Bool, apticaAttiva: Bool) {
        self.suoniAttivi = suoniAttivi
        self.apticaAttiva = apticaAttiva
    }
}

/// Il nucleo puro di decisione dei canali (05 §11.3), collaudabile senza piattaforma.
public struct DecisoreCanali: Sendable {
    public let apparecchioConAptica: Bool
    public init(apparecchioConAptica: Bool) { self.apparecchioConAptica = apparecchioConAptica }

    /// L'annuncio sempre; il suono se il canale è attivo; l'aptica se il canale è
    /// attivo e l'apparecchio dispone del motore (00 §5.1, 05 §11.3).
    public func canali(preferenze: PreferenzeSegnali, conSegnaleTattile: Bool) -> [CanaleSegnale] {
        var esito: [CanaleSegnale] = [.annuncio]
        if preferenze.suoniAttivi { esito.append(.suono) }
        if conSegnaleTattile && preferenze.apticaAttiva && apparecchioConAptica {
            esito.append(.aptica)
        }
        return esito
    }
}

#if canImport(UIKit)
// La realizzazione dei canali di piattaforma (annunci con lingua, CoreHaptics con
// motore mantenuto pronto, suoni) prende corpo nella fase B (05 §11.4–11.6).
#endif
