import XCTest
import Dati
import Motore
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
        try await schermata.partitaPerProva.concludiBattaglia(battaglia, statoBattaglia: statoFinale)
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
        try await schermata.partitaPerProva.concludiBattaglia(battaglia, statoBattaglia: statoFinale)

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
}
