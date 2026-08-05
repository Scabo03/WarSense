import UIKit
import Motore
import Dati

/// L'elemento accessibile di una cella (00 §2.3, §2.4): creato una volta per
/// battaglia e aggiornato sul posto, mai ricreato durante l'uso (05 §10.1, RDA-03).
final class ElementoCella: UIAccessibilityElement {
    let cella: Cella
    weak var schermata: SchermataBattaglia?

    init(cella: Cella, contenitore: UIView, schermata: SchermataBattaglia) {
        self.cella = cella
        self.schermata = schermata
        super.init(accessibilityContainer: contenitore)
    }

    override func accessibilityActivate() -> Bool {
        schermata?.attiva(cella) ?? false
    }

    override func accessibilityElementDidBecomeFocused() {
        schermata?.fuocoArrivato(su: cella)
    }
}

/// La vista della griglia: disegno minimo per chi vede, contenitore degli elementi
/// accessibili per chi ascolta. I dati sottostanti sono gli stessi (02 §10.3).
/// Da `VistaACaselle` eredita il tocco diretto: le celle si attivano al dito e alla
/// voce per la stessa porta (02 §2.11, RDA-78).
final class VistaGriglia: VistaACaselle {
    static let passoX: CGFloat = 64
    static let passoY: CGFloat = 56
    static let lato: CGFloat = 60
    static let margine: CGFloat = 12

    var griglia: Griglia?
    var coloreCella: ((Cella) -> UIColor?)?
    /// La lettera del reparto nella cella (01 §9.4.3): ciò che si sente si vede.
    var testoCella: ((Cella) -> String?)?

    static func dimensione(per griglia: Griglia) -> CGSize {
        CGSize(width: margine * 2 + CGFloat(griglia.colonne) * passoX + passoX / 2,
               height: margine * 2 + CGFloat(griglia.righe) * passoY)
    }

    static func cornice(di cella: Cella) -> CGRect {
        let sfalsata = cella.riga % 2 == 0
        let x = margine + CGFloat(cella.colonna - 1) * passoX + (sfalsata ? passoX / 2 : 0)
        let y = margine + CGFloat(cella.riga - 1) * passoY
        return CGRect(x: x, y: y, width: lato, height: lato)
    }

    override func draw(_ rect: CGRect) {
        guard let griglia else { return }
        for cella in griglia.tutteLeCelle {
            let cornice = Self.cornice(di: cella).insetBy(dx: 2, dy: 2)
            let percorso = UIBezierPath(ovalIn: cornice)
            (coloreCella?(cella) ?? UIColor.systemGray5).setFill()
            percorso.fill()
            UIColor.systemGray3.setStroke()
            percorso.stroke()
            if let testo = testoCella?(cella) {
                let attributi: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: UIColor.white,
                ]
                let misura = (testo as NSString).size(withAttributes: attributi)
                let origine = CGPoint(x: cornice.midX - misura.width / 2,
                                      y: cornice.midY - misura.height / 2)
                (testo as NSString).draw(at: origine, withAttributes: attributi)
            }
        }
    }
}
