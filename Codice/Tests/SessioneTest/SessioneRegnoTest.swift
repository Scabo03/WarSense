import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// La Sessione del regno (05 §6; incarico 30, RDA-162): il giornale è la verità e si scrive prima
/// che l'esito diventi visibile; la ripresa restituisce il punto di interruzione; l'annullamento
/// delle spese non retrocede oltre l'apertura della stazione; la campagna dell'anno vive in uno slot
/// annidato e porta in patria il solo esito.
final class SessioneRegnoTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
    }

    /// Valori di prova con stagioni di due giornate, perché un anno intero si giochi in sei giornate.
    static func valoriDiProva() -> ValoriRegno {
        ValoriRegno(
            giornatePerStagione: 2,
            quotaRiporto: Scalato(millesimi: 100),
            dotazioneIniziale: ["denaro": 10, "uomini": 1, "metalli": 2, "materiale": 3, "animali": 0],
            renditaAnnua: ["denaro": 200, "uomini": 24, "metalli": 30, "materiale": 30, "animali": 12],
            premioBattagliaVinta: Scalato(millesimi: 100),
            premioCampagnaVinta: Scalato(millesimi: 500),
            baseLeva: ["denaro": 5, "uomini": 1, "metalli": 1, "materiale": 0, "animali": 1],
            costoMinimo: 1,
            voci: [
                VoceDelRegno(identificatore: "leva_fanteria_leggera",
                             pesi: ["denaro": Scalato(intero: 1), "uomini": Scalato(intero: 1),
                                    "metalli": Scalato(millesimi: 500)],
                             effetto: .reclutaReparto(archetipo: "fanteria_leggera", atomi: 6)),
                VoceDelRegno(identificatore: "leva_fanteria_pesante",
                             pesi: ["denaro": Scalato(millesimi: 1600), "uomini": Scalato(intero: 1),
                                    "metalli": Scalato(intero: 2)],
                             effetto: .reclutaReparto(archetipo: "fanteria_pesante", atomi: 8)),
            ],
            fronti: [FronteDelRegno(identificatore: "pianura_lunga", scenario: "campagna_grande")],
            faseIniziale: .arcaica,
            forzeIniziali: [
                FormazioneIniziale(categoria: "armato", composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)]),
                FormazioneIniziale(categoria: "armato", composizione: [.init(archetipo: "fanteria_pesante", atomi: 8)]),
                FormazioneIniziale(categoria: "ricognizione",
                                   composizione: [.init(archetipo: "fanteria_leggera", atomi: 3)], competenza: 5),
            ])
    }

    /// Lo scenario del fronte: la mappa grande, con l'avversario lontano, perché in sei giornate i
    /// due eserciti non si tocchino e la campagna finisca per l'arrivo dell'inverno.
    static let fronteLontano = ScenarioCampagna(
        mappa: "pianura_lunga",
        gruppiGiocatore: [.init(riga: 10, colonna: 5, composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)]),
                          .init(riga: 10, colonna: 6, composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)])],
        gruppiAvversario: [.init(riga: 1, colonna: 5, composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)])])

    private func slot() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("regno-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func nuovo(_ cartella: URL, valoriRegno: ValoriRegno = SessioneRegnoTest.valoriDiProva()) throws -> SessioneRegno {
        try SessioneRegno(nuovo: valoriRegno, versioneValori: valori.versioneEffettiva, versioneTesti: "0.1.1",
                          cartella: cartella, seme: 4242, identificatore: "prova-regno")
    }

    private func riprendi(_ cartella: URL, valoriRegno: ValoriRegno = SessioneRegnoTest.valoriDiProva()) throws -> SessioneRegno {
        try SessioneRegno(riprendi: cartella, valori: valoriRegno, versioneValori: valori.versioneEffettiva,
                          versioniCompatibili: valori.versioniCompatibili)
    }

    private func apri(_ regno: SessioneRegno, in cartella: URL) async throws -> SessioneCampagna {
        let aperta = try await regno.apriCampagna(
            fronte: "pianura_lunga", scenarioDelFronte: Self.fronteLontano, valori: valori,
            valoriCampagna: valoriCampagna, versioneTesti: "0.1.1", cartellaDelRegno: cartella,
            seme: 99, identificatore: "campagna-di-prova")
        XCTAssertTrue(aperta.esito.eValido)
        return try XCTUnwrap(aperta.campagna)
    }

    // MARK: - Il giornale (05 §6.1)

    func test_05_6_1_il_regno_nasce_con_l_atto_di_fondazione_e_ogni_comando_e_una_riga() async throws {
        let cartella = try slot()
        let regno = try nuovo(cartella)
        let righe = await regno.numeroRigheGiornale
        XCTAssertEqual(righe, 1, "la prima riga è l'atto di fondazione")
        let fondazione = await regno.fondazione
        XCTAssertEqual(fondazione?.modalita, FondazioneRegno.modalitaASciami)
        XCTAssertEqual(fondazione?.versioneSchema, FondazioneRegno.schemaCorrente)

        // Un comando non valido non viene applicato né registrato.
        let respinto = try await regno.esegui(.prosegui)
        XCTAssertEqual(respinto.esito.motivo, .nonEInverno)
        let dopoRespinto = await regno.numeroRigheGiornale
        XCTAssertEqual(dopoRespinto, 1)

        let accolto = try await regno.esegui(.attendiInverno)
        XCTAssertTrue(accolto.esito.eValido)
        let dopoAccolto = await regno.numeroRigheGiornale
        XCTAssertEqual(dopoAccolto, 2)
        // La riga è già su disco, senza chiudere la sessione.
        let contenuto = try String(contentsOf: cartella.appendingPathComponent(SessioneRegno.nomeGiornale), encoding: .utf8)
        XCTAssertTrue(contenuto.contains("attendiInverno"), "la scrittura è confermata, non differita")
    }

    // MARK: - La campagna dell'anno (RDA-162, RDA-166)

    func test_la_campagna_dell_anno_nasce_nello_slot_annidato_con_le_forze_del_regno_e_il_calendario() async throws {
        let cartella = try slot()
        let regno = try nuovo(cartella)
        let campagna = try await apri(regno, in: cartella)
        let stato = await campagna.stato
        XCTAssertEqual(stato.calendario, CalendarioDiCampagna(anno: 1, giornatePerStagione: 2))
        XCTAssertEqual(stato.gruppi(di: .giocatore).count, 3, "partono tutte le formazioni del regno")
        XCTAssertEqual(stato.gruppi(di: .avversario).count, 1, "le forze avversarie sono quelle del fronte")
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: cartella.appendingPathComponent(SessioneRegno.cartellaCampagna)
                .appendingPathComponent("giornale.jsonl").path))
        let statoRegno = await regno.stato
        XCTAssertEqual(statoRegno.campagna, .aperta(fronte: "pianura_lunga"))

        // Una seconda apertura è respinta, e non tocca lo slot della campagna in corso.
        let seconda = try await regno.apriCampagna(
            fronte: "pianura_lunga", scenarioDelFronte: Self.fronteLontano, valori: valori,
            valoriCampagna: valoriCampagna, versioneTesti: "0.1.1", cartellaDelRegno: cartella,
            seme: 1, identificatore: "seconda")
        XCTAssertNil(seconda.campagna)
        XCTAssertEqual(seconda.esito.motivo, .campagnaAperta)
        let ripresa = try SessioneCampagna(riprendi: cartella.appendingPathComponent(SessioneRegno.cartellaCampagna),
                                           valori: valori, valoriCampagna: valoriCampagna)
        let identificatore = await ripresa.fondazione.identificatore
        XCTAssertEqual(identificatore, "campagna-di-prova")
    }

    func test_un_anno_intero_fino_alla_seconda_primavera_e_la_ripresa_dal_giornale() async throws {
        let cartella = try slot()
        let regno = try nuovo(cartella)
        let campagna = try await apri(regno, in: cartella)

        // La campagna: sei giornate chiuse, poi l'inverno la conclude.
        var chiusure = 0
        while await campagna.stato.conclusione == nil, chiusure < 20 {
            try await campagna.chiudiGiornata()
            chiusure += 1
        }
        XCTAssertEqual(chiusure, 6, "tre stagioni di due giornate")
        let statoCampagna = await campagna.stato
        XCTAssertEqual(statoCampagna.conclusione, ConclusioneCampagna(modo: .inverno, vincitore: nil, giorno: 6))

        // Conclusa, la campagna non si chiude oltre e non torna indietro.
        do { try await campagna.chiudiGiornata(); XCTFail("la campagna conclusa non avanza") }
        catch SessioneCampagna.ErroreSessione.campagnaConclusa {}
        do { try await campagna.annulla(parte: .giocatore); XCTFail("non si annulla oltre la conclusione") }
        catch SessioneCampagna.ErroreSessione.campagnaConclusa {}
        do { try await campagna.azzera(parte: .giocatore); XCTFail("non si azzera oltre la conclusione") }
        catch SessioneCampagna.ErroreSessione.campagnaConclusa {}

        // L'esito arriva in patria, una volta sola.
        let eventi = try await regno.riceviEsito(dalla: statoCampagna)
        XCTAssertEqual(eventi?.count, 1)
        let secondaVolta = try await regno.riceviEsito(dalla: statoCampagna)
        XCTAssertNil(secondaVolta, "non si conclude ciò che non è più aperto")
        var stato = await regno.stato
        XCTAssertEqual(stato.campagna.esito?.modo, .inverno)
        XCTAssertEqual(stato.forze.numeroDiUnita, 3, "nessuna battaglia: rientrano tutti")

        // L'inverno e le spese.
        _ = try await regno.esegui(.attendiInverno)
        _ = try await regno.esegui(.ordina(voce: "leva_fanteria_leggera"))
        _ = try await regno.esegui(.ordina(voce: "leva_fanteria_pesante"))
        stato = await regno.stato
        XCTAssertEqual(stato.lavori.count, 2)
        let denaroDopoDue = stato.riserve[.denaro]

        // L'annullamento ritira l'ultima spesa e restituisce le risorse.
        let ritirata = try await regno.annullaSpesa()
        XCTAssertEqual(ritirata.voce, "leva_fanteria_pesante")
        stato = await regno.stato
        XCTAssertEqual(stato.lavori.map(\.voce), ["leva_fanteria_leggera"])
        XCTAssertEqual(stato.riserve[.denaro], denaroDopoDue + ritirata.costo[.denaro])

        // L'azzeramento ritira tutte le spese della stazione.
        _ = try await regno.esegui(.ordina(voce: "leva_fanteria_leggera"))
        let quante = try await regno.azzeraSpese()
        XCTAssertEqual(quante, 2)
        stato = await regno.stato
        XCTAssertTrue(stato.lavori.isEmpty)
        XCTAssertEqual(stato.riserve[.denaro], 210)
        do { _ = try await regno.annullaSpesa(); XCTFail("non c'è nulla da annullare") }
        catch SessioneRegno.ErroreSessione.nienteDaRitirare {}
        do { _ = try await regno.azzeraSpese(); XCTFail("non c'è nulla da azzerare") }
        catch SessioneRegno.ErroreSessione.nienteDaRitirare {}

        // L'apertura di una stazione è un punto di conferma: oltre non si torna (05 §6.5).
        _ = try await regno.esegui(.ordina(voce: "leva_fanteria_pesante"))
        _ = try await regno.esegui(.prosegui)
        do { _ = try await regno.annullaSpesa(); XCTFail("la spesa della stazione precedente è confermata") }
        catch SessioneRegno.ErroreSessione.nienteDaRitirare {}
        _ = try await regno.esegui(.ordina(voce: "leva_fanteria_leggera"))
        for _ in 2...MomentoDellAnno.stazioniInvernali { _ = try await regno.esegui(.prosegui) }

        stato = await regno.stato
        XCTAssertEqual(stato.anno, 2)
        XCTAssertEqual(stato.momento, .operativo)
        XCTAssertEqual(stato.forze.numeroDiUnita, 4, "le reclute sono una formazione nuova")
        XCTAssertEqual(stato.forze.formazioni.last?.composizione,
                       [Reparto(archetipo: "fanteria_pesante", atomi: 8), Reparto(archetipo: "fanteria_leggera", atomi: 6)])

        // La ripresa dal giornale restituisce lo stesso stato.
        let impronta = await regno.impronta()
        let ripreso = try riprendi(cartella)
        let improntaRipresa = await ripreso.impronta()
        XCTAssertEqual(improntaRipresa, impronta, "stato di fondazione più righe del giornale: è l'intera partita")
        let statoRipreso = await ripreso.stato
        XCTAssertEqual(statoRipreso, stato)

        // La campagna del secondo anno porta al fronte anche le reclute.
        let seconda = try await apri(ripreso, in: cartella)
        let statoSeconda = await seconda.stato
        XCTAssertEqual(statoSeconda.calendario?.anno, 2)
        XCTAssertEqual(statoSeconda.gruppi(di: .giocatore).count, 4)
        print("REGNO-SESSIONE righe_giornale=\(await ripreso.numeroRigheGiornale) anno=\(statoRipreso.anno) formazioni=\(statoRipreso.forze.numeroDiUnita)")
    }

    func test_l_esito_di_una_campagna_non_aperta_e_rifiutato_e_non_si_scrive() async throws {
        let cartella = try slot()
        let regno = try nuovo(cartella)
        let stato = await regno.stato
        let esito = EsitoCampagna(fronte: "pianura_lunga", anno: 1, modo: .inverno, vincitore: nil, giornate: 6,
                                  battaglieVinte: 0, battagliePerse: 0, superstiti: stato.forze)
        do { try await regno.concludiCampagna(esito); XCTFail("nessuna campagna è aperta") }
        catch SessioneRegno.ErroreSessione.esitoNonAtteso {}
        let righe = await regno.numeroRigheGiornale
        XCTAssertEqual(righe, 1)
    }

    func test_la_campagna_aperta_il_cui_slot_e_perduto_si_ricrea_identica() async throws {
        let cartella = try slot()
        let regno = try nuovo(cartella)
        let prima = try await apri(regno, in: cartella)
        let scenarioPrima = await prima.fondazione.scenario
        try FileManager.default.removeItem(at: cartella.appendingPathComponent(SessioneRegno.cartellaCampagna))
        let ricreata = try await regno.ricreaCampagnaAperta(
            scenarioDelFronte: Self.fronteLontano, valori: valori, valoriCampagna: valoriCampagna,
            versioneTesti: "0.1.1", cartellaDelRegno: cartella, seme: 5, identificatore: "ricreata")
        let scenarioDopo = await ricreata?.fondazione.scenario
        XCTAssertEqual(scenarioDopo, scenarioPrima, "le forze del regno non sono cambiate dall'apertura")
        let righe = await regno.numeroRigheGiornale
        XCTAssertEqual(righe, 2, "ricreare lo slot non aggiunge righe al giornale del regno")
    }

    // MARK: - Versioni e integrità (00 §15, 05 §6.6, §6.8)

    func test_00_15_2_un_regno_di_valori_incompatibili_si_dichiara_e_non_si_apre() async throws {
        let cartella = try slot()
        _ = try SessioneRegno(nuovo: Self.valoriDiProva(), versioneValori: "0.1.0", versioneTesti: "0.1.1",
                              cartella: cartella, seme: 1, identificatore: "vecchio")
        XCTAssertThrowsError(try SessioneRegno(riprendi: cartella, valori: Self.valoriDiProva(),
                                               versioneValori: "9.9.9", versioniCompatibili: ["9.9.8"])) {
            XCTAssertEqual($0 as? SessioneRegno.ErroreSessione,
                           .salvataggioIncompatibile(attesa: "9.9.9", trovata: "0.1.0"))
        }
        // La stessa versione, o una dichiarata compatibile, si apre.
        XCTAssertNoThrow(try SessioneRegno(riprendi: cartella, valori: Self.valoriDiProva(),
                                           versioneValori: "0.1.0", versioniCompatibili: []))
        XCTAssertNoThrow(try SessioneRegno(riprendi: cartella, valori: Self.valoriDiProva(),
                                           versioneValori: "9.9.9", versioniCompatibili: ["0.1.0"]))
    }

    func test_00_15_2_un_regno_di_schema_diverso_si_dichiara_e_non_si_apre() async throws {
        let cartella = try slot()
        _ = try nuovo(cartella)
        let url = cartella.appendingPathComponent(SessioneRegno.nomeGiornale)
        let testo = try String(contentsOf: url, encoding: .utf8)
        try testo.replacingOccurrences(of: "\"versione_schema\":\(FondazioneRegno.schemaCorrente)",
                                       with: "\"versione_schema\":\(FondazioneRegno.schemaCorrente + 7)")
            .write(to: url, atomically: true, encoding: .utf8)
        XCTAssertThrowsError(try riprendi(cartella)) {
            XCTAssertEqual($0 as? SessioneRegno.ErroreSessione,
                           .schemaIncompatibile(atteso: FondazioneRegno.schemaCorrente,
                                                trovato: FondazioneRegno.schemaCorrente + 7))
        }
    }

    func test_05_6_8_un_giornale_con_un_comando_che_il_motore_respinge_e_dichiarato_corrotto() async throws {
        let cartella = try slot()
        let regno = try nuovo(cartella)
        _ = try await regno.esegui(.attendiInverno)
        // Una riga estranea: «attendi l'inverno» in pieno inverno.
        let url = cartella.appendingPathComponent(SessioneRegno.nomeGiornale)
        var testo = try String(contentsOf: url, encoding: .utf8)
        testo += "{\"numero\":2,\"voce\":{\"comandoRegno\":{\"comando\":{\"attendiInverno\":{}}}}}\n"
        try testo.write(to: url, atomically: true, encoding: .utf8)
        XCTAssertThrowsError(try riprendi(cartella)) {
            XCTAssertEqual($0 as? SessioneRegno.ErroreSessione, .giornaleCorrotto(riga: 2))
        }
    }

    // MARK: - La riproduzione d'oro del regno (05 §14.6: «un inverno»)

    static let cartellaFixture = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("RiproduzioneOroRegno")

    /// Il copione: due anni con i valori di FABBRICA. Il primo con una campagna vinta sul fronte
    /// dell'istmo — l'esito è scritto qui, perché il giornale del regno porta l'esito e non la
    /// campagna —, tre leve su due stazioni, la primavera; il secondo senza campagna, una leva.
    static func giocaCopione(in cartella: URL, valori: ValoriDiGioco) async throws -> SessioneRegno {
        let valoriRegno = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica,
                                                     archetipiNoti: Set(valori.archetipi.keys))
        let regno = try SessioneRegno(nuovo: valoriRegno, versioneValori: valori.versioneEffettiva,
                                      versioneTesti: "0.1.1", cartella: cartella, seme: 7,
                                      identificatore: "oro-regno")
        _ = try await regno.esegui(.apriCampagna(fronte: "istmo"))
        let forze = await regno.stato.forze
        // Rientrano tutti tranne la terza armata, caduta; la prima torna dimezzata.
        var superstiti = forze.formazioni
        superstiti.remove(at: 2)
        superstiti[0].composizione = [Reparto(archetipo: "fanteria_leggera", atomi: 3)]
        try await regno.concludiCampagna(EsitoCampagna(
            fronte: "istmo", anno: 1, modo: .annientamento, vincitore: .giocatore, giornate: 47,
            battaglieVinte: 2, battagliePerse: 1, superstiti: .sciami(superstiti)))
        _ = try await regno.esegui(.attendiInverno)
        _ = try await regno.esegui(.ordina(voce: "leva_fanteria_pesante"))
        _ = try await regno.esegui(.ordina(voce: "leva_fanteria_leggera"))
        _ = try await regno.esegui(.prosegui)
        _ = try await regno.esegui(.ordina(voce: "leva_cavalleria_manovrata"))
        for _ in 2...MomentoDellAnno.stazioniInvernali { _ = try await regno.esegui(.prosegui) }
        _ = try await regno.esegui(.attendiInverno)
        _ = try await regno.esegui(.ordina(voce: "leva_fanteria_leggera"))
        for _ in 1...MomentoDellAnno.stazioniInvernali { _ = try await regno.esegui(.prosegui) }
        return regno
    }

    func test_05_14_6_riproduzione_d_oro_di_due_anni_di_regno() async throws {
        let attesa = try String(contentsOf: Self.cartellaFixture.appendingPathComponent("impronta.txt"),
                                encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        let cartella = try slot()
        try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: Self.cartellaFixture.appendingPathComponent("giornale.jsonl"),
                                         to: cartella.appendingPathComponent(SessioneRegno.nomeGiornale))
        let valoriRegno = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica,
                                                     archetipiNoti: Set(valori.archetipi.keys))
        let regno = try SessioneRegno(riprendi: cartella, valori: valoriRegno,
                                      versioneValori: valori.versioneEffettiva,
                                      versioniCompatibili: valori.versioniCompatibili)
        let impronta = await regno.impronta()
        XCTAssertEqual(impronta, attesa,
                       "riproduzione d'oro del regno: rigenerare solo con revisione esplicita (05 §14.6)")
        let stato = await regno.stato
        XCTAssertEqual(stato.anno, 3)
        XCTAssertEqual(stato.momento, .operativo)
        // Il copione giocato adesso dà lo stesso stato del giornale committato.
        let dalVivo = try await Self.giocaCopione(in: try slot(), valori: valori)
        let improntaDalVivo = await dalVivo.impronta()
        XCTAssertEqual(improntaDalVivo, attesa, "il copione giocato oggi non dà più lo stato registrato")
    }
}
