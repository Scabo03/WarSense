import XCTest
import Contenuti

/// La posizione, in ogni frase, si dice allo stesso modo: «riga 1, cella 2», con la virgola, che a chi ascolta
/// separa i due numeri (02 §3.3; incarico 32). Le azioni d'ingaggio e le voci della mischia dicevano «riga 1
/// cella 2». Il cancello legge i testi come sono scritti, per intero.
final class PosizioneNelleFrasiTest: XCTestCase {

    func test_02_3_3_la_riga_e_la_cella_sono_separate_dalla_virgola() throws {
        let cartella = Contenuti.testiDiFabbrica.appendingPathComponent("it.lproj")
        let senzaVirgola = try NSRegularExpression(pattern: "riga %([0-9]+\\$)?d (cella|casella)")
        let conVirgola = try NSRegularExpression(pattern: "riga %([0-9]+\\$)?d, (cella|casella)")
        var esaminate = 0
        for nome in ["Annunci.strings", "Annunci.stringsdict", "Vocabolario.strings"] {
            let testo = try String(contentsOf: cartella.appendingPathComponent(nome), encoding: .utf8)
            for riga in testo.split(separator: "\n") {
                let r = String(riga), tutto = NSRange(location: 0, length: (r as NSString).length)
                esaminate += conVirgola.numberOfMatches(in: r, range: tutto)
                XCTAssertNil(senzaVirgola.firstMatch(in: r, range: tutto), "\(nome): manca la virgola in «\(r)»")
            }
        }
        XCTAssertGreaterThan(esaminate, 60, "i testi sono stati letti")
    }
}
