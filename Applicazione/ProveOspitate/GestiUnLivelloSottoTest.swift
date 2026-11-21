import XCTest
import Dati
import Motore
import Sessione
@testable import WarSense

/// I gesti di VoiceOver verificati UN LIVELLO SOTTO il gesto (incarico 28, seconda parte): si chiama
/// direttamente ciò che il gesto attiva — la ricerca di un rotore personalizzato, il gestore del tocco
/// magico e quello dell'uscita, il gestore di un'azione personalizzata — e se ne controlla l'EFFETTO
/// (dove va il fuoco, che cosa cambia) e l'ANNUNCIO, nello strato dei segnali del gioco
/// (`PuntoSegnali.annunciPronunciati`, la coda che il punto dei segnali già tiene). Le prove che
/// c'erano controllavano che rotori e azioni esistessero, con i nomi giusti; queste controllano che
/// facciano ciò che dichiarano. Quali gesti si guidano anche dal vivo, e quali no, è nel rapporto sui
/// canali dei prodotti dell'incarico 28.
@MainActor
final class GestiUnLivelloSottoTest: XCTestCase {

    private var finestre: [UIWindow] = []

    override func tearDown() async throws {
        for f in finestre {
            f.rootViewController?.presentedViewController?.dismiss(animated: false)
            f.isHidden = true; f.rootViewController = nil
        }
        finestre = []
        try await super.tearDown()
    }

    private func monta(_ schermata: UIViewController) {
        let finestra = UIWindow(frame: CGRect(x: 0, y: 0, width: 420, height: 912))
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        finestre.append(finestra)
    }

    private func attendi(_ condizione: () -> Bool) async throws {
        for _ in 0..<300 where !condizione() { try await Task.sleep(nanoseconds: 20_000_000) }
    }

    private func mappa(_ taglia: PartitaCampagna.Taglia = .piccola) async throws
        -> (SchermataMappaCampagna, Ambiente) {
        let ambiente = try Ambiente()
        let schermata = SchermataMappaCampagna(partita: try await PartitaCampagna(nuova: ambiente, taglia: taglia))
        monta(schermata)
        try await attendi { !schermata.elementiPerProva.isEmpty }
        try await Task.sleep(nanoseconds: 200_000_000)
        return (schermata, ambiente)
    }

    private func battaglia() async throws -> (SchermataBattaglia, Ambiente) {
        let ambiente = try Ambiente()
        let schermata = SchermataBattaglia(partita: try await PartitaCorrente(nuova: ambiente))
        monta(schermata)
        try await attendi { !schermata.elementiPerProva.isEmpty }
        try await Task.sleep(nanoseconds: 200_000_000)
        return (schermata, ambiente)
    }

    /// Le caselle che il rotore raggiunge, nell'ordine: dalla ricerca senza elemento corrente, poi
    /// «successivo» da ciascuno, finché il giro si chiude.
    private func percorsoDelRotore(_ rotore: UIAccessibilityCustomRotor, massimo: Int = 60) -> [NSObject] {
        var visti: [NSObject] = []
        // Il primo passo parte da un elemento che non è del gioco, come quando il fuoco sta altrove.
        var corrente = UIAccessibilityCustomRotorItemResult(targetElement: NSObject(), targetRange: nil)
        for _ in 0..<massimo {
            let richiesta = UIAccessibilityCustomRotorSearchPredicate()
            richiesta.searchDirection = .next
            richiesta.currentItem = corrente
            guard let esito = rotore.itemSearchBlock(richiesta),
                  let bersaglio = esito.targetElement as? NSObject else { break }
            if visti.contains(where: { $0 === bersaglio }) { break }
            visti.append(bersaglio)
            corrente = esito
        }
        return visti
    }

    // MARK: - Mappa di campagna

    /// Tocco magico sulla mappa (02 §6.7): annuncia l'informazione di stato della campagna, quella
    /// del costruttore sullo stato corrente, e non sposta il fuoco.
    func test_mappa_tocco_magico_annuncia_lo_stato_senza_spostare_il_fuoco() async throws {
        let (schermata, ambiente) = try await mappa()
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let atteso = CostruttoreAnnunciCampagna(testi: ambiente.testi, motore: schermata.motorePerProva,
                                                stato: stato, verbosita: Impostazioni.verbosita).informazioneDiStato()
        let movimenti = Fuoco.registro.count
        XCTAssertTrue(schermata.accessibilityPerformMagicTap())
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.last?.testo, atteso)
        XCTAssertEqual(Fuoco.registro.count, movimenti, "il tocco magico non sposta il fuoco")
    }

    /// I sei rotori della mappa (02 §7.3): ciascuno percorre esattamente le caselle del proprio
    /// insieme, in ordine di lettura, e il rotore di un insieme vuoto non porta da nessuna parte.
    func test_mappa_i_rotori_percorrono_il_proprio_insieme() async throws {
        let (schermata, ambiente) = try await mappa(.media)
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let vista = CostruttoreAnnunciCampagna(testi: ambiente.testi, motore: schermata.motorePerProva,
                                               stato: stato, verbosita: Impostazioni.verbosita).vista
        let attesi: [[Cella]] = [vista.casellePropriFormazioni, vista.caselleGruppiInAttesa,
                                 vista.caselleGruppiSenzaRifornimento, vista.caselleFormazioniAvversarieNote,
                                 vista.caselleEsplorabili, vista.caselleRicognizioneScadute]
        let rotori = schermata.view.accessibilityCustomRotors ?? []
        XCTAssertEqual(rotori.count, 6)
        var percorsi: [String] = []
        for (rotore, insieme) in zip(rotori, attesi) {
            let raggiunte = percorsoDelRotore(rotore).compactMap { ($0 as? ElementoCasella)?.casella }
            XCTAssertEqual(raggiunte, Array(Set(insieme)).sorted(), "rotore «\(rotore.name)»")
            percorsi.append("\(rotore.name): \(raggiunte.count)")
        }
        print("ROTORI-MAPPA " + percorsi.joined(separator: " | "))
        XCTAssertFalse(attesi[1].isEmpty, "a inizio partita ci sono gruppi da muovere: il rotore non è vuoto")
    }

    /// Le azioni personalizzate della casella (02 §2.5): «Vai a nord» e «Vai a sud» portano il fuoco
    /// sulla casella sopra e sotto, come movimento richiesto dal giocatore.
    func test_mappa_le_azioni_personalizzate_portano_il_fuoco_alla_casella_vicina() async throws {
        let (schermata, ambiente) = try await mappa()
        let nord = ambiente.testi.frase("direzione.nord").testo
        let sud = ambiente.testi.frase("direzione.sud").testo
        let partenza = Cella(riga: 2, colonna: 2)
        let elemento = try XCTUnwrap(schermata.elementiPerProva[partenza])
        for (nome, arrivo) in [(nord, Cella(riga: 1, colonna: 2)), (sud, Cella(riga: 3, colonna: 2))] {
            let azione = try XCTUnwrap(elemento.accessibilityCustomActions?.first { $0.name == nome })
            XCTAssertTrue(try XCTUnwrap(azione.actionHandler)(azione), "«\(nome)» eseguita")
            XCTAssertEqual(Fuoco.registro.last, .richiesto)
            XCTAssertTrue(Fuoco.ultimoBersaglio === schermata.elementiPerProva[arrivo], "«\(nome)» porta il fuoco in \(arrivo)")
        }
    }

    /// Il gesto di uscita sulla mappa (02 §6.7, §9.2.1): durante la designazione di una marcia la
    /// annulla e lo annuncia; senza designazione risale di un livello, all'avvio.
    func test_mappa_uscita_annulla_la_designazione_poi_risale() async throws {
        let (schermata, ambiente) = try await mappa()
        var risalito = false
        schermata.alTermine = { risalito = true }
        let gruppo = try XCTUnwrap(schermata.statoPerProva?.gruppiInAttesa(di: .giocatore).first { $0.categoria.eArmata })
        schermata.avviaDesignazionePerProva(gruppo: gruppo.id)
        XCTAssertTrue(schermata.accessibilityPerformEscape())
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.last?.testo,
                       ambiente.testi.frase("pannello.designazione_annullata").testo)
        XCTAssertFalse(risalito, "la prima uscita annulla la designazione, non lascia la mappa")
        XCTAssertTrue(schermata.accessibilityPerformEscape())
        XCTAssertTrue(risalito, "la seconda uscita risale all'avvio")
    }

    // MARK: - Battaglia

    func test_battaglia_tocco_magico_annuncia_lo_stato() async throws {
        let (schermata, ambiente) = try await battaglia()
        let atteso = try XCTUnwrap(schermata.costruttorePerProva).informazioneDiStato()
        XCTAssertTrue(schermata.accessibilityPerformMagicTap())
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.last?.testo, atteso)
    }

    /// I rotori della battaglia (02 §7.2): «Celle valide» è vuoto senza un elemento del deck scelto e,
    /// scelto il primo, percorre le celle valide per quell'elemento; «Tuoi reparti» è vuoto prima del
    /// primo piazzamento.
    func test_battaglia_i_rotori_seguono_la_selezione() async throws {
        let (schermata, ambiente) = try await battaglia()
        let rotori = schermata.view.accessibilityCustomRotors ?? []
        let nomi = rotori.map(\.name)
        XCTAssertEqual(nomi, ["rotore.propri_sciami", "rotore.propri_senza_azione", "rotore.sciami_avversari",
                              "rotore.celle_valide", "rotore.rinforzi", "rotore.ostacoli"].map { ambiente.testi.frase($0).testo })
        let valide = try XCTUnwrap(rotori.first { $0.name == ambiente.testi.frase("rotore.celle_valide").testo })
        XCTAssertTrue(percorsoDelRotore(valide).isEmpty, "senza selezione nessuna cella è valida")
        _ = try await schermata.partitaPerProva.esegui(.seleziona(indiceDeck: 0))
        try await Task.sleep(nanoseconds: 300_000_000)
        let stato = await schermata.partitaPerProva.stato
        let attese = VistaBattaglia(motore: schermata.partitaPerProva.motore, stato: stato, parte: .giocatore)
            .celleValidePerSelezione().map(\.cella)
        let raggiunte = percorsoDelRotore(valide, massimo: 120).compactMap { ($0 as? ElementoCella)?.cella }
        XCTAssertFalse(raggiunte.isEmpty)
        XCTAssertEqual(raggiunte, Array(Set(attese)).sorted(), "il rotore percorre le celle valide per la selezione")
        let propri = try XCTUnwrap(rotori.first { $0.name == ambiente.testi.frase("rotore.propri_sciami").testo })
        XCTAssertTrue(percorsoDelRotore(propri).isEmpty, "nessun reparto proprio in campo prima del piazzamento")
    }

    /// Le azioni personalizzate della cella esagonale (02 §2.5): le quattro diagonali portano il fuoco
    /// sulla cella vicina giusta, nelle righe pari e dispari (sfalsate).
    func test_battaglia_le_azioni_personalizzate_portano_il_fuoco_alla_cella_vicina() async throws {
        let (schermata, ambiente) = try await battaglia()
        for partenza in [Cella(riga: 4, colonna: 5), Cella(riga: 5, colonna: 5)] {
            let sfalsata = partenza.riga % 2 == 0
            let attese: [(String, Cella)] = [
                ("direzione.nord_ovest", Cella(riga: partenza.riga - 1, colonna: sfalsata ? partenza.colonna : partenza.colonna - 1)),
                ("direzione.nord_est", Cella(riga: partenza.riga - 1, colonna: sfalsata ? partenza.colonna + 1 : partenza.colonna)),
                ("direzione.sud_ovest", Cella(riga: partenza.riga + 1, colonna: sfalsata ? partenza.colonna : partenza.colonna - 1)),
                ("direzione.sud_est", Cella(riga: partenza.riga + 1, colonna: sfalsata ? partenza.colonna + 1 : partenza.colonna)),
            ]
            let elemento = try XCTUnwrap(schermata.elementiPerProva[partenza])
            for (chiave, arrivo) in attese {
                let nome = ambiente.testi.frase(chiave).testo
                let azione = try XCTUnwrap(elemento.accessibilityCustomActions?.first { $0.name == nome }, "\(nome) in \(partenza)")
                XCTAssertTrue(try XCTUnwrap(azione.actionHandler)(azione))
                XCTAssertTrue(Fuoco.ultimoBersaglio === schermata.elementiPerProva[arrivo], "«\(nome)» da \(partenza) a \(arrivo)")
            }
        }
    }

    /// Il gesto di uscita in battaglia senza designazione in corso non fa nulla e lo dichiara al
    /// sistema (ritorna falso): la battaglia non si lascia con un gesto (02 §6.7).
    func test_battaglia_uscita_senza_designazione_non_fa_nulla() async throws {
        let (schermata, ambiente) = try await battaglia()
        let annunci = ambiente.segnali.annunciPronunciati.count
        XCTAssertFalse(schermata.accessibilityPerformEscape())
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.count, annunci)
        XCTAssertNil(schermata.presentedViewController)
    }

    // MARK: - Registro: l'uscita chiude

    func test_registro_l_uscita_lo_chiude() async throws {
        let (schermata, _) = try await mappa()
        schermata.apriRegistroPerProva()
        try await attendi { schermata.presentedViewController is SchermataRegistro }
        let registro = try XCTUnwrap(schermata.presentedViewController as? SchermataRegistro)
        XCTAssertTrue(registro.accessibilityPerformEscape())
        try await attendi { schermata.presentedViewController == nil }
        XCTAssertNil(schermata.presentedViewController, "l'uscita chiude il registro")
    }
}
