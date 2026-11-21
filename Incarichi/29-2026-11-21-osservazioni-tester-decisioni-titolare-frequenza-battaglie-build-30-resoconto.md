Resoconto — Incarico 29: le osservazioni del tester, quattro decisioni del titolare, la frequenza delle battaglie, la build 30

## In testa

- ⟨IN ATTESA: build 30⟩
- Le sei osservazioni della sessione da tester: ciascuna riprodotta da una prova che fallisce sul codice della build 29 e poi corretta (9a83674). L'intermittenza del fuoco sull'iPad (osservazione 3) ha una causa accertata con otto serie controllate: la notifica del gioco partiva dopo il caricamento asincrono dello stato e, se il caricamento durava abbastanza, cadeva nella finestra in cui VoiceOver applicava il proprio fuoco predefinito sulla prima cella; ora parte in `viewDidAppear`, 20 aperture su 20 sull'intestazione con i ritardi che prima la facevano cadere. La causa dell'osservazione 5 è quella ipotizzata (tratti aggiornati soltanto dopo la ricarica asincrona), più un reperto dal vivo: la frase «è selezionato» dell'incarico 28 era la lettura della messa a fuoco PRIMA del doppio tocco che deselezionava.
- Decisioni del 21 novembre: D1 (testo dinamico, una prova per schermata alla dimensione massima, vista fallire), D2 (frasi accordate al genere, cancello visto fallire), D3 (designazione: prima la posizione, poi il costo; l'avvertimento lo dice il comando) realizzate; D4 (previsione del meteo) nei documenti, nessun codice; punto aperto 11.10 della modalità a campioni.
- Frequenza delle battaglie misurata col banco su 1200 partite intere per misura (strumento `MisuraFrequenzaBattaglie`, `StrumentoVerifica --frequenza-battaglie`): rare, fra 0 e 0,104 ogni dieci giornate; tre cause strutturali; proposta al titolare, nessuna taratura.
- La misura ha trovato un difetto del Motore (RDA-161): lo sconfitto poteva ripiegare nella meta di una marcia propria in corso; all'arrivo due gruppi della stessa parte stavano nella stessa casella e la scelta del gruppo della battaglia successiva seguiva l'ordine del dizionario, diverso a ogni processo. Corretto, con prove viste fallire. Valori 0.13.0 → 0.14.0 con 0.13.0 fra le compatibili; schema del giornale di campagna fermo a 9: le partite della build 29 si riaprono.
- Verifica attraverso l'interfaccia con VoiceOver, iPhone e iPad: ogni osservazione e decisione realizzata ha almeno un controllo dal vivo, salvo il gesto di uscita (non guidabile). La lettura delle schermate a testo massimo ha trovato una leva delle impostazioni oltre il bordo dell'iPhone: riprodotta con una prova, corretta (e68e39d), ripetuta dal vivo con l'app corretta.

## Lo stato di partenza, verificato

Alle 18:42 (comandi nel registro della sessione): `principale` = `origin/principale` = 72aec4c (`git rev-parse` sui due, e HEAD), albero pulito, nessun altro ramo. Valori 0.13.0 e testi 0.1.1 (`manifest.json` dei due alberi), schema del giornale di campagna 9 e di battaglia 2 (`Giornale.swift`, `schemaCorrente`), ultima decisione RDA-154 (`grep` sul registro). Build 29: ultima riga di `build-caricate.md` (29, 2026-11-21 13:05:58, 1.1.0, b8abc93) e verifica per API dell'incarico 28 (`Incarichi/28-2026-11-21-prodotti/build-29/asc-build-29.md`); all'inizio NON ripetuta per API, ripetuta alla fine (sezione App Store Connect). Tutto concorde con l'incarico: nessun motivo di fermarsi.

## Le versioni della macchina

macOS 27.0.1 (26A434); Xcode 27.2 (27B52), selezionato `/Applications/Xcode.app` e non cambiato; Swift 6.4.2; runtime iOS 27.0 (24A434). Simulatori: «WarSense iPhone Air» C86CB490-B9AE-48E8-BC1B-FDD2C52274B4 e «WarSense iPad Pro 13» D01FE19F-2594-4B94-98A0-E3F2486DAD1F per i piloti; «WarSense iPhone Air · 2» 76DF33B6-7EA7-489D-98AD-459879B75C2D per collaudo e sessioni complete, in parallelo ai piloti; «WarSense iPhone Air · 3» E2C6F42C-A154-485C-B504-DB8BB5C3FFA4 per il pilota con l'app corretta, acceso per quella corsa e poi spento. Apple M5 Pro, 15 core, 24 GB (`sysctl`). Python 3.9.6. Sulla stessa macchina girava un `xcodebuild test` di un altro progetto (ScaboPDF, sul suo iPad): non toccato.

## Le osservazioni, una per una

Uscite rosse sul codice della build 29 in `Incarichi/29-2026-11-21-prodotti/prove-rosse/`: `ospitate-osservazioni-sul-codice-della-build-29.txt` (prove ospitate, copia di lavoro pulita a 72aec4c più le sole prove nuove) e `pacchetto-sul-codice-della-build-29.txt` (pacchetto). Le asserzioni fallite sono contate con `grep "error: -\[" … | sort -u` su quei file (righe distinte: nel file delle ospitate una riga compare due volte).

| oss. | prova che la riproduce (rossa sulla build 29) | commit | causa e correzione | dal vivo con VoiceOver |
|---|---|---|---|---|
| 1 | `OsservazioniTesterTest.test_osservazione_1_il_pannello_di_un_gruppo_bloccato_dichiara_il_motivo` (3 asserzioni) | 9a83674 | il pannello di un gruppo fuori dalla casella contesa, con una battaglia in sospeso, offriva la sola chiusura senza dire perché; ora dichiara il motivo e il luogo, ricavati dalla validazione del Motore (`motivoDelBlocco`). La prova ha trovato anche la revoca della marcia offerta a un gruppo bloccato, che il Motore avrebbe respinto: ora si offre solo se valida | al giorno 4 di una campagna piccola, pannello di Orso: «Nessun ordine possibile: c'è una battaglia in sospeso in riga 2, casella 2», iPhone e iPad |
| 2 | `AccordoAlNumeroTest` (2 prove, 3 asserzioni) e `OsservazioniTesterTest.test_osservazione_2_…` (2) | 9a83674 | il verbo era fuori dalla regola del plurale; frase intera per numero in `Annunci.stringsdict` | «Giorno 1. Ha agito 1 gruppo su 4», iPhone e iPad |
| 3 | `OsservazioniTesterTest.test_osservazione_3_il_fuoco_d_apertura_parte_alla_comparsa_senza_attendere_il_caricamento` (3) | 9a83674 | sezione «L'osservazione 3» qui sotto | «Riserve da schierare, intestazione» alla prima pronuncia, 2 aperture per apparecchio |
| 4 | `test_osservazione_4_il_gesto_di_uscita_chiude_impostazioni_e_apprendimento` (7) e `…_congeda_il_resoconto` (3) | 9a83674 | `accessibilityPerformEscape` mancava su impostazioni, suoni e vibrazioni, resoconto | NON guidabile dal vivo: tentato col tasto Esc della tastiera del simulatore, le impostazioni restano aperte (iPhone e iPad) |
| 5 | `OsservazioniTesterTest.test_osservazione_5_la_tessera_dichiara_lo_stato_nuovo_appena_attivata` (3) | 9a83674 | i tratti della tessera cambiavano soltanto dopo la ricarica asincrona dello stato dalla Sessione: per qualche centinaio di millisecondi la tessera appena attivata dichiarava lo stato di prima. Ora il comando validato dal Motore si applica subito allo stato presentato (`MotoreBattaglia.applica`, la stessa funzione della Sessione), poi va alla Sessione; se la Sessione lo respinge, lo stato si ricarica | sezione «L'osservazione 5» qui sotto |
| 6 | `SessioneBattagliaTest.test_incarico_29_azzeramento_a_vuoto_rifiutato` (2), `test_osservazione_6_…_in_battaglia_…` (2) e `…_in_campagna_…` (1) | 9a83674 | `SessioneBattaglia.azzera` non distingueva il turno senza comandi propri; ora lo rifiuta e l'interfaccia dice «Niente da azzerare in questo turno» (in campagna la frase propria) | a vuoto «Niente da azzerare in questo turno»; con comandi «Schieramento del turno azzerato», iPhone e iPad |

### L'osservazione 3: l'intermittenza, accertata prima di correggere

Indagine completa, con le serie, i registri dei tempi e gli script, in `Incarichi/29-2026-11-21-prodotti/fuoco-apertura-ipad/README.md`. In sintesi: su una copia di diagnosi (worktree temporaneo, non committato) che registrava con l'orario ogni fuoco assegnato da VoiceOver e ogni notifica del gioco, otto serie sull'iPad. Con il codice com'era, 9 aperture su 9 corrette a macchina scarica e 10 su 10 a macchina caricata con due `swift test --parallel`: l'intermittenza non si riproduceva per caso. Senza alcuna notifica del gioco VoiceOver mette il fuoco su «riga 1, cella 1, libera» circa 800 ms dopo la presentazione (805–808 ms): è l'atterraggio dell'incarico 28. VoiceOver applica ogni notifica circa 770 ms dopo averla ricevuta. Rallentando artificialmente il caricamento (300–1500 ms) la caduta si riproduce: a 700 ms la notifica del gioco (771 ms) e lo spostamento del sistema (784 ms) si incrociano e il fuoco resta sulla prima cella (prova 22); in 9 aperture su 15 il fuoco passa dalla prima cella prima di arrivare all'intestazione. Non è accertato quanto durasse il caricamento nelle aperture dell'incarico 28: quella sessione non registrava i tempi dell'app; la condizione compatibile è la macchina carica di quella sessione (tre simulatori e tre piloti). Corretto (notifica in `viewDidAppear`, una volta): 20 su 20 con gli stessi ritardi, mai passando dalla prima cella. I conteggi della tabella del README sono contati a mano dalle righe dei registri, e lì dichiarati come tali.

### L'osservazione 5: la causa nel codice e il reperto dal vivo

La causa ipotizzata dall'incarico è confermata nel codice e riprodotta dalla prova ospitata (la tessera, interrogata subito dopo l'attivazione, dichiarava il tratto `.selected` di prima). Dal vivo, prima corsa del blocco «battaglia» (20:32–20:33): due controlli «NO» che erano difetti del guidatore, non dell'app — leggeva come «dopo l'attivazione» la pronuncia restituita subito dopo il doppio tocco, che è invece la lettura della messa a fuoco PRIMA dell'attivazione: `XCUIVoiceOverService` non restituisce alcuna pronuncia nuova dopo il doppio tocco sintetico. La frase «è selezionato» riferita dal tester dell'incarico 28 era quella lettura. Seconda corsa (20:36–20:37), con la tessera riletta spostando il fuoco avanti e indietro: dopo la deselezione «tiratori 5 atomi, volume 50, 1 esemplare», senza «selezionato», su iPhone e iPad. La pronuncia restituita dal servizio si tronca a 64 caratteri e taglia la forma accordata «selezionati» («… 1 esemplare, selezion»). Blocco «selezione» (21:13), lettura dall'albero di accessibilità: tessera scelta «tiratori … =5 atomi, volume 50, 1 esemplare, selezionati», tolta la scelta «… =5 atomi, volume 50, 1 esemplare», su iPhone e iPad.

## Le decisioni del titolare

| | che cosa | prove | commit | documenti |
|---|---|---|---|---|
| D1 | il testo segue la dimensione di sistema, tranne tessere del deck, celle, caselle | `TestoDinamicoTest`, una prova per schermata (avvio, impostazioni, apprendimento, resoconto, registro con voci e vuoto, divisione, battaglia col pannello, mappa col pannello) alla dimensione massima; rossa sulla build 29 (`testo-dinamico-prima-della-correzione.txt`, tre schermate con testi fermi a 28 e 15 punti) | 9a83674 | 02 §10.4 (2.8), 05 §10.14 (1.6), RDA-158 |
| D2 | frasi accordate al genere; termine invariabile; forma per ogni genere ricevibile | `AccordoDiGenereTest` (quattro prove: ogni soggetto dichiara genere e numero; ogni frase accordata ha la forma per ciascun genere; il codice inserisce soggetti solo nelle forme accordate; le frasi si risolvono nella forma del genere); visto fallire di proposito (`cancello-genere-visto-fallire.txt`, 6 asserzioni nelle quattro prove): tolte la forma maschile di `battaglia.contatto_subito` e la dichiarazione `genere.unita.tiratori`, e aggiunto in `Significati.swift` un lettore del termine soggetto senza `Testi.soggetto`; poi ripristinati dalla copia | 9a83674 | 02 §4.6, §15.2 (2.8, vale anche per i titoli dei campioni), 05 §8.7, RDA-157 |
| D3 | in designazione la cella comincia dalla posizione e chiude col costo; l'avvertimento lo dice il comando di marcia | `AnnunciEFuocoTest.test_02_3_3_con_selezione_la_cella_comincia_dalla_posizione_e_chiude_con_la_disponibilita`, `AnnuncioDiCasellaTest` e `MappaCampagnaAccessibileTest` aggiornati alla regola nuova | 9a83674 | 02 §3.3, §9.2.2, 01 §5.6.3.5, RDA-156 |
| D4 | previsione del meteo, termini chiusi, seme della partita, nell'informazione di stato, senza interrompere | nessun codice (il meteo non esiste) | 6429fee | 01 §12.2.1 (3.10), 02 §4.4, §6.5.1.3, §6.5.2.1, modalità a campioni 1.2 §11.10 aperto, RDA-159 |

Dal vivo (controlli in `verifica-con-voiceover/`): D2 «riga 8, cella 1, tua fanteria leggera A, occupata»; «tuo Orso», «tuo Corvo» sulla mappa; D3 in battaglia «riga 8, cella 1, libera, costa 55, restano 305», sulla mappa «riga 3, casella 2, strada battuta, raggiungibile in 1 giorno», e il comando di marcia che dice l'avvertimento; attivata la casella, «Corvo marcia verso riga 3, casella 2, 1 giorno al termine». D1 a testo massimo: impostazioni, apprendimento, battaglia e registro letti per intero con VoiceOver su iPhone e iPad; sulle schermate, la leva delle impostazioni dell'iPhone oltre il bordo, trovata così e corretta (sezione della verifica). In una battaglia di campagna giocata dal tester: «La tua fanteria leggera A è disfatta in riga 1, cella 1», «Ingaggiata fanteria leggera A avversaria, perdite inflitte lievi», «fanteria pesante B avversaria si sposta in riga 2, cella 1».

## La frequenza delle battaglie

Strumento, metodo, dati grezzi, varianti e riproducibilità in `Incarichi/29-2026-11-21-prodotti/frequenza-battaglie/README.md`; tabelle complete in `tabelle.md`. Tutti i numeri di questa sezione sono prodotti da `StrumentoVerifica --frequenza-battaglie 200 --giornate-massime 730` (valori 0.14.0, dopo RDA-161) e riassunti da `scripts/riassumi-frequenza-battaglie.py` sulle righe grezze; le tabelle qui sotto sono copiate da `tabelle.md`, non ricalcolate.

Misura principale, 200 partite per formato e condotta:

| formato | condotta | partite | battaglie ogni 10 giornate | nelle prime 120 giornate, ogni 10 | battaglie per partita: media; mediana; massimo | prima battaglia, giornata mediana | partite senza battaglie | durata fino alla fine naturale, mediana | finite in modo naturale | fine: avversario senza armati | fine: giocatore senza armati | fine: limite | ferme su una battaglia non conclusa | partite con invarianti violati |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| piccola | competente | 200 | 0,038 | 0,175 | 1,99; 2; 4 | 18 | 13 (6%) | 42,5 | 62 (31%) | 10 | 52 | 137 | 1 | 0 |
| piccola | prudente | 200 | 0,014 | 0,083 | 1,00; 1; 1 | 4 | 0 (0%) | – | 0 (0%) | 0 | 0 | 200 | 0 | 0 |
| media | competente | 200 | 0,104 | 0,101 | 6,79; 0; 169 | 68,5 | 116 (58%) | – | 0 (0%) | 0 | 0 | 175 | 25 | 0 |
| media | prudente | 200 | 0,028 | 0,173 | 2,08; 2; 3 | 11 | 0 (0%) | – | 0 (0%) | 0 | 0 | 200 | 0 | 0 |
| grande | competente | 200 | 0,019 | 0,071 | 1,23; 0; 92 | 55,5 | 120 (60%) | 54,5 | 16 (8%) | 16 | 0 | 177 | 7 | 0 |
| grande | prudente | 200 | 0,000 | 0,000 | 0,00; 0; 0 | – | 200 (100%) | – | 0 (0%) | 0 | 0 | 200 | 0 | 0 |

Le varianti (copie temporanee dei valori, `varianti.md`; i valori del gioco non cambiano), colonne scelte:

| variante | formato | condotta | battaglie ogni 10 giornate | nelle prime 120, ogni 10 | prima battaglia, giornata mediana | partite senza battaglie | finite in modo naturale | ferme su una battaglia non conclusa |
|---|---|---|---|---|---|---|---|---|
| base | piccola | competente | 0,038 | 0,175 | 18 | 13 (6%) | 62 (31%) | 1 |
| base | piccola | prudente | 0,014 | 0,083 | 4 | 0 (0%) | 0 (0%) | 0 |
| base | media | competente | 0,104 | 0,101 | 68,5 | 116 (58%) | 0 (0%) | 25 |
| base | media | prudente | 0,028 | 0,173 | 11 | 0 (0%) | 0 (0%) | 0 |
| base | grande | competente | 0,019 | 0,071 | 55,5 | 120 (60%) | 16 (8%) | 7 |
| base | grande | prudente | 0,000 | 0,000 | – | 200 (100%) | 0 (0%) | 0 |
| aggressivita-300 | piccola | competente | 0,037 | 0,178 | 15,5 | 16 (8%) | 59 (30%) | 0 |
| aggressivita-300 | piccola | prudente | 0,014 | 0,083 | 4 | 0 (0%) | 0 (0%) | 0 |
| aggressivita-300 | media | competente | 0,112 | 0,096 | 66 | 119 (60%) | 0 (0%) | 20 |
| aggressivita-300 | media | prudente | 0,028 | 0,173 | 11 | 0 (0%) | 0 (0%) | 0 |
| aggressivita-300 | grande | competente | 0,019 | 0,069 | 54 | 124 (62%) | 13 (6%) | 6 |
| aggressivita-300 | grande | prudente | 0,000 | 0,000 | – | 200 (100%) | 0 (0%) | 0 |
| aggressivita-700 | piccola | competente | 0,019 | 0,097 | 5 | 38 (19%) | 32 (16%) | 0 |
| aggressivita-700 | piccola | prudente | 0,013 | 0,080 | 4 | 9 (4%) | 0 (0%) | 0 |
| aggressivita-700 | media | competente | 0,246 | 0,228 | 30,5 | 86 (43%) | 0 (0%) | 20 |
| aggressivita-700 | media | prudente | 0,031 | 0,190 | 16 | 14 (7%) | 0 (0%) | 0 |
| aggressivita-700 | grande | competente | 0,011 | 0,064 | 53 | 135 (68%) | 11 (6%) | 7 |
| aggressivita-700 | grande | prudente | 0,000 | 0,000 | 39 | 199 (100%) | 0 (0%) | 0 |
| difesa-150 | piccola | competente | 0,037 | 0,172 | 14 | 13 (6%) | 59 (30%) | 0 |
| difesa-150 | piccola | prudente | 0,013 | 0,082 | 4 | 3 (2%) | 0 (0%) | 0 |
| difesa-150 | media | competente | 0,105 | 0,112 | 62 | 105 (52%) | 0 (0%) | 21 |
| difesa-150 | media | prudente | 0,028 | 0,173 | 11 | 0 (0%) | 0 (0%) | 0 |
| difesa-150 | grande | competente | 0,021 | 0,079 | 56 | 112 (56%) | 15 (8%) | 4 |
| difesa-150 | grande | prudente | 0,000 | 0,000 | – | 200 (100%) | 0 (0%) | 0 |
| raggio-3 | piccola | competente | 0,038 | 0,176 | 21 | 12 (6%) | 57 (28%) | 1 |
| raggio-3 | piccola | prudente | 0,014 | 0,083 | 6 | 0 (0%) | 0 (0%) | 0 |
| raggio-3 | media | competente | 0,148 | 0,121 | 57,5 | 102 (51%) | 0 (0%) | 27 |
| raggio-3 | media | prudente | 0,028 | 0,170 | 11 | 1 (0%) | 0 (0%) | 0 |
| raggio-3 | grande | competente | 0,013 | 0,074 | 52 | 117 (58%) | 15 (8%) | 12 |
| raggio-3 | grande | prudente | 0,000 | 0,000 | 26 | 199 (100%) | 0 (0%) | 0 |
| due-armati-avversari | piccola | competente | 0,039 | 0,175 | 16,5 | 18 (9%) | 79 (40%) | 0 |
| due-armati-avversari | piccola | prudente | 0,014 | 0,083 | 4 | 0 (0%) | 0 (0%) | 0 |
| due-armati-avversari | media | competente | 0,299 | 0,280 | 30 | 51 (26%) | 0 (0%) | 56 |
| due-armati-avversari | media | prudente | 0,042 | 0,253 | 9 | 0 (0%) | 0 (0%) | 0 |
| due-armati-avversari | grande | competente | 0,040 | 0,216 | 21 | 33 (16%) | 7 (4%) | 31 |
| due-armati-avversari | grande | prudente | 0,004 | 0,022 | 18 | 147 (74%) | 0 (0%) | 0 |

Il ritmo atteso nei documenti: nessun numero. 01 §5.6.2 descrive un ritmo «a titolo illustrativo e senza valore normativo» e dice che «il ritmo non va progettato: discende dalle regole»; 01 §6.1.3, §16.4 e 03 §6.5 affidano la frequenza degli scontri al carattere degli ufficiali avversari, da tarare con le simulazioni; `valori-provvisori.md` dichiara provvisoria l'aggressività, «la manopola che 01 §6.1.3 dichiara decidere molto più di prima la frequenza degli scontri».

Le cause, misurate: (1) ogni scenario del gioco dà all'avversario UN solo gruppo armato; (2) la condotta avversaria aggira le formazioni note del giocatore e torna a difendere il quartier generale; (3) le battaglie non sono decisive: lo sconfitto ripiega e torna (una partita media competente conta 169 battaglie, il massimo della colonna, senza che il gruppo avversario sia mai annientato). La campagna non ha altra fine che una parte senza armati.

### La proposta al titolare, non decisa

1. Più gruppi armati avversari negli scenari: con un secondo gruppo (variante `due-armati-avversari`), media competente da 0,104 a 0,299 battaglie ogni dieci giornate, grande competente da 0,019 a 0,040 con la prima battaglia alla giornata 21 invece che alla 55,5, e il 26% delle partite grandi prudenti con almeno una battaglia invece di nessuna (147 su 200 senza; i rapporti fra le colonne sono calcolati a mano). Effetto collaterale misurato: le partite ferme su una battaglia non conclusa salgono da 32 a 87 (media e grande competenti).
2. Una fine della campagna (la stagione, che i documenti prevedono, o la presa del quartier generale): non misurabile finché la regola non esiste.
3. Non alzare da sola l'aggressività: a 700, sopra la difesa del quartier generale (500), la media competente sale a 0,246 ma la piccola scende da 0,038 a 0,019 e la grande da 0,019 a 0,011.
4. Prima di tarare, accertare le battaglie che al banco non si concludono entro 400 giri: 33 partite su 1200 (tutte competenti, 32 nei formati medio e grande; 22 sulla casella del quartier generale avversario, altre 5 nella prima riga: tabella «Le partite ferme…» di `tabelle.md`). A chi gioca resterebbe la sola resa; non è accertato se dipenda dal tattico del banco o dalle regole.

Note per il titolare: `nota-per-il-titolare-frequenza-delle-battaglie.md`.

## Il difetto trovato dalla misura (RDA-161)

Il registro delle decisioni dà causa, misura, correzione e versioni; qui ciò che è successo. Alle 20:50, rigenerati i dati dopo la correzione delle uscite dello strumento (c61c131), le tabelle sono uscite diverse in tre righe; il confronto riga per riga dei dati grezzi ha isolato UNA partita su 1200 (media, competente, seme 179). Sei corse da 200 partite per cella, in sei processi: esiti alternati (corse 1, 3, 5 ferme al giorno 110 con tre battaglie; 2, 4, 6 a 730 giornate con dieci). Quattro corse con `SWIFT_DETERMINISTIC_HASHING=1`: sempre 730 giornate. Copia diagnostica dello strumento con l'impronta dello stato a ogni passo per quella sola partita (tolta con `git checkout` prima di continuare): prima riga diversa la 615, chiusura del giorno 79. Prove rosse: `prove-rosse/ripiegamento-nella-meta-di-una-marcia.txt`. Dopo la correzione: tre corse in tre processi, 0 partite diverse su 1200; nessuna violazione della sonda in 7200 partite (misura principale e cinque varianti); cambiano soltanto le due partite toccate (confronto riga per riga dei dati grezzi, script in linea non committato).

## La verifica attraverso l'interfaccia, con VoiceOver

Canale: il pilota dell'incarico 28 (`SessioneInterattivaTest.test_sessione_da_tester`, schema `WarSenseEsplorazione`), uno per apparecchio sui due simulatori di WarSense, guidato da `P/verifica-con-voiceover/percorsi.py`, che per ogni controllo scrive atteso, trovato ed esito; VoiceOver acceso (`vo_accendi`), lettura dal servizio `XCUIVoiceOverService` e dall'albero di accessibilità. App costruita alle 20:29 dal codice di 9a83674 (le correzioni del Motore e della leva vengono dopo: sotto, la ripetuta). Esiti integrali in `P/verifica-con-voiceover/{iphone,ipad}/controlli.jsonl`, trascrizioni dei passi in `esiti.jsonl`, schermate in `schermate/`.

| controllo | iPhone | iPad |
|---|---|---|
| oss. 3 — aprendo uno scontro, prima pronuncia «Riserve da schierare, intestazione» | ok, 2 aperture | ok, 2 aperture |
| oss. 6 — azzeramento a vuoto: «Niente da azzerare in questo turno»; con comandi: «Schieramento del turno azzerato» | ok | ok |
| D3 — con un elemento scelto, «riga 8, cella 1, libera, costa 55, restano 305» | ok | ok |
| D2 — piazzata, «riga 8, cella 1, tua fanteria leggera A, occupata» | ok | ok |
| oss. 5 — riletta dopo la deselezione, «tiratori 5 atomi, volume 50, 1 esemplare», senza «selezionato» | ok | ok |
| oss. 5 e D2 — dall'albero: scelta, valore «…, selezionati»; tolta, senza | ok | ok |
| D2 — mappa: «tuo Orso», «tuo Corvo» | ok | ok |
| oss. 2 — tocco magico: «Giorno 1. Ha agito 1 gruppo su 4» | ok | ok |
| D3 — il comando di marcia dice l'avvertimento; le caselle in designazione «riga 3, casella 2, strada battuta, raggiungibile in 1 giorno»; attivata: «Corvo marcia verso riga 3, casella 2, 1 giorno al termine» | ok | ok |
| oss. 1 — al giorno 4 di una campagna piccola, il pannello di Orso: «Nessun ordine possibile: c'è una battaglia in sospeso in riga 2, casella 2» | ok | ok |
| D1 — a testo massimo (`accessibility-extra-extra-extra-large` con `simctl ui content_size`), letti per intero con VoiceOver: impostazioni (12 pronunce, «è selezionato Normale»), apprendimento (21 e 20), battaglia fino a «Fine del turno», registro fino al congedo | ok | ok |
| oss. 4 — il gesto di uscita dal vivo | NON guidabile: il servizio non ha il gesto; il tasto Esc della tastiera del simulatore lascia aperte le impostazioni | idem |

Tre controlli «NO» della prima corsa del blocco «battaglia» (20:33) e uno della seconda (20:37) sono difetti del guidatore, non dell'app, e restano nei registri: la pronuncia subito dopo il doppio tocco è la lettura della messa a fuoco prima dell'attivazione (sezione «L'osservazione 5»), e la pronuncia restituita si tronca a 64 caratteri e taglia «selezionati»; il blocco «selezione», con la lettura dall'albero, li sostituisce. Il primo percorso «blocco» (17 giornate, 333 passi per apparecchio, fermato poco prima delle 21:06, ora letta con `date` subito dopo il riavvio) non ha mai fatto marciare un gruppo: il guidatore cercava la meta fra le voci del pannello, che a pannello aperto è modale; corretto, il secondo ha trovato la battaglia al giorno 4.

**Che cosa si è visto sulle schermate.** A testo massimo sull'iPhone la leva «Suoni del gioco» delle impostazioni usciva dal bordo destro (`schermate/iphone-testo-massimo-impostazioni-prima-della-correzione.png`): VoiceOver la leggeva («Interruttore attivo»), il controllo del percorso era «ok», ma la schermata no. Riprodotto con una prova, corretto (e68e39d, RDA-158). Sull'iPad la riga entrava. Nella schermata di battaglia a testo massimo la griglia appare tagliata a sinistra e in alto: è lo scorrimento del contenitore portato da VoiceOver durante la lettura, e le celle hanno misura fissa per decisione.

**La ripetuta con l'app corretta** (`P/verifica-con-voiceover/iphone-app-corretta/`): app costruita da e68e39d in una cartella di prodotti separata (`Applicazione/build/esplorazione-29b`), pilota nuovo sul terzo iPhone, blocco «testo» intero in 256 s: tutti i controlli di D1 «ok», il gesto di uscita di nuovo non guidabile; sulla schermata la riga va a capo («Suoni / del gioco») e la leva resta dentro (`schermate/iphone-testo-massimo-impostazioni-app-corretta.png`). Le altre correzioni successive all'app delle 20:29 sono del Motore (RDA-161) e dello strumento di misura: nessuna tocca ciò che i percorsi leggono.

**Il tester dell'incarico 28** (`scripts/tester.py … piccola 6 nuova tutti`, iPhone, app delle 20:29; `P/verifica-con-voiceover/tester-iphone/`): sei giornate in 870 s (`date +%s` attorno al comando), con le etichette nuove che riconosce dopo l'aggiornamento delle sue espressioni regolari (9a83674). Ogni armato marcia verso nord; al giorno 3 una battaglia in sospeso, aperta con la prima pronuncia «Riserve da schierare, intestazione»; giocata in 7 turni, persa per annientamento; il resoconto letto per intero («Sconfitta: è stato annientato», «Durata: 7 turni», «Perdite tue: 600 punti su 600 impegnati», …); ritorno in campagna al giorno 4 con tre gruppi, poi tre giornate fino al giorno 7. Una nota del tester alle 21:25, «tocco magico non eseguito: nessun bersaglio visibile»: è il suo canale (il doppio tocco a due dita va dato su un elemento visibile, e in quell'istante non ne trovava), non l'app; il tocco magico era riuscito in tutte le altre 14 letture dell'informazione di stato. Sentito in campagna: «Giorno 2. Nessun gruppo ha agito, 2 in marcia lunga su 4», «Lupo marcia verso riga 2, casella 3, 4 giorni al termine».

**Osservato, non corretto.** Le azioni d'ingaggio e le voci di mischia dicono la posizione senza virgola («Ingaggia fanteria leggera A avversaria in riga 1 cella 2, …»; chiavi `pannello.ingaggia.*`, `battaglia.mischia_voce`), mentre ovunque altrove si dice «riga 1, cella 2». C'era già sul codice della build 29 (`git show 72aec4c:…/Annunci.strings`); non toccato per non riaprire collaudo e sessioni a fine incarico.

## Le versioni: la valutazione

Valori 0.13.0 → 0.14.0 con `versioni_compatibili` che aggiunge 0.13.0 (RDA-161, `valori-provvisori.md`): cambia l'applicazione di una regola della campagna, il ripiegamento; una campagna della build 29 prosegue diversamente soltanto dove il Motore di prima produceva lo stato vietato, e il suo giornale si rigioca identico perché la riga `battagliaConclusa` porta le caselle del ritorno. Nessuna delle altre modifiche tocca una regola che una partita in corso legga: le sei osservazioni e D1–D3 sono presentazione e Sessione (l'azzeramento a vuoto si rifiuta prima di scrivere nel giornale), D4 è documento. Schema del giornale di campagna 9 e di battaglia 2, fermi: nessuna riga nuova né cambiata. Testi 0.1.1, fermi, con le impronte rigenerate (9a83674). Versione di marketing 1.1.0, non toccata. Le campagne e gli scontri salvati con la build 29 si riaprono: lo dicono le due note.

## Le decisioni prese da solo, e perché

1. **RDA-161 corretto in questo incarico, e le versioni così.** Il difetto viola una regola scritta (01 §5.6.0.2) e rende l'esito di una campagna dipendente dal processo: tenerlo fino a un incarico successivo voleva dire caricare la build 30 sapendolo. Valori a 0.14.0 perché il criterio di 03 §9.2.1 è soddisfatto; 0.13.0 compatibile e schema fermo perché la rigiocatura è identica e la sola prosecuzione diversa è quella che la regola vieta (stesso ragionamento di RDA-149). La scelta non toglie ai tester alcuna partita salvata.
2. **`occupante(di:parte:)` non reso deterministico.** Con l'invariante rispettato l'occupante è unico; un ordine fisso in uno stato vietato nasconderebbe il segnale che la sonda deve vedere (RDA-161).
3. **D2: le parole di stato che seguono il nome come voci a sé restano invariate** («impegnato», «in attesa», «ha agito»): sono segnali fissi del vocabolario chiuso, letti da soli dopo la virgola, non predicati del soggetto (RDA-157). Il genere dei nomi dei gruppi è quello della parola (Aquila, Lince, Volpe femminili): il nome è un termine invariabile, come chiede la decisione.
4. **D1: i selettori a segmenti delle impostazioni (verbosità, intensità delle vibrazioni) sostituiti da elenchi di pulsanti a capo (`SceltaAVoci`).** Il selettore di sistema non cresce con la dimensione del testo e a testo massimo ne tronca i nomi; la decisione vuole il testo che segue il sistema in ogni schermata salvo le tre eccezioni nominate. La scelta si dichiara col tratto «selezionato».
5. **D3 applicata anche alle celle del campo di battaglia, non soltanto alla mappa.** 00 §7.1 vuole un solo modo di annunciare la stessa cosa su tutte le superfici; cambiare la mappa e non il campo l'avrebbe violato (RDA-156).
6. **D4: la previsione si dice con «possibilità alta», non «pioggia probabile».** L'esempio della decisione usa un termine che non sta fra i termini chiusi della probabilità (02 §4.4); lo scrivo così finché il titolare non decide un termine nuovo, e lo dice la nota.
7. **Osservazione 5: il comando validato si applica allo stato mostrato con `MotoreBattaglia.applica` prima che la Sessione risponda.** Le alternative — attendere la Sessione (il difetto) o calcolare i tratti nell'interfaccia (vietato, 00 §3.2) — non reggevano; la funzione è la stessa della Sessione, e un rifiuto ricarica lo stato.
8. **Osservazione 1: la revoca della marcia non si offre più se il Motore la respinge.** Trovato dalla prova dell'osservazione; 02 §9.5 vieta di offrire un'azione respinta.
9. **La misura della frequenza: due condotte, 200 partite per cella, 730 giornate, cinque varianti scelte fra le grandezze che i documenti indicano come manopole della frequenza.** La condotta competente dà il primo ordine valido della sequenza del banco (S27g); la prudente non riproduce la resa del tester (S27h). Nessuna taratura.
10. **Le battaglie che al banco non si concludono, registrate e non corrette.** La causa non è accertata (tattico del banco o regola); correggerla senza accertarla era tarare prima di misurare.
11. **Il collaudo sul secondo iPhone di WarSense** (`simulatore-warsense.sh iphone 2`), in parallelo ai piloti sui due apparecchi principali, per non fermare la verifica con VoiceOver.

## Modifiche, per commit

Percorsi relativi alla radice; `P/` sta per `Incarichi/29-2026-11-21-prodotti/`.

- fa25bb1 — `Incarichi/29-2026-11-21-…-incarico.md`, `Incarichi/README.md`.
- 9a83674 — `Applicazione/Sorgenti/{SchermataBattaglia,SchermataMappaCampagna,SchermateContorno,Impaginazione,SchermataRegistro,SchermataDivisione,CostruttoreAnnunci,CostruttoreAnnunciCampagna}.swift`, `Applicazione/WarSense.xcodeproj/project.pbxproj`; `Codice/Sources/Dati/{Genere,Testi}.swift`, `Codice/Sources/Segnali/{Significati,SignificatiCampagna}.swift`, `Codice/Sources/Sessione/SessioneBattaglia.swift`; `Codice/Sources/Contenuti/Testi/it.lproj/{Annunci.strings,Annunci.stringsdict,Vocabolario.strings}`, `Codice/Sources/Contenuti/Testi/manifest.json`; prove `Applicazione/ProveOspitate/{OsservazioniTesterTest,TestoDinamicoTest}.swift` (nuove), `{AnnunciEFuocoTest,AnnuncioDiCasellaTest,CatenaInterfacciaMotoreTest,DesignazioneBersaglioTest,MappaCampagnaAccessibileTest,RaggiungibilitaTest}.swift`, `Applicazione/ProveInterfaccia/FumoInterfacciaTest.swift`, `Codice/Tests/DatiTest/{AccordoAlNumeroTest,AccordoDiGenereTest}.swift` (nuove), `Codice/Tests/SegnaliTest/{TraduttoreCampagnaTest,TraduttoreEventiTest}.swift`, `Codice/Tests/SessioneTest/SessioneBattagliaTest.swift`; `scripts/tester.py`; `P/prove-rosse/`, `P/fuoco-apertura-ipad/`.
- 6429fee — `Fondamenta/02-accessibilita.md` (2.8), `Fondamenta/01-progetto-del-gioco.md` (3.10), `Fondamenta/modalita-a-campioni.md` (1.2).
- e48c5b5 — `Codice/Sources/Verifica/MisuraFrequenzaBattaglie.swift` (nuovo), `Codice/Sources/Verifica/BancoCampagna.swift`, `Codice/Sources/StrumentoVerifica/main.swift`, `Codice/Tests/VerificaTest/MisuraFrequenzaBattaglieTest.swift` (nuovo), `scripts/riassumi-frequenza-battaglie.py` (nuovo), `P/frequenza-battaglie/`.
- 005a3c4 — `P/frequenza-battaglie/{varianti.md,crea-varianti.py}`.
- a5e8d20 — `Fondamenta/registro-decisioni-architetturali.md` (RDA-155–160), `registro-scostamenti.md` (S27a–h), `Fondamenta/05-architettura-tecnica.md` (1.6), `Fondamenta/matrice-di-copertura.md`.
- d44e8d7 — `note-di-rilascio.txt`, `nota-per-il-titolare-genere-testo-marcia-e-correzioni.md`, `nota-per-il-titolare-frequenza-delle-battaglie.md`, `P/verifica-con-voiceover/percorsi.py`.
- c61c131 — `Codice/Sources/Verifica/MisuraFrequenzaBattaglie.swift`.
- cf09ce9 — `Codice/Sources/Motore/PonteCampagnaBattaglia.swift`, `Codice/Sources/Contenuti/Valori/manifest.json` (0.14.0), `Codice/Sources/Verifica/MisuraFrequenzaBattaglie.swift`, `Codice/Tests/MotoreTest/RipiegamentoTest.swift` (nuovo), `Codice/Tests/VerificaTest/MisuraFrequenzaBattaglieTest.swift`, `Fondamenta/registro-decisioni-architetturali.md` (RDA-161, RDA-160 corretto), `valori-provvisori.md`, `scripts/riassumi-frequenza-battaglie.py`, `P/frequenza-battaglie/` (dati rigenerati), `P/prove-rosse/ripiegamento-nella-meta-di-una-marcia.txt`.
- d8fc804 — le tre note, `P/verifica-con-voiceover/percorsi.py`.
- e68e39d — `Applicazione/Sorgenti/SchermateContorno.swift` (la riga della leva), `Applicazione/ProveOspitate/TestoDinamicoTest.swift` (`fuoriDalBordo`), `P/prove-rosse/leva-oltre-il-bordo-a-testo-massimo.txt`.
- 144c23c — `note-di-rilascio.txt`, `nota-per-il-titolare-genere-testo-marcia-e-correzioni.md`, `Fondamenta/registro-decisioni-architetturali.md` (RDA-158, il reperto dal vivo).
- 0b8a110, 39ec83c — `nota-per-il-titolare-genere-testo-marcia-e-correzioni.md` (titolo: il controllo delle cifre ha rifiutato il «21» della data).
- ⟨IN ATTESA: prodotti della verifica, resoconto, fusione⟩

## Ciò che ho fatto senza che fosse chiesto

- La correzione del Motore di RDA-161 (ripiegamento nella meta di una marcia propria), con le versioni, e la sonda degli invarianti dello stato dentro lo strumento di frequenza, che ora la interroga in ogni partita misurata.
- La revoca della marcia offerta soltanto se il Motore la accetta (trovata dalla prova dell'osservazione 1).
- Cinque varianti della misura della frequenza, per dare alla proposta un effetto misurato.
- `scripts/tester.py` aggiornato alle etichette nuove (cella in designazione che comincia dalla posizione; possessivo nelle quattro forme accordate): senza, il tester dell'incarico 28 non avrebbe più riconosciuto le celle valide né i propri gruppi.
- RDA-160 corretto (il conteggio delle partite ferme e il «quasi sempre» sul quartier generale, che i dati non sostengono: 22 su 33).

## Ciò che era chiesto e non ho fatto

- **Il gesto di uscita dal vivo (osservazione 4).** Non guidabile: `XCUIVoiceOverService` non ha lo strofinio a due dita, e il tasto Esc della tastiera del simulatore non arriva come `accessibilityPerformEscape` (tentato su entrambi gli apparecchi a testo massimo: impostazioni ancora aperte). Coperto un livello sotto dalle due prove ospitate, che chiamano `accessibilityPerformEscape` sulla schermata presentata e verificano chiusura e ritorno del fuoco.
- **La pronuncia di VoiceOver subito dopo il doppio tocco (osservazione 5).** Il canale non ne restituisce alcuna: dopo l'attivazione sintetica il servizio ripete la lettura della messa a fuoco. Lo stato nuovo si è verificato rileggendo la tessera e dall'albero, non nella frase che VoiceOver direbbe da sé dopo il doppio tocco su un apparecchio vero.
- **L'orizzontale.** Nessun percorso in orizzontale: l'attivazione sintetica in orizzontale non si guida (incarico 28; con Safari lo stesso, limite del simulatore).
- **Il testo massimo su mappa e divisione dal vivo.** I percorsi a testo massimo hanno letto impostazioni, apprendimento, battaglia e registro; mappa col pannello e divisione sono coperte dalle prove ospitate di `TestoDinamicoTest`, non dal vivo.
- **La resa del tester nella condotta prudente della misura** (S27h): non riprodotta.
- **Le battaglie che al banco non si concludono:** registrate (33 su 1200), causa non accertata.

## Tempi

Sessione dalle 18:42 (primo comando) alla chiusura. Fonte di ogni durata fra parentesi; ciò che non è stato misurato è detto.

- **Compilazione.** `swift build -c release --product StrumentoVerifica`: 8,2 s, 8,7 s e 33,1 s (riga «Build complete» di SwiftPM). Prove ospitate mirate (`xcodebuild test -only-testing:WarSenseTest/TestoDinamicoTest`, compilazione compresa): 35 s e 35 s (`date +%s`). `build-for-testing` dell'app del pilota corretto: non misurato. Archivio Release per la build 30: dentro il caricamento.
- **Collaudo.** `collaudo-completo.sh` tre volte (`date +%s`): 53 s, fermato da `ConfiniTest` (i motivi dello strumento di frequenza erano testo nel codice: cancello vero, corretto in c61c131); 388 s verde; 343 s verde sul codice finale. `swift test` del pacchetto da solo: 60 s. Sessioni complete: ⟨IN ATTESA⟩; una prima corsa, partita alle 21:13, fermata dopo circa tre minuti perché la correzione della leva l'avrebbe resa vecchia.
- **Simulatore.** Indagine dell'osservazione 3 sull'iPad: dalle 18:55 alle 19:33 (README dell'indagine). Percorsi «battaglia» e «campagna»: dalle 20:32 alle 20:37 (orari dei controlli). Primo percorso «blocco», senza marce: durata non registrata, fermato poco prima delle 21:06. Secondo «blocco» e «testo»: dalle 21:04 circa alle 21:13 (controlli alle 21:08 e alle 21:12). «Selezione»: 21:13. Ripetuta a testo massimo con l'app corretta: 256 s (`date +%s`).
- **Misura della frequenza.** 1200 partite con la sonda: 8 s; misura principale e cinque varianti, 7200 partite: 106 s (`date +%s`); le corse di riproducibilità (da 360 e da 1200 partite) non misurate.
- **Esplorazione.** Il tester: 870 s (`date +%s`).
- **Caricamento.** ⟨IN ATTESA⟩
