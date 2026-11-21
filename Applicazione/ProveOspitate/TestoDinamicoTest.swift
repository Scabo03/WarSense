import XCTest
import Dati
import Motore
import Sessione
@testable import WarSense

/// La dimensione del testo segue quella scelta nelle impostazioni di sistema (02 §10.4, decisione del
/// titolare del 2026-11-21, incarico 29): una prova per ogni schermata, alla dimensione più grande
/// (`accessibilityExtraExtraExtraLarge`), confrontata con quella predefinita (`large`). Per ogni testo
/// della schermata: alla dimensione più grande il carattere è più grande; il testo segue i cambiamenti
/// a partita in corso (`adjustsFontForContentSizeCategory`); nessun testo si taglia; nessun controllo esce dal
/// bordo della schermata (`fuoriDalBordo`). Fanno eccezione,
/// dichiarata, le tessere del deck, le celle della griglia e le caselle della mappa (misure fisse per
/// ragioni di geometria): i loro testi non si contano. I pannelli sono avvisi di sistema: se ne
/// controlla soltanto la crescita del carattere.
@MainActor
final class TestoDinamicoTest: XCTestCase {

    private var finestre: [UIWindow] = []

    override func tearDown() async throws {
        for f in finestre {
            f.rootViewController?.presentedViewController?.dismiss(animated: false)
            f.isHidden = true
            f.rootViewController = nil
        }
        finestre = []
        try await super.tearDown()
    }

    private static let predefinita = UIContentSizeCategory.large
    private static let massima = UIContentSizeCategory.accessibilityExtraExtraExtraLarge

    private func monta(_ schermata: UIViewController, taglia: UIContentSizeCategory) -> UIWindow {
        let finestra = UIWindow(frame: CGRect(x: 0, y: 0, width: 420, height: 912))
        finestra.traitOverrides.preferredContentSizeCategory = taglia
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        finestra.layoutIfNeeded()
        finestre.append(finestra)
        return finestra
    }

    private func attendi(_ condizione: () -> Bool, giri: Int = 300) async throws {
        for _ in 0..<giri where !condizione() { try await Task.sleep(nanoseconds: 20_000_000) }
    }

    /// Un testo della schermata: dove sta, con che carattere, se segue la taglia, se è tagliato.
    struct Testo {
        let testo: String
        let punti: CGFloat
        let segue: Bool
        let tagliato: Bool
        let diSistema: Bool
    }

    /// I testi visibili della vista, eccezioni dichiarate escluse.
    static func testi(in radice: UIView, diSistema: Bool = false) -> [Testo] {
        var esito: [Testo] = []
        func scendi(_ vista: UIView) {
            guard !vista.isHidden, vista.alpha > 0.01 else { return }
            // Le eccezioni dichiarate di 02 §10.4: tessere del deck, celle della griglia, caselle della mappa.
            if vista is TesseraDeck || vista is VistaGriglia || vista is VistaMappa { return }
            if let etichetta = vista as? UILabel, let testo = etichetta.text, !testo.isEmpty,
               etichetta.bounds.width > 0 {
                // Tagliato in altezza (le righe che servono non entrano) o, su una riga sola, in larghezza.
                let necessaria = etichetta.sizeThatFits(CGSize(width: etichetta.bounds.width,
                                                               height: .greatestFiniteMagnitude)).height
                let libera = etichetta.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                           height: .greatestFiniteMagnitude)).width
                let tagliato = necessaria > etichetta.bounds.height + 1
                    || (etichetta.numberOfLines == 1 && !etichetta.adjustsFontSizeToFitWidth
                        && libera > etichetta.bounds.width + 1)
                esito.append(Testo(testo: testo, punti: etichetta.font.pointSize,
                                   segue: etichetta.adjustsFontForContentSizeCategory,
                                   tagliato: tagliato, diSistema: diSistema))
            }
            for sotto in vista.subviews { scendi(sotto) }
        }
        scendi(radice)
        return esito
    }

    /// I controlli che alla dimensione più grande escono dal bordo della schermata. Una leva di sistema ha
    /// misura propria: se la riga la comprime, la sua cornice si stringe ma la leva si disegna intera, oltre
    /// la cornice; per questo della leva si misura l'estensione naturale, non la cornice. Trovato dal vivo
    /// sull'iPhone (incarico 29, percorso a testo massimo): la leva «Suoni del gioco» oltre il bordo destro.
    /// Restano fuori le eccezioni dichiarate e ciò che sta in un contenitore che scorre in orizzontale.
    static func fuoriDalBordo(in radice: UIView) -> [String] {
        var esito: [String] = []
        let larghezza = radice.bounds.width
        func scendi(_ vista: UIView, scorreInOrizzontale: Bool) {
            guard !vista.isHidden, vista.alpha > 0.01 else { return }
            if vista is TesseraDeck || vista is VistaGriglia || vista is VistaMappa { return }
            var orizzontale = scorreInOrizzontale
            if let contenitore = vista as? UIScrollView,
               contenitore.contentSize.width > contenitore.bounds.width + 1 { orizzontale = true }
            if let controllo = vista as? UIControl, !orizzontale, controllo.bounds.width > 0 {
                let cornice = controllo.convert(controllo.bounds, to: radice)
                let estensione = controllo is UISwitch ? controllo.sizeThatFits(.zero).width : cornice.width
                if cornice.minX < -1 || cornice.minX + estensione > larghezza + 1 {
                    let nome = controllo.accessibilityLabel ?? String(describing: type(of: controllo))
                    esito.append("«\(nome)» esce dal bordo: da \(Int(cornice.minX)) a \(Int(cornice.minX + estensione)) punti su \(Int(larghezza))")
                }
            }
            for sotto in vista.subviews { scendi(sotto, scorreInOrizzontale: orizzontale) }
        }
        scendi(radice, scorreInOrizzontale: false)
        return esito
    }

    /// I difetti di una schermata: confronta i testi alle due taglie, per testo.
    static func difetti(_ nome: String, predefinita: [Testo], massima: [Testo]) -> [String] {
        var difetti: [String] = []
        if massima.isEmpty { difetti.append("\(nome): nessun testo trovato") }
        let perTesto = Dictionary(predefinita.map { ($0.testo, $0) }, uniquingKeysWith: { a, _ in a })
        for t in massima {
            if let base = perTesto[t.testo], t.punti <= base.punti {
                difetti.append("\(nome): «\(t.testo)» resta a \(t.punti) punti alla dimensione più grande (\(base.punti) alla predefinita)")
            }
            if !t.diSistema, !t.segue {
                difetti.append("\(nome): «\(t.testo)» non segue la taglia a partita in corso (adjustsFontForContentSizeCategory)")
            }
            if !t.diSistema, t.tagliato {
                difetti.append("\(nome): «\(t.testo)» è tagliato alla dimensione più grande")
            }
        }
        return difetti
    }

    /// Una schermata montata alle due taglie, costruita due volte dalla stessa fabbrica.
    private func confronta(_ nome: String, _ fabbrica: () async throws -> UIViewController,
                           pronta: (UIViewController) async throws -> Void = { _ in }) async throws -> [String] {
        var raccolti: [[Testo]] = []
        var fuori: [String] = []
        for taglia in [Self.predefinita, Self.massima] {
            let schermata = try await fabbrica()
            let finestra = monta(schermata, taglia: taglia)
            try await pronta(schermata)
            finestra.layoutIfNeeded()
            raccolti.append(Self.testi(in: schermata.view))
            if taglia == Self.massima { fuori = Self.fuoriDalBordo(in: schermata.view).map { "\(nome): \($0)" } }
        }
        return Self.difetti(nome, predefinita: raccolti[0], massima: raccolti[1]) + fuori
    }

    // MARK: - Una prova per ogni schermata

    func test_02_10_4_avvio() async throws {
        let ambiente = try Ambiente()
        let difetti = try await confronta("avvio", { SchermataAvvio(ambiente: ambiente) },
                                          pronta: { $0.viewWillAppear(false) })
        XCTAssertEqual(difetti, [], difetti.joined(separator: "\n"))
    }

    func test_02_10_4_impostazioni() async throws {
        let ambiente = try Ambiente()
        let difetti = try await confronta("impostazioni", { SchermataImpostazioni(ambiente: ambiente) })
        XCTAssertEqual(difetti, [], difetti.joined(separator: "\n"))
    }

    func test_02_10_4_apprendimento_dei_segnali() async throws {
        let ambiente = try Ambiente()
        let difetti = try await confronta("apprendimento", { SchermataApprendimento(ambiente: ambiente) })
        XCTAssertEqual(difetti, [], difetti.joined(separator: "\n"))
    }

    func test_02_10_4_resoconto() async throws {
        let ambiente = try Ambiente()
        let voci = ["Sconfitta: si è ritirato", "Durata: 7 turni", "Perdite tue: 600 punti su 600 impegnati"]
        let difetti = try await confronta("resoconto", { SchermataResoconto(voci: voci, testi: ambiente.testi) })
        XCTAssertEqual(difetti, [], difetti.joined(separator: "\n"))
    }

    func test_02_10_4_registro_con_voci_e_vuoto() async throws {
        let ambiente = try Ambiente()
        let voci = [SchermataRegistro.Voce(frase: "Giorno 3: battaglia vinta in riga 2, casella 2", luogo: Cella(riga: 2, colonna: 2)),
                    SchermataRegistro.Voce(frase: "Giorno 3: ordine annullato", luogo: nil)]
        var difetti = try await confronta("registro", { SchermataRegistro(voci: voci, testi: ambiente.testi) })
        difetti += try await confronta("registro vuoto", { SchermataRegistro(voci: [], testi: ambiente.testi) })
        XCTAssertEqual(difetti, [], difetti.joined(separator: "\n"))
    }

    func test_02_10_4_divisione() async throws {
        let ambiente = try Ambiente()
        let partita = try await PartitaCampagna(nuova: ambiente, taglia: .piccola)
        let stato = await partita.stato
        let gruppo = try XCTUnwrap(stato.gruppi(di: .giocatore).max { $0.composizione.count < $1.composizione.count })
        let difetti = try await confronta("divisione", {
            SchermataDivisione(gruppo: gruppo, destinazioni: [Cella(riga: 1, colonna: 1)], testi: ambiente.testi)
        })
        XCTAssertEqual(difetti, [], difetti.joined(separator: "\n"))
    }

    func test_02_10_4_battaglia_e_il_suo_pannello() async throws {
        let ambiente = try Ambiente()
        var difetti = try await confronta("battaglia", {
            SchermataBattaglia(partita: try await PartitaCorrente(nuova: ambiente))
        }, pronta: { s in
            let b = try XCTUnwrap(s as? SchermataBattaglia)
            try await self.attendi { !b.elementiPerProva.isEmpty }
        })
        // Il pannello di un proprio reparto (avviso di sistema): il carattere cresce.
        var pannelli: [[Testo]] = []
        for taglia in [Self.predefinita, Self.massima] {
            let schermata = SchermataBattaglia(partita: try await PartitaCorrente(nuova: ambiente))
            _ = monta(schermata, taglia: taglia)
            try await attendi { !schermata.elementiPerProva.isEmpty }
            let partita = schermata.partitaPerProva
            _ = try await partita.esegui(.seleziona(indiceDeck: 0))
            let stato = await partita.stato
            let cella = try XCTUnwrap(VistaBattaglia(motore: partita.motore, stato: stato, parte: .giocatore)
                .celleValidePerSelezione().first?.cella)
            _ = try await partita.esegui(.piazza(cella: cella))
            _ = try await partita.esegui(.deseleziona)
            try await Task.sleep(nanoseconds: 150_000_000)
            XCTAssertTrue(schermata.attiva(cella))
            try await attendi { schermata.presentedViewController is UIAlertController }
            let pannello = try XCTUnwrap(schermata.presentedViewController as? UIAlertController)
            pannello.view.layoutIfNeeded()
            pannelli.append(Self.testi(in: pannello.view, diSistema: true))
        }
        difetti += Self.difetti("pannello di battaglia", predefinita: pannelli[0], massima: pannelli[1])
        XCTAssertEqual(difetti, [], difetti.joined(separator: "\n"))
    }

    func test_02_10_4_mappa_e_il_suo_pannello() async throws {
        let ambiente = try Ambiente()
        var difetti = try await confronta("mappa", {
            SchermataMappaCampagna(partita: try await PartitaCampagna(nuova: ambiente, taglia: .piccola))
        }, pronta: { s in
            let m = try XCTUnwrap(s as? SchermataMappaCampagna)
            try await self.attendi { !m.elementiPerProva.isEmpty }
        })
        var pannelli: [[Testo]] = []
        for taglia in [Self.predefinita, Self.massima] {
            let schermata = SchermataMappaCampagna(partita: try await PartitaCampagna(nuova: ambiente, taglia: .piccola))
            _ = monta(schermata, taglia: taglia)
            try await attendi { !schermata.elementiPerProva.isEmpty }
            let gruppo = try XCTUnwrap(schermata.statoPerProva?.gruppiInAttesa(di: .giocatore).first)
            XCTAssertTrue(schermata.attiva(gruppo.posizione))
            try await attendi { schermata.presentedViewController is UIAlertController }
            let pannello = try XCTUnwrap(schermata.presentedViewController as? UIAlertController)
            pannello.view.layoutIfNeeded()
            pannelli.append(Self.testi(in: pannello.view, diSistema: true))
        }
        difetti += Self.difetti("pannello della mappa", predefinita: pannelli[0], massima: pannelli[1])
        XCTAssertEqual(difetti, [], difetti.joined(separator: "\n"))
    }
}
