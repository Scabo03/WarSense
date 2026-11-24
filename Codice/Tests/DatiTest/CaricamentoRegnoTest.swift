import XCTest
@testable import Dati
import Contenuti

/// Il caricamento dei valori del regno (05 §7.8; incarico 30): la copia di fabbrica è valida, e
/// ogni copia incoerente è respinta con un rapporto a chiavi di testo, mai applicata in silenzio.
/// Dalla seconda tappa (incarico 31) il caricatore legge anche le durate delle voci, le linguette,
/// il mantenimento e la lista chiusa dei nomi, e verifica i miglioramenti contro `miglioramenti.json`.
final class CaricamentoRegnoTest: XCTestCase {

    private var archetipi: Set<IdentificatoreDati> = []
    private var miglioramenti: Set<IdentificatoreDati> = []

    override func setUpWithError() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        archetipi = Set(valori.archetipi.keys)
        miglioramenti = Set(valori.miglioramenti.keys)
    }

    private func diFabbrica() throws -> [String: Any] {
        let dati = try Data(contentsOf: Contenuti.valoriDiFabbrica.appendingPathComponent(CaricatoreRegno.nomeFile))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: dati) as? [String: Any])
    }

    /// La lista chiusa dei nomi che sta accanto a `regno.json` nella cartella di prova (incarico 31):
    /// il caricatore la legge dallo stesso posto, sicché una prova che scrive `regno.json` in una
    /// cartella temporanea deve mettervi anche quella.
    private enum FileDeiNomi {
        /// La copia di fabbrica, com'è.
        case diFabbrica
        /// Un contenuto scritto dalla prova, per guastarlo di proposito.
        case scritto(String)
        /// Nessun file.
        case assente
    }

    /// Scrive una copia modificata in una cartella temporanea e la carica.
    private func carica(nomi: FileDeiNomi = .diFabbrica,
                        _ modifica: (inout [String: Any]) -> Void) throws -> ValoriRegno {
        var copia = try diFabbrica()
        modifica(&copia)
        let cartella = FileManager.default.temporaryDirectory.appendingPathComponent("regno-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: cartella) }
        try JSONSerialization.data(withJSONObject: copia)
            .write(to: cartella.appendingPathComponent(CaricatoreRegno.nomeFile))
        let fileDeiNomi = cartella.appendingPathComponent(CaricatoreRegno.fileDeiNomi)
        switch nomi {
        case .diFabbrica:
            try FileManager.default.copyItem(
                at: Contenuti.valoriDiFabbrica.appendingPathComponent(CaricatoreRegno.fileDeiNomi), to: fileDeiNomi)
        case .scritto(let contenuto):
            try contenuto.write(to: fileDeiNomi, atomically: true, encoding: .utf8)
        case .assente:
            break
        }
        return try CaricatoreRegno.carica(da: cartella, archetipiNoti: archetipi, miglioramentiNoti: miglioramenti)
    }

    private func attendiRifiuto(chiave: String, voce: String? = nil, fileAtteso: String? = nil,
                                nomi: FileDeiNomi = .diFabbrica, file: StaticString = #filePath,
                                line: UInt = #line, _ modifica: (inout [String: Any]) -> Void) {
        XCTAssertThrowsError(try carica(nomi: nomi, modifica), file: file, line: line) { errore in
            let dati = errore as? ErroreDati
            XCTAssertEqual(dati?.chiave, chiave, file: file, line: line)
            if let voce { XCTAssertEqual(dati?.voce, voce, file: file, line: line) }
            if let fileAtteso { XCTAssertEqual(dati?.file, fileAtteso, file: file, line: line) }
        }
    }

    func test_la_copia_di_fabbrica_si_carica_ed_e_coerente() throws {
        let valori = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica, archetipiNoti: archetipi,
                                                miglioramentiNoti: miglioramenti)
        XCTAssertGreaterThanOrEqual(valori.giornatePerStagione, 1)
        XCTAssertEqual(valori.giornateOperative, valori.giornatePerStagione * 3,
                       "tre stagioni operative: primavera, estate, autunno (01 §5.9)")
        XCTAssertEqual(Set(valori.renditaAnnua.keys), Set(Risorsa.allCases.map(\.rawValue)),
                       "le risorse sono cinque e tutte dichiarate (01 §5.5.1)")
        XCTAssertFalse(valori.voci.isEmpty)
        XCTAssertFalse(valori.fronti.isEmpty)
        print("REGNO-VALORI giornate_per_stagione=\(valori.giornatePerStagione) voci=\(valori.voci.count) fronti=\(valori.fronti.count) formazioni_iniziali=\(valori.forzeIniziali.count)")
    }

    func test_01_5_5_1_una_risorsa_mancante_e_respinta() {
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "rendita_annua") {
            var rendita = $0["rendita_annua"] as! [String: Any]
            rendita.removeValue(forKey: "animali")
            $0["rendita_annua"] = rendita
        }
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "dotazione_iniziale") {
            var dotazione = $0["dotazione_iniziale"] as! [String: Any]
            dotazione["uomini"] = -1
            $0["dotazione_iniziale"] = dotazione
        }
    }

    func test_01_5_9_il_calendario_e_il_riporto_fuori_intervallo_sono_respinti() {
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "giornate_per_stagione") {
            $0["giornate_per_stagione"] = 0
        }
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "quota_riporto") {
            $0["quota_riporto"] = 1.5
        }
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "costo_minimo") {
            $0["costo_minimo"] = 0
        }
    }

    func test_05_7_7_un_gancio_ignoto_e_respinto() {
        attendiRifiuto(chiave: "errore.dati.file_malformato") {
            var voci = $0["voci"] as! [[String: Any]]
            voci[0]["effetto"] = ["gancio": "gancio_inesistente", "archetipo": "fanteria_leggera", "atomi": 6]
            $0["voci"] = voci
        }
    }

    func test_le_voci_incoerenti_sono_respinte() {
        // Un archetipo che non esiste.
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "leva_fanteria_leggera") {
            var voci = $0["voci"] as! [[String: Any]]
            voci[0]["effetto"] = ["gancio": "recluta_reparto", "archetipo": "archetipo_inesistente", "atomi": 6]
            $0["voci"] = voci
        }
        // Una voce che non costa nulla sarebbe il difetto sfruttabile di 00 §13.6.
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "leva_fanteria_leggera") {
            var voci = $0["voci"] as! [[String: Any]]
            voci[0]["pesi"] = [String: Any]()
            $0["voci"] = voci
        }
        // Un peso su una risorsa che non esiste.
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "leva_fanteria_leggera") {
            var voci = $0["voci"] as! [[String: Any]]
            voci[0]["pesi"] = ["denaro": 1, "risorsa_inesistente": 2]
            $0["voci"] = voci
        }
        // Due voci con lo stesso identificatore.
        attendiRifiuto(chiave: "errore.dati.identificatore_duplicato", voce: "leva_fanteria_leggera") {
            var voci = $0["voci"] as! [[String: Any]]
            voci.append(voci[0])
            $0["voci"] = voci
        }
    }

    func test_le_forze_iniziali_senza_formazione_armata_sono_respinte() {
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "forze_iniziali") {
            let forze = $0["forze_iniziali"] as! [[String: Any]]
            $0["forze_iniziali"] = forze.filter { ($0["categoria"] as? String) != "armato" }
        }
    }

    func test_il_file_mancante_e_dichiarato() {
        let vuota = FileManager.default.temporaryDirectory.appendingPathComponent("regno-vuoto-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: vuota, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: vuota) }
        XCTAssertThrowsError(try CaricatoreRegno.carica(da: vuota, archetipiNoti: archetipi,
                                                        miglioramentiNoti: miglioramenti)) {
            XCTAssertEqual(($0 as? ErroreDati)?.chiave, "errore.dati.file_mancante")
        }
    }

    // MARK: - Incarico 31: durate, linguette, mantenimento, miglioramenti, nomi

    /// La copia di fabbrica della seconda tappa: le durate delle voci, la scala che fa di una durata
    /// una stagione, le linguette, il mantenimento, e la lista chiusa dei nomi letta dal file che
    /// già la contiene.
    func test_incarico_31_la_copia_di_fabbrica_dichiara_durate_linguette_mantenimento_e_nomi() throws {
        let valori = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica, archetipiNoti: archetipi,
                                                miglioramentiNoti: miglioramenti)
        XCTAssertEqual(valori.stazioniPerStagione, 4)
        XCTAssertEqual(valori.voci.map(\.identificatore),
                       ["leva_fanteria_leggera", "leva_fanteria_pesante", "leva_cavalleria_manovrata",
                        "addestramento_mirato", "mantenimento_addestramento"])
        XCTAssertEqual(valori.voci.map(\.durata), [2, 4, 6, 1, 1])
        XCTAssertEqual(valori.voce("addestramento_mirato")?.effetto,
                       .miglioraReparto(miglioramento: "addestramento_mirato"))
        XCTAssertEqual(valori.voce("mantenimento_addestramento")?.effetto,
                       .mantieniMiglioramento(miglioramento: "addestramento_mirato"))
        XCTAssertEqual(valori.linguette.map(\.identificatore), ["lunghi", "medi", "brevi"])
        XCTAssertEqual(valori.linguette.map(\.durataMinima), [5, 3, 1])
        XCTAssertEqual(valori.mantenimento, ValoriMantenimento(quotaPerMisura: Scalato(millesimi: 400), quotaMinima: 1))
        XCTAssertEqual(valori.durataMassima, 13,
                       "una stazione più tre stagioni di quattro: ordinata all'ultima stazione matura con l'inverno")
        // I nomi sono quelli del fronte, nello stesso ordine: la lista esiste in un posto solo.
        let nomiDelFronte = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica).nomiGruppi
        XCTAssertEqual(valori.nomiDelleUnita, nomiDelFronte)
        XCTAssertGreaterThanOrEqual(valori.nomiDelleUnita.count, valori.forzeIniziali.count)
        XCTAssertEqual(Array(valori.nomiDelleUnita.prefix(5)), ["corvo", "lupo", "falco", "orso", "cervo"])
    }

    /// I ganci d'effetto sono un insieme chiuso di tre (05 §7.7): ciascuno dice se porta con sé la
    /// misura o se la prende da un bersaglio, e che cosa fa alle forze.
    func test_incarico_31_i_tre_ganci_dichiarano_misura_bersaglio_e_specie() throws {
        let recluta = EffettoMilitare.reclutaReparto(archetipo: "fanteria_leggera", atomi: 6)
        let migliora = EffettoMilitare.miglioraReparto(miglioramento: "addestramento_mirato")
        let mantiene = EffettoMilitare.mantieniMiglioramento(miglioramento: "addestramento_mirato")
        XCTAssertEqual(recluta.misuraPropria, 6)
        XCTAssertNil(migliora.misuraPropria)
        XCTAssertNil(mantiene.misuraPropria)
        XCTAssertFalse(recluta.richiedeBersaglio)
        XCTAssertTrue(migliora.richiedeBersaglio)
        XCTAssertTrue(mantiene.richiedeBersaglio)
        XCTAssertEqual(recluta.specie, .recluta)
        XCTAssertEqual(migliora.specie, .migliora("addestramento_mirato"))
        XCTAssertEqual(mantiene.specie, .mantiene("addestramento_mirato"))
        XCTAssertEqual([recluta, migliora, mantiene].map(\.gancio),
                       ["recluta_reparto", "migliora_reparto", "mantieni_miglioramento"])
        // La codifica è quella del file: il gancio e i suoi campi, e si rilegge uguale.
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = [.sortedKeys]
        XCTAssertEqual(String(data: try codificatore.encode(migliora), encoding: .utf8),
                       #"{"gancio":"migliora_reparto","miglioramento":"addestramento_mirato"}"#)
        for effetto in [recluta, migliora, mantiene] {
            XCTAssertEqual(try JSONDecoder().decode(EffettoMilitare.self, from: try codificatore.encode(effetto)), effetto)
        }
    }

    /// REGOLA E, le linguette (01 §5.9.1.3): le voci si ripartiscono per durata, le più lunghe per
    /// prime, e ogni voce cade in una linguetta e in una sola.
    func test_incarico_31_le_linguette_ordinano_le_voci_per_durata_e_ogni_voce_cade_in_una() throws {
        let valori = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica, archetipiNoti: archetipi,
                                                miglioramentiNoti: miglioramenti)
        let perLinguetta = valori.linguette.map { valori.voci(in: $0).map(\.identificatore) }
        XCTAssertEqual(perLinguetta, [["leva_cavalleria_manovrata"],
                                      ["leva_fanteria_pesante"],
                                      ["leva_fanteria_leggera", "addestramento_mirato", "mantenimento_addestramento"]])
        XCTAssertEqual(perLinguetta.flatMap { $0 }.sorted(), valori.voci.map(\.identificatore).sorted(),
                       "ogni voce cade in una linguetta, e in una sola")
        for (indice, linguetta) in valori.linguette.enumerated() {
            for voce in valori.voci(in: linguetta) {
                XCTAssertEqual(valori.linguetta(di: voce), linguetta)
                XCTAssertGreaterThanOrEqual(voce.durata, linguetta.durataMinima)
                if indice > 0 { XCTAssertLessThan(voce.durata, valori.linguette[indice - 1].durataMinima) }
            }
            let durate = valori.voci(in: linguetta).map(\.durata)
            XCTAssertEqual(durate, durate.sorted(by: >), "dentro la linguetta, le più lunghe per prime")
        }
        XCTAssertEqual(valori.linguette.map(\.durataMinima), valori.linguette.map(\.durataMinima).sorted(by: >),
                       "le linguette stesse vanno dalla più lunga alla più breve")

        // Lo stesso su voci scritte qui in disordine: l'ordine dentro la linguetta è la durata, e a
        // parità di durata quello del file.
        let disordinate = try carica {
            var voci = $0["voci"] as! [[String: Any]]
            // Nell'ordine del file: leggera 1, pesante 13, cavalleria 3, poi i due miglioramenti (1 e 1).
            voci[0]["durata"] = 1
            voci[1]["durata"] = 13
            voci[2]["durata"] = 3
            $0["voci"] = voci
            $0["linguette"] = [["identificatore": "lunghi", "durata_minima": 3],
                               ["identificatore": "brevi", "durata_minima": 1]]
        }
        XCTAssertEqual(disordinate.linguette.map { disordinate.voci(in: $0).map(\.identificatore) },
                       [["leva_fanteria_pesante", "leva_cavalleria_manovrata"],
                        ["leva_fanteria_leggera", "addestramento_mirato", "mantenimento_addestramento"]])
    }

    /// REGOLA G: una voce con durata zero, negativa od oltre la massima è respinta. La massima è
    /// quella che, ordinata all'ultima stazione, matura con l'inverno successivo.
    func test_incarico_31_una_durata_nulla_od_oltre_la_massima_e_respinta() throws {
        for durata in [0, -1, 14, 99] {
            attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "leva_fanteria_pesante") {
                var voci = $0["voci"] as! [[String: Any]]
                voci[1]["durata"] = durata
                $0["voci"] = voci
            }
        }
        // I due estremi ammessi si caricano: il cancello rifiuta ciò che sta fuori, non il bordo.
        for durata in [1, 13] {
            let valori = try carica {
                var voci = $0["voci"] as! [[String: Any]]
                voci[1]["durata"] = durata
                $0["voci"] = voci
            }
            XCTAssertEqual(valori.voce("leva_fanteria_pesante")?.durata, durata)
        }
        // La massima segue la scala delle stagioni: con due stazioni per stagione è sette.
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "leva_cavalleria_manovrata") {
            $0["stazioni_per_stagione"] = 2
            var voci = $0["voci"] as! [[String: Any]]
            voci[2]["durata"] = 8
            $0["voci"] = voci
        }
        // Una voce senza durata non ha un valore sottinteso (00 §13.1): il file è malformato.
        attendiRifiuto(chiave: "errore.dati.file_malformato") {
            var voci = $0["voci"] as! [[String: Any]]
            voci[0].removeValue(forKey: "durata")
            $0["voci"] = voci
        }
        attendiRifiuto(chiave: "errore.dati.regno_incoerente") { $0["stazioni_per_stagione"] = 0 }
    }

    /// REGOLA G: ciò che agisce su un reparto esistente dura una stazione, né più né meno; il
    /// miglioramento che nomina deve esistere.
    func test_incarico_31_un_miglioramento_con_durata_diversa_da_uno_o_ignoto_e_respinto() {
        for (indice, identificatore) in [(3, "addestramento_mirato"), (4, "mantenimento_addestramento")] {
            for durata in [2, 5] {
                attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: identificatore) {
                    var voci = $0["voci"] as! [[String: Any]]
                    voci[indice]["durata"] = durata
                    $0["voci"] = voci
                }
            }
            attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: identificatore) {
                var voci = $0["voci"] as! [[String: Any]]
                var effetto = voci[indice]["effetto"] as! [String: Any]
                effetto["miglioramento"] = "miglioramento_inesistente"
                voci[indice]["effetto"] = effetto
                $0["voci"] = voci
            }
        }
        // Il gancio senza il proprio campo è un file malformato, come ogni gancio incompleto.
        attendiRifiuto(chiave: "errore.dati.file_malformato") {
            var voci = $0["voci"] as! [[String: Any]]
            voci[3]["effetto"] = ["gancio": "migliora_reparto"]
            $0["voci"] = voci
        }
    }

    /// REGOLA G: ogni miglioramento che si può dare si deve poter mantenere, e viceversa.
    func test_incarico_31_un_miglioramento_che_si_da_e_non_si_mantiene_o_viceversa_e_respinto() throws {
        // Si può dare e non mantenere: sarebbe permanente.
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "miglioramenti") {
            let voci = $0["voci"] as! [[String: Any]]
            $0["voci"] = voci.filter { ($0["identificatore"] as? String) != "mantenimento_addestramento" }
        }
        // Si può mantenere e non dare: la voce non avrebbe mai oggetto.
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "miglioramenti") {
            let voci = $0["voci"] as! [[String: Any]]
            $0["voci"] = voci.filter { ($0["identificatore"] as? String) != "addestramento_mirato" }
        }
        // Senza l'uno e senza l'altro il regno è coerente: le sole leve.
        let soloLeve = try carica {
            let voci = $0["voci"] as! [[String: Any]]
            $0["voci"] = Array(voci.prefix(3))
        }
        XCTAssertEqual(soloLeve.voci.count, 3)
    }

    /// REGOLA G: le linguette vuote, non decrescenti, o senza la soglia uno in coda sono respinte.
    func test_incarico_31_le_linguette_vuote_non_decrescenti_o_senza_soglia_uno_sono_respinte() throws {
        func linguette(_ soglie: [(String, Int)]) -> [[String: Any]] {
            soglie.map { ["identificatore": $0.0, "durata_minima": $0.1] }
        }
        // Vuote.
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "linguette") { $0["linguette"] = [[String: Any]]() }
        // Non decrescenti: crescenti, e a pari soglia.
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "linguette") {
            $0["linguette"] = linguette([("lunghi", 3), ("medi", 5), ("brevi", 1)])
        }
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "linguette") {
            $0["linguette"] = linguette([("lunghi", 5), ("medi", 5), ("brevi", 1)])
        }
        // Senza la soglia uno in coda: una voce di durata uno non cadrebbe in alcuna linguetta.
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "linguette") {
            $0["linguette"] = linguette([("lunghi", 5), ("medi", 3), ("brevi", 2)])
        }
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "linguette") {
            $0["linguette"] = linguette([("lunghi", 5), ("medi", 3), ("brevi", 0)])
        }
        // La soglia uno fuori dalla coda.
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "linguette") {
            $0["linguette"] = linguette([("brevi", 1), ("medi", 3), ("lunghi", 5)])
        }
        // Due linguette con lo stesso identificatore.
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "linguette") {
            $0["linguette"] = linguette([("lunghi", 5), ("lunghi", 3), ("brevi", 1)])
        }
        // Una sola linguetta, con la soglia uno, è coerente: contiene tutto.
        let una = try carica { $0["linguette"] = linguette([("brevi", 1)]) }
        XCTAssertEqual(una.voci(in: una.linguette[0]).count, una.voci.count)
        // Il campo mancante non ha un valore sottinteso.
        attendiRifiuto(chiave: "errore.dati.file_malformato") { $0.removeValue(forKey: "linguette") }
    }

    /// REGOLA G: il mantenimento con minimo zero è respinto (00 §13.6), e così la quota negativa.
    func test_incarico_31_il_mantenimento_con_minimo_zero_e_respinto() throws {
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "mantenimento") {
            $0["mantenimento"] = ["quota_per_misura": 0.4, "quota_minima": 0]
        }
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "mantenimento") {
            $0["mantenimento"] = ["quota_per_misura": 0.4, "quota_minima": -1]
        }
        attendiRifiuto(chiave: "errore.dati.regno_incoerente", voce: "mantenimento") {
            $0["mantenimento"] = ["quota_per_misura": -0.1, "quota_minima": 1]
        }
        attendiRifiuto(chiave: "errore.dati.file_malformato") { $0.removeValue(forKey: "mantenimento") }
        // La quota nulla col minimo uno è coerente: ogni reparto paga il minimo.
        let minima = try carica { $0["mantenimento"] = ["quota_per_misura": 0, "quota_minima": 1] }
        XCTAssertEqual(minima.mantenimento, ValoriMantenimento(quotaPerMisura: .zero, quotaMinima: 1))
    }

    /// La lista chiusa dei nomi (01 §5.6.0.4): mancante, malformata, con ripetizioni o più corta
    /// delle formazioni con cui il regno comincia, è dichiarata col nome del proprio file.
    func test_incarico_31_la_lista_dei_nomi_mancante_o_incoerente_e_respinta() throws {
        attendiRifiuto(chiave: "errore.dati.file_mancante", fileAtteso: CaricatoreRegno.fileDeiNomi, nomi: .assente) { _ in }
        attendiRifiuto(chiave: "errore.dati.file_malformato", fileAtteso: CaricatoreRegno.fileDeiNomi,
                       nomi: .scritto("non json")) { _ in }
        attendiRifiuto(chiave: "errore.dati.nomi_gruppi_incoerenti", fileAtteso: CaricatoreRegno.fileDeiNomi,
                       nomi: .scritto(#"{ "chiavi": ["corvo", "lupo", "falco", "orso", "cervo", "corvo"] }"#)) { _ in }
        // Cinque formazioni iniziali e quattro nomi: una nascerebbe senza nome.
        attendiRifiuto(chiave: "errore.dati.nomi_gruppi_incoerenti", fileAtteso: CaricatoreRegno.fileDeiNomi,
                       nomi: .scritto(#"{ "chiavi": ["corvo", "lupo", "falco", "orso"] }"#)) { _ in }
        let giusti = try carica(nomi: .scritto(#"{ "chiavi": ["corvo", "lupo", "falco", "orso", "cervo"] }"#)) { _ in }
        XCTAssertEqual(giusti.nomiDelleUnita, ["corvo", "lupo", "falco", "orso", "cervo"])
    }

    // MARK: - Incarico 31: `miglioramenti.json`

    private func copiaDeiValoriCon(miglioramenti contenuto: String?) throws -> URL {
        let copia = FileManager.default.temporaryDirectory
            .appendingPathComponent("valori-miglioramenti-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: Contenuti.valoriDiFabbrica, to: copia)
        addTeardownBlock { try? FileManager.default.removeItem(at: copia) }
        let url = copia.appendingPathComponent("miglioramenti.json")
        if let contenuto {
            try contenuto.write(to: url, atomically: true, encoding: .utf8)
        } else {
            try FileManager.default.removeItem(at: url)
        }
        return copia
    }

    func test_incarico_31_i_miglioramenti_di_fabbrica_si_caricano_e_non_peggiorano() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        XCTAssertEqual(Set(valori.miglioramenti.keys), ["addestramento_mirato"])
        for (chiave, miglioramento) in valori.miglioramenti {
            XCTAssertEqual(miglioramento.identificatore, chiave)
            XCTAssertGreaterThanOrEqual(miglioramento.capacitaOffensiva, .uno, "un miglioramento non peggiora")
        }
        XCTAssertGreaterThan(try XCTUnwrap(valori.miglioramenti["addestramento_mirato"]).capacitaOffensiva, .uno,
                             "l'addestramento mirato accresce davvero la capacità offensiva")
        // Ogni miglioramento che il regno dà o mantiene è definito qui.
        let regno = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica, archetipiNoti: archetipi,
                                               miglioramentiNoti: Set(valori.miglioramenti.keys))
        for voce in regno.voci {
            switch voce.effetto.specie {
            case .migliora(let chiave), .mantiene(let chiave): XCTAssertNotNil(valori.miglioramenti[chiave])
            case .recluta: break
            }
        }
    }

    /// REGOLA G: `miglioramenti.json` con un coefficiente sotto uno è respinto.
    func test_incarico_31_un_coefficiente_di_miglioramento_sotto_uno_e_respinto() throws {
        for coefficiente in ["0.999", "0.5", "0", "-1"] {
            let copia = try copiaDeiValoriCon(
                miglioramenti: #"[ {"identificatore":"addestramento_mirato","capacita_offensiva":\#(coefficiente)} ]"#)
            XCTAssertThrowsError(try CaricatoreValori.carica(da: copia), "coefficiente \(coefficiente)") { errore in
                let dati = errore as? ErroreDati
                XCTAssertEqual(dati?.chiave, "errore.dati.miglioramento_incoerente")
                XCTAssertEqual(dati?.file, "miglioramenti.json")
                XCTAssertEqual(dati?.voce, "addestramento_mirato")
            }
        }
        // Il coefficiente uno è il bordo ammesso: non accresce, ma non peggiora.
        let neutro = try CaricatoreValori.carica(da: try copiaDeiValoriCon(
            miglioramenti: #"[ {"identificatore":"addestramento_mirato","capacita_offensiva":1} ]"#))
        XCTAssertEqual(neutro.miglioramenti["addestramento_mirato"]?.capacitaOffensiva, .uno)
        XCTAssertTrue(neutro.modificatiLocalmente, "il file cambiato dà la versione locale derivata (RDA-45)")
    }

    func test_incarico_31_miglioramenti_duplicati_malformati_o_mancanti_sono_respinti() throws {
        let duplicati = try copiaDeiValoriCon(miglioramenti: """
        [ {"identificatore":"addestramento_mirato","capacita_offensiva":1.2},
          {"identificatore":"addestramento_mirato","capacita_offensiva":1.5} ]
        """)
        XCTAssertThrowsError(try CaricatoreValori.carica(da: duplicati)) { errore in
            XCTAssertEqual((errore as? ErroreDati)?.chiave, "errore.dati.identificatore_duplicato")
            XCTAssertEqual((errore as? ErroreDati)?.file, "miglioramenti.json")
        }
        let malformato = try copiaDeiValoriCon(miglioramenti: #"[ {"identificatore":"addestramento_mirato"} ]"#)
        XCTAssertThrowsError(try CaricatoreValori.carica(da: malformato)) { errore in
            XCTAssertEqual((errore as? ErroreDati)?.chiave, "errore.dati.file_malformato")
            XCTAssertEqual((errore as? ErroreDati)?.file, "miglioramenti.json")
        }
        let mancante = try copiaDeiValoriCon(miglioramenti: nil)
        XCTAssertThrowsError(try CaricatoreValori.carica(da: mancante)) { errore in
            XCTAssertEqual((errore as? ErroreDati)?.chiave, "errore.dati.file_mancante")
            XCTAssertEqual((errore as? ErroreDati)?.file, "miglioramenti.json")
        }
    }

    /// REGOLA H, la versione: la 0.14.0 — quella della build 31 — sta fra le compatibili, perché le
    /// battaglie e le campagne salvate con quella si riaprano. La versione corrente la pretende
    /// `SalvataggiBuild32Test` (incarico 32).
    func test_incarico_31_la_versione_0_14_0_e_fra_le_compatibili() throws {
        let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        XCTAssertEqual(valori.versioneEffettiva, valori.versione, "la fabbrica coincide con le proprie impronte")
        XCTAssertTrue(valori.versioniCompatibili.contains("0.14.0"))
        XCTAssertFalse(valori.versioniCompatibili.contains(valori.versione),
                       "la versione corrente non si dichiara compatibile con sé stessa")
    }

    /// Le chiavi di testo dei rifiuti nuovi esistono nella fabbrica dei testi (05 §7.8).
    func test_incarico_31_i_rifiuti_nuovi_hanno_la_propria_chiave_di_testo() throws {
        let testi = try Testi.carica(albero: Contenuti.testiDiFabbrica, lingua: "it")
        for chiave in ["errore.dati.regno_incoerente", "errore.dati.miglioramento_incoerente",
                       "errore.dati.nomi_gruppi_incoerenti", "errore.dati.identificatore_duplicato",
                       "errore.dati.file_mancante", "errore.dati.file_malformato"] {
            XCTAssertTrue(testi.esiste(chiave), "chiave mancante nei testi di fabbrica: \(chiave)")
        }
    }
}
