# Resoconto — Caricamento della build 15, spostamento delle sessioni complete, e le questioni di impianto

Ramo di lavoro `06-caricamento-spostamento-tre-questioni`, aperto da `principale` a `6a998cb`. Commit, dal più vecchio: `6a998cb` (scritture residue della sessione 05, su `principale`), `b23ad8b` (incarico 06 verbatim), `3c6f199` (note della build 15), `2b8e87a` (segnaposto 02 e indice), `c5534fd` (build 15 nel registro), `2125032` (cancello sul manifest dei testi), `48cba49` (sessioni complete in corsa separata e conteggio dall'esecutore), `90043ae` (selezione per nome invece che per ambiente), più i commit di questo resoconto e dei registri.

## 0. Stato di partenza e discrepanze dichiarate prima di cominciare

Le tre precondizioni, verificate prima di toccare qualunque cosa:

- **Ramo a `d0d23a6`**: sì (`git log --oneline -1` su `principale`).
- **Albero pulito**: **NO**. `git status` riportava `forma-dei-resoconti.md` modificato e due file non tracciati (`Incarichi/05-...-richiesta.md`, `...-risposta.md`): le scritture non committate della sessione 05, che le istruzioni finali dell'incarico stesso danno per attese («la sessione precedente ha lasciato scritture non committate»). Discrepanza dichiarata; committate su `principale` in `6a998cb` per stabilire la base pulita.
- **`controlla-build.py` concorde**: sì — «registro e App Store Connect concordano: 14 build, la più alta è la 14», uscita 0.

**Ambiguità dichiarata prima di agire.** «La sola condizione è che il collaudo di ogni caricamento, nella forma stabilita più sotto, sia verde» ammette due letture: (a) caricare solo dopo aver ridotto il collaudo al sottoinsieme (subordinando il caricamento alla sezione dello spostamento) o (b) caricare col collaudo attuale, che «viene prima di tutto e da solo». Risolta a favore di (b): il collaudo completo attuale (144 sessioni) è un **soprainsieme stretto** del sottoinsieme di 24, sicché verde nel soprainsieme implica verde nel sottoinsieme; lo spostamento e il cancello di freschezza sono stati realizzati DOPO il caricamento, per non subordinarlo ad alcuna condizione sulle sessioni complete. È la lettura coerente con «non subordinare il caricamento ad alcuna altra sezione di questo incarico».

## 1. La finestra b4vb5t6e4

Non è in esecuzione in questa sessione. Verificato per FINESTRE e processi, non per elenco di nomi: nessun ciclo `until … sleep` fra i processi (`ps -Ao pid,ppid,etime,command | grep -iE 'sleep|until'`), nessun processo utente più vecchio di un'ora, nessun file di uscita atteso nello scratchpad. Le finestre di comando in background non sopravvivono al termine della sessione che le ha aperte: `b4vb5t6e4` apparteneva alla sessione precedente e qui non esiste più. Non c'era nulla da chiudere; lo si dichiara invece di riportare un'operazione non avvenuta.

## 2. Il caricamento della build 15 — eseguito e verificato per interfaccia di programmazione

Caricata la **build 15**, `MARKETING_VERSION` **1.1.0** (non toccata), versione dei valori **0.5.0** (non toccata).

**Come è stata caricata, dato il vincolo di rete.** I processi in background di questa sessione non hanno rete (accertato: `socket.gaierror` su `api.appstoreconnect.apple.com` sia con sandbox sia senza), mentre il primo piano sì ma con un tetto di dieci minuti, e il collaudo completo dura di più. Il caricamento è stato quindi spezzato lungo il confine della rete, rispecchiando `scripts/carica-testflight.sh` passo per passo: i cancelli (`controlla-note.py`, `controlla-build.py`, controllo delle versioni) e la parte SENZA rete (collaudo completo + archivio + esportazione firmata, `scratchpad/costruisci-15.sh`) in background; la parte CON rete (`altool --upload-app`, `nota-testflight.sh 15`, `controlla-build.py --appendi 15`) in primo piano. Il collaudo completo è uscito verde («Collaudo completo: tutto verde»). L'archivio e l'esportazione hanno riusato il certificato «Apple Distribution» e il profilo «match AppStore com.scabo.warsense» già installati (ExportOptions.plist, firma manuale, `MATCH_READONLY`): **nessun certificato, profilo o identificatore creato, revocato o modificato**.

**Verifica per API.** Da `scripts/asc_api.py GET`:

| verifica | valore | fonte |
|---|---|---|
| processingState | `VALID`, `expired=false` | `GET /v1/builds?filter[version]=15` |
| versione | 15 | idem |
| treno | `1.1.0`, il più alto sull'app | `GET /v1/preReleaseVersions` |
| gruppo di test | `WarLab`, interno, `hasAccessToAllBuilds=true` → assegnazione automatica | `GET /v1/betaGroups` |
| nota allegata | 2933 caratteri, coincide con `note-di-rilascio.txt` (2934, meno l'a capo finale che l'interfaccia non conserva) | `GET /v1/builds/{id}/betaBuildLocalizations` |
| registro ↔ ASC | concordi in entrambi i versi, **15 build, la più alta la 15** | `scripts/controlla-build.py` |

**La colonna del commit nel registro.** La riga registra `2b8e87a` (HEAD al momento di `--appendi`); l'archivio fu prodotto dall'albero a `3c6f199`. I due commit differiscono SOLO per la documentazione in `Incarichi/` (segnaposto 02 e indice), non per sorgente né note: il binario è identico. Dichiarato perché la colonna non sia scambiata per una registrazione dell'istante di build.

**Valutazione sulla versione dei valori, non lasciata per omissione.** Non si incrementa: resta **0.5.0**. Criterio 03 §9.2.1 — la versione sale quando cambia una regola che incide sul modo in cui una partita in corso si svolgerebbe. `git diff --stat d9a5c82..9574a25 -- Codice/Sources/Contenuti/Valori Codice/Sources/Motore` è **vuoto**: nessun file di valori né del Motore è cambiato dalla build 14. Le modifiche sono nella Presentazione (`TesseraDeck`, `CostruttoreAnnunci`, `PartitaCampagna`, `SchermataBattaglia`) e nel banco di verifica. Una partita salvata prosegue identica.

## 3. Le due note, rigenerate per la build 15

Entrambe erano più vecchie dell'ultimo commit del codice (`9574a25`) — `note-di-rilascio.txt` a `2d3c546`, `nota-per-il-titolare-mappa.md` a `26a19e3` — e `controlla-note.py` le avrebbe rifiutate. Rigenerate e committate in `3c6f199`.

- `note-di-rilascio.txt` (tester): descrive la build 15 e non la 14 — la correzione di `TesseraDeck` (la griglia non si sposta più alla selezione, S10/`e35b61a`) come cosa principale, poi il dito sulle griglie grandi, poi il punto sotto la griglia. 2933 caratteri su 4000.
- `nota-per-il-titolare-mappa.md`: dichiara le **tre cose da provare, in quest'ordine** — (1) il piazzamento di un reparto dopo aver scelto una tessera, sulle celle della fila più arretrata (la cosa rotta e corretta); (2) il tocco su una casella della mappa grande fuori dalla parte visibile (il dito non scorre da solo); (3) che cosa si sente esplorando al tatto sopra la zona dei comandi (una cella là dove non è disegnata).

`python3 scripts/controlla-note.py` passa tutti i controlli: freschezza (documento `3c6f199`, codice `9574a25`), 16 nomi citati tutti esposti, 1 misura pari a ciò che il programma stampa (`pianura_lunga,raccolti,5`: con_il_salto=15, senza_il_salto=106), nessuna cifra non dichiarata, lunghezza in regola.

## 4. Lo spostamento delle sessioni complete (RDA-83, aggiornamento S11)

Il titolare, informato del numero vero (1258,6 s per le 144 sessioni di campagna per l'interfaccia, tre volte la stima di sette minuti), le ha spostate fuori dal collaudo di ogni caricamento.

**Il collaudo di ogni caricamento tiene il sottoinsieme di 24.** `SessioniPerInterfacciaTest.test_00_3_1` gioca il sottoinsieme (tetto gruppi 2); `test_00_3_9_ogni_configurazione_completa_giocata_al_dito` gioca le 144 (tetto 12). Il collaudo esclude `test_00_3_9` con `-skip-testing`.

**Costo del collaudo dopo lo spostamento, da strumento** (corsa `blsltzwas`):

| parte | prima dell'aggiunta | con le 144 | dopo lo spostamento (24) | strumento |
|---|---|---|---|---|
| pacchetto | 30 s | 30,5 s | **29,5 s** | `swift test`, «Executed 236 tests … 29.539s» |
| simulatore | 122 s | 1363,7 s | **163,18 s** | xcresult `startTime`/`finishTime` (`1786007819.133 − 1786007655.956`) |

Il collaudo torna vicino alla misura di prima dell'aggiunta.

**Perché la selezione è per nome e non per variabile d'ambiente.** Una prima stesura leggeva `WARSENSE_SESSIONI_COMPLETE` dentro la prova per alzare il tetto a 12. Difetto RIPRODOTTO: xcodebuild non propaga l'ambiente della shell al processo di prova sul simulatore, e la corsa separata `bb3aq10j7` è durata **1 minuto invece di venti**, cioè ha giocato le 24 del sottoinsieme credendo di girarne 144. Corretto in `90043ae` con due prove distinte selezionate per nome (`-skip-testing` nel collaudo, `-only-testing` nella corsa separata); il fascio di risultati della corsa separata registra la durata della prova, che distingue 144 da 24.

## 5. Il cancello di freschezza sull'esito della corsa separata (RDA-83)

`scripts/esegui-sessioni-complete.sh` è la corsa separata: non dipende da alcuna credenziale, esegue le 144 per l'interfaccia (`test_00_3_9`) e l'insieme headless completo con le 32 di battaglia al Motore (`SessioniCompleteTest` fuori dal fumo, che pretende zero `violazioni_nelle_sessioni_di_battaglia`), e scrive `esiti-sessioni-complete/esito.json` con data, commit ed esito (non versionato).

`scripts/controlla-sessioni.py`, invocato da `carica-testflight.sh` prima del collaudo, rifiuta se l'esito manca, dichiara un fallimento, o è più vecchio dell'ultimo commit del codice. **Visto fallire di proposito su ciascuno dei tre casi e accettare sul quarto:**

| caso | esito | uscita |
|---|---|---|
| esito mancante | RIFIUTATO | «manca esiti-sessioni-complete/esito.json … Eseguire scripts/esegui-sessioni-complete.sh» |
| esito che dichiara fallimento | RIFIUTATO | «l'ultima corsa separata dichiara «fallimento» … Non si carica su una corsa fallita» |
| esito vero ma vecchio (commit `9574a25`, superato da `2125032`) | RIFIUTATO | «l'esito … è più vecchio dell'ultimo commit che ha toccato il codice … esito girato su: 9574a25 / codice a: 2125032» |
| esito fresco e di successo (commit HEAD) | ACCETTA | «corsa separata … esito «successo», girata su 2125032, codice a 2125032» |

Il terzo caso è la risposta alla domanda che l'incarico pone: rifiuterebbe un esito vero ma vecchio? Sì.

## 6. La corsa separata reale e l'intermittenza

**La corsa gira davvero le 144, verificato per durata.** La corsa `bz074xwk0` (commit `90043ae`) ha dato `test_00_3_9` VERDE con **durata prova 1234,0 s**, letta dal fascio di risultati (`xcresulttool` `finishTime − startTime`): è l'ordine dei 1258,6 s misurati sulle 144 dalla sessione 04, non i 34 s del sottoinsieme. La parte headless (144 campagna + 32 battaglia al Motore) VERDE. `esiti-sessioni-complete/esito.json` scritto con esito «successo», e `controlla-sessioni.py` lo accetta.

La corsa precedente `bb3aq10j7` NON conta come corsa completa: durò 1 minuto perché la variabile d'ambiente non arrivava al simulatore (§4). È il difetto riprodotto e poi corretto.

**Intermittenza — tre corse complete, tutte verdi, e la dichiarazione onesta.** Durata di `test_00_3_9`, da `xcresulttool`:

| corsa | esito interfaccia (144) | headless | durata prova |
|---|---|---|---|
| bz074xwk0 (n.1) | VERDE | VERDE | 1234,0 s |
| b7vxhhbee n.2 | VERDE | VERDE | 1238,0 s |
| b7vxhhbee n.3 | VERDE | VERDE | 1240,3 s |

Tre passaggi identici, durata entro l'1 %. **Tre corse NON sono una misura di intermittenza a bassa frequenza, e non le presento come sufficienti**: è l'errore che la sessione 04 aveva già dichiarato (tre esecuzioni insufficienti a una parte su venti), e ripresentarlo come sufficiente sarebbe l'errore che l'incarico vieta. Una misura vera a «una parte su venti» chiede l'ordine delle 20 esecuzioni, cioè ~7 ore a 21 minuti l'una, che la capacità di questa sessione non contiene. Ciò che riduce STRUTTURALMENTE il rischio, e che vale più di un piccolo campione, è che `SessioniPerInterfacciaTest` non contiene attese a tempo fisso: ogni passo attende una CONDIZIONE (`impronta` cambiata, avviso presentato, avviso congedato) con un tetto (250 iterazioni da 5 ms), e un tetto raggiunto FALLISCE invece di proseguire — quindi un'eventuale intermittenza si manifesterebbe come rosso, non come un verde che non verifica. Non ho osservato alcun rosso in tre corse complete più le molte corse del sottoinsieme nel collaudo.

## 7. Il manifest dei testi è confrontato (RDA-84, sezione «Il manifest dei testi»)

`Testi.carica` leggeva il campo `impronte` e non lo confrontava: unico artefatto di contenuto senza controllo. Ora calcola l'impronta SHA-256 di ogni file elencato e RIFIUTA — `errore.testi.impronta_discorde` se non coincide, `errore.testi.file_mancante` se manca. A differenza dei valori, che sulla discordanza derivano una versione locale (RDA-45), qui è un rifiuto: i testi non ammettono modifica locale silenziosa. Il rifiuto non distrugge la schermata perché `Servizi` ripiega sulla fabbrica, sempre coerente (05 §7.1) — verificato da `test_05_7_1_al_rifiuto_segue_il_ripiego_sulla_fabbrica`.

Prove in `CaricamentoTest`, modellate su quelle dei valori. **Fatta fallire di proposito** alterando `Vocabolario.strings` senza rigenerare il manifest: `test_05_7_2_testi_di_fabbrica_coincidono_con_le_impronte` fallisce con `XCTAssertNoThrow failed: threw error ErroreDati(chiave: "errore.testi.impronta_discorde", file: "it.lproj/Vocabolario.strings")`; poi ripristinato (`git checkout`). Il controllo NON è vacuo: le prove leggono manifest e file committati e non rieseguono `rigenera-impronte.py` (se lo facessero, le impronte coinciderebbero sempre). `swift test`: **236 prove, 1 saltata, 0 fallimenti** (era 232). Committato in `2125032`.

## 8. Il conteggio delle prove, dall'esecutore (sezione «Il conteggio delle prove»)

**Il secondo problema, risolto.** I conteggi delle ospitate e d'interfaccia venivano da uno scanner Python perché il collaudo girava con `-quiet`. Ora `collaudo-completo.sh` scrive un fascio di risultati (`-resultBundlePath`) e `scripts/conta-prove.sh` legge il conteggio con `xcrun xcresulttool get test-results summary/tests`. Corsa `blsltzwas`: **56 ospitate (`WarSenseTest`) + 8 interfaccia (`WarSenseUITest`) = 64**, tutte passate, esito `Passed`. Il pacchetto è già dall'esecutore (`swift test`, 236 con 1 saltata). Comando che lo stampa: `scripts/conta-prove.sh <percorso .xcresult>`, invocato dal collaudo. Committato in `48cba49`.

**Il primo problema, dichiarato non meccanizzabile e non installato.** Una sonda priva di asserzioni committata fra le prove non è distinguibile meccanicamente da una prova che asserisce in un'ausiliaria senza produrre rifiuti falsi: la sessione 04 aveva già accertato che lo scanner ingenuo segnala 14 funzioni prive di asserzioni di cui 13 legittime (asseriscono in `attendiRifiuto`, `giocaEConfronta`, `giocaTutte`, `accertaCheLaDesignazioneConservi`). Un cancello che rifiuta 13 prove legittime viene disattivato entro una settimana, e disattivarlo è peggio che non averlo mai messo. Non installato. Perché la distinzione sia meccanizzabile servirebbe seguire le chiamate alle ausiliarie fino a un'asserzione lungo ogni cammino — un'analisi del flusso di chiamate, non un'espressione regolare — e trattare come sonda solo la funzione da cui NESSUN cammino raggiunge un'asserzione. Finché quel controllo non esiste, il problema resta aperto e dichiarato.

## 9. La cella della zona arretrata (S10) — sezione a cui mi sono fermato

**Non accertata in questa sessione.** È il confine verde a cui mi fermo, per capacità: caricamento, manifest dei testi, conteggio, spostamento con cancello e le tre corse di intermittenza hanno consumato la sessione, e S10 è misura, non correzione, ed è la questione a priorità più bassa. Dichiaro invece di misurare a mano.

**Perché non ho prodotto numeri nuovi.** La misura vera chiede il simulatore (occupato dalle corse di intermittenza per gran parte della sessione) e un tool: l'incarico e `forma-dei-resoconti.md` vietano numeri calcolati a mente, quindi non sostituisco la misura con un'aritmetica geometrica inventata. Le misure che ESISTONO sono quelle già in S10, prodotte dalla sonda in processo della sessione precedente su finestra 420×912: porzione visibile della griglia di battaglia **439,7** punti (108 in meno della mappa, 547,3, occupati dalla colonna del deck); contenuto **696×584** (mappa 664×664); la cella di riga 8 colonna 1 con centro a **y=502** e cornice d'accessibilità **(44, 472, 60, 60)**; e la constatazione che sei tentativi di scorrimento non portano alcuna cella della zona arretrata interamente in vista. Queste reggono; non ne ho aggiunte.

**Che cosa servirebbe per accertarlo, in modo che la prossima sessione lo esegua diretto.** Una prova ospitata di sola misura (nessuna correzione), che con la disposizione FERMA e senza selezionare tessera apra la battaglia con `battagliaAperta()`, legga `scorrevole.contentSize` e `scorrevole.bounds` (la porzione visibile), e per ogni cella della zona di schieramento legga la cornice con `LettoreAccessibilita.cornice(di:)` (la stessa via di `RaggiungibilitaTest`), calcolando quanto della cornice resta sotto `contentOffset.y + bounds.height` anche allo scorrimento massimo. Il fenomeno va ripetuto sui formati (`cento` 10×10, `quindici`) e sulle taglie di carattere accessibili iniettando `UITraitCollection(preferredContentSizeCategory:)` nella finestra. Se allo scorrimento massimo la cornice sconfina ancora, il vincolo è geometrico — contenuto più alto della porzione visibile che la colonna del deck accorcia — e la portata di un rimedio (senza realizzarlo) è o ridurre il contenuto, o dare alla griglia una porzione visibile che non ceda alla colonna del deck; se invece allo scorrimento massimo la cornice entra, la causa è nello scorrimento sintetico di XCUITest e non nella geometria. **Non intervengo sulla cornice riportata dall'accessibilità né sulla prova di raggiungibilità**, come l'incarico vieta.

## 10. L'incarico 02 perduto, l'indice, i file mancanti (sezione «L'incarico perduto e l'indice»)

Verifica meccanizzata (comando in `git`): `grep -rhoE '([0-9]{2}-…-(incarico|resoconto)\.md)' --include='*.md' .` incrociato con l'esistenza su disco dà **un solo** file dichiarato ma assente: `02-2026-08-05-catena-e-sessioni-complete-incarico.md`. Tutti gli altri presenti.

A darlo per archiviato NON è la prosa del resoconto 02 (verificato: `grep -niE "indice|README|deposit|archivi|verbatim"` sul resoconto 02, zero righe), ma l'**indice**: la riga 02 di `Incarichi/README.md`, aggiunta dal commit del resoconto 02 (`1ae39cf`, `git log -S` sulla stringa del nome file), lo presenta come collegamento a un file mai scritto. Precisato così nel segnaposto invece della formulazione dell'incarico, che attribuiva l'affermazione al resoconto.

Aggiunto `Incarichi/02-2026-08-05-INCARICO-MANCANTE-segnaposto.md` (nome distinto per non occupare il nome canonico che il titolare reinserirà); l'indice `README.md` ora elenca 01, 02 (marcato **MANCANTE**, con collegamento al segnaposto), 03, 04, 05 (chiarimento), 06, e spiega la lacuna e il chiarimento 05. Committato in `2b8e87a`.

## 11. Ciò che ho fatto e l'incarico non chiedeva

- Committato le scritture residue della sessione 05 su `principale` (`6a998cb`) per stabilire la base pulita: l'incarico lo chiede solo in coda («committa il lavoro concluso»), ma serviva prima di cominciare.
- Aggiunto un fascio di risultati (`-resultBundlePath`) al collaudo, oltre al conteggio, perché il conteggio dall'esecutore ne ha bisogno.

## 12. Ciò che l'incarico chiedeva e non ho fatto

- **S10 — la cella della zona arretrata: non accertata.** È il confine a cui mi sono fermato (§9). Nessuna misura nuova prodotta; dichiarato che cosa servirebbe.
- **Intermittenza oltre le tre corse.** Ho fatto tre corse complete (§6), tutte verdi, e le ho dichiarate insufficienti a bassa frequenza invece di presentarle come sufficienti. Una misura a «una parte su venti» resta da fare in una sessione che regga le ~7 ore.

## 13. Registri e rami

Decisioni nuove: **RDA-83** (sessioni complete in corsa separata dietro cancello di freschezza) e **RDA-84** (manifest dei testi confrontato con rifiuto) nel registro delle decisioni architetturali. **S11** aggiornato (spostamento, battaglia al Motore, interfaccia ancora aperta). Il lavoro verde è sul ramo `06-caricamento-spostamento-tre-questioni`; portato su `principale` ciò che è completo e verde.
