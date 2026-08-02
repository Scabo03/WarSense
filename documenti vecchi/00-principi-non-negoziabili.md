# Carta dei principi non negoziabili

Documento 00 di 05 — versione 1.0

## A cosa serve questo documento e come si usa

Questo è il documento fondativo del progetto. Non descrive il gioco e non descrive il programma: stabilisce i vincoli che nessuna decisione successiva può violare, per nessuna ragione.

Va copiato in testa a ogni conversazione con qualunque modello coinvolto nel progetto, sia in fase di progettazione architetturale sia in fase di scrittura del codice. Il suo scopo pratico è impedire che, a distanza di settimane, venga proposta e accettata una soluzione tecnicamente elegante che infrange silenziosamente uno di questi principi.

Ogni principio è numerato e diviso in punti numerati. Il riferimento va fatto per numero: dire "attieniti al requisito 8.2" è più rapido, più preciso e meno soggetto a fraintendimenti che riformulare il vincolo a parole ogni volta.

Se un principio entra in conflitto con un altro, prevale quello con il numero più basso. Il principio 1 prevale su tutti.

## Istruzione ai modelli che leggono questo documento

Se una richiesta ricevuta durante il progetto non è realizzabile senza violare uno di questi principi, la risposta corretta non è realizzarla comunque, e non è nemmeno realizzarla in una versione ridotta che aggira il vincolo. La risposta corretta è dichiarare esplicitamente quale principio verrebbe violato e proporre un'alternativa che lo rispetti. Se non esiste alcuna alternativa, va detto chiaramente che la funzione non può entrare nel gioco nella forma richiesta.

Un principio non è una linea guida da bilanciare con altre considerazioni. È un vincolo.

## Contesto minimo del progetto

Gioco gestionale e strategico militare a turni, scritto in Swift puro per iOS e iPadOS, distribuito tramite TestFlight in fase di sviluppo. Due piani di gioco: una mappa di campagna a caselle quadrate, con regno persistente, logistica, installazioni militari, addestramento, ricognizione e informazione nascosta; un campo di battaglia a celle esagonali, a informazione completa, con schieramento preliminare a budget di volume. Progressione per fasi storiche, di cui la prima versione copre la fase arcaica e la fase antica insieme alla transizione tra le due. Partita contro avversari gestiti dal programma, con difficoltà generale e con ufficiali nemici dal comportamento differenziato; predisposizione a una futura partita amichevole tra dispositivi vicini sulla stessa rete locale, senza server, senza poste in gioco e senza ricompense.

---

## Principio 1 — L'accessibilità è la priorità assoluta

1.1 L'accessibilità completa con VoiceOver è la priorità assoluta del progetto e prevale su qualunque altra considerazione: eleganza dell'interfaccia, prestazioni, ricchezza delle funzioni, tempi di sviluppo, ambizione delle meccaniche.

1.2 Nessuna informazione e nessuna azione può essere disponibile a chi vede lo schermo e non a chi lo ascolta. La parità non è la disponibilità della stessa funzione in una forma più faticosa: è la disponibilità della stessa informazione con lo stesso numero di operazioni e lo stesso grado di certezza.

1.3 Una funzione non accessibile non è una funzione incompleta da sistemare in seguito. Non entra nel gioco. Non esistono funzioni accessibili in una versione successiva.

1.4 Esempio di violazione da respingere: una mappa in cui la fascia di schieramento valida è evidenziata a colori e, per chi ascolta, si può conoscere solo interrogando le celle una a una. L'informazione formalmente c'è, la parità no.

1.5 Esempio di violazione meno evidente: un pannello che elenca le unità disponibili in una tabella a righe e colonne, dove ogni casella è un elemento distinto. L'informazione è tutta presente e tutta raggiungibile, ma per ricostruire una riga occorrono sei operazioni invece di una, e il confronto tra due unità diventa impraticabile.

## Principio 2 — Swift puro e strumenti nativi

2.1 Il gioco è scritto in Swift con gli strumenti nativi di Apple. Nessun motore di gioco esterno, nessun ambiente multipiattaforma, nessuna libreria che disegni l'interfaccia al posto del sistema.

2.2 La ragione è esclusivamente il principio 1: un motore di gioco disegna l'intera schermata dentro un'unica superficie grafica, che per un lettore di schermo è una zona muta e priva di struttura. Ogni elemento leggibile andrebbe ricostruito artificialmente, con soluzioni fragili e da mantenere a mano una per una.

2.3 Ogni elemento con cui il giocatore interagisce è un elemento accessibile dotato di nome, ruolo, valore e, dove pertinente, azioni. Nessun elemento interattivo è un semplice disegno con un'area sensibile al tocco sovrapposta.

2.4 Le celle della griglia esagonale e della mappa di campagna sono elementi accessibili a tutti gli effetti, non porzioni di un'immagine.

## Principio 3 — Logica separata dall'interfaccia

3.1 La logica di gioco è costituita da uno stato completo e da comandi discreti che lo modificano. Applicare lo stesso comando allo stesso stato produce sempre lo stesso risultato.

3.2 La logica non conosce lo schermo: non contiene riferimenti a schermate, gesti, annunci, animazioni, suoni o vibrazioni. L'interfaccia non contiene regole: non decide esiti, costi, validità o conseguenze, ma li chiede alla logica e li presenta.

3.3 Il confine tra i due va tenuto in modo rigoroso anche quando attraversarlo sembra una scorciatoia innocua. È il singolo requisito da cui dipende il maggior numero di funzioni già decise, e l'unico che non si può recuperare in seguito senza riscrivere il gioco.

3.4 Da questo requisito dipendono direttamente: il salvataggio automatico dello stato completo a ogni singola azione e non a fine turno; la futura partita tra dispositivi vicini, che consiste nello scambio della sequenza di comandi; il programma di verifica del bilanciamento, che gioca migliaia di partite senza interfaccia; l'annullamento dell'ultima mossa e l'azzeramento dello schieramento; la possibilità di rigiocare una partita conclusa per capire dove è andata storta.

3.5 Il salvataggio automatico a ogni azione è un requisito di base e non un'aggiunta successiva, perché una partita senza limiti di tempo può restare aperta per giorni e venire interrotta in qualunque istante.

## Principio 4 — Turni e nessun limite di tempo

4.1 Il gioco è a turni. Non esiste alcun limite di tempo, in nessuna schermata e in nessuna fase, compresa la fase di schieramento preliminare.

4.2 Nessuna meccanica può richiedere prontezza di reazione, nessun conto alla rovescia può scadere, nessuna opportunità può svanire per il passare del tempo reale. Ascoltare richiede più tempo che guardare, e qualunque vincolo di durata reintroduce per via indiretta la disparità vietata dal principio 1.

4.3 Ogni vincolo che nella progettazione si presenta spontaneamente come una durata va riformulato come una quantità. Esempio già adottato: il vantaggio di chi coglie l'avversario di sorpresa non è un tempo di schieramento più breve per la vittima, ma un budget di volume schierabile più basso e una profondità di schieramento più ridotta. L'effetto sul gioco è lo stesso, la disparità scompare, e per di più il vincolo diventa deterministico e quindi misurabile dalle simulazioni.

4.4 Questa riformulazione va applicata sistematicamente a ogni nuova meccanica proposta, non solo a quelle già decise.

## Principio 5 — L'aptica è uno strato aggiuntivo, mai l'unico

5.1 Il motore aptico avanzato esiste soltanto su iPhone. Gli iPad non dispongono del componente fisico necessario, compresi i modelli più recenti della linea professionale. Su iPad lo strato tattile semplicemente non esiste, e non è aggirabile in alcun modo.

5.2 Di conseguenza, nessuna informazione può essere trasmessa esclusivamente per via tattile. Ogni segnale aptico ha sempre una controparte sonora o testuale che veicola la stessa informazione.

5.3 Un solo punto centrale del programma riceve gli eventi di gioco in forma astratta, per esempio battaglia vinta, risorsa esaurita, cambio di riga nella navigazione, piazzamento confermato, e decide da sé quali canali attivare in base all'apparecchio in uso e alle preferenze dell'utente. Il resto del programma non contiene alcun riferimento a vibrazioni, suoni o annunci: si limita a segnalare che un evento è avvenuto.

5.4 Il vocabolario aptico è costruito prima di tutto sulla struttura temporale, cioè su ritmo e durata, e solo in second'ordine su intensità e nitidezza. Due impulsi separati da una pausa si distinguono da tre impulsi in qualunque condizione d'uso; due livelli di intensità ravvicinati si confondono se l'apparecchio è appoggiato a un tavolo, tenuto con una mano sola o dentro una custodia spessa. Intensità e nitidezza sono ammesse come sfumature interne a famiglie già distinte per ritmo.

5.5 I pattern aptici stanno in un file di dati separato, con nomi parlanti e parametri modificabili senza ricompilare, esattamente come i valori di bilanciamento.

5.6 Due vincoli tecnici da non dimenticare: la vibrazione è disattivata dal sistema quando l'apparecchio è in modalità di risparmio energetico, e il motore aptico va mantenuto pronto anziché acceso e spento a ogni evento, altrimenti il primo impulso arriva in ritardo e la sincronia con il suono si perde.

## Principio 6 — Il testo resta testo

6.1 Tutti i contenuti verbali del gioco restano testo, letto da VoiceOver con la voce, la lingua e la velocità scelte dall'utente nelle impostazioni di sistema.

6.2 Nessuna narrazione registrata o sintetizzata sostituisce gli annunci, in nessun punto del gioco. Chi usa VoiceOver quotidianamente ascolta a velocità molto elevate con una voce scelta con cura: una voce registrata che parla a ritmo naturale risulta lentissima e frustrante, e non è accelerabile.

6.3 Le voci sintetiche generate e la produzione audio servono per un altro strato, e su quello vanno sfruttate a fondo: suoni brevi e riconoscibili che comunicano informazione senza parole, ambienti sonori che cambiano con la fase storica, segnali distinti per esiti diversi.

6.4 Corollario: qualunque informazione affidata a un suono senza parole deve essere recuperabile anche in forma testuale su richiesta. Un suono si può perdere, un testo si può rileggere.

## Principio 7 — Un solo linguaggio di interazione

7.1 Gesti, formato degli annunci, logica dei rotori, comportamento del fuoco e vocabolario degli stati sono identici sulla mappa di campagna e sul campo di battaglia.

7.2 L'unica differenza ammessa tra i due piani è il numero di celle vicine: quattro sulla mappa di campagna a caselle quadrate senza diagonali, sei sul campo di battaglia esagonale.

7.3 Chi ha imparato a muoversi su un piano deve saper muoversi sull'altro senza reimparare nulla. Due dialetti diversi nello stesso gioco sono la cosa che affatica di più chi ascolta.

7.4 Il modello di navigazione è unico: gli scorrimenti orizzontali percorrono la riga da est a ovest e viceversa, proseguendo nella riga successiva alle estremità; le direzioni restanti stanno nelle azioni personalizzate, in numero non superiore a quattro; le azioni di gioco relative alla cella stanno in un pannello dedicato che si apre con l'attivazione della cella, e non nelle azioni personalizzate.

7.5 Le azioni personalizzate non superano mai le cinque voci. Oltre quella soglia ritrovare quella giusta costa più tempo che aprire un pannello, e il vantaggio sparisce.

## Principio 8 — Nessun trascinamento come manipolazione

8.1 In nessun punto del gioco un'operazione richiede di afferrare un oggetto e portarlo altrove. Il trascinamento come manipolazione non è disponibile quando VoiceOver è attivo.

8.2 Lo schema universale è: si seleziona l'elemento da una lista, si naviga fino alla destinazione, si conferma. Questo vale per lo schieramento, per gli spostamenti sulla mappa di campagna, per l'assegnazione di unità a colonne e per qualunque operazione futura di natura analoga.

8.3 Va distinta l'esplorazione al tatto, cioè appoggiare il dito e farlo scorrere sentendo annunciare ciò che si attraversa, che è pienamente disponibile e va sfruttata: è una modalità normale di uso di VoiceOver. Ciò che non esiste è il trascinamento con manipolazione. La somiglianza tra i due gesti non deve indurre a confonderli in fase di progettazione.

## Principio 9 — Ogni informazione è dichiarata, non dedotta

9.1 Ogni informazione che chi vede riceve a colpo d'occhio deve essere dichiarata a voce, mai lasciata da ricostruire.

9.2 Ricadono obbligatoriamente in questa categoria: la validità di una cella rispetto all'elemento attualmente selezionato e il motivo dell'eventuale non validità; il costo di un'azione prima della conferma e il residuo che ne conseguirebbe; il budget disponibile, consultabile in qualunque momento con un gesto fisso e senza uscire dalla griglia; l'affidabilità di un dato di ricognizione; la posizione della cella in cui si trova il fuoco.

9.3 Esempio di riferimento, già stabilito: con un elemento selezionato nel deck, una cella si annuncia come disponibile con l'indicazione di quanto volume spenderebbe e di quanto ne resterebbe, oppure come non disponibile con il motivo, cioè troppo avanzata rispetto alla profondità concessa oppure capienza della cella esaurita. Chi vede ha una barra che si consuma e celle colorate per fascia di costo, e non ci pensa. La parità si ottiene solo dicendolo.

9.4 Il vocabolario che esprime questi stati è chiuso, fisso e identico in tutto il gioco. I termini vanno scelti una volta e mai variati, perché il giocatore li userà come segnali e non come frasi. Esempio per la ricognizione: inesplorato, presunto, avvistato con il numero di turni trascorsi, confermato. Nessun sinonimo, nessuna variazione stilistica, in nessun punto.

9.5 Le impostazioni offrono tre livelli di verbosità degli annunci: sintetico, normale, dettagliato. L'ordine di priorità delle informazioni all'interno di ogni annuncio è fisso e dichiarato, così che nei livelli più brevi si taglino le ultime voci e non porzioni arbitrarie.

## Principio 10 — Nulla è raggiungibile solo per esplorazione al tatto

10.1 Nessuna informazione spaziale è accessibile soltanto appoggiando il dito allo schermo. Tutto è raggiungibile anche a scorrimenti, perché molti giocatori esperti navigano quasi esclusivamente così, essendo più affidabile e non richiedendo di sapere dove si trovino fisicamente le cose.

10.2 Per ogni insieme di elementi che il giocatore consulta ripetutamente esiste un rotore dedicato, che permette di saltarvi direttamente. Insiemi previsti: le proprie unità, le unità nemiche note, le installazioni, le celle valide per l'elemento attualmente selezionato, le caselle da cui è possibile esplorare, le informazioni di ricognizione scadute, gli eventi del turno.

10.3 I rotori non sono una comodità accessoria: percorrere una griglia un passo alla volta è sempre lento, e su cento celle diventa impraticabile. Sono il principale strumento di parità nell'accesso a una superficie estesa.

10.4 La griglia da cento celle non viene compressa a forza dentro lo schermo di un iPhone, perché ne risulterebbero bersagli inferiori alla dimensione minima raccomandata e l'esplorazione al tatto diventerebbe imprecisa. La griglia è ingrandibile e scorrevole; tutte le celle restano raggiungibili a scorrimenti anche quando sono fuori dalla porzione visibile, e il fuoco che si sposta su una cella non visibile fa scorrere la vista di conseguenza.

## Principio 11 — Il fuoco non si sposta da solo

11.1 Il fuoco di VoiceOver non si sposta mai in modo non richiesto dall'utente. Dopo ogni azione resta dove l'utente lo ha lasciato.

11.2 Questo requisito va imposto esplicitamente perché il comportamento predefinito del sistema, quando il contenuto di una schermata cambia, tende a riportare il fuoco all'inizio. È il difetto che rompe più spesso i giochi accessibili.

11.3 Esempi vincolanti. Confermato un piazzamento, il fuoco resta sulla cella appena usata, perché il modello di schieramento prevede di piazzare più elementi su celle vicine con conferme successive: se il fuoco torna al deck, ogni piazzamento costa il viaggio di ritorno e il modello crolla. Esaurito un elemento del deck, con conseguente deselezione automatica, il fuoco resta dove è e l'esaurimento viene annunciato. Aggiornato un valore in una schermata di gestione, il fuoco non si muove.

11.4 Ogni cambiamento di stato rilevante viene annunciato senza rubare il fuoco.

11.5 L'ordine di lettura è definito esplicitamente dal gioco, elemento per elemento, e non lasciato dedurre al sistema dalla disposizione sullo schermo. Con una griglia esagonale le righe sono sfalsate e i centri delle celle non sono allineati: l'ordinamento automatico produce percorsi imprevedibili. L'ordine stabilito è: le celle della griglia da ovest a est e dall'alto in basso, poi il deck, poi i comandi di annullamento e di azzeramento.

11.6 Il passaggio da una riga alla successiva, che comporta un salto attraverso tutto il campo, è segnalato da un impulso aptico riconoscibile con la sua controparte sonora, e il numero di riga compare nell'annuncio.

## Principio 12 — Nessun riferimento storico diretto

12.1 Il gioco non contiene riferimenti storici diretti: né popoli, né personaggi, né unità o macchine identificabili con una civiltà determinata.

12.2 Le unità sono archetipi definiti per funzione, ai quali si applicano tratti modificatori. Questo risolve insieme la questione della licenza storica e un problema di progettazione: la fanteria d'élite di tipo spartano e la guardia scelta di tipo persiano sono entrambe guardia d'élite, l'una con un tratto di tenuta in formazione e l'altra con un tratto di versatilità e capacità di tiro, e il giocatore può disporre di entrambe senza alcuna incongruenza.

12.3 La fedeltà alla fase storica riguarda i parametri fisici e logistici, non i nomi: quali materiali esistono, quanto lontano si può colpire, quanto pesa e quanto costa alimentare una colonna in marcia, quale autonomia ha, quanto tempo richiede addestrare o costruire. È lì che la verosimiglianza si percepisce.

12.4 Poiché l'estensione reale di una cella varia con la dimensione dello scontro, portate e autonomie non sono espresse in metri o in giorni, ma in numero di celle e in numero di turni, con la scala reale dichiarata a parte per ciascun formato. Questa regola va rispettata senza eccezioni, altrimenti la stessa arma risulta più efficace su una griglia piccola che su una grande.

## Principio 13 — Valori come rapporti, costi come numeri interi

13.1 I valori di gioco stanno in file di dati separati dal programma, leggibili e modificabili senza ricompilare. Non è previsto alcun pannello di regolazione dei valori all'interno del gioco: le modifiche di bilanciamento si fanno sui file.

13.2 I valori sono espressi il più possibile come rapporti e coefficienti riferiti a una base di fase, non come cifre indipendenti. La ragione è operativa: se il costo di una guardia d'élite è definito come multiplo del costo della fanteria di base della sua fase, una richiesta del tipo "rendi più costosa la guardia d'élite in modo da allargare il distacco dalla fanteria" si traduce in una modifica di due coefficienti e l'intera scala si riassesta coerentemente. Con duecento cifre scollegate, la stessa richiesta diventa duecento modifiche manuali e l'incoerenza è garantita.

13.3 Ogni comportamento che dipende da più fattori è espresso da una formula unica condivisa più un coefficiente per tipo di elemento, mai da una tabella a doppia entrata. Esempio già stabilito: il costo in volume di un piazzamento cresce con la profondità e dipende dal tipo di unità. Non esiste una tabella tipo per riga per formato di griglia, che sarebbero centinaia di numeri indipendenti. Esiste un coefficiente di penalità di avanzamento per tipo di unità, basso per la fanteria e altissimo per una macchina d'assedio, e una sola formula che lo combina con la profondità espressa in proporzione alla griglia, così che i tre formati si regolino da sé.

13.4 I coefficienti possono essere decimali nei file di dati, dove nessuno li ascolta. I costi e i valori mostrati al giocatore sono sempre numeri interi.

13.5 Regola di arrotondamento, unica e valida per tutto il gioco: qualunque valore decimale mostrato al giocatore o registrato nello stato viene arrotondato per difetto, cioè troncato alla parte intera. Nessuna eccezione, nessuna regola locale diversa, in nessun punto.

13.6 Corollario obbligatorio della regola precedente: dove un arrotondamento per difetto potrebbe produrre zero, va dichiarato un valore minimo di uno. Un piazzamento a costo zero o un attacco a danno zero per effetto del troncamento sarebbero difetti sfruttabili, non scelte di progetto. Il minimo va stabilito espressamente per ciascuna grandezza in cui il caso è possibile.

13.7 Le grandezze di base sono scelte abbastanza grandi da rendere i decimali quasi sempre irrilevanti. Un fante non vale uno ma dieci, una macchina d'assedio cinquanta: le proporzioni restano identiche, gli annunci restano interi e leggibili, e le simulazioni restano riproducibili.

13.8 Ogni budget che si consuma richiede l'annullamento dell'ultima operazione e l'azzeramento completo. Un'operazione sbagliata consuma budget, e senza annullamento il giocatore paga un errore di manovra come se fosse stata una scelta tattica.

## Principio 14 — Testi fuori dal programma e localizzazione dal primo giorno

14.1 Tutti i testi, compresi gli annunci vocali, stanno fuori dal programma dal primo giorno. La prima versione è in italiano, una versione inglese seguirà, e nessuna stringa va scritta dentro il codice nemmeno in via provvisoria.

14.2 Ogni annuncio è una frase intera con dei segnaposto da riempire, mai una somma di parole concatenate. In italiano i componenti si accordano per genere e numero, in inglese quasi mai: un annuncio costruito incollando parole produce frasi sgrammaticate nella lingua diversa da quella in cui è stato pensato.

14.3 I plurali sono gestiti dal meccanismo di localizzazione del sistema e non con condizioni scritte a mano.

14.4 Ogni testo dichiara la propria lingua. Se un giocatore usa VoiceOver con una voce inglese e gioca in italiano, senza questa dichiarazione la voce legge l'italiano in modo incomprensibile. È un'indicazione minima per ciascun annuncio, e va inserita dall'inizio: aggiungerla in seguito su centinaia di annunci è un lavoro cieco e incompleto per definizione.

14.5 I termini del vocabolario chiuso di cui al principio 9.4 sono localizzati come termini fissi, non come frasi liberamente traducibili, e la loro invariabilità va mantenuta anche nella versione inglese.

## Principio 15 — Salvataggi versionati

15.1 Ogni salvataggio registra la versione dei file di dati a cui appartiene.

15.2 Davanti a un salvataggio incompatibile, il gioco lo dichiara esplicitamente e non lo apre, invece di caricarlo e comportarsi in modo imprevedibile.

15.3 La ragione è pratica e riguarda i tester. Con un regno persistente le partite durano molte ore, e durante il bilanciamento i file dei valori cambiano continuamente. Il giorno in cui un tester perde una campagna da dieci ore senza spiegazione, smette di collaborare, e i tester competenti sono la risorsa più scarsa del progetto.

15.4 I file di dati vengono copiati, al primo avvio, in una posizione accessibile dall'applicazione File dell'apparecchio, così che siano modificabili anche direttamente su iPad durante la fase di messa a punto, senza passare dal computer e senza ricompilare.

## Principio 16 — La verifica è misura, non impressione

16.1 Il bilanciamento non si valuta a sensazione. Esiste un programma di verifica, separato dal gioco e senza interfaccia, che simula un grande numero di scontri e confronti e riporta percentuali di esito. Ogni richiesta di rimodulazione dei valori si verifica con quei numeri.

16.2 Le simulazioni misurano in particolare i margini che non si percepiscono giocando, per esempio quale budget di schieramento renda una posizione praticamente indifendibile e quale la renda una vittoria automatica.

16.3 Tester non vedenti reali sono coinvolti tramite TestFlight dal primo prototipo giocabile, non alla fine. La verifica in prima persona con VoiceOver attivo è utile ma insufficiente, perché chi ha progettato il gioco sa già dove si trovano le cose.

16.4 Ordine di costruzione: un singolo scontro completo, dalla schermata iniziale alla battaglia conclusa, perfettamente accessibile e giocabile dall'inizio alla fine, portato ai tester prima di costruire il piano di campagna. Se il modello di navigazione e di annuncio funziona su una battaglia funzionerà su tutto; se non funziona, è preferibile scoprirlo con una battaglia da rifare che con un gioco intero.

---

## Riepilogo dei documenti di progetto

00 Carta dei principi non negoziabili — questo documento.

01 Documento di progetto del gioco — fasi storiche e transizione, economia, archetipi di unità e tratti, mappa di campagna, ricognizione, campagne e ufficiali nemici, ponte tra i due piani, regole di scala.

02 Documento di accessibilità — modello di navigazione, azioni personalizzate e pannelli, rotori, formato esatto degli annunci, vocabolario chiuso, vocabolario aptico e corrispondenze, impostazioni di accessibilità.

03 Documento dei dati — struttura dei file di valori, coefficienti e formule, regole di arrotondamento e minimi, funzionamento del programma di verifica.

04 Riferimenti storici — un file per fase, con distinzione tra valori documentati e stime.

Il documento di architettura tecnica non è redatto a mano: è il prodotto richiesto a partire da questi cinque.
