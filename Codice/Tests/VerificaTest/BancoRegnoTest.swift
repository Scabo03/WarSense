import XCTest
import Verifica
import Motore
import Dati
import Contenuti

/// Il banco del regno e la sonda dei suoi invarianti (incarico 30). Due cose distinte: che anni
/// interi giocati coi valori di fabbrica non violino alcun invariante, e che la sonda MORDA — cioè
/// che ciascun invariante, violato di proposito in uno stato costruito qui, sia riferito col suo
/// codice. Una sonda che non si è mai vista rifiutare non è una protezione.
final class BancoRegnoTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    var valoriRegno: ValoriRegno!
    var motore: MotoreRegno!
    let sonda = SondaInvariantiRegno()

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        valoriRegno = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica,
                                                 archetipiNoti: Set(valori.archetipi.keys),
                                                 miglioramentiNoti: Set(valori.miglioramenti.keys))
        motore = MotoreRegno(valori: valoriRegno)
    }

    private func banco() throws -> BancoRegno {
        let dati = try Data(contentsOf: Contenuti.valoriDiFabbrica.appendingPathComponent("scenari-campagna.json"))
        let scenari = try JSONDecoder().decode([String: ScenarioCampagna].self, from: dati)
        return BancoRegno(valoriRegno: valoriRegno,
                          motoreCampagna: MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna),
                          valoriCampagna: valoriCampagna, scenari: scenari)
    }

    // MARK: - Anni interi senza violazioni

    func test_il_banco_gioca_anni_interi_coi_valori_di_fabbrica_senza_violare_alcun_invariante() throws {
        let banco = try banco()
        var anni: [BancoRegno.Anno] = []
        for condotta in MisuraFrequenzaBattaglie.Condotta.allCases {
            for seme in 0..<3 { anni += try banco.gioca(anni: 3, condotta: condotta, seme: UInt64(seme)) }
        }
        XCTAssertGreaterThanOrEqual(anni.count, 12, "le partite arrivano almeno al secondo anno")
        let conViolazioni = anni.filter { !$0.violazioni.isEmpty }
        XCTAssertEqual(conViolazioni.map { "\($0.condotta.rawValue)/\($0.seme)/\($0.anno): \($0.violazioni)" }, [])
        for anno in anni where anno.conclusione != "ferma" {
            XCTAssertTrue(["annientamento", "inverno"].contains(anno.conclusione), anno.conclusione)
            XCTAssertLessThanOrEqual(anno.atomiRientrati, anno.atomiPartiti, "nessun reintegro sul campo (01 §4.12)")
            XCTAssertLessThanOrEqual(anno.giornate, valoriRegno.giornateOperative)
            XCTAssertEqual(anno.proposteAvversarieRespinte, 0)
            for risorsa in Risorsa.allCases {
                XCTAssertGreaterThanOrEqual(anno.riportato[risorsa.rawValue] ?? -1, 0)
            }
        }
        let conclusi = anni.filter { $0.conclusione != "ferma" }.count
        let conLeve = anni.filter { $0.leveOrdinate > 0 }.count
        XCTAssertGreaterThan(conLeve, 0, "d'inverno il banco ordina leve")
        print("BANCO-REGNO anni=\(anni.count) conclusi=\(conclusi) fermi=\(anni.count - conclusi) con_leve=\(conLeve) con_violazioni=\(conViolazioni.count)")

        // Incarico 31: ogni anno concluso paga il mantenimento, e nessuno scende sotto zero per pagarlo.
        for anno in anni where anno.conclusione != "ferma" {
            XCTAssertGreaterThan(anno.mantenimento, 0, "\(anno.condotta.rawValue)/\(anno.seme)/\(anno.anno): nessun mantenimento")
        }
    }

    /// Il banco su PIÙ SEMI E PIÙ ANNI (incarico 31): nessuna violazione, né del regno né della
    /// campagna. E il silenzio della sonda vale qualcosa soltanto se il banco passa davvero per ciò
    /// che la seconda tappa ha aggiunto: fra i semi e gli anni giocati ci sono formazioni tenute in
    /// patria, reclute, arrivi dalla patria a campagna aperta, addestramenti mirati e mantenimenti
    /// di addestramenti. Se una taratura dei valori facesse sparire uno di questi dal banco, questa
    /// prova lo dice, invece di lasciare che la sonda taccia su ciò che non accade più.
    func test_incarico_31_il_banco_su_piu_semi_e_piu_anni_non_produce_alcuna_violazione() throws {
        let banco = try banco()
        var anni: [BancoRegno.Anno] = []
        for condotta in MisuraFrequenzaBattaglie.Condotta.allCases {
            for seme in 0..<6 { anni += try banco.gioca(anni: 5, condotta: condotta, seme: UInt64(seme)) }
        }
        XCTAssertGreaterThanOrEqual(anni.count, 48, "le partite arrivano quasi tutte al quinto anno")
        let conViolazioni = anni.filter { !$0.violazioni.isEmpty }
        XCTAssertEqual(conViolazioni.map { "\($0.condotta.rawValue)/\($0.seme)/\($0.anno): \($0.violazioni)" }, [])
        let conclusi = anni.filter { $0.conclusione != "ferma" }
        for anno in conclusi {
            XCTAssertTrue(["annientamento", "inverno", "nessuna"].contains(anno.conclusione), anno.conclusione)
            XCTAssertLessThanOrEqual(anno.atomiRientrati, anno.atomiPartiti, "nessun reintegro sul campo (01 §4.12)")
            XCTAssertLessThanOrEqual(anno.giornate, valoriRegno.giornateOperative)
            XCTAssertEqual(anno.proposteAvversarieRespinte, 0)
            XCTAssertGreaterThan(anno.mantenimento, 0, "\(anno.condotta.rawValue)/\(anno.seme)/\(anno.anno)")
            for risorsa in Risorsa.allCases {
                XCTAssertGreaterThanOrEqual(anno.riportato[risorsa.rawValue] ?? -1, 0)
            }
        }
        // Le partite arrivano al quinto anno: le forze reggono il mantenimento per anni di seguito.
        XCTAssertGreaterThan(anni.filter { $0.anno == 5 }.count, 6)
        let conInPatria = anni.filter { $0.tenuteInPatria > 0 }.count
        let conReclute = anni.filter { $0.formazioniDiReclute > 0 }.count
        let conArrivi = anni.filter { $0.arriviACampagnaAperta > 0 }.count
        let miglioramenti = anni.reduce(0) { $0 + $1.miglioramentiOrdinati }
        let mantenimenti = anni.reduce(0) { $0 + $1.mantenimentiOrdinati }
        let conSciolti = anni.filter { $0.repartiSciolti > 0 }.count
        print("BANCO-REGNO-31 anni=\(anni.count) conclusi=\(conclusi.count) fermi=\(anni.count - conclusi.count) con_violazioni=\(conViolazioni.count) con_formazioni_in_patria=\(conInPatria) con_reclute=\(conReclute) con_arrivi_a_campagna_aperta=\(conArrivi) miglioramenti=\(miglioramenti) mantenimenti=\(mantenimenti) con_reparti_sciolti=\(conSciolti)")
        XCTAssertGreaterThan(conInPatria, 0, "il banco non ha mai tenuto in patria una formazione")
        XCTAssertGreaterThan(conReclute, 0, "la primavera non ha mai formato una formazione di reclute")
        XCTAssertGreaterThan(conArrivi, 0, "nessuna campagna ha avuto arrivi dalla patria a campagna aperta")
        XCTAssertGreaterThan(miglioramenti, 0, "il banco non ha mai ordinato un addestramento mirato")
        XCTAssertGreaterThan(mantenimenti, 0, "il banco non ha mai mantenuto un addestramento")
    }

    /// Coi valori di fabbrica il denaro basta sempre al mantenimento, e il banco non scioglie mai
    /// nulla: lo scioglimento resterebbe sorvegliato dalla sonda senza accadere mai. Qui la rendita
    /// di denaro è ridotta a un decimo, sicché ogni inverno il gioco scioglie reparti: anni interi
    /// giocati così non violano alcun invariante, e il denaro non scende mai sotto zero.
    func test_incarico_31_il_banco_col_denaro_che_non_basta_scioglie_reparti_senza_violare_alcun_invariante() throws {
        let dati = try Data(contentsOf: Contenuti.valoriDiFabbrica.appendingPathComponent("scenari-campagna.json"))
        let scenari = try JSONDecoder().decode([String: ScenarioCampagna].self, from: dati)
        let povero = BancoRegno(valoriRegno: valoriPoveri(renditaDiDenaro: 20),
                                motoreCampagna: MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna),
                                valoriCampagna: valoriCampagna, scenari: scenari)
        var anni: [BancoRegno.Anno] = []
        for condotta in MisuraFrequenzaBattaglie.Condotta.allCases {
            for seme in 0..<4 { anni += try povero.gioca(anni: 4, condotta: condotta, seme: UInt64(seme)) }
        }
        XCTAssertGreaterThanOrEqual(anni.count, 16)
        let conViolazioni = anni.filter { !$0.violazioni.isEmpty }
        XCTAssertEqual(conViolazioni.map { "\($0.condotta.rawValue)/\($0.seme)/\($0.anno): \($0.violazioni)" }, [])
        let conSciolti = anni.filter { $0.repartiSciolti > 0 }
        XCTAssertGreaterThan(conSciolti.count, 0, "con la rendita ridotta il gioco deve sciogliere dei reparti")
        for anno in anni where anno.conclusione != "ferma" {
            XCTAssertGreaterThanOrEqual(anno.riportato[Risorsa.denaro.rawValue] ?? -1, 0, "il denaro non va mai sotto zero")
            XCTAssertLessThanOrEqual(anno.atomiRientrati, anno.atomiPartiti)
        }
        print("BANCO-REGNO-POVERO anni=\(anni.count) con_reparti_sciolti=\(conSciolti.count) reparti_sciolti=\(anni.reduce(0) { $0 + $1.repartiSciolti }) mantenimento=\(anni.map(\.mantenimento)) con_violazioni=\(conViolazioni.count)")
    }

    func test_00_3_1_lo_stesso_seme_da_gli_stessi_anni() throws {
        let banco = try banco()
        let a = try banco.gioca(anni: 2, condotta: .prudente, seme: 5)
        let b = try banco.gioca(anni: 2, condotta: .prudente, seme: 5)
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = [.sortedKeys]
        XCTAssertEqual(try codificatore.encode(a), try codificatore.encode(b))
        XCTAssertFalse(a.isEmpty)
    }

    func test_la_campagna_con_calendario_si_conclude_da_se_nello_strumento_di_misura() throws {
        let dati = try Data(contentsOf: Contenuti.valoriDiFabbrica.appendingPathComponent("scenari-campagna.json"))
        let base = try XCTUnwrap(try JSONDecoder().decode([String: ScenarioCampagna].self, from: dati)["campagna_media"])
        let scenario = try PonteRegnoCampagna.scenario(
            delFronte: base, forze: try ForzeDelRegno.iniziali(valoriRegno.forzeIniziali,
                                                                nomi: valoriRegno.nomiDelleUnita),
            calendario: CalendarioDiCampagna(anno: 1, giornatePerStagione: 4), valori: valoriCampagna)
        let misura = MisuraFrequenzaBattaglie(motore: MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna),
                                              valoriCampagna: valoriCampagna)
        let partita = try misura.gioca(scenario: scenario, formato: "istmo", condotta: .prudente, seme: 1,
                                       limiteGiornate: 100)
        XCTAssertEqual(partita.fine, .conclusa)
        XCTAssertLessThanOrEqual(partita.giornate, 12)
        XCTAssertEqual(partita.violazioni, [])
    }

    // MARK: - La sonda morde: un mutante per ciascun invariante

    /// Una transizione legittima per ciascun passo, costruita col Motore. Su ciascuna la sonda tace.
    private struct Transizione {
        let prima: StatoRegno
        let dopo: StatoRegno
        let passo: SondaInvariantiRegno.Passo
    }

    /// Le stesse forze con le formazioni trasformate: la posizione nella lista dei nomi resta.
    private func conFormazioni(_ forze: ForzeDelRegno,
                               _ trasforma: ([FormazioneDelRegno]) -> [FormazioneDelRegno]) -> ForzeDelRegno {
        switch forze {
        case .sciami(let formazioni, let prossimoNome):
            return .sciami(formazioni: trasforma(formazioni), prossimoNome: prossimoNome)
        }
    }

    /// La stessa formazione con un altro nome.
    private func rinominata(_ formazione: FormazioneDelRegno, _ nome: IdentificatoreDati) -> FormazioneDelRegno {
        FormazioneDelRegno(nome: nome, categoria: formazione.categoria, composizione: formazione.composizione,
                           inPatria: formazione.inPatria, arrivo: formazione.arrivo)
    }

    /// Le forze con una formazione armata in più, che nessun passo del regno giustifica.
    private func conUnaFormazioneInPiu(_ forze: ForzeDelRegno, atomi: Int) -> ForzeDelRegno {
        conFormazioni(forze) {
            $0 + [FormazioneDelRegno(nome: "muflone", categoria: .armato,
                                     composizione: [Reparto(archetipo: "fanteria_leggera", atomi: atomi)])]
        }
    }

    /// I valori di fabbrica con una rendita di denaro così bassa che il mantenimento non vi rientra:
    /// servono alla transizione in cui il gioco scioglie dei reparti.
    private func valoriPoveri(renditaDiDenaro: Int) -> ValoriRegno {
        var rendita = valoriRegno.renditaAnnua
        rendita[Risorsa.denaro.rawValue] = renditaDiDenaro
        return ValoriRegno(giornatePerStagione: valoriRegno.giornatePerStagione, quotaRiporto: valoriRegno.quotaRiporto,
                           dotazioneIniziale: valoriRegno.dotazioneIniziale, renditaAnnua: rendita,
                           premioBattagliaVinta: valoriRegno.premioBattagliaVinta,
                           premioCampagnaVinta: valoriRegno.premioCampagnaVinta, baseLeva: valoriRegno.baseLeva,
                           costoMinimo: valoriRegno.costoMinimo, voci: valoriRegno.voci, fronti: valoriRegno.fronti,
                           faseIniziale: valoriRegno.faseIniziale, forzeIniziali: valoriRegno.forzeIniziali,
                           stazioniPerStagione: valoriRegno.stazioniPerStagione, linguette: valoriRegno.linguette,
                           mantenimento: valoriRegno.mantenimento, nomiDelleUnita: valoriRegno.nomiDelleUnita)
    }

    private static let bersaglioDiLupo = BersaglioMilitare(unita: "lupo", elemento: 1)

    /// Le transizioni legittime: due anni giocati col Motore sui valori di fabbrica — il primo con
    /// la formazione non armata tenuta in patria, la campagna, una leva e un addestramento mirato;
    /// il secondo senza campagna, una volta col mantenimento dell'addestramento e una senza —, più
    /// un inverno in cui il denaro non basta e il gioco scioglie dei reparti.
    private func legittime() throws -> [String: Transizione] {
        var esito: [String: Transizione] = [:]
        var stato = try motore.statoIniziale()
        func applica(_ comando: ComandoRegno, riga: UInt = #line) -> [EventoRegno] {
            XCTAssertTrue(motore.valida(comando, stato: stato).eValido, "\(comando) dovrebbe essere valido", line: riga)
            let (nuovo, eventi) = motore.applica(comando, stato: stato)
            stato = nuovo
            return eventi
        }
        /// Ordina una voce e ne restituisce la transizione, col costo che l'evento dichiara.
        func spesa(_ identificatore: String, bersaglio: BersaglioMilitare?, riga: UInt = #line) throws -> Transizione {
            let voce = try XCTUnwrap(valoriRegno.voce(identificatore))
            let prima = stato
            var costo = Riserve()
            for evento in applica(.ordina(voce: identificatore, bersaglio: bersaglio), riga: riga) {
                if case .lavoroOrdinato(_, let c, _, _) = evento { costo = c }
            }
            return Transizione(prima: prima, dopo: stato,
                               passo: .spesa(costo: costo, durata: voce.durata,
                                             stazioniPerStagione: valoriRegno.stazioniPerStagione))
        }
        /// Apre l'inverno e ne restituisce la transizione, con l'entrata che l'evento dichiara.
        func inverno() -> (Transizione, Riserve) {
            let prima = stato
            var entrata = Riserve()
            for evento in applica(.attendiInverno) { if case .invernoCominciato(_, let e, _, _) = evento { entrata = e } }
            return (Transizione(prima: prima, dopo: stato,
                                passo: .arrivoDellInverno(entrata: entrata, mantenimento: valoriRegno.mantenimento)),
                    entrata)
        }

        // Il primo anno. La scelta di chi parte: la formazione non armata resta in patria.
        var prima = stato
        _ = applica(.destina(unita: "cervo", alFronte: false))
        esito["destinazione"] = Transizione(prima: prima, dopo: stato,
                                            passo: .destinazione(unita: "cervo", alFronte: false))

        prima = stato
        _ = applica(.apriCampagna(fronte: "guado"))
        esito["apertura"] = Transizione(prima: prima, dopo: stato, passo: .aperturaDellaCampagna)

        // Rientra chi era partito, col proprio nome, tranne l'ultima formazione, caduta.
        prima = stato
        var superstiti = stato.forze.formazioni.filter(\.parteConLaCampagna).map {
            FormazioneDelRegno(nome: $0.nome, categoria: $0.categoria, composizione: $0.composizione)
        }
        superstiti.removeLast()
        let esitoCampagna = EsitoCampagna(fronte: "guado", anno: 1, modo: .annientamento, vincitore: .giocatore,
                                          giornate: 12, battaglieVinte: 1, battagliePerse: 0,
                                          superstiti: .sciami(formazioni: superstiti, prossimoNome: 0))
        _ = motore.applicaEsito(esitoCampagna, in: &stato)
        esito["rientro"] = Transizione(prima: prima, dopo: stato, passo: .rientroDallaCampagna(esitoCampagna))

        let (primoInverno, entrata) = inverno()
        esito["inverno"] = primoInverno
        esito["spesa"] = try spesa("leva_fanteria_leggera", bersaglio: nil)
        esito["addestramento"] = try spesa("addestramento_mirato", bersaglio: Self.bersaglioDiLupo)

        prima = stato
        _ = applica(.prosegui)
        esito["stazione"] = Transizione(prima: prima, dopo: stato, passo: .stazioneSuccessiva)
        // Una leva lunga ordinata tardi: matura a campagna aperta, e la primavera forma due formazioni.
        esito["spesa_lunga"] = try spesa("leva_cavalleria_manovrata", bersaglio: nil)
        _ = applica(.prosegui)
        _ = applica(.prosegui)

        prima = stato
        _ = applica(.prosegui)
        esito["primavera"] = Transizione(prima: prima, dopo: stato,
                                         passo: .primavera(quotaRiporto: valoriRegno.quotaRiporto, entrata: entrata))

        // Il secondo anno, senza campagna. Dall'inverno in poi due storie: in una l'addestramento
        // di Lupo si mantiene, nell'altra no e in primavera si perde.
        let (secondoInverno, secondaEntrata) = inverno()
        esito["inverno_con_gli_arrivi"] = secondoInverno
        let allInizioDelSecondoInverno = stato
        esito["mantenimento_dell_addestramento"] = try spesa("mantenimento_addestramento", bersaglio: Self.bersaglioDiLupo)
        for _ in 1..<MomentoDellAnno.stazioniInvernali { _ = applica(.prosegui) }
        prima = stato
        _ = applica(.prosegui)
        esito["primavera_col_miglioramento_mantenuto"] = Transizione(
            prima: prima, dopo: stato, passo: .primavera(quotaRiporto: valoriRegno.quotaRiporto, entrata: secondaEntrata))

        stato = allInizioDelSecondoInverno
        for _ in 1..<MomentoDellAnno.stazioniInvernali { _ = applica(.prosegui) }
        prima = stato
        _ = applica(.prosegui)
        esito["primavera_col_miglioramento_perduto"] = Transizione(
            prima: prima, dopo: stato, passo: .primavera(quotaRiporto: valoriRegno.quotaRiporto, entrata: secondaEntrata))

        // L'inverno povero: la rendita è di dieci monete, e la quota di ciò che il regno tiene in
        // armi è di sedici. Il gioco scioglie per primi i reparti reclutati per ultimi.
        let povero = MotoreRegno(valori: valoriPoveri(renditaDiDenaro: 10))
        var riserve = Riserve(valoriRegno.dotazioneIniziale)
        riserve[.denaro] = 0
        let primaDelPovero = StatoRegno(anno: 3, momento: .operativo, fase: valoriRegno.faseIniziale, riserve: riserve,
                                        forze: .sciami(formazioni: [
                                            FormazioneDelRegno(nome: "corvo", categoria: .armato, composizione: [
                                                Reparto(archetipo: "fanteria_leggera", atomi: 6)]),
                                            FormazioneDelRegno(nome: "lupo", categoria: .armato, composizione: [
                                                Reparto(archetipo: "fanteria_pesante", atomi: 8, leva: 1),
                                                Reparto(archetipo: "fanteria_leggera", atomi: 18, leva: 2)]),
                                            FormazioneDelRegno(nome: "falco", categoria: .armato, composizione: [
                                                Reparto(archetipo: "cavalleria_manovrata", atomi: 12, leva: 2)]),
                                        ], prossimoNome: 3))
        let (dopoIlPovero, eventi) = povero.applica(.attendiInverno, stato: primaDelPovero)
        var entrataPovera = Riserve()
        for evento in eventi { if case .invernoCominciato(_, let e, _, _) = evento { entrataPovera = e } }
        esito["inverno_povero"] = Transizione(
            prima: primaDelPovero, dopo: dopoIlPovero,
            passo: .arrivoDellInverno(entrata: entrataPovera, mantenimento: valoriRegno.mantenimento))
        return esito
    }

    private func codici(_ t: Transizione, dopo: StatoRegno? = nil, passo: SondaInvariantiRegno.Passo? = nil) -> Set<String> {
        Set(sonda.controlla(prima: t.prima, dopo: dopo ?? t.dopo, passo: passo ?? t.passo,
                            giornateOperative: valoriRegno.giornateOperative)
            .map(SondaInvariantiRegno.codice(di:)))
    }

    func test_sulle_transizioni_del_motore_la_sonda_tace() throws {
        let legittime = try legittime()
        // Le sei della prima tappa — apertura, rientro, inverno, spesa, stazione, primavera — e
        // quelle della seconda (incarico 31).
        XCTAssertEqual(legittime.count, 14)
        for (nome, transizione) in legittime.sorted(by: { $0.key < $1.key }) {
            XCTAssertEqual(codici(transizione), [], "transizione legittima «\(nome)»")
        }
        // Le transizioni contengono davvero ciò che i mutanti guasteranno: senza, il silenzio della
        // sonda su di esse non direbbe nulla.
        XCTAssertEqual(legittime["rientro"]!.prima.forze.formazioni.filter(\.inPatria).map(\.nome), ["cervo"])
        XCTAssertEqual(legittime["rientro"]!.dopo.forze.formazioni.map(\.nome), ["corvo", "lupo", "falco", "cervo"])
        XCTAssertEqual(legittime["primavera"]!.dopo.forze.formazioni.map(\.nome),
                       ["corvo", "lupo", "falco", "cervo", "lince", "aquila"])
        XCTAssertEqual(legittime["primavera"]!.dopo.forze.formazioni.map(\.arrivo),
                       [nil, nil, nil, nil, .primavera, .estate])
        XCTAssertEqual(legittime["primavera"]!.dopo.forze.reparto(Self.bersaglioDiLupo)?.miglioramento,
                       "addestramento_mirato")
        XCTAssertTrue(legittime["inverno_con_gli_arrivi"]!.dopo.forze.formazioni.allSatisfy { $0.arrivo == nil })
        XCTAssertEqual(legittime["primavera_col_miglioramento_mantenuto"]!.dopo.forze
            .reparto(Self.bersaglioDiLupo)?.miglioramento, "addestramento_mirato")
        XCTAssertNil(try XCTUnwrap(legittime["primavera_col_miglioramento_perduto"]!.dopo.forze
            .reparto(Self.bersaglioDiLupo)).miglioramento)
        let povero = legittime["inverno_povero"]!.dopo
        XCTAssertEqual(povero.sciolti.map(\.unita), ["falco", "lupo"], "prima l'ultimo reclutato che sta più in fondo")
        XCTAssertEqual(povero.sciolti.map(\.reparto.atomi), [12, 18])
        XCTAssertEqual(povero.forze.formazioni.map(\.nome), ["corvo", "lupo"], "la formazione rimasta vuota sparisce")
        XCTAssertEqual(povero.mantenimento[.denaro], 5)
        XCTAssertEqual(povero.riserve[.denaro], 5)
    }

    /// Su ogni voce di fabbrica, ordinata a ciascuna delle quattro stazioni, la sonda tace: la
    /// stagione in cui il lavoro sarà pronto, che la sonda ricalcola da sé, è quella del Motore. Lo
    /// stato di partenza ha un reparto già migliorato, perché anche il mantenimento abbia su che
    /// cosa ordinarsi, e riserve abbondanti, perché il costo di una voce non decida quali si provano.
    func test_incarico_31_la_sonda_tace_su_ogni_voce_ordinata_a_ogni_stazione() throws {
        var controllate = 0
        var dichiarate: [IdentificatoreDati: [Stagione]] = [:]
        for stazione in 1...MomentoDellAnno.stazioniInvernali {
            var stato = try motore.statoIniziale()
            stato.forze = conFormazioni(stato.forze) { formazioni in
                formazioni.map { formazione in
                    guard formazione.nome == Self.bersaglioDiLupo.unita else { return formazione }
                    var migliorata = formazione
                    migliorata.composizione[Self.bersaglioDiLupo.elemento] =
                        migliorata.composizione[Self.bersaglioDiLupo.elemento].con(miglioramento: "addestramento_mirato")
                    return migliorata
                }
            }
            (stato, _) = motore.applica(.attendiInverno, stato: stato)
            for _ in 1..<stazione { (stato, _) = motore.applica(.prosegui, stato: stato) }
            XCTAssertEqual(stato.momento.stazione, stazione)
            stato.riserve = Riserve(["denaro": 10_000, "uomini": 1_000, "metalli": 1_000, "materiale": 1_000,
                                     "animali": 1_000])
            for voce in valoriRegno.voci {
                let bersaglio = voce.effetto.richiedeBersaglio ? motore.bersagli(di: voce, stato: stato).first : nil
                let comando = ComandoRegno.ordina(voce: voce.identificatore, bersaglio: bersaglio)
                XCTAssertTrue(motore.valida(comando, stato: stato).eValido,
                              "\(voce.identificatore) alla stazione \(stazione): \(String(describing: motore.valida(comando, stato: stato).motivo))")
                guard motore.valida(comando, stato: stato).eValido else { continue }
                let prima = stato
                var costo = Riserve()
                let (dopo, eventi) = motore.applica(comando, stato: stato)
                for evento in eventi {
                    if case .lavoroOrdinato(_, let c, let pronto, _) = evento {
                        costo = c
                        dichiarate[voce.identificatore, default: []].append(pronto)
                    }
                }
                stato = dopo
                let transizione = Transizione(prima: prima, dopo: dopo,
                                              passo: .spesa(costo: costo, durata: voce.durata,
                                                            stazioniPerStagione: valoriRegno.stazioniPerStagione))
                XCTAssertEqual(codici(transizione), [], "\(voce.identificatore) alla stazione \(stazione)")
                controllate += 1
            }
        }
        XCTAssertEqual(controllate, valoriRegno.voci.count * MomentoDellAnno.stazioniInvernali,
                       "ogni voce di fabbrica a ciascuna stazione")
        // Le transizioni coprono tre stagioni diverse: la sonda non tace perché tutto matura in primavera.
        XCTAssertEqual(Set(dichiarate.values.flatMap { $0 }), [.primavera, .estate, .autunno])
    }

    private func attendi(_ codice: String, _ trovati: Set<String>, in visti: inout Set<String>,
                         file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(trovati.contains(codice), "la sonda non riferisce «\(codice)»: ha visto \(trovati.sorted())",
                      file: file, line: line)
        visti.insert(codice)
    }

    /// I tredici invarianti della prima tappa (incarico 30).
    static let invariantiDellaPrimaTappa: Set<String> = [
        "saldo_negativo", "spesa_non_conservata", "entrata_non_conservata", "riporto_oltre_la_quota",
        "riporto_che_aggiunge", "anno_fuori_passo", "stazione_fuori_passo", "forze_cambiate_fuori_tempo",
        "rientro_maggiore_della_partenza", "reclute_non_arrivate", "lavori_fuori_tempo",
        "esito_incoerente", "campagna_fuori_passo"]

    /// I dieci invarianti della seconda tappa (incarico 31).
    static let invariantiDellaSecondaTappa: Set<String> = [
        "nome_duplicato", "nome_non_conservato", "formazione_in_patria_cambiata", "destinazione_fuori_regola",
        "mantenimento_non_conservato", "mantenimento_errato", "sciolto_senza_necessita", "sciolto_fuori_ordine",
        "miglioramento_fuori_regola", "pronto_fuori_regola"]

    func test_ogni_invariante_violato_di_proposito_e_riferito_col_suo_codice() throws {
        let t = try legittime()
        var visti = Set<String>()
        func attendi(_ codice: String, _ trovati: Set<String>, file: StaticString = #filePath, line: UInt = #line) {
            self.attendi(codice, trovati, in: &visti, file: file, line: line)
        }

        // La spesa: si spende ciò che non si ha; il saldo non scende del costo dichiarato; il
        // lavoro non entra in elenco; le forze cambiano d'inverno.
        var m = t["spesa"]!.dopo
        m.riserve[.uomini] = -1
        attendi("saldo_negativo", codici(t["spesa"]!, dopo: m))
        m = t["spesa"]!.dopo
        m.riserve[.denaro] += 5
        attendi("spesa_non_conservata", codici(t["spesa"]!, dopo: m))
        m = t["spesa"]!.dopo
        m.lavori.removeAll()
        attendi("lavori_fuori_tempo", codici(t["spesa"]!, dopo: m))
        m = t["spesa"]!.dopo
        m.forze = conUnaFormazioneInPiu(m.forze, atomi: 6)
        attendi("forze_cambiate_fuori_tempo", codici(t["spesa"]!, dopo: m))

        // L'inverno: l'entrata non arriva per intero; si comincia da una stazione che non è la prima.
        m = t["inverno"]!.dopo
        m.riserve[.metalli] -= 1
        attendi("entrata_non_conservata", codici(t["inverno"]!, dopo: m))
        m = t["inverno"]!.dopo
        m.momento = .inverno(stazione: 3)
        attendi("stazione_fuori_passo", codici(t["inverno"]!, dopo: m))
        m = t["stazione"]!.dopo
        m.momento = .inverno(stazione: 7)
        attendi("stazione_fuori_passo", codici(t["stazione"]!, dopo: m))

        // La primavera: avanza più della quota; il riporto aggiunge; l'anno non avanza; le reclute
        // non arrivano; un lavoro sopravvive.
        m = t["primavera"]!.dopo
        m.riserve[.denaro] = t["primavera"]!.prima.riserve[.denaro]
        attendi("riporto_oltre_la_quota", codici(t["primavera"]!, dopo: m))
        m = t["primavera"]!.dopo
        m.riserve[.animali] = t["primavera"]!.prima.riserve[.animali] + 1
        attendi("riporto_che_aggiunge", codici(t["primavera"]!, dopo: m))
        m = t["primavera"]!.dopo
        m.anno += 1
        attendi("anno_fuori_passo", codici(t["primavera"]!, dopo: m))
        m = t["primavera"]!.dopo
        m.forze = t["primavera"]!.prima.forze
        attendi("reclute_non_arrivate", codici(t["primavera"]!, dopo: m))
        m = t["primavera"]!.dopo
        m.lavori = t["primavera"]!.prima.lavori
        attendi("lavori_fuori_tempo", codici(t["primavera"]!, dopo: m))

        // Il rientro: torna più di quanto era partito; l'esito si contraddice.
        m = t["rientro"]!.dopo
        m.forze = conUnaFormazioneInPiu(t["rientro"]!.prima.forze, atomi: 40)
        attendi("rientro_maggiore_della_partenza", codici(t["rientro"]!, dopo: m))
        let contraddetto = EsitoCampagna(fronte: "guado", anno: 1, modo: .inverno, vincitore: .giocatore,
                                         giornate: 12, battaglieVinte: 0, battagliePerse: 0,
                                         superstiti: t["rientro"]!.dopo.forze)
        var conEsito = t["rientro"]!.dopo
        conEsito.campagna = .conclusa(contraddetto)
        attendi("esito_incoerente", codici(t["rientro"]!, dopo: conEsito, passo: .rientroDallaCampagna(contraddetto)))

        // La campagna dell'anno: aperta due volte; aperta d'inverno.
        m = t["apertura"]!.dopo
        m.momento = .inverno(stazione: 1)
        attendi("campagna_fuori_passo", codici(t["apertura"]!, dopo: m))

        // Ogni codice della sonda è stato visto mordere: un invariante aggiunto senza il suo mutante
        // fa fallire questa prova, non passa in silenzio.
        XCTAssertEqual(visti, Self.invariantiDellaPrimaTappa)
        print("SONDA-REGNO invarianti=\(Self.invariantiDellaPrimaTappa.count) mutanti_riferiti=\(visti.count)")
    }

    /// I dieci invarianti della seconda tappa (incarico 31), ciascuno violato di proposito in uno
    /// stato costruito qui a partire da una transizione legittima, e riferito col proprio codice.
    func test_incarico_31_ogni_invariante_nuovo_violato_di_proposito_e_riferito_col_suo_codice() throws {
        let t = try legittime()
        var visti = Set<String>()
        func attendi(_ codice: String, _ trovati: Set<String>, file: StaticString = #filePath, line: UInt = #line) {
            self.attendi(codice, trovati, in: &visti, file: file, line: line)
        }

        // I NOMI. Le reclute prendono il nome di una formazione che c'è già.
        var m = t["primavera"]!.dopo
        m.forze = conFormazioni(m.forze) { formazioni in
            formazioni.map { $0.nome == "lince" ? rinominata($0, "corvo") : $0 }
        }
        XCTAssertEqual(codici(t["primavera"]!, dopo: m), ["nome_duplicato"])
        attendi("nome_duplicato", codici(t["primavera"]!, dopo: m))
        // In primavera una formazione che c'era cambia nome.
        m = t["primavera"]!.dopo
        m.forze = conFormazioni(m.forze) { formazioni in
            formazioni.map { $0.nome == "lupo" ? rinominata($0, "muflone") : $0 }
        }
        attendi("nome_non_conservato", codici(t["primavera"]!, dopo: m))
        // Al rientro due formazioni che c'erano si scambiano di posto.
        m = t["rientro"]!.dopo
        m.forze = conFormazioni(m.forze) { formazioni in
            var scambiate = formazioni
            scambiate.swapAt(0, 1)
            return scambiate
        }
        XCTAssertEqual(codici(t["rientro"]!, dopo: m), ["nome_non_conservato"])
        attendi("nome_non_conservato", codici(t["rientro"]!, dopo: m))

        // CHI RESTA IN PATRIA. La formazione tenuta in patria torna dalla campagna diversa.
        m = t["rientro"]!.dopo
        m.forze = conFormazioni(m.forze) { formazioni in
            formazioni.map { formazione in
                guard formazione.nome == "cervo" else { return formazione }
                var cambiata = formazione
                cambiata.composizione = [Reparto(archetipo: "fanteria_leggera", atomi: 2)]
                return cambiata
            }
        }
        attendi("formazione_in_patria_cambiata", codici(t["rientro"]!, dopo: m))
        // La formazione tenuta in patria sparisce con la campagna.
        m = t["rientro"]!.dopo
        m.forze = conFormazioni(m.forze) { $0.filter { $0.nome != "cervo" } }
        attendi("formazione_in_patria_cambiata", codici(t["rientro"]!, dopo: m))

        // LA SCELTA DI CHI PARTE. Cambia destinazione anche un'altra unità; la scelta costa; la
        // scelta non ha effetto.
        m = t["destinazione"]!.dopo
        m.forze = m.forze.destinando("orso", alFronte: false)
        XCTAssertEqual(codici(t["destinazione"]!, dopo: m), ["destinazione_fuori_regola"])
        attendi("destinazione_fuori_regola", codici(t["destinazione"]!, dopo: m))
        m = t["destinazione"]!.dopo
        m.riserve[.denaro] -= 1
        attendi("destinazione_fuori_regola", codici(t["destinazione"]!, dopo: m))
        attendi("destinazione_fuori_regola", codici(t["destinazione"]!, dopo: t["destinazione"]!.prima))

        // IL MANTENIMENTO. Il saldo non è quello di prima più l'entrata meno il prelievo; il
        // prelievo tocca altro che il denaro.
        m = t["inverno"]!.dopo
        m.riserve[.denaro] += 1
        XCTAssertEqual(codici(t["inverno"]!, dopo: m), ["mantenimento_non_conservato"])
        attendi("mantenimento_non_conservato", codici(t["inverno"]!, dopo: m))
        m = t["inverno"]!.dopo
        m.mantenimento[.metalli] = 1
        m.riserve[.metalli] -= 1
        XCTAssertEqual(codici(t["inverno"]!, dopo: m), ["mantenimento_non_conservato"])
        attendi("mantenimento_non_conservato", codici(t["inverno"]!, dopo: m))
        // Il prelievo non è la quota dei reparti rimasti: una moneta in più, e il saldo torna.
        m = t["inverno"]!.dopo
        m.mantenimento[.denaro] += 1
        m.riserve[.denaro] -= 1
        XCTAssertEqual(codici(t["inverno"]!, dopo: m), ["mantenimento_errato"])
        attendi("mantenimento_errato", codici(t["inverno"]!, dopo: m))

        // LO SCIOGLIMENTO. Un reparto è sciolto benché il denaro bastasse: i conti tornano tutti,
        // tranne la necessità.
        m = t["inverno"]!.dopo
        let cervo = try XCTUnwrap(m.forze.formazioni.first { $0.nome == "cervo" })
        m.forze = conFormazioni(m.forze) { $0.filter { $0.nome != "cervo" } }
        m.sciolti = cervo.composizione.map { ElementoDelleForze(unita: "cervo", reparto: $0) }
        m.mantenimento[.denaro] -= 1
        m.riserve[.denaro] += 1
        XCTAssertEqual(codici(t["inverno"]!, dopo: m), ["sciolto_senza_necessita"])
        attendi("sciolto_senza_necessita", codici(t["inverno"]!, dopo: m))
        // Un reparto sparisce senza che nessuno lo dichiari sciolto: gli atomi non tornano.
        m = t["inverno"]!.dopo
        m.forze = conFormazioni(m.forze) { $0.filter { $0.nome != "cervo" } }
        attendi("sciolto_senza_necessita", codici(t["inverno"]!, dopo: m))
        // Nell'inverno povero si scioglie un reparto più anziano mentre ne resta uno più recente:
        // restano Corvo e la cavalleria di Falco, levata nell'anno 2; sciolti i due di Lupo, uno dei
        // quali levato nell'anno 1. La quota dei rimasti — due più quattro — rientra nelle dieci monete.
        m = t["inverno_povero"]!.dopo
        let primaDelPovero = t["inverno_povero"]!.prima
        m.forze = conFormazioni(primaDelPovero.forze) { $0.filter { $0.nome != "lupo" } }
        m.sciolti = try XCTUnwrap(primaDelPovero.forze.formazioni.first { $0.nome == "lupo" }).composizione
            .map { ElementoDelleForze(unita: "lupo", reparto: $0) }
        m.mantenimento[.denaro] = 6
        m.riserve[.denaro] = 4
        XCTAssertEqual(codici(t["inverno_povero"]!, dopo: m), ["sciolto_fuori_ordine"])
        attendi("sciolto_fuori_ordine", codici(t["inverno_povero"]!, dopo: m))

        // I MIGLIORAMENTI. L'addestramento ordinato non arriva; arriva a chi nessuno l'ha ordinato;
        // quello mantenuto si perde; quello non mantenuto resta.
        func conIlMiglioramento(_ forze: ForzeDelRegno, di bersaglio: BersaglioMilitare,
                                _ miglioramento: IdentificatoreDati?) -> ForzeDelRegno {
            conFormazioni(forze) { formazioni in
                formazioni.map { formazione in
                    guard formazione.nome == bersaglio.unita else { return formazione }
                    var cambiata = formazione
                    cambiata.composizione[bersaglio.elemento] =
                        cambiata.composizione[bersaglio.elemento].con(miglioramento: miglioramento)
                    return cambiata
                }
            }
        }
        m = t["primavera"]!.dopo
        m.forze = conIlMiglioramento(m.forze, di: Self.bersaglioDiLupo, nil)
        XCTAssertEqual(codici(t["primavera"]!, dopo: m), ["miglioramento_fuori_regola"])
        attendi("miglioramento_fuori_regola", codici(t["primavera"]!, dopo: m))
        m = t["primavera"]!.dopo
        m.forze = conIlMiglioramento(m.forze, di: BersaglioMilitare(unita: "corvo", elemento: 0), "addestramento_mirato")
        XCTAssertEqual(codici(t["primavera"]!, dopo: m), ["miglioramento_fuori_regola"])
        attendi("miglioramento_fuori_regola", codici(t["primavera"]!, dopo: m))
        m = t["primavera_col_miglioramento_mantenuto"]!.dopo
        m.forze = conIlMiglioramento(m.forze, di: Self.bersaglioDiLupo, nil)
        XCTAssertEqual(codici(t["primavera_col_miglioramento_mantenuto"]!, dopo: m), ["miglioramento_fuori_regola"])
        attendi("miglioramento_fuori_regola", codici(t["primavera_col_miglioramento_mantenuto"]!, dopo: m))
        m = t["primavera_col_miglioramento_perduto"]!.dopo
        m.forze = conIlMiglioramento(m.forze, di: Self.bersaglioDiLupo, "addestramento_mirato")
        XCTAssertEqual(codici(t["primavera_col_miglioramento_perduto"]!, dopo: m), ["miglioramento_fuori_regola"])
        attendi("miglioramento_fuori_regola", codici(t["primavera_col_miglioramento_perduto"]!, dopo: m))

        // QUANDO È PRONTO. Il lavoro dichiara un'altra stagione; dichiara un'altra stazione.
        func conLUltimoLavoro(_ stato: StatoRegno, pronto: Stagione? = nil, stazione: Int? = nil) -> StatoRegno {
            var nuovo = stato
            let ultimo = stato.lavori[stato.lavori.count - 1]
            nuovo.lavori[stato.lavori.count - 1] = LavoroOrdinato(
                voce: ultimo.voce, costo: ultimo.costo, stazione: stazione ?? ultimo.stazione, effetto: ultimo.effetto,
                pronto: pronto ?? ultimo.pronto, bersaglio: ultimo.bersaglio)
            return nuovo
        }
        XCTAssertEqual(t["spesa"]!.dopo.lavori.last?.pronto, .primavera)
        XCTAssertEqual(codici(t["spesa"]!, dopo: conLUltimoLavoro(t["spesa"]!.dopo, pronto: .estate)),
                       ["pronto_fuori_regola"])
        attendi("pronto_fuori_regola", codici(t["spesa"]!, dopo: conLUltimoLavoro(t["spesa"]!.dopo, pronto: .estate)))
        // La leva lunga ordinata alla seconda stazione matura in estate: dichiararla pronta in
        // primavera sarebbe promettere ciò che il calendario non dà.
        XCTAssertEqual(t["spesa_lunga"]!.dopo.lavori.last?.pronto, .estate)
        attendi("pronto_fuori_regola", codici(t["spesa_lunga"]!, dopo: conLUltimoLavoro(t["spesa_lunga"]!.dopo,
                                                                                    pronto: .primavera)))
        attendi("pronto_fuori_regola", codici(t["spesa_lunga"]!, dopo: conLUltimoLavoro(t["spesa_lunga"]!.dopo,
                                                                                    pronto: .inverno)))
        attendi("pronto_fuori_regola", codici(t["spesa"]!, dopo: conLUltimoLavoro(t["spesa"]!.dopo, stazione: 3)))

        XCTAssertEqual(visti, Self.invariantiDellaSecondaTappa)
        print("SONDA-REGNO-31 invarianti=\(Self.invariantiDellaSecondaTappa.count) mutanti_riferiti=\(visti.count)")
    }

    // MARK: - Nessun invariante senza mutante: lo specchio della sonda

    /// Specchio di `SondaInvariantiRegno.Violazione`, privo di valori associati e perciò
    /// `CaseIterable`, con due funzioni totali ed esaustive come in `CompatibilitaGiornaleTest`:
    /// aggiungere una violazione alla sonda non compila `specie(di:)`; aggiungerla allo specchio non
    /// compila `esemplare(di:)`; e a quel punto la prova pretende che il suo codice stia fra quelli
    /// che i mutanti di qui sopra fanno scattare.
    enum SpecieDiViolazione: CaseIterable {
        case saldoNegativo, spesaNonConservata, entrataNonConservata, riportoOltreLaQuota, riportoCheAggiunge
        case annoFuoriPasso, stazioneFuoriPasso, forzeCambiateFuoriTempo, rientroMaggioreDellaPartenza
        case recluteNonArrivate, lavoriFuoriTempo, esitoIncoerente, campagnaFuoriPasso
        case nomeDuplicato, nomeNonConservato, formazioneInPatriaCambiata, destinazioneFuoriRegola
        case mantenimentoNonConservato, mantenimentoErrato, scioltoSenzaNecessita, scioltoFuoriOrdine
        case miglioramentoFuoriRegola, prontoFuoriRegola
    }

    private func specie(di violazione: SondaInvariantiRegno.Violazione) -> SpecieDiViolazione {
        switch violazione {
        case .saldoNegativo: return .saldoNegativo
        case .spesaNonConservata: return .spesaNonConservata
        case .entrataNonConservata: return .entrataNonConservata
        case .riportoOltreLaQuota: return .riportoOltreLaQuota
        case .riportoCheAggiunge: return .riportoCheAggiunge
        case .annoFuoriPasso: return .annoFuoriPasso
        case .stazioneFuoriPasso: return .stazioneFuoriPasso
        case .forzeCambiateFuoriTempo: return .forzeCambiateFuoriTempo
        case .rientroMaggioreDellaPartenza: return .rientroMaggioreDellaPartenza
        case .recluteNonArrivate: return .recluteNonArrivate
        case .lavoriFuoriTempo: return .lavoriFuoriTempo
        case .esitoIncoerente: return .esitoIncoerente
        case .campagnaFuoriPasso: return .campagnaFuoriPasso
        case .nomeDuplicato: return .nomeDuplicato
        case .nomeNonConservato: return .nomeNonConservato
        case .formazioneInPatriaCambiata: return .formazioneInPatriaCambiata
        case .destinazioneFuoriRegola: return .destinazioneFuoriRegola
        case .mantenimentoNonConservato: return .mantenimentoNonConservato
        case .mantenimentoErrato: return .mantenimentoErrato
        case .scioltoSenzaNecessita: return .scioltoSenzaNecessita
        case .scioltoFuoriOrdine: return .scioltoFuoriOrdine
        case .miglioramentoFuoriRegola: return .miglioramentoFuoriRegola
        case .prontoFuoriRegola: return .prontoFuoriRegola
        }
    }

    private func esemplare(di specie: SpecieDiViolazione) -> SondaInvariantiRegno.Violazione {
        switch specie {
        case .saldoNegativo: return .saldoNegativo(.denaro)
        case .spesaNonConservata: return .spesaNonConservata(.denaro)
        case .entrataNonConservata: return .entrataNonConservata(.denaro)
        case .riportoOltreLaQuota: return .riportoOltreLaQuota(.denaro)
        case .riportoCheAggiunge: return .riportoCheAggiunge(.denaro)
        case .annoFuoriPasso: return .annoFuoriPasso
        case .stazioneFuoriPasso: return .stazioneFuoriPasso
        case .forzeCambiateFuoriTempo: return .forzeCambiateFuoriTempo
        case .rientroMaggioreDellaPartenza: return .rientroMaggioreDellaPartenza
        case .recluteNonArrivate: return .recluteNonArrivate
        case .lavoriFuoriTempo: return .lavoriFuoriTempo
        case .esitoIncoerente: return .esitoIncoerente
        case .campagnaFuoriPasso: return .campagnaFuoriPasso
        case .nomeDuplicato: return .nomeDuplicato
        case .nomeNonConservato: return .nomeNonConservato
        case .formazioneInPatriaCambiata: return .formazioneInPatriaCambiata
        case .destinazioneFuoriRegola: return .destinazioneFuoriRegola
        case .mantenimentoNonConservato: return .mantenimentoNonConservato(.denaro)
        case .mantenimentoErrato: return .mantenimentoErrato
        case .scioltoSenzaNecessita: return .scioltoSenzaNecessita
        case .scioltoFuoriOrdine: return .scioltoFuoriOrdine
        case .miglioramentoFuoriRegola: return .miglioramentoFuoriRegola
        case .prontoFuoriRegola: return .prontoFuoriRegola
        }
    }

    func test_incarico_31_ogni_violazione_della_sonda_ha_il_proprio_mutante() {
        for specieAttesa in SpecieDiViolazione.allCases {
            XCTAssertEqual(specie(di: esemplare(di: specieAttesa)), specieAttesa)
        }
        let codici = SpecieDiViolazione.allCases.map { SondaInvariantiRegno.codice(di: esemplare(di: $0)) }
        XCTAssertEqual(Set(codici).count, codici.count, "due violazioni hanno lo stesso codice")
        XCTAssertEqual(codici.count, 23, "le tredici della prima tappa e le dieci della seconda")
        XCTAssertTrue(Self.invariantiDellaPrimaTappa.isDisjoint(with: Self.invariantiDellaSecondaTappa))
        XCTAssertEqual(Set(codici), Self.invariantiDellaPrimaTappa.union(Self.invariantiDellaSecondaTappa),
                       "una violazione della sonda è priva di mutante, oppure un mutante attende un codice che non esiste")
    }
}
