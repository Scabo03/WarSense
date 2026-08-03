import XCTest
import Dati
import Motore
@testable import WarSense

/// Le prove di raggiungibilità reale (00 §1.2, 02 §2.8): non basta che un elemento
/// esista con nome e ruolo; deve comparire nell'ordine di lettura effettivo, avere
/// una cornice non degenere e giacere dentro lo schermo o in un contenitore
/// scorrevole. Il primo collaudo su dispositivo ha mostrato elementi del deck
/// dichiarati ma non agganciabili: queste prove catturano quel difetto in automatico.
@MainActor
final class RaggiungibilitaTest: XCTestCase {

    /// Lo schermo piccolo di riferimento: il caso peggiore per lo spazio verticale.
    private static let schermoPiccolo = CGRect(x: 0, y: 0, width: 375, height: 667)

    private func schermataAperta(in cornice: CGRect) async throws
        -> (SchermataBattaglia, UIWindow, Ambiente) {
        let ambiente = try Ambiente()
        let partita = try await PartitaCorrente(nuova: ambiente)
        let schermata = SchermataBattaglia(partita: partita)
        let finestra = UIWindow(frame: cornice)
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        for _ in 0..<200 where schermata.elementiPerProva.isEmpty {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        try await Task.sleep(nanoseconds: 200_000_000) // primo aggiornamento compiuto
        finestra.layoutIfNeeded()
        return (schermata, finestra, ambiente)
    }

    func test_00_1_2_ogni_elemento_interattivo_e_agganciabile_sullo_schermo_piccolo() async throws {
        let (schermata, finestra, _) = try await schermataAperta(in: Self.schermoPiccolo)
        let ordine = LettoreAccessibilita.ordineDiLettura(radice: schermata.view!)

        var difetti: [String] = []
        for elemento in ordine {
            let etichetta = LettoreAccessibilita.etichetta(di: elemento)
            if etichetta.isEmpty {
                difetti.append("elemento senza etichetta: \(type(of: elemento))")
            }
            if let motivo = LettoreAccessibilita.motivoNonAgganciabile(
                elemento, schermo: finestra.bounds) {
                difetti.append("«\(etichetta)»: \(motivo)")
            }
        }
        XCTAssertTrue(difetti.isEmpty,
                      "elementi dichiarati ma non agganciabili (00 §1.2):\n"
                      + difetti.joined(separator: "\n"))

        // I comandi si attivano al tatto: mai sotto la dimensione minima (02 §8.5).
        for elemento in ordine where LettoreAccessibilita.eInterattivo(elemento) {
            // Arrotondata al punto: il risolutore dei vincoli lavora in virgola mobile.
            XCTAssertGreaterThanOrEqual(LettoreAccessibilita.cornice(di: elemento).height.rounded(), 44,
                "bersaglio sotto la dimensione minima: «\(LettoreAccessibilita.etichetta(di: elemento))»")
        }
    }

    func test_02_2_8_l_ordine_di_lettura_e_quello_dichiarato_ed_e_completo() async throws {
        let (schermata, _, ambiente) = try await schermataAperta(in: Self.schermoPiccolo)
        let ordine = LettoreAccessibilita.ordineDiLettura(radice: schermata.view!)
        let stato = try FabbricaBattaglia.crea(
            scenario: PartitaCorrente.scenarioDiProva(), valori: ambiente.valori).0
        let vociDeck = stato.deck[.giocatore]?.count ?? 0

        // Celle, intestazione del deck, elementi del deck, annullamento, azzeramento,
        // resa, fine del turno (02 §2.8, RDA-49): tutto presente, niente d'altro.
        let attesi = 100 + 1 + vociDeck + 4
        XCTAssertEqual(ordine.count, attesi, "il percorso di lettura è completo")
        guard ordine.count == attesi else { return }

        let celle = ordine.prefix(100).compactMap { $0 as? ElementoCella }
        XCTAssertEqual(celle.count, 100, "prima le celle, da ovest a est e dall'alto in basso")
        XCTAssertEqual(celle.first?.cella, Cella(riga: 1, colonna: 1))
        XCTAssertEqual(celle.last?.cella, Cella(riga: 10, colonna: 10))

        let testi = ambiente.testi
        XCTAssertEqual(LettoreAccessibilita.etichetta(di: ordine[100]),
                       testi.frase("deck.intestazione").testo,
                       "dopo le celle viene l'intestazione del deck (02 §2.9)")
        for indice in 0..<vociDeck {
            let elemento = ordine[101 + indice]
            let nome = testi.frase("unita." + stato.deck[.giocatore]![indice].archetipo).testo
            XCTAssertTrue(LettoreAccessibilita.etichetta(di: elemento)
                            .localizedCaseInsensitiveContains(nome),
                          "l'elemento \(indice) del deck dichiara la propria identità (02 §8.2)")
        }
        let codaAttesa = ["pulsante.annulla", "pulsante.azzera", "pulsante.resa", "pulsante.fine_turno"]
        for (scarto, chiave) in codaAttesa.enumerated() {
            XCTAssertEqual(LettoreAccessibilita.etichetta(di: ordine[101 + vociDeck + scarto]),
                           testi.frase(chiave).testo,
                           "i comandi globali chiudono l'ordine dichiarato (RDA-49)")
        }
    }
}
