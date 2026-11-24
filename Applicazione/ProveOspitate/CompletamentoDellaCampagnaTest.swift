import XCTest
import UIKit
import Dati
import Motore
import Sessione
import Segnali
import Contenuti
@testable import WarSense

/// La presa del quartier generale e il richiamo dell'esercito attraverso l'interfaccia (01 §5.18.2, §5.18.3;
/// 02 §6.5.5, §8.2.2; incarico 32): ciò che la mappa dice a ogni passo, dove lo dice, il comando di richiamo
/// con il suo perché, e la patria che ne dichiara l'esito.
@MainActor
final class CompletamentoDellaCampagnaTest: XCTestCase {

    private var finestra: UIWindow?

    override func tearDown() async throws {
        finestra?.isHidden = true
        finestra = nil
        try? FileManager.default.removeItem(at: PartitaRegno.cartellaRegno)
        try? FileManager.default.removeItem(at: Ambiente.cartellaValori)
        try await super.tearDown()
    }

    private func monta(_ controllore: UIViewController) {
        let finestra = UIWindow(frame: CGRect(x: 0, y: 0, width: 420, height: 912))
        finestra.rootViewController = controllore
        finestra.makeKeyAndVisible()
        controllore.loadViewIfNeeded()
        controllore.view.layoutIfNeeded()
        self.finestra = finestra
    }

    private func attendi(_ che: String = "", _ condizione: () -> Bool, giri: Int = 500,
                         file: StaticString = #filePath, line: UInt = #line) async throws {
        for _ in 0..<giri where !condizione() { try await Task.sleep(nanoseconds: 20_000_000) }
        XCTAssertTrue(condizione(), "attesa scaduta: \(che)", file: file, line: line)
    }

    private func lettura(_ schermata: UIViewController) -> [String] {
        schermata.view.layoutIfNeeded()
        return LettoreAccessibilita.ordineDiLettura(radice: schermata.view as Any).map { LettoreAccessibilita.etichetta(di: $0) }
    }

    private func premi(_ prefisso: String, in schermata: UIViewController,
                       file: StaticString = #filePath, line: UInt = #line) throws {
        let elemento = try XCTUnwrap(LettoreAccessibilita.ordineDiLettura(radice: schermata.view as Any)
            .first { LettoreAccessibilita.etichetta(di: $0).hasPrefix(prefisso) }, "manca «\(prefisso)» in \(lettura(schermata))",
                                     file: file, line: line)
        try XCTUnwrap(elemento as? UIControl, file: file, line: line).sendActions(for: .touchUpInside)
    }

    /// La patria di un regno nuovo con la campagna aperta sul guado, e gli scenari messi a punto nella
    /// cartella Documenti come farebbe chi li tara (00 §15.4): il giocatore sul quartier generale avversario,
    /// riga 1 casella 2, e l'avversario lontano, dove il test lo vuole.
    private func campagna(avversario: [[String: Any]], giocatore: [[Int]] = [[1, 2], [4, 2], [4, 3], [4, 4], [4, 1]])
        async throws -> (SchermataPatria, SchermataMappaCampagna, Ambiente) {
        _ = try Ambiente()
        let url = Ambiente.cartellaValori.appendingPathComponent("scenari-campagna.json")
        var scenari = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        var piccola = try XCTUnwrap(scenari["campagna_piccola"] as? [String: Any])
        piccola["gruppi_giocatore"] = giocatore.map {
            ["riga": $0[0], "colonna": $0[1], "composizione": [["archetipo": "fanteria_leggera", "atomi": 6]]] as [String: Any]
        }
        piccola["gruppi_avversario"] = avversario
        scenari["campagna_piccola"] = piccola
        try JSONSerialization.data(withJSONObject: scenari).write(to: url)
        let ambiente = try Ambiente()
        let patria = SchermataPatria(partita: try await PartitaRegno(nuovo: ambiente))
        monta(patria)
        try await attendi("la patria si carica") { self.lettura(patria).contains("Riserve") }
        await patria.apriLaCampagnaPerProva(sul: "guado")
        try await attendi("si entra nel fronte") { patria.presentedViewController is SchermataMappaCampagna }
        let mappa = try XCTUnwrap(patria.presentedViewController as? SchermataMappaCampagna)
        try await attendi("la mappa si carica") { !mappa.elementiPerProva.isEmpty && mappa.statoPerProva != nil }
        return (patria, mappa, ambiente)
    }

    private func armato(_ riga: Int, _ colonna: Int) -> [String: Any] {
        ["riga": riga, "colonna": colonna, "composizione": [["archetipo": "fanteria_leggera", "atomi": 6]]]
    }

    private func chiudiUnaGiornata(_ mappa: SchermataMappaCampagna) async throws {
        let giorno = mappa.statoPerProva?.giorno
        mappa.chiudiGiornataPerProva()
        try await attendi("la giornata si chiude") {
            mappa.statoPerProva?.giorno != giorno || mappa.statoPerProva?.conclusione != nil
        }
    }

    // MARK: - La presa

    /// Il giocatore tiene il quartier generale avversario: a ogni chiusura la mappa lo dice, nell'annuncio,
    /// nella casella e nell'informazione di stato; alla terza la campagna è vinta, e la patria lo dichiara.
    func test_01_5_18_3_il_giocatore_prende_il_quartier_generale_e_ogni_passo_si_sente() async throws {
        // L'avversario sa che il proprio è occupato e vi torna, ma è all'altro capo della mappa e non arriva
        // in tempo.
        let (patria, mappa, ambiente) = try await campagna(
            avversario: [armato(4, 4)], giocatore: [[1, 2], [4, 1], [3, 1], [2, 1], [1, 1]])
        let suo = Cella(riga: 1, colonna: 2)
        let attesi = [
            "Occupi il quartier generale avversario, in riga 1, casella 2: se lo tieni sarà preso fra 3 giornate",
            "Tieni il quartier generale avversario: sarà preso fra 2 giornate",
            "Tieni il quartier generale avversario: sarà preso fra 1 giornata",
        ]
        for (indice, atteso) in attesi.enumerated() {
            let mancano = 3 - indice
            ambiente.segnali.azzeraAnnunciPronunciati()
            try await chiudiUnaGiornata(mappa)
            XCTAssertEqual(mappa.statoPerProva?.battaglieInSospeso, [])
            let detti = ambiente.segnali.annunciPronunciati.map(\.testo)
            XCTAssertTrue(detti.contains(atteso), "\(detti)")
            // La casella del quartier generale porta le giornate che mancano, a voce e a schermo.
            let etichetta = LettoreAccessibilita.etichetta(di: try XCTUnwrap(mappa.elementiPerProva[suo]))
            let giornate = mancano == 1 ? "1 giornata" : "\(mancano) giornate"
            XCTAssertTrue(etichetta.contains("quartier generale avversario, occupato, sarà preso fra \(giornate)"), etichetta)
            // L'informazione di stato lo dice, in coda.
            ambiente.segnali.azzeraAnnunciPronunciati()
            XCTAssertTrue(mappa.accessibilityPerformMagicTap())
            let stato = ambiente.segnali.annunciPronunciati.last?.testo ?? ""
            XCTAssertTrue(stato.hasSuffix(". Occupi il quartier generale avversario, sarà preso fra \(giornate)"), stato)
        }
        ambiente.segnali.azzeraAnnunciPronunciati()
        mappa.chiudiGiornataPerProva()
        try await attendi("la campagna si conclude") { mappa.statoPerProva?.conclusione != nil }
        XCTAssertTrue(ambiente.segnali.annunciPronunciati.map(\.testo)
            .contains("Campagna conclusa: il quartier generale avversario è caduto. Hai vinto"))
        try await attendi("compare la dichiarazione di conclusione") { patria.presentedViewController is SchermataResoconto }
        let dichiarazione = try XCTUnwrap(patria.presentedViewController as? SchermataResoconto)
        dichiarazione.loadViewIfNeeded()
        XCTAssertTrue(lettura(dichiarazione).contains("Vittoria: il quartier generale avversario sul fronte del guado è caduto"))
    }

    /// L'avversario prende il quartier generale del giocatore, che è lontano e non lo osserva: lo sente dal
    /// primo giorno, lo vede sulla casella e nel registro, e alla terza giornata la campagna è perduta.
    func test_01_5_18_3_3_il_difensore_sa_sempre_che_il_proprio_quartier_generale_e_occupato() async throws {
        let (patria, mappa, ambiente) = try await campagna(
            avversario: [armato(4, 2)], giocatore: [[1, 4], [2, 4], [1, 3], [2, 3], [1, 1]])
        let mio = Cella(riga: 4, colonna: 2)
        ambiente.segnali.azzeraAnnunciPronunciati()
        try await chiudiUnaGiornata(mappa)
        XCTAssertTrue(ambiente.segnali.annunciPronunciati.map(\.testo).contains(
            "L'avversario occupa il tuo quartier generale, in riga 4, casella 2: se non lo scacci sarà preso fra 3 giornate"))
        var etichetta = LettoreAccessibilita.etichetta(di: try XCTUnwrap(mappa.elementiPerProva[mio]))
        XCTAssertTrue(etichetta.contains("formazione avversaria, tuo quartier generale, occupato, sarà preso fra 3 giornate"), etichetta)
        XCTAssertFalse(etichetta.contains("inesplorato"), "lo sa, anche senza osservarlo: \(etichetta)")
        mappa.apriRegistroPerProva()
        try await attendi("si apre il registro") { mappa.presentedViewController is SchermataRegistro }
        let registro = try XCTUnwrap(mappa.presentedViewController as? SchermataRegistro)
        registro.loadViewIfNeeded()
        XCTAssertTrue(lettura(registro).contains("Giorno 1: l'avversario occupa il tuo quartier generale in riga 4, casella 2"),
                      "\(lettura(registro))")
        registro.dismiss(animated: false)
        try await attendi("il registro si chiude") { mappa.presentedViewController == nil }
        for mancano in [2, 1] {
            ambiente.segnali.azzeraAnnunciPronunciati()
            try await chiudiUnaGiornata(mappa)
            let giornate = mancano == 1 ? "1 giornata" : "\(mancano) giornate"
            XCTAssertTrue(ambiente.segnali.annunciPronunciati.map(\.testo)
                .contains("Il tuo quartier generale è ancora occupato: sarà preso fra \(giornate)"))
            etichetta = LettoreAccessibilita.etichetta(di: try XCTUnwrap(mappa.elementiPerProva[mio]))
            XCTAssertTrue(etichetta.contains("occupato, sarà preso fra \(giornate)"), etichetta)
        }
        ambiente.segnali.azzeraAnnunciPronunciati()
        mappa.chiudiGiornataPerProva()
        try await attendi("la campagna si conclude") { mappa.statoPerProva?.conclusione != nil }
        XCTAssertTrue(ambiente.segnali.annunciPronunciati.map(\.testo)
            .contains("Campagna conclusa: il tuo quartier generale è caduto. Hai perso"))
        try await attendi("compare la dichiarazione di conclusione") { patria.presentedViewController is SchermataResoconto }
        let dichiarazione = try XCTUnwrap(patria.presentedViewController as? SchermataResoconto)
        dichiarazione.loadViewIfNeeded()
        let letta = lettura(dichiarazione)
        XCTAssertTrue(letta.contains("Sconfitta: il tuo quartier generale sul fronte del guado è caduto"), "\(letta)")
        XCTAssertTrue(letta.contains("Rientrano in patria: 5 formazioni"), "i superstiti tornano tutti: \(letta)")
        XCTAssertTrue(letta.contains("Nessun premio: quest'inverno arriva la sola rendita"), "\(letta)")
        dichiarazione.chiudiTuttoPerProva()
        try await attendi("si torna in patria") { patria.presentedViewController == nil }
        XCTAssertTrue(lettura(patria).contains("Campagna sul fronte del guado perduta"))
    }

    // MARK: - Il richiamo

    /// Il comando sta fra i comandi della mappa, chiede conferma, e conclude la campagna: conta come perduta
    /// e le formazioni rientrano tutte.
    func test_01_5_18_2_il_richiamo_chiede_conferma_e_riporta_l_esercito_in_patria() async throws {
        let (patria, mappa, ambiente) = try await campagna(avversario: [armato(1, 2)], giocatore: [[4, 2], [4, 3], [4, 4], [4, 1], [3, 1]])
        XCTAssertTrue(lettura(mappa).contains("Richiama l'esercito in patria"))
        // Si rinuncia: nulla cambia.
        try premi("Richiama l'esercito in patria", in: mappa)
        try await attendi("si chiede conferma") { mappa.presentedViewController is UIAlertController }
        let pannello = try XCTUnwrap(mappa.presentedViewController as? UIAlertController)
        XCTAssertEqual(pannello.title, "Richiamare l'esercito in patria?")
        XCTAssertEqual(pannello.message, "La campagna si conclude e conta come perduta. I superstiti tornano tutti in patria")
        XCTAssertEqual(mappa.vociPannelloPerProva.map(\.titolo), ["Conferma il richiamo", "Rinuncia"])
        mappa.vociPannelloPerProva[1].esegui()
        pannello.dismiss(animated: false)
        try await attendi("il pannello si chiude") { mappa.presentedViewController == nil }
        XCTAssertNil(mappa.statoPerProva?.conclusione)
        // Si conferma.
        try premi("Richiama l'esercito in patria", in: mappa)
        try await attendi("si chiede conferma di nuovo") { mappa.presentedViewController is UIAlertController }
        ambiente.segnali.azzeraAnnunciPronunciati()
        mappa.vociPannelloPerProva[0].esegui()
        mappa.presentedViewController?.dismiss(animated: false)
        try await attendi("compare la dichiarazione di conclusione") { patria.presentedViewController is SchermataResoconto }
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo).first,
                       "Campagna conclusa: hai richiamato l'esercito in patria. Conta come perduta")
        let dichiarazione = try XCTUnwrap(patria.presentedViewController as? SchermataResoconto)
        dichiarazione.loadViewIfNeeded()
        let letta = lettura(dichiarazione)
        XCTAssertTrue(letta.contains("Hai richiamato l'esercito dal fronte del guado: la campagna conta come perduta"), "\(letta)")
        XCTAssertTrue(letta.contains("Rientrano in patria: 5 formazioni"), "\(letta)")
        dichiarazione.chiudiTuttoPerProva()
        try await attendi("si torna in patria") { patria.presentedViewController == nil }
        XCTAssertTrue(lettura(patria).contains("Campagna sul fronte del guado perduta: esercito richiamato in patria"))
    }

    /// Quando non si può, il comando lo dice nella propria etichetta e quando lo si attiva, con il gruppo e il
    /// luogo, e nessun pannello si apre.
    func test_02_6_5_5_il_richiamo_impedito_dichiara_il_perche() async throws {
        let (_, mappa, ambiente) = try await campagna(avversario: [armato(3, 2)], giocatore: [[2, 2], [4, 4], [4, 1], [3, 4], [1, 4]])
        let nome = try XCTUnwrap(mappa.statoPerProva?.occupante(di: Cella(riga: 2, colonna: 2))?.nome).capitalized
        let motivo = "\(nome) ha il rifornimento tagliato in riga 2, casella 2"
        XCTAssertTrue(lettura(mappa).contains("Richiama l'esercito in patria, adesso non si può: \(motivo)"), "\(lettura(mappa))")
        ambiente.segnali.azzeraAnnunciPronunciati()
        try premi("Richiama l'esercito in patria", in: mappa)
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo), ["L'esercito non si può richiamare: \(motivo)"])
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertNil(mappa.presentedViewController)
        XCTAssertNil(mappa.statoPerProva?.conclusione)
    }

    /// Le campagne di prova non hanno una patria a cui tornare: il comando non c'è.
    func test_01_5_18_2_le_campagne_di_prova_non_hanno_il_richiamo() async throws {
        let ambiente = try Ambiente()
        let mappa = SchermataMappaCampagna(partita: try await PartitaCampagna(nuova: ambiente, taglia: .piccola))
        monta(mappa)
        try await attendi("la mappa si carica") { !mappa.elementiPerProva.isEmpty }
        XCTAssertFalse(lettura(mappa).contains { $0.hasPrefix("Richiama l'esercito") }, "\(lettura(mappa))")
        try? FileManager.default.removeItem(at: PartitaCampagna.cartellaCampagna)
    }
}
