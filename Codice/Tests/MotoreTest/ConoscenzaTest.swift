import XCTest
import Motore
import Dati
import Contenuti

/// Collaudo degli stati di conoscenza (incarico 17, blocco 1; 01 §5.3, §5.6.11, §12).
/// L'informazione è incompleta e il gioco non dichiara mai il falso: una casella è
/// confermata se osservata ora, inesplorata se mai vista, e la certezza decade col
/// tempo in avvistato coi turni trascorsi. Raggio di osservazione e soglia di
/// decadimento vengono dai dati (`conoscenza-campagna.json`, provvisori).
final class ConoscenzaTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    var motore: MotoreCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
    }

    static let leggera: [ScenarioCampagna.RepartoIniziale] =
        [.init(archetipo: "fanteria_leggera", atomi: 6)]

    func crea(gruppi: [(Int, Int)], mappa: String = "pianura_lunga") throws -> StatoCampagna {
        try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: mappa,
                gruppiGiocatore: gruppi.map { .init(riga: $0.0, colonna: $0.1, composizione: Self.leggera) }),
            valori: valoriCampagna, archetipiNoti: Set(valori.archetipi.keys))
    }

    func cella(_ r: Int, _ c: Int) -> Cella { Cella(riga: r, colonna: c) }
    var soglia: Int { valoriCampagna.conoscenza.sogliaConfermatoInAvvistato }

    @discardableResult
    func esegui(_ c: ComandoCampagna, _ s: inout StatoCampagna,
                file: StaticString = #filePath, linea: UInt = #line) -> [EventoCampagna] {
        let esito = motore.valida(c, parte: .giocatore, stato: s)
        XCTAssertTrue(esito.eValido, "comando non valido: \(String(describing: esito.motivo))",
                      file: file, line: linea)
        let (n, e) = motore.applica(c, parte: .giocatore, stato: s); s = n; return e
    }

    // MARK: - 01 §5.3, §12 — si conferma ciò che si osserva, e nient'altro

    func test_5_3_si_conferma_l_osservato_e_l_inesplorato_e_ignoto() throws {
        // Raggio uno (dai dati): la casella della formazione e le adiacenti ortogonali
        // sono confermate; una casella a distanza due non è mai stata vista.
        let s = try crea(gruppi: [(5, 5)])
        XCTAssertEqual(motore.conoscenza(di: cella(5, 5), per: .giocatore, stato: s), .confermato)
        XCTAssertEqual(motore.conoscenza(di: cella(4, 5), per: .giocatore, stato: s), .confermato)
        XCTAssertEqual(motore.conoscenza(di: cella(5, 6), per: .giocatore, stato: s), .confermato)
        // Il gioco non dichiara il falso: ciò che non ha visto è inesplorato, non
        // qualcosa di inventato (01 §12).
        XCTAssertEqual(motore.conoscenza(di: cella(3, 5), per: .giocatore, stato: s), .inesplorato)
        XCTAssertEqual(motore.conoscenza(di: cella(1, 1), per: .giocatore, stato: s), .inesplorato)
    }

    /// La derivazione pura dall'età dell'informazione (03 §4.8.1): sotto la soglia è
    /// confermato, alla soglia e oltre è avvistato coi turni trascorsi, assente è
    /// inesplorato. Il presunto non nasce dall'età.
    func test_5_3_derivazione_dall_eta_dell_informazione() throws {
        XCTAssertEqual(StatoConoscenza.da(eta: nil, sogliaConfermato: soglia), .inesplorato)
        XCTAssertEqual(StatoConoscenza.da(eta: 0, sogliaConfermato: soglia), .confermato)
        XCTAssertEqual(StatoConoscenza.da(eta: soglia - 1, sogliaConfermato: soglia), .confermato)
        XCTAssertEqual(StatoConoscenza.da(eta: soglia, sogliaConfermato: soglia), .avvistato(turni: soglia))
        XCTAssertEqual(StatoConoscenza.da(eta: soglia + 3, sogliaConfermato: soglia),
                       .avvistato(turni: soglia + 3))
    }

    // MARK: - 01 §5.6.11 — l'invecchiamento è un passo di fine giornata

    func test_5_6_11_il_ricordo_invecchia_a_fine_giornata_e_decade_in_avvistato() throws {
        // Un gruppo lontano da una casella ricordata: la casella non è osservata, e a
        // ogni chiusura di giornata il suo ricordo invecchia di un turno.
        var s = try crea(gruppi: [(5, 5)])
        let lontana = cella(10, 10)
        s.conoscenza[.giocatore] = [lontana: 0]   // ricordata, appena vista
        // Giorno 1: presidio chiude la giornata, la conoscenza invecchia. Il gruppo
        // resta a (5,5), lontano da (10,10): il ricordo passa a 1 (ancora confermato).
        esegui(.presidio(gruppo: s.gruppiOrdinati[0].id), &s)
        XCTAssertEqual(motore.conoscenza(di: lontana, per: .giocatore, stato: s), .confermato)
        // Si continua a chiudere giornate finché il ricordo supera la soglia: allora
        // decade in avvistato, e i turni annunciati sono l'età vera dell'informazione.
        for _ in 0..<soglia { esegui(.presidio(gruppo: s.gruppiOrdinati[0].id), &s) }
        guard case .avvistato(let turni) = motore.conoscenza(di: lontana, per: .giocatore, stato: s) else {
            return XCTFail("dopo la soglia il ricordo decade in avvistato")
        }
        XCTAssertGreaterThanOrEqual(turni, soglia, "l'avvistato porta l'età vera, non minore della soglia")
        // La casella del gruppo resta confermata: la si osserva ancora.
        XCTAssertEqual(motore.conoscenza(di: cella(5, 5), per: .giocatore, stato: s), .confermato)
    }

    // MARK: - 02 §3.8.1 — lo stato di conoscenza è la prima voce, se diverso da confermato

    func test_3_8_1_la_conoscenza_e_la_prima_voce_e_il_confermato_tace() throws {
        let s = try crea(gruppi: [(5, 5)])
        let vista = VistaCampagna(motore: motore, stato: s, parte: .giocatore)
        // Una casella lontana e mai vista: la prima voce è lo stato di conoscenza.
        let vociLontane = vista.vociDiCasella(cella(1, 1))
        guard let prima = vociLontane.first else { return XCTFail("attesa almeno una voce") }
        XCTAssertEqual(prima, .conoscenza(.inesplorato), "lo stato di conoscenza viene per primo")
        // La casella del proprio gruppo è confermata: il confermato NON si annuncia,
        // e la prima voce è l'occupante.
        let vociQui = vista.vociDiCasella(cella(5, 5))
        XCTAssertFalse(vociQui.contains { if case .conoscenza = $0 { return true }; return false },
                       "il confermato non si annuncia (02 §3.8.1)")
        if case .occupante = vociQui.first {} else { XCTFail("sul confermato la prima voce è l'occupante") }
    }
}
