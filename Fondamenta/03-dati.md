# Documento dei dati

Documento 03 di 05 — versione 2.1

Novità della versione 2.1, in conseguenza della prima tranche di semplificazioni decisa dal titolare (01 versione 3.3): la grandezza critica 6.4, cioè l'ampiezza della fascia entro cui il tiro uccide, ha perso oggetto con la gittata unica ed è ridefinita come taratura della gittata utile unica; i coefficienti d'offesa si riferiscono al proiettile fisso di ciascun reparto (5.4); si aggiungono le soglie delle fasce descrittive degli esiti (nuovo punto 5.14), valori con contrassegno di provvisorietà.

Novità della versione 2.0, prodotta nella fase di architettura tecnica: aggiunta la sezione 9 con la struttura dei file dei valori e dei testi definita dal documento 05; aggiunte le grandezze introdotte dalle chiusure dei punti aperti, cioè conoscenza e ricognizione (4.8), stanchezza e manutenzione (4.9), sortita (4.10), soglia distribuita (4.7.3), meteo per stagione (4.11) e caratteristiche del campo (5.12). Come nella versione precedente, il documento registra quali grandezze esistono e quali vincoli rispettano, non i loro valori, che restano materia di taratura.

## Come leggere questo documento

Questo documento raccoglie i valori del gioco: intervalli, coefficienti, formule, regole di arrotondamento e grandezze da tarare. Non contiene regole di gioco, che stanno nel documento 01, né regole di presentazione, che stanno nel documento 02.

Va letto insieme alla carta dei principi non negoziabili, che prevale in caso di conflitto, e in particolare insieme al principio 13, che ne stabilisce i criteri costruttivi.

Il documento nasce come registro delle grandezze da determinare, non come tabella di numeri già stabiliti. Alla data di questa versione quasi nessun valore è fissato: ciò che è fissato è quali grandezze esistono, da dove provengono, quali vincoli devono rispettare e chi le deve determinare. Ogni voce indica la propria fonte, cioè il punto del documento 01 o della carta da cui discende.

Le voci sono divise per provenienza del valore: quelle che derivano dalla documentazione storica, quelle che sono decisioni di progetto e vanno annotate come tali, e quelle che si determinano soltanto con le simulazioni. La distinzione non è formale: un valore storico si discute con le fonti, una decisione di progetto si discute con il titolare, una grandezza da simulare non si discute affatto finché il programma di verifica non l'ha misurata.

---

## 1. Criteri costruttivi vincolanti

1.1 I valori stanno in file di dati separati dal programma, leggibili e modificabili senza ricompilare. Non esiste alcun pannello di regolazione dei valori dentro il gioco. Fonte: carta, principio 13.1.

1.2 I valori sono espressi il più possibile come rapporti e coefficienti riferiti a una base di fase, non come cifre indipendenti. Fonte: carta, principio 13.2.

1.3 Dove la documentazione storica fornisce un intervallo, l'intervallo va conservato e non schiacciato in una cifra sola. Ogni valore che ammette variazione è definito da un intervallo più una regola di variazione. Fonte: carta, principi 13.2.1 e 13.2.2.

1.4 Un valore si muove dentro la forbice soltanto per una causa dichiarata e riconoscibile. Fonte: carta, principio 13.2.3.

1.5 Ogni comportamento che dipende da più fattori è espresso da una formula unica condivisa più un coefficiente per tipo di elemento, mai da una tabella a doppia entrata. Fonte: carta, principio 13.3.

1.6 I coefficienti possono essere decimali nei file; i valori mostrati al giocatore sono sempre numeri interi, troncati per difetto, con minimo di uno dove il troncamento potrebbe dare zero. Fonte: carta, principi da 13.4 a 13.6.

1.7 Le grandezze di base sono scelte abbastanza grandi da rendere i decimali quasi sempre irrilevanti. Fonte: carta, principio 13.7.

1.8 Le simulazioni provano gli estremi degli intervalli e non una sola configurazione. Fonte: carta, principio 13.2.4.

## 2. Calibrazione della scala interna

2.1 Non viene dichiarata alcuna scala reale per i formati. La scala è interna e si fonda sui rapporti fra le misure storiche, non su una conversione lineare di unità. Fonte: carta, principi 12.5 e 12.6.

2.2 Ciò che deve risultare corretto sono i rapporti fra le grandezze, non i loro valori assoluti. La calibrazione è attenta e reiterata ed è materia di questo documento.

2.3 Portate e autonomie sono espresse in celle e in turni, mai in metri o in giorni reali. Fonte: carta, principio 12.4.

## 3. Differenze di partenza fra i regni

3.1 Le differenze di partenza fra un regno e l'altro, cioè quelle anteriori a qualunque miglioramento, sono fissate una volta sola e non riestratte a ogni partita. Fonte: carta, principio 13.2.3; documento 01, punto 16.3.

3.2 Da determinare: quali grandezze differiscano fra i regni, entro quale ampiezza, e con quale criterio di assegnazione.

## 4. Valori del piano di campagna

### 4.1 Marcia e terreno

4.1.1 Costo in giorni dello scatto fra due caselle, in funzione della natura della casella di partenza e di quella di arrivo, del tipo di strada e del volume complessivo della colonna. Fonte: documento 01, punti 5.6.3.1 e 5.6.3.2. Da determinare come intervallo con regola di variazione.

4.1.2 Pesi rispettivi della casella di partenza e della casella di arrivo nel calcolo del costo, che non sono necessariamente uguali. Fonte: documento 01, punto 5.6.3.2.

4.1.3 Costo fisso di transito della strettoia. Fonte: documento 01, punto 5.1.3.

4.1.4 Effetto del miglioramento delle vie di comunicazione sui valori di percorrenza e sulla velocità dei messaggeri. È il caso di riferimento del movimento di un valore dentro la propria forbice per causa dichiarata. Fonte: documento 01, punti 2.6.5 e 5.14.4.

### 4.2 Marcia forzata

4.2.1 Tetto ai turni consecutivi di marcia forzata, fissato in due o tre. È decisione di progetto e non dato storico, poiché la durata massima sostenibile non è documentata per alcuna fase, e va annotato come tale. Fonte: documento 01, punto 5.6.4.

4.2.2 Curva del logoramento più che proporzionale per turno consecutivo. Fonte: documento 01, punto 5.6.4.

4.2.3 Entità dei malus prodotti dalla marcia forzata e quota di essi rimossa da una giornata di riposo. Fonte: documento 01, punto 5.6.4.4.

### 4.3 Rifornimento

4.3.1 Entità dei malus da mancanza di provviste, con il vincolo che risultino più marcati di quelli della marcia forzata. Fonte: documento 01, punto 5.2.2.4.

4.3.2 Eventuali differenze di autonomia fra formazioni di volume diverso. Fonte: documento 01, punto 5.6.5.

### 4.4 Risorse e bilancio

4.4.1 Quota di riporto delle risorse, fissata al dieci per cento di ciascuna. Decisione di progetto. Fonte: documento 01, punto 5.5.1.4.

4.4.2 Progressione dei materiali monetari per fase storica: bronzo o rame nella fase arcaica, un materiale migliore nella fase antica, argento nella classica, oro nelle medievali. Il mutamento non converte il valore. Fonte: documento 01, punto 5.5.1.3.

4.4.3 Costo dell'addestramento. È decisione di progetto e non dato storico e va annotato come tale. Fonte: documento 01, punto 16.3.

4.4.4 Durate dei lavori invernali, che determinano la ripartizione delle voci fra le linguette ordinate per durata e il momento di completamento dichiarato al giocatore. Fonte: documento 01, punti 5.9.1.3 e 5.9.1.4.

4.4.5 Costi in risorse delle opere permanenti, distinti per tipo di opera. Fonte: documento 01, punti da 5.14.2 a 5.14.8.

### 4.5 Opere e postazioni

4.5.1 Consistenza della guarnigione minima automatica della fortezza ed entità dei malus subiti dalla guarnigione che resiste in attesa di rinforzi. Fonte: documento 01, punto 5.14.3.1.

4.5.2 Valori dei vantaggi in combattimento conferiti dalle opere da campo. Fonte: documento 01, punto 5.14.1.

4.5.3 Peso delle torri di osservazione sull'apporto informativo invernale, cumulativo per fronte. Fonte: documento 01, punti 5.14.6 e 5.9.1.7.

### 4.6 Campagne contemporanee

4.6.1 Distanza alla quale scatta l'avviso che precede il blocco per scarto massimo fra campagne, essendo il blocco fissato a due settimane. Fonte: documento 01, punti 5.6.9.1 e 5.6.9.3.

### 4.7 Progressione e avversari

4.7.1 Numero di acquisizioni finali raggiunte e di acquisizioni ancora mancanti che determina il momento in cui si fissa la specializzazione del regno lontano. Fonte: documento 01, punto 14.6.2.

4.7.2 Tetti d'epoca per ciascun ambito e per ciascuna fase storica. Fonte: documento 01, punto 2.6.2.1.

4.7.3 Numero minimo di acquisizioni e numero minimo di ambiti diversi che compongono la soglia distribuita, per ciascuna fase. Decisione di progetto da tarare con le simulazioni di partita lunga. Fonte: documento 01, punti 2.6.2 e 2.8.2.

4.7.4 Costi, durate e prerequisiti di ciascuna acquisizione dell'elenco del punto 2.8.2.1 del documento 01. L'ordinamento interno agli ambiti si appoggia alla sequenza documentata; i costi sono decisioni di progetto ancorate al principio che il salto tecnologico si paga. Fonte: documento 01, punti 2.7 e 2.8.2.1.

### 4.8 Conoscenza e ricognizione

4.8.1 Numero di turni dopo i quali lo stato confermato decade in avvistato. Vincolo di direzione: il decadimento deve mordere, perché la certezza deve restare rara. Fonte: documento 01, punto 5.3; decisioni di fase due, punto 1.8.

4.8.2 Raggio di osservazione dei gruppi ordinari e portata di esplorazione delle formazioni di ricognizione in funzione della competenza degli esploratori. Fonte: documento 01, punti 5.4 e 5.4.2.

4.8.3 Soglie di competenza richieste per il sabotaggio compiuto da esploratori e soglia di protezione dichiarata di ciascun tipo di formazione non armata. Fonte: documento 01, punto 5.10.2.

4.8.4 Parametri deterministici degli esiti sfavorevoli della ricognizione, cioè le condizioni in cui gli esploratori si perdono, tornano a mani vuote o si fanno notare, in funzione di competenza, distanza e presenza nemica. Il caso non vi interviene, poiché resta confinato a meteo e guasti. Fonte: documento 01, punti 5.4 e 12.2.

### 4.9 Stanchezza e manutenzione

4.9.1 Moltiplicatori di punti vita e capacità offensiva applicati all'apertura della battaglia in funzione dei malus di marcia forzata e di mancanza di provviste, e coefficiente di sensibilità alla stanchezza per archetipo. Vincolo: i malus da mancanza di provviste sono più marcati di quelli della marcia forzata, come già registrato al punto 4.3.1. Fonte: documento 01, punti 5.7 e 3.4.

4.9.2 Passi di degrado dello stato di manutenzione per giorni di movimento e per impiego in battaglia, e probabilità di guasto per ciascuno dei due stati operativi. Fonte: documento 01, punti 5.7.1 e 12.2.

### 4.10 Sortita

4.10.1 Soglia in turni di blocco oltre la quale scatta la sortita, in funzione della propensione dell'ufficiale assediato e dei malus accumulati, e soglie dei tre termini di imminenza. Fonte: documento 01, punti 8b.5 e 8b.5.1; documento 02, punto 4.4.

### 4.11 Meteo e stagioni

4.11.1 Probabilità degli eventi meteorologici per ciascuna stagione operativa ed effetto di ciascun evento sul costo in giorni della marcia, entro le forbici e per causa dichiarata. Nella prima versione le stagioni intermedie differiscono soltanto per queste probabilità. Fonte: documento 01, punti 5.9.2, 5.9.3 e 12.2.

## 5. Valori del campo di battaglia

5.1 Coefficiente di penalità di avanzamento per archetipo, e formula unica che lo combina con la profondità espressa in proporzione all'altezza della griglia. Fonte: documento 01, punto 8.6; carta, principio 13.3.

5.2 Capacità di volume per turno, con il rapporto fra il primo turno maggiorato e i successivi. Fonte: documento 01, punto 9.3.

5.3 Costo aggiuntivo in volume dello spostamento di due celle anziché una. Fonte: documento 01, punto 9.5.0.3.

5.4 Coefficienti del proiettile fisso di ciascun reparto da tiro (01 §3.3.1, versione 3.3), dell'arma da mischia di ciascun archetipo e di ciascun tipo di protezione, con la formula che li combina. Fonte: documento 01, punti 9.9 e 9.9.2.

5.5 Frazione di danno inflitta dalla munizione o dall'arma poco adatta al bersaglio. Fonte: documento 01, punto 9.9.

5.6 Portate del corpo a corpo, del tiro e dell'artiglieria, espresse in celle. Fonte: documento 01, punto 9.5.0.

5.7 Dotazione di munizioni di ciascun archetipo, non reintegrabile in battaglia. Fonte: documento 01, punto 9.6.1.

5.8 Soglie di disingaggio per tipo di truppa, espresse come proporzione della consistenza con cui il reparto è entrato nel contatto. Fonte: documento 01, punti 9.8 e 9.8.1.

5.9 Numero di turni consecutivi di vantaggio dell'imboscante e misura dello sconto sul costo di piazzamento, indicata nell'ordine del trenta per cento. Fonte: documento 01, punto 9.3.2.

5.10 Base di calcolo del riporto di volume fra turni, fissato al dieci per cento, e se il volume riportato generi a sua volta riporto. Fonte: documento 01, punti 9.3.3 e 9.3.4.

5.11 Formula del turno di arrivo dei rinforzi, che combina distanza, durata della battaglia conclusa e volume del distaccamento. Fonte: documento 01, punto 11.2.

5.12 Modificatori di ciascuna caratteristica del campo di battaglia, espressi come coefficienti sui ganci tipizzati definiti dal documento 05: costo del movimento, gittate, soglie di disingaggio e ogni altro gancio che il Motore dichiari. L'elenco delle caratteristiche della prima versione è contenuto nei file dei valori e ogni caratteristica ha un nome fisso del vocabolario chiuso. Fonte: documento 01, punto 7.4; documento 02, punto 4.4.5.

5.13 Capacità di volume per turno per ciascun formato di campo, con il rapporto fra primo turno e successivi già registrato al punto 5.2, e ordine interno fisso di risoluzione. Fonte: documento 01, punti 9.3 e 9.3.1.

5.14 Soglie delle fasce descrittive degli esiti dei combattimenti (aggiunto nella versione 2.1). Le fasce di 01 §9.7.2 — nessuna perdita, lievi, significative, gravi — discendono da soglie deterministiche espresse come proporzione del danno sulla consistenza del reparto colpito immediatamente prima dell'applicazione. Le soglie sono decisioni di progetto con contrassegno di provvisorietà, risiedono nel file dei parametri di combattimento e si riesaminano con i ritorni dei tester e con le simulazioni. Fonte: documento 01, punto 9.7.2.

## 6. Grandezze critiche da tarare con le simulazioni

Le voci di questa sezione non si determinano a tavolino. Il programma di verifica del bilanciamento, separato dal gioco e senza interfaccia, le misura simulando un grande numero di scontri e di partite. Fonte: carta, principio 16.

6.1 Soglia minima di turni prima della resa, che determina la durata di una battaglia perduta. Fonte: documento 01, punti 10.2 e 10.10.

6.2 Margine di convenienza della ritirata combattuta, cioè il rapporto fra soglia di riga, soglia minima di turni e volume disponibile. Fonte: documento 01, punto 10.9.

6.3 Costo di mantenimento dei miglioramenti, che è l'unico freno automatico all'accumulo di forze. Fonte: documento 01, punto 4.14.1.

6.4 Taratura della gittata utile unica dei reparti da tiro (ridefinita nella versione 2.1: l'ampiezza della fascia fra le due gittate ha perso oggetto con 01 §3.4.1 versione 3.3). La gittata unica e la resa vanno tarate perché il tiro non domini distanze eccessive, conservando lo spirito del vincolo storico originario. Fonte: documento 01, punto 3.4.1.

6.5 Carattere degli ufficiali avversari, che determina la frequenza effettiva degli scontri. Fonte: documento 01, punto 6.1.3.

6.6 Rapporto fra volume disponibile e profondità concessa, che determina quanto pesi il vantaggio della sorpresa. Fonte: documento 01, punto 16.4.

6.7 Precisione dell'apporto informativo invernale in funzione di ricognizione, penetrazione delle campagne e numero di torri. La taratura è espressamente delegata alla fase di realizzazione. Fonte: documento 01, punto 5.9.1.7.

6.8 Peso effettivo della fortezza in una campagna difensiva, tenuto conto che all'aggressore basta espugnarla una volta per neutralizzarla per il resto della campagna. Fonte: documento 01, punto 5.14.3.5.

6.9 Sbilanciamento dei formati di mappa minori, dove fortezza e torri conferiscono conoscenza piena su tutta la mappa. Fonte: documento 01, punto 5.14.5.2.

## 7. Registro dei vantaggi nascosti del giocatore

7.1 I vantaggi deliberatamente concessi al giocatore vanno noti al programma di verifica, che diversamente misurerebbe probabilità irreali. Fonte: documento 01, sezione 13.

7.2 Vantaggi attualmente stabiliti: l'avversario può ritirare unità soltanto dalla propria riga più arretrata; la sua propensione alla ritirata è molto bassa.

7.3 Ogni vantaggio nascosto introdotto in seguito va aggiunto qui e al documento 01.

## 8. Minimi obbligatori

8.1 Per ciascuna grandezza in cui il troncamento per difetto potrebbe produrre zero va dichiarato un valore minimo, di regola pari a uno. Fonte: carta, principio 13.6.

8.2 Casi già individuati in cui il minimo è obbligatorio: il costo dimezzato del primo dispiegamento dei rinforzi; il costo scontato dei piazzamenti dell'imboscante; qualunque danno ridotto per effetto dell'accoppiamento fra offesa e protezione; il costo del piazzamento di elementi di volume basso.

## 9. Struttura dei file dei valori e dei testi

Sezione aggiunta nella versione 2.0. La struttura è definita dal documento di architettura (05, sezioni 7 e 8); qui se ne registra l'articolazione perché questo documento è la sede dei dati. Ogni file è leggibile e modificabile senza ricompilare, secondo il principio 13.1 della carta.

9.1 Collocazione. I file di fabbrica vivono nelle risorse dell'applicazione; al primo avvio e a ogni aggiornamento vengono copiati nella cartella Documenti, visibile nell'app File, in due alberi: Valori e Testi. Il programma carica da Documenti; se la validazione fallisce, torna alla copia di fabbrica dichiarandolo. Fonte: carta, principio 15.4.

9.2 Manifest dei valori. Il file manifest.json dichiara la versione semantica dei valori, l'elenco dei file con l'impronta di ciascuno e le versioni di salvataggio compatibili. Ogni modifica di bilanciamento incrementa la versione; i salvataggi che dichiarano una versione non compatibile non si aprono. Fonte: carta, principio 15.

9.3 Forma delle voci. Ogni grandezza è una base di fase, un coefficiente riferito alla base, oppure un intervallo con regola di variazione, cioè l'elenco delle cause dichiarate che spostano il valore e del passo di ciascuna. Le tabelle a doppia entrata sono vietate e la validazione le respinge. Fonte: carta, principio 13.

9.4 Elenco dei file dei valori e corrispondenza con questo documento. fasi.json: basi di fase e progressione monetaria (4.4.2). archetipi.json: i parametri del punto 3.4 del documento 01 come coefficienti, comprese soglie di disingaggio (5.8), dotazioni (5.7), sensibilità alla stanchezza (4.9.1), coefficienti di penalità di avanzamento (5.1). assetti.json: taglie e composizioni (documento 01, punto 4.7). acquisizioni.json: ambiti, ordinamenti, costi, durate, effetti tipizzati (4.7.4). terreni-e-strade.json: costi in giorni e pesi di partenza e arrivo (4.1). meteo.json: probabilità per stagione ed effetti (4.11). opere.json: costi, durate e effetti delle opere permanenti e da campo (4.4.5, 4.5). caratteristiche-campo.json: modificatori (5.12). ufficiali.json: parametri di carattere (6.5). regni.json: differenze di partenza, fissate una volta sola (3.1). vantaggi-nascosti.json: i vantaggi della sezione 7, letti anche dal programma di verifica. minimi.json: i minimi obbligatori della sezione 8. formato-battaglia.json: capacità di volume, riporto, zone e soglie per formato (5.2, 5.10, 5.13). nomi-gruppi.json: la lista chiusa dei nomi propri dei gruppi (documento 01, punto 5.6.0.4). mappe/: un file per mappa, raggruppate per fronte, almeno cinque per fronte (documento 01, punto 5.6.9). aptica.json: i pattern tattili con nomi parlanti (carta, principio 5.5). suoni.json: segnali sonori, ambienti e temi per fase.

9.5 Testi. L'albero Testi contiene un pacchetto di localizzazione per lingua, nel formato di sistema che gestisce i plurali, più il file del vocabolario chiuso con chiavi stabili per insieme e per termine, e il proprio manifest con la versione e, dalla versione 2.1 di questo documento, con le impronte dei file: sono le impronte a far rinfrescare la copia in Documenti quando i testi cambiano, sicché la versione resta ferma finché il titolare non ne ordina il cambio. Ogni annuncio è una frase intera con segnaposto e dichiara la propria lingua. La versione dei testi non blocca mai l'apertura dei salvataggi. Fonte: carta, principio 14; documento 02, sezioni 4 e 15.

9.6 Scenari di verifica. Gli scenari del programma di verifica sono anch'essi file dichiarativi, con le soglie di accettazione di ciascuna metrica, così che una misura sia ripetibile e confrontabile nel tempo. Fonte: documento 05, sezione 12.
