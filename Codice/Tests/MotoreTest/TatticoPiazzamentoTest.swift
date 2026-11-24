import XCTest
import Motore
import Dati
import Contenuti

/// Il piazzamento del tattico avversario (incarico 32). Con un elemento del mazzo che il volume del
/// turno non basta a piazzare, seguito da un altro ancora da piazzare, il tattico alternava la
/// selezione dei due senza fine e non chiudeva mai il turno: il reperto dell'incarico 31, e la causa di
/// ogni battaglia che al banco non si concludeva.
final class TatticoPiazzamentoTest: XCTestCase {

    private func valori() throws -> ValoriDiGioco { try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica) }

    private func battaglia(_ valori: ValoriDiGioco, mazzo: [(String, Int64)], primo: Parte = .avversario) throws -> StatoBattaglia {
        let scenario = ScenarioBattaglia(
            formato: "cento", caratteristica: "campo_aperto", ostacoli: [], primoOccupante: primo, imboscata: false,
            deckGiocatore: [.init(archetipo: "fanteria_leggera", protezione: .antiSaturazione, atomi: 6, esemplari: 1)],
            deckAvversario: mazzo.map { .init(archetipo: $0.0, protezione: .antiSaturazione, atomi: $0.1, esemplari: 1) },
            ufficialeAvversario: "ufficiale_prova")
        return try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
    }

    /// I comandi del tattico fino alla fine del proprio turno, entro un tetto che un turno vero non
    /// raggiunge: un comando per selezione, uno per piazzamento, uno per reparto, e la fine.
    private func turno(_ stato: inout StatoBattaglia, _ valori: ValoriDiGioco, parte: Parte = .avversario,
                       tetto: Int = 60) throws -> [ComandoBattaglia] {
        let motore = MotoreBattaglia(valori: valori)
        let tattico = TatticoBattaglia(motore: motore, ufficiale: try XCTUnwrap(valori.ufficiali["ufficiale_prova"]), parte: parte)
        var comandi: [ComandoBattaglia] = []
        while stato.parteDiTurno == parte, stato.esito == nil, comandi.count < tetto {
            let comando = tattico.prossimoComando(stato: stato)
            XCTAssertTrue(motore.valida(comando, parte: parte, stato: stato).eValido, "il tattico propone un comando valido: \(comando)")
            comandi.append(comando)
            stato = motore.applica(comando, parte: parte, stato: stato).0
        }
        return comandi
    }

    /// Il caso del resoconto dell'incarico 31: sei reparti, gli ultimi due non piazzabili col volume che
    /// resta. Il turno finisce.
    func test_due_elementi_non_piazzabili_non_alternano_la_selezione() throws {
        let valori = try valori()
        var stato = try battaglia(valori, mazzo: [
            ("fanteria_leggera", 6), ("fanteria_leggera", 6), ("fanteria_leggera", 6), ("fanteria_leggera", 6),
            ("fanteria_pesante", 24), ("cavalleria_manovrata", 12)])
        let comandi = try turno(&stato, valori)
        XCTAssertEqual(comandi.last, .fineTurno, "il turno si chiude: \(comandi.count) comandi, ultimi \(comandi.suffix(4))")
        XCTAssertEqual(stato.deck[.avversario]?.map(\.esemplari), [0, 0, 0, 0, 1, 1],
                       "scendono i quattro che il volume ammette, restano i due che non ci stanno")
        let selezioni = comandi.filter { if case .seleziona = $0 { return true } else { return false } }
        XCTAssertEqual(selezioni.count, 4, "una selezione per elemento piazzato, e nessuna per chi non può scendere")
    }

    /// Basta un solo elemento non piazzabile davanti a uno che lo è: prima il tattico alternava anche qui.
    func test_un_elemento_non_piazzabile_non_ferma_quello_che_lo_segue() throws {
        let valori = try valori()
        var stato = try battaglia(valori, mazzo: [("fanteria_pesante", 32), ("fanteria_leggera", 3)])
        let comandi = try turno(&stato, valori)
        XCTAssertEqual(comandi.last, .fineTurno)
        XCTAssertEqual(stato.deck[.avversario]?.map(\.esemplari), [1, 0],
                       "la fanteria leggera scende, la pesante che eccede il volume del turno resta nel mazzo")
    }

    /// Chi non può piazzare nulla non seleziona nulla: nessun comando a vuoto prima della fine del turno.
    func test_senza_nulla_di_piazzabile_il_turno_si_chiude_senza_selezionare() throws {
        let valori = try valori()
        var stato = try battaglia(valori, mazzo: [("fanteria_pesante", 32), ("cavalleria_manovrata", 20)])
        XCTAssertEqual(try turno(&stato, valori), [.fineTurno])
    }

    /// L'ordine del piazzamento non cambia quando tutto ci sta: il primo elemento del mazzo scende per
    /// primo, come prima della correzione.
    func test_quando_tutto_ci_sta_l_ordine_del_mazzo_resta() throws {
        let valori = try valori()
        var stato = try battaglia(valori, mazzo: [("fanteria_leggera", 6), ("fanteria_pesante", 8)])
        let comandi = try turno(&stato, valori)
        XCTAssertEqual(comandi.prefix(1), [.seleziona(indiceDeck: 0)])
        XCTAssertEqual(stato.deck[.avversario]?.map(\.esemplari), [0, 0])
        XCTAssertEqual(stato.sciamiOrdinati.map(\.archetipo), ["fanteria_leggera", "fanteria_pesante"])
    }
}
