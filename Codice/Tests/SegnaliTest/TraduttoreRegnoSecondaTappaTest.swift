import XCTest
import Segnali
import Motore
import Dati
import Contenuti

/// Le frasi della SECONDA TAPPA DEL REGNO (incarico 31): la riga di una formazione in patria, con
/// dove va e — per le reclute — dove e quando entra; il mantenimento e ciò che scioglie; i
/// miglioramenti dati, mantenuti e perduti; la scelta di chi parte; le voci che si ordinano su un
/// reparto; l'arrivo dalla patria sul fronte. Ogni fatto, ogni motivo, ogni linguetta e ogni
/// miglioramento ha la propria frase, e nessuna resta irrisolta. I testi attesi sono scritti per
/// esteso: sono ciò che il giocatore sente.
final class TraduttoreRegnoSecondaTappaTest: XCTestCase {

    var testi: Testi!
    var traduttore: TraduttoreEventiRegno!
    var valori: ValoriDiGioco!
    var valoriRegno: ValoriRegno!
    var motore: MotoreRegno!

    override func setUpWithError() throws {
        testi = try Testi.carica(albero: Contenuti.testiDiFabbrica, lingua: "it")
        traduttore = TraduttoreEventiRegno(testi: testi)
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriRegno = try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica,
                                                 archetipiNoti: Set(valori.archetipi.keys),
                                                 miglioramentiNoti: Set(valori.miglioramenti.keys))
        motore = MotoreRegno(valori: valoriRegno)
    }

    // MARK: - Attrezzi

    private func risolta(_ testo: String, _ che: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(testo.isEmpty, "\(che): frase vuota", file: file, line: line)
        XCTAssertFalse(testo.contains(Testi.segnaposto), "\(che): chiave irrisolta in «\(testo)»", file: file, line: line)
        XCTAssertFalse(testo.contains("%"), "\(che): segnaposto non riempito in «\(testo)»", file: file, line: line)
    }

    private func leggera(_ atomi: Int, leva: Int? = nil, migliorata: Bool = false) -> Reparto {
        Reparto(archetipo: "fanteria_leggera", atomi: atomi, miglioramento: migliorata ? "addestramento_mirato" : nil,
                leva: leva)
    }
    private func pesante(_ atomi: Int, leva: Int? = nil, migliorata: Bool = false) -> Reparto {
        Reparto(archetipo: "fanteria_pesante", atomi: atomi, miglioramento: migliorata ? "addestramento_mirato" : nil,
                leva: leva)
    }
    private func cavalleria(_ atomi: Int, leva: Int? = nil) -> Reparto {
        Reparto(archetipo: "cavalleria_manovrata", atomi: atomi, leva: leva)
    }

    /// Le forze di un regno al suo secondo anno: una formazione per ciascuno dei casi che la patria
    /// sa dire.
    private var forze: ForzeDelRegno {
        .sciami(formazioni: [
            FormazioneDelRegno(nome: "corvo", categoria: .armato, composizione: [leggera(6)]),
            FormazioneDelRegno(nome: "lupo", categoria: .armato, composizione: [leggera(18), pesante(8, migliorata: true)]),
            FormazioneDelRegno(nome: "orso", categoria: .ricognizione(competenza: 5), composizione: [leggera(3)]),
            FormazioneDelRegno(nome: "cervo", categoria: .nonArmata(carico: 4, sogliaProtezione: 2),
                               composizione: [leggera(4)], inPatria: true),
            FormazioneDelRegno(nome: "lince", categoria: .armato, composizione: [pesante(8, leva: 1), leggera(6, leva: 1)],
                               arrivo: .primavera),
            FormazioneDelRegno(nome: "aquila", categoria: .armato, composizione: [cavalleria(6, leva: 1)], arrivo: .estate),
            FormazioneDelRegno(nome: "volpe", categoria: .armato, composizione: [cavalleria(6, leva: 1)], arrivo: .inverno),
        ], prossimoNome: 8)
    }

    private func formazione(_ nome: String) throws -> FormazioneDelRegno {
        try XCTUnwrap(forze.formazioni.first { $0.nome == nome })
    }

    // MARK: - Ogni fatto, ogni motivo, ogni linguetta, ogni miglioramento ha la propria frase

    func test_incarico_31_ogni_fatto_della_patria_ha_la_propria_frase_risolta() {
        // Quattordici dall'incarico 31, più i tre modi nuovi in cui una campagna si conclude (incarico 32).
        XCTAssertEqual(FattoDiPatria.casiDiRiferimento.count, 17)
        var frasi = Set<String>()
        for fatto in FattoDiPatria.casiDiRiferimento {
            for stagione in Stagione.allCases {
                let frase = traduttore.voceDiRegistro(VoceRegistroPatria(numero: 0, anno: 4, stagione: stagione, fatto: fatto),
                                                      fase: valoriRegno.faseIniziale).testo
                risolta(frase, "\(fatto)")
                XCTAssertTrue(frase.hasPrefix("Anno 4, \(stagione.rawValue): "),
                              "la voce dichiara l'anno e la stagione: «\(frase)»")
                XCTAssertFalse(frase.hasSuffix("."), "la voce di registro non porta il punto finale: «\(frase)»")
            }
            frasi.insert(traduttore.voceDiRegistro(VoceRegistroPatria(numero: 0, anno: 4, stagione: .inverno, fatto: fatto),
                                                   fase: valoriRegno.faseIniziale).testo)
        }
        XCTAssertEqual(frasi.count, FattoDiPatria.casiDiRiferimento.count, "ogni fatto ha una frase propria, diversa dalle altre")
    }

    func test_incarico_31_ogni_motivo_del_regno_ha_la_propria_frase_risolta() {
        XCTAssertEqual(MotivoNonValidoRegno.casiDiRiferimento.count, 12)
        var frasi = Set<String>()
        for motivo in MotivoNonValidoRegno.casiDiRiferimento {
            XCTAssertTrue(testi.esiste(motivo.chiaveTesto, tavola: "Vocabolario"), "manca il termine \(motivo.chiaveTesto)")
            let frase = traduttore.motivo(motivo, fase: valoriRegno.faseIniziale).testo
            risolta(frase, "\(motivo)")
            frasi.insert(frase)
        }
        XCTAssertEqual(frasi.count, MotivoNonValidoRegno.casiDiRiferimento.count, "ogni motivo ha una frase propria")
        // I quattro motivi della seconda tappa, per esteso.
        XCTAssertEqual(traduttore.motivo(.unitaIgnota, fase: .arcaica).testo, "formazione non trovata")
        XCTAssertEqual(traduttore.motivo(.bersaglioMancante, fase: .arcaica).testo, "va scelto il reparto")
        XCTAssertEqual(traduttore.motivo(.bersaglioNonAmmesso, fase: .arcaica).testo,
                       "il reparto non può ricevere questo lavoro")
        XCTAssertEqual(traduttore.motivo(.giaOrdinato, fase: .arcaica).testo,
                       "per questo reparto c'è già un lavoro ordinato in questo inverno")
    }

    func test_incarico_31_ogni_linguetta_e_ogni_miglioramento_dei_valori_di_fabbrica_ha_il_proprio_testo() {
        XCTAssertEqual(valoriRegno.linguette.count, 3)
        for linguetta in valoriRegno.linguette {
            XCTAssertTrue(testi.esiste(TraduttoreEventiRegno.chiave(dellaLinguetta: linguetta.identificatore)),
                          "manca il titolo della linguetta \(linguetta.identificatore)")
            risolta(traduttore.linguetta(linguetta.identificatore), linguetta.identificatore)
        }
        XCTAssertEqual(valoriRegno.linguette.map { traduttore.linguetta($0.identificatore) },
                       ["Lavori lunghi", "Lavori di media durata", "Lavori brevi"])
        XCTAssertFalse(valori.miglioramenti.isEmpty)
        for chiave in valori.miglioramenti.keys.sorted() {
            XCTAssertTrue(testi.esiste(TraduttoreEventiRegno.chiave(delMiglioramento: chiave), tavola: "Vocabolario"),
                          "manca il termine del miglioramento \(chiave)")
            risolta(traduttore.miglioramento(chiave), chiave)
        }
        XCTAssertEqual(traduttore.miglioramento("addestramento_mirato"), "addestramento mirato")
        // Ogni miglioramento che una voce dà o mantiene ha il proprio termine, e ogni effetto la propria frase.
        for voce in valoriRegno.voci {
            risolta(traduttore.effetto(voce.effetto), voce.identificatore)
            switch voce.effetto.specie {
            case .migliora(let chiave), .mantiene(let chiave): risolta(traduttore.miglioramento(chiave), chiave)
            case .recluta: break
            }
        }
        XCTAssertEqual(traduttore.effetto(.miglioraReparto(miglioramento: "addestramento_mirato")),
                       "Accresce la capacità offensiva del reparto")
        XCTAssertEqual(traduttore.effetto(.mantieniMiglioramento(miglioramento: "addestramento_mirato")),
                       "Conserva il miglioramento del reparto per un altro anno")
        XCTAssertEqual(traduttore.effetto(.reclutaReparto(archetipo: "fanteria_leggera", atomi: 6)), "6 atomi")
        // Le due voci nuove hanno nome e genere: sono maschili, le leve femminili.
        XCTAssertEqual(traduttore.voce("addestramento_mirato").genere, .maschile)
        XCTAssertEqual(traduttore.voce("mantenimento_addestramento").genere, .maschile)
        XCTAssertEqual(traduttore.voce("leva_fanteria_leggera").genere, .femminile)
    }

    // MARK: - La riga di una formazione: i sei casi

    func test_incarico_31_la_riga_di_una_formazione_dice_il_nome_la_categoria_i_reparti_e_dove_va() throws {
        // 1. Al fronte.
        XCTAssertEqual(traduttore.formazione(try formazione("lupo")),
                       "Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante con addestramento mirato. "
                       + "Parte per il fronte")
        XCTAssertEqual(traduttore.formazione(try formazione("orso")),
                       "Orso, formazione di ricognizione: 3 atomi di fanteria leggera. Parte per il fronte")
        // 2. In patria.
        XCTAssertEqual(traduttore.formazione(try formazione("cervo")),
                       "Cervo, formazione non armata: 4 atomi di fanteria leggera. Resta in patria")
        // 3. Le reclute pronte in primavera.
        XCTAssertEqual(traduttore.formazione(try formazione("lince")),
                       "Lince, gruppo armato, reclute dell'inverno: 8 atomi di fanteria pesante, 6 atomi di fanteria leggera. "
                       + "Entra sul fronte in primavera, al quartier generale o nella casella libera più vicina")
        // 4. Le reclute che arrivano a campagna aperta: in estate, in autunno.
        XCTAssertEqual(traduttore.formazione(try formazione("aquila")),
                       "Aquila, gruppo armato, reclute dell'inverno: 6 atomi di cavalleria manovrata. "
                       + "Raggiunge il fronte in estate, a campagna aperta, al quartier generale o nella casella libera più vicina")
        var inAutunno = try formazione("aquila")
        inAutunno.arrivo = .autunno
        XCTAssertEqual(traduttore.formazione(inAutunno),
                       "Aquila, gruppo armato, reclute dell'inverno: 6 atomi di cavalleria manovrata. "
                       + "Raggiunge il fronte in autunno, a campagna aperta, al quartier generale o nella casella libera più vicina")
        // 5. Le reclute che maturano con l'inverno successivo.
        XCTAssertEqual(traduttore.formazione(try formazione("volpe")),
                       "Volpe, gruppo armato, reclute dell'inverno: 6 atomi di cavalleria manovrata. "
                       + "Arriva in patria con l'inverno")
        // 6. Le reclute che il giocatore tiene in patria: arrivano, e restano.
        var tenuta = try formazione("lince")
        tenuta.inPatria = true
        XCTAssertEqual(traduttore.formazione(tenuta),
                       "Lince, gruppo armato, reclute dell'inverno: 8 atomi di fanteria pesante, 6 atomi di fanteria leggera. "
                       + "Arriva in primavera e resta in patria")
        tenuta = try formazione("aquila")
        tenuta.inPatria = true
        XCTAssertEqual(traduttore.formazione(tenuta),
                       "Aquila, gruppo armato, reclute dell'inverno: 6 atomi di cavalleria manovrata. "
                       + "Arriva in estate e resta in patria")
        // Chi matura con l'inverno non parte comunque: la riga è la stessa, tenuta in patria o no.
        tenuta = try formazione("volpe")
        tenuta.inPatria = true
        XCTAssertEqual(traduttore.formazione(tenuta), traduttore.formazione(try formazione("volpe")))

        // Le sei righe sono sei frasi diverse, e nessuna resta irrisolta.
        let righe = traduttore.forze(forze)
        XCTAssertEqual(righe.map(\.unita), ["corvo", "lupo", "orso", "cervo", "lince", "aquila", "volpe"],
                       "una riga per formazione, nell'ordine in cui il regno le conserva")
        for riga in righe { risolta(riga.testo, riga.unita) }
        XCTAssertEqual(righe[0].testo, "Corvo, gruppo armato: 6 atomi di fanteria leggera. Parte per il fronte")
        XCTAssertEqual(Set(righe.map { $0.testo.components(separatedBy: ". ").last ?? "" }).count, 5,
                       "cinque destinazioni diverse fra le sette formazioni")
    }

    /// S29q, punto (d) (incarico 32): a campagna aperta la riga dice dov'è la formazione ADESSO, con i
    /// reparti che ha; il futuro resta soltanto a chi deve ancora arrivare.
    func test_02_6_5_4_5_a_campagna_aperta_la_riga_dice_dov_e_la_formazione() throws {
        let fronte = SituazioneDelFronte(
            sulFronte: ["lupo": .init(casella: Cella(riga: 2, colonna: 3), composizione: [leggera(10)]),
                        "lince": .init(casella: Cella(riga: 3, colonna: 1), composizione: [pesante(8), leggera(6)]),
                        "orso": .init(casella: Cella(riga: 4, colonna: 4), composizione: [leggera(3)])],
            inArrivo: ["aquila"])
        func riga(_ nome: IdentificatoreDati) throws -> String { traduttore.formazione(try formazione(nome), fronte: fronte) }
        // Partita: la casella, e i reparti che le restano.
        XCTAssertEqual(try riga("lupo"), "Lupo, gruppo armato: 10 atomi di fanteria leggera. Sul fronte, in riga 2, casella 3")
        XCTAssertEqual(try riga("orso"), "Orso, formazione di ricognizione: 3 atomi di fanteria leggera. Sul fronte, in riga 4, casella 4")
        // Le reclute già arrivate: non ne parla più al futuro, e dice la casella vera.
        XCTAssertEqual(try riga("lince"),
                       "Lince, gruppo armato: 8 atomi di fanteria pesante, 6 atomi di fanteria leggera. Sul fronte, in riga 3, casella 1")
        // Le reclute che devono ancora arrivare: il futuro è il loro.
        XCTAssertEqual(try riga("aquila"),
                       "Aquila, gruppo armato, reclute dell'inverno: 6 atomi di cavalleria manovrata. "
                       + "Raggiunge il fronte in estate, a campagna aperta, al quartier generale o nella casella libera più vicina")
        // Partita, e sul fronte non c'è più: distrutta, o riunita a un'altra.
        XCTAssertEqual(try riga("corvo"), "Corvo, gruppo armato. Non è più sul fronte")
        // Chi non è partito non cambia riga.
        XCTAssertEqual(try riga("cervo"), traduttore.formazione(try formazione("cervo")))
        XCTAssertEqual(try riga("volpe"), traduttore.formazione(try formazione("volpe")))
        // Conclusa la campagna, chi doveva ancora arrivarvi resta in patria.
        XCTAssertEqual(traduttore.formazione(try formazione("aquila"), condotta: true),
                       "Aquila, gruppo armato, reclute dell'inverno: 6 atomi di cavalleria manovrata. Arriva in estate e resta in patria")
        XCTAssertEqual(traduttore.forze(forze, fronte: fronte).map(\.unita), forze.formazioni.map(\.nome))
        for riga in traduttore.forze(forze, fronte: fronte) { risolta(riga.testo, riga.unita) }
        // Ogni nome della lista chiusa regge le righe nuove, nelle due forme.
        for nome in valoriRegno.nomiDelleUnita {
            let sola = FormazioneDelRegno(nome: nome, categoria: .armato, composizione: [leggera(6)])
            risolta(traduttore.formazione(sola, fronte: SituazioneDelFronte(
                sulFronte: [nome: .init(casella: Cella(riga: 1, colonna: 1), composizione: [leggera(6)])], inArrivo: [])), nome)
            risolta(traduttore.formazione(sola, fronte: SituazioneDelFronte(sulFronte: [:], inArrivo: [])), nome)
        }
    }

    func test_incarico_31_la_riga_si_accorda_al_numero_degli_atomi_e_al_genere_del_nome() throws {
        // Un atomo solo, e un nome femminile: le forme sono scritte per ciascun genere (02 §4.6).
        let sola = FormazioneDelRegno(nome: "aquila", categoria: .armato, composizione: [leggera(1)])
        XCTAssertEqual(traduttore.formazione(sola), "Aquila, gruppo armato: 1 atomo di fanteria leggera. Parte per il fronte")
        XCTAssertEqual(traduttore.reparto(pesante(1, migliorata: true)), "1 atomo di fanteria pesante con addestramento mirato")
        XCTAssertEqual(traduttore.reparto(pesante(8, migliorata: true)), "8 atomi di fanteria pesante con addestramento mirato")
        XCTAssertEqual(traduttore.reparto(pesante(8, migliorata: true), conMiglioramento: false), "8 atomi di fanteria pesante")
        XCTAssertEqual(traduttore.reparto(leggera(6, leva: 3)), "6 atomi di fanteria leggera",
                       "l'anno di leva non si dice: serve al regno, non al giocatore")
        XCTAssertEqual(traduttore.composizione([leggera(18), pesante(8), cavalleria(12)]),
                       "18 atomi di fanteria leggera, 8 atomi di fanteria pesante, 12 atomi di cavalleria manovrata")
        // Ogni nome della lista chiusa regge ogni riga, in ogni caso.
        for nome in valoriRegno.nomiDelleUnita {
            for (inPatria, arrivo) in [(false, nil), (true, nil), (false, Stagione.primavera), (false, .estate),
                                       (false, .inverno), (true, .autunno)] as [(Bool, Stagione?)] {
                risolta(traduttore.formazione(FormazioneDelRegno(nome: nome, categoria: .armato, composizione: [leggera(6)],
                                                                 inPatria: inPatria, arrivo: arrivo)), nome)
            }
        }
    }

    /// D'inverno la riga aggiunge a ciascun reparto lo stato del suo miglioramento: da mantenere, già
    /// mantenuto, oppure in corso.
    func test_incarico_31_d_inverno_la_riga_dice_lo_stato_del_miglioramento_di_ciascun_reparto() throws {
        let lupo = try formazione("lupo")
        let leggeraDiLupo = BersaglioMilitare(unita: "lupo", elemento: 0)
        let pesanteDiLupo = BersaglioMilitare(unita: "lupo", elemento: 1)
        func lavoro(_ voce: String, _ effetto: EffettoMilitare, _ bersaglio: BersaglioMilitare?) -> LavoroOrdinato {
            LavoroOrdinato(voce: IdentificatoreDati(voce), costo: .vuote, stazione: 1, effetto: effetto, pronto: .primavera,
                           bersaglio: bersaglio)
        }
        // Nessun lavoro: il reparto addestrato va ancora mantenuto.
        XCTAssertEqual(traduttore.formazione(lupo, lavori: []),
                       "Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante con addestramento mirato, "
                       + "da mantenere entro l'inverno. Parte per il fronte")
        // Il mantenimento è stato ordinato.
        let mantenuto = lavoro("mantenimento_addestramento", .mantieniMiglioramento(miglioramento: "addestramento_mirato"),
                               pesanteDiLupo)
        XCTAssertEqual(traduttore.formazione(lupo, lavori: [mantenuto]),
                       "Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante con addestramento mirato, "
                       + "mantenimento pagato. Parte per il fronte")
        // L'altro reparto è in addestramento.
        let inCorso = lavoro("addestramento_mirato", .miglioraReparto(miglioramento: "addestramento_mirato"), leggeraDiLupo)
        XCTAssertEqual(traduttore.formazione(lupo, lavori: [mantenuto, inCorso]),
                       "Lupo, gruppo armato: 18 atomi di fanteria leggera, addestramento mirato in corso, "
                       + "8 atomi di fanteria pesante con addestramento mirato, mantenimento pagato. Parte per il fronte")
        // Una leva non riguarda alcun reparto, e i lavori di un'altra formazione non toccano questa.
        let leva = lavoro("leva_fanteria_leggera", .reclutaReparto(archetipo: "fanteria_leggera", atomi: 6), nil)
        let altrove = lavoro("addestramento_mirato", .miglioraReparto(miglioramento: "addestramento_mirato"),
                             BersaglioMilitare(unita: "corvo", elemento: 0))
        XCTAssertEqual(traduttore.formazione(lupo, lavori: [leva, altrove]), traduttore.formazione(lupo, lavori: []))
        XCTAssertEqual(traduttore.formazione(try formazione("corvo"), lavori: [leva, altrove]),
                       "Corvo, gruppo armato: 6 atomi di fanteria leggera, addestramento mirato in corso. Parte per il fronte")
        // Fuori dall'inverno la riga non dice nulla del mantenimento.
        XCTAssertEqual(traduttore.formazione(lupo),
                       "Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante con addestramento mirato. "
                       + "Parte per il fronte")
        XCTAssertEqual(traduttore.forze(forze, lavori: [mantenuto]).first { $0.unita == "lupo" }?.testo,
                       traduttore.formazione(lupo, lavori: [mantenuto]))
    }

    // MARK: - Le reclute, lo scioglimento, i miglioramenti

    func test_incarico_31_l_ingresso_delle_reclute_dice_quale_formazione_con_che_cosa_e_dove_e_quando_entra() {
        XCTAssertEqual(traduttore.ingresso(Esemplari.ingresso(.primavera, confluite: false)),
                       "Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, ed entra sul fronte in primavera, "
                       + "al quartier generale o nella casella libera più vicina")
        XCTAssertEqual(traduttore.ingresso(Esemplari.ingresso(.estate, confluite: false)),
                       "Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, e raggiunge il fronte "
                       + "in estate, a campagna aperta, al quartier generale o nella casella libera più vicina")
        XCTAssertEqual(traduttore.ingresso(Esemplari.ingresso(.autunno, confluite: false)),
                       "Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, e raggiunge il fronte "
                       + "in autunno, a campagna aperta, al quartier generale o nella casella libera più vicina")
        XCTAssertEqual(traduttore.ingresso(Esemplari.ingresso(.inverno, confluite: false)),
                       "Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, e arriva in patria con l'inverno")
        // A nomi esauriti le reclute si uniscono a una formazione che c'è già.
        XCTAssertEqual(traduttore.ingresso(Esemplari.ingresso(.primavera, confluite: true)),
                       "Lince riceve le reclute dell'inverno: 6 atomi di fanteria leggera")
        XCTAssertEqual(traduttore.ingresso(Esemplari.ingresso(.estate, confluite: true)),
                       traduttore.ingresso(Esemplari.ingresso(.primavera, confluite: true)))
    }

    func test_incarico_31_lo_scioglimento_e_i_miglioramenti_hanno_la_formazione_per_soggetto() {
        XCTAssertEqual(traduttore.sciolto(Esemplari.sciolto),
                       "Lince perde 6 atomi di fanteria leggera: reparto sciolto, il denaro non è bastato al mantenimento")
        XCTAssertEqual(traduttore.migliorato(Esemplari.migliorato), "Lupo ha ora 8 atomi di fanteria pesante con addestramento mirato")
        XCTAssertEqual(traduttore.miglioramentoPerduto(Esemplari.migliorato),
                       "Lupo ha 8 atomi di fanteria pesante senza più addestramento mirato, per mancato mantenimento")
        // Un reparto addestrato che viene sciolto si nomina col suo addestramento.
        XCTAssertEqual(traduttore.sciolto(ElementoDelleForze(unita: "aquila", reparto: pesante(8, leva: 2, migliorata: true))),
                       "Aquila perde 8 atomi di fanteria pesante con addestramento mirato: reparto sciolto, "
                       + "il denaro non è bastato al mantenimento")
    }

    // MARK: - Gli annunci degli eventi

    func test_incarico_31_l_inverno_annuncia_l_entrata_il_mantenimento_e_cio_che_e_stato_sciolto() {
        let entrata = Riserve(["denaro": 200, "uomini": 24, "metalli": 30, "materiale": 30, "animali": 12])
        var mantenimento = Riserve()
        mantenimento[.denaro] = 27
        // Il mantenimento, quando basta.
        XCTAssertEqual(traduttore.annuncio(
            per: .invernoCominciato(anno: 2, entrata: entrata, mantenimento: mantenimento, sciolti: []),
            fase: .arcaica)?.testo,
            "Comincia l'inverno dell'anno 2. Entrate: monete di bronzo 200, uomini 24, metalli 30, "
            + "materiale da costruzione 30, animali 12. Mantenimento dell'esercito: monete di bronzo 27.")
        // Quando non basta: lo dice, e nomina ciascun reparto sciolto.
        let secondo = ElementoDelleForze(unita: "lupo", reparto: pesante(8, leva: 1))
        XCTAssertEqual(traduttore.annuncio(
            per: .invernoCominciato(anno: 2, entrata: entrata, mantenimento: mantenimento,
                                    sciolti: [Esemplari.sciolto, secondo]),
            fase: .arcaica)?.testo,
            "Comincia l'inverno dell'anno 2. Entrate: monete di bronzo 200, uomini 24, metalli 30, "
            + "materiale da costruzione 30, animali 12. Mantenimento dell'esercito: monete di bronzo 27. "
            + "Il denaro non basta al mantenimento. "
            + "Lince perde 6 atomi di fanteria leggera: reparto sciolto, il denaro non è bastato al mantenimento. "
            + "Lupo perde 8 atomi di fanteria pesante: reparto sciolto, il denaro non è bastato al mantenimento.")
        // Sciolto tutto, non resta nulla da prelevare: il mantenimento non si nomina, lo scioglimento sì.
        XCTAssertEqual(traduttore.annuncio(
            per: .invernoCominciato(anno: 2, entrata: entrata, mantenimento: .vuote, sciolti: [Esemplari.sciolto]),
            fase: .arcaica)?.testo,
            "Comincia l'inverno dell'anno 2. Entrate: monete di bronzo 200, uomini 24, metalli 30, "
            + "materiale da costruzione 30, animali 12. Il denaro non basta al mantenimento. "
            + "Lince perde 6 atomi di fanteria leggera: reparto sciolto, il denaro non è bastato al mantenimento.")
        XCTAssertNil(traduttore.significato(per: .invernoCominciato(anno: 2, entrata: entrata, mantenimento: mantenimento,
                                                                    sciolti: [])))
    }

    func test_incarico_31_la_primavera_annuncia_le_reclute_i_miglioramenti_dati_e_quelli_perduti() {
        let perduto = ElementoDelleForze(unita: "corvo", reparto: leggera(6, migliorata: true))
        XCTAssertEqual(traduttore.annuncio(
            per: .primaveraCominciata(anno: 3, perduto: .vuote,
                                      ingressi: [Esemplari.ingresso(.primavera, confluite: false),
                                                 Esemplari.ingresso(.estate, confluite: false)],
                                      migliorati: [Esemplari.migliorato], miglioramentiPerduti: [perduto]),
            fase: .arcaica)?.testo,
            "Comincia la primavera dell'anno 3. "
            + "Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, ed entra sul fronte in primavera, "
            + "al quartier generale o nella casella libera più vicina. "
            + "Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, e raggiunge il fronte "
            + "in estate, a campagna aperta, al quartier generale o nella casella libera più vicina. "
            + "Lupo ha ora 8 atomi di fanteria pesante con addestramento mirato. "
            + "Corvo ha 6 atomi di fanteria leggera senza più addestramento mirato, per mancato mantenimento.")
        // Col riporto, e un solo miglioramento perduto.
        XCTAssertEqual(traduttore.annuncio(
            per: .primaveraCominciata(anno: 3, perduto: Riserve(["denaro": 64]), ingressi: [], migliorati: [],
                                      miglioramentiPerduti: [perduto]),
            fase: .arcaica)?.testo,
            "Comincia la primavera dell'anno 3. Il riporto ha tolto: monete di bronzo 64. "
            + "Corvo ha 6 atomi di fanteria leggera senza più addestramento mirato, per mancato mantenimento.")
    }

    func test_incarico_31_l_ordine_su_un_reparto_e_la_scelta_di_chi_parte_si_annunciano_e_portano_la_conferma() throws {
        let pesanteDiLupo = BersaglioMilitare(unita: "lupo", elemento: 1)
        let leggeraDiCorvo = BersaglioMilitare(unita: "corvo", elemento: 0)
        // L'ordine nomina il reparto e la sua formazione; le voci nuove sono maschili.
        XCTAssertEqual(traduttore.annuncio(
            per: .lavoroOrdinato(voce: "addestramento_mirato", costo: .vuote, pronto: .primavera, bersaglio: leggeraDiCorvo),
            fase: .arcaica, forze: forze)?.testo,
            "Addestramento mirato ordinato per 6 atomi di fanteria leggera di Corvo: pronto in primavera.")
        XCTAssertEqual(traduttore.annuncio(
            per: .lavoroOrdinato(voce: "mantenimento_addestramento", costo: .vuote, pronto: .primavera, bersaglio: pesanteDiLupo),
            fase: .arcaica, forze: forze)?.testo,
            "Mantenimento dell'addestramento mirato ordinato per 8 atomi di fanteria pesante con addestramento mirato di Lupo: "
            + "pronto in primavera.")
        // La leva, senza bersaglio, si annuncia com'era, con la stagione in cui sarà pronta.
        XCTAssertEqual(traduttore.annuncio(
            per: .lavoroOrdinato(voce: "leva_cavalleria_manovrata", costo: .vuote, pronto: .autunno, bersaglio: nil),
            fase: .arcaica, forze: forze)?.testo, "Leva di cavalleria manovrata ordinata: pronta in autunno.")
        // Senza le forze il reparto non si può nominare: resta la frase senza bersaglio, risolta.
        XCTAssertEqual(traduttore.annuncio(
            per: .lavoroOrdinato(voce: "addestramento_mirato", costo: .vuote, pronto: .primavera, bersaglio: leggeraDiCorvo),
            fase: .arcaica)?.testo, "Addestramento mirato ordinato: pronto in primavera.")
        XCTAssertEqual(traduttore.significato(per: .lavoroOrdinato(voce: "addestramento_mirato", costo: .vuote,
                                                                   pronto: .primavera, bersaglio: leggeraDiCorvo)), .conferma)
        // Il bersaglio in parole, e quello che non esiste.
        XCTAssertEqual(traduttore.bersaglio(pesanteDiLupo, forze: forze), "8 atomi di fanteria pesante con addestramento mirato di Lupo")
        XCTAssertNil(traduttore.bersaglio(BersaglioMilitare(unita: "lupo", elemento: 7), forze: forze))
        XCTAssertNil(traduttore.bersaglio(BersaglioMilitare(unita: "muflone", elemento: 0), forze: forze))

        // La scelta di chi parte.
        XCTAssertEqual(traduttore.annuncio(per: .unitaDestinata(unita: "lupo", alFronte: false), fase: .arcaica)?.testo,
                       "Lupo resta in patria.")
        XCTAssertEqual(traduttore.annuncio(per: .unitaDestinata(unita: "lupo", alFronte: true), fase: .arcaica)?.testo,
                       "Lupo parte per il fronte.")
        XCTAssertEqual(traduttore.annuncio(per: .unitaDestinata(unita: "aquila", alFronte: false), fase: .arcaica)?.testo,
                       "Aquila resta in patria.")
        XCTAssertEqual(traduttore.significato(per: .unitaDestinata(unita: "lupo", alFronte: false)), .conferma)
        for nome in valoriRegno.nomiDelleUnita {
            for alFronte in [true, false] {
                risolta(traduttore.annuncio(per: .unitaDestinata(unita: nome, alFronte: alFronte), fase: .arcaica)?.testo ?? "", nome)
            }
        }
    }

    // MARK: - Il registro della patria

    func test_incarico_31_il_registro_annota_i_fatti_delle_forze_con_la_frase_dell_annuncio() {
        func voce(_ fatto: FattoDiPatria, anno: Int = 2, _ stagione: Stagione = .primavera) -> String {
            traduttore.voceDiRegistro(VoceRegistroPatria(numero: 0, anno: anno, stagione: stagione, fatto: fatto),
                                      fase: .arcaica).testo
        }
        XCTAssertEqual(voce(.mantenimentoPrelevato(quota: Riserve(["denaro": 30])), anno: 1, .inverno),
                       "Anno 1, inverno: prelevato il mantenimento dell'esercito, monete di bronzo 30")
        XCTAssertEqual(voce(.elementoSciolto(Esemplari.sciolto), anno: 1, .inverno),
                       "Anno 1, inverno: Lince perde 6 atomi di fanteria leggera: reparto sciolto, "
                       + "il denaro non è bastato al mantenimento")
        XCTAssertEqual(voce(.recluteEntrate(Esemplari.ingresso(.estate, confluite: false))),
                       "Anno 2, primavera: Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, "
                       + "e raggiunge il fronte in estate, a campagna aperta, al quartier generale o nella casella libera più vicina")
        XCTAssertEqual(voce(.recluteEntrate(Esemplari.ingresso(.inverno, confluite: false))),
                       "Anno 2, primavera: Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, "
                       + "e arriva in patria con l'inverno")
        XCTAssertEqual(voce(.recluteEntrate(Esemplari.ingresso(.primavera, confluite: true))),
                       "Anno 2, primavera: Lince riceve le reclute dell'inverno: 6 atomi di fanteria leggera")
        XCTAssertEqual(voce(.miglioramentoDato(Esemplari.migliorato)),
                       "Anno 2, primavera: Lupo ha ora 8 atomi di fanteria pesante con addestramento mirato")
        XCTAssertEqual(voce(.miglioramentoPerduto(Esemplari.migliorato)),
                       "Anno 2, primavera: Lupo ha 8 atomi di fanteria pesante senza più addestramento mirato, "
                       + "per mancato mantenimento")
        // La frase del registro è quella dell'annuncio, con l'anno e la stagione davanti.
        XCTAssertEqual(voce(.miglioramentoDato(Esemplari.migliorato)),
                       "Anno 2, primavera: " + traduttore.migliorato(Esemplari.migliorato))
        XCTAssertEqual(voce(.elementoSciolto(Esemplari.sciolto)), "Anno 2, primavera: " + traduttore.sciolto(Esemplari.sciolto))
    }

    /// Il registro di un anno GIOCATO: ogni voce che il Motore annota — il mantenimento, le reclute,
    /// l'addestramento dato, quello perduto — si risolve in una frase compiuta.
    func test_incarico_31_ogni_voce_del_registro_di_due_anni_giocati_si_risolve() throws {
        var stato = try motore.statoIniziale()
        func applica(_ comando: ComandoRegno, riga: UInt = #line) -> [EventoRegno] {
            XCTAssertTrue(motore.valida(comando, stato: stato).eValido, "\(comando)", line: riga)
            let (nuovo, eventi) = motore.applica(comando, stato: stato)
            stato = nuovo
            return eventi
        }
        var annunci: [String] = []
        func annuncia(_ eventi: [EventoRegno]) {
            for evento in eventi {
                if let testo = traduttore.annuncio(per: evento, fase: stato.fase, forze: stato.forze)?.testo {
                    risolta(testo, "\(evento)")
                    annunci.append(testo)
                }
            }
        }
        annuncia(applica(.destina(unita: "cervo", alFronte: false)))
        annuncia(applica(.attendiInverno))
        annuncia(applica(.ordina(voce: "leva_fanteria_leggera", bersaglio: nil)))
        annuncia(applica(.ordina(voce: "addestramento_mirato", bersaglio: BersaglioMilitare(unita: "corvo", elemento: 0))))
        annuncia(applica(.prosegui))
        annuncia(applica(.ordina(voce: "leva_cavalleria_manovrata", bersaglio: nil)))
        while stato.momento.eInverno { annuncia(applica(.prosegui)) }
        annuncia(applica(.attendiInverno))
        while stato.momento.eInverno { annuncia(applica(.prosegui)) }
        XCTAssertEqual(stato.anno, 3)
        let registro = stato.registro.map { traduttore.voceDiRegistro($0, fase: stato.fase).testo }
        for frase in registro { risolta(frase, "registro") }
        XCTAssertEqual(registro, [
            "Anno 1, inverno: comincia l'inverno e arriva l'entrata dell'anno",
            "Anno 1, inverno: prelevato il mantenimento dell'esercito, monete di bronzo 27",
            "Anno 2, primavera: comincia la primavera; il riporto ha tolto ciò che eccedeva",
            "Anno 2, primavera: Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, ed entra sul fronte "
                + "in primavera, al quartier generale o nella casella libera più vicina",
            "Anno 2, primavera: Aquila nasce dalle reclute dell'inverno, con 6 atomi di cavalleria manovrata, e raggiunge "
                + "il fronte in estate, a campagna aperta, al quartier generale o nella casella libera più vicina",
            "Anno 2, primavera: Corvo ha ora 6 atomi di fanteria leggera con addestramento mirato",
            "Anno 2, inverno: comincia l'inverno e arriva l'entrata dell'anno",
            "Anno 2, inverno: prelevato il mantenimento dell'esercito, monete di bronzo 31",
            "Anno 3, primavera: comincia la primavera; il riporto ha tolto ciò che eccedeva",
            "Anno 3, primavera: Corvo ha 6 atomi di fanteria leggera senza più addestramento mirato, per mancato mantenimento",
        ])
        XCTAssertEqual(annunci.first, "Cervo resta in patria.")
        XCTAssertTrue(annunci.contains("Addestramento mirato ordinato per 6 atomi di fanteria leggera di Corvo: pronto in primavera."))
        XCTAssertTrue(annunci.contains("Leva di cavalleria manovrata ordinata: pronta in estate."))
        // Le righe delle forze al terzo anno, com'è la patria: tutte risolte.
        for riga in traduttore.forze(stato.forze) { risolta(riga.testo, riga.unita) }
        XCTAssertEqual(traduttore.forze(stato.forze).map(\.testo).filter { $0.hasSuffix("Resta in patria") },
                       ["Cervo, formazione non armata: 4 atomi di fanteria leggera. Resta in patria"])
    }

    // MARK: - Le voci che si ordinano su un reparto

    func test_incarico_31_l_etichetta_della_voce_che_si_ordina_su_un_reparto() throws {
        let addestramento = try XCTUnwrap(valoriRegno.voce("addestramento_mirato"))
        let mantenimento = try XCTUnwrap(valoriRegno.voce("mantenimento_addestramento"))
        XCTAssertEqual(traduttore.etichetta(dellaVoceConBersaglio: addestramento, bersagli: 3, pronta: .primavera,
                                            verbosita: .normale),
                       "Addestramento mirato. Si sceglie il reparto. Accresce la capacità offensiva del reparto, pronto in primavera.")
        XCTAssertEqual(traduttore.etichetta(dellaVoceConBersaglio: mantenimento, bersagli: 1, pronta: .primavera,
                                            verbosita: .normale),
                       "Mantenimento dell'addestramento mirato. Si sceglie il reparto. "
                       + "Conserva il miglioramento del reparto per un altro anno, pronto in primavera.")
        // Senza alcun reparto che la ammetta, lo dice.
        XCTAssertEqual(traduttore.etichetta(dellaVoceConBersaglio: mantenimento, bersagli: 0, pronta: .primavera,
                                            verbosita: .normale),
                       "Mantenimento dell'addestramento mirato. Nessun reparto disponibile. "
                       + "Conserva il miglioramento del reparto per un altro anno, pronto in primavera.")
        // I livelli brevi tagliano dalla coda (00 §9.5).
        XCTAssertEqual(traduttore.etichetta(dellaVoceConBersaglio: addestramento, bersagli: 3, pronta: .primavera,
                                            verbosita: .sintetico), "Addestramento mirato. Si sceglie il reparto.")
        XCTAssertEqual(traduttore.etichetta(dellaVoceConBersaglio: addestramento, bersagli: 3, pronta: .primavera,
                                            verbosita: .dettagliato),
                       traduttore.etichetta(dellaVoceConBersaglio: addestramento, bersagli: 3, pronta: .primavera,
                                            verbosita: .normale))
        // La leva dice la stagione in cui sarà pronta, che cambia con la schermata in cui la si ordina.
        let cavalleria = try XCTUnwrap(valoriRegno.voce("leva_cavalleria_manovrata"))
        let costo = motore.costo(di: cavalleria, misura: 6)
        let riserve = Riserve(["denaro": 220, "uomini": 26, "metalli": 33, "materiale": 33, "animali": 13])
        XCTAssertEqual(traduttore.etichetta(dellaVoce: cavalleria, costo: costo, riserve: riserve,
                                            pronta: motore.prontoIn(voce: cavalleria, stazione: 1), fase: .arcaica,
                                            verbosita: .normale),
                       "Leva di cavalleria manovrata. Costa: monete di bronzo 72 su 220, uomini 6 su 26, metalli 6 su 33, "
                       + "animali 6 su 13. 6 atomi, pronta in estate.")
        XCTAssertEqual(traduttore.etichetta(dellaVoce: cavalleria, costo: costo, riserve: riserve,
                                            pronta: motore.prontoIn(voce: cavalleria, stazione: 4), fase: .arcaica,
                                            verbosita: .normale),
                       "Leva di cavalleria manovrata. Costa: monete di bronzo 72 su 220, uomini 6 su 26, metalli 6 su 33, "
                       + "animali 6 su 13. 6 atomi, pronta in autunno.")
    }

    func test_incarico_31_l_etichetta_del_reparto_da_scegliere_dice_il_costo_sulla_riserva() throws {
        let addestramento = try XCTUnwrap(valoriRegno.voce("addestramento_mirato"))
        let pesanteDiLupo = BersaglioMilitare(unita: "lupo", elemento: 1)
        let stato = StatoRegno(anno: 2, momento: .inverno(stazione: 1), fase: .arcaica,
                               riserve: Riserve(["denaro": 220, "uomini": 26, "metalli": 33, "materiale": 33, "animali": 13]),
                               forze: forze)
        // Il costo è quello dei valori di fabbrica: gli atomi del reparto, per la base, per il peso
        // della voce. Si legge dal Motore, e qui si pretende soltanto che la frase lo dica.
        let costo = try XCTUnwrap(motore.costo(di: addestramento, bersaglio: pesanteDiLupo, stato: stato))
        XCTAssertEqual(costo.risorseInGioco, [.denaro])
        XCTAssertEqual(costo[.denaro], Int(addestramento.peso(su: .denaro).applicato(a: 8 * 5)))
        XCTAssertEqual(traduttore.etichetta(delBersaglio: pesanteDiLupo, forze: forze, costo: costo, riserve: stato.riserve,
                                            fase: .arcaica),
                       "Lupo: 8 atomi di fanteria pesante con addestramento mirato. "
                       + "Costa: monete di bronzo \(costo[.denaro]) su 220.")
        // Con le riserve scarse, l'impossibilità prima del costo (01 §5.9.1.5).
        XCTAssertEqual(traduttore.etichetta(delBersaglio: pesanteDiLupo, forze: forze, costo: costo,
                                            riserve: Riserve(["denaro": 10]), fase: .arcaica),
                       "Lupo: 8 atomi di fanteria pesante con addestramento mirato. "
                       + "Non si può ordinare: mancano monete di bronzo. Costa: monete di bronzo \(costo[.denaro]) su 10.")
        // Un nome femminile, un reparto senza addestramento.
        var otto = Riserve()
        otto[.denaro] = 8
        XCTAssertEqual(traduttore.etichetta(delBersaglio: BersaglioMilitare(unita: "aquila", elemento: 0), forze: forze,
                                            costo: otto, riserve: stato.riserve, fase: .arcaica),
                       "Aquila: 6 atomi di cavalleria manovrata. Costa: monete di bronzo 8 su 220.")
    }

    func test_incarico_31_il_lavoro_elencato_dice_su_che_cosa_e_quando_sara_pronto() {
        let pesanteDiLupo = BersaglioMilitare(unita: "lupo", elemento: 1)
        let mantenimento = LavoroOrdinato(voce: "mantenimento_addestramento", costo: .vuote, stazione: 2,
                                          effetto: .mantieniMiglioramento(miglioramento: "addestramento_mirato"),
                                          pronto: .primavera, bersaglio: pesanteDiLupo)
        XCTAssertEqual(traduttore.lavoroElencato(mantenimento, forze: forze),
                       "Mantenimento dell'addestramento mirato per 8 atomi di fanteria pesante con addestramento mirato di Lupo, "
                       + "pronto in primavera")
        let leva = LavoroOrdinato(voce: "leva_fanteria_pesante", costo: .vuote, stazione: 3,
                                  effetto: .reclutaReparto(archetipo: "fanteria_pesante", atomi: 8), pronto: .estate)
        XCTAssertEqual(traduttore.lavoroElencato(leva, forze: forze), "Leva di fanteria pesante, pronta in estate")
        XCTAssertEqual(traduttore.spesaAnnullata(mantenimento).testo,
                       "Mantenimento dell'addestramento mirato: ordine annullato, risorse restituite.")
    }

    func test_incarico_31_la_prima_schermata_dichiara_il_mantenimento_e_cio_che_ha_sciolto() {
        var prelevato = Riserve()
        prelevato[.denaro] = 27
        XCTAssertEqual(traduttore.dichiarazioneDelMantenimento(prelevato: prelevato, sciolti: [], fase: .arcaica),
                       ["Mantenimento dell'esercito, prelevato all'inizio dell'inverno: monete di bronzo 27"])
        XCTAssertEqual(traduttore.dichiarazioneDelMantenimento(prelevato: prelevato,
                                                               sciolti: [Esemplari.sciolto], fase: .arcaica), [
            "Mantenimento dell'esercito, prelevato all'inizio dell'inverno: monete di bronzo 27",
            "Il denaro non è bastato al mantenimento: sciolti per primi i reparti reclutati per ultimi",
            "Lince perde 6 atomi di fanteria leggera: reparto sciolto, il denaro non è bastato al mantenimento",
        ])
        // Nulla da mantenere, nulla da dichiarare.
        XCTAssertEqual(traduttore.dichiarazioneDelMantenimento(prelevato: .vuote, sciolti: [], fase: .arcaica), [])
        // Sciolto tutto: non c'è prelievo, e lo scioglimento si dichiara.
        XCTAssertEqual(traduttore.dichiarazioneDelMantenimento(prelevato: .vuote, sciolti: [Esemplari.sciolto],
                                                               fase: .arcaica).count, 2)
    }

    // MARK: - La dichiarazione di conclusione con gli arrivi mai giunti

    func test_incarico_31_la_conclusione_conta_fra_chi_rientra_soltanto_chi_era_sul_fronte() {
        // Rientrano due formazioni; una terza non è mai arrivata, e torna ancora in arrivo.
        let superstiti = ForzeDelRegno.sciami(formazioni: [
            FormazioneDelRegno(nome: "corvo", categoria: .armato, composizione: [leggera(6)]),
            FormazioneDelRegno(nome: "lupo", categoria: .armato, composizione: [pesante(8)]),
            FormazioneDelRegno(nome: "aquila", categoria: .armato, composizione: [cavalleria(6, leva: 1)], arrivo: .autunno),
        ], prossimoNome: 0)
        let esito = EsitoCampagna(fronte: "guado", anno: 2, modo: .annientamento, vincitore: .giocatore, giornate: 40,
                                  battaglieVinte: 1, battagliePerse: 0, superstiti: superstiti)
        let voci = traduttore.dichiarazioneDiConclusione(esito, premi: motore.premi(per: esito), fase: .arcaica)
        XCTAssertEqual(voci[3], "Rientrano in patria: 2 formazioni")
        for voce in voci { risolta(voce, "conclusione") }
    }

    // MARK: - Sul fronte: l'arrivo dalla patria

    func test_incarico_31_l_arrivo_dalla_patria_si_annuncia_ed_entra_nel_registro_accordato_al_genere() {
        let campagna = TraduttoreEventiCampagna(testi: testi, parte: .giocatore)
        let quartierGenerale = Cella(riga: 10, colonna: 6)
        func arrivo(_ nome: String) -> EventoCampagna {
            .arrivoDallaPatria(gruppo: IdGruppo(7), nome: IdentificatoreDati(nome), casella: quartierGenerale)
        }
        XCTAssertEqual(campagna.annuncio(per: arrivo("lince"), verbosita: .normale)?.testo,
                       "Lince è arrivata dalla patria in riga 10, casella 6")
        XCTAssertEqual(campagna.annuncio(per: arrivo("cervo"), verbosita: .normale)?.testo,
                       "Cervo è arrivato dalla patria in riga 10, casella 6")
        XCTAssertEqual(campagna.annuncio(per: arrivo("lince"), verbosita: .sintetico)?.testo,
                       "Lince dalla patria in riga 10, casella 6")
        XCTAssertEqual(campagna.annuncio(per: arrivo("lince"), verbosita: .dettagliato)?.testo,
                       campagna.annuncio(per: arrivo("lince"), verbosita: .normale)?.testo)
        // Si annuncia a parole, senza un significato tattile proprio: il tetto è chiuso (02 §11.5).
        XCTAssertNil(campagna.significato(per: arrivo("lince")))
        XCTAssertFalse(TraduttoreEventiCampagna.supera(arrivo("lince")), "l'arrivo si accoda, non supera gli altri annunci")
        // Nel registro, col giorno davanti e il luogo.
        XCTAssertEqual(campagna.voceDiRegistro(VoceRegistro(
            numero: 0, giorno: 31, fatto: .arrivoDallaPatria(gruppo: "lince", casella: quartierGenerale))).testo,
            "Giorno 31: Lince è arrivata dalla patria in riga 10, casella 6")
        XCTAssertEqual(campagna.voceDiRegistro(VoceRegistro(
            numero: 0, giorno: 1, fatto: .arrivoDallaPatria(gruppo: "cervo", casella: Cella(riga: 9, colonna: 6)))).testo,
            "Giorno 1: Cervo è arrivato dalla patria in riga 9, casella 6")
        XCTAssertEqual(VoceRegistro(numero: 0, giorno: 31,
                                    fatto: .arrivoDallaPatria(gruppo: "lince", casella: quartierGenerale)).luogo,
                       quartierGenerale, "la voce porta il luogo: dal registro si può andare alla casella")
        // Ogni nome della lista chiusa ha l'annuncio e la voce di registro, a ogni livello di verbosità.
        for nome in valoriRegno.nomiDelleUnita {
            for verbosita in Verbosita.allCases {
                risolta(campagna.annuncio(per: arrivo(nome), verbosita: verbosita)?.testo ?? "", "\(nome) a \(verbosita)")
            }
            risolta(campagna.voceDiRegistro(VoceRegistro(
                numero: 0, giorno: 3, fatto: .arrivoDallaPatria(gruppo: nome, casella: quartierGenerale))).testo, nome)
        }
    }
}
