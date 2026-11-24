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
        /// Due formazioni portano lo stesso nome (01 §5.6.0.4; incarico 31).
        case nomeDuplicato
        /// Una formazione che c'era ha cambiato nome o posto: il regno conserva le formazioni col
        /// loro nome da un anno all'altro (incarico 31).
        case nomeNonConservato
        /// Una formazione che il giocatore teneva in patria è cambiata durante la campagna.
        case formazioneInPatriaCambiata
        /// La scelta di chi parte ha cambiato altro che la destinazione dell'unità indicata.
        case destinazioneFuoriRegola
        /// All'arrivo dell'inverno il saldo non è quello di prima più l'entrata meno il
        /// mantenimento dichiarato, o il mantenimento ha toccato altro che il denaro (01 §4.14.1.1).
        case mantenimentoNonConservato(Risorsa)
        /// Il mantenimento prelevato non è la quota annua dei reparti rimasti (01 §4.14.1.1).
        case mantenimentoErrato
        /// Un reparto è stato sciolto benché il denaro bastasse, o gli atomi non tornano.
        case scioltoSenzaNecessita
        /// È stato sciolto un reparto mentre ne restava uno reclutato più di recente (01 §4.14.1.1).
        case scioltoFuoriOrdine
        /// Un reparto porta un miglioramento che nessuno ha ordinato o mantenuto, o ha perduto
        /// quello che era stato mantenuto (01 §4.13, §4.14).
        case miglioramentoFuoriRegola
        /// Un lavoro dichiara una stagione in cui sarà pronto diversa da quella che la sua durata e
        /// la stazione in cui è stato ordinato danno (01 §5.9.1.4).
        case prontoFuoriRegola
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
        case .nomeDuplicato: return "nome_duplicato"
        case .nomeNonConservato: return "nome_non_conservato"
        case .formazioneInPatriaCambiata: return "formazione_in_patria_cambiata"
        case .destinazioneFuoriRegola: return "destinazione_fuori_regola"
        case .mantenimentoNonConservato: return "mantenimento_non_conservato"
        case .mantenimentoErrato: return "mantenimento_errato"
        case .scioltoSenzaNecessita: return "sciolto_senza_necessita"
        case .scioltoFuoriOrdine: return "sciolto_fuori_ordine"
        case .miglioramentoFuoriRegola: return "miglioramento_fuori_regola"
        case .prontoFuoriRegola: return "pronto_fuori_regola"
        }
    }

    /// Che cosa è accaduto fra i due stati: la sonda non lo deduce, glielo dice chi ha fatto il passo.
    public enum Passo: Sendable {
        case aperturaDellaCampagna
        case rientroDallaCampagna(EsitoCampagna)
        /// L'arrivo dell'inverno, con l'entrata che l'evento dichiara e i valori del mantenimento.
        case arrivoDellInverno(entrata: Riserve, mantenimento: ValoriMantenimento)
        /// Una spesa, con il costo che l'evento dichiara, la durata della voce e quante stazioni
        /// vale una stagione.
        case spesa(costo: Riserve, durata: Int, stazioniPerStagione: Int)
        case stazioneSuccessiva
        /// La primavera, con la quota di riporto e l'entrata dell'anno che vale per il tetto.
        case primavera(quotaRiporto: Scalato, entrata: Riserve)
        /// La scelta di chi parte: l'unità e dove va.
        case destinazione(unita: IdentificatoreDati, alFronte: Bool)
    }

    /// Quanti atomi contano le forze: la misura con cui si confronta partenza e rientro. Qui, e non
    /// nel regno comune, perché è della modalità a sciami.
    static func atomi(_ forze: ForzeDelRegno) -> Int {
        forze.formazioni.reduce(0) { $0 + $1.atomiTotali }
    }

    /// La quota annua di mantenimento, ricalcolata qui con la sola aritmetica dei documenti: per
    /// ogni reparto gli atomi per la quota, troncata, mai sotto il minimo (01 §4.14.1.1, 00 §13.5–13.6).
    static func quota(_ forze: ForzeDelRegno, _ valori: ValoriMantenimento) -> Int {
        var totale = 0
        for formazione in forze.formazioni {
            for reparto in formazione.composizione {
                totale += max(valori.quotaMinima, Int((Int64(reparto.atomi) * valori.quotaPerMisura.grezzo) / Scalato.fattore))
            }
        }
        return totale
    }

    /// I reparti di tutte le formazioni, come multinsieme: per dire che cosa manca fra due stati.
    static func reparti(_ forze: ForzeDelRegno) -> [Reparto: Int] {
        var conto: [Reparto: Int] = [:]
        for formazione in forze.formazioni {
            for reparto in formazione.composizione { conto[reparto, default: 0] += 1 }
        }
        return conto
    }

    public func controlla(prima: StatoRegno, dopo: StatoRegno, passo: Passo,
                          giornateOperative: Int) -> [Violazione] {
        var v: [Violazione] = []
        for risorsa in Risorsa.allCases where dopo.riserve[risorsa] < 0 { v.append(.saldoNegativo(risorsa)) }
        if let stazione = dopo.momento.stazione,
           !(1...MomentoDellAnno.stazioniInvernali).contains(stazione) { v.append(.stazioneFuoriPasso) }
        // I nomi sono unici, in ogni momento (01 §5.6.0.4).
        let nomiDopo = dopo.forze.formazioni.map(\.nome)
        if Set(nomiDopo).count != nomiDopo.count { v.append(.nomeDuplicato) }

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
            // Chi non era partito resta identico; di chi era partito resta ciò che il fronte
            // restituisce, e nient'altro.
            let rimaste = prima.forze.formazioni.filter { !$0.parteConLaCampagna }
            for formazione in rimaste where !dopo.forze.formazioni.contains(formazione) {
                v.append(.formazioneInPatriaCambiata)
            }
            let ammesse = Set(rimaste).union(esito.superstiti.formazioni)
            if dopo.forze.formazioni.contains(where: { !ammesse.contains($0) })
                || dopo.forze.formazioni.count != rimaste.count + esito.superstiti.formazioni.count {
                v.append(.forzeCambiateFuoriTempo)
            }
            // Le formazioni che c'erano e che ci sono ancora conservano l'ordine in cui il regno le
            // teneva: è l'ordine in cui il giocatore le legge e in cui partono.
            let noti = Set(prima.forze.formazioni.map(\.nome))
            let sopravvissuti = Set(nomiDopo)
            if nomiDopo.filter({ noti.contains($0) })
                != prima.forze.formazioni.map(\.nome).filter({ sopravvissuti.contains($0) }) {
                v.append(.nomeNonConservato)
            }
            switch esito.modo {
            case .inverno:
                if esito.vincitore != nil || esito.giornate != giornateOperative { v.append(.esitoIncoerente) }
            case .annientamento:
                if esito.vincitore == nil || !(1...giornateOperative).contains(esito.giornate) {
                    v.append(.esitoIncoerente)
                }
            }

        case .arrivoDellInverno(let entrata, let mantenimento):
            if dopo.anno != prima.anno { v.append(.annoFuoriPasso) }
            if prima.momento.eInverno || dopo.momento.stazione != 1 { v.append(.stazioneFuoriPasso) }
            if prima.campagna.fronteAperto != nil || dopo.campagna != prima.campagna { v.append(.campagnaFuoriPasso) }
            // Il bilancio dell'inizio dell'inverno, risorsa per risorsa. Per ciò che il mantenimento
            // non tocca — tutto fuorché il denaro (01 §4.14.1.1) — il saldo è quello di prima più
            // l'entrata, e un prelievo dichiarato su una di quelle risorse è già una violazione. Per
            // il denaro il saldo è quello di prima più l'entrata meno il prelievo dichiarato.
            for risorsa in Risorsa.allCases {
                if risorsa == .denaro {
                    if dopo.riserve[risorsa] != prima.riserve[risorsa] + entrata[risorsa] - dopo.mantenimento[risorsa] {
                        v.append(.mantenimentoNonConservato(risorsa))
                    }
                } else if dopo.mantenimento[risorsa] != 0 {
                    v.append(.mantenimentoNonConservato(risorsa))
                } else if dopo.riserve[risorsa] != prima.riserve[risorsa] + entrata[risorsa] {
                    v.append(.entrataNonConservata(risorsa))
                }
            }
            if dopo.mantenimento[.denaro] != Self.quota(dopo.forze, mantenimento) { v.append(.mantenimentoErrato) }
            // Ciò che è stato sciolto: soltanto se il denaro non bastava alla quota di tutti; gli
            // atomi tornano; e nessun reparto rimasto è stato reclutato dopo uno di quelli sciolti.
            let scioltiAtomi = dopo.sciolti.reduce(0) { $0 + $1.reparto.atomi }
            if Self.atomi(dopo.forze) != Self.atomi(prima.forze) - scioltiAtomi { v.append(.scioltoSenzaNecessita) }
            let disponibile = prima.riserve[.denaro] + entrata[.denaro]
            if !dopo.sciolti.isEmpty, Self.quota(prima.forze, mantenimento) <= disponibile {
                v.append(.scioltoSenzaNecessita)
            }
            if dopo.sciolti.isEmpty, dopo.forze.formazioni.map(\.composizione) != prima.forze.formazioni.map(\.composizione) {
                v.append(.forzeCambiateFuoriTempo)
            }
            if let piuAnziano = dopo.sciolti.map({ $0.reparto.leva ?? 0 }).min() {
                let rimasti = dopo.forze.formazioni.flatMap(\.composizione).map { $0.leva ?? 0 }
                if let piuRecente = rimasti.max(), piuRecente > piuAnziano { v.append(.scioltoFuoriOrdine) }
            }
            // D'inverno nessuna formazione è ancora in arrivo: sono tutte in patria.
            if dopo.forze.formazioni.contains(where: { $0.arrivo != nil }) { v.append(.forzeCambiateFuoriTempo) }

        case .spesa(let costo, let durata, let stazioniPerStagione):
            if dopo.anno != prima.anno { v.append(.annoFuoriPasso) }
            if dopo.momento != prima.momento { v.append(.stazioneFuoriPasso) }
            if dopo.forze != prima.forze { v.append(.forzeCambiateFuoriTempo) }
            if dopo.lavori.count != prima.lavori.count + 1 { v.append(.lavoriFuoriTempo) }
            for risorsa in Risorsa.allCases where dopo.riserve[risorsa] != prima.riserve[risorsa] - costo[risorsa] {
                v.append(.spesaNonConservata(risorsa))
            }
            // Quando sarà pronto, ricalcolato qui: la stazione più la durata, misurate sull'inverno
            // di quattro stazioni e sulle stagioni che ne valgono ciascuna quante i valori dicono.
            if let lavoro = dopo.lavori.last, let stazione = prima.momento.stazione {
                let compiuto = stazione + durata
                let primavera = MomentoDellAnno.stazioniInvernali + 1
                let attesa: Stagione
                if compiuto <= primavera { attesa = .primavera }
                else if compiuto <= primavera + stazioniPerStagione { attesa = .estate }
                else if compiuto <= primavera + 2 * stazioniPerStagione { attesa = .autunno }
                else { attesa = .inverno }
                if lavoro.pronto != attesa || lavoro.stazione != stazione { v.append(.prontoFuoriRegola) }
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
            // Le reclute: al più una formazione in più per ciascuna stagione in cui una leva matura
            // (nessuna, se i nomi sono finiti e le reclute confluiscono); e gli atomi di prima più
            // quelli che le leve dichiaravano.
            let leve = prima.lavori.filter { $0.effetto.specie == .recluta }
            let stagioni = Set(leve.map(\.pronto)).count
            let atomiAttesi = Self.atomi(prima.forze) + leve.reduce(0) { $0 + ($1.effetto.misuraPropria ?? 0) }
            let prime = prima.forze.formazioni.count, dopoConto = dopo.forze.formazioni.count
            if dopoConto < prime || dopoConto > prime + stagioni || Self.atomi(dopo.forze) != atomiAttesi {
                v.append(.recluteNonArrivate)
            }
            // Le formazioni che c'erano restano al loro posto, col loro nome.
            if Array(nomiDopo.prefix(prime)) != prima.forze.formazioni.map(\.nome) { v.append(.nomeNonConservato) }
            // I miglioramenti (01 §4.13, §4.14): un reparto che ne portava uno lo conserva se e solo
            // se una voce di mantenimento di questo inverno lo indicava; uno che non ne portava lo
            // riceve se e solo se una voce di miglioramento lo indicava.
            for (f, formazione) in prima.forze.formazioni.enumerated() where f < dopoConto {
                let nuova = dopo.forze.formazioni[f]
                for (r, reparto) in formazione.composizione.enumerated() where r < nuova.composizione.count {
                    let bersaglio = BersaglioMilitare(unita: formazione.nome, elemento: r)
                    let lavoro = prima.lavori.first { $0.bersaglio == bersaglio }
                    let atteso: IdentificatoreDati?
                    switch lavoro?.effetto.specie {
                    case .migliora(let chiave): atteso = reparto.miglioramento ?? chiave
                    case .mantiene: atteso = reparto.miglioramento
                    case .recluta, nil: atteso = nil
                    }
                    if nuova.composizione[r].miglioramento != atteso { v.append(.miglioramentoFuoriRegola) }
                }
            }

        case .destinazione(let unita, let alFronte):
            if dopo.anno != prima.anno || dopo.momento != prima.momento { v.append(.annoFuoriPasso) }
            if dopo.riserve != prima.riserve || dopo.lavori != prima.lavori || dopo.campagna != prima.campagna {
                v.append(.destinazioneFuoriRegola)
            }
            let attese = prima.forze.formazioni.map { formazione -> FormazioneDelRegno in
                var nuova = formazione
                if formazione.nome == unita { nuova.inPatria = !alFronte }
                return nuova
            }
            if dopo.forze.formazioni != attese { v.append(.destinazioneFuoriRegola) }
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
/// giocatore in patria, la più semplice che usi tutto ciò che la patria offre (incarico 31): in
/// primavera, in una partita su tre, tiene in patria la formazione non armata negli anni pari e la
/// rimanda al fronte nei dispari; d'inverno, in ciascuna delle prime tre schermate, ordina una volta
/// ogni voce che può pagare — per le voci che agiscono su un reparto, sul primo che le ammette —, e
/// nella quarta continua finché ne resta una che si può pagare; poi prosegue fino alla primavera.
/// Così i lavori cadono in schermate diverse, e quelli lunghi ordinati tardi arrivano a campagna aperta.
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
        /// Il denaro che il mantenimento ha prelevato all'inizio dell'inverno, e i reparti sciolti.
        public let mantenimento: Int
        public let repartiSciolti: Int
        /// I miglioramenti e i mantenimenti di miglioramenti ordinati nell'inverno.
        public let miglioramentiOrdinati: Int
        public let mantenimentiOrdinati: Int
        /// Le formazioni di reclute che la primavera ha formato, e quante arrivano a campagna aperta.
        public let formazioniDiReclute: Int
        public let arriviACampagnaAperta: Int
        /// Le formazioni che il giocatore ha tenuto in patria durante la campagna dell'anno.
        public let tenuteInPatria: Int
        public let riportato: [String: Int]
        public let violazioni: [String]
        public let motivoFerma: String?
        /// Le proposte della condotta avversaria che il Motore ha respinto durante la campagna
        /// dell'anno, e la prima (`MisuraFrequenzaBattaglie.Partita`).
        public let proposteAvversarieRespinte: Int
        public let primaPropostaRespinta: String?
        /// Com'era la battaglia che non si è conclusa e ha fermato la campagna dell'anno (incarico 32);
        /// nulla, e omesso dalla riga, quando la campagna si è conclusa.
        public var diagnosi: DiagnosiBattaglia?
        enum CodingKeys: String, CodingKey {
            case seme, condotta, anno, fronte, conclusione, vincitore, giornate, battaglie, vinte, perse, diagnosi
            case atomiPartiti = "atomi_partiti"
            case atomiRientrati = "atomi_rientrati"
            case formazioniPartite = "formazioni_partite"
            case formazioniRientrate = "formazioni_rientrate"
            case entrata
            case leveOrdinate = "leve_ordinate"
            case atomiReclutati = "atomi_reclutati"
            case mantenimento
            case repartiSciolti = "reparti_sciolti"
            case miglioramentiOrdinati = "miglioramenti_ordinati"
            case mantenimentiOrdinati = "mantenimenti_ordinati"
            case formazioniDiReclute = "formazioni_di_reclute"
            case arriviACampagnaAperta = "arrivi_a_campagna_aperta"
            case tenuteInPatria = "tenute_in_patria"
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

            // 0. La scelta di chi parte: in una partita su tre la formazione non armata resta in
            // patria negli anni pari e torna al fronte nei dispari.
            if seme % 3 == 2, let nonArmata = stato.forze.formazioni.first(where: { $0.categoria.eNonArmata }) {
                let comando = ComandoRegno.destina(unita: nonArmata.nome, alFronte: stato.anno % 2 == 1)
                if motoreRegno.valida(comando, stato: stato).eValido {
                    let prima = stato
                    _ = applica(comando)
                    sorveglia(prima, .destinazione(unita: nonArmata.nome, alFronte: stato.anno % 2 == 1))
                }
            }
            let tenuteInPatria = stato.forze.formazioni.filter(\.inPatria).count
            let arriviACampagnaAperta = stato.forze.formazioni
                .filter { $0.parteConLaCampagna && ($0.arrivo == .estate || $0.arrivo == .autunno) }.count

            // 1. La campagna dell'anno, se il regno ha di che condurla.
            let fronti = motoreRegno.valori.fronti
            let fronte = fronti[(stato.anno - 1 + Int(seme % UInt64(fronti.count))) % fronti.count]
            let atomiPartiti = SondaInvariantiRegno.atomi(stato.forze)
            let formazioniPartite = stato.forze.formazioni.filter(\.parteConLaCampagna).count
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
                        leveOrdinate: 0, atomiReclutati: 0, mantenimento: 0, repartiSciolti: 0,
                        miglioramentiOrdinati: 0, mantenimentiOrdinati: 0, formazioniDiReclute: 0,
                        arriviACampagnaAperta: arriviACampagnaAperta, tenuteInPatria: tenuteInPatria,
                        riportato: [:], violazioni: violazioni.sorted(),
                        motivoFerma: partita.motivoFerma ?? partita.fine.rawValue,
                        proposteAvversarieRespinte: respinte, primaPropostaRespinta: primaRespinta,
                        diagnosi: partita.diagnosi))
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

            // 2. L'inverno: l'entrata e il mantenimento; poi, schermata per schermata, le voci.
            var prima = stato
            var entrata = Riserve()
            var mantenimento = 0, repartiSciolti = 0
            for evento in applica(.attendiInverno) {
                if case .invernoCominciato(_, let e, let m, let sciolti) = evento {
                    entrata = e; mantenimento = m[.denaro]; repartiSciolti = sciolti.count
                }
            }
            sorveglia(prima, .arrivoDellInverno(entrata: entrata, mantenimento: motoreRegno.valori.mantenimento))
            var leve = 0, atomiReclutati = 0, miglioramenti = 0, mantenimenti = 0
            let voci = motoreRegno.valori.voci
            /// Ordina la voce se si può, sul primo bersaglio che la ammette quando ne chiede uno.
            func ordina(_ voce: VoceDelRegno) -> Bool {
                let bersaglio = voce.effetto.richiedeBersaglio
                    ? motoreRegno.bersagli(di: voce, stato: stato).first : nil
                if voce.effetto.richiedeBersaglio, bersaglio == nil { return false }
                let comando = ComandoRegno.ordina(voce: voce.identificatore, bersaglio: bersaglio)
                guard motoreRegno.valida(comando, stato: stato).eValido else { return false }
                let prima = stato
                var costo = Riserve()
                for evento in applica(comando) {
                    if case .lavoroOrdinato(_, let c, _, _) = evento { costo = c }
                }
                sorveglia(prima, .spesa(costo: costo, durata: voce.durata,
                                        stazioniPerStagione: motoreRegno.valori.stazioniPerStagione))
                switch voce.effetto.specie {
                case .recluta:
                    leve += 1
                    atomiReclutati += voce.effetto.misuraPropria ?? 0
                case .migliora: miglioramenti += 1
                case .mantiene: mantenimenti += 1
                }
                return true
            }
            // Per prima cosa si mantiene ciò che è già migliorato: chi non lo paga lo perde.
            for voce in voci where voce.effetto.specie != .recluta {
                if case .mantiene = voce.effetto.specie { while ordina(voce) {} }
            }
            for stazione in 1...MomentoDellAnno.stazioniInvernali {
                if stazione < MomentoDellAnno.stazioniInvernali {
                    for voce in voci { _ = ordina(voce) }
                    prima = stato
                    _ = applica(.prosegui)
                    sorveglia(prima, .stazioneSuccessiva)
                } else {
                    var rifiutiDiFila = 0, indice = 0
                    while rifiutiDiFila < voci.count {
                        if ordina(voci[indice % voci.count]) { rifiutiDiFila = 0 } else { rifiutiDiFila += 1 }
                        indice += 1
                    }
                }
            }
            prima = stato
            var formazioniDiReclute = 0
            for evento in applica(.prosegui) {
                if case .primaveraCominciata(_, _, let ingressi, _, _) = evento {
                    formazioniDiReclute = ingressi.filter { !$0.confluite }.count
                }
            }
            sorveglia(prima, .primavera(quotaRiporto: motoreRegno.valori.quotaRiporto, entrata: entrata))

            giocati.append(Anno(
                seme: seme, condotta: condotta, anno: stato.anno - 1, fronte: fronte.identificatore,
                conclusione: conclusione, vincitore: esitoCampagna?.vincitore?.rawValue, giornate: giornate,
                battaglie: battaglie, vinte: vinte, perse: perse, atomiPartiti: atomiPartiti,
                atomiRientrati: atomiRientrati, formazioniPartite: formazioniPartite,
                formazioniRientrate: formazioniRientrate, entrata: mappa(entrata), leveOrdinate: leve,
                atomiReclutati: atomiReclutati, mantenimento: mantenimento, repartiSciolti: repartiSciolti,
                miglioramentiOrdinati: miglioramenti, mantenimentiOrdinati: mantenimenti,
                formazioniDiReclute: formazioniDiReclute, arriviACampagnaAperta: arriviACampagnaAperta,
                tenuteInPatria: tenuteInPatria, riportato: mappa(stato.riserve),
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
        let centrale = ordinati[n / 2]
        if n % 2 == 1 { return String(centrale) }
        // Le stringhe letterali del pacchetto non contengono spazi (00 §14.1, ConfiniTest): i
        // valori si calcolano prima e si scrivono dopo.
        let somma = ordinati[n / 2 - 1] + centrale
        let meta = String(somma / 2)
        return somma % 2 == 0 ? meta : meta + ",5"
    }

    public static func esegui(cartellaValori: URL, partite: Int, anni: Int) throws -> Rapporto {
        let valori = try CaricatoreValori.carica(da: cartellaValori)
        let valoriCampagna = try CaricatoreCampagna.carica(da: cartellaValori)
        let valoriRegno = try CaricatoreRegno.carica(da: cartellaValori, archetipiNoti: Set(valori.archetipi.keys),
                                                     miglioramentiNoti: Set(valori.miglioramenti.keys))
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
        let anniPrevisti = compiti.count * anni
        let numeroErrori = raccolta.tuttiGliErrori().count
        righe.append(["regno.partite_per_condotta=\(partite)", "anni_per_partita=\(anni)",
                      "giornate_operative=\(valoriRegno.giornateOperative)",
                      "anni_giocati=\(giocati.count)", "anni_previsti=\(anniPrevisti)",
                      "errori=\(numeroErrori)"].joined(separator: ","))
        for errore in raccolta.tuttiGliErrori() { righe.append("regno.errore=" + errore) }
        righe.append("condotta|fronte|anni|vinte|perse|interrotte_dall_inverno|ferme|battaglie_ogni_10_giornate|giornate_mediana|battaglie_per_anno_x100|atomi_partiti_mediana|atomi_rientrati_mediana|atomi_reclutati_mediana|mantenimento_mediana|anni_con_reparti_sciolti|miglioramenti_ordinati|mantenimenti_ordinati|anni_con_arrivi_a_campagna_aperta|anni_con_formazioni_in_patria|anni_con_violazioni|anni_con_proposte_avversarie_respinte")
        for condotta in MisuraFrequenzaBattaglie.Condotta.allCases {
            let identificatori: [String] = valoriRegno.fronti.map { $0.identificatore }
            let fronti: [String] = identificatori + ["tutti"]
            for fronte in fronti {
                let gruppo = giocati.filter { $0.condotta == condotta && (fronte == "tutti" || $0.fronte == fronte) }
                guard !gruppo.isEmpty else { continue }
                let giornate = gruppo.reduce(0) { $0 + $1.giornate }
                let battaglie = gruppo.reduce(0) { $0 + $1.battaglie }
                let vinte = gruppo.filter { $0.vincitore == Parte.giocatore.rawValue }.count
                let perse = gruppo.filter { $0.vincitore == Parte.avversario.rawValue }.count
                let interrotte = gruppo.filter { $0.conclusione == ConclusioneCampagna.Modo.inverno.rawValue }.count
                let ferme = gruppo.filter { $0.conclusione == "ferma" }.count
                let conViolazioni = gruppo.filter { !$0.violazioni.isEmpty }.count
                let conRespinte = gruppo.filter { $0.proposteAvversarieRespinte > 0 }.count
                let battagliePerCentoAnni = battaglie * 100 / gruppo.count
                let conclusi = gruppo.filter { $0.conclusione != "ferma" }
                let conSciolti = gruppo.filter { $0.repartiSciolti > 0 }.count
                let miglioramenti = gruppo.reduce(0) { $0 + $1.miglioramentiOrdinati }
                let mantenimenti = gruppo.reduce(0) { $0 + $1.mantenimentiOrdinati }
                let conArrivi = gruppo.filter { $0.arriviACampagnaAperta > 0 }.count
                let conInPatria = gruppo.filter { $0.tenuteInPatria > 0 }.count
                let frequenza: String = giornate == 0 ? "-" : String(format: "%.3f", Double(battaglie) * 10 / Double(giornate))
                var colonne: [String] = [condotta.rawValue, fronte, String(gruppo.count)]
                colonne += [String(vinte), String(perse), String(interrotte), String(ferme)]
                colonne += [frequenza, mediana(gruppo.map { $0.giornate }), String(battagliePerCentoAnni)]
                colonne += [mediana(gruppo.map { $0.atomiPartiti }), mediana(gruppo.map { $0.atomiRientrati })]
                colonne += [mediana(gruppo.map { $0.atomiReclutati }), mediana(conclusi.map { $0.mantenimento })]
                colonne += [String(conSciolti), String(miglioramenti), String(mantenimenti)]
                colonne += [String(conArrivi), String(conInPatria), String(conViolazioni), String(conRespinte)]
                righe.append(colonne.joined(separator: "|"))
            }
        }
        return Rapporto(grezzi: grezzi, testo: righe.joined(separator: "\n"), anni: giocati)
    }
}
