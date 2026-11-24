Incarico 32 — Gli annunci interrotti, il completamento della campagna, e la build 33

Che cos'è questo documento

È il primo messaggio di una sessione nuova. Vale per intero CLAUDE.md. Archivia questo incarico verbatim in Incarichi con il numero 32 e aggiorna l'indice. Leggi il resoconto dell'incarico 31, lo scostamento S29q e il README della verifica con VoiceOver nei prodotti di quell'incarico.

Lo stato di partenza, da verificare

Il principale è a 06dee59, con la build 32 su TestFlight compilata dal codice di b0a15f2. La versione dei valori è 0.15.0, con la 0.14.0 fra le compatibili. Gli schemi dei giornali sono: battaglia 2, campagna 9, regno 2. I numeri sono usati fino a RDA-182 e S29q. Accerta che locale e remoto coincidano e che l'albero di lavoro sia pulito; se trovi altro, fermati e dichiaralo.

Convivenza e consumo

Valgono le regole di CLAUDE.md. In più: nell'incarico 31 i sotto-agenti hanno consumato circa tre milioni di token, e l'account si è fermato tre volte per il limite d'uso. Usa i sotto-agenti soltanto per lavori davvero indipendenti e lunghi da eseguire, per esempio le corse in parallelo sui simulatori. Non usarli per scrivere documenti o prove che poi devi rileggere per intero.

Prima parte: i quattro reperti della verifica con VoiceOver

L'annuncio interrotto. È il reperto S29q, punto (a), ed è il più importante, perché tocca il principio 1 della carta. Quando un annuncio accompagna uno spostamento del fuoco o un cambio di schermata, VoiceOver lo sostituisce dopo circa un secondo e mezzo con la lettura del nuovo elemento. L'annuncio dell'inverno, che dura una decina di secondi, si sente soltanto all'inizio. Correggilo in tutto il gioco, battaglia e campagna comprese, non soltanto nel regno. Scegli la via e motivala: trattenere l'annuncio finché il fuoco non è arrivato, pubblicarlo insieme alla notifica del cambio di schermata, accodarlo con l'attributo di accodamento della sintesi, oppure far portare il contenuto all'elemento che riceve il fuoco. Vale anche qualunque altra via che il servizio VoiceOver delle prove dimostri migliore. Resta valida la coda degli annunci di RDA-172. Misura con il pilota, prima e dopo, su iPhone e iPad, quanto resta in pronuncia ciascun annuncio toccato e se viene detto per intero. Verifica anche che gli annunci che non spostano il fuoco non peggiorino.

Gli altri tre reperti di S29q:

Le reclute che entrano accanto al nemico. A parità di distanza dal proprio quartier generale si sceglie la casella più lontana da quello avversario. La patria e l'annuncio devono dire la casella vera. Rifai il banco.
Senza un gruppo armato da mandare, il rifiuto deve arrivare prima che si apra la scelta del fronte.
La riga in patria di una formazione già arrivata non deve più parlarne al futuro. Scegli la via e dichiarala.

Seconda parte: il completamento della campagna

La presa del quartier generale. Decisione del titolare del 24 novembre. Il quartier generale di una parte è preso quando un gruppo armato dell'altra lo occupa per un certo numero di giornate di fila senza esserne scacciato. Il numero va in un file di valori, provvisorio, a tre. Il difensore può tornare a riprenderlo. Se l'occupante lascia la casella, o perde la battaglia che vi nasce, il conteggio si azzera. La regola vale identica per le due parti, quindi anche l'avversario può prendere il quartier generale del giocatore. Dove c'è una fortezza, che vale come secondo quartier generale, vanno presi tutti e due, come dice già 01 §5.14.3.2. Quando l'ultimo quartier generale cade, la campagna è vinta da chi l'ha preso: i superstiti del perdente tornano in patria, e il vincitore riceve il premio della campagna vinta.

Gli annunci della presa sono questi, per l'attaccante e per il difensore: l'inizio dell'occupazione, le giornate che mancano, l'azzeramento, la caduta. Il difensore sa sempre che il proprio quartier generale è occupato. L'avversario deve saper usare la regola e saper difendersi, con le stesse regole del giocatore. Scrivi la regola in 01 §5.18, con gli annunci in 02 e il valore in 03, poi costruiscila.

La resa della campagna. Costruiscila come dice 01 §5.18.2. Il titolare ha deciso che cosa vale come contatto con il nemico: un gruppo è a contatto se sta nella stessa casella di un gruppo avversario, oppure se c'è una battaglia in sospeso che lo riguarda. Oggi una campagna ha un fronte solo, quindi il richiamo riguarda la campagna. Il caso di più fronti resta aperto in 01 §16.8: aggiorna quel punto, togliendo la parte decisa. Il comando di richiamo, quando non è disponibile, dichiara il perché, secondo 02 §6.5.

Le battaglie che non finiscono. Comincia dal reperto riferito nell'incarico 31: TatticoBattaglia.comandoDiPiazzamento, con due o più elementi del mazzo non piazzabili, alterna la selezione senza fine. Riproducilo e correggilo. Poi rimisura le battaglie che al banco non si concludono, cioè le 33 su 1200 della misura della frequenza e le 78 del banco del regno, e cerca le altre cause. L'obiettivo è zero; se ne restano, dichiara la causa di ciascuna.

Lo squilibrio fra le mappe. Dai dati dell'incarico 29: con la condotta competente il giocatore perde 391 battaglie su 398 sulla mappa piccola, 229 su 245 sulla grande, e vince la gran parte di quelle sulla media. Accertane la causa. Se è un difetto, correggilo. Se dipende dalla composizione delle forze negli scenari, non cambiare nulla: proponi i numeri con l'effetto misurato, e ricorda che il titolare ha deciso di non aggiungere gruppi avversari.

Tre cose minori:

la virgola mancante in «riga 1 cella 2» nelle azioni d'ingaggio;
il congedo del resoconto di una battaglia di campagna, che oggi dice «Torna all'inizio» e riporta sulla mappa: deve dire dove porta;
le tre campagne vinte per annientamento senza nessuna battaglia vinta, nel banco dell'incarico 31 con i semi 123, 173 e 190: spiega come accade, e correggilo se è un difetto.

Terza parte: le verifiche e la build 33

Verifica ogni cosa attraverso l'interfaccia, con il pilota e il tester con VoiceOver su iPhone e iPad. Il tester deve arrivare almeno una volta a prendere un quartier generale e almeno una volta a ritirare l'esercito. Ripeti il banco del regno e la misura della frequenza delle battaglie. Con il collaudo completo e la corsa delle sessioni verdi, carica la build 33 e verificala come d'uso. Dichiara la valutazione sulle versioni dei valori e dei tre schemi, e se le partite salvate con la build 32 non si riaprono lo dicono la nota e il gioco. La nota per il titolare dice in poche righe che cosa cambia per chi gioca.

Consegna

Come prescrive CLAUDE.md. In più, nel resoconto:

per ogni punto, il commit e la prova che lo verificano;
per gli annunci, la tabella dei tempi prima e dopo, per annuncio e per apparecchio;
per le battaglie che non finiscono, per lo squilibrio e per la frequenza, le tabelle prima e dopo, con il file dei dati grezzi e lo strumento che le produce.
