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
                                          dannoAlPrimo: 10, dannoAlSecondo: 20)
        let eventi: [EventoBattaglia] = [
            .turnoIniziato(parte: .giocatore, numeroGiro: 2),
            .turnoIniziato(parte: .avversario, numeroGiro: 2),
            .piazzamentoConfermato(parte: .giocatore, sciame: IdSciame(1), cella: cella, costo: 12, residuo: 88),
            .elementoDeckEsaurito(parte: .giocatore, indice: 0),
            .spostamentoEseguito(sciame: IdSciame(1), a: cella, costo: 9, residuo: 70),
            .tiroEseguito(sciame: IdSciame(1), bersaglio: IdSciame(2), danno: 30, efficacia: .pocoEfficace),
            .contattoAvviato(cella: cella),
            .esitoMischiaComplessivo([esitoContatto]),
            .disingaggio(sciame: IdSciame(2), da: cella, a: Cella(riga: 4, colonna: 4)),
            .sciameDisfatto(sciame: IdSciame(2), cella: cella, parte: .avversario),
            .munizioniEsaurite(sciame: IdSciame(1), cella: cella),
            .resaDichiarata(parte: .avversario),
            .unitaEvacuata(sciame: IdSciame(1), costo: 15),
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
        let evento = EventoBattaglia.tiroEseguito(sciame: IdSciame(1), bersaglio: IdSciame(2),
                                                  danno: 30, efficacia: .pocoEfficace)
        let annuncio = traduttore.annuncio(per: evento, verbosita: .normale)!
        XCTAssertTrue(annuncio.testo.contains(testi.termine("efficacia.poco_efficace").testo),
                      "il termine chiuso compare tale e quale (00 §9.4)")
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
                          cellaSecondo: Cella(riga: 4, colonna: 2), dannoAlPrimo: 10, dannoAlSecondo: 30),
            EsitoContatto(partePrimo: .avversario, cellaPrimo: Cella(riga: 4, colonna: 6),
                          cellaSecondo: Cella(riga: 5, colonna: 6), dannoAlPrimo: 12, dannoAlSecondo: 8),
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
