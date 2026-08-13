import XCTest
import Verifica
import Motore
import Dati
import Contenuti

/// La conclusione della battaglia (incarico 26): ogni battaglia si chiude in un numero finito di
/// turni, per una delle vie previste (01 §15.2.3). Il difetto segnalato dalla sessione dell'incarico
/// 25 e non toccato allora: in una battaglia molto sbilanciata la parte perdente conservava una
/// riserva troppo grande per il budget — mai schierabile (01 §8.6), mai annientata perché il deck
/// non era vuoto, mai in resa — e nessuna via chiudeva lo scontro. Reso impossibile: una riserva non
/// schierabile non tiene «viva» la parte, e l'annientamento chiude in pochi giri.
final class ConclusioneBattagliaTest: XCTestCase {

    /// Il limite dichiarato di giri entro cui OGNI battaglia deve concludersi. Generoso: uno scontro
    /// vero si chiude in poche decine di giri; 300 è la rete che coglie il non-terminare, non un
    /// limite di gioco.
    private let limiteGiri = 300

    /// Uno scontro in cui l'avversario ha una sola riserva, un solo sciame di volume 500 (10 atomi di
    /// `macchina_assedio`, 50 di volume l'uno) che eccede ogni budget del formato `cento` (base 300,
    /// primo turno 360): non entra mai in campo. Prima della correzione lo scontro non si concludeva;
    /// ora la parte senza sciami e senza riserve schierabili è annientata (01 §15.2.3).
    func test_incarico_26_la_battaglia_sbilanciata_si_conclude() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        let motore = MotoreBattaglia(valori: valori)
        let scenario = ScenarioBattaglia(
            formato: "cento", caratteristica: "campo_aperto", ostacoli: [],
            primoOccupante: .giocatore, imboscata: false,
            deckGiocatore: [.init(archetipo: "fanteria_leggera", protezione: .antiSaturazione,
                                  atomi: 5, esemplari: 4)],
            deckAvversario: [.init(archetipo: "macchina_assedio", protezione: .antiPerforazione,
                                   atomi: 10, esemplari: 1)],
            ufficialeAvversario: "ufficiale_prova")
        var stato = try FabbricaBattaglia.crea(scenario: scenario, valori: valori).0
        let ufficiale = try XCTUnwrap(valori.ufficiali["ufficiale_prova"])
        let tattici: [Parte: TatticoBattaglia] = [
            .giocatore: TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .giocatore),
            .avversario: TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .avversario),
        ]

        var comandi = 0
        let tettoComandi = limiteGiri * 200
        while stato.esito == nil && stato.giro <= limiteGiri && comandi < tettoComandi {
            let parte = stato.parteDiTurno
            stato = motore.applica(tattici[parte]!.prossimoComando(stato: stato), parte: parte, stato: stato).0
            comandi += 1
        }

        XCTAssertNotNil(stato.esito,
            "la battaglia sbilanciata non si è conclusa entro \(limiteGiri) giri (giro=\(stato.giro), comandi=\(comandi)): la riserva non schierabile la teneva aperta")
        // L'invariante non deve trovare nulla su una battaglia conclusa nel limite.
        let sonda = SondaInvariantiCampagna()
        XCTAssertEqual(
            sonda.controllaConclusioneBattaglia(concluso: stato.esito != nil, giri: stato.giro, limite: limiteGiri),
            [], "la sonda ha segnalato non conclusa una battaglia che si è chiusa")
    }
}
