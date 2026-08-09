import Foundation
import Dati

/// La vista RISTRETTA su cui decide l'avversario (01 §5.6.11, §5.11.1, incarico 18).
///
/// È un valore AUTOSUFFICIENTE e non porta alcun riferimento allo `StatoCampagna`: vi
/// stanno i propri gruppi per intero, la geografia (pubblica: mappa, quartier generali,
/// terreno, strada, strettoia), i valori della marcia e del carattere, e SOLTANTO le
/// caselle in cui l'avversario osserva ORA una formazione del giocatore, cioè quelle per
/// lui confermate (01 §5.3). Le posizioni del giocatore che l'avversario NON osserva non
/// sono nel grafo degli oggetti: la condotta non può accedervi, e non per disciplina ma
/// perché non esistono in ciò che riceve (RDA-114, «un controllo, non una disciplina»).
///
/// L'unico punto in cui lo stato reale si legge è `MotoreCampagna.vistaAvversario`, che
/// costruisce questa vista proiettando le posizioni del giocatore attraverso la
/// conoscenza dell'avversario. Da lì in poi la decisione è cieca allo stato reale.
public struct VistaAvversario: Sendable {
    public let mappa: MappaCampagna
    public let marcia: ValoriMarcia
    public let condotta: ValoriCondotta
    /// I propri gruppi, per intero: l'avversario conosce sé stesso.
    public let gruppiPropri: [Gruppo]
    /// Il volume di ciascun proprio gruppo, precalcolato: è geometria della colonna
    /// (01 §3.4.4), non informazione sul giocatore.
    public let volumi: [IdGruppo: Int64]
    /// Le caselle in cui l'avversario OSSERVA ORA una formazione del giocatore
    /// (conoscenza confermato): l'unica cosa che sa delle posizioni del giocatore.
    public let formazioniGiocatoreNote: Set<Cella>

    public init(mappa: MappaCampagna, marcia: ValoriMarcia, condotta: ValoriCondotta,
                gruppiPropri: [Gruppo], volumi: [IdGruppo: Int64],
                formazioniGiocatoreNote: Set<Cella>) {
        self.mappa = mappa; self.marcia = marcia; self.condotta = condotta
        self.gruppiPropri = gruppiPropri; self.volumi = volumi
        self.formazioniGiocatoreNote = formazioniGiocatoreNote
    }

    public var qgProprio: Cella { mappa.quartierGenerale(di: .avversario) }
    public var qgGiocatore: Cella { mappa.quartierGenerale(di: .giocatore) }
    public var griglia: GrigliaCampagna { mappa.griglia }

    /// I propri gruppi che attendono una decisione, in ordine di id: è l'ordine interno
    /// FISSO e deterministico con cui l'avversario muove (01 §5.6.11).
    public var gruppiInAttesa: [Gruppo] {
        gruppiPropri.filter { !$0.haConclusoLaGiornata }.sorted { $0.id < $1.id }
    }

    /// Il PROPRIO occupante di una casella, se c'è: serve alla validità della marcia,
    /// dove una casella ospita al più una formazione della stessa parte (01 §5.6.0.2).
    func occupanteProprio(_ cella: Cella) -> Gruppo? {
        gruppiPropri.first { $0.posizione == cella }
    }

    /// Il costo in giorni di uno scatto di un proprio gruppo, dal nucleo puro del costo
    /// (mappa più volume della colonna): non tocca alcuna posizione del giocatore.
    public func costoInGiorni(di gruppo: Gruppo, a arrivo: Cella) -> Int {
        MotoreCampagna.costoInGiorni(da: gruppo.posizione, a: arrivo,
                                     volumeColonna: volumi[gruppo.id] ?? 0,
                                     mappa: mappa, marcia: marcia)
    }

    /// Il comando di marcia VALIDO di un proprio gruppo verso una casella adiacente, o
    /// nil se non ammissibile. Riproduce i soli controlli della marcia che dipendono da
    /// ciò che l'avversario CONOSCE — i propri gruppi e la geografia: adiacenza, casella
    /// dentro la mappa, libera dalla PROPRIA parte e non già puntata da un'altra propria
    /// marcia, costo coerente, gruppo che non ha concluso e non deve rifornirsi. NON
    /// dipende da alcuna posizione del giocatore: la compresenza resta possibile
    /// (01 §6.1), e un comando così costruito supera `MotoreCampagna.valida(_,
    /// parte: .avversario, _)` per costruzione, perché quei controlli coincidono coi
    /// controlli di parte propria del Motore.
    public func comandoDiMarcia(di gruppo: Gruppo, a arrivo: Cella) -> ComandoCampagna? {
        guard !gruppo.haConclusoLaGiornata, !gruppo.deveRifornirsi,
              griglia.contiene(arrivo), griglia.adiacenti(gruppo.posizione, arrivo),
              occupanteProprio(arrivo) == nil,
              !gruppiPropri.contains(where: { $0.marcia?.destinazione == arrivo }) else { return nil }
        return .marcia(gruppo: gruppo.id, a: arrivo, giorni: costoInGiorni(di: gruppo, a: arrivo))
    }
}

/// La condotta deterministica dell'avversario di campagna (01 §12.1, §5.6.11, incarico
/// 18). Riceve SOLTANTO la vista ristretta: non ha, e non può ottenere, le posizioni del
/// giocatore che l'avversario non osserva (RDA-114). Nessuna estrazione del caso: le
/// scelte discendono dai pesi del carattere (dati) e le parità si rompono per ordine di
/// lettura della casella (RDA-07). Due partite identiche restano identiche.
///
/// Per il gruppo di id minore che ancora attende, la condotta assegna a ogni mossa
/// candidata — il presidio e ogni marcia valida verso una casella adiacente — un
/// punteggio intero, somma pesata di tre spinte, e sceglie il punteggio massimo:
///
/// 1. **Avanzata (aggressività).** Guadagno pari a quanto la mossa avvicina il gruppo al
///    quartier generale del giocatore, misurato AGGIRANDO le formazioni note (distanza
///    su un cammino che le tratta come ostacoli): così l'aggiramento di 01 §5.13 è
///    inerente all'avanzata, e una formazione che sbarra la via diretta fa girare intorno.
/// 2. **Minaccia al rifornimento.** Un premio se la casella è ALLE SPALLE di una
///    formazione nota, cioè in una delle caselle da cui se ne taglia il rifornimento
///    (01 §5.2.2.2): è il mettersi dietro le linee del giocatore.
/// 3. **Difesa del quartier generale.** Se una formazione nota è entro la soglia dal
///    proprio quartier generale, un guadagno pari a quanto la mossa vi si avvicina: il
///    gruppo ripiega a difenderlo (01 §5.2.1).
///
/// A parità di punteggio vince il PRESIDIO (l'avversario non si muove a vuoto) e, fra
/// marce, la casella minore nell'ordine di lettura. Restituisce sempre un comando VALIDO;
/// un gruppo costretto dal taglio si ferma con la sosta di raccolta (l'unica sua azione
/// ammessa), come il giocatore.
public struct CondottaAvversaria: Sendable {
    public init() {}

    /// Il prossimo comando dell'avversario, per il gruppo di id minore che attende. Nil
    /// quando nessun gruppo avversario attende: il turno dell'avversario è concluso.
    public func prossimoComando(vista: VistaAvversario) -> ComandoCampagna? {
        guard let gruppo = vista.gruppiInAttesa.first else { return nil }
        return comando(per: gruppo, vista: vista)
    }

    /// La decisione per un singolo gruppo. Pubblica per la Verifica, che la esercita
    /// direttamente per provare determinismo e cecità all'informazione non posseduta.
    public func comando(per gruppo: Gruppo, vista: VistaAvversario) -> ComandoCampagna {
        // Un gruppo tenuto fermo dal taglio (sosta dovuta) non può marciare né, con due
        // soste, presidiare: la sola azione valida è la sosta con raccolta, come per il
        // giocatore (01 §5.2.2.4, §5.6.5). Nessuna asimmetria.
        if gruppo.deveRifornirsi { return .sostaConRaccolta(gruppo: gruppo.id) }

        // Gli ESPLORATORI dell'avversario usano la ricognizione alle stesse condizioni del
        // giocatore (01 §5.4, incarico 19): esplorano. Non partecipano all'avanzata armata —
        // non innescano mai battaglia (01 §5.4.1) — e il loro compito è osservare. Condotta
        // provvisoria: un esploratore esplora la propria zona; la taratura del suo impiego è
        // rinviata come il carattere (01 §6.1.3).
        if gruppo.categoria.eRicognizione { return .esplorazione(gruppo: gruppo.id) }

        // Le formazioni NON ARMATE non avanzano né combattono: presidiano dove sono (catene di
        // approvvigionamento, 01 §5.2). Nel banco questo le tiene raggiungibili — bersaglio di
        // sabotaggio e studio — invece di ritirarle; la loro condotta è comunque provvisoria.
        if gruppo.categoria.eNonArmata { return .presidio(gruppo: gruppo.id) }

        let c = vista.condotta
        let noti = vista.formazioniGiocatoreNote
        let griglia = vista.griglia
        let qgAvv = vista.qgProprio
        let qgGio = vista.qgGiocatore

        // Il campo delle distanze dal quartier generale del giocatore, AGGIRANDO le
        // formazioni note (ostacoli): è l'aggiramento reso inerente all'avanzata.
        let distDaQgGiocatore = distanzeAggirando(qgGio, ostacoli: noti, griglia: griglia)

        // Il proprio quartier generale è minacciato se una formazione nota vi è entro
        // la soglia (01 §5.2.1): decide sulla propria conoscenza, non sullo stato reale.
        let qgMinacciato = noti.contains { griglia.distanza($0, qgAvv) <= c.sogliaDifesaQuartierGenerale }

        // Le caselle da cui si taglia il rifornimento di una formazione nota: le sue
        // spalle, verso il quartier generale del giocatore (01 §5.2.2.2).
        var spalleDeiNoti = Set<Cella>()
        for cella in noti {
            spalleDeiNoti.formUnion(MotoreCampagna.caselleAlleSpalle(di: cella, qg: qgGio, griglia: griglia))
        }

        let lontano = griglia.righe * griglia.colonne + 1
        func distObiettivo(_ cella: Cella) -> Int { distDaQgGiocatore[cella] ?? lontano }

        func punteggio(dove: Cella, partenza: Cella) -> Int {
            var p = 0
            p += c.aggressivita * (distObiettivo(partenza) - distObiettivo(dove))
            if spalleDeiNoti.contains(dove) { p += c.minacciaRifornimento }
            if qgMinacciato {
                p += c.difesaQuartierGenerale * (griglia.distanza(partenza, qgAvv) - griglia.distanza(dove, qgAvv))
            }
            return p
        }

        let partenza = gruppo.posizione
        // Base: il presidio, con il punteggio della casella attuale (guadagni nulli,
        // salvo una minaccia già in atto). Vince a parità, sicché l'avversario resta
        // fermo anziché muoversi senza guadagno.
        var miglioreComando: ComandoCampagna = .presidio(gruppo: gruppo.id)
        var migliorePunteggio = punteggio(dove: partenza, partenza: partenza)

        for arrivo in griglia.vicini(di: partenza).sorted() {
            guard let comando = vista.comandoDiMarcia(di: gruppo, a: arrivo) else { continue }
            let p = punteggio(dove: arrivo, partenza: partenza)
            if p > migliorePunteggio {
                migliorePunteggio = p
                miglioreComando = comando
            }
        }
        // In assenza di guadagno il gruppo armato PRESIDIA, come nell'incarico 18: continua ad
        // avanzare quando conviene, e non si ferma a vuoto in modo da smettere di premere. La
        // CAPACITÀ di tendere imboscate esiste ed è simmetrica (la validazione ammette l'ordine
        // di imboscata per l'avversario esattamente come per il giocatore, RDA-112): che il
        // giocatore vi possa cadere è provato da una prova dedicata (AvversarioCampagnaTest). La
        // TATTICA con cui la condotta sceglie di appostarsi — invece di limitarsi a poterlo — è
        // una manopola del carattere, rinviata con la sua taratura (01 §6.1.3, dichiarato in S18).
        return miglioreComando
    }

    /// Le distanze in caselle da una sorgente, su un cammino che AGGIRA un insieme di
    /// ostacoli (le formazioni note): un percorso in ampiezza sulla griglia ortogonale
    /// che non attraversa gli ostacoli. La sorgente e gli ostacoli hanno distanza propria
    /// (la sorgente zero; gli ostacoli non ricevono distanza, restando irraggiungibili e
    /// quindi «oltre l'obiettivo»). Deterministico: nessuna estrazione, ordine dei vicini
    /// fisso. È il nucleo dell'aggiramento (01 §5.13).
    func distanzeAggirando(_ sorgente: Cella, ostacoli: Set<Cella>,
                           griglia: GrigliaCampagna) -> [Cella: Int] {
        var distanze: [Cella: Int] = [sorgente: 0]
        var frangia = [sorgente]
        var i = 0
        while i < frangia.count {
            let corrente = frangia[i]; i += 1
            let d = distanze[corrente]!
            for vicino in griglia.vicini(di: corrente) where distanze[vicino] == nil && !ostacoli.contains(vicino) {
                distanze[vicino] = d + 1
                frangia.append(vicino)
            }
        }
        return distanze
    }
}
