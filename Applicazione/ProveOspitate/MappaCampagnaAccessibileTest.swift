import XCTest
import Dati
import Motore
@testable import WarSense

/// Raggiungibilità reale della mappa di campagna (00 §1.2, 02 §2.8): non basta che
/// un elemento esista con nome e ruolo, deve comparire nell'ordine di lettura
/// effettivo, avere una cornice non degenere e giacere dentro lo schermo o in un
/// contenitore scorrevole. È la stessa prova che la fase B ha dovuto introdurre
/// dopo il primo collaudo su dispositivo (scostamento S3): la si applica alla
/// mappa fin dal primo giorno, invece che dopo il primo difetto.
@MainActor
final class MappaCampagnaAccessibileTest: XCTestCase {

    /// Lo schermo piccolo di riferimento: il caso peggiore per lo spazio verticale.
    private static let schermoPiccolo = CGRect(x: 0, y: 0, width: 375, height: 667)

    private func mappaAperta(taglia: PartitaCampagna.Taglia = .grande,
                             in cornice: CGRect = schermoPiccolo) async throws
        -> (SchermataMappaCampagna, UIWindow, Ambiente) {
        let ambiente = try Ambiente()
        let partita = try await PartitaCampagna(nuova: ambiente, taglia: taglia)
        let schermata = SchermataMappaCampagna(partita: partita)
        let finestra = UIWindow(frame: cornice)
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        for _ in 0..<200 where schermata.elementiPerProva.isEmpty {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        try await Task.sleep(nanoseconds: 200_000_000)
        finestra.layoutIfNeeded()
        // Una schermata lasciata con un avviso presentato impedisce le presentazioni
        // delle prove successive: si congeda tutto alla fine di ciascuna.
        addTeardownBlock { @MainActor in
            schermata.presentedViewController?.dismiss(animated: false)
            finestra.isHidden = true
            finestra.rootViewController = nil
        }
        return (schermata, finestra, ambiente)
    }

    func test_00_1_2_ogni_elemento_della_mappa_e_agganciabile_sullo_schermo_piccolo() async throws {
        let (schermata, finestra, _) = try await mappaAperta()
        let ordine = LettoreAccessibilita.ordineDiLettura(radice: schermata.view!)
        var difetti: [String] = []
        for elemento in ordine {
            let etichetta = LettoreAccessibilita.etichetta(di: elemento)
            if etichetta.isEmpty { difetti.append("elemento senza etichetta: \(type(of: elemento))") }
            if let motivo = LettoreAccessibilita.motivoNonAgganciabile(elemento, schermo: finestra.bounds) {
                difetti.append("«\(etichetta)»: \(motivo)")
            }
        }
        XCTAssertTrue(difetti.isEmpty,
                      "elementi dichiarati ma non agganciabili (00 §1.2):\n" + difetti.joined(separator: "\n"))
        for elemento in ordine where LettoreAccessibilita.eInterattivo(elemento) {
            XCTAssertGreaterThanOrEqual(LettoreAccessibilita.cornice(di: elemento).height.rounded(), 44,
                "bersaglio sotto la dimensione minima: «\(LettoreAccessibilita.etichetta(di: elemento))»")
        }
    }

    func test_02_2_8_l_ordine_di_lettura_della_mappa_e_quello_dichiarato_ed_e_completo() async throws {
        let (schermata, _, ambiente) = try await mappaAperta()
        let ordine = LettoreAccessibilita.ordineDiLettura(radice: schermata.view!)
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let caselle = stato.griglia.righe * stato.griglia.colonne
        // Caselle, poi i quattro comandi globali: tutto presente, niente d'altro.
        XCTAssertEqual(ordine.count, caselle + 4, "il percorso di lettura è completo")
        guard ordine.count == caselle + 4 else { return }

        let elementi = ordine.prefix(caselle).compactMap { $0 as? ElementoCasella }
        XCTAssertEqual(elementi.count, caselle, "prima le caselle, da ovest a est e dall'alto in basso")
        XCTAssertEqual(elementi.first?.casella, Cella(riga: 1, colonna: 1))
        XCTAssertEqual(elementi.last?.casella,
                       Cella(riga: stato.griglia.righe, colonna: stato.griglia.colonne))
        XCTAssertEqual(elementi.map(\.casella), elementi.map(\.casella).sorted())

        let testi = ambiente.testi
        for (scarto, chiave) in ["registro.apri", "pulsante.annulla",
                                 "pulsante.azzera", "resoconto.torna"].enumerated() {
            XCTAssertEqual(LettoreAccessibilita.etichetta(di: ordine[caselle + scarto]),
                           testi.frase(chiave).testo,
                           "i comandi globali chiudono l'ordine dichiarato")
        }
    }

    func test_00_11_5_ogni_casella_si_annuncia_con_la_testa_fissa_e_la_propria_posizione() async throws {
        let (schermata, _, ambiente) = try await mappaAperta(taglia: .media)
        let testi = ambiente.testi
        for (casella, elemento) in schermata.elementiPerProva {
            let etichetta = try XCTUnwrap(elemento.accessibilityLabel)
            let testa = testi.frase("casella.testa", casella.riga, casella.colonna).testo
            XCTAssertTrue(etichetta.contains(testa),
                          "la testa fissa manca o è alterata in \(casella): «\(etichetta)»")
            XCTAssertFalse(etichetta.contains(Testi.segnaposto),
                           "chiave irrisolta nell'annuncio di \(casella)")
        }
    }

    func test_02_2_5_le_azioni_personalizzate_sono_due_e_soltanto_di_navigazione() async throws {
        let (schermata, _, ambiente) = try await mappaAperta(taglia: .media)
        let testi = ambiente.testi
        let nord = testi.frase("direzione.nord").testo
        let sud = testi.frase("direzione.sud").testo
        for (casella, elemento) in schermata.elementiPerProva {
            let azioni = elemento.accessibilityCustomActions ?? []
            XCTAssertLessThanOrEqual(azioni.count, 2,
                                     "sulla mappa le azioni personalizzate sono due (02 §2.5)")
            for azione in azioni {
                XCTAssertTrue([nord, sud].contains(azione.name),
                              "azione non di navigazione in \(casella): \(azione.name)")
            }
            // Ai bordi mancano le direzioni che uscirebbero dalla mappa.
            let attese = (casella.riga > 1 ? 1 : 0)
                + (casella.riga < schermata.statoPerProva!.griglia.righe ? 1 : 0)
            XCTAssertEqual(azioni.count, attese, "direzioni offerte al bordo in \(casella)")
        }
    }

    func test_02_7_3_i_rotori_della_mappa_sono_quelli_realizzati() async throws {
        let (schermata, _, ambiente) = try await mappaAperta(taglia: .media)
        let testi = ambiente.testi
        let rotori = schermata.view.accessibilityCustomRotors ?? []
        XCTAssertEqual(rotori.map(\.name),
                       [testi.frase("rotore.proprie_formazioni").testo,
                        testi.frase("rotore.gruppi_in_attesa").testo],
                       "gli insiemi di 02 §7.3 che questa unità realizza, e nessuno a vuoto")
    }

    func test_01_5_16_il_pannello_offre_marcia_e_presidio_e_nient_altro() async throws {
        let (schermata, _, ambiente) = try await mappaAperta(taglia: .media)
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let gruppo = stato.gruppiOrdinati[0]
        XCTAssertTrue(schermata.attiva(gruppo.posizione), "la casella di un proprio gruppo si attiva")
        try await Task.sleep(nanoseconds: 100_000_000)
        let voci = schermata.vociPannelloPerProva
        let testi = ambiente.testi
        XCTAssertEqual(voci.map(\.titolo),
                       [testi.frase("pannello.designa_marcia").testo,
                        testi.frase("pannello.presidio").testo,
                        testi.frase("pannello.chiudi").testo],
                       "le due azioni di questa unità più la chiusura, in ordine fisso")
    }

    func test_02_9_5_una_casella_vuota_non_apre_alcun_pannello() async throws {
        let (schermata, _, _) = try await mappaAperta(taglia: .media)
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let vuota = stato.griglia.tutteLeCaselle.first { stato.occupante(di: $0) == nil }!
        XCTAssertFalse(schermata.attiva(vuota),
                       "senza gruppo non c'è nulla da ordinare: nessun pannello si apre")
    }

    /// Il difetto che rompe più spesso i giochi accessibili (00 §11.2): dopo un
    /// ordine gli elementi devono essere gli STESSI oggetti, aggiornati sul posto,
    /// e il fuoco non deve essersi mosso da solo (00 §11.1, RDA-03).
    func test_00_11_1_dopo_un_ordine_gli_elementi_non_sono_ricreati_e_il_fuoco_resta() async throws {
        let (schermata, _, _) = try await mappaAperta(taglia: .media)
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let gruppo = stato.gruppiOrdinati[0]
        let elementiPrima = schermata.elementiPerProva
        let identitaPrima = elementiPrima.mapValues { ObjectIdentifier($0) }
        let etichettaPrima = elementiPrima[gruppo.posizione]?.accessibilityLabel

        Fuoco.azzeraRegistro()
        _ = await schermata.eseguiPerProva(.presidio(gruppo: gruppo.id))

        let elementiDopo = schermata.elementiPerProva
        XCTAssertEqual(elementiDopo.mapValues { ObjectIdentifier($0) }, identitaPrima,
                       "gli elementi sono stati RICREATI: è ciò che fa perdere il fuoco (RDA-03)")
        XCTAssertNotEqual(elementiDopo[gruppo.posizione]?.accessibilityLabel, etichettaPrima,
                          "l'etichetta si aggiorna sul posto: il gruppo ora ha agito")
        XCTAssertTrue(schermata.registroFuocoPerProva.isEmpty,
                      "il fuoco si è mosso senza che l'utente lo chiedesse (00 §11.1)")
    }

    func test_01_5_6_0_6_la_giornata_si_chiude_e_lo_stato_lo_dichiara() async throws {
        let (schermata, _, _) = try await mappaAperta(taglia: .piccola)
        let stato = try XCTUnwrap(schermata.statoPerProva)
        XCTAssertEqual(stato.giorno, 1)
        for gruppo in stato.gruppiOrdinati {
            _ = await schermata.eseguiPerProva(.presidio(gruppo: gruppo.id))
        }
        let dopo = try XCTUnwrap(schermata.statoPerProva)
        XCTAssertEqual(dopo.giorno, 2, "ordinati tutti i gruppi, la giornata si chiude da sé")
        XCTAssertTrue(dopo.gruppi.values.allSatisfy { !$0.azioneSpesa })
        XCTAssertTrue(schermata.accessibilityPerformMagicTap(),
                      "il tocco magico risponde anche a giornata cambiata (02 §6.7)")
    }

    func test_02_6_6_il_registro_e_un_elenco_di_voci_e_non_una_tabella() async throws {
        let ambiente = try Ambiente()
        let schermata = SchermataRegistro(voci: [
            .init(frase: "Giorno 2: ordine annullato", luogo: nil),
            .init(frase: "Giorno 1: un fatto con luogo", luogo: Cella(riga: 3, colonna: 4)),
        ], testi: ambiente.testi)
        let finestra = UIWindow(frame: Self.schermoPiccolo)
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        finestra.layoutIfNeeded()

        let ordine = LettoreAccessibilita.ordineDiLettura(radice: schermata.view!)
        let etichette = ordine.map { LettoreAccessibilita.etichetta(di: $0) }
        XCTAssertTrue(etichette.contains("Giorno 2: ordine annullato"),
                      "ogni voce è un elemento a sé che si annuncia in una frase compiuta")
        // La voce senza luogo esiste, si legge, e non si attiva: nulla cui saltare.
        let senzaLuogo = try XCTUnwrap(ordine.first {
            LettoreAccessibilita.etichetta(di: $0).contains("Giorno 2") })
        XCTAssertTrue(senzaLuogo.accessibilityTraits.contains(.staticText))
        let conLuogo = ordine.first { LettoreAccessibilita.etichetta(di: $0).contains("Giorno 1") }
        XCTAssertEqual((conLuogo as? UIButton)?.isEnabled, true,
                       "la voce con un luogo consente di saltarvi (02 §6.6)")
        for elemento in ordine {
            XCTAssertNil(LettoreAccessibilita.motivoNonAgganciabile(elemento, schermo: finestra.bounds),
                         "voce del registro non agganciabile: «\(LettoreAccessibilita.etichetta(di: elemento))»")
        }
    }

    /// Il registro contiene gli ordini impartiti ai gruppi, ciascuno con il proprio
    /// giorno e il proprio luogo (01 §5.17, scostamento S8). Nella prima unità
    /// conteneva soltanto voci di calendario, e il salto al luogo del fatto non era
    /// mai esercitabile.
    func test_01_5_17_il_registro_contiene_gli_ordini_con_il_loro_luogo() async throws {
        let (schermata, _, ambiente) = try await mappaAperta(taglia: .media)
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let gruppo = stato.gruppiOrdinati[0]
        let destinazione = try XCTUnwrap(
            stato.griglia.vicini(di: gruppo.posizione).first { stato.occupante(di: $0) == nil })
        await schermata.eseguiPerProva(
            .marcia(gruppo: gruppo.id, a: destinazione,
                    giorni: partitaMotore(schermata).costoInGiorni(da: gruppo.posizione,
                                                                   a: destinazione, stato: stato)))
        let dopo = try XCTUnwrap(schermata.statoPerProva)
        XCTAssertEqual(dopo.registro.count, 1)
        let voce = try XCTUnwrap(dopo.registro.first)
        XCTAssertEqual(voce.luogo, destinazione, "la voce porta al luogo del fatto")

        let costruttore = CostruttoreAnnunciCampagna(testi: ambiente.testi,
                                                     motore: partitaMotore(schermata),
                                                     stato: dopo, verbosita: .normale)
        let frase = costruttore.voceDiRegistro(voce)
        XCTAssertFalse(frase.contains(Testi.segnaposto), "chiave irrisolta nella voce: \(frase)")
        XCTAssertTrue(frase.contains("\(voce.giorno)"), "la voce dichiara il giorno")
        XCTAssertTrue(frase.contains(costruttore.nomeGruppo(dopo.gruppi[gruppo.id]!)),
                      "la voce dichiara quale gruppo: \(frase)")
    }

    /// Il salto dalla voce al luogo del fatto (02 §6.6), esercitabile per la prima
    /// volta: il fuoco arriva sulla casella e la casella si annuncia.
    func test_02_6_6_attivare_una_voce_porta_il_fuoco_sul_luogo_del_fatto() async throws {
        let (schermata, _, _) = try await mappaAperta(taglia: .media)
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let gruppo = stato.gruppiOrdinati[0]
        let destinazione = try XCTUnwrap(
            stato.griglia.vicini(di: gruppo.posizione).first { stato.occupante(di: $0) == nil })
        await schermata.eseguiPerProva(
            .marcia(gruppo: gruppo.id, a: destinazione,
                    giorni: partitaMotore(schermata).costoInGiorni(da: gruppo.posizione,
                                                                   a: destinazione, stato: stato)))
        schermata.apriRegistroPerProva()
        for _ in 0..<50 where schermata.presentedViewController == nil {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        try await Task.sleep(nanoseconds: 100_000_000)
        let registro = try XCTUnwrap(schermata.presentedViewController as? SchermataRegistro)
        registro.loadViewIfNeeded()
        let voce = try XCTUnwrap(registro.vociVisibili.first as? UIButton,
                                 "la voce con un luogo è attivabile")

        Fuoco.azzeraRegistro()
        voce.sendActions(for: .touchUpInside)
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertNil(schermata.presentedViewController, "il registro si congeda prima del salto")
        XCTAssertTrue(schermata.registroFuocoPerProva.contains(.richiesto),
                      "il fuoco è stato portato sul luogo del fatto")
        // La casella su cui il fuoco arriva si annuncia: la sua etichetta è
        // completa e dichiara il gruppo che vi si trova.
        let elemento = try XCTUnwrap(schermata.elementiPerProva[destinazione])
        let etichetta = try XCTUnwrap(elemento.accessibilityLabel)
        XCTAssertTrue(etichetta.contains("\(destinazione.riga)"))
        XCTAssertFalse(etichetta.contains(Testi.segnaposto))
    }

    private func partitaMotore(_ schermata: SchermataMappaCampagna) -> MotoreCampagna {
        schermata.motorePerProva
    }
}
