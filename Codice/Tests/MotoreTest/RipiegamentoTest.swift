import XCTest
import Motore
import Dati
import Contenuti

/// Le caselle di ripiegamento dello sconfitto (01 §10.6, §15.6) e la regola di una formazione per parte
/// per casella (01 §5.6.0.2). La destinazione di una marcia in corso è PRENOTATA quanto una casella
/// occupata (la validazione della marcia la rifiuta a un secondo gruppo, `MotoreCampagna.valida`): lo
/// sconfitto non vi ripiega, perché all'arrivo della marcia la casella ospiterebbe due gruppi della stessa
/// parte. Trovato dalla misura della frequenza delle battaglie (incarico 29): due partite su 1200.
final class RipiegamentoTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    var motore: MotoreCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
    }

    private func crea(gruppi: [Cella]) throws -> StatoCampagna {
        try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: "guado", gruppiGiocatore: gruppi.map {
                .init(riga: $0.riga, colonna: $0.colonna,
                      composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)]) }),
            valori: valoriCampagna, archetipiNoti: Set(valori.archetipi.keys))
    }

    /// Lo sconfitto in `contesa`, la sua prima casella di ripiegamento con la mappa libera, e un altro
    /// gruppo proprio che vi può marciare (adiacente, non nella casella contesa).
    private func disposizione() throws -> (contesa: Cella, prenotata: Cella, marciante: Cella) {
        let contesa = Cella(riga: 2, colonna: 3)
        let solo = try crea(gruppi: [contesa])
        let prenotata = try XCTUnwrap(PonteCampagnaBattaglia.caselleDiRipiegamento(
            per: .giocatore, da: contesa, stato: solo).first, "lo sconfitto ha almeno una casella di ripiegamento")
        let marciante = try XCTUnwrap(solo.griglia.vicini(di: prenotata).sorted().first {
            $0 != contesa && solo.griglia.contiene($0)
        })
        return (contesa, prenotata, marciante)
    }

    func test_01_5_6_0_2_lo_sconfitto_non_ripiega_nella_meta_di_una_marcia_propria() throws {
        let (contesa, prenotata, marciante) = try disposizione()
        var stato = try crea(gruppi: [contesa, marciante])
        let idMarciante = try XCTUnwrap(stato.occupante(di: marciante)).id
        let giorni = motore.costoInGiorni(da: marciante, a: prenotata, stato: stato)
        let marcia = ComandoCampagna.marcia(gruppo: idMarciante, a: prenotata, giorni: giorni)
        XCTAssertTrue(motore.valida(marcia, parte: .giocatore, stato: stato).eValido)
        stato = motore.applica(marcia, parte: .giocatore, stato: stato).0
        XCTAssertEqual(stato.gruppi[idMarciante]?.marcia?.destinazione, prenotata, "la marcia è in corso")

        let caselle = PonteCampagnaBattaglia.caselleDiRipiegamento(per: .giocatore, da: contesa, stato: stato)
        XCTAssertFalse(caselle.contains(prenotata),
                       "lo sconfitto ripiegherebbe in \(prenotata), meta della marcia del gruppo \(idMarciante): "
                       + "all'arrivo la casella ospiterebbe due gruppi del giocatore (01 §5.6.0.2)")
    }

    /// La prenotazione è degli ALTRI gruppi: la marcia dello sconfitto stesso si interrompe con la
    /// battaglia (`applicaEsitoInCampagna`), sicché la sua meta resta una casella dove può ripiegare.
    func test_la_meta_della_marcia_dello_sconfitto_stesso_resta_disponibile() throws {
        let (contesa, prenotata, _) = try disposizione()
        // Un secondo gruppo, fermo, tiene aperta la giornata: altrimenti la marcia si compirebbe subito.
        let fermo = try XCTUnwrap(try crea(gruppi: [contesa]).griglia.tutteLeCaselle.first {
            $0 != contesa && $0 != prenotata
        })
        var stato = try crea(gruppi: [contesa, fermo])
        let idSconfitto = try XCTUnwrap(stato.occupante(di: contesa)).id
        let giorni = motore.costoInGiorni(da: contesa, a: prenotata, stato: stato)
        stato = motore.applica(.marcia(gruppo: idSconfitto, a: prenotata, giorni: giorni),
                               parte: .giocatore, stato: stato).0
        XCTAssertEqual(stato.gruppi[idSconfitto]?.marcia?.destinazione, prenotata)
        XCTAssertTrue(PonteCampagnaBattaglia.caselleDiRipiegamento(per: .giocatore, da: contesa, stato: stato)
            .contains(prenotata))
    }
}
