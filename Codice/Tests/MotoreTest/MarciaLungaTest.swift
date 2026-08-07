import XCTest
import Motore
import Dati
import Contenuti

/// Collaudo delle marce di più giorni, della revoca e della risoluzione di fine
/// giornata (01 §5.6.3.1–§5.6.3.5, §5.6.11, §5.6.8.1). Ogni prova cita la regola
/// numerata che verifica.
final class MarciaLungaTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    var motore: MotoreCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
    }

    static let composizioneLeggera: [ScenarioCampagna.RepartoIniziale] =
        [.init(archetipo: "fanteria_leggera", atomi: 6)]

    private func crea(mappa: String = "guado", gruppi: [(Int, Int)]) throws -> StatoCampagna {
        try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: mappa,
                                       gruppiGiocatore: gruppi.map {
                                        .init(riga: $0.0, colonna: $0.1, composizione: Self.composizioneLeggera) }),
            valori: valoriCampagna, archetipiNoti: Set(valori.archetipi.keys))
    }

    @discardableResult
    private func esegui(_ comando: ComandoCampagna, _ stato: inout StatoCampagna) -> [EventoCampagna] {
        XCTAssertTrue(motore.valida(comando, parte: .giocatore, stato: stato).eValido)
        let (nuovo, eventi) = motore.applica(comando, parte: .giocatore, stato: stato)
        stato = nuovo
        return eventi
    }

    /// Il costo verso una casella d'acqua, da uno scenario a due gruppi (la giornata
    /// resta aperta ordinandone uno solo).
    private func statoMarciaLunga() throws -> (StatoCampagna, IdGruppo, Int) {
        var stato = try crea(gruppi: [(3, 3), (4, 3)])
        let id = stato.occupante(di: Cella(riga: 3, colonna: 3))!.id
        let costo = motore.costoInGiorni(da: Cella(riga: 3, colonna: 3),
                                         a: Cella(riga: 2, colonna: 3), stato: stato)
        XCTAssertGreaterThan(costo, 1)
        esegui(.marcia(gruppo: id, a: Cella(riga: 2, colonna: 3), giorni: costo), &stato)
        return (stato, id, costo)
    }

    // MARK: - 01 §5.6.3.3 — nessuno stato intermedio, i giorni mancanti dichiarati

    func test_01_5_6_3_3_durante_la_marcia_il_gruppo_resta_in_partenza() throws {
        let (stato, id, costo) = try statoMarciaLunga()
        XCTAssertEqual(stato.gruppi[id]!.posizione, Cella(riga: 3, colonna: 3))
        XCTAssertEqual(stato.gruppi[id]!.marcia?.giorniMancanti, costo,
                       "appena ordinata, mancano tutti i giorni")
        XCTAssertEqual(stato.gruppi[id]!.marcia?.giorniCompiuti, 0)
    }

    /// Un gruppo in marcia lunga NON compare fra i gruppi in attesa: non attende
    /// alcuna decisione (01 §5.16.1). È la condizione del rotore.
    func test_01_5_16_1_il_gruppo_in_marcia_non_compare_fra_quelli_in_attesa() throws {
        let (stato, id, _) = try statoMarciaLunga()
        XCTAssertFalse(stato.gruppiInAttesa().contains { $0.id == id },
                       "il gruppo in marcia non è in attesa")
        XCTAssertTrue(stato.gruppiInMarcia().contains { $0.id == id })
    }

    /// Un gruppo in marcia lunga non riceve mai un ordine di marcia o di presidio
    /// (01 §5.6.3.3): reso impossibile dalla validazione.
    func test_01_5_6_3_3_un_gruppo_in_marcia_non_riceve_ordini() throws {
        let (stato, id, _) = try statoMarciaLunga()
        XCTAssertEqual(motore.valida(.presidio(gruppo: id), parte: .giocatore, stato: stato).motivo,
                       .azioneGiaSpesa)
        XCTAssertEqual(motore.valida(.marcia(gruppo: id, a: Cella(riga: 2, colonna: 2), giorni: 1),
                                     parte: .giocatore, stato: stato).motivo, .azioneGiaSpesa)
    }

    // MARK: - 01 §5.6.3.4 — l'avanzamento visivo è derivato dai giorni

    func test_01_5_6_3_4_la_posizione_visiva_e_derivata_dalla_proporzione() throws {
        let posizioni = valoriCampagna.marcia.posizioniVisive
        // Con troncamento per difetto: 0 giorni -> 0; a metà -> circa metà; mai il fondo.
        XCTAssertEqual(motore.avanzamentoVisivo(giorniCompiuti: 0, giorniTotali: 3), 0)
        XCTAssertEqual(motore.avanzamentoVisivo(giorniCompiuti: 1, giorniTotali: 3), posizioni / 3)
        XCTAssertEqual(motore.avanzamentoVisivo(giorniCompiuti: 2, giorniTotali: 3), (2 * posizioni) / 3)
        // Il valore resta sempre in [0, posizioni): non raggiunge il fondo finché la
        // marcia è in corso (giorni compiuti < totali).
        for totali in 1...9 {
            for compiuti in 0..<totali {
                let v = motore.avanzamentoVisivo(giorniCompiuti: compiuti, giorniTotali: totali)
                XCTAssertTrue(v >= 0 && v < posizioni, "posizione fuori intervallo")
            }
        }
    }

    // MARK: - 01 §5.6.11 — la risoluzione di fine giornata avanza le marce

    func test_01_5_6_11_la_marcia_avanza_di_un_giorno_a_ogni_chiusura() throws {
        // Un gruppo in marcia lunga e uno che presidia ogni giorno: a ogni chiusura la
        // marcia avanza di un giorno, finché si compie.
        var stato = try crea(gruppi: [(3, 3), (4, 3)])
        let marciante = stato.occupante(di: Cella(riga: 3, colonna: 3))!.id
        let fermo = stato.occupante(di: Cella(riga: 4, colonna: 3))!.id
        let costo = motore.costoInGiorni(da: Cella(riga: 3, colonna: 3),
                                         a: Cella(riga: 2, colonna: 3), stato: stato)
        esegui(.marcia(gruppo: marciante, a: Cella(riga: 2, colonna: 3), giorni: costo), &stato)
        for giornoAtteso in 1..<costo {
            esegui(.presidio(gruppo: fermo), &stato)   // chiude la giornata
            XCTAssertEqual(stato.gruppi[marciante]!.marcia?.giorniCompiuti, giornoAtteso,
                           "la marcia è avanzata di un giorno")
            XCTAssertEqual(stato.gruppi[marciante]!.posizione, Cella(riga: 3, colonna: 3),
                           "finché non è compiuta, il gruppo resta in partenza")
        }
        // L'ultima chiusura la compie.
        let eventi = esegui(.presidio(gruppo: fermo), &stato)
        XCTAssertNil(stato.gruppi[marciante]!.marcia)
        XCTAssertEqual(stato.gruppi[marciante]!.posizione, Cella(riga: 2, colonna: 3))
        XCTAssertTrue(eventi.contains { if case .marciaCompiuta = $0 { return true } else { return false } })
    }

    /// Se TUTTI i gruppi sono in marcia lunga, non c'è nulla da ordinare e le
    /// giornate scorrono da sé alla chiusura, finché una marcia si compie (01 §5.6.11).
    func test_01_5_6_11_con_tutti_in_marcia_le_giornate_scorrono_a_cascata() throws {
        var stato = try crea(gruppi: [(3, 3)])
        let id = stato.gruppiOrdinati[0].id
        let costo = motore.costoInGiorni(da: Cella(riga: 3, colonna: 3),
                                         a: Cella(riga: 2, colonna: 3), stato: stato)
        let giornoIniziale = stato.giorno
        let eventi = esegui(.marcia(gruppo: id, a: Cella(riga: 2, colonna: 3), giorni: costo), &stato)
        XCTAssertEqual(stato.giorno, giornoIniziale + costo,
                       "sono scorse tante giornate quante il costo, tutte in una sola applicazione")
        let chiusure = eventi.reduce(0) { if case .giornataChiusa = $1 { return $0 + 1 } else { return $0 } }
        XCTAssertEqual(chiusure, costo)
        XCTAssertEqual(stato.gruppi[id]!.posizione, Cella(riga: 2, colonna: 3))
    }

    // MARK: - 01 §5.6.3.3, RDA-100 — la revoca

    func test_01_5_6_3_3_la_revoca_lascia_il_gruppo_in_partenza_con_la_giornata_spesa() throws {
        var stato = try crea(gruppi: [(3, 3), (4, 3)])
        let id = stato.occupante(di: Cella(riga: 3, colonna: 3))!.id
        let costo = motore.costoInGiorni(da: Cella(riga: 3, colonna: 3),
                                         a: Cella(riga: 2, colonna: 3), stato: stato)
        let fermo = stato.occupante(di: Cella(riga: 4, colonna: 3))!.id
        esegui(.marcia(gruppo: id, a: Cella(riga: 2, colonna: 3), giorni: costo), &stato)
        esegui(.presidio(gruppo: fermo), &stato)   // chiude una giornata: la marcia avanza a 1
        XCTAssertEqual(stato.gruppi[id]!.marcia?.giorniCompiuti, 1)
        // La revoca: il gruppo perde i giorni, resta nella casella di partenza, e la
        // giornata è spesa (non restituita) — RDA-100.
        let eventi = esegui(.revocaMarcia(gruppo: id), &stato)
        XCTAssertNil(stato.gruppi[id]!.marcia)
        XCTAssertEqual(stato.gruppi[id]!.posizione, Cella(riga: 3, colonna: 3))
        XCTAssertTrue(stato.gruppi[id]!.azioneSpesa, "la giornata è spesa: il gruppo non compie altro")
        XCTAssertFalse(stato.gruppi[id]!.inMarcia)
        guard case .marciaRevocata(_, _, _, let persi)? = eventi.first(where: {
            if case .marciaRevocata = $0 { return true } else { return false }
        }) else { return XCTFail("nessun evento di revoca") }
        XCTAssertEqual(persi, 1, "i giorni persi sono quelli già compiuti")
    }

    /// La revoca non consuma l'azione come atto — non è un'azione (01 §5.6.8.1) — ma
    /// il gruppo ha già speso la giornata con l'ordine, sicché non agisce di nuovo.
    func test_01_5_6_8_1_dopo_la_revoca_il_gruppo_non_agisce_di_nuovo() throws {
        var stato = try crea(gruppi: [(3, 3), (4, 3)])
        let id = stato.occupante(di: Cella(riga: 3, colonna: 3))!.id
        let costo = motore.costoInGiorni(da: Cella(riga: 3, colonna: 3),
                                         a: Cella(riga: 2, colonna: 3), stato: stato)
        esegui(.marcia(gruppo: id, a: Cella(riga: 2, colonna: 3), giorni: costo), &stato)
        esegui(.revocaMarcia(gruppo: id), &stato)   // stessa giornata dell'ordine
        XCTAssertEqual(motore.valida(.presidio(gruppo: id), parte: .giocatore, stato: stato).motivo,
                       .azioneGiaSpesa)
    }

    func test_01_5_6_3_3_la_revoca_su_un_gruppo_non_in_marcia_e_rifiutata() throws {
        let stato = try crea(gruppi: [(3, 3), (4, 3)])
        let id = stato.occupante(di: Cella(riga: 3, colonna: 3))!.id
        XCTAssertEqual(motore.valida(.revocaMarcia(gruppo: id), parte: .giocatore, stato: stato).motivo,
                       .gruppoNonInMarcia, "non c'è marcia da revocare")
    }

    /// Il registro annota il compimento di una marcia — primo fatto non deciso dal
    /// giocatore (01 §5.17.1) — con il luogo della casella di arrivo (RDA-67).
    func test_01_5_17_1_il_compimento_della_marcia_entra_nel_registro_col_luogo() throws {
        var stato = try crea(gruppi: [(3, 3)])
        let id = stato.gruppiOrdinati[0].id
        let costo = motore.costoInGiorni(da: Cella(riga: 3, colonna: 3),
                                         a: Cella(riga: 2, colonna: 3), stato: stato)
        esegui(.marcia(gruppo: id, a: Cella(riga: 2, colonna: 3), giorni: costo), &stato)
        let compimenti = stato.registro.filter {
            if case .marciaCompiuta = $0.fatto { return true } else { return false }
        }
        XCTAssertEqual(compimenti.count, 1)
        XCTAssertEqual(compimenti[0].luogo, Cella(riga: 2, colonna: 3),
                       "la voce porta al luogo del fatto, cioè la casella di arrivo")
    }
}
