Incarico — L'avversario sulla mappa, la ricognizione e l'informazione incompleta

Ripresa del lavoro sulla campagna. Ramo principale a 7533b62 più i commit del rifornimento, allineato con il remoto, collaudo verde a trecentotré prove del pacchetto e settantatré fra ospitate e d'interfaccia. Build 21 su TestFlight.

Esistono già e non vanno rifatti: mappa nei tre formati, gruppi con composizione e volume, marce di più giorni con revoca, risoluzione di fine giornata come momento ordinato, divisione e riunione, rifornimento con taglio, zone, autonomia e sosta. Il rifornimento è realizzato e provato ma non è mai scattato in partita, perché senza nemici sulla mappa il taglio non può prodursi: questa sessione lo accende.

I vincoli generali del progetto restano quelli degli incarichi precedenti archiviati in Incarichi/: leggili lì invece di ricostruirli.

## Che cosa costruisce questa sessione

Tutto ciò che resta della campagna tranne le stagioni, le opere, la stanchezza, la manutenzione, il passaggio alla battaglia e la patria: l'avversario sulla mappa con le sue mosse, l'informazione incompleta con gli stati di conoscenza, gli esploratori e la ricognizione, le formazioni non armate, il sabotaggio e lo studio approfondito, le imboscate, l'aggiramento.

È molto, e l'ordine interno conta: costruisci per primi gli stati di conoscenza, perché tutto il resto vi si appoggia; poi l'avversario; poi la ricognizione; poi le formazioni non armate con le azioni che le riguardano; poi le imboscate. Se la capacità della sessione non basta, fermati al confine di uno di questi blocchi con la sua prova superata e dichiara da dove si riprende, senza lasciare parti a metà.

## Gli stati di conoscenza

Ogni casella possiede uno stato di conoscenza espresso con il vocabolario chiuso, che esiste già e non va ampliato: inesplorato, presunto, avvistato seguito dal numero di turni trascorsi, confermato. Il vocabolario è fisso e non ammette sinonimi in alcun punto.

Nell'annuncio della casella lo stato di conoscenza viene per primo dopo la testa fissa, se diverso da confermato, con l'età dell'informazione. Entra nell'elenco unico da cui la casella dichiara ciò che dichiara, e non in punti separati.

L'invecchiamento e il decadimento della conoscenza sono uno dei passi della risoluzione di fine giornata, che già esiste come momento ordinato: aggiungivi il passo senza toccare gli altri.

Il gioco non dichiara mai il falso. Un gruppo appostato non è individuato perché la sua casella non è confermata, non perché il gioco abbia mentito sul suo stato: il vocabolario resta integralmente veritiero e la sua affidabilità non ammette eccezioni.

La posizione del quartier generale avversario è nota fin dall'inizio ed è geografia dichiarata dalla mappa: non passa dagli stati di conoscenza.

## L'avversario

Le sue scelte discendono da propensioni e valutazioni ed è interamente deterministico: nessuna estrazione del caso interviene, e le parità si risolvono per criteri d'ordine fissi sugli identificatori. Due partite identiche restano identiche. Competente qui significa che valuta bene, non che sia imprevedibile: un comportamento coerente si può imparare ed è un pregio dichiarato del progetto.

I gruppi avversari agiscono dopo che tutti i gruppi del giocatore hanno agito, in un ordine interno fisso e deterministico, e la giornata si chiude da sé con le risoluzioni di fine giornata. Ciò che il giocatore apprende delle mosse avversarie passa esclusivamente dagli stati di conoscenza e dal registro: l'ordine interno di risoluzione non gli comunica nulla che la ricognizione non gli abbia dato.

L'avversario dispone delle stesse azioni del giocatore e delle stesse regole: marcia con lo stesso costo in giorni, presidio, divisione e riunione, rifornimento con lo stesso taglio, imboscata. Verifica esplicitamente che nessuna regola sia applicata a una parte sola, e dichiara ogni asimmetria che trovi o che introduci.

L'avversario è già predisposto come sorgente di comandi che si appendono al giornale: rispetta quella forma e non costruirne una seconda.

Fallo giocare con un carattere, cioè con parametri che ne determinino l'aggressività e la propensione a cercare lo scontro, collocati nei file di dati con il contrassegno di provvisorietà. Il carattere degli ufficiali determina la frequenza effettiva degli scontri ed è una delle grandezze da tarare con le simulazioni: introducilo come parametro e non come comportamento scritto nel codice.

Dichiara con precisione quali valutazioni compie e in quale ordine, perché il titolare deve poter capire che cosa l'avversario stia cercando di fare quando lo vedrà giocare.

## La ricognizione

Le formazioni di ricognizione sono una delle tre categorie che si muovono sulla mappa. Esplorare consuma risorse quel tanto che basta perché non sia gratuito, e il costo è soprattutto in rischio: gli esploratori possono perdersi, tornare a mani vuote o farsi notare dall'avversario. Il rischio va realizzato deterministicamente, perché il caso resta confinato al proprio perimetro.

Gli esploratori non innescano mai una battaglia: ciò che accade loro si risolve interamente sulla mappa. Hanno qualità e competenza differenziate, e il personale formato che si perde non si rimpiazza in un turno. Non sono soggetti al taglio del rifornimento.

Osservano i movimenti di tutte le formazioni, non solo di quelle non armate. Se rilevano che una colonna avversaria si è mossa lungo una strada per due caselle consecutive, se ne deduce che stia seguendo quella strada fino alla destinazione o a una ramificazione: realizza questa deduzione come informazione che il giocatore riceve.

## Le formazioni non armate e le azioni che le riguardano

Le formazioni non armate, cioè catene di approvvigionamento e simili, sono la terza categoria e vanno realizzate.

Quando una formazione di ricognizione o un gruppo armato raggiunge la casella di una formazione non armata avversaria non si apre alcuna battaglia. Sono possibili due azioni, entrambe deterministiche ed entrambe già chiuse nei documenti.

Il sabotaggio consuma l'azione della giornata e disperde la formazione bersaglio, il cui carico è perduto. Compiuto da un gruppo armato riesce sempre; compiuto da esploratori riesce soltanto se la loro competenza raggiunge la soglia di protezione dichiarata della formazione bersaglio, altrimenti fallisce e gli esploratori si fanno notare, cioè la loro casella diventa avvistata per l'avversario.

Lo studio approfondito è riservato alle formazioni di ricognizione, consuma l'azione e porta a confermato lo stato di conoscenza della formazione studiata: composizione, carico e direzione di marcia.

## Le imboscate e l'aggiramento

L'imboscata è un'azione di posizione: su qualunque casella il giocatore può collocare un proprio gruppo armato con l'ordine di imboscata, e se un gruppo armato avversario entra in quella casella l'imboscata scatta. Lo scatto delle imboscate è uno dei passi della risoluzione di fine giornata: aggiungivelo.

L'imboscata non richiede alcuna menzogna del gioco: l'avversario non individua il gruppo appostato perché quella casella non è per lui confermata. Ha un costo proprio, perché un gruppo appostato è fermo, consuma rifornimenti e non produce nulla, e se l'avversario cambia itinerario i turni sono perduti.

Il vantaggio dell'imboscante è materia della battaglia, che questa sessione non costruisce: realizza lo scatto e la registrazione del vantaggio, e dichiara come la sessione che costruirà il passaggio alla battaglia lo raccoglierà, senza costruirlo.

Un gruppo in attesa con ordine di imboscata si annuncia come tale, perché il suo stato non è deducibile dal fatto che sia fermo. Il termine esiste già nel vocabolario.

L'aggiramento va realizzato: due formazioni possono sfilarsi in caselle adiacenti senza ingaggiarsi, e una colonna avversaria può oltrepassare l'esercito del giocatore e puntare su un obiettivo sguarnito. È un comportamento voluto e non un difetto da correggere.

## Che cosa il giocatore sente

Non introdurre termini nuovi nel vocabolario chiuso: quelli degli stati di conoscenza e dell'agguato esistono già. Se ne servisse uno nuovo, dichiaralo e fermati.

I fatti che il giocatore non ha deciso entrano ora in quantità nel registro degli eventi: mosse avversarie avvistate, rifornimento interrotto, imboscata scattata, esploratori perduti o notati, formazione sabotata. Ciascuna voce dichiara il giorno e, se ha un luogo, è attivabile e porta il fuoco lì.

Realizza i rotori della mappa già previsti e oggi mancanti: le formazioni avversarie note, le caselle da cui è possibile esplorare, le informazioni di ricognizione scadute. Verifica che i rotori esistenti reggano con formazioni che compaiono e spariscono dalla conoscenza.

Completa l'informazione di stato della campagna per le voci che questa sessione rende esistenti, rispettando il formato chiuso, l'ordine fisso e i tagli di verbosità dalla coda.

Attenzione a un punto di parità: le mosse avversarie che il giocatore apprende vanno annunciate. Un ingresso in campo mai annunciato è già stato uno dei difetti gravi di questo progetto, sul campo di battaglia, ed è la stessa classe di errore.

## Il collaudo, tarato su questa sessione

Le prove del pacchetto girano sempre. Le prove d'interfaccia sul simulatore servono, perché cambiano annunci, stato, rotori e registro: falle una volta alla fine.

La corsa completa delle sessioni va eseguita, perché il caricamento la esige e il suo cancello prevale su qualunque prescrizione di questo incarico: l'incarico precedente aveva chiesto di ometterla e la sessione ha giustamente obiettato.

Estendi il programma di verifica, con invarianti nuovi ciascuno col proprio mutante: che nessuna informazione avversaria raggiunga il giocatore se non attraverso gli stati di conoscenza; che l'avversario non violi alcuna regola che vincola il giocatore; che uno stato di conoscenza non retroceda mai da confermato senza il passare del tempo; che un'imboscata scatti soltanto all'ingresso di un gruppo armato; che gli esploratori non inneschino mai una battaglia; che il gioco non dichiari mai il falso su uno stato di conoscenza.

Il banco deve generare partite intere contro l'avversario, con tagli di rifornimento realmente prodotti dalle sue mosse, imboscate scattate, esploratori perduti e formazioni sabotate: non basta renderli possibili. Riporta con quale frequenza ciascun fenomeno si produce, perché è il primo dato che dice se l'avversario giochi davvero.

Ogni cancello nuovo va visto fallire una volta di proposito, con l'uscita riportata. I casi nuovi del giornale rispettano la catena dei campioni, committati nella stessa modifica.

## Sulla macchina

Il MacBook ha un M5 Pro e ventiquattro gigabyte: usalo per intero. È una sessione grande, e il parallelismo qui serve davvero. Ricorri a sottoagenti in parallelo dove due parti non dipendono l'una dall'altra, e a più simulatori in parallelo se servono corse indipendenti; se non puoi tenerne due identici, usa un telefono e una tavoletta. È un invito e non un obbligo, e vale per il lavoro, non per le misure di tempo, che si prendono sempre da sole.

## Che cosa non devi fare

Non costruire le stagioni, le opere, la stanchezza, la manutenzione, il passaggio dalla campagna alla battaglia, la patria. Di ciascuna realizza soltanto il minimo indispensabile a rendere provabile ciò che costruisci, dichiarandolo come tale.

Non introdurre alcuna estrazione del caso nelle scelte dell'avversario né nella ricognizione.

Non far conoscere al giocatore alcunché delle mosse avversarie per una via diversa dagli stati di conoscenza e dal registro.

Non far dichiarare al gioco alcunché di falso, in nessuna circostanza.

Non introdurre termini nuovi nel vocabolario chiuso.

Non applicare all'avversario regole diverse da quelle del giocatore, salvo dove i documenti lo prevedano espressamente, e in tal caso dichiaralo.

Non toccare la versione di marketing, i certificati, i profili o gli identificatori di pacchetto.

Se una prescrizione di questo incarico contraddice un documento consolidato, prevale il consolidato: dichiaralo citando documento e punto. Se un rimando è irrisolvibile o una condizione ammette più letture, segnalalo prima di cominciare e non dopo aver scelto in silenzio.

## Il caricamento

Carica la build al termine, anche se ti fermi al confine di un blocco, purché quel blocco sia chiuso e verde e renda giocabile qualcosa di nuovo: il titolare deve poter giocare contro qualcuno, ed è la cosa che aspetta da tutta la campagna.

Incrementa la versione dei valori e dichiara la valutazione. Verifica che i salvataggi incompatibili si dichiarino invece di fallire in silenzio. Verifica per interfaccia di programmazione che la build sia valida, sul treno più alto, assegnata al gruppo di test, e che il registro concordi con i server nei due versi.

Nella nota per il titolare, in linguaggio non tecnico: che ora c'è un avversario che si muove e che non si vede se non esplorando; che cosa fare per scoprirlo; che il rifornimento può ora essere interrotto davvero e che cosa si sente quando accade; e come si tende un'imboscata.

## Il versionamento

Ramo dedicato, fusione del solo verde, spinta sempre di principale e del ramo dedicato, rami fusi cancellati. Verifica al termine che principale locale e remoto coincidano, col comando che lo accerta.

## Al termine

Registra nel registro delle decisioni: la forma della condotta avversaria con le valutazioni che compie e il loro ordine; la realizzazione degli stati di conoscenza e del loro decadimento; il modello del rischio della ricognizione senza caso; lo scatto delle imboscate dentro la risoluzione di fine giornata. Registra fra i valori provvisori tutti i numeri introdotti, il carattere dell'avversario compreso. Registra gli scostamenti nuovi e chiudi quelli superati.

Resoconto in registro tecnico, con nomi reali e senza semplificazioni. Ogni numero porta lo strumento che lo ha prodotto; nessun numero a mente; i totali pareggiano le righe. Ciò che non hai verificato va dichiarato tale nel punto in cui compare. Elenca ciò che hai fatto senza che fosse chiesto e ciò che era chiesto e non hai fatto.

Riporta in coda quanto è durata ciascuna parte del lavoro e quanto tempo è andato in compilazioni, corse del collaudo, corse del simulatore e caricamento.

Metti in testa al resoconto due cose: le frasi vere che il giocatore sentirà scoprendo una formazione avversaria, subendo un taglio di rifornimento e vedendo scattare una propria imboscata; e la descrizione in parole di che cosa l'avversario cerca di fare, perché il titolare deve poterlo riconoscere giocando.

Archivia il resoconto verbatim in Incarichi/, verifica che il file esista e non sia vuoto, e aggiorna l'indice.

---

Nota d'archivio. Questo incarico è grande e a più blocchi; la prima sessione (2026-08-08) ha realizzato il solo blocco 1 (gli stati di conoscenza) e si è fermata al suo confine, come l'incarico consente, senza caricare (blocco non giocabile da solo). Il resoconto compagno documenta il blocco 1 e la traccia per i blocchi 2–5; le sessioni successive lo completano.
