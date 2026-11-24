# La misura della frequenza delle battaglie, ripetuta (incarico 31)

> Corsa sul codice del commit `c3b5e2a` del ramo `incarico-31` (albero dei sorgenti pulito). Una prima corsa a tappa non ancora chiusa aveva dato gli stessi dati grezzi: quella conservata qui è la ripetizione sul codice committato (9 s, `date +%s`).

L'incarico chiede di ripeterla se la tappa tocca il Motore della campagna. La seconda tappa del regno lo tocca in tre punti (RDA-175, RDA-177): i nomi dei gruppi, che uno scenario può ora dichiarare e che una campagna può riservare, con la ricerca del primo nome libero per chi nasce sul fronte; gli arrivi dalla patria, consegnati all'apertura di ogni giornata; il reparto, che può portare un miglioramento e un anno di leva, con i superstiti di una battaglia raggruppati anche per quei due tratti. Tutti e tre sono attivi soltanto dove lo scenario li dichiara, cioè nella campagna dell'anno di un regno.

La misura principale dell'incarico 29 gioca le tre campagne di prova, che non dichiarano né nomi, né nomi riservati, né arrivi, né miglioramenti. Ripetuta con gli stessi parametri dà dati grezzi identici byte per byte.

- Comando: `cd Codice && swift build -c release --product StrumentoVerifica && .build/release/StrumentoVerifica --frequenza-battaglie 200 --giornate-massime 730 --uscita ../Incarichi/31-2026-11-23-prodotti/frequenza-battaglie`. Durata della corsa: 7 s (`date +%s` attorno al comando). Il tetto di 730 giornate è quello della corsa dell'incarico 29: senza quell'opzione lo strumento ne usa 365, e le righe differiscono nel campo delle giornate.
- `frequenza-battaglie.jsonl`: 1200 righe, una per partita (`wc -l`). `frequenza-battaglie.txt`: il riepilogo stampato dallo strumento.
- `confronto-con-l-incarico-29.txt`: le due impronte SHA-256 (d2e2002b608282802aec36269b40aa4f0c08df5bfb03bb99173da79ae5fca567 per entrambi i file), l'esito di `cmp` (nessuna differenza) e quello di `diff` sui due riepiloghi, che differiscono nella sola riga `frequenza.versione_valori`: 0.15.0 al posto di 0.14.0 (RDA-181). Il termine di confronto è `Incarichi/29-2026-11-21-prodotti/frequenza-battaglie/base/`.

Che cosa dimostra: le campagne senza calendario, senza nomi dichiarati e senza arrivi si svolgono come prima; e quindi che le campagne di prova salvate con i valori 0.14.0 proseguono identiche con i valori 0.15.0. Che cosa non dimostra: nulla sulle campagne del regno, che sono misurate dal banco del regno: `../banco-del-regno/`.
