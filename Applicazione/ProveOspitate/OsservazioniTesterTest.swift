import XCTest
import Dati
import Motore
import Sessione
@testable import WarSense

/// Le sei osservazioni della sessione da tester dell'incarico 28
/// (`Incarichi/28-2026-11-21-prodotti/sessione-da-tester/osservazioni.md`), ciascuna resa una prova
/// che FALLISCE sul codice della build 29 e passa dopo la correzione (incarico 29). I numeri delle
/// prove sono quelli del file delle osservazioni.
@MainActor
final class OsservazioniTesterTest: XCTestCase {

    private var finestre: [UIWindow] = []

    override func tearDown() async throws {
        for f in finestre {
            f.rootViewController?.presentedViewController?.presentedViewController?.dismiss(animated: false)
            f.rootViewController?.presentedViewController?.dismiss(animated: false)
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

    private func attendi(_ condizione: () -> Bool, giri: Int = 300) async throws {
        for _ in 0..<giri where !condizione() { try await Task.sleep(nanoseconds: 20_000_000) }
    }

    private func attendiStato(_ condizione: () async -> Bool, giri: Int = 300) async throws {
        for _ in 0..<giri {
            if await condizione() { return }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    private func mappa(_ taglia: PartitaCampagna.Taglia = .piccola) async throws
        -> (SchermataMappaCampagna, Ambiente) {
        let ambiente = try Ambiente()
        let schermata = SchermataMappaCampagna(partita: try await PartitaCampagna(nuova: ambiente, taglia: taglia))
        monta(schermata)
        try await attendi { !schermata.elementiPerProva.isEmpty }
        try await Task.sleep(nanoseconds: 150_000_000)
        return (schermata, ambiente)
    }

    private func battaglia() async throws -> (SchermataBattaglia, Ambiente) {
        let ambiente = try Ambiente()
        let schermata = SchermataBattaglia(partita: try await PartitaCorrente(nuova: ambiente))
        monta(schermata)
        try await attendi { !schermata.elementiPerProva.isEmpty }
        try await Task.sleep(nanoseconds: 150_000_000)
        return (schermata, ambiente)
    }

    /// Il pulsante dell'ordine di lettura con il titolo indicato.
    private func pulsante(_ titolo: String, in radice: UIView) throws -> UIButton {
        try XCTUnwrap(LettoreAccessibilita.ordineDiLettura(radice: radice)
            .first { LettoreAccessibilita.etichetta(di: $0) == titolo } as? UIButton,
            "il pulsante «\(titolo)» è nell'ordine di lettura")
    }

    // MARK: - Osservazione 1 — il pannello di un gruppo bloccato dichiara il motivo (02 §6.5)

    /// Porta due armati a contatto finché nasce una battaglia in sospeso, ordinando i gruppi come il
    /// giocatore che cerca il contatto (la stessa condotta della prova del passaggio, incarico 24).
    private func portaAContatto(_ schermata: SchermataMappaCampagna, maxGiorni: Int = 60) async throws
        -> BattagliaInSospeso {
        func dist(_ a: Cella, _ b: Cella) -> Int { abs(a.riga - b.riga) + abs(a.colonna - b.colonna) }
        let motore = schermata.motorePerProva
        for _ in 0..<maxGiorni {
            let stato = try XCTUnwrap(schermata.statoPerProva)
            if let b = stato.battaglieInSospeso.first { return b }
            let giorno = stato.giorno
            let avversari = stato.gruppi(di: .avversario).filter { $0.categoria.eArmata }
            var protezione = 0
            while schermata.statoPerProva?.giorno == giorno && protezione < 60 {
                protezione += 1
                guard let s = schermata.statoPerProva, s.battaglieInSospeso.isEmpty,
                      let gruppo = s.gruppiInAttesa(di: .giocatore).first else { break }
                var ordine: ComandoCampagna = .presidio(gruppo: gruppo.id)
                if gruppo.categoria.eArmata,
                   let bersaglio = avversari.min(by: { dist(gruppo.posizione, $0.posizione) < dist(gruppo.posizione, $1.posizione) }) {
                    let destinazioni = VistaCampagna(motore: motore, stato: s, parte: .giocatore).destinazioniValide(per: gruppo.id)
                    if let meta = destinazioni.first(where: { $0 == bersaglio.posizione })
                        ?? destinazioni.min(by: { dist($0, bersaglio.posizione) < dist($1, bersaglio.posizione) }) {
                        ordine = .marcia(gruppo: gruppo.id, a: meta,
                                         giorni: motore.costoInGiorni(da: gruppo.posizione, a: meta, stato: s))
                    }
                }
                if !motore.valida(ordine, parte: .giocatore, stato: s).eValido { ordine = .sostaConRaccolta(gruppo: gruppo.id) }
                await schermata.eseguiPerProva(ordine)
            }
        }
        return try XCTUnwrap(schermata.statoPerProva?.battaglieInSospeso.first,
                             "in \(maxGiorni) giornate non è nata alcuna battaglia")
    }

    /// Con una battaglia in sospeso ALTROVE, il pannello di un gruppo che non vi combatte non offre
    /// azioni: deve dire perché, col motivo chiuso dei comandi bloccati e il luogo della battaglia
    /// (02 §6.5). Fino alla build 29 conteneva il solo titolo e «Chiudi il pannello».
    func test_osservazione_1_il_pannello_di_un_gruppo_bloccato_dichiara_il_motivo() async throws {
        let (schermata, ambiente) = try await mappa()
        let battaglia = try await portaAContatto(schermata)
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let altro = try XCTUnwrap(stato.gruppi(di: .giocatore).first { $0.posizione != battaglia.casella },
                                  "c'è un gruppo del giocatore fuori dalla casella contesa")
        XCTAssertTrue(schermata.attiva(altro.posizione))
        try await attendi { schermata.presentedViewController is UIAlertController }
        let pannello = try XCTUnwrap(schermata.presentedViewController as? UIAlertController)
        let motivo = ambiente.testi.termine(MotivoNonValidoCampagna.battagliaInSospeso.rawValue).testo
        let messaggio = pannello.message ?? ""
        XCTAssertTrue(messaggio.contains(motivo),
                      "il pannello dichiara il motivo «\(motivo)»: messaggio «\(messaggio)»")
        XCTAssertTrue(messaggio.contains("riga \(battaglia.casella.riga), casella \(battaglia.casella.colonna)"),
                      "il pannello dice dove sta la battaglia in sospeso: «\(messaggio)»")
        XCTAssertTrue(schermata.vociPannelloPerProva.allSatisfy { $0.stile == .cancel },
                      "le azioni bloccate non compaiono (02 §9.5): \(schermata.vociPannelloPerProva.map(\.titolo))")
    }

    // MARK: - Osservazione 2 — «Hanno agito 1 gruppi su 4»

    /// Con un solo gruppo che ha agito, l'informazione di stato (tocco magico) accorda verbo e nome
    /// al numero (00 §14.3: i plurali dal meccanismo di sistema).
    func test_osservazione_2_un_gruppo_che_ha_agito_si_accorda_al_numero() async throws {
        let (schermata, ambiente) = try await mappa()
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let gruppo = try XCTUnwrap(stato.gruppiInAttesa(di: .giocatore).first)
        await schermata.eseguiPerProva(.presidio(gruppo: gruppo.id))
        try await attendi { schermata.statoPerProva?.gruppi[gruppo.id]?.haConclusoLaGiornata == true }
        XCTAssertTrue(schermata.accessibilityPerformMagicTap())
        let detto = try XCTUnwrap(ambiente.segnali.annunciPronunciati.last?.testo)
        XCTAssertFalse(detto.contains("1 gruppi"), "«\(detto)»")
        XCTAssertTrue(detto.contains("Ha agito 1 gruppo su"), "«\(detto)»")
    }

    // MARK: - Osservazione 3 — il fuoco d'apertura della battaglia non attende il caricamento

    /// La causa dell'intermittenza (accertata sul simulatore, `Incarichi/29-2026-11-21-prodotti/
    /// fuoco-apertura-ipad/`): la notifica che porta il fuoco sull'intestazione del deck partiva alla
    /// fine del caricamento asincrono dello stato, e quando il caricamento si allungava cadeva nella
    /// finestra in cui VoiceOver applica il proprio fuoco di sistema, che finiva sulla prima cella.
    /// Corretta, parte nel momento stesso in cui la schermata compare: chiamata la comparsa, senza
    /// lasciare correre il caricamento, il fuoco è già stato portato sull'intestazione.
    func test_osservazione_3_il_fuoco_d_apertura_parte_alla_comparsa_senza_attendere_il_caricamento() async throws {
        let ambiente = try Ambiente()
        let schermata = SchermataBattaglia(partita: try await PartitaCorrente(nuova: ambiente))
        let finestra = UIWindow(frame: CGRect(x: 0, y: 0, width: 1032, height: 1376))
        finestre.append(finestra)
        Fuoco.azzeraRegistro()
        // Nessuna sospensione fra qui e le asserzioni: il caricamento asincrono non può correre.
        schermata.loadViewIfNeeded()
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.viewDidAppear(false)
        XCTAssertEqual(Fuoco.registro.first, .schermataAperta,
                       "alla comparsa il gioco non ha ancora portato il fuoco: lo farà dopo il caricamento, quando VoiceOver può averlo già messo altrove")
        let bersaglio = Fuoco.ultimoBersaglio as? UILabel
        XCTAssertEqual(bersaglio?.text, ambiente.testi.frase("deck.intestazione").testo,
                       "il fuoco d'apertura va sull'intestazione del deck (02 §2.9)")
        XCTAssertEqual(bersaglio?.accessibilityTraits.contains(.header), true)
        // Ripetere la comparsa (per esempio al ritorno da un pannello) non riporta il fuoco.
        let movimenti = Fuoco.registro.count
        schermata.viewDidAppear(false)
        XCTAssertEqual(Fuoco.registro.count, movimenti, "il fuoco d'apertura si porta una volta sola")
    }

    // MARK: - Osservazione 4 — il gesto di uscita chiude impostazioni, apprendimento e resoconto

    /// Il gesto di fuga risale di un livello (02 §6.7): chiude le impostazioni e l'apprendimento, e il
    /// fuoco torna sul comando che li aveva aperti, come alla chiusura col pulsante.
    func test_osservazione_4_il_gesto_di_uscita_chiude_impostazioni_e_apprendimento() async throws {
        let ambiente = try Ambiente()
        let avvio = SchermataAvvio(ambiente: ambiente)
        monta(avvio)
        avvio.viewWillAppear(false)
        for chiave in ["avvio.impostazioni", "avvio.apprendimento"] {
            let titolo = ambiente.testi.frase(chiave).testo
            let origine = try pulsante(titolo, in: avvio.view)
            origine.sendActions(for: .touchUpInside)
            try await attendi { avvio.presentedViewController != nil }
            let aperta = try XCTUnwrap(avvio.presentedViewController, "«\(titolo)» ha aperto la sua schermata")
            let movimenti = Fuoco.registro.count
            XCTAssertTrue(aperta.accessibilityPerformEscape(), "il gesto di uscita è gestito da «\(titolo)»")
            try await attendi { avvio.presentedViewController == nil && Fuoco.registro.count > movimenti }
            XCTAssertNil(avvio.presentedViewController, "il gesto di uscita ha chiuso «\(titolo)»")
            XCTAssertEqual(Fuoco.registro.last, .schermataChiusa)
            XCTAssertTrue(Fuoco.ultimoBersaglio === (try? pulsante(titolo, in: avvio.view)),
                          "chiusa col gesto, il fuoco torna su «\(titolo)»")
        }
    }

    /// Il gesto di fuga sul resoconto di fine battaglia lo congeda come «Torna all'inizio».
    func test_osservazione_4_il_gesto_di_uscita_congeda_il_resoconto() async throws {
        let ambiente = try Ambiente()
        let radice = UIViewController()
        monta(radice)
        let resoconto = SchermataResoconto(voci: ["Voce di prova"], testi: ambiente.testi)
        var congedato = false
        resoconto.alTermine = { congedato = true }
        radice.present(resoconto, animated: false)
        try await attendi { radice.presentedViewController === resoconto }
        XCTAssertTrue(resoconto.accessibilityPerformEscape(), "il gesto di uscita è gestito dal resoconto")
        try await attendi { congedato }
        XCTAssertTrue(congedato, "il gesto di uscita congeda il resoconto e riporta dove porta «Torna all'inizio»")
        XCTAssertNil(radice.presentedViewController)
    }

    // MARK: - Osservazione 5 — la tessera appena deselezionata non si dichiara selezionata

    /// La causa ipotizzata dal resoconto 28, verificata qui: dopo l'attivazione i tratti della tessera
    /// si aggiornavano soltanto per la via asincrona (comando alla Sessione, ricarica dello stato), e
    /// VoiceOver, che rilegge l'elemento appena l'attivazione ritorna, vi trovava lo stato di prima.
    /// Corretta, l'attivazione che ritorna lascia la tessera già nello stato nuovo.
    func test_osservazione_5_la_tessera_dichiara_lo_stato_nuovo_appena_attivata() async throws {
        let (schermata, ambiente) = try await battaglia()
        let tessera = try XCTUnwrap(schermata.tesserePerProva.first { $0.isEnabled })
        let statoIniziale = await schermata.partitaPerProva.stato
        let archetipo = try XCTUnwrap(statoIniziale.deck[.giocatore]?[tessera.tag].archetipo)
        let selezionato = ambiente.testi.frase("deck.selezionato", soggetto: ambiente.testi.soggetto(.unita, archetipo)).testo
        XCTAssertNotEqual(selezionato, Testi.segnaposto)
        // Scelta: subito dopo l'attivazione la tessera è selezionata.
        XCTAssertTrue(tessera.accessibilityActivate())
        XCTAssertTrue(tessera.accessibilityTraits.contains(.selected),
                      "appena scelta, la tessera deve dichiararsi selezionata: VoiceOver la rilegge ora")
        try await attendiStato { await schermata.partitaPerProva.stato.selezione[.giocatore] == tessera.tag }
        try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertTrue(tessera.accessibilityTraits.contains(.selected))
        // Deselezione: subito dopo l'attivazione la tessera NON è più selezionata (il caso osservato).
        XCTAssertTrue(tessera.accessibilityActivate())
        XCTAssertFalse(tessera.accessibilityTraits.contains(.selected),
                       "appena deselezionata la tessera si dichiara ancora «selezionato»")
        XCTAssertFalse((tessera.accessibilityValue ?? "").contains(selezionato),
                       "il valore della tessera dice ancora «\(selezionato)»: \(tessera.accessibilityValue ?? "")")
        // E lo stato vero, a comando eseguito, coincide con ciò che la tessera ha dichiarato.
        try await attendiStato { await schermata.partitaPerProva.stato.selezione[.giocatore] == nil }
        try await Task.sleep(nanoseconds: 150_000_000)
        let statoFinale = await schermata.partitaPerProva.stato
        XCTAssertNil(statoFinale.selezione[.giocatore])
        XCTAssertFalse(tessera.accessibilityTraits.contains(.selected))
    }

    // MARK: - Osservazione 6 — l'azzeramento a vuoto lo dichiara

    /// In battaglia, dopo due annullamenti che hanno tolto piazzamento e scelta, l'azzeramento non ha
    /// nulla da azzerare: deve dirlo, invece di confermare «Schieramento del turno azzerato».
    func test_osservazione_6_l_azzeramento_a_vuoto_in_battaglia_lo_dichiara() async throws {
        let (schermata, ambiente) = try await battaglia()
        let partita = schermata.partitaPerProva
        let stato = await partita.stato
        let indice = try XCTUnwrap(stato.deck[.giocatore]?.firstIndex { $0.esemplari > 0 })
        _ = try await partita.esegui(.seleziona(indiceDeck: indice))
        let scelta = await partita.stato
        let cella = try XCTUnwrap(VistaBattaglia(motore: partita.motore, stato: scelta, parte: .giocatore)
            .celleValidePerSelezione().first?.cella)
        _ = try await partita.esegui(.piazza(cella: cella))
        try await partita.annulla()
        try await partita.annulla()
        try await Task.sleep(nanoseconds: 150_000_000)
        ambiente.segnali.azzeraAnnunciPronunciati()
        try pulsante(ambiente.testi.frase("pulsante.azzera").testo, in: schermata.view).sendActions(for: .touchUpInside)
        try await attendi { !ambiente.segnali.annunciPronunciati.isEmpty }
        let detti = ambiente.segnali.annunciPronunciati.map(\.testo)
        XCTAssertFalse(detti.contains(ambiente.testi.frase("battaglia.azzerato_conferma").testo),
                       "con nulla da azzerare l'azzeramento conferma lo stesso: \(detti)")
        XCTAssertEqual(detti.last, ambiente.testi.frase("battaglia.niente_da_azzerare").testo)
    }

    /// In campagna, all'inizio della giornata senza alcun ordine: lo stesso, nella forma della campagna.
    func test_osservazione_6_l_azzeramento_a_vuoto_in_campagna_lo_dichiara() async throws {
        let (schermata, ambiente) = try await mappa()
        ambiente.segnali.azzeraAnnunciPronunciati()
        try pulsante(ambiente.testi.frase("pulsante.azzera").testo, in: schermata.view).sendActions(for: .touchUpInside)
        try await attendi { !ambiente.segnali.annunciPronunciati.isEmpty }
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.last?.testo,
                       ambiente.testi.frase("campagna.niente_da_azzerare").testo)
    }
}
