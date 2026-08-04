import XCTest
import Motore
import Dati
import Contenuti

/// I due modificatori introdotti dopo l'accertamento: la vicinanza per il tiro
/// (01 §9.10.1) e l'accerchiamento (01 §9.10.2). Ogni prova cita per numero la
/// regola che verifica e misura sul danno che i comandi producono davvero.
final class ModificatoriDiScontroTest: XCTestCase {

    var valori: ValoriDiGioco!
    var motore: MotoreBattaglia!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreBattaglia(valori: valori)
    }

    // MARK: - Attrezzi

    struct Posto {
        let parte: Parte
        let archetipo: IdentificatoreDati
        let protezione: TipoProtezione
        let cella: Cella
    }

    func campo(_ posti: [Posto], parteDiTurno: Parte = .giocatore) throws -> (StatoBattaglia, [IdSciame]) {
        let riserva = ScenarioBattaglia.ElementoScenario(
            archetipo: "fanteria_leggera", protezione: .antiSaturazione, atomi: 5, esemplari: 1)
        let scenario = ScenarioBattaglia(formato: "cento", caratteristica: "campo_aperto",
                                         primoOccupante: parteDiTurno, imboscata: false,
                                         deckGiocatore: [riserva], deckAvversario: [riserva])
        var stato = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
        var ids: [IdSciame] = []
        for posto in posti {
            let id = IdSciame(stato.prossimoIdSciame)
            stato.prossimoIdSciame += 1
            let lettera = stato.prossimaLettera[posto.parte] ?? 1
            stato.prossimaLettera[posto.parte] = lettera + 1
            let a = valori.archetipi[posto.archetipo]!
            stato.sciami[id] = Sciame(id: id, parte: posto.parte, archetipo: posto.archetipo,
                                      protezione: posto.protezione, lettera: lettera,
                                      atomiIniziali: 5, serbatoio: 5 * a.puntiVitaPerAtomo,
                                      munizioni: a.dotazioneMunizioni, posizione: posto.cella,
                                      azioneSpesa: false, rinforzo: false)
            stato.forzeImpegnate[posto.parte, default: 0] += 5 * a.puntiVitaPerAtomo
            ids.append(id)
        }
        return (stato, ids)
    }

    func dannoDelTiro(_ tiratore: IdSciame, _ bersaglio: IdSciame,
                      parte: Parte, stato: StatoBattaglia,
                      file: StaticString = #filePath, linea: UInt = #line) -> Int64 {
        let comando = ComandoBattaglia.tira(sciame: tiratore, bersaglio: bersaglio)
        XCTAssertTrue(motore.valida(comando, parte: parte, stato: stato).eValido,
                      "tiro non ammissibile", file: file, line: linea)
        for evento in motore.applica(comando, parte: parte, stato: stato).1 {
            if case .tiroEseguito(_, _, _, _, _, let danno, _, _) = evento { return danno }
        }
        XCTFail("nessun evento di tiro", file: file, line: linea)
        return 0
    }

    /// Il danno subito da ciascuno in un giro di mischia risolto davvero.
    func dannoDelleMischie(_ stato: StatoBattaglia) -> [IdSciame: Int64] {
        var lavoro = stato
        let prima = lavoro.sciami.mapValues(\.serbatoio)
        for _ in 0..<2 {
            lavoro = motore.applica(.fineTurno, parte: lavoro.parteDiTurno, stato: lavoro).0
        }
        return prima.mapValues { $0 }.reduce(into: [:]) { esito, voce in
            esito[voce.key] = voce.value - (lavoro.sciami[voce.key]?.serbatoio ?? 0)
        }
    }

    // MARK: - Vicinanza per il tiro (01 §9.10.1)

    /// Il danno del tiro cresce al calare della distanza, per OGNI reparto da tiro,
    /// misurato sul comando applicato davvero a ciascuna distanza della sua gittata.
    func test_01_9_10_1_il_danno_del_tiro_cresce_al_calare_della_distanza() throws {
        var reparti = 0
        for (identificatore, archetipo) in valori.archetipi.sorted(by: { $0.key < $1.key }) {
            guard archetipo.offesaTiro != nil else { continue }
            reparti += 1
            var precedente: Int64 = 0
            // Dalla gittata massima fino al contatto, sulla stessa colonna.
            for distanza in stride(from: archetipo.gittata, through: 1, by: -1) {
                let (stato, ids) = try campo([
                    Posto(parte: .giocatore, archetipo: identificatore,
                          protezione: .antiSaturazione, cella: Cella(riga: 9, colonna: 5)),
                    Posto(parte: .avversario, archetipo: "fanteria_pesante",
                          protezione: .antiSaturazione, cella: Cella(riga: 9 - distanza, colonna: 5)),
                ])
                XCTAssertEqual(stato.griglia.distanza(stato.sciami[ids[0]]!.posizione,
                                                      stato.sciami[ids[1]]!.posizione), distanza)
                let inflitto = dannoDelTiro(ids[0], ids[1], parte: .giocatore, stato: stato)
                XCTAssertGreaterThan(inflitto, precedente,
                                     "\(identificatore) a distanza \(distanza): il tiro deve rendere di più")
                precedente = inflitto
            }
        }
        XCTAssertGreaterThan(reparti, 1, "la prova copre più di un reparto da tiro")
    }

    /// Al limite della gittata la maggiorazione è nulla: il modificatore accresce
    /// alla minima distanza e non riduce mai il tiro lontano.
    func test_01_9_10_1_al_limite_della_gittata_nessuna_maggiorazione() throws {
        for (identificatore, archetipo) in valori.archetipi.sorted(by: { $0.key < $1.key }) {
            guard archetipo.gittata > 0 else { continue }
            // Al limite della gittata la resa è quella dichiarata nei dati, ridotta:
            // il tiro lontano disturba (01 §9.10.1, taratura della fase C).
            XCTAssertEqual(motore.coefficienteVicinanza(distanza: archetipo.gittata,
                                                        gittata: archetipo.gittata),
                           valori.combattimento.resaTiroAlLimite,
                           "\(identificatore): al limite vale la resa dichiarata")
            XCTAssertLessThan(valori.combattimento.resaTiroAlLimite, .uno,
                              "il tiro al limite rende meno dell'accoppiamento nudo")
            XCTAssertEqual(motore.prossimita(distanza: archetipo.gittata, gittata: archetipo.gittata), .zero)
            XCTAssertEqual(motore.prossimita(distanza: 1, gittata: archetipo.gittata), .uno)
            // Alla minima distanza vale esattamente l'altro estremo dei dati (00 §13.1).
            XCTAssertEqual(motore.coefficienteVicinanza(distanza: 1, gittata: archetipo.gittata),
                           valori.combattimento.resaTiroAllaMinimaDistanza)
        }
    }

    /// La fascia annunciata percorre tutti e tre i termini lungo la gittata, e non
    /// annuncia mai una cifra: il giocatore decide sulla fascia (01 §9.10.1, 02 §4.4.5).
    func test_01_9_10_1_la_fascia_percorre_i_tre_termini_lungo_la_gittata() throws {
        let gittata = valori.archetipi["tiratori"]!.gittata
        var fasce: [FasciaVicinanza] = []
        for distanza in stride(from: gittata, through: 1, by: -1) {
            fasce.append(motore.fasciaVicinanza(distanza: distanza, gittata: gittata))
        }
        XCTAssertEqual(fasce.first, .lontano, "al limite della gittata il bersaglio è a distanza")
        XCTAssertEqual(fasce.last, .aRidosso, "alla minima distanza è a ridosso")
        XCTAssertEqual(Set(fasce).count, FasciaVicinanza.allCases.count,
                       "tutte e tre le fasce sono raggiungibili: \(fasce)")
        // Le fasce non tornano mai indietro avvicinandosi.
        let ordine: [FasciaVicinanza: Int] = [.lontano: 0, .ravvicinato: 1, .aRidosso: 2]
        for coppia in zip(fasce, fasce.dropFirst()) {
            XCTAssertLessThanOrEqual(ordine[coppia.0]!, ordine[coppia.1]!)
        }
    }

    /// La vicinanza vale per entrambe le parti (01 §9.10): premia chi ha l'iniziativa
    /// di avvicinarsi, chiunque egli sia.
    func test_01_9_10_1_la_vicinanza_vale_per_entrambe_le_parti() throws {
        func danno(tiratoreDi parte: Parte, distanza: Int) throws -> Int64 {
            let (stato, ids) = try campo([
                Posto(parte: parte, archetipo: "tiratori",
                      protezione: .antiSaturazione, cella: Cella(riga: 9, colonna: 5)),
                Posto(parte: parte.avversaria, archetipo: "fanteria_pesante",
                      protezione: .antiSaturazione, cella: Cella(riga: 9 - distanza, colonna: 5)),
            ], parteDiTurno: parte)
            return dannoDelTiro(ids[0], ids[1], parte: parte, stato: stato)
        }
        for distanza in 1...valori.archetipi["tiratori"]!.gittata {
            XCTAssertEqual(try danno(tiratoreDi: .giocatore, distanza: distanza),
                           try danno(tiratoreDi: .avversario, distanza: distanza),
                           "distanza \(distanza): il modificatore è identico per le due parti")
        }
        XCTAssertGreaterThan(try danno(tiratoreDi: .avversario, distanza: 1),
                             try danno(tiratoreDi: .avversario, distanza: 6),
                             "anche l'avversario guadagna avvicinandosi")
    }

    // MARK: - Accerchiamento (01 §9.10.2)

    /// Il coefficiente cresce col numero dei concorrenti: moderatamente a due,
    /// assai di più a tre e a quattro. I numeri vengono dai dati (00 §13.1).
    func test_01_9_10_2_due_stringono_moderatamente_tre_e_quattro_assai_di_piu() throws {
        let uno = motore.coefficienteAccerchiamento(concorrenti: 1)
        let due = motore.coefficienteAccerchiamento(concorrenti: 2)
        let tre = motore.coefficienteAccerchiamento(concorrenti: 3)
        let quattro = motore.coefficienteAccerchiamento(concorrenti: 4)
        XCTAssertEqual(uno, .uno, "un solo assalitore non accerchia nessuno")
        XCTAssertGreaterThan(due, uno)
        XCTAssertGreaterThan(tre, due)
        XCTAssertGreaterThan(quattro, tre)
        // «Assai maggiore»: il salto da due a tre supera quello da uno a due.
        XCTAssertGreaterThan(tre - due, due - uno)
        // Il conteggio è limitato dal tetto dei dati: oltre non cresce più.
        let tetto = valori.combattimento.concorrentiMassimi
        XCTAssertEqual(motore.coefficienteAccerchiamento(concorrenti: tetto + 3),
                       motore.coefficienteAccerchiamento(concorrenti: tetto))
        // Le fasce dell'annuncio seguono la stessa scala.
        XCTAssertEqual(motore.fasciaAccerchiamento(concorrenti: 1), .isolato)
        XCTAssertEqual(motore.fasciaAccerchiamento(concorrenti: 2), .stretto)
        XCTAssertEqual(motore.fasciaAccerchiamento(concorrenti: 3), .circondato)
        XCTAssertEqual(motore.fasciaAccerchiamento(concorrenti: 4), .circondato)
    }

    /// Il danno inflitto in mischia cresce col numero degli assalitori, misurato
    /// sul giro risolto davvero e a parità di assalitori: si aggiunge un reparto
    /// identico alla volta e si guarda quanto prende quello che c'era già.
    func test_01_9_10_2_il_danno_di_mischia_cresce_col_numero_degli_assalitori() throws {
        let bersaglio = Cella(riga: 5, colonna: 5)
        let poste = [Cella(riga: 6, colonna: 4), Cella(riga: 6, colonna: 5),
                     Cella(riga: 5, colonna: 4), Cella(riga: 5, colonna: 6)]

        func dannoDelPrimo(assalitori: Int) throws -> Int64 {
            var (stato, ids) = try campo(
                (0..<assalitori).map { Posto(parte: .giocatore, archetipo: "fanteria_pesante",
                                             protezione: .antiSaturazione, cella: poste[$0]) }
                + [Posto(parte: .avversario, archetipo: "guardia_elite",
                         protezione: .antiSaturazione, cella: bersaglio)])
            let idBersaglio = ids.removeLast()
            // Soltanto il primo ingaggia: gli altri restano adiacenti e concorrono
            // ugualmente, perché l'insieme si ricava dalla posizione (01 §9.10.2).
            stato = motore.applica(.ingaggia(sciame: ids[0], bersaglio: idBersaglio),
                                   parte: .giocatore, stato: stato).0
            return dannoDelleMischie(stato)[idBersaglio] ?? 0
        }

        let solo = try dannoDelPrimo(assalitori: 1)
        let inDue = try dannoDelPrimo(assalitori: 2)
        let inTre = try dannoDelPrimo(assalitori: 3)
        XCTAssertGreaterThan(inDue, solo, "il secondo concorrente accresce il danno del primo")
        XCTAssertGreaterThan(inTre, inDue)
        XCTAssertGreaterThan(inTre - inDue, inDue - solo, "tre stringono assai più di due")
    }

    /// I tiratori concorrono all'accerchiamento pur non essendo a contatto: senza
    /// questo, l'accerchiamento condotto con i tiratori — che è manovra voluta —
    /// non produrrebbe alcun effetto (01 §9.10.2).
    func test_01_9_10_2_i_tiratori_concorrono_pur_non_essendo_a_contatto() throws {
        let bersaglio = Cella(riga: 5, colonna: 5)
        func danno(conTiratoreLontano: Bool) throws -> Int64 {
            var posti = [Posto(parte: .giocatore, archetipo: "fanteria_pesante",
                               protezione: .antiSaturazione, cella: Cella(riga: 6, colonna: 5)),
                         Posto(parte: .avversario, archetipo: "guardia_elite",
                               protezione: .antiSaturazione, cella: bersaglio)]
            if conTiratoreLontano {
                // A quattro celle: fuori da ogni contatto, dentro la gittata dei tiratori.
                posti.append(Posto(parte: .giocatore, archetipo: "tiratori",
                                   protezione: .antiSaturazione, cella: Cella(riga: 9, colonna: 5)))
            }
            var (stato, ids) = try campo(posti)
            XCTAssertGreaterThan(stato.griglia.distanza(Cella(riga: 9, colonna: 5), bersaglio), 1)
            stato = motore.applica(.ingaggia(sciame: ids[0], bersaglio: ids[1]),
                                   parte: .giocatore, stato: stato).0
            return dannoDelleMischie(stato)[ids[1]] ?? 0
        }
        XCTAssertGreaterThan(try danno(conTiratoreLontano: true), try danno(conTiratoreLontano: false),
                             "il tiratore che tiene il bersaglio sotto tiro concorre a stringerlo")

        // Fuori gittata non concorre: la portata è la condizione, non la presenza.
        let (stato, ids) = try campo([
            Posto(parte: .giocatore, archetipo: "fanteria_pesante",
                  protezione: .antiSaturazione, cella: Cella(riga: 6, colonna: 5)),
            Posto(parte: .avversario, archetipo: "guardia_elite",
                  protezione: .antiSaturazione, cella: bersaglio),
            Posto(parte: .giocatore, archetipo: "tiratori",
                  protezione: .antiSaturazione, cella: Cella(riga: 10, colonna: 10)),
        ])
        XCTAssertEqual(motore.concorrenti(contro: ids[1], stato: stato).count, 1,
                       "il tiratore fuori gittata non concorre")
        XCTAssertEqual(motore.concorrenti(contro: ids[1], stato: stato), [ids[0]])
    }

    /// L'accerchiato non riceve la maggiorazione: contro ciascuno dei suoi
    /// assalitori è lui a essere isolato, e i suoi colpi restano quelli di sempre.
    func test_01_9_10_2_l_accerchiato_non_riceve_la_maggiorazione() throws {
        let bersaglio = Cella(riga: 5, colonna: 5)
        let poste = [Cella(riga: 6, colonna: 4), Cella(riga: 6, colonna: 5), Cella(riga: 5, colonna: 4)]
        var (stato, ids) = try campo(
            (0..<3).map { Posto(parte: .giocatore, archetipo: "fanteria_pesante",
                                protezione: .antiSaturazione, cella: poste[$0]) }
            + [Posto(parte: .avversario, archetipo: "guardia_elite",
                     protezione: .antiSaturazione, cella: bersaglio)])
        for indice in 0..<3 {
            stato = motore.applica(.ingaggia(sciame: ids[indice], bersaglio: ids[3]),
                                   parte: .giocatore, stato: stato).0
        }
        XCTAssertEqual(motore.concorrenti(contro: ids[3], stato: stato).count, 3)
        for indice in 0..<3 {
            XCTAssertEqual(motore.concorrenti(contro: ids[indice], stato: stato).count, 1,
                           "contro ciascun assalitore l'accerchiato è solo")
            XCTAssertEqual(motore.fasciaAccerchiamento(
                concorrenti: motore.concorrenti(contro: ids[indice], stato: stato).count), .isolato)
        }
        XCTAssertEqual(motore.fasciaAccerchiamento(
            concorrenti: motore.concorrenti(contro: ids[3], stato: stato).count), .circondato)
    }

    /// L'insieme dei concorrenti si ricava dal solo stato: non dipende da quali
    /// azioni siano già state compiute — munizioni spese, azione consumata — né
    /// dall'ordine in cui i danni si applicano (01 §9.10.2).
    func test_01_9_10_2_l_insieme_dei_concorrenti_non_dipende_dalle_azioni_gia_compiute() throws {
        let bersaglio = Cella(riga: 5, colonna: 5)
        var (stato, ids) = try campo([
            Posto(parte: .giocatore, archetipo: "fanteria_pesante",
                  protezione: .antiSaturazione, cella: Cella(riga: 6, colonna: 5)),
            Posto(parte: .avversario, archetipo: "guardia_elite",
                  protezione: .antiSaturazione, cella: bersaglio),
            Posto(parte: .giocatore, archetipo: "tiratori",
                  protezione: .antiSaturazione, cella: Cella(riga: 8, colonna: 5)),
        ])
        let prima = motore.concorrenti(contro: ids[1], stato: stato)
        XCTAssertEqual(prima.count, 2)
        // Il tiratore spara: spende una scarica e l'azione. L'insieme non cambia.
        stato = motore.applica(.tira(sciame: ids[2], bersaglio: ids[1]),
                               parte: .giocatore, stato: stato).0
        XCTAssertEqual(motore.concorrenti(contro: ids[1], stato: stato), prima,
                       "spendere la scarica non toglie il reparto dai concorrenti")
        XCTAssertLessThan(stato.sciami[ids[2]]!.munizioni, valori.archetipi["tiratori"]!.dotazioneMunizioni)
        // Anche a munizioni esaurite l'insieme resta quello: la condizione è la posizione.
        stato.sciami[ids[2]]!.munizioni = 0
        XCTAssertEqual(motore.concorrenti(contro: ids[1], stato: stato), prima)
    }

    /// Chi è trattenuto in una mischia che non comprende il bersaglio non concorre
    /// a stringerlo: è impegnato altrove (01 §9.10.2).
    func test_01_9_10_2_chi_e_impegnato_altrove_non_concorre() throws {
        var (stato, ids) = try campo([
            Posto(parte: .giocatore, archetipo: "fanteria_pesante",
                  protezione: .antiSaturazione, cella: Cella(riga: 6, colonna: 5)),
            Posto(parte: .avversario, archetipo: "guardia_elite",
                  protezione: .antiSaturazione, cella: Cella(riga: 5, colonna: 5)),
            // I due vicini della cella (6,5) che stanno nella riga 5 sono (5,5) e (5,6).
            Posto(parte: .avversario, archetipo: "guardia_elite",
                  protezione: .antiSaturazione, cella: Cella(riga: 5, colonna: 6)),
        ])
        // Prima di ingaggiare, la fanteria concorre contro entrambi gli adiacenti.
        XCTAssertEqual(stato.griglia.distanza(Cella(riga: 6, colonna: 5), Cella(riga: 5, colonna: 6)), 1)
        XCTAssertEqual(motore.concorrenti(contro: ids[1], stato: stato), [ids[0]])
        XCTAssertEqual(motore.concorrenti(contro: ids[2], stato: stato), [ids[0]])
        stato = motore.applica(.ingaggia(sciame: ids[0], bersaglio: ids[1]),
                               parte: .giocatore, stato: stato).0
        XCTAssertEqual(motore.concorrenti(contro: ids[1], stato: stato), [ids[0]],
                       "contro chi ha ingaggiato continua a concorrere")
        XCTAssertEqual(motore.concorrenti(contro: ids[2], stato: stato), [],
                       "contro l'altro no: è trattenuto nella mischia")
    }

    /// L'accerchiamento vale per entrambe le parti (01 §9.10): scambiando le
    /// etichette di parte gli esiti restano identici.
    func test_01_9_10_2_l_accerchiamento_vale_per_entrambe_le_parti() throws {
        let bersaglio = Cella(riga: 5, colonna: 5)
        let poste = [Cella(riga: 6, colonna: 4), Cella(riga: 6, colonna: 5), Cella(riga: 5, colonna: 4)]
        func dannoSubitoDalBersaglio(assalitoriDi parte: Parte) throws -> Int64 {
            var (stato, ids) = try campo(
                (0..<3).map { Posto(parte: parte, archetipo: "fanteria_pesante",
                                    protezione: .antiSaturazione, cella: poste[$0]) }
                + [Posto(parte: parte.avversaria, archetipo: "guardia_elite",
                         protezione: .antiSaturazione, cella: bersaglio)],
                parteDiTurno: parte)
            for indice in 0..<3 {
                stato = motore.applica(.ingaggia(sciame: ids[indice], bersaglio: ids[3]),
                                       parte: parte, stato: stato).0
            }
            return dannoDelleMischie(stato)[ids[3]] ?? 0
        }
        XCTAssertEqual(try dannoSubitoDalBersaglio(assalitoriDi: .giocatore),
                       try dannoSubitoDalBersaglio(assalitoriDi: .avversario))
    }

    // MARK: - I due modificatori insieme

    /// I due modificatori si compongono sul tiro e non si escludono: avvicinarsi a
    /// un bersaglio già stretto rende più che avvicinarsi a uno isolato.
    func test_01_9_10_i_due_modificatori_si_compongono_sul_tiro() throws {
        func dannoDelTiratore(conAltriConcorrenti: Bool, distanza: Int) throws -> Int64 {
            var posti = [Posto(parte: .giocatore, archetipo: "tiratori",
                               protezione: .antiSaturazione, cella: Cella(riga: 9, colonna: 5)),
                         Posto(parte: .avversario, archetipo: "fanteria_pesante",
                               protezione: .antiSaturazione, cella: Cella(riga: 9 - distanza, colonna: 5))]
            if conAltriConcorrenti {
                posti.append(Posto(parte: .giocatore, archetipo: "fanteria_pesante",
                                   protezione: .antiSaturazione,
                                   cella: Cella(riga: 9 - distanza + 1, colonna: 5)))
            }
            let (stato, ids) = try campo(posti)
            return dannoDelTiro(ids[0], ids[1], parte: .giocatore, stato: stato)
        }
        let lontanoIsolato = try dannoDelTiratore(conAltriConcorrenti: false, distanza: 6)
        let lontanoStretto = try dannoDelTiratore(conAltriConcorrenti: true, distanza: 6)
        let vicinoIsolato = try dannoDelTiratore(conAltriConcorrenti: false, distanza: 2)
        let vicinoStretto = try dannoDelTiratore(conAltriConcorrenti: true, distanza: 2)
        XCTAssertGreaterThan(lontanoStretto, lontanoIsolato, "l'accerchiamento vale anche per il tiro")
        XCTAssertGreaterThan(vicinoIsolato, lontanoIsolato, "la vicinanza vale a bersaglio isolato")
        XCTAssertGreaterThan(vicinoStretto, max(vicinoIsolato, lontanoStretto),
                             "i due modificatori si compongono, non si escludono")
        print("MISURA modificatori sul tiro (tiratori, 5 atomi, bersaglio anti-saturazione): "
              + "lontano e isolato \(lontanoIsolato); lontano e stretto \(lontanoStretto); "
              + "vicino e isolato \(vicinoIsolato); vicino e stretto \(vicinoStretto)")
    }

    /// Che cosa cambia nello scontro che il titolare ha osservato: tre reparti
    /// contro uno, con i medesimi mazzi di prova. La misura si riporta in chiaro.
    func test_01_9_10_2_i_tre_contro_uno_dopo_i_modificatori() throws {
        let bersaglio = Cella(riga: 5, colonna: 5)
        let poste = [Cella(riga: 6, colonna: 4), Cella(riga: 6, colonna: 5), Cella(riga: 5, colonna: 4)]
        var (stato, ids) = try campo([
            Posto(parte: .giocatore, archetipo: "tiratori",
                  protezione: .antiSaturazione, cella: poste[0]),
            Posto(parte: .giocatore, archetipo: "fanteria_leggera",
                  protezione: .antiSaturazione, cella: poste[1]),
            Posto(parte: .giocatore, archetipo: "fanteria_pesante",
                  protezione: .antiPerforazione, cella: poste[2]),
            Posto(parte: .avversario, archetipo: "fanteria_pesante",
                  protezione: .antiSaturazione, cella: bersaglio),
        ])
        for indice in 0..<3 {
            stato = motore.applica(.ingaggia(sciame: ids[indice], bersaglio: ids[3]),
                                   parte: .giocatore, stato: stato).0
        }
        let subiti = dannoDelleMischie(stato)
        let inflitto = subiti[ids[3]] ?? 0
        let subito = (0..<3).reduce(Int64(0)) { $0 + (subiti[ids[$1]] ?? 0) }
        print("MISURA tre contro uno con l'accerchiamento: i tre infliggono \(inflitto) punti, "
              + "ne subiscono \(subito) in totale")
        // Prima dei modificatori i tre infliggevano 258 punti a giro (accertamento).
        XCTAssertGreaterThan(inflitto, 258, "l'accerchiamento accresce ciò che i tre infliggono")
        // Il rovescio della medaglia non è più simmetrico: dal limite dei bersagli
        // simultanei (01 §9.11) l'accerchiato risponde ad al massimo due, e i 416
        // punti che restituiva alla data dell'accertamento sono ora molti meno.
        // L'accerchiamento resta comunque un premio a chi stringe e mai a chi è stretto.
        XCTAssertLessThan(subito, 416)
        for indice in 0..<3 {
            XCTAssertEqual(motore.concorrenti(contro: ids[indice], stato: stato).count, 1,
                           "contro ciascun assalitore l'accerchiato resta isolato")
        }
    }

    // MARK: - Nessun numero di gioco fuori dai dati (00 §13.1)

    /// I due modificatori non contengono alcuna cifra propria: ogni numero viene
    /// dai file e la struttura è la sola formula.
    func test_00_13_1_i_numeri_dei_due_modificatori_vengono_dai_dati() throws {
        let c = valori.combattimento
        XCTAssertEqual(motore.coefficienteVicinanza(distanza: 1, gittata: 5),
                       c.resaTiroAllaMinimaDistanza)
        XCTAssertEqual(motore.coefficienteVicinanza(distanza: 5, gittata: 5), c.resaTiroAlLimite)
        XCTAssertEqual(motore.coefficienteAccerchiamento(concorrenti: 2),
                       .uno + c.passoAccerchiamento)
        XCTAssertEqual(motore.coefficienteAccerchiamento(concorrenti: 3),
                       .uno + c.passoAccerchiamento * Scalato(intero: 4))
        // Le soglie delle fasce sono quelle dei dati, non cifre scritte nel Motore.
        XCTAssertEqual(motore.fasciaVicinanza(distanza: 1, gittata: 1), .aRidosso)
        let gittata = 101 // prossimità in centesimi esatti: la soglia si vede al passo
        let sogliaLontano = Int(c.fasciaVicinanzaLontanoFino.grezzo)
        XCTAssertEqual(motore.fasciaVicinanza(distanza: gittata - sogliaLontano / 10,
                                              gittata: gittata), .lontano)
    }
}
