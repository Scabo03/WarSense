import XCTest
import Verifica
import Motore
import Dati
import Contenuti

/// Gli invarianti di SESSIONE (05 §12.4): quelli che soltanto una sessione intera
/// può violare, perché riguardano l'accumularsi dello stato e non il singolo passo.
///
/// La disciplina è quella degli invarianti di passo e non si indebolisce: ciascuno
/// ha il proprio mutante, e una prova pretende che nessuno ne resti privo. Un
/// invariante che non si è mai visto violare non è un invariante.
final class SessioniCompleteTest: XCTestCase {

    func programma(fumo: Bool = true) -> ProgrammaDiVerifica {
        ProgrammaDiVerifica(cartellaValori: Contenuti.valoriDiFabbrica,
                            cartellaScenari: Contenuti.scenariDiVerifica,
                            cartellaScenariCampagna: Verifica.Ambiente.scenariCampagnaDiFabbrica,
                            fumo: fumo)
    }

    // MARK: - La storia sana, da cui i mutanti si ricavano guastandola

    private func storiaSana() -> SondaSessioneCampagna.Storia {
        // Il registro annota i soli fatti non decisi dal giocatore (01 §5.17.1), e dall'
        // incarico 19 l'ARRIVO di un proprio gruppo ne è USCITO: una storia di soli ordini e
        // compimenti, senza revoche né avvistamenti, ha il registro VUOTO — due marce compiute
        // non vi lasciano più alcuna voce.
        SondaSessioneCampagna.Storia(
            giorniLetti: [1, 1, 2, 2, 3], gruppiIniziali: [1, 2], gruppiFinali: [1, 2],
            vociDiRegistro: 0, ordiniImpartiti: 4, compimentiDiMarcia: 2,
            improntaFinale: "abc", improntaRigiocata: "abc")
    }

    private func codici(_ violazioni: [SondaSessioneCampagna.Violazione]) -> [String] {
        violazioni.map { SondaSessioneCampagna.codice(di: $0) }
    }

    func test_05_12_4_la_storia_sana_non_produce_alcuna_violazione() {
        XCTAssertEqual(SondaSessioneCampagna().controlla(storiaSana()).count, 0,
                       "la sonda vede violazioni dove non ce ne sono: i mutanti non direbbero nulla")
    }

    // MARK: - I mutanti della campagna

    /// Un salto IN AVANTI del calendario è legittimo: con la marcia lunga, se tutti
    /// i gruppi sono in marcia le giornate scorrono a cascata in una sola
    /// applicazione (01 §5.6.11). L'invariante non lo segnala.
    func test_01_5_6_11_un_calendario_che_salta_in_avanti_e_legittimo() {
        let s = storiaSana()
        let cascata = SondaSessioneCampagna.Storia(
            giorniLetti: [1, 2, 5], gruppiIniziali: s.gruppiIniziali, gruppiFinali: s.gruppiFinali,
            vociDiRegistro: s.vociDiRegistro, ordiniImpartiti: s.ordiniImpartiti,
            improntaFinale: s.improntaFinale, improntaRigiocata: s.improntaRigiocata)
        XCTAssertFalse(codici(SondaSessioneCampagna().controlla(cascata))
            .contains("calendario_non_monotono"),
            "il salto in avanti della cascata non è una violazione")
    }

    /// Dall'incarico 19 l'ARRIVO di un proprio gruppo NON entra più nel registro (correzione
    /// del titolare): una storia di soli ordini e compimenti, senza revoche né avvistamenti,
    /// ha il registro VUOTO, e la sonda non vi trova divergenza quali che siano i compimenti.
    func test_01_5_17_1_il_registro_senza_arrivi_e_sano() {
        let s = storiaSana()
        let conCompimenti = SondaSessioneCampagna.Storia(
            giorniLetti: s.giorniLetti, gruppiIniziali: s.gruppiIniziali, gruppiFinali: s.gruppiFinali,
            vociDiRegistro: 0, ordiniImpartiti: 5, compimentiDiMarcia: 3,
            improntaFinale: s.improntaFinale, improntaRigiocata: s.improntaRigiocata)
        XCTAssertFalse(codici(SondaSessioneCampagna().controlla(conCompimenti))
            .contains("registro_non_corrisponde"),
            "il registro vuoto (l'arrivo non vi entra più) è sano, quali che siano i compimenti")
    }

    func test_mutante_un_calendario_che_torna_indietro_viene_visto() {
        let s = storiaSana()
        let mutante = SondaSessioneCampagna.Storia(
            giorniLetti: [1, 2, 1], gruppiIniziali: s.gruppiIniziali, gruppiFinali: s.gruppiFinali,
            vociDiRegistro: s.vociDiRegistro, ordiniImpartiti: s.ordiniImpartiti,
            improntaFinale: s.improntaFinale, improntaRigiocata: s.improntaRigiocata)
        XCTAssertTrue(codici(SondaSessioneCampagna().controlla(mutante))
            .contains("calendario_non_monotono"))
    }

    func test_mutante_un_gruppo_che_sparisce_viene_visto() {
        let s = storiaSana()
        let mutante = SondaSessioneCampagna.Storia(
            giorniLetti: s.giorniLetti, gruppiIniziali: [1, 2], gruppiFinali: [1],
            vociDiRegistro: s.vociDiRegistro, ordiniImpartiti: s.ordiniImpartiti,
            improntaFinale: s.improntaFinale, improntaRigiocata: s.improntaRigiocata)
        XCTAssertTrue(codici(SondaSessioneCampagna().controlla(mutante))
            .contains("gruppi_non_conservati"))
    }

    func test_mutante_un_registro_con_una_voce_di_troppo_viene_visto() {
        let s = storiaSana()
        // Il registro dovrebbe essere vuoto (l'arrivo non vi entra più, incarico 19), ma porta
        // una voce: un fatto vi è comparso senza sorgente legittima in questa condotta.
        let mutante = SondaSessioneCampagna.Storia(
            giorniLetti: s.giorniLetti, gruppiIniziali: s.gruppiIniziali,
            gruppiFinali: s.gruppiFinali, vociDiRegistro: 1, ordiniImpartiti: 4,
            compimentiDiMarcia: 2,
            improntaFinale: s.improntaFinale, improntaRigiocata: s.improntaRigiocata)
        XCTAssertTrue(codici(SondaSessioneCampagna().controlla(mutante))
            .contains("registro_non_corrisponde"))
    }

    func test_mutante_una_rigiocatura_divergente_viene_vista() {
        let s = storiaSana()
        let mutante = SondaSessioneCampagna.Storia(
            giorniLetti: s.giorniLetti, gruppiIniziali: s.gruppiIniziali,
            gruppiFinali: s.gruppiFinali, vociDiRegistro: s.vociDiRegistro,
            ordiniImpartiti: s.ordiniImpartiti,
            improntaFinale: "abc", improntaRigiocata: "xyz")
        XCTAssertTrue(codici(SondaSessioneCampagna().controlla(mutante))
            .contains("rigiocatura_divergente"))
    }

    // MARK: - I mutanti della battaglia

    private func storiaBattagliaSana() -> SondaSessioneBattaglia.Storia {
        SondaSessioneBattaglia.Storia(
            giriLetti: [1, 1, 2, 3], lettereAssegnate: [.giocatore: [1, 2, 3], .avversario: [1, 2]],
            improntaFinale: "abc", improntaRigiocata: "abc")
    }

    func test_05_12_4_la_storia_di_battaglia_sana_non_produce_violazioni() {
        XCTAssertEqual(SondaSessioneBattaglia().controlla(storiaBattagliaSana()).count, 0)
    }

    func test_mutante_un_giro_che_torna_indietro_viene_visto() {
        let s = storiaBattagliaSana()
        let mutante = SondaSessioneBattaglia.Storia(
            giriLetti: [1, 2, 1], lettereAssegnate: s.lettereAssegnate,
            improntaFinale: s.improntaFinale, improntaRigiocata: s.improntaRigiocata)
        XCTAssertTrue(SondaSessioneBattaglia().controlla(mutante)
            .map { SondaSessioneBattaglia.codice(di: $0) }.contains("giro_non_monotono"))
    }

    /// 01 §9.4.3 vuole le lettere «mai riusate»: è una proprietà della STORIA, e
    /// nello stato una lettera libera e una mai usata sono indistinguibili.
    func test_01_9_4_3_mutante_una_lettera_riusata_viene_vista() {
        let s = storiaBattagliaSana()
        let mutante = SondaSessioneBattaglia.Storia(
            giriLetti: s.giriLetti, lettereAssegnate: [.giocatore: [1, 2, 2], .avversario: [1]],
            improntaFinale: s.improntaFinale, improntaRigiocata: s.improntaRigiocata)
        XCTAssertTrue(SondaSessioneBattaglia().controlla(mutante)
            .map { SondaSessioneBattaglia.codice(di: $0) }.contains("lettera_riusata"))
    }

    func test_mutante_una_rigiocatura_di_battaglia_divergente_viene_vista() {
        let s = storiaBattagliaSana()
        let mutante = SondaSessioneBattaglia.Storia(
            giriLetti: s.giriLetti, lettereAssegnate: s.lettereAssegnate,
            improntaFinale: "abc", improntaRigiocata: "xyz")
        XCTAssertTrue(SondaSessioneBattaglia().controlla(mutante)
            .map { SondaSessioneBattaglia.codice(di: $0) }
            .contains("rigiocatura_divergente_battaglia"))
    }

    // MARK: - Nessun invariante senza mutante

    /// Il presidio che impedisce alla copertura di restringersi in silenzio: se si
    /// aggiunge un invariante di sessione senza il suo mutante, questa prova lo
    /// dichiara. È la gemella di quella degli invarianti di passo, e come quella non
    /// va indebolita.
    func test_05_12_4_ogni_invariante_di_sessione_ha_almeno_un_mutante() throws {
        var coperti = Set<String>()
        // Campagna: si guasta la storia sana in ogni modo previsto e si raccoglie
        // il codice che ne esce. Un invariante nuovo senza mutante non compare.
        let sana = storiaSana()
        let guasti: [SondaSessioneCampagna.Storia] = [
            .init(giorniLetti: [1, 2, 1], gruppiIniziali: sana.gruppiIniziali,
                  gruppiFinali: sana.gruppiFinali, vociDiRegistro: sana.vociDiRegistro,
                  ordiniImpartiti: sana.ordiniImpartiti, improntaFinale: "a", improntaRigiocata: "a"),
            .init(giorniLetti: sana.giorniLetti, gruppiIniziali: [1, 2], gruppiFinali: [1],
                  vociDiRegistro: sana.vociDiRegistro, ordiniImpartiti: sana.ordiniImpartiti,
                  improntaFinale: "a", improntaRigiocata: "a"),
            .init(giorniLetti: sana.giorniLetti, gruppiIniziali: sana.gruppiIniziali,
                  gruppiFinali: sana.gruppiFinali, vociDiRegistro: 3, ordiniImpartiti: 4,
                  improntaFinale: "a", improntaRigiocata: "a"),
            .init(giorniLetti: sana.giorniLetti, gruppiIniziali: sana.gruppiIniziali,
                  gruppiFinali: sana.gruppiFinali, vociDiRegistro: sana.vociDiRegistro,
                  ordiniImpartiti: sana.ordiniImpartiti, improntaFinale: "a", improntaRigiocata: "b"),
        ]
        for guasto in guasti { coperti.formUnion(codici(SondaSessioneCampagna().controlla(guasto))) }
        XCTAssertEqual(coperti, Set(SondaSessioneCampagna.codiciNoti),
                       "invarianti di sessione di campagna senza mutante: "
                       + "\(Set(SondaSessioneCampagna.codiciNoti).subtracting(coperti))")

        var copertiB = Set<String>()
        let sanaB = storiaBattagliaSana()
        let guastiB: [SondaSessioneBattaglia.Storia] = [
            .init(giriLetti: [1, 2, 1], lettereAssegnate: sanaB.lettereAssegnate,
                  improntaFinale: "a", improntaRigiocata: "a"),
            .init(giriLetti: sanaB.giriLetti, lettereAssegnate: [.giocatore: [1, 1]],
                  improntaFinale: "a", improntaRigiocata: "a"),
            .init(giriLetti: sanaB.giriLetti, lettereAssegnate: sanaB.lettereAssegnate,
                  improntaFinale: "a", improntaRigiocata: "b"),
        ]
        for guasto in guastiB {
            copertiB.formUnion(SondaSessioneBattaglia().controlla(guasto)
                .map { SondaSessioneBattaglia.codice(di: $0) })
        }
        XCTAssertEqual(copertiB, Set(SondaSessioneBattaglia.codiciNoti),
                       "invarianti di sessione di battaglia senza mutante: "
                       + "\(Set(SondaSessioneBattaglia.codiciNoti).subtracting(copertiB))")
    }

    // MARK: - Le sessioni vere

    /// Nessuna sessione generata viola alcun invariante, né di passo né di sessione.
    func test_05_12_4_nessuna_sessione_generata_viola_alcun_invariante() throws {
        let rapporto = try programma().esegui()
        for nome in ["sessioni_campagna", "sessioni_battaglia"] {
            let sezione = try XCTUnwrap(rapporto.sezioni.first { $0.nome == nome },
                                        "sezione mancante: \(nome)")
            let colonna = try XCTUnwrap(sezione.intestazione.firstIndex(of: "violazioni"))
            let dettaglio = try XCTUnwrap(sezione.intestazione.firstIndex(of: "dettaglio"))
            XCTAssertFalse(sezione.righe.isEmpty, "\(nome): nessuna sessione giocata")
            for riga in sezione.righe {
                XCTAssertEqual(riga[colonna], "0",
                               "violazione nella sessione \(riga[0]): \(riga[dettaglio])")
            }
        }
    }

    /// Il blocco di riepilogo pareggia con le righe di dettaglio (RDA-71): i numeri
    /// del resoconto vengono da lì, e se i suoi totali non fossero quelli del
    /// dettaglio avrei spostato l'errore dalla mia testa al programma.
    func test_05_12_6_il_riepilogo_delle_sessioni_pareggia_con_il_dettaglio() throws {
        let rapporto = try programma().esegui()
        func sezione(_ nome: String) throws -> Rapporto.Sezione {
            try XCTUnwrap(rapporto.sezioni.first { $0.nome == nome }, "sezione mancante: \(nome)")
        }
        let riepilogo = try sezione("sessioni_riepilogo")
        func valore(_ voce: String) throws -> Int {
            let riga = try XCTUnwrap(riepilogo.righe.first { $0[0] == voce }, "voce mancante: \(voce)")
            return try XCTUnwrap(Int(riga[1]), "voce non numerica: \(voce)")
        }
        let campagna = try sezione("sessioni_campagna")
        let battaglia = try sezione("sessioni_battaglia")
        func somma(_ s: Rapporto.Sezione, _ colonna: String) throws -> Int {
            let indice = try XCTUnwrap(s.intestazione.firstIndex(of: colonna))
            return s.righe.reduce(0) { $0 + (Int($1[indice]) ?? 0) }
        }

        XCTAssertEqual(try valore("sessioni_di_campagna_giocate"), campagna.righe.count)
        XCTAssertEqual(try valore("giornate_giocate_nelle_sessioni"),
                       try somma(campagna, "giornate"))
        XCTAssertEqual(try valore("ordini_impartiti_nelle_sessioni"),
                       try somma(campagna, "ordini"))
        XCTAssertEqual(try valore("violazioni_nelle_sessioni_di_campagna"),
                       try somma(campagna, "violazioni"))
        XCTAssertEqual(try valore("sessioni_di_battaglia_giocate"), battaglia.righe.count)
        XCTAssertEqual(try valore("comandi_nelle_sessioni_di_battaglia"),
                       try somma(battaglia, "comandi"))
        XCTAssertEqual(try valore("violazioni_nelle_sessioni_di_battaglia"),
                       try somma(battaglia, "violazioni"))
        XCTAssertEqual(try valore("invarianti_di_sessione_campagna"),
                       SondaSessioneCampagna.codiciNoti.count)
        XCTAssertEqual(try valore("invarianti_di_sessione_battaglia"),
                       SondaSessioneBattaglia.codiciNoti.count)

        let indiceGruppi = try XCTUnwrap(campagna.intestazione.firstIndex(of: "gruppi"))
        let gruppi = campagna.righe.compactMap { Int($0[indiceGruppi]) }
        XCTAssertEqual(try valore("gruppi_minimo_nelle_sessioni"), gruppi.min())
        XCTAssertEqual(try valore("gruppi_massimo_nelle_sessioni"), gruppi.max())
    }

    /// L'estensione dei parametri non si restringe in silenzio: le sessioni devono
    /// percorrere tutti i formati di mappa, entrambe le disposizioni, entrambe le
    /// condotte, e almeno una composizione di mazzo che lasci forze in riserva.
    func test_05_12_3_l_estensione_dei_parametri_e_quella_dichiarata() throws {
        let rapporto = try programma(fumo: false).esegui()
        let campagna = try XCTUnwrap(rapporto.sezioni.first { $0.nome == "sessioni_campagna" })
        func distinti(_ colonna: String) throws -> Set<String> {
            let i = try XCTUnwrap(campagna.intestazione.firstIndex(of: colonna))
            return Set(campagna.righe.map { $0[i] })
        }
        let valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        XCTAssertEqual(try distinti("mappa").count, valoriCampagna.mappe.count,
                       "le sessioni non percorrono tutte le mappe")
        XCTAssertEqual(try distinti("disposizione"),
                       Set(BancoSessioniCampagna.Disposizione.allCases.map(\.rawValue)))
        XCTAssertEqual(try distinti("condotta"),
                       Set(BancoSessioniCampagna.Condotta.allCases.map(\.rawValue)))

        let battaglia = try XCTUnwrap(rapporto.sezioni.first { $0.nome == "sessioni_battaglia" })
        let riserve = try XCTUnwrap(battaglia.intestazione.firstIndex(of: "riserve_rimaste"))
        XCTAssertTrue(battaglia.righe.contains { (Int($0[riserve]) ?? 0) > 0 },
                      "nessuna sessione di battaglia lascia forze in riserva: la composizione "
                      + "abbondante non sta esercitando il deck come riserva vera (01 §9.3.5)")
    }
}
