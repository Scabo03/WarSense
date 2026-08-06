# Resoconto — Misura di S10, e due chiarimenti sui numeri della sessione precedente

Ramo di lavoro `07-misura-s10-e-chiarimenti`, aperto da `principale` a `309ca11`. Precondizioni verificate: `principale` a `309ca11`, albero pulito, 32 commit avanti su `origin/principale` non spinti. Commit: `23836ae` (incarico verbatim), più i commit di S10 e del resoconto in coda.

---

# I due chiarimenti (in testa, separati dal resto)

## Chiarimento 1 — che cosa comprende il numero 163, e il confronto valido

**Che cosa comprende 163,18 s.** È il `finishTime − startTime` del fascio di risultati dell'INTERA parte simulatore del collaudo ridotto (corsa `blsltzwas` della sessione 06): tutte le 64 prove ospitate e d'interfaccia (`WarSenseTest` 56 + `WarSenseUITest` 8), **compreso** il sottoinsieme di 24 sessioni (`SessioniPerInterfacciaTest.test_00_3_1`), più un solo avvio/spegnimento del simulatore. Comando che lo produce: `xcrun xcresulttool get test-results summary` sul fascio del collaudo. **Non fu misurato in isolamento**: la sessione 06 aveva appena costruito e caricato la build, e io lavoravo alla documentazione mentre `blsltzwas` girava.

**Perché non è 121,7 + 34,4 = 156,1 (somma calcolata a mano, marcata come tale).** Quattro ragioni, non una:
1. **Strumenti diversi.** 121,7 (sessione 04) veniva da `IDETestOperationsObserverDebug: … elapsed`; 34,4 (sessione 04) era una misura isolata del sottoinsieme; 163,18 è `xcresult finishTime−startTime`. Tre strumenti diversi non si sommano.
2. **Ambiti diversi.** 121,7 era SENZA alcuna `SessioniPerInterfacciaTest`; 163,18 INCLUDE il sottoinsieme di 24. Non sono lo stesso insieme di prove.
3. **Un solo avvio.** Una corsa intera ha UN avvio del simulatore, non la somma di due corse ciascuna col proprio.
4. **Non-isolamento.** 163,18 è gonfiato dal non-isolamento.

La riga del resoconto 06 che metteva `122`, `1363,7` e `163,18` nella stessa colonna «simulatore» **mescolava strumenti**: 122 e 1363,7 erano `IDETestOperations elapsed` della sessione 04, 163,18 era `xcresult` della sessione 06. Il numero 163,18 non è sbagliato per ciò che misura; è il CONFRONTO a non reggere. Se la sessione 04 girò su una macchina diversa da questa non è verificato, e va dichiarato non verificato.

**Il confronto valido**, rimisurato ORA su iPhone Air, un solo strumento (`xcresult finishTime−startTime`), ciascuno **in isolamento** (script sequenziale `misura-collaudo.sh`, nessun'altra corsa; comando `xcodebuild test-without-building` per variante):

| grandezza | valore | strumento |
|---|---|---|
| A — parte simulatore del collaudo attuale (64 prove, incl. sottoinsieme 24) | **156,88 s** | xcresult finishTime−startTime |
| B — baseline SENZA `SessioniPerInterfacciaTest` (63 prove) | **120,21 s** | idem |
| C — sottoinsieme 24 da solo (`test_00_3_1`) | **42,01 s** | idem |
| A − B — costo marginale del sottoinsieme nel collaudo | **36,67 s** | `python3` (differenza), derivato |
| scarto di 163,18 (sess. 06, non isolato) da A (156,88 isolato) | **6,3 s** | `python3`, derivato |
| scarto di B (120,21) da 121,7 (sess. 04, IDETestOperations) | **1,49 s** | `python3`, derivato |

Letture: il baseline senza sessioni è **~120 s** e regge fra strumenti e sessioni (scarto 1,49 s da 121,7). La parte simulatore del collaudo ridotto è **156,88 s in isolamento** (i 163,18 della sessione 06 erano ~6 s più alti per il non-isolamento). Il sottoinsieme aggiunge **36,67 s** al baseline (marginale), vicino ai 34,4 s della sessione 04; da solo, con il proprio avvio, costa 42,01 s. Il pacchetto è **29,984 s** questa corsa (`swift test`, esecutore), coerente con i 29,5 s dichiarati.

## Chiarimento 2 — le quattro prove del pacchetto aggiunte, e il conteggio dall'esecutore

Le quattro prove che portano il pacchetto da 232 a 236 sono tutte in `Codice/Tests/DatiTest/CaricamentoTest.swift`, introdotte dal commit **`2125032`** (il cancello sul manifest dei testi), verificato con `git show 2125032 -- Codice/Tests/DatiTest/CaricamentoTest.swift`:

| prova | regola | che cosa verifica |
|---|---|---|
| `test_05_7_2_testi_di_fabbrica_coincidono_con_le_impronte` | 05 §7.2 | la fabbrica dei testi coincide con le proprie impronte; fallisce se un file è alterato senza rigenerare il manifest |
| `test_05_7_2_testo_alterato_senza_rigenerare_respinto` | 05 §7.2 | una copia con un testo alterato è respinta con `errore.testi.impronta_discorde` |
| `test_05_7_2_testo_mancante_respinto` | 05 §7.2 | un file elencato ma assente è respinto con `errore.testi.file_mancante` |
| `test_05_7_1_al_rifiuto_segue_il_ripiego_sulla_fabbrica` | 05 §7.1 | dopo il rifiuto della copia divergente, i testi della fabbrica funzionano |

**Il conteggio 236 viene dall'ESECUTORE**, non da uno scanner: `swift test` (da `Codice/`) stampa «Executed 236 tests, with 1 test skipped and 0 failures (0 unexpected) in 29,984 seconds». Comando che lo stampa: `cd Codice && swift test`.

---

# La misura di S10

Misurato e non corretto. S10 **resta aperto**. Le misure complete e l'accertamento sono nella voce S10 di `registro-scostamenti.md`; qui la sintesi.

**Come.** Arnese temporaneo `MisuraS10Temp` (una sola misura, nessuna asserzione), **rimosso a misura presa** perché non è una prova; i numeri vengono dalle righe `MISURA_S10` stampate ed eseguite con `xcodebuild test -only-testing:WarSenseTest/MisuraS10Temp`. Griglia formato `cento` (10×10, scenario di prova). Misure di GEOMETRIA, non di tempo; dichiarati apparecchio, orientamento e taglia per ciascuna. La parte simulatore per iPhone Air e iPad è stata eseguita in parallelo (geometria, non tempo: il parallelismo è ammesso).

**Contenuto della griglia: `696×584` ovunque** — le celle non scalano con la taglia di carattere (`VistaGriglia` a passi fissi); cambiano la porzione visibile e il deck, non il contenuto.

**Risultato principale (iPhone Air, verticale, taglia predefinita).** A riposo la fila arretrata (cella a `y` contenuto 516–576) è sotto la porzione visibile (`420×421,7`) e sconfina sotto la colonna del deck (`deckTop` 497,7) — è ciò che S10 osservava. **Ma portando lo scorrimento al massimo (162,3 punti) la cella entra INTERAMENTE** (`visibileAlMax=true`, `fuoriAlMax=0`). **Non dipende dalla sola geometria:** la cella ci sta se si scorre fino in fondo, e il «scorrere non basta» è lo scorrimento SINTETICO di XCUITest che non raggiunge i 162,3 punti. Vale in entrambi gli stati: con una tessera selezionata la porzione visibile resta `421,7` identica — la correzione di `TesseraDeck` (`valoreDiRiserva`) regge, selezionare non restringe più la griglia.

**iPad Pro 13": il fenomeno non si presenta.** La fila arretrata entra al massimo scorrimento in tutte le otto configurazioni; in verticale a taglia predefinita l'intera griglia è visibile senza scorrere (`maxOffset=0`, porzione `1032×757`).

**Un secondo fenomeno, più grave, e questo È geometrico.** Sull'iPhone Air la porzione visibile della griglia COLLASSA a `0` a taglia `AXXXL` in verticale (`420×0`) e in ORIZZONTALE a qualunque taglia (`Info.plist` dichiara tutti e quattro gli orientamenti, quindi è reale): il deck, la cui altezza intrinseca cresce con la tipografia dinamica, su schermo di altezza fissa lascia zero alla griglia. In orizzontale l'altezza disponibile (420 − 102 di aree sicure = 318, somma a mano marcata come tale) è già sotto l'altezza intrinseca del deck a taglia predefinita. Sull'iPad non accade: lo spazio basta. Portata di un rimedio, **non realizzato**: tetto o area scorrevole per la colonna del deck, così che la griglia conservi una porzione minima; oppure scalare il contenuto della griglia. Tocca il principio 1.

**Non ho toccato** la cornice riportata dall'accessibilità né la prova di raggiungibilità.

---

# Ciò che ho fatto e l'incarico non chiedeva

- Ho accertato e registrato un SECONDO fenomeno (la porzione visibile che collassa a `0` a caratteri grandi e in orizzontale sull'iPhone), distinto dalla cella arretrata di S10 e più grave. L'incarico chiedeva la cella arretrata; questo l'ho trovato misurando ed è geometrico, quindi l'ho dichiarato invece di tacerlo.

# Ciò che l'incarico chiedeva e non ho fatto

- **Il formato `quindici` non è stato misurato.** `PartitaCorrente(nuova:)` fissa lo scenario di prova (formato `cento`), e per misurare `quindici` (4×4) avrei dovuto aggiungere un inizializzatore alla Presentazione: in una sessione che «misura e basta» ho preferito non toccare il codice di produzione. Il fenomeno è sul formato grande `cento`; `quindici` è 4×4 con 2 righe di piazzamento, molto più piccolo del contenuto misurato, e non è stato instanziato — dichiarato non verificato.
- Taglie di carattere: provate la predefinita (`.large`) e la più grande accessibile (`.accessibilityExtraExtraExtraLarge`), non le intermedie.

# Registri e rami

**S10** aggiornato in `registro-scostamenti.md` con l'accertamento, **senza chiuderlo** (nessun rimedio realizzato). Nessuna decisione architetturale nuova (nessun RDA): questa sessione misura, non decide. Il lavoro verde è sul ramo `07-misura-s10-e-chiarimenti`; portato su `principale`.
