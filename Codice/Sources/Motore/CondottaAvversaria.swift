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
    /// Ciò che sa della presa dei quartieri generali (01 §5.18.3; incarico 32): nulla se la campagna non
    /// dichiara la regola.
    public let presa: Presa?

    /// Ciò che l'avversario conosce della presa: i due conteggi — il proprio quartier generale occupato,
    /// che sa sempre, e la propria occupazione di quello del giocatore — e quali delle formazioni note
    /// sono ARMATE, le sole che possono prendere un quartier generale. La categoria si distingue dalla
    /// sagoma, per l'avversario come per il giocatore (incarico 19).
    public struct Presa: Hashable, Sendable {
        /// Le giornate che mancano al giocatore per prendere il quartier generale dell'avversario; nullo
        /// se non lo occupa.
        public let mancanoAlGiocatore: Int?
        /// Le giornate che mancano all'avversario per prendere quello del giocatore; nullo se non lo occupa.
        public let mancanoAllAvversario: Int?
        /// Le caselle note in cui sta un gruppo armato del giocatore.
        public let armateNote: Set<Cella>
        public init(mancanoAlGiocatore: Int?, mancanoAllAvversario: Int?, armateNote: Set<Cella>) {
            self.mancanoAlGiocatore = mancanoAlGiocatore; self.mancanoAllAvversario = mancanoAllAvversario
            self.armateNote = armateNote
        }
    }

    public init(mappa: MappaCampagna, marcia: ValoriMarcia, condotta: ValoriCondotta,
                gruppiPropri: [Gruppo], volumi: [IdGruppo: Int64],
                formazioniGiocatoreNote: Set<Cella>, presa: Presa? = nil) {
        self.mappa = mappa; self.marcia = marcia; self.condotta = condotta
        self.gruppiPropri = gruppiPropri; self.volumi = volumi
        self.formazioniGiocatoreNote = formazioniGiocatoreNote
        self.presa = presa
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
/// 4. **Presa del quartier generale** (01 §5.18.3; incarico 32). Un premio a entrare in quello
///    del giocatore, dove la campagna dichiara la regola.
///
/// Dove la campagna dichiara la regola della presa, due decisioni precedono i punteggi
/// (`comandoPerLaPresa`): chi occupa il quartier generale del giocatore lo TIENE, e chi sa
/// occupato il proprio torna a RIPRENDERLO per la via più breve in giornate, entrando nella
/// casella — salvo che stia per prendere prima quello del giocatore, o che non possa arrivare
/// in tempo e ne tenga già uno. E la difesa guarda alla corsa: la accende una formazione ARMATA
/// nota vicina al proprio quartier generale, ma non quando l'avversario arriverebbe prima a
/// quello del giocatore, libero per ciò che ne sa.
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

        // LA PRESA DEL QUARTIER GENERALE (01 §5.18.3): tenere quello del giocatore, riprendere il proprio.
        if let presa = vista.presa, let comando = comandoPerLaPresa(gruppo, vista: vista, presa: presa) {
            return comando
        }

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
        let minacce = vista.presa?.armateNote ?? noti
        var qgMinacciato = minacce.contains { griglia.distanza($0, qgAvv) <= c.sogliaDifesaQuartierGenerale }
        if qgMinacciato, let presa = vista.presa, vinceLaCorsa(gruppo, vista: vista, presa: presa) {
            qgMinacciato = false
        }

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
            if vista.presa != nil, dove == qgGio { p += c.presaQuartierGenerale }
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
        // L'IMBOSCATA dell'avversario (01 §5.11, incarico 21): un gruppo armato che NON guadagna
        // avanzando (presiderebbe) ma ha una formazione nota del giocatore ADIACENTE si APPOSTA
        // invece di restare fermo a vuoto — tende l'agguato a chi gli è alla porta anziché
        // cederglielo. È la simmetria dell'imboscata resa reale: la casella diventa occulta per il
        // giocatore (la sua conoscenza vi retrocede, §5.11.1), il giocatore vi può cadere entrando,
        // e i suoi esploratori possono scoprirla. Deterministica e senza estrazione. È la tattica
        // che S18 aveva RINVIATO come manopola del carattere (01 §6.1.3): questa decisione del
        // titolare (incarico 21) la avvia in forma MINIMA e PROVVISORIA — la soglia dell'agguato e
        // il suo raggio restano da tarare col gioco, come il resto del carattere.
        if case .presidio = miglioreComando,
           noti.contains(where: { griglia.distanza($0, partenza) == 1 }) {
            return .imboscata(gruppo: gruppo.id)
        }
        // Altrimenti PRESIDIA (incarico 18): continua ad avanzare quando conviene, e non si ferma a
        // vuoto in modo da smettere di premere.
        return miglioreComando
    }

    /// Le due decisioni della presa (01 §5.18.3), nell'ordine in cui il giocatore le leggerà nel
    /// comportamento. Nullo quando nessuna delle due si applica, e valgono i punteggi.
    private func comandoPerLaPresa(_ gruppo: Gruppo, vista: VistaAvversario,
                                   presa: VistaAvversario.Presa) -> ComandoCampagna? {
        // Chi tiene una casella e ha accanto una formazione nota vi si apposta, altrimenti la presidia:
        // la stessa scelta di chi non guadagna a muoversi.
        func tieni() -> ComandoCampagna {
            vista.formazioniGiocatoreNote.contains { vista.griglia.distanza($0, gruppo.posizione) == 1 }
                ? .imboscata(gruppo: gruppo.id) : .presidio(gruppo: gruppo.id)
        }
        let proprieGiornate = gruppo.posizione == vista.qgGiocatore ? presa.mancanoAllAvversario : nil
        if let scadenza = presa.mancanoAlGiocatore {
            if gruppo.posizione == vista.qgProprio { return tieni() }
            // Chi sta per prendere prima quello del giocatore vince la corsa, e resta.
            if let mie = proprieGiornate, mie < scadenza { return tieni() }
            let giornate = MotoreCampagna.giornate(
                verso: vista.qgProprio, volumeColonna: vista.volumi[gruppo.id] ?? 0, mappa: vista.mappa,
                marcia: vista.marcia,
                evitando: vista.formazioniGiocatoreNote.subtracting([vista.qgProprio, gruppo.posizione]))
            // Chi ne tiene già uno e non può arrivare in tempo a riprendere il proprio, resta.
            if proprieGiornate != nil, (giornate[gruppo.posizione] ?? Int.max) > scadenza { return tieni() }
            var migliore: (comando: ComandoCampagna, giornate: Int)?
            for casella in vista.griglia.vicini(di: gruppo.posizione).sorted() {
                guard let resto = giornate[casella], let comando = vista.comandoDiMarcia(di: gruppo, a: casella) else { continue }
                let totale = vista.costoInGiorni(di: gruppo, a: casella) + resto
                if migliore.map({ totale < $0.giornate }) ?? true { migliore = (comando, totale) }
            }
            return migliore?.comando
        }
        return proprieGiornate == nil ? nil : tieni()
    }

    /// Vero se il gruppo arriverebbe al quartier generale del giocatore prima che una qualunque delle
    /// formazioni armate note arrivi al proprio (01 §5.18.3.5): allora prosegue invece di tornare. Le
    /// giornate sono quelle della colonna propria per lui, e quelle di una colonna senza volume — le meno
    /// che possano essere — per chi non conosce. Se il quartier generale del giocatore è notoriamente
    /// difeso non c'è corsa: entrarvi è una battaglia.
    private func vinceLaCorsa(_ gruppo: Gruppo, vista: VistaAvversario, presa: VistaAvversario.Presa) -> Bool {
        guard !presa.armateNote.contains(vista.qgGiocatore) else { return false }
        let mie = MotoreCampagna.giornate(verso: vista.qgGiocatore, volumeColonna: vista.volumi[gruppo.id] ?? 0,
                                          mappa: vista.mappa, marcia: vista.marcia,
                                          evitando: vista.formazioniGiocatoreNote.subtracting([gruppo.posizione]))[gruppo.posizione]
        guard let mie else { return false }
        let loro = MotoreCampagna.giornate(verso: vista.qgProprio, volumeColonna: 0, mappa: vista.mappa, marcia: vista.marcia)
        return presa.armateNote.allSatisfy { mie < loro[$0] ?? Int.max }
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
