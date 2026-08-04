import Foundation

// I tipi dei valori vivono in Dati e il Motore li consuma già validati (05 §1.2, RDA-01).
// Nessun valore di bilanciamento vive nel codice: tutto arriva dai file (00 §13.1).

/// Identificatore stabile di una voce dei dati (archetipo, caratteristica, opera...).
public typealias IdentificatoreDati = String

/// Le due parti di uno scontro.
public enum Parte: String, Codable, Hashable, Sendable, CaseIterable {
    case giocatore, avversario
    public var avversaria: Parte { self == .giocatore ? .avversario : .giocatore }
}

/// I due tipi di offesa da tiro (01 §3.3.1) e le offese da mischia.
public enum TipoOffesa: String, Codable, Hashable, Sendable, CaseIterable, CodingKeyRepresentable {
    case proiettileLeggero = "proiettile_leggero"
    case proiettilePesante = "proiettile_pesante"
    case armaDaMischia = "arma_da_mischia"
}

/// I due tipi di protezione, opposti (01 §3.3.2).
public enum TipoProtezione: String, Codable, Hashable, Sendable, CaseIterable, CodingKeyRepresentable {
    case antiSaturazione = "anti_saturazione"
    case antiPerforazione = "anti_perforazione"
}

/// Profilo di un'offesa: due poteri, uno per asse. La formula unica del Motore
/// li combina con i due pari della protezione: nessuna tabella a doppia entrata (00 §13.3, 01 §9.9).
public struct ProfiloOffesa: Codable, Hashable, Sendable {
    public let potereSaturazione: Scalato
    public let poterePerforazione: Scalato
    public init(potereSaturazione: Scalato, poterePerforazione: Scalato) {
        self.potereSaturazione = potereSaturazione
        self.poterePerforazione = poterePerforazione
    }
    enum CodingKeys: String, CodingKey {
        case potereSaturazione = "potere_saturazione"
        case poterePerforazione = "potere_perforazione"
    }
}

/// Profilo di una protezione: due pare, una per asse.
public struct ProfiloProtezione: Codable, Hashable, Sendable {
    public let paraSaturazione: Scalato
    public let paraPerforazione: Scalato
    enum CodingKeys: String, CodingKey {
        case paraSaturazione = "para_saturazione"
        case paraPerforazione = "para_perforazione"
    }
}

/// Parametri di un archetipo (01 §3.4). Tutti coefficienti o quantità dai file.
public struct DefinizioneArchetipo: Codable, Hashable, Sendable {
    public let identificatore: IdentificatoreDati
    /// Punti vita per atomo (grandezza base grande: 00 §13.7).
    public let puntiVitaPerAtomo: Int64
    /// Capacità offensiva per atomo, in punti di danno base.
    public let capacitaOffensivaPerAtomo: Int64
    /// La gittata utile unica in celle (01 §3.4.1, versione 3.3); zero per chi non tira.
    public let gittata: Int
    /// Volume per atomo (01 §3.4.4), seguito incorporato (01 §3.4.5).
    public let volumePerAtomo: Int64
    /// Coefficiente di penalità di avanzamento (01 §8.6).
    public let penalitaAvanzamento: Scalato
    /// Soglia di disingaggio: proporzione delle perdite sulla consistenza d'ingresso (01 §9.8).
    public let sogliaDisingaggio: Scalato
    /// Sensibilità alla stanchezza (01 §5.7).
    public let sensibilitaStanchezza: Scalato
    /// Scariche di munizioni disponibili (01 §3.4.3); zero per chi non tira.
    public let dotazioneMunizioni: Int
    /// Offesa in mischia.
    public let offesaMischia: ProfiloOffesa
    /// Il proiettile del reparto, proprietà fissa e dichiarata (01 §3.3.1, versione 3.3);
    /// assente per chi non tira.
    public let proiettile: TipoOffesa?
    /// L'offesa da tiro del proiettile fisso; assente per chi non tira.
    public let offesaTiro: ProfiloOffesa?

    enum CodingKeys: String, CodingKey {
        case identificatore
        case puntiVitaPerAtomo = "punti_vita_per_atomo"
        case capacitaOffensivaPerAtomo = "capacita_offensiva_per_atomo"
        case gittata
        case volumePerAtomo = "volume_per_atomo"
        case penalitaAvanzamento = "penalita_avanzamento"
        case sogliaDisingaggio = "soglia_disingaggio"
        case sensibilitaStanchezza = "sensibilita_stanchezza"
        case dotazioneMunizioni = "dotazione_munizioni"
        case offesaMischia = "offesa_mischia"
        case proiettile
        case offesaTiro = "offesa_tiro"
    }
}

/// Valori del formato di battaglia (03 §5.2, §5.13; 01 §8.2.1, §9.3).
public struct FormatoBattaglia: Codable, Hashable, Sendable {
    public let identificatore: IdentificatoreDati
    public let righe: Int
    public let colonne: Int
    /// Budget di volume di base per turno.
    public let budgetVolumeBase: Int64
    /// Coefficiente del primo turno maggiorato (01 §9.3.1).
    public let coefficientePrimoTurno: Scalato
    /// Quota di riporto del volume non speso, sul budget di base (01 §9.3.3, §9.3.4).
    public let quotaRiporto: Scalato
    /// Righe di piazzamento dal proprio lato (2 sui formati minori, 3 sul dieci: 01 §8.2.1).
    public let righeDiPiazzamento: Int
    /// Righe dalla propria retrolinea che definiscono la soglia della ritirata (01 §10.3).
    public let righeSogliaRitirata: Int
    /// Coefficiente del costo dello spostamento di due celle (01 §9.5.0.3, 03 §5.3).
    public let coefficienteSpostamentoDoppio: Scalato
    /// Turni consecutivi di vantaggio dell'imboscante (01 §9.3.2, 03 §5.9).
    public let turniVantaggioImboscante: Int
    /// Sconto sul piazzamento dell'imboscante (01 §9.3.2, ordine del trenta per cento).
    public let scontoImboscante: Scalato
    /// Turni minimi prima della resa e accorciamento per perdite (01 §10.2, 03 §6.1).
    public let sogliaMinimaResaTurni: Int
    public let accorciamentoResaPerPerdite: Scalato

    enum CodingKeys: String, CodingKey {
        case identificatore, righe, colonne
        case budgetVolumeBase = "budget_volume_base"
        case coefficientePrimoTurno = "coefficiente_primo_turno"
        case quotaRiporto = "quota_riporto"
        case righeDiPiazzamento = "righe_di_piazzamento"
        case righeSogliaRitirata = "righe_soglia_ritirata"
        case coefficienteSpostamentoDoppio = "coefficiente_spostamento_doppio"
        case turniVantaggioImboscante = "turni_vantaggio_imboscante"
        case scontoImboscante = "sconto_imboscante"
        case sogliaMinimaResaTurni = "soglia_minima_resa_turni"
        case accorciamentoResaPerPerdite = "accorciamento_resa_per_perdite"
    }
}

/// Caratteristica unica del campo (01 §7.4), con modificatori su ganci tipizzati (05 §7.7, 03 §5.12).
public struct CaratteristicaCampo: Codable, Hashable, Sendable {
    /// L'insieme chiuso dei ganci che il Motore conosce. Un gancio ignoto è respinto in validazione.
    public enum Gancio: String, Codable, Hashable, Sendable, CaseIterable, CodingKeyRepresentable {
        case coefficienteDanno = "coefficiente_danno"
        case coefficienteCostoMovimento = "coefficiente_costo_movimento"
        case variazioneGittate = "variazione_gittate"
    }
    public let identificatore: IdentificatoreDati
    public let modificatori: [Gancio: Scalato]
}

/// Minimi obbligatori (00 §13.6, 03 §8): dove il troncamento può dare zero, il minimo è dichiarato.
public struct Minimi: Codable, Hashable, Sendable {
    public let dannoMinimo: Int64
    public let costoPiazzamentoMinimo: Int64
    public let atomiMinimiSciameVivo: Int64
    enum CodingKeys: String, CodingKey {
        case dannoMinimo = "danno_minimo"
        case costoPiazzamentoMinimo = "costo_piazzamento_minimo"
        case atomiMinimiSciameVivo = "atomi_minimi_sciame_vivo"
    }
}

/// Parametri della formula unica del danno (01 §9.9, §9.2.1). I numeri sono provvisori nei file.
public struct ParametriCombattimento: Codable, Hashable, Sendable {
    /// Frazione minima di efficacia: l'offesa poco adatta non è mai inefficace (01 §9.9).
    public let efficaciaMinima: Scalato
    /// Soglia sotto la quale l'annuncio dichiara l'offesa poco efficace (01 §9.9.1, 02 §4.4.1.3).
    public let sogliaPocoEfficace: Scalato
    /// Soglie delle fasce descrittive degli esiti (01 §9.7.2, 03 §5.14): proporzione
    /// del danno sulla consistenza del colpito prima dell'applicazione. Provvisorie.
    public let fasciaPerditeLieviFino: Scalato
    public let fasciaPerditeSignificativeFino: Scalato
    /// Maggiorazione massima del tiro alla minima distanza (01 §9.10.1, 03 §5.15):
    /// al limite della gittata la maggiorazione è nulla, a contatto è questa. Provvisoria.
    public let maggiorazioneVicinanzaMassima: Scalato
    /// Soglie delle fasce descrittive della vicinanza (01 §9.10.1, 02 §4.4.5),
    /// espresse sulla prossimità: zero al limite della gittata, uno a contatto. Provvisorie.
    public let fasciaVicinanzaLontanoFino: Scalato
    public let fasciaVicinanzaRavvicinatoFino: Scalato
    /// Passo della maggiorazione di accerchiamento (01 §9.10.2, 03 §5.16). Provvisorio.
    public let passoAccerchiamento: Scalato
    /// Numero massimo di concorrenti che il conteggio dell'accerchiamento considera
    /// (01 §9.10.2): oltre questo la maggiorazione non cresce più. Provvisorio.
    public let concorrentiMassimi: Int
    /// Il malus del secondo bersaglio (01 §9.11), espresso come resa conservata:
    /// un reparto già impegnato si difende di lato e rende questa frazione contro
    /// il secondo nemico. Contro il primo rende per intero, dal terzo non risponde
    /// affatto. Provvisorio.
    public let resaControSecondoBersaglio: Scalato
    enum CodingKeys: String, CodingKey {
        case efficaciaMinima = "efficacia_minima"
        case sogliaPocoEfficace = "soglia_poco_efficace"
        case fasciaPerditeLieviFino = "fascia_perdite_lievi_fino"
        case fasciaPerditeSignificativeFino = "fascia_perdite_significative_fino"
        case maggiorazioneVicinanzaMassima = "maggiorazione_vicinanza_massima"
        case fasciaVicinanzaLontanoFino = "fascia_vicinanza_lontano_fino"
        case fasciaVicinanzaRavvicinatoFino = "fascia_vicinanza_ravvicinato_fino"
        case passoAccerchiamento = "passo_accerchiamento"
        case concorrentiMassimi = "concorrenti_massimi"
        case resaControSecondoBersaglio = "resa_contro_secondo_bersaglio"
    }
}

/// Parametri di carattere di un ufficiale avversario (01 §14.3, 03 §6.5).
/// Un'unica intelligenza, parametri diversi; tutti provvisori nei file.
public struct DefinizioneUfficiale: Codable, Hashable, Sendable {
    public let identificatore: IdentificatoreDati
    public let propensioneAttacco: Scalato
    public let tolleranzaPerdite: Scalato
    public let tendenzaAccerchiamento: Scalato
    public let propensioneImboscata: Scalato
    public let propensioneRitirata: Scalato
    enum CodingKeys: String, CodingKey {
        case identificatore
        case propensioneAttacco = "propensione_attacco"
        case tolleranzaPerdite = "tolleranza_perdite"
        case tendenzaAccerchiamento = "tendenza_accerchiamento"
        case propensioneImboscata = "propensione_imboscata"
        case propensioneRitirata = "propensione_ritirata"
    }
}

/// I vantaggi nascosti del giocatore (01 §13, 03 §7): noti al programma di verifica,
/// che può disattivarli per misurare le probabilità reali (05 §12.5).
public struct VantaggiNascosti: Codable, Hashable, Sendable {
    /// L'avversario ritira unità soltanto dalla propria riga più arretrata (01 §13.2).
    public let ritirataAvversariaSoloUltimaRiga: Bool
    /// Riduzione della propensione alla ritirata dell'avversario (01 §13.2).
    public let riduzionePropensioneRitirataAvversaria: Scalato
    /// L'annientamento simultaneo non si risolve a sfavore del giocatore (01 §13.2,
    /// §15.2.5): quando entrambe le parti restano senza nulla nello stesso giro,
    /// sconfitto è l'avversario. A falso vale il comportamento opposto, che esiste
    /// soltanto perché il programma di verifica misuri le probabilità reali (05 §12.5).
    public let annientamentoSimultaneoAlGiocatore: Bool
    enum CodingKeys: String, CodingKey {
        case ritirataAvversariaSoloUltimaRiga = "ritirata_avversaria_solo_ultima_riga"
        case riduzionePropensioneRitirataAvversaria = "riduzione_propensione_ritirata_avversaria"
        case annientamentoSimultaneoAlGiocatore = "annientamento_simultaneo_al_giocatore"
    }
}

/// L'insieme dei valori caricati e validati che il Motore riceve (05 §1.2).
public struct ValoriDiGioco: Sendable {
    public let versione: String
    /// Versione effettiva registrata nei salvataggi: base, o base più suffisso locale (RDA-45).
    public let versioneEffettiva: String
    public let modificatiLocalmente: Bool
    /// Versioni di salvataggio che questi valori sanno aprire (00 §15, 05 §6.6).
    public let versioniCompatibili: [String]
    public let archetipi: [IdentificatoreDati: DefinizioneArchetipo]
    public let protezioni: [TipoProtezione: ProfiloProtezione]
    public let formati: [IdentificatoreDati: FormatoBattaglia]
    public let caratteristiche: [IdentificatoreDati: CaratteristicaCampo]
    public let minimi: Minimi
    public let combattimento: ParametriCombattimento
    public let ufficiali: [IdentificatoreDati: DefinizioneUfficiale]
    public let vantaggi: VantaggiNascosti
}
