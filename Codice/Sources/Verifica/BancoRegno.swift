import Foundation
import Dati
import Motore

/// La SONDA degli invarianti del regno (incarico 30): guarda lo stato del regno prima e dopo ogni
/// passo e riferisce ciò che non deve mai accadere. Come la sonda della campagna, non rifà i calcoli
/// del Motore con il suo stesso codice dove può evitarlo: confronta grandezze che il Motore non
/// conosce insieme — il saldo prima e dopo, le forze prima e dopo — e le regole scritte nei documenti.
public struct SondaInvariantiRegno: Sendable {

    public enum Violazione: Hashable, Sendable {
        /// Una risorsa è scesa sotto zero: si è speso ciò che non si aveva.
        case saldoNegativo(Risorsa)
        /// Dopo una spesa il saldo non è quello di prima meno il costo dichiarato (02 §8.7).
        case spesaNonConservata(Risorsa)
        /// All'arrivo dell'inverno il saldo non è quello di prima più l'entrata dichiarata.
        case entrataNonConservata(Risorsa)
        /// In primavera è avanzato più della quota dell'entrata dell'anno (01 §5.5.1.4).
        case riportoOltreLaQuota(Risorsa)
        /// In primavera una risorsa è cresciuta: il riporto può soltanto togliere.
        case riportoCheAggiunge(Risorsa)
        /// L'anno non è avanzato di uno in primavera, o è cambiato fuori dalla primavera.
        case annoFuoriPasso
        /// La stazione invernale è fuori dalle quattro, o è avanzata di più di una (01 §5.9.1.1).
        case stazioneFuoriPasso
        /// Le forze sono cambiate fuori dai due soli momenti in cui possono: il rientro da una
        /// campagna e la primavera (01 §4.12: il reintegro avviene soltanto in patria).
        case forzeCambiateFuoriTempo
        /// Dal fronte è rientrato più di quanto era partito: non esiste reintegro sul campo (01 §4.12).
        case rientroMaggioreDellaPartenza
        /// In primavera le unità non sono quelle di prima più una formazione di reclute, quando un
        /// lavoro era ordinato, o sono cambiate senza lavori.
        case recluteNonArrivate
        /// Un lavoro ordinato è sparito senza la primavera, o è sopravvissuto alla primavera.
        case lavoriFuoriTempo
        /// L'esito di una campagna si contraddice: un vincitore con l'inverno, nessun vincitore con
        /// l'annientamento, giornate fuori dal calendario (RDA-164).
        case esitoIncoerente
        /// La campagna dell'anno ha cambiato stato per una via che non esiste: da conclusa ad aperta,
        /// o aperta d'inverno.
        case campagnaFuoriPasso
    }

    public init() {}

    /// Il codice stabile di una violazione, senza i valori (05 §12.6).
    public static func codice(di violazione: Violazione) -> String {
        switch violazione {
        case .saldoNegativo: return "saldo_negativo"
        case .spesaNonConservata: return "spesa_non_conservata"
        case .entrataNonConservata: return "entrata_non_conservata"
        case .riportoOltreLaQuota: return "riporto_oltre_la_quota"
        case .riportoCheAggiunge: return "riporto_che_aggiunge"
        case .annoFuoriPasso: return "anno_fuori_passo"
        case .stazioneFuoriPasso: return "stazione_fuori_passo"
        case .forzeCambiateFuoriTempo: return "forze_cambiate_fuori_tempo"
        case .rientroMaggioreDellaPartenza: return "rientro_maggiore_della_partenza"
        case .recluteNonArrivate: return "reclute_non_arrivate"
        case .lavoriFuoriTempo: return "lavori_fuori_tempo"
        case .esitoIncoerente: return "esito_incoerente"
        case .campagnaFuoriPasso: return "campagna_fuori_passo"
        }
    }

    /// Che cosa è accaduto fra i due stati: la sonda non lo deduce, glielo dice chi ha fatto il passo.
    public enum Passo: Sendable {
        case aperturaDellaCampagna
        case rientroDallaCampagna(EsitoCampagna)
        /// L'arrivo dell'inverno, con l'entrata che l'evento dichiara.
        case arrivoDellInverno(entrata: Riserve)
        /// Una spesa, con il costo che l'evento dichiara.
        case spesa(costo: Riserve)
        case stazioneSuccessiva
        /// La primavera, con la quota di riporto e l'entrata dell'anno che vale per il tetto.
        case primavera(quotaRiporto: Scalato, entrata: Riserve)
    }

    /// Quanti atomi contano le forze: la misura con cui si confronta partenza e rientro. Qui, e non
    /// nel regno comune, perché è della modalità a sciami.
    static func atomi(_ forze: ForzeDelRegno) -> Int {
        forze.formazioni.reduce(0) { $0 + $1.atomiTotali }
    }

    public func controlla(prima: StatoRegno, dopo: StatoRegno, passo: Passo,
                          giornateOperative: Int) -> [Violazione] {
        var v: [Violazione] = []
        for risorsa in Risorsa.allCases where dopo.riserve[risorsa] < 0 { v.append(.saldoNegativo(risorsa)) }
        if let stazione = dopo.momento.stazione,
           !(1...MomentoDellAnno.stazioniInvernali).contains(stazione) { v.append(.stazioneFuoriPasso) }

        switch passo {
        case .aperturaDellaCampagna:
            if dopo.anno != prima.anno { v.append(.annoFuoriPasso) }
            if prima.campagna != .nonAperta || dopo.campagna.fronteAperto == nil || dopo.momento.eInverno {
                v.append(.campagnaFuoriPasso)
            }
            if dopo.forze != prima.forze { v.append(.forzeCambiateFuoriTempo) }
            if dopo.riserve != prima.riserve { v.append(contentsOf: Risorsa.allCases
                .filter { dopo.riserve[$0] != prima.riserve[$0] }.map { .spesaNonConservata($0) }) }

        case .rientroDallaCampagna(let esito):
            if dopo.anno != prima.anno { v.append(.annoFuoriPasso) }
            if prima.campagna.fronteAperto != esito.fronte || dopo.campagna.esito != esito {
                v.append(.campagnaFuoriPasso)
            }
            if Self.atomi(dopo.forze) > Self.atomi(prima.forze) { v.append(.rientroMaggioreDellaPartenza) }
            if dopo.forze != esito.superstiti { v.append(.forzeCambiateFuoriTempo) }
            switch esito.modo {
            case .inverno:
                if esito.vincitore != nil || esito.giornate != giornateOperative { v.append(.esitoIncoerente) }
            case .annientamento:
                if esito.vincitore == nil || !(1...giornateOperative).contains(esito.giornate) {
                    v.append(.esitoIncoerente)
                }
            }

        case .arrivoDellInverno(let entrata):
            if dopo.anno != prima.anno { v.append(.annoFuoriPasso) }
            if prima.momento.eInverno || dopo.momento.stazione != 1 { v.append(.stazioneFuoriPasso) }
            if prima.campagna.fronteAperto != nil || dopo.campagna != prima.campagna { v.append(.campagnaFuoriPasso) }
            if dopo.forze != prima.forze { v.append(.forzeCambiateFuoriTempo) }
            for risorsa in Risorsa.allCases where dopo.riserve[risorsa] != prima.riserve[risorsa] + entrata[risorsa] {
                v.append(.entrataNonConservata(risorsa))
            }

        case .spesa(let costo):
            if dopo.anno != prima.anno { v.append(.annoFuoriPasso) }
            if dopo.momento != prima.momento { v.append(.stazioneFuoriPasso) }
            if dopo.forze != prima.forze { v.append(.forzeCambiateFuoriTempo) }
            if dopo.lavori.count != prima.lavori.count + 1 { v.append(.lavoriFuoriTempo) }
            for risorsa in Risorsa.allCases where dopo.riserve[risorsa] != prima.riserve[risorsa] - costo[risorsa] {
                v.append(.spesaNonConservata(risorsa))
            }

        case .stazioneSuccessiva:
            if dopo.anno != prima.anno { v.append(.annoFuoriPasso) }
            if let p = prima.momento.stazione, dopo.momento.stazione != p + 1 { v.append(.stazioneFuoriPasso) }
            if dopo.forze != prima.forze { v.append(.forzeCambiateFuoriTempo) }
            if dopo.lavori != prima.lavori { v.append(.lavoriFuoriTempo) }
            if dopo.riserve != prima.riserve { v.append(contentsOf: Risorsa.allCases
                .filter { dopo.riserve[$0] != prima.riserve[$0] }.map { .spesaNonConservata($0) }) }

        case .primavera(let quotaRiporto, let entrata):
            if dopo.anno != prima.anno + 1 { v.append(.annoFuoriPasso) }
            if prima.momento.stazione != MomentoDellAnno.stazioniInvernali || dopo.momento.eInverno {
                v.append(.stazioneFuoriPasso)
            }
            if dopo.campagna != .nonAperta { v.append(.campagnaFuoriPasso) }
            if !dopo.lavori.isEmpty { v.append(.lavoriFuoriTempo) }
            for risorsa in Risorsa.allCases {
                // La quota dell'entrata, ricalcolata qui con la sola aritmetica dei documenti:
                // troncamento per difetto (00 §13.5).
                let tetto = Int(quotaRiporto.applicato(a: Int64(entrata[risorsa])))
                if dopo.riserve[risorsa] > tetto { v.append(.riportoOltreLaQuota(risorsa)) }
                if dopo.riserve[risorsa] > prima.riserve[risorsa] { v.append(.riportoCheAggiunge(risorsa)) }
            }
            // Le reclute: una formazione in più se un lavoro era ordinato, nessuna altrimenti; e gli
            // atomi di prima più quelli che i lavori dichiaravano.
            let attese = prima.forze.numeroDiUnita + (prima.lavori.isEmpty ? 0 : 1)
            let atomiAttesi = Self.atomi(prima.forze) + prima.lavori.reduce(0) { $0 + $1.effetto.misura }
            if dopo.forze.numeroDiUnita != attese || Self.atomi(dopo.forze) != atomiAttesi {
                v.append(.recluteNonArrivate)
            }
        }
        return v
    }
}

/// Il BANCO DEL REGNO (incarico 30): anni interi giocati senza interfaccia, per misurare e per
/// sorvegliare. Ogni anno apre la campagna su un fronte, la gioca fino alla sua conclusione con lo
/// strumento della frequenza delle battaglie — le stesse due condotte del giocatore, lo stesso
/// avversario, le stesse battaglie al banco —, ne porta l'esito in patria, passa l'inverno ordinando
/// leve e arriva alla primavera. A ogni passo interroga la sonda degli invarianti del regno, e a ogni
/// passo della campagna quella della campagna.
///
/// Non contiene regole: ogni esito viene dai due Motori. Ciò che aggiunge è la condotta del
/// giocatore in patria, la più semplice che spenda: ordina le voci a turno finché ne resta una che
/// si può pagare, poi prosegue fino alla primavera.
public struct BancoRegno: Sendable {

    /// Un anno giocato: la riga dei dati grezzi.
    public struct Anno: Sendable, Codable {
        public let seme: UInt64
        public let condotta: MisuraFrequenzaBattaglie.Condotta
        public let anno: Int
        public let fronte: String
        /// «annientamento», «inverno», oppure «ferma» se la campagna non si è conclusa al banco.
        public let conclusione: String
        public let vincitore: String?
        public let giornate: Int
        public let battaglie: Int
        public let vinte: Int
        public let perse: Int
        public let atomiPartiti: Int
        public let atomiRientrati: Int
        public let formazioniPartite: Int
        public let formazioniRientrate: Int
        public let entrata: [String: Int]
        public let leveOrdinate: Int
        public let atomiReclutati: Int
        public let riportato: [String: Int]
        public let violazioni: [String]
        public let motivoFerma: String?
        /// Le proposte della condotta avversaria che il Motore ha respinto durante la campagna
        /// dell'anno, e la prima (`MisuraFrequenzaBattaglie.Partita`).
        public let proposteAvversarieRespinte: Int
        public let primaPropostaRespinta: String?
        enum CodingKeys: String, CodingKey {
            case seme, condotta, anno, fronte, conclusione, vincitore, giornate, battaglie, vinte, perse
            case atomiPartiti = "atomi_partiti"
            case atomiRientrati = "atomi_rientrati"
            case formazioniPartite = "formazioni_partite"
            case formazioniRientrate = "formazioni_rientrate"
            case entrata
            case leveOrdinate = "leve_ordinate"
            case atomiReclutati = "atomi_reclutati"
            case riportato, violazioni
            case motivoFerma = "motivo_ferma"
            case proposteAvversarieRespinte = "proposte_avversarie_respinte"
            case primaPropostaRespinta = "prima_proposta_respinta"
        }
    }

    let motoreRegno: MotoreRegno
    let misura: MisuraFrequenzaBattaglie
    let valoriCampagna: ValoriCampagna
    let scenari: [String: ScenarioCampagna]
    let sonda = SondaInvariantiRegno()

    public init(valoriRegno: ValoriRegno, motoreCampagna: MotoreCampagna, valoriCampagna: ValoriCampagna,
                scenari: [String: ScenarioCampagna]) {
        motoreRegno = MotoreRegno(valori: valoriRegno)
        misura = MisuraFrequenzaBattaglie(motore: motoreCampagna, valoriCampagna: valoriCampagna)
        self.valoriCampagna = valoriCampagna
        self.scenari = scenari
    }

    public enum Errore: Error, Equatable {
        case fronteSenzaScenario(String)
    }

    private func mappa(_ riserve: Riserve) -> [String: Int] {
        var m: [String: Int] = [:]
        for risorsa in Risorsa.allCases { m[risorsa.rawValue] = riserve[risorsa] }
        return m
    }

    /// Gioca `anni` anni dallo stato iniziale. Il fronte dell'anno ruota con il seme, sicché ogni
    /// partita li percorre tutti. Si ferma prima se una campagna non si conclude al banco, oppure se
    /// il regno resta senza forze e senza di che reclutarne.
    public func gioca(anni: Int, condotta: MisuraFrequenzaBattaglie.Condotta, seme: UInt64) throws -> [Anno] {
        var stato = try motoreRegno.statoIniziale()
        let giornateOperative = motoreRegno.valori.giornateOperative
        var giocati: [Anno] = []
        for _ in 0..<anni {
            var violazioni = Set<String>()
            func sorveglia(_ prima: StatoRegno, _ passo: SondaInvariantiRegno.Passo) {
                violazioni.formUnion(sonda.controlla(prima: prima, dopo: stato, passo: passo,
                                                     giornateOperative: giornateOperative)
                    .map(SondaInvariantiRegno.codice(di:)))
            }
            func applica(_ comando: ComandoRegno) -> [EventoRegno] {
                let (nuovo, eventi) = motoreRegno.applica(comando, stato: stato)
                stato = nuovo
                return eventi
            }

            // 1. La campagna dell'anno, se il regno ha di che condurla.
            let fronti = motoreRegno.valori.fronti
            let fronte = fronti[(stato.anno - 1 + Int(seme % UInt64(fronti.count))) % fronti.count]
            let atomiPartiti = SondaInvariantiRegno.atomi(stato.forze)
            let formazioniPartite = stato.forze.numeroDiUnita
            var esitoCampagna: EsitoCampagna?
            var conclusione = "nessuna"
            var battaglie = 0, vinte = 0, perse = 0, giornate = 0
            var respinte = 0, primaRespinta: String?
            if motoreRegno.valida(.apriCampagna(fronte: fronte.identificatore), stato: stato).eValido {
                guard let base = scenari[fronte.scenario] else { throw Errore.fronteSenzaScenario(fronte.scenario) }
                var prima = stato
                _ = applica(.apriCampagna(fronte: fronte.identificatore))
                sorveglia(prima, .aperturaDellaCampagna)
                let scenario = try PonteRegnoCampagna.scenario(
                    delFronte: base, forze: stato.forze,
                    calendario: CalendarioDiCampagna(anno: stato.anno,
                                                     giornatePerStagione: motoreRegno.valori.giornatePerStagione),
                    valori: valoriCampagna)
                let (partita, statoCampagna) = try misura.giocaConStato(
                    scenario: scenario, formato: fronte.identificatore, condotta: condotta,
                    seme: seme &+ UInt64(stato.anno) &* 1_000_003, limiteGiornate: giornateOperative + 1)
                violazioni.formUnion(partita.violazioni)
                battaglie = partita.battaglie; vinte = partita.vinte; perse = partita.perse
                giornate = partita.giornate
                respinte = partita.proposteAvversarieRespinte ?? 0
                primaRespinta = partita.primaPropostaRespinta
                guard let esito = PonteRegnoCampagna.esito(da: statoCampagna, fronte: fronte.identificatore) else {
                    // La campagna non si è conclusa al banco (una battaglia oltre i tetti: difetto noto
                    // dell'incarico 29): l'anno si registra fermo e la partita finisce qui.
                    giocati.append(Anno(
                        seme: seme, condotta: condotta, anno: stato.anno, fronte: fronte.identificatore,
                        conclusione: "ferma", vincitore: nil, giornate: giornate, battaglie: battaglie,
                        vinte: vinte, perse: perse, atomiPartiti: atomiPartiti, atomiRientrati: 0,
                        formazioniPartite: formazioniPartite, formazioniRientrate: 0, entrata: [:],
                        leveOrdinate: 0, atomiReclutati: 0, riportato: [:], violazioni: violazioni.sorted(),
                        motivoFerma: partita.motivoFerma ?? partita.fine.rawValue,
                        proposteAvversarieRespinte: respinte, primaPropostaRespinta: primaRespinta))
                    return giocati
                }
                prima = stato
                _ = motoreRegno.applicaEsito(esito, in: &stato)
                sorveglia(prima, .rientroDallaCampagna(esito))
                esitoCampagna = esito
                conclusione = esito.modo.rawValue
                giornate = esito.giornate
            }
            let atomiRientrati = SondaInvariantiRegno.atomi(stato.forze)
            let formazioniRientrate = stato.forze.numeroDiUnita

            // 2. L'inverno: l'entrata, le leve a turno finché se ne può pagare una, le quattro stazioni.
            var prima = stato
            var entrata = Riserve()
            for evento in applica(.attendiInverno) {
                if case .invernoCominciato(_, let e) = evento { entrata = e }
            }
            sorveglia(prima, .arrivoDellInverno(entrata: entrata))
            var leve = 0, atomiReclutati = 0
            var indice = 0, rifiutiDiFila = 0
            let voci = motoreRegno.valori.voci
            while rifiutiDiFila < voci.count {
                let voce = voci[indice % voci.count]
                indice += 1
                guard motoreRegno.valida(.ordina(voce: voce.identificatore), stato: stato).eValido else {
                    rifiutiDiFila += 1
                    continue
                }
                rifiutiDiFila = 0
                prima = stato
                var costo = Riserve()
                for evento in applica(.ordina(voce: voce.identificatore)) {
                    if case .lavoroOrdinato(_, let c, _) = evento { costo = c }
                }
                sorveglia(prima, .spesa(costo: costo))
                leve += 1
                atomiReclutati += voce.effetto.misura
            }
            for _ in 1..<MomentoDellAnno.stazioniInvernali {
                prima = stato
                _ = applica(.prosegui)
                sorveglia(prima, .stazioneSuccessiva)
            }
            prima = stato
            _ = applica(.prosegui)
            sorveglia(prima, .primavera(quotaRiporto: motoreRegno.valori.quotaRiporto, entrata: entrata))

            giocati.append(Anno(
                seme: seme, condotta: condotta, anno: stato.anno - 1, fronte: fronte.identificatore,
                conclusione: conclusione, vincitore: esitoCampagna?.vincitore?.rawValue, giornate: giornate,
                battaglie: battaglie, vinte: vinte, perse: perse, atomiPartiti: atomiPartiti,
                atomiRientrati: atomiRientrati, formazioniPartite: formazioniPartite,
                formazioniRientrate: formazioniRientrate, entrata: mappa(entrata), leveOrdinate: leve,
                atomiReclutati: atomiReclutati, riportato: mappa(stato.riserve),
                violazioni: violazioni.sorted(), motivoFerma: nil,
                proposteAvversarieRespinte: respinte, primaPropostaRespinta: primaRespinta))
        }
        return giocati
    }
}

/// Il banco del regno come lo esegue lo strumento da riga di comando: `partite` partite di `anni`
/// anni per ciascuna condotta del giocatore (semi da 0 a `partite` − 1), in parallelo, con i dati
/// grezzi — una riga JSON per anno — e il riepilogo per condotta e per fronte.
public enum BancoRegnoDaRigaDiComando {
    public struct Rapporto: Sendable {
        public let grezzi: String
        public let testo: String
        public let anni: [BancoRegno.Anno]
    }

    final class Raccolta: @unchecked Sendable {
        private var valori: [[BancoRegno.Anno]]
        private var errori: [String] = []
        private let serratura = NSLock()
        init(conteggio: Int) { valori = Array(repeating: [], count: conteggio) }
        func metti(_ anni: [BancoRegno.Anno], a indice: Int) {
            serratura.lock(); valori[indice] = anni; serratura.unlock()
        }
        func errore(_ testo: String) { serratura.lock(); errori.append(testo); serratura.unlock() }
        func tutti() -> [BancoRegno.Anno] { valori.flatMap { $0 } }
        func tuttiGliErrori() -> [String] { errori.sorted() }
    }

    static func mediana(_ valori: [Int]) -> String {
        guard !valori.isEmpty else { return "-" }
        let ordinati = valori.sorted()
        let n = ordinati.count
        if n % 2 == 1 { return "\(ordinati[n / 2])" }
        let somma = ordinati[n / 2 - 1] + ordinati[n / 2]
        return somma % 2 == 0 ? "\(somma / 2)" : "\(somma / 2),5"
    }

    public static func esegui(cartellaValori: URL, partite: Int, anni: Int) throws -> Rapporto {
        let valori = try CaricatoreValori.carica(da: cartellaValori)
        let valoriCampagna = try CaricatoreCampagna.carica(da: cartellaValori)
        let valoriRegno = try CaricatoreRegno.carica(da: cartellaValori, archetipiNoti: Set(valori.archetipi.keys))
        let dati = try Data(contentsOf: cartellaValori.appendingPathComponent("scenari-campagna.json"))
        let scenari = try JSONDecoder().decode([String: ScenarioCampagna].self, from: dati)
        let banco = BancoRegno(valoriRegno: valoriRegno,
                               motoreCampagna: MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna),
                               valoriCampagna: valoriCampagna, scenari: scenari)
        struct Compito: Sendable { let condotta: MisuraFrequenzaBattaglie.Condotta; let seme: UInt64 }
        var tutti: [Compito] = []
        for condotta in MisuraFrequenzaBattaglie.Condotta.allCases {
            for seme in 0..<partite { tutti.append(Compito(condotta: condotta, seme: UInt64(seme))) }
        }
        let compiti = tutti
        let raccolta = Raccolta(conteggio: compiti.count)
        DispatchQueue.concurrentPerform(iterations: compiti.count) { indice in
            let c = compiti[indice]
            do { raccolta.metti(try banco.gioca(anni: anni, condotta: c.condotta, seme: c.seme), a: indice) }
            catch { raccolta.errore("condotta=\(c.condotta.rawValue),seme=\(c.seme),errore=\(error)") }
        }
        let giocati = raccolta.tutti()
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = [.sortedKeys]
        let grezzi = giocati.compactMap { try? String(data: codificatore.encode($0), encoding: .utf8) }
            .joined(separator: "\n") + "\n"

        var righe: [String] = []
        righe.append("regno.versione_valori=\(valori.versioneEffettiva)")
        righe.append(["regno.partite_per_condotta=\(partite)", "anni_per_partita=\(anni)",
                      "giornate_operative=\(valoriRegno.giornateOperative)",
                      "anni_giocati=\(giocati.count)", "anni_previsti=\(compiti.count * anni)",
                      "errori=\(raccolta.tuttiGliErrori().count)"].joined(separator: ","))
        for errore in raccolta.tuttiGliErrori() { righe.append("regno.errore=" + errore) }
        righe.append("condotta|fronte|anni|vinte|perse|interrotte_dall_inverno|ferme|battaglie_ogni_10_giornate|giornate_mediana|battaglie_per_anno_x100|atomi_partiti_mediana|atomi_rientrati_mediana|atomi_reclutati_mediana|anni_con_violazioni|anni_con_proposte_avversarie_respinte")
        for condotta in MisuraFrequenzaBattaglie.Condotta.allCases {
            let fronti = valoriRegno.fronti.map(\.identificatore) + ["tutti"]
            for fronte in fronti {
                let gruppo = giocati.filter { $0.condotta == condotta && (fronte == "tutti" || $0.fronte == fronte) }
                guard !gruppo.isEmpty else { continue }
                let giornate = gruppo.reduce(0) { $0 + $1.giornate }
                let battaglie = gruppo.reduce(0) { $0 + $1.battaglie }
                righe.append([
                    condotta.rawValue, fronte, "\(gruppo.count)",
                    "\(gruppo.filter { $0.vincitore == Parte.giocatore.rawValue }.count)",
                    "\(gruppo.filter { $0.vincitore == Parte.avversario.rawValue }.count)",
                    "\(gruppo.filter { $0.conclusione == ConclusioneCampagna.Modo.inverno.rawValue }.count)",
                    "\(gruppo.filter { $0.conclusione == "ferma" }.count)",
                    giornate == 0 ? "-" : String(format: "%.3f", Double(battaglie) * 10 / Double(giornate)),
                    mediana(gruppo.map(\.giornate)),
                    "\(battaglie * 100 / gruppo.count)",
                    mediana(gruppo.map(\.atomiPartiti)), mediana(gruppo.map(\.atomiRientrati)),
                    mediana(gruppo.map(\.atomiReclutati)),
                    "\(gruppo.filter { !$0.violazioni.isEmpty }.count)",
                    "\(gruppo.filter { $0.proposteAvversarieRespinte > 0 }.count)",
                ].joined(separator: "|"))
            }
        }
        return Rapporto(grezzi: grezzi, testo: righe.joined(separator: "\n"), anni: giocati)
    }
}
