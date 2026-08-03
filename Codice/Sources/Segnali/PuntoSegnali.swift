import Foundation
import Dati
import Motore

#if canImport(UIKit)
import UIKit
import CoreHaptics
import AVFoundation

/// Il punto centrale unico dei segnali di piattaforma (00 §5.3, 05 §11): riceve gli
/// eventi in forma astratta, decide i canali e li attiva. Nessun altro modulo
/// nomina vibrazioni, suoni o annunci.
@MainActor
public final class PuntoSegnali {

    public struct Preferenze: Sendable {
        public var verbosita: Verbosita
        public var canali: PreferenzeSegnali
        /// Intensità complessiva dei segnali tattili, su tre passi (02 §14.3).
        public var passoIntensita: Int
        public init(verbosita: Verbosita, canali: PreferenzeSegnali, passoIntensita: Int) {
            self.verbosita = verbosita
            self.canali = canali
            self.passoIntensita = passoIntensita
        }
    }

    private let testi: Testi
    private let definizioni: DefinizioniSegnali
    private let cartellaSuoni: URL
    /// Fornitore delle preferenze locali (05 §10.7): mai parte dello stato di partita.
    private let preferenze: @MainActor () -> Preferenze
    private let decisore: DecisoreCanali
    private var motoreAptico: CHHapticEngine?
    private var lettori: [String: AVAudioPlayer] = [:]
    private var codaAnnunci: [NSAttributedString] = []
    private var annuncioInCorso = false

    public init(testi: Testi, definizioni: DefinizioniSegnali, cartellaSuoni: URL,
                preferenze: @escaping @MainActor () -> Preferenze) {
        self.testi = testi
        self.definizioni = definizioni
        self.cartellaSuoni = cartellaSuoni
        self.preferenze = preferenze
        self.decisore = DecisoreCanali(
            apparecchioConAptica: CHHapticEngine.capabilitiesForHardware().supportsHaptics)
        preparaMotoreAptico() // mantenuto pronto, mai acceso e spento a ogni evento (00 §5.6)
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.announcementDidFinishNotification,
            object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.annuncioConcluso() }
        }
    }

    // MARK: - Ingresso

    /// L'ingresso del punto: l'evento astratto, tradotto e smistato sui canali.
    public func segnala(evento: EventoBattaglia, per parte: Parte) {
        let traduttore = TraduttoreEventi(testi: testi, parte: parte)
        let p = preferenze()
        if let annuncio = traduttore.annuncio(per: evento, verbosita: p.verbosita) {
            accoda(annuncio, interrompente: false)
        }
        guard let significato = traduttore.significato(per: evento) else { return }
        emetti(significato: significato)
    }

    /// I fatti di pura navigazione prodotti dalla Presentazione (00 §11.6, 05 §11.2).
    public func segnalaCambioRiga(conNemici: Bool) {
        emetti(significato: conNemici ? .cambioRigaConNemici : .cambioRiga)
    }

    /// Le conferme locali (annullamento, azzeramento: 05 §6.4) e ogni altro
    /// annuncio della Presentazione passano da qui: un solo punto (00 §5.3).
    public func annuncia(_ testo: TestoLocalizzato, interrompente: Bool = false,
                         significato: SignificatoSegnale? = nil) {
        accoda(testo, interrompente: interrompente)
        if let significato { emetti(significato: significato) }
    }

    // MARK: - Canali

    private func emetti(significato: SignificatoSegnale) {
        let p = preferenze()
        let canali = decisore.canali(preferenze: p.canali,
                                     conSegnaleTattile: significato.conSegnaleTattile)
        if canali.contains(.suono) { suona(significato) }
        if canali.contains(.aptica) { vibra(significato, passoIntensita: p.passoIntensita) }
    }

    // MARK: - Coda degli annunci (05 §11.6)

    private func accoda(_ testo: TestoLocalizzato, interrompente: Bool) {
        let attribuito = NSAttributedString(string: testo.testo, attributes: [
            .accessibilitySpeechLanguage: testo.lingua, // 00 §14.4
        ])
        if interrompente {
            codaAnnunci.removeAll()
            codaAnnunci.append(attribuito)
            annuncioInCorso = false
        } else {
            codaAnnunci.append(attribuito)
        }
        pronunciaProssimo()
    }

    private func pronunciaProssimo() {
        guard !annuncioInCorso, !codaAnnunci.isEmpty else { return }
        let prossimo = codaAnnunci.removeFirst()
        annuncioInCorso = true
        UIAccessibility.post(notification: .announcement, argument: prossimo)
    }

    private func annuncioConcluso() {
        annuncioInCorso = false
        pronunciaProssimo()
    }

    // MARK: - Suoni (02 §12)

    private func suona(_ significato: SignificatoSegnale) {
        guard let nomeFile = definizioni.suoni[significato.rawValue] else { return }
        if lettori[nomeFile] == nil {
            let url = cartellaSuoni.appendingPathComponent(nomeFile + ".wav")
            lettori[nomeFile] = try? AVAudioPlayer(contentsOf: url)
            lettori[nomeFile]?.prepareToPlay()
        }
        lettori[nomeFile]?.currentTime = 0
        lettori[nomeFile]?.play()
    }

    // MARK: - Aptica (00 §5, 02 §11)

    private func preparaMotoreAptico() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        motoreAptico = try? CHHapticEngine()
        motoreAptico?.resetHandler = { [weak self] in
            Task { @MainActor in try? self?.motoreAptico?.start() }
        }
        try? motoreAptico?.start()
    }

    private func vibra(_ significato: SignificatoSegnale, passoIntensita: Int) {
        guard let motore = motoreAptico,
              let pattern = definizioni.pattern[significato.rawValue] else { return }
        // Tre passi d'intensità complessiva (02 §14.3): coefficiente in terzi.
        let coefficiente = Float(max(1, min(3, passoIntensita))) / 3.0
        let eventi = pattern.impulsi.map { impulso in
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity,
                                       value: Float(impulso.intensita.grezzo) / 1000 * coefficiente),
                CHHapticEventParameter(parameterID: .hapticSharpness,
                                       value: Float(impulso.nitidezza.grezzo) / 1000),
            ], relativeTime: TimeInterval(impulso.attesa) / 1000)
        }
        if let patternPronto = try? CHHapticPattern(events: eventi, parameters: []),
           let lettore = try? motore.makePlayer(with: patternPronto) {
            try? lettore.start(atTime: 0)
        }
    }
}
#endif
