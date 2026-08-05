import XCTest

/// L'impianto di prova sull'interfaccia reale del simulatore (05 §14.4).
///
/// ## Che cosa cambia rispetto a prima
///
/// Le due prove d'interfaccia preesistenti — `FumoInterfacciaTest` e
/// `FumoMappaCampagnaTest` — verificano che gli elementi ESISTANO con le loro
/// etichette, e lo dichiarano nei propri commenti: quella della mappa dichiara
/// espressamente di non provare l'attivazione, perché le caselle non rispondevano
/// al tocco grezzo. Erano le sole due prove del progetto a passare per il servizio
/// di accessibilità vero, e nessuna delle due esercitava il gioco.
///
/// Questo impianto lo esercita: tocca, legge ciò che l'interfaccia espone,
/// verifica. È possibile perché le caselle rispondono ora al dito (RDA-78), ed è
/// il tocco VERO del simulatore, non la chiamata diretta che le prove ospitate
/// possono fare.
///
/// ## CHE COSA QUESTO IMPIANTO NON PUÒ VERIFICARE
///
/// Va enunciato qui e non lasciato dedurre, perché la tentazione di dichiarare
/// coperto ciò che è soltanto esercitato è il difetto che questo progetto ha già
/// commesso una volta (scostamento S3: le prove accertavano la dichiarazione e non
/// la raggiungibilità).
///
/// 1. **La pronuncia.** Il servizio di accessibilità con sintesi vocale non è
///    disponibile qui. Si legge la stringa che l'interfaccia espone, non la frase
///    che una voce pronuncia alla velocità di chi gioca.
/// 2. **Il fuoco di VoiceOver.** Non è osservabile da un processo di prova. Ciò
///    che si verifica è che la schermata non venga sostituita e che gli elementi
///    non spariscano — condizione necessaria e non sufficiente. Il guardiano del
///    fuoco si osserva nelle prove ospitate, il fuoco vero solo sul dispositivo.
/// 3. **La comprensibilità di una frase** e **l'orientabilità di una mappa**: se
///    dopo qualche giornata il giocatore sappia dove sono le cose. Nessuna misura
///    lo dirà mai.
/// 4. **L'aptica e i suoni**, che il simulatore non produce.
///
/// Tutte e quattro restano in `collaudo-solo-dispositivo.md` e non vanno mai
/// dichiarate coperte.
final class ImpiantoInterfacciaTest: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Attrezzi

    /// Tutti gli elementi che il servizio di accessibilità espone, nell'ordine in
    /// cui li espone. È l'ordine di lettura effettivo (02 §2.8).
    private func percorsoDiLettura() -> [XCUIElement] {
        app.descendants(matching: .any).allElementsBoundByIndex.filter {
            $0.exists && !$0.label.isEmpty
        }
    }

    private func apriLaMappaPiccola() {
        let nuova = app.buttons["Nuova campagna, mappa piccola"]
        XCTAssertTrue(nuova.waitForExistence(timeout: 15),
                      "la schermata di avvio espone l'ingresso alla mappa")
        nuova.tap()
        XCTAssertTrue(casella(riga: 1, colonna: 1).waitForExistence(timeout: 15),
                      "la mappa si apre e le caselle sono elementi")
    }

    private func casella(riga: Int, colonna: Int) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@",
                                  "riga \(riga), casella \(colonna)")).firstMatch
    }

    /// La casella del proprio gruppo: si riconosce dallo stato che dichiara.
    private func casellaDelGruppoInAttesa() -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "in attesa")).firstMatch
    }

    // MARK: - 00 §2.3 — nome, ruolo, valore, e un bersaglio per il dito

    func test_00_2_3_ogni_elemento_esposto_ha_nome_ed_e_raggiungibile() throws {
        apriLaMappaPiccola()
        var muti: [String] = []
        var irraggiungibili: [String] = []
        for elemento in percorsoDiLettura() {
            if elemento.label.trimmingCharacters(in: .whitespaces).isEmpty {
                muti.append(elemento.identifier)
            }
            // I bottoni e le caselle devono essere colpibili: un elemento
            // dichiarato e non colpibile è il difetto della build 3 (S3).
            if elemento.elementType == .button && !elemento.isHittable {
                irraggiungibili.append(elemento.label)
            }
        }
        XCTAssertTrue(muti.isEmpty, "elementi senza nome (00 §2.3): \(muti)")
        XCTAssertTrue(irraggiungibili.isEmpty,
                      "comandi dichiarati e non colpibili (00 §1.2): \(irraggiungibili)")
    }

    // MARK: - 02 §2.8 — completezza del percorso, e ciò che qui NON è osservabile

    /// **Limite accertato in questa sessione, e dichiarato invece che aggirato.**
    /// `XCUIApplication.descendants` NON restituisce l'ordine di lettura: percorre
    /// la gerarchia delle viste e ignora `view.accessibilityElements`. Misurato: sulla
    /// mappa piccola i quattro comandi globali compaiono agli indici 6–9, PRIMA delle
    /// sedici caselle (indici 10–25), mentre l'ordine dichiarato li mette in coda.
    /// L'ordine EFFETTIVO che la tecnologia assistiva percorre è quello di
    /// `accessibilityElements`, e si verifica dove è leggibile: nelle prove ospitate,
    /// `MappaCampagnaAccessibileTest.test_02_2_8_…` e
    /// `RaggiungibilitaTest.test_02_2_8_…`. Dichiarare qui verificato l'ordine
    /// sarebbe dichiarare coperta una cosa provata da un albero diverso.
    ///
    /// Ciò che qui si verifica, e che le prove ospitate non possono verificare, è la
    /// COMPLETEZZA attraverso il servizio vero: ogni elemento dell'ordine dichiarato
    /// esiste davvero nell'albero che la tecnologia assistiva vede, con la propria
    /// etichetta. Un elemento dichiarato e assente di lì è muto per il giocatore.
    func test_02_2_8_ogni_elemento_dichiarato_esiste_nell_albero_dell_accessibilita() throws {
        apriLaMappaPiccola()
        let etichette = percorsoDiLettura().map(\.label)
        var mancanti: [String] = []
        for riga in 1...4 {
            for colonna in 1...4 where !etichette.contains(where: {
                $0.hasPrefix("riga \(riga), casella \(colonna),")
            }) {
                mancanti.append("riga \(riga), casella \(colonna)")
            }
        }
        for comando in ["Registro della campagna", "Annulla l'ultima operazione",
                        "Azzera lo schieramento del turno", "Torna all'inizio"]
        where !etichette.contains(comando) {
            mancanti.append(comando)
        }
        XCTAssertTrue(mancanti.isEmpty,
                      "elementi dell'ordine dichiarato assenti dall'albero "
                      + "dell'accessibilità (02 §2.8): \(mancanti)")
    }

    // MARK: - 00 §14.2 — nessun segnaposto irrisolto, nessuna chiave nuda

    /// Un'etichetta che porti `%@` o `%d` è una frase mai riempita; una che abbia
    /// la forma di una chiave è un testo mai risolto. Entrambe arriverebbero alla
    /// voce così come sono.
    func test_00_14_2_nessuna_etichetta_porta_segnaposto_o_chiavi_non_risolte() throws {
        apriLaMappaPiccola()
        let chiaveNuda = try NSRegularExpression(pattern: "^[a-z][a-z0-9_]*(\\.[a-z0-9_]+)+$")
        var guaste: [String] = []
        for elemento in percorsoDiLettura() {
            for testo in [elemento.label, elemento.value as? String ?? ""] where !testo.isEmpty {
                if testo.contains("%@") || testo.contains("%d") || testo.contains("%lld")
                    || testo.contains("%1$") {
                    guaste.append("segnaposto irrisolto: «\(testo)»")
                }
                let intero = NSRange(location: 0, length: (testo as NSString).length)
                if chiaveNuda.firstMatch(in: testo, range: intero) != nil {
                    guaste.append("chiave di testo non risolta: «\(testo)»")
                }
            }
        }
        XCTAssertTrue(guaste.isEmpty, "etichette guaste (00 §14.2, 00 §9.1): \(guaste)")
    }

    // MARK: - 02 §6.7, 05 §9.3 — da ogni schermata si torna indietro

    func test_02_6_7_da_ogni_schermata_si_torna_indietro() throws {
        apriLaMappaPiccola()
        // Il registro si apre e si chiude tornando alla mappa.
        app.buttons["Registro della campagna"].tap()
        XCTAssertTrue(app.buttons["Chiudi il registro"].waitForExistence(timeout: 10),
                      "il registro si apre e dichiara come uscirne")
        app.buttons["Chiudi il registro"].tap()
        XCTAssertTrue(casella(riga: 1, colonna: 1).waitForExistence(timeout: 10),
                      "chiudendo il registro si torna alla mappa")

        // Il pannello della casella si apre al dito e si chiude senza congedare la
        // schermata: è il primo difetto bloccante della fase B (P5).
        casellaDelGruppoInAttesa().tap()
        XCTAssertTrue(app.buttons["Chiudi il pannello"].waitForExistence(timeout: 10),
                      "il pannello si apre al TOCCO DIRETTO della casella (RDA-78)")
        app.buttons["Chiudi il pannello"].tap()
        XCTAssertTrue(casella(riga: 1, colonna: 1).waitForExistence(timeout: 10),
                      "chiudendo il pannello si resta sulla mappa e non si torna all'avvio")

        // Dalla mappa si torna alla schermata iniziale.
        app.buttons["Torna all'inizio"].tap()
        XCTAssertTrue(app.buttons["Nuova campagna, mappa piccola"].waitForExistence(timeout: 10),
                      "dalla mappa si risale alla schermata iniziale")
    }

    // MARK: - Il gioco esercitato: un ordine dato al dito arriva dove deve

    /// La prova che nessuna prova d'interfaccia poteva scrivere prima di RDA-78:
    /// si tocca la casella del proprio gruppo, si sceglie il presidio, e si accerta
    /// che l'ordine sia arrivato — lo stato del gruppo cambia, il registro si
    /// riempie della voce giusta, e il giorno avanza perché era l'ultimo gruppo.
    func test_01_5_6_un_ordine_dato_al_dito_arriva_al_gioco() throws {
        apriLaMappaPiccola()
        let gruppo = casellaDelGruppoInAttesa()
        XCTAssertTrue(gruppo.waitForExistence(timeout: 10),
                      "un gruppo dichiara di attendere una decisione (01 §5.16.1)")
        let etichettaPrima = gruppo.label

        gruppo.tap()
        let presidio = app.buttons["Presidia: resta fermo in guardia"]
        XCTAssertTrue(presidio.waitForExistence(timeout: 10),
                      "il pannello aperto al dito offre il presidio (01 §5.6.8.1)")
        presidio.tap()

        // Lo stato del gruppo cambia: la casella non dichiara più «in attesa».
        let agito = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "ha agito")).firstMatch
        XCTAssertTrue(agito.waitForExistence(timeout: 10),
                      "dopo l'ordine dato al dito il gruppo dichiara di avere agito "
                      + "(01 §5.16.1). Etichetta prima: «\(etichettaPrima)»")

        // Il registro annota il fatto con il giorno e il luogo (S8, RDA-72).
        app.buttons["Registro della campagna"].tap()
        let voce = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "presidia")).firstMatch
        XCTAssertTrue(voce.waitForExistence(timeout: 10),
                      "il registro annota l'ordine impartito, con il giorno e la casella")
        app.buttons["Chiudi il registro"].tap()
    }

    // MARK: - 00 §11.1 — dopo un ordine la schermata non viene sostituita

    /// Ciò che qui è osservabile del requisito sul fuoco: dopo un ordine la
    /// schermata resta la stessa e gli elementi non spariscono. Il fuoco vero di
    /// VoiceOver non è osservabile da un processo di prova, e il guardiano del
    /// fuoco si controlla nelle prove ospitate
    /// (`ToccoDirettoTest.test_00_11_1_…`): questa prova è la condizione
    /// necessaria, non quella sufficiente, e non va letta come di più.
    func test_00_11_1_dopo_un_ordine_la_schermata_resta_e_gli_elementi_no_spariscono() throws {
        apriLaMappaPiccola()
        let etichettePrima = Set(percorsoDiLettura().map(\.label))

        casellaDelGruppoInAttesa().tap()
        let presidio = app.buttons["Presidia: resta fermo in guardia"]
        XCTAssertTrue(presidio.waitForExistence(timeout: 10))
        presidio.tap()
        XCTAssertTrue(casella(riga: 1, colonna: 1).waitForExistence(timeout: 10),
                      "la schermata dello scontro è stata sostituita dopo un ordine: "
                      + "per chi ascolta è indistinguibile da un riavvio (P5)")

        let etichetteDopo = Set(percorsoDiLettura().map(\.label))
        let sparite = etichettePrima.subtracting(etichetteDopo)
        // Cambia la sola casella del gruppo, che ora dichiara un altro stato.
        XCTAssertLessThanOrEqual(sparite.count, 1,
                                 "dopo un ordine sono sparite \(sparite.count) etichette: "
                                 + "gli elementi vanno aggiornati sul posto (05 §10.1, RDA-03). "
                                 + "\(sparite)")
    }

    // MARK: - 00 §7.1 — il piano della battaglia: un difetto corretto, la prova ancora assente
    //
    // **Corretto in questa sessione, ed era un difetto del gioco.** Selezionare una
    // tessera del deck ne faceva crescere il valore di una riga («selezionato»,
    // 02 §8.2): la colonna del deck cresceva di diciotto punti e la griglia, che le
    // cede spazio (RDA-50), perdeva altrettanto di porzione visibile — proprio fra
    // il selezionare e il piazzare, e proprio sul bordo inferiore, dove sta la zona
    // di schieramento (01 §8.2.1). Misurato: la cella di riga 8 colonna 1 ha il
    // centro a y=502, e la porzione visibile finiva a y=507,7 prima della selezione
    // e a y=489,7 dopo. La cornice riportata dall'accessibilità restava però
    // (44, 472, 60, 60), perché è la posizione nel CONTENUTO: chi toccava dove la
    // cella era annunciata non toccava la cella. `TesseraDeck` riserva ora l'altezza
    // dello stato più lungo, e `StabilitaDellaDisposizioneTest` è la prova rossa.
    //
    // **Che cosa resta.** Nemmeno con la disposizione ferma il tocco sintetizzato
    // riesce a schierare: una cella della zona arretrata non entra INTERAMENTE nella
    // porzione visibile, e scorrere non basta. Vedi lo scostamento S10. Ciò che è
    // provato: l'equivalenza fra le due porte sui due piani
    // (`ToccoDirettoTest`), un ordine impartito con il tocco vero sulla mappa
    // (`test_01_5_6_…`), e la stabilità della disposizione (sopra).
}
