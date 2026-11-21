import XCTest
@testable import Verifica
import Motore
import Dati
import Contenuti

/// La misura della frequenza delle battaglie (incarico 29): la condotta «competente» è quella del banco
/// e lo strumento non ne inventa un'altra; le partite misurate sono coerenti.
final class MisuraFrequenzaBattaglieTest: XCTestCase {

    private func strumenti() throws -> (BancoCampagna, MisuraFrequenzaBattaglie, ScenariCampagna) {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        let scenari = try ScenariCampagna.carica(da: Ambiente.scenariCampagnaDiFabbrica)
        let motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
        return (BancoCampagna(motore: motore, valoriCampagna: valoriCampagna, scenari: scenari),
                MisuraFrequenzaBattaglie(motore: motore, valoriCampagna: valoriCampagna), scenari)
    }

    /// Con sfasamento 0 la condotta competente dello strumento compie le stesse scelte del banco: sugli
    /// scenari del banco con l'avversario, dopo le stesse giornate, lo stato finale ha la stessa impronta.
    func test_la_condotta_competente_e_quella_del_banco() throws {
        let (banco, misura, scenari) = try strumenti()
        let conAvversario = scenari.scenari.filter { !$0.gruppiAvversario.isEmpty }
        XCTAssertFalse(conAvversario.isEmpty)
        var confronti = 0
        for voce in conAvversario {
            let giornate = 20
            let corsa = try banco.corri(voce, giornate: giornate)
            let scenario = ScenarioCampagna(mappa: voce.mappa, gruppiGiocatore: voce.gruppi,
                                            gruppiAvversario: voce.gruppiAvversario,
                                            forzeNemiche: voce.forzeNemiche,
                                            struttureDiRifornimento: voce.struttureDiRifornimento)
            let (partita, stato) = try misura.giocaConStato(scenario: scenario, formato: voce.identificatore,
                                                           condotta: .competente, seme: 0,
                                                           limiteGiornate: giornate, fermaAllaFineNaturale: false)
            // Il banco chiude la corsa quando nessun gruppo del giocatore attende alla scelta: lì il confronto
            // non ha senso, e lo si dichiara invece di tacerlo.
            guard corsa.giornate == giornate else {
                print("FREQUENZA-FEDELTA \(voce.identificatore): corsa del banco chiusa al giorno \(corsa.giornate), non confrontata")
                continue
            }
            XCTAssertEqual(stato.impronta(), corsa.improntaFinale,
                           "\(voce.identificatore): la condotta competente non è quella del banco")
            XCTAssertEqual(partita.battaglie, corsa.battaglieGiocate, "\(voce.identificatore): battaglie diverse dal banco")
            confronti += 1
        }
        print("FREQUENZA-FEDELTA confronti=\(confronti) su \(conAvversario.count)")
        XCTAssertGreaterThan(confronti, 0, "almeno uno scenario confrontato")
    }

    /// Le partite misurate sono coerenti: nessuna si ferma, le battaglie contate sono quelle elencate, la
    /// prima battaglia è la prima elencata, la durata non supera il limite.
    func test_le_partite_misurate_sono_coerenti() throws {
        let rapporto = try FrequenzaBattaglieDaRigaDiComando.esegui(
            cartellaValori: Contenuti.valoriDiFabbrica, partite: 2, giornateMassime: 40)
        XCTAssertEqual(rapporto.partite.count, 2 * 2 * FrequenzaBattaglieDaRigaDiComando.formati.count)
        for p in rapporto.partite {
            XCTAssertNotEqual(p.fine, .ferma, "\(p.formato)/\(p.condotta)/\(p.seme): la partita si è fermata")
            XCTAssertEqual(p.battaglie, p.giornateDelleBattaglie.count)
            XCTAssertEqual(p.primaBattaglia, p.giornateDelleBattaglie.first)
            XCTAssertLessThanOrEqual(p.giornate, 40)
            XCTAssertEqual(p.vinte + p.perse, p.battaglie)
        }
        print(rapporto.testo)
    }
}
