import UIKit
import Motore
import Dati

/// L'elemento accessibile di una casella della mappa di campagna (00 §2.3, §2.4):
/// creato una volta per campagna e aggiornato sul posto, mai ricreato (05 §10.1,
/// RDA-03). È il gemello di `ElementoCella` della battaglia: stessa struttura,
/// perché il modello di navigazione è unico (00 §7.1).
final class ElementoCasella: UIAccessibilityElement {
    let casella: Cella
    weak var schermata: SchermataMappaCampagna?

    init(casella: Cella, contenitore: UIView, schermata: SchermataMappaCampagna) {
        self.casella = casella
        self.schermata = schermata
        super.init(accessibilityContainer: contenitore)
    }

    override func accessibilityActivate() -> Bool {
        schermata?.attiva(casella) ?? false
    }

    override func accessibilityElementDidBecomeFocused() {
        schermata?.fuocoArrivato(su: casella)
    }
}

/// La vista della mappa: disegno minimo per chi vede, contenitore degli elementi
/// accessibili per chi ascolta. I dati sottostanti sono gli stessi (02 §10.3).
/// Caselle quadrate e non sfalsate: è l'unica differenza geometrica ammessa
/// rispetto alla griglia di battaglia (00 §7.2). Il tocco diretto viene da
/// `VistaACaselle`, condivisa con la griglia di battaglia: i due piani non possono
/// divergere su questo, perché la realizzazione è una sola (02 §2.11, RDA-78).
final class VistaMappa: VistaACaselle {
    static let passo: CGFloat = 64
    static let lato: CGFloat = 60
    static let margine: CGFloat = 12

    var griglia: GrigliaCampagna?
    var coloreCasella: ((Cella) -> UIColor?)?
    /// L'iniziale del gruppo presente e i segni della casella: ciò che si sente si vede.
    var testoCasella: ((Cella) -> String?)?
    var segnoCasella: ((Cella) -> String?)?
    /// Per un gruppo in marcia lunga, la posizione dell'avanzamento fra le nove
    /// disposte a quadrato (01 §5.6.3.4): indice in 0..8, derivato dai giorni. Se
    /// nulla, l'iniziale si disegna al centro. È una rappresentazione DERIVATA: non
    /// è una grandezza autonoma e non può divergere dai giorni (il Motore la calcola).
    var avanzamentoCasella: ((Cella) -> Int?)?

    static func dimensione(per griglia: GrigliaCampagna) -> CGSize {
        CGSize(width: margine * 2 + CGFloat(griglia.colonne) * passo,
               height: margine * 2 + CGFloat(griglia.righe) * passo)
    }

    static func cornice(di casella: Cella) -> CGRect {
        CGRect(x: margine + CGFloat(casella.colonna - 1) * passo,
               y: margine + CGFloat(casella.riga - 1) * passo,
               width: lato, height: lato)
    }

    override func draw(_ rect: CGRect) {
        guard let griglia else { return }
        for casella in griglia.tutteLeCaselle {
            let cornice = Self.cornice(di: casella).insetBy(dx: 2, dy: 2)
            let percorso = UIBezierPath(roundedRect: cornice, cornerRadius: 6)
            (coloreCasella?(casella) ?? UIColor.systemGray6).setFill()
            percorso.fill()
            UIColor.systemGray3.setStroke()
            percorso.stroke()
            if let segno = segnoCasella?(casella) {
                disegna(segno, in: cornice, dimensione: 12, peso: .regular,
                        colore: .secondaryLabel, allineamento: .basso)
            }
            if let testo = testoCasella?(casella) {
                if let indice = avanzamentoCasella?(casella), (0..<9).contains(indice) {
                    // L'esercito si fa strada verso il bordo: l'iniziale si colloca in
                    // una delle nove sotto-caselle, secondo l'indice derivato dai giorni.
                    let colonna = indice % 3, riga = indice / 3
                    let terzoL = cornice.width / 3, terzoH = cornice.height / 3
                    let sotto = CGRect(x: cornice.minX + CGFloat(colonna) * terzoL,
                                       y: cornice.minY + CGFloat(riga) * terzoH,
                                       width: terzoL, height: terzoH)
                    disegna(testo, in: sotto, dimensione: 13, peso: .bold,
                            colore: .white, allineamento: .centro)
                } else {
                    disegna(testo, in: cornice, dimensione: 20, peso: .bold,
                            colore: .white, allineamento: .centro)
                }
            }
        }
    }

    private enum Allineamento { case centro, basso }

    private func disegna(_ testo: String, in cornice: CGRect, dimensione: CGFloat,
                         peso: UIFont.Weight, colore: UIColor, allineamento: Allineamento) {
        let attributi: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: dimensione, weight: peso),
            .foregroundColor: colore,
        ]
        let misura = (testo as NSString).size(withAttributes: attributi)
        let y = allineamento == .centro
            ? cornice.midY - misura.height / 2
            : cornice.maxY - misura.height - 2
        (testo as NSString).draw(at: CGPoint(x: cornice.midX - misura.width / 2, y: y),
                                 withAttributes: attributi)
    }
}
