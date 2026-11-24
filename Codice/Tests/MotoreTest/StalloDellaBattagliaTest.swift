import XCTest
import Motore
import Dati
import Contenuti

/// Le battaglie che non avrebbero fine (01 §10.7.1; incarico 32). Due schieramenti troppo ingombranti per
/// incontrarsi, una colonna fermata da un proprio reparto che non può andare oltre, un tattico che provava un
/// passo solo: con i due tattici dello stesso ufficiale le tre battaglie restavano aperte finché il banco
/// non le interrompeva. È l'avversario a uscire da uno stallo, ritirandosi: il giocatore decide da sé.
final class StalloDellaBattagliaTest: XCTestCase {

    private static let tettoTurni = 400

    private func valori() throws -> ValoriDiGioco { try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica) }

    private func battaglia(_ valori: ValoriDiGioco, giocatore: [(String, Int64)], avversario: [(String, Int64)],
                           primo: Parte = .giocatore) throws -> StatoBattaglia {
        func mazzo(_ elementi: [(String, Int64)]) -> [ScenarioBattaglia.ElementoScenario] {
            elementi.map { .init(archetipo: $0.0, protezione: .antiSaturazione, atomi: $0.1, esemplari: 1) }
        }
        return try FabbricaBattaglia.crea(scenario: ScenarioBattaglia(
            formato: "cento", caratteristica: "campo_aperto", ostacoli: [], primoOccupante: primo, imboscata: false,
            deckGiocatore: mazzo(giocatore), deckAvversario: mazzo(avversario), ufficialeAvversario: "ufficiale_prova"),
            valori: valori).0
    }

    /// Un campo già schierato, dal secondo turno di ciascuno in poi: nessuna riserva, il volume di un turno
    /// pieno, tutti i reparti con l'azione da spendere.
    private func campo(_ valori: ValoriDiGioco, turno: Parte, giro: Int = 8,
                       _ posti: [(parte: Parte, archetipo: String, atomi: Int64, riga: Int, colonna: Int)]) throws -> StatoBattaglia {
        var stato = try battaglia(valori, giocatore: [("fanteria_leggera", 6)], avversario: [("fanteria_leggera", 6)])
        let formato = try XCTUnwrap(valori.formati["cento"])
        // Un giro a vuoto, perché ciascuna parte abbia il proprio bilancio del volume.
        let motore = MotoreBattaglia(valori: valori)
        for _ in Parte.allCases { stato = motore.applica(.fineTurno, parte: stato.parteDiTurno, stato: stato).0 }
        stato.deck = [.giocatore: [], .avversario: []]
        stato.selezione = [:]
        for posto in posti {
            let id = IdSciame(stato.prossimoIdSciame)
            stato.prossimoIdSciame += 1
            let archetipo = try XCTUnwrap(valori.archetipi[IdentificatoreDati(stringLiteral: posto.archetipo)])
            stato.sciami[id] = Sciame(id: id, parte: posto.parte, archetipo: IdentificatoreDati(stringLiteral: posto.archetipo),
                                      protezione: .antiSaturazione, lettera: id.numero, atomiIniziali: posto.atomi,
                                      serbatoio: posto.atomi * archetipo.puntiVitaPerAtomo, munizioni: archetipo.dotazioneMunizioni,
                                      posizione: Cella(riga: posto.riga, colonna: posto.colonna), azioneSpesa: false, rinforzo: false)
            stato.forzeImpegnate[posto.parte, default: 0] += posto.atomi * archetipo.puntiVitaPerAtomo
        }
        stato.giro = giro
        stato.parteDiTurno = turno
        stato.turniGiocati = [.giocatore: giro, .avversario: giro]
        for parte in Parte.allCases {
            stato.bilancio[parte]?.baseTurno = formato.budgetVolumeBase
            stato.bilancio[parte]?.riportoEntrante = formato.quotaRiporto.applicato(a: formato.budgetVolumeBase)
            stato.bilancio[parte]?.spesa = 0
        }
        return stato
    }

    private func tattici(_ motore: MotoreBattaglia) throws -> [Parte: TatticoBattaglia] {
        let ufficiale = try XCTUnwrap(motore.valori.ufficiali["ufficiale_prova"])
        return [.giocatore: TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .giocatore),
                .avversario: TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .avversario)]
    }

    /// Gioca fino alla conclusione coi due tattici; nullo se al tetto dei turni la battaglia è ancora aperta.
    private func gioca(_ stato: inout StatoBattaglia, _ motore: MotoreBattaglia) throws -> EsitoBattaglia? {
        let tattici = try tattici(motore)
        var passi = 0
        while stato.esito == nil, stato.giro <= Self.tettoTurni, passi < 40_000 {
            passi += 1
            let comando = tattici[stato.parteDiTurno]!.prossimoComando(stato: stato)
            XCTAssertTrue(motore.valida(comando, parte: stato.parteDiTurno, stato: stato).eValido, "\(comando)")
            stato = motore.applica(comando, parte: stato.parteDiTurno, stato: stato).0
        }
        return stato.esito
    }

    // MARK: - Due schieramenti troppo ingombranti

    /// Ventiquattro fanti pesanti e dodici cavalieri da una parte e dall'altra: nessun reparto può avanzare,
    /// nessuno è a portata. La battaglia si conclude con la ritirata dell'avversario, e nessuno ha perso un
    /// uomo.
    func test_01_10_7_1_due_schieramenti_che_non_possono_incontrarsi_si_concludono_con_la_ritirata_dell_avversario() throws {
        let motore = MotoreBattaglia(valori: try valori())
        let pesanti: [(String, Int64)] = [("fanteria_pesante", 24), ("cavalleria_manovrata", 12)]
        for primo in Parte.allCases {
            var stato = try battaglia(motore.valori, giocatore: pesanti, avversario: pesanti, primo: primo)
            XCTAssertFalse(motore.nonPossonoPiuIncontrarsi(stato), "al primo turno il volume è maggiorato: non si giudica")
            let esito = try XCTUnwrap(try gioca(&stato, motore), "\(primo): la battaglia si conclude")
            XCTAssertEqual(esito.sconfitto, .avversario, "\(primo)")
            XCTAssertEqual(esito.modo, .ritirataCompiuta, "\(primo)")
            XCTAssertLessThan(esito.turni, 10, "\(primo): appena lo stallo c'è, non al tetto")
            XCTAssertEqual(stato.perditeSubite.values.reduce(0, +), 0, "\(primo): nessuno ha combattuto")
            XCTAssertEqual(stato.evacuati[.avversario]?.count, 1, "\(primo): il reparto schierato esce")
        }
    }

    /// Due schieramenti che si possono incontrare non sono in stallo prima del contatto: nessuna delle due
    /// funzioni lo dice vero, e la battaglia si combatte.
    func test_01_10_7_1_due_schieramenti_che_possono_incontrarsi_non_sono_in_stallo() throws {
        let motore = MotoreBattaglia(valori: try valori())
        let lupo: [(String, Int64)] = [("fanteria_leggera", 18), ("fanteria_pesante", 8)]
        var stato = try battaglia(motore.valori, giocatore: lupo, avversario: lupo)
        let tattici = try tattici(motore)
        var passi = 0
        while stato.esito == nil, stato.contatti.isEmpty, passi < 2_000 {
            passi += 1
            XCTAssertFalse(motore.nonPossonoPiuIncontrarsi(stato), "passo \(passi)")
            XCTAssertFalse(motore.nessunoPuoAvvicinarsi(stato), "passo \(passi)")
            let comando = tattici[stato.parteDiTurno]!.prossimoComando(stato: stato)
            stato = motore.applica(comando, parte: stato.parteDiTurno, stato: stato).0
        }
        XCTAssertFalse(stato.contatti.isEmpty, "si sono incontrati")
    }

    /// Il giocatore non esce da sé da uno stallo: il suo tattico, al banco, chiude il turno.
    func test_01_15_2_4_il_tattico_del_giocatore_non_si_arrende_per_uno_stallo() throws {
        let motore = MotoreBattaglia(valori: try valori())
        let stato = try campo(motore.valori, turno: .giocatore, [
            (.giocatore, "fanteria_pesante", 24, 10, 5), (.avversario, "fanteria_pesante", 24, 1, 5)])
        XCTAssertTrue(motore.nonPossonoPiuIncontrarsi(stato))
        XCTAssertEqual(try tattici(motore)[.giocatore]!.prossimoComando(stato: stato), .fineTurno)
        var suo = stato
        suo.parteDiTurno = .avversario
        XCTAssertEqual(try tattici(motore)[.avversario]!.prossimoComando(stato: suo), .dichiaraResa)
    }

    // MARK: - La colonna fermata

    /// La colonna dell'avversario è davanti ai reparti del giocatore, che non possono lasciare la loro riga:
    /// il reparto di testa non può fare l'ultimo passo, gli altri sono fermati da lui. Nessuno può più
    /// avvicinarsi, e l'avversario si ritira.
    func test_01_10_7_1_quando_nessuno_puo_piu_avvicinarsi_l_avversario_si_ritira() throws {
        let motore = MotoreBattaglia(valori: try valori())
        var stato = try campo(motore.valori, turno: .avversario, [
            (.giocatore, "cavalleria_manovrata", 12, 10, 6), (.giocatore, "fanteria_pesante", 21, 10, 7),
            (.avversario, "fanteria_pesante", 12, 8, 5), (.avversario, "fanteria_pesante", 12, 7, 5),
            (.avversario, "cavalleria_manovrata", 6, 6, 4)])
        // Lo si lascia giocare: la colonna avanza finché può, e poi si ferma.
        let esito = try XCTUnwrap(try gioca(&stato, motore), "la battaglia si conclude")
        XCTAssertEqual(esito.sconfitto, .avversario)
        XCTAssertEqual(esito.modo, .ritirataCompiuta)
        XCTAssertEqual(stato.perditeSubite.values.reduce(0, +), 0, "nessuno si è potuto colpire")
        XCTAssertLessThan(esito.turni, 40)
    }

    /// Finché uno dei due può fare un passo che lo avvicina, o colpire, lo stallo non c'è.
    func test_01_10_7_1_chi_puo_ancora_fare_un_passo_verso_il_nemico_non_e_in_stallo() throws {
        let motore = MotoreBattaglia(valori: try valori())
        let libero = try campo(motore.valori, turno: .avversario, [
            (.giocatore, "fanteria_leggera", 6, 10, 6), (.avversario, "fanteria_pesante", 12, 5, 5)])
        XCTAssertFalse(motore.nessunoPuoAvvicinarsi(libero))
        let aContatto = try campo(motore.valori, turno: .avversario, [
            (.giocatore, "fanteria_pesante", 24, 10, 5), (.avversario, "fanteria_pesante", 12, 9, 5)])
        XCTAssertFalse(motore.nessunoPuoAvvicinarsi(aContatto), "adiacenti: l'ingaggio è possibile")
        var appenaStaccati = try campo(motore.valori, turno: .avversario, [
            (.giocatore, "fanteria_pesante", 24, 10, 5), (.avversario, "fanteria_pesante", 24, 9, 5)])
        let ids = appenaStaccati.sciamiOrdinati.map(\.id)
        appenaStaccati.divietoIngaggio[Coppia(ids[0], ids[1])] = appenaStaccati.giro
        XCTAssertFalse(motore.nessunoPuoAvvicinarsi(appenaStaccati), "il divieto d'ingaggio passa: non è uno stallo")
    }

    // MARK: - Il passo del tattico

    /// Il reparto che non può pagare il passo più vicino al nemico — una riga più avanti — prende l'altro che
    /// lo avvicina e che può pagare. Fino alla build 32 ne provava uno solo e restava fermo.
    func test_01_14_2_il_tattico_prende_il_passo_che_puo_pagare_e_non_soltanto_il_piu_vicino() throws {
        let motore = MotoreBattaglia(valori: try valori())
        let stato = try campo(motore.valori, turno: .giocatore, [
            (.giocatore, "cavalleria_manovrata", 6, 2, 6), (.avversario, "fanteria_pesante", 24, 1, 4)])
        let cavalleria = try XCTUnwrap(stato.sciamiOrdinati.first { $0.parte == .giocatore })
        let nemico = try XCTUnwrap(stato.sciamiOrdinati.first { $0.parte == .avversario })
        let distanza = stato.griglia.distanza(cavalleria.posizione, nemico.posizione)
        let passi = stato.griglia.vicini(di: cavalleria.posizione)
            .filter { stato.griglia.distanza($0, nemico.posizione) < distanza }
            .sorted { a, b in
                let da = stato.griglia.distanza(a, nemico.posizione), db = stato.griglia.distanza(b, nemico.posizione)
                return da != db ? da < db : a < b
            }
        let pagabili = passi.filter { motore.valida(.muovi(sciame: cavalleria.id, percorso: [$0]), parte: .giocatore, stato: stato).eValido }
        XCTAssertGreaterThan(passi.count, 1)
        XCTAssertFalse(pagabili.contains(passi[0]), "il più vicino costa troppo: è la premessa")
        let comando = try tattici(motore)[.giocatore]!.prossimoComando(stato: stato)
        XCTAssertEqual(comando, .muovi(sciame: cavalleria.id, percorso: [try XCTUnwrap(pagabili.first)]))
    }
}
