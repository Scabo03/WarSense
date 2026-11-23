import XCTest
import Dati
import Motore
import Sessione
@testable import WarSense

/// UN ANNO INTERO DEL REGNO attraverso l'interfaccia, coi valori veri (incarico 30): la patria, la
/// campagna dell'anno giocata giornata per giornata dal pannello dei gruppi, le battaglie aperte e
/// combattute sulla schermata di battaglia, la conclusione — per annientamento o per l'inverno — con
/// la sua dichiarazione, l'inverno con le leve ordinate dai pulsanti, la primavera, la campagna del
/// secondo anno con le reclute sulla mappa, e la ripresa dal giornale. È la prova che l'anello si
/// chiude giocando, e non soltanto al Motore.
@MainActor
final class AnnoDelRegnoTest: XCTestCase {

    private var finestra: UIWindow?

    override func tearDown() async throws {
        if let f = finestra {
            var catena: [UIViewController] = []
            var presentata = f.rootViewController?.presentedViewController
            while let p = presentata { catena.append(p); presentata = p.presentedViewController }
            for p in catena.reversed() { p.dismiss(animated: false) }
            f.isHidden = true
            f.rootViewController = nil
        }
        finestra = nil
        try await super.tearDown()
    }

    private func attendi(_ che: String, _ condizione: () -> Bool, giri: Int = 600,
                         file: StaticString = #filePath, line: UInt = #line) async throws {
        for _ in 0..<giri where !condizione() { try await Task.sleep(nanoseconds: 20_000_000) }
        XCTAssertTrue(condizione(), "attesa scaduta: \(che)", file: file, line: line)
    }

    private func lettura(_ schermata: UIViewController) -> [String] {
        schermata.view.layoutIfNeeded()
        return LettoreAccessibilita.ordineDiLettura(radice: schermata.view as Any)
            .map { LettoreAccessibilita.etichetta(di: $0) }
    }

    private func premi(_ etichetta: String, in schermata: UIViewController,
                       file: StaticString = #filePath, line: UInt = #line) throws {
        let nodo = try XCTUnwrap(LettoreAccessibilita.ordineDiLettura(radice: schermata.view as Any)
            .first { LettoreAccessibilita.etichetta(di: $0) == etichetta } as? UIControl,
                                 "manca il comando «\(etichetta)» in \(lettura(schermata))", file: file, line: line)
        nodo.sendActions(for: .touchUpInside)
    }

    /// Gioca la campagna aperta sulla mappa fino alla sua conclusione: ogni battaglia in sospeso si
    /// apre e si combatte dalla catena dello schermo; ogni gruppo in attesa riceve un ordine valido
    /// — un armato marcia verso l'armato avversario più vicino, gli altri restano. Ritorna quante
    /// battaglie sono state combattute.
    private func giocaLaCampagna(_ mappa: SchermataMappaCampagna, ambiente: Ambiente) async throws -> Int {
        let motore = mappa.motorePerProva
        let guida = PassaggioBattagliaInterfacciaTest()
        func dist(_ a: Cella, _ b: Cella) -> Int { abs(a.riga - b.riga) + abs(a.colonna - b.colonna) }
        var battaglie = 0
        var passi = 0
        while let s = mappa.statoPerProva, s.conclusione == nil {
            passi += 1
            guard passi < 4000 else { XCTFail("la campagna non si conclude: giorno \(s.giorno)"); break }
            if let b = s.battaglieInSospeso.first {
                try await guida.apriCombattiEtornaDalloSchermo(mappa, battaglia: b, ambiente: ambiente)
                battaglie += 1
                if mappa.statoPerProva?.battaglieInSospeso.contains(where: { $0.identificatore == b.identificatore }) == true {
                    XCTFail("la battaglia in riga \(b.casella.riga) casella \(b.casella.colonna) è conclusa ma resta in sospeso")
                    break
                }
                continue
            }
            guard let g = s.gruppiInAttesa(di: .giocatore).first else {
                // Nessuno attende e la giornata non si è chiusa: la chiude il tasto del giocatore.
                mappa.chiudiGiornataPerProva()
                try await Task.sleep(nanoseconds: 60_000_000)
                continue
            }
            func valido(_ c: ComandoCampagna) -> Bool { motore.valida(c, parte: .giocatore, stato: s).eValido }
            var ordine: ComandoCampagna = .sostaConRaccolta(gruppo: g.id)
            if valido(.presidio(gruppo: g.id)) { ordine = .presidio(gruppo: g.id) }
            if g.categoria.eArmata,
               let bersaglio = s.gruppi(di: .avversario).filter({ $0.categoria.eArmata })
                .min(by: { dist(g.posizione, $0.posizione) < dist(g.posizione, $1.posizione) }) {
                let dest = VistaCampagna(motore: motore, stato: s, parte: .giocatore).destinazioniValide(per: g.id)
                if let meta = dest.first(where: { $0 == bersaglio.posizione })
                    ?? dest.min(by: { dist($0, bersaglio.posizione) < dist($1, bersaglio.posizione) }) {
                    let marcia = ComandoCampagna.marcia(gruppo: g.id, a: meta,
                                                        giorni: motore.costoInGiorni(da: g.posizione, a: meta, stato: s))
                    if valido(marcia) { ordine = marcia }
                }
            }
            await mappa.eseguiPerProva(ordine)
        }
        return battaglie
    }

    func test_un_anno_intero_del_regno_dalla_patria_alla_seconda_primavera() async throws {
        let ambiente = try Ambiente()
        let giornateOperative = ambiente.valoriRegno.giornateOperative
        let patria = SchermataPatria(partita: try await PartitaRegno(nuovo: ambiente))
        let f = UIWindow(frame: CGRect(x: 0, y: 0, width: 420, height: 912))
        f.rootViewController = patria
        f.makeKeyAndVisible()
        patria.loadViewIfNeeded()
        finestra = f
        try await attendi("la patria si carica") { self.lettura(patria).contains("Apri la campagna") }
        let formazioniIniziali = await patria.partitaPerProva.stato.forze.numeroDiUnita

        // 1. La campagna dell'anno, sul fronte del guado.
        await patria.apriLaCampagnaPerProva(sul: "guado")
        try await attendi("si entra nel fronte") { patria.presentedViewController is SchermataMappaCampagna }
        let mappa = try XCTUnwrap(patria.presentedViewController as? SchermataMappaCampagna)
        try await attendi("la mappa si carica") { !mappa.elementiPerProva.isEmpty }
        XCTAssertEqual(mappa.statoPerProva?.gruppi(di: .giocatore).count, formazioniIniziali)
        let battaglie = try await giocaLaCampagna(mappa, ambiente: ambiente)
        let conclusione = try XCTUnwrap(mappa.statoPerProva?.conclusione, "la campagna si conclude")
        XCTAssertLessThanOrEqual(conclusione.giorno, giornateOperative)

        // 2. La dichiarazione di conclusione, in patria.
        try await attendi("compare la dichiarazione di conclusione") { patria.presentedViewController is SchermataResoconto }
        let dichiarazione = try XCTUnwrap(patria.presentedViewController as? SchermataResoconto)
        dichiarazione.loadViewIfNeeded()
        let voci = lettura(dichiarazione)
        XCTAssertEqual(voci.first, "Campagna conclusa")
        XCTAssertEqual(voci.last, "Torna in patria")
        XCTAssertEqual(voci.count, 7, "\(voci)")
        dichiarazione.chiudiTuttoPerProva()
        try await attendi("si torna in patria") { patria.presentedViewController == nil }
        var stato = await patria.partitaPerProva.stato
        let esito = try XCTUnwrap(stato.campagna.esito)
        XCTAssertEqual(esito.modo, conclusione.modo)
        XCTAssertEqual(esito.battaglieVinte + esito.battagliePerse, battaglie,
                       "le battaglie combattute sullo schermo sono quelle che l'esito porta in patria")
        let rientrate = stato.forze.numeroDiUnita

        // 3. L'inverno: le leve dai pulsanti, finché una voce si può pagare; poi le quattro schermate.
        try premi("Attendi l'inverno", in: patria)
        try await attendi("arriva l'inverno") { self.lettura(patria).contains("Anno 1, inverno, schermata 1 di 4") }
        var leve = 0
        while leve < 40 {
            var ordinata = false
            // Le leve: le voci che non chiedono un reparto su cui agire (le altre le percorre
            // `SecondaTappaDelRegnoTest`).
            for voce in ambiente.valoriRegno.voci where !voce.effetto.richiedeBersaglio {
                guard await patria.partitaPerProva.anteprima(.ordina(voce: voce.identificatore, bersaglio: nil)).eValido else { continue }
                let pulsante = try XCTUnwrap(patria.corpoPerProva.arrangedSubviews
                    .first { $0.accessibilityIdentifier == "voce." + voce.identificatore } as? UIControl)
                let prima = await patria.partitaPerProva.stato.lavori.count
                pulsante.sendActions(for: .touchUpInside)
                for _ in 0..<200 {
                    if await patria.partitaPerProva.stato.lavori.count > prima { break }
                    try await Task.sleep(nanoseconds: 10_000_000)
                }
                leve += 1
                ordinata = true
            }
            if !ordinata { break }
        }
        XCTAssertGreaterThan(leve, 0, "con l'entrata dell'anno almeno una leva si può pagare")
        for stazione in 2...MomentoDellAnno.stazioniInvernali {
            try premi("Prosegui alla schermata \(stazione) di 4", in: patria)
            try await attendi("si apre la schermata \(stazione)") {
                self.lettura(patria).contains("Anno 1, inverno, schermata \(stazione) di 4")
            }
        }
        // Le leve maturano in stagioni diverse secondo la durata (01 §5.9.1.4): le reclute formano
        // una formazione nuova per ciascuna stagione, con un reparto per leva (incarico 31).
        let stagioni = Set(await patria.partitaPerProva.stato.lavori.map(\.pronto))
        let nomiPrima = await patria.partitaPerProva.stato.forze.formazioni.map(\.nome)
        try premi("Prosegui alla primavera", in: patria)
        try await attendi("comincia la primavera") { self.lettura(patria).contains("Anno 2, primavera") }
        stato = await patria.partitaPerProva.stato
        XCTAssertEqual(stato.forze.formazioni.count, rientrate + stagioni.count,
                       "le reclute sono una formazione nuova per ciascuna stagione in cui maturano")
        let nuove = stato.forze.formazioni.suffix(stagioni.count)
        XCTAssertEqual(nuove.reduce(0) { $0 + $1.composizione.count }, leve, "un reparto per leva")
        XCTAssertEqual(Set(nuove.compactMap(\.arrivo)), stagioni, "ciascuna dichiara la stagione in cui entra")
        XCTAssertEqual(Array(stato.forze.formazioni.map(\.nome).prefix(nomiPrima.count)), nomiPrima,
                       "le formazioni che c'erano conservano il nome e il posto")

        // 4. La campagna del secondo anno porta al fronte anche le reclute.
        await patria.apriLaCampagnaPerProva(sul: "istmo")
        try await attendi("si entra nel fronte del secondo anno") { patria.presentedViewController is SchermataMappaCampagna }
        let seconda = try XCTUnwrap(patria.presentedViewController as? SchermataMappaCampagna)
        try await attendi("la mappa del secondo anno si carica") { !seconda.elementiPerProva.isEmpty }
        XCTAssertEqual(seconda.statoPerProva?.calendario?.anno, 2)
        // Sul fronte, dalla prima giornata: chi c'era e le reclute pronte in primavera, ciascuno col
        // nome che ha in patria; le reclute che maturano più tardi sono arrivi in attesa.
        let subito = stato.forze.formazioni.filter { $0.arrivo == nil || $0.arrivo == .primavera }.map(\.nome)
        let dopo = stato.forze.formazioni.filter { $0.arrivo == .estate || $0.arrivo == .autunno }.map(\.nome)
        XCTAssertEqual(Set(seconda.statoPerProva?.gruppi(di: .giocatore).map(\.nome) ?? []), Set(subito))
        XCTAssertEqual(seconda.statoPerProva?.arriviInAttesa?.map(\.nome) ?? [], dopo)

        // 5. La ripresa dal giornale dà lo stesso regno.
        let impronta = await patria.partitaPerProva.stato.impronta()
        let ripreso = await (try PartitaRegno(riprendi: ambiente)).stato
        XCTAssertEqual(ripreso.impronta(), impronta)

        print("ANNO-DEL-REGNO-30 fronte=guado conclusione=\(conclusione.modo.rawValue) vincitore=\(conclusione.vincitore?.rawValue ?? "nessuno") giornate=\(conclusione.giorno) battaglie=\(battaglie) vinte=\(esito.battaglieVinte) perse=\(esito.battagliePerse) formazioni_partite=\(formazioniIniziali) rientrate=\(rientrate) leve=\(leve) formazioni_anno_2=\(stato.forze.formazioni.count)")
    }

    /// La battaglia di una campagna del regno vive TRE slot sotto: regno, campagna, battaglia
    /// (RDA-162). Chiusa l'applicazione a battaglia aperta, il regno si riprende identico, la
    /// campagna è quella, la battaglia si riprende identica dal proprio slot; combattuta, l'esito
    /// torna nella campagna e sopravvive a un altro riavvio (05 §6.1, §6.3).
    func test_la_battaglia_di_una_campagna_del_regno_si_riprende_dopo_un_riavvio() async throws {
        let ambiente = try Ambiente()
        let patria = SchermataPatria(partita: try await PartitaRegno(nuovo: ambiente))
        let f = UIWindow(frame: CGRect(x: 0, y: 0, width: 420, height: 912))
        f.rootViewController = patria
        f.makeKeyAndVisible()
        patria.loadViewIfNeeded()
        finestra = f
        try await attendi("la patria si carica") { self.lettura(patria).contains("Apri la campagna") }
        await patria.apriLaCampagnaPerProva(sul: "guado")
        try await attendi("si entra nel fronte") { patria.presentedViewController is SchermataMappaCampagna }
        let mappa = try XCTUnwrap(patria.presentedViewController as? SchermataMappaCampagna)
        try await attendi("la mappa si carica") { !mappa.elementiPerProva.isEmpty }
        let guida = PassaggioBattagliaInterfacciaTest()
        let battaglia = try await guida.portaAContatto(mappa)

        // «Spegni» a battaglia appena aperta.
        var aperta: PartitaCorrente? = try await mappa.partitaPerProva.apriBattaglia(battaglia)
        let improntaBattaglia = await aperta!.stato.impronta()
        let improntaCampagna = await mappa.partitaPerProva.stato.impronta()
        let improntaRegno = await patria.partitaPerProva.stato.impronta()
        aperta = nil
        let slotBattaglia = PartitaRegno.cartellaCampagna.appendingPathComponent("battaglie")
            .appendingPathComponent(battaglia.identificatore)
        XCTAssertTrue(FileManager.default.fileExists(atPath: slotBattaglia.appendingPathComponent("giornale.jsonl").path),
                      "la battaglia ha il proprio slot dentro quello della campagna, dentro quello del regno")

        // «Riapri»: regno, campagna e battaglia dai tre slot annidati.
        let regno = try await PartitaRegno(riprendi: ambiente)
        let improntaRegnoRipreso = await regno.stato.impronta()
        XCTAssertEqual(improntaRegnoRipreso, improntaRegno, "il regno si riprende identico")
        let campagnaRipresa = try await regno.campagnaAperta()
        let campagna = try XCTUnwrap(campagnaRipresa, "il regno ritrova la campagna aperta")
        let statoCampagna = await campagna.stato
        XCTAssertEqual(statoCampagna.impronta(), improntaCampagna, "la campagna si riprende identica")
        let inSospeso = try XCTUnwrap(statoCampagna.battaglieInSospeso.first, "la battaglia è ancora in sospeso")
        XCTAssertEqual(inSospeso.identificatore, battaglia.identificatore)
        let ripresa = try await campagna.apriBattaglia(inSospeso)
        let improntaRipresa = await ripresa.stato.impronta()
        XCTAssertEqual(improntaRipresa, improntaBattaglia, "la battaglia si riprende identica dal proprio slot")

        // Combattuta, l'esito torna nella campagna e sopravvive a un altro riavvio.
        let finale = try await guida.combattiAConclusione(ripresa, ambiente: ambiente)
        let esito = await campagna.esitoDiRitorno(inSospeso, statoBattaglia: finale)
        try await campagna.concludiBattaglia(inSospeso, esito: esito)
        let dopoLaBattaglia = await campagna.stato
        XCTAssertFalse(FileManager.default.fileExists(atPath: slotBattaglia.path),
                       "lo slot della battaglia si rimuove quando l'esito è nel giornale della campagna")
        let regnoDiNuovo = try await PartitaRegno(riprendi: ambiente)
        let campagnaDiNuovo = try await regnoDiNuovo.campagnaAperta()
        let ritrovata = try XCTUnwrap(campagnaDiNuovo)
        let statoDiNuovo = await ritrovata.stato
        XCTAssertEqual(statoDiNuovo.impronta(), dopoLaBattaglia.impronta(), "l'esito sopravvive al riavvio")
        XCTAssertTrue(statoDiNuovo.battaglieInSospeso.isEmpty)
        XCTAssertTrue(statoDiNuovo.registro.contains {
            if case .battagliaConclusa(let casella, _) = $0.fatto { return casella == battaglia.casella }
            return false
        }, "la battaglia conclusa è nel registro della campagna anche dopo il riavvio")
        var esitoInPatria = "campagna ancora aperta"
        if statoDiNuovo.conclusione != nil {
            // La battaglia ha tolto a una parte l'ultimo gruppo armato: alla ripresa l'esito arriva in patria.
            let riportato = try await regnoDiNuovo.riportaEsitoSeConclusa(ritrovata)
            let esitoCampagna = try XCTUnwrap(riportato, "la campagna conclusa porta l'esito in patria alla ripresa")
            XCTAssertEqual(esitoCampagna.battaglieVinte + esitoCampagna.battagliePerse, 1)
            esitoInPatria = "campagna conclusa: \(esitoCampagna.modo.rawValue)"
        }
        print("RIPRESA-BATTAGLIA-DEL-REGNO-30 giorno=\(statoCampagna.giorno) casella=riga \(battaglia.casella.riga) casella \(battaglia.casella.colonna) sconfitto=\(esito.sconfitto.rawValue) dopo=\(esitoInPatria)")
    }
}
