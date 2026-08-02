import XCTest
import Segnali

/// Collaudo del nucleo di decisione dei canali (05 §11.3).
final class DecisoreCanaliTest: XCTestCase {

    func test_00_5_1_niente_aptica_dove_il_motore_non_esiste() {
        let tablet = DecisoreCanali(apparecchioConAptica: false)
        let canali = tablet.canali(preferenze: .init(suoniAttivi: true, apticaAttiva: true),
                                   conSegnaleTattile: true)
        XCTAssertEqual(canali, [.annuncio, .suono], "su tablet lo strato tattile non esiste (00 §5.1)")
    }

    func test_00_5_2_l_annuncio_non_manca_mai() {
        let telefono = DecisoreCanali(apparecchioConAptica: true)
        let tuttoSpento = telefono.canali(preferenze: .init(suoniAttivi: false, apticaAttiva: false),
                                          conSegnaleTattile: true)
        XCTAssertEqual(tuttoSpento, [.annuncio], "ogni segnale ha sempre controparte testuale (00 §5.2)")
        let tuttoAcceso = telefono.canali(preferenze: .init(suoniAttivi: true, apticaAttiva: true),
                                          conSegnaleTattile: true)
        XCTAssertEqual(tuttoAcceso, [.annuncio, .suono, .aptica])
    }

    func test_02_11_7_1_evento_senza_segnale_tattile_resta_suono_e_voce() {
        let telefono = DecisoreCanali(apparecchioConAptica: true)
        let canali = telefono.canali(preferenze: .init(suoniAttivi: true, apticaAttiva: true),
                                     conSegnaleTattile: false)
        XCTAssertEqual(canali, [.annuncio, .suono])
    }
}
