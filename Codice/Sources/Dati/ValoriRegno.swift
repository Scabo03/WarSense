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

    /// Le stazioni dell'inverno: quattro, numero di struttura e non di gioco (01 §5.9.1.1, 05 §0.4).
    public static let stazioniInvernali = 4

    /// La chiave del termine chiuso della stagione (02 §4.4.5).
    public var chiaveTesto: String { "stagione." + rawValue }
}

/// L'insieme CHIUSO dei ganci d'effetto delle voci militari del regno (05 §7.7): un file non può
/// introdurre un effetto che il Motore non conosce, e il caricamento respinge i ganci ignoti. È la
/// sola parte del regno che dipende dalla modalità di battaglia (01 §1.2; documento della modalità a
/// campioni, 1.3): questa versione conosce i ganci della modalità a sciami; quelli della modalità
/// a campioni — reclutare un combattente, migliorare la persona o l'istituzione — si aggiungeranno
/// qui come casi nuovi, senza toccare calendario, bilancio e voci.
public enum EffettoMilitare: Hashable, Codable, Sendable {
    /// Modalità a sciami: recluta e addestra un reparto di `atomi` atomi dell'archetipo (01 §4.12).
    case reclutaReparto(archetipo: IdentificatoreDati, atomi: Int)
    /// Modalità a sciami: dà a un reparto ESISTENTE, scelto quando si ordina, l'addestramento
    /// mirato che ne accresce le prestazioni (01 §4.13; incarico 31).
    case miglioraReparto(miglioramento: IdentificatoreDati)
    /// Modalità a sciami: mantiene per un altro anno il miglioramento che un reparto, scelto quando
    /// si ordina, porta già; non mantenuto, il miglioramento si perde e il reparto resta (01 §4.14).
    case mantieniMiglioramento(miglioramento: IdentificatoreDati)

    /// La misura cui si applica il costo di base, quando la voce la porta con sé: per la leva, gli
    /// atomi del reparto. Nulla per le voci che agiscono su qualcosa di esistente, la cui misura è
    /// quella del bersaglio scelto. La formula del costo è una sola e vive nel Motore (00 §13.3).
    public var misuraPropria: Int? {
        switch self {
        case .reclutaReparto(_, let atomi): return atomi
        case .miglioraReparto, .mantieniMiglioramento: return nil
        }
    }

    /// Vero se la voce si ordina SU qualcosa che esiste già, da scegliere quando la si ordina.
    public var richiedeBersaglio: Bool { misuraPropria == nil }

    /// Che cosa fa l'effetto alle forze, detto senza i termini della modalità: è ciò che il regno
    /// comune ha bisogno di sapere per trattare la voce — se aggiunge forze nuove, se migliora
    /// qualcosa che esiste, se ne conserva il miglioramento.
    public enum Specie: Hashable, Sendable {
        case recluta
        case migliora(IdentificatoreDati)
        case mantiene(IdentificatoreDati)
    }

    public var specie: Specie {
        switch self {
        case .reclutaReparto: return .recluta
        case .miglioraReparto(let miglioramento): return .migliora(miglioramento)
        case .mantieniMiglioramento(let miglioramento): return .mantiene(miglioramento)
        }
    }

    /// Il nome del gancio nei file dei valori.
    public var gancio: String {
        switch self {
        case .reclutaReparto: return "recluta_reparto"
        case .miglioraReparto: return "migliora_reparto"
        case .mantieniMiglioramento: return "mantieni_miglioramento"
        }
    }

    enum CodingKeys: String, CodingKey { case gancio, archetipo, atomi, miglioramento }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let gancio = try c.decode(String.self, forKey: .gancio)
        switch gancio {
        case "recluta_reparto":
            self = .reclutaReparto(archetipo: try c.decode(IdentificatoreDati.self, forKey: .archetipo),
                                   atomi: try c.decode(Int.self, forKey: .atomi))
        case "migliora_reparto":
            self = .miglioraReparto(miglioramento: try c.decode(IdentificatoreDati.self, forKey: .miglioramento))
        case "mantieni_miglioramento":
            self = .mantieniMiglioramento(miglioramento: try c.decode(IdentificatoreDati.self, forKey: .miglioramento))
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
        case .miglioraReparto(let miglioramento), .mantieniMiglioramento(let miglioramento):
            try c.encode(miglioramento, forKey: .miglioramento)
        }
    }
}

/// Una voce che si ordina in patria (01 §5.9.1.3, §5.9.1.5): ciò che dà, quanto pesa su ciascuna
/// risorsa rispetto alla base, e quanto dura. I pesi sono coefficienti riferiti alla base
/// (00 §13.2): il costo è `misura × base × peso`, troncato (00 §13.5), e la voce dichiara soltanto le
/// risorse che consuma davvero (02 §8.7). La durata si conta in stazioni dell'inverno (03 §4.4.4):
/// decide la linguetta in cui la voce sta e, con la stazione in cui la si ordina, quando sarà
/// pronta — che è ciò che il gioco dichiara, mai la durata (01 §5.9.1.4).
public struct VoceDelRegno: Codable, Hashable, Sendable {
    public let identificatore: IdentificatoreDati
    /// Il peso su ciascuna risorsa consumata, per nome di risorsa. Le risorse assenti non costano.
    public let pesi: [String: Scalato]
    /// Quante stazioni dell'inverno dura il lavoro (01 §5.9.1.3, 03 §4.4.4).
    public let durata: Int
    public let effetto: EffettoMilitare

    public init(identificatore: IdentificatoreDati, pesi: [String: Scalato], durata: Int = 1,
                effetto: EffettoMilitare) {
        self.identificatore = identificatore; self.pesi = pesi
        self.durata = durata; self.effetto = effetto
    }

    /// Il peso su una risorsa: zero se la voce non la consuma.
    public func peso(su risorsa: Risorsa) -> Scalato { pesi[risorsa.rawValue] ?? .zero }
}

/// Una LINGUETTA dell'inverno (01 §5.9.1.3, 02 §8.7.3): le voci si ripartiscono per durata, le più
/// lunghe per prime. Una linguetta raccoglie le voci la cui durata è almeno la sua soglia e sta
/// sotto la soglia della linguetta che la precede.
public struct LinguettaDelRegno: Codable, Hashable, Sendable {
    public let identificatore: IdentificatoreDati
    public let durataMinima: Int

    public init(identificatore: IdentificatoreDati, durataMinima: Int) {
        self.identificatore = identificatore; self.durataMinima = durataMinima
    }

    enum CodingKeys: String, CodingKey {
        case identificatore
        case durataMinima = "durata_minima"
    }
}

/// Il MANTENIMENTO delle forze (01 §4.14.1; decisione del titolare del 2026-11-23): la quota annua
/// che il gioco preleva da sé all'inizio dell'inverno, in denaro (01 §5.5.1), per ciascuna unità di
/// misura delle forze — nella modalità a sciami l'atomo —, con il minimo per elemento mantenuto
/// (00 §13.6).
public struct ValoriMantenimento: Codable, Hashable, Sendable {
    public let quotaPerMisura: Scalato
    public let quotaMinima: Int

    public init(quotaPerMisura: Scalato, quotaMinima: Int) {
        self.quotaPerMisura = quotaPerMisura; self.quotaMinima = quotaMinima
    }

    enum CodingKeys: String, CodingKey {
        case quotaPerMisura = "quota_per_misura"
        case quotaMinima = "quota_minima"
    }
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
    /// Quante stazioni dell'inverno vale una stagione operativa (03 §4.4.4): la scala con cui la
    /// durata di un lavoro, contata in stazioni, diventa la stagione in cui è pronto.
    public let stazioniPerStagione: Int
    /// Le linguette dell'inverno, dalla più lunga alla più breve (01 §5.9.1.3).
    public let linguette: [LinguettaDelRegno]
    /// Il mantenimento delle forze (01 §4.14.1).
    public let mantenimento: ValoriMantenimento
    /// I NOMI propri che le unità delle forze ricevono (01 §5.6.0.4): la lista chiusa e ordinata
    /// dei nomi dei gruppi, la stessa del fronte (`nomi-gruppi.json`). Non sta in `regno.json`: la
    /// legge il caricatore dal file che già la contiene, perché esista in un posto solo.
    public var nomiDelleUnita: [IdentificatoreDati] = []

    public init(giornatePerStagione: Int, quotaRiporto: Scalato, dotazioneIniziale: [String: Int],
                renditaAnnua: [String: Int], premioBattagliaVinta: Scalato, premioCampagnaVinta: Scalato,
                baseLeva: [String: Int], costoMinimo: Int, voci: [VoceDelRegno], fronti: [FronteDelRegno],
                faseIniziale: Fase, forzeIniziali: [FormazioneIniziale],
                stazioniPerStagione: Int = Stagione.stazioniInvernali,
                linguette: [LinguettaDelRegno] = [LinguettaDelRegno(identificatore: "brevi", durataMinima: 1)],
                mantenimento: ValoriMantenimento = ValoriMantenimento(quotaPerMisura: .zero, quotaMinima: 1),
                nomiDelleUnita: [IdentificatoreDati] = []) {
        self.stazioniPerStagione = stazioniPerStagione
        self.linguette = linguette
        self.mantenimento = mantenimento
        self.nomiDelleUnita = nomiDelleUnita
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
        case stazioniPerStagione = "stazioni_per_stagione"
        case linguette, mantenimento
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

    /// La linguetta in cui sta una voce (01 §5.9.1.3): la prima, dalla più lunga, la cui soglia la
    /// durata della voce raggiunge. Il caricamento garantisce che ne esista sempre una.
    public func linguetta(di voce: VoceDelRegno) -> LinguettaDelRegno {
        linguette.first { voce.durata >= $0.durataMinima } ?? linguette[linguette.count - 1]
    }

    /// Le voci di una linguetta, nell'ordine in cui si elencano: dalla più lunga alla più breve, a
    /// parità di durata nell'ordine del file (RDA-39: nessun secondo criterio).
    public func voci(in linguetta: LinguettaDelRegno) -> [VoceDelRegno] {
        voci.enumerated()
            .filter { self.linguetta(di: $0.element) == linguetta }
            .sorted { $0.element.durata == $1.element.durata ? $0.offset < $1.offset
                                                               : $0.element.durata > $1.element.durata }
            .map(\.element)
    }

    /// La durata più lunga che una voce può avere (03 §4.4.4): ordinata all'ultima stazione deve
    /// essere pronta al più tardi con l'inverno successivo (01 §5.9.1.3).
    public var durataMassima: Int { 1 + Stagione.operative.count * stazioniPerStagione }
}

/// Carica e valida i valori del regno (05 §7.8), con la disciplina degli altri caricatori: schema,
/// tipi, completezza, coerenza; un fallimento è un rapporto a chiavi di testo.
public enum CaricatoreRegno {
    public static let nomeFile = "regno.json"

    /// Il file che contiene la lista chiusa dei nomi (01 §5.6.0.4), la stessa del fronte.
    public static let fileDeiNomi = "nomi-gruppi.json"

    private struct ElencoDeiNomi: Decodable { let chiavi: [IdentificatoreDati] }

    /// - Parameter archetipiNoti: le chiavi degli archetipi validi, contro cui si verificano le
    ///   voci militari e le forze iniziali.
    /// - Parameter miglioramentiNoti: le chiavi dei miglioramenti validi (`miglioramenti.json`).
    public static func carica(da cartella: URL, archetipiNoti: Set<IdentificatoreDati>,
                              miglioramentiNoti: Set<IdentificatoreDati>) throws -> ValoriRegno {
        let url = cartella.appendingPathComponent(nomeFile)
        guard let dati = try? Data(contentsOf: url) else {
            throw ErroreDati(chiave: "errore.dati.file_mancante", file: nomeFile)
        }
        var valori: ValoriRegno
        do { valori = try JSONDecoder().decode(ValoriRegno.self, from: dati) }
        catch { throw ErroreDati(chiave: "errore.dati.file_malformato", file: nomeFile) }
        guard let datiNomi = try? Data(contentsOf: cartella.appendingPathComponent(fileDeiNomi)) else {
            throw ErroreDati(chiave: "errore.dati.file_mancante", file: fileDeiNomi)
        }
        guard let nomi = try? JSONDecoder().decode(ElencoDeiNomi.self, from: datiNomi) else {
            throw ErroreDati(chiave: "errore.dati.file_malformato", file: fileDeiNomi)
        }
        valori.nomiDelleUnita = nomi.chiavi
        try valida(valori, archetipiNoti: archetipiNoti, miglioramentiNoti: miglioramentiNoti)
        return valori
    }

    static func rifiuto(_ voce: String) -> ErroreDati {
        ErroreDati(chiave: "errore.dati.regno_incoerente", file: nomeFile, voce: voce)
    }

    static func valida(_ valori: ValoriRegno, archetipiNoti: Set<IdentificatoreDati>,
                       miglioramentiNoti: Set<IdentificatoreDati>) throws {
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
            guard costaQualcosa, (voce.effetto.misuraPropria ?? 1) >= 1 else { throw rifiuto(voce.identificatore) }
            // La durata: almeno una stazione, e non oltre quella che, ordinata all'ultima stazione,
            // matura con l'inverno successivo (01 §5.9.1.3: nulla arriva più tardi di così).
            guard voce.durata >= 1, voce.durata <= valori.durataMassima else {
                throw rifiuto(voce.identificatore)
            }
            switch voce.effetto {
            case .reclutaReparto(let archetipo, _):
                guard archetipiNoti.contains(archetipo) else { throw rifiuto(voce.identificatore) }
            case .miglioraReparto(let miglioramento), .mantieniMiglioramento(let miglioramento):
                guard miglioramentiNoti.contains(miglioramento) else { throw rifiuto(voce.identificatore) }
                // Ciò che agisce su un reparto esistente matura entro l'inverno (01 §4.13): il
                // reparto parte in primavera già addestrato, a qualunque stazione lo si ordini.
                // Una durata più lunga farebbe maturare il miglioramento a campagna aperta, su un
                // reparto che intanto può essere stato diviso, riunito o perduto.
                guard voce.durata == 1 else { throw rifiuto(voce.identificatore) }
            }
        }
        // Ogni miglioramento che si può dare si deve poter mantenere, e viceversa: altrimenti un
        // miglioramento sarebbe permanente, o una voce di mantenimento non avrebbe mai oggetto.
        let dati = Set(valori.voci.compactMap { voce -> IdentificatoreDati? in
            if case .miglioraReparto(let m) = voce.effetto { return m } else { return nil } })
        let mantenuti = Set(valori.voci.compactMap { voce -> IdentificatoreDati? in
            if case .mantieniMiglioramento(let m) = voce.effetto { return m } else { return nil } })
        guard dati == mantenuti else { throw rifiuto("miglioramenti") }
        // Il calendario dei lavori: una stagione vale almeno una stazione.
        guard valori.stazioniPerStagione >= 1 else { throw rifiuto("stazioni_per_stagione") }
        // Le linguette: almeno una, identificatori unici, soglie decrescenti, e l'ultima a uno,
        // sicché ogni voce cada in una linguetta (01 §5.9.1.3: ciascuna schermata contiene tutto).
        guard !valori.linguette.isEmpty,
              Set(valori.linguette.map(\.identificatore)).count == valori.linguette.count,
              valori.linguette.last?.durataMinima == 1,
              zip(valori.linguette, valori.linguette.dropFirst()).allSatisfy({ $0.durataMinima > $1.durataMinima })
        else { throw rifiuto("linguette") }
        // Il mantenimento: quota non negativa, minimo almeno uno (00 §13.6).
        guard valori.mantenimento.quotaPerMisura >= .zero, valori.mantenimento.quotaMinima >= 1 else {
            throw rifiuto("mantenimento")
        }
        // I nomi: abbastanza per le formazioni con cui il regno comincia, senza ripetizioni.
        guard Set(valori.nomiDelleUnita).count == valori.nomiDelleUnita.count,
              valori.nomiDelleUnita.count >= valori.forzeIniziali.count else {
            throw ErroreDati(chiave: "errore.dati.nomi_gruppi_incoerenti", file: fileDeiNomi)
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
