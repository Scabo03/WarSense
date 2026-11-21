import XCTest
@testable import Dati
import Contenuti

/// L'informazione di stato della campagna accorda verbo e nome al numero dei gruppi (incarico 29,
/// osservazione 2 della sessione da tester: «Hanno agito 1 gruppi su 4»). I plurali vengono dal
/// meccanismo di sistema (00 §14.3), cioè dal .stringsdict, e non da condizioni scritte a mano.
final class AccordoAlNumeroTest: XCTestCase {

    private func testi() throws -> Testi {
        try Testi.carica(albero: Contenuti.testiDiFabbrica, lingua: "it")
    }

    func test_un_gruppo_che_ha_agito() throws {
        let t = try testi()
        XCTAssertEqual(t.frase("campagna.stato", 3, 1, 4).testo, "Giorno 3. Ha agito 1 gruppo su 4")
        XCTAssertEqual(t.frase("campagna.stato", 3, 2, 4).testo, "Giorno 3. Hanno agito 2 gruppi su 4")
        XCTAssertEqual(t.frase("campagna.stato_con_marcia", 5, 1, 4, 2).testo,
                       "Giorno 5. Ha agito 1 gruppo su 4, 2 in marcia lunga")
        XCTAssertEqual(t.frase("campagna.stato_con_marcia", 5, 3, 4, 1).testo,
                       "Giorno 5. Hanno agito 3 gruppi su 4, 1 in marcia lunga")
    }

    func test_nessun_gruppo_ha_agito() throws {
        let t = try testi()
        XCTAssertEqual(t.frase("campagna.stato_tutti_fermi", 1, 4).testo,
                       "Giorno 1. Nessun gruppo ha ancora agito, sono 4")
        XCTAssertEqual(t.frase("campagna.stato_tutti_fermi", 1, 1).testo,
                       "Giorno 1. Il solo gruppo non ha ancora agito")
    }
}
