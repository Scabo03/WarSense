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

    /// La presa del quartier generale (02 §8.2.2; incarico 32): ciascun passo, detto a chi occupa e a chi è
    /// occupato, per esteso e nel livello sintetico, col numero delle giornate accordato.
    func test_02_8_2_2_l_occupazione_di_un_quartier_generale_si_annuncia_alle_due_parti() throws {
        let casella = Cella(riga: 4, colonna: 2)
        func detto(_ evento: EventoCampagna, _ verbosita: Verbosita = .normale) -> String {
            traduttore.annuncio(per: evento, verbosita: verbosita)?.testo ?? ""
        }
        // Il difensore.
        XCTAssertEqual(detto(.quartierGeneraleOccupato(casella: casella, occupante: .avversario, mancano: 3)),
                       "L'avversario occupa il tuo quartier generale, in riga 4, casella 2: se non lo scacci sarà preso fra 3 giornate")
        XCTAssertEqual(detto(.quartierGeneraleOccupato(casella: casella, occupante: .avversario, mancano: 1)),
                       "L'avversario occupa il tuo quartier generale, in riga 4, casella 2: se non lo scacci sarà preso fra 1 giornata")
        XCTAssertEqual(detto(.occupazioneProsegue(casella: casella, occupante: .avversario, mancano: 2)),
                       "Il tuo quartier generale è ancora occupato: sarà preso fra 2 giornate")
        XCTAssertEqual(detto(.occupazioneProsegue(casella: casella, occupante: .avversario, mancano: 1)),
                       "Il tuo quartier generale è ancora occupato: sarà preso fra 1 giornata")
        XCTAssertEqual(detto(.occupazioneInterrotta(casella: casella, occupante: .avversario)),
                       "L'avversario non occupa più il tuo quartier generale: il conteggio si azzera")
        XCTAssertEqual(detto(.quartierGeneralePreso(casella: casella, occupante: .avversario)),
                       "Il tuo quartier generale in riga 4, casella 2 è caduto: te ne resta un altro")
        // L'attaccante.
        XCTAssertEqual(detto(.quartierGeneraleOccupato(casella: casella, occupante: .giocatore, mancano: 3)),
                       "Occupi il quartier generale avversario, in riga 4, casella 2: se lo tieni sarà preso fra 3 giornate")
        XCTAssertEqual(detto(.occupazioneProsegue(casella: casella, occupante: .giocatore, mancano: 1)),
                       "Tieni il quartier generale avversario: sarà preso fra 1 giornata")
        XCTAssertEqual(detto(.occupazioneInterrotta(casella: casella, occupante: .giocatore)),
                       "Non occupi più il quartier generale avversario: il conteggio si azzera")
        XCTAssertEqual(detto(.quartierGeneralePreso(casella: casella, occupante: .giocatore)),
                       "Il quartier generale avversario in riga 4, casella 2 è caduto: ne resta un altro")
        // Il livello sintetico tiene il fatto e le giornate.
        XCTAssertEqual(detto(.quartierGeneraleOccupato(casella: casella, occupante: .avversario, mancano: 3), .sintetico),
                       "Tuo quartier generale occupato, 3 giornate alla presa")
        XCTAssertEqual(detto(.occupazioneProsegue(casella: casella, occupante: .giocatore, mancano: 1), .sintetico),
                       "Quartier generale avversario occupato, 1 giornata alla presa")
        // Nessuno aggiunge un segnale tattile, e nessuno cambia schermata.
        for evento in [EventoCampagna.quartierGeneraleOccupato(casella: casella, occupante: .avversario, mancano: 3),
                       .occupazioneProsegue(casella: casella, occupante: .avversario, mancano: 2),
                       .occupazioneInterrotta(casella: casella, occupante: .avversario),
                       .quartierGeneralePreso(casella: casella, occupante: .avversario)] {
            XCTAssertNil(traduttore.significato(per: evento))
            XCTAssertFalse(TraduttoreEventiCampagna.cambiaSchermata(evento))
            for verbosita in Verbosita.allCases { XCTAssertFalse(detto(evento, verbosita).contains(Testi.segnaposto)) }
        }
        // La conclusione dice la caduta, o il richiamo.
        XCTAssertEqual(detto(.campagnaConclusa(modo: .presa, vincitore: .giocatore)),
                       "Campagna conclusa: il quartier generale avversario è caduto. Hai vinto")
        XCTAssertEqual(detto(.campagnaConclusa(modo: .presa, vincitore: .avversario)),
                       "Campagna conclusa: il tuo quartier generale è caduto. Hai perso")
        XCTAssertEqual(detto(.campagnaConclusa(modo: .richiamo, vincitore: .avversario)),
                       "Campagna conclusa: hai richiamato l'esercito in patria. Conta come perduta")
        // Il registro.
        func voce(_ fatto: FattoRegistrato) -> String {
            traduttore.voceDiRegistro(VoceRegistro(numero: 1, giorno: 12, fatto: fatto)).testo
        }
        XCTAssertEqual(voce(.quartierGeneraleOccupato(casella: casella)),
                       "Giorno 12: l'avversario occupa il tuo quartier generale in riga 4, casella 2")
        XCTAssertEqual(voce(.quartierGeneraleLiberato(casella: casella)),
                       "Giorno 12: l'avversario non occupa più il tuo quartier generale in riga 4, casella 2")
        XCTAssertEqual(voce(.quartierGeneralePreso(casella: casella, dalGiocatore: true)),
                       "Giorno 12: preso il quartier generale avversario in riga 4, casella 2")
        XCTAssertEqual(voce(.quartierGeneralePreso(casella: casella, dalGiocatore: false)),
                       "Giorno 12: il tuo quartier generale in riga 4, casella 2 è caduto")
    }

    /// Perché l'esercito non si può richiamare (01 §5.18.2, 02 §6.5.5): il motivo, col gruppo e il luogo, nel
    /// genere e nel numero del nome.
    func test_02_6_5_5_il_richiamo_impedito_dice_il_perche() throws {
        let casella = Cella(riga: 2, colonna: 3)
        func detto(_ impedimento: ImpedimentoDelRichiamo) -> String { traduttore.impedimento(impedimento).testo }
        XCTAssertEqual(detto(.battagliaInSospeso(casella: casella)), "c'è una battaglia in sospeso in riga 2, casella 3")
        XCTAssertEqual(detto(.rifornimentoTagliato(gruppo: "lupo", casella: casella)),
                       "Lupo ha il rifornimento tagliato in riga 2, casella 3")
        XCTAssertEqual(detto(.aContatto(gruppo: "aquila", casella: casella)),
                       "Aquila è a contatto con l'avversario in riga 2, casella 3")
        XCTAssertEqual(detto(.campagnaConclusa), "la campagna è conclusa")
        let valori = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        for nome in valori.nomiGruppi {
            XCTAssertFalse(detto(.rifornimentoTagliato(gruppo: nome, casella: casella)).contains(Testi.segnaposto), nome)
            XCTAssertFalse(detto(.aContatto(gruppo: nome, casella: casella)).contains(Testi.segnaposto), nome)
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
            case .inAttesa, .haAgito, .inAgguato:
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
            XCTAssertTrue(testi.esiste(CategoriaSoggetto.gruppo.prefisso + chiave, tavola: "Vocabolario"),
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

    /// Le voci del registro con un gruppo per soggetto si accordano al suo genere (02 §4.6, incarico 29):
    /// la chiave della frase viene dal fatto (`chiaveTesto`) e non è scritta nel codice, sicché il
    /// controllo statico dei sorgenti la ammette e la verifica qui, risolvendola per un nome maschile e
    /// per uno femminile. Nessuna forma manca, e dove l'accordo cambia la frase cambia.
    func test_incarico_29_le_voci_del_registro_si_accordano_al_genere() throws {
        let casella = Cella(riga: 4, colonna: 2)
        func fatti(_ nome: String) -> [FattoRegistrato] {
            [.marciaRevocata(gruppo: nome, casella: casella),
             .rifornimentoInterrotto(gruppo: nome, casella: casella),
             .sostaDiRifornimento(gruppo: nome, casella: casella),
             .rifornimentoRipreso(gruppo: nome, casella: casella),
             .esploratoriPerduti(gruppo: nome, casella: casella),
             .esploratoriNotati(gruppo: nome, casella: casella)]
        }
        for nome in ["corvo", "aquila"] {
            for fatto in fatti(nome) {
                let frase = traduttore.voceDiRegistro(VoceRegistro(numero: 0, giorno: 7, fatto: fatto)).testo
                XCTAssertFalse(frase.contains(Testi.segnaposto), "manca la forma per \(fatto)")
                XCTAssertTrue(frase.hasPrefix("Giorno 7: "), "il giorno apre la voce: «\(frase)»")
                XCTAssertTrue(frase.contains(nome.capitalized), "il soggetto è nella voce: «\(frase)»")
            }
        }
        let sostaAquila = traduttore.voceDiRegistro(VoceRegistro(numero: 0, giorno: 7,
            fatto: .sostaDiRifornimento(gruppo: "aquila", casella: casella))).testo
        XCTAssertEqual(sostaAquila, "Giorno 7: Aquila costretta alla sosta di rifornimento in riga 4, casella 2")
        let sostaCorvo = traduttore.voceDiRegistro(VoceRegistro(numero: 0, giorno: 7,
            fatto: .sostaDiRifornimento(gruppo: "corvo", casella: casella))).testo
        XCTAssertEqual(sostaCorvo, "Giorno 7: Corvo costretto alla sosta di rifornimento in riga 4, casella 2")
    }

    /// Gli annunci con un gruppo per soggetto si accordano al suo genere (02 §4.6, incarico 29), in ogni
    /// livello di verbosità: «Aquila è arrivata», «Corvo è arrivato».
    func test_incarico_29_gli_annunci_si_accordano_al_genere_del_gruppo() throws {
        let a = Cella(riga: 9, colonna: 6)
        let arrivoAquila = traduttore.annuncio(per: .marciaCompiuta(gruppo: IdGruppo(1), nome: "aquila",
                                                                    da: a, a: a), verbosita: .normale)
        XCTAssertEqual(arrivoAquila?.testo, "Aquila è arrivata in riga 9, casella 6")
        let agguato = traduttore.annuncio(per: .imboscataOrdinata(gruppo: IdGruppo(1), nome: "volpe", casella: a),
                                          verbosita: .normale)
        XCTAssertEqual(agguato?.testo, "Volpe si è messa in agguato in riga 9, casella 6")
        for nome in ["corvo", "aquila"] {
            for evento in [EventoCampagna.marciaCompiuta(gruppo: IdGruppo(1), nome: nome, da: a, a: a),
                           .gruppiRiuniti(risultante: IdGruppo(1), nome: nome, assorbito: IdGruppo(2), casella: a),
                           .esplorazioneCompiuta(parte: .giocatore, gruppo: IdGruppo(1), nome: nome, casella: a, esito: .notati)] {
                for verbosita in Verbosita.allCases {
                    let testo = traduttore.annuncio(per: evento, verbosita: verbosita)?.testo ?? ""
                    XCTAssertFalse(testo.contains(Testi.segnaposto), "manca la forma per \(evento) a \(verbosita)")
                }
            }
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
