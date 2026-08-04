import XCTest
import Verifica
import Motore
import Dati
import Contenuti

/// Gli invarianti della campagna, e le prove che tentano di violarli DI PROPOSITO.
///
/// Le prove scritte nello stesso momento e con la stessa testa con cui si scrive il
/// codice ne ereditano i punti ciechi, e in questo progetto tutti i difetti gravi
/// finora sono stati trovati dal titolare giocando o da una misura, mai dal collaudo
/// automatico. Per ogni invariante esiste quindi qui una coppia: la corsa vera, che
/// non deve produrre violazioni, e il MUTANTE, cioè uno stato o una transizione
/// guastati a mano, che deve produrne esattamente una. Un invariante che non si è
/// mai visto violare non è un invariante.
final class InvariantiCampagnaTest: XCTestCase {

    var valori: ValoriDiGioco!
    var valoriCampagna: ValoriCampagna!
    var motore: MotoreCampagna!
    let sonda = SondaInvariantiCampagna()

    override func setUpWithError() throws {
        valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
        valoriCampagna = try CaricatoreCampagna.carica(da: Contenuti.valoriDiFabbrica)
        motore = MotoreCampagna(valori: valori, valoriCampagna: valoriCampagna)
    }

    private func stato(gruppi: [(Int, Int)] = [(10, 6), (10, 5), (9, 6)]) throws -> StatoCampagna {
        try FabbricaCampagna.crea(
            scenario: ScenarioCampagna(mappa: "pianura_lunga",
                                       gruppiGiocatore: gruppi.map { .init(riga: $0.0, colonna: $0.1) }),
            valori: valoriCampagna)
    }

    private func descrizioni(_ violazioni: [SondaInvariantiCampagna.Violazione]) -> [String] {
        violazioni.map(\.description)
    }

    // MARK: - La corsa vera non produce violazioni

    func test_incarico_6_molte_giornate_generate_senza_alcuna_violazione() throws {
        let scenari = try ScenariCampagna.carica(da: Verifica.Ambiente.scenariCampagnaDiFabbrica)
        let banco = BancoCampagna(motore: motore, valoriCampagna: valoriCampagna, scenari: scenari)
        var giornateTotali = 0, ordiniTotali = 0
        for voce in scenari.scenari {
            let corsa = try banco.corri(voce, giornate: scenari.giornateGenerate)
            XCTAssertEqual(corsa.violazioni, [],
                           "violazioni nello scenario \(corsa.identificatore)")
            XCTAssertEqual(corsa.giornate, scenari.giornateGenerate,
                           "le giornate generate sono quelle chieste")
            giornateTotali += corsa.giornate
            ordiniTotali += corsa.ordini
        }
        XCTAssertGreaterThan(giornateTotali, 100, "la generazione copre molte giornate")
        XCTAssertGreaterThan(ordiniTotali, 300)
    }

    func test_05_12_3_1_due_corse_sugli_stessi_dati_danno_lo_stesso_identico_esito() throws {
        let scenari = try ScenariCampagna.carica(da: Verifica.Ambiente.scenariCampagnaDiFabbrica)
        let banco = BancoCampagna(motore: motore, valoriCampagna: valoriCampagna, scenari: scenari)
        for voce in scenari.scenari {
            let una = try banco.corri(voce, giornate: 12)
            let due = try banco.corri(voce, giornate: 12)
            XCTAssertEqual(una.improntaFinale, due.improntaFinale,
                           "la campagna non contiene alcuna estrazione del caso (RDA-59)")
            XCTAssertEqual(una.ordini, due.ordini)
        }
    }

    // MARK: - Mutanti: ogni invariante si è visto violare

    func test_mutante_un_gruppo_in_due_caselle_viene_visto() throws {
        var guasto = try stato(gruppi: [(10, 6), (10, 5)])
        XCTAssertEqual(sonda.controlla(stato: guasto), [], "lo stato sano non produce violazioni")
        // Si duplica un gruppo su una seconda casella, con lo STESSO identificatore.
        let primo = guasto.gruppiOrdinati[0]
        guasto.gruppi[IdGruppo(99)] = Gruppo(id: primo.id, parte: .giocatore, nome: primo.nome,
                                             posizione: Cella(riga: 8, colonna: 6), azioneSpesa: false)
        XCTAssertTrue(descrizioni(sonda.controlla(stato: guasto))
            .contains { $0.contains("gruppo_in_piu_caselle:gruppo=1:caselle=2") },
            "la sonda non vede un gruppo in due caselle")
    }

    func test_mutante_due_gruppi_nella_stessa_casella_vengono_visti() throws {
        var guasto = try stato(gruppi: [(10, 6), (10, 5)])
        let secondo = guasto.gruppiOrdinati[1]
        guasto.gruppi[secondo.id]!.posizione = Cella(riga: 10, colonna: 6)
        XCTAssertTrue(descrizioni(sonda.controlla(stato: guasto))
            .contains { $0.contains("due_gruppi_stessa_casella:riga=10:casella=6") },
            "la sonda non vede due gruppi sulla stessa casella (01 §5.6.0.2)")
    }

    func test_mutante_un_gruppo_fuori_dalla_mappa_viene_visto() throws {
        var guasto = try stato(gruppi: [(10, 6)])
        let id = guasto.gruppiOrdinati[0].id
        guasto.gruppi[id]!.posizione = Cella(riga: 99, colonna: 99)
        XCTAssertTrue(descrizioni(sonda.controlla(stato: guasto))
            .contains { $0.hasPrefix("gruppo_fuori_dalla_mappa") })
    }

    func test_mutante_un_gruppo_che_agisce_due_volte_viene_visto() throws {
        var prima = try stato(gruppi: [(10, 6), (10, 5)])
        let id = prima.gruppiOrdinati[0].id
        // La transizione sana: il gruppo non aveva ancora agito.
        let (dopoSano, eventiSani) = motore.applica(.presidio(gruppo: id), parte: .giocatore, stato: prima)
        XCTAssertEqual(sonda.controlla(prima: prima, comando: .presidio(gruppo: id),
                                       dopo: dopoSano, eventi: eventiSani,
                                       adiacenti: prima.griglia.adiacenti), [])
        // Il mutante: lo stesso comando applicato a un gruppo che aveva GIÀ agito.
        prima.gruppi[id]!.azioneSpesa = true
        XCTAssertTrue(descrizioni(sonda.controlla(prima: prima, comando: .presidio(gruppo: id),
                                                  dopo: dopoSano, eventi: eventiSani,
                                                  adiacenti: prima.griglia.adiacenti))
            .contains { $0.hasPrefix("azione_spesa_due_volte") })
    }

    func test_mutante_un_movimento_fra_caselle_non_adiacenti_viene_visto() throws {
        let prima = try stato(gruppi: [(10, 6)])
        let id = prima.gruppiOrdinati[0].id
        let lontana = Cella(riga: 5, colonna: 1)
        var dopo = prima
        dopo.gruppi[id]!.posizione = lontana
        dopo.gruppi[id]!.azioneSpesa = true
        let violazioni = sonda.controlla(prima: prima, comando: .marcia(gruppo: id, a: lontana),
                                         dopo: dopo, eventi: [], adiacenti: prima.griglia.adiacenti)
        XCTAssertTrue(descrizioni(violazioni).contains { $0 == "movimento_non_adiacente:da=10-6:a=5-1" },
                      "la sonda non vede un movimento fra caselle non adiacenti")
    }

    func test_mutante_il_giorno_che_resta_fermo_alla_chiusura_viene_visto() throws {
        let prima = try stato(gruppi: [(10, 6)])
        let id = prima.gruppiOrdinati[0].id
        var dopo = prima
        dopo.gruppi[id]!.azioneSpesa = false // come se la giornata si fosse chiusa
        // ...ma il giorno non è avanzato: è precisamente il difetto da vedere.
        let eventi: [EventoCampagna] = [.giornataChiusa(giorno: 1), .giornataAperta(giorno: 1)]
        XCTAssertTrue(descrizioni(sonda.controlla(prima: prima, comando: .presidio(gruppo: id),
                                                  dopo: dopo, eventi: eventi,
                                                  adiacenti: prima.griglia.adiacenti))
            .contains { $0 == "giorno_non_avanzato:prima=1:dopo=1" })
    }

    func test_mutante_il_giorno_che_torna_indietro_viene_visto() throws {
        let prima = try stato(gruppi: [(10, 6)])
        let id = prima.gruppiOrdinati[0].id
        var dopo = prima
        dopo.giorno = prima.giorno - 1
        let eventi: [EventoCampagna] = [.giornataChiusa(giorno: 1), .giornataAperta(giorno: 0)]
        XCTAssertTrue(descrizioni(sonda.controlla(prima: prima, comando: .presidio(gruppo: id),
                                                  dopo: dopo, eventi: eventi,
                                                  adiacenti: prima.griglia.adiacenti))
            .contains { $0 == "giorno_non_avanzato:prima=1:dopo=0" })
    }

    func test_mutante_le_azioni_non_azzerate_alla_chiusura_vengono_viste() throws {
        let prima = try stato(gruppi: [(10, 6), (10, 5)])
        let id = prima.gruppiOrdinati[0].id
        var dopo = prima
        dopo.giorno = prima.giorno + 1
        for gruppo in dopo.gruppiOrdinati { dopo.gruppi[gruppo.id]!.azioneSpesa = true }
        let eventi: [EventoCampagna] = [.giornataChiusa(giorno: 1), .giornataAperta(giorno: 2)]
        let violazioni = descrizioni(sonda.controlla(prima: prima, comando: .presidio(gruppo: id),
                                                     dopo: dopo, eventi: eventi,
                                                     adiacenti: prima.griglia.adiacenti))
        XCTAssertEqual(violazioni.filter { $0.hasPrefix("azione_non_azzerata") }.count, 2)
    }

    func test_mutante_un_gruppo_che_agisce_da_se_viene_visto() throws {
        // Nessuna azione automatica: nessun gruppo può spendere l'azione senza
        // averne ricevuto l'ordine (incarico, sezione 2).
        let prima = try stato(gruppi: [(10, 6), (10, 5), (9, 6)])
        let id = prima.gruppiOrdinati[0].id
        var dopo = prima
        dopo.gruppi[id]!.azioneSpesa = true
        dopo.gruppi[prima.gruppiOrdinati[1].id]!.azioneSpesa = true // ha agito da sé
        XCTAssertTrue(descrizioni(sonda.controlla(prima: prima, comando: .presidio(gruppo: id),
                                                  dopo: dopo, eventi: [],
                                                  adiacenti: prima.griglia.adiacenti))
            .contains { $0.hasPrefix("gruppo_ha_agito_da_se") })
    }

    // MARK: - Mutanti del salto diretto

    func test_mutante_un_salto_che_dimentica_un_gruppo_viene_visto() throws {
        let stato = try stato(gruppi: [(10, 6), (10, 5), (9, 6)])
        let vista = VistaCampagna(motore: motore, stato: stato, parte: .giocatore)
        let banco = try banchino()
        let sana = banco.sequenzaDelSalto(vista, stato)
        XCTAssertEqual(sonda.controllaSalto(stato: stato, sequenza: sana), [],
                       "la sequenza vera non dimentica nulla")
        let monca = Array(sana.dropLast())
        XCTAssertTrue(descrizioni(sonda.controllaSalto(stato: stato, sequenza: monca))
            .contains { $0.hasPrefix("salto_ha_dimenticato") })
    }

    func test_mutante_un_salto_che_propone_chi_ha_gia_agito_viene_visto() throws {
        var stato = try stato(gruppi: [(10, 6), (10, 5)])
        let id = stato.gruppiOrdinati[0].id
        stato.gruppi[id]!.azioneSpesa = true
        let tutti = stato.gruppiOrdinati.map(\.id) // comprende chi ha già agito
        XCTAssertTrue(descrizioni(sonda.controllaSalto(stato: stato, sequenza: tutti))
            .contains { $0.hasPrefix("salto_ha_proposto_chi_ha_agito") })
    }

    func test_mutante_un_salto_che_ripete_un_gruppo_viene_visto() throws {
        let stato = try stato(gruppi: [(10, 6), (10, 5)])
        let primo = stato.gruppiOrdinati[0].id
        let secondo = stato.gruppiOrdinati[1].id
        XCTAssertTrue(descrizioni(sonda.controllaSalto(stato: stato,
                                                       sequenza: [primo, primo, secondo]))
            .contains { $0.hasPrefix("salto_ha_ripetuto") })
    }

    // MARK: - Mutanti della percorribilità

    func test_mutante_una_casella_percorribile_irraggiungibile_viene_vista() throws {
        let griglia = GrigliaCampagna(righe: 6, colonne: 6)
        XCTAssertEqual(sonda.controllaRaggiungibilita(griglia: griglia,
                                                      da: Cella(riga: 1, colonna: 1),
                                                      vicini: griglia.vicini), [],
                       "la mappa vera è interamente percorribile (01 §5.1.2)")
        // Adiacenza guasta: si tolgono i passi verso sud, e metà mappa sparisce.
        let mutila: (Cella) -> [Cella] = { casella in
            griglia.vicini(di: casella).filter { $0.riga <= casella.riga }
        }
        let violazioni = sonda.controllaRaggiungibilita(griglia: griglia,
                                                        da: Cella(riga: 1, colonna: 1),
                                                        vicini: mutila)
        XCTAssertEqual(violazioni.count, 30, "cinque righe di sei caselle diventano irraggiungibili")
        XCTAssertTrue(descrizioni(violazioni).contains { $0.hasPrefix("casella_irraggiungibile") })
    }

    func test_mutante_un_registro_fuori_ordine_viene_visto() throws {
        var guasto = try stato(gruppi: [(10, 6)])
        guasto.registro.append(VoceRegistro(numero: 1, giorno: 5, fatto: .giornataAperta, luogo: nil))
        guasto.registro.append(VoceRegistro(numero: 2, giorno: 2, fatto: .giornataAperta, luogo: nil))
        XCTAssertTrue(descrizioni(sonda.controlla(stato: guasto))
            .contains { $0.hasPrefix("registro_fuori_ordine") })
    }

    // MARK: - Attrezzo

    private func banchino() throws -> BancoCampagna {
        BancoCampagna(motore: motore, valoriCampagna: valoriCampagna,
                      scenari: try ScenariCampagna.carica(da: Verifica.Ambiente.scenariCampagnaDiFabbrica))
    }
}
