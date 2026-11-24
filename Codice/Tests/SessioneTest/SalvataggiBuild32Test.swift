import XCTest
import Sessione
import Motore
import Dati
import Contenuti

/// LE PARTITE SALVATE CON LA BUILD 32 SI RIAPRONO (00 §15; incarico 32). La build 33 porta i valori alla
/// 0.16.0: la presa del quartier generale, la casella d'arrivo dalla patria, il budget del primo turno, le
/// unità evacuate che tornano. Una campagna nata prima non dichiara regole e continua com'era; un regno
/// continua, e la sua PROSSIMA campagna nasce con le regole nuove; uno scontro si riapre, e quello che un
/// difetto aveva chiuso al primo comando torna da giocare.
///
/// Le fixture sono i giornali scritti dal codice della build 32 (commit `06dee59`, valori 0.15.0) eseguendo
/// `CopioniBuild32`, con l'impronta che QUEL codice ha calcolato e l'ultima istantanea che ha scattato. Non si
/// rigenerano col codice di oggi.
final class SalvataggiBuild32Test: XCTestCase {

    private static func fixture(_ nome: String) -> URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent(nome)
    }
    static let campagna = fixture("SalvataggioCampagnaBuild32")
    static let regno = fixture("SalvataggioRegnoBuild32")
    static let inRitirata = fixture("SalvataggioBattagliaBuild32InRitirata")
    static let inCorso = fixture("SalvataggioBattagliaBuild32InCorso")
    static let chiusaAlPrimoComando = fixture("SalvataggioBattagliaBuild32ChiusaAlPrimoComando")

    private var valori: ValoriDiGioco!
    private var valoriCampagna: ValoriCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
    }

    // MARK: - Attrezzi

    /// Copia una fixture in uno slot di lavoro, come un salvataggio trovato sull'apparecchio: con le
    /// istantanee o senza.
    private func slot(_ fixture: URL, istantanee: Bool) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("build-32-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        try FileManager.default.copyItem(at: fixture, to: url)
        if !istantanee {
            for caso in FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
            where caso.lastPathComponent.hasPrefix("istantanea-") { try FileManager.default.removeItem(at: caso) }
        }
        return url
    }

    private func impronta(_ fixture: URL) throws -> String {
        try String(contentsOf: fixture.appendingPathComponent("impronta.txt"), encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func righe(_ url: URL) throws -> [String] {
        try String(contentsOf: url.appendingPathComponent("giornale.jsonl"), encoding: .utf8).split(separator: "\n").map(String.init)
    }

    private func riprendiRegno(_ cartella: URL) throws -> SessioneRegno {
        try SessioneRegno(riprendi: cartella, valori: try CopioniBuild32.valoriRegno(valori), versioneValori: valori.versioneEffettiva,
                          versioniCompatibili: valori.versioniCompatibili)
    }

    private func riprendiCampagna(_ cartella: URL) throws -> SessioneCampagna {
        try SessioneCampagna(riprendi: cartella, valori: valori, valoriCampagna: valoriCampagna)
    }

    // MARK: - Le versioni

    func test_incarico_32_i_valori_sono_alla_0_16_0_con_la_0_15_0_fra_le_compatibili() throws {
        XCTAssertEqual(valori.versione, "0.16.0")
        XCTAssertEqual(valori.versioneEffettiva, "0.16.0", "la fabbrica coincide con le proprie impronte")
        XCTAssertTrue(valori.versioniCompatibili.contains(CopioniBuild32.versione))
        XCTAssertFalse(valori.versioniCompatibili.contains("0.16.0"), "la versione corrente non si dichiara compatibile con sé stessa")
        XCTAssertEqual([Fondazione.schemaCorrente, FondazioneCampagna.schemaCorrente, FondazioneRegno.schemaCorrente], [2, 9, 2],
                       "gli schemi dei tre giornali non cambiano")
        for fixture in [Self.campagna, Self.regno, Self.regno.appendingPathComponent(SessioneRegno.cartellaCampagna),
                        Self.inRitirata, Self.inCorso, Self.chiusaAlPrimoComando] {
            XCTAssertTrue(try righe(fixture).first?.contains("\"versione_valori\":\"0.15.0\"") == true, fixture.path)
        }
    }

    func test_incarico_32_senza_la_0_15_0_fra_le_compatibili_le_partite_della_build_32_sarebbero_rifiutate() async throws {
        let copia = FileManager.default.temporaryDirectory.appendingPathComponent("valori-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: copia) }
        try FileManager.default.copyItem(at: Contenuti.valoriDiFabbrica, to: copia)
        let manifest = copia.appendingPathComponent("manifest.json")
        var oggetto = try XCTUnwrap(JSONSerialization.jsonObject(with: try Data(contentsOf: manifest)) as? [String: Any])
        oggetto["versioni_compatibili"] = (oggetto["versioni_compatibili"] as? [String])?.filter { $0 != CopioniBuild32.versione }
        try JSONSerialization.data(withJSONObject: oggetto).write(to: manifest)
        let senza = try CaricatoreValori.carica(da: copia)
        XCTAssertThrowsError(try SessioneCampagna(riprendi: try slot(Self.campagna, istantanee: true), valori: senza, valoriCampagna: valoriCampagna))
        XCTAssertThrowsError(try SessioneBattaglia(riprendi: try slot(Self.inCorso, istantanee: true), valori: senza))
        XCTAssertThrowsError(try SessioneRegno(riprendi: try slot(Self.regno, istantanee: true), valori: try CopioniBuild32.valoriRegno(valori),
                                               versioneValori: senza.versioneEffettiva, versioniCompatibili: senza.versioniCompatibili))
    }

    // MARK: - La campagna di prova

    func test_incarico_32_una_campagna_di_prova_della_build_32_si_riapre_com_era_e_continua() async throws {
        for istantanee in [true, false] {
            let cartella = try slot(Self.campagna, istantanee: istantanee)
            let prima = try Data(contentsOf: cartella.appendingPathComponent("giornale.jsonl"))
            let sessione = try riprendiCampagna(cartella)
            let impronta = await sessione.impronta()
            XCTAssertEqual(impronta, try self.impronta(Self.campagna), "istantanee \(istantanee)")
            XCTAssertEqual(try Data(contentsOf: cartella.appendingPathComponent("giornale.jsonl")), prima, "riaprire non riscrive")
            let stato = await sessione.stato
            XCTAssertNil(stato.regole, "una campagna di prova non dichiara regole")
            XCTAssertNil(stato.occupazioni)
            try await CopioniBuild32.chiudi(2, sessione)
            let dopo = await sessione.stato.giorno
            XCTAssertEqual(dopo, stato.giorno + 2)
        }
    }

    /// Le campagne di prova sono quelle della build 32: lo stesso copione, giocato oggi, scrive lo stesso
    /// giornale — la condotta dell'avversario compresa — e arriva alla stessa impronta. Cambia soltanto la
    /// versione dei valori nell'atto di fondazione.
    func test_incarico_32_il_copione_di_campagna_giocato_oggi_da_il_giornale_della_build_32() async throws {
        let cartella = FileManager.default.temporaryDirectory.appendingPathComponent("campagna-oggi-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: cartella) }
        let sessione = try await CopioniBuild32.campagna(in: cartella, valori: valori, valoriCampagna: valoriCampagna)
        let impronta = await sessione.impronta()
        XCTAssertEqual(impronta, try self.impronta(Self.campagna))
        let oggi = try righe(cartella), allora = try righe(Self.campagna)
        XCTAssertEqual(oggi.first?.replacingOccurrences(of: "\"versione_valori\":\"0.16.0\"", with: "\"versione_valori\":\"0.15.0\""), allora.first)
        XCTAssertEqual(Array(oggi.dropFirst()), Array(allora.dropFirst()))
    }

    // MARK: - Il regno

    /// Il regno della build 32, al secondo anno, con la campagna in corso: si riapre, la campagna continua
    /// con le regole con cui è nata — nessuna presa, e le reclute dove la regola di allora le aveva messe —,
    /// l'inverno la interrompe, e la campagna dell'anno dopo nasce con le regole nuove.
    func test_incarico_32_un_regno_della_build_32_si_riapre_e_la_prossima_campagna_ha_le_regole_nuove() async throws {
        for istantanee in [true, false] {
            let cartella = try slot(Self.regno, istantanee: istantanee)
            let prima = try Data(contentsOf: cartella.appendingPathComponent(SessioneRegno.nomeGiornale))
            let regno = try riprendiRegno(cartella)
            let improntaDelRegno = await regno.impronta()
            XCTAssertEqual(improntaDelRegno, try impronta(Self.regno), "istantanee \(istantanee)")
            XCTAssertEqual(try Data(contentsOf: cartella.appendingPathComponent(SessioneRegno.nomeGiornale)), prima)
            let cartellaCampagna = cartella.appendingPathComponent(SessioneRegno.cartellaCampagna)
            let campagna = try riprendiCampagna(cartellaCampagna)
            let improntaDellaCampagna = await campagna.impronta()
            XCTAssertEqual(improntaDellaCampagna, try impronta(Self.regno.appendingPathComponent(SessioneRegno.cartellaCampagna)),
                           "istantanee \(istantanee): la campagna in corso, con gli arrivi calcolati alla riapplicazione")
            var fronte = await campagna.stato
            XCTAssertEqual(fronte.calendario?.anno, 2)
            XCTAssertNil(fronte.regole, "la campagna nata con la build 32 non conosce la presa")
            let arrivi = fronte.registro.compactMap { voce -> Cella? in
                if case .arrivoDallaPatria(_, let casella) = voce.fatto { return casella } else { return nil }
            }
            XCTAssertEqual(arrivi.count, 2, "la leva della primavera e quella dell'estate")

            // Fino all'inverno, con le regole di allora.
            try await CopioniBuild32.chiudi(200, campagna)
            fronte = await campagna.stato
            XCTAssertEqual(fronte.conclusione?.modo, .inverno)
            XCTAssertNil(fronte.occupazioni)
            XCTAssertNil(fronte.quartieriGeneraliPresi)
            let ricevuti = try await regno.riceviEsito(dalla: fronte)
            XCTAssertNotNil(ricevuti, "l'esito torna in patria")
            let inverno = try await regno.esegui(.attendiInverno)
            XCTAssertTrue(inverno.esito.eValido)
            while await regno.stato.momento.eInverno {
                let passo = try await regno.esegui(.prosegui)
                XCTAssertTrue(passo.esito.eValido)
            }
            // Il terzo anno: la campagna nuova dichiara le regole della build 33.
            let aperta = try await regno.apriCampagna(
                fronte: "guado", scenarioDelFronte: try CopioniBuild32.scenario("campagna_piccola"), valori: valori,
                valoriCampagna: valoriCampagna, versioneTesti: "0.1.1", cartellaDelRegno: cartella, seme: 33, identificatore: "terza")
            let terza = try XCTUnwrap(aperta.campagna)
            let regole = await terza.stato.regole
            XCTAssertEqual(regole, RegoleDiCampagna(giornatePerLaPresa: valoriCampagna.presa.giornateDiOccupazione))
        }
    }

    // MARK: - Le battaglie

    func test_incarico_32_uno_scontro_in_corso_della_build_32_si_riapre_com_era() async throws {
        for istantanee in [true, false] {
            let sessione = try SessioneBattaglia(riprendi: try slot(Self.inCorso, istantanee: istantanee), valori: valori)
            let impronta = await sessione.impronta()
            XCTAssertEqual(impronta, try self.impronta(Self.inCorso), "istantanee \(istantanee)")
            let stato = await sessione.stato
            XCTAssertNil(stato.esito)
            XCTAssertNil(stato.sciamiEvacuati)
        }
    }

    /// Uno scontro lasciato a metà della ritirata: si riapre con chi è in campo com'era, e chi era già uscito
    /// è salvo con gli atomi che aveva, anche quando l'istantanea della build 32 ne conservava il solo numero.
    func test_incarico_32_uno_scontro_lasciato_in_ritirata_conserva_chi_era_gia_uscito() async throws {
        for istantanee in [true, false] {
            let cartella = try slot(Self.inRitirata, istantanee: istantanee)
            let sessione = try SessioneBattaglia(riprendi: cartella, valori: valori)
            let stato = await sessione.stato
            XCTAssertNil(stato.esito)
            XCTAssertEqual(stato.resaDichiarataDa, .giocatore)
            XCTAssertEqual(stato.evacuati[.giocatore], [IdSciame(1)])
            XCTAssertEqual(stato.sciamiEvacuati?.map(\.id), [IdSciame(1)], "istantanee \(istantanee)")
            XCTAssertEqual(stato.sciamiEvacuati?.first?.atomiIniziali, 6)
            XCTAssertTrue(stato.conosceGliEvacuati)
            XCTAssertEqual(stato.sciami.values.filter { $0.parte == .giocatore }.count, 2, "gli altri sono ancora in campo")
            // Senza la parte nuova lo stato è quello che la build 32 ha lasciato.
            var comAllora = stato
            comAllora.sciamiEvacuati = nil
            XCTAssertEqual(comAllora.impronta(), try self.impronta(Self.inRitirata), "istantanee \(istantanee)")
            XCTAssertFalse(comAllora.conosceGliEvacuati, "l'istantanea di allora non basta: si scala alla precedente")
        }
    }

    /// Il difetto del budget del primo turno (01 §9.3): la build 32 chiudeva questo scontro appena il
    /// giocatore sceglieva un reparto, e lo dava perso con le forze intatte. Riaperto, torna da giocare.
    func test_incarico_32_uno_scontro_che_la_build_32_chiudeva_al_primo_comando_torna_da_giocare() async throws {
        for istantanee in [true, false] {
            let sessione = try SessioneBattaglia(riprendi: try slot(Self.chiusaAlPrimoComando, istantanee: istantanee), valori: valori)
            var stato = await sessione.stato
            XCTAssertNil(stato.esito)
            XCTAssertNotEqual(stato.impronta(), try impronta(Self.chiusaAlPrimoComando), "allora era concluso")
            XCTAssertEqual(stato.parteDiTurno, .giocatore)
            let motore = MotoreBattaglia(valori: valori)
            let cella = try XCTUnwrap(stato.griglia.tutteLeCelle.first { motore.valida(.piazza(cella: $0), parte: .giocatore, stato: stato).eValido })
            let esito = try await sessione.esegui(.piazza(cella: cella), parte: .giocatore)
            XCTAssertTrue(esito.esito.eValido)
            stato = await sessione.stato
            XCTAssertNil(stato.esito)
            XCTAssertEqual(stato.sciami.count, 1)
        }
    }
}
