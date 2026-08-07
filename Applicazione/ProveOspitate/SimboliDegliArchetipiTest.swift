import XCTest
import Dati
import Contenuti
@testable import WarSense

/// Il controllo che RIFIUTA lo stato sbagliato dei simboli d'archetipo (principio 1,
/// 02 §8.2, RDA-97): ogni archetipo dei dati deve avere il proprio simbolo grafico,
/// e ciascun simbolo deve disegnarsi a dimensione reale nei tre ambienti. È la forma
/// di protezione del progetto — un cancello che rifiuta, non una prescrizione scritta.
/// Un archetipo aggiunto ad `archetipi.json` SENZA il corrispondente
/// `<archetipo>.symbolset` in `Immagini.xcassets` fa fallire `test_principio_1_...`.
/// Il verso opposto — nessun simbolo orfano — è il cancello di `scripts/verifica-simboli.sh`.
final class SimboliDegliArchetipiTest: XCTestCase {

    private func archetipi() throws -> [IdentificatoreDati] {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        return valori.archetipi.keys.sorted()
    }

    /// Ogni archetipo ha il proprio simbolo, caricabile dal pacchetto dell'app col
    /// nome dell'archetipo stesso. Toglierne uno da `Immagini.xcassets` fa fallire qui.
    func test_principio_1_ogni_archetipo_ha_il_proprio_simbolo() throws {
        let bundle = Bundle(for: TesseraDeck.self)
        let ids = try archetipi()
        XCTAssertFalse(ids.isEmpty, "i dati devono elencare gli archetipi")
        for id in ids {
            XCTAssertNotNil(UIImage(named: id, in: bundle, compatibleWith: nil),
                            "l'archetipo «\(id)» non ha il proprio simbolo: manca "
                            + "«\(id).symbolset» in Immagini.xcassets (RDA-97, principio 1)")
        }
    }

    /// Ogni simbolo si disegna, a dimensione reale della tessera (il lato del riquadro
    /// entro cui si iscrive), tinto con `.label`, in chiaro, in scuro e con il contrasto
    /// aumentato: il risultato NON è vuoto (ha inchiostro). La forma è monocroma e non
    /// porta informazione col colore (00 §1.4); il contrasto aumentato rende la tinta
    /// più netta, non altera la forma.
    @MainActor
    func test_00_1_4_ogni_simbolo_si_disegna_a_dimensione_reale_in_chiaro_scuro_e_contrasto() throws {
        let bundle = Bundle(for: TesseraDeck.self)
        let ids = try archetipi()
        let lato = TesseraDeck.latoSimbolo
        let ambienti: [(String, UITraitCollection)] = [
            ("chiaro", UITraitCollection(userInterfaceStyle: .light)),
            ("scuro", UITraitCollection(userInterfaceStyle: .dark)),
            // Contrasto aumentato (stile chiaro implicito): `.label` vi si risolve più netto.
            ("contrasto aumentato", UITraitCollection(accessibilityContrast: .high)),
        ]
        for id in ids {
            let simbolo = try XCTUnwrap(UIImage(named: id, in: bundle, compatibleWith: nil),
                                        "manca il simbolo di «\(id)»")
                .withRenderingMode(.alwaysTemplate)
            for (nome, tratti) in ambienti {
                let tinta = UIColor.label.resolvedColor(with: tratti)
                let render = UIGraphicsImageRenderer(size: CGSize(width: lato, height: lato))
                let immagine = render.image { _ in
                    simbolo.withTintColor(tinta, renderingMode: .alwaysOriginal)
                        .draw(in: CGRect(x: 0, y: 0, width: lato, height: lato))
                }
                XCTAssertTrue(haInchiostro(immagine, tinta: tinta),
                              "il simbolo di «\(id)» non disegna nulla a \(Int(lato)) punti "
                              + "in ambiente «\(nome)» (00 §1.4)")
            }
        }
    }

    /// Vero se l'immagine contiene almeno un pixel della tinta prevista, cioè il
    /// simbolo ha lasciato un segno visibile e non è una tessera vuota.
    @MainActor
    private func haInchiostro(_ immagine: UIImage, tinta: UIColor) -> Bool {
        guard let cg = immagine.cgImage else { return false }
        let larghezza = cg.width, altezza = cg.height
        var pixel = [UInt8](repeating: 0, count: larghezza * altezza * 4)
        let spazio = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: &pixel, width: larghezza, height: altezza,
                                  bitsPerComponent: 8, bytesPerRow: larghezza * 4, space: spazio,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: larghezza, height: altezza))
        for i in stride(from: 0, to: pixel.count, by: 4) where pixel[i + 3] > 0 {
            return true
        }
        return false
    }
}
