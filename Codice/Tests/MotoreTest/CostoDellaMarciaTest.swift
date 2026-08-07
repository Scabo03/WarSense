import XCTest
import Motore
import Dati
import Contenuti

/// Lo statuto del costo in giorni della marcia (01 §5.6.3.1, §5.6.3.2, §5.6.3.3).
///
/// Con questa unità il costo non vale più uno per ogni scatto: vi confluiscono, in
/// UNA SOLA grandezza, il costo base, i pesi della casella di partenza e di arrivo,
/// il tipo di strada e il costo fisso della strettoia. I pesi sono PROVVISORI e
/// vivono nei dati; il minimo di uno resta FISSATO. Queste prove fissano che il
/// costo esista come grandezza unica, che venga dai dati, che il comando lo
/// trasporti, e che una marcia di più giorni lasci il gruppo nella casella di
/// partenza fino al compimento.
final class CostoDellaMarciaTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    var motore: MotoreCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
    }

    private func stato(mappa: String = "guado",
                       gruppi: [(Int, Int)] = [(4, 2)]) throws -> StatoCampagna {
        try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: mappa,
                                       gruppiGiocatore: gruppi.map { .init(riga: $0.0, colonna: $0.1) }),
            valori: valoriCampagna)
    }

    // MARK: - 00 §13.1 — il costo vive nei dati, non nel codice

    /// Il Motore non conosce alcun numero proprio: il costo è la SOMMA dei pesi
    /// letti dai dati, saturata a uno. La prova rifà l'aritmetica del Motore con i
    /// pesi dei dati e pretende che coincidano, casella per casella.
    func test_00_13_1_il_costo_in_giorni_e_la_somma_dei_pesi_dei_dati() throws {
        let m = valoriCampagna.marcia
        let s = try stato()
        for da in s.griglia.tutteLeCaselle {
            for a in s.griglia.vicini(di: da) {
                var atteso = m.costoGiorniBase
                atteso += m.pesoTerrenoPartenza[s.mappa.terreno(di: da).rawValue]!
                atteso += m.pesoTerrenoArrivo[s.mappa.terreno(di: a).rawValue]!
                atteso += m.pesoStradaArrivo[s.mappa.strada(di: a).rawValue]!
                if s.mappa.strettoia == a { atteso += m.costoStrettoia }
                atteso = max(1, atteso)
                XCTAssertEqual(motore.costoInGiorni(da: da, a: a, stato: s), atteso,
                               "il costo non coincide con la somma dei pesi dei dati (00 §13.1)")
            }
        }
    }

    /// Su terreno aperto senza strada il costo resta il base: è il caso ordinario.
    /// Marciando in una casella d'acqua costa di più; una strada l'accorcia; il costo
    /// non scende mai sotto uno.
    func test_01_5_6_3_2_i_fattori_confluiscono_in_una_sola_grandezza() throws {
        let s = try stato()
        // (4,3) è aperta senza strada: partenza (4,2) aperta, arrivo aperto -> base.
        XCTAssertEqual(motore.costoInGiorni(da: Cella(riga: 4, colonna: 2),
                                            a: Cella(riga: 4, colonna: 3), stato: s),
                       valoriCampagna.marcia.costoGiorniBase)
        // (3,3) aperta -> base; da (3,3) verso (2,3) acqua -> più giorni.
        let versoAcqua = motore.costoInGiorni(da: Cella(riga: 3, colonna: 3),
                                              a: Cella(riga: 2, colonna: 3), stato: s)
        XCTAssertGreaterThan(versoAcqua, 1, "marciare nell'acqua costa più di un giorno")
        // Il costo non scende sotto uno nemmeno con la strada che lo accorcia.
        for da in s.griglia.tutteLeCaselle {
            for a in s.griglia.vicini(di: da) {
                XCTAssertGreaterThanOrEqual(motore.costoInGiorni(da: da, a: a, stato: s), 1,
                                            "uno scatto a costo zero è vietato (00 §13.6)")
            }
        }
    }

    /// Il valore è letto e non ricalcolato: cambiando il base nei dati cambia il
    /// costo di ogni scatto.
    func test_00_13_1_cambiando_il_dato_cambia_il_costo() throws {
        let m = valoriCampagna.marcia
        let alterata = ValoriMarcia(costoGiorniBase: m.costoGiorniBase + 2,
                                    posizioniVisive: m.posizioniVisive,
                                    pesoTerrenoPartenza: m.pesoTerrenoPartenza,
                                    pesoTerrenoArrivo: m.pesoTerrenoArrivo,
                                    pesoStradaArrivo: m.pesoStradaArrivo,
                                    costoStrettoia: m.costoStrettoia)
        let alterati = ValoriCampagna(formatiMappa: valoriCampagna.formatiMappa,
                                      mappe: valoriCampagna.mappe,
                                      nomiGruppi: valoriCampagna.nomiGruppi,
                                      marcia: alterata)
        let altroMotore = MotoreCampagna(valori: valori, valoriCampagna: alterati)
        let s = try stato()
        XCTAssertEqual(altroMotore.costoInGiorni(da: Cella(riga: 4, colonna: 2),
                                                 a: Cella(riga: 4, colonna: 3), stato: s),
                       m.costoGiorniBase + 2)
    }

    func test_00_13_6_un_costo_minore_di_uno_e_respinto_in_caricamento() throws {
        let cartella = FileManager.default.temporaryDirectory
            .appendingPathComponent("valori-costo-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: Contenuti.valoriDiFabbrica, to: cartella)
        defer { try? FileManager.default.removeItem(at: cartella) }
        // File completo nella forma, ma con il costo base a zero: colpisce il cancello
        // del minimo, non il decodificatore.
        let costoZero = """
        {"costo_giorni_base": 0, "posizioni_visive": 9,
         "peso_terreno_partenza": {"aperto": 0, "bosco": 1, "acqua": 1},
         "peso_terreno_arrivo": {"aperto": 0, "bosco": 1, "acqua": 2},
         "peso_strada_arrivo": {"nessuna": 0, "sterrata": 0, "battuta": -1, "lastricata": -1},
         "costo_strettoia": 1}
        """
        try Data(costoZero.utf8).write(to: cartella.appendingPathComponent("marcia-campagna.json"))
        XCTAssertThrowsError(try CaricatoreCampagna.carica(da: cartella),
                             "uno scatto a costo zero sarebbe il difetto che 00 §13.6 vieta")
    }

    /// Un peso di terreno mancante è respinto: un fattore assente sarebbe una regola
    /// che si somma in modo opaco, cioè per omissione (01 §5.6.3.2).
    func test_01_5_6_3_2_un_peso_mancante_e_respinto_in_caricamento() throws {
        let cartella = FileManager.default.temporaryDirectory
            .appendingPathComponent("valori-peso-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: Contenuti.valoriDiFabbrica, to: cartella)
        defer { try? FileManager.default.removeItem(at: cartella) }
        let manca = """
        {"costo_giorni_base": 1, "posizioni_visive": 9,
         "peso_terreno_partenza": {"aperto": 0, "bosco": 1},
         "peso_terreno_arrivo": {"aperto": 0, "bosco": 1, "acqua": 2},
         "peso_strada_arrivo": {"nessuna": 0, "sterrata": 0, "battuta": -1, "lastricata": -1},
         "costo_strettoia": 1}
        """
        try Data(manca.utf8).write(to: cartella.appendingPathComponent("marcia-campagna.json"))
        XCTAssertThrowsError(try CaricatoreCampagna.carica(da: cartella),
                             "manca il peso di partenza per l'acqua: va respinto")
    }

    // MARK: - 01 §5.6.3.1 — il comando trasporta il costo

    func test_01_5_6_3_1_il_comando_di_marcia_trasporta_il_costo_in_giorni() throws {
        let s = try stato()
        let id = s.gruppiOrdinati[0].id
        let vista = VistaCampagna(motore: motore, stato: s, parte: .giocatore)
        let comando = try XCTUnwrap(vista.comandoDiMarcia(per: id, a: Cella(riga: 4, colonna: 3)))
        guard case .marcia(_, _, let giorni) = comando else {
            return XCTFail("il comando di marcia non porta i giorni")
        }
        XCTAssertEqual(giorni, motore.costoInGiorni(da: Cella(riga: 4, colonna: 2),
                                                    a: Cella(riga: 4, colonna: 3), stato: s))
        XCTAssertTrue(motore.valida(comando, parte: .giocatore, stato: s).eValido)
    }

    /// Un comando che dichiari un costo diverso da quello prescritto è rifiutato con
    /// il proprio motivo, non applicato in silenzio (giornale estraneo o manomesso).
    func test_01_5_6_3_1_un_costo_diverso_da_quello_prescritto_e_rifiutato() throws {
        let s = try stato()
        let id = s.gruppiOrdinati[0].id
        let vero = motore.costoInGiorni(da: Cella(riga: 4, colonna: 2),
                                        a: Cella(riga: 4, colonna: 3), stato: s)
        for giorni in [0, vero + 1, vero + 5] {
            let comando = ComandoCampagna.marcia(gruppo: id, a: Cella(riga: 4, colonna: 3),
                                                 giorni: giorni)
            XCTAssertEqual(motore.valida(comando, parte: .giocatore, stato: s).motivo,
                           .costoNonCoerente, "costo \(giorni) accettato")
        }
    }

    // MARK: - 01 §5.6.3.3 — la marcia lunga lascia il gruppo nella casella di partenza

    /// Una marcia di più giorni, ordinata mentre un altro gruppo deve ancora agire,
    /// NON muove il gruppo: lo lascia nella casella di partenza, in marcia, con i
    /// giorni mancanti dichiarati e l'azione spesa. Non esiste stato intermedio.
    func test_01_5_6_3_3_la_marcia_lunga_non_muove_il_gruppo_subito() throws {
        // Due gruppi: ordinandone uno, la giornata NON si chiude, e la risoluzione
        // di fine giornata non scatta. (3,3) è aperta; (2,3) è acqua e costa più giorni.
        var s = try stato(gruppi: [(3, 3), (4, 3)])
        let id = s.occupante(di: Cella(riga: 3, colonna: 3))!.id
        let vista = VistaCampagna(motore: motore, stato: s, parte: .giocatore)
        let comando = try XCTUnwrap(vista.comandoDiMarcia(per: id, a: Cella(riga: 2, colonna: 3)))
        guard case .marcia(_, _, let giorni) = comando else { return XCTFail() }
        XCTAssertGreaterThan(giorni, 1, "la marcia nell'acqua dura più di un giorno")
        let (dopo, eventi) = motore.applica(comando, parte: .giocatore, stato: s)
        s = dopo
        XCTAssertEqual(s.gruppi[id]!.posizione, Cella(riga: 3, colonna: 3),
                       "il gruppo resta nella casella di partenza (01 §5.6.3.3)")
        XCTAssertEqual(s.gruppi[id]!.marcia?.destinazione, Cella(riga: 2, colonna: 3))
        XCTAssertEqual(s.gruppi[id]!.marcia?.giorniMancanti, giorni)
        XCTAssertTrue(s.gruppi[id]!.azioneSpesa)
        XCTAssertEqual(s.giorno, 1, "l'altro gruppo non ha agito: la giornata resta aperta")
        XCTAssertTrue(eventi.contains { if case .marciaOrdinata = $0 { return true } else { return false } })
        XCTAssertFalse(eventi.contains { if case .marciaCompiuta = $0 { return true } else { return false } })
    }

    /// La marcia si compie alla risoluzione di fine giornata, dopo tanti giorni
    /// quanti il costo. Con un solo gruppo la giornata si chiude a ogni ordine e la
    /// cascata la porta a compimento.
    func test_01_5_6_11_la_marcia_si_compie_alla_risoluzione_di_fine_giornata() throws {
        var s = try stato(gruppi: [(3, 3)])
        let id = s.gruppiOrdinati[0].id
        let vista = VistaCampagna(motore: motore, stato: s, parte: .giocatore)
        let comando = try XCTUnwrap(vista.comandoDiMarcia(per: id, a: Cella(riga: 2, colonna: 3)))
        guard case .marcia(_, _, let giorni) = comando else { return XCTFail() }
        let giornoIniziale = s.giorno
        let (dopo, eventi) = motore.applica(comando, parte: .giocatore, stato: s)
        s = dopo
        // Un solo gruppo: ordinata la marcia, la giornata si chiude e la cascata
        // avanza la marcia fino al compimento. Il gruppo arriva dopo `giorni` giornate.
        XCTAssertEqual(s.gruppi[id]!.posizione, Cella(riga: 2, colonna: 3),
                       "la marcia si è compiuta e il gruppo è arrivato")
        XCTAssertNil(s.gruppi[id]!.marcia)
        XCTAssertEqual(s.giorno, giornoIniziale + giorni, "sono passate tante giornate quante il costo")
        XCTAssertTrue(eventi.contains { if case .marciaCompiuta = $0 { return true } else { return false } })
    }
}
