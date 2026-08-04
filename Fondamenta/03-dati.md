# Documento dei dati

Documento 03 di 05 — versione 2.4

Novità della versione 2.4, prodotta dalla prima taratura sui numeri della fase C. È la prima versione in cui alcuni valori cessano di essere provvisori perché una misura li giustifica, e non perché siano parsi ragionevoli. Cambiano: i due estremi della curva del tiro (5.15), il passo dell'accerchiamento (5.16), i parametri di carattere degli ufficiali (6.5), la riduzione della propensione alla ritirata avversaria (7.4) e le composizioni dello scenario di prova (nuovo punto 5.18). Si aggiunge la sezione 10 con la forma del programma di verifica e le misure della prima corsa; si aggiornano le grandezze critiche 6.1, 6.5, 6.9 e 6.10 con i numeri misurati.

Novità della versione 2.3: si aggiunge il malus della risposta al secondo bersaglio (nuovo punto 5.17), introdotto da 01 §9.11; si aggiorna la grandezza critica 6.10 con la misura dell'effetto congiunto fra quel limite e il modificatore di accerchiamento, e con la proposta di revisione del passo di accerchiamento che ne discende, non applicata perché i valori appartengono alla taratura; si iscrive fra i vantaggi nascosti l'assegnazione dell'annientamento simultaneo (7.2); si stabilisce al nuovo punto 9.2.1 la regola generale di incremento della versione dei valori.

Novità della versione 2.2, in conseguenza dei due modificatori di posizione introdotti da 01 §9.10: si aggiungono i valori della vicinanza nel tiro (nuovo punto 5.15) e quelli dell'accerchiamento (nuovo punto 5.16), tutti con contrassegno di provvisorietà; si aggiunge la grandezza critica del loro peso complessivo (nuovo punto 6.10). Si registra inoltre, al punto 7.4, una misura ricavata dall'accertamento sugli esiti degli scontri: con i valori attuali la soglia di resa del tattico avversario è irraggiungibile già prima che il vantaggio nascosto la innalzi, sicché il vantaggio non è oggi la causa del comportamento osservato.

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

5.15 Valori della vicinanza nel tiro (riscritto nella versione 2.4 sulla misura). Le grandezze sono ora TRE. Le prime due sono gli estremi della curva: la resa al limite della gittata e quella alla minima distanza; fra i due la formula unica interpola sulla prossimità, che vale zero al limite e uno alla minima distanza. La terza sono le due soglie che dividono la prossimità nelle tre fasce descrittive del vocabolario chiuso, con lo stesso impianto delle soglie del punto 5.14.

5.15.1 TARATI nella fase C, non più provvisori. Resa al limite: sette decimi. Resa alla minima distanza: due unità e quattro decimi. La misura che li giustifica è la curva del tiro del punto 10.3: con i valori precedenti — nessuna riduzione al limite e sei decimi di maggiorazione a ridosso — i tiratori producevano sul bersaglio di riferimento perdite significative a OGNI distanza della gittata, sicché la fascia annunciata non cambiava mai e avvicinarsi non mutava nulla di ciò che il giocatore sentiva. Con i valori tarati, contro un bersaglio ben scelto le perdite vanno da lievi al limite della gittata a gravi alla minima distanza; contro un bersaglio mal scelto restano lievi al limite e non superano le significative a ridosso, sicché la vicinanza non ripara l'accoppiamento sbagliato. Fonte: documento 01, punti 9.10.1 e 9.10.1.0.

5.15.2 Restano provvisorie le due soglie delle fasce di vicinanza, che dividono la prossimità in terzi: non le si è tarate perché sono soglie di ANNUNCIO e la loro bontà si giudica all'ascolto, non sulla misura. Si riesaminano con i ritorni dei tester.

5.16.1 TARATO nella fase C, non più provvisorio. Passo della maggiorazione: otto centesimi, in luogo di quindici. La misura che lo giustifica è la spazzata del punto 10.4, che ha provato sette valori dallo zero a quindici centesimi sulla configurazione di riferimento con il limite dei bersagli in vigore. Criterio adottato, e dichiarato: tre assalitori NON devono annientare il bersaglio in un solo giro, perché l'accerchiamento sia decisivo in due giri e non istantaneo, lasciando al difensore il giro per disingaggiarsi o farsi soccorrere; quattro possono. La banda che soddisfa il criterio va da quattro a dodici centesimi; a quindici tre assalitori annientano in un giro, a zero nemmeno quattro ci riescono e la maggiorazione non aggiunge nulla. Otto centesimi è il punto della banda con il margine più ampio, cioè quello in cui il bersaglio a tre assalitori sopravvive al primo giro con lo scarto maggiore. Resta provvisorio il tetto dei concorrenti conteggiati, che il criterio non tocca.

5.16 Valori dell'accerchiamento (aggiunto nella versione 2.2, tarato nella 2.4). Due grandezze, entrambe nel file dei parametri di combattimento. La prima è il passo della maggiorazione, che la formula unica compone col quadrato dei concorrenti eccedenti il primo, sicché due stringono moderatamente e tre o quattro assai di più come il punto 9.10.2 prescrive. La seconda è il tetto dei concorrenti conteggiati, oltre il quale la maggiorazione non cresce più; il tetto esiste perché su griglia esagonale i vicini sono sei e i tiratori a portata possono essere molti di più, e senza tetto un ammassamento produrrebbe maggiorazioni prive di senso. Le fasce descrittive dell'annuncio non hanno soglie proprie nei dati: discendono dai numeri di concorrenti che il punto 9.10.2 dichiara come regola, cioè uno, due, tre o più. Fonte: documento 01, punto 9.10.2.

5.17 Malus della risposta al secondo bersaglio (aggiunto nella versione 2.3). Una sola grandezza, nel file dei parametri di combattimento e provvisoria, espressa come resa conservata: un reparto già impegnato risponde al secondo nemico con questa frazione della propria resa piena. Contro il primo rende per intero e dal terzo non risponde affatto, quindi non esistono altre voci: il numero massimo di nemici cui si risponde è una regola di 01 §9.11 e non un valore, e renderlo un valore obbligherebbe a un malus per posto, cioè a una tabella a doppia entrata, vietata dal punto 13.3 della carta. Vincolo di intervallo: strettamente fra zero e l'unità — a uno il malus sparirebbe, a zero la condizione ridotta si confonderebbe con l'assenza di risposta, e la validazione respinge entrambi gli estremi. Fonte: documento 01, punto 9.11.

5.18 Composizioni dello scenario di prova (aggiunto nella versione 2.4). I due mazzi non sono valori di bilanciamento in senso stretto, ma la loro asimmetria pesa sull'esito come un valore, e va quindi registrata qui. Vincolo stabilito dal titolare: nessuna delle due parti deve disporre in partenza di un bersaglio molto più redditizio dell'altra, e i due mazzi non devono per questo diventare identici, che sarebbe una perdita.

5.18.1 TARATE nella fase C sulla misura del punto 10.5. Prima: la fanteria pesante del giocatore portava protezione anti-perforazione e quella avversaria anti-saturazione, mentre il proiettile leggero satura; il reparto più pesante e più caro del giocatore era quindi il bersaglio migliore del campo per il tiro avversario, e quello avversario il peggiore per il tiro del giocatore. Dopo: la fanteria pesante di ENTRAMBE le parti porta protezione anti-saturazione, che è anche la sola coerente col suo ruolo, e la differenza fra i mazzi si sposta sugli altri reparti — il giocatore ha tiratori di protezione mista, l'avversario fanteria leggera di protezione mista. I punti vita esposti a un tiro efficace scendono così da 1400 contro 2300 a 400 contro 500, e la frequenza di vittoria a vantaggi spenti passa da sette contro uno a quattro contro quattro.

5.18.2 Vincolo strutturale registrato, perché non lo si riscopra: con due sole protezioni e tre soli tipi di reparto, imporre ai due mazzi la stessa identica massa esposta li rende necessariamente identici. La parità esatta si ottiene quindi soltanto differenziando la composizione, non la sola protezione: è ciò che le protezioni miste fanno.

## 6. Grandezze critiche da tarare con le simulazioni

Le voci di questa sezione non si determinano a tavolino. Il programma di verifica del bilanciamento, separato dal gioco e senza interfaccia, le misura simulando un grande numero di scontri e di partite. Fonte: carta, principio 16.

6.1 Soglia minima di turni prima della resa, che determina la durata di una battaglia perduta. Fonte: documento 01, punti 10.2 e 10.10. MISURATA nella fase C e lasciata come è: con le soglie di resa rese raggiungibili (6.5) ogni configurazione conclude, la durata mediana sta fra nove e quindici giri secondo lo scenario, e nessuna corsa raggiunge il tetto. Prima della taratura un quarto delle configurazioni non concludeva affatto. La soglia in turni non è quindi il freno operante: lo è la soglia di perdite.

6.2 Margine di convenienza della ritirata combattuta, cioè il rapporto fra soglia di riga, soglia minima di turni e volume disponibile. Fonte: documento 01, punto 10.9.

6.3 Costo di mantenimento dei miglioramenti, che è l'unico freno automatico all'accumulo di forze. Fonte: documento 01, punto 4.14.1.

6.4 Taratura della gittata utile unica dei reparti da tiro (ridefinita nella versione 2.1: l'ampiezza della fascia fra le due gittate ha perso oggetto con 01 §3.4.1 versione 3.3). La gittata unica e la resa vanno tarate perché il tiro non domini distanze eccessive, conservando lo spirito del vincolo storico originario. Fonte: documento 01, punto 3.4.1.

6.5 Carattere degli ufficiali avversari, che determina la frequenza effettiva degli scontri. Fonte: documento 01, punto 6.1.3.

6.5.1 TARATI nella fase C due parametri su cinque, sulle misure dei punti 10.2 e 10.6. Primo: la tolleranza alle perdite e la propensione alla ritirata dell'ufficiale ordinario passano da mezzo e mezzo a quattro decimi e otto decimi, perché la soglia di resa — che è la prima divisa per la seconda — vale ora mezzo anziché l'unità intera. Con l'unità intera la soglia richiedeva la perdita di TUTTE le forze impiegate, cioè non era raggiungibile, e nessuna battaglia poteva chiudersi per resa: la misura precedente lo aveva già rilevato e la fase C lo ha confermato misurando gli esiti, dove la resa non compariva mai. Secondo: la propensione all'attacco dell'ufficiale prudente passa da tre decimi a sei, perché sotto la metà il tattico non avanza né ingaggia mai; due ufficiali prudenti contrapposti restavano immobili e la battaglia non si concludeva in alcun giro. Restano provvisori gli altri tre parametri, che governano imboscata e accerchiamento e non hanno ancora un banco che li misuri.

6.5.2 Da tenere presente per la fase D: la propensione all'attacco governa anche il rifiuto della battaglia sul piano di campagna (01 §6.1.3), che non esiste ancora. Se i due ruoli chiederanno valori diversi, il parametro andrà sdoppiato; oggi non c'è modo di accorgersene.

6.6 Rapporto fra volume disponibile e profondità concessa, che determina quanto pesi il vantaggio della sorpresa. Fonte: documento 01, punto 16.4.

6.7 Precisione dell'apporto informativo invernale in funzione di ricognizione, penetrazione delle campagne e numero di torri. La taratura è espressamente delegata alla fase di realizzazione. Fonte: documento 01, punto 5.9.1.7.

6.8 Peso effettivo della fortezza in una campagna difensiva, tenuto conto che all'aggressore basta espugnarla una volta per neutralizzarla per il resto della campagna. Fonte: documento 01, punto 5.14.3.5.

6.9 Sbilanciamento dei formati di mappa minori, dove fortezza e torri conferiscono conoscenza piena su tutta la mappa. Fonte: documento 01, punto 5.14.5.2. MISURATO in fase C anche per il formato di BATTAGLIA minore, che è cosa distinta ma affine: sul campo da quindici celle lo scarto fra le vittorie a vantaggi spenti resta di cinquecento per mille, contro lo zero del campo grande e i duecentocinquanta del campo grande a mazzi identici. Il formato minore è quindi sbilanciato e la causa non è nelle composizioni. Da tarare quando la fase D fornirà scenari di formato minore realistici: la leva più probabile è la profondità di schieramento, che sul quindici vale due righe su quattro, cioè metà campo.

6.10 Peso dei modificatori di posizione e del limite dei bersagli (aggiornato nella versione 2.3). Tre misure da prendere insieme. La prima: quanto la vicinanza premi l'avanzata rispetto al costo in volume che l'avanzata comporta, poiché se il premio non copre il costo nessuno avanzerà e il modificatore sarà inerte, mentre se lo supera di molto il tiro da lontano cesserà di avere senso e le battaglie collasseranno a contatto immediato. La seconda: quanto l'accerchiamento debba pesare perché più reparti contro uno prevalgano senza che il campo si riduca a un ammassamento. La terza: il malus del punto 5.17. Le tre interagiscono, perché i tiratori concorrono all'accerchiamento e la loro posizione è governata dalla prima.

6.10.1 Misura dell'effetto congiunto, eseguita nella versione 2.3 sulla configurazione di riferimento (assalitori di fanteria pesante identici contro una fanteria pesante avversaria, cinque atomi ciascuno, un giro di mischia). Il rapporto è fra punti inflitti al bersaglio e punti complessivamente subiti dagli assalitori.

Con il passo di accerchiamento oggi nei dati, cioè quindici centesimi: un assalitore, rapporto uno; due, rapporto 1,53; tre, rapporto 3,07 con il bersaglio ANNIENTATO nel solo primo giro; quattro, identico perché il bersaglio è già caduto. Con il solo limite dei bersagli e nessuna maggiorazione di accerchiamento: uno, rapporto uno; due, 1,33; tre, 2,00; quattro, 2,67, e il bersaglio sopravvive al primo giro fino a quattro assalitori.

6.10.2 Che cosa se ne ricava, e proposta non applicata. Il limite dei bersagli da solo produce già la progressione voluta, e per di più regolare: il rapporto cresce all'incirca con il numero degli assalitori. La maggiorazione di accerchiamento, scelta quando l'accerchiato restituiva ancora la propria resa piena a ciascun assalitore, si somma ora a un effetto che prima non esisteva, e a tre assalitori porta lo scambio all'annientamento in un solo giro: su griglia esagonale l'adiacenza tripla si ottiene senza fatica, e l'avversario, che già ordina i bersagli per efficacia, imparerà a cercarla. Il moltiplicatore risulta quindi eccessivo.

Proposta: portare il passo di accerchiamento da quindici a otto centesimi, che dà 1,08 con due concorrenti, 1,32 con tre e 1,72 con quattro. La forma resta quella prescritta da 01 §9.10.2, moderata a due e assai maggiore a tre o quattro; a tre assalitori il bersaglio sopravvive al primo giro con un margine sottile anziché cadere, e la manovra resta premiata senza essere risolutiva da sola. La proposta NON è applicata: i valori appartengono alla taratura e la scelta è del titolare. Valori intermedi misurati, per confronto: dieci centesimi dà 1,10, 1,40 e 1,90, con il bersaglio che a tre assalitori sopravvive di poco; cinque centesimi dà 1,05, 1,20 e 1,45.

6.10.3 Da osservare in taratura, emerso dalla stessa misura e CONFERMATO in fase C a ogni valore del passo: oltre il secondo assalitore il costo dell'accerchiamento per chi lo compie non cresce più, poiché il bersaglio non risponde dal terzo in poi. Il terzo e il quarto assalitore subiscono esattamente zero. Aggiungere reparti su un bersaglio già stretto è quindi, in sé, sempre conveniente, e il fatto non dipende dal passo: nessun valore del passo lo corregge, perché discende dal limite dei bersagli e non dalla maggiorazione. Il freno non è nel combattimento ma nel volume speso per portarveli e nei fianchi che si scoprono altrove. RESTA DA TARARE e non è tarabile ora: misurarlo richiede scenari in cui scoprire un fianco costi qualcosa, cioè un fronte più largo delle forze disponibili, e la taratura del budget di volume rispetto alla profondità del punto 6.6. Entrambi dipendono dalla fase D. Fonte: documento 01, punti 9.10.1, 9.10.2, 9.11, 9.11.5 e 16.4.

## 7. Registro dei vantaggi nascosti del giocatore

7.1 I vantaggi deliberatamente concessi al giocatore vanno noti al programma di verifica, che diversamente misurerebbe probabilità irreali. Fonte: documento 01, sezione 13.

7.2 Vantaggi attualmente stabiliti: l'avversario può ritirare unità soltanto dalla propria riga più arretrata; la sua propensione alla ritirata è molto bassa; l'annientamento simultaneo assegna l'esito al giocatore (aggiunto nella versione 2.3; documento 01, punti 13.2 e 15.2.5). Quest'ultimo è un interruttore e non una misura: acceso, sconfitto è l'avversario; spento, l'esito torna a cadere sul giocatore, ed è la forma in cui il programma di verifica misura le probabilità reali.

7.3 Ogni vantaggio nascosto introdotto in seguito va aggiunto qui e al documento 01.

7.4.1 TARATA nella fase C. La riduzione della propensione alla ritirata avversaria passa da tre decimi a sei. La misura che lo giustifica è il punto 10.2: con tre decimi la soglia di resa dell'avversario valeva più del triplo delle forze impiegate, cioè era irraggiungibile, e il vantaggio non rendeva rara la ritirata avversaria — la rendeva impossibile, che è cosa diversa e non è ciò che 01 §10.7 chiede. Con sei decimi la soglia vale poco più di otto decimi delle forze impiegate per l'ufficiale ordinario e sette per il prudente: la ritirata avversaria resta rara e costituisce una sfida quando accade, ma è raggiungibile. Non è più provvisoria.

7.4.2 Fatto misurato da tenere presente, che nessuna taratura può togliere: il vantaggio è per costruzione un'asimmetria, e in uno scontro simulato fra due tattici di pari condotta lo scarto fra le vittorie lo riflette per intero. La frequenza di vittoria delle due parti si giudica quindi sulle sole corse a vantaggi SPENTI, dove misura la struttura; a vantaggi accesi misura quanto valgono i vantaggi. Le soglie di accettazione degli scenari lo dichiarano esplicitamente e si applicano alle sole corse a vantaggi spenti.

7.4 Misura registrata nella versione 2.2, dall'accertamento sugli esiti degli scontri. La soglia oltre la quale il tattico avversario dichiara la resa è la sua tolleranza alle perdite divisa per la propensione effettiva alla ritirata, ed è espressa come proporzione delle forze impiegate. Con i valori di fabbrica dell'ufficiale di prova la soglia vale l'unità intera già SENZA il vantaggio nascosto, cioè richiederebbe la perdita di tutto ciò che è stato impegnato, e il vantaggio la porta a poco più del triplo. Ne discende un fatto da tenere presente in taratura: il comportamento osservato, cioè un avversario che non si ritira mai e costringe all'annientamento, non è oggi prodotto dal vantaggio nascosto ma dai valori di carattere dell'ufficiale, e ridurre o togliere il vantaggio non lo cambierebbe. Il vantaggio resta registrato e resta reale; ciò che va tarato è il rapporto fra tolleranza alle perdite e propensione alla ritirata del punto 6.5.

7.5 I due modificatori della sezione 9.10 del documento 01 non sono vantaggi nascosti e non entrano in questo registro: valgono per entrambe le parti, e l'accertamento lo ha verificato misurando i danni a parti scambiate.

## 8. Minimi obbligatori

8.1 Per ciascuna grandezza in cui il troncamento per difetto potrebbe produrre zero va dichiarato un valore minimo, di regola pari a uno. Fonte: carta, principio 13.6.

8.2 Casi già individuati in cui il minimo è obbligatorio: il costo dimezzato del primo dispiegamento dei rinforzi; il costo scontato dei piazzamenti dell'imboscante; qualunque danno ridotto per effetto dell'accoppiamento fra offesa e protezione; il costo del piazzamento di elementi di volume basso.

## 9. Struttura dei file dei valori e dei testi

Sezione aggiunta nella versione 2.0. La struttura è definita dal documento di architettura (05, sezioni 7 e 8); qui se ne registra l'articolazione perché questo documento è la sede dei dati. Ogni file è leggibile e modificabile senza ricompilare, secondo il principio 13.1 della carta.

9.1 Collocazione. I file di fabbrica vivono nelle risorse dell'applicazione; al primo avvio e a ogni aggiornamento vengono copiati nella cartella Documenti, visibile nell'app File, in due alberi: Valori e Testi. Il programma carica da Documenti; se la validazione fallisce, torna alla copia di fabbrica dichiarandolo. Fonte: carta, principio 15.4.

9.2 Manifest dei valori. Il file manifest.json dichiara la versione semantica dei valori, l'elenco dei file con l'impronta di ciascuno e le versioni di salvataggio compatibili. I salvataggi che dichiarano una versione non compatibile non si aprono. Fonte: carta, principio 15.

9.2.1 Quando la versione dei valori si incrementa. Regola generale, stabilita dal titolare nella versione 2.3 e vincolante da qui in avanti: LA VERSIONE DEI VALORI SI INCREMENTA OGNI VOLTA CHE CAMBIA UNA REGOLA CHE INCIDE SUL MODO IN CUI UNA PARTITA IN CORSO SI SVOLGEREBBE, e non soltanto quando cambia la forma dei file. Il criterio è uno solo e si applica così: se una partita salvata prima della modifica, riaperta dopo, proseguirebbe in modo diverso da come era cominciata, la versione sale. Vi rientrano quindi le modifiche alle regole del combattimento, ai costi, alle soglie e a qualunque valore che entri in una formula del Motore; non vi rientrano le aggiunte di voci mai lette da una partita esistente, né i testi, che per 9.5 non bloccano mai l'apertura.

9.2.1.1 Perché la regola esiste. Il giornale registra i comandi e la ripresa li riapplica: se le regole sono cambiate, gli stessi comandi producono uno stato diverso, e il giocatore ritrova una battaglia che non è quella che aveva lasciato — senza alcun avviso, perché il rifiuto del salvataggio incompatibile del principio 15.2 si fonda proprio sulla versione. Una nota per i tester non vi supplisce: chi riapre una partita non legge le note. L'omissione è già avvenuta una volta, con la tranche dei modificatori di posizione, e questa regola esiste per chiuderla una volta sola.

9.2.1.2 Rapporto con la disciplina delle versioni. Resta fermo che la versione di marketing dell'applicazione si cambia soltanto su istruzione esplicita del titolare. La versione dei valori non è più discrezionale: ha il criterio automatico del punto 9.2.1, e chi tocca una regola la incrementa nella stessa modifica insieme alle impronte del manifest. La versione dei testi resta ferma e discrezionale, poiché le impronte del manifest dei testi bastano al rinfresco della copia in Documenti.

9.3 Forma delle voci. Ogni grandezza è una base di fase, un coefficiente riferito alla base, oppure un intervallo con regola di variazione, cioè l'elenco delle cause dichiarate che spostano il valore e del passo di ciascuna. Le tabelle a doppia entrata sono vietate e la validazione le respinge. Fonte: carta, principio 13.

9.4 Elenco dei file dei valori e corrispondenza con questo documento. fasi.json: basi di fase e progressione monetaria (4.4.2). archetipi.json: i parametri del punto 3.4 del documento 01 come coefficienti, comprese soglie di disingaggio (5.8), dotazioni (5.7), sensibilità alla stanchezza (4.9.1), coefficienti di penalità di avanzamento (5.1). assetti.json: taglie e composizioni (documento 01, punto 4.7). acquisizioni.json: ambiti, ordinamenti, costi, durate, effetti tipizzati (4.7.4). terreni-e-strade.json: costi in giorni e pesi di partenza e arrivo (4.1). meteo.json: probabilità per stagione ed effetti (4.11). opere.json: costi, durate e effetti delle opere permanenti e da campo (4.4.5, 4.5). caratteristiche-campo.json: modificatori (5.12). ufficiali.json: parametri di carattere (6.5). regni.json: differenze di partenza, fissate una volta sola (3.1). vantaggi-nascosti.json: i vantaggi della sezione 7, letti anche dal programma di verifica. minimi.json: i minimi obbligatori della sezione 8. formato-battaglia.json: capacità di volume, riporto, zone e soglie per formato (5.2, 5.10, 5.13). nomi-gruppi.json: la lista chiusa dei nomi propri dei gruppi (documento 01, punto 5.6.0.4). mappe/: un file per mappa, raggruppate per fronte, almeno cinque per fronte (documento 01, punto 5.6.9). aptica.json: i pattern tattili con nomi parlanti (carta, principio 5.5). suoni.json: segnali sonori, ambienti e temi per fase.

9.5 Testi. L'albero Testi contiene un pacchetto di localizzazione per lingua, nel formato di sistema che gestisce i plurali, più il file del vocabolario chiuso con chiavi stabili per insieme e per termine, e il proprio manifest con la versione e, dalla versione 2.1 di questo documento, con le impronte dei file: sono le impronte a far rinfrescare la copia in Documenti quando i testi cambiano, sicché la versione resta ferma finché il titolare non ne ordina il cambio. Ogni annuncio è una frase intera con segnaposto e dichiara la propria lingua. La versione dei testi non blocca mai l'apertura dei salvataggi. Fonte: carta, principio 14; documento 02, sezioni 4 e 15.

9.6 Scenari di verifica. Gli scenari del programma di verifica sono anch'essi file dichiarativi, con le soglie di accettazione di ciascuna metrica, così che una misura sia ripetibile e confrontabile nel tempo. Fonte: documento 05, sezione 12.

---

## 10. Il programma di verifica e la prima corsa (sezione aggiunta nella versione 2.4)

10.1 Forma realizzata. Il programma di verifica è la libreria `Verifica` più il guscio da riga di comando `StrumentoVerifica` (05 §12.1, RDA-58). Non contiene alcuna regola propria: gioca battaglie intere applicando i comandi del Motore e facendo agire il tattico del Motore su ENTRAMBE le parti, sicché la condotta è pari per costruzione e ogni sbilanciamento che resta è strutturale. Dove una misura richiedeva una grandezza che il Motore non esponeva — la soglia di resa del tattico — la grandezza è stata esposta dal Motore, non riscritta nel programma.

10.2 Variazione e riproducibilità. La battaglia non contiene alcuna estrazione del caso (01 §12.1): due corse sugli stessi dati e sulla stessa configurazione danno lo stesso identico esito, e il seme di 05 §12.6 non ha oggetto sul piano di battaglia. La distribuzione viene quindi dagli ESTREMI degli intervalli (00 §13.2.4), enumerati come assi dichiarati nello scenario: chi occupa per primo, ogni combinazione di ufficiali fra le due parti, vantaggi nascosti accesi e spenti, scontro ordinario e da imboscata. L'insieme degli assi è chiuso e un asse ignoto è respinto in caricamento. Il rapporto è identico fra una corsa e l'altra, ed è collaudato che lo sia.

10.3 Misura della curva del tiro. Per ogni reparto da tiro e ogni distanza della sua gittata: coefficiente, danno prodotto dal comando davvero applicato, e la fascia di perdite che ne risulta sul bersaglio di riferimento. È la misura su cui la taratura del punto 5.15.1 è stata decisa.

10.4 Misura della progressione dell'accerchiamento. Da uno a quattro assalitori identici contro un bersaglio identico, un giro: coefficiente, punti inflitti, punti subiti, rapporto, e se il bersaglio cada nel solo primo giro. La spazzata su sette valori del passo è la misura su cui la taratura del punto 5.16.1 è stata decisa.

10.5 Misura delle composizioni. Per ciascun elemento di ciascuno schieramento: quanto rende al tiro avverso batterlo, se lo batta da efficace, e quanti punti vita quell'elemento porti. È la misura fine dell'asimmetria dei mazzi, e quella su cui la correzione del punto 5.18.1 è stata decisa: la media delle due parti può coincidere mentre l'una espone il reparto più pesante e l'altra il più leggero, che non è la stessa cosa.

10.6 Misura degli esiti. Per ogni configurazione: modo di conclusione, sconfitto, giri, comandi, perdite e forze impiegate delle due parti; in riepilogo, per scenario e per stato dei vantaggi, la frequenza di ciascun modo, la distribuzione della durata e la frequenza di vittoria delle due parti con lo scarto in per mille.

10.7 Misura dei duelli. Ogni archetipo contro ogni altro, in condizioni pari e per entrambe le protezioni: danno reciproco del primo giro, giri, residuo e modo di fine. Fatto emerso e registrato: in condizioni pari NESSUN duello si chiude con la dispersione di uno dei due — tutti i centosessantadue si chiudono per disingaggio, perché la soglia di 01 §9.8 interviene prima. Il duello misura quindi il PRIMO scambio, e chi valga di più si legge dal residuo; al secondo contatto nessuna soglia opera più (01 §9.8.3) e la questione si sposta lì. Non è un difetto ed è coerente con 01 §9.8.4, che vuole il disingaggio una finestra e non una via di fuga; è però una grandezza da tarare, perché una battaglia in cui il primo contatto non uccide mai nessuno allunga tutti gli scontri.

10.8 Misura dei pesi dei modificatori. Ciascun modificatore isolato nella stessa configurazione di riferimento: accoppiamento offesa-protezione contro le due protezioni, vicinanza agli estremi e al centro della gittata, accerchiamento a ciascun numero di concorrenti, limite dei bersagli a ciascun posto. Il limite dei bersagli non è disattivabile perché è una regola e non un valore (01 §16.3.1): il suo peso si legge sulla progressione del punto 10.4, dove il subito dell'accerchiato smette di crescere dopo il secondo assalitore.

10.9 Soglie di accettazione. Vivono negli scenari e non nel codice (05 §12.6). Quella dichiarata è lo scarto massimo fra le vittorie delle due parti, a vantaggi spenti, per la ragione del punto 7.4.2. Con otto configurazioni per scenario la granularità dello scarto è di centoventicinque per mille: una soglia più stretta di duecentocinquanta sarebbe soddisfacibile soltanto dal pareggio esatto, e non va quindi dichiarata.
