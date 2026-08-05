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
/// Le voci prive di luogo — gli annullamenti — non sono attivabili: non esistendo
/// una casella cui saltare, un comando che non porta da nessuna parte sarebbe
/// peggio della sua assenza (RDA-67). Lo dichiarano nel proprio suggerimento,
/// perché il silenzio non è distinguibile da un difetto (00 §9.1).
///
/// Quelle voci sono TESTO STATICO e non pulsanti disabilitati. La distinzione non
/// è di forma: un pulsante disabilitato disegna il proprio titolo con il colore
/// dello stato inattivo, che sul fondo della schermata ha un contrasto intorno a
/// 1,7 contro 1 — leggibile dalla voce e invisibile all'occhio. Era l'immagine
/// speculare delle tessere accessibili di altezza zero della fase B: là un
/// elemento visibile e non agganciabile, qui un elemento agganciabile e non
/// visibile, e in entrambi i casi la divergenza fra i due piani che 00 §1.2 vieta.
/// Non riguarda i soli ipovedenti di 02 §1.3: riguarda chiunque guardi lo schermo.
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

    /// Gli elementi delle voci, nell'ordine dell'elenco: attrezzo per le prove (05 §14.4).
    private(set) var vociVisibili: [UIView] = []

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
            // Ogni voce è UN elemento che si annuncia in una frase compiuta (02 §6.6),
            // e in entrambi i casi il testo è disegnato con il colore ordinario del
            // testo: ciò che la voce legge, l'occhio lo vede.
            if let luogo = voce.luogo {
                let pulsante = UIButton(type: .system)
                pulsante.setTitle(voce.frase, for: .normal)
                pulsante.contentHorizontalAlignment = .leading
                pulsante.titleLabel?.numberOfLines = 0
                pulsante.titleLabel?.font = .preferredFont(forTextStyle: .body)
                pulsante.titleLabel?.adjustsFontForContentSizeCategory = true
                pulsante.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
                pulsante.accessibilityLabel = voce.frase
                pulsante.accessibilityHint = testi.frase("registro.con_luogo").testo
                pulsante.addAction(UIAction { [weak self] _ in
                    self?.dismiss(animated: false) { self?.alSalto?(luogo) }
                }, for: .touchUpInside)
                vociVisibili.append(pulsante)
                colonna.addArrangedSubview(pulsante)
            } else {
                let etichetta = UILabel()
                etichetta.text = voce.frase
                etichetta.numberOfLines = 0
                etichetta.font = .preferredFont(forTextStyle: .body)
                etichetta.adjustsFontForContentSizeCategory = true
                etichetta.textColor = .label
                etichetta.isAccessibilityElement = true
                etichetta.accessibilityLabel = voce.frase
                etichetta.accessibilityTraits = [.staticText]
                etichetta.accessibilityHint = testi.frase("registro.senza_luogo").testo
                etichetta.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
                vociVisibili.append(etichetta)
                colonna.addArrangedSubview(etichetta)
            }
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
