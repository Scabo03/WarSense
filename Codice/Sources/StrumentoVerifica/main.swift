import Foundation
import Verifica

// Il guscio da riga di comando del programma di verifica (05 §12.1). Tutta la
// misura vive nella libreria Verifica, così che il fumo delle simulazioni sia
// collaudabile come qualunque altro bersaglio (05 §14.7, RDA-58).
//
// Uso:
//   swift run StrumentoVerifica
//   swift run StrumentoVerifica --valori <cartella> --scenari <cartella> --uscita <cartella> --fumo
//   swift run StrumentoVerifica --scenari-campagna <cartella> | --senza-campagna
//   swift run -c release StrumentoVerifica --frequenza-battaglie <partite> [--giornate-massime <n>] [--uscita <cartella>]
//     la misura della frequenza delle battaglie (incarico 29): <partite> partite intere per formato e per
//     condotta del giocatore, sugli scenari del gioco; scrive i dati grezzi (una riga JSON per partita)
//     e il riepilogo per formato e condotta.

var cartellaValori = Ambiente.valoriDiFabbrica
var cartellaScenari = Ambiente.scenariDiFabbrica
var cartellaScenariCampagna: URL? = Ambiente.scenariCampagnaDiFabbrica
var cartellaUscita: URL?
var fumo = false
var partiteFrequenza: Int?
var giornateMassime = 365

var argomenti = Array(CommandLine.arguments.dropFirst())
while let argomento = argomenti.first {
    argomenti.removeFirst()
    switch argomento {
    case "--valori":
        guard let valore = argomenti.first else { break }
        argomenti.removeFirst()
        cartellaValori = URL(fileURLWithPath: valore)
    case "--scenari":
        guard let valore = argomenti.first else { break }
        argomenti.removeFirst()
        cartellaScenari = URL(fileURLWithPath: valore)
    case "--uscita":
        guard let valore = argomenti.first else { break }
        argomenti.removeFirst()
        cartellaUscita = URL(fileURLWithPath: valore)
    case "--scenari-campagna":
        guard let valore = argomenti.first else { break }
        argomenti.removeFirst()
        cartellaScenariCampagna = URL(fileURLWithPath: valore)
    case "--senza-campagna":
        cartellaScenariCampagna = nil
    case "--fumo":
        fumo = true
    case "--frequenza-battaglie":
        guard let valore = argomenti.first, let n = Int(valore) else { break }
        argomenti.removeFirst()
        partiteFrequenza = n
    case "--giornate-massime":
        guard let valore = argomenti.first, let n = Int(valore) else { break }
        argomenti.removeFirst()
        giornateMassime = n
    default:
        FileHandle.standardError.write(Data(("verifica.argomento_ignoto=" + argomento + "\n").utf8))
        exit(2)
    }
}

if let partite = partiteFrequenza {
    do {
        let rapporto = try FrequenzaBattaglieDaRigaDiComando.esegui(
            cartellaValori: cartellaValori, partite: partite, giornateMassime: giornateMassime)
        if let cartellaUscita {
            try FileManager.default.createDirectory(at: cartellaUscita, withIntermediateDirectories: true)
            try rapporto.grezzi.write(to: cartellaUscita.appendingPathComponent("frequenza-battaglie.jsonl"),
                                      atomically: true, encoding: .utf8)
            try rapporto.testo.write(to: cartellaUscita.appendingPathComponent("frequenza-battaglie.txt"),
                                     atomically: true, encoding: .utf8)
        }
        print(rapporto.testo)
        exit(0)
    } catch {
        FileHandle.standardError.write(Data(("verifica.errore=\(error)\n").utf8))
        exit(1)
    }
}

do {
    let programma = ProgrammaDiVerifica(cartellaValori: cartellaValori,
                                        cartellaScenari: cartellaScenari,
                                        cartellaScenariCampagna: cartellaScenariCampagna,
                                        fumo: fumo)
    let rapporto = try programma.esegui()
    if let cartellaUscita {
        try rapporto.scrivi(in: cartellaUscita)
        print("verifica.uscita=" + cartellaUscita.path)
    } else {
        print(rapporto.testo)
    }
} catch {
    FileHandle.standardError.write(Data(("verifica.errore=\(error)\n").utf8))
    exit(1)
}
