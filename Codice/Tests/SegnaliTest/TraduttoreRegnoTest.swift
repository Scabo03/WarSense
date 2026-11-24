import XCTest
import Segnali
import Motore
import Dati
import Contenuti

/// Le frasi del regno (incarico 30): vocabolario chiuso, costo sulla riserva, impossibilità con la
/// risorsa che manca, frasi accordate al genere della voce, registro della patria, dichiarazione
/// di conclusione. Ogni fatto e ogni motivo ha la propria frase, e nessuna resta irrisolta.
///
/// Le frasi della seconda tappa (incarico 31) — le righe delle formazioni, le reclute, il
/// mantenimento, i miglioramenti, la scelta di chi parte — hanno le proprie prove in
/// `TraduttoreRegnoSecondaTappaTest`.
final class TraduttoreRegnoTest: XCTestCase {

    var testi: Testi!
    var traduttore: TraduttoreEventiRegno!
    var valoriRegno: ValoriRegno!
    var motore: MotoreRegno!

    override func setUpWithError() throws {
        testi = try Testi.carica(albero: Contenuti.testiDiFabbrica, lingua: "it")
        traduttore = TraduttoreEventiRegno(testi: testi)
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriRegno = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica,
                                                 archetipiNoti: Set(valori.archetipi.keys),
                                                 miglioramentiNoti: Set(valori.miglioramenti.keys))
        motore = MotoreRegno(valori: valoriRegno)
    }

    /// Il costo di una leva com'è adesso: la voce porta con sé la propria misura.
    private func costo(_ voce: VoceDelRegno) throws -> Riserve {
        try XCTUnwrap(motore.costo(di: voce, bersaglio: nil, stato: try motore.statoIniziale()))
    }

    private func forzeIniziali() throws -> ForzeDelRegno {
        try ForzeDelRegno.iniziali(valoriRegno.forzeIniziali, nomi: valoriRegno.nomiDelleUnita)
    }

    private func risolta(_ testo: String, _ che: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(testo.isEmpty, "\(che): frase vuota", file: file, line: line)
        XCTAssertFalse(testo.contains(Testi.segnaposto), "\(che): chiave irrisolta in «\(testo)»", file: file, line: line)
        XCTAssertFalse(testo.contains("%"), "\(che): segnaposto non riempito in «\(testo)»", file: file, line: line)
    }

    // MARK: - Vocabolario chiuso (02 §4)

    func test_02_4_ogni_termine_del_regno_esiste_nel_vocabolario() throws {
        for motivo in MotivoNonValidoRegno.casiDiRiferimento {
            XCTAssertTrue(testi.esiste(motivo.chiaveTesto, tavola: "Vocabolario"), "manca il termine \(motivo.chiaveTesto)")
        }
        for risorsa in Risorsa.allCases {
            let chiave = TraduttoreEventiRegno.chiave(di: risorsa, fase: valoriRegno.faseIniziale)
            XCTAssertTrue(testi.esiste(chiave, tavola: "Vocabolario"), "manca il termine \(chiave)")
            risolta(traduttore.termine(risorsa, fase: valoriRegno.faseIniziale), chiave)
        }
        for stagione in Stagione.allCases {
            XCTAssertTrue(testi.esiste(stagione.chiaveTesto, tavola: "Vocabolario"), "manca \(stagione.chiaveTesto)")
        }
        XCTAssertTrue(testi.esiste(MotivoNonValidoCampagna.campagnaConclusa.rawValue, tavola: "Vocabolario"))
    }

    func test_ogni_voce_e_ogni_fronte_dei_valori_ha_il_proprio_nome() throws {
        for voce in valoriRegno.voci {
            let soggetto = traduttore.voce(voce.identificatore)
            XCTAssertNotNil(soggetto.genere, "la voce \(voce.identificatore) dichiara il proprio genere (02 §4.6)")
            risolta(testi.frase("regno.voce_nome", soggetto: soggetto).testo, voce.identificatore)
        }
        for fronte in valoriRegno.fronti {
            let nome = traduttore.fronte(fronte.identificatore)
            risolta(nome, fronte.identificatore)
            XCTAssertTrue(nome.hasPrefix("fronte "),
                          "ogni fronte si chiama per punti di riferimento e comincia con «fronte» (01 §5.6.9)")
        }
    }

    func test_05_7_8_l_errore_dei_valori_del_regno_ha_la_propria_chiave_di_testo() {
        XCTAssertTrue(testi.esiste("errore.dati.regno_incoerente"))
    }

    // MARK: - Costo e impossibilità (01 §5.9.1.5, 02 §8.7)

    func test_02_8_7_il_costo_si_dice_su_quanto_se_ne_possiede_e_per_le_sole_risorse_consumate() throws {
        let voce = try XCTUnwrap(valoriRegno.voce("leva_fanteria_leggera"))
        let costo = try costo(voce)
        let riserve = Riserve(["denaro": 220, "uomini": 26, "metalli": 33, "materiale": 33, "animali": 13])
        XCTAssertEqual(traduttore.costo(costo, su: riserve, fase: .arcaica),
                       "Costa: monete di bronzo 30 su 220, uomini 6 su 26, metalli 3 su 33.")
        XCTAssertEqual(traduttore.elenco(riserve, fase: .arcaica),
                       "monete di bronzo 220, uomini 26, metalli 33, materiale da costruzione 33, animali 13")
        XCTAssertEqual(traduttore.elenco(.vuote, fase: .arcaica), "")
    }

    func test_01_5_9_1_5_l_impossibilita_nomina_ogni_risorsa_che_manca() {
        XCTAssertEqual(traduttore.impedimento([.uomini], fase: .arcaica), "Non si può ordinare: mancano uomini.")
        XCTAssertEqual(traduttore.impedimento(Risorsa.allCases, fase: .arcaica),
                       "Non si può ordinare: mancano monete di bronzo, mancano uomini, mancano metalli, "
                       + "manca materiale da costruzione, mancano animali.")
        XCTAssertEqual(traduttore.motivo(.risorseInsufficienti([.metalli]), fase: .arcaica).testo,
                       "Non si può ordinare: mancano metalli.")
        XCTAssertEqual(traduttore.motivo(.nonEInverno, fase: .arcaica).testo, "si ordina soltanto d'inverno")
    }

    func test_02_8_7_1_l_etichetta_della_voce_dice_l_impossibilita_soltanto_quando_c_e() throws {
        let voce = try XCTUnwrap(valoriRegno.voce("leva_fanteria_pesante"))
        let costo = try costo(voce)
        let piene = Riserve(["denaro": 220, "uomini": 26, "metalli": 33, "materiale": 33, "animali": 13])
        XCTAssertEqual(traduttore.etichetta(dellaVoce: voce, costo: costo, riserve: piene, pronta: .primavera,
                                            fase: .arcaica, verbosita: .normale),
                       "Leva di fanteria pesante. Costa: monete di bronzo 64 su 220, uomini 8 su 26, metalli 16 su 33. "
                       + "8 atomi, pronta in primavera.",
                       "una voce acquistabile non dichiara di esserlo (02 §8.7.1)")
        let scarse = Riserve(["denaro": 220, "uomini": 4, "metalli": 3, "materiale": 33, "animali": 13])
        XCTAssertEqual(traduttore.etichetta(dellaVoce: voce, costo: costo, riserve: scarse, pronta: .primavera,
                                            fase: .arcaica, verbosita: .normale),
                       "Leva di fanteria pesante. Non si può ordinare: mancano uomini, mancano metalli. "
                       + "Costa: monete di bronzo 64 su 220, uomini 8 su 4, metalli 16 su 3. 8 atomi, pronta in primavera.",
                       "l'impossibilità si dice prontamente, con le risorse che mancano (01 §5.9.1.5)")
        // I livelli brevi tagliano dalla coda (00 §9.5): il sintetico omette ciò che la voce dà.
        XCTAssertEqual(traduttore.etichetta(dellaVoce: voce, costo: costo, riserve: piene, pronta: .primavera,
                                            fase: .arcaica, verbosita: .sintetico),
                       "Leva di fanteria pesante. Costa: monete di bronzo 64 su 220, uomini 8 su 26, metalli 16 su 33.")
        XCTAssertEqual(traduttore.etichetta(dellaVoce: voce, costo: costo, riserve: piene, pronta: .primavera,
                                            fase: .arcaica, verbosita: .dettagliato),
                       traduttore.etichetta(dellaVoce: voce, costo: costo, riserve: piene, pronta: .primavera,
                                            fase: .arcaica, verbosita: .normale))
    }

    // MARK: - Eventi (05 §10.7)

    func test_05_10_7_ogni_evento_del_regno_ha_il_proprio_annuncio() throws {
        let forze = try forzeIniziali()
        let esito = EsitoCampagna(fronte: "guado", anno: 1, modo: .annientamento, vincitore: .giocatore,
                                  giornate: 12, battaglieVinte: 1, battagliePerse: 0, superstiti: forze)
        XCTAssertEqual(traduttore.annuncio(per: .campagnaAperta(fronte: "guado"), fase: .arcaica)?.testo,
                       "Campagna aperta sul fronte del guado")
        XCTAssertNil(traduttore.annuncio(per: .campagnaConclusa(esito: esito), fase: .arcaica),
                     "la conclusione ha la propria schermata (05 §9.3)")
        // Senza nulla da mantenere l'inverno si annuncia com'era: le condizioni assenti non si
        // nominano (02 §8.7.1). Il mantenimento e ciò che scioglie hanno le proprie frasi
        // (`TraduttoreRegnoSecondaTappaTest`).
        XCTAssertEqual(traduttore.annuncio(
            per: .invernoCominciato(anno: 1, entrata: Riserve(["denaro": 200, "uomini": 24, "metalli": 30,
                                                               "materiale": 30, "animali": 12]),
                                    mantenimento: .vuote, sciolti: []),
            fase: .arcaica)?.testo,
            "Comincia l'inverno dell'anno 1. Entrate: monete di bronzo 200, uomini 24, metalli 30, "
            + "materiale da costruzione 30, animali 12.")
        XCTAssertEqual(traduttore.annuncio(
            per: .lavoroOrdinato(voce: "leva_fanteria_leggera", costo: .vuote, pronto: .primavera, bersaglio: nil),
            fase: .arcaica)?.testo, "Leva di fanteria leggera ordinata: pronta in primavera.")
        XCTAssertEqual(traduttore.annuncio(per: .stazioneAperta(stazione: 2), fase: .arcaica)?.testo,
                       "Inverno, schermata 2 di 4")
        XCTAssertEqual(traduttore.annuncio(
            per: .primaveraCominciata(anno: 2, perduto: .vuote, ingressi: [], migliorati: [],
                                      miglioramentiPerduti: []), fase: .arcaica)?.testo,
            "Comincia la primavera dell'anno 2.", "le condizioni assenti non si nominano (02 §8.7.1)")
        // La primavera col riporto e con ciò che l'inverno ha preparato. Dall'incarico 31 l'evento
        // non elenca più le voci pronte («Leva di fanteria leggera: è pronta»): dichiara dove e come
        // le reclute entrano — qui una formazione sola, pronta in primavera.
        XCTAssertEqual(traduttore.annuncio(
            per: .primaveraCominciata(anno: 2, perduto: Riserve(["denaro": 64, "uomini": 4]),
                                      ingressi: [Esemplari.ingresso(.primavera, confluite: false)],
                                      migliorati: [], miglioramentiPerduti: []),
            fase: .arcaica)?.testo,
            "Comincia la primavera dell'anno 2. Il riporto ha tolto: monete di bronzo 64, uomini 4. "
            + "Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, ed entra sul fronte "
            + "in primavera, al quartier generale.")
        XCTAssertEqual(traduttore.significato(per: .campagnaAperta(fronte: "guado")), .conferma)
        XCTAssertEqual(traduttore.significato(per: .lavoroOrdinato(voce: "leva_fanteria_leggera", costo: .vuote,
                                                                   pronto: .primavera, bersaglio: nil)), .conferma)
        XCTAssertNil(traduttore.significato(per: .stazioneAperta(stazione: 2)),
                     "il tetto dei significati è chiuso (02 §11.5)")
    }

    func test_02_4_6_le_frasi_delle_voci_si_accordano_al_genere() throws {
        // Le leve sono femminili, e dall'incarico 31 l'addestramento e il suo mantenimento sono
        // maschili; le forme esistono per tutti e quattro i generi (`AccordoDiGenereTest`), e qui si
        // provano quelle che il vocabolario porta.
        let forze = try forzeIniziali()
        let lavoro = LavoroOrdinato(voce: "leva_cavalleria_manovrata", costo: .vuote, stazione: 1,
                                    effetto: .reclutaReparto(archetipo: "cavalleria_manovrata", atomi: 6),
                                    pronto: .primavera)
        XCTAssertEqual(traduttore.lavoroElencato(lavoro, forze: forze), "Leva di cavalleria manovrata, pronta in primavera")
        let addestramento = LavoroOrdinato(voce: "addestramento_mirato", costo: .vuote, stazione: 1,
                                           effetto: .miglioraReparto(miglioramento: "addestramento_mirato"),
                                           pronto: .primavera, bersaglio: BersaglioMilitare(unita: "lupo", elemento: 1))
        XCTAssertEqual(traduttore.lavoroElencato(addestramento, forze: forze),
                       "Addestramento mirato per 8 atomi di fanteria pesante di Lupo, pronto in primavera")
        XCTAssertEqual(traduttore.spesaAnnullata(addestramento).testo,
                       "Addestramento mirato: ordine annullato, risorse restituite.")
        XCTAssertEqual(traduttore.spesaAnnullata(lavoro).testo,
                       "Leva di cavalleria manovrata: ordine annullato, risorse restituite.")
        XCTAssertEqual(testi.frase("regno.lavoro_ordinato.maschile_plurale", "Addestramenti", "estate").testo,
                       "Addestramenti ordinati: pronti in estate.")
    }

    // MARK: - Registro della patria (01 §5.17, 02 §6.6)

    func test_02_6_6_ogni_fatto_della_patria_ha_la_propria_frase_con_l_anno_e_la_stagione() {
        for fatto in FattoDiPatria.casiDiRiferimento {
            let frase = traduttore.voceDiRegistro(VoceRegistroPatria(numero: 0, anno: 3, stagione: .autunno, fatto: fatto),
                                                  fase: .arcaica).testo
            risolta(frase, "\(fatto)")
            XCTAssertTrue(frase.hasPrefix("Anno 3, autunno: "), "la voce dichiara l'anno e la stagione: «\(frase)»")
        }
        XCTAssertEqual(traduttore.voceDiRegistro(VoceRegistroPatria(
            numero: 0, anno: 1, stagione: .estate,
            fatto: .campagnaConclusa(fronte: "istmo", modo: .annientamento, vincitore: .giocatore)),
            fase: .arcaica).testo,
            "Anno 1, estate: campagna sul fronte dell'istmo vinta")
        // Il «lavoro pronto» della prima tappa non è più un fatto del registro (incarico 31): al suo
        // posto la patria annota ciò che il lavoro ha dato — qui le reclute di una leva, con dove e
        // quando entrano. Gli altri fatti nuovi sono in `TraduttoreRegnoSecondaTappaTest`.
        XCTAssertEqual(traduttore.voceDiRegistro(VoceRegistroPatria(
            numero: 1, anno: 2, stagione: .primavera,
            fatto: .recluteEntrate(Esemplari.ingresso(.primavera, confluite: false))), fase: .arcaica).testo,
            "Anno 2, primavera: Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, "
            + "ed entra sul fronte in primavera, al quartier generale")
    }

    // MARK: - La dichiarazione di conclusione (05 §9.3)

    func test_05_9_3_la_dichiarazione_di_conclusione_dice_esito_durata_battaglie_rientro_e_premi() throws {
        let forze = try forzeIniziali()
        let vinta = EsitoCampagna(fronte: "guado", anno: 1, modo: .annientamento, vincitore: .giocatore,
                                  giornate: 12, battaglieVinte: 1, battagliePerse: 0, superstiti: forze)
        XCTAssertEqual(traduttore.dichiarazioneDiConclusione(vinta, premi: motore.premi(per: vinta), fase: .arcaica), [
            "Vittoria: l'avversario non ha più gruppi armati sul fronte del guado",
            "Durata: 12 giornate",
            "Battaglie vinte: 1. Battaglie perse: 0",
            "Rientrano in patria: 5 formazioni",
            "Premi che si aggiungono alla rendita dell'anno: monete di bronzo 120, uomini 14, metalli 18, "
                + "materiale da costruzione 18, animali 7",
        ])
        let interrotta = EsitoCampagna(fronte: "pianura_lunga", anno: 1, modo: .inverno, vincitore: nil,
                                       giornate: 90, battaglieVinte: 0, battagliePerse: 0,
                                       superstiti: .sciami(formazioni: [forze.formazioni[0]], prossimoNome: 0))
        XCTAssertEqual(traduttore.dichiarazioneDiConclusione(interrotta, premi: motore.premi(per: interrotta),
                                                             fase: .arcaica), [
            "L'inverno ha interrotto la campagna sul fronte della pianura lunga: nessun vincitore",
            "Durata: 90 giornate",
            "Battaglie vinte: 0. Battaglie perse: 0",
            "Rientrano in patria: 1 formazione",
            "Nessun premio: quest'inverno arriva la sola rendita",
        ])
        let perduta = EsitoCampagna(fronte: "istmo", anno: 1, modo: .annientamento, vincitore: .avversario,
                                    giornate: 1, battaglieVinte: 0, battagliePerse: 1,
                                    superstiti: .sciami(formazioni: [], prossimoNome: 0))
        let voci = traduttore.dichiarazioneDiConclusione(perduta, premi: motore.premi(per: perduta), fase: .arcaica)
        XCTAssertEqual(voci[0], "Sconfitta: non hai più gruppi armati sul fronte dell'istmo")
        XCTAssertEqual(voci[1], "Durata: 1 giornata")
        XCTAssertEqual(voci[3], "Nessuna formazione rientra in patria")
    }

    // MARK: - La campagna del regno

    func test_gli_annunci_della_stagione_e_della_conclusione_della_campagna() {
        let campagna = TraduttoreEventiCampagna(testi: testi, parte: .giocatore)
        XCTAssertEqual(campagna.annuncio(per: .stagioneCambiata(stagione: .estate), verbosita: .normale)?.testo,
                       "Nuova stagione: estate")
        XCTAssertEqual(campagna.annuncio(per: .campagnaConclusa(modo: .inverno, vincitore: nil), verbosita: .normale)?.testo,
                       "È arrivato l'inverno: la campagna è conclusa, senza vincitore")
        XCTAssertEqual(campagna.annuncio(per: .campagnaConclusa(modo: .annientamento, vincitore: .giocatore),
                                         verbosita: .normale)?.testo,
                       "Campagna conclusa: l'avversario non ha più gruppi armati. Hai vinto")
        XCTAssertEqual(campagna.annuncio(per: .campagnaConclusa(modo: .annientamento, vincitore: .avversario),
                                         verbosita: .normale)?.testo,
                       "Campagna conclusa: non hai più gruppi armati. Hai perso")
        XCTAssertEqual(campagna.voceDiRegistro(VoceRegistro(numero: 0, giorno: 31,
                                                           fatto: .stagioneCambiata(stagione: .estate))).testo,
                       "Giorno 31: nuova stagione, estate")
        // La data nell'informazione di stato: l'anno, la stagione, e quanto manca all'inverno.
        XCTAssertEqual(testi.frase("campagna.stato_data", 1, "primavera", 78).testo,
                       "Anno 1, primavera, mancano 78 giornate all'inverno. ")
        XCTAssertEqual(testi.frase("campagna.stato_data", 1, "autunno", 1).testo,
                       "Anno 1, autunno, manca 1 giornata all'inverno. ")
        XCTAssertEqual(testi.frase("campagna.stato_data", 1, "autunno", 0).testo,
                       "Anno 1, autunno, ultima giornata prima dell'inverno. ")
    }
}
