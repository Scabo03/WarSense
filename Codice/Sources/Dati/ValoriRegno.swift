import Foundation

// I tipi dei valori del regno (01 §5.5, §5.9; 03 §4.4; 05 §7.5). Il regno è identico nelle due
// modalità di battaglia (01 §1.2): calendario, risorse, bilancio e voci stanno qui senza alcun
// riferimento alla modalità, e la sola parte che ne dipende è il gancio d'effetto di una voce
// militare (`EffettoMilitare`, 05 §7.7). Nessun numero vive nel codice (00 §13.1).

/// Le cinque risorse del bilancio (01 §5.5.1): distinte, nessuna si sovrappone a un'altra. L'ordine
/// dei casi è l'ordine fisso in cui si annunciano (02 §8.7): denaro, uomini, metalli, materiale da
/// costruzione, animali da sella e da tiro. Cibo e derrate non vi figurano (01 §5.5.1.1).
public enum Risorsa: String, Codable, Hashable, Sendable, CaseIterable {
    case denaro, uomini, metalli, materiale, animali
}

/// Le stagioni (01 §5.9, 02 §4.4.5): tre operative e l'inverno, in cui non si conduce campagna.
public enum Stagione: String, Codable, Hashable, Sendable, CaseIterable {
    case primavera, estate, autunno, inverno

    /// Le stagioni in cui si conduce campagna, nell'ordine dell'anno. Numero di struttura, non di
    /// gioco (05 §0.4): è l'insieme chiuso del vocabolario meno l'inverno.
    public static let operative: [Stagione] = [.primavera, .estate, .autunno]

    /// La chiave del termine chiuso della stagione (02 §4.4.5).
    public var chiaveTesto: String { "stagione." + rawValue }
}

/// L'insieme CHIUSO dei ganci d'effetto delle voci militari del regno (05 §7.7): un file non può
/// introdurre un effetto che il Motore non conosce, e il caricamento respinge i ganci ignoti. È la
/// sola parte del regno che dipende dalla modalità di battaglia (01 §1.2; documento della modalità a
/// campioni, 1.3): questa versione conosce il gancio della modalità a sciami; quelli della modalità
/// a campioni — reclutare un combattente, migliorare la persona o l'istituzione — si aggiungeranno
/// qui come casi nuovi, senza toccare calendario, bilancio e voci.
public enum EffettoMilitare: Hashable, Codable, Sendable {
    /// Modalità a sciami: recluta un reparto di `atomi` atomi dell'archetipo (01 §4.12).
    case reclutaReparto(archetipo: IdentificatoreDati, atomi: Int)

    /// La misura cui si applica il costo di base: quante unità di ciò che la voce dà (per la leva,
    /// gli atomi del reparto). La formula del costo è una sola e vive nel Motore (00 §13.3).
    public var misura: Int {
        switch self {
        case .reclutaReparto(_, let atomi): return atomi
        }
    }

    /// Il nome del gancio nei file dei valori.
    public var gancio: String {
        switch self {
        case .reclutaReparto: return "recluta_reparto"
        }
    }

    enum CodingKeys: String, CodingKey { case gancio, archetipo, atomi }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let gancio = try c.decode(String.self, forKey: .gancio)
        switch gancio {
        case "recluta_reparto":
            self = .reclutaReparto(archetipo: try c.decode(IdentificatoreDati.self, forKey: .archetipo),
                                   atomi: try c.decode(Int.self, forKey: .atomi))
        default:
            throw DecodingError.dataCorruptedError(forKey: .gancio, in: c,
                                                   debugDescription: "gancio.ignoto")
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(gancio, forKey: .gancio)
        switch self {
        case .reclutaReparto(let archetipo, let atomi):
            try c.encode(archetipo, forKey: .archetipo)
            try c.encode(atomi, forKey: .atomi)
        }
    }
}

/// Una voce che si ordina in patria (01 §5.9.1.3, §5.9.1.5): ciò che dà, quanto pesa su ciascuna
/// risorsa rispetto alla base, e quando è pronta. I pesi sono coefficienti riferiti alla base
/// (00 §13.2): il costo è `misura × base × peso`, troncato (00 §13.5), e la voce dichiara soltanto le
/// risorse che consuma davvero (02 §8.7).
public struct VoceDelRegno: Codable, Hashable, Sendable {
    public let identificatore: IdentificatoreDati
    /// Il peso su ciascuna risorsa consumata, per nome di risorsa. Le risorse assenti non costano.
    public let pesi: [String: Scalato]
    public let effetto: EffettoMilitare

    public init(identificatore: IdentificatoreDati, pesi: [String: Scalato], effetto: EffettoMilitare) {
        self.identificatore = identificatore; self.pesi = pesi; self.effetto = effetto
    }

    /// Il peso su una risorsa: zero se la voce non la consuma.
    public func peso(su risorsa: Risorsa) -> Scalato { pesi[risorsa.rawValue] ?? .zero }
}

/// Un fronte su cui il regno può aprire la campagna dell'anno (01 §5.6.9): un identificatore, che è
/// anche la chiave del suo nome per punti di riferimento, e lo scenario che ne dà la mappa e le
/// forze avversarie.
public struct FronteDelRegno: Codable, Hashable, Sendable {
    public let identificatore: IdentificatoreDati
    public let scenario: IdentificatoreDati
    public init(identificatore: IdentificatoreDati, scenario: IdentificatoreDati) {
        self.identificatore = identificatore; self.scenario = scenario
    }
}

/// Una formazione con cui il regno comincia, nella modalità a sciami (01 §5.2): la stessa forma
/// dichiarativa dei gruppi di uno scenario, senza la casella, che la dà il fronte.
public struct FormazioneIniziale: Codable, Hashable, Sendable {
    public struct RepartoDichiarato: Codable, Hashable, Sendable {
        public let archetipo: IdentificatoreDati
        public let atomi: Int
        public init(archetipo: IdentificatoreDati, atomi: Int) {
            self.archetipo = archetipo; self.atomi = atomi
        }
    }
    /// «armato», «ricognizione» o «non_armata» (01 §5.2).
    public let categoria: String
    public let composizione: [RepartoDichiarato]
    public let competenza: Int?
    public let carico: Int?
    public let sogliaProtezione: Int?

    public init(categoria: String, composizione: [RepartoDichiarato], competenza: Int? = nil,
                carico: Int? = nil, sogliaProtezione: Int? = nil) {
        self.categoria = categoria; self.composizione = composizione
        self.competenza = competenza; self.carico = carico; self.sogliaProtezione = sogliaProtezione
    }

    enum CodingKeys: String, CodingKey {
        case categoria, composizione, competenza, carico
        case sogliaProtezione = "soglia_protezione"
    }
}

/// I valori del regno caricati e validati (`regno.json`). Tutti provvisori finché una misura o una
/// decisione del titolare non li fissa (`valori-provvisori.md`).
public struct ValoriRegno: Codable, Hashable, Sendable {
    /// Quante giornate dura ciascuna stagione operativa (01 §5.9). L'anno conta tre stagioni
    /// operative uguali e l'inverno, che non ha giornate ma quattro stazioni (01 §5.9.1.1).
    public let giornatePerStagione: Int
    /// La quota di riporto (01 §5.5.1.4, 03 §4.4.1): quanta parte dell'entrata dell'anno può avanzare.
    public let quotaRiporto: Scalato
    /// Le riserve con cui il regno comincia, per risorsa.
    public let dotazioneIniziale: [String: Int]
    /// La rendita di un anno per risorsa: il canale astratto che non si gestisce (01 §1.3.1).
    public let renditaAnnua: [String: Int]
    /// Il premio per ogni battaglia vinta, come coefficiente della rendita (01 §2.6; documento della
    /// modalità a campioni, 8.1).
    public let premioBattagliaVinta: Scalato
    /// Il premio per la campagna vinta, come coefficiente della rendita (01 §2.6).
    public let premioCampagnaVinta: Scalato
    /// La base della leva per unità di misura e per risorsa (00 §13.2): il costo di una voce è la
    /// base moltiplicata per la misura e per il peso della voce.
    public let baseLeva: [String: Int]
    /// Il minimo del costo di una voce su una risorsa che consuma (00 §13.6, 03 §8): il troncamento
    /// non deve mai produrre un costo nullo, che sarebbe un difetto sfruttabile.
    public let costoMinimo: Int
    /// Le voci che si ordinano d'inverno, nell'ordine in cui si elencano.
    public let voci: [VoceDelRegno]
    /// I fronti su cui si può aprire la campagna dell'anno, nell'ordine in cui si offrono.
    public let fronti: [FronteDelRegno]
    /// La fase storica con cui il regno comincia (01 §2.3): decide il nome della moneta (01 §5.5.1.3).
    public let faseIniziale: Fase
    /// Le formazioni con cui il regno comincia, nella modalità a sciami.
    public let forzeIniziali: [FormazioneIniziale]

    public init(giornatePerStagione: Int, quotaRiporto: Scalato, dotazioneIniziale: [String: Int],
                renditaAnnua: [String: Int], premioBattagliaVinta: Scalato, premioCampagnaVinta: Scalato,
                baseLeva: [String: Int], costoMinimo: Int, voci: [VoceDelRegno], fronti: [FronteDelRegno],
                faseIniziale: Fase, forzeIniziali: [FormazioneIniziale]) {
        self.giornatePerStagione = giornatePerStagione
        self.quotaRiporto = quotaRiporto
        self.dotazioneIniziale = dotazioneIniziale
        self.renditaAnnua = renditaAnnua
        self.premioBattagliaVinta = premioBattagliaVinta
        self.premioCampagnaVinta = premioCampagnaVinta
        self.baseLeva = baseLeva
        self.costoMinimo = costoMinimo
        self.voci = voci
        self.fronti = fronti
        self.faseIniziale = faseIniziale
        self.forzeIniziali = forzeIniziali
    }

    enum CodingKeys: String, CodingKey {
        case giornatePerStagione = "giornate_per_stagione"
        case quotaRiporto = "quota_riporto"
        case dotazioneIniziale = "dotazione_iniziale"
        case renditaAnnua = "rendita_annua"
        case premioBattagliaVinta = "premio_battaglia_vinta"
        case premioCampagnaVinta = "premio_campagna_vinta"
        case baseLeva = "base_leva"
        case costoMinimo = "costo_minimo"
        case voci, fronti
        case faseIniziale = "fase_iniziale"
        case forzeIniziali = "forze_iniziali"
    }

    /// La voce con l'identificatore dato, se esiste.
    public func voce(_ identificatore: IdentificatoreDati) -> VoceDelRegno? {
        voci.first { $0.identificatore == identificatore }
    }

    /// Il fronte con l'identificatore dato, se esiste.
    public func fronte(_ identificatore: IdentificatoreDati) -> FronteDelRegno? {
        fronti.first { $0.identificatore == identificatore }
    }

    /// L'ultima giornata operativa dell'anno: chiusa quella, arriva l'inverno (01 §5.9).
    public var giornateOperative: Int { giornatePerStagione * Stagione.operative.count }
}

/// Carica e valida i valori del regno (05 §7.8), con la disciplina degli altri caricatori: schema,
/// tipi, completezza, coerenza; un fallimento è un rapporto a chiavi di testo.
public enum CaricatoreRegno {
    public static let nomeFile = "regno.json"

    /// - Parameter archetipiNoti: le chiavi degli archetipi validi, contro cui si verificano le
    ///   voci militari e le forze iniziali.
    public static func carica(da cartella: URL, archetipiNoti: Set<IdentificatoreDati>) throws -> ValoriRegno {
        let url = cartella.appendingPathComponent(nomeFile)
        guard let dati = try? Data(contentsOf: url) else {
            throw ErroreDati(chiave: "errore.dati.file_mancante", file: nomeFile)
        }
        let valori: ValoriRegno
        do { valori = try JSONDecoder().decode(ValoriRegno.self, from: dati) }
        catch { throw ErroreDati(chiave: "errore.dati.file_malformato", file: nomeFile) }
        try valida(valori, archetipiNoti: archetipiNoti)
        return valori
    }

    static func rifiuto(_ voce: String) -> ErroreDati {
        ErroreDati(chiave: "errore.dati.regno_incoerente", file: nomeFile, voce: voce)
    }

    static func valida(_ valori: ValoriRegno, archetipiNoti: Set<IdentificatoreDati>) throws {
        let risorse = Set(Risorsa.allCases.map(\.rawValue))
        // Il calendario: almeno una giornata per stagione, o l'anno non avrebbe campagna (01 §5.9).
        guard valori.giornatePerStagione >= 1 else { throw rifiuto("giornate_per_stagione") }
        // La quota di riporto è una proporzione dell'entrata: fra zero e uno (01 §5.5.1.4).
        guard valori.quotaRiporto >= .zero, valori.quotaRiporto <= .uno else { throw rifiuto("quota_riporto") }
        // Dotazione e rendita dichiarano TUTTE e cinque le risorse, mai negative: una risorsa
        // sottintesa sarebbe un valore applicato per omissione (00 §13.1).
        for (nome, mappa) in [("dotazione_iniziale", valori.dotazioneIniziale),
                              ("rendita_annua", valori.renditaAnnua),
                              ("base_leva", valori.baseLeva)] {
            guard Set(mappa.keys) == risorse, mappa.values.allSatisfy({ $0 >= 0 }) else { throw rifiuto(nome) }
        }
        guard valori.premioBattagliaVinta >= .zero, valori.premioCampagnaVinta >= .zero else {
            throw rifiuto("premi")
        }
        // Il minimo del costo è almeno uno (00 §13.6): sotto, una voce potrebbe non costare nulla.
        guard valori.costoMinimo >= 1 else { throw rifiuto("costo_minimo") }
        // Le voci: identificatori unici; pesi su risorse note e non negativi; almeno un costo vero,
        // perché una voce gratuita sarebbe il difetto sfruttabile di 00 §13.6; effetto coerente.
        guard !valori.voci.isEmpty else { throw rifiuto("voci") }
        var visti = Set<IdentificatoreDati>()
        for voce in valori.voci {
            guard visti.insert(voce.identificatore).inserted else {
                throw ErroreDati(chiave: "errore.dati.identificatore_duplicato", file: nomeFile,
                                 voce: voce.identificatore)
            }
            guard Set(voce.pesi.keys).isSubset(of: risorse),
                  voce.pesi.values.allSatisfy({ $0 >= .zero }) else { throw rifiuto(voce.identificatore) }
            let costaQualcosa = Risorsa.allCases.contains {
                voce.peso(su: $0) > .zero && (valori.baseLeva[$0.rawValue] ?? 0) > 0
            }
            guard costaQualcosa, voce.effetto.misura >= 1 else { throw rifiuto(voce.identificatore) }
            switch voce.effetto {
            case .reclutaReparto(let archetipo, _):
                guard archetipiNoti.contains(archetipo) else { throw rifiuto(voce.identificatore) }
            }
        }
        // I fronti: almeno uno, identificatori unici.
        guard !valori.fronti.isEmpty,
              Set(valori.fronti.map(\.identificatore)).count == valori.fronti.count else {
            throw rifiuto("fronti")
        }
        // Le forze iniziali: almeno una formazione armata, o nessuna campagna potrebbe concludersi
        // altrimenti che per annientamento immediato; reparti con atomi positivi e archetipi noti.
        guard valori.forzeIniziali.contains(where: { $0.categoria == "armato" }) else {
            throw rifiuto("forze_iniziali")
        }
        for formazione in valori.forzeIniziali {
            guard !formazione.composizione.isEmpty,
                  formazione.composizione.allSatisfy({ $0.atomi >= 1 && archetipiNoti.contains($0.archetipo) })
            else { throw rifiuto("forze_iniziali") }
        }
    }
}
