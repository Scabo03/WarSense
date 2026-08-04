import UIKit
import Dati
import Motore

/// Il registro degli eventi della campagna (01 §5.17, 02 §6.6, 05 §10.13).
///
/// Non è una tabella né un blocco unico di testo: ogni voce è un elemento
/// accessibile a sé, che si annuncia in una frase compiuta, dichiara il giorno cui
/// si riferisce e, attivandola, porta il fuoco sul luogo del fatto. L'ordine è dal
/// più recente al meno recente, così che scorrendo si vada indietro nel tempo e ci
/// si fermi alle cose già sentite.
///
/// Le voci prive di luogo — i fatti di calendario — non sono attivabili: non
/// esistendo una casella cui saltare, un comando che non porta da nessuna parte
/// sarebbe peggio della sua assenza. Lo dichiarano nel proprio suggerimento,
/// perché il silenzio non è distinguibile da un difetto (00 §9.1).
@MainActor
final class SchermataRegistro: UIViewController {

    struct Voce {
        let frase: String
        let luogo: Cella?
    }

    private let voci: [Voce]
    private let testi: Testi
    /// Chiamata quando il giocatore attiva una voce che ha un luogo.
    var alSalto: ((Cella) -> Void)?

    init(voci: [Voce], testi: Testi) {
        self.voci = voci
        self.testi = testi
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    private var pulsantiVoce: [UIButton] = []

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

        let titolo = UILabel()
        titolo.text = testi.frase("registro.titolo").testo
        titolo.font = .preferredFont(forTextStyle: .title1)
        titolo.adjustsFontForContentSizeCategory = true
        titolo.accessibilityTraits = .header
        colonna.addArrangedSubview(titolo)

        if voci.isEmpty {
            let vuoto = UILabel()
            vuoto.text = testi.frase("registro.vuoto").testo
            vuoto.numberOfLines = 0
            vuoto.adjustsFontForContentSizeCategory = true
            colonna.addArrangedSubview(vuoto)
        }

        for voce in voci {
            let pulsante = UIButton(type: .system)
            pulsante.setTitle(voce.frase, for: .normal)
            pulsante.contentHorizontalAlignment = .leading
            pulsante.titleLabel?.numberOfLines = 0
            pulsante.titleLabel?.font = .preferredFont(forTextStyle: .body)
            pulsante.titleLabel?.adjustsFontForContentSizeCategory = true
            pulsante.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            // Ogni voce è UN elemento che si annuncia in una frase compiuta (02 §6.6).
            pulsante.accessibilityLabel = voce.frase
            if let luogo = voce.luogo {
                pulsante.addAction(UIAction { [weak self] _ in
                    self?.dismiss(animated: false) { self?.alSalto?(luogo) }
                }, for: .touchUpInside)
            } else {
                pulsante.isEnabled = false
                pulsante.accessibilityTraits = [.staticText]
                pulsante.accessibilityHint = testi.frase("registro.senza_luogo").testo
            }
            pulsantiVoce.append(pulsante)
            colonna.addArrangedSubview(pulsante)
        }

        let chiudi = UIButton(type: .system)
        chiudi.setTitle(testi.frase("registro.chiudi").testo, for: .normal)
        chiudi.titleLabel?.adjustsFontForContentSizeCategory = true
        chiudi.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        chiudi.addTarget(self, action: #selector(chiudiSchermata), for: .touchUpInside)
        colonna.addArrangedSubview(chiudi)
    }

    @objc private func chiudiSchermata() { dismiss(animated: false) }

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: false)
        return true
    }
}
