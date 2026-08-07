import UIKit
import Dati
import Motore

/// La schermata di divisione di un gruppo (01 §5.6.0.2, 02 §10.3). È l'operazione
/// più complessa della mappa, e va praticata ascoltando: NESSUNA tabella a caselle.
/// Ogni riga di dati è un unico elemento accessibile che si annuncia in una frase
/// compatta — un reparto con i suoi atomi e se sia da tenere o da staccare, oppure
/// una casella dove collocare il distaccamento — e che, attivato, agisce (02 §10.3).
///
/// La sequenza: si aprono i reparti come interruttori (attivarli li sposta fra il
/// tenere e lo staccare), poi si attiva una casella di destinazione, che conferma la
/// divisione con la scelta corrente. Attivare una destinazione con una scelta
/// impossibile — nessun reparto staccato, o tutti — non divide e lo DICHIARA, perché
/// il silenzio non è distinguibile da un difetto (00 §9.1). Nessun trascinamento.
@MainActor
final class SchermataDivisione: UIViewController {

    private let gruppo: Gruppo
    private let destinazioni: [Cella]
    private let testi: Testi
    /// La divisione confermata: i reparti da staccare (per indice) e dove collocarli.
    var alConferma: (([Int], Cella) -> Void)?

    private var staccati: Set<Int> = []
    private var pulsantiReparto: [(indice: Int, pulsante: UIButton)] = []

    init(gruppo: Gruppo, destinazioni: [Cella], testi: Testi) {
        self.gruppo = gruppo
        self.destinazioni = destinazioni
        self.testi = testi
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    /// Attrezzi per le prove (05 §14.4).
    private(set) var righeReparto: [UIButton] = []
    private(set) var righeDestinazione: [UIButton] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let scorrevole = UIScrollView()
        scorrevole.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scorrevole)
        let colonna = UIStackView()
        colonna.axis = .vertical
        colonna.spacing = 10
        colonna.translatesAutoresizingMaskIntoConstraints = false
        scorrevole.addSubview(colonna)
        NSLayoutConstraint.activate([
            scorrevole.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scorrevole.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scorrevole.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scorrevole.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            colonna.topAnchor.constraint(equalTo: scorrevole.topAnchor, constant: 16),
            colonna.leadingAnchor.constraint(equalTo: scorrevole.leadingAnchor, constant: 24),
            colonna.trailingAnchor.constraint(equalTo: scorrevole.trailingAnchor, constant: -24),
            colonna.bottomAnchor.constraint(equalTo: scorrevole.bottomAnchor, constant: -16),
            colonna.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -48),
        ])

        colonna.addArrangedSubview(intestazione(
            testi.frase("divisione.titolo", nomeGruppo(gruppo)).testo, .title1, .header))
        colonna.addArrangedSubview(intestazione(
            testi.frase("divisione.scegli_reparti").testo, .headline, .header))

        // Un reparto per riga: interruttore fra tenere e staccare.
        for (indice, _) in gruppo.composizione.enumerated() {
            let pulsante = pulsanteRiga(etichettaReparto(indice))
            pulsante.accessibilityHint = testi.frase("divisione.suggerimento_reparto").testo
            pulsante.addAction(UIAction { [weak self] _ in self?.commuta(indice) }, for: .touchUpInside)
            pulsantiReparto.append((indice, pulsante))
            righeReparto.append(pulsante)
            colonna.addArrangedSubview(pulsante)
        }

        colonna.addArrangedSubview(intestazione(
            testi.frase("divisione.scegli_dove").testo, .headline, .header))

        // Una casella libera adiacente per riga: attivarla conferma la divisione.
        for cella in destinazioni {
            let pulsante = pulsanteRiga(testi.frase("divisione.colloca", cella.riga, cella.colonna).testo)
            pulsante.accessibilityHint = testi.frase("divisione.suggerimento_colloca").testo
            pulsante.addAction(UIAction { [weak self] _ in self?.conferma(cella) }, for: .touchUpInside)
            righeDestinazione.append(pulsante)
            colonna.addArrangedSubview(pulsante)
        }

        let annulla = pulsanteRiga(testi.frase("divisione.annulla").testo)
        annulla.addAction(UIAction { [weak self] _ in self?.dismiss(animated: false) }, for: .touchUpInside)
        colonna.addArrangedSubview(annulla)
    }

    // MARK: - Azioni

    private func commuta(_ indice: Int) {
        if staccati.contains(indice) { staccati.remove(indice) } else { staccati.insert(indice) }
        if let riga = pulsantiReparto.first(where: { $0.indice == indice }) {
            let etichetta = etichettaReparto(indice)
            riga.pulsante.setTitle(etichetta, for: .normal)
            riga.pulsante.accessibilityLabel = etichetta
        }
    }

    private func conferma(_ cella: Cella) {
        // Nessuna parte vuota (01 §5.6.0.2): almeno un reparto staccato e almeno uno
        // tenuto. La scelta impossibile non divide e si dichiara.
        guard !staccati.isEmpty, staccati.count < gruppo.composizione.count else {
            UIAccessibility.post(notification: .announcement,
                                 argument: testi.frase("divisione.scelta_incompleta").testo)
            return
        }
        let indici = staccati.sorted()
        dismiss(animated: false) { self.alConferma?(indici, cella) }
    }

    // MARK: - Etichette

    private func nomeGruppo(_ gruppo: Gruppo) -> String {
        testi.termine("gruppo.nome." + gruppo.nome).testo
    }

    /// La frase compatta di un reparto: gli atomi, l'archetipo, e se sia da tenere o
    /// da staccare — tutto in una riga sola (02 §10.3).
    private func etichettaReparto(_ indice: Int) -> String {
        let reparto = gruppo.composizione[indice]
        let nome = testi.frase("unita." + reparto.archetipo).testo
        let base = testi.frase("divisione.reparto", reparto.atomi, nome).testo
        let stato = staccati.contains(indice)
            ? testi.frase("divisione.da_staccare").testo
            : testi.frase("divisione.da_tenere").testo
        return [base, stato].joined(separator: ", ")
    }

    private func intestazione(_ testo: String, _ stile: UIFont.TextStyle,
                              _ tratti: UIAccessibilityTraits) -> UILabel {
        let etichetta = UILabel()
        etichetta.text = testo
        etichetta.font = .preferredFont(forTextStyle: stile)
        etichetta.adjustsFontForContentSizeCategory = true
        etichetta.numberOfLines = 0
        etichetta.accessibilityTraits = tratti
        return etichetta
    }

    private func pulsanteRiga(_ titolo: String) -> UIButton {
        let pulsante = UIButton(type: .system)
        pulsante.setTitle(titolo, for: .normal)
        pulsante.contentHorizontalAlignment = .leading
        pulsante.titleLabel?.numberOfLines = 0
        pulsante.titleLabel?.font = .preferredFont(forTextStyle: .body)
        pulsante.titleLabel?.adjustsFontForContentSizeCategory = true
        pulsante.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        pulsante.accessibilityLabel = titolo
        return pulsante
    }

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: false)
        return true
    }
}
