# Documento di accessibilità

Documento 02 di 05 — versione 1.0

## Come leggere questo documento

Questo documento stabilisce come le informazioni del gioco vengono presentate e come il giocatore agisce. È il documento da consultare per qualunque lavoro sull'interfaccia, sugli annunci, sui gesti, sui segnali tattili e sonori.

Va letto insieme alla carta dei principi non negoziabili, che prevale in caso di conflitto, e insieme al documento 01 per ciò che riguarda le regole di gioco sottostanti.

I requisiti sono numerati. I punti contrassegnati come proposta sono suggerimenti del redattore e non decisioni del titolare del progetto. I punti contrassegnati come da definire vanno chiusi prima della realizzazione della parte corrispondente e non devono essere colmati di iniziativa da alcun modello.

---

## 1. Principio di parità applicato all'interfaccia

1.1 Ogni informazione che chi guarda riceve a colpo d'occhio è dichiarata a voce. Ogni azione disponibile a chi guarda è disponibile con lo stesso numero di operazioni a chi ascolta.

1.2 La parità non consiste nel rendere l'informazione raggiungibile, ma nel renderla raggiungibile con lo stesso costo. Un dato ottenibile solo interrogando venti elementi uno per uno non è un dato disponibile.

1.3 Il gioco è pensato anche per giocatori ipovedenti che usano VoiceOver come supporto e non come unico canale, e per giocatori che alternano esplorazione al tatto e navigazione a scorrimenti. Nessuna scelta di progetto può presupporre che il giocatore abbia percorso un cammino: ogni elemento deve essere comprensibile anche da chi vi atterra direttamente.

## 2. Modello di navigazione

2.1 Il modello di navigazione è unico per il campo di battaglia e per la mappa di campagna, secondo il principio 7. L'unica differenza ammessa è il numero di celle vicine.

2.2 Campo di battaglia. Griglia esagonale con esagoni orientati con la punta in alto. Le celle si dispongono in righe orizzontali continue e due dei sei vicini si trovano esattamente a est e a ovest. Le quattro direzioni rimanenti sono nord-est, sud-est, sud-ovest, nord-ovest.

2.3 Mappa di campagna. Griglia a caselle quadrate con adiacenza ortogonale. I vicini sono quattro: est, ovest, nord, sud.

2.4 Lo scorrimento orizzontale di VoiceOver percorre la riga verso est e verso ovest e prosegue nella riga successiva alle estremità. È il gesto principale di spostamento e coincide, su entrambi i piani, con lo spostamento reale lungo la riga.

2.5 Le direzioni rimanenti sono realizzate come azioni personalizzate, accessibili con lo scorrimento verticale: quattro sul campo di battaglia, due sulla mappa di campagna.

2.6 Le azioni personalizzate non superano mai le cinque voci complessive. Oltre quella soglia scorrere l'elenco costa più tempo che aprire un pannello.

2.7 Le azioni personalizzate contengono soltanto spostamenti di navigazione. Le azioni di gioco relative alla cella stanno in un pannello dedicato che si apre attivando la cella. La divisione è netta: le azioni personalizzate servono a muoversi, il pannello serve ad agire.

2.8 L'ordine di lettura è definito esplicitamente dal gioco, elemento per elemento, e mai lasciato dedurre al sistema dalla disposizione sullo schermo. Con righe sfalsate l'ordinamento automatico produce percorsi imprevedibili. L'ordine stabilito è: le celle della griglia da ovest a est e dall'alto in basso, poi il deck, poi i comandi di annullamento e di azzeramento.

2.9 All'apertura della battaglia il fuoco si posiziona sull'intestazione del deck. Uno scorrimento verso destra porta al primo elemento del deck; uno scorrimento verso sinistra porta all'ultima cella della griglia, cioè quella più a est della riga più vicina alle proprie retrovie, da cui si risale la retrolinea verso ovest e quindi alle righe superiori.

2.10 La zona di schieramento coincide quindi con la zona più vicina al deck sia nell'ordine degli scorrimenti sia nella disposizione fisica sullo schermo. Questa coincidenza è voluta e va preservata in qualunque riorganizzazione dell'interfaccia.

2.11 Nessuna informazione spaziale è raggiungibile soltanto per esplorazione al tatto. Tutto è raggiungibile anche a scorrimenti, e viceversa nessuna informazione è raggiungibile soltanto a scorrimenti.

2.12 Modalità di esplorazione libera con area a tocco diretto, in cui l'applicazione riceve i tocchi grezzi e genera direttamente gli annunci. Proposta, e da valutare solo come modalità opzionale in una versione successiva. Non fa parte della prima versione e non deve condizionarne il progetto.

## 3. Struttura degli annunci di cella

3.1 L'annuncio di una cella ha una testa fissa e obbligatoria, il cui ordine non può essere modificato in alcun punto del gioco.

3.2 Con nessun elemento selezionato nel deck, l'ordine è: numero di riga, numero della cella nella riga, contenuto della cella. Esempio di forma: riga sette, cella quattro, seguito da ciò che vi si trova.

3.3 Con un elemento selezionato nel deck, l'ordine è: disponibilità della cella per quell'elemento e, se non disponibile, immediatamente il motivo; poi numero di riga; poi numero della cella nella riga; poi eventuale contenuto.

3.4 Il numero di riga è annunciato sempre, in ogni annuncio di cella, anche scorrendo più celle consecutive della stessa riga. La ripetizione è voluta e non va ottimizzata: chi esplora al tatto e chi usa VoiceOver come supporto visivo atterra su una cella senza averne percorse altre, e una cella priva del numero di riga sarebbe una cella priva di posizione.

3.5 I motivi di non disponibilità sono tre e soltanto tre, secondo il punto 8.9 del documento 01: profondità eccessiva rispetto al budget disponibile, cella già occupata, cella non interattiva perché parte di un ostacolo. I termini che li esprimono appartengono al vocabolario chiuso della sezione 4 e non ammettono varianti.

3.6 Quando il piazzamento è possibile, l'annuncio dichiara il costo in volume dell'operazione e il volume che resterebbe dopo averla compiuta, prima della conferma. Chi guarda dispone di una barra che si consuma e di celle differenziate per fascia di costo; la parità si ottiene dicendolo.

3.7 Le celle occupate da un ostacolo sono annunciate immediatamente come tali e non sono interattive.

3.8 Il resto del contenuto dell'annuncio, cioè quali informazioni sulla cella seguano la testa fissa e in quale ordine, è lasciato alla scelta di chi realizza, con una condizione vincolante: la scelta va compiuta una volta sola, registrata in questo documento e rispettata in ogni schermata del gioco. Il principio 7 vieta che due schermate annuncino le stesse cose in ordine diverso. L'ordine potrà essere rivisto dopo le prime prove di gioco, ma sempre come modifica unica e globale.

3.9 Livelli di verbosità. Le impostazioni offrono tre livelli: sintetico, normale, dettagliato. L'ordine di priorità delle informazioni è fisso e dichiarato, così che nei livelli più brevi si taglino le ultime voci e non porzioni arbitrarie. La testa fissa della sezione 3.2 e 3.3 non è mai tagliata, in nessun livello.

3.10 Nel livello sintetico l'annuncio di una cella vuota deve restare dell'ordine di poche parole. Da questo dipende la praticabilità della scansione rapida di riga descritta alla sezione 6.

## 4. Vocabolario chiuso

4.1 Gli stati ricorrenti del gioco sono espressi con un insieme chiuso di termini, fissi e identici in ogni punto del gioco. I termini sono segnali, non frasi: nessun sinonimo, nessuna variazione stilistica, nessuna riformulazione contestuale.

4.2 Stati di conoscenza sulla mappa di campagna: inesplorato, presunto, avvistato seguito dal numero di turni trascorsi, confermato.

4.3 Motivi di non disponibilità di una cella: troppo avanzata, occupata, ostacolo.

4.4 Espressioni di probabilità, impiegate per lo stato di manutenzione e per il rischio di guasto, secondo il punto 12.3 del documento 01. Da definire l'insieme dei gradi e i termini che li esprimono.

4.5 I termini del vocabolario chiuso sono localizzati come termini fissi e non come frasi liberamente traducibili. La loro invariabilità va mantenuta anche nella versione inglese.

## 5. Comportamento del fuoco

5.1 Il fuoco di VoiceOver non si sposta mai in modo non richiesto dall'utente. Dopo ogni azione resta dove l'utente lo ha lasciato. Questo va imposto esplicitamente, perché il comportamento predefinito del sistema, al mutare del contenuto di una schermata, tende a riportare il fuoco all'inizio.

5.2 Confermato un piazzamento, il fuoco resta sulla cella appena usata. Il modello di schieramento prevede conferme successive su celle vicine: se il fuoco tornasse al deck, ogni piazzamento costerebbe il viaggio di ritorno.

5.3 Esaurito un elemento del deck, con conseguente deselezione automatica, il fuoco resta dove è e l'esaurimento è annunciato.

5.4 L'arrivo dei rinforzi nel deck è annunciato con una sintesi e un segnale sonoro dedicato, senza spostare il fuoco.

5.5 Ogni cambiamento di stato rilevante è annunciato senza rubare il fuoco.

5.6 L'evento che innesca una battaglia non forza il passaggio alla schermata di battaglia. Il passaggio avviene solo per scelta del giocatore, attraverso il comando presente nella casella interessata.

## 6. Scansione di riga e informazioni di stato

6.1 La verifica dello stato di una riga si compie scorrendo le celle della riga, che sono al massimo dieci. È l'operazione su cui si fondano lo sbarramento della traiettoria avversaria e la valutazione di una linea durante la ritirata combattuta.

6.2 Su griglia esagonale i vicini di una cella appartengono alla sua riga e alle due adiacenti: per superare una riga occorre attraversarla, e una riga interamente occupata è per costruzione una barriera. Chiudere una linea coincide dunque con riempire una riga, che è l'operazione che la navigazione a scorrimenti esegue meglio. Questa coincidenza va preservata.

6.3 Il passaggio da una riga alla successiva, che nell'ordine di lettura comporta un salto attraverso tutto il campo, è segnalato da un impulso tattile riconoscibile con la corrispondente controparte sonora, e il numero di riga compare comunque nell'annuncio della cella.

6.4 Informazione di stato della battaglia, richiamabile in qualunque momento con un gesto fisso e senza abbandonare la griglia. Contiene almeno: budget di volume residuo del turno, numero del turno, riga occupata dalle forze avversarie più avanzate, e durante la ritirata combattuta il numero di righe che mancano alla soglia.

6.5 Informazione di stato della campagna, dichiarata all'apertura della schermata di campagna. Se una battaglia è in sospeso, lo stato lo dichiara e indica dove. Ogni comando bloccato dichiara il medesimo motivo, cioè la battaglia in sospeso, così che il giocatore non debba ricostruirlo per tentativi.

## 7. Rotori

7.1 I rotori personalizzati consentono di saltare direttamente agli elementi di un insieme. Non sono una comodità accessoria: percorrere una griglia un passo alla volta è sempre lento, e su cento celle diventa impraticabile. Sono il principale strumento di parità nell'accesso a una superficie estesa.

7.2 Elenco proposto per il campo di battaglia: i propri sciami, gli sciami avversari, le celle valide per l'elemento attualmente selezionato nel deck, gli sciami giunti come rinforzo nel turno corrente, gli ostacoli quando presenti.

7.3 Elenco proposto per la mappa di campagna: le proprie formazioni, le formazioni avversarie note, le installazioni, le caselle da cui è possibile esplorare, le informazioni di ricognizione scadute, le battaglie in sospeso in tutte le campagne, gli eventi del turno.

7.4 Entrambi gli elenchi sono proposte e vanno confermati o corretti. Il rotore delle battaglie in sospeso ha carattere trasversale e deve funzionare anche da una campagna diversa da quella in cui la battaglia si trova.

## 8. Schieramento e deck

8.1 Il deck è un elenco posto sotto la griglia, contenente gli sciami disponibili. Si seleziona un elemento, si naviga fino alla cella, si conferma. Nessun trascinamento come manipolazione, in alcun punto del gioco.

8.2 Ogni elemento del deck si annuncia con il proprio archetipo, il numero di atomi dell'assetto, il volume, e l'indicazione di rinforzo quando si tratta di forze giunte in corso di battaglia.

8.3 Ogni conferma su una cella piazza un esemplare dell'elemento selezionato. Se restano altri esemplari, il piazzamento su celle successive avviene con conferme successive, senza dover riselezionare.

8.4 I comandi di annullamento dell'ultima operazione e di azzeramento completo dello schieramento sono obbligatori. Nell'ordine di lettura seguono immediatamente il deck, e sono quindi raggiungibili a scorrimenti oltre che al tatto.

8.5 I due comandi non sono collocati a ridosso del bordo inferiore dello schermo, dove la striscia estrema è riservata al gesto di sistema per uscire dall'applicazione. Sono distanziati dal bordo e di altezza piena.

8.6 Uno schieramento proposto dal gioco, applicabile con una sola operazione e successivamente modificabile, è previsto come comodità per qualunque giocatore. Non è una misura di parità.

## 9. Interazione tra celle

9.1 Le operazioni che coinvolgono due celle, come ordinare a uno sciame di attaccare un determinato sciame avversario tra più bersagli possibili, si compiono attivando la cella della propria unità e successivamente la cella del bersaglio, con l'apertura del pannello di conferma.

9.2 Da definire. La sequenza esatta di attivazione, il comportamento in caso di annullamento a metà operazione, la modalità con cui il pannello elenca i bersagli disponibili quando il giocatore preferisce sceglierli da un elenco anziché navigare fino alla cella, e il modo in cui viene segnalato che un'unità è in attesa di un bersaglio.

## 10. Dimensioni e disposizione sullo schermo

10.1 La griglia da cento celle non viene compressa a forza entro lo schermo di un telefono. Ne risulterebbero bersagli inferiori alla dimensione minima raccomandata, e l'esplorazione al tatto diventerebbe imprecisa, con annunci che si accavallano.

10.2 La griglia è ingrandibile e scorrevole. Tutte le celle restano raggiungibili a scorrimenti anche quando si trovano fuori dalla porzione visibile, e il fuoco che si sposta su una cella non visibile fa scorrere la vista di conseguenza.

10.3 Nessuna tabella a caselle nelle schermate di gestione. Ogni riga di dati è un unico elemento accessibile, che si annuncia in una frase compatta comprensiva dei suoi valori e che, attivato, apre il dettaglio. Chi guarda legge una tabella, chi ascolta sente un elenco di frasi, e i dati sottostanti sono gli stessi.

## 11. Vocabolario tattile

11.1 Il motore aptico avanzato esiste soltanto su telefono. Sui tablet lo strato tattile non esiste e non è aggirabile. Nessuna informazione è quindi trasmessa esclusivamente per via tattile: ogni segnale ha sempre una controparte sonora o testuale.

11.2 Un solo punto centrale del programma riceve gli eventi di gioco in forma astratta e decide quali canali attivare in base all'apparecchio e alle preferenze. Il resto del programma non contiene alcun riferimento a vibrazioni, suoni o annunci.

11.3 Tavolozza disponibile. Tre livelli di nitidezza nettamente distinti; due o tre livelli di intensità; una serie di ritmi costituiti da impulsi singoli, doppi, tripli, quadrupli e da combinazioni semplici del tipo singolo, doppio, singolo, comunque non superiori a quattro o cinque impulsi complessivi.

11.4 Regola di struttura, vincolante. Le tre dimensioni non sono intercambiabili. Il ritmo, cioè il numero e la disposizione degli impulsi, identifica il genere dell'evento, per esempio spostamento, combattimento, risorsa, allarme. La nitidezza e l'intensità esprimono soltanto la gradazione o il segno all'interno di quel genere, per esempio esito favorevole o sfavorevole, entità piccola o grande. Il giocatore impara così quattro o cinque famiglie ritmiche e ne deduce le sfumature, invece di dover memorizzare decine di segnali indipendenti.

11.5 Le combinazioni matematicamente possibili superano il numero di segnali che un polpastrello distingue in modo affidabile e che una persona impara. Per la prima versione i significati effettivamente assegnati non superano i dodici o quindici, anche se la tavolozza ne consentirebbe molti di più. L'insieme potrà essere ampliato dopo aver osservato quali segnali servono davvero.

11.6 Il ritmo e la durata sono percepiti in modo affidabile in qualunque condizione d'uso; l'intensità e la nitidezza si confondono quando l'apparecchio è appoggiato, tenuto con una mano sola o dentro una custodia spessa. Da qui il ruolo subordinato assegnato a queste due dimensioni.

11.7 Da definire in fase di progettazione architetturale. L'assegnazione dei significati ai singoli pattern, cioè quali eventi del gioco meritino un segnale tattile e quale pattern venga assegnato a ciascuno. La decisione richiede la visione d'insieme di tutti gli eventi comunicabili e viene presa quando tale insieme è completo. La struttura della sezione 11.4 e il tetto della sezione 11.5 restano vincolanti.

11.8 I pattern risiedono in un file di dati separato, con nomi parlanti e parametri modificabili senza ricompilare.

11.9 Vincoli tecnici. La vibrazione è disattivata dal sistema in modalità di risparmio energetico. Il motore aptico va mantenuto pronto anziché acceso e spento a ogni evento, altrimenti il primo impulso arriva in ritardo e la sincronia con il suono si perde.

## 12. Vocabolario sonoro

12.1 Il vocabolario sonoro è costruito in parallelo a quello tattile e secondo le stesse famiglie. Sui tablet il suono è l'unico canale non testuale disponibile, e chi ha imparato un sistema deve averli imparati entrambi.

12.2 I suoni sono brevi, riconoscibili e privi di parole. Sono impiegati per esiti, cambiamenti di stato, cambi di riga, arrivo di rinforzi, e per l'ambiente sonoro, che cambia con la fase storica.

12.3 Nessuna narrazione registrata o sintetizzata sostituisce gli annunci. I testi restano testo e li legge VoiceOver con la voce, la lingua e la velocità scelte dall'utente.

12.4 Qualunque informazione affidata a un suono senza parole è recuperabile anche in forma testuale su richiesta. Un suono si può perdere, un testo si può rileggere.

## 13. Schermata di apprendimento dei segnali

13.1 Le impostazioni contengono una schermata in cui ogni segnale tattile e sonoro può essere riascoltato e risentito singolarmente, con accanto il proprio significato in forma scritta.

13.2 Con una dozzina di segnali distinti questa schermata non è un accessorio: è il solo modo di apprendere il linguaggio senza doverlo indovinare giocando.

## 14. Impostazioni di accessibilità

14.1 Livello di verbosità degli annunci: sintetico, normale, dettagliato.

14.2 Attivazione e disattivazione indipendenti del canale tattile e del canale sonoro non verbale.

14.3 Da definire. Eventuale regolazione dell'intensità complessiva dei segnali tattili, eventuale scelta tra insiemi sonori alternativi, e ogni altra preferenza che emerga dalle prove con i tester.

## 15. Testi e localizzazione

15.1 Tutti i testi, compresi gli annunci, risiedono fuori dal programma dal primo giorno. Nessuna stringa è scritta nel codice, nemmeno in via provvisoria.

15.2 Ogni annuncio è una frase intera con segnaposto da riempire, mai una somma di parole concatenate. In italiano i componenti si accordano per genere e numero, in inglese quasi mai: un annuncio costruito incollando parole produce frasi sgrammaticate nella lingua diversa da quella in cui è stato pensato.

15.3 I plurali sono gestiti dal meccanismo di localizzazione del sistema e non con condizioni scritte a mano.

15.4 Ogni testo dichiara la propria lingua. Senza questa indicazione, un giocatore che usa VoiceOver con una voce inglese e gioca in italiano riceve una lettura incomprensibile. È un'indicazione minima per ciascun annuncio e va inserita dall'inizio: aggiungerla in seguito su centinaia di annunci è un lavoro cieco e incompleto per definizione.

## 16. Verifica

16.1 La verifica dell'accessibilità non si compie da soli. Tester non vedenti reali sono coinvolti tramite distribuzione di prova dal primo prototipo giocabile, non alla fine.

16.2 La prova in prima persona con VoiceOver attivo è utile ma insufficiente: chi ha progettato il gioco sa già dove si trovano le cose.

16.3 Il primo prototipo sottoposto ai tester è un singolo scontro completo, dalla schermata iniziale alla battaglia conclusa, prima che il piano di campagna venga costruito.

---

## 17. Riepilogo dei punti aperti

17.1 Da definire prima della realizzazione della parte corrispondente. I gradi e i termini che esprimono la probabilità, punto 4.4. La sequenza di interazione tra due celle e la gestione dei bersagli, punto 9.2. L'assegnazione dei significati ai pattern tattili, punto 11.7. Le preferenze aggiuntive nelle impostazioni, punto 14.3.

17.2 Da confermare o correggere. L'elenco dei rotori del campo di battaglia e della mappa di campagna, punti 7.2 e 7.3. L'ordine delle informazioni che seguono la testa fissa dell'annuncio di cella, punto 3.8, che una volta scelto va registrato qui e rispettato ovunque.

17.3 Escluso dalla prima versione. La modalità di esplorazione libera con area a tocco diretto, punto 2.12.
