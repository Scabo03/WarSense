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

    /// Lo slot su disco di una battaglia nata dalla campagna (incarico 24): una sottocartella
    /// dedicata sotto lo slot di campagna, nominata dall'identificatore deterministico della
    /// battaglia in sospeso. Distinta dallo slot dello scontro di prova del menu, sicché le due
    /// non si toccano; distinta per identificatore, sicché due battaglie non si sovrappongono.
    static func cartellaBattaglia(_ identificatore: String) -> URL {
        cartellaCampagna.appendingPathComponent("battaglie").appendingPathComponent(identificatore)
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

    // MARK: - Passaggio alla battaglia e ritorno (01 §6, §15, incarico 24)

    /// Il modello PROVVISORIO dello scontro da campagna (S24e): il campo, il terreno, la
    /// protezione, la fase e l'ufficiale che la campagna non dichiara. Li si legge dallo scenario
    /// di prova, così che il riferimento ai dati resti nei DATI e non nel codice: il campo aperto
    /// standard su formato «cento». Non è taratura del combattimento — che il titolare ha
    /// accettato — ma la cornice minima entro cui i due gruppi si affrontano.
    private func modelloScontro() throws -> PonteCampagnaBattaglia.Modello {
        let prova = try PartitaCorrente.scenarioDiProva()
        return PonteCampagnaBattaglia.Modello(
            formato: prova.formato, caratteristica: prova.caratteristica,
            protezione: prova.deckGiocatore.first?.protezione ?? .antiSaturazione,
            fase: prova.fase, ufficialeAvversario: prova.ufficialeAvversario)
    }

    /// Apre la battaglia in sospeso: costruisce lo scenario dai due gruppi in contatto e ne apre
    /// (o riprende) lo slot. Il passaggio alla schermata di battaglia lo decide il chiamante — non
    /// si forza il cambio di schermata (01 §6.2, 02 §5.6).
    func apriBattaglia(_ battaglia: BattagliaInSospeso) async throws -> PartitaCorrente {
        let scenario = PonteCampagnaBattaglia.scenario(da: battaglia, stato: await stato,
                                                       modello: try modelloScontro())
        return try await PartitaCorrente(daCampagna: ambiente, scenario: scenario,
                                         cartella: Self.cartellaBattaglia(battaglia.identificatore),
                                         identificatore: battaglia.identificatore)
    }

    /// L'esito da riportare in campagna, derivato dallo stato finale della battaglia (01 §15). Il
    /// chiamante può poi sostituire la casella di ripiegamento del giocatore con quella SCELTA e
    /// piegare il risultato con `concludiBattaglia(esito:)`.
    func esitoDiRitorno(_ battaglia: BattagliaInSospeso, statoBattaglia: StatoBattaglia) async -> EsitoInCampagna {
        PonteCampagnaBattaglia.esito(da: statoBattaglia, per: battaglia,
                                     stato: await stato, valori: ambiente.valori)
    }

    /// Le caselle fra cui il giocatore SCEGLIE dove ripiegare (01 §10.6, §15.6, incarico 25): le
    /// caselle alle spalle secondo la definizione del taglio, libere. Vuoto = nessuna scelta (resta).
    func caselleDiRipiegamento(perLaCasella casella: Cella) async -> [Cella] {
        PonteCampagnaBattaglia.caselleDiRipiegamento(per: .giocatore, da: casella, stato: await stato)
    }

    /// Riporta in campagna l'esito (01 §15): lo iscrive nel giornale di campagna e lo piega sulla
    /// mappa; poi rimuove lo slot della battaglia, che ha esaurito il suo compito (l'esito vive ora
    /// nel giornale di campagna e vi si rigioca identico). Annuncia l'esito a chi torna sulla mappa.
    func concludiBattaglia(_ battaglia: BattagliaInSospeso, esito: EsitoInCampagna) async throws {
        try await sessione.concludiBattaglia(esito)
        ambiente.segnali.segnala(
            evento: .battagliaConclusa(casella: esito.casella,
                                       giocatoreSconfitto: esito.sconfitto == .giocatore),
            per: .giocatore)
        try? FileManager.default.removeItem(at: Self.cartellaBattaglia(battaglia.identificatore))
    }

    // MARK: - Chiusura esplicita della giornata (incarico 26)

    /// Chiude ESPLICITAMENTE la giornata: la via d'uscita del titolare, sempre disponibile, perché
    /// non resti bloccato da un difetto in una partita in corso. Ritorna la diagnostica di ciò che
    /// la rendeva necessaria; se c'erano gruppi non-agiti — la giornata non si sarebbe chiusa da sé —
    /// la SCRIVE accanto al salvataggio (`diagnostica-giornata-N.json`, nello slot di campagna),
    /// sicché il titolare possa mandarla indietro insieme al giornale. Non è un canale del collaudo:
    /// è il gioco vero che conserva la traccia di un blocco che il titolare non sa riprodurre.
    @discardableResult
    func chiudiGiornata() async throws -> DiagnosticaChiusura {
        let diagnostica = try await sessione.chiudiGiornata()
        if diagnostica.laGiornataNonSiSarebbeChiusa {
            scriviDiagnostica(diagnostica)
        }
        return diagnostica
    }

    /// Dove vive la diagnostica: un file accanto a `giornale.jsonl`, nello stesso slot, sicché
    /// viaggia con il salvataggio quando il titolare lo manda indietro. Scrittura atomica (05 §6.8).
    static func urlDiagnostica(giorno: Int) -> URL {
        cartellaCampagna.appendingPathComponent("diagnostica-giornata-\(giorno).json")
    }

    private func scriviDiagnostica(_ diagnostica: DiagnosticaChiusura) {
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        guard let dati = try? codificatore.encode(diagnostica) else { return }
        try? dati.write(to: Self.urlDiagnostica(giorno: diagnostica.giorno), options: .atomic)
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
