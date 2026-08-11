import XCTest
import Dati
import Motore
@testable import WarSense

/// La prova d'interfaccia che accerta, aprendo la campagna COME LA APRE IL GIOCATORE
/// (`PartitaCampagna(nuova:taglia:)`, lo stesso inizializzatore dei pulsanti di
/// `SchermateContorno`) e leggendo la schermata VERA (`SchermataMappaCampagna` in una
/// finestra), i quattro fatti che il programma di verifica interno non poteva vedere
/// perché genera i propri scenari e non guarda ciò che arriva in mano al giocatore
/// (incarico 23):
///
/// 1. che fra le formazioni del giocatore esistano formazioni di RICOGNIZIONE;
/// 2. che il pannello di una formazione di ricognizione offra l'ESPLORAZIONE e quello
///    di un gruppo armato no;
/// 3. che nel corso della partita il giocatore AVVISTI almeno una formazione avversaria;
/// 4. che una casella con una formazione avversaria avvistata porti il proprio SEGNO —
///    il riempimento ARANCIONE (letto dallo stesso blocco che disegna) e la forma «×».
///
/// Questa prova FALLISCE sullo scenario giocabile privo di esploratori e di avversario
/// (`scenari-campagna.json` prima dell'incarico 23) e passa una volta corretto lo
/// scenario e aggiunto il riempimento arancione.
@MainActor
final class EsploratoriAvversarioInterfacciaTest: XCTestCase {

    private static let schermoPiccolo = CGRect(x: 0, y: 0, width: 375, height: 667)

    private func mappaAperta(taglia: PartitaCampagna.Taglia) async throws
        -> (SchermataMappaCampagna, UIWindow, Ambiente) {
        let ambiente = try Ambiente()
        let partita = try await PartitaCampagna(nuova: ambiente, taglia: taglia)
        let schermata = SchermataMappaCampagna(partita: partita)
        let finestra = UIWindow(frame: Self.schermoPiccolo)
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
        return (schermata, finestra, ambiente)
    }

    // MARK: - (1) Lo scenario giocabile schiera le tre categorie per entrambe le parti

    func test_incarico_23_ogni_scenario_giocabile_schiera_le_tre_categorie() async throws {
        for taglia in PartitaCampagna.Taglia.allCases {
            let (schermata, _, _) = try await mappaAperta(taglia: taglia)
            let stato = try XCTUnwrap(schermata.statoPerProva)
            for parte in [Parte.giocatore, .avversario] {
                let gruppi = stato.gruppi(di: parte)
                XCTAssertTrue(gruppi.contains { $0.categoria.eArmata },
                              "\(taglia.rawValue): manca un gruppo armato per \(parte)")
                XCTAssertTrue(gruppi.contains { $0.categoria.eRicognizione },
                              "\(taglia.rawValue): manca una formazione di ricognizione per \(parte)")
                XCTAssertTrue(gruppi.contains { $0.categoria.eNonArmata },
                              "\(taglia.rawValue): manca una formazione non armata per \(parte)")
            }
        }
    }

    // MARK: - (2) Il pannello della ricognizione offre l'esplorazione, quello armato no

    func test_incarico_23_il_pannello_distingue_ricognizione_e_armato() async throws {
        let (schermata, _, ambiente) = try await mappaAperta(taglia: .piccola)
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let testi = ambiente.testi
        let esplora = testi.frase("pannello.esplora").testo

        let ricognizione = try XCTUnwrap(stato.gruppi(di: .giocatore).first { $0.categoria.eRicognizione },
                                         "lo scenario giocabile deve schierare un esploratore")
        XCTAssertTrue(schermata.attiva(ricognizione.posizione))
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(schermata.vociPannelloPerProva.map(\.titolo).contains(esplora),
                      "il pannello dell'esploratore offre l'esplorazione")
        schermata.presentedViewController?.dismiss(animated: false)
        try await Task.sleep(nanoseconds: 100_000_000)

        let armato = try XCTUnwrap(stato.gruppi(di: .giocatore).first { $0.categoria.eArmata })
        XCTAssertTrue(schermata.attiva(armato.posizione))
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertFalse(schermata.vociPannelloPerProva.map(\.titolo).contains(esplora),
                       "il pannello di un gruppo armato NON offre l'esplorazione (01 §5.6.8.1)")
    }

    // MARK: - (3) L'esplorazione ordinata dall'interfaccia produce un effetto sensibile

    func test_incarico_23_l_esplorazione_ordinata_produce_un_effetto() async throws {
        let (schermata, _, ambiente) = try await mappaAperta(taglia: .piccola)
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let esplora = ambiente.testi.frase("pannello.esplora").testo
        let ricognizione = try XCTUnwrap(stato.gruppi(di: .giocatore).first { $0.categoria.eRicognizione })

        let motore = schermata.motorePerProva
        func confermate(_ s: StatoCampagna) -> Int {
            s.griglia.tutteLeCaselle.filter {
                motore.conoscenza(di: $0, per: .giocatore, stato: s) == .confermato
            }.count
        }
        let confermatePrima = confermate(stato)
        let registroPrima = stato.registro.count

        XCTAssertTrue(schermata.attiva(ricognizione.posizione))
        try await Task.sleep(nanoseconds: 100_000_000)
        let voce = try XCTUnwrap(schermata.vociPannelloPerProva.first { $0.titolo == esplora },
                                 "l'ordine di esplorazione è raggiungibile dal pannello")
        voce.esegui()
        for _ in 0..<50 where schermata.statoPerProva?.gruppi[ricognizione.id]?.azioneSpesa != true {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        let dopo = try XCTUnwrap(schermata.statoPerProva)
        XCTAssertEqual(dopo.gruppi[ricognizione.id]?.azioneSpesa, true,
                       "l'ordine di esplorazione è stato impartito e ha consumato l'azione")
        // L'esito è annunciato: o la mappa si è rivelata (l'area confermata cresce) o un
        // fatto è entrato nel registro (mani vuote, notati, perduti). Uno dei due è vero
        // per costruzione — l'esploratore non torna senza che il giocatore lo senta.
        XCTAssertTrue(confermate(dopo) > confermatePrima || dopo.registro.count > registroPrima,
                      "l'esito dell'esplorazione non produce alcun effetto sensibile")
    }

    // MARK: - (4) Il giocatore avvista l'avversario e la casella si riempie di arancione

    func test_incarico_23_il_giocatore_avvista_l_avversario_e_la_casella_e_arancione() async throws {
        let (schermata, _, ambiente) = try await mappaAperta(taglia: .piccola)
        let avvistata = try await avanzaFinoAvvistamento(schermata)
        let cella = try XCTUnwrap(avvistata,
            "il giocatore non ha mai avvistato l'avversario: lo scenario non contiene un avversario avvistabile")

        // Il segno di FORMA: la casella dell'avversario avvistato porta la «×».
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let costruttore = CostruttoreAnnunciCampagna(testi: ambiente.testi,
                                                     motore: schermata.motorePerProva,
                                                     stato: stato, verbosita: .normale)
        let segni = try XCTUnwrap(costruttore.segniCasella(cella),
                                  "la casella dell'avversario avvistato porta un segno di forma")
        XCTAssertTrue(segni.contains("×"), "il segno dell'avversario è la «×»: «\(segni)»")

        // L'annuncio dichiara la formazione avversaria (ciò che si vede coincide con ciò
        // che si sente).
        let etichetta = try XCTUnwrap(schermata.elementiPerProva[cella]?.accessibilityLabel)
        XCTAssertTrue(etichetta.contains("avversari"),
                      "l'annuncio della casella dichiara la formazione avversaria: «\(etichetta)»")

        // Il segno di COLORE: la casella è riempita di arancione, letto dallo stesso blocco
        // che la mappa disegna.
        XCTAssertEqual(schermata.coloreCasellaPerProva(cella), .systemOrange,
                       "la casella dell'avversario avvistato è riempita di arancione (incarico 23)")
    }

    // MARK: - Attrezzi

    /// Percorre la mappa avanzando le giornate — un esploratore marcia verso il quartier
    /// generale avversario, gli altri presidiano — finché il giocatore non avvista una
    /// formazione avversaria (o si esaurisce il numero di giornate). Deterministica: la
    /// campagna non estrae mai il caso (RDA-43).
    private func avanzaFinoAvvistamento(_ schermata: SchermataMappaCampagna,
                                        maxGiorni: Int = 30) async throws -> Cella? {
        let motore = schermata.motorePerProva
        for _ in 0..<maxGiorni {
            let stato = try XCTUnwrap(schermata.statoPerProva)
            let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
            if let avv = vista.caselleFormazioniAvversarieNote.first { return avv }
            let qgAvversario = try XCTUnwrap(stato.griglia.tutteLeCaselle.first {
                vista.quartierGeneraleSu($0) == .avversario })
            try await avanzaUnGiorno(schermata, versoQG: qgAvversario)
        }
        // Un ultimo controllo dopo l'ultima giornata.
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
        return vista.caselleFormazioniAvversarieNote.first
    }

    /// Chiude una giornata: il gruppo in attesa più vicino al quartier generale avversario
    /// marcia verso di esso (scegliendo la destinazione valida che riduce la distanza), gli
    /// altri presidiano. La giornata si chiude da sé quando tutti hanno agito (01 §5.6.0.6).
    private func avanzaUnGiorno(_ schermata: SchermataMappaCampagna, versoQG qg: Cella) async throws {
        func dist(_ a: Cella, _ b: Cella) -> Int { abs(a.riga - b.riga) + abs(a.colonna - b.colonna) }
        let motore = schermata.motorePerProva
        let giornoDiPartenza = schermata.statoPerProva?.giorno ?? 0
        var protezione = 0
        while protezione < 40 {
            protezione += 1
            guard let stato = schermata.statoPerProva else { return }
            if stato.giorno != giornoDiPartenza { return } // la giornata si è chiusa: uno solo per volta
            let attesa = stato.gruppiInAttesa(di: .giocatore)
            guard let gruppo = attesa.min(by: { dist($0.posizione, qg) < dist($1.posizione, qg) })
            else { return } // nessuno in attesa: la giornata è chiusa
            let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
            let destinazioni = vista.destinazioniValide(per: gruppo.id)
            if let meta = destinazioni.filter({ dist($0, qg) < dist(gruppo.posizione, qg) })
                .min(by: { dist($0, qg) < dist($1, qg) }) {
                let costo = motore.costoInGiorni(da: gruppo.posizione, a: meta, stato: stato)
                await schermata.eseguiPerProva(.marcia(gruppo: gruppo.id, a: meta, giorni: costo))
            } else {
                await schermata.eseguiPerProva(.presidio(gruppo: gruppo.id))
            }
        }
    }
}
