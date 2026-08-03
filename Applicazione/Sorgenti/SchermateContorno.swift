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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        colonna.axis = .vertical
        colonna.spacing = 16
        colonna.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colonna)
        NSLayoutConstraint.activate([
            colonna.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            colonna.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            colonna.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
        let titolo = UILabel()
        titolo.text = testi.frase("avvio.titolo").testo
        titolo.font = .preferredFont(forTextStyle: .largeTitle)
        titolo.adjustsFontForContentSizeCategory = true
        titolo.accessibilityTraits = .header
        colonna.addArrangedSubview(titolo)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ricostruisciVoci()
    }

    private func ricostruisciVoci() {
        for vista in colonna.arrangedSubviews.dropFirst() { vista.removeFromSuperview() }
        if PartitaCorrente.esisteScontroInCorso() {
            aggiungiPulsante("avvio.riprendi", #selector(riprendi))
        }
        aggiungiPulsante("avvio.nuovo_scontro", #selector(nuovoScontro))
        aggiungiPulsante("avvio.impostazioni", #selector(apriImpostazioni))
        aggiungiPulsante("avvio.apprendimento", #selector(apriApprendimento))
    }

    private func aggiungiPulsante(_ chiave: String, _ azione: Selector) {
        let pulsante = UIButton(type: .system)
        pulsante.setTitle(testi.frase(chiave).testo, for: .normal)
        pulsante.titleLabel?.font = .preferredFont(forTextStyle: .title2)
        pulsante.titleLabel?.adjustsFontForContentSizeCategory = true
        pulsante.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
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
            self?.dismiss(animated: false)
            Fuoco.sposta(a: nil, perche: .schermataAperta)
        }
        present(schermata, animated: false)
        Fuoco.azzeraRegistro()
    }

    @objc private func apriImpostazioni() {
        present(SchermataImpostazioni(ambiente: ambiente), animated: false)
    }

    @objc private func apriApprendimento() {
        present(SchermataApprendimento(ambiente: ambiente), animated: false)
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
    var alTermine: (() -> Void)?

    init(voci: [String], testi: Testi) {
        self.voci = voci
        self.testi = testi
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let colonna = UIStackView()
        colonna.axis = .vertical
        colonna.spacing = 12
        colonna.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colonna)
        NSLayoutConstraint.activate([
            colonna.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            colonna.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            colonna.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
        let titolo = UILabel()
        titolo.text = testi.frase("resoconto.titolo").testo
        titolo.font = .preferredFont(forTextStyle: .title1)
        titolo.adjustsFontForContentSizeCategory = true
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
        let chiudi = UIButton(type: .system)
        chiudi.setTitle(testi.frase("resoconto.torna").testo, for: .normal)
        chiudi.titleLabel?.font = .preferredFont(forTextStyle: .title3)
        chiudi.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        chiudi.addTarget(self, action: #selector(chiudiTutto), for: .touchUpInside)
        colonna.addArrangedSubview(chiudi)
    }

    @objc private func chiudiTutto() {
        dismiss(animated: false) { [alTermine] in alTermine?() }
    }
}

/// Le impostazioni della prima versione (02 §14, RDA-38): preferenze locali.
@MainActor
final class SchermataImpostazioni: UIViewController {
    private let ambiente: Ambiente
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
        colonna.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colonna)
        NSLayoutConstraint.activate([
            colonna.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            colonna.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            colonna.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
        let titolo = UILabel()
        titolo.text = testi.frase("impostazioni.titolo").testo
        titolo.font = .preferredFont(forTextStyle: .title1)
        titolo.accessibilityTraits = .header
        colonna.addArrangedSubview(titolo)

        // Verbosità: tre livelli (00 §9.5).
        let etichettaVerbosita = UILabel()
        etichettaVerbosita.text = testi.frase("impostazioni.verbosita").testo
        colonna.addArrangedSubview(etichettaVerbosita)
        let selettore = UISegmentedControl(items: Verbosita.allCases.map {
            testi.frase("impostazioni.verbosita." + $0.rawValue).testo })
        selettore.selectedSegmentIndex = Verbosita.allCases.firstIndex(of: Impostazioni.verbosita) ?? 1
        selettore.addTarget(self, action: #selector(cambiaVerbosita(_:)), for: .valueChanged)
        selettore.accessibilityLabel = etichettaVerbosita.text
        colonna.addArrangedSubview(selettore)

        colonna.addArrangedSubview(interruttore("impostazioni.suoni", attivo: Impostazioni.suoniAttivi,
                                                azione: #selector(cambiaSuoni(_:)), testi: testi))
        colonna.addArrangedSubview(interruttore("impostazioni.aptica", attivo: Impostazioni.apticaAttiva,
                                                azione: #selector(cambiaAptica(_:)), testi: testi))

        // Intensità tattile su tre passi (02 §14.3).
        let etichettaIntensita = UILabel()
        etichettaIntensita.text = testi.frase("impostazioni.intensita").testo
        colonna.addArrangedSubview(etichettaIntensita)
        let passi = UISegmentedControl(items: (1...3).map(String.init))
        passi.selectedSegmentIndex = Impostazioni.passoIntensita - 1
        passi.addTarget(self, action: #selector(cambiaIntensita(_:)), for: .valueChanged)
        passi.accessibilityLabel = etichettaIntensita.text
        colonna.addArrangedSubview(passi)

        let chiudi = UIButton(type: .system)
        chiudi.setTitle(testi.frase("pannello.chiudi").testo, for: .normal)
        chiudi.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        chiudi.addTarget(self, action: #selector(chiudiSchermata), for: .touchUpInside)
        colonna.addArrangedSubview(chiudi)
    }

    private func interruttore(_ chiave: String, attivo: Bool, azione: Selector, testi: Testi) -> UIStackView {
        let riga = UIStackView()
        riga.axis = .horizontal
        riga.spacing = 12
        let etichetta = UILabel()
        etichetta.text = testi.frase(chiave).testo
        let leva = UISwitch()
        leva.isOn = attivo
        leva.addTarget(self, action: azione, for: .valueChanged)
        leva.accessibilityLabel = etichetta.text
        riga.addArrangedSubview(etichetta)
        riga.addArrangedSubview(leva)
        return riga
    }

    @objc private func cambiaVerbosita(_ selettore: UISegmentedControl) {
        Impostazioni.verbosita = Verbosita.allCases[selettore.selectedSegmentIndex]
    }
    @objc private func cambiaSuoni(_ leva: UISwitch) { Impostazioni.suoniAttivi = leva.isOn }
    @objc private func cambiaAptica(_ leva: UISwitch) { Impostazioni.apticaAttiva = leva.isOn }
    @objc private func cambiaIntensita(_ selettore: UISegmentedControl) {
        Impostazioni.passoIntensita = selettore.selectedSegmentIndex + 1
    }
    @objc private func chiudiSchermata() { dismiss(animated: false) }
}

/// La schermata di apprendimento dei segnali (02 §13): ogni segnale riascoltabile,
/// con accanto il significato in forma scritta.
@MainActor
final class SchermataApprendimento: UIViewController {
    private let ambiente: Ambiente
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
        let titolo = UILabel()
        titolo.text = testi.frase("apprendimento.titolo").testo
        titolo.font = .preferredFont(forTextStyle: .title1)
        titolo.accessibilityTraits = .header
        colonna.addArrangedSubview(titolo)
        let spiegazione = UILabel()
        spiegazione.text = testi.frase("apprendimento.spiegazione").testo
        spiegazione.numberOfLines = 0
        colonna.addArrangedSubview(spiegazione)
        for significato in SignificatoSegnale.allCases {
            let pulsante = UIButton(type: .system)
            pulsante.setTitle(testi.frase("significato." + significato.rawValue).testo, for: .normal)
            pulsante.contentHorizontalAlignment = .leading
            pulsante.titleLabel?.numberOfLines = 0
            pulsante.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            pulsante.accessibilityHint = spiegazione.text
            pulsante.addAction(UIAction { [weak self] _ in
                self?.ambiente.segnali.annuncia(
                    TestoLocalizzato(testo: pulsante.currentTitle ?? "", lingua: testi.lingua),
                    significato: significato)
            }, for: .touchUpInside)
            colonna.addArrangedSubview(pulsante)
        }
        let chiudi = UIButton(type: .system)
        chiudi.setTitle(testi.frase("pannello.chiudi").testo, for: .normal)
        chiudi.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        chiudi.addTarget(self, action: #selector(chiudiSchermata), for: .touchUpInside)
        colonna.addArrangedSubview(chiudi)
    }

    @objc private func chiudiSchermata() { dismiss(animated: false) }
}
