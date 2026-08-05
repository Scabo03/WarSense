import UIKit
import Motore

/// La vista che ospita gli elementi accessibili di una griglia — di battaglia o di
/// campagna — e li rende operabili ANCHE con il dito.
///
/// ## Il difetto che chiude
///
/// Le caselle delle due griglie sono elementi accessibili sintetici
/// (`UIAccessibilityElement`) dentro una vista che non aveva alcun riconoscitore
/// di gesto. Rispondevano quindi ad `accessibilityActivate`, cioè al doppio tocco
/// della tecnologia assistiva, e a nient'altro: con VoiceOver spento nessuna delle
/// due griglie era operabile, e nessuna prova d'interfaccia poteva esercitare il
/// gioco, perché una prova d'interfaccia tocca a dito. L'osservazione stava nel
/// registro degli scostamenti come P11, con il rimedio già indicato e mai
/// realizzato, ed era condizione preesistente di ENTRAMBI i piani: correggerne uno
/// solo li avrebbe fatti divergere, che il principio 7 vieta.
///
/// ## Perché il percorso è uno solo per costruzione
///
/// Il riconoscitore non chiama una seconda realizzazione dell'attivazione: risolve
/// il punto nell'elemento accessibile che lo contiene e ne invoca
/// `accessibilityActivate()`, cioè esattamente il metodo che la tecnologia
/// assistiva invoca. Non esiste un secondo ramo da tenere allineato, e non c'è
/// disciplina da rispettare: le due porte sono la stessa porta. È la forma che
/// `TesseraDeck` usa già dalla fase B nel verso opposto — lì l'attivazione
/// assistiva chiama `sendActions(for: .touchUpInside)`, cioè la porta del dito.
///
/// ## Che cosa NON è
///
/// Non è l'esplorazione libera a tocco diretto di 02 §2.12, che resta esclusa
/// dalla prima versione: quella riceve i tocchi grezzi per ANNUNCIARE ciò che il
/// dito attraversa mentre scorre, ed è una modalità di lettura. Qui il tocco
/// ATTIVA, come su qualunque controllo del sistema. La distinzione è registrata in
/// RDA-78 perché è precisamente il punto su cui una sessione futura potrebbe
/// citare 02 §2.12 per disfare questa correzione.
///
/// Con VoiceOver in funzione il riconoscitore non entra mai in azione: il tocco
/// singolo è consumato dalla tecnologia assistiva per l'esplorazione, e il doppio
/// tocco arriva all'elemento come `accessibilityActivate`. Le due porte non si
/// sovrappongono mai, e nessuna attivazione può quindi contarsi due volte.
class VistaACaselle: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        installaIlTocco()
    }

    required init?(coder: NSCoder) { nil }

    private func installaIlTocco() {
        let tocco = UITapGestureRecognizer(target: self, action: #selector(dito(_:)))
        // Il contenitore scorrevole deve continuare a scorrere e a ingrandire
        // (00 §10.4): un tocco singolo non è mai in concorrenza con quei gesti.
        tocco.cancelsTouchesInView = false
        addGestureRecognizer(tocco)
    }

    @objc private func dito(_ riconoscitore: UITapGestureRecognizer) {
        attivaAlTocco(in: riconoscitore.location(in: self))
    }

    /// L'elemento accessibile la cui cornice contiene il punto, nello spazio di
    /// questa vista. Gli elementi sono quelli dell'ordine di lettura dichiarato
    /// (02 §2.8): il dito raggiunge esattamente ciò che la voce raggiunge, e nello
    /// stesso ordine, che è la simmetria di 02 §2.11.
    func elemento(sotto punto: CGPoint) -> UIAccessibilityElement? {
        guard let elementi = accessibilityElements as? [UIAccessibilityElement] else { return nil }
        return elementi.first { $0.accessibilityFrameInContainerSpace.contains(punto) }
    }

    /// Attiva con il dito ciò che sta sotto il punto. Restituisce se qualcosa è
    /// stato attivato: falso su una casella vuota, che non ha azioni, esattamente
    /// come per l'attivazione assistiva.
    @discardableResult
    func attivaAlTocco(in punto: CGPoint) -> Bool {
        elemento(sotto: punto)?.accessibilityActivate() ?? false
    }
}
