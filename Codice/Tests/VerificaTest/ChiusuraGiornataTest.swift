import XCTest
import Verifica
import Sessione
import Motore
import Dati
import Contenuti

/// Il tasto «Chiudi la giornata» attraverso la Sessione (incarico 28). Fino alla build 28
/// `SessioneCampagna.chiudiGiornata` chiamava `MotoreCampagna.chiudiLaGiornataForzata`, che segnava
/// spesa la giornata di TUTTI i gruppi che non l'avevano conclusa, compresi quelli dell'avversario,
/// senza che l'avversario avesse mosso: chi ordinava tre gruppi, ne lasciava fermo uno e premeva il
/// tasto toglieva il turno all'avversario, e ripetendolo ogni giorno l'avversario non muoveva mai.
/// Queste prove guardano il giornale — l'unico luogo dove i comandi avversari esistono — e lo
/// giudicano con l'invariante `azione_avversaria_sottratta` della sonda della campagna.
final class ChiusuraGiornataTest: XCTestCase {
    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    let sonda = SondaInvariantiCampagna()

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
    }

    private func slot() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("chiusura-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    static let leggera: [ScenarioCampagna.RepartoIniziale] = [.init(archetipo: "fanteria_leggera", atomi: 6)]

    /// Tre gruppi del giocatore in basso, due dell'avversario in alto, lontani: nessuna battaglia
    /// nelle prime giornate, sicché il turno avversario si vede intero.
    private func nuova(_ cartella: URL) throws -> SessioneCampagna {
        let scenario = ScenarioCampagna(mappa: "pianura_lunga",
            gruppiGiocatore: [.init(riga: 10, colonna: 4, composizione: Self.leggera),
                              .init(riga: 10, colonna: 5, composizione: Self.leggera),
                              .init(riga: 10, colonna: 6, composizione: Self.leggera)],
            gruppiAvversario: [.init(riga: 1, colonna: 5, composizione: Self.leggera),
                               .init(riga: 1, colonna: 6, composizione: Self.leggera)])
        return try SessioneCampagna(nuova: scenario, valori: valori, valoriCampagna: valoriCampagna,
                                    versioneTesti: "0.1.1", cartella: cartella,
                                    seme: 2828, identificatore: "prova-chiusura")
    }

    /// I gruppi cui si riferiscono i comandi AVVERSARI scritti nel giornale dalla riga `da` in poi.
    private func comandatiDallAvversario(_ cartella: URL, da riga: Int) throws -> Set<IdGruppo> {
        let giornale = try Giornale.apri(a: cartella.appendingPathComponent("giornale.jsonl"))
        var esito = Set<IdGruppo>()
        for r in giornale.righe.dropFirst(riga) {
            if case .comandoCampagna(.avversario, let comando) = r.voce { esito.insert(comando.gruppo) }
        }
        return esito
    }

    /// Ordina col presidio tutti i gruppi del giocatore in attesa TRANNE l'ultimo.
    private func ordinaTuttiTranneUno(_ sessione: SessioneCampagna) async throws {
        while true {
            let attesa = await sessione.stato.gruppiInAttesa(di: .giocatore)
            guard attesa.count > 1 else { break }
            _ = try await sessione.esegui(.presidio(gruppo: attesa[0].id), parte: .giocatore)
        }
    }

    /// Tre gruppi, due ordinati e uno lasciato fermo, poi il tasto: la giornata si chiude e i due
    /// gruppi dell'avversario, che attendevano, hanno AGITO con un proprio comando nel giornale.
    func test_incarico_28_il_tasto_lascia_muovere_l_avversario() async throws {
        let cartella = try slot()
        let sessione = try nuova(cartella)
        try await ordinaTuttiTranneUno(sessione)
        let prima = await sessione.stato
        XCTAssertEqual(prima.gruppiInAttesa(di: .giocatore).count, 1, "un gruppo del giocatore resta in attesa")
        let attesaAvversaria = prima.gruppiInAttesa(di: .avversario).map(\.id)
        XCTAssertEqual(attesaAvversaria.count, 2, "l'avversario non ha ancora mosso")
        let righePrima = await sessione.numeroRigheGiornale

        _ = try await sessione.chiudiGiornata()

        let dopo = await sessione.stato
        XCTAssertEqual(dopo.giorno, prima.giorno + 1, "il tasto ha chiuso la giornata")
        let comandati = try comandatiDallAvversario(cartella, da: righePrima)
        let violazioni = sonda.controllaAzioniAvversarie(
            attesaPrima: attesaAvversaria, giornoPrima: prima.giorno,
            dopo: dopo, comandatiDallAvversario: comandati).map(\.description)
        XCTAssertEqual(violazioni, [], "il tasto ha tolto il turno all'avversario")
        XCTAssertEqual(comandati, Set(attesaAvversaria), "ogni gruppo avversario ha agito col proprio comando")
    }

    /// Il caso del titolare ripetuto: per sei giornate il giocatore ordina tutti i gruppi tranne uno
    /// e preme il tasto. L'avversario deve muovere ogni giorno — le sue posizioni cambiano — e
    /// nessuna giornata gli toglie un'azione.
    func test_incarico_28_ripetuto_ogni_giorno_l_avversario_muove_comunque() async throws {
        let cartella = try slot()
        let sessione = try nuova(cartella)
        let posizioniIniziali = await sessione.stato.gruppi(di: .avversario).map(\.posizione)
        var violazioni: [String] = []
        for _ in 0..<6 {
            try await ordinaTuttiTranneUno(sessione)
            let prima = await sessione.stato
            guard prima.battaglieInSospeso.isEmpty else { break }
            let attesaAvversaria = prima.gruppiInAttesa(di: .avversario).map(\.id)
            let righePrima = await sessione.numeroRigheGiornale
            _ = try await sessione.chiudiGiornata()
            let dopo = await sessione.stato
            violazioni += sonda.controllaAzioniAvversarie(
                attesaPrima: attesaAvversaria, giornoPrima: prima.giorno, dopo: dopo,
                comandatiDallAvversario: try comandatiDallAvversario(cartella, da: righePrima)).map(\.description)
        }
        XCTAssertEqual(violazioni, [], "giornate in cui il tasto ha tolto il turno all'avversario")
        let posizioniFinali = await sessione.stato.gruppi(di: .avversario).map(\.posizione)
        XCTAssertNotEqual(posizioniIniziali, posizioniFinali,
                          "in sei giornate chiuse col tasto l'avversario non si è mai mosso")
    }

    // MARK: - Dopo la correzione: diagnostica, eventi, annullamento, ripresa, battaglia in sospeso

    /// La diagnostica conserva le due parti, DISTINTE: i gruppi del giocatore che il tasto ha fatto
    /// restare (col presidio), e quelli dell'avversario che attendevano e hanno poi mosso da sé. Gli
    /// eventi consegnati al giocatore portano l'apertura della giornata nuova, non i presidi dati dal
    /// tasto (li riassume l'annuncio).
    func test_incarico_28_la_diagnostica_distingue_le_due_parti() async throws {
        let cartella = try slot()
        let sessione = try nuova(cartella)
        try await ordinaTuttiTranneUno(sessione)
        let prima = await sessione.stato
        let fermo = try XCTUnwrap(prima.gruppiInAttesa(di: .giocatore).first)
        let esito = try await sessione.chiudiGiornata()
        let d = esito.diagnostica
        XCTAssertEqual(d.giorno, prima.giorno)
        XCTAssertEqual(d.giocatore.map(\.numero), [fermo.id.numero], "il solo gruppo del giocatore lasciato fermo")
        XCTAssertEqual(d.giocatore.first?.ordineDato, "presidio", "il tasto gli ha dato l'ordine di restare")
        XCTAssertEqual(d.avversario.map(\.numero).sorted(),
                       prima.gruppiInAttesa(di: .avversario).map(\.id.numero).sorted(),
                       "i gruppi dell'avversario che non avevano ancora agito, a parte")
        XCTAssertTrue(d.avversario.allSatisfy { $0.ordineDato == nil && $0.propostaRespinta == nil },
                      "l'avversario ha agito da sé, nessuno sblocco")
        XCTAssertTrue(d.laGiornataNonSiSarebbeChiusa)
        XCTAssertTrue(esito.eventi.contains { if case .giornataAperta = $0 { return true } else { return false } },
                      "il giocatore riceve l'apertura della giornata nuova")
        XCTAssertFalse(esito.eventi.contains { if case .presidioOrdinato(let g, _, _) = $0 { return g == fermo.id } else { return false } },
                       "il presidio dato dal tasto non si annuncia a sé")
    }

    /// Con l'avversario che ha mosso dopo il tasto, la chiusura è sigillata: l'annullamento è
    /// rifiutato col suo motivo (05 §6.5). Senza avversario in attesa, il tasto è l'ultimo gesto e
    /// l'annullamento lo ritira intero, riaprendo la giornata coi gruppi in attesa di prima.
    func test_incarico_28_l_annullamento_dopo_il_tasto() async throws {
        let sessione = try nuova(try slot())
        try await ordinaTuttiTranneUno(sessione)
        _ = try await sessione.chiudiGiornata()
        do {
            _ = try await sessione.annulla(parte: .giocatore)
            XCTFail("annullare dopo il turno dell'avversario equivarrebbe alla prova a rovescio")
        } catch SessioneCampagna.ErroreSessione.oltreLaGiornataInCorso { }

        let soloGiocatore = ScenarioCampagna(mappa: "pianura_lunga",
            gruppiGiocatore: [.init(riga: 10, colonna: 4, composizione: Self.leggera),
                              .init(riga: 10, colonna: 5, composizione: Self.leggera)])
        let senza = try SessioneCampagna(nuova: soloGiocatore, valori: valori, valoriCampagna: valoriCampagna,
                                         versioneTesti: "0.1.1", cartella: try slot(),
                                         seme: 1, identificatore: "prova-chiusura-senza-avversario")
        _ = try await senza.esegui(.presidio(gruppo: await senza.stato.gruppiInAttesa(di: .giocatore)[0].id),
                                   parte: .giocatore)
        let primaDelTasto = await senza.stato
        _ = try await senza.chiudiGiornata()
        let dopoIlTasto = await senza.stato
        XCTAssertEqual(dopoIlTasto.giorno, 2)
        let annullamento = try await senza.annulla(parte: .giocatore)
        XCTAssertTrue(annullamento.giornataRiaperta, "l'annullamento del tasto riapre la giornata")
        let riaperta = await senza.stato
        XCTAssertEqual(riaperta.giorno, 1)
        XCTAssertEqual(riaperta.gruppiInAttesa(di: .giocatore).count, 1,
                       "torna in attesa il gruppo che il tasto aveva fatto restare, non quello ordinato prima")
        // L'impronta no: l'annullamento è un fatto e il registro lo annota (01 §5.17). I gruppi sì.
        XCTAssertEqual(riaperta.gruppi, primaDelTasto.gruppi, "i gruppi sono quelli di prima del tasto")
    }

    /// Chiusa la giornata col tasto, la campagna riaperta dal giornale ritrova lo stesso stato: il
    /// tasto rigiocato dà gli stessi ordini di restare e il turno avversario sta nel giornale.
    func test_incarico_28_la_ripresa_riproduce_la_chiusura() async throws {
        let cartella = try slot()
        let sessione = try nuova(cartella)
        for _ in 0..<3 {
            try await ordinaTuttiTranneUno(sessione)
            _ = try await sessione.chiudiGiornata()
        }
        let impronta = await sessione.impronta()
        let ripresa = try SessioneCampagna(riprendi: cartella, valori: valori, valoriCampagna: valoriCampagna)
        let improntaRipresa = await ripresa.impronta()
        XCTAssertEqual(improntaRipresa, impronta, "la ripresa non riproduce le giornate chiuse col tasto")
    }

    // MARK: - Il banco che preme il tasto

    /// Il banco di campagna gioca gli scenari con l'avversario premendo il tasto a giorni alterni,
    /// con un gruppo lasciato fermo: nessuna violazione — in particolare nessuna
    /// `azione_avversaria_sottratta`, che il banco controlla dopo OGNI gesto del giocatore — e il
    /// tasto premuto davvero. Stampa le misure per il resoconto.
    func test_incarico_28_il_banco_preme_il_tasto_senza_violazioni() throws {
        let motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
        let scenari = try ScenariCampagna.carica(da: Verifica.Ambiente.scenariCampagnaDiFabbrica)
        let banco = BancoCampagna(motore: motore, valoriCampagna: valoriCampagna, scenari: scenari)
        var chiusure = 0, corse = 0
        for voce in scenari.scenari where !voce.gruppiAvversario.isEmpty {
            let corsa = try banco.corri(voce, giornate: scenari.giornateGenerate, chiudeLaGiornataOgni: 2)
            print("TASTO-28 \(voce.identificatore): chiusure=\(corsa.chiusureDelGiocatore) giornate=\(corsa.giornate)"
                  + " battaglie=\(corsa.battaglieGiocate) violazioni=\(corsa.violazioni.count) \(corsa.violazioni.joined(separator: ";"))")
            XCTAssertEqual(corsa.violazioni, [], "\(voce.identificatore)")
            chiusure += corsa.chiusureDelGiocatore; corse += 1
        }
        print("TASTO-28 TOTALE corse=\(corse) chiusure=\(chiusure)")
        XCTAssertGreaterThan(chiusure, 0, "il banco non ha mai premuto il tasto")
    }
}
