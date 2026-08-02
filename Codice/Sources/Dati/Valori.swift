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
    /// Gittata di disturbo e di pericolosità in celle (01 §3.4.1); zero per chi non tira.
    public let gittataDisturbo: Int
    public let gittataPericolosita: Int
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
    /// Offese da tiro disponibili (vuoto per chi non tira).
    public let offeseTiro: [TipoOffesa: ProfiloOffesa]

    enum CodingKeys: String, CodingKey {
        case identificatore
        case puntiVitaPerAtomo = "punti_vita_per_atomo"
        case capacitaOffensivaPerAtomo = "capacita_offensiva_per_atomo"
        case gittataDisturbo = "gittata_disturbo"
        case gittataPericolosita = "gittata_pericolosita"
        case volumePerAtomo = "volume_per_atomo"
        case penalitaAvanzamento = "penalita_avanzamento"
        case sogliaDisingaggio = "soglia_disingaggio"
        case sensibilitaStanchezza = "sensibilita_stanchezza"
        case dotazioneMunizioni = "dotazione_munizioni"
        case offesaMischia = "offesa_mischia"
        case offeseTiro = "offese_tiro"
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
    /// Coefficiente del danno del tiro entro la sola gittata di disturbo (01 §3.4.1).
    public let coefficienteTiroDisturbo: Scalato
    enum CodingKeys: String, CodingKey {
        case efficaciaMinima = "efficacia_minima"
        case sogliaPocoEfficace = "soglia_poco_efficace"
        case coefficienteTiroDisturbo = "coefficiente_tiro_disturbo"
    }
}

/// L'insieme dei valori caricati e validati che il Motore riceve (05 §1.2).
public struct ValoriDiGioco: Sendable {
    public let versione: String
    /// Versione effettiva registrata nei salvataggi: base, o base più suffisso locale (RDA-45).
    public let versioneEffettiva: String
    public let modificatiLocalmente: Bool
    public let archetipi: [IdentificatoreDati: DefinizioneArchetipo]
    public let protezioni: [TipoProtezione: ProfiloProtezione]
    public let formati: [IdentificatoreDati: FormatoBattaglia]
    public let caratteristiche: [IdentificatoreDati: CaratteristicaCampo]
    public let minimi: Minimi
    public let combattimento: ParametriCombattimento
}
