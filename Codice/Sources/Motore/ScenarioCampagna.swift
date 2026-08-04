import Foundation
import Dati

/// La definizione dichiarativa di una campagna: da qui nasce lo stato iniziale.
/// È anche la forma degli scenari di campagna del programma di verifica (05 §12.2).
public struct ScenarioCampagna: Hashable, Codable, Sendable {
    public struct GruppoIniziale: Hashable, Codable, Sendable {
        public let riga: Int
        public let colonna: Int
        public init(riga: Int, colonna: Int) { self.riga = riga; self.colonna = colonna }
        public var casella: Cella { Cella(riga: riga, colonna: colonna) }
    }

    public let mappa: IdentificatoreDati
    /// I gruppi propri, in numero libero (01 §5.6.0.1): non esiste alcun tetto.
    public let gruppiGiocatore: [GruppoIniziale]

    public init(mappa: IdentificatoreDati, gruppiGiocatore: [GruppoIniziale]) {
        self.mappa = mappa
        self.gruppiGiocatore = gruppiGiocatore
    }

    enum CodingKeys: String, CodingKey {
        case mappa
        case gruppiGiocatore = "gruppi_giocatore"
    }
}

/// La fabbrica dello stato iniziale di campagna: funzione pura dei valori e dello
/// scenario, senza alcuna estrazione del caso (05 §2.10, RDA-43).
public enum FabbricaCampagna {
    public enum ErroreScenario: Error, Equatable {
        case mappaIgnota(IdentificatoreDati)
        case formatoIgnoto(IdentificatoreDati)
        case gruppoFuoriMappa(Cella)
        case gruppiSovrapposti(Cella)
        case nomiInsufficienti(richiesti: Int, disponibili: Int)
        case nessunGruppo
    }

    public static func crea(scenario: ScenarioCampagna,
                            valori: ValoriCampagna) throws -> StatoCampagna {
        guard let definizione = valori.mappe[scenario.mappa] else {
            throw ErroreScenario.mappaIgnota(scenario.mappa)
        }
        guard let formato = valori.formatiMappa[definizione.formato] else {
            throw ErroreScenario.formatoIgnoto(definizione.formato)
        }
        let mappa = MappaCampagna(definizione: definizione, formato: formato)

        // Senza gruppi la giornata non si chiuderebbe mai: la chiusura automatica
        // di 01 §5.6.0.6 presuppone che qualcuno debba agire.
        guard !scenario.gruppiGiocatore.isEmpty else { throw ErroreScenario.nessunGruppo }
        guard scenario.gruppiGiocatore.count <= valori.nomiGruppi.count else {
            throw ErroreScenario.nomiInsufficienti(richiesti: scenario.gruppiGiocatore.count,
                                                   disponibili: valori.nomiGruppi.count)
        }

        var gruppi: [IdGruppo: Gruppo] = [:]
        var occupate = Set<Cella>()
        var prossimoId = 1
        var prossimoNome = 0
        for iniziale in scenario.gruppiGiocatore {
            let casella = iniziale.casella
            guard mappa.griglia.contiene(casella) else {
                throw ErroreScenario.gruppoFuoriMappa(casella)
            }
            guard occupate.insert(casella).inserted else {
                throw ErroreScenario.gruppiSovrapposti(casella)
            }
            let id = IdGruppo(prossimoId)
            gruppi[id] = Gruppo(id: id, parte: .giocatore, indiceNome: prossimoNome,
                                posizione: casella, azioneSpesa: false)
            prossimoId += 1
            prossimoNome += 1
        }

        // Il primo giorno si apre come ogni altro, e la sua apertura è il primo
        // fatto del registro (01 §5.17.1): senza, il registro nascerebbe muto e
        // la prima giornata sarebbe l'unica non annotata.
        var stato = StatoCampagna(mappa: mappa, giorno: 1, gruppi: gruppi,
                                  prossimoIdGruppo: prossimoId,
                                  prossimoIndiceNome: prossimoNome,
                                  registro: [], prossimoNumeroVoce: 0)
        stato.registro.append(VoceRegistro(numero: 0, giorno: 1,
                                           fatto: .giornataAperta, luogo: nil))
        stato.prossimoNumeroVoce = 1
        return stato
    }
}
