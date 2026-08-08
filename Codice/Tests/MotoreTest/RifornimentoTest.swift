import XCTest
import Motore
import Dati
import Contenuti

/// Collaudo del rifornimento (incarico 16, 01 §5.2.2): la catena, il taglio, le zone,
/// l'autonomia e la sosta. Ogni prova cita la regola. Dove serve, colloca forze
/// nemiche o strutture come DATI MINIMI dello scenario — il minimo per rendere
/// provabile la regola, non l'avversario (che non ha condotta né mosse) e non le opere.
final class RifornimentoTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    var motore: MotoreCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
    }

    // MARK: - Attrezzi

    /// Composizione leggera: il volume non incide sul rifornimento, che ignora il volume.
    static let leggera: [ScenarioCampagna.RepartoIniziale] =
        [.init(archetipo: "fanteria_leggera", atomi: 6)]

    /// La mappa `pianura_lunga` è dieci per dieci; il quartier generale del GIOCATORE
    /// sta in basso, riga 10; quello avversario in alto, riga 1. «Retrostante» per il
    /// giocatore è dunque verso le righe crescenti (verso riga 10).
    func crea(gruppi: [(Int, Int)], nemici: [(Int, Int)] = [], strutture: [(Int, Int)] = [],
              mappa: String = "pianura_lunga") throws -> StatoCampagna {
        try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(
                mappa: mappa,
                gruppiGiocatore: gruppi.map {
                    .init(riga: $0.0, colonna: $0.1, composizione: Self.leggera) },
                forzeNemiche: nemici.map { Cella(riga: $0.0, colonna: $0.1) },
                struttureDiRifornimento: strutture.map { Cella(riga: $0.0, colonna: $0.1) }),
            valori: valoriCampagna, archetipiNoti: Set(valori.archetipi.keys))
    }

    func primo(_ s: StatoCampagna) -> Gruppo { s.gruppiOrdinati[0] }

    @discardableResult
    func esegui(_ c: ComandoCampagna, _ s: inout StatoCampagna,
                file: StaticString = #filePath, linea: UInt = #line) -> [EventoCampagna] {
        let esito = motore.valida(c, parte: .giocatore, stato: s)
        XCTAssertTrue(esito.eValido, "comando non valido: \(String(describing: esito.motivo))",
                      file: file, line: linea)
        let (n, e) = motore.applica(c, parte: .giocatore, stato: s); s = n; return e
    }

    func cella(_ r: Int, _ c: Int) -> Cella { Cella(riga: r, colonna: c) }

    // MARK: - 01 §5.2.2.2 — le sei caselle alle spalle e la direzione

    func test_5_2_2_2_le_sei_caselle_sono_tre_colonne_per_due_righe() throws {
        let s = try crea(gruppi: [(5, 5)])
        let spalle = Set(motore.caselleAlleSpalle(di: primo(s), mappa: s.mappa))
        // La riga occupata (5) e quella retrostante verso il quartier generale (6).
        XCTAssertEqual(spalle, Set([(5, 4), (5, 5), (5, 6), (6, 4), (6, 5), (6, 6)].map { cella($0.0, $0.1) }))
    }

    /// La direzione del retro viene dal quartier generale REALE della parte del gruppo,
    /// non da un'assunzione sulla geometria né dall'allineamento dei due quartier
    /// generali (RDA-107, correzione dell'errore che li assumeva allineati).
    func test_5_2_2_2_la_direzione_viene_dal_quartier_generale_reale() throws {
        let s = try crea(gruppi: [(5, 5)])
        // Gruppo del GIOCATORE: quartier generale in basso (riga 10), dietro è la riga 6.
        let miei = Set(motore.caselleAlleSpalle(di: primo(s), mappa: s.mappa))
        XCTAssertTrue(miei.contains(cella(6, 5)))
        XCTAssertFalse(miei.contains(cella(4, 5)))
        // Gruppo AVVERSARIO nella stessa casella: quartier generale in alto (riga 1),
        // dietro è la riga 4. La direzione si RIBALTA, perché segue il quartier generale
        // di quella parte e non una direzione fissa della mappa.
        let avversario = Gruppo(id: IdGruppo(99), parte: .avversario, nome: primo(s).nome,
                                posizione: cella(5, 5), composizione: primo(s).composizione,
                                azioneSpesa: false)
        let suoi = Set(motore.caselleAlleSpalle(di: avversario, mappa: s.mappa))
        XCTAssertTrue(suoi.contains(cella(4, 5)))
        XCTAssertFalse(suoi.contains(cella(6, 5)))
    }

    /// Prima condizione di bordo: sulla riga del proprio quartier generale (riga 10) la
    /// riga retrostante non esiste, e restano le sole tre caselle esistenti della riga
    /// occupata. La fascia da sei si riduce a tre.
    func test_5_2_2_2_bordo_ultima_riga_verso_il_quartier_generale() throws {
        let s = try crea(gruppi: [(10, 5)])
        let spalle = Set(motore.caselleAlleSpalle(di: primo(s), mappa: s.mappa))
        XCTAssertEqual(spalle, Set([(10, 4), (10, 5), (10, 6)].map { cella($0.0, $0.1) }))
    }

    /// Seconda condizione di bordo: su una colonna di bordo (colonna 1) la colonna 0 non
    /// esiste, e la fascia si restringe a due colonne per due righe.
    func test_5_2_2_2_bordo_colonna_la_fascia_si_restringe_a_due() throws {
        let s = try crea(gruppi: [(5, 1)])
        let spalle = Set(motore.caselleAlleSpalle(di: primo(s), mappa: s.mappa))
        XCTAssertEqual(spalle, Set([(5, 1), (5, 2), (6, 1), (6, 2)].map { cella($0.0, $0.1) }))
    }

    /// Il taglio dipende SOLO dalle caselle prescritte: un nemico fuori da quelle sei
    /// non taglia, quale che sia la sua vicinanza.
    func test_5_2_2_2_il_taglio_dipende_solo_dalle_caselle_prescritte() throws {
        func tagliato(_ nemico: (Int, Int)) throws -> Bool {
            let s = try crea(gruppi: [(5, 5)], nemici: [nemico])
            return motore.rifornimentoTagliato(di: primo(s), stato: s)
        }
        XCTAssertTrue(try tagliato((6, 5)), "dietro, in colonna: taglia")
        XCTAssertTrue(try tagliato((6, 4)), "dietro, in diagonale: taglia")
        XCTAssertTrue(try tagliato((5, 6)), "di fianco, sulla riga occupata: taglia")
        XCTAssertFalse(try tagliato((4, 5)), "davanti, verso il nemico: non è alle spalle")
        XCTAssertFalse(try tagliato((7, 5)), "due righe dietro: fuori dalle caselle prescritte")
        XCTAssertFalse(try tagliato((6, 3)), "due colonne di lato: fuori dalle caselle prescritte")
    }

    // MARK: - 01 §5.2.2.6, §5.2.2.7 — le zone

    func test_5_2_2_6_la_zona_e_nove_caselle_e_batte_il_taglio() throws {
        let s = try crea(gruppi: [(5, 5)], nemici: [(6, 5)], strutture: [(5, 5)])
        // Le nove caselle del blocco tre per tre, diagonali comprese.
        for d in -1...1 {
            for e in -1...1 {
                XCTAssertTrue(motore.inZonaDiRifornimento(cella(5 + d, 5 + e), stato: s),
                              "la casella (\(5 + d),\(5 + e)) è nella zona")
            }
        }
        XCTAssertFalse(motore.inZonaDiRifornimento(cella(3, 5), stato: s), "a distanza due non è zona")
        // In zona il taglio non ha effetto: benché il nemico sia alle spalle, il gruppo
        // NON è tagliato, e il suo stato è «in zona».
        XCTAssertFalse(motore.rifornimentoTagliato(di: primo(s), stato: s))
        XCTAssertEqual(motore.statoDiRifornimento(di: primo(s), stato: s), .inZona)
    }

    func test_5_2_2_7_la_fortezza_isolata_rifornisce_comunque() throws {
        // Nessun gruppo attorno alla struttura, nessuna catena: rifornisce per la sola
        // prossimità, che non guarda chi possiede l'intorno.
        let s = try crea(gruppi: [(1, 1)], strutture: [(8, 8)])
        XCTAssertTrue(motore.inZonaDiRifornimento(cella(8, 8), stato: s))
        XCTAssertTrue(motore.inZonaDiRifornimento(cella(7, 8), stato: s))
    }

    // MARK: - 01 §5.2.2.3, §5.2.2.4 — gli effetti: perde tempo, non paralizza

    func test_5_2_2_il_taglio_non_paralizza_e_impone_al_piu_due_soste() throws {
        var s = try crea(gruppi: [(5, 5)], nemici: [(6, 5)])
        let id = primo(s).id
        // Giorno 1: il gruppo PUÒ ancora agire (presidia). A fine giornata il rifornimento
        // si interrompe: senza provviste, primo giorno. Non è un blocco.
        esegui(.presidio(gruppo: id), &s)
        XCTAssertEqual(s.gruppi[id]!.turniSenzaProvviste, 1)
        XCTAssertEqual(s.gruppi[id]!.sostaDovuta, 0)
        XCTAssertEqual(motore.statoDiRifornimento(di: s.gruppi[id]!, stato: s), .senzaProvviste(giorno: 1))
        // Giorno 2: può ancora presidiare (il malus non è un blocco). A fine giornata:
        // secondo turno senza provviste, e SCATTA la sosta imposta di due turni.
        esegui(.presidio(gruppo: id), &s)
        XCTAssertEqual(s.gruppi[id]!.turniSenzaProvviste, 2)
        XCTAssertEqual(s.gruppi[id]!.sostaDovuta, 2)
        // Ora la marcia è vietata (deve rifornirsi) e il presidio pure: il primo turno di
        // sosta è dedicato al rifornimento. Resta la sosta con raccolta.
        XCTAssertFalse(motore.valida(.presidio(gruppo: id), parte: .giocatore, stato: s).eValido)
        XCTAssertTrue(motore.valida(.sostaConRaccolta(gruppo: id), parte: .giocatore, stato: s).eValido)
        // Giorno 3: sosta con raccolta. A fine giornata la sosta scala a uno.
        esegui(.sostaConRaccolta(gruppo: id), &s)
        XCTAssertEqual(s.gruppi[id]!.sostaDovuta, 1)
        // Giorno 4: col secondo turno di sosta si può presidiare (azione diversa dalla marcia).
        XCTAssertTrue(motore.valida(.presidio(gruppo: id), parte: .giocatore, stato: s).eValido)
        esegui(.presidio(gruppo: id), &s)
        // A fine giornata la sosta è esaurita, il rifornimento riprende, i turni si azzerano.
        XCTAssertEqual(s.gruppi[id]!.sostaDovuta, 0)
        XCTAssertEqual(s.gruppi[id]!.turniSenzaProvviste, 0)
        XCTAssertNil(motore.statoDiRifornimento(di: s.gruppi[id]!, stato: s))
        // La ripresa è un fatto non deciso: entra nel registro.
        XCTAssertTrue(s.registro.contains {
            if case .rifornimentoRipreso = $0.fatto { return true }; return false })
    }

    /// L'autonomia: al limite si può SEMPRE fermarsi a rifornirsi di propria iniziativa,
    /// coi giorni di sosta dovuti. Fermandosi al primo turno, la sosta è di uno solo.
    func test_5_2_2_l_autonomia_la_sosta_volontaria_dura_i_turni_digiunati() throws {
        var s = try crea(gruppi: [(5, 5)], nemici: [(6, 5)])
        let id = primo(s).id
        esegui(.presidio(gruppo: id), &s)            // giorno 1 → senza provviste, primo giorno
        XCTAssertEqual(s.gruppi[id]!.turniSenzaProvviste, 1)
        // Giorno 2: di propria iniziativa si ferma a rifornirsi. La sosta è di UN turno.
        esegui(.sostaConRaccolta(gruppo: id), &s)
        XCTAssertEqual(s.gruppi[id]!.sostaDovuta, 0)   // esaurita a fine giornata
        XCTAssertEqual(s.gruppi[id]!.turniSenzaProvviste, 0)
    }

    /// I due conteggi restano distinti (01 §5.2.2.5): questa unità alimenta il solo
    /// contatore della mancanza di provviste; quello della marcia forzata resta a zero.
    func test_5_2_2_5_i_due_conteggi_restano_distinti() throws {
        var s = try crea(gruppi: [(5, 5)], nemici: [(6, 5)])
        let id = primo(s).id
        esegui(.presidio(gruppo: id), &s)
        esegui(.presidio(gruppo: id), &s)
        XCTAssertEqual(s.gruppi[id]!.turniSenzaProvviste, 2)
        XCTAssertEqual(s.gruppi[id]!.turniMarciaForzata, 0)
    }

    // MARK: - 01 §5.17.1 — il registro dei fatti non decisi

    func test_5_17_1_il_taglio_e_la_sosta_imposta_si_annotano() throws {
        var s = try crea(gruppi: [(5, 5)], nemici: [(6, 5)])
        let id = primo(s).id
        esegui(.presidio(gruppo: id), &s)  // interrotto
        esegui(.presidio(gruppo: id), &s)  // sosta imposta
        let fatti = s.registro.map(\.fatto)
        XCTAssertTrue(fatti.contains { if case .rifornimentoInterrotto = $0 { return true }; return false })
        XCTAssertTrue(fatti.contains { if case .sostaDiRifornimento = $0 { return true }; return false })
    }

    /// La sosta VOLONTARIA è un ordine (fatto deciso): l'evento la annuncia, ma il
    /// registro non la annota. A fine giornata entra invece la ripresa, non decisa.
    func test_la_sosta_volontaria_non_entra_nel_registro() throws {
        var s = try crea(gruppi: [(5, 5)], nemici: [(6, 5)])
        let id = primo(s).id
        esegui(.presidio(gruppo: id), &s)         // giorno 1: interrotto (annotato)
        let prima = s.registro.count
        esegui(.sostaConRaccolta(gruppo: id), &s) // giorno 2: sosta ordinata + ripresa
        let nuovi = Array(s.registro[prima...]).map(\.fatto)
        XCTAssertFalse(nuovi.contains { if case .sostaDiRifornimento = $0 { return true }; return false },
                       "la sosta ordinata non si annota")
        XCTAssertTrue(nuovi.contains { if case .rifornimentoRipreso = $0 { return true }; return false },
                      "la ripresa sì")
    }

    // MARK: - 02 §3.8.1 — l'ordine delle voci di casella

    func test_3_8_1_il_rifornimento_e_la_prima_anomalia_dell_occupante() throws {
        var s = try crea(gruppi: [(5, 5)], nemici: [(6, 5)])
        esegui(.presidio(gruppo: primo(s).id), &s)  // senza provviste, primo giorno
        let vista = VistaCampagna(motore: motore, stato: s, parte: .giocatore)
        let voci = vista.vociDiCasella(cella(5, 5))
        guard voci.count >= 2 else { return XCTFail("attese almeno due voci") }
        if case .occupante = voci[0] {} else { XCTFail("prima l'occupante") }
        if case .rifornimento = voci[1] {} else { XCTFail("subito dopo il rifornimento") }
    }

    func test_3_8_1_la_zona_e_una_nota_in_coda() throws {
        let s = try crea(gruppi: [(1, 1)], strutture: [(5, 5)])
        let vista = VistaCampagna(motore: motore, stato: s, parte: .giocatore)
        let voci = vista.vociDiCasella(cella(5, 5))  // casella vuota, in zona
        XCTAssertEqual(voci.last, .zonaDiRifornimento)
    }
}
