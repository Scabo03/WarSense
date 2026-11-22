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
            for voce in ambiente.valoriRegno.voci {
                guard await patria.partitaPerProva.anteprima(.ordina(voce: voce.identificatore)).eValido else { continue }
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
        try premi("Prosegui alla primavera", in: patria)
        try await attendi("comincia la primavera") { self.lettura(patria).contains("Anno 2, primavera") }
        stato = await patria.partitaPerProva.stato
        XCTAssertEqual(stato.forze.numeroDiUnita, rientrate + 1, "le reclute sono una formazione nuova")
        XCTAssertEqual(stato.forze.formazioni.last?.composizione.count, leve, "un reparto per leva")

        // 4. La campagna del secondo anno porta al fronte anche le reclute.
        await patria.apriLaCampagnaPerProva(sul: "istmo")
        try await attendi("si entra nel fronte del secondo anno") { patria.presentedViewController is SchermataMappaCampagna }
        let seconda = try XCTUnwrap(patria.presentedViewController as? SchermataMappaCampagna)
        try await attendi("la mappa del secondo anno si carica") { !seconda.elementiPerProva.isEmpty }
        XCTAssertEqual(seconda.statoPerProva?.calendario?.anno, 2)
        XCTAssertEqual(seconda.statoPerProva?.gruppi(di: .giocatore).count, stato.forze.numeroDiUnita)

        // 5. La ripresa dal giornale dà lo stesso regno.
        let impronta = await patria.partitaPerProva.stato.impronta()
        let ripreso = await (try PartitaRegno(riprendi: ambiente)).stato
        XCTAssertEqual(ripreso.impronta(), impronta)

        print("ANNO-DEL-REGNO-30 fronte=guado conclusione=\(conclusione.modo.rawValue) vincitore=\(conclusione.vincitore?.rawValue ?? "nessuno") giornate=\(conclusione.giorno) battaglie=\(battaglie) vinte=\(esito.battaglieVinte) perse=\(esito.battagliePerse) formazioni_partite=\(formazioniIniziali) rientrate=\(rientrate) leve=\(leve) formazioni_anno_2=\(stato.forze.numeroDiUnita)")
    }
}
