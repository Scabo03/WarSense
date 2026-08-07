import Foundation

/// Carica e valida i valori del piano di campagna (05 §7.6, §7.8). Vive accanto al
/// caricatore dei valori di battaglia e ne condivide la disciplina: schema, tipi,
/// completezza, coerenza; un fallimento produce un rapporto a chiavi di testo.
public enum CaricatoreCampagna {

    /// La cartella delle mappe dentro l'albero dei valori.
    public static let cartellaMappe = "Mappe"

    public static func carica(da cartella: URL) throws -> ValoriCampagna {
        let decoder = JSONDecoder()

        func dati(_ nome: String) throws -> Data {
            let url = cartella.appendingPathComponent(nome)
            guard let d = try? Data(contentsOf: url) else {
                throw ErroreDati(chiave: "errore.dati.file_mancante", file: nome)
            }
            return d
        }
        func leggi<T: Decodable>(_ tipo: T.Type, _ nome: String) throws -> T {
            do { return try decoder.decode(tipo, from: try dati(nome)) }
            catch let e as ErroreDati { throw e }
            catch { throw ErroreDati(chiave: "errore.dati.file_malformato", file: nome) }
        }

        let formatiElenco = try leggi([FormatoMappa].self, "formati-mappa.json")
        var formati: [IdentificatoreDati: FormatoMappa] = [:]
        for f in formatiElenco {
            guard formati[f.identificatore] == nil else {
                throw ErroreDati(chiave: "errore.dati.identificatore_duplicato",
                                 file: "formati-mappa.json", voce: f.identificatore)
            }
            // Una mappa di meno di due caselle per lato non ha adiacenza da percorrere.
            guard f.righe >= 2, f.colonne >= 2 else {
                throw ErroreDati(chiave: "errore.dati.formato_incoerente",
                                 file: "formati-mappa.json", voce: f.identificatore)
            }
            formati[f.identificatore] = f
        }
        guard !formati.isEmpty else {
            throw ErroreDati(chiave: "errore.dati.elenco_vuoto", file: "formati-mappa.json")
        }

        let nomi = try leggi(NomiGruppi.self, "nomi-gruppi.json")
        guard !nomi.chiavi.isEmpty, Set(nomi.chiavi).count == nomi.chiavi.count else {
            throw ErroreDati(chiave: "errore.dati.nomi_gruppi_incoerenti", file: "nomi-gruppi.json")
        }

        // Il costo in giorni dello scatto (01 §5.6.3.1): valore esplicito nei dati,
        // mai una costante nel codice (00 §13.1). Il minimo è uno, perché uno scatto
        // a costo zero sarebbe il difetto sfruttabile che 00 §13.6 vieta.
        let marcia = try leggi(ValoriMarcia.self, "marcia-campagna.json")
        guard marcia.costoGiorniBase >= 1 else {
            throw ErroreDati(chiave: "errore.dati.costo_marcia_incoerente",
                             file: "marcia-campagna.json")
        }
        // Le nove posizioni dell'avanzamento visivo (01 §5.6.3.4): almeno una, o la
        // proporzione non si discretizzerebbe e il troncamento dividerebbe per zero.
        guard marcia.posizioniVisive >= 1 else {
            throw ErroreDati(chiave: "errore.dati.costo_marcia_incoerente",
                             file: "marcia-campagna.json")
        }
        // I pesi confluiscono in una sola grandezza (01 §5.6.3.2) e nessun terreno o
        // strada può restare senza peso: un peso mancante sarebbe un fattore che si
        // somma in modo opaco, cioè per omissione. Si respinge la copia incompleta
        // invece di applicare un valore sottinteso (00 §13.1, §13.6).
        let terreniAttesi = Set(TerrenoCasella.allCases.map(\.rawValue))
        let stradeAttese = Set(TipoStrada.allCases.map(\.rawValue))
        guard Set(marcia.pesoTerrenoPartenza.keys) == terreniAttesi,
              Set(marcia.pesoTerrenoArrivo.keys) == terreniAttesi,
              Set(marcia.pesoStradaArrivo.keys) == stradeAttese else {
            throw ErroreDati(chiave: "errore.dati.costo_marcia_incoerente",
                             file: "marcia-campagna.json")
        }

        // Le mappe sono un albero di file: ciascuna è contenuto a sé (05 §7.6).
        let cartellaDelleMappe = cartella.appendingPathComponent(cartellaMappe)
        let contenuti = (try? FileManager.default.contentsOfDirectory(
            at: cartellaDelleMappe, includingPropertiesForKeys: nil)) ?? []
        var mappe: [IdentificatoreDati: DefinizioneMappa] = [:]
        for url in contenuti.filter({ $0.pathExtension == "json" }).sorted(by: { $0.path < $1.path }) {
            let nome = cartellaMappe + "/" + url.lastPathComponent
            let mappa = try leggi(DefinizioneMappa.self, nome)
            guard mappe[mappa.identificatore] == nil else {
                throw ErroreDati(chiave: "errore.dati.identificatore_duplicato",
                                 file: nome, voce: mappa.identificatore)
            }
            try valida(mappa: mappa, nomeFile: nome, formati: formati)
            mappe[mappa.identificatore] = mappa
        }
        guard !mappe.isEmpty else {
            throw ErroreDati(chiave: "errore.dati.elenco_vuoto", file: cartellaMappe)
        }

        return ValoriCampagna(formatiMappa: formati, mappe: mappe,
                              nomiGruppi: nomi.chiavi, marcia: marcia)
    }

    /// Coerenza di una mappa (05 §7.8): formato noto, caselle dentro i confini e
    /// non ripetute, al più una strettoia, quartier generali in ultima riga dalla
    /// propria parte e mai sulla stessa casella.
    static func valida(mappa: DefinizioneMappa, nomeFile: String,
                       formati: [IdentificatoreDati: FormatoMappa]) throws {
        guard let formato = formati[mappa.formato] else {
            throw ErroreDati(chiave: "errore.dati.formato_ignoto", file: nomeFile, voce: mappa.formato)
        }
        func dentro(_ p: PosizioneMappa) -> Bool {
            p.riga >= 1 && p.riga <= formato.righe && p.colonna >= 1 && p.colonna <= formato.colonne
        }
        var viste = Set<PosizioneMappa>()
        for casella in mappa.caselle {
            let posizione = PosizioneMappa(riga: casella.riga, colonna: casella.colonna)
            guard dentro(posizione) else {
                throw ErroreDati(chiave: "errore.dati.casella_fuori_mappa", file: nomeFile,
                                 voce: mappa.identificatore)
            }
            guard viste.insert(posizione).inserted else {
                throw ErroreDati(chiave: "errore.dati.casella_ripetuta", file: nomeFile,
                                 voce: mappa.identificatore)
            }
        }
        // La strettoia è al più una (01 §5.1.3): la forma del campo lo impone già,
        // essendo un singolo valore facoltativo; resta da verificarne la posizione.
        if let strettoia = mappa.strettoia, !dentro(strettoia) {
            throw ErroreDati(chiave: "errore.dati.strettoia_fuori_mappa", file: nomeFile,
                             voce: mappa.identificatore)
        }
        let qg = mappa.quartierGenerali
        guard dentro(qg.giocatore), dentro(qg.avversario), qg.giocatore != qg.avversario else {
            throw ErroreDati(chiave: "errore.dati.quartier_generale_incoerente", file: nomeFile,
                             voce: mappa.identificatore)
        }
        // Ciascuna parte ha il proprio quartier generale in ultima riga dalla propria
        // parte (01 §5.14.3.2). La riga 1 è dalla parte dell'avversario, come sul
        // campo di battaglia, dove la riga 1 è la sua retrolinea (01 §7.3).
        guard qg.avversario.riga == 1, qg.giocatore.riga == formato.righe else {
            throw ErroreDati(chiave: "errore.dati.quartier_generale_non_in_ultima_riga",
                             file: nomeFile, voce: mappa.identificatore)
        }
    }
}
