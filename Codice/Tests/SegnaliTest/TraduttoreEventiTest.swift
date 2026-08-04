import XCTest
import Segnali
import Motore
import Dati
import Contenuti

/// Gli annunci si provano per quello che dicono (incarico fase B): vocabolario
/// chiuso rispettato, verbosità che taglia dalla coda, significati assegnati.
final class TraduttoreEventiTest: XCTestCase {

    var testi: Testi!
    var traduttore: TraduttoreEventi!

    override func setUpWithError() throws {
        testi = try Testi.carica(albero: Contenuti.testiDiFabbrica, lingua: "it")
        traduttore = TraduttoreEventi(testi: testi, parte: .giocatore)
    }

    func test_05_10_7_ogni_evento_annunciabile_ha_il_suo_modello() throws {
        let cella = Cella(riga: 3, colonna: 4)
        let esitoContatto = EsitoContatto(partePrimo: .giocatore, cellaPrimo: cella,
                                          cellaSecondo: Cella(riga: 2, colonna: 4),
                                          dannoAlPrimo: 10, dannoAlSecondo: 20,
                                          fasciaAlPrimo: .lievi, fasciaAlSecondo: .significative)
        let eventi: [EventoBattaglia] = [
            .turnoIniziato(parte: .giocatore, numeroGiro: 2),
            .turnoIniziato(parte: .avversario, numeroGiro: 2),
            .piazzamentoConfermato(parte: .giocatore, sciame: IdSciame(1), archetipo: "fanteria_leggera",
                                   lettera: 1, cella: cella, costo: 12, residuo: 88),
            .piazzamentoConfermato(parte: .avversario, sciame: IdSciame(2), archetipo: "fanteria_pesante",
                                   lettera: 1, cella: cella, costo: 12, residuo: 88),
            .elementoDeckEsaurito(parte: .giocatore, indice: 0),
            .spostamentoEseguito(parte: .giocatore, sciame: IdSciame(1), archetipo: "fanteria_leggera",
                                 lettera: 1, a: cella, costo: 9, residuo: 70),
            .spostamentoEseguito(parte: .avversario, sciame: IdSciame(2), archetipo: "fanteria_pesante",
                                 lettera: 1, a: cella, costo: 9, residuo: 70),
            .tiroEseguito(parte: .giocatore, sciame: IdSciame(1), bersaglio: IdSciame(2),
                          bersaglioArchetipo: "fanteria_pesante", bersaglioLettera: 2,
                          danno: 30, fascia: .significative, efficacia: .pocoEfficace),
            .tiroEseguito(parte: .avversario, sciame: IdSciame(2), bersaglio: IdSciame(1),
                          bersaglioArchetipo: "fanteria_leggera", bersaglioLettera: 1,
                          danno: 30, fascia: .lievi, efficacia: .efficace),
            .contattoRisolto(parte: .giocatore, bersaglioArchetipo: "fanteria_leggera",
                             bersaglioLettera: 1, esito: esitoContatto),
            .esitoMischiaComplessivo([esitoContatto]),
            .disingaggio(sciame: IdSciame(2), da: cella, a: Cella(riga: 4, colonna: 4)),
            .sciameDisfatto(sciame: IdSciame(2), archetipo: "fanteria_pesante", lettera: 2,
                            cella: cella, parte: .avversario),
            .munizioniEsaurite(sciame: IdSciame(1), cella: cella),
            .resaDichiarata(parte: .avversario),
            .unitaEvacuata(parte: .giocatore, sciame: IdSciame(1), costo: 15),
            .unitaEvacuata(parte: .avversario, sciame: IdSciame(2), costo: 15),
            .sorpresaConclusa,
            .battagliaConclusa(EsitoBattaglia(sconfitto: .avversario, modo: .annientamento, turni: 9)),
        ]
        for evento in eventi {
            guard let annuncio = traduttore.annuncio(per: evento, verbosita: .normale) else {
                return XCTFail("evento senza annuncio: \(evento)")
            }
            XCTAssertFalse(annuncio.testo.contains(Testi.segnaposto),
                           "chiave irrisolta per \(evento): \(annuncio.testo)")
            XCTAssertEqual(annuncio.lingua, "it", "ogni testo dichiara la propria lingua (00 §14.4)")
        }
    }

    func test_00_9_4_il_vocabolario_chiuso_entra_nell_annuncio_senza_varianti() throws {
        // Il tiro annuncia la fascia chiusa e la lettera del bersaglio (01 §9.7.2, §9.4.3).
        let evento = EventoBattaglia.tiroEseguito(parte: .giocatore, sciame: IdSciame(1),
                                                  bersaglio: IdSciame(2),
                                                  bersaglioArchetipo: "fanteria_pesante",
                                                  bersaglioLettera: 2,
                                                  danno: 30, fascia: .gravi, efficacia: .pocoEfficace)
        let annuncio = traduttore.annuncio(per: evento, verbosita: .normale)!
        XCTAssertTrue(annuncio.testo.contains(testi.termine("perdite.inflitte.gravi").testo),
                      "la fascia chiusa compare tale e quale (00 §9.4, 01 §9.7.2)")
        XCTAssertTrue(annuncio.testo.contains(testi.termine("lettera.2").testo),
                      "il bersaglio è designato con la lettera (01 §9.4.3)")
        XCTAssertFalse(annuncio.testo.contains("30"),
                       "nessun numero di danno nell'annuncio (01 §9.7.2)")
    }

    func test_00_9_5_la_verbosita_taglia_dalla_coda() throws {
        let evento = EventoBattaglia.turnoIniziato(parte: .giocatore, numeroGiro: 3)
        let normale = traduttore.annuncio(per: evento, verbosita: .normale)!.testo
        let sintetico = traduttore.annuncio(per: evento, verbosita: .sintetico)!.testo
        XCTAssertLessThan(sintetico.count, normale.count, "il sintetico è più breve")
        XCTAssertTrue(normale.hasPrefix(String(sintetico.prefix(8))),
                      "il sintetico è la testa della frase, non un rimontaggio (00 §9.5)")
    }

    func test_01_9_7_1_la_mischia_e_una_sola_comunicazione_ordinata() throws {
        let esiti = [
            EsitoContatto(partePrimo: .giocatore, cellaPrimo: Cella(riga: 5, colonna: 2),
                          cellaSecondo: Cella(riga: 4, colonna: 2), dannoAlPrimo: 10, dannoAlSecondo: 30,
                          fasciaAlPrimo: .lievi, fasciaAlSecondo: .gravi),
            EsitoContatto(partePrimo: .avversario, cellaPrimo: Cella(riga: 4, colonna: 6),
                          cellaSecondo: Cella(riga: 5, colonna: 6), dannoAlPrimo: 12, dannoAlSecondo: 8,
                          fasciaAlPrimo: .significative, fasciaAlSecondo: .lievi),
        ]
        let annuncio = traduttore.annuncio(per: .esitoMischiaComplessivo(esiti), verbosita: .normale)!
        XCTAssertTrue(annuncio.testo.contains(testi.frase("battaglia.mischia_separatore").testo),
                      "i contatti stanno in un unico annuncio, separati e ordinati (01 §9.7.1)")
        // Il segno complessivo si valuta dal punto di vista di chi ascolta.
        XCTAssertEqual(traduttore.significato(per: .esitoMischiaComplessivo(esiti)),
                       .mischiaFavorevole, "inflitte 30+12 contro subite 10+8")
        let traduttoreAvversario = TraduttoreEventi(testi: testi, parte: .avversario)
        XCTAssertEqual(traduttoreAvversario.significato(per: .esitoMischiaComplessivo(esiti)),
                       .mischiaSfavorevole)
    }

    func test_01_9_3_7_il_volume_avversario_non_compare_in_alcuna_forma() throws {
        // Gli eventi avversari con costi nei fatti interni: l'annuncio non ne parla.
        let cella = Cella(riga: 2, colonna: 3)
        let eventi: [EventoBattaglia] = [
            .piazzamentoConfermato(parte: .avversario, sciame: IdSciame(7), archetipo: "tiratori",
                                   lettera: 3, cella: cella, costo: 77, residuo: 55),
            .spostamentoEseguito(parte: .avversario, sciame: IdSciame(7), archetipo: "tiratori",
                                 lettera: 3, a: cella, costo: 77, residuo: 55),
            .unitaEvacuata(parte: .avversario, sciame: IdSciame(7), costo: 77),
        ]
        for evento in eventi {
            let annuncio = traduttore.annuncio(per: evento, verbosita: .dettagliato)!
            XCTAssertFalse(annuncio.testo.contains("77"),
                           "niente volume speso dell'avversario (01 §9.3.7): \(annuncio.testo)")
            XCTAssertFalse(annuncio.testo.contains("55"),
                           "niente volume residuo dell'avversario (01 §9.3.7): \(annuncio.testo)")
        }
        // L'ingresso di forze avversarie però si annuncia, con nome e lettera (02 §8.2.1, 01 §9.4.3).
        let ingresso = traduttore.annuncio(per: eventi[0], verbosita: .normale)!
        XCTAssertTrue(ingresso.testo.contains(testi.frase("unita.tiratori").testo))
        XCTAssertTrue(ingresso.testo.contains(testi.termine("lettera.3").testo))
    }

    func test_02_8_9_1_la_mischia_annuncia_fasce_e_stallo_mai_numeri() throws {
        let contatto = EsitoContatto(partePrimo: .giocatore, cellaPrimo: Cella(riga: 5, colonna: 2),
                                     cellaSecondo: Cella(riga: 4, colonna: 2),
                                     dannoAlPrimo: 47, dannoAlSecondo: 93,
                                     fasciaAlPrimo: .lievi, fasciaAlSecondo: .gravi)
        let annuncio = traduttore.annuncio(per: .esitoMischiaComplessivo([contatto]), verbosita: .normale)!
        XCTAssertTrue(annuncio.testo.contains(testi.termine("perdite.inflitte.gravi").testo),
                      "le perdite inflitte in fascia, dal punto di vista di chi ascolta")
        XCTAssertTrue(annuncio.testo.contains(testi.termine("perdite.subite.lievi").testo))
        XCTAssertFalse(annuncio.testo.contains("47"), "mai numeri di danno (01 §9.7.2)")
        XCTAssertFalse(annuncio.testo.contains("93"), "mai numeri di danno (01 §9.7.2)")

        let stallo = EsitoContatto(partePrimo: .giocatore, cellaPrimo: Cella(riga: 5, colonna: 2),
                                   cellaSecondo: Cella(riga: 4, colonna: 2),
                                   dannoAlPrimo: 0, dannoAlSecondo: 0,
                                   fasciaAlPrimo: .nessuna, fasciaAlSecondo: .nessuna)
        let annuncioStallo = traduttore.annuncio(per: .esitoMischiaComplessivo([stallo]), verbosita: .normale)!
        XCTAssertTrue(annuncioStallo.testo.contains(testi.termine("esito.stallo").testo),
                      "il contatto senza perdite da ambo i lati è uno stallo (02 §4.4.5)")
    }

    func test_02_11_7_1_significati_ed_esclusioni() throws {
        XCTAssertEqual(traduttore.significato(per: .munizioniEsaurite(sciame: IdSciame(1),
                                                                      cella: Cella(riga: 1, colonna: 1))),
                       .munizioniEsaurite)
        XCTAssertNil(traduttore.significato(per: .turnoIniziato(parte: .giocatore, numeroGiro: 1)),
                     "il cambio di turno non è fra i quindici significati")
        XCTAssertFalse(SignificatoSegnale.rinforziNelDeck.conSegnaleTattile,
                       "i rinforzi restano a suono e voce (02 §11.7.1)")
        // Ogni significato con segnale tattile ha il pattern e il suono nei dati (00 §5.2).
        let definizioni = try DefinizioniSegnali.carica(
            da: Contenuti.valoriDiFabbrica)
        for significato in SignificatoSegnale.allCases {
            XCTAssertNotNil(definizioni.suoni[significato.rawValue],
                            "suono mancante per \(significato.rawValue)")
            if significato.conSegnaleTattile {
                XCTAssertNotNil(definizioni.pattern[significato.rawValue],
                                "pattern tattile mancante per \(significato.rawValue)")
            }
        }
    }
}
