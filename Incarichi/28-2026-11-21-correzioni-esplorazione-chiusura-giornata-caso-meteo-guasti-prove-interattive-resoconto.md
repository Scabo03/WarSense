Resoconto — Incarico 28: correzioni dall'esplorazione, chiusura della giornata, caso per meteo e guasti, build 29, prove interattive approfondite

## In testa

- Build 29 caricata su TestFlight: VALID, treno 1.1.0 (il più alto), IN_BETA_TESTING per il gruppo interno WarLab, nota allegata, registro concorde (29 build). Verifica per API in `Incarichi/28-2026-11-21-prodotti/build-29/asc-build-29.md`.
- Il tasto «Chiudi la giornata» toglieva davvero il turno all'avversario: riprodotto sul codice della build 28 (in sei giornate chiuse col tasto l'avversario non si è mai mosso) e corretto; invariante nuovo `azione_avversaria_sottratta`, visto fallire tre volte (RDA-151). Valori 0.13.0, schema del giornale di campagna 9.
- Le nove osservazioni dell'incarico 27: otto corrette, ciascuna prima vista fallire sul codice della build 28; il pannello del gruppo a testo massimo non è un difetto dell'app (lo legge VoiceOver, si blocca XCUITest); la parte del carattere dinamico è una proposta, non decisa. Esplorazione ripetuta sugli stessi percorsi.
- Seconda parte: un canale nuovo a passi brevi (il pilota) e un tester che gioca con VoiceOver; il tocco magico e il rotore si guidano dal vivo; l'uscita, l'esecuzione delle azioni personalizzate, il doppio tocco ovunque e l'attivazione in orizzontale no. Osservazioni in `sessione-da-tester/osservazioni.md`, la più seria: con una battaglia in sospeso il pannello di un gruppo non dice perché non offre azioni (02 §6.5).

## Lo stato di partenza, verificato

`git fetch --all --prune`, `git rev-parse principale origin/principale`: entrambi 972aeb8; `git status` pulito; `riferimento-agosto` locale = remoto = 62e0828, con il solo commit non fuso 62e0828 (`git log principale..origin/riferimento-agosto`). RDA fino a 150, S fino a 26. Nessuna discrepanza. Sulla macchina girava per tutta la sessione un altro progetto (scabopdf-mac-lab: prove d'interfaccia macOS, `AutomationModeUI` attivo); non l'ho toccato.

## Le versioni della macchina

Invariate dall'incarico 27 (`sw_vers`, `xcodebuild -version`, `swift --version`, `xcrun simctl list runtimes`, `xcodegen --version`): macOS 27.0.1 (26A434), Xcode 27.2 (27B52), Swift 6.4.2, runtime iOS 27.0 (24A434) e 26.5 (23F77), xcodegen 2.45.4, Python 3.9.6. Corretto un errore del rapporto dell'incarico 27: Xcode 27.2 contiene DeviceHub.app, Accessibility Inspector.app e Instruments.app (`Contents/Applications/`, creati il 20–23 ottobre).

## Prima parte — che cosa è successo

**Il tasto della giornata.** Riprodotto prima di correggere: `ChiusuraGiornataTest` sul codice della build 28, quattro asserzioni fallite (`prove-rosse/chiusura-giornata-sul-codice-della-build-28.txt`). Il disegno della correzione e la decisione sul blocco dalla parte dell'avversario stanno in RDA-151; qui ciò che non si legge lì. La condotta dell'avversario, nel codice attuale, propone sempre comandi validi (il banco lo sorveglia): lo sblocco del tasto non ha un caso reale da provocare, ed è verificato un livello sotto, con una proposta respinta costruita a mano (`SbloccoTurnoAvversarioTest`). Prima della correzione un comando respinto della condotta sarebbe stato applicato comunque, fermando l'app sulla precondizione di `MotoreCampagna.applica`: letto nel codice, non riprodotto. Il mutante del banco: il difetto reintrodotto per un momento in `concludiLaGiornataDelGiocatore`, rifiutato su tutti e quattro gli scenari con l'avversario (`prove-rosse/chiusura-giornata-mutante-nel-banco.txt`), poi il Motore ripristinato dal file di riserva (`diff -q`: identico). Il banco che preme il tasto a giorni alterni: 77 pressioni su quattro scenari, nessuna violazione (riga `TASTO-28` della prova). Due prove scritte e tolte prima del commit, perché non affidabili: la battaglia in sospeso nella prova di sessione (lo scenario minimo non la produce sempre: l'avversario si scansa) e l'annullamento confrontato per impronta (l'annullamento è un fatto che il registro annota, quindi l'impronta cambia per forza; ora si confrontano i gruppi).

**Le osservazioni, riprodotte sul codice della build 28.** Una copia di lavoro temporanea del principale 972aeb8 in `Applicazione/build/rosso-28` (prodotti di compilazione, ignorati), con le due classi di prova nuove copiate dentro: 13 prove, 12 fallite, 1 passata (`xcresulttool`), 101 s compilazione compresa (`date +%s`); poi rimossa (`git worktree remove`). Uscite in `prove-rosse/osservazioni-27-sul-codice-della-build-28.txt`. Il resoconto vuoto si è riprodotto in ENTRAMBE le vie chieste: battaglia giocata senza interruzioni fino alla fine e battaglia ripresa e conclusa con la resa. La causa (due compiti separati in `SchermataBattaglia.ricevi`) è in RDA-153.

**Collaudi.** Tre collaudi completi sul ramo della prima parte. Il primo: un solo fallimento, la misura delle leve delle impostazioni (la prova misurava la cornice della vista e non il bersaglio allargato: corretta la misura, che ora pretende anche che il tocco copra i 44 punti); 98 su 99. Il secondo, dopo la misura e il modo Swift 6: pacchetto 350 eseguite, 0 fallite, 1 saltata (somma dei fasci di `swift test` fatta da uno script); ospitate e interfaccia 99 su 99 (`xcresulttool`); 391 s. Il terzo, dopo le correzioni del ritorno del fuoco: stessi numeri, 315 s. Le prove nuove della prima parte sono 24: 6 del tasto (`ChiusuraGiornataTest`, cinque di sessione e una del banco) e 1 dell'invariante (`InvariantiCampagnaTest`), 3 dello sblocco (`SbloccoTurnoAvversarioTest`), 9 ospitate (`OsservazioniEsplorazioneTest`), 5 d'interfaccia (`TaglieEOrientamentiInterfacciaTest`) — conteggio dai file; le ospitate e d'interfaccia passano da 85 a 99, coerente.

**Una prova d'interfaccia scritta e tolta.** `test_osservazione_5_il_pannello_del_gruppo_a_testo_massimo` non può passare: a testo massimo XCUITest scambia l'avviso del pannello per un'interruzione esterna, non ne tocca le voci e il suo gestore delle interruzioni gira senza fine (2513 righe nel registro, `grep -c`), finché xcodebuild esce con 138. È la causa dell'uscita 138 delle due corse a testo massimo dell'esplorazione, sia nell'incarico 27 sia ora. VoiceOver invece legge e raggiunge tutte le voci del pannello. Non era mai stata verde; uscita in `esplorazione-ripetuta/pannello-a-testo-massimo-xcuitest.txt`.

**Il modo Swift 6 dei bersagli di prova** non ha chiesto di indebolire alcuna prova (RDA-154).

**Il ramo `riferimento-agosto`** è cancellato in locale e sul remoto, dopo aver verificato che il solo commit non fuso, 62e0828, aggiungesse soltanto `.github/workflows/riferimento-agosto.yml`; il contenuto del file è conservato in `pulizie/ramo-riferimento-agosto.txt`.

**Il caso per meteo e guasti.** Il ripristino del perimetro della versione 3.7 tocca, oltre a 12.1, 12.2, 12.3, 12.5, 16.5 e 16.7, tutti i punti che l'incarico 27 aveva riformulato per il caso in 01, 02, 03, 05 e nella modalità a campioni: l'ho fatto scrivere a un sotto-agente con istruzioni precise e ho riletto il diff; ho aggiunto io il tasto in 01 §5.6.0.6 e le avvertenze dei due documenti di lavoro (RDA-152). Il cancello del vocabolario sui documenti (`VocabolarioOsservatoTest`) passa. Restano, segnalate e non toccate: la carta, nel contesto minimo, dice della modalità a campioni «con il caso confinato alle probabilità dichiarate di quello scontro», che leggo come detto dello scontro e quindi compatibile; nessun documento dice se meteo e guasti valgano anche nella modalità a campioni; nessun punto dice se le probabilità del meteo si annuncino al giocatore (12.3 vuole annunciato tutto ciò che è probabilistico, ma il linguaggio della probabilità è riservato a guasti e scontro a campioni): lacuna già presente nella versione 3.7.

**La forma del resoconto e la regola nuova.** Il cancello che la regola nuova chiedeva c'è: `controlla-note.py` rifiuta una nota per il titolare che gli chieda una prova. La prima forma era troppo debole (lasciava passare «verifica che il suo pannello offra la sosta» della nota della build 28): rafforzata, rifiuta sia una nota costruita apposta sia le due note vere che chiedevano prove (`prove-rosse/cancello-prove-a-mano-rosso.txt`); da quelle due note ho tolto le richieste. La nota per i tester (`note-di-rilascio.txt`) conserva «Cosa provare», perché la regola riguarda il titolare e quel campo di TestFlight è per i tester.

**L'esplorazione ripetuta sugli stessi percorsi** (le stesse dieci configurazioni dell'incarico 27, dieci simulatori, 2307 s): stesse uscite per configurazione (quattro 0, quattro 65, due 138), durate più lunghe perché i percorsi vanno più avanti. Che cosa è cambiato, confrontato per schermata con i rilievi dell'incarico 27: la battaglia a testo massimo su iPhone si legge fino a «Fine del turno» (108 → 109 pronunce) e il percorso arriva ora al resoconto; la mappa a testo massimo fino a «Torna all'inizio» (20 → 21); il resoconto ha 9 pronunce invece di 2 in ogni configurazione che vi arriva; l'avvio in orizzontale a testo massimo 7 elementi invece di 5; l'annuncio del tasto conta i soli gruppi propri; i segmenti e le leve misurano 44–45 punti nell'albero d'accessibilità; «Text clipped» 86 → 53 rilievi. Che cosa non è cambiato: in orizzontale l'impianto non riesce ad attivare alcun comando col doppio tocco, nemmeno quelli interamente visibili, su iPhone e su iPad (accertato poi nella seconda parte: è il canale); le corse a testo massimo finiscono ancora con 138 nel pannello del gruppo (sopra). E una cosa nuova, che l'esplorazione ha mostrato e che ho corretto: il ritorno del fuoco dopo la chiusura di una schermata riusciva con VoiceOver in 6 chiusure su 11, perché la notifica partiva dentro l'attivazione del pulsante di chiusura; spostata a chiusura compiuta, con il comando portato in vista, due esplorazioni mirate danno 8 chiusure su 8 (`esplorazione-mirata-fuoco`, `…-2`). Le schermate dell'esplorazione ripetuta NON ci sono: erano fra gli allegati in `Applicazione/build/esplorazione-corse/`, che lo script di caricamento cancella per intero prima di archiviare (sotto); restano i rilievi, la sintesi e i tempi.

**La build 29.** Fusione sul principale (2fefedb), sessioni complete sul principale: successo, 144 di campagna per l'interfaccia in 621,4 s e la corsa headless con le 32 di battaglia, 647 s in tutto (esito su 2fefedb). Le note rilette e ricommesse dopo l'ultimo commit di codice (il cancello di freschezza le avrebbe rifiutate). `carica-testflight.sh`: tutti i controlli preventivi passati, collaudo completo interno, caricamento, nota allegata, riga scritta in `build-caricate.md`; uscita 0, 592 s (`date +%s`). Il registro dell'esecuzione è perduto: lo avevo rediretto in `Applicazione/build/`, che lo script cancella (`rm -rf "$CARTELLA_BUILD"`) insieme ai registri dei collaudi, delle sessioni e agli allegati dell'esplorazione; i numeri riportati sopra li avevo già estratti. Integrazione continua: verde sulla fusione della prima parte (corsa 44905527544 su 2fefedb); l'esito sugli ultimi invii è in fondo.

## Le osservazioni dell'incarico 27, una per una

Commit della correzione 01c2439 salvo dove detto, fuso in 2fefedb. «Rossa» = vista fallire sul codice della build 28.

1. BLOCCANTE, «Fine del turno» a testo massimo su iPhone — CORRETTA. Prove: `OsservazioniEsplorazioneTest.test_osservazioni_1_5_la_battaglia_e_raggiungibile_in_ogni_configurazione` (rossa), `TaglieEOrientamentiInterfacciaTest.test_osservazione_1_fine_del_turno_a_testo_massimo` (rossa: «Failed to scroll to visible … kAXErrorFailure»). Esplorazione: 109 pronunce fino a «Fine del turno».
2. SERIA, resoconto vuoto — CORRETTA. Prove: `test_osservazione_2_il_resoconto_di_una_battaglia_giocata_fino_alla_fine` e `…_ripresa_e_conclusa_con_la_resa` (rosse). Esplorazione: 9 pronunce; nella seconda parte anche nella battaglia nata in campagna.
3. SERIA, avvio in orizzontale a testo massimo — CORRETTA. Prove: `test_osservazioni_3_7_l_avvio_e_raggiungibile_in_ogni_configurazione` (rossa), `test_osservazione_3_avvio_in_orizzontale_a_testo_massimo` (rossa). Esplorazione: 7 elementi su 7.
4. SERIA, il tasto conta i gruppi avversari — CORRETTA (con il tasto intero). Prove: `test_osservazione_4_l_annuncio_del_tasto_conta_i_soli_gruppi_del_giocatore` (rossa: «7 gruppi» con 4), `ChiusuraGiornataTest`.
5. SERIA, comandi sotto il bordo a testo massimo — MAPPA CORRETTA (`test_osservazione_5_la_mappa_e_raggiungibile_in_ogni_configurazione` rossa, `test_osservazione_5_torna_all_inizio_dalla_mappa_a_testo_massimo` rossa); PANNELLO NON UN DIFETTO DELL'APP: VoiceOver ne legge tutte le voci a testo massimo, XCUITest no (sopra).
6. IMPERFEZIONE, fuoco al ritorno — CORRETTA in 01c2439 ed e30f479. Prove: `test_osservazione_6_chiuse_le_impostazioni_il_fuoco_torna_al_pulsante` (rossa), `test_osservazione_6_congedato_il_resoconto_il_fuoco_torna_al_comando_d_origine`. Esplorazioni mirate: 8 su 8.
7. IMPERFEZIONE, «Impostazioni» in orizzontale — CORRETTA nella geometria (prova ospitata rossa, poi verde); la prova d'interfaccia col tocco passava già sul codice della build 28; con VoiceOver NON VERIFICATA, perché in orizzontale il doppio tocco sintetico non attiva nulla (limite del canale).
8. IMPERFEZIONE, verifica automatica — testo tagliato CORRETTO in parte (`test_osservazione_8_nessun_testo_tagliato_sull_avvio_e_sulle_impostazioni`, rossa; esplorazione 86 → 53, i restanti per lo più senza elemento attribuito); carattere dinamico PROPOSTO (sotto); «Potentially inaccessible text» non esaminato elemento per elemento.
9. IMPERFEZIONE, segmenti a 32 punti — CORRETTA, insieme alle leve a 28 punti trovate dalla prova nuova (`test_osservazioni_3_5_9_le_schermate_di_contorno_sono_raggiungibili`, rossa). Esplorazione: segmenti 44–45, leve 44.

## Seconda parte — che cosa è successo

**Device Hub.** Accertato in parte e non esercitato come canale d'ingresso, per convivenza: guidarlo vuol dire portare in primo piano la sua finestra e generare eventi di mouse e tastiera di macOS, mentre l'altro progetto faceva girare prove d'interfaccia macOS con la modalità d'automazione attiva. Dettagli e limiti in `canali-di-automazione.md`.

**Il canale usato: il pilota.** Una prova d'interfaccia resta accesa sul simulatore e legge i comandi da un file del Mac; per ciascuno esegue l'azione e scrive ciò che VoiceOver ha pronunciato prima e dopo (annunci compresi, quando VoiceOver li dice), l'albero e, a richiesta, una schermata. L'ho usato a passi singoli (`scripts/interattivo.py`) per i gesti e per i percorsi sbagliati, e attraverso il tester (`scripts/tester.py`), che gioca le partite decidendo su ciò che sente e vede. Due limiti del canale accertati strada facendo: il servizio VoiceOver delle prove restituisce le pronunce TRONCATE a 64 caratteri (l'informazione di stato perde la sua coda, per esempio la battaglia in sospeso), e su elementi fuori vista o sull'intera applicazione sull'iPad XCUITest non calcola le coordinate di un tocco a più dita e il pilota cade («unable to compute coordinates for gesture»): tre cadute, ciascuna seguita da un riavvio, una sola sull'iPhone con l'intera applicazione.

**I percorsi sbagliati, a passi brevi** (iPad, scontro di prova; iPhone 2, campagna piccola): bersaglio non valido in schieramento e in designazione, annullamento ripetuto, azzeramento, app chiusa e riaperta a metà azione (in battaglia e durante la designazione di una marcia), rotazione a metà azione (in battaglia e durante la designazione), taglia del testo cambiata a partita in corso, VoiceOver spento e riacceso, comando ripetuto, tasto della giornata con gruppi fermi e annullamento subito dopo. Esiti in `sessione-da-tester/confermato.md` e nelle trascrizioni.

**Le partite col tester.** Tre formati in parallelo su tre simulatori, con VoiceOver acceso, a circa nove secondi per attivazione. Campagna PICCOLA (iPhone): 305 attivazioni, giorni di gioco 1–37, poi il limite di 30 giornate del tester; nessun errore del canale, nessun arresto né blocco dell'app; 62 presidi, 37 esplorazioni, 20 soste con raccolta, 6 marce (conteggi dello script sulle pronunce del diario); una battaglia nata in campagna, aperta dal pannello del gruppo, combattuta per 14 turni (un piazzamento, quattro spostamenti, l'avversario che ingaggia) e conclusa con l'annientamento del gruppo del giocatore; resoconto letto per intero; ritorno in campagna con tre gruppi; nessuna conclusione naturale entro il limite. Campagna MEDIA (iPad): 209 attivazioni, giorni 1–24, nessun errore, nessuna battaglia (il tester marcia con un gruppo armato su due e non ha raggiunto il contatto); interrotta da me alle 15:33. Campagna GRANDE (iPhone 2): due tentativi caduti al primo tocco magico, perché la prima casella della mappa grande sta fuori vista e XCUITest non vi calcola il tocco a due dita; non portata avanti, per i tempi: con VoiceOver una campagna grande costa ore. Il tester stesso è stato corretto tre volte durante la sessione (rotore che non resta scelto dopo un ordine, etichette che in designazione cominciano con la disponibilità, battaglia in sospeso non sentita per il troncamento a 64 caratteri, schieramento col rotore che in battaglia non riusciva): le versioni e i diari di ciascun tentativo sono nelle trascrizioni. Il ripiegamento non si è presentato: l'unica battaglia in campagna è finita con l'annientamento, che non lascia nulla da ripiegare.

**Le osservazioni della seconda parte** stanno in `sessione-da-tester/osservazioni.md`, con gravità e passi; non ho corretto nulla.

## Per ciascun gesto: guidato, un livello sotto, scoperto

- Rotore (scelta dell'insieme e salto all'elemento): GUIDATO dal vivo, da tastiera (Control+Opzione+Comando+frecce) e, per la scelta, anche con la rotazione a due dita sintetica; e verificato un livello sotto (le sei ricerche della mappa e le sei della battaglia percorrono il proprio insieme).
- Tocco magico: GUIDATO dal vivo (`tapWithNumberOfTaps:2 numberOfTouches:2`) e verificato un livello sotto (annuncio uguale all'informazione di stato, fuoco fermo).
- Strofinio (uscita): SCOPERTO dal vivo (nessuna API di trascinamento a più dita; Esc e Control+Opzione+Esc non lo producono); verificato un livello sotto per mappa, battaglia e registro; impostazioni, apprendimento e resoconto non lo gestiscono (osservazione 4 della seconda parte).
- Azioni personalizzate: la SCELTA è guidata da tastiera, l'ESECUZIONE è SCOPERTA dal vivo (Control+Opzione+Spazio non attiva; il doppio tocco sintetico riporta il fuoco sull'elemento ed esegue l'azione predefinita); verificata un livello sotto (le direzioni della mappa e le quattro diagonali della battaglia portano il fuoco sulla cella giusta).
- Doppio tocco ovunque: SCOPERTO (il doppio tocco sintetico attiva ciò che sta sotto il dito); coperto in verticale dal doppio tocco sull'elemento, che è guidato.
- Attivazione con VoiceOver in orizzontale: SCOPERTA (il doppio tocco sintetico non attiva nulla in orizzontale, né pulsanti né caselle; in verticale sì).

## Per ciascun percorso, il canale usato

- Gesti e percorsi sbagliati in battaglia (iPad): pilota a passi singoli, VoiceOver acceso; taglia del testo da `simctl ui content_size`.
- Percorsi sbagliati in campagna (iPhone 2): pilota a passi singoli.
- Partite intere e battaglie nate in campagna: tester sul pilota (iPhone: piccola; iPad: media; iPhone 2: grande, interrotta).
- Verifiche un livello sotto: prove ospitate (`GestiUnLivelloSottoTest`), nel collaudo.
- Annunci: nel pilota, dove VoiceOver li pronuncia; nelle prove ospitate, dalla coda del punto dei segnali.

## Proposta al titolare: il carattere dinamico (osservazione 8), non decisa

Cercato nei documenti (00, 01, 02, 03, 05, modalità a campioni, registro, incarichi 08 e 13): nessun punto prescrive che i testi seguano la taglia scelta nelle impostazioni di sistema; 02 §1.3 nomina i giocatori ipovedenti che usano VoiceOver come supporto, senza dire del carattere; l'incarico 08 ha fissato i caratteri delle tessere del deck. Proposta: tutti i testi dell'interfaccia seguono la taglia di sistema — pulsanti, etichette, pannelli, impostazioni, apprendimento, registro, resoconti —, salvo le eccezioni dichiarate delle tessere del deck, delle celle della griglia e delle caselle della mappa, che hanno dimensioni fisse per ragioni di geometria (00 §10.4); il prezzo l'ha già pagato questo incarico (ogni schermata scorre, i titoli vanno a capo). L'alternativa è tenere i caratteri fissi dove oggi lo sono, che lascia a metà l'ingrandimento del sistema per chi vede poco. Oggi l'app è a metà: pulsanti ed etichette con stile di testo seguono la taglia, le altre etichette no.

Da valutare dal titolare anche: il termine chiuso «tuo» resta invariabile davanti a un nome femminile («Il tuo fanteria leggera A è stato ingaggiato»), come vuole 02 §4.5 per i termini del vocabolario chiuso; e la testa molto lunga delle caselle raggiungibili in più giorni durante la designazione di una marcia («raggiungibile in 2 giorni di marcia, il gruppo resterà fermo fino all'arrivo e non potrà sfilarsi senza perdere i giorni spesi, riga 3, casella 3, libera»).

## Le decisioni prese da solo, e perché

- Lo sblocco del turno avversario col tasto dà al gruppo bloccato l'ordine di restare invece di spenderne la giornata, perché l'avversario non perda alcuna azione (RDA-151).
- Il tasto è, per l'annullamento, un gesto del giocatore come un ordine: si annulla intero, col confine di sempre (RDA-151).
- Le campagne della build 28 si rifiutano con lo schema 9 invece di rigiocare il vecchio tasto con la vecchia regola: è la disciplina già seguita per lo schema 8 (RDA-149), e la build 28 era uscita da meno di un giorno.
- Le leve delle impostazioni a 44 punti, trovate dalla prova nuova e non nell'osservazione 9.
- Il ritorno del fuoco spostato a chiusura compiuta, dopo l'esplorazione ripetuta.
- La prova del pannello a testo massimo tolta, perché misura un limite di XCUITest.
- Il cancello delle prove a mano anche sulle note già consegnate, con le loro richieste di prova tolte.
- La campagna grande non portata avanti col tester, per i tempi (sotto).

## Modifiche, per commit

- 610ed7a — `Incarichi/28-…-incarico.md`, `Incarichi/README.md`
- 01c2439 — `Codice/Sources/Motore/ComandiCampagna.swift`, `Codice/Sources/Motore/MotoreCampagna.swift`, `Codice/Sources/Sessione/Giornale.swift`, `Codice/Sources/Sessione/SessioneCampagna.swift`, `Codice/Sources/Verifica/BancoCampagna.swift`, `Codice/Sources/Verifica/InvariantiCampagna.swift`, `Codice/Sources/Contenuti/Testi/it.lproj/Annunci.strings`, `Annunci.stringsdict`, `Codice/Sources/Contenuti/Testi/manifest.json`, `Codice/Sources/Contenuti/Valori/manifest.json`, `Codice/Package.swift`, `Codice/Tests/VerificaTest/ChiusuraGiornataTest.swift`, `Codice/Tests/VerificaTest/InvariantiCampagnaTest.swift`, `Codice/Tests/SessioneTest/SbloccoTurnoAvversarioTest.swift`, `Applicazione/Sorgenti/Impaginazione.swift`, `PartitaCampagna.swift`, `SchermataBattaglia.swift`, `SchermataMappaCampagna.swift`, `SchermateContorno.swift`, `Servizi.swift`, `Applicazione/ProveOspitate/OsservazioniEsplorazioneTest.swift`, `PassaggioBattagliaInterfacciaTest.swift`, `Applicazione/ProveInterfaccia/TaglieEOrientamentiInterfacciaTest.swift`, `ImpiantoInterfacciaTest.swift`, `Applicazione/Esplorazione/EsplorazioneInterfacciaTest.swift`, `Applicazione/project.yml`, `Applicazione/WarSense.xcodeproj/project.pbxproj`, `valori-provvisori.md`, `Incarichi/28-2026-11-21-prodotti/prove-rosse/`, `…/pulizie/`
- 6db79ae — `CLAUDE.md`, `forma-dei-resoconti.md`, `memoria-infrastruttura.md`, `nota-per-il-titolare-chiusura-giornata-e-correzioni.md`, `nota-per-il-titolare-divisione-riunione-rifornimento.md`, `nota-per-il-titolare-partite-fino-alla-fine.md`, `note-di-rilascio.txt`, `scripts/controlla-note.py`
- 9a7408b — `Fondamenta/01-progetto-del-gioco.md`, `02-accessibilita.md`, `03-dati.md`, `05-architettura-tecnica.md`, `modalita-a-campioni.md`, `decisioni-fase-2.md`, `matrice-di-copertura.md`, `registro-decisioni-architetturali.md` (RDA-151–154)
- e30f479 — `Applicazione/Sorgenti/SchermateContorno.swift`, `SchermataRegistro.swift`, `SchermataBattaglia.swift`, `Incarichi/28-2026-11-21-prodotti/esplorazione-ripetuta/`, `…/esplorazione-mirata-fuoco/`, `…/esplorazione-mirata-fuoco-2/`
- 5fda587 — `nota-per-il-titolare-chiusura-giornata-e-correzioni.md`, `note-di-rilascio.txt`
- b073603 — `build-caricate.md` (scritto dallo script), `Incarichi/28-2026-11-21-prodotti/build-29/`
- 8de3905 — `.gitignore`, `Applicazione/Esplorazione/SessioneInterattivaTest.swift`, `Applicazione/ProveOspitate/GestiUnLivelloSottoTest.swift`, `scripts/interattivo.py`, `Applicazione/WarSense.xcodeproj/project.pbxproj`
- 04d7ac3 — `scripts/tester.py`, `Applicazione/Esplorazione/SessioneInterattivaTest.swift`, `Incarichi/28-2026-11-21-prodotti/canali-di-automazione.md`, `…/sessione-da-tester/osservazioni.md`
- b495ea0 — `Incarichi/28-2026-11-21-prodotti/sessione-da-tester/` (trascrizioni, diari, schermate, `confermato.md`)
- aa1e59a — `Incarichi/28-…-resoconto.md`, `Incarichi/README.md`
- f0e64b3 — `scripts/tester.py` (la forma con cui ha giocato le partite)
- la coda di questo resoconto — `Incarichi/28-…-resoconto.md`
- fusioni sul principale: 2fefedb, b8abc93, 257aac2, d6e7887, e quella della coda di questo resoconto

## Ciò che ho fatto senza che fosse chiesto

- La correzione del turno avversario anche fuori dal tasto: un comando respinto della condotta non si applica più (fermava l'app sulla precondizione).
- Gli eventi del turno avversario e della chiusura, che il tasto prima scartava, ora annunciati; il rifiuto del tasto con una battaglia in sospeso; il tasto annullabile come gesto.
- Il banco di campagna che controlla il nuovo invariante dopo ogni ordine e che sa premere il tasto.
- 01 §5.6.0.6 registra il tasto; avvertenze dei documenti di lavoro aggiornate.
- Le leve delle impostazioni a 44 punti; il titolo del registro e l'intestazione del deck che vanno a capo.
- Il ritorno del fuoco corretto una seconda volta dopo l'esplorazione ripetuta, con due esplorazioni mirate.
- Il cancello delle prove a mano, e le richieste di prova tolte dalle note già consegnate.
- Le verifiche un livello sotto entrate nel collaudo (`GestiUnLivelloSottoTest`, 9 prove).
- La correzione del rapporto dell'incarico 27 sugli strumenti contenuti in Xcode.

## Ciò che era chiesto e non ho fatto

- Device Hub non esercitato come canale d'ingresso: avrebbe disturbato le prove macOS dell'altro progetto.
- Con VoiceOver, in orizzontale, nessun comando attivato (limite del canale); la correzione dell'osservazione 7 è verificata solo nella geometria e col tocco senza VoiceOver.
- Il carattere dinamico: proposto, non deciso.
- Le schermate dell'esplorazione ripetuta, perdute con la cartella che lo script di caricamento cancella.
- Partite intere fino alla conclusione naturale: la piccola giocata per 37 giorni senza concludersi, la media per 24, la grande non giocata (sopra); nessun ripiegamento incontrato.
- La sessione da tester non ha percorso con VoiceOver le schermate dopo l'avvio in orizzontale (attivazione non guidabile), né l'apprendimento dei segnali e il registro oltre quanto già nell'esplorazione ripetuta.

## Tempi

Somme fatte a mano dai tempi dei registri (`date +%s` attorno agli script, `xcresulttool`), marcate come tali. Sessione dalle 11:55 alle 15:45 circa del 2026-11-21.
- Compilazione e collaudi completi: 358 + 391 + 315 s (ramo della prima parte), 360 s (ramo della seconda parte), più quello dentro il caricamento: circa 24 minuti più il caricamento (somma a mano).
- Prove rosse sul codice della build 28: 101 s; pacchetto e prove mirate: pochi minuti, non misurati uno per uno.
- Sessioni complete: 647 s.
- Caricamento: 592 s.
- Esplorazione ripetuta: 2307 s; esplorazioni mirate: 208 e 203 s.
- Sessione da tester (sonde dei gesti, percorsi sbagliati e partite col tester): dalle 14:14 alle 15:33, circa 80 minuti (somma a mano), con fino a tre simulatori insieme.
- Device Hub e canali: circa 15 minuti, senza eventi di macOS.

## Integrazione continua all'ultimo invio verificato

Corse sui tre invii al principale della prima parte, tutte VERDI (API pubblica di GitHub Actions): 44905527544 su 2fefedb, 44906411692 su b8abc93, 44907355868 su 257aac2. Le corse su d6e7887 e sull'invio di questa coda partono dopo la chiusura del resoconto: il loro esito non l'ho visto.

