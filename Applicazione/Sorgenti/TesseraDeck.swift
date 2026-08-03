import UIKit

/// Un elemento del deck come riquadro a sé stante (02 §8.1, §8.2): dichiara chi è,
/// quanti esemplari restano e che cosa costa. Si distingue dai comandi globali
/// tanto alla vista (riquadro di un insieme di forze, non pulsante di sistema)
/// quanto all'ascolto (nome, poi valore in ordine fisso; l'indicazione d'uso sta
/// nel suggerimento). L'attivazione seleziona, secondo lo schema
/// seleziona-naviga-conferma (00 §8.2).
final class TesseraDeck: UIControl {
    private let etichettaNome = UILabel()
    private let etichettaDettaglio = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 10
        layer.borderWidth = 2
        backgroundColor = .secondarySystemBackground
        etichettaNome.font = .preferredFont(forTextStyle: .headline)
        etichettaNome.adjustsFontForContentSizeCategory = true
        etichettaNome.numberOfLines = 0
        etichettaDettaglio.font = .preferredFont(forTextStyle: .footnote)
        etichettaDettaglio.adjustsFontForContentSizeCategory = true
        etichettaDettaglio.textColor = .secondaryLabel
        etichettaDettaglio.numberOfLines = 0
        let colonna = UIStackView(arrangedSubviews: [etichettaNome, etichettaDettaglio])
        colonna.axis = .vertical
        colonna.spacing = 2
        colonna.isUserInteractionEnabled = false
        colonna.translatesAutoresizingMaskIntoConstraints = false
        addSubview(colonna)
        NSLayoutConstraint.activate([
            colonna.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            colonna.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            colonna.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            colonna.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 104),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
        isAccessibilityElement = true
        aggiornaAspetto()
    }
    required init?(coder: NSCoder) { nil }

    /// Aggiornamento sul posto (RDA-03): l'oggetto resta, cambiano le proprietà.
    func aggiorna(nome: String, valore: String, selezionata: Bool, attiva: Bool) {
        etichettaNome.text = nome
        etichettaDettaglio.text = valore
        accessibilityLabel = nome
        accessibilityValue = valore
        isSelected = selezionata
        isEnabled = attiva
        var tratti: UIAccessibilityTraits = []
        if selezionata { tratti.insert(.selected) }
        if !attiva { tratti.insert(.notEnabled) }
        accessibilityTraits = tratti
        aggiornaAspetto()
    }

    private func aggiornaAspetto() {
        layer.borderColor = (isSelected ? tintColor : UIColor.separator).cgColor
        alpha = isEnabled ? 1 : 0.45
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        aggiornaAspetto()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        aggiornaAspetto()
    }

    /// Il doppio tocco della voce seleziona, come il tocco diretto.
    override func accessibilityActivate() -> Bool {
        guard isEnabled else { return false }
        sendActions(for: .touchUpInside)
        return true
    }

    /// La voce che arriva su una tessera fuori vista la porta in vista da sé,
    /// come per le celle della griglia (00 §10.4); il fuoco non viene toccato.
    override func accessibilityElementDidBecomeFocused() {
        var vista = superview
        while let corrente = vista, !(corrente is UIScrollView) { vista = corrente.superview }
        guard let scorrevole = vista as? UIScrollView else { return }
        scorrevole.scrollRectToVisible(convert(bounds, to: scorrevole), animated: false)
    }
}
