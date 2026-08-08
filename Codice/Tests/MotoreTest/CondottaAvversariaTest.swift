import XCTest
import Dati
import Motore
import Contenuti

/// Collaudo della condotta deterministica dell'avversario di campagna (01 §12.1,
/// §5.11.1, incarico 18): è interamente deterministica e decide SOLTANTO sulla propria
/// vista, cieca alle posizioni del giocatore che non osserva.
final class CondottaAvversariaTest: XCTestCase {
    var valori: ValoriDiGioco!
    var vc: ValoriCampagna!
    var motore: MotoreCampagna!
    let condotta = CondottaAvversaria()

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        vc = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: vc)
    }

    /// Uno stato di prova: un gruppo avversario in alto e un gruppo del giocatore, la
    /// cui posizione si può spostare per provare la cecità.
    private func stato(giocatore: Cella) throws -> StatoCampagna {
        try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: "pianura_lunga",
                gruppiGiocatore: [.init(riga: giocatore.riga, colonna: giocatore.colonna,
                                        composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)])],
                gruppiAvversario: [.init(riga: 2, colonna: 5,
                                         composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)])]),
            valori: vc, archetipiNoti: Set(valori.archetipi.keys))
    }

    // MARK: - Determinismo (01 §12.1, RDA-07)

    func test_01_12_1_la_stessa_vista_produce_lo_stesso_comando() throws {
        let s = try stato(giocatore: Cella(riga: 9, colonna: 5))
        let vista = motore.vistaAvversario(stato: s)
        let c1 = condotta.prossimoComando(vista: vista)
        let c2 = condotta.prossimoComando(vista: vista)
        XCTAssertEqual(c1, c2, "l'avversario non è deterministico: due decisioni divergono")
        XCTAssertNotNil(c1)
    }

    // MARK: - Cecità: decide solo su ciò che possiede (01 §5.11.1, RDA-114)

    func test_01_5_11_1_una_posizione_del_giocatore_non_osservata_non_cambia_la_decisione() throws {
        // Il gruppo avversario è a (2,5), raggio di osservazione 1: osserva le caselle a
        // distanza ortogonale <= 1. Un gruppo del giocatore lontano — riga 9 e riga 10,
        // entrambe fuori dalla sua osservazione — non deve cambiare la sua scelta.
        let a = try stato(giocatore: Cella(riga: 9, colonna: 5))
        let b = try stato(giocatore: Cella(riga: 10, colonna: 8))
        // Nessuna delle due posizioni del giocatore è osservata dall'avversario.
        XCTAssertFalse(motore.osservata(Cella(riga: 9, colonna: 5), da: .avversario, stato: a))
        XCTAssertFalse(motore.osservata(Cella(riga: 10, colonna: 8), da: .avversario, stato: b))
        let ca = condotta.prossimoComando(vista: motore.vistaAvversario(stato: a))
        let cb = condotta.prossimoComando(vista: motore.vistaAvversario(stato: b))
        XCTAssertEqual(ca, cb,
                       "l'avversario decide su informazione che non possiede: la posizione nascosta del giocatore ha cambiato la sua mossa")
    }

    func test_01_5_11_1_la_vista_contiene_solo_le_caselle_osservate() throws {
        // Un gruppo del giocatore ADIACENTE all'avversario (osservato) e uno lontano
        // (non osservato): la vista contiene solo il primo.
        let s = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: "pianura_lunga",
                gruppiGiocatore: [
                    .init(riga: 3, colonna: 5, composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)]),
                    .init(riga: 10, colonna: 1, composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)])],
                gruppiAvversario: [.init(riga: 2, colonna: 5,
                                         composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)])]),
            valori: vc, archetipiNoti: Set(valori.archetipi.keys))
        let vista = motore.vistaAvversario(stato: s)
        XCTAssertTrue(vista.formazioniGiocatoreNote.contains(Cella(riga: 3, colonna: 5)),
                      "il giocatore adiacente, osservato, deve comparire nella vista")
        XCTAssertFalse(vista.formazioniGiocatoreNote.contains(Cella(riga: 10, colonna: 1)),
                       "il giocatore lontano, non osservato, non deve comparire nella vista")
        XCTAssertEqual(vista.formazioniGiocatoreNote.count, 1)
    }

    // MARK: - Comportamento riconoscibile

    func test_incarico_18_avanza_verso_il_quartier_generale_del_giocatore() throws {
        // Senza minacce né formazioni note, l'avversario avanza verso il quartier
        // generale del giocatore (riga 10): la mossa riduce la distanza (aggressività).
        let s = try stato(giocatore: Cella(riga: 10, colonna: 1)) // giocatore fuori vista
        let qgGiocatore = s.mappa.quartierGenerale(di: .giocatore)
        let avv = s.gruppi(di: .avversario).first!
        let distPrima = s.griglia.distanza(avv.posizione, qgGiocatore)
        guard case .marcia(_, let dest, _) = condotta.prossimoComando(vista: motore.vistaAvversario(stato: s)) else {
            return XCTFail("l'avversario non ha marciato verso l'obiettivo")
        }
        XCTAssertLessThan(s.griglia.distanza(dest, qgGiocatore), distPrima,
                          "la marcia non avvicina l'avversario al quartier generale del giocatore")
    }

    /// Un comando prodotto dalla condotta è SEMPRE valido per lo stesso percorso di
    /// chiunque (nessuna via a parte, incarico 18): giocando molte giornate contro
    /// l'avversario, `applica` non deve mai rifiutare per la precondizione.
    func test_incarico_18_ogni_comando_dell_avversario_e_valido() throws {
        var s = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: "guado",
                gruppiGiocatore: [.init(riga: 4, colonna: 2, composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)])],
                gruppiAvversario: [
                    .init(riga: 1, colonna: 2, composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)]),
                    .init(riga: 1, colonna: 3, composizione: [.init(archetipo: "fanteria_pesante", atomi: 24)])]),
            valori: vc, archetipiNoti: Set(valori.archetipi.keys))
        for _ in 0..<60 {
            if let g = s.gruppiInAttesa(di: .giocatore).first {
                (s, _) = motore.applica(.presidio(gruppo: g.id), parte: .giocatore, stato: s)
            }
            while s.gruppiInAttesa(di: .giocatore).isEmpty, !s.gruppiInAttesa(di: .avversario).isEmpty {
                let c = condotta.prossimoComando(vista: motore.vistaAvversario(stato: s))!
                XCTAssertTrue(motore.valida(c, parte: .avversario, stato: s).eValido,
                              "comando avversario non valido: \(c)")
                (s, _) = motore.applica(c, parte: .avversario, stato: s)
            }
        }
    }
}
