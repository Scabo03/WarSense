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

        // Terzo: il salvataggio della build distribuita è un prefisso a battaglia in corso
        // del primo oro (SalvataggioBuildDistribuitaTest). Si rigenera dallo stesso oro,
        // scegliendo il prefisso più lungo entro la metà che lascia l'esito ancora nullo.
        try await scriviPrefissoInCorso(golden: RiproduzioneOroTest.cartellaFixture,
                                        fixture: SalvataggioBuildDistribuitaTest.cartellaFixture,
                                        valori: valori)
    }

    private func scriviPrefissoInCorso(golden: URL, fixture: URL, valori: ValoriDiGioco) async throws {
        let righe = try String(contentsOf: golden.appendingPathComponent("giornale.jsonl"), encoding: .utf8)
            .split(separator: "\n").map(String.init)
        var scelto: (n: Int, impronta: String)?
        for n in stride(from: max(1, righe.count / 2), through: 1, by: -1) {
            let slot = FileManager.default.temporaryDirectory
                .appendingPathComponent("prefisso-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: slot, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: slot) }
            try (righe.prefix(n).joined(separator: "\n") + "\n")
                .write(to: slot.appendingPathComponent("giornale.jsonl"), atomically: true, encoding: .utf8)
            guard let sessione = try? await SessioneBattaglia(riprendi: slot, valori: valori) else { continue }
            if await sessione.stato.esito == nil {
                scelto = (n, await sessione.impronta())
                break
            }
        }
        let (n, impronta) = try XCTUnwrap(scelto, "nessun prefisso lascia la battaglia in corso")
        try (righe.prefix(n).joined(separator: "\n") + "\n")
            .write(to: fixture.appendingPathComponent("giornale.jsonl"), atomically: true, encoding: .utf8)
        try (impronta + "\n").write(to: fixture.appendingPathComponent("impronta.txt"),
                                    atomically: true, encoding: .utf8)
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
