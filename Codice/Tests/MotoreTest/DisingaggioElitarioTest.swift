import XCTest
import Motore
import Dati
import Contenuti

/// Le meccaniche del disingaggio dell'incarico 10: il reparto elitario che non si sfila
/// mai (soglia assente), il coefficiente di logoramento sulla soglia, e il disingaggio su
/// ordine riservato all'elitario. Ogni prova è intestata alla regola che verifica, e
/// ciascun cancello è visto rifiutare lo stato sbagliato.
final class DisingaggioElitarioTest: XCTestCase {

    var valori: ValoriDiGioco!
    var motore: MotoreBattaglia!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreBattaglia(valori: valori)
    }

    /// Costruisce uno stato con reparti collocati a mano, sul formato quindici.
    private func stato(_ sciami: [(IdSciame, Parte, IdentificatoreDati, Cella, Int64)]) throws -> StatoBattaglia {
        let scenario = ScenarioBattaglia(formato: "quindici", caratteristica: "campo_aperto",
                                         primoOccupante: .giocatore, imboscata: false,
                                         deckGiocatore: [], deckAvversario: [])
        var s = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
        for (id, parte, archetipo, cella, atomi) in sciami {
            let a = valori.archetipi[archetipo]!
            s.sciami[id] = Sciame(id: id, parte: parte, archetipo: archetipo, protezione: .antiSaturazione,
                                  lettera: s.prossimaLettera[parte] ?? 1, atomiIniziali: atomi,
                                  serbatoio: atomi * a.puntiVitaPerAtomo, munizioni: a.dotazioneMunizioni,
                                  posizione: cella, azioneSpesa: false, rinforzo: false)
            s.forzeImpegnate[parte, default: 0] += s.sciami[id]!.serbatoio
            s.prossimaLettera[parte] = (s.prossimaLettera[parte] ?? 1) + 1
            s.prossimoIdSciame = max(s.prossimoIdSciame, id.numero + 1)
        }
        return s
    }

    @discardableResult
    private func esegui(_ c: ComandoBattaglia, _ p: Parte, _ s: inout StatoBattaglia) -> [EventoBattaglia] {
        XCTAssertTrue(motore.valida(c, parte: p, stato: s).eValido, String(describing: motore.valida(c, parte: p, stato: s).motivo))
        let (nuovo, eventi) = motore.applica(c, parte: p, stato: s)
        s = nuovo
        return eventi
    }

    // MARK: - Seconda decisione: il reparto elitario non si sfila mai (soglia assente)

    /// Di fabbrica il solo `guardia_elite` ha soglia assente, e nessun altro: l'assenza è
    /// leggibile come tale (nil), non confondibile con una soglia molto alta (incarico 10).
    func test_incarico10_solo_l_elitario_ha_soglia_assente() {
        XCTAssertNil(valori.archetipi["guardia_elite"]!.sogliaDisingaggio,
                     "il reparto elitario non ha soglia: è l'assenza, non un valore estremo")
        for (id, a) in valori.archetipi where id != "guardia_elite" {
            XCTAssertNotNil(a.sogliaDisingaggio, "solo l'elitario ha soglia assente, non \(id)")
        }
    }

    /// L'elitario non si disingaggia MAI da sé, per quante perdite subisca (01 §9.8, seconda
    /// decisione). Un solo assalitore moderato lo logora a poco a poco: l'elitario supera una
    /// soglia tipica (25 %) RESTANDO ingaggiato — che è ciò che una soglia, quale che fosse,
    /// farebbe scattare — e prosegue fino alla distruzione senza mai sfilarsi. La condizione
    /// «ancora ingaggiato oltre la soglia tipica» distingue l'assenza di soglia dalla sola
    /// mancanza di perdite: se all'elitario si desse una soglia, si sfilerebbe prima e la
    /// condizione cadrebbe.
    func test_incarico10_l_elitario_non_si_sfila_mai_automaticamente() throws {
        var s = try stato([
            (IdSciame(1), .giocatore, "fanteria_pesante", Cella(riga: 2, colonna: 2), 4),
            (IdSciame(2), .avversario, "guardia_elite", Cella(riga: 3, colonna: 2), 3),
        ])
        let ingresso = s.sciami[IdSciame(2)]!.serbatoio
        esegui(.ingaggia(sciame: IdSciame(1), bersaglio: IdSciame(2)), .giocatore, &s)
        var disingaggiElitario = false
        var oltreSogliaTipicaRestandoIngaggiato = false
        var giri = 0
        while s.sciami[IdSciame(2)] != nil && s.esito == nil && giri < 40 {
            let eventi = esegui(.fineTurno, s.parteDiTurno, &s)
            if eventi.contains(where: { if case .disingaggio(let chi, _, _) = $0 { return chi == IdSciame(2) }; return false }) {
                disingaggiElitario = true
            }
            if let elite = s.sciami[IdSciame(2)], s.impegnato(IdSciame(2)),
               (ingresso - elite.serbatoio) * 1000 / ingresso >= 250 {
                oltreSogliaTipicaRestandoIngaggiato = true
            }
            giri += 1
        }
        XCTAssertFalse(disingaggiElitario, "l'elitario non si sfila mai da sé, nemmeno logorato")
        XCTAssertTrue(oltreSogliaTipicaRestandoIngaggiato,
                      "l'elitario supera il 25 % delle perdite restando a contatto: è l'assenza di soglia a trattenerlo")
        XCTAssertNil(s.sciami[IdSciame(2)], "senza mai sfilarsi, l'elitario prosegue fino alla distruzione")
    }

    // MARK: - Quarta decisione: il coefficiente di logoramento sulla soglia

    /// La soglia effettiva di un reparto fresco è quella di base; quella di un reparto
    /// logorato all'ingresso è più bassa, in misura del coefficiente (incarico 10).
    func test_incarico10_il_logoramento_abbassa_la_soglia_del_reparto_gia_logorato() throws {
        let s = try stato([(IdSciame(1), .giocatore, "fanteria_pesante", Cella(riga: 2, colonna: 2), 5)])
        let sciame = s.sciami[IdSciame(1)]!
        let base = valori.archetipi["fanteria_pesante"]!.sogliaDisingaggio!
        let pieno = sciame.atomiIniziali * valori.archetipi["fanteria_pesante"]!.puntiVitaPerAtomo
        // Fresco (ingresso pieno): soglia effettiva = base.
        let fresco = motore.sogliaDisingaggioEffettiva(base: base, sciame: sciame, consistenzaIngresso: pieno)
        XCTAssertEqual(fresco, base, "a integrità piena la soglia effettiva è quella di base")
        // Logorato (ingresso a metà): soglia effettiva minore della base.
        let logorato = motore.sogliaDisingaggioEffettiva(base: base, sciame: sciame,
                                                         consistenzaIngresso: pieno / 2)
        XCTAssertLessThan(logorato, base, "un reparto logorato all'ingresso cede prima")
        // Con coefficiente attivo il calo è positivo; il coefficiente sta nei dati.
        XCTAssertGreaterThan(valori.combattimento.coefficienteLogoramentoSoglia, .zero,
                             "il coefficiente di logoramento è attivo nei dati distribuiti")
    }

    // MARK: - Terza decisione: il disingaggio su ordine, riservato all'elitario a contatto

    /// L'azione di disingaggio su ordine è valida SOLO per il reparto elitario e SOLO
    /// quando è a contatto; per ogni altro reparto e per l'elitario non impegnato è
    /// respinta, sicché la schermata non la offre mai (01 §9.5, incarico 10, terza decisione).
    func test_incarico10_disingaggio_su_ordine_solo_elitario_a_contatto() throws {
        var s = try stato([
            (IdSciame(1), .giocatore, "guardia_elite", Cella(riga: 3, colonna: 2), 3),
            (IdSciame(2), .avversario, "fanteria_pesante", Cella(riga: 2, colonna: 2), 3),
            (IdSciame(3), .giocatore, "fanteria_pesante", Cella(riga: 3, colonna: 3), 3),
        ])
        // Elitario NON a contatto: respinto.
        XCTAssertFalse(motore.valida(.disingaggiaSuOrdine(sciame: IdSciame(1)), parte: .giocatore, stato: s).eValido,
                       "l'elitario non a contatto non può disingaggiarsi su ordine")
        // Passa il turno all'avversario, che ingaggia l'elitario; poi torna al giocatore.
        s = motore.applica(.fineTurno, parte: .giocatore, stato: s).0
        XCTAssertEqual(s.parteDiTurno, .avversario)
        s = motore.applica(.ingaggia(sciame: IdSciame(2), bersaglio: IdSciame(1)), parte: .avversario, stato: s).0
        s = motore.applica(.fineTurno, parte: .avversario, stato: s).0
        XCTAssertEqual(s.parteDiTurno, .giocatore)
        XCTAssertTrue(s.impegnato(IdSciame(1)), "l'elitario è a contatto")
        // Non elitario a contatto: respinto.
        XCTAssertFalse(motore.valida(.disingaggiaSuOrdine(sciame: IdSciame(3)), parte: .giocatore, stato: s).eValido,
                       "un reparto non elitario non ha il disingaggio su ordine")
        // Elitario a contatto: valido, e l'applicazione lo sfila e chiude i suoi contatti.
        XCTAssertTrue(motore.valida(.disingaggiaSuOrdine(sciame: IdSciame(1)), parte: .giocatore, stato: s).eValido,
                      "l'elitario a contatto può disingaggiarsi su ordine")
        let eventi = esegui(.disingaggiaSuOrdine(sciame: IdSciame(1)), .giocatore, &s)
        XCTAssertTrue(eventi.contains { if case .disingaggio(let chi, _, _) = $0 { return chi == IdSciame(1) }; return false },
                      "il disingaggio su ordine è annunciato con l'evento di disingaggio")
        XCTAssertFalse(s.impegnato(IdSciame(1)), "dopo l'ordine l'elitario ha lasciato la mischia")
    }
}
