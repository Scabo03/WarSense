import XCTest
import Dati
import Motore
@testable import WarSense

/// La disposizione non si muove sotto il dito (00 §1.2, 00 §11.1, 02 §8.2).
///
/// **Il difetto che questa prova riproduce.** Selezionando una tessera del deck il
/// suo valore guadagnava il termine «selezionato» (02 §8.2), la riga andava a capo
/// e la tessera cresceva di diciotto punti. La colonna del deck cresce con essa, e
/// poiché la griglia CEDE spazio alla colonna (RDA-50, scostamento S3) la porzione
/// visibile della griglia si accorciava di altrettanto — proprio nel passo fra il
/// selezionare e il piazzare, e proprio sul bordo inferiore, dove sta la zona di
/// schieramento del giocatore (01 §8.2.1).
///
/// Conseguenze misurate su iPhone Air: la cella di riga 8 colonna 1 ha il centro a
/// y=502; la porzione visibile finiva a y=507,7 prima della selezione e a y=489,7
/// dopo. La cella era dunque visibile prima e non più dopo, mentre la cornice che
/// l'accessibilità riporta restava (44, 472, 60, 60), perché quella cornice è la
/// posizione nel CONTENUTO e non sullo schermo. Chi tocca dove la cella è annunciata
/// non tocca la cella.
///
/// È lo stesso fenomeno della mappa di campagna — la cornice fuori vista — con una
/// causa diversa: là lo scorrimento, qui la disposizione che si muove da sola.
@MainActor
final class StabilitaDellaDisposizioneTest: XCTestCase {

    private func battagliaAperta() async throws -> (SchermataBattaglia, PartitaCorrente, UIWindow) {
        let ambiente = try Ambiente()
        let partita = try await PartitaCorrente(nuova: ambiente)
        let schermata = SchermataBattaglia(partita: partita)
        let finestra = UIWindow(frame: CGRect(x: 0, y: 0, width: 420, height: 912))
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        for _ in 0..<250 where schermata.elementiPerProva.isEmpty {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        try await Task.sleep(nanoseconds: 300_000_000)
        finestra.layoutIfNeeded()
        addTeardownBlock { @MainActor in
            schermata.presentedViewController?.dismiss(animated: false)
            finestra.isHidden = true
            finestra.rootViewController = nil
        }
        return (schermata, partita, finestra)
    }

    /// La porzione visibile della griglia non cambia quando si seleziona una
    /// tessera: selezionare è un atto che non muove nulla di ciò che si tocca.
    func test_00_1_2_selezionare_una_tessera_non_muove_la_griglia() async throws {
        let (schermata, partita, finestra) = try await battagliaAperta()
        let scorrevole = try XCTUnwrap(schermata.grigliaPerProva.superview as? UIScrollView,
                                       "la griglia vive in un contenitore scorrevole")
        let prima = scorrevole.bounds.height

        _ = try await partita.esegui(.seleziona(indiceDeck: 0))
        try await Task.sleep(nanoseconds: 300_000_000)
        finestra.layoutIfNeeded()
        let dopo = scorrevole.bounds.height

        XCTAssertEqual(dopo, prima, accuracy: 0.5,
                       "la porzione visibile della griglia è passata da \(prima) a \(dopo) "
                       + "punti per effetto della SOLA selezione di una tessera: le celle "
                       + "sul bordo inferiore — cioè la zona di schieramento — escono di "
                       + "vista proprio quando servono (00 §1.2, RDA-50)")
    }

    /// La tessera non cambia altezza quando viene selezionata: è la causa diretta.
    func test_02_8_2_la_tessera_non_cambia_altezza_quando_e_selezionata() async throws {
        let (schermata, partita, finestra) = try await battagliaAperta()
        let tessere = schermata.tesserePerProva
        XCTAssertFalse(tessere.isEmpty, "il deck espone le proprie tessere")
        let prima = tessere.map(\.frame.height)

        _ = try await partita.esegui(.seleziona(indiceDeck: 0))
        try await Task.sleep(nanoseconds: 300_000_000)
        finestra.layoutIfNeeded()
        let dopo = schermata.tesserePerProva.map(\.frame.height)

        XCTAssertEqual(dopo, prima,
                       "la selezione cambia l'altezza delle tessere: \(prima) → \(dopo). "
                       + "Il termine «selezionato» del valore (02 §8.2) manda la riga a capo "
                       + "e la disposizione si sposta sotto il dito")
    }

    /// E ciò che si vede continua a dire ciò che si sente: la correzione non deve
    /// tagliare il testo disegnato per tenere ferma l'altezza (00 §1.2).
    func test_00_1_2_il_testo_disegnato_dice_quanto_la_voce(
    ) async throws {
        let (schermata, partita, finestra) = try await battagliaAperta()
        _ = try await partita.esegui(.seleziona(indiceDeck: 0))
        try await Task.sleep(nanoseconds: 300_000_000)
        finestra.layoutIfNeeded()
        for tessera in schermata.tesserePerProva {
            XCTAssertEqual(tessera.dettaglioDisegnatoPerProva, tessera.accessibilityValue,
                           "la tessera «\(tessera.accessibilityLabel ?? "")» disegna un testo "
                           + "diverso da quello che annuncia")
        }
    }
}
