import XCTest
import Motore
import Dati
import Contenuti

/// La campagna che il regno apre (incarico 30): il calendario con le stagioni, la conclusione nel
/// minimo — annientamento e arrivo dell'inverno (RDA-164) —, e il ponte che porta le forze del regno
/// al fronte e l'esito in patria. Le campagne che non dichiarano un calendario restano com'erano.
final class CampagnaDelRegnoTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    var motore: MotoreCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
    }

    private func reparti(_ atomi: Int = 6) -> [ScenarioCampagna.RepartoIniziale] {
        [.init(archetipo: "fanteria_leggera", atomi: atomi)]
    }

    /// Una campagna sulla mappa grande, con le parti lontane: un gruppo armato per parte, più una
    /// formazione di ricognizione del giocatore. Col calendario, due giornate per stagione.
    private func crea(calendario: CalendarioDiCampagna?) throws -> StatoCampagna {
        try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(
                mappa: "pianura_lunga",
                gruppiGiocatore: [.init(riga: 10, colonna: 5, composizione: reparti()),
                                  .init(riga: 10, colonna: 6, composizione: reparti(3),
                                        categoria: "ricognizione", competenza: 5)],
                gruppiAvversario: [.init(riga: 1, colonna: 5, composizione: reparti())],
                calendario: calendario),
            valori: valoriCampagna, archetipiNoti: Set(valori.archetipi.keys))
    }

    private let dueGiornate = CalendarioDiCampagna(anno: 3, giornatePerStagione: 2)

    /// Chiude una giornata con l'ordine di restare a ogni gruppo delle due parti, come fa la
    /// chiusura esplicita per il giocatore e la condotta per l'avversario fermo.
    private func chiudiUnaGiornata(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        let giorno = stato.giorno
        for gruppo in stato.gruppiOrdinati where stato.giorno == giorno {
            guard let ordine = motore.ordineDiRestare(per: gruppo.id, parte: gruppo.parte, stato: stato) else { continue }
            let (nuovo, ev) = motore.applica(ordine, parte: gruppo.parte, stato: stato)
            stato = nuovo
            eventi += ev
        }
        return eventi
    }

    // MARK: - Il calendario (01 §5.9)

    func test_01_5_9_il_calendario_dice_la_stagione_di_ogni_giornata() {
        let calendario = CalendarioDiCampagna(anno: 1, giornatePerStagione: 30)
        XCTAssertEqual(calendario.ultimaGiornata, 90)
        XCTAssertEqual(calendario.stagione(del: 1), .primavera)
        XCTAssertEqual(calendario.stagione(del: 30), .primavera)
        XCTAssertEqual(calendario.stagione(del: 31), .estate)
        XCTAssertEqual(calendario.stagione(del: 60), .estate)
        XCTAssertEqual(calendario.stagione(del: 61), .autunno)
        XCTAssertEqual(calendario.stagione(del: 90), .autunno)
        XCTAssertEqual(calendario.stagione(del: 91), .inverno, "oltre l'ultima giornata operativa è inverno")
        let data = calendario.data(del: 31)
        XCTAssertEqual(data.anno, 1)
        XCTAssertEqual(data.giorno, 31)
        XCTAssertEqual(data.giornateOperative, 90)
    }

    func test_01_5_17_1_il_cambio_di_stagione_si_annuncia_ed_entra_nel_registro() throws {
        var stato = try crea(calendario: dueGiornate)
        XCTAssertEqual(stato.data?.stagione, .primavera)
        var eventi = chiudiUnaGiornata(&stato)
        XCTAssertEqual(stato.giorno, 2)
        XCTAssertFalse(eventi.contains { if case .stagioneCambiata = $0 { return true } else { return false } },
                       "dalla prima alla seconda giornata la stagione è la stessa")
        eventi = chiudiUnaGiornata(&stato)
        XCTAssertEqual(stato.giorno, 3)
        XCTAssertTrue(eventi.contains(.stagioneCambiata(stagione: .estate)))
        XCTAssertEqual(stato.registro.last?.fatto, .stagioneCambiata(stagione: .estate))
        XCTAssertEqual(stato.registro.last?.giorno, 3, "la voce dichiara il giorno in cui la stagione comincia")
        XCTAssertEqual(stato.data?.stagione, .estate)
    }

    // MARK: - La conclusione per l'arrivo dell'inverno (RDA-164)

    func test_01_5_9_chiusa_l_ultima_giornata_d_autunno_la_campagna_si_conclude_senza_vincitore() throws {
        var stato = try crea(calendario: dueGiornate)
        var tutti: [EventoCampagna] = []
        for _ in 1...6 { tutti += chiudiUnaGiornata(&stato) }
        XCTAssertEqual(stato.conclusione, ConclusioneCampagna(modo: .inverno, vincitore: nil, giorno: 6))
        XCTAssertEqual(tutti.last, .campagnaConclusa(modo: .inverno, vincitore: nil))
        XCTAssertFalse(tutti.contains(.giornataAperta(giorno: 7)),
                       "d'inverno non si conduce campagna: la giornata nuova non si apre")
        XCTAssertEqual(tutti.filter { if case .stagioneCambiata = $0 { return true } else { return false } },
                       [.stagioneCambiata(stagione: .estate), .stagioneCambiata(stagione: .autunno)])

        // Conclusa la campagna, ogni comando è respinto col MEDESIMO motivo, per le due parti.
        for gruppo in stato.gruppiOrdinati {
            XCTAssertEqual(motore.valida(.presidio(gruppo: gruppo.id), parte: gruppo.parte, stato: stato).motivo,
                           .campagnaConclusa)
            XCTAssertEqual(motore.valida(.sostaConRaccolta(gruppo: gruppo.id), parte: gruppo.parte, stato: stato).motivo,
                           .campagnaConclusa)
        }
        // E nulla più avanza: la chiusura esplicita non trova nulla da chiudere.
        let prima = stato
        let (ordini, eventi) = motore.concludiLaGiornataDelGiocatore(&stato)
        XCTAssertTrue(ordini.isEmpty)
        XCTAssertTrue(eventi.isEmpty)
        XCTAssertEqual(stato, prima)
    }

    func test_le_campagne_senza_calendario_restano_senza_stagioni_e_senza_conclusione() throws {
        var stato = try crea(calendario: nil)
        var tutti: [EventoCampagna] = []
        for _ in 1...8 { tutti += chiudiUnaGiornata(&stato) }
        XCTAssertEqual(stato.giorno, 9)
        XCTAssertNil(stato.conclusione)
        XCTAssertNil(stato.data)
        XCTAssertFalse(tutti.contains {
            switch $0 { case .stagioneCambiata, .campagnaConclusa: return true; default: return false }
        })
    }

    func test_l_inverno_attende_la_battaglia_nata_dall_ultima_risoluzione() throws {
        // L'anno operativo è finito, ma una battaglia è in sospeso: la campagna non si conclude
        // finché quella non si conclude (01 §6.4), poi si conclude per l'inverno.
        var stato = try crea(calendario: dueGiornate)
        let mio = try XCTUnwrap(stato.gruppiOrdinati.first { $0.parte == .giocatore && $0.categoria.eArmata })
        let suo = try XCTUnwrap(stato.gruppiOrdinati.first { $0.parte == .avversario })
        stato.gruppi[suo.id]!.posizione = mio.posizione
        stato.giorno = dueGiornate.ultimaGiornata + 1
        stato.battaglieInSospeso = [BattagliaInSospeso(
            identificatore: "battaglia-di-prova", casella: mio.posizione, gruppoGiocatore: mio.id,
            gruppoAvversario: suo.id, primoOccupante: .giocatore, imboscante: nil, giorno: 6)]
        XCTAssertEqual(motore.valida(.presidio(gruppo: mio.id), parte: .giocatore, stato: stato).motivo,
                       .battagliaInSospeso)

        // Sopravvivono entrambi: nessun annientamento, e l'inverno conclude.
        let esito = EsitoInCampagna(
            identificatore: "battaglia-di-prova", casella: mio.posizione, sconfitto: .avversario,
            modo: .ritirataCompiuta, gruppoGiocatore: mio.id, gruppoAvversario: suo.id,
            composizioneGiocatore: [Reparto(archetipo: "fanteria_leggera", atomi: 5)],
            composizioneAvversario: [Reparto(archetipo: "fanteria_leggera", atomi: 2)],
            posizioneGiocatore: mio.posizione, posizioneAvversario: Cella(riga: 9, colonna: 5))
        let eventi = motore.applicaEsitoInCampagna(esito, in: &stato)
        XCTAssertEqual(stato.conclusione, ConclusioneCampagna(modo: .inverno, vincitore: nil, giorno: 6))
        XCTAssertEqual(eventi.last, .campagnaConclusa(modo: .inverno, vincitore: nil))
    }

    // MARK: - La conclusione per annientamento (RDA-164)

    /// Mette in sospeso una battaglia fra i due gruppi armati e ne applica l'esito.
    private func combatti(_ stato: inout StatoCampagna, sopravviveIlGiocatore: Bool,
                          sopravviveLAvversario: Bool) throws -> [EventoCampagna] {
        let mio = try XCTUnwrap(stato.gruppiOrdinati.first { $0.parte == .giocatore && $0.categoria.eArmata })
        let suo = try XCTUnwrap(stato.gruppiOrdinati.first { $0.parte == .avversario })
        stato.gruppi[suo.id]!.posizione = mio.posizione
        stato.battaglieInSospeso = [BattagliaInSospeso(
            identificatore: "battaglia-di-prova", casella: mio.posizione, gruppoGiocatore: mio.id,
            gruppoAvversario: suo.id, primoOccupante: .giocatore, imboscante: nil, giorno: stato.giorno)]
        let esito = EsitoInCampagna(
            identificatore: "battaglia-di-prova", casella: mio.posizione,
            sconfitto: sopravviveIlGiocatore ? .avversario : .giocatore, modo: .annientamento,
            gruppoGiocatore: mio.id, gruppoAvversario: suo.id,
            composizioneGiocatore: sopravviveIlGiocatore ? [Reparto(archetipo: "fanteria_leggera", atomi: 4)] : [],
            composizioneAvversario: sopravviveLAvversario ? [Reparto(archetipo: "fanteria_leggera", atomi: 4)] : [],
            posizioneGiocatore: sopravviveIlGiocatore ? mio.posizione : nil,
            posizioneAvversario: sopravviveLAvversario ? mio.posizione : nil)
        return motore.applicaEsitoInCampagna(esito, in: &stato)
    }

    func test_l_avversario_senza_gruppi_armati_ha_perso_la_campagna() throws {
        var stato = try crea(calendario: dueGiornate)
        let eventi = try combatti(&stato, sopravviveIlGiocatore: true, sopravviveLAvversario: false)
        XCTAssertEqual(stato.conclusione, ConclusioneCampagna(modo: .annientamento, vincitore: .giocatore, giorno: 1))
        XCTAssertEqual(eventi, [.battagliaConclusa(casella: Cella(riga: 10, colonna: 5), giocatoreSconfitto: false),
                                .campagnaConclusa(modo: .annientamento, vincitore: .giocatore)],
                       "la campagna si conclude al ritorno dalla battaglia, senza chiudere la giornata")
        XCTAssertEqual(stato.giorno, 1)
    }

    func test_il_giocatore_senza_gruppi_armati_ha_perso_anche_se_gli_restano_gli_esploratori() throws {
        var stato = try crea(calendario: dueGiornate)
        _ = try combatti(&stato, sopravviveIlGiocatore: false, sopravviveLAvversario: true)
        XCTAssertEqual(stato.conclusione?.vincitore, .avversario)
        XCTAssertEqual(stato.gruppiArmati(di: .giocatore), 0)
        XCTAssertEqual(stato.gruppi(di: .giocatore).count, 1, "la formazione di ricognizione resta, e rientrerà")
    }

    func test_01_15_2_5_l_annientamento_simultaneo_assegna_la_campagna_al_giocatore() throws {
        var stato = try crea(calendario: dueGiornate)
        _ = try combatti(&stato, sopravviveIlGiocatore: false, sopravviveLAvversario: false)
        XCTAssertEqual(stato.conclusione?.vincitore, .giocatore,
                       "il vantaggio nascosto che assegna l'annientamento simultaneo (01 §15.2.5) vale anche qui")
    }

    /// Il vantaggio si spegne dal file anche per la campagna (S28f, chiuso dall'incarico 32): allora vince
    /// l'avversario. Il caso non simultaneo non ne è toccato.
    func test_05_12_5_il_vantaggio_dell_annientamento_simultaneo_si_spegne_anche_in_campagna() throws {
        let copia = FileManager.default.temporaryDirectory.appendingPathComponent("valori-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: copia) }
        try FileManager.default.copyItem(at: Contenuti.valoriDiFabbrica, to: copia)
        let file = copia.appendingPathComponent("vantaggi-nascosti.json")
        var voci = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        voci["annientamento_simultaneo_al_giocatore"] = false
        try JSONSerialization.data(withJSONObject: voci).write(to: file)
        motore = MotoreCampagna(valori: try CaricatoreValori.carica(da: copia), valoriCampagna: valoriCampagna)
        var stato = try crea(calendario: dueGiornate)
        _ = try combatti(&stato, sopravviveIlGiocatore: false, sopravviveLAvversario: false)
        XCTAssertEqual(stato.conclusione?.vincitore, .avversario)
        stato = try crea(calendario: dueGiornate)
        _ = try combatti(&stato, sopravviveIlGiocatore: true, sopravviveLAvversario: false)
        XCTAssertEqual(stato.conclusione?.vincitore, .giocatore)
    }

    func test_senza_calendario_l_annientamento_non_conclude_nulla() throws {
        var stato = try crea(calendario: nil)
        _ = try combatti(&stato, sopravviveIlGiocatore: true, sopravviveLAvversario: false)
        XCTAssertNil(stato.conclusione, "le campagne di prova restano senza conclusione, com'erano")
    }

    // MARK: - L'impronta (05 §2.9)

    func test_05_2_9_l_impronta_distingue_il_calendario_e_la_conclusione() throws {
        let senza = try crea(calendario: nil)
        let con = try crea(calendario: dueGiornate)
        XCTAssertNotEqual(senza.impronta(), con.impronta())
        var conclusa = con
        conclusa.conclusione = ConclusioneCampagna(modo: .inverno, vincitore: nil, giorno: 6)
        XCTAssertNotEqual(con.impronta(), conclusa.impronta())
        XCTAssertNotEqual(con.impronta(),
                          try crea(calendario: CalendarioDiCampagna(anno: 4, giornatePerStagione: 2)).impronta())
    }

    func test_00_15_lo_scenario_senza_calendario_si_codifica_come_prima() throws {
        let scenario = ScenarioCampagna(mappa: "guado", gruppiGiocatore: [.init(riga: 4, colonna: 2, composizione: reparti())])
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = [.sortedKeys]
        let testo = String(data: try codificatore.encode(scenario), encoding: .utf8)!
        XCTAssertFalse(testo.contains("calendario"), "il campo nullo si omette: i giornali scritti prima restano identici")
        let conCalendario = ScenarioCampagna(mappa: "guado", gruppiGiocatore: scenario.gruppiGiocatore,
                                             calendario: dueGiornate)
        let ricodificato = try JSONDecoder().decode(ScenarioCampagna.self, from: try codificatore.encode(conCalendario))
        XCTAssertEqual(ricodificato.calendario, dueGiornate)
        XCTAssertThrowsError(try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: "guado", gruppiGiocatore: scenario.gruppiGiocatore,
                                       calendario: CalendarioDiCampagna(anno: 1, giornatePerStagione: 0)),
            valori: valoriCampagna, archetipiNoti: Set(valori.archetipi.keys))) {
            XCTAssertEqual($0 as? FabbricaCampagna.ErroreScenario, .calendarioIncoerente)
        }
    }

    // MARK: - Il ponte fra regno e campagna (RDA-162, RDA-166)

    private func scenarioDiFabbrica(_ nome: String) throws -> ScenarioCampagna {
        let dati = try Data(contentsOf: Contenuti.valoriDiFabbrica.appendingPathComponent("scenari-campagna.json"))
        return try XCTUnwrap(try JSONDecoder().decode([String: ScenarioCampagna].self, from: dati)[nome])
    }

    private func forzeDiFabbrica() throws -> ForzeDelRegno {
        let regno = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica, archetipiNoti: Set(valori.archetipi.keys),
                                               miglioramentiNoti: Set(valori.miglioramenti.keys))
        return try ForzeDelRegno.iniziali(regno.forzeIniziali, nomi: regno.nomiDelleUnita)
    }

    func test_sul_fronte_dell_istmo_il_primo_anno_e_lo_scenario_di_oggi_col_calendario() throws {
        let base = try scenarioDiFabbrica("campagna_media")
        let scenario = try PonteRegnoCampagna.scenario(delFronte: base, forze: try forzeDiFabbrica(),
                                                       calendario: dueGiornate, valori: valoriCampagna)
        // Le forze iniziali del regno sono quelle dello scenario medio, nelle stesse caselle; dall'incarico
        // 31 ciascun gruppo porta in più il NOME della propria formazione, che è l'unica differenza.
        let nomi = ["corvo", "lupo", "falco", "orso", "cervo"]
        XCTAssertEqual(base.gruppiGiocatore.count, nomi.count)
        let attesi = zip(base.gruppiGiocatore, nomi).map { gruppo, nome in
            ScenarioCampagna.GruppoIniziale(riga: gruppo.riga, colonna: gruppo.colonna, composizione: gruppo.composizione,
                                            categoria: gruppo.categoria, competenza: gruppo.competenza,
                                            carico: gruppo.carico, sogliaProtezione: gruppo.sogliaProtezione,
                                            nome: nome)
        }
        XCTAssertEqual(scenario.gruppiGiocatore, attesi,
                       "le forze iniziali del regno sono quelle dello scenario medio, nelle stesse caselle")
        XCTAssertEqual(scenario.gruppiAvversario, base.gruppiAvversario)
        XCTAssertTrue(scenario.nomiRiservati.isEmpty, "nessuna formazione resta in patria")
        XCTAssertTrue(scenario.arrivi.isEmpty, "il primo anno non ci sono reclute")
        XCTAssertEqual(scenario.mappa, base.mappa)
        XCTAssertEqual(scenario.calendario, dueGiornate)
        // E lo stato nasce senza che la fabbrica rifiuti nulla.
        let stato = try FabbricaCampagna.crea(scenario: scenario, valori: valoriCampagna,
                                              archetipiNoti: Set(valori.archetipi.keys))
        XCTAssertEqual(stato.calendario, dueGiornate)
        XCTAssertEqual(stato.gruppiOrdinati.filter { $0.parte == .giocatore }.map(\.nome), nomi,
                       "sul fronte i gruppi portano il nome della formazione")
    }

    func test_le_formazioni_in_piu_occupano_le_caselle_libere_piu_vicine_al_quartier_generale() throws {
        // Sul fronte del guado lo scenario assegna quattro caselle; il regno ha cinque formazioni.
        let base = try scenarioDiFabbrica("campagna_piccola")
        let forze = try forzeDiFabbrica()
        let scenario = try PonteRegnoCampagna.scenario(delFronte: base, forze: forze,
                                                       calendario: dueGiornate, valori: valoriCampagna)
        XCTAssertEqual(scenario.gruppiGiocatore.count, forze.formazioni.count, "partono tutte")
        XCTAssertEqual(Array(scenario.gruppiGiocatore.map(\.casella).prefix(4)), base.gruppiGiocatore.map(\.casella))
        let stato = try FabbricaCampagna.crea(scenario: scenario, valori: valoriCampagna,
                                              archetipiNoti: Set(valori.archetipi.keys))
        let quinta = scenario.gruppiGiocatore[4].casella
        let qg = stato.mappa.quartierGenerale(di: .giocatore)
        let libere = stato.griglia.tutteLeCaselle.filter { !base.gruppiGiocatore.map(\.casella).contains($0) }
        let minima = try XCTUnwrap(libere.map { stato.griglia.distanza(qg, $0) }.min())
        XCTAssertEqual(stato.griglia.distanza(qg, quinta), minima)
        XCTAssertEqual(Set(scenario.gruppiGiocatore.map(\.casella)).count, 5, "nessuna casella due volte")
        // Le categorie e le composizioni passano intatte, nell'ordine del regno.
        XCTAssertEqual(scenario.gruppiGiocatore.map(\.categoria),
                       ["armato", "armato", "armato", "ricognizione", "non_armata"])
        XCTAssertEqual(scenario.gruppiGiocatore[3].competenza, 5)
        XCTAssertEqual(scenario.gruppiGiocatore[4].carico, 4)
    }

    func test_le_formazioni_oltre_il_tetto_confluiscono_nell_armata_che_le_precede() throws {
        // Dall'incarico 31 ogni formazione porta un nome della lista chiusa, sicché il regno non ne
        // può avere più dei nomi: le trenta formazioni anonime della prima tappa non esistono più.
        // Qui sono quante la lista ne ammette — ventiquattro —, più delle caselle del guado e più
        // dei nomi che restano una volta dati i suoi all'avversario.
        let nomi = valoriCampagna.nomiGruppi
        XCTAssertEqual(nomi.count, 24)
        let troppe = ForzeDelRegno.sciami(formazioni: nomi.map {
            FormazioneDelRegno(nome: $0, categoria: .armato, composizione: [Reparto(archetipo: "fanteria_leggera", atomi: 2)])
        }, prossimoNome: 0)
        func atomi(_ scenario: ScenarioCampagna) -> Int {
            scenario.gruppiGiocatore.reduce(0) { $0 + $1.composizione.reduce(0) { $0 + $1.atomi } }
        }

        // Sul guado il tetto è delle caselle: sedici.
        let base = try scenarioDiFabbrica("campagna_piccola")
        let scenario = try PonteRegnoCampagna.scenario(delFronte: base, forze: troppe,
                                                       calendario: dueGiornate, valori: valoriCampagna)
        let tetto = min(valoriCampagna.nomiGruppi.count - base.gruppiAvversario.count, 16)
        XCTAssertEqual(scenario.gruppiGiocatore.count, tetto)
        XCTAssertEqual(atomi(scenario), 48, "nessuna forza resta in patria")
        XCTAssertEqual(scenario.gruppiGiocatore.map(\.nome), Array(nomi.prefix(tetto)),
                       "restano le prime, col loro nome: le armate in eccesso confluiscono in quella che le precede")
        XCTAssertEqual(scenario.gruppiGiocatore.last?.composizione.count, nomi.count - tetto + 1,
                       "l'ultima armata rimasta porta i reparti di tutte quelle confluite")
        XCTAssertNoThrow(try FabbricaCampagna.crea(scenario: scenario, valori: valoriCampagna,
                                                   archetipiNoti: Set(valori.archetipi.keys)))

        // Sulla pianura lunga le caselle bastano, e il tetto è dei nomi: quelli della lista meno
        // quelli che servono all'avversario.
        let grande = try scenarioDiFabbrica("campagna_grande")
        let scenarioGrande = try PonteRegnoCampagna.scenario(delFronte: grande, forze: troppe,
                                                             calendario: dueGiornate, valori: valoriCampagna)
        XCTAssertEqual(scenarioGrande.gruppiGiocatore.count, nomi.count - grande.gruppiAvversario.count)
        XCTAssertEqual(atomi(scenarioGrande), 48, "nessuna forza resta in patria")
        XCTAssertEqual(Set(scenarioGrande.gruppiGiocatore.map(\.casella)).count, scenarioGrande.gruppiGiocatore.count,
                       "nessuna casella due volte")
        XCTAssertNoThrow(try FabbricaCampagna.crea(scenario: scenarioGrande, valori: valoriCampagna,
                                                   archetipiNoti: Set(valori.archetipi.keys)))
    }

    func test_il_ponte_rifiuta_cio_che_non_puo_diventare_una_campagna() throws {
        let base = try scenarioDiFabbrica("campagna_piccola")
        let soloEsploratori = ForzeDelRegno.sciami(formazioni: [FormazioneDelRegno(
            nome: "corvo", categoria: .ricognizione(competenza: 5),
            composizione: [Reparto(archetipo: "fanteria_leggera", atomi: 3)])], prossimoNome: 1)
        XCTAssertThrowsError(try PonteRegnoCampagna.scenario(delFronte: base, forze: soloEsploratori,
                                                             calendario: dueGiornate, valori: valoriCampagna)) {
            XCTAssertEqual($0 as? PonteRegnoCampagna.Errore, .nessunaFormazioneArmata)
        }
        let senzaNemico = ScenarioCampagna(mappa: "guado", gruppiGiocatore: base.gruppiGiocatore)
        XCTAssertThrowsError(try PonteRegnoCampagna.scenario(delFronte: senzaNemico, forze: try forzeDiFabbrica(),
                                                             calendario: dueGiornate, valori: valoriCampagna)) {
            XCTAssertEqual($0 as? PonteRegnoCampagna.Errore, .fronteSenzaAvversarioArmato)
        }
    }

    func test_l_esito_porta_al_regno_il_modo_le_battaglie_e_chi_rientra() throws {
        var stato = try crea(calendario: dueGiornate)
        XCTAssertNil(PonteRegnoCampagna.esito(da: stato, fronte: "pianura_lunga"), "una campagna in corso non ha esito")
        _ = try combatti(&stato, sopravviveIlGiocatore: true, sopravviveLAvversario: false)
        let esito = try XCTUnwrap(PonteRegnoCampagna.esito(da: stato, fronte: "pianura_lunga"))
        XCTAssertEqual(esito.fronte, "pianura_lunga")
        XCTAssertEqual(esito.anno, 3)
        XCTAssertEqual(esito.modo, .annientamento)
        XCTAssertEqual(esito.vincitore, .giocatore)
        XCTAssertEqual(esito.giornate, 1)
        XCTAssertEqual(esito.battaglieVinte, 1)
        XCTAssertEqual(esito.battagliePerse, 0)
        // Rientrano i gruppi com'erano alla conclusione, e dall'incarico 31 col NOME che portavano
        // sul fronte: qui i primi due della lista, che la fabbrica ha dato ai gruppi di una campagna
        // senza nomi dichiarati.
        XCTAssertEqual(esito.superstiti, .sciami(formazioni: [
            FormazioneDelRegno(nome: "corvo", categoria: .armato,
                               composizione: [Reparto(archetipo: "fanteria_leggera", atomi: 4)]),
            FormazioneDelRegno(nome: "lupo", categoria: .ricognizione(competenza: 5),
                               composizione: [Reparto(archetipo: "fanteria_leggera", atomi: 3)]),
        ], prossimoNome: 0), "rientrano i gruppi com'erano alla conclusione: i caduti no")
        XCTAssertNil(PonteRegnoCampagna.esito(da: try crea(calendario: nil), fronte: "pianura_lunga"))
    }
}
