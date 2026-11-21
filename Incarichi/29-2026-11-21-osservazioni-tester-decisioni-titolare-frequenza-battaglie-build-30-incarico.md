Incarico 29 — Le osservazioni del tester, quattro decisioni del titolare, la frequenza delle battaglie, e la build 30

Che cos’è questo documento

È il primo messaggio di una sessione nuova. Vale per intero CLAUDE.md. Archivia questo incarico verbatim in Incarichi con il numero 29 e aggiorna l’indice. Prima di cominciare leggi il resoconto dell’incarico 28 e il file delle osservazioni della sessione da tester nei suoi prodotti.

Lo stato di partenza, da verificare

Il principale è a 72aec4c, con la build 29 su TestFlight, la versione dei valori 0.13.0 e lo schema del giornale di campagna 9. I numeri sono usati fino a RDA-154. Accerta che locale e remoto coincidano e che l’albero di lavoro sia pulito; se trovi altro, fermati e dichiaralo.

Convivenza

Valgono le regole di CLAUDE.md, compresa quella sulla chiusura di Device Hub.

Le osservazioni della sessione da tester

Correggi le sei osservazioni del file dell’incarico 28, ciascuna prima riprodotta con una prova che fallisce sul codice attuale.

Il pannello di un gruppo con una battaglia in sospeso altrove è vuoto e non dice perché: deve dichiarare il motivo come prescrive 02 §6.5.
«Hanno agito 1 gruppi su 4» va accordato al numero.
Sull’iPad il fuoco, all’apertura della battaglia, a volte cade sulla prima cella invece che sull’intestazione del deck: accerta la causa dell’intermittenza prima di correggere.
Il gesto di uscita deve chiudere anche impostazioni, apprendimento e resoconto.
Una tessera appena deselezionata non deve più essere annunciata come selezionata: verifica la causa che il resoconto 28 ipotizza, cioè i tratti aggiornati per via asincrona dopo l’attivazione.
L’azzeramento, quando non c’è nulla da azzerare, deve dirlo invece di confermare.

Le decisioni del titolare del 21 novembre

Il testo segue la dimensione di sistema. Tutti i testi dell’interfaccia seguono la dimensione del testo scelta nelle impostazioni di sistema: pulsanti, etichette, pannelli, impostazioni, apprendimento, registro, resoconti. Fanno eccezione, dichiarata, le tessere del deck, le celle della griglia e le caselle della mappa, che hanno misure fisse per ragioni di geometria. Scrivilo nei documenti e realizzalo, con una prova per ogni schermata alla dimensione più grande.

Frasi accordate al genere. Ogni termine chiuso che designa un reparto, un archetipo o qualunque soggetto di frase dichiara il proprio genere nei file del vocabolario. Le frasi che lo contengono si scrivono intere per ciascun genere, mai incollando pezzi, secondo il punto 14.2 della carta: per esempio «La tua fanteria leggera A è stata ingaggiata» e «Il tuo carro B è stato ingaggiato». Il termine in sé resta invariabile, come vuole 02 §4.5; cambiano articoli e accordi. Aggiungi un controllo che rifiuti una frase priva della forma per un genere che può ricevere, e vedilo fallire. Aggiorna 02 dove serve, perché la regola valga anche per i titoli dei campioni.

La designazione della marcia. Ogni casella in designazione comincia dalla sua posizione, come la testa fissa di ogni casella, e poi dice il costo: per esempio «riga 3, casella 3, libera, raggiungibile in 2 giorni». L’avvertimento sul gruppo che resta fermo fino all’arrivo e non può sfilarsi senza perdere i giorni spesi lo dice una volta sola il comando di marcia, quando lo si sceglie, e non più ogni casella.

Il meteo. Ogni giornata la campagna dichiara una previsione per la giornata successiva, con i termini chiusi che 02 riserva alle probabilità, per esempio «domani pioggia probabile». Il tempo che poi arriva si estrae secondo quella probabilità, con il seme della partita. La previsione sta nell’informazione di stato e non interrompe. Scrivilo in 01 e 02, coerente con il trattamento dei guasti. Nel codice non c’è nulla da costruire: il meteo non esiste ancora. Resta aperto, e non va deciso, se meteo e guasti valgano anche nella modalità a campioni: segnalalo come punto aperto nel documento della modalità.

La frequenza delle battaglie

Nelle partite della sessione da tester, su circa centoventi giornate di campagna, sono nate soltanto due battaglie, e nessuna partita è arrivata alla fine. In parte dipende dal tester, che gioca con prudenza. Misura con il banco, su un numero di partite intere che giustifichi la misura, per ciascun formato: quante battaglie nascono ogni dieci giornate, dopo quante giornate nasce la prima, quante giornate dura una partita fino alla sua fine naturale, e come finisce. Fallo con due modi di giocare per la parte del giocatore: quello competente del banco, e uno prudente sul modello del tester. Cerca nei documenti se esiste un ritmo atteso. Poi proponi che cosa cambiare e con quale effetto previsto. Non tarare nulla: la decisione spetta al titolare.

Le verifiche

Ogni correzione e ogni decisione realizzata va vista funzionare attraverso l’interfaccia, con VoiceOver acceso, usando il pilota e il tester dell’incarico 28 sui percorsi toccati, su iPhone e iPad, compresa la dimensione del testo più grande. Riporta ciò che resta scoperto, come d’uso.

La build 30

Con il collaudo completo e la corsa delle sessioni verdi, carica la build 30 e verificala su App Store Connect come d’uso. Dichiara la valutazione sulle versioni dei valori e dello schema del giornale. Se lo schema cambia, le campagne salvate con la build 29 vanno rifiutate dichiarandolo, come già fatto per la build 28, e la nota per il titolare lo dice. Nella nota scrivi in poche righe che cosa cambia per chi gioca.

Consegna

Come prescrive CLAUDE.md. In più, nel resoconto: per ogni osservazione e ogni decisione, il commit e la prova che la verificano; per la frequenza delle battaglie, una tabella per formato e per modo di gioco, con i numeri prodotti da uno strumento e lo strumento indicato, e il file dei dati grezzi nei prodotti.
