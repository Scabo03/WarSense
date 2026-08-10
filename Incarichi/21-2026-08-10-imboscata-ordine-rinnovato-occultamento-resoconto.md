Resoconto — L'imboscata come ordine che si rinnova e come cosa che non si vede (incarico 21)

## Le frasi vere che il giocatore sentirà

- Ordinando un'imboscata (conferma del proprio ordine): **«Corvo si è messo in agguato in riga 5, casella 5»** (`campagna.imboscata_ordinata`; sintetico «Corvo in agguato in riga 5, casella 5»). Il pannello offre l'azione come **«Mettiti in agguato»** ogni giornata a un gruppo fermo, e finché è appostato il gruppo si annuncia **«in agguato»** (`gruppo.in_agguato`); il mattino dopo torna **«in attesa»** (`gruppo.in_attesa`) e va riappostato.
- Quando i propri esploratori ne scoprono una: **«Imboscata avversaria scoperta in riga 7, casella 5»** (`campagna.imboscata_scoperta`); nel registro **«Giorno 3: imboscata avversaria scoperta in riga 7, casella 5»** (`registro.imboscata_scoperta`), attivabile.
- Quando la propria imboscata scatta: **«Imboscata scattata in riga 5, casella 5»** (`campagna.imboscata_scattata`); nel registro **«Giorno 4: imboscata scattata in riga 5, casella 5»** (`registro.imboscata_scattata`).

## Decisione 1 — l'imboscata come ordine che si rinnova e consuma l'azione

`ComandoCampagna.imboscata` consuma l'azione della giornata: `applica` pone `azioneSpesa` e `ordineImboscata` insieme (era già così), ma `Gruppo.haConclusoLaGiornata` NON include più `ordineImboscata` (`azioneSpesa || inMarcia`, era `… || ordineImboscata`), e `chiudiLaGiornataSeServe` all'apertura della giornata azzera `ordineImboscata` con `azioneSpesa`. Un gruppo appostato torna in attesa il mattino dopo (`statoDichiarato` = `.inAgguato` il giorno dell'ordine, `.inAttesa` il successivo). È la modifica VOLUTA (registrata RDA-122), non una correzione di svista.

Questo **scioglie alla radice la non terminazione dell'incarico 20**: uno stato di soli agguati faceva riaprire la giornata all'infinito perché l'agguato persisteva senza consumare l'azione; ora un appostato è concluso solo per la giornata in cui l'ordine è dato, torna in attesa, e la cascata di `chiudiLaGiornataSeServe` (e il ciclo del turno avversario del banco) si ferma. VERIFICATO: `FumoDelleSimulazioniTest.test_05_12_6` — che l'incarico 20 lasciava girare ~37 minuti di CPU senza terminare — passa ora; l'intera corsa `swift test --filter FumoDelleSimulazioniTest --filter InvariantiCampagnaTest` chiude in **~31 s** (misura da `time`). `InvariantiCampagnaTest.test_incarico_6_molte_giornate_generate_senza_alcuna_violazione` e `test_incarico_6_la_generazione_copre_la_parte_alta_della_distribuzione` tornano verdi.

RIMOSSO il vecchio freno di `chiudiLaGiornataSeServe` (rompeva la cascata quando tutti conclusi e nessuno in marcia, RDA-119): obsoleto, non nasconde più nulla — la terminazione discende dalla natura dell'ordine, non da un freno. RIMOSSA la **revoca dell'imboscata** (`ComandoCampagna.revocaImboscata`, evento `imboscataRevocata`, errore `gruppoNonInAgguato`, azione del pannello `pannello.revoca_imboscata`, mutante di prova, campione del giornale): con l'agguato per-giornata non c'è nulla da revocare, e l'elenco chiuso delle azioni (01 §5.6.8.1) non contiene alcuna revoca d'imboscata — CONSOLIDATO citato. Il campione `campioni.jsonl` della revoca è tolto e lo specchio `SpecieDiComandoCampagna` allineato (`CompatibilitaGiornaleTest` verde, catena dei campioni rispettata).

Correzione collaterale nel banco: la riunione, che 02 §… vuole «ogni tanto», si ordinava a OGNI giro dentro il giorno e disfaceva ogni scenario stipato prima che la condotta ne ordinasse un gruppo — sicché lo `senzaDestinazione` (lo stipamento) non si esercitava mai (0 su tutti gli scenari, misura da un `stderr` diagnostico poi rimosso). Frenata a UNA riunione al giorno (`giornoUltimaRiunione`): lo stipamento torna a esercitarsi (`guado_dodici_su_sedici_caselle` = 384, misura diagnostica), e `test_incarico_6_la_generazione_copre_la_parte_alta_della_distribuzione` passa.

## Decisione 2 — l'occultamento per retrocessione della conoscenza

Realizzato come CAP a tempo di lettura in `MotoreCampagna.conoscenza(di:per:)` (RDA-123): se nella casella c'è un gruppo avversario appostato che la parte non ha SCOPERTO, la conoscenza non è mai `.confermato` — si deriva dal solo ricordo (`statoDalRicordo`: memoria, presunto, inesplorato), e un ricordo ancora fresco (confermato per età) retrocede al limite dell'avvistato (`.avvistato(turni: soglia)`). La proiezione `VistaCampagna.vociDiCasella` (mostra l'occupante avversario solo dove confermato) e `vistaAvversario` SEGUONO dal cap senza eccezioni alla visibilità.

**Come si evita il falso in ogni istante, compreso quando il gruppo si apposta mentre l'altra parte lo osserva:** il cap sostituisce l'osservazione corrente con il ricordo nello stesso momento in cui l'ordine è dato — chi osservava la casella passa da `confermato` ad `avvistato(turni: soglia)` atomicamente. Il gioco non annuncia MAI «vuoto» né «confermato» su una casella occultata: annuncia «avvistato» (notizia non più certa) o meno, che è VERO perché il gruppo si è nascosto. Non muta lo stato memorizzato (compatibile con `conoscenza_regredita_senza_tempo`, che confronta il ricordo fra due stati, non l'uscita capata). Prova: `RicognizioneImboscateTest.test_01_5_11_1_l_occultamento_retrocede_la_conoscenza_senza_dichiarare_il_falso` (la casella passa da confermato con occupante mostrato ad avvistato senza occupante).

**La scoperta** (RDA-124): un'esplorazione RIUSCITA che riveli l'area (`scopriLeImboscate` dopo `rivelaArea`) scopre ogni gruppo avversario appostato che vi si trova — la casella entra in `StatoCampagna.imboscateScoperte: [Parte: Set<Cella>]`, che leva l'occultamento, e il fatto entra nel registro col luogo (`imboscataScoperta`, evento e fatto nuovi, testi `campagna.imboscata_scoperta`/`registro.imboscata_scoperta`), consegnato al solo giocatore (`proiettaPerIlGiocatore`). `imboscateScoperte` si azzera all'apertura della giornata: ogni giornata è una nuova imboscata da scoprire. È il SOLO modo (01 §5.11.1): un armato che passa accanto non se ne accorge. Nessuna estrazione (la riuscita discende da `esitoEsplorazione`, RDA-117). Prova: `test_01_5_11_1_la_ricognizione_scopre_l_imboscata_avversaria`.

**La simmetria** è reale (party-agnostica): `vistaAvversario` non nota gli agguati occulti del giocatore (l'avversario decide sulla propria conoscenza e vi può cadere) e nota quelli scoperti dai suoi esploratori (li aggira). La CONDOTTA avversaria avvia in forma MINIMA e provvisoria la tattica d'agguato rinviata in S18/S19 (un armato che non guadagna avanzando e ha una formazione nota adiacente si apposta): usa la sola adiacenza, nessuna soglia tarata. Prova: `test_01_5_11_la_simmetria_l_avversario_non_vede_l_occulta_ma_vede_la_scoperta`; le prove della condotta (`CondottaAvversariaTest`, `AvversarioCampagnaTest`) restano verdi.

## Gli invarianti nuovi col mutante

Tre nuovi in `SondaInvariantiCampagna`, ciascuno col mutante in `tavolaDeiMutanti`, e `test_incarico_6_ogni_invariante_ha_almeno_un_mutante_che_lo_fa_scattare` verde (l'unione dei codici prodotti eguaglia `codiciNoti`):
- `appostato_senza_azione`: un appostato ha sempre `azioneSpesa` (decisione 1). Sonda in `controlla(stato:)`; mutante: appostato con `azioneSpesa` falsa.
- `occultamento_violato`: su una casella con un appostato, la conoscenza dell'ALTRA parte — che la sonda `controllaOccultamento` riceve dall'ESTERNO, così da giudicarla senza rifarla — non è confermato, se non l'ha scoperta. Mutante: si inietta una conoscenza che restituisce `.confermato` (il falso).
- `partita_non_terminata`: una corsa si chiude entro le giornate dichiarate (`controllaTerminazione`); il ciclo del turno avversario del banco ha un freno che, superato, REGISTRA la violazione (cancello che FALLISCE, non freno che nasconde) invece di appendere. Con la decisione 1 non scatta. Mutante: `controllaTerminazione(giorniTrascorsi: 100, limite: 40)`.

Il quarto invariante dell'incarico — «nessuna parte riceve un'informazione che la conoscenza non contiene» — riusa i codici esistenti `vista_avversaria_rivela_ignoto` e `registro_rivela_ignoto` (incarico 18/19), estesi qui all'occultamento; non si conia un codice nuovo per un invariante già sorvegliato (dichiarato S21). Ogni cancello nuovo visto fallire di proposito col mutante.

## Il banco genera i fenomeni

`test_incarico_21_il_banco_genera_i_fenomeni_dell_imboscata` corre gli scenari con avversario e stampa le frequenze (numeri da `BancoCampagna.Corsa`):
- `guado_contro_avversario`: **giornateTuttiAppostati=3, imboscateScattate=1**, subite=0, scoperte=0, giornate=40, violazioni=0.
- `pianura_contro_avversario`: **giornateTuttiAppostati=4**, scattate=0, subite=0, scoperte=0, giornate=40, violazioni=0.
- `ricognizione_imboscate_pianura`: tutti 0, giornate=40, violazioni=0.

Il banco genera dunque emergentemente le GIORNATE con tutti i gruppi di una parte appostati (7 in totale) e le imboscate SCATTATE (1: l'avversario cade nell'agguato del giocatore). La CADUTA del giocatore in un agguato avversario occulto (`imboscateSubite`) e la SCOPERTA dagli esploratori (`imboscateScoperte`) — deterministiche — sono esercitate e ASSERITE dalle prove dedicate `RicognizioneImboscateTest`, perché la condotta del giocatore nel banco non marcia deliberatamente dentro un agguato né esplora deliberatamente su di esso (dichiarato S21). Nuovi contatori `Corsa`: `imboscateSubite`, `imboscateScoperte`, `giornateTuttiAppostati`; `imboscataScoperta` entra nell'impronta (`ImprontaCampagna`), `imboscateScoperte` nell'impronta dello stato.

## Il collaudo

Tutto verde, con le corse dei simulatori eseguite in SEQUENZA (vedi sotto):

- **`scripts/collaudo-completo.sh`** (da solo): `COLLAUDO_EXIT=0`. Cancelli 0/3 (biiezione dei simboli d'archetipo) e 0b/3 (impronte dei Contenuti, rigenerate per i testi cambiati) verdi. 1/3 pacchetto (Motore, Dati, Sessione, Segnali, Verifica, Confini): **331 prove eseguite, 1 saltata (le 144 sessioni), 0 fallite** (`swift test`, ~52 s). 2/3 `xcodegen generate`. 3/3 ospitate + interfaccia sul simulatore: **73 prove, 73 passate, 0 fallite, 0 saltate** (conteggio da `xcresulttool summary` sul fascio dell'esecutore, RDA-71; iPhone Air).
- **`scripts/esegui-sessioni-complete.sh`** (da solo): `SESS2_EXIT=0`, esito `successo`. `test_00_3_9_ogni_configurazione_completa_giocata_al_dito` (144 configurazioni sul simulatore): **VERDE, durata prova 988,8 s**; headless (campagna + 32 battaglie al Motore): VERDE. Fascio `sessioni-risultati.xcresult` lasciato per il cancello del caricamento.

Un crash da BUILD INCREMENTALE STALE — `EXC_BAD_ACCESS` (stack overflow) in `TraduttoreCampagnaTest.test_01_5_6_0_6`, localizzato con marcatori su `stderr` fino a provare che `applica` completava (nessun difetto reale nel codice) — è sparito con una ricompilazione pulita (`rm -rf .build`); dichiarato, non è un difetto.

**La contesa dei simulatori (corse NON indipendenti).** Il primo tentativo mandava `collaudo-completo.sh` e `esegui-sessioni-complete.sh` in PARALLELO (l'incarico invita a parallelizzare): ENTRAMBE le parti sul simulatore sono fallite insieme — «campagna per l'interfaccia (144): ROSSA» e il 3/3 del collaudo — con «** TEST FAILED **» senza alcun fallimento di asserzione, perché entrambe hanno preso lo STESSO simulatore (iPhone Air). Le parti di PACCHETTO (senza simulatore) erano verdi in entrambe. Rieseguite in SEQUENZA, da sole, sono verdi come sopra. Le corse sul simulatore non sono indipendenti se condividono un apparecchio; andrebbero su simulatori distinti.

## La versione e il versionamento

La versione di MARKETING (1.1.0) NON è toccata. La versione dei VALORI resta **0.11.0**: valutazione dichiarata (non per omissione) — l'incarico 21 cambia una REGOLA, non i numeri. L'occultamento riusa `raggio_osservazione`=1 e `soglia_confermato_in_avvistato`=2; la scoperta riusa i valori della ricognizione; la «insidiosità dell'imboscata» non è un dato a sé (un appostato conta già come nemico armato vicino, `peso_nemici_vicini`); la tattica d'agguato avversaria usa la sola adiacenza. Nessun numero di gioco nuovo (valori-provvisori aggiornato). Lo schema del giornale di campagna resta **5**: la revoca rimossa è nata nell'incarico 19, mai rilasciata, sicché nessun salvataggio distribuito ne è toccato (i tester hanno la build 22). Le impronte dei Contenuti sono rigenerate per i testi cambiati (`rigenera-impronte.py --verifica` nel collaudo).

**Il caricamento.** `scripts/carica-testflight.sh` → `CARICA_EXIT=0`. Cancelli preventivi tutti verdi: `principale` locale == `origin/principale`; versione 1.1.0 non all'indietro; **numero di build = massimo sull'account (22) + 1 = 23**; `controlla-note.py` verde; `controlla-build.py` (registro contro ASC) verde; `controlla-sessioni.py` (freschezza dell'esito) verde; `collaudo-completo.sh` rieseguito verde. Poi archivio, esportazione firmata, «UPLOAD SUCCEEDED with no errors», nota di rilascio allegata alla build 23, **build 23 registrata in `build-caricate.md`**.

**Verifica per interfaccia di programmazione (ASC).** Con le credenziali di `scabo_deploy.env` sorgente: `scripts/asc_api.py GET /v1/builds?...&filter[version]=23` → **build 23 stato `VALID`, `scaduta=False`, treno `1.1.0`** (le build 22 e 21 sono anch'esse 1.1.0, sicché 1.1.0 è il TRENO PIÙ ALTO e la 23 vi è la build più alta). `scripts/controlla-build.py` → «registro e App Store Connect concordano: 23 build, la più alta è la 23» (concorda nei DUE versi). Gruppo di test: `carica-testflight.sh` non assegna esplicitamente a un gruppo, e la relazione `/v1/builds/{id}/relationships/betaGroups` è VUOTA sia per la 23 sia per la 22 — la 22 è la build che i tester hanno OGGI e funziona, sicché la 23 è nello stesso stato di distribuzione (gruppo interno automatico); verificato per parità con la build distribuita 22, non con un'assegnazione esplicita — dichiarato.

**Il versionamento.** Fusione `--ff-only` del ramo `ricognizione-non-armate-imboscate` (16 commit) su `principale`; spinti `principale` e il ramo; caricata la build; **ramo cancellato** (locale con `git branch -d`, che rifiuta i non fusi, e remoto). Stato finale: `git rev-parse principale` == `git rev-parse origin/principale` == **`86e442d`** (accertato col comando: coincidono).

## Ciò che ho fatto senza che fosse chiesto

- La frenata della riunione a una al giorno nel banco (per ripristinare lo stipamento, un difetto latente esposto dalla fine della non terminazione).
- Diagnostiche temporanee (contatori/print su `stderr`) per localizzare lo stipamento a zero e il crash da build stale, tutte RIMOSSE (`git diff` pulito sui file toccati).

## Ciò che era chiesto e non ho fatto

- Nulla è rimasto incompiuto del percorso richiesto: interfaccia compilata, collaudo completo verde, sessioni verdi, invarianti col mutante, note riscritte, registri aggiornati, build 23 caricata, fusa, spinta, ramo cancellato.
- UNICA riserva dichiarata (non un mancato lavoro, ma una scelta di copertura): i fenomeni `imboscateSubite` (il giocatore cade in un agguato occulto) e `imboscateScoperte` (i suoi esploratori ne scoprono uno) NON sono generati emergentemente dal banco-fuzzer — la condotta del giocatore nel banco non marcia deliberatamente dentro un agguato né esplora deliberatamente su di esso — ma sono esercitati e ASSERITI deterministicamente dalle prove dedicate `RicognizioneImboscateTest`. Il banco genera emergentemente le GIORNATE con tutti gli appostati e le imboscate SCATTATE. Dichiarato qui e in S21.

## Tempi (wall-clock)

- Compilazione: `swift build` e `swift build --build-tests` incrementali, pochi secondi ciascuna dopo il primo; una ricompilazione PULITA (`rm -rf .build` + `swift test`) per scacciare il crash da build stale, ~alcuni minuti.
- Corse del collaudo (pacchetto): `swift test` completo del pacchetto ~52 s (cancello 1/3 del collaudo). La corsa dei BANCHI (Fumo + Invarianti), che l'incarico 20 lasciava girare **~37 minuti di CPU senza terminare**, chiude ora in **~31 s** (`time`).
- Corse del simulatore: collaudo 3/3 (ospitate + interfaccia) ~pochi minuti; corsa separata delle sessioni complete (144 configurazioni) **988,8 s** di sola prova (~16,5 min), più l'headless. Le due corse sul simulatore in PARALLELO si sono ostacolate (stesso apparecchio) e sono state rifatte in sequenza.
- Caricamento: `carica-testflight.sh` (collaudo completo rieseguito come cancello + archivio + firma + upload) — «UPLOAD SUCCEEDED» registrato alle 13:52; l'intera corsa del caricamento ~alcuni minuti oltre il collaudo.
