import UIKit
import Dati
import Motore
import Sessione
import Segnali
import Contenuti

/// Il coordinatore dello scontro in corso: possiede la Sessione, fa agire il
/// tattico avversario e smista gli eventi ai Segnali (05 §1.7, §1.8).
/// L'interfaccia non calcola mai un dato di gioco: chiede e presenta (00 §3.2).
@MainActor
final class PartitaCorrente {
    let ambiente: Ambiente
    let motore: MotoreBattaglia
    private let sessione: SessioneBattaglia
    private let tattico: TatticoBattaglia
    /// Chi ascolta gli eventi dell'interfaccia (la schermata di battaglia).
    var consegnaEventi: (([EventoBattaglia]) -> Void)?

    static var cartellaScontroDiProva: URL {
        Ambiente.cartellaPartite.appendingPathComponent("scontro-di-prova")
    }

    private struct FileScenari: Codable {
        let scenarioDiProva: ScenarioBattaglia
        enum CodingKeys: String, CodingKey { case scenarioDiProva = "scenario_di_prova" }
    }

    static func scenarioDiProva() throws -> ScenarioBattaglia {
        let url = Ambiente.cartellaValori.appendingPathComponent("scenari.json")
        let dati = try (try? Data(contentsOf: url))
            ?? Data(contentsOf: Contenuti.valoriDiFabbrica.appendingPathComponent("scenari.json"))
        return try JSONDecoder().decode(FileScenari.self, from: dati).scenarioDiProva
    }

    static func esisteScontroInCorso() -> Bool {
        FileManager.default.fileExists(
            atPath: cartellaScontroDiProva.appendingPathComponent("giornale.jsonl").path)
    }

    /// Crea uno scontro nuovo, sostituendo l'eventuale slot precedente.
    init(nuova ambiente: Ambiente) async throws {
        self.ambiente = ambiente
        self.motore = MotoreBattaglia(valori: ambiente.valori)
        try? FileManager.default.removeItem(at: Self.cartellaScontroDiProva)
        let scenario = try Self.scenarioDiProva()
        var generatore = SystemRandomNumberGenerator()
        self.sessione = try await SessioneBattaglia(
            nuova: scenario, valori: ambiente.valori, versioneTesti: ambiente.testi.versione,
            cartella: Self.cartellaScontroDiProva,
            seme: generatore.next(),
            identificatore: UUID().uuidString)
        self.tattico = Self.tattico(per: scenario, motore: motore, valori: ambiente.valori)
    }

    /// Riprende lo scontro salvato dal giornale (00 §3.5, 05 §6.3).
    init(riprendi ambiente: Ambiente) async throws {
        self.ambiente = ambiente
        self.motore = MotoreBattaglia(valori: ambiente.valori)
        self.sessione = try await SessioneBattaglia(riprendi: Self.cartellaScontroDiProva,
                                                    valori: ambiente.valori)
        let scenario = await sessione.fondazione.scenario
        self.tattico = Self.tattico(per: scenario, motore: motore, valori: ambiente.valori)
    }

    /// Apre uno scontro NATO DA UNA CAMPAGNA nel suo slot proprio (incarico 24): scenario
    /// esplicito derivato dai gruppi in contatto, cartella dedicata sotto lo slot di campagna,
    /// identificatore deterministico. Se lo slot esiste già lo RIPRENDE — una battaglia chiusa e
    /// riaperta dal giornale è la stessa (05 §6.3) —, altrimenti lo crea. È così che una battaglia
    /// nata dalla campagna si salva, si riprende e si rigioca, anche dopo un riavvio.
    init(daCampagna ambiente: Ambiente, scenario: ScenarioBattaglia,
         cartella: URL, identificatore: String) async throws {
        self.ambiente = ambiente
        self.motore = MotoreBattaglia(valori: ambiente.valori)
        let giornale = cartella.appendingPathComponent("giornale.jsonl")
        if FileManager.default.fileExists(atPath: giornale.path) {
            self.sessione = try await SessioneBattaglia(riprendi: cartella, valori: ambiente.valori)
            let ripreso = await sessione.fondazione.scenario
            self.tattico = Self.tattico(per: ripreso, motore: motore, valori: ambiente.valori)
        } else {
            var generatore = SystemRandomNumberGenerator()
            self.sessione = try await SessioneBattaglia(
                nuova: scenario, valori: ambiente.valori, versioneTesti: ambiente.testi.versione,
                cartella: cartella, seme: generatore.next(), identificatore: identificatore)
            self.tattico = Self.tattico(per: scenario, motore: motore, valori: ambiente.valori)
        }
    }

    private static func tattico(per scenario: ScenarioBattaglia, motore: MotoreBattaglia,
                                valori: ValoriDiGioco) -> TatticoBattaglia {
        let identificatore = scenario.ufficialeAvversario
        let ufficiale = identificatore.flatMap { valori.ufficiali[$0] }
            ?? valori.ufficiali.values.sorted { $0.identificatore < $1.identificatore }[0]
        return TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .avversario)
    }

    // MARK: - Letture

    var stato: StatoBattaglia { get async { await sessione.stato } }
    var vista: VistaBattaglia { get async { await sessione.vista(per: .giocatore) } }
    var eventiIniziali: [EventoBattaglia] { get async { await sessione.eventiIniziali } }

    func anteprima(_ comando: ComandoBattaglia) async -> EsitoValidazione {
        await sessione.anteprima(comando, parte: .giocatore)
    }

    // MARK: - Esecuzione

    /// Esegue un comando del giocatore; se il turno passa all'avversario, fa agire
    /// il tattico. Gli eventi arrivano ai Segnali e alla schermata, senza toccare
    /// il fuoco (00 §11.4).
    @discardableResult
    func esegui(_ comando: ComandoBattaglia) async throws -> EsitoValidazione {
        let (esito, eventi) = try await sessione.esegui(comando, parte: .giocatore)
        guard esito.eValido else { return esito }
        distribuisci(eventi)
        var stato = await sessione.stato
        while stato.parteDiTurno == .avversario && stato.esito == nil {
            let eventiAvversario = try await sessione.eseguiTurnoAvversario(tattico)
            distribuisci(eventiAvversario)
            stato = await sessione.stato
        }
        return esito
    }

    /// Fa agire l'avversario se tocca a LUI appena aperta la battaglia (01 §9.4.1): quando il
    /// primo occupante è l'avversario — una battaglia imposta entrando nella sua casella, dove
    /// chi attendeva riceve la prima mossa — agisce per primo, e senza questo nulla lo muoverebbe
    /// finché il giocatore non agisce, ma il giocatore non può agire nel turno altrui: sarebbe uno
    /// stallo. Negli scontri del menu il primo occupante è sempre il giocatore, sicché non serviva.
    func muoviAvversarioSeTocca() async throws {
        var stato = await sessione.stato
        while stato.parteDiTurno == .avversario && stato.esito == nil {
            let eventi = try await sessione.eseguiTurnoAvversario(tattico)
            distribuisci(eventi)
            stato = await sessione.stato
        }
    }

    func annulla() async throws {
        try await sessione.annulla(parte: .giocatore)
    }

    func azzera() async throws {
        try await sessione.azzera(parte: .giocatore)
    }

    private func distribuisci(_ eventi: [EventoBattaglia]) {
        for evento in eventi {
            ambiente.segnali.segnala(evento: evento, per: .giocatore)
        }
        consegnaEventi?(eventi)
    }
}
