import XCTest
import Dati
import Motore
import Sessione
@testable import WarSense

/// LA SECONDA TAPPA DEL REGNO attraverso l'interfaccia (incarico 31): le formazioni che il regno
/// conserva col loro nome, la scelta di chi parte e chi resta in patria, le reclute che dichiarano
/// dove e come entrano, il mantenimento che il gioco preleva e dichiara nella prima schermata
/// dell'inverno, lo scioglimento dei reparti reclutati per ultimi quando il denaro non basta, le voci
/// con durate diverse e gli arrivi a campagna aperta, l'addestramento mirato di un reparto esistente
/// e il suo mantenimento, il reparto migliorato sulla tessera del deck in battaglia.
///
/// Ogni prova legge la schermata come la percorre la voce, preme i comandi che il giocatore preme,
/// e ascolta ciò che il punto dei segnali pronuncia.
@MainActor
final class SecondaTappaDelRegnoTest: XCTestCase {

    private var finestre: [UIWindow] = []

    override func tearDown() async throws {
        for f in finestre {
            var presentata = f.rootViewController?.presentedViewController
            var catena: [UIViewController] = []
            while let p = presentata { catena.append(p); presentata = p.presentedViewController }
            for p in catena.reversed() { p.dismiss(animated: false) }
            f.isHidden = true
            f.rootViewController = nil
        }
        finestre = []
        try await super.tearDown()
    }

    @discardableResult
    private func monta(_ schermata: UIViewController) -> UIWindow {
        let finestra = UIWindow(frame: CGRect(x: 0, y: 0, width: 420, height: 912))
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        finestra.layoutIfNeeded()
        finestre.append(finestra)
        return finestra
    }

    private func attendi(_ che: String = "", _ condizione: () -> Bool, giri: Int = 500,
                         file: StaticString = #filePath, line: UInt = #line) async throws {
        for _ in 0..<giri where !condizione() { try await Task.sleep(nanoseconds: 20_000_000) }
        XCTAssertTrue(condizione(), "attesa scaduta: \(che)", file: file, line: line)
    }

    private func lettura(_ schermata: UIViewController) -> [String] {
        schermata.view.layoutIfNeeded()
        return LettoreAccessibilita.ordineDiLettura(radice: schermata.view as Any)
            .map { LettoreAccessibilita.etichetta(di: $0) }
    }

    private func elemento(prefisso: String, in schermata: UIViewController,
                          file: StaticString = #filePath, line: UInt = #line) throws -> NSObject {
        try XCTUnwrap(LettoreAccessibilita.ordineDiLettura(radice: schermata.view as Any)
            .first { LettoreAccessibilita.etichetta(di: $0).hasPrefix(prefisso) },
                      "manca un elemento che cominci con «\(prefisso)» in \(lettura(schermata))", file: file, line: line)
    }

    /// Preme il comando la cui etichetta comincia col prefisso dato.
    private func premi(_ prefisso: String, in schermata: UIViewController,
                       file: StaticString = #filePath, line: UInt = #line) throws {
        let pulsante = try XCTUnwrap(try elemento(prefisso: prefisso, in: schermata, file: file, line: line) as? UIControl,
                                     "«\(prefisso)» non è un comando", file: file, line: line)
        pulsante.sendActions(for: .touchUpInside)
    }

    private func riga(_ nome: String, in schermata: UIViewController) -> String {
        lettura(schermata).first { $0.hasPrefix(nome + ",") } ?? ""
    }

    /// L'ambiente con i valori del regno modificati per la via che il gioco dà a chi li mette a
    /// punto — il file nella cartella Documenti (00 §15.4) —, non per un canale di prova; la
    /// cartella si rimuove a fine prova, e il prossimo avvio la ricopia dalla fabbrica.
    private func ambiente(modificando modifica: (inout [String: Any]) -> Void) throws -> Ambiente {
        _ = try Ambiente()
        let url = Ambiente.cartellaValori.appendingPathComponent("regno.json")
        var valori = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        modifica(&valori)
        try JSONSerialization.data(withJSONObject: valori).write(to: url)
        addTeardownBlock { try? FileManager.default.removeItem(at: Ambiente.cartellaValori) }
        let ambiente = try Ambiente()
        XCTAssertFalse(ambiente.ripiegoSuFabbrica, "i valori modificati in Documenti si caricano")
        return ambiente
    }

    private func patria(_ ambiente: Ambiente? = nil) async throws -> (SchermataPatria, Ambiente) {
        let ambiente = try ambiente ?? Ambiente()
        let schermata = SchermataPatria(partita: try await PartitaRegno(nuovo: ambiente))
        monta(schermata)
        try await attendi("la patria si carica") { self.lettura(schermata).contains("Riserve") }
        return (schermata, ambiente)
    }

    /// Dall'inizio dell'inverno alla primavera: le tre schermate che restano e il congedo.
    private func finoAllaPrimavera(_ schermata: SchermataPatria, anno: Int, dallaStazione: Int = 1) async throws {
        if dallaStazione < 4 {
            for stazione in (dallaStazione + 1)...4 {
                try premi("Prosegui alla schermata \(stazione) di 4", in: schermata)
                try await attendi("si apre la schermata \(stazione)") {
                    self.lettura(schermata).contains("Anno \(anno), inverno, schermata \(stazione) di 4")
                }
            }
        }
        try premi("Prosegui alla primavera", in: schermata)
        try await attendi("comincia la primavera") { self.lettura(schermata).contains("Anno \(anno + 1), primavera") }
    }

    // MARK: - Chi parte e chi resta; i nomi (incarico 31, prima parte)

    func test_incarico_31_chi_parte_si_sceglie_in_patria_e_ogni_formazione_conserva_il_suo_nome() async throws {
        let ambiente = try ambiente { $0["giornate_per_stagione"] = 1 }
        let (schermata, _) = try await patria(ambiente)
        let cervoAlFronte = "Cervo, formazione non armata: 4 atomi di fanteria leggera. Parte per il fronte"
        let cervoInPatria = "Cervo, formazione non armata: 4 atomi di fanteria leggera. Resta in patria"
        XCTAssertEqual(riga("Cervo", in: schermata), cervoAlFronte)
        let comando = try elemento(prefisso: "Cervo,", in: schermata)
        XCTAssertTrue(comando is UIControl, "in primavera la riga di una formazione è un comando")
        XCTAssertEqual(comando.accessibilityHint, "Attiva per scegliere se parte per il fronte o resta in patria")

        // Attivata, la formazione resta in patria: la riga si aggiorna sul posto, il fuoco non si
        // muove (00 §11.3), e la conferma si sente.
        ambiente.segnali.azzeraAnnunciPronunciati()
        Fuoco.azzeraRegistro()
        try premi("Cervo,", in: schermata)
        try await attendi("Cervo resta in patria") { self.riga("Cervo", in: schermata) == cervoInPatria }
        XCTAssertTrue(try elemento(prefisso: "Cervo,", in: schermata) === comando, "l'elemento è lo stesso")
        XCTAssertEqual(Fuoco.registro, [])
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo), ["Cervo resta in patria."])
        // Riattivata, torna a partire.
        ambiente.segnali.azzeraAnnunciPronunciati()
        try premi("Cervo,", in: schermata)
        try await attendi("Cervo riparte") { self.riga("Cervo", in: schermata) == cervoAlFronte }
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo), ["Cervo parte per il fronte."])

        // Senza un gruppo armato che parta la campagna non si apre, e il gioco dice perché.
        for nome in ["Corvo", "Lupo", "Falco"] {
            try premi(nome + ",", in: schermata)
            try await attendi("\(nome) resta in patria") { self.riga(nome, in: schermata).hasSuffix("Resta in patria") }
        }
        ambiente.segnali.azzeraAnnunciPronunciati()
        await schermata.apriLaCampagnaPerProva(sul: "guado")
        XCTAssertNil(schermata.presentedViewController, "nessuna campagna senza un gruppo armato che parta")
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo), ["nessun gruppo armato da mandare"])

        // Partono Lupo, Falco e gli esploratori; Corvo e Cervo restano.
        for nome in ["Lupo", "Falco", "Cervo"] {
            try premi(nome + ",", in: schermata)
            let attesa = nome == "Cervo" ? "Resta in patria" : "Parte per il fronte"
            try await attendi("\(nome): \(attesa)") { self.riga(nome, in: schermata).hasSuffix(attesa) }
        }
        await schermata.apriLaCampagnaPerProva(sul: "guado")
        try await attendi("si entra nel fronte") { schermata.presentedViewController is SchermataMappaCampagna }
        let mappa = try XCTUnwrap(schermata.presentedViewController as? SchermataMappaCampagna)
        try await attendi("la mappa si carica") { !mappa.elementiPerProva.isEmpty }
        let sulFronte = try XCTUnwrap(mappa.statoPerProva)
        XCTAssertEqual(sulFronte.gruppiOrdinati.filter { $0.parte == .giocatore }.map(\.nome), ["lupo", "falco", "orso"],
                       "sul fronte i gruppi sono le formazioni partite, col nome che hanno in patria")
        XCTAssertEqual(Set(sulFronte.nomiRiservati ?? []).intersection(["corvo", "cervo"]), ["corvo", "cervo"],
                       "i nomi di chi è rimasto in patria sono riservati")
        XCTAssertTrue(Set(sulFronte.gruppi(di: .avversario).map(\.nome)).isDisjoint(with: ["corvo", "lupo", "falco", "orso", "cervo"]),
                      "l'avversario non porta mai un nome del regno")
        // Il nome che la casella annuncia è lo stesso che la patria elenca.
        let casellaDiLupo = try XCTUnwrap(sulFronte.gruppi(di: .giocatore).first { $0.nome == "lupo" }?.posizione)
        let annuncioDiLupo = LettoreAccessibilita.etichetta(di: try XCTUnwrap(mappa.elementiPerProva[casellaDiLupo]))
        XCTAssertTrue(annuncioDiLupo.contains("Lupo"), annuncioDiLupo)

        // L'anno si chiude con l'inverno (stagioni di una giornata): rientrano le tre formazioni partite.
        for giorno in 1...3 {
            mappa.chiudiGiornataPerProva()
            try await attendi("si chiude la giornata \(giorno)") {
                giorno < 3 ? mappa.statoPerProva?.giorno == giorno + 1 : mappa.statoPerProva?.conclusione != nil
            }
        }
        try await attendi("compare la dichiarazione di conclusione") { schermata.presentedViewController is SchermataResoconto }
        let dichiarazione = try XCTUnwrap(schermata.presentedViewController as? SchermataResoconto)
        dichiarazione.loadViewIfNeeded()
        XCTAssertTrue(lettura(dichiarazione).contains("Rientrano in patria: 3 formazioni"), "\(lettura(dichiarazione))")
        dichiarazione.chiudiTuttoPerProva()
        try await attendi("si torna in patria") { schermata.presentedViewController == nil }

        // In patria le cinque formazioni sono quelle di prima, con lo stesso nome, nello stesso
        // ordine, e la scelta di chi parte è rimasta. Fuori dalla primavera le righe sono testo.
        let attese = [
            "Corvo, gruppo armato: 6 atomi di fanteria leggera. Resta in patria",
            "Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante. Parte per il fronte",
            "Falco, gruppo armato: 24 atomi di fanteria pesante, 12 atomi di cavalleria manovrata. Parte per il fronte",
            "Orso, formazione di ricognizione: 3 atomi di fanteria leggera. Parte per il fronte",
            "Cervo, formazione non armata: 4 atomi di fanteria leggera. Resta in patria",
        ]
        func forze() -> [String] { lettura(schermata).filter { $0.contains(" atomi di ") && $0.contains(": ") && !$0.hasPrefix("Leva") } }
        XCTAssertEqual(forze(), attese)
        XCTAssertFalse(try elemento(prefisso: "Corvo,", in: schermata) is UIControl,
                       "a campagna condotta la scelta non ha oggetto: la riga è testo")

        // L'anno dopo: stessi nomi, stessa scelta.
        try premi("Attendi l'inverno", in: schermata)
        try await attendi("arriva l'inverno") { self.lettura(schermata).contains("Anno 1, inverno, schermata 1 di 4") }
        XCTAssertEqual(forze().filter { !$0.contains("Costa:") }, attese)
        try await finoAllaPrimavera(schermata, anno: 1)
        XCTAssertEqual(forze(), attese)
        XCTAssertTrue(try elemento(prefisso: "Corvo,", in: schermata) is UIControl)

        // La ripresa dal giornale dà lo stesso regno.
        let impronta = await schermata.partitaPerProva.stato.impronta()
        let ripreso = await (try PartitaRegno(riprendi: ambiente)).stato
        XCTAssertEqual(ripreso.impronta(), impronta)
    }

    // MARK: - Il mantenimento (01 §4.14.1.1; seconda parte)

    func test_incarico_31_se_il_denaro_non_basta_il_gioco_lo_dichiara_e_scioglie_gli_ultimi_reclutati() async throws {
        // Valori messi a punto per la prova: quota più alta e rendita più bassa, sicché al secondo
        // inverno il denaro non basti di tre monete, cioè della quota del reparto reclutato per ultimo.
        let ambiente = try ambiente { valori in
            valori["mantenimento"] = ["quota_per_misura": 0.6, "quota_minima": 1]
            var dotazione = valori["dotazione_iniziale"] as? [String: Any] ?? [:]
            dotazione["denaro"] = 60
            valori["dotazione_iniziale"] = dotazione
            var rendita = valori["rendita_annua"] as? [String: Any] ?? [:]
            rendita["denaro"] = 38
            valori["rendita_annua"] = rendita
        }
        let (schermata, _) = try await patria(ambiente)

        // Primo inverno: 60 + 38 = 98 monete; la quota è 41 (3 + 10 + 4 + 14 + 7 + 1 + 2), e basta.
        ambiente.segnali.azzeraAnnunciPronunciati()
        try premi("Attendi l'inverno", in: schermata)
        try await attendi("arriva l'inverno") { self.lettura(schermata).contains("Anno 1, inverno, schermata 1 di 4") }
        XCTAssertTrue(lettura(schermata).contains("Mantenimento dell'esercito, prelevato all'inizio dell'inverno: monete di bronzo 41"))
        XCTAssertTrue(lettura(schermata).contains("monete di bronzo: 57"))
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo), [
            "Comincia l'inverno dell'anno 1. Entrate: monete di bronzo 38, uomini 24, metalli 30, materiale da "
            + "costruzione 30, animali 12. Mantenimento dell'esercito: monete di bronzo 41."])
        // Una leva di fanteria leggera: le reclute formeranno Lince.
        try premi("Leva di fanteria leggera.", in: schermata)
        try await attendi("la leva è ordinata") { self.lettura(schermata).contains("monete di bronzo: 27") }
        try await finoAllaPrimavera(schermata, anno: 1)
        XCTAssertEqual(riga("Lince", in: schermata),
                       "Lince, gruppo armato, reclute dell'inverno: 6 atomi di fanteria leggera. Entra sul fronte in primavera, al quartier generale")

        // Secondo inverno, senza campagna: 3 monete riportate più 38 fanno 41; la quota sarebbe 44.
        ambiente.segnali.azzeraAnnunciPronunciati()
        Fuoco.azzeraRegistro()
        try premi("Attendi l'inverno", in: schermata)
        try await attendi("arriva il secondo inverno") { self.lettura(schermata).contains("Anno 2, inverno, schermata 1 di 4") }
        let letta = lettura(schermata)
        let dopoLeRiserve = try XCTUnwrap(letta.firstIndex(of: "animali: 13")).advanced(by: 1)
        XCTAssertEqual(Array(letta[dopoLeRiserve..<(dopoLeRiserve + 4)]), [
            "Mantenimento dell'esercito, prelevato all'inizio dell'inverno: monete di bronzo 41",
            "Il denaro non è bastato al mantenimento: sciolti per primi i reparti reclutati per ultimi",
            "Lince perde 6 atomi di fanteria leggera: reparto sciolto, il denaro non è bastato al mantenimento",
            "Forze",
        ], "la prima schermata dichiara il mantenimento subito dopo le riserve")
        XCTAssertTrue(letta.contains("monete di bronzo: 0"), "il denaro non scende sotto zero: \(letta)")
        XCTAssertEqual(riga("Lince", in: schermata), "", "la formazione rimasta senza reparti non esiste più")
        XCTAssertEqual(letta.filter { $0.contains(", gruppo armato") }.count, 3, "i reparti più anziani restano")
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo), [
            "Comincia l'inverno dell'anno 2. Entrate: monete di bronzo 38, uomini 24, metalli 30, materiale da "
            + "costruzione 30, animali 12. Mantenimento dell'esercito: monete di bronzo 41. Il denaro non basta al "
            + "mantenimento. Lince perde 6 atomi di fanteria leggera: reparto sciolto, il denaro non è bastato al mantenimento."])
        // Nella seconda schermata la dichiarazione non c'è più; il registro la conserva.
        try premi("Prosegui alla schermata 2 di 4", in: schermata)
        try await attendi("si apre la seconda schermata") { self.lettura(schermata).contains("Anno 2, inverno, schermata 2 di 4") }
        XCTAssertFalse(lettura(schermata).contains { $0.hasPrefix("Mantenimento dell'esercito, prelevato") })
        XCTAssertFalse(lettura(schermata).contains { $0.hasPrefix("Lince perde") })
        try premi("Registro della patria", in: schermata)
        let registro = try XCTUnwrap(schermata.presentedViewController as? SchermataRegistro)
        registro.loadViewIfNeeded()
        XCTAssertEqual(Array(lettura(registro).dropFirst().prefix(3)), [
            "Anno 2, inverno: Lince perde 6 atomi di fanteria leggera: reparto sciolto, il denaro non è bastato al mantenimento",
            "Anno 2, inverno: prelevato il mantenimento dell'esercito, monete di bronzo 41",
            "Anno 2, inverno: comincia l'inverno e arriva l'entrata dell'anno",
        ])
    }

    // MARK: - L'addestramento mirato e il suo mantenimento (01 §4.13, §4.14; terza parte)

    func test_incarico_31_l_addestramento_mirato_si_ordina_su_un_reparto_e_si_perde_se_non_lo_si_mantiene() async throws {
        let (schermata, ambiente) = try await patria()
        try premi("Attendi l'inverno", in: schermata)
        try await attendi("arriva l'inverno") { self.lettura(schermata).contains("Anno 1, inverno, schermata 1 di 4") }

        // La voce apre la scelta del reparto: ogni scelta dichiara il proprio costo sulla riserva.
        try premi("Addestramento mirato.", in: schermata)
        try await attendi("si apre la scelta del reparto") { schermata.presentedViewController is SchermataScelta }
        var scelta = try XCTUnwrap(schermata.presentedViewController as? SchermataScelta)
        scelta.loadViewIfNeeded()
        XCTAssertEqual(lettura(scelta), [
            "Addestramento mirato.",
            "Per quale reparto?",
            // Dodici monete e mezza per atomo, troncate (03 §4.4.3.1): più di qualunque leva. Le
            // scelte che il denaro non copre lo dicono prontamente (02 §8.7.1).
            "Corvo: 6 atomi di fanteria leggera. Costa: monete di bronzo 75 su 193.",
            "Lupo: 18 atomi di fanteria leggera. Non si può ordinare: mancano monete di bronzo. Costa: monete di bronzo 225 su 193.",
            "Lupo: 8 atomi di fanteria pesante. Costa: monete di bronzo 100 su 193.",
            "Falco: 24 atomi di fanteria pesante. Non si può ordinare: mancano monete di bronzo. Costa: monete di bronzo 300 su 193.",
            "Falco: 12 atomi di cavalleria manovrata. Costa: monete di bronzo 150 su 193.",
            "Orso: 3 atomi di fanteria leggera. Costa: monete di bronzo 37 su 193.",
            "Cervo: 4 atomi di fanteria leggera. Costa: monete di bronzo 50 su 193.",
            "Chiudi il pannello",
        ])
        // Il gesto di fuga esce senza ordinare nulla.
        XCTAssertTrue(scelta.accessibilityPerformEscape())
        try await attendi("la scelta si chiude") { schermata.presentedViewController == nil }
        XCTAssertTrue(lettura(schermata).contains("Nessun lavoro ordinato in questo inverno"))

        // Una scelta che il denaro non copre si può toccare, e il gioco dice che cosa manca.
        try premi("Addestramento mirato.", in: schermata)
        try await attendi("si riapre la scelta") { schermata.presentedViewController is SchermataScelta }
        scelta = try XCTUnwrap(schermata.presentedViewController as? SchermataScelta)
        scelta.loadViewIfNeeded()
        ambiente.segnali.azzeraAnnunciPronunciati()
        try premi("Falco: 24 atomi di fanteria pesante.", in: scelta)
        try await attendi("il rifiuto si annuncia") { !ambiente.segnali.annunciPronunciati.isEmpty }
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo), ["Non si può ordinare: mancano monete di bronzo."])
        XCTAssertTrue(lettura(schermata).contains("Nessun lavoro ordinato in questo inverno"), "un comando respinto non cambia nulla")
        XCTAssertTrue(lettura(schermata).contains("monete di bronzo: 193"))

        // Scelto il reparto, il lavoro è ordinato: l'annuncio dice per chi e quando sarà pronto.
        ambiente.segnali.azzeraAnnunciPronunciati()
        try premi("Addestramento mirato.", in: schermata)
        try await attendi("si riapre la scelta") { schermata.presentedViewController is SchermataScelta }
        scelta = try XCTUnwrap(schermata.presentedViewController as? SchermataScelta)
        scelta.loadViewIfNeeded()
        try premi("Lupo: 8 atomi di fanteria pesante.", in: scelta)
        try await attendi("il lavoro è ordinato") {
            self.lettura(schermata).contains("Addestramento mirato per 8 atomi di fanteria pesante di Lupo, pronto in primavera")
        }
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo),
                       ["Addestramento mirato ordinato per 8 atomi di fanteria pesante di Lupo: pronto in primavera."])
        XCTAssertTrue(lettura(schermata).contains("monete di bronzo: 93"))
        XCTAssertEqual(riga("Lupo", in: schermata),
                       "Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante, addestramento mirato in corso. Parte per il fronte")
        // Lo stesso reparto non si addestra due volte nello stesso inverno: non è più fra le scelte.
        try premi("Addestramento mirato.", in: schermata)
        try await attendi("si riapre la scelta") { schermata.presentedViewController is SchermataScelta }
        scelta = try XCTUnwrap(schermata.presentedViewController as? SchermataScelta)
        scelta.loadViewIfNeeded()
        XCTAssertFalse(lettura(scelta).contains { $0.hasPrefix("Lupo: 8 atomi di fanteria pesante") })
        XCTAssertEqual(scelta.pulsantiVoci.count, 6)
        try premi("Chiudi il pannello", in: scelta)
        try await attendi("la scelta si chiude") { schermata.presentedViewController == nil }

        // In primavera il reparto porta il miglioramento, e la primavera lo dice.
        ambiente.segnali.azzeraAnnunciPronunciati()
        try await finoAllaPrimavera(schermata, anno: 1)
        XCTAssertTrue(ambiente.segnali.annunciPronunciati.last?.testo
            .hasSuffix("Lupo ha ora 8 atomi di fanteria pesante con addestramento mirato.") ?? false,
                      "\(ambiente.segnali.annunciPronunciati.map(\.testo))")
        XCTAssertEqual(riga("Lupo", in: schermata),
                       "Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante con addestramento mirato. Parte per il fronte")

        // Il secondo inverno: il miglioramento va mantenuto, e la patria lo dice sul reparto.
        try premi("Attendi l'inverno", in: schermata)
        try await attendi("arriva il secondo inverno") { self.lettura(schermata).contains("Anno 2, inverno, schermata 1 di 4") }
        let daMantenere = "Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante con addestramento mirato, da mantenere entro l'inverno. Parte per il fronte"
        XCTAssertEqual(riga("Lupo", in: schermata), daMantenere)
        XCTAssertTrue(lettura(schermata).contains("Mantenimento dell'addestramento mirato. Si sceglie il reparto. Conserva il miglioramento del reparto per un altro anno, pronto in primavera."))
        try premi("Mantenimento dell'addestramento mirato.", in: schermata)
        try await attendi("si apre la scelta del mantenimento") { schermata.presentedViewController is SchermataScelta }
        scelta = try XCTUnwrap(schermata.presentedViewController as? SchermataScelta)
        scelta.loadViewIfNeeded()
        XCTAssertEqual(lettura(scelta), [
            "Mantenimento dell'addestramento mirato.",
            "Per quale reparto?",
            "Lupo: 8 atomi di fanteria pesante con addestramento mirato. Costa: monete di bronzo 8 su 193.",
            "Chiudi il pannello",
        ])
        ambiente.segnali.azzeraAnnunciPronunciati()
        try premi("Lupo: 8 atomi di fanteria pesante con addestramento mirato.", in: scelta)
        try await attendi("il mantenimento è pagato") { self.riga("Lupo", in: schermata).contains("mantenimento pagato") }
        XCTAssertEqual(riga("Lupo", in: schermata),
                       "Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante con addestramento mirato, mantenimento pagato. Parte per il fronte")
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo), [
            "Mantenimento dell'addestramento mirato ordinato per 8 atomi di fanteria pesante con addestramento mirato di Lupo: pronto in primavera."])

        // Chi non lo paga lo perde, e il reparto resta: la spesa annullata, la primavera lo toglie.
        try premi("Annulla l'ultima spesa", in: schermata)
        try await attendi("il mantenimento è annullato") { self.riga("Lupo", in: schermata) == daMantenere }
        ambiente.segnali.azzeraAnnunciPronunciati()
        try await finoAllaPrimavera(schermata, anno: 2)
        XCTAssertTrue(ambiente.segnali.annunciPronunciati.last?.testo
            .hasSuffix("Lupo ha 8 atomi di fanteria pesante senza più addestramento mirato, per mancato mantenimento.") ?? false,
                      "\(ambiente.segnali.annunciPronunciati.map(\.testo))")
        XCTAssertEqual(riga("Lupo", in: schermata),
                       "Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante. Parte per il fronte")
    }

    // MARK: - Le durate e gli arrivi a campagna aperta (01 §5.9.1.3–5.9.1.4, §5.2.1; terza parte)

    func test_incarico_31_le_reclute_ordinate_tardi_arrivano_al_quartier_generale_a_campagna_aperta() async throws {
        let ambiente = try ambiente { $0["giornate_per_stagione"] = 1 }
        let (schermata, _) = try await patria(ambiente)
        try premi("Attendi l'inverno", in: schermata)
        try await attendi("arriva l'inverno") { self.lettura(schermata).contains("Anno 1, inverno, schermata 1 di 4") }
        for stazione in 2...4 {
            try premi("Prosegui alla schermata \(stazione) di 4", in: schermata)
            try await attendi("si apre la schermata \(stazione)") {
                self.lettura(schermata).contains("Anno 1, inverno, schermata \(stazione) di 4")
            }
        }
        // Alla quarta schermata la leva di fanteria leggera dichiara che sarà pronta in estate.
        ambiente.segnali.azzeraAnnunciPronunciati()
        try premi("Leva di fanteria leggera.", in: schermata)
        try await attendi("la leva è ordinata") {
            self.lettura(schermata).contains("Leva di fanteria leggera, pronta in estate")
        }
        XCTAssertEqual(ambiente.segnali.annunciPronunciati.map(\.testo), ["Leva di fanteria leggera ordinata: pronta in estate."])
        ambiente.segnali.azzeraAnnunciPronunciati()
        try await finoAllaPrimavera(schermata, anno: 1, dallaStazione: 4)
        XCTAssertTrue(ambiente.segnali.annunciPronunciati.last?.testo.hasSuffix(
            "Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, e raggiunge il quartier generale in estate, a campagna aperta.") ?? false,
                      "\(ambiente.segnali.annunciPronunciati.map(\.testo))")
        XCTAssertEqual(riga("Lince", in: schermata),
                       "Lince, gruppo armato, reclute dell'inverno: 6 atomi di fanteria leggera. Raggiunge il quartier generale in estate, a campagna aperta")

        // La campagna del secondo anno: Lince non c'è alla prima giornata, arriva con l'estate.
        await schermata.apriLaCampagnaPerProva(sul: "guado")
        try await attendi("si entra nel fronte") { schermata.presentedViewController is SchermataMappaCampagna }
        let mappa = try XCTUnwrap(schermata.presentedViewController as? SchermataMappaCampagna)
        try await attendi("la mappa si carica") { !mappa.elementiPerProva.isEmpty }
        XCTAssertEqual(mappa.statoPerProva?.gruppi(di: .giocatore).count, 5)
        XCTAssertEqual(mappa.statoPerProva?.arriviInAttesa?.map(\.nome), ["lince"])
        ambiente.segnali.azzeraAnnunciPronunciati()
        mappa.chiudiGiornataPerProva()
        try await attendi("comincia l'estate") { mappa.statoPerProva?.giorno == 2 }
        let arrivata = try XCTUnwrap(mappa.statoPerProva?.gruppi(di: .giocatore).first { $0.nome == "lince" },
                                     "Lince è sul fronte con la prima giornata dell'estate")
        let quartierGenerale = try XCTUnwrap(mappa.statoPerProva?.mappa.quartierGenerale(di: .giocatore))
        let casella = arrivata.posizione
        XCTAssertLessThanOrEqual(abs(casella.riga - quartierGenerale.riga) + abs(casella.colonna - quartierGenerale.colonna), 2,
                                 "entra al quartier generale, o nella casella libera più vicina")
        XCTAssertEqual(mappa.statoPerProva?.gruppi.values.filter { $0.posizione == casella }.count, 1,
                       "la casella d'arrivo era libera")
        XCTAssertFalse(arrivata.haConclusoLaGiornata, "chi arriva attende una decisione")
        let annunci = ambiente.segnali.annunciPronunciati.map(\.testo)
        XCTAssertTrue(annunci.contains("Nuova stagione: estate"), "\(annunci)")
        let attesoAnnuncio = "Lince è arrivata dalla patria in riga \(casella.riga), casella \(casella.colonna)"
        XCTAssertTrue(annunci.contains(attesoAnnuncio), "\(annunci)")
        XCTAssertEqual(mappa.statoPerProva?.arriviInAttesa, [])
        // Il registro della campagna annota l'arrivo, con il luogo.
        mappa.apriRegistroPerProva()
        try await attendi("si apre il registro") { mappa.presentedViewController is SchermataRegistro }
        let registro = try XCTUnwrap(mappa.presentedViewController as? SchermataRegistro)
        registro.loadViewIfNeeded()
        XCTAssertTrue(lettura(registro).contains("Giorno 2: " + attesoAnnuncio), "\(lettura(registro))")
        registro.dismiss(animated: false)
        try await attendi("il registro si chiude") { mappa.presentedViewController == nil }

        // La campagna si chiude con l'inverno: rientrano in sei, e Lince è una formazione come le altre.
        for giorno in 2...3 {
            mappa.chiudiGiornataPerProva()
            try await attendi("si chiude la giornata \(giorno)") {
                giorno < 3 ? mappa.statoPerProva?.giorno == giorno + 1 : mappa.statoPerProva?.conclusione != nil
            }
        }
        try await attendi("compare la dichiarazione di conclusione") { schermata.presentedViewController is SchermataResoconto }
        let dichiarazione = try XCTUnwrap(schermata.presentedViewController as? SchermataResoconto)
        dichiarazione.loadViewIfNeeded()
        XCTAssertTrue(lettura(dichiarazione).contains("Rientrano in patria: 6 formazioni"), "\(lettura(dichiarazione))")
        dichiarazione.chiudiTuttoPerProva()
        try await attendi("si torna in patria") { schermata.presentedViewController == nil }
        XCTAssertEqual(riga("Lince", in: schermata), "Lince, gruppo armato: 6 atomi di fanteria leggera. Parte per il fronte")
    }

    // MARK: - Il reparto migliorato in battaglia (01 §4.13; terza parte)

    func test_incarico_31_il_reparto_migliorato_si_dichiara_sulla_mappa_e_sulla_tessera_del_deck_in_battaglia() async throws {
        let (schermata, ambiente) = try await patria()
        // Primo inverno, senza campagna: l'addestramento mirato alla cavalleria di Falco (150 monete:
        // i ventiquattro atomi di fanteria pesante ne costerebbero 300, più di ciò che c'è).
        try premi("Attendi l'inverno", in: schermata)
        try await attendi("arriva l'inverno") { self.lettura(schermata).contains("Anno 1, inverno, schermata 1 di 4") }
        try premi("Addestramento mirato.", in: schermata)
        try await attendi("si apre la scelta del reparto") { schermata.presentedViewController is SchermataScelta }
        let scelta = try XCTUnwrap(schermata.presentedViewController as? SchermataScelta)
        scelta.loadViewIfNeeded()
        try premi("Falco: 12 atomi di cavalleria manovrata.", in: scelta)
        try await attendi("il lavoro è ordinato") { self.riga("Falco", in: schermata).contains("addestramento mirato in corso") }
        try await finoAllaPrimavera(schermata, anno: 1)
        // Parte Falco soltanto fra gli armati, perché la prima battaglia sia sua.
        for nome in ["Corvo", "Lupo"] {
            try premi(nome + ",", in: schermata)
            try await attendi("\(nome) resta in patria") { self.riga(nome, in: schermata).hasSuffix("Resta in patria") }
        }
        await schermata.apriLaCampagnaPerProva(sul: "guado")
        try await attendi("si entra nel fronte") { schermata.presentedViewController is SchermataMappaCampagna }
        let mappa = try XCTUnwrap(schermata.presentedViewController as? SchermataMappaCampagna)
        try await attendi("la mappa si carica") { !mappa.elementiPerProva.isEmpty }
        let falco = try XCTUnwrap(mappa.statoPerProva?.gruppi(di: .giocatore).first { $0.nome == "falco" })
        XCTAssertEqual(falco.composizione.map(\.miglioramento), [nil, "addestramento_mirato"])
        // Sulla mappa la casella di Falco dichiara il reparto migliorato.
        let annuncio = LettoreAccessibilita.etichetta(di: try XCTUnwrap(mappa.elementiPerProva[falco.posizione]))
            + " " + (try XCTUnwrap(mappa.elementiPerProva[falco.posizione]).accessibilityValue ?? "")
        XCTAssertTrue(annuncio.contains("12 atomi di cavalleria manovrata con addestramento mirato"), annuncio)

        // Si marcia verso l'armato avversario più vicino finché una battaglia non è in sospeso.
        let motore = mappa.motorePerProva
        func dist(_ a: Cella, _ b: Cella) -> Int { abs(a.riga - b.riga) + abs(a.colonna - b.colonna) }
        var passi = 0
        while let s = mappa.statoPerProva, s.battaglieInSospeso.isEmpty, s.conclusione == nil {
            passi += 1
            guard passi < 2000 else { XCTFail("nessuna battaglia entro il giorno \(s.giorno)"); return }
            guard let g = s.gruppiInAttesa(di: .giocatore).first else {
                mappa.chiudiGiornataPerProva()
                try await Task.sleep(nanoseconds: 60_000_000)
                continue
            }
            func valido(_ c: ComandoCampagna) -> Bool { motore.valida(c, parte: .giocatore, stato: s).eValido }
            var ordine: ComandoCampagna = .sostaConRaccolta(gruppo: g.id)
            if valido(.presidio(gruppo: g.id)) { ordine = .presidio(gruppo: g.id) }
            if g.categoria.eArmata,
               let bersaglio = s.gruppi(di: .avversario).filter({ $0.categoria.eArmata })
                .min(by: { dist(g.posizione, $0.posizione) < dist(g.posizione, $1.posizione) }) {
                let dest = VistaCampagna(motore: motore, stato: s, parte: .giocatore).destinazioniValide(per: g.id)
                if let meta = dest.first(where: { $0 == bersaglio.posizione })
                    ?? dest.min(by: { dist($0, bersaglio.posizione) < dist($1, bersaglio.posizione) }) {
                    let marcia = ComandoCampagna.marcia(gruppo: g.id, a: meta,
                                                        giorni: motore.costoInGiorni(da: g.posizione, a: meta, stato: s))
                    if valido(marcia) { ordine = marcia }
                }
            }
            await mappa.eseguiPerProva(ordine)
        }
        let battaglia = try XCTUnwrap(mappa.statoPerProva?.battaglieInSospeso.first, "una battaglia è in sospeso")
        XCTAssertEqual(mappa.statoPerProva?.gruppi[battaglia.gruppoGiocatore]?.nome, "falco")

        // Aperta la battaglia dal pannello della casella, la tessera del reparto migliorato lo dichiara.
        XCTAssertTrue(mappa.attiva(battaglia.casella))
        try await Task.sleep(nanoseconds: 150_000_000)
        let apri = ambiente.testi.frase("pannello.apri_battaglia").testo
        try XCTUnwrap(mappa.vociPannelloPerProva.first { $0.titolo == apri }).esegui()
        try await attendi("si apre la battaglia") { mappa.presentedViewController is SchermataBattaglia }
        let campo = try XCTUnwrap(mappa.presentedViewController as? SchermataBattaglia)
        try await attendi("il campo si carica") { !campo.elementiPerProva.isEmpty && !campo.tesserePerProva.isEmpty }
        let tessere = campo.tesserePerProva.map {
            (LettoreAccessibilita.etichetta(di: $0), $0.accessibilityValue ?? "")
        }
        let migliorate = tessere.filter { $0.1.contains("addestramento mirato") }
        XCTAssertEqual(migliorate.count, 1, "una sola tessera porta il miglioramento: \(tessere)")
        XCTAssertTrue(migliorate.first?.0.lowercased().contains("cavalleria manovrata") ?? false, "\(tessere)")
        let statoBattaglia = await campo.partitaPerProva.stato
        XCTAssertEqual(statoBattaglia.deck[.giocatore]?.map(\.miglioramento), [nil, "addestramento_mirato"])

        // Combattuta la battaglia, i superstiti di quel reparto restano migliorati.
        _ = try await PassaggioBattagliaInterfacciaTest().combattiAConclusione(campo.partitaPerProva, ambiente: ambiente)
        try await attendi("compare il resoconto") { campo.presentedViewController is SchermataResoconto }
        try XCTUnwrap(campo.presentedViewController as? SchermataResoconto).chiudiTuttoPerProva()
        for _ in 0..<300 where mappa.presentedViewController != nil
            || mappa.statoPerProva?.battaglieInSospeso.isEmpty == false {
            if let caselle = mappa.caselleDiRipiegamentoPerProva, let prima = caselle.first { mappa.ripiegaPerProva(in: prima) }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        await mappa.ricaricaStatoPerProva()
        if let tornato = mappa.statoPerProva?.gruppi[battaglia.gruppoGiocatore] {
            let cavalleria = tornato.composizione.filter { $0.archetipo == "cavalleria_manovrata" }
            XCTAssertTrue(cavalleria.allSatisfy { $0.miglioramento == "addestramento_mirato" },
                          "i superstiti della cavalleria conservano l'addestramento: \(tornato.composizione)")
            XCTAssertTrue(tornato.composizione.filter { $0.archetipo != "cavalleria_manovrata" }
                .allSatisfy { $0.miglioramento == nil }, "e gli altri reparti non lo acquistano: \(tornato.composizione)")
        }
        print("REPARTO-MIGLIORATO-31 giorno=\(mappa.statoPerProva?.giorno ?? 0) tessere=\(tessere.map { $0.0 + " | " + $0.1 })")
    }
}
