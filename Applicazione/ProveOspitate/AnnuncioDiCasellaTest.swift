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
                // Il livello più breve è un PREFISSO del più lungo: si taglia dalla
                // coda, mai in mezzo.
                XCTAssertTrue(normale.hasPrefix(sintetico),
                              "il taglio non parte dalla coda in \(casella): "
                              + "«\(sintetico)» non è in testa a «\(normale)»")
                XCTAssertTrue(dettagliato.hasPrefix(normale),
                              "il dettagliato non estende il normale in coda in \(casella)")
            }
        }
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

    /// Ogni voce dell'esplorazione compare nella designazione, nello stesso ordine,
    /// e la designazione aggiunge in TESTA la disponibilità o il motivo (02 §3.3).
    private func accertaCheLaDesignazioneConservi(_ esplorazione: String, in designazione: String,
                                                 dove: String,
                                                 file: StaticString = #filePath, line: UInt = #line) {
        let attese = esplorazione.components(separatedBy: ", ")
        let trovate = designazione.components(separatedBy: ", ")
        XCTAssertEqual(Array(trovate.suffix(attese.count)), attese,
                       "\(dove): la designazione non conserva l'annuncio di esplorazione in coda.\n"
                       + "esplorazione: «\(esplorazione)»\ndesignazione: «\(designazione)»",
                       file: file, line: line)
        // La designazione AGGIUNGE in testa, senza togliere nulla: per una
        // destinazione valida la disponibilità E la conseguenza dell'inchiodamento
        // (due voci, correzione del titolare RDA-104); per una non valida il solo
        // motivo (una voce). Nessuna delle due toglie l'esplorazione dalla coda.
        let aggiunte = trovate.count - attese.count
        XCTAssertTrue(aggiunte == 1 || aggiunte == 2,
                      "\(dove): la designazione aggiunge il motivo (1) o disponibilità e "
                      + "inchiodamento (2), non \(aggiunte).\ndesignazione: «\(designazione)»",
                      file: file, line: line)
    }
}
