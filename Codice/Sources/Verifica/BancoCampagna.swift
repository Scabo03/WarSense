import Foundation
import Dati
import Motore

/// Gli scenari di campagna del programma di verifica, dichiarativi come quelli di
/// scontro (05 §12.2): aggiungere un caso da misurare non richiede di toccare il
/// programma. La variazione non viene da semi — la campagna di questa unità non
/// contiene alcuna estrazione del caso, esattamente come la battaglia (RDA-59) —
/// ma dagli scenari e dal numero dei gruppi.
public struct ScenariCampagna: Codable, Sendable {
    public struct Voce: Codable, Sendable {
        public let identificatore: IdentificatoreDati
        public let mappa: IdentificatoreDati
        public let gruppi: [ScenarioCampagna.GruppoIniziale]
        /// I gruppi dell'AVVERSARIO (incarico 18): quando presenti, la corsa è una partita
        /// intera contro la condotta deterministica, ed è il primo dato che dice se si
        /// gioca davvero contro qualcuno. Assenti, la corsa è quella di prima e nessuno
        /// muove dopo il giocatore.
        public let gruppiAvversario: [ScenarioCampagna.GruppoIniziale]
        /// Le forze nemiche e le strutture dello scenario: dati MINIMI per provare taglio
        /// e zona, non l'avversario e non le opere (incarico 16). Assenti negli scenari
        /// che non li esercitano, e allora vuoti.
        public let forzeNemiche: [Cella]
        public let struttureDiRifornimento: [Cella]

        enum CodingKeys: String, CodingKey {
            case identificatore, mappa, gruppi
            case gruppiAvversario = "gruppi_avversario"
            case forzeNemiche = "forze_nemiche"
            case struttureDiRifornimento = "strutture_di_rifornimento"
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            identificatore = try c.decode(IdentificatoreDati.self, forKey: .identificatore)
            mappa = try c.decode(IdentificatoreDati.self, forKey: .mappa)
            gruppi = try c.decode([ScenarioCampagna.GruppoIniziale].self, forKey: .gruppi)
            gruppiAvversario = try c.decodeIfPresent([ScenarioCampagna.GruppoIniziale].self,
                                                     forKey: .gruppiAvversario) ?? []
            forzeNemiche = try c.decodeIfPresent([Cella].self, forKey: .forzeNemiche) ?? []
            struttureDiRifornimento = try c.decodeIfPresent([Cella].self, forKey: .struttureDiRifornimento) ?? []
        }
    }
    /// Quante giornate generare per ciascuno scenario.
    public let giornateGenerate: Int
    /// I conteggi di gruppi su cui si misura il costo di chiusura della giornata.
    public let gruppiPerLaMisuraDeiPassi: [Int]
    public let scenari: [Voce]

    enum CodingKeys: String, CodingKey {
        case giornateGenerate = "giornate_generate"
        case gruppiPerLaMisuraDeiPassi = "gruppi_per_la_misura_dei_passi"
        case scenari
    }

    public static func carica(da cartella: URL) throws -> ScenariCampagna {
        let url = cartella.appendingPathComponent("campagne.json")
        guard let dati = try? Data(contentsOf: url) else {
            throw ErroreDati(chiave: "errore.dati.file_mancante", file: url.lastPathComponent)
        }
        do { return try JSONDecoder().decode(ScenariCampagna.self, from: dati) }
        catch { throw ErroreDati(chiave: "errore.dati.file_malformato", file: url.lastPathComponent) }
    }
}

/// Il banco di misura della campagna: genera giornate in modo deterministico e
/// riproducibile, sorveglia gli invarianti a ogni passo e prende le misure.
///
/// Non contiene alcuna regola propria: ogni esito viene dal Motore, come il banco
/// degli scontri (05 §12.1). Ciò che aggiunge è la CONDOTTA con cui si generano le
/// giornate, che è deterministica per costruzione: ogni gruppo in attesa riceve un
/// ordine scelto da una regola fissa, mai da un'estrazione.
public struct BancoCampagna: Sendable {
    public let motore: MotoreCampagna
    public let valoriCampagna: ValoriCampagna
    public let scenari: ScenariCampagna
    private let sonda = SondaInvariantiCampagna()

    public init(motore: MotoreCampagna, valoriCampagna: ValoriCampagna, scenari: ScenariCampagna) {
        self.motore = motore
        self.valoriCampagna = valoriCampagna
        self.scenari = scenari
    }

    /// Le chiavi degli archetipi noti, per la fabbrica (rifiuto dell'archetipo ignoto).
    private var archetipiNoti: Set<IdentificatoreDati> { Set(motore.valori.archetipi.keys) }

    // MARK: - Il passaggio alla battaglia al banco (01 §6, §15, incarico 24)

    /// Il modello PROVVISORIO dello scontro al banco (S24e): campo aperto standard su formato
    /// «cento», protezione anti-saturazione, il primo ufficiale. Cornice minima; il banco non tara
    /// il combattimento, che il titolare ha accettato.
    private var modelloScontro: PonteCampagnaBattaglia.Modello {
        PonteCampagnaBattaglia.Modello(formato: "cento", caratteristica: "campo_aperto",
            protezione: .antiSaturazione, fase: nil,
            ufficialeAvversario: motore.valori.ufficiali.keys.sorted().first)
    }

    /// Vero se per un gruppo esiste ALMENO UN comando di campagna valido (incarico 25): presidio,
    /// sosta con raccolta, una marcia verso un vicino, e — secondo la categoria — esplorazione o
    /// imboscata. È il predicato dell'invariante della giocabilità: un gruppo non-agito ordinabile.
    private func ordinabile(_ gruppo: Gruppo, stato: StatoCampagna) -> Bool {
        var candidati: [ComandoCampagna] = [.presidio(gruppo: gruppo.id), .sostaConRaccolta(gruppo: gruppo.id)]
        for vicino in stato.griglia.vicini(di: gruppo.posizione) {
            candidati.append(.marcia(gruppo: gruppo.id, a: vicino,
                                     giorni: motore.costoInGiorni(da: gruppo.posizione, a: vicino, stato: stato)))
        }
        if gruppo.categoria.eRicognizione { candidati.append(.esplorazione(gruppo: gruppo.id)) }
        if gruppo.categoria.eArmata { candidati.append(.imboscata(gruppo: gruppo.id)) }
        return candidati.contains { motore.valida($0, parte: gruppo.parte, stato: stato).eValido }
    }

    /// Vero se un gruppo armato AVVERSARIO occupa una casella adiacente a quella del gruppo: la
    /// condotta del banco vi tende un'imboscata, così l'ingresso dell'avversario apre una battaglia
    /// da agguato invece che una ordinaria (incarico 24).
    private func armatoAvversarioAdiacente(a gruppo: Gruppo, stato: StatoCampagna) -> Bool {
        let avversa: Parte = gruppo.parte.avversaria
        for vicino in stato.griglia.vicini(di: gruppo.posizione) {
            if let occupante = stato.occupante(di: vicino, parte: avversa), occupante.categoria.eArmata {
                return true
            }
        }
        return false
    }

    /// I conteggi delle battaglie di una corsa.
    struct EsitiBattaglie { var giocate = 0, vinte = 0, perse = 0, daImboscata = 0; var primoGiorno: Int? = nil }

    /// Gioca le battaglie in sospeso e ne riporta l'esito in campagna (incarico 24): per ciascuna,
    /// costruisce lo scenario dai due gruppi (`PonteCampagnaBattaglia.scenario`), la combatte a
    /// conclusione con due tattici deterministici come `BancoSessioniBattaglia`, RIGIOCA la stessa
    /// sequenza per l'invariante di determinismo, deriva l'esito e lo PIEGA sulla mappa. Sorveglia
    /// i quattro invarianti del passaggio (conservazione, ritorno, blocco, rigiocatura). Il banco
    /// non solo RENDE POSSIBILE la battaglia: la GENERA e la gioca, e ne conta gli esiti.
    private func giocaBattaglieInSospeso(_ stato: inout StatoCampagna,
                                         violazioni: inout Set<String>) -> EsitiBattaglie {
        var conteggi = EsitiBattaglie()
        let motoreB = MotoreBattaglia(valori: motore.valori)
        guard let uffId = modelloScontro.ufficialeAvversario,
              let ufficiale = motore.valori.ufficiali[uffId] else { return conteggi }
        var sicurezza = 0
        while let battaglia = stato.battaglieInSospeso.first, sicurezza < 100 {
            sicurezza += 1
            // (3) Il BLOCCO: con una battaglia in sospeso un comando è respinto col motivo dovuto.
            let motivo = motore.valida(.presidio(gruppo: battaglia.gruppoGiocatore),
                                       parte: .giocatore, stato: stato).motivo
            violazioni.formUnion(sonda.controllaBloccoBattaglia(
                haBattagliaInSospeso: true, motivoDelComando: motivo).map(\.description))

            let scenario = PonteCampagnaBattaglia.scenario(da: battaglia, stato: stato, modello: modelloScontro)
            guard var sb = try? FabbricaBattaglia.crea(scenario: scenario, valori: motore.valori).0 else {
                stato.battaglieInSospeso.removeFirst(); continue
            }
            let tattici: [Parte: TatticoBattaglia] = [
                .giocatore: TatticoBattaglia(motore: motoreB, ufficiale: ufficiale, parte: .giocatore),
                .avversario: TatticoBattaglia(motore: motoreB, ufficiale: ufficiale, parte: .avversario)]
            var comandi: [(Parte, ComandoBattaglia)] = []
            var passi = 0
            while sb.esito == nil, sb.giro <= 400, passi < 40000 {
                passi += 1
                let parte = sb.parteDiTurno
                let comando = tattici[parte]!.prossimoComando(stato: sb)
                comandi.append((parte, comando))
                sb = motoreB.applica(comando, parte: parte, stato: sb).0
            }
            // (4) DETERMINISMO: rigioca la stessa sequenza e confronta l'impronta.
            if var rigiocata = try? FabbricaBattaglia.crea(scenario: scenario, valori: motore.valori).0 {
                for (parte, comando) in comandi where motoreB.valida(comando, parte: parte, stato: rigiocata).eValido {
                    rigiocata = motoreB.applica(comando, parte: parte, stato: rigiocata).0
                }
                violazioni.formUnion(sonda.controllaRigiocaturaBattaglia(
                    casella: battaglia.casella, improntaGiocata: sb.impronta(),
                    improntaRigiocata: rigiocata.impronta()).map(\.description))
            }
            // I superstiti, contati INDIPENDENTEMENTE dal Ponte, per la conservazione.
            func superstiti(_ parte: Parte) -> Int {
                var totale = 0
                for sciame in sb.sciami.values where sciame.parte == parte {
                    let pv = motore.valori.archetipi[sciame.archetipo]?.puntiVitaPerAtomo ?? 1
                    totale += Int(sciame.atomiPresenti(puntiVitaPerAtomo: pv,
                                                       minimo: motore.valori.minimi.atomiMinimiSciameVivo))
                }
                for elemento in sb.deck[parte] ?? [] where elemento.esemplari > 0 {
                    totale += Int(elemento.atomi) * elemento.esemplari
                }
                return totale
            }
            let esito = PonteCampagnaBattaglia.esito(da: sb, per: battaglia, stato: stato, valori: motore.valori)
            // (1) CONSERVAZIONE: gli atomi che tornano coincidono coi superstiti.
            violazioni.formUnion(sonda.controllaConservazioneForze(esito: esito,
                superstiti: [.giocatore: superstiti(.giocatore), .avversario: superstiti(.avversario)]).map(\.description))
            _ = motore.applicaEsitoInCampagna(esito, in: &stato)
            // (2) RITORNO: annientato sparito, superstite ridotto e alla casella dovuta.
            violazioni.formUnion(sonda.controllaRitornoInCampagna(
                inSospeso: battaglia, esito: esito, dopo: stato).map(\.description))
            // (5) GIOCABILITÀ (incarico 25): tornata la campagna dalla battaglia, NESSUN gruppo può
            // essere non-agito e senza azioni — il blocco del titolare. È qui, subito dopo il
            // ritorno, che il difetto viveva; l'invariante lo rende impossibile.
            violazioni.formUnion(sonda.controllaGiocabilita(
                stato: stato, ordinabile: { ordinabile($0, stato: stato) }).map(\.description))
            conteggi.giocate += 1
            if conteggi.primoGiorno == nil { conteggi.primoGiorno = battaglia.giorno }
            if battaglia.daImboscata { conteggi.daImboscata += 1 }
            if esito.sconfitto == .giocatore { conteggi.perse += 1 } else { conteggi.vinte += 1 }
        }
        return conteggi
    }

    /// La composizione dei gruppi generati dalle misure interne (passi, distanze,
    /// uscite): una fanteria leggera, volume sotto la soglia, così che la misura del
    /// costo di chiusura non dipenda dal volume. La diversità di volume che l'unità
    /// esercita viene dagli scenari di `campagne.json`, non da queste misure.
    static let composizioneDiMisura: [ScenarioCampagna.RepartoIniziale] =
        [.init(archetipo: "fanteria_leggera", atomi: 6)]

    // MARK: - Generazione deterministica delle giornate

    /// L'esito di una corsa: quante giornate, quanti ordini, quali violazioni.
    public struct Corsa: Sendable {
        public let identificatore: IdentificatoreDati
        public let mappa: IdentificatoreDati
        public let gruppi: Int
        public let giornate: Int
        public let ordini: Int
        public let marce: Int
        /// Le marce ordinate che durano più di un giorno (01 §5.6.3.3): il caso che
        /// questa unità introduce. Se zero, la corsa non ha esercitato la marcia lunga.
        public let marceLunghe: Int
        /// Le marce compiutesi alla risoluzione di fine giornata (01 §5.6.11).
        public let marceCompiute: Int
        /// Le revoche impartite (01 §5.6.3.3, RDA-76).
        public let revoche: Int
        public let presidi: Int
        /// Le divisioni e le riunioni generate (01 §5.6.0.2, §5.6.0.3): se zero, la
        /// corsa non le ha esercitate, e gli invarianti relativi non hanno morso.
        public let divisioni: Int
        public let riunioni: Int
        /// Ordini impartiti a un gruppo che NON aveva alcuna destinazione libera:
        /// è il caso di stipamento, quello in cui l'azione di marcia non si offre
        /// affatto (02 §9.5). Se questo numero è zero, la corsa non ha esercitato
        /// lo stipamento, per quanti gruppi vi fossero.
        public let senzaDestinazione: Int
        /// Il volume più piccolo e più grande fra i gruppi dello scenario (01 §5.6.3):
        /// se differiscono, la corsa ha esercitato marce di volumi diversi, cioè il
        /// caso che questa unità introduce. Uguali, i gruppi erano tutti dello stesso
        /// ingombro e la diversità di volume non è stata esercitata.
        public let volumeMinimo: Int
        public let volumeMassimo: Int
        /// I fenomeni del rifornimento generati dalla corsa (01 §5.2.2): se restano a
        /// zero, la corsa non li ha esercitati e gli invarianti relativi non hanno morso.
        /// Il taglio (interruzioni), la sosta IMPOSTA di due turni (fatti non decisi nel
        /// registro), la sosta VOLONTARIA di un turno (ordinata dalla condotta), le
        /// riprese, i turni-gruppo passati in zona e le strutture isolate allo scenario.
        public let tagli: Int
        public let sosteImposte: Int
        public let sosteVolontarie: Int
        public let riprese: Int
        public let passaggiInZona: Int
        public let struttureIsolate: Int
        // I fenomeni dell'AVVERSARIO (incarico 18): il primo dato che dice se si gioca
        // davvero contro qualcuno. Zero negli scenari senza avversario.
        /// I gruppi avversari dello scenario.
        public let gruppiAvversario: Int
        /// I tagli di rifornimento dei gruppi del GIOCATORE causati dall'avversario: negli
        /// scenari con avversario e senza forze ferme, ogni taglio del giocatore è opera
        /// sua (nessun'altra forza può stargli alle spalle).
        public let tagliDaAvversario: Int
        /// Gli AGGIRAMENTI (01 §5.13): i gruppi avversari DISTINTI che almeno una volta
        /// si sono portati oltre la linea del giocatore, cioè più vicini al suo quartier
        /// generale di ogni suo gruppo. Se zero, la corsa non ha esercitato l'aggiramento.
        public let aggiramenti: Int
        /// La distanza MINIMA raggiunta da un gruppo avversario dal quartier generale del
        /// giocatore, durante la corsa: quanto l'avversario si è avvicinato all'obiettivo.
        /// Vale la larghezza della mappa più uno quando non c'è avversario (mai avvicinato).
        public let minDistanzaAvversarioQg: Int
        // I fenomeni della RICOGNIZIONE, delle imboscate e delle azioni contro le formazioni
        // non armate (incarico 19): il banco deve GENERARLI, non solo renderli possibili. Se
        // uno resta a zero, la corsa non l'ha esercitato e l'invariante relativo non ha morso.
        /// Le esplorazioni per esito deterministico (01 §5.4): riuscite, a mani vuote, notati,
        /// perduti. La loro somma è il numero di esplorazioni ordinate nella corsa.
        public let esplorazioniRiuscite: Int
        public let esplorazioniAManiVuote: Int
        public let esploratoriNotati: Int
        public let esploratoriPerduti: Int
        /// I sabotaggi RIUSCITI, per categoria di chi li compie (01 §5.10.2): da gruppo armato
        /// (riesce sempre) e da esploratori (solo con competenza sufficiente); più i sabotaggi
        /// FALLITI, cioè esploratori sotto soglia che si fanno notare.
        public let sabotaggiArmati: Int
        public let sabotaggiEsploratori: Int
        public let sabotaggiFalliti: Int
        /// Gli studi approfonditi compiuti (01 §5.10.2).
        public let studi: Int
        /// Le imboscate PIAZZATE (ordine di imboscata) e quelle SCATTATE (01 §5.11): lo scatto
        /// è sempre fra parti opposte, sicché ne conta le imboscate di entrambe le parti.
        public let imboscatePiazzate: Int
        public let imboscateScattate: Int
        /// Le imboscate dell'avversario SUBITE dal giocatore (01 §5.11, incarico 21): lo scatto in
        /// cui il GIOCATORE è caduto entrando in una casella occultata di cui non aveva notizia
        /// certa. Sottoinsieme degli scatti, dalla parte di chi cade.
        public let imboscateSubite: Int
        /// Le imboscate avversarie SCOPERTE dalla ricognizione del giocatore (01 §5.11.1, incarico
        /// 21): un'esplorazione riuscita ne ha rivelato la casella, prima occulta.
        public let imboscateScoperte: Int
        /// Le BATTAGLIE nate dalla campagna e giocate al banco (01 §6, §15, incarico 24): quante in
        /// tutto, quante vinte e quante perse dal giocatore, e quante nate da un'imboscata. Il banco
        /// deve GENERARLE, non solo renderle possibili: se restano a zero negli scenari con avversario,
        /// la funzione che il giocatore non può raggiungere non esiste.
        public let battaglieGiocate: Int
        public let battaglieVinte: Int
        public let battagliePerse: Int
        public let battaglieDaImboscata: Int
        /// Le GIORNATE che la partita PROSEGUE dopo la PRIMA battaglia (incarico 25): dal giorno del
        /// primo scontro alla fine della corsa. Se è zero o quasi negli scenari con battaglie, il
        /// banco non esercita il caso che ha bloccato il titolare — la giornata dopo il ritorno.
        public let giornateDopoLaPrimaBattaglia: Int
        /// Le GIORNATE in cui TUTTI i gruppi di una parte erano appostati (01 §5.11, incarico 21):
        /// il caso limite che l'incarico 20 non terminava e che ora, con l'imboscata che consuma
        /// l'azione, si chiude da sé.
        public let giornateTuttiAppostati: Int
        /// Gli AVVISTAMENTI di formazioni avversarie da parte del giocatore lungo la corsa (01
        /// §5.6.11, incarico 22): quanti in tutto, in quale giornata il PRIMO (nil se nessuno), e
        /// il GAP MEDIO fra un avvistamento e il successivo (nil con meno di due). Sono il dato che
        /// dice se e quando l'avversario si manifesta — la misura che l'incarico 22 pretende riportata.
        public let avvistamenti: Int
        public let primoAvvistamento: Int?
        public let gapMedioAvvistamenti: Int?
        /// La porzione di mappa che il giocatore OSSERVA davvero muovendo i propri gruppi, dato il
        /// raggio di osservazione (incarico 22): le caselle viste in unione su tutte le giornate, e
        /// il totale della griglia. Un raggio piccolo su una mappa grande lascia fuori quasi tutto.
        public let caselleOsservate: Int
        public let caselleTotali: Int
        public let violazioni: [String]
        public let improntaFinale: String
    }

    /// La condotta deterministica dell'avversario, la stessa della Sessione (RDA-114):
    /// il banco la «pompa» dopo il turno del giocatore, per generare partite intere.
    private let condotta = CondottaAvversaria()

    /// La condotta: per ciascun gruppo in attesa, la prima destinazione valida
    /// nell'ordine di lettura se ne esiste una, altrimenti il presidio; il gruppo
    /// da ordinare è sempre quello che il salto diretto propone. È la stessa
    /// sequenza che compirebbe un giocatore che si affida al salto, ed è la
    /// ragione per cui la misura dei passi dice qualcosa di reale.
    ///
    /// Ogni tanto si ordina il presidio anche potendo marciare, secondo una regola
    /// fissa sul numero della giornata: senza, i gruppi si accalcherebbero tutti
    /// verso nord e la misura vedrebbe una sola situazione.
    /// `partitaCompleta` dice se la corsa è una partita INTERA, giocata fino alla lunghezza
    /// dichiarata: solo allora ha senso pretendere che il giocatore abbia avvistato l'avversario
    /// (01 §5.6.11, incarico 22). Una corsa TRONCATA — il fumo, che chiude a poche giornate per
    /// costare poco — può legittimamente non contenere ancora alcun avvistamento, perché il primo
    /// arriva più tardi: pretenderlo lì sarebbe un falso allarme. Le corse intere (il collaudo, le
    /// prove dedicate) restano il luogo dove l'invariante morde. Preimpostato a vero.
    public func corri(_ voce: ScenariCampagna.Voce, giornate: Int,
                      partitaCompleta: Bool = true) throws -> Corsa {
        var stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: voce.mappa, gruppiGiocatore: voce.gruppi,
                                       gruppiAvversario: voce.gruppiAvversario,
                                       forzeNemiche: voce.forzeNemiche,
                                       struttureDiRifornimento: voce.struttureDiRifornimento),
            valori: valoriCampagna, archetipiNoti: archetipiNoti)
        var violazioni = Set<String>()
        var ordini = 0, marce = 0, marceLunghe = 0, marceCompiute = 0, revoche = 0
        var presidi = 0, senzaDestinazione = 0, divisioni = 0, riunioni = 0
        // La riunione va fatta «ogni tanto» (non a ogni giro): senza questo freno si fondevano
        // tutte le coppie adiacenti nello stesso giorno, disfacendo ogni scenario stipato prima
        // che la condotta ne ordinasse un gruppo — sicché lo STIPAMENTO (un gruppo senza
        // destinazione, `senzaDestinazione`) non si esercitava mai. Una riunione al giorno.
        var giornoUltimaRiunione = Int.min
        // I fenomeni dell'avversario, misurati lungo la corsa.
        let qgGiocatore = stato.mappa.quartierGenerale(di: .giocatore)
        var gruppiAggiranti = Set<IdGruppo>()
        var minDistanzaAvversarioQg = stato.griglia.colonne + stato.griglia.righe + 1
        // I fenomeni del rifornimento. Le soste VOLONTARIE le conta la condotta (è lei a
        // ordinarle); il taglio, la sosta imposta e le riprese si leggono dal registro
        // alla fine, perché sono i fatti non decisi che vi si annotano. I turni-gruppo in
        // zona si contano a ogni giornata. Le strutture isolate si contano allo scenario.
        var sosteVolontarie = 0, passaggiInZona = 0
        // I fenomeni della ricognizione, delle imboscate e delle azioni contro le non armate.
        var esplRiuscite = 0, esplManiVuote = 0, esplNotati = 0, esplPerduti = 0
        var sabArmati = 0, sabEsploratori = 0, sabFalliti = 0, studi = 0
        var imboscatePiazzate = 0, imboscateScattate = 0, imboscateSubite = 0, imboscateScoperte = 0
        // Le BATTAGLIE nate dalla campagna, giocate al banco (incarico 24): quante, con quale
        // esito, e quante da imboscata. Il banco le genera e le gioca, non le rende soltanto possibili.
        var battaglieGiocate = 0, battaglieVinte = 0, battagliePerse = 0, battaglieDaImboscata = 0
        var primoGiornoBattaglia: Int? = nil // il giorno della PRIMA battaglia, per misurare quanto la partita prosegue dopo
        // Gli AVVISTAMENTI di formazioni avversarie da parte del GIOCATORE (01 §5.6.11, incarico 22):
        // quanti, e in quale giornata ciascuno, per misurare se e quando l'avversario si manifesta.
        // La casella OSSERVATA da almeno un gruppo del giocatore in qualche giornata: l'unione dà la
        // porzione di mappa che il giocatore vede davvero muovendosi (raggio di osservazione).
        var avvistamentiGiocatore = 0, giorniAvvistamento: [Int] = []
        var caselleOsservateUnione = Set<Cella>()
        // Le GIORNATE con tutti i gruppi di una parte appostati: insieme di giorni, contato una
        // sola volta ciascuno (il fenomeno del caso limite dell'incarico 20). Solo un gruppo armato
        // può appostarsi, sicché il caso richiede una parte di soli armati, tutti in agguato.
        var giorniTuttiAppostati = Set<Int>()
        func aggiornaTuttiAppostati(_ s: StatoCampagna) {
            for parte in [Parte.giocatore, .avversario] {
                let propri = s.gruppi(di: parte)
                if !propri.isEmpty, propri.allSatisfy({ $0.ordineImboscata }) {
                    giorniTuttiAppostati.insert(s.giorno)
                }
            }
        }
        // Conta i fenomeni prodotti da una serie di eventi, sullo stato PRIMA (per leggere la
        // categoria di chi sabota e la parte di chi ha teso l'agguato, che l'evento non porta).
        // Vale per il giocatore e per l'avversario: lo scatto d'imboscata è fra parti opposte.
        func contaFenomeni(_ eventi: [EventoCampagna], prima: StatoCampagna) {
            for evento in eventi {
                switch evento {
                case .esplorazioneCompiuta(_, _, _, _, let esito):
                    switch esito {
                    case .riuscita: esplRiuscite += 1
                    case .aManiVuote: esplManiVuote += 1
                    case .notati: esplNotati += 1
                    case .perduti: esplPerduti += 1
                    }
                case .sabotaggioCompiuto(let g, _, _, let riuscito):
                    if riuscito {
                        if prima.gruppi[g]?.categoria.eArmata == true { sabArmati += 1 }
                        else { sabEsploratori += 1 }
                    } else { sabFalliti += 1 }
                case .studioCompiuto: studi += 1
                case .imboscataScattata(let casella):
                    imboscateScattate += 1
                    // Chi ha teso l'agguato, letto sullo stato PRIMA (l'evento non lo porta): se è
                    // l'AVVERSARIO, il giocatore vi è caduto — è un'imboscata SUBITA, il fenomeno
                    // «cadere in un agguato non scoperto» dalla parte del giocatore.
                    if prima.gruppi.values.first(where: { $0.posizione == casella && $0.ordineImboscata })?.parte == .avversario {
                        imboscateSubite += 1
                    }
                case .imboscataScoperta(let parte, _):
                    // La scoperta dei propri esploratori (l'evento la porta con la parte): quella
                    // del giocatore è il fenomeno da riportare.
                    if parte == .giocatore { imboscateScoperte += 1 }
                case .formazioneAvversariaAvvistata:
                    // L'avvistamento è sempre del giocatore (prodotto solo dove il giocatore osserva,
                    // 01 §5.6.11): il giorno è quello che si sta chiudendo (`prima.giorno`).
                    avvistamentiGiocatore += 1; giorniAvvistamento.append(prima.giorno)
                default: break
                }
            }
        }
        // La tabella dei volumi per atomo, per l'invariante del volume come somma.
        let volumePerAtomo = motore.valori.archetipi.mapValues { $0.volumePerAtomo }
        // I volumi dei gruppi (costanti in questa unità: la composizione non muta).
        let volumi = stato.gruppiOrdinati.map { motore.volume(di: $0) }
        let volumeMinimo = Int(volumi.min() ?? 0)
        let volumeMassimo = Int(volumi.max() ?? 0)
        violazioni.formUnion(sonda.controlla(stato: stato).map(\.description))

        let giornoIniziale = stato.giorno
        var passiDiSicurezza = 0
        while stato.giorno < giornoIniziale + giornate {
            passiDiSicurezza += 1
            guard passiDiSicurezza <= giornate * (voce.gruppi.count + 4) + 10 else { break }
            // Il PASSAGGIO ALLA BATTAGLIA (incarico 24): se un contatto ha innescato una battaglia in
            // sospeso, la campagna è preclusa finché non si conclude (01 §6.4). Il banco la gioca e ne
            // piega l'esito, poi la campagna riprende. Va PRIMA di generare qualunque comando, che il
            // blocco respingerebbe (la precondizione di `applica` scatterebbe).
            if !stato.battaglieInSospeso.isEmpty {
                let esiti = giocaBattaglieInSospeso(&stato, violazioni: &violazioni)
                battaglieGiocate += esiti.giocate; battaglieVinte += esiti.vinte
                battagliePerse += esiti.perse; battaglieDaImboscata += esiti.daImboscata
                if primoGiornoBattaglia == nil { primoGiornoBattaglia = esiti.primoGiorno }
                continue
            }
            let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)

            // I turni-gruppo passati in una zona di rifornimento: si contano a ogni
            // giro, così che il fenomeno risulti esercitato quando esiste una struttura.
            passaggiInZona += stato.gruppi(di: .giocatore).lazy.filter {
                motore.inZonaDiRifornimento($0.posizione, stato: stato) }.count
            // La porzione di mappa osservata: si accumulano le caselle che i gruppi del giocatore
            // vedono a ogni giornata (raggio di osservazione), per l'unione a fine corsa.
            caselleOsservateUnione.formUnion(motore.caselleOsservate(da: .giocatore, stato: stato))

            // L'invariante del salto si controlla percorrendolo davvero, con la
            // sequenza che la Presentazione userebbe.
            violazioni.formUnion(sonda.controllaSalto(stato: stato,
                                                      sequenza: sequenzaDelSalto(vista, stato))
                .map(\.description))
            // L'invariante della posizione visiva: le posizioni mostrate sono quelle
            // che la Presentazione disegnerebbe, cioè la funzione pura del Motore.
            let mostrate = Dictionary(uniqueKeysWithValues: stato.gruppiInMarcia().map {
                ($0.id, motore.avanzamentoVisivo(giorniCompiuti: $0.marcia!.giorniCompiuti,
                                                 giorniTotali: $0.marcia!.giorniTotali))
            })
            violazioni.formUnion(sonda.controllaPosizioniVisive(
                stato: stato, posizioni: valoriCampagna.marcia.posizioniVisive,
                mostrate: mostrate).map(\.description))

            // La condotta: ogni tanto si REVOCA una marcia in corso, secondo una
            // regola fissa sul giorno, per esercitare la revoca e i suoi invarianti;
            // altrimenti si ordina il prossimo gruppo in attesa, con la prima
            // destinazione valida o il presidio. Deterministica, senza caso.
            let comando: ComandoCampagna
            // La riunione (non è un'azione): ogni tanto due gruppi adiacenti si
            // fondono, purché ne restino almeno due, così da esercitare la regola
            // dell'azione già spesa senza far collassare lo scenario a un gruppo solo.
            if stato.giorno % 4 == 1, stato.giorno != giornoUltimaRiunione, stato.gruppi.count > 2,
               let (a, b) = coppiaRiunibile(stato) {
                comando = .riunione(gruppo: a, con: b)
                riunioni += 1
                giornoUltimaRiunione = stato.giorno
            // La divisione (costa l'azione): ogni tanto un gruppo divisibile stacca il
            // primo reparto in una casella libera, se un nome è disponibile.
            } else if stato.giorno % 7 == 3,
                      let (g, staccati, dest) = divisionePossibile(vista, stato) {
                comando = .divisione(gruppo: g, repartiStaccati: staccati, a: dest)
                divisioni += 1
            } else if stato.giorno % 5 == 2, let marciante = stato.gruppiInMarcia().first {
                comando = .revocaMarcia(gruppo: marciante.id)
                revoche += 1
            } else {
                guard let gruppo = vista.prossimoGruppoInAttesa(dopo: nil) else { break }
                // Le formazioni di RICOGNIZIONE (01 §5.4, §5.10.2, incarico 19): se co-locate con
                // una formazione non armata avversaria, la STUDIANO o la SABOTANO a giorni
                // alterni, per esercitare entrambe le vie; altrimenti ESPLORANO. Non marciano nel
                // banco e non sono soggette al taglio (01 §5.15): il loro costo è il rischio.
                if gruppo.categoria.eRicognizione {
                    if let bersaglio = motore.bersaglioNonArmato(su: gruppo.posizione,
                                                                 parte: .giocatore, stato: stato) {
                        // Prima si STUDIA il bersaglio (che non lo disperde), poi lo si SABOTA:
                        // così una stessa formazione esercita entrambe le vie (01 §5.10.2).
                        let giaStudiato = stato.studiati[.giocatore]?.contains(bersaglio.id) == true
                        comando = giaStudiato
                            ? .sabotaggio(gruppo: gruppo.id)
                            : .studioApprofondito(gruppo: gruppo.id)
                    } else {
                        comando = .esplorazione(gruppo: gruppo.id)
                    }
                }
                // I gruppi ARMATI co-locati con una formazione non armata avversaria la SABOTANO
                // (riesce sempre, 01 §5.10.2); ogni tanto un gruppo armato tende un'IMBOSCATA
                // (01 §5.11), così che, entrando un armato avversario, l'imboscata del GIOCATORE
                // scatti — l'altra metà dello scatto rispetto a quello dell'avversario.
                else if gruppo.categoria.eArmata,
                        motore.bersaglioNonArmato(su: gruppo.posizione, parte: .giocatore, stato: stato) != nil {
                    comando = .sabotaggio(gruppo: gruppo.id)
                }
                // Un gruppo armato con un armato AVVERSARIO adiacente TENDE UN'IMBOSCATA invece di
                // marciargli sopra (01 §5.11, incarico 24): così, quando l'avversario entra, la
                // battaglia nasce da un AGGGUATO — col vantaggio della sorpresa (01 §9.3.2) — e non
                // ordinaria. È ciò che fa GENERARE al banco battaglie da imboscata, non solo possibili.
                else if gruppo.categoria.eArmata, gruppo.sostaDovuta < 2, !gruppo.deveRifornirsi,
                        armatoAvversarioAdiacente(a: gruppo, stato: stato) {
                    comando = .imboscata(gruppo: gruppo.id)
                    imboscatePiazzate += 1
                } else if gruppo.categoria.eArmata, stato.giorno % 6 == 4,
                          gruppo.sostaDovuta < 2, !gruppo.deveRifornirsi {
                    comando = .imboscata(gruppo: gruppo.id)
                    imboscatePiazzate += 1
                }
                // Rifornimento (01 §5.2.2). Un gruppo che DEVE rifornirsi si ferma a
                // rifornirsi: è l'unica azione possibile, e la sosta non si elude. Un
                // gruppo senza provviste, ogni tanto, si ferma di propria iniziativa: è
                // la sosta VOLONTARIA di un turno (autonomia). Un gruppo col rifornimento
                // TAGLIATO presidia, così il taglio matura invece di essere aggirato
                // marciando via — è ciò che fa emergere il taglio, la sosta imposta e la
                // ripresa in modo deterministico, qualunque cosa faccia il resto.
                else if gruppo.deveRifornirsi {
                    comando = .sostaConRaccolta(gruppo: gruppo.id)
                } else if gruppo.turniSenzaProvviste == 1, stato.giorno % 3 == 0 {
                    comando = .sostaConRaccolta(gruppo: gruppo.id)
                    sosteVolontarie += 1
                } else if motore.rifornimentoTagliato(di: gruppo, stato: stato) {
                    comando = .presidio(gruppo: gruppo.id)
                    presidi += 1
                } else {
                    let destinazioni = vista.destinazioniValide(per: gruppo.id)
                    if destinazioni.isEmpty { senzaDestinazione += 1 }
                    if destinazioni.isEmpty || stato.giorno % 3 == 0 {
                        comando = .presidio(gruppo: gruppo.id)
                        presidi += 1
                    } else {
                        let destinazione = destinazioni[gruppo.id.numero % destinazioni.count]
                        // Il comando lo forma l'interrogazione, che vi mette il costo in
                        // giorni prescritto dai dati: nemmeno il banco lo inventa.
                        comando = vista.comandoDiMarcia(per: gruppo.id, a: destinazione)!
                        if case .marcia(_, _, let giorni) = comando, giorni > 1 { marceLunghe += 1 }
                        marce += 1
                    }
                }
            }
            let prima = stato
            let (dopo, eventi) = motore.applica(comando, parte: .giocatore, stato: stato)
            marceCompiute += eventi.reduce(0) {
                if case .marciaCompiuta = $1 { return $0 + 1 } else { return $0 }
            }
            contaFenomeni(eventi, prima: prima)
            violazioni.formUnion(sonda.controlla(prima: prima, comando: comando, dopo: dopo,
                                                 eventi: eventi,
                                                 adiacenti: prima.griglia.adiacenti).map(\.description))
            violazioni.formUnion(sonda.controlla(stato: dopo).map(\.description))
            violazioni.formUnion(sonda.controllaGiocabilita(stato: dopo, ordinabile: { ordinabile($0, stato: dopo) }).map(\.description))
            // L'OCCULTAMENTO dell'imboscata (01 §5.11.1, incarico 21): su una casella con un
            // appostato, la conoscenza dell'altra parte — passata dall'esterno — non è confermato,
            // se non l'ha scoperta. La sonda giudica la conoscenza vera del Motore.
            violazioni.formUnion(sonda.controllaOccultamento(
                stato: dopo, conoscenzaDelNemico: { motore.conoscenza(di: $1, per: $0, stato: dopo) }
            ).map(\.description))
            // L'invariante del volume come somma: il volume riportato è quello che il
            // Motore calcola, la sonda ne verifica la coincidenza con la composizione.
            let volumiRiportati = Dictionary(uniqueKeysWithValues:
                dopo.gruppiOrdinati.map { ($0.id, motore.volume(di: $0)) })
            violazioni.formUnion(sonda.controllaVolumi(
                stato: dopo, volumePerAtomo: volumePerAtomo,
                volumiRiportati: volumiRiportati).map(\.description))
            // L'invariante dell'AVVISTAMENTO (incarico 22): un avvistamento avversario
            // annotato durante la chiusura innescata dal turno del giocatore deve corrispondere
            // a una formazione realmente osservata (§5.6.11). Va controllato anche qui, non solo
            // dopo il turno dell'avversario, perché la cascata di fine giornata — e con essa gli
            // arrivi avversari e i loro avvistamenti — può chiudersi sull'ultimo comando del
            // giocatore. Nessun annuncio deve dichiarare un avvistamento senza la sua formazione.
            violazioni.formUnion(sonda.controllaRegistro(
                prima: prima, dopo: dopo,
                osservataDalGiocatore: { motore.osservata($0, da: .giocatore, stato: dopo) }
            ).map(\.description))
            stato = dopo
            aggiornaTuttiAppostati(stato)
            ordini += 1

            // Il turno dell'AVVERSARIO (01 §5.6.11): appena il giocatore ha concluso, la
            // condotta muove i gruppi avversari passando dalla stessa applicazione. È un
            // ciclo a vuoto negli scenari senza avversario. Ogni suo comando è sorvegliato
            // dagli stessi invarianti di transizione e di stato del giocatore (nessuna
            // regola per una parte sola), più i due nuovi: che la sua vista non veda ciò
            // che non osserva, e che il registro non riveli al giocatore l'ignoto.
            var passiAvv = 0
            let limitePassiAvv = giornate * (voce.gruppi.count + voce.gruppiAvversario.count + 4) + 100
            while stato.gruppiInAttesa(di: .giocatore).isEmpty,
                  stato.battaglieInSospeso.isEmpty, // una battaglia in sospeso ferma anche l'avversario (01 §6.4)
                  !stato.gruppiInAttesa(di: .avversario).isEmpty {
                // Il cancello della TERMINAZIONE (incarico 21): il turno dell'avversario si esaurisce
                // entro un limite dichiarato. Se non lo facesse — il difetto dell'incarico 20 — non
                // si appende un freno che nasconde, ma si REGISTRA una violazione che fa fallire il
                // collaudo, dichiarando lo scenario. Con l'imboscata che consuma l'azione non scatta.
                passiAvv += 1
                if passiAvv > limitePassiAvv {
                    violazioni.insert(SondaInvariantiCampagna.Violazione
                        .partitaNonTerminata(giornate: stato.giorno - giornoIniziale).description)
                    break
                }
                let vistaAvv = motore.vistaAvversario(stato: stato)
                let statoVista = stato
                violazioni.formUnion(sonda.controllaVistaAvversario(
                    stato: statoVista, note: vistaAvv.formazioniGiocatoreNote,
                    osservataDallAvversario: { motore.osservata($0, da: .avversario, stato: statoVista) }
                ).map(\.description))
                guard let comandoAvv = condotta.prossimoComando(vista: vistaAvv) else { break }
                let primaAvv = stato
                let (dopoAvv, eventiAvv) = motore.applica(comandoAvv, parte: .avversario, stato: stato)
                // Una marcia del GIOCATORE può compiersi alla chiusura innescata
                // dall'ultimo comando avversario: la si conta di qui.
                marceCompiute += eventiAvv.reduce(0) {
                    if case .marciaCompiuta = $1 { return $0 + 1 } else { return $0 }
                }
                contaFenomeni(eventiAvv, prima: primaAvv)
                aggiornaTuttiAppostati(dopoAvv)
                violazioni.formUnion(sonda.controlla(prima: primaAvv, comando: comandoAvv, dopo: dopoAvv,
                                                     eventi: eventiAvv,
                                                     adiacenti: primaAvv.griglia.adiacenti).map(\.description))
                violazioni.formUnion(sonda.controlla(stato: dopoAvv).map(\.description))
                violazioni.formUnion(sonda.controllaGiocabilita(stato: dopoAvv, ordinabile: { ordinabile($0, stato: dopoAvv) }).map(\.description))
                violazioni.formUnion(sonda.controllaOccultamento(
                    stato: dopoAvv, conoscenzaDelNemico: { motore.conoscenza(di: $1, per: $0, stato: dopoAvv) }
                ).map(\.description))
                violazioni.formUnion(sonda.controllaRegistro(
                    prima: primaAvv, dopo: dopoAvv,
                    osservataDalGiocatore: { motore.osservata($0, da: .giocatore, stato: dopoAvv) }
                ).map(\.description))
                stato = dopoAvv
            }
            // Le misure dell'avversario, sullo stato dopo il suo turno: quanto si è
            // avvicinato al quartier generale del giocatore, e quali suoi gruppi hanno
            // AGGIRATO la linea (si sono portati più vicini al quartier generale del
            // giocatore di ogni gruppo del giocatore — 01 §5.13).
            let distMinGiocatore = stato.gruppi(di: .giocatore)
                .map { stato.griglia.distanza($0.posizione, qgGiocatore) }.min() ?? Int.max
            for avv in stato.gruppi(di: .avversario) {
                let d = stato.griglia.distanza(avv.posizione, qgGiocatore)
                minDistanzaAvversarioQg = min(minDistanzaAvversarioQg, d)
                if d < distMinGiocatore { gruppiAggiranti.insert(avv.id) }
            }
        }

        // Una battaglia innescata all'ULTIMA giornata va comunque giocata, o l'impronta finale
        // porterebbe una battaglia in sospeso e la campagna resterebbe bloccata a metà.
        if !stato.battaglieInSospeso.isEmpty {
            let esiti = giocaBattaglieInSospeso(&stato, violazioni: &violazioni)
            battaglieGiocate += esiti.giocate; battaglieVinte += esiti.vinte
            battagliePerse += esiti.perse; battaglieDaImboscata += esiti.daImboscata
                if primoGiornoBattaglia == nil { primoGiornoBattaglia = esiti.primoGiorno }
        }
        violazioni.formUnion(sonda.controllaRaggiungibilita(
            griglia: stato.griglia, da: Cella(riga: 1, colonna: 1),
            vicini: stato.griglia.vicini).map(\.description))
        // La TERMINAZIONE (incarico 21): la corsa si è chiusa entro le giornate dichiarate. Con
        // l'imboscata che consuma l'azione (decisione 1) la cascata non corre all'infinito.
        violazioni.formUnion(sonda.controllaTerminazione(
            giorniTrascorsi: stato.giorno - giornoIniziale, limite: giornate).map(\.description))
        // L'AVVISTAMENTO AVVENUTO (incarico 22): in una partita INTERA contro l'avversario la corsa
        // deve aver prodotto almeno un avvistamento del giocatore. Un avversario che non si manifesta
        // mai è il difetto che il titolare vide e il collaudo non colse: ora è un cancello che
        // FALLISCE. Solo sulle partite complete, però: una corsa troncata non ha ancora avuto il
        // tempo del primo avvistamento, e pretenderlo sarebbe un falso allarme.
        violazioni.formUnion(sonda.controllaAvvistamentoAvvenuto(
            avvistamenti: avvistamentiGiocatore,
            conAvversario: partitaCompleta && !voce.gruppiAvversario.isEmpty).map(\.description))

        // Il taglio, la sosta imposta e la ripresa sono i fatti NON decisi che il
        // registro annota (01 §5.17.1): li si conta di là, non dagli eventi, così che
        // la sosta VOLONTARIA — che è un ordine e non si annota — non vi si confonda.
        var tagli = 0, sosteImposte = 0, riprese = 0
        for voce in stato.registro {
            switch voce.fatto {
            case .rifornimentoInterrotto: tagli += 1
            case .sostaDiRifornimento: sosteImposte += 1
            case .rifornimentoRipreso: riprese += 1
            default: break
            }
        }
        // Le strutture ISOLATE allo scenario: nessun proprio gruppo, all'inizio, nelle
        // nove caselle della zona (01 §5.2.2.7). Riforniscono comunque, e la prova che
        // la corsa le esercita è che esistono e che i turni-gruppo in zona sono positivi.
        let posizioniIniziali = Set(voce.gruppi.map { Cella(riga: $0.riga, colonna: $0.colonna) })
        let struttureIsolate = voce.struttureDiRifornimento.filter { struttura in
            !posizioniIniziali.contains { max(abs($0.riga - struttura.riga),
                                              abs($0.colonna - struttura.colonna)) <= 1 }
        }.count

        // I tagli del giocatore CAUSATI dall'avversario: negli scenari con avversario e
        // senza forze ferme, nessun'altra forza può stargli alle spalle, sicché ogni suo
        // taglio è opera dell'avversario. Zero altrove.
        let tagliDaAvversario = (!voce.gruppiAvversario.isEmpty && voce.forzeNemiche.isEmpty) ? tagli : 0

        let totCelle = stato.griglia.righe * stato.griglia.colonne
        // Il GAP MEDIO fra un avvistamento e il successivo: la media dei salti di giornata, intera
        // per troncamento, definita solo con almeno due avvistamenti (con uno solo non c'è intervallo).
        var gaps: [Int] = []
        for i in 1..<max(1, giorniAvvistamento.count) { gaps.append(giorniAvvistamento[i] - giorniAvvistamento[i-1]) }
        let gapMedio = gaps.isEmpty ? nil : gaps.reduce(0, +) / gaps.count
        return Corsa(identificatore: voce.identificatore, mappa: voce.mappa,
                     gruppi: voce.gruppi.count, giornate: stato.giorno - giornoIniziale,
                     ordini: ordini, marce: marce, marceLunghe: marceLunghe,
                     marceCompiute: marceCompiute, revoche: revoche, presidi: presidi,
                     divisioni: divisioni, riunioni: riunioni,
                     senzaDestinazione: senzaDestinazione,
                     volumeMinimo: volumeMinimo, volumeMassimo: volumeMassimo,
                     tagli: tagli, sosteImposte: sosteImposte, sosteVolontarie: sosteVolontarie,
                     riprese: riprese, passaggiInZona: passaggiInZona,
                     struttureIsolate: struttureIsolate,
                     gruppiAvversario: voce.gruppiAvversario.count,
                     tagliDaAvversario: tagliDaAvversario,
                     aggiramenti: gruppiAggiranti.count,
                     minDistanzaAvversarioQg: minDistanzaAvversarioQg,
                     esplorazioniRiuscite: esplRiuscite, esplorazioniAManiVuote: esplManiVuote,
                     esploratoriNotati: esplNotati, esploratoriPerduti: esplPerduti,
                     sabotaggiArmati: sabArmati, sabotaggiEsploratori: sabEsploratori,
                     sabotaggiFalliti: sabFalliti, studi: studi,
                     imboscatePiazzate: imboscatePiazzate, imboscateScattate: imboscateScattate,
                     imboscateSubite: imboscateSubite, imboscateScoperte: imboscateScoperte,
                     battaglieGiocate: battaglieGiocate, battaglieVinte: battaglieVinte,
                     battagliePerse: battagliePerse, battaglieDaImboscata: battaglieDaImboscata,
                     giornateDopoLaPrimaBattaglia: primoGiornoBattaglia.map { stato.giorno - $0 } ?? 0,
                     giornateTuttiAppostati: giorniTuttiAppostati.count,
                     avvistamenti: avvistamentiGiocatore,
                     primoAvvistamento: giorniAvvistamento.first,
                     gapMedioAvvistamenti: gapMedio,
                     caselleOsservate: caselleOsservateUnione.count,
                     caselleTotali: totCelle,
                     violazioni: violazioni.sorted(), improntaFinale: stato.impronta())
    }

    /// Due gruppi propri adiacenti e NON in marcia, per la riunione, il primo per id.
    /// La riunione lavora su qualunque coppia adiacente, quale che sia lo stato
    /// dell'azione: è così che si esercita la regola «già agito se uno lo era».
    private func coppiaRiunibile(_ stato: StatoCampagna) -> (IdGruppo, IdGruppo)? {
        // Solo i gruppi del GIOCATORE: la condotta del banco muove il giocatore, e una
        // riunione impartita per suo conto su gruppi avversari sarebbe invalida.
        let gruppi = stato.gruppi(di: .giocatore).filter { !$0.inMarcia }
        for i in gruppi.indices {
            for j in gruppi.indices
            where j > i && stato.griglia.adiacenti(gruppi[i].posizione, gruppi[j].posizione) {
                return (gruppi[i].id, gruppi[j].id)
            }
        }
        return nil
    }

    /// Un gruppo in attesa con almeno due reparti, una casella libera adiacente e un
    /// nome disponibile: stacca il PRIMO reparto verso quella casella. La casella
    /// libera si prende da `destinazioniValide`, cioè le adiacenti libere e non già
    /// puntate — lo stesso vincolo del distaccamento (01 §5.6.0.2).
    private func divisionePossibile(_ vista: VistaCampagna,
                                    _ stato: StatoCampagna) -> (IdGruppo, [Int], Cella)? {
        guard stato.prossimoIndiceNome < valoriCampagna.nomiGruppi.count else { return nil }
        for gruppo in stato.gruppiInAttesa() where gruppo.composizione.count >= 2 {
            if let dest = vista.destinazioniValide(per: gruppo.id).first {
                return (gruppo.id, [0], dest)
            }
        }
        return nil
    }

    /// La sequenza che il salto diretto propone percorrendolo fino a tornare al
    /// primo: è ciò che il giocatore ottiene ripetendo il gesto.
    public func sequenzaDelSalto(_ vista: VistaCampagna, _ stato: StatoCampagna) -> [IdGruppo] {
        var sequenza: [IdGruppo] = []
        var corrente: Cella? = nil
        let quanti = stato.gruppiInAttesa().count
        for _ in 0..<quanti {
            guard let prossimo = vista.prossimoGruppoInAttesa(dopo: corrente) else { break }
            sequenza.append(prossimo.id)
            corrente = prossimo.posizione
        }
        return sequenza
    }

    // MARK: - Misura: passi per chiudere una giornata

    /// Quanti passi costa chiudere una giornata al crescere del numero dei gruppi.
    /// È la misura più importante, perché è il costo che paga chi ascolta invece
    /// di guardare: chi guarda vede tutta la mappa in un colpo d'occhio.
    ///
    /// Il modello dei passi è dichiarato ed è il seguente. Con il salto diretto,
    /// ordinare un gruppo costa tre passi: il gesto di salto, l'attivazione della
    /// casella, la scelta della voce nel pannello. Senza il salto, al posto del
    /// gesto di salto occorre percorrere a scorrimenti la distanza nell'ordine di
    /// lettura fra la casella dove si è e quella del gruppo successivo. Il conteggio
    /// riguarda il presidio, che è l'azione più breve: isola così il costo della
    /// NAVIGAZIONE, che è ciò che la misura vuole vedere.
    /// Come i gruppi stanno sulla mappa quando la misura è presa. Le due
    /// disposizioni non sono un dettaglio: la prima giornata di una campagna ha i
    /// gruppi tutti presso il quartier generale, e dopo qualche giornata di marcia
    /// li ha sparsi. Se il costo dipendesse dalla dispersione e non dal numero, una
    /// misura sola non lo direbbe.
    public enum Disposizione: String, Sendable, CaseIterable {
        /// Ammassati intorno al proprio quartier generale, nell'ordine di lettura.
        case raccolti
        /// A distanza pari lungo l'ordine di lettura, dalla prima all'ultima casella.
        case sparpagliati
    }

    public struct Passi: Sendable {
        public let gruppi: Int
        public let mappa: IdentificatoreDati
        public let disposizione: Disposizione
        public let conIlSalto: Int
        public let senzaIlSalto: Int
    }

    static let passiPerOrdine = 2 // attivazione della casella, scelta della voce
    static let passiDelSalto = 1

    /// Le caselle su cui disporre i gruppi, per disposizione. Deterministica: la
    /// stessa richiesta dà sempre le stesse caselle.
    static func caselleDellaDisposizione(_ disposizione: Disposizione, gruppi: Int,
                                         griglia: GrigliaCampagna,
                                         quartierGenerale: Cella) -> [Cella]? {
        let tutte = griglia.tutteLeCaselle
        guard gruppi >= 1, gruppi <= tutte.count else { return nil }
        switch disposizione {
        case .sparpagliati:
            let caselle: [Cella] = gruppi == 1
                ? [tutte[tutte.count / 2]]
                : (0..<gruppi).map { tutte[$0 * (tutte.count - 1) / (gruppi - 1)] }
            return Set(caselle).count == gruppi ? caselle : nil
        case .raccolti:
            // Le più vicine al proprio quartier generale, a parità di distanza
            // nell'ordine di lettura: è la configurazione di apertura di campagna.
            let caselle = tutte.sorted {
                let da = griglia.distanza(quartierGenerale, $0)
                let db = griglia.distanza(quartierGenerale, $1)
                return da == db ? $0 < $1 : da < db
            }.prefix(gruppi)
            return Array(caselle).sorted()
        }
    }

    public func misuraPassi(mappa identificatore: IdentificatoreDati, gruppi: Int,
                            disposizione: Disposizione) throws -> Passi? {
        guard let definizione = valoriCampagna.mappe[identificatore],
              let formato = valoriCampagna.formatiMappa[definizione.formato] else { return nil }
        let griglia = GrigliaCampagna(righe: formato.righe, colonne: formato.colonne)
        let quartierGenerale = Cella(riga: definizione.quartierGenerali.giocatore.riga,
                                     colonna: definizione.quartierGenerali.giocatore.colonna)
        guard let caselle = Self.caselleDellaDisposizione(
            disposizione, gruppi: gruppi, griglia: griglia,
            quartierGenerale: quartierGenerale) else { return nil }
        let stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(
                mappa: identificatore,
                gruppiGiocatore: caselle.map {
                    .init(riga: $0.riga, colonna: $0.colonna,
                          composizione: Self.composizioneDiMisura) }),
            valori: valoriCampagna, archetipiNoti: archetipiNoti)

        let ordine = griglia.tutteLeCaselle
        func indice(_ casella: Cella) -> Int { ordine.firstIndex(of: casella) ?? 0 }
        let posizioni = stato.gruppiInAttesa().map(\.posizione)

        let conIlSalto = gruppi * (Self.passiDelSalto + Self.passiPerOrdine)
        // Senza il salto si parte dalla prima casella della mappa e si scorre.
        var senza = 0
        var corrente = 0
        for posizione in posizioni {
            senza += abs(indice(posizione) - corrente) + Self.passiPerOrdine
            corrente = indice(posizione)
        }
        return Passi(gruppi: gruppi, mappa: identificatore, disposizione: disposizione,
                     conIlSalto: conIlSalto, senzaIlSalto: senza)
    }

    // MARK: - Misura: distanza fra i due quartier generali

    /// Quanto distano fra loro i due quartier generali, e quante giornate costa
    /// congiungerli marciando ogni giorno. Si gioca davvero: il numero esce dalle
    /// regole e non da una formula scritta qui.
    ///
    /// La grandezza misurata è la DISTANZA FRA I DUE QUARTIER GENERALI e non
    /// l'attraversamento della mappa, che è un'altra cosa e vale di più: sul
    /// formato quattro per quattro i due quartier generali distano tre caselle,
    /// mentre la distanza massima fra due caselle qualunque è sei. È la stessa
    /// classe di errore già corretta sulle caselle con meno di quattro uscite —
    /// una grandezza chiamata con il nome di un'altra — e per questo le due
    /// compaiono ora affiancate, così che nessuna delle due possa essere letta
    /// per l'altra.
    public struct DistanzaFraQuartierGenerali: Sendable {
        public let mappa: IdentificatoreDati
        public let formato: IdentificatoreDati
        public let lato: Int
        /// La distanza ortogonale fra il proprio quartier generale e quello avverso.
        public let distanzaFraQuartierGenerali: Int
        /// La distanza massima fra due caselle qualunque della mappa: la traversata
        /// effettiva, cioè da un angolo all'angolo opposto.
        public let distanzaMassimaFraDueCaselle: Int
        /// Le giornate spese a congiungerli marciando ogni giorno.
        public let giornatePerCongiungerli: Int
    }

    public func misuraDistanzaFraQuartierGenerali(mappa identificatore: IdentificatoreDati) throws
        -> DistanzaFraQuartierGenerali? {
        guard let definizione = valoriCampagna.mappe[identificatore],
              let formato = valoriCampagna.formatiMappa[definizione.formato] else { return nil }
        let partenza = Cella(riga: definizione.quartierGenerali.giocatore.riga,
                             colonna: definizione.quartierGenerali.giocatore.colonna)
        let arrivo = Cella(riga: definizione.quartierGenerali.avversario.riga,
                           colonna: definizione.quartierGenerali.avversario.colonna)
        var stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: identificatore,
                                       gruppiGiocatore: [.init(riga: partenza.riga,
                                                               colonna: partenza.colonna,
                                                               composizione: Self.composizioneDiMisura)]),
            valori: valoriCampagna, archetipiNoti: archetipiNoti)
        let id = stato.gruppiOrdinati[0].id
        let giornoIniziale = stato.giorno
        var passi = 0
        let tetto = stato.griglia.righe * stato.griglia.colonne + 2
        while stato.gruppi[id]!.posizione != arrivo, passi < tetto {
            passi += 1
            let qui = stato.gruppi[id]!.posizione
            // Rotta deterministica: prima si pareggia la riga, poi la colonna.
            let prossima = qui.riga != arrivo.riga
                ? Cella(riga: qui.riga + (arrivo.riga > qui.riga ? 1 : -1), colonna: qui.colonna)
                : Cella(riga: qui.riga, colonna: qui.colonna + (arrivo.colonna > qui.colonna ? 1 : -1))
            let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
            guard let comando = vista.comandoDiMarcia(per: id, a: prossima),
                  motore.valida(comando, parte: .giocatore, stato: stato).eValido else { break }
            (stato, _) = motore.applica(comando, parte: .giocatore, stato: stato)
        }
        let griglia = stato.griglia
        return DistanzaFraQuartierGenerali(
            mappa: identificatore, formato: definizione.formato, lato: formato.righe,
            distanzaFraQuartierGenerali: griglia.distanza(partenza, arrivo),
            distanzaMassimaFraDueCaselle: griglia.distanza(
                Cella(riga: 1, colonna: 1), Cella(riga: griglia.righe, colonna: griglia.colonne)),
            giornatePerCongiungerli: stato.giorno - giornoIniziale)
    }

    // MARK: - Misura: caselle raggiungibili in una giornata

    /// Quante caselle sono raggiungibili in una giornata da ciascuna casella della
    /// mappa. Con una sola azione per gruppo e lo scatto di una casella, sono i
    /// vicini ortogonali LIBERI.
    ///
    /// Le uscite libere e le caselle di bordo sono due grandezze DIVERSE, e la
    /// misura le tiene separate perché il resoconto della prima unità le aveva
    /// confuse. Il bordo è geometria e non cambia mai; le uscite libere dipendono
    /// da dove stanno i gruppi, perché una casella occupata da una propria
    /// formazione non è disponibile (01 §5.6.0.2). Una casella interna adiacente a
    /// un proprio gruppo ha quattro vicine e tre uscite: è interna e ha meno di
    /// quattro uscite, e chiamarla «di bordo» è sbagliato.
    public struct UsciteLibere: Sendable {
        public let mappa: IdentificatoreDati
        public let distribuzione: Distribuzione
        /// Geometria pura: le caselle su un lato della mappa. Non dipende dai gruppi.
        public let caselleDiBordo: Int
        /// Geometria pura: il complemento del bordo.
        public let caselleInterne: Int
        /// Occupazione: le caselle da cui, nella configurazione misurata, si esce
        /// verso meno di quattro caselle libere.
        public let conMenoDiQuattroUscite: Int
        /// Di quelle, quante sono INTERNE, cioè quante devono la propria strettezza
        /// alla presenza di un gruppo e non alla forma della mappa.
        public let interneConMenoDiQuattroUscite: Int
        /// I gruppi presenti nella configurazione con cui la misura è presa.
        public let gruppiPresenti: Int
    }

    public func misuraUsciteLibere(mappa identificatore: IdentificatoreDati) throws
        -> UsciteLibere? {
        guard let definizione = valoriCampagna.mappe[identificatore] else { return nil }
        let stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(
                mappa: identificatore,
                gruppiGiocatore: [.init(riga: definizione.quartierGenerali.giocatore.riga,
                                        colonna: definizione.quartierGenerali.giocatore.colonna,
                                        composizione: Self.composizioneDiMisura)]),
            valori: valoriCampagna, archetipiNoti: archetipiNoti)
        let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
        let griglia = stato.griglia
        func diBordo(_ c: Cella) -> Bool {
            c.riga == 1 || c.riga == griglia.righe || c.colonna == 1 || c.colonna == griglia.colonne
        }
        let conteggi = griglia.tutteLeCaselle.map {
            vista.usciteLibere(da: $0).count
        }
        let strette = griglia.tutteLeCaselle.filter {
            vista.usciteLibere(da: $0).count < 4
        }
        return UsciteLibere(mappa: identificatore,
                             distribuzione: Distribuzione(conteggi),
                             caselleDiBordo: griglia.tutteLeCaselle.filter(diBordo).count,
                             caselleInterne: griglia.tutteLeCaselle.filter { !diBordo($0) }.count,
                             conMenoDiQuattroUscite: strette.count,
                             interneConMenoDiQuattroUscite: strette.filter { !diBordo($0) }.count,
                             gruppiPresenti: stato.gruppi.count)
    }
}
