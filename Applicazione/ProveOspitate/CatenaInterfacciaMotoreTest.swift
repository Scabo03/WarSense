import XCTest
import Dati
import Motore
import Sessione
import Segnali
@testable import WarSense

/// La catena intera: dal dito al Motore (00 §3.1, §3.2, 05 §1.4).
///
/// Sono le prove che l'impianto d'interfaccia sul simulatore non può scrivere,
/// perché XCUITest vive in un processo separato e non vede né lo stato del Motore
/// né il costruttore degli annunci. Girano nello stesso processo
/// dell'applicazione, sul simulatore, e sono le uniche del progetto che colleghino
/// ciò che il giocatore FA a ciò che il gioco È.
///
/// ## Perché la prova della catena non può passare se un anello viene tolto
///
/// Gli anelli sono cinque, e ciascuno ha il proprio pretesto:
///
/// 1. **Tocco e risoluzione** — ogni tocco deve restituire vero, e il conteggio dei
///    tocchi riusciti deve pareggiare con i comandi che il giornale porta. Un tocco
///    che non risolva, o un comando che si perda per strada, fa cadere il pareggio.
/// 2. **Nessun ordine respinto in silenzio** — un comando RIFIUTATO non lascia
///    traccia nel giornale, perché il giornale registra i comandi validi (05 §6.1):
///    il solo posto in cui esista è l'annuncio. La prova pretende che fra gli
///    annunci emessi durante la partita non compaia alcun termine di rifiuto
///    (`MotivoNonValidoCampagna.allCases`). Senza questo controllo il confronto
///    delle impronte passerebbe anche se metà degli ordini fosse stata respinta,
///    perché entrambi i percorsi riapplicherebbero i soli comandi accettati.
/// 3. **Il comando è quello del Motore, non della Presentazione** — per ciascuna
///    marcia del giornale si ricostruisce, dallo stato che la precedeva, la
///    prescrizione del Motore per quel medesimo gesto, e si pretende che coincidano.
///    Se la Presentazione si calcolasse un costo in giorni proprio — che 00 §13.1 e
///    00 §3.2 le vietano — il confronto cadrebbe qui anche a comando valido.
/// 4. **Applicazione e impronta** — la sequenza del giornale, riapplicata da una
///    Sessione senza alcuna interfaccia, deve dare la stessa impronta canonica, lo
///    stesso calendario e lo stesso registro.
/// 5. **Elementi mai ricreati** — l'identità di oggetto degli elementi accessibili
///    non cambia per tutta la partita (05 §10.1, RDA-03).
///
/// ## Che cosa NON osserva
///
/// Il tocco vero: qui si entra da `VistaACaselle.attivaAlTocco`, che è il metodo che
/// il riconoscitore chiama, non il riconoscitore stesso. Il tocco sintetizzato dal
/// servizio di accessibilità è provato in `ImpiantoInterfacciaTest`. E non osserva
/// la pronuncia, che resta materia del dispositivo.
@MainActor
final class CatenaInterfacciaMotoreTest: XCTestCase {

    /// Un anello rotto va dichiarato subito: senza questo, il ciclo proseguirebbe
    /// per centinaia di ordini falliti prima di arrivare al confronto finale.
    override func setUp() { super.setUp(); continueAfterFailure = false }

    private func attendi(_ descrizione: String,
                         _ condizione: @MainActor () -> Bool) async throws {
        for _ in 0..<250 where !condizione() {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertTrue(condizione(), "attesa scaduta: \(descrizione)")
    }

    private func mappaAperta(_ taglia: PartitaCampagna.Taglia)
        async throws -> (SchermataMappaCampagna, Ambiente) {
        let ambiente = try Ambiente()
        let partita = try await PartitaCampagna(nuova: ambiente, taglia: taglia)
        let schermata = SchermataMappaCampagna(partita: partita)
        let finestra = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        finestra.rootViewController = schermata
        finestra.makeKeyAndVisible()
        schermata.loadViewIfNeeded()
        try await attendi("creazione delle caselle") { !schermata.elementiPerProva.isEmpty }
        try await Task.sleep(nanoseconds: 200_000_000)
        finestra.layoutIfNeeded()
        addTeardownBlock { @MainActor in
            schermata.presentedViewController?.dismiss(animated: false)
            finestra.isHidden = true
            finestra.rootViewController = nil
        }
        return (schermata, ambiente)
    }

    // MARK: - 00 §9.1, 02 §3.8 — l'annuncio dell'interfaccia è quello del Motore

    /// Ciò che l'elemento accessibile porta come etichetta deve essere esattamente
    /// ciò che il costruttore degli annunci ricava dallo stato del Motore, casella
    /// per casella. Una divergenza qui significa che la schermata ha una seconda
    /// sorgente di verità, e chi ascolta riceverebbe la descrizione di uno stato
    /// che non è quello della partita.
    func test_00_9_1_l_etichetta_esposta_coincide_con_quella_che_il_motore_prescrive() async throws {
        for taglia in PartitaCampagna.Taglia.allCases {
            let (schermata, ambiente) = try await mappaAperta(taglia)
            let stato = try XCTUnwrap(schermata.statoPerProva)
            let costruttore = CostruttoreAnnunciCampagna(
                testi: ambiente.testi, motore: schermata.motorePerProva,
                stato: stato, verbosita: Impostazioni.verbosita)
            var divergenze: [String] = []
            for (casella, elemento) in schermata.elementiPerProva {
                let dalMotore = costruttore.etichettaCasella(casella)
                if elemento.accessibilityLabel != dalMotore {
                    divergenze.append("\(casella): esposto «\(elemento.accessibilityLabel ?? "")» "
                                      + "contro «\(dalMotore)»")
                }
            }
            XCTAssertTrue(divergenze.isEmpty,
                          "\(taglia.rawValue): l'interfaccia annuncia qualcosa di diverso da "
                          + "ciò che il Motore prescrive (00 §3.2): "
                          + divergenze.prefix(3).joined(separator: " | "))
        }
    }

    // MARK: - 05 §3.2 — un ordine respinto lascia una traccia leggibile

    /// Il rifiuto di un comando è oggi annunciato e non registrato: il giornale
    /// porta i comandi VALIDI (05 §6.1), e un ordine respinto non vi lascia nulla.
    /// Senza una traccia leggibile, nessuno — né una prova né il titolare — può
    /// sapere che cosa il gioco abbia rifiutato durante una partita, e la prova
    /// della catena passerebbe anche con metà degli ordini respinti.
    ///
    /// La traccia è l'elenco degli annunci emessi, tenuto dal punto che li produce
    /// (`PuntoSegnali.annunciPronunciati`). Questa prova lo accerta con un ordine
    /// che il Motore deve respingere: una marcia verso una casella non adiacente
    /// (01 §5.6.3.1, motivo `casella.non_adiacente`).
    func test_05_3_2_un_ordine_respinto_lascia_traccia_negli_annunci() async throws {
        let (schermata, ambiente) = try await mappaAperta(.grande)
        let stato = try XCTUnwrap(schermata.statoPerProva)
        let gruppo = stato.gruppiOrdinati[0]
        let lontana = try XCTUnwrap(stato.griglia.tutteLeCaselle.first {
            !stato.griglia.vicini(di: gruppo.posizione).contains($0) && $0 != gruppo.posizione
        }, "serve una casella non adiacente")

        ambiente.segnali.azzeraAnnunciPronunciati()
        await schermata.eseguiPerProva(.marcia(gruppo: gruppo.id, a: lontana, giorni: 1))
        try await Task.sleep(nanoseconds: 200_000_000)

        let atteso = ambiente.testi.termine(MotivoNonValidoCampagna.nonAdiacente.rawValue).testo
        XCTAssertTrue(ambiente.segnali.annunciPronunciati.map(\.testo).contains(atteso),
                      "il rifiuto non lascia alcuna traccia leggibile: annunciato «\(atteso)» "
                      + "ma l'elenco porta \(ambiente.segnali.annunciPronunciati.map(\.testo))")
        // E lo stato non è cambiato: il comando respinto non ha prodotto nulla.
        XCTAssertEqual(schermata.statoPerProva?.gruppi[gruppo.id]?.posizione, gruppo.posizione,
                       "un comando respinto ha mosso il gruppo")
    }

    // MARK: - 00 §3.1 — la partita giocata al dito è la partita del Motore

    /// Una campagna condotta dall'inizio attraverso l'interfaccia, sui tre formati,
    /// con criterio di arresto dichiarato: si gioca finché il calendario non supera
    /// il giorno stabilito.
    func test_00_3_1_una_campagna_giocata_al_dito_da_lo_stesso_stato_del_motore() async throws {
        for taglia in PartitaCampagna.Taglia.allCases {
            try await giocaEConfronta(taglia, finoAlGiorno: 4)
        }
    }

    private func giocaEConfronta(_ taglia: PartitaCampagna.Taglia,
                                 finoAlGiorno ultimoGiorno: Int) async throws {
        let (schermata, ambiente) = try await mappaAperta(taglia)
        let partita = schermata.partitaPerProva
        let dove = taglia.rawValue

        // ANELLO 5: l'identità degli elementi non deve cambiare per tutta la partita.
        let identitaIniziale = schermata.elementiPerProva.mapValues { ObjectIdentifier($0) }
        // ANELLO 2: si guarda ciò che il gioco dice DA QUI IN POI.
        ambiente.segnali.azzeraAnnunciPronunciati()

        // Lo stato che precedeva ciascun ordine, per ricostruire poi la prescrizione
        // del Motore per quel gesto (anello 3).
        var statiPrecedenti: [StatoCampagna] = []
        // La casella che il dito ha toccato per ciascun ordine. Senza di essa la
        // prova passerebbe anche se l'interfaccia mandasse il gruppo su una casella
        // DIVERSA da quella toccata, purché valida: il giornale porterebbe quella
        // sbagliata e i due percorsi la riapplicherebbero entrambi, concordi.
        var caselleToccate: [Cella] = []
        var tocchiRiusciti = 0

        while (await partita.stato).giorno <= ultimoGiorno {
            let stato = await partita.stato
            // Se un contatto armato ha innescato una battaglia in sospeso (incarico 24), la campagna
            // è preclusa e questa prova — che verifica la CATENA del gioco ordinario dal dito al
            // Motore — ha esaurito il suo àmbito: il passaggio alla battaglia ha la propria prova
            // dedicata (`PassaggioBattagliaInterfacciaTest`). La catena è verificata fino a qui.
            if !stato.battaglieInSospeso.isEmpty { break }
            // Il prossimo gruppo che ATTENDE una decisione: non basta `!azioneSpesa`,
            // perché un gruppo in marcia lunga ha l'azione consumata dalla marcia e
            // non dal giocatore (azioneSpesa falsa, marcia non nulla) e non è
            // ordinabile — offrirebbe la revoca, non il presidio. È lo stesso criterio
            // del salto e del rotore (`haConclusoLaGiornata`, 01 §5.16.1). Con i volumi
            // diversi dell'incarico 15 le marce durano più giorni e questo caso, prima
            // latente, si esercita davvero.
            guard let gruppo = stato.gruppiOrdinati.first(where: { !$0.haConclusoLaGiornata })
            else { break }
            let vista = await partita.vista
            let improntaPrima = stato.impronta()
            statiPrecedenti.append(stato)

            // Marcia dove una destinazione esiste, presidio dove non esiste: al
            // gruppo stipato l'azione di marcia non si offre affatto (02 §9.5).
            if let meta = vista.destinazioniValide(per: gruppo.id).first {
                schermata.avviaDesignazionePerProva(gruppo: gruppo.id)
                let bersaglio = VistaMappa.cornice(di: meta)
                // ANELLO 1: il tocco risolve l'elemento e lo attiva. Attivare la
                // destinazione ORDINA la marcia DIRETTAMENTE, senza pannello di
                // conferma (correzione del titolare, RDA-104): il costo e la
                // conseguenza dell'inchiodamento sono già sulla voce della casella
                // (casella.disponibile e casella.inchioda), che chi ascolta ha sentito
                // prima di attivarla. L'ordine è asincrono e la sua applicazione si
                // attende sotto, con il cambiamento d'impronta.
                XCTAssertTrue(schermata.grigliaPerProva.attivaAlTocco(
                    in: CGPoint(x: bersaglio.midX, y: bersaglio.midY)),
                              "\(dove): il dito non ordina la marcia verso \(meta)")
                caselleToccate.append(meta)
            } else {
                let cornice = VistaMappa.cornice(di: gruppo.posizione)
                XCTAssertTrue(schermata.grigliaPerProva.attivaAlTocco(
                    in: CGPoint(x: cornice.midX, y: cornice.midY)),
                              "\(dove): il dito non apre il pannello su \(gruppo.posizione)")
                try await attendi("\(dove): pannello aperto") {
                    schermata.presentedViewController is UIAlertController
                }
                let voce = try XCTUnwrap(schermata.vociPannelloPerProva.first {
                    $0.titolo == ambiente.testi.frase("pannello.presidio").testo
                }, "\(dove): il pannello offre il presidio (01 §5.6.0.6)")
                // La sequenza reale del tocco (P5): l'avviso si congeda da sé e la
                // voce agisce a congedo avvenuto.
                schermata.presentedViewController?.dismiss(animated: false)
                try await attendi("\(dove): congedo dell'avviso") {
                    schermata.presentedViewController == nil
                }
                voce.esegui()
                caselleToccate.append(gruppo.posizione)
            }
            tocchiRiusciti += 1

            // Si attende che lo STATO cambi, non che l'azione risulti spesa:
            // l'ordine che chiude la giornata azzera le azioni nel medesimo passo
            // (01 §5.6.0.6), sicché attendere `azioneSpesa` non terminerebbe mai. È
            // l'errore che teneva rossa questa prova nella sessione precedente, e
            // non era un rifiuto del comando: vedi il resoconto.
            try await attendi("\(dove): ordine applicato") {
                schermata.statoPerProva?.impronta() != improntaPrima
            }
            XCTAssertLessThan(tocchiRiusciti, 400, "\(dove): il criterio di arresto non arriva")
        }
        XCTAssertGreaterThan(tocchiRiusciti, 0, "\(dove): nessun ordine impartito")

        // ANELLO 2: nessun ordine respinto in silenzio.
        let terminiDiRifiuto = Set(MotivoNonValidoCampagna.allCases.map {
            ambiente.testi.termine($0.rawValue).testo
        })
        let rifiuti = ambiente.segnali.annunciPronunciati.map(\.testo).filter {
            terminiDiRifiuto.contains($0)
        }
        XCTAssertTrue(rifiuti.isEmpty,
                      "\(dove): il gioco ha respinto \(rifiuti.count) ordini e il giornale non "
                      + "ne porta traccia: \(Set(rifiuti))")

        // ANELLO 1: il giornale porta un comando per ciascun tocco riuscito.
        let comandi = try comandiDelGiornale(PartitaCampagna.cartellaCampagna
            .appendingPathComponent("giornale.jsonl"))
        XCTAssertEqual(comandi.count, tocchiRiusciti,
                       "\(dove): \(tocchiRiusciti) ordini impartiti e \(comandi.count) comandi "
                       + "nel giornale: un anello della catena perde ciò che il dito produce")

        // ANELLO 3: ogni marcia è quella che il Motore prescrive per quel gesto.
        XCTAssertEqual(statiPrecedenti.count, comandi.count,
                       "\(dove): stati e comandi non si corrispondono")
        var marceControllate = 0
        for (indice, comando) in comandi.enumerated() where indice < statiPrecedenti.count {
            guard case .marcia(let id, let a, _) = comando else { continue }
            // Il comando porta la casella che il DITO ha toccato, non un'altra.
            XCTAssertEqual(a, caselleToccate[indice],
                           "\(dove): il comando \(indice) manda il gruppo in \(a) mentre il "
                           + "dito ha toccato \(caselleToccate[indice])")
            // E porta il costo che il Motore prescrive per quel gesto, non uno che
            // la Presentazione si sia calcolata (00 §3.2, §13.1).
            let vistaAllora = VistaCampagna(motore: schermata.motorePerProva,
                                            stato: statiPrecedenti[indice], parte: .giocatore)
            XCTAssertEqual(comando, vistaAllora.comandoDiMarcia(per: id, a: a),
                           "\(dove): il comando \(indice) non è quello che il Motore prescrive "
                           + "per quel gesto: la Presentazione ha calcolato un dato di gioco")
            marceControllate += 1
        }
        XCTAssertGreaterThan(marceControllate, 0,
                             "\(dove): nessuna marcia nella sequenza: l'anello del costo in "
                             + "giorni non è stato esercitato")

        // ANELLO 4: la stessa sequenza, senza alcuna interfaccia.
        let slot = FileManager.default.temporaryDirectory
            .appendingPathComponent("catena-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: slot) }
        let diretta = try await SessioneCampagna(
            nuova: PartitaCampagna.scenario(taglia), valori: ambiente.valori,
            valoriCampagna: ambiente.valoriCampagna, versioneTesti: ambiente.testi.versione,
            cartella: slot, seme: 1, identificatore: "catena")
        for comando in comandi {
            let esito = try await diretta.esegui(comando, parte: .giocatore).0
            XCTAssertTrue(esito.eValido,
                          "\(dove): il comando \(comando) prodotto dall'interfaccia non è valido "
                          + "applicato direttamente: \(String(describing: esito.motivo))")
        }
        let statoDiretto = await diretta.stato
        let statoDalDito = await partita.stato
        XCTAssertEqual(statoDalDito.impronta(), statoDiretto.impronta(),
                       "\(dove): la partita giocata al dito e la stessa sequenza applicata "
                       + "senza interfaccia danno stati diversi (00 §3.1, §3.2). "
                       + "Ordini: \(tocchiRiusciti)")
        XCTAssertEqual(statoDalDito.giorno, statoDiretto.giorno,
                       "\(dove): il calendario diverge fra i due percorsi")
        XCTAssertEqual(statoDalDito.registro.map(\.fatto), statoDiretto.registro.map(\.fatto),
                       "\(dove): il registro diverge fra i due percorsi")

        // ANELLO 5.
        XCTAssertEqual(schermata.elementiPerProva.mapValues { ObjectIdentifier($0) },
                       identitaIniziale,
                       "\(dove): gli elementi accessibili sono stati ricreati durante la "
                       + "partita (05 §10.1, RDA-03): la voce perderebbe il proprio posto")
    }

    /// I comandi di campagna DEL GIOCATORE nel giornale, nell'ordine in cui vi sono stati
    /// scritti. Da quando lo scenario giocabile schiera un avversario (incarico 23), il giornale
    /// porta anche i comandi dell'AVVERSARIO — la condotta li applica come qualunque comando e li
    /// annota (RDA-42) — ma questa prova verifica la catena dal DITO del giocatore al giornale,
    /// sicché conta i soli comandi del giocatore. La sequenza dell'avversario, deterministica, la
    /// riproduce da sé la sessione diretta dell'anello 4.
    private func comandiDelGiornale(_ percorso: URL) throws -> [ComandoCampagna] {
        let testo = try String(contentsOf: percorso, encoding: .utf8)
        var comandi: [ComandoCampagna] = []
        for riga in testo.split(separator: "\n") {
            guard let voce = try? JSONDecoder().decode(RigaGiornale.self, from: Data(riga.utf8))
            else { continue }
            if case .comandoCampagna(let parte, let comando) = voce.voce, parte == .giocatore {
                comandi.append(comando)
            }
        }
        return comandi
    }
}
