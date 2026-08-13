import XCTest
import Dati
import Motore
import Sessione
@testable import WarSense

/// La prova d'interfaccia del PASSAGGIO fra i due piani (incarico 24), che apre la campagna
/// COME LA APRE IL GIOCATORE (`PartitaCampagna(nuova:taglia:)`, lo stesso inizializzatore dei
/// pulsanti di `SchermateContorno`), legge la schermata VERA (`SchermataMappaCampagna`), porta
/// due gruppi armati a contatto, apre la battaglia dal comando della casella, la combatte fino
/// alla conclusione e verifica sulla schermata di campagna che le forze tornino con l'esito
/// giusto. Percorre i medesimi metodi del coordinatore che la schermata invoca
/// (`apriBattaglia`, `concludiBattaglia`), mentre il combattimento è guidato da un tattico
/// deterministico, come al banco (`BancoSessioniBattaglia`): una battaglia tattica non si guida
/// cella per cella da una prova ospitata, ma l'apertura e il ritorno passano dall'interfaccia.
///
/// FALLISCE sul codice privo del passaggio (nessuna battaglia in sospeso si innesca, il pannello
/// non offre l'apertura, l'esito non torna) e passa una volta costruito il passaggio.
@MainActor
final class PassaggioBattagliaInterfacciaTest: XCTestCase {

    private static let schermo = CGRect(x: 0, y: 0, width: 375, height: 667)

    private func mappaAperta(taglia: PartitaCampagna.Taglia) async throws
        -> (SchermataMappaCampagna, Ambiente) {
        let ambiente = try Ambiente()
        let partita = try await PartitaCampagna(nuova: ambiente, taglia: taglia)
        let schermata = SchermataMappaCampagna(partita: partita)
        let finestra = UIWindow(frame: Self.schermo)
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        for _ in 0..<200 where schermata.elementiPerProva.isEmpty {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        addTeardownBlock { @MainActor in
            schermata.presentedViewController?.dismiss(animated: false)
            finestra.isHidden = true
            finestra.rootViewController = nil
        }
        return (schermata, ambiente)
    }

    // MARK: - La prova intera: mappa → battaglia → mappa

    func test_incarico_24_dalla_mappa_alla_battaglia_e_ritorno() async throws {
        let (schermata, ambiente) = try await mappaAperta(taglia: .piccola)

        // (1) Due gruppi armati a contatto innescano una battaglia in sospeso.
        let battaglia = try await portaAContatto(schermata)
        let statoContatto = try XCTUnwrap(schermata.statoPerProva)
        XCTAssertTrue(statoContatto.battaglieInSospeso.contains { $0.identificatore == battaglia.identificatore },
                      "un contatto armato ha innescato una battaglia in sospeso sulla schermata vera")

        // (2) Il BLOCCO: ogni comando di campagna è respinto col medesimo motivo (01 §6.4).
        let armato = try XCTUnwrap(statoContatto.gruppi(di: .giocatore).first { $0.categoria.eArmata })
        let esitoBloccato = await schermata.partitaPerProva.anteprima(.presidio(gruppo: armato.id))
        XCTAssertEqual(esitoBloccato.motivo, .battagliaInSospeso,
                       "con una battaglia in sospeso ogni comando è respinto col motivo battaglia_in_sospeso")

        // L'informazione di stato della campagna dichiara la battaglia in sospeso COL LUOGO (02 §6.5).
        let costruttore = CostruttoreAnnunciCampagna(testi: ambiente.testi, motore: schermata.motorePerProva,
                                                     stato: statoContatto, verbosita: .normale)
        let statoDichiarato = costruttore.informazioneDiStato()
        XCTAssertTrue(statoDichiarato.contains("attaglia in sospeso")
                      && statoDichiarato.contains("riga \(battaglia.casella.riga)"),
                      "l'informazione di stato dichiara la battaglia in sospeso col luogo: «\(statoDichiarato)»")

        // (3) Il pannello della casella contesa offre «Apri la battaglia» (01 §6.2).
        let apri = ambiente.testi.frase("pannello.apri_battaglia").testo
        XCTAssertTrue(schermata.attiva(battaglia.casella))
        try await Task.sleep(nanoseconds: 120_000_000)
        XCTAssertTrue(schermata.vociPannelloPerProva.map(\.titolo).contains(apri),
                      "il pannello della casella con la battaglia in sospeso offre l'apertura")
        schermata.presentedViewController?.dismiss(animated: false)
        try await Task.sleep(nanoseconds: 80_000_000)

        // Somma degli atomi delle due parti PRIMA della battaglia: nessuna forza si crea nel passaggio.
        let atomiPrima = atomiTotali(statoContatto)

        // (4) Apri la battaglia (lo stesso metodo del coordinatore che la schermata invoca) e
        //     combattila fino alla conclusione.
        let partitaBattaglia = try await schermata.partitaPerProva.apriBattaglia(battaglia)
        let statoFinale = try await combattiAConclusione(partitaBattaglia, ambiente: ambiente)
        let esito = try XCTUnwrap(statoFinale.esito, "la battaglia si è conclusa con un esito")

        // (5) Il RITORNO: l'esito torna in campagna, sulla schermata vera.
        let esitoRitorno = await schermata.partitaPerProva.esitoDiRitorno(battaglia, statoBattaglia: statoFinale)
        try await schermata.partitaPerProva.concludiBattaglia(battaglia, esito: esitoRitorno)
        await schermata.ricaricaStatoPerProva()
        let statoRitorno = try XCTUnwrap(schermata.statoPerProva)

        XCTAssertTrue(statoRitorno.battaglieInSospeso.isEmpty,
                      "l'esito ha consumato la battaglia in sospeso e sbloccato la campagna (01 §15.8)")

        let vincitore = esito.sconfitto.avversaria
        let idVincitore = battaglia.gruppo(di: vincitore)
        let idSconfitto = battaglia.gruppo(di: esito.sconfitto)

        // Il vincitore resta nella casella contesa (01 §15.5).
        let gruppoVincitore = try XCTUnwrap(statoRitorno.gruppi[idVincitore],
                                            "il vincitore sopravvive e torna sulla mappa")
        XCTAssertEqual(gruppoVincitore.posizione, battaglia.casella,
                       "il vincitore occupa la casella contesa (01 §15.5)")

        // Lo sconfitto: annientato sparisce, altrimenti sopravvive RIDOTTO e arretrato (01 §15.2.3, §10.6).
        if let gruppoSconfitto = statoRitorno.gruppi[idSconfitto] {
            XCTAssertNotEqual(gruppoSconfitto.posizione, battaglia.casella,
                              "lo sconfitto che ripiega arretra dalla casella contesa (01 §10.6)")
        } else {
            // Annientato: correttamente sparito dalla mappa. Nulla da verificare oltre.
        }

        // Nessuna forza si crea nel passaggio: gli atomi al ritorno non superano quelli di prima.
        let atomiDopo = atomiTotali(statoRitorno)
        XCTAssertLessThanOrEqual(atomiDopo, atomiPrima,
                                 "nessuna forza si crea nel passaggio fra i due piani (conservazione)")

        // L'esito è nel registro, così che chi riapre la campagna sappia com'è andata (01 §15.3).
        XCTAssertTrue(statoRitorno.registro.contains {
            if case .battagliaConclusa(let c, _) = $0.fatto { return c == battaglia.casella }
            return false
        }, "la conclusione della battaglia è annotata nel registro col luogo")
    }

    // MARK: - Spegni e riapri: i due giornali si toccano e l'esito sopravvive al riavvio

    func test_incarico_24_l_esito_torna_in_campagna_dopo_un_riavvio() async throws {
        let (schermata, ambiente) = try await mappaAperta(taglia: .piccola)
        let battaglia = try await portaAContatto(schermata)

        // «Spegni» a battaglia appena aperta: la si riprende dallo slot su disco, identica. È il
        // punto in cui i due giornali si toccano: la battaglia vive nel proprio slot.
        var apertura: PartitaCorrente? = try await schermata.partitaPerProva.apriBattaglia(battaglia)
        let improntaApertura = await apertura!.stato.impronta()
        apertura = nil // rilascia la Sessione (chiude il giornale): come se l'applicazione chiudesse
        let ripresaBattaglia = try await schermata.partitaPerProva.apriBattaglia(battaglia)
        let statoRipreso = await ripresaBattaglia.stato
        XCTAssertEqual(statoRipreso.impronta(), improntaApertura,
                       "la battaglia nata dalla campagna si riprende identica dallo slot (05 §6.3)")

        // Combatti a conclusione e riporta l'esito in campagna.
        let statoFinale = try await combattiAConclusione(ripresaBattaglia, ambiente: ambiente)
        let esito = try XCTUnwrap(statoFinale.esito)
        let esitoRitorno = await schermata.partitaPerProva.esitoDiRitorno(battaglia, statoBattaglia: statoFinale)
        try await schermata.partitaPerProva.concludiBattaglia(battaglia, esito: esitoRitorno)

        // «Riapri» la campagna dallo slot su disco: l'esito è tornato, e resta dopo il riavvio —
        // la campagna lo rigioca dal giornale senza rileggere i file della battaglia (05 §6.1).
        let ripresaCampagna = try await PartitaCampagna(riprendi: ambiente)
        let statoCampagna = await ripresaCampagna.stato
        XCTAssertTrue(statoCampagna.battaglieInSospeso.isEmpty,
                      "dopo il riavvio la battaglia non è più in sospeso: la campagna è ripresa (01 §15.8)")
        XCTAssertTrue(statoCampagna.registro.contains {
            if case .battagliaConclusa(let c, _) = $0.fatto { return c == battaglia.casella }
            return false
        }, "l'esito della battaglia è nel registro anche dopo il riavvio")
        let idVincitore = battaglia.gruppo(di: esito.sconfitto.avversaria)
        XCTAssertEqual(statoCampagna.gruppi[idVincitore]?.posizione, battaglia.casella,
                       "il vincitore è nella casella contesa anche dopo il riavvio (01 §15.5)")
    }

    // MARK: - Incarico 25: la campagna prosegue oltre il ritorno dalla battaglia

    func test_incarico_25_la_campagna_prosegue_due_giornate_oltre_il_ritorno() async throws {
        let (schermata, ambiente) = try await mappaAperta(taglia: .piccola)
        let battaglia = try await portaAContatto(schermata)

        // Apre e combatte la battaglia attraverso la CATENA VERA dello schermo — il comando della
        // casella, la schermata di battaglia, il resoconto e il suo congedo — non i metodi del
        // coordinatore: è nella catena dello schermo che il difetto del titolare vive.
        try await apriCombattiEtornaDalloSchermo(schermata, battaglia: battaglia, ambiente: ambiente)

        let dopoRitorno = try XCTUnwrap(schermata.statoPerProva)
        XCTAssertTrue(dopoRitorno.battaglieInSospeso.isEmpty,
                      "tornato dalla battaglia dallo schermo, l'esito è piegato e nessuna battaglia resta in sospeso")
        // IL GRUPPO CHE HA COMBATTUTO HA SPESO LA GIORNATA (la regola del titolare, 01 §5.6.0.5):
        // il superstite di una battaglia — di qualunque parte — deve risultare AGITO, non in attesa.
        // Sul codice della build 26 risulta NON agito, ed è la causa vera del blocco.
        for id in [battaglia.gruppoGiocatore, battaglia.gruppoAvversario] {
            if let combattente = dopoRitorno.gruppi[id] {
                XCTAssertTrue(combattente.azioneSpesa,
                    "il gruppo \(id) reduce dalla battaglia deve aver SPESO la giornata combattendo (01 §5.6.0.5): "
                    + "è la regola che impedisce il blocco del titolare")
            }
        }
        let giornoRitorno = dopoRitorno.giorno

        // Prosegue per DUE giornate intere, ordinando ogni gruppo in attesa e vedendo la giornata
        // chiudersi. È lo spazio oltre il ritorno in cui il difetto del titolare vive.
        try await proseguiGiornate(schermata, quante: 2)

        let finale = try XCTUnwrap(schermata.statoPerProva)
        XCTAssertGreaterThanOrEqual(finale.giorno, giornoRitorno + 2,
            "dopo il ritorno la campagna prosegue almeno due giornate: giorno \(giornoRitorno) → \(finale.giorno)")
    }

    /// Apre la battaglia dal comando della casella, la combatte a conclusione guidando la
    /// `PartitaCorrente` della schermata di battaglia PRESENTATA (i suoi eventi la raggiungono e ne
    /// fanno comparire il resoconto), poi congeda il resoconto come il pulsante «torna» — la stessa
    /// catena `alTermine` del gioco, che riporta l'esito in campagna (incarico 25).
    private func apriCombattiEtornaDalloSchermo(_ schermata: SchermataMappaCampagna,
                                                battaglia: BattagliaInSospeso, ambiente: Ambiente) async throws {
        XCTAssertTrue(schermata.attiva(battaglia.casella))
        try await Task.sleep(nanoseconds: 150_000_000)
        let apri = ambiente.testi.frase("pannello.apri_battaglia").testo
        let voce = try XCTUnwrap(schermata.vociPannelloPerProva.first { $0.titolo == apri },
                                 "il pannello della casella offre «Apri la battaglia»")
        voce.esegui()

        var trovata: SchermataBattaglia?
        for _ in 0..<300 {
            if let b = schermata.presentedViewController as? SchermataBattaglia { trovata = b; break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        let battleScreen = try XCTUnwrap(trovata, "la schermata di battaglia è stata presentata dal comando")
        for _ in 0..<200 where battleScreen.elementiPerProva.isEmpty {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        _ = try await combattiAConclusione(battleScreen.partitaPerProva, ambiente: ambiente)

        var resoconto: SchermataResoconto?
        for _ in 0..<300 {
            if let r = battleScreen.presentedViewController as? SchermataResoconto { resoconto = r; break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        try XCTUnwrap(resoconto, "il resoconto di fine battaglia è stato presentato").chiudiTuttoPerProva()

        // Attende che la mappa torni in primo piano e che l'esito sia piegato (la catena alTermine).
        for _ in 0..<300 where schermata.presentedViewController != nil
            || schermata.statoPerProva?.battaglieInSospeso.isEmpty == false {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        await schermata.ricaricaStatoPerProva()
    }

    /// Ordina ogni gruppo del giocatore in attesa e lascia chiudere la giornata, `quante` volte.
    /// Sorveglia LUNGO IL CAMMINO che nessun gruppo in attesa sia privo di ogni azione (il blocco).
    private func proseguiGiornate(_ schermata: SchermataMappaCampagna, quante: Int) async throws {
        let motore = schermata.motorePerProva
        func haQualcheAzione(_ g: Gruppo, _ s: StatoCampagna) -> Bool {
            let comandi: [ComandoCampagna] = [.presidio(gruppo: g.id), .sostaConRaccolta(gruppo: g.id)]
                + s.griglia.vicini(di: g.posizione).map {
                    .marcia(gruppo: g.id, a: $0, giorni: motore.costoInGiorni(da: g.posizione, a: $0, stato: s))
                }
            return comandi.contains { motore.valida($0, parte: .giocatore, stato: s).eValido }
        }
        let presidioTitolo = schermata.partitaPerProva.ambiente.testi.frase("pannello.presidio").testo
        for _ in 0..<quante {
            let giorno = schermata.statoPerProva?.giorno ?? 0
            var protezione = 0
            while schermata.statoPerProva?.giorno == giorno && protezione < 80 {
                protezione += 1
                guard let s = schermata.statoPerProva else { break }
                for g in s.gruppiInAttesa(di: .giocatore) {
                    XCTAssertTrue(haQualcheAzione(g, s),
                        "gruppo \(g.id) in attesa nel giorno \(s.giorno) senza ALCUNA azione disponibile: blocco irreversibile")
                }
                guard let g = s.gruppiInAttesa(di: .giocatore).first else { break } // giornata chiusa
                // Ordina ATTRAVERSO IL PANNELLO della casella, non con l'esecuzione diretta: è nel
                // pannello — ciò che il giocatore tocca — che un gruppo può risultare non ordinabile.
                XCTAssertTrue(schermata.attiva(g.posizione),
                              "la casella del gruppo \(g.id) in riga \(g.posizione.riga) si attiva")
                try? await Task.sleep(nanoseconds: 60_000_000)
                let titoli = schermata.vociPannelloPerProva.map(\.titolo)
                XCTAssertFalse(titoli.isEmpty,
                    "il pannello del gruppo \(g.id) reduce dalla battaglia deve offrire almeno un'azione: blocco")
                let voce = try XCTUnwrap(
                    schermata.vociPannelloPerProva.first { $0.titolo == presidioTitolo }
                        ?? schermata.vociPannelloPerProva.first { $0.stile == .default },
                    "il pannello del gruppo \(g.id) offre un ordine (presidio o altro): «\(titoli)»")
                voce.esegui()
                for _ in 0..<50 where schermata.statoPerProva?.gruppi[g.id]?.haConclusoLaGiornata == false
                    && schermata.statoPerProva?.giorno == giorno {
                    try? await Task.sleep(nanoseconds: 20_000_000)
                }
            }
            XCTAssertLessThan(protezione, 80,
                "la giornata \(giorno) non si è chiusa: la campagna è bloccata dopo il ritorno dalla battaglia")
        }
    }

    // MARK: - Attrezzi

    private func atomiTotali(_ stato: StatoCampagna) -> Int {
        stato.gruppi.values.reduce(0) { $0 + $1.atomiTotali }
    }

    /// Porta un gruppo armato del giocatore a contatto con un gruppo armato avversario,
    /// marciando ogni giornata verso la posizione REALE dell'avversario più vicino (la prova ha
    /// pieno accesso allo stato: naviga sui fatti, mentre il gioco applica le sue regole). Quando
    /// un armato avversario è adiacente, vi marcia sopra: la compresenza alla risoluzione innesca
    /// la battaglia (01 §6.1). Deterministico: la campagna non estrae mai il caso (RDA-43).
    private func portaAContatto(_ schermata: SchermataMappaCampagna, maxGiorni: Int = 60) async throws
        -> BattagliaInSospeso {
        func dist(_ a: Cella, _ b: Cella) -> Int { abs(a.riga - b.riga) + abs(a.colonna - b.colonna) }
        let motore = schermata.motorePerProva
        for _ in 0..<maxGiorni {
            let stato = try XCTUnwrap(schermata.statoPerProva)
            if let b = stato.battaglieInSospeso.first { return b }
            let giorno = stato.giorno
            let avversari = stato.gruppi(di: .avversario).filter { $0.categoria.eArmata }
            guard !avversari.isEmpty else { XCTFail("lo scenario non schiera un armato avversario"); break }
            // OGNI gruppo in attesa riceve un ordine, o la giornata non si chiuderebbe mai
            // (01 §5.6.0.6): gli armati marciano verso l'avversario più vicino — sopra di esso se
            // adiacente, per il contatto —, gli altri presidiano. Uno per volta finché la giornata
            // si chiude o si innesca una battaglia.
            var protezione = 0
            while schermata.statoPerProva?.giorno == giorno && protezione < 60 {
                protezione += 1
                guard let s = schermata.statoPerProva else { break }
                if !s.battaglieInSospeso.isEmpty { break }
                guard let gruppo = s.gruppiInAttesa(di: .giocatore).first else { break } // giornata chiusa
                if gruppo.categoria.eArmata,
                   let bersaglio = avversari.min(by: {
                       dist(gruppo.posizione, $0.posizione) < dist(gruppo.posizione, $1.posizione) }) {
                    let vista = VistaCampagna(motore: motore, stato: s, parte: .giocatore)
                    let destinazioni = vista.destinazioniValide(per: gruppo.id)
                    let meta = destinazioni.first { $0 == bersaglio.posizione }
                        ?? destinazioni.min(by: { dist($0, bersaglio.posizione) < dist($1, bersaglio.posizione) })
                    if let meta {
                        let costo = motore.costoInGiorni(da: gruppo.posizione, a: meta, stato: s)
                        await schermata.eseguiPerProva(.marcia(gruppo: gruppo.id, a: meta, giorni: costo))
                    } else {
                        await schermata.eseguiPerProva(.presidio(gruppo: gruppo.id))
                    }
                } else {
                    await schermata.eseguiPerProva(.presidio(gruppo: gruppo.id))
                }
            }
        }
        let finale = try XCTUnwrap(schermata.statoPerProva)
        return try XCTUnwrap(finale.battaglieInSospeso.first,
            "in \(maxGiorni) giornate i due armati non sono mai entrati in contatto: lo scenario giocabile non permette di arrivare a una battaglia (incarico 24)")
    }

    /// Combatte la battaglia fino alla conclusione con un tattico deterministico per il giocatore,
    /// mentre `PartitaCorrente` muove l'avversario da sé (come nel gioco). Fa agire prima
    /// l'avversario se è lui il primo occupante (01 §9.4.1).
    private func combattiAConclusione(_ partita: PartitaCorrente, ambiente: Ambiente) async throws
        -> StatoBattaglia {
        let ufficiale = try XCTUnwrap(
            ambiente.valori.ufficiali.values.sorted { $0.identificatore < $1.identificatore }.first,
            "serve almeno un ufficiale")
        let tattico = TatticoBattaglia(motore: partita.motore, ufficiale: ufficiale, parte: .giocatore)
        try await partita.muoviAvversarioSeTocca()
        var stato = await partita.stato
        var passi = 0
        while stato.esito == nil && passi < 6000 {
            passi += 1
            guard stato.parteDiTurno == .giocatore else { break }
            let comando = tattico.prossimoComando(stato: stato)
            _ = try await partita.esegui(comando)
            stato = await partita.stato
        }
        return stato
    }

    // MARK: - Il tasto di chiusura della giornata e la diagnostica (incarico 26)

    /// Il titolare preme «Chiudi la giornata» con gruppi ancora in attesa: la giornata si chiude
    /// quale che sia il loro stato, la chiusura sopravvive a un riavvio (è nel giornale), e — poiché
    /// la giornata non si sarebbe chiusa da sé — il gioco ha scritto la diagnostica accanto al
    /// salvataggio, coi gruppi non-agiti e le loro azioni. È il dato che un blocco irriproducibile
    /// lascia dietro di sé.
    func test_incarico_26_il_tasto_chiude_la_giornata_e_scrive_la_diagnostica() async throws {
        let urlDiag = PartitaCampagna.urlDiagnostica(giorno: 1)
        try? FileManager.default.removeItem(at: urlDiag)
        let (schermata, _) = try await mappaAperta(taglia: .piccola)
        let prima = try XCTUnwrap(schermata.statoPerProva)
        XCTAssertEqual(prima.giorno, 1)
        // I gruppi non-agiti di ENTRAMBE le parti: la diagnostica li registra tutti (il quadro
        // completo per chi indaga), non i soli del giocatore.
        let nonAgiti = prima.gruppi.values.filter { !$0.haConclusoLaGiornata }.count
        XCTAssertGreaterThan(prima.gruppiInAttesa(di: .giocatore).count, 0,
                             "a inizio giornata i gruppi del giocatore sono in attesa")

        schermata.chiudiGiornataPerProva()
        for _ in 0..<200 where schermata.statoPerProva?.giorno == 1 {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertEqual(schermata.statoPerProva?.giorno, 2,
                       "il tasto ha chiuso la giornata anche coi gruppi in attesa")

        // La diagnostica è accanto al salvataggio, coi gruppi non-agiti e le loro azioni.
        XCTAssertTrue(FileManager.default.fileExists(atPath: urlDiag.path),
                      "la diagnostica è stata scritta accanto al giornale: \(urlDiag.lastPathComponent)")
        let dati = try Data(contentsOf: urlDiag)
        let diag = try JSONDecoder().decode(DiagnosticaChiusura.self, from: dati)
        XCTAssertEqual(diag.giorno, 1)
        XCTAssertEqual(diag.gruppiNonAgiti.count, nonAgiti,
                       "la diagnostica elenca i gruppi che non avevano agito")
        XCTAssertTrue(diag.gruppiNonAgiti.contains { $0.parte == "giocatore" },
                      "la diagnostica include i gruppi del giocatore in attesa")
        XCTAssertTrue(diag.gruppiNonAgiti.allSatisfy { !$0.azioniDisponibili.isEmpty },
                      "ogni gruppo non-agito porta le azioni che gli erano disponibili")

        // La chiusura sopravvive al riavvio: rigiocando il giornale, la giornata resta chiusa.
        let ripresa = try await PartitaCampagna(riprendi: schermata.partitaPerProva.ambiente)
        let statoRipreso = await ripresa.stato
        XCTAssertEqual(statoRipreso.giorno, 2,
                       "riaperta la campagna, la giornata chiusa dal titolare è ancora chiusa")
    }

    // MARK: - Le partite intere fino alla conclusione naturale (incarico 26)

    /// Il limite DICHIARATO di giornate per una partita di prova: generoso. Una campagna non ha una
    /// condizione di vittoria — nessuna stagione, nessun obiettivo —, sicché la sua conclusione
    /// naturale è che una parte non abbia più gruppi ARMATI e non possa più combattere; oppure che
    /// il limite sia raggiunto senza che il gioco si sia MAI fermato, che è comunque giocabilità. La
    /// prova FALLISCE solo se il gioco si ferma — un gruppo in attesa senza alcuna azione offerta dal
    /// pannello, o una battaglia che non si conclude —, dichiarando dove e perché.
    private static let massimoGiornate = 30

    /// La prova che gioca le partite FINO IN FONDO, su tutti e tre i formati, attraverso l'interfaccia
    /// vera (incarico 26): apre la partita come il giocatore, ordina i gruppi giornata dopo giornata,
    /// apre e combatte ogni battaglia sulla schermata di battaglia, torna in campagna, prosegue, e non
    /// si ferma finché la partita non si conclude per una via prevista o si esaurisce il limite senza
    /// mai bloccarsi. È la protezione che mancava: nessuna prova prima giocava una partita intera.
    func test_incarico_26_le_partite_arrivano_alla_fine_su_ogni_formato() async throws {
        var esiti: [String] = []
        for taglia in PartitaCampagna.Taglia.allCases {
            esiti.append("\(taglia.rawValue): \(try await giocaFinoAllaFine(taglia))")
        }
        // Numero per lo strumento: quante partite, quante concluse. Non un numero a mente.
        print("PARTITE-INTERE-26 partite=\(esiti.count) | " + esiti.joined(separator: " | "))
    }

    /// Gioca una partita intera su un formato e ritorna un riassunto (per lo strumento). Fallisce se
    /// il gioco si ferma; non fallisce se la partita è ancora giocabile al limite delle giornate.
    private func giocaFinoAllaFine(_ taglia: PartitaCampagna.Taglia) async throws -> String {
        let (schermata, ambiente) = try await mappaAperta(taglia: taglia)
        let motore = schermata.motorePerProva
        func dist(_ a: Cella, _ b: Cella) -> Int { abs(a.riga - b.riga) + abs(a.colonna - b.colonna) }
        func armati(_ parte: Parte, _ s: StatoCampagna) -> [Gruppo] {
            s.gruppi(di: parte).filter { $0.categoria.eArmata }
        }
        let giornoIniziale = schermata.statoPerProva?.giorno ?? 0
        var battaglie = 0
        while true {
            guard let s = schermata.statoPerProva else { break }
            // 1. Una battaglia in sospeso si combatte SUBITO, dalla catena vera dello schermo: il
            //    comando della casella, la schermata di battaglia, il resoconto, il ritorno.
            if let b = s.battaglieInSospeso.first {
                try await apriCombattiEtornaDalloSchermo(schermata, battaglia: b, ambiente: ambiente)
                battaglie += 1
                continue
            }
            // 2. Conclusione naturale: una parte non ha più gruppi armati (non nascono altre battaglie).
            if armati(.giocatore, s).isEmpty || armati(.avversario, s).isEmpty {
                return "conclusa al giorno \(s.giorno) dopo \(battaglie) battaglie (armati giocatore \(armati(.giocatore, s).count), avversario \(armati(.avversario, s).count))"
            }
            // 3. Limite generoso: giocabile fin qui senza fermarsi mai, non un blocco.
            if s.giorno - giornoIniziale >= Self.massimoGiornate {
                return "giocata al limite di \(Self.massimoGiornate) giornate senza fermarsi, dopo \(battaglie) battaglie"
            }
            // 4. Ordina l'intera giornata attraverso il pannello. Ogni gruppo in attesa DEVE poter
            //    agire, colto dal pannello — dov'è che il giocatore lo vedrebbe bloccato.
            let giorno = s.giorno
            var protezione = 0
            while schermata.statoPerProva?.giorno == giorno,
                  schermata.statoPerProva?.battaglieInSospeso.isEmpty == true, protezione < 80 {
                protezione += 1
                guard let s = schermata.statoPerProva,
                      let g = s.gruppiInAttesa(di: .giocatore).first else { break } // giornata chiusa
                XCTAssertTrue(schermata.attiva(g.posizione),
                              "formato \(taglia.rawValue): la casella del gruppo \(g.id.numero) si attiva")
                try? await Task.sleep(nanoseconds: 40_000_000)
                XCTAssertFalse(schermata.vociPannelloPerProva.isEmpty,
                    "IL GIOCO SI È FERMATO — formato \(taglia.rawValue), giorno \(s.giorno): il gruppo \(g.id.numero) in riga \(g.posizione.riga) casella \(g.posizione.colonna) è in attesa e il pannello non offre ALCUNA azione")
                // Scegli un ordine VALIDO (il giocatore non dà un ordine che il gioco respinge): un
                // armato marcia verso l'avversario più vicino se può — per il contatto —, altrimenti
                // presidia; se nemmeno il presidio vale (deve rifornirsi), sosta con raccolta, che è
                // sempre valida per un gruppo non-agito (l'invariante della giocabilità). Così la
                // prova avanza sempre; è il PANNELLO, sopra, a dire se un'azione ESISTE.
                func valido(_ c: ComandoCampagna) -> Bool { motore.valida(c, parte: .giocatore, stato: s).eValido }
                var ordine: ComandoCampagna = .sostaConRaccolta(gruppo: g.id)
                if valido(.presidio(gruppo: g.id)) { ordine = .presidio(gruppo: g.id) }
                if g.categoria.eArmata,
                   let bersaglio = armati(.avversario, s).min(by: {
                       dist(g.posizione, $0.posizione) < dist(g.posizione, $1.posizione) }) {
                    let vista = VistaCampagna(motore: motore, stato: s, parte: .giocatore)
                    let dest = vista.destinazioniValide(per: g.id)
                    if let meta = dest.first(where: { $0 == bersaglio.posizione })
                        ?? dest.min(by: { dist($0, bersaglio.posizione) < dist($1, bersaglio.posizione) }) {
                        let marcia = ComandoCampagna.marcia(gruppo: g.id, a: meta,
                            giorni: motore.costoInGiorni(da: g.posizione, a: meta, stato: s))
                        if valido(marcia) { ordine = marcia }
                    }
                }
                await schermata.eseguiPerProva(ordine)
                for _ in 0..<40 where schermata.statoPerProva?.gruppi[g.id]?.haConclusoLaGiornata == false
                    && schermata.statoPerProva?.giorno == giorno
                    && schermata.statoPerProva?.battaglieInSospeso.isEmpty == true {
                    try? await Task.sleep(nanoseconds: 10_000_000)
                }
            }
            XCTAssertLessThan(protezione, 80,
                "IL GIOCO SI È FERMATO — formato \(taglia.rawValue): la giornata \(giorno) non si è chiusa in 80 ordini, la campagna è bloccata")
        }
        return "interrotta"
    }
}
