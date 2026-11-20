import XCTest

/// L'esplorazione completa dell'interfaccia con VoiceOver (incarico 27, quarta parte).
///
/// NON è una prova del collaudo: vive nel bersaglio `WarSenseEsplorazione`, che lo schema
/// `WarSense` non esegue, e si lancia con `scripts/esplora-interfaccia.sh`. Non asserisce nulla
/// sul gioco: REGISTRA. Per ogni schermata fa due giri. Il primo con VoiceOver acceso, elemento
/// per elemento, con ciò che VoiceOver pronuncia nell'ordine (`XCUIDevice.voiceOverService`),
/// il punto in cui il fuoco atterra, e ciò che si sente dopo ogni azione. Il secondo senza
/// VoiceOver: l'albero d'accessibilità come lo vede la prova (un'istantanea), la verifica
/// automatica di Xcode, una schermata PNG. Poi confronta i due giri. Ogni rilievo esce come riga
/// «ESPLORA|<json>» nel registro della corsa e come allegato JSON del fascio dei risultati; lo
/// script li raccoglie in `Incarichi/27-2026-11-20-prodotti/esplorazione/`.
///
/// La configurazione arriva dall'ambiente (`TEST_RUNNER_ESPLORA_*` per xcodebuild):
/// ESPLORA_ORIENTAMENTO = verticale | orizzontale; ESPLORA_TESTO = predefinito | grande.
/// Le attivazioni con VoiceOver acceso passano per il gesto del giocatore: un tocco porta il
/// fuoco sull'elemento, il doppio tocco lo attiva. NON si possono guidare il rotore, il tocco
/// magico, lo strofinio e le azioni personalizzate: dove il percorso li richiederebbe, il rilievo
/// lo dichiara.
@available(iOS 27.0, *)  // il servizio VoiceOver delle prove esiste da iOS 27; l'app resta a iOS 17
@MainActor
final class EsplorazioneInterfacciaTest: XCTestCase {

    // MARK: - Configurazione

    private var orientamento: String { ProcessInfo.processInfo.environment["ESPLORA_ORIENTAMENTO"] ?? "verticale" }
    private var testo: String { ProcessInfo.processInfo.environment["ESPLORA_TESTO"] ?? "predefinito" }
    private var apparecchio: String { UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone" }
    private var configurazione: String { "\(apparecchio)-\(orientamento)-\(testo)" }

    private var app: XCUIApplication!
    private var rilievi: [[String: Any]] = []
    private var vo: XCUIVoiceOverService { XCUIDevice.shared.voiceOverService }

    override func setUp() {
        continueAfterFailure = true
        app = XCUIApplication()
        if testo == "grande" {
            // La preferenza di sistema della taglia del testo, passata all'avvio: non è un canale
            // dell'app, è l'impostazione che il giocatore sceglie in Impostazioni > Accessibilità.
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        XCUIDevice.shared.orientation = orientamento == "orizzontale" ? .landscapeLeft : .portrait
    }

    override func tearDown() {
        try? vo.disable()
        if let dati = try? JSONSerialization.data(withJSONObject: rilievi, options: [.prettyPrinted, .sortedKeys]) {
            let allegato = XCTAttachment(data: dati, uniformTypeIdentifier: "public.json")
            allegato.name = "rilievi-\(configurazione)-\(name.replacingOccurrences(of: " ", with: "_"))"
            allegato.lifetime = .keepAlways
            add(allegato)
        }
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Registrazione

    private func registra(_ voce: [String: Any]) {
        var v = voce
        v["configurazione"] = configurazione
        v["prova"] = name
        rilievi.append(v)
        if let d = try? JSONSerialization.data(withJSONObject: v, options: [.sortedKeys]),
           let s = String(data: d, encoding: .utf8) { print("ESPLORA|" + s) }
    }

    private func istantanea(_ nome: String) -> String {
        let n = "\(configurazione)-\(nome)"
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = n; a.lifetime = .keepAlways; add(a)
        return n
    }

    // MARK: - VoiceOver

    private func accendiVoiceOver() {
        if !vo.isEnabled { do { try vo.enable() } catch { registra(["evento": "errore", "dettaglio": "VoiceOver non si accende: \(error)"]) } }
    }
    private func spegniVoiceOver() { if vo.isEnabled { try? vo.disable() } }

    private func corrente() -> String {
        do { return try vo.currentSpeech().utterance } catch { return "<nessuna pronuncia: \(error.localizedDescription)>" }
    }

    /// Un passo del fuoco; `fine` è vero quando il fuoco non si è mosso (la pronuncia si ripete e
    /// il servizio ha atteso il suo tempo massimo: accertato nelle sonde, 2,3 s contro 0,5 s).
    private func passo(avanti: Bool, precedente: String?) -> (String, Bool) {
        let t = Date()
        let u: String
        do { u = try (avanti ? vo.moveForward() : vo.moveBackward()).utterance } catch { return ("<errore: \(error.localizedDescription)>", true) }
        let lento = Date().timeIntervalSince(t) > 1.5
        return (u, lento && u == precedente)
    }

    /// Il primo giro: dal punto in cui il fuoco è atterrato si risale all'inizio della schermata,
    /// poi la si percorre tutta in avanti, elemento per elemento.
    private func giroVoiceOver(_ schermata: String, massimo: Int = 260) -> [String] {
        accendiVoiceOver()
        Thread.sleep(forTimeInterval: 0.8)
        let atterraggio = corrente()
        var ultima: String? = atterraggio
        var salita = 0
        while salita < massimo {
            let (u, fine) = passo(avanti: false, precedente: ultima)
            if fine { break }
            ultima = u; salita += 1
        }
        var pronunce: [String] = [corrente()]
        ultima = pronunce[0]
        while pronunce.count < massimo {
            let (u, fine) = passo(avanti: true, precedente: ultima)
            if fine { break }
            pronunce.append(u); ultima = u
        }
        registra(["schermata": schermata, "giro": "voiceover", "atterraggio_del_fuoco": atterraggio,
                  "pronunce": pronunce, "numero_pronunce": pronunce.count,
                  "troncato": pronunce.count >= massimo])
        return pronunce
    }

    /// Porta il fuoco di VoiceOver sull'elemento scorrendo, come il giocatore, e lo attiva col tocco
    /// diretto. Restituisce ciò che si sente subito e dopo un secondo e mezzo: se cambia senza che
    /// l'utente abbia fatto nulla, il fuoco si è spostato da solo o è arrivato un annuncio.
    @discardableResult
    private func attivaConVoiceOver(_ elemento: XCUIElement, _ azione: String, schermata: String) -> [String: Any] {
        accendiVoiceOver()
        guard elemento.waitForExistence(timeout: 5) else {
            let v: [String: Any] = ["schermata": schermata, "azione": azione, "esito": "elemento non trovato"]
            registra(v); return v
        }
        // Il fuoco si porta sull'elemento come lo porta il giocatore, uno scorrimento alla volta,
        // finché la pronuncia comincia con la sua etichetta. Il tocco sintetico con VoiceOver acceso
        // NON porta il fuoco in modo affidabile (corsa di prova dell'incarico 27: il tocco su
        // «Impostazioni» seguito dal doppio tocco ha aperto la mappa media).
        // Un tocco singolo con VoiceOver acceso porta il fuoco sull'elemento, come l'esplorazione al
        // tatto: si registra ciò che VoiceOver vi pronuncia, poi il doppio tocco lo attiva.
        elemento.tap()
        Thread.sleep(forTimeInterval: 0.6)
        let sulFuoco = corrente()
        // L'attivazione è il DOPPIO TOCCO SULL'ELEMENTO, come chi esplora al tatto: con VoiceOver
        // acceso un tocco sintetico sposta il fuoco sull'elemento toccato e non lo attiva, e un doppio
        // tocco attiva l'elemento su cui il primo tocco ha portato il fuoco. Accertato nelle corse di
        // prova dell'incarico 27: il doppio tocco al centro dello schermo attivava il pulsante del
        // centro, il tocco singolo su «Impostazioni» non lo apriva.
        elemento.doubleTap()
        Thread.sleep(forTimeInterval: 0.4)
        let subito = corrente()
        Thread.sleep(forTimeInterval: 1.5)
        let dopo = corrente()
        let v: [String: Any] = ["schermata": schermata, "giro": "voiceover", "azione": azione,
                                "fuoco_prima_dell_attivazione": sulFuoco, "pronuncia_subito_dopo": subito,
                                "pronuncia_dopo_1_5_s": dopo, "fuoco_mosso_da_solo": subito != dopo]
        registra(v)
        return v
    }

    /// Porta il fuoco di VoiceOver sull'elemento la cui pronuncia comincia con `etichetta`: prima in
    /// avanti fino alla fine della schermata, poi indietro fino all'inizio.
    private func portaIlFuoco(su etichetta: String, massimo: Int = 200) -> Bool {
        func combacia(_ u: String) -> Bool { u.hasPrefix(etichetta) }
        if combacia(corrente()) { return true }
        var ultima: String? = corrente()
        for _ in 0..<massimo {
            let (u, fine) = passo(avanti: true, precedente: ultima)
            if combacia(u) { return true }
            if fine { break }
            ultima = u
        }
        ultima = corrente()
        for _ in 0..<massimo {
            let (u, fine) = passo(avanti: false, precedente: ultima)
            if combacia(u) { return true }
            if fine { break }
            ultima = u
        }
        return false
    }

    // MARK: - Il giro senza VoiceOver

    /// L'albero d'accessibilità come lo vede la prova, in una sola istantanea.
    private func elementiVisibili() -> [[String: Any]] {
        guard let radice = try? app.snapshot() else { return [] }
        let finestra = app.windows.firstMatch.frame
        var esito: [[String: Any]] = []
        func scendi(_ n: XCUIElementSnapshot) {
            let tipo = n.elementType
            let interessante = !n.label.isEmpty || [.button, .cell, .switch, .slider, .segmentedControl, .textField].contains(tipo)
            if interessante, tipo != .application, tipo != .window, tipo != .other || !n.label.isEmpty {
                let f = n.frame
                let dentro = finestra.intersects(f) && f.width > 0 && f.height > 0
                esito.append(["tipo": nomeTipo(tipo), "etichetta": n.label,
                              "valore": (n.value as? String) ?? "", "identificatore": n.identifier,
                              "abilitato": n.isEnabled, "selezionato": n.isSelected,
                              "cornice": "\(Int(f.minX)),\(Int(f.minY)),\(Int(f.width))x\(Int(f.height))",
                              "sullo_schermo": dentro,
                              "bersaglio_almeno_44": f.width >= 44 && f.height >= 44])
            }
            for c in n.children { scendi(c) }
        }
        scendi(radice)
        return esito
    }

    private func nomeTipo(_ t: XCUIElement.ElementType) -> String {
        switch t {
        case .button: return "pulsante"
        case .staticText: return "testo"
        case .cell: return "cella"
        case .switch: return "interruttore"
        case .slider: return "cursore"
        case .segmentedControl: return "segmenti"
        case .other: return "altro"
        case .scrollView: return "scorrevole"
        case .table: return "tabella"
        case .collectionView: return "collezione"
        case .image: return "immagine"
        case .navigationBar: return "barra"
        case .textField: return "campo"
        default: return "tipo-\(t.rawValue)"
        }
    }

    private func giroVisivo(_ schermata: String, pronunce: [String]) {
        spegniVoiceOver()
        Thread.sleep(forTimeInterval: 0.5)
        let elementi = elementiVisibili()
        var verifica: [String] = []
        do {
            try app.performAccessibilityAudit(for: .all) { rilievo in
                verifica.append("\(rilievo.compactDescription) — \(rilievo.element?.label ?? "senza elemento")")
                return true
            }
        } catch { verifica.append("verifica non eseguita: \(error.localizedDescription)") }
        // Il confronto fra ciò che si vede e ciò che si sente: un elemento con etichetta sullo
        // schermo che nessuna pronuncia contiene, e una pronuncia che non comincia con alcuna
        // etichetta dell'albero.
        let etichette = elementi.compactMap { e -> String? in
            guard (e["sullo_schermo"] as? Bool) == true, let l = e["etichetta"] as? String, !l.isEmpty else { return nil }
            return l
        }
        let nonSentiti = pronunce.isEmpty ? [] : Array(Set(etichette.filter { l in !pronunce.contains { $0.contains(l) } })).sorted()
        let nonVisti = pronunce.filter { p in !etichette.contains { p.hasPrefix($0) || p.contains($0) } }
        let segnaposto = elementi.compactMap { e -> String? in
            let l = (e["etichetta"] as? String) ?? ""
            return (l.range(of: "^[a-z_]+(\\.[a-z_]+)+$", options: .regularExpression) != nil || l.contains("⟦")) ? l : nil
        }
        let senzaEtichetta = elementi.filter { e in
            ["pulsante", "interruttore", "cursore", "segmenti", "cella"].contains(e["tipo"] as? String ?? "")
                && ((e["etichetta"] as? String) ?? "").isEmpty }.count
        registra(["schermata": schermata, "giro": "vista", "istantanea": istantanea(schermata),
                  "elementi": elementi, "numero_elementi": elementi.count,
                  "verifica_automatica": verifica,
                  "in_vista_ma_non_sentiti": nonSentiti, "sentiti_ma_non_nell_albero": nonVisti,
                  "etichette_come_chiavi": segnaposto, "controlli_senza_etichetta": senzaEtichetta])
    }

    /// I due giri di una schermata.
    private func esplora(_ schermata: String, massimo: Int = 260) {
        let pronunce = giroVoiceOver(schermata, massimo: massimo)
        giroVisivo(schermata, pronunce: pronunce)
    }

    private func pulsante(_ etichetta: String) -> XCUIElement { app.buttons[etichetta].firstMatch }
    private func qualunque(_ predicato: String, _ arg: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: predicato, arg)).firstMatch
    }

    /// Attiva SENZA VoiceOver un pulsante e registra che cosa compare: il secondo giro delle azioni.
    private func toccaSenzaVoce(_ etichetta: String, schermata: String, attesa: String? = nil) -> Bool {
        spegniVoiceOver()
        let p = pulsante(etichetta)
        guard p.waitForExistence(timeout: 5) else {
            registra(["schermata": schermata, "giro": "vista", "azione": etichetta, "esito": "pulsante non trovato"]); return false
        }
        let raggiungibile = p.isHittable
        p.tap()
        var comparso: Bool? = nil
        if let attesa { comparso = qualunque("label CONTAINS %@", attesa).waitForExistence(timeout: 8) }
        registra(["schermata": schermata, "giro": "vista", "azione": etichetta, "agganciabile": raggiungibile,
                  "atteso": attesa ?? "", "comparso": comparso as Any, "istantanea": istantanea("\(schermata)-dopo-\(etichetta)")])
        return comparso ?? true
    }

    // MARK: - I percorsi

    /// Schermata d'avvio, impostazioni, apprendimento dei segnali.
    func test_1_avvio_impostazioni_apprendimento() throws {
        app.launch()
        XCTAssertTrue(app.buttons.firstMatch.waitForExistence(timeout: 20))
        esplora("avvio")

        attivaConVoiceOver(pulsante("Impostazioni"), "apri Impostazioni", schermata: "avvio")
        esplora("impostazioni")
        // Il secondo giro: ogni controllo attivato una volta e rimesso com'era.
        spegniVoiceOver()
        for i in 0..<app.switches.count {
            let s = app.switches.element(boundBy: i)
            let prima = (s.value as? String) ?? ""
            s.tap(); let dopo = (s.value as? String) ?? ""; s.tap()
            registra(["schermata": "impostazioni", "giro": "vista", "azione": "interruttore \(s.label)",
                      "valore_prima": prima, "valore_dopo": dopo, "cambia": prima != dopo])
        }
        for i in 0..<app.segmentedControls.count {
            let c = app.segmentedControls.element(boundBy: i)
            let bottoni = c.buttons
            registra(["schermata": "impostazioni", "giro": "vista", "azione": "segmenti \(c.label)", "voci": bottoni.count])
            if bottoni.count > 1 { bottoni.element(boundBy: 0).tap(); bottoni.element(boundBy: bottoni.count / 2).tap() }
        }
        _ = istantanea("impostazioni-dopo-i-controlli")
        attivaConVoiceOver(pulsante("Chiudi il pannello"), "chiudi Impostazioni", schermata: "impostazioni")
        spegniVoiceOver()

        attivaConVoiceOver(pulsante("Suoni e vibrazioni del gioco"), "apri l'apprendimento dei segnali", schermata: "avvio")
        esplora("apprendimento-dei-segnali")
        // Ogni voce si attiva per risentirla: con VoiceOver si attiva la prima e l'ultima della
        // schermata (i pulsanti della schermata d'avvio, sotto, restano nell'albero e si scartano).
        let sentite = rilievi.last { ($0["schermata"] as? String) == "apprendimento-dei-segnali" && $0["pronunce"] != nil }?["pronunce"] as? [String] ?? []
        let voci = app.buttons.allElementsBoundByIndex.filter { b in
            b.label != "Chiudi il pannello" && sentite.contains { $0.hasPrefix(b.label) } }
        if let prima = voci.first { attivaConVoiceOver(prima, "risenti «\(prima.label)»", schermata: "apprendimento-dei-segnali") }
        if let ultima = voci.last, voci.count > 1 { attivaConVoiceOver(ultima, "risenti «\(ultima.label)»", schermata: "apprendimento-dei-segnali") }
        attivaConVoiceOver(pulsante("Chiudi il pannello"), "chiudi l'apprendimento", schermata: "apprendimento-dei-segnali")
        spegniVoiceOver()
        _ = istantanea("avvio-al-ritorno")
    }

    /// Battaglia nuova: deck, selezione, piazzamento, annullamento, azzeramento, fine del turno,
    /// designazione; poi ripresa dopo il riavvio; poi la resa e il resoconto.
    func test_2_battaglia_nuova_ripresa_e_resoconto() throws {
        app.launch()
        XCTAssertTrue(app.buttons.firstMatch.waitForExistence(timeout: 20))
        attivaConVoiceOver(pulsante("Nuovo scontro di prova"), "apri lo scontro di prova", schermata: "avvio")
        XCTAssertTrue(qualunque("label == %@", "Riserve da schierare").waitForExistence(timeout: 15))
        esplora("battaglia-apertura")

        let tessera = qualunque("label == %@", "fanteria leggera")
        attivaConVoiceOver(tessera, "seleziona la tessera «fanteria leggera»", schermata: "battaglia")
        let cella = qualunque("label BEGINSWITH %@", "riga 10, cella 1")
        attivaConVoiceOver(cella, "piazza in riga 10, cella 1", schermata: "battaglia")
        attivaConVoiceOver(pulsante("Annulla l'ultima operazione"), "annulla", schermata: "battaglia")
        attivaConVoiceOver(tessera, "riseleziona la tessera", schermata: "battaglia")
        attivaConVoiceOver(cella, "ripiazza in riga 10, cella 1", schermata: "battaglia")
        attivaConVoiceOver(pulsante("Azzera lo schieramento del turno"), "azzera", schermata: "battaglia")
        attivaConVoiceOver(tessera, "seleziona di nuovo", schermata: "battaglia")
        attivaConVoiceOver(cella, "piazza di nuovo", schermata: "battaglia")
        esplora("battaglia-dopo-il-piazzamento")
        attivaConVoiceOver(pulsante("Fine del turno"), "fine del turno", schermata: "battaglia")
        Thread.sleep(forTimeInterval: 3)
        // La designazione: il pannello della cella occupata (attivazione della cella).
        attivaConVoiceOver(qualunque("label BEGINSWITH %@", "riga 10, cella 1"), "apri il pannello della cella occupata", schermata: "battaglia")
        if pulsante("Chiudi il pannello").waitForExistence(timeout: 5) {
            esplora("battaglia-pannello-della-cella")
            let designa = qualunque("label BEGINSWITH %@", "Scegli la destinazione")
            if designa.exists {
                attivaConVoiceOver(designa, "avvia la designazione del movimento", schermata: "battaglia-pannello-della-cella")
                attivaConVoiceOver(qualunque("label BEGINSWITH %@", "riga 9, cella 1"), "designa riga 9, cella 1", schermata: "battaglia")
            } else if pulsante("Chiudi il pannello").exists {
                attivaConVoiceOver(pulsante("Chiudi il pannello"), "chiudi il pannello", schermata: "battaglia-pannello-della-cella")
            }
        } else {
            registra(["schermata": "battaglia", "evento": "il pannello della cella occupata non si è aperto"])
        }
        esplora("battaglia-dopo-il-primo-turno")

        // La ripresa: l'app si chiude e si riapre, la battaglia salvata si riprende.
        spegniVoiceOver()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons.firstMatch.waitForExistence(timeout: 20))
        esplora("avvio-con-partite-salvate")
        attivaConVoiceOver(pulsante("Riprendi lo scontro in corso"), "riprendi lo scontro", schermata: "avvio")
        _ = qualunque("label == %@", "Riserve da schierare").waitForExistence(timeout: 15)
        esplora("battaglia-ripresa")

        attivaConVoiceOver(pulsante("Dichiara la resa"), "dichiara la resa", schermata: "battaglia-ripresa")
        // La ritirata combattuta può durare più turni: si chiude il turno finché arriva il resoconto.
        for _ in 0..<30 where !qualunque("label == %@", "Resoconto della battaglia").exists {
            spegniVoiceOver()
            if pulsante("Fine del turno").exists && pulsante("Fine del turno").isHittable { pulsante("Fine del turno").tap() }
            Thread.sleep(forTimeInterval: 1.0)
        }
        if qualunque("label == %@", "Resoconto della battaglia").waitForExistence(timeout: 10) {
            esplora("resoconto-della-battaglia")
            attivaConVoiceOver(pulsante("Torna all'inizio"), "torna all'inizio", schermata: "resoconto-della-battaglia")
            _ = app.buttons.firstMatch.waitForExistence(timeout: 10)
            esplora("avvio-dopo-il-resoconto")
        } else {
            registra(["schermata": "battaglia-ripresa", "evento": "il resoconto non è comparso dopo la resa e trenta fini del turno"])
            _ = istantanea("battaglia-senza-resoconto")
        }
    }

    /// La campagna su un formato: mappa, registro, pannello del gruppo, marcia, esplorazione,
    /// imboscata, divisione, chiusura della giornata, passaggio alla battaglia, resa, resoconto,
    /// ripiegamento, ritorno in campagna.
    private func campagna(_ formato: String) {
        app.launch()
        XCTAssertTrue(app.buttons.firstMatch.waitForExistence(timeout: 20))
        attivaConVoiceOver(pulsante("Nuova campagna, mappa \(formato)"), "apri la campagna, mappa \(formato)", schermata: "avvio")
        _ = qualunque("label BEGINSWITH %@", "riga 1, casella 1").waitForExistence(timeout: 15)
        let m = "mappa-\(formato)"
        esplora(m, massimo: 320)

        attivaConVoiceOver(pulsante("Registro della campagna"), "apri il registro", schermata: m)
        esplora("registro-\(formato)")
        attivaConVoiceOver(pulsante("Chiudi il registro"), "chiudi il registro", schermata: "registro-\(formato)")

        // Il pannello di un gruppo in attesa.
        let inAttesa = qualunque("label CONTAINS %@", "in attesa")
        attivaConVoiceOver(inAttesa, "apri il pannello del primo gruppo in attesa", schermata: m)
        if pulsante("Chiudi il pannello").waitForExistence(timeout: 5) {
            esplora("pannello-gruppo-\(formato)")
            let marcia = qualunque("label BEGINSWITH %@", "Marcia")
            if marcia.exists {
                attivaConVoiceOver(marcia, "avvia la designazione della marcia", schermata: "pannello-gruppo-\(formato)")
                esplora("designazione-marcia-\(formato)", massimo: 320)
                // La prima casella che si annuncia disponibile per la marcia.
                let meta = qualunque("label CONTAINS %@", "giorn")
                attivaConVoiceOver(meta, "ordina la marcia verso la prima casella disponibile", schermata: "designazione-marcia-\(formato)")
            } else if pulsante("Chiudi il pannello").exists {
                attivaConVoiceOver(pulsante("Chiudi il pannello"), "chiudi il pannello", schermata: "pannello-gruppo-\(formato)")
            }
        } else {
            registra(["schermata": m, "evento": "il pannello del gruppo in attesa non si è aperto"])
        }

        // Le azioni per categoria: esplorazione, agguato, divisione — sul gruppo in attesa
        // successivo che le offre.
        for (voce, nome) in [("Esplora la zona", "esplorazione"), ("Mettiti in agguato", "imboscata"), ("Dividi", "divisione")] {
            var fatto = false
            for i in 0..<6 where !fatto {
                let gruppi = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "in attesa"))
                guard i < gruppi.count else { break }
                attivaConVoiceOver(gruppi.element(boundBy: i), "apri un pannello per cercare «\(voce)»", schermata: m)
                let azione = qualunque("label BEGINSWITH %@", voce)
                if azione.waitForExistence(timeout: 3) {
                    attivaConVoiceOver(azione, voce, schermata: "pannello-\(nome)-\(formato)")
                    if nome == "divisione", qualunque("label BEGINSWITH %@", "Dividi ").waitForExistence(timeout: 5) {
                        esplora("divisione-\(formato)")
                        attivaConVoiceOver(pulsante("Annulla la divisione"), "annulla la divisione", schermata: "divisione-\(formato)")
                    }
                    fatto = true
                } else if pulsante("Chiudi il pannello").exists {
                    attivaConVoiceOver(pulsante("Chiudi il pannello"), "chiudi il pannello", schermata: m)
                }
            }
            if !fatto { registra(["schermata": m, "evento": "nessun gruppo in attesa offriva «\(voce)»"]) }
        }
        esplora("\(m)-dopo-gli-ordini", massimo: 320)

        // La chiusura della giornata col tasto, ripetuta finché nasce una battaglia in sospeso.
        var giorni = 0
        while giorni < 40, !qualunque("label CONTAINS %@", "attaglia in sospeso").exists {
            guard pulsante("Chiudi la giornata").exists else {
                registra(["schermata": m, "evento": "il tasto «Chiudi la giornata» non esiste"]); break
            }
            if giorni == 0 { attivaConVoiceOver(pulsante("Chiudi la giornata"), "chiudi la giornata", schermata: m) }
            else { spegniVoiceOver(); pulsante("Chiudi la giornata").tap(); Thread.sleep(forTimeInterval: 0.8) }
            giorni += 1
        }
        registra(["schermata": m, "evento": "giornate chiuse col tasto prima della battaglia", "giornate": giorni])
        let contesa = qualunque("label CONTAINS %@", "attaglia in sospeso")
        guard contesa.exists else {
            registra(["schermata": m, "evento": "nessuna battaglia in sospeso in \(giorni) giornate"]); _ = istantanea("\(m)-senza-battaglia"); return
        }
        esplora("\(m)-con-battaglia-in-sospeso", massimo: 320)
        attivaConVoiceOver(contesa, "apri il pannello della casella contesa", schermata: m)
        let apri = pulsante("Apri la battaglia")
        guard apri.waitForExistence(timeout: 5) else {
            registra(["schermata": m, "evento": "il pannello della casella contesa non offre «Apri la battaglia»"]); return
        }
        esplora("pannello-casella-contesa-\(formato)")
        attivaConVoiceOver(apri, "apri la battaglia", schermata: "pannello-casella-contesa-\(formato)")
        _ = qualunque("label == %@", "Riserve da schierare").waitForExistence(timeout: 15)
        esplora("battaglia-di-campagna-\(formato)")
        attivaConVoiceOver(pulsante("Dichiara la resa"), "dichiara la resa", schermata: "battaglia-di-campagna-\(formato)")
        for _ in 0..<30 where !qualunque("label == %@", "Resoconto della battaglia").exists {
            spegniVoiceOver()
            if pulsante("Fine del turno").exists && pulsante("Fine del turno").isHittable { pulsante("Fine del turno").tap() }
            Thread.sleep(forTimeInterval: 1.0)
        }
        guard qualunque("label == %@", "Resoconto della battaglia").waitForExistence(timeout: 10) else {
            registra(["schermata": "battaglia-di-campagna-\(formato)", "evento": "il resoconto non è comparso"]); return
        }
        esplora("resoconto-di-campagna-\(formato)")
        let torna = app.buttons.allElementsBoundByIndex.first { $0.label.hasPrefix("Torna") }
        if let torna { attivaConVoiceOver(torna, "congeda il resoconto (\(torna.label))", schermata: "resoconto-di-campagna-\(formato)") }
        if qualunque("label == %@", "Scegli dove ripiegare").waitForExistence(timeout: 8) {
            esplora("ripiegamento-\(formato)")
            attivaConVoiceOver(qualunque("label BEGINSWITH %@", "In riga"), "scegli la prima casella di ripiegamento", schermata: "ripiegamento-\(formato)")
        } else {
            registra(["schermata": "ritorno-\(formato)", "evento": "nessuna scelta di ripiegamento offerta"])
        }
        _ = qualunque("label BEGINSWITH %@", "riga 1, casella 1").waitForExistence(timeout: 15)
        esplora("\(m)-al-ritorno", massimo: 320)
    }

    func test_3_campagna_mappa_piccola() throws { campagna("piccola") }
    func test_4_campagna_mappa_media() throws { campagna("media") }
    func test_5_campagna_mappa_grande() throws { campagna("grande") }
}
