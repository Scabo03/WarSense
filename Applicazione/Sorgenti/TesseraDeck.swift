import UIKit

/// Un elemento del deck come riquadro compatto (02 §8.1, §8.2; RDA-50, RDA-85).
/// Modello dichiarato: il deck di Clash of Clans, col numero di atomi al posto del
/// livello.
///
/// Il riquadro è alto circa la metà della tessera precedente (misurata 130 punti)
/// e largo poco meno di quanto sia alto, mai sotto la dimensione minima toccabile
/// del sistema (44 punti). Mostra, PER CHI VEDE soltanto: il SIMBOLO grafico
/// dell'archetipo al centro — forma vettoriale monocroma nel formato dei simboli
/// di sistema (`Immagini.xcassets/<archetipo>.symbolset`), che ha sostituito la
/// sigla testuale segnaposto (RDA-97) —, il nome molto in piccolo, e due
/// quadratini negli angoli inferiori con atomi e volume.
///
/// PER CHI ASCOLTA nulla cambia: il simbolo, il nome disegnato e i due quadratini
/// sono DECORAZIONE, esclusi dall'albero accessibile; l'elemento accessibile resta
/// uno solo, con la propria etichetta (nome) e il proprio valore (l'annuncio in
/// ordine fisso, invariato). Il simbolo non porta informazione da solo e non si
/// distingue per il colore: prende il colore da fuori (`tintColor`/`.label`) e la
/// riconoscibilità sta nella FORMA, non nella tinta (00 §1.4).
///
/// L'altezza è FISSA e il simbolo non scala con la tipografia dinamica: selezionare
/// non fa crescere la tessera né spinge in giù ciò che le sta sotto (il difetto già
/// corretto, S10), e la banda del deck resta compatta a ogni taglia di carattere —
/// è ciò che restituisce altezza alla griglia.
final class TesseraDeck: UIControl {
    private let vistaSimbolo = UIImageView()
    private let etichettaNome = UILabel()
    private let quadratinoAtomi = UILabel()
    private let quadratinoVolume = UILabel()

    /// Circa la metà dell'altezza precedente (130), sopra il minimo toccabile.
    static let altezzaRiquadro: CGFloat = 65
    /// Poco meno dell'altezza, sopra il minimo toccabile.
    static let larghezzaRiquadro: CGFloat = 56
    /// Lato del riquadro entro cui il simbolo si iscrive, fisso: se un simbolo non
    /// entra, si rimpicciolisce il simbolo (`scaleAspectFit`), non si allarga la
    /// tessera. Sta fra il nome (in alto) e i due quadratini (in basso).
    static let latoSimbolo: CGFloat = 32

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 8
        layer.borderWidth = 2
        backgroundColor = .secondarySystemBackground

        // Il simbolo è una forma monocroma che prende il colore da fuori: sempre in
        // modalità template, mai colori scritti dentro (00 §1.4).
        vistaSimbolo.contentMode = .scaleAspectFit
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
        for decorazione in [vistaSimbolo, etichettaNome, quadratinoAtomi, quadratinoVolume] as [UIView] {
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
            vistaSimbolo.centerXAnchor.constraint(equalTo: centerXAnchor),
            vistaSimbolo.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1),
            vistaSimbolo.widthAnchor.constraint(equalToConstant: Self.latoSimbolo),
            vistaSimbolo.heightAnchor.constraint(equalToConstant: Self.latoSimbolo),
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
    /// annuncia —, non sull'uguaglianza letterale col vecchio testo composto. Il
    /// simbolo non è testo: `simboloDisegnatoPerProva` è nil quando manca l'immagine.
    var simboloDisegnatoPerProva: UIImage? { vistaSimbolo.image }
    var atomiDisegnatiPerProva: String? { quadratinoAtomi.text }
    var volumeDisegnatoPerProva: String? { quadratinoVolume.text }

    /// Aggiornamento sul posto (RDA-03). Etichetta e valore (l'annuncio) NON cambiano
    /// rispetto alla forma precedente; simbolo, nome disegnato, atomi e volume sono le
    /// decorazioni visive e non si annunciano.
    func aggiorna(nome: String, valore: String, simbolo: UIImage?, atomi: String, volume: String,
                  selezionata: Bool, attiva: Bool) {
        vistaSimbolo.image = simbolo?.withRenderingMode(.alwaysTemplate)
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
        vistaSimbolo.tintColor = isSelected ? tintColor : .label
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
