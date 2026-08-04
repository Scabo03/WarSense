import XCTest
import Sessione
import Motore
import Dati

/// Blocco della codifica del giornale (incarico fase B): il giornale è anche il
/// formato di salvataggio, e se la codifica degli enumerativi con valori associati
/// si sposta, le partite aperte dei tester non si riaprono più (00 §15).
/// I campioni committati coprono ogni caso di voce; ogni caso di comando aggiunto
/// in futuro entra nei campioni nella stessa modifica che lo introduce.
final class CompatibilitaGiornaleTest: XCTestCase {

    static let campioni = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("CampioniGiornale/campioni.jsonl")

    func test_00_15_i_campioni_committati_si_decodificano_e_ricodificano_identici() throws {
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let testo = try String(contentsOf: Self.campioni, encoding: .utf8)
        let righe = testo.split(separator: "\n")
        XCTAssertGreaterThanOrEqual(righe.count, 11, "un campione per ogni caso di voce")
        var casiComando = Set<String>()
        var casiComandoCampagna = Set<String>()
        var casiVoce = Set<String>()
        for riga in righe {
            let dati = Data(riga.utf8)
            let voce: RigaGiornale
            do { voce = try JSONDecoder().decode(RigaGiornale.self, from: dati) }
            catch {
                return XCTFail("campione non piu decodificabile: la codifica del giornale si e spostata. Riga: \(riga.prefix(80))")
            }
            // La ricodifica deve produrre esattamente i byte del campione:
            // qualunque scarto e un cambiamento di formato di salvataggio.
            let ricodifica = try codificatore.encode(voce)
            XCTAssertEqual(String(data: ricodifica, encoding: .utf8), String(riga),
                           "la ricodifica differisce dal campione committato")
            if case .comando(_, let comando) = voce.voce {
                casiComando.insert(etichettaCaso(comando))
            }
            if case .comandoCampagna(_, let comando) = voce.voce {
                casiComandoCampagna.insert(etichettaCaso(comando))
            }
            casiVoce.formUnion(try chiaviDiPrimoLivelloDellaVoce(dati))
        }
        // Ogni caso di comando oggi esistente ha un campione: se si aggiunge un caso
        // all'enumerativo senza aggiungere il campione, questa prova lo dichiara.
        let attesi: Set<String> = ["seleziona", "deseleziona", "piazza", "muovi", "tira",
                                   "ingaggia", "dichiaraResa", "ritiraUnita", "fineTurno"]
        XCTAssertEqual(casiComando, attesi, "casi di comando senza campione committato")
        XCTAssertEqual(casiComandoCampagna, ["marcia", "presidio"],
                       "casi di comando di campagna senza campione committato")

        // I nomi dei casi di VOCE sono anch'essi formato di salvataggio: la codifica
        // sintetizzata degli enumerativi con valori associati usa il NOME del caso
        // come chiave, non la sua posizione. Rinominare un caso, o cambiarne la
        // forma, rende illeggibili i giornali già scritti; AGGIUNGERE un caso non
        // tocca gli altri, ed è ciò che la campagna ha fatto. Questa prova fissa i
        // nomi perché l'aggiunta resti un'aggiunta: le quattro righe di campagna dei
        // campioni sono state accodate DOPO che le dodici preesistenti avevano
        // superato la ricodifica byte per byte con i casi nuovi già in enumerativo.
        XCTAssertEqual(casiVoce, ["fondazione", "comando", "inizioTurno",
                                  "fondazioneCampagna", "comandoCampagna", "aperturaGiornata"],
                       "un caso di VoceGiornale è stato rinominato o spostato: i salvataggi esistenti non si riaprono (00 §15)")
    }

    /// Le chiavi di primo livello dell'oggetto `voce`: il nome del caso codificato.
    private func chiaviDiPrimoLivelloDellaVoce(_ dati: Data) throws -> Set<String> {
        guard let radice = try JSONSerialization.jsonObject(with: dati) as? [String: Any],
              let voce = radice["voce"] as? [String: Any] else { return [] }
        return Set(voce.keys)
    }

    private func etichettaCaso(_ comando: ComandoBattaglia) -> String {
        switch comando {
        case .seleziona: return "seleziona"
        case .deseleziona: return "deseleziona"
        case .piazza: return "piazza"
        case .muovi: return "muovi"
        case .tira: return "tira"
        case .ingaggia: return "ingaggia"
        case .dichiaraResa: return "dichiaraResa"
        case .ritiraUnita: return "ritiraUnita"
        case .fineTurno: return "fineTurno"
        }
    }

    private func etichettaCaso(_ comando: ComandoCampagna) -> String {
        switch comando {
        case .marcia: return "marcia"
        case .presidio: return "presidio"
        }
    }
}
