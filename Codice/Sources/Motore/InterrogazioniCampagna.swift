import Foundation
import Dati

/// Le interrogazioni di sola lettura per la Presentazione (05 §9.4). La
/// Presentazione non calcola mai un dato di gioco: se un'informazione non è
/// ottenibile con un'interrogazione, si aggiunge l'interrogazione qui.
public struct VistaCampagna: Sendable {
    let motore: MotoreCampagna
    let stato: StatoCampagna
    let parte: Parte

    public init(motore: MotoreCampagna, stato: StatoCampagna, parte: Parte) {
        self.motore = motore; self.stato = stato; self.parte = parte
    }

    /// Ciò che il giocatore OSSERVA di una formazione avversaria (prima correzione, incarico
    /// 19): la sua CATEGORIA — visibile dalla sagoma, e distinta per segno e per annuncio da
    /// quella delle altre categorie e delle proprie — e, per la sola non armata STUDIATA a
    /// fondo, il suo carico (01 §5.10.2). Non porta mai nome, volume né stato d'azione
    /// (02 §6.4.1): un tipo dedicato rende IMPOSSIBILE, non solo sconsigliato, che quei dati
    /// trapelino: il carico è nell'oggetto solo se davvero noto.
    public enum CategoriaAvversariaOsservata: Hashable, Sendable {
        case gruppoArmato
        case ricognizione
        /// Il carico è noto solo se la formazione è stata studiata a fondo; altrimenti nil.
        case nonArmata(caricoNoto: Int?)

        /// La chiave del termine che nomina la categoria (composta dai termini di 01 §5.2, non
        /// un termine nuovo del vocabolario chiuso — S18, incarico 19): la stessa da cui
        /// discende il segno, sicché ciò che si vede e ciò che si sente coincidono.
        public var chiaveCategoria: String {
            switch self {
            case .gruppoArmato: return "categoria.gruppo_armato"
            case .ricognizione: return "categoria.ricognizione"
            case .nonArmata: return "categoria.non_armata"
            }
        }
        public var eStudiata: Bool { if case .nonArmata(.some) = self { return true } else { return false } }
    }

    // MARK: - Contenuto della casella

    public func occupante(di casella: Cella) -> Gruppo? { stato.occupante(di: casella, parte: parte) }
    public func terreno(di casella: Cella) -> TerrenoCasella { stato.mappa.terreno(di: casella) }
    public func strada(di casella: Cella) -> TipoStrada { stato.mappa.strada(di: casella) }
    public func eStrettoia(_ casella: Cella) -> Bool { stato.mappa.strettoia == casella }
    public func quartierGeneraleSu(_ casella: Cella) -> Parte? { stato.mappa.quartierGeneraleSu(casella) }

    /// Ciò che una casella dichiara, in UN SOLO elenco ordinato e in un solo punto
    /// del programma (02 §3.8.1, principio 7).
    ///
    /// Prima esistevano tre enumerazioni parallele delle stesse caratteristiche —
    /// quella che le annunciava, quella che decideva se dire «libera» e quella che
    /// le disegnava — e nulla obbligava a tenerle allineate: una caratteristica
    /// aggiunta all'una e dimenticata nelle altre sarebbe stata una divergenza fra
    /// il piano visivo e quello sonoro, che è la classe di difetto che 00 §1.2
    /// vieta. Con un elenco solo la divergenza è impossibile per COSTRUZIONE e non
    /// per disciplina: chi aggiunge un caso all'enumerativo è obbligato dal
    /// compilatore a dargli una frase e un segno (RDA-74).
    ///
    /// L'ordine è quello registrato da 02 §3.8.1, ridotto a ciò che esiste in
    /// questa unità: occupante, quartier generale (che occupa il posto delle opere,
    /// RDA-63), terreno, strada, note di zona. Le voci che non si applicano si
    /// saltano senza lasciare traccia; i tagli di verbosità partono dalla coda.
    public enum VoceDiCasella: Hashable, Sendable {
        /// Lo stato di conoscenza, PRIMA voce dopo la testa fissa se diverso da
        /// confermato (02 §3.8.1): dice quanto è corrente ciò che segue.
        case conoscenza(StatoConoscenza)
        case occupante(Gruppo)
        /// Una FORMAZIONE AVVERSARIA, mostrata solo dove la conoscenza del giocatore è
        /// confermato (01 §5.6.11, incarico 18): l'occultamento. Non porta il gruppo —
        /// né il suo nome né il suo volume (02 §6.4.1), né il suo stato d'azione, che
        /// tradirebbe l'ordine interno di risoluzione — perché il giocatore la vede, non
        /// la conosce. Porta però la sua CATEGORIA osservata (prima correzione, incarico 19):
        /// gruppo armato, ricognizione o non armata sono distinguibili dalla sagoma, e ciascuna
        /// ha il proprio segno e il proprio annuncio. Il CARICO di una formazione non armata è
        /// noto solo se la si è STUDIATA a fondo (01 §5.10.2). Su una casella non confermata
        /// questa voce non compare affatto.
        case occupanteAvversario(CategoriaAvversariaOsservata)
        case rifornimento(StatoRifornimento)
        /// La COMPOSIZIONE della PROPRIA formazione (incarico 22): i reparti e gli atomi di
        /// cui è fatta. Riguarda le proprie truppe e non è nascosta — il giocatore deve poter
        /// sapere che cosa muove — ma è un DETTAGLIO di bassa priorità dell'occupante: sta DOPO
        /// le voci di testa (la categoria compresa), sicché il livello sintetico la lascia cadere
        /// per prima dalla coda (02 §3.8.1). Non esiste per le formazioni avversarie, di cui non
        /// si dichiara il volume (02 §6.4.1): appartiene solo all'occupante proprio.
        case composizionePropria([Reparto])
        case quartierGenerale(Parte)
        case terreno(TerrenoCasella)
        case strada(TipoStrada)
        case strettoia
        case zonaDiRifornimento
    }

    public func vociDiCasella(_ casella: Cella) -> [VoceDiCasella] {
        var voci: [VoceDiCasella] = []
        // Lo stato di conoscenza viene PER PRIMO dopo la testa fissa, se diverso da
        // confermato (02 §3.8.1): dichiara quanto è corrente ciò che la casella dice.
        let statoConoscenza = motore.conoscenza(di: casella, per: parte, stato: stato)
        if statoConoscenza.siAnnuncia { voci.append(.conoscenza(statoConoscenza)) }
        let occupanteProprio = occupante(di: casella)
        if let gruppo = occupanteProprio {
            voci.append(.occupante(gruppo))
            // Il rifornimento è la PRIMA anomalia dell'occupante (02 §3.8.1): un gruppo
            // senza provviste o in sosta lo dichiara subito dopo il proprio nome. La
            // zona, che è una proprietà del LUOGO e non del gruppo, va invece in coda
            // (con la strettoia): un gruppo che vi sosta è solo rifornito, e il
            // rifornito non si annuncia (02 §8.7).
            if let rifornimento = motore.statoDiRifornimento(di: gruppo, stato: stato),
               rifornimento.eDiPrivazione {
                voci.append(.rifornimento(rifornimento))
            }
        }
        // La formazione avversaria si mostra SOLO dove la conoscenza del giocatore è
        // confermato, cioè dove una sua formazione la osserva (01 §5.6.11, §5.11.1): è
        // l'occultamento. La compresenza (01 §6.1) è possibile, sicché può accompagnare
        // un proprio occupante. Su una casella non confermata non compare, e il giocatore
        // vi legge solo lo stato di conoscenza, che tace ciò che non osserva.
        let parteAvversa: Parte = parte == .giocatore ? .avversario : .giocatore
        if statoConoscenza == .confermato,
           let avversario = stato.occupante(di: casella, parte: parteAvversa) {
            voci.append(.occupanteAvversario(categoriaOsservata(di: avversario)))
        }
        // La COMPOSIZIONE della propria formazione va DOPO tutte le voci di testa —
        // la categoria propria e quella avversaria comprese (02 §3.8.1): è un dettaglio
        // non nascosto ma di bassa priorità, e i tagli di verbosità la lasciano cadere per
        // prima dalla coda. Riguarda solo le proprie truppe; dell'avversario non si dichiara
        // il volume (02 §6.4.1), sicché nessuna composizione ne accompagna la categoria.
        if let gruppo = occupanteProprio {
            voci.append(.composizionePropria(gruppo.composizione))
        }
        if let parte = quartierGeneraleSu(casella) { voci.append(.quartierGenerale(parte)) }
        let terreno = terreno(di: casella)
        if terreno != .aperto { voci.append(.terreno(terreno)) }
        let strada = strada(di: casella)
        if strada != .nessuna { voci.append(.strada(strada)) }
        if eStrettoia(casella) { voci.append(.strettoia) }
        // Nota di zona in coda: la casella è in una zona di rifornimento, che vi sia o
        // no un occupante (una zona vuota resta una zona). È l'ultima voce, e i tagli
        // di verbosità partono da qui (02 §3.8.1).
        if motore.inZonaDiRifornimento(casella, stato: stato) { voci.append(.zonaDiRifornimento) }
        return voci
    }

    /// Vero se il giocatore OSSERVA ORA una formazione avversaria su questa casella: il
    /// segno del nemico sulla mappa (incarico 23). Discende dalla STESSA voce
    /// `.occupanteAvversario` di `vociDiCasella` — l'unico elenco delle caratteristiche
    /// della casella (02 §3.8.1) — sicché il riempimento arancione della casella e il suo
    /// annuncio non possono divergere: dove l'uno dichiara l'avversario, l'altro lo colora.
    /// Come la voce, è vero solo dove la conoscenza è confermato (l'occultamento, 01 §5.6.11).
    public func avversarioAvvistato(su casella: Cella) -> Bool {
        vociDiCasella(casella).contains {
            if case .occupanteAvversario = $0 { return true }
            return false
        }
    }

    /// La categoria osservata di una formazione avversaria (01 §5.2, §5.10.2): la sua categoria,
    /// e il carico solo se la si è studiata a fondo. Il carico non entra mai nell'oggetto se non
    /// è noto, sicché non può trapelare.
    func categoriaOsservata(di avversario: Gruppo) -> CategoriaAvversariaOsservata {
        let studiata = stato.studiati[parte]?.contains(avversario.id) == true
        switch avversario.categoria {
        case .armato: return .gruppoArmato
        case .ricognizione: return .ricognizione
        case .nonArmata(let carico, _): return .nonArmata(caricoNoto: studiata ? carico : nil)
        }
    }

    // MARK: - Destinazioni

    /// Il costo in giorni dello scatto verso una casella adiacente (01 §5.6.3.1).
    /// La Presentazione non lo calcola mai: lo chiede qui (00 §3.2).
    public func costoInGiorni(da partenza: Cella, a arrivo: Cella) -> Int {
        motore.costoInGiorni(da: partenza, a: arrivo, parte: parte, stato: stato)
    }

    /// Il comando di marcia già formato, con il costo che i dati prescrivono: è
    /// l'unico modo in cui la Presentazione lo costruisce, così che il costo non
    /// possa essere inventato altrove (00 §3.2, 00 §13.1).
    public func comandoDiMarcia(per id: IdGruppo, a casella: Cella) -> ComandoCampagna? {
        guard let gruppo = stato.gruppi[id] else { return nil }
        return .marcia(gruppo: id, a: casella,
                       giorni: costoInGiorni(da: gruppo.posizione, a: casella))
    }

    /// Il comando di revoca della marcia, se il gruppo ne ha una in corso (01 §5.6.3.3).
    public func comandoDiRevoca(per id: IdGruppo) -> ComandoCampagna? {
        guard let gruppo = stato.gruppi[id], gruppo.inMarcia else { return nil }
        return .revocaMarcia(gruppo: id)
    }

    /// I giorni che una revoca farebbe perdere: quelli già spesi (01 §5.6.3.3). La
    /// Presentazione lo dichiara nel pannello di conferma, prima della conferma
    /// (01 §5.6.3.5). Nullo se il gruppo non è in marcia.
    public func giorniPersiRevocando(per id: IdGruppo) -> Int? {
        stato.gruppi[id]?.marcia?.giorniCompiuti
    }

    /// L'avanzamento visivo di un gruppo in marcia (01 §5.6.3.4): la posizione fra le
    /// nove, derivata dai giorni. La Presentazione non la calcola: la chiede qui.
    public func avanzamentoVisivo(di id: IdGruppo) -> Int? {
        guard let m = stato.gruppi[id]?.marcia else { return nil }
        return motore.avanzamentoVisivo(giorniCompiuti: m.giorniCompiuti, giorniTotali: m.giorniTotali)
    }

    /// Le destinazioni valide per un gruppo, in ordine di lettura. È l'anteprima
    /// annunciata (05 §3.2) e alimenta la designazione sulla mappa (02 §9.2.1).
    public func destinazioniValide(per id: IdGruppo) -> [Cella] {
        guard let gruppo = stato.gruppi[id] else { return [] }
        return stato.griglia.vicini(di: gruppo.posizione)
            .filter { anteprimaMarcia(da: id, a: $0).eValido }
            .sorted()
    }

    /// Vero se il gruppo ha almeno una destinazione raggiungibile: quando è falso,
    /// l'azione di marcia non si offre affatto (02 §9.5).
    public func esisteDestinazione(per id: IdGruppo) -> Bool { !destinazioniValide(per: id).isEmpty }

    /// L'esito di validazione di una marcia sulla casella: l'anteprima annunciata.
    public func anteprimaMarcia(da id: IdGruppo, a casella: Cella) -> EsitoValidazioneCampagna {
        guard let comando = comandoDiMarcia(per: id, a: casella) else {
            return .nonValido(.gruppoIgnoto)
        }
        return motore.valida(comando, parte: parte, stato: stato)
    }

    // MARK: - Divisione e riunione (01 §5.6.0.2, §5.6.0.3)

    /// Vero se il gruppo può DIVIDERSI: non ha concluso la giornata, ha almeno due
    /// reparti (la divisione lavora su reparti interi e nessuna parte resta vuota) e
    /// ha una casella adiacente libera dove collocare il distaccamento. Quando è
    /// falso, l'azione di divisione non si offre affatto (02 §9.5).
    public func puoDividere(per id: IdGruppo) -> Bool {
        guard let gruppo = stato.gruppi[id], !gruppo.haConclusoLaGiornata,
              gruppo.composizione.count >= 2 else { return false }
        return esisteDestinazione(per: id)
    }

    /// Il comando di divisione già formato, se valido; altrimenti nullo (00 §3.2): la
    /// Presentazione non giudica da sé, chiede al Motore.
    public func comandoDiDivisione(per id: IdGruppo, staccando reparti: [Int],
                                   a casella: Cella) -> ComandoCampagna? {
        let comando = ComandoCampagna.divisione(gruppo: id, repartiStaccati: reparti.sorted(), a: casella)
        return motore.valida(comando, parte: parte, stato: stato).eValido ? comando : nil
    }

    /// I gruppi propri adiacenti con cui questo si può RIUNIRE: entrambi non in marcia
    /// (01 §5.6.0.3), in ordine di id. Vuoto se il gruppo stesso è in marcia.
    public func gruppiRiunibili(con id: IdGruppo) -> [Gruppo] {
        guard let gruppo = stato.gruppi[id], !gruppo.inMarcia else { return [] }
        return stato.griglia.vicini(di: gruppo.posizione).compactMap { vicina in
            guard let altro = stato.occupante(di: vicina, parte: parte), !altro.inMarcia else { return nil }
            return altro
        }.sorted { $0.id < $1.id }
    }

    /// Il comando di riunione, se valido; altrimenti nullo (00 §3.2).
    public func comandoDiRiunione(gruppo id: IdGruppo, con altro: IdGruppo) -> ComandoCampagna? {
        let comando = ComandoCampagna.riunione(gruppo: id, con: altro)
        return motore.valida(comando, parte: parte, stato: stato).eValido ? comando : nil
    }

    // MARK: - Orientamento (01 §5.16)

    /// Il primo strato dell'orientamento: l'informazione di stato, richiamabile in
    /// qualunque momento senza abbandonare la mappa (01 §5.16, 02 §6.5.1.3).
    /// L'ordine dei campi è quello fisso di 02 §6.5.1.3, ridotto a ciò che esiste
    /// in questa unità: giorno, gruppi che hanno agito sul totale, gruppi in marcia e
    /// — da questa unità — gruppi senza rifornimento. Stagione, scatti, battaglie in
    /// sospeso e vincolo fra campagne appartengono alle unità che li introducono e non
    /// si annunciano a vuoto (02 §8.7.1). Le «provviste» dell'elenco entrano ora, col
    /// conto dei gruppi che il rifornimento non raggiunge.
    public struct InformazioneDiStato: Hashable, Sendable {
        public let giorno: Int
        public let gruppiCheHannoAgito: Int
        public let gruppiInMarcia: Int
        public let gruppiSenzaRifornimento: Int
        public let gruppiTotali: Int
        /// Le caselle delle battaglie in sospeso (01 §6.3, 02 §6.5.1.3, incarico 24): lo stato le
        /// dichiara «e dove», in coda al formato chiuso. Vuoto quando nessuna è in sospeso.
        public let battaglieInSospeso: [Cella]
    }

    public var informazioneDiStato: InformazioneDiStato {
        let miei = stato.gruppi(di: parte)
        // «Ha agito» e «in marcia lunga» sono categorie distinte (01 §5.16): un gruppo
        // in marcia si dichiara a parte e non si conta fra chi ha agito, così che il
        // giocatore sappia che quella giornata è consumata da una marcia e non da
        // un'azione conclusa. Chi attende è il resto: totale meno agiti meno in marcia.
        // «Senza rifornimento» è un'altra categoria ancora: raccoglie chi patisce il
        // taglio — senza provviste o in sosta imposta — indipendentemente dall'azione.
        // «Ha agito» conta i gruppi che hanno CONCLUSO la giornata e non sono in marcia lunga:
        // vi rientrano i gruppi appostati in agguato, che pure hanno concluso la giornata
        // (01 §5.11.3, «un gruppo appostato è fermo e non produce nulla») e non attendono una
        // decisione. Il loro stato di agguato si dichiara nell'annuncio della casella (02 §6.5.3),
        // non qui, dove il formato è chiuso (02 §6.5.1.3): nessuna voce nuova. Per i gruppi non
        // appostati «concluso e non in marcia» coincide con «azione spesa e non in marcia».
        return InformazioneDiStato(giorno: stato.giorno,
                                   gruppiCheHannoAgito: miei.filter { $0.haConclusoLaGiornata && !$0.inMarcia }.count,
                                   gruppiInMarcia: miei.filter(\.inMarcia).count,
                                   gruppiSenzaRifornimento: miei.filter {
                                       motore.statoDiRifornimento(di: $0, stato: stato)?.eDiPrivazione == true
                                   }.count,
                                   gruppiTotali: miei.count,
                                   battaglieInSospeso: stato.battaglieInSospeso.map(\.casella))
    }

    /// Il secondo strato: il salto diretto al prossimo gruppo che non ha ancora
    /// agito (01 §5.16, 02 §7.3.1). Non è una comodità accessoria ma la
    /// contropartita della struttura a un'azione per gruppo.
    ///
    /// Il prossimo è quello che segue la casella indicata nell'ordine di lettura,
    /// e si riparte dal primo quando non ne resta alcuno dopo: chi salta ripetuta-
    /// mente percorre tutti i gruppi in attesa e non si ferma sull'ultimo.
    public func prossimoGruppoInAttesa(dopo casella: Cella?) -> Gruppo? {
        let attesa = stato.gruppiInAttesa(di: parte)
        guard !attesa.isEmpty else { return nil }
        guard let casella else { return attesa.first }
        return attesa.first { casella < $0.posizione } ?? attesa.first
    }

    public func gruppoPrecedenteInAttesa(prima casella: Cella?) -> Gruppo? {
        let attesa = stato.gruppiInAttesa(di: parte)
        guard !attesa.isEmpty else { return nil }
        guard let casella else { return attesa.last }
        return attesa.last { $0.posizione < casella } ?? attesa.last
    }

    /// Gli insiemi dei rotori realizzati in questa unità (02 §7.3): le proprie
    /// formazioni e i propri gruppi che non hanno ancora agito. Gli altri rotori
    /// dell'elenco dipendono da regole che questa unità non realizza.
    public var casellePropriFormazioni: [Cella] { stato.gruppi(di: parte).map(\.posizione).sorted() }
    public var caselleGruppiInAttesa: [Cella] { stato.gruppiInAttesa(di: parte).map(\.posizione).sorted() }

    /// Il rotore delle FORMAZIONI AVVERSARIE NOTE (02 §7.3): le caselle in cui una
    /// formazione avversaria è osservata ORA, cioè dove la conoscenza è confermato
    /// (01 §5.6.11, incarico 18). È il salto diretto a ciò che il giocatore vede del
    /// nemico; ciò che non osserva non vi compare, come nella casella. Ordine di lettura
    /// (02 §7.4): i nomi delle formazioni avversarie non si rivelano (02 §6.4.1), sicché
    /// l'ordine è per posizione e non per nome.
    public var caselleFormazioniAvversarieNote: [Cella] {
        let parteAvversa: Parte = parte == .giocatore ? .avversario : .giocatore
        return stato.gruppi(di: parteAvversa)
            .map(\.posizione)
            .filter { motore.osservata($0, da: parte, stato: stato) }
            .sorted()
    }

    /// Il rotore dei propri gruppi SENZA RIFORNIMENTO (02 §7.3): quelli che patiscono
    /// il taglio — senza provviste o in sosta imposta — in ordine di lettura. È il
    /// salto diretto ai gruppi che chiedono attenzione, contropartita del fatto che il
    /// taglio non paralizza ma va gestito.
    public var caselleGruppiSenzaRifornimento: [Cella] {
        stato.gruppi(di: parte)
            .filter { motore.statoDiRifornimento(di: $0, stato: stato)?.eDiPrivazione == true }
            .map(\.posizione).sorted()
    }

    /// Il rotore delle CASELLE DA CUI È POSSIBILE ESPLORARE (02 §7.3): le posizioni delle proprie
    /// formazioni di ricognizione che non hanno ancora concluso la giornata e possono quindi
    /// ordinare un'esplorazione (01 §5.4). È il salto diretto agli esploratori pronti; una volta
    /// che hanno esplorato, escono dal rotore fino al giorno dopo.
    public var caselleEsplorabili: [Cella] {
        stato.gruppi(di: parte)
            .filter { $0.categoria.eRicognizione && !$0.haConclusoLaGiornata }
            .map(\.posizione).sorted()
    }

    /// Il rotore delle INFORMAZIONI DI RICOGNIZIONE SCADUTE (02 §7.3): le caselle la cui conoscenza
    /// non è più corrente — avvistato (vista e invecchiata) o presunto (dedotta, mai osservata
    /// direttamente) — cioè ciò che si sa del nemico ma che il tempo o la deduzione rendono
    /// incerto (01 §5.3). È il salto diretto a ciò che converrebbe riesplorare. In ordine di
    /// lettura, escluse le confermate (correnti) e le inesplorate (nulla si sa).
    public var caselleRicognizioneScadute: [Cella] {
        stato.griglia.tutteLeCaselle.filter {
            switch motore.conoscenza(di: $0, per: parte, stato: stato) {
            case .avvistato, .presunto: return true
            case .confermato, .inesplorato: return false
            }
        }.sorted()
    }

    // MARK: - Registro (01 §5.17, 02 §6.6)

    /// Le voci in ordine dal più recente al meno recente, così che scorrendo si
    /// vada indietro nel tempo e ci si fermi alle cose già sentite (02 §6.6).
    public var registroDalPiuRecente: [VoceRegistro] { stato.registro.reversed() }

    // MARK: - Misure di percorribilità (per il programma di verifica)

    /// Le USCITE LIBERE di una casella: i vicini ortogonali non occupati.
    ///
    /// Si chiamava «caselle raggiungibili in una giornata», e quel nome
    /// presupponeva l'identità fra una casella e una giornata, che non è una regola
    /// ma il caso particolare prodotto dal costo in giorni pari a uno (01 §5.6.3.1).
    /// Con un costo maggiore la stessa casella resterebbe un'uscita libera senza
    /// essere raggiungibile in una giornata, e il nome direbbe il falso: è la stessa
    /// classe di errore delle caselle di bordo scambiate per quelle con meno di
    /// quattro uscite.
    public func usciteLibere(da casella: Cella) -> [Cella] {
        stato.griglia.vicini(di: casella)
            .filter { stato.occupante(di: $0, parte: parte) == nil }
            .sorted()
    }
}
