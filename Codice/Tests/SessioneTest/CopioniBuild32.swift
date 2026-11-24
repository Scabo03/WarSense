import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// I COPIONI DELLE PARTITE SALVATE CON LA BUILD 32 (00 §15; incarico 32). Usano soltanto ciò che esisteva
/// già in quel codice (commit `06dee59`, valori 0.15.0), perché lo stesso file, copiato nel pacchetto di
/// allora, ne scriva i giornali: così il confronto è fra due codici diversi e non di un codice con sé
/// stesso. `GeneraFixtureBuild32Test` li esegue e ne scrive i file quando la variabile d'ambiente
/// `WARSENSE_FIXTURE_BUILD_32` indica dove; le fixture NON si rigenerano col codice di oggi.
enum CopioniBuild32 {

    static let versione = "0.15.0"

    static func scenario(_ nome: String) throws -> ScenarioCampagna {
        let dati = try Data(contentsOf: Contenuti.valoriDiFabbrica.appendingPathComponent("scenari-campagna.json"))
        return try XCTUnwrap(try JSONDecoder().decode([String: ScenarioCampagna].self, from: dati)[nome])
    }

    static func valoriRegno(_ valori: ValoriDiGioco) throws -> ValoriRegno {
        try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica, archetipiNoti: Set(valori.archetipi.keys),
                                   miglioramentiNoti: Set(valori.miglioramenti.keys))
    }

    /// Chiude giornate, concludendo ogni battaglia che nasce con l'esito indicato: il giocatore perde il
    /// gruppo che combatte, l'avversario resta con ciò che aveva.
    static func chiudi(_ giornate: Int, _ campagna: SessioneCampagna) async throws {
        var fatte = 0
        while fatte < giornate, await campagna.stato.conclusione == nil {
            let stato = await campagna.stato
            if let battaglia = stato.battaglieInSospeso.first {
                let avversario = try XCTUnwrap(stato.gruppi[battaglia.gruppoAvversario])
                _ = try await campagna.concludiBattaglia(EsitoInCampagna(
                    identificatore: battaglia.identificatore, casella: battaglia.casella, sconfitto: .giocatore,
                    modo: .annientamento, gruppoGiocatore: battaglia.gruppoGiocatore,
                    gruppoAvversario: battaglia.gruppoAvversario, composizioneGiocatore: [],
                    composizioneAvversario: avversario.composizione, posizioneGiocatore: nil,
                    posizioneAvversario: battaglia.casella))
                continue
            }
            _ = try await campagna.chiudiGiornata()
            fatte += 1
        }
    }

    static func marcia(_ campagna: SessioneCampagna, _ nome: String, verso casella: Cella) async throws {
        let stato = await campagna.stato
        let gruppo = try XCTUnwrap(stato.gruppiOrdinati.first { $0.nome == nome && $0.parte == .giocatore }, "manca \(nome)")
        let vista = await campagna.vista(per: .giocatore)
        let comando = try XCTUnwrap(vista.comandoDiMarcia(per: gruppo.id, a: casella), "\(nome) non può marciare in \(casella)")
        let esito = try await campagna.esegui(comando, parte: .giocatore).esito
        XCTAssertTrue(esito.eValido, "marcia respinta: \(String(describing: esito.motivo))")
    }

    // MARK: - La campagna di prova

    /// La campagna di prova piccola: Lupo stacca un reparto, Falco esplora, Corvo va verso il nemico, e si
    /// chiudono otto giornate combattendo ciò che nasce.
    static func campagna(in cartella: URL, valori: ValoriDiGioco, valoriCampagna: ValoriCampagna) async throws -> SessioneCampagna {
        let sessione = try SessioneCampagna(nuova: try scenario("campagna_piccola"), valori: valori, valoriCampagna: valoriCampagna,
                                            versioneTesti: "0.1.1", cartella: cartella, seme: 32,
                                            identificatore: "campagna-build-32")
        func gruppo(_ nome: String) async throws -> IdGruppo {
            let stato = await sessione.stato
            return try XCTUnwrap(stato.gruppiOrdinati.first { $0.nome == nome }, "manca il gruppo \(nome)").id
        }
        func ordina(_ comando: ComandoCampagna) async throws {
            let esito = try await sessione.esegui(comando, parte: .giocatore).esito
            XCTAssertTrue(esito.eValido, "ordine respinto: \(comando), \(String(describing: esito.motivo))")
        }
        try await ordina(.divisione(gruppo: try await gruppo("lupo"), repartiStaccati: [1], a: Cella(riga: 3, colonna: 3)))
        try await ordina(.esplorazione(gruppo: try await gruppo("falco")))
        try await chiudi(1, sessione)
        try await marcia(sessione, "corvo", verso: Cella(riga: 3, colonna: 2))
        try await chiudi(2, sessione)
        if await sessione.stato.gruppiOrdinati.contains(where: { $0.nome == "corvo" }) {
            try await marcia(sessione, "corvo", verso: Cella(riga: 2, colonna: 2))
        }
        try await chiudi(5, sessione)
        return sessione
    }

    // MARK: - Il regno

    /// Il regno al secondo anno, con la campagna sul guado in corso d'estate: una leva leggera entrata con
    /// la primavera e una di cavalleria arrivata d'estate, a campagna aperta, con la regola di allora (la
    /// casella libera più vicina al quartier generale, senza riguardo al nemico).
    static func regno(in cartella: URL, valori: ValoriDiGioco, valoriCampagna: ValoriCampagna) async throws
        -> (regno: SessioneRegno, campagna: SessioneCampagna) {
        let valoriRegno = try valoriRegno(valori)
        let regno = try SessioneRegno(nuovo: valoriRegno, versioneValori: valori.versioneEffettiva, versioneTesti: "0.1.1",
                                      cartella: cartella, seme: 32, identificatore: "regno-build-32")
        func esegui(_ comando: ComandoRegno) async throws {
            let esito = try await regno.esegui(comando)
            XCTAssertTrue(esito.esito.eValido, "\(comando): \(String(describing: esito.esito.motivo))")
        }
        func apri() async throws -> SessioneCampagna {
            let anno = await regno.stato.anno
            let aperta = try await regno.apriCampagna(
                fronte: "guado", scenarioDelFronte: try scenario("campagna_piccola"), valori: valori,
                valoriCampagna: valoriCampagna, versioneTesti: "0.1.1", cartellaDelRegno: cartella, seme: 32,
                identificatore: "campagna-anno-\(anno)")
            return try XCTUnwrap(aperta.campagna, "\(String(describing: aperta.esito.motivo))")
        }
        // Il primo anno: la formazione non armata resta in patria, la campagna passa con l'inverno.
        try await esegui(.destina(unita: "orso", alFronte: false))
        var campagna = try await apri()
        try await chiudi(200, campagna)
        let finita = await campagna.stato
        XCTAssertNotNil(finita.conclusione)
        _ = try await regno.riceviEsito(dalla: finita)
        // L'inverno: una leva leggera, pronta in primavera, e una di cavalleria, pronta d'estate.
        try await esegui(.attendiInverno)
        try await esegui(.ordina(voce: "leva_fanteria_leggera", bersaglio: nil))
        try await esegui(.ordina(voce: "leva_cavalleria_manovrata", bersaglio: nil))
        while await regno.stato.momento.eInverno { try await esegui(.prosegui) }
        // Il secondo anno, fino al terzo giorno dell'estate.
        campagna = try await apri()
        try await chiudi(valoriRegno.giornatePerStagione + 2, campagna)
        return (regno, campagna)
    }

    // MARK: - Le battaglie

    private static func scontro(_ giocatore: [(String, Int64)], _ avversario: [(String, Int64)], in cartella: URL,
                                valori: ValoriDiGioco, nome: String) async throws -> SessioneBattaglia {
        func mazzo(_ elementi: [(String, Int64)]) -> [ScenarioBattaglia.ElementoScenario] {
            elementi.map { .init(archetipo: IdentificatoreDati(stringLiteral: $0.0), protezione: .antiSaturazione, atomi: $0.1, esemplari: 1) }
        }
        return try SessioneBattaglia(nuova: ScenarioBattaglia(
            formato: "cento", caratteristica: "campo_aperto", primoOccupante: .giocatore, imboscata: false,
            deckGiocatore: mazzo(giocatore), deckAvversario: mazzo(avversario), ufficialeAvversario: "ufficiale_prova"),
            valori: valori, versioneTesti: "0.1.1", cartella: cartella, seme: 32, identificatore: nome)
    }

    /// I due schieramenti entrano in campo e il giocatore, ferito, si ritira: il giornale si ferma con un
    /// reparto già evacuato e un altro ancora in campo.
    static func battagliaInRitirata(in cartella: URL, valori: ValoriDiGioco) async throws -> SessioneBattaglia {
        let sessione = try await scontro([("fanteria_leggera", 6), ("fanteria_leggera", 6), ("fanteria_leggera", 6)],
                                         [("fanteria_pesante", 8)], in: cartella, valori: valori, nome: "ritirata-build-32")
        let motore = MotoreBattaglia(valori: valori)
        let ufficiale = try XCTUnwrap(valori.ufficiali["ufficiale_prova"])
        let mio = TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .giocatore)
        let suo = TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .avversario)
        var passi = 0
        while await sessione.stato.esito == nil, passi < 400 {
            passi += 1
            let stato = await sessione.stato
            if stato.parteDiTurno == .avversario { _ = try await sessione.eseguiTurnoAvversario(suo); continue }
            if stato.resaDichiarataDa == nil, stato.giro >= 4, await sessione.anteprima(.dichiaraResa, parte: .giocatore).eValido {
                _ = try await sessione.esegui(.dichiaraResa, parte: .giocatore)
                continue
            }
            let comando = mio.prossimoComando(stato: stato)
            _ = try await sessione.esegui(comando, parte: .giocatore)
            if case .ritiraUnita = comando {
                // Uno è fuori; si chiude il turno, l'avversario svolge il suo, e il giornale si ferma lì.
                _ = try await sessione.esegui(.fineTurno, parte: .giocatore)
                _ = try await sessione.eseguiTurnoAvversario(suo)
                break
            }
        }
        return sessione
    }

    /// Lo scontro che la build 32 chiudeva al primo comando: i reparti del giocatore stanno fra il budget
    /// ordinario e quello del primo turno, e appena ne sceglie uno è annientato con le forze intatte.
    static func battagliaChiusaAlPrimoComando(in cartella: URL, valori: ValoriDiGioco) async throws -> SessioneBattaglia {
        let sessione = try await scontro([("fanteria_pesante", 24), ("cavalleria_manovrata", 12)], [("fanteria_leggera", 6)],
                                         in: cartella, valori: valori, nome: "primo-turno-build-32")
        _ = try await sessione.esegui(.seleziona(indiceDeck: 0), parte: .giocatore)
        return sessione
    }

    /// Uno scontro in corso, alla metà della mischia: nessuno evacuato.
    static func battagliaInCorso(in cartella: URL, valori: ValoriDiGioco) async throws -> SessioneBattaglia {
        let sessione = try await scontro([("fanteria_leggera", 18), ("fanteria_pesante", 8)],
                                         [("fanteria_leggera", 18), ("fanteria_pesante", 8)], in: cartella, valori: valori,
                                         nome: "in-corso-build-32")
        let motore = MotoreBattaglia(valori: valori)
        let ufficiale = try XCTUnwrap(valori.ufficiali["ufficiale_prova"])
        let mio = TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .giocatore)
        let suo = TatticoBattaglia(motore: motore, ufficiale: ufficiale, parte: .avversario)
        var passi = 0
        while await sessione.stato.esito == nil, await sessione.stato.giro < 8, passi < 2_000 {
            passi += 1
            let stato = await sessione.stato
            if stato.parteDiTurno == .avversario { _ = try await sessione.eseguiTurnoAvversario(suo); continue }
            _ = try await sessione.esegui(mio.prossimoComando(stato: stato), parte: .giocatore)
        }
        return sessione
    }
}

/// Scrive le fixture della build 32, quando si esegue nel pacchetto di quella build con la variabile
/// d'ambiente che indica la cartella; altrove è saltata.
final class GeneraFixtureBuild32Test: XCTestCase {
    func test_genera_le_fixture_della_build_32() async throws {
        guard let percorso = ProcessInfo.processInfo.environment["WARSENSE_FIXTURE_BUILD_32"] else {
            throw XCTSkip("si esegue soltanto nel pacchetto della build 32")
        }
        let base = URL(fileURLWithPath: percorso)
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        XCTAssertEqual(valori.versione, CopioniBuild32.versione, "le fixture si generano coi valori della build 32")
        let valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        func scrivi(_ impronta: String, in cartella: URL) throws {
            try (impronta + "\n").write(to: cartella.appendingPathComponent("impronta.txt"), atomically: true, encoding: .utf8)
        }
        let campagna = base.appendingPathComponent("SalvataggioCampagnaBuild32")
        let c = try await CopioniBuild32.campagna(in: campagna, valori: valori, valoriCampagna: valoriCampagna)
        try scrivi(await c.impronta(), in: campagna)
        let regno = base.appendingPathComponent("SalvataggioRegnoBuild32")
        let r = try await CopioniBuild32.regno(in: regno, valori: valori, valoriCampagna: valoriCampagna)
        try scrivi(await r.regno.impronta(), in: regno)
        try scrivi(await r.campagna.impronta(), in: regno.appendingPathComponent(SessioneRegno.cartellaCampagna))
        for (nome, gioca) in [("InRitirata", CopioniBuild32.battagliaInRitirata),
                              ("ChiusaAlPrimoComando", CopioniBuild32.battagliaChiusaAlPrimoComando),
                              ("InCorso", CopioniBuild32.battagliaInCorso)] {
            let cartella = base.appendingPathComponent("SalvataggioBattagliaBuild32\(nome)")
            let b = try await gioca(cartella, valori)
            try scrivi(await b.impronta(), in: cartella)
        }
    }
}
