import XCTest
import Dati
import Motore
import Sessione
import Segnali
import Verifica
import Contenuti
@testable import WarSense

/// Le sessioni complete giocate ATTRAVERSO L'INTERFACCIA (05 §12.4, 00 §3.1).
///
/// Il programma di verifica gioca le proprie sessioni nel Motore; qui le medesime
/// sessioni — la stessa lista, non un campione e non un elenco parallelo — si
/// giocano toccando le caselle, e si pretende che diano lo stesso stato. È l'unica
/// prova del progetto che percorra l'intera catena su TUTTE le configurazioni
/// generate, e non su tre.
///
/// L'elenco ha una definizione sola, `BancoSessioniCampagna.configurazioni(…)`, e
/// così la CONDOTTA, `BancoSessioniCampagna.prossimoOrdine(stato:vista:condotta:)`:
/// il banco le usa per giocare nel Motore, questa prova per giocare al dito, e ciò
/// che qui si aggiunge è la sola traduzione dell'ordine in tocchi. Due elenchi o due
/// condotte separate sarebbero divergiti al primo cambiamento — ed è già accaduto
/// mentre questa prova veniva scritta: la prima stesura sceglieva il gruppo con
/// `gruppiOrdinati` da un lato e con il salto diretto dall'altro, e le impronte non
/// coincidevano appena i gruppi erano più d'uno.
///
/// ## Il costo, misurato
///
/// La prova stampa `MISURA sessioni per interfaccia` con giocate, ordini, durata,
/// costo per sessione e per ordine: i numeri del resoconto vengono da lì e non da un
/// conteggio a mano (RDA-71). Misurato il 2026-08-05 su iPhone Air: 144 sessioni su
/// 144 generate, 3744 ordini, 1258,6 secondi — 8,741 per sessione e 0,3362 per
/// ordine. È tre volte la stima di sette minuti su cui la decisione di tenerle nel
/// collaudo di ogni caricamento era stata presa.
///
/// ## Le sessioni di BATTAGLIA non passano di qui, e la ragione è un numero
///
/// Il banco genera 32 sessioni di battaglia per un totale di 130 322 comandi
/// (`#sessioni_riepilogo`, voce `comandi_nelle_sessioni_di_battaglia`). Al costo per
/// ordine misurato qui, 0,3362 secondi, passarle per l'interfaccia costerebbe
/// dell'ordine delle dodici ore. Non è una scelta di comodo: è la ragione per cui
/// restano al Motore, ed è dichiarata perché sia riesaminabile con il numero in
/// mano.
@MainActor
final class SessioniPerInterfacciaTest: XCTestCase {

    override func setUp() { super.setUp(); continueAfterFailure = false }

    /// Le giornate per sessione. Numero di STRUTTURA della misura e non di gioco
    /// (05 §0.4): governa quanto a lungo si gioca, non come.
    private static let giornatePerSessione = 4

    private func attendi(_ descrizione: String,
                         _ condizione: @MainActor () -> Bool) async throws {
        for _ in 0..<250 where !condizione() {
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        XCTAssertTrue(condizione(), "attesa scaduta: \(descrizione)")
    }

    private func ambienteEBanco() throws -> (WarSense.Ambiente, BancoSessioniCampagna, ValoriCampagna) {
        let ambiente = try WarSense.Ambiente()
        let banco = BancoSessioniCampagna(
            motore: MotoreCampagna(valori: ambiente.valori,
                                   valoriCampagna: ambiente.valoriCampagna),
            valoriCampagna: ambiente.valoriCampagna)
        return (ambiente, banco, ambiente.valoriCampagna)
    }

    /// Gioca UNA sessione attraverso la schermata e restituisce l'impronta finale,
    /// il numero di ordini impartiti e i rifiuti annunciati.
    private func giocaPerInterfaccia(
        _ configurazione: BancoSessioniCampagna.Configurazione, ambiente: WarSense.Ambiente
    ) async throws -> (impronta: String, ordini: Int, rifiuti: [String]) {
        let partita = try await PartitaCampagna(nuova: ambiente,
                                                scenario: configurazione.scenario)
        let schermata = SchermataMappaCampagna(partita: partita)
        let finestra = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        defer {
            schermata.presentedViewController?.dismiss(animated: false)
            finestra.isHidden = true
            finestra.rootViewController = nil
        }
        try await attendi("caselle create") { !schermata.elementiPerProva.isEmpty }
        ambiente.segnali.azzeraAnnunciPronunciati()

        var ordini = 0
        let giornoIniziale = (await partita.stato).giorno
        while (await partita.stato).giorno < giornoIniziale + Self.giornatePerSessione {
            let stato = await partita.stato
            let vista = await partita.vista
            let improntaPrima = stato.impronta()
            // La condotta viene dal banco e non è riscritta qui: è lo stesso metodo
            // che il programma di verifica usa per giocare nel Motore. Ciò che
            // questa prova aggiunge è la TRADUZIONE dell'ordine in tocchi.
            guard let comando = BancoSessioniCampagna.prossimoOrdine(
                stato: stato, vista: vista, condotta: configurazione.condotta) else { break }

            switch comando {
            case .presidio(let id):
                let posizione = try XCTUnwrap(stato.gruppi[id]?.posizione)
                let cornice = VistaMappa.cornice(di: posizione)
                XCTAssertTrue(schermata.grigliaPerProva.attivaAlTocco(
                    in: CGPoint(x: cornice.midX, y: cornice.midY)),
                              "il dito non apre il pannello su \(posizione)")
                try await attendi("pannello aperto") {
                    schermata.presentedViewController is UIAlertController
                }
                let voce = try XCTUnwrap(schermata.vociPannelloPerProva.first {
                    $0.titolo == ambiente.testi.frase("pannello.presidio").testo
                }, "il pannello offre il presidio (01 §5.6.0.6)")
                // La sequenza reale del tocco (P5): l'avviso si congeda da sé e la
                // voce agisce a congedo avvenuto.
                schermata.presentedViewController?.dismiss(animated: false)
                try await attendi("congedo dell'avviso") {
                    schermata.presentedViewController == nil
                }
                voce.esegui()
            case .marcia(let id, let meta, _):
                schermata.avviaDesignazionePerProva(gruppo: id)
                let bersaglio = VistaMappa.cornice(di: meta)
                XCTAssertTrue(schermata.grigliaPerProva.attivaAlTocco(
                    in: CGPoint(x: bersaglio.midX, y: bersaglio.midY)),
                              "il dito non conferma la destinazione \(meta)")
            }
            ordini += 1
            try await attendi("ordine applicato") {
                schermata.statoPerProva?.impronta() != improntaPrima
            }
        }

        let terminiDiRifiuto = Set(MotivoNonValidoCampagna.allCases.map {
            ambiente.testi.termine($0.rawValue).testo
        })
        let rifiuti = ambiente.segnali.annunciPronunciati.map(\.testo)
            .filter { terminiDiRifiuto.contains($0) }
        return (await partita.stato.impronta(), ordini, rifiuti)
    }

    // MARK: - 00 §3.1 — ogni sessione generata, giocata al dito

    /// Tutte le configurazioni che il banco genera, giocate attraverso la schermata
    /// e confrontate con la corsa del Motore sulla stessa configurazione. Una
    /// divergenza significa che la Presentazione decide qualcosa (00 §3.2).
    func test_00_3_1_ogni_sessione_generata_giocata_al_dito_da_lo_stesso_stato() async throws {
        try await giocaTutte(gruppiMassimi: Self.gruppiMassimi)
    }

    private func giocaTutte(gruppiMassimi: Int) async throws {
        let (ambiente, banco, valoriCampagna) = try ambienteEBanco()
        let configurazioni = banco.configurazioni(
            mappe: valoriCampagna.mappe, formati: valoriCampagna.formatiMappa,
            gruppiMassimi: gruppiMassimi)
        XCTAssertFalse(configurazioni.isEmpty, "il banco non genera alcuna configurazione")

        var giocate = 0
        var ordiniTotali = 0
        let avvio = Date()
        for configurazione in configurazioni {
            let dalDito = try await giocaPerInterfaccia(configurazione, ambiente: ambiente)
            XCTAssertTrue(dalDito.rifiuti.isEmpty,
                          "\(configurazione.mappa)/\(configurazione.gruppi.count)/"
                          + "\(configurazione.disposizione.rawValue)/\(configurazione.condotta.rawValue): "
                          + "il gioco ha respinto \(dalDito.rifiuti.count) ordini")
            let dalMotore = try banco.gioca(mappa: configurazione.mappa,
                                            gruppi: configurazione.gruppi,
                                            disposizione: configurazione.disposizione,
                                            condotta: configurazione.condotta,
                                            giornate: Self.giornatePerSessione)
            XCTAssertEqual(dalDito.impronta, dalMotore.improntaFinale,
                           "\(configurazione.mappa) con \(configurazione.gruppi.count) gruppi, "
                           + "\(configurazione.disposizione.rawValue), \(configurazione.condotta.rawValue): "
                           + "la sessione giocata al dito e quella giocata nel Motore danno stati "
                           + "diversi (00 §3.1, §3.2). Ordini al dito: \(dalDito.ordini), "
                           + "nel Motore: \(dalMotore.ordini)")
            XCTAssertEqual(dalDito.ordini, dalMotore.ordini,
                           "\(configurazione.mappa): numero di ordini diverso fra i due percorsi")
            giocate += 1
            ordiniTotali += dalDito.ordini
        }
        let durata = Date().timeIntervalSince(avvio)
        // I numeri della misura li stampa la prova, così che il resoconto li copi
        // invece di contarli (RDA-71).
        print("MISURA sessioni per interfaccia: giocate=\(giocate) su \(configurazioni.count) "
              + "generate, ordini=\(ordiniTotali), durata=\(String(format: "%.1f", durata))s, "
              + "per sessione=\(String(format: "%.3f", durata / Double(max(giocate, 1))))s, "
              + "per ordine=\(String(format: "%.4f", durata / Double(max(ordiniTotali, 1))))s")
        XCTAssertEqual(giocate, configurazioni.count,
                       "non tutte le configurazioni generate sono passate per l'interfaccia")
    }

    /// Il tetto dei gruppi: lo stesso del programma di verifica fuori dal fumo, così
    /// che le due liste coincidano. Numero di struttura della misura (05 §0.4).
    private static let gruppiMassimi = 12
}
