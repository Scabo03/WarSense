Resoconto — La campagna si blocca dopo la battaglia, e il ripiegamento dello sconfitto (incarico 25)

## In testa 1: la causa vera del blocco, in forma diretta

Al ritorno dalla battaglia (build 26) `MotoreCampagna.applicaEsitoInCampagna` riportava i superstiti in campagna con **`azioneSpesa = false`**, cioè NON-AGITI. Ma un gruppo che ha combattuto ha speso la giornata combattendo (01 §5.6.0.5: «ogni azione consuma l'intera giornata del gruppo che la compie»). Tornare non-agito lo metteva in uno stato che 01 §5.6.0.6 dichiara impossibile — «un gruppo che non ha agito è sempre un gruppo che attende una decisione», cioè ordinabile. La giornata, che si chiude automaticamente solo quando TUTTI i gruppi hanno agito (01 §5.6.0.6), restava aperta in attesa del combattente; il giocatore avrebbe dovuto dargli un ordine di troppo, e nel flusso reale non poteva: campagna bloccata, partita perduta. **La correzione, per costruzione:** il gruppo che ha combattuto SPENDE la giornata (`azioneSpesa = true`, per entrambe le parti), la giornata si chiude di conseguenza, e nessun ordine al reduce serve.

## In testa 2: le frasi che il giocatore sentirà

Dai testi in `Codice/Sources/Contenuti/Testi/it.lproj`.

- **Tornando dalla battaglia:** l'annuncio dell'esito «**Battaglia vinta in riga R, casella C**» o «**Battaglia persa in riga R, casella C**» (`campagna.battaglia_vinta`/`_persa`); e il gruppo reduce, incontrandolo, dichiara ora «**ha agito**» (`gruppo.ha_agito`), non «in attesa» — ha speso la giornata combattendo, e l'informazione di stato lo conta fra i gruppi che hanno agito.
- **Scegliendo dove ripiegare** (quando il proprio gruppo è lo sconfitto sopravvissuto): il pannello «**Scegli dove ripiegare**» (`ripiegamento.titolo`), con una voce per ciascuna casella disponibile — «**In riga R, casella C**» (`ripiegamento.casella`) —, e si sceglie attivandone una. Nessuna tabella, nessun trascinamento, nessun congedo: lo sconfitto DEVE ripiegare, sceglie soltanto dove.

---

## Che cosa è stato costruito, coi nomi reali

### La causa vera e la correzione (RDA-135)

`MotoreCampagna.applicaEsitoInCampagna`: i superstiti tornano con **`azioneSpesa = true`** (era `false`) — «il gruppo che ha combattuto spende la giornata combattendo», per entrambe le parti; e la funzione chiama ora `chiudiLaGiornataSeServe(&stato)` subito dopo il ripiegamento, sicché se i combattenti erano gli ultimi in attesa la giornata avanza subito, senza un ordine di troppo. È la correzione PER COSTRUZIONE che l'incarico esige: lo stato di blocco non è evitato per disciplina, non si produce.

### Il ripiegamento dello sconfitto (RDA-136)

Lo sconfitto non annientato ripiega di una casella all'indietro (01 §10.6), e il GIOCATORE sceglie dove. `PonteCampagnaBattaglia.caselleDiRipiegamento` usa `MotoreCampagna.caselleAlleSpalle` — la STESSA definizione di direzione retrostante del taglio del rifornimento (01 §5.2.2.2, «dalla parte del proprio quartier generale») — ristretta alle caselle strettamente più vicine al quartier generale (un passo all'indietro, mai un avanzamento) e libere da un proprio gruppo. Sostituisce l'euristica «vicino più vicino al QG» dell'incarico 24 (`casellaArretrata`), che era una SECONDA nozione di direzione (S25c). La scelta, in forma praticabile ascoltando (02 §8): `SchermataMappaCampagna.scegliRipiegamento` presenta le caselle disponibili, una voce ciascuna, e si sceglie attivandone una (`withCheckedContinuation`); la scelta entra nell'`EsitoInCampagna` (nuovo `conPosizioneGiocatore`) che il giornale registra, deterministica alla rigiocatura. La condotta e il default prendono la prima casella. Il flusso: `SchermataMappaCampagna.concludiLaBattaglia` deriva l'esito (`PartitaCampagna.esitoDiRitorno`), offre la scelta se il gruppo del giocatore ripiega (`partita.caselleDiRipiegamento`), e piega il risultato (`partita.concludiBattaglia(_:esito:)`).

**Il vincitore resta** (01 §15.5). L'eccezione — il vincitore che ripiega avendo chiamato ritirata dopo l'avversario (01 §15.2.2) — è IRRAGGIUNGIBILE: `MotoreBattaglia.valida` (riga 325) respinge una seconda `dichiaraResa` (`resaNonDisponibile`), una sola parte chiama ritirata ed è sempre lo sconfitto (S25b). **Caso limite (S25a):** nessuna casella disponibile verso il quartier generale (bordo o spalle occupate) → lo sconfitto RESTA nella casella contesa (compresenza col vincitore, parte opposta, ammessa 01 §6.1; non si crea una casella dove non c'è, non si sovrappongono due gruppi di una parte).

### L'invariante della giocabilità (RDA-137)

`SondaInvariantiCampagna.controllaGiocabilita(stato:ordinabile:)`: quando la campagna NON ha una battaglia in sospeso, ogni gruppo non-agito e non-in-marcia deve essere ORDINABILE (almeno un comando valido), o `gruppo_bloccato_senza_azioni`. Una battaglia in sospeso è esclusa (blocco legittimo, sciolto aprendo la battaglia dalla casella, 01 §6.2). Codice in `codiciNoti`; mutante in `tavolaDeiMutanti` (stato senza battaglia in sospeso con `ordinabile` sempre falso). Il banco lo controlla dopo ogni comando e subito dopo il ritorno dalla battaglia (`giocaBattaglieInSospeso`). Nota: poiché la sosta con raccolta è sempre valida per un gruppo non-agito, un ben formato stato sbloccato non ha mai un gruppo bloccato — l'invariante è la RETE che coglie una regressione (una battaglia in sospeso persistente); il difetto del combattente non-agito lo coglie la prova d'interfaccia.

## Il modo di provare, corretto (S25d)

La prova d'interfaccia dell'incarico 24 si fermava al ritorno. `PassaggioBattagliaInterfacciaTest.test_incarico_25_la_campagna_prosegue_due_giornate_oltre_il_ritorno` PROSEGUE: apre la partita come il giocatore (`PartitaCampagna(nuova:taglia:)`), porta due gruppi a contatto, combatte la battaglia ATTRAVERSO LA CATENA VERA dello schermo — il comando «Apri la battaglia» della casella, la `SchermataBattaglia` presentata, il resoconto e il suo congedo (`SchermataResoconto.chiudiTuttoPerProva`, la stessa catena `alTermine` del gioco) —, torna in campagna, e da lì PROSEGUE due giornate intere ordinando i gruppi ATTRAVERSO IL PANNELLO della casella (non l'esecuzione diretta) e vedendo le giornate chiudersi. Sorveglia lungo il cammino che nessun gruppo in attesa sia privo d'azione.

**Vista fallire di proposito sul codice della build 26** (`xcodebuild test`, prima della correzione): `test_incarico_25_…` rosso — «il gruppo gruppo-5 reduce dalla battaglia deve aver SPESO la giornata combattendo (01 §5.6.0.5)» (il superstite ha `azioneSpesa=false`); «** TEST FAILED **». Verde dopo la correzione. Il mutante `gruppo_bloccato_senza_azioni` visto scattare dalla guardia `test_incarico_6_ogni_invariante_ha_almeno_un_mutante`.

## Il banco prosegue dopo le battaglie

Nuovo scenario di verifica `pianura_vince_e_prosegue` (`campagne.json`, cartella `Scenari/Campagne`), in cui il giocatore VINCE (forza superiore) e la campagna prosegue. `test_incarico_25_il_banco_prosegue_dopo_le_battaglie` riporta, per gli scenari con battaglie, `Corsa.giornateDopoLaPrimaBattaglia` (nuova misura): dallo strumento (`PROSEGUE-25`), `guado_contro_avversario` battaglie=2 (perse, il giocatore annientato) giornateDopoLaPrimaBattaglia=4; `pianura_vince_e_prosegue` battaglie=1 VINTA giornateDopoLaPrimaBattaglia=33 su 40; **MEDIA = 18, massimo = 33**, zero violazioni di giocabilità. Il banco genera ora partite che PROSEGUONO molte giornate dopo le battaglie — il caso del blocco — e non solo che si fermano allo scontro.

## Ciò che era chiesto e non ho fatto (dichiarato)

- Il blocco PERMANENTE esatto della build 26 NON è stato riprodotto in una prova automatica (RDA-135, S25d): le battaglie naturali di `campagna_piccola` annientano il gruppo del giocatore (nessun combattente superstite del giocatore); uno scenario costruito in cui il giocatore vince produce, col tattico d'interfaccia attuale, una battaglia da imboscata che non conclude (l'avversario trattenuto non schiera). La prova coglie la CAUSA alla radice (il combattente non-agito) e il proseguimento oltre il ritorno, non lo stato terminale del blocco. Che una battaglia con forte squilibrio non concluda col tattico è un difetto adiacente NON toccato in questa sessione, dichiarato.
- L'eccezione del vincitore che ripiega (01 §15.2.2) non è realizzata perché irraggiungibile col motore attuale (S25b).

## Non verificato, dichiarato

- L'effetto reale su chi ascolta con VoiceOver su DISPOSITIVO (la pronuncia, il fuoco): provato solo sul simulatore.
- Le composizioni dello scenario `pianura_vince_e_prosegue` sono PROVVISORIE, scelte perché il giocatore vinca e la corsa prosegua, non un equilibrio.

## Il collaudo, coi numeri e lo strumento

- **Prove del pacchetto** (`swift test`, cartella `Codice`): **336 prove eseguite, 1 saltata, 0 fallite** (di cui `InvariantiCampagnaTest` con l'invariante `gruppo_bloccato_senza_azioni`, il suo mutante e la prova `test_incarico_25_il_banco_prosegue_dopo_le_battaglie`). Numero dal blocco «Executed 336 tests, with 1 test skipped and 0 failures» di `swift test` (era 335 all'incarico 24; la nuova è la prova del banco che prosegue).
- **`scripts/collaudo-completo.sh`** (iPhone Air, `WARSENSE_SIMULATORE`): «Collaudo completo: tutto verde». Conteggio da `xcresulttool summary`: **83 prove eseguite — 73 `WarSenseTest`, 10 `WarSenseUITest` — 83 passate, 0 fallite, 0 saltate** (erano 82 all'incarico 24; la nuova è `test_incarico_25_la_campagna_prosegue_due_giornate_oltre_il_ritorno`).
- **Vista fallire di proposito** (sul codice della build 26, prima della correzione): `xcodebuild test … test_incarico_25_…` → «il gruppo gruppo-5 reduce dalla battaglia deve aver SPESO la giornata combattendo (01 §5.6.0.5)»; «** TEST FAILED **». Verde dopo la correzione. Il mutante `gruppo_bloccato_senza_azioni` visto scattare dalla guardia dei mutanti (verde).
- **Il banco prosegue** (`PROSEGUE-25` da `InvariantiCampagnaTest`): `pianura_vince_e_prosegue` battaglie=1 VINTA, giornateDopoLaPrimaBattaglia=**33** su 40; media **18**, massimo **33** (dallo strumento), zero violazioni di giocabilità.

## La corsa completa delle sessioni

`scripts/esegui-sessioni-complete.sh`: «Corsa separata: SUCCESSO». 1/2 le **144** configurazioni di CAMPAGNA per l'interfaccia (VERDE, durata prova 1020,0 s dal blocco `IDETestOperationsObserverDebug`); 2/2 le sessioni HEADLESS di campagna e le **32** di battaglia al Motore, `SessioniCompleteTest` **15 prove, 0 fallite**. Esito in `esiti-sessioni-complete/esito.json`: `successo`, `commit: 6d580a5…`.

## La versione e il versionamento

Versione dei valori RESTA **0.11.0** (nessun valore tarato nuovo). Schema del giornale di CAMPAGNA **6 → 7** (`FondazioneCampagna.schemaCorrente`): la regola del ritorno cambia il modo in cui una partita in corso si svolge (il combattente agito, la casella di ripiegamento); i salvataggi v6 si DICHIARANO incompatibili (`schemaIncompatibile`, annunciato da `SchermateContorno.riprendiCampagna`). È la build che scioglie la campagna bloccata del titolare, che riparte da una partita nuova. Schema della battaglia RESTA 2. Versione dei Testi RESTA **0.1.1** (chiavi nuove `ripiegamento.titolo`/`ripiegamento.casella`, etichette d'azione; impronte per file rigenerate). Marketing **1.1.0**, certificati, profili e identificatori NON toccati.

Ramo dedicato `blocco-dopo-battaglia-ripiegamento`, commit **6d580a5** (codice, prove, invariante, dati, registri, nota). Fuso su `principale` con `git merge --ff-only`; spinti `principale` e il ramo. La correzione della nota per il titolare (il termine tra virgolette respinto dal controllo) è un commit successivo su `principale` (d91d7f2). Stato finale accertato con `git rev-parse principale` uguale a `git rev-parse origin/principale`.

## Il caricamento e la verifica per interfaccia di programmazione

Build **27** caricata (`carica-testflight.sh`, «UPLOAD SUCCEEDED with no errors», Delivery UUID `86d8ab18-1595-4bba-8671-a7dbbfefe642`). Numero di build = massimo su tutto l'account più uno (26 → 27). Cancelli preventivi verdi prima dell'archivio: `principale` locale == `origin/principale`; marketing 1.1.0 non all'indietro; `controlla-note.py` verde (nota di rilascio 2338 caratteri; nota per il titolare fresca, 36 nomi tutti esposti); `controlla-build.py` verde; `controlla-sessioni.py` (esito fresco su `6d580a5`) verde; `collaudo-completo.sh` rieseguito verde (83/83). Build 27 registrata in `build-caricate.md` (riga `| 27 | 2026-08-12 10:52:02 | 1.1.0 | d91d7f2 | …`).

**Verifica per interfaccia di programmazione (`asc_api.py`/`controlla-build.py`, credenziali da `scabo_deploy.env`).** La build 27 è **`processingState = VALID`**, **`expired = False`**, sul treno **`1.1.0`** (la più alta del treno più alto), assegnata a **un gruppo di test** (`betaGroups = 1`). Registro e App Store Connect concordano NEI DUE VERSI (`controlla-build.py`): «registro e App Store Connect concordano: 27 build, la più alta è la 27».

## Registri toccati

`Fondamenta/registro-decisioni-architetturali.md`: RDA-135 (la causa vera del blocco), RDA-136 (il ripiegamento coi casi limite chiusi), RDA-137 (l'invariante della giocabilità). `registro-scostamenti.md`: S25 (a–d). `valori-provvisori.md`: le versioni e lo scenario di verifica. `build-caricate.md`: riga 27. `Incarichi/README.md`: riga 25. Incarico e resoconto archiviati verbatim in `Incarichi/`.
