# Resoconto — Freschezza delle note, build 13, tocco in battaglia

Commit: `5fefd77` (freschezza e registro delle build), `e35b61a` (disposizione), `bd0e2b1`/`cd3e7a9` (sonda tolta, verifiche su dispositivo, fusione). Ramo `freschezza-e-tocco-battaglia`.

Collaudo alla chiusura, letto dall'esecutore: **232 prove del pacchetto (una saltata), 55 ospitate, 8 d'interfaccia, zero fallimenti.**

**Nessuna build caricata.** La sezione 4 non è stata eseguita, e l'incarico condiziona il caricamento alla chiusura delle sezioni 1, 2 e 4.

## 1. La freschezza dei documenti consegnati

**Forma scelta: una tabella, non una generalizzazione.** `scripts/controlla-note.py` sostituisce `controlla-nota-titolare.py` e porta `DOCUMENTI`, che elenca ciascun artefatto consegnato con l'insieme dei controlli cui è soggetto: `note-di-rilascio.txt` per esistenza, lunghezza e freschezza; `nota-per-il-titolare-*.md` per esistenza, vocabolario, misure, cifre e freschezza. Una sola realizzazione per controllo.

Applicare tutto a tutti sarebbe stato falso: il controllo del vocabolario pretende la convenzione delle virgolette basse, che la nota per i tester non usa, e sarebbe stato vacuo o costretto. Duplicare la freschezza avrebbe rimesso in piedi la condizione da cui il difetto nasce — due protezioni in due posti. La tabella non aggiunge un controllo: rende **leggibile** quale documento è protetto da che cosa, che è precisamente ciò che mancava. Registrato in RDA-81.

**Il rifiuto, provocato sul caso vero.** Installato il controllo, `python3 scripts/controlla-note.py` si è fermato subito con **uscita 1**:

```
RIFIUTATO: «note-di-rilascio.txt» è più vecchio dell'ultimo commit che ha toccato il codice.
  documento: 2d3c546
  codice:    f3c8288
```

Verificato inoltre che avrebbe impedito l'episodio della build 14: al momento di quel caricamento la nota era al commit `61a90e6` (09:47) e il codice a `6b0caf8` (13:47).

**Un errore prodotto dalla generalizzazione, e corretto.** Nel modo dell'integrazione continua si salta `misure`; tenendo `cifre` attivo, i numeri legittimi della nota per il titolare venivano rifiutati, perché `cifre` giudica ammissibili proprio i numeri che `misure` ha riconosciuto. Le dipendenze fra controlli sono ora dichiarate in `DIPENDE_DA` invece che implicite.

**Altri artefatti protetti da controlli di sola forma, o da nessuno.** Elencati e non corretti:

| artefatto | protezione oggi | che cosa manca |
|---|---|---|
| `collaudo-solo-dispositivo.md` | **nessuna** | RDA-51 lo dichiara «consegnato con la build», ma nessun controllo ne verifica esistenza né freschezza; non è in `DOCUMENTI` |
| manifest dei TESTI (`Contenuti/Testi/manifest.json`) | **nessuna** | `Testi.carica` legge il campo `impronte` e **non lo verifica mai**; il manifest dei VALORI è invece protetto, perché `CaricamentoTest.test_fabbrica_sempre_valida` pretende `modificatiLocalmente == false`. Chi modifica un `.strings` e dimentica `rigenera-impronte.py` lascia installazioni con testi stantii e nulla lo rifiuta |
| icona dell'applicazione | forma | è ancora il segnaposto blu di `memoria-infrastruttura.md`; nessun controllo distingue segnaposto da icona vera |
| `ITSAppUsesNonExemptEncryption` | forma | dichiarata una volta in `project.yml`; nessun controllo la rivaluta se entrasse della crittografia |

## 2. La build 13

**Tutte le build su App Store Connect**, lette con `GET /v1/builds?filter[app]=6797306323`. Il commit è **ricostruito** dal confronto fra istante di caricamento e cronologia — è l'ultimo commit precedente il caricamento, che è ciò da cui lo script produce l'archivio — e non è una registrazione dell'epoca. Tutte `VALID`, nessuna scaduta.

| build | caricata (UTC) | treno | commit ricostruito |
|---|---|---|---|
| 1 | 2026-08-02 20:48:12 | 1.0 | `0690b58` |
| 2 | 2026-08-03 07:14:51 | 1.0 | `d5cfb44` |
| 3 | 2026-08-03 07:19:06 | 0.2.0 | `d5cfb44` |
| 4 | 2026-08-03 09:37:58 | 0.2.0 | `ac87d1c` |
| 5 | 2026-08-03 14:02:46 | 1.1.0 | `8edf8ec` |
| 6 | 2026-08-03 14:47:53 | 1.1.0 | `e21974f` |
| 7 | 2026-08-04 11:34:52 | 1.1.0 | `3fd54b6` |
| 8 | 2026-08-04 12:22:56 | 1.1.0 | `75a133e` |
| 9 | 2026-08-04 13:02:33 | 1.1.0 | `bfd9eb3` |
| 10 | 2026-08-04 16:05:03 | 1.1.0 | `71db5e6` |
| 11 | 2026-08-04 18:30:31 | 1.1.0 | `3298e86` |
| 12 | 2026-08-04 20:23:41 | 1.1.0 | `f16e409` |
| 13 | 2026-08-05 07:50:41 | 1.1.0 | `6c2829d` |
| 14 | 2026-08-05 12:03:51 | 1.1.0 | `d9a5c82` |

**La causa della build 13 è ACCERTATA, non ipotizzata.** Il campo `whatsNew` della build 13, letto con `GET /v1/builds/7a0d.../betaBuildLocalizations`, è **identico** al contenuto di `note-di-rilascio.txt` al commit `61a90e6`: 3547 caratteri contro 3548, e la differenza è l'a capo finale che l'interfaccia non conserva. Il confronto è stato fatto byte per byte. L'unico procedimento che alleghi quella nota è `scripts/carica-testflight.sh`, che la legge dal file al momento del caricamento.

Ne segue che la build 13 fu prodotta e caricata **dallo script, durante la sessione della seconda unità della fase D**, fra il commit `6c2829d` (09:47 locali) e `349ee17` (09:53); il caricamento risulta alle 09:50:41 locali. Non è un caricamento manuale, non è un tentativo interrotto — la build è `VALID` e non scaduta — e non è opera di altro procedimento. **Quella sessione caricò e non lo scrisse in alcun documento.**

**Il controllo di corrispondenza è stato realizzato.** `build-caricate.md` porta tutte e quattordici le righe, con la colonna che dichiara riga per riga che la correlazione è ricostruita. `scripts/controlla-build.py` confronta i numeri del registro con quelli letti per interfaccia di programmazione e rifiuta in entrambi i versi; `carica-testflight.sh` lo invoca prima di ogni altra cosa e, a caricamento riuscito, appende la riga da sé — il passo umano mancato non esiste più. Gira soltanto al caricamento, perché chiede le credenziali di App Store Connect, che non esistono nell'integrazione continua né devono esistervi. Registrato in RDA-82.

**Visto rifiutare.** Tolta la riga della build 14 dal registro:

```
RIFIUTATO: su App Store Connect esistono build che build-caricate.md non registra: 14 (caricata 2026-08-05T05:03:51-07:00).
```

uscita 1.

**Documenti corretti.** `esame-critico.md` §4.1: la riga della seconda unità della fase D porta ora «build 13», con sotto la nota di quando e perché la correzione è avvenuta. I resoconti in `Incarichi/` **non** sono stati toccati: la regola della cartella è che si depositano verbatim e che a una premessa errata risponde il resoconto della sessione che l'ha accertata — cioè questo.

## 3. Il tocco sulla griglia di battaglia

**Le differenze fra le due schermate, isolate prima di ogni ipotesi** (sonda in processo, finestra 420×912):

| | mappa di campagna | griglia di battaglia |
|---|---|---|
| catena delle viste | `VistaMappa < UIScrollView < UIView < UIDropShadowView < UITransitionView < UIWindow` | identica, con `VistaGriglia` |
| riconoscitori | 1 sulla vista, 8 sullo scorrevole | identici |
| elementi / `accessibilityElements` | 100 / 100 | 100 / 100 |
| costruzione degli elementi | una volta all'apertura | identica |
| zoom, scostamento iniziale | 1,0 — (0,0) | identici |
| **porzione visibile** | **547,3 punti** | **439,7 punti** |
| contenuto | 664×664 | 696×584 |
| **disegnato sotto la porzione visibile** | `UIButton` dei comandi | `TesseraDeck` |

**Ipotesi escluse, con la sonda.** (a) Il riconoscitore: `hitTest` sul centro della cella di riga 8 restituisce `VistaGriglia` ed `elemento(sotto:)` la risolve. (b) `delaysContentTouches`: portato a falso senza effetto, modifica ritirata. (c) La cornice fuori vista per solo scorrimento: esclusa per la battaglia, dove scorrere non bastava — ed è così che si è arrivati alla causa vera.

**La causa trovata, ed è un difetto del gioco.** Selezionare una tessera del deck ne fa crescere il valore di una riga, perché vi si aggiunge il termine «selezionato» (02 §8.2). Misurato: la tessera passa da **112 a 130** punti, l'intestazione del deck da y=515,7 a **y=497,7**, e la porzione visibile della griglia perde diciotto punti. La cella di riga 8 colonna 1 ha il centro a y=502: era dentro la porzione visibile prima della selezione e fuori dopo, mentre la cornice riportata dall'accessibilità restava (44, 472, 60, 60), perché è la posizione nel CONTENUTO. **Chi toccava dove la cella era annunciata non toccava la cella, e accadeva esattamente nel passo fra il selezionare e il piazzare, sul bordo dove sta la zona di schieramento** (01 §8.2.1).

**Le prove che fallivano prima**, in `StabilitaDellaDisposizioneTest`: `test_00_1_2_selezionare_una_tessera_non_muove_la_griglia` (porzione visibile 439,7 → 421,7) e `test_02_8_2_la_tessera_non_cambia_altezza_quando_e_selezionata` (112 → 130).

**La correzione.** `TesseraDeck` riserva l'altezza del proprio stato più lungo con un'etichetta invisibile che porta il valore come sarebbe da selezionata (`valoreDiRiserva`, da `CostruttoreAnnunci.valoreElementoDeck(indice:comeSelezionato:)`). L'altezza riservata è quella che servirà e non una costante: si adatta alle taglie d'accessibilità. Il testo disegnato continua a dire quanto la voce annuncia, e `test_00_1_2_il_testo_disegnato_dice_quanto_la_voce` lo pretende.

**Il fuoco e le prove esistenti.** Le 55 prove ospitate e le 8 d'interfaccia passano tutte dopo l'intervento; nessuna dipendeva dal comportamento vecchio. `ToccoDirettoTest.test_00_11_1_…` e `MappaCampagnaAccessibileTest.test_00_11_1_…` restano verdi: il fuoco non si muove e gli elementi non sono ricreati.

**Che cosa resta aperto in S10.** Nemmeno con la disposizione ferma il tocco sintetizzato da XCUITest riesce a schierare: una cella della zona arretrata non entra **interamente** nella porzione visibile — la sua cornice sconfina sotto la colonna del deck — e sei tentativi di scorrimento non ne portano alcuna interamente in vista. Se ciò dipenda soltanto dalla geometria della griglia da cento celle su schermo piccolo, o da altro, **non è accertato**.

**La conseguenza possibile sull'esplorazione al tatto** è ora iscritta in `collaudo-solo-dispositivo.md` alla voce 18, con la portata del rimedio su `RaggiungibilitaTest`: quella prova pretende oggi una cornice non degenere per OGNI elemento del percorso, e con il rimedio gli elementi fuori vista ne avrebbero una degenere; andrebbe distinto «non agganciabile» da «fuori vista ma raggiungibile scorrendo». Non realizzato, non verificato.

## 4. Le sessioni complete nel collaudo — NON ESEGUITA

La sezione non è stata aperta. Non è stata compressa né abbozzata: non esiste.

Quel che si sa e che serve a chi riprende: le sessioni generate dal banco usano collocazioni arbitrarie dei gruppi, mentre `PartitaCampagna` sa aprire soltanto i tre scenari dichiarati in `scenari-campagna.json` (`init(nuova:taglia:)`). Farle passare per l'interfaccia richiede che `PartitaCampagna` accetti uno `ScenarioCampagna` qualunque — che non è un canale per il collaudo ma il completamento naturale dell'interfaccia esistente, con l'inizializzatore per taglia che vi delega.

Il costo della singola sessione **non è stato isolato** nemmeno in questa sessione. Il costo del collaudo completo prima e dopo gli interventi di oggi, misurato dall'esecutore: prove del pacchetto 29,9 s prima e **30,9 s** dopo; prove ospitate **22,4 s**; prove d'interfaccia **76,6 s**.

## 5. Una correzione a un numero della sessione precedente

`SondaScorrevoleTest.swift` era una sonda diagnostica creata per l'indagine sul tocco e **committata per errore** a `770fcfb`: stampa e non asserisce nulla. Era contata fra le «8 prove d'interfaccia» del resoconto precedente. Le prove d'interfaccia vere erano **sette**. È stata tolta; ora sono otto, e sono tutte prove.

## 6. Perché non ho caricato

L'incarico condiziona il caricamento alla chiusura delle sezioni 1, 2 e 4. La sezione 4 non è stata eseguita. `MARKETING_VERSION` resta `1.1.0`, la versione dei valori `0.5.0`, l'ultima build su App Store Connect è la **14**, invariata. Nessun certificato, profilo o identificatore creato, revocato o modificato.

`nota-per-il-titolare-mappa.md` e `note-di-rilascio.txt` **non** sono state rigenerate, perché non c'è build da descrivere; il controllo di freschezza le rifiuterà entrambe al prossimo caricamento finché non lo saranno, ed è il comportamento voluto.

## 7. Da dove si riprende

1. **Sezione 4**, intatta, a partire dall'inizializzatore per scenario di `PartitaCampagna`.
2. **S10**, la cella che non entra interamente in vista sulla griglia da cento celle.
3. Gli artefatti senza cancello elencati in §1, in particolare **il manifest dei testi**, che è l'unico dei due a non essere verificato da alcuna prova.
