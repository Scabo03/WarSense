import UIKit
import Dati
import Motore
import Segnali
import Sessione

/// La mappa di campagna (05 §9.3, §15.5): caselle quadrate, comandi globali,
/// registro. Ordine di lettura dichiarato elemento per elemento (00 §11.5,
/// 02 §2.8); il fuoco non si sposta mai in modo non richiesto (00 §11.1);
/// gli elementi si creano una volta e si aggiornano sul posto (05 §10.1, RDA-03).
///
/// La schermata è costruita sullo stesso modello di quella di battaglia perché il
/// linguaggio di interazione è unico (00 §7): scorrimento orizzontale lungo la
/// riga, direzioni restanti nelle azioni personalizzate (due sole, nord e sud:
/// 02 §2.5), azioni di gioco nel pannello che si apre attivando la casella,
/// tocco magico per l'informazione di stato, gesto di fuga per risalire.
@MainActor
final class SchermataMappaCampagna: UIViewController {

    private let partita: PartitaCampagna
    private var statoCorrente: StatoCampagna?
    private var elementi: [Cella: ElementoCasella] = [:]
    private var ordineCaselle: [Cella] = []
    private var designazione: CostruttoreAnnunciCampagna.Designazione = .nessuna
    private var ultimaRigaDelFuoco: Int?
    var alTermine: (() -> Void)?

    private let scorrimento = UIScrollView()
    private let vistaMappa = VistaMappa()
    private let colonnaComandi = UIStackView()
    /// Area scorrevole propria della banda dei comandi: quando lo spazio verticale
    /// manca (orizzontale, caratteri grandi) i comandi scorrono invece di comprimere
    /// la mappa, che conserva un minimo richiesto. Come in battaglia (00 §10.4).
    private let scorrimentoComandi = UIScrollView()
    /// Altezza minima RICHIESTA della mappa: sufficiente a una riga intera di caselle.
    private static let altezzaMinimaMappa: CGFloat = 120
    private let pulsanteRegistro = UIButton(type: .system)
    private let pulsanteChiudiGiornata = UIButton(type: .system)
    private let pulsanteAnnulla = UIButton(type: .system)
    private let pulsanteAzzera = UIButton(type: .system)
    private let pulsanteEsci = UIButton(type: .system)

    init(partita: PartitaCampagna) {
        self.partita = partita
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    private var testi: Testi { partita.ambiente.testi }
    private var costruttore: CostruttoreAnnunciCampagna? {
        guard let stato = statoCorrente else { return nil }
        return CostruttoreAnnunciCampagna(testi: testi, motore: partita.motore,
                                          stato: stato, verbosita: Impostazioni.verbosita)
    }

    // MARK: - Impianto

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        montaViste()
        Task { await avvia() }
    }

    private func montaViste() {
        scorrimento.translatesAutoresizingMaskIntoConstraints = false
        scorrimento.maximumZoomScale = 2.5
        scorrimento.minimumZoomScale = 0.5
        scorrimento.delegate = self
        view.addSubview(scorrimento)
        scorrimento.addSubview(vistaMappa)

        colonnaComandi.axis = .vertical
        colonnaComandi.spacing = 6
        colonnaComandi.translatesAutoresizingMaskIntoConstraints = false
        scorrimentoComandi.translatesAutoresizingMaskIntoConstraints = false
        scorrimentoComandi.showsVerticalScrollIndicator = false
        view.addSubview(scorrimentoComandi)
        scorrimentoComandi.addSubview(colonnaComandi)
        for (pulsante, azione) in [(pulsanteRegistro, #selector(apriRegistro)),
                                   (pulsanteChiudiGiornata, #selector(chiudiGiornata)),
                                   (pulsanteAnnulla, #selector(annulla)),
                                   (pulsanteAzzera, #selector(azzera)),
                                   (pulsanteEsci, #selector(esci))] {
            pulsante.addTarget(self, action: azione, for: .touchUpInside)
            pulsante.titleLabel?.font = .preferredFont(forTextStyle: .body)
            pulsante.titleLabel?.adjustsFontForContentSizeCategory = true
            pulsante.titleLabel?.numberOfLines = 0
            colonnaComandi.addArrangedSubview(pulsante)
            pulsante.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        }

        // L'altezza della mappa è desiderata al 60% a bassa priorità, ma NON scende
        // mai sotto il minimo richiesto: quando lo spazio manca è la banda dei comandi
        // a scorrere, non la mappa a collassare (principio 1, 00 §10.4).
        let altezzaMappa = scorrimento.heightAnchor.constraint(
            equalTo: view.heightAnchor, multiplier: 0.6)
        altezzaMappa.priority = .defaultLow
        NSLayoutConstraint.activate([
            scorrimento.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scorrimento.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scorrimento.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            altezzaMappa,
            scorrimento.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.altezzaMinimaMappa),
            scorrimentoComandi.topAnchor.constraint(equalTo: scorrimento.bottomAnchor, constant: 8),
            scorrimentoComandi.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scorrimentoComandi.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scorrimentoComandi.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            colonnaComandi.topAnchor.constraint(equalTo: scorrimentoComandi.contentLayoutGuide.topAnchor),
            colonnaComandi.bottomAnchor.constraint(equalTo: scorrimentoComandi.contentLayoutGuide.bottomAnchor),
            colonnaComandi.leadingAnchor.constraint(equalTo: scorrimentoComandi.contentLayoutGuide.leadingAnchor),
            colonnaComandi.trailingAnchor.constraint(equalTo: scorrimentoComandi.contentLayoutGuide.trailingAnchor),
            colonnaComandi.widthAnchor.constraint(equalTo: scorrimentoComandi.frameLayoutGuide.widthAnchor),
        ])
    }

    private func avvia() async {
        let stato = await partita.stato
        statoCorrente = stato
        vistaMappa.griglia = stato.griglia
        let dimensione = VistaMappa.dimensione(per: stato.griglia)
        vistaMappa.frame = CGRect(origin: .zero, size: dimensione)
        scorrimento.contentSize = dimensione

        // Gli elementi si creano UNA volta e si aggiornano sul posto (05 §10.1).
        ordineCaselle = stato.griglia.tutteLeCaselle // ovest-est, alto-basso (00 §11.5)
        for casella in ordineCaselle {
            let elemento = ElementoCasella(casella: casella, contenitore: vistaMappa, schermata: self)
            elemento.accessibilityFrameInContainerSpace = VistaMappa.cornice(di: casella)
            elementi[casella] = elemento
        }
        vistaMappa.accessibilityElements = ordineCaselle.map { elementi[$0]! }
        // Ordine di lettura dichiarato: prima le caselle, poi i comandi globali
        // (02 §2.8), esattamente come in battaglia.
        view.accessibilityElements = [vistaMappa, pulsanteRegistro, pulsanteChiudiGiornata,
                                      pulsanteAnnulla, pulsanteAzzera, pulsanteEsci]
        montaRotori()
        aggiorna(con: stato)

        if let costruttore {
            partita.ambiente.segnali.annuncia(
                TestoLocalizzato(testo: costruttore.annuncioApertura(), lingua: testi.lingua))
            partita.ambiente.segnali.annuncia(
                TestoLocalizzato(testo: costruttore.informazioneDiStato(), lingua: testi.lingua))
        }
        // All'apertura il fuoco va al primo gruppo che attende una decisione: è la
        // casella da cui la giornata comincia (01 §5.16).
        let vista = await partita.vista
        if let primo = vista.prossimoGruppoInAttesa(dopo: nil), let elemento = elementi[primo.posizione] {
            Fuoco.sposta(a: elemento, perche: .schermataAperta)
        } else {
            Fuoco.sposta(a: nil, perche: .schermataAperta)
        }
    }

    // MARK: - Aggiornamento sul posto (RDA-03)

    private func ricaricaStato() async {
        let stato = await partita.stato
        statoCorrente = stato
        aggiorna(con: stato)
    }

    /// Aggiorna etichette e valori degli elementi ESISTENTI: mai ricreare,
    /// mai toccare il fuoco (00 §11.1, 05 §10.3).
    private func aggiorna(con stato: StatoCampagna) {
        guard let costruttore else { return }
        for (casella, elemento) in elementi {
            elemento.accessibilityLabel = costruttore.etichettaCasella(casella, designazione: designazione)
            elemento.accessibilityCustomActions = azioniDirezione(da: casella)
            let occupata = costruttore.vista.occupante(di: casella) != nil
            elemento.accessibilityTraits = occupata ? [.button] : []
        }
        pulsanteRegistro.setTitle(testi.frase("registro.apri").testo, for: .normal)
        pulsanteChiudiGiornata.setTitle(testi.frase("giornata.chiudi").testo, for: .normal)
        pulsanteAnnulla.setTitle(testi.frase("pulsante.annulla").testo, for: .normal)
        pulsanteAzzera.setTitle(testi.frase("pulsante.azzera").testo, for: .normal)
        pulsanteEsci.setTitle(testi.frase("resoconto.torna").testo, for: .normal)

        vistaMappa.coloreCasella = { [weak self] casella in
            guard let self, let costruttore = self.costruttore else { return nil }
            if case .marcia(let id) = self.designazione,
               costruttore.vista.destinazioniValide(per: id).contains(casella) {
                return .systemGreen.withAlphaComponent(0.4)
            }
            // Il segno del nemico (incarico 23): una casella con una formazione avversaria
            // AVVISTATA si riempie interamente di ARANCIONE, come quella di un proprio gruppo
            // si riempie di BLU — stessa estensione, cambia il colore. Il colore non distingue
            // le categorie (quello lo fa la FORMA: i segni «×», «×»», «×≈» restano, `segniCasella`):
            // l'arancione dice soltanto «nemico», ridondante con la «×». Precede il blu perché la
            // compresenza è possibile (01 §6.1) e la minaccia va segnalata; la lettera centrale del
            // proprio gruppo e i segni di forma si disegnano comunque sopra il riempimento.
            if costruttore.vista.avversarioAvvistato(su: casella) { return .systemOrange }
            return costruttore.vista.occupante(di: casella) != nil ? .systemBlue : nil
        }
        vistaMappa.testoCasella = { [weak self] casella in
            guard let self, let costruttore = self.costruttore,
                  let gruppo = costruttore.vista.occupante(di: casella) else { return nil }
            return costruttore.inizialeGruppo(gruppo)
        }
        vistaMappa.segnoCasella = { [weak self] casella in
            self?.costruttore?.segniCasella(casella)
        }
        // L'avanzamento visivo di un gruppo in marcia lunga: la posizione fra le nove
        // (01 §5.6.3.4), derivata dai giorni dal Motore, mai calcolata qui (00 §3.2).
        vistaMappa.avanzamentoCasella = { [weak self] casella in
            guard let self, let costruttore = self.costruttore,
                  let gruppo = costruttore.vista.occupante(di: casella), gruppo.inMarcia
            else { return nil }
            return costruttore.vista.avanzamentoVisivo(di: gruppo.id)
        }
        vistaMappa.setNeedsDisplay()
    }

    // MARK: - Attivazione e pannello (00 §7.4, 02 §9.2.1)

    struct VocePannello {
        let titolo: String
        let stile: UIAlertAction.Style
        let esegui: () -> Void
    }
    private var vociPannello: [VocePannello] = []

    func attiva(_ casella: Cella) -> Bool {
        guard let stato = statoCorrente else { return false }
        if case .marcia(let id) = designazione {
            // L'ordine parte DIRETTAMENTE dalla voce del comando, senza pannello di
            // conferma intermedio (correzione del titolare, RDA-104). La conseguenza
            // dell'inchiodamento è già stata dichiarata sulla voce della casella di
            // destinazione, che chi ascolta ha sentito prima di attivarla: l'etichetta
            // vocale la porta (02 §9.2.1, `CostruttoreAnnunciCampagna.etichettaCasella`).
            let esito = costruttore?.vista.anteprimaMarcia(da: id, a: casella) ?? .nonValido(.gruppoIgnoto)
            designazione = .nessuna
            aggiorna(con: stato)
            switch esito {
            case .valido:
                if let comando = costruttore?.vista.comandoDiMarcia(per: id, a: casella) {
                    Task { await eseguiComando(comando) }
                }
            case .nonValido(let motivo):
                partita.ambiente.segnali.annuncia(TestoLocalizzato(
                    testo: testi.termine(motivo.rawValue).testo, lingua: testi.lingua))
            }
            return true
        }
        guard let gruppo = stato.occupante(di: casella) else { return false }
        apriPannello(per: gruppo)
        return true
    }

    /// Il pannello di conferma della revoca (01 §5.6.3.5): dichiara i giorni che si
    /// perdono e che il gruppo resta senza azione, prima della conferma.
    private func apriPannelloConfermaRevoca(gruppo: Gruppo) {
        guard let costruttore,
              let giorniPersi = costruttore.vista.giorniPersiRevocando(per: gruppo.id) else { return }
        let pannello = UIAlertController(
            title: costruttore.titoloPannello(gruppo),
            message: testi.frase("pannello.revoca_conferma", costruttore.nomeGruppo(gruppo), giorniPersi).testo,
            preferredStyle: .alert)
        let voci = [
            VocePannello(titolo: testi.frase("pannello.revoca_conferma_azione").testo,
                         stile: .destructive) { [weak self] in
                self?.chiudiPannello(casella: gruppo.posizione) {
                    await self?.eseguiComando(.revocaMarcia(gruppo: gruppo.id))
                }
            },
            VocePannello(titolo: testi.frase("pannello.marcia_rinuncia_azione").testo,
                         stile: .cancel) { [weak self] in
                self?.chiudiPannello(casella: gruppo.posizione, poi: nil)
            },
        ]
        for voce in voci {
            pannello.addAction(UIAlertAction(title: voce.titolo, style: voce.stile) { _ in voce.esegui() })
        }
        vociPannello = voci
        present(pannello, animated: false)
    }

    private func apriPannello(per gruppo: Gruppo) {
        guard let costruttore else { return }
        let pannello = UIAlertController(title: costruttore.titoloPannello(gruppo),
                                         message: nil, preferredStyle: .alert)
        var voci: [VocePannello] = []

        // Se la casella ha una battaglia in sospeso, il comando che la apre precede ogni altro
        // (01 §6.2, incarico 24). NON è un comando di campagna — non passa dalla validazione, e il
        // blocco non lo tocca — ma il passaggio all'altra schermata, che il giocatore decide (02
        // §5.6): il fuoco non si sposta se non lo chiede. Le altre azioni, bloccate, non compaiono.
        if let battaglia = statoCorrente?.battagliaInSospeso(su: gruppo.posizione) {
            voci.append(VocePannello(titolo: testi.frase("pannello.apri_battaglia").testo,
                                     stile: .default) { [weak self] in
                self?.chiudiPannello(casella: gruppo.posizione) {
                    await self?.apriLaBattaglia(battaglia)
                }
            })
        }

        // La marcia si offre soltanto se esiste almeno una destinazione: un'azione
        // impossibile in ogni sua forma non compare affatto (02 §9.5).
        if costruttore.vista.esisteDestinazione(per: gruppo.id) {
            voci.append(VocePannello(titolo: testi.frase("pannello.designa_marcia").testo,
                                     stile: .default) { [weak self] in
                guard let self else { return }
                self.designazione = .marcia(gruppo: gruppo.id)
                if let stato = self.statoCorrente { self.aggiorna(con: stato) }
                self.partita.ambiente.segnali.annuncia(TestoLocalizzato(
                    testo: self.testi.frase("pannello.marcia_designazione_avviata").testo,
                    lingua: self.testi.lingua))
                self.chiudiPannello(casella: gruppo.posizione, poi: nil)
            })
        }
        // Il presidio è sempre disponibile per un gruppo che non ha ancora agito:
        // stare fermi è un'azione ordinabile e non un'omissione (01 §5.6.0.6).
        if partita.motore.valida(.presidio(gruppo: gruppo.id),
                                 parte: .giocatore, stato: costruttore.stato).eValido {
            voci.append(VocePannello(titolo: testi.frase("pannello.presidio").testo,
                                     stile: .default) { [weak self] in
                self?.chiudiPannello(casella: gruppo.posizione) {
                    await self?.eseguiComando(.presidio(gruppo: gruppo.id))
                }
            })
        }
        // La divisione si offre a un gruppo con almeno due reparti, una casella libera
        // adiacente e la giornata non conclusa (01 §5.6.0.2): apre la schermata dei
        // reparti. È l'operazione più complessa della mappa (02 §10.3).
        if costruttore.vista.puoDividere(per: gruppo.id) {
            voci.append(VocePannello(titolo: testi.frase("pannello.dividi").testo,
                                     stile: .default) { [weak self] in
                guard let self else { return }
                if let attuale = self.presentedViewController as? UIAlertController,
                   !attuale.isBeingDismissed {
                    attuale.dismiss(animated: false) { self.apriSchermataDivisione(per: gruppo) }
                } else {
                    self.apriSchermataDivisione(per: gruppo)
                }
            })
        }
        // La riunione (non è un'azione, 01 §5.6.0.3): una voce per ciascun gruppo
        // proprio adiacente e non in marcia. Attivarla riunisce e non apre schermate.
        for altro in costruttore.vista.gruppiRiunibili(con: gruppo.id) {
            voci.append(VocePannello(
                titolo: testi.frase("pannello.riunisci", costruttore.nomeGruppo(altro)).testo,
                stile: .default) { [weak self] in
                self?.chiudiPannello(casella: gruppo.posizione) {
                    await self?.eseguiComando(.riunione(gruppo: gruppo.id, con: altro.id))
                }
            })
        }
        // Le azioni dell'incarico 19, ciascuna offerta SOLO se il Motore la valida: la
        // Presentazione non giudica la categoria né il bersaglio, chiede al Motore (00 §3.2).
        // L'ESPLORAZIONE (riservata agli esploratori, 01 §5.4): risolve subito, sulla casella.
        if partita.motore.valida(.esplorazione(gruppo: gruppo.id),
                                 parte: .giocatore, stato: costruttore.stato).eValido {
            voci.append(VocePannello(titolo: testi.frase("pannello.esplora").testo,
                                     stile: .default) { [weak self] in
                self?.chiudiPannello(casella: gruppo.posizione) {
                    await self?.eseguiComando(.esplorazione(gruppo: gruppo.id))
                }
            })
        }
        // Il SABOTAGGIO (gruppi armati o esploratori co-locati con una non armata avversaria,
        // 01 §5.10.2): disperde il bersaglio, o — per esploratori sotto soglia — li fa notare.
        if partita.motore.valida(.sabotaggio(gruppo: gruppo.id),
                                 parte: .giocatore, stato: costruttore.stato).eValido {
            voci.append(VocePannello(titolo: testi.frase("pannello.sabota").testo,
                                     stile: .destructive) { [weak self] in
                self?.chiudiPannello(casella: gruppo.posizione) {
                    await self?.eseguiComando(.sabotaggio(gruppo: gruppo.id))
                }
            })
        }
        // Lo STUDIO APPROFONDITO (esploratori co-locati con una non armata avversaria,
        // 01 §5.10.2): ne porta a confermato composizione, carico e direzione.
        if partita.motore.valida(.studioApprofondito(gruppo: gruppo.id),
                                 parte: .giocatore, stato: costruttore.stato).eValido {
            voci.append(VocePannello(titolo: testi.frase("pannello.studia").testo,
                                     stile: .default) { [weak self] in
                self?.chiudiPannello(casella: gruppo.posizione) {
                    await self?.eseguiComando(.studioApprofondito(gruppo: gruppo.id))
                }
            })
        }
        // L'IMBOSCATA (gruppi armati, 01 §5.11): colloca il gruppo in agguato nella casella e
        // CONSUMA l'azione della giornata (incarico 21). È un ordine da RIPETERE ogni giornata —
        // non uno stato che dura: si offre a un gruppo in attesa come il presidio, e il mattino
        // dopo il gruppo torna in attesa e va riappostato. Non esiste più una revoca dell'imboscata.
        if partita.motore.valida(.imboscata(gruppo: gruppo.id),
                                 parte: .giocatore, stato: costruttore.stato).eValido {
            voci.append(VocePannello(titolo: testi.frase("pannello.imboscata").testo,
                                     stile: .default) { [weak self] in
                self?.chiudiPannello(casella: gruppo.posizione) {
                    await self?.eseguiComando(.imboscata(gruppo: gruppo.id))
                }
            })
        }
        // La revoca si offre soltanto a un gruppo in marcia lunga: congeda il
        // pannello del gruppo e apre quello di conferma, che dichiara i giorni persi.
        if gruppo.inMarcia {
            voci.append(VocePannello(titolo: testi.frase("pannello.revoca").testo,
                                     stile: .destructive) { [weak self] in
                guard let self else { return }
                if let attuale = self.presentedViewController as? UIAlertController,
                   !attuale.isBeingDismissed {
                    attuale.dismiss(animated: false) { self.apriPannelloConfermaRevoca(gruppo: gruppo) }
                } else {
                    self.apriPannelloConfermaRevoca(gruppo: gruppo)
                }
            })
        }
        voci.append(VocePannello(titolo: testi.frase("pannello.chiudi").testo,
                                 stile: .cancel) { [weak self] in
            self?.chiudiPannello(casella: gruppo.posizione, poi: nil)
        })
        for voce in voci {
            pannello.addAction(UIAlertAction(title: voce.titolo, style: voce.stile) { _ in voce.esegui() })
        }
        vociPannello = voci
        present(pannello, animated: false)
    }

    /// Presenta la schermata di divisione del gruppo (01 §5.6.0.2, 02 §10.3). Alla
    /// conferma forma il comando con i reparti scelti — il Motore lo valida, la
    /// Presentazione non lo giudica — e lo esegue.
    private func apriSchermataDivisione(per gruppo: Gruppo) {
        guard let costruttore else { return }
        let schermata = SchermataDivisione(
            gruppo: gruppo,
            destinazioni: costruttore.vista.destinazioniValide(per: gruppo.id),
            testi: testi)
        schermata.alConferma = { [weak self] staccati, cella in
            guard let self,
                  let comando = self.costruttore?.vista.comandoDiDivisione(
                    per: gruppo.id, staccando: staccati, a: cella) else { return }
            Task { await self.eseguiComando(comando) }
        }
        schermata.modalPresentationStyle = .fullScreen
        present(schermata, animated: false)
    }

    /// Alla chiusura il fuoco torna alla casella d'origine (05 §10.3). L'avviso di
    /// sistema si congeda DA SOLO al tocco di una voce: si congeda qui soltanto un
    /// pannello ancora presentato (precisazione P5).
    private func chiudiPannello(casella: Cella, poi azione: (() async -> Void)?) {
        let ripristina: () -> Void = { [weak self] in
            guard let self else { return }
            Fuoco.sposta(a: self.elementi[casella], perche: .richiesto)
            if let azione { Task { await azione() } }
        }
        if let pannello = presentedViewController as? UIAlertController, !pannello.isBeingDismissed {
            pannello.dismiss(animated: false, completion: ripristina)
        } else {
            ripristina()
        }
    }

    // MARK: - Passaggio alla battaglia e ritorno (01 §6, §15, incarico 24)

    /// Apre la battaglia in sospeso e PRESENTA la schermata di battaglia (01 §6.2): il passaggio
    /// avviene ORA, per scelta del giocatore, e non forzato all'innesco. Al termine dello scontro
    /// — congedato il resoconto — si torna a questa mappa e l'esito vi si piega (`concludiLaBattaglia`).
    private func apriLaBattaglia(_ battaglia: BattagliaInSospeso) async {
        do {
            let partitaBattaglia = try await partita.apriBattaglia(battaglia)
            let schermata = SchermataBattaglia(partita: partitaBattaglia)
            schermata.modalPresentationStyle = .fullScreen
            schermata.alTermine = { [weak self] in
                self?.dismiss(animated: false) {
                    Task { await self?.concludiLaBattaglia(battaglia, partitaBattaglia: partitaBattaglia) }
                }
            }
            present(schermata, animated: false)
            Fuoco.azzeraRegistro()
        } catch {
            partita.ambiente.segnali.annuncia(TestoLocalizzato(
                testo: testi.frase("campagna.battaglia_non_apribile").testo, lingua: testi.lingua),
                interrompente: true)
        }
    }

    /// Riporta l'esito in campagna a battaglia conclusa (01 §15): legge lo stato finale della
    /// battaglia, lo piega sulla mappa attraverso la Sessione — che lo iscrive nel giornale di
    /// campagna — e aggiorna la schermata. Se la battaglia non è conclusa (uscita anomala) non
    /// piega nulla: la battaglia resta in sospeso e si potrà riaprire.
    private func concludiLaBattaglia(_ battaglia: BattagliaInSospeso,
                                     partitaBattaglia: PartitaCorrente) async {
        let statoBattaglia = await partitaBattaglia.stato
        guard statoBattaglia.esito != nil else { return }
        var esito = await partita.esitoDiRitorno(battaglia, statoBattaglia: statoBattaglia)
        // Se il gruppo del GIOCATORE ripiega (sconfitto sopravvissuto, non nella casella contesa), il
        // giocatore SCEGLIE dove, a battaglia appena conclusa (01 §10.6, incarico 25). Con una sola
        // casella disponibile non c'è scelta da offrire; con nessuna, resta (il caso limite, S25a).
        if esito.sconfitto == .giocatore, let pos = esito.posizioneGiocatore, pos != battaglia.casella {
            let candidati = await partita.caselleDiRipiegamento(perLaCasella: battaglia.casella)
            if candidati.count > 1, let scelta = await scegliRipiegamento(fra: candidati) {
                esito = esito.conPosizioneGiocatore(scelta)
            }
        }
        do { try await partita.concludiBattaglia(battaglia, esito: esito) }
        catch { }
        await ricaricaStato()
        Fuoco.sposta(a: elementi[esito.posizione(di: .giocatore) ?? battaglia.casella], perche: .schermataAperta)
    }

    /// Offre le CASELLE DI RIPIEGAMENTO, ciascuna come voce a sé in una frase compatta, e attende la
    /// scelta del giocatore attivando una voce (01 §10.6, 02 §8, incarico 25). Nessuna tabella,
    /// nessun trascinamento. Non c'è congedo: lo sconfitto DEVE ripiegare, e sceglie soltanto dove.
    private func scegliRipiegamento(fra candidati: [Cella]) async -> Cella? {
        await withCheckedContinuation { (cont: CheckedContinuation<Cella?, Never>) in
            let pannello = UIAlertController(title: testi.frase("ripiegamento.titolo").testo,
                                             message: nil, preferredStyle: .alert)
            for cella in candidati {
                let titolo = testi.frase("ripiegamento.casella", cella.riga, cella.colonna).testo
                pannello.addAction(UIAlertAction(title: titolo, style: .default) { _ in
                    cont.resume(returning: cella)
                })
            }
            present(pannello, animated: false)
        }
    }

    // MARK: - Comandi

    private func eseguiComando(_ comando: ComandoCampagna) async {
        do {
            let esito = try await partita.esegui(comando)
            if case .nonValido(let motivo) = esito {
                partita.ambiente.segnali.annuncia(
                    TestoLocalizzato(testo: testi.termine(motivo.rawValue).testo, lingua: testi.lingua))
            }
        } catch { }
        await ricaricaStato()
    }

    @objc private func annulla() {
        Task { await operazioneGiornale({ try await self.partita.annulla() },
                                        conferma: "campagna.annullato_conferma",
                                        confermaConRiapertura: "campagna.annullato_giornata_riaperta") }
    }

    @objc private func azzera() {
        Task { await operazioneGiornale({ try await self.partita.azzera() },
                                        conferma: "campagna.azzerato_conferma",
                                        confermaConRiapertura: "campagna.azzerato_giornata_riaperta") }
    }

    /// La CHIUSURA ESPLICITA della giornata (incarico 26, decisione del titolare): sempre
    /// disponibile, chiude la giornata quale che sia lo stato dei gruppi. Annuncia — con significato
    /// di conferma, non interrompente — e NON sposta il fuoco (nessun `Fuoco.sposta`), come annulla e
    /// azzera. Se la giornata non si sarebbe chiusa da sé (c'erano gruppi non-agiti), il gioco ne ha
    /// conservato la traccia accanto al salvataggio, e l'annuncio lo dice.
    @objc private func chiudiGiornata() {
        Task {
            let diagnostica = try? await partita.chiudiGiornata()
            await ricaricaStato()
            let testo: String
            if let d = diagnostica, d.laGiornataNonSiSarebbeChiusa {
                testo = testi.frase("giornata.chiusa_con_diagnostica", d.gruppiNonAgiti.count).testo
            } else {
                testo = testi.frase("giornata.chiusa_conferma").testo
            }
            partita.ambiente.segnali.annuncia(
                TestoLocalizzato(testo: testo, lingua: testi.lingua), significato: .conferma)
        }
    }

    /// La riapertura della giornata si annuncia con una frase PROPRIA: è un
    /// cambiamento di stato rilevante e diverso da un annullamento ordinario
    /// (00 §11.4). Chi ascolta deve sapere non solo che l'ordine è stato ritirato,
    /// ma che il calendario è tornato indietro.
    private func operazioneGiornale(_ operazione: () async throws -> SessioneCampagna.EsitoAnnullamento,
                                    conferma chiave: String,
                                    confermaConRiapertura chiaveRiapertura: String) async {
        do {
            let esito = try await operazione()
            await ricaricaStato()
            let testo = esito.giornataRiaperta
                ? testi.frase(chiaveRiapertura, esito.giorno).testo
                : testi.frase(chiave).testo
            partita.ambiente.segnali.annuncia(
                TestoLocalizzato(testo: testo, lingua: testi.lingua),
                significato: .annullamento)
        } catch SessioneCampagna.ErroreSessione.oltreLaGiornataInCorso {
            // Il rifiuto al confine non è silenzioso e ha un motivo PROPRIO, distinto
            // da «niente da annullare»: c'è qualcosa da annullare, ed è fuori portata
            // (00 §9, principio 9; 05 §6.5).
            partita.ambiente.segnali.annuncia(TestoLocalizzato(
                testo: testi.termine(MotivoNonValidoCampagna.oltreLaGiornataInCorso.rawValue).testo,
                lingua: testi.lingua))
        } catch {
            partita.ambiente.segnali.annuncia(TestoLocalizzato(
                testo: testi.frase("campagna.niente_da_annullare").testo, lingua: testi.lingua))
        }
    }

    @objc private func esci() { alTermine?() }

    @objc private func apriRegistro() {
        guard let costruttore else { return }
        let schermata = SchermataRegistro(
            voci: costruttore.vista.registroDalPiuRecente.map {
                SchermataRegistro.Voce(frase: costruttore.voceDiRegistro($0), luogo: $0.luogo) },
            testi: testi)
        schermata.alSalto = { [weak self] casella in
            guard let self, let elemento = self.elementi[casella] else { return }
            Fuoco.sposta(a: elemento, perche: .richiesto)
        }
        schermata.modalPresentationStyle = .fullScreen
        present(schermata, animated: false)
        Fuoco.sposta(a: nil, perche: .schermataAperta)
    }

    // MARK: - Fuoco, righe, scorrimento (00 §11.6, §10.4)

    func fuocoArrivato(su casella: Cella) {
        scorrimento.scrollRectToVisible(VistaMappa.cornice(di: casella).insetBy(dx: -40, dy: -40),
                                        animated: false)
        if let ultima = ultimaRigaDelFuoco, ultima != casella.riga {
            // Il cambio di riga si segnala come in battaglia (00 §11.6). Sulla mappa
            // non esistono ancora forze avversarie da annunciare nella riga.
            partita.ambiente.segnali.segnalaCambioRiga(conNemici: false)
        }
        ultimaRigaDelFuoco = casella.riga
    }

    /// Il tocco magico richiama l'informazione di stato senza lasciare la mappa
    /// (02 §6.4, §6.5, §6.7): stesso gesto, stesso significato dei due piani.
    override func accessibilityPerformMagicTap() -> Bool {
        guard let costruttore else { return false }
        partita.ambiente.segnali.annuncia(
            TestoLocalizzato(testo: costruttore.informazioneDiStato(), lingua: testi.lingua),
            interrompente: true)
        return true
    }

    /// Il gesto di fuga annulla la designazione in corso; senza designazione risale
    /// di un livello (02 §6.7).
    override func accessibilityPerformEscape() -> Bool {
        if case .marcia = designazione {
            designazione = .nessuna
            if let stato = statoCorrente { aggiorna(con: stato) }
            partita.ambiente.segnali.annuncia(TestoLocalizzato(
                testo: testi.frase("pannello.designazione_annullata").testo, lingua: testi.lingua))
            return true
        }
        alTermine?()
        return true
    }

    // MARK: - Azioni personalizzate: due sole, nord e sud (02 §2.5)

    private func azioniDirezione(da casella: Cella) -> [UIAccessibilityCustomAction] {
        guard let stato = statoCorrente else { return [] }
        let destinazioni: [(String, Cella)] = [
            ("direzione.nord", Cella(riga: casella.riga - 1, colonna: casella.colonna)),
            ("direzione.sud", Cella(riga: casella.riga + 1, colonna: casella.colonna)),
        ]
        return destinazioni.compactMap { chiave, destinazione in
            guard stato.griglia.contiene(destinazione) else { return nil }
            return UIAccessibilityCustomAction(name: testi.frase(chiave).testo) { [weak self] _ in
                guard let self, let elemento = self.elementi[destinazione] else { return false }
                Fuoco.sposta(a: elemento, perche: .richiesto)
                return true
            }
        }
    }

    // MARK: - Rotori (00 §10.2, 02 §7.3)

    private func montaRotori() {
        func rotore(_ chiave: String, caselle: @escaping () -> [Cella]) -> UIAccessibilityCustomRotor {
            UIAccessibilityCustomRotor(name: testi.frase(chiave).testo) { [weak self] richiesta in
                guard let self else { return nil }
                let insieme = caselle().sorted()
                guard !insieme.isEmpty else { return nil }
                let corrente = (richiesta.currentItem.targetElement as? ElementoCasella)?.casella
                let successiva: Cella?
                if richiesta.searchDirection == .next {
                    successiva = insieme.first { corrente == nil || corrente! < $0 } ?? insieme.first
                } else {
                    successiva = insieme.last { corrente == nil || $0 < corrente! } ?? insieme.last
                }
                guard let destinazione = successiva,
                      let elemento = self.elementi[destinazione] else { return nil }
                return UIAccessibilityCustomRotorItemResult(targetElement: elemento, targetRange: nil)
            }
        }
        // Gli insiemi di 02 §7.3 che questa unità realizza. Gli altri dipendono da
        // regole che non esistono ancora e non si offrono a vuoto.
        view.accessibilityCustomRotors = [
            rotore("rotore.proprie_formazioni") { [weak self] in
                self?.costruttore?.vista.casellePropriFormazioni ?? [] },
            rotore("rotore.gruppi_in_attesa") { [weak self] in
                self?.costruttore?.vista.caselleGruppiInAttesa ?? [] },
            rotore("rotore.gruppi_senza_rifornimento") { [weak self] in
                self?.costruttore?.vista.caselleGruppiSenzaRifornimento ?? [] },
            // Il rotore delle formazioni avversarie NOTE (02 §7.3, incarico 18): il salto
            // diretto a ciò che il giocatore osserva del nemico. Vuoto finché non ne osserva.
            rotore("rotore.formazioni_avversarie_note") { [weak self] in
                self?.costruttore?.vista.caselleFormazioniAvversarieNote ?? [] },
            // I due rotori di 02 §7.3 realizzati da questa unità (incarico 19): le caselle da
            // cui è possibile ESPLORARE — i propri esploratori pronti — e le informazioni di
            // ricognizione SCADUTE, cioè le caselle avvistate o presunte, che converrebbe
            // riesplorare. Vuoti finché non esistono esploratori o conoscenza non corrente.
            rotore("rotore.caselle_esplorabili") { [weak self] in
                self?.costruttore?.vista.caselleEsplorabili ?? [] },
            rotore("rotore.ricognizione_scadute") { [weak self] in
                self?.costruttore?.vista.caselleRicognizioneScadute ?? [] },
        ]
    }

    // Attrezzi per le prove ospitate (05 §14.4).
    var elementiPerProva: [Cella: ElementoCasella] { elementi }
    var vociPannelloPerProva: [VocePannello] { vociPannello }
    var statoPerProva: StatoCampagna? { statoCorrente }
    var registroFuocoPerProva: [Fuoco.Movimento] { Fuoco.registro }
    func eseguiPerProva(_ comando: ComandoCampagna) async { await eseguiComando(comando) }
    func apriRegistroPerProva() { apriRegistro() }
    /// Il pulsante «Chiudi la giornata» quale il titolare lo preme (incarico 26).
    func chiudiGiornataPerProva() { chiudiGiornata() }
    var motorePerProva: MotoreCampagna { partita.motore }
    /// Il colore di riempimento che la mappa disegna per una casella, letto dallo STESSO
    /// blocco che il disegno usa (`vistaMappa.coloreCasella`): la prova d'interfaccia verifica
    /// così il segno del nemico — il riempimento arancione — sulla schermata vera, non su una
    /// derivazione parallela (incarico 23).
    func coloreCasellaPerProva(_ casella: Cella) -> UIColor? { vistaMappa.coloreCasella?(casella) }
    /// La mappa come `VistaACaselle`: le prove del tocco diretto girano con
    /// lo stesso corpo sui due piani (02 §2.11, RDA-78).
    var grigliaPerProva: VistaACaselle { vistaMappa }
    var partitaPerProva: PartitaCampagna { partita }
    /// Ricarica lo stato dalla Sessione e aggiorna la schermata: la prova d'interfaccia del
    /// passaggio alla battaglia lo usa per verificare il ritorno sulla schermata VERA (incarico 24).
    func ricaricaStatoPerProva() async { await ricaricaStato() }
    func avviaDesignazionePerProva(gruppo: IdGruppo) {
        designazione = .marcia(gruppo: gruppo)
        if let stato = statoCorrente { aggiorna(con: stato) }
    }
}

extension SchermataMappaCampagna: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { vistaMappa }
}
