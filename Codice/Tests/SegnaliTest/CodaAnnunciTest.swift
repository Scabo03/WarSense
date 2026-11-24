import XCTest
@testable import Segnali
import Motore
import Dati

/// La coda degli annunci (05 §10.7, §11.6): l'ordine, l'interruzione, e la conclusione tardiva
/// dell'annuncio interrotto, che non deve far avanzare la coda (incarico 30).
final class CodaAnnunciTest: XCTestCase {

    /// Nelle prove l'annuncio è il suo stesso testo.
    private func accoda(_ coda: inout CodaAnnunci<String>, _ testo: String, interrompente: Bool = false) -> String? {
        coda.accoda(testo, testo: testo, interrompente: interrompente)
    }

    func test_05_11_6_un_annuncio_alla_volta_nell_ordine_di_arrivo() {
        var coda = CodaAnnunci<String>()
        XCTAssertEqual(accoda(&coda, "primo"), "primo", "a coda vuota l'annuncio si pronuncia subito")
        XCTAssertNil(accoda(&coda, "secondo"), "mentre un annuncio è in corso il successivo attende")
        XCTAssertNil(accoda(&coda, "terzo"))
        XCTAssertEqual(coda.concluso(testo: "primo"), "secondo")
        XCTAssertEqual(coda.concluso(testo: "secondo"), "terzo")
        XCTAssertNil(coda.concluso(testo: "terzo"))
        XCTAssertNil(coda.inCorso)
        XCTAssertTrue(coda.inAttesa.isEmpty)
    }

    func test_05_10_7_l_esito_chiesto_dal_giocatore_supera_cio_che_attende() {
        var coda = CodaAnnunci<String>()
        _ = accoda(&coda, "fatto di ieri")
        _ = accoda(&coda, "altro fatto di ieri")
        _ = accoda(&coda, "comincia il giorno 12")
        XCTAssertEqual(accoda(&coda, "giornata chiusa", interrompente: true), "giornata chiusa",
                       "l'interrompente si pronuncia subito")
        XCTAssertTrue(coda.inAttesa.isEmpty, "ciò che attendeva è superato: resta nel registro (00 §6.4)")
        XCTAssertEqual(coda.inCorso, "giornata chiusa")
        XCTAssertNil(accoda(&coda, "fatto di oggi"), "i fatti che seguono si accodano dietro l'esito")
        XCTAssertEqual(coda.inAttesa.map(\.testo), ["fatto di oggi"])
    }

    /// Il difetto che la corsa col tester avrebbe mostrato dopo la correzione della chiusura: la
    /// conclusione dell'annuncio interrotto arriva dopo, e senza questa regola farebbe partire il
    /// fatto di fondo successivo sopra l'esito appena chiesto.
    func test_la_conclusione_tardiva_dell_annuncio_interrotto_non_fa_avanzare_la_coda() {
        var coda = CodaAnnunci<String>()
        _ = accoda(&coda, "fatto di ieri")
        _ = accoda(&coda, "giornata chiusa", interrompente: true)
        _ = accoda(&coda, "fatto di oggi")
        XCTAssertNil(coda.concluso(testo: "fatto di ieri"),
                     "la conclusione dell'annuncio interrotto non fa partire il successivo")
        XCTAssertEqual(coda.inCorso, "giornata chiusa", "l'esito chiesto resta l'annuncio in corso")
        XCTAssertEqual(coda.concluso(testo: "giornata chiusa"), "fatto di oggi",
                       "conclusa la conferma, il fatto di oggi si pronuncia")
        XCTAssertTrue(coda.interrotti.isEmpty)
    }

    func test_chiusure_ripetute_non_lasciano_indietro_la_coda() {
        var coda = CodaAnnunci<String>()
        // Trenta chiusure di fila, ciascuna con due fatti di fondo, senza che nulla finisca di essere detto.
        for giorno in 1...30 {
            XCTAssertEqual(accoda(&coda, "giornata \(giorno) chiusa", interrompente: true), "giornata \(giorno) chiusa")
            _ = accoda(&coda, "fatto del giorno \(giorno)")
            _ = accoda(&coda, "comincia il giorno \(giorno + 1)")
        }
        XCTAssertEqual(coda.inCorso, "giornata 30 chiusa")
        XCTAssertEqual(coda.inAttesa.map(\.testo), ["fatto del giorno 30", "comincia il giorno 31"],
                       "in attesa restano i soli fatti dell'ultima giornata")
        XCTAssertLessThanOrEqual(coda.interrotti.count, CodaAnnunci<String>.tettoDegliInterrotti,
                                 "gli interrotti ricordati non crescono oltre il tetto")
    }

    /// Nessun caso ferma la coda: una conclusione senza testo, o con un testo che la coda non
    /// riconosce, vale come quella dell'annuncio in corso; e due annunci dallo stesso testo non la
    /// confondono.
    func test_nessuna_conclusione_ferma_la_coda() {
        var coda = CodaAnnunci<String>()
        _ = accoda(&coda, "primo")
        _ = accoda(&coda, "secondo")
        XCTAssertEqual(coda.concluso(testo: nil), "secondo", "senza testo: è quella dell'annuncio in corso")
        _ = accoda(&coda, "terzo")
        XCTAssertEqual(coda.concluso(testo: "testo che il sistema ha cambiato"), "terzo",
                       "un testo non riconosciuto: è quella dell'annuncio in corso")
        XCTAssertNil(coda.concluso(testo: "terzo"))

        // Lo stesso testo interrotto e poi in corso: la conclusione vale per quello in corso.
        _ = accoda(&coda, "giornata chiusa")
        _ = accoda(&coda, "giornata chiusa", interrompente: true)
        _ = accoda(&coda, "fatto")
        XCTAssertEqual(coda.concluso(testo: "giornata chiusa"), "fatto",
                       "a testi uguali la coda avanza: non resta mai ferma")
    }

    func test_05_11_6_la_conclusione_della_campagna_supera_e_ogni_altro_evento_si_accoda() {
        XCTAssertTrue(TraduttoreEventiCampagna.supera(.campagnaConclusa(modo: .inverno, vincitore: nil)))
        XCTAssertTrue(TraduttoreEventiCampagna.supera(.campagnaConclusa(modo: .annientamento, vincitore: .giocatore)))
        XCTAssertFalse(TraduttoreEventiCampagna.supera(.stagioneCambiata(stagione: .estate)))
        XCTAssertFalse(TraduttoreEventiCampagna.supera(
            .presidioOrdinato(gruppo: IdGruppo(2), nome: "lupo", casella: Cella(riga: 10, colonna: 5))))
        XCTAssertFalse(TraduttoreEventiCampagna.supera(
            .rifornimentoInterrotto(gruppo: IdGruppo(1), nome: "corvo", casella: Cella(riga: 5, colonna: 5))))
    }

    /// Acceso il lettore di schermo, la coda riparte vuota (incarico 32): ciò che era stato consegnato
    /// a lettore spento non conclude mai, e terrebbe indietro tutto ciò che segue.
    func test_svuotata_la_coda_riparte() {
        var coda = CodaAnnunci<String>()
        _ = accoda(&coda, "detto a lettore spento")
        XCTAssertNil(accoda(&coda, "fermo dietro il primo"))
        _ = accoda(&coda, "interrompente a lettore spento", interrompente: true)
        coda.svuota()
        XCTAssertEqual(accoda(&coda, "il primo che si sente"), "il primo che si sente")
        XCTAssertTrue(coda.inAttesa.isEmpty)
        XCTAssertTrue(coda.interrotti.isEmpty)
    }

    // MARK: - La finestra del fuoco (incarico 32, RDA-183)

    func test_la_finestra_resta_aperta_per_il_tempo_in_cui_il_fuoco_puo_arrivare() {
        var finestra = FinestraDelFuoco()
        XCTAssertFalse(finestra.eAperta(a: 10), "nessuna richiesta: chiusa")
        finestra.chiesto(a: 10)
        XCTAssertTrue(finestra.eAperta(a: 10))
        // VoiceOver applica lo spostamento 0,77–0,80 s dopo la richiesta (misurato sui simulatori).
        XCTAssertTrue(finestra.eAperta(a: 10.8))
        XCTAssertTrue(finestra.eAperta(a: 10 + FinestraDelFuoco.durata))
        XCTAssertFalse(finestra.eAperta(a: 10.01 + FinestraDelFuoco.durata))
        finestra.chiesto(a: 20)
        XCTAssertTrue(finestra.eAperta(a: 21), "una richiesta nuova la riapre")
        XCTAssertFalse(finestra.eAperta(a: 19.9), "un istante di prima della richiesta non vi cade")
    }

    // MARK: - La conferma del fuoco (incarico 32, RDA-192)

    /// VoiceOver ha portato il fuoco su un altro elemento della schermata: la richiesta si rinnova, una volta
    /// sola, e poi chi si muove è chi gioca.
    func test_02_5_7_la_richiesta_perduta_si_rinnova_una_volta_sola() {
        var conferma = ConfermaDelFuoco()
        XCTAssertFalse(conferma.raggiunto(bersaglio: false, a: 5), "nessuna richiesta: non c'è nulla da rinnovare")
        conferma.chiesto(a: 10)
        XCTAssertTrue(conferma.raggiunto(bersaglio: false, a: 10.8))
        XCTAssertFalse(conferma.raggiunto(bersaglio: false, a: 11.6), "rinnovata una volta, non due")
        conferma.chiesto(a: 20)
        XCTAssertTrue(conferma.raggiunto(bersaglio: false, a: 20.8), "una richiesta nuova ricomincia")
    }

    /// Arrivato il fuoco dove il gioco l'ha chiesto, uno scorrimento di chi gioca non si contrasta.
    func test_02_5_7_arrivato_il_fuoco_chi_si_muove_e_chi_gioca() {
        var conferma = ConfermaDelFuoco()
        conferma.chiesto(a: 10)
        XCTAssertFalse(conferma.raggiunto(bersaglio: true, a: 10.8))
        XCTAssertFalse(conferma.raggiunto(bersaglio: false, a: 11), "lo scorrimento all'elemento dopo")
    }

    /// Finché la richiesta è in viaggio, ciò che riceve il fuoco non la conferma e non la smentisce: il sistema
    /// può passare dall'elemento chiesto e poi applicarla su un altro, o passare da un altro e applicarla bene.
    func test_02_5_7_finche_la_richiesta_e_in_viaggio_il_fuoco_non_conta() {
        var conferma = ConfermaDelFuoco()
        conferma.chiesto(a: 10)
        XCTAssertFalse(conferma.raggiunto(bersaglio: true, a: 10.07), "il sistema passa dall'elemento chiesto")
        XCTAssertTrue(conferma.raggiunto(bersaglio: false, a: 10.8), "e la applica su un altro: si rinnova")
        conferma.chiesto(a: 20)
        XCTAssertFalse(conferma.raggiunto(bersaglio: false, a: 20.03), "il sistema passa da un altro elemento")
        XCTAssertFalse(conferma.raggiunto(bersaglio: true, a: 20.9), "e la applica dove il gioco l'ha chiesta")
        XCTAssertFalse(conferma.raggiunto(bersaglio: false, a: 21.2), "poi chi si muove è chi gioca")
        conferma.chiesto(a: 30)
        XCTAssertTrue(conferma.raggiunto(bersaglio: false, a: 30 + ConfermaDelFuoco.viaggio))
    }

    /// Passato il tempo in cui la richiesta può ancora arrivare, il fuoco è di chi gioca.
    func test_02_5_7_passato_il_tempo_la_richiesta_non_si_rinnova() {
        var conferma = ConfermaDelFuoco()
        conferma.chiesto(a: 10)
        XCTAssertTrue(conferma.raggiunto(bersaglio: false, a: 10 + FinestraDelFuoco.durata))
        conferma.chiesto(a: 20)
        XCTAssertFalse(conferma.raggiunto(bersaglio: false, a: 20.01 + FinestraDelFuoco.durata))
        XCTAssertFalse(conferma.raggiunto(bersaglio: false, a: 20.02 + FinestraDelFuoco.durata))
    }

    /// Gli eventi a cui segue un'altra schermata, e nessun altro.
    func test_gli_eventi_che_cambiano_schermata() {
        XCTAssertTrue(TraduttoreEventiCampagna.cambiaSchermata(.campagnaConclusa(modo: .inverno, vincitore: nil)))
        XCTAssertFalse(TraduttoreEventiCampagna.cambiaSchermata(.giornataAperta(giorno: 2)))
        XCTAssertFalse(TraduttoreEventiCampagna.cambiaSchermata(.battagliaInnescata(casella: Cella(riga: 1, colonna: 1), daImboscata: false)),
                       "una battaglia in sospeso non porta altrove: il passaggio lo decide il giocatore (02 §5.6)")
        XCTAssertTrue(TraduttoreEventi.cambiaSchermata(.battagliaConclusa(EsitoBattaglia(sconfitto: .avversario, modo: .annientamento, turni: 3))))
        XCTAssertFalse(TraduttoreEventi.cambiaSchermata(.turnoIniziato(parte: .giocatore, numeroGiro: 2)))
        XCTAssertTrue(TraduttoreEventiRegno.cambiaSchermata(.campagnaAperta(fronte: "guado")))
        XCTAssertTrue(TraduttoreEventiRegno.cambiaSchermata(.invernoCominciato(anno: 1, entrata: .vuote, mantenimento: .vuote, sciolti: [])))
        XCTAssertTrue(TraduttoreEventiRegno.cambiaSchermata(.primaveraCominciata(anno: 2, perduto: .vuote, ingressi: [], migliorati: [], miglioramentiPerduti: [])))
        XCTAssertFalse(TraduttoreEventiRegno.cambiaSchermata(.stazioneAperta(stazione: 2)),
                       "fra le schermate dell'inverno gli elementi si aggiornano sul posto e il fuoco resta (02 §8.7.3)")
        XCTAssertFalse(TraduttoreEventiRegno.cambiaSchermata(.unitaDestinata(unita: "lupo", alFronte: true)))
    }
}
