import XCTest
import Motore
import Dati
import Contenuti

/// Seconda prova dell'accertamento, costruita in modo diverso dalla prima
/// (`AccertamentoScontriTest`). Dove la prima misura un colpo alla volta e
/// confronta due misure, questa procede per contro-prova e per identità:
/// accerta che ciò che NON deve entrare nel danno davvero non vi entri, che
/// scambiare simultaneamente tutte le protezioni scambi tutti gli esiti, e che
/// uno scontro intero giocato a parti scambiate abbia la medesima traiettoria.
/// Non trovare difetti una volta non basta: questo file è la seconda volta.
final class AccertamentoSecondaProvaTest: XCTestCase {

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

    /// `parteDiTurno` è anche il primo occupante: il giro si chiude quando il turno
    /// torna a lui (01 §9.4.1), e scambiare le parti senza scambiare anche questo
    /// sfaserebbe il confronto di un turno, misurando l'attrezzo e non le regole.
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
        if parteDiTurno != stato.parteDiTurno {
            stato = motore.applica(.fineTurno, parte: stato.parteDiTurno, stato: stato).0
        }
        return (stato, ids)
    }

    /// La fotografia del campo per cella: che cosa c'è e in quale consistenza.
    /// È la grandezza che deve restare identica scambiando le etichette di parte.
    func fotografia(_ stato: StatoBattaglia) -> [Cella: String] {
        var mappa: [Cella: String] = [:]
        for sciame in stato.sciamiOrdinati {
            mappa[sciame.posizione] = "\(sciame.archetipo)/\(sciame.protezione.rawValue)/\(sciame.serbatoio)"
        }
        return mappa
    }

    // MARK: - Contro-prova: ciò che non deve entrare nel danno

    /// Contro-prova del verso dell'accoppiamento. La prima prova varia la protezione
    /// del BERSAGLIO e osserva il danno cambiare. Questa varia la protezione
    /// dell'ATTACCANTE e accerta che il danno inflitto non cambi affatto: se il
    /// Motore consultasse la protezione sbagliata, qui si vedrebbe e là no.
    func test_01_9_9_la_protezione_di_chi_colpisce_non_entra_nel_danno_che_infligge() throws {
        var confronti = 0
        for (identificatore, archetipo) in valori.archetipi.sorted(by: { $0.key < $1.key }) {
            for protezioneBersaglio in TipoProtezione.allCases {
                func dannoInflitto(protezioneAttaccante: TipoProtezione) throws -> Int64 {
                    let (stato, ids) = try campo([
                        Posto(parte: .giocatore, archetipo: identificatore,
                              protezione: protezioneAttaccante, cella: Cella(riga: 6, colonna: 5)),
                        Posto(parte: .avversario, archetipo: "fanteria_pesante",
                              protezione: protezioneBersaglio, cella: Cella(riga: 5, colonna: 5)),
                    ])
                    return motore.danno(da: stato.sciami[ids[0]]!, offesa: archetipo.offesaMischia,
                                        a: stato.sciami[ids[1]]!, coefficiente: .uno, stato: stato)
                }
                XCTAssertEqual(try dannoInflitto(protezioneAttaccante: .antiSaturazione),
                               try dannoInflitto(protezioneAttaccante: .antiPerforazione),
                               "\(identificatore): la propria protezione non deve entrare nell'offesa")
                confronti += 1
            }
        }
        XCTAssertEqual(confronti, valori.archetipi.count * 2)
    }

    /// Identità: scambiare simultaneamente TUTTE le protezioni del campo scambia
    /// esattamente tutti gli esiti. È una prova di struttura, non di confronto fra
    /// due misure: se un solo ramo del calcolo fosse cablato su una protezione
    /// determinata anziché su quella del bersaglio, l'identità non reggerebbe.
    func test_01_3_3_2_scambiare_tutte_le_protezioni_scambia_tutti_gli_esiti() throws {
        func opposta(_ p: TipoProtezione) -> TipoProtezione {
            p == .antiSaturazione ? .antiPerforazione : .antiSaturazione
        }
        func misura(scambiate: Bool) throws -> [Int64] {
            var esiti: [Int64] = []
            for (idAttaccante, attaccante) in valori.archetipi.sorted(by: { $0.key < $1.key }) {
                for (idBersaglio, _) in valori.archetipi.sorted(by: { $0.key < $1.key }) {
                    let protezione: TipoProtezione = scambiate
                        ? opposta(.antiSaturazione) : .antiSaturazione
                    let (stato, ids) = try campo([
                        Posto(parte: .giocatore, archetipo: idAttaccante,
                              protezione: .antiSaturazione, cella: Cella(riga: 6, colonna: 5)),
                        Posto(parte: .avversario, archetipo: idBersaglio,
                              protezione: protezione, cella: Cella(riga: 5, colonna: 5)),
                    ])
                    esiti.append(motore.danno(da: stato.sciami[ids[0]]!,
                                              offesa: attaccante.offesaMischia,
                                              a: stato.sciami[ids[1]]!,
                                              coefficiente: .uno, stato: stato))
                }
            }
            return esiti
        }
        let dritti = try misura(scambiate: false)
        let rovesci = try misura(scambiate: true)
        XCTAssertEqual(dritti.count, rovesci.count)
        XCTAssertNotEqual(dritti, rovesci, "le due protezioni rispondono in modo opposto (01 §3.3.2)")
        // Ogni esito è la resa della formula con la protezione corrispondente: l'identità
        // vale voce per voce e non soltanto in blocco.
        var indice = 0
        for (_, attaccante) in valori.archetipi.sorted(by: { $0.key < $1.key }) {
            for (_, bersaglio) in valori.archetipi.sorted(by: { $0.key < $1.key }) {
                for (esiti, protezione) in [(dritti, TipoProtezione.antiSaturazione),
                                            (rovesci, TipoProtezione.antiPerforazione)] {
                    let atteso = max(valori.minimi.dannoMinimo,
                                     motore.efficacia(offesa: attaccante.offesaMischia,
                                                      protezione: valori.protezioni[protezione]!)
                                         .applicato(a: attaccante.capacitaOffensivaPerAtomo * 5))
                    XCTAssertEqual(esiti[indice], atteso)
                    _ = bersaglio
                }
                indice += 1
            }
        }
    }

    // MARK: - Simmetria accertata su uno scontro intero, non su un colpo

    /// Uno scontro completo giocato due volte sulle medesime celle, scambiando
    /// soltanto a quale parte appartiene ciascun reparto. Finché nessuno cambia
    /// posizione, la fotografia del campo deve coincidere giro per giro. È una
    /// costruzione diversa da quella della prima prova, perché attraversa il ciclo
    /// dei turni, i bilanci, l'ordinamento dei contatti e le soglie di disingaggio.
    func test_01_12_1_lo_scontro_completo_a_parti_scambiate_ha_traiettoria_identica() throws {
        let schieramento: [(IdentificatoreDati, TipoProtezione, Cella, Bool)] = [
            // archetipo, protezione, cella, appartiene alla prima parte
            ("fanteria_pesante", .antiPerforazione, Cella(riga: 6, colonna: 4), true),
            ("guardia_elite", .antiSaturazione, Cella(riga: 6, colonna: 5), true),
            ("fanteria_pesante", .antiSaturazione, Cella(riga: 5, colonna: 4), false),
            ("guardia_elite", .antiPerforazione, Cella(riga: 5, colonna: 5), false),
        ]

        func traiettoria(primaParte: Parte) throws -> [[Cella: String]] {
            let posti = schieramento.map { archetipo, protezione, cella, dellaPrima in
                Posto(parte: dellaPrima ? primaParte : primaParte.avversaria,
                      archetipo: archetipo, protezione: protezione, cella: cella)
            }
            var (stato, ids) = try campo(posti, parteDiTurno: primaParte)
            // Ciascuna delle due parti ingaggia il proprio dirimpettaio nel proprio turno.
            stato = motore.applica(.ingaggia(sciame: ids[0], bersaglio: ids[2]),
                                   parte: primaParte, stato: stato).0
            stato = motore.applica(.ingaggia(sciame: ids[1], bersaglio: ids[3]),
                                   parte: primaParte, stato: stato).0
            var passi: [[Cella: String]] = [fotografia(stato)]
            let celleIniziali = Set(passi[0].keys)
            for _ in 0..<20 {
                stato = motore.applica(.fineTurno, parte: stato.parteDiTurno, stato: stato).0
                let scatto = fotografia(stato)
                // La traiettoria si confronta finché nessuno si è spostato: la cella
                // verso cui ci si ritrae dipende, per definizione, dalla propria parte.
                guard Set(scatto.keys) == celleIniziali else { break }
                passi.append(scatto)
                if stato.esito != nil { break }
            }
            return passi
        }

        let conGiocatorePrimo = try traiettoria(primaParte: .giocatore)
        let conAvversarioPrimo = try traiettoria(primaParte: .avversario)
        XCTAssertGreaterThanOrEqual(conGiocatorePrimo.count, 4,
                                    "la traiettoria confrontata copre più giri di mischia")
        XCTAssertEqual(conGiocatorePrimo, conAvversarioPrimo,
                       "scambiare le parti non cambia nulla di ciò che accade sul campo")
        XCTAssertNotEqual(conGiocatorePrimo.first, conGiocatorePrimo.last,
                          "la mischia ha davvero prodotto perdite: il confronto non è a vuoto")
    }

    // MARK: - Cumulatività accertata per invarianza, non per somma

    /// La somma dei danni di più attaccanti che ingaggiano tutti nello STESSO turno
    /// non dipende dall'ordine in cui gli ingaggi sono impartiti: ciascuno scambia
    /// i colpi all'istante contro un bersaglio che nessun altro ha ancora toccato in
    /// quell'istante, e la risoluzione d'inizio giro è una sola e simultanea.
    /// AVVERTENZA: non è una proprietà generale. Dalla risoluzione immediata
    /// (01 §9.7.1) l'ordine delle proprie mosse conta, ed è profondità voluta; qui
    /// si misura il caso in cui non conta, cioè quello in cui nulla si interpone
    /// fra un ingaggio e l'altro.
    func test_01_9_7_la_somma_dei_danni_non_dipende_dall_ordine_degli_ingaggi() throws {
        let bersaglio = Cella(riga: 5, colonna: 5)
        let poste = [Cella(riga: 6, colonna: 4), Cella(riga: 6, colonna: 5), Cella(riga: 5, colonna: 4)]
        let archetipi = ["fanteria_pesante", "fanteria_leggera", "guardia_elite"]

        func totale(ordine: [Int]) throws -> Int64 {
            var (stato, ids) = try campo(
                (0..<3).map { Posto(parte: .giocatore, archetipo: archetipi[$0],
                                    protezione: .antiSaturazione, cella: poste[$0]) }
                + [Posto(parte: .avversario, archetipo: "fanteria_pesante",
                         protezione: .antiSaturazione, cella: bersaglio)])
            for indice in ordine {
                stato = motore.applica(.ingaggia(sciame: ids[indice], bersaglio: ids[3]),
                                       parte: .giocatore, stato: stato).0
            }
            let prima = stato.sciami[ids[3]]!.serbatoio
            for _ in 0..<2 {
                stato = motore.applica(.fineTurno, parte: stato.parteDiTurno, stato: stato).0
            }
            return prima - (stato.sciami[ids[3]]?.serbatoio ?? 0)
        }

        let riferimento = try totale(ordine: [0, 1, 2])
        for ordine in [[0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]] {
            XCTAssertEqual(try totale(ordine: ordine), riferimento,
                           "ordine \(ordine): la somma dei danni non dipende dall'ordine")
        }
        XCTAssertGreaterThan(riferimento, 0)
    }

    /// Ultima contro-prova sulla cumulatività: togliendo un attaccante alla volta
    /// il danno sul bersaglio deve calare ogni volta. Si misura la sola risoluzione
    /// d'inizio giro, che è UNA risoluzione simultanea: fra risoluzioni diverse la
    /// simultaneità non esiste più (01 §9.7.1) e il confronto non sarebbe pulito.
    func test_01_9_7_togliere_un_attaccante_riduce_sempre_il_danno_subito() throws {
        let bersaglio = Cella(riga: 5, colonna: 5)
        let poste = [Cella(riga: 6, colonna: 4), Cella(riga: 6, colonna: 5), Cella(riga: 5, colonna: 4)]
        let archetipi = ["fanteria_pesante", "fanteria_leggera", "guardia_elite"]

        func danno(attaccanti: [Int]) throws -> Int64 {
            var (stato, ids) = try campo(
                attaccanti.map { Posto(parte: .giocatore, archetipo: archetipi[$0],
                                       protezione: .antiSaturazione, cella: poste[$0]) }
                + [Posto(parte: .avversario, archetipo: "fanteria_pesante",
                         protezione: .antiSaturazione, cella: bersaglio)])
            let idBersaglio = ids.removeLast()
            // L'intero primo scambio: gli ingaggi, che si risolvono all'istante,
            // più la risoluzione d'inizio giro.
            let prima = stato.sciami[idBersaglio]!.serbatoio
            for id in ids {
                let comando = ComandoBattaglia.ingaggia(sciame: id, bersaglio: idBersaglio)
                guard motore.valida(comando, parte: .giocatore, stato: stato).eValido else { continue }
                stato = motore.applica(comando, parte: .giocatore, stato: stato).0
            }
            for _ in 0..<2 where stato.esito == nil {
                stato = motore.applica(.fineTurno, parte: stato.parteDiTurno, stato: stato).0
            }
            return prima - (stato.sciami[idBersaglio]?.serbatoio ?? 0)
        }

        let tre = try danno(attaccanti: [0, 1, 2])
        for tolto in 0..<3 {
            let due = try danno(attaccanti: [0, 1, 2].filter { $0 != tolto })
            XCTAssertLessThan(due, tre, "togliendo l'attaccante \(tolto) il danno deve calare")
        }
    }
}
