import UIKit

/// Un elemento del deck come riquadro compatto (02 §8.1, §8.2; modifica di RDA-50
/// per decisione del titolare, non correzione di una svista). Modello dichiarato:
/// il deck di Clash of Clans, col numero di atomi al posto del livello.
///
/// Il riquadro è alto circa la metà della tessera precedente (misurata 130 punti)
/// e largo poco meno di quanto sia alto, mai sotto la dimensione minima toccabile
/// del sistema (44 punti). Mostra, PER CHI VEDE soltanto: un simbolo dell'archetipo
/// al centro — oggi il SEGNAPOSTO TESTUALE della sigla, in attesa dei simboli
/// grafici (valori-provvisori.md) —, il nome molto in piccolo, e due quadratini
/// negli angoli inferiori con atomi e volume.
///
/// PER CHI ASCOLTA nulla cambia: la sigla, il nome disegnato e i due quadratini
/// sono DECORAZIONE, esclusi dall'albero accessibile; l'elemento accessibile resta
/// uno solo, con la propria etichetta (nome) e il proprio valore (l'annuncio in
/// ordine fisso, invariato). Chi ascolta non sente sigle né numeri due volte.
///
/// L'altezza è FISSA e i caratteri decorativi non scalano con la tipografia
/// dinamica: selezionare non fa crescere la tessera né spinge in giù ciò che le sta
/// sotto (il difetto già corretto, S10), e la banda del deck resta compatta a ogni
/// taglia di carattere — è ciò che restituisce altezza alla griglia.
final class TesseraDeck: UIControl {
    private let etichettaSigla = UILabel()
    private let etichettaNome = UILabel()
    private let quadratinoAtomi = UILabel()
    private let quadratinoVolume = UILabel()

    /// Circa la metà dell'altezza precedente (130), sopra il minimo toccabile.
    static let altezzaRiquadro: CGFloat = 65
    /// Poco meno dell'altezza, sopra il minimo toccabile.
    static let larghezzaRiquadro: CGFloat = 56

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 8
        layer.borderWidth = 2
        backgroundColor = .secondarySystemBackground

        etichettaSigla.font = .systemFont(ofSize: 24, weight: .bold)
        etichettaSigla.textAlignment = .center
        etichettaSigla.adjustsFontSizeToFitWidth = true
        etichettaSigla.minimumScaleFactor = 0.5
        etichettaNome.font = .systemFont(ofSize: 8, weight: .regular)
        etichettaNome.textAlignment = .center
        etichettaNome.textColor = .secondaryLabel
        etichettaNome.numberOfLines = 1
        etichettaNome.adjustsFontSizeToFitWidth = true
        etichettaNome.minimumScaleFactor = 0.6
        for quadratino in [quadratinoAtomi, quadratinoVolume] {
            quadratino.font = .systemFont(ofSize: 9, weight: .semibold)
            quadratino.textAlignment = .center
            quadratino.backgroundColor = .tertiarySystemBackground
            quadratino.layer.cornerRadius = 3
            quadratino.layer.masksToBounds = true
        }
        // La decorazione è ESCLUSA dall'albero accessibile: chi ascolta non la sente.
        for decorazione in [etichettaSigla, etichettaNome, quadratinoAtomi, quadratinoVolume] {
            decorazione.isAccessibilityElement = false
            decorazione.isUserInteractionEnabled = false
            decorazione.translatesAutoresizingMaskIntoConstraints = false
            addSubview(decorazione)
        }
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.larghezzaRiquadro),
            heightAnchor.constraint(equalToConstant: Self.altezzaRiquadro),
            etichettaNome.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            etichettaNome.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            etichettaNome.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
            etichettaSigla.centerXAnchor.constraint(equalTo: centerXAnchor),
            etichettaSigla.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 3),
            etichettaSigla.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 3),
            etichettaSigla.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -3),
            quadratinoAtomi.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3),
            quadratinoAtomi.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            quadratinoVolume.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -3),
            quadratinoVolume.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
        ])
        isAccessibilityElement = true
        aggiornaAspetto()
    }
    required init?(coder: NSCoder) { nil }

    /// Le decorazioni disegnate, per il collaudo: la parità sonoro/visivo (00 §1.2)
    /// si prova sull'INFORMAZIONE — gli stessi atomi e lo stesso volume che la voce
    /// annuncia —, non sull'uguaglianza letterale col vecchio testo composto.
    var siglaDisegnataPerProva: String? { etichettaSigla.text }
    var atomiDisegnatiPerProva: String? { quadratinoAtomi.text }
    var volumeDisegnatoPerProva: String? { quadratinoVolume.text }

    /// Aggiornamento sul posto (RDA-03). Etichetta e valore (l'annuncio) NON cambiano
    /// rispetto alla forma precedente; sigla, nome disegnato, atomi e volume sono le
    /// decorazioni visive nuove e non si annunciano.
    func aggiorna(nome: String, valore: String, sigla: String, atomi: String, volume: String,
                  selezionata: Bool, attiva: Bool) {
        etichettaSigla.text = sigla
        etichettaNome.text = nome
        quadratinoAtomi.text = atomi
        quadratinoVolume.text = volume
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
        etichettaSigla.textColor = isSelected ? tintColor : .label
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

    /// La voce che arriva su una tessera fuori vista la porta in vista da sé (00 §10.4).
    override func accessibilityElementDidBecomeFocused() {
        var vista = superview
        while let corrente = vista, !(corrente is UIScrollView) { vista = corrente.superview }
        guard let scorrevole = vista as? UIScrollView else { return }
        scorrevole.scrollRectToVisible(convert(bounds, to: scorrevole), animated: false)
    }
}
