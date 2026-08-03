import XCTest
import Dati
import Contenuti

/// Collaudo dei Dati (05 §14.3): la copia di fabbrica è sempre valida,
/// i file malformati sono respinti con la chiave giusta, la modifica locale
/// produce la versione derivata (RDA-45), i testi di fabbrica sono completi.
final class CaricamentoTest: XCTestCase {

    func test_fabbrica_sempre_valida() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        XCTAssertEqual(valori.versione, valori.versioneEffettiva)
        XCTAssertFalse(valori.modificatiLocalmente)
        XCTAssertEqual(valori.archetipi.count, 9, "Nove archetipi definitivi (01 §3.2.3)")
        XCTAssertNotNil(valori.formati["cento"])
        XCTAssertNotNil(valori.formati["quindici"])
    }

    func test_scalato_e_aritmetica_a_virgola_fissa() throws {
        // 1,3 × 200 = 260, senza virgola mobile (RDA-44).
        let coefficiente = Scalato(millesimi: 1300)
        XCTAssertEqual(coefficiente.applicato(a: 200), 260)
        // Troncamento per difetto: 0,999 × 100 = 99 (00 §13.5).
        XCTAssertEqual(Scalato(millesimi: 999).applicato(a: 100), 99)
        // 0,3 + 0,3 + 0,3 + 0,1 = 1,0 esatto: niente errori di rappresentazione.
        let somma = Scalato(millesimi: 300) + Scalato(millesimi: 300) + Scalato(millesimi: 300) + Scalato(millesimi: 100)
        XCTAssertEqual(somma, .uno)
    }

    func test_file_malformato_respinto_con_chiave() throws {
        let copia = try copiaDiLavoro()
        try Data("non json".utf8).write(to: copia.appendingPathComponent("archetipi.json"))
        XCTAssertThrowsError(try CaricatoreValori.carica(da: copia)) { errore in
            let e = errore as? ErroreDati
            XCTAssertEqual(e?.chiave, "errore.dati.file_malformato")
            XCTAssertEqual(e?.file, "archetipi.json")
        }
    }

    func test_01_3_4_1_vincolo_tiro_in_blocco_respinto() throws {
        let copia = try copiaDiLavoro()
        let url = copia.appendingPathComponent("archetipi.json")
        var testo = try String(contentsOf: url, encoding: .utf8)
        // Un tiratore senza gittata è incoerente: il tiro è un blocco unico
        // (proiettile, offesa, gittata, dotazione: 01 §3.3.1, §3.4.1 versione 3.3).
        testo = testo.replacingOccurrences(
            of: "\"capacita_offensiva_per_atomo\":25,\"gittata\":6",
            with: "\"capacita_offensiva_per_atomo\":25,\"gittata\":0")
        try testo.write(to: url, atomically: true, encoding: .utf8)
        XCTAssertThrowsError(try CaricatoreValori.carica(da: copia)) { errore in
            XCTAssertEqual((errore as? ErroreDati)?.chiave, "errore.dati.tiro_incoerente")
        }
    }

    func test_modifica_locale_produce_versione_derivata() throws {
        let copia = try copiaDiLavoro()
        let url = copia.appendingPathComponent("combattimento.json")
        var testo = try String(contentsOf: url, encoding: .utf8)
        testo = testo.replacingOccurrences(of: "0.15", with: "0.2")
        try testo.write(to: url, atomically: true, encoding: .utf8)
        let valori = try CaricatoreValori.carica(da: copia)
        XCTAssertTrue(valori.modificatiLocalmente)
        XCTAssertTrue(valori.versioneEffettiva.hasPrefix(valori.versione + "+"),
                      "Versione base più suffisso dalle impronte (RDA-45)")
    }

    func test_testi_di_fabbrica_completi_per_le_chiavi_di_errore() throws {
        let testi = try Testi.carica(albero: Contenuti.testiDiFabbrica, lingua: "it")
        // Ogni chiave di ErroreDati usata dal caricatore deve esistere nella fabbrica (05 §7.8).
        let chiavi = ["errore.dati.file_mancante", "errore.dati.file_malformato",
                      "errore.dati.identificatore_duplicato", "errore.dati.elenco_vuoto",
                      "errore.dati.valore_non_positivo",
                      "errore.dati.tiro_incoerente", "errore.dati.soglia_fuori_intervallo",
                      "errore.dati.protezione_mancante", "errore.dati.formato_incoerente",
                      "errore.dati.minimi_sotto_uno", "errore.dati.efficacia_minima_nulla",
                      "errore.testi.manifest_mancante", "errore.testi.manifest_malformato",
                      "errore.testi.lingua_assente", "errore.testi.pacchetto_illeggibile"]
        for chiave in chiavi {
            XCTAssertTrue(testi.esiste(chiave), "Chiave mancante nei testi di fabbrica: \(chiave)")
        }
    }

    func test_testi_frase_con_lingua_e_plurale() throws {
        let testi = try Testi.carica(albero: Contenuti.testiDiFabbrica, lingua: "it")
        let frase = testi.frase("battaglia.turno", 3)
        XCTAssertEqual(frase.testo, "Turno 3")
        XCTAssertEqual(frase.lingua, "it")
        XCTAssertEqual(testi.frase("battaglia.atomi_presenti", 1).testo, "1 atomo")
        XCTAssertEqual(testi.frase("battaglia.atomi_presenti", 5).testo, "5 atomi")
        XCTAssertEqual(testi.termine("cella.troppo_avanzata").testo, "troppo avanzata")
    }

    private func copiaDiLavoro() throws -> URL {
        let copia = FileManager.default.temporaryDirectory
            .appendingPathComponent("valori-prova-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: Contenuti.valoriDiFabbrica, to: copia)
        addTeardownBlock { try? FileManager.default.removeItem(at: copia) }
        return copia
    }
}
