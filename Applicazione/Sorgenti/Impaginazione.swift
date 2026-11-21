import UIKit

// Gli attrezzi d'impaginazione nati dalle osservazioni dell'esplorazione con VoiceOver
// dell'incarico 27 (incarico 28): schermate che a testo massimo o in orizzontale non entravano
// nello schermo e non scorrevano, comandi irraggiungibili, titoli tagliati, bersagli sotto la
// dimensione minima. Valgono per le schermate di contorno e per le colonne dei comandi.

/// Un pulsante il cui titolo va A CAPO invece di essere tagliato, e la cui altezza segue il testo
/// (osservazioni 3 e 8): il titolo usa il carattere dello stile indicato e ne segue la taglia
/// (`adjustsFontForContentSizeCategory`), e l'altezza intrinseca è quella delle righe del titolo,
/// mai sotto il minimo di 48 punti dei comandi (02 §8.5). Il pulsante di sistema non ricalcola da
/// sé l'altezza di un titolo su più righe: per questo la si dichiara qui.
final class PulsanteMultiriga: UIButton {

    static func crea(titolo: String, stile: UIFont.TextStyle,
                     allineamento: NSTextAlignment = .center) -> PulsanteMultiriga {
        let pulsante = PulsanteMultiriga(type: .system)
        pulsante.setTitle(titolo, for: .normal)
        pulsante.titleLabel?.font = .preferredFont(forTextStyle: stile)
        pulsante.titleLabel?.adjustsFontForContentSizeCategory = true
        pulsante.titleLabel?.numberOfLines = 0
        pulsante.titleLabel?.lineBreakMode = .byWordWrapping
        pulsante.titleLabel?.textAlignment = allineamento
        pulsante.contentHorizontalAlignment = allineamento == .center ? .center : .leading
        return pulsante
    }

    /// Il margine verticale attorno al titolo.
    private static let margine: CGFloat = 8
    static let altezzaMinima: CGFloat = 48

    override var intrinsicContentSize: CGSize {
        guard let etichetta = titleLabel else { return super.intrinsicContentSize }
        let larghezza = etichetta.preferredMaxLayoutWidth > 0
            ? etichetta.preferredMaxLayoutWidth : CGFloat.greatestFiniteMagnitude
        let misura = etichetta.sizeThatFits(CGSize(width: larghezza, height: .greatestFiniteMagnitude))
        return CGSize(width: misura.width + 2 * Self.margine,
                      height: max(Self.altezzaMinima, ceil(misura.height) + 2 * Self.margine))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let etichetta = titleLabel else { return }
        let disponibile = max(0, bounds.width - 2 * Self.margine)
        if abs(etichetta.preferredMaxLayoutWidth - disponibile) > 0.5 {
            etichetta.preferredMaxLayoutWidth = disponibile
            invalidateIntrinsicContentSize()
        }
    }

    override func traitCollectionDidChange(_ precedente: UITraitCollection?) {
        super.traitCollectionDidChange(precedente)
        if precedente?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            invalidateIntrinsicContentSize()
        }
    }
}

/// Una leva di sistema con il bersaglio alto almeno 44 punti (02 §8.5): la leva disegnata resta la
/// stessa, ma il tocco e la cornice d'accessibilità — quella che l'esplorazione al tatto trova —
/// si allargano in verticale fino al minimo. Le leve di iOS 27 sono alte 28 punti.
final class InterruttoreAmpio: UISwitch {
    static let altezzaMinima: CGFloat = 44

    private var bersaglio: CGRect {
        let mancante = max(0, Self.altezzaMinima - bounds.height)
        return bounds.insetBy(dx: 0, dy: -mancante / 2)
    }

    override func point(inside punto: CGPoint, with evento: UIEvent?) -> Bool {
        bersaglio.contains(punto)
    }

    override var accessibilityFrame: CGRect {
        get { UIAccessibility.convertToScreenCoordinates(bersaglio, in: self) }
        set { super.accessibilityFrame = newValue }
    }
}

/// La colonna di una schermata di contorno dentro un contenitore che SCORRE quando il contenuto non
/// entra (osservazioni 3, 5 e 7): a testo massimo o in orizzontale l'avvio e le schermate di
/// contorno uscivano dallo schermo senza poter scorrere. Il contenitore scorrevole sta sul percorso
/// d'accessibilità degli elementi — la colonna è sua figlia, senza ordini dichiarati altrove —,
/// sicché VoiceOver vi porta in vista l'elemento a fuoco. Quando il contenuto entra, la colonna sta
/// in alto oppure al centro, come prima.
@MainActor
enum ColonnaScorrevole {
    @discardableResult
    static func monta(_ colonna: UIStackView, in vista: UIView, centrata: Bool,
                      margine: CGFloat = 24) -> UIScrollView {
        let scorrimento = UIScrollView()
        scorrimento.translatesAutoresizingMaskIntoConstraints = false
        colonna.translatesAutoresizingMaskIntoConstraints = false
        vista.addSubview(scorrimento)
        scorrimento.addSubview(colonna)
        let guida = vista.safeAreaLayoutGuide
        let contenuto = scorrimento.contentLayoutGuide
        let cornice = scorrimento.frameLayoutGuide
        // Il contenuto è alto almeno quanto la cornice (per poter centrare), e non più del
        // necessario quando la colonna è più alta (bassa priorità: cede alla colonna).
        let altezzaComeLaCornice = contenuto.heightAnchor.constraint(equalTo: cornice.heightAnchor)
        altezzaComeLaCornice.priority = .defaultLow
        var vincoli: [NSLayoutConstraint] = [
            scorrimento.topAnchor.constraint(equalTo: guida.topAnchor),
            scorrimento.bottomAnchor.constraint(equalTo: guida.bottomAnchor),
            scorrimento.leadingAnchor.constraint(equalTo: guida.leadingAnchor),
            scorrimento.trailingAnchor.constraint(equalTo: guida.trailingAnchor),
            contenuto.widthAnchor.constraint(equalTo: cornice.widthAnchor),
            contenuto.heightAnchor.constraint(greaterThanOrEqualTo: cornice.heightAnchor),
            altezzaComeLaCornice,
            colonna.leadingAnchor.constraint(equalTo: contenuto.leadingAnchor, constant: margine),
            colonna.trailingAnchor.constraint(equalTo: contenuto.trailingAnchor, constant: -margine),
            colonna.topAnchor.constraint(greaterThanOrEqualTo: contenuto.topAnchor, constant: 16),
            colonna.bottomAnchor.constraint(lessThanOrEqualTo: contenuto.bottomAnchor, constant: -16),
        ]
        if centrata {
            vincoli.append(colonna.centerYAnchor.constraint(equalTo: contenuto.centerYAnchor))
        } else {
            vincoli.append(colonna.topAnchor.constraint(equalTo: contenuto.topAnchor, constant: 16))
        }
        NSLayoutConstraint.activate(vincoli)
        return scorrimento
    }
}
