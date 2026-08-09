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

/// Un reparto che compone un gruppo di campagna (01 §5.6.0): un archetipo e il
/// numero di atomi che vi sono schierati. È l'unità INTERA su cui lavora la
/// divisione (01 §5.6.0.2): «la divisione lavora su reparti interi e non sui
/// singoli atomi».
///
/// Il volume che ne discende (`MotoreCampagna.volume`) è la STESSA grandezza del
/// volume di battaglia, non una grandezza omonima: 01 §3.4.4 dichiara «il volume è
/// il parametro unico da cui dipendono tanto il costo di schieramento quanto la
/// velocità di marcia della colonna» ed è «unico e stabile per archetipo». Il
/// numero letto è lo stesso campo dell'archetipo, `volume_per_atomo`, che in
/// battaglia misura l'ingombro manovrabile (01 §9.5.0.2) e in campagna la
/// lunghezza della colonna (01 §5.6.3). Il budget di manovra della battaglia
/// (`BilancioVolume`) è invece un'altra cosa e conserva il proprio nome: qui non
/// entra. L'accertamento è dichiarato in RDA.
public struct Reparto: Hashable, Codable, Sendable {
    /// La chiave dell'archetipo nei dati di battaglia (01 §3.4): da esso si legge
    /// `volume_per_atomo`. Un archetipo ignoto è respinto dalla fabbrica.
    public let archetipo: IdentificatoreDati
    /// Il numero di atomi del reparto. Sempre positivo: un reparto senza atomi non
    /// esiste, e la fabbrica lo respinge (invariante «nessun gruppo vuoto»).
    public let atomi: Int

    public init(archetipo: IdentificatoreDati, atomi: Int) {
        self.archetipo = archetipo; self.atomi = atomi
    }
}

/// La CATEGORIA di una formazione sulla mappa di campagna (01 §5.2): tre e soltanto
/// tre — gruppi armati capaci di combattere, formazioni di ricognizione (esploratori),
/// formazioni non armate (catene di approvvigionamento e simili). Non è un'etichetta
/// accanto al gruppo ma un tipo con valore associato, sicché uno stato impossibile — un
/// gruppo armato con un carico da saccheggiare, un esploratore senza competenza — non è
/// rappresentabile e non solo sconsigliato.
///
/// La competenza dell'esploratore (01 §5.4.2, personale formato) è la grandezza da cui
/// discende DETERMINISTICAMENTE l'esito della ricognizione e del sabotaggio (01 §5.4,
/// §5.10.2): nessuna estrazione, il caso resta confinato al proprio perimetro (01 §12).
/// Il carico e la soglia di protezione della formazione non armata (01 §5.10.2) sono ciò
/// che il sabotaggio disperde e ciò che l'esploratore deve raggiungere per riuscirvi.
public enum CategoriaFormazione: Hashable, Codable, Sendable {
    /// Gruppo armato, capace di combattere (01 §5.2). La categoria ordinaria e, come
    /// tale, quella che la codifica dello scenario e l'impronta OMETTONO quando ricorre:
    /// gli scenari e i salvataggi scritti prima di questa unità restano identici al byte
    /// (RDA-113, e la stessa disciplina dei gruppi avversari omessi se vuoti).
    case armato
    /// Formazione di ricognizione, esploratori (01 §5.2): porta la propria COMPETENZA
    /// (01 §5.4.2). Non innesca mai una battaglia (01 §5.4.1) e non è soggetta al taglio
    /// del rifornimento (01 §5.15).
    case ricognizione(competenza: Int)
    /// Formazione non armata, catena di approvvigionamento e simili (01 §5.2): porta un
    /// CARICO e una SOGLIA DI PROTEZIONE dichiarata (01 §5.10.2). Non combatte, non
    /// esplora, non si mette in agguato; è bersaglio di sabotaggio e di studio approfondito.
    case nonArmata(carico: Int, sogliaProtezione: Int)

    /// Vero se è un esploratore.
    public var eRicognizione: Bool { if case .ricognizione = self { return true } else { return false } }
    /// Vero se è una formazione non armata.
    public var eNonArmata: Bool { if case .nonArmata = self { return true } else { return false } }
    /// Vero se è un gruppo armato.
    public var eArmata: Bool { if case .armato = self { return true } else { return false } }

    /// La competenza dell'esploratore, o nil per le altre categorie.
    public var competenza: Int? { if case .ricognizione(let c) = self { return c } else { return nil } }
    /// La soglia di protezione della formazione non armata, o nil per le altre.
    public var sogliaProtezione: Int? { if case .nonArmata(_, let s) = self { return s } else { return nil } }
    /// Il carico della formazione non armata, o nil per le altre.
    public var carico: Int? { if case .nonArmata(let c, _) = self { return c } else { return nil } }

    /// La chiave del TERMINE che nomina la categoria dell'occupante nell'annuncio
    /// (00 §14.1). Non è un termine nuovo del vocabolario chiuso di 02 §4.4.5 — che non
    /// contiene un insieme di categorie di formazione — ma un'etichetta composta dai
    /// termini del consolidato 01 §5.2, gemella di `casella.occupante_avversario` (S18):
    /// il segno disegnato e questo annuncio devono coincidere (prima correzione, incarico
    /// 19), e da qui discendono entrambi.
    public var chiaveCategoria: String {
        switch self {
        case .armato: return "categoria.gruppo_armato"
        case .ricognizione: return "categoria.ricognizione"
        case .nonArmata: return "categoria.non_armata"
        }
    }

    /// Un esemplare per ciascun caso, in ordine fisso, per le prove che pretendono che
    /// ogni categoria abbia il proprio termine e il proprio segno (come gli altri
    /// `casiDiRiferimento`).
    public static let casiDiRiferimento: [CategoriaFormazione] = [
        .armato, .ricognizione(competenza: 1), .nonArmata(carico: 1, sogliaProtezione: 1),
    ]
}

/// Un gruppo sulla mappa di campagna (01 §5.6.0): l'oggetto che dispone di
/// un'azione al giorno. Porta l'identità, il nome, la posizione, l'azione spesa,
/// l'eventuale marcia lunga in corso e la COMPOSIZIONE in reparti da cui discende
/// il volume (01 §5.6.0, §5.6.3); provviste e imboscata appartengono alle unità
/// successive.
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
    /// La composizione del gruppo (01 §5.6.0): i reparti di cui è fatto. Mai vuota
    /// — un gruppo senza reparti non esiste (01 §5.6.0.2, invariante `gruppoVuoto`).
    /// È `var` perché la divisione stacca reparti interi e la riunione li fonde
    /// (01 §5.6.0.2, §5.6.0.3, unità successiva). Il volume NON è un campo qui: è
    /// derivato dai reparti e dagli archetipi (`MotoreCampagna.volume`), sicché non
    /// può divergere dalla composizione — la sola via che rende impossibile lo stato
    /// sbagliato dell'invariante «il volume è la somma di ciò che lo compone».
    public var composizione: [Reparto]
    /// La CATEGORIA della formazione (01 §5.2): gruppo armato, ricognizione o non armata.
    /// Non muta nella vita del gruppo — un esploratore non diventa una colonna — e porta
    /// con sé ciò che la categoria richiede (competenza; carico e soglia). Da essa
    /// dipendono le azioni ammesse (01 §5.6.8.1), l'esenzione dal taglio (01 §5.15) e il
    /// segno sulla mappa (prima correzione, incarico 19). L'esploratore e la formazione
    /// non armata nascono dalla divisione conservando la categoria del gruppo di origine.
    public let categoria: CategoriaFormazione
    /// Vero se l'azione della giornata è stata spesa DAL GIOCATORE (01 §5.6). Un
    /// gruppo in marcia lunga ha l'azione consumata ma non spesa dal giocatore nei
    /// giorni successivi all'ordine (02 §6.5.1.2): per quei giorni `azioneSpesa` è
    /// falsa e `marcia` non nulla, e a distinguerli serve `marcia`, non `azioneSpesa`.
    public var azioneSpesa: Bool
    /// La marcia di più giorni in corso, se il gruppo ne ha una (01 §5.6.3.3).
    public var marcia: MarciaInCorso?
    /// I turni CONSECUTIVI in cui il gruppo ha operato con il rifornimento tagliato,
    /// da zero a due (01 §5.2.2.4): oltre il secondo non può proseguire e deve
    /// fermarsi. È il conteggio della mancanza di provviste, distinto per invariante
    /// da quello della marcia forzata.
    public var turniSenzaProvviste: Int
    /// I turni di SOSTA di rifornimento ancora dovuti, da zero a due (01 §5.2.2.4):
    /// finché è maggiore di zero il gruppo non può marciare, e ogni sosta lo riduce.
    public var sostaDovuta: Int
    /// I turni consecutivi di marcia forzata: SEPARATO da `turniSenzaProvviste`
    /// perché i due malus si cumulano e i loro conteggi restano distinti (01 §5.2.2.5).
    /// Predisposto e non ancora alimentato: la marcia forzata è materia successiva, e
    /// oggi questo campo resta a zero (dichiarato nel resoconto).
    public var turniMarciaForzata: Int
    /// Vero se il gruppo — armato — è APPOSTATO con l'ordine di imboscata (01 §5.11): resta
    /// fermo nella casella, consuma rifornimenti e non produce nulla (01 §5.11.3), e se un
    /// gruppo armato avversario vi entra l'imboscata scatta alla risoluzione di fine giornata
    /// (01 §5.6.11). Persiste attraverso le giornate senza un nuovo ordine — un gruppo in
    /// agguato ha CONCLUSO la giornata come uno inchiodato dalla marcia lunga — finché non
    /// scatta o il giocatore lo revoca. Solo un gruppo armato lo porta (invariante).
    public var ordineImboscata: Bool

    public init(id: IdGruppo, parte: Parte, nome: IdentificatoreDati,
                posizione: Cella, composizione: [Reparto],
                categoria: CategoriaFormazione = .armato,
                azioneSpesa: Bool, marcia: MarciaInCorso? = nil,
                turniSenzaProvviste: Int = 0, sostaDovuta: Int = 0, turniMarciaForzata: Int = 0,
                ordineImboscata: Bool = false) {
        self.id = id; self.parte = parte; self.nome = nome
        self.posizione = posizione; self.composizione = composizione
        self.categoria = categoria
        self.azioneSpesa = azioneSpesa; self.marcia = marcia
        self.turniSenzaProvviste = turniSenzaProvviste; self.sostaDovuta = sostaDovuta
        self.turniMarciaForzata = turniMarciaForzata
        self.ordineImboscata = ordineImboscata
    }

    /// Il numero totale di atomi del gruppo: la somma sui reparti. Serve alla
    /// riunione per stabilire «il maggiore dei due» (01 §5.6.0.4) senza gli
    /// archetipi, e al confronto della divisione.
    public var atomiTotali: Int { composizione.reduce(0) { $0 + $1.atomi } }

    /// Vero se il gruppo è impegnato in una marcia lunga.
    public var inMarcia: Bool { marcia != nil }

    /// Vero se il gruppo ha concluso la propria giornata, sia per averla spesa sia
    /// perché una marcia lunga o un ordine di imboscata gliela consuma senza comando del
    /// giocatore. È il criterio della chiusura automatica (01 §5.6.0.6) e dell'esclusione
    /// dal salto e dal rotore: un gruppo in marcia non attende alcuna decisione, e un
    /// gruppo appostato «non fa altro» (01 §5.6.0.5, §5.11.3) — resta in agguato attraverso
    /// le giornate senza babysitting, come uno inchiodato dalla marcia.
    public var haConclusoLaGiornata: Bool { azioneSpesa || inMarcia || ordineImboscata }

    /// Lo stato che il gruppo dichiara quando lo si incontra (01 §5.16.1, 02 §4.4.1.1).
    /// La marcia lunga porta con sé i giorni mancanti (02 §4.4.5, termine chiuso
    /// `gruppo.in_marcia` con il plurale sui giorni), e precede gli altri stati perché è
    /// la condizione più informativa; l'agguato la segue, perché non è deducibile dal
    /// fatto che il gruppo sia fermo (01 §5.16.1, 02 §6.5.3, termine chiuso «in agguato»).
    public var statoDichiarato: StatoGruppo {
        if let marcia { return .inMarcia(giorniMancanti: marcia.giorniMancanti) }
        if ordineImboscata { return .inAgguato }
        return azioneSpesa ? .haAgito : .inAttesa
    }

    /// Vero se il gruppo è un esploratore, esente dal taglio del rifornimento (01 §5.15):
    /// «le formazioni di ricognizione non sono soggette al taglio … vivono di autonomia e
    /// di raccolta automatica». Il loro costo è il rischio, non il rifornimento (01 §5.4).
    public var esenteDalTaglio: Bool { categoria.eRicognizione }

    /// Vero se il gruppo DEVE fermarsi a rifornirsi e non può marciare (01 §5.2.2.4):
    /// ha una sosta ancora dovuta. La validazione della marcia lo respinge.
    public var deveRifornirsi: Bool { sostaDovuta > 0 }
}

/// Gli stati di rifornimento del vocabolario chiuso (02 §4.4.5): esistono già come
/// termini e questa unità li rende esistenti nel gioco, senza aggiungerne di nuovi.
/// Il gruppo RIFORNITO è la condizione ordinaria e non ha termine, perché non si
/// annuncia (02 §8.7). L'ordine di precedenza — sosta, poi zona, poi senza provviste
/// — lo fissa `MotoreCampagna.statoDiRifornimento`.
public enum StatoRifornimento: Hashable, Sendable {
    /// «senza provviste, primo giorno» / «secondo giorno» (giorno = 1 o 2).
    case senzaProvviste(giorno: Int)
    /// «in sosta di rifornimento, con i giorni di sosta dovuti».
    case inSosta(giorniDovuti: Int)
    /// «in zona di rifornimento».
    case inZona

    /// La chiave del termine chiuso (00 §14.1): il testo lo risolve il pacchetto. Le
    /// chiavi ESISTONO GIÀ nel vocabolario (`rifornimento.*`, 02 §4.4.5): questa unità
    /// le usa, non ne conia. Il termine della sosta è «in sosta di rifornimento» come
    /// il consolidato lo fissa, senza il seguito «con i giorni di sosta dovuti» che
    /// l'incarico suggeriva: fra i due prevale il consolidato (scostamento S17).
    public var chiaveTesto: String {
        switch self {
        case .senzaProvviste(let giorno):
            return giorno >= 2 ? "rifornimento.senza_provviste_secondo" : "rifornimento.senza_provviste_primo"
        case .inSosta: return "rifornimento.in_sosta"
        case .inZona: return "rifornimento.in_zona"
        }
    }

    /// La privazione è ciò che si annuncia SULL'OCCUPANTE come sua prima anomalia
    /// (02 §3.8.1): senza provviste, oppure in sosta. La zona è invece una proprietà
    /// del LUOGO — la si annuncia in coda alla casella, con la strettoia — e un gruppo
    /// che vi sosta è semplicemente rifornito, che non si annuncia (02 §8.7).
    public var eDiPrivazione: Bool {
        switch self {
        case .senzaProvviste, .inSosta: return true
        case .inZona: return false
        }
    }

    /// Un esemplare per ciascun caso, in ordine fisso, per le prove che pretendono
    /// che ogni stato abbia il proprio termine (come `StatoGruppo.casiDiRiferimento`).
    public static let casiDiRiferimento: [StatoRifornimento] = [
        .senzaProvviste(giorno: 1), .senzaProvviste(giorno: 2),
        .inSosta(giorniDovuti: 1), .inZona,
    ]
}

/// Lo stato di conoscenza di una casella per una parte (01 §5.3, 02 §4.2): il
/// vocabolario chiuso — inesplorato, presunto, avvistato con i turni trascorsi,
/// confermato — esiste già come termine (`conoscenza.*`) e questa unità lo rende
/// esistente nel gioco senza ampliarlo. Il gioco non dichiara MAI il falso (01 §12):
/// questi stati descrivono che cosa una parte SA, e la mancanza di conoscenza non è
/// una menzogna — un gruppo appostato non è individuato perché la sua casella non è
/// confermata, non perché si sia mentito sul suo stato (01 §5.11.1).
///
/// Non è un campo grezzo dello stato: si DERIVA dall'età dell'informazione — i turni
/// trascorsi dall'ultima osservazione — con `da(eta:sogliaConfermato:)`. Il `presunto`
/// nasce solo dalla deduzione dell'itinerario (01 §5.10.1) ed è materia del blocco
/// della ricognizione: qui non si produce, ma il termine esiste per l'annuncio.
public enum StatoConoscenza: Hashable, Sendable {
    case inesplorato
    case presunto
    /// «avvistato» seguito dai turni trascorsi dall'ultima osservazione (02 §4.2).
    case avvistato(turni: Int)
    case confermato

    /// La chiave del termine chiuso già riservato (02 §4.2). «avvistato» porta i turni
    /// e passa dagli Annunci col plurale di sistema; gli altri sono termini semplici.
    public var chiaveTesto: String {
        switch self {
        case .inesplorato: return "conoscenza.inesplorato"
        case .presunto: return "conoscenza.presunto"
        case .avvistato: return "conoscenza.avvistato"
        case .confermato: return "conoscenza.confermato"
        }
    }

    /// Il CONFERMATO è la condizione ordinaria di ciò su cui si ha certezza e NON si
    /// annuncia (02 §3.8.1: lo stato di conoscenza si dichiara «se diverso da
    /// confermato»); gli altri tre si annunciano, in testa alla casella.
    public var siAnnuncia: Bool {
        if case .confermato = self { return false }
        return true
    }

    /// Deriva lo stato dall'ETÀ dell'informazione (turni dall'ultima osservazione) e
    /// dalla soglia oltre la quale il confermato decade in avvistato (03 §4.8.1).
    /// L'assenza di età significa mai osservata: inesplorato. Il presunto, che non
    /// dipende dall'età, non nasce da qui (01 §5.10.1, blocco successivo).
    public static func da(eta: Int?, sogliaConfermato: Int) -> StatoConoscenza {
        guard let eta else { return .inesplorato }
        return eta < sogliaConfermato ? .confermato : .avvistato(turni: eta)
    }

    public static let casiDiRiferimento: [StatoConoscenza] = [
        .inesplorato, .presunto, .avvistato(turni: 0), .confermato,
    ]
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
    /// Gruppo appostato con ordine di imboscata (01 §5.16.1, 02 §4.4.1.1, §6.5.3): il
    /// termine chiuso è «in agguato» (02 §4.4.5), che ESISTE GIÀ nel vocabolario e questa
    /// unità rende esistente nel gioco senza ampliarlo. Va dichiarato perché non è
    /// deducibile dal fatto che il gruppo sia fermo.
    case inAgguato

    /// La chiave del termine chiuso (00 §14.1): il traduttore vi risolve la frase.
    public var chiaveTesto: String {
        switch self {
        case .inAttesa: return "gruppo.in_attesa"
        case .haAgito: return "gruppo.ha_agito"
        case .inMarcia: return "gruppo.in_marcia"
        case .inAgguato: return "gruppo.in_agguato"
        }
    }

    /// Un esemplare per ciascun caso, in ordine fisso: sostituisce `CaseIterable`,
    /// che con il valore associato non si sintetizza, per le prove che pretendono
    /// che OGNI stato abbia il proprio termine (`TraduttoreCampagnaTest`).
    public static let casiDiRiferimento: [StatoGruppo] = [
        .inAttesa, .haAgito, .inMarcia(giorniMancanti: 1), .inAgguato,
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
/// Il registro annota i fatti che il giocatore NON ha deciso (01 §5.17.1), più poche
/// eccezioni volute dal titolare. L'ARRIVO di un proprio gruppo a destinazione — il
/// compimento di una marcia lunga — ESCE dal registro per decisione del titolare (incarico
/// 19): è un fatto che il giocatore ha deciso e già conosce, mentre il registro serve a
/// recuperare ciò che è accaduto mentre guardava altrove. L'annuncio dell'arrivo resta
/// (`EventoCampagna.marciaCompiuta`, col richiamo tattile del completamento di marcia,
/// 02 §11.7.1); soltanto la voce di registro se ne va. Restano la revoca — per VOLONTÀ del
/// titolare benché decisa dal giocatore, perché spiega perché un gruppo si trovi fermo
/// (RDA-104) —, gli annullamenti, gli avvistamenti e i fatti del rifornimento. Vi ENTRANO i
/// fatti nuovi di questa unità: esploratori perduti e notati, formazione sabotata e
/// studiata, imboscata scattata, direzione di marcia dedotta (incarico 19, 01 §5.17.1).
///
/// Ogni caso porta con sé ciò che la frase deve dichiarare: il registro non
/// ricalcola nulla e non rilegge lo stato, perché la voce racconta il momento in
/// cui il fatto è avvenuto e non quello in cui la si legge.
public enum FattoRegistrato: Hashable, Codable, Sendable {
    /// Un ordine di marcia è stato revocato (01 §5.6.3.3): il gruppo perde i giorni
    /// spesi e resta nella casella di partenza. Mossa di gioco, non annullamento
    /// (RDA-76); resta nel registro per volontà del titolare (RDA-104), eccezione
    /// voluta, perché spiega perché un gruppo si trovi fermo.
    case marciaRevocata(gruppo: IdentificatoreDati, casella: Cella)
    /// L'ultimo ordine è stato ritirato (00 §13.8).
    case ordineAnnullato
    /// Gli ordini della giornata sono stati azzerati (00 §13.8).
    case giornataAzzerata
    /// Il rifornimento di un gruppo si è interrotto: forze nemiche alle sue spalle
    /// (01 §5.2.2.2). Fatto NON deciso dal giocatore (01 §5.17.1) — entra nel registro.
    case rifornimentoInterrotto(gruppo: IdentificatoreDati, casella: Cella)
    /// Un gruppo è stato costretto alla sosta di rifornimento (01 §5.2.2.4): compiuti
    /// i turni senza provviste, deve fermarsi. Fatto non deciso dal giocatore.
    case sostaDiRifornimento(gruppo: IdentificatoreDati, casella: Cella)
    /// Il rifornimento di un gruppo è ripreso (01 §5.2.2): non ha più nemici alle
    /// spalle, o è entrato in una zona di rifornimento. Fatto non deciso dal giocatore.
    case rifornimentoRipreso(gruppo: IdentificatoreDati, casella: Cella)
    /// Una formazione avversaria è stata avvistata dal giocatore in una casella che
    /// osserva (01 §5.6.11, §5.17.1, 02 §8.2.1): la mossa avversaria di cui il giocatore
    /// «abbia notizia» entra nel registro, ed è attivabile per portare il fuoco sul
    /// luogo (02 §6.6). NON porta il nome della formazione né il volume (02 §6.4.1): il
    /// registro annota il fatto — una formazione avversaria, e dove — e nulla di più.
    /// È annotata SOLO dove il giocatore osserva (conoscenza confermato): un avvistamento
    /// su una casella non osservata non entra mai nel registro, o il registro darebbe al
    /// giocatore informazione che la sua conoscenza non gli ha dato.
    case formazioneAvversariaAvvistata(casella: Cella)
    /// Gli esploratori si sono PERDUTI durante una ricognizione (01 §5.4): la formazione di
    /// ricognizione è andata perduta — personale formato che non si rimpiazza in un turno
    /// (01 §5.4.2) — nella casella da cui esplorava. Fatto non deciso dal giocatore, del
    /// SOLO giocatore: gli esploratori dell'avversario che si perdono non entrano nel suo
    /// registro. Porta il nome della propria formazione perduta.
    case esploratoriPerduti(gruppo: IdentificatoreDati, casella: Cella)
    /// Gli esploratori si sono fatti NOTARE (01 §5.4, §5.10.2): la loro casella è ora
    /// avvistata per l'avversario. Fatto non deciso, del solo giocatore, col nome e il luogo.
    case esploratoriNotati(gruppo: IdentificatoreDati, casella: Cella)
    /// Una formazione non armata è stata SABOTATA (01 §5.10.2): dispersa, il suo carico
    /// perduto. Il sabotaggio è sempre fra parti opposte, sicché tocca sempre il giocatore —
    /// come sabotatore o come vittima — e la voce vi entra col luogo. Non porta il nome
    /// della formazione (02 §6.4.1): il fatto, e dove.
    case formazioneSabotata(casella: Cella)
    /// Una formazione non armata avversaria è stata STUDIATA a fondo dagli esploratori del
    /// giocatore (01 §5.10.2): composizione, carico e direzione sono ora confermati. Del
    /// solo giocatore che studia; col luogo.
    case formazioneStudiata(casella: Cella)
    /// Un'IMBOSCATA è scattata (01 §5.11, §5.17.1): un gruppo armato avversario è entrato
    /// nella casella di un gruppo appostato. Lo scatto è sempre fra parti opposte e tocca
    /// sempre il giocatore — come imboscante o come vittima — e la voce vi entra col luogo.
    case imboscataScattata(casella: Cella)
    /// DEDUZIONE sulla direzione di marcia di una colonna (01 §5.10.1): gli esploratori del
    /// giocatore hanno rilevato una colonna avversaria muoversi lungo una strada per due
    /// caselle consecutive e se ne deduce che la segua. Del solo giocatore; il luogo è la
    /// casella in cui la colonna è stata osservata, da cui la deduzione si proietta.
    case direzioneDedotta(casella: Cella)

    /// Un esemplare per ciascun caso, in ordine fisso. Serve al collaudo per
    /// pretendere che OGNI fatto abbia la propria frase compiuta: con i valori
    /// associati `CaseIterable` non si sintetizza, e senza questo elenco un fatto
    /// aggiunto senza frase passerebbe inosservato — la stessa ragione per cui
    /// esiste l'elenco dei codici degli invarianti.
    public static let casiDiRiferimento: [FattoRegistrato] = [
        .marciaRevocata(gruppo: "corvo", casella: Cella(riga: 1, colonna: 1)),
        .ordineAnnullato,
        .giornataAzzerata,
        .rifornimentoInterrotto(gruppo: "corvo", casella: Cella(riga: 1, colonna: 1)),
        .sostaDiRifornimento(gruppo: "corvo", casella: Cella(riga: 1, colonna: 1)),
        .rifornimentoRipreso(gruppo: "corvo", casella: Cella(riga: 1, colonna: 1)),
        .formazioneAvversariaAvvistata(casella: Cella(riga: 1, colonna: 1)),
        .esploratoriPerduti(gruppo: "corvo", casella: Cella(riga: 1, colonna: 1)),
        .esploratoriNotati(gruppo: "corvo", casella: Cella(riga: 1, colonna: 1)),
        .formazioneSabotata(casella: Cella(riga: 1, colonna: 1)),
        .formazioneStudiata(casella: Cella(riga: 1, colonna: 1)),
        .imboscataScattata(casella: Cella(riga: 1, colonna: 1)),
        .direzioneDedotta(casella: Cella(riga: 1, colonna: 1)),
    ]

    /// La chiave del testo che compone la frase della voce (00 §14.1): il fatto
    /// non conosce la frase, la nomina soltanto.
    public var chiaveTesto: String {
        switch self {
        case .marciaRevocata: return "registro.marcia_revocata"
        case .ordineAnnullato: return "registro.ordine_annullato"
        case .giornataAzzerata: return "registro.giornata_azzerata"
        case .rifornimentoInterrotto: return "registro.rifornimento_interrotto"
        case .sostaDiRifornimento: return "registro.sosta_di_rifornimento"
        case .rifornimentoRipreso: return "registro.rifornimento_ripreso"
        case .formazioneAvversariaAvvistata: return "registro.formazione_avvistata"
        case .esploratoriPerduti: return "registro.esploratori_perduti"
        case .esploratoriNotati: return "registro.esploratori_notati"
        case .formazioneSabotata: return "registro.formazione_sabotata"
        case .formazioneStudiata: return "registro.formazione_studiata"
        case .imboscataScattata: return "registro.imboscata_scattata"
        case .direzioneDedotta: return "registro.direzione_dedotta"
        }
    }

    /// Il luogo del fatto, quando ne ha uno (02 §6.6): attivando la voce il fuoco
    /// vi si porta. Gli annullamenti non ne hanno, perché ritirano un ordine e non
    /// accadono in una casella.
    public var luogo: Cella? {
        switch self {
        case .marciaRevocata(_, let casella): return casella
        case .rifornimentoInterrotto(_, let casella): return casella
        case .sostaDiRifornimento(_, let casella): return casella
        case .rifornimentoRipreso(_, let casella): return casella
        case .formazioneAvversariaAvvistata(let casella): return casella
        case .esploratoriPerduti(_, let casella): return casella
        case .esploratoriNotati(_, let casella): return casella
        case .formazioneSabotata(let casella): return casella
        case .formazioneStudiata(let casella): return casella
        case .imboscataScattata(let casella): return casella
        case .direzioneDedotta(let casella): return casella
        case .ordineAnnullato, .giornataAzzerata: return nil
        }
    }
}

/// Un'imboscata SCATTATA in attesa di diventare battaglia (01 §5.11.2, §9.3.2): quando un
/// gruppo armato avversario entra nella casella di un gruppo appostato, l'imboscata scatta e
/// il vantaggio dell'imboscante — turni di gioco in più e sconto sul piazzaggio (01 §9.3.2) —
/// è materia della BATTAGLIA, che questa sessione non costruisce. Lo scatto si registra qui,
/// nello stato, dichiarando che cosa la sessione del passaggio alla battaglia dovrà
/// raccogliere: la casella, chi imboscava (che avrà il vantaggio), e il gruppo intruso. Quella
/// sessione leggerà questa lista per aprire la battaglia da imboscata con l'ordine dei turni di
/// 01 §9.4.1 e il vantaggio di 01 §9.3.2; questa la riempie soltanto (RDA-98, il passo già
/// preparato). Nulla la consuma ancora: resta a testimoniare che lo scatto è avvenuto.
public struct ImboscataInSospeso: Hashable, Codable, Sendable {
    /// La casella dove l'imboscata è scattata: il futuro campo di battaglia.
    public let casella: Cella
    /// La parte che imboscava, cui spetta il vantaggio della sorpresa (01 §9.3.2).
    public let imboscante: Parte
    /// Il gruppo armato avversario entrato nella casella, che subisce l'imboscata.
    public let intruso: IdGruppo
    /// Il giorno in cui l'imboscata è scattata.
    public let giorno: Int

    public init(casella: Cella, imboscante: Parte, intruso: IdGruppo, giorno: Int) {
        self.casella = casella; self.imboscante = imboscante
        self.intruso = intruso; self.giorno = giorno
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
    /// Le caselle occupate da forze nemiche (01 §5.2.2.2): ciò che sta alle spalle di
    /// una colonna e ne taglia il rifornimento. L'AVVERSARIO sulla mappa NON esiste
    /// ancora (materia della sessione successiva): questo è il MINIMO indispensabile a
    /// rendere provabile la regola del taglio, un dato dello scenario, e non
    /// l'avversario — dichiarato come anticipazione parziale. In gioco reale è vuoto,
    /// sicché oggi nessun gruppo risulta mai tagliato.
    public var forzeNemiche: Set<Cella>
    /// Le caselle con una struttura di rifornimento — fortezza o magazzino avanzato
    /// (01 §5.2.2.6). Le OPERE non esistono ancora (materia della sessione successiva):
    /// questo è il minimo per rendere provabile la zona di rifornimento, dato dello
    /// scenario, non l'opera. In gioco reale è vuoto.
    public var struttureDiRifornimento: Set<Cella>
    /// La MEMORIA di conoscenza di ciascuna parte: per ogni casella già osservata,
    /// i turni trascorsi dall'ultima osservazione (01 §5.3). L'assenza di una casella
    /// significa mai osservata (inesplorato). L'osservazione CORRENTE — ciò che una
    /// formazione vede ora attorno a sé — non sta qui ma si deriva dalle posizioni
    /// (`MotoreCampagna.conoscenza`), e questa mappa conserva solo il ricordo che
    /// invecchia a ogni fine giornata (`invecchiaLaConoscenza`). Non è nel giornale:
    /// si ricostruisce rigiocando, sicché non tocca lo schema; entra però nell'impronta,
    /// perché due partite con memorie diverse non sono lo stesso stato.
    public var conoscenza: [Parte: [Cella: Int]]
    /// Le caselle che ciascuna parte PRESUME occupate da una colonna avversaria (01 §5.3,
    /// §5.10.1): il seguito dell'itinerario dedotto dagli esploratori quando una colonna si
    /// muove lungo una strada per due caselle consecutive. Danno lo stato di conoscenza
    /// `presunto`, che NON nasce dall'età (a differenza di avvistato) ma dalla deduzione, ed
    /// è la sola sua sorgente (RDA-110). Si azzerano e si ricalcolano a ogni fine giornata
    /// dagli avvistamenti freschi: una presunzione non osservata invecchia con la casella su
    /// cui poggia. Vuote in una partita senza esploratori che deducano.
    public var presunti: [Parte: Set<Cella>]
    /// La MEMORIA per-formazione dell'ultima posizione in cui una parte ha osservato una
    /// formazione AVVERSARIA (01 §5.10.1): per ciascuna parte osservatrice, la casella dove
    /// ha visto l'ultima volta ogni gruppo avversario, per identificatore. È ciò che rende
    /// possibile la deduzione dell'itinerario — «mossa lungo una strada per due caselle
    /// consecutive» richiede di ricordare dov'era la colonna il turno prima — che 01 §5.10.1
    /// e RDA-110 rinviavano esplicitamente a questo blocco (S18). L'identificatore serve solo
    /// internamente: il giocatore non riceve mai il nome della colonna (02 §6.4.1). Entra
    /// nell'impronta come la conoscenza; vuota senza esploratori attivi.
    public var ultimaPosizioneNota: [Parte: [IdGruppo: Cella]]
    /// Le formazioni AVVERSARIE che una parte ha STUDIATO a fondo (01 §5.10.2): per
    /// identificatore. Lo studio porta a confermato la conoscenza della formazione studiata —
    /// composizione, carico e direzione — e quella conoscenza PERSISTE anche se la formazione
    /// esce dall'osservazione: si è appreso ciò che quella colonna trasporta. Il giocatore
    /// riceve i dettagli solo dove la osserva (confermato) E l'ha studiata. Vuota senza studi;
    /// entra nell'impronta come la conoscenza.
    public var studiati: [Parte: Set<IdGruppo>]
    /// Le imboscate SCATTATE in attesa di diventare battaglia (01 §5.11.2): riempita dallo
    /// scatto di fine giornata, la raccoglierà la sessione del passaggio alla battaglia. Vuota
    /// finché nessuna imboscata scatta; entra nell'impronta, perché due partite in cui
    /// un'imboscata è scattata o no non sono lo stesso stato.
    public var imboscateInSospeso: [ImboscataInSospeso]

    public init(mappa: MappaCampagna, giorno: Int, gruppi: [IdGruppo: Gruppo],
                prossimoIdGruppo: Int, prossimoIndiceNome: Int,
                registro: [VoceRegistro], prossimoNumeroVoce: Int,
                forzeNemiche: Set<Cella> = [], struttureDiRifornimento: Set<Cella> = [],
                conoscenza: [Parte: [Cella: Int]] = [:],
                presunti: [Parte: Set<Cella>] = [:],
                ultimaPosizioneNota: [Parte: [IdGruppo: Cella]] = [:],
                studiati: [Parte: Set<IdGruppo>] = [:],
                imboscateInSospeso: [ImboscataInSospeso] = []) {
        self.mappa = mappa; self.giorno = giorno; self.gruppi = gruppi
        self.prossimoIdGruppo = prossimoIdGruppo
        self.prossimoIndiceNome = prossimoIndiceNome
        self.registro = registro; self.prossimoNumeroVoce = prossimoNumeroVoce
        self.forzeNemiche = forzeNemiche; self.struttureDiRifornimento = struttureDiRifornimento
        self.conoscenza = conoscenza
        self.presunti = presunti
        self.ultimaPosizioneNota = ultimaPosizioneNota
        self.studiati = studiati
        self.imboscateInSospeso = imboscateInSospeso
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
