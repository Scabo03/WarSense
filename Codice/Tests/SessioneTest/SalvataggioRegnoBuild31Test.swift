import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// UN REGNO SALVATO CON LA BUILD 31 NON SI RIAPRE, E IL GIOCO LO DICHIARA (00 §15.2; incarico 31).
///
/// Lo schema del giornale del regno è passato da 1 a 2 con la seconda tappa: le forze conservano le
/// formazioni col loro nome, il mantenimento si preleva all'inizio dell'inverno, i lavori hanno
/// durate. Un giornale di schema 1 non si decodifica più nella forma di oggi. Prima di questa prova
/// la ripresa lo apriva comunque: la prima riga, non più decodificabile, era presa per una riga
/// corrotta, il file veniva TRONCATO a zero byte, e chi riprendeva riceveva un errore del giornale
/// che l'avvio non sa dichiarare — «Riprendi il regno» non faceva nulla, in silenzio. Ora lo schema
/// si legge dall'intestazione prima di aprire, il regno è dichiarato incompatibile e il file resta
/// com'era.
///
/// La fixture è il giornale d'oro del regno com'era committato alla build 31 (`41cccff`,
/// `RiproduzioneOroRegno/giornale.jsonl`): byte per byte ciò che il codice della build 31 scrive.
final class SalvataggioRegnoBuild31Test: XCTestCase {

    static let fixture = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().appendingPathComponent("SalvataggioRegnoBuild31")
        .appendingPathComponent("giornale.jsonl")

    private func slotConIlRegnoDellaBuild31() throws -> URL {
        let slot = FileManager.default.temporaryDirectory.appendingPathComponent("regno-31-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: slot, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: slot) }
        try FileManager.default.copyItem(at: Self.fixture, to: slot.appendingPathComponent(SessioneRegno.nomeGiornale))
        return slot
    }

    func test_incarico_31_lo_schema_si_legge_dall_intestazione_senza_decodificare_il_resto() throws {
        let slot = try slotConIlRegnoDellaBuild31()
        XCTAssertEqual(Giornale.schemaDelRegno(a: slot.appendingPathComponent(SessioneRegno.nomeGiornale)), 1,
                       "la fixture è un giornale della build 31, di schema 1")
        XCTAssertNil(Giornale.schemaDelRegno(a: slot.appendingPathComponent("non-esiste.jsonl")))
        // Un giornale di battaglia non è un regno: nessuno schema del regno da leggervi.
        let battaglia = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("SalvataggioBuildDistribuita").appendingPathComponent("giornale.jsonl")
        XCTAssertNil(Giornale.schemaDelRegno(a: battaglia))
    }

    func test_incarico_31_un_regno_della_build_31_e_dichiarato_incompatibile_e_il_file_resta_com_era() async throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let valoriRegno = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica,
                                                     archetipiNoti: Set(valori.archetipi.keys),
                                                     miglioramentiNoti: Set(valori.miglioramenti.keys))
        let slot = try slotConIlRegnoDellaBuild31()
        let file = slot.appendingPathComponent(SessioneRegno.nomeGiornale)
        let prima = try Data(contentsOf: file)
        XCTAssertGreaterThan(prima.count, 1000, "la fixture non è vuota")

        do {
            _ = try await SessioneRegno(riprendi: slot, valori: valoriRegno,
                                        versioneValori: valori.versioneEffettiva,
                                        versioniCompatibili: valori.versioniCompatibili)
            XCTFail("un regno di schema 1 non deve riaprirsi: proseguirebbe con regole diverse (00 §15.2)")
        } catch let errore as SessioneRegno.ErroreSessione {
            XCTAssertEqual(errore, .schemaIncompatibile(atteso: 2, trovato: 1),
                           "l'incompatibilità si dichiara come tale, perché l'avvio la sappia dire")
        } catch {
            XCTFail("la ripresa fallisce con un errore che l'avvio non sa dichiarare: \(error)")
        }
        XCTAssertEqual(try Data(contentsOf: file), prima,
                       "il giornale rifiutato resta byte per byte com'era: non lo si tronca")
    }
}
