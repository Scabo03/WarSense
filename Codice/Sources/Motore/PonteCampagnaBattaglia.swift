import Foundation
import Dati

/// IL PONTE FRA I DUE PIANI (01 §6, §15, incarico 24): le due traduzioni pure con cui una
/// battaglia nasce da una campagna e vi ritorna. Sta nel Motore — non nella Presentazione —
/// perché è REGOLA e non interfaccia, e perché la deve condividere il programma di verifica,
/// che gioca le stesse battaglie che gioca il giocatore. Non introduce alcuna estrazione del
/// caso (01 §12): entrambe le traduzioni sono funzioni dei soli dati e dello stato.
///
/// L'andata (`scenario`) costruisce lo `ScenarioBattaglia` dai due gruppi di campagna: il deck
/// di ciascuna parte è la sua composizione — un elemento per reparto (01 §8.3) — chi occupava
/// per primo agisce per primo (01 §9.4.1), e se la battaglia nasce da un'imboscata lo scenario
/// porta `imboscata: true`, da cui la fabbrica di battaglia accende il vantaggio della sorpresa
/// (01 §9.3.2, `FabbricaBattaglia`). Il ritorno (`esito`) raccoglie i superstiti — sciami in
/// campo e riserve non scese — in una composizione per archetipo (01 §15.7, §4.11), decide le
/// caselle del ritorno (01 §15.5, §10.6) e dichiara annientato chi non ha più nulla (01 §15.2.3).
public enum PonteCampagnaBattaglia {

    /// Il modello dello scontro che la campagna non dichiara e che la Presentazione fornisce: il
    /// formato del campo, il terreno, la protezione con cui i reparti scendono, la fase e
    /// l'ufficiale avversario. Sono PROVVISORI (S24e): la campagna non porta questi dati, e finché
    /// non li porterà valgono i valori di un campo aperto standard. Non è taratura del combattimento
    /// — che il titolare ha accettato — ma la cornice minima entro cui i gruppi si affrontano.
    public struct Modello: Hashable, Sendable {
        public let formato: IdentificatoreDati
        public let caratteristica: IdentificatoreDati
        public let protezione: TipoProtezione
        public let fase: Fase?
        public let ufficialeAvversario: IdentificatoreDati?
        public init(formato: IdentificatoreDati, caratteristica: IdentificatoreDati,
                    protezione: TipoProtezione, fase: Fase? = nil,
                    ufficialeAvversario: IdentificatoreDati? = nil) {
            self.formato = formato; self.caratteristica = caratteristica
            self.protezione = protezione; self.fase = fase
            self.ufficialeAvversario = ufficialeAvversario
        }
    }

    // MARK: - Andata: campagna → battaglia (01 §6.2, §8.3, §9.3.2, §9.4.1)

    /// Costruisce lo scenario di battaglia dai due gruppi in contatto. Il deck di ciascuna parte
    /// è la sua composizione: un elemento per reparto, un esemplare ciascuno (01 §8.3). La
    /// protezione è quella del modello (la campagna non la porta, S24e). `primoOccupante` e
    /// `imboscata` vengono dalla battaglia in sospeso.
    public static func scenario(da battaglia: BattagliaInSospeso, stato: StatoCampagna,
                                modello: Modello) -> ScenarioBattaglia {
        func deck(_ id: IdGruppo) -> [ScenarioBattaglia.ElementoScenario] {
            (stato.gruppi[id]?.composizione ?? []).map { reparto in
                ScenarioBattaglia.ElementoScenario(archetipo: reparto.archetipo,
                                                   protezione: modello.protezione,
                                                   atomi: Int64(reparto.atomi), esemplari: 1)
            }
        }
        return ScenarioBattaglia(
            formato: modello.formato, caratteristica: modello.caratteristica, ostacoli: [],
            primoOccupante: battaglia.primoOccupante, imboscata: battaglia.daImboscata,
            deckGiocatore: deck(battaglia.gruppoGiocatore),
            deckAvversario: deck(battaglia.gruppoAvversario),
            ufficialeAvversario: modello.ufficialeAvversario, fase: modello.fase)
    }

    // MARK: - Ritorno: battaglia → campagna (01 §15)

    /// Deriva l'esito da riportare in campagna da una battaglia CONCLUSA. Precondizione: lo stato
    /// porta un esito (`stato.esito != nil`). I superstiti di ciascuna parte — sciami in campo
    /// (atomi presenti) e riserve non scese nel deck — si raggruppano per archetipo (01 §15.7,
    /// §4.11); una parte senza superstiti è annientata (composizione vuota). Le caselle: il
    /// vincitore resta nella contesa (01 §15.5), lo sconfitto ripiega verso casa (01 §10.6),
    /// l'annientato non ne ha.
    public static func esito(da battaglia: StatoBattaglia, per inSospeso: BattagliaInSospeso,
                             stato: StatoCampagna, valori: ValoriDiGioco) -> EsitoInCampagna {
        guard let esito = battaglia.esito else {
            preconditionFailure("ponte.esito.su.battaglia.non.conclusa")
        }
        func composizione(di parte: Parte) -> [Reparto] {
            var perArchetipo: [IdentificatoreDati: Int] = [:]
            for sciame in battaglia.sciami.values where sciame.parte == parte {
                let pv = valori.archetipi[sciame.archetipo]?.puntiVitaPerAtomo ?? 1
                let atomi = sciame.atomiPresenti(puntiVitaPerAtomo: pv,
                                                 minimo: valori.minimi.atomiMinimiSciameVivo)
                perArchetipo[sciame.archetipo, default: 0] += Int(atomi)
            }
            for elemento in battaglia.deck[parte] ?? [] where elemento.esemplari > 0 {
                perArchetipo[elemento.archetipo, default: 0] += Int(elemento.atomi) * elemento.esemplari
            }
            return perArchetipo.keys.sorted().compactMap { archetipo in
                let atomi = perArchetipo[archetipo]!
                return atomi > 0 ? Reparto(archetipo: archetipo, atomi: atomi) : nil
            }
        }
        let compGiocatore = composizione(di: .giocatore)
        let compAvversario = composizione(di: .avversario)
        let vincitore = esito.sconfitto.avversaria
        func posizione(di parte: Parte, composizione: [Reparto]) -> Cella? {
            if composizione.isEmpty { return nil }                 // annientato: sparisce (01 §15.2.3)
            if parte == vincitore { return inSospeso.casella }     // il vincitore resta (01 §15.5, S24b)
            return casellaArretrata(per: parte, da: inSospeso.casella, stato: stato)
                ?? inSospeso.casella                               // ripiega verso casa (01 §10.6)
        }
        return EsitoInCampagna(
            identificatore: inSospeso.identificatore, casella: inSospeso.casella,
            sconfitto: esito.sconfitto, modo: esito.modo,
            gruppoGiocatore: inSospeso.gruppoGiocatore, gruppoAvversario: inSospeso.gruppoAvversario,
            composizioneGiocatore: compGiocatore, composizioneAvversario: compAvversario,
            posizioneGiocatore: posizione(di: .giocatore, composizione: compGiocatore),
            posizioneAvversario: posizione(di: .avversario, composizione: compAvversario))
    }

    /// La casella dove ripiega lo sconfitto (01 §10.6): il vicino più vicino al proprio quartier
    /// generale, libero da un proprio gruppo, in ordine deterministico (est, ovest, nord, sud). È
    /// «arretrata rispetto alla direzione di provenienza» reso come «verso casa»: la mappa non
    /// tiene la provenienza, ma il verso del quartier generale è la sua approssimazione fedele
    /// (S24). Una ritirata non può risolversi in un avanzamento: si guarda solo ai vicini più
    /// vicini a casa. Nil se non ve n'è alcuno libero (al proprio margine): il caso degenere lo
    /// gestisce il chiamante lasciando lo sconfitto nella casella (raro; dichiarato).
    public static func casellaArretrata(per parte: Parte, da casella: Cella,
                                        stato: StatoCampagna) -> Cella? {
        let qg = stato.mappa.quartierGenerale(di: parte)
        let distanzaAttuale = stato.griglia.distanza(casella, qg)
        for vicino in stato.griglia.vicini(di: casella)
        where stato.griglia.distanza(vicino, qg) < distanzaAttuale
            && stato.occupante(di: vicino, parte: parte) == nil {
            return vicino
        }
        return nil
    }
}
