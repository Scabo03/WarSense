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
        .marciaOrdinata(gruppo: IdGruppo(1), nome: "corvo",
                        da: Cella(riga: 10, colonna: 6), a: Cella(riga: 9, colonna: 6), giorni: 2),
        .marciaCompiuta(gruppo: IdGruppo(1), nome: "corvo",
                        da: Cella(riga: 10, colonna: 6), a: Cella(riga: 9, colonna: 6)),
        .marciaRevocata(gruppo: IdGruppo(1), nome: "corvo",
                        casella: Cella(riga: 10, colonna: 6), giorniPersi: 1),
        .presidioOrdinato(gruppo: IdGruppo(2), nome: "lupo", casella: Cella(riga: 10, colonna: 5)),
        .rifornimentoInterrotto(gruppo: IdGruppo(1), nome: "corvo", casella: Cella(riga: 5, colonna: 5)),
        .sostaDiRifornimento(gruppo: IdGruppo(1), nome: "corvo", casella: Cella(riga: 5, colonna: 5)),
        .rifornimentoRipreso(gruppo: IdGruppo(1), nome: "corvo", casella: Cella(riga: 5, colonna: 5)),
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
        let arrivo = traduttore.annuncio(
            per: .marciaCompiuta(gruppo: IdGruppo(1), nome: "corvo",
                                 da: Cella(riga: 10, colonna: 6), a: Cella(riga: 9, colonna: 6)),
            verbosita: .normale)
        XCTAssertEqual(arrivo?.testo, "Corvo è arrivato in riga 9, casella 6")
    }

    /// L'annuncio della marcia ordinata dichiara i giorni con il PLURALE di sistema:
    /// «1 giorno» al singolare, «più giorni» al plurale. È il modo in cui chi ascolta
    /// riceve la grandezza di origine (01 §5.6.3.3, §5.6.3.4).
    func test_01_5_6_3_3_l_annuncio_della_marcia_ordinata_declina_i_giorni() throws {
        func detto(_ giorni: Int) -> String {
            traduttore.annuncio(
                per: .marciaOrdinata(gruppo: IdGruppo(1), nome: "corvo",
                                     da: Cella(riga: 10, colonna: 6),
                                     a: Cella(riga: 9, colonna: 6), giorni: giorni),
                verbosita: .normale)?.testo ?? "‼️"
        }
        XCTAssertEqual(detto(1), "Corvo marcia verso riga 9, casella 6, 1 giorno al termine")
        XCTAssertEqual(detto(3), "Corvo marcia verso riga 9, casella 6, 3 giorni al termine")
    }

    /// La revoca dichiara i giorni persi con il plurale: la conseguenza che
    /// 01 §5.6.3.5 vuole detta.
    func test_01_5_6_3_3_l_annuncio_della_revoca_declina_i_giorni_persi() throws {
        func detto(_ giorni: Int) -> String {
            traduttore.annuncio(
                per: .marciaRevocata(gruppo: IdGruppo(1), nome: "corvo",
                                     casella: Cella(riga: 10, colonna: 6), giorniPersi: giorni),
                verbosita: .normale)?.testo ?? "‼️"
        }
        XCTAssertEqual(detto(1), "Corvo: marcia revocata, perso 1 giorno")
        XCTAssertEqual(detto(2), "Corvo: marcia revocata, persi 2 giorni")
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

    /// I segnali del rifornimento (02 §11.5, §11.7.1): il taglio e la sosta imposta
    /// portano lo stesso segnale dedicato «rifornimento interrotto» — un solo richiamo
    /// tattile, e le parole dicono quale dei due; la ripresa è buona notizia e non ha
    /// segnale proprio (il tetto è chiuso), ma la si annuncia a voce.
    func test_02_11_7_i_segnali_del_rifornimento() throws {
        let luogo = Cella(riga: 5, colonna: 5)
        XCTAssertEqual(traduttore.significato(
            per: .rifornimentoInterrotto(gruppo: IdGruppo(1), nome: "corvo", casella: luogo)),
                       .rifornimentoInterrotto)
        XCTAssertEqual(traduttore.significato(
            per: .sostaDiRifornimento(gruppo: IdGruppo(1), nome: "corvo", casella: luogo)),
                       .rifornimentoInterrotto)
        XCTAssertNil(traduttore.significato(
            per: .rifornimentoRipreso(gruppo: IdGruppo(1), nome: "corvo", casella: luogo)),
                     "la ripresa non aggiunge un segnale al tetto chiuso")
    }

    func test_02_4_ogni_termine_del_vocabolario_di_campagna_esiste_nei_testi() throws {
        for stato in StatoGruppo.casiDiRiferimento {
            switch stato {
            case .inAttesa, .haAgito:
                XCTAssertTrue(testi.esiste(stato.chiaveTesto, tavola: "Vocabolario"),
                              "manca il termine \(stato.chiaveTesto)")
            case .inMarcia:
                // «in marcia» porta i giorni mancanti e declina al plurale: vive nel
                // .stringsdict della tavola Annunci, non nel vocabolario semplice.
                XCTAssertTrue(testi.esiste(stato.chiaveTesto, tavola: "Annunci"),
                              "manca il plurale di \(stato.chiaveTesto)")
            }
        }
        for motivo in MotivoNonValidoCampagna.allCases {
            XCTAssertTrue(testi.esiste(motivo.rawValue, tavola: "Vocabolario"),
                          "manca il termine \(motivo.rawValue)")
        }
        // Gli stati di rifornimento (01 §5.2.2, 02 §4.4.5): ciascuno ha il proprio
        // termine chiuso, che questa unità realizza usando le chiavi già riservate.
        for stato in StatoRifornimento.casiDiRiferimento {
            XCTAssertTrue(testi.esiste(stato.chiaveTesto, tavola: "Vocabolario"),
                          "manca il termine dello stato di rifornimento \(stato.chiaveTesto)")
        }
        // Gli stati di conoscenza (01 §5.3, 02 §4.2): «avvistato» porta i turni e vive
        // nel .stringsdict degli Annunci; gli altri sono termini semplici.
        for stato in StatoConoscenza.casiDiRiferimento {
            let tavola = { if case .avvistato = stato { return "Annunci" } else { return "Vocabolario" } }()
            XCTAssertTrue(testi.esiste(stato.chiaveTesto, tavola: tavola),
                          "manca il termine dello stato di conoscenza \(stato.chiaveTesto)")
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
        for fatto in FattoRegistrato.casiDiRiferimento {
            let voce = VoceRegistro(numero: 0, giorno: 7, fatto: fatto)
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
                                       gruppiGiocatore: [.init(riga: 4, colonna: 2,
                                           composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)])]),
            valori: valoriCampagna, archetipiNoti: Set(valori.archetipi.keys))
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
