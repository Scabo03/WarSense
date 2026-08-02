import Foundation

/// Manifest dei valori (05 §7.2).
public struct ManifestValori: Codable, Sendable {
    public let versione: String
    /// Nome file → impronta SHA-256 esadecimale.
    public let impronte: [String: String]
    /// Versioni di salvataggio compatibili (05 §6.6).
    public let versioniCompatibili: [String]
    enum CodingKeys: String, CodingKey {
        case versione, impronte
        case versioniCompatibili = "versioni_compatibili"
    }
}

/// Fallimento di caricamento o validazione: ogni caso è una chiave di testo,
/// risolta esclusivamente sulla copia di fabbrica dei testi (05 §7.8).
public struct ErroreDati: Error, Sendable {
    public let chiave: String
    public let file: String
    public let voce: String?
    public init(chiave: String, file: String, voce: String? = nil) {
        self.chiave = chiave; self.file = file; self.voce = voce
    }
}

/// Carica e valida l'albero dei valori (05 §7). Il caricamento avviene una volta
/// per sessione e i valori restano fissi fino alla chiusura dello slot (05 §7.9).
public enum CaricatoreValori {

    public static func carica(da cartella: URL) throws -> ValoriDiGioco {
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

        let manifest = try leggi(ManifestValori.self, "manifest.json")

        // Impronte: se discordanti ma i contenuti sono validi, versione locale derivata (RDA-45, 05 §7.2.1).
        var discordanti = false
        var accumulatore = Data()
        for (nome, attesa) in manifest.impronte.sorted(by: { $0.key < $1.key }) {
            let effettiva = SHA256.improntaEsadecimale(try dati(nome))
            accumulatore.append(Data(effettiva.utf8))
            if effettiva != attesa { discordanti = true }
        }

        let archetipiElenco = try leggi([DefinizioneArchetipo].self, "archetipi.json")
        let protezioni = try leggi([TipoProtezione: ProfiloProtezione].self, "offese-e-protezioni.json")
        let formatiElenco = try leggi([FormatoBattaglia].self, "formato-battaglia.json")
        let caratteristicheElenco = try leggi([CaratteristicaCampo].self, "caratteristiche-campo.json")
        let minimi = try leggi(Minimi.self, "minimi.json")
        let combattimento = try leggi(ParametriCombattimento.self, "combattimento.json")

        var archetipi: [IdentificatoreDati: DefinizioneArchetipo] = [:]
        for a in archetipiElenco {
            guard archetipi[a.identificatore] == nil else {
                throw ErroreDati(chiave: "errore.dati.identificatore_duplicato", file: "archetipi.json", voce: a.identificatore)
            }
            archetipi[a.identificatore] = a
        }
        var formati: [IdentificatoreDati: FormatoBattaglia] = [:]
        for f in formatiElenco { formati[f.identificatore] = f }
        var caratteristiche: [IdentificatoreDati: CaratteristicaCampo] = [:]
        for c in caratteristicheElenco { caratteristiche[c.identificatore] = c }

        try validaContenuti(archetipi: archetipi, protezioni: protezioni, formati: formati,
                            minimi: minimi, combattimento: combattimento)

        let versioneEffettiva: String
        if discordanti {
            let suffisso = String(SHA256.improntaEsadecimale(accumulatore).prefix(8))
            versioneEffettiva = manifest.versione + "+" + suffisso
        } else {
            versioneEffettiva = manifest.versione
        }

        return ValoriDiGioco(versione: manifest.versione,
                             versioneEffettiva: versioneEffettiva,
                             modificatiLocalmente: discordanti,
                             archetipi: archetipi,
                             protezioni: protezioni,
                             formati: formati,
                             caratteristiche: caratteristiche,
                             minimi: minimi,
                             combattimento: combattimento)
    }

    /// Validazione dei contenuti (05 §7.8), oltre la forma: completezza e coerenza.
    private static func validaContenuti(archetipi: [IdentificatoreDati: DefinizioneArchetipo],
                                        protezioni: [TipoProtezione: ProfiloProtezione],
                                        formati: [IdentificatoreDati: FormatoBattaglia],
                                        minimi: Minimi,
                                        combattimento: ParametriCombattimento) throws {
        guard !archetipi.isEmpty else { throw ErroreDati(chiave: "errore.dati.elenco_vuoto", file: "archetipi.json") }
        for (id, a) in archetipi {
            guard a.puntiVitaPerAtomo > 0, a.volumePerAtomo > 0 else {
                throw ErroreDati(chiave: "errore.dati.valore_non_positivo", file: "archetipi.json", voce: id)
            }
            // Due gittate: la pericolosità non supera il disturbo (01 §3.4.1: disturbo ≥ pericolosità).
            guard a.gittataDisturbo >= a.gittataPericolosita else {
                throw ErroreDati(chiave: "errore.dati.gittate_incoerenti", file: "archetipi.json", voce: id)
            }
            // Chi ha offese da tiro ha dotazione, e viceversa.
            guard (a.offeseTiro.isEmpty) == (a.dotazioneMunizioni == 0) else {
                throw ErroreDati(chiave: "errore.dati.tiro_incoerente", file: "archetipi.json", voce: id)
            }
            guard a.sogliaDisingaggio > .zero, a.sogliaDisingaggio <= .uno else {
                throw ErroreDati(chiave: "errore.dati.soglia_fuori_intervallo", file: "archetipi.json", voce: id)
            }
        }
        for tipo in TipoProtezione.allCases where protezioni[tipo] == nil {
            throw ErroreDati(chiave: "errore.dati.protezione_mancante", file: "offese-e-protezioni.json", voce: tipo.rawValue)
        }
        guard !formati.isEmpty else { throw ErroreDati(chiave: "errore.dati.elenco_vuoto", file: "formato-battaglia.json") }
        for (id, f) in formati {
            guard f.righe >= 3, f.colonne >= 3, f.righeDiPiazzamento >= 2,
                  f.righeDiPiazzamento < f.righe / 2 + 1,
                  f.budgetVolumeBase > 0, f.coefficientePrimoTurno >= .uno,
                  f.quotaRiporto >= .zero, f.quotaRiporto <= .uno,
                  f.turniVantaggioImboscante >= 1, f.sogliaMinimaResaTurni >= 1 else {
                throw ErroreDati(chiave: "errore.dati.formato_incoerente", file: "formato-battaglia.json", voce: id)
            }
        }
        guard minimi.dannoMinimo >= 1, minimi.costoPiazzamentoMinimo >= 1, minimi.atomiMinimiSciameVivo >= 1 else {
            throw ErroreDati(chiave: "errore.dati.minimi_sotto_uno", file: "minimi.json")
        }
        guard combattimento.efficaciaMinima > .zero else {
            throw ErroreDati(chiave: "errore.dati.efficacia_minima_nulla", file: "combattimento.json")
        }
    }
}
