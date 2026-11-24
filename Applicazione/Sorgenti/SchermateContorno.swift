import UIKit
import Dati
import Segnali

/// La schermata d'avvio: riprendi, nuovo scontro, impostazioni, apprendimento.
@MainActor
final class SchermataAvvio: UIViewController {
    private let ambiente: Ambiente
    private let colonna = UIStackView()

    init(ambiente: Ambiente) {
        self.ambiente = ambiente
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    private var testi: Testi { ambiente.testi }

    /// Il comando che ha aperto la schermata in primo piano, per chiave: alla sua chiusura il fuoco
    /// torna lì (02 §5.1, osservazione 6 dell'esplorazione dell'incarico 27). Per chiave e non per
    /// oggetto, perché tornando da uno scontro o da una campagna le voci si ricostruiscono.
    private var chiaveDiOrigine: String?
    /// Il contenitore scorrevole della colonna, per portare in vista il comando d'origine.
    private var scorrimento: UIScrollView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        colonna.axis = .vertical
        colonna.spacing = 16
        // A testo massimo o in orizzontale le voci non entrano nello schermo: la colonna scorre
        // (osservazioni 3 e 7). Quando entrano, sta al centro come prima.
        scorrimento = ColonnaScorrevole.monta(colonna, in: view, centrata: true)
        let titolo = UILabel()
        titolo.text = testi.frase("avvio.titolo").testo
        titolo.font = .preferredFont(forTextStyle: .largeTitle)
        titolo.adjustsFontForContentSizeCategory = true
        titolo.numberOfLines = 0
        titolo.accessibilityTraits = .header
        colonna.addArrangedSubview(titolo)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ricostruisciVoci()
    }

    /// Il pulsante della voce indicata, se c'è.
    private func pulsante(perChiave chiave: String) -> UIButton? {
        colonna.arrangedSubviews.compactMap { $0 as? UIButton }.first { $0.accessibilityIdentifier == chiave }
    }

    /// Chiusa una schermata aperta da qui, il fuoco torna sul comando che l'aveva aperta, dove il
    /// giocatore l'aveva lasciato (02 §5.1). Se quel comando non c'è più — «Riprendi lo scontro in
    /// corso» sparisce quando lo scontro si conclude —, il fuoco va al titolo dell'avvio.
    ///
    /// La notifica si emette a chiusura COMPIUTA, un istante dopo: emessa dentro l'attivazione del
    /// pulsante che chiude, VoiceOver la scavalcava con la propria rifocalizzazione sull'elemento
    /// sparito (esplorazione ripetuta dell'incarico 28: dopo le impostazioni restava su «Chiudi il
    /// pannello» o andava al titolo, in cinque chiusure su undici).
    private func riportaIlFuoco() {
        let chiave = chiaveDiOrigine
        chiaveDiOrigine = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + Fuoco.attesaDelSistema) { [weak self] in
            guard let self else { return }
            let origine = chiave.flatMap { self.pulsante(perChiave: $0) }
            // A testo massimo la colonna è più alta dello schermo: il comando d'origine si porta
            // in vista prima, perché VoiceOver non ripieghi sul primo elemento visibile.
            if let origine, let scorrimento = self.scorrimento {
                scorrimento.layoutIfNeeded()
                scorrimento.scrollRectToVisible(origine.convert(origine.bounds, to: scorrimento), animated: false)
            }
            Fuoco.sposta(a: origine ?? self.colonna.arrangedSubviews.first, perche: .schermataChiusa)
        }
    }

    private func ricostruisciVoci() {
        for vista in colonna.arrangedSubviews.dropFirst() { vista.removeFromSuperview() }
        // Il regno è il gioco (incarico 30): le sue voci stanno in testa. Vive in uno slot proprio,
        // e le voci di prova che seguono — lo scontro e le tre campagne — restano dov'erano.
        if PartitaRegno.esisteRegnoInCorso() {
            aggiungiPulsante("avvio.riprendi_regno", #selector(riprendiRegno))
        }
        aggiungiPulsante("avvio.nuovo_regno", #selector(nuovoRegno))
        if PartitaCorrente.esisteScontroInCorso() {
            aggiungiPulsante("avvio.riprendi", #selector(riprendi))
        }
        // La campagna vive in uno slot proprio: le sue voci si aggiungono senza
        // toccare quelle dello scontro, e la ripresa di una battaglia salvata
        // resta esattamente dov'era.
        if PartitaCampagna.esisteCampagnaInCorso() {
            aggiungiPulsante("avvio.riprendi_campagna", #selector(riprendiCampagna))
        }
        aggiungiPulsante("avvio.nuovo_scontro", #selector(nuovoScontro))
        aggiungiPulsante("avvio.nuova_campagna_piccola", #selector(nuovaCampagnaPiccola))
        aggiungiPulsante("avvio.nuova_campagna_media", #selector(nuovaCampagnaMedia))
        aggiungiPulsante("avvio.nuova_campagna_grande", #selector(nuovaCampagnaGrande))
        aggiungiPulsante("avvio.impostazioni", #selector(apriImpostazioni))
        aggiungiPulsante("avvio.apprendimento", #selector(apriApprendimento))
    }

    private func aggiungiPulsante(_ chiave: String, _ azione: Selector) {
        // Il titolo va a capo invece di essere tagliato (osservazione 8).
        let pulsante = PulsanteMultiriga.crea(titolo: testi.frase(chiave).testo, stile: .title2)
        pulsante.accessibilityIdentifier = chiave
        pulsante.addAction(UIAction { [weak self] _ in self?.chiaveDiOrigine = chiave }, for: .touchUpInside)
        pulsante.addTarget(self, action: azione, for: .touchUpInside)
        colonna.addArrangedSubview(pulsante)
    }

    @objc private func nuovoScontro() {
        Task {
            do { try await presentaBattaglia(PartitaCorrente(nuova: ambiente)) }
            catch { }
        }
    }

    @objc private func riprendi() {
        Task {
            do { try await presentaBattaglia(PartitaCorrente(riprendi: ambiente)) }
            catch let errore as SessioneBattaglia.ErroreSessione {
                // Un salvataggio incompatibile si dichiara e non si apre (00 §15.2).
                if case .salvataggioIncompatibile(let attesa, let trovata) = errore {
                    ambiente.segnali.annuncia(TestoLocalizzato(
                        testo: testi.frase("avvio.slot_incompatibile", trovata, attesa).testo,
                        lingua: testi.lingua), interrompente: true)
                }
            } catch { }
        }
    }

    private func presentaBattaglia(_ partita: PartitaCorrente) {
        let schermata = SchermataBattaglia(partita: partita)
        schermata.modalPresentationStyle = .fullScreen
        schermata.alTermine = { [weak self] in
            self?.dismiss(animated: false) { self?.riportaIlFuoco() }
        }
        present(schermata, animated: false)
        Fuoco.azzeraRegistro()
    }

    @objc private func nuovaCampagnaPiccola() { nuovaCampagna(.piccola) }
    @objc private func nuovaCampagnaMedia() { nuovaCampagna(.media) }
    @objc private func nuovaCampagnaGrande() { nuovaCampagna(.grande) }

    private func nuovaCampagna(_ taglia: PartitaCampagna.Taglia) {
        Task {
            do { try await presentaMappa(PartitaCampagna(nuova: ambiente, taglia: taglia)) }
            catch { }
        }
    }

    @objc private func riprendiCampagna() {
        Task {
            do { try await presentaMappa(PartitaCampagna(riprendi: ambiente)) }
            catch let errore as SessioneCampagna.ErroreSessione {
                // Un salvataggio incompatibile si dichiara e non si apre (00 §15.2).
                // Le due incompatibilità sono distinte: quella dei VALORI, che dice
                // quali versioni sono in gioco, e quella dello SCHEMA del giornale,
                // che nasce dal formato di salvataggio e non ha versioni da citare.
                // Tacere la seconda lascerebbe il giocatore davanti a un comando
                // che non fa nulla, che è ciò che 00 §15.2 vieta.
                switch errore {
                case .salvataggioIncompatibile(let attesa, let trovata):
                    ambiente.segnali.annuncia(TestoLocalizzato(
                        testo: testi.frase("campagna.slot_incompatibile", trovata, attesa).testo,
                        lingua: testi.lingua), interrompente: true)
                case .schemaIncompatibile:
                    ambiente.segnali.annuncia(TestoLocalizzato(
                        testo: testi.frase("campagna.slot_schema_incompatibile").testo,
                        lingua: testi.lingua), interrompente: true)
                default:
                    break
                }
            } catch { }
        }
    }

    private func presentaMappa(_ partita: PartitaCampagna) {
        let schermata = SchermataMappaCampagna(partita: partita)
        schermata.modalPresentationStyle = .fullScreen
        schermata.alTermine = { [weak self] in
            self?.dismiss(animated: false) { self?.riportaIlFuoco() }
        }
        present(schermata, animated: false)
        Fuoco.azzeraRegistro()
    }

    @objc private func nuovoRegno() {
        Task {
            do { try await presentaPatria(PartitaRegno(nuovo: ambiente)) }
            catch { }
        }
    }

    @objc private func riprendiRegno() {
        Task {
            do { try await presentaPatria(PartitaRegno(riprendi: ambiente)) }
            catch let errore as SessioneRegno.ErroreSessione {
                // Un salvataggio incompatibile si dichiara e non si apre (00 §15.2), con le due
                // incompatibilità distinte, come per la campagna.
                switch errore {
                case .salvataggioIncompatibile(let attesa, let trovata):
                    ambiente.segnali.annuncia(TestoLocalizzato(
                        testo: testi.frase("regno.slot_incompatibile", trovata, attesa).testo,
                        lingua: testi.lingua), interrompente: true)
                case .schemaIncompatibile:
                    ambiente.segnali.annuncia(TestoLocalizzato(
                        testo: testi.frase("regno.slot_schema_incompatibile").testo,
                        lingua: testi.lingua), interrompente: true)
                default:
                    break
                }
            } catch { }
        }
    }

    private func presentaPatria(_ partita: PartitaRegno) {
        let schermata = SchermataPatria(partita: partita)
        schermata.modalPresentationStyle = .fullScreen
        schermata.alTermine = { [weak self] in
            self?.dismiss(animated: false) { self?.riportaIlFuoco() }
        }
        present(schermata, animated: false)
        Fuoco.azzeraRegistro()
    }

    @objc private func apriImpostazioni() {
        let schermata = SchermataImpostazioni(ambiente: ambiente)
        schermata.alTermine = { [weak self] in self?.riportaIlFuoco() }
        present(schermata, animated: false)
    }

    @objc private func apriApprendimento() {
        let schermata = SchermataApprendimento(ambiente: ambiente)
        schermata.alTermine = { [weak self] in self?.riportaIlFuoco() }
        present(schermata, animated: false)
    }
}

// Serve l'accesso al tipo dell'errore della Sessione.
import Sessione

/// Il resoconto di fine battaglia (01 §15.3.1): voci in ordine fisso, ognuna un
/// elemento accessibile che si annuncia in una frase (02 §10.3).
@MainActor
final class SchermataResoconto: UIViewController {
    private let voci: [String]
    private let testi: Testi
    /// Le chiavi del titolo e del comando di congedo: quelle del resoconto di battaglia, oppure
    /// quelle della dichiarazione di conclusione della campagna (05 §9.3; incarico 30), che ha la
    /// stessa forma — voci in ordine fisso, una frase ciascuna — e torna in patria.
    private let chiaveTitolo: String
    private let chiaveCongedo: String
    var alTermine: (() -> Void)?

    init(voci: [String], testi: Testi, chiaveTitolo: String = "resoconto.titolo",
         chiaveCongedo: String = "resoconto.torna") {
        self.voci = voci
        self.testi = testi
        self.chiaveTitolo = chiaveTitolo
        self.chiaveCongedo = chiaveCongedo
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let colonna = UIStackView()
        colonna.axis = .vertical
        colonna.spacing = 12
        // Sette voci a testo massimo non entrano nello schermo: la colonna scorre.
        ColonnaScorrevole.monta(colonna, in: view, centrata: true)
        let titolo = UILabel()
        titolo.text = testi.frase(chiaveTitolo).testo
        titolo.font = .preferredFont(forTextStyle: .title1)
        titolo.adjustsFontForContentSizeCategory = true
        titolo.numberOfLines = 0
        titolo.accessibilityTraits = .header
        colonna.addArrangedSubview(titolo)
        for voce in voci {
            let etichetta = UILabel()
            etichetta.text = voce
            etichetta.numberOfLines = 0
            etichetta.font = .preferredFont(forTextStyle: .body)
            etichetta.adjustsFontForContentSizeCategory = true
            colonna.addArrangedSubview(etichetta)
        }
        let chiudi = PulsanteMultiriga.crea(titolo: testi.frase(chiaveCongedo).testo, stile: .title3)
        chiudi.accessibilityIdentifier = chiaveCongedo
        chiudi.addTarget(self, action: #selector(chiudiTutto), for: .touchUpInside)
        colonna.addArrangedSubview(chiudi)
    }

    @objc private func chiudiTutto() {
        dismiss(animated: false) { [alTermine] in alTermine?() }
    }

    /// Il gesto di fuga congeda il resoconto come «Torna all'inizio» (02 §6.7; incarico 29, osservazione
    /// 4 della sessione da tester): fino alla build 29 non era gestito, e il giocatore doveva cercare il
    /// pulsante.
    override func accessibilityPerformEscape() -> Bool {
        chiudiTutto()
        return true
    }

    /// Attrezzo per le prove ospitate: congeda il resoconto come il tocco del pulsante «torna»,
    /// così che la prova percorra la STESSA catena di congedo del gioco (incarico 25).
    func chiudiTuttoPerProva() { chiudiTutto() }
}

/// Le impostazioni della prima versione (02 §14, RDA-38): preferenze locali.
@MainActor
final class SchermataImpostazioni: UIViewController {
    private let ambiente: Ambiente
    /// Chiamato quando la schermata si è chiusa, per qualunque via: chi l'ha aperta vi riporta il
    /// fuoco (osservazione 6).
    var alTermine: (() -> Void)?
    init(ambiente: Ambiente) {
        self.ambiente = ambiente
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let testi = ambiente.testi
        let colonna = UIStackView()
        colonna.axis = .vertical
        colonna.spacing = 20
        // In orizzontale e a testo massimo le voci non entrano nello schermo: la colonna scorre.
        ColonnaScorrevole.monta(colonna, in: view, centrata: false)
        let titolo = UILabel()
        titolo.text = testi.frase("impostazioni.titolo").testo
        TestoDinamico.applica(titolo, stile: .title1) // segue la taglia di sistema (02 §10.4)
        titolo.accessibilityTraits = .header
        colonna.addArrangedSubview(titolo)

        // Verbosità: tre livelli (00 §9.5). Dal 2026-11-21 (incarico 29) una colonna di voci invece del
        // selettore a segmenti, che non seguiva la taglia del testo e a testo grande ne tagliava i titoli
        // (02 §10.4). L'etichetta visibile dà il nome al gruppo di voci, che lo porta per chi atterra su
        // una voce (02 §1.3): per non sentirlo due volte, l'etichetta in sé non è un elemento.
        let etichettaVerbosita = TestoDinamico.applica(UILabel(), stile: .body)
        etichettaVerbosita.text = testi.frase("impostazioni.verbosita").testo
        etichettaVerbosita.isAccessibilityElement = false
        colonna.addArrangedSubview(etichettaVerbosita)
        let verbosita = SceltaAVoci(nome: etichettaVerbosita.text ?? "",
                                    voci: Verbosita.allCases.map { testi.frase("impostazioni.verbosita." + $0.rawValue).testo },
                                    scelta: Verbosita.allCases.firstIndex(of: Impostazioni.verbosita) ?? 1)
        verbosita.alCambio = { Impostazioni.verbosita = Verbosita.allCases[$0] }
        colonna.addArrangedSubview(verbosita)

        colonna.addArrangedSubview(interruttore("impostazioni.suoni", attivo: Impostazioni.suoniAttivi,
                                                azione: #selector(cambiaSuoni(_:)), testi: testi))
        colonna.addArrangedSubview(interruttore("impostazioni.aptica", attivo: Impostazioni.apticaAttiva,
                                                azione: #selector(cambiaAptica(_:)), testi: testi))

        // Intensità tattile su tre passi (02 §14.3), con la stessa colonna di voci.
        let etichettaIntensita = TestoDinamico.applica(UILabel(), stile: .body)
        etichettaIntensita.text = testi.frase("impostazioni.intensita").testo
        etichettaIntensita.isAccessibilityElement = false
        colonna.addArrangedSubview(etichettaIntensita)
        let intensita = SceltaAVoci(nome: etichettaIntensita.text ?? "", voci: (1...3).map(String.init),
                                    scelta: Impostazioni.passoIntensita - 1)
        intensita.alCambio = { Impostazioni.passoIntensita = $0 + 1 }
        colonna.addArrangedSubview(intensita)

        let chiudi = PulsanteMultiriga.crea(titolo: testi.frase("pannello.chiudi").testo, stile: .body)
        chiudi.addTarget(self, action: #selector(chiudiSchermata), for: .touchUpInside)
        colonna.addArrangedSubview(chiudi)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed { alTermine?() }
    }

    private func interruttore(_ chiave: String, attivo: Bool, azione: Selector, testi: Testi) -> UIStackView {
        let riga = UIStackView()
        riga.axis = .horizontal
        riga.spacing = 12
        riga.alignment = .center
        let etichetta = TestoDinamico.applica(UILabel(), stile: .body) // segue la taglia (02 §10.4)
        etichetta.text = testi.frase(chiave).testo
        // Il bersaglio della leva alto almeno 44 punti (02 §8.5): le leve di iOS 27 sono alte 28.
        let leva = InterruttoreAmpio()
        riga.heightAnchor.constraint(greaterThanOrEqualToConstant: InterruttoreAmpio.altezzaMinima).isActive = true
        leva.isOn = attivo
        leva.addTarget(self, action: azione, for: .valueChanged)
        leva.accessibilityLabel = etichetta.text
        // A testo grande cede l'etichetta, che va a capo; la leva ha misura propria e, compressa, si
        // disegnerebbe oltre la sua cornice e oltre il bordo (trovato dal vivo sull'iPhone, incarico 29).
        etichetta.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        leva.setContentCompressionResistancePriority(.required, for: .horizontal)
        leva.setContentHuggingPriority(.required, for: .horizontal)
        riga.addArrangedSubview(etichetta)
        riga.addArrangedSubview(leva)
        return riga
    }

    @objc private func cambiaSuoni(_ leva: UISwitch) { Impostazioni.suoniAttivi = leva.isOn }
    @objc private func cambiaAptica(_ leva: UISwitch) { Impostazioni.apticaAttiva = leva.isOn }
    @objc private func chiudiSchermata() { dismiss(animated: false) }

    /// Il gesto di fuga chiude le impostazioni come «Chiudi il pannello», e il fuoco torna sul comando
    /// che le aveva aperte (02 §6.7; incarico 29, osservazione 4 della sessione da tester).
    override func accessibilityPerformEscape() -> Bool {
        chiudiSchermata()
        return true
    }
}

/// La schermata di apprendimento dei segnali (02 §13): ogni segnale riascoltabile,
/// con accanto il significato in forma scritta.
@MainActor
final class SchermataApprendimento: UIViewController {
    private let ambiente: Ambiente
    /// Chiamato quando la schermata si è chiusa, per qualunque via (osservazione 6).
    var alTermine: (() -> Void)?
    init(ambiente: Ambiente) {
        self.ambiente = ambiente
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let testi = ambiente.testi
        let scorrimento = UIScrollView()
        scorrimento.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scorrimento)
        let colonna = UIStackView()
        colonna.axis = .vertical
        colonna.spacing = 10
        colonna.translatesAutoresizingMaskIntoConstraints = false
        scorrimento.addSubview(colonna)
        NSLayoutConstraint.activate([
            scorrimento.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scorrimento.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scorrimento.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scorrimento.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            colonna.topAnchor.constraint(equalTo: scorrimento.topAnchor, constant: 16),
            colonna.leadingAnchor.constraint(equalTo: scorrimento.leadingAnchor, constant: 24),
            colonna.trailingAnchor.constraint(equalTo: scorrimento.trailingAnchor, constant: -24),
            colonna.bottomAnchor.constraint(equalTo: scorrimento.bottomAnchor, constant: -16),
            colonna.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -48),
        ])
        // Tutti i testi seguono la taglia di sistema (02 §10.4, incarico 29).
        let titolo = UILabel()
        titolo.text = testi.frase("apprendimento.titolo").testo
        TestoDinamico.applica(titolo, stile: .title1)
        titolo.accessibilityTraits = .header
        colonna.addArrangedSubview(titolo)
        let spiegazione = TestoDinamico.applica(UILabel(), stile: .body)
        spiegazione.text = testi.frase("apprendimento.spiegazione").testo
        colonna.addArrangedSubview(spiegazione)
        for significato in SignificatoSegnale.allCases {
            let pulsante = PulsanteMultiriga.crea(titolo: testi.frase("significato." + significato.rawValue).testo,
                                                  stile: .body, allineamento: .natural)
            pulsante.accessibilityHint = spiegazione.text
            pulsante.addAction(UIAction { [weak self] _ in
                self?.ambiente.segnali.annuncia(
                    TestoLocalizzato(testo: pulsante.currentTitle ?? "", lingua: testi.lingua),
                    significato: significato)
            }, for: .touchUpInside)
            colonna.addArrangedSubview(pulsante)
        }
        let chiudi = PulsanteMultiriga.crea(titolo: testi.frase("pannello.chiudi").testo, stile: .body)
        chiudi.addTarget(self, action: #selector(chiudiSchermata), for: .touchUpInside)
        colonna.addArrangedSubview(chiudi)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed { alTermine?() }
    }

    @objc private func chiudiSchermata() { dismiss(animated: false) }

    /// Il gesto di fuga chiude l'apprendimento come «Chiudi il pannello», e il fuoco torna sul comando
    /// che l'aveva aperto (02 §6.7; incarico 29, osservazione 4 della sessione da tester).
    override func accessibilityPerformEscape() -> Bool {
        chiudiSchermata()
        return true
    }
}
