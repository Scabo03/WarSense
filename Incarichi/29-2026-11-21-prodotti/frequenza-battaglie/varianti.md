# Le varianti misurate per la proposta (nessun valore del gioco cambiato)

Ogni variante è una COPIA TEMPORANEA della cartella dei valori, modificata in un solo punto e con le impronte del manifest rigenerate nella copia; la misura è la stessa della principale (200 partite per formato e condotta, 730 giornate), con `--valori <copia>`. I valori del gioco non sono toccati.

| variante | che cosa cambia nella copia |
|---|---|
| `aggressivita-300` | `condotta-campagna.json`: `aggressivita` 100 → 300 (pari a `minaccia_rifornimento`) |
| `aggressivita-700` | `condotta-campagna.json`: `aggressivita` 100 → 700 (sopra `difesa_quartier_generale`, 600) |
| `difesa-150` | `condotta-campagna.json`: `difesa_quartier_generale` 600 → 150, `minaccia_rifornimento` 300 → 75 (l'avanzata, 100, diventa il peso dominante dopo la difesa) |
| `raggio-3` | `conoscenza-campagna.json`: `raggio_osservazione` 2 → 3; `ricognizione-campagna.json`: `raggio_esplorazione` 3 → 4 (il caricatore pretende l'esplorazione più ampia dell'osservazione e rifiuta la copia altrimenti: `errore.dati.ricognizione_incoerente`) |
| `due-armati-avversari` | `scenari-campagna.json`: in ciascun formato un secondo gruppo armato avversario, copia del primo (stessa composizione), nella prima casella libera accanto (piccola 1,3 → occupata, quindi 1,1; media 1,4; grande 1,6) |

Lo script che ha prodotto le copie è `crea-varianti.py` (in questa cartella).
