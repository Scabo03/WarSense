import XCTest
import Motore
import Dati
import Contenuti

/// Divisione e riunione dei gruppi (01 §5.6.0.2, §5.6.0.3, §5.6.0.4). Ogni prova
/// cita la regola che verifica.
final class DivisioneRiunioneTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    var motore: MotoreCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
    }

    typealias RI = ScenarioCampagna.RepartoIniziale
    let leggera = RI(archetipo: "fanteria_leggera", atomi: 6)      // volume 60
    let pesante = RI(archetipo: "fanteria_pesante", atomi: 20)     // volume 280

    func stato(_ gruppi: [(Int, Int, [RI])], mappa: String = "guado") throws -> StatoCampagna {
        try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: mappa, gruppiGiocatore: gruppi.map {
                .init(riga: $0.0, colonna: $0.1, composizione: $0.2) }),
            valori: valoriCampagna, archetipiNoti: Set(valori.archetipi.keys))
    }

    @discardableResult
    func esegui(_ comando: ComandoCampagna, _ s: inout StatoCampagna,
                file: StaticString = #filePath, line: UInt = #line) -> [EventoCampagna] {
        let esito = motore.valida(comando, parte: .giocatore, stato: s)
        XCTAssertTrue(esito.eValido, "non valido: \(String(describing: esito.motivo))", file: file, line: line)
        let (nuovo, eventi) = motore.applica(comando, parte: .giocatore, stato: s)
        s = nuovo
        return eventi
    }

    // MARK: - 01 §5.6.0.2 — la divisione

    func test_01_5_6_0_2_la_divisione_stacca_reparti_costa_l_azione_e_nasce_gia_agito() throws {
        // Due gruppi, così la giornata non si chiude ordinandone uno.
        var s = try stato([(2, 2, [leggera, pesante]), (3, 3, [leggera])])
        let id = s.occupante(di: Cella(riga: 2, colonna: 2))!.id
        let nomiPrima = Set(s.gruppiOrdinati.map(\.nome))
        let dest = Cella(riga: 2, colonna: 1)
        let eventi = esegui(.divisione(gruppo: id, repartiStaccati: [1], a: dest), &s)

        // Origine: conserva id, nome, casella; tiene il reparto [0]; azione spesa.
        let origine = s.gruppi[id]!
        XCTAssertEqual(origine.posizione, Cella(riga: 2, colonna: 2))
        XCTAssertEqual(origine.composizione, [Reparto(archetipo: "fanteria_leggera", atomi: 6)])
        XCTAssertTrue(origine.azioneSpesa, "la divisione costa l'azione del gruppo di origine")
        // Distaccamento: nella casella adiacente, con il reparto [1], nome NUOVO, già agito.
        let distacco = s.occupante(di: dest)!
        XCTAssertNotEqual(distacco.id, id)
        XCTAssertEqual(distacco.composizione, [Reparto(archetipo: "fanteria_pesante", atomi: 20)])
        XCTAssertFalse(nomiPrima.contains(distacco.nome), "il distaccamento riceve un nome nuovo (01 §5.6.0.4)")
        XCTAssertTrue(distacco.azioneSpesa, "il distaccamento nasce avendo già agito (collocamento = spostamento)")
        XCTAssertNil(distacco.marcia, "il distaccamento non nasce in marcia")
        // La somma delle due parti eguaglia il gruppo di prima.
        XCTAssertEqual(Set(origine.composizione + distacco.composizione),
                       [Reparto(archetipo: "fanteria_leggera", atomi: 6),
                        Reparto(archetipo: "fanteria_pesante", atomi: 20)])
        XCTAssertTrue(eventi.contains { if case .gruppoDiviso = $0 { return true } else { return false } })
    }

    func test_01_5_6_0_2_il_distaccamento_non_nasce_nella_casella_di_origine() throws {
        let s = try stato([(2, 2, [leggera, pesante]), (2, 3, [leggera])])
        let id = s.occupante(di: Cella(riga: 2, colonna: 2))!.id
        // La casella di origine non è adiacente a sé: la divisione verso di essa è rifiutata.
        XCTAssertEqual(motore.valida(.divisione(gruppo: id, repartiStaccati: [1],
                                                a: Cella(riga: 2, colonna: 2)),
                                     parte: .giocatore, stato: s).motivo, .nonAdiacente)
        // Verso la casella (2,3), occupata dall'altro gruppo: rifiutata.
        XCTAssertEqual(motore.valida(.divisione(gruppo: id, repartiStaccati: [1],
                                                a: Cella(riga: 2, colonna: 3)),
                                     parte: .giocatore, stato: s).motivo, .occupata)
    }

    func test_01_5_6_0_2_nessuna_parte_puo_restare_vuota() throws {
        var s = try stato([(2, 2, [leggera, pesante]), (3, 3, [leggera])])
        let id = s.occupante(di: Cella(riga: 2, colonna: 2))!.id
        let dest = Cella(riga: 2, colonna: 1)
        // Nessun reparto staccato: una parte resterebbe vuota.
        XCTAssertEqual(motore.valida(.divisione(gruppo: id, repartiStaccati: [], a: dest),
                                     parte: .giocatore, stato: s).motivo, .divisioneImpropria)
        // Tutti i reparti staccati: l'origine resterebbe vuota.
        XCTAssertEqual(motore.valida(.divisione(gruppo: id, repartiStaccati: [0, 1], a: dest),
                                     parte: .giocatore, stato: s).motivo, .divisioneImpropria)
        // Indici ripetuti o inesistenti: rifiutati.
        XCTAssertEqual(motore.valida(.divisione(gruppo: id, repartiStaccati: [1, 1], a: dest),
                                     parte: .giocatore, stato: s).motivo, .divisioneImpropria)
        XCTAssertEqual(motore.valida(.divisione(gruppo: id, repartiStaccati: [5], a: dest),
                                     parte: .giocatore, stato: s).motivo, .divisioneImpropria)
        _ = s
    }

    func test_01_5_6_0_2_un_gruppo_in_marcia_lunga_non_si_divide() throws {
        // Un gruppo in acqua marcia più giorni e resta inchiodato; l'altro attende.
        var s = try stato([(3, 3, [leggera, pesante]), (4, 3, [leggera])])
        let id = s.occupante(di: Cella(riga: 3, colonna: 3))!.id
        // (2,3) è acqua sul guado: la marcia dura più di un giorno e il gruppo resta in marcia.
        let costo = motore.costoInGiorni(da: Cella(riga: 3, colonna: 3), a: Cella(riga: 2, colonna: 3), stato: s)
        esegui(.marcia(gruppo: id, a: Cella(riga: 2, colonna: 3), giorni: costo), &s)
        XCTAssertTrue(s.gruppi[id]!.inMarcia, "il gruppo è inchiodato dalla marcia lunga")
        // Ciò che il giocatore sente provando a dividere: «inchiodato», non «azione già spesa».
        XCTAssertEqual(motore.valida(.divisione(gruppo: id, repartiStaccati: [1], a: Cella(riga: 3, colonna: 2)),
                                     parte: .giocatore, stato: s).motivo, .gruppoInchiodato)
    }

    // MARK: - 01 §5.6.0.3 — la riunione

    func test_01_5_6_0_3_la_riunione_conserva_il_nome_del_maggiore_e_unisce_i_reparti() throws {
        // A a (2,2) è il maggiore per volume (280 > 60); B a (2,3) è adiacente.
        var s = try stato([(2, 2, [pesante]), (2, 3, [leggera])])
        let a = s.occupante(di: Cella(riga: 2, colonna: 2))!
        let b = s.occupante(di: Cella(riga: 2, colonna: 3))!
        let eventi = esegui(.riunione(gruppo: b.id, con: a.id), &s)   // ordine irrilevante
        // Il risultante è il maggiore: nome, id e casella di A; l'altro sparisce.
        XCTAssertNil(s.gruppi[b.id], "il gruppo minore è stato assorbito")
        let risultante = s.gruppi[a.id]!
        XCTAssertEqual(risultante.nome, a.nome, "il risultante conserva il nome del maggiore")
        XCTAssertEqual(risultante.posizione, Cella(riga: 2, colonna: 2))
        XCTAssertEqual(Set(risultante.composizione),
                       [Reparto(archetipo: "fanteria_pesante", atomi: 20),
                        Reparto(archetipo: "fanteria_leggera", atomi: 6)], "i reparti si uniscono")
        XCTAssertTrue(eventi.contains { if case .gruppiRiuniti = $0 { return true } else { return false } })
    }

    func test_01_5_6_0_3_la_riunione_non_costa_l_azione_ma_eredita_l_azione_spesa() throws {
        // Due gruppi in attesa: riuniti, il risultante è ancora in attesa (non costa l'azione).
        var s = try stato([(2, 2, [pesante]), (2, 3, [leggera])])
        let a = s.occupante(di: Cella(riga: 2, colonna: 2))!.id
        let b = s.occupante(di: Cella(riga: 2, colonna: 3))!.id
        esegui(.riunione(gruppo: a, con: b), &s)
        XCTAssertFalse(s.gruppi[a]!.azioneSpesa, "riuniti due gruppi fermi, il risultante può ancora agire")

        // Se UNO dei due aveva agito, il risultante risulta avere agito (01 §5.6.0.3).
        var s2 = try stato([(2, 2, [pesante]), (2, 3, [leggera]), (3, 3, [leggera])])
        let a2 = s2.occupante(di: Cella(riga: 2, colonna: 2))!.id
        let b2 = s2.occupante(di: Cella(riga: 2, colonna: 3))!.id
        esegui(.presidio(gruppo: b2), &s2)   // b2 ha agito; la giornata resta aperta (terzo gruppo)
        esegui(.riunione(gruppo: a2, con: b2), &s2)
        XCTAssertTrue(s2.gruppi[a2]!.azioneSpesa,
                      "riunito con uno che aveva agito, il risultante ha l'azione spesa")
    }

    func test_01_5_6_0_3_un_gruppo_in_marcia_lunga_non_si_riunisce() throws {
        var s = try stato([(3, 3, [leggera, pesante]), (3, 2, [leggera])])
        let id = s.occupante(di: Cella(riga: 3, colonna: 3))!.id
        let altro = s.occupante(di: Cella(riga: 3, colonna: 2))!.id
        let costo = motore.costoInGiorni(da: Cella(riga: 3, colonna: 3), a: Cella(riga: 2, colonna: 3), stato: s)
        esegui(.marcia(gruppo: id, a: Cella(riga: 2, colonna: 3), giorni: costo), &s)
        XCTAssertTrue(s.gruppi[id]!.inMarcia)
        XCTAssertEqual(motore.valida(.riunione(gruppo: altro, con: id),
                                     parte: .giocatore, stato: s).motivo, .gruppoInchiodato)
    }
}
