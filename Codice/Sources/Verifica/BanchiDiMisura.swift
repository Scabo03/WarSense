import Foundation
import Dati
import Motore

/// I banchi di misura controllati: scambi in condizioni pari, dai quali si leggono
/// il valore di ciascun archetipo, il peso di ciascun modificatore e le curve.
/// Anche qui nessuna regola propria: si costruisce uno stato, si applicano comandi
/// del Motore e si legge il risultato.
public struct BanchiDiMisura: Sendable {

    let motore: MotoreBattaglia
    let banchi: ParametriBanchi

    public init(motore: MotoreBattaglia, banchi: ParametriBanchi) {
        self.motore = motore
        self.banchi = banchi
    }

    var valori: ValoriDiGioco { motore.valori }
    var archetipiOrdinati: [IdentificatoreDati] { valori.archetipi.keys.sorted() }

    // MARK: - Costruzione di un campo controllato

    struct Collocazione {
        let parte: Parte
        let archetipo: IdentificatoreDati
        let protezione: TipoProtezione
        let cella: Cella
    }

    /// Un campo con i reparti dove servono alla misura. I mazzi restano forniti
    /// perché la battaglia non si chiuda per annientamento a metà misura.
    func campo(_ collocazioni: [Collocazione], parteDiTurno: Parte = .giocatore) throws
        -> (StatoBattaglia, [IdSciame]) {
        let riserva = ScenarioBattaglia.ElementoScenario(
            archetipo: archetipiOrdinati[0], protezione: .antiSaturazione,
            atomi: banchi.atomiDiRiferimento, esemplari: 1)
        let scenario = ScenarioBattaglia(
            formato: banchi.formatoDiProva, caratteristica: valori.caratteristiche.keys.sorted()[0],
            primoOccupante: parteDiTurno, imboscata: false,
            deckGiocatore: [riserva], deckAvversario: [riserva])
        var stato = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
        var ids: [IdSciame] = []
        for c in collocazioni {
            let id = IdSciame(stato.prossimoIdSciame)
            stato.prossimoIdSciame += 1
            let lettera = stato.prossimaLettera[c.parte] ?? 1
            stato.prossimaLettera[c.parte] = lettera + 1
            let a = valori.archetipi[c.archetipo]!
            let serbatoio = banchi.atomiDiRiferimento * a.puntiVitaPerAtomo
            stato.sciami[id] = Sciame(id: id, parte: c.parte, archetipo: c.archetipo,
                                      protezione: c.protezione, lettera: lettera,
                                      atomiIniziali: banchi.atomiDiRiferimento, serbatoio: serbatoio,
                                      munizioni: a.dotazioneMunizioni, posizione: c.cella,
                                      azioneSpesa: false, rinforzo: false)
            stato.forzeImpegnate[c.parte, default: 0] += serbatoio
            ids.append(id)
        }
        return (stato, ids)
    }

    /// La cella centrale del banco e i suoi vicini, in ordine deterministico.
    var centro: Cella { Cella(riga: 5, colonna: 5) }
    /// I sei vicini della cella centrale, in ordine fisso.
    var intorno: [Cella] {
        [Cella(riga: 6, colonna: 5), Cella(riga: 6, colonna: 4),
         Cella(riga: 5, colonna: 4), Cella(riga: 5, colonna: 6),
         Cella(riga: 4, colonna: 5), Cella(riga: 4, colonna: 4)]
    }

    /// Un giro di mischia risolto: il danno subito da ciascuno sciame.
    func giroDiMischia(_ stato: StatoBattaglia) -> (StatoBattaglia, [IdSciame: Int64]) {
        var lavoro = stato
        let prima = lavoro.sciami.mapValues { $0.serbatoio }
        for _ in 0..<2 {
            guard lavoro.esito == nil else { break }
            lavoro = motore.applica(.fineTurno, parte: lavoro.parteDiTurno, stato: lavoro).0
        }
        var subiti: [IdSciame: Int64] = [:]
        for (id, consistenza) in prima {
            subiti[id] = consistenza - (lavoro.sciami[id]?.serbatoio ?? 0)
        }
        return (lavoro, subiti)
    }

    // MARK: - 1. Valore di ciascun archetipo contro ciascun altro (duelli)

    public struct Duello: Sendable {
        public let attaccante: IdentificatoreDati
        public let bersaglio: IdentificatoreDati
        public let protezione: TipoProtezione
        public let dannoInflittoPrimoGiro: Int64
        public let dannoSubitoPrimoGiro: Int64
        public let giri: Int
        /// Vero se l'attaccante resta in campo e il bersaglio no.
        public let prevale: Bool
        public let consistenzaResiduaPermille: Int64
        /// Come il primo contatto si è chiuso. La soglia di disingaggio (01 §9.8)
        /// interviene quasi sempre prima della dispersione: il duello misura quindi
        /// il PRIMO scambio, e chi valga di più si legge dal residuo. Al secondo
        /// contatto nessuna soglia opera più (01 §9.8.3).
        public let modoDiFine: String
    }

    /// Uno contro uno in condizioni pari: stessi atomi, stessa protezione ai due,
    /// contatto immediato. Si conta chi resta e in quanti giri.
    public func duelli() throws -> [Duello] {
        var esito: [Duello] = []
        for protezione in TipoProtezione.allCases.sorted(by: { $0.rawValue < $1.rawValue }) {
            for attaccante in archetipiOrdinati {
                for bersaglio in archetipiOrdinati {
                    var (stato, ids) = try campo([
                        Collocazione(parte: .giocatore, archetipo: attaccante,
                                     protezione: protezione, cella: intorno[0]),
                        Collocazione(parte: .avversario, archetipo: bersaglio,
                                     protezione: protezione, cella: centro),
                    ])
                    stato = motore.applica(.ingaggia(sciame: ids[0], bersaglio: ids[1]),
                                           parte: .giocatore, stato: stato).0
                    let inizialeAttaccante = stato.sciami[ids[0]]!.serbatoio
                    var primoInflitto: Int64 = 0
                    var primoSubito: Int64 = 0
                    var giri = 0
                    while stato.sciami[ids[0]] != nil && stato.sciami[ids[1]] != nil
                            && stato.esito == nil && giri < banchi.giriMassimiDuello {
                        let (dopo, subiti) = giroDiMischia(stato)
                        if giri == 0 {
                            primoInflitto = subiti[ids[1]] ?? 0
                            primoSubito = subiti[ids[0]] ?? 0
                        }
                        stato = dopo
                        giri += 1
                        // Un disingaggio interrompe il duello: si registra come tale.
                        if stato.contatti.isEmpty { break }
                    }
                    let attaccanteVivo = stato.sciami[ids[0]] != nil
                    let bersaglioVivo = stato.sciami[ids[1]] != nil
                    let modo: String
                    if !attaccanteVivo || !bersaglioVivo { modo = "disfatta" }
                    else if stato.contatti.isEmpty { modo = "disingaggio" }
                    else { modo = "tetto_dei_giri" }
                    let residuo = attaccanteVivo
                        ? (stato.sciami[ids[0]]!.serbatoio * 1000) / max(1, inizialeAttaccante) : 0
                    esito.append(Duello(attaccante: attaccante, bersaglio: bersaglio,
                                        protezione: protezione,
                                        dannoInflittoPrimoGiro: primoInflitto,
                                        dannoSubitoPrimoGiro: primoSubito,
                                        giri: giri,
                                        prevale: attaccanteVivo && !bersaglioVivo,
                                        consistenzaResiduaPermille: residuo,
                                        modoDiFine: modo))
                }
            }
        }
        return esito
    }

    // MARK: - 2. Curva del tiro per distanza (01 §9.10.1)

    public struct PuntoDellaCurva: Sendable {
        public let archetipo: IdentificatoreDati
        public let distanza: Int
        public let coefficientePermille: Int64
        public let fasciaVicinanza: FasciaVicinanza
        public let danno: Int64
        public let dannoPermilleDelBersaglio: Int64
        public let fasciaPerdite: FasciaPerdite
    }

    /// Per ogni reparto da tiro e ogni distanza della sua gittata: coefficiente,
    /// danno vero prodotto dal comando, e la fascia di perdite che ne risulta sul
    /// bersaglio di riferimento. È la misura su cui si giudica se al limite il tiro
    /// disturbi e da vicino uccida.
    public func curvaDelTiro(protezioneBersaglio: TipoProtezione) throws -> [PuntoDellaCurva] {
        var esito: [PuntoDellaCurva] = []
        for identificatore in archetipiOrdinati {
            let a = valori.archetipi[identificatore]!
            guard a.offesaTiro != nil else { continue }
            for distanza in stride(from: a.gittata, through: 1, by: -1) {
                let (stato, ids) = try campo([
                    Collocazione(parte: .giocatore, archetipo: identificatore,
                                 protezione: .antiSaturazione, cella: Cella(riga: 9, colonna: 5)),
                    Collocazione(parte: .avversario, archetipo: banchi.bersaglioDiRiferimento,
                                 protezione: protezioneBersaglio,
                                 cella: Cella(riga: 9 - distanza, colonna: 5)),
                ])
                let consistenza = stato.sciami[ids[1]]!.serbatoio
                var danno: Int64 = 0
                for evento in motore.applica(.tira(sciame: ids[0], bersaglio: ids[1]),
                                             parte: .giocatore, stato: stato).1 {
                    if case .tiroEseguito(_, _, _, _, _, let inflitto, _, _) = evento { danno = inflitto }
                }
                let gittata = motore.gittataEffettiva(a.gittata, stato: stato)
                esito.append(PuntoDellaCurva(
                    archetipo: identificatore, distanza: distanza,
                    coefficientePermille: motore.coefficienteVicinanza(distanza: distanza,
                                                                       gittata: gittata).grezzo,
                    fasciaVicinanza: motore.fasciaVicinanza(distanza: distanza, gittata: gittata),
                    danno: danno,
                    dannoPermilleDelBersaglio: (danno * 1000) / max(1, consistenza),
                    fasciaPerdite: motore.fascia(danno: danno, consistenzaPrima: consistenza)))
            }
        }
        return esito
    }

    // MARK: - 3. Progressione dell'accerchiamento (01 §9.10.2 e §9.11)

    public struct PassoAccerchiamento: Sendable {
        public let assalitori: Int
        public let coefficientePermille: Int64
        public let inflitto: Int64
        public let subito: Int64
        public let rapportoPermille: Int64
        public let bersaglioCadutoInUnGiro: Bool
        /// Quanto l'ultimo assalitore aggiunto ha pagato: è la misura del costo
        /// dell'ammassamento oltre il secondo (01 §9.11.5).
        public let subitoDallUltimoAggiunto: Int64
    }

    /// Da uno a `assalitoriMassimi` assalitori identici contro un bersaglio identico,
    /// un giro. Con il limite dei bersagli in vigore il subito smette di crescere
    /// dopo il secondo: la misura lo mostra invece di lasciarlo dedurre.
    public func progressioneAccerchiamento() throws -> [PassoAccerchiamento] {
        var esito: [PassoAccerchiamento] = []
        for numero in 1...banchi.assalitoriMassimi {
            var (stato, ids) = try campo(
                (0..<numero).map { Collocazione(parte: .giocatore,
                                                archetipo: banchi.assalitoreDiRiferimento,
                                                protezione: banchi.protezioneDiRiferimento,
                                                cella: intorno[$0]) }
                + [Collocazione(parte: .avversario, archetipo: banchi.bersaglioDiRiferimento,
                                protezione: banchi.protezioneDiRiferimento, cella: centro)])
            let idBersaglio = ids.removeLast()
            for id in ids {
                stato = motore.applica(.ingaggia(sciame: id, bersaglio: idBersaglio),
                                       parte: .giocatore, stato: stato).0
            }
            let (dopo, subiti) = giroDiMischia(stato)
            let inflitto = subiti[idBersaglio] ?? 0
            let subito = ids.reduce(Int64(0)) { $0 + (subiti[$1] ?? 0) }
            esito.append(PassoAccerchiamento(
                assalitori: numero,
                coefficientePermille: motore.coefficienteAccerchiamento(concorrenti: numero).grezzo,
                inflitto: inflitto, subito: subito,
                rapportoPermille: (inflitto * 1000) / max(1, subito),
                bersaglioCadutoInUnGiro: dopo.sciami[idBersaglio] == nil,
                subitoDallUltimoAggiunto: subiti[ids[numero - 1]] ?? 0))
        }
        return esito
    }

    // MARK: - 4. Peso di ciascun modificatore

    public struct PesoModificatore: Sendable {
        public let modificatore: String
        public let condizione: String
        public let coefficientePermille: Int64
        public let dannoDiRiferimento: Int64
    }

    /// Ciascun modificatore isolato, nella stessa configurazione di riferimento:
    /// accoppiamento offesa-protezione, vicinanza agli estremi della gittata,
    /// accerchiamento a ciascun numero di concorrenti, limite dei bersagli a ciascun posto.
    public func pesiDeiModificatori() throws -> [PesoModificatore] {
        var esito: [PesoModificatore] = []
        let riferimento = valori.archetipi[banchi.assalitoreDiRiferimento]!
        let base = riferimento.capacitaOffensivaPerAtomo * banchi.atomiDiRiferimento

        // Accoppiamento: la stessa arma contro le due protezioni.
        for protezione in TipoProtezione.allCases.sorted(by: { $0.rawValue < $1.rawValue }) {
            let efficacia = motore.efficacia(offesa: riferimento.offesaMischia,
                                             protezione: valori.protezioni[protezione]!)
            esito.append(PesoModificatore(modificatore: "accoppiamento",
                                          condizione: protezione.rawValue,
                                          coefficientePermille: efficacia.grezzo,
                                          dannoDiRiferimento: efficacia.applicato(a: base)))
        }
        // Vicinanza: agli estremi e al centro della gittata del reparto da tiro di riferimento.
        for identificatore in archetipiOrdinati {
            let a = valori.archetipi[identificatore]!
            guard a.offesaTiro != nil else { continue }
            for distanza in [a.gittata, max(1, (a.gittata + 1) / 2), 1] {
                let coefficiente = motore.coefficienteVicinanza(distanza: distanza, gittata: a.gittata)
                esito.append(PesoModificatore(
                    modificatore: "vicinanza",
                    condizione: identificatore + "@" + String(distanza),
                    coefficientePermille: coefficiente.grezzo,
                    dannoDiRiferimento: coefficiente.applicato(
                        a: a.capacitaOffensivaPerAtomo * banchi.atomiDiRiferimento)))
            }
            break // un solo reparto da tiro basta a mostrare la forma della curva
        }
        // Accerchiamento: a ciascun numero di concorrenti fino al tetto dei dati.
        for numero in 1...(valori.combattimento.concorrentiMassimi + 1) {
            let coefficiente = motore.coefficienteAccerchiamento(concorrenti: numero)
            esito.append(PesoModificatore(modificatore: "accerchiamento",
                                          condizione: String(numero),
                                          coefficientePermille: coefficiente.grezzo,
                                          dannoDiRiferimento: coefficiente.applicato(a: base)))
        }
        // Limite dei bersagli: la resa di risposta a ciascun posto. Il terzo posto
        // non ha coefficiente perché non c'è risposta: si registra a zero.
        for posto in 0...2 {
            let resa = motore.resaDiRisposta(posto: posto)
            esito.append(PesoModificatore(modificatore: "limite_bersagli",
                                          condizione: String(posto),
                                          coefficientePermille: resa?.grezzo ?? 0,
                                          dannoDiRiferimento: resa?.applicato(a: base) ?? 0))
        }
        return esito
    }

    // MARK: - 5. Redditività delle composizioni (asimmetria dei mazzi)

    public struct RedditivitaComposizione: Sendable {
        public let scenario: IdentificatoreDati
        public let parte: Parte
        /// Efficacia massima che i reparti da tiro di questa parte ottengono
        /// contro un elemento dello schieramento avverso.
        public let efficaciaMassimaPermille: Int64
        public let efficaciaMediaPermille: Int64
        /// Quanti elementi avversari il tiro di questa parte batte da efficace.
        public let elementiEfficaci: Int
        public let elementiTotali: Int
    }

    /// Quanto rende il tiro di ciascuna parte contro lo schieramento avverso.
    /// È la misura dell'asimmetria delle composizioni: se una parte dispone in
    /// partenza di bersagli molto più redditizi dell'altra, si vede qui.
    public func redditivita(di scenario: ScenarioDiVerifica) -> [RedditivitaComposizione] {
        func misura(parte: Parte, propri: [ScenarioBattaglia.ElementoScenario],
                    avversi: [ScenarioBattaglia.ElementoScenario]) -> RedditivitaComposizione {
            var rese: [Int64] = []
            var efficaci = 0
            for elemento in propri {
                guard let offesa = valori.archetipi[elemento.archetipo]?.offesaTiro else { continue }
                for bersaglio in avversi {
                    let protezione = valori.protezioni[bersaglio.protezione]!
                    let efficacia = motore.efficacia(offesa: offesa, protezione: protezione)
                    rese.append(efficacia.grezzo)
                    if motore.efficaciaQualitativa(offesa: offesa, protezione: protezione) == .efficace {
                        efficaci += 1
                    }
                }
            }
            let media = rese.isEmpty ? 0 : rese.reduce(0, +) / Int64(rese.count)
            return RedditivitaComposizione(scenario: scenario.identificatore, parte: parte,
                                           efficaciaMassimaPermille: rese.max() ?? 0,
                                           efficaciaMediaPermille: media,
                                           elementiEfficaci: efficaci, elementiTotali: rese.count)
        }
        return [misura(parte: .giocatore, propri: scenario.deckGiocatore, avversi: scenario.deckAvversario),
                misura(parte: .avversario, propri: scenario.deckAvversario, avversi: scenario.deckGiocatore)]
    }

    public struct BersaglioDiSchieramento: Sendable {
        public let scenario: IdentificatoreDati
        /// La parte cui il reparto appartiene, cioè quella che lo SUBISCE come bersaglio.
        public let parte: Parte
        public let archetipo: IdentificatoreDati
        public let protezione: TipoProtezione
        /// La resa migliore che il tiro avverso ottiene contro questo reparto.
        public let efficaciaDelTiroAvversoPermille: Int64
        public let efficace: Bool
        /// I punti vita che questo elemento porta nello schieramento: dice quanto
        /// pesa il bersaglio, non solo quanto è redditizio colpirlo.
        public let puntiVita: Int64
    }

    /// Per ciascun elemento di ciascuno schieramento, quanto rende battere PROPRIO
    /// QUELLO con il tiro avverso. È la misura fine dell'asimmetria delle
    /// composizioni: la media può coincidere mentre l'una parte espone il proprio
    /// reparto più pesante e l'altra il più leggero, che non è la stessa cosa.
    public func bersagliDiSchieramento(di scenario: ScenarioDiVerifica) -> [BersaglioDiSchieramento] {
        func offeseDaTiro(_ elementi: [ScenarioBattaglia.ElementoScenario]) -> [ProfiloOffesa] {
            elementi.compactMap { valori.archetipi[$0.archetipo]?.offesaTiro }
        }
        func misura(parte: Parte, propri: [ScenarioBattaglia.ElementoScenario],
                    offeseAvverse: [ProfiloOffesa]) -> [BersaglioDiSchieramento] {
            propri.map { elemento in
                let protezione = valori.protezioni[elemento.protezione]!
                var migliore = Scalato.zero
                var efficace = false
                for offesa in offeseAvverse {
                    let resa = motore.efficacia(offesa: offesa, protezione: protezione)
                    if resa > migliore { migliore = resa }
                    if motore.efficaciaQualitativa(offesa: offesa, protezione: protezione) == .efficace {
                        efficace = true
                    }
                }
                let perAtomo = valori.archetipi[elemento.archetipo]?.puntiVitaPerAtomo ?? 0
                return BersaglioDiSchieramento(
                    scenario: scenario.identificatore, parte: parte,
                    archetipo: elemento.archetipo, protezione: elemento.protezione,
                    efficaciaDelTiroAvversoPermille: migliore.grezzo, efficace: efficace,
                    puntiVita: perAtomo * elemento.atomi * Int64(elemento.esemplari))
            }
        }
        return misura(parte: .giocatore, propri: scenario.deckGiocatore,
                      offeseAvverse: offeseDaTiro(scenario.deckAvversario))
            + misura(parte: .avversario, propri: scenario.deckAvversario,
                     offeseAvverse: offeseDaTiro(scenario.deckGiocatore))
    }

    // MARK: - 6. Soglia di resa del tattico (03 §6.1, §6.5)

    public struct SogliaDiResa: Sendable {
        public let ufficiale: IdentificatoreDati
        public let parte: Parte
        public let vantaggiAccesi: Bool
        public let sogliaPermille: Int64
        /// Vera se la soglia è raggiungibile: oltre l'unità richiederebbe più
        /// perdite di quante siano le forze impiegate, quindi la resa non avviene mai.
        public let raggiungibile: Bool
    }

    /// La soglia oltre la quale il tattico dichiara la resa, per ufficiale e per parte.
    /// La formula è del Motore; qui si legge soltanto (01 §12.1, RDA-46).
    public func soglieDiResa(vantaggiAccesi: Bool) -> [SogliaDiResa] {
        var esito: [SogliaDiResa] = []
        for identificatore in valori.ufficiali.keys.sorted() {
            let ufficiale = valori.ufficiali[identificatore]!
            for parte in Parte.allCases {
                let tattico = TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: parte)
                let soglia = tattico.sogliaDiResa
                esito.append(SogliaDiResa(ufficiale: identificatore, parte: parte,
                                          vantaggiAccesi: vantaggiAccesi,
                                          sogliaPermille: soglia.grezzo,
                                          raggiungibile: soglia < .uno))
            }
        }
        return esito
    }
}
