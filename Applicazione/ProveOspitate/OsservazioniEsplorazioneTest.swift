import XCTest
import Dati
import Motore
import Sessione
@testable import WarSense

/// Le osservazioni dell'esplorazione con VoiceOver dell'incarico 27, ciascuna resa una prova che
/// FALLISCE sul codice della build 28 e passa dopo la correzione (incarico 28). I numeri delle prove
/// sono quelli del file `Incarichi/27-2026-11-20-prodotti/esplorazione/osservazioni.md`.
///
/// La raggiungibilità si giudica sull'ordine di lettura dichiarato e sul PERCORSO d'accessibilità che
/// vi conduce: un elemento fuori dallo schermo è raggiungibile solo se un contenitore scorrevole sta
/// su quel percorso — è da lì che la tecnologia assistiva lo porta in vista — oppure se l'elemento si
/// porta in vista da sé quando il fuoco vi arriva (le celle, le caselle, le tessere del deck).
/// L'esplorazione dell'incarico 27 ha mostrato il caso contrario: «Fine del turno» stava nella
/// colonna scorrevole della battaglia, ma l'ordine era dichiarato sulla vista radice, e né VoiceOver
/// né XCUITest riuscivano a portarlo in vista a testo massimo.
@MainActor
final class OsservazioniEsplorazioneTest: XCTestCase {

    // MARK: - Le configurazioni dell'esplorazione: iPhone Air, verticale e orizzontale

    /// L'iPhone Air in punti, con le aree sicure dell'apparecchio vero (verticale: isola in alto,
    /// barra in basso; orizzontale: isola di lato).
    struct Configurazione {
        let nome: String
        let dimensione: CGSize
        let areeSicure: UIEdgeInsets
        let taglia: UIContentSizeCategory
    }

    static let verticale = CGSize(width: 420, height: 912)
    static let orizzontale = CGSize(width: 912, height: 420)
    static let areeVerticale = UIEdgeInsets(top: 68, left: 0, bottom: 34, right: 0)
    static let areeOrizzontale = UIEdgeInsets(top: 0, left: 68, bottom: 21, right: 68)

    static let configurazioni: [Configurazione] = [
        .init(nome: "verticale-predefinito", dimensione: verticale, areeSicure: areeVerticale, taglia: .large),
        .init(nome: "verticale-massimo", dimensione: verticale, areeSicure: areeVerticale,
              taglia: .accessibilityExtraExtraExtraLarge),
        .init(nome: "orizzontale-predefinito", dimensione: orizzontale, areeSicure: areeOrizzontale, taglia: .large),
        .init(nome: "orizzontale-massimo", dimensione: orizzontale, areeSicure: areeOrizzontale,
              taglia: .accessibilityExtraExtraExtraLarge),
    ]

    private var finestre: [UIWindow] = []

    override func tearDown() async throws {
        for f in finestre {
            f.rootViewController?.presentedViewController?.dismiss(animated: false)
            f.isHidden = true
            f.rootViewController = nil
        }
        finestre = []
        try await super.tearDown()
    }

    /// Monta la schermata in una finestra della configurazione e attende la disposizione.
    private func monta(_ schermata: UIViewController, in c: Configurazione) -> UIWindow {
        let finestra = UIWindow(frame: CGRect(origin: .zero, size: c.dimensione))
        finestra.traitOverrides.preferredContentSizeCategory = c.taglia
        schermata.additionalSafeAreaInsets = c.areeSicure
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

    // MARK: - Il lettore del percorso d'accessibilità

    /// Le foglie dell'ordine di lettura, ciascuna col percorso dei contenitori d'accessibilità che vi
    /// conducono (la stessa derivazione di `LettoreAccessibilita.ordineDiLettura`).
    static func foglieConPercorso(radice: NSObject) -> [(NSObject, [NSObject])] {
        var esito: [(NSObject, [NSObject])] = []
        func raccogli(_ nodo: NSObject, _ percorso: [NSObject]) {
            if let vista = nodo as? UIView {
                guard !vista.isHidden, vista.alpha > 0.01, !vista.accessibilityElementsHidden else { return }
                let foglia = vista.isAccessibilityElement || vista is UIControl
                    || ((vista as? UILabel)?.text?.isEmpty == false)
                if foglia { esito.append((vista, percorso)); return }
                if let dichiarati = vista.accessibilityElements {
                    for e in dichiarati { if let o = e as? NSObject { raccogli(o, percorso + [vista]) } }
                    return
                }
                for sotto in vista.subviews { raccogli(sotto, percorso + [vista]) }
                return
            }
            if nodo.isAccessibilityElement { esito.append((nodo, percorso)); return }
            if let dichiarati = nodo.accessibilityElements {
                for e in dichiarati { if let o = e as? NSObject { raccogli(o, percorso + [nodo]) } }
            }
        }
        raccogli(radice, [])
        return esito
    }

    /// Il motivo per cui un elemento dell'ordine di lettura NON è raggiungibile, o nulla.
    static func motivoNonRaggiungibile(_ elemento: NSObject, percorso: [NSObject], schermo: CGRect) -> String? {
        let cornice = LettoreAccessibilita.cornice(di: elemento)
        guard cornice.width >= 1, cornice.height >= 1 else { return "cornice degenere \(cornice)" }
        // Mezzo punto di tolleranza: il risolutore dei vincoli lavora in virgola mobile.
        if schermo.insetBy(dx: -0.5, dy: -0.5).contains(cornice) { return nil }
        // Gli elementi che si portano in vista da sé quando il fuoco vi arriva (00 §10.4).
        if elemento is ElementoCella || elemento is ElementoCasella || elemento is TesseraDeck { return nil }
        for contenitore in percorso.reversed() {
            guard let scorrevole = contenitore as? UIScrollView else { continue }
            let contenuto = CGRect(origin: .zero, size: scorrevole.contentSize).insetBy(dx: -1, dy: -1)
            let nelContenuto = scorrevole.convert(cornice, from: nil)
            return contenuto.contains(nelContenuto) ? nil : "fuori dal contenuto scorrevole \(nelContenuto)"
        }
        return "fuori dallo schermo \(cornice) e nessun contenitore scorrevole sul percorso d'accessibilità"
    }

    /// L'altezza del BERSAGLIO di un elemento: la sua cornice, oppure — per una vista che dichiara
    /// una cornice d'accessibilità più alta, come le leve di `InterruttoreAmpio` — quella cornice,
    /// purché anche il tocco la copra davvero ai due estremi. È ciò che trovano l'esplorazione al
    /// tatto di VoiceOver (la cornice d'accessibilità) e il dito (il tocco).
    static func altezzaDelBersaglio(_ elemento: NSObject) -> CGFloat {
        let cornice = LettoreAccessibilita.cornice(di: elemento)
        guard let vista = elemento as? UIView else { return cornice.height }
        let dichiarata = vista.accessibilityFrame
        guard dichiarata.height > cornice.height else { return cornice.height }
        let mezzo = dichiarata.height / 2 - 1
        let centro = CGPoint(x: vista.bounds.midX, y: vista.bounds.midY)
        let copre = vista.point(inside: CGPoint(x: centro.x, y: centro.y - mezzo), with: nil)
            && vista.point(inside: CGPoint(x: centro.x, y: centro.y + mezzo), with: nil)
        return copre ? dichiarata.height : cornice.height
    }

    /// Le violazioni di raggiungibilità e di dimensione minima di una schermata montata.
    static func difetti(di schermata: UIViewController, finestra: UIWindow) -> [String] {
        var difetti: [String] = []
        for (elemento, percorso) in foglieConPercorso(radice: schermata.view) {
            let etichetta = LettoreAccessibilita.etichetta(di: elemento)
            if let motivo = motivoNonRaggiungibile(elemento, percorso: percorso, schermo: finestra.bounds) {
                difetti.append("«\(etichetta)»: \(motivo)")
            }
            if LettoreAccessibilita.eInterattivo(elemento),
               !(elemento is ElementoCella), !(elemento is ElementoCasella),
               altezzaDelBersaglio(elemento).rounded() < 44 {
                difetti.append("«\(etichetta)»: bersaglio alto \(altezzaDelBersaglio(elemento)) < 44")
            }
        }
        return difetti
    }

    // MARK: - Osservazioni 1, 3, 5, 7 — ogni elemento raggiungibile in ogni configurazione

    /// Osservazioni 3 e 7: l'avvio, in verticale e in orizzontale, a testo predefinito e massimo.
    func test_osservazioni_3_7_l_avvio_e_raggiungibile_in_ogni_configurazione() async throws {
        let ambiente = try Ambiente()
        var difetti: [String] = []
        for c in Self.configurazioni {
            let schermata = SchermataAvvio(ambiente: ambiente)
            let finestra = monta(schermata, in: c)
            schermata.viewWillAppear(false)
            finestra.layoutIfNeeded()
            difetti += Self.difetti(di: schermata, finestra: finestra).map { "avvio \(c.nome): \($0)" }
        }
        XCTAssertEqual(difetti, [], "elementi dell'avvio non raggiungibili:\n" + difetti.joined(separator: "\n"))
    }

    /// Osservazioni 1 e 5: la battaglia (scontro di prova) in ogni configurazione.
    func test_osservazioni_1_5_la_battaglia_e_raggiungibile_in_ogni_configurazione() async throws {
        var difetti: [String] = []
        for c in Self.configurazioni {
            let ambiente = try Ambiente()
            let partita = try await PartitaCorrente(nuova: ambiente)
            let schermata = SchermataBattaglia(partita: partita)
            let finestra = monta(schermata, in: c)
            try await attendi { !schermata.elementiPerProva.isEmpty }
            try await Task.sleep(nanoseconds: 200_000_000)
            finestra.layoutIfNeeded()
            difetti += Self.difetti(di: schermata, finestra: finestra).map { "battaglia \(c.nome): \($0)" }
        }
        XCTAssertEqual(difetti, [], "elementi della battaglia non raggiungibili:\n" + difetti.joined(separator: "\n"))
    }

    /// Osservazione 5: la mappa di campagna (formato piccolo) in ogni configurazione.
    func test_osservazione_5_la_mappa_e_raggiungibile_in_ogni_configurazione() async throws {
        var difetti: [String] = []
        for c in Self.configurazioni {
            let ambiente = try Ambiente()
            let partita = try await PartitaCampagna(nuova: ambiente, taglia: .piccola)
            let schermata = SchermataMappaCampagna(partita: partita)
            let finestra = monta(schermata, in: c)
            try await attendi { !schermata.elementiPerProva.isEmpty }
            try await Task.sleep(nanoseconds: 200_000_000)
            finestra.layoutIfNeeded()
            difetti += Self.difetti(di: schermata, finestra: finestra).map { "mappa \(c.nome): \($0)" }
        }
        XCTAssertEqual(difetti, [], "elementi della mappa non raggiungibili:\n" + difetti.joined(separator: "\n"))
    }

    /// Le altre schermate di contorno — impostazioni, apprendimento, resoconto — in ogni
    /// configurazione: le stesse ragioni delle osservazioni 3 e 5. L'osservazione 9 (i segmenti
    /// dell'intensità alti 32 punti) è il controllo della dimensione minima sulle impostazioni.
    func test_osservazioni_3_5_9_le_schermate_di_contorno_sono_raggiungibili() async throws {
        let ambiente = try Ambiente()
        let voci = (1...7).map { "Voce di prova numero \($0) del resoconto, abbastanza lunga da andare a capo." }
        var difetti: [String] = []
        for c in Self.configurazioni {
            let schermate: [(String, UIViewController)] = [
                ("impostazioni", SchermataImpostazioni(ambiente: ambiente)),
                ("apprendimento", SchermataApprendimento(ambiente: ambiente)),
                ("resoconto", SchermataResoconto(voci: voci, testi: ambiente.testi)),
            ]
            for (nome, schermata) in schermate {
                let finestra = monta(schermata, in: c)
                finestra.layoutIfNeeded()
                difetti += Self.difetti(di: schermata, finestra: finestra).map { "\(nome) \(c.nome): \($0)" }
            }
        }
        XCTAssertEqual(difetti, [], "elementi delle schermate di contorno non raggiungibili:\n"
                       + difetti.joined(separator: "\n"))
    }

    // MARK: - Osservazione 2 — il resoconto della battaglia dichiara come è finita

    /// Ciò che il resoconto presentato fa leggere, nell'ordine.
    private func letturaDelResoconto(_ schermata: SchermataBattaglia) async throws -> [String] {
        var resoconto: SchermataResoconto?
        for _ in 0..<300 {
            if let r = schermata.presentedViewController as? SchermataResoconto { resoconto = r; break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        let r = try XCTUnwrap(resoconto, "il resoconto di fine battaglia è stato presentato")
        r.view.layoutIfNeeded()
        return LettoreAccessibilita.ordineDiLettura(radice: r.view).map { LettoreAccessibilita.etichetta(di: $0) }
    }

    /// Il resoconto atteso per lo stato finale: titolo, le voci del costruttore, il congedo.
    private func resocontoAtteso(_ partita: PartitaCorrente, ambiente: Ambiente) async -> [String] {
        let finale = await partita.stato
        let voci = CostruttoreAnnunci(testi: ambiente.testi, motore: partita.motore, stato: finale,
                                      verbosita: Impostazioni.verbosita).vociResoconto()
        return [ambiente.testi.frase("resoconto.titolo").testo] + voci
            + [ambiente.testi.frase("resoconto.torna").testo]
    }

    /// Gioca la parte del giocatore con il tattico del collaudo finché lo scontro si conclude.
    private func combattiFinoAllaFine(_ partita: PartitaCorrente, ambiente: Ambiente) async throws {
        let ufficiale = try XCTUnwrap(
            ambiente.valori.ufficiali.values.sorted { $0.identificatore < $1.identificatore }.first)
        let tattico = TatticoBattaglia(motore: partita.motore, ufficiale: ufficiale, parte: .giocatore)
        var stato = await partita.stato
        var passi = 0
        while stato.esito == nil, passi < 6000 {
            passi += 1
            guard stato.parteDiTurno == .giocatore else { break }
            _ = try await partita.esegui(tattico.prossimoComando(stato: stato))
            stato = await partita.stato
        }
        XCTAssertNotNil(stato.esito, "lo scontro si è concluso")
    }

    /// Osservazione 2, prima via: una battaglia giocata SENZA interruzioni fino alla conclusione.
    func test_osservazione_2_il_resoconto_di_una_battaglia_giocata_fino_alla_fine() async throws {
        let ambiente = try Ambiente()
        let partita = try await PartitaCorrente(nuova: ambiente)
        let schermata = SchermataBattaglia(partita: partita)
        _ = monta(schermata, in: Self.configurazioni[0])
        try await attendi { !schermata.elementiPerProva.isEmpty }
        try await combattiFinoAllaFine(partita, ambiente: ambiente)
        let letto = try await letturaDelResoconto(schermata)
        let atteso = await resocontoAtteso(partita, ambiente: ambiente)
        XCTAssertGreaterThan(atteso.count, 2)
        XCTAssertEqual(letto, atteso, "il resoconto non dichiara come è finita la battaglia")
    }

    /// Osservazione 2, seconda via: una battaglia RIPRESA dopo la chiusura dell'app e conclusa con
    /// la resa, dichiarata dal pulsante della schermata appena diventa disponibile.
    func test_osservazione_2_il_resoconto_di_una_battaglia_ripresa_e_conclusa_con_la_resa() async throws {
        let ambiente = try Ambiente()
        do {
            let partita = try await PartitaCorrente(nuova: ambiente)
            let schermata = SchermataBattaglia(partita: partita)
            _ = monta(schermata, in: Self.configurazioni[0])
            try await attendi { !schermata.elementiPerProva.isEmpty }
            _ = try await partita.esegui(.fineTurno)
            try await Task.sleep(nanoseconds: 200_000_000)
            for f in finestre { f.isHidden = true; f.rootViewController = nil }
            finestre = []
        }
        // Riaperta l'app: la battaglia si riprende dal salvataggio.
        let ripresa = try await PartitaCorrente(riprendi: ambiente)
        let schermata = SchermataBattaglia(partita: ripresa)
        _ = monta(schermata, in: Self.configurazioni[0])
        try await attendi { !schermata.elementiPerProva.isEmpty }
        let resa = ambiente.testi.frase("pulsante.resa").testo
        let pulsante = try XCTUnwrap(
            LettoreAccessibilita.ordineDiLettura(radice: schermata.view)
                .first { LettoreAccessibilita.etichetta(di: $0) == resa } as? UIButton,
            "il pulsante «\(resa)» è nell'ordine di lettura")
        var stato = await ripresa.stato
        var giri = 0
        while stato.esito == nil, giri < 40 {
            giri += 1
            if stato.parteDiTurno == .giocatore, ripresa.motore.valida(.dichiaraResa, parte: .giocatore,
                                                                       stato: stato).eValido {
                pulsante.sendActions(for: .touchUpInside)
                for _ in 0..<100 where (await ripresa.stato).esito == nil {
                    try await Task.sleep(nanoseconds: 20_000_000)
                }
            } else if stato.parteDiTurno == .giocatore {
                _ = try await ripresa.esegui(.fineTurno)
            } else {
                try await ripresa.muoviAvversarioSeTocca()
            }
            stato = await ripresa.stato
        }
        XCTAssertNotNil(stato.esito, "la resa ha concluso lo scontro")
        let letto = try await letturaDelResoconto(schermata)
        let atteso = await resocontoAtteso(ripresa, ambiente: ambiente)
        XCTAssertEqual(letto, atteso, "il resoconto non dichiara come è finita la battaglia ripresa")
    }

    // MARK: - Osservazione 4 — l'annuncio del tasto conta i soli gruppi del giocatore

    func test_osservazione_4_l_annuncio_del_tasto_conta_i_soli_gruppi_del_giocatore() async throws {
        let ambiente = try Ambiente()
        let partita = try await PartitaCampagna(nuova: ambiente, taglia: .piccola)
        let schermata = SchermataMappaCampagna(partita: partita)
        _ = monta(schermata, in: Self.configurazioni[0])
        try await attendi { !schermata.elementiPerProva.isEmpty }
        let prima = try XCTUnwrap(schermata.statoPerProva)
        let propri = prima.gruppiInAttesa(di: .giocatore).count
        XCTAssertGreaterThan(propri, 0)
        XCTAssertGreaterThan(prima.gruppiInAttesa(di: .avversario).count, 0,
                             "l'avversario ha gruppi in attesa: è il caso in cui il conteggio sbagliava")
        let atteso = ambiente.testi.frase("giornata.chiusa_con_diagnostica", propri).testo
        let giaDetti = ambiente.segnali.annunciPronunciati.count
        schermata.chiudiGiornataPerProva()
        try await attendi { schermata.statoPerProva?.giorno == prima.giorno + 1
            && ambiente.segnali.annunciPronunciati.count > giaDetti }
        try await Task.sleep(nanoseconds: 200_000_000)
        let detti = ambiente.segnali.annunciPronunciati.dropFirst(giaDetti).map(\.testo)
        XCTAssertTrue(detti.contains(atteso),
                      "l'annuncio deve contare i \(propri) gruppi del giocatore; detto: \(detti)")
    }

    // MARK: - Osservazione 6 — chiusa una schermata, il fuoco torna sul pulsante che l'ha aperta

    func test_osservazione_6_chiuse_le_impostazioni_il_fuoco_torna_al_pulsante() async throws {
        let ambiente = try Ambiente()
        let avvio = SchermataAvvio(ambiente: ambiente)
        let finestra = monta(avvio, in: Self.configurazioni[0])
        avvio.viewWillAppear(false)
        finestra.layoutIfNeeded()
        let impostazioni = ambiente.testi.frase("avvio.impostazioni").testo
        let pulsante = try XCTUnwrap(
            LettoreAccessibilita.ordineDiLettura(radice: avvio.view)
                .first { LettoreAccessibilita.etichetta(di: $0) == impostazioni } as? UIButton)
        pulsante.sendActions(for: .touchUpInside)
        try await attendi { avvio.presentedViewController is SchermataImpostazioni }
        let aperta = try XCTUnwrap(avvio.presentedViewController as? SchermataImpostazioni)
        let movimentiPrima = Fuoco.registro.count
        let chiudi = ambiente.testi.frase("pannello.chiudi").testo
        let pulsanteChiudi = try XCTUnwrap(
            LettoreAccessibilita.ordineDiLettura(radice: aperta.view)
                .first { LettoreAccessibilita.etichetta(di: $0) == chiudi } as? UIButton)
        pulsanteChiudi.sendActions(for: .touchUpInside)
        try await attendi { avvio.presentedViewController == nil && Fuoco.registro.count > movimentiPrima }
        XCTAssertGreaterThan(Fuoco.registro.count, movimentiPrima,
                             "chiuse le impostazioni, il gioco non riporta il fuoco al pulsante d'origine: decide il sistema")
        // Dopo la correzione (incarico 28): il movimento è dichiarato come ritorno, e va sul pulsante.
        XCTAssertEqual(Fuoco.registro.last, .schermataChiusa)
        XCTAssertTrue(Fuoco.ultimoBersaglio === pulsante,
                      "il fuoco torna su «\(impostazioni)», non altrove: \(String(describing: Fuoco.ultimoBersaglio))")
    }

    /// Osservazione 6, seconda via: congedato il resoconto di uno scontro aperto da «Nuovo scontro di
    /// prova», il fuoco torna su quel comando dell'avvio, ricostruito al ritorno.
    func test_osservazione_6_congedato_il_resoconto_il_fuoco_torna_al_comando_d_origine() async throws {
        let ambiente = try Ambiente()
        let avvio = SchermataAvvio(ambiente: ambiente)
        let finestra = monta(avvio, in: Self.configurazioni[0])
        avvio.viewWillAppear(false)
        finestra.layoutIfNeeded()
        let nuovo = ambiente.testi.frase("avvio.nuovo_scontro").testo
        func pulsanteNuovo() -> UIButton? {
            LettoreAccessibilita.ordineDiLettura(radice: avvio.view)
                .first { LettoreAccessibilita.etichetta(di: $0) == nuovo } as? UIButton
        }
        try XCTUnwrap(pulsanteNuovo()).sendActions(for: .touchUpInside)
        try await attendi { avvio.presentedViewController is SchermataBattaglia }
        let battaglia = try XCTUnwrap(avvio.presentedViewController as? SchermataBattaglia)
        try await attendi { !battaglia.elementiPerProva.isEmpty }
        try await combattiFinoAllaFine(battaglia.partitaPerProva, ambiente: ambiente)
        var resoconto: SchermataResoconto?
        for _ in 0..<300 {
            if let r = battaglia.presentedViewController as? SchermataResoconto { resoconto = r; break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        try XCTUnwrap(resoconto).chiudiTuttoPerProva()
        try await attendi { avvio.presentedViewController == nil && Fuoco.registro.last == .schermataChiusa }
        XCTAssertEqual(Fuoco.registro.last, .schermataChiusa)
        XCTAssertTrue(Fuoco.ultimoBersaglio === pulsanteNuovo(),
                      "il fuoco torna su «\(nuovo)»: \(String(describing: Fuoco.ultimoBersaglio))")
    }
}
