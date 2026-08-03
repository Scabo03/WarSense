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
