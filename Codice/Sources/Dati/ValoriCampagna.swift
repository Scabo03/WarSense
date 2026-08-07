import Foundation

// I tipi dei valori del piano di campagna (05 §7.5, §7.6). Come per la battaglia,
// il Motore li riceve già validati e nessun numero vive nel codice (00 §13.1).

/// I tre formati fissi della mappa di campagna (01 §5.1). Le dimensioni stanno
/// nei dati e non nel codice: qui vive soltanto la forma della voce.
public struct FormatoMappa: Codable, Hashable, Sendable {
    public let identificatore: IdentificatoreDati
    public let righe: Int
    public let colonne: Int
    public init(identificatore: IdentificatoreDati, righe: Int, colonne: Int) {
        self.identificatore = identificatore
        self.righe = righe
        self.colonne = colonne
    }
}

/// La qualificazione di una casella (01 §5.1.2). L'insieme è chiuso: un terreno
/// ignoto è respinto in caricamento, come i ganci delle caratteristiche (05 §7.7).
/// La mappa è interamente percorribile: nessun terreno è interdetto.
public enum TerrenoCasella: String, Codable, Hashable, Sendable, CaseIterable {
    /// La condizione ordinaria: non si annuncia (02 §8.7.1).
    case aperto
    /// Bosco o zona alberata: abilita la costruzione di macchine sul posto (01 §5.12).
    case bosco
    /// Acqua: fiume, rigagnolo, stagno o sorgente (01 §5.1.2).
    case acqua
}

/// I tipi di strada previsti (01 §5.5.3, §5.14.4). Il loro effetto sul ritmo di
/// marcia e sulla lunghezza della colonna è materia dell'unità successiva: qui la
/// strada è proprietà dichiarata della casella ed elemento di orientamento
/// (01 §5.14.4.1, «il tipo di strada fa parte di ciò che la casella dichiara»).
public enum TipoStrada: String, Codable, Hashable, Sendable, CaseIterable {
    /// La condizione ordinaria: non si annuncia (02 §8.7.1).
    case nessuna
    case sterrata
    case battuta
    case lastricata
}

/// Ciò che una casella dichiara oltre la condizione ordinaria (05 §7.6).
/// Nel file di mappa si elencano soltanto le caselle che si scostano
/// dall'ordinario: terreno aperto e nessuna strada non si scrivono.
public struct DescrizioneCasella: Codable, Hashable, Sendable {
    public let riga: Int
    public let colonna: Int
    public let terreno: TerrenoCasella
    public let strada: TipoStrada
    public init(riga: Int, colonna: Int, terreno: TerrenoCasella = .aperto,
                strada: TipoStrada = .nessuna) {
        self.riga = riga; self.colonna = colonna
        self.terreno = terreno; self.strada = strada
    }
    enum CodingKeys: String, CodingKey { case riga, colonna, terreno, strada }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        riga = try c.decode(Int.self, forKey: .riga)
        colonna = try c.decode(Int.self, forKey: .colonna)
        terreno = try c.decodeIfPresent(TerrenoCasella.self, forKey: .terreno) ?? .aperto
        strada = try c.decodeIfPresent(TipoStrada.self, forKey: .strada) ?? .nessuna
    }
}

/// La definizione dichiarativa di una mappa di campagna (05 §7.6). È contenuto e
/// non codice: le dimensioni vengono dal formato, le qualificazioni dalle voci.
public struct DefinizioneMappa: Codable, Hashable, Sendable {
    public let identificatore: IdentificatoreDati
    public let formato: IdentificatoreDati
    /// Le sole caselle che si scostano dalla condizione ordinaria.
    public let caselle: [DescrizioneCasella]
    /// La strettoia, al più una per mappa e non presente in ogni mappa (01 §5.1.3).
    public let strettoia: PosizioneMappa?
    /// I quartier generali, uno per parte, ciascuno in ultima riga dalla propria
    /// parte (01 §5.2.1, §5.14.3.2).
    public let quartierGenerali: QuartierGenerali

    enum CodingKeys: String, CodingKey {
        case identificatore, formato, caselle, strettoia
        case quartierGenerali = "quartier_generali"
    }
}

/// I due quartier generali di una mappa. Voci nominate anziché dizionario per
/// parte: un dizionario con chiave enumerativa obbligherebbe a rendere `Parte`
/// rappresentabile come chiave di codifica, il che cambierebbe la forma delle
/// istantanee di battaglia già scritte su disco. Il formato di salvataggio non
/// si tocca per una comodità di scrittura.
public struct QuartierGenerali: Codable, Hashable, Sendable {
    public let giocatore: PosizioneMappa
    public let avversario: PosizioneMappa
    public init(giocatore: PosizioneMappa, avversario: PosizioneMappa) {
        self.giocatore = giocatore; self.avversario = avversario
    }
    public func posizione(di parte: Parte) -> PosizioneMappa {
        parte == .giocatore ? giocatore : avversario
    }
}

/// Una posizione sulla mappa, come compare nei file dei dati. Il Motore la traduce
/// nel proprio tipo di cella: i Dati non conoscono la geometria.
public struct PosizioneMappa: Codable, Hashable, Sendable {
    public let riga: Int
    public let colonna: Int
    public init(riga: Int, colonna: Int) { self.riga = riga; self.colonna = colonna }
}

/// L'elenco chiuso e ordinato dei nomi che il gioco assegna ai gruppi (01 §5.6.0.4).
/// Il file dei valori dichiara le CHIAVI, in ordine fisso e prevedibile; il nome
/// parlato lo risolve il pacchetto dei testi, perché è testo (00 §14.1).
public struct NomiGruppi: Codable, Hashable, Sendable {
    public let chiavi: [IdentificatoreDati]
}

/// I valori della marcia (01 §5.6.3.1, §5.6.3.2). La velocità di una colonna si
/// manifesta come NUMERO DI GIORNI necessari a entrare in una casella adiacente:
/// non esistono percorsi di più caselle in un turno, e la casella resta l'unità
/// dello spostamento.
///
/// Su quella medesima grandezza — un solo numero, senza regole che si sommino in
/// modo opaco — agiscono la natura della casella di partenza e quella della casella
/// di arrivo con pesi distinti, il tipo di strada e il costo fisso della strettoia
/// (01 §5.6.3.2). Tutti confluiscono nel valore che `MotoreCampagna.costoInGiorni`
/// somma e satura a uno: nessuna regola separata, un solo numero. Il VOLUME della
/// colonna, quinto fattore di 01 §5.6.3.2, non agisce ancora perché il gruppo non
/// ha composizione in questa unità (`impatto-marcia-lunga.md` §1 lo rinvia): la
/// firma di `costoInGiorni` riceve già lo stato e vi leggerà il volume quando la
/// composizione esisterà, senza spostare il punto di calcolo (RDA-75). Tutti i pesi
/// sono PROVVISORI e si tarano giocando; il minimo di uno resta FISSATO (00 §13.6).
public struct ValoriMarcia: Codable, Hashable, Sendable {
    /// Il costo base in giorni dello scatto fra due caselle adiacenti. Provvisorio: uno.
    public let costoGiorniBase: Int
    /// Il numero delle posizioni in cui l'avanzamento visivo si discretizza dentro
    /// la casella (01 §5.6.3.4): nove, disposte a quadrato. FISSATO dal documento.
    public let posizioniVisive: Int
    /// Il peso della natura della casella DI PARTENZA, per terreno (chiave = rawValue
    /// di `TerrenoCasella`). Il costo grava sul tragitto reale, e i due pesi non sono
    /// necessariamente uguali (01 §5.6.3.2).
    public let pesoTerrenoPartenza: [String: Int]
    /// Il peso della natura della casella DI ARRIVO, per terreno.
    public let pesoTerrenoArrivo: [String: Int]
    /// L'effetto del tipo di strada della casella di arrivo (chiave = rawValue di
    /// `TipoStrada`): negativo per le strade che accorciano il tempo. Il costo non
    /// scende comunque sotto uno (saturazione nel Motore).
    public let pesoStradaArrivo: [String: Int]
    /// Il costo fisso aggiuntivo dell'attraversare la strettoia (01 §5.1.3, §5.6.3.2).
    public let costoStrettoia: Int
    /// Il volume oltre il quale la colonna spende un giorno in più (01 §5.6.3.2,
    /// quinto fattore): i giorni aggiuntivi sono il volume del gruppo diviso questa
    /// soglia, per troncamento. È il coefficiente che lega volume e costo (01 §5.6.3:
    /// «una colonna più voluminosa è più lunga e percorre meno strada»). PROVVISORIO
    /// e da tarare giocando; almeno uno, o la divisione sarebbe per zero.
    public let sogliaVolumePerGiornoAggiuntivo: Int

    public init(costoGiorniBase: Int, posizioniVisive: Int,
                pesoTerrenoPartenza: [String: Int], pesoTerrenoArrivo: [String: Int],
                pesoStradaArrivo: [String: Int], costoStrettoia: Int,
                sogliaVolumePerGiornoAggiuntivo: Int) {
        self.costoGiorniBase = costoGiorniBase
        self.posizioniVisive = posizioniVisive
        self.pesoTerrenoPartenza = pesoTerrenoPartenza
        self.pesoTerrenoArrivo = pesoTerrenoArrivo
        self.pesoStradaArrivo = pesoStradaArrivo
        self.costoStrettoia = costoStrettoia
        self.sogliaVolumePerGiornoAggiuntivo = sogliaVolumePerGiornoAggiuntivo
    }

    enum CodingKeys: String, CodingKey {
        case costoGiorniBase = "costo_giorni_base"
        case posizioniVisive = "posizioni_visive"
        case pesoTerrenoPartenza = "peso_terreno_partenza"
        case pesoTerrenoArrivo = "peso_terreno_arrivo"
        case pesoStradaArrivo = "peso_strada_arrivo"
        case costoStrettoia = "costo_strettoia"
        case sogliaVolumePerGiornoAggiuntivo = "soglia_volume_per_giorno_aggiuntivo"
    }
}

/// I valori del piano di campagna caricati e validati.
public struct ValoriCampagna: Sendable {
    public let formatiMappa: [IdentificatoreDati: FormatoMappa]
    public let mappe: [IdentificatoreDati: DefinizioneMappa]
    public let nomiGruppi: [IdentificatoreDati]
    public let marcia: ValoriMarcia

    public init(formatiMappa: [IdentificatoreDati: FormatoMappa],
                mappe: [IdentificatoreDati: DefinizioneMappa],
                nomiGruppi: [IdentificatoreDati], marcia: ValoriMarcia) {
        self.formatiMappa = formatiMappa
        self.mappe = mappe
        self.nomiGruppi = nomiGruppi
        self.marcia = marcia
    }
}
