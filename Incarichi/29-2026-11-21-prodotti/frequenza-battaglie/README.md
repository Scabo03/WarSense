# La frequenza delle battaglie — misura col banco (incarico 29)

## Lo strumento e i comandi

- Strumento: `MisuraFrequenzaBattaglie` (`Codice/Sources/Verifica/MisuraFrequenzaBattaglie.swift`), eseguito dallo strumento di verifica:
  `cd Codice && swift build -c release --product StrumentoVerifica && .build/release/StrumentoVerifica --frequenza-battaglie 200 --giornate-massime 730 --uscita <cartella>` (con `--valori <cartella>` per le varianti).
- Dati grezzi: `base/frequenza-battaglie.jsonl` (1200 partite, una riga JSON per partita) e `variante-*/frequenza-battaglie.jsonl`; il riepilogo dello strumento accanto, in `frequenza-battaglie.txt` (con la versione dei valori della corsa).
- Tabelle: `tabelle.md`, prodotte da `python3 scripts/riassumi-frequenza-battaglie.py <file.jsonl>…` sulle righe grezze. Nessun numero delle tabelle è calcolato a mano.
- Prove dello strumento: `MisuraFrequenzaBattaglieTest` (la condotta competente con sfasamento 0 dà la stessa impronta finale del banco su 3 dei 4 scenari del banco con l'avversario; il quarto il banco lo chiude al giorno 10 e non è confrontabile; le partite misurate sono coerenti e senza invarianti violati; le due partite che avevano due gruppi nella stessa casella non ne hanno più).

## Il metodo

- Scenari: i tre del gioco (`scenari-campagna.json`), quelli che aprono i pulsanti «Nuova campagna, mappa piccola / media / grande». In tutti e tre l'avversario ha UN gruppo armato, un gruppo di ricognizione e una formazione non armata; il giocatore ha da due a cinque gruppi armati.
- Avversario: la condotta deterministica del gioco (`CondottaAvversaria`). Battaglie: il modello del banco (`BancoCampagna`: campo aperto, due tattici deterministici col primo ufficiale, tetto di 400 giri e 40000 passi).
- Due condotte del giocatore, 200 partite ciascuna per formato:
  - competente: la condotta del banco (`BancoCampagna.corri`), regola per regola; le partite variano per uno sfasamento (seme modulo 420) delle regole periodiche e della scelta della destinazione. Dove una regola darebbe un ordine che il Motore respinge, vale la successiva (accade con lo sfasamento: un gruppo che deve rifornirsi riceverebbe il sabotaggio).
  - prudente: il modello del tester dell'incarico 28 — i gruppi in attesa nell'ordine di lettura; un armato marcia di una casella a nord, se libera e valida, con probabilità un mezzo (il tester ne muoveva uno su due); altrimenti esplora, presidia o sosta. In battaglia combatte il tattico del banco: la resa del tester dopo il quattordicesimo turno non è riprodotta.
- Fine naturale: una parte resta senza gruppi armati (la definizione della prova delle partite intere dell'incarico 26: la campagna non ha altra condizione di vittoria). Limite: 730 giornate; quattro partite lo superano di una a tre giornate, perché una cascata di chiusure può far avanzare più giorni in un passo.
- Le battaglie che non si concludono entro i tetti del banco fermano la partita e si registrano (`motivo_ferma`, una chiave con i suoi valori: giri, giorno, casella, imboscata): il banco si fermerebbe sulla precondizione di `PonteCampagnaBattaglia.esito`. Dove stavano lo dice la tabella «Le partite ferme…» di `tabelle.md`, ricavata dal motivo e dalle mappe del gioco.
- Gli invarianti dello stato: dopo ogni cambiamento dello stato lo strumento interroga `SondaInvariantiCampagna.controlla(stato:)`; ogni riga grezza porta i codici violati (`violazioni`, vuoto se nessuno) e il giorno della prima violazione (`giorno_prima_violazione`). La prova di coerenza delle partite misurate pretende che siano vuoti.

## La riproducibilità, e il difetto che la misura ha trovato (RDA-161)

Rigenerati i dati con lo strumento, una partita (media, competente, seme 179) è uscita diversa dalla corsa precedente: sei corse in processi diversi alternavano due esiti, quattro corse con `SWIFT_DETERMINISTIC_HASHING=1` davano sempre lo stesso, cioè l'esito dipendeva dall'ordine dei dizionari, che cambia a ogni processo. La causa, trovata confrontando l'impronta dello stato passo per passo fra due processi, era nel Motore: lo sconfitto di una battaglia poteva ripiegare nella meta di una marcia propria in corso, e all'arrivo della marcia due gruppi del giocatore stavano nella stessa casella (01 §5.6.0.2); da lì la scelta del gruppo della battaglia successiva seguiva l'ordine del dizionario. Prima della correzione la sonda vedeva la violazione in 2 partite su 1200 (media competente seme 179 dal giorno 77, grande competente seme 196 dal giorno 41), nessun'altra violazione. Dopo: nessuna violazione nelle 1200 partite né nelle 6000 delle varianti, e tre corse in processi diversi danno le stesse 1200 partite, riga per riga. Tutti i dati di questa cartella sono stati rigenerati DOPO la correzione, con i valori 0.14.0; delle 1200 partite della misura principale cambiano soltanto le due toccate dal difetto.

## Il ritmo atteso nei documenti

Nessun numero. 01 §5.6.2 descrive un ritmo «a titolo illustrativo e senza valore normativo» e dice che «il ritmo non va progettato: discende dalle regole»; 01 §6.1.3 e §16.4 e 03 §6.5 affidano la frequenza effettiva degli scontri al carattere degli ufficiali avversari, da tarare con le simulazioni; il registro delle decisioni (conferma del titolare sull'imposizione della battaglia) prevede che «gli scontri campali della prima versione avverranno quasi soltanto contro chi non può o non vuole sfilarsi» e affida il peso di questa scelta alla taratura del carattere degli ufficiali e della velocità delle colonne; `valori-provvisori.md` dichiara provvisoria l'`aggressivita` (100), «la manopola che 01 §6.1.3 dichiara decidere molto più di prima la frequenza degli scontri».

## Le tabelle

Sono in `tabelle.md`, una per la misura principale e una per ciascuna variante, e nel resoconto.
