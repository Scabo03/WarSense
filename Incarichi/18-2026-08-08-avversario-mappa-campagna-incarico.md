Incarico — L'avversario che si muove sulla mappa di campagna
Sessione nuova senza memoria delle precedenti. Questo documento contiene quanto serve. Archivialo verbatim in Incarichi/ prima di cominciare, verifica che il file esista e non sia vuoto, e aggiorna l'indice.
Prima di cominciare leggi soltanto: forma-dei-resoconti.md, che è il file di memoria permanente; il resoconto dell'incarico 17 in Incarichi/, che descrive la predisposizione già trovata e la traccia per questo lavoro; i punti del documento di progetto sull'ordine di risoluzione della giornata, sull'avversario, sull'informazione incompleta e sull'aggiramento; il registro delle decisioni architetturali limitatamente alle voci sull'avversario deterministico, sui comandi che si appendono al giornale e sugli stati di conoscenza. Non aprire la documentazione di materie che questa sessione non tocca.
Il progetto in breve
WarSense è un gioco gestionale e strategico militare a turni per iOS e iPadOS, interamente utilizzabile senza vedere lo schermo tramite VoiceOver. La carta dei principi prevale su tutto e al suo interno prevale il numero più basso: il principio 1, cioè la parità di accesso per chi non vede, prevale su qualunque altra considerazione. I consolidati sono fermi a prima della fase D e il riallineamento avverrà in una sessione dedicata: le modifiche si registrano intanto come scostamenti dichiarati.
Ramo principale allineato con il remoto, collaudo verde a trecentosette prove del pacchetto e settantatré fra ospitate e d'interfaccia. Build 21 su TestFlight.
Della campagna esistono: mappa nei tre formati con terreno, strade, strettoia e quartier generale; gruppi con composizione e volume; marce di più giorni con costo pesato e revoca; risoluzione di fine giornata come momento ordinato; divisione e riunione; rifornimento con taglio, zone, autonomia e sosta; stati di conoscenza con invecchiamento. Il rifornimento non è mai scattato in partita perché senza nemici il taglio non può prodursi.
L'unico oggetto di questa sessione
L'avversario che si muove sulla mappa. Nient'altro.
Non costruire la ricognizione, gli esploratori, le formazioni non armate, il sabotaggio, lo studio approfondito, le imboscate, le stagioni, le opere, la stanchezza, la manutenzione, il passaggio dalla campagna alla battaglia, la patria. Di ciascuna realizza solo il minimo indispensabile a rendere provabile l'avversario, dichiarandolo come tale.
Questa sessione va portata fino in fondo. Fermarsi prima è ammesso soltanto se la capacità della sessione si sta esaurendo davvero, e in quel caso va dichiarato con il dato che lo mostra, non con una valutazione di opportunità. Non è tua facoltà decidere che consegnare una parte pulita valga più di consegnare il lavoro: quella scelta appartiene al titolare, che l'ha già fatta chiedendo questo blocco intero. Se ti fermi senza che il contesto sia esaurito, hai disatteso l'incarico.
Che cosa deve fare l'avversario
Muove i propri gruppi sulla mappa dopo che tutti i gruppi del giocatore hanno agito, in un ordine interno fisso e deterministico. Poi la giornata si chiude da sé con le risoluzioni di fine giornata, che già esistono come momento ordinato.
Dispone delle stesse azioni e delle stesse regole del giocatore: marcia con lo stesso costo in giorni, marce di più giorni, revoca, presidio, divisione e riunione, rifornimento con lo stesso taglio. Verifica esplicitamente che nessuna regola sia applicata a una parte sola e dichiara ogni asimmetria che trovi o che introduca.
Le sue scelte discendono da propensioni e valutazioni ed è interamente deterministico: nessuna estrazione del caso interviene, e le parità si risolvono per criteri d'ordine fissi sugli identificatori. Due partite identiche restano identiche. Competente significa che valuta bene, non che sia imprevedibile: un comportamento coerente si può imparare ed è un pregio dichiarato del progetto.
Deve giocare in modo riconoscibile: cercare lo scontro quando gli conviene, evitarlo quando non gli conviene, minacciare il rifornimento del giocatore mettendosi alle sue spalle, difendere il proprio quartier generale, e sfruttare l'aggiramento, cioè oltrepassare le forze del giocatore per puntare a un obiettivo sguarnito, che è comportamento voluto e non difetto.
Dichiara con precisione quali valutazioni compie e in quale ordine, perché il titolare deve poter capire che cosa l'avversario stia cercando di fare quando lo vedrà giocare.
Il suo carattere, cioè l'aggressività e la propensione a cercare lo scontro, sta nei file di dati con il contrassegno di provvisorietà e non nel codice. È una delle grandezze da tarare con le simulazioni.
L'avversario ha informazione incompleta come il giocatore
Non deve conoscere ciò che la propria ricognizione non gli ha dato. Gli stati di conoscenza sono già memorizzati per parte proprio per questo: l'avversario decide sulla propria memoria e non sullo stato reale della mappa.
È il punto più facile da sbagliare e va protetto da un controllo e non da una disciplina: fa' in modo che il codice della condotta avversaria non possa accedere allo stato reale delle posizioni del giocatore, e dichiara come lo hai reso impossibile. Un invariante che si limiti a osservare non basta.
Che cosa il giocatore apprende
Esclusivamente attraverso i propri stati di conoscenza e il registro degli eventi. L'ordine interno di risoluzione non comunica nulla che la ricognizione non abbia dato.
Le mosse avversarie che il giocatore apprende vanno annunciate. Un ingresso in campo mai annunciato è già stato uno dei difetti gravi di questo progetto sul campo di battaglia, ed è la stessa classe di errore.
Le voci del registro che riguardano un luogo sono attivabili e portano il fuoco lì.
Realizza il rotore delle formazioni avversarie note, già previsto nell'elenco stabilito dei rotori della mappa. Completa l'informazione di stato della campagna per le voci che questa sessione rende esistenti, rispettando il formato chiuso, l'ordine fisso e i tagli di verbosità dalla coda.
Non introdurre termini nuovi nel vocabolario chiuso: quelli che servono esistono già. Se ne servisse uno, dichiaralo e fermati su quel punto, non sull'intera sessione.
Il giornale e i salvataggi
I comandi dell'avversario si appendono al giornale esistente, e la catena dal comando alla riproduzione è già distinta per parte: l'avversario passa dalla stessa via del giocatore e non da una seconda forma. È il punto più delicato della sessione e va fatto con cura, non di fretta.
I casi nuovi rispettano la catena dei campioni, committati nella stessa modifica che li introduce. Verifica che una partita salvata e ripresa dia lo stesso stato, e che una partita rigiocata dal solo giornale produca le stesse mosse avversarie.
Il collaudo
Le prove del pacchetto girano sempre. Le prove d'interfaccia sul simulatore servono, perché cambiano annunci, registro, stato e rotori: falle una volta alla fine. La corsa completa delle sessioni va eseguita perché il cancello del caricamento la esige.
Estendi il programma di verifica con invarianti nuovi, ciascuno col proprio mutante: che l'avversario non violi alcuna regola che vincola il giocatore; che nessuna informazione raggiunga il giocatore se non attraverso i suoi stati di conoscenza; che l'avversario non decida su informazione che non possiede; che due partite con lo stesso giornale producano le stesse mosse.
Il banco deve generare partite intere contro l'avversario, e riporta con quale frequenza si producono i fenomeni che contano: tagli di rifornimento realmente causati dalle sue mosse, aggiramenti, avvicinamenti al quartier generale del giocatore. È il primo dato che dice se giochi davvero contro qualcuno.
Ogni cancello nuovo va visto fallire una volta di proposito, con l'uscita riportata.
Sulla macchina
Il MacBook ha un M5 Pro e ventiquattro gigabyte: usalo per intero. Ricorri a sottoagenti in parallelo dove due parti non dipendono l'una dall'altra, e a più simulatori in parallelo se servono corse indipendenti; se non puoi tenerne due identici, usa un telefono e una tavoletta. È un invito e non un obbligo, e vale per il lavoro, non per le misure di tempo, che si prendono da sole.
Che cosa non devi fare
Non introdurre alcuna estrazione del caso nelle scelte dell'avversario.
Non far decidere l'avversario su informazione che non possiede.
Non far conoscere al giocatore alcunché per una via diversa dagli stati di conoscenza e dal registro.
Non far dichiarare al gioco alcunché di falso, in nessuna circostanza.
Non applicare all'avversario regole diverse da quelle del giocatore, salvo dove i documenti lo prevedano espressamente, e in tal caso dichiaralo.
Non costruire una seconda via per i comandi avversari.
Non introdurre termini nuovi nel vocabolario chiuso.
Non toccare la versione di marketing, i certificati, i profili o gli identificatori di pacchetto.
Se una prescrizione di questo incarico contraddice un documento consolidato, prevale il consolidato: dichiaralo citando documento e punto. Se un rimando è irrisolvibile o una condizione ammette più letture, segnalalo prima di cominciare e non dopo aver scelto in silenzio.
Il caricamento
Carica la build al termine. Il titolare deve giocare contro qualcuno, ed è la cosa che aspetta da tutta la campagna.
Incrementa la versione dei valori e dichiara la valutazione. Verifica che i salvataggi incompatibili si dichiarino invece di fallire in silenzio. Verifica per interfaccia di programmazione che la build sia valida, sul treno più alto, assegnata al gruppo di test, e che il registro concordi con i server nei due versi.
Nella nota per il titolare, in linguaggio non tecnico: che ora c'è un avversario che si muove; che non lo si vede se non si va a guardare dove si trova; che può interrompere il rifornimento mettendosi alle spalle di un gruppo, e che cosa si sente quando accade; e che può oltrepassare le proprie forze per andare altrove.
Il versionamento
Ramo dedicato, fusione del solo verde, spinta sempre di principale e del ramo dedicato, rami fusi cancellati. Verifica al termine che principale locale e remoto coincidano, col comando che lo accerta.
Al termine
Registra nel registro delle decisioni la forma della condotta avversaria con le valutazioni che compie e il loro ordine, e il modo in cui è resa impossibile la decisione su informazione non posseduta. Registra fra i valori provvisori il carattere dell'avversario e ogni altro numero introdotto. Registra gli scostamenti nuovi e chiudi quelli superati.
Resoconto in registro tecnico, con nomi reali e senza semplificazioni. Ogni numero porta lo strumento che lo ha prodotto; nessun numero a mente; i totali pareggiano le righe. Ciò che non hai verificato va dichiarato tale nel punto in cui compare. Elenca ciò che hai fatto senza che fosse chiesto e ciò che era chiesto e non hai fatto.
Riporta in coda quanto è durata ciascuna parte del lavoro e quanto tempo è andato in compilazioni, corse del collaudo, corse del simulatore e caricamento.
Metti in testa al resoconto due cose: le frasi vere che il giocatore sentirà scoprendo una formazione avversaria e subendo un taglio di rifornimento; e la descrizione in parole di che cosa l'avversario cerca di fare, perché il titolare deve poterlo riconoscere giocando.
Archivia il resoconto verbatim in Incarichi/, verifica che il file esista e non sia vuoto, e aggiorna l'indice.
