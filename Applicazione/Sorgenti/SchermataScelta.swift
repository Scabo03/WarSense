import UIKit
import Dati

/// Una SCELTA fra più voci come schermata propria (00 §8.2: si seleziona da una lista e si
/// conferma; incarico 31). Serve dove ciascuna scelta porta una frase lunga — il reparto, il costo
/// sulla riserva, l'impedimento (02 §8.7) — che un pannello di sistema taglierebbe alle dimensioni
/// grandi del testo: qui ogni voce è un comando che va a capo e segue la dimensione di sistema
/// (02 §10.4).
///
/// Il linguaggio è quello delle altre schermate (00 §7): una colonna che scorre, letta nell'ordine
/// in cui è disposta — il titolo, la domanda, le voci, il congedo —, e il gesto di fuga per uscire
/// senza scegliere.
@MainActor
final class SchermataScelta: UIViewController {

    private let titoloTesto: String
    private let domanda: String
    private let voci: [String]
    private let congedo: String
    /// Chiamata, a schermata chiusa, con l'indice della voce scelta.
    var allaScelta: ((Int) -> Void)?
    /// Chiamata, a schermata chiusa, se il giocatore esce senza scegliere.
    var alCongedo: (() -> Void)?

    /// I comandi delle voci, nell'ordine dell'elenco: attrezzo per le prove (05 §14.4).
    private(set) var pulsantiVoci: [PulsanteMultiriga] = []
    private let titolo = UILabel()

    init(titolo: String, domanda: String, voci: [String], congedo: String) {
        self.titoloTesto = titolo
        self.domanda = domanda
        self.voci = voci
        self.congedo = congedo
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let colonna = UIStackView()
        colonna.axis = .vertical
        colonna.spacing = 12
        ColonnaScorrevole.monta(colonna, in: view, centrata: false)
        titolo.text = titoloTesto
        TestoDinamico.applica(titolo, stile: .title1)
        titolo.accessibilityTraits = .header
        colonna.addArrangedSubview(titolo)
        let etichettaDomanda = TestoDinamico.applica(UILabel(), stile: .title3)
        etichettaDomanda.text = domanda
        colonna.addArrangedSubview(etichettaDomanda)
        for (indice, voce) in voci.enumerated() {
            let pulsante = PulsanteMultiriga.crea(titolo: voce, stile: .body, allineamento: .natural)
            pulsante.accessibilityLabel = voce
            pulsante.accessibilityIdentifier = "scelta." + String(indice)
            pulsante.addAction(UIAction { [weak self] _ in self?.scegli(indice) }, for: .touchUpInside)
            pulsantiVoci.append(pulsante)
            colonna.addArrangedSubview(pulsante)
        }
        let chiudi = PulsanteMultiriga.crea(titolo: congedo, stile: .body)
        chiudi.accessibilityIdentifier = "scelta.chiudi"
        chiudi.addTarget(self, action: #selector(esci), for: .touchUpInside)
        colonna.addArrangedSubview(chiudi)
    }

    private func scegli(_ indice: Int) {
        dismiss(animated: false) { [allaScelta] in allaScelta?(indice) }
    }

    @objc private func esci() {
        dismiss(animated: false) { [alCongedo] in alCongedo?() }
    }

    /// Il gesto di fuga risale di un livello senza scegliere (02 §6.7).
    override func accessibilityPerformEscape() -> Bool {
        esci()
        return true
    }

    /// Attrezzo per le prove ospitate: sceglie una voce come farebbe il comando.
    func scegliPerProva(_ indice: Int) { scegli(indice) }
}
