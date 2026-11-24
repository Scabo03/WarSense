import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// La SECONDA TAPPA DEL REGNO (incarico 31) attraverso le Sessioni: il regno, la campagna dell'anno
/// nel suo slot annidato, e i giornali che ne sono la verità. Qui le regole si provano com'è fatta
/// una partita — comandi che passano dal giornale, campagne giocate giornata per giornata, battaglie
/// il cui esito torna in campagna e poi in patria — e ogni volta si riprende dal giornale e si
/// pretende lo stesso stato. Le formule stanno nelle prove del Motore (`RegnoSecondaTappaTest`,
/// `ArriviDallaPatriaTest`).
final class SessioneRegnoSecondaTappaTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
    }

    // MARK: - I valori e il fronte delle prove

    /// Valori di prova: stagioni di due giornate, perché un anno si giochi in sei; le tre leve con
    /// le durate di fabbrica, l'addestramento mirato e il suo mantenimento; il mantenimento delle
    /// forze di quattro decimi di denaro per atomo, mai sotto uno. Quattro formazioni iniziali:
    /// Corvo e Lupo armate, Falco di ricognizione, Orso non armata.
    static func valoriDiProva() -> ValoriRegno {
        ValoriRegno(
            giornatePerStagione: 2,
            quotaRiporto: Scalato(millesimi: 100),
            dotazioneIniziale: ["denaro": 10, "uomini": 1, "metalli": 2, "materiale": 3, "animali": 0],
            renditaAnnua: ["denaro": 400, "uomini": 40, "metalli": 60, "materiale": 30, "animali": 20],
            premioBattagliaVinta: Scalato(millesimi: 100),
            premioCampagnaVinta: Scalato(millesimi: 500),
            baseLeva: ["denaro": 5, "uomini": 1, "metalli": 1, "materiale": 0, "animali": 1],
            costoMinimo: 1,
            voci: [
                VoceDelRegno(identificatore: "leva_fanteria_leggera",
                             pesi: ["denaro": Scalato(intero: 1), "uomini": Scalato(intero: 1),
                                    "metalli": Scalato(millesimi: 500)],
                             durata: 2, effetto: .reclutaReparto(archetipo: "fanteria_leggera", atomi: 6)),
                VoceDelRegno(identificatore: "leva_fanteria_pesante",
                             pesi: ["denaro": Scalato(millesimi: 1600), "uomini": Scalato(intero: 1),
                                    "metalli": Scalato(intero: 2)],
                             durata: 4, effetto: .reclutaReparto(archetipo: "fanteria_pesante", atomi: 8)),
                VoceDelRegno(identificatore: "leva_cavalleria_manovrata",
                             pesi: ["denaro": Scalato(millesimi: 2400), "uomini": Scalato(intero: 1),
                                    "metalli": Scalato(intero: 1), "animali": Scalato(intero: 1)],
                             durata: 6, effetto: .reclutaReparto(archetipo: "cavalleria_manovrata", atomi: 6)),
                VoceDelRegno(identificatore: "addestramento_mirato",
                             pesi: ["denaro": Scalato(millesimi: 800)],
                             durata: 1, effetto: .miglioraReparto(miglioramento: "addestramento_mirato")),
                VoceDelRegno(identificatore: "mantenimento_addestramento",
                             pesi: ["denaro": Scalato(millesimi: 200)],
                             durata: 1, effetto: .mantieniMiglioramento(miglioramento: "addestramento_mirato")),
            ],
            fronti: [FronteDelRegno(identificatore: "pianura_lunga", scenario: "campagna_grande")],
            faseIniziale: .arcaica,
            forzeIniziali: [
                FormazioneIniziale(categoria: "armato", composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)]),
                FormazioneIniziale(categoria: "armato", composizione: [.init(archetipo: "fanteria_pesante", atomi: 8)]),
                FormazioneIniziale(categoria: "ricognizione",
                                   composizione: [.init(archetipo: "fanteria_leggera", atomi: 3)], competenza: 5),
                FormazioneIniziale(categoria: "non_armata", composizione: [.init(archetipo: "fanteria_leggera", atomi: 4)],
                                   carico: 4, sogliaProtezione: 2),
            ],
            mantenimento: ValoriMantenimento(quotaPerMisura: Scalato(millesimi: 400), quotaMinima: 1),
            nomiDelleUnita: SessioneRegnoTest.nomiDiFabbrica)
    }

    static let quartierGenerale = Cella(riga: 10, colonna: 6)

    /// Il fronte ASSEDIATO: sulla pianura lunga un gruppo armato avversario tiene il quartier
    /// generale del giocatore — riga 10, casella 6 —, e i gruppi del giocatore gli stanno intorno.
    /// Serve a due cose. La condotta dell'avversario non guadagna nulla muovendosi da lì e resta
    /// dov'è, sicché le battaglie nascono soltanto quando un gruppo del giocatore entra in quella
    /// casella, alla giornata che la prova sceglie. E chi arriva dalla patria trova il quartier
    /// generale occupato, ed entra nella casella libera più vicina. Delle tre caselle accanto al
    /// quartier generale — a ovest, a est e a nord — la sola a ovest è una casella di partenza: le
    /// altre due restano libere per chi arriva.
    static let fronteAssediato = ScenarioCampagna(
        mappa: "pianura_lunga",
        gruppiGiocatore: [(10, 5), (9, 5), (8, 5), (8, 6)].map {
            .init(riga: $0.0, colonna: $0.1, composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)])
        },
        gruppiAvversario: [.init(riga: 10, colonna: 6, composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)])])

    // MARK: - Attrezzi

    private func slot() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("regno-31-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func nuovo(_ cartella: URL) throws -> SessioneRegno {
        try SessioneRegno(nuovo: Self.valoriDiProva(), versioneValori: valori.versioneEffettiva, versioneTesti: "0.1.1",
                          cartella: cartella, seme: 3131, identificatore: "regno-seconda-tappa")
    }

    private func riprendi(_ cartella: URL) throws -> SessioneRegno {
        try SessioneRegno(riprendi: cartella, valori: Self.valoriDiProva(), versioneValori: valori.versioneEffettiva,
                          versioniCompatibili: valori.versioniCompatibili)
    }

    private func apri(_ regno: SessioneRegno, in cartella: URL, file: StaticString = #filePath,
                      line: UInt = #line) async throws -> SessioneCampagna {
        let anno = await regno.stato.anno
        let aperta = try await regno.apriCampagna(
            fronte: "pianura_lunga", scenarioDelFronte: Self.fronteAssediato, valori: valori,
            valoriCampagna: valoriCampagna, versioneTesti: "0.1.1", cartellaDelRegno: cartella,
            seme: 77, identificatore: "campagna-anno-\(anno)")
        XCTAssertTrue(aperta.esito.eValido, "la campagna dovrebbe aprirsi: \(String(describing: aperta.esito.motivo))",
                      file: file, line: line)
        return try XCTUnwrap(aperta.campagna, file: file, line: line)
    }

    /// Esegue un comando del regno che deve essere valido.
    @discardableResult
    private func esegui(_ regno: SessioneRegno, _ comando: ComandoRegno, file: StaticString = #filePath,
                        line: UInt = #line) async throws -> [EventoRegno] {
        let esito = try await regno.esegui(comando)
        XCTAssertTrue(esito.esito.eValido, "\(comando) dovrebbe essere valido: \(String(describing: esito.esito.motivo))",
                      file: file, line: line)
        return esito.eventi
    }

    private func finoAllaPrimavera(_ regno: SessioneRegno, file: StaticString = #filePath,
                                   line: UInt = #line) async throws -> [EventoRegno] {
        var ultimi: [EventoRegno] = []
        while await regno.stato.momento.eInverno { ultimi = try await esegui(regno, .prosegui, file: file, line: line) }
        return ultimi
    }

    /// Ordina a un gruppo del giocatore la marcia in una casella adiacente, coi giorni che il
    /// Motore le attribuisce.
    private func marcia(_ campagna: SessioneCampagna, _ nome: String, verso casella: Cella,
                        file: StaticString = #filePath, line: UInt = #line) async throws {
        let stato = await campagna.stato
        let gruppo = try XCTUnwrap(stato.gruppiOrdinati.first { $0.nome == nome && $0.parte == .giocatore },
                                   "manca il gruppo \(nome)", file: file, line: line)
        let vista = await campagna.vista(per: .giocatore)
        let comando = try XCTUnwrap(vista.comandoDiMarcia(per: gruppo.id, a: casella),
                                    "\(nome) non può marciare in \(casella)", file: file, line: line)
        let esito = try await campagna.esegui(comando, parte: .giocatore).esito
        XCTAssertTrue(esito.eValido, "marcia respinta: \(String(describing: esito.motivo))", file: file, line: line)
    }

    /// Chiude giornate finché una battaglia resta in sospeso; restituisce la battaglia.
    private func finoAllaBattaglia(_ campagna: SessioneCampagna, alPiu giornate: Int = 4,
                                   file: StaticString = #filePath, line: UInt = #line) async throws -> BattagliaInSospeso {
        for _ in 0..<giornate {
            if let battaglia = await campagna.stato.battaglieInSospeso.first { return battaglia }
            try await campagna.chiudiGiornata()
        }
        let ultima = await campagna.stato.battaglieInSospeso.first
        return try XCTUnwrap(ultima, "nessuna battaglia in sospeso", file: file, line: line)
    }

    /// L'esito di una battaglia in cui UNA delle due parti è annientata e l'altra resta nella
    /// casella contesa coi propri superstiti.
    private func esito(_ battaglia: BattagliaInSospeso, _ stato: StatoCampagna, annientato: Parte,
                       superstiti: [Reparto]) -> EsitoInCampagna {
        EsitoInCampagna(
            identificatore: battaglia.identificatore, casella: battaglia.casella, sconfitto: annientato,
            modo: .annientamento, gruppoGiocatore: battaglia.gruppoGiocatore, gruppoAvversario: battaglia.gruppoAvversario,
            composizioneGiocatore: annientato == .giocatore ? [] : superstiti,
            composizioneAvversario: annientato == .avversario ? [] : superstiti,
            posizioneGiocatore: annientato == .giocatore ? nil : battaglia.casella,
            posizioneAvversario: annientato == .avversario ? nil : battaglia.casella)
    }

    private func nomi(_ stato: StatoCampagna, di parte: Parte) -> [IdentificatoreDati] {
        stato.gruppiOrdinati.filter { $0.parte == parte }.map(\.nome)
    }

    private func arrivi(_ eventi: [EventoCampagna]) -> [IdentificatoreDati] {
        eventi.compactMap { if case .arrivoDallaPatria(_, let nome, _) = $0 { return nome } else { return nil } }
    }

    private func righeDelGiornale(_ cartella: URL) throws -> [String] {
        try String(contentsOf: cartella.appendingPathComponent(SessioneRegno.nomeGiornale), encoding: .utf8)
            .split(separator: "\n").map(String.init)
    }

    private func leggera(_ atomi: Int, leva: Int? = nil, migliorata: Bool = false) -> Reparto {
        Reparto(archetipo: "fanteria_leggera", atomi: atomi, miglioramento: migliorata ? "addestramento_mirato" : nil,
                leva: leva)
    }

    // MARK: - Due anni interi

    /// Due anni interi giocati attraverso le Sessioni. Il primo: una formazione tenuta in patria,
    /// una perduta in battaglia — la prima, Corvo —, la campagna che l'inverno interrompe; d'inverno
    /// tre leve che maturano in tre stagioni diverse e un addestramento mirato. Il secondo: le reclute della
    /// primavera entrano con la prima giornata, quelle dell'estate arrivano a campagna aperta e
    /// vincono la battaglia che conclude la campagna, quelle dell'autunno non fanno in tempo ad
    /// arrivare. In ogni momento i nomi di chi c'è sono quelli con cui è nato, e a ogni passo il
    /// giornale rigiocato dà lo stesso stato.
    func test_incarico_31_due_anni_interi_con_una_formazione_perduta_una_in_patria_un_arrivo_ricevuto_e_uno_mai_giunto() async throws {
        let cartella = try slot()
        var regno = try nuovo(cartella)
        var stato = await regno.stato
        XCTAssertEqual(stato.forze.formazioni.map(\.nome), ["corvo", "lupo", "falco", "orso"])

        // --- IL PRIMO ANNO ---
        // Orso, la formazione non armata, resta in patria: la scelta è un comando, e sta nel giornale.
        let destinata = try await esegui(regno, .destina(unita: "orso", alFronte: false))
        XCTAssertEqual(destinata, [.unitaDestinata(unita: "orso", alFronte: false)])
        XCTAssertTrue(try righeDelGiornale(cartella).last?.contains(#""destina":{"alFronte":false,"unita":"orso"}"#) == true)
        stato = await regno.stato
        let orsoInPatria = try XCTUnwrap(stato.forze.formazioni.first { $0.nome == "orso" })
        XCTAssertTrue(orsoInPatria.inPatria)

        var campagna = try await apri(regno, in: cartella)
        var fronte = await campagna.stato
        XCTAssertEqual(nomi(fronte, di: .giocatore), ["corvo", "lupo", "falco"], "Orso non è partito")
        XCTAssertEqual(fronte.calendario, CalendarioDiCampagna(anno: 1, giornatePerStagione: 2))
        XCTAssertEqual(fronte.gruppiOrdinati.first { $0.nome == "corvo" }?.posizione, Cella(riga: 10, colonna: 5))
        XCTAssertEqual(fronte.gruppiOrdinati.first { $0.nome == "lupo" }?.posizione, Cella(riga: 9, colonna: 5))
        let delRegno = Set(stato.forze.formazioni.map(\.nome))
        XCTAssertTrue(delRegno.isDisjoint(with: nomi(fronte, di: .avversario)),
                      "l'avversario non porta un nome del regno, nemmeno quello di chi è rimasto in patria")
        XCTAssertEqual(fronte.nomiRiservati.map(Set.init), delRegno)
        // A campagna aperta la scelta di chi parte non si cambia più.
        let tardi = try await regno.esegui(.destina(unita: "orso", alFronte: true))
        XCTAssertEqual(tardi.esito.motivo, .campagnaAperta)

        // Corvo entra nel quartier generale tenuto dall'avversario, e vi cade.
        try await marcia(campagna, "corvo", verso: Self.quartierGenerale)
        var battaglia = try await finoAllaBattaglia(campagna)
        fronte = await campagna.stato
        XCTAssertEqual(battaglia.casella, Self.quartierGenerale)
        XCTAssertEqual(fronte.gruppi[battaglia.gruppoGiocatore]?.nome, "corvo")
        try await campagna.concludiBattaglia(esito(battaglia, fronte, annientato: .giocatore, superstiti: [leggera(4)]))
        fronte = await campagna.stato
        XCTAssertNil(fronte.conclusione, "resta Lupo: la campagna prosegue")
        XCTAssertEqual(nomi(fronte, di: .giocatore), ["lupo", "falco"])

        // Le giornate che restano, fino all'inverno.
        var chiusure = 0
        while await campagna.stato.conclusione == nil, chiusure < 12 {
            if await !campagna.stato.battaglieInSospeso.isEmpty { return XCTFail("battaglia inattesa") }
            try await campagna.chiudiGiornata()
            chiusure += 1
        }
        fronte = await campagna.stato
        XCTAssertEqual(fronte.conclusione, ConclusioneCampagna(modo: .inverno, vincitore: nil, giorno: 6))
        XCTAssertEqual(nomi(fronte, di: .giocatore), ["lupo", "falco"])

        // L'esito torna in patria: Corvo — la prima formazione — è perduto; gli altri hanno il nome
        // di prima e non sono scalati di un posto; Orso è identico.
        _ = try await regno.riceviEsito(dalla: fronte)
        stato = await regno.stato
        XCTAssertEqual(stato.forze.formazioni.map(\.nome), ["lupo", "falco", "orso"])
        XCTAssertEqual(stato.campagna.esito?.battagliePerse, 1)
        XCTAssertEqual(stato.campagna.esito?.superstiti.formazioni.map(\.nome), ["lupo", "falco"])
        XCTAssertEqual(stato.forze.formazioni.first { $0.nome == "orso" }, orsoInPatria,
                       "chi è rimasto in patria è identico a prima della campagna")
        XCTAssertEqual(stato.forze.formazioni.first { $0.nome == "lupo" }?.composizione,
                       [Reparto(archetipo: "fanteria_pesante", atomi: 8)])
        XCTAssertEqual(stato.forze.formazioni.first { $0.nome == "falco" }?.categoria, .ricognizione(competenza: 5))

        // La ripresa dal giornale, a campagna conclusa.
        var impronta = await regno.impronta()
        regno = try riprendi(cartella)
        var improntaRipresa = await regno.impronta()
        XCTAssertEqual(improntaRipresa, impronta)

        // L'inverno: l'entrata, il mantenimento, e i lavori.
        let inverno = try await esegui(regno, .attendiInverno)
        guard case .invernoCominciato(_, _, let mantenimento, let sciolti)? = inverno.first else {
            return XCTFail("l'inverno si dichiara con un evento")
        }
        XCTAssertEqual(mantenimento[.denaro], 3 + 1 + 1, "Lupo 3, Falco 1, Orso 1: Corvo non c'è più")
        XCTAssertTrue(sciolti.isEmpty)
        stato = await regno.stato
        XCTAssertEqual(stato.riserve[.denaro], 10 + 400 - 5)

        // Alla prima schermata: una leva leggera, pronta in primavera; una di cavalleria, pronta in
        // estate; l'addestramento mirato degli otto atomi di Lupo.
        try await esegui(regno, .ordina(voce: "leva_fanteria_leggera", bersaglio: nil))
        try await esegui(regno, .ordina(voce: "leva_cavalleria_manovrata", bersaglio: nil))
        let addestramento = try XCTUnwrap(Self.valoriDiProva().voce("addestramento_mirato"))
        let bersagli = await regno.bersagli(di: addestramento)
        XCTAssertEqual(bersagli, [BersaglioMilitare(unita: "lupo", elemento: 0), BersaglioMilitare(unita: "falco", elemento: 0),
                                  BersaglioMilitare(unita: "orso", elemento: 0)])
        let costo = await regno.costo(di: addestramento, bersaglio: bersagli[0])
        XCTAssertEqual(costo?[.denaro], 32, "otto atomi per cinque monete per otto decimi")
        let senzaBersaglio = await regno.costo(di: addestramento)
        XCTAssertNil(senzaBersaglio, "senza il reparto il costo non c'è")
        let ordinato = try await esegui(regno, .ordina(voce: "addestramento_mirato", bersaglio: bersagli[0]))
        XCTAssertEqual(ordinato, [.lavoroOrdinato(voce: "addestramento_mirato", costo: try XCTUnwrap(costo),
                                                  pronto: .primavera, bersaglio: bersagli[0])])
        let rimasti = await regno.bersagli(di: addestramento)
        XCTAssertEqual(rimasti, Array(bersagli.dropFirst()), "il reparto già al lavoro non si offre più")
        let doppio = try await regno.esegui(.ordina(voce: "addestramento_mirato", bersaglio: bersagli[0]))
        XCTAssertEqual(doppio.esito.motivo, .giaOrdinato)
        // Alla quarta schermata: un'altra leva di cavalleria, che matura in autunno.
        for _ in 1..<MomentoDellAnno.stazioniInvernali { try await esegui(regno, .prosegui) }
        try await esegui(regno, .ordina(voce: "leva_cavalleria_manovrata", bersaglio: nil))
        stato = await regno.stato
        XCTAssertEqual(stato.lavori.map(\.pronto), [.primavera, .estate, .primavera, .autunno])

        // La ripresa a metà inverno: i lavori, il bersaglio e il mantenimento dichiarato sono quelli.
        impronta = await regno.impronta()
        regno = try riprendi(cartella)
        improntaRipresa = await regno.impronta()
        XCTAssertEqual(improntaRipresa, impronta)
        stato = await regno.stato
        XCTAssertEqual(stato.lavori.map(\.bersaglio), [nil, nil, bersagli[0], nil])
        XCTAssertEqual(stato.mantenimento[.denaro], 5)

        // La primavera: tre formazioni di reclute, una per stagione, e Lupo addestrato.
        let primavera = try await finoAllaPrimavera(regno)
        guard case .primaveraCominciata(let anno, _, let ingressi, let migliorati, _)? = primavera.first else {
            return XCTFail("la primavera si dichiara con un evento")
        }
        XCTAssertEqual(anno, 2)
        XCTAssertEqual(ingressi.map(\.unita), ["cervo", "lince", "aquila"])
        XCTAssertEqual(ingressi.map(\.arrivo), [.primavera, .estate, .autunno])
        let pesanteAddestrata = Reparto(archetipo: "fanteria_pesante", atomi: 8, miglioramento: "addestramento_mirato")
        XCTAssertEqual(migliorati, [ElementoDelleForze(unita: "lupo", reparto: pesanteAddestrata)])
        stato = await regno.stato
        XCTAssertEqual(stato.forze.formazioni.map(\.nome), ["lupo", "falco", "orso", "cervo", "lince", "aquila"],
                       "chi c'era ha il nome di prima; il nome di Corvo, perduto, non è stato dato a nessuna recluta")
        XCTAssertEqual(stato.forze.formazioni.map(\.inPatria), [false, false, true, false, false, false],
                       "la scelta dell'anno prima resta: Orso è ancora in patria")

        // --- IL SECONDO ANNO ---
        campagna = try await apri(regno, in: cartella)
        fronte = await campagna.stato
        XCTAssertEqual(fronte.calendario?.anno, 2)
        XCTAssertEqual(nomi(fronte, di: .giocatore), ["lupo", "falco", "cervo"],
                       "le reclute della primavera sono entrate con la prima giornata")
        let regnoAlSecondoAnno = Set(stato.forze.formazioni.map(\.nome))
        XCTAssertTrue(regnoAlSecondoAnno.isDisjoint(with: nomi(fronte, di: .avversario)))
        let cervo = try XCTUnwrap(fronte.gruppiOrdinati.first { $0.nome == "cervo" })
        XCTAssertNotEqual(cervo.posizione, Self.quartierGenerale, "il quartier generale è tenuto dall'avversario")
        XCTAssertEqual(fronte.griglia.distanza(Self.quartierGenerale, cervo.posizione), 1, "la casella libera più vicina")
        XCTAssertEqual(cervo.composizione, [leggera(6, leva: 1)])
        XCTAssertEqual(fronte.registro.map(\.fatto), [.arrivoDallaPatria(gruppo: "cervo", casella: cervo.posizione)])
        XCTAssertEqual(fronte.arriviInAttesa?.map(\.nome), ["lince", "aquila"])
        XCTAssertEqual(fronte.arriviInAttesa?.map(\.giorno), [3, 5])
        XCTAssertEqual(fronte.gruppiOrdinati.first { $0.nome == "lupo" }?.composizione, [pesanteAddestrata],
                       "il reparto addestrato porta il miglioramento al fronte")

        // Due giornate di primavera. All'apertura della terza — la prima dell'estate — arriva Lince,
        // a campagna aperta, e il giocatore lo sente.
        let prima = try await campagna.chiudiGiornata()
        XCTAssertTrue(arrivi(prima.eventi).isEmpty)
        let seconda = try await campagna.chiudiGiornata()
        fronte = await campagna.stato
        XCTAssertEqual(fronte.giorno, 3)
        XCTAssertEqual(arrivi(seconda.eventi), ["lince"])
        XCTAssertTrue(seconda.eventi.contains(.stagioneCambiata(stagione: .estate)))
        let lince = try XCTUnwrap(fronte.gruppiOrdinati.first { $0.nome == "lince" })
        XCTAssertEqual(lince.composizione, [Reparto(archetipo: "cavalleria_manovrata", atomi: 6, leva: 1)])
        XCTAssertFalse(lince.azioneSpesa)
        XCTAssertEqual(fronte.griglia.distanza(Self.quartierGenerale, lince.posizione), 1)
        XCTAssertEqual(fronte.registro.last?.fatto, .arrivoDallaPatria(gruppo: "lince", casella: lince.posizione))
        XCTAssertEqual(fronte.registro.last?.giorno, 3)
        XCTAssertEqual(fronte.arriviInAttesa?.map(\.nome), ["aquila"])

        // La campagna in corso, ripresa dal proprio giornale — anche senza istantanee —, è la stessa:
        // l'arrivo è avvenuto, e quello che deve ancora venire è ancora atteso.
        let cartellaCampagna = cartella.appendingPathComponent(SessioneRegno.cartellaCampagna)
        let improntaDelFronte = await campagna.impronta()
        for url in try FileManager.default.contentsOfDirectory(at: cartellaCampagna, includingPropertiesForKeys: nil)
        where url.lastPathComponent.hasPrefix("istantanea-") {
            try FileManager.default.removeItem(at: url)
        }
        campagna = try SessioneCampagna(riprendi: cartellaCampagna, valori: valori, valoriCampagna: valoriCampagna)
        let improntaDelFronteRipreso = await campagna.impronta()
        XCTAssertEqual(improntaDelFronteRipreso, improntaDelFronte)
        fronte = await campagna.stato
        XCTAssertEqual(nomi(fronte, di: .giocatore), ["lupo", "falco", "cervo", "lince"])
        XCTAssertEqual(fronte.arriviInAttesa?.map(\.nome), ["aquila"])

        // Lince, appena arrivata, entra nel quartier generale e annienta chi lo teneva: la campagna
        // è vinta in estate, prima che Aquila — attesa per l'autunno — faccia in tempo ad arrivare.
        try await marcia(campagna, "lince", verso: Self.quartierGenerale)
        battaglia = try await finoAllaBattaglia(campagna, alPiu: 2)
        fronte = await campagna.stato
        XCTAssertEqual(fronte.gruppi[battaglia.gruppoGiocatore]?.nome, "lince")
        XCTAssertLessThanOrEqual(fronte.giorno, 4, "ancora estate")
        try await campagna.concludiBattaglia(esito(battaglia, fronte, annientato: .avversario,
                                                   superstiti: [Reparto(archetipo: "cavalleria_manovrata", atomi: 4, leva: 1)]))
        fronte = await campagna.stato
        XCTAssertEqual(fronte.conclusione?.modo, .annientamento)
        XCTAssertEqual(fronte.conclusione?.vincitore, .giocatore)
        XCTAssertEqual(fronte.arriviInAttesa?.map(\.nome), ["aquila"], "Aquila non è mai arrivata")

        // In patria: ciascuno col proprio nome; Aquila ancora in arrivo; Orso identico a due anni prima.
        _ = try await regno.riceviEsito(dalla: fronte)
        stato = await regno.stato
        XCTAssertEqual(stato.forze.formazioni.map(\.nome), ["lupo", "falco", "orso", "cervo", "lince", "aquila"])
        XCTAssertEqual(stato.forze.formazioni.map(\.arrivo), [nil, nil, nil, nil, nil, .autunno])
        XCTAssertEqual(stato.forze.numeroDiUnita, 5)
        XCTAssertEqual(stato.campagna.esito?.vinta, true)
        XCTAssertEqual(stato.campagna.esito?.battaglieVinte, 1)
        XCTAssertEqual(stato.campagna.esito?.superstiti.numeroDiUnita, 4, "rientrano dal fronte Lupo, Falco, Cervo e Lince")
        XCTAssertEqual(stato.forze.formazioni.first { $0.nome == "lince" }?.composizione,
                       [Reparto(archetipo: "cavalleria_manovrata", atomi: 4, leva: 1)], "i superstiti, con l'anno di leva")
        XCTAssertEqual(stato.forze.formazioni.first { $0.nome == "aquila" }?.composizione,
                       [Reparto(archetipo: "cavalleria_manovrata", atomi: 6, leva: 1)])
        XCTAssertEqual(stato.forze.formazioni.first { $0.nome == "orso" }, orsoInPatria,
                       "dopo due campagne Orso è identico a com'era quando il giocatore l'ha tenuto in patria")

        // L'inverno: Aquila raggiunge le altre, e tutte sono mantenute. Il miglioramento di Lupo si mantiene.
        let secondoInverno = try await esegui(regno, .attendiInverno)
        guard case .invernoCominciato(_, _, let secondoMantenimento, _)? = secondoInverno.first else {
            return XCTFail("l'inverno si dichiara con un evento")
        }
        XCTAssertEqual(secondoMantenimento[.denaro], 3 + 1 + 1 + 2 + 1 + 2,
                       "Lupo 3, Falco 1, Orso 1, Cervo 2, Lince 1 (quattro atomi), Aquila 2")
        stato = await regno.stato
        XCTAssertTrue(stato.forze.formazioni.allSatisfy { $0.arrivo == nil })
        let mantenimentoDellAddestramento = try XCTUnwrap(Self.valoriDiProva().voce("mantenimento_addestramento"))
        let daMantenere = await regno.bersagli(di: mantenimentoDellAddestramento)
        XCTAssertEqual(daMantenere, [BersaglioMilitare(unita: "lupo", elemento: 0)])
        try await esegui(regno, .ordina(voce: "mantenimento_addestramento", bersaglio: daMantenere[0]))
        let terzaPrimavera = try await finoAllaPrimavera(regno)
        guard case .primaveraCominciata(let terzoAnno, _, let nuoviIngressi, let nuoviMigliorati, let perduti)?
                = terzaPrimavera.first else { return XCTFail("la primavera si dichiara con un evento") }
        XCTAssertEqual(terzoAnno, 3)
        XCTAssertTrue(nuoviIngressi.isEmpty)
        XCTAssertTrue(nuoviMigliorati.isEmpty)
        XCTAssertTrue(perduti.isEmpty, "il miglioramento mantenuto non si perde")
        stato = await regno.stato
        XCTAssertEqual(stato.forze.formazioni.map(\.nome), ["lupo", "falco", "orso", "cervo", "lince", "aquila"],
                       "al terzo anno i nomi sono quelli con cui ciascuna formazione è nata")
        XCTAssertEqual(stato.forze.formazioni.first { $0.nome == "lupo" }?.composizione, [pesanteAddestrata])
        XCTAssertEqual(stato.forze.formazioni.map(\.inPatria), [false, false, true, false, false, false])

        // La rigiocatura: il giornale del regno, riletto da capo, dà lo stesso stato.
        impronta = await regno.impronta()
        let ripreso = try riprendi(cartella)
        improntaRipresa = await ripreso.impronta()
        XCTAssertEqual(improntaRipresa, impronta, "stato di fondazione più righe del giornale: è l'intera partita")
        let statoRipreso = await ripreso.stato
        XCTAssertEqual(statoRipreso.forze, stato.forze)
        XCTAssertEqual(statoRipreso.registro.count, stato.registro.count)
        let righe = try righeDelGiornale(cartella)
        print("REGNO-SESSIONE-31 righe_giornale=\(righe.count) anno=\(stato.anno) formazioni=\(stato.forze.formazioni.count) registro=\(stato.registro.count)")
    }

    // MARK: - La scelta di chi parte, nel giornale

    func test_incarico_31_C_la_scelta_di_chi_parte_passa_dal_giornale_e_regge_la_ripresa() async throws {
        let cartella = try slot()
        var regno = try nuovo(cartella)
        // Una scelta respinta non entra nel giornale.
        let ignota = try await regno.esegui(.destina(unita: "muflone", alFronte: false))
        XCTAssertEqual(ignota.esito.motivo, .unitaIgnota)
        var righe = await regno.numeroRigheGiornale
        XCTAssertEqual(righe, 1)
        try await esegui(regno, .destina(unita: "lupo", alFronte: false))
        try await esegui(regno, .destina(unita: "falco", alFronte: false))
        try await esegui(regno, .destina(unita: "falco", alFronte: true))
        righe = await regno.numeroRigheGiornale
        XCTAssertEqual(righe, 4, "ogni scelta accolta è una riga")
        // La ripresa prima di aprire la campagna: la scelta è quella lasciata.
        let impronta = await regno.impronta()
        regno = try riprendi(cartella)
        let improntaRipresa = await regno.impronta()
        XCTAssertEqual(improntaRipresa, impronta)
        var stato = await regno.stato
        XCTAssertEqual(stato.forze.formazioni.map(\.inPatria), [false, true, false, false])
        // La campagna nasce senza Lupo, e il suo nome è riservato: lo slot annidato porta lo
        // scenario che il ponte ha composto dalle forze del regno.
        let campagna = try await apri(regno, in: cartella)
        let fronte = await campagna.stato
        XCTAssertEqual(nomi(fronte, di: .giocatore), ["corvo", "falco", "orso"])
        let scenario = await campagna.fondazione.scenario
        XCTAssertEqual(scenario.gruppiGiocatore.map(\.nome), ["corvo", "falco", "orso"])
        XCTAssertEqual(scenario.nomiRiservati, ["lupo"])
        XCTAssertFalse(nomi(fronte, di: .avversario).contains("lupo"))
        // Lo slot perduto si ricrea identico: la scelta sta nello stato del regno, non nello slot.
        try FileManager.default.removeItem(at: cartella.appendingPathComponent(SessioneRegno.cartellaCampagna))
        let ricreata = try await regno.ricreaCampagnaAperta(
            scenarioDelFronte: Self.fronteAssediato, valori: valori, valoriCampagna: valoriCampagna,
            versioneTesti: "0.1.1", cartellaDelRegno: cartella, seme: 5, identificatore: "ricreata")
        let scenarioRicreato = await ricreata?.fondazione.scenario
        XCTAssertEqual(scenarioRicreato, scenario)
        // Se nessuna armata parte, la campagna non si apre e lo slot non nasce.
        let altra = try slot()
        let fermo = try nuovo(altra)
        try await esegui(fermo, .destina(unita: "corvo", alFronte: false))
        try await esegui(fermo, .destina(unita: "lupo", alFronte: false))
        let respinta = try await fermo.apriCampagna(
            fronte: "pianura_lunga", scenarioDelFronte: Self.fronteAssediato, valori: valori,
            valoriCampagna: valoriCampagna, versioneTesti: "0.1.1", cartellaDelRegno: altra, seme: 1,
            identificatore: "mai-nata")
        XCTAssertNil(respinta.campagna)
        XCTAssertEqual(respinta.esito.motivo, .nessunaForza)
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: altra.appendingPathComponent(SessioneRegno.cartellaCampagna).path))
        stato = await fermo.stato
        XCTAssertEqual(stato.campagna, .nonAperta)
    }

    // MARK: - Gli ordini col bersaglio fra le spese della schermata

    func test_incarico_31_F_gli_ordini_su_un_reparto_si_annullano_e_si_azzerano_come_le_altre_spese() async throws {
        let cartella = try slot()
        let regno = try nuovo(cartella)
        try await esegui(regno, .attendiInverno)
        var stato = await regno.stato
        let denaro = stato.riserve[.denaro]
        let corvo = BersaglioMilitare(unita: "corvo", elemento: 0)
        let lupo = BersaglioMilitare(unita: "lupo", elemento: 0)
        try await esegui(regno, .ordina(voce: "addestramento_mirato", bersaglio: corvo))
        try await esegui(regno, .ordina(voce: "addestramento_mirato", bersaglio: lupo))
        stato = await regno.stato
        XCTAssertEqual(stato.riserve[.denaro], denaro - 24 - 32)
        // L'annullamento ritira l'ultimo: il reparto torna addestrabile, e le monete tornano.
        let ritirato = try await regno.annullaSpesa()
        XCTAssertEqual(ritirato.bersaglio, lupo)
        XCTAssertEqual(ritirato.costo[.denaro], 32)
        stato = await regno.stato
        XCTAssertEqual(stato.lavori.map(\.bersaglio), [corvo])
        XCTAssertEqual(stato.riserve[.denaro], denaro - 24)
        let addestramento = try XCTUnwrap(Self.valoriDiProva().voce("addestramento_mirato"))
        var bersagli = await regno.bersagli(di: addestramento)
        XCTAssertTrue(bersagli.contains(lupo))
        XCTAssertFalse(bersagli.contains(corvo))
        // L'azzeramento ritira tutte le spese della schermata.
        try await esegui(regno, .ordina(voce: "leva_fanteria_leggera", bersaglio: nil))
        let quante = try await regno.azzeraSpese()
        XCTAssertEqual(quante, 2)
        stato = await regno.stato
        XCTAssertTrue(stato.lavori.isEmpty)
        XCTAssertEqual(stato.riserve[.denaro], denaro)
        bersagli = await regno.bersagli(di: addestramento)
        XCTAssertTrue(bersagli.contains(corvo))
        // Il mantenimento prelevato non è una spesa della schermata: non si ritira.
        XCTAssertEqual(stato.mantenimento[.denaro], 2 + 3 + 1 + 1)
        do { _ = try await regno.annullaSpesa(); XCTFail("non c'è nulla da annullare") }
        catch SessioneRegno.ErroreSessione.nienteDaRitirare {}
        // La ripresa dopo i ritiri: il giornale non porta traccia degli ordini ritirati.
        try await esegui(regno, .ordina(voce: "addestramento_mirato", bersaglio: lupo))
        let impronta = await regno.impronta()
        let ripreso = try riprendi(cartella)
        let improntaRipresa = await ripreso.impronta()
        XCTAssertEqual(improntaRipresa, impronta)
        let righe = try righeDelGiornale(cartella)
        XCTAssertEqual(righe.count, 3, "la fondazione, l'inverno, e il solo ordine rimasto")
        XCTAssertTrue(righe[2].contains(#""ordina":{"bersaglio":{"elemento":0,"unita":"lupo"},"voce":"addestramento_mirato"}"#))
    }

    // MARK: - La ripresa prima del primo inverno

    /// Il regno ripreso subito dopo la nascita, e dopo la sola scelta di chi parte, è quello vivo:
    /// stessa impronta, stesse forze, stesse riserve risorsa per risorsa. (Le riserve si confrontano
    /// qui risorsa per risorsa e non con `==`, che su `Riserve` distingue un saldo nullo scritto da
    /// uno assente: lo stato vivo nasce con l'entrata e il mantenimento «vuoti», quello riletto dal
    /// giornale li ha con le cinque risorse a zero.)
    func test_incarico_31_il_regno_ripreso_prima_del_primo_inverno_e_quello_vivo() async throws {
        let cartella = try slot()
        let vivo = try nuovo(cartella)
        try await esegui(vivo, .destina(unita: "orso", alFronte: false))
        let ripreso = try riprendi(cartella)
        let statoVivo = await vivo.stato
        let statoRipreso = await ripreso.stato
        XCTAssertEqual(statoRipreso.impronta(), statoVivo.impronta())
        XCTAssertEqual(statoRipreso.forze, statoVivo.forze)
        XCTAssertEqual(statoRipreso.anno, statoVivo.anno)
        XCTAssertEqual(statoRipreso.momento, statoVivo.momento)
        XCTAssertEqual(statoRipreso.campagna, statoVivo.campagna)
        for risorsa in Risorsa.allCases {
            XCTAssertEqual(statoRipreso.riserve[risorsa], statoVivo.riserve[risorsa])
            XCTAssertEqual(statoRipreso.entrataDellAnno[risorsa], statoVivo.entrataDellAnno[risorsa])
            XCTAssertEqual(statoRipreso.mantenimento[risorsa], statoVivo.mantenimento[risorsa])
        }
        XCTAssertTrue(statoRipreso.mantenimento.sonoVuote)
        XCTAssertTrue(statoRipreso.sciolti.isEmpty)
    }
}
