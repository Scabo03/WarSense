import XCTest
import Motore
import Dati
import Contenuti

/// Accertamento sugli esiti degli scontri (incarico del titolare dopo le prime tre
/// partite sulla build 6). Ogni prova cita per numero la regola che verifica, e
/// accerta per esecuzione — comandi applicati, eventi letti — mai per ispezione
/// del codice. Le prove di questo file non tarano nulla: misurano.
final class AccertamentoScontriTest: XCTestCase {

    var valori: ValoriDiGioco!
    var motore: MotoreBattaglia!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreBattaglia(valori: valori)
    }

    // MARK: - Attrezzi: un campo costruito reparto per reparto

    /// Un reparto da collocare: parte, archetipo, protezione, cella.
    struct Reparto {
        let parte: Parte
        let archetipo: IdentificatoreDati
        let protezione: TipoProtezione
        let cella: Cella
        let atomi: Int64
        init(_ parte: Parte, _ archetipo: IdentificatoreDati, _ protezione: TipoProtezione,
             _ cella: Cella, atomi: Int64 = 5) {
            self.parte = parte; self.archetipo = archetipo
            self.protezione = protezione; self.cella = cella; self.atomi = atomi
        }
    }

    /// Uno scontro con i reparti collocati dove serve alla misura, senza passare
    /// dalla zona di piazzamento: la misura riguarda il danno, non lo schieramento.
    /// I mazzi restano pieni perché la battaglia non si chiuda per annientamento.
    func campo(_ reparti: [Reparto], parteDiTurno: Parte = .giocatore) throws
        -> (StatoBattaglia, [IdSciame]) {
        let riserva = ScenarioBattaglia.ElementoScenario(
            archetipo: "fanteria_leggera", protezione: .antiSaturazione, atomi: 5, esemplari: 1)
        let scenario = ScenarioBattaglia(formato: "cento", caratteristica: "campo_aperto",
                                         primoOccupante: .giocatore, imboscata: false,
                                         deckGiocatore: [riserva], deckAvversario: [riserva])
        var stato = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
        var identificatori: [IdSciame] = []
        for reparto in reparti {
            let id = IdSciame(stato.prossimoIdSciame)
            stato.prossimoIdSciame += 1
            let lettera = stato.prossimaLettera[reparto.parte] ?? 1
            stato.prossimaLettera[reparto.parte] = lettera + 1
            let a = valori.archetipi[reparto.archetipo]!
            stato.sciami[id] = Sciame(id: id, parte: reparto.parte, archetipo: reparto.archetipo,
                                      protezione: reparto.protezione, lettera: lettera,
                                      atomiIniziali: reparto.atomi,
                                      serbatoio: reparto.atomi * a.puntiVitaPerAtomo,
                                      munizioni: a.dotazioneMunizioni, posizione: reparto.cella,
                                      azioneSpesa: false, rinforzo: false)
            stato.forzeImpegnate[reparto.parte, default: 0] += reparto.atomi * a.puntiVitaPerAtomo
            identificatori.append(id)
        }
        // Il turno si consegna con il comando ordinario, così che il bilancio della
        // parte che agisce nasca dalla stessa strada di sempre (05 §3.9).
        if parteDiTurno != stato.parteDiTurno {
            stato = motore.applica(.fineTurno, parte: stato.parteDiTurno, stato: stato).0
        }
        XCTAssertEqual(stato.parteDiTurno, parteDiTurno)
        return (stato, identificatori)
    }

    /// Il danno di un tiro, letto dall'evento del comando davvero applicato.
    func dannoDelTiro(_ tiratore: IdSciame, _ bersaglio: IdSciame,
                      parte: Parte, stato: StatoBattaglia,
                      file: StaticString = #filePath, linea: UInt = #line) -> Int64 {
        let comando = ComandoBattaglia.tira(sciame: tiratore, bersaglio: bersaglio)
        let validazione = motore.valida(comando, parte: parte, stato: stato)
        XCTAssertTrue(validazione.eValido, "tiro non valido: \(String(describing: validazione.motivo))",
                      file: file, line: linea)
        let (_, eventi) = motore.applica(comando, parte: parte, stato: stato)
        for evento in eventi {
            if case .tiroEseguito(_, _, _, _, _, let danno, _, _) = evento { return danno }
        }
        XCTFail("nessun evento di tiro", file: file, line: linea)
        return 0
    }

    /// I danni reciproci di una mischia, letti dall'evento aggregato del giro (01 §9.7.1).
    /// Restituisce, per ciascuno sciame, il danno che ha SUBITO nel giro.
    func dannoDelleMischie(_ stato: StatoBattaglia) -> [IdSciame: Int64] {
        var lavoro = stato
        var subiti: [IdSciame: Int64] = [:]
        let serbatoiPrima = lavoro.sciami.mapValues(\.serbatoio)
        // Un giro intero: la mischia si risolve quando il turno torna al primo occupante.
        for _ in 0..<2 {
            let (nuovo, _) = motore.applica(.fineTurno, parte: lavoro.parteDiTurno, stato: lavoro)
            lavoro = nuovo
        }
        for (id, prima) in serbatoiPrima {
            let dopo = lavoro.sciami[id]?.serbatoio ?? 0
            subiti[id] = prima - dopo
        }
        return subiti
    }

    // MARK: - 1. Verso dell'accoppiamento proiettile-protezione (01 §3.3.2, §9.9)

    /// Per OGNI reparto da tiro: il proiettile poco adatto riduce davvero il danno
    /// inflitto — non lo aumenta e non lo lascia invariato — e la riduzione si misura
    /// sul danno che il comando di tiro produce davvero, non sul solo coefficiente.
    func test_01_9_9_il_proiettile_poco_adatto_riduce_il_danno_inflitto() throws {
        var provati = 0
        for (identificatore, archetipo) in valori.archetipi.sorted(by: { $0.key < $1.key }) {
            guard let offesa = archetipo.offesaTiro else { continue }
            provati += 1
            // Due bersagli identici in tutto tranne la protezione, alla stessa distanza.
            let (stato, ids) = try campo([
                Reparto(.giocatore, identificatore, .antiSaturazione, Cella(riga: 8, colonna: 5)),
                Reparto(.avversario, "fanteria_pesante", .antiSaturazione, Cella(riga: 7, colonna: 5)),
                Reparto(.avversario, "fanteria_pesante", .antiPerforazione, Cella(riga: 7, colonna: 6)),
            ])
            XCTAssertEqual(stato.griglia.distanza(stato.sciami[ids[0]]!.posizione,
                                                  stato.sciami[ids[1]]!.posizione),
                           stato.griglia.distanza(stato.sciami[ids[0]]!.posizione,
                                                  stato.sciami[ids[2]]!.posizione),
                           "i due bersagli sono alla stessa distanza")
            let controSaturazione = dannoDelTiro(ids[0], ids[1], parte: .giocatore, stato: stato)
            let controPerforazione = dannoDelTiro(ids[0], ids[2], parte: .giocatore, stato: stato)

            // Il verso atteso si ricava dai SOLI dati: la protezione che copre meglio
            // l'asse su cui il proiettile porta più potere deve subire meno danno.
            let anti = valori.protezioni[.antiSaturazione]!
            let perf = valori.protezioni[.antiPerforazione]!
            let resaControSaturazione = offesa.potereSaturazione * (.uno - anti.paraSaturazione)
                + offesa.poterePerforazione * (.uno - anti.paraPerforazione)
            let resaControPerforazione = offesa.potereSaturazione * (.uno - perf.paraSaturazione)
                + offesa.poterePerforazione * (.uno - perf.paraPerforazione)
            if resaControSaturazione < resaControPerforazione {
                XCTAssertLessThan(controSaturazione, controPerforazione,
                                  "\(identificatore): il proiettile poco adatto deve infliggere MENO")
            } else {
                XCTAssertGreaterThan(controSaturazione, controPerforazione,
                                     "\(identificatore): il verso dell'accoppiamento è invertito")
            }
            // Poco adatto non vuol dire inefficace (01 §9.9).
            XCTAssertGreaterThan(min(controSaturazione, controPerforazione),
                                 valori.minimi.dannoMinimo - 1)
        }
        XCTAssertGreaterThan(provati, 1, "l'accertamento copre più di un reparto da tiro")
    }

    /// Il verso è lo stesso in mischia (01 §9.9.2), misurato sull'esito aggregato
    /// di un giro davvero risolto, non sul coefficiente.
    func test_01_9_9_2_l_arma_da_mischia_segue_lo_stesso_verso() throws {
        // Due fanterie pesanti avversarie identiche, protette in modo opposto,
        // ciascuna a contatto con una fanteria pesante del giocatore identica.
        var (stato, ids) = try campo([
            Reparto(.giocatore, "fanteria_pesante", .antiSaturazione, Cella(riga: 6, colonna: 2)),
            Reparto(.avversario, "fanteria_pesante", .antiSaturazione, Cella(riga: 5, colonna: 2)),
            Reparto(.giocatore, "fanteria_pesante", .antiSaturazione, Cella(riga: 6, colonna: 6)),
            Reparto(.avversario, "fanteria_pesante", .antiPerforazione, Cella(riga: 5, colonna: 6)),
        ])
        let (statoDopo1, _) = motore.applica(.ingaggia(sciame: ids[0], bersaglio: ids[1]),
                                             parte: .giocatore, stato: stato)
        stato = statoDopo1
        let (statoDopo2, _) = motore.applica(.ingaggia(sciame: ids[2], bersaglio: ids[3]),
                                             parte: .giocatore, stato: stato)
        stato = statoDopo2
        let subiti = dannoDelleMischie(stato)

        // L'arma della fanteria pesante porta più potere sull'asse della perforazione:
        // deve mordere di più chi è protetto dalla saturazione.
        let arma = valori.archetipi["fanteria_pesante"]!.offesaMischia
        XCTAssertGreaterThan(arma.poterePerforazione, arma.potereSaturazione,
                             "premessa del dato: l'arma della fanteria pesante perfora")
        XCTAssertGreaterThan(subiti[ids[1]] ?? 0, subiti[ids[3]] ?? 0,
                             "in mischia il verso dell'accoppiamento è lo stesso del tiro (01 §9.9.2)")
        XCTAssertGreaterThan(subiti[ids[3]] ?? 0, 0, "l'arma poco adatta non è mai inefficace")
    }

    // MARK: - 2. Simmetria fra le due parti (01 §9.1, §12.1)

    /// Due reparti del medesimo archetipo, appartenenti alle due parti e nelle
    /// stesse condizioni, si infliggono danni identici. La prova scambia soltanto
    /// l'etichetta di parte, lasciando ferme celle, archetipi e protezioni.
    func test_01_12_1_scambiare_le_parti_non_cambia_i_danni() throws {
        let a = Cella(riga: 6, colonna: 5)
        let b = Cella(riga: 5, colonna: 5)

        func misura(_ primo: Parte) throws -> (Int64, Int64) {
            var (stato, ids) = try campo([
                Reparto(primo, "fanteria_pesante", .antiPerforazione, a),
                Reparto(primo.avversaria, "fanteria_pesante", .antiSaturazione, b),
            ], parteDiTurno: primo)
            let (nuovo, _) = motore.applica(.ingaggia(sciame: ids[0], bersaglio: ids[1]),
                                            parte: primo, stato: stato)
            stato = nuovo
            let subiti = dannoDelleMischie(stato)
            return (subiti[ids[0]] ?? 0, subiti[ids[1]] ?? 0)
        }

        let conGiocatoreInA = try misura(.giocatore)
        let conAvversarioInA = try misura(.avversario)
        XCTAssertEqual(conGiocatoreInA.0, conAvversarioInA.0,
                       "chi occupa la cella A subisce lo stesso danno da qualunque parte stia")
        XCTAssertEqual(conGiocatoreInA.1, conAvversarioInA.1,
                       "chi occupa la cella B subisce lo stesso danno da qualunque parte stia")
        XCTAssertNotEqual(conGiocatoreInA.0, 0)
    }

    /// Verifica esaustiva e di costruzione diversa dalla precedente: per OGNI
    /// combinazione di archetipo attaccante, archetipo bersaglio e protezione, il
    /// danno non dipende da quale delle due parti attacchi.
    func test_01_12_1_nessun_modificatore_di_parte_su_tutta_la_matrice() throws {
        var confronti = 0
        for (idAttaccante, attaccante) in valori.archetipi.sorted(by: { $0.key < $1.key }) {
            for (idBersaglio, _) in valori.archetipi.sorted(by: { $0.key < $1.key }) {
                for protezione in TipoProtezione.allCases {
                    func danno(_ parte: Parte) throws -> Int64 {
                        let (stato, ids) = try campo([
                            Reparto(parte, idAttaccante, .antiSaturazione, Cella(riga: 6, colonna: 5)),
                            Reparto(parte.avversaria, idBersaglio, protezione, Cella(riga: 5, colonna: 5)),
                        ], parteDiTurno: parte)
                        return motore.danno(da: stato.sciami[ids[0]]!,
                                            offesa: attaccante.offesaMischia,
                                            a: stato.sciami[ids[1]]!,
                                            coefficiente: .uno, stato: stato)
                    }
                    XCTAssertEqual(try danno(.giocatore), try danno(.avversario),
                                   "\(idAttaccante) → \(idBersaglio) (\(protezione.rawValue))")
                    confronti += 1
                }
            }
        }
        XCTAssertEqual(confronti, valori.archetipi.count * valori.archetipi.count * 2)
    }

    // MARK: - 3. Somma dei danni di più attaccanti (01 §9.7)

    /// La somma dei danni di più attaccanti sullo stesso bersaglio è cumulativa:
    /// non sostituita, non sovrascritta, non applicata una volta sola. La prova
    /// misura prima ciascun attaccante da solo, poi i tre insieme.
    func test_01_9_7_i_danni_di_piu_attaccanti_si_sommano_sul_bersaglio() throws {
        let bersaglio = Cella(riga: 5, colonna: 5)
        let poste = [Cella(riga: 6, colonna: 4), Cella(riga: 6, colonna: 5), Cella(riga: 5, colonna: 4)]
        let archetipiAttaccanti = ["fanteria_pesante", "fanteria_leggera", "tiratori"]

        // Ciascuno da solo, nella medesima posizione che occuperà nell'accerchiamento.
        var isolati: [Int64] = []
        for (indice, archetipo) in archetipiAttaccanti.enumerated() {
            var (stato, ids) = try campo([
                Reparto(.giocatore, archetipo, .antiSaturazione, poste[indice]),
                Reparto(.avversario, "fanteria_pesante", .antiSaturazione, bersaglio),
            ])
            let (nuovo, _) = motore.applica(.ingaggia(sciame: ids[0], bersaglio: ids[1]),
                                            parte: .giocatore, stato: stato)
            stato = nuovo
            isolati.append(dannoDelleMischie(stato)[ids[1]] ?? 0)
        }

        // Tutti e tre insieme contro il medesimo bersaglio.
        var (stato, ids) = try campo([
            Reparto(.giocatore, archetipiAttaccanti[0], .antiSaturazione, poste[0]),
            Reparto(.giocatore, archetipiAttaccanti[1], .antiSaturazione, poste[1]),
            Reparto(.giocatore, archetipiAttaccanti[2], .antiSaturazione, poste[2]),
            Reparto(.avversario, "fanteria_pesante", .antiSaturazione, bersaglio),
        ])
        for attaccante in 0..<3 {
            let (nuovo, _) = motore.applica(.ingaggia(sciame: ids[attaccante], bersaglio: ids[3]),
                                            parte: .giocatore, stato: stato)
            stato = nuovo
        }
        XCTAssertEqual(stato.contatti.count, 3, "tre contatti distinti sul medesimo bersaglio")
        let insieme = dannoDelleMischie(stato)[ids[3]] ?? 0

        XCTAssertGreaterThanOrEqual(insieme, isolati.reduce(0, +),
                                    "i danni si sommano: nessuno è sostituito o sovrascritto")
        XCTAssertGreaterThan(insieme, isolati.max()!,
                             "il totale supera il maggiore dei tre: non è applicato una volta sola")
    }

    // MARK: - 4. Peso dei vantaggi nascosti oggi in vigore (01 §13.2, 03 §7)

    /// I vantaggi nascosti sono due e agiscono entrambi soltanto sulla ritirata
    /// avversaria. Nessuno dei due tocca il danno: la prova lo accerta misurando
    /// il danno con i vantaggi in vigore e confrontandolo con la formula.
    func test_01_13_2_i_vantaggi_nascosti_non_toccano_il_danno() throws {
        // L'elenco dei vantaggi è chiuso e dichiarato: se ne compare un terzo,
        // questa prova va aggiornata insieme a 01 §13.2 e 03 §7.2.
        XCTAssertTrue(valori.vantaggi.ritirataAvversariaSoloUltimaRiga)
        XCTAssertLessThan(valori.vantaggi.riduzionePropensioneRitirataAvversaria, .uno)

        // Ancoraggio: al limite della gittata e contro un bersaglio isolato nessuno
        // dei due modificatori dichiarati agisce, e il danno deve uscire dalla sola
        // formula dell'accoppiamento. Se un vantaggio nascosto vi entrasse, qui si vedrebbe.
        let a = valori.archetipi["tiratori"]!
        let (nudo, idsNudo) = try campo([
            Reparto(.giocatore, "tiratori", .antiSaturazione, Cella(riga: 8, colonna: 5)),
            Reparto(.avversario, "fanteria_pesante", .antiPerforazione,
                    Cella(riga: 8 - a.gittata, colonna: 5)),
        ])
        let inflitto = dannoDelTiro(idsNudo[0], idsNudo[1], parte: .giocatore, stato: nudo)
        let atteso = motore.efficacia(offesa: a.offesaTiro!,
                                      protezione: valori.protezioni[.antiPerforazione]!)
            .applicato(a: a.capacitaOffensivaPerAtomo * 5)
        XCTAssertEqual(inflitto, atteso,
                       "senza modificatori il danno esce dalla sola formula: nessun vantaggio vi entra")

        // E a qualunque distanza, con o senza concorrenti, il danno non dipende da
        // quale parte tiri: i vantaggi nascosti non toccano il combattimento.
        func danno(tiratoreDi parte: Parte, distanza: Int) throws -> Int64 {
            let (stato, ids) = try campo([
                Reparto(parte, "tiratori", .antiSaturazione, Cella(riga: 8, colonna: 5)),
                Reparto(parte.avversaria, "fanteria_pesante", .antiPerforazione,
                        Cella(riga: 8 - distanza, colonna: 5)),
            ], parteDiTurno: parte)
            return dannoDelTiro(ids[0], ids[1], parte: parte, stato: stato)
        }
        for distanza in 1...a.gittata {
            XCTAssertEqual(try danno(tiratoreDi: .giocatore, distanza: distanza),
                           try danno(tiratoreDi: .avversario, distanza: distanza),
                           "distanza \(distanza): nessun vantaggio di parte nel danno")
        }
    }

    /// Quanto pesa davvero la riduzione della propensione alla ritirata avversaria:
    /// la soglia di perdite oltre la quale il tattico avversario si arrende.
    /// Misurata in chiaro, perché il documento la dichiara «molto bassa» senza numeri.
    func test_01_13_2_peso_misurato_della_propensione_alla_ritirata_ridotta() throws {
        let ufficiale = valori.ufficiali["ufficiale_prova"]!
        // Soglia del tattico: tolleranza alle perdite diviso propensione effettiva.
        let sogliaSenzaVantaggio = ufficiale.tolleranzaPerdite / ufficiale.propensioneRitirata
        let ridotta = ufficiale.propensioneRitirata * valori.vantaggi.riduzionePropensioneRitirataAvversaria
        let sogliaConVantaggio = ufficiale.tolleranzaPerdite / ridotta

        XCTAssertGreaterThan(sogliaConVantaggio, sogliaSenzaVantaggio,
                             "il vantaggio alza la soglia: l'avversario si arrende più tardi")
        // Il fatto che conta per il titolare: già SENZA il vantaggio la soglia
        // raggiunge o supera l'unità, cioè la totalità delle forze impiegate.
        // La resa avversaria è quindi irraggiungibile per costruzione dei valori,
        // e il vantaggio nascosto non ne è la causa: la causa sono i valori.
        XCTAssertGreaterThanOrEqual(sogliaSenzaVantaggio, .uno,
                                    "con i valori di fabbrica la resa avversaria è già irraggiungibile senza vantaggio")
        print("MISURA vantaggi-nascosti: soglia di resa avversaria senza vantaggio = "
              + "\(Double(sogliaSenzaVantaggio.grezzo) / 1000) delle forze impiegate; "
              + "con vantaggio = \(Double(sogliaConVantaggio.grezzo) / 1000)")
    }

    // MARK: - 5. Le tre osservazioni del titolare, misurate

    /// Osservazione 1 e 2. Nel mazzo dello scenario di prova la fanteria pesante
    /// del giocatore porta protezione anti-perforazione e quella avversaria
    /// anti-saturazione: contro il proiettile leggero dei tiratori, che satura,
    /// la prima è il bersaglio MIGLIORE del campo e la seconda il peggiore.
    /// È il fatto che spiega entrambe le osservazioni, e sta nei dati, non nel codice.
    func test_01_3_3_2_le_protezioni_dei_due_mazzi_non_sono_speculari() throws {
        let leggero = valori.archetipi["tiratori"]!.offesaTiro!
        let controGiocatore = motore.efficaciaQualitativa(
            offesa: leggero, protezione: valori.protezioni[.antiPerforazione]!)
        let controAvversario = motore.efficaciaQualitativa(
            offesa: leggero, protezione: valori.protezioni[.antiSaturazione]!)
        XCTAssertEqual(controGiocatore, .efficace,
                       "i tiratori avversari sono EFFICACI contro la fanteria pesante del giocatore")
        XCTAssertEqual(controAvversario, .pocoEfficace,
                       "i tiratori del giocatore sono POCO EFFICACI contro quella avversaria")

        // Lo stesso, misurato sul danno del comando applicato davvero.
        let (stato, ids) = try campo([
            Reparto(.giocatore, "tiratori", .antiSaturazione, Cella(riga: 8, colonna: 5)),
            Reparto(.avversario, "fanteria_pesante", .antiSaturazione, Cella(riga: 7, colonna: 4)),
            Reparto(.avversario, "fanteria_pesante", .antiPerforazione, Cella(riga: 7, colonna: 5)),
        ])
        let controAntiSaturazione = dannoDelTiro(ids[0], ids[1], parte: .giocatore, stato: stato)
        let controAntiPerforazione = dannoDelTiro(ids[0], ids[2], parte: .giocatore, stato: stato)
        XCTAssertGreaterThan(controAntiPerforazione, controAntiSaturazione)
        print("MISURA tiro: proiettile leggero, 5 atomi — contro anti-perforazione "
              + "\(controAntiPerforazione) punti, contro anti-saturazione \(controAntiSaturazione) punti")
    }

    /// Osservazione 3. Alla data dell'accertamento il reparto accerchiato combatteva
    /// a piena capacità in CIASCUNO dei contatti che lo stringevano: tre assalitori
    /// gli infliggevano 258 punti a giro e ne subivano 416, cioè uno scambio in
    /// perdita. Non era un difetto — 01 §9.7 non prevedeva alcuna divisione della
    /// resa — ma era la ragione misurata per cui tre contro uno non prevaleva.
    ///
    /// Il titolare ha poi stabilito il limite dei bersagli simultanei (01 §9.11),
    /// che sostituisce quel comportamento. Questa prova resta a presidiare la
    /// misura nella configurazione di riferimento e a fissare il verso del
    /// cambiamento: lo scambio, prima in perdita, deve ora concludersi a favore
    /// dei tre. Il dettaglio della nuova regola sta in `LimiteBersagliTest`.
    func test_01_9_11_il_reparto_stretto_da_tre_non_rende_piu_per_tre() throws {
        let bersaglio = Cella(riga: 5, colonna: 5)
        let poste = [Cella(riga: 6, colonna: 4), Cella(riga: 6, colonna: 5), Cella(riga: 5, colonna: 4)]
        var (stato, ids) = try campo([
            Reparto(.giocatore, "tiratori", .antiSaturazione, poste[0]),
            Reparto(.giocatore, "fanteria_leggera", .antiSaturazione, poste[1]),
            Reparto(.giocatore, "fanteria_pesante", .antiPerforazione, poste[2]),
            Reparto(.avversario, "fanteria_pesante", .antiSaturazione, bersaglio),
        ])
        for attaccante in 0..<3 {
            let (nuovo, _) = motore.applica(.ingaggia(sciame: ids[attaccante], bersaglio: ids[3]),
                                            parte: .giocatore, stato: stato)
            stato = nuovo
        }
        let subiti = dannoDelleMischie(stato)
        let inflittoDaiTre = subiti[ids[3]] ?? 0
        let subitoDaiTre = (0..<3).reduce(Int64(0)) { $0 + (subiti[ids[$1]] ?? 0) }
        print("MISURA tre contro uno, valori correnti (mazzo di prova, 5 atomi ciascuno): "
              + "i tre infliggono \(inflittoDaiTre) punti, ne subiscono \(subitoDaiTre) in totale "
              + "(\(subiti[ids[0]] ?? 0) ai tiratori, \(subiti[ids[1]] ?? 0) alla fanteria leggera, "
              + "\(subiti[ids[2]] ?? 0) alla fanteria pesante)")
        XCTAssertGreaterThan(subitoDaiTre, 0)
        XCTAssertGreaterThan(inflittoDaiTre, subitoDaiTre,
                             "con il limite dei bersagli lo scambio si è rovesciato a favore dei tre")
        XCTAssertLessThan(subitoDaiTre, 416,
                          "l'accerchiato non rende più tre volte: alla data dell'accertamento erano 416")

        // Il fatto che è cambiato: l'accerchiato non colpisce più ciascun assalitore
        // come se fosse solo. Il secondo arrivato riceve la resa ridotta e il terzo nulla.
        var (uno, idsUno) = try campo([
            Reparto(.giocatore, "fanteria_leggera", .antiSaturazione, poste[1]),
            Reparto(.avversario, "fanteria_pesante", .antiSaturazione, bersaglio),
        ])
        let (nuovo, _) = motore.applica(.ingaggia(sciame: idsUno[0], bersaglio: idsUno[1]),
                                        parte: .giocatore, stato: uno)
        uno = nuovo
        let controUnoSolo = dannoDelleMischie(uno)[idsUno[0]] ?? 0
        XCTAssertLessThan(subiti[ids[1]] ?? 0, controUnoSolo,
                          "il secondo arrivato è contrastato di lato, non fronteggiato (01 §9.11)")
        XCTAssertEqual(subiti[ids[2]] ?? -1, 0, "il terzo arrivato non riceve risposta alcuna")
    }

    // MARK: - L'unica asimmetria fra le parti trovata dall'accertamento

    /// Annientamento simultaneo (01 §15.2.5, chiuso dal titolare). Quando l'ultimo
    /// reparto di ciascuna parte cade nel medesimo giro, la parità non esiste
    /// (01 §15.2.2) e l'esito va assegnato: non può risolversi a sfavore del
    /// giocatore, ed è quindi un vantaggio nascosto dichiarato (01 §13.2), che
    /// come tale vive nei dati perché la Verifica possa disattivarlo (05 §12.5).
    func test_01_15_2_5_annientamento_simultaneo_assegnato_al_giocatore() throws {
        let vuoto = ScenarioBattaglia.ElementoScenario(
            archetipo: "fanteria_leggera", protezione: .antiSaturazione, atomi: 5, esemplari: 0)
        let scenario = ScenarioBattaglia(formato: "cento", caratteristica: "campo_aperto",
                                         primoOccupante: .giocatore, imboscata: false,
                                         deckGiocatore: [vuoto], deckAvversario: [vuoto])
        var stato = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
        // Due reparti identici a contatto, ciascuno con un solo punto di consistenza:
        // il giro di mischia li disfa entrambi nello stesso istante.
        for (numero, parte, cella) in [(1, Parte.giocatore, Cella(riga: 6, colonna: 5)),
                                       (2, Parte.avversario, Cella(riga: 5, colonna: 5))] {
            let id = IdSciame(numero)
            stato.sciami[id] = Sciame(id: id, parte: parte, archetipo: "fanteria_leggera",
                                      protezione: .antiSaturazione, lettera: 1, atomiIniziali: 5,
                                      serbatoio: 1, munizioni: 0, posizione: cella,
                                      azioneSpesa: false, rinforzo: false)
            stato.prossimoIdSciame = numero + 1
            stato.forzeImpegnate[parte, default: 0] += 500
        }
        stato = motore.applica(.ingaggia(sciame: IdSciame(1), bersaglio: IdSciame(2)),
                               parte: .giocatore, stato: stato).0
        stato = motore.applica(.fineTurno, parte: .giocatore, stato: stato).0
        stato = motore.applica(.fineTurno, parte: .avversario, stato: stato).0

        XCTAssertTrue(stato.sciami.isEmpty, "il campo resta vuoto: entrambi disfatti nello stesso giro")
        XCTAssertEqual(stato.esito?.modo, .annientamento)
        XCTAssertEqual(stato.esito?.sconfitto, .avversario,
                       "l'annientamento simultaneo non si risolve a sfavore del giocatore (01 §15.2.5)")
        XCTAssertTrue(valori.vantaggi.annientamentoSimultaneoAlGiocatore,
                      "è un vantaggio nascosto e sta nei dati, non nel codice (01 §13.2, 03 §7.2)")
    }

    /// Il vantaggio è disattivabile, perché il programma di verifica misuri le
    /// probabilità reali (05 §12.5, 03 §7.1): spento, l'esito simultaneo torna
    /// a cadere sul giocatore. Il caso NON simultaneo non ne è toccato in alcun modo.
    func test_05_12_5_il_vantaggio_dell_annientamento_simultaneo_e_disattivabile() throws {
        // Il vantaggio si spegne come lo spegnerà la Verifica: sui file, in una
        // cartella di valori alternativa (05 §12.1, §12.5), non con una scorciatoia
        // di collaudo. Così la prova accerta anche che l'interruttore sia davvero
        // nei dati e non nel codice.
        func valoriCon(vantaggio acceso: Bool) throws -> ValoriDiGioco {
            let cartella = FileManager.default.temporaryDirectory
                .appendingPathComponent("valori-vantaggi-\(acceso)-\(UUID().uuidString)")
            try FileManager.default.copyItem(at: Contenuti.valoriDiFabbrica, to: cartella)
            addTeardownBlock { try? FileManager.default.removeItem(at: cartella) }
            let file = cartella.appendingPathComponent("vantaggi-nascosti.json")
            var voci = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
            voci["annientamento_simultaneo_al_giocatore"] = acceso
            try JSONSerialization.data(withJSONObject: voci).write(to: file)
            return try CaricatoreValori.carica(da: cartella)
        }

        func esito(conVantaggio: Bool) throws -> Parte? {
            let valoriProva = try valoriCon(vantaggio: conVantaggio)
            XCTAssertEqual(valoriProva.vantaggi.annientamentoSimultaneoAlGiocatore, conVantaggio)
            let motoreProva = MotoreBattaglia(valori: valoriProva)
            let vuoto = ScenarioBattaglia.ElementoScenario(
                archetipo: "fanteria_leggera", protezione: .antiSaturazione, atomi: 5, esemplari: 0)
            let scenario = ScenarioBattaglia(formato: "cento", caratteristica: "campo_aperto",
                                             primoOccupante: .giocatore, imboscata: false,
                                             deckGiocatore: [vuoto], deckAvversario: [vuoto])
            var stato = try FabbricaBattaglia.crea(scenario: scenario, valori: valoriProva).0
            for (numero, parte, cella) in [(1, Parte.giocatore, Cella(riga: 6, colonna: 5)),
                                           (2, Parte.avversario, Cella(riga: 5, colonna: 5))] {
                let id = IdSciame(numero)
                stato.sciami[id] = Sciame(id: id, parte: parte, archetipo: "fanteria_leggera",
                                          protezione: .antiSaturazione, lettera: 1, atomiIniziali: 5,
                                          serbatoio: 1, munizioni: 0, posizione: cella,
                                          azioneSpesa: false, rinforzo: false)
                stato.prossimoIdSciame = numero + 1
                stato.forzeImpegnate[parte, default: 0] += 500
            }
            stato = motoreProva.applica(ComandoBattaglia.ingaggia(sciame: IdSciame(1), bersaglio: IdSciame(2)),
                                        parte: Parte.giocatore, stato: stato).0
            stato = motoreProva.applica(ComandoBattaglia.fineTurno, parte: Parte.giocatore, stato: stato).0
            stato = motoreProva.applica(ComandoBattaglia.fineTurno, parte: Parte.avversario, stato: stato).0
            return stato.esito?.sconfitto
        }
        XCTAssertEqual(try esito(conVantaggio: true), .avversario)
        XCTAssertEqual(try esito(conVantaggio: false), .giocatore,
                       "spento il vantaggio, la Verifica misura il caso reale")
    }

    /// L'annientamento di una sola parte non è toccato: chi resta senza nulla perde,
    /// e il vantaggio non vi entra (01 §15.2.3).
    func test_01_15_2_3_l_annientamento_di_una_sola_parte_resta_invariato() throws {
        for perdente in Parte.allCases {
            let vuoto = ScenarioBattaglia.ElementoScenario(
                archetipo: "fanteria_leggera", protezione: .antiSaturazione, atomi: 5, esemplari: 0)
            let pieno = ScenarioBattaglia.ElementoScenario(
                archetipo: "fanteria_leggera", protezione: .antiSaturazione, atomi: 5, esemplari: 1)
            let scenario = ScenarioBattaglia(
                formato: "cento", caratteristica: "campo_aperto",
                primoOccupante: .giocatore, imboscata: false,
                deckGiocatore: [perdente == .giocatore ? vuoto : pieno],
                deckAvversario: [perdente == .avversario ? vuoto : pieno])
            var stato = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
            // Un solo reparto in campo, della parte che NON deve perdere.
            let id = IdSciame(1)
            stato.sciami[id] = Sciame(id: id, parte: perdente.avversaria, archetipo: "fanteria_leggera",
                                      protezione: .antiSaturazione, lettera: 1, atomiIniziali: 5,
                                      serbatoio: 500, munizioni: 0, posizione: Cella(riga: 5, colonna: 5),
                                      azioneSpesa: false, rinforzo: false)
            stato.prossimoIdSciame = 2
            stato = motore.applica(.fineTurno, parte: .giocatore, stato: stato).0
            XCTAssertEqual(stato.esito?.sconfitto, perdente)
            XCTAssertEqual(stato.esito?.modo, .annientamento)
        }
    }
}
