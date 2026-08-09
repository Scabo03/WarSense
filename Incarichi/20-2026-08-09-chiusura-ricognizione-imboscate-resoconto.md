Resoconto — Chiusura del lavoro su ricognizione, formazioni non armate e imboscate (incarico 20)

> Il lavoro dell'incarico 19 NON si è potuto chiudere. Compilata l'interfaccia mai compilata, corrette dentro il perimetro tre prove ospitate, verificato il rapporto dei sabotaggi, sistemate le due note. Ma il collaudo completo del pacchetto NON passa: il banco della campagna NON TERMINA su tre scenari con avversario. È un problema di progettazione, non un errore da correggere alla cieca: lo dichiaro e mi fermo su quel punto, come l'incarico prescrive. Nulla è stato fuso né caricato: una build che non supera il collaudo non si spinge sul principale.

## Se l'interfaccia compilava

NO, non compilava. `xcodebuild build-for-testing` (progetto rigenerato da `xcodegen generate`) è fallito con `TEST BUILD FAILED`, un solo `error:`: `SessioniPerInterfacciaTest.swift:102: switch must be exhaustive`. Lo switch di `SessioniPerInterfacciaTest.giocaTutte` su `ComandoCampagna` non copriva i cinque comandi aggiunti dall'incarico 19 (`esplorazione`, `imboscata`, `revocaImboscata`, `sabotaggio`, `studioApprofondito`). Aggiunti al ramo `XCTFail` esistente — la condotta delle sessioni complete, di soli gruppi armati, non li produce, sicché se comparissero la traduzione in tocchi non sarebbe esercitata. Ricompilato: `TEST BUILD SUCCEEDED`, 0 error. È il difetto che l'incarico chiedeva di scoprire per primo.

## Che cosa ho corretto dentro il perimetro

Tre prove ospitate (`MappaCampagnaAccessibileTest`) fallivano al primo collaudo d'interfaccia — mai eseguito nell'incarico 19 — perché asserivano il comportamento PRIMA delle decisioni già prese, non decisioni nuove:

- `test_01_5_16_il_pannello_offre_le_azioni_disponibili_in_ordine_fisso`: il pannello di un gruppo armato libero offre ora anche l'imboscata (01 §5.11). Elenco atteso: marcia, presidio, riunione, IMBOSCATA, chiusura.
- `test_01_5_17_1_il_registro_contiene_i_compimenti_col_loro_luogo` e `test_02_6_6_attivare_una_voce_porta_il_fuoco_sul_luogo_del_fatto`: l'ARRIVO è uscito dal registro (incarico 19, seconda correzione del titolare, RDA-120), sicché queste prove restavano appese a `presidiaFinoAlCompimento` in attesa di un fatto che non arriva. Riscritte per usare la REVOCA — l'unico fatto col luogo che questa scena genera senza avversario, e che vi RESTA per volontà del titolare (RDA-104). La prima è rinominata `..._le_revoche_col_loro_luogo`; l'aiuto `presidiaFinoAlCompimento` è ora `attendiRegistroNonVuoto`.

Nessuna funzione aggiunta, nessuna decisione riaperta: le prove sono allineate alle decisioni dell'incarico 19. Con queste correzioni il collaudo d'interfaccia passa: `xcodebuild test` con `-skip-testing` sulle 144 sessioni, **73 prove, 73 passate, 0 fallite** (conteggio da `scripts/conta-prove.sh` sul fascio `xcresult`, RDA-71); cancelli 0/3 (biiezione dei simboli, 9 archetipi) e 0b/3 (impronte dei Contenuti) verdi.

## Il difetto che ferma la chiusura: il banco della campagna non termina

Il collaudo COMPLETO del pacchetto (`swift test`) NON passa. `FumoDelleSimulazioniTest.test_05_12_6_l_uscita_e_riproducibile` non termina: l'ho lasciato girare **~37 minuti di tempo di CPU al 100% su un solo core** (misura da `ps -o time` sul processo `xctest`) fermo su una sola prova, con il registro delle prove immobile. Non è lentezza: è un ciclo che non finisce.

**Dove.** Un campionamento dello stack (`sample <pid>`) inchioda il punto: `FumoDelleSimulazioniTest.swift:44` → `ProgrammaDiVerifica.sezioniDiCampagna` (`ProgrammaDiVerifica.swift:83`) → `BancoCampagna.corri` (`BancoCampagna.swift:392`, `:394`, `:404`) → `MotoreCampagna.applica` (`:735`) e `SondaInvariantiCampagna.controlla`. È il **ciclo del turno dell'avversario** dentro `BancoCampagna.corri` (`BancoCampagna.swift:384`):

```
while stato.gruppiInAttesa(di: .giocatore).isEmpty,
      !stato.gruppiInAttesa(di: .avversario).isEmpty { … applica un comando avversario … }
```

**Perché non termina.** Il ciclo ESTERNO del banco (`BancoCampagna.swift:250`) ha un freno esplicito, `passiDiSicurezza` (`:249`–`:252`), che rompe se i passi superano `giornate * (gruppi + 4) + 10`. Il ciclo INTERNO dell'avversario NON ha lo stesso freno. Quando il GIOCATORE ha messo TUTTI i suoi gruppi in agguato (`ordineImboscata`), i suoi gruppi restano conclusi giornata dopo giornata (`haConclusoLaGiornata = azioneSpesa || inMarcia || ordineImboscata`, `StatoCampagna.swift:219`), sicché `gruppiInAttesa(di: .giocatore)` resta VUOTO per sempre. L'avversario, invece, conserva gruppi liberi: applicando il suo comando, `MotoreCampagna.chiudiLaGiornataSeServe` (`:793`) chiude la giornata e ne apre una nuova azzerando `azioneSpesa` (`:803`), e i suoi gruppi tornano in attesa. Il ciclo interno, senza freno, muove l'avversario per giornate senza fine, mai restituendo il controllo al ciclo esterno (che è l'unico col freno).

Il Motore in sé è CORRETTO: `chiudiLaGiornataSeServe` ha già un freno per il caso SIMMETRICO — tutti conclusi e nessuno in marcia (soli agguati) rompe la cascata (`:808`–`:819`, col commento «uno stato di soli agguati farebbe scorrere i giorni senza fine — difetto trovato al banco»). Ma quel freno non copre il caso ASIMMETRICO — giocatore tutto in agguato, avversario ancora attivo — perché lì i gruppi non sono TUTTI conclusi (quelli avversari sono liberi), e la cascata correttamente si ferma dopo una chiusura, lasciando i gruppi avversari da muovere. È il ciclo del BANCO, non il Motore, a girare a vuoto.

**Verifica concreta.** Con una diagnostica temporanea (un contatore che, superato il limite del freno esterno, scrive lo stato su `stderr` e rompe — poi RIMOSSA, l'albero di lavoro è tornato pulito, `git diff` vuoto su `BancoCampagna.swift`) ho misurato il fenomeno su tre scenari:

- `pianura_contro_avversario`: giorno da 1 a **126** senza fermarsi; `gioc_attesa=0, avv_attesa=3, gioc_agguato=3, gioc_marcia=0` (i 3 gruppi del giocatore tutti in agguato).
- `guado_contro_avversario`: giorno da 1 a **165**; `gioc_attesa=0, avv_attesa=1, gioc_agguato=2`.
- (Lo stesso su `pianura_contro_avversario` a diversi ingressi: giorno 42, 60.)

Col freno diagnostico inserito, `test_05_12_6` passa in **1,8 s con 0 violazioni di invariante**: la logica di gioco è sana, il solo difetto è la non terminazione del ciclo del banco.

**Perché è un problema di PROGETTAZIONE e non un errore da correggere.** Non esiste una correzione meccanica che renda VERDE il collaudo. Col solo freno diagnostico inserito, DUE altre prove falliscono — `InvariantiCampagnaTest.test_incarico_6_molte_giornate_generate_senza_alcuna_violazione` e `FumoDelleSimulazioniTest.test_incarico_6_la_generazione_copre_la_parte_alta_della_distribuzione` — perché ESIGONO che il banco generi molte giornate su questi stessi scenari, cosa che lo stallo degli agguati impedisce. Gli scenari `*_contro_avversario` e le prove che chiedono «molte giornate» sono in tensione: lo scenario raggiunge uno stallo di agguati che ferma la generazione. Scioglierlo richiede una DECISIONE — freno al ciclo interno come all'esterno; interruzione del turno avversario al confine della giornata; fine della corsa quando il giocatore non ha più gruppi liberi; scenari che non arrivino allo stallo; o condotta dell'avversario che non riparta ogni giorno. Sono decisioni del titolare, non correzioni da inventare. L'incarico è esplicito: «Se un fallimento rivelasse un problema di progettazione e non un errore da correggere, dichiaralo e fermati su quel punto invece di inventare una soluzione». Mi fermo qui, sul banco.

Nota: la corsa separata delle sessioni complete (`test_00_3_9`, via `scripts/esegui-sessioni-complete.sh`) è passata: quella prova gioca sessioni pilotate da giornali fissi, non dal ciclo di condotta dell'avversario del banco, e non tocca il difetto. Il difetto è del banco (`FumoDelleSimulazioniTest`, `InvariantiCampagnaTest`), non delle sessioni.

## L'esito della verifica sui sabotaggi (da riportare, non da correggere)

Il rapporto «39 falliti su 40» NON nasconde un difetto: è taratura dei dati, e la competenza VIENE letta. La logica di `MotoreCampagna` per il sabotaggio da esploratori è `riuscito = competenza >= soglia`, con `competenza` da `gruppo.categoria.competenza` e `soglia` da `bersaglio.categoria.sogliaProtezione`. Nello scenario del banco `ricognizione_imboscate_pianura` due coppie esploratore–bersaglio co-locate: competenza **5** contro soglia **2** (5 ≥ 2, RIESCE una volta), e competenza **2** contro soglia **15** (2 < 15, FALLISCE ogni giorno). I 39 fallimenti sono lo stesso esploratore che riattacca ogni giornata un bersaglio con soglia 15, imbattibile per la sua competenza 2; il banco ordina il sabotaggio finché il bersaglio è co-locato, e un fallimento non lo disperde. Che la competenza sia letta e il confronto valga nei due sensi è provato da `RicognizioneImboscateTest.test_01_5_10_2_sabotaggio_esploratore_sotto_soglia_fallisce_e_li_fa_notare` (competenza 2 vs soglia 9, fallisce) e dal caso riuscito 5 ≥ 2. I valori sono provvisori (S19) e non li tocco: soglia 15 e competenza 2 sono stati scelti per esercitare la via del fallimento.

## Le note

- `note-di-rilascio.txt` descriveva la build 22 dell'AVVERSARIO — non l'esplorazione. RISCRITTA per la build della ricognizione: esploratori e «Esplora la zona»; i tre esiti che vanno storti; l'imboscata («Mettiti in agguato», scatto «Imboscata scattata in riga …, casella …»); le non armate e «Sabota la formazione avversaria»/«Studia a fondo la formazione avversaria»; i segni distinti per forma; l'arrivo fuori dal registro. **2873 caratteri su 4000**; freschezza e vocabolario a posto.
- `nota-per-il-titolare-ricognizione.md`: i marcatori sulla mappa (il segno dell'avversario, i marcatori di categoria) sono glifi DISEGNATI e non valori di testo, sicché citarli fra «…» faceva rifiutare il controllo del vocabolario. Descritti per ruolo senza citarne il glifo.
- `scripts/controlla-note.py` reggeva su entrambe al controllo precedente. NON l'ho ri-eseguito a fondo in questa sessione (esegue `swift run StrumentoVerifica`, che avrebbe conteso col collaudo in corso); e comunque il caricamento — che lo ri-esegue come cancello — non si fa, perché il collaudo non è verde.

## Il caricamento, la fusione, il versionamento

**Non fatti.** La build NON è stata caricata e il ramo NON è stato fuso sul principale, perché il collaudo completo non passa (il banco non termina) e «non si fonde sul principale nulla che non sia completo e verde». `principale` resta a `26d061e`, locale e remoto coincidono; il ramo `ricognizione-non-armate-imboscate` resta con i suoi 12 commit non fusi (9 dell'incarico 19, 3 dell'incarico 20: interfaccia compilata, prove ospitate + nota di rilascio, nota per il titolare). Nessun numero di build è stato consumato.

**La valutazione della versione, dichiarata.** La versione dei VALORI è 0.11.0 (`Codice/Sources/Contenuti/Valori/manifest.json`), portata lì dall'incarico 19; la versione di MARKETING è 1.1.0 (`project.yml`, unica sorgente), intatta. 0.11.0 è un incremento MINORE corretto per un blocco di funzioni nuove (ricognizione, non armate, imboscate) che non cambia i valori della battaglia; l'incompatibilità dei salvataggi di campagna la governa lo schema del giornale, non questo numero. Non l'ho toccata: la valutazione è che è corretta.

## L'ordine fra caricamento e fusione (dichiarato, benché ora non si applichi)

L'incarico dice «carica la build, poi fondi il ramo … spingi». Contraddice il cancello dello STESSO caricamento: `scripts/carica-testflight.sh` rifiuta come primo controllo se `origin/principale..HEAD` è maggiore di zero — «una build non si carica se il suo codice non è già sul remoto» (forma-dei-resoconti, «Il versionamento: si spinge sempre», punto 3). Prevale il consolidato: si fonde e si spinge prima, poi si carica. Lo dichiaro per completezza; nella pratica di oggi non si arriva né a fondere né a caricare.

## Ciò che ho fatto senza che fosse chiesto

- La diagnostica temporanea nel ciclo dell'avversario del banco (contatore + scrittura su `stderr` + rottura), per LOCALIZZARE lo scenario e misurare il fenomeno. RIMOSSA subito dopo: `git diff` è vuoto su `BancoCampagna.swift`. Ha anche mostrato, di rimbalzo, che `ConfiniTest.test_00_14_1` intercetta una stringa estranea nel codice di Verifica — cosa attesa e utile, e sparita con la rimozione.
- Nessun'altra modifica oltre il perimetro: le sole correzioni conservate sono i quattro file di prova (lo switch e le tre ospitate) e le due note.

## Ciò che era chiesto e non ho fatto, e perché

- **Collaudo completo verde, caricamento, verifica per interfaccia di programmazione (ASC), nota per il titolare come cancello, fusione, spinta, cancellazione del ramo.** Non fatti: il collaudo non è verde per il difetto di terminazione del banco, che è un problema di progettazione dichiarato sopra. Fondere o caricare violerebbe «non fondere nulla che non sia verde». La decisione su COME sciogliere lo stallo del banco spetta al titolare.

## Tempi (wall-clock)

- Compilazione dell'interfaccia (`xcodegen` + `build-for-testing`, due volte per la correzione dello switch): pochi minuti ciascuna.
- Collaudo d'interfaccia sul simulatore (iPhone Air): ~minuti, verde.
- Corsa separata delle sessioni complete (iPhone 17 Pro Max, `test_00_3_9`): ~20 minuti, verde.
- Prove del pacchetto: NON concluse. Un tentativo seriale è rimasto ~37 minuti di CPU su `test_05_12_6` senza terminare (poi interrotto). Un tentativo `--parallel` si è rivelato patologico (11 lavoratori a ~38 minuti di CPU ciascuno) e interrotto. La diagnostica bounded ha fatto passare `test_05_12_6` in 1,8 s.
- Caricamento: non eseguito.
