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
    /// L'etichetta invisibile che RISERVA l'altezza dello stato più lungo.
    ///
    /// Il difetto che chiude: selezionando una tessera il suo valore guadagna il
    /// termine «selezionato» (02 §8.2), la riga va a capo e la tessera cresceva di
    /// diciotto punti. La colonna del deck cresceva con essa e la griglia, che le
    /// cede spazio (RDA-50, scostamento S3), perdeva altrettanto dalla propria
    /// porzione visibile — proprio fra il selezionare e il piazzare, e proprio sul
    /// bordo inferiore, dove sta la zona di schieramento (01 §8.2.1). Le celle di
    /// quella zona uscivano di vista mentre la cornice che l'accessibilità riporta
    /// restava quella di prima, perché è la posizione nel CONTENUTO: chi toccava
    /// dove la cella era annunciata non toccava la cella.
    ///
    /// La riserva non taglia nulla di ciò che si vede: il testo disegnato continua
    /// a dire quanto la voce annuncia (00 §1.2), e l'altezza è quella che servirà,
    /// non una costante — si adatta quindi alle taglie d'accessibilità.
    private let etichettaDiRiserva = UILabel()

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
        etichettaDiRiserva.font = etichettaDettaglio.font
        etichettaDiRiserva.adjustsFontForContentSizeCategory = true
        etichettaDiRiserva.numberOfLines = 0
        etichettaDiRiserva.alpha = 0
        etichettaDiRiserva.isAccessibilityElement = false
        // I due testi occupano lo stesso posto: il riquadro prende l'altezza del
        // più alto, che è sempre quello di riserva.
        let riquadroDettaglio = UIView()
        riquadroDettaglio.isUserInteractionEnabled = false
        for etichetta in [etichettaDiRiserva, etichettaDettaglio] {
            etichetta.translatesAutoresizingMaskIntoConstraints = false
            riquadroDettaglio.addSubview(etichetta)
            NSLayoutConstraint.activate([
                etichetta.topAnchor.constraint(equalTo: riquadroDettaglio.topAnchor),
                etichetta.leadingAnchor.constraint(equalTo: riquadroDettaglio.leadingAnchor),
                etichetta.trailingAnchor.constraint(equalTo: riquadroDettaglio.trailingAnchor),
                etichetta.bottomAnchor.constraint(lessThanOrEqualTo: riquadroDettaglio.bottomAnchor),
            ])
        }
        etichettaDiRiserva.bottomAnchor
            .constraint(equalTo: riquadroDettaglio.bottomAnchor).isActive = true

        let colonna = UIStackView(arrangedSubviews: [etichettaNome, riquadroDettaglio])
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

    /// Il testo che la tessera DISEGNA, per il collaudo: deve dire quanto la voce
    /// annuncia (00 §1.2), e nessuna correzione di disposizione può tagliarlo.
    var dettaglioDisegnatoPerProva: String? { etichettaDettaglio.text }

    /// Aggiornamento sul posto (RDA-03): l'oggetto resta, cambiano le proprietà.
    /// - Parameter valoreDiRiserva: il valore come sarebbe nello stato più lungo,
    ///   cioè quello selezionato. Non si disegna e non si annuncia: serve soltanto
    ///   a riservare l'altezza, così che selezionare non muova la disposizione.
    func aggiorna(nome: String, valore: String, valoreDiRiserva: String,
                  selezionata: Bool, attiva: Bool) {
        etichettaNome.text = nome
        etichettaDettaglio.text = valore
        etichettaDiRiserva.text = valoreDiRiserva
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
