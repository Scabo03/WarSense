import XCTest
import Sessione
import Motore
import Dati

/// Blocco della codifica del giornale (incarico fase B): il giornale è anche il
/// formato di salvataggio, e se la codifica degli enumerativi con valori associati
/// si sposta, le partite aperte dei tester non si riaprono più (00 §15).
///
/// La composizione dei gruppi (01 §5.6.0) non aggiunge alcun caso agli enumerativi
/// del giornale, ma cambia la FORMA di `ScenarioCampagna` — ogni gruppo iniziale
/// porta ora la propria composizione — e quindi la codifica di `FondazioneCampagna`,
/// che lo iscrive. Il campione di `fondazioneCampagna` è stato perciò rigenerato con
/// la composizione, ed è il solo toccato; il suo `versione_schema` sale a 4, valore
/// che `FondazioneCampagna.schemaCorrente` porta perché un giornale di versione 3 —
/// gruppi senza composizione — non ha da dove leggere il volume e non si riapre
/// (00 §15.2). Gli altri campioni continuano a ricodificarsi byte per byte identici:
/// la codifica sintetizzata usa il NOME del caso come chiave, e i casi non sono
/// cambiati.
///
/// Storia dello schema di campagna: 2 da quando il comando di marcia trasporta il
/// costo (RDA-75); 3 dalla marcia lunga e dalla risoluzione di fine giornata; 4 dalla
/// composizione e dal volume.
///
/// ## Perché la copertura è imposta da una catena di errori di compilazione
///
/// La forma precedente di questa prova confrontava i casi trovati nei campioni con
/// un insieme di nomi scritto a mano. Un caso aggiunto all'enumerativo senza il
/// proprio campione non compariva né nei campioni né nel letterale, i due insiemi
/// restavano uguali e la prova PASSAVA: la protezione che `stato-avanzamento.md`
/// le attribuiva non esisteva per nessuno dei tre tipi.
///
/// La forma attuale lega ciascun tipo a uno SPECCHIO privo di valori associati e
/// quindi `CaseIterable`, con due funzioni totali ed esaustive per ciascuna
/// coppia. Aggiungere un caso al tipo vero non compila `specie(di:)`; aggiungerlo
/// allo specchio per far compilare quella non compila `esemplare(di:)`, che
/// obbliga a COSTRUIRE il valore; e a quel punto la prova pretende che la chiave
/// codificata di quel valore compaia nei campioni committati. Nessun anello della
/// catena si può saltare, e i primi due sono errori di compilazione.
///
/// Serve adesso e non alla prossima unità: RDA-76 e `impatto-marcia-lunga.md` §7
/// stabiliscono che la revoca della marcia introdurrà un caso nuovo proprio in
/// `VoceGiornale`, ed è il passaggio che rende irrecuperabili i salvataggi.
final class CompatibilitaGiornaleTest: XCTestCase {

    static let campioni = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("CampioniGiornale/campioni.jsonl")

    // MARK: - Gli specchi dei tre tipi che compongono il formato di salvataggio

    /// Specchio di `VoceGiornale`. I nomi dei casi DEVONO coincidere con quelli
    /// del tipo vero, perché è il nome del caso a essere la chiave codificata.
    enum SpecieDiVoce: String, CaseIterable {
        case fondazione, comando, inizioTurno, fondazioneCampagna
        case comandoCampagna, aperturaGiornata, annullamentoCampagna, risoluzioneGiornata
    }

    /// Specchio di `ComandoBattaglia`.
    enum SpecieDiComando: String, CaseIterable {
        case seleziona, deseleziona, piazza, muovi, tira
        case ingaggia, dichiaraResa, ritiraUnita, disingaggiaSuOrdine, fineTurno
    }

    /// Specchio di `ComandoCampagna`.
    enum SpecieDiComandoCampagna: String, CaseIterable {
        case marcia, presidio, revocaMarcia, divisione, riunione
    }

    // MARK: - I due lati della catena: dal tipo vero allo specchio e ritorno

    /// Totale ed esaustiva: aggiungere un caso a `VoceGiornale` NON COMPILA.
    private func specie(di voce: VoceGiornale) -> SpecieDiVoce {
        switch voce {
        case .fondazione: return .fondazione
        case .comando: return .comando
        case .inizioTurno: return .inizioTurno
        case .fondazioneCampagna: return .fondazioneCampagna
        case .comandoCampagna: return .comandoCampagna
        case .aperturaGiornata: return .aperturaGiornata
        case .annullamentoCampagna: return .annullamentoCampagna
        case .risoluzioneGiornata: return .risoluzioneGiornata
        }
    }

    /// Totale ed esaustiva: aggiungere un caso a `SpecieDiVoce` NON COMPILA finché
    /// non se ne costruisce l'esemplare, che è ciò che il campione deve portare.
    private func esemplare(di specie: SpecieDiVoce) -> VoceGiornale {
        switch specie {
        case .fondazione: return .fondazione(Self.fondazioneDiProva)
        case .comando: return .comando(parte: .giocatore, comando: .fineTurno)
        case .inizioTurno: return .inizioTurno(parte: .giocatore, giro: 1)
        case .fondazioneCampagna: return .fondazioneCampagna(Self.fondazioneCampagnaDiProva)
        case .comandoCampagna:
            return .comandoCampagna(parte: .giocatore, comando: .presidio(gruppo: IdGruppo(1)))
        case .aperturaGiornata: return .aperturaGiornata(giorno: 1)
        case .annullamentoCampagna: return .annullamentoCampagna(giorno: 1, azzeramento: false)
        case .risoluzioneGiornata: return .risoluzioneGiornata(giorno: 1)
        }
    }

    /// Totale ed esaustiva: aggiungere un caso a `ComandoBattaglia` NON COMPILA.
    private func specie(di comando: ComandoBattaglia) -> SpecieDiComando {
        switch comando {
        case .seleziona: return .seleziona
        case .deseleziona: return .deseleziona
        case .piazza: return .piazza
        case .muovi: return .muovi
        case .tira: return .tira
        case .ingaggia: return .ingaggia
        case .dichiaraResa: return .dichiaraResa
        case .ritiraUnita: return .ritiraUnita
        case .disingaggiaSuOrdine: return .disingaggiaSuOrdine
        case .fineTurno: return .fineTurno
        }
    }

    private func esemplare(di specie: SpecieDiComando) -> ComandoBattaglia {
        switch specie {
        case .seleziona: return .seleziona(indiceDeck: 0)
        case .deseleziona: return .deseleziona
        case .piazza: return .piazza(cella: Cella(riga: 1, colonna: 1))
        case .muovi: return .muovi(sciame: IdSciame(1), percorso: [Cella(riga: 1, colonna: 1)])
        case .tira: return .tira(sciame: IdSciame(1), bersaglio: IdSciame(2))
        case .ingaggia: return .ingaggia(sciame: IdSciame(1), bersaglio: IdSciame(2))
        case .dichiaraResa: return .dichiaraResa
        case .ritiraUnita: return .ritiraUnita(sciame: IdSciame(1))
        case .disingaggiaSuOrdine: return .disingaggiaSuOrdine(sciame: IdSciame(1))
        case .fineTurno: return .fineTurno
        }
    }

    /// Totale ed esaustiva: aggiungere un caso a `ComandoCampagna` NON COMPILA.
    private func specie(di comando: ComandoCampagna) -> SpecieDiComandoCampagna {
        switch comando {
        case .marcia: return .marcia
        case .presidio: return .presidio
        case .revocaMarcia: return .revocaMarcia
        case .divisione: return .divisione
        case .riunione: return .riunione
        }
    }

    private func esemplare(di specie: SpecieDiComandoCampagna) -> ComandoCampagna {
        switch specie {
        case .marcia:
            return .marcia(gruppo: IdGruppo(1), a: Cella(riga: 1, colonna: 1), giorni: 1)
        case .presidio: return .presidio(gruppo: IdGruppo(1))
        case .revocaMarcia: return .revocaMarcia(gruppo: IdGruppo(1))
        case .divisione:
            return .divisione(gruppo: IdGruppo(1), repartiStaccati: [1], a: Cella(riga: 1, colonna: 2))
        case .riunione:
            return .riunione(gruppo: IdGruppo(1), con: IdGruppo(2))
        }
    }

    // MARK: - Gli esemplari che servono a costruire i due atti di fondazione

    static let fondazioneDiProva = Fondazione(
        versioneSchema: Fondazione.schemaCorrente, versioneValori: "0.0.0",
        versioneTesti: "0.0.0", seme: 1, identificatore: "specie",
        scenario: ScenarioBattaglia(formato: "quindici", caratteristica: "campo_aperto",
                                    primoOccupante: .giocatore, imboscata: false,
                                    deckGiocatore: [], deckAvversario: []))

    static let fondazioneCampagnaDiProva = FondazioneCampagna(
        versioneSchema: FondazioneCampagna.schemaCorrente, versioneValori: "0.0.0",
        versioneTesti: "0.0.0", seme: 1, identificatore: "specie",
        scenario: ScenarioCampagna(mappa: "guado",
                                   gruppiGiocatore: [.init(riga: 4, colonna: 2,
                                       composizione: [.init(archetipo: "fanteria_leggera", atomi: 6)])]))

    // MARK: - La prova

    func test_00_15_i_campioni_committati_si_decodificano_e_ricodificano_identici() throws {
        let codificatore = JSONEncoder()
        codificatore.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let testo = try String(contentsOf: Self.campioni, encoding: .utf8)
        let righe = testo.split(separator: "\n")
        XCTAssertGreaterThanOrEqual(righe.count, SpecieDiVoce.allCases.count,
                                    "almeno un campione per ogni caso di voce")
        var casiComando = Set<String>()
        var casiComandoCampagna = Set<String>()
        var casiVoce = Set<String>()
        for riga in righe {
            let dati = Data(riga.utf8)
            let voce: RigaGiornale
            do { voce = try JSONDecoder().decode(RigaGiornale.self, from: dati) }
            catch {
                return XCTFail("campione non piu decodificabile: la codifica del giornale si e spostata. Riga: \(riga.prefix(80))")
            }
            // La ricodifica deve produrre esattamente i byte del campione:
            // qualunque scarto e un cambiamento di formato di salvataggio.
            let ricodifica = try codificatore.encode(voce)
            XCTAssertEqual(String(data: ricodifica, encoding: .utf8), String(riga),
                           "la ricodifica differisce dal campione committato")
            if case .comando(_, let comando) = voce.voce {
                casiComando.insert(specie(di: comando).rawValue)
            }
            if case .comandoCampagna(_, let comando) = voce.voce {
                casiComandoCampagna.insert(specie(di: comando).rawValue)
            }
            casiVoce.formUnion(try chiaviDiPrimoLivelloDellaVoce(dati))
        }

        // Ogni specie DEVE avere il proprio campione. L'insieme atteso non è più un
        // letterale ma la codifica degli esemplari: chi aggiunge un caso è passato
        // per due errori di compilazione e trova qui il terzo anello.
        XCTAssertEqual(casiVoce, try chiaviAttese(SpecieDiVoce.allCases) { esemplare(di: $0) },
                       "un caso di VoceGiornale è privo di campione, oppure è stato rinominato o spostato: i salvataggi esistenti non si riaprono (00 §15)")
        XCTAssertEqual(casiComando, Set(SpecieDiComando.allCases.map(\.rawValue)),
                       "casi di comando di battaglia senza campione committato")
        XCTAssertEqual(casiComandoCampagna, Set(SpecieDiComandoCampagna.allCases.map(\.rawValue)),
                       "casi di comando di campagna senza campione committato")
    }

    /// Lo specchio deve rispecchiare: `specie(di: esemplare(di: s))` è `s` per
    /// ogni specie, e il nome dello specchio è la chiave che il codificatore
    /// sintetizzato scrive. Senza questa prova un ramo mappato al caso sbagliato
    /// passerebbe inosservato e la copertura sarebbe apparente.
    func test_00_15_lo_specchio_dei_casi_coincide_con_gli_enumerativi_veri() throws {
        for specieAttesa in SpecieDiVoce.allCases {
            let valore = esemplare(di: specieAttesa)
            XCTAssertEqual(specie(di: valore), specieAttesa,
                           "l'esemplare di \(specieAttesa.rawValue) è di un altro caso")
            XCTAssertEqual(try chiaveCodificata(di: RigaGiornale(numero: 1, voce: valore),
                                                dentro: "voce"),
                           specieAttesa.rawValue,
                           "il nome dello specchio non è la chiave codificata")
        }
        for specieAttesa in SpecieDiComando.allCases {
            XCTAssertEqual(specie(di: esemplare(di: specieAttesa)), specieAttesa)
        }
        for specieAttesa in SpecieDiComandoCampagna.allCases {
            XCTAssertEqual(specie(di: esemplare(di: specieAttesa)), specieAttesa)
        }
    }

    // MARK: - Attrezzi

    private func chiaviAttese(_ specie: [SpecieDiVoce],
                              _ costruisci: (SpecieDiVoce) -> VoceGiornale) throws -> Set<String> {
        Set(try specie.map {
            try chiaveCodificata(di: RigaGiornale(numero: 1, voce: costruisci($0)), dentro: "voce")
        })
    }

    /// La chiave di primo livello che il codificatore sintetizzato scrive per il
    /// caso: è il NOME del caso, ed è formato di salvataggio a tutti gli effetti.
    private func chiaveCodificata(di riga: RigaGiornale, dentro campo: String) throws -> String {
        let dati = try JSONEncoder().encode(riga)
        let chiavi = try chiaviDiPrimoLivelloDellaVoce(dati)
        return try XCTUnwrap(chiavi.first, "la voce non ha alcuna chiave di caso")
    }

    /// Le chiavi di primo livello dell'oggetto `voce`: il nome del caso codificato.
    private func chiaviDiPrimoLivelloDellaVoce(_ dati: Data) throws -> Set<String> {
        guard let radice = try JSONSerialization.jsonObject(with: dati) as? [String: Any],
              let voce = radice["voce"] as? [String: Any] else { return [] }
        return Set(voce.keys)
    }
}
