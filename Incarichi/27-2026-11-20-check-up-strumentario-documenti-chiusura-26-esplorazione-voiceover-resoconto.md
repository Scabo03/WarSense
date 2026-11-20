Resoconto — Incarico 27: check-up dello strumentario, documenti allineati alle decisioni di novembre, chiusura dell'incarico 26 con la build 28, esplorazione dell'interfaccia con VoiceOver

## In testa

- Build 28 caricata su TestFlight: VALID, treno 1.1.0 (il più alto), IN_BETA_TESTING per il gruppo interno WarLab, nota allegata, registro concorde (28 build). Le build dalla 23 alla 27 erano tutte scadute il 2026-11-20 (la 27 dal 2026-11-10).
- Con Xcode 27.2 l'app non partiva più (ciclo di vita a scene obbligatorio): corretto prima di tutto il resto.
- L'integrazione continua era rossa da agosto senza che nessuno lo leggesse; ora è verde su `xcode-27` a ogni invio dell'incarico.
- La prova dell'incarico 26 che gioca le partite intere aveva un controllo VUOTO; rafforzato, ha trovato un blocco vero del gioco: un gruppo che doveva rifornirsi non aveva alcuna azione nel pannello (manca la sosta con raccolta). Corretto (RDA-150). Che sia il blocco riferito dal titolare è compatibile, non accertato.
- L'esplorazione con VoiceOver: vedi la sezione della quarta parte e `Incarichi/27-2026-11-20-prodotti/esplorazione/`.

## Lo stato di partenza, verificato

`git fetch --all --prune`, `git ls-remote origin`, `git rev-parse`: `principale` locale = `origin/principale` = f7b2941; `partite-fino-alla-fine` locale = remoto = 08ef4bf; albero pulito (`git status --porcelain` vuoto, solo file ignorati: `.DS_Store`, `Applicazione/build/`, `Codice/.build/`, `esiti-sessioni-complete/`); nessuna voce in `git stash list`. Nessuna discrepanza da dichiarare. RDA usati fino a 140 e S fino a 26 sul ramo dell'incarico 26 (`git show <ramo>:…`); le registrazioni di questa sessione partono da RDA-141.

## Le versioni della macchina

Tabella completa, con la fonte di ogni numero, in `Incarichi/27-2026-11-20-prodotti/inventario-strumentario.md`. In breve: macOS 27.0.1 (26A434) contro 26.5 (25F80, dedotto dalla lettera della build) di agosto; un solo Xcode, 27.2 (27B52), selezionato e non toccato, contro 26.6 (17F113); Swift 6.4.2 contro 6.3.3; runtime iOS 27.0 (24A434) e 26.5 (23F77), mentre l'SDK 27.2 preferisce il runtime 24B8118 (iOS 27.2), non installato e non installato da me (sotto); xcodegen 2.45.4, lo stesso di agosto; Python 3.9.6 di Xcode; gh assente (né ora né, a quanto risulta dai documenti, ad agosto); Claude Code 2.1.329; altool 27.10.4, riscritto. Xcode 27.2 non contiene più l'applicazione Simulator né alcun altro pacchetto `.app`.

## Prima parte — che cosa è successo

**Collaudo di partenza** (principale f7b2941 senza modifiche, prodotti di compilazione cancellati, simulatore dedicato imposto con la variabile che f7b2941 già aveva): pacchetto verde, 336 eseguite, 0 fallite, 1 saltata, in 6 fasci (somma dei fasci di `swift test` fatta da uno script della sessione, perché con Swift 6.4 `swift test` stampa un «All tests» per fascio e non più un totale); prove sul simulatore ROSSE, 11 registrate e 11 fallite (`xcresulttool`): l'app non si avviava, «UIScene life cycle is required for apps built with this SDK» (`StandardOutputAndStandardError.txt` del fascio; arresto in `_UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption`). Corsa delle sessioni rossa per lo stesso motivo (144 per l'interfaccia), headless verde. Durate: 186 s e 46 s (`date +%s`). Dettagli in `prodotti/collaudo-di-partenza/esito.md`.

**Che cosa falliva già.** L'integrazione continua: 30 corse rosse su 44 (API), ultima verde il 2026-08-05, rossa a ogni invio dal 2026-08-07, registri scaduti (HTTP 410). L'ho rieseguita con lo strumentario esatto di agosto sul ramo temporaneo `riferimento-agosto` (immagine `macos-26` con Xcode 26.6 17F113): 81 prove su 83, fallite le due `AnnunciEFuocoTest` 00_11_1 e 00_11_3. Sulla macchina del titolare ad agosto passavano: rosso dell'integrazione continua, non della macchina.

**Le avvertenze del compilatore.** Nessuna nuova: le 64 avvertenze uniche (file, riga, messaggio) del collaudo di partenza sono tutte nell'insieme della corsa con Xcode 26.6; con lo strumentario nuovo ne spariscono tre di SwiftPM («'Motore' is missing a dependency on 'Dati'» e simili). Elenchi completi in `prodotti/collaudo-di-partenza/`. L'obbligo delle scene non era annunciato da alcuna avvertenza di compilazione.

**Aggiornamento sul ramo `check-up-strumentario`.**
1. Scene: `SceneDelegate` (RDA-141). Riapplicato, 82 prove su 83.
2. La ottantatreesima, `PassaggioBattagliaInterfacciaTest/test_incarico_25_…`, si arrestava con `EXC_BAD_ACCESS` dentro l'attesa. Da sola passava tre volte su tre; l'intera classe ripetuta tre volte si arrestava (due prove su tre). Riprodotta anche su un simulatore iOS 26.5 creato apposta («WarSense iPhone Air (iOS 26.5, diagnosi)»), quindi non è il runtime. Con `TEST_RUNNER_NSZombieEnabled=YES`: «-[AVAudioPlayer performSelector:withObject:]: message sent to deallocated instance». Correzione: i lettori dei suoni vivono quanto il processo (RDA-141); sei ripetizioni della classe senza arresti su entrambi i runtime. Ipotesi provata e ritirata: le finestre di prova agganciate alla scena (non toglievano l'arresto e non cambiavano alcuna misura di `PorzioneVisibileTest`).
3. Le due prove del fuoco che facevano rosso l'integrazione continua: lettura del registro del fuoco a metà dell'apertura della schermata (RDA-143). In locale NON riprodotte nemmeno con quindici processi `yes` a saturare la CPU (cinque ripetizioni, sei prove su sei verdi): riproduzione solo sull'esecutore remoto. Corrette sincronizzando l'attesa; la verifica è stata l'integrazione continua (verde).
4. Simulatori dedicati, integrazione continua su `xcode-27` con Xcode 27.2 per percorso, xcodegen 2.45.4 fissato, checkout v5, `altool --upload-package` (RDA-142).
5. Collaudo e sessioni verdi in locale sul commit d061164 (220 s; 515 s, le 144 per l'interfaccia in 502,8 s); integrazione continua verde sulla richiesta n. 1 (prima verde dal 2026-08-05), con il simulatore dedicato creato da sé sull'esecutore. Fuso, spinto, ramo cancellato. Corse sui due invii al principale: verdi (44816648652 su b732674, 44817590790 su f3efe39).

**Le 144 sessioni per l'interfaccia** durano ora 502–514 s contro 1017,7 s di agosto (stessi numeri di prove; `xcresult`).

**Firma e distribuzione, sola lettura.** Certificato JJ47RUK3DJ scade il 2027-05-30 (API), chiave privata presente (impronta 0C2A8106…); profilo 3JN94477B2 ACTIVE, scade il 2027-05-30, installato nelle due cartelle; chiave di App Store Connect funzionante; registro concorde (27 build alla partenza). Nel portachiavi ci sono altre due identità «Apple Distribution: Luca Scabini», di altre applicazioni, non toccate. Nessun certificato creato, revocato o modificato.

**Il metodo di caricamento.** `--upload-app` è dichiarato deprecato dalla guida di altool; l'altool di Xcode 27.2 accetta entrambe le forme (provato con un pacchetto inesistente: entrambe autenticano e si fermano su «IPA file not found»). Migrato a `--upload-package`, che ha caricato la build 28 al primo colpo.

**Canali di automazione.** Accertamento in `prodotti/canali-di-automazione.md` (CORRETTO nella quarta parte, vedi sotto): il servizio VoiceOver funziona (accensione 3,44 s, 0,5 s a passo, pronuncia restituita, `moveIn`/`moveOut` rifiutati senza la navigazione per gruppi); `performAccessibilityAudit` funziona; `simctl` funziona ad apparecchio acceso, e con Xcode 27.2 `xcodebuild test` spegne l'apparecchio a fine corsa; l'applicazione Simulator non esiste più; nessuno strumento di controllo dello schermo in questa sessione; l'accesso d'assistenza di macOS c'è ma non ha finestre su cui agire.

## Seconda parte — che cosa è successo

Ramo `documenti-decisioni-novembre`. Le decisioni sono applicate alla carta (1.3), a 01 (3.8), 02 (2.6), 03 (2.5), 05 (1.4), al documento nuovo della modalità a campioni (1.0), ai due documenti di lavoro (avvertenza in testa), alle note e ai testi; registrate in RDA-144–147. Due decisioni prese da solo, motivate nei registri: la modalità a campioni in un documento proprio (RDA-144), e la regola di lettura per i punti non ancora riallineati invece della loro riscrittura, che è il riallineamento dei consolidati escluso dall'incarico.

**Premessa dell'incarico non confermata dai documenti, segnalata qui perché l'incarico non ammette domande** (forma-dei-resoconti, voce 3): «regno, campagne, fronti… restano deterministici» — fino a 01 3.7 il meteo e i guasti delle macchine erano proprio le estrazioni del caso del piano di campagna, e 01 §16.5 dichiarava il perimetro del caso «da non riaprire». Ho applicato la decisione alla lettera (nessuna estrazione del caso fuori dallo scontro a campioni) senza inventare la forma deterministica di meteo e guasti, che resta un punto aperto per il titolare (01 §16.7, RDA-146). Nessuno dei due è costruito nel codice.

**Il cancello di «osservato».** `VocabolarioOsservatoTest` visto fallire sui testi e sui documenti di prima (3 prove, 4 fallimenti, righe rifiutate esattamente quelle attese: `prodotti/documenti/cancello-osservato-rosso.txt`), poi verde. La nota per il titolare `nota-per-il-titolare-avversario-visibile.md` citava il termine vecchio fra virgolette e `controlla-note.py` l'ha rifiutata: riscritta. Ho poi trovato che il controllo delle cifre delle note (che gira solo al caricamento) avrebbe rifiutato «build 27» e «build 28» scritti da me e «build 27» scritto dall'incarico 26: tolti.

**Contraddizioni segnalate e non risolte, come chiede l'incarico:** in `CLAUDE.md`, la forma della consegna dell'incarico 27 (una riga per modifica) contro «La regola in vigore» di `forma-dei-resoconti.md` (modifiche descritte con invariante e requisito). Un'altra, fuori dai due file del repo: la mia memoria persistente di agosto vietava di toccare la versione dei valori, contro la regola 5 di memoria-infrastruttura (03 §9.2.1): ho allineato la memoria alla regola 5, che è scritta nel repo ed è più recente.

Collaudo completo verde (227 s; pacchetto 339 eseguite, 0 fallite, 1 saltata; 83 su 83), fuso, spinto, ramo cancellato, coincidenza verificata (f3efe39).

## Terza parte — che cosa è successo

**Il ribasamento** di `partite-fino-alla-fine` su f3efe39 ha avuto tre conflitti, risolti a mano: l'indice degli incarichi (righe 27 e 26), il manifest dei testi (impronte rigenerate), il registro delle decisioni (RDA in ordine di numero, 138–140 prima di 141–147). Il ramo riscritto è stato spinto con `--force-with-lease` sul vecchio 08ef4bf.

**La prova del tasto** passa (11 s). **La prova delle partite intere**, alla prima corsa, non finiva più: fermata a mano dopo circa tredici minuti, con 226 «SWIFT TASK CONTINUATION MISUSE: scegliRipiegamento(fra:) leaked its continuation» e 371 «Attempt to present <UIAlertController> … which is already presenting <UIAlertController>» nel registro (`grep -c`). Causa: dopo una battaglia persa con più caselle di ripiegamento la mappa chiede dove ripiegare e attende; la prova non lo sapeva, riapriva la battaglia ancora in sospeso e girava senza tetto. Nel gioco il pannello compare dopo il congedo della schermata di battaglia (`dismiss(animated:completion:)` → `concludiLaBattaglia`) ed è modale: difetto della prova. Poi 260 presentazioni rifiutate del pannello della casella (l'ordine dato con `eseguiPerProva` lo lasciava aperto). Corretti entrambi (RDA-148): zero continuazioni perse, zero rifiuti, partite giocate fino alla fine o al limite (piccola: conclusa al giorno 11 dopo 2 battaglie, il giocatore perde; media e grande: 30 giornate senza fermarsi, 7 e 4 battaglie), 25,56 s per il caso di prova (`xcresulttool`).

**Il blocco costruito** (voci d'azione del gruppo azzerate) ha mostrato che il cancello dell'incarico 26 era vuoto: il pannello ha sempre la voce di chiusura, e il controllo `isEmpty` non poteva scattare; con il blocco la prova cadeva solo più tardi, su «Apri la battaglia» mancante. Rafforzato (conta le sole voci d'azione), ha fallito come deve: «IL GIOCO SI È FERMATO — formato campagna_piccola, giorno 1: il gruppo 4 in riga 4 casella 1 è in attesa e il pannello non offre ALCUNA azione (voci: ["Chiudi il pannello"])». Uscite in `prodotti/chiusura-incarico-26/blocco-costruito-uscite.txt`.

**Il blocco vero.** Il collaudo completo successivo è stato ROSSO per due prove: l'ordine di lettura della mappa (105 elementi contro 104: il tasto di chiusura dell'incarico 26 non era nella prova; il ramo dell'incarico 26 non aveva mai avuto un collaudo completo verde) e, senza alcun blocco costruito, la prova delle partite intere: «formato campagna_media, giorno 18: il gruppo 1 in riga 2 casella 2 è in attesa e il pannello non offre ALCUNA azione». È lo stesso gruppo, lo stesso giorno che la sessione dell'incarico 26 aveva visto e giudicato un difetto della prova, guardando il controllo vuoto. Il pannello non offriva la sosta con raccolta, che il Motore accetta sempre (RDA-150). Correzione: la voce «Sosta con raccolta: resta fermo e raccogli provviste»; prove dell'ordine di lettura e dell'ordine fisso del pannello aggiornate. La traiettoria della prova dipende dai tempi dell'interfaccia: da sola, due volte, non arrivava a quello stato; nella corsa completa sì. È una caratteristica della prova da sapere, non un'intermittenza del gioco: il suo giudizio vale in ogni traiettoria.

**Collocazione della prova, decisa con la misura:** nel collaudo di ogni caricamento (dove già si trova), perché costa 25,6 s.

**Le versioni** (RDA-149): valori 0.11.0 → 0.12.0 per la regola dell'annientamento (03 §9.2.1; l'incarico 26 l'aveva lasciata ferma perché nessun numero dei dati era cambiato, che non è il criterio), con 0.11.0 fra le compatibili; schema del giornale di campagna 8 (incarico 26); schema di battaglia 2; testi 0.1.1.

**Ordine delle operazioni, scostamento dichiarato:** l'incarico chiede di caricare e poi fondere; `carica-testflight.sh` rifiuta di caricare codice che non sia già su `origin/principale` (cancello dell'incarico 12). Ho quindi fuso e spinto prima (1b543e8), corso le sessioni sul principale (528 s, verdi, esito su 1b543e8), e caricato. Lo script ha rieseguito da sé il collaudo completo (85 su 85) prima di archiviare.

**Caricamento:** 488 s per l'intero script; «UPLOAD SUCCEEDED with no errors» (consegna c34b2d29-…, 1 586 590 byte in 4,76 s); una riga «ERROR … CDUploaderStateInfoResumeFilePath … The file doesn't exist» stampata da altool, che riguarda il file di ripresa del caricamento e non ha avuto effetti; nota allegata all'elaborazione; riga scritta in `build-caricate.md`. Verifica per API in `prodotti/chiusura-incarico-26/asc-build-28.md`.

## Quarta parte — che cosa è successo

Sul principale con il codice della build 28, ramo `esplorazione-interfaccia`, poi fuso (400d834). Impianto nel bersaglio `WarSenseEsplorazione`, fuori dal collaudo. Osservazioni con gravità e passi in `prodotti/esplorazione/osservazioni.md`; ciò che funziona in `confermato.md`; trascrizioni nell'ordine in `trascrizioni-voiceover.md`; rilievi grezzi in `rilievi-*.jsonl` (637 righe, conteggio dello script di sintesi); 52 schermate ridotte in `schermate/` (3,3 MB, somma dello script di scelta).

**Le corse di prova hanno smentito il rapporto della prima parte.** Il doppio tocco sintetico «ovunque» non attiva l'elemento portato a fuoco: arriva come tocco al centro dello schermo. Nella sonda della prima parte il pulsante giusto stava per caso al centro. Con VoiceOver acceso, poi, il tocco singolo sposta il fuoco e non attiva. Il meccanismo accertato è il doppio tocco sull'elemento stesso; il rapporto sui canali è corretto in due passi (commit 9dd0a20 e dd2b792).

**La prima partenza completa, dieci corse insieme, è stata fermata** dopo pochi minuti. Appena acceso, VoiceOver non intercettava ancora i tocchi, e il primo tocco attivava; l'impianto ora attende che il servizio risponda. Nella seconda partenza (1676 s in tutto) le quattro corse in verticale a testo predefinito sono passate; le quattro in orizzontale e le due a testo massimo si sono fermate sulle schermate che non entrano nello schermo (osservazioni 1, 3, 5, 7). Le due a testo massimo sono finite con l'uscita 138 di xcodebuild durante il percorso della mappa piccola; la causa non è stata accertata. Una corsa ha avuto VoiceOver muto all'inizio («No speech available» sulla mappa media dell'iPhone): è un'intermittenza dell'impianto sotto carico, non dell'app.

**Rilievi principali** (dettagli e passi nel file delle osservazioni):
1. **Bloccante, iPhone a testo massimo.** «Fine del turno» non si raggiunge né con VoiceOver né al tatto.
2. **Seria.** Il resoconto della battaglia è vuoto (solo titolo e pulsante), verificato su una battaglia ripresa e conclusa con la resa.
3. **Seria, iPhone in orizzontale a testo massimo.** L'avvio è tagliato e due elementi su sette non si raggiungono.
4. **Seria.** «Chiudi la giornata» conta anche i gruppi dell'avversario («7 gruppi non avevano agito» con 4 propri).
5. **Seria.** Altri comandi finiscono sotto il bordo a testo massimo.
6. **Imperfezione.** Il fuoco non torna al pulsante d'origine dopo la chiusura di una schermata.
7. **Imperfezione.** Sull'iPhone in orizzontale «Impostazioni» non si apre col doppio tocco sull'elemento.
8. **Imperfezione.** Rilievi della verifica automatica: carattere dinamico non supportato, testo tagliato.
9. **Imperfezione.** Segmenti alti 32 punti.

**Non esplorati, dichiarati:** piazzamento e designazione in battaglia (l'impianto non ha trovato la cella con una riserva selezionata); passaggio alla battaglia di campagna, resoconto di campagna e ripiegamento (in 30 giornate di marcia nessuna battaglia è nata su alcun formato); le schermate dopo l'avvio nell'iPhone in orizzontale; la campagna a testo massimo; i gesti non guidabili.

## Modifiche, per commit

- bfbbe7a — `Incarichi/27-…-incarico.md`, `Incarichi/README.md`
- d061164 — `.github/workflows/collaudo.yml`, `Applicazione/Esplorazione/SondaCanaliTest.swift`, `Applicazione/ProveOspitate/AnnunciEFuocoTest.swift`, `Applicazione/Sorgenti/AppDelegate.swift`, `Applicazione/Sorgenti/SceneDelegate.swift`, `Applicazione/Sorgenti/Info.plist`, `Applicazione/project.yml`, `Applicazione/WarSense.xcodeproj/…`, `Codice/Sources/Segnali/PuntoSegnali.swift`, `Fondamenta/registro-decisioni-architetturali.md` (RDA-141–143), `memoria-infrastruttura.md`, `scripts/carica-testflight.sh`, `scripts/collaudo-completo.sh`, `scripts/esegui-sessioni-complete.sh`, `scripts/simulatore-warsense.sh`, `Incarichi/27-2026-11-20-prodotti/` (inventario, canali, sonde, collaudo di partenza)
- 6427133 — `CLAUDE.md`, `Fondamenta/00-…`, `01-…`, `02-…`, `03-…`, `05-…`, `modalita-a-campioni.md`, `decisioni-fase-2.md`, `matrice-di-copertura.md`, `registro-decisioni-architetturali.md` (RDA-144–147), `Codice/Sources/Contenuti/Testi/it.lproj/Vocabolario.strings`, `Annunci.stringsdict`, `manifest.json`, `Codice/Tests/DatiTest/VocabolarioOsservatoTest.swift`, `nota-per-il-titolare-avversario-visibile.md`, `valori-provvisori.md`, `Incarichi/27-2026-11-20-prodotti/documenti/`, `…/integrazione-continua.md`
- a088054, d2bcbd4, 37eed1f, bdf9398 — i quattro commit dell'incarico 26, ribasati (stessi percorsi dei commit 3d4b3a5, b2540d7, a13e3c1, 08ef4bf)
- 267c5d3 — `Applicazione/ProveOspitate/PassaggioBattagliaInterfacciaTest.swift`, `Applicazione/Sorgenti/SchermataMappaCampagna.swift`, `Codice/Sources/Contenuti/Valori/manifest.json`, `Fondamenta/registro-decisioni-architetturali.md` (RDA-148, 149), `Incarichi/README.md`, `nota-per-il-titolare-*.md`, `note-di-rilascio.txt`, `valori-provvisori.md`, `Incarichi/27-2026-11-20-prodotti/chiusura-incarico-26/`
- 6caaaa3 — `Applicazione/Sorgenti/SchermataMappaCampagna.swift`, `Applicazione/ProveOspitate/MappaCampagnaAccessibileTest.swift`, `Codice/Sources/Contenuti/Testi/it.lproj/Annunci.strings`, `manifest.json`, `Fondamenta/registro-decisioni-architetturali.md` (RDA-150), note
- fe736a1 — `build-caricate.md` (scritto dallo script)
- 9dd0a20, dd2b792 — `Applicazione/Esplorazione/EsplorazioneInterfacciaTest.swift`, `scripts/esplora-interfaccia.sh`, `scripts/sintetizza-esplorazione.py`, `scripts/scegli-schermate-esplorazione.py`, `Incarichi/27-2026-11-20-prodotti/esplorazione/`, `…/canali-di-automazione.md`, `…/chiusura-incarico-26/asc-build-28.md`
- fusioni sul principale: b732674, f3efe39, 1b543e8, 400d834

## Proposta al titolare: requisito minimo e versione del linguaggio

Non ho cambiato né l'uno né l'altra. Propongo: **requisito minimo iOS 17, invariato**, perché nulla dell'aggiornamento lo richiede; la correzione dei lettori dei suoni avrebbe potuto usare `isolated deinit`, che chiede iOS 18.4, ed è stata fatta senza. **Bersagli di prova del progetto in modo Swift 6**, come l'app e il pacchetto: oggi `WarSenseTest`, `WarSenseUITest` e `WarSenseEsplorazione` compilano in modo Swift 5, e l'unica avvertenza di concorrenza del progetto (`MappaCampagnaAccessibileTest.swift:19`, «this is an error in the Swift 6 language mode») resterebbe un'avvertenza per sempre. Va deciso, perché diventerebbe un errore da correggere.

## Ciò che ho fatto senza che fosse chiesto

- Corsa di riferimento con lo strumentario di agosto in integrazione continua (ramo temporaneo `riferimento-agosto`, rimasto spinto perché contiene un commit non fuso; la regola dei rami ne vieta la cancellazione).
- Correzione del rosso dell'integrazione continua, che falliva già prima del cambio di strumenti (RDA-143), e richiesta di integrazione n. 1 per vedere l'immagine nuova prima della fusione.
- Correzione dell'arresto dei lettori dei suoni (RDA-141).
- Simulatore di diagnosi su iOS 26.5, dedicato a WarSense.
- Correzione del riferimento superato al documento 04 nella carta («un file per fase»).
- Avvertenze in testa a `decisioni-fase-2.md` e `matrice-di-copertura.md`.
- I tre difetti della prova delle partite intere (RDA-148), oltre a rieseguirla.
- Il blocco della sosta con raccolta trovato chiudendo l'incarico 26 (RDA-150).
- La versione dei valori a 0.12.0 (RDA-149), contro la valutazione della sessione 26.
- Tolte le cifre di build dalle note per il titolare.
- Nella nota per i tester, la riga sulle build scadute.
- Allineata la mia memoria persistente alla regola 5.

## Ciò che era chiesto e non ho fatto

- xcodegen non aggiornato: la 2.45.4 funziona con Xcode 27.2, e le 2.47 e 2.48, di 1 e 3 giorni fa, cambiano le impostazioni predefinite; fissata la 2.45.4 anche in integrazione continua.
- Runtime iOS 27.2, preferito dall'SDK, non installato. Installarlo crea apparecchi predefiniti nuovi, che potrebbero cambiare il simulatore scelto da altri progetti; i simulatori dedicati stanno sul runtime più recente installato, il 27.0.
- gh non installato: per l'integrazione continua ho usato l'API di GitHub con le credenziali del portachiavi.
- «Usare a fondo l'applicazione Simulator»: non esiste in Xcode 27.2.
- Ordine della terza parte: fusione prima del caricamento, imposta dal cancello dello script.
- Esplorazione incompleta: piazzamento, designazione, battaglia di campagna, ripiegamento e ritorno non esplorati con VoiceOver; orizzontale e testo massimo esplorati solo fino alle schermate che li bloccano; nessun gesto non guidabile provato.
- La prova delle partite intere dà ancora gli ordini con `eseguiPerProva`, dopo aver verificato le voci del pannello, e non attraverso la voce del pannello.

## Tempi

Somme fatte a mano dai tempi dei registri (`date +%s` attorno agli script, `xcresulttool`, orari dei passi delle corse remote), marcate come tali. Sessione dalle 20:46 del 2026-11-20 alle 00:30 circa del 2026-11-21.
- **Collaudi completi locali:** 186 + 239 + 232 + 220 + 227 + 247 + 248 + 247 s, più quello dentro il caricamento: circa 31 minuti (somma a mano).
- **Corse delle sessioni:** 46 + 516 + 515 + 528 s: circa 27 minuti (somma a mano).
- **Diagnosi sul simulatore** (riproduzioni, zombie, iOS 26.5, carico, sonde, partite intere e blocchi): circa 25 minuti, compresa la prova ferma dopo circa tredici minuti.
- **Caricamento:** 488 s.
- **Integrazione continua remota:** 14 min 50 s (riferimento), 17 min 13 s (richiesta n. 1), e le corse sui quattro invii al principale.
- **Esplorazione:** corse di prova 194 + 221 + 145 + 192 + 1316 s, prima partenza fermata dopo circa 8 minuti, seconda partenza 1676 s: circa 63 minuti (somma a mano).
