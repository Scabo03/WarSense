# Osservazioni dell'esplorazione con VoiceOver — incarico 27, quarta parte

Build esplorata: il principale con il codice della build 28 (1b543e8 e successivi, che non toccano l'app). Impianto: `Applicazione/Esplorazione/EsplorazioneInterfacciaTest.swift`, `scripts/esplora-interfaccia.sh`, `scripts/sintetizza-esplorazione.py`, `scripts/scegli-schermate-esplorazione.py`. Dieci corse il 2026-11-20/21 su dieci simulatori dedicati, iOS 27.0: iPhone Air e iPad Pro 13", verticale e orizzontale, testo predefinito e testo massimo (`UICTContentSizeCategoryAccessibilityXXXL`). Rilievi grezzi in `rilievi-*.jsonl` (637 righe), sintesi automatica in `sintesi-automatica.md`, schermate in `schermate/`. Qui sotto le sole osservazioni verificate su più di una fonte (giro VoiceOver, albero, schermata); i segnali automatici non verificati restano nella sintesi.

Come si attiva con VoiceOver acceso: tocco sull'elemento (il fuoco vi arriva e si registra la pronuncia), poi doppio tocco sull'elemento stesso. Il doppio tocco «ovunque» dopo gli scorrimenti, il rotore, il tocco magico, lo strofinio e le azioni personalizzate NON si possono guidare (vedi `../canali-di-automazione.md`): nulla di ciò che dipende da quei gesti è stato verificato.

## 1. BLOCCANTE — Battaglia, iPhone, testo massimo: «Fine del turno» non si raggiunge né con VoiceOver né al tatto

- **Schermata:** battaglia (scontro di prova), iPhone Air, verticale, testo massimo.
- **Atteso:** ogni elemento attivabile raggiungibile a scorrimenti e al tatto, a ogni taglia del testo (00 §1.2, §10.1, §10.4; 02 §2.8); i comandi globali chiudono l'ordine di lettura (00 §11.5).
- **Visto e sentito:** il giro VoiceOver si ferma su «Dichiara la resa Pulsante» (108 pronunce; a testo predefinito sono 109 e l'ultima è «Fine del turno»). Il pulsante «Fine del turno» è nell'albero con cornice 16,964 388×76, sotto il bordo dello schermo (912 punti); XCUITest: «Failed to scroll to visible (by AX action) Button … label: 'Fine del turno', error: kAXErrorFailure». Il percorso della prova si è fermato lì.
- **Gravità:** bloccante in quella configurazione: il turno non si chiude.
- **Passi:** iPhone Air, Impostazioni di sistema > Accessibilità > Testo più grande al massimo; WarSense > «Nuovo scontro di prova»; VoiceOver: scorrere a destra fino in fondo; al tatto: cercare «Fine del turno».

## 2. SERIA — Resoconto della battaglia senza esito né perdite

- **Schermata:** resoconto della battaglia, iPhone e iPad, verticale, testo predefinito.
- **Atteso:** il resoconto dichiara esito, durata, perdite proprie e inflitte, unità evacuate, scariche residue, riserve mai schierate (01 §15; testi `resoconto.esito_*`, `resoconto.durata`, `resoconto.perdite_*`, `resoconto.evacuati`, `resoconto.munizioni`, `resoconto.riserve` nel catalogo; 00 §9.1).
- **Visto e sentito:** VoiceOver: «Resoconto della battaglia Intestazione», «Torna all'inizio Pulsante», e nient'altro; l'albero ha gli stessi due elementi; la schermata mostra solo il titolo e il pulsante (`schermate/iphone-verticale-predefinito-ridotta--resoconto-della-battaglia.png`).
- **Gravità:** seria: chi gioca non sa come è finita la battaglia.
- **Passi:** «Nuovo scontro di prova»; selezionare una riserva e chiudere un turno; chiudere l'app e riaprirla; «Riprendi lo scontro in corso»; «Dichiara la resa» quando diventa disponibile (al primo turno risponde «resa non ancora disponibile») e «Fine del turno» finché compare il resoconto. **Non verificato** se il resoconto sia vuoto anche in una battaglia non ripresa: l'impianto vi è arrivato soltanto per questa strada.

## 3. SERIA — Avvio, iPhone in orizzontale con testo massimo: schermata tagliata, due elementi irraggiungibili

- **Schermata:** avvio, iPhone Air, orizzontale, testo massimo.
- **Atteso:** come al punto 1.
- **Visto e sentito:** il giro VoiceOver pronuncia 5 elementi su 7 (manca «WarSense Intestazione» e «Suoni e vibrazioni del gioco»); la schermata non scorre: il titolo sta sopra il bordo, «Nuovo scontro di prova» e «Impostazioni» sono tagliati, «Suoni e vibrazioni del gioco» (cornice 24,452 864×79) sta sotto il bordo inferiore di 420 punti (`schermate/iphone-orizzontale-grande-ridotta--avvio.png`). Il tocco su «Nuovo scontro di prova» ha portato il fuoco su «Dynamic Island, vuota Elemento barra di stato».
- **Gravità:** seria: l'apprendimento dei segnali non si raggiunge; i comandi di gioco sì.
- **Passi:** iPhone, testo massimo, ruotare in orizzontale; aprire WarSense.

## 4. SERIA — Il tasto «Chiudi la giornata» conta anche i gruppi dell'avversario

- **Schermata:** mappa di campagna.
- **Atteso:** l'informazione sull'avversario passa soltanto dagli stati di conoscenza (01 §5.3, §5.6.11); il conteggio dei gruppi da muovere è del giocatore (01 §5.6.9.2).
- **Visto e sentito:** corsa di prova, mappa piccola, giorno 1, nessun gruppo ancora ordinato (il giocatore ne ha 4: «Giorno 1. Nessun gruppo ha ancora agito, sono 4»): l'annuncio è «Giornata chiusa. 7 gruppi non avevano agito: ne è stata conservata traccia…». Almeno 3 dei 7 sono dell'avversario. La sessione dell'incarico 26 aveva già notato che la diagnostica conta entrambe le parti; l'annuncio al giocatore usa lo stesso numero.
- **Gravità:** seria: rivela il numero dei gruppi avversari e confonde («7 gruppi» quando i propri sono 4).
- **Passi:** «Nuova campagna, mappa piccola»; «Chiudi la giornata» subito.

## 5. SERIA — Battaglia e mappa, iPhone, testo massimo: altri comandi sotto il bordo

- **Schermata:** mappa piccola e pannello del gruppo, iPhone, verticale, testo massimo.
- **Visto:** «Torna all'inizio» della mappa fuori dallo schermo; nel pannello del gruppo «Marcia: scegli la casella sulla mappa» fuori dallo schermo (albero, `sullo_schermo` falso). Raggiungibilità a VoiceOver di questi due **non verificata** (la corsa si è interrotta prima del giro VoiceOver dei pannelli).
- **Gravità:** seria.
- **Passi:** come al punto 1, sulla mappa piccola.

## 6. IMPERFEZIONE — Chiusa una schermata, il fuoco non torna da dove si era partiti (iPhone)

- **Schermate:** Impostazioni chiuse; resoconto congedato.
- **Atteso:** «Dopo ogni azione [il fuoco] resta dove l'utente lo ha lasciato» (02 §5.1, 00 §11.1): tornando all'avvio, il fuoco sul pulsante che aveva aperto la schermata.
- **Sentito:** iPhone: dopo «Chiudi il pannello» delle Impostazioni e dopo «Torna all'inizio» del resoconto, il fuoco atterra su «Nuova campagna, mappa media Pulsante»; iPad: su «WarSense Intestazione»; dopo la chiusura dell'apprendimento, su «WarSense Intestazione» in entrambi.
- **Gravità:** imperfezione, con una riserva: l'attivazione dell'impianto è al tatto, e il punto d'atterraggio potrebbe dipendere dal punto toccato; con il doppio tocco dopo gli scorrimenti non è verificabile.
- **Passi:** avvio > «Impostazioni» > «Chiudi il pannello».

## 7. IMPERFEZIONE — iPhone in orizzontale, testo predefinito: «Impostazioni» non si apre con il doppio tocco sull'elemento

- **Visto e sentito:** il fuoco arriva su «Impostazioni Pulsante», il doppio tocco sull'elemento non apre la schermata (il giro successivo ripete l'avvio). Il pulsante sta in parte sotto il bordo inferiore. Da lì il percorso salta Impostazioni, apprendimento e battaglia in quella configurazione. Con il doppio tocco dopo gli scorrimenti non verificabile.
- **Gravità:** imperfezione (il gesto del giocatore non è stato provato).

## 8. IMPERFEZIONE — Verifica automatica di Xcode

`performAccessibilityAudit` su ogni schermata e configurazione (conteggio dello script di sintesi): «Dynamic Type font sizes are unsupported» 457 rilievi su 16 schermate; «Text clipped» 86 su 14 (per esempio i pulsanti dell'avvio); «Potentially inaccessible text» 62 su 13; «Dynamic Type font sizes are partially unsupported» 50, sui pannelli del gruppo. Una parte è voluta (le tessere del deck hanno caratteri fissi per decisione dell'incarico 08); il resto non è stato esaminato elemento per elemento.

## 9. IMPERFEZIONE — Impostazioni: i segmenti dell'intensità alti 32 punti

I tre segmenti «1», «2», «3» dell'intensità delle vibrazioni hanno cornici alte 32 punti (iPhone 124×32, iPad 177×32), sotto il minimo di 44 (00 §10.4).

## Che cosa NON è stato esplorato, e perché

- **Piazzamento e designazione in battaglia:** l'impianto non ha trovato la cella «riga 10, cella 1» con una riserva selezionata (ricerca per etichetta fallita in tutte le configurazioni); non è un difetto accertato dell'app.
- **Passaggio alla battaglia dalla campagna, battaglia di campagna, resoconto di campagna, ripiegamento, ritorno in campagna:** in 30 giornate, marciando ogni giorno con un gruppo armato verso la riga del nemico, nessuna battaglia in sospeso è nata su alcun formato. La prova ospitata delle partite intere li percorre (incarico 26, terza parte), ma senza VoiceOver.
- **Orizzontale (quattro corse):** i percorsi si sono interrotti all'avvio (punti 3 e 7), e le schermate successive non sono state raggiunte; sull'iPad in orizzontale i giri ci sono, con segnali da esaminare nella sintesi.
- **Testo massimo, campagna:** le due corse si sono interrotte (uscita 138 di xcodebuild) durante il percorso della mappa piccola, dopo l'avvio e la battaglia.
- **Mappa media su iPhone:** il primo giro VoiceOver ha restituito «No speech available» (VoiceOver non ancora pronto con dieci simulatori al lavoro); su iPad la stessa mappa si legge in 41 pronunce.
- **Gesti non guidabili:** rotore, tocco magico, strofinio, azioni personalizzate, stile di navigazione per gruppi.
