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
        view.accessibilityElements = [vistaMappa, pulsanteRegistro, pulsanteAnnulla,
                                      pulsanteAzzera, pulsanteEsci]
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
        pulsanteAnnulla.setTitle(testi.frase("pulsante.annulla").testo, for: .normal)
        pulsanteAzzera.setTitle(testi.frase("pulsante.azzera").testo, for: .normal)
        pulsanteEsci.setTitle(testi.frase("resoconto.torna").testo, for: .normal)

        vistaMappa.coloreCasella = { [weak self] casella in
            guard let self, let costruttore = self.costruttore else { return nil }
            if case .marcia(let id) = self.designazione,
               costruttore.vista.destinazioniValide(per: id).contains(casella) {
                return .systemGreen.withAlphaComponent(0.4)
            }
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
        ]
    }

    // Attrezzi per le prove ospitate (05 §14.4).
    var elementiPerProva: [Cella: ElementoCasella] { elementi }
    var vociPannelloPerProva: [VocePannello] { vociPannello }
    var statoPerProva: StatoCampagna? { statoCorrente }
    var registroFuocoPerProva: [Fuoco.Movimento] { Fuoco.registro }
    func eseguiPerProva(_ comando: ComandoCampagna) async { await eseguiComando(comando) }
    func apriRegistroPerProva() { apriRegistro() }
    var motorePerProva: MotoreCampagna { partita.motore }
    /// La mappa come `VistaACaselle`: le prove del tocco diretto girano con
    /// lo stesso corpo sui due piani (02 §2.11, RDA-78).
    var grigliaPerProva: VistaACaselle { vistaMappa }
    var partitaPerProva: PartitaCampagna { partita }
    func avviaDesignazionePerProva(gruppo: IdGruppo) {
        designazione = .marcia(gruppo: gruppo)
        if let stato = statoCorrente { aggiorna(con: stato) }
    }
}

extension SchermataMappaCampagna: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { vistaMappa }
}
