import Foundation
import Motore
import Dati

/// L'atto di fondazione: prima riga del giornale (05 §2.10). Stato iniziale
/// ricostruito dalla fabbrica più comandi del giornale: questa è l'intera
/// definizione di una partita (05 §4.5).
public struct Fondazione: Codable, Sendable {
    public let versioneSchema: Int
    public let versioneValori: String
    public let versioneTesti: String
    public let seme: UInt64
    public let identificatore: String
    public let scenario: ScenarioBattaglia
    /// Versione 2 dalla prima tranche di semplificazioni (01 versione 3.3): il
    /// comando di tiro non trasporta più il proiettile, che è del reparto.
    public static let schemaCorrente = 2

    public init(versioneSchema: Int, versioneValori: String, versioneTesti: String,
                seme: UInt64, identificatore: String, scenario: ScenarioBattaglia) {
        self.versioneSchema = versioneSchema
        self.versioneValori = versioneValori
        self.versioneTesti = versioneTesti
        self.seme = seme
        self.identificatore = identificatore
        self.scenario = scenario
    }

    enum CodingKeys: String, CodingKey {
        case versioneSchema = "versione_schema"
        case versioneValori = "versione_valori"
        case versioneTesti = "versione_testi"
        case seme, identificatore, scenario
    }
}

/// L'atto di fondazione di una campagna. Caso a sé e non riuso di `Fondazione`,
/// perché lo scenario che vi si iscrive è di natura diversa: mescolarli avrebbe
/// reso opzionale un campo dell'atto di fondazione della battaglia, e un campo
/// opzionale in più nel formato di salvataggio è un rischio senza contropartita.
public struct FondazioneCampagna: Codable, Sendable {
    public let versioneSchema: Int
    public let versioneValori: String
    public let versioneTesti: String
    public let seme: UInt64
    public let identificatore: String
    public let scenario: ScenarioCampagna
    /// Versione 1: la prima forma dell'atto di fondazione di una campagna.
    public static let schemaCorrente = 1

    public init(versioneSchema: Int, versioneValori: String, versioneTesti: String,
                seme: UInt64, identificatore: String, scenario: ScenarioCampagna) {
        self.versioneSchema = versioneSchema
        self.versioneValori = versioneValori
        self.versioneTesti = versioneTesti
        self.seme = seme
        self.identificatore = identificatore
        self.scenario = scenario
    }

    enum CodingKeys: String, CodingKey {
        case versioneSchema = "versione_schema"
        case versioneValori = "versione_valori"
        case versioneTesti = "versione_testi"
        case seme, identificatore, scenario
    }
}

/// Le voci del giornale (05 §6.1): comandi e marcatori. La codifica è stabile:
/// i casi si AGGIUNGONO, non si rinominano e non si riordinano.
///
/// La codifica sintetizzata degli enumerativi con valori associati usa il NOME del
/// caso come chiave e non la sua posizione: aggiungere un caso non tocca la
/// codifica degli altri, rinominarne uno rende illeggibili i giornali già scritti.
/// I tre casi della campagna sono quindi aggiunti in coda e i campioni committati
/// dei tre casi preesistenti continuano a ricodificarsi byte per byte identici
/// (`CompatibilitaGiornaleTest`).
public enum VoceGiornale: Codable, Sendable {
    case fondazione(Fondazione)
    case comando(parte: Parte, comando: ComandoBattaglia)
    /// Marcatore di inizio turno: bersaglio dell'azzeramento (05 §6.4) e punto di conferma (05 §6.5).
    case inizioTurno(parte: Parte, giro: Int)
    /// Atto di fondazione di una campagna (05 §2.10).
    case fondazioneCampagna(FondazioneCampagna)
    /// Un comando di campagna (05 §3.3).
    case comandoCampagna(parte: Parte, comando: ComandoCampagna)
    /// Marcatore di apertura giornata: bersaglio dell'azzeramento sulla mappa di
    /// campagna (05 §6.4) e punto di conferma (05 §6.5).
    case aperturaGiornata(giorno: Int)
}

/// Una riga del giornale, numerata progressivamente.
public struct RigaGiornale: Codable, Sendable {
    public let numero: Int
    public let voce: VoceGiornale
    public init(numero: Int, voce: VoceGiornale) {
        self.numero = numero
        self.voce = voce
    }
}

/// Il giornale dei comandi: file in appendice, una riga JSON per voce (05 §6.1).
/// La scrittura è confermata prima che l'esito diventi visibile; il ritiro è una
/// riscrittura atomica (05 §6.4); la lettura tollera una riga finale tronca (05 §6.8).
public final class Giornale {
    public let percorso: URL
    private var maniglia: FileHandle
    public private(set) var righe: [RigaGiornale]

    private static let codificatore: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return e
    }()
    private static let decodificatore = JSONDecoder()

    public enum ErroreGiornale: Error {
        case percorsoNonScrivibile
        case fondazioneMancante
    }

    /// Apre un giornale nuovo, scrivendo l'atto di fondazione della battaglia.
    public static func nuovo(a percorso: URL, fondazione: Fondazione) throws -> Giornale {
        try nuovo(a: percorso, atto: .fondazione(fondazione))
    }

    /// Apre un giornale nuovo, scrivendo l'atto di fondazione della campagna.
    public static func nuovo(a percorso: URL, fondazione: FondazioneCampagna) throws -> Giornale {
        try nuovo(a: percorso, atto: .fondazioneCampagna(fondazione))
    }

    private static func nuovo(a percorso: URL, atto: VoceGiornale) throws -> Giornale {
        FileManager.default.createFile(atPath: percorso.path, contents: nil)
        guard let maniglia = try? FileHandle(forWritingTo: percorso) else {
            throw ErroreGiornale.percorsoNonScrivibile
        }
        let giornale = Giornale(percorso: percorso, maniglia: maniglia, righe: [])
        try giornale.appendi(atto)
        return giornale
    }

    /// Apre un giornale esistente, troncando alla ultima riga integra se serve (05 §6.8).
    public static func apri(a percorso: URL) throws -> Giornale {
        let contenuto = (try? Data(contentsOf: percorso)) ?? Data()
        var righe: [RigaGiornale] = []
        var byteValidi = 0
        var inizio = contenuto.startIndex
        while inizio < contenuto.endIndex {
            let fine = contenuto[inizio...].firstIndex(of: 0x0A) ?? contenuto.endIndex
            let rigaByte = contenuto[inizio..<fine]
            if fine == contenuto.endIndex { break } // riga senza fine riga: tronca, non integra
            if let riga = try? decodificatore.decode(RigaGiornale.self, from: Data(rigaByte)) {
                righe.append(riga)
                byteValidi = contenuto.distance(from: contenuto.startIndex, to: fine) + 1
            } else {
                break // prima riga corrotta: si tronca qui
            }
            inizio = contenuto.index(after: fine)
        }
        if byteValidi < contenuto.count {
            try contenuto.prefix(byteValidi).write(to: percorso, options: .atomic)
        }
        // La prima riga è sempre un atto di fondazione, di battaglia o di campagna.
        switch righe.first?.voce {
        case .fondazione, .fondazioneCampagna: break
        default: throw ErroreGiornale.fondazioneMancante
        }
        guard let maniglia = try? FileHandle(forWritingTo: percorso) else {
            throw ErroreGiornale.percorsoNonScrivibile
        }
        try maniglia.seekToEnd()
        return Giornale(percorso: percorso, maniglia: maniglia, righe: righe)
    }

    private init(percorso: URL, maniglia: FileHandle, righe: [RigaGiornale]) {
        self.percorso = percorso
        self.maniglia = maniglia
        self.righe = righe
    }

    public var fondazione: Fondazione {
        if case .fondazione(let f) = righe[0].voce { return f }
        preconditionFailure("giornale.senza.fondazione")
    }

    public var fondazioneCampagna: FondazioneCampagna {
        if case .fondazioneCampagna(let f) = righe[0].voce { return f }
        preconditionFailure("giornale.senza.fondazione.campagna")
    }

    /// Appende e conferma su disco prima di restituire (05 §6.1).
    public func appendi(_ voce: VoceGiornale) throws {
        let riga = RigaGiornale(numero: righe.count, voce: voce)
        var dati = try Giornale.codificatore.encode(riga)
        dati.append(0x0A)
        try maniglia.write(contentsOf: dati)
        try maniglia.synchronize()
        righe.append(riga)
    }

    /// Ritira le righe dalla posizione indicata in poi: riscrittura atomica (05 §6.4).
    public func tronca(a numeroRighe: Int) throws {
        precondition(numeroRighe >= 1, "la.fondazione.non.si.ritira")
        let rimaste = Array(righe.prefix(numeroRighe))
        var dati = Data()
        for riga in rimaste {
            dati.append(try Giornale.codificatore.encode(riga))
            dati.append(0x0A)
        }
        try dati.write(to: percorso, options: .atomic)
        try? maniglia.close()
        guard let nuova = try? FileHandle(forWritingTo: percorso) else {
            throw ErroreGiornale.percorsoNonScrivibile
        }
        try nuova.seekToEnd()
        maniglia = nuova
        righe = rimaste
    }

    deinit { try? maniglia.close() }
}
