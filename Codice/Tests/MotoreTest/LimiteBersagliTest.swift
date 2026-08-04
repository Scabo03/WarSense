import XCTest
import Motore
import Dati
import Contenuti

/// Il limite dei bersagli simultanei (01 §9.11): un reparto risponde ad al massimo
/// due nemici — al primo per intero, al secondo con resa ridotta, dal terzo in poi
/// per nulla — e i posti si contano dall'ordine di arrivo del contatto.
/// Ogni prova cita per numero la regola che verifica e misura sui giri davvero risolti.
final class LimiteBersagliTest: XCTestCase {

    var valori: ValoriDiGioco!
    var motore: MotoreBattaglia!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreBattaglia(valori: valori)
    }

    // MARK: - Attrezzi

    struct Posto {
        let parte: Parte
        let archetipo: IdentificatoreDati
        let protezione: TipoProtezione
        let cella: Cella
    }

    /// I sei vicini della cella centrale usata come bersaglio, in ordine fisso.
    static let bersaglio = Cella(riga: 5, colonna: 5)
    static let intorno = [Cella(riga: 6, colonna: 5), Cella(riga: 6, colonna: 4),
                          Cella(riga: 5, colonna: 4), Cella(riga: 5, colonna: 6),
                          Cella(riga: 4, colonna: 5), Cella(riga: 4, colonna: 4)]

    func campo(_ posti: [Posto], parteDiTurno: Parte = .giocatore) throws -> (StatoBattaglia, [IdSciame]) {
        let riserva = ScenarioBattaglia.ElementoScenario(
            archetipo: "fanteria_leggera", protezione: .antiSaturazione, atomi: 5, esemplari: 1)
        let scenario = ScenarioBattaglia(formato: "cento", caratteristica: "campo_aperto",
                                         primoOccupante: parteDiTurno, imboscata: false,
                                         deckGiocatore: [riserva], deckAvversario: [riserva])
        var stato = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
        var ids: [IdSciame] = []
        for posto in posti {
            let id = IdSciame(stato.prossimoIdSciame)
            stato.prossimoIdSciame += 1
            let lettera = stato.prossimaLettera[posto.parte] ?? 1
            stato.prossimaLettera[posto.parte] = lettera + 1
            let a = valori.archetipi[posto.archetipo]!
            stato.sciami[id] = Sciame(id: id, parte: posto.parte, archetipo: posto.archetipo,
                                      protezione: posto.protezione, lettera: lettera,
                                      atomiIniziali: 5, serbatoio: 5 * a.puntiVitaPerAtomo,
                                      munizioni: a.dotazioneMunizioni, posizione: posto.cella,
                                      azioneSpesa: false, rinforzo: false)
            stato.forzeImpegnate[posto.parte, default: 0] += 5 * a.puntiVitaPerAtomo
            ids.append(id)
        }
        return (stato, ids)
    }

    /// Un bersaglio avversario circondato da `quanti` assalitori del giocatore.
    /// Dalla risoluzione immediata (01 §9.7.1) ogni ingaggio scambia i colpi
    /// all'istante: la fotografia si prende PRIMA di ingaggiare, e ogni ingaggio
    /// si valida, perché uno scambio già avvenuto può renderne impossibile un altro.
    func mischia(assalitori quanti: Int, ordineIngaggio: [Int]? = nil,
                 archetipoAssalitore: IdentificatoreDati = "fanteria_pesante")
        throws -> (StatoBattaglia, [IdSciame], IdSciame, [IdSciame: Int64]) {
        var (stato, ids) = try campo(
            (0..<quanti).map { Posto(parte: .giocatore, archetipo: archetipoAssalitore,
                                     protezione: .antiSaturazione, cella: Self.intorno[$0]) }
            + [Posto(parte: .avversario, archetipo: "guardia_elite",
                     protezione: .antiSaturazione, cella: Self.bersaglio)])
        let idBersaglio = ids.removeLast()
        let prima = stato.sciami.mapValues(\.serbatoio)
        for indice in ordineIngaggio ?? Array(0..<quanti) {
            let comando = ComandoBattaglia.ingaggia(sciame: ids[indice], bersaglio: idBersaglio)
            guard motore.valida(comando, parte: .giocatore, stato: stato).eValido else { continue }
            stato = motore.applica(comando, parte: .giocatore, stato: stato).0
        }
        return (stato, ids, idBersaglio, prima)
    }

    /// Il danno subito da ciascuno nell'INTERO primo scambio: gli ingaggi, che si
    /// risolvono all'istante, più la risoluzione d'inizio giro.
    func subitiNelPrimoScambio(_ stato: StatoBattaglia, prima: [IdSciame: Int64]) -> [IdSciame: Int64] {
        var lavoro = stato
        for _ in 0..<2 {
            guard lavoro.esito == nil else { break }
            lavoro = motore.applica(.fineTurno, parte: lavoro.parteDiTurno, stato: lavoro).0
        }
        return prima.reduce(into: [:]) { esito, voce in
            esito[voce.key] = voce.value - (lavoro.sciami[voce.key]?.serbatoio ?? 0)
        }
    }

    /// Il danno subito nel solo giro successivo, a partire dallo stato dato.
    func subitiInUnGiro(_ stato: StatoBattaglia) -> [IdSciame: Int64] {
        subitiNelPrimoScambio(stato, prima: stato.sciami.mapValues(\.serbatoio))
    }

    // MARK: - I tre posti (01 §9.11)

    /// Il primo arrivato riceve risposta piena, il secondo ridotta, il terzo e il
    /// quarto nessuna. Misurato sul giro risolto, non sui coefficienti.
    func test_01_9_11_al_primo_piena_al_secondo_ridotta_dal_terzo_nessuna() throws {
        let (stato, assalitori, _, prima) = try mischia(assalitori: 4)
        let subiti = subitiNelPrimoScambio(stato, prima: prima)
        let primo = subiti[assalitori[0]] ?? 0
        let secondo = subiti[assalitori[1]] ?? 0
        let terzo = subiti[assalitori[2]] ?? 0
        let quarto = subiti[assalitori[3]] ?? 0

        XCTAssertGreaterThan(primo, 0, "il primo arrivato è fronteggiato a piena resa")
        XCTAssertGreaterThan(secondo, 0, "il secondo riceve una risposta, ridotta")
        XCTAssertLessThan(secondo, primo, "la risposta al secondo è ridotta dal malus dei dati")
        XCTAssertEqual(terzo, 0, "dal terzo in poi non c'è risposta alcuna (01 §9.11.2)")
        XCTAssertEqual(quarto, 0, "e nemmeno al quarto")
        print("MISURA posti in mischia: primo \(primo), secondo \(secondo), terzo \(terzo), quarto \(quarto)")
    }

    /// Il malus del secondo è esattamente quello dei dati e non una cifra nel codice.
    func test_00_13_1_il_malus_del_secondo_viene_dai_dati() throws {
        XCTAssertEqual(motore.resaDiRisposta(posto: 0), .uno)
        XCTAssertEqual(motore.resaDiRisposta(posto: 1), valori.combattimento.resaControSecondoBersaglio)
        XCTAssertNil(motore.resaDiRisposta(posto: 2), "niente risposta, non una risposta nulla")
        XCTAssertNil(motore.resaDiRisposta(posto: 7))
        // Il caso senza risposta non ricade nel minimo obbligatorio di 00 §13.6:
        // il danno non è ridotto a zero, semplicemente non viene calcolato.
        let (stato, assalitori, _, prima) = try mischia(assalitori: 3)
        XCTAssertEqual(subitiNelPrimoScambio(stato, prima: prima)[assalitori[2]] ?? -1, 0)
        XCTAssertGreaterThanOrEqual(valori.minimi.dannoMinimo, 1, "il minimo esiste ed è aggirato di proposito")
    }

    /// Chi colpisce senza ricevere risposta infligge comunque il proprio danno pieno:
    /// il limite riguarda la risposta, non l'offesa di chi arriva (01 §9.11).
    func test_01_9_11_chi_non_riceve_risposta_infligge_ugualmente() throws {
        let (statoTre, _, bersaglioTre, primaTre) = try mischia(assalitori: 3)
        let (statoDue, _, bersaglioDue, primaDue) = try mischia(assalitori: 2)
        let inflittoDaTre = subitiNelPrimoScambio(statoTre, prima: primaTre)[bersaglioTre] ?? 0
        let inflittoDaDue = subitiNelPrimoScambio(statoDue, prima: primaDue)[bersaglioDue] ?? 0
        XCTAssertGreaterThan(inflittoDaTre, inflittoDaDue,
                             "il terzo arrivato colpisce, pur non essendo colpito di ritorno")
    }

    // MARK: - Il criterio è l'ordine di arrivo (01 §9.11.1)

    /// I posti seguono l'ordine di arrivo del contatto, non la potenza né la
    /// posizione: scambiando l'ordine degli ingaggi si scambiano le risposte.
    func test_01_9_11_1_il_posto_segue_l_ordine_di_arrivo_e_non_la_potenza() throws {
        // Tre assalitori identici: se contasse la potenza o la posizione, l'ordine
        // degli ingaggi non cambierebbe nulla. Cambia.
        let (dritto, assalitoriDritto, _, primaDritto) = try mischia(assalitori: 3, ordineIngaggio: [0, 1, 2])
        let (rovescio, assalitoriRovescio, _, primaRovescio) = try mischia(assalitori: 3, ordineIngaggio: [2, 1, 0])
        let a = subitiNelPrimoScambio(dritto, prima: primaDritto)
        let b = subitiNelPrimoScambio(rovescio, prima: primaRovescio)
        XCTAssertGreaterThan(a[assalitoriDritto[0]] ?? 0, 0, "chi ingaggia per primo è fronteggiato")
        XCTAssertEqual(a[assalitoriDritto[2]] ?? -1, 0, "chi ingaggia per terzo non riceve risposta")
        XCTAssertGreaterThan(b[assalitoriRovescio[2]] ?? 0, 0, "a ordine rovesciato è il terzo a essere fronteggiato")
        XCTAssertEqual(b[assalitoriRovescio[0]] ?? -1, 0, "e il primo a restare fuori")
        // Il posto è calcolabile dal solo stato.
        XCTAssertEqual(motore.postoInMischia(di: assalitoriDritto[0], contro: IdSciame(4), stato: dritto), 0)
    }

    /// Il posto non dipende dall'ordine in cui i danni si applicano nella risoluzione
    /// simultanea: si ricava dallo stato d'ingresso del giro ed è identico per tutti
    /// i contatti risolti in quel giro (01 §9.11.1).
    func test_01_9_11_1_i_posti_non_dipendono_dall_ordine_di_applicazione() throws {
        let (stato, assalitori, bersaglio, prima) = try mischia(assalitori: 3)
        _ = prima
        // Dallo stato d'ingresso: il bersaglio vede i tre nei posti 0, 1, 2.
        for (atteso, assalitore) in assalitori.enumerated() {
            XCTAssertEqual(motore.postoInMischia(di: bersaglio, contro: assalitore, stato: stato), atteso)
            // E ciascun assalitore vede il bersaglio al proprio posto zero: ha un contatto solo.
            XCTAssertEqual(motore.postoInMischia(di: assalitore, contro: bersaglio, stato: stato), 0)
        }
        // I danni del giro corrispondono ESATTAMENTE ai posti letti dallo stato
        // d'ingresso: nessun altro fattore vi entra, e in particolare non l'ordine
        // interno di risoluzione, che il Motore percorre per identificatore mentre
        // i posti seguono l'arrivo.
        let difensore = stato.sciami[bersaglio]!
        let offesa = valori.archetipi[difensore.archetipo]!.offesaMischia
        let subiti = subitiInUnGiro(stato)
        for (posto, assalitore) in assalitori.enumerated() {
            let atteso: Int64
            if let resa = motore.resaDiRisposta(posto: posto) {
                atteso = motore.danno(da: difensore, offesa: offesa, a: stato.sciami[assalitore]!,
                                      coefficiente: resa * motore.coefficienteAccerchiamento(
                                          concorrenti: motore.concorrenti(contro: assalitore,
                                                                          stato: stato).count),
                                      stato: stato)
            } else {
                atteso = 0
            }
            XCTAssertEqual(subiti[assalitore] ?? -1, atteso,
                           "posto \(posto): il danno è quello che il posto d'ingresso prescrive")
        }
    }

    // MARK: - Successione nei posti liberati (01 §9.11.2)

    /// Quando chi occupava un posto esce di scena, i posti dietro scorrono in avanti
    /// da sé, senza alcuna decisione del giocatore: il terzo diventa secondo e poi
    /// primo. La regola è una sola e vale per ENTRAMBI i posti, non solo per il primo.
    func test_01_9_11_2_i_posti_liberati_scorrono_da_se() throws {
        let (stato, assalitori, bersaglio, _) = try mischia(assalitori: 3)
        XCTAssertEqual(motore.postoInMischia(di: bersaglio, contro: assalitori[2], stato: stato), 2)

        // Esce il PRIMO: il secondo avanza al primo posto, il terzo al secondo.
        var senzaPrimo = stato
        senzaPrimo.sciami[assalitori[0]] = nil
        senzaPrimo.contatti.removeAll { $0.coinvolge(assalitori[0]) }
        XCTAssertEqual(motore.postoInMischia(di: bersaglio, contro: assalitori[1], stato: senzaPrimo), 0)
        XCTAssertEqual(motore.postoInMischia(di: bersaglio, contro: assalitori[2], stato: senzaPrimo), 1)

        // Esce il SECONDO: il terzo avanza al secondo posto, con la stessa regola.
        var senzaSecondo = stato
        senzaSecondo.sciami[assalitori[1]] = nil
        senzaSecondo.contatti.removeAll { $0.coinvolge(assalitori[1]) }
        XCTAssertEqual(motore.postoInMischia(di: bersaglio, contro: assalitori[0], stato: senzaSecondo), 0)
        XCTAssertEqual(motore.postoInMischia(di: bersaglio, contro: assalitori[2], stato: senzaSecondo), 1)

        // E il terzo, salito al secondo posto, riceve davvero la risposta ridotta.
        let subiti = subitiInUnGiro(senzaSecondo)
        XCTAssertGreaterThan(subiti[assalitori[2]] ?? 0, 0, "chi era terzo ora riceve risposta")
        XCTAssertLessThan(subiti[assalitori[2]] ?? 0, subiti[assalitori[0]] ?? 0, "ridotta, non piena")
    }

    /// La successione avviene anche quando il posto si libera per disfacimento
    /// durante la risoluzione, senza che il giocatore possa deciderlo: chi è in
    /// mischia è fuori controllo (01 §9.5).
    func test_01_9_11_2_la_successione_non_e_una_decisione_del_giocatore() throws {
        // Due assalitori, perché il bersaglio sopravviva al primo scambio: con tre
        // la risoluzione immediata di 01 §9.7.1 lo disfa e non resta nessuna mischia
        // in cui succedere.
        var (stato, assalitori, bersaglio, _) = try mischia(assalitori: 2)
        // Il primo arrivato è ridotto al lumicino: cadrà nel giro e lascerà il posto.
        stato.sciami[assalitori[0]]!.serbatoio = 1
        XCTAssertEqual(motore.postoInMischia(di: bersaglio, contro: assalitori[1], stato: stato), 1)
        for _ in 0..<2 {
            guard stato.esito == nil else { break }
            stato = motore.applica(.fineTurno, parte: stato.parteDiTurno, stato: stato).0
        }
        XCTAssertNil(stato.sciami[assalitori[0]], "il primo è caduto")
        XCTAssertEqual(motore.postoInMischia(di: bersaglio, contro: assalitori[1], stato: stato), 0,
                       "il secondo è avanzato da sé al primo posto, senza alcun comando")
    }

    // MARK: - Simmetria fra le parti (01 §9.11)

    /// La regola vale per entrambe le parti senza eccezioni.
    func test_01_9_11_la_regola_vale_per_entrambe_le_parti() throws {
        func subiti(assalitoriDi parte: Parte) throws -> [Int64] {
            var (stato, ids) = try campo(
                (0..<3).map { Posto(parte: parte, archetipo: "fanteria_pesante",
                                    protezione: .antiSaturazione, cella: Self.intorno[$0]) }
                + [Posto(parte: parte.avversaria, archetipo: "guardia_elite",
                         protezione: .antiSaturazione, cella: Self.bersaglio)],
                parteDiTurno: parte)
            let idBersaglio = ids.removeLast()
            for id in ids {
                stato = motore.applica(.ingaggia(sciame: id, bersaglio: idBersaglio),
                                       parte: parte, stato: stato).0
            }
            let mappa = subitiInUnGiro(stato)
            return ids.map { mappa[$0] ?? 0 } + [mappa[idBersaglio] ?? 0]
        }
        XCTAssertEqual(try subiti(assalitoriDi: .giocatore), try subiti(assalitoriDi: .avversario))
    }

    /// Un reparto impegnato su due fronti rende per intero al primo e ridotto al
    /// secondo anche quando i due nemici arrivano da parti diverse della linea:
    /// il limite è del reparto, non della cella.
    func test_01_9_11_il_limite_e_del_reparto_e_vale_anche_attaccando() throws {
        // Un solo reparto del giocatore fra due avversari: ingaggia il primo, poi
        // viene ingaggiato dal secondo. Contro il primo rende pieno, contro il secondo ridotto.
        var (stato, ids) = try campo([
            Posto(parte: .giocatore, archetipo: "fanteria_pesante",
                  protezione: .antiSaturazione, cella: Cella(riga: 5, colonna: 5)),
            Posto(parte: .avversario, archetipo: "guardia_elite",
                  protezione: .antiSaturazione, cella: Cella(riga: 5, colonna: 4)),
            Posto(parte: .avversario, archetipo: "guardia_elite",
                  protezione: .antiSaturazione, cella: Cella(riga: 5, colonna: 6)),
        ])
        stato = motore.applica(.ingaggia(sciame: ids[0], bersaglio: ids[1]), parte: .giocatore, stato: stato).0
        stato = motore.applica(.fineTurno, parte: .giocatore, stato: stato).0
        stato = motore.applica(.ingaggia(sciame: ids[2], bersaglio: ids[0]), parte: .avversario, stato: stato).0
        XCTAssertEqual(motore.postoInMischia(di: ids[0], contro: ids[1], stato: stato), 0)
        XCTAssertEqual(motore.postoInMischia(di: ids[0], contro: ids[2], stato: stato), 1)
        let subiti = subitiInUnGiro(stato)
        XCTAssertGreaterThan(subiti[ids[1]] ?? 0, subiti[ids[2]] ?? 0,
                             "il reparto rende di più contro il nemico che fronteggia da prima")
    }

    // MARK: - Effetto congiunto con l'accerchiamento (01 §9.10.2 e §9.11)

    /// La configurazione di riferimento del titolare, misurata dopo le due regole:
    /// tre reparti del mazzo di prova contro una fanteria pesante avversaria.
    func test_01_9_11_effetto_congiunto_sui_tre_contro_uno() throws {
        let poste = [Cella(riga: 6, colonna: 4), Cella(riga: 6, colonna: 5), Cella(riga: 5, colonna: 4)]
        var (stato, ids) = try campo([
            Posto(parte: .giocatore, archetipo: "tiratori",
                  protezione: .antiSaturazione, cella: poste[0]),
            Posto(parte: .giocatore, archetipo: "fanteria_leggera",
                  protezione: .antiSaturazione, cella: poste[1]),
            Posto(parte: .giocatore, archetipo: "fanteria_pesante",
                  protezione: .antiPerforazione, cella: poste[2]),
            Posto(parte: .avversario, archetipo: "fanteria_pesante",
                  protezione: .antiSaturazione, cella: Self.bersaglio),
        ])
        for indice in 0..<3 {
            stato = motore.applica(.ingaggia(sciame: ids[indice], bersaglio: ids[3]),
                                   parte: .giocatore, stato: stato).0
        }
        let subiti = subitiInUnGiro(stato)
        let inflitto = subiti[ids[3]] ?? 0
        let subito = (0..<3).reduce(Int64(0)) { $0 + (subiti[ids[$1]] ?? 0) }
        print("MISURA tre contro uno con limite e accerchiamento: i tre infliggono \(inflitto) punti, "
              + "ne subiscono \(subito) in totale (\(subiti[ids[0]] ?? 0) ai tiratori, "
              + "\(subiti[ids[1]] ?? 0) alla fanteria leggera, \(subiti[ids[2]] ?? 0) alla fanteria pesante)")
        // Prima delle due regole lo scambio era 258 inflitti contro 416 subiti, cioè
        // in perdita; ora deve essere nettamente in guadagno.
        XCTAssertGreaterThan(inflitto, subito,
                             "tre contro uno deve ora concludersi a favore dei tre")
        XCTAssertLessThan(subito, 416, "il limite dei bersagli riduce ciò che l'accerchiato restituisce")
    }

    // MARK: - Impronta (05 §2.9, RDA-55)

    /// L'ordine di arrivo dei contatti è stato di gioco e deve entrare nell'impronta:
    /// due situazioni che differiscono solo per quell'ordine si comportano in modo
    /// diverso, quindi non possono avere la stessa impronta.
    func test_05_2_9_l_ordine_di_arrivo_entra_nell_impronta() throws {
        let (dritto, _, _, _) = try mischia(assalitori: 3, ordineIngaggio: [0, 1, 2])
        let (rovescio, _, _, _) = try mischia(assalitori: 3, ordineIngaggio: [2, 1, 0])
        XCTAssertEqual(dritto.sciami.count, rovescio.sciami.count)
        XCTAssertEqual(Set(dritto.contatti.map(\.primo)), Set(rovescio.contatti.map(\.primo)),
                       "gli stessi contatti, in ordine diverso")
        XCTAssertNotEqual(dritto.impronta(), rovescio.impronta(),
                          "l'impronta distingue due stati che si comportano in modo diverso")
    }
}
