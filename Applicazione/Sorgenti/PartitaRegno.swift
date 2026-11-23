import UIKit
import Dati
import Motore
import Sessione
import Segnali
import Contenuti

/// Il coordinatore del regno in corso (incarico 30, RDA-162): possiede la Sessione del regno,
/// smista i suoi eventi ai Segnali e tiene insieme il regno e la campagna dell'anno, che vive in
/// uno slot annidato. Gemello di `PartitaCampagna` e di `PartitaCorrente`; l'interfaccia non calcola
/// mai un dato di gioco (00 §3.2).
///
/// Il regno vive in uno SLOT PROPRIO: cominciarne o riprenderne uno non tocca né lo scontro di
/// prova né le campagne di prova, che restano dov'erano.
@MainActor
final class PartitaRegno {
    let ambiente: Ambiente
    private let sessione: SessioneRegno
    let motore: MotoreRegno

    static var cartellaRegno: URL {
        Ambiente.cartellaPartite.appendingPathComponent("regno")
    }

    /// Lo slot annidato della campagna dell'anno.
    static var cartellaCampagna: URL {
        cartellaRegno.appendingPathComponent(SessioneRegno.cartellaCampagna)
    }

    static func esisteRegnoInCorso() -> Bool {
        FileManager.default.fileExists(
            atPath: cartellaRegno.appendingPathComponent(SessioneRegno.nomeGiornale).path)
    }

    /// Crea un regno nuovo, sostituendo l'eventuale slot precedente.
    init(nuovo ambiente: Ambiente) async throws {
        self.ambiente = ambiente
        self.motore = MotoreRegno(valori: ambiente.valoriRegno)
        try? FileManager.default.removeItem(at: Self.cartellaRegno)
        var generatore = SystemRandomNumberGenerator()
        self.sessione = try await SessioneRegno(
            nuovo: ambiente.valoriRegno, versioneValori: ambiente.valori.versioneEffettiva,
            versioneTesti: ambiente.testi.versione, cartella: Self.cartellaRegno,
            seme: generatore.next(), identificatore: UUID().uuidString)
    }

    /// Riprende il regno salvato dal giornale (00 §3.5, 05 §6.3).
    init(riprendi ambiente: Ambiente) async throws {
        self.ambiente = ambiente
        self.motore = MotoreRegno(valori: ambiente.valoriRegno)
        self.sessione = try await SessioneRegno(
            riprendi: Self.cartellaRegno, valori: ambiente.valoriRegno,
            versioneValori: ambiente.valori.versioneEffettiva,
            versioniCompatibili: ambiente.valori.versioniCompatibili)
    }

    // MARK: - Letture

    var stato: StatoRegno { get async { await sessione.stato } }
    var valori: ValoriRegno { ambiente.valoriRegno }

    func anteprima(_ comando: ComandoRegno) async -> EsitoValidazioneRegno {
        await sessione.anteprima(comando)
    }

    // MARK: - Esecuzione

    /// Esegue un comando del regno e ne consegna gli eventi al punto dei segnali: la sola via per
    /// cui un fatto del regno diventa annuncio, suono o vibrazione (00 §5.3).
    @discardableResult
    func esegui(_ comando: ComandoRegno) async throws -> EsitoValidazioneRegno {
        let (esito, eventi) = try await sessione.esegui(comando)
        guard esito.eValido else { return esito }
        await segnala(eventi)
        return esito
    }

    private func segnala(_ eventi: [EventoRegno]) async {
        let stato = await sessione.stato
        for evento in eventi {
            ambiente.segnali.segnala(evento: evento, fase: stato.fase, forze: stato.forze)
        }
    }

    @discardableResult
    func annullaSpesa() async throws -> LavoroOrdinato {
        try await sessione.annullaSpesa()
    }

    @discardableResult
    func azzeraSpese() async throws -> Int {
        try await sessione.azzeraSpese()
    }

    // MARK: - La campagna dell'anno (RDA-162, RDA-166)

    /// Lo scenario che dà a un fronte la mappa e le forze avversarie.
    private func scenario(delFronte fronte: IdentificatoreDati) throws -> ScenarioCampagna {
        guard let voce = valori.fronte(fronte) else {
            throw FabbricaCampagna.ErroreScenario.mappaIgnota(fronte)
        }
        return try PartitaCampagna.scenario(chiave: voce.scenario)
    }

    /// Le dimensioni della mappa di un fronte, per dichiararle quando lo si sceglie.
    func mappa(delFronte fronte: IdentificatoreDati) -> FormatoMappa? {
        guard let scenario = try? scenario(delFronte: fronte),
              let definizione = ambiente.valoriCampagna.mappe[scenario.mappa] else { return nil }
        return ambiente.valoriCampagna.formatiMappa[definizione.formato]
    }

    /// Apre la campagna dell'anno sul fronte scelto: la Sessione del regno fa nascere quella del
    /// fronte nello slot annidato, con le forze del regno e il calendario dell'anno. Restituisce la
    /// campagna, oppure il motivo per cui il regno la rifiuta.
    func apriCampagna(fronte: IdentificatoreDati) async throws
        -> (campagna: PartitaCampagna?, esito: EsitoValidazioneRegno) {
        var generatore = SystemRandomNumberGenerator()
        let aperta = try await sessione.apriCampagna(
            fronte: fronte, scenarioDelFronte: try scenario(delFronte: fronte),
            valori: ambiente.valori, valoriCampagna: ambiente.valoriCampagna,
            versioneTesti: ambiente.testi.versione, cartellaDelRegno: Self.cartellaRegno,
            seme: generatore.next(), identificatore: UUID().uuidString)
        await segnala(aperta.eventi)
        guard let sessioneCampagna = aperta.campagna else { return (nil, aperta.esito) }
        return (PartitaCampagna(delRegno: ambiente, sessione: sessioneCampagna,
                                cartella: Self.cartellaCampagna), aperta.esito)
    }

    /// La campagna che il regno dichiara aperta, ripresa dal proprio slot. Se lo slot è perduto la
    /// campagna rinasce identica, perché le forze del regno non sono cambiate dall'apertura. Nulla
    /// se il regno non ha una campagna aperta.
    func campagnaAperta() async throws -> PartitaCampagna? {
        guard let fronte = await sessione.stato.campagna.fronteAperto else { return nil }
        let cartella = Self.cartellaCampagna
        let sessioneCampagna: SessioneCampagna
        if FileManager.default.fileExists(atPath: cartella.appendingPathComponent("giornale.jsonl").path) {
            sessioneCampagna = try await SessioneCampagna(riprendi: cartella, valori: ambiente.valori,
                                                          valoriCampagna: ambiente.valoriCampagna)
        } else {
            var generatore = SystemRandomNumberGenerator()
            guard let ricreata = try await sessione.ricreaCampagnaAperta(
                scenarioDelFronte: try scenario(delFronte: fronte), valori: ambiente.valori,
                valoriCampagna: ambiente.valoriCampagna, versioneTesti: ambiente.testi.versione,
                cartellaDelRegno: Self.cartellaRegno, seme: generatore.next(),
                identificatore: UUID().uuidString) else { return nil }
            sessioneCampagna = ricreata
        }
        return PartitaCampagna(delRegno: ambiente, sessione: sessioneCampagna, cartella: cartella)
    }

    /// Se la campagna aperta si è conclusa, ne riporta l'esito in patria — lo iscrive nel giornale
    /// del regno — e rimuove lo slot della campagna, che ha esaurito il suo compito. Restituisce
    /// l'esito, oppure nulla se la campagna è ancora in corso. Vale anche alla ripresa: una
    /// campagna conclusa il cui esito non era ancora arrivato in patria lo porta adesso.
    func riportaEsitoSeConclusa(_ campagna: PartitaCampagna) async throws -> EsitoCampagna? {
        let statoCampagna = await campagna.stato
        guard try await sessione.riceviEsito(dalla: statoCampagna) != nil else { return nil }
        try? FileManager.default.removeItem(at: Self.cartellaCampagna)
        return await sessione.stato.campagna.esito
    }

    /// I premi che l'esito aggiunge alla rendita dell'anno: li calcola il Motore (05 §9.4).
    func premi(per esito: EsitoCampagna) -> Riserve { motore.premi(per: esito) }

    /// Il costo di una voce e la stagione in cui sarà pronta, com'è adesso: li calcola il Motore
    /// (05 §9.4). Per le voci che si ordinano su un reparto il costo è quello del reparto indicato.
    func costo(di voce: VoceDelRegno, bersaglio: BersaglioMilitare? = nil, stato: StatoRegno) -> Riserve? {
        motore.costo(di: voce, bersaglio: bersaglio, stato: stato)
    }
    func prontoIn(_ voce: VoceDelRegno, stato: StatoRegno) -> Stagione {
        motore.prontoIn(voce: voce, stato: stato)
    }
    /// I reparti su cui una voce si può ancora ordinare in questo inverno.
    func bersagli(di voce: VoceDelRegno, stato: StatoRegno) -> [BersaglioMilitare] {
        motore.bersagli(di: voce, stato: stato)
    }
}
