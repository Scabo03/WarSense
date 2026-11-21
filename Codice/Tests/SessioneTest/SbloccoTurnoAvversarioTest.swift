import XCTest
@testable import Sessione
import Motore
import Dati
import Contenuti

/// Lo SBLOCCO del turno avversario (incarico 28), un livello sotto la Sessione. La condotta
/// dell'avversario propone sempre comandi che il Motore convalida — lo sorveglia il banco, con gli
/// invarianti di transizione su ogni comando —, sicché il blocco dalla parte dell'avversario non si
/// produce in una partita vera; se si producesse, fino alla build 28 il comando respinto sarebbe stato
/// applicato comunque, fermando l'applicazione sulla precondizione di `MotoreCampagna.applica`. La
/// decisione del passo (`decidiPassoAvversario`) è la funzione che il turno avversario usa per OGNI
/// proposta della condotta; qui le si dà a mano una proposta che il Motore respinge.
final class SbloccoTurnoAvversarioTest: XCTestCase {
    var motore: MotoreCampagna!
    var stato: StatoCampagna!
    var avversario: IdGruppo!

    override func setUpWithError() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
        let leggera: [ScenarioCampagna.RepartoIniziale] = [.init(archetipo: "fanteria_leggera", atomi: 6)]
        stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: "pianura_lunga",
                                       gruppiGiocatore: [.init(riga: 10, colonna: 5, composizione: leggera)],
                                       gruppiAvversario: [.init(riga: 1, colonna: 5, composizione: leggera)]),
            valori: valoriCampagna, archetipiNoti: Set(valori.archetipi.keys))
        avversario = stato.gruppi(di: .avversario)[0].id
    }

    /// Una proposta valida passa com'è, senza sblocco, con o senza il tasto.
    func test_incarico_28_la_proposta_valida_passa() {
        for sblocca in [false, true] {
            let passo = SessioneCampagna.decidiPassoAvversario(
                proposto: .presidio(gruppo: avversario), motore: motore, stato: stato, sblocca: sblocca)
            XCTAssertEqual(passo.comando, .presidio(gruppo: avversario))
            XCTAssertNil(passo.sblocco)
        }
    }

    /// Una proposta respinta (l'esplorazione chiesta a un gruppo armato): nel turno ordinario il
    /// turno si FERMA — nessun comando, la giornata resta aperta, nessun arresto —; con lo sblocco del
    /// tasto il gruppo riceve l'ordine di restare, e lo sblocco porta la proposta e il motivo.
    func test_incarico_28_la_proposta_respinta_ferma_il_turno_o_si_sblocca_col_tasto() {
        let respinta = ComandoCampagna.esplorazione(gruppo: avversario)
        XCTAssertFalse(motore.valida(respinta, parte: .avversario, stato: stato).eValido)

        let ordinario = SessioneCampagna.decidiPassoAvversario(
            proposto: respinta, motore: motore, stato: stato, sblocca: false)
        XCTAssertNil(ordinario.comando, "senza il tasto il turno si ferma invece di applicare un comando respinto")
        XCTAssertNil(ordinario.sblocco)

        let colTasto = SessioneCampagna.decidiPassoAvversario(
            proposto: respinta, motore: motore, stato: stato, sblocca: true)
        XCTAssertEqual(colTasto.comando, .presidio(gruppo: avversario), "l'ordine di restare")
        XCTAssertEqual(colTasto.sblocco?.gruppo, avversario)
        XCTAssertEqual(colTasto.sblocco?.proposta, respinta)
        XCTAssertEqual(colTasto.sblocco?.motivo, .categoriaNonAmmessa)
        XCTAssertTrue(motore.valida(colTasto.comando!, parte: .avversario, stato: stato).eValido,
                      "l'ordine dato dallo sblocco è un comando che il Motore accetta")
    }

    /// Un gruppo che deve rifornirsi con due soste non può presidiare (01 §5.2.2.4): l'ordine di
    /// restare è la sosta con raccolta, come quello che la condotta gli darebbe.
    func test_incarico_28_chi_deve_rifornirsi_resta_con_la_sosta() {
        stato.gruppi[avversario]!.sostaDovuta = 2
        let passo = SessioneCampagna.decidiPassoAvversario(
            proposto: .esplorazione(gruppo: avversario), motore: motore, stato: stato, sblocca: true)
        XCTAssertEqual(passo.comando, .sostaConRaccolta(gruppo: avversario))
    }
}
