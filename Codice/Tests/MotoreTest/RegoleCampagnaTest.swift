import XCTest
import Motore
import Dati
import Contenuti

/// Collaudo del Motore di campagna (05 §14.2): ogni prova cita per numero la regola
/// che verifica. Le regole di questa unità sono la mappa (01 §5.1), la casella e la
/// sua qualificazione (01 §5.1.2, §5.1.3), la giornata a un'azione per gruppo
/// (01 §5.6, §5.6.0.5), la chiusura automatica del turno (01 §5.6.0.6), gli stati
/// del gruppo (01 §5.16.1) e il registro (01 §5.17).
final class RegoleCampagnaTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    var motore: MotoreCampagna!

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
    }

    // MARK: - Attrezzi

    func scenario(mappa: String = "pianura_lunga",
                  gruppi: [(Int, Int)] = [(10, 6), (10, 5), (9, 6)]) -> ScenarioCampagna {
        ScenarioCampagna(mappa: mappa,
                         gruppiGiocatore: gruppi.map { .init(riga: $0.0, colonna: $0.1) })
    }

    func crea(_ s: ScenarioCampagna) throws -> StatoCampagna {
        try FabbricaCampagna.crea(scenario: s, valori: valoriCampagna)
    }

    @discardableResult
    func esegui(_ comando: ComandoCampagna, _ stato: inout StatoCampagna,
                file: StaticString = #filePath, linea: UInt = #line) -> [EventoCampagna] {
        let esito = motore.valida(comando, parte: .giocatore, stato: stato)
        XCTAssertTrue(esito.eValido, "comando non valido: \(String(describing: esito.motivo))",
                      file: file, line: linea)
        let (nuovo, eventi) = motore.applica(comando, parte: .giocatore, stato: stato)
        stato = nuovo
        return eventi
    }

    // MARK: - 01 §5.1 — la mappa e l'adiacenza ortogonale

    func test_01_5_1_adiacenza_ortogonale_quattro_vicini_senza_diagonali() throws {
        let griglia = GrigliaCampagna(righe: 10, colonne: 10)
        let centro = Cella(riga: 5, colonna: 5)
        XCTAssertEqual(griglia.vicini(di: centro),
                       [Cella(riga: 5, colonna: 6), Cella(riga: 5, colonna: 4),
                        Cella(riga: 4, colonna: 5), Cella(riga: 6, colonna: 5)],
                       "quattro vicini in ordine fisso: est, ovest, nord, sud (02 §2.3)")
        for diagonale in [Cella(riga: 4, colonna: 4), Cella(riga: 4, colonna: 6),
                          Cella(riga: 6, colonna: 4), Cella(riga: 6, colonna: 6)] {
            XCTAssertFalse(griglia.adiacenti(centro, diagonale), "nessuna diagonale")
        }
    }

    func test_01_5_1_i_bordi_hanno_meno_vicini_e_nessuno_esce_dalla_mappa() throws {
        let griglia = GrigliaCampagna(righe: 4, colonne: 4)
        XCTAssertEqual(griglia.vicini(di: Cella(riga: 1, colonna: 1)).count, 2, "angolo: due vicini")
        XCTAssertEqual(griglia.vicini(di: Cella(riga: 1, colonna: 2)).count, 3, "bordo: tre vicini")
        for casella in griglia.tutteLeCaselle {
            for vicino in griglia.vicini(di: casella) {
                XCTAssertTrue(griglia.contiene(vicino), "nessun vicino fuori dai confini")
            }
        }
    }

    func test_01_5_1_i_tre_formati_stanno_nei_dati_e_non_nel_codice() throws {
        // Le dimensioni non compaiono nel programma: si leggono dai valori (00 §13.1).
        let identificatori = Set(valoriCampagna.formatiMappa.keys)
        XCTAssertEqual(identificatori.count, 3, "tre formati fissi (01 §5.1)")
        let lati = valoriCampagna.formatiMappa.values
            .map { [$0.righe, $0.colonne] }.sorted { $0[0] < $1[0] }
        XCTAssertEqual(lati, [[4, 4], [6, 6], [10, 10]],
                       "quattro per quattro, sei per sei, dieci per dieci (01 §5.1)")
    }

    func test_00_11_5_ordine_di_lettura_da_ovest_a_est_e_dall_alto_in_basso() throws {
        let caselle = GrigliaCampagna(righe: 3, colonne: 3).tutteLeCaselle
        XCTAssertEqual(caselle.first, Cella(riga: 1, colonna: 1))
        XCTAssertEqual(caselle[1], Cella(riga: 1, colonna: 2))
        XCTAssertEqual(caselle[3], Cella(riga: 2, colonna: 1))
        XCTAssertEqual(caselle.last, Cella(riga: 3, colonna: 3))
        XCTAssertEqual(caselle, caselle.sorted(), "l'ordine di lettura è l'ordine della cella")
    }

    // MARK: - 01 §5.1.2, §5.1.3 — qualificazione delle caselle e strettoia

    func test_01_5_1_2_la_mappa_e_interamente_percorribile() throws {
        // Non esistono caselle interdette: da ogni casella si raggiunge ogni altra.
        for identificatore in valoriCampagna.mappe.keys.sorted() {
            let stato = try crea(ScenarioCampagna(
                mappa: identificatore, gruppiGiocatore: [.init(riga: 1, colonna: 1)]))
            let griglia = stato.griglia
            var visitate: Set<Cella> = [Cella(riga: 1, colonna: 1)]
            var fronte = [Cella(riga: 1, colonna: 1)]
            while let corrente = fronte.popLast() {
                for vicino in griglia.vicini(di: corrente) where visitate.insert(vicino).inserted {
                    fronte.append(vicino)
                }
            }
            XCTAssertEqual(visitate.count, griglia.righe * griglia.colonne,
                           "ogni casella dichiarata percorribile è raggiungibile: mappa \(identificatore)")
        }
    }

    func test_01_5_1_3_la_strettoia_e_al_piu_una_e_non_esiste_in_ogni_mappa() throws {
        let conStrettoia = valoriCampagna.mappe.values.filter { $0.strettoia != nil }
        let senzaStrettoia = valoriCampagna.mappe.values.filter { $0.strettoia == nil }
        XCTAssertFalse(conStrettoia.isEmpty, "esiste una mappa con strettoia")
        XCTAssertFalse(senzaStrettoia.isEmpty, "esiste una mappa senza strettoia: la rarità è voluta")
        // La forma del campo impone già l'unicità: un solo valore facoltativo.
        let stato = try crea(scenario(mappa: "istmo", gruppi: [(6, 3)]))
        let strettoie = stato.griglia.tutteLeCaselle.filter { stato.mappa.strettoia == $0 }
        XCTAssertEqual(strettoie.count, 1, "al più una strettoia per mappa")
    }

    func test_01_5_1_2_la_casella_dichiara_terreno_e_strada() throws {
        let stato = try crea(scenario(mappa: "istmo", gruppi: [(6, 3)]))
        XCTAssertEqual(stato.mappa.terreno(di: Cella(riga: 3, colonna: 4)), .acqua)
        XCTAssertEqual(stato.mappa.terreno(di: Cella(riga: 4, colonna: 2)), .bosco)
        XCTAssertEqual(stato.mappa.strada(di: Cella(riga: 2, colonna: 3)), .lastricata)
        XCTAssertEqual(stato.mappa.strada(di: Cella(riga: 5, colonna: 4)), .sterrata)
        // La condizione ordinaria non si dichiara (02 §8.7.1): è il valore di ripiego.
        XCTAssertEqual(stato.mappa.terreno(di: Cella(riga: 1, colonna: 1)), .aperto)
        XCTAssertEqual(stato.mappa.strada(di: Cella(riga: 1, colonna: 1)), .nessuna)
    }

    func test_01_5_14_3_2_ciascuna_parte_ha_il_quartier_generale_in_ultima_riga() throws {
        for (identificatore, mappa) in valoriCampagna.mappe.sorted(by: { $0.key < $1.key }) {
            let formato = valoriCampagna.formatiMappa[mappa.formato]!
            XCTAssertEqual(mappa.quartierGenerali.avversario.riga, 1, "mappa \(identificatore)")
            XCTAssertEqual(mappa.quartierGenerali.giocatore.riga, formato.righe,
                           "mappa \(identificatore)")
        }
    }

    // MARK: - 01 §5.6 — la giornata: un'azione per gruppo

    func test_01_5_6_ogni_gruppo_dispone_di_una_sola_azione_al_giorno() throws {
        var stato = try crea(scenario())
        let id = stato.gruppiOrdinati[0].id
        esegui(.presidio(gruppo: id), &stato)
        XCTAssertTrue(stato.gruppi[id]!.azioneSpesa)
        XCTAssertEqual(motore.valida(.presidio(gruppo: id), parte: .giocatore, stato: stato).motivo,
                       .azioneGiaSpesa, "un gruppo non agisce due volte nella stessa giornata")
        XCTAssertEqual(motore.valida(.marcia(gruppo: id, a: Cella(riga: 9, colonna: 6)),
                                     parte: .giocatore, stato: stato).motivo,
                       .azioneGiaSpesa, "vale per qualunque azione, non solo per quella già scelta")
    }

    func test_01_5_6_0_5_la_marcia_consuma_l_intera_giornata_del_gruppo() throws {
        var stato = try crea(scenario())
        let id = stato.gruppiOrdinati[0].id
        let partenza = stato.gruppi[id]!.posizione
        esegui(.marcia(gruppo: id, a: Cella(riga: 10, colonna: 7)), &stato)
        XCTAssertEqual(stato.gruppi[id]!.posizione, Cella(riga: 10, colonna: 7))
        XCTAssertNotEqual(stato.gruppi[id]!.posizione, partenza)
        XCTAssertTrue(stato.gruppi[id]!.azioneSpesa)
    }

    func test_01_5_6_3_1_non_esistono_percorsi_di_piu_caselle_in_un_turno() throws {
        let stato = try crea(scenario())
        let id = stato.gruppiOrdinati[0].id
        let posizione = stato.gruppi[id]!.posizione
        let lontana = Cella(riga: posizione.riga - 2, colonna: posizione.colonna)
        XCTAssertEqual(motore.valida(.marcia(gruppo: id, a: lontana),
                                     parte: .giocatore, stato: stato).motivo, .nonAdiacente)
        let diagonale = Cella(riga: posizione.riga - 1, colonna: posizione.colonna - 1)
        XCTAssertEqual(motore.valida(.marcia(gruppo: id, a: diagonale),
                                     parte: .giocatore, stato: stato).motivo, .nonAdiacente,
                       "la diagonale non è adiacenza (01 §5.1)")
    }

    func test_01_5_6_0_2_ogni_casella_ospita_al_massimo_una_propria_formazione() throws {
        var stato = try crea(scenario(gruppi: [(10, 6), (10, 5)]))
        let primo = stato.gruppiOrdinati[0].id
        let secondo = stato.gruppiOrdinati[1].id
        let dove = stato.gruppi[secondo]!.posizione
        XCTAssertEqual(motore.valida(.marcia(gruppo: primo, a: dove),
                                     parte: .giocatore, stato: stato).motivo, .occupata)
        // Liberata la casella, la marcia diventa valida: il divieto è di posizione.
        esegui(.marcia(gruppo: secondo, a: Cella(riga: 9, colonna: 5)), &stato)
        XCTAssertTrue(motore.valida(.marcia(gruppo: primo, a: dove),
                                    parte: .giocatore, stato: stato).eValido)
    }

    func test_01_5_1_la_marcia_fuori_mappa_e_respinta_con_il_proprio_motivo() throws {
        let stato = try crea(scenario(mappa: "guado", gruppi: [(4, 2)]))
        let id = stato.gruppiOrdinati[0].id
        XCTAssertEqual(motore.valida(.marcia(gruppo: id, a: Cella(riga: 5, colonna: 2)),
                                     parte: .giocatore, stato: stato).motivo, .fuoriMappa)
    }

    func test_05_3_2_ogni_comando_non_valido_produce_un_motivo_del_tipo_chiuso() throws {
        let stato = try crea(scenario())
        // Un gruppo inesistente e uno dell'altra parte producono lo stesso motivo chiuso.
        XCTAssertEqual(motore.valida(.presidio(gruppo: IdGruppo(999)),
                                     parte: .giocatore, stato: stato).motivo, .gruppoIgnoto)
        XCTAssertEqual(motore.valida(.presidio(gruppo: stato.gruppiOrdinati[0].id),
                                     parte: .avversario, stato: stato).motivo, .gruppoIgnoto)
    }

    // MARK: - 01 §5.6.0.6 — chiusura automatica del turno

    func test_01_5_6_0_6_la_giornata_si_chiude_quando_tutti_i_gruppi_hanno_agito() throws {
        var stato = try crea(scenario(gruppi: [(10, 6), (10, 5), (9, 6)]))
        let ids = stato.gruppiOrdinati.map(\.id)
        XCTAssertEqual(stato.giorno, 1)
        var eventi = esegui(.presidio(gruppo: ids[0]), &stato)
        XCTAssertFalse(eventi.contains(.giornataChiusa(giorno: 1)), "non basta un gruppo")
        eventi = esegui(.presidio(gruppo: ids[1]), &stato)
        XCTAssertFalse(eventi.contains(.giornataChiusa(giorno: 1)), "non bastano due gruppi")
        XCTAssertEqual(stato.giorno, 1, "il giorno non avanza finché qualcuno attende")
        eventi = esegui(.presidio(gruppo: ids[2]), &stato)
        XCTAssertTrue(eventi.contains(.giornataChiusa(giorno: 1)))
        XCTAssertTrue(eventi.contains(.giornataAperta(giorno: 2)))
        XCTAssertEqual(stato.giorno, 2, "il contatore dei giorni avanza")
        XCTAssertTrue(stato.gruppi.values.allSatisfy { !$0.azioneSpesa },
                      "alla giornata nuova tutti tornano in attesa")
    }

    func test_01_5_6_0_6_non_esiste_alcun_comando_di_fine_giornata() throws {
        // L'elenco dei comandi di campagna di questa unità è chiuso a due voci, e
        // nessuna delle due chiude la giornata: la chiusura è conseguenza degli
        // ordini, mai un comando a sé (01 §5.6.0.6).
        var stato = try crea(scenario(gruppi: [(10, 6)]))
        let id = stato.gruppiOrdinati[0].id
        let eventi = esegui(.presidio(gruppo: id), &stato)
        XCTAssertEqual(eventi.count, 3, "presidio, chiusura, apertura: nient'altro accade da sé")
    }

    func test_01_5_6_0_6_stare_fermi_e_un_azione_ordinabile_e_non_un_omissione() throws {
        var stato = try crea(scenario(gruppi: [(10, 6), (10, 5)]))
        let ids = stato.gruppiOrdinati.map(\.id)
        XCTAssertEqual(stato.gruppiInAttesa().count, 2)
        esegui(.presidio(gruppo: ids[0]), &stato)
        XCTAssertEqual(stato.gruppiInAttesa().count, 1,
                       "un gruppo che ha presidiato ha agito: non attende più una decisione")
    }

    // MARK: - 01 §5.16.1 — gli stati del gruppo, ridotti a ciò che esiste

    func test_01_5_16_1_il_gruppo_dichiara_il_proprio_stato_con_il_vocabolario_ridotto() throws {
        var stato = try crea(scenario(gruppi: [(10, 6), (10, 5)]))
        let id = stato.gruppiOrdinati[0].id
        XCTAssertEqual(stato.gruppi[id]!.statoDichiarato, .inAttesa)
        esegui(.presidio(gruppo: id), &stato)
        XCTAssertEqual(stato.gruppi[id]!.statoDichiarato, .haAgito)
        // Il vocabolario di questa unità è chiuso a due termini: gli altri stati di
        // 02 §4.4.5 appartengono alle regole che li producono e non esistono qui.
        XCTAssertEqual(StatoGruppo.allCases.count, 2)
    }

    func test_01_5_6_0_4_ogni_gruppo_riceve_un_nome_proprio_stabile_e_unico() throws {
        let stato = try crea(scenario(gruppi: [(10, 6), (10, 5), (9, 6), (9, 5)]))
        let indici = stato.gruppiOrdinati.map(\.indiceNome)
        XCTAssertEqual(Set(indici).count, indici.count, "i nomi sono unici nella campagna")
        for indice in indici {
            XCTAssertTrue(valoriCampagna.nomiGruppi.indices.contains(indice),
                          "il nome viene dalla lista chiusa dei dati")
        }
    }

    // MARK: - 01 §5.17 — il registro

    func test_01_5_17_il_registro_annota_i_fatti_non_decisi_dal_giocatore() throws {
        var stato = try crea(scenario(gruppi: [(10, 6)]))
        XCTAssertEqual(stato.registro.count, 1, "l'apertura del primo giorno è già annotata")
        XCTAssertEqual(stato.registro[0].giorno, 1)
        let id = stato.gruppiOrdinati[0].id
        esegui(.presidio(gruppo: id), &stato)
        XCTAssertEqual(stato.registro.count, 2, "l'apertura della giornata nuova è un fatto")
        XCTAssertEqual(stato.registro[1].giorno, 2, "la voce dichiara il giorno cui si riferisce")
        // Gli ordini del giocatore non vi entrano (01 §5.17.1).
        XCTAssertTrue(stato.registro.allSatisfy { $0.fatto == .giornataAperta })
    }

    func test_02_6_6_il_registro_si_legge_dal_piu_recente_al_meno_recente() throws {
        var stato = try crea(scenario(gruppi: [(10, 6)]))
        let id = stato.gruppiOrdinati[0].id
        for _ in 0..<3 { esegui(.presidio(gruppo: id), &stato) }
        let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
        let giorni = vista.registroDalPiuRecente.map(\.giorno)
        XCTAssertEqual(giorni, giorni.sorted(by: >), "dal più recente al meno recente")
        XCTAssertEqual(giorni.first, stato.giorno)
    }

    // MARK: - 00 §3.1 — determinismo

    func test_00_3_1_stesso_comando_su_stesso_stato_stesso_esito() throws {
        let stato = try crea(scenario())
        let id = stato.gruppiOrdinati[0].id
        let comando = ComandoCampagna.marcia(gruppo: id, a: Cella(riga: 10, colonna: 7))
        let (unoStato, unoEventi) = motore.applica(comando, parte: .giocatore, stato: stato)
        let (dueStato, dueEventi) = motore.applica(comando, parte: .giocatore, stato: stato)
        XCTAssertEqual(unoStato.impronta(), dueStato.impronta())
        XCTAssertEqual(unoEventi, dueEventi)
    }

    func test_05_2_9_l_impronta_distingue_stati_che_si_comportano_diversamente() throws {
        let stato = try crea(scenario(gruppi: [(10, 6), (10, 5)]))
        let ids = stato.gruppiOrdinati.map(\.id)
        let (a, _) = motore.applica(.marcia(gruppo: ids[0], a: Cella(riga: 9, colonna: 6)),
                                    parte: .giocatore, stato: stato)
        let (b, _) = motore.applica(.marcia(gruppo: ids[0], a: Cella(riga: 10, colonna: 7)),
                                    parte: .giocatore, stato: stato)
        XCTAssertNotEqual(a.impronta(), b.impronta(), "posizioni diverse, impronte diverse")
        let (c, _) = motore.applica(.presidio(gruppo: ids[0]), parte: .giocatore, stato: stato)
        XCTAssertNotEqual(c.impronta(), stato.impronta(), "l'azione spesa entra nell'impronta")
    }

    // MARK: - 01 §5.16 — il salto diretto al prossimo gruppo in attesa

    func test_01_5_16_il_salto_diretto_percorre_tutti_i_gruppi_in_attesa() throws {
        let stato = try crea(scenario(gruppi: [(10, 6), (10, 5), (9, 6), (9, 5)]))
        let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
        var visitati: [Cella] = []
        var corrente: Cella? = nil
        for _ in 0..<4 {
            guard let prossimo = vista.prossimoGruppoInAttesa(dopo: corrente) else {
                return XCTFail("il salto ha dimenticato un gruppo in attesa")
            }
            visitati.append(prossimo.posizione)
            corrente = prossimo.posizione
        }
        XCTAssertEqual(Set(visitati).count, 4, "nessun gruppo dimenticato e nessuno ripetuto")
        XCTAssertEqual(visitati, visitati.sorted(), "si percorre nell'ordine di lettura")
        // Chiuso il giro, si riparte dal primo: non ci si ferma sull'ultimo.
        XCTAssertEqual(vista.prossimoGruppoInAttesa(dopo: visitati.last)?.posizione, visitati.first)
    }

    func test_01_5_16_il_salto_non_propone_mai_un_gruppo_che_ha_gia_agito() throws {
        var stato = try crea(scenario(gruppi: [(10, 6), (10, 5), (9, 6)]))
        let primo = stato.gruppiOrdinati[0].id
        esegui(.presidio(gruppo: primo), &stato)
        let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
        let posizioneSpesa = stato.gruppi[primo]!.posizione
        var corrente: Cella? = nil
        for _ in 0..<6 {
            guard let prossimo = vista.prossimoGruppoInAttesa(dopo: corrente) else { break }
            XCTAssertNotEqual(prossimo.posizione, posizioneSpesa,
                              "proposto un gruppo che ha già agito")
            corrente = prossimo.posizione
        }
    }

    // MARK: - 02 §6.5.1.3 — l'informazione di stato

    func test_02_6_5_1_3_l_informazione_di_stato_dichiara_giorno_e_gruppi_che_hanno_agito() throws {
        var stato = try crea(scenario(gruppi: [(10, 6), (10, 5), (9, 6)]))
        func info() -> VistaCampagna.InformazioneDiStato {
            VistaCampagna(motore: motore, stato: stato, parte: .giocatore).informazioneDiStato
        }
        XCTAssertEqual(info().giorno, 1)
        XCTAssertEqual(info().gruppiCheHannoAgito, 0)
        XCTAssertEqual(info().gruppiTotali, 3)
        esegui(.presidio(gruppo: stato.gruppiOrdinati[0].id), &stato)
        XCTAssertEqual(info().gruppiCheHannoAgito, 1)
        XCTAssertEqual(info().gruppiTotali, 3)
    }
}
