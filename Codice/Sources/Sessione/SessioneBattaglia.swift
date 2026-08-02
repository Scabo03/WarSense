import Foundation
import Motore
import Dati

/// L'orchestratore di uno scontro (05 §1.7): unico proprietario dello stato corrente
/// e unico scrittore del giornale. Elaborazione seriale; la scrittura è confermata
/// prima che l'esito diventi visibile; gli eventi della riapplicazione non escono.
public actor SessioneBattaglia {

    public enum ErroreSessione: Error, Sendable {
        /// Salvataggio con versione dei valori incompatibile: dichiarato e non aperto (00 §15.2).
        case salvataggioIncompatibile(attesa: String, trovata: String)
        case schemaIncompatibile(atteso: Int, trovato: Int)
        /// Un comando del giornale non è più valido alla riapplicazione: giornale corrotto.
        case giornaleCorrotto(riga: Int)
        case scritturaFallita
        case operazioneNonDisponibile
    }

    private let motore: MotoreBattaglia
    private let giornale: Giornale
    private let cartella: URL
    public private(set) var stato: StatoBattaglia
    /// Ogni quante righe si scatta un'istantanea: numero di struttura, non di gioco (05 §6.2).
    private static let passoIstantanee = 200

    // MARK: - Nascita e ripresa

    /// Crea una partita di scontro nuova (05 §2.10). Il seme e l'identificatore
    /// li fornisce chi chiama: la Sessione non è il Motore e può attingere all'entropia.
    public init(nuova scenario: ScenarioBattaglia, valori: ValoriDiGioco, versioneTesti: String,
                cartella: URL, seme: UInt64, identificatore: String) throws {
        try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        self.cartella = cartella
        self.motore = MotoreBattaglia(valori: valori)
        let fondazione = Fondazione(versioneSchema: Fondazione.schemaCorrente,
                                    versioneValori: valori.versioneEffettiva,
                                    versioneTesti: versioneTesti,
                                    seme: seme, identificatore: identificatore,
                                    scenario: scenario)
        self.giornale = try Giornale.nuovo(a: cartella.appendingPathComponent("giornale.jsonl"),
                                           fondazione: fondazione)
        let (statoIniziale, eventi) = try FabbricaBattaglia.crea(scenario: scenario, valori: valori)
        self.stato = statoIniziale
        self.eventiIniziali = eventi
        try Self.registraMarcatori(per: eventi, giornale: giornale, stato: statoIniziale, cartella: cartella)
        try Self.scattaIstantanea(giornale: giornale, stato: statoIniziale, cartella: cartella, forzata: true)
    }

    /// Gli eventi di apertura del primo turno, da consegnare una sola volta.
    public private(set) var eventiIniziali: [EventoBattaglia] = []

    /// Riprende dal giornale: istantanea più recente più riapplicazione (05 §6.3).
    /// Un salvataggio incompatibile viene dichiarato e non aperto (00 §15.2).
    public init(riprendi cartella: URL, valori: ValoriDiGioco) throws {
        self.cartella = cartella
        self.motore = MotoreBattaglia(valori: valori)
        self.giornale = try Giornale.apri(a: cartella.appendingPathComponent("giornale.jsonl"))
        let fondazione = giornale.fondazione

        guard fondazione.versioneSchema == Fondazione.schemaCorrente else {
            throw ErroreSessione.schemaIncompatibile(atteso: Fondazione.schemaCorrente,
                                                     trovato: fondazione.versioneSchema)
        }
        // Compatibilità sulla versione base (RDA-45): il suffisso locale è un'avvertenza, non un blocco.
        let baseSalvataggio = String(fondazione.versioneValori.split(separator: "+")[0])
        let compatibile = fondazione.versioneValori == valori.versioneEffettiva
            || valori.versioniCompatibili.contains(baseSalvataggio)
        guard compatibile else {
            throw ErroreSessione.salvataggioIncompatibile(attesa: valori.versioneEffettiva,
                                                          trovata: fondazione.versioneValori)
        }

        // Istantanea più recente non oltre la fine del giornale, poi riapplicazione.
        var (statoCorrente, daRiga) = try Self.istantaneaMigliore(in: cartella,
                                                                  nonOltre: giornale.righe.count,
                                                                  scenario: fondazione.scenario,
                                                                  valori: valori)
        for riga in giornale.righe.dropFirst(daRiga) {
            guard case .comando(let parte, let comando) = riga.voce else { continue }
            guard motore.valida(comando, parte: parte, stato: statoCorrente).eValido else {
                throw ErroreSessione.giornaleCorrotto(riga: riga.numero)
            }
            // Riapplicazione: gli eventi non raggiungono nessuno (05 §6.3).
            (statoCorrente, _) = motore.applica(comando, parte: parte, stato: statoCorrente)
        }
        self.stato = statoCorrente
    }

    // MARK: - Esecuzione (05 §1.7)

    /// Valida, appende al giornale con conferma di scrittura, applica, consegna gli eventi.
    /// Un comando non valido non viene applicato né registrato: l'esito riporta il motivo.
    public func esegui(_ comando: ComandoBattaglia,
                       parte: Parte) throws -> (esito: EsitoValidazione, eventi: [EventoBattaglia]) {
        let esito = motore.valida(comando, parte: parte, stato: stato)
        guard esito.eValido else { return (esito, []) }
        do { try giornale.appendi(.comando(parte: parte, comando: comando)) }
        catch { throw ErroreSessione.scritturaFallita }
        let (nuovoStato, eventi) = motore.applica(comando, parte: parte, stato: stato)
        stato = nuovoStato
        try registraMarcatoriDiTurno(per: eventi)
        try scattaIstantaneaSeServe(forzata: false)
        return (esito, eventi)
    }

    /// L'anteprima è la validazione (05 §3.2).
    public func anteprima(_ comando: ComandoBattaglia, parte: Parte) -> EsitoValidazione {
        motore.valida(comando, parte: parte, stato: stato)
    }

    public func vista(per parte: Parte) -> VistaBattaglia {
        VistaBattaglia(motore: motore, stato: stato, parte: parte)
    }

    public func impronta() -> String { stato.impronta() }
    public var fondazione: Fondazione { giornale.fondazione }
    public var numeroRigheGiornale: Int { giornale.righe.count }

    // MARK: - Annullamento e azzeramento (05 §6.4, RDA-05)

    /// Ritira l'ultimo comando della parte, mai oltre un punto di conferma (05 §6.5).
    /// La fine del proprio turno è un punto di conferma: non si annulla.
    public func annulla(parte: Parte) throws {
        guard case .comando(let p, let c) = giornale.righe.last?.voce,
              p == parte, c != .fineTurno else {
            throw ErroreSessione.operazioneNonDisponibile
        }
        try ritira(a: giornale.righe.count - 1)
    }

    /// Ritira tutti i comandi della parte dal marcatore di inizio del turno corrente (05 §6.4).
    public func azzera(parte: Parte) throws {
        guard stato.parteDiTurno == parte, stato.esito == nil else {
            throw ErroreSessione.operazioneNonDisponibile
        }
        var indiceMarcatore: Int? = nil
        for riga in giornale.righe.reversed() {
            if case .inizioTurno(let p, _) = riga.voce, p == parte {
                indiceMarcatore = riga.numero
                break
            }
        }
        guard let indice = indiceMarcatore else { throw ErroreSessione.operazioneNonDisponibile }
        try ritira(a: indice + 1)
    }

    private func ritira(a numeroRighe: Int) throws {
        try giornale.tronca(a: numeroRighe)
        try eliminaIstantanee(oltre: numeroRighe)
        // Ricostruzione dall'istantanea più recente, eventi soppressi (05 §6.4, §6.3).
        var (statoCorrente, daRiga) = try Self.istantaneaMigliore(in: cartella,
                                                                 nonOltre: numeroRighe,
                                                                 scenario: giornale.fondazione.scenario,
                                                                 valori: motore.valori)
        for riga in giornale.righe.dropFirst(daRiga) {
            guard case .comando(let parte, let comando) = riga.voce else { continue }
            guard motore.valida(comando, parte: parte, stato: statoCorrente).eValido else {
                throw ErroreSessione.giornaleCorrotto(riga: riga.numero)
            }
            (statoCorrente, _) = motore.applica(comando, parte: parte, stato: statoCorrente)
        }
        stato = statoCorrente
    }

    // MARK: - Istantanee (05 §6.2)

    private struct Istantanea: Codable {
        let righeApplicate: Int
        let stato: StatoBattaglia
        enum CodingKeys: String, CodingKey {
            case righeApplicate = "righe_applicate"
            case stato
        }
    }

    private func registraMarcatoriDiTurno(per eventi: [EventoBattaglia]) throws {
        try Self.registraMarcatori(per: eventi, giornale: giornale, stato: stato, cartella: cartella)
    }

    private func scattaIstantaneaSeServe(forzata: Bool) throws {
        try Self.scattaIstantanea(giornale: giornale, stato: stato, cartella: cartella, forzata: forzata)
    }

    private static func registraMarcatori(per eventi: [EventoBattaglia], giornale: Giornale,
                                          stato: StatoBattaglia, cartella: URL) throws {
        for evento in eventi {
            if case .turnoIniziato(let parte, let giro) = evento {
                try giornale.appendi(.inizioTurno(parte: parte, giro: giro))
                try scattaIstantanea(giornale: giornale, stato: stato, cartella: cartella, forzata: true)
            }
        }
    }

    private static func scattaIstantanea(giornale: Giornale, stato: StatoBattaglia,
                                         cartella: URL, forzata: Bool) throws {
        let conta = giornale.righe.count
        guard forzata || conta % passoIstantanee == 0 else { return }
        let istantanea = Istantanea(righeApplicate: conta, stato: stato)
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = [.sortedKeys]
        let dati = try codificatore.encode(istantanea)
        let url = cartella.appendingPathComponent("istantanea-\(conta).json")
        try dati.write(to: url, options: .atomic) // scrittura atomica (05 §6.8)
    }

    private func eliminaIstantanee(oltre limite: Int) throws {
        for (indice, url) in Self.istantaneeDisponibili(in: cartella) where indice > limite {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func istantaneeDisponibili(in cartella: URL) -> [(Int, URL)] {
        let contenuti = (try? FileManager.default.contentsOfDirectory(at: cartella,
                                                                      includingPropertiesForKeys: nil)) ?? []
        return contenuti.compactMap { url in
            let nome = url.lastPathComponent
            guard nome.hasPrefix("istantanea-"), nome.hasSuffix(".json"),
                  let indice = Int(nome.dropFirst("istantanea-".count).dropLast(".json".count))
            else { return nil }
            return (indice, url)
        }.sorted { $0.0 < $1.0 }
    }

    /// L'istantanea valida più recente non oltre il limite, o lo stato di fabbrica.
    /// Un'istantanea corrotta fa scalare alla precedente (05 §6.8).
    private static func istantaneaMigliore(in cartella: URL, nonOltre limite: Int,
                                           scenario: ScenarioBattaglia,
                                           valori: ValoriDiGioco) throws -> (StatoBattaglia, Int) {
        let candidate = istantaneeDisponibili(in: cartella)
            .filter { $0.0 <= limite }
            .sorted { $0.0 > $1.0 }
        for (indice, url) in candidate {
            if let dati = try? Data(contentsOf: url),
               let istantanea = try? JSONDecoder().decode(Istantanea.self, from: dati) {
                return (istantanea.stato, indice)
            }
        }
        let (stato, _) = try FabbricaBattaglia.crea(scenario: scenario, valori: valori)
        return (stato, 0)
    }
}
