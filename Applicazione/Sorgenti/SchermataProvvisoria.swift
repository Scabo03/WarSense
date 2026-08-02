import UIKit

/// Schermata provvisoria della catena di distribuzione: dichiara nome e versione.
/// Nessun testo vive nel codice (00 §14.1): nome e versione vengono dal pacchetto
/// applicativo. Le etichette sono elementi accessibili ordinari (00 §2.3).
final class SchermataProvvisoria: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let info = Bundle.main.infoDictionary ?? [:]
        let nome = (info["CFBundleDisplayName"] as? String)
            ?? (info["CFBundleName"] as? String) ?? ""
        let versione = (info["CFBundleShortVersionString"] as? String) ?? ""
        let build = (info["CFBundleVersion"] as? String) ?? ""

        let etichettaNome = UILabel()
        etichettaNome.text = nome
        etichettaNome.font = .preferredFont(forTextStyle: .largeTitle)
        etichettaNome.adjustsFontForContentSizeCategory = true
        etichettaNome.accessibilityTraits = .header

        let etichettaVersione = UILabel()
        etichettaVersione.text = versione + " (" + build + ")"
        etichettaVersione.font = .preferredFont(forTextStyle: .body)
        etichettaVersione.adjustsFontForContentSizeCategory = true

        let colonna = UIStackView(arrangedSubviews: [etichettaNome, etichettaVersione])
        colonna.axis = .vertical
        colonna.spacing = 12
        colonna.alignment = .center
        colonna.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colonna)
        NSLayoutConstraint.activate([
            colonna.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            colonna.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
