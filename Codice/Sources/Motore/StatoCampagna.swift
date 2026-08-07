import Foundation
import Dati

/// Identificatore stabile di un gruppo, assegnato dal Motore in modo deterministico
/// (05 §2.8): contatore nello stato, mai valori casuali né orologio.
public struct IdGruppo: Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    public let numero: Int
    public init(_ numero: Int) { self.numero = numero }
    public static func < (a: IdGruppo, b: IdGruppo) -> Bool { a.numero < b.numero }
    public var description: String { "gruppo-\(numero)" }
}

/// La marcia di più giorni in corso per un gruppo (01 §5.6.3.3). Finché non ha
/// compiuto i giorni necessari il gruppo resta nella casella di partenza — che è la
/// sua `posizione` — e questo stato porta soltanto la destinazione e il conto dei
/// giorni. NON esiste alcuno stato intermedio fra due caselle: la posizione è sempre
/// una casella reale, e i giorni compiuti sono sempre minori di quelli totali,
/// perché nel momento in cui li eguagliano la marcia si compie e il gruppo si muove
/// (`MotoreCampagna.risolviFineGiornata`).
public struct MarciaInCorso: Hashable, Codable, Sendable {
    /// La casella adiacente verso cui il gruppo marcia (01 §5.6.3.1): mai un percorso.
    public let destinazione: Cella
    /// I giorni necessari allo scatto, calcolati alla conferma e conservati: il
    /// costo non si ricalcola mentre la marcia procede (RDA-75).
    public let giorniTotali: Int
    /// I giorni già spesi. Cresce di uno a ogni chiusura di giornata, per saturazione
    /// a `giorniTotali` (dove la marcia si compie). Invariante: `0 ..< giorniTotali`.
    public var giorniCompiuti: Int

    public init(destinazione: Cella, giorniTotali: Int, giorniCompiuti: Int) {
        self.destinazione = destinazione
        self.giorniTotali = giorniTotali
        self.giorniCompiuti = giorniCompiuti
    }

    /// I giorni ancora mancanti, che il gioco dichiara (01 §5.6.3.3): la grandezza di
    /// origine, quella che chi ascolta riceve. Sempre positiva mentre la marcia è in
    /// corso, perché a zero la marcia si è già compiuta.
    public var giorniMancanti: Int { giorniTotali - giorniCompiuti }
}

/// Un gruppo sulla mappa di campagna (01 §5.6.0): l'oggetto che dispone di
/// un'azione al giorno. In questa unità porta l'identità, il nome, la posizione,
/// l'azione spesa e l'eventuale marcia lunga in corso; composizione, provviste e
/// imboscata appartengono alle unità successive.
public struct Gruppo: Hashable, Codable, Sendable {
    public let id: IdGruppo
    public let parte: Parte
    /// La chiave del nome, presa dall'elenco chiuso e ordinato dei dati
    /// (01 §5.6.0.4): breve, stabile, conservata per tutta l'esistenza del gruppo.
    /// Il nome parlato lo risolve il pacchetto dei testi, perché è testo (00 §14.1).
    /// Vive nello stato e non si ricalcola dall'elenco: un gruppo conserva il
    /// proprio nome anche se l'elenco dei dati cambia.
    public let nome: IdentificatoreDati
    public var posizione: Cella
    /// Vero se l'azione della giornata è stata spesa DAL GIOCATORE (01 §5.6). Un
    /// gruppo in marcia lunga ha l'azione consumata ma non spesa dal giocatore nei
    /// giorni successivi all'ordine (02 §6.5.1.2): per quei giorni `azioneSpesa` è
    /// falsa e `marcia` non nulla, e a distinguerli serve `marcia`, non `azioneSpesa`.
    public var azioneSpesa: Bool
    /// La marcia di più giorni in corso, se il gruppo ne ha una (01 §5.6.3.3).
    public var marcia: MarciaInCorso?

    public init(id: IdGruppo, parte: Parte, nome: IdentificatoreDati,
                posizione: Cella, azioneSpesa: Bool, marcia: MarciaInCorso? = nil) {
        self.id = id; self.parte = parte; self.nome = nome
        self.posizione = posizione; self.azioneSpesa = azioneSpesa; self.marcia = marcia
    }

    /// Vero se il gruppo è impegnato in una marcia lunga.
    public var inMarcia: Bool { marcia != nil }

    /// Vero se il gruppo ha concluso la propria giornata, sia per averla spesa sia
    /// perché una marcia lunga gliela consuma senza comando del giocatore. È il
    /// criterio della chiusura automatica (01 §5.6.0.6) e dell'esclusione dal salto
    /// e dal rotore: un gruppo in marcia non attende alcuna decisione.
    public var haConclusoLaGiornata: Bool { azioneSpesa || inMarcia }

    /// Lo stato che il gruppo dichiara quando lo si incontra (01 §5.16.1, 02 §4.4.1.1).
    /// La marcia lunga porta con sé i giorni mancanti (02 §4.4.5, termine chiuso
    /// `gruppo.in_marcia` con il plurale sui giorni), e precede gli altri due stati
    /// perché è la condizione più informativa.
    public var statoDichiarato: StatoGruppo {
        if let marcia { return .inMarcia(giorniMancanti: marcia.giorniMancanti) }
        return azioneSpesa ? .haAgito : .inAttesa
    }
}

/// I termini chiusi degli stati di un gruppo realizzati in questa unità
/// (02 §4.4.5: «in attesa», «ha agito», «in marcia» con i giorni mancanti). Gli
/// altri termini dell'insieme — in agguato, scatto disponibile, e gli stati di
/// rifornimento — esistono nei documenti e si aggiungono qui quando la regola che
/// li produce esiste. Non è più un enumerativo a valore grezzo di stringa perché
/// «in marcia» porta con sé una grandezza, i giorni mancanti; la chiave del testo
/// resta esplicita in `chiaveTesto`.
public enum StatoGruppo: Hashable, Codable, Sendable {
    case inAttesa
    case haAgito
    case inMarcia(giorniMancanti: Int)

    /// La chiave del termine chiuso (00 §14.1): il traduttore vi risolve la frase.
    public var chiaveTesto: String {
        switch self {
        case .inAttesa: return "gruppo.in_attesa"
        case .haAgito: return "gruppo.ha_agito"
        case .inMarcia: return "gruppo.in_marcia"
        }
    }

    /// Un esemplare per ciascun caso, in ordine fisso: sostituisce `CaseIterable`,
    /// che con il valore associato non si sintetizza, per le prove che pretendono
    /// che OGNI stato abbia il proprio termine (`TraduttoreCampagnaTest`).
    public static let casiDiRiferimento: [StatoGruppo] = [
        .inAttesa, .haAgito, .inMarcia(giorniMancanti: 1),
    ]
}

/// Una voce del registro degli eventi della campagna (01 §5.17, 02 §6.6).
/// Vi entrano soltanto i fatti che il giocatore non ha deciso (01 §5.17.1).
public struct VoceRegistro: Hashable, Codable, Sendable {
    public let numero: Int
    /// Il giorno cui la voce si riferisce, dichiarato nell'annuncio (02 §6.6).
    public let giorno: Int
    public let fatto: FattoRegistrato

    public init(numero: Int, giorno: Int, fatto: FattoRegistrato) {
        self.numero = numero; self.giorno = giorno; self.fatto = fatto
    }

    /// Il luogo del fatto, quando ne ha uno (02 §6.6). Deriva dal fatto e non è
    /// un campo a sé: due sorgenti per la stessa cosa possono divergere, una no.
    public var luogo: Cella? { fatto.luogo }
}

/// I fatti che il registro sa annotare. Insieme chiuso, come ogni vocabolario del
/// gioco.
///
/// Con questa unità compaiono i PRIMI fatti non decisi dal giocatore: il
/// completamento di una marcia lunga (01 §5.17.1). Ciò riapre la deroga di RDA-72,
/// per cui il registro annotava soltanto gli ordini del giocatore in assenza
/// d'altro (scostamento S8, in deroga a 01 §5.17.1 che gli ordini li esclude). Il
/// RIESAME: gli ordini RESTANO nel registro accanto ai fatti nuovi. La ragione è
/// che 01 §5.17 giustifica il registro con il recupero degli annunci persi mentre
/// il giocatore fa altro, e nel perimetro attuale — solo, senza avversario né fatti
/// frequenti — un registro dei soli completamenti sarebbe quasi vuoto e perderebbe
/// gli annullamenti, che RDA-72 dichiara fatti ricostruibili; togliere gli ordini
/// cambierebbe ciò che il giocatore sente in peggio. La deroga S8 resta dichiarata
/// e si risolverà quando i fatti avversari frequenti e mancabili esisteranno, cioè
/// nella sessione di riallineamento (RDA-101).
///
/// Ogni caso porta con sé ciò che la frase deve dichiarare: il registro non
/// ricalcola nulla e non rilegge lo stato, perché la voce racconta il momento in
/// cui il fatto è avvenuto e non quello in cui la si legge.
public enum FattoRegistrato: Hashable, Codable, Sendable {
    /// Un gruppo ha ricevuto l'ordine di marciare in una casella adiacente.
    case marciaOrdinata(gruppo: IdentificatoreDati, da: Cella, a: Cella)
    /// Un gruppo ha ricevuto l'ordine di restare fermo in guardia (01 §5.6.0.6).
    case presidioOrdinato(gruppo: IdentificatoreDati, casella: Cella)
    /// Una marcia lunga si è compiuta alla chiusura della giornata (01 §5.17.1): il
    /// PRIMO fatto non deciso dal giocatore, e il primo che esercita il salto al
    /// luogo del fatto, essendo `a` una casella reale (RDA-67).
    case marciaCompiuta(gruppo: IdentificatoreDati, da: Cella, a: Cella)
    /// Un ordine di marcia è stato revocato (01 §5.6.3.3): il gruppo perde i giorni
    /// spesi e resta nella casella di partenza. Mossa di gioco, non annullamento (RDA-76).
    case marciaRevocata(gruppo: IdentificatoreDati, casella: Cella)
    /// L'ultimo ordine è stato ritirato (00 §13.8).
    case ordineAnnullato
    /// Gli ordini della giornata sono stati azzerati (00 §13.8).
    case giornataAzzerata

    /// Un esemplare per ciascun caso, in ordine fisso. Serve al collaudo per
    /// pretendere che OGNI fatto abbia la propria frase compiuta: con i valori
    /// associati `CaseIterable` non si sintetizza, e senza questo elenco un fatto
    /// aggiunto senza frase passerebbe inosservato — la stessa ragione per cui
    /// esiste l'elenco dei codici degli invarianti.
    public static let casiDiRiferimento: [FattoRegistrato] = [
        .marciaOrdinata(gruppo: "corvo",
                        da: Cella(riga: 1, colonna: 1), a: Cella(riga: 1, colonna: 2)),
        .presidioOrdinato(gruppo: "corvo", casella: Cella(riga: 1, colonna: 1)),
        .marciaCompiuta(gruppo: "corvo",
                        da: Cella(riga: 1, colonna: 1), a: Cella(riga: 1, colonna: 2)),
        .marciaRevocata(gruppo: "corvo", casella: Cella(riga: 1, colonna: 1)),
        .ordineAnnullato,
        .giornataAzzerata,
    ]

    /// La chiave del testo che compone la frase della voce (00 §14.1): il fatto
    /// non conosce la frase, la nomina soltanto.
    public var chiaveTesto: String {
        switch self {
        case .marciaOrdinata: return "registro.marcia_ordinata"
        case .presidioOrdinato: return "registro.presidio_ordinato"
        case .marciaCompiuta: return "registro.marcia_compiuta"
        case .marciaRevocata: return "registro.marcia_revocata"
        case .ordineAnnullato: return "registro.ordine_annullato"
        case .giornataAzzerata: return "registro.giornata_azzerata"
        }
    }

    /// Il luogo del fatto, quando ne ha uno (02 §6.6): attivando la voce il fuoco
    /// vi si porta. Gli annullamenti non ne hanno, perché ritirano un ordine e non
    /// accadono in una casella.
    public var luogo: Cella? {
        switch self {
        case .marciaOrdinata(_, _, let a): return a
        case .presidioOrdinato(_, let casella): return casella
        case .marciaCompiuta(_, _, let a): return a
        case .marciaRevocata(_, let casella): return casella
        case .ordineAnnullato, .giornataAzzerata: return nil
        }
    }
}

/// Lo stato completo di una campagna (05 §2.6). Un valore, interamente Codable,
/// senza alcun riferimento a schermate o annunci (00 §3.2).
public struct StatoCampagna: Hashable, Codable, Sendable {
    /// La mappa: riferimento alla definizione nei Contenuti più ciò che ne serve
    /// al Motore. In questa unità le caselle non hanno stato mutevole.
    public let mappa: MappaCampagna
    /// La data propria della campagna (01 §5.6.9.1): il giorno È il turno (05 §2.2.2).
    public var giorno: Int
    public var gruppi: [IdGruppo: Gruppo]
    /// Contatore per gli identificatori, deterministico (05 §2.8).
    public var prossimoIdGruppo: Int
    /// Indice del prossimo nome da assegnare: i nomi non si riusano (01 §5.6.0.4).
    public var prossimoIndiceNome: Int
    /// Il registro cronologico, dal più recente al meno recente in presentazione;
    /// qui si conserva in ordine di accadimento e si legge al contrario (02 §6.6).
    public var registro: [VoceRegistro]
    public var prossimoNumeroVoce: Int

    public init(mappa: MappaCampagna, giorno: Int, gruppi: [IdGruppo: Gruppo],
                prossimoIdGruppo: Int, prossimoIndiceNome: Int,
                registro: [VoceRegistro], prossimoNumeroVoce: Int) {
        self.mappa = mappa; self.giorno = giorno; self.gruppi = gruppi
        self.prossimoIdGruppo = prossimoIdGruppo
        self.prossimoIndiceNome = prossimoIndiceNome
        self.registro = registro; self.prossimoNumeroVoce = prossimoNumeroVoce
    }

    public var griglia: GrigliaCampagna { mappa.griglia }

    /// Ordine deterministico dei gruppi (per risoluzioni, rotori e impronte).
    public var gruppiOrdinati: [Gruppo] { gruppi.values.sorted { $0.id < $1.id } }

    /// Il gruppo che occupa una casella, se esiste. Derivato dai fatti, mai duplicato.
    /// Ogni casella contiene al massimo una formazione per parte (01 §5.6.0.2).
    public func occupante(di casella: Cella, parte: Parte = .giocatore) -> Gruppo? {
        gruppi.values.first { $0.posizione == casella && $0.parte == parte }
    }

    /// I propri gruppi che non hanno ancora agito, in ordine di lettura della
    /// casella: alimenta il conteggio dello stato e il salto diretto (02 §6.5.1, §7.3).
    /// Un gruppo in marcia lunga NON vi compare, perché non attende alcuna decisione:
    /// la sua giornata è consumata dalla marcia (01 §5.16.1, `haConclusoLaGiornata`).
    public func gruppiInAttesa(di parte: Parte = .giocatore) -> [Gruppo] {
        gruppi.values
            .filter { $0.parte == parte && !$0.haConclusoLaGiornata }
            .sorted { $0.posizione == $1.posizione ? $0.id < $1.id : $0.posizione < $1.posizione }
    }

    /// I propri gruppi impegnati in una marcia lunga, in ordine di lettura:
    /// l'informazione di stato li dichiara a parte (01 §5.16).
    public func gruppiInMarcia(di parte: Parte = .giocatore) -> [Gruppo] {
        gruppi.values
            .filter { $0.parte == parte && $0.inMarcia }
            .sorted { $0.posizione == $1.posizione ? $0.id < $1.id : $0.posizione < $1.posizione }
    }

    public func gruppi(di parte: Parte) -> [Gruppo] {
        gruppi.values.filter { $0.parte == parte }
            .sorted { $0.posizione == $1.posizione ? $0.id < $1.id : $0.posizione < $1.posizione }
    }
}
