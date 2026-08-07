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
        case occupante(Gruppo)
        case quartierGenerale(Parte)
        case terreno(TerrenoCasella)
        case strada(TipoStrada)
        case strettoia
    }

    public func vociDiCasella(_ casella: Cella) -> [VoceDiCasella] {
        var voci: [VoceDiCasella] = []
        if let gruppo = occupante(di: casella) { voci.append(.occupante(gruppo)) }
        if let parte = quartierGeneraleSu(casella) { voci.append(.quartierGenerale(parte)) }
        let terreno = terreno(di: casella)
        if terreno != .aperto { voci.append(.terreno(terreno)) }
        let strada = strada(di: casella)
        if strada != .nessuna { voci.append(.strada(strada)) }
        if eStrettoia(casella) { voci.append(.strettoia) }
        return voci
    }

    // MARK: - Destinazioni

    /// Il costo in giorni dello scatto verso una casella adiacente (01 §5.6.3.1).
    /// La Presentazione non lo calcola mai: lo chiede qui (00 §3.2).
    public func costoInGiorni(da partenza: Cella, a arrivo: Cella) -> Int {
        motore.costoInGiorni(da: partenza, a: arrivo, stato: stato)
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
    /// in questa unità: giorno, gruppi che hanno agito sul totale. Stagione, marce,
    /// scatti, provviste, battaglie in sospeso e vincolo fra campagne appartengono
    /// alle unità che li introducono e non si annunciano a vuoto (02 §8.7.1).
    public struct InformazioneDiStato: Hashable, Sendable {
        public let giorno: Int
        public let gruppiCheHannoAgito: Int
        public let gruppiInMarcia: Int
        public let gruppiTotali: Int
    }

    public var informazioneDiStato: InformazioneDiStato {
        let miei = stato.gruppi(di: parte)
        // «Ha agito» e «in marcia lunga» sono categorie distinte (01 §5.16): un gruppo
        // in marcia si dichiara a parte e non si conta fra chi ha agito, così che il
        // giocatore sappia che quella giornata è consumata da una marcia e non da
        // un'azione conclusa. Chi attende è il resto: totale meno agiti meno in marcia.
        return InformazioneDiStato(giorno: stato.giorno,
                                   gruppiCheHannoAgito: miei.filter { $0.azioneSpesa && !$0.inMarcia }.count,
                                   gruppiInMarcia: miei.filter(\.inMarcia).count,
                                   gruppiTotali: miei.count)
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
