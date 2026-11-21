# Canali per guidare e osservare l'app sul simulatore — aggiornamento (incarico 28)

Aggiorna e corregge `Incarichi/27-2026-11-20-prodotti/canali-di-automazione.md`. Macchina: macOS 27.0.1, Xcode 27.2 (27B52), simulatori dedicati «WarSense iPhone Air» (C86CB490…) e «WarSense iPad Pro 13» (D01FE19F…), iOS 27.0. Ogni esito qui sotto viene da una prova eseguita il 2026-11-21 col pilota della sessione da tester (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`, lato Mac `scripts/interattivo.py`); le trascrizioni stanno in `sessione-da-tester/`.

## 0. Correzione del rapporto dell'incarico 27

Il rapporto dell'incarico 27 diceva che Xcode 27.2 non contiene alcun pacchetto `.app`, «nemmeno Accessibility Inspector o Instruments». È falso: `find /Applications/Xcode.app/Contents -maxdepth 4 -name "*.app"` trova in `Contents/Applications/` DeviceHub.app (com.apple.dt.Devices 27.2, build 255.31.3), Accessibility Inspector.app (com.apple.AccessibilityInspector 5.0), Instruments.app, FileMerge.app, Create ML.app e Icon Composer.app, creati fra il 20 e il 23 ottobre 2026, cioè prima di quella sessione (`stat`). È vero che l'applicazione Simulator non c'è più: la sostituisce Device Hub.

## 1. Device Hub — accertato in parte, NON esercitato come canale d'ingresso, per convivenza

- Esiste e si avvia (`open -g -b com.apple.dt.Devices`, senza portarlo in primo piano). Lo schema d'indirizzo dichiarato è `devices:`.
- Dalle sue stringhe: una vista dal vivo degli apparecchi; l'impostazione «Simulate hardware keyboard by default»; l'impostazione «Send keyboard shortcuts to device», che manda quasi tutte le scorciatoie da tastiera all'apparecchio con il fuoco invece che al Mac (è ciò che servirebbe ai comandi da tastiera di VoiceOver); l'«inserimento sicuro» («Prevent apps on your Mac from accessing keyboard input to devices. This may affect accessibility tools»); l'interazione sospesa quando lo schermo del Mac è bloccato. Per nota del titolare non consente i gesti a due dita.
- Avviato in secondo piano non apre finestre, e il suo menu non è leggibile con l'accesso d'assistenza finché non è attivo (`System Events`: «Indice non valido» su `menu bar 1`).
- Guidarlo vuol dire generare eventi di mouse e di tastiera di macOS dentro la sua finestra portata in primo piano (`System Events` o eventi di sistema). Durante tutta la sessione sulla macchina girava un altro progetto con prove d'interfaccia macOS (`ScaboMacUITests-Runner`, `ScaboMac`, `xctest`, e `AutomationModeUI`, cioè la modalità d'automazione di macOS attiva): portare in primo piano una finestra o inviare battute di tasti avrebbe potuto finire nell'applicazione dell'altro progetto. Non l'ho fatto. Il canale resta quindi non esercitato.
- Che cosa aggiungerebbe: la vista dal vivo e il tocco a un dito col mouse. I comandi da tastiera di VoiceOver che Device Hub inoltrerebbe all'apparecchio sono gli stessi che il pilota invia già con `typeKey` (sezione 3), con gli stessi esiti attesi; i gesti a due dita non li dà.

## 2. Il pilota della sessione da tester — FUNZIONA, ed è il canale usato

Una prova d'interfaccia resta accesa sul simulatore e legge i comandi da un file del Mac (il corridore delle prove nel simulatore legge e scrive nella cartella del progetto); per ciascuno esegue l'azione e scrive l'esito: ciò che VoiceOver pronunciava prima, le pronunce distinte nei secondi dopo (dove compaiono anche gli ANNUNCI, quando VoiceOver li dice), l'albero essenziale, una schermata. Un passo costa da 0,3 a 6 secondi. Gli annunci si sentono: per esempio «Mappa Guado, 4 righe per 4 caselle…», «Piazzato: costa 50, restano 310», «Turno 1, agisce l'avversario», «Giornata conclusa: comincia il giorno 2».

## 3. I gesti di VoiceOver, uno per uno

| gesto | vie provate | esito |
|---|---|---|
| Passo avanti e indietro (colpetto a un dito) | servizio `moveForward`/`moveBackward`; tastiera Control+Opzione+freccia destra e sinistra; scorrimento sintetico `swipeRight` | GUIDATO: servizio e tastiera muovono il fuoco nell'ordine di lettura. Lo scorrimento sintetico arriva come esplorazione al tatto (porta il fuoco sotto il dito), non come colpetto. |
| Rotore: scelta dell'insieme | rotazione a due dita sintetica (`rotate:withVelocity:`); tastiera Control+Opzione+Comando+freccia destra e sinistra | GUIDATO in tutte e due le vie: VoiceOver pronuncia il nome del rotore («Gruppi da muovere», «Celle valide»…). La rotazione in verso negativo non ha cambiato insieme. |
| Rotore: salto all'elemento | scorrimento sintetico in su e in giù; tastiera Control+Opzione+Comando+freccia su e giù | GUIDATO da tastiera: «Gruppi da muovere» salta da Corvo a Lupo a Falco. Lo scorrimento sintetico no (esplorazione al tatto). |
| Tocco magico (doppio tocco a due dita) | `tapWithNumberOfTaps:2 numberOfTouches:2` | GUIDATO: sulla mappa VoiceOver pronuncia l'informazione di stato («Giorno 1. Nessun gruppo ha ancora agito, sono 4»). Verificato anche un livello sotto (`GestiUnLivelloSottoTest`). |
| Attivazione (doppio tocco) sull'elemento, in verticale | tocco poi doppio tocco sintetico sull'elemento | GUIDATO: il primo tocco porta il fuoco, il doppio tocco attiva (pannelli, pulsanti, caselle, celle, tessere). |
| Attivazione in ORIZZONTALE | doppio tocco sull'elemento; `tapWithNumberOfTaps:2 numberOfTouches:1` sull'elemento | NON GUIDATO: il tocco porta il fuoco, il doppio tocco non attiva nulla, né i pulsanti né le caselle che gestiscono da sé l'attivazione d'accessibilità; tornati in verticale lo stesso comando attiva. È un limite del canale, non un difetto osservato dell'app (senza VoiceOver il tocco in orizzontale attiva: `TaglieEOrientamentiInterfacciaTest.test_osservazione_7_…`). |
| Doppio tocco «ovunque» con il fuoco portato altrove | doppio tocco su un punto neutro; `tapWithNumberOfTaps:2 numberOfTouches:1` sull'applicazione | NON GUIDATO: il doppio tocco sintetico è letto come esplorazione al tatto e attiva l'elemento sotto il dito (si è aperta la mappa piccola, che stava al centro, con il fuoco su «Impostazioni»). |
| Attivazione da tastiera | Control+Opzione+Spazio; Control+Opzione+Invio; Invio | NON GUIDATO: nessuna delle tre attiva (avvio e caselle della mappa). |
| Azioni personalizzate | rotore «Azioni» da tastiera e Control+Opzione+Comando+giù; poi doppio tocco sull'elemento | SCELTA GUIDATA, ESECUZIONE NO: la tastiera scorre le azioni («Vai a nord», «Attiva»), ma il doppio tocco sintetico, il cui primo tocco riporta il fuoco sull'elemento, esegue l'azione predefinita (si è aperto il pannello). Verificate un livello sotto. |
| Uscita (strofinio a due dita) | nessuna API di trascinamento a più dita; tasto Esc; Control+Opzione+Esc | NON GUIDATO: il pannello aperto resta aperto. Verificata un livello sotto (mappa, battaglia, registro). |
| Pausa della voce (tocco a due dita) | `twoFingerTap` | non provato: non serve ad alcun percorso del gioco. |

## 4. Gli altri canali, ripresi dall'incarico 27 e verificati di nuovo

- Taglia del testo a partita in corso: `xcrun simctl ui <udid> content_size accessibility-extra-extra-extra-large` dal Mac, mentre il pilota gira: l'app si ridispone dal vivo (iPad, battaglia: 109 pronunce fino a «Fine del turno» anche a testo massimo).
- Orientamento a metà azione: `XCUIDevice.orientation` dal pilota; VoiceOver annuncia la rotazione («Porta a destra», «verticale»): era questo il «Porta a destra» registrato nell'esplorazione dell'incarico 27 e in quella ripetuta, non un elemento dell'app.
- Chiusura e riapertura dell'app a metà azione: `terminate` e `launch` dal pilota.
- VoiceOver acceso e spento a partita in corso: `enable`/`disable` dal pilota; riacceso, VoiceOver riparte dal primo elemento della schermata.
- Prove d'interfaccia con XCUITest in un avviso dell'app a testo massimo: XCUITest scambia l'avviso per un'interruzione esterna e non tocca le sue voci; il suo gestore delle interruzioni gira senza fine e xcodebuild esce con 138 (le due corse a testo massimo dell'esplorazione, nell'incarico 27 e nella ripetizione; `esplorazione-ripetuta/pannello-a-testo-massimo-xcuitest.txt`). VoiceOver invece legge e raggiunge tutte le voci del pannello.
- Sull'iPad, durante la scelta del rotore da tastiera, VoiceOver ha detto «Tastiera nascosta», «Tastiera visibile» e i tasti successivi non hanno più cambiato rotore; la schermata non mostrava alcuna tastiera. Non accertato che cosa sia stato attivato.

## 5. Conseguenza per la sessione da tester

Si guidano dal vivo, con VoiceOver acceso: lettura nell'ordine, rotori (scelta e salto), tocco magico, attivazione sull'elemento in verticale, rotazione, taglia del testo, chiusura e ripresa, VoiceOver acceso e spento. Restano scoperti dal vivo, e verificati soltanto un livello sotto: l'uscita, l'esecuzione delle azioni personalizzate, il doppio tocco ovunque; resta scoperta l'attivazione con VoiceOver in orizzontale, che un livello sotto non ha un equivalente (è il gesto stesso).
