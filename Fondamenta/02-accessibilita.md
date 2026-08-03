# Documento di accessibilità

Documento 02 di 05 — versione 2.2

Novità della versione 2.2, per decisione del titolare dopo la prima prova su dispositivo della fase B (prima tranche di semplificazioni; le modifiche sono volute): gli stati di gittata escono dal vocabolario chiuso, sostituiti dalla distinzione binaria fra bersaglio a portata e fuori portata (3.7.2, 4.4.5), in conseguenza della gittata unica di 01 §3.4.1; ogni reparto in campo si annuncia e si mostra con la propria lettera stabile (3.8.1, 4.4.5, 9.2.1; regola in 01 §9.4.3); il pannello di tiro non offre più la scelta del proiettile, che è proprietà fissa del reparto (9.3; 01 §3.3.1); gli esiti dei combattimenti si annunciano in fasce descrittive del vocabolario chiuso, senza numeri di danno (8.9, 4.4.5; 01 §9.7.2); il volume dell'avversario non compare in alcuna forma (6.4.1; 01 §9.3.7); un'azione impossibile in ogni sua forma non viene offerta (9.5).

Novità della versione 2.1, prodotta nella fase di architettura tecnica su delega del titolare: chiusura di tutti i punti da definire e da confermare dei punti 17.1 e 17.2 della versione 2.0. In particolare: termini di tutti gli insiemi del vocabolario chiuso (4.4.5); annuncio delle due gittate (3.7.2); ordine delle informazioni dopo la testa fissa (3.8.1); formato dell'annuncio dei gruppi che hanno agito (6.5.1.3); gesti fissi e passaggio diretto fra campagne (6.7); elenchi dei rotori confermati con una aggiunta (7.2, 7.3, 7.4); sequenza di interazione fra due celle (9.2.1); assegnazione dei significati ai pattern tattili (11.7.1); impostazioni della prima versione (14.3). Le motivazioni sono nel registro delle decisioni architetturali. Nessuna decisione della versione 2.0 è stata riaperta.

## Come leggere questo documento

Questo documento stabilisce come le informazioni del gioco vengono presentate e come il giocatore agisce. È il documento da consultare per qualunque lavoro sull'interfaccia, sugli annunci, sui gesti, sui segnali tattili e sonori.

Va letto insieme alla carta dei principi non negoziabili, che prevale in caso di conflitto, e insieme al documento 01 per ciò che riguarda le regole di gioco sottostanti.

Questa versione recepisce le direzioni di progettazione della fase tre, e in particolare: gli stati dei gruppi sulla mappa di campagna e quelli di rifornimento, il registro degli eventi, l'architettura a tre livelli fra patria, campagne e mappa, il formato dell'annuncio del costo nelle schermate invernali, l'annuncio della mischia complessiva e quello della portata di ingaggio.

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

3.5 I motivi di non disponibilità sono tre e soltanto tre, secondo il punto 8.9 del documento 01: profondità eccessiva rispetto al volume disponibile nel turno, cella già occupata, cella non interattiva perché parte di un ostacolo. I termini che li esprimono appartengono al vocabolario chiuso della sezione 4 e non ammettono varianti.

3.5.2 Poiché non esiste una fase di schieramento separata e il deck resta attingibile per tutta la battaglia, secondo il punto 8.1 del documento 01, questi annunci valgono identici in ogni turno e non soltanto all'apertura dello scontro.

3.5.1 Le mura di una piazzaforte, che sono un ostacolo esteso e determinante ai sensi del punto 7.5.1 del documento 01, si annunciano con il medesimo termine chiuso riservato agli ostacoli. La differenza di rilievo tattico non produce una differenza di vocabolario.

3.6 Quando il piazzamento è possibile, l'annuncio dichiara il costo in volume dell'operazione e il volume che resterebbe dopo averla compiuta, prima della conferma. Chi guarda dispone di una barra che si consuma e di celle differenziate per fascia di costo; la parità si ottiene dicendolo.

3.7 Le celle occupate da un ostacolo sono annunciate immediatamente come tali e non sono interattive.

3.7.1 Sciami misti. Uno sciame di assetto misto si annuncia con il proprio nome di assetto e mai con l'elenco dei suoi componenti. Un annuncio che enumerasse la composizione trasformerebbe ogni voce del deck e ogni cella occupata in una frase lunga, rendendo impraticabile la scansione rapida di riga di cui alla sezione 6.

3.7.2 Portata binaria (versione 2.2, in conseguenza della gittata unica di 01 §3.4.1). La disponibilità di un bersaglio per il tiro è binaria: a portata oppure fuori portata, con i termini chiusi del punto 4.4.5. Il pannello dell'ordine di tiro elenca soltanto i bersagli a portata, ciascuno designato con la propria lettera; ciò che è fuori portata non compare fra le voci, e l'attivazione di una cella fuori portata durante una designazione ne dichiara il motivo con il termine chiuso. Nessun termine di gittata graduato esiste più in alcun punto del gioco.

3.7.3 Munizioni. La dotazione residua di un reparto da tiro è informazione che chi guarda riceverebbe a colpo d'occhio, e va quindi dichiarata. Rientra fra le informazioni di stato dell'unità e non nella testa fissa dell'annuncio di cella.

3.8 Il resto del contenuto dell'annuncio, cioè quali informazioni sulla cella seguano la testa fissa e in quale ordine, è stato scelto una volta sola nella fase di architettura, è registrato al punto 3.8.1 e va rispettato in ogni schermata del gioco. Il principio 7 vieta che due schermate annuncino le stesse cose in ordine diverso. L'ordine potrà essere rivisto dopo le prime prove di gioco, ma sempre come modifica unica e globale di questo punto.

3.8.1 Ordine registrato, identico sui due piani; le voci che non si applicano si saltano senza lasciare traccia. Dopo la testa fissa: prima lo stato di conoscenza, se diverso da confermato, con l'età dell'informazione (solo mappa di campagna); poi l'occupante, con la propria lettera in posizione fissa subito dopo il nome (01 §9.4.3, versione 2.2) e il termine di stato che gli compete secondo la sezione 4; poi le anomalie dell'occupante, cioè rifornimento, munizioni, controllo, manutenzione, nell'ordine in cui sono qui nominate; poi le opere presenti nella casella; poi il terreno e il tipo di strada (solo mappa di campagna, dove la casella lo dichiara secondo il punto 5.14.4.1 del documento 01); infine le note di zona, cioè zona di rifornimento e strettoia. I livelli di verbosità tagliano dalla coda, secondo il punto 3.9; la condizione ordinaria non si annuncia, secondo il criterio del punto 8.7.1.

3.9 Livelli di verbosità. Le impostazioni offrono tre livelli: sintetico, normale, dettagliato. L'ordine di priorità delle informazioni è fisso e dichiarato, così che nei livelli più brevi si taglino le ultime voci e non porzioni arbitrarie. La testa fissa della sezione 3.2 e 3.3 non è mai tagliata, in nessun livello.

3.10 Nel livello sintetico l'annuncio di una cella vuota deve restare dell'ordine di poche parole. Da questo dipende la praticabilità della scansione rapida di riga descritta alla sezione 6.

## 4. Vocabolario chiuso

4.1 Gli stati ricorrenti del gioco sono espressi con un insieme chiuso di termini, fissi e identici in ogni punto del gioco. I termini sono segnali, non frasi: nessun sinonimo, nessuna variazione stilistica, nessuna riformulazione contestuale.

4.2 Stati di conoscenza sulla mappa di campagna: inesplorato, presunto, avvistato seguito dal numero di turni trascorsi, confermato.

4.3 Motivi di non disponibilità di una cella: troppo avanzata, occupata, ostacolo.

4.4 Espressioni di probabilità, impiegate per lo stato di manutenzione e per il rischio di guasto, secondo il punto 12.3 del documento 01. Chiuso nella fase di architettura: gli stati di manutenzione di una macchina sono tre — efficiente, cioè possibilità di guasto bassa; logora, cioè possibilità di guasto alta; guasta, cioè ferma finché riparata — secondo il punto 5.7.1 del documento 01. Il linguaggio della probabilità è riservato ai guasti; l'avvicinarsi di una sortita, che è deterministica secondo il punto 8b.5.1 del documento 01, si esprime con i tre termini di imminenza: sortita lontana, sortita vicina, sortita imminente.

4.4.1 Il vocabolario chiuso si estende ai seguenti insiemi introdotti dalle regole di gioco consolidate. Stato di portata rispetto a un bersaglio, secondo il punto 3.7.2. Stato di controllo di un reparto, cioè se sia disponibile agli ordini oppure impegnato a contatto secondo il punto 9.5 del documento 01. Stato della dotazione di munizioni. Stagione in corso, secondo il punto 5.9 del documento 01. Caratteristica del campo di battaglia, secondo il punto 7.4 del documento 01. Le lettere dei reparti, secondo il punto 9.4.3 del documento 01. Le fasce descrittive degli esiti dei combattimenti, secondo il punto 9.7.2 del documento 01. I termini di ciascun insieme sono chiusi al punto 4.4.5, con il vincolo di invariabilità del punto 4.1.

4.4.1.1 Stati di un gruppo sulla mappa di campagna, secondo il punto 5.16.1 del documento 01: gruppo che non ha ancora agito nel turno; gruppo che ha già agito; gruppo impegnato in una marcia lunga, con i giorni mancanti; gruppo appostato con ordine di imboscata; gruppo che dispone ancora dello scatto di marcia forzata. I termini dei primi due e dell'ultimo devono essere brevi e non confondibili fra loro, poiché un gruppo con scatto residuo compare fra quelli da muovere pur avendo già marciato e l'annuncio deve dirne la ragione.

4.4.1.2 Stati di rifornimento di un gruppo, secondo il punto 5.2.2 del documento 01: gruppo senza provviste, con l'indicazione se si tratti del primo o del secondo turno consecutivo; gruppo in sosta di rifornimento, con i turni di sosta ancora dovuti; gruppo che si trova in una zona di rifornimento. Il gruppo rifornito, essendo la condizione ordinaria, non richiede menzione esplicita, in applicazione del criterio del punto 8.7.

4.4.1.3 Efficacia dell'offesa contro il bersaglio selezionato, secondo il punto 9.9.1 del documento 01. L'annuncio è qualitativo e non numerico e distingue soltanto fra offesa efficace e offesa poco efficace, tanto per il tiro quanto per la mischia. Il modello sottostante resta graduato e i suoi numeri non compaiono nell'annuncio.

4.4.1.4 Il termine che designa il denaro appartiene a un insieme che varia con la fase storica, secondo il punto 5.5.1.3 del documento 01. Poiché il giocatore deve riconoscerlo immediatamente come la stessa cosa di prima, la moneta compare sempre nella medesima posizione e con la medesima funzione dentro l'annuncio, cosicché a mutare sia una sola parola in una frase per il resto identica.

4.4.2 La caratteristica del campo è dichiarata una sola volta all'apertura della battaglia, insieme alla presenza di ostacoli secondo il punto 7.6 del documento 01, e resta richiamabile dall'informazione di stato della battaglia di cui al punto 6.4.

4.4.3 Lo stato di conoscenza di cui al punto 4.2 conserva la propria funzione anche a fronte dell'imboscata di posizione del punto 5.11 del documento 01. Il gioco non dichiara mai il falso: un gruppo appostato non è individuato perché la casella non è confermata, non perché il gioco abbia mentito sul suo stato. Il vocabolario resta quindi integralmente veritiero, e la sua affidabilità non ammette eccezioni in alcun punto.

4.4.4 Opacità di un turno sul campo di battaglia. Chi subisce un'imboscata agisce, nel proprio primo turno, senza vedere alcunché dello schieramento avversario; dall'inizio del turno successivo dell'imboscante il campo torna pienamente trasparente, secondo il punto 9.3.2.1 del documento 01. È l'unica eccezione alla trasparenza del campo e va annunciata come tale, dichiarando che le posizioni avversarie non sono note e che lo diverranno. La condizione non viola la parità: non riguarda il modo in cui l'informazione è resa disponibile, ma quale informazione il gioco nasconde, e la nasconde allo stesso modo a chiunque si trovi in quella situazione.

4.4.5 Termini chiusi, vincolanti in ogni punto del gioco. Stato di portata (versione 2.2, sostituisce gli stati di gittata): a portata; fuori portata. Lettere dei reparti (versione 2.2): le lettere dell'alfabeto in ordine fisso, A, B, C e seguenti, assegnate per ordine di piazzamento dentro ciascuno schieramento e mai riusate (01 §9.4.3); esaurite le singole, seguono le doppie in ordine fisso. Fasce degli esiti dei combattimenti (versione 2.2, 01 §9.7.2): stallo, per il contatto senza perdite da ambo i lati; per ciascuna direzione, nessuna perdita, perdite lievi, perdite significative, perdite gravi, declinate come inflitte e come subite. Stato di controllo: disponibile; impegnato. Dotazione di munizioni: munizioni piene; munizioni scarse; munizioni esaurite. Stagioni: primavera; estate; autunno; inverno. Caratteristica del campo: il nome fisso dichiarato per ciascuna caratteristica nel file dei valori, uno per caratteristica, mai variato. Stati di un gruppo: in attesa; ha agito; in marcia, con i giorni mancanti; in agguato; scatto disponibile. Stati di rifornimento: senza provviste, primo giorno; senza provviste, secondo giorno; in sosta di rifornimento, con i giorni di sosta dovuti; in zona di rifornimento. Efficacia dell'offesa: efficace; poco efficace. Manutenzione e imminenza della sortita: i termini del punto 4.4. I termini brevi e non confondibili richiesti dal punto 4.4.1.1 sono in attesa e scatto disponibile, che non condividono alcuna parola.

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

6.4.1 Il volume dell'avversario non compare in alcuna forma (versione 2.2; 01 §9.3.7): né qui, né negli annunci degli eventi avversari, né in pannelli, riepiloghi, rotori o resoconti. Gli annunci delle azioni avversarie dichiarano il fatto — che cosa è entrato o si è mosso, e dove — senza numeri di volume.

6.5 Informazione di stato della campagna, dichiarata all'apertura della schermata di campagna. Se una battaglia è in sospeso, lo stato lo dichiara e indica dove. Ogni comando bloccato dichiara il medesimo motivo, cioè la battaglia in sospeso, così che il giocatore non debba ricostruirlo per tentativi.

6.5.1 Poiché ciascun gruppo dispone di un'azione al giorno secondo il punto 5.6 del documento 01, l'informazione di stato della campagna dichiara quanti gruppi abbiano già agito nel turno e quanti no. Fra esploratori, colonna principale e distaccamenti il numero dei gruppi da seguire cresce rapidamente, e ricostruire per tentativi quali abbiano già agito è precisamente il tipo di operazione che il punto 1.2 vieta. Il formato è chiuso al punto 6.5.1.3; il salto diretto ai gruppi inattivi è il rotore del punto 7.3.

6.5.1.3 Formato chiuso nella fase di architettura, con ordine fisso e tagli di verbosità dalla coda: giorno e stagione; gruppi che hanno agito sul totale; gruppi in marcia, con il termine chiuso del punto 4.4.5; gruppi con scatto disponibile, se ve ne sono; gruppi senza provviste, se ve ne sono; battaglie in sospeso e dove; avviso di avvicinamento al blocco fra campagne, quando ricorre. Le condizioni assenti non si nominano, secondo il criterio del punto 8.7.1.

6.5.1.1 L'orientamento durante la giornata è affidato a tre strati distinti che non si duplicano, secondo il punto 5.16 del documento 01: l'informazione di stato, richiamabile con un gesto fisso senza abbandonare la mappa; lo strumento di salto diretto al prossimo gruppo che non ha ancora agito; la dichiarazione dello stato da parte del gruppo stesso ogni volta che il giocatore lo incontra. I tre rispondono a tre domande diverse, cioè quanto manca alla fine della giornata, dove andare adesso, che cosa stia facendo quel gruppo.

6.5.1.2 L'informazione di stato dichiara a parte i gruppi impegnati in una marcia lunga, che hanno l'azione consumata ma non spesa dal giocatore in quella giornata, e la presenza di gruppi con scatto di marcia forzata ancora disponibile, poiché è l'unica cosa che il giocatore possa perdere per distrazione.

6.5.4 Architettura a tre livelli. La navigazione si articola su patria, schermata delle campagne e mappa della singola campagna, secondo il punto 5.6.10 del documento 01. La patria è la schermata di partenza all'avvio e resta sempre raggiungibile senza mai chiedere di essere visitata.

6.5.4.1 La schermata delle campagne è la sede dell'informazione di stato complessiva, ed è articolata per fronti e, dentro ciascun fronte, per località attive. Vi si dichiarano quali campagne abbiano gruppi ancora da muovere, quale sia bloccata per avere raggiunto lo scarto massimo e quale sia rimasta indietro.

6.5.4.2 Una campagna bloccata dichiara di esserlo appena vi si entra, indicando la ragione e quale campagna sia rimasta indietro; il gioco avvisa inoltre quando la distanza si avvicina al limite. Senza il primo annuncio, chi non vede lo stato complessivo non ha modo di distinguere fra una campagna bloccata, una in cui ha già mosso tutti e un malfunzionamento.

6.5.4.3 I riferimenti temporali compaiono in alto tanto in patria quanto nella mappa di campagna. La mappa mostra la data della propria campagna, la patria la data più arretrata fra tutte le campagne aperte, la schermata delle campagne la data di ciascuna insieme allo scarto rispetto alle altre.

6.5.4.4 Il gesto fisso di risalita fra i tre livelli e il passaggio diretto da una campagna all'altra sono chiusi al punto 6.7.

6.6 Registro degli eventi. Ogni campagna dispone del proprio registro cronologico e la patria del proprio, secondo il punto 5.17 del documento 01. Il registro non è una tabella né un blocco unico di testo: ogni voce è un elemento accessibile a sé, che si annuncia in una frase compiuta, dichiara il giorno cui si riferisce e consente, attivandola, di portare il fuoco sul luogo del fatto. L'ordine è dal più recente al meno recente, così che scorrendo si vada indietro nel tempo e ci si fermi alle cose già sentite.

6.6.1 Il registro è la sede in cui si recupera in forma testuale ciò che è stato annunciato mentre il giocatore era altrove, in applicazione del punto 6.4 della carta. Per chi ascolta vale quindi più che per chi vede, poiché chi guarda ha il riquadro davanti e vi torna con lo sguardo.

6.6.2 Vi entrano soltanto i fatti che il giocatore non ha deciso, secondo il punto 5.17.1 del documento 01. Non vi entrano i propri ordini. Il riquadro narrativo del passaggio di fase non vi entra, poiché riguarda il regno e non una singola guerra, e si chiude con un comando di conferma senza limiti di tempo.

6.5.2 L'informazione di stato della campagna dichiara inoltre la stagione in corso e, quando la pausa invernale è attiva, il fatto che le operazioni di campagna siano sospese e quali attività restino disponibili in patria.

6.5.3 Un gruppo in attesa con ordine di imboscata secondo il punto 5.11 del documento 01 si annuncia come tale, poiché il suo stato non è deducibile dal fatto che sia fermo.

6.7 Gesti fissi, chiusi nella fase di architettura. Tre gesti, identici in tutto il gioco. Il tocco magico a due dita richiama l'informazione di stato del contesto corrente, cioè della battaglia secondo il punto 6.4 o della campagna secondo il punto 6.5, senza abbandonare la griglia e senza spostare il fuoco. Il gesto di fuga a due dita, quello di sistema, risale di un livello: dal pannello alla griglia, dalla mappa alla schermata delle campagne, da questa alla patria. Il passaggio diretto da una campagna all'altra avviene con il rotore delle campagne attive del punto 7.3, che salta alla campagna successiva non bloccata; non occupa quindi alcuna azione personalizzata, e il vincolo del punto 2.5 sul numero e sul contenuto delle azioni personalizzate resta intatto.

## 7. Rotori

7.1 I rotori personalizzati consentono di saltare direttamente agli elementi di un insieme. Non sono una comodità accessoria: percorrere una griglia un passo alla volta è sempre lento, e su cento celle diventa impraticabile. Sono il principale strumento di parità nell'accesso a una superficie estesa.

7.2 Elenco confermato nella fase di architettura per il campo di battaglia: i propri sciami; i propri sciami con azione non ancora spesa nel turno; gli sciami avversari; le celle valide per l'elemento attualmente selezionato nel deck; gli sciami giunti come rinforzo nel turno corrente; gli ostacoli quando presenti. Il rotore dei propri sciami con azione non spesa è l'unica aggiunta all'elenco proposto: poiché ogni reparto dispone di una azione per turno secondo il punto 9.5.0 del documento 01, ritrovare chi non ha ancora agito è la stessa esigenza di parità che il punto 6.5.1 riconosce sulla mappa di campagna, e chi guarda la soddisfa con un'occhiata al campo.

7.3 Elenco confermato nella fase di architettura per la mappa di campagna: le proprie formazioni, i propri gruppi che non hanno ancora agito nel turno, i propri gruppi con scatto di marcia forzata ancora disponibile, i propri gruppi senza rifornimento, le formazioni avversarie note, le installazioni, le piazzeforti e le opere permanenti proprie e note, le caselle da cui è possibile esplorare, le caselle boscose in cui è possibile costruire, le informazioni di ricognizione scadute, le battaglie in sospeso in tutte le campagne, le voci del registro degli eventi non ancora consultate, e le campagne attive, che è il rotore con cui si passa direttamente da una campagna all'altra secondo il punto 6.7.

7.3.1 Il rotore dei gruppi che non hanno ancora agito non è una comodità ma la contropartita diretta della struttura a un'azione per gruppo, secondo il punto 6.5.1.

7.4 Entrambi gli elenchi sono confermati nella fase di architettura, con la sola aggiunta dichiarata al punto 7.2 e il rotore delle campagne attive al punto 7.3. I rotori delle battaglie in sospeso e delle campagne attive hanno carattere trasversale e funzionano anche da una campagna diversa da quella interessata. L'ordine interno di ciascun rotore è deterministico e fisso: per posizione nell'ordine di lettura per gli insiemi di celle, per nome per i gruppi, dal più recente per registro e battaglie.

## 8. Schieramento e deck

8.1 Il deck è un elenco posto sotto la griglia, contenente gli sciami disponibili. Si seleziona un elemento, si naviga fino alla cella, si conferma. Nessun trascinamento come manipolazione, in alcun punto del gioco.

8.2 Ogni elemento del deck si annuncia con il proprio archetipo o nome di assetto, il numero di atomi dell'assetto, il volume, e l'indicazione di rinforzo quando si tratta di forze giunte in corso di battaglia. Per gli sciami misti vale il punto 3.7.1.

8.2.1 Il deck resta utilizzabile per tutta la durata dello scontro secondo il punto 9.3.5 del documento 01, ed è il canale attraverso cui passa la sorpresa, poiché il campo è trasparente ma le riserve avversarie sono ignote. L'ingresso in campo di forze avversarie precedentemente trattenute è quindi annunciato esplicitamente al pari di ogni altro cambiamento di stato rilevante, senza rubare il fuoco.

8.3 Ogni conferma su una cella piazza un esemplare dell'elemento selezionato. Se restano altri esemplari, il piazzamento su celle successive avviene con conferme successive, senza dover riselezionare.

8.4 I comandi di annullamento dell'ultima operazione e di azzeramento completo dello schieramento sono obbligatori. Nell'ordine di lettura seguono immediatamente il deck, e sono quindi raggiungibili a scorrimenti oltre che al tatto.

8.5 I due comandi non sono collocati a ridosso del bordo inferiore dello schermo, dove la striscia estrema è riservata al gesto di sistema per uscire dall'applicazione. Sono distanziati dal bordo e di altezza piena.

8.6 Uno schieramento proposto dal gioco, applicabile con una sola operazione e successivamente modificabile, è previsto come comodità per qualunque giocatore. Non è una misura di parità.

8.7 Annuncio del costo nelle schermate di spesa. Nelle schermate invernali e in ogni altra schermata in cui si acquistano lavori o miglioramenti, ciascuna voce dichiara il costo insieme alla riserva complessiva di ciascuna risorsa impiegata, nella forma che dice quanto costa su quanto se ne possiede. Ciascuna voce dichiara soltanto le risorse che quel lavoro consuma effettivamente, e non tutte e cinque. Il carico dell'ascolto non nasce infatti dal numero delle risorse ma dal dover tenere a mente le riserve mentre si valutano le voci: se ogni voce si porta dietro la propria riserva, il giocatore decide sentendo una frase sola.

8.7.1 L'esito non va annunciato quando è positivo. Una voce acquistabile non dichiara di esserlo, poiché il fatto che sia presente e priva di impedimenti lo comunica già; va invece annunciata prontamente l'impossibilità di acquistare, con l'indicazione di quale risorsa manchi. Un elenco in cui solo alcune voci recano un impedimento dichiarato è molto più rapido da percorrere.

8.7.2 Esiste inoltre un riquadro delle riserve, navigabile per scorrimento voce per voce, che raggruppa quanto si possiede in valore assoluto. È la vista d'insieme che serve a orientarsi, distinta dalla dichiarazione per voce che serve a decidere.

8.7.3 Le quattro schermate invernali contengono sempre tutte le voci, ripartite in linguette ordinate per durata dei lavori, secondo il punto 5.9.1.3 del documento 01. La struttura non cambia da una schermata all'altra: il giocatore ne impara una sola e la ritrova identica quattro volte. Quando si ordina un lavoro, il gioco dichiara quando sarà pronto e non quanto dura.

8.8 Annuncio della disponibilità di ingaggio. Poiché non esiste alcun attacco automatico e l'ingaggio si rende disponibile al ricorrere di una condizione di portata, secondo il punto 9.5.0 del documento 01, la disponibilità dell'ingaggio è dichiarata quando si incontra il reparto, insieme ai bersagli che essa consente di raggiungere. Il giocatore non deve dedurre la portata né verificarla cella per cella.

8.9 Annuncio della mischia. L'esito dei combattimenti a contatto è annunciato in una sola comunicazione ordinata all'inizio del turno, comprensiva di tutti i contatti in corso, e non con un annuncio per ciascuna mischia. Il dettaglio di ciascun contatto resta consultabile atterrando sulla cella interessata. Con quattro o cinque contatti simultanei, l'annuncio per singola mischia renderebbe l'inizio di ogni turno una lista di perdite da ascoltare.

8.9.1 Fasce descrittive (versione 2.2; 01 §9.7.2). Ogni contatto dell'annuncio complessivo, e ogni esito di tiro, si esprime con le fasce chiuse del punto 4.4.5 dal punto di vista del giocatore — perdite inflitte e perdite subite — e mai con numeri di danno. Il contatto senza perdite da ambo i lati si annuncia con il solo termine di stallo. La consistenza attuale di un reparto resta consultabile interrogando la sua cella, secondo il punto 3.8.1: il racconto dell'esito e il dato di consistenza sono due cose distinte.

## 9. Interazione tra celle

9.1 Le operazioni che coinvolgono due celle, come ordinare a uno sciame di attaccare un determinato sciame avversario tra più bersagli possibili, si compiono attivando la cella della propria unità e successivamente la cella del bersaglio, con l'apertura del pannello di conferma.

9.2 La sequenza è chiusa al punto 9.2.1.

9.2.1 Chiuso nella fase di architettura; aggiornato nella versione 2.2 per la portata binaria e le lettere. L'attivazione della cella della propria unità apre il pannello, che elenca le azioni possibili; per le azioni con bersaglio il pannello offre due vie equivalenti. La prima è l'elenco dei bersagli a portata, ciascuno come voce che annuncia il bersaglio con nome e lettera, l'efficacia e ogni costo; l'attivazione della voce conferma. La seconda è la designazione sulla griglia: si sceglie la voce di designazione, il pannello si chiude, il fuoco resta sulla cella dell'unità, si naviga fino alla cella del bersaglio e la si attiva, il che apre il pannello di conferma con le stesse informazioni. Durante la designazione l'unità si annuncia in attesa di bersaglio, e l'informazione di stato lo dichiara. L'attivazione di una cella non valida come bersaglio annuncia il motivo e non annulla la designazione; la designazione si annulla con l'apposita voce del pannello, con il gesto di fuga, oppure automaticamente selezionando un altro elemento del deck o attivando un'altra propria unità, e l'annullamento è annunciato senza spostare il fuoco.

9.3 Ordine di tiro. Poiché il tiro non è un automatismo e la dotazione è limitata secondo i punti 3.4.3 e 9.6 del documento 01, far tirare un reparto è un'operazione esplicita che il giocatore compie o omette a ogni turno. Il pannello della cella elenca i soli bersagli a portata, ciascuno designato con nome e lettera (01 §9.4.3), con l'efficacia qualitativa del reparto contro quel bersaglio (01 §9.9.1); nessuna scelta di proiettile, che è proprietà fissa del reparto (01 §3.3.1, versione 2.2). La dotazione residua resta dichiarata fra le informazioni del reparto secondo il punto 3.7.3.

9.4 Reparti non controllabili. Un reparto impegnato a contatto secondo il punto 9.5 del documento 01 non accetta ordini. Il suo stato è dichiarato nell'annuncio della cella con il termine chiuso di cui al punto 4.4.1, e il pannello non presenta comandi che risulterebbero inefficaci. Il ritorno alla controllabilità è annunciato come cambiamento di stato rilevante, senza spostare il fuoco.

9.5 Azioni impossibili non offerte (versione 2.2, per decisione del titolare). Un'azione che non è eseguibile in alcuna sua forma non compare fra le azioni del reparto: in particolare, lo spostamento non si offre quando il volume residuo non consente di raggiungere alcuna destinazione. Scoprire l'impossibilità soltanto dopo aver scelto l'azione, dovendo poi annullare, è un giro che a voce costa moltissimo. Resta fermo il comportamento di 9.2.1 quando alcune destinazioni sono raggiungibili e altre no: la cella non raggiungibile continua a dichiarare il motivo, perché serve a capire il campo. Il criterio è generale e vale per qualunque azione presente e futura.

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

11.7 L'assegnazione dei significati ai singoli pattern è chiusa al punto 11.7.1, nel rispetto della struttura del punto 11.4 e del tetto del punto 11.5.

11.7.1 Assegnazione chiusa nella fase di architettura: cinque famiglie ritmiche, quindici significati. I parametri fini di ciascun pattern risiedono nel file dei dati secondo il punto 11.8, e ogni segnale ha la propria controparte sonora e il proprio testo. Famiglia della navigazione, impulso singolo: cambio di riga (significato 1, con intensità alta al passaggio su una riga contenente forze avversarie); completamento di una marcia lunga (significato 2, nitidezza alta). Famiglia della conferma, impulso doppio ravvicinato: piazzamento oppure ordine confermato (3); annullamento oppure azzeramento eseguito (4, intensità bassa). Famiglia del combattimento, impulso triplo: esito di mischia complessivo favorevole (5, intensità alta) oppure sfavorevole (6, intensità bassa); disingaggio di un reparto (7, nitidezza bassa). Famiglia delle risorse, impulso doppio distanziato: munizioni esaurite (8); elemento del deck esaurito (9); rifornimento interrotto (10); risorsa insufficiente in una schermata di spesa (11). Famiglia dell'allarme, sequenza singolo-doppio-singolo: imboscata scattata (12); nuova battaglia in sospeso (13); sortita dalla piazzaforte (14); vincolo di campagna, cioè avviso di avvicinamento al blocco oppure blocco per scarto massimo (15). Gli eventi comunicabili rimasti fuori dal tetto — arrivo dei rinforzi nel deck, cambio di stagione, passaggio di fase, ritorno alla controllabilità di un reparto — hanno segnale sonoro dedicato e annuncio, senza segnale tattile; la selezione rispetta il punto 17.2.1.

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

14.3 Chiuso nella fase di architettura, per la prima versione: regolazione dell'intensità complessiva dei segnali tattili su tre passi; volume degli effetti sonori e volume dell'ambiente e della musica, regolabili separatamente; attivazione e disattivazione della musica. Gli insiemi sonori alternativi non entrano nella prima versione. Le preferenze che emergeranno dalle prove con i tester si aggiungeranno qui con una nuova versione di questo documento. Tutte le preferenze sono locali all'apparecchio e non fanno parte dello stato della partita.

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

17.1 Tutti i punti da definire della versione 2.0 sono stati chiusi nella fase di architettura per delega del titolare. Gradi e termini della probabilità: punto 4.4. Termini dei nuovi insiemi del vocabolario chiuso: punto 4.4.5. Annuncio delle due gittate: punto 3.7.2. Formato dell'annuncio dei gruppi che hanno agito: punto 6.5.1.3. Gesti di risalita e passaggio diretto fra campagne: punto 6.7. Sequenza di interazione fra due celle: punto 9.2.1. Assegnazione dei pattern tattili: punto 11.7.1. Impostazioni della prima versione: punto 14.3. Le motivazioni sono nel registro delle decisioni architetturali.

17.2 I punti da confermare della versione 2.0 sono confermati: gli elenchi dei rotori ai punti 7.2, 7.3 e 7.4, con l'aggiunta del rotore dei propri sciami con azione non spesa e del rotore delle campagne attive; l'ordine delle informazioni dopo la testa fissa, registrato al punto 3.8.1.

17.2.1 La verifica del tetto dei significati tattili è stata compiuta in sede di assegnazione: i significati assegnati sono quindici, entro il tetto del punto 11.5, e gli eventi rimasti fuori sono elencati al punto 11.7.1 con il loro canale sonoro e testuale.

17.3 Escluso dalla prima versione. La modalità di esplorazione libera con area a tocco diretto, punto 2.12.
