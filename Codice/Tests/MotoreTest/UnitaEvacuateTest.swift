import XCTest
import Motore
import Dati
import Contenuti

/// Le unità evacuate durante la ritirata «sono salvate integralmente» (01 §10.4) e «ricompaiono sulla mappa
/// di campagna» (01 §10.6). Fino alla build 32 il ritorno in campagna contava gli sciami rimasti in campo e
/// le riserve del mazzo, non quelli evacuati: chi si ritirava perdeva tutto ciò che aveva messo in salvo, e
/// se aveva evacuato l'ultimo reparto il suo gruppo spariva dalla mappa (trovato nell'incarico 32 cercando la
/// causa dello squilibrio fra le mappe).
final class UnitaEvacuateTest: XCTestCase {

    private func campagna(_ valori: ValoriDiGioco, mio: [Reparto], suo: [Reparto]) throws -> (StatoCampagna, BattagliaInSospeso, ValoriCampagna) {
        let valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        var stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(
                mappa: "guado",
                gruppiGiocatore: [.init(riga: 4, colonna: 2, composizione: mio.map(ScenarioCampagna.RepartoIniziale.init))],
                gruppiAvversario: [.init(riga: 1, colonna: 2, composizione: suo.map(ScenarioCampagna.RepartoIniziale.init))]),
            valori: valoriCampagna, archetipiNoti: Set(valori.archetipi.keys))
        let casella = Cella(riga: 3, colonna: 2)
        for id in stato.gruppi.keys { stato.gruppi[id]!.posizione = casella }
        let battaglia = BattagliaInSospeso(identificatore: "prova", casella: casella,
                                           gruppoGiocatore: stato.gruppi(di: .giocatore)[0].id,
                                           gruppoAvversario: stato.gruppi(di: .avversario)[0].id,
                                           primoOccupante: .giocatore, imboscante: nil, giorno: 1)
        stato.battaglieInSospeso = [battaglia]
        return (stato, battaglia, valoriCampagna)
    }

    private let modello = PonteCampagnaBattaglia.Modello(formato: "cento", caratteristica: "campo_aperto",
                                                         protezione: .antiSaturazione, ufficialeAvversario: "ufficiale_prova")

    func test_01_10_4_le_unita_evacuate_tornano_in_campagna_con_gli_atomi_che_avevano() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let motore = MotoreBattaglia(valori: valori)
        let migliorato = Reparto(archetipo: "fanteria_pesante", atomi: 8, miglioramento: "addestramento_mirato", leva: 2)
        let (stato, battaglia, _) = try campagna(valori, mio: [Reparto(archetipo: "fanteria_leggera", atomi: 6), migliorato],
                                                 suo: [Reparto(archetipo: "fanteria_leggera", atomi: 6)])
        var sb = try FabbricaBattaglia.crea(scenario: PonteCampagnaBattaglia.scenario(da: battaglia, stato: stato, modello: modello),
                                            valori: valori).0
        // Il giocatore schiera i due reparti sulla propria ultima riga, attende che la resa sia disponibile,
        // si arrende ed evacua entrambi.
        for (indice, colonna) in [(0, 4), (1, 6)] {
            sb = motore.applica(.seleziona(indiceDeck: indice), parte: .giocatore, stato: sb).0
            sb = motore.applica(.piazza(cella: Cella(riga: 10, colonna: colonna)), parte: .giocatore, stato: sb).0
        }
        while !motore.valida(.dichiaraResa, parte: .giocatore, stato: sb).eValido || sb.parteDiTurno != .giocatore {
            sb = motore.applica(.fineTurno, parte: sb.parteDiTurno, stato: sb).0
        }
        // Uno dei due ha perduto la metà: torna con ciò che ha, non con ciò che aveva.
        let leggera = try XCTUnwrap(sb.sciami.values.first { $0.archetipo == "fanteria_leggera" && $0.parte == .giocatore })
        sb.sciami[leggera.id]!.serbatoio = leggera.serbatoio / 2
        sb = motore.applica(.dichiaraResa, parte: .giocatore, stato: sb).0
        while sb.esito == nil {
            let da = sb.sciamiOrdinati.first { $0.parte == .giocatore && motore.valida(.ritiraUnita(sciame: $0.id), parte: .giocatore, stato: sb).eValido }
            let comando: ComandoBattaglia = sb.parteDiTurno == .giocatore ? da.map { .ritiraUnita(sciame: $0.id) } ?? .fineTurno : .fineTurno
            sb = motore.applica(comando, parte: sb.parteDiTurno, stato: sb).0
        }
        XCTAssertEqual(sb.esito?.sconfitto, .giocatore)
        XCTAssertEqual(sb.esito?.modo, .ritirataCompiuta)
        let esito = PonteCampagnaBattaglia.esito(da: sb, per: battaglia, stato: stato, valori: valori)
        XCTAssertEqual(esito.composizione(di: .giocatore),
                       [Reparto(archetipo: "fanteria_leggera", atomi: 3), migliorato],
                       "salvate con gli atomi che avevano, il miglioramento e la leva")
        XCTAssertNotNil(esito.posizione(di: .giocatore), "e il gruppo ripiega, non sparisce")
    }

    /// Un reparto troppo ingombrante per il volume di un turno si evacua comunque, spendendolo tutto
    /// (01 §10.4.2): chi si ritira deve poter uscire.
    func test_01_10_4_2_un_reparto_troppo_ingombrante_si_evacua_spendendo_il_turno_intero() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let motore = MotoreBattaglia(valori: valori)
        let (stato, battaglia, _) = try campagna(valori, mio: [Reparto(archetipo: "fanteria_pesante", atomi: 24)],
                                                 suo: [Reparto(archetipo: "fanteria_leggera", atomi: 6)])
        var sb = try FabbricaBattaglia.crea(scenario: PonteCampagnaBattaglia.scenario(da: battaglia, stato: stato, modello: modello),
                                            valori: valori).0
        sb = motore.applica(.seleziona(indiceDeck: 0), parte: .giocatore, stato: sb).0
        sb = motore.applica(.piazza(cella: Cella(riga: 10, colonna: 5)), parte: .giocatore, stato: sb).0
        while !motore.valida(.dichiaraResa, parte: .giocatore, stato: sb).eValido || sb.parteDiTurno != .giocatore {
            sb = motore.applica(.fineTurno, parte: sb.parteDiTurno, stato: sb).0
        }
        sb = motore.applica(.dichiaraResa, parte: .giocatore, stato: sb).0
        let mio = try XCTUnwrap(sb.sciamiOrdinati.first { $0.parte == .giocatore })
        let base = valori.formati["cento"]!.budgetVolumeBase
        XCTAssertGreaterThan(motore.costo(archetipo: mio.archetipo, atomi: mio.atomiIniziali, cella: mio.posizione, parte: .giocatore, stato: sb), base)
        XCTAssertEqual(motore.valida(.ritiraUnita(sciame: mio.id), parte: .giocatore, stato: sb).costi?.volume, base)
        sb = motore.applica(.ritiraUnita(sciame: mio.id), parte: .giocatore, stato: sb).0
        XCTAssertEqual(sb.esito?.modo, .ritirataCompiuta)
        let esito = PonteCampagnaBattaglia.esito(da: sb, per: battaglia, stato: stato, valori: valori)
        XCTAssertEqual(esito.composizione(di: .giocatore), [Reparto(archetipo: "fanteria_pesante", atomi: 24)])
        // Chi costa meno paga ciò che costa.
        XCTAssertEqual(motore.costo(archetipo: "fanteria_leggera", atomi: 6, cella: Cella(riga: 10, colonna: 5), parte: .giocatore, stato: sb), 60)
    }
}
