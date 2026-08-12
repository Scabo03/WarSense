import UIKit
import Dati
import Motore
import Segnali

/// La schermata dello scontro (05 §15.3): griglia, deck, comandi globali.
/// Ordine di lettura dichiarato elemento per elemento (00 §11.5, 02 §2.8);
/// il fuoco non si sposta mai in modo non richiesto (00 §11.1).
@MainActor
final class SchermataBattaglia: UIViewController {

    private let partita: PartitaCorrente
    private var statoCorrente: StatoBattaglia?
    private var elementi: [Cella: ElementoCella] = [:]
    private var ordineCelle: [Cella] = []
    private var designazione: CostruttoreAnnunci.Designazione = .nessuna
    private var ultimaRigaDelFuoco: Int?
    var alTermine: (() -> Void)?

    private let scorrimento = UIScrollView()
    private let vistaGriglia = VistaGriglia()
    private let intestazioneDeck = UILabel()
    private let scorrimentoDeck = UIScrollView()
    private let rigaDeck = UIStackView()
    private var tessereDeck: [TesseraDeck] = []
    private let colonnaDeck = UIStackView()
    /// Area scorrevole propria del deck: quando lo spazio verticale manca (orizzontale,
    /// caratteri grandi) la colonna del deck scorre invece di comprimere la griglia, che
    /// conserva un minimo richiesto. Il deck non determina più l'altezza della griglia.
    private let scorrimentoColonna = UIScrollView()
    /// Altezza minima RICHIESTA della griglia: sufficiente a una riga intera di celle
    /// più i margini (00 §10.4, principio 1). È il numero che impedisce il collasso.
    private static let altezzaMinimaGriglia: CGFloat = 120
    private let pulsanteAnnulla = UIButton(type: .system)
    private let pulsanteAzzera = UIButton(type: .system)
    private let pulsanteResa = UIButton(type: .system)
    private let pulsanteFineTurno = UIButton(type: .system)

    init(partita: PartitaCorrente) {
        self.partita = partita
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    private var testi: Testi { partita.ambiente.testi }
    private var costruttore: CostruttoreAnnunci? {
        guard let stato = statoCorrente else { return nil }
        return CostruttoreAnnunci(testi: testi, motore: partita.motore,
                                  stato: stato, verbosita: Impostazioni.verbosita)
    }

    // MARK: - Impianto

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        partita.consegnaEventi = { [weak self] eventi in self?.ricevi(eventi) }
        montaViste()
        Task { await avvia() }
    }

    private func montaViste() {
        scorrimento.translatesAutoresizingMaskIntoConstraints = false
        scorrimento.maximumZoomScale = 2.5
        scorrimento.minimumZoomScale = 0.5
        scorrimento.delegate = self
        view.addSubview(scorrimento)
        scorrimento.addSubview(vistaGriglia)

        intestazioneDeck.font = .preferredFont(forTextStyle: .headline)
        intestazioneDeck.adjustsFontForContentSizeCategory = true
        intestazioneDeck.isAccessibilityElement = true
        intestazioneDeck.accessibilityTraits = .header
        colonnaDeck.axis = .vertical
        colonnaDeck.spacing = 6
        colonnaDeck.translatesAutoresizingMaskIntoConstraints = false
        scorrimentoColonna.translatesAutoresizingMaskIntoConstraints = false
        scorrimentoColonna.showsVerticalScrollIndicator = false
        view.addSubview(scorrimentoColonna)
        scorrimentoColonna.addSubview(colonnaDeck)
        colonnaDeck.addArrangedSubview(intestazioneDeck)

        // Le tessere del deck in una riga scorrevole: riquadri di un insieme di
        // forze, mai una pila che comprime o spinge fuori schermo (00 §1.2).
        scorrimentoDeck.showsHorizontalScrollIndicator = false
        rigaDeck.axis = .horizontal
        rigaDeck.spacing = 8
        rigaDeck.alignment = .center
        // Le tessere hanno dimensione fissa e compatta (TesseraDeck): la riga non le
        // stira più a riempire la larghezza (modifica di RDA-50 per decisione del
        // titolare). Poche tessere stanno a sinistra; molte (i rinforzi futuri) fanno
        // scorrere la riga lateralmente, mai comprimere (00 §1.2).
        rigaDeck.translatesAutoresizingMaskIntoConstraints = false
        scorrimentoDeck.addSubview(rigaDeck)
        colonnaDeck.addArrangedSubview(scorrimentoDeck)
        NSLayoutConstraint.activate([
            rigaDeck.topAnchor.constraint(equalTo: scorrimentoDeck.contentLayoutGuide.topAnchor),
            rigaDeck.bottomAnchor.constraint(equalTo: scorrimentoDeck.contentLayoutGuide.bottomAnchor),
            rigaDeck.leadingAnchor.constraint(equalTo: scorrimentoDeck.contentLayoutGuide.leadingAnchor),
            rigaDeck.trailingAnchor.constraint(equalTo: scorrimentoDeck.contentLayoutGuide.trailingAnchor),
            scorrimentoDeck.frameLayoutGuide.heightAnchor
                .constraint(equalTo: scorrimentoDeck.contentLayoutGuide.heightAnchor),
        ])

        // I comandi globali, distanziati dal bordo inferiore e di altezza piena (02 §8.5).
        for (pulsante, azione) in [(pulsanteAnnulla, #selector(annulla)),
                                   (pulsanteAzzera, #selector(azzera)),
                                   (pulsanteResa, #selector(dichiaraResa)),
                                   (pulsanteFineTurno, #selector(fineTurno))] {
            pulsante.addTarget(self, action: azione, for: .touchUpInside)
            pulsante.titleLabel?.font = .preferredFont(forTextStyle: .body)
            pulsante.titleLabel?.adjustsFontForContentSizeCategory = true
            colonnaDeck.addArrangedSubview(pulsante)
            pulsante.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        }

        // L'altezza della griglia è desiderata al 55% a bassa priorità, ma NON scende
        // mai sotto il minimo richiesto: quando lo spazio manca (orizzontale, caratteri
        // grandi) è la COLONNA DEL DECK a scorrere, non la griglia a collassare. Prima
        // il deck ne determinava l'altezza e la griglia spariva (S10, principio 1).
        let altezzaGriglia = scorrimento.heightAnchor.constraint(
            equalTo: view.heightAnchor, multiplier: 0.55)
        altezzaGriglia.priority = .defaultLow
        NSLayoutConstraint.activate([
            scorrimento.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scorrimento.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scorrimento.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            altezzaGriglia,
            scorrimento.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.altezzaMinimaGriglia),
            scorrimentoColonna.topAnchor.constraint(equalTo: scorrimento.bottomAnchor, constant: 8),
            scorrimentoColonna.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scorrimentoColonna.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scorrimentoColonna.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            colonnaDeck.topAnchor.constraint(equalTo: scorrimentoColonna.contentLayoutGuide.topAnchor),
            colonnaDeck.bottomAnchor.constraint(equalTo: scorrimentoColonna.contentLayoutGuide.bottomAnchor),
            colonnaDeck.leadingAnchor.constraint(equalTo: scorrimentoColonna.contentLayoutGuide.leadingAnchor),
            colonnaDeck.trailingAnchor.constraint(equalTo: scorrimentoColonna.contentLayoutGuide.trailingAnchor),
            colonnaDeck.widthAnchor.constraint(equalTo: scorrimentoColonna.frameLayoutGuide.widthAnchor),
        ])
    }

    private func avvia() async {
        let stato = await partita.stato
        statoCorrente = stato
        vistaGriglia.griglia = stato.griglia
        let dimensione = VistaGriglia.dimensione(per: stato.griglia)
        vistaGriglia.frame = CGRect(origin: .zero, size: dimensione)
        scorrimento.contentSize = dimensione

        // Gli elementi si creano UNA volta e si aggiornano sul posto (05 §10.1).
        ordineCelle = stato.griglia.tutteLeCelle // ovest-est, alto-basso (00 §11.5)
        for cella in ordineCelle {
            let elemento = ElementoCella(cella: cella, contenitore: vistaGriglia, schermata: self)
            elemento.accessibilityFrameInContainerSpace = VistaGriglia.cornice(di: cella)
            elementi[cella] = elemento
        }
        vistaGriglia.accessibilityElements = ordineCelle.map { elementi[$0]! }
        montaDeck(stato: stato)
        montaRotori()
        aggiorna(con: stato)

        // Annuncio di apertura (02 §4.4.2) e fuoco sull'intestazione del deck (02 §2.9).
        if let costruttore {
            partita.ambiente.segnali.annuncia(
                TestoLocalizzato(testo: costruttore.annuncioApertura(), lingua: testi.lingua))
        }
        let eventi = await partita.eventiIniziali
        ricevi(eventi)
        // Se la battaglia si apre col turno dell'avversario — primo occupante l'avversario, 01
        // §9.4.1 — lo si fa agire subito, o lo scontro resterebbe bloccato nel suo turno (incarico
        // 24). Solo allora: negli scontri col giocatore primo occupante (tutti quelli del menu) non
        // si tocca il flusso, per non introdurre un punto di sospensione prima del fuoco d'apertura.
        if stato.parteDiTurno == .avversario, stato.esito == nil {
            try? await partita.muoviAvversarioSeTocca()
        }
        Fuoco.sposta(a: intestazioneDeck, perche: .schermataAperta)
        // Battaglia RIPRESA già conclusa (incarico 24): se l'applicazione è stata chiusa dopo la
        // fine dello scontro ma prima che l'esito tornasse in campagna, riaprendo la battaglia si
        // ritrova l'esito e si mostra il resoconto, il cui congedo porta il ritorno in campagna.
        // Alla ripresa gli eventi sono soppressi (05 §6.3), sicché `ricevi` non lo farebbe da sé.
        if stato.esito != nil { await mostraResoconto() }
    }

    private func montaDeck(stato: StatoBattaglia) {
        intestazioneDeck.text = testi.frase("deck.intestazione").testo
        for indice in (stato.deck[.giocatore] ?? []).indices {
            let tessera = TesseraDeck()
            tessera.tag = indice
            tessera.accessibilityHint = testi.frase("deck.elemento_indicazione").testo
            tessera.addTarget(self, action: #selector(toccaElementoDeck(_:)), for: .touchUpInside)
            tessereDeck.append(tessera)
            rigaDeck.addArrangedSubview(tessera)
        }
        // L'ordine di lettura dichiarato: celle, deck, annullamento, azzeramento (02 §2.8),
        // poi la resa e la fine del turno (RDA-49).
        view.accessibilityElements = [vistaGriglia, intestazioneDeck] + tessereDeck
            + [pulsanteAnnulla, pulsanteAzzera, pulsanteResa, pulsanteFineTurno]
    }

    // MARK: - Aggiornamento sul posto (RDA-03)

    private func ricevi(_ eventi: [EventoBattaglia]) {
        Task { await ricaricaStato() }
        for evento in eventi {
            if case .battagliaConclusa = evento {
                Task { await mostraResoconto() }
            }
        }
    }

    private func ricaricaStato() async {
        let stato = await partita.stato
        statoCorrente = stato
        aggiorna(con: stato)
    }

    /// Aggiorna etichette e valori degli elementi ESISTENTI: mai ricreare,
    /// mai toccare il fuoco (00 §11.1, 05 §10.3).
    private func aggiorna(con stato: StatoBattaglia) {
        guard let costruttore else { return }
        for (cella, elemento) in elementi {
            elemento.accessibilityLabel = costruttore.etichettaCella(cella, designazione: designazione)
            elemento.accessibilityCustomActions = azioniDirezione(da: cella)
            let occupante = VistaBattaglia(motore: partita.motore, stato: stato, parte: .giocatore)
                .occupanteVisibile(di: cella)
            var tratti: UIAccessibilityTraits = []
            if stato.ostacoli.contains(cella) { tratti.insert(.notEnabled) }
            if occupante?.parte == .giocatore { tratti.insert(.button) }
            elemento.accessibilityTraits = tratti
        }
        for tessera in tessereDeck {
            let esemplari = stato.deck[.giocatore]?[tessera.tag].esemplari ?? 0
            tessera.aggiorna(nome: costruttore.nomeElementoDeck(indice: tessera.tag),
                             valore: costruttore.valoreElementoDeck(indice: tessera.tag),
                             simbolo: UIImage(named: costruttore.nomeSimboloElementoDeck(indice: tessera.tag)),
                             atomi: costruttore.atomiElementoDeck(indice: tessera.tag),
                             volume: costruttore.volumeElementoDeck(indice: tessera.tag),
                             selezionata: stato.selezione[.giocatore] == tessera.tag,
                             attiva: esemplari > 0 && stato.esito == nil)
        }
        pulsanteAnnulla.setTitle(testi.frase("pulsante.annulla").testo, for: .normal)
        pulsanteAzzera.setTitle(testi.frase("pulsante.azzera").testo, for: .normal)
        pulsanteResa.setTitle(testi.frase("pulsante.resa").testo, for: .normal)
        pulsanteFineTurno.setTitle(testi.frase("pulsante.fine_turno").testo, for: .normal)
        let mioTurno = stato.parteDiTurno == .giocatore && stato.esito == nil
        pulsanteFineTurno.isEnabled = mioTurno
        pulsanteResa.isEnabled = mioTurno && stato.resaDichiarataDa == nil

        vistaGriglia.coloreCella = { [weak self] cella in
            guard let self, let stato = self.statoCorrente else { return nil }
            if stato.ostacoli.contains(cella) { return .systemGray }
            let vista = VistaBattaglia(motore: self.partita.motore, stato: stato, parte: .giocatore)
            guard let sciame = vista.occupanteVisibile(di: cella) else { return nil }
            return sciame.parte == .giocatore ? .systemBlue : .systemRed
        }
        // La lettera compare anche a schermo: ciò che si sente si vede (01 §9.4.3).
        vistaGriglia.testoCella = { [weak self] cella in
            guard let self, let stato = self.statoCorrente else { return nil }
            let vista = VistaBattaglia(motore: self.partita.motore, stato: stato, parte: .giocatore)
            guard let sciame = vista.occupanteVisibile(di: cella) else { return nil }
            return self.costruttore?.lettera(sciame)
        }
        vistaGriglia.setNeedsDisplay()
    }

    // MARK: - Attivazione e pannello (00 §7.4, 02 §9.2.1)

    /// Una voce del pannello nella forma che l'avviso esegue al tocco: il collaudo
    /// riproduce la sequenza reale (congedo automatico dell'avviso, poi la chiusura).
    struct VocePannello {
        let titolo: String
        let stile: UIAlertAction.Style
        let esegui: () -> Void
    }
    private var vociPannello: [VocePannello] = []

    func attiva(_ cella: Cella) -> Bool {
        guard let stato = statoCorrente else { return false }
        if case .movimento(let id) = designazione {
            guard let percorso = costruttore?.percorsoMovimento(da: id, a: cella) else { return false }
            designazione = .nessuna
            Task { await eseguiComando(.muovi(sciame: id, percorso: percorso)) }
            return true
        }
        if stato.selezione[.giocatore] != nil {
            // Conferma di piazzamento: il fuoco resta sulla cella (00 §11.3).
            Task { await eseguiComando(.piazza(cella: cella)) }
            return true
        }
        if let occupante = stato.occupante(di: cella), occupante.parte == .giocatore {
            apriPannello(per: occupante, stato: stato)
            return true
        }
        return false
    }

    private func apriPannello(per sciame: Sciame, stato: StatoBattaglia) {
        let pannello = UIAlertController(
            title: testi.frase("pannello.titolo", sciame.posizione.riga, sciame.posizione.colonna).testo,
            message: nil, preferredStyle: .alert)
        let vistaAvversari = stato.sciamiOrdinati.filter { $0.parte == .avversario }
        var voci: [VocePannello] = []

        // Tiro: i soli bersagli a portata, con nome, lettera, efficacia, vicinanza e
        // accerchiamento; il proiettile è del reparto e non si sceglie
        // (02 §9.3, 01 §3.3.1, §3.4.1, §9.10.1, §9.10.2). Il testo lo compone il
        // costruttore degli annunci: la schermata non calcola dati di gioco (00 §3.2).
        for bersaglio in vistaAvversari {
            guard let titolo = costruttore?.voceTiro(da: sciame.id, su: bersaglio) else { continue }
            let comando = ComandoBattaglia.tira(sciame: sciame.id, bersaglio: bersaglio.id)
            voci.append(VocePannello(titolo: titolo, stile: .default) { [weak self] in
                self?.chiudiPannello(cella: sciame.posizione) { await self?.eseguiComando(comando) }
            })
        }
        // Ingaggio degli adiacenti (02 §8.8), designati con nome e lettera (01 §9.4.3),
        // con efficacia e accerchiamento come ogni azione con bersaglio (02 §9.2.1).
        for bersaglio in vistaAvversari {
            guard let titolo = costruttore?.voceIngaggio(da: sciame.id, su: bersaglio) else { continue }
            let comando = ComandoBattaglia.ingaggia(sciame: sciame.id, bersaglio: bersaglio.id)
            voci.append(VocePannello(titolo: titolo, stile: .default) { [weak self] in
                self?.chiudiPannello(cella: sciame.posizione) { await self?.eseguiComando(comando) }
            })
        }
        // Movimento per designazione sulla griglia (02 §9.2.1): l'azione si offre
        // soltanto se esiste almeno una destinazione raggiungibile (02 §9.5).
        if !stato.impegnato(sciame.id), !sciame.azioneSpesa, stato.parteDiTurno == .giocatore,
           VistaBattaglia(motore: partita.motore, stato: stato, parte: .giocatore)
               .esisteDestinazione(per: sciame.id) {
            voci.append(VocePannello(
                titolo: testi.frase("pannello.designa_movimento").testo, stile: .default) { [weak self] in
                guard let self else { return }
                self.designazione = .movimento(sciame: sciame.id)
                if let stato = self.statoCorrente { self.aggiorna(con: stato) }
                self.partita.ambiente.segnali.annuncia(TestoLocalizzato(
                    testo: self.testi.frase("pannello.designazione_avviata").testo,
                    lingua: self.testi.lingua))
                self.chiudiPannello(cella: sciame.posizione, poi: nil)
            })
        }
        // Evacuazione durante la ritirata (01 §10.4).
        let ritiro = ComandoBattaglia.ritiraUnita(sciame: sciame.id)
        if case .valido(let costi) = partita.motore.valida(ritiro, parte: .giocatore, stato: stato) {
            voci.append(VocePannello(
                titolo: testi.frase("pannello.ritira_unita", Int(costi.volume)).testo,
                stile: .default) { [weak self] in
                self?.chiudiPannello(cella: sciame.posizione) { await self?.eseguiComando(ritiro) }
            })
        }
        // Disingaggio su ordine, riservato al reparto elitario a contatto (incarico 10):
        // la validità è decisa dal Motore, quindi l'azione compare solo quando è ammessa e
        // per nessun altro reparto (00 §3.2: la schermata non calcola dati di gioco).
        let disingaggio = ComandoBattaglia.disingaggiaSuOrdine(sciame: sciame.id)
        if partita.motore.valida(disingaggio, parte: .giocatore, stato: stato).eValido {
            voci.append(VocePannello(
                titolo: testi.frase("pannello.disingaggia").testo, stile: .default) { [weak self] in
                self?.chiudiPannello(cella: sciame.posizione) { await self?.eseguiComando(disingaggio) }
            })
        }
        voci.append(VocePannello(titolo: testi.frase("pannello.chiudi").testo,
                                 stile: .cancel) { [weak self] in
            self?.chiudiPannello(cella: sciame.posizione, poi: nil)
        })
        for voce in voci {
            pannello.addAction(UIAlertAction(title: voce.titolo, style: voce.stile) { _ in voce.esegui() })
        }
        vociPannello = voci
        present(pannello, animated: false)
    }

    /// Alla chiusura del pannello il fuoco torna alla cella d'origine (05 §10.3).
    /// L'avviso di sistema si congeda DA SOLO al tocco di una voce: congedare qui
    /// senza pannello presentato congederebbe la schermata dello scontro stessa.
    private func chiudiPannello(cella: Cella, poi azione: (() async -> Void)?) {
        let ripristina: () -> Void = { [weak self] in
            guard let self else { return }
            Fuoco.sposta(a: self.elementi[cella], perche: .richiesto)
            if let azione { Task { await azione() } }
        }
        if let pannello = presentedViewController as? UIAlertController,
           !pannello.isBeingDismissed {
            pannello.dismiss(animated: false, completion: ripristina)
        } else {
            ripristina()
        }
    }

    // MARK: - Comandi

    private func eseguiComando(_ comando: ComandoBattaglia) async {
        do {
            let esito = try await partita.esegui(comando)
            if case .nonValido(let motivo) = esito {
                partita.ambiente.segnali.annuncia(
                    TestoLocalizzato(testo: testi.termine(motivo.rawValue).testo, lingua: testi.lingua))
            }
        } catch {
            await ricaricaStato()
        }
    }

    @objc private func toccaElementoDeck(_ tessera: UIControl) {
        guard let stato = statoCorrente else { return }
        designazione = .nessuna
        let comando: ComandoBattaglia = stato.selezione[.giocatore] == tessera.tag
            ? .deseleziona : .seleziona(indiceDeck: tessera.tag)
        Task { await eseguiComando(comando) }
    }

    @objc private func annulla() { Task { await operazioneGiornale { try await self.partita.annulla() }
        .map { self.conferma("battaglia.annullato_conferma", significato: .annullamento) } } }

    @objc private func azzera() { Task { await operazioneGiornale { try await self.partita.azzera() }
        .map { self.conferma("battaglia.azzerato_conferma", significato: .annullamento) } } }

    private func operazioneGiornale(_ operazione: () async throws -> Void) async -> Void? {
        do { try await operazione(); await ricaricaStato(); return () }
        catch {
            partita.ambiente.segnali.annuncia(TestoLocalizzato(
                testo: testi.frase("battaglia.niente_da_annullare").testo, lingua: testi.lingua))
            return nil
        }
    }

    private func conferma(_ chiave: String, significato: SignificatoSegnale) {
        partita.ambiente.segnali.annuncia(
            TestoLocalizzato(testo: testi.frase(chiave).testo, lingua: testi.lingua),
            significato: significato)
    }

    @objc private func dichiaraResa() { Task { await eseguiComando(.dichiaraResa) } }
    @objc private func fineTurno() {
        designazione = .nessuna
        Task { await eseguiComando(.fineTurno) }
    }

    // MARK: - Fuoco, righe, scorrimento (00 §11.6, §10.4)

    func fuocoArrivato(su cella: Cella) {
        let cornice = VistaGriglia.cornice(di: cella).insetBy(dx: -40, dy: -40)
        scorrimento.scrollRectToVisible(cornice, animated: false)
        if let ultima = ultimaRigaDelFuoco, ultima != cella.riga, let stato = statoCorrente {
            let vista = VistaBattaglia(motore: partita.motore, stato: stato, parte: .giocatore)
            let nemiciNellaRiga = (1...stato.griglia.colonne).contains { colonna in
                vista.occupanteVisibile(di: Cella(riga: cella.riga, colonna: colonna))?.parte == .avversario
            }
            partita.ambiente.segnali.segnalaCambioRiga(conNemici: nemiciNellaRiga)
        }
        ultimaRigaDelFuoco = cella.riga
    }

    /// Il tocco magico richiama l'informazione di stato senza lasciare la griglia (02 §6.4, §6.7).
    override func accessibilityPerformMagicTap() -> Bool {
        guard let costruttore else { return false }
        partita.ambiente.segnali.annuncia(
            TestoLocalizzato(testo: costruttore.informazioneDiStato(), lingua: testi.lingua),
            interrompente: true)
        return true
    }

    /// Il gesto di fuga annulla la designazione in corso (02 §9.2.1).
    override func accessibilityPerformEscape() -> Bool {
        if case .movimento = designazione {
            designazione = .nessuna
            if let stato = statoCorrente { aggiorna(con: stato) }
            partita.ambiente.segnali.annuncia(TestoLocalizzato(
                testo: testi.frase("pannello.designazione_annullata").testo, lingua: testi.lingua))
            return true
        }
        return false
    }

    // MARK: - Azioni personalizzate: soltanto spostamenti di navigazione (02 §2.7)

    private func azioniDirezione(da cella: Cella) -> [UIAccessibilityCustomAction] {
        guard let stato = statoCorrente else { return [] }
        let sfalsata = cella.riga % 2 == 0
        let destinazioni: [(String, Cella)] = [
            ("direzione.nord_ovest", Cella(riga: cella.riga - 1, colonna: sfalsata ? cella.colonna : cella.colonna - 1)),
            ("direzione.nord_est", Cella(riga: cella.riga - 1, colonna: sfalsata ? cella.colonna + 1 : cella.colonna)),
            ("direzione.sud_ovest", Cella(riga: cella.riga + 1, colonna: sfalsata ? cella.colonna : cella.colonna - 1)),
            ("direzione.sud_est", Cella(riga: cella.riga + 1, colonna: sfalsata ? cella.colonna + 1 : cella.colonna)),
        ]
        return destinazioni.compactMap { chiave, destinazione in
            guard stato.griglia.contiene(destinazione) else { return nil }
            let azione = UIAccessibilityCustomAction(
                name: testi.frase(chiave).testo) { [weak self] _ in
                guard let self, let elemento = self.elementi[destinazione] else { return false }
                Fuoco.sposta(a: elemento, perche: .richiesto)
                return true
            }
            return azione
        }
    }

    // MARK: - Rotori (00 §10.2, 02 §7.2)

    private func montaRotori() {
        func rotore(_ chiave: String, celle: @escaping () -> [Cella]) -> UIAccessibilityCustomRotor {
            UIAccessibilityCustomRotor(name: testi.frase(chiave).testo) { [weak self] richiesta in
                guard let self else { return nil }
                let insieme = celle().sorted()
                guard !insieme.isEmpty else { return nil }
                let corrente = (richiesta.currentItem.targetElement as? ElementoCella)?.cella
                let successiva: Cella?
                if richiesta.searchDirection == .next {
                    successiva = insieme.first { corrente == nil || corrente! < $0 } ?? insieme.first
                } else {
                    successiva = insieme.last { corrente == nil || $0 < corrente! } ?? insieme.last
                }
                guard let destinazione = successiva, let elemento = self.elementi[destinazione] else { return nil }
                return UIAccessibilityCustomRotorItemResult(targetElement: elemento, targetRange: nil)
            }
        }
        view.accessibilityCustomRotors = [
            rotore("rotore.propri_sciami") { [weak self] in
                self?.celleSciami(parte: .giocatore) ?? [] },
            rotore("rotore.propri_senza_azione") { [weak self] in
                guard let self, let stato = self.statoCorrente else { return [] }
                return stato.sciamiOrdinati
                    .filter { $0.parte == .giocatore && !$0.azioneSpesa && !stato.impegnato($0.id) }
                    .map(\.posizione) },
            rotore("rotore.sciami_avversari") { [weak self] in
                self?.celleSciami(parte: .avversario) ?? [] },
            rotore("rotore.celle_valide") { [weak self] in
                guard let self, let stato = self.statoCorrente else { return [] }
                let vista = VistaBattaglia(motore: self.partita.motore, stato: stato, parte: .giocatore)
                return vista.celleValidePerSelezione().map(\.cella) },
            rotore("rotore.rinforzi") { [weak self] in
                guard let self, let stato = self.statoCorrente else { return [] }
                return stato.sciamiOrdinati.filter { $0.parte == .giocatore && $0.rinforzo }.map(\.posizione) },
            rotore("rotore.ostacoli") { [weak self] in
                guard let stato = self?.statoCorrente else { return [] }
                return Array(stato.ostacoli) },
        ]
    }

    private func celleSciami(parte: Parte) -> [Cella] {
        guard let stato = statoCorrente else { return [] }
        let vista = VistaBattaglia(motore: partita.motore, stato: stato, parte: .giocatore)
        return vista.sciamiVisibili.filter { $0.parte == parte }.map(\.posizione)
    }

    // MARK: - Resoconto

    private func mostraResoconto() async {
        guard let costruttore else { return }
        let schermata = SchermataResoconto(voci: costruttore.vociResoconto(), testi: testi)
        schermata.alTermine = { [weak self] in self?.alTermine?() }
        schermata.modalPresentationStyle = .fullScreen
        present(schermata, animated: false)
        Fuoco.sposta(a: nil, perche: .schermataAperta)
    }

    // Attrezzi per le prove ospitate (05 §14.4).
    var elementiPerProva: [Cella: ElementoCella] { elementi }
    var registroFuocoPerProva: [Fuoco.Movimento] { Fuoco.registro }
    var vociPannelloPerProva: [VocePannello] { vociPannello }
    /// La griglia come `VistaACaselle`: le prove del tocco diretto girano
    /// con lo stesso corpo sui due piani (02 §2.11, RDA-78).
    var grigliaPerProva: VistaACaselle { vistaGriglia }
    var tesserePerProva: [TesseraDeck] { rigaDeck.arrangedSubviews.compactMap { $0 as? TesseraDeck } }
    var costruttorePerProva: CostruttoreAnnunci? { costruttore }
    var partitaPerProva: PartitaCorrente { partita }
}

extension SchermataBattaglia: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { vistaGriglia }
}
