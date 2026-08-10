import XCTest
import Motore
import Dati
import Contenuti

/// Collaudo della ricognizione, del sabotaggio, dello studio approfondito e delle
/// imboscate (incarico 19, 01 §5.4, §5.10.2, §5.11). Ogni prova cita la regola che
/// verifica. Le meccaniche sono DETERMINISTICHE (01 §12): nessuna estrazione.
final class RicognizioneImboscateTest: XCTestCase {
    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    var motore: MotoreCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
    }

    /// Costruisce uno stato su «pianura_lunga» con i gruppi indicati, per il controllo
    /// preciso di posizioni e categorie, dalla fabbrica pubblica. Il giocatore ha il quartier
    /// generale in riga 10, l'avversario in riga 1. I gruppi del giocatore ricevono gli id più
    /// bassi (fabbrica), quelli avversari i successivi.
    private func stato(_ gruppi: [(parte: Parte, categoria: CategoriaFormazione, cella: Cella)]) throws -> StatoCampagna {
        func iniziale(_ categoria: CategoriaFormazione, _ cella: Cella) -> ScenarioCampagna.GruppoIniziale {
            let comp = [ScenarioCampagna.RepartoIniziale(archetipo: "fanteria_leggera", atomi: 4)]
            switch categoria {
            case .armato:
                return .init(riga: cella.riga, colonna: cella.colonna, composizione: comp)
            case .ricognizione(let competenza):
                return .init(riga: cella.riga, colonna: cella.colonna, composizione: comp,
                             categoria: "ricognizione", competenza: competenza)
            case .nonArmata(let carico, let soglia):
                return .init(riga: cella.riga, colonna: cella.colonna, composizione: comp,
                             categoria: "non_armata", carico: carico, sogliaProtezione: soglia)
            }
        }
        let scenario = ScenarioCampagna(
            mappa: "pianura_lunga",
            gruppiGiocatore: gruppi.filter { $0.parte == .giocatore }.map { iniziale($0.categoria, $0.cella) },
            gruppiAvversario: gruppi.filter { $0.parte == .avversario }.map { iniziale($0.categoria, $0.cella) })
        return try FabbricaCampagna.crea(scenario: scenario, valori: valoriCampagna,
                                         archetipiNoti: Set(valori.archetipi.keys))
    }

    // MARK: - 01 §5.4 — il rischio deterministico della ricognizione

    /// Un esploratore competente vicino alla propria base (bassa insidiosità) ESPLORA con
    /// successo: le caselle attorno diventano conoscenza fresca (confermata) del giocatore.
    func test_01_5_4_esplorazione_riuscita_rivela_la_zona() throws {
        // Un secondo gruppo tiene la giornata aperta, così l'azione spesa resta leggibile
        // (senza, l'unico gruppo chiuderebbe la giornata e l'azzeramento la riporterebbe a falso).
        let s = try stato([(.giocatore, .ricognizione(competenza: 20), Cella(riga: 9, colonna: 5)),
                           (.giocatore, .armato, Cella(riga: 10, colonna: 6))])
        let id = s.gruppi(di: .giocatore).first { $0.categoria.eRicognizione }!.id
        XCTAssertEqual(motore.esitoEsplorazione(di: s.gruppi[id]!, stato: s), .riuscita)
        // Prima di esplorare, una casella a distanza tre è oltre il raggio ordinario di osservazione
        // (due, incarico 22): inesplorata. L'esplorazione vede più lontano (raggio di esplorazione tre).
        XCTAssertNotEqual(motore.conoscenza(di: Cella(riga: 6, colonna: 5), per: .giocatore, stato: s), .confermato)
        let (dopo, eventi) = motore.applica(.esplorazione(gruppo: id), parte: .giocatore, stato: s)
        // Quella stessa casella, a distanza tre dall'esploratore, è ora confermata: l'esplorazione
        // rivela oltre il raggio ordinario. È il senso della ricognizione (01 §5.4).
        XCTAssertEqual(motore.conoscenza(di: Cella(riga: 6, colonna: 5), per: .giocatore, stato: dopo), .confermato)
        XCTAssertTrue(eventi.contains { if case .esplorazioneCompiuta(_, _, _, _, .riuscita) = $0 { return true } else { return false } })
        XCTAssertTrue(dopo.gruppi[id]!.azioneSpesa, "l'esplorazione consuma la giornata (01 §5.6.0.5)")
    }

    /// Un esploratore incapace nel profondo del campo avversario si PERDE: la formazione
    /// sparisce dalla mappa (01 §5.4.2, personale formato) e il fatto entra nel registro.
    func test_01_5_4_esploratori_perduti_spariscono_dalla_mappa() throws {
        let s = try stato([(.giocatore, .ricognizione(competenza: 0), Cella(riga: 2, colonna: 5)),
                           (.avversario, .armato, Cella(riga: 2, colonna: 4))])
        let id = s.gruppiOrdinati[0].id
        XCTAssertEqual(motore.esitoEsplorazione(di: s.gruppi[id]!, stato: s), .perduti)
        let (dopo, eventi) = motore.applica(.esplorazione(gruppo: id), parte: .giocatore, stato: s)
        XCTAssertNil(dopo.gruppi[id], "l'esploratore perduto è rimosso")
        XCTAssertTrue(dopo.registro.contains { if case .esploratoriPerduti = $0.fatto { return true } else { return false } })
        XCTAssertTrue(eventi.contains { if case .esplorazioneCompiuta(_, _, _, _, .perduti) = $0 { return true } else { return false } })
    }

    /// Un esploratore che si fa NOTARE rende la propria casella avvistata per l'avversario
    /// (01 §5.4): l'avversario acquista conoscenza di quella casella.
    func test_01_5_4_esploratori_notati_avvistati_per_l_avversario() throws {
        let r = valoriCampagna.ricognizione
        let cella = Cella(riga: 5, colonna: 5)
        // Senza nemici vicini l'insidiosità è base più profondità: si sceglie la competenza
        // perché il margine cada nella fascia dei NOTATI (fra a mani vuote e perduti).
        let sondaggio = try stato([(.giocatore, .ricognizione(competenza: 0), cella)])
        let prof = sondaggio.griglia.distanza(cella, sondaggio.mappa.quartierGenerale(di: .giocatore))
        let insidiosita = r.insidiositaBase + r.pesoProfondita * prof
        let competenza = insidiosita - (r.sogliaManiVuote + 1)  // margine = -(sogliaManiVuote+1) -> notati
        let s = try stato([(.giocatore, .ricognizione(competenza: competenza), cella)])
        let id = s.gruppiOrdinati[0].id
        XCTAssertEqual(motore.esitoEsplorazione(di: s.gruppi[id]!, stato: s), .notati)
        let (dopo, _) = motore.applica(.esplorazione(gruppo: id), parte: .giocatore, stato: s)
        XCTAssertEqual(motore.conoscenza(di: cella, per: .avversario, stato: dopo), .confermato,
                       "la casella dell'esploratore notato è osservata per l'avversario")
        XCTAssertTrue(dopo.registro.contains { if case .esploratoriNotati = $0.fatto { return true } else { return false } })
    }

    // MARK: - 01 §5.10.2 — sabotaggio e studio approfondito

    /// Il sabotaggio compiuto da un gruppo ARMATO riesce sempre e disperde la formazione
    /// bersaglio, il cui carico è perduto (01 §5.10.2).
    func test_01_5_10_2_sabotaggio_armato_disperde_il_bersaglio() throws {
        let s = try stato([(.giocatore, .armato, Cella(riga: 5, colonna: 5)),
                           (.avversario, .nonArmata(carico: 9, sogliaProtezione: 3), Cella(riga: 5, colonna: 5))])
        let armato = s.gruppi(di: .giocatore)[0].id
        let bersaglio = s.gruppi(di: .avversario)[0].id
        let (dopo, eventi) = motore.applica(.sabotaggio(gruppo: armato), parte: .giocatore, stato: s)
        XCTAssertNil(dopo.gruppi[bersaglio], "la formazione sabotata sparisce col suo carico")
        XCTAssertTrue(eventi.contains { if case .sabotaggioCompiuto(_, _, _, true) = $0 { return true } else { return false } })
        XCTAssertTrue(dopo.registro.contains { if case .formazioneSabotata = $0.fatto { return true } else { return false } })
    }

    /// Il sabotaggio compiuto da esploratori riesce solo se la loro competenza raggiunge la
    /// soglia di protezione; altrimenti FALLISCE e gli esploratori si fanno notare (01 §5.10.2).
    func test_01_5_10_2_sabotaggio_esploratore_sotto_soglia_fallisce_e_li_fa_notare() throws {
        let s = try stato([(.giocatore, .ricognizione(competenza: 2), Cella(riga: 5, colonna: 5)),
                           (.avversario, .nonArmata(carico: 4, sogliaProtezione: 9), Cella(riga: 5, colonna: 5))])
        let esploratore = s.gruppi(di: .giocatore)[0].id
        let bersaglio = s.gruppi(di: .avversario)[0].id
        let (dopo, eventi) = motore.applica(.sabotaggio(gruppo: esploratore), parte: .giocatore, stato: s)
        XCTAssertNotNil(dopo.gruppi[bersaglio], "sotto soglia il bersaglio resta")
        XCTAssertTrue(eventi.contains { if case .sabotaggioCompiuto(_, _, _, false) = $0 { return true } else { return false } })
        XCTAssertTrue(dopo.registro.contains { if case .esploratoriNotati = $0.fatto { return true } else { return false } })
        XCTAssertEqual(motore.conoscenza(di: Cella(riga: 5, colonna: 5), per: .avversario, stato: dopo), .confermato)
    }

    /// Lo studio approfondito porta a CONFERMATO la conoscenza della formazione studiata e la
    /// registra fra le studiate (01 §5.10.2), senza disperderla.
    func test_01_5_10_2_studio_porta_a_confermato_e_registra_la_studiata() throws {
        let s = try stato([(.giocatore, .ricognizione(competenza: 5), Cella(riga: 5, colonna: 5)),
                           (.avversario, .nonArmata(carico: 4, sogliaProtezione: 2), Cella(riga: 5, colonna: 5))])
        let esploratore = s.gruppi(di: .giocatore)[0].id
        let bersaglio = s.gruppi(di: .avversario)[0].id
        let (dopo, eventi) = motore.applica(.studioApprofondito(gruppo: esploratore), parte: .giocatore, stato: s)
        XCTAssertNotNil(dopo.gruppi[bersaglio], "lo studio non disperde")
        XCTAssertTrue(dopo.studiati[.giocatore]?.contains(bersaglio) == true, "la formazione è ora studiata")
        XCTAssertTrue(eventi.contains { if case .studioCompiuto = $0 { return true } else { return false } })
        XCTAssertTrue(dopo.registro.contains { if case .formazioneStudiata = $0.fatto { return true } else { return false } })
    }

    // MARK: - 01 §5.11 — le imboscate

    /// L'imboscata scatta soltanto all'INGRESSO di un gruppo armato avversario nella casella
    /// appostata (01 §5.11), alla risoluzione di fine giornata; lo scatto si registra.
    func test_01_5_11_imboscata_scatta_su_ingresso_di_un_armato() throws {
        var s = try stato([(.giocatore, .armato, Cella(riga: 5, colonna: 5)),
                           (.avversario, .armato, Cella(riga: 4, colonna: 5))])
        let imboscante = s.gruppi(di: .giocatore)[0].id
        // Appostato oggi: l'imboscata è un'azione che CONSUMA la giornata (incarico 21), sicché
        // l'imboscante ha `azioneSpesa` come dopo il comando `.imboscata`, ed è concluso.
        s.gruppi[imboscante]!.ordineImboscata = true
        s.gruppi[imboscante]!.azioneSpesa = true
        let intruso = s.gruppi(di: .avversario)[0].id
        // L'avversario entra nella casella appostata: la sua marcia chiude la giornata
        // (l'imboscante ha già concluso), la risoluzione avanza la marcia e fa scattare.
        let costo = motore.costoInGiorni(da: Cella(riga: 4, colonna: 5), a: Cella(riga: 5, colonna: 5),
                                         parte: .avversario, stato: s)
        let (dopo, eventi) = motore.applica(.marcia(gruppo: intruso, a: Cella(riga: 5, colonna: 5), giorni: costo),
                                            parte: .avversario, stato: s)
        XCTAssertFalse(dopo.imboscateInSospeso.isEmpty, "l'imboscata è scattata")
        XCTAssertEqual(dopo.imboscateInSospeso.first?.imboscante, .giocatore)
        XCTAssertFalse(dopo.gruppi[imboscante]!.ordineImboscata, "l'agguato scattato si spegne")
        XCTAssertTrue(eventi.contains { if case .imboscataScattata = $0 { return true } else { return false } })
        XCTAssertTrue(dopo.registro.contains { if case .imboscataScattata = $0.fatto { return true } else { return false } })
    }

    /// Gli ESPLORATORI non inneschiano mai una battaglia (01 §5.4.1): un esploratore che entra
    /// nella casella appostata NON fa scattare l'imboscata.
    func test_01_5_4_1_un_esploratore_non_fa_scattare_l_imboscata() throws {
        var s = try stato([(.giocatore, .armato, Cella(riga: 5, colonna: 5)),
                           (.avversario, .ricognizione(competenza: 5), Cella(riga: 4, colonna: 5))])
        let imboscante = s.gruppi(di: .giocatore)[0].id
        s.gruppi[imboscante]!.ordineImboscata = true
        s.gruppi[imboscante]!.azioneSpesa = true   // appostato consuma la giornata (incarico 21)
        let esploratore = s.gruppi(di: .avversario)[0].id
        let costo = motore.costoInGiorni(da: Cella(riga: 4, colonna: 5), a: Cella(riga: 5, colonna: 5),
                                         parte: .avversario, stato: s)
        let (dopo, eventi) = motore.applica(.marcia(gruppo: esploratore, a: Cella(riga: 5, colonna: 5), giorni: costo),
                                            parte: .avversario, stato: s)
        XCTAssertTrue(dopo.imboscateInSospeso.isEmpty, "un esploratore non innesca battaglia (01 §5.4.1)")
        XCTAssertFalse(eventi.contains { if case .imboscataScattata = $0 { return true } else { return false } })
    }

    /// L'avversario può a sua volta tendere imboscate e il GIOCATORE vi può cadere (01 §5.11,
    /// incarico 19): un gruppo armato del giocatore che entra nella casella appostata
    /// dall'avversario fa scattare l'imboscata, col vantaggio all'avversario.
    func test_01_5_11_il_giocatore_cade_nell_imboscata_avversaria() throws {
        var s = try stato([(.avversario, .armato, Cella(riga: 5, colonna: 5)),
                           (.giocatore, .armato, Cella(riga: 6, colonna: 5))])
        let imboscante = s.gruppi(di: .avversario)[0].id
        s.gruppi[imboscante]!.ordineImboscata = true
        s.gruppi[imboscante]!.azioneSpesa = true   // appostato consuma la giornata (incarico 21)
        let intruso = s.gruppi(di: .giocatore)[0].id
        let costo = motore.costoInGiorni(da: Cella(riga: 6, colonna: 5), a: Cella(riga: 5, colonna: 5),
                                         parte: .giocatore, stato: s)
        let (dopo, _) = motore.applica(.marcia(gruppo: intruso, a: Cella(riga: 5, colonna: 5), giorni: costo),
                                       parte: .giocatore, stato: s)
        XCTAssertFalse(dopo.imboscateInSospeso.isEmpty, "il giocatore è caduto nell'imboscata avversaria")
        XCTAssertEqual(dopo.imboscateInSospeso.first?.imboscante, .avversario, "il vantaggio è dell'avversario")
    }

    // MARK: - 01 §5.11, §5.11.1 — l'imboscata come ordine che si rinnova e l'occultamento (incarico 21)

    /// L'imboscata è un'AZIONE che consuma la giornata e si RINNOVA (decisione 1, incarico 21): il
    /// comando pone `azioneSpesa` e `ordineImboscata`; un gruppo appostato conclude la giornata.
    func test_01_5_11_l_imboscata_consuma_l_azione_e_conclude_la_giornata() throws {
        // Due gruppi, così che ordinare l'imboscata al primo NON chiuda la giornata (il secondo
        // resta in attesa) e si osservi lo stato appostato prima dell'azzeramento di fine giornata.
        let s = try stato([(.giocatore, .armato, Cella(riga: 5, colonna: 5)),
                           (.giocatore, .armato, Cella(riga: 8, colonna: 6))])
        let g = s.gruppi(di: .giocatore)[0].id
        XCTAssertTrue(motore.valida(.imboscata(gruppo: g), parte: .giocatore, stato: s).eValido)
        let (dopo, _) = motore.applica(.imboscata(gruppo: g), parte: .giocatore, stato: s)
        XCTAssertTrue(dopo.gruppi[g]!.ordineImboscata, "il gruppo è appostato")
        XCTAssertTrue(dopo.gruppi[g]!.azioneSpesa, "l'imboscata consuma l'azione (decisione 1)")
        XCTAssertTrue(dopo.gruppi[g]!.haConclusoLaGiornata, "l'appostato ha concluso la giornata")
        XCTAssertEqual(dopo.gruppi[g]!.statoDichiarato, .inAgguato, "si annuncia «in agguato»")
    }

    /// L'OCCULTAMENTO (decisione 2, 01 §5.11.1): la casella di un gruppo appostato NON è confermata
    /// per l'avversario che le è adiacente — la sua conoscenza retrocede al ricordo — e il gioco non
    /// dichiara il falso: mai «confermato», mai un occupante mostrato. La conoscenza propria resta.
    func test_01_5_11_1_l_occultamento_retrocede_la_conoscenza_senza_dichiarare_il_falso() throws {
        var s = try stato([(.giocatore, .armato, Cella(riga: 6, colonna: 5)),
                           (.avversario, .armato, Cella(riga: 5, colonna: 5))])
        let cella = Cella(riga: 5, colonna: 5)
        // Adiacente, senza agguato: il giocatore CONFERMA la casella e vi vede l'avversario.
        XCTAssertEqual(motore.conoscenza(di: cella, per: .giocatore, stato: s), .confermato)
        let vistaPrima = VistaCampagna(motore: motore, stato: s, parte: .giocatore)
        XCTAssertTrue(vistaPrima.vociDiCasella(cella).contains { if case .occupanteAvversario = $0 { return true }; return false })
        // L'avversario si apposta: la conoscenza del giocatore RETROCEDE da confermato.
        s.gruppi[s.gruppi(di: .avversario)[0].id]!.ordineImboscata = true
        s.gruppi[s.gruppi(di: .avversario)[0].id]!.azioneSpesa = true
        XCTAssertNotEqual(motore.conoscenza(di: cella, per: .giocatore, stato: s), .confermato,
                          "occultato: la casella non è più confermata")
        let vistaDopo = VistaCampagna(motore: motore, stato: s, parte: .giocatore)
        XCTAssertFalse(vistaDopo.vociDiCasella(cella).contains { if case .occupanteAvversario = $0 { return true }; return false },
                       "l'appostato non si mostra, e nulla dichiara il vuoto")
        // La conoscenza PROPRIA non è toccata: il proprio gruppo resta visibile a sé.
        XCTAssertNotNil(s.occupante(di: Cella(riga: 6, colonna: 5), parte: .giocatore))
    }

    /// La SCOPERTA (decisione 2, 01 §5.11.1): un'esplorazione riuscita che rivela l'area scopre
    /// l'imboscata avversaria — la casella torna confermata, il fatto entra nel registro col luogo.
    /// È il SOLO modo di scoprirla, senza estrazione (la riuscita discende dalla competenza).
    func test_01_5_11_1_la_ricognizione_scopre_l_imboscata_avversaria() throws {
        // Un secondo gruppo del giocatore (lontano, non concluso) tiene aperta la giornata, così che
        // la scoperta non si azzeri con la chiusura prima di osservarla.
        var s = try stato([(.giocatore, .ricognizione(competenza: 12), Cella(riga: 7, colonna: 7)),
                           (.giocatore, .armato, Cella(riga: 10, colonna: 6)),
                           (.avversario, .armato, Cella(riga: 7, colonna: 5))])
        let esploratore = s.gruppi(di: .giocatore).first { $0.categoria.eRicognizione }!.id
        let cella = Cella(riga: 7, colonna: 5)
        s.gruppi[s.gruppi(di: .avversario)[0].id]!.ordineImboscata = true
        s.gruppi[s.gruppi(di: .avversario)[0].id]!.azioneSpesa = true
        // Occulta prima della scoperta.
        XCTAssertNotEqual(motore.conoscenza(di: cella, per: .giocatore, stato: s), .confermato)
        let (dopo, eventi) = motore.applica(.esplorazione(gruppo: esploratore), parte: .giocatore, stato: s)
        XCTAssertTrue(dopo.imboscateScoperte[.giocatore]?.contains(cella) == true, "l'imboscata è scoperta")
        XCTAssertEqual(motore.conoscenza(di: cella, per: .giocatore, stato: dopo), .confermato,
                       "scoperta: la casella torna confermata e vi si vede l'appostato")
        XCTAssertTrue(eventi.contains { if case .imboscataScoperta(.giocatore, cella) = $0 { return true }; return false })
        XCTAssertTrue(dopo.registro.contains { if case .imboscataScoperta = $0.fatto { return true }; return false },
                      "il fatto entra nel registro col luogo, attivabile")
    }

    /// La SIMMETRIA (incarico 21): un'imboscata del GIOCATORE è occulta per l'avversario, che vi può
    /// cadere; scoperta dai suoi esploratori, entra fra le sue formazioni note e la aggira. La vista
    /// dell'avversario esclude l'appostato occulto e include lo scoperto.
    func test_01_5_11_la_simmetria_l_avversario_non_vede_l_occulta_ma_vede_la_scoperta() throws {
        var s = try stato([(.giocatore, .armato, Cella(riga: 5, colonna: 5)),
                           (.avversario, .armato, Cella(riga: 5, colonna: 4))])
        let appostato = s.gruppi(di: .giocatore)[0].id
        let cella = Cella(riga: 5, colonna: 5)
        s.gruppi[appostato]!.ordineImboscata = true
        s.gruppi[appostato]!.azioneSpesa = true
        // Occulta: l'avversario, adiacente, NON la nota (vi può entrare e cadervi).
        XCTAssertFalse(motore.vistaAvversario(stato: s).formazioniGiocatoreNote.contains(cella),
                       "l'appostato del giocatore è occulto per l'avversario")
        // Scoperta dagli esploratori dell'avversario: torna nota e l'avversario la aggira.
        s.imboscateScoperte[.avversario] = [cella]
        XCTAssertTrue(motore.vistaAvversario(stato: s).formazioniGiocatoreNote.contains(cella),
                      "scoperta, la casella entra fra le note dell'avversario")
    }

    // MARK: - 01 §5.13 — l'aggiramento simmetrico

    /// Due formazioni possono sfilarsi in caselle adiacenti senza ingaggiarsi, e una colonna
    /// può oltrepassare le forze avversarie (01 §5.13): nessuna regola impedisce al giocatore
    /// di marciare accanto a un gruppo avversario né di superarlo. La compresenza è ammessa.
    func test_01_5_13_aggiramento_il_giocatore_supera_l_avversario_senza_ingaggiare() throws {
        let s = try stato([(.giocatore, .armato, Cella(riga: 6, colonna: 5)),
                           (.avversario, .armato, Cella(riga: 5, colonna: 6))])
        let g = s.gruppi(di: .giocatore)[0].id
        // Marcia accanto all'avversario (in una casella adiacente a esso): ammessa.
        let costoAccanto = motore.costoInGiorni(da: Cella(riga: 6, colonna: 5), a: Cella(riga: 5, colonna: 5),
                                                parte: .giocatore, stato: s)
        XCTAssertTrue(motore.valida(.marcia(gruppo: g, a: Cella(riga: 5, colonna: 5), giorni: costoAccanto),
                                    parte: .giocatore, stato: s).eValido,
                      "sfilarsi in una casella adiacente all'avversario non è impedito (01 §5.13)")
        // Marcia NELLA casella dell'avversario (compresenza, 01 §6.1): ammessa, nessuna battaglia.
        let costoSopra = motore.costoInGiorni(da: Cella(riga: 6, colonna: 5), a: Cella(riga: 5, colonna: 6),
                                              parte: .giocatore, stato: s)
        // Non adiacente in un solo scatto: si prova la compresenza da una casella adiacente.
        var s2 = s
        s2.gruppi[g]!.posizione = Cella(riga: 5, colonna: 5)
        let costo2 = motore.costoInGiorni(da: Cella(riga: 5, colonna: 5), a: Cella(riga: 5, colonna: 6),
                                          parte: .giocatore, stato: s2)
        XCTAssertTrue(motore.valida(.marcia(gruppo: g, a: Cella(riga: 5, colonna: 6), giorni: costo2),
                                    parte: .giocatore, stato: s2).eValido,
                      "oltrepassare entrando nella casella avversaria è ammesso (compresenza, 01 §6.1, §5.13)")
        _ = costoSopra
    }
}
