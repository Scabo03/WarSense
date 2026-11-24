import XCTest
import Motore
import Dati
import Contenuti

/// La seconda tappa del regno (incarico 31) vista dal FRONTE: i nomi che i gruppi portano (regola
/// A), le reclute che entrano come arrivi dalla patria (B), le formazioni tenute in patria che non
/// compaiono (C). Qui lavorano il ponte fra regno e campagna, la fabbrica della campagna e il suo
/// Motore; ciò che il regno fa di suo sta in `RegnoSecondaTappaTest`.
final class ArriviDallaPatriaTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    var motore: MotoreCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
    }

    // MARK: - Attrezzi

    private let dueGiornate = CalendarioDiCampagna(anno: 2, giornatePerStagione: 2)
    private let trentaGiornate = CalendarioDiCampagna(anno: 2, giornatePerStagione: 30)

    private func scenarioDiFabbrica(_ nome: String) throws -> ScenarioCampagna {
        let dati = try Data(contentsOf: Contenuti.valoriDiFabbrica.appendingPathComponent("scenari-campagna.json"))
        return try XCTUnwrap(try JSONDecoder().decode([String: ScenarioCampagna].self, from: dati)[nome])
    }

    private func leggera(_ atomi: Int, leva: Int? = nil) -> Reparto {
        Reparto(archetipo: "fanteria_leggera", atomi: atomi, leva: leva)
    }
    private func pesante(_ atomi: Int, migliorata: Bool = false) -> Reparto {
        Reparto(archetipo: "fanteria_pesante", atomi: atomi, miglioramento: migliorata ? "addestramento_mirato" : nil)
    }

    private func armata(_ nome: String, _ composizione: [Reparto], inPatria: Bool = false,
                        arrivo: Stagione? = nil) -> FormazioneDelRegno {
        FormazioneDelRegno(nome: IdentificatoreDati(nome), categoria: .armato, composizione: composizione,
                           inPatria: inPatria, arrivo: arrivo)
    }

    /// Un fronte sulla pianura lunga, con l'avversario lontano e il quartier generale del giocatore
    /// — riga 10, casella 6 — LIBERO: le caselle di partenza gli stanno accanto.
    private var fronteColQuartierGeneraleLibero: ScenarioCampagna {
        let reparti: [ScenarioCampagna.RepartoIniziale] = [.init(archetipo: "fanteria_leggera", atomi: 6)]
        return ScenarioCampagna(
            mappa: "pianura_lunga",
            gruppiGiocatore: [.init(riga: 9, colonna: 5, composizione: reparti),
                              .init(riga: 9, colonna: 6, composizione: reparti),
                              .init(riga: 10, colonna: 5, composizione: reparti),
                              .init(riga: 10, colonna: 7, composizione: reparti)],
            gruppiAvversario: [.init(riga: 1, colonna: 5, composizione: reparti)])
    }

    private let quartierGenerale = Cella(riga: 10, colonna: 6)

    /// Le forze di un regno al suo secondo anno: due armate che c'erano; le reclute dell'inverno
    /// in tre formazioni, pronte in primavera, in estate e in autunno, e una che matura con
    /// l'inverno; una formazione che il giocatore tiene in patria.
    private var forzeDelSecondoAnno: ForzeDelRegno {
        .sciami(formazioni: [
            armata("corvo", [leggera(6)]),
            armata("lupo", [leggera(18), pesante(8, migliorata: true)]),
            armata("orso", [leggera(4)], inPatria: true),
            armata("cervo", [leggera(6, leva: 1)], arrivo: .primavera),
            armata("lince", [Reparto(archetipo: "cavalleria_manovrata", atomi: 6, leva: 1)], arrivo: .estate),
            armata("aquila", [leggera(6, leva: 1)], arrivo: .autunno),
            armata("volpe", [leggera(6, leva: 1)], arrivo: .inverno),
        ], prossimoNome: 8)
    }

    private func scenario(_ fronte: ScenarioCampagna, _ forze: ForzeDelRegno,
                          _ calendario: CalendarioDiCampagna) throws -> ScenarioCampagna {
        try PonteRegnoCampagna.scenario(delFronte: fronte, forze: forze, calendario: calendario, valori: valoriCampagna)
    }

    private func crea(_ scenario: ScenarioCampagna) throws -> StatoCampagna {
        try FabbricaCampagna.crea(scenario: scenario, valori: valoriCampagna, archetipiNoti: Set(valori.archetipi.keys))
    }

    /// Chiude una giornata con l'ordine di restare a ogni gruppo delle due parti.
    @discardableResult
    private func chiudiUnaGiornata(_ stato: inout StatoCampagna) -> [EventoCampagna] {
        var eventi: [EventoCampagna] = []
        let giorno = stato.giorno
        for gruppo in stato.gruppiOrdinati where stato.giorno == giorno && stato.conclusione == nil {
            guard stato.gruppi[gruppo.id]?.haConclusoLaGiornata == false,
                  let ordine = motore.ordineDiRestare(per: gruppo.id, parte: gruppo.parte, stato: stato) else { continue }
            let (nuovo, ev) = motore.applica(ordine, parte: gruppo.parte, stato: stato)
            stato = nuovo
            eventi += ev
        }
        return eventi
    }

    private func nomi(_ stato: StatoCampagna, di parte: Parte) -> [IdentificatoreDati] {
        stato.gruppiOrdinati.filter { $0.parte == parte }.map(\.nome)
    }

    private func gruppo(_ nome: String, _ stato: StatoCampagna, file: StaticString = #filePath,
                        line: UInt = #line) throws -> Gruppo {
        try XCTUnwrap(stato.gruppiOrdinati.first { $0.nome == nome }, "manca il gruppo \(nome)", file: file, line: line)
    }

    /// Gli arrivi annunciati da una serie di eventi.
    private func arrivi(_ eventi: [EventoCampagna]) -> [(nome: IdentificatoreDati, casella: Cella)] {
        eventi.compactMap { evento in
            if case .arrivoDallaPatria(_, let nome, let casella) = evento { return (nome, casella) } else { return nil }
        }
    }

    /// Gli arrivi annotati nel registro, col giorno.
    private func arriviNelRegistro(_ stato: StatoCampagna) -> [String] {
        stato.registro.compactMap { voce in
            if case .arrivoDallaPatria(let nome, let casella) = voce.fatto {
                return "\(voce.giorno):\(nome):\(casella.riga),\(casella.colonna)"
            }
            return nil
        }
    }

    /// La casella libera più vicina al quartier generale, a parità nell'ordine di lettura: la
    /// regola dell'arrivo, ricalcolata qui sullo stato PRIMA dell'arrivo.
    private func casellaAttesa(_ stato: StatoCampagna) -> Cella? {
        let qg = stato.mappa.quartierGenerale(di: .giocatore)
        var occupate = Set(stato.gruppi.values.map(\.posizione)).union(stato.forzeNemiche)
        for gruppo in stato.gruppi.values where gruppo.parte == .giocatore {
            if let meta = gruppo.marcia?.destinazione { occupate.insert(meta) }
        }
        var migliore: Cella?
        for casella in stato.griglia.tutteLeCaselle.sorted() where !occupate.contains(casella) {
            if migliore == nil || stato.griglia.distanza(qg, casella) < stato.griglia.distanza(qg, migliore!) {
                migliore = casella
            }
        }
        return migliore
    }

    /// Conclude la campagna con una battaglia fra il primo gruppo armato di ciascuna parte.
    @discardableResult
    private func combatti(_ stato: inout StatoCampagna, sopravviveIlGiocatore: Bool,
                          sopravviveLAvversario: Bool) throws -> [EventoCampagna] {
        let mio = try XCTUnwrap(stato.gruppiOrdinati.first { $0.parte == .giocatore && $0.categoria.eArmata })
        let suo = try XCTUnwrap(stato.gruppiOrdinati.first { $0.parte == .avversario && $0.categoria.eArmata })
        stato.gruppi[suo.id]!.posizione = mio.posizione
        stato.battaglieInSospeso = [BattagliaInSospeso(
            identificatore: "battaglia-di-prova", casella: mio.posizione, gruppoGiocatore: mio.id,
            gruppoAvversario: suo.id, primoOccupante: .giocatore, imboscante: nil, giorno: stato.giorno)]
        let esito = EsitoInCampagna(
            identificatore: "battaglia-di-prova", casella: mio.posizione,
            sconfitto: sopravviveIlGiocatore ? .avversario : .giocatore, modo: .annientamento,
            gruppoGiocatore: mio.id, gruppoAvversario: suo.id,
            composizioneGiocatore: sopravviveIlGiocatore ? mio.composizione : [],
            composizioneAvversario: sopravviveLAvversario ? suo.composizione : [],
            posizioneGiocatore: sopravviveIlGiocatore ? mio.posizione : nil,
            posizioneAvversario: sopravviveLAvversario ? mio.posizione : nil)
        return motore.applicaEsitoInCampagna(esito, in: &stato)
    }

    // MARK: - A. I nomi sul fronte

    func test_incarico_31_A_sul_fronte_ogni_gruppo_porta_il_nome_della_propria_formazione() throws {
        let regno = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica, archetipiNoti: Set(valori.archetipi.keys),
                                               miglioramentiNoti: Set(valori.miglioramenti.keys))
        let forze = try ForzeDelRegno.iniziali(regno.forzeIniziali, nomi: regno.nomiDelleUnita)
        XCTAssertEqual(forze.formazioni.map(\.nome), ["corvo", "lupo", "falco", "orso", "cervo"])
        for fronte in regno.fronti {
            let base = try scenarioDiFabbrica(fronte.scenario)
            let scenario = try scenario(base, forze, dueGiornate)
            XCTAssertEqual(scenario.gruppiGiocatore.map(\.nome), forze.formazioni.map(\.nome), fronte.identificatore)
            XCTAssertTrue(scenario.gruppiAvversario.allSatisfy { $0.nome == nil },
                          "l'avversario non dichiara nomi: glieli dà la fabbrica, fra quelli liberi")
            let stato = try crea(scenario)
            XCTAssertEqual(nomi(stato, di: .giocatore), ["corvo", "lupo", "falco", "orso", "cervo"], fronte.identificatore)
            XCTAssertEqual(nomi(stato, di: .avversario), ["muflone", "ermellino", "sciacallo"],
                           "\(fronte.identificatore): gli ultimi nomi della lista, presi dal fondo")
            // La formazione e il gruppo sono la stessa cosa: stesso nome, stessa categoria, stessi reparti.
            for formazione in forze.formazioni {
                let gruppo = try gruppo(formazione.nome, stato)
                XCTAssertEqual(gruppo.parte, .giocatore)
                XCTAssertEqual(gruppo.categoria, formazione.categoria)
                XCTAssertEqual(gruppo.composizione, formazione.composizione)
            }
            XCTAssertEqual(Set(stato.gruppi.values.map(\.nome)).count, stato.gruppi.count, "nessun nome due volte")
        }
    }

    func test_incarico_31_A_i_gruppi_avversari_non_prendono_mai_un_nome_del_regno() throws {
        // Il regno porta nomi sparsi per la lista, anche in fondo: due al fronte, uno in patria,
        // tre in arrivo — uno dei quali soltanto con l'inverno. L'avversario prende dal fondo gli
        // ultimi che restano: Muflone è del regno ed Ermellino è in patria, e la ricerca li salta.
        let forze = ForzeDelRegno.sciami(formazioni: [
            armata("lupo", [leggera(6)]),
            armata("muflone", [leggera(6)]),
            armata("ermellino", [leggera(6)], inPatria: true),
            armata("lince", [leggera(6, leva: 1)], arrivo: .primavera),
            armata("poiana", [leggera(6, leva: 1)], arrivo: .estate),
            armata("ariete", [leggera(6, leva: 1)], arrivo: .inverno),
        ], prossimoNome: 9)
        let delRegno = Set(forze.formazioni.map(\.nome))
        for nome in ["campagna_piccola", "campagna_media", "campagna_grande"] {
            let stato = try crea(try scenario(try scenarioDiFabbrica(nome), forze, dueGiornate))
            let avversari = nomi(stato, di: .avversario)
            XCTAssertEqual(avversari, ["sciacallo", "donnola", "ghiro"], nome)
            XCTAssertTrue(delRegno.isDisjoint(with: avversari), "\(nome): un gruppo avversario porta un nome del regno")
            XCTAssertEqual(Set(nomi(stato, di: .giocatore)), ["lupo", "muflone", "lince"],
                           "\(nome): al fronte chi è partito e chi è arrivato con la prima giornata")
            XCTAssertEqual(stato.nomiRiservati.map(Set.init), delRegno.union(avversari),
                           "\(nome): la campagna tiene da parte ogni nome del regno e quelli che l'avversario ha preso")
            XCTAssertEqual(motore.prossimoNomeLibero(stato)?.nome, "corvo",
                           "\(nome): chi nasce sul fronte prende il primo nome che nessuna delle due parti tiene")
        }
    }

    /// I NOMI DELLE DUE PARTI D'ANNO IN ANNO (incarico 31, trovato a tappa costruita). Il regno
    /// assegna i nomi dall'inizio della lista chiusa; nella campagna di un regno l'avversario li
    /// prende dal FONDO. Così i gruppi nemici portano gli stessi nomi ogni anno, e le reclute di
    /// un inverno non ricevono il nome che l'anno prima era di un gruppo nemico. Finché
    /// l'avversario prendeva i primi nomi liberi, al primo anno erano Lince, Aquila e Volpe: proprio
    /// quelli che la primavera dopo toccavano alle formazioni nuove del regno.
    func test_incarico_31_A_l_avversario_porta_gli_stessi_nomi_ogni_anno_e_le_reclute_non_li_ereditano() throws {
        let regno = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica, archetipiNoti: Set(valori.archetipi.keys),
                                               miglioramentiNoti: Set(valori.miglioramenti.keys))
        let primoAnno = try ForzeDelRegno.iniziali(regno.forzeIniziali, nomi: regno.nomiDelleUnita)
        // L'inverno del primo anno: una leva pronta in primavera e una pronta in estate.
        let secondoAnno = primoAnno.dopoLaPrimavera(
            reclute: [(effetto: .reclutaReparto(archetipo: "fanteria_leggera", atomi: 6), pronto: .primavera),
                      (effetto: .reclutaReparto(archetipo: "cavalleria_manovrata", atomi: 6), pronto: .estate)],
            miglioramenti: [], mantenuti: [], anno: 1, nomi: regno.nomiDelleUnita).forze
        let delRegnoAlSecondoAnno = secondoAnno.formazioni.map(\.nome)
        XCTAssertEqual(delRegnoAlSecondoAnno, ["corvo", "lupo", "falco", "orso", "cervo", "lince", "aquila"])

        for fronte in regno.fronti {
            let base = try scenarioDiFabbrica(fronte.scenario)
            let uno = try crea(try scenario(base, primoAnno, CalendarioDiCampagna(anno: 1, giornatePerStagione: 30)))
            let due = try crea(try scenario(base, secondoAnno, CalendarioDiCampagna(anno: 2, giornatePerStagione: 30)))
            let nemiciDelPrimoAnno = nomi(uno, di: .avversario)
            let nemiciDelSecondoAnno = nomi(due, di: .avversario)
            print("NOMI-DELLE-PARTI-31 fronte=\(fronte.identificatore) nemici_anno_1=\(nemiciDelPrimoAnno) "
                  + "nemici_anno_2=\(nemiciDelSecondoAnno) regno_anno_2=\(delRegnoAlSecondoAnno)")
            XCTAssertEqual(nemiciDelSecondoAnno, nemiciDelPrimoAnno,
                           "\(fronte.identificatore): i gruppi nemici portano gli stessi nomi ogni anno")
            XCTAssertTrue(Set(delRegnoAlSecondoAnno).isDisjoint(with: nemiciDelPrimoAnno),
                          "\(fronte.identificatore): una formazione del regno porta il nome che l'anno prima era di un gruppo nemico")
            XCTAssertEqual(nemiciDelPrimoAnno, ["muflone", "ermellino", "sciacallo"],
                           "\(fronte.identificatore): gli ultimi nomi della lista, dal fondo")
            // Chi nasce sul fronte prende il primo nome che né il regno né l'avversario tengono.
            XCTAssertEqual(motore.prossimoNomeLibero(uno)?.nome, "lince", fronte.identificatore)
            XCTAssertEqual(motore.prossimoNomeLibero(due)?.nome, "volpe", fronte.identificatore)
        }
    }

    func test_incarico_31_A_il_distaccamento_riceve_un_nome_che_nessuna_formazione_del_regno_porta() throws {
        // Falco è tenuto in patria: è proprio il nome che la lista darebbe al primo distaccamento.
        // Cervo matura con l'inverno, e nemmeno lui è sul fronte: sarebbe il nome del secondo.
        let forze = ForzeDelRegno.sciami(formazioni: [
            armata("corvo", [leggera(6)]),
            armata("lupo", [leggera(18), pesante(8), leggera(4)]),
            armata("falco", [leggera(6)], inPatria: true),
            armata("cervo", [leggera(6, leva: 1)], arrivo: .inverno),
        ], prossimoNome: 5)
        var stato = try crea(try scenario(try scenarioDiFabbrica("campagna_piccola"), forze, dueGiornate))
        XCTAssertEqual(nomi(stato, di: .giocatore), ["corvo", "lupo"])
        XCTAssertEqual(nomi(stato, di: .avversario), ["muflone", "ermellino", "sciacallo"])
        XCTAssertEqual(motore.prossimoNomeLibero(stato)?.nome, "orso",
                       "non Falco, tenuto in patria: il primo nome che nessuno porta")

        // Lupo stacca il reparto pesante, poi — il giorno dopo — il terzo reparto.
        let lupo = try gruppo("lupo", stato)
        let primo = try XCTUnwrap(stato.griglia.vicini(di: lupo.posizione).sorted().first {
            motore.valida(.divisione(gruppo: lupo.id, repartiStaccati: [1], a: $0), parte: .giocatore, stato: stato).eValido
        })
        var eventi: [EventoCampagna]
        (stato, eventi) = motore.applica(.divisione(gruppo: lupo.id, repartiStaccati: [1], a: primo),
                                         parte: .giocatore, stato: stato)
        guard case .gruppoDiviso(_, let origine, _, let nomeDelPrimo, _)? = eventi.first else {
            return XCTFail("la divisione si dichiara con un evento")
        }
        XCTAssertEqual(origine, "lupo")
        XCTAssertEqual(nomeDelPrimo, "orso")
        chiudiUnaGiornata(&stato)
        XCTAssertEqual(stato.giorno, 2)
        let secondo = try XCTUnwrap(stato.griglia.vicini(di: lupo.posizione).sorted().first {
            motore.valida(.divisione(gruppo: lupo.id, repartiStaccati: [1], a: $0), parte: .giocatore, stato: stato).eValido
        })
        (stato, eventi) = motore.applica(.divisione(gruppo: lupo.id, repartiStaccati: [1], a: secondo),
                                         parte: .giocatore, stato: stato)
        guard case .gruppoDiviso(_, _, _, let nomeDelSecondo, _)? = eventi.first else {
            return XCTFail("la divisione si dichiara con un evento")
        }
        XCTAssertEqual(nomeDelSecondo, "lince", "Cervo è del regno, e la lista lo salta")
        XCTAssertEqual(nomi(stato, di: .giocatore), ["corvo", "lupo", "orso", "lince"])
        let delRegno = Set(forze.formazioni.map(\.nome))
        XCTAssertFalse(delRegno.contains(nomeDelPrimo))
        XCTAssertFalse(delRegno.contains(nomeDelSecondo))
        XCTAssertEqual(Set(stato.gruppi.values.map(\.nome)).count, stato.gruppi.count, "nessun nome due volte sul fronte")

        // La campagna si conclude, e i distaccamenti tornano in patria col nome che hanno ricevuto.
        try combatti(&stato, sopravviveIlGiocatore: true, sopravviveLAvversario: false)
        let esito = try XCTUnwrap(PonteRegnoCampagna.esito(da: stato, fronte: "guado"))
        XCTAssertEqual(esito.superstiti.formazioni.map(\.nome), ["corvo", "lupo", "orso", "lince"])
        XCTAssertEqual(esito.superstiti.formazioni.first { $0.nome == "orso" }?.composizione, [pesante(8)])
        XCTAssertEqual(esito.superstiti.formazioni.first { $0.nome == "lince" }?.composizione, [leggera(4)])
        XCTAssertEqual(esito.superstiti.formazioni.first { $0.nome == "lupo" }?.composizione, [leggera(18)])
        // Nel regno: chi c'era al suo posto, chi è nato sul fronte in coda, e nessun nome ripetuto.
        let dopo = forze.dopoLaCampagna(rientrano: esito.superstiti)
        XCTAssertEqual(dopo.formazioni.map(\.nome), ["corvo", "lupo", "falco", "cervo", "orso", "lince"])
        XCTAssertEqual(Set(dopo.formazioni.map(\.nome)).count, 6)
        XCTAssertEqual(dopo.formazioni[2], forze.formazioni[2], "Falco, rimasto in patria, è identico")
        XCTAssertEqual(dopo.formazioni[3], forze.formazioni[3])
    }

    /// Le impronte degli stati iniziali delle tre campagne di prova, calcolate dal codice della
    /// build 31 (commit `41cccff`, esportato in una cartella di lavoro) sugli stessi scenari.
    private static let improntePrimaDellaSecondaTappa: [String: String] = [
        "campagna_piccola": "83f87315dc37f21cbcc339e2a88ffbd625bde1553dd70967697fb9d09166ecb3",
        "campagna_media": "1bce375c0670eafae12cc8ae0e7ab981d25a336160afac5684c64f6267ef4376",
        "campagna_grande": "81bbeb0e77b6528d649a1524b396b2267aa6f3f7f63d0fa1208dbd6f06ae73fb",
    ]

    func test_incarico_31_A_nelle_campagne_di_prova_nulla_cambia_stessi_nomi_stessa_impronta_di_prima() throws {
        let lista = valoriCampagna.nomiGruppi
        for (nome, improntaDiPrima) in Self.improntePrimaDellaSecondaTappa.sorted(by: { $0.key < $1.key }) {
            let scenario = try scenarioDiFabbrica(nome)
            XCTAssertTrue((scenario.gruppiGiocatore + scenario.gruppiAvversario).allSatisfy { $0.nome == nil })
            XCTAssertTrue(scenario.nomiRiservati.isEmpty)
            XCTAssertTrue(scenario.arrivi.isEmpty)
            let stato = try crea(scenario)
            let quanti = scenario.gruppiGiocatore.count + scenario.gruppiAvversario.count
            // I nomi sono i primi della lista, nell'ordine in cui i gruppi sono dichiarati: prima
            // quelli del giocatore, poi quelli dell'avversario.
            XCTAssertEqual(stato.gruppiOrdinati.map(\.nome), Array(lista.prefix(quanti)), nome)
            XCTAssertEqual(stato.prossimoIndiceNome, quanti, nome)
            XCTAssertNil(stato.nomiRiservati, nome)
            XCTAssertNil(stato.arriviInAttesa, nome)
            XCTAssertTrue(stato.registro.isEmpty, nome)
            XCTAssertEqual(motore.prossimoNomeLibero(stato)?.nome, lista[quanti], nome)
            XCTAssertEqual(stato.impronta(), improntaDiPrima,
                           "\(nome): lo stato iniziale non ha più l'impronta che aveva con la build 31")
        }
    }

    func test_incarico_31_A_lo_scenario_senza_nomi_si_codifica_come_prima_e_quello_coi_nomi_si_rilegge() throws {
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = [.sortedKeys]
        // Lo scenario di prova: nessuna delle chiavi nuove compare, e la codifica è quella di prima.
        let diProva = ScenarioCampagna(mappa: "guado", gruppiGiocatore: [
            .init(riga: 4, colonna: 2, composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)])])
        XCTAssertEqual(String(data: try codificatore.encode(diProva), encoding: .utf8),
                       #"{"gruppi_giocatore":[{"colonna":2,"composizione":[{"archetipo":"fanteria_leggera","atomi":6}],"riga":4}],"mappa":"guado"}"#)
        // Lo scenario del regno porta tutto, e si rilegge uguale.
        let delRegno = try scenario(fronteColQuartierGeneraleLibero, forzeDelSecondoAnno, dueGiornate)
        let testo = String(data: try codificatore.encode(delRegno), encoding: .utf8)!
        for chiave in ["\"nome\":\"corvo\"", "\"nomi_riservati\":[\"orso\",\"volpe\"]", "\"arrivi\":[",
                       "\"miglioramento\":\"addestramento_mirato\"", "\"leva\":1", "\"giorno\":3"] {
            XCTAssertTrue(testo.contains(chiave), "manca \(chiave) in \(testo)")
        }
        XCTAssertEqual(try JSONDecoder().decode(ScenarioCampagna.self, from: try codificatore.encode(delRegno)), delRegno)
        // E lo stato che ne nasce si codifica e si rilegge sullo stesso stato.
        let stato = try crea(delRegno)
        let riletto = try JSONDecoder().decode(StatoCampagna.self, from: try JSONEncoder().encode(stato))
        XCTAssertEqual(riletto, stato)
        XCTAssertEqual(riletto.impronta(), stato.impronta())
    }

    func test_incarico_31_la_fabbrica_rifiuta_i_nomi_duplicati_e_gli_arrivi_incoerenti() throws {
        let reparti: [ScenarioCampagna.RepartoIniziale] = [.init(archetipo: "fanteria_leggera", atomi: 6)]
        func rifiuto(_ scenario: ScenarioCampagna, file: StaticString = #filePath,
                     line: UInt = #line) -> FabbricaCampagna.ErroreScenario? {
            var errore: FabbricaCampagna.ErroreScenario?
            XCTAssertThrowsError(try crea(scenario), file: file, line: line) {
                errore = $0 as? FabbricaCampagna.ErroreScenario
            }
            return errore
        }
        // Due gruppi con lo stesso nome.
        XCTAssertEqual(rifiuto(ScenarioCampagna(mappa: "guado", gruppiGiocatore: [
            .init(riga: 4, colonna: 2, composizione: reparti, nome: "corvo"),
            .init(riga: 4, colonna: 3, composizione: reparti, nome: "corvo")])), .nomeDuplicato("corvo"))
        // Un gruppo e un arrivo con lo stesso nome.
        XCTAssertEqual(rifiuto(ScenarioCampagna(
            mappa: "guado", gruppiGiocatore: [.init(riga: 4, colonna: 2, composizione: reparti, nome: "corvo")],
            arrivi: [.init(giorno: 3, nome: "corvo", composizione: reparti)])), .nomeDuplicato("corvo"))
        // Due arrivi con lo stesso nome.
        XCTAssertEqual(rifiuto(ScenarioCampagna(
            mappa: "guado", gruppiGiocatore: [.init(riga: 4, colonna: 2, composizione: reparti, nome: "corvo")],
            arrivi: [.init(giorno: 3, nome: "lupo", composizione: reparti),
                     .init(giorno: 5, nome: "lupo", composizione: reparti)])), .nomeDuplicato("lupo"))
        // Un arrivo senza giornata, senza reparti, o con un reparto vuoto.
        func conArrivo(_ arrivo: ScenarioCampagna.ArrivoProgrammato) -> ScenarioCampagna {
            ScenarioCampagna(mappa: "guado",
                             gruppiGiocatore: [.init(riga: 4, colonna: 2, composizione: reparti, nome: "corvo")],
                             arrivi: [arrivo])
        }
        XCTAssertEqual(rifiuto(conArrivo(.init(giorno: 0, nome: "lupo", composizione: reparti))), .arrivoIncoerente("lupo"))
        XCTAssertEqual(rifiuto(conArrivo(.init(giorno: -3, nome: "lupo", composizione: reparti))), .arrivoIncoerente("lupo"))
        XCTAssertEqual(rifiuto(conArrivo(.init(giorno: 3, nome: "lupo", composizione: []))), .arrivoIncoerente("lupo"))
        XCTAssertEqual(rifiuto(conArrivo(.init(giorno: 3, nome: "lupo", composizione: [
            .init(archetipo: "fanteria_leggera", atomi: 0)]))), .arrivoIncoerente("lupo"))
        XCTAssertEqual(rifiuto(conArrivo(.init(giorno: 3, nome: "lupo", composizione: [
            .init(archetipo: "archetipo_che_non_esiste", atomi: 6)]))), .archetipoIgnoto("archetipo_che_non_esiste"))
        // Un arrivo di una categoria incoerente è respinto come un gruppo incoerente.
        XCTAssertThrowsError(try crea(conArrivo(.init(giorno: 3, nome: "lupo", composizione: reparti,
                                                      categoria: "ricognizione"))))
        // I nomi che restano non bastano ai gruppi senza nome: riservati tutti meno uno, due gruppi.
        let quasiTutti = Array(valoriCampagna.nomiGruppi.dropLast())
        XCTAssertEqual(rifiuto(ScenarioCampagna(
            mappa: "guado",
            gruppiGiocatore: [.init(riga: 4, colonna: 2, composizione: reparti)],
            gruppiAvversario: [.init(riga: 1, colonna: 2, composizione: reparti)],
            nomiRiservati: quasiTutti)), .nomiInsufficienti(richiesti: 2, disponibili: 1))
        // Un arrivo coerente nasce.
        XCTAssertNoThrow(try crea(conArrivo(.init(giorno: 3, nome: "lupo", composizione: reparti))))
    }

    // MARK: - B. Gli arrivi dalla patria

    func test_incarico_31_B_il_ponte_programma_gli_arrivi_alla_prima_giornata_della_stagione() throws {
        // Con trenta giornate per stagione: la 1, la 31 e la 61.
        let trenta = try scenario(fronteColQuartierGeneraleLibero, forzeDelSecondoAnno, trentaGiornate)
        XCTAssertEqual(trenta.gruppiGiocatore.map(\.nome), ["corvo", "lupo"], "partono subito le sole formazioni che ci sono")
        XCTAssertEqual(trenta.gruppiGiocatore.map(\.casella), [Cella(riga: 9, colonna: 5), Cella(riga: 9, colonna: 6)])
        XCTAssertEqual(trenta.arrivi.map(\.nome), ["cervo", "lince", "aquila"])
        XCTAssertEqual(trenta.arrivi.map(\.giorno), [1, 31, 61])
        XCTAssertEqual(trenta.arrivi.map(\.categoria), ["armato", "armato", "armato"])
        XCTAssertEqual(trenta.arrivi[1].composizione,
                       [.init(archetipo: "cavalleria_manovrata", atomi: 6, leva: 1)])
        XCTAssertEqual(trenta.nomiRiservati, ["orso", "volpe"],
                       "chi resta in patria e chi matura con l'inverno non parte, e il suo nome è riservato")
        XCTAssertEqual(trenta.calendario, trentaGiornate)
        // Con due giornate per stagione: la 1, la 3 e la 5.
        XCTAssertEqual(try scenario(fronteColQuartierGeneraleLibero, forzeDelSecondoAnno, dueGiornate).arrivi.map(\.giorno),
                       [1, 3, 5])
        // I reparti portano al fronte il miglioramento e l'anno di leva.
        XCTAssertEqual(trenta.gruppiGiocatore[1].composizione,
                       [.init(archetipo: "fanteria_leggera", atomi: 18),
                        .init(archetipo: "fanteria_pesante", atomi: 8, miglioramento: "addestramento_mirato")])
    }

    func test_incarico_31_B_le_reclute_pronte_in_primavera_entrano_con_la_prima_giornata_al_quartier_generale() throws {
        let stato = try crea(try scenario(fronteColQuartierGeneraleLibero, forzeDelSecondoAnno, dueGiornate))
        XCTAssertEqual(stato.giorno, 1)
        XCTAssertEqual(nomi(stato, di: .giocatore), ["corvo", "lupo", "cervo"])
        let cervo = try gruppo("cervo", stato)
        XCTAssertEqual(cervo.posizione, quartierGenerale, "il quartier generale è libero: le reclute entrano lì")
        XCTAssertEqual(cervo.composizione, [leggera(6, leva: 1)])
        XCTAssertEqual(cervo.categoria, .armato)
        XCTAssertEqual(cervo.parte, .giocatore)
        XCTAssertFalse(cervo.azioneSpesa, "chi arriva attende una decisione, come gli altri")
        XCTAssertNil(cervo.marcia)
        // Una voce nel registro della campagna, col giorno e la casella.
        XCTAssertEqual(stato.registro.map(\.fatto), [.arrivoDallaPatria(gruppo: "cervo", casella: quartierGenerale)])
        XCTAssertEqual(stato.registro.first?.giorno, 1)
        XCTAssertEqual(stato.registro.first?.numero, 0)
        XCTAssertEqual(stato.prossimoNumeroVoce, 1)
        XCTAssertEqual(stato.registro.first?.luogo, quartierGenerale)
        // Restano in attesa gli arrivi delle stagioni successive, nell'ordine in cui giungeranno.
        XCTAssertEqual(stato.arriviInAttesa?.map(\.nome), ["lince", "aquila"])
        XCTAssertEqual(stato.arriviInAttesa?.map(\.giorno), [3, 5])
        // L'avversario prende l'ultimo nome della lista, e chi resta in patria non c'è.
        XCTAssertEqual(nomi(stato, di: .avversario), ["muflone"])
        XCTAssertFalse(stato.gruppi.values.contains { $0.nome == "orso" || $0.nome == "volpe" })
        XCTAssertEqual(stato.nomiRiservati, ["corvo", "lupo", "orso", "cervo", "lince", "aquila", "volpe", "muflone"],
                       "ogni nome del regno e quello dell'avversario, nell'ordine della lista")
        // Il gruppo arrivato si comanda come gli altri.
        XCTAssertTrue(motore.valida(.presidio(gruppo: cervo.id), parte: .giocatore, stato: stato).eValido)
    }

    func test_incarico_31_B_col_quartier_generale_occupato_le_reclute_entrano_nella_casella_libera_piu_vicina() throws {
        // Sui fronti di fabbrica la prima formazione parte dal quartier generale.
        for nome in ["campagna_piccola", "campagna_media", "campagna_grande"] {
            let base = try scenarioDiFabbrica(nome)
            let forze = ForzeDelRegno.sciami(formazioni: [
                armata("corvo", [leggera(6)]), armata("lupo", [leggera(6)]),
                armata("cervo", [leggera(6, leva: 1)], arrivo: .primavera),
            ], prossimoNome: 5)
            let scenario = try scenario(base, forze, dueGiornate)
            // Lo stato senza le reclute: è su quello che si cerca la casella.
            let senza = try crea(ScenarioCampagna(
                mappa: scenario.mappa, gruppiGiocatore: scenario.gruppiGiocatore,
                gruppiAvversario: scenario.gruppiAvversario, forzeNemiche: scenario.forzeNemiche,
                struttureDiRifornimento: scenario.struttureDiRifornimento, calendario: scenario.calendario,
                nomiRiservati: ["cervo"]))
            let qg = senza.mappa.quartierGenerale(di: .giocatore)
            XCTAssertNotNil(senza.occupante(di: qg, parte: .giocatore), "\(nome): il quartier generale è occupato")
            let attesa = try XCTUnwrap(casellaAttesa(senza))
            XCTAssertEqual(MotoreCampagna.casellaDiArrivo(senza), attesa, nome)
            XCTAssertEqual(senza.griglia.distanza(qg, attesa), 1, "\(nome): una casella accanto al quartier generale")

            let stato = try crea(scenario)
            let cervo = try gruppo("cervo", stato)
            XCTAssertEqual(cervo.posizione, attesa, nome)
            XCTAssertEqual(stato.gruppi.values.filter { $0.posizione == attesa }.count, 1,
                           "\(nome): nella casella d'arrivo non c'è nessun altro")
            XCTAssertEqual(stato.registro.map(\.fatto), [.arrivoDallaPatria(gruppo: "cervo", casella: attesa)], nome)
        }
    }

    func test_incarico_31_B_gli_arrivi_d_estate_e_d_autunno_giungono_all_apertura_della_prima_giornata_della_stagione() throws {
        var stato = try crea(try scenario(fronteColQuartierGeneraleLibero, forzeDelSecondoAnno, trentaGiornate))
        XCTAssertEqual(stato.arriviInAttesa?.map(\.giorno), [31, 61])
        // Cervo, entrata con la prima giornata, lascia libero il quartier generale: si sposta accanto.
        let cervo = try gruppo("cervo", stato)
        stato.gruppi[cervo.id]!.posizione = Cella(riga: 10, colonna: 5)

        var eventiPerGiorno: [Int: [EventoCampagna]] = [:]
        while stato.conclusione == nil, stato.giorno <= 62 {
            let chiuso = stato.giorno
            eventiPerGiorno[chiuso + 1] = chiudiUnaGiornata(&stato)
            if stato.giorno == chiuso { return XCTFail("la giornata \(chiuso) non si è chiusa") }
        }
        // Per trenta giornate nessun arrivo; all'apertura della 31 arriva Lince, della 61 Aquila.
        for giorno in 2...62 where giorno != 31 && giorno != 61 {
            XCTAssertTrue(arrivi(eventiPerGiorno[giorno] ?? []).isEmpty, "nessun arrivo all'apertura della giornata \(giorno)")
        }
        let estate = try XCTUnwrap(eventiPerGiorno[31])
        XCTAssertEqual(arrivi(estate).map(\.nome), ["lince"])
        XCTAssertEqual(arrivi(estate).map(\.casella), [quartierGenerale])
        let autunno = try XCTUnwrap(eventiPerGiorno[61])
        XCTAssertEqual(arrivi(autunno).map(\.nome), ["aquila"])
        // L'ordine di ciò che il giocatore sente: la giornata, la stagione, e poi chi arriva.
        func posizione(_ eventi: [EventoCampagna], _ condizione: (EventoCampagna) -> Bool) -> Int? {
            eventi.firstIndex(where: condizione)
        }
        let aperta = try XCTUnwrap(posizione(estate) { $0 == .giornataAperta(giorno: 31) })
        let stagione = try XCTUnwrap(posizione(estate) { $0 == .stagioneCambiata(stagione: .estate) })
        let arrivo = try XCTUnwrap(posizione(estate) { if case .arrivoDallaPatria = $0 { return true } else { return false } })
        XCTAssertLessThan(aperta, stagione)
        XCTAssertLessThan(stagione, arrivo)
        // Il registro: il cambio di stagione e l'arrivo, col giorno in cui sono avvenuti.
        XCTAssertEqual(arriviNelRegistro(stato), ["1:cervo:10,6", "31:lince:10,6", "61:aquila:\(try gruppo("aquila", stato).posizione.riga),\(try gruppo("aquila", stato).posizione.colonna)"])
        let stagioni = stato.registro.compactMap { voce -> String? in
            if case .stagioneCambiata(let stagione) = voce.fatto { return "\(voce.giorno):\(stagione.rawValue)" } else { return nil }
        }
        XCTAssertEqual(stagioni, ["31:estate", "61:autunno"])
        // Tutti arrivati: nessuno attende più, e i tre sono gruppi del giocatore coi loro reparti.
        XCTAssertEqual(stato.arriviInAttesa, [])
        XCTAssertEqual(nomi(stato, di: .giocatore), ["corvo", "lupo", "cervo", "lince", "aquila"])
        XCTAssertEqual(try gruppo("lince", stato).composizione, [Reparto(archetipo: "cavalleria_manovrata", atomi: 6, leva: 1)])
        XCTAssertEqual(try gruppo("lince", stato).posizione, quartierGenerale)
        // Aquila ha trovato il quartier generale occupato da Lince, ed è entrata accanto.
        XCTAssertEqual(stato.griglia.distanza(quartierGenerale, try gruppo("aquila", stato).posizione), 1)
        XCTAssertEqual(Set(stato.gruppi.values.map(\.id)).count, stato.gruppi.count)
        // Gli eventi dell'arrivo raggiungono il giocatore: la proiezione non li toglie.
        XCTAssertEqual(arrivi(motore.proiettaPerIlGiocatore(estate, stato: stato)).map(\.nome), ["lince"])
    }

    func test_incarico_31_B_finche_attende_la_formazione_non_e_un_gruppo_e_all_arrivo_attende_una_decisione() throws {
        var stato = try crea(try scenario(fronteColQuartierGeneraleLibero, forzeDelSecondoAnno, dueGiornate))
        // Prima dell'estate Lince non è sulla mappa: non occupa caselle e non conta fra i gruppi.
        XCTAssertNil(stato.gruppiOrdinati.first { $0.nome == "lince" })
        XCTAssertEqual(stato.gruppi(di: .giocatore).count, 3)
        chiudiUnaGiornata(&stato)
        XCTAssertEqual(stato.giorno, 2)
        XCTAssertNil(stato.gruppiOrdinati.first { $0.nome == "lince" })
        let primaDellArrivo = stato
        let eventi = chiudiUnaGiornata(&stato)
        XCTAssertEqual(stato.giorno, 3, "la terza giornata è la prima dell'estate")
        XCTAssertEqual(arrivi(eventi).map(\.nome), ["lince"])
        let lince = try gruppo("lince", stato)
        XCTAssertEqual(lince.id.numero, primaDellArrivo.prossimoIdGruppo, "il gruppo nuovo prende il prossimo identificatore")
        XCTAssertEqual(stato.prossimoIdGruppo, primaDellArrivo.prossimoIdGruppo + 1)
        XCTAssertFalse(lince.azioneSpesa)
        XCTAssertEqual(stato.gruppiInAttesa(di: .giocatore).map(\.nome).sorted(), ["cervo", "corvo", "lince", "lupo"],
                       "la giornata nuova non si chiude da sé: chi è arrivato attende un ordine")
        XCTAssertEqual(lince.posizione, try XCTUnwrap(casellaAttesa(primaDellArrivoConLaGiornataAperta(primaDellArrivo, stato))))
        XCTAssertEqual(stato.arriviInAttesa?.map(\.nome), ["aquila"])
        // E si comanda: marcia verso una casella vicina.
        let meta = try XCTUnwrap(stato.griglia.vicini(di: lince.posizione).sorted().first {
            motore.valida(.marcia(gruppo: lince.id, a: $0,
                                  giorni: motore.costoInGiorni(da: lince.posizione, a: $0, stato: stato)),
                          parte: .giocatore, stato: stato).eValido
        })
        XCTAssertNotEqual(meta, lince.posizione)
    }

    /// Lo stato su cui l'arrivo ha cercato la casella: le posizioni di tutti i gruppi che c'erano,
    /// com'erano all'apertura della giornata nuova.
    private func primaDellArrivoConLaGiornataAperta(_ prima: StatoCampagna, _ dopo: StatoCampagna) -> StatoCampagna {
        var stato = dopo
        for id in dopo.gruppi.keys where prima.gruppi[id] == nil { stato.gruppi.removeValue(forKey: id) }
        return stato
    }

    func test_incarico_31_B_un_arrivo_senza_casella_libera_attende_la_giornata_successiva() throws {
        var stato = try crea(try scenario(fronteColQuartierGeneraleLibero, forzeDelSecondoAnno, dueGiornate))
        chiudiUnaGiornata(&stato)
        XCTAssertEqual(stato.giorno, 2)
        // Ogni casella senza formazioni è tenuta da forze nemiche ferme: non resta una casella libera.
        let occupate = Set(stato.gruppi.values.map(\.posizione))
        let libere = Set(stato.griglia.tutteLeCaselle.filter { !occupate.contains($0) })
        let forzeNemicheDiPrima = stato.forzeNemiche
        stato.forzeNemiche = libere
        XCTAssertNil(MotoreCampagna.casellaDiArrivo(stato))
        var eventi = chiudiUnaGiornata(&stato)
        XCTAssertEqual(stato.giorno, 3)
        XCTAssertTrue(arrivi(eventi).isEmpty, "senza una casella libera l'arrivo non entra")
        XCTAssertNil(stato.gruppiOrdinati.first { $0.nome == "lince" })
        XCTAssertEqual(stato.arriviInAttesa?.map(\.nome), ["lince", "aquila"], "e resta in attesa, non si perde")
        XCTAssertEqual(arriviNelRegistro(stato), ["1:cervo:10,6"])
        // Liberato il campo, arriva all'apertura della giornata successiva.
        stato.forzeNemiche = forzeNemicheDiPrima
        eventi = chiudiUnaGiornata(&stato)
        XCTAssertEqual(stato.giorno, 4)
        XCTAssertEqual(arrivi(eventi).map(\.nome), ["lince"])
        XCTAssertEqual(stato.arriviInAttesa?.map(\.nome), ["aquila"])
        XCTAssertEqual(arriviNelRegistro(stato).last?.hasPrefix("4:lince:"), true, "la voce porta il giorno in cui è arrivata davvero")
    }

    func test_incarico_31_B_la_casella_d_arrivo_evita_ogni_formazione_le_forze_nemiche_e_le_mete_di_marcia() throws {
        var stato = try crea(try scenario(fronteColQuartierGeneraleLibero,
                                          .sciami(formazioni: [armata("corvo", [leggera(6)]), armata("lupo", [leggera(6)])],
                                                  prossimoNome: 2), dueGiornate))
        XCTAssertEqual(MotoreCampagna.casellaDiArrivo(stato), quartierGenerale)
        // Un gruppo avversario sul quartier generale: chi arriva non entra in contatto.
        let avversario = try XCTUnwrap(stato.gruppiOrdinati.first { $0.parte == .avversario })
        var conAvversario = stato
        conAvversario.gruppi[avversario.id]!.posizione = quartierGenerale
        XCTAssertNotEqual(MotoreCampagna.casellaDiArrivo(conAvversario), quartierGenerale)
        XCTAssertEqual(MotoreCampagna.casellaDiArrivo(conAvversario), casellaAttesa(conAvversario))
        // Forze nemiche ferme sul quartier generale.
        var conNemici = stato
        conNemici.forzeNemiche.insert(quartierGenerale)
        XCTAssertNotEqual(MotoreCampagna.casellaDiArrivo(conNemici), quartierGenerale)
        XCTAssertEqual(MotoreCampagna.casellaDiArrivo(conNemici), casellaAttesa(conNemici))
        // Il quartier generale è la meta di una marcia propria: il posto è prenotato.
        let corvo = try gruppo("corvo", stato)
        let giorni = motore.costoInGiorni(da: corvo.posizione, a: quartierGenerale, stato: stato)
        let marcia = ComandoCampagna.marcia(gruppo: corvo.id, a: quartierGenerale, giorni: giorni)
        if giorni > 1, motore.valida(marcia, parte: .giocatore, stato: stato).eValido {
            (stato, _) = motore.applica(marcia, parte: .giocatore, stato: stato)
            XCTAssertEqual(stato.gruppi[corvo.id]?.marcia?.destinazione, quartierGenerale)
            XCTAssertNotEqual(MotoreCampagna.casellaDiArrivo(stato), quartierGenerale)
        } else {
            // La marcia di un giorno si compie alla chiusura: si prova la prenotazione sullo stato.
            var inMarcia = stato
            inMarcia.gruppi[corvo.id]!.marcia = MarciaInCorso(destinazione: quartierGenerale, giorniTotali: 2, giorniCompiuti: 0)
            XCTAssertNotEqual(MotoreCampagna.casellaDiArrivo(inMarcia), quartierGenerale)
            XCTAssertEqual(MotoreCampagna.casellaDiArrivo(inMarcia), casellaAttesa(inMarcia))
        }
    }

    // MARK: - B e C. Chi non parte, e chi non fa in tempo ad arrivare

    func test_incarico_31_C_la_formazione_tenuta_in_patria_non_compare_nello_scenario_e_il_suo_nome_e_riservato() throws {
        let forze = ForzeDelRegno.sciami(formazioni: [
            armata("corvo", [leggera(6)]), armata("lupo", [leggera(18), pesante(8)], inPatria: true),
            armata("falco", [leggera(6)]),
        ], prossimoNome: 3)
        let base = try scenarioDiFabbrica("campagna_piccola")
        let scenario = try scenario(base, forze, dueGiornate)
        XCTAssertEqual(scenario.gruppiGiocatore.map(\.nome), ["corvo", "falco"])
        XCTAssertEqual(scenario.gruppiGiocatore.map(\.casella), Array(base.gruppiGiocatore.map(\.casella).prefix(2)),
                       "chi parte occupa le prime caselle del fronte, senza lasciare il posto vuoto di chi resta")
        XCTAssertEqual(scenario.nomiRiservati, ["lupo"])
        XCTAssertTrue(scenario.arrivi.isEmpty)
        var stato = try crea(scenario)
        XCTAssertEqual(nomi(stato, di: .giocatore), ["corvo", "falco"])
        XCTAssertEqual(nomi(stato, di: .avversario), ["muflone", "ermellino", "sciacallo"])
        XCTAssertEqual(motore.prossimoNomeLibero(stato)?.nome, "orso", "Lupo è del regno anche se non è qui: chi nasce sul fronte non lo prende")
        // La campagna si conclude: Lupo non è fra chi rientra, e nel regno è rimasto com'era.
        try combatti(&stato, sopravviveIlGiocatore: true, sopravviveLAvversario: false)
        let esito = try XCTUnwrap(PonteRegnoCampagna.esito(da: stato, fronte: "guado"))
        XCTAssertEqual(esito.superstiti.formazioni.map(\.nome), ["corvo", "falco"])
        let dopo = forze.dopoLaCampagna(rientrano: esito.superstiti)
        XCTAssertEqual(dopo.formazioni.map(\.nome), ["corvo", "lupo", "falco"])
        XCTAssertEqual(dopo.formazioni[1], forze.formazioni[1])
        // Senza un'armata che parta subito il ponte non compone la campagna.
        let tutteACasa = ForzeDelRegno.sciami(formazioni: forze.formazioni.map {
            armata($0.nome, $0.composizione, inPatria: true)
        }, prossimoNome: 3)
        XCTAssertThrowsError(try self.scenario(base, tutteACasa, dueGiornate)) {
            XCTAssertEqual($0 as? PonteRegnoCampagna.Errore, .nessunaFormazioneArmata)
        }
        let soloInArrivo = ForzeDelRegno.sciami(formazioni: [armata("corvo", [leggera(6, leva: 1)], arrivo: .primavera)],
                                                prossimoNome: 1)
        XCTAssertThrowsError(try self.scenario(base, soloInArrivo, dueGiornate)) {
            XCTAssertEqual($0 as? PonteRegnoCampagna.Errore, .nessunaFormazioneArmata)
        }
    }

    func test_incarico_31_B_se_la_campagna_si_conclude_prima_gli_arrivi_mai_giunti_tornano_al_regno_ancora_in_arrivo() throws {
        let forze = forzeDelSecondoAnno
        var stato = try crea(try scenario(fronteColQuartierGeneraleLibero, forze, dueGiornate))
        chiudiUnaGiornata(&stato)
        XCTAssertEqual(stato.giorno, 2, "ancora primavera: Lince e Aquila non sono arrivate")
        // L'avversario è annientato: la campagna si conclude alla seconda giornata.
        try combatti(&stato, sopravviveIlGiocatore: true, sopravviveLAvversario: false)
        XCTAssertEqual(stato.conclusione, ConclusioneCampagna(modo: .annientamento, vincitore: .giocatore, giorno: 2))
        XCTAssertEqual(stato.arriviInAttesa?.map(\.nome), ["lince", "aquila"])

        let esito = try XCTUnwrap(PonteRegnoCampagna.esito(da: stato, fronte: "pianura_lunga"))
        XCTAssertEqual(esito.anno, 2)
        XCTAssertEqual(esito.superstiti.formazioni.map(\.nome), ["corvo", "lupo", "cervo", "lince", "aquila"])
        XCTAssertEqual(esito.superstiti.formazioni.map(\.arrivo), [nil, nil, nil, .estate, .autunno],
                       "chi è arrivato è un gruppo come gli altri; chi non ha fatto in tempo torna ancora in arrivo")
        XCTAssertEqual(esito.superstiti.numeroDiUnita, 3, "rientrano tre formazioni: le altre due non erano mai partite")
        XCTAssertEqual(esito.superstiti.formazioni[3].composizione, forze.formazioni[4].composizione)
        XCTAssertEqual(esito.superstiti.formazioni[1].composizione, [leggera(18), pesante(8, migliorata: true)],
                       "il reparto migliorato torna migliorato")

        // Nel regno: ciascuno al suo posto, chi non è partito identico, gli arrivi ancora in arrivo.
        let dopo = forze.dopoLaCampagna(rientrano: esito.superstiti)
        XCTAssertEqual(dopo.formazioni.map(\.nome), forze.formazioni.map(\.nome))
        XCTAssertEqual(dopo.formazioni.map(\.arrivo), [nil, nil, nil, nil, .estate, .autunno, .inverno])
        XCTAssertEqual(dopo.formazioni.map(\.inPatria), forze.formazioni.map(\.inPatria))
        XCTAssertEqual(dopo.formazioni.map(\.composizione), forze.formazioni.map(\.composizione))
        // All'inizio dell'inverno raggiungono le altre in patria.
        let inInverno = dopo.conGliArriviGiunti()
        XCTAssertTrue(inInverno.formazioni.allSatisfy { $0.arrivo == nil })
        XCTAssertEqual(inInverno.formazioni.map(\.nome), forze.formazioni.map(\.nome))
        XCTAssertEqual(inInverno.numeroDiUnita, 7)
    }

    func test_incarico_31_B_chi_attende_non_conta_fra_i_gruppi_armati_del_fronte() throws {
        // Una sola armata parte subito; le reclute arriveranno in estate.
        let forze = ForzeDelRegno.sciami(formazioni: [
            armata("corvo", [leggera(6)]), armata("lince", [leggera(6, leva: 1)], arrivo: .estate),
        ], prossimoNome: 6)
        var stato = try crea(try scenario(fronteColQuartierGeneraleLibero, forze, dueGiornate))
        XCTAssertEqual(stato.gruppiArmati(di: .giocatore), 1)
        // Corvo cade prima dell'estate: il giocatore non ha più gruppi armati, e la campagna è perduta.
        let eventi = try combatti(&stato, sopravviveIlGiocatore: false, sopravviveLAvversario: true)
        XCTAssertEqual(stato.conclusione?.vincitore, .avversario)
        XCTAssertEqual(eventi.last, .campagnaConclusa(modo: .annientamento, vincitore: .avversario))
        // Le reclute non erano partite: tornano al regno, ancora in arrivo.
        let esito = try XCTUnwrap(PonteRegnoCampagna.esito(da: stato, fronte: "pianura_lunga"))
        XCTAssertEqual(esito.superstiti.formazioni.map(\.nome), ["lince"])
        XCTAssertEqual(esito.superstiti.formazioni.map(\.arrivo), [.estate])
        XCTAssertEqual(esito.superstiti.numeroDiUnita, 0, "nessuna formazione rientra dal fronte")
        let dopo = forze.dopoLaCampagna(rientrano: esito.superstiti)
        XCTAssertEqual(dopo.formazioni.map(\.nome), ["lince"])
        XCTAssertEqual(dopo.formazioni.first?.composizione, [leggera(6, leva: 1)])
    }

    // MARK: - L'impronta (05 §2.9)

    func test_incarico_31_l_impronta_della_campagna_distingue_i_nomi_riservati_e_gli_arrivi_in_attesa() throws {
        let stato = try crea(try scenario(fronteColQuartierGeneraleLibero, forzeDelSecondoAnno, dueGiornate))
        let base = stato.impronta()
        XCTAssertEqual(try crea(try scenario(fronteColQuartierGeneraleLibero, forzeDelSecondoAnno, dueGiornate)).impronta(),
                       base, "stesso scenario, stesso stato (00 §3.1)")
        var altro = stato
        altro.nomiRiservati = (stato.nomiRiservati ?? []) + ["muflone"]
        XCTAssertNotEqual(altro.impronta(), base)
        altro = stato
        altro.nomiRiservati = nil
        XCTAssertNotEqual(altro.impronta(), base)
        altro = stato
        altro.arriviInAttesa = Array((stato.arriviInAttesa ?? []).dropLast())
        XCTAssertNotEqual(altro.impronta(), base)
        altro = stato
        altro.arriviInAttesa = (stato.arriviInAttesa ?? []).map {
            ArrivoInAttesa(giorno: $0.giorno + 1, nome: $0.nome, composizione: $0.composizione, categoria: $0.categoria)
        }
        XCTAssertNotEqual(altro.impronta(), base, "la giornata dell'arrivo")
        altro = stato
        altro.arriviInAttesa = (stato.arriviInAttesa ?? []).map {
            ArrivoInAttesa(giorno: $0.giorno, nome: $0.nome,
                           composizione: $0.composizione.map { $0.con(miglioramento: "addestramento_mirato") },
                           categoria: $0.categoria)
        }
        XCTAssertNotEqual(altro.impronta(), base, "il miglioramento di un reparto in arrivo")
        // Il miglioramento e l'anno di leva di un reparto sul fronte.
        let lupo = try gruppo("lupo", stato)
        altro = stato
        altro.gruppi[lupo.id]!.composizione[1] = pesante(8)
        XCTAssertNotEqual(altro.impronta(), base, "il miglioramento di un reparto")
        altro = stato
        altro.gruppi[lupo.id]!.composizione[0] = leggera(18, leva: 1)
        XCTAssertNotEqual(altro.impronta(), base, "l'anno di leva di un reparto")
    }
}
