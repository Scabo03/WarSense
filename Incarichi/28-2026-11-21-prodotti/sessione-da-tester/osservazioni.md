# Osservazioni della sessione da tester — incarico 28, seconda parte

Build osservata: il codice della build 29 (principale b8abc93 e successivi, che non toccano l'app). Simulatori dedicati «WarSense iPhone Air» e «WarSense iPad Pro 13», iOS 27.0, il 2026-11-21. Canale: il pilota (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`) guidato a passi brevi da `scripts/interattivo.py` (passi singoli) e da `scripts/tester.py` (il tester che gioca le partite), con VoiceOver acceso; i canali sono descritti in `../canali-di-automazione.md`. Trascrizioni: `esiti-*.jsonl` (ogni passo, con ciò che VoiceOver ha detto) e `diario-*.jsonl` (le decisioni del tester). Qui le osservazioni verificate; in questa parte nulla è stato corretto.

## 1. SERIA — Con una battaglia in sospeso, il pannello di un gruppo non coinvolto non dice perché non offre azioni

- **Dove:** mappa di campagna, pannello di un gruppo mentre c'è una battaglia in sospeso altrove.
- **Atteso:** «Ogni comando bloccato dichiara il medesimo motivo, cioè la battaglia in sospeso, così che il giocatore non debba ricostruirlo per tentativi» (02 §6.5).
- **Visto e sentito:** iPhone, campagna piccola, giorno 9, battaglia in sospeso nella casella di Corvo (riga 1, casella 2). Il pannello di Orso e quello di Falco contengono il solo titolo («Azioni per Orso in riga 4, casella 1») e «Chiudi il pannello»: nessun messaggio, nessun motivo (albero del passo 365 e precedenti, `esiti-iphone.jsonl`). Nel codice: `SchermataMappaCampagna.apriPannello(per:)` crea l'avviso con `message: nil` e, con una battaglia in sospeso, non aggiunge le azioni bloccate («Le altre azioni, bloccate, non compaiono»). Il tester automatico vi è rimasto fermo per tre giornate di tentativi, che è esattamente il ricostruire per tentativi che 02 §6.5 vuole evitare.
- **Passi:** campagna piccola; marciare con un gruppo armato fino a un contatto che apre una battaglia in sospeso; non aprirla; attivare la casella di un altro gruppo.

## 2. IMPERFEZIONE — «Hanno agito 1 gruppi su 4»

- **Dove:** informazione di stato della campagna (tocco magico), iPhone e iPad.
- **Visto e sentito:** «Giorno 3. Hanno agito 1 gruppi su 4», più volte (`diario-piccola.jsonl`). Con un solo gruppo il verbo e il nome restano al plurale; «Nessun gruppo ha ancora agito, sono 4» e «2 in marcia lunga su 4» invece concordano.
- **Passi:** campagna piccola; dare un ordine a un solo gruppo; tocco magico.

## 3. IMPERFEZIONE, INTERMITTENTE — All'apertura dello scontro sull'iPad il fuoco atterra a volte sulla prima cella invece che sull'intestazione del deck

- **Atteso:** aperta la battaglia, il fuoco sull'intestazione «Riserve da schierare» (02 §2.9–2.10).
- **Visto e sentito:** iPad, verticale, testo predefinito: due aperture su tre (scontro nuovo, scontro ripreso) atterrano su «riga 1, cella 1, libera» (un passo avanti dà «riga 1, cella 2»); la terza, dopo una chiusura e riapertura dell'app, su «Riserve da schierare Intestazione». Nelle esplorazioni automatiche, che leggono l'atterraggio 0,8 s dopo l'apertura, otto aperture su otto atterrano sull'intestazione. Il pilota ascolta per 4–7 s: è possibile che il fuoco arrivi sull'intestazione e ne sia tolto dopo l'annuncio d'apertura; non accertato.
- **Passi:** iPad; «Nuovo scontro di prova»; ascoltare per alcuni secondi dove sta il fuoco.

## 4. IMPERFEZIONE — Il gesto di uscita non chiude le impostazioni, l'apprendimento e il resoconto

- **Atteso:** il gesto di fuga risale di un livello (02 §6.7); un pannello si chiude col gesto, come il registro e la divisione.
- **Verificato un livello sotto, letto nel codice:** `SchermataImpostazioni`, `SchermataApprendimento` e `SchermataResoconto` non ridefiniscono `accessibilityPerformEscape`, quindi il gesto non le chiude; il giocatore deve trovare «Chiudi il pannello» o «Torna all'inizio». Il gesto dal vivo non si guida (`../canali-di-automazione.md`).

## 5. IMPERFEZIONE, DA ACCERTARE DAL VIVO — Tolta la scelta di una tessera, VoiceOver la dice ancora «selezionato»

- **Visto e sentito:** iPad, battaglia, tessera «tiratori» scelta; doppio tocco sulla tessera per toglierla: VoiceOver dice «è selezionato tiratori 5 atomi, volume 50, 1 esemplare, selezion…». La scelta però è tolta: subito dopo il pannello del reparto si apre invece del rifiuto «occupata».
- **Letto nel codice, dopo la ripresa:** la causa è probabilmente l'ordine dei fatti nell'app. `TesseraDeck.accessibilityActivate` invia l'azione e restituisce subito; i tratti della tessera (`.selected`) si aggiornano soltanto per la via asincrona: comando alla sessione, poi `SchermataBattaglia.ricevi` → `Task` → `ricaricaStato` → `aggiorna(con:)` → `TesseraDeck.aggiorna`. VoiceOver, che rilegge l'elemento subito dopo l'attivazione, può trovarvi ancora lo stato di prima. Ipotesi coerente con ciò che si è sentito, non accertata dal vivo: il servizio VoiceOver delle prove non dice quando ha letto i tratti.

## 6. MINORE — L'azzeramento senza nulla da azzerare conferma lo stesso

- iPad, battaglia: dopo due annullamenti che hanno tolto piazzamento e scelta, «Azzera lo schieramento del turno» annuncia «Schieramento del turno azzerato» invece di dire che non c'era nulla da azzerare.

## Che cosa NON è stato percorso con VoiceOver, e perché

- **Orizzontale, oltre la lettura:** in orizzontale il doppio tocco non attiva nulla, né con XCUITest né con Device Hub. Safari si comporta allo stesso modo, quindi il limite è del simulatore e non di WarSense (`../device-hub/trascrizione.md`, passi 8–9 e 22–23). La schermata l'ho letta, i comandi non li ho attivati.
- **Gesto di uscita ed esecuzione delle azioni personalizzate:** non guidabili dal vivo con nessuno dei due canali; verificati un livello sotto (`GestiUnLivelloSottoTest`), salvo il punto 4. **Doppio tocco ovunque:** non guidabile, e Safari fa lo stesso (passi 4–6 e 24–25).
