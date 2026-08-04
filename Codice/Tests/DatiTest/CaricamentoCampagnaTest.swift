import XCTest
import Dati
import Contenuti

/// Collaudo dei Dati per il piano di campagna (05 §14.3): la validazione di fabbrica
/// è sempre verde, e i file volutamente malformati sono respinti con il rapporto
/// giusto. Il secondo mestiere conta quanto il primo: una validazione che non si è
/// mai vista respingere qualcosa non è una validazione.
final class CaricamentoCampagnaTest: XCTestCase {

    func test_05_7_8_i_valori_di_campagna_di_fabbrica_si_caricano_e_validano() throws {
        let valori = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        XCTAssertEqual(valori.formatiMappa.count, 3, "i tre formati di 01 §5.1")
        XCTAssertFalse(valori.mappe.isEmpty, "almeno una mappa per formato")
        XCTAssertFalse(valori.nomiGruppi.isEmpty, "l'elenco chiuso dei nomi (01 §5.6.0.4)")
        for (identificatore, mappa) in valori.mappe {
            XCTAssertNotNil(valori.formatiMappa[mappa.formato],
                            "la mappa \(identificatore) dichiara un formato noto")
        }
    }

    func test_01_5_1_esiste_una_mappa_per_ciascuno_dei_tre_formati() throws {
        let valori = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        let formatiCoperti = Set(valori.mappe.values.map(\.formato))
        XCTAssertEqual(formatiCoperti, Set(valori.formatiMappa.keys),
                       "ciascun formato ha almeno una mappa: le misure li percorrono tutti e tre")
    }

    // MARK: - Respinte volute

    /// Prepara una copia dei valori di fabbrica in cui un file è stato guastato di
    /// proposito, e restituisce la cartella.
    private func valoriGuasti(scrivendo contenuto: String,
                              in relativo: String) throws -> URL {
        let copia = FileManager.default.temporaryDirectory
            .appendingPathComponent("valori-guasti-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: Contenuti.valoriDiFabbrica, to: copia)
        addTeardownBlock { try? FileManager.default.removeItem(at: copia) }
        try contenuto.write(to: copia.appendingPathComponent(relativo),
                            atomically: true, encoding: .utf8)
        return copia
    }

    private func attendiRifiuto(_ cartella: URL, chiave attesa: String,
                                file: StaticString = #filePath, linea: UInt = #line) {
        do {
            _ = try CaricatoreCampagna.carica(da: cartella)
            XCTFail("il caricamento avrebbe dovuto respingere", file: file, line: linea)
        } catch let errore as ErroreDati {
            XCTAssertEqual(errore.chiave, attesa, file: file, line: linea)
        } catch {
            XCTFail("errore inatteso: \(error)", file: file, line: linea)
        }
    }

    func test_05_7_8_una_mappa_con_formato_ignoto_e_respinta() throws {
        let cartella = try valoriGuasti(scrivendo: """
        { "identificatore": "guasta", "formato": "inesistente", "caselle": [],
          "strettoia": null,
          "quartier_generali": { "giocatore": { "riga": 4, "colonna": 2 },
                                 "avversario": { "riga": 1, "colonna": 2 } } }
        """, in: "Mappe/guado.json")
        attendiRifiuto(cartella, chiave: "errore.dati.formato_ignoto")
    }

    func test_05_7_8_una_casella_fuori_dai_confini_e_respinta() throws {
        let cartella = try valoriGuasti(scrivendo: """
        { "identificatore": "guado", "formato": "quattro",
          "caselle": [ { "riga": 9, "colonna": 9, "terreno": "bosco" } ],
          "strettoia": null,
          "quartier_generali": { "giocatore": { "riga": 4, "colonna": 2 },
                                 "avversario": { "riga": 1, "colonna": 2 } } }
        """, in: "Mappe/guado.json")
        attendiRifiuto(cartella, chiave: "errore.dati.casella_fuori_mappa")
    }

    func test_05_7_8_una_casella_dichiarata_due_volte_e_respinta() throws {
        let cartella = try valoriGuasti(scrivendo: """
        { "identificatore": "guado", "formato": "quattro",
          "caselle": [ { "riga": 2, "colonna": 2, "terreno": "bosco" },
                       { "riga": 2, "colonna": 2, "terreno": "acqua" } ],
          "strettoia": null,
          "quartier_generali": { "giocatore": { "riga": 4, "colonna": 2 },
                                 "avversario": { "riga": 1, "colonna": 2 } } }
        """, in: "Mappe/guado.json")
        attendiRifiuto(cartella, chiave: "errore.dati.casella_ripetuta")
    }

    func test_01_5_1_3_una_strettoia_fuori_dai_confini_e_respinta() throws {
        let cartella = try valoriGuasti(scrivendo: """
        { "identificatore": "guado", "formato": "quattro", "caselle": [],
          "strettoia": { "riga": 7, "colonna": 1 },
          "quartier_generali": { "giocatore": { "riga": 4, "colonna": 2 },
                                 "avversario": { "riga": 1, "colonna": 2 } } }
        """, in: "Mappe/guado.json")
        attendiRifiuto(cartella, chiave: "errore.dati.strettoia_fuori_mappa")
    }

    func test_01_5_14_3_2_un_quartier_generale_fuori_dall_ultima_riga_e_respinto() throws {
        let cartella = try valoriGuasti(scrivendo: """
        { "identificatore": "guado", "formato": "quattro", "caselle": [],
          "strettoia": null,
          "quartier_generali": { "giocatore": { "riga": 3, "colonna": 2 },
                                 "avversario": { "riga": 1, "colonna": 2 } } }
        """, in: "Mappe/guado.json")
        attendiRifiuto(cartella, chiave: "errore.dati.quartier_generale_non_in_ultima_riga")
    }

    func test_05_7_7_un_terreno_ignoto_e_respinto_anziche_ignorato_in_silenzio() throws {
        let cartella = try valoriGuasti(scrivendo: """
        { "identificatore": "guado", "formato": "quattro",
          "caselle": [ { "riga": 2, "colonna": 2, "terreno": "palude" } ],
          "strettoia": null,
          "quartier_generali": { "giocatore": { "riga": 4, "colonna": 2 },
                                 "avversario": { "riga": 1, "colonna": 2 } } }
        """, in: "Mappe/guado.json")
        attendiRifiuto(cartella, chiave: "errore.dati.file_malformato")
    }

    func test_05_7_7_un_tipo_di_strada_ignoto_e_respinto() throws {
        let cartella = try valoriGuasti(scrivendo: """
        { "identificatore": "guado", "formato": "quattro",
          "caselle": [ { "riga": 2, "colonna": 2, "strada": "autostrada" } ],
          "strettoia": null,
          "quartier_generali": { "giocatore": { "riga": 4, "colonna": 2 },
                                 "avversario": { "riga": 1, "colonna": 2 } } }
        """, in: "Mappe/guado.json")
        attendiRifiuto(cartella, chiave: "errore.dati.file_malformato")
    }

    func test_05_7_8_due_mappe_con_lo_stesso_identificatore_sono_respinte() throws {
        let cartella = try valoriGuasti(scrivendo: """
        { "identificatore": "istmo", "formato": "quattro", "caselle": [],
          "strettoia": null,
          "quartier_generali": { "giocatore": { "riga": 4, "colonna": 2 },
                                 "avversario": { "riga": 1, "colonna": 2 } } }
        """, in: "Mappe/guado.json")
        attendiRifiuto(cartella, chiave: "errore.dati.identificatore_duplicato")
    }

    func test_01_5_6_0_4_un_elenco_di_nomi_con_ripetizioni_e_respinto() throws {
        let cartella = try valoriGuasti(scrivendo: """
        { "chiavi": ["corvo", "corvo"] }
        """, in: "nomi-gruppi.json")
        attendiRifiuto(cartella, chiave: "errore.dati.nomi_gruppi_incoerenti")
    }

    func test_05_7_8_un_formato_di_lato_inferiore_a_due_e_respinto() throws {
        let cartella = try valoriGuasti(scrivendo: """
        [ { "identificatore": "punto", "righe": 1, "colonne": 1 } ]
        """, in: "formati-mappa.json")
        attendiRifiuto(cartella, chiave: "errore.dati.formato_incoerente")
    }
}
