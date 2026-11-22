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
                                                 archetipiNoti: Set(valori.archetipi.keys))
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
            delFronte: base, forze: try ForzeDelRegno.iniziali(valoriRegno.forzeIniziali),
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

    private func legittime() throws -> [String: Transizione] {
        var esito: [String: Transizione] = [:]
        var stato = try motore.statoIniziale()
        func applica(_ comando: ComandoRegno) -> [EventoRegno] {
            let (nuovo, eventi) = motore.applica(comando, stato: stato)
            stato = nuovo
            return eventi
        }
        var prima = stato
        _ = applica(.apriCampagna(fronte: "guado"))
        esito["apertura"] = Transizione(prima: prima, dopo: stato, passo: .aperturaDellaCampagna)

        prima = stato
        var superstiti = stato.forze.formazioni
        superstiti.removeLast()
        let esitoCampagna = EsitoCampagna(fronte: "guado", anno: 1, modo: .annientamento, vincitore: .giocatore,
                                          giornate: 12, battaglieVinte: 1, battagliePerse: 0,
                                          superstiti: .sciami(superstiti))
        _ = motore.applicaEsito(esitoCampagna, in: &stato)
        esito["rientro"] = Transizione(prima: prima, dopo: stato, passo: .rientroDallaCampagna(esitoCampagna))

        prima = stato
        var entrata = Riserve()
        for evento in applica(.attendiInverno) { if case .invernoCominciato(_, let e) = evento { entrata = e } }
        esito["inverno"] = Transizione(prima: prima, dopo: stato, passo: .arrivoDellInverno(entrata: entrata))

        prima = stato
        var costo = Riserve()
        for evento in applica(.ordina(voce: "leva_fanteria_leggera")) {
            if case .lavoroOrdinato(_, let c, _) = evento { costo = c }
        }
        esito["spesa"] = Transizione(prima: prima, dopo: stato, passo: .spesa(costo: costo))

        prima = stato
        _ = applica(.prosegui)
        esito["stazione"] = Transizione(prima: prima, dopo: stato, passo: .stazioneSuccessiva)
        _ = applica(.prosegui)
        _ = applica(.prosegui)

        prima = stato
        _ = applica(.prosegui)
        esito["primavera"] = Transizione(prima: prima, dopo: stato,
                                         passo: .primavera(quotaRiporto: valoriRegno.quotaRiporto, entrata: entrata))
        return esito
    }

    private func codici(_ t: Transizione, dopo: StatoRegno? = nil, passo: SondaInvariantiRegno.Passo? = nil) -> Set<String> {
        Set(sonda.controlla(prima: t.prima, dopo: dopo ?? t.dopo, passo: passo ?? t.passo,
                            giornateOperative: valoriRegno.giornateOperative)
            .map(SondaInvariantiRegno.codice(di:)))
    }

    func test_sulle_transizioni_del_motore_la_sonda_tace() throws {
        let legittime = try legittime()
        XCTAssertEqual(legittime.count, 6)
        for (nome, transizione) in legittime.sorted(by: { $0.key < $1.key }) {
            XCTAssertEqual(codici(transizione), [], "transizione legittima «\(nome)»")
        }
    }

    func test_ogni_invariante_violato_di_proposito_e_riferito_col_suo_codice() throws {
        let t = try legittime()
        var visti = Set<String>()
        func attendi(_ codice: String, _ trovati: Set<String>, file: StaticString = #filePath, line: UInt = #line) {
            XCTAssertTrue(trovati.contains(codice), "la sonda non riferisce «\(codice)»: ha visto \(trovati.sorted())",
                          file: file, line: line)
            visti.insert(codice)
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
        m.forze = m.forze.ricevendo([.reclutaReparto(archetipo: "fanteria_leggera", atomi: 6)])
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
        m.forze = t["rientro"]!.prima.forze.ricevendo([.reclutaReparto(archetipo: "fanteria_leggera", atomi: 40)])
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
        let tutti: Set<String> = [
            "saldo_negativo", "spesa_non_conservata", "entrata_non_conservata", "riporto_oltre_la_quota",
            "riporto_che_aggiunge", "anno_fuori_passo", "stazione_fuori_passo", "forze_cambiate_fuori_tempo",
            "rientro_maggiore_della_partenza", "reclute_non_arrivate", "lavori_fuori_tempo",
            "esito_incoerente", "campagna_fuori_passo"]
        XCTAssertEqual(visti, tutti)
        print("SONDA-REGNO invarianti=\(tutti.count) mutanti_riferiti=\(visti.count)")
    }
}
