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
}
