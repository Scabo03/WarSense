import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// Riproduzione d'oro (05 §14.6): un giornale registrato di uno scontro completo,
/// riapplicato a ogni modifica. L'impronta finale deve coincidere con quella registrata.
/// Quando una modifica di regole è voluta, la riproduzione si rigenera con revisione
/// esplicita: si aggiornano insieme giornale.jsonl e impronta.txt in RiproduzioneOro.
final class RiproduzioneOroTest: XCTestCase {

    static let cartellaFixture = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().appendingPathComponent("RiproduzioneOro")

    func test_05_14_6_riproduzione_d_oro_dello_scontro_completo() async throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let attesa = try String(contentsOf: Self.cartellaFixture.appendingPathComponent("impronta.txt"),
                                encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        // Il giornale registrato si copia in uno slot di lavoro e si riapre.
        let slot = FileManager.default.temporaryDirectory
            .appendingPathComponent("oro-slot-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: slot, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: slot) }
        try FileManager.default.copyItem(
            at: Self.cartellaFixture.appendingPathComponent("giornale.jsonl"),
            to: slot.appendingPathComponent("giornale.jsonl"))
        let sessione = try await SessioneBattaglia(riprendi: slot, valori: valori)
        let impronta = await sessione.impronta()
        XCTAssertEqual(impronta, attesa,
                       "il determinismo nel tempo si è rotto: se la modifica delle regole è voluta, rigenerare la riproduzione con revisione esplicita (05 §14.6)")
        let esito = await sessione.stato.esito
        XCTAssertNotNil(esito, "la riproduzione registra uno scontro concluso")
    }
}
