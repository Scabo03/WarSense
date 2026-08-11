Incarico — Gli esploratori non esistono in partita, il nemico non si incontra, e il segno del nemico sulla mappa
Sessione nuova senza memoria delle precedenti. Archivia questo documento verbatim in Incarichi/ prima di cominciare, verifica che il file esista e non sia vuoto, e aggiorna l'indice.
Prima di cominciare leggi soltanto forma-dei-resoconti.md e i resoconti degli incarichi 19, 21 e 22 in Incarichi/. Non aprire altra documentazione se non ti serve per un punto specifico.
Ramo principale a 27fe8b9, allineato con il remoto, collaudo verde, build 24 su TestFlight.
Questa sessione va portata fino al caricamento e non si ferma in mezzo. Fermarsi è ammesso soltanto se la capacità della sessione si sta esaurendo davvero, e va dichiarato con il dato che lo mostra. Non è tua facoltà fermarti per giudizio di opportunità né chiedere conferme: hai piena delega fino al resoconto finale.
Il fatto da cui questa sessione parte
Il titolare ha giocato la build 24 sul dispositivo e riferisce quanto segue. Sono osservazioni di partite reali e vanno trattate come dati, non come impressioni da verificare con gli strumenti che non hanno visto il problema.
Primo. Fra i gruppi schierati all'avvio non ce n'è alcuno che si dichiari di ricognizione, e le azioni offerte nel pannello sono identiche per tutti i gruppi, senza alcuna voce propria degli esploratori. Se esista un modo di schierarne altri, non è comprensibile.
Secondo. Anche sulla mappa da quattro per quattro, cioè sedici caselle, non ha mai avvistato una sola formazione avversaria, in nessuna partita.
Terzo. La composizione dei propri gruppi viene annunciata e funziona.
Che cosa questo significa, e come devi procedere
La ricognizione è stata costruita nel Motore in una sessione precedente e provata lì, ma con ogni probabilità non esiste nella partita che il giocatore gioca, perché lo scenario non contiene formazioni di ricognizione e il pannello non offre le loro azioni. Due build di fila non hanno dato al titolare nulla da provare per questa ragione.
Il secondo punto non è taratura. Con raggio di osservazione due su una mappa di sedici caselle il giocatore osserva più di metà della mappa muovendo un solo gruppo, e non incontrare mai nessuno in nessuna partita è un difetto. La diagnosi della sessione precedente, che attribuiva tutto al raggio, era incompleta o sbagliata: verificala di nuovo senza darla per buona.
Il metodo di verifica, che è il punto centrale di questo incarico
Tutto ciò che questa sessione accerta e corregge va verificato giocando una partita vera sul simulatore, attraverso l'interfaccia, e non soltanto con il programma di verifica interno.
La ragione è documentata: il programma di verifica genera i propri scenari e non guarda ciò che arriva in mano al giocatore, e per questo non ha visto nessuno dei tre difetti riferiti. Le prove che stanno al livello in cui i difetti si manifestano sono quelle che passano per l'interfaccia.
Realizza quindi una prova d'interfaccia che apra una partita di campagna come la apre il giocatore, percorra la mappa, e accerti sulla schermata vera: che esistano formazioni di ricognizione fra quelle del giocatore; che il pannello di una formazione di ricognizione offra le azioni proprie della ricognizione e quello di un gruppo armato no; che nel corso della partita il giocatore avvisti almeno una formazione avversaria; e che una casella con una formazione avversaria avvistata porti il proprio segno. Questa prova deve fallire sul codice attuale prima che tu corregga alcunché: falla fallire e riporta l'uscita.
Che cosa devi ottenere
Primo. Che lo scenario di partenza della campagna contenga, per entrambe le parti, gruppi armati, formazioni di ricognizione e formazioni non armate. Le tre categorie esistono nel Motore e devono esistere in campo. Dichiara quante ne hai messe per parte e su quale criterio.
Secondo. Che ciascuna categoria offra nel proprio pannello le azioni che le competono e non quelle delle altre. Le formazioni di ricognizione offrono l'esplorazione e lo studio approfondito; i gruppi armati offrono l'imboscata, il sabotaggio e le altre azioni armate; le formazioni non armate offrono ciò che loro compete. Un'azione impossibile non si offre: è regola già in vigore e vale qui.
Ogni formazione dichiara la propria categoria quando il giocatore la incontra, prima della composizione, in modo che si capisca a colpo d'ascolto se si tratti di un gruppo armato, di esploratori o di una formazione non armata.
Terzo. Che l'esplorazione, ordinata dal giocatore attraverso l'interfaccia, produca un effetto che il giocatore sente: che cosa è stato scoperto, oppure che gli esploratori sono tornati a mani vuote, si sono fatti notare o si sono perduti. Verifica sul simulatore che l'ordine sia raggiungibile, che si possa impartire e che l'esito sia annunciato.
Quarto. Che il giocatore incontri l'avversario. Accerta perché su una mappa da sedici caselle non lo incontri mai, riportando con i numeri dove sta la causa: se le formazioni avversarie esistano nello scenario, dove si trovino all'avvio, se si muovano, se l'osservazione le rilevi, e se l'annuncio le dichiari. Il difetto può stare in uno qualunque di questi punti e vanno verificati uno per uno, non presunti. Distingui i tre esiti possibili: che il codice sia difettoso, che sia la taratura, o che l'ipotesi di questo incarico sia sbagliata.
Correggi ciò che l'accertamento mostra rotto, nella stessa sessione. Se risultasse taratura anche stavolta, non accettarlo senza prova: mostra con una partita giocata sul simulatore che l'avvistamento avviene.
Quinto. Il segno del nemico sulla mappa. Una casella con una formazione avversaria avvistata deve essere riempita interamente di arancione, esattamente come la casella di un proprio gruppo armato è riempita di blu: stessa caratterizzazione visiva, stessa estensione, cambia il colore.
Poiché il colore non può portare informazione da solo, il segno di forma già introdotto resta e continua a distinguere le categorie: il riempimento arancione dice che è nemico, la forma dice che cosa è. Verifica che le due cose convivano e che ciò che si vede coincida con ciò che l'annuncio dichiara.
Il collaudo
Prove del pacchetto sempre. Prove d'interfaccia sul simulatore, comprese quelle nuove descritte sopra. Corsa completa delle sessioni perché il caricamento la esige.
Aggiungi al programma di verifica un invariante, con il proprio mutante, che pretenda che lo scenario iniziale contenga tutte e tre le categorie per entrambe le parti. È il difetto che ha reso inutili due build e va reso impossibile da ripetere.
Ogni cancello nuovo va visto fallire una volta di proposito, con l'uscita riportata.
Sulla macchina
Il MacBook ha un M5 Pro e ventiquattro gigabyte. Ricorri a sottoagenti in parallelo dove due parti non dipendono l'una dall'altra. Due corse sullo stesso apparecchio simulato si ostacolano: se ne usi due, devono essere apparecchi diversi. Le misure di tempo si prendono da sole.
Che cosa non devi fare
Non dichiarare risolto nulla che tu non abbia visto funzionare su una partita giocata attraverso l'interfaccia del simulatore.
Non aggiungere un'altra voce all'annuncio al posto di far esistere la cosa: il titolare non ha bisogno di sapere che gli esploratori esistono nel codice, ha bisogno di averli in campo.
Non rendere l'informazione completa: la ricognizione resta il modo di sapere.
Non introdurre estrazioni del caso.
Non distinguere le categorie per il solo colore.
Non introdurre termini nuovi nel vocabolario chiuso: se ne servisse uno, dichiaralo e fermati su quel punto.
Non costruire stagioni, opere, stanchezza, manutenzione, passaggio alla battaglia, patria, risorse.
Non toccare la versione di marketing, i certificati, i profili o gli identificatori di pacchetto.
Se una prescrizione di questo incarico contraddice un documento consolidato, prevale il consolidato: dichiaralo citando documento e punto.
Il caricamento
Carica la build al termine.
Valuta la versione dei valori e dichiara la valutazione. Verifica per interfaccia di programmazione che la build sia valida, sul treno più alto, assegnata al gruppo di test, e che il registro concordi con i server nei due versi.
Nella nota per il titolare, in linguaggio non tecnico e in questo ordine: quali gruppi ha in campo all'avvio e come riconosce gli esploratori; che cosa può ordinare loro, dove trova l'ordine, e che cosa succede quando lo dà; che cosa fare per incontrare l'avversario; e che il nemico avvistato riempie la propria casella di arancione.
Il versionamento
Ramo dedicato, fusione del solo verde, spinta di principale e del ramo dedicato, cancellazione del ramo fuso. Verifica al termine che principale locale e remoto coincidano, riportando il comando che lo accerta.
Al termine
Registra nel registro delle decisioni ciò che hai accertato e corretto, e la composizione dello scenario iniziale con il criterio adottato. Registra fra i valori provvisori i numeri cambiati con quelli di prima. Registra gli scostamenti nuovi.
Resoconto in registro tecnico, con nomi reali e comandi. Ogni numero porta lo strumento che lo ha prodotto; nessun numero a mente; i totali pareggiano le righe. Ciò che non hai verificato va dichiarato tale nel punto in cui compare. Elenca ciò che hai fatto senza che fosse chiesto e ciò che era chiesto e non hai fatto.
Metti in testa al resoconto tre cose: la causa vera per cui il giocatore non incontrava l'avversario; che cosa contiene ora lo scenario iniziale; e le frasi vere che il giocatore sentirà incontrando un proprio gruppo di ricognizione, ordinando un'esplorazione e avvistando una formazione avversaria.
Archivia il resoconto verbatim in Incarichi/, verifica che il file esista e non sia vuoto, e aggiorna l'indice.
