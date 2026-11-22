import XCTest
import Motore
import Dati
import Contenuti

/// Le regole del regno (incarico 30, prima tappa): il calendario dell'anno, il bilancio che nasce
/// dalla rendita e dall'esito, il costo delle voci, il riporto, la primavera. Le formule si provano
/// su valori scritti qui, perché una prova sui valori di fabbrica cambierebbe a ogni taratura; una
/// prova a parte accerta che i valori di fabbrica producano un anno giocabile.
final class RegnoTest: XCTestCase {

    /// Valori di prova, scelti perché i troncamenti si vedano: rendita non multipla di dieci, pesi
    /// con decimali.
    static func valoriDiProva(giornatePerStagione: Int = 2) -> ValoriRegno {
        ValoriRegno(
            giornatePerStagione: giornatePerStagione,
            quotaRiporto: Scalato(millesimi: 100),
            dotazioneIniziale: ["denaro": 10, "uomini": 1, "metalli": 2, "materiale": 3, "animali": 0],
            renditaAnnua: ["denaro": 105, "uomini": 17, "metalli": 23, "materiale": 30, "animali": 9],
            premioBattagliaVinta: Scalato(millesimi: 100),
            premioCampagnaVinta: Scalato(millesimi: 500),
            baseLeva: ["denaro": 5, "uomini": 1, "metalli": 1, "materiale": 0, "animali": 1],
            costoMinimo: 1,
            voci: [
                VoceDelRegno(identificatore: "leva_fanteria_leggera",
                             pesi: ["denaro": Scalato(intero: 1), "uomini": Scalato(intero: 1),
                                    "metalli": Scalato(millesimi: 500)],
                             effetto: .reclutaReparto(archetipo: "fanteria_leggera", atomi: 6)),
                VoceDelRegno(identificatore: "leva_fanteria_pesante",
                             pesi: ["denaro": Scalato(millesimi: 1600), "uomini": Scalato(intero: 1),
                                    "metalli": Scalato(intero: 2)],
                             effetto: .reclutaReparto(archetipo: "fanteria_pesante", atomi: 8)),
                // Un peso così piccolo che il troncamento darebbe zero: deve valere il minimo.
                VoceDelRegno(identificatore: "leva_cavalleria_manovrata",
                             pesi: ["denaro": Scalato(intero: 2), "animali": Scalato(millesimi: 10)],
                             effetto: .reclutaReparto(archetipo: "cavalleria_manovrata", atomi: 3)),
            ],
            fronti: [FronteDelRegno(identificatore: "guado", scenario: "campagna_piccola"),
                     FronteDelRegno(identificatore: "pianura_lunga", scenario: "campagna_grande")],
            faseIniziale: .arcaica,
            forzeIniziali: [
                FormazioneIniziale(categoria: "armato", composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)]),
                FormazioneIniziale(categoria: "ricognizione",
                                   composizione: [.init(archetipo: "fanteria_leggera", atomi: 3)], competenza: 5),
            ])
    }

    private var motore: MotoreRegno!

    override func setUp() {
        motore = MotoreRegno(valori: Self.valoriDiProva())
    }

    /// Applica un comando che deve essere valido.
    @discardableResult
    private func esegui(_ comando: ComandoRegno, _ stato: inout StatoRegno,
                        file: StaticString = #filePath, line: UInt = #line) -> [EventoRegno] {
        XCTAssertTrue(motore.valida(comando, stato: stato).eValido, "\(comando) dovrebbe essere valido",
                      file: file, line: line)
        let (nuovo, eventi) = motore.applica(comando, stato: stato)
        stato = nuovo
        return eventi
    }

    private func esito(_ stato: StatoRegno, fronte: String = "guado", modo: ConclusioneCampagna.Modo = .annientamento,
                       vincitore: Parte? = .giocatore, vinte: Int = 1, perse: Int = 0,
                       superstiti: ForzeDelRegno? = nil) -> EsitoCampagna {
        EsitoCampagna(fronte: fronte, anno: stato.anno, modo: modo, vincitore: vincitore, giornate: 4,
                      battaglieVinte: vinte, battagliePerse: perse, superstiti: superstiti ?? stato.forze)
    }

    // MARK: - Nascita

    func test_05_2_10_il_regno_nasce_in_primavera_con_la_dotazione() throws {
        let stato = try motore.statoIniziale()
        XCTAssertEqual(stato.anno, 1)
        XCTAssertEqual(stato.momento, .operativo)
        XCTAssertEqual(stato.campagna, .nonAperta)
        XCTAssertEqual(stato.riserve[.denaro], 10)
        XCTAssertEqual(stato.riserve[.animali], 0)
        XCTAssertEqual(stato.forze.numeroDiUnita, 2)
        XCTAssertEqual(stato.stagione(giornatePerStagione: 2), .primavera)
        XCTAssertTrue(stato.registro.isEmpty)
    }

    // MARK: - Il costo (00 §13.3, §13.5, §13.6)

    func test_00_13_il_costo_e_misura_per_base_per_peso_troncato_con_il_minimo() {
        let leggera = motore.costo(di: motore.valori.voce("leva_fanteria_leggera")!)
        XCTAssertEqual(leggera[.denaro], 30, "6 atomi per 5 per 1")
        XCTAssertEqual(leggera[.uomini], 6)
        XCTAssertEqual(leggera[.metalli], 3, "6 per 1 per 0,5")
        XCTAssertEqual(leggera[.materiale], 0, "ciò che la voce non consuma non costa")
        XCTAssertEqual(leggera.risorseInGioco, [.denaro, .uomini, .metalli],
                       "la voce dichiara soltanto le risorse che consuma, nell'ordine fisso (02 §8.7)")

        let pesante = motore.costo(di: motore.valori.voce("leva_fanteria_pesante")!)
        XCTAssertEqual(pesante[.denaro], 64, "8 per 5 per 1,6")
        XCTAssertEqual(pesante[.metalli], 16)

        let cavalleria = motore.costo(di: motore.valori.voce("leva_cavalleria_manovrata")!)
        XCTAssertEqual(cavalleria[.animali], 1,
                       "3 per 1 per 0,01 troncato darebbe zero: vale il minimo dichiarato (00 §13.6)")
        XCTAssertEqual(cavalleria[.denaro], 30)
    }

    // MARK: - L'entrata (RDA-165)

    func test_01_2_6_l_entrata_e_la_rendita_piu_i_premi_per_le_vittorie() throws {
        let stato = try motore.statoIniziale()
        let senza = motore.entrata(dopo: nil)
        XCTAssertEqual(senza[.denaro], 105)
        XCTAssertEqual(senza[.animali], 9)

        // Una campagna perduta, con una battaglia vinta: il solo premio della battaglia.
        let perduta = motore.entrata(dopo: esito(stato, vincitore: .avversario, vinte: 1, perse: 2))
        XCTAssertEqual(perduta[.denaro], 105 + 10, "un decimo della rendita, troncato")
        XCTAssertEqual(perduta[.uomini], 17 + 1)

        // Una campagna vinta con due battaglie vinte.
        let vinta = motore.entrata(dopo: esito(stato, vinte: 2))
        XCTAssertEqual(vinta[.denaro], 105 + 21 + 52, "due decimi troncati, più la metà troncata")
        XCTAssertEqual(vinta[.animali], 9 + 1 + 4)

        // L'inverno che interrompe: nessun vincitore, nessun premio di campagna.
        let interrotta = motore.entrata(dopo: esito(stato, modo: .inverno, vincitore: nil, vinte: 0))
        XCTAssertEqual(interrotta, senza)

        // I premi sono l'entrata con l'esito meno quella senza.
        XCTAssertEqual(motore.premi(per: esito(stato, vinte: 2))[.denaro], 73)
        XCTAssertTrue(motore.premi(per: esito(stato, modo: .inverno, vincitore: nil, vinte: 0)).sonoVuote)
    }

    // MARK: - La validazione (05 §3.2)

    func test_05_3_2_ogni_comando_fuori_posto_e_respinto_col_suo_motivo() throws {
        var stato = try motore.statoIniziale()
        XCTAssertEqual(motore.valida(.ordina(voce: "leva_fanteria_leggera"), stato: stato).motivo, .nonEInverno)
        XCTAssertEqual(motore.valida(.prosegui, stato: stato).motivo, .nonEInverno)
        XCTAssertEqual(motore.valida(.apriCampagna(fronte: "fronte_che_non_esiste"), stato: stato).motivo, .fronteIgnoto)

        esegui(.apriCampagna(fronte: "guado"), &stato)
        XCTAssertEqual(motore.valida(.apriCampagna(fronte: "pianura_lunga"), stato: stato).motivo, .campagnaAperta)
        XCTAssertEqual(motore.valida(.attendiInverno, stato: stato).motivo, .campagnaAperta,
                       "l'inverno non arriva finché la campagna dura: il fronte ha il proprio calendario")

        _ = motore.applicaEsito(esito(stato), in: &stato)
        XCTAssertEqual(motore.valida(.apriCampagna(fronte: "guado"), stato: stato).motivo, .campagnaGiaCondotta)

        esegui(.attendiInverno, &stato)
        XCTAssertEqual(motore.valida(.apriCampagna(fronte: "guado"), stato: stato).motivo, .eInverno)
        XCTAssertEqual(motore.valida(.attendiInverno, stato: stato).motivo, .eInverno)
        XCTAssertEqual(motore.valida(.ordina(voce: "voce_che_non_esiste"), stato: stato).motivo, .voceIgnota)
    }

    func test_01_5_9_1_5_la_voce_che_non_si_puo_pagare_dice_quali_risorse_mancano() throws {
        var stato = try motore.statoIniziale()
        esegui(.attendiInverno, &stato)
        // Senza campagna: denaro 115, uomini 18, metalli 25. Una leva pesante costa 64, 8 e 16: dopo
        // la prima restano 51, 10 e 9, e alla seconda mancano il denaro e i metalli, non gli uomini.
        esegui(.ordina(voce: "leva_fanteria_pesante"), &stato)
        XCTAssertEqual(motore.valida(.ordina(voce: "leva_fanteria_pesante"), stato: stato).motivo,
                       .risorseInsufficienti([.denaro, .metalli]))
        esegui(.ordina(voce: "leva_fanteria_leggera"), &stato)
        XCTAssertEqual(motore.valida(.ordina(voce: "leva_fanteria_pesante"), stato: stato).motivo,
                       .risorseInsufficienti([.denaro, .uomini, .metalli]),
                       "le risorse che mancano, tutte, nell'ordine fisso")
        XCTAssertEqual(stato.lavori.map(\.voce), ["leva_fanteria_pesante", "leva_fanteria_leggera"])
        XCTAssertEqual(stato.riserve[.denaro], 115 - 64 - 30)
    }

    func test_il_regno_senza_formazioni_armate_non_apre_la_campagna() throws {
        var stato = try motore.statoIniziale()
        stato.forze = .sciami(stato.forze.formazioni.filter { !$0.categoria.eArmata })
        XCTAssertEqual(motore.valida(.apriCampagna(fronte: "guado"), stato: stato).motivo, .nessunaForza)
        XCTAssertTrue(motore.valida(.attendiInverno, stato: stato).eValido,
                      "chi non può condurre campagna può attendere l'inverno e reclutare")
    }

    // MARK: - L'anno intero

    func test_01_5_9_un_anno_intero_la_campagna_l_inverno_la_leva_la_primavera() throws {
        var stato = try motore.statoIniziale()
        let forzeIniziali = stato.forze

        XCTAssertEqual(esegui(.apriCampagna(fronte: "guado"), &stato), [.campagnaAperta(fronte: "guado")])
        XCTAssertEqual(stato.campagna, .aperta(fronte: "guado"))

        // La campagna torna vinta, con una battaglia vinta e la ricognizione perduta.
        let rientrano = ForzeDelRegno.sciami([forzeIniziali.formazioni[0]])
        let vinta = esito(stato, vinte: 1, superstiti: rientrano)
        XCTAssertTrue(motore.accetta(vinta, stato: stato))
        XCTAssertEqual(motore.applicaEsito(vinta, in: &stato), [.campagnaConclusa(esito: vinta)])
        XCTAssertEqual(stato.forze, rientrano, "i caduti non tornano (01 §4.12)")
        XCTAssertEqual(stato.stagione(giornatePerStagione: 2), .estate, "la giornata 4 di 6 è d'estate")

        // L'inverno: il bilancio nasce dalla rendita e dall'esito.
        let eventiInverno = esegui(.attendiInverno, &stato)
        let entrata = motore.entrata(dopo: vinta)
        XCTAssertEqual(eventiInverno, [.invernoCominciato(anno: 1, entrata: entrata)])
        XCTAssertEqual(stato.momento, .inverno(stazione: 1))
        XCTAssertEqual(stato.riserve[.denaro], 10 + 105 + 10 + 52)
        XCTAssertEqual(stato.entrataDellAnno, entrata)

        // Le quattro stazioni: il bilancio resta disponibile per tutto l'inverno (01 §5.9.1.2).
        esegui(.ordina(voce: "leva_fanteria_leggera"), &stato)
        XCTAssertEqual(esegui(.prosegui, &stato), [.stazioneAperta(stazione: 2)])
        esegui(.ordina(voce: "leva_fanteria_pesante"), &stato)
        XCTAssertEqual(esegui(.prosegui, &stato), [.stazioneAperta(stazione: 3)])
        XCTAssertEqual(esegui(.prosegui, &stato), [.stazioneAperta(stazione: 4)])
        XCTAssertEqual(stato.lavori.map(\.stazione), [1, 2])
        let prima = stato.riserve

        // La primavera: riporto, reclute, anno nuovo.
        let eventi = esegui(.prosegui, &stato)
        XCTAssertEqual(stato.anno, 2)
        XCTAssertEqual(stato.momento, .operativo)
        XCTAssertEqual(stato.campagna, .nonAperta)
        XCTAssertTrue(stato.lavori.isEmpty)
        XCTAssertTrue(stato.entrataDellAnno.sonoVuote)
        let tetto = motore.tettoDelRiporto(entrata: entrata)
        XCTAssertEqual(tetto[.denaro], 16, "un decimo di 167, troncato")
        for risorsa in Risorsa.allCases {
            XCTAssertEqual(stato.riserve[risorsa], min(prima[risorsa], tetto[risorsa]),
                           "di \(risorsa) avanza al più la quota (01 §5.5.1.4)")
        }
        // Le reclute formano una formazione armata nuova, un reparto per leva, in coda.
        XCTAssertEqual(stato.forze.formazioni.count, 2)
        XCTAssertEqual(stato.forze.formazioni[1],
                       FormazioneDelRegno(categoria: .armato, composizione: [
                           Reparto(archetipo: "fanteria_leggera", atomi: 6),
                           Reparto(archetipo: "fanteria_pesante", atomi: 8)]))
        guard case .primaveraCominciata(let anno, let perduto, let pronti)? = eventi.first else {
            return XCTFail("la primavera si dichiara con un evento")
        }
        XCTAssertEqual(anno, 2)
        XCTAssertEqual(perduto[.denaro], prima[.denaro] - 16)
        XCTAssertEqual(pronti, ["leva_fanteria_leggera", "leva_fanteria_pesante"])

        // Il registro della patria: soltanto ciò che il giocatore non ha deciso (01 §5.17.1).
        XCTAssertEqual(stato.registro.map(\.fatto), [
            .campagnaConclusa(fronte: "guado", modo: .annientamento, vincitore: .giocatore),
            .invernoCominciato,
            .primaveraCominciata(eccedenzaPerduta: true),
            .lavoroPronto(voce: "leva_fanteria_leggera"),
            .lavoroPronto(voce: "leva_fanteria_pesante"),
        ])
        XCTAssertEqual(stato.registro.map(\.stagione), [.estate, .inverno, .primavera, .primavera, .primavera])
        XCTAssertEqual(stato.registro.map(\.anno), [1, 1, 2, 2, 2])
    }

    func test_01_5_5_1_4_il_riporto_si_calcola_sull_entrata_e_non_su_cio_che_era_riportato() throws {
        var stato = try motore.statoIniziale()
        esegui(.attendiInverno, &stato)
        for _ in 0..<MomentoDellAnno.stazioniInvernali { esegui(.prosegui, &stato) }
        // Entrata 105: tetto 10. Il saldo era 115: restano 10, non 11 (un decimo di 115).
        XCTAssertEqual(stato.riserve[.denaro], 10)
        XCTAssertEqual(stato.riserve[.animali], 0, "un decimo di 9, troncato, è zero: non avanza nulla")
        XCTAssertEqual(stato.riserve[.materiale], 3)
    }

    func test_l_esito_di_un_altra_campagna_non_e_accettato() throws {
        var stato = try motore.statoIniziale()
        XCTAssertFalse(motore.accetta(esito(stato), stato: stato), "nessuna campagna aperta")
        esegui(.apriCampagna(fronte: "guado"), &stato)
        XCTAssertFalse(motore.accetta(esito(stato, fronte: "pianura_lunga"), stato: stato), "altro fronte")
        var annoSbagliato = stato
        annoSbagliato.anno = 2
        XCTAssertFalse(motore.accetta(esito(annoSbagliato), stato: stato), "altro anno")
    }

    func test_00_3_1_stessi_comandi_stesso_stato() throws {
        func gioca() throws -> StatoRegno {
            var stato = try motore.statoIniziale()
            esegui(.apriCampagna(fronte: "guado"), &stato)
            _ = motore.applicaEsito(esito(stato), in: &stato)
            esegui(.attendiInverno, &stato)
            esegui(.ordina(voce: "leva_fanteria_leggera"), &stato)
            for _ in 0..<MomentoDellAnno.stazioniInvernali { esegui(.prosegui, &stato) }
            return stato
        }
        let a = try gioca(), b = try gioca()
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.impronta(), b.impronta())
        var diverso = a
        diverso.riserve[.uomini] += 1
        XCTAssertNotEqual(a.impronta(), diverso.impronta(), "l'impronta distingue due stati diversi")
    }

    // MARK: - I valori di fabbrica

    func test_i_valori_di_fabbrica_danno_un_anno_giocabile() throws {
        let archetipi = Set(try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica).archetipi.keys)
        let fabbrica = MotoreRegno(valori: try CaricatoreRegno.carica(da: Contenuti.valoriDiFabbrica,
                                                                      archetipiNoti: archetipi))
        var stato = try fabbrica.statoIniziale()
        XCTAssertTrue(stato.forze.possonoCondurreCampagna)
        (stato, _) = fabbrica.applica(.attendiInverno, stato: stato)
        // Con la sola rendita, almeno una voce è acquistabile: l'inverno non è mai vuoto.
        let acquistabili = fabbrica.valori.voci.filter {
            fabbrica.valida(.ordina(voce: $0.identificatore), stato: stato).eValido
        }
        XCTAssertFalse(acquistabili.isEmpty)
        for voce in fabbrica.valori.voci {
            let costo = fabbrica.costo(di: voce)
            XCTAssertFalse(costo.sonoVuote, "\(voce.identificatore) costa qualcosa")
            print("REGNO-COSTO \(voce.identificatore) " + costo.risorseInGioco
                .map { "\($0.rawValue)=\(costo[$0])" }.joined(separator: " "))
        }
        print("REGNO-ENTRATA " + Risorsa.allCases
            .map { "\($0.rawValue)=\(fabbrica.entrata(dopo: nil)[$0])" }.joined(separator: " "))
    }
}
