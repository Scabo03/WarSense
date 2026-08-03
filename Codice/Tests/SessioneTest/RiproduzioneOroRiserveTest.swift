import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// Secondo copione d'oro (incarico fase B): lascia deliberatamente una riserva nel
/// mazzo e si chiude per resa, così la base delle perdite sulle sole forze impiegate
/// (01 §10.2.1, RDA-46) è coperta da una riproduzione registrata: nel primo oro
/// l'intero mazzo scende in campo e le due basi coincidono.
final class RiproduzioneOroRiserveTest: XCTestCase {

    static let cartellaFixture = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("RiproduzioneOroRiserve")

    /// Il copione: il giocatore impegna una sola fanteria leggera su due disponibili,
    /// la perde sotto due pesanti avversarie, e la resa arriva alla soglia accorciata
    /// calcolata sul solo impiegato. Restituisce la sessione a scontro concluso.
    static func giocaCopione(in cartella: URL, valori: ValoriDiGioco) async throws -> SessioneBattaglia {
        let scenario = ScenarioBattaglia(
            formato: "quindici", caratteristica: "campo_aperto",
            primoOccupante: .giocatore, imboscata: false,
            deckGiocatore: [.init(archetipo: "fanteria_leggera", protezione: .antiSaturazione,
                                  atomi: 3, esemplari: 2)],
            deckAvversario: [.init(archetipo: "fanteria_pesante", protezione: .antiPerforazione,
                                   atomi: 3, esemplari: 2)],
            ufficialeAvversario: "ufficiale_prova")
        let sessione = try await SessioneBattaglia(
            nuova: scenario, valori: valori, versioneTesti: "0.1.0",
            cartella: cartella, seme: 99, identificatore: "oro-riserve")
        let motore = MotoreBattaglia(valori: valori)
        let tattico = TatticoBattaglia(motore: motore,
                                       ufficiale: valori.ufficiali["ufficiale_prova"]!,
                                       parte: .avversario)
        // Il giocatore impegna UNA sola unità e tiene l'altra nel mazzo.
        _ = try await sessione.esegui(.seleziona(indiceDeck: 0), parte: .giocatore)
        _ = try await sessione.esegui(.piazza(cella: Cella(riga: 4, colonna: 2)), parte: .giocatore)
        _ = try await sessione.esegui(.fineTurno, parte: .giocatore)

        var passi = 0
        while await sessione.stato.esito == nil && passi < 200 {
            passi += 1
            let stato = await sessione.stato
            if stato.parteDiTurno == .avversario {
                _ = try await sessione.eseguiTurnoAvversario(tattico)
                continue
            }
            // Il giocatore: appena la resa è disponibile e l'unità impegnata è perduta,
            // dichiara; poi non gli resta nulla in campo e la ritirata si compie.
            let miaInCampo = stato.sciami.values.contains { $0.parte == .giocatore }
            if !miaInCampo, stato.resaDichiarataDa == nil,
               await sessione.anteprima(.dichiaraResa, parte: .giocatore).eValido {
                _ = try await sessione.esegui(.dichiaraResa, parte: .giocatore)
                continue
            }
            _ = try await sessione.esegui(.fineTurno, parte: .giocatore)
        }
        return sessione
    }

    func test_01_10_2_1_oro_con_riserve_nel_mazzo() async throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let attesa = try String(contentsOf: Self.cartellaFixture.appendingPathComponent("impronta.txt"),
                                encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        let slot = FileManager.default.temporaryDirectory
            .appendingPathComponent("oro-riserve-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: slot, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: slot) }
        try FileManager.default.copyItem(
            at: Self.cartellaFixture.appendingPathComponent("giornale.jsonl"),
            to: slot.appendingPathComponent("giornale.jsonl"))
        let sessione = try await SessioneBattaglia(riprendi: slot, valori: valori)
        let improntaRipresa = await sessione.impronta()
        XCTAssertEqual(improntaRipresa, attesa,
                       "riproduzione d'oro delle riserve: rigenerare solo con revisione esplicita (05 §14.6)")
        let stato = await sessione.stato
        XCTAssertEqual(stato.esito?.modo, .ritirataCompiuta)
        XCTAssertEqual(stato.esito?.sconfitto, .giocatore, "sconfitto è chi dichiara (01 §15.2.2)")
        // La riserva è rimasta nel mazzo e NON ha trattenuto la resa: la base era il solo impiegato.
        let riserve = stato.deck[.giocatore]?.reduce(0) { $0 + $1.esemplari } ?? 0
        XCTAssertGreaterThan(riserve, 0, "il copione lascia deliberatamente una riserva nel mazzo")
        XCTAssertEqual(stato.forzeImpegnate[.giocatore], 300,
                       "la base conta il solo impiegato (01 §10.2.1)")
        let motore = MotoreBattaglia(valori: valori)
        XCTAssertEqual(motore.sogliaResaEffettiva(per: .giocatore, stato: stato), 1,
                       "perdite piene sull'impiegato: soglia al minimo; con la base sull'intero mazzo sarebbe 2")
    }
}
