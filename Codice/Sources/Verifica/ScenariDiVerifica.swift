import Foundation
import Dati
import Motore

/// Gli scenari del programma di verifica sono file dichiarativi (03 §9.6, 05 §12.2):
/// aggiungere un caso da misurare non richiede di toccare il programma.

/// Gli assi lungo cui una misura si ripete. Insieme CHIUSO, come i ganci delle
/// caratteristiche di campo (05 §7.7): un asse ignoto è respinto in caricamento,
/// non ignorato in silenzio. Ogni asse enumera gli estremi del proprio intervallo,
/// perché un valore si giudica dal suo intervallo e non dal suo centro (00 §13.2.4).
public enum AsseDiVariazione: String, Codable, Hashable, Sendable, CaseIterable {
    /// Chi occupava per primo la casella, e quindi agisce per primo (01 §9.4.1).
    case primoOccupante = "primo_occupante"
    /// Ogni combinazione di ufficiali fra i due schieramenti (01 §14.3, 03 §6.5).
    case ufficiali
    /// Vantaggi nascosti accesi e spenti (01 §13.1, 03 §7.1, 05 §12.5).
    case vantaggiNascosti = "vantaggi_nascosti"
    /// Scontro ordinario e scontro nato da imboscata (01 §9.3.2).
    case imboscata
}

/// Uno scenario di scontro singolo (05 §12.2, prima famiglia).
public struct ScenarioDiVerifica: Codable, Sendable {
    public let identificatore: IdentificatoreDati
    public let formato: IdentificatoreDati
    public let caratteristica: IdentificatoreDati
    public let ostacoli: [Cella]
    public let deckGiocatore: [ScenarioBattaglia.ElementoScenario]
    public let deckAvversario: [ScenarioBattaglia.ElementoScenario]
    /// Tetto ai giri: una corsa che non conclude si registra come non conclusa,
    /// e non blocca la misura (05 §12.6: ogni riga deve restare riproducibile).
    public let giriMassimi: Int
    public let assi: [AsseDiVariazione]
    /// Soglie di accettazione per metrica: vivono nello scenario, non nel codice (05 §12.6).
    public let soglie: [String: Int]

    enum CodingKeys: String, CodingKey {
        case identificatore, formato, caratteristica, ostacoli
        case deckGiocatore = "deck_giocatore"
        case deckAvversario = "deck_avversario"
        case giriMassimi = "giri_massimi"
        case assi, soglie
    }
}

/// I parametri dei banchi di misura: le condizioni pari in cui le misure controllate
/// si prendono. Non sono valori di gioco e non entrano in alcuna formula del Motore;
/// cambiarli cambia la misura, non il gioco.
public struct ParametriBanchi: Codable, Sendable {
    public let atomiDiRiferimento: Int64
    public let assalitoreDiRiferimento: IdentificatoreDati
    public let bersaglioDiRiferimento: IdentificatoreDati
    public let protezioneDiRiferimento: TipoProtezione
    public let assalitoriMassimi: Int
    public let giriMassimiDuello: Int
    public let formatoDiProva: IdentificatoreDati

    enum CodingKeys: String, CodingKey {
        case atomiDiRiferimento = "atomi_di_riferimento"
        case assalitoreDiRiferimento = "assalitore_di_riferimento"
        case bersaglioDiRiferimento = "bersaglio_di_riferimento"
        case protezioneDiRiferimento = "protezione_di_riferimento"
        case assalitoriMassimi = "assalitori_massimi"
        case giriMassimiDuello = "giri_massimi_duello"
        case formatoDiProva = "formato_di_prova"
    }
}

/// L'insieme caricato: i banchi più gli scenari, in ordine deterministico.
public struct CartellaScenari: Sendable {
    public let banchi: ParametriBanchi
    public let scenari: [ScenarioDiVerifica]

    public static func carica(da cartella: URL) throws -> CartellaScenari {
        let decoder = JSONDecoder()
        func leggi<T: Decodable>(_ tipo: T.Type, _ url: URL) throws -> T {
            guard let dati = try? Data(contentsOf: url) else {
                throw ErroreDati(chiave: "errore.dati.file_mancante", file: url.lastPathComponent)
            }
            do { return try decoder.decode(tipo, from: dati) }
            catch { throw ErroreDati(chiave: "errore.dati.file_malformato", file: url.lastPathComponent) }
        }
        let banchi = try leggi(ParametriBanchi.self, cartella.appendingPathComponent("banchi.json"))
        let voci = (try? FileManager.default.contentsOfDirectory(at: cartella,
                                                                 includingPropertiesForKeys: nil)) ?? []
        let files = voci.filter { $0.pathExtension == "json" && $0.lastPathComponent != "banchi.json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        var scenari: [ScenarioDiVerifica] = []
        for file in files { scenari.append(try leggi(ScenarioDiVerifica.self, file)) }
        guard !scenari.isEmpty else {
            throw ErroreDati(chiave: "errore.dati.elenco_vuoto", file: cartella.lastPathComponent)
        }
        return CartellaScenari(banchi: banchi, scenari: scenari)
    }
}
