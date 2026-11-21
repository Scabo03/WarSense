# Osservazione 3 — il fuoco all'apertura della battaglia sull'iPad: l'indagine

Simulatore «WarSense iPad Pro 13» (D01FE19F…), iOS 27.0, verticale, testo predefinito, VoiceOver acceso, 2026-11-21 fra le 18:55 e le 19:33. Canale: il pilota dell'incarico 28 (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`) guidato da `prove_apertura.py` e `prove_come_28.py` (in questa cartella). App: una COPIA DI DIAGNOSI del codice di fa25bb1 in `Applicazione/build/diagnosi-29` (prodotti di compilazione, ignorati, mai committata), con le aggiunte di `copia-di-diagnosi.diff`: `DiagnosiFuoco` registra con l'orario ogni `UIAccessibility.elementFocusedNotification` (dove VoiceOver mette il fuoco), ogni `Fuoco.sposta` e i momenti della presentazione; un argomento di lancio (`-diagnosiModo`) sceglie il momento della notifica d'apertura del gioco. Ogni riga dei file `prove-apertura.jsonl` è un'apertura: ciò che VoiceOver ha detto nell'ordine (`ascoltate`, campioni ogni 0,25 s per 8 s) e dove è rimasto (`dopo`). I file `diagnosi-*.jsonl` sono i registri dell'app, con l'ora in secondi.

## Che cosa si è visto

| serie | condizione | aperture | atterraggio sull'intestazione | sulla prima cella |
|---|---|---|---|---|
| 1 | codice com'è, app riavviata ogni volta, pausa 1,5 s | 9 | 9 | 0 |
| 2 | codice com'è, macchina carica (`swift test --parallel` due volte), senza pausa | 10 | 10 | 0 |
| 3 | nessuna notifica del gioco (`nessuno`) | 4 | 0 | 4 |
| 4 | notifica alla comparsa, prima della fine della presentazione (`anticipato`) | 4 | 4 | 0 |
| 5 | notifica 0,5 s dopo la comparsa (`ritardato`) | 4 | 4 | 0 |
| 6 | codice com'è, sequenza dell'incarico 28 (VoiceOver spento e riacceso, dati azzerati, nessuna pausa) | 6 | 6 | 0 |
| 7 | notifica dopo un caricamento rallentato di 300 / 700 / 800 / 900 / 1500 ms (`lentoNNN`) | 15 | 14 alla fine (in 9 dopo essere passato dalla prima cella) | 1 (700 ms, prova 22) |
| 8 | CORRETTO: notifica alla comparsa; caricamento rallentato di 700 / 760 / 780 / 1500 ms, e nessun ritardo | 20 | 20, mai passando dalla prima cella | 0 |

Conteggi fatti a mano dalle righe di `prove-apertura.jsonl` e dall'uscita delle prove riportata nel resoconto.

## La causa

1. Senza la notifica del gioco VoiceOver mette da sé il fuoco sul primo elemento dell'ordine di lettura, «riga 1, cella 1, libera», circa 800 ms dopo la presentazione (serie 3: 805–808 ms). È esattamente l'atterraggio sbagliato dell'incarico 28.
2. VoiceOver applica ogni notifica di cambio schermata circa 770 ms dopo averla ricevuta: alla presentazione ne riceve due, quella automatica del sistema e quella del gioco (`Fuoco.sposta(a: intestazioneDeck, perche: .schermataAperta)`), che il codice emetteva alla fine di `avvia()`, cioè DOPO il caricamento asincrono dello stato (`await partita.stato`, `await partita.eventiIniziali`). Di norma ci arriva in 20–35 ms e VoiceOver le fonde in un solo spostamento, sull'intestazione.
3. Se il caricamento dura di più — macchina carica, come nella sessione da tester dell'incarico 28 con tre simulatori e tre piloti insieme —, la notifica del gioco può cadere nella finestra in cui VoiceOver sta per applicare quella del sistema. Prova 22 (`lento700`, registro `diagnosi-fuoco-ipad-3/diagnosi-lento.jsonl`): notifica del gioco a 771 ms; a 784 ms VoiceOver applica lo spostamento del sistema usando l'intestazione; a 1552 ms applica quello del gioco e il fuoco va su «riga 1, cella 1». Con 725 e 766 ms la caduta non c'è: la finestra è stretta, e l'esito dipende da pochi millisecondi. È l'intermittenza.

Non è stato accertato quale fosse, nell'incarico 28, la durata del caricamento in ciascuna apertura: quella sessione non registrava i tempi dell'app.

## La correzione e la sua verifica

La notifica d'apertura parte in `viewDidAppear`, una volta sola, nello stesso giro del filo principale che conclude la presentazione, e non dipende più dal caricamento; il testo dell'intestazione si scrive al montaggio delle viste. Nella copia di diagnosi, con la stessa correzione e gli stessi ritardi artificiali del caricamento che prima producevano la caduta, 20 aperture su 20 sull'intestazione (serie 8).
