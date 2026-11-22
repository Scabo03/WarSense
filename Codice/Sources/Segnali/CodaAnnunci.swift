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

    private mutating func prossimo() -> Annuncio? {
        guard inCorso == nil, !inAttesa.isEmpty else { return nil }
        let primo = inAttesa.removeFirst()
        inCorso = primo.testo
        return primo.annuncio
    }
}
