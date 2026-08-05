import XCTest
import Dati
import Motore
@testable import WarSense

/// Il tocco diretto sulle due griglie (02 §2.11, 00 §7.1, 00 §2.3).
///
/// **Il difetto che queste prove riproducono.** Fino al 2026-08-05 le caselle di
/// entrambe le griglie erano elementi accessibili sintetici dentro una vista priva
/// di qualunque riconoscitore di gesto: rispondevano ad `accessibilityActivate`,
/// cioè al doppio tocco della tecnologia assistiva, e a nient'altro. Con VoiceOver
/// spento nessuna delle due griglie era operabile; e nessuna prova d'interfaccia
/// poteva esercitare il gioco, perché una prova d'interfaccia tocca a dito.
/// L'osservazione era registrata come P11 e non era mai stata corretta.
///
/// 02 §2.11 chiede la simmetria: «nessuna informazione spaziale è raggiungibile
/// soltanto per esplorazione al tatto… e viceversa nessuna informazione è
/// raggiungibile soltanto a scorrimenti». Una casella attivabile soltanto dalla
/// tecnologia assistiva sta esattamente dal lato sbagliato di quella simmetria.
///
/// Non è l'esplorazione libera a tocco diretto di 02 §2.12, che resta esclusa
/// dalla prima versione: quella riceve i tocchi grezzi per ANNUNCIARE ciò che il
/// dito attraversa. Qui il tocco ATTIVA, come su qualunque controllo, e le tessere
/// del deck lo facevano già dalla fase B (`TesseraDeck` è una `UIControl`).
/// Distinzione registrata in RDA-78.
///
/// Le prove valgono per i DUE piani insieme, con lo stesso corpo eseguito su
/// entrambi: correggerne uno solo li avrebbe fatti divergere, che il principio 7
/// vieta e che P11 aveva espressamente avvertito di non fare.
@MainActor
final class ToccoDirettoTest: XCTestCase {

    private static let schermoPiccolo = CGRect(x: 0, y: 0, width: 375, height: 667)

    private func attendi(_ descrizione: String,
                         _ condizione: @MainActor () -> Bool) async throws {
        for _ in 0..<250 where !condizione() {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertTrue(condizione(), "attesa scaduta: \(descrizione)")
    }

    private func presenta(_ schermata: UIViewController) -> UIWindow {
        let finestra = UIWindow(frame: Self.schermoPiccolo)
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        addTeardownBlock { @MainActor in
            schermata.presentedViewController?.dismiss(animated: false)
            finestra.isHidden = true
            finestra.rootViewController = nil
        }
        return finestra
    }

    private func mappaAperta() async throws -> (SchermataMappaCampagna, UIWindow) {
        let ambiente = try Ambiente()
        let partita = try await PartitaCampagna(nuova: ambiente, taglia: .grande)
        let schermata = SchermataMappaCampagna(partita: partita)
        let finestra = presenta(schermata)
        try await attendi("creazione delle caselle") { !schermata.elementiPerProva.isEmpty }
        try await Task.sleep(nanoseconds: 200_000_000)
        finestra.layoutIfNeeded()
        return (schermata, finestra)
    }

    /// Lo scontro con un reparto già in campo e l'azione tornata disponibile
    /// (01 §8.1.2): senza un proprio reparto nessuna cella ha azioni da offrire.
    private func battagliaAperta() async throws
        -> (SchermataBattaglia, PartitaCorrente, Cella, UIWindow) {
        let ambiente = try Ambiente()
        let partita = try await PartitaCorrente(nuova: ambiente)
        let schermata = SchermataBattaglia(partita: partita)
        let finestra = presenta(schermata)
        try await attendi("creazione delle celle") { !schermata.elementiPerProva.isEmpty }
        let cella = Cella(riga: 10, colonna: 1)
        _ = try await partita.esegui(.seleziona(indiceDeck: 0))
        _ = try await partita.esegui(.piazza(cella: cella))
        _ = try await partita.esegui(.deseleziona)
        _ = try await partita.esegui(.fineTurno)
        try await Task.sleep(nanoseconds: 300_000_000)
        finestra.layoutIfNeeded()
        return (schermata, partita, cella, finestra)
    }

    // MARK: - 02 §2.11 — la riproduzione: esiste un percorso per il dito?

    /// **È la prova che falliva sul codice del 2026-08-04.** Non usa alcuna
    /// interfaccia nuova: interroga soltanto ciò che UIKit espone da sempre, cioè
    /// se la vista che contiene le caselle abbia un bersaglio per il tocco. Prima
    /// della correzione `gestureRecognizers` era `nil` su entrambe le griglie.
    func test_02_2_11_le_due_griglie_hanno_un_percorso_per_il_tocco_diretto() async throws {
        let (mappa, _) = try await mappaAperta()
        let (battaglia, _, _, _) = try await battagliaAperta()
        for (nome, vista) in [("mappa di campagna", mappa.grigliaPerProva),
                              ("griglia di battaglia", battaglia.grigliaPerProva)] {
            XCTAssertTrue(vista.isUserInteractionEnabled,
                          "\(nome): la vista non riceve tocchi affatto")
            XCTAssertFalse(vista.gestureRecognizers?.isEmpty ?? true,
                           "\(nome): nessun riconoscitore di tocco. Le caselle rispondono "
                           + "soltanto all'attivazione assistiva, e con VoiceOver spento la "
                           + "griglia non è operabile (02 §2.11, scostamento P11)")
        }
    }

    // MARK: - 02 §2.11, 00 §7.1 — le due porte sono la stessa porta

    /// Il tocco diretto e l'attivazione assistiva producono lo stesso effetto
    /// perché sono la STESSA chiamata: il riconoscitore risolve il punto
    /// nell'elemento e ne invoca `accessibilityActivate()`. Accertato per
    /// esecuzione e non per ispezione: la stessa casella, aperta dalle due porte,
    /// deve offrire le stesse voci.
    func test_02_2_11_sulla_mappa_il_dito_apre_lo_stesso_pannello_della_voce() async throws {
        let (mappa, _) = try await mappaAperta()
        let stato = try XCTUnwrap(mappa.statoPerProva)
        let casella = stato.gruppiOrdinati[0].posizione
        let elemento = try XCTUnwrap(mappa.elementiPerProva[casella])

        XCTAssertTrue(elemento.accessibilityActivate(), "l'attivazione assistiva non apre nulla")
        try await attendi("pannello della voce") { !mappa.vociPannelloPerProva.isEmpty }
        let vociDellaVoce = mappa.vociPannelloPerProva.map(\.titolo)
        mappa.presentedViewController?.dismiss(animated: false)
        try await Task.sleep(nanoseconds: 200_000_000)

        let cornice = VistaMappa.cornice(di: casella)
        XCTAssertTrue(mappa.grigliaPerProva.attivaAlTocco(in: CGPoint(x: cornice.midX,
                                                                     y: cornice.midY)),
                      "il tocco diretto sulla casella del gruppo non attiva nulla")
        try await attendi("pannello del dito") { !mappa.vociPannelloPerProva.isEmpty }
        XCTAssertEqual(mappa.vociPannelloPerProva.map(\.titolo), vociDellaVoce,
                       "le due porte aprono pannelli diversi: il percorso non è uno solo")
    }

    /// La griglia di battaglia, con lo stesso corpo.
    func test_02_2_11_in_battaglia_il_dito_apre_lo_stesso_pannello_della_voce() async throws {
        let (battaglia, _, cella, _) = try await battagliaAperta()
        let elemento = try XCTUnwrap(battaglia.elementiPerProva[cella])

        XCTAssertTrue(elemento.accessibilityActivate(), "l'attivazione assistiva non apre nulla")
        try await attendi("pannello della voce") { !battaglia.vociPannelloPerProva.isEmpty }
        let vociDellaVoce = battaglia.vociPannelloPerProva.map(\.titolo)
        battaglia.presentedViewController?.dismiss(animated: false)
        try await Task.sleep(nanoseconds: 200_000_000)

        let cornice = VistaGriglia.cornice(di: cella)
        XCTAssertTrue(battaglia.grigliaPerProva.attivaAlTocco(in: CGPoint(x: cornice.midX,
                                                                         y: cornice.midY)),
                      "il tocco diretto sulla cella del reparto non attiva nulla")
        try await attendi("pannello del dito") { !battaglia.vociPannelloPerProva.isEmpty }
        XCTAssertEqual(battaglia.vociPannelloPerProva.map(\.titolo), vociDellaVoce,
                       "le due porte aprono pannelli diversi: il percorso non è uno solo")
    }

    /// Il dito su una casella vuota non attiva nulla, esattamente come la voce: il
    /// tocco non inventa azioni dove non ce ne sono (02 §9.5).
    func test_02_9_5_il_dito_su_una_casella_vuota_non_attiva_nulla() async throws {
        let (mappa, _) = try await mappaAperta()
        let stato = try XCTUnwrap(mappa.statoPerProva)
        let occupate = Set(stato.gruppiOrdinati.map(\.posizione))
        let vuota = try XCTUnwrap(stato.griglia.tutteLeCaselle.first { !occupate.contains($0) })
        let cornice = VistaMappa.cornice(di: vuota)
        XCTAssertFalse(mappa.grigliaPerProva.attivaAlTocco(in: CGPoint(x: cornice.midX,
                                                                      y: cornice.midY)),
                       "il dito su una casella vuota ha attivato qualcosa")
        XCTAssertNil(mappa.presentedViewController, "nessun pannello si apre su una casella vuota")
    }

    /// Il dito fuori da ogni casella — nei margini della vista — non attiva nulla.
    func test_02_2_11_il_dito_fuori_dalle_caselle_non_attiva_nulla() async throws {
        let (mappa, _) = try await mappaAperta()
        XCTAssertFalse(mappa.grigliaPerProva.attivaAlTocco(in: CGPoint(x: 2, y: 2)),
                       "il margine della vista non è una casella e non deve attivare nulla")
    }

    // MARK: - 00 §11.1 — il fuoco dopo un ordine dato al dito

    /// Il requisito che si rompe più facilmente quando si tocca lo strato degli
    /// eventi. Dopo un ordine impartito AL DITO gli elementi non sono ricreati
    /// (05 §10.1, RDA-03) e il guardiano del fuoco non registra alcuno spostamento
    /// non richiesto (00 §11.1). È la stessa verifica che
    /// `MappaCampagnaAccessibileTest.test_00_11_1_…` fa per la porta assistiva.
    func test_00_11_1_dopo_un_ordine_al_dito_gli_elementi_restano_e_il_fuoco_non_si_muove() async throws {
        let (mappa, _) = try await mappaAperta()
        let stato = try XCTUnwrap(mappa.statoPerProva)
        let gruppo = stato.gruppiOrdinati[0]
        let identita = mappa.elementiPerProva.mapValues { ObjectIdentifier($0) }

        let cornice = VistaMappa.cornice(di: gruppo.posizione)
        XCTAssertTrue(mappa.grigliaPerProva.attivaAlTocco(in: CGPoint(x: cornice.midX,
                                                                     y: cornice.midY)))
        try await attendi("pannello del dito") { !mappa.vociPannelloPerProva.isEmpty }
        let presidio = try XCTUnwrap(
            mappa.vociPannelloPerProva.first { $0.titolo.lowercased().contains("presid") },
            "il pannello offre il presidio (01 §5.6.0.6)")
        mappa.presentedViewController?.dismiss(animated: false)
        Fuoco.azzeraRegistro()
        presidio.esegui()
        try await attendi("ordine applicato") {
            mappa.statoPerProva?.gruppi[gruppo.id]?.azioneSpesa == true
        }
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(mappa.elementiPerProva.mapValues { ObjectIdentifier($0) }, identita,
                       "gli elementi sono stati ricreati dopo un ordine dato al dito "
                       + "(05 §10.1, RDA-03): la voce perderebbe il proprio posto")
        // Il solo spostamento ammesso dopo la chiusura di un pannello è quello
        // RICHIESTO, cioè il ritorno del fuoco sulla casella d'origine (00 §11.3).
        // Nessuno spostamento di schermata: quello riporterebbe la voce all'inizio.
        XCTAssertFalse(mappa.registroFuocoPerProva.contains(.schermataAperta),
                       "il fuoco è stato riportato all'inizio dopo un ordine dato al dito "
                       + "(00 §11.1, §11.2): \(mappa.registroFuocoPerProva)")
    }

    // MARK: - 00 §1.2 — nessun elemento raggiungibile da una porta sola

    /// La prova generale, che vale anche per gli elementi che verranno: si percorre
    /// l'ordine di lettura dichiarato e si pretende che OGNI elemento sintetico sia
    /// risolvibile dal punto del proprio centro, cioè che il dito raggiunga
    /// esattamente ciò che la voce raggiunge. Un elemento nuovo raggiungibile da
    /// una porta sola fa fallire qui, senza che nessuno debba ricordarsi di
    /// scrivergli la prova.
    func test_00_1_2_ogni_casella_e_risolvibile_dal_punto_del_proprio_centro() async throws {
        let (mappa, _) = try await mappaAperta()
        let (battaglia, _, _, _) = try await battagliaAperta()
        for (nome, vista) in [("mappa di campagna", mappa.grigliaPerProva),
                              ("griglia di battaglia", battaglia.grigliaPerProva)] {
            let elementi = try XCTUnwrap(vista.accessibilityElements as? [UIAccessibilityElement],
                                         "\(nome): la vista non dichiara i propri elementi")
            XCTAssertFalse(elementi.isEmpty, "\(nome): nessun elemento dichiarato")
            var irrisolti: [String] = []
            for elemento in elementi {
                let cornice = elemento.accessibilityFrameInContainerSpace
                let centro = CGPoint(x: cornice.midX, y: cornice.midY)
                if vista.elemento(sotto: centro) !== elemento {
                    irrisolti.append(elemento.accessibilityLabel ?? "senza etichetta")
                }
            }
            XCTAssertTrue(irrisolti.isEmpty,
                          "\(nome): elementi che il dito non raggiunge nel proprio centro "
                          + "(02 §2.11): " + irrisolti.prefix(5).joined(separator: " | "))
        }
    }
}
