import XCTest
import Segnali
import Motore
import Dati
import Contenuti

/// Collaudo degli annunci di campagna per CONTENUTO (05 §14.4): ogni evento ha il
/// proprio modello nei tre livelli di verbosità, nella lingua dichiarata, e nessun
/// annuncio esce con la chiave irrisolta.
final class TraduttoreCampagnaTest: XCTestCase {

    var testi: Testi!
    var traduttore: TraduttoreEventiCampagna!

    override func setUpWithError() throws {
        testi = try Testi.carica(albero: Contenuti.testiDiFabbrica, lingua: "it")
        traduttore = TraduttoreEventiCampagna(testi: testi, parte: .giocatore)
    }

    private let eventi: [EventoCampagna] = [
        .marciaEseguita(gruppo: IdGruppo(1), nome: "corvo",
                        da: Cella(riga: 10, colonna: 6), a: Cella(riga: 9, colonna: 6)),
        .presidioOrdinato(gruppo: IdGruppo(2), nome: "lupo", casella: Cella(riga: 10, colonna: 5)),
        .giornataChiusa(giorno: 1),
        .giornataAperta(giorno: 2),
    ]

    func test_05_10_7_ogni_evento_annunciabile_ha_il_suo_modello_nei_tre_livelli() throws {
        for evento in eventi {
            for verbosita in Verbosita.allCases {
                guard let annuncio = traduttore.annuncio(per: evento, verbosita: verbosita) else {
                    // Soltanto la chiusura della giornata tace: l'apertura la racconta.
                    XCTAssertEqual(evento, .giornataChiusa(giorno: 1),
                                   "evento senza modello di annuncio: \(evento)")
                    continue
                }
                XCTAssertFalse(annuncio.testo.contains(Testi.segnaposto),
                               "chiave irrisolta per \(evento) al livello \(verbosita)")
                XCTAssertFalse(annuncio.testo.isEmpty)
                XCTAssertEqual(annuncio.lingua, "it", "ogni testo dichiara la propria lingua (00 §14.4)")
            }
        }
    }

    func test_00_14_2_l_annuncio_e_una_frase_intera_con_i_segnaposto_riempiti() throws {
        let annuncio = traduttore.annuncio(
            per: .marciaEseguita(gruppo: IdGruppo(1), nome: "corvo",
                                 da: Cella(riga: 10, colonna: 6), a: Cella(riga: 9, colonna: 6)),
            verbosita: .normale)
        XCTAssertEqual(annuncio?.testo, "Corvo marcia in riga 9, casella 6")
    }

    func test_02_11_5_la_chiusura_della_giornata_non_aggiunge_un_significato_tattile() throws {
        // Il tetto dei significati è chiuso a quindici (02 §11.5) e l'elenco degli
        // eventi fuori dal tetto è anch'esso chiuso (02 §11.7.1).
        XCTAssertNil(traduttore.significato(per: .giornataAperta(giorno: 2)))
        XCTAssertNil(traduttore.significato(per: .giornataChiusa(giorno: 1)))
        XCTAssertEqual(traduttore.significato(
            per: .presidioOrdinato(gruppo: IdGruppo(1), nome: "corvo",
                                   casella: Cella(riga: 1, colonna: 1))), .conferma,
                       "l'ordine confermato usa il significato 3, che 02 §11.7.1 nomina proprio così")
    }

    func test_02_4_ogni_termine_del_vocabolario_di_campagna_esiste_nei_testi() throws {
        for stato in StatoGruppo.allCases {
            XCTAssertTrue(testi.esiste(stato.rawValue, tavola: "Vocabolario"),
                          "manca il termine \(stato.rawValue)")
        }
        for motivo in MotivoNonValidoCampagna.allCases {
            XCTAssertTrue(testi.esiste(motivo.rawValue, tavola: "Vocabolario"),
                          "manca il termine \(motivo.rawValue)")
        }
        for terreno in TerrenoCasella.allCases where terreno != .aperto {
            XCTAssertTrue(testi.esiste("terreno." + terreno.rawValue, tavola: "Vocabolario"),
                          "manca il termine del terreno \(terreno.rawValue)")
        }
        for strada in TipoStrada.allCases where strada != .nessuna {
            XCTAssertTrue(testi.esiste("strada." + strada.rawValue, tavola: "Vocabolario"),
                          "manca il termine della strada \(strada.rawValue)")
        }
    }

    func test_01_5_6_0_4_ogni_nome_dell_elenco_chiuso_ha_il_proprio_testo() throws {
        let valori = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        for chiave in valori.nomiGruppi {
            XCTAssertTrue(testi.esiste("gruppo.nome." + chiave, tavola: "Vocabolario"),
                          "manca il nome parlato del gruppo \(chiave)")
        }
    }

    func test_05_7_8_ogni_errore_dei_dati_di_campagna_ha_la_propria_chiave_di_testo() throws {
        // Il rapporto di validazione parla all'utente anche quando è il pacchetto in
        // Documenti a essere rotto: le chiavi si risolvono sulla fabbrica (05 §7.8).
        for chiave in ["errore.dati.formato_ignoto", "errore.dati.casella_fuori_mappa",
                       "errore.dati.casella_ripetuta", "errore.dati.strettoia_fuori_mappa",
                       "errore.dati.quartier_generale_incoerente",
                       "errore.dati.quartier_generale_non_in_ultima_riga",
                       "errore.dati.nomi_gruppi_incoerenti"] {
            XCTAssertTrue(testi.esiste(chiave), "manca la chiave d'errore \(chiave)")
        }
    }

    func test_02_6_6_ogni_fatto_del_registro_ha_la_propria_frase_compiuta() throws {
        for fatto in FattoRegistrato.allCases {
            let voce = VoceRegistro(numero: 0, giorno: 7, fatto: fatto, luogo: nil)
            let frase = traduttore.voceDiRegistro(voce)
            XCTAssertFalse(frase.testo.contains(Testi.segnaposto), "manca la frase per \(fatto)")
            XCTAssertTrue(frase.testo.contains("7"), "la voce dichiara il giorno cui si riferisce")
        }
    }

    // MARK: - Che cosa il giocatore sente alla chiusura e all'apertura di una giornata

    /// La sequenza esatta di ciò che viene detto quando l'ultimo ordine della
    /// giornata la chiude. Non è una descrizione: è la sequenza vera, prodotta dal
    /// Motore e tradotta dal traduttore, fissata perché non cambi per caso.
    func test_01_5_6_0_6_che_cosa_si_sente_alla_chiusura_e_all_apertura_di_una_giornata() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        let motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
        var stato = try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: "guado",
                                       gruppiGiocatore: [.init(riga: 4, colonna: 2)]),
            valori: valoriCampagna)
        let id = stato.gruppiOrdinati[0].id
        let (dopo, eventi) = motore.applica(.presidio(gruppo: id), parte: .giocatore, stato: stato)
        stato = dopo

        let dette = eventi.compactMap { traduttore.annuncio(per: $0, verbosita: .normale)?.testo }
        XCTAssertEqual(dette, ["Corvo presidia in riga 4, casella 2",
                               "Giornata conclusa: comincia il giorno 2"],
                       "il giocatore sente due frasi: la conferma del proprio ordine, poi la giornata")
        // La chiusura non produce una frase propria: l'apertura la racconta, e due
        // frasi per un fatto solo sarebbero ridondanza (02 §8.7.1).
        XCTAssertNil(traduttore.annuncio(per: .giornataChiusa(giorno: 1), verbosita: .normale))
        // Il segnale accompagna il solo ordine confermato: il tetto dei significati
        // resta chiuso a quindici (02 §11.5, RDA-64).
        let significati = eventi.compactMap { traduttore.significato(per: $0) }
        XCTAssertEqual(significati, [.conferma])
    }

    func test_00_13_8_l_annullamento_che_riapre_la_giornata_ha_una_frase_propria() throws {
        // Chi ascolta deve distinguere il ritiro di un ordine dal calendario che
        // torna indietro: sono due fatti diversi e hanno due frasi diverse.
        let ordinario = testi.frase("campagna.annullato_conferma").testo
        let conRiapertura = testi.frase("campagna.annullato_giornata_riaperta", 3).testo
        XCTAssertNotEqual(ordinario, conRiapertura)
        XCTAssertFalse(conRiapertura.contains(Testi.segnaposto))
        XCTAssertTrue(conRiapertura.contains("3"), "la frase dichiara il giorno a cui si torna")
        let azzeramento = testi.frase("campagna.azzerato_giornata_riaperta", 3).testo
        XCTAssertFalse(azzeramento.contains(Testi.segnaposto))
        XCTAssertTrue(azzeramento.contains("3"))
    }
}
