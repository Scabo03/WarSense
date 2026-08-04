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

var cartellaValori = Ambiente.valoriDiFabbrica
var cartellaScenari = Ambiente.scenariDiFabbrica
var cartellaScenariCampagna: URL? = Ambiente.scenariCampagnaDiFabbrica
var cartellaUscita: URL?
var fumo = false

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
    default:
        FileHandle.standardError.write(Data(("verifica.argomento_ignoto=" + argomento + "\n").utf8))
        exit(2)
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
