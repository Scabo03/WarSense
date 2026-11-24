import XCTest
import Motore
import Dati
import Contenuti

/// Il budget del primo turno e la parte che non può più schierare (01 §9.3, §15.2.3; RDA-140, corretta
/// dall'incarico 32). Una parte senza sciami in campo è annientata quando nessun elemento del suo mazzo può
/// più entrare; ma nel primo turno, che ha il budget maggiorato, un elemento che sta in quel budget e non in
/// quello ordinario può ancora entrare: finché il turno dura la parte non è annientata. Fino alla build 32 lo
/// era al primo comando del primo turno: un gruppo i cui reparti stanno tutti fra i due budget perdeva ogni
/// battaglia appena selezionava un elemento del mazzo, coi reparti intatti. È la causa dello squilibrio fra
/// le mappe: è il gruppo armato dell'avversario sulla mappa media, e uno dei tre del giocatore sulle altre.
final class BudgetDelPrimoTurnoTest: XCTestCase {

    private func valori() throws -> ValoriDiGioco { try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica) }

    private func battaglia(_ valori: ValoriDiGioco, giocatore: [(String, Int64)], avversario: [(String, Int64)],
                           primo: Parte) throws -> StatoBattaglia {
        func mazzo(_ elementi: [(String, Int64)]) -> [ScenarioBattaglia.ElementoScenario] {
            elementi.map { .init(archetipo: $0.0, protezione: .antiSaturazione, atomi: $0.1, esemplari: 1) }
        }
        return try FabbricaBattaglia.crea(scenario: ScenarioBattaglia(
            formato: "cento", caratteristica: "campo_aperto", ostacoli: [], primoOccupante: primo, imboscata: false,
            deckGiocatore: mazzo(giocatore), deckAvversario: mazzo(avversario), ufficialeAvversario: "ufficiale_prova"),
            valori: valori).0
    }

    /// Il gruppo di ventiquattro atomi di fanteria pesante e dodici di cavalleria, per le due parti e nei due
    /// ordini: selezionare un elemento non conclude nulla, e il primo si piazza col budget del primo turno.
    func test_01_9_3_un_elemento_che_sta_nel_budget_del_primo_turno_si_piazza_e_la_battaglia_continua() throws {
        let valori = try valori()
        let motore = MotoreBattaglia(valori: valori)
        let pesanti: [(String, Int64)] = [("fanteria_pesante", 24), ("cavalleria_manovrata", 12)]
        for parte in Parte.allCases {
            for primo in Parte.allCases {
                var stato = try battaglia(valori, giocatore: parte == .giocatore ? pesanti : [("fanteria_leggera", 6)],
                                          avversario: parte == .avversario ? pesanti : [("fanteria_leggera", 6)], primo: primo)
                // Fino al suo primo turno.
                while stato.parteDiTurno != parte {
                    stato = motore.applica(.fineTurno, parte: stato.parteDiTurno, stato: stato).0
                    XCTAssertNil(stato.esito, "attende il proprio primo turno: non è annientata")
                }
                let formato = try XCTUnwrap(valori.formati["cento"])
                let volume = 24 * (valori.archetipi["fanteria_pesante"]!.volumePerAtomo)
                XCTAssertGreaterThan(volume, formato.budgetVolumeBase + formato.quotaRiporto.applicato(a: formato.budgetVolumeBase))
                XCTAssertLessThanOrEqual(volume, stato.bilancio[parte]!.disponibile, "sta nel budget del primo turno")
                stato = motore.applica(.seleziona(indiceDeck: 0), parte: parte, stato: stato).0
                XCTAssertNil(stato.esito, "\(parte)/\(primo): selezionare un elemento non conclude la battaglia")
                let cella = try XCTUnwrap(stato.griglia.tutteLeCelle.first {
                    motore.valida(.piazza(cella: $0), parte: parte, stato: stato).eValido
                })
                stato = motore.applica(.piazza(cella: cella), parte: parte, stato: stato).0
                XCTAssertNil(stato.esito)
                XCTAssertEqual(stato.sciami.values.filter { $0.parte == parte }.map(\.atomiIniziali), [24])
            }
        }
    }

    /// Se il primo turno passa senza schierare, la riserva non entrerà più e la parte è annientata: ciò che
    /// RDA-140 voleva, alla fine del turno e non al suo primo comando.
    func test_rda_140_passato_il_primo_turno_la_riserva_troppo_grande_non_tiene_viva_la_parte() throws {
        let valori = try valori()
        let motore = MotoreBattaglia(valori: valori)
        var stato = try battaglia(valori, giocatore: [("fanteria_pesante", 24)], avversario: [("fanteria_leggera", 6)], primo: .giocatore)
        stato = motore.applica(.fineTurno, parte: .giocatore, stato: stato).0
        XCTAssertEqual(stato.esito?.sconfitto, .giocatore)
        XCTAssertEqual(stato.esito?.modo, .annientamento)
        // Un elemento che nemmeno il primo turno può pagare non la tiene viva neppure durante quel turno.
        stato = try battaglia(valori, giocatore: [("fanteria_pesante", 30)], avversario: [("fanteria_leggera", 6)], primo: .giocatore)
        stato = motore.applica(.seleziona(indiceDeck: 0), parte: .giocatore, stato: stato).0
        XCTAssertEqual(stato.esito?.sconfitto, .giocatore)
    }
}
