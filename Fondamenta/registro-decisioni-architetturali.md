# Registro delle decisioni architetturali

Documento di lavoro della fase di architettura — versione 1.0

## 0. Che cosa contiene e come si usa

Ogni scelta non banale compiuta nella fase di architettura, con il problema, le opzioni considerate, la scelta, la motivazione e le conseguenze. Comprende le decisioni tecniche (RDA-01 fino a RDA-12), le chiusure dei punti che i consolidati lasciavano aperti, delegate dal titolare (RDA-13 fino a RDA-40), le decisioni aggiunte a valle delle verifiche di conformità e di sufficienza condotte nella stessa fase (RDA-41 fino a RDA-45), e le decisioni della revisione del titolare sulle chiusure (RDA-46 e RDA-47, più la conferma annotata sotto RDA-25). Serve a impedire che una cosa già valutata e respinta venga riproposta come idea nuova. Prima di proporre un cambiamento a una di queste materie, leggere la voce corrispondente.

I rinvii usano le stesse convenzioni del documento 05: carta come 00 §P.n, consolidati come 01 §n, 02 §n, 03 §n, architettura come A §n.

---

## Parte prima — Decisioni tecniche

### RDA-01 — Pacchetto SwiftPM con sette bersagli e confini di dipendenza imposti

Problema. Come organizzare il programma perché la separazione fra logica e interfaccia (00 §3) sia un fatto strutturale e non una disciplina volontaria.

Opzioni. Un solo bersaglio applicativo con cartelle; più bersagli in un pacchetto SwiftPM; più repository separati.

Scelta. Un pacchetto con sette bersagli — Dati, Motore, Sessione, Contenuti, Segnali, Presentazione, Verifica — e regole di dipendenza esplicite (A §1.2, §1.3), verificate dal collaudo. Il grafo è: Dati importa solo Foundation; Motore importa Dati, da cui riceve i tipi dei valori e l'insieme chiuso dei ganci; Sessione importa Motore e Dati; Segnali importa Motore per il solo tipo degli eventi, oltre a Dati e ai framework di piattaforma; Presentazione sta in cima; Verifica importa Sessione, Motore e Dati.

Motivazione. Le cartelle non impediscono nulla: chiunque può importare UIKit nella logica senza accorgersene. Un bersaglio SwiftPM che non dichiara UIKit fra le dipendenze non compila se qualcuno lo importa: il confine si difende da solo. I repository separati aggiungono attrito senza aggiungere protezione. Il programma di verifica e la futura partita fra dispositivi richiedono un Motore compilabile senza interfaccia: con i bersagli è garantito per costruzione. La direzione Motore-verso-Dati è stata scelta, dopo la prova di sufficienza, come la soluzione minima al problema dei tipi condivisi: l'alternativa di un bersaglio di soli tipi è stata scartata perché aggiungeva un modulo senza aggiungere protezione, e l'alternativa della duplicazione speculare dei tipi è stata scartata perché ogni asimmetria fra le copie sarebbe un difetto silenzioso.

Conseguenze. Il Motore è compilabile e collaudabile su macOS; la Verifica usa gli stessi binari del gioco; ogni tentazione di scorciatoia attraverso il confine diventa un errore di compilazione; i tipi dei valori e i ganci vivono in Dati, la loro semantica nel Motore (A §7.7).

### RDA-02 — UIKit programmatico per l'intero strato di presentazione

Problema. Scegliere fra SwiftUI e UIKit per le schermate, sapendo che il principio 1 prevale su qualunque considerazione di modernità o velocità di sviluppo.

Opzioni. SwiftUI puro; SwiftUI con isole UIKit per le griglie; UIKit ovunque.

Scelta. UIKit programmatico, senza storyboard, per tutte le schermate (A §9.1).

Motivazione. I requisiti più severi del progetto sono il controllo esatto dell'ordine di lettura (00 §11.5), i rotori personalizzati, il fuoco che non si muove mai da solo (00 §11.1) e gli elementi aggiornati sul posto. UIKit li serve con interfacce dirette e mature: elenco esplicito degli elementi accessibili, notifiche di fuoco con argomento, rotori con cursore. SwiftUI ricostruisce le viste per differenza a ogni aggiornamento, e la stabilità del fuoco dipende dall'identità delle viste in modi fragili e difficili da garantire: è esattamente il difetto che 00 §11.2 definisce quello che rompe più spesso i giochi accessibili. La soluzione mista è stata scartata perché due tecnologie di interfaccia sono due comportamenti del fuoco da garantire, e il principio 7 chiede un solo linguaggio. Entrambe le tecnologie sono native, quindi 00 §2 è rispettato in ogni caso.

Conseguenze. Più codice di impianto per le schermate semplici; in cambio, un solo modello di fuoco, un solo modello di elementi, collaudabile. La scelta è rivedibile per singole schermate accessorie soltanto se una revisione futura dimostra, prove alla mano con VoiceOver, la piena equivalenza del comportamento del fuoco.

### RDA-03 — Elementi accessibili persistenti, aggiornati sul posto

Problema. Come garantire che il fuoco di VoiceOver non si perda quando il contenuto cambia (00 §11).

Opzioni. Ricostruire gli elementi a ogni aggiornamento e riposizionare il fuoco a mano; mantenere elementi persistenti e aggiornarne le proprietà.

Scelta. Un oggetto elemento per cella, creato una volta e mai ricreato durante l'uso; gli aggiornamenti mutano etichetta, valore e azioni dell'oggetto esistente (A §10.1).

Motivazione. Il fuoco di VoiceOver è ancorato all'identità dell'oggetto elemento: finché l'oggetto vive, il fuoco resta. Il riposizionamento manuale dopo ogni ricostruzione è una rincorsa che prima o poi si perde, e ogni caso perso è una violazione del principio 1.

Conseguenze. Le griglie hanno un ciclo di vita esplicito degli elementi; il collaudo di accessibilità può verificare l'identità degli elementi prima e dopo un aggiornamento (A §14.4).

### RDA-04 — Persistenza a giornale di comandi più istantanee

Problema. Realizzare il salvataggio automatico dello stato completo a ogni singola azione (00 §3.5) senza scrivere l'intero stato a ogni tocco.

Opzioni. Scrittura dell'intero stato a ogni azione; giornale dei comandi in appendice con istantanee periodiche; base dati relazionale.

Scelta. Giornale in appendice, una riga per comando, scritto prima che l'esito diventi visibile; istantanee complete ai confini significativi (A §6.1, §6.2).

Motivazione. L'appendice di una riga è economica quanto serve per non esitare mai a salvare; il determinismo del Motore (00 §3.1) garantisce che giornale più istantanea equivalgano allo stato completo. La scrittura integrale a ogni azione pagherebbe il costo dell'intero stato per ogni tocco; la base dati introduce uno schema parallelo allo stato senza dare nulla che il giornale non dia. Il giornale è inoltre esattamente la sequenza di comandi che la partita fra dispositivi scambia e che la rigiocatura ripercorre (00 §3.4): una sola struttura serve tre requisiti.

Conseguenze. La perdita massima possibile è l'ultimo comando (A §6.8); la rigiocatura è gratuita; ogni difetto segnalato dai tester è riproducibile allegando giornale e versione dei dati.

### RDA-05 — Annullamento e azzeramento come operazioni del giornale, non comandi

Problema. Come realizzare l'annullamento dell'ultima operazione e l'azzeramento dello schieramento (00 §13.8) in un'architettura a comandi.

Opzioni. Comandi inversi (ogni comando sa disfarsi); comando di annullamento che il Motore interpreta guardando la storia; troncamento del giornale con ricostruzione dallo stato precedente.

Scelta. Troncamento: l'annullamento ritira l'ultimo comando dal giornale e ricostruisce lo stato dall'istantanea più recente; l'azzeramento ritira tutti i comandi dal marcatore di inizio turno (A §6.4). Limite: mai oltre il più recente punto di conferma (A §6.5).

Motivazione. I comandi inversi obbligano ogni regola a essere scritta due volte, e ogni asimmetria fra le due è un difetto di coerenza; un comando di annullamento dentro il Motore romperebbe la purezza del modello, perché il Motore dovrebbe conoscere la storia oltre allo stato. Il troncamento sfrutta il determinismo già pagato e mantiene il giornale come sequenza delle sole scelte effettive: la rigiocatura e la partita fra dispositivi vedono le mosse, non i ripensamenti.

Conseguenze. Il costo dell'annullamento è una ricostruzione dall'istantanea, reso trascurabile dalle istantanee di inizio turno; il giornale resta pulito e monotono.

### RDA-06 — Generatore del caso con seme dentro lo stato

Problema. Il caso esiste (meteo, guasti: 01 §12.2) ma il determinismo è un requisito (00 §3.1, 01 §12.1).

Opzioni. Casualità di sistema; generatore con seme fuori dallo stato; generatore con seme e contatore dentro lo stato.

Scelta. Un unico generatore deterministico con seme e contatore nello stato; estrazioni soltanto in due punti dichiarati; ogni altra fonte vietata e sorvegliata dal collaudo (A §4.1, §4.2).

Motivazione. Con il seme nello stato, la stessa partita ripercorsa dà lo stesso meteo e gli stessi guasti: le simulazioni sono riproducibili (00 §16.1), i difetti segnalati sono riproducibili, la partita fra dispositivi condivide il seme e resta identica sui due lati.

Conseguenze. Il salvataggio contiene il caso già deciso e non ridecidibile; ricaricare non permette di ritentare la sorte, il che è anche una protezione del gioco.

### RDA-07 — Avversario interamente deterministico, parità risolte per ordine

Problema. Le scelte avversarie devono discendere da propensioni e valutazioni, non da estrazioni (01 §12.1), ma le valutazioni possono produrre parità.

Opzioni. Spareggio casuale; spareggio per criterio d'ordine fisso.

Scelta. Spareggio per criteri d'ordine deterministici sugli identificatori (A §4.3).

Motivazione. Un solo spareggio casuale renderebbe l'avversario non riproducibile e vanificherebbe le riproduzioni d'oro e le misure della Verifica. Un comportamento coerente si può imparare, ed è un pregio dichiarato del progetto.

Conseguenze. Due partite identiche restano identiche; l'eventuale prevedibilità fine dell'avversario si corregge con i parametri degli ufficiali, non con il caso.

### RDA-08 — Formule nel codice, coefficienti nei file, effetti come ganci tipizzati

Problema. I valori devono stare fuori dal programma (00 §13.1), ma le formule sono struttura; e i file non devono degenerare in un linguaggio di programmazione.

Opzioni. Formule interpretate dai file; tutto nel codice; formule nel codice e coefficienti nei file, con effetti scelti da un insieme chiuso di ganci.

Scelta. La terza (A §7.4, §7.7).

Motivazione. Le formule uniche condivise sono requisiti numerati (00 §13.3) e vanno collaudate come codice; un interprete di formule nei file sposterebbe la logica fuori dal collaudo e renderebbe ogni errore di battitura un difetto di gioco silenzioso. I ganci tipizzati permettono ad acquisizioni, opere e caratteristiche del campo di dichiarare effetti senza poter inventare meccaniche: ciò che il Motore non conosce viene respinto alla validazione.

Conseguenze. Aggiungere un tipo di effetto nuovo richiede una modifica al Motore, ed è giusto così: un effetto nuovo è una regola nuova.

### RDA-09 — Testi come pacchetti di localizzazione caricati da una cartella sostituibile

Problema. Tutti i testi fuori dal programma e modificabili senza ricompilare (00 §14.1, §15.4), ma i plurali devono usare il meccanismo di localizzazione del sistema (00 §14.3).

Opzioni. Testi in JSON con gestione dei plurali scritta a mano; cataloghi di stringhe compilati nell'applicazione; pacchetti .lproj in formato di sistema caricati a runtime da Documenti.

Scelta. La terza: `Bundle(path:)` su un albero Testi copiato in Documenti, con i formati di sistema per stringhe e plurali (A §8.1, §8.2).

Motivazione. È l'unica opzione che soddisfa entrambe le condizioni insieme: i plurali li gestisce il sistema, come impone 00 §14.3, e i file restano testo semplice, modificabile anche su iPad, come impone 00 §15.4. I cataloghi compilati richiederebbero la ricompilazione; i plurali a mano sono espressamente vietati.

Conseguenze. La versione inglese è un secondo pacchetto senza modifiche al codice; ogni testo viaggia con la propria lingua dichiarata fino all'annuncio (00 §14.4).

### RDA-10 — Programma di verifica come eseguibile SwiftPM su macOS

Problema. Dove e come far girare le migliaia di simulazioni (00 §16.1).

Opzioni. Bersaglio di collaudo dentro Xcode; applicazione iOS separata; eseguibile SwiftPM da riga di comando su macOS.

Scelta. Eseguibile SwiftPM (A §12.1).

Motivazione. Gira senza simulatore e senza dispositivo, si lancia da terminale e da integrazione continua, parallelizza sulle macchine di sviluppo, e importa gli stessi bersagli Motore e Dati del gioco: non esiste una seconda implementazione delle regole che possa divergere. Un bersaglio di collaudo confonderebbe misura e verifica; un'applicazione iOS aggiungerebbe attrito a ogni corsa.

Conseguenze. Il Motore resta multipiattaforma per costruzione, il che è anche la migliore sentinella del confine di RDA-01.

### RDA-11 — Predisposizione della partita fra dispositivi: sorgente di comandi, non protocollo di rete

Problema. La partita amichevole fra dispositivi vicini va resa possibile fin d'ora senza realizzarla (00 §3.4).

Opzioni. Realizzare subito il trasporto di rete; non fare nulla e rinviare tutto; definire ora l'interfaccia di sorgente dei comandi, la codifica stabile e l'impronta di stato, rinviando il solo trasporto.

Scelta. La terza (A §13.1).

Motivazione. Ciò che non si può aggiungere dopo è la disciplina: comandi serializzabili e versionati, determinismo totale, seme condiviso, impronta per rilevare le divergenze. Il trasporto, invece, è un dettaglio sostituibile. Realizzarlo ora violerebbe l'ordine di costruzione (00 §16.4); non predisporre nulla renderebbe la funzione una riscrittura.

Conseguenze. L'avversario interno è già una sorgente di comandi: il giorno della realizzazione si aggiunge una seconda sorgente, non un secondo gioco. Due avvertenze registrate. Prima: la trasmissione dei comandi all'altro apparecchio è differita ai punti di conferma (A §6.5), perché l'annullamento e l'azzeramento sono operazioni locali del giornale (RDA-05) e un comando già trasmesso non deve poter essere ritirato; la trasmissione immediata comando per comando è stata esaminata e scartata per questa ragione. Seconda: durante il turno di opacità dell'imboscata i comandi dell'imboscante raggiungono comunque l'altro apparecchio, che li applica senza presentarli; fra giocatori amichevoli, senza poste in gioco, la riservatezza del canale non è un requisito e non va trattata come tale.

### RDA-12 — Requisito minimo iOS 17

Problema. Fissare la base di sistema.

Opzioni. iOS 15 o 16 per la platea più ampia; iOS 17.

Scelta. iOS 17 (A §1.1).

Motivazione. Le interfacce di annuncio con priorità e le API aptiche e di accessibilità nella forma matura richiesta dal progetto sono complete da iOS 17; sostenere versioni precedenti significherebbe mantenere doppi percorsi proprio nel punto più delicato, gli annunci. La platea di TestFlight della fase di sviluppo non ne è ristretta in modo rilevante.

Conseguenze. Requisito da riverificare al momento della pubblicazione; mai abbassabile sotto la disponibilità delle API di accessibilità usate.

---

## Parte seconda — Chiusure dei punti aperti dei consolidati

Ogni voce indica dove la chiusura è registrata. Le voci contrassegnate come «incide sul gioco» sono riportate nei consolidati; le altre sono realizzative.

### RDA-13 — Ordine dei turni in battaglia (incide sul gioco; 01 §9.4.1)

Problema. Quale parte agisca per prima nella battaglia senza imboscata (01 §16.2 della versione 3.0).

Opzioni. Agisce per primo chi impone lo scontro; agisce per primo l'altro; agisce per primo chi occupava per primo la casella.

Scelta. Chi occupava per primo la casella.

Motivazione. È l'unica regola che copre tutti i casi senza eccezioni e coincide con l'imboscata già stabilita, dove chi attende agisce per primo: chi arriva sceglie tempo e luogo, chi attendeva riceve la prima mossa. Una regola sola da imparare, in ossequio allo spirito del principio 7. La variante «prima chi impone» premierebbe due volte l'aggressore; la variante «prima l'altro» creerebbe un caso speciale per la piazzaforte.

Conseguenze. Lo stato registra l'ordine di arrivo nella casella; nessuno spareggio è necessario perché gli arrivi sono sequenziali.

### RDA-14 — Base del riporto di volume (incide sul gioco; 01 §9.3.4)

Scelta. Tetto del dieci per cento calcolato sul budget di base del turno; il volume riportato si somma ma non genera a sua volta riporto. È la soluzione già proposta nei consolidati, adottata perché mantiene una sola grandezza annunciata e limita l'accumulo a un turno di profondità; l'alternativa composta avrebbe reso il tetto una funzione di se stesso, inspiegabile a voce.

### RDA-15 — Conteggio dei turni dei rinforzi (incide sul gioco; 01 §11.3)

Scelta. Dall'inizio della seconda battaglia, come proposto. La somma della durata della prima battaglia avrebbe legato la stima a un fatto esaurito e non più influenzabile, rendendo l'annuncio della stima meno utile alla decisione.

### RDA-16 — Ingresso dei rinforzi (incide sul gioco; 01 §11.8)

Scelta. Vincoli ordinari di profondità, ingresso attraverso il deck nella propria zona di schieramento. Una zona d'ingresso speciale sarebbe una seconda regola di schieramento da imparare e da annunciare; il vantaggio dei rinforzi resta il costo dimezzato, già stabilito.

### RDA-17 — Più elementi nella stessa cella (incide sul gioco; 01 §9.4.2)

Scelta. Il caso non esiste: una cella ospita al più uno sciame (01 §4.4) e le basi non sono occupabili. La questione, ereditata da versioni precedenti delle regole, si estingue per costruzione anziché ricevere una disciplina che non avrebbe oggetto.

### RDA-18 — Ritiro di un reparto in mischia durante la ritirata combattuta (conferma; 01 §10.4.1)

Scelta. Escluso, come 01 §10.4.1 già stabiliva: i reparti a contatto non sono controllabili e la ritirata salva chi era arretrato. Il punto era elencato fra i da confermare solo per il raccordo con 01 §9.5; il raccordo è coerente e non serve alcuna regola aggiuntiva.

### RDA-19 — Stanchezza senza terza specie (incide sul gioco; 01 §5.7, §5.7.2)

Problema. Entità e recupero della stanchezza, e rapporto fra riposo e stanchezza ordinaria.

Opzioni. Un contatore di stanchezza ordinaria alimentato dalla marcia sostenibile, con recupero nelle soste; nessuna stanchezza ordinaria: due sole fonti, marcia forzata e mancanza di provviste.

Scelta. Nessuna stanchezza ordinaria nella prima versione.

Motivazione. Il ritmo sostenibile è tale per definizione: farlo logorare significherebbe incorporare la sosta nella meccanica dopo averla esclusa dalla velocità media (01 §5.6.1). Un terzo contatore aggiungerebbe uno stato da annunciare a ogni gruppo e una regola di recupero da imparare, senza una decisione nuova per il giocatore: le decisioni vere — correre pagando, restare senza provviste pagando — esistono già. La sensibilità alla stanchezza degli archetipi resta il coefficiente che modula i malus esistenti.

Conseguenze. Il rapporto riposo-stanchezza ordinaria, lasciato aperto dal primo nodo, si chiude da sé; le entità dei moltiplicatori vanno in 03 §4.9.1.

### RDA-20 — Manutenzione a tre stati (incide sul gioco; 01 §5.7.1)

Scelta. Efficiente, logora, guasta; degrado per movimento e impiego; riparazione come azione di giornata, completa presso quartier generale o fortezza; d'inverno tutto torna efficiente. Due soli stati operativi perché 01 §12.3 chiede di annunciare la possibilità di guasto come alta o bassa: una scala più fine non sarebbe annunciabile con quel vocabolario. Il guasto resta l'unico esito casuale, dentro il perimetro di 01 §12.2.

### RDA-21 — L'approvvigionamento agisce sui parametri, non sul volume (incide sul gioco; 01 §5.8)

Motivazione della scelta. Il budget di volume rappresenta la capacità di manovra del comandante e fonda tutti gli annunci di costo: renderlo variabile con lo stato di rifornimento significherebbe che la stessa cella cambia costo per una causa lontana dal campo, il che confonde l'annuncio; e la privazione sarebbe contata due volte, sui parametri e sulla manovra. Simmetrico al trattamento di stanchezza e manutenzione: tutti gli stati di logoramento agiscono sui parametri.

### RDA-22 — Stagioni intermedie senza meccaniche dedicate (incide sul gioco; 01 §5.9.2)

Scelta. Nella prima versione estate e autunno differiscono solo per le probabilità meteo nei dati. Il titolare aveva rinviato la materia; la chiusura evita sia di inventare meccaniche non richieste (incendi, nebbia) sia di lasciare il punto indefinito. La struttura dei dati ne consente l'aggiunta futura senza toccare il programma.

### RDA-23 — Sabotaggio e studio approfondito deterministici (incide sul gioco; 01 §5.10.2)

Scelta. Sabotaggio: riesce sempre ai gruppi armati; agli esploratori solo con competenza sufficiente, altrimenti fallisce e li fa notare. Studio: riservato agli esploratori, porta a confermato la conoscenza della formazione studiata. Tutto deterministico, perché il caso resta confinato a meteo e guasti (01 §12.2): l'incertezza percepita nasce dall'informazione incompleta, non dai dadi. Le soglie di competenza vanno in 03 §4.8.3.

### RDA-24 — Magazzino, torri, ricognizione e taglio (incide sul gioco; 01 §5.15)

Scelta. Magazzino con la disciplina comune delle opere permanenti, su territorio conquistato; l'effetto delle torri in campagna era già stabilito ed è confermato; le formazioni di ricognizione non sono soggette al taglio del rifornimento. Sottoporre gli esploratori al taglio moltiplicherebbe gli annunci di stato senza aggiungere decisioni: il loro costo è già il rischio (01 §5.4.3), e la regola delle sei caselle è costruita sulle colonne.

### RDA-25 — Elenco chiuso delle azioni di campagna (incide sul gioco; 01 §5.6.8.1)

Scelta. Sedici azioni, elencate con i requisiti di categoria; riunione, revoca, accettazione, apertura della battaglia e dirottamento espressamente dichiarati non-azioni. Il criterio di inclusione: ogni azione già nominata nei consolidati e nelle direzioni, nessuna nuova. La distruzione di opera nemica e l'imposizione della battaglia consumano la giornata perché sono lavoro di una giornata (01 §5.14.7, §5.6.0.5); l'accettazione no, perché chi accetta non compie: subisce la volontà altrui (01 §6.1.1).

Conferma del titolare, in sede di revisione delle chiusure. L'imposizione della battaglia che consuma la giornata del gruppo è confermata così com'è, insieme alla conseguenza esaminata e accettata come voluta: fra l'arrivo dell'attaccante e la battaglia intercorre sempre una notte, e gli scontri campali della prima versione avverranno quasi soltanto contro chi non può o non vuole sfilarsi. Il peso di questa scelta sulla frequenza degli scontri ricade sulla taratura del carattere degli ufficiali e della velocità delle colonne (01 §6.1.3, 03 §6.5). La voce non va riaperta come se fosse una svista.

### RDA-26 — Ordine di risoluzione della giornata (incide sul gioco; 01 §5.6.11)

Problema. Il turno a un'azione per gruppo non stabiliva quando agissero i gruppi avversari.

Opzioni. Alternanza gruppo per gruppo; avversario prima; avversario dopo tutti i gruppi del giocatore.

Scelta. L'avversario agisce dopo, in ordine interno fisso; le risoluzioni di fine giornata seguono.

Motivazione. L'alternanza obbligherebbe il giocatore ad ascoltare mosse avversarie interlacciate alle proprie, moltiplicando gli annunci a metà giornata; e poiché l'informazione è comunque filtrata dalla conoscenza, l'ordine interno non rivela nulla. La forma scelta è la più semplice da annunciare: la giornata del giocatore, poi il mondo che risponde, poi la notte che chiude i conti.

Conseguenze. L'imboscata scatta nelle risoluzioni di fine giornata; il registro riporta ciò che la ricognizione ha visto.

### RDA-27 — Cinque ambiti e sequenza delle acquisizioni (incide sul gioco; 01 §2.8.2–2.8.2.2)

Problema. Quali ambiti concorrano alla soglia distribuita e quali acquisizioni compongano il passaggio arcaica-antica.

Opzioni. Ambiti ricalcati sulle cinque risorse; ambiti funzionali ricavati dai grappoli documentati; nessuna struttura fissa, solo elenco piatto.

Scelta. Cinque ambiti funzionali — armi e protezioni; montature e macchine; comando e trasmissione; logistica e vie; economia militare — con quindici acquisizioni per la prima versione, ordinate sull'appoggio della sequenza documentata delle sette innovazioni databili e degli intervalli delle non databili.

Motivazione. Gli ambiti funzionali rispecchiano le separazioni e le sostituzioni che definiscono la transizione (01 §2.5.2): ferro, moneta, trasmissione, cavalleria, macchine sono esattamente i capitoli della ricerca. Ricalcare le risorse avrebbe confuso il mezzo (con che cosa si paga) con il fine (che cosa cambia nel fare la guerra). L'elenco piatto non avrebbe sostenuto né i tetti d'epoca né la soglia distribuita. I numeri della soglia e i costi restano in 03 §4.7.3 e §4.7.4.

Conseguenze. Ogni ambito ha un'acquisizione finale per fase, che è il tetto d'epoca; l'elenco si estende nelle fasi future senza cambiare struttura; i nomi restano funzionali per il principio 12.

### RDA-28 — Nove archetipi, macchina da tiro distinta (incide sul gioco; 01 §3.2.3)

Scelta. Gli otto archetipi provvisori sono confermati e la macchina da tiro diventa il nono, distinto dalla macchina d'assedio da contatto. La distinzione è necessaria perché le macchine da tiro sono l'unica capacità presente nella fase antica e assente nell'arcaica (01 §2.5.4): se fossero una variante della macchina d'assedio, quella differenza per presenza non sarebbe rappresentabile senza tratti speciali.

### RDA-29 — Installazioni senza edifici di patria (incide sul gioco; 01 §5.5.2, §5.5.1.4.1)

Problema. L'elenco definitivo delle installazioni e le voci acquistabili fuori inverno.

Opzioni. Introdurre edifici di patria (piazza d'armi, arsenale, cantiere) con livelli e capacità; dichiarare che le installazioni sono le opere permanenti già definite e che le capacità di patria discendono dalle acquisizioni.

Scelta. La seconda; fuori inverno si comprano solo reclutamento, scorte e riparazioni.

Motivazione. Gli edifici di patria sarebbero una meccanica interamente nuova, mai nominata nei consolidati né nelle direzioni: introdurli in fase di architettura violerebbe il mandato. Le acquisizioni fanno già il lavoro che farebbero gli edifici — abilitare e limitare le capacità — e la patria resta la sede delle funzioni, non un secondo piano di costruzioni da gestire. Le tre voci brevi sono quelle già indicate dalla proposta accolta nella direzione dei nodi 2 e 3.

Conseguenze. Nessuna schermata di gestione edilizia della patria; il bilancio invernale resta l'unico luogo delle scelte di crescita.

### RDA-30 — Assedio della fortezza e sortita deterministica (incide sul gioco; 01 §5.14.3.6, §8b.5, §8b.5.1)

Scelta. La fortezza segue integralmente la sezione 8 bis; resistere in attesa di rinforzi è subire il blocco senza sortire; l'assalto resta sempre possibile all'aggressore; la sortita scatta a una soglia deterministica dipendente dall'ufficiale e dai malus, annunciata con termini di imminenza. La formulazione precedente («cresce la probabilità») è stata emendata perché l'avversario non estrae (01 §12.1) e il linguaggio della probabilità è riservato ai guasti (01 §12.3): il gioco non deve chiamare probabilità ciò che non lo è, per lo stesso principio per cui non mente mai.

### RDA-31 — Contenuto del resoconto di fine battaglia (incide sul gioco; 01 §15.3.1)

Scelta. Otto voci in ordine fisso, dalla più decisiva (esito) alla più accessoria (conseguenze sulla campagna), ciascuna un elemento accessibile in una frase, con i tagli di verbosità dalla coda. Il criterio d'ordine è lo stesso di 00 §9.5: ciò che si taglia per brevità dev'essere l'ultima voce, quindi le voci vanno ordinate per importanza decrescente.

### RDA-32 — Termini del vocabolario chiuso (incide sul gioco; 02 §4.4, §4.4.5)

Scelta. Termini brevi, concreti e mai sovrapposti fra insiemi: a tiro utile, a tiro di disturbo; disponibile, impegnato; munizioni piene, scarse, esaurite; in attesa, ha agito, in marcia, in agguato, scatto disponibile; senza provviste con il giorno, in rifornimento, in zona di rifornimento; efficiente, logora, guasta; sortita lontana, vicina, imminente. Criteri: nessuna parola condivisa fra i due stati che 02 §4.4.1.1 impone di non confondere (in attesa, scatto disponibile); i termini di gittata dicono l'uso (utile, disturbo) e non la distanza, perché è l'uso che il giocatore decide; i termini di manutenzione dicono lo stato della macchina e la coppia alta-bassa della possibilità di guasto resta nella spiegazione, come 01 §12.3 chiede.

### RDA-33 — Gesti fissi (incide sul gioco; 02 §6.7)

Scelta. Tocco magico a due dita per l'informazione di stato; gesto di fuga per la risalita di livello; rotore delle campagne attive per il passaggio diretto. Il tocco magico è il gesto di sistema pensato per l'azione principale contestuale ed è richiamabile da qualunque punto senza perdere il fuoco; il gesto di fuga è già il gesto universale di risalita e non va reinventato; il passaggio fra campagne come rotore, anziché come azione personalizzata, preserva il vincolo per cui le azioni personalizzate contengono solo spostamenti di navigazione locale (02 §2.7) e il loro numero per piano (02 §2.5).

### RDA-34 — Sequenza a due celle con doppia via (incide sul gioco; 02 §9.2.1)

Scelta. Elenco dei bersagli nel pannello oppure designazione sulla griglia, equivalenti; stato di attesa dichiarato; annullamento esplicito, per fuga, o automatico su nuova selezione, sempre annunciato; l'attivazione di una cella non valida spiega e non annulla. La doppia via è imposta da 02 §9.2 stesso (l'elenco per chi preferisce non navigare); l'annullamento automatico su nuova selezione evita lo stato pendente dimenticato, che sarebbe l'equivalente in battaglia dello scatto perso in silenzio che 01 §5.6.4.2 vieta.

### RDA-35 — Assegnazione dei pattern tattili (incide sul gioco; 02 §11.7.1)

Scelta. Cinque famiglie ritmiche (navigazione, conferma, combattimento, risorse, allarme), quindici significati, con intensità e nitidezza come sole sfumature interne. Il criterio di selezione degli eventi: hanno segnale tattile i fatti che colgono il giocatore mentre la sua attenzione è altrove o che scandiscono l'operazione in corso; restano solo sonori e testuali i fatti che arrivano già dentro un annuncio strutturato (rinforzi, stagione, passaggio di fase, ritorno del controllo). Il tetto di 02 §11.5 è rispettato con margine zero apparente ma reale, perché i quindici significati riusano cinque ritmi.

### RDA-36 — Rotori confermati con due aggiunte (incide sul gioco; 02 §7.2–7.4)

Scelta. Gli elenchi proposti sono confermati; si aggiungono il rotore dei propri sciami con azione non spesa (parità con chi vede il campo d'un colpo, stessa logica del rotore dei gruppi inattivi) e il rotore delle campagne attive (sede del passaggio diretto di RDA-33). Ordine interno di ogni rotore fisso e documentato.

### RDA-37 — Ordine delle informazioni dopo la testa fissa (incide sul gioco; 02 §3.8.1)

Scelta. Conoscenza, occupante con stato, anomalie in ordine fisso, opere, terreno e strada, note di zona; identico sui due piani; la condizione ordinaria non si annuncia. Criterio: prima ciò che decide (posso fidarmi? c'è qualcuno? in che stato?), poi ciò che qualifica (opere, terreno), infine ciò che contestualizza (zone); così i livelli di verbosità, tagliando dalla coda, tolgono contesto e mai decisione.

### RDA-38 — Impostazioni della prima versione (incide sul gioco; 02 §14.3)

Scelta. Intensità tattile a tre passi, volumi separati per effetti e ambiente, musica disattivabile; niente insiemi sonori alternativi nella prima versione. Le preferenze sono locali all'apparecchio: metterle nello stato di partita renderebbe un salvataggio dipendente dall'apparecchio su cui è nato, contro lo spirito di 00 §15.

### RDA-39 — Linguette invernali: basta l'ordinamento per durata (nodo 2-3 §15.4; realizzato in A §9.3)

Scelta. Nessun secondo criterio di raggruppamento dentro le linguette. Il dubbio della direzione era se l'ordinamento per durata bastasse: la risposta è sì, perché dentro ciascuna linguetta le voci sono decine e non centinaia, ogni voce dichiara le sole risorse che consuma (02 §8.7), e un secondo criterio costringerebbe il giocatore a imparare due chiavi di ricerca invece di una.

### RDA-40 — Lista dei nomi dei gruppi nei dati (incide sul gioco; realizzato in 03 §9.4, nomi-gruppi.json)

Scelta. La lista chiusa dei nomi propri risiede in un file dei dati; l'assegnazione è deterministica (il primo nome libero della lista, con numerale progressivo quando la lista si esaurisse); i nomi sono brevi, pronunciabili, privi di riferimenti storici (00 §12.1) e unici per campagna; la ridenominazione facoltativa esiste nel pannello del gruppo, fuori dal percorso obbligato, come la direzione del primo nodo ammette.

---

## Parte terza — Decisioni aggiunte a valle delle verifiche

### RDA-41 — La Sessione come orchestratore (A §1.7)

Problema. La prova di sufficienza ha mostrato che nessun modulo possedeva lo stato corrente, scriveva il giornale, pompava l'avversario e consegnava gli eventi: il collante del flusso non aveva un proprietario.

Opzioni. Orchestrazione dentro la Presentazione; orchestrazione dentro il Motore; bersaglio dedicato senza interfaccia.

Scelta. Il bersaglio Sessione: un attore per slot aperto, unico proprietario dello stato e unico scrittore del giornale, elaborazione seriale, scrittura confermata prima della visibilità, avversario pompato dalla Sessione attraverso le sorgenti di comandi, distinzione fra applicazione viva e riapplicazione.

Motivazione. Nella Presentazione violerebbe il principio 3 (la persistenza e il ciclo diventerebbero codice di interfaccia, non riusabile dalla Verifica); nel Motore ne romperebbe la purezza, perché il Motore diventerebbe proprietario di file e code. Il bersaglio dedicato serve gioco e Verifica con lo stesso codice.

Conseguenze. La Verifica riusa giornali e riproduzioni della Sessione; la partita fra dispositivi si innesta sostituendo una sorgente; la soppressione degli eventi in riapplicazione ha un proprietario.

### RDA-42 — I comandi dell'avversario si appendono al giornale (A §6.1)

Problema. Con un avversario deterministico, i suoi comandi si possono ricalcolare alla ripresa oppure registrare nel giornale; le due letture producono formati e riprese incompatibili.

Opzioni. Ricalcolo alla ripresa; registrazione nel giornale.

Scelta. Registrazione, con identificatore di parte; la ripresa riapplica senza reinterrogare l'avversario.

Motivazione. Il ricalcolo lega la ripresa ai parametri correnti: una modifica dei valori dichiarata compatibile cambierebbe le mosse già avvenute, corrompendo la partita in modo silenzioso. La registrazione rende il giornale l'unica verità, uniforme con la futura partita fra dispositivi, dove i comandi remoti arrivano comunque dall'esterno.

Conseguenze. Il giornale cresce di più; la garanzia di identità della partita non dipende dalla stabilità dell'avversario fra versioni.

### RDA-43 — Nascita della partita senza estrazioni del caso (A §2.10)

Problema. La generazione del mondo iniziale non era descritta: chi la compie, con quale casualità, da dove viene il seme.

Opzioni. Mondo estratto con il generatore del caso; mondo come funzione pura dei dati e della difficoltà.

Scelta. Funzione pura: la fabbrica del mondo nel Motore, nessuna estrazione; le differenze fra i regni sono fissate nei dati una volta sola (00 §13.2.3); seme e identificatore forniti dalla Sessione alla creazione e registrati nell'atto di fondazione, prima riga del giornale.

Motivazione. Estrarre il mondo violerebbe 00 §13.2.3, che vieta di riestrarre le differenze di partenza a ogni partita, e amplierebbe il perimetro del caso oltre 01 §12.2. La funzione pura rende la partita interamente definita da fondazione più comandi, che è la definizione su cui poggiano ripresa, rigiocatura e rete.

Conseguenze. La varietà fra partite viene dai contenuti e dalle scelte, non dal caso; il seme serve soltanto a meteo e guasti.

### RDA-44 — Virgola fissa nel Motore e codifica canonica per l'impronta (A §2.2.1, A §2.9)

Problema. La virgola mobile binaria non garantisce identità bit a bit fra piattaforme e versioni del compilatore; combinata con il troncamento, una differenza infinitesima produce interi diversi, rompendo impronte, riproduzioni d'oro e partita fra dispositivi. E l'impronta calcolata su una codifica non canonica cambierebbe a ogni riordino dei campi.

Scelta. Interi scalati su fattore fisso per tutte le grandezze del Motore, virgola mobile vietata nello stato e nelle formule, conversione dei coefficienti al caricamento; codifica canonica dedicata per l'impronta (campi in ordine dichiarato, interi a lunghezza fissa, insiemi ordinati) con SHA-256; riproduzione d'oro incrociata iOS-macOS nel collaudo.

Motivazione. È l'unico assetto in cui il determinismo di 00 §3.1 vale anche fra macchine diverse, ed è coerente con 00 §13.7, che già vuole grandezze di base grandi e intere.

Conseguenze. Le formule vanno scritte su aritmetica intera fin dal primo giorno; ogni tentazione di Double nel Motore è un difetto rilevabile dal collaudo.

### RDA-45 — Modalità di messa a punto per i valori modificati su apparecchio (A §7.2.1)

Problema. Il manifest con impronte e versione protegge i salvataggi (00 §15.1), ma il tester che modifica un coefficiente su iPad (00 §15.4) non ricalcola impronte né incrementa versioni: con la verifica rigida la messa a punto muore, senza verifica la versione registrata mente.

Opzioni. Verifica rigida delle impronte con ritorno alla fabbrica; nessuna verifica; versione locale derivata.

Scelta. Versione locale derivata: a impronte discordanti ma contenuti validi, il programma compone la versione base con un suffisso calcolato dalle impronte correnti, la registra nei salvataggi e la annuncia; la compatibilità si valuta sulla base, con avvertenza dichiarata.

Motivazione. Conserva insieme le due garanzie in conflitto: il flusso di modifica diretta previsto dalla carta e la riconducibilità di ogni difetto ai valori esatti con cui si è prodotto.

Conseguenze. Un salvataggio nato da valori ritoccati è riconoscibile per sempre; il programma di verifica può ricevere la stessa cartella di valori ritoccati e riprodurre la segnalazione.

---

## Parte quarta — Decisioni della revisione del titolare

### RDA-46 — Le perdite si contano sulle sole forze impiegate (incide sul gioco; 01 §10.2, §10.2.1)

Problema. Nella scrittura dello scontro la proporzione delle perdite, da cui dipende l'accorciamento della soglia della resa, era calcolata sul totale delle forze comprese le riserve non ancora schierate: chi perdeva poco rispetto a un esercito grande non poteva arrendersi presto, trattenuto dal peso di ciò che non aveva mai schierato. Il titolare ha stabilito l'intento opposto: una battaglia perduta si riconosce e si chiude per quel che accade sul campo.

Opzioni. Base sul totale delle forze, riserve comprese (la scrittura precedente); base sulle forze presenti sul campo nell'istante del calcolo; base cumulativa su tutto ciò che è sceso in campo fino a quel momento.

Scelta. La base cumulativa: un contatore per parte, che cresce a ogni piazzamento della somma di punti vita con cui il reparto scende in campo, rinforzi compresi quando verranno. Proporzione = perdite cumulative diviso forze impiegate; prima di qualunque piazzamento la proporzione è zero. La medesima base vale per la ritirata combattuta e per ogni soglia dipendente dalle perdite; resta distinta, per natura, la soglia di disingaggio calcolata per singolo contatto (01 §9.8).

Motivazione. La base sul campo nell'istante del calcolo oscillerebbe con le evacuazioni e con le distruzioni (un esercito distrutto quasi del tutto avrebbe base quasi nulla e proporzioni paradossali); la base cumulativa è monotona, deterministica, calcolabile dal solo stato, e realizza l'intento: chi impegna poco e perde quel poco conclude presto, chi sceglie di impegnare altro riallunga la propria soglia con le proprie mani.

Conseguenze. Contatore nuovo nello stato e nell'impronta; la riproduzione d'oro resta valida perché in quello scontro l'intero mazzo scende in campo e le due basi coincidono; tenere riserve non ritarda più la possibilità di arrendersi, e la stima del peso delle riserve passa interamente alla taratura.

### RDA-47 — Nessun fuoco amico, regola dichiarata (incide sul gioco; 01 §9.6.2)

Problema. Il motore dello scontro già impediva di prendere a bersaglio i propri reparti, ma come conseguenza tacita della validazione, non come regola del gioco: una sessione futura avrebbe potuto introdurre il fuoco amico credendo di correggere una dimenticanza.

Scelta. Regola dichiarata nel consolidato: i reparti da tiro colpiscono soltanto avversari, non esiste fuoco amico in alcuna forma, e battere un nemico impegnato in mischia con propri reparti è lecito e senza rischio per i propri. Il principio è generale: nessuna regola del gioco può danneggiare le forze di chi la esegue per effetto di un'azione rivolta all'avversario. Verificato che valga in ogni punto in cui si producono perdite: il tiro convalida il bersaglio come avversario, l'ingaggio pure, e la mischia infligge perdite soltanto fra i due contendenti del contatto.

Conseguenze. Una prova di collaudo dedicata accerta la persistenza della regola (tiro sul proprio respinto, tiro sul nemico impegnato senza danno ai propri); la scelta tattica di battere la mischia dal di fuori resta lecita e senza contropartita, e il suo eventuale peso è materia di taratura dei valori del tiro.

---

## Parte quinta — Decisioni della fase di infrastruttura

### RDA-48 — Segnali come bersaglio del pacchetto con compilazione condizionale (A §1.2)

Problema. Il bersaglio Segnali importa i framework di piattaforma (UIKit, CoreHaptics, AVFoundation), ma il pacchetto deve compilare anche su macOS, dove girano il collaudo e il programma di verifica: la sessione della fase A aveva lasciato aperta la scelta fra compilazione condizionale e spostamento del modulo nel solo progetto applicativo.

Opzioni. Bersaglio soltanto nel progetto applicativo Xcode (fuori dal pacchetto); pacchetto separato solo iOS; bersaglio nel pacchetto con le parti di piattaforma dietro `#if canImport(UIKit)`.

Scelta. La terza: Segnali resta un bersaglio del pacchetto, come 05 §1.2 dichiara. Il nucleo di decisione dei canali (05 §11.3) è puro e compila ovunque, con le proprie prove eseguite dal collaudo ordinario; le realizzazioni di piattaforma (aptica, suoni, annunci) vivono dietro compilazione condizionale e prendono corpo nella fase B.

Motivazione. Spostare il modulo nel progetto applicativo lo sottrarrebbe al collaudo dei confini e contraddirebbe l'architettura senza necessità; un pacchetto separato aggiungerebbe un artefatto per un problema che una direttiva di compilazione risolve. Con la scelta adottata la tabella eventi-canali resta collaudabile su macOS, che è dove il collaudo gira a ogni invio.

Conseguenze. Il collaudo dei confini conosce l'insieme degli import ammessi di Segnali, framework di piattaforma compresi; l'integrazione continua esegue anche le prove del nucleo dei canali; la parte di piattaforma andrà scritta interamente dentro i blocchi condizionali.


### RDA-49 — Completamenti di presentazione della fase B (02 §2.8, 00 §7.4)

Problema. Tre punti che i documenti non normavano riguardo alla schermata dello scontro: dove stiano la resa e la fine del turno nell'ordine di lettura; con quale controllo realizzare il pannello della cella; l'attivazione di una cella con un elemento selezionato.

Scelta. L'ordine di lettura prosegue oltre i comandi obbligatori di 02 §2.8: celle, deck, annullamento, azzeramento, poi resa e fine del turno. Il pannello della cella è nella fase B l'avviso di sistema, che è nativamente accessibile e restituisce il fuoco alla cella d'origine alla chiusura tramite il guardiano del fuoco; una realizzazione propria è ammessa in seguito solo a parità di comportamento del fuoco provata. L'attivazione di una cella con un elemento del deck selezionato piazza direttamente, senza pannello: è la conferma dello schema seleziona-naviga-conferma (00 §8.2), e il pannello resta per le celle occupate da un proprio reparto senza selezione attiva.

Conseguenze. Nessuna regola nuova per il giocatore; l'ordine è dichiarato e stabile; la scelta del pannello è rivedibile con i ritorni dei tester.

---

## Parte sesta — Decisioni dell'intervento correttivo della fase B

### RDA-50 — Il deck come tessere in riga scorrevole (02 §8.1, §8.2; 00 §1.2)

Problema. Nella prima stesura della fase B gli elementi del deck erano pulsanti ordinari impilati sotto la griglia, identici ai comandi globali alla vista e all'ascolto; e la pila, sommata all'altezza della griglia imposta al 55 per cento, produceva vincoli insoddisfacibili con elementi schiacciati fuori dall'aggancio di VoiceOver (scostamento S3, primo collaudo su dispositivo).

Opzioni. Pulsanti in pila dentro uno scorrimento verticale; tessere-riquadro in una riga orizzontale scorrevole; griglia più bassa a valore fisso.

Scelta. Tessere (`TesseraDeck`, controllo proprio): riquadro con bordo, nome dell'archetipo come etichetta, valore in ordine fisso — atomi, volume, esemplari residui, selezione — e suggerimento d'uso da chiave dei testi; nessun ruolo di pulsante, così all'ascolto non si confondono con i comandi globali; tratti di selezione e disabilitazione; aggiornate sul posto (RDA-03). La riga riempie la larghezza quando le tessere sono poche e scorre quando saranno tante (i rinforzi), mai comprimere; la tessera fuori vista che riceve il fuoco si porta in vista da sé. L'altezza della griglia diventa desiderata a bassa priorità: quando lo spazio manca cede alla colonna, restando scorrevole e ingrandibile (00 §10.4).

Motivazione. 02 §8.2 impone che ogni elemento del deck annunci identità, atomi, volume; il principio 1 impone che tutto sia agganciabile; l'ordine di lettura di 02 §2.8 e RDA-49 resta immutato. Lo scorrimento verticale della pila avrebbe conservato la confusione con i comandi globali; la griglia fissa più bassa avrebbe solo spostato il punto di rottura.

Conseguenze. Chiavi nuove nei testi di fabbrica (`deck.volume`, `deck.elemento_indicazione`), versione dei testi 0.1.1; la vecchia chiave composita `deck.elemento` è rimossa; la selezione si annuncia nel valore, quindi l'aggiornamento non muove il fuoco (00 §11.3).

### RDA-51 — Il collaudo accerta la raggiungibilità, non la sola dichiarazione (00 §1.2, 05 §14.4)

Problema. Le prove della fase B verificavano esistenza, identità ed etichette; su dispositivo elementi dichiarati risultavano non agganciabili (scostamento S3).

Opzioni. Affidare la raggiungibilità alla sola prova manuale su dispositivo; verificarla in automatico fin dove possibile e dichiarare il resto.

Scelta. La seconda. Ogni schermata ha una prova di raggiungibilità sul formato di schermo piccolo: il lettore dell'ordine effettivo (`LettoreAccessibilita`) percorre gli elenchi dichiarati come la tecnologia assistiva e accerta presenza nel percorso, etichetta, cornice non degenere, posizione nello schermo o in contenitore scorrevole, bersagli di almeno 44 punti; il fumo d'interfaccia esercita il tocco vero. Ciò che l'automazione non può cogliere — pronuncia, gesti di sistema, aptica, scorrimento al fuoco, caratteri molto grandi — è dichiarato espressamente in `collaudo-solo-dispositivo.md`, consegnato ai tester con ogni build.

Motivazione. Un elemento non raggiungibile è una violazione del principio 1, della stessa gravità di un blocco del programma: il collaudo deve poterla vedere prima del dispositivo. La sola prova manuale non scala e arriva tardi; l'automazione senza dichiarazione dei limiti darebbe una falsa completezza (il verde della fase B).

Conseguenze. Le schermate future nascono con la prova di raggiungibilità; l'elenco delle verifiche da dispositivo è un documento vivo, aggiornato quando l'automazione si estende o una prova manuale scopre un buco nuovo.

### RDA-52 — Scala e soglie delle fasce descrittive degli esiti (01 §9.7.2, 03 §5.14)

Problema. La prima tranche di semplificazioni sopprime i numeri di danno dagli annunci dei combattimenti e delega la scala esatta e le soglie alla realizzazione.

Opzioni. Tre fasce; quattro fasce più lo stallo; cinque fasce.

Scelta. Quattro fasce per direzione — nessuna perdita, perdite lievi, perdite significative, perdite gravi — più lo stallo come termine del contatto senza perdite da ambo i lati. Soglie deterministiche calcolate come proporzione del danno sulla consistenza del reparto colpito immediatamente PRIMA dell'applicazione: lievi fino al 10 per cento, significative fino al 30, gravi oltre; nei file di dati (`combattimento.json`) con contrassegno di provvisorietà. Nel vocabolario chiuso le fasce vivono come frasi complete declinate per direzione (perdite inflitte lievi, perdite subite gravi, …), perché l'accordo grammaticale non si costruisca incollando parole (00 §14.2). La stessa scala vale per la mischia e per il tiro: un solo linguaggio (00 §7).

Motivazione. La consistenza prima dell'applicazione è l'unica base che il solo stato conosce al momento dell'evento e rende la fascia indipendente dall'ordine di applicazione dei danni simultanei. Il 10 e il 30 per cento dividono la scala in zone percepibili distinte; sono numeri di lavoro e la taratura appartiene ai ritorni dei tester e alle simulazioni.

Conseguenze. Gli eventi del Motore trasportano la fascia già calcolata (il traduttore non conosce lo stato); i numeri di danno restano fatti interni dell'evento, mai annunciati.

### RDA-53 — Realizzazione delle lettere dei reparti (01 §9.4.3)

Problema. La lettera deve essere stabile per l'intero scontro, mai riusata, identica all'ascolto e alla vista, e sopravvivere a salvataggio e ripresa.

Opzioni. Derivarla ogni volta dall'ordine degli identificatori vivi; conservarla nello stato con un contatore per parte.

Scelta. La seconda: ogni sciame porta la propria lettera come ordinale assegnato al piazzamento, e lo stato conserva la prossima lettera per parte, che cresce e non torna mai indietro; entrambi entrano nell'impronta canonica. La Presentazione risolve l'ordinale nel termine chiuso del vocabolario (`lettera.1` … `lettera.40`: le ventisei singole e poi le doppie), lo annuncia in posizione fissa dopo il nome e lo disegna nella cella.

Motivazione. La derivazione dagli identificatori vivi riuserebbe le lettere quando un reparto esce dal campo, che è precisamente ciò che il titolare vieta; il contatore nello stato rende la regola un fatto del Motore, riproducibile dal giornale e verificabile dall'impronta.

Conseguenze. Sciame e stato crescono di un campo; quaranta voci nel vocabolario chiuso bastano con margine ampio ai formati della prima versione; superarle è un errore visibile (segnaposto), non un silenzio.

### RDA-54 — Il manifest dei testi porta le impronte dei file (03 §9.5)

Problema. La copia dei testi in Documenti si rinfresca soltanto quando i byte del manifest cambiano; con il manifest ridotto a versione e lingue, ogni aggiunta di chiavi obbligava ad alzare la versione — vietato dalla regola del titolare sulle versioni — o lasciava le installazioni esistenti con testi vecchi (accaduto nel collaudo di questa stessa tranche: la lettera non compariva perché la copia del simulatore era stantia).

Opzioni. Alzare la versione dei testi a ogni modifica; confrontare le impronte dei file a ogni avvio; includere le impronte nel manifest, come già fa quello dei valori.

Scelta. La terza, che era l'alternativa già annotata nella memoria di infrastruttura: il manifest dei testi elenca le impronte dei file di lingua e ogni modifica ai testi le rigenera; il confronto dei byte del manifest fa il resto, senza toccare la versione e senza costi d'avvio aggiuntivi.

Conseguenze. Regola operativa nuova nella memoria di infrastruttura: chi tocca un file in `Contenuti/Testi/` rigenera le impronte del manifest, come già per i valori. La versione dei testi resta materia esclusiva del titolare.

## Parte settima — Decisioni del limite dei bersagli simultanei

### RDA-55 — I contatti entrano nell'impronta nell'ordine di arrivo (05 §2.9)

Problema. Il limite dei bersagli simultanei (01 §9.11) fa dipendere la risposta di un reparto dall'ordine in cui i nemici lo hanno ingaggiato. Fino alla versione precedente la codifica canonica dell'impronta ordinava i contatti per identificatore, sul presupposto — allora vero — che il loro ordine fosse irrilevante. Con la regola nuova due stati identici in tutto salvo l'ordine di arrivo si comportano in modo diverso e avrebbero avuto la stessa impronta.

Opzioni. Conservare l'ordinamento e aggiungere allo stato un campo esplicito con il posto di ciascun contatto; serializzare i contatti nel loro ordine di elenco.

Scelta. La seconda. L'elenco dei contatti è già in ordine di arrivo per costruzione — vi si appende all'ingaggio e se ne rimuove senza riordinare — ed è deterministico, perché discende dalla sequenza dei comandi del giornale. Serializzarlo così è insieme canonico e corretto, e non aggiunge alcun campo allo stato.

Motivazione. Un campo esplicito con i posti sarebbe stato un secondo luogo della verità da tenere in sincronia con l'elenco a ogni disfacimento e a ogni disingaggio, cioè esattamente la duplicazione che 05 §2.7 evita derivando i fatti anziché copiarli. Il criterio generale che ne discende è ora scritto in 05 §2.9: la canonicità serve a distinguere stati diversi, quindi non può cancellare un ordine significante.

Conseguenze. Tutte le impronte cambiano e i copioni d'oro si rigenerano; la successione automatica nei posti liberati (01 §9.11.2) diventa gratuita, perché rimuovere un contatto fa scorrere in avanti i successivi senza alcun codice dedicato.

### RDA-56 — Il posto si legge dall'elenco, e il terzo non produce danno anziché produrne zero

Problema. Realizzare 01 §9.11 senza rompere la simultaneità della risoluzione (01 §9.7.1) e senza cadere nel minimo obbligatorio di 00 §13.6, che riporterebbe a uno qualunque danno calcolato con coefficiente nullo.

Scelta. Il posto di un nemico è l'indice del suo contatto fra i contatti di quel reparto, letto dallo stato con cui il giro si apre; i posti si leggono una volta sola, prima di applicare qualunque danno, quindi valgono identici per tutti i contatti del giro e l'ordine interno di risoluzione — che il Motore percorre per identificatore — non li tocca. La resa di risposta è piena al posto zero, il valore dei dati al posto uno, e ASSENTE dal posto due: la funzione restituisce un opzionale vuoto e il Motore non calcola alcun danno, invece di calcolarne uno con coefficiente nullo.

Motivazione. La distinzione fra «danno nullo» e «nessun danno» non è formale: 00 §13.6 impone il minimo di uno dove il troncamento potrebbe produrre zero, e un coefficiente nullo vi ricadrebbe, facendo passare un punto di danno dove la regola ne vuole nessuno. Il minimo esiste contro il troncamento, non contro l'assenza di un colpo.

Conseguenze. Un contatto può produrre perdite in una direzione sola; le fasce descrittive lo esprimono già (02 §8.9.1) e nessun termine nuovo è servito. La soglia di disingaggio non scatta mai per chi non riceve risposta, il che è dichiarato in 01 §9.11.2.1.

### RDA-57 — L'annientamento simultaneo è un interruttore nei vantaggi nascosti (01 §15.2.5)

Problema. Con entrambe le parti annientate nello stesso giro, 01 §15.2.3 non designa lo sconfitto e 01 §15.2.2 vieta la parità. Il comportamento precedente lo assegnava al giocatore per l'ordine di un'enumerazione, cioè per caso.

Opzioni. Introdurre un esito di parità; assegnare l'esito con una regola dichiarata.

Scelta. La seconda, con il verso stabilito dal titolare — sconfitto è l'avversario — e la regola iscritta fra i vantaggi nascosti, quindi nel file `vantaggi-nascosti.json` come interruttore booleano e non nel codice.

Motivazione. La parità avrebbe contraddetto 01 §15.2.2 e obbligato a rifare il resoconto, il ritorno in campagna dei punti da 15.4 a 15.6, che presuppongono un vincitore, e le registrazioni: molte conseguenze per un caso raro. La forma dell'interruttore discende da 03 §7.1 e 05 §12.5: un vantaggio nascosto deve essere disattivabile, altrimenti il programma di verifica misura probabilità irreali. Spento, l'esito torna a cadere sul giocatore: non è una terza regola ma il caso reale che la Verifica deve poter osservare.

Conseguenze. L'annientamento di una sola parte non è toccato. Il caso simultaneo diventa un po' meno raro con il modificatore di accerchiamento, che accresce i danni: ragione in più perché sia normato anziché lasciato all'ordine di un'enumerazione.

## Parte ottava — Decisioni della fase C

### RDA-58 — Il programma di verifica è una libreria più un guscio (05 §12.1)

Problema. 05 §14.7 vuole una corsa breve del programma di verifica dentro il collaudo, e 05 §12.1 lo descrive come eseguibile da riga di comando. Un bersaglio eseguibile non si importa da un bersaglio di prova senza attriti, e il fumo delle simulazioni sarebbe rimasto fuori dal collaudo o vi sarebbe entrato lanciando un processo, che è fragile e lento.

Opzioni. Lasciare tutto nell'eseguibile e collaudarlo lanciandolo come processo; dividere in una libreria di misura più un guscio che si limita a leggere gli argomenti e stampare.

Scelta. La seconda. La libreria `Verifica` contiene scenari, banchi, corse e rapporto; l'eseguibile `StrumentoVerifica` contiene soltanto la lettura degli argomenti e la scrittura dell'uscita. Il collaudo importa la libreria e ne esercita una corsa breve come qualunque altra prova.

Motivazione. Il fumo delle simulazioni è un requisito e non un accessorio (00 §16.1): deve fallire come falliscono le altre prove, nello stesso comando e con lo stesso rapporto. Lanciare un processo avrebbe reso il collaudo dipendente dalla presenza del binario compilato e dall'ambiente.

Conseguenze. Il comando cambia nome: `swift run StrumentoVerifica` in luogo di `swift run Verifica`. I confini fra bersagli valgono anche qui e sono verificati: il guscio importa la sola libreria di misura, e la libreria espone le cartelle di fabbrica perché il guscio non debba importare Contenuti.

### RDA-59 — La variazione viene dagli assi dichiarati, non dai semi (05 §12.3.1)

Problema. 05 §12.6 prevede che ogni riga di uscita porti il seme, perché la misura sia riproducibile. Sul piano di battaglia il seme non ha oggetto: non esiste alcuna estrazione del caso (01 §12.1) e il tattico è deterministico, quindi ogni corsa sulla stessa configurazione dà lo stesso esito e mille semi darebbero mille righe identiche.

Opzioni. Introdurre una perturbazione casuale negli scenari per ottenere una distribuzione; enumerare gli estremi delle forbici come assi dichiarati e fare della configurazione ciò che il seme è altrove.

Scelta. La seconda. Ogni scenario dichiara i propri assi da un insieme chiuso — primo occupante, coppie di ufficiali, vantaggi accesi e spenti, imboscata — e il programma percorre il prodotto in ordine deterministico. La riga di uscita porta la configurazione al posto del seme.

Motivazione. Introdurre caso dove il gioco non ne ha significherebbe misurare una cosa diversa da quella che si gioca, e violerebbe lo spirito di 01 §12.1. Gli estremi delle forbici sono per di più ciò che 00 §13.2.4 prescrive di provare: la scelta non è un ripiego ma la forma giusta.

Conseguenze. La riproducibilità è totale e collaudata: due corse sugli stessi dati danno lo stesso identico rapporto, carattere per carattere. Quando la fase D introdurrà meteo e guasti, il seme tornerà ad avere oggetto e si affiancherà agli assi sul piano di campagna, senza toglierli.


## Parte nona — Decisione della risoluzione immediata

### RDA-60 — Il contatto si risolve quando si forma, i disingaggi restano a inizio giro (01 §9.7.1, §9.8.5)

Problema. La misura della fase C ha mostrato che, con mazzi identici e condotta identica, chi muoveva per primo perdeva in ventuno configurazioni su ventiquattro. La causa era la sequenza del giro: i contatti si risolvevano tutti alla fine, quindi chi si impegnava per primo consegnava all'avversario un turno intero per portargli altri nemici addosso prima di scambiare un colpo.

Opzioni. Cambiare l'ordine dei turni; risolvere ogni contatto quando si forma; risolvere a metà giro.

Scelta. La seconda, per decisione del titolare, che ha escluso di toccare l'ordine dei turni. Un contatto si risolve nell'istante in cui si forma e poi all'inizio di ogni giro finché dura. La risoluzione immediata riguarda il SOLO contatto che si è appena formato; le altre mischie in piedi attendono il giro.

Sotto-decisione presa in corso d'opera e registrata perché non era ovvia: la soglia di disingaggio NON si valuta nello scambio immediato, ma solo a inizio giro. La prima realizzazione la valutava a ogni risoluzione, e il risultato era un reparto che poteva ritrarsi nello stesso turno in cui gli era stato ordinato di attaccare — comportamento che nessuna regola prevede e che 01 §9.8.2 esclude, dichiarando che chi si sfila torna controllabile dal turno successivo. Se ne è accorto il collaudo, che è cominciato a cadere a cascata su fixture che presupponevano contatti stabili.

Motivazione. Agire sulla sequenza anziché sull'ordine dei turni conserva 01 §9.4.1, che il titolare vuole intatto, e colpisce la causa misurata anziché un suo sintomo. Risolvere il solo contatto formato, e non tutti, conserva la simultaneità dove serve e la toglie dove produceva l'ingiustizia.

Conseguenze. La simultaneità resta intera dentro una risoluzione e cade fra risoluzioni diverse dello stesso turno: i posti in mischia e gli insiemi dei concorrenti si leggono all'apertura di ciascuna risoluzione, non una volta per giro (01 §9.11.1, §9.10.2.3 riformulati). L'evento di contatto porta ora il proprio esito, come quello di tiro, e l'annuncio segue l'azione (02 §8.9.2). Tutte le impronte cambiano e i copioni d'oro si rigenerano. Misura dopo la modifica: chi muove per primo perde in tredici configurazioni su ventiquattro, cioè quanto il caso.

## Parte decima — Decisioni della prima unità della fase D (la mappa navigabile)

### RDA-61 — La giornata si chiude da sé, e non esiste alcun comando di fine giornata (01 §5.6.0.6)

Problema. L'incarico della sessione dice che «la giornata si chiude su comando del giocatore», mentre 01 §5.6.0.6 stabilisce che «il turno di campagna si chiude automaticamente quando tutti i gruppi hanno agito, e non esiste alcun comando di fine giornata», regola richiamata da 05 §3.8 e da 01 §5.6.9.2. Le due formulazioni non possono valere insieme.

Opzioni. Aggiungere un comando esplicito di fine giornata, seguendo la lettera dell'incarico; conservare la chiusura automatica del consolidato.

Scelta. La chiusura automatica. La frase dell'incarico si legge come descrizione di ciò che accade: la giornata si chiude PER EFFETTO dell'ultimo ordine del giocatore e mai per iniziativa del programma, e la frase che segue nell'incarico stesso — «nessuna azione automatica» — chiede precisamente questo, cioè che nessun gruppo agisca da sé.

Motivazione. 01 §5.6.0.6 è una decisione presa, e l'incarico vieta di riaprire decisioni prese; 05 §0.3 fa inoltre prevalere il consolidato sulle regole di gioco. La lettura adottata le concilia entrambe senza forzare nessuna delle due. Se il titolare volesse davvero un comando esplicito, la modifica costa una voce di comando e un pulsante, mentre l'errore opposto avrebbe contraddetto una regola scritta.

Conseguenze. Stare fermi resta un'azione ordinabile e non un'omissione: il presidio esiste proprio perché la giornata possa chiudersi anche quando non si vuole marciare. Un invariante del programma di verifica sorveglia che nessun gruppo spenda l'azione senza averne ricevuto l'ordine.

### RDA-62 — La mappa riusa la cella della battaglia; il termine parlato è «casella»

Problema. La mappa di campagna ha bisogno di un tipo per la posizione e di una testa fissa per l'annuncio. Il principio 7 ammette una sola differenza fra i due piani, cioè il numero di celle vicine.

Opzioni. Un tipo di posizione proprio della campagna; il riuso di `Cella`, che la battaglia già usa come coppia riga-colonna.

Scelta. Il riuso di `Cella`, con una `GrigliaCampagna` propria per la sola adiacenza. Nell'annuncio la testa fissa conserva la stessa struttura — riga, poi posizione nella riga — e cambia la sola parola: «riga 7, casella 4» sulla mappa, «riga 7, cella 4» in battaglia.

Motivazione. Riga e colonna significano la stessa cosa sui due piani, l'ordine di lettura è lo stesso, e un tipo gemello avrebbe soltanto duplicato le conversioni. Sulla parola: i consolidati chiamano «caselle» quelle della mappa e «celle» quelle della griglia, e seguirli evita che il documento e la voce dicano cose diverse; ciò che il principio 7 protegge è la STRUTTURA dell'annuncio, che resta identica.

Conseguenze. Ordine di lettura, ordinamento dei rotori e impronte funzionano sui due piani con lo stesso codice. Se le prove con i tester mostrassero che le due parole confondono, la materia si riapre cambiando una chiave di testo.

### RDA-63 — Il quartier generale è geografia dichiarata dalla mappa e occupa il posto delle opere nell'annuncio

Problema. 02 §3.8.1 fissa l'ordine delle informazioni dopo la testa fissa e nomina «le opere presenti nella casella», ma il quartier generale non è un'opera: è il perno della mappa (01 §5.2.1) ed esiste prima di qualunque costruzione.

Scelta. I due quartier generali sono parte della definizione della mappa, come 05 §7.6 già prevede, e ciascuno sta in ultima riga dalla propria parte (01 §5.14.3.2), il che la validazione impone. Nell'annuncio occupano il posto delle opere: dopo l'occupante, prima del terreno.

Motivazione. È il posto che l'ordine registrato assegna a ciò che sta stabilmente nella casella e non vi si muove. Collocarlo altrove avrebbe richiesto di riaprire 02 §3.8.1, che è chiuso.

Conseguenze. La posizione del quartier generale avversario è nota fin dall'inizio, come le regole già prevedono (01 §5.14.3.2 la dà per acquisita). Non è informazione di ricognizione e non passa dagli stati di conoscenza.

### RDA-64 — La chiusura della giornata non aggiunge un significato tattile

Problema. Il cambio di giornata è un fatto rilevante, ma 02 §11.5 chiude il tetto dei significati a quindici e 02 §11.7.1 chiude anche l'elenco degli eventi che restano fuori dal tetto con suono dedicato. Il cambio di giornata non compare in nessuno dei due.

Opzioni. Aggiungere un sedicesimo significato; riusare un significato esistente; lasciare il solo annuncio.

Scelta. Il solo annuncio, senza segnale proprio.

Motivazione. La chiusura arriva sempre nell'istante immediatamente successivo a un ordine del giocatore, che porta già il segnale di conferma: un secondo segnale a un decimo di secondo dal primo sarebbe carico senza informazione. L'annuncio è testo, non si perde, e il fatto resta recuperabile nel registro (02 §6.6.1), che è il canale di recupero dichiarato per la mappa di campagna. Riusare un significato altrui avrebbe rotto la corrispondenza uno a uno fra segnale e significato.

Conseguenze. Se la prova su dispositivo mostrasse che il cambio di giornata passa inosservato, la materia si riapre e richiede una versione nuova di 02 §11.7.1, non una modifica locale.

### RDA-65 — Il nome del gruppo vive nello stato come chiave, non come indice

Problema. I nomi dei gruppi vengono da un elenco chiuso e ordinato dei dati (01 §5.6.0.4). Il gruppo può portarne l'indice oppure la chiave.

Scelta. La chiave, iscritta nello stato alla nascita del gruppo.

Motivazione. Il nome è «breve e stabile, che conserva per tutta la propria esistenza». Con l'indice, allungare o riordinare l'elenco nei dati rinominerebbe i gruppi delle partite in corso; con la chiave, il nome resta quello ricevuto. La chiave entra inoltre nell'impronta e negli eventi, sicché Segnali risolve il nome parlato senza dover leggere i valori di campagna.

Conseguenze. L'elenco dei nomi si può ampliare senza toccare i salvataggi. Un nome tolto dall'elenco lascerebbe un gruppo con una chiave irrisolvibile: il collaudo verifica che ogni chiave dell'elenco abbia il proprio testo, e togliere una chiave in uso resta una modifica da fare con revisione esplicita.

### RDA-66 — I comandi di campagna si aggiungono al giornale esistente; la campagna vive in uno slot proprio

Problema. Il giornale è anche il formato di salvataggio (05 §6.1). La campagna vi aggiunge una famiglia intera di comandi, ed è il caso che la fase B aveva segnalato come pericoloso.

Opzioni. Un formato di giornale separato per la campagna; casi nuovi nello stesso enumerativo.

Scelta. Casi nuovi nello stesso enumerativo — `fondazioneCampagna`, `comandoCampagna`, `aperturaGiornata` — e slot di partita distinti sul disco.

Motivazione. La codifica sintetizzata degli enumerativi con valori associati usa il NOME del caso come chiave e non la sua posizione: aggiungere un caso non tocca la codifica degli altri. Il fatto non è stato dato per buono ma provato, e nell'ordine giusto: i campioni dei tre casi preesistenti e un salvataggio della build distribuita sono stati fissati e visti verdi PRIMA dell'aggiunta, e rieseguiti dopo. Due formati separati avrebbero raddoppiato la macchina della persistenza — appendice confermata, istantanee, troncamento atomico, ripresa — per non condividere nulla.

Conseguenze. Una partita di battaglia in corso non si accorge dell'esistenza della campagna. Un giornale dichiara la propria natura dalla prima riga, e la Sessione competente la legge. Ogni caso nuovo che verrà entra nei campioni committati nella stessa modifica che lo introduce, come la prova impone.

### RDA-67 — Le voci di registro prive di luogo non sono attivabili e lo dichiarano

Problema. 02 §6.6 vuole che ogni voce del registro consenta, attivandola, di portare il fuoco sul luogo del fatto. Alcuni fatti non hanno luogo: il cambio di stagione, l'apertura della giornata.

Opzioni. Dare comunque un luogo convenzionale, per esempio il quartier generale; rendere la voce non attivabile.

Scelta. La voce non è attivabile, ha il tratto di testo statico e dichiara nel proprio suggerimento che non riguarda un luogo della mappa.

Motivazione. Un salto che porta in un posto che non c'entra è peggio della sua assenza, e violerebbe 02 §4.4.3, secondo cui il gioco non dichiara mai il falso. Il silenzio, invece, non è distinguibile da un difetto (00 §9.1): per questo la ragione si annuncia.

Conseguenze. In questa unità tutte le voci sono di calendario e nessuna è attivabile, perché i fatti con un luogo — mosse avversarie, rifornimento interrotto, imboscata scattata, marcia lunga compiuta — appartengono tutti a unità successive. Il salto è realizzato e provato, ma nessun fatto di questa unità lo esercita: è dichiarato nel resoconto e nell'elenco delle verifiche su dispositivo.

### RDA-68 — Il fuoco all'apertura della mappa va al primo gruppo che attende una decisione

Problema. 02 §2.9 fissa il fuoco d'apertura della battaglia sull'intestazione del deck. La mappa non ha deck, e il punto non ha equivalente scritto.

Opzioni. La prima casella della mappa; il proprio quartier generale; il primo gruppo che non ha ancora agito.

Scelta. Il primo gruppo in attesa, nell'ordine di lettura.

Motivazione. È il luogo da cui la giornata comincia, ed è coerente con lo spirito di 02 §2.9, che posa il fuoco dove l'azione comincia e non dove la griglia comincia. Le altre due scelte avrebbero costretto a un viaggio prima di poter fare qualunque cosa.

Conseguenze. Ad apertura di una giornata già interamente ordinata — caso possibile riprendendo una campagna — non esiste alcun gruppo in attesa e il fuoco resta all'inizio della schermata. Il tocco magico dice in ogni caso a che punto è la giornata.

### RDA-69 — La sonda degli invarianti vive fuori dal Motore e riceve dall'esterno ciò che giudica

Problema. Gli invarianti della campagna vanno sorvegliati, e la tentazione naturale è metterli dentro il Motore, dove i dati sono a portata di mano.

Scelta. La sonda vive nella libreria di verifica e riceve dall'esterno lo stato, la transizione, la sequenza del salto e la funzione di adiacenza.

Motivazione. Due ragioni distinte. La prima è che il Motore non deve controllare se stesso: un invariante scritto nello stesso momento e nello stesso file della regola ne eredita i punti ciechi. La seconda, e più importante, è che un invariante deve poter essere VIOLATO da una prova: ricevendo dall'esterno ciò che giudica, la sonda si può mettere davanti a uno stato guastato a mano o a un'adiacenza mutilata, e si accerta che se ne accorga. Un invariante che non si è mai visto violare non è un invariante.

Conseguenze. Ogni invariante della campagna ha in collaudo la propria coppia: la corsa vera che non produce violazioni e il mutante che ne produce una. Il costo è qualche parametro in più nelle firme, che è precisamente ciò che rende le prove possibili.

### RDA-70 — L'annullamento riapre la giornata finché non c'è nulla di giocato da disfare (00 §13.8)

**SUPERATA da RDA-73 (decisione del titolare).** La deroga qui concessa — annullamento illimitato all'indietro fino al principio della campagna — è stata rimossa: il confine di 05 §6.5 vale adesso e non quando l'avversario comparirà. Resta valida di questa voce la parte che riguarda l'ordine che chiude la giornata, che continua ad annullarsi. Storia in S9.

Problema. La giornata si chiude quando l'ultimo gruppo riceve il proprio ordine (01 §5.6.0.6). Con la prima realizzazione, quell'ordine era l'unico della giornata che non si potesse ritirare: l'annullamento veniva rifiutato e il giorno restava avanzato. 05 §6.5 elenca infatti «chiusura della giornata di campagna» fra i punti di conferma oltre i quali l'annullamento non retrocede.

Opzioni. Conservare il punto di conferma alla lettera; consentire la riapertura della giornata finché nulla è stato giocato dopo la chiusura.

Scelta. La seconda. L'annullamento ritira l'ultimo ordine impartito quale che sia ciò che gli è seguito, e se la chiusura della giornata è fra quelle cose la giornata si riapre. Lo stesso vale per l'azzeramento, che riapre e svuota la giornata annullabile, cioè la più recente che contenga almeno un ordine.

Motivazione. Tre ragioni, in ordine di forza. La prima è 00 §13.8, che prevale su 05: ogni budget che si consuma richiede l'annullamento dell'ultima operazione, «senza annullamento il giocatore paga un errore di manovra come se fosse stata una scelta tattica», e la giornata è un budget che si consuma. La seconda è che l'ordine più esposto all'errore è proprio l'ultimo, perché il giocatore lo impartisce per muovere un gruppo e ne ottiene per soprammercato un passaggio di giornata che non ha chiesto: un gesto compiuto per fare una cosa ne produceva un'altra, irreversibile e priva di segnale proprio, che per chi ascolta è la combinazione peggiore possibile. La terza è che la ragione per cui 05 §6.5 fa della chiusura un punto di conferma è ciò che la SEGUE — le mosse avversarie e le risoluzioni di fine giornata, come 05 §6.4 dice esplicitamente («finché l'avversario non ha agito») — e in questa unità non esiste né l'una né l'altra cosa: la chiusura incrementa un contatore e riazzera le azioni, e non c'è nulla di giocato che l'annullamento debba disfare.

Conseguenze. Annullando a ritroso si torna indietro di più giornate, un ordine per volta, fino al principio della campagna, ed è provato. Quando lo stratega avversario e le risoluzioni di fine giornata esisteranno, il punto di conferma dovrà tornare a mordere come 05 §6.5 prescrive: il posto dove imporlo è `SessioneCampagna.annulla`, dove la ragione è scritta per esteso. La riapertura si annuncia con una frase propria, distinta da quella dell'annullamento ordinario, perché il calendario tornato indietro è un fatto diverso dal ritiro di un ordine e chi ascolta deve poterli distinguere (00 §11.4).

### RDA-71 — I numeri del resoconto si prendono da un blocco che il programma stampa

Problema. Nel resoconto della prima unità tre numeri non reggevano un controllo aritmetico, e uno di essi contraddiceva la conclusione che gli era stata fatta dire. Nessuno dei tre veniva da un calcolo del programma: erano somme fatte a mente, un conteggio ricordato e una grandezza chiamata con il nome di un'altra.

Opzioni. Ricontrollare a mano con più attenzione; far calcolare al programma tutto ciò che il resoconto cita.

Scelta. La seconda. Il programma di verifica produce una sezione `campagna_riepilogo` che contiene ogni numero destinato al resoconto — totali compresi, sommati dal programma — e una prova pareggia quei totali con le righe di dettaglio, così che il riepilogo non possa discostarsene. Un numero che compaia nel resoconto e non in quella sezione va dichiarato come calcolato a mano nel punto stesso in cui è scritto.

Motivazione. È la stessa ragione per cui esiste il controllo preventivo sul caricamento: una regola si può dimenticare, uno strumento che stampa no. L'attenzione non è una difesa, perché è precisamente ciò che era già stato applicato e che aveva prodotto tre numeri sbagliati su tre.

Conseguenze. Le grandezze omonime ma diverse hanno ora colonne distinte e nomi che non si possono scambiare: `caselle_di_bordo` e `caselle_interne` sono geometria e non dipendono dai gruppi, `con_meno_di_quattro_uscite` e `di_cui_interne` dipendono da dove i gruppi stanno. Il conteggio degli invarianti sorvegliati è anch'esso stampato dal programma, e una prova pretende che ciascuno abbia il proprio mutante.

### RDA-72 — Il registro annota gli ordini del giocatore finché non esistono altri fatti (01 §5.17, §5.17.1)

Problema. 01 §5.17.1 esclude dal registro gli ordini del giocatore. Nel perimetro della prima unità di campagna non esiste alcun fatto non deciso dal giocatore: mosse avversarie, rifornimento, imboscate, marce lunghe e stagioni appartengono tutte a unità successive. Applicata alla lettera, la regola produce un registro vuoto, e la prima unità lo aveva riempito con l'unica cosa rimasta, l'apertura della giornata.

Opzioni. Lasciare il registro con le sole voci di calendario; lasciarlo vuoto e dichiararlo; annotarvi gli ordini impartiti e i loro annullamenti.

Scelta. La terza, per decisione del titolare. Vi entrano marcia e presidio con il gruppo e le caselle, e gli annullamenti.

Motivazione. Il criterio di accettazione è la ragione che 01 §5.17 dichiara: senza il registro ogni annuncio che passa mentre il giocatore fa altro è perduto, mentre chi guarda ha il riquadro davanti. Un registro di sole voci di calendario non recupera nulla, e per di più il salto al luogo del fatto — che 02 §6.6 prescrive — non è mai esercitabile, perché una data non ha luogo. Un registro vuoto sarebbe onesto ma lascerebbe la funzione non provata fino all'unità che porterà i fatti avversari. Gli ordini sono ciò che nel perimetro avviene, e l'annullamento in particolare è un fatto che il giocatore può volere ricostruire, essendo diventato frequente.

Conseguenze. La deroga è dichiarata e limitata: quando i fatti non decisi dal giocatore esisteranno, 01 §5.17.1 va confermato — togliendo allora gli ordini — oppure modificato con una versione nuova del documento. Registrata come scostamento S8. Gli annullamenti non possono vivere nel solo stato, che si ricostruisce riapplicando i comandi: hanno una voce propria nel giornale (RDA-73).

### RDA-73 — Il confine dell'annullamento sta nel giornale, non nello stato (00 §13.8, 05 §6.5)

Problema. Ripristinare il punto di conferma di 05 §6.5 alla chiusura della giornata senza rendere di nuovo irreversibile l'ordine impartito all'ultimo gruppo, che 00 §13.8 vuole annullabile. Le due cose sembrano incompatibili, perché quell'ordine appartiene alla giornata che si è chiusa.

Opzioni. Rifiutare l'annullamento appena la giornata si chiude, cioè la build 11; consentirlo sempre, cioè RDA-70; consentirlo finché la giornata nuova è intatta.

Scelta. La terza. Un ordine è annullabile quando segue l'ultima apertura di giornata; l'ordine che la precede — quello la cui conferma ha chiuso la giornata prima — è annullabile finché nella giornata nuova non è accaduto nulla, né un ordine né un annullamento. Oltre quel punto il rifiuto è dichiarato con il termine chiuso `campagna.non_si_torna_oltre_la_giornata`. L'azzeramento segue la stessa regola.

Motivazione. È la sola lettura sotto la quale entrambe le prescrizioni valgono: l'annullamento ritira sempre l'ULTIMO GESTO del giocatore, quale che sia la giornata cui l'ordine appartiene, e si ferma appena quel gesto non è più l'ultimo. È anche la sola sotto la quale il rifiuto al confine sia una situazione raggiungibile e quindi provabile: con la lettura puramente «giornata corrente» si tornerebbe indietro una giornata alla volta senza fine, che è esattamente il comportamento da rimuovere.

Dove vive il confine, e perché lì. Nel GIORNALE, come voce `annullamentoCampagna(giorno:azzeramento:)`, e non nello stato. Lo stato si ricostruisce riapplicando i comandi: dopo un annullamento sarebbe byte per byte indistinguibile da una giornata appena aperta, e il confine sparirebbe alla prima ripresa della campagna — cioè al riavvio dell'applicazione, che è il momento in cui i difetti di questa specie si manifestano. La stessa voce serve al registro, perché l'annullamento è un fatto avvenuto (RDA-72): una riga sola per due esigenze che vogliono entrambe sopravvivere alla ricostruzione.

Conseguenze. L'annullamento non riporta più lo stato ESATTAMENTE com'era: la partita sì — posizioni, azioni spese, giorno — ma il registro cresce di una voce, e l'impronta cambia di conseguenza. Le prove confrontano perciò la partita e non l'impronta, e verificano a parte che il registro sia cresciuto. Il giornale rigiocato dà lo stesso stato, registro compreso, anche cancellando le istantanee. Sostituisce RDA-70, la cui deroga è tolta; la vicenda è in S9.

### RDA-74 — Ciò che una casella dichiara sta in un elenco solo (02 §3.8.1, 00 §1.2)

Problema. Le caratteristiche di una casella erano enumerate in tre punti indipendenti della Presentazione: quello che le annunciava, quello che decideva se dire «libera», e quello che disegnava i segni per chi guarda. Nulla obbligava a tenerli allineati.

Opzioni. Lasciarli separati con la disciplina di aggiornarli insieme; ricavarli tutti da un elenco unico.

Scelta. Un elenco unico, `VistaCampagna.vociDiCasella(_:)`, che restituisce ciò che la casella dichiara nell'ordine registrato da 02 §3.8.1. La frase e il segno si ottengono attraversando quell'elenco con due enumerazioni esaustive.

Motivazione. Una caratteristica aggiunta all'annuncio e dimenticata nel disegno — o viceversa — sarebbe una divergenza fra il piano sonoro e quello visivo, cioè la classe di difetto che 00 §1.2 vieta e che questa sessione ha dovuto correggere nel registro. Con un elenco solo la divergenza non è impedita dalla disciplina ma dal compilatore: chi aggiunge un caso all'enumerativo è obbligato a dargli sia una frase sia un segno. L'elenco vive nelle interrogazioni del Motore e non nella Presentazione, perché è un dato di gioco e la Presentazione non ne calcola alcuno (00 §3.2).

Conseguenze. L'elenco è il punto in cui entreranno lo stato di conoscenza, le anomalie dell'occupante e le note di zona quando esisteranno, e vi entreranno una volta sola. Le frasi del registro hanno subito la stessa riduzione: le componeva sia il traduttore dei Segnali sia il costruttore degli annunci, e ora le compone il solo traduttore.

### RDA-75 — Il costo in giorni dello scatto viaggia dentro il comando di marcia (01 §5.6.3.1)

Problema. Dare esistenza al costo in giorni dello spostamento senza realizzare la marcia lunga, e impedire che il caso particolare oggi realizzato — un giorno per casella — si consolidi come regola.

Opzioni. Lasciare il costo implicito e introdurlo con la marcia lunga; calcolarlo al bisogno dal Motore; farlo trasportare dal comando.

Scelta. Il valore vive nei dati (`marcia-campagna.json`, `costo_giorni_base`, oggi uno), il Motore lo espone con la firma definitiva `costoInGiorni(da:a:stato:)`, e il comando `.marcia(gruppo:a:giorni:)` lo trasporta. La validazione rifiuta un comando che dichiari un costo diverso da quello prescritto, con il proprio motivo del vocabolario chiuso.

Motivazione. Il giornale è anche il formato di salvataggio: una campagna ripresa deve ripercorrere gli scatti che è costata, non quelli che costerebbero con i dati di oggi. Il costo dentro il comando lo garantisce, e la validazione impedisce che un giornale estraneo introduca un costo arbitrario. La firma è già quella definitiva perché il punto in cui il costo si calcola non debba spostarsi quando arriveranno i pesi della casella di partenza e di arrivo, il volume della colonna, la strada e la strettoia: 01 §5.6.3.2 vuole che agiscano tutti sulla MEDESIMA grandezza, senza regole che si sommino in modo opaco, e quella grandezza ora esiste.

Conseguenze. `FondazioneCampagna.schemaCorrente` sale da 1 a 2 e i giornali di campagna precedenti si dichiarano e non si aprono (00 §15.2); il campione committato del comando di marcia è stato riscritto nella stessa modifica. Con il valore pari a uno il comportamento osservabile non cambia in alcun punto. Il valore è iscritto fra quelli provvisori con il contrassegno di provvisorietà.

### RDA-76 — Annullamento e revoca sono due cose diverse e non si confondono (00 §13.8, 01 §5.6.3.3)

Problema. Con le marce di più giorni compariranno due operazioni che a parole si somigliano e che nel gioco non hanno nulla in comune. Registrare adesso la distinzione impedisce che la prima si allarghi fino a coprire la seconda.

La distinzione. L'ANNULLAMENTO corregge un errore di comando: è gratuito, non è una mossa di gioco, non lascia conseguenze, e vale entro il confine della giornata in corso secondo RDA-73. La REVOCA dell'ordine di marcia è una mossa di gioco: 01 §5.6.3.3 stabilisce che «l'ordine di marcia si può revocare in qualunque momento, perdendo tutti i giorni già spesi», e 01 §5.6.8.1 la elenca fra le operazioni che NON sono azioni e non consumano la giornata. Si paga con la perdita dei giorni, non con l'azione.

Conseguenze. La revoca non si realizza in questa sessione. Quando si realizzerà, non passerà dal comando di annullamento né dal giornale come troncamento: sarà un comando proprio, che si aggiunge alla sequenza invece di toglierne, perché la perdita dei giorni è un fatto di partita e non un ripensamento. La conseguenza va dichiarata prima della conferma, come 01 §5.6.3.5 prescrive.

### RDA-77 — Il termine dell'ordine di restare fermi è «presidio», ed è già nei documenti (01 §5.6.8.1)

Problema. L'incarico della seconda unità segnalava che «presidiare» non figurasse nei documenti e portasse con sé un significato che il progetto non gli attribuisce, chiedendo di ricondurlo al vocabolario chiuso.

Accertamento. La premessa non regge: 01 §5.6.8.1, che chiude nella fase di architettura l'elenco delle sedici azioni di giornata, elenca testualmente «presidio, cioè restare fermi in guardia (5.6.0.6)». Il termine è quindi documentato, ed è il nome dell'azione. Le altre cose che 01 §5.6.0.6 nomina come ragioni per restare fermi — raccogliere risorse, riordinarsi, riposare — sono nello stesso elenco AZIONI DISTINTE: sosta con raccolta automatica (5.6.5), riordino degli assetti (4.8), riposo (5.6.4.4). Il presidio non le assorbe e non pretende di farlo.

Scelta. Si conserva «presidio», con la glossa dei documenti. Il termine non appartiene al vocabolario chiuso di 02 §4.4.5, che elenca STATI e non azioni: lo stato di un gruppo che ha presidiato è «ha agito», come dopo qualunque altra azione. L'invariabilità di 02 §4.1 è comunque rispettata: tutte le occorrenze nei testi usano la stessa radice — `pannello.presidio`, `campagna.presidio_ordinato`, `registro.presidio_ordinato` — e nessun sinonimo compare in alcun punto.

Conseguenze. Nessuna modifica ai testi. Se una revisione futura vorrà elencare anche i nomi delle AZIONI in 02 §4.4.5, il posto è quello e la voce esiste già altrove; oggi il documento 02 non li elenca, e aggiungerveli sarebbe una modifica al documento e non una correzione.

## Parte undicesima — Decisioni della sessione degli strumenti e dei cancelli

### RDA-78 — Il tocco diretto attiva per la stessa porta dell'attivazione assistiva (02 §2.11, 00 §7.2)

Problema. Le caselle delle due griglie erano elementi accessibili sintetici dentro una vista priva di riconoscitori di gesto: rispondevano soltanto ad `accessibilityActivate`. Con VoiceOver spento nessuna delle due griglie era operabile, e nessuna prova d'interfaccia poteva esercitare il gioco, perché una prova d'interfaccia tocca a dito. L'osservazione stava come scostamento P11 dal 2026-08-04 con il rimedio già indicato e mai realizzato.

Opzioni. Un riconoscitore per ciascuna vista che risolva il punto e chiami `attiva(_:)` sulla schermata, come P11 proponeva; oppure un riconoscitore in una base condivisa che risolva il punto nell'ELEMENTO e ne invochi `accessibilityActivate()`.

Scelta. La seconda, in `VistaACaselle`, da cui `VistaGriglia` e `VistaMappa` ereditano. Il tocco non chiama una seconda realizzazione dell'attivazione: chiama esattamente il metodo che la tecnologia assistiva invoca.

Motivazione. La prima opzione lascia due rami da tenere allineati, ed è la forma di difetto che questo progetto produce con maggiore regolarità: una regola scritta («i due percorsi devono fare la stessa cosa») anziché uno stato reso impossibile. Con la seconda non esiste un secondo ramo. La base è condivisa fra i due piani per la stessa ragione: P11 avvertiva che correggerne uno solo sarebbe stata la disparità che il principio 7 vieta, e con una realizzazione sola la divergenza non è scrivibile.

Delimitazione, che è il punto per cui questa voce esiste. NON è l'esplorazione libera a tocco diretto di 02 §2.12, esclusa dalla prima versione: quella riceve i tocchi grezzi per ANNUNCIARE ciò che il dito attraversa mentre scorre, ed è una modalità di lettura. Qui il tocco ATTIVA, come su qualunque controllo del sistema, e `TesseraDeck` lo faceva già dalla fase B nel verso opposto (l'attivazione assistiva vi chiama `sendActions(for: .touchUpInside)`). Chi trovasse 02 §2.12 citato contro questa correzione legga qui: sono due cose diverse, e 02 §2.11 chiede espressamente la simmetria che questa realizza.

Conseguenze. Con VoiceOver in funzione il riconoscitore non entra mai in azione, perché il tocco singolo è consumato dalla tecnologia assistiva: le due porte non si sovrappongono e nessuna attivazione si conta due volte. Le prove d'interfaccia possono ora esercitare il gioco, che è la condizione dell'impianto sul simulatore. `ToccoDirettoTest` copre entrambi i piani con lo stesso corpo, compreso il caso della casella vuota e del margine, e `test_00_1_2_ogni_casella_e_risolvibile_dal_punto_del_proprio_centro` pretende che ogni elemento dichiarato sia raggiungibile dal dito nel proprio centro, sicché un elemento futuro raggiungibile da una porta sola fallisce senza che nessuno debba ricordarsi di scrivergli la prova.

### RDA-79 — La copertura del formato di salvataggio è imposta da una catena che non compila (00 §15)

Problema. `CompatibilitaGiornaleTest` confrontava i casi trovati nei campioni committati con un insieme di nomi scritto a mano. Un caso aggiunto a `VoceGiornale`, a `ComandoBattaglia` o a `ComandoCampagna` senza il proprio campione non compariva né nei campioni né nel letterale: i due insiemi restavano uguali e la prova PASSAVA. La protezione che `stato-avanzamento.md` le attribuiva non esisteva per nessuno dei tre tipi. L'esame critico l'aveva rilevata per `VoceGiornale` e attribuita a torto agli altri due: l'esaustività di `etichettaCaso` obbligava a NOMINARE il caso nuovo, non a dargli un campione.

Opzioni. Un elenco statico di casi di riferimento come quello di `FattoRegistrato`, che resta una lista scritta a mano; oppure uno specchio `CaseIterable` legato al tipo vero da due funzioni totali.

Scelta. Lo specchio. Per ciascuno dei tre tipi esiste un enumerativo senza valori associati, `specie(di:)` che va dal tipo vero allo specchio, ed `esemplare(di:)` che va dallo specchio al tipo vero costruendo un valore.

Motivazione. Swift non sa enumerare un enumerativo con valori associati, quindi una lista scritta a mano c'è comunque: la questione è se sia possibile lasciarla incompleta. Con lo specchio non lo è. Aggiungere un caso al tipo vero non compila `specie(di:)`; aggiungerlo allo specchio per far compilare quella non compila `esemplare(di:)`, che obbliga a costruire il valore; e a quel punto la prova pretende che la chiave codificata di quel valore compaia nei campioni. Due dei tre anelli sono errori di compilazione.

Conseguenze. La catena è stata percorsa a rovescio per verificarla, aggiungendo un caso finto a `VoceGiornale`: primo anello, `specie(di:)` non compila; secondo, `esemplare(di:)` non compila; terzo, la prova fallisce dichiarando il caso privo di campione. Serviva adesso e non alla prossima unità perché RDA-76 e `impatto-marcia-lunga.md` §7 stabiliscono che la revoca della marcia introdurrà un caso nuovo proprio in `VoceGiornale`.

### RDA-80 — La nota per il titolare sta dietro un cancello, non dietro una prescrizione

Problema. `nota-per-il-titolare-mappa.md` è il documento su cui il titolare si forma il giudizio sul lavoro, ed è l'unico che nessuno rilegge: due commit su trentanove, e quattro affermazioni false su quattro alla verifica dell'esame critico. `note-di-rilascio.txt` ha lo stesso destinatario, quattordici commit su trentanove ed è coerente, per una ragione sola: `carica-testflight.sh` rifiuta il caricamento se manca o se supera il limite.

Opzioni. Una prescrizione in `forma-dei-resoconti.md`; oppure un controllo che rifiuti il caricamento.

Scelta. Il controllo, invocato da `carica-testflight.sh` prima di qualunque compilazione e, nella sola parte che non chiede il programma di verifica, dall'integrazione continua. **Dal 2026-08-05 lo script si chiama `scripts/controlla-note.py` e vale per due documenti**: vedi RDA-81.

Motivazione. La prescrizione è la forma che in questo progetto viene disattesa; il rifiuto è la forma che non lo è mai stata. Non è un'opinione: è il confronto fra i due documenti destinati allo stesso lettore.

Delimitazione, dichiarata perché non sia mai scambiata per copertura piena. Il controllo giudica quattro cose: che la nota esista e non sia vuota; che ogni nome citato fra virgolette basse sia il valore di una chiave dei cataloghi di testo o un gesto il cui metodo esiste nei sorgenti; che ogni numero del corpo provenga da una misura dichiarata e pari a ciò che il programma di verifica stampa oggi; e che la nota non sia più vecchia dell'ultimo commit che ha toccato il codice. NON giudica le affermazioni di COMPORTAMENTO in prosa, che non sono riducibili a un nome né a un numero. Su quelle agisce soltanto il controllo di freschezza, che obbliga a rileggerle a ogni modifica del codice: ed è il controllo che avrebbe impedito tutte e quattro le affermazioni false, perché nessuna era un errore di misura e tutte erano affermazioni divenute false sotto una nota che nessuno rileggeva.

### RDA-81 — I documenti consegnati stanno in una tabella che dichiara chi è protetto da che cosa

Problema. Tre volte lo stesso errore, e la terza è la prova che la forma della protezione contava più del suo contenuto. `nota-per-il-titolare-mappa.md` aveva quattro affermazioni false su quattro; è stata messa dietro un controllo. `note-di-rilascio.txt`, stesso destinatario, è partita con la build 14 descrivendo la build precedente — perché il controllo che la proteggeva ne verificava la LUNGHEZZA e non l'ATTUALITÀ. Le due protezioni vivevano in due posti diversi (una dentro `carica-testflight.sh`, l'altra in uno script a sé) e la differenza non era leggibile da nessuna parte.

Opzioni. Applicare tutti i controlli a tutti i documenti; oppure duplicare il controllo di freschezza nel secondo posto; oppure una tabella che dichiari, documento per documento, l'insieme dei controlli cui è soggetto.

Scelta. La tabella, in `scripts/controlla-note.py`. Una sola realizzazione per ciascun controllo; `DOCUMENTI` elenca `note-di-rilascio.txt` con esistenza, lunghezza e freschezza, e `nota-per-il-titolare-*.md` con esistenza, vocabolario, misure, cifre e freschezza.

Motivazione. Applicare tutto a tutti sarebbe stato falso: il controllo del vocabolario pretende la convenzione delle virgolette basse, che la nota per i tester non usa, e sarebbe stato vacuo o costretto. Duplicare la freschezza avrebbe rimesso in piedi la condizione da cui il difetto è nato, cioè due protezioni in due posti. La tabella non aggiunge un controllo: rende LEGGIBILE quale documento è protetto da che cosa, sicché un artefatto consegnato senza riga si veda a colpo d'occhio.

Conseguenze. Il controllo di freschezza sulla nota per i tester è stato visto rifiutare sul caso vero, non su uno costruito: al momento in cui è stato installato, `note-di-rilascio.txt` era al commit `2d3c546` e il codice a `f3c8288`, e lo script si è fermato con uscita 1. Verificato inoltre che avrebbe impedito l'episodio della build 14: allora la nota era a `61a90e6` (09:47) e il codice a `6b0caf8` (13:47).

### RDA-82 — Il registro delle build e il confronto con App Store Connect

Problema. La build 13 esisteva sui server di Apple e nessun documento del progetto la registrava; `esame-critico.md` §4.1 e un resoconto dicevano entrambi che l'ultima fosse la 12. È l'unica catena del progetto che nessun controllo interno poteva verificare, perché l'altro capo non sta nel repository.

Opzioni. Affidare la registrazione alla disciplina di chi carica, come fino a ieri; oppure un registro scritto dallo script con un controllo che lo confronti con i server.

Scelta. `build-caricate.md`, scritto da `scripts/carica-testflight.sh` a caricamento riuscito, e `scripts/controlla-build.py`, che confronta il registro con App Store Connect e rifiuta il caricamento successivo se divergono in un verso o nell'altro.

Motivazione. Il passo che è mancato è precisamente quello umano: la sessione che caricò la 13 fece tutto il resto e non scrisse la riga. Uno strumento che la scrive da sé toglie il passo; un controllo che rifiuta al caricamento successivo prende anche i caricamenti fatti altrove.

## Parte dodicesima — Decisioni della sessione del caricamento e delle tre questioni

### RDA-83 — Le sessioni complete per l'interfaccia stanno in una corsa separata, dietro un cancello di freschezza (05 §12.4, S11)

Problema. La sessione delle sessioni per l'interfaccia (RDA in S11) aveva aggiunto le 144 sessioni di campagna giocate al dito al collaudo di ogni caricamento, sulla base di una stima di sette minuti. La misura le dà a **1258,6 s** — venti minuti e cinquanta — e con le sessioni di battaglia per l'interfaccia salirebbe all'ordine delle dodici ore (130 322 comandi a 0,3362 s, S11): la stima era sbagliata di più del triplo. Un collaudo che costa venti minuti a ogni caricamento non viene eseguito, e un cancello che non si esegue non protegge.

Opzioni. Tenerle nel collaudo di ogni caricamento accettando i venti minuti; toglierle e basta, perdendo la protezione; toglierle dal collaudo di ogni caricamento e spostarle in una corsa separata che lasci un esito che il caricamento esige fresco.

Scelta. La terza, per decisione del titolare informato del numero vero. Il collaudo di ogni caricamento tiene il **sottoinsieme di 24 sessioni** (1–2 gruppi), già misurato a 34,4 s: `SessioniPerInterfacciaTest.test_00_3_1` gioca il sottoinsieme (tetto gruppi 2), `test_00_3_9` gioca le 144 (tetto 12). La separazione è per SELEZIONE della prova, non per variabile d'ambiente: `collaudo-completo.sh` esclude `test_00_3_9` con `-skip-testing`, la corsa separata la include con `-only-testing`. Una prima stesura leggeva `WARSENSE_SESSIONI_COMPLETE`, ma xcodebuild non propaga l'ambiente della shell al processo di prova sul simulatore, e la corsa girava le 24 credendo di girarne 144 (accertato: la corsa durava un minuto invece di venti); la selezione per nome non ha quel difetto. La corsa separata è `scripts/esegui-sessioni-complete.sh`, esegue le 144 per l'interfaccia e l'insieme headless completo con le 32 di battaglia al Motore, non dipende da alcuna credenziale, e scrive `esiti-sessioni-complete/esito.json` con data, commit ed esito. Il cancello `scripts/controlla-sessioni.py`, invocato da `carica-testflight.sh`, rifiuta il caricamento se l'esito manca, dichiara un fallimento, o è più vecchio dell'ultimo commit che ha toccato il codice.

Motivazione. È la forma che questo progetto impone: un requisito nuovo si introduce con qualcosa che rifiuta, non con una prescrizione. Lo spostamento senza il cancello sarebbe stato una perdita di protezione — le sessioni complete girerebbero quando qualcuno se ne ricorda. Il cancello è la freschezza già realizzata per le note (RDA-80/81) applicata a un artefatto diverso, e supera la stessa domanda: rifiuterebbe un esito **vero ma vecchio**? Sì — visto rifiutare su un esito di successo girato su `9574a25` dopo che il codice era andato a `2125032`, oltre che sull'esito mancante e su quello che dichiara fallimento; visto accettare sull'esito fresco. Le sessioni di battaglia entrano nella corsa al livello a cui passano, il Motore, perché per l'interfaccia il costo è proibitivo (S11 resta aperto sull'interfaccia).

Conseguenze. Il collaudo di ogni caricamento torna dai 30,5 s + 1363,7 s (pacchetto + simulatore) con le 144, a **29,5 s + 163,18 s** con le 24, vicino ai 30 s + 122 s di prima dell'aggiunta. Chi carica deve prima eseguire la corsa separata sul codice attuale, o il cancello rifiuta. `esiti-sessioni-complete/` non è versionato: un clone fresco non ha esito e il cancello rifiuta, che è il comportamento voluto. La decisione del titolare sostituisce quella precedente (le sessioni complete nel collaudo di ogni caricamento) e non va riaperta.

### RDA-84 — Il manifest dei testi è confrontato, e la discordanza è un rifiuto non una versione derivata (05 §7.2)

Problema. `Testi.carica` leggeva il campo `impronte` del manifest e non lo confrontava con nulla: era l'unico artefatto di contenuto senza controllo, mentre `CaricatoreValori` confronta le proprie impronte dalla fase dei dati (RDA-54, RDA-45). Nessuna prova verificava il manifest dei testi.

Opzioni. Modellare i testi esattamente sui valori — discordanza che deriva una versione locale e non rifiuta (RDA-45); oppure confrontare e RIFIUTARE la copia divergente, lasciando che chi carica ripieghi sulla fabbrica.

Scelta. Il rifiuto. `Testi.carica` calcola l'impronta SHA-256 di ogni file elencato e lancia `ErroreDati(errore.testi.impronta_discorde)` se non coincide, o `errore.testi.file_mancante` se il file elencato manca. `Servizi` cattura il rifiuto e ripiega sulla fabbrica, sempre coerente (05 §7.1), sicché nessuna schermata resta senza testi.

Motivazione. I valori ammettono la modifica locale come uso legittimo (una campagna con dati alterati vale, con la versione derivata a dichiararlo): per i testi non esiste un uso legittimo della copia in Documenti che diverga dal proprio manifest — la copia si rinfresca dalla fabbrica quando i byte del manifest cambiano, quindi una divergenza è una corruzione, non una scelta. Il rifiuto con ripiego è la risposta corretta a una corruzione; la versione derivata mostrerebbe testi corrotti dichiarandoli «modificati localmente», che per i testi non ha senso. Il rifiuto è dichiarato (una chiave del vocabolario) e non muto, e non distrugge la schermata perché il ripiego esiste già.

Conseguenze. Prove in `CaricamentoTest` modellate su quelle dei valori: `test_05_7_2_testi_di_fabbrica_coincidono_con_le_impronte` è la prova che fallisce se un file di testo è alterato senza rigenerare il manifest — vista fallire di proposito con `errore.testi.impronta_discorde` su `Vocabolario.strings`, poi ripristinato. Il controllo non è vacuo: le prove leggono manifest e file committati e non rieseguono `rigenera-impronte.py`. Chi modifica un file di testo deve rieseguire `rigenera-impronte.py` nella stessa modifica, o `Testi.carica` rifiuta la fabbrica — ed è precisamente ciò che rende il manifest dei testi protetto quanto quello dei valori.

Conseguenze. Gira soltanto al caricamento, perché chiede le credenziali di App Store Connect, che non esistono nell'integrazione continua né devono esistervi. Le righe da 1 a 14 sono RICOSTRUITE dall'istante di caricamento contro la cronologia, e il registro lo dichiara riga per riga; quella della 13 è inoltre accertata per confronto del campo `whatsNew`.

## Parte tredicesima — Decisioni della sessione del deck a riquadri e della griglia in orizzontale

### RDA-85 — La forma delle tessere del deck: riquadro compatto, non riga di testo (02 §8.1, §8.2; modifica di RDA-50)

**Modifica una decisione presa, per volontà del titolare, e NON corregge una svista.** RDA-50 aveva scelto tessere con nome ed etichette di testo impilate, alte quanto lo stato più lungo: misurate **130 punti** su iPhone Air. Il titolare, provata la build 15 sul dispositivo, ha giudicato la banda del deck troppo alta — scomoda in verticale, causa del collasso della griglia in orizzontale (S10) — e ha chiesto la forma compatta che la sua indicazione originaria non aveva ottenuto.

Scelta. `TesseraDeck` diventa un riquadro alto **65** punti (circa la metà dei 130) e largo **56** (poco meno dell'altezza), mai sotto il minimo toccabile di 44. Mostra, PER CHI VEDE: la sigla dell'archetipo al centro (segnaposto testuale dei simboli grafici, `valori-provvisori.md`), il nome molto in piccolo, due quadratini negli angoli inferiori con atomi e volume — il modello è il deck di Clash of Clans col numero di atomi al posto del livello. I caratteri decorativi hanno dimensione fissa e NON scalano con la tipografia dinamica: la banda resta compatta a ogni taglia, ed è ciò che restituisce altezza alla griglia.

Vincolo di accessibilità, per cui la forma è ammissibile. La sigla, il nome disegnato e i due quadratini sono DECORAZIONE: esclusi dall'albero accessibile (`isAccessibilityElement = false`); l'elemento accessibile resta uno solo, con etichetta (nome) e valore (annuncio in ordine fisso) INVARIATI — chi ascolta non sente sigle né numeri due volte. Provato da `StabilitaDellaDisposizioneTest.test_02_8_2_l_annuncio_della_tessera_non_cambia_col_ridisegno` e da `RaggiungibilitaTest` (ogni tessera raggiungibile dal centro).

Conseguenze. L'altezza è FISSA: selezionare non fa crescere la tessera (il difetto di S10 non torna; `test_02_8_2_la_tessera_non_cambia_altezza`). La riga non stira più le tessere a riempire la larghezza (la clausola «riempie la larghezza» di RDA-50 è superata): tessere piccole a sinistra, scorrimento laterale quando saranno molte. Le sigle sono testo (`deck.sigla.<archetipo>`) nei file dei testi, italiano e — come segnaposto per il futuro — inglese; manifest rigenerato. Le sigle sono PROVVISORIE (`valori-provvisori.md`): un lavoro successivo le sostituirà con simboli grafici.

### RDA-86 — Il deck non determina più l'altezza della griglia: minimo richiesto e area scorrevole (00 §10.4, principio 1; modifica di RDA-50)

Problema. RDA-50 aveva reso l'altezza della griglia «desiderata a bassa priorità», cedevole alla colonna del deck. La sessione 07 ha misurato la conseguenza: sull'iPhone la porzione visibile della griglia collassa a **ZERO** in orizzontale (a ogni taglia) e a caratteri grandi in verticale, perché la colonna del deck (tessere e comandi, che crescono con la tipografia) ne prende tutta l'altezza. Il titolare l'ha confermato sul dispositivo. Tocca il principio 1.

Opzioni. Un tetto all'altezza del deck; un'area scorrevole propria del deck; la sola riduzione delle tessere (RDA-85).

Scelta. Entrambe le protezioni, perché la sola riduzione delle tessere non basta (i comandi globali scalano con la tipografia e da soli possono superare l'altezza disponibile in orizzontale): (a) la griglia — `scorrimento` in battaglia e in campagna — ha un'altezza MINIMA RICHIESTA (`altezzaMinimaGriglia`/`altezzaMinimaMappa`, 120 punti, sufficiente a una riga intera di celle) oltre alla desiderata a bassa priorità; (b) la colonna del deck (`colonnaDeck`) e la banda dei comandi della mappa (`colonnaComandi`) vivono in una propria area scorrevole verticale (`scorrimentoColonna`/`scorrimentoComandi`): quando lo spazio manca è il deck a scorrere, non la griglia a collassare.

Motivazione. Rende IMPOSSIBILE lo stato sbagliato invece di vietarlo: il minimo è richiesto, non desiderato, quindi il risolutore non può azzerare la griglia; l'area scorrevole assorbe la pressione dei comandi. Vale in campagna quanto in battaglia, perché la mappa ha la stessa struttura e collassava allo stesso modo.

Conseguenze. `PorzioneVisibileTest` (00 §10.4) pretende, per la griglia di battaglia e per la mappa nei tre formati, in verticale e in orizzontale, a taglia predefinita e AXXXL, porzione visibile > 0 e almeno una riga intera di celle. Vista fallire sul codice attuale (battaglia orizzontale e AXXXL, mappe orizzontale AXXXL: porzione 0, zero righe) e passare dopo il rimedio. S10 è chiuso per la parte del collasso.

## Parte quattordicesima — Decisioni delle soglie di disingaggio, del logoramento e del reparto elitario (incarico 10)

Le cinque voci che seguono realizzano decisioni del titolare prese dopo la misura del corpo a corpo (incarico 09, resoconto in `Incarichi/09`). Toccano punti scritti nei consolidati (01 §9.5, §9.8, §9.8.3), che sono fermi a prima della fase D: le modifiche sono perciò registrate anche come scostamenti dichiarati (registro degli scostamenti, S13). I numeri introdotti sono provvisori (`valori-provvisori.md`).

### RDA-87 — Le soglie di disingaggio si ritarano su tre fasce, con l'ordinamento degli archetipi (incide sul gioco; 01 §9.8)

Problema. La misura dell'incarico 09 ha mostrato che le soglie di disingaggio erano tutte troppo basse: la soglia scattava sempre molto prima della distruzione, in 115 accoppiamenti su 162 strettamente prima, e nessuna mischia 1v1 si concludeva con una distruzione salvo gli otto casi della macchina d'assedio. Il difetto non era l'assenza di soglie differenziate — esistevano — ma la loro taratura.

Opzioni. Alzare uniformemente tutte le soglie; assegnare a ciascun archetipo un valore su misura; assegnare tre fasce distinte a priori.

Scelta. Tre fasce distinte, per decisione del titolare, con i valori nei dati (`archetipi.json`, campo `soglia_disingaggio`) e non nel codice. Assegnazione dei nove archetipi, ordinata per crescente tenuta in mischia: **fascia bassa 0,12** (i tre reparti da tiro e distanza — `tiratori`, `piattaforma_trainata`, `macchina_tiro` — che si sfilano quasi subito); **fascia media 0,6** (`fanteria_leggera`, `cavalleria_ricognizione`, `cavalleria_manovrata`, che si sfilano a metà strada); **fascia alta 0,9** (`fanteria_pesante`, `macchina_assedio`, che non si sfilano quasi mai). Il reparto elitario `guardia_elite` non ha soglia (RDA-88). Il criterio dell'ordinamento reciproco: il più mobile o fragile o da distanza si sfila prima, il più pesante e disciplinato regge più a lungo, l'elitario mai.

Motivazione. Le fasce devono essere distinguibili ascoltando e non solo diverse sulla carta (vincolo dell'incarico). La misura `mischia_fasce` del programma di verifica riporta, per ciascuna fascia, dopo quanti scambi la soglia scatta negli accoppiamenti tipici: mediana **1 / 4 / 8** scambi per bassa / media / alta, con divario di almeno due scambi fra fasce adiacenti. Il cancello `MisuraMischiaTest.test_incarico10_le_fasce_di_disingaggio_restano_separate` rifiuta lo stato in cui le mediane si avvicinano a meno di due scambi — visto fallire di proposito appiattendo la fascia media sulla bassa. Con la ritaratura i duelli che finiscono per distruzione salgono da 8 a 16 su 162, e il reparto che si sfila ha perso in mediana il 50 per cento della consistenza invece del 38.

Conseguenze. Tutte le impronte cambiano e i copioni d'oro sono rigenerati (RDA-60, 05 §14.6). La versione dei valori sale a 0.6.0 (RDA-91-bis nel corpo di RDA-91). I valori sono provvisori. La taratura non chiude il carattere degli ufficiali né i valori del danno, che restano dove sono.

### RDA-88 — L'assenza della soglia per il reparto elitario è nil, non un valore estremo (incide sul gioco; 01 §9.8)

Problema. Il reparto più elitario di ciascuna fase storica — nella fase arcaica `guardia_elite` — non si sfila mai, in nessuna condizione e qualunque sia il suo stato. La rappresentazione precedente ammetteva soltanto un valore di soglia nell'intervallo (0, 1]: una soglia molto alta (per esempio 0,99) non è l'assenza della soglia, perché a consistenza quasi nulla scatterebbe comunque, e non è leggibile come «non si sfila mai».

Opzioni. Una soglia estrema (0,99 o 1,0); un interruttore booleano separato accanto alla soglia; la soglia opzionale, assente per l'elitario.

Scelta. La soglia opzionale: `DefinizioneArchetipo.sogliaDisingaggio` diventa `Scalato?`, e la chiave `soglia_disingaggio` è omessa in `archetipi.json` per il solo `guardia_elite`. Assente significa elitario: il ramo di disingaggio in `MotoreBattaglia.risolvi` salta lo sciame la cui soglia è nil, che perciò non si sfila mai da sé.

Motivazione. È la forma che rende lo stato leggibile come tale e non confondibile con una soglia alta (richiesta esplicita dell'incarico). Un interruttore separato sarebbe un secondo luogo della verità da tenere in sincronia con la soglia; la soglia opzionale porta l'informazione in un campo solo. La validazione del caricatore ammette l'assenza e valida il valore quando è presente. Il cancello `DisingaggioElitarioTest.test_incarico10_l_elitario_non_si_sfila_mai_automaticamente` accerta che l'elitario superi una soglia tipica restando ingaggiato e prosegua fino alla distruzione senza sfilarsi — visto fallire di proposito dando all'elitario una soglia.

Conseguenze. Il codice di misura dell'incarico 09 tratta la soglia come opzionale; l'elitario come bersaglio non raggiunge mai la propria soglia (colonna «assente» in `mischia_accoppiamenti` e `mischia_fasce`). L'artificio di misura `ValoriVariati.disingaggioDisattivato` porta a 1,0 anche l'elitario, perché a soglia disattivata ogni corsa prosegua fino alla distruzione.

### RDA-89 — Il disingaggio su ordine è un'eccezione dichiarata, riservata all'elitario, e non contraddice la perdita di controllo (incide sul gioco; 01 §9.5, §9.8)

Problema. La regola generale è che il reparto che ingaggia esce dal comando del giocatore (01 §9.5): è la ragione della riserva, e la sua ragione documentale è che il problema del comando antico non era decidere ma farsi obbedire. Il titolare ha stabilito una eccezione: il reparto elitario è l'unico che possa disingaggiarsi su ordine del giocatore, ed è quindi l'unico sul quale il controllo non si perde del tutto quando ingaggia.

Perché non è una contraddizione, e va scritto perché nessuna revisione futura la tolga credendo di correggere una svista. La regola generale nasce dall'osservazione che le truppe antiche, una volta a contatto, non obbedivano più agli ordini: la perdita di controllo modella questo fatto. La truppa scelta — l'elitario — è precisamente quella che obbedisce anche in mischia: l'eccezione è quindi COERENTE con la ragione della regola, non una deroga ad essa. La riserva resta per tutti gli altri reparti; l'elitario paga il proprio privilegio con il costo di reclutamento e con l'assenza di soglia automatica (RDA-88), che lo espone alla distruzione se il giocatore non interviene.

Scelta. Un comando proprio del Motore, `ComandoBattaglia.disingaggiaSuOrdine(sciame:)`, azione esplicita del giocatore e non evento automatico. La validazione lo ammette SOLO se il reparto è elitario (soglia assente) e a contatto, e se esiste una cella arretrata libera; per ogni altro reparto e per l'elitario non impegnato è respinto, sicché la schermata non lo offre mai (l'azione impossibile non si offre, come per il ritiro). L'applicazione riusa la ritrazione comune al disingaggio automatico (`eseguiRitrazione`): arretra di una cella, termina i contatti, registra la coppia staccata e ne vieta il reingaggio per un turno. L'evento emesso è quello di disingaggio già esistente, quindi l'annuncio scatta senza nuovo lavoro sui Segnali; la voce del pannello ha un termine proprio nei testi (`pannello.disingaggia`), che riusa il concetto di disingaggio e non introduce alcun termine nel vocabolario chiuso.

Conseguenze. Un caso nuovo in `ComandoBattaglia`, con il suo specchio in `CompatibilitaGiornaleTest` e il suo campione nel giornale d'oro (RDA-79). Il tattico non usa il disingaggio su ordine: resta uno strumento del giocatore. Il cancello `DisingaggioElitarioTest.test_incarico10_disingaggio_su_ordine_solo_elitario_a_contatto` e la prova d'interfaccia `PannelloAzioniTest` accertano che l'azione compaia solo per l'elitario a contatto e per nessun altro reparto.

### RDA-90 — Il coefficiente di logoramento abbassa la soglia del reparto già logorato (incide sul gioco; 01 §9.8)

Problema. La soglia si calcola sulla consistenza con cui il reparto è entrato in quel contatto: chi si stacca e riattacca riparte da zero. Il titolare ha stabilito che la soglia acquisti un coefficiente dipendente dallo stato di integrità del reparto: un reparto già logorato cede prima, uno fresco regge più a lungo.

Scelta. Una formula unica nel Motore, `sogliaDisingaggioEffettiva(base:sciame:consistenzaIngresso:)`, con un solo coefficiente nei dati (`combattimento.json`, `coefficiente_logoramento_soglia`, provvisorio 0,5). L'integrità è la consistenza d'INGRESSO nel contatto sulla consistenza piena (atomi iniziali × punti vita per atomo): fissa per la durata del contatto, riflette il logoramento pregresso e non la perdita in corso, già contata dalla proporzione delle perdite. Soglia effettiva = soglia base × (1 − coefficiente × (1 − integrità)). A integrità piena la soglia è quella di base; a integrità ridotta cala. Non si applica all'elitario, che non ha soglia. Nessuna tabella (00 §13.3).

Motivazione. Misurare l'integrità all'ingresso e non nell'istante evita di contare due volte la perdita in corso, che la proporzione già misura; e fa mordere il coefficiente esattamente dove serve, sul reparto che riattacca logorato. Il cancello `DisingaggioElitarioTest.test_incarico10_il_logoramento_abbassa_la_soglia_del_reparto_gia_logorato` accerta che a integrità piena la soglia effettiva è la base e a metà integrità è minore.

Conseguenze. Il coefficiente lavora in parte sulla stessa materia della regola del secondo contatto (RDA-91): impedire la spola indefinita. Il valore è provvisorio.

### RDA-91 — L'esame congiunto con la regola del secondo contatto è misurato, non deciso (01 §9.8.3)

Problema. Il coefficiente di logoramento e la regola del secondo contatto (01 §9.8.3: due reparti già staccati che tornano a contatto non hanno più soglia e combattono fino alla dispersione) lavorano in parte sulla stessa materia. L'incarico chiede di esaminarle insieme e di misurare, non di scegliere fra conservare entrambe, il solo coefficiente, o la sola regola: la scelta è del titolare.

Realizzazione della misura, non decisione. La regola del secondo contatto diventa condizionata da un interruttore nei dati (`combattimento.json`, `soglia_al_secondo_contatto`, booleano, provvisorio FALSO = comportamento distribuito): a falso la coppia già staccata non ha soglia (regola presente); a vero la soglia opera di nuovo, con il coefficiente di logoramento (regola tolta). Il gioco onora l'interruttore, quindi non è un canale di sola misura; ne esce una decisione futura del titolare che consiste nel fissare l'interruttore o rimuoverlo. La build distribuita conserva il comportamento attuale (regola presente).

Che cosa mostrano i numeri (misura `secondo_contatto` del programma di verifica, sulle 32 sessioni complete di battaglia, coefficiente di logoramento attivo). **Oggi** (soglie vecchie, nessun coefficiente, regola presente) la regola era molto esercitata: 136 reingaggi di coppie già staccate su 80 battaglie generate, in 55 battaglie. Con le soglie nuove i reingaggi calano a 101 su 80 battaglie (le soglie alte fanno sfilare meno i pesanti, che è la causa della spola). Sulle 32 sessioni, a coefficiente attivo: **regola presente** 34 reingaggi, 67 disingaggi, 36 distruzioni in mischia, 24 su 32 concluse; **regola tolta** 36 reingaggi, 76 disingaggi, 32 distruzioni in mischia, 24 su 32 concluse. Nessuna delle due produce un comportamento manifestamente rotto: in entrambe un reparto può sempre staccarsi (regola tolta) o combattere fino alla dispersione (regola presente), e le battaglie concludono nella stessa misura. La decisione resta al titolare, con i numeri accanto.

Conseguenze (RDA-91-bis, versione dei valori). La versione dei valori sale da 0.5.0 a **0.6.0**, e le versioni compatibili si riducono a `["0.6.0"]`: le regole della mischia cambiano come una partita in corso si svolgerebbe, quindi un salvataggio 0.4.0/0.5.0, rigiocato con le regole nuove, ripercorrerebbe disingaggi automatici diversi e ricostruirebbe uno stato sbagliato. La valutazione è che tali salvataggi siano incompatibili, e la ripresa li DICHIARA con `ErroreSessione.salvataggioIncompatibile` invece di aprirli su uno stato divergente (00 §15.2). Il cancello `SalvataggioBuildDistribuitaTest.test_00_15_un_salvataggio_di_versione_incompatibile_si_dichiara` accerta il rifiuto dichiarato; i copioni d'oro e il salvataggio della build distribuita sono rigenerati a 0.6.0.

## Parte quindicesima — Decisioni dell'élite storica e delle chiusure del corpo a corpo (incarico 11)

Il cancello d'apertura dell'incarico 11 è stato superato: `guardia_elite` NON è un archetipo di realizzazione ma il terzo degli otto archetipi di 01 §3.2, uno dei nove chiusi in 01 §3.2.3 (RDA-28), creato nel commit `24458a0` insieme a tutti gli altri; nessun archetipo è mai stato aggiunto o rimosso dopo. La sessione è perciò proseguita.

### RDA-92 — Le due élite storiche e la rappresentazione archetipo-fase (incide sul gioco; 01 §3.2.3, §3.3)

Problema. La condizione di soglia assente (incarico 10) era assegnata a un solo archetipo, `guardia_elite`, come reparto «dedicato» a non sfilarsi. Il titolare vuole invece che l'élite di ciascuna fase storica sia il reparto che la ricerca storica indica come superiore per addestramento e disciplina, scelto fra i nove esistenti, e che la condizione vari con la fase.

Scelta, fondata sulla ricerca in cartella (riferimenti verificabili riga per riga). Élite della **fase antica**: `guardia_elite` (guardia d'élite = Immortali persiani e opliti spartani, `Fondamenta/01-progetto-del-gioco.md:117`; `Fondamenta/04-riferimenti-storici.md:1175` Immortali corpo scelto a pieno organico, `:2279` la disciplina «come pratica di un solo popolo», `:2751` agoge spartana). Élite della **fase arcaica**: `piattaforma_trainata` (il carro dei *maryannu*, `04-riferimenti-storici.md:216` e `:3122` «arma da urto mobile … arma di stato palaziale», `:642` addestramento specializzato del carro; la ricerca ESCLUDE la fanteria pesante corazzata come élite arcaica: `:607` «la corazza metallica è oggetto da principe, non da reparto», `:609` «La fase arcaica non ha una fanteria corazzata: ha individui corazzati» — l'indizio del titolare sulle poche corazze di bronzo conferma proprio questo). Caveat dichiarato dalla ricerca: l'addestramento istituzionale del fante è «novità terminale» della fase antica (`04:2759`) e il tempo d'addestramento dell'uomo del carro non è quantificato (`04:962`); ciò che è documentato è il requisito, non la misura.

Rappresentazione. `DefinizioneArchetipo.eliteFase: Fase?` (enum `Fase` = arcaica/antica) dice in quale fase l'archetipo è élite; `ScenarioBattaglia.fase` e `StatoBattaglia.fase` dicono la fase della battaglia. L'élite senza soglia è la coppia `eliteFase == stato.fase`, letta in `MotoreBattaglia.risolvi` e nella validazione di `.disingaggiaSuOrdine`. Non è una tabella a doppia entrata: un campo per archetipo e uno per battaglia, combinati per uguaglianza. Il caricatore rifiuta due archetipi élite della stessa fase (`errore.dati.elite_di_fase_duplicata`). `guardia_elite` riceve una soglia di fascia 0,9 come ripiego per le fasi in cui non è élite (PROVVISORIA, non esercitata: è antica-solo per la ricerca); il comportamento accettato in antica — soglia assente — è invariato. `piattaforma_trainata` conserva 0,12 ed è élite solo in arcaica: datata in antica, si sfila. Cancelli: `DisingaggioElitarioTest.test_incarico11_l_elite_dipende_dalla_fase` (visto rifiutare) e `test_incarico11_l_elite_e_una_coppia_archetipo_fase_unica`. La battaglia non aveva concetto di fase (nessun passaggio campagna-battaglia); la fase è una proprietà DICHIARATIVA dello scenario, non un ponte dalla campagna. Assente nei salvataggi anteriori, la fabbrica assume l'antica.

Conseguenze. Versione dei valori 0.6.0 → **0.7.0**, `versioni_compatibili` = `["0.7.0"]`: cambia il reparto élite e il formato dello stato (campo `fase`), quindi un salvataggio 0.6.0 rigiocato ricostruirebbe uno stato diverso; è dichiarato incompatibile e rifiutato con `salvataggioIncompatibile`. Impronte e copioni d'oro rigenerati.

### RDA-93 — La soglia di disingaggio NON si dichiara al giocatore (modifica voluta di 01 §9.8.1)

Problema e decisione. 01 §9.8.1 prescrive che «la soglia è una caratteristica leggibile del reparto e va dichiarata fra le sue informazioni». Il titolare ROVESCIA deliberatamente la prescrizione: la soglia, e qualunque grandezza che dica quanto manchi a un reparto per cedere, NON si dichiara in alcuna forma, perché dirlo prima sarebbe artificioso e favorirebbe un gioco fondato sulla lettura dei numeri anziché sulla situazione. È modifica voluta, non correzione di una svista: nessuna revisione futura la reintroduca credendo di colmare una dimenticanza. Registrata come scostamento (S14) per la sessione di riallineamento di 01 §9.8.1. Cancello: `DesignazioneBersaglioTest.test_incarico11_l_elite_e_annunciata_e_la_soglia_no` accerta che l'annuncio di un reparto non contenga la soglia (né in cifre né in fasce).

### RDA-94 — Il reparto élite è annunciato come sempre controllabile, per l'addestramento superiore (incide sul gioco; 01 §3.3, 02 §3.8.1)

Scelta. Il reparto élite della fase corrente porta fra le proprie informazioni l'annuncio `battaglia.reparto_elite` («reparto scelto: per l'addestramento superiore resta ai tuoi ordini anche in mischia»), in `CostruttoreAnnunci.contenutoCella`, riconoscibile PRIMA di ingaggiare e per il proprio reparto come per l'avversario. La ragione comunicata è l'addestramento superiore, non la meccanica; non è la soglia (RDA-93). Il testo sta nei file (`Annunci.strings`), manifest rigenerato; non è un termine del vocabolario chiuso (02 §4.4.5 elenca stati, non tratti). Poiché la soglia non si annuncia, le tre FASCE si distinguono per chi ascolta dal solo nome dell'archetipo, che il gioco già dichiara: tiratori/piattaforma/macchina da tiro dicono il tiro (fascia bassa), fanteria leggera e cavalleria dicono il tipo mobile (media), fanteria pesante e macchina d'assedio dicono il peso (alta). I nomi bastano a distinguere le tre fasce; l'élite, che i nomi non renderebbero riconoscibile per la piattaforma arcaica, ha l'annuncio proprio. Nessun annuncio nuovo per le fasce.

### RDA-95 — La regola del secondo contatto è confermata e il suo interruttore è rimosso (01 §9.8.3)

Scelta. Il titolare conferma la regola per cui due reparti già staccati, tornando a contatto, combattono fino alla dispersione senza più soglia (01 §9.8.3). L'interruttore `soglia_al_secondo_contatto` introdotto per la misura dell'incarico 10 è RIMOSSO da `ParametriCombattimento`, da `combattimento.json` e dal Motore: un interruttore lasciato in piedi è una decisione che qualcuno riaprirebbe. La regola vale sempre. Cancello: `MisuraMischiaTest.test_incarico11_il_secondo_contatto_combatte_fino_alla_dispersione`. La sezione di misura `secondo_contatto` è rimossa dal programma di verifica.

### RDA-96 — Lo scorrimento anticipato della mappa è comportamento accettato, non difetto (S12)

Scelta. Lo scorrimento anticipato della mappa quando il fuoco passa dalle prime righe ai comandi (S12, incarico 08) NON è un difetto e non va corretto. Il titolare l'ha provato e lo giudica accettabile e utile: riporta la vista verso le proprie truppe, il comando si raggiunge in meno di un secondo, e la manovra riguarda al più chi vede parzialmente, poiché chi non vede non punta il dito su un tasto in quel modo. S12 è trasformato da scostamento aperto in COSTO DICHIARATO E ACCETTATO, nella forma del punto 16.6 di 01, perché nessuna sessione futura si metta a correggerlo.

## Parte sedicesima — Decisioni della sessione dei simboli delle tessere del deck (incarico 13)

### RDA-97 — I simboli grafici degli archetipi al posto della sigla testuale, e la regola dell'assetto misto (02 §8.2, 00 §1.4, principio 1; sostituisce il segnaposto di RDA-85)

Problema. RDA-85 mostrava al centro della tessera del deck la sigla testuale dell'archetipo (`deck.sigla.<archetipo>`), dichiarata SEGNAPOSTO in attesa dei simboli grafici. Questa sessione produce i simboli veri e rimuove la sigla.

Forma dei simboli. Nove simboli, uno per archetipo, forme vettoriali monocrome scritte a mano nel formato dei simboli di sistema: un `.symbolset` per archetipo in `Applicazione/Risorse/Immagini.xcassets`, ciascuno un SVG con lo scheletro del template SF Symbols (gruppo `Guides` con `Capline-S/M/L` e `Baseline-S/M/L`; gruppo `Symbols` con le nove varianti peso×scala `{Ultralight,Regular,Black}-{S,M,L}` che condividono un solo path di glifo, poiché la silhouette è piena e non varia col peso). Ogni `.symbolset` porta il NOME dell'archetipo, sicché il caricamento è per identificatore e senza stringhe nel codice: `UIImage(named: elemento.archetipo)`. Il simbolo è UNA forma sola che prende il colore da fuori — reso in `.alwaysTemplate`, tinto con `tintColor` quando la tessera è selezionata e con `.label` altrimenti — e non porta colori scritti dentro: la riconoscibilità sta nella FORMA, non nella tinta (00 §1.4), e i nove differiscono per silhouette. I glifi: fanteria leggera = lancia; fanteria pesante = scudo; guardia scelta = elmo crestato con feritoia (elmo corinzio di profilo); tiratori = arco con freccia incoccata; cavalleria da ricognizione = testa di cavallo; cavalleria manovrata = due lance incrociate; piattaforma trainata = affusto su ruota con timone di traino; macchina d'assedio = ariete sotto tettoia; macchina da tiro = catapulta con braccio e proiettile.

Accertamento sugli assetti (fatto PRIMA di disegnare). Gli archetipi sono NOVE e chiusi (`archetipi.json`, nove `identificatore`). Gli assetti misti — reparti che si annunciano col nome dell'assetto e mai coi componenti (02 §3.7.1) — NON sono istanziati nel modello di battaglia: `ElementoDeck` e `Sciame` (`StatoBattaglia.swift`) portano un solo `archetipo` più la `protezione`, cioè sono monotipo; nessun file di dati definisce un assetto misto. Il concetto è consolidato ma APERTO (01 §4.7: «un insieme di assetti ammessi», ciascuno con taglia e composizione, che cresce con le combinazioni), a differenza dei nove archetipi che sono chiusi.

Regola dell'assetto misto. Poiché gli archetipi sono pochi e chiusi, si disegna UN simbolo proprio per ciascuno (sostenibile). Poiché gli assetti sono aperti, per un assetto misto NON si disegna un simbolo per combinazione: varrà il simbolo dell'archetipo PREVALENTE con un segno che dichiara la mistione — una REGOLA imperniata sull'archetipo prevalente, non un elenco di disegni. Vale in ogni caso 02 §3.7.1 per il segno come per la voce: il simbolo non tenta di rappresentare la composizione. La regola è DICHIARATA ma non resa nel codice, perché il modello non prevede ancora l'assetto misto (niente campo di composizione, niente archetipo prevalente): renderla ora sarebbe un canale che esiste solo per il collaudo. `nomeSimboloElementoDeck` restituisce già l'archetipo dell'elemento, che nel modello attuale è puro.

Cancello (il controllo che rifiuta, non la prescrizione scritta). La biiezione archetipi↔simboli è imposta nei due versi: `SimboliDegliArchetipiTest.test_principio_1_ogni_archetipo_ha_il_proprio_simbolo` (prova ospitata) fa fallire il caso «archetipo senza simbolo» caricando il simbolo di ciascun archetipo dei dati; `scripts/verifica-simboli.sh` (cancello di script, invocato come passo 0 di `collaudo-completo.sh`) impone entrambi i versi — archetipo senza simbolo E simbolo orfano — perché il verso orfano non è enumerabile dal catalogo compilato a runtime. Il cancello è stato visto fallire di proposito nei due versi (rimozione di `guardia_elite.symbolset` → «archetipi senza simbolo: guardia_elite»; symbolset estraneo → «simboli orfani»), poi ripristinato. È la stessa forma di protezione della copertura del formato di salvataggio.

L'annuncio non cambia. Etichetta e valore della tessera restano l'uscita di `CostruttoreAnnunci.nomeElementoDeck`/`valoreElementoDeck`, funzioni NON toccate: il simbolo è decorazione, escluso dall'albero accessibile come i due quadratini, e non essendo testo non può comparire nell'annuncio. `StabilitaDellaDisposizioneTest.test_02_8_2_l_annuncio_della_tessera_non_cambia_col_ridisegno` confronta ora l'etichetta e il valore della tessera con l'uscita del costruttore (prima=dopo) e verifica che il simbolo sia disegnato.

Leggibilità. `SimboliDegliArchetipiTest.test_00_1_4_ogni_simbolo_si_disegna_a_dimensione_reale_in_chiaro_scuro_e_contrasto` disegna ogni simbolo al lato reale del riquadro (`TesseraDeck.latoSimbolo`, 32 punti), tinto con `.label` risolto in chiaro, in scuro e col contrasto aumentato, e pretende che il risultato abbia inchiostro. La riconoscibilità delle nove forme a quella dimensione è stata verificata rasterizzando i path su host in chiaro e scuro (i simboli sono silhouette piene; il contrasto aumentato ne rende la tinta più netta e non altera la forma).

Conseguenze sul codice. `TesseraDeck.etichettaSigla` (UILabel) → `vistaSimbolo` (UIImageView, template, `scaleAspectFit` in un riquadro fisso di 32 punti centrato fra nome e quadratini); `aggiorna(... sigla: String ...)` → `aggiorna(... simbolo: UIImage? ...)`; `siglaDisegnataPerProva` → `simboloDisegnatoPerProva`. `CostruttoreAnnunci.siglaElementoDeck` → `nomeSimboloElementoDeck` (restituisce l'identificatore dell'archetipo). `SchermataBattaglia.montaDeck`/`aggiorna(con:)` carica `UIImage(named:)`. Chiavi `deck.sigla.*` rimosse da `it.lproj/Annunci.strings`; `en.lproj/Annunci.strings` — che conteneva SOLTANTO le sigle inglesi — eliminato con la cartella `en.lproj` (i simboli sono indipendenti dalla lingua); manifest dei testi rigenerato (versione 0.1.1 invariata). Voce delle sigle rimossa da `valori-provvisori.md`.

Geometria invariata. Riquadro 65×56 fisso, altezza dello stato più lungo, banda del deck compatta (S10), altezza minima della griglia (RDA-86): nulla toccato. Se un simbolo non entra si rimpicciolisce il simbolo (`scaleAspectFit`), non si allarga la tessera.

Versione dei valori. NON incrementata: cambia solo la rappresentazione visiva della tessera; nessuna regola incide su come una partita in corso si svolgerebbe (l'annuncio, il modello dello stato e i valori sono invariati), quindi non ricorre il criterio di RDA-92/RDA-91. Resta 0.7.0.

## Parte diciassettesima — Decisioni della sessione della risoluzione di fine giornata e delle marce di più giorni (incarico 14)

### RDA-98 — La risoluzione di fine giornata è un momento dichiarato e ordinato, non una funzione che fa una cosa sola (01 §5.6.11)

Problema. Con le marce di più giorni il movimento non avviene più all'atto dell'ordine ma alla chiusura della giornata, dove 01 §5.6.11 colloca un ORDINE di risoluzioni: avanzamento delle marce lunghe, scatto delle imboscate, valutazione dei tagli di rifornimento, completamenti di costruzione, invecchiamento e decadimento della conoscenza. Di queste, questa unità realizza soltanto la prima; le altre appartengono a materie non ancora costruite. Il rischio è scrivere il meccanismo sulla misura del suo unico abitante, e costringere la sessione successiva a rifarlo per aggiungervi un passo.

Opzioni. Una funzione `avanzaLeMarce` chiamata direttamente da `chiudiLaGiornataSeServe`; oppure un momento `risolviFineGiornata` che elenca i passi in ordine e ne contiene oggi uno solo.

Scelta. La seconda. `MotoreCampagna.risolviFineGiornata(_:)` è il momento; contiene la sola chiamata a `avanzaLeMarce(_:)` più i posti dichiarati in commento per i passi futuri, ciascuno con la propria firma `(inout StatoCampagna) -> [EventoCampagna]`. Una sessione futura aggiunge il proprio passo come una riga in coda a `risolviFineGiornata`, senza toccare gli altri: ogni passo è indipendente e riceve e restituisce lo stato per riferimento. `chiudiLaGiornataSeServe` chiama `risolviFineGiornata` fra l'evento `giornataChiusa` e l'incremento del giorno.

Motivazione. L'ordine di 01 §5.6.11 è un fatto di gioco (determina quale risoluzione vede lo stato prima di un'altra) e va reso esplicito nel codice, non lasciato all'ordine di scrittura di chiamate sparse. Il costo — una funzione in più che oggi delega a una sola — è precisamente ciò che rende il punto d'estensione visibile.

Conseguenze. `chiudiLaGiornataSeServe` è un CICLO e non un solo passo: se dopo l'apertura della giornata nuova tutti i gruppi restano in marcia lunga, non c'è nulla da ordinare e le giornate scorrono a cascata finché una marcia si compie e libera un gruppo. Il ciclo termina perché ogni giro avanza tutte le marce di un giorno. La chiusura automatica di 01 §5.6.0.6 non è toccata: nessun comando di fine giornata, nessun gruppo che agisca da sé. Il criterio della chiusura passa da `allSatisfy(azioneSpesa)` a `allSatisfy(haConclusoLaGiornata)`, dove un gruppo in marcia ha concluso la giornata pur senza spendere l'azione.

### RDA-99 — I fattori del costo in giorni confluiscono in una sola grandezza (01 §5.6.3.2)

Problema. 01 §5.6.3.2 vuole che sul numero di giorni dello scatto agiscano insieme, in UNA SOLA grandezza e senza regole che si sommino in modo opaco, la natura della casella di partenza e di arrivo con pesi distinti, il volume della colonna, il tipo di strada e il costo fisso della strettoia. La firma `costoInGiorni(da:a:stato:)` era già definitiva (RDA-75) proprio perché il punto di calcolo non si spostasse quando questi fattori sarebbero arrivati.

Scelta. `MotoreCampagna.costoInGiorni` somma il costo base, il peso del terreno di partenza, il peso del terreno di arrivo, il peso della strada di arrivo e il costo della strettoia se la casella di arrivo la è, e satura il risultato a uno. I pesi vivono nei dati (`marcia-campagna.json`: `peso_terreno_partenza`, `peso_terreno_arrivo`, `peso_strada_arrivo`, `costo_strettoia`), sono `[String: Int]` per rawValue di `TerrenoCasella`/`TipoStrada`, e il caricatore RIFIUTA una copia che ometta un terreno o una strada — un peso mancante sarebbe un fattore che si somma per omissione. Nessuna tabella a doppia entrata: una formula nel codice, coefficienti nei file.

Il VOLUME non agisce ancora. Il gruppo non ha composizione in questa unità (`impatto-marcia-lunga.md` §1 la rinvia): la firma riceve già lo `stato` e vi leggerà il volume quando la composizione esisterà, senza spostare il punto di calcolo. È un fattore DICHIARATO ma non reso, non un'omissione silenziosa: renderlo senza un volume da leggere sarebbe un canale che esiste solo per il collaudo.

Conseguenze. Con i pesi introdotti (tutti PROVVISORI, in `valori-provvisori.md`) la stessa casella costa da uno a tre giorni secondo il terreno; l'identità «una casella = una giornata» della prima unità cade, come `CostoDellaMarciaTest` fissava che sarebbe caduto. Il minimo di uno resta FISSATO da 00 §13.6 e imposto dal caricatore. Il costo viaggia dentro il comando (RDA-75) e la validazione rifiuta un comando che ne dichiari un altro.

### RDA-100 — La revoca è un comando proprio, e la decisione del titolare sulla giornata (01 §5.6.3.3, §5.6.8.1, RDA-76)

Problema. RDA-76 aveva distinto annullamento e revoca e stabilito che la revoca, quando si fosse realizzata, sarebbe stata un comando proprio che si aggiunge alla sequenza invece di toglierne. 01 §5.6.8.1 la elenca fra le operazioni che NON sono azioni e non consumano la giornata; ma i documenti lasciavano aperto se la revoca RESTITUISСА la giornata in cui viene compiuta, perché ogni azione consuma l'intera giornata mentre la revoca non è un'azione.

La decisione del titolare. La revoca NON restituisce la giornata. È gratuita come atto — non è essa stessa un'azione — ma il gruppo che revoca ha già speso la propria giornata con l'ordine di marcia impartito e non compie altro quel giorno. Perde i giorni già spesi nella marcia e resta senza azione per la giornata corrente.

Scelta. `ComandoCampagna.revocaMarcia(gruppo:)`, caso nuovo che passa per `valida`/`applica` come ogni comando e si iscrive nel giornale come `.comandoCampagna`, ricalcolabile alla ripresa; NON dal comando di annullamento né dal troncamento del giornale. `valida` la ammette solo su un gruppo in marcia (motivo nuovo `comando.non_valido.gruppo_non_in_marcia`), senza controllare `azioneSpesa`, perché si può revocare in qualunque momento, anche nel giorno stesso dell'ordine. `applica` azzera la marcia (i giorni compiuti si perdono, la posizione resta quella di partenza) e pone `azioneSpesa` a vero: la giornata è spesa. La conseguenza — i giorni persi — è dichiarata prima della conferma, nel pannello di revoca (01 §5.6.3.5).

Conseguenze. Caso nuovo di `ComandoCampagna`: la catena di `CompatibilitaGiornaleTest` pretende il campione, committato nella stessa modifica. Registrata come scostamento la contraddizione dei documenti che la decisione chiude (S15). L'invariante `revoca_non_conforme` sorveglia che una revoca lasci sempre il gruppo nella casella di partenza, senza marcia residua e con la giornata spesa.

### RDA-101 — Riesame della deroga sul registro: gli ordini restano accanto ai fatti nuovi (01 §5.17.1, RDA-72) — SUPERATO da RDA-104

**Superato dall'incarico 15.** La previsione qui sotto — rinviare la rimozione degli ordini alla comparsa dei fatti avversari — è superata dalla quarta correzione del titolare (RDA-104): gli ordini escono dal registro ORA. Il testo resta verbatim.


Problema. RDA-72 aveva ammesso gli ordini del giocatore nel registro, in deroga a 01 §5.17.1 che li esclude, perché nel perimetro della prima unità non esisteva alcun fatto non deciso dal giocatore (scostamento S8). RDA-72 prevedeva che, comparso il primo fatto non deciso dal giocatore, 01 §5.17.1 andasse confermato togliendo allora gli ordini. Questa sessione porta quel fatto: il compimento di una marcia lunga (01 §5.17.1).

Opzioni. Togliere gli ordini e lasciare nel registro i soli fatti non decisi dal giocatore (conferma di 01 §5.17.1); oppure lasciare gli ordini accanto ai fatti nuovi (deroga estesa).

Scelta. Gli ordini RESTANO. La ragione che 01 §5.17 dichiara per il registro è il recupero degli annunci persi mentre il giocatore fa altro; nel perimetro attuale — solo, senza avversario, con i completamenti come unico fatto e per giunta raro — un registro dei soli completamenti sarebbe quasi vuoto e perderebbe gli annullamenti, che RDA-72 dichiara fatti che il giocatore può volere ricostruire. Togliere gli ordini cambierebbe ciò che il giocatore sente, in peggio; e l'incarico chiede espressamente di non decidere da soli una scelta che cambia ciò che il giocatore sente.

Motivazione della divergenza dalla previsione di RDA-72. La previsione fu fatta quando la forma del primo fatto era ignota. Ora si vede che è raro e che il perimetro resta di sola giocata; la rimozione degli ordini avrà senso quando esisteranno i fatti avversari, frequenti e mancabili — cioè alla sessione di riallineamento, dove 01 §5.17.1 si conferma o si riscrive. Fino ad allora la deroga S8 resta dichiarata.

Conseguenze. `FattoRegistrato` acquista `marciaCompiuta(gruppo:da:a:)` (primo fatto non deciso dal giocatore, luogo = casella di arrivo, primo fatto che esercita il salto al luogo di RDA-67) e `marciaRevocata(gruppo:casella:)`; gli ordini preesistenti restano. La sonda di sessione `registro_non_corrisponde` passa da «voci = ordini» a «voci = ordini + compimenti».

### RDA-102 — Il confine dell'annullamento morde sul compimento di una marcia (05 §6.5, 00 §13.8, RDA-70, RDA-73)

Problema. Fino a questa unità la chiusura della giornata non aveva nulla di giocato dopo di sé, e RDA-70/RDA-73 concedevano di annullare l'ordine che l'aveva chiusa finché la giornata nuova era intatta. Con la risoluzione di fine giornata la chiusura produce FATTI: il compimento di una marcia lunga, che il giocatore ascolta. Annullare dopo averlo ascoltato equivarrebbe a rifare la mossa sapendo com'è andata, cioè alla prova a rovescio che 05 §6.5 vieta.

Opzioni. Rimuovere del tutto la grazia (l'ordine di chiusura non si annulla mai, come la build 11); oppure rimuoverla solo quando la chiusura ha prodotto un fatto ascoltato.

Scelta. La seconda. La grazia di RDA-73 resta valida per le chiusure SENZA fatti, dove 00 §13.8 — annullare l'ultimo gesto, che è principio dell'accessibilità e prevale su 05 — chiede che l'ordine resti annullabile; e cade per le chiusure che compiono una marcia, dove 05 §6.5 prevale. La rimozione totale reintrodurrebbe proprio il difetto che RDA-70/RDA-73 avevano corretto (l'ordine dell'ultimo gruppo irreversibile senza segnale), a danno di chi ascolta, nel caso frequente in cui nessuna marcia si compie.

Dove vive il confine, e perché lì. Nel GIORNALE, come marcatore nuovo `VoceGiornale.risoluzioneGiornata(giorno:)`, scritto dalla Sessione alla chiusura SE e solo se la risoluzione ha compiuto almeno una marcia (evento `.marciaCompiuta`), prima dell'apertura della giornata. `SessioneCampagna.ordineDentroIlConfine` concede l'annullamento dell'ordine di chiusura finché la giornata nuova è intatta E fra quell'ordine e l'apertura non sta un `risoluzioneGiornata`. Sta nel giornale e non nello stato perché il confine deve sopravvivere alla ripresa della campagna, dove i difetti di questa specie si manifestano. Il marcatore NON duplica i fatti che il registro annota — quelli si ricalcolano riapplicando il comando di chiusura — e serve al solo confine.

### RDA-103 — La composizione dei gruppi e il volume, con l'accertamento sull'omonimia col volume di battaglia (01 §5.6.0, §5.6.3, §3.4.4)

Problema. Il gruppo di campagna non aveva composizione: era identità, nome, posizione, azione e marcia. Il volume della colonna — la grandezza da cui 01 §5.6.3 fa dipendere il costo della marcia, la lunghezza della colonna e la capacità di trasporto — non esisteva, e RDA-99 aveva dichiarato che non agiva ancora sul costo «perché il gruppo non ha composizione». Questa unità costruisce la composizione e il volume, primi perché tutto il resto vi poggia.

Forma della composizione. `Gruppo.composizione: [Reparto]`, dove `Reparto` è `(archetipo: IdentificatoreDati, atomi: Int)` — l'unità INTERA su cui lavorerà la divisione (01 §5.6.0.2). La composizione è `var` perché la divisione staccherà reparti interi e la riunione li fonderà. Mai vuota: la fabbrica `FabbricaCampagna.crea` respinge lo scenario che dichiari una composizione vuota (`gruppoSenzaComposizione`), un reparto a atomi non positivi (`repartoVuoto`) o un archetipo ignoto (`archetipoIgnoto`), come lo scenario di battaglia respinge i propri sciami. Lo scenario porta la composizione (`ScenarioCampagna.GruppoIniziale.composizione: [RepartoIniziale]`), quindi `FondazioneCampagna` cambia forma e lo schema del giornale di campagna sale da 3 a 4 (00 §15.2): un giornale di versione 3, i cui gruppi non hanno composizione, non ha da dove leggere il volume e non si riapre.

Il volume NON è un campo. `MotoreCampagna.volume(di gruppo:)` lo DERIVA dalla composizione: somma sui reparti di `atomi × volume_per_atomo` dell'archetipo. Derivarlo, invece di conservarlo, rende IMPOSSIBILE che diverga dalla composizione — la sola via che rende impossibile lo stato sbagliato dell'invariante «il volume è la somma di ciò che lo compone», invece di sorvegliarlo soltanto. L'invariante esiste comunque, con mutante: `SondaInvariantiCampagna.controllaVolumi` riceve dall'esterno il volume riportato (nel banco, `motore.volume`) e lo confronta con la somma indipendente, come `controllaPosizioniVisive` per la posizione visiva; il mutante gliene passa uno divergente. `gruppoVuoto` è il secondo invariante nuovo, con mutante che svuota la composizione.

Accertamento sull'omonimia col volume di battaglia — ESITO: è la STESSA grandezza, non due omonime. 01 §3.4.4 dichiara «il volume è il parametro unico da cui dipendono tanto il costo di schieramento quanto la velocità di marcia della colonna» ed è «unico e stabile per archetipo». `MotoreCampagna.volume` legge lo STESSO campo dell'archetipo, `volume_per_atomo`, che `MotoreBattaglia.volume(di sciame:)` usa per l'ingombro manovrabile (01 §9.5.0.2): stessa formula `atomi × volume_per_atomo`, stesso dato. Perciò non riceve un nome diverso. Ciò che invece è un'ALTRA cosa, e conserva il proprio nome, è `BilancioVolume`, il budget di manovra che si rigenera a ogni turno di battaglia (01 §9.3): quello è capacità del comandante, non ingombro di una forza, e non entra in campagna. Il precedente errore da omonimia (due grandezze chiamate uguali in un resoconto) è così evitato per accertamento dichiarato, non per assunzione.

Il volume nel costo. `costoInGiorni(da:a:stato:)` — firma già definitiva (RDA-75, RDA-99) — legge il volume del gruppo che occupa la casella di partenza e vi somma `volume / soglia_volume_per_giorno_aggiuntivo` (troncamento), sulla MEDESIMA grandezza degli altri fattori: una colonna più voluminosa è più lunga e percorre meno strada in una giornata (01 §5.6.3), sicché il contributo è positivo e monotòno. La soglia è PROVVISORIA (`valori-provvisori.md`), minimo uno perché è un divisore, imposta dal caricatore. Il punto di calcolo non si sposta: `impatto-marcia-lunga.md` §1 è superato.

Conseguenze. Schema del giornale di campagna a 4; campione `fondazioneCampagna` rigenerato con la composizione, nella stessa modifica (`CompatibilitaGiornaleTest`). Versione dei valori a 0.9.0 (impronte rigenerate), `0.8.0` conservata in `versioni_compatibili` perché i salvataggi di battaglia restano compatibili — nulla di battaglia è cambiato — mentre quelli di campagna li dichiara incompatibili il cancello dello schema. Banco esteso: la `Corsa` porta `volumeMinimo`/`volumeMassimo`, il riepilogo `volume_minimo/massimo_fra_gli_scenari` e `soglia_volume_per_giorno_aggiuntivo`, e gli scenari di `campagne.json` portano tre fasce di volume (60, 292, 696 → zero, uno, due giorni aggiuntivi) così che il banco generi marce di volumi diversi, non le renda soltanto possibili.

### RDA-104 — Le quattro correzioni del titolare sulla marcia, dopo la prova sul dispositivo (01 §5.6.3.3, §5.6.3.5, §5.17.1)

Decisioni del titolare, prese provando la build sul dispositivo, da eseguire come scritte. Sono sue e non discendono da un consolidato; si registrano come tali.

Prima. Il pannello di conferma della marcia SPARISCE. L'ordine parte direttamente dalla voce del comando, senza schermata intermedia. `SchermataMappaCampagna.attiva`, ramo della designazione `.marcia`, non apre più `apriPannelloConfermaMarcia` (metodo rimosso) ma esegue il comando; il pannello di conferma resta per la sola revoca (`apriPannelloConfermaRevoca`).

Seconda, e la ragione della differenza fra ciò che si vede e ciò che si sente. La voce del comando — la voce della casella di destinazione durante la designazione — porta il costo in giorni, e per chi ascolta porta ANCHE la conseguenza dell'inchiodamento. Ciò che si vede sulla voce dice la destinazione e i giorni; l'etichetta destinata alla sintesi vocale (`CostruttoreAnnunciCampagna.etichettaCasella`, ramo `.valido`) aggiunge, con `casella.inchioda`, che il gruppo resterà fermo fino all'arrivo e non potrà sfilarsi senza perdere i giorni spesi. La ragione della differenza: chi vede riceve la stessa informazione dai nove pallini che mostrano il gruppo avanzare dentro la casella (01 §5.6.3.4), mentre chi ascolta non ha quel canale. Non è una disparità ma la parità ottenuta per due vie diverse, ed è coerente con 01 §5.6.3.5 che vuole la conseguenza dichiarata prima della conferma: qui l'attivazione È la conferma, e la voce È la dichiarazione.

Terza. Il pannello di conferma resta per la SOLA revoca, ed è lì che si dichiarano le conseguenze del revocare — i giorni che si perdono e la giornata che resta spesa (`pannello.revoca_conferma`, 01 §5.6.3.5).

Quarta. Gli ordini di marcia e di presidio ESCONO dal registro degli eventi. Vi restano la marcia revocata e l'arrivo del gruppo a destinazione. È il ripristino di 01 §5.17.1 (il registro annota i fatti che il giocatore NON ha deciso): gli ordini vi erano entrati in deroga dichiarata (S8, RDA-72) soltanto perché nel perimetro di allora non esisteva alcun fatto non deciso, e adesso quel fatto — il compimento della marcia — esiste. La deroga S8 e la previsione di RDA-101 (che rinviava la rimozione alla comparsa dei fatti avversari) sono SUPERATE dalla decisione del titolare: la rimozione avviene ora. La revoca RESTA nel registro benché decisa dal giocatore, per volontà del titolare, perché è il fatto che spiega perché un gruppo si trovi fermo — eccezione voluta, non dimenticanza. `MotoreCampagna.applica` non chiama più `annota` per gli ordini; `FattoRegistrato` perde i casi `marciaOrdinata` e `presidioOrdinato` (l'impronta, il traduttore e i campioni ne seguono); gli EVENTI `marciaOrdinata`/`presidioOrdinato` restano e fanno l'annuncio immediato della conferma dell'ordine, che il giocatore ascolta.

Conseguenze sulle prove. Cadono il pannello di conferma della marcia (`test_02_9_2_1` riscritto: l'attivazione ordina direttamente, e la voce della destinazione porta costo e inchiodamento) e le voci di registro degli ordini (`RegoleCampagnaTest`, `MappaCampagnaAccessibileTest`, `SessioniCompleteTest`, `SondaSessioneCampagna` riscritti: il registro accumula i soli compimenti; il salto al luogo del fatto ora si esercita sul compimento, la cui `a` è una casella reale). Testi rimossi: `pannello.marcia_titolo`, `pannello.marcia_conferma_azione`, `pannello.marcia_conferma`, `registro.marcia_ordinata`, `registro.presidio_ordinato`; aggiunto `casella.inchioda`. Impronte dei testi rigenerate.

Conseguenze. Caso nuovo di `VoceGiornale`: la catena di `CompatibilitaGiornaleTest` pretende il campione. Il rifiuto oltre il confine si dichiara col termine chiuso già esistente `campagna.non_si_torna_oltre_la_giornata`. Situazione raggiungibile e provata: un gruppo marcia verso l'acqua, la marcia si compie a cascata, l'annullamento è rifiutato e il rifiuto sopravvive al riavvio (`AnnullamentoGiornataTest`). Predisposto per l'avversario: quando le sue mosse produrranno fatti alla chiusura, il marcatore li coprirà con la stessa logica.

### RDA-105 — La discordanza di un'impronta di Contenuti si dichiara, invece dell'auto-rigenerazione (05 §7.2, 00 §14.1)

Problema. Due volte nella sessione precedente, la modifica di un file di Contenuti senza rigenerare le impronte ha fatto fallire in massa prove che sembravano regressioni: `Testi.carica` RESPINGE una copia divergente dal proprio manifest (05 §7.2), e il rifiuto risaliva in molti `setUp`, con la sola riga opaca `ErroreDati(chiave: "errore.testi.impronta_discorde", …)`. L'incarico chiedeva di togliere la CONDIZIONE, non l'effetto: o la rigenerazione avviene da sé, o il fallimento dichiara la causa e il comando.

Perché NON l'auto-rigenerazione. Rigenerare le impronte prima delle prove renderebbe VACUO il controllo `test_05_7_2_testi_di_fabbrica_coincidono_con_le_impronte`, che accerta proprio che i file committati coincidano col manifest committato: se si rigenerasse, coinciderebbero sempre, e la protezione che invalida la copia stantia in Documenti (memoria d'infrastruttura, regola 6) sparirebbe. E l'auto-rigenerazione a livello di prova non aiuterebbe chi corre `swift test` da solo. Perciò la seconda via: il fallimento si dichiara.

Scelta. (a) `scripts/rigenera-impronte.py --verifica`: modalità di sola verifica che confronta i file col manifest SENZA scrivere ed esce 1 dichiarando in chiaro, in italiano, causa, file divergenti e comando. (b) `collaudo-completo.sh` la esegue come passo 0b, PRIMA delle prove del pacchetto: una discordanza si dichiara in due secondi invece di far fallire in massa dopo quarantacinque. (c) `ErroreDati: CustomStringConvertible` che, per la chiave d'impronta, nomina il file e lo script — SENZA spazi, perché il collaudo dei confini (00 §14.1) vieta le stringhe con spazi nei Sorgenti, come per i codici degli invarianti; la dichiarazione in prosa vive nel cancello dello script e del collaudo, non nel codice. Il controllo resta un rifiuto e non è vacuo: `test_05_7_2_*_respinto` prova che `Testi.carica` respinge ancora una copia divergente, e il nuovo cancello è stato visto fallire di proposito (uscita 1) e passare dopo il ripristino.

### RDA-106 — Divisione e riunione dei gruppi: sequenza d'interazione e denominazione (01 §5.6.0.2, §5.6.0.3, §5.6.0.4)

Comandi. `ComandoCampagna.divisione(gruppo:repartiStaccati:a:)` e `.riunione(gruppo:con:)`, casi nuovi che passano per la catena di `CompatibilitaGiornaleTest` (specchio `SpecieDiComandoCampagna`, due campioni committati nella stessa modifica). La divisione porta gli INDICI dei reparti da staccare, perché lavora su reparti interi (01 §5.6.0.2); la validazione respinge selezione vuota o totale, indici ripetuti o inesistenti (`divisioneImpropria`). La riunione porta i due id. Nessun `FattoRegistrato`: divisione e riunione sono decise dal giocatore e non entrano nel registro (01 §5.17.1, RDA-104); gli eventi `gruppoDiviso`/`gruppiRiuniti` fanno l'annuncio immediato.

Applicazione. La divisione toglie i reparti staccati dall'origine (che spende l'azione) e crea il distaccamento nella casella adiacente con id e nome nuovi, azione GIÀ SPESA (il collocamento è uno spostamento). La riunione determina il MAGGIORE per volume — a parità l'id minore — che conserva nome, id e casella; l'assorbito sparisce; la composizione è l'unione; l'azione spesa del risultante è l'OR delle due (01 §5.6.0.3), o un gruppo che ha marciato si rimetterebbe in marcia fondendosi con uno fermo. L'inchiodamento (marcia lunga) impedisce entrambe e si controlla PRIMA dell'azione spesa, così che il giocatore senta `gruppoInchiodato` e non `azioneGiaSpesa`.

Denominazione, e lo scostamento S16. Il distaccamento riceve il prossimo nome della lista chiusa; i nomi NON si riusano (contatore monotòno `prossimoIndiceNome`). Ciò impone un tetto pratico al numero di gruppi CREATI, in tensione con 01 §5.6.0.1 («non esiste alcun tetto al numero di gruppi contemporaneamente attivi»): scostamento S16, mitigato allargando la lista da dodici a ventiquattro nomi; il rifiuto `nomiEsauriti` morde solo dopo moltissime divisioni. Il riuso dei nomi liberati alla riunione è la soluzione piena e resta rinviata.

Sequenza d'interazione della divisione, e il suo costo. È l'operazione più complessa della mappa (02 §10.3) e non ha tabelle a caselle né trascinamento: `SchermataDivisione` è un elenco di elementi accessibili, ciascuno una frase compatta. Chi ascolta: attiva la casella del gruppo (1), attiva «Dividi» (1), commuta ogni reparto da staccare (k, una per reparto), attiva una casella di destinazione (1), che conferma. Totale k+3 tocchi per staccare k reparti. Chi vede compie gli stessi gesti sulle stesse righe: tocca il gruppo, tocca «Dividi», tocca i reparti, tocca la destinazione — costo pari, dati identici, come 02 §10.3 vuole. Una destinazione attivata con scelta impossibile (nessun reparto staccato, o tutti) non divide e lo dichiara (`divisione.scelta_incompleta`). La riunione non ha schermata: una voce «Riunisci con ⟨nome⟩» per ciascun gruppo proprio adiacente.

Invarianti nuovi, col mutante: `divisione_non_conserva` (la somma dei reparti dell'origine e del distaccamento eguaglia, come multiinsieme, il gruppo di prima) e `guadagno_azione` (nessun gruppo diviso o riunito guadagna una giornata; non si controlla quando la transizione ha chiuso la giornata e azzerato l'azione). Il banco genera divisioni e riunioni con regole fisse sul giorno, non le rende soltanto possibili: `swift run StrumentoVerifica` riporta `divisioni_in_totale` 53 e `riunioni_in_totale` 61, con `violazioni_trovate_in_totale` 0 e `invarianti_sorvegliati` 24.

### RDA-107 — Il taglio del rifornimento: la geometria delle spalle e la direzione dal quartier generale reale (incide sul gioco; 01 §5.2.2.2)

Le caselle alle spalle. Il rifornimento di una colonna è tagliato quando una forza nemica occupa una delle SEI caselle alle sue spalle: le tre colonne centrate su quella occupata (colonna meno uno, colonna, colonna più uno), prese sulla riga occupata e sulla riga immediatamente RETROSTANTE. `MotoreCampagna.caselleAlleSpalle` le ricava; `rifornimentoTagliato` è vero se una casella di `forzeNemiche` vi cade. Le due condizioni di bordo cadono da sé filtrando le caselle inesistenti: sull'ultima riga verso il proprio quartier generale la riga retrostante non esiste e la fascia si riduce alle tre caselle della riga occupata; su una colonna di bordo si restringe a due colonne. Entrambe hanno la loro prova (`RifornimentoTest`).

La direzione, e l'errore che si corregge. «Retrostante» significa DALLA PARTE DEL PROPRIO QUARTIER GENERALE, e la direzione è ricavata dalla posizione REALE del quartier generale di quella parte (`mappa.quartierGenerale(di: gruppo.parte)`), mai da un'assunzione sulla geometria della mappa né dall'allineamento dei due quartier generali. È la correzione esplicita dell'errore che un'unità precedente aveva commesso assumendo i due quartier generali allineati: `caselleAlleSpalle` calcola il passo di riga dal quartier generale del gruppo, sicché per il giocatore (quartier generale in basso) il retro è verso le righe crescenti e per l'avversario (in alto) verso le decrescenti — la prova `test_5_2_2_2_la_direzione_viene_dal_quartier_generale_reale` mostra i due versi opposti sulla stessa casella.

Il dato minimo, non l'avversario. L'avversario sulla mappa NON è costruito (né condotta, né mosse): `forzeNemiche` è un insieme di caselle FERME, dato dello scenario, il minimo per rendere PROVABILE la regola del taglio. Le campagne giocabili non ne dichiarano; vi compaiono solo gli scenari di verifica. `ScenarioCampagna` le porta come campo opzionale che la codifica OMETTE quando è vuoto, sicché il campione del giornale e gli scenari che non le usano restano identici al byte (nessun salto di schema). La sonda degli invarianti ricava la geometria delle spalle PER CONTO PROPRIO, così che un errore del Motore non le sfugga.

### RDA-108 — Le zone di rifornimento e la fortezza isolata (incide sul gioco; 01 §5.2.2.6, §5.2.2.7)

La zona. Una struttura di rifornimento — fortezza o magazzino avanzato — rifornisce le NOVE caselle del blocco tre per tre centrato su di essa, diagonali comprese (distanza di Čebyšëv al più uno): `inZonaDiRifornimento`. In una zona il taglio NON ha effetto: `rifornimentoTagliato` è falso per un gruppo in zona, e la zona vince sul taglio anche se il nemico è alle spalle (invariante `zona_tagliata`). La fortezza ISOLATA rifornisce comunque, perché conta la prossimità e non il collegamento con la patria: la regola non guarda chi possiede l'intorno.

Il dato minimo, non l'opera. Le OPERE non sono costruite: `struttureDiRifornimento` è un insieme di caselle ferme, dato dello scenario, il minimo per rendere provabile la zona. Come le forze nemiche, è opzionale in `ScenarioCampagna` e omesso quando vuoto. Il banco genera i passaggi in zona e le strutture isolate; `StrumentoVerifica` li riporta.

### RDA-109 — Gli effetti del taglio, i due conteggi distinti, la sosta e il vocabolario (incide sul gioco; 01 §5.2.2.3, §5.2.2.4, §5.2.2.5, 02 §4.4.5)

La macchina a stati. Il taglio non paralizza: fa perdere tempo. Tre campi sul gruppo, tutti in [0, 2]: `turniSenzaProvviste` (i turni operati senza rifornimento), `sostaDovuta` (i turni di sosta ancora dovuti), `turniMarciaForzata` (SEPARATO, non alimentato da questa unità). La valutazione di fine giornata (`valutaITagliDiRifornimento`, passo di `risolviFineGiornata` dopo l'avanzamento delle marce, così una marcia compiuta si valuta già all'arrivo) applica la precedenza fissa: un gruppo IN SOSTA scala un giorno dovuto e, esaurito, torna rifornito azzerando i turni; un gruppo IN ZONA è rifornito comunque; un gruppo TAGLIATO accumula un turno senza provviste — al primo il rifornimento si interrompe, al secondo scatta la sosta imposta di DUE turni. Finché `sostaDovuta > 0` la marcia è vietata (`deveRifornirsi`, motivo `comando.non_valido.deve_rifornirsi`); il primo turno di sosta è dedicato al rifornimento (anche il presidio è vietato), il secondo è usabile per un'azione non di marcia. La sosta con raccolta (`ComandoCampagna.sostaConRaccolta`, azione esistente 01 §5.6.8.1, non voce nuova) la si può ordinare di propria iniziativa: se il gruppo ha già patito il taglio, fissa i giorni di sosta pari ai turni digiunati (autonomia: al limite ci si ferma sempre). Il malus del digiuno agisce ALTROVE, sui parametri del reparto, e MAI sul volume disponibile; i valori del malus e dell'autonomia restano da tarare e questa unità non li introduce (valori-provvisori.md, §«Valori della campagna»).

I due conteggi distinti. `turniSenzaProvviste` e `turniMarciaForzata` sono campi separati perché i due malus (mancanza di provviste e marcia forzata) si cumulano ma i loro conteggi non si confondono (01 §5.2.2.5). Questa unità alimenta solo il primo; il secondo resta a zero, e l'invariante `marcia_forzata_inattesa` lo sorveglia finché la marcia forzata non sarà costruita.

I fatti nel registro, e il vocabolario. Il taglio, la sosta IMPOSTA e la ripresa sono fatti che il giocatore NON decide: si annotano (01 §5.17.1) con il giorno e il salto al luogo (`FattoRegistrato.rifornimentoInterrotto/sostaDiRifornimento/rifornimentoRipreso`). La sosta VOLONTARIA è un ordine e non si annota. I segnali: il taglio e la sosta imposta portano lo stesso segnale dedicato `rifornimento_interrotto` (il tetto dei significati resta chiuso a 02 §11.5); la ripresa non ne ha uno proprio ma si annuncia a voce. Il vocabolario chiuso non riceve termini nuovi: gli stati usano le chiavi `rifornimento.*` GIÀ riservate, e il termine della sosta resta «in sosta di rifornimento» (scostamento S17). Cinque invarianti nuovi col mutante — `rifornimento_fuori_intervallo`, `marcia_forzata_inattesa`, `sosta_elusa_marciando`, `zona_tagliata`, `taglio_da_casella_non_prescritta` — e il banco genera tagli, soste imposte, soste volontarie, riprese, passaggi in zona e strutture isolate.

### RDA-110 — Gli stati di conoscenza: modello per età, decadimento e osservazione (incide sul gioco; 01 §5.3, §5.6.11, §12)

Il modello. Ogni casella ha, PER PARTE, uno stato di conoscenza del vocabolario chiuso (`StatoConoscenza`: inesplorato, presunto, avvistato coi turni, confermato — 01 §5.3, 02 §4.2, chiavi `conoscenza.*` già riservate). Non è un campo grezzo: si DERIVA dall'ETÀ dell'informazione, cioè i turni trascorsi dall'ultima osservazione (`StatoConoscenza.da(eta:sogliaConfermato:)`). La memoria di conoscenza è per parte (`StatoCampagna.conoscenza: [Parte: [Cella: Int]]`), perché l'agguato dipende dal fatto che una casella non sia confermata PER L'AVVERSARIO (01 §5.11.1) e l'avversario decide sulla propria conoscenza: la simmetria è voluta (01 §5.3). La memoria NON entra nel giornale (si ricostruisce rigiocando, sicché lo schema non sale) ma entra nell'impronta (due partite con ricordi diversi non sono lo stesso stato).

L'osservazione. La conoscenza CORRENTE — ciò che una formazione vede ora entro il raggio di osservazione — si deriva dalle posizioni (`MotoreCampagna.conoscenza`/`osservata`): una casella osservata ora è confermata, quale che sia il ricordo. La memoria conserva solo ciò che NON si osserva più, e invecchia a ogni fine giornata (`invecchiaLaConoscenza`, passo di `risolviFineGiornata`): ogni ricordo sale di un turno, poi le caselle osservate a fine giornata tornano a zero. Il confermato decade in avvistato oltre la soglia (03 §4.8.1). Il raggio di osservazione e la soglia vengono dai dati (`conoscenza-campagna.json`), provvisori.

Il gioco non dichiara il falso (01 §12). La mancanza di conoscenza è inesplorato, non una menzogna; un gruppo appostato non è individuato perché la sua casella non è confermata, non perché si sia mentito (01 §5.11.1). Nell'annuncio la conoscenza è la PRIMA voce dopo la testa fissa, se diversa da confermato (02 §3.8.1), con l'età; il confermato è la condizione ordinaria e tace. «avvistato» porta i turni col plurale di sistema (`.stringsdict`). Due invarianti col mutante: la memoria non retrocede senza il passare del tempo (cambia solo alla chiusura della giornata); nessuna età è negativa (conoscenza dal futuro = il gioco che dichiara il falso). Il `presunto` nasce solo dalla deduzione dell'itinerario (01 §5.10.1) ed è rinviato al blocco della ricognizione: il termine esiste, la sua produzione no.

Ambito. È il PRIMO blocco dell'incarico dell'avversario e della ricognizione: la fondazione su cui poggiano l'avversario (che si vede solo esplorando), l'agguato (casella non confermata per l'avversario) e lo studio approfondito (che porta a confermato). L'osservazione di formazioni AVVERSARIE nascoste, e il loro occultamento sulle caselle non note, sono materia del blocco dell'avversario e non di questo, che non ha ancora nulla di nascosto da mostrare o celare.

### RDA-111 — La condotta dell'avversario di campagna: le valutazioni, il loro ordine, il turno nel giornale (incide sul gioco; 01 §5.6.11, §12.1, §14.3, incarico 18)

Il turno. Dopo che TUTTI i gruppi del giocatore hanno agito, la Sessione «pompa» l'avversario (RDA-41): finché nessun gruppo del giocatore attende e un gruppo avversario sì, la condotta (`CondottaAvversaria`) decide un comando per il gruppo di id minore che attende — l'ordine interno FISSO e deterministico di 01 §5.6.11 — che si appende al giornale come `.comandoCampagna(parte: .avversario, …)` e si applica dallo STESSO percorso del giocatore (`SessioneCampagna.svolgiTurnoAvversario`; RDA-42, nessuna seconda via). L'ultimo comando avversario chiude la giornata, che si risolve e ne apre una nuova; se questa si apre coi soli gruppi del giocatore in marcia lunga, l'avversario torna a muovere (il ciclo termina perché ogni chiusura avanza il giorno). Il banco (`BancoCampagna`) e la ripresa (`init(riprendi:)`) pompano l'avversario dallo stesso codice statico.

Le valutazioni e il loro ordine. Per il gruppo che decide, la condotta assegna a ogni mossa candidata — il presidio e ogni marcia valida verso una casella adiacente — un punteggio intero, somma pesata di tre spinte, e sceglie il punteggio massimo; le parità si rompono a favore del presidio (l'avversario non si muove a vuoto) e, fra marce, per la casella minore nell'ordine di lettura (RDA-07). L'ordine, che il titolare deve poter leggere nel comportamento, è quello dei pesi in diminuzione nei valori di fabbrica: (1) **difesa del proprio quartier generale** quando una formazione nota del giocatore vi è entro la soglia — guadagno pari a quanto la mossa vi si avvicina (peso 600); (2) **minaccia al rifornimento** — un premio se la casella è ALLE SPALLE di una formazione nota, cioè da dove se ne taglia il rifornimento (peso 300); (3) **avanzata** verso il quartier generale del giocatore — guadagno pari a quanto la mossa vi si avvicina, misurato AGGIRANDO le formazioni note (peso 100, l'aggressività). In assenza di guadagno, presidia; un gruppo tenuto fermo dal taglio si ferma con la sosta di raccolta, come il giocatore (nessuna asimmetria).

L'aggiramento (01 §5.13) non è un peso ma un tratto costante dell'avanzata: la distanza-obiettivo si misura con un percorso in ampiezza che tratta le formazioni note come ostacoli (`distanzeAggirando`), sicché una formazione che sbarra la via diretta spinge l'avversario a girarle intorno anziché ammassarvisi. Nessuna estrazione del caso interviene: due partite identiche restano identiche (verificato: `AvversarioCampagnaTest.test_incarico_18_stesso_giornale_stesse_mosse`, `CondottaAvversariaTest.test_01_12_1_la_stessa_vista_produce_lo_stesso_comando`). Il carattere — aggressività, minaccia, difesa, soglia — sta nei dati (`condotta-campagna.json`, provvisori) e non nel codice.

### RDA-112 — La simmetria delle regole fra le parti (incide sul gioco; 01 §5.2.3, §5.9.1.8, incarico 18)

Nessuna regola vale per una parte sola, salvo dove i documenti lo prevedano (i vantaggi nascosti di 01 §13.2 sono di BATTAGLIA e non si replicano in campagna). Due asimmetrie del codice, entrambe residui del periodo senza avversario, sono state tolte. Il **costo della marcia**: `costoInGiorni` leggeva il volume dell'occupante fisso su `.giocatore`; ora riceve la `parte` e legge il volume della colonna che marcia (con la compresenza, 01 §6.1, una casella ospita un gruppo per parte), sicché l'avversario paga il proprio volume. Il **taglio**: `rifornimentoTagliato` confrontava le caselle alle spalle con `stato.forzeNemiche`, insieme fisso ostile al solo giocatore; ora usa `caselleOstili(a:)` — i gruppi della parte opposta più, per il solo giocatore, le forze ferme dello scenario — sicché il rifornimento dell'avversario si taglia mettendosi alle SUE spalle. Due invarianti che presupponevano il giocatore — `due_gruppi_stessa_casella` (ora conta per parte, la compresenza è ammessa) e `taglio_da_casella_non_prescritta` (ora relativo alla parte) — sono stati resi simmetrici; gli altri invarianti di stato già iteravano tutti i gruppi. Il rifornimento dell'avversario si aggiorna con le stesse regole, ma i suoi fatti NON entrano nel registro del giocatore (RDA-115).

### RDA-113 — I gruppi avversari nello scenario, omessi se vuoti (incide sul gioco; 01 §5.6.0, incarico 18)

`ScenarioCampagna` porta `gruppiAvversario`, gemelli di `gruppiGiocatore` ma di parte avversaria; la fabbrica li crea con lo STESSO percorso (stessi rifiuti, stessa derivazione del volume, nomi dalla medesima lista chiusa che non si riusa fra le parti), il giocatore per primo, così che i suoi identificatori restino i più bassi e fissino l'ordine deterministico delle risoluzioni. Quando l'elenco è vuoto la codifica lo OMETTE: gli scenari e i salvataggi scritti prima di questa unità — tutti — restano identici al byte, il campione del giornale non si muove e lo schema resta 4 (`CompatibilitaGiornaleTest` verde). Uno scenario senza gruppi avversari si comporta come prima: nessuno muove dopo il giocatore. Il banco porta lo stesso campo in `campagne.json` per generare partite intere contro l'avversario.

### RDA-114 — Il confine informativo reso impossibile, non sorvegliato (incide sul gioco; 01 §5.11.1, incarico 18)

L'errore più facile — far decidere l'avversario sullo stato reale invece che sulla propria conoscenza — è protetto da un controllo e non da una disciplina. La condotta riceve SOLTANTO una `VistaAvversario`, valore AUTOSUFFICIENTE senza alcun riferimento allo `StatoCampagna`: vi stanno i propri gruppi per intero, la geografia (pubblica), i due quartier generali, e SOLTANTO le caselle in cui l'avversario osserva ORA una formazione del giocatore (conoscenza confermato). Le posizioni del giocatore che l'avversario non osserva non sono nel grafo degli oggetti: la condotta non può accedervi perché non esistono in ciò che riceve. La vista calcola per conto proprio i costi e la validità delle proprie marce, senza toccare lo stato: `costoInGiorni` e `caselleAlleSpalle` sono stati fattorizzati in NUCLEI PURI (statici, funzione della sola geografia e del volume della colonna) che tanto il Motore quanto la vista chiamano, sicché il costo cessa di dipendere dallo stato. L'unico punto in cui lo stato reale si legge è `MotoreCampagna.vistaAvversario`, e solo per calcolare l'insieme osservato. Un invariante col mutante lo sorveglia oltre alla barriera di tipo (`vista_avversaria_rivela_ignoto`: ogni casella nella vista è davvero osservata e ospita un gruppo del giocatore), e una prova differenziale lo mostra: due stati che differiscono solo per una posizione del giocatore NON osservata producono la stessa mossa (`CondottaAvversariaTest.test_01_5_11_1_una_posizione_del_giocatore_non_osservata_non_cambia_la_decisione`).

### RDA-115 — Il confine dell'annullamento con l'avversario, e la proiezione degli eventi per il giocatore (incide sul gioco; 01 §5.6.11, 05 §6.5, incarico 18)

Ciò che il giocatore apprende delle mosse avversarie passa ESCLUSIVAMENTE dai suoi stati di conoscenza e dal registro (01 §5.6.11). Tre difese concorrono. Nel Motore, le risoluzioni di fine giornata annunciano e annotano i fatti di rifornimento del SOLO giocatore (`valutaITagliDiRifornimento`); una marcia avversaria compiutasi diventa un `formazioneAvversariaAvvistata` — il fatto e il luogo, senza nome né volume (02 §6.4.1) — solo dove il giocatore la OSSERVA, valutato sulle posizioni SETTLATE (non a metà del giro, che dipenderebbe dall'ordine degli id: un gruppo del giocatore nato da divisione ha id maggiore dell'avversario). Nella Sessione, `proiettaPerIlGiocatore` è l'ultima difesa: alla Presentazione arrivano solo gli eventi dei gruppi del giocatore, i confini di giornata e gli avvistamenti. Un invariante col mutante sorveglia il registro (`registro_rivela_ignoto`: nessun fatto nuovo su casella non osservata o su gruppo avversario).

Il confine dell'annullamento torna a mordere. Chiusa la giornata con l'avversario che ha agito, l'ordine del giocatore che l'ha chiusa NON è più annullabile: annullarlo dopo che l'avversario ha risposto sarebbe la prova a rovescio, che vanificherebbe l'informazione imperfetta (05 §6.5). Si scrive il marcatore `risoluzioneGiornata` — che sigilla l'ordine — quando la chiusura ha compiuto una marcia OPPURE l'avversario ha agito nella giornata; `ultimoOrdine` trova l'ultimo ordine DEL GIOCATORE saltando i comandi avversari che lo seguono nel giornale. L'annullamento DENTRO il proprio turno resta pieno (00 §13.8). Restringe la deroga RDA-73, che valeva finché l'avversario non esisteva.

### RDA-116 — Le tre categorie di formazione come tipo con valore associato (incide sul gioco; 01 §5.2, §5.4.2, §5.10.2, incarico 19)

Sulla mappa di campagna si muovono tre categorie (01 §5.2): gruppi armati, formazioni di ricognizione (esploratori), formazioni non armate. Sono realizzate come `CategoriaFormazione`, TIPO CON VALORE ASSOCIATO e non etichetta accanto al gruppo: `armato`, `ricognizione(competenza:)`, `nonArmata(carico:, sogliaProtezione:)`. La scelta rende IMPOSSIBILE, non solo sconsigliato, lo stato incoerente — un gruppo armato con un carico da saccheggiare, un esploratore senza competenza — perché non è rappresentabile. La competenza dell'esploratore (01 §5.4.2, personale formato) e il carico con la soglia della non armata (01 §5.10.2) vivono dentro la categoria. `Gruppo.categoria` non muta nella vita del gruppo. La codifica dello scenario (`GruppoIniziale`) e l'impronta OMETTONO la categoria quando è `armato` — la ordinaria — sicché gli scenari e i salvataggi armati scritti prima restano identici al byte (come i gruppi avversari omessi se vuoti, RDA-113); la fabbrica traduce i campi dichiarativi (`categoria`, `competenza`, `carico`, `soglia_protezione`) respingendo ogni combinazione incoerente (`ErroreScenario.datiCategoriaIncoerenti`, `.categoriaIgnota`). La categoria è indipendente dall'archetipo dei reparti — provvisorio, dichiarato in S19: un esploratore può avere qualunque archetipo, la sua natura è la categoria.

### RDA-117 — Il modello deterministico del rischio della ricognizione (incide sul gioco; 01 §5.4, §12, incarico 19)

Esplorare consuma l'azione della giornata e ha un costo soprattutto in RISCHIO: gli esploratori possono perdersi, tornare a mani vuote o farsi notare (01 §5.4). Il rischio è DETERMINISTICO, perché il caso è confinato al proprio perimetro (01 §12): la riuscita discende dalla COMPETENZA degli esploratori e dalle CONDIZIONI, mai da un'estrazione. Le condizioni compongono l'INSIDIOSITÀ della zona: una base, la PROFONDITÀ dell'esploratore nel campo avversario (distanza ortogonale dal proprio quartier generale) e il numero di gruppi armati avversari VICINI. Il MARGINE `competenza − insidiosità`, confrontato con lo zero e con due soglie, dà l'esito in una scala monotòna: `margine ≥ 0` riuscita (le caselle entro il raggio di esplorazione, più ampio dell'osservazione ordinaria, diventano conoscenza fresca); `≥ −sogliaManiVuote` a mani vuote; `≥ −sogliaNotati` notati (la loro casella diventa avvistata PER L'AVVERSARIO); sotto, perduti (la formazione sparisce, personale formato che non si rimpiazza in un turno, 01 §5.4.2). I pesi e le soglie sono nei dati (`ricognizione-campagna.json`, provvisori), mai nel codice (00 §13.1). Gli esploratori NON innescano mai battaglia (01 §5.4.1) e NON sono soggetti al taglio del rifornimento (01 §5.15): il loro costo è il rischio. `esitoEsplorazione`, `RicognizioneImboscateTest` prova i quattro esiti; l'avversario esplora alle stesse condizioni (nessuna asimmetria).

### RDA-118 — La forma dei segni sulla mappa: propria, avversaria e categoria distinte per FORMA (incide sul gioco; 02 §3.8.1, incarico 19, prima correzione del titolare)

Le formazioni avversarie avvistate hanno ora un proprio SEGNO visivo, come i gruppi del giocatore (prima correzione). Il segno non distingue MAI per il solo colore, che sarebbe inutile a chi distingue male i colori: distingue per FORMA. La PARTE si legge dalla forma: una formazione PROPRIA porta al centro della casella l'INIZIALE del nome (una lettera, A–Z); una AVVERSARIA porta nella riga dei segni un «×», mai una lettera. La CATEGORIA si legge da un marcatore, uguale per le due parti: il gruppo armato è la ordinaria e non porta marcatore (né segno né parola nell'annuncio, 02 §8.7); l'esploratore porta «»», la non armata «≈». Ciò che si VEDE e ciò che si SENTE coincidono per costruzione: il segno e l'annuncio discendono dallo STESSO elenco (`VistaCampagna.vociDiCasella`, `.occupanteAvversario(CategoriaAvversariaOsservata)`), sicché una caratteristica aggiunta all'uno e dimenticata nell'altro non compila (RDA-74). L'annuncio dell'occupante avversario nomina la categoria (`categoria.gruppo_armato`/`ricognizione`/`non_armata`, etichette composte dai termini di 01 §5.2, non termini nuovi del vocabolario chiuso — S18/incarico 19), e per la sola non armata STUDIATA a fondo dichiara il carico (01 §5.10.2); mai nome, volume né stato d'azione (02 §6.4.1). `CostruttoreAnnunciCampagna.segno`, `MappaCampagnaAccessibileTest`.

### RDA-119 — Lo scatto delle imboscate dentro la risoluzione di fine giornata (incide sul gioco; 01 §5.11, §5.6.11, incarico 19)

L'imboscata è un ordine di posizione: `ComandoCampagna.imboscata` colloca un gruppo ARMATO in agguato (`Gruppo.ordineImboscata`) nella propria casella. Un gruppo appostato ha CONCLUSO la giornata come uno inchiodato dalla marcia (`haConclusoLaGiornata`), resta lì attraverso le giornate senza babysitting, consuma rifornimenti e non produce nulla (01 §5.11.3); si annuncia «in agguato» (termine chiuso di 02 §4.4.5, già esistente), perché il suo stato non è deducibile dal fatto che sia fermo (02 §6.5.3). Lo SCATTO è un passo della risoluzione di fine giornata (`scattaLeImboscate`, inserito fra l'avanzamento delle marce e i tagli, l'ordine di 01 §5.6.11): scatta SOLO all'INGRESSO di un gruppo armato avversario nella casella appostata — «ingresso» distinto per confronto delle posizioni prima e dopo l'avanzamento delle marce, sicché un armato già presente per compresenza non lo fa scattare, e un esploratore o una non armata che vi entrano nemmeno (gli esploratori non inneschiano battaglia, 01 §5.4.1). Il gioco non dichiara il falso: l'avversario non individua l'appostato perché la casella non è per lui confermata (01 §5.11.1), non perché si menta. Il VANTAGGIO dell'imboscante è materia della BATTAGLIA, che questa sessione non costruisce (01 §9.3.2): lo scatto si registra in `StatoCampagna.imboscateInSospeso` (casella, imboscante, intruso, giorno), che la sessione del passaggio alla battaglia raccoglierà per aprire la battaglia da imboscata con l'ordine dei turni di 01 §9.4.1 e il vantaggio di 01 §9.3.2 — questa la riempie soltanto. L'avversario può a sua volta tendere imboscate e il giocatore vi può cadere (`RicognizioneImboscateTest`), la capacità è simmetrica (validazione party-agnostica); la TATTICA con cui la condotta sceglie di appostarsi è rinviata col carattere. Difetto trovato e corretto: uno stato di soli agguati faceva scorrere le giornate all'infinito (l'agguato non progredisce da sé, a differenza della marcia che si compie), corretto fermando la cascata di `chiudiLaGiornataSeServe` quando tutti i gruppi sono conclusi e nessuno è in marcia.

### RDA-120 — L'uscita degli arrivi dal registro, decisione del titolare (incide sul gioco; 01 §5.17.1, incarico 19, seconda correzione del titolare)

L'ARRIVO di un proprio gruppo a destinazione — il compimento di una marcia lunga — ESCE dal registro degli eventi, per decisione del titolare dopo aver giocato: è un fatto che il giocatore ha deciso e già conosce, mentre il registro serve a recuperare ciò che è accaduto mentre guardava altrove. Contraddice 01 §5.17.1, che elenca «il completamento di una marcia lunga» fra i fatti del registro: prevale la volontà del titolare (i consolidati sono fermi a prima della fase D e si riallineano per scostamenti dichiarati), registrata come scostamento S20. Il fatto `FattoRegistrato.marciaCompiuta` è RIMOSSO; l'ANNUNCIO dell'arrivo resta (`EventoCampagna.marciaCompiuta`, col richiamo tattile del completamento di marcia, 02 §11.7.1) e solo la voce di registro se ne va. Il marcatore `risoluzioneGiornata` (confine dell'annullamento, RDA-115) si scrive comunque quando la chiusura ha compiuto una marcia, sicché il confine regge. Restano nel registro le revoche (eccezione voluta, RDA-104), gli annullamenti, gli avvistamenti, i fatti del rifornimento, e vi ENTRANO i fatti nuovi di questa unità (esploratori perduti e notati, formazione sabotata e studiata, imboscata scattata, direzione di marcia dedotta). Lo schema del giornale di campagna sale da 4 a 5: un giornale 4 rigiocato con queste regole produrrebbe un registro diverso, sicché non si riapre e lo si DICHIARA incompatibile (00 §15.2).

### RDA-121 — La deduzione dell'itinerario e il «presunto» (incide sul gioco; 01 §5.10.1, RDA-110, incarico 19)

Il compito degli esploratori non si limita alle formazioni non armate: osservano i movimenti di tutte (01 §5.10.1). Se una colonna avversaria si è mossa lungo una strada per due caselle consecutive, se ne deduce che segua quella strada «fino alla destinazione o a una ramificazione»: le caselle a valle diventano `presunto` per quella parte, e la deduzione si annota nel registro (`direzioneDedotta`). È la produzione del `presunto` che RDA-110 e 01 §5.10.1 rinviavano esplicitamente a questo blocco (S18): il termine esisteva, la sua sorgente no, ed è la SOLA. La deduzione richiede la memoria per-formazione dell'ultima posizione nota (`StatoCampagna.ultimaPosizioneNota: [Parte: [IdGruppo: Cella]]`), che S18 dichiarava mancante; abilitata SOLO da ciò che un ESPLORATORE della parte osserva (`osservataDaEsploratore`), non da qualunque gruppo. È un passo di fine giornata dentro la conoscenza (`deduciGliItinerari`), simmetrico fra le parti, coi soli fatti del giocatore nel suo registro; le presunzioni si ricalcolano ogni giornata dalle osservazioni fresche. Lo STUDIO APPROFONDITO porta a confermato la conoscenza della formazione studiata quanto a composizione, carico e direzione (01 §5.10.2): la formazione entra fra le `StatoCampagna.studiati` — conoscenza che PERSISTE anche quando esce dall'osservazione — e il carico si rivela nell'annuncio solo di una non armata studiata. La conoscenza può MIGLIORARE fuori dalla chiusura della giornata (esplorazione, studio, notati), ma non REGREDIRE: l'invariante `conoscenza_regredita_senza_tempo` è stato ristretto dalle regressioni soltanto (un'età che cresce, un ricordo che sparisce), non da ogni cambiamento — difetto trovato al banco e corretto.
