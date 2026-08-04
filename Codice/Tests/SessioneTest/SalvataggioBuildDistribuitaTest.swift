import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// Il giornale è anche il formato di salvataggio (05 §6.1). Il piano di campagna
/// aggiunge una famiglia intera di comandi nuovi, ed è il caso segnalato come
/// pericoloso: se la codifica degli enumerativi con valori associati si sposta,
/// le partite in corso dei tester non si riaprono più (00 §15).
///
/// Questa prova non guarda i byte — lo fa `CompatibilitaGiornaleTest` — ma il
/// PERCORSO REALE di riapertura: un salvataggio prodotto dalla build oggi
/// distribuita, a battaglia in corso e non conclusa, riaperto attraverso
/// `SessioneBattaglia(riprendi:)`, che è ciò che il giocatore esegue toccando
/// «riprendi». La fixture è il prefisso del giornale d'oro committato, cioè
/// byte per byte ciò che la build distribuita ha scritto su disco.
final class SalvataggioBuildDistribuitaTest: XCTestCase {

    static let cartellaFixture = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().appendingPathComponent("SalvataggioBuildDistribuita")

    private func slotConIlSalvataggio() throws -> URL {
        let slot = FileManager.default.temporaryDirectory
            .appendingPathComponent("distribuita-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: slot, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: slot) }
        try FileManager.default.copyItem(
            at: Self.cartellaFixture.appendingPathComponent("giornale.jsonl"),
            to: slot.appendingPathComponent("giornale.jsonl"))
        return slot
    }

    func test_00_15_un_salvataggio_della_build_distribuita_si_riapre() async throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let slot = try slotConIlSalvataggio()
        let sessione: SessioneBattaglia
        do { sessione = try await SessioneBattaglia(riprendi: slot, valori: valori) }
        catch let errore as SessioneBattaglia.ErroreSessione {
            switch errore {
            case .salvataggioIncompatibile(let attesa, let trovata):
                return XCTFail("la partita in corso di un tester verrebbe rifiutata: attesa \(attesa), trovata \(trovata)")
            case .schemaIncompatibile(let atteso, let trovato):
                return XCTFail("schema del giornale cambiato: atteso \(atteso), trovato \(trovato)")
            case .giornaleCorrotto(let riga):
                return XCTFail("comando non piu valido alla riapplicazione, riga \(riga): la codifica o le regole si sono spostate")
            default:
                return XCTFail("riapertura fallita: \(errore)")
            }
        }
        // La partita è in corso, non conclusa: è il caso che interessa ai tester.
        let esito = await sessione.stato.esito
        XCTAssertNil(esito, "la fixture è una battaglia a metà, non una conclusa")
        let attesa = try String(contentsOf: Self.cartellaFixture.appendingPathComponent("impronta.txt"),
                                encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        let impronta = await sessione.impronta()
        XCTAssertEqual(impronta, attesa,
                       "il salvataggio si riapre ma su uno stato diverso: la partita che il tester ritrova non è quella che aveva lasciato")
    }

    /// La ripresa deve poter proseguire: riaperto il salvataggio, un comando
    /// ordinario si valida e si applica come prima dell'interruzione.
    func test_00_15_la_partita_riaperta_prosegue() async throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let sessione = try await SessioneBattaglia(riprendi: try slotConIlSalvataggio(), valori: valori)
        let stato = await sessione.stato
        let parte = stato.parteDiTurno
        let (esito, _) = try await sessione.esegui(.fineTurno, parte: parte)
        XCTAssertTrue(esito.eValido, "la partita riaperta accetta ancora i comandi")
    }
}
