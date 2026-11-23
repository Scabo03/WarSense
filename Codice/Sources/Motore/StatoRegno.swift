import Foundation
import Dati

// Lo stato del regno (05 §2.4; incarico 30, RDA-162). Il regno è lo strato sopra il fronte, come il
// fronte è lo strato sopra la battaglia: uno stato che è un valore, interamente Codable, senza alcun
// riferimento a schermate o annunci (00 §3.2), e comandi discreti che lo modificano.
//
// Il regno è IDENTICO nelle due modalità di battaglia (01 §1.2; documento della modalità a campioni,
// 1.3): in questo file non compare nulla che appartenga a una modalità. Le forze militari sono un
// valore opaco (`ForzeDelRegno`), e ciò che una voce militare dà è un gancio d'effetto (`EffettoMilitare`):
// le due cose, e soltanto quelle, cambiano con la modalità, e vivono in `ForzeDelRegno.swift`.
// Un controllo del collaudo lo fa rispettare (`RegnoComuneAlleModalitaTest`).

/// Le riserve del regno: un saldo intero per ciascuna delle cinque risorse (01 §5.5.1). Serve anche
/// a esprimere un costo, un'entrata o una quantità perduta, che hanno la stessa forma.
public struct Riserve: Hashable, Codable, Sendable {
    /// I saldi per nome di risorsa. Le risorse assenti valgono zero.
    private var saldi: [String: Int]

    public init() { saldi = [:] }

    /// Le riserve dichiarate da un file dei valori, per nome di risorsa.
    public init(_ mappa: [String: Int]) {
        saldi = [:]
        for risorsa in Risorsa.allCases { saldi[risorsa.rawValue] = mappa[risorsa.rawValue] ?? 0 }
    }

    public static let vuote = Riserve()

    public subscript(risorsa: Risorsa) -> Int {
        get { saldi[risorsa.rawValue] ?? 0 }
        set { saldi[risorsa.rawValue] = newValue }
    }

    /// Le risorse con quantità diversa da zero, nell'ordine fisso in cui si annunciano (02 §8.7:
    /// ciascuna voce dichiara soltanto le risorse che consuma davvero).
    public var risorseInGioco: [Risorsa] { Risorsa.allCases.filter { self[$0] != 0 } }

    /// Vero se ogni quantità è nulla.
    public var sonoVuote: Bool { risorseInGioco.isEmpty }

    /// Le risorse di cui queste riserve non bastano a pagare il costo, nell'ordine fisso.
    public func mancanti(per costo: Riserve) -> [Risorsa] {
        Risorsa.allCases.filter { self[$0] < costo[$0] }
    }

    public static func + (a: Riserve, b: Riserve) -> Riserve {
        var esito = Riserve()
        for risorsa in Risorsa.allCases { esito[risorsa] = a[risorsa] + b[risorsa] }
        return esito
    }

    public static func - (a: Riserve, b: Riserve) -> Riserve {
        var esito = Riserve()
        for risorsa in Risorsa.allCases { esito[risorsa] = a[risorsa] - b[risorsa] }
        return esito
    }

    public init(from decoder: any Decoder) throws {
        self.init(try decoder.singleValueContainer().decode([String: Int].self))
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        var pieni: [String: Int] = [:]
        for risorsa in Risorsa.allCases { pieni[risorsa.rawValue] = self[risorsa] }
        try c.encode(pieni)
    }
}

/// Il momento dell'anno in cui il regno si trova (01 §5.9): la parte operativa, da primavera ad
/// autunno, in cui si conduce campagna, oppure l'inverno, con la stazione corrente fra le quattro
/// (01 §5.9.1.1, 05 §2.3).
public enum MomentoDellAnno: Hashable, Codable, Sendable {
    case operativo
    case inverno(stazione: Int)

    /// Le stazioni dell'inverno: quattro, numero di struttura e non di gioco (01 §5.9.1.1, 05 §0.4).
    public static let stazioniInvernali = Stagione.stazioniInvernali

    public var eInverno: Bool { if case .inverno = self { return true } else { return false } }
    public var stazione: Int? { if case .inverno(let s) = self { return s } else { return nil } }
}

/// L'ESITO di una campagna, come arriva al regno (incarico 30, RDA-162, RDA-164): un dato
/// autosufficiente, iscritto nel giornale del regno, sicché rigiocare quel giornale riproduce il
/// regno senza rileggere i file della campagna — come l'esito di una battaglia nel giornale del fronte.
public struct EsitoCampagna: Hashable, Codable, Sendable {
    public let fronte: IdentificatoreDati
    public let anno: Int
    public let modo: ConclusioneCampagna.Modo
    /// Chi ha vinto; nessuno se l'inverno ha interrotto la campagna.
    public let vincitore: Parte?
    /// L'ultima giornata giocata.
    public let giornate: Int
    public let battaglieVinte: Int
    public let battagliePerse: Int
    /// Le forze che rientrano in patria.
    public let superstiti: ForzeDelRegno

    public init(fronte: IdentificatoreDati, anno: Int, modo: ConclusioneCampagna.Modo, vincitore: Parte?,
                giornate: Int, battaglieVinte: Int, battagliePerse: Int, superstiti: ForzeDelRegno) {
        self.fronte = fronte; self.anno = anno; self.modo = modo; self.vincitore = vincitore
        self.giornate = giornate; self.battaglieVinte = battaglieVinte
        self.battagliePerse = battagliePerse; self.superstiti = superstiti
    }

    /// Vero se la campagna è stata vinta dal giocatore.
    public var vinta: Bool { vincitore == .giocatore }
}

/// La campagna dell'anno (01 §5.6.9): nella prima tappa il regno ne conduce al più una, su un fronte.
public enum CampagnaDellAnno: Hashable, Codable, Sendable {
    case nonAperta
    case aperta(fronte: IdentificatoreDati)
    case conclusa(EsitoCampagna)

    public var fronteAperto: IdentificatoreDati? {
        if case .aperta(let fronte) = self { return fronte } else { return nil }
    }
    public var esito: EsitoCampagna? {
        if case .conclusa(let esito) = self { return esito } else { return nil }
    }
}

/// Un lavoro ordinato in patria e non ancora pronto (01 §5.9.1.4, 05 §2.4): la voce, ciò che è
/// costato, la stazione in cui è stato ordinato, ciò che darà, la stagione in cui sarà pronto e —
/// per le voci che agiscono su qualcosa che esiste già (01 §4.13) — su che cosa.
public struct LavoroOrdinato: Hashable, Codable, Sendable {
    public let voce: IdentificatoreDati
    public let costo: Riserve
    public let stazione: Int
    public let effetto: EffettoMilitare
    public let pronto: Stagione
    public let bersaglio: BersaglioMilitare?

    public init(voce: IdentificatoreDati, costo: Riserve, stazione: Int, effetto: EffettoMilitare,
                pronto: Stagione, bersaglio: BersaglioMilitare? = nil) {
        self.voce = voce; self.costo = costo; self.stazione = stazione
        self.effetto = effetto; self.pronto = pronto; self.bersaglio = bersaglio
    }
}

/// I fatti che il registro della patria sa annotare (01 §5.17, §5.17.1): soltanto ciò che il
/// giocatore non ha deciso. Insieme chiuso.
public enum FattoDiPatria: Hashable, Codable, Sendable {
    /// La campagna dell'anno si è conclusa, e come.
    case campagnaConclusa(fronte: IdentificatoreDati, modo: ConclusioneCampagna.Modo, vincitore: Parte?)
    /// È cominciato l'inverno.
    case invernoCominciato
    /// Un miglioramento ordinato nell'inverno è compiuto (01 §5.17.1: «il completamento di un'opera
    /// in patria entra nel registro della patria»): chi lo ha ricevuto.
    case miglioramentoDato(ElementoDelleForze)
    /// È cominciata la primavera; `eccedenzaPerduta` dice se il riporto ha tolto qualcosa (01 §5.5.1.4).
    case primaveraCominciata(eccedenzaPerduta: Bool)
    /// Il gioco ha prelevato da sé la quota annua di mantenimento delle forze (01 §4.14.1.1).
    case mantenimentoPrelevato(quota: Riserve)
    /// Il denaro non è bastato al mantenimento, e un elemento delle forze è stato sciolto (01 §4.14.1.1).
    case elementoSciolto(ElementoDelleForze)
    /// Le reclute di un inverno sono entrate nelle forze, e dove (01 §4.12; incarico 31).
    case recluteEntrate(IngressoNelleForze)
    /// Un miglioramento non mantenuto si è perduto (01 §4.14).
    case miglioramentoPerduto(ElementoDelleForze)

    /// Un esemplare per ciascun caso, perché il collaudo pretenda una frase per ogni fatto.
    public static let casiDiRiferimento: [FattoDiPatria] = [
        .campagnaConclusa(fronte: "guado", modo: .annientamento, vincitore: .giocatore),
        .campagnaConclusa(fronte: "guado", modo: .annientamento, vincitore: .avversario),
        .campagnaConclusa(fronte: "guado", modo: .inverno, vincitore: nil),
        .invernoCominciato,
        .miglioramentoDato(Esemplari.migliorato),
        .primaveraCominciata(eccedenzaPerduta: false),
        .primaveraCominciata(eccedenzaPerduta: true),
        .mantenimentoPrelevato(quota: Riserve(["denaro": 30])),
        .elementoSciolto(Esemplari.sciolto),
        .recluteEntrate(Esemplari.ingresso(.primavera, confluite: false)),
        .recluteEntrate(Esemplari.ingresso(.estate, confluite: false)),
        .recluteEntrate(Esemplari.ingresso(.inverno, confluite: false)),
        .recluteEntrate(Esemplari.ingresso(.primavera, confluite: true)),
        .miglioramentoPerduto(Esemplari.migliorato),
    ]
}

/// Una voce del registro della patria: numerata, con l'anno e la stagione cui si riferisce (01 §5.17).
public struct VoceRegistroPatria: Hashable, Codable, Sendable {
    public let numero: Int
    public let anno: Int
    public let stagione: Stagione
    public let fatto: FattoDiPatria

    public init(numero: Int, anno: Int, stagione: Stagione, fatto: FattoDiPatria) {
        self.numero = numero; self.anno = anno; self.stagione = stagione; self.fatto = fatto
    }
}

/// Lo stato completo del regno (05 §2.4). Nella prima tappa ne esiste la parte che serve a un anno
/// intero: calendario, riserve, forze, lavori, campagna dell'anno, registro, fase.
public struct StatoRegno: Hashable, Codable, Sendable {
    /// L'anno in corso, da uno.
    public var anno: Int
    public var momento: MomentoDellAnno
    /// La fase storica corrente (01 §2.3): decide il nome della moneta (01 §5.5.1.3).
    public var fase: Fase
    public var riserve: Riserve
    /// L'entrata dell'anno, cioè la base su cui si calcola il riporto (01 §5.5.1.4, RDA-165): vuota
    /// fuori dall'inverno.
    public var entrataDellAnno: Riserve
    public var forze: ForzeDelRegno
    public var campagna: CampagnaDellAnno
    /// I lavori ordinati in questo inverno, nell'ordine in cui sono stati ordinati.
    public var lavori: [LavoroOrdinato]
    /// Il registro della patria, in ordine di accadimento (01 §5.17).
    public var registro: [VoceRegistroPatria]
    public var prossimoNumeroVoce: Int
    /// Ciò che il mantenimento delle forze ha prelevato all'inizio di questo inverno (01 §4.14.1.1):
    /// è ciò che la prima schermata dichiara. Vuoto fuori dall'inverno.
    public var mantenimento: Riserve
    /// Ciò che il mantenimento ha sciolto all'inizio di questo inverno, perché il denaro non bastava.
    public var sciolti: [ElementoDelleForze]

    public init(anno: Int, momento: MomentoDellAnno, fase: Fase, riserve: Riserve,
                entrataDellAnno: Riserve = .vuote, forze: ForzeDelRegno,
                campagna: CampagnaDellAnno = .nonAperta, lavori: [LavoroOrdinato] = [],
                registro: [VoceRegistroPatria] = [], prossimoNumeroVoce: Int = 0,
                mantenimento: Riserve = .vuote, sciolti: [ElementoDelleForze] = []) {
        self.anno = anno; self.momento = momento; self.fase = fase; self.riserve = riserve
        self.entrataDellAnno = entrataDellAnno; self.forze = forze; self.campagna = campagna
        self.lavori = lavori; self.registro = registro; self.prossimoNumeroVoce = prossimoNumeroVoce
        self.mantenimento = mantenimento; self.sciolti = sciolti
    }

    /// La stagione in cui il regno si trova quando non ha una campagna aperta che lo dica: l'inverno
    /// se è inverno; altrimenti la primavera, finché la campagna dell'anno non è stata condotta, e
    /// la stagione in cui essa si è conclusa dopo. Con la campagna aperta la data è quella del
    /// fronte (01 §5.6.10.2: la patria mostra la data più arretrata fra i fronti aperti).
    public func stagione(giornatePerStagione: Int) -> Stagione {
        if momento.eInverno { return .inverno }
        guard let esito = campagna.esito else { return .primavera }
        return CalendarioDiCampagna(anno: anno, giornatePerStagione: giornatePerStagione)
            .stagione(del: esito.giornate)
    }

    /// Il registro dal fatto più recente al meno recente, com'è presentato (02 §6.6).
    public var registroDalPiuRecente: [VoceRegistroPatria] { registro.reversed() }
}

/// I comandi discreti del regno (05 §3.5). Codifica stabile: i casi si aggiungono, non si rinominano.
public enum ComandoRegno: Hashable, Codable, Sendable {
    /// Apre la campagna dell'anno su un fronte (01 §5.6.9, §5.6.10).
    case apriCampagna(fronte: IdentificatoreDati)
    /// Lascia passare ciò che resta dell'anno: comincia l'inverno, e con esso il bilancio (01 §5.9).
    case attendiInverno
    /// Ordina un lavoro (05 §3.5): una leva, oppure — con il bersaglio — l'addestramento mirato o il
    /// mantenimento del miglioramento di un elemento delle forze che esiste già (01 §4.13, §4.14).
    case ordina(voce: IdentificatoreDati, bersaglio: BersaglioMilitare?)
    /// Destina un'unità delle forze al fronte, oppure la tiene in patria (incarico 31): vale per la
    /// campagna dell'anno e resta finché il giocatore non la cambia.
    case destina(unita: IdentificatoreDati, alFronte: Bool)
    /// Prosegue alla stazione invernale successiva; dalla quarta, alla primavera (05 §3.5: le
    /// quattro schermate avanzano soltanto per questo comando esplicito).
    case prosegui
}

/// I motivi chiusi di non ammissibilità di un comando del regno (05 §3.2): ciascuno corrisponde a
/// un termine del vocabolario chiuso; la risorsa che manca si dichiara per nome (01 §5.9.1.5).
public enum MotivoNonValidoRegno: Hashable, Sendable {
    case fronteIgnoto
    case voceIgnota
    /// D'inverno non si conduce campagna (01 §5.9).
    case eInverno
    /// I lavori si ordinano d'inverno (01 §4.13; le voci fuori dall'inverno non sono costruite).
    case nonEInverno
    /// C'è una campagna aperta: non se ne apre un'altra, e l'inverno non arriva finché dura.
    case campagnaAperta
    /// La campagna dell'anno è già stata condotta.
    case campagnaGiaCondotta
    /// Il regno non ha forze con cui condurre una campagna.
    case nessunaForza
    /// Le riserve non bastano: le risorse che mancano, nell'ordine fisso.
    case risorseInsufficienti([Risorsa])
    /// Le forze non hanno un'unità con quel nome.
    case unitaIgnota
    /// La voce si ordina su un elemento delle forze, e il comando non lo indica, o ne indica uno
    /// che non esiste; oppure la voce non ne vuole e il comando lo indica.
    case bersaglioMancante
    /// L'elemento indicato non può ricevere la voce: porta già un miglioramento, o non porta quello
    /// che si vuole mantenere.
    case bersaglioNonAmmesso
    /// La stessa voce è già stata ordinata in questo inverno sullo stesso elemento.
    case giaOrdinato

    /// La chiave del termine chiuso che dichiara il motivo. Per le risorse insufficienti la frase
    /// nomina ciascuna risorsa che manca, e la compone chi annuncia.
    public var chiaveTesto: String {
        switch self {
        case .fronteIgnoto: return "regno.non_valido.fronte_ignoto"
        case .voceIgnota: return "regno.non_valido.voce_ignota"
        case .eInverno: return "regno.non_valido.e_inverno"
        case .nonEInverno: return "regno.non_valido.non_e_inverno"
        case .campagnaAperta: return "regno.non_valido.campagna_aperta"
        case .campagnaGiaCondotta: return "regno.non_valido.campagna_gia_condotta"
        case .nessunaForza: return "regno.non_valido.nessuna_forza"
        case .risorseInsufficienti: return "regno.non_valido.risorse_insufficienti"
        case .unitaIgnota: return "regno.non_valido.unita_ignota"
        case .bersaglioMancante: return "regno.non_valido.bersaglio_mancante"
        case .bersaglioNonAmmesso: return "regno.non_valido.bersaglio_non_ammesso"
        case .giaOrdinato: return "regno.non_valido.gia_ordinato"
        }
    }

    /// Un esemplare per ciascun caso, perché il collaudo pretenda un termine per ogni motivo.
    public static let casiDiRiferimento: [MotivoNonValidoRegno] = [
        .fronteIgnoto, .voceIgnota, .eInverno, .nonEInverno, .campagnaAperta,
        .campagnaGiaCondotta, .nessunaForza, .risorseInsufficienti([.uomini]),
        .unitaIgnota, .bersaglioMancante, .bersaglioNonAmmesso, .giaOrdinato,
    ]
}

/// L'esito della validazione di un comando del regno: validazione e anteprima sono la stessa cosa
/// (05 §3.2). Valido, porta il costo che verrebbe pagato.
public enum EsitoValidazioneRegno: Hashable, Sendable {
    case valido(costo: Riserve)
    case nonValido(MotivoNonValidoRegno)

    public var eValido: Bool { if case .valido = self { return true } else { return false } }
    public var motivo: MotivoNonValidoRegno? {
        if case .nonValido(let m) = self { return m } else { return nil }
    }
}

/// Gli eventi astratti del regno (05 §3.7): fatti, mai annunci (00 §3.2).
public enum EventoRegno: Hashable, Codable, Sendable {
    /// La campagna dell'anno è stata aperta su un fronte.
    case campagnaAperta(fronte: IdentificatoreDati)
    /// La campagna dell'anno si è conclusa e l'esito è arrivato in patria.
    case campagnaConclusa(esito: EsitoCampagna)
    /// È cominciato l'inverno: l'entrata dell'anno si è aggiunta alle riserve, e il mantenimento
    /// delle forze ne ha prelevato la propria quota; se il denaro non bastava, ciò che è stato sciolto.
    case invernoCominciato(anno: Int, entrata: Riserve, mantenimento: Riserve, sciolti: [ElementoDelleForze])
    /// Un lavoro è stato ordinato e pagato.
    case lavoroOrdinato(voce: IdentificatoreDati, costo: Riserve, pronto: Stagione, bersaglio: BersaglioMilitare?)
    /// Si è aperta una stazione invernale successiva alla prima.
    case stazioneAperta(stazione: Int)
    /// È cominciata la primavera dell'anno nuovo: ciò che il riporto ha tolto, le reclute entrate
    /// nelle forze, ciò che ha ricevuto un miglioramento, ciò che lo ha perduto.
    case primaveraCominciata(anno: Int, perduto: Riserve, ingressi: [IngressoNelleForze],
                             migliorati: [ElementoDelleForze], miglioramentiPerduti: [ElementoDelleForze])
    /// Un'unità delle forze è stata destinata al fronte, oppure tenuta in patria.
    case unitaDestinata(unita: IdentificatoreDati, alFronte: Bool)
}
