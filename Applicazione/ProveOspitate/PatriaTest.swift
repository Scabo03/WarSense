import XCTest
import Dati
import Motore
import Sessione
@testable import WarSense

/// La patria e l'anno del regno attraverso l'interfaccia (incarico 30, prima tappa): la schermata
/// com'è letta, l'inverno con il costo sulla riserva e l'impossibilità dichiarata, il fuoco che non
/// si muove dopo una spesa, l'annullamento, la primavera con le reclute, la campagna aperta dalla
/// patria che si conclude e torna con la sua dichiarazione, la ripresa dal giornale.
@MainActor
final class PatriaTest: XCTestCase {

    private var finestre: [UIWindow] = []

    override func tearDown() async throws {
        for f in finestre {
            var presentata = f.rootViewController?.presentedViewController
            var catena: [UIViewController] = []
            while let p = presentata { catena.append(p); presentata = p.presentedViewController }
            for p in catena.reversed() { p.dismiss(animated: false) }
            f.isHidden = true
            f.rootViewController = nil
        }
        finestre = []
        try await super.tearDown()
    }

    @discardableResult
    private func monta(_ schermata: UIViewController) -> UIWindow {
        let finestra = UIWindow(frame: CGRect(x: 0, y: 0, width: 420, height: 912))
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        finestra.layoutIfNeeded()
        finestre.append(finestra)
        return finestra
    }

    private func attendi(_ che: String = "", _ condizione: () -> Bool, giri: Int = 400,
                         file: StaticString = #filePath, line: UInt = #line) async throws {
        for _ in 0..<giri where !condizione() { try await Task.sleep(nanoseconds: 20_000_000) }
        XCTAssertTrue(condizione(), "attesa scaduta: \(che)", file: file, line: line)
    }

    /// Le etichette della schermata nell'ordine in cui la voce le percorre.
    private func lettura(_ schermata: UIViewController) -> [String] {
        schermata.view.layoutIfNeeded()
        return LettoreAccessibilita.ordineDiLettura(radice: schermata.view as Any)
            .map { LettoreAccessibilita.etichetta(di: $0) }
    }

    private func elemento(_ etichetta: String, in schermata: UIViewController,
                          file: StaticString = #filePath, line: UInt = #line) throws -> NSObject {
        try XCTUnwrap(LettoreAccessibilita.ordineDiLettura(radice: schermata.view as Any)
            .first { LettoreAccessibilita.etichetta(di: $0) == etichetta },
                      "manca «\(etichetta)» in \(lettura(schermata))", file: file, line: line)
    }

    private func premi(_ etichetta: String, in schermata: UIViewController,
                       file: StaticString = #filePath, line: UInt = #line) throws {
        let pulsante = try XCTUnwrap(try elemento(etichetta, in: schermata, file: file, line: line) as? UIControl,
                                     "«\(etichetta)» non è un comando", file: file, line: line)
        pulsante.sendActions(for: .touchUpInside)
    }

    /// Una patria nuova, montata e caricata.
    private func patria(_ ambiente: Ambiente? = nil) async throws -> (SchermataPatria, Ambiente) {
        let ambiente = try ambiente ?? Ambiente()
        let schermata = SchermataPatria(partita: try await PartitaRegno(nuovo: ambiente))
        monta(schermata)
        try await attendi("la patria si carica") { self.lettura(schermata).contains("Riserve") }
        return (schermata, ambiente)
    }

    /// L'ambiente con stagioni di una giornata sola. I valori si cambiano per la via che il gioco
    /// dà a chi li mette a punto — il file nella cartella Documenti (00 §15.4) —, non per un canale
    /// di prova; la cartella si rimuove a fine prova, e il prossimo avvio la ricopia dalla fabbrica.
    private func ambienteConStagioniDiUnaGiornata() throws -> Ambiente {
        _ = try Ambiente()
        let url = Ambiente.cartellaValori.appendingPathComponent("regno.json")
        var valori = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        valori["giornate_per_stagione"] = 1
        try JSONSerialization.data(withJSONObject: valori).write(to: url)
        addTeardownBlock { try? FileManager.default.removeItem(at: Ambiente.cartellaValori) }
        let ambiente = try Ambiente()
        XCTAssertEqual(ambiente.valoriRegno.giornatePerStagione, 1)
        XCTAssertFalse(ambiente.ripiegoSuFabbrica, "i valori modificati in Documenti si caricano")
        return ambiente
    }

    // MARK: - La patria com'è letta (00 §11.5, 02 §8.7.2)

    func test_01_5_6_10_la_patria_si_legge_in_ordine_data_riserve_forze_comandi() async throws {
        Fuoco.azzeraRegistro()
        let (schermata, _) = try await patria()
        XCTAssertEqual(lettura(schermata), [
            "Patria",
            "Anno 1, primavera",
            "Nessuna campagna aperta quest'anno",
            "Riserve",
            "monete di bronzo: 20", "uomini: 2", "metalli: 3", "materiale da costruzione: 3", "animali: 1",
            "Forze",
            "gruppo armato: 6 atomi di fanteria leggera",
            "gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante",
            "gruppo armato: 24 atomi di fanteria pesante, 12 atomi di cavalleria manovrata",
            "formazione di ricognizione: 3 atomi di fanteria leggera",
            "formazione non armata: 4 atomi di fanteria leggera",
            "Apri la campagna",
            "Attendi l'inverno",
            "Registro della patria",
            "Torna all'inizio",
        ])
        // Ogni elemento è agganciabile: dentro lo schermo, o dentro la colonna che scorre.
        let schermo = try XCTUnwrap(schermata.view.window).bounds
        for nodo in LettoreAccessibilita.ordineDiLettura(radice: schermata.view as Any) {
            XCTAssertNil(LettoreAccessibilita.motivoNonAgganciabile(nodo, schermo: schermo),
                         "«\(LettoreAccessibilita.etichetta(di: nodo))»")
        }
        // Il fuoco d'apertura va al titolo, alla comparsa.
        XCTAssertEqual(Fuoco.registro, [.schermataAperta])
        XCTAssertEqual(LettoreAccessibilita.etichetta(di: try XCTUnwrap(Fuoco.ultimoBersaglio as? NSObject)), "Patria")
        // Il tocco magico dà l'informazione di stato; il gesto di fuga risale.
        XCTAssertEqual(schermata.informazioneDiStatoPerProva(), "Anno 1, primavera. Nessuna campagna aperta quest'anno")
        var uscito = false
        schermata.alTermine = { uscito = true }
        XCTAssertTrue(schermata.accessibilityPerformEscape())
        XCTAssertTrue(uscito)
    }

    // MARK: - L'inverno (01 §5.9.1, 02 §8.7)

    func test_01_5_9_l_inverno_il_costo_sulla_riserva_la_spesa_e_il_fuoco_che_non_si_muove() async throws {
        let (schermata, ambiente) = try await patria()
        ambiente.segnali.azzeraAnnunciPronunciati()
        Fuoco.azzeraRegistro()
        try premi("Attendi l'inverno", in: schermata)
        try await attendi("arriva l'inverno") { self.lettura(schermata).contains("Anno 1, inverno, schermata 1 di 4") }
        XCTAssertEqual(lettura(schermata), [
            "Patria",
            "Anno 1, inverno, schermata 1 di 4",
            "Quest'anno nessuna campagna",
            "Riserve",
            "monete di bronzo: 220", "uomini: 26", "metalli: 33", "materiale da costruzione: 33", "animali: 13",
            "Forze",
            "gruppo armato: 6 atomi di fanteria leggera",
            "gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante",
            "gruppo armato: 24 atomi di fanteria pesante, 12 atomi di cavalleria manovrata",
            "formazione di ricognizione: 3 atomi di fanteria leggera",
            "formazione non armata: 4 atomi di fanteria leggera",
            "Lavori da ordinare",
            "Leva di fanteria leggera. Costa: monete di bronzo 30 su 220, uomini 6 su 26, metalli 3 su 33. 6 atomi, pronta in primavera.",
            "Leva di fanteria pesante. Costa: monete di bronzo 64 su 220, uomini 8 su 26, metalli 16 su 33. 8 atomi, pronta in primavera.",
            "Leva di cavalleria manovrata. Costa: monete di bronzo 72 su 220, uomini 6 su 26, metalli 6 su 33, animali 6 su 13. 6 atomi, pronta in primavera.",
            "Lavori ordinati",
            "Nessun lavoro ordinato in questo inverno",
            "Annulla l'ultima spesa",
            "Azzera le spese di questa schermata",
            "Prosegui alla schermata 2 di 4",
            "Registro della patria",
            "Torna all'inizio",
        ])
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo), [
            "Comincia l'inverno dell'anno 1. Entrate: monete di bronzo 200, uomini 24, metalli 30, "
            + "materiale da costruzione 30, animali 12."])
        // L'inverno è una schermata nuova: il fuoco va in testa, alla data.
        XCTAssertEqual(Fuoco.registro, [.schermataAperta])
        XCTAssertEqual(LettoreAccessibilita.etichetta(di: try XCTUnwrap(Fuoco.ultimoBersaglio as? NSObject)),
                       "Anno 1, inverno, schermata 1 di 4")

        // Una spesa: gli elementi restano gli stessi, si aggiornano sul posto, e il fuoco non si muove.
        let pesante = "Leva di fanteria pesante. Costa: monete di bronzo 64 su 220, uomini 8 su 26, metalli 16 su 33. 8 atomi, pronta in primavera."
        let pulsantePrima = try elemento(pesante, in: schermata)
        let riservaPrima = try elemento("metalli: 33", in: schermata)
        Fuoco.azzeraRegistro()
        ambiente.segnali.azzeraAnnunciPronunciati()
        try premi(pesante, in: schermata)
        try await attendi("la spesa si vede") { self.lettura(schermata).contains("metalli: 17") }
        XCTAssertEqual(Fuoco.registro, [], "aggiornato un valore in una schermata di gestione, il fuoco non si muove (00 §11.3)")
        XCTAssertTrue(try elemento("metalli: 17", in: schermata) === riservaPrima, "l'elemento è lo stesso, aggiornato sul posto")
        let pesanteDopo = "Leva di fanteria pesante. Costa: monete di bronzo 64 su 156, uomini 8 su 18, metalli 16 su 17. 8 atomi, pronta in primavera."
        XCTAssertTrue(try elemento(pesanteDopo, in: schermata) === pulsantePrima)
        XCTAssertTrue(lettura(schermata).contains("Leva di fanteria pesante, pronta in primavera"))
        XCTAssertFalse(lettura(schermata).contains("Nessun lavoro ordinato in questo inverno"))
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo),
                       ["Leva di fanteria pesante ordinata: pronta in primavera."])

        // Una seconda leva pesante: poi i metalli non bastano più, e la voce lo dice prontamente.
        try premi(pesanteDopo, in: schermata)
        try await attendi("la seconda spesa si vede") { self.lettura(schermata).contains("metalli: 1") }
        let impedita = "Leva di fanteria pesante. Non si può ordinare: mancano metalli. "
            + "Costa: monete di bronzo 64 su 92, uomini 8 su 10, metalli 16 su 1. 8 atomi, pronta in primavera."
        XCTAssertTrue(lettura(schermata).contains(impedita), "\(lettura(schermata))")
        ambiente.segnali.azzeraAnnunciPronunciati()
        try premi(impedita, in: schermata)
        try await attendi("il rifiuto si annuncia") { !ambiente.segnali.annunciPronunciati.isEmpty }
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo), ["Non si può ordinare: mancano metalli."])
        XCTAssertTrue(lettura(schermata).contains("metalli: 1"), "un comando respinto non cambia nulla")

        // L'annullamento ritira l'ultima spesa; l'azzeramento tutte quelle della schermata.
        ambiente.segnali.azzeraAnnunciPronunciati()
        try premi("Annulla l'ultima spesa", in: schermata)
        try await attendi("l'annullamento si vede") { self.lettura(schermata).contains("metalli: 17") }
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo),
                       ["Leva di fanteria pesante: ordine annullato, risorse restituite."])
        ambiente.segnali.azzeraAnnunciPronunciati()
        try premi("Azzera le spese di questa schermata", in: schermata)
        try await attendi("l'azzeramento si vede") { self.lettura(schermata).contains("metalli: 33") }
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo), ["Spese della schermata azzerate: 1 ordine ritirato"])
        XCTAssertTrue(lettura(schermata).contains("Nessun lavoro ordinato in questo inverno"))
        ambiente.segnali.azzeraAnnunciPronunciati()
        try premi("Annulla l'ultima spesa", in: schermata)
        try await attendi("il vuoto si dichiara") { !ambiente.segnali.annunciPronunciati.isEmpty }
        try premi("Azzera le spese di questa schermata", in: schermata)
        try await attendi("il vuoto si dichiara") { ambiente.segnali.annunciPronunciati.count == 2 }
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo),
                       ["Nessuna spesa da annullare in questa schermata", "Nessuna spesa da azzerare in questa schermata"])
        XCTAssertEqual(Fuoco.registro, [], "né la spesa né l'annullamento spostano il fuoco")
    }

    func test_01_5_9_1_le_quattro_schermate_e_la_primavera_con_le_reclute() async throws {
        let (schermata, ambiente) = try await patria()
        try premi("Attendi l'inverno", in: schermata)
        try await attendi("arriva l'inverno") { self.lettura(schermata).contains("Prosegui alla schermata 2 di 4") }
        try premi("Leva di fanteria leggera. Costa: monete di bronzo 30 su 220, uomini 6 su 26, metalli 3 su 33. 6 atomi, pronta in primavera.", in: schermata)
        try await attendi("la leva si vede") { self.lettura(schermata).contains("uomini: 20") }
        let vociDellaPrima = lettura(schermata).filter { $0.hasPrefix("Leva di") && $0.contains("Costa:") }

        for stazione in 2...4 {
            ambiente.segnali.azzeraAnnunciPronunciati()
            Fuoco.azzeraRegistro()
            try premi("Prosegui alla schermata \(stazione) di 4", in: schermata)
            try await attendi("si apre la schermata \(stazione)") {
                self.lettura(schermata).contains("Anno 1, inverno, schermata \(stazione) di 4")
            }
            XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo), ["Inverno, schermata \(stazione) di 4"])
            // La struttura non cambia da una schermata all'altra (01 §5.9.1.3): le stesse voci, tutte.
            XCTAssertEqual(lettura(schermata).filter { $0.hasPrefix("Leva di") && $0.contains("Costa:") }, vociDellaPrima)
            XCTAssertTrue(lettura(schermata).contains("Leva di fanteria leggera, pronta in primavera"),
                          "il lavoro ordinato resta in elenco per tutto l'inverno")
            // Il fuoco: la schermata è la stessa finché il momento dell'anno non cambia.
            XCTAssertEqual(Fuoco.registro, [])
        }
        XCTAssertTrue(lettura(schermata).contains("Prosegui alla primavera"))

        ambiente.segnali.azzeraAnnunciPronunciati()
        Fuoco.azzeraRegistro()
        try premi("Prosegui alla primavera", in: schermata)
        try await attendi("comincia la primavera") { self.lettura(schermata).contains("Anno 2, primavera") }
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo), [
            "Comincia la primavera dell'anno 2. Il riporto ha tolto: monete di bronzo 170, uomini 18, metalli 27, "
            + "materiale da costruzione 30, animali 12. Leva di fanteria leggera: è pronta."])
        let letta = lettura(schermata)
        XCTAssertTrue(letta.contains("monete di bronzo: 20"), "avanza un decimo dell'entrata dell'anno (01 §5.5.1.4): \(letta)")
        XCTAssertTrue(letta.contains("uomini: 2"))
        XCTAssertEqual(letta.filter { $0.hasPrefix("gruppo armato") }.last, "gruppo armato: 6 atomi di fanteria leggera",
                       "le reclute sono una formazione nuova, in coda")
        XCTAssertEqual(letta.filter { $0.hasPrefix("gruppo armato") }.count, 4)
        XCTAssertTrue(letta.contains("Apri la campagna"))
        XCTAssertEqual(Fuoco.registro, [.schermataAperta], "la primavera è una schermata nuova")

        // Il registro della patria: i fatti che il giocatore non ha deciso, dal più recente.
        try premi("Registro della patria", in: schermata)
        let registro = try XCTUnwrap(schermata.presentedViewController as? SchermataRegistro)
        registro.loadViewIfNeeded()
        XCTAssertEqual(lettura(registro), [
            "Registro della patria",
            "Anno 2, primavera: Leva di fanteria leggera è pronta",
            "Anno 2, primavera: comincia la primavera; il riporto ha tolto ciò che eccedeva",
            "Anno 1, inverno: comincia l'inverno e arriva l'entrata dell'anno",
            "Chiudi il registro",
        ])
    }

    // MARK: - La campagna aperta dalla patria (RDA-162, RDA-164)

    func test_la_campagna_si_apre_dalla_patria_dichiara_la_stagione_e_torna_in_patria() async throws {
        let (schermata, ambiente) = try await patria()
        try premi("Apri la campagna", in: schermata)
        try await attendi("si apre la scelta del fronte") { schermata.presentedViewController is UIAlertController }
        let pannello = try XCTUnwrap(schermata.presentedViewController as? UIAlertController)
        XCTAssertEqual(pannello.title, "Su quale fronte?")
        XCTAssertEqual(pannello.actions.map(\.title), [
            "fronte del guado, mappa 4 per 4", "fronte dell'istmo, mappa 6 per 6",
            "fronte della pianura lunga, mappa 10 per 10", "Chiudi il pannello"])
        pannello.dismiss(animated: false)
        try await attendi("il pannello si chiude") { schermata.presentedViewController == nil }

        ambiente.segnali.azzeraAnnunciPronunciati()
        await schermata.apriLaCampagnaPerProva(sul: "istmo")
        try await attendi("si entra nel fronte") { schermata.presentedViewController is SchermataMappaCampagna }
        let mappa = try XCTUnwrap(schermata.presentedViewController as? SchermataMappaCampagna)
        try await attendi("la mappa si carica") { !mappa.elementiPerProva.isEmpty }
        let stato = try XCTUnwrap(mappa.statoPerProva)
        XCTAssertEqual(stato.calendario, CalendarioDiCampagna(anno: 1, giornatePerStagione: 30))
        XCTAssertEqual(stato.gruppi(di: .giocatore).count, 5, "partono tutte le formazioni del regno")
        XCTAssertTrue(ambiente.segnali.annunciPronunciati.map(\.testo).contains("Campagna aperta sul fronte dell'istmo"))
        // Il comando d'uscita dice dove porta, e l'informazione di stato dichiara la data.
        XCTAssertTrue(lettura(mappa).contains("Torna in patria"))
        XCTAssertFalse(lettura(mappa).contains("Torna all'inizio"))
        ambiente.segnali.azzeraAnnunciPronunciati()
        XCTAssertTrue(mappa.accessibilityPerformMagicTap())
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.last?.testo,
                       "Anno 1, primavera, mancano 89 giornate all'inverno. Giorno 1. Nessun gruppo ha ancora agito, sono 5")

        // Una giornata, poi il ritorno in patria: la data è quella del fronte.
        mappa.chiudiGiornataPerProva()
        try await attendi("la giornata si chiude") { mappa.statoPerProva?.giorno == 2 }
        mappa.dismiss(animated: false)
        await schermata.tornatoDalFrontePerProva()
        let letta = lettura(schermata)
        XCTAssertTrue(letta.contains("Anno 1, primavera, giorno 2 di 90"), "\(letta)")
        XCTAssertTrue(letta.contains("Campagna aperta sul fronte dell'istmo"))
        XCTAssertTrue(letta.contains("Entra nel fronte dell'istmo"))
        XCTAssertFalse(letta.contains("Apri la campagna"))
        XCTAssertFalse(letta.contains("Attendi l'inverno"), "l'inverno non arriva finché la campagna dura")

        // La ripresa dal giornale: il regno dichiara la campagna aperta e la ritrova allo stesso giorno.
        let ripresa = SchermataPatria(partita: try await PartitaRegno(riprendi: ambiente))
        monta(ripresa)
        try await attendi("la patria ripresa si carica") { self.lettura(ripresa).contains("Entra nel fronte dell'istmo") }
        XCTAssertTrue(lettura(ripresa).contains("Anno 1, primavera, giorno 2 di 90"))
        let giornoRipreso = await ripresa.campagnaPerProva?.stato.giorno
        XCTAssertEqual(giornoRipreso, 2)
    }

    func test_la_campagna_che_l_inverno_conclude_torna_con_la_dichiarazione_e_il_bilancio_ne_nasce() async throws {
        let ambiente = try ambienteConStagioniDiUnaGiornata()
        let (schermata, _) = try await patria(ambiente)
        await schermata.apriLaCampagnaPerProva(sul: "pianura_lunga")
        try await attendi("si entra nel fronte") { schermata.presentedViewController is SchermataMappaCampagna }
        let mappa = try XCTUnwrap(schermata.presentedViewController as? SchermataMappaCampagna)
        try await attendi("la mappa si carica") { !mappa.elementiPerProva.isEmpty }
        XCTAssertEqual(mappa.statoPerProva?.calendario?.ultimaGiornata, 3)

        ambiente.segnali.azzeraAnnunciPronunciati()
        for giorno in 1...3 {
            mappa.chiudiGiornataPerProva()
            try await attendi("si chiude la giornata \(giorno)") {
                giorno < 3 ? mappa.statoPerProva?.giorno == giorno + 1 : mappa.statoPerProva?.conclusione != nil
            }
        }
        XCTAssertEqual(mappa.statoPerProva?.conclusione, ConclusioneCampagna(modo: .inverno, vincitore: nil, giorno: 3))
        let annunci = ambiente.segnali.annunciPronunciati.map(\.testo)
        XCTAssertTrue(annunci.contains("Nuova stagione: estate"), "\(annunci)")
        XCTAssertTrue(annunci.contains("Nuova stagione: autunno"))
        XCTAssertTrue(annunci.contains("È arrivato l'inverno: la campagna è conclusa, senza vincitore"))

        // La mappa si chiude da sé e la patria mostra la dichiarazione di conclusione (05 §9.3).
        try await attendi("compare la dichiarazione di conclusione") { schermata.presentedViewController is SchermataResoconto }
        let dichiarazione = try XCTUnwrap(schermata.presentedViewController as? SchermataResoconto)
        dichiarazione.loadViewIfNeeded()
        XCTAssertEqual(lettura(dichiarazione), [
            "Campagna conclusa",
            "L'inverno ha interrotto la campagna sul fronte della pianura lunga: nessun vincitore",
            "Durata: 3 giornate",
            "Battaglie vinte: 0. Battaglie perse: 0",
            "Rientrano in patria: 5 formazioni",
            "Nessun premio: quest'inverno arriva la sola rendita",
            "Torna in patria",
        ])
        // Lo slot della campagna ha esaurito il suo compito: l'esito vive nel giornale del regno.
        XCTAssertFalse(FileManager.default.fileExists(atPath: PartitaRegno.cartellaCampagna.path))

        Fuoco.azzeraRegistro()
        dichiarazione.chiudiTuttoPerProva()
        try await attendi("si torna in patria") { schermata.presentedViewController == nil }
        let letta = lettura(schermata)
        XCTAssertTrue(letta.contains("Anno 1, autunno"), "\(letta)")
        XCTAssertTrue(letta.contains("Campagna sul fronte della pianura lunga interrotta dall'inverno, senza vincitore"))
        XCTAssertTrue(letta.contains("Attendi l'inverno"))
        XCTAssertFalse(letta.contains("Apri la campagna"), "la campagna dell'anno è già stata condotta")
        try await attendi("il fuoco torna in testa") { Fuoco.registro == [.schermataAperta] }

        // L'inverno: il bilancio nasce dall'esito — qui, senza vittorie, la sola rendita.
        try premi("Attendi l'inverno", in: schermata)
        try await attendi("arriva l'inverno") { self.lettura(schermata).contains("Anno 1, inverno, schermata 1 di 4") }
        XCTAssertTrue(lettura(schermata).contains("monete di bronzo: 220"))
        try premi("Registro della patria", in: schermata)
        let registro = try XCTUnwrap(schermata.presentedViewController as? SchermataRegistro)
        registro.loadViewIfNeeded()
        XCTAssertEqual(Array(lettura(registro).dropFirst().prefix(2)), [
            "Anno 1, inverno: comincia l'inverno e arriva l'entrata dell'anno",
            "Anno 1, autunno: campagna sul fronte della pianura lunga interrotta dall'inverno",
        ])
    }

    func test_la_campagna_conclusa_a_gioco_chiuso_porta_l_esito_in_patria_alla_ripresa() async throws {
        let ambiente = try ambienteConStagioniDiUnaGiornata()
        let regno = try await PartitaRegno(nuovo: ambiente)
        let aperta = try await regno.apriCampagna(fronte: "pianura_lunga")
        let campagna = try XCTUnwrap(aperta.campagna)
        for _ in 1...3 { try await campagna.chiudiGiornata() }
        let conclusa = await campagna.stato.conclusione
        XCTAssertNotNil(conclusa)
        // Il gioco si chiude qui: la campagna è conclusa nel suo giornale, l'esito non è in patria.
        let statoPrima = await regno.stato
        XCTAssertEqual(statoPrima.campagna.fronteAperto, "pianura_lunga")

        let ripresa = SchermataPatria(partita: try await PartitaRegno(riprendi: ambiente))
        monta(ripresa)
        try await attendi("alla ripresa compare la dichiarazione") { ripresa.presentedViewController is SchermataResoconto }
        let statoDopo = await ripresa.partitaPerProva.stato
        XCTAssertEqual(statoDopo.campagna.esito?.modo, .inverno)
        XCTAssertFalse(FileManager.default.fileExists(atPath: PartitaRegno.cartellaCampagna.path))
    }

    // MARK: - L'avvio

    func test_l_avvio_offre_il_regno_in_testa_e_la_ripresa_quando_ce_n_e_uno() async throws {
        try? FileManager.default.removeItem(at: PartitaRegno.cartellaRegno)
        let ambiente = try Ambiente()
        let avvio = SchermataAvvio(ambiente: ambiente)
        monta(avvio)
        avvio.viewWillAppear(false)
        let senza = lettura(avvio)
        XCTAssertEqual(Array(senza.prefix(2)), ["WarSense", "Nuovo regno"])
        XCTAssertFalse(senza.contains("Riprendi il regno"))
        XCTAssertTrue(senza.contains("Nuova campagna, mappa piccola"), "le campagne di prova restano")

        _ = try await PartitaRegno(nuovo: ambiente)
        avvio.viewWillAppear(false)
        XCTAssertEqual(Array(lettura(avvio).prefix(3)), ["WarSense", "Riprendi il regno", "Nuovo regno"])

        try premi("Riprendi il regno", in: avvio)
        try await attendi("si apre la patria") { avvio.presentedViewController is SchermataPatria }
    }
}
