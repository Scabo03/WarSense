import Foundation
import Sessione
import Motore
import Dati
import Contenuti

// Il programma di verifica del bilanciamento (00 §16.1, 05 §12) prende forma nella
// fase C. Questo scheletro carica i valori di fabbrica e dichiara la versione:
// garantisce fin d'ora che Motore e Dati restino simulabili senza interfaccia (05 §14.7).
// L'uscita è per la persona che sviluppa, in forma di dati, non testo di prodotto.

do {
    let valori = try CaricatoreValori.carica(da: Contenuti.valoriDiFabbrica)
    print("verifica.valori.versione=\(valori.versioneEffettiva)")
    print("verifica.archetipi=\(valori.archetipi.count)")
    print("verifica.formati=\(valori.formati.count)")
} catch {
    print("verifica.errore=\(error)")
    exit(1)
}
