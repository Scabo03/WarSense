import XCTest
import Motore
import Dati
import Contenuti

/// Rinforzo della parte più fragile del Motore (incarico fase B): i casi d'angolo
/// della risoluzione delle mischie con i disingaggi. Ogni prova è intestata alla
/// regola che verifica; la precisazione P4 (contatti multipli) è nel registro
/// degli scostamenti.
final class CasiAngoloMischiaTest: XCTestCase {

    var valori: ValoriDiGioco!
    var motore: MotoreBattaglia!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreBattaglia(valori: valori)
    }

    /// Stato costruito a mano sul formato quindici: attrezzo per i casi d'angolo.
    private func statoCostruito(_ sciami: [(IdSciame, Parte, IdentificatoreDati, Cella, Int64)]) throws -> StatoBattaglia {
        let scenario = ScenarioBattaglia(
            formato: "quindici", caratteristica: "campo_aperto",
            primoOccupante: .giocatore, imboscata: false,
            deckGiocatore: [], deckAvversario: [])
        var stato = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
        for (id, parte, archetipo, cella, atomi) in sciami {
            let a = valori.archetipi[archetipo]!
            stato.sciami[id] = Sciame(id: id, parte: parte, archetipo: archetipo,
                                      protezione: .antiSaturazione,
                                      lettera: stato.prossimaLettera[parte] ?? 1,
                                      atomiIniziali: atomi,
                                      serbatoio: atomi * a.puntiVitaPerAtomo,
                                      munizioni: a.dotazioneMunizioni, posizione: cella,
                                      azioneSpesa: false, rinforzo: false)
            stato.forzeImpegnate[parte, default: 0] += stato.sciami[id]!.serbatoio
            stato.prossimaLettera[parte] = (stato.prossimaLettera[parte] ?? 1) + 1
            stato.prossimoIdSciame = max(stato.prossimoIdSciame, id.numero + 1)
        }
        return stato
    }

    private func esegui(_ comando: ComandoBattaglia, _ parte: Parte, _ stato: inout StatoBattaglia,
                        file: StaticString = #filePath, linea: UInt = #line) -> [EventoBattaglia] {
        let esito = motore.valida(comando, parte: parte, stato: stato)
        XCTAssertTrue(esito.eValido, String(describing: esito.motivo), file: file, line: linea)
        let (nuovo, eventi) = motore.applica(comando, parte: parte, stato: stato)
        stato = nuovo
        return eventi
    }

    /// Due attaccanti sullo stesso bersaglio: il bersaglio subisce entrambe le mischie
    /// nello stesso giro (01 §9.7), e quando si disingaggia lascia l'intera mischia:
    /// entrambi i contatti terminano ed entrambe le coppie sono ricordate (01 §9.8.3, P4).
    func test_01_9_8_contatti_multipli_sullo_stesso_sciame() throws {
        // Bersaglio: fanteria leggera (soglia di disingaggio bassa) fra due pesanti.
        var stato = try statoCostruito([
            (IdSciame(1), .giocatore, "fanteria_pesante", Cella(riga: 3, colonna: 1), 3),
            (IdSciame(2), .giocatore, "fanteria_pesante", Cella(riga: 3, colonna: 3), 3),
            (IdSciame(3), .avversario, "fanteria_leggera", Cella(riga: 3, colonna: 2), 3),
        ])
        _ = esegui(.ingaggia(sciame: IdSciame(1), bersaglio: IdSciame(3)), .giocatore, &stato)
        _ = esegui(.ingaggia(sciame: IdSciame(2), bersaglio: IdSciame(3)), .giocatore, &stato)
        XCTAssertEqual(stato.contatti.count, 2)
        _ = esegui(.fineTurno, .giocatore, &stato)
        let serbatoioPrima = stato.sciami[IdSciame(3)]!.serbatoio
        let eventi = esegui(.fineTurno, .avversario, &stato) // giro nuovo: mischie risolte

        // Il bersaglio ha subito il danno di entrambi i contatti nello stesso giro.
        if let bersaglio = stato.sciami[IdSciame(3)] {
            let perdite = serbatoioPrima - bersaglio.serbatoio
            let dannoSingolo = motore.danno(da: stato.sciami[IdSciame(1)]!,
                                            offesa: valori.archetipi["fanteria_pesante"]!.offesaMischia,
                                            a: bersaglio, coefficiente: .uno, stato: stato)
            XCTAssertGreaterThanOrEqual(perdite, dannoSingolo * 2 - 2,
                                        "due contatti, due mischie nello stesso giro (01 §9.7)")
        }
        // Se si è disingaggiato, ha lasciato TUTTA la mischia: nessun contatto residuo
        // che lo coinvolga, ed entrambe le coppie ricordate (P4, 01 §9.8.3).
        let disingaggi = eventi.filter { if case .disingaggio(let chi, _, _) = $0 { return chi == IdSciame(3) }; return false }
        if !disingaggi.isEmpty {
            XCTAssertFalse(stato.impegnato(IdSciame(3)), "chi si ritrae lascia l'intera mischia (P4)")
            XCTAssertTrue(stato.coppieStaccate.contains(Coppia(IdSciame(1), IdSciame(3))))
            XCTAssertTrue(stato.coppieStaccate.contains(Coppia(IdSciame(2), IdSciame(3))))
        } else {
            XCTAssertNil(stato.sciami[IdSciame(3)] ?? nil as Sciame?,
                         "senza disingaggio, sotto due pesanti il bersaglio è disfatto")
        }
    }

    /// Entrambi i reparti della stessa coppia superano la soglia nello stesso giro:
    /// il disingaggio è uno solo, deterministico (l'identificatore minore), e la
    /// coppia entra una sola volta nella memoria (01 §9.8, 00 §3.1).
    func test_01_9_8_disingaggio_doppio_nella_stessa_coppia() throws {
        var stato = try statoCostruito([
            (IdSciame(1), .giocatore, "fanteria_leggera", Cella(riga: 3, colonna: 2), 3),
            (IdSciame(2), .avversario, "fanteria_leggera", Cella(riga: 2, colonna: 2), 3),
        ])
        _ = esegui(.ingaggia(sciame: IdSciame(1), bersaglio: IdSciame(2)), .giocatore, &stato)
        var tuttiEventi: [EventoBattaglia] = []
        var giri = 0
        while stato.contatti.count == 1 && giri < 30 && stato.esito == nil {
            _ = esegui(.fineTurno, stato.parteDiTurno, &stato)
            tuttiEventi += esegui(.fineTurno, stato.parteDiTurno, &stato)
            giri += 1
        }
        let disingaggi = tuttiEventi.filter { if case .disingaggio = $0 { return true }; return false }
        XCTAssertEqual(disingaggi.count, 1, "un solo disingaggio per coppia, anche a soglie pari")
        guard case .disingaggio(let chi, _, _)? = disingaggi.first else { return }
        XCTAssertEqual(chi, IdSciame(1), "a parità decide l'ordine degli identificatori (05 §4.3)")
        XCTAssertEqual(stato.coppieStaccate.count, 1)
        // Determinismo: la stessa costruzione produce lo stesso esito.
        var ripetizione = try statoCostruito([
            (IdSciame(1), .giocatore, "fanteria_leggera", Cella(riga: 3, colonna: 2), 3),
            (IdSciame(2), .avversario, "fanteria_leggera", Cella(riga: 2, colonna: 2), 3),
        ])
        _ = esegui(.ingaggia(sciame: IdSciame(1), bersaglio: IdSciame(2)), .giocatore, &ripetizione)
        var giri2 = 0
        while ripetizione.contatti.count == 1 && giri2 < 30 && ripetizione.esito == nil {
            _ = esegui(.fineTurno, ripetizione.parteDiTurno, &ripetizione)
            _ = esegui(.fineTurno, ripetizione.parteDiTurno, &ripetizione)
            giri2 += 1
        }
        XCTAssertEqual(ripetizione.impronta(), stato.impronta())
    }

    /// Il tattico gioca contro se stesso e la battaglia si conclude, due volte
    /// con la stessa impronta: il tattico è parte del Motore e non fa eccezione
    /// al determinismo (01 §12.1, 05 §5.3).
    func test_05_5_3_il_tattico_e_deterministico_e_conclude() throws {
        func partita() throws -> (String, Int) {
            let scenario = ScenarioBattaglia(
                formato: "quindici", caratteristica: "campo_aperto",
                primoOccupante: .giocatore, imboscata: false,
                deckGiocatore: [.init(archetipo: "fanteria_pesante", protezione: .antiPerforazione, atomi: 3, esemplari: 1)],
                deckAvversario: [.init(archetipo: "fanteria_leggera", protezione: .antiSaturazione, atomi: 3, esemplari: 2)],
                ufficialeAvversario: "ufficiale_prova")
            var stato = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
            let ufficiale = valori.ufficiali["ufficiale_prova"]!
            let tatticoG = TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .giocatore)
            let tatticoA = TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .avversario)
            var passi = 0
            while stato.esito == nil && passi < 4000 {
                let tattico = stato.parteDiTurno == .giocatore ? tatticoG : tatticoA
                let comando = tattico.prossimoComando(stato: stato)
                let esito = motore.valida(comando, parte: stato.parteDiTurno, stato: stato)
                XCTAssertTrue(esito.eValido, "il tattico propone solo comandi validi")
                (stato, _) = motore.applica(comando, parte: stato.parteDiTurno, stato: stato)
                passi += 1
            }
            XCTAssertNotNil(stato.esito, "la battaglia guidata dal tattico si conclude")
            return (stato.impronta(), passi)
        }
        let (prima, passi1) = try partita()
        let (seconda, passi2) = try partita()
        XCTAssertEqual(prima, seconda)
        XCTAssertEqual(passi1, passi2)
    }
}
