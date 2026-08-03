import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// L'attrezzo della revisione esplicita degli ori (05 §14.6): quando una modifica
/// di regole è voluta, i giornali d'oro e le impronte si rigenerano INSIEME e la
/// rigenerazione si dichiara nel commit. Per impedirne l'esecuzione accidentale,
/// l'attrezzo corre soltanto con la variabile d'ambiente RIGENERA_ORO presente:
/// in ogni corsa ordinaria del collaudo viene saltato.
final class RigenerazioneOroTest: XCTestCase {

    func test_rigenerazione_esplicita_dei_copioni_d_oro() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["RIGENERA_ORO"] != nil,
                          "rigenerazione solo su richiesta esplicita (05 §14.6)")
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)

        // Primo oro: la battaglia completa della fase A (annientamento).
        let cartellaPrimo = FileManager.default.temporaryDirectory
            .appendingPathComponent("rigenera-oro-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: cartellaPrimo) }
        let guida = SessioneBattagliaTest()
        guida.valori = valori
        let primo = try await guida.giocaBattagliaCompleta(in: cartellaPrimo)
        try await scrivi(sessione: primo, cartellaSlot: cartellaPrimo,
                         fixture: RiproduzioneOroTest.cartellaFixture)

        // Secondo oro: la resa con riserve nel mazzo (01 §10.2.1, RDA-46).
        let cartellaSecondo = FileManager.default.temporaryDirectory
            .appendingPathComponent("rigenera-oro-riserve-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: cartellaSecondo) }
        let secondo = try await RiproduzioneOroRiserveTest.giocaCopione(in: cartellaSecondo,
                                                                       valori: valori)
        try await scrivi(sessione: secondo, cartellaSlot: cartellaSecondo,
                         fixture: RiproduzioneOroRiserveTest.cartellaFixture)
    }

    private func scrivi(sessione: SessioneBattaglia, cartellaSlot: URL, fixture: URL) async throws {
        let esito = await sessione.stato.esito
        XCTAssertNotNil(esito, "un oro registra uno scontro concluso")
        let impronta = await sessione.impronta()
        let giornale = cartellaSlot.appendingPathComponent("giornale.jsonl")
        let destinazione = fixture.appendingPathComponent("giornale.jsonl")
        try? FileManager.default.removeItem(at: destinazione)
        try FileManager.default.copyItem(at: giornale, to: destinazione)
        try (impronta + "\n").write(to: fixture.appendingPathComponent("impronta.txt"),
                                    atomically: true, encoding: .utf8)
    }
}
