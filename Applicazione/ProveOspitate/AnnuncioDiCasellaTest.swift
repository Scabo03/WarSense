import XCTest
import Dati
import Motore
@testable import WarSense

/// L'annuncio di una cella durante la DESIGNAZIONE non può dire meno di quanto la
/// stessa cella dica in esplorazione (02 §3.3, §3.8, principio 7).
///
/// 02 §3.3 fissa l'ordine con un elemento selezionato: disponibilità e, se non
/// disponibile, il motivo; poi riga; poi cella nella riga; poi eventuale contenuto.
/// L'ultima voce è quella che una divergenza fra i due percorsi farebbe cadere.
/// 02 §3.8 vuole inoltre che l'ordine delle informazioni dopo la testa fissa sia lo
/// stesso in ogni schermata, e il principio 7 vieta che due schermate annuncino le
/// stesse cose in ordine diverso.
///
/// La prova è di CLASSE e non di istanza: percorre ogni casella di ogni mappa e ogni
/// cella della griglia di battaglia, in tutti e tre i livelli di verbosità, e
/// pretende che ogni voce dell'esplorazione compaia nella designazione, nello stesso
/// ordine e in coda alla testa fissa.
@MainActor
final class AnnuncioDiCasellaTest: XCTestCase {

    var ambiente: Ambiente!

    override func setUpWithError() throws {
        ambiente = try Ambiente()
    }

    // MARK: - Mappa di campagna

    func test_02_3_3_la_designazione_di_marcia_non_toglie_nulla_all_esplorazione() async throws {
        for taglia in PartitaCampagna.Taglia.allCases {
            let partita = try await PartitaCampagna(nuova: ambiente, taglia: taglia)
            let stato = await partita.stato
            let gruppo = stato.gruppiOrdinati[0]
            for verbosita in Verbosita.allCases {
                let costruttore = CostruttoreAnnunciCampagna(
                    testi: ambiente.testi, motore: partita.motore, stato: stato, verbosita: verbosita)
                for casella in stato.griglia.tutteLeCaselle {
                    let esplorazione = costruttore.etichettaCasella(casella)
                    let designazione = costruttore.etichettaCasella(
                        casella, designazione: .marcia(gruppo: gruppo.id))
                    accertaCheLaDesignazioneConservi(esplorazione, in: designazione,
                                                     dove: "\(taglia.rawValue)/\(verbosita) \(casella)")
                }
            }
        }
    }

    /// Il caso che il difetto riferito nomina: una casella con acqua. In
    /// esplorazione la dichiara, e in designazione deve dichiararla ancora.
    func test_02_3_3_una_casella_con_acqua_dichiara_l_acqua_anche_in_designazione() async throws {
        let partita = try await PartitaCampagna(nuova: ambiente, taglia: .grande)
        let stato = await partita.stato
        let costruttore = CostruttoreAnnunciCampagna(
            testi: ambiente.testi, motore: partita.motore, stato: stato, verbosita: .normale)
        let acqua = ambiente.testi.termine("terreno." + TerrenoCasella.acqua.rawValue).testo
        let conAcqua = stato.griglia.tutteLeCaselle.filter {
            stato.mappa.terreno(di: $0) == .acqua
        }
        XCTAssertFalse(conAcqua.isEmpty, "la mappa di prova deve contenere acqua")
        let gruppo = stato.gruppiOrdinati[0]
        for casella in conAcqua {
            let designazione = costruttore.etichettaCasella(
                casella, designazione: .marcia(gruppo: gruppo.id))
            XCTAssertTrue(designazione.contains(acqua),
                          "\(casella) tace l'acqua in designazione: «\(designazione)»")
        }
    }

    /// I tre livelli di verbosità tagliano le ULTIME voci e mai porzioni arbitrarie
    /// (00 §9.5), e la testa fissa non è mai tagliata in nessuno dei due percorsi
    /// (02 §3.9).
    func test_00_9_5_la_verbosita_taglia_dalla_coda_e_mai_la_testa_fissa() async throws {
        let partita = try await PartitaCampagna(nuova: ambiente, taglia: .media)
        let stato = await partita.stato
        let gruppo = stato.gruppiOrdinati[0]
        // «Libera» compare quando la coda è vuota e sparisce quando non lo è: non è
        // una voce tagliata ma la dichiarazione che non ce n'è alcuna, e si toglie
        // prima di confrontare i livelli.
        let libera = ambiente.testi.frase("casella.libera").testo
        func annuncio(_ verbosita: Verbosita, _ casella: Cella,
                      _ designazione: CostruttoreAnnunciCampagna.Designazione) -> String {
            let testo = CostruttoreAnnunciCampagna(testi: ambiente.testi, motore: partita.motore,
                                                   stato: stato, verbosita: verbosita)
                .etichettaCasella(casella, designazione: designazione)
            return testo.replacingOccurrences(of: ", " + libera, with: "")
        }
        for designazione: CostruttoreAnnunciCampagna.Designazione in [.nessuna,
                                                                     .marcia(gruppo: gruppo.id)] {
            for casella in stato.griglia.tutteLeCaselle {
                let sintetico = annuncio(.sintetico, casella, designazione)
                let normale = annuncio(.normale, casella, designazione)
                let dettagliato = annuncio(.dettagliato, casella, designazione)
                // La testa fissa sopravvive in ogni livello (02 §3.9).
                let testa = ambiente.testi.frase("casella.testa", casella.riga, casella.colonna).testo
                for livello in [sintetico, normale, dettagliato] {
                    XCTAssertTrue(livello.contains(testa),
                                  "la testa fissa è stata tagliata in \(casella): «\(livello)»")
                }
                // In designazione la disponibilità — il costo o il motivo — chiude l'annuncio in OGNI
                // livello e non si taglia (02 §3.3 dalla versione 2.8): è la stessa voce nei tre livelli,
                // e la si mette da parte prima di confrontare il resto.
                var (s1, n1, d1) = (sintetico, normale, dettagliato)
                if case .marcia = designazione {
                    let coda = sintetico.components(separatedBy: ", ").last ?? ""
                    for livello in [sintetico, normale, dettagliato] {
                        XCTAssertTrue(livello.hasSuffix(", " + coda),
                                      "la disponibilità non chiude ogni livello in \(casella): «\(livello)»")
                    }
                    func senzaCoda(_ t: String) -> String { String(t.dropLast(coda.count + 2)) }
                    (s1, n1, d1) = (senzaCoda(sintetico), senzaCoda(normale), senzaCoda(dettagliato))
                }
                // Il livello più breve è un PREFISSO del più lungo: si taglia dalla
                // coda, mai in mezzo.
                XCTAssertTrue(n1.hasPrefix(s1),
                              "il taglio non parte dalla coda in \(casella): "
                              + "«\(s1)» non è in testa a «\(n1)»")
                XCTAssertTrue(d1.hasPrefix(n1),
                              "il dettagliato non estende il normale in coda in \(casella)")
            }
        }
    }

    /// La propria formazione DICHIARA la sua COMPOSIZIONE (incarico 22): di quali reparti e di
    /// quanti atomi è fatta, con la stessa frase «N atomi di <archetipo>» della divisione. È un
    /// dettaglio in coda alle voci di testa: compare nel livello normale e dettagliato, e il
    /// sintetico la lascia cadere per prima (02 §3.8.1). Nessun termine nuovo del vocabolario.
    func test_incarico_22_la_propria_formazione_dichiara_la_composizione() async throws {
        let partita = try await PartitaCampagna(nuova: ambiente, taglia: .media)
        let stato = await partita.stato
        let gruppo = stato.gruppiOrdinati.first { $0.parte == .giocatore }!
        // La composizione attesa, costruita con le STESSE frasi che l'annuncio userà.
        let parti = gruppo.composizione.map { reparto in
            ambiente.testi.frase("divisione.reparto", soggetto: ambiente.testi.soggetto(.unita, reparto.archetipo),
                                 reparto.atomi).testo
        }
        let composizione = ambiente.testi.frase("casella.composizione",
                                                parti.joined(separator: ", ")).testo
        func annuncio(_ verbosita: Verbosita) -> String {
            CostruttoreAnnunciCampagna(testi: ambiente.testi, motore: partita.motore,
                                       stato: stato, verbosita: verbosita)
                .etichettaCasella(gruppo.posizione)
        }
        // Il livello normale e il dettagliato la dichiarano; il sintetico la lascia cadere.
        XCTAssertTrue(annuncio(.normale).contains(composizione),
                      "il livello normale tace la composizione: «\(annuncio(.normale))»")
        XCTAssertTrue(annuncio(.dettagliato).contains(composizione),
                      "il livello dettagliato tace la composizione: «\(annuncio(.dettagliato))»")
        XCTAssertFalse(annuncio(.sintetico).contains(composizione),
                       "il sintetico non taglia la composizione dalla coda: «\(annuncio(.sintetico))»")
        // La composizione non è vuota: un gruppo ha sempre almeno un reparto (01 §5.6.0.2).
        XCTAssertFalse(gruppo.composizione.isEmpty, "il gruppo di prova deve avere una composizione")
    }

    // MARK: - Griglia di battaglia (stesso meccanismo, mai controllato prima)

    /// La medesima verifica sulla griglia di battaglia, fra l'esplorazione di una
    /// cella e la designazione della destinazione di un movimento. È lo stesso
    /// meccanismo dei due percorsi, e il principio 7 vuole che i due piani si
    /// comportino allo stesso modo.
    func test_02_3_3_in_battaglia_la_designazione_non_toglie_nulla_all_esplorazione() async throws {
        let partita = try await PartitaCorrente(nuova: ambiente)
        // Si piazza un reparto, così che una designazione di movimento esista.
        _ = try await partita.esegui(.seleziona(indiceDeck: 0))
        _ = try await partita.esegui(.piazza(cella: Cella(riga: 9, colonna: 5)))
        _ = try await partita.esegui(.deseleziona)
        let stato = await partita.stato
        let mio = try XCTUnwrap(stato.sciamiOrdinati.first { $0.parte == .giocatore })
        for verbosita in Verbosita.allCases {
            let costruttore = CostruttoreAnnunci(testi: ambiente.testi, motore: partita.motore,
                                                 stato: stato, verbosita: verbosita)
            for cella in stato.griglia.tutteLeCelle {
                let esplorazione = costruttore.etichettaCella(cella)
                let designazione = costruttore.etichettaCella(
                    cella, designazione: .movimento(sciame: mio.id))
                accertaCheLaDesignazioneConservi(esplorazione, in: designazione,
                                                 dove: "battaglia/\(verbosita) \(cella)")
            }
        }
    }

    // MARK: - Attrezzo

    /// Ogni voce dell'esplorazione compare nella designazione, nello stesso ordine e IN TESTA, e la
    /// designazione aggiunge in CODA la disponibilità o il motivo (02 §3.3 dalla versione 2.8: la cella
    /// comincia dalla sua posizione e chiude col costo). Fino alla versione 2.7 l'aggiunta stava in testa.
    private func accertaCheLaDesignazioneConservi(_ esplorazione: String, in designazione: String,
                                                 dove: String,
                                                 file: StaticString = #filePath, line: UInt = #line) {
        let attese = esplorazione.components(separatedBy: ", ")
        let trovate = designazione.components(separatedBy: ", ")
        XCTAssertEqual(Array(trovate.prefix(attese.count)), attese,
                       "\(dove): la designazione non conserva l'annuncio di esplorazione in testa.\n"
                       + "esplorazione: «\(esplorazione)»\ndesignazione: «\(designazione)»",
                       file: file, line: line)
        // La designazione AGGIUNGE in coda, senza togliere nulla: il motivo, oppure il costo — una voce
        // sulla mappa («raggiungibile in N giorni»), due sul campo («costa N», «restano M»). Dal
        // 2026-11-21 (decisione del titolare, incarico 29) l'avvertimento sull'inchiodamento non sta più
        // sulla casella: lo dice una volta il comando di marcia.
        let aggiunte = trovate.count - attese.count
        XCTAssertTrue(aggiunte == 1 || aggiunte == 2,
                      "\(dove): la designazione aggiunge il motivo o il costo (1 o 2 voci), non \(aggiunte).\n"
                      + "designazione: «\(designazione)»",
                      file: file, line: line)
    }
}
