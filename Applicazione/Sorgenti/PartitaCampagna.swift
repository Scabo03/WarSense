import UIKit
import Dati
import Motore
import Sessione
import Segnali
import Contenuti

/// Il coordinatore della campagna in corso: possiede la Sessione e smista gli
/// eventi ai Segnali (05 §1.7, §1.8). Gemello di `PartitaCorrente` per la
/// battaglia; l'interfaccia non calcola mai un dato di gioco (00 §3.2).
///
/// La campagna vive in uno SLOT PROPRIO, distinto da quello dello scontro: aprire
/// o cominciare una campagna non tocca in alcun modo la ripresa di una battaglia
/// salvata, che resta esattamente dov'era.
@MainActor
final class PartitaCampagna {
    let ambiente: Ambiente
    let motore: MotoreCampagna
    private let sessione: SessioneCampagna

    /// Le tre campagne di prova, una per formato di mappa (01 §5.1).
    enum Taglia: String, CaseIterable {
        case piccola = "campagna_piccola"
        case media = "campagna_media"
        case grande = "campagna_grande"
    }

    static var cartellaCampagna: URL {
        Ambiente.cartellaPartite.appendingPathComponent("campagna-di-prova")
    }

    static func esisteCampagnaInCorso() -> Bool {
        FileManager.default.fileExists(
            atPath: cartellaCampagna.appendingPathComponent("giornale.jsonl").path)
    }

    static func scenario(_ taglia: Taglia) throws -> ScenarioCampagna {
        let nome = "scenari-campagna.json"
        let url = Ambiente.cartellaValori.appendingPathComponent(nome)
        let dati = try (try? Data(contentsOf: url))
            ?? Data(contentsOf: Contenuti.valoriDiFabbrica.appendingPathComponent(nome))
        let tutti = try JSONDecoder().decode([String: ScenarioCampagna].self, from: dati)
        guard let scenario = tutti[taglia.rawValue] else {
            throw FabbricaCampagna.ErroreScenario.mappaIgnota(taglia.rawValue)
        }
        return scenario
    }

    /// Crea una campagna nuova da uno SCENARIO qualunque, sostituendo l'eventuale
    /// slot precedente.
    ///
    /// È la forma che il gioco richiede, non un'aggiunta per il collaudo. Le tre
    /// `Taglia` sono campagne di prova, come il loro stesso commento dichiara:
    /// quando esisteranno i fronti, 01 §5.6.9 vuole più campagne aperte insieme,
    /// ciascuna su una mappa propria e con almeno cinque mappe per fronte, e
    /// 01 §5.6.10 fa entrare nella mappa dalla schermata delle campagne, scegliendo
    /// una località. La schermata aprirà allora la campagna scelta a partire dal suo
    /// scenario, non da uno di tre formati fissi. L'inizializzatore per taglia è il
    /// riparo provvisorio e delega a questo.
    init(nuova ambiente: Ambiente, scenario: ScenarioCampagna) async throws {
        self.ambiente = ambiente
        self.motore = MotoreCampagna(valori: ambiente.valori,
                                     valoriCampagna: ambiente.valoriCampagna)
        try? FileManager.default.removeItem(at: Self.cartellaCampagna)
        var generatore = SystemRandomNumberGenerator()
        self.sessione = try await SessioneCampagna(
            nuova: scenario, valori: ambiente.valori,
            valoriCampagna: ambiente.valoriCampagna,
            versioneTesti: ambiente.testi.versione,
            cartella: Self.cartellaCampagna,
            seme: generatore.next(), identificatore: UUID().uuidString)
    }

    /// Le tre campagne di prova, per identificatore di taglia.
    convenience init(nuova ambiente: Ambiente, taglia: Taglia) async throws {
        try await self.init(nuova: ambiente, scenario: Self.scenario(taglia))
    }

    /// Riprende la campagna salvata dal giornale (00 §3.5, 05 §6.3).
    init(riprendi ambiente: Ambiente) async throws {
        self.ambiente = ambiente
        self.motore = MotoreCampagna(valori: ambiente.valori,
                                     valoriCampagna: ambiente.valoriCampagna)
        self.sessione = try await SessioneCampagna(riprendi: Self.cartellaCampagna,
                                                   valori: ambiente.valori,
                                                   valoriCampagna: ambiente.valoriCampagna)
    }

    // MARK: - Letture

    var stato: StatoCampagna { get async { await sessione.stato } }
    var vista: VistaCampagna { get async { await sessione.vista(per: .giocatore) } }

    func anteprima(_ comando: ComandoCampagna) async -> EsitoValidazioneCampagna {
        await sessione.anteprima(comando, parte: .giocatore)
    }

    // MARK: - Esecuzione

    @discardableResult
    func esegui(_ comando: ComandoCampagna) async throws -> EsitoValidazioneCampagna {
        let (esito, eventi) = try await sessione.esegui(comando, parte: .giocatore)
        guard esito.eValido else { return esito }
        for evento in eventi { ambiente.segnali.segnala(evento: evento, per: .giocatore) }
        return esito
    }

    @discardableResult
    func annulla() async throws -> SessioneCampagna.EsitoAnnullamento {
        try await sessione.annulla(parte: .giocatore)
    }

    @discardableResult
    func azzera() async throws -> SessioneCampagna.EsitoAnnullamento {
        try await sessione.azzera(parte: .giocatore)
    }
}
