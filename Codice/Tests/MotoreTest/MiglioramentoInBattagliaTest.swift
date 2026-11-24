import XCTest
import Motore
import Dati
import Contenuti

/// Il MIGLIORAMENTO DI UN REPARTO IN BATTAGLIA (01 §4.13; incarico 31, regola F): il reparto che in
/// patria ha ricevuto l'addestramento mirato infligge più danno dello stesso reparto non
/// migliorato, nella misura del coefficiente che i valori dichiarano; il miglioramento e l'anno di
/// leva scendono in battaglia col reparto e tornano coi suoi superstiti. Per il reparto ordinario
/// nulla cambia: lo provano le riproduzioni d'oro e `SalvataggiBattagliaECampagnaBuild31Test`.
final class MiglioramentoInBattagliaTest: XCTestCase {

    var valori: ValoriDiGioco!
    var motore: MotoreBattaglia!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreBattaglia(valori: valori)
    }

    // MARK: - Attrezzi

    private static let addestramento: IdentificatoreDati = "addestramento_mirato"

    private func elemento(_ archetipo: String, atomi: Int64, migliorato: Bool = false, leva: Int? = nil,
                          protezione: TipoProtezione = .antiSaturazione) -> ScenarioBattaglia.ElementoScenario {
        .init(archetipo: IdentificatoreDati(archetipo), protezione: protezione, atomi: atomi, esemplari: 1,
              miglioramento: migliorato ? Self.addestramento : nil, leva: leva)
    }

    private func scenario(giocatore: [ScenarioBattaglia.ElementoScenario],
                          avversario: [ScenarioBattaglia.ElementoScenario]) -> ScenarioBattaglia {
        ScenarioBattaglia(formato: "cento", caratteristica: "campo_aperto", primoOccupante: .giocatore,
                          imboscata: false, deckGiocatore: giocatore, deckAvversario: avversario)
    }

    @discardableResult
    private func esegui(_ comando: ComandoBattaglia, _ parte: Parte, _ stato: inout StatoBattaglia,
                        con motore: MotoreBattaglia? = nil, file: StaticString = #filePath,
                        line: UInt = #line) -> [EventoBattaglia] {
        let motore = motore ?? self.motore!
        let esito = motore.valida(comando, parte: parte, stato: stato)
        XCTAssertTrue(esito.eValido, "comando non valido: \(String(describing: esito.motivo))", file: file, line: line)
        guard esito.eValido else { return [] }
        let (nuovo, eventi) = motore.applica(comando, parte: parte, stato: stato)
        stato = nuovo
        return eventi
    }

    /// Uno sciame di prova, con tutti gli atomi presenti.
    private func sciame(_ numero: Int, _ parte: Parte, _ archetipo: String, atomi: Int64, migliorato: Bool,
                        protezione: TipoProtezione = .antiSaturazione) throws -> Sciame {
        let definizione = try XCTUnwrap(valori.archetipi[IdentificatoreDati(archetipo)])
        return Sciame(id: IdSciame(numero), parte: parte, archetipo: IdentificatoreDati(archetipo),
                      protezione: protezione, lettera: numero, atomiIniziali: atomi,
                      serbatoio: atomi * definizione.puntiVitaPerAtomo, munizioni: definizione.dotazioneMunizioni,
                      posizione: Cella(riga: parte == .giocatore ? 8 : 3, colonna: numero), azioneSpesa: false,
                      rinforzo: false, miglioramento: migliorato ? Self.addestramento : nil, leva: nil)
    }

    /// Il danno atteso, con la sola aritmetica della regola (01 §9.2.1, §4.13): la capacità
    /// offensiva del reparto — per atomo, per gli atomi, e per il coefficiente del miglioramento se
    /// lo porta — moltiplicata per l'efficacia dell'offesa sulla protezione e per il coefficiente
    /// dello scontro; troncata, mai sotto il danno minimo. In campo aperto nessun altro modificatore.
    private func dannoAtteso(archetipo: String, atomi: Int64, offesa: ProfiloOffesa, protezione: TipoProtezione,
                             coefficiente: Scalato, miglioramento: Scalato?, con motore: MotoreBattaglia) throws -> Int64 {
        let definizione = try XCTUnwrap(motore.valori.archetipi[IdentificatoreDati(archetipo)])
        var base = definizione.capacitaOffensivaPerAtomo * atomi
        if let miglioramento { base = miglioramento.applicato(a: base) }
        let efficacia = motore.efficacia(offesa: offesa, protezione: try XCTUnwrap(motore.valori.protezioni[protezione]))
        return max(motore.valori.minimi.dannoMinimo, (efficacia * coefficiente * .uno).applicato(a: base))
    }

    // MARK: - La formula

    func test_incarico_31_F_il_reparto_migliorato_infligge_piu_danno_nella_misura_del_coefficiente() throws {
        let coefficiente = try XCTUnwrap(valori.miglioramenti[Self.addestramento]).capacitaOffensiva
        XCTAssertGreaterThan(coefficiente, .uno)
        let stato = try FabbricaBattaglia.crea(
            scenario: scenario(giocatore: [elemento("fanteria_pesante", atomi: 8)],
                               avversario: [elemento("fanteria_leggera", atomi: 6)]), valori: valori).0
        var confronti = 0
        for archetipo in ["fanteria_leggera", "fanteria_pesante", "cavalleria_manovrata", "tiratori"] {
            let definizione = try XCTUnwrap(valori.archetipi[IdentificatoreDati(archetipo)])
            for atomi in [Int64(1), 5, 8, 24] {
                let ordinario = try sciame(1, .giocatore, archetipo, atomi: atomi, migliorato: false)
                let migliorato = try sciame(2, .giocatore, archetipo, atomi: atomi, migliorato: true)
                for protezione in TipoProtezione.allCases {
                    let bersaglio = try sciame(3, .avversario, "fanteria_leggera", atomi: 6, migliorato: false,
                                               protezione: protezione)
                    var offese = [definizione.offesaMischia]
                    if let tiro = definizione.offesaTiro { offese.append(tiro) }
                    for offesa in offese {
                        for scontro in [Scalato.uno, Scalato(millesimi: 500), Scalato(millesimi: 1500)] {
                            let dannoOrdinario = motore.danno(da: ordinario, offesa: offesa, a: bersaglio,
                                                              coefficiente: scontro, stato: stato)
                            let dannoMigliorato = motore.danno(da: migliorato, offesa: offesa, a: bersaglio,
                                                               coefficiente: scontro, stato: stato)
                            let che = "\(archetipo), \(atomi) atomi, \(protezione.rawValue), coefficiente \(scontro.grezzo)"
                            XCTAssertEqual(dannoOrdinario, try dannoAtteso(
                                archetipo: archetipo, atomi: atomi, offesa: offesa, protezione: protezione,
                                coefficiente: scontro, miglioramento: nil, con: motore), "ordinario: \(che)")
                            XCTAssertEqual(dannoMigliorato, try dannoAtteso(
                                archetipo: archetipo, atomi: atomi, offesa: offesa, protezione: protezione,
                                coefficiente: scontro, miglioramento: coefficiente, con: motore), "migliorato: \(che)")
                            XCTAssertGreaterThanOrEqual(dannoMigliorato, dannoOrdinario, che)
                            confronti += 1
                        }
                    }
                }
            }
        }
        XCTAssertGreaterThan(confronti, 100)
        // Un caso scritto per esteso: otto atomi di fanteria pesante contro la protezione che para
        // la saturazione. La capacità è 40 per atomo: 320 senza addestramento, 384 con (per 1,2).
        let pesante = try XCTUnwrap(valori.archetipi["fanteria_pesante"])
        XCTAssertEqual(pesante.capacitaOffensivaPerAtomo * 8, 320)
        XCTAssertEqual(coefficiente.applicato(a: 320), Int64(320 * coefficiente.grezzo / 1000))
        let bersaglio = try sciame(3, .avversario, "fanteria_leggera", atomi: 6, migliorato: false)
        let senza = motore.danno(da: try sciame(1, .giocatore, "fanteria_pesante", atomi: 8, migliorato: false),
                                 offesa: pesante.offesaMischia, a: bersaglio, coefficiente: .uno, stato: stato)
        let con = motore.danno(da: try sciame(2, .giocatore, "fanteria_pesante", atomi: 8, migliorato: true),
                               offesa: pesante.offesaMischia, a: bersaglio, coefficiente: .uno, stato: stato)
        XCTAssertGreaterThan(con, senza, "il reparto addestrato infligge più danno dello stesso reparto non addestrato")
        let efficacia = motore.efficacia(offesa: pesante.offesaMischia,
                                         protezione: try XCTUnwrap(valori.protezioni[.antiSaturazione]))
        XCTAssertEqual(senza, efficacia.applicato(a: 320))
        XCTAssertEqual(con, efficacia.applicato(a: coefficiente.applicato(a: 320)))
        print("MIGLIORAMENTO-DANNO coefficiente=\(coefficiente.grezzo) senza=\(senza) con=\(con) confronti=\(confronti)")
    }

    /// La misura è quella dei VALORI: con un altro coefficiente in `miglioramenti.json` il danno del
    /// reparto migliorato cambia di conseguenza, e quello del reparto ordinario resta lo stesso.
    func test_incarico_31_F_la_misura_e_quella_dichiarata_nei_valori() throws {
        func motoreCon(coefficiente: String) throws -> MotoreBattaglia {
            let copia = FileManager.default.temporaryDirectory.appendingPathComponent("valori-miglioramento-\(UUID().uuidString)")
            try FileManager.default.copyItem(at: Contenuti.valoriDiFabbrica, to: copia)
            addTeardownBlock { try? FileManager.default.removeItem(at: copia) }
            try #"[ {"identificatore":"addestramento_mirato","capacita_offensiva":\#(coefficiente)} ]"#
                .write(to: copia.appendingPathComponent("miglioramenti.json"), atomically: true, encoding: .utf8)
            return MotoreBattaglia(valori: try CaricatoreValori.carica(da: copia))
        }
        let stato = try FabbricaBattaglia.crea(
            scenario: scenario(giocatore: [elemento("fanteria_pesante", atomi: 8)],
                               avversario: [elemento("fanteria_leggera", atomi: 6)]), valori: valori).0
        let pesante = try XCTUnwrap(valori.archetipi["fanteria_pesante"])
        let ordinario = try sciame(1, .giocatore, "fanteria_pesante", atomi: 8, migliorato: false)
        let migliorato = try sciame(2, .giocatore, "fanteria_pesante", atomi: 8, migliorato: true)
        let bersaglio = try sciame(3, .avversario, "fanteria_leggera", atomi: 6, migliorato: false)
        let diFabbrica = motore.danno(da: ordinario, offesa: pesante.offesaMischia, a: bersaglio, coefficiente: .uno, stato: stato)
        var precedente = diFabbrica
        for (testo, millesimi) in [("1", Int64(1000)), ("1.5", 1500), ("2", 2000), ("3.25", 3250)] {
            let altro = try motoreCon(coefficiente: testo)
            XCTAssertEqual(altro.danno(da: ordinario, offesa: pesante.offesaMischia, a: bersaglio, coefficiente: .uno, stato: stato),
                           diFabbrica, "il reparto ordinario non risente del coefficiente \(testo)")
            let danno = altro.danno(da: migliorato, offesa: pesante.offesaMischia, a: bersaglio, coefficiente: .uno, stato: stato)
            XCTAssertEqual(danno, try dannoAtteso(archetipo: "fanteria_pesante", atomi: 8, offesa: pesante.offesaMischia,
                                                  protezione: .antiSaturazione, coefficiente: .uno,
                                                  miglioramento: Scalato(millesimi: millesimi), con: altro), "coefficiente \(testo)")
            XCTAssertGreaterThanOrEqual(danno, precedente, "a coefficiente maggiore, danno non minore")
            precedente = danno
        }
        // Col coefficiente uno il miglioramento non accresce nulla: il danno è quello ordinario.
        XCTAssertEqual(try motoreCon(coefficiente: "1").danno(da: migliorato, offesa: pesante.offesaMischia, a: bersaglio,
                                                              coefficiente: .uno, stato: stato), diFabbrica)
    }

    // MARK: - In una battaglia giocata

    /// Due reparti di tiratori identici, uno addestrato e uno no, tirano dalla stessa distanza sullo
    /// stesso bersaglio: il miglioramento scende in campo col reparto — dallo scenario al mazzo,
    /// dal mazzo allo sciame — e il tiro dell'addestrato fa più danno, nella misura del coefficiente.
    func test_incarico_31_F_in_una_battaglia_giocata_il_tiro_del_reparto_addestrato_fa_piu_danno() throws {
        let coefficiente = try XCTUnwrap(valori.miglioramenti[Self.addestramento]).capacitaOffensiva
        var stato = try FabbricaBattaglia.crea(
            scenario: scenario(giocatore: [elemento("tiratori", atomi: 5, migliorato: true, leva: 2),
                                           elemento("tiratori", atomi: 5)],
                               avversario: [elemento("fanteria_pesante", atomi: 8)]), valori: valori).0
        XCTAssertEqual(stato.deck[.giocatore]?.map(\.miglioramento), [Self.addestramento, nil])
        XCTAssertEqual(stato.deck[.giocatore]?.map(\.leva), [2, nil])
        // Il giocatore schiera i due reparti di tiratori; l'avversario la fanteria.
        esegui(.seleziona(indiceDeck: 0), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 8, colonna: 4)), .giocatore, &stato)
        esegui(.seleziona(indiceDeck: 1), .giocatore, &stato)
        esegui(.piazza(cella: Cella(riga: 8, colonna: 6)), .giocatore, &stato)
        esegui(.fineTurno, .giocatore, &stato)
        esegui(.seleziona(indiceDeck: 0), .avversario, &stato)
        esegui(.piazza(cella: Cella(riga: 3, colonna: 5)), .avversario, &stato)
        esegui(.fineTurno, .avversario, &stato)

        let addestrato = try XCTUnwrap(stato.sciami.values.first { $0.posizione == Cella(riga: 8, colonna: 4) })
        let ordinario = try XCTUnwrap(stato.sciami.values.first { $0.posizione == Cella(riga: 8, colonna: 6) })
        let bersaglio = try XCTUnwrap(stato.sciami.values.first { $0.parte == .avversario })
        XCTAssertEqual(addestrato.miglioramento, Self.addestramento, "lo sciame porta il miglioramento del reparto")
        XCTAssertEqual(addestrato.leva, 2)
        XCTAssertNil(ordinario.miglioramento)
        XCTAssertNil(ordinario.leva)
        let distanza = stato.griglia.distanza(addestrato.posizione, bersaglio.posizione)
        XCTAssertEqual(stato.griglia.distanza(ordinario.posizione, bersaglio.posizione), distanza,
                       "i due reparti tirano dalla stessa distanza")

        func dannoDelTiro(_ eventi: [EventoBattaglia]) -> Int64? {
            for evento in eventi {
                if case .tiroEseguito(_, _, _, _, _, let danno, _, _) = evento { return danno }
            }
            return nil
        }
        let dannoOrdinario = try XCTUnwrap(dannoDelTiro(esegui(.tira(sciame: ordinario.id, bersaglio: bersaglio.id), .giocatore, &stato)))
        let dannoAddestrato = try XCTUnwrap(dannoDelTiro(esegui(.tira(sciame: addestrato.id, bersaglio: bersaglio.id), .giocatore, &stato)))
        XCTAssertGreaterThan(dannoAddestrato, dannoOrdinario)

        // La misura: la stessa efficacia, la stessa vicinanza e lo stesso accerchiamento — i due
        // reparti hanno entrambi il bersaglio a portata, e concorrono contro di lui (01 §9.10.2) —,
        // sulla capacità accresciuta dal coefficiente.
        let tiratori = try XCTUnwrap(valori.archetipi["tiratori"])
        let vicinanza = motore.coefficienteVicinanza(distanza: distanza,
                                                    gittata: motore.gittataEffettiva(tiratori.gittata, stato: stato))
        XCTAssertEqual(motore.concorrenti(contro: bersaglio.id, stato: stato).count, 2)
        let scontro = vicinanza * motore.coefficienteAccerchiamento(concorrenti: 2)
        let tiro = try XCTUnwrap(tiratori.offesaTiro)
        XCTAssertEqual(dannoOrdinario, try dannoAtteso(archetipo: "tiratori", atomi: 5, offesa: tiro, protezione: .antiSaturazione,
                                                       coefficiente: scontro, miglioramento: nil, con: motore))
        XCTAssertEqual(dannoAddestrato, try dannoAtteso(archetipo: "tiratori", atomi: 5, offesa: tiro, protezione: .antiSaturazione,
                                                        coefficiente: scontro, miglioramento: coefficiente, con: motore))
        // Il bersaglio ha perduto esattamente la somma dei due tiri.
        let dopo = try XCTUnwrap(stato.sciami[bersaglio.id])
        XCTAssertEqual(bersaglio.serbatoio - dopo.serbatoio, dannoOrdinario + dannoAddestrato)
        print("MIGLIORAMENTO-TIRO distanza=\(distanza) ordinario=\(dannoOrdinario) addestrato=\(dannoAddestrato)")
    }

    func test_incarico_31_F_la_fabbrica_rifiuta_un_miglioramento_che_i_valori_non_conoscono() throws {
        let ignoto = ScenarioBattaglia.ElementoScenario(archetipo: "fanteria_leggera", protezione: .antiSaturazione,
                                                        atomi: 6, esemplari: 1, miglioramento: "miglioramento_che_non_esiste")
        for (giocatore, avversario) in [([ignoto], [elemento("fanteria_leggera", atomi: 6)]),
                                        ([elemento("fanteria_leggera", atomi: 6)], [ignoto])] {
            XCTAssertThrowsError(try FabbricaBattaglia.crea(scenario: scenario(giocatore: giocatore, avversario: avversario),
                                                            valori: valori)) {
                XCTAssertEqual($0 as? FabbricaBattaglia.ErroreScenario, .miglioramentoIgnoto("miglioramento_che_non_esiste"))
            }
        }
        XCTAssertNoThrow(try FabbricaBattaglia.crea(
            scenario: scenario(giocatore: [elemento("fanteria_leggera", atomi: 6, migliorato: true)],
                               avversario: [elemento("fanteria_leggera", atomi: 6)]), valori: valori))
    }

    // MARK: - Dalla campagna alla battaglia, e ritorno

    /// I reparti del gruppo di prova: per ciascun archetipo, ordinari e addestrati, e di anni di leva
    /// diversi; due sono della stessa specie, e al ritorno si riuniscono.
    private static let seiReparti: [ScenarioCampagna.RepartoIniziale] = [
        .init(archetipo: "fanteria_pesante", atomi: 8, miglioramento: addestramento),
        .init(archetipo: "fanteria_pesante", atomi: 8),
        .init(archetipo: "fanteria_leggera", atomi: 6, leva: 2),
        .init(archetipo: "fanteria_leggera", atomi: 6, miglioramento: addestramento, leva: 2),
        .init(archetipo: "fanteria_leggera", atomi: 6, leva: 3),
        .init(archetipo: "fanteria_leggera", atomi: 6, leva: 2),
    ]

    /// Un gruppo di campagna coi reparti dati e l'avversario nella stessa casella, con la battaglia
    /// in sospeso.
    private func campagnaConLaBattagliaInSospeso(
        reparti: [ScenarioCampagna.RepartoIniziale] = MiglioramentoInBattagliaTest.seiReparti,
        avversario: [ScenarioCampagna.RepartoIniziale] = [.init(archetipo: "fanteria_leggera", atomi: 6)]
    ) throws -> (stato: StatoCampagna, battaglia: BattagliaInSospeso, valoriCampagna: ValoriCampagna) {
        let valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        var stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(
                mappa: "pianura_lunga",
                gruppiGiocatore: [.init(riga: 9, colonna: 5, composizione: reparti, nome: "lupo")],
                gruppiAvversario: [.init(riga: 1, colonna: 5, composizione: avversario)],
                calendario: CalendarioDiCampagna(anno: 3, giornatePerStagione: 30)),
            valori: valoriCampagna, archetipiNoti: Set(valori.archetipi.keys))
        let mio = try XCTUnwrap(stato.gruppiOrdinati.first { $0.parte == .giocatore })
        let suo = try XCTUnwrap(stato.gruppiOrdinati.first { $0.parte == .avversario })
        stato.gruppi[suo.id]!.posizione = mio.posizione
        let battaglia = BattagliaInSospeso(identificatore: "battaglia-di-prova", casella: mio.posizione,
                                           gruppoGiocatore: mio.id, gruppoAvversario: suo.id,
                                           primoOccupante: .giocatore, imboscante: nil, giorno: 1)
        stato.battaglieInSospeso = [battaglia]
        return (stato, battaglia, valoriCampagna)
    }

    private var modello: PonteCampagnaBattaglia.Modello {
        PonteCampagnaBattaglia.Modello(formato: "cento", caratteristica: "campo_aperto", protezione: .antiSaturazione,
                                       fase: nil, ufficialeAvversario: valori.ufficiali.keys.sorted().first)
    }

    func test_incarico_31_F_il_ponte_porta_in_battaglia_il_miglioramento_e_l_anno_di_leva_di_ogni_reparto() throws {
        let (stato, battaglia, _) = try campagnaConLaBattagliaInSospeso()
        let scenario = PonteCampagnaBattaglia.scenario(da: battaglia, stato: stato, modello: modello)
        XCTAssertEqual(scenario.deckGiocatore.map(\.archetipo),
                       ["fanteria_pesante", "fanteria_pesante", "fanteria_leggera", "fanteria_leggera",
                        "fanteria_leggera", "fanteria_leggera"], "un elemento per reparto, nell'ordine del gruppo")
        XCTAssertEqual(scenario.deckGiocatore.map(\.miglioramento),
                       [Self.addestramento, nil, nil, Self.addestramento, nil, nil])
        XCTAssertEqual(scenario.deckGiocatore.map(\.leva), [nil, nil, 2, 2, 3, 2])
        XCTAssertEqual(scenario.deckGiocatore.map(\.atomi), [8, 8, 6, 6, 6, 6])
        XCTAssertTrue(scenario.deckAvversario.allSatisfy { $0.miglioramento == nil && $0.leva == nil })
        // Lo stato di battaglia che ne nasce li porta nel mazzo.
        let inBattaglia = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
        XCTAssertEqual(inBattaglia.deck[.giocatore]?.map(\.miglioramento),
                       [Self.addestramento, nil, nil, Self.addestramento, nil, nil])
        XCTAssertEqual(inBattaglia.deck[.giocatore]?.map(\.leva), [nil, nil, 2, 2, 3, 2])
    }

    func test_incarico_31_F_i_superstiti_di_una_battaglia_conservano_miglioramento_e_anno_di_leva() throws {
        let (stato, battaglia, _) = try campagnaConLaBattagliaInSospeso()
        let scenario = PonteCampagnaBattaglia.scenario(da: battaglia, stato: stato, modello: modello)
        // L'avversario si arrende prima che un colpo sia scambiato: tutti i reparti del giocatore
        // sono superstiti, per intero. Tornano raggruppati per archetipo, miglioramento e anno di
        // leva: i due reparti di fanteria leggera dell'anno 2 senza addestramento si riuniscono, gli
        // altri restano distinti, e l'addestrato non si confonde col non addestrato.
        var conclusa = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
        conclusa.esito = EsitoBattaglia(sconfitto: .avversario, modo: .ritirataCompiuta, turni: 1)
        let intatta = PonteCampagnaBattaglia.esito(da: conclusa, per: battaglia, stato: stato, valori: valori)
        XCTAssertEqual(intatta.composizioneGiocatore, [
            Reparto(archetipo: "fanteria_leggera", atomi: 12, leva: 2),
            Reparto(archetipo: "fanteria_leggera", atomi: 6, leva: 3),
            Reparto(archetipo: "fanteria_leggera", atomi: 6, miglioramento: Self.addestramento, leva: 2),
            Reparto(archetipo: "fanteria_pesante", atomi: 8),
            Reparto(archetipo: "fanteria_pesante", atomi: 8, miglioramento: Self.addestramento),
        ])
        XCTAssertEqual(intatta.composizioneAvversario, [Reparto(archetipo: "fanteria_leggera", atomi: 6)],
                       "senza miglioramenti né leve il raggruppamento è quello di sempre: un reparto per archetipo")
    }

    /// Una battaglia COMBATTUTA fino in fondo dai due tattici, come al banco: tre reparti del
    /// giocatore — uno addestrato, uno con l'anno di leva, uno con entrambi — contro un gruppo
    /// avversario ordinario e più debole. Per ogni specie di reparto non torna più di
    /// quanto è sceso, e non torna alcuna specie che non c'era: il miglioramento e l'anno di leva
    /// non nascono, non si perdono e non migrano da un reparto all'altro combattendo.
    func test_incarico_31_F_in_una_battaglia_combattuta_ogni_superstite_e_della_specie_con_cui_e_sceso() throws {
        let (stato, battaglia, _) = try campagnaConLaBattagliaInSospeso(
            reparti: [.init(archetipo: "fanteria_pesante", atomi: 8, miglioramento: Self.addestramento),
                      .init(archetipo: "fanteria_leggera", atomi: 6, leva: 2),
                      .init(archetipo: "fanteria_leggera", atomi: 6, miglioramento: Self.addestramento, leva: 2)],
            avversario: [.init(archetipo: "fanteria_leggera", atomi: 6)])
        let scenario = PonteCampagnaBattaglia.scenario(da: battaglia, stato: stato, modello: modello)
        var combattuta = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
        let ufficiale = try XCTUnwrap(valori.ufficiali[try XCTUnwrap(modello.ufficialeAvversario)])
        let tattici: [Parte: TatticoBattaglia] = [
            .giocatore: TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .giocatore),
            .avversario: TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .avversario)]
        var passi = 0
        var scesiInCampo: [IdSciame: Sciame] = [:]
        while combattuta.esito == nil, combattuta.giro <= 400, passi < 40_000 {
            passi += 1
            let parte = combattuta.parteDiTurno
            combattuta = motore.applica(tattici[parte]!.prossimoComando(stato: combattuta), parte: parte, stato: combattuta).0
            for sciame in combattuta.sciami.values where sciame.parte == .giocatore && scesiInCampo[sciame.id] == nil {
                scesiInCampo[sciame.id] = sciame
            }
        }
        guard combattuta.esito != nil else {
            return XCTFail("la battaglia di prova non si è conclusa (giro \(combattuta.giro), \(passi) passi)")
        }
        // Ogni sciame sceso in campo porta il miglioramento e l'anno di leva dell'elemento da cui viene:
        // tre elementi, tre sciami, le stesse tre specie.
        XCTAssertEqual(scesiInCampo.values.map { "\($0.archetipo)|\($0.miglioramento ?? "")|\($0.leva ?? -1)" }.sorted(),
                       scenario.deckGiocatore.map { "\($0.archetipo)|\($0.miglioramento ?? "")|\($0.leva ?? -1)" }.sorted())
        let esito = PonteCampagnaBattaglia.esito(da: combattuta, per: battaglia, stato: stato, valori: valori)
        struct Specie: Hashable { let archetipo: String; let miglioramento: String?; let leva: Int? }
        var entrati: [Specie: Int] = [:]
        for reparto in stato.gruppi[battaglia.gruppoGiocatore]!.composizione {
            entrati[Specie(archetipo: reparto.archetipo, miglioramento: reparto.miglioramento, leva: reparto.leva),
                    default: 0] += reparto.atomi
        }
        var viste = Set<Specie>()
        for reparto in esito.composizioneGiocatore {
            let specie = Specie(archetipo: reparto.archetipo, miglioramento: reparto.miglioramento, leva: reparto.leva)
            XCTAssertTrue(viste.insert(specie).inserted, "due reparti della stessa specie: non sono stati raggruppati")
            XCTAssertLessThanOrEqual(reparto.atomi, try XCTUnwrap(entrati[specie], "specie mai scesa in battaglia: \(specie)"))
            XCTAssertGreaterThan(reparto.atomi, 0)
        }
        // L'avversario, senza miglioramenti né leve, torna raggruppato per solo archetipo.
        XCTAssertTrue(esito.composizioneAvversario.allSatisfy { $0.miglioramento == nil && $0.leva == nil })
        XCTAssertEqual(Set(esito.composizioneAvversario.map(\.archetipo)).count, esito.composizioneAvversario.count)
        // I superstiti del giocatore sono gli atomi presenti dei suoi sciami, specie per specie.
        for (specie, _) in entrati {
            let presenti = combattuta.sciami.values
                .filter { $0.parte == .giocatore && $0.archetipo == specie.archetipo
                    && $0.miglioramento == specie.miglioramento && $0.leva == specie.leva }
                .reduce(0) { somma, sciame in
                    somma + Int(sciame.atomiPresenti(puntiVitaPerAtomo: valori.archetipi[sciame.archetipo]!.puntiVitaPerAtomo,
                                                     minimo: valori.minimi.atomiMinimiSciameVivo))
                }
            let nelMazzo = (combattuta.deck[.giocatore] ?? [])
                .filter { $0.esemplari > 0 && $0.archetipo == specie.archetipo
                    && $0.miglioramento == specie.miglioramento && $0.leva == specie.leva }
                .reduce(0) { $0 + Int($1.atomi) * $1.esemplari }
            let tornati = esito.composizioneGiocatore.first {
                $0.archetipo == specie.archetipo && $0.miglioramento == specie.miglioramento && $0.leva == specie.leva
            }?.atomi ?? 0
            XCTAssertEqual(tornati, presenti + nelMazzo, "\(specie)")
        }
        print("MIGLIORAMENTO-SUPERSTITI passi=\(passi) giro=\(combattuta.giro) esito=\(String(describing: combattuta.esito)) superstiti=\(esito.composizioneGiocatore.map { "\($0.archetipo):\($0.atomi):\($0.miglioramento ?? "-"):\($0.leva.map(String.init) ?? "-")" })")
    }

    /// L'esito piegato sulla campagna rende al gruppo i reparti com'erano: il miglioramento e
    /// l'anno di leva stanno nella composizione che il gruppo riprende.
    func test_incarico_31_F_tornato_in_campagna_il_gruppo_ha_ancora_i_reparti_addestrati() throws {
        let (iniziale, battaglia, valoriCampagna) = try campagnaConLaBattagliaInSospeso()
        var stato = iniziale
        let scenario = PonteCampagnaBattaglia.scenario(da: battaglia, stato: stato, modello: modello)
        var conclusa = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
        conclusa.esito = EsitoBattaglia(sconfitto: .avversario, modo: .annientamento, turni: 3)
        conclusa.deck[.avversario] = []
        let esito = PonteCampagnaBattaglia.esito(da: conclusa, per: battaglia, stato: stato, valori: valori)
        XCTAssertTrue(esito.composizioneAvversario.isEmpty)
        let motoreCampagna = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
        _ = motoreCampagna.applicaEsitoInCampagna(esito, in: &stato)
        let lupo = try XCTUnwrap(stato.gruppiOrdinati.first { $0.nome == "lupo" })
        XCTAssertEqual(lupo.composizione, esito.composizioneGiocatore)
        XCTAssertEqual(lupo.composizione.filter { $0.miglioramento == Self.addestramento }.map(\.atomi), [6, 8])
        XCTAssertEqual(lupo.composizione.compactMap(\.leva).sorted(), [2, 2, 3])
        // E l'esito che la campagna conclusa porta al regno ha gli stessi reparti.
        XCTAssertEqual(stato.conclusione?.vincitore, .giocatore, "l'avversario non ha più gruppi armati")
        let alRegno = try XCTUnwrap(PonteRegnoCampagna.esito(da: stato, fronte: "pianura_lunga"))
        XCTAssertEqual(alRegno.superstiti.formazioni.first { $0.nome == "lupo" }?.composizione, esito.composizioneGiocatore)
    }

    // MARK: - Codifica e impronta (00 §15, 05 §2.9)

    func test_incarico_31_F_il_reparto_ordinario_si_codifica_come_prima_e_quello_addestrato_si_rilegge() throws {
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = [.sortedKeys]
        func testo<T: Encodable>(_ valore: T) throws -> String { String(data: try codificatore.encode(valore), encoding: .utf8)! }
        // L'elemento dello scenario, l'elemento del mazzo, il reparto di campagna: senza
        // miglioramento né anno di leva le chiavi nuove non compaiono.
        XCTAssertEqual(try testo(elemento("fanteria_leggera", atomi: 6)),
                       #"{"archetipo":"fanteria_leggera","atomi":6,"esemplari":1,"protezione":"anti_saturazione"}"#)
        XCTAssertEqual(try testo(Reparto(archetipo: "fanteria_leggera", atomi: 6)),
                       #"{"archetipo":"fanteria_leggera","atomi":6}"#)
        XCTAssertEqual(try testo(Reparto(archetipo: "fanteria_leggera", atomi: 6, miglioramento: Self.addestramento, leva: 2)),
                       #"{"archetipo":"fanteria_leggera","atomi":6,"leva":2,"miglioramento":"addestramento_mirato"}"#)
        let ordinario = try sciame(1, .giocatore, "fanteria_leggera", atomi: 6, migliorato: false)
        XCTAssertFalse(try testo(ordinario).contains("miglioramento"))
        XCTAssertFalse(try testo(ordinario).contains("leva"))
        // Con i campi nuovi, tutto si rilegge uguale.
        let addestrato = try sciame(2, .giocatore, "fanteria_leggera", atomi: 6, migliorato: true)
        XCTAssertEqual(try JSONDecoder().decode(Sciame.self, from: try codificatore.encode(addestrato)), addestrato)
        let nelMazzo = elemento("fanteria_pesante", atomi: 8, migliorato: true, leva: 4)
        XCTAssertEqual(try JSONDecoder().decode(ScenarioBattaglia.ElementoScenario.self, from: try codificatore.encode(nelMazzo)),
                       nelMazzo)
        // Un reparto scritto prima dell'incarico 31 si legge come reparto ordinario.
        let vecchio = try JSONDecoder().decode(Reparto.self, from: Data(#"{"archetipo":"fanteria_leggera","atomi":6}"#.utf8))
        XCTAssertEqual(vecchio, Reparto(archetipo: "fanteria_leggera", atomi: 6))
    }

    func test_incarico_31_F_l_impronta_della_battaglia_distingue_il_reparto_addestrato() throws {
        func stato(migliorato: Bool, leva: Int?) throws -> StatoBattaglia {
            try FabbricaBattaglia.crea(
                scenario: scenario(giocatore: [elemento("fanteria_pesante", atomi: 8, migliorato: migliorato, leva: leva)],
                                   avversario: [elemento("fanteria_leggera", atomi: 6)]), valori: valori).0
        }
        let ordinario = try stato(migliorato: false, leva: nil)
        XCTAssertEqual(try stato(migliorato: false, leva: nil).impronta(), ordinario.impronta())
        XCTAssertNotEqual(try stato(migliorato: true, leva: nil).impronta(), ordinario.impronta())
        XCTAssertNotEqual(try stato(migliorato: false, leva: 2).impronta(), ordinario.impronta())
        XCTAssertNotEqual(try stato(migliorato: true, leva: 2).impronta(), try stato(migliorato: true, leva: 3).impronta())
        // Anche in campo: lo sciame piazzato porta la differenza nell'impronta.
        var inCampoOrdinario = ordinario
        var inCampoAddestrato = try stato(migliorato: true, leva: nil)
        for parte in [Parte.giocatore] {
            esegui(.seleziona(indiceDeck: 0), parte, &inCampoOrdinario)
            esegui(.piazza(cella: Cella(riga: 9, colonna: 5)), parte, &inCampoOrdinario)
            esegui(.seleziona(indiceDeck: 0), parte, &inCampoAddestrato)
            esegui(.piazza(cella: Cella(riga: 9, colonna: 5)), parte, &inCampoAddestrato)
        }
        XCTAssertNotEqual(inCampoAddestrato.impronta(), inCampoOrdinario.impronta())
    }
}
