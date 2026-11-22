import XCTest
@testable import Dati
import Contenuti

/// Il caricamento dei valori del regno (05 §7.8; incarico 30): la copia di fabbrica è valida, e
/// ogni copia incoerente è respinta con un rapporto a chiavi di testo, mai applicata in silenzio.
final class CaricamentoRegnoTest: XCTestCase {

    private var archetipi: Set<IdentificatoreDati> = []

    override func setUpWithError() throws {
        archetipi = Set(try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica).archetipi.keys)
    }

    private func diFabbrica() throws -> [String: Any] {
        let dati = try Data(contentsOf: Contenuti.valoriDiFabbrica.appendingPathComponent(CaricatoreRegno.nomeFile))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: dati) as? [String: Any])
    }

    /// Scrive una copia modificata in una cartella temporanea e la carica.
    private func carica(_ modifica: (inout [String: Any]) -> Void) throws -> ValoriRegno {
        var copia = try diFabbrica()
        modifica(&copia)
        let cartella = FileManager.default.temporaryDirectory.appendingPathComponent("regno-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: cartella) }
        try JSONSerialization.data(withJSONObject: copia)
            .write(to: cartella.appendingPathComponent(CaricatoreRegno.nomeFile))
        return try CaricatoreRegno.carica(da: cartella, archetipiNoti: archetipi)
    }

    private func attendiRifiuto(chiave: String, voce: String? = nil, file: StaticString = #filePath,
                                line: UInt = #line, _ modifica: (inout [String: Any]) -> Void) {
        XCTAssertThrowsError(try carica(modifica), file: file, line: line) { errore in
            let dati = errore as? ErroreDati
            XCTAssertEqual(dati?.chiave, chiave, file: file, line: line)
            if let voce { XCTAssertEqual(dati?.voce, voce, file: file, line: line) }
        }
    }

    func test_la_copia_di_fabbrica_si_carica_ed_e_coerente() throws {
        let valori = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica, archetipiNoti: archetipi)
        XCTAssertGreaterThanOrEqual(valori.giornatePerStagione, 1)
        XCTAssertEqual(valori.giornateOperative, valori.giornatePerStagione * 3,
                       "tre stagioni operative: primavera, estate, autunno (01 §5.9)")
        XCTAssertEqual(Set(valori.renditaAnnua.keys), Set(Risorsa.allCases.map(\.rawValue)),
                       "le risorse sono cinque e tutte dichiarate (01 §5.5.1)")
        XCTAssertFalse(valori.voci.isEmpty)
        XCTAssertFalse(valori.fronti.isEmpty)
        print("REGNO-VALORI giornate_per_stagione=\(valori.giornatePerStagione) voci=\(valori.voci.count) fronti=\(valori.fronti.count) formazioni_iniziali=\(valori.forzeIniziali.count)")
    }

    func test_01_5_5_1_una_risorsa_mancante_e_respinta() {
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "rendita_annua") {
            var rendita = $0["rendita_annua"] as! [String: Any]
            rendita.removeValue(forKey: "animali")
            $0["rendita_annua"] = rendita
        }
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "dotazione_iniziale") {
            var dotazione = $0["dotazione_iniziale"] as! [String: Any]
            dotazione["uomini"] = -1
            $0["dotazione_iniziale"] = dotazione
        }
    }

    func test_01_5_9_il_calendario_e_il_riporto_fuori_intervallo_sono_respinti() {
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "giornate_per_stagione") {
            $0["giornate_per_stagione"] = 0
        }
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "quota_riporto") {
            $0["quota_riporto"] = 1.5
        }
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "costo_minimo") {
            $0["costo_minimo"] = 0
        }
    }

    func test_05_7_7_un_gancio_ignoto_e_respinto() {
        attendiRifiuto(chiave: "errore.dati.file_malformato") {
            var voci = $0["voci"] as! [[String: Any]]
            voci[0]["effetto"] = ["gancio": "gancio_inesistente", "archetipo": "fanteria_leggera", "atomi": 6]
            $0["voci"] = voci
        }
    }

    func test_le_voci_incoerenti_sono_respinte() {
        // Un archetipo che non esiste.
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "leva_fanteria_leggera") {
            var voci = $0["voci"] as! [[String: Any]]
            voci[0]["effetto"] = ["gancio": "recluta_reparto", "archetipo": "archetipo_inesistente", "atomi": 6]
            $0["voci"] = voci
        }
        // Una voce che non costa nulla sarebbe il difetto sfruttabile di 00 §13.6.
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "leva_fanteria_leggera") {
            var voci = $0["voci"] as! [[String: Any]]
            voci[0]["pesi"] = [String: Any]()
            $0["voci"] = voci
        }
        // Un peso su una risorsa che non esiste.
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "leva_fanteria_leggera") {
            var voci = $0["voci"] as! [[String: Any]]
            voci[0]["pesi"] = ["denaro": 1, "risorsa_inesistente": 2]
            $0["voci"] = voci
        }
        // Due voci con lo stesso identificatore.
        attendiRifiuto(chiave: "errore.dati.identificatore_duplicato", voce: "leva_fanteria_leggera") {
            var voci = $0["voci"] as! [[String: Any]]
            voci.append(voci[0])
            $0["voci"] = voci
        }
    }

    func test_le_forze_iniziali_senza_formazione_armata_sono_respinte() {
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "forze_iniziali") {
            let forze = $0["forze_iniziali"] as! [[String: Any]]
            $0["forze_iniziali"] = forze.filter { ($0["categoria"] as? String) != "armato" }
        }
    }

    func test_il_file_mancante_e_dichiarato() {
        let vuota = FileManager.default.temporaryDirectory.appendingPathComponent("regno-vuoto-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: vuota, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: vuota) }
        XCTAssertThrowsError(try CaricatoreRegno.carica(da: vuota, archetipiNoti: archetipi)) {
            XCTAssertEqual(($0 as? ErroreDati)?.chiave, "errore.dati.file_mancante")
        }
    }
}
