import XCTest
import Motore
import Dati
import Contenuti

/// La presa del quartier generale e il richiamo dell'esercito (01 §5.18.2, §5.18.3; incarico 32): la regola
/// sullo stato, per le due parti, e la condotta dell'avversario che la usa e se ne difende.
final class PresaDelQuartierGeneraleTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    var motore: MotoreCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
    }

    // MARK: - Attrezzi

    /// Sul guado il quartier generale del giocatore è in riga 4, casella 2, quello avversario in riga 1.
    private let mio = Cella(riga: 4, colonna: 2)
    private let suo = Cella(riga: 1, colonna: 2)
    private let trentaGiornate = CalendarioDiCampagna(anno: 1, giornatePerStagione: 30)
    private let treGiornate = RegoleDiCampagna(giornatePerLaPresa: 3)

    private func reparti(_ atomi: Int = 6) -> [ScenarioCampagna.RepartoIniziale] {
        [.init(archetipo: "fanteria_leggera", atomi: atomi)]
    }
    private func armato(_ riga: Int, _ colonna: Int, _ atomi: Int = 6) -> ScenarioCampagna.GruppoIniziale {
        .init(riga: riga, colonna: colonna, composizione: reparti(atomi))
    }

    private func crea(_ giocatore: [ScenarioCampagna.GruppoIniziale], _ avversario: [ScenarioCampagna.GruppoIniziale],
                      regole: RegoleDiCampagna? = RegoleDiCampagna(giornatePerLaPresa: 3),
                      calendario: CalendarioDiCampagna? = CalendarioDiCampagna(anno: 1, giornatePerStagione: 30),
                      fortezze: [Fortezza] = [], mappa: IdentificatoreDati = "guado") throws -> StatoCampagna {
        try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: mappa, gruppiGiocatore: giocatore, gruppiAvversario: avversario,
                                       calendario: calendario, regole: regole, fortezze: fortezze),
            valori: valoriCampagna, archetipiNoti: Set(valori.archetipi.keys))
    }

    /// Chiude una giornata con l'ordine di restare a ogni gruppo delle due parti.
    @discardableResult
    private func chiudi(_ stato: inout StatoCampagna, _ giornate: Int = 1) -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        for _ in 0..<giornate {
            let giorno = stato.giorno
            for gruppo in stato.gruppiOrdinati where stato.giorno == giorno && stato.conclusione == nil {
                guard stato.gruppi[gruppo.id]?.haConclusoLaGiornata == false,
                      let ordine = motore.ordineDiRestare(per: gruppo.id, parte: gruppo.parte, stato: stato) else { continue }
                let (nuovo, ev) = motore.applica(ordine, parte: gruppo.parte, stato: stato)
                stato = nuovo
                eventi += ev
            }
        }
        return eventi
    }

    private func gruppo(_ parte: Parte, _ stato: StatoCampagna, _ indice: Int = 0) -> Gruppo {
        stato.gruppiOrdinati.filter { $0.parte == parte }[indice]
    }

    private func ordina(_ comando: ComandoCampagna, _ parte: Parte, _ stato: inout StatoCampagna,
                        file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(motore.valida(comando, parte: parte, stato: stato).motivo, nil, file: file, line: line)
        (stato, _) = motore.applica(comando, parte: parte, stato: stato)
    }

    private func marcia(_ gruppo: Gruppo, a casella: Cella, _ stato: inout StatoCampagna,
                        file: StaticString = #filePath, line: UInt = #line) {
        ordina(.marcia(gruppo: gruppo.id, a: casella,
                       giorni: motore.costoInGiorni(da: gruppo.posizione, a: casella, parte: gruppo.parte, stato: stato)),
               gruppo.parte, &stato, file: file, line: line)
    }

    private func occupazioni(_ eventi: [EventoCampagna]) -> [EventoCampagna] {
        eventi.filter {
            switch $0 {
            case .quartierGeneraleOccupato, .occupazioneProsegue, .occupazioneInterrotta, .quartierGeneralePreso,
                 .campagnaConclusa: return true
            default: return false
            }
        }
    }

    /// La battaglia in sospeso conclusa con l'esito dato; chi perde, se sopravvive, ripiega dove si dice.
    private func combatti(_ stato: inout StatoCampagna, perde: Parte, ripiegaIn ritiro: Cella? = nil) throws -> [EventoCampagna] {
        let battaglia = try XCTUnwrap(stato.battaglieInSospeso.first)
        let g = try XCTUnwrap(stato.gruppi[battaglia.gruppoGiocatore]), a = try XCTUnwrap(stato.gruppi[battaglia.gruppoAvversario])
        func dopo(_ parte: Parte, _ gruppo: Gruppo) -> ([Reparto], Cella?) {
            if parte != perde { return (gruppo.composizione, battaglia.casella) }
            return ritiro == nil ? ([], nil) : (gruppo.composizione, ritiro)
        }
        let (cg, pg) = dopo(.giocatore, g), (ca, pa) = dopo(.avversario, a)
        return motore.applicaEsitoInCampagna(EsitoInCampagna(
            identificatore: battaglia.identificatore, casella: battaglia.casella, sconfitto: perde,
            modo: ritiro == nil ? .annientamento : .ritirataCompiuta,
            gruppoGiocatore: g.id, gruppoAvversario: a.id, composizioneGiocatore: cg, composizioneAvversario: ca,
            posizioneGiocatore: pg, posizioneAvversario: pa), in: &stato)
    }

    // MARK: - Il conteggio (01 §5.18.3.1)

    /// La chiusura in cui il gruppo entra comincia l'occupazione e non conta; ciascuna delle tre seguenti
    /// conta, e alla terza il quartier generale cade: la campagna è conclusa e vinta da chi l'ha preso.
    func test_01_5_18_3_il_quartier_generale_cade_dopo_le_giornate_della_regola_per_le_due_parti() throws {
        for (chi, casella, iniziale) in [(Parte.giocatore, suo, try crea([armato(2, 2)], [armato(1, 4)])),
                                         (Parte.avversario, mio, try crea([armato(4, 4)], [armato(3, 2)]))] {
            var stato = iniziale
            XCTAssertNil(stato.occupazione(di: casella))
            // Entra: marcia sul quartier generale dell'altra parte.
            let entrante = gruppo(chi, stato)
            marcia(entrante, a: casella, &stato)
            var eventi: [EventoCampagna] = []
            while stato.gruppi[entrante.id]!.posizione != casella { eventi = chiudi(&stato) }
            XCTAssertEqual(occupazioni(eventi), [.quartierGeneraleOccupato(casella: casella, occupante: chi, mancano: 3)])
            XCTAssertEqual(stato.occupazioni, [OccupazioneDelQuartierGenerale(casella: casella, occupante: chi, giornate: 0)])
            let giornoDelPrimo = stato.giorno
            XCTAssertEqual(occupazioni(chiudi(&stato)), [.occupazioneProsegue(casella: casella, occupante: chi, mancano: 2)])
            XCTAssertEqual(occupazioni(chiudi(&stato)), [.occupazioneProsegue(casella: casella, occupante: chi, mancano: 1)])
            XCTAssertNil(stato.conclusione)
            eventi = chiudi(&stato)
            XCTAssertEqual(occupazioni(eventi), [.campagnaConclusa(modo: .presa, vincitore: chi)])
            XCTAssertEqual(stato.conclusione, ConclusioneCampagna(modo: .presa, vincitore: chi, giorno: giornoDelPrimo + 2))
            XCTAssertEqual(stato.quartieriGeneraliPresi, [casella])
            XCTAssertEqual(stato.occupazioni, [])
            XCTAssertEqual(stato.giorno, giornoDelPrimo + 2, "la giornata nuova non si apre")
            XCTAssertFalse(eventi.contains { if case .giornataAperta = $0 { return true } else { return false } })
            // Conclusa, ogni comando è respinto col medesimo motivo.
            for g in stato.gruppiOrdinati {
                XCTAssertEqual(motore.valida(.presidio(gruppo: g.id), parte: g.parte, stato: stato).motivo, .campagnaConclusa)
            }
        }
    }

    /// Le giornate sono quelle della regola che la campagna porta con sé, qualunque sia il valore.
    func test_01_5_18_3_le_giornate_sono_quelle_che_la_campagna_dichiara() throws {
        for giornate in [1, 2, 5] {
            var stato = try crea([armato(1, 2)], [armato(1, 4)], regole: RegoleDiCampagna(giornatePerLaPresa: giornate))
            chiudi(&stato) // comincia
            XCTAssertEqual(stato.occupazioni?.first?.giornate, 0)
            for n in 1..<max(giornate, 1) {
                chiudi(&stato)
                XCTAssertEqual(stato.occupazioni?.first?.giornate, n)
                XCTAssertNil(stato.conclusione)
            }
            chiudi(&stato)
            XCTAssertEqual(stato.conclusione?.modo, .presa, "\(giornate)")
        }
    }

    /// Una campagna che non dichiara la regola — le campagne di prova, e quelle nate con la build 32 — non
    /// conosce la presa: nessun conteggio, nessun evento, nessuna conclusione.
    func test_incarico_32_senza_la_regola_nulla_cambia() throws {
        var stato = try crea([armato(1, 2)], [armato(1, 4)], regole: nil)
        let eventi = chiudi(&stato, 8)
        XCTAssertEqual(occupazioni(eventi), [])
        XCTAssertNil(stato.occupazioni)
        XCTAssertNil(stato.conclusione)
        XCTAssertEqual(stato.giorno, 9)
    }

    /// Soltanto un gruppo ARMATO occupa: la ricognizione e le formazioni non armate no.
    func test_01_5_18_3_la_ricognizione_e_le_non_armate_non_occupano() throws {
        for categoria in [("ricognizione", 5, nil, nil), ("non_armata", nil, 4, 2)] as [(String, Int?, Int?, Int?)] {
            var stato = try crea([armato(4, 1), .init(riga: 1, colonna: 2, composizione: reparti(3), categoria: categoria.0,
                                                      competenza: categoria.1, carico: categoria.2, sogliaProtezione: categoria.3)],
                                 [armato(1, 4)])
            XCTAssertEqual(occupazioni(chiudi(&stato, 5)), [], categoria.0)
            XCTAssertNil(stato.conclusione)
        }
    }

    // MARK: - L'azzeramento (01 §5.18.3.2)

    /// Chi lascia la casella azzera il conteggio; se vi torna ricomincia da capo.
    func test_01_5_18_3_2_lasciata_la_casella_il_conteggio_si_azzera_e_ricomincia_da_capo() throws {
        var stato = try crea([armato(1, 2)], [armato(1, 4)])
        chiudi(&stato, 3)
        XCTAssertEqual(stato.occupazioni?.first?.giornate, 2, "ne manca una")
        let io = gruppo(.giocatore, stato)
        let fuori = Cella(riga: 1, colonna: 1)
        marcia(io, a: fuori, &stato)
        var eventi: [EventoCampagna] = []
        var tutti: [EventoCampagna] = []
        while stato.gruppi[io.id]!.posizione == suo, stato.conclusione == nil {
            eventi = chiudi(&stato)
            tutti += eventi
        }
        if stato.conclusione == nil {
            XCTAssertEqual(occupazioni(eventi), [.occupazioneInterrotta(casella: suo, occupante: .giocatore)])
            XCTAssertEqual(stato.occupazioni, [])
            XCTAssertFalse(stato.registro.contains { $0.fatto.chiaveTesto.hasPrefix("registro.quartier") },
                           "la propria occupazione non è un fatto da annotare: la si è decisa")
            marcia(gruppo(.giocatore, stato), a: suo, &stato)
            while stato.gruppi[io.id]!.posizione != suo { eventi = chiudi(&stato) }
            XCTAssertEqual(occupazioni(eventi), [.quartierGeneraleOccupato(casella: suo, occupante: .giocatore, mancano: 3)])
        } else {
            XCTFail("la marcia verso la casella accanto dura più di una giornata, e il quartier generale cade prima")
        }
    }

    /// Finché la marcia d'uscita non si compie il gruppo è ancora sulla casella, e la giornata conta.
    func test_01_5_18_3_2_chi_sta_per_uscire_occupa_ancora_finche_non_e_uscito() throws {
        var stato = try crea([armato(1, 2)], [armato(1, 4)])
        chiudi(&stato, 1)
        let io = gruppo(.giocatore, stato)
        stato.gruppi[io.id]!.marcia = MarciaInCorso(destinazione: Cella(riga: 1, colonna: 1), giorniTotali: 5, giorniCompiuti: 0)
        XCTAssertEqual(occupazioni(chiudi(&stato)), [.occupazioneProsegue(casella: suo, occupante: .giocatore, mancano: 2)])
    }

    /// Il difensore torna: la battaglia nasce sul quartier generale, la giornata contesa non conta e non
    /// azzera; se l'occupante la perde il conteggio si azzera, se la vince riprende da dov'era.
    func test_01_5_18_3_2_il_difensore_che_torna_e_vince_azzera_e_se_perde_il_conteggio_riprende() throws {
        for vinceIlDifensore in [true, false] {
            var stato = try crea([armato(3, 2)], [armato(4, 2), armato(1, 4)])
            chiudi(&stato)
            XCTAssertEqual(stato.occupazioni, [OccupazioneDelQuartierGenerale(casella: mio, occupante: .avversario, giornate: 0)])
            // Il difensore, accanto, torna subito a riprenderselo: l'occupante gli taglia il rifornimento
            // (01 §5.2.2.2), e il giorno dopo dovrebbe fermarsi.
            let io = gruppo(.giocatore, stato)
            marcia(io, a: mio, &stato)
            var eventi: [EventoCampagna] = []
            var giornateInAttesa = 0
            while stato.battaglieInSospeso.isEmpty, stato.conclusione == nil { eventi = chiudi(&stato); giornateInAttesa += 1 }
            XCTAssertNil(stato.conclusione)
            let prima = try XCTUnwrap(stato.occupazioni?.first).giornate
            XCTAssertTrue(eventi.contains(.battagliaInnescata(casella: mio, daImboscata: false)))
            XCTAssertEqual(occupazioni(eventi), [], "la giornata contesa non conta e non azzera")
            XCTAssertEqual(prima, giornateInAttesa - 1)
            let esito = try combatti(&stato, perde: vinceIlDifensore ? .avversario : .giocatore, ripiegaIn: Cella(riga: 3, colonna: 1))
            if vinceIlDifensore {
                XCTAssertEqual(occupazioni(esito).first, .occupazioneInterrotta(casella: mio, occupante: .avversario))
                XCTAssertEqual(stato.occupazioni, [])
                XCTAssertTrue(stato.registro.map(\.fatto).contains(.quartierGeneraleLiberato(casella: mio)))
            } else {
                XCTAssertEqual(occupazioni(esito).filter { if case .occupazioneInterrotta = $0 { return true } else { return false } }, [])
                XCTAssertEqual(stato.occupazioni?.first?.casella, mio)
                let seguito = stato.occupazioni!.first!.giornate
                XCTAssertGreaterThanOrEqual(seguito, prima, "riprende da dov'era")
            }
        }
    }

    /// Il difensore battuto sul proprio quartier generale, che è in ultima riga, può non avere una casella
    /// in cui ripiegare, e resta lì (S25a). Non per questo scaccia chi l'ha battuto: il conteggio comincia e
    /// prosegue. Se invece è l'attaccante a perdere e a restare, non occupa nulla.
    func test_01_5_18_3_2_il_difensore_battuto_che_non_puo_ripiegare_non_ferma_il_conteggio() throws {
        for perde in Parte.allCases {
            var stato = try crea([armato(4, 2)], [armato(3, 2), armato(1, 4)])
            marcia(gruppo(.avversario, stato), a: mio, &stato)
            while stato.battaglieInSospeso.isEmpty { chiudi(&stato) }
            let esito = try combatti(&stato, perde: perde, ripiegaIn: mio)
            XCTAssertEqual(stato.gruppi.values.filter { $0.posizione == mio }.count, 2, "stanno fronte a fronte")
            if perde == .giocatore {
                XCTAssertEqual(occupazioni(esito).first, .quartierGeneraleOccupato(casella: mio, occupante: .avversario, mancano: 3))
                var tutti = occupazioni(esito)
                while stato.conclusione == nil, stato.giorno < 12 { tutti += occupazioni(chiudi(&stato)) }
                XCTAssertEqual(stato.conclusione?.modo, .presa)
                XCTAssertEqual(stato.conclusione?.vincitore, .avversario)
            } else {
                XCTAssertEqual(occupazioni(esito), [])
                XCTAssertEqual(occupazioni(chiudi(&stato, 5)), [], "l'attaccante battuto non occupa, finché il difensore vi sta")
                XCTAssertNil(stato.conclusione)
            }
        }
    }

    /// L'occupante battuto che non ha una casella in cui ripiegare resta nel quartier generale, ma non lo
    /// occupa più: il conteggio si azzera lo stesso, e non ricomincia finché il difensore vi sta.
    func test_01_5_18_3_2_l_occupante_battuto_che_non_puo_ripiegare_perde_comunque_il_conteggio() throws {
        var stato = try crea([armato(3, 2), armato(1, 4)], [armato(4, 2), armato(1, 1)])
        chiudi(&stato)
        let difensore = try XCTUnwrap(stato.gruppiOrdinati.first { $0.parte == .giocatore && $0.posizione == Cella(riga: 3, colonna: 2) })
        marcia(difensore, a: mio, &stato)
        var giri = 0
        while stato.battaglieInSospeso.isEmpty, stato.conclusione == nil, giri < 4 { chiudi(&stato); giri += 1 }
        XCTAssertNotNil(stato.occupazione(di: mio), "contesa, l'occupazione dura")
        let esito = try combatti(&stato, perde: .avversario, ripiegaIn: mio)
        XCTAssertEqual(stato.gruppi.values.filter { $0.posizione == mio }.count, 2, "stanno fronte a fronte")
        XCTAssertEqual(occupazioni(esito).first, .occupazioneInterrotta(casella: mio, occupante: .avversario))
        XCTAssertNil(stato.occupazione(di: mio))
        XCTAssertTrue(stato.registro.map(\.fatto).contains(.quartierGeneraleLiberato(casella: mio)))
        XCTAssertEqual(occupazioni(chiudi(&stato, 4)), [], "battuto, non occupa finché il difensore vi sta")
        XCTAssertNil(stato.conclusione)
    }

    /// Chi entra in un quartier generale difeso combatte: se vince, l'occupazione comincia lì, al ritorno
    /// dalla battaglia.
    func test_01_5_18_3_2_vinta_la_battaglia_contro_il_difensore_comincia_l_occupazione() throws {
        var stato = try crea([armato(2, 2), armato(4, 4)], [armato(1, 2), armato(1, 4)])
        marcia(gruppo(.giocatore, stato), a: suo, &stato)
        var eventi: [EventoCampagna] = []
        while stato.battaglieInSospeso.isEmpty { eventi = chiudi(&stato) }
        XCTAssertEqual(occupazioni(eventi), [], "contesa: l'occupazione non comincia finché il difensore vi sta")
        XCTAssertNil(stato.occupazione(di: suo))
        let esito = try combatti(&stato, perde: .avversario, ripiegaIn: Cella(riga: 1, colonna: 1))
        XCTAssertEqual(occupazioni(esito).first, .quartierGeneraleOccupato(casella: suo, occupante: .giocatore, mancano: 3))
    }

    /// La riunione che porta altrove l'occupante lascia il quartier generale subito.
    func test_01_5_18_3_2_riunito_altrove_l_occupante_lascia_il_quartier_generale() throws {
        var stato = try crea([armato(1, 2, 3), armato(1, 1, 9)], [armato(1, 4)])
        chiudi(&stato, 2)
        XCTAssertEqual(stato.occupazioni?.first?.giornate, 1)
        let (occupante, altro) = (gruppo(.giocatore, stato, 0), gruppo(.giocatore, stato, 1))
        let (nuovo, eventi) = motore.applica(.riunione(gruppo: altro.id, con: occupante.id), parte: .giocatore, stato: stato)
        XCTAssertEqual(nuovo.gruppiOrdinati.filter { $0.parte == .giocatore }.map(\.posizione), [Cella(riga: 1, colonna: 1)])
        XCTAssertEqual(occupazioni(eventi), [.occupazioneInterrotta(casella: suo, occupante: .giocatore)])
        XCTAssertEqual(nuovo.occupazioni, [])
    }

    // MARK: - La conclusione (01 §5.18.3.4)

    /// Chiusa l'ultima giornata dell'anno, chi completa la presa vince: l'inverno arriva dopo.
    func test_01_5_18_3_4_la_presa_che_si_compie_nell_ultima_giornata_vince_sull_inverno() throws {
        var stato = try crea([armato(1, 2)], [armato(1, 4)], regole: RegoleDiCampagna(giornatePerLaPresa: 2),
                             calendario: CalendarioDiCampagna(anno: 1, giornatePerStagione: 1))
        XCTAssertEqual(stato.calendario?.ultimaGiornata, 3)
        chiudi(&stato, 3)
        XCTAssertEqual(stato.conclusione, ConclusioneCampagna(modo: .presa, vincitore: .giocatore, giorno: 3))
        // Con una giornata in più da tenere l'inverno arriva prima.
        stato = try crea([armato(1, 2)], [armato(1, 4)], calendario: CalendarioDiCampagna(anno: 1, giornatePerStagione: 1))
        chiudi(&stato, 3)
        XCTAssertEqual(stato.conclusione, ConclusioneCampagna(modo: .inverno, vincitore: nil, giorno: 3))
    }

    /// Se nella stessa chiusura cadono gli ultimi quartieri generali di entrambi vince il giocatore, come
    /// nell'annientamento simultaneo (01 §15.2.5).
    func test_01_15_2_5_caduti_insieme_gli_ultimi_quartieri_generali_vince_il_giocatore() throws {
        var stato = try crea([armato(1, 2)], [armato(4, 2)])
        let eventi = chiudi(&stato, 4)
        XCTAssertEqual(stato.conclusione?.vincitore, .giocatore)
        XCTAssertEqual(occupazioni(eventi).last, .campagnaConclusa(modo: .presa, vincitore: .giocatore))
        XCTAssertEqual(stato.quartieriGeneraliPresi, [suo])
    }

    /// È un vantaggio nascosto (01 §13.2), e la voce di dati che governa l'annientamento simultaneo lo spegne
    /// (05 §12.5): allora vince l'avversario.
    func test_05_12_5_il_vantaggio_della_caduta_simultanea_e_disattivabile() throws {
        let copia = FileManager.default.temporaryDirectory.appendingPathComponent("valori-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: copia) }
        try FileManager.default.copyItem(at: Contenuti.valoriDiFabbrica, to: copia)
        let file = copia.appendingPathComponent("vantaggi-nascosti.json")
        var voci = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        voci["annientamento_simultaneo_al_giocatore"] = false
        try JSONSerialization.data(withJSONObject: voci).write(to: file)
        let spento = MotoreCampagna(valori: try CaricatoreValori.carica(da: copia), valoriCampagna: valoriCampagna)
        XCTAssertTrue(motore.valori.vantaggi.annientamentoSimultaneoAlGiocatore, "di fabbrica è acceso")
        let acceso = motore
        motore = spento
        defer { motore = acceso }
        var stato = try crea([armato(1, 2)], [armato(4, 2)])
        chiudi(&stato, 4)
        XCTAssertEqual(stato.conclusione, ConclusioneCampagna(modo: .presa, vincitore: .avversario, giorno: 4))
    }

    /// Una battaglia rimasta in sospeso altrove non si combatte più: la campagna è finita.
    func test_01_5_18_3_4_la_caduta_dell_ultimo_quartier_generale_chiude_anche_le_battaglie_in_sospeso() throws {
        var stato = try crea([armato(1, 2), armato(3, 4)], [armato(2, 4)])
        chiudi(&stato, 3)
        XCTAssertEqual(stato.occupazioni?.first?.giornate, 2)
        // Alla chiusura che compie la presa, altrove nasce una battaglia.
        let secondo = gruppo(.giocatore, stato, 1), nemico = gruppo(.avversario, stato)
        stato.gruppi[secondo.id]!.marcia = MarciaInCorso(destinazione: nemico.posizione, giorniTotali: 1, giorniCompiuti: 0)
        stato.gruppi[secondo.id]!.azioneSpesa = true
        chiudi(&stato)
        XCTAssertEqual(stato.conclusione?.modo, .presa)
        XCTAssertEqual(stato.battaglieInSospeso, [])
    }

    /// Dove c'è una fortezza vanno presi tutti e due (01 §5.14.3.2): la prima caduta è un fatto, la seconda
    /// conclude la campagna. Un quartier generale preso resta preso.
    func test_01_5_14_3_2_con_una_fortezza_vanno_presi_tutti_e_due_i_quartieri_generali() throws {
        let fortezza = Cella(riga: 1, colonna: 4)
        var stato = try crea([armato(1, 2)], [armato(2, 4)],
                             regole: RegoleDiCampagna(giornatePerLaPresa: 1),
                             fortezze: [Fortezza(riga: 1, colonna: 4, parte: .avversario)])
        XCTAssertEqual(stato.quartieriGenerali(di: .avversario), [suo, fortezza])
        XCTAssertEqual(stato.quartieriGenerali(di: .giocatore), [mio])
        chiudi(&stato)
        XCTAssertEqual(occupazioni(chiudi(&stato)), [.quartierGeneralePreso(casella: suo, occupante: .giocatore)])
        XCTAssertNil(stato.conclusione, "resta la fortezza")
        XCTAssertEqual(stato.registro.last?.fatto, .quartierGeneralePreso(casella: suo, dalGiocatore: true))
        // Preso, resta preso: lasciarlo non lo rende, e restarvi non conta di nuovo.
        XCTAssertEqual(occupazioni(chiudi(&stato, 2)), [])
        let io = gruppo(.giocatore, stato)
        stato.gruppi[io.id]!.posizione = fortezza
        XCTAssertEqual(occupazioni(chiudi(&stato)), [.quartierGeneraleOccupato(casella: fortezza, occupante: .giocatore, mancano: 1)])
        XCTAssertEqual(occupazioni(chiudi(&stato)), [.campagnaConclusa(modo: .presa, vincitore: .giocatore)])
        XCTAssertEqual(stato.quartieriGeneraliPresi, [suo, fortezza])
        // Prima la fortezza e poi l'altro: la stessa cosa. E una fortezza del giocatore lo difende.
        var difeso = try crea([armato(3, 4)], [armato(4, 2)], regole: RegoleDiCampagna(giornatePerLaPresa: 1),
                              fortezze: [Fortezza(riga: 4, colonna: 4, parte: .giocatore)])
        chiudi(&difeso, 4)
        XCTAssertNil(difeso.conclusione)
        XCTAssertEqual(difeso.quartieriGeneraliPresi, [mio])
        XCTAssertTrue(difeso.registro.map(\.fatto).contains(.quartierGeneralePreso(casella: mio, dalGiocatore: false)))
    }

    /// L'esito torna al regno: chi ha vinto con la presa riceve il premio della campagna vinta, chi l'ha
    /// perduta no; i superstiti tornano tutti, nell'uno e nell'altro caso. Il richiamo conta come perduto.
    func test_01_5_18_3_4_l_esito_della_presa_e_del_richiamo_arriva_al_regno() throws {
        let regno = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica, archetipiNoti: Set(valori.archetipi.keys),
                                               miglioramentiNoti: Set(valori.miglioramenti.keys))
        let motoreRegno = MotoreRegno(valori: regno)
        var vinta = try crea([armato(1, 2), armato(4, 4)], [armato(1, 4)])
        chiudi(&vinta, 4)
        let esitoVinta = try XCTUnwrap(PonteRegnoCampagna.esito(da: vinta, fronte: "guado"))
        XCTAssertEqual(esitoVinta.modo, .presa)
        XCTAssertTrue(esitoVinta.vinta)
        XCTAssertEqual(esitoVinta.superstiti.formazioni.count, 2)
        var perduta = try crea([armato(4, 4), armato(3, 4)], [armato(4, 2)])
        chiudi(&perduta, 4)
        let esitoPerduta = try XCTUnwrap(PonteRegnoCampagna.esito(da: perduta, fronte: "guado"))
        XCTAssertEqual(esitoPerduta.modo, .presa)
        XCTAssertFalse(esitoPerduta.vinta)
        XCTAssertEqual(esitoPerduta.superstiti.formazioni.count, 2, "i superstiti del perdente tornano in patria")
        var richiamata = try crea([armato(4, 4), armato(3, 4)], [armato(1, 2)])
        XCTAssertEqual(motore.richiama(&richiamata), [.campagnaConclusa(modo: .richiamo, vincitore: .avversario)])
        let esitoRichiamata = try XCTUnwrap(PonteRegnoCampagna.esito(da: richiamata, fronte: "guado"))
        XCTAssertFalse(esitoRichiamata.vinta)
        XCTAssertEqual(esitoRichiamata.superstiti.formazioni.count, 2)
        // I premi: soltanto chi ha vinto.
        XCTAssertFalse(motoreRegno.premi(per: esitoVinta).sonoVuote)
        XCTAssertTrue(motoreRegno.premi(per: esitoPerduta).sonoVuote)
        XCTAssertTrue(motoreRegno.premi(per: esitoRichiamata).sonoVuote)
    }

    // MARK: - Il difensore lo sa sempre (01 §5.18.3.3)

    /// Il proprio quartier generale occupato è confermato per chi lo possiede, anche se nessuna sua
    /// formazione lo osserva e anche se l'occupante vi sta appostato. Vale per le due parti.
    func test_01_5_18_3_3_chi_possiede_il_quartier_generale_sa_sempre_che_e_occupato() throws {
        // Lontano: nessuna formazione del giocatore osserva il proprio quartier generale.
        var stato = try crea([armato(1, 4)], [armato(4, 2)])
        XCTAssertFalse(motore.osservata(mio, da: .giocatore, stato: stato))
        XCTAssertEqual(motore.conoscenza(di: mio, per: .giocatore, stato: stato), .confermato)
        let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
        XCTAssertTrue(vista.avversarioAvvistato(su: mio))
        XCTAssertEqual(vista.caselleFormazioniAvversarieNote, [mio], "e il rotore delle formazioni note vi porta")
        // Appostato, lo sa lo stesso.
        let nemico = gruppo(.avversario, stato)
        stato.gruppi[nemico.id]!.ordineImboscata = true
        stato.gruppi[nemico.id]!.azioneSpesa = true
        XCTAssertEqual(motore.conoscenza(di: mio, per: .giocatore, stato: stato), .confermato)
        // Altrove l'occultamento resta.
        var altrove = stato
        altrove.gruppi[nemico.id]!.posizione = Cella(riga: 2, colonna: 4)
        XCTAssertNotEqual(motore.conoscenza(di: Cella(riga: 2, colonna: 4), per: .giocatore, stato: altrove), .confermato)
        // Un esploratore non occupa, e non si rivela così.
        let senzaRegola = try crea([armato(1, 4)], [armato(4, 2)], regole: nil)
        XCTAssertNotEqual(motore.conoscenza(di: mio, per: .giocatore, stato: senzaRegola), .confermato)
        // E l'avversario sa del proprio, nello stesso modo.
        let occupato = try crea([armato(1, 2)], [armato(4, 4)])
        XCTAssertFalse(motore.osservata(suo, da: .avversario, stato: occupato))
        XCTAssertEqual(motore.vistaAvversario(stato: occupato).formazioniGiocatoreNote, [suo])
        XCTAssertEqual(motore.conoscenza(di: suo, per: .avversario, stato: occupato), .confermato)
    }

    /// Ciò che entra nel registro: l'occupazione subita e la sua fine, col luogo; non la propria.
    func test_01_5_17_1_il_registro_annota_l_occupazione_subita() throws {
        var stato = try crea([armato(4, 4)], [armato(4, 2)])
        chiudi(&stato)
        XCTAssertEqual(stato.registro.last?.fatto, .quartierGeneraleOccupato(casella: mio))
        XCTAssertEqual(stato.registro.last?.luogo, mio)
        chiudi(&stato)
        XCTAssertEqual(stato.registro.map(\.fatto).filter { $0 == .quartierGeneraleOccupato(casella: mio) }.count, 1,
                       "le giornate che mancano si annunciano, e stanno nell'informazione di stato")
        // La lascia: si annota.
        let nemico = gruppo(.avversario, stato)
        stato.gruppi[nemico.id]!.posizione = Cella(riga: 3, colonna: 1)
        chiudi(&stato)
        XCTAssertEqual(stato.registro.last?.fatto, .quartierGeneraleLiberato(casella: mio))
    }

    /// Lo stato si conserva: la codifica porta le occupazioni, l'impronta le distingue, e uno stato senza
    /// occupazioni ha l'impronta di prima.
    func test_00_15_le_occupazioni_stanno_nello_stato_e_nell_impronta() throws {
        var stato = try crea([armato(1, 2)], [armato(1, 4)])
        let prima = stato.impronta()
        chiudi(&stato, 2)
        let riletto = try JSONDecoder().decode(StatoCampagna.self, from: JSONEncoder().encode(stato))
        XCTAssertEqual(riletto, stato)
        XCTAssertEqual(riletto.impronta(), stato.impronta())
        var conUnaInPiu = stato
        conUnaInPiu.occupazioni![0].giornate += 1
        XCTAssertNotEqual(conUnaInPiu.impronta(), stato.impronta())
        XCTAssertNotEqual(prima, stato.impronta())
        // Nessun campo nuovo nella codifica di una campagna che non dichiara la regola.
        let senza = String(decoding: try JSONEncoder().encode(try crea([armato(1, 2)], [armato(1, 4)], regole: nil)), as: UTF8.self)
        for campo in ["regole", "occupazioni", "quartieriGeneraliPresi", "fortezze"] { XCTAssertFalse(senza.contains(campo), campo) }
    }

    // MARK: - Il richiamo (01 §5.18.2)

    func test_01_5_18_2_l_esercito_si_richiama_quando_nessun_gruppo_e_tagliato_ne_a_contatto() throws {
        var stato = try crea([armato(4, 2), armato(3, 2)], [armato(1, 2)])
        XCTAssertNil(motore.impedimentoDelRichiamo(stato))
        let eventi = motore.richiama(&stato)
        XCTAssertEqual(eventi, [.campagnaConclusa(modo: .richiamo, vincitore: .avversario)])
        XCTAssertEqual(stato.conclusione, ConclusioneCampagna(modo: .richiamo, vincitore: .avversario, giorno: 1))
        XCTAssertEqual(stato.gruppi(di: .giocatore).count, 2, "i superstiti tornano tutti")
        XCTAssertEqual(motore.impedimentoDelRichiamo(stato), .campagnaConclusa)
    }

    func test_01_5_18_2_il_rifornimento_tagliato_impedisce_il_richiamo_e_dice_quale_gruppo() throws {
        // Un nemico alle spalle del gruppo avanzato.
        let stato = try crea([armato(4, 1), armato(2, 2)], [armato(3, 2)])
        let avanzato = try XCTUnwrap(stato.occupante(di: Cella(riga: 2, colonna: 2)))
        XCTAssertTrue(motore.rifornimentoTagliato(di: avanzato, stato: stato))
        XCTAssertEqual(motore.impedimentoDelRichiamo(stato),
                       .rifornimentoTagliato(gruppo: avanzato.nome, casella: Cella(riga: 2, colonna: 2)))
        // Un esploratore nello stesso posto non è soggetto al taglio (01 §5.15).
        let esploratore = try crea([armato(4, 1), .init(riga: 2, colonna: 2, composizione: reparti(3), categoria: "ricognizione",
                                                        competenza: 5)], [armato(3, 2)])
        XCTAssertNil(motore.impedimentoDelRichiamo(esploratore))
    }

    func test_01_5_18_2_il_contatto_col_nemico_impedisce_il_richiamo_e_dice_quale_gruppo_e_dove() throws {
        // Nella stessa casella di un gruppo avversario, di qualunque categoria.
        let stato = try crea([armato(4, 2), .init(riga: 3, colonna: 4, composizione: reparti(3), categoria: "ricognizione", competenza: 5)],
                             [armato(1, 2), .init(riga: 3, colonna: 4, composizione: reparti(4), categoria: "non_armata",
                                                  carico: 4, sogliaProtezione: 2)])
        let esploratore = gruppo(.giocatore, stato, 1)
        XCTAssertEqual(motore.impedimentoDelRichiamo(stato), .aContatto(gruppo: esploratore.nome, casella: Cella(riga: 3, colonna: 4)))
        // La vicinanza non è contatto (decisione del titolare del 24 novembre 2026).
        let vicino = try crea([armato(4, 2), armato(2, 2)], [armato(1, 2)])
        XCTAssertNil(motore.impedimentoDelRichiamo(vicino))
        // Una battaglia in sospeso: il medesimo motivo di ogni comando bloccato, e dove.
        var inBattaglia = try crea([armato(2, 2), armato(4, 2)], [armato(1, 2)])
        marcia(gruppo(.giocatore, inBattaglia), a: suo, &inBattaglia)
        while inBattaglia.battaglieInSospeso.isEmpty { chiudi(&inBattaglia) }
        XCTAssertEqual(motore.impedimentoDelRichiamo(inBattaglia), .battagliaInSospeso(casella: suo))
        // Le campagne di prova non hanno una patria.
        XCTAssertEqual(motore.impedimentoDelRichiamo(try crea([armato(4, 2)], [armato(1, 2)], regole: nil, calendario: nil)), .senzaPatria)
    }

    // MARK: - La condotta dell'avversario (01 §5.18.3.5)

    private func comando(_ stato: StatoCampagna, _ indice: Int = 0) -> ComandoCampagna {
        CondottaAvversaria().comando(per: gruppo(.avversario, stato, indice), vista: motore.vistaAvversario(stato: stato))
    }

    /// Chi occupa il quartier generale del giocatore lo tiene, anche se vedrebbe un guadagno altrove.
    func test_01_5_18_3_5_l_avversario_che_occupa_il_quartier_generale_lo_tiene() throws {
        var stato = try crea([armato(4, 4)], [armato(4, 2)])
        chiudi(&stato)
        XCTAssertEqual(stato.occupazioni?.first?.occupante, .avversario)
        XCTAssertEqual(comando(stato), .presidio(gruppo: gruppo(.avversario, stato).id))
        // Con una formazione nota accanto vi si apposta: resta comunque.
        var accanto = try crea([armato(4, 1)], [armato(4, 2)])
        chiudi(&accanto)
        XCTAssertEqual(comando(accanto), .imboscata(gruppo: gruppo(.avversario, accanto).id))
        // E la campagna finisce con la sua vittoria, se nessuno lo scaccia.
        for _ in 0..<3 { giocaLaGiornata(&stato) }
        XCTAssertEqual(stato.conclusione, ConclusioneCampagna(modo: .presa, vincitore: .avversario, giorno: stato.giorno))
    }

    /// A un passo dal quartier generale libero, l'avversario vi entra invece di girare intorno al giocatore.
    func test_01_5_18_3_5_a_un_passo_l_avversario_entra_nel_quartier_generale() throws {
        // Una formazione armata nota, vicina al suo quartier generale: senza la corsa tornerebbe a difenderlo,
        // e mettersi alle sue spalle varrebbe più della sola avanzata. Arriva prima lui: entra.
        let stato = try crea([armato(2, 3)], [armato(3, 2)])
        XCTAssertEqual(motore.vistaAvversario(stato: stato).presa?.armateNote, [Cella(riga: 2, colonna: 3)])
        guard case .marcia(_, let dove, _) = comando(stato) else { return XCTFail("\(comando(stato))") }
        XCTAssertEqual(dove, mio)
        // Se il quartier generale del giocatore è notoriamente difeso non c'è corsa: torna a difendere il suo.
        let difeso = try crea([armato(2, 3), armato(4, 2)], [armato(3, 2)])
        guard case .marcia(_, let dove, _) = comando(difeso) else { return XCTFail("\(comando(difeso))") }
        XCTAssertEqual(dove, Cella(riga: 2, colonna: 2))
        // Un esploratore non può prendere un quartier generale: non lo richiama indietro.
        let esploratore = try crea([.init(riga: 2, colonna: 3, composizione: reparti(3), categoria: "ricognizione", competenza: 5),
                                    armato(4, 4)], [armato(3, 2)])
        XCTAssertEqual(motore.vistaAvversario(stato: esploratore).presa?.armateNote, [])
        guard case .marcia(_, let dove, _) = comando(esploratore) else { return XCTFail("\(comando(esploratore))") }
        XCTAssertEqual(dove, mio)
    }

    /// Sa occupato il proprio: torna a riprenderlo per la via più breve e vi entra, e la battaglia nasce.
    func test_01_5_18_3_5_l_avversario_torna_a_riprendere_il_proprio_quartier_generale() throws {
        var stato = try crea([armato(1, 2), armato(4, 4)], [armato(3, 2)])
        chiudi(&stato)
        XCTAssertEqual(stato.occupazioni?.first?.occupante, .giocatore)
        guard case .marcia(_, let verso, _) = comando(stato) else { return XCTFail("\(comando(stato))") }
        XCTAssertEqual(verso, Cella(riga: 2, colonna: 2), "la via più breve, sulla strada")
        var giri = 0
        while stato.battaglieInSospeso.isEmpty, stato.conclusione == nil, giri < 10 { giocaLaGiornata(&stato); giri += 1 }
        XCTAssertEqual(stato.battaglieInSospeso.map(\.casella), [suo], "entra nella casella a scacciare l'occupante")
    }

    /// La corsa: chi sta per prendere prima quello del giocatore resta; chi la perderebbe, e può arrivare
    /// in tempo, torna; chi non può arrivare in tempo e ne tiene già uno, resta.
    func test_01_5_18_3_5_l_avversario_valuta_la_corsa() throws {
        func inCorsa(giocatore: Int, avversario: Int, giornate: Int = 3) throws -> StatoCampagna {
            var stato = try crea([armato(1, 2)], [armato(4, 2)], regole: RegoleDiCampagna(giornatePerLaPresa: giornate))
            stato.occupazioni = [OccupazioneDelQuartierGenerale(casella: suo, occupante: .giocatore, giornate: giocatore),
                                 OccupazioneDelQuartierGenerale(casella: mio, occupante: .avversario, giornate: avversario)]
            return stato
        }
        let resta = try inCorsa(giocatore: 0, avversario: 1)
        XCTAssertEqual(comando(resta), .presidio(gruppo: gruppo(.avversario, resta).id), "vince la corsa, e resta")
        let tardi = try inCorsa(giocatore: 2, avversario: 0)
        XCTAssertEqual(comando(tardi), .presidio(gruppo: gruppo(.avversario, tardi).id), "non arriverebbe in tempo, e resta")
        let torna = try inCorsa(giocatore: 1, avversario: 0, giornate: 40)
        guard case .marcia(_, let verso, _) = comando(torna) else { return XCTFail("\(comando(torna))") }
        XCTAssertEqual(verso, Cella(riga: 3, colonna: 2), "perderebbe la corsa e può arrivare in tempo: torna")
    }

    /// Senza la regola la condotta è quella di prima: la stessa per lo stesso stato.
    func test_incarico_32_senza_la_regola_la_condotta_non_cambia() throws {
        // Il giocatore sta sul quartier generale dell'avversario, che senza la regola non entra mai nella
        // casella di una formazione nota: le va accanto e vi si apposta, com'era.
        var stato = try crea([armato(1, 2), armato(4, 4)], [armato(3, 2)], regole: nil)
        XCTAssertNil(motore.vistaAvversario(stato: stato).presa)
        XCTAssertEqual(comando(stato), .marcia(gruppo: gruppo(.avversario, stato).id, a: Cella(riga: 2, colonna: 2),
                                               giorni: motore.costoInGiorni(da: Cella(riga: 3, colonna: 2), a: Cella(riga: 2, colonna: 2),
                                                                            parte: .avversario, stato: stato)))
        stato.gruppi[gruppo(.avversario, stato).id]!.posizione = Cella(riga: 2, colonna: 2)
        XCTAssertEqual(comando(stato), .imboscata(gruppo: gruppo(.avversario, stato).id))
        // Con la regola, dalla stessa posizione vi entra.
        var conRegola = try crea([armato(1, 2), armato(4, 4)], [armato(2, 2)])
        chiudi(&conRegola)
        guard case .marcia(_, let dove, _) = comando(conRegola) else { return XCTFail("\(comando(conRegola))") }
        XCTAssertEqual(dove, suo)
    }

    /// Le giornate verso una meta: la via più breve, aggirando ciò che si evita.
    func test_01_5_6_3_1_le_giornate_verso_una_meta_seguono_la_via_piu_breve() throws {
        let stato = try crea([armato(4, 2)], [armato(1, 2)])
        let volume = motore.volume(di: gruppo(.avversario, stato))
        let libere = MotoreCampagna.giornate(verso: suo, volumeColonna: volume, mappa: stato.mappa, marcia: valoriCampagna.marcia)
        XCTAssertEqual(libere[suo], 0)
        XCTAssertEqual(Set(libere.keys), Set(stato.griglia.tutteLeCaselle))
        for casella in stato.griglia.tutteLeCaselle where casella != suo {
            let passi = stato.griglia.vicini(di: casella).map {
                MotoreCampagna.costoInGiorni(da: casella, a: $0, volumeColonna: volume, mappa: stato.mappa,
                                             marcia: valoriCampagna.marcia) + libere[$0]!
            }
            XCTAssertEqual(libere[casella], passi.min(), "\(casella)")
        }
        let evitando = MotoreCampagna.giornate(verso: suo, volumeColonna: volume, mappa: stato.mappa, marcia: valoriCampagna.marcia,
                                               evitando: [Cella(riga: 2, colonna: 2)])
        XCTAssertNil(evitando[Cella(riga: 2, colonna: 2)])
        XCTAssertGreaterThanOrEqual(evitando[Cella(riga: 3, colonna: 2)]!, libere[Cella(riga: 3, colonna: 2)]!)
    }

    /// Una giornata: il giocatore resta, l'avversario segue la propria condotta.
    private func giocaLaGiornata(_ stato: inout StatoCampagna) {
        let giorno = stato.giorno
        for gruppo in stato.gruppiOrdinati where gruppo.parte == .giocatore {
            guard stato.giorno == giorno, stato.conclusione == nil, stato.gruppi[gruppo.id]?.haConclusoLaGiornata == false,
                  let ordine = motore.ordineDiRestare(per: gruppo.id, parte: .giocatore, stato: stato) else { continue }
            (stato, _) = motore.applica(ordine, parte: .giocatore, stato: stato)
        }
        while stato.giorno == giorno, stato.conclusione == nil, stato.battaglieInSospeso.isEmpty,
              let comando = CondottaAvversaria().prossimoComando(vista: motore.vistaAvversario(stato: stato)) {
            XCTAssertTrue(motore.valida(comando, parte: .avversario, stato: stato).eValido, "\(comando)")
            (stato, _) = motore.applica(comando, parte: .avversario, stato: stato)
        }
    }
}
