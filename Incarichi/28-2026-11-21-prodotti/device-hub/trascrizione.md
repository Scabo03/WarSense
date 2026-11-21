# Device Hub come canale: trascrizione (incarico 28, seconda parte)

Eseguita il 2026-11-21 dalle 16:44 alle 17:00, dopo la ripresa della sessione. Prima di cominciare: nessun corridore di prove d'interfaccia macOS di altri progetti in esecuzione (`pgrep -fl "xctest|ScaboMacUITests"` vuoto; restava soltanto il processo `AutomationModeUI`); il controllo è stato ripetuto prima di ogni gruppo di azioni.

- Device Hub 27.2 (com.apple.dt.Devices, in Xcode 27.2), aperto con `open -b com.apple.dt.Devices`. All'apertura la finestra mostrava «iPad Pro 11-inch (M5) – iPadOS 27.0», un apparecchio che non è di WarSense, spento: non l'ho toccato né avviato. Ho scelto «WarSense iPhone Air» nella barra laterale con l'accesso d'assistenza (`AXSelectedRows`).
- Apparecchio: WarSense iPhone Air (C86CB490…), iOS 27.0. L'app l'ha avviata il pilota (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`), che ha anche acceso VoiceOver. Per ascoltare, il pilota eseguiva `attendi` con `ascolto` da 3 a 8 s, lanciato 1,2 s prima di ogni azione di Device Hub. Le righe del pilota stanno in `esiti-pilota-in-ascolto.jsonl`.
- Strumento: `scripts/devicehub.swift` (accesso d'assistenza ed eventi di sistema). I suoi cancelli: Device Hub in primo piano, la sua finestra sopra tutte nel punto, una finestra che mostra un apparecchio di WarSense. L'ultimo l'ho visto rifiutare una volta di proposito: `cancello-finestra-warsense.txt`, uscita 2.
- Alla fine ho rimesso tutto com'era: «Capture Keyboard» spento, la barra laterale di nuovo su «iPad Pro 11-inch (M5)», Device Hub chiuso (prima di me non era aperto).

## Lettura

Device Hub espone l'albero d'accessibilità dell'apparecchio all'accesso d'assistenza di macOS, in un `AXGroup` con sottoruolo `iOSContentGroup`. Ogni elemento ha il ruolo (AXHeading, AXButton, AXGenericElement per le caselle, AXCheckBox AXSwitch per le leve, AXTabGroup per i segmenti), l'etichetta e la cornice in punti dello schermo del Mac. In verticale lo schermo dell'iPhone, 420 × 912 punti, occupa 272 × 590 punti del Mac.

Le etichette arrivano INTERE, senza il taglio a 64 caratteri del servizio VoiceOver delle prove. Per esempio: «riga 1, casella 3, tuo Lupo, in attesa, in sosta di rifornimento, formazione di ricognizione avversaria, composta da 18 atomi di fanteria leggera, 8 atomi di fanteria pesante».

In orizzontale le cornici sono sbagliate, con larghezza e altezza scambiate. Il gruppo vale 398,221 794 × 365, ma l'intestazione «WarSense» risulta a 412,−126 con misure 35 × 633. In orizzontale le posizioni le ho quindi ricavate dall'albero del pilota e dalla schermata del simulatore.

## Ingresso: eventi al solo processo di Device Hub

Clic e doppio clic su «Impostazioni» inviati al solo processo (`postToPid`): nessun effetto, VoiceOver resta su «WarSense Intestazione». Questa via è scartata.

## Ingresso: eventi di sistema, con Device Hub in primo piano

Il puntatore torna dov'era dopo ogni azione. «Clic» vale un tocco a un dito, «doppio clic» un doppio tocco, «trascinamento rapido» (5 passi, circa 80 ms) un colpetto.

| n. | dove | azione in Device Hub | VoiceOver (pilota) | esito |
|---|---|---|---|---|
| 1 | avvio, verticale | clic su «Impostazioni» | «Impostazioni Pulsante» | il fuoco va sull'elemento sotto il dito |
| 2 | avvio, verticale | doppio clic su «Impostazioni» | «Impostazioni Intestazione» | ATTIVATO: si aprono le impostazioni |
| 3 | impostazioni | clic su «Chiudi il pannello» | «Chiudi il pannello Pulsante» | fuoco |
| 4 | impostazioni | doppio clic sull'intestazione, col fuoco su «Chiudi il pannello» | nulla di nuovo | nessuna attivazione, il fuoco resta |
| 5 | impostazioni | doppio clic in un punto vuoto sotto «Chiudi il pannello» | nulla | nessuna attivazione |
| 6 | impostazioni | di nuovo come al passo 4 | nulla | uguale |
| 7 | impostazioni | doppio clic SU «Chiudi il pannello» | «Impostazioni Pulsante» | le impostazioni si chiudono e il fuoco torna sul pulsante che le aveva aperte |
| 8 | avvio, ORIZZONTALE (rotazione dal pilota) | clic su «Riprendi la campagna in corso» | «Riprendi la campagna in corso Pulsante» | fuoco |
| 9 | avvio, orizzontale | doppio clic sullo stesso pulsante | nulla | NESSUNA attivazione (schermata `devicehub-orizzontale-dopo-doppio-clic.png`) |
| 10 | avvio, verticale | clic, poi doppio clic su «Riprendi la campagna in corso» | «Mappa Guado, 4 righe per 4 caselle…», «Giorno 38. Nessun gruppo ha ancora agito, sono 3, 1 senza riforn…» | si apre la mappa |
| 11 | mappa | clic sulla casella di Lupo | «riga 1, casella 3, tuo Lupo, in attesa, in sosta di rifornimento» | fuoco |
| 12 | mappa | Opzione + doppio clic | nulla | nessun tocco magico |
| 13 | mappa | Opzione + clic | nulla | nessun effetto, nemmeno sul fuoco |
| 14–16 | mappa | «Capture Keyboard» acceso; Control+Opzione+freccia destra due volte; Control+Opzione+Spazio | nulla | nessun effetto |
| 17–19 | mappa | un clic dentro l'apparecchio, poi Control+Opzione+freccia destra; freccia destra sola; tabulatore | nulla | nessun effetto; «Capture Keyboard» rispento |
| 20 | Safari, verticale (controllo) | clic su «Personalizza pagina di apertura» | «Personalizza pagina di apertura Pulsante» | fuoco |
| 21 | Safari, verticale | doppio clic sullo stesso pulsante | «Personalizza pagina di apertura Intestazione» | ATTIVATO: si apre il foglio (chiuso poi con clic e doppio clic su «chiudi») |
| 22 | Safari, ORIZZONTALE | clic su «Pannelli» | «Pannelli Pulsante» | fuoco: il cursore di VoiceOver si vede attorno al pulsante (`safari-orizzontale-dopo-il-doppio-clic.png`) |
| 23 | Safari, orizzontale | doppio clic su «Pannelli» | nulla | NESSUNA attivazione: la pagina resta uguale |
| 24 | Safari, verticale | clic su «Pannelli» | «Pannelli Pulsante» | fuoco |
| 25 | Safari, verticale | doppio clic in un punto vuoto | nulla | NESSUNA attivazione (`safari-verticale-doppio-clic-in-un-punto-vuoto.png`) |
| 26 | mappa (app riattivata dal pilota) | clic su Lupo | «riga 1, casella 3, tuo Lupo…» | fuoco |
| 27 | mappa | trascinamento rapido verso destra | «riga 1, casella 4, formazione non armata avversaria, bosco…» | ELEMENTO SUCCESSIVO: il colpetto funziona |
| 28 | mappa | trascinamento rapido verso il basso | «Vai a sud» | scelta dell'azione personalizzata |
| 29 | mappa | doppio clic sulla casella col fuoco | nulla di nuovo | l'azione scelta NON viene eseguita: il fuoco non scende |
| 30 | mappa | trascinamento rapido verso sinistra | «riga 1, casella 3, tuo Lupo…» | ELEMENTO PRECEDENTE (il fuoco era rimasto sulla casella 4) |
| 31 | mappa | clic, poi doppio clic su Lupo | «Azioni per Lupo in riga 1, casella 3» | si apre il pannello. Dall'albero di Device Hub: «Presidia: resta fermo in guardia», «Sosta con raccolta: resta fermo e raccogli provviste», «Mettiti in agguato», «Chiudi il pannello» |
| 32 | pannello | clic, poi doppio clic su «Chiudi il pannello» | «Chiudi il pannello Pulsante», «riga 1, casella 3, tuo Lupo…» | il pannello si chiude e il fuoco torna sulla casella di Lupo (`devicehub-mappa-dopo-pannello.png`) |

## Che cosa se ne ricava

- **Device Hub è un canale di lettura e un canale d'ingresso per i gesti a un dito.** Con VoiceOver funzionano il tocco (fuoco sotto il dito), il doppio tocco sull'elemento in verticale (attivazione) e i colpetti (elemento successivo e precedente, scelta dell'azione personalizzata). Il colpetto, che con XCUITest arrivava come esplorazione al tatto, qui funziona.
- **Non si guidano con Device Hub:**
  - i gesti a due dita: Opzione non ha effetto, quindi niente tocco magico, uscita o rotazione del rotore;
  - i comandi da tastiera di VoiceOver: nessun effetto, nemmeno con «Capture Keyboard»;
  - l'esecuzione di un'azione personalizzata scelta;
  - il doppio tocco ovunque;
  - l'attivazione in orizzontale.
- **Le ultime due non sono difetti di WarSense.** Safari, app di sistema usata come controllo, si comporta allo stesso modo: in orizzontale il doppio tocco sull'elemento col fuoco non attiva, e in verticale il doppio tocco in un punto vuoto non attiva l'elemento col fuoco. Su un apparecchio vero VoiceOver attiva l'elemento col fuoco ovunque si faccia il doppio tocco: è il simulatore, con questi due canali, a non produrlo. È coerente con le cornici sbagliate che Device Hub legge in orizzontale.
- **Casella di Lupo condivisa con una formazione avversaria, senza battaglia:** è previsto da 01 §6.1 («La compresenza di due gruppi armati contrapposti nella stessa casella non obbliga a combattere»). Non è un difetto.
