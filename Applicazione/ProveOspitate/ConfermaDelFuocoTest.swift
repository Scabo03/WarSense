import XCTest
import UIKit
import Dati
import Motore
@testable import WarSense

/// LA CONFERMA DEL FUOCO (02 §5.7, RDA-192; incarico 32). Alla comparsa e al congedo di una schermata una
/// richiesta di fuoco la manda anche il sistema, e VoiceOver applica l'ultima: quella del gioco, se arriva
/// prima, va perduta e il fuoco resta su un elemento qualunque — «Attendi l'inverno» al ritorno in patria,
/// una voce a metà della dichiarazione di conclusione. Il gioco se ne accorge dalla notifica con cui il
/// sistema dice quale elemento ha ricevuto il fuoco, e lo chiede di nuovo, una volta sola.
@MainActor
final class ConfermaDelFuocoTest: XCTestCase {

    private var ambiente: Ambiente!
    private var finestre: [UIWindow] = []

    override func setUp() async throws {
        ambiente = try Ambiente()
        Fuoco.azzeraRegistro()
    }

    override func tearDown() async throws {
        for finestra in finestre { finestra.isHidden = true; finestra.rootViewController = nil }
        finestre = []
        Fuoco.sposta(a: nil, perche: .richiesto) // nessuna richiesta in attesa di conferma per le prove che seguono
        Fuoco.azzeraRegistro()
    }

    private func monta(_ schermata: UIViewController) {
        let finestra = UIWindow(frame: CGRect(x: 0, y: 0, width: 420, height: 912))
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        finestra.layoutIfNeeded()
        finestre.append(finestra)
    }

    private func attendi(_ che: String, _ condizione: () -> Bool) async throws {
        for _ in 0..<200 {
            if condizione() { return }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTFail("tempo scaduto: \(che)")
    }

    /// La notifica con cui il sistema dice che una tecnologia assistiva ha messo a fuoco un elemento.
    private func attendiIlViaggio() async throws { try await Task.sleep(nanoseconds: 700_000_000) }

    private func metteAFuoco(_ elemento: AnyObject,
                             _ tecnologia: UIAccessibility.AssistiveTechnologyIdentifier = .notificationVoiceOver) {
        NotificationCenter.default.post(name: UIAccessibility.elementFocusedNotification, object: nil, userInfo: [
            UIAccessibility.focusedElementUserInfoKey: elemento,
            UIAccessibility.assistiveTechnologyUserInfoKey: tecnologia.rawValue])
    }

    /// Una dichiarazione con due voci, comparsa, e il fuoco chiesto sul titolo.
    private func dichiarazione() async throws -> (titolo: UILabel, voci: [UILabel]) {
        let schermata = SchermataResoconto(voci: ["Prima voce", "Seconda voce"], testi: ambiente.testi)
        monta(schermata)
        try await attendi("il fuoco si chiede sul titolo") { Fuoco.registro == [.schermataAperta] }
        let titolo = try XCTUnwrap(Fuoco.ultimoBersaglio as? UILabel)
        XCTAssertEqual(titolo.text, ambiente.testi.frase("resoconto.titolo").testo)
        func etichette(_ vista: UIView) -> [UILabel] {
            (vista as? UILabel).map { [$0] } ?? vista.subviews.flatMap(etichette)
        }
        let voci = etichette(schermata.view).filter { $0.text?.hasSuffix("voce") == true }
        XCTAssertEqual(voci.compactMap(\.text), ["Prima voce", "Seconda voce"])
        return (titolo, voci)
    }

    func test_02_5_7_il_fuoco_andato_su_una_voce_si_chiede_di_nuovo_sul_titolo_una_volta_sola() async throws {
        let (titolo, voci) = try await dichiarazione()
        metteAFuoco(titolo)
        metteAFuoco(voci[0])
        XCTAssertEqual(Fuoco.registro, [.schermataAperta], "la richiesta è ancora in viaggio")
        try await attendiIlViaggio()
        metteAFuoco(voci[1])
        XCTAssertEqual(Fuoco.registro, [.schermataAperta, .schermataAperta], "la richiesta perduta si rinnova")
        XCTAssertTrue(Fuoco.ultimoBersaglio === titolo)
        metteAFuoco(voci[0])
        metteAFuoco(voci[1])
        XCTAssertEqual(Fuoco.registro.count, 2, "una volta sola: adesso chi si muove è chi gioca (00 §11.1)")
    }

    func test_02_5_7_arrivato_il_fuoco_sul_titolo_uno_scorrimento_non_si_contrasta() async throws {
        let (titolo, voci) = try await dichiarazione()
        try await attendiIlViaggio()
        metteAFuoco(titolo)
        metteAFuoco(voci[0])
        metteAFuoco(voci[1])
        XCTAssertEqual(Fuoco.registro, [.schermataAperta])
    }

    func test_02_5_7_il_fuoco_che_passa_da_un_altra_schermata_non_conta() async throws {
        let (_, voci) = try await dichiarazione()
        // Mentre un pannello si congeda il fuoco passa per la schermata che si lascia.
        let altra = UIViewController()
        let comando = UIButton(type: .system)
        altra.view.addSubview(comando)
        monta(altra)
        try await attendiIlViaggio()
        metteAFuoco(comando)
        XCTAssertEqual(Fuoco.registro, [.schermataAperta])
        metteAFuoco(voci[0])
        XCTAssertEqual(Fuoco.registro.count, 2, "e quello che arriva sulla schermata giusta conta ancora")
    }

    func test_02_5_7_il_fuoco_di_un_altra_tecnologia_non_conta() async throws {
        let (_, voci) = try await dichiarazione()
        try await attendiIlViaggio()
        metteAFuoco(voci[0], .notificationSwitchControl)
        XCTAssertEqual(Fuoco.registro, [.schermataAperta])
    }

    func test_02_5_7_uno_spostamento_chiesto_dal_giocatore_non_si_conferma() async throws {
        let (titolo, voci) = try await dichiarazione()
        try await attendiIlViaggio()
        metteAFuoco(titolo)
        Fuoco.sposta(a: voci[1], perche: .richiesto)
        try await attendiIlViaggio()
        metteAFuoco(voci[0])
        XCTAssertEqual(Fuoco.registro, [.schermataAperta, .richiesto])
    }

    /// Una casella della mappa è un elemento senza vista propria, e la sua schermata si riconosce lo stesso.
    func test_02_5_7_anche_la_casella_di_una_mappa_sta_in_una_schermata() async throws {
        defer { try? FileManager.default.removeItem(at: PartitaCampagna.cartellaCampagna) }
        let mappa = SchermataMappaCampagna(partita: try await PartitaCampagna(nuova: ambiente, taglia: .piccola))
        monta(mappa)
        try await attendi("la mappa chiede il fuoco") { Fuoco.registro.contains(.schermataAperta) }
        let chiesto = try XCTUnwrap(Fuoco.ultimoBersaglio)
        let altra = try XCTUnwrap(mappa.elementiPerProva.values.first { $0 !== chiesto })
        XCTAssertTrue(mappa.elementiPerProva.values.contains { $0 === chiesto }, "il fuoco si chiede su una casella")
        let prima = Fuoco.registro.count
        try await attendiIlViaggio()
        metteAFuoco(altra)
        XCTAssertEqual(Fuoco.registro.count, prima + 1)
        XCTAssertTrue(Fuoco.ultimoBersaglio === chiesto)
    }
}
