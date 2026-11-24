import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// UNA BATTAGLIA E UNA CAMPAGNA SALVATE CON LA BUILD 31 SI RIAPRONO, SULLO STESSO STATO (00 §15;
/// incarico 31, regole A e H).
///
/// La seconda tappa del regno ha portato i valori alla 0.15.0, ha aggiunto ai reparti il
/// miglioramento e l'anno di leva, ai gruppi iniziali il nome, alla campagna i nomi riservati e gli
/// arrivi dalla patria. Tutto ciò che è nuovo è facoltativo e, quando manca, non si scrive: una
/// battaglia e una campagna di prova devono perciò restare quelle di prima — stessi nomi, stesso
/// giornale, stessa impronta — e i salvataggi della build 31, scritti con i valori 0.14.0, devono
/// riaprirsi sullo stato in cui il giocatore li aveva lasciati.
///
/// Le due fixture NON sono scritte dal codice di oggi: sono i giornali che il codice della build 31
/// (commit `41cccff`, valori 0.14.0) ha scritto giocando i due copioni di qui sotto, con l'impronta
/// dello stato finale che QUEL codice ha calcolato. Sono state prodotte esportando il pacchetto di
/// quel commit in una cartella di lavoro (`git archive 41cccff Codice`), copiandovi questo file ed
/// eseguendovi i due copioni. Il confronto è quindi fra due codici diversi, non di un codice con sé
/// stesso: è ciò che dà valore alla prova.
///
/// Per questo le fixture non si rigenerano col codice corrente: se una prova di qui fallisce, o le
/// regole di una partita in corso sono cambiate — e allora vanno dichiarate le versioni, come
/// vuole 00 §15.2 —, o qualcosa si è spostato senza volerlo.
final class SalvataggiBattagliaECampagnaBuild31Test: XCTestCase {

    static let cartellaCampagna = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("SalvataggioCampagnaBuild31")
    static let cartellaBattaglia = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("SalvataggioBattagliaBuild31")

    /// La versione dei valori con cui la build 31 ha scritto le due fixture.
    static let versioneDellaBuild31 = "0.14.0"

    // MARK: - I due copioni

    /// Il copione di CAMPAGNA: la campagna di prova piccola, senza nomi dichiarati. Il primo giorno
    /// Lupo stacca il proprio secondo reparto, che riceve il prossimo nome della lista, e la
    /// formazione di ricognizione esplora; il secondo giorno Corvo marcia lungo la strada; poi tre
    /// giornate chiuse col tasto. A ogni chiusura l'avversario svolge il proprio turno. La campagna
    /// resta in corso al quinto giorno. Usa soltanto ciò che esisteva già nella build 31.
    static func giocaCopioneDiCampagna(in cartella: URL, valori: ValoriDiGioco,
                                       valoriCampagna: ValoriCampagna) async throws -> SessioneCampagna {
        let dati = try Data(contentsOf: Contenuti.valoriDiFabbrica.appendingPathComponent("scenari-campagna.json"))
        let scenario = try XCTUnwrap(
            try JSONDecoder().decode([String: ScenarioCampagna].self, from: dati)["campagna_piccola"])
        let sessione = try SessioneCampagna(nuova: scenario, valori: valori, valoriCampagna: valoriCampagna,
                                            versioneTesti: "0.1.1", cartella: cartella, seme: 31,
                                            identificatore: "campagna-build-31")
        func ordina(_ comando: ComandoCampagna, riga: UInt = #line) async throws {
            let esito = try await sessione.esegui(comando, parte: .giocatore).esito
            XCTAssertTrue(esito.eValido, "il copione contiene un ordine respinto: \(comando), "
                          + "motivo \(String(describing: esito.motivo))", line: riga)
        }
        func gruppo(_ nome: String) async throws -> IdGruppo {
            let stato = await sessione.stato
            return try XCTUnwrap(stato.gruppiOrdinati.first { $0.nome == nome }, "manca il gruppo \(nome)").id
        }
        // Il primo giorno.
        try await ordina(.divisione(gruppo: try await gruppo("lupo"), repartiStaccati: [1],
                                    a: Cella(riga: 3, colonna: 3)))
        try await ordina(.esplorazione(gruppo: try await gruppo("falco")))
        try await sessione.chiudiGiornata()
        // Il secondo giorno.
        try await ordina(.marcia(gruppo: try await gruppo("corvo"), a: Cella(riga: 3, colonna: 2), giorni: 1))
        try await sessione.chiudiGiornata()
        // Il terzo e il quarto.
        try await sessione.chiudiGiornata()
        try await sessione.chiudiGiornata()
        return sessione
    }

    /// Il copione di BATTAGLIA: quello dell'oro con le riserve nel mazzo, che si chiude per resa
    /// (`RiproduzioneOroRiserveTest.giocaCopione`), giocato dall'avversario col tattico.
    static func giocaCopioneDiBattaglia(in cartella: URL, valori: ValoriDiGioco) async throws -> SessioneBattaglia {
        try await RiproduzioneOroRiserveTest.giocaCopione(in: cartella, valori: valori)
    }

    // MARK: - Attrezzi

    private func slot(_ nome: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(nome)-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    /// Copia il giornale di una fixture in uno slot di lavoro, come un salvataggio trovato sul disco.
    private func slotCol(_ fixture: URL, _ nome: String) throws -> URL {
        let url = try slot(nome)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: fixture.appendingPathComponent("giornale.jsonl"),
                                         to: url.appendingPathComponent("giornale.jsonl"))
        return url
    }

    private func impronta(di fixture: URL) throws -> String {
        try String(contentsOf: fixture.appendingPathComponent("impronta.txt"), encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func righe(_ url: URL) throws -> [String] {
        try String(contentsOf: url, encoding: .utf8).split(separator: "\n").map(String.init)
    }

    /// Il giornale scritto oggi coincide riga per riga, al byte, con quello della build 31; la sola
    /// differenza ammessa è la versione dei valori nell'atto di fondazione.
    private func confronta(giornaleDiOggi: URL, conQuelloDella fixture: URL, versioneDiOggi: String,
                           file: StaticString = #filePath, line: UInt = #line) throws {
        let oggi = try righe(giornaleDiOggi)
        let allora = try righe(fixture.appendingPathComponent("giornale.jsonl"))
        XCTAssertEqual(oggi.count, allora.count, "il copione giocato oggi scrive un numero diverso di righe",
                       file: file, line: line)
        guard let fondazioneDiOggi = oggi.first, let fondazioneDiAllora = allora.first else {
            return XCTFail("giornale vuoto", file: file, line: line)
        }
        let conLaVersione = "\"versione_valori\":\"\(versioneDiOggi)\""
        XCTAssertTrue(fondazioneDiOggi.contains(conLaVersione), "l'atto di fondazione dichiara la versione dei valori",
                      file: file, line: line)
        XCTAssertEqual(fondazioneDiOggi.replacingOccurrences(
                           of: conLaVersione, with: "\"versione_valori\":\"\(Self.versioneDellaBuild31)\""),
                       fondazioneDiAllora,
                       "l'atto di fondazione differisce da quello della build 31 per altro che la versione dei valori",
                       file: file, line: line)
        for (numero, coppia) in zip(oggi, allora).enumerated().dropFirst() {
            XCTAssertEqual(coppia.0, coppia.1, "la riga \(numero) del giornale non è quella della build 31",
                           file: file, line: line)
        }
    }

    // MARK: - La versione dei valori (regola H)

    func test_incarico_31_H_le_fixture_sono_scritte_con_i_valori_della_build_31_che_oggi_sono_compatibili() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        XCTAssertNotEqual(valori.versione, Self.versioneDellaBuild31, "i valori di oggi sono di una versione successiva")
        XCTAssertTrue(valori.versioniCompatibili.contains(Self.versioneDellaBuild31),
                      "la versione dei valori della build 31 deve stare fra le compatibili")
        for fixture in [Self.cartellaCampagna, Self.cartellaBattaglia] {
            let fondazione = try XCTUnwrap(try righe(fixture.appendingPathComponent("giornale.jsonl")).first)
            XCTAssertTrue(fondazione.contains("\"versione_valori\":\"\(Self.versioneDellaBuild31)\""),
                          "la fixture \(fixture.lastPathComponent) non è scritta con i valori \(Self.versioneDellaBuild31)")
        }
    }

    // MARK: - La campagna

    func test_incarico_31_H_una_campagna_salvata_con_la_build_31_si_riapre_sullo_stato_in_cui_era() async throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        let cartella = try slotCol(Self.cartellaCampagna, "campagna-31")
        let primaDiAprire = try Data(contentsOf: cartella.appendingPathComponent("giornale.jsonl"))
        let sessione: SessioneCampagna
        do { sessione = try SessioneCampagna(riprendi: cartella, valori: valori, valoriCampagna: valoriCampagna) }
        catch { return XCTFail("la campagna in corso di un tester verrebbe rifiutata: \(error)") }
        let fondazione = await sessione.fondazione
        XCTAssertEqual(fondazione.versioneValori, Self.versioneDellaBuild31)
        XCTAssertEqual(fondazione.versioneSchema, FondazioneCampagna.schemaCorrente,
                       "lo schema del giornale di campagna non è cambiato")
        let impronta = await sessione.impronta()
        XCTAssertEqual(impronta, try self.impronta(di: Self.cartellaCampagna),
                       "la campagna si riapre ma su uno stato diverso da quello che la build 31 aveva lasciato")
        XCTAssertEqual(try Data(contentsOf: cartella.appendingPathComponent("giornale.jsonl")), primaDiAprire,
                       "riaprire non riscrive il giornale")
        // Ciò che il giocatore ritrova: il quinto giorno, i nomi di allora, il distaccamento col suo.
        let stato = await sessione.stato
        XCTAssertEqual(stato.giorno, 5)
        XCTAssertNil(stato.conclusione)
        XCTAssertEqual(stato.gruppiOrdinati.map(\.nome),
                       ["corvo", "lupo", "falco", "orso", "cervo", "lince", "aquila", "volpe"])
        XCTAssertEqual(stato.gruppiOrdinati.first { $0.nome == "volpe" }?.composizione,
                       [Reparto(archetipo: "fanteria_pesante", atomi: 8)])
        XCTAssertEqual(stato.gruppiOrdinati.first { $0.nome == "corvo" }?.posizione, Cella(riga: 3, colonna: 2))
        // E la partita riaperta prosegue: la giornata si chiude, e comincia il sesto giorno.
        try await sessione.chiudiGiornata()
        let dopo = await sessione.stato.giorno
        XCTAssertEqual(dopo, 6)
    }

    /// Lo stesso copione, giocato col codice di oggi, dà lo stesso stato e lo stesso giornale che
    /// la build 31 ha scritto: nelle campagne di prova nulla è cambiato (regola A).
    func test_incarico_31_A_il_copione_di_campagna_giocato_oggi_da_lo_stato_e_il_giornale_della_build_31() async throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        let cartella = try slot("campagna-oggi")
        let sessione = try await Self.giocaCopioneDiCampagna(in: cartella, valori: valori,
                                                            valoriCampagna: valoriCampagna)
        let impronta = await sessione.impronta()
        XCTAssertEqual(impronta, try self.impronta(di: Self.cartellaCampagna),
                       "il copione di campagna giocato oggi non dà più lo stato che dava con la build 31")
        try confronta(giornaleDiOggi: cartella.appendingPathComponent("giornale.jsonl"),
                      conQuelloDella: Self.cartellaCampagna, versioneDiOggi: valori.versioneEffettiva)
        // Nulla di ciò che la seconda tappa ha aggiunto compare in una campagna di prova.
        let stato = await sessione.stato
        XCTAssertNil(stato.nomiRiservati)
        XCTAssertNil(stato.arriviInAttesa)
        XCTAssertNil(stato.calendario)
        XCTAssertTrue(stato.gruppi.values.allSatisfy { $0.composizione.allSatisfy { $0.miglioramento == nil && $0.leva == nil } })
        let testo = try String(contentsOf: cartella.appendingPathComponent("giornale.jsonl"), encoding: .utf8)
        for chiave in ["\"nome\"", "\"nomi_riservati\"", "\"arrivi\"", "\"miglioramento\"", "\"leva\""] {
            XCTAssertFalse(testo.contains(chiave), "il giornale di una campagna di prova contiene \(chiave)")
        }
    }

    /// Senza la 0.14.0 fra le versioni compatibili la stessa campagna sarebbe rifiutata, e
    /// dichiarata: il cancello delle versioni è quello che decide, e morde.
    func test_incarico_31_H_senza_la_0_14_0_fra_le_compatibili_la_campagna_della_build_31_e_dichiarata_incompatibile() async throws {
        let valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        let copia = try slot("valori-senza-la-0-14-0")
        try FileManager.default.copyItem(at: Contenuti.valoriDiFabbrica, to: copia)
        let manifest = copia.appendingPathComponent("manifest.json")
        var oggetto = try XCTUnwrap(JSONSerialization.jsonObject(with: try Data(contentsOf: manifest)) as? [String: Any])
        let compatibili = try XCTUnwrap(oggetto["versioni_compatibili"] as? [String])
        XCTAssertTrue(compatibili.contains(Self.versioneDellaBuild31))
        oggetto["versioni_compatibili"] = compatibili.filter { $0 != Self.versioneDellaBuild31 }
        try JSONSerialization.data(withJSONObject: oggetto).write(to: manifest)
        let senza = try CaricatoreValori.carica(da: copia)
        XCTAssertFalse(senza.versioniCompatibili.contains(Self.versioneDellaBuild31))

        let cartella = try slotCol(Self.cartellaCampagna, "campagna-31-rifiutata")
        do {
            _ = try SessioneCampagna(riprendi: cartella, valori: senza, valoriCampagna: valoriCampagna)
            XCTFail("senza la 0.14.0 fra le compatibili la campagna andava rifiutata")
        } catch let errore as SessioneCampagna.ErroreSessione {
            guard case .salvataggioIncompatibile(let attesa, let trovata) = errore else {
                return XCTFail("motivo di rifiuto sbagliato: \(errore)")
            }
            XCTAssertEqual(attesa, senza.versioneEffettiva)
            XCTAssertEqual(trovata, Self.versioneDellaBuild31)
        }
        let battaglia = try slotCol(Self.cartellaBattaglia, "battaglia-31-rifiutata")
        do {
            _ = try SessioneBattaglia(riprendi: battaglia, valori: senza)
            XCTFail("senza la 0.14.0 fra le compatibili la battaglia andava rifiutata")
        } catch let errore as SessioneBattaglia.ErroreSessione {
            guard case .salvataggioIncompatibile(_, let trovata) = errore else {
                return XCTFail("motivo di rifiuto sbagliato: \(errore)")
            }
            XCTAssertEqual(trovata, Self.versioneDellaBuild31)
        }
    }

    // MARK: - La battaglia

    func test_incarico_31_H_una_battaglia_salvata_con_la_build_31_si_riapre_sullo_stato_in_cui_era() async throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let cartella = try slotCol(Self.cartellaBattaglia, "battaglia-31")
        let primaDiAprire = try Data(contentsOf: cartella.appendingPathComponent("giornale.jsonl"))
        let sessione: SessioneBattaglia
        do { sessione = try SessioneBattaglia(riprendi: cartella, valori: valori) }
        catch { return XCTFail("lo scontro salvato con la build 31 verrebbe rifiutato: \(error)") }
        let fondazione = await sessione.fondazione
        XCTAssertEqual(fondazione.versioneValori, Self.versioneDellaBuild31)
        XCTAssertEqual(fondazione.versioneSchema, Fondazione.schemaCorrente,
                       "lo schema del giornale di battaglia non è cambiato")
        let impronta = await sessione.impronta()
        XCTAssertEqual(impronta, try self.impronta(di: Self.cartellaBattaglia),
                       "lo scontro si riapre ma su uno stato diverso da quello che la build 31 aveva lasciato")
        XCTAssertEqual(try Data(contentsOf: cartella.appendingPathComponent("giornale.jsonl")), primaDiAprire,
                       "riaprire non riscrive il giornale")
        let stato = await sessione.stato
        XCTAssertEqual(stato.esito?.modo, .ritirataCompiuta)
        XCTAssertTrue(stato.sciami.values.allSatisfy { $0.miglioramento == nil && $0.leva == nil })
    }

    /// Lo stesso copione di battaglia, giocato col codice di oggi, dà lo stesso stato e lo stesso
    /// giornale: per i reparti ordinari la formula del danno è quella di sempre.
    func test_incarico_31_F_il_copione_di_battaglia_giocato_oggi_da_lo_stato_e_il_giornale_della_build_31() async throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let cartella = try slot("battaglia-oggi")
        let sessione = try await Self.giocaCopioneDiBattaglia(in: cartella, valori: valori)
        let impronta = await sessione.impronta()
        XCTAssertEqual(impronta, try self.impronta(di: Self.cartellaBattaglia),
                       "il copione di battaglia giocato oggi non dà più lo stato che dava con la build 31")
        try confronta(giornaleDiOggi: cartella.appendingPathComponent("giornale.jsonl"),
                      conQuelloDella: Self.cartellaBattaglia, versioneDiOggi: valori.versioneEffettiva)
        let testo = try String(contentsOf: cartella.appendingPathComponent("giornale.jsonl"), encoding: .utf8)
        for chiave in ["\"miglioramento\"", "\"leva\""] {
            XCTAssertFalse(testo.contains(chiave), "il giornale di uno scontro di prova contiene \(chiave)")
        }
    }
}
