import XCTest
import Motore
import Dati
import Contenuti

/// Lo statuto del costo in giorni della marcia (01 §5.6.3.1, §5.6.3.2).
///
/// La prima unità realizza il caso particolare in cui il numero di giorni vale
/// sempre uno. NON è una regola stabilita: è una semplificazione provvisoria, e
/// queste prove ne fissano lo statuto perché una sessione futura non la citi come
/// regola per rifiutarne la modifica. Ciò che è stabilito è che il costo ESISTA
/// come grandezza unica, che venga dai dati e che il comando lo trasporti.
final class CostoDellaMarciaTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    var motore: MotoreCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
    }

    private func stato(mappa: String = "pianura_lunga",
                       gruppi: [(Int, Int)] = [(10, 6)]) throws -> StatoCampagna {
        try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: mappa,
                                       gruppiGiocatore: gruppi.map { .init(riga: $0.0, colonna: $0.1) }),
            valori: valoriCampagna)
    }

    // MARK: - 00 §13.1 — il costo vive nei dati, non nel codice

    func test_00_13_1_il_costo_in_giorni_viene_dal_file_dei_valori() throws {
        XCTAssertEqual(valoriCampagna.marcia.costoGiorniBase, 1,
                       "oggi il costo vale uno, ed è il valore dichiarato nei dati")
        let s = try stato()
        for da in s.griglia.tutteLeCaselle {
            for a in s.griglia.vicini(di: da) {
                XCTAssertEqual(motore.costoInGiorni(da: da, a: a, stato: s),
                               valoriCampagna.marcia.costoGiorniBase,
                               "il Motore non conosce alcun numero proprio (00 §13.1)")
            }
        }
    }

    /// Il valore è letto e non ricalcolato: cambiandolo nei dati cambia il costo,
    /// che è precisamente ciò che 00 §13.1 chiede e ciò che oggi non si potrebbe
    /// verificare se il numero fosse scritto nel programma.
    func test_00_13_1_cambiando_il_dato_cambia_il_costo() throws {
        let alterati = ValoriCampagna(formatiMappa: valoriCampagna.formatiMappa,
                                      mappe: valoriCampagna.mappe,
                                      nomiGruppi: valoriCampagna.nomiGruppi,
                                      marcia: ValoriMarcia(costoGiorniBase: 3))
        let altroMotore = MotoreCampagna(valori: valori, valoriCampagna: alterati)
        let s = try stato()
        XCTAssertEqual(altroMotore.costoInGiorni(da: Cella(riga: 10, colonna: 6),
                                                 a: Cella(riga: 10, colonna: 7), stato: s), 3)
    }

    func test_00_13_6_un_costo_minore_di_uno_e_respinto_in_caricamento() throws {
        let cartella = FileManager.default.temporaryDirectory
            .appendingPathComponent("valori-costo-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: Contenuti.valoriDiFabbrica, to: cartella)
        defer { try? FileManager.default.removeItem(at: cartella) }
        try Data("{\"costo_giorni_base\": 0}".utf8)
            .write(to: cartella.appendingPathComponent("marcia-campagna.json"))
        XCTAssertThrowsError(try CaricatoreCampagna.carica(da: cartella),
                             "uno scatto a costo zero sarebbe il difetto che 00 §13.6 vieta")
    }

    // MARK: - 01 §5.6.3.1 — il comando trasporta il costo

    func test_01_5_6_3_1_il_comando_di_marcia_trasporta_il_costo_in_giorni() throws {
        let s = try stato()
        let id = s.gruppiOrdinati[0].id
        let vista = VistaCampagna(motore: motore, stato: s, parte: .giocatore)
        let comando = try XCTUnwrap(vista.comandoDiMarcia(per: id, a: Cella(riga: 10, colonna: 7)))
        guard case .marcia(_, _, let giorni) = comando else {
            return XCTFail("il comando di marcia non porta i giorni")
        }
        XCTAssertEqual(giorni, valoriCampagna.marcia.costoGiorniBase)
        XCTAssertTrue(motore.valida(comando, parte: .giocatore, stato: s).eValido)
    }

    /// Un comando che dichiari un costo diverso da quello prescritto non è un
    /// comando del gioco: è rifiutato con il proprio motivo, non applicato in
    /// silenzio. Il caso nasce da un giornale estraneo o manomesso.
    func test_01_5_6_3_1_un_costo_diverso_da_quello_prescritto_e_rifiutato() throws {
        let s = try stato()
        let id = s.gruppiOrdinati[0].id
        for giorni in [0, 2, 7] {
            let comando = ComandoCampagna.marcia(gruppo: id, a: Cella(riga: 10, colonna: 7),
                                                 giorni: giorni)
            XCTAssertEqual(motore.valida(comando, parte: .giocatore, stato: s).motivo,
                           .costoNonCoerente, "costo \(giorni) accettato")
        }
    }

    /// Con il costo pari a uno il comportamento osservabile è identico a quello
    /// della prima unità: il gruppo entra nella casella nello stesso turno e la
    /// giornata si chiude quando tutti hanno agito.
    func test_01_5_6_3_1_con_costo_uno_il_comportamento_osservabile_non_cambia() throws {
        var s = try stato(gruppi: [(10, 6), (10, 5)])
        let id = s.gruppiOrdinati[0].id
        let vista = VistaCampagna(motore: motore, stato: s, parte: .giocatore)
        let comando = try XCTUnwrap(vista.comandoDiMarcia(per: id, a: Cella(riga: 10, colonna: 7)))
        let (dopo, eventi) = motore.applica(comando, parte: .giocatore, stato: s)
        s = dopo
        XCTAssertEqual(s.gruppi[id]!.posizione, Cella(riga: 10, colonna: 7),
                       "con un giorno il gruppo entra subito: nessuno stato intermedio")
        XCTAssertTrue(s.gruppi[id]!.azioneSpesa, "l'azione della giornata è spesa (01 §5.6.0.5)")
        XCTAssertEqual(s.giorno, 1, "l'altro gruppo non ha agito: la giornata resta aperta")
        XCTAssertTrue(eventi.contains { if case .marciaEseguita = $0 { return true } else { return false } })
    }

    /// L'identità fra una casella e una giornata NON è una regola del gioco: è la
    /// conseguenza del valore corrente del dato. Questa prova la lega al dato, così
    /// che chi la troverà scritta altrove sappia da dove viene.
    func test_01_5_6_3_1_una_casella_costa_una_giornata_soltanto_perche_il_dato_vale_uno() throws {
        XCTAssertEqual(valoriCampagna.marcia.costoGiorniBase, 1,
                       """
                       Se questo valore cambia, l'identità fra una casella e una \
                       giornata cade: non è una regola dell'unità ma il caso \
                       particolare che i dati oggi producono (01 §5.6.3.1).
                       """)
    }
}
