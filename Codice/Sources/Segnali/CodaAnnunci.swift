import Foundation

/// La coda degli annunci (05 §10.7, §11.6): un annuncio alla volta, nell'ordine di arrivo. Un annuncio
/// INTERROMPENTE — l'esito che il giocatore ha appena chiesto — supera ciò che attende e ciò che si
/// sta dicendo: i fatti superati restano nel registro (00 §6.4).
///
/// È un tipo puro, senza interfaccia: `PuntoSegnali` gli chiede che cosa pronunciare e gli riferisce
/// le conclusioni che il sistema notifica. Sta a parte perché la sua regola si provi senza VoiceOver.
///
/// LA CONCLUSIONE TARDIVA (incarico 30). Un annuncio interrotto da uno interrompente conclude anche
/// lui, più tardi e senza successo, e il sistema lo notifica come ogni altra conclusione. Se quella
/// notifica facesse avanzare la coda, il fatto di fondo successivo partirebbe subito e taglierebbe
/// proprio l'annuncio che ha interrotto. La coda ricorda perciò il testo degli annunci che ha
/// interrotto e ne ignora la conclusione; una conclusione che non riconosce la tratta come quella
/// dell'annuncio in corso, sicché nessun caso la può fermare.
struct CodaAnnunci<Annuncio> {

    /// Gli annunci non ancora pronunciati, dal primo che uscirà.
    private(set) var inAttesa: [(testo: String, annuncio: Annuncio)] = []
    /// Il testo dell'annuncio che si sta pronunciando, se ce n'è uno.
    private(set) var inCorso: String?
    /// I testi degli annunci interrotti di cui la conclusione non è ancora arrivata.
    private(set) var interrotti: [String] = []

    /// Il tetto dei testi interrotti ricordati: numero di STRUTTURA e non di gioco (05 §0.4). Una
    /// conclusione che non arrivasse mai non deve far crescere l'elenco per sempre.
    static var tettoDegliInterrotti: Int { 8 }

    /// Accoda un annuncio. Restituisce quello da pronunciare SUBITO, se ce n'è uno: l'annuncio stesso
    /// quando nulla è in corso o quando interrompe, nulla quando deve attendere il proprio turno.
    mutating func accoda(_ annuncio: Annuncio, testo: String, interrompente: Bool) -> Annuncio? {
        if interrompente {
            if let interrotto = inCorso {
                interrotti.append(interrotto)
                if interrotti.count > Self.tettoDegliInterrotti {
                    interrotti.removeFirst(interrotti.count - Self.tettoDegliInterrotti)
                }
            }
            inAttesa.removeAll()
            inCorso = nil
        }
        inAttesa.append((testo: testo, annuncio: annuncio))
        return prossimo()
    }

    /// Il sistema notifica che un annuncio è concluso; `testo` è quello che la notifica dichiara, se
    /// lo dichiara. Restituisce il prossimo annuncio da pronunciare, se ce n'è uno.
    mutating func concluso(testo: String?) -> Annuncio? {
        if let testo, testo != inCorso, let indice = interrotti.firstIndex(of: testo) {
            interrotti.remove(at: indice)
            return nil
        }
        inCorso = nil
        return prossimo()
    }

    /// Dimentica tutto: ciò che attende, ciò che è in corso e ciò che è stato interrotto (incarico 32).
    /// Serve quando il lettore di schermo si accende: degli annunci consegnati a lettore spento il
    /// sistema non notifica la conclusione, e la coda li attenderebbe per sempre.
    mutating func svuota() {
        inAttesa.removeAll()
        inCorso = nil
        interrotti.removeAll()
    }

    private mutating func prossimo() -> Annuncio? {
        guard inCorso == nil, !inAttesa.isEmpty else { return nil }
        let primo = inAttesa.removeFirst()
        inCorso = primo.testo
        return primo.annuncio
    }
}

/// Se uno spostamento del fuoco è IN ARRIVO (incarico 32, RDA-183). Il gioco lo chiede — spostando il
/// fuoco, o consegnando un fatto a cui segue un'altra schermata —, e VoiceOver lo applica più tardi:
/// 0,77–0,80 secondi dopo la richiesta, misurati sui simulatori dell'iPhone e dell'iPad. Un annuncio
/// che esce in quell'intervallo a priorità predefinita è tagliato dalla lettura dell'elemento su cui il
/// fuoco arriva; il punto dei segnali lo fa uscire perciò a priorità alta.
///
/// La finestra è più larga del tempo misurato, perché un apparecchio può essere più lento, e non si
/// chiude all'arrivo del fuoco, perché il sistema può spostarlo più d'una volta per la stessa azione
/// (un pannello che si congeda, poi la schermata che il gioco mostra). Essere larga non costa nulla a
/// chi ascolta: la priorità alta cambia soltanto che cosa può interrompere l'annuncio — non la lettura
/// di ciò che compare da sé, sempre il gesto di chi gioca.
struct FinestraDelFuoco {
    /// L'istante dell'ultima richiesta, se ce n'è stata una.
    private(set) var chiestoA: TimeInterval?
    /// Quanto resta aperta: tempo d'interfaccia e non di gioco (05 §0.4, 00 §4.2 — nulla scade per chi
    /// gioca: cambia soltanto la priorità con cui un annuncio esce).
    static let durata: TimeInterval = 2

    mutating func chiesto(a istante: TimeInterval) { chiestoA = istante }

    func eAperta(a istante: TimeInterval) -> Bool {
        guard let chiestoA else { return false }
        return istante >= chiestoA && istante - chiestoA <= Self.durata
    }
}

/// LA CONFERMA DEL FUOCO (incarico 32, RDA-192). Alla comparsa e al congedo di una schermata VoiceOver
/// applica la richiesta del gioco 0,77–0,80 secondi dopo, ma non sempre sull'elemento chiesto: a volte su
/// un altro della stessa schermata, che sceglie da sé. Misurato sui simulatori dell'iPhone, al ritorno in
/// patria dopo una campagna: sette volte su sedici; sull'iPad mai. Perché lo faccia non si è accertato.
///
/// Perciò la richiesta si conferma: se l'elemento della schermata che riceve il fuoco quando VoiceOver la
/// applica non è quello chiesto, la si rinnova, una volta sola. Chi riceve il fuoco prima non conta, perché
/// la richiesta è ancora in viaggio; dopo, chi si muove è chi gioca, e il gioco non gli riporta il fuoco
/// (00 §11.1).
public struct ConfermaDelFuoco {
    /// L'istante della richiesta che nessun elemento della schermata ha ancora confermato o smentito.
    private var chiestoA: TimeInterval?
    /// Quanto resta in viaggio, al meno: meno di quanto VoiceOver impiega ad applicarla. Tempo d'interfaccia
    /// e non di gioco (05 §0.4).
    static let viaggio: TimeInterval = 0.5

    public init() {}

    public mutating func chiesto(a istante: TimeInterval) { chiestoA = istante }

    /// Un elemento della schermata ha ricevuto il fuoco. Vero se la richiesta va rinnovata.
    public mutating func raggiunto(bersaglio: Bool, a istante: TimeInterval) -> Bool {
        guard let inizio = chiestoA, istante - inizio >= Self.viaggio else { return false }
        chiestoA = nil
        return !bersaglio && istante - inizio <= FinestraDelFuoco.durata
    }
}
