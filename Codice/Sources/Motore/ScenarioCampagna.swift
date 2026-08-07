import Foundation
import Dati

/// La definizione dichiarativa di una campagna: da qui nasce lo stato iniziale.
/// È anche la forma degli scenari di campagna del programma di verifica (05 §12.2).
public struct ScenarioCampagna: Hashable, Codable, Sendable {
    /// Un reparto iniziale di un gruppo, come compare nei dati: archetipo e atomi
    /// (01 §5.6.0). La fabbrica lo traduce in `Reparto` dopo averne verificato
    /// l'archetipo e il numero di atomi.
    public struct RepartoIniziale: Hashable, Codable, Sendable {
        public let archetipo: IdentificatoreDati
        public let atomi: Int
        public init(archetipo: IdentificatoreDati, atomi: Int) {
            self.archetipo = archetipo; self.atomi = atomi
        }
    }

    public struct GruppoIniziale: Hashable, Codable, Sendable {
        public let riga: Int
        public let colonna: Int
        /// La composizione del gruppo (01 §5.6.0): mai vuota. La fabbrica respinge
        /// lo scenario che ne dichiari una vuota o con reparti a zero atomi.
        public let composizione: [RepartoIniziale]
        public init(riga: Int, colonna: Int, composizione: [RepartoIniziale]) {
            self.riga = riga; self.colonna = colonna; self.composizione = composizione
        }
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
        /// Un gruppo con composizione vuota: nessun gruppo può esistere senza reparti
        /// (01 §5.6.0.2, invariante `gruppoVuoto`). Reso impossibile qui, non solo
        /// sorvegliato.
        case gruppoSenzaComposizione(Cella)
        /// Un reparto con atomi non positivi: un reparto senza atomi non esiste, e la
        /// somma dei volumi non tornerebbe (01 §5.6.0).
        case repartoVuoto(Cella)
        /// Un archetipo ignoto nella composizione: come il terreno ignoto respinto in
        /// caricamento (05 §7.7), il volume non si potrebbe leggere.
        case archetipoIgnoto(IdentificatoreDati)
    }

    /// - Parameter archetipiNoti: le chiavi degli archetipi caricati e validi
    ///   (`ValoriDiGioco.archetipi`). La composizione di ogni gruppo vi si verifica,
    ///   come lo scenario di battaglia verifica i propri sciami (`ScenarioBattaglia`).
    public static func crea(scenario: ScenarioCampagna,
                            valori: ValoriCampagna,
                            archetipiNoti: Set<IdentificatoreDati>) throws -> StatoCampagna {
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
            // La composizione: mai vuota, reparti a atomi positivi, archetipi noti.
            // I tre rifiuti rendono impossibile — non solo sorvegliabile — il gruppo
            // vuoto e il volume che non torna (01 §5.6.0.2).
            guard !iniziale.composizione.isEmpty else {
                throw ErroreScenario.gruppoSenzaComposizione(casella)
            }
            var composizione: [Reparto] = []
            for reparto in iniziale.composizione {
                guard reparto.atomi > 0 else { throw ErroreScenario.repartoVuoto(casella) }
                guard archetipiNoti.contains(reparto.archetipo) else {
                    throw ErroreScenario.archetipoIgnoto(reparto.archetipo)
                }
                composizione.append(Reparto(archetipo: reparto.archetipo, atomi: reparto.atomi))
            }
            let id = IdGruppo(prossimoId)
            gruppi[id] = Gruppo(id: id, parte: .giocatore, nome: valori.nomiGruppi[prossimoNome],
                                posizione: casella, composizione: composizione, azioneSpesa: false)
            prossimoId += 1
            prossimoNome += 1
        }

        // Il registro nasce vuoto e la schermata lo dichiara: l'apertura di una
        // giornata non è un fatto da annotare, perché il giorno è una proprietà di
        // ciascuna voce (02 §6.6) e un elemento che dichiarasse soltanto l'inizio
        // di una giornata occuperebbe una posizione senza portare informazione.
        return StatoCampagna(mappa: mappa, giorno: 1, gruppi: gruppi,
                             prossimoIdGruppo: prossimoId,
                             prossimoIndiceNome: prossimoNome,
                             registro: [], prossimoNumeroVoce: 0)
    }
}
