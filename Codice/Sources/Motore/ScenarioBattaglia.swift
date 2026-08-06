import Foundation
import Dati

/// La definizione dichiarativa di uno scontro: da qui nasce lo stato iniziale.
/// È anche la forma degli scenari del programma di verifica (05 §12.2, 03 §9.6).
public struct ScenarioBattaglia: Hashable, Codable, Sendable {
    public struct ElementoScenario: Hashable, Codable, Sendable {
        public let archetipo: IdentificatoreDati
        public let protezione: TipoProtezione
        public let atomi: Int64
        public let esemplari: Int
        public init(archetipo: IdentificatoreDati, protezione: TipoProtezione, atomi: Int64, esemplari: Int) {
            self.archetipo = archetipo; self.protezione = protezione
            self.atomi = atomi; self.esemplari = esemplari
        }
    }

    public let formato: IdentificatoreDati
    public let caratteristica: IdentificatoreDati
    public let ostacoli: [Cella]
    /// Chi occupava per primo la casella e agisce per primo (01 §9.4.1).
    public let primoOccupante: Parte
    /// Se presente, la battaglia nasce da un'imboscata tesa dal primo occupante (01 §9.3.2).
    public let imboscata: Bool
    public let deckGiocatore: [ElementoScenario]
    public let deckAvversario: [ElementoScenario]
    /// L'ufficiale che comanda la parte avversaria (01 §14.3). Facoltativo per
    /// compatibilità con i salvataggi anteriori: assente, vale il primo dei dati.
    public let ufficialeAvversario: IdentificatoreDati?
    /// La fase storica in cui la battaglia si combatte (01 §2.3, §2.4; incarico 11):
    /// determina quale archetipo sia l'élite senza soglia. Facoltativa per compatibilità
    /// con i salvataggi anteriori: assente, la fabbrica assume la fase antica.
    public let fase: Fase?

    public init(formato: IdentificatoreDati, caratteristica: IdentificatoreDati,
                ostacoli: [Cella] = [], primoOccupante: Parte, imboscata: Bool,
                deckGiocatore: [ElementoScenario], deckAvversario: [ElementoScenario],
                ufficialeAvversario: IdentificatoreDati? = nil, fase: Fase? = nil) {
        self.formato = formato; self.caratteristica = caratteristica
        self.ostacoli = ostacoli; self.primoOccupante = primoOccupante
        self.imboscata = imboscata
        self.deckGiocatore = deckGiocatore; self.deckAvversario = deckAvversario
        self.ufficialeAvversario = ufficialeAvversario
        self.fase = fase
    }
}

/// La fabbrica dello stato iniziale di battaglia: funzione pura dei valori e dello scenario,
/// senza alcuna estrazione del caso (05 §2.10, RDA-43).
public enum FabbricaBattaglia {
    public enum ErroreScenario: Error, Equatable {
        case formatoIgnoto(IdentificatoreDati)
        case caratteristicaIgnota(IdentificatoreDati)
        case archetipoIgnoto(IdentificatoreDati)
        case ostacoloFuoriGriglia(Cella)
    }

    /// Crea lo stato iniziale e gli eventi di apertura del primo turno.
    public static func crea(scenario: ScenarioBattaglia,
                            valori: ValoriDiGioco) throws -> (StatoBattaglia, [EventoBattaglia]) {
        guard let f = valori.formati[scenario.formato] else {
            throw ErroreScenario.formatoIgnoto(scenario.formato)
        }
        guard valori.caratteristiche[scenario.caratteristica] != nil else {
            throw ErroreScenario.caratteristicaIgnota(scenario.caratteristica)
        }
        let griglia = Griglia(righe: f.righe, colonne: f.colonne)
        for cella in scenario.ostacoli where !griglia.contiene(cella) {
            throw ErroreScenario.ostacoloFuoriGriglia(cella)
        }

        func elementi(_ e: [ScenarioBattaglia.ElementoScenario]) throws -> [ElementoDeck] {
            try e.map { voce in
                guard valori.archetipi[voce.archetipo] != nil else {
                    throw ErroreScenario.archetipoIgnoto(voce.archetipo)
                }
                return ElementoDeck(archetipo: voce.archetipo, protezione: voce.protezione,
                                    atomi: voce.atomi, esemplari: voce.esemplari)
            }
        }
        let deckG = try elementi(scenario.deckGiocatore)
        let deckA = try elementi(scenario.deckAvversario)

        var stato = StatoBattaglia(
            formato: scenario.formato,
            griglia: griglia,
            caratteristica: scenario.caratteristica,
            ostacoli: Set(scenario.ostacoli),
            primoOccupante: scenario.primoOccupante,
            fase: scenario.fase ?? .antica, // fase assente: la fabbrica assume l'antica (incarico 11)
            sciami: [:],
            deck: [.giocatore: deckG, .avversario: deckA],
            prossimoIdSciame: 1,
            prossimaLettera: [.giocatore: 1, .avversario: 1],
            selezione: [:],
            parteDiTurno: scenario.primoOccupante,
            giro: 1,
            turniGiocati: [:],
            bilancio: [:],
            sorpresa: scenario.imboscata
                ? .vantaggio(restanti: f.turniVantaggioImboscante)
                : .trasparente,
            contatti: [],
            coppieStaccate: [],
            divietoIngaggio: [:],
            resaDichiarataDa: nil,
            evacuati: [:],
            perditeSubite: [:],
            forzeImpegnate: [:], // cresce a ogni discesa in campo (01 §10.2)
            esito: nil
        )
        let motore = MotoreBattaglia(valori: valori)
        let eventi = motore.apriPrimoTurno(&stato)
        return (stato, eventi)
    }
}
