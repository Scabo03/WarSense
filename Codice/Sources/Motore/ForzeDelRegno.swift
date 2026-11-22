import Foundation
import Dati

// Le forze militari del regno, e ciò che una voce militare fa loro: la SOLA parte del regno che
// dipende dalla modalità di battaglia (01 §1.2; documento della modalità a campioni, 1.3; incarico 30,
// RDA-166). Il resto del regno — calendario, risorse, bilancio, voci, registro — tratta le forze come
// un valore opaco e non nomina né reparti né gruppi (`StatoRegno.swift`, `MotoreRegno.swift`).
//
// Questa versione conosce la modalità a sciami. La modalità a campioni aggiungerà qui un caso a
// `ForzeDelRegno` — l'organico dei combattenti e gli eroi, con infortuni e recuperi — e i propri
// ganci a `EffettoMilitare`, senza che il resto del regno cambi.

/// Una formazione del regno nella modalità a sciami: ciò che un gruppo è quando non sta su un fronte.
/// La categoria (01 §5.2) e i reparti che la compongono (01 §5.6.0), senza casella né nome, che le dà
/// il fronte quando la formazione parte.
public struct FormazioneDelRegno: Hashable, Codable, Sendable {
    public let categoria: CategoriaFormazione
    public var composizione: [Reparto]

    public init(categoria: CategoriaFormazione, composizione: [Reparto]) {
        self.categoria = categoria; self.composizione = composizione
    }

    public var atomiTotali: Int { composizione.reduce(0) { $0 + $1.atomi } }
}

/// Le forze militari del regno, nella forma della modalità di battaglia scelta all'inizio della
/// partita (01 §1.2).
public enum ForzeDelRegno: Hashable, Codable, Sendable {
    /// Modalità a sciami: le formazioni, nell'ordine in cui partono per il fronte.
    case sciami([FormazioneDelRegno])

    /// Le formazioni della modalità a sciami.
    public var formazioni: [FormazioneDelRegno] {
        switch self {
        case .sciami(let formazioni): return formazioni
        }
    }

    /// Quante unità contano le forze, nella misura della modalità: nella modalità a sciami le
    /// formazioni. È il numero che la dichiarazione di conclusione dice di ciò che rientra.
    public var numeroDiUnita: Int {
        switch self {
        case .sciami(let formazioni): return formazioni.count
        }
    }

    /// Vero se il regno ha di che condurre una campagna: nella modalità a sciami, almeno una
    /// formazione armata, perché senza la campagna si concluderebbe all'istante (RDA-164).
    public var possonoCondurreCampagna: Bool {
        switch self {
        case .sciami(let formazioni): return formazioni.contains { $0.categoria.eArmata }
        }
    }

    /// Le forze dopo che i lavori militari pronti hanno prodotto il proprio effetto (01 §4.12).
    /// Nella modalità a sciami le reclute di un inverno formano UNA formazione armata nuova, con un
    /// reparto per leva, che in primavera raggiunge il quartier generale come gruppo a sé (01 §5.2.1,
    /// §5.17.1): riunirla a un altro gruppo o tenerla distinta è una scelta che il giocatore compie
    /// sulla mappa, con le azioni che già esistono (01 §5.6.0.2, §5.6.0.3).
    public func ricevendo(_ effetti: [EffettoMilitare]) -> ForzeDelRegno {
        guard !effetti.isEmpty else { return self }
        switch self {
        case .sciami(var formazioni):
            var reclute: [Reparto] = []
            for effetto in effetti {
                switch effetto {
                case .reclutaReparto(let archetipo, let atomi):
                    reclute.append(Reparto(archetipo: archetipo, atomi: atomi))
                }
            }
            if !reclute.isEmpty {
                formazioni.append(FormazioneDelRegno(categoria: .armato, composizione: reclute))
            }
            return .sciami(formazioni)
        }
    }

    /// Le forze iniziali dichiarate dai valori, tradotte e verificate come i gruppi di uno scenario.
    public static func iniziali(_ dichiarate: [FormazioneIniziale]) throws -> ForzeDelRegno {
        var formazioni: [FormazioneDelRegno] = []
        for dichiarata in dichiarate {
            let categoria: CategoriaFormazione
            switch dichiarata.categoria {
            case "armato":
                guard dichiarata.competenza == nil, dichiarata.carico == nil,
                      dichiarata.sogliaProtezione == nil else { throw ErroreForze.formazioneIncoerente }
                categoria = .armato
            case "ricognizione":
                guard let competenza = dichiarata.competenza, competenza >= 0, dichiarata.carico == nil,
                      dichiarata.sogliaProtezione == nil else { throw ErroreForze.formazioneIncoerente }
                categoria = .ricognizione(competenza: competenza)
            case "non_armata":
                guard let carico = dichiarata.carico, carico >= 0,
                      let soglia = dichiarata.sogliaProtezione, soglia >= 0,
                      dichiarata.competenza == nil else { throw ErroreForze.formazioneIncoerente }
                categoria = .nonArmata(carico: carico, sogliaProtezione: soglia)
            default:
                throw ErroreForze.formazioneIncoerente
            }
            guard !dichiarata.composizione.isEmpty,
                  dichiarata.composizione.allSatisfy({ $0.atomi >= 1 }) else {
                throw ErroreForze.formazioneIncoerente
            }
            formazioni.append(FormazioneDelRegno(
                categoria: categoria,
                composizione: dichiarata.composizione.map { Reparto(archetipo: $0.archetipo, atomi: $0.atomi) }))
        }
        return .sciami(formazioni)
    }

    public enum ErroreForze: Error, Equatable {
        /// Una formazione iniziale con una categoria ignota, dati di un'altra categoria, o vuota.
        case formazioneIncoerente
    }
}
