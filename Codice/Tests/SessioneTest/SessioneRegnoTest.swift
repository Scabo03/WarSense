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

    /// La lista chiusa dei nomi (01 §5.6.0.4): la stessa del fronte, letta dal file che la contiene,
    /// perché i nomi che il regno dà alle formazioni siano quelli che la campagna conosce.
    static let nomiDiFabbrica: [IdentificatoreDati] =
        (try? CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica).nomiGruppi) ?? []

    /// Valori di prova con stagioni di due giornate, perché un anno intero si giochi in sei giornate.
    /// Le voci durano una stazione, sicché ciò che si ordina è pronto in primavera; il mantenimento
    /// è di quattro decimi di denaro per atomo, troncati, mai sotto uno (incarico 31).
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
            ],
            mantenimento: ValoriMantenimento(quotaPerMisura: Scalato(millesimi: 400), quotaMinima: 1),
            nomiDelleUnita: nomiDiFabbrica)
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
        // Incarico 31: sul fronte ciascun gruppo porta il nome della propria formazione, e
        // l'avversario prende il primo nome della lista che il regno non tiene per sé.
        let forzeDelRegno = await regno.stato.forze
        XCTAssertEqual(forzeDelRegno.formazioni.map(\.nome), ["corvo", "lupo", "falco"])
        XCTAssertEqual(stato.gruppiOrdinati.filter { $0.parte == .giocatore }.map(\.nome), ["corvo", "lupo", "falco"])
        XCTAssertEqual(stato.gruppiOrdinati.filter { $0.parte == .avversario }.map(\.nome), ["orso"])
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
        _ = try await regno.esegui(.ordina(voce: "leva_fanteria_leggera", bersaglio: nil))
        _ = try await regno.esegui(.ordina(voce: "leva_fanteria_pesante", bersaglio: nil))
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
        _ = try await regno.esegui(.ordina(voce: "leva_fanteria_leggera", bersaglio: nil))
        let quante = try await regno.azzeraSpese()
        XCTAssertEqual(quante, 2)
        stato = await regno.stato
        XCTAssertTrue(stato.lavori.isEmpty)
        // La dotazione e la rendita, meno il mantenimento che il gioco ha prelevato da sé all'inizio
        // dell'inverno (incarico 31): 2 per i sei atomi di Corvo, 3 per gli otto di Lupo, 1 per i
        // tre di Falco. L'azzeramento restituisce le spese, non il mantenimento.
        XCTAssertEqual(stato.mantenimento[.denaro], 6)
        XCTAssertEqual(stato.riserve[.denaro], 210 - 6)
        do { _ = try await regno.annullaSpesa(); XCTFail("non c'è nulla da annullare") }
        catch SessioneRegno.ErroreSessione.nienteDaRitirare {}
        do { _ = try await regno.azzeraSpese(); XCTFail("non c'è nulla da azzerare") }
        catch SessioneRegno.ErroreSessione.nienteDaRitirare {}

        // L'apertura di una stazione è un punto di conferma: oltre non si torna (05 §6.5).
        _ = try await regno.esegui(.ordina(voce: "leva_fanteria_pesante", bersaglio: nil))
        _ = try await regno.esegui(.prosegui)
        do { _ = try await regno.annullaSpesa(); XCTFail("la spesa della stazione precedente è confermata") }
        catch SessioneRegno.ErroreSessione.nienteDaRitirare {}
        _ = try await regno.esegui(.ordina(voce: "leva_fanteria_leggera", bersaglio: nil))
        for _ in 2...MomentoDellAnno.stazioniInvernali { _ = try await regno.esegui(.prosegui) }

        stato = await regno.stato
        XCTAssertEqual(stato.anno, 2)
        XCTAssertEqual(stato.momento, .operativo)
        // Le reclute sono una formazione nuova. Dall'incarico 31 ha un nome — il primo libero —, i
        // suoi reparti portano l'anno di leva, e fino alla prima giornata della campagna è «in
        // arrivo»: per questo le unità che ci sono già restano tre, e le formazioni sono quattro.
        XCTAssertEqual(stato.forze.formazioni.count, 4, "le reclute sono una formazione nuova")
        XCTAssertEqual(stato.forze.numeroDiUnita, 3, "la formazione delle reclute è ancora in arrivo")
        XCTAssertEqual(stato.forze.formazioni.map(\.nome), ["corvo", "lupo", "falco", "orso"])
        XCTAssertEqual(stato.forze.formazioni.last?.arrivo, .primavera)
        XCTAssertEqual(stato.forze.formazioni.last?.composizione,
                       [Reparto(archetipo: "fanteria_pesante", atomi: 8, leva: 1),
                        Reparto(archetipo: "fanteria_leggera", atomi: 6, leva: 1)])

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
        XCTAssertEqual(statoSeconda.gruppiOrdinati.filter { $0.parte == .giocatore }.map(\.nome).sorted(),
                       ["corvo", "falco", "lupo", "orso"], "i nomi sono quelli dell'anno prima, più le reclute")
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

    /// Il copione: due anni con i valori di FABBRICA. Il giornale del regno porta l'esito e non la
    /// campagna, sicché i due esiti sono scritti qui, nella forma in cui il ponte li compone.
    ///
    /// Dalla seconda tappa (incarico 31) il copione passa per ogni comando del regno e per i due
    /// modi di ordinare — con e senza bersaglio —, perché l'oro sorvegli anche quelli. Il primo anno:
    /// la campagna vinta sul fronte dell'istmo, con la terza armata caduta e la prima dimezzata; tre
    /// leve su due schermate, di cui una lunga ordinata alla seconda, che matura in estate; due
    /// addestramenti mirati. Il secondo anno: la formazione non armata tenuta in patria; la campagna
    /// vinta sul fronte del guado prima dell'estate, sicché la cavalleria non fa in tempo ad arrivare
    /// e torna ancora in arrivo; d'inverno un solo addestramento mantenuto — l'altro si perde — e una leva.
    ///
    /// Il copione NON finisce in primavera ma a metà del terzo inverno, alla seconda schermata, con
    /// tre lavori ordinati: in primavera il riporto taglia le riserve alla quota e i lavori si
    /// svuotano, sicché uno stato di primavera non porta traccia di quanto le voci sono costate né
    /// di quanto il mantenimento ha prelevato. A metà inverno l'impronta porta le riserve, il
    /// mantenimento dichiarato e i lavori in corso, e l'oro si accorge di un costo che cambia.
    ///
    /// Ogni comando del copione DEVE essere valido: uno respinto non entrerebbe nel giornale, e
    /// l'oro registrerebbe in silenzio un'altra storia.
    static func giocaCopione(in cartella: URL, valori: ValoriDiGioco) async throws -> SessioneRegno {
        let valoriRegno = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica,
                                                     archetipiNoti: Set(valori.archetipi.keys),
                                                     miglioramentiNoti: Set(valori.miglioramenti.keys))
        let regno = try SessioneRegno(nuovo: valoriRegno, versioneValori: valori.versioneEffettiva,
                                      versioneTesti: "0.1.1", cartella: cartella, seme: 7,
                                      identificatore: "oro-regno")
        func esegui(_ comando: ComandoRegno, riga: UInt = #line) async throws {
            let esito = try await regno.esegui(comando)
            XCTAssertTrue(esito.esito.eValido, "il copione d'oro contiene un comando respinto: \(comando), "
                          + "motivo \(String(describing: esito.esito.motivo))", line: riga)
        }

        // Il primo anno.
        try await esegui(.apriCampagna(fronte: "istmo"))
        var forze = await regno.stato.forze
        // Rientrano tutti tranne la terza armata, caduta; la prima torna dimezzata.
        var superstiti = forze.formazioni
        superstiti.remove(at: 2)
        superstiti[0].composizione = [Reparto(archetipo: "fanteria_leggera", atomi: 3)]
        try await regno.concludiCampagna(EsitoCampagna(
            fronte: "istmo", anno: 1, modo: .annientamento, vincitore: .giocatore, giornate: 47,
            battaglieVinte: 2, battagliePerse: 1, superstiti: .sciami(formazioni: superstiti, prossimoNome: 0)))
        try await esegui(.attendiInverno)
        try await esegui(.ordina(voce: "leva_fanteria_pesante", bersaglio: nil))
        try await esegui(.ordina(voce: "leva_fanteria_leggera", bersaglio: nil))
        try await esegui(.ordina(voce: "addestramento_mirato", bersaglio: BersaglioMilitare(unita: "lupo", elemento: 1)))
        try await esegui(.prosegui)
        try await esegui(.ordina(voce: "leva_cavalleria_manovrata", bersaglio: nil))
        try await esegui(.ordina(voce: "addestramento_mirato", bersaglio: BersaglioMilitare(unita: "corvo", elemento: 0)))
        for _ in 2...MomentoDellAnno.stazioniInvernali { try await esegui(.prosegui) }

        // Il secondo anno.
        try await esegui(.destina(unita: "cervo", alFronte: false))
        try await esegui(.apriCampagna(fronte: "guado"))
        forze = await regno.stato.forze
        // Rientra chi era partito, com'era; la formazione che doveva arrivare in estate non ha fatto
        // in tempo, e torna ancora in arrivo; quella tenuta in patria non è nell'esito.
        let rientrati = forze.formazioni.filter(\.parteConLaCampagna).map { formazione in
            FormazioneDelRegno(nome: formazione.nome, categoria: formazione.categoria,
                               composizione: formazione.composizione,
                               arrivo: formazione.arrivo == .primavera ? nil : formazione.arrivo)
        }
        try await regno.concludiCampagna(EsitoCampagna(
            fronte: "guado", anno: 2, modo: .annientamento, vincitore: .giocatore, giornate: 20,
            battaglieVinte: 1, battagliePerse: 0, superstiti: .sciami(formazioni: rientrati, prossimoNome: 0)))
        try await esegui(.attendiInverno)
        try await esegui(.ordina(voce: "mantenimento_addestramento", bersaglio: BersaglioMilitare(unita: "lupo", elemento: 1)))
        try await esegui(.ordina(voce: "leva_fanteria_leggera", bersaglio: nil))
        for _ in 1...MomentoDellAnno.stazioniInvernali { try await esegui(.prosegui) }

        // Il terzo anno, senza campagna, fino alla seconda schermata dell'inverno.
        try await esegui(.attendiInverno)
        try await esegui(.ordina(voce: "leva_fanteria_pesante", bersaglio: nil))
        try await esegui(.ordina(voce: "addestramento_mirato", bersaglio: BersaglioMilitare(unita: "lince", elemento: 1)))
        try await esegui(.prosegui)
        try await esegui(.ordina(voce: "mantenimento_addestramento", bersaglio: BersaglioMilitare(unita: "lupo", elemento: 1)))
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
                                                     archetipiNoti: Set(valori.archetipi.keys),
                                                     miglioramentiNoti: Set(valori.miglioramenti.keys))
        let regno = try SessioneRegno(riprendi: cartella, valori: valoriRegno,
                                      versioneValori: valori.versioneEffettiva,
                                      versioniCompatibili: valori.versioniCompatibili)
        let impronta = await regno.impronta()
        XCTAssertEqual(impronta, attesa,
                       "riproduzione d'oro del regno: rigenerare solo con revisione esplicita (05 §14.6)")
        let stato = await regno.stato
        XCTAssertEqual(stato.anno, 3)
        // Il copione d'oro finiva nella primavera del terzo anno; dall'incarico 31 prosegue fino alla
        // seconda schermata dell'inverno di quell'anno, perché l'impronta porti riserve, mantenimento
        // e lavori (si veda `giocaCopione`).
        XCTAssertEqual(stato.momento, .inverno(stazione: 2))
        let fondazione = await regno.fondazione
        XCTAssertEqual(fondazione?.versioneSchema, FondazioneRegno.schemaCorrente,
                       "l'oro è scritto nello schema corrente del giornale del regno")
        // Ciò che il copione racconta, letto sullo stato che il giornale d'oro ricostruisce (incarico
        // 31): i nomi sono quelli con cui le formazioni sono nate, la terza armata caduta non ha
        // lasciato il proprio a nessuno, la formazione tenuta in patria lo è ancora, e dei due
        // addestramenti resta quello mantenuto.
        XCTAssertEqual(stato.forze.formazioni.map(\.nome), ["corvo", "lupo", "orso", "cervo", "lince", "aquila", "volpe"])
        XCTAssertEqual(stato.forze.formazioni.filter(\.inPatria).map(\.nome), ["cervo"])
        XCTAssertTrue(stato.forze.formazioni.allSatisfy { $0.arrivo == nil }, "d'inverno sono tutte in patria")
        XCTAssertEqual(stato.forze.reparto(BersaglioMilitare(unita: "lupo", elemento: 1))?.miglioramento,
                       "addestramento_mirato")
        XCTAssertNil(stato.forze.reparto(BersaglioMilitare(unita: "corvo", elemento: 0))?.miglioramento)
        // A metà inverno lo stato porta il mantenimento prelevato, i lavori ordinati e ciò che è
        // rimasto in cassa dopo averli pagati: sono i numeri che l'impronta d'oro sorveglia.
        XCTAssertEqual(stato.mantenimento[.denaro], 22, "1 + (7 + 3) + 1 + 1 + (3 + 2) + 2 + 2")
        XCTAssertTrue(stato.sciolti.isEmpty)
        XCTAssertEqual(stato.lavori.map(\.voce), ["leva_fanteria_pesante", "addestramento_mirato", "mantenimento_addestramento"])
        XCTAssertEqual(stato.lavori.map(\.stazione), [1, 1, 2])
        XCTAssertEqual(stato.lavori.map(\.pronto), [.primavera, .primavera, .primavera])
        XCTAssertEqual(stato.lavori.map(\.bersaglio), [nil, BersaglioMilitare(unita: "lince", elemento: 1),
                                                       BersaglioMilitare(unita: "lupo", elemento: 1)])
        // Le riserve: il riporto del secondo anno, la rendita, meno il mantenimento e i tre lavori.
        // Il costo dell'addestramento è quello dei valori di fabbrica — sei atomi per cinque monete
        // per il peso della voce —, letto dal lavoro stesso.
        XCTAssertEqual(stato.lavori[0].costo[.denaro], 64)
        XCTAssertEqual(stato.lavori[2].costo[.denaro], 8)
        XCTAssertEqual(stato.riserve[.denaro],
                       32 + 200 - 22 - 64 - stato.lavori[1].costo[.denaro] - 8)
        XCTAssertEqual(stato.riserve[.uomini], 3 + 24 - 8)
        XCTAssertEqual(stato.riserve[.metalli], 4 + 30 - 16)
        // Il copione giocato adesso dà lo stesso stato del giornale committato.
        let dalVivo = try await Self.giocaCopione(in: try slot(), valori: valori)
        let improntaDalVivo = await dalVivo.impronta()
        XCTAssertEqual(improntaDalVivo, attesa, "il copione giocato oggi non dà più lo stato registrato")
    }
}
