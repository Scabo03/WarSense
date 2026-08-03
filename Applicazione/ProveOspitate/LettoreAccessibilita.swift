import UIKit

/// Ricostruisce l'ordine di lettura EFFETTIVO come lo risolve la tecnologia
/// assistiva: elenchi `accessibilityElements` dichiarati, visibilità, foglie.
///
/// Nasce dal primo collaudo su dispositivo della fase B: le prove verificavano
/// esistenza e identità degli elementi, non la loro raggiungibilità. Qui si
/// accerta ciò che si può accertare in automatico — presenza nel percorso di
/// lettura, cornice non degenere, posizione dentro lo schermo o dentro un
/// contenitore scorrevole — e il resto è dichiarato nell'elenco delle verifiche
/// possibili soltanto su dispositivo (collaudo-solo-dispositivo.md).
@MainActor
enum LettoreAccessibilita {

    /// Le foglie del percorso di lettura, nell'ordine in cui la voce le percorre.
    static func ordineDiLettura(radice: Any) -> [NSObject] {
        var esito: [NSObject] = []
        raccogli(radice as AnyObject, in: &esito)
        return esito
    }

    private static func raccogli(_ nodo: AnyObject, in esito: inout [NSObject]) {
        guard let oggetto = nodo as? NSObject else { return }
        if let vista = oggetto as? UIView {
            guard !vista.isHidden, vista.alpha > 0.01, !vista.accessibilityElementsHidden else { return }
            if eFoglia(vista) { esito.append(vista); return }
            if let dichiarati = vista.accessibilityElements {
                for elemento in dichiarati { raccogli(elemento as AnyObject, in: &esito) }
                return
            }
            for sotto in vista.subviews { raccogli(sotto, in: &esito) }
            return
        }
        if oggetto.isAccessibilityElement { esito.append(oggetto); return }
        if let dichiarati = oggetto.accessibilityElements {
            for elemento in dichiarati { raccogli(elemento as AnyObject, in: &esito) }
        }
    }

    /// Nel collaudo ospitato il runtime di accessibilità non è caricato: controlli
    /// ed etichette di sistema non dichiarano da sé la propria natura. Si applica
    /// la stessa derivazione convenzionale del runtime (un controllo è un elemento,
    /// un'etichetta con testo è un elemento); la lettura reale resta materia della
    /// prova su dispositivo, come dichiarato in collaudo-solo-dispositivo.md.
    private static func eFoglia(_ vista: UIView) -> Bool {
        if vista.isAccessibilityElement { return true }
        if vista is UIControl { return true }
        if let etichetta = vista as? UILabel { return etichetta.text?.isEmpty == false }
        return false
    }

    /// L'etichetta come la deriverebbe il runtime: dichiarata, o dal contenuto.
    static func etichetta(di elemento: NSObject) -> String {
        if let dichiarata = elemento.accessibilityLabel { return dichiarata }
        if let pulsante = elemento as? UIButton { return pulsante.currentTitle ?? "" }
        if let testo = elemento as? UILabel { return testo.text ?? "" }
        return ""
    }

    /// La cornice sullo schermo come la deriverebbe il runtime di accessibilità:
    /// dalla cornice nello spazio del contenitore per gli elementi sintetici,
    /// dalla geometria della vista per le viste.
    static func cornice(di elemento: NSObject) -> CGRect {
        if let sintetico = elemento as? UIAccessibilityElement,
           let contenitore = sintetico.accessibilityContainer as? UIView {
            let dichiarata = sintetico.accessibilityFrameInContainerSpace
            if dichiarata != .null { return contenitore.convert(dichiarata, to: nil) }
        }
        if let vista = elemento as? UIView {
            return vista.convert(vista.bounds, to: nil)
        }
        return elemento.accessibilityFrame
    }

    /// Il motivo per cui un elemento del percorso NON è agganciabile, o nulla.
    /// Un elemento è agganciabile se la sua cornice sullo schermo non è degenere
    /// e se giace dentro lo schermo, oppure dentro il contenuto di un antenato
    /// scorrevole che possa portarlo in vista.
    static func motivoNonAgganciabile(_ elemento: NSObject, schermo: CGRect) -> String? {
        let corniceElemento = cornice(di: elemento)
        guard corniceElemento.width >= 1, corniceElemento.height >= 1 else {
            return "cornice degenere \(corniceElemento)"
        }
        if schermo.contains(corniceElemento) { return nil }
        guard let scorrevole = antenatoScorrevole(di: elemento) else {
            return "fuori dallo schermo \(corniceElemento) senza contenitore scorrevole"
        }
        let contenuto = CGRect(origin: .zero, size: scorrevole.contentSize)
            .insetBy(dx: -1, dy: -1)
        // Le coordinate del contenitore scorrevole SONO quelle del contenuto:
        // l'origine dei suoi confini coincide con lo scostamento corrente.
        let nelContenuto = scorrevole.convert(corniceElemento, from: nil)
        guard contenuto.contains(nelContenuto) else {
            return "fuori dal contenuto scorrevole \(nelContenuto)"
        }
        return nil
    }

    private static func antenatoScorrevole(di elemento: NSObject) -> UIScrollView? {
        var vista: UIView?
        if let propria = elemento as? UIView {
            vista = propria
        } else if let sintetico = elemento as? UIAccessibilityElement {
            vista = sintetico.accessibilityContainer as? UIView
        }
        while let corrente = vista {
            if let scorrevole = corrente as? UIScrollView { return scorrevole }
            vista = corrente.superview
        }
        return nil
    }

    /// Vero per gli elementi che il giocatore attiva: hanno il tratto di pulsante
    /// o sono controlli veri (00 §2.3: nome, ruolo, valore e azioni).
    static func eInterattivo(_ elemento: NSObject) -> Bool {
        elemento is UIControl || elemento.accessibilityTraits.contains(.button)
    }
}
