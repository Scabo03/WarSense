import XCTest
import Motore
import Dati
import Contenuti

/// Collaudo del Motore (05 §14.2): ogni prova cita per numero la regola che verifica.
final class RegoleBattagliaTest: XCTestCase {

    var valori: ValoriDiGioco!
    var motore: MotoreBattaglia!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreBattaglia(valori: valori)
    }

    // MARK: - Attrezzi

    func scenarioOrdinario(formato: String = "cento", imboscata: Bool = false,
                           primoOccupante: Parte = .giocatore) -> ScenarioBattaglia {
        let fanteria = ScenarioBattaglia.ElementoScenario(
            archetipo: "fanteria_leggera", protezione: .antiSaturazione, atomi: 5, esemplari: 3)
        let tiratori = ScenarioBattaglia.ElementoScenario(
            archetipo: "tiratori", protezione: .antiSaturazione, atomi: 5, esemplari: 2)
        return ScenarioBattaglia(formato: formato, caratteristica: "campo_aperto",
                                 primoOccupante: primoOccupante, imboscata: imboscata,
                                 deckGiocatore: [fanteria, tiratori],
                                 deckAvversario: [fanteria, tiratori])
    }

    func crea(_ scenario: ScenarioBattaglia) throws -> StatoBattaglia {
        try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
    }

    @discardableResult
    func esegui(_ comando: ComandoBattaglia, _ parte: Parte,
                _ stato: inout StatoBattaglia,
                file: StaticString = #filePath, linea: UInt = #line) -> [EventoBattaglia] {
        let esito = motore.valida(comando, parte: parte, stato: stato)
        XCTAssertTrue(esito.eValido, "comando non valido: \(String(describing: esito.motivo))",
                      file: file, line: linea)
        let (nuovo, eventi) = motore.applica(comando, parte: parte, stato: stato)
        stato = nuovo
        return eventi
    }

    /// Porta la battaglia a uno stato con due fanterie adiacenti a metà campo, pronte all'ingaggio.
    func statoConFronteggiamento() throws -> (StatoBattaglia, IdSciame, IdSciame) {
        var stato = try crea(scenarioOrdinario())
        // Il giocatore piazza una fanteria nella riga 8 (la più avanzata della sua zona).
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 8, colonna: 5)), .giocatore, &stato)
        esegui(.fineTurno, .giocatore, &stato)
        // L'avversario piazza nella riga 3.
        esegui(.seleziona(indiceDeck: 0), .avversario, &stato)
        esegui(.piazza(cella: Cella(riga: 3, colonna: 5)), .avversario, &stato)
        esegui(.fineTurno, .avversario, &stato)
        // Avanzano l'uno verso l'altro fino all'adiacenza (due celle per turno al massimo).
        while stato.griglia.distanza(stato.sciami[IdSciame(1)]!.posizione,
                                     stato.sciami[IdSciame(2)]!.posizione) > 1 {
            let parte = stato.parteDiTurno
            let mio = stato.sciami.values.first { $0.parte == parte }!
            let nemico = stato.sciami.values.first { $0.parte == parte.avversaria }!
            let passo = stato.griglia.vicini(di: mio.posizione)
                .filter { stato.occupante(di: $0) == nil }
                .min { stato.griglia.distanza($0, nemico.posizione) < stato.griglia.distanza($1, nemico.posizione) }!
            if stato.griglia.distanza(passo, nemico.posizione) < stato.griglia.distanza(mio.posizione, nemico.posizione),
               motore.valida(.muovi(sciame: mio.id, percorso: [passo]), parte: parte, stato: stato).eValido {
                esegui(.muovi(sciame: mio.id, percorso: [passo]), parte, &stato)
            }
            esegui(.fineTurno, parte, &stato)
        }
        return (stato, IdSciame(1), IdSciame(2))
    }

    // MARK: - Piazzamento e vincoli di cella

    func test_01_8_2_1_zona_di_piazzamento() throws {
        var stato = try crea(scenarioOrdinario())
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        // La riga 7 è oltre la zona (righe 8, 9, 10 sul formato da dieci): troppo avanzata.
        let fuori = motore.valida(.piazza(cella: Cella(riga: 7, colonna: 5)), parte: .giocatore, stato: stato)
        XCTAssertEqual(fuori.motivo, .troppoAvanzata)
        XCTAssertTrue(motore.valida(.piazza(cella: Cella(riga: 8, colonna: 5)), parte: .giocatore, stato: stato).eValido)
    }

    func test_01_8_9_tre_motivi_di_cella() throws {
        var scenario = scenarioOrdinario()
        scenario = ScenarioBattaglia(formato: scenario.formato, caratteristica: scenario.caratteristica,
                                     ostacoli: [Cella(riga: 9, colonna: 9)],
                                     primoOccupante: .giocatore, imboscata: false,
                                     deckGiocatore: scenario.deckGiocatore,
                                     deckAvversario: scenario.deckAvversario)
        var stato = try crea(scenario)
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 10, colonna: 5)), .giocatore, &stato)
        XCTAssertEqual(motore.valida(.piazza(cella: Cella(riga: 10, colonna: 5)),
                                     parte: .giocatore, stato: stato).motivo, .occupata)
        XCTAssertEqual(motore.valida(.piazza(cella: Cella(riga: 9, colonna: 9)),
                                     parte: .giocatore, stato: stato).motivo, .ostacolo)
        XCTAssertEqual(motore.valida(.piazza(cella: Cella(riga: 7, colonna: 5)),
                                     parte: .giocatore, stato: stato).motivo, .troppoAvanzata)
    }

    func test_01_8_6_il_costo_cresce_con_la_profondita() throws {
        let stato = try crea(scenarioOrdinario())
        let arretrata = motore.costo(archetipo: "fanteria_leggera", atomi: 5,
                                     cella: Cella(riga: 10, colonna: 5), parte: .giocatore, stato: stato)
        let avanzata = motore.costo(archetipo: "fanteria_leggera", atomi: 5,
                                    cella: Cella(riga: 8, colonna: 5), parte: .giocatore, stato: stato)
        XCTAssertGreaterThan(avanzata, arretrata)
        // Il coefficiente alto della macchina rende l'avanzamento molto più caro (01 §8.6).
        let macchinaArretrata = motore.costo(archetipo: "macchina_assedio", atomi: 1,
                                             cella: Cella(riga: 10, colonna: 5), parte: .giocatore, stato: stato)
        let macchinaAvanzata = motore.costo(archetipo: "macchina_assedio", atomi: 1,
                                            cella: Cella(riga: 8, colonna: 5), parte: .giocatore, stato: stato)
        let rapportoFanteria = Double(avanzata) / Double(arretrata)
        let rapportoMacchina = Double(macchinaAvanzata) / Double(macchinaArretrata)
        XCTAssertGreaterThan(rapportoMacchina, rapportoFanteria)
    }

    func test_01_8_4_esaurimento_deseleziona_con_evento() throws {
        var stato = try crea(scenarioOrdinario())
        esegui(.seleziona(indiceDeck: 1), .giocatore, &stato) // tiratori: due esemplari
        esegui(.piazza(cella: Cella(riga: 10, colonna: 1)), .giocatore, &stato)
        let eventi = esegui(.piazza(cella: Cella(riga: 10, colonna: 2)), .giocatore, &stato)
        XCTAssertTrue(eventi.contains { if case .elementoDeckEsaurito = $0 { return true }; return false })
        XCTAssertNil(stato.selezione[.giocatore], "deselezione automatica (01 §8.4)")
    }

    func test_01_8_1_2_il_piazzato_ha_speso_l_azione() throws {
        var stato = try crea(scenarioOrdinario())
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 10, colonna: 5)), .giocatore, &stato)
        let esito = motore.valida(.muovi(sciame: IdSciame(1), percorso: [Cella(riga: 9, colonna: 5)]),
                                  parte: .giocatore, stato: stato)
        XCTAssertEqual(esito.motivo, .azioneGiaSpesa)
    }

    // MARK: - Budget di volume

    func test_01_9_3_1_primo_turno_maggiorato_per_entrambi() throws {
        var stato = try crea(scenarioOrdinario())
        let f = valori.formati["cento"]!
        let atteso = f.coefficientePrimoTurno.applicato(a: f.budgetVolumeBase)
        XCTAssertEqual(stato.bilancio[.giocatore]!.baseTurno, atteso)
        esegui(.fineTurno, .giocatore, &stato)
        XCTAssertEqual(stato.bilancio[.avversario]!.baseTurno, atteso)
        esegui(.fineTurno, .avversario, &stato)
        XCTAssertEqual(stato.bilancio[.giocatore]!.baseTurno, f.budgetVolumeBase,
                       "dal secondo turno la base è ordinaria")
    }

    func test_01_9_3_4_riporto_sul_budget_di_base_non_composto() throws {
        var stato = try crea(scenarioOrdinario())
        let f = valori.formati["cento"]!
        let tetto = f.quotaRiporto.applicato(a: f.budgetVolumeBase)
        // Nessuna spesa: il riporto è il tetto, non tutto il non speso.
        esegui(.fineTurno, .giocatore, &stato)
        esegui(.fineTurno, .avversario, &stato)
        XCTAssertEqual(stato.bilancio[.giocatore]!.riportoEntrante, tetto)
        // Anche non spendendo nulla di nuovo, il riporto resta il tetto: non si compone (01 §9.3.4).
        esegui(.fineTurno, .giocatore, &stato)
        esegui(.fineTurno, .avversario, &stato)
        XCTAssertEqual(stato.bilancio[.giocatore]!.riportoEntrante, tetto)
        XCTAssertEqual(stato.bilancio[.giocatore]!.disponibile, f.budgetVolumeBase + tetto)
    }

    // MARK: - Azione del reparto e movimento

    func test_01_9_5_0_3_spostamento_massimo_due_celle() throws {
        var stato = try crea(scenarioOrdinario())
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 10, colonna: 5)), .giocatore, &stato)
        esegui(.fineTurno, .giocatore, &stato)
        esegui(.fineTurno, .avversario, &stato)
        let tre = [Cella(riga: 9, colonna: 5), Cella(riga: 8, colonna: 5), Cella(riga: 7, colonna: 5)]
        XCTAssertFalse(motore.valida(.muovi(sciame: IdSciame(1), percorso: tre),
                                     parte: .giocatore, stato: stato).eValido)
        // Due celle: valido, con il costo maggiorato del coefficiente (03 §5.3).
        let una = motore.valida(.muovi(sciame: IdSciame(1), percorso: [Cella(riga: 9, colonna: 5)]),
                                parte: .giocatore, stato: stato)
        let due = motore.valida(.muovi(sciame: IdSciame(1),
                                       percorso: [Cella(riga: 9, colonna: 5), Cella(riga: 8, colonna: 5)]),
                                parte: .giocatore, stato: stato)
        XCTAssertGreaterThan(due.costi!.volume, una.costi!.volume)
    }

    // MARK: - Mischia, controllo, disingaggio

    func test_01_9_5_ingaggio_gratuito_e_perdita_di_controllo() throws {
        var (stato, mio, suo) = try statoConFronteggiamento()
        if stato.parteDiTurno != .giocatore { esegui(.fineTurno, stato.parteDiTurno, &stato) }
        let esito = motore.valida(.ingaggia(sciame: mio, bersaglio: suo), parte: .giocatore, stato: stato)
        XCTAssertEqual(esito.costi?.volume, 0, "l'ingaggio è gratuito (01 §9.5.0.1)")
        esegui(.ingaggia(sciame: mio, bersaglio: suo), .giocatore, &stato)
        XCTAssertTrue(stato.impegnato(mio))
        XCTAssertTrue(stato.impegnato(suo))
        // Il reparto impegnato non accetta ordini (01 §9.5).
        let mosso = motore.valida(.muovi(sciame: mio, percorso: [Cella(riga: 9, colonna: 5)]),
                                  parte: .giocatore, stato: stato)
        XCTAssertEqual(mosso.motivo, .impegnato)
    }

    func test_01_9_7_1_mischia_risolta_a_inizio_giro_con_evento_aggregato() throws {
        var (stato, mio, suo) = try statoConFronteggiamento()
        if stato.parteDiTurno != .giocatore { esegui(.fineTurno, stato.parteDiTurno, &stato) }
        esegui(.ingaggia(sciame: mio, bersaglio: suo), .giocatore, &stato)
        let serbatoioPrima = stato.sciami[mio]!.serbatoio
        esegui(.fineTurno, .giocatore, &stato) // turno avversario: nessuna risoluzione
        XCTAssertEqual(stato.sciami[mio]!.serbatoio, serbatoioPrima)
        let eventi = esegui(.fineTurno, .avversario, &stato) // nuovo giro: mischia risolta
        let aggregato = eventi.contains { if case .esitoMischiaComplessivo(let esiti) = $0 {
            return !esiti.isEmpty }; return false }
        XCTAssertTrue(aggregato, "un solo evento aggregato (01 §9.7.1, 05 §3.9)")
        XCTAssertLessThan(stato.sciami[mio]?.serbatoio ?? 0, serbatoioPrima, "perdite reciproche (01 §9.7)")
    }

    func test_01_9_8_disingaggio_a_soglia_con_ritrazione_e_divieto() throws {
        // La fanteria leggera ha soglia bassa: dopo abbastanza giri si disingaggia.
        var (stato, mio, suo) = try statoConFronteggiamento()
        if stato.parteDiTurno != .giocatore { esegui(.fineTurno, stato.parteDiTurno, &stato) }
        esegui(.ingaggia(sciame: mio, bersaglio: suo), .giocatore, &stato)
        var disingaggi: [EventoBattaglia] = []
        var giri = 0
        while disingaggi.isEmpty && giri < 60 && stato.esito == nil {
            let eventi = esegui(.fineTurno, stato.parteDiTurno, &stato)
            disingaggi = eventi.filter { if case .disingaggio = $0 { return true }; return false }
            giri += 1
        }
        guard case .disingaggio(let chi, let da, let a)? = disingaggi.first else {
            return XCTFail("nessun disingaggio entro \(giri) giri")
        }
        // Ritrazione di una cella verso le proprie retrovie (01 §9.8.2).
        XCTAssertEqual(stato.griglia.distanza(da, a), 1)
        XCTAssertFalse(stato.impegnato(chi), "il contatto è finito")
        // Nessun nuovo ingaggio della coppia in questo giro (01 §9.8.2).
        let sciameStaccato = stato.sciami[chi]!
        let altroId = chi == mio ? suo : mio
        if stato.parteDiTurno == sciameStaccato.parte,
           stato.griglia.distanza(stato.sciami[chi]!.posizione, stato.sciami[altroId]!.posizione) == 1 {
            let esito = motore.valida(.ingaggia(sciame: chi, bersaglio: altroId),
                                      parte: sciameStaccato.parte, stato: stato)
            XCTAssertFalse(esito.eValido)
        }
        // La coppia è ricordata: al nuovo contatto niente soglia (01 §9.8.3).
        XCTAssertTrue(stato.coppieStaccate.contains(Coppia(mio, suo)))
    }

    // MARK: - Offesa, protezione, tiro

    func test_01_9_9_efficacia_graduata_mai_nulla() throws {
        // Il proiettile è proprietà fissa del reparto (01 §3.3.1, versione 3.3).
        let leggero = valori.archetipi["tiratori"]!.offesaTiro!
        let bene = motore.efficacia(offesa: leggero, protezione: valori.protezioni[.antiPerforazione]!)
        let male = motore.efficacia(offesa: leggero, protezione: valori.protezioni[.antiSaturazione]!)
        XCTAssertGreaterThan(bene, male, "le due protezioni rispondono in modo opposto (01 §3.3.2)")
        XCTAssertGreaterThanOrEqual(male, valori.combattimento.efficaciaMinima,
                                    "la munizione poco adatta non è mai inefficace (01 §9.9)")
        XCTAssertEqual(motore.efficaciaQualitativa(offesa: leggero,
                                                   protezione: valori.protezioni[.antiSaturazione]!),
                       .pocoEfficace, "annuncio qualitativo (01 §9.9.1)")
    }

    func test_01_3_4_1_gittata_unica_resa_piena_dentro_niente_fuori() throws {
        var stato = try crea(scenarioOrdinario())
        // Tiratori del giocatore in riga 8; bersaglio avversario al limite della gittata.
        esegui(.seleziona(indiceDeck: 1), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 8, colonna: 5)), .giocatore, &stato)
        esegui(.fineTurno, .giocatore, &stato)
        esegui(.seleziona(indiceDeck: 0), .avversario, &stato)
        esegui(.piazza(cella: Cella(riga: 2, colonna: 5)), .avversario, &stato) // distanza 6: limite gittata
        esegui(.fineTurno, .avversario, &stato)

        let tiratore = IdSciame(1)
        let vicino = IdSciame(2)
        // Dentro la gittata unica la resa è piena: il danno è quello della formula, non una frazione.
        let a = valori.archetipi["tiratori"]!
        XCTAssertEqual(stato.griglia.distanza(stato.sciami[tiratore]!.posizione,
                                              stato.sciami[vicino]!.posizione), a.gittata,
                       "il bersaglio è al limite esatto della gittata unica")
        let atomiPrima = stato.sciami[tiratore]!.atomiPresenti(puntiVitaPerAtomo: a.puntiVitaPerAtomo, minimo: 1)
        let (_, eventi) = motore.applica(.tira(sciame: tiratore, bersaglio: vicino),
                                         parte: .giocatore, stato: stato)
        guard case .tiroEseguito(_, _, _, _, _, let dannoInflitto, _, _)? =
                eventi.first(where: { if case .tiroEseguito = $0 { return true }; return false }) else {
            return XCTFail("nessun tiro eseguito")
        }
        // Una sola gittata e disponibilità binaria (01 §3.4.1); la resa però non è
        // unica lungo la gittata (01 §3.4.1.1): al limite vale quella dichiarata nei
        // dati, che dopo la taratura della fase C è ridotta perché il tiro lontano
        // disturbi e quello vicino uccida (01 §9.10.1).
        let eff = motore.efficacia(offesa: a.offesaTiro!,
                                   protezione: valori.protezioni[.antiSaturazione]!)
        let alLimite = max(valori.minimi.dannoMinimo,
                           (eff * valori.combattimento.resaTiroAlLimite)
                               .applicato(a: a.capacitaOffensivaPerAtomo * atomiPrima))
        XCTAssertEqual(dannoInflitto, alLimite,
                       "al limite della gittata vale la resa dichiarata (01 §9.10.1)")
        // Fuori portata: non valido con il motivo chiuso. Disponibilità binaria.
        var statoLontano = stato
        statoLontano.sciami[vicino]!.posizione = Cella(riga: 1, colonna: 1)
        let esito = motore.valida(.tira(sciame: tiratore, bersaglio: vicino),
                                  parte: .giocatore, stato: statoLontano)
        XCTAssertEqual(esito.motivo, .fuoriTiro)
    }

    func test_01_9_6_1_munizioni_esaurite_reparto_resta_e_non_tira() throws {
        var stato = try crea(scenarioOrdinario())
        esegui(.seleziona(indiceDeck: 1), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 8, colonna: 5)), .giocatore, &stato)
        esegui(.fineTurno, .giocatore, &stato)
        esegui(.seleziona(indiceDeck: 0), .avversario, &stato)
        esegui(.piazza(cella: Cella(riga: 3, colonna: 5)), .avversario, &stato)
        esegui(.fineTurno, .avversario, &stato)
        let tiratore = IdSciame(1), bersaglio = IdSciame(2)
        let dotazione = valori.archetipi["tiratori"]!.dotazioneMunizioni
        var esaurite = false
        for _ in 0..<dotazione {
            let eventi = esegui(.tira(sciame: tiratore, bersaglio: bersaglio), .giocatore, &stato)
            esaurite = esaurite || eventi.contains { if case .munizioniEsaurite = $0 { return true }; return false }
            if stato.esito != nil || stato.sciami[bersaglio] == nil { return } // il bersaglio può cadere prima
            esegui(.fineTurno, .giocatore, &stato)
            esegui(.fineTurno, .avversario, &stato)
        }
        XCTAssertTrue(esaurite, "l'esaurimento è un evento (05 §3.7)")
        let esito = motore.valida(.tira(sciame: tiratore, bersaglio: bersaglio),
                                  parte: .giocatore, stato: stato)
        XCTAssertEqual(esito.motivo, .munizioniEsaurite)
        XCTAssertNotNil(stato.sciami[tiratore], "il reparto resta in campo (01 §9.6.1)")
        XCTAssertTrue(motore.valida(.muovi(sciame: tiratore, percorso: [Cella(riga: 9, colonna: 5)]),
                                    parte: .giocatore, stato: stato).eValido,
                      "conserva l'azione: può muoversi (01 §9.6.1)")
    }

    // MARK: - Atomi, troncamento, minimi

    func test_01_4_3_atomi_per_troncamento_con_minimo_di_uno() throws {
        let archetipo = valori.archetipi["fanteria_leggera"]!
        var sciame = Sciame(id: IdSciame(9), parte: .giocatore, archetipo: "fanteria_leggera",
                            protezione: .antiSaturazione, lettera: 1, atomiIniziali: 5,
                            serbatoio: 5 * archetipo.puntiVitaPerAtomo, munizioni: 0,
                            posizione: Cella(riga: 10, colonna: 1), azioneSpesa: false, rinforzo: false)
        XCTAssertEqual(sciame.atomiPresenti(puntiVitaPerAtomo: archetipo.puntiVitaPerAtomo, minimo: 1), 5)
        sciame.serbatoio = archetipo.puntiVitaPerAtomo * 2 - 1 // troncamento per difetto: 1,99... -> 1
        XCTAssertEqual(sciame.atomiPresenti(puntiVitaPerAtomo: archetipo.puntiVitaPerAtomo, minimo: 1), 1)
        sciame.serbatoio = 1 // vivo con meno di un atomo di punti vita: minimo di uno (01 §4.3)
        XCTAssertEqual(sciame.atomiPresenti(puntiVitaPerAtomo: archetipo.puntiVitaPerAtomo, minimo: 1), 1)
        sciame.serbatoio = 0
        XCTAssertEqual(sciame.atomiPresenti(puntiVitaPerAtomo: archetipo.puntiVitaPerAtomo, minimo: 1), 0)
    }

    // MARK: - Resa e ritirata combattuta

    func test_01_10_resa_ritirata_e_sconfitto_chi_dichiara() throws {
        var stato = try crea(scenarioOrdinario())
        let f = valori.formati["cento"]!
        // La resa non è disponibile prima della soglia (01 §10.2).
        XCTAssertEqual(motore.valida(.dichiaraResa, parte: .giocatore, stato: stato).motivo,
                       .resaNonDisponibile)
        // Schieramenti minimi e giri a vuoto fino alla soglia.
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 10, colonna: 5)), .giocatore, &stato)
        esegui(.fineTurno, .giocatore, &stato)
        esegui(.seleziona(indiceDeck: 0), .avversario, &stato)
        esegui(.piazza(cella: Cella(riga: 1, colonna: 5)), .avversario, &stato)
        esegui(.fineTurno, .avversario, &stato)
        while stato.giro < f.sogliaMinimaResaTurni {
            esegui(.fineTurno, stato.parteDiTurno, &stato)
        }
        if stato.parteDiTurno != .giocatore { esegui(.fineTurno, .avversario, &stato) }
        esegui(.dichiaraResa, .giocatore, &stato)
        XCTAssertEqual(stato.resaDichiarataDa, .giocatore)
        // Un'unità non impegnata si può evacuare, con costo dalla riga di partenza (01 §10.4, §8.7).
        let esitoRitiro = motore.valida(.ritiraUnita(sciame: IdSciame(1)), parte: .giocatore, stato: stato)
        XCTAssertTrue(esitoRitiro.eValido)
        esegui(.ritiraUnita(sciame: IdSciame(1)), .giocatore, &stato)
        XCTAssertEqual(stato.evacuati[.giocatore], [IdSciame(1)])
        // Il ritirante non ha più nulla in campo: la battaglia si conclude, sconfitto chi ha dichiarato
        // (01 §10.3, §15.2.2).
        XCTAssertEqual(stato.esito?.sconfitto, .giocatore)
        XCTAssertEqual(stato.esito?.modo, .ritirataCompiuta)
    }

    // MARK: - Conclusione durante la ritirata combattuta (01 §15.2.3, P8)

    /// Difetto trovato dal programma di verifica della fase C. Il ritirante che
    /// evacua TUTTO e non ha più riserve resta senza nulla in campo e senza nulla
    /// nel mazzo: la condizione di annientamento risultava allora vera e la
    /// battaglia si chiudeva come annientamento, mentre 01 §15.2.3 riserva quel
    /// modo al caso in cui «nessuno dei due si ritira». Una ritirata riuscita
    /// veniva quindi raccontata al giocatore come una disfatta.
    func test_01_15_2_3_la_ritirata_riuscita_non_e_un_annientamento() throws {
        var stato = try crea(scenarioOrdinario())
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 10, colonna: 5)), .giocatore, &stato)
        esegui(.fineTurno, .giocatore, &stato)
        esegui(.seleziona(indiceDeck: 0), .avversario, &stato)
        esegui(.piazza(cella: Cella(riga: 1, colonna: 5)), .avversario, &stato)
        esegui(.fineTurno, .avversario, &stato)
        // Il mazzo del giocatore si svuota: resta soltanto ciò che è in campo.
        stato.deck[.giocatore] = []
        while stato.giro < valori.formati["cento"]!.sogliaMinimaResaTurni {
            esegui(.fineTurno, stato.parteDiTurno, &stato)
        }
        if stato.parteDiTurno != .giocatore { esegui(.fineTurno, .avversario, &stato) }
        esegui(.dichiaraResa, .giocatore, &stato)
        esegui(.ritiraUnita(sciame: IdSciame(1)), .giocatore, &stato)

        XCTAssertEqual(stato.evacuati[.giocatore]?.count, 1, "l'unità è stata salvata, non perduta")
        XCTAssertEqual(stato.esito?.modo, .ritirataCompiuta,
                       "chi si ritira compie la ritirata: l'annientamento vale se nessuno si ritira")
        XCTAssertEqual(stato.esito?.sconfitto, .giocatore, "sconfitto è chi dichiara (01 §15.2.2)")
    }

    /// Anche quando è l'AVANZANTE a restare senza nulla durante la ritirata, lo
    /// scontro si chiude come ritirata compiuta e lo sconfitto resta chi si è
    /// ritirato (01 §15.2.2). Caso non normato dai consolidati: precisazione P8.
    func test_01_15_2_2_se_l_avanzante_si_esaurisce_lo_sconfitto_resta_il_ritirante() throws {
        var stato = try crea(scenarioOrdinario())
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 10, colonna: 5)), .giocatore, &stato)
        esegui(.fineTurno, .giocatore, &stato)
        esegui(.seleziona(indiceDeck: 0), .avversario, &stato)
        esegui(.piazza(cella: Cella(riga: 1, colonna: 5)), .avversario, &stato)
        esegui(.fineTurno, .avversario, &stato)
        while stato.giro < valori.formati["cento"]!.sogliaMinimaResaTurni {
            esegui(.fineTurno, stato.parteDiTurno, &stato)
        }
        if stato.parteDiTurno != .giocatore { esegui(.fineTurno, .avversario, &stato) }
        esegui(.dichiaraResa, .giocatore, &stato)
        // L'avanzante sparisce dal campo e dal mazzo mentre la ritirata è in corso.
        stato.sciami[IdSciame(2)] = nil
        stato.deck[.avversario] = []
        esegui(.fineTurno, .giocatore, &stato)

        XCTAssertEqual(stato.esito?.modo, .ritirataCompiuta)
        XCTAssertEqual(stato.esito?.sconfitto, .giocatore,
                       "si può perdere avendo inflitto più danni: sconfitto è chi si ritira")
    }

    // MARK: - Imboscata

    func test_01_9_3_2_imboscata_turni_di_vantaggio_sconto_e_opacita() throws {
        var stato = try crea(scenarioOrdinario(imboscata: true, primoOccupante: .avversario))
        let f = valori.formati["cento"]!
        // L'imboscante agisce per primo (01 §9.4.1) con i turni di vantaggio (01 §9.3.2).
        XCTAssertEqual(stato.parteDiTurno, .avversario)
        XCTAssertEqual(stato.sorpresa, .vantaggio(restanti: f.turniVantaggioImboscante))
        // Lo sconto si applica ai suoi piazzamenti (01 §9.3.6).
        esegui(.seleziona(indiceDeck: 0), .avversario, &stato)
        let cella = Cella(riga: 2, colonna: 5)
        let costoScontato = motore.valida(.piazza(cella: cella), parte: .avversario, stato: stato).costi!.volume
        let costoPieno = motore.costo(archetipo: "fanteria_leggera", atomi: 5, cella: cella,
                                      parte: .avversario, stato: stato)
        XCTAssertLessThan(costoScontato, costoPieno)
        esegui(.piazza(cella: cella), .avversario, &stato)
        // I turni di vantaggio sono turni di battaglia a tutti gli effetti (01 §8.1.3).
        for _ in 1..<f.turniVantaggioImboscante {
            esegui(.fineTurno, .avversario, &stato)
            XCTAssertEqual(stato.parteDiTurno, .avversario)
        }
        esegui(.fineTurno, .avversario, &stato)
        // Ora il turno opaco di chi subisce: non vede nulla dell'avversario (01 §9.3.2.1).
        XCTAssertEqual(stato.parteDiTurno, .giocatore)
        XCTAssertEqual(stato.sorpresa, .opacita)
        let vista = VistaBattaglia(motore: motore, stato: stato, parte: .giocatore)
        XCTAssertNil(vista.occupanteVisibile(di: cella), "l'imboscante è nascosto")
        XCTAssertNotNil(stato.occupante(di: cella), "ma esiste nello stato")
        let eventi = esegui(.fineTurno, .giocatore, &stato)
        // Dal turno successivo dell'imboscante tutto è scoperto (01 §9.3.2.1).
        XCTAssertTrue(eventi.contains { if case .sorpresaConclusa = $0 { return true }; return false })
        XCTAssertEqual(stato.sorpresa, .trasparente)
        let vistaDopo = VistaBattaglia(motore: motore, stato: stato, parte: .giocatore)
        XCTAssertNotNil(vistaDopo.occupanteVisibile(di: cella))
    }

    // MARK: - Base delle perdite: le sole forze impiegate (01 §10.2, revisione del titolare)

    func test_01_10_2_la_soglia_si_accorcia_sulle_forze_impiegate() throws {
        var stato = try crea(scenarioOrdinario())
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 10, colonna: 5)), .giocatore, &stato)
        // Impiegate: un solo sciame, 5 atomi per 100 punti vita.
        XCTAssertEqual(stato.forzeImpegnate[.giocatore], 500)
        // Metà delle forze impiegate perdute: riduzione 0,5 × 0,5 = 0,25; soglia 4 → 3.
        stato.perditeSubite[.giocatore] = 250
        XCTAssertEqual(motore.sogliaResaEffettiva(per: .giocatore, stato: stato), 3)
        // Tutto il piazzato perduto: riduzione 0,5; soglia 4 → 2.
        stato.perditeSubite[.giocatore] = 500
        XCTAssertEqual(motore.sogliaResaEffettiva(per: .giocatore, stato: stato), 2)
    }

    func test_01_10_2_le_riserve_nel_deck_non_trattengono_la_resa() throws {
        var stato = try crea(scenarioOrdinario())
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 10, colonna: 5)), .giocatore, &stato)
        stato.perditeSubite[.giocatore] = 500 // perso tutto ciò che era in campo
        // Sulla base delle sole forze impiegate la soglia scende a 2. Con la base
        // precedente (l'intero mazzo: 2300 punti vita) la proporzione sarebbe stata
        // 500/2300 e la soglia sarebbe rimasta 3: la riserva avrebbe trattenuto la resa.
        XCTAssertEqual(motore.sogliaResaEffettiva(per: .giocatore, stato: stato), 2,
                       "chi ha impegnato poco e perso quel poco deve poter concludere presto")
        XCTAssertEqual(motore.proporzionePerdite(per: .giocatore, stato: stato), .uno)
    }

    func test_01_10_2_piazzare_altro_accresce_la_base_e_riallunga_la_soglia() throws {
        var stato = try crea(scenarioOrdinario())
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 10, colonna: 5)), .giocatore, &stato)
        stato.perditeSubite[.giocatore] = 500
        XCTAssertEqual(motore.sogliaResaEffettiva(per: .giocatore, stato: stato), 2)
        // Chi sceglie di impegnare altro accresce la base: la proporzione scende
        // e la soglia si riallunga. Vale identicamente per i rinforzi futuri,
        // che entrano nella base quando scendono in campo.
        esegui(.piazza(cella: Cella(riga: 10, colonna: 6)), .giocatore, &stato)
        XCTAssertEqual(stato.forzeImpegnate[.giocatore], 1000)
        XCTAssertEqual(motore.sogliaResaEffettiva(per: .giocatore, stato: stato), 3)
        // Prima di qualunque piazzamento la proporzione è zero per definizione.
        let vergine = try crea(scenarioOrdinario())
        XCTAssertEqual(motore.proporzionePerdite(per: .giocatore, stato: vergine), .zero)
    }

    // MARK: - Nessun fuoco amico (01 §9.6.2, revisione del titolare)

    func test_01_9_6_2_nessun_fuoco_amico() throws {
        var (stato, mio, suo) = try statoConFronteggiamento()
        if stato.parteDiTurno != .giocatore { esegui(.fineTurno, stato.parteDiTurno, &stato) }
        esegui(.ingaggia(sciame: mio, bersaglio: suo), .giocatore, &stato)

        // Un tiratore proprio entro gittata del nemico impegnato.
        esegui(.seleziona(indiceDeck: 1), .giocatore, &stato)
        let posNemico = stato.sciami[suo]!.posizione
        let cellaTiratore = stato.griglia.tutteLeCelle.first { cella in
            motore.valida(.piazza(cella: cella), parte: .giocatore, stato: stato).eValido
                && stato.griglia.distanza(cella, posNemico) <= valori.archetipi["tiratori"]!.gittata
        }
        let tiratore = IdSciame(stato.prossimoIdSciame)
        esegui(.piazza(cella: try XCTUnwrap(cellaTiratore)), .giocatore, &stato)
        esegui(.fineTurno, .giocatore, &stato)
        esegui(.fineTurno, .avversario, &stato) // il giro nuovo risolve una mischia

        // Il proprio reparto non è mai un bersaglio, né di tiro né di ingaggio.
        XCTAssertEqual(motore.valida(.tira(sciame: tiratore, bersaglio: mio),
                                     parte: .giocatore, stato: stato).motivo, .bersaglioNonValido)
        XCTAssertFalse(motore.valida(.ingaggia(sciame: tiratore, bersaglio: mio),
                                     parte: .giocatore, stato: stato).eValido)

        // Battere un nemico impegnato in mischia con i propri è lecito e senza
        // alcun rischio per i propri: il danno cade soltanto sul bersaglio.
        XCTAssertTrue(stato.impegnato(suo))
        let serbatoioMioPrima = stato.sciami[mio]!.serbatoio
        let perditeMiePrima = stato.perditeSubite[.giocatore] ?? 0
        let perditeSuePrima = stato.perditeSubite[.avversario] ?? 0
        esegui(.tira(sciame: tiratore, bersaglio: suo), .giocatore, &stato)
        XCTAssertEqual(stato.sciami[mio]?.serbatoio, serbatoioMioPrima)
        XCTAssertEqual(stato.perditeSubite[.giocatore] ?? 0, perditeMiePrima)
        XCTAssertGreaterThan(stato.perditeSubite[.avversario] ?? 0, perditeSuePrima)
    }


    // MARK: - Lettere dei reparti (01 §9.4.3, versione 3.3)

    func test_01_9_4_3_lettere_in_ordine_di_piazzamento_mai_riusate() throws {
        var stato = try crea(scenarioOrdinario())
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 10, colonna: 1)), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 10, colonna: 2)), .giocatore, &stato)
        esegui(.fineTurno, .giocatore, &stato)
        esegui(.seleziona(indiceDeck: 0), .avversario, &stato)
        esegui(.piazza(cella: Cella(riga: 1, colonna: 1)), .avversario, &stato)
        esegui(.fineTurno, .avversario, &stato)

        // Ordine di piazzamento dentro ciascuno schieramento: A e B del giocatore,
        // A avversaria distinta dalla parte, non dalla lettera.
        XCTAssertEqual(stato.sciami[IdSciame(1)]?.lettera, 1)
        XCTAssertEqual(stato.sciami[IdSciame(2)]?.lettera, 2)
        XCTAssertEqual(stato.sciami[IdSciame(3)]?.lettera, 1)
        XCTAssertEqual(stato.sciami[IdSciame(3)]?.parte, .avversario)

        // Un reparto esce dal campo: la sua lettera non si riusa, per nessuna ragione.
        stato.sciami[IdSciame(2)] = nil // uscita simulata dal campo
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 10, colonna: 3)), .giocatore, &stato)
        let nuovo = stato.sciami.values.first { $0.parte == .giocatore && $0.posizione == Cella(riga: 10, colonna: 3) }
        XCTAssertEqual(nuovo?.lettera, 3, "chi ha imparato che B era un reparto deve potersene fidare (01 §9.4.3)")
    }

    // MARK: - Fasce descrittive degli esiti (01 §9.7.2, 03 §5.14)

    func test_01_9_7_2_fasce_con_soglie_deterministiche_dai_valori() throws {
        let stato = try crea(scenarioOrdinario())
        _ = stato
        // Le soglie di fabbrica: lievi fino al 10 per cento, significative fino al 30.
        XCTAssertEqual(motore.fascia(danno: 0, consistenzaPrima: 500), .nessuna)
        XCTAssertEqual(motore.fascia(danno: 50, consistenzaPrima: 500), .lievi)
        XCTAssertEqual(motore.fascia(danno: 51, consistenzaPrima: 500), .significative)
        XCTAssertEqual(motore.fascia(danno: 150, consistenzaPrima: 500), .significative)
        XCTAssertEqual(motore.fascia(danno: 151, consistenzaPrima: 500), .gravi)
        XCTAssertEqual(motore.fascia(danno: 500, consistenzaPrima: 500), .gravi)
    }

    func test_01_9_7_2_gli_esiti_di_mischia_portano_le_fasce() throws {
        var (stato, mio, suo) = try statoConFronteggiamento()
        if stato.parteDiTurno != .giocatore { esegui(.fineTurno, stato.parteDiTurno, &stato) }
        esegui(.ingaggia(sciame: mio, bersaglio: suo), .giocatore, &stato)
        esegui(.fineTurno, .giocatore, &stato)
        let eventi = esegui(.fineTurno, .avversario, &stato) // il giro nuovo risolve la mischia
        guard case .esitoMischiaComplessivo(let esiti)? =
                eventi.first(where: { if case .esitoMischiaComplessivo = $0 { return true }; return false }),
              let contatto = esiti.first else {
            return XCTFail("nessun esito di mischia")
        }
        XCTAssertNotEqual(contatto.fasciaAlPrimo, .nessuna, "la mischia continua infligge perdite (01 §9.7)")
        XCTAssertNotEqual(contatto.fasciaAlSecondo, .nessuna)
    }

    // MARK: - Nessuna azione impossibile offerta (02 §9.5)

    func test_02_9_5_nessuna_destinazione_quando_il_reparto_e_circondato() throws {
        var stato = try crea(scenarioOrdinario())
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        // L'angolo (10,1) ha tre vicini: (10,2), (9,1), (9,2). Occupati tutti,
        // non esiste destinazione, nemmeno a due celle (le intermedie sono piene).
        esegui(.piazza(cella: Cella(riga: 10, colonna: 1)), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 10, colonna: 2)), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 9, colonna: 1)), .giocatore, &stato)
        esegui(.seleziona(indiceDeck: 1), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 9, colonna: 2)), .giocatore, &stato)
        esegui(.fineTurno, .giocatore, &stato)
        esegui(.fineTurno, .avversario, &stato)

        let vista = VistaBattaglia(motore: motore, stato: stato, parte: .giocatore)
        let angolo = stato.occupante(di: Cella(riga: 10, colonna: 1))!
        XCTAssertFalse(angolo.azioneSpesa, "al turno nuovo l\u{2019}azione è tornata")
        XCTAssertFalse(vista.esisteDestinazione(per: angolo.id),
                       "nessuna destinazione raggiungibile: l\u{2019}azione non va offerta (02 §9.5)")
        let libero = stato.occupante(di: Cella(riga: 9, colonna: 2))!
        XCTAssertTrue(vista.esisteDestinazione(per: libero.id),
                      "chi ha destinazioni conserva l\u{2019}azione di spostamento")
    }

    // MARK: - Determinismo

    func test_00_3_1_determinismo_stessa_sequenza_stessa_impronta() throws {
        func partita() throws -> String {
            var stato = try crea(scenarioOrdinario())
            esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
            esegui(.piazza(cella: Cella(riga: 9, colonna: 4)), .giocatore, &stato)
            esegui(.piazza(cella: Cella(riga: 9, colonna: 5)), .giocatore, &stato)
            esegui(.fineTurno, .giocatore, &stato)
            esegui(.seleziona(indiceDeck: 1), .avversario, &stato)
            esegui(.piazza(cella: Cella(riga: 2, colonna: 5)), .avversario, &stato)
            esegui(.fineTurno, .avversario, &stato)
            return stato.impronta()
        }
        XCTAssertEqual(try partita(), try partita())
    }
}
