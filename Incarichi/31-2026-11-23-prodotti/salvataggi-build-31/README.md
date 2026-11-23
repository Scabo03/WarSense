# I salvataggi della build 31 aperti con l'app nuova: la prova dal vivo (incarico 31)

Simulatore «WarSense iPhone Air · 5» (iOS 27.0, 4CD3DC60…), app disinstallata prima di cominciare. Canale: il pilota dell'incarico 28 con VoiceOver acceso; guidatore `migrazione.py`, preparazione `prepara.sh` (questa cartella). Il codice sotto prova è il commit `bb66d20` del ramo `incarico-31`, esportato con `git archive` in una cartella di lavoro esclusa da git (`Applicazione/build-interattivo/migrazione-31/candidata/`), perché la corsa non dipendesse dai file che altre parti della sessione stavano modificando; accanto, il codice della build 31 (`7ef91fd`) esportato allo stesso modo. Compilazione di ciascuno: 15 s (stampato da `prepara.sh`, `date +%s`).

1. **Prima.** L'app e il pilota compilati dal commit della build 31. Un regno portato al primo inverno con una leva di fanteria leggera ordinata; una campagna piccola con un ordine dato e due giornate chiuse («Giorno 3»); uno scontro di prova con una riserva piazzata. Di ciascuno si registra ciò che la schermata espone (`stato-con-la-build-31.json`: l'albero della patria, 16 caselle, 100 celle, l'informazione di stato), e del giornale del regno, letto nel contenitore dei dati dell'app con `xcrun simctl get_app_container`, lunghezza e impronta: 1306 byte, 3 righe, `versione_schema` 1, SHA-256 a2abb2ed…7a116. App chiusa con le tre partite in corso.
2. **Dopo.** Il pilota compilato dal codice sotto prova installa l'app nuova sopra la vecchia; i dati restano.
   - L'avvio offre «Riprendi il regno», «Nuovo regno», «Riprendi lo scontro in corso», «Riprendi la campagna in corso».
   - «Riprendi il regno»: VoiceOver dice «Il regno salvato è di un formato precedente e non può essere ape…» (il servizio tronca le pronunce a 64 caratteri; la frase intera è `regno.slot_schema_incompatibile`); si resta all'avvio; il giornale del regno nel contenitore è byte per byte quello di prima (stessa lunghezza, stessa impronta).
   - La campagna ripresa espone le stesse 16 caselle e la stessa informazione di stato («Giorno 3. Nessun gruppo ha ancora agito, sono 4»); chiusa la giornata comincia il giorno 4.
   - Lo scontro ripreso espone le stesse 100 celle.
   - Chiusa e riaperta l'app, «Nuovo regno» apre la patria, con «Corvo, gruppo armato: 6 atomi di fanteria leggera. Parte per il fronte»; il giornale del regno è ora di schema 2 (1415 byte, una riga).

Esiti: `controlli.jsonl` (15 controlli, 15 «ok»: 5 prima, 10 dopo), `prima.log`, `dopo.log`; i passi del pilota in `pilota-build-31/` e `pilota-app-nuova/`; quattro schermate. Durate stampate dal guidatore: 171 s e 120 s.

**La prima corsa** (`prima-corsa/`): 5 su 5 prima, 8 su 10 dopo. I due controlli falliti erano gli ultimi due, sul regno nuovo, e fallivano per un errore del guidatore: dopo lo scontro cercava «Torna all'inizio» sulla schermata di battaglia, dove quel comando non c'è, e «Nuovo regno» non veniva mai attivato. Corretto il guidatore (chiude e riapre l'app), la prova è stata rifatta per intero da un'installazione pulita: è la corsa riportata qui sopra.

**Perché il regno non si riapre.** Lo schema del giornale del regno è passato da 1 a 2 (RDA-181): le forze conservano le formazioni col loro nome, il mantenimento si preleva all'inizio dell'inverno, i lavori hanno durate. Un regno della build 31, rigiocato con queste regole, sarebbe un altro regno. Il gioco lo dichiara e lo lascia com'era; «Nuovo regno» ne comincia uno.

**Il difetto trovato preparando questa prova.** Prima della correzione di `bb66d20` il giornale di schema 1, che non si decodifica più nella forma di oggi, era preso per un file corrotto: `Giornale.apri` lo troncava a zero byte, la ripresa falliva con `fondazioneMancante`, che l'avvio non sa dichiarare, e «Riprendi il regno» non faceva nulla, in silenzio. Ora lo schema si legge dall'intestazione prima di aprire (`Giornale.schemaDelRegno`). La prova che lo fissa, vista fallire senza la protezione: `../cancelli-visti-fallire/regno-della-build-31-senza-la-lettura-dello-schema.txt`.

Non verificato: un salvataggio di build più vecchie della 31; un'installazione vera da TestFlight su un apparecchio.
