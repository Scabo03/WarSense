import Foundation
import Dati
import Motore

/// Il banco degli scontri: gioca battaglie intere sugli stessi binari del gioco.
/// Nessuna regola vive qui — comandi del Motore, tattico del Motore, esiti del
/// Motore — perché una copia semplificata delle regole misurerebbe sé stessa.
public struct BancoScontri: Sendable {

    /// Una configurazione dello scenario: un punto del prodotto degli assi.
    public struct Configurazione: Hashable, Sendable {
        public let primoOccupante: Parte
        public let ufficialeGiocatore: IdentificatoreDati
        public let ufficialeAvversario: IdentificatoreDati
        public let vantaggiAccesi: Bool
        public let imboscata: Bool
    }

    /// L'esito di una corsa. Le battaglie non hanno alcuna estrazione del caso
    /// (01 §12.1): a parità di valori e configurazione la riga si ripete identica,
    /// e la configurazione è quindi ciò che il seme è altrove.
    public struct Corsa: Sendable {
        public let scenario: IdentificatoreDati
        public let configurazione: Configurazione
        public let concluso: Bool
        public let sconfitto: Parte?
        public let modo: EsitoBattaglia.Modo?
        public let giri: Int
        public let comandi: Int
        public let perdite: [Parte: Int64]
        public let impegnate: [Parte: Int64]
    }

    let motore: MotoreBattaglia
    let scenario: ScenarioDiVerifica

    public init(motore: MotoreBattaglia, scenario: ScenarioDiVerifica) {
        self.motore = motore
        self.scenario = scenario
    }

    /// Le configurazioni dello scenario: il prodotto degli assi dichiarati, in
    /// ordine deterministico. Un asse assente lascia il proprio valore di base.
    public static func configurazioni(di scenario: ScenarioDiVerifica,
                                      ufficiali: [IdentificatoreDati]) -> [Configurazione] {
        let assi = Set(scenario.assi)
        let occupanti: [Parte] = assi.contains(.primoOccupante) ? [.giocatore, .avversario] : [.giocatore]
        let elenco = ufficiali.sorted()
        let coppie: [(IdentificatoreDati, IdentificatoreDati)] = assi.contains(.ufficiali)
            ? elenco.flatMap { g in elenco.map { a in (g, a) } }
            : [(elenco[0], elenco[0])]
        let vantaggi: [Bool] = assi.contains(.vantaggiNascosti) ? [true, false] : [true]
        let imboscate: [Bool] = assi.contains(.imboscata) ? [false, true] : [false]
        var esito: [Configurazione] = []
        for occupante in occupanti {
            for coppia in coppie {
                for accesi in vantaggi {
                    for imboscata in imboscate {
                        esito.append(Configurazione(primoOccupante: occupante,
                                                    ufficialeGiocatore: coppia.0,
                                                    ufficialeAvversario: coppia.1,
                                                    vantaggiAccesi: accesi,
                                                    imboscata: imboscata))
                    }
                }
            }
        }
        return esito
    }

    /// Gioca una configurazione fino alla conclusione o al tetto dei giri.
    /// Entrambe le parti sono guidate dal medesimo tattico del Motore: la condotta
    /// è quindi pari per costruzione, e ogni sbilanciamento che resta è strutturale.
    public func gioca(_ configurazione: Configurazione) throws -> Corsa {
        let scenarioBattaglia = ScenarioBattaglia(
            formato: scenario.formato, caratteristica: scenario.caratteristica,
            ostacoli: scenario.ostacoli, primoOccupante: configurazione.primoOccupante,
            imboscata: configurazione.imboscata,
            deckGiocatore: scenario.deckGiocatore, deckAvversario: scenario.deckAvversario,
            ufficialeAvversario: configurazione.ufficialeAvversario)
        var stato = try FabbricaBattaglia.crea(scenario: scenarioBattaglia, valori: motore.valori).0

        guard let ufficialeG = motore.valori.ufficiali[configurazione.ufficialeGiocatore],
              let ufficialeA = motore.valori.ufficiali[configurazione.ufficialeAvversario] else {
            throw ErroreDati(chiave: "errore.dati.elenco_vuoto", file: "ufficiali.json")
        }
        let tattici: [Parte: TatticoBattaglia] = [
            .giocatore: TatticoBattaglia(motore: motore, ufficiale: ufficialeG, parte: .giocatore),
            .avversario: TatticoBattaglia(motore: motore, ufficiale: ufficialeA, parte: .avversario),
        ]

        var comandi = 0
        // Il tetto sui comandi è una rete: un turno produce al più un comando per
        // reparto più la fine, quindi il tetto vero è quello sui giri.
        let tettoComandi = scenario.giriMassimi * 200
        while stato.esito == nil && stato.giro <= scenario.giriMassimi && comandi < tettoComandi {
            let parte = stato.parteDiTurno
            let comando = tattici[parte]!.prossimoComando(stato: stato)
            stato = motore.applica(comando, parte: parte, stato: stato).0
            comandi += 1
        }
        return Corsa(scenario: scenario.identificatore, configurazione: configurazione,
                     concluso: stato.esito != nil,
                     sconfitto: stato.esito?.sconfitto, modo: stato.esito?.modo,
                     giri: stato.giro, comandi: comandi,
                     perdite: stato.perditeSubite, impegnate: stato.forzeImpegnate)
    }
}
