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
        /// La categoria dichiarata (01 §5.2): «armato» (per difetto e omesso dalla
        /// codifica, sicché gli scenari precedenti restano identici al byte), «ricognizione»
        /// o «non_armata». La fabbrica la traduce in `CategoriaFormazione` verificando che i
        /// dati che la categoria richiede — competenza per la ricognizione, carico e soglia
        /// per la non armata — siano presenti e coerenti.
        public let categoria: String
        /// La competenza dell'esploratore (01 §5.4.2), richiesta se e solo se
        /// categoria = «ricognizione».
        public let competenza: Int?
        /// Il carico della formazione non armata (01 §5.10.2), richiesto se e solo se
        /// categoria = «non_armata».
        public let carico: Int?
        /// La soglia di protezione della formazione non armata (01 §5.10.2), richiesta se e
        /// solo se categoria = «non_armata».
        public let sogliaProtezione: Int?

        public init(riga: Int, colonna: Int, composizione: [RepartoIniziale],
                    categoria: String = "armato", competenza: Int? = nil,
                    carico: Int? = nil, sogliaProtezione: Int? = nil) {
            self.riga = riga; self.colonna = colonna; self.composizione = composizione
            self.categoria = categoria; self.competenza = competenza
            self.carico = carico; self.sogliaProtezione = sogliaProtezione
        }
        public var casella: Cella { Cella(riga: riga, colonna: colonna) }

        enum CodingKeys: String, CodingKey {
            case riga, colonna, composizione, categoria, competenza, carico
            case sogliaProtezione = "soglia_protezione"
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            riga = try c.decode(Int.self, forKey: .riga)
            colonna = try c.decode(Int.self, forKey: .colonna)
            composizione = try c.decode([RepartoIniziale].self, forKey: .composizione)
            // Assente negli scenari precedenti a questa unità: si legge «armato» e nulla cambia.
            categoria = try c.decodeIfPresent(String.self, forKey: .categoria) ?? "armato"
            competenza = try c.decodeIfPresent(Int.self, forKey: .competenza)
            carico = try c.decodeIfPresent(Int.self, forKey: .carico)
            sogliaProtezione = try c.decodeIfPresent(Int.self, forKey: .sogliaProtezione)
        }

        public func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(riga, forKey: .riga)
            try c.encode(colonna, forKey: .colonna)
            try c.encode(composizione, forKey: .composizione)
            // La categoria ordinaria e i campi assenti si OMETTONO: uno scenario armato — cioè
            // tutti quelli scritti prima di questa unità — si ricodifica identico al byte, e i
            // campioni del giornale non si muovono (RDA-113, `CompatibilitaGiornaleTest`).
            if categoria != "armato" { try c.encode(categoria, forKey: .categoria) }
            try c.encodeIfPresent(competenza, forKey: .competenza)
            try c.encodeIfPresent(carico, forKey: .carico)
            try c.encodeIfPresent(sogliaProtezione, forKey: .sogliaProtezione)
        }
    }

    public let mappa: IdentificatoreDati
    /// I gruppi propri, in numero libero (01 §5.6.0.1): non esiste alcun tetto.
    public let gruppiGiocatore: [GruppoIniziale]
    /// I gruppi dell'AVVERSARIO (01 §5.6.11, incarico 18): stessa forma di quelli del
    /// giocatore, ma di parte avversaria. Muovono con la condotta deterministica dopo
    /// che il giocatore ha agito. Quando l'elenco è vuoto la codifica lo OMETTE, così
    /// che gli scenari e i salvataggi che non li usano — tutti quelli scritti prima di
    /// questa unità — restino identici al byte e i campioni del giornale non si muovano
    /// (00 §15, RDA-66, RDA-113). Uno scenario senza gruppi avversari si comporta come
    /// prima: nessuno si muove dopo il giocatore.
    public let gruppiAvversario: [GruppoIniziale]
    /// Le forze nemiche FERME che lo scenario dichiara (01 §5.2.2): dati MINIMI per
    /// provare il taglio senza condotta, non l'avversario (incarico 16). Restano per gli
    /// scenari di verifica che esercitano il taglio con un nemico immobile; le campagne
    /// giocabili ora dichiarano invece `gruppiAvversario`. Omesse dalla codifica se vuote.
    public let forzeNemiche: [Cella]
    /// Le strutture di rifornimento FERME (01 §5.2.2.6): stessa natura dei dati minimi,
    /// per provare la zona, mai le opere. Anch'esse omesse dalla codifica se vuote.
    public let struttureDiRifornimento: [Cella]

    public init(mappa: IdentificatoreDati, gruppiGiocatore: [GruppoIniziale],
                gruppiAvversario: [GruppoIniziale] = [],
                forzeNemiche: [Cella] = [], struttureDiRifornimento: [Cella] = []) {
        self.mappa = mappa
        self.gruppiGiocatore = gruppiGiocatore
        self.gruppiAvversario = gruppiAvversario
        self.forzeNemiche = forzeNemiche
        self.struttureDiRifornimento = struttureDiRifornimento
    }

    enum CodingKeys: String, CodingKey {
        case mappa
        case gruppiGiocatore = "gruppi_giocatore"
        case gruppiAvversario = "gruppi_avversario"
        case forzeNemiche = "forze_nemiche"
        case struttureDiRifornimento = "strutture_di_rifornimento"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mappa = try c.decode(IdentificatoreDati.self, forKey: .mappa)
        gruppiGiocatore = try c.decode([GruppoIniziale].self, forKey: .gruppiGiocatore)
        // Assenti nei dati precedenti a questa unità: si leggono vuote e nulla cambia.
        gruppiAvversario = try c.decodeIfPresent([GruppoIniziale].self, forKey: .gruppiAvversario) ?? []
        forzeNemiche = try c.decodeIfPresent([Cella].self, forKey: .forzeNemiche) ?? []
        struttureDiRifornimento = try c.decodeIfPresent([Cella].self, forKey: .struttureDiRifornimento) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(mappa, forKey: .mappa)
        try c.encode(gruppiGiocatore, forKey: .gruppiGiocatore)
        // Omessi quando vuoti: la compatibilità dei giornali esige che ciò che non li
        // usa non cambi di un byte (il campione del giornale resta identico).
        if !gruppiAvversario.isEmpty { try c.encode(gruppiAvversario, forKey: .gruppiAvversario) }
        if !forzeNemiche.isEmpty { try c.encode(forzeNemiche, forKey: .forzeNemiche) }
        if !struttureDiRifornimento.isEmpty {
            try c.encode(struttureDiRifornimento, forKey: .struttureDiRifornimento)
        }
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
        /// Una forza nemica o una struttura FUORI dalla mappa: come i gruppi, i dati
        /// minimi del rifornimento devono stare dentro la griglia (01 §5.2.2).
        case rifornimentoFuoriMappa(Cella)
        /// Una categoria di formazione ignota: l'insieme è chiuso a tre (01 §5.2), e una
        /// stringa che non sia «armato», «ricognizione» o «non_armata» è respinta come un
        /// terreno ignoto (05 §7.7).
        case categoriaIgnota(String)
        /// I dati della categoria sono incoerenti (01 §5.2, §5.4.2, §5.10.2): un esploratore
        /// senza competenza o con un carico, una formazione non armata senza carico o senza
        /// soglia o con una competenza, un gruppo armato con dati da altra categoria. Lo
        /// stato impossibile è respinto qui, non solo sorvegliato.
        case datiCategoriaIncoerenti(Cella)
    }

    /// Traduce i campi dichiarativi della categoria (01 §5.2) nel tipo con valore
    /// associato, respingendo ogni combinazione incoerente: la competenza è richiesta se e
    /// solo se «ricognizione», il carico e la soglia se e solo se «non_armata», e nessuna
    /// categoria tollera i dati di un'altra.
    static func categoria(di iniziale: ScenarioCampagna.GruppoIniziale) throws -> CategoriaFormazione {
        switch iniziale.categoria {
        case "armato":
            guard iniziale.competenza == nil, iniziale.carico == nil,
                  iniziale.sogliaProtezione == nil else {
                throw ErroreScenario.datiCategoriaIncoerenti(iniziale.casella)
            }
            return .armato
        case "ricognizione":
            guard let competenza = iniziale.competenza, competenza >= 0,
                  iniziale.carico == nil, iniziale.sogliaProtezione == nil else {
                throw ErroreScenario.datiCategoriaIncoerenti(iniziale.casella)
            }
            return .ricognizione(competenza: competenza)
        case "non_armata":
            guard let carico = iniziale.carico, carico >= 0,
                  let soglia = iniziale.sogliaProtezione, soglia >= 0,
                  iniziale.competenza == nil else {
                throw ErroreScenario.datiCategoriaIncoerenti(iniziale.casella)
            }
            return .nonArmata(carico: carico, sogliaProtezione: soglia)
        default:
            throw ErroreScenario.categoriaIgnota(iniziale.categoria)
        }
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

        // Senza gruppi del giocatore la giornata non si chiuderebbe mai: la chiusura
        // automatica di 01 §5.6.0.6 presuppone che qualcuno debba agire. I gruppi
        // avversari possono mancare (scenario senza condotta): allora nessuno si muove
        // dopo il giocatore, e la campagna resta quella di prima dell'avversario.
        guard !scenario.gruppiGiocatore.isEmpty else { throw ErroreScenario.nessunGruppo }
        let richiestiNomi = scenario.gruppiGiocatore.count + scenario.gruppiAvversario.count
        guard richiestiNomi <= valori.nomiGruppi.count else {
            throw ErroreScenario.nomiInsufficienti(richiesti: richiestiNomi,
                                                   disponibili: valori.nomiGruppi.count)
        }

        var gruppi: [IdGruppo: Gruppo] = [:]
        // Le caselle occupate si tengono PER PARTE: la compresenza di un gruppo del
        // giocatore e di uno avversario nella stessa casella è ammessa (01 §6.1), ma due
        // gruppi della STESSA parte non possono nascere sovrapposti (01 §5.6.0.2).
        var occupate: [Parte: Set<Cella>] = [.giocatore: [], .avversario: []]
        var prossimoId = 1
        var prossimoNome = 0

        // Le due parti nascono con lo STESSO percorso — stessi rifiuti, stessa
        // derivazione del volume, nomi dalla medesima lista chiusa (i nomi non si
        // riusano fra le parti, 01 §5.6.0.4) — così che nessuna regola di nascita valga
        // per una parte sola (incarico 18). Il giocatore per primo, l'avversario dopo:
        // gli identificatori del giocatore restano i più bassi, il che fissa anche
        // l'ordine deterministico delle risoluzioni.
        func creaGruppi(_ iniziali: [ScenarioCampagna.GruppoIniziale], parte: Parte) throws {
            for iniziale in iniziali {
                let casella = iniziale.casella
                guard mappa.griglia.contiene(casella) else {
                    throw ErroreScenario.gruppoFuoriMappa(casella)
                }
                guard occupate[parte]!.insert(casella).inserted else {
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
                gruppi[id] = Gruppo(id: id, parte: parte, nome: valori.nomiGruppi[prossimoNome],
                                    posizione: casella, composizione: composizione,
                                    categoria: try categoria(di: iniziale), azioneSpesa: false)
                prossimoId += 1
                prossimoNome += 1
            }
        }
        try creaGruppi(scenario.gruppiGiocatore, parte: .giocatore)
        try creaGruppi(scenario.gruppiAvversario, parte: .avversario)

        // Le forze nemiche e le strutture: dati minimi per provare taglio e zona, che
        // devono comunque stare dentro la griglia. Nessun'altra regola le governa —
        // non hanno condotta, non si muovono, non sono opere (incarico 16).
        for cella in scenario.forzeNemiche + scenario.struttureDiRifornimento {
            guard mappa.griglia.contiene(cella) else {
                throw ErroreScenario.rifornimentoFuoriMappa(cella)
            }
        }

        // Il registro nasce vuoto e la schermata lo dichiara: l'apertura di una
        // giornata non è un fatto da annotare, perché il giorno è una proprietà di
        // ciascuna voce (02 §6.6) e un elemento che dichiarasse soltanto l'inizio
        // di una giornata occuperebbe una posizione senza portare informazione.
        return StatoCampagna(mappa: mappa, giorno: 1, gruppi: gruppi,
                             prossimoIdGruppo: prossimoId,
                             prossimoIndiceNome: prossimoNome,
                             registro: [], prossimoNumeroVoce: 0,
                             forzeNemiche: Set(scenario.forzeNemiche),
                             struttureDiRifornimento: Set(scenario.struttureDiRifornimento))
    }
}
