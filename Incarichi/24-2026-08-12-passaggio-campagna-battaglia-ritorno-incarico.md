Incarico — Il passaggio dalla campagna alla battaglia e il ritorno
Sessione nuova senza memoria delle precedenti. Archivia questo documento verbatim in Incarichi/ prima di cominciare, verifica che il file esista e non sia vuoto, e aggiorna l'indice.
Prima di cominciare leggi forma-dei-resoconti.md e il resoconto dell'incarico precedente in Incarichi/. Del documento di progetto leggi i punti sull'innesco della battaglia e il blocco della campagna, sullo schieramento, sulla ritirata combattuta, sulla conclusione della battaglia e il ritorno in campagna, sull'imboscata e sul suo vantaggio, e i punti sull'ordine dei turni. Del documento di accessibilità leggi i punti sul comportamento del fuoco quando una battaglia si innesca, sullo schieramento e il deck, e sull'informazione di stato della campagna.
Ramo principale a 7f71e08, allineato con il remoto, collaudo verde, build 25 su TestFlight.
Questa sessione va portata fino al caricamento e non si ferma in mezzo. Fermarsi è ammesso soltanto se la capacità della sessione si sta esaurendo davvero, e va dichiarato con il dato che lo mostra. Non è tua facoltà fermarti per giudizio di opportunità né chiedere conferme: hai piena delega fino al resoconto finale.
Che cosa costruisce questa sessione
Il passaggio dalla campagna alla battaglia e il ritorno. È il pezzo che unisce le due metà del gioco: oggi la battaglia funziona, la campagna funziona, e non esiste alcun modo di passare dall'una all'altra. Quando due gruppi si trovano nella stessa casella non accade nulla, e tutto ciò che la campagna costruisce — imboscate, aggiramenti, tagli di rifornimento, incontri — non porta a niente.
Le regole ci sono già nei documenti e vanno cercate, non inventate
Prima di realizzare alcunché, accerta nei consolidati e riporta con il riferimento puntuale di ciascuna: che cosa innesca una battaglia e che cosa la si può rifiutare o imporre; che cosa accade alla campagna mentre una battaglia è in sospeso; che cosa entra nel deck quando la battaglia si apre; con quali forze si schiera ciascuna parte e quale profondità le compete; chi agisce per primo; che cosa spetta a chi ha teso un'imboscata; come si conclude la battaglia e che cosa accade ai reparti sopravvissuti; che cosa accade al gruppo sconfitto e al gruppo vincitore sulla mappa, comprese le posizioni che occupano al ritorno; che cosa accade ai superstiti e al loro eventuale dirottamento.
Realizza quello che i documenti prescrivono. Dove tacciono davvero, decidi tu, dichiara la decisione con la sua ragione e registrala: non chiedere e non lasciare buchi. Se trovi due prescrizioni che si contraddicono, dichiaralo citando entrambi i punti e scegli quella del documento che prevale secondo la gerarchia, registrando la contraddizione come scostamento.
Non contestare una prescrizione senza averla prima cercata: in questo progetto è già accaduto due volte di correggere a torto qualcosa che i documenti dicevano chiaramente.
I due punti tecnici che vanno fatti con cura
Il primo è il giornale. Battaglia e campagna vivono oggi in slot di partita distinti sul disco, e il giornale è anche il formato di salvataggio. Il passaggio fa toccare le due cose: una battaglia nata da una campagna deve poter essere salvata, ripresa e rigiocata, e il suo esito deve tornare nella campagna che l'ha generata anche dopo un riavvio dell'applicazione. Dichiara come lo hai realizzato e verificalo spegnendo e riaprendo, perché è il momento in cui i difetti di questa specie si manifestano.
Il secondo è il vantaggio dell'imboscante, che una sessione precedente ha registrato nello stato senza costruirlo perché apparteneva alla battaglia. Adesso la battaglia c'è: raccoglilo e realizzalo secondo quanto i documenti prescrivono, e verifica che una battaglia nata da un'imboscata si comporti diversamente da una ordinaria.
Che cosa il giocatore deve sentire e poter fare
La battaglia in sospeso va dichiarata dall'informazione di stato della campagna, con il luogo. Il passaggio alla schermata di battaglia avviene per scelta del giocatore attraverso il comando presente nella casella interessata, e non forzando il cambio di schermata: il fuoco non si sposta mai senza che l'utente lo chieda.
Ogni comando bloccato dalla battaglia in sospeso dichiara il medesimo motivo, così che il giocatore non debba ricostruirlo per tentativi.
Al ritorno in campagna, il giocatore deve sentire che cosa è successo: chi ha vinto, che cosa gli resta, dove si trovano ora le sue forze. Il resoconto di fine battaglia esiste già: verifica che dica ciò che serve a chi torna sulla mappa e non solo a chi ha combattuto.
Non introdurre termini nuovi nel vocabolario chiuso. Se ne servisse uno, dichiaralo e fermati su quel punto, non sull'intera sessione.
Il metodo di verifica
Tutto va verificato giocando sul simulatore, attraverso l'interfaccia, e non soltanto con il programma di verifica interno. La sessione precedente ha accertato che il programma di verifica guarda i propri scenari e non ciò che arriva in mano al giocatore, ed è la ragione per cui tre difetti gravi gli sono sfuggiti.
Realizza quindi una prova d'interfaccia che apra la partita di campagna come la apre il giocatore, porti due gruppi a contatto, apra la battaglia dal comando della casella, la combatta fino alla conclusione, e verifichi sulla schermata vera che le forze tornino in campagna con l'esito giusto. Deve fallire sul codice attuale prima che tu corregga: falla fallire e riporta l'uscita.
Verifica inoltre sul simulatore che lo scenario giocabile permetta effettivamente di arrivare a una battaglia: se le posizioni di partenza o le regole lo rendessero improbabile, dichiaralo e correggi lo scenario, perché una funzione che il giocatore non può raggiungere è una funzione che non esiste.
Il collaudo
Prove del pacchetto sempre. Prove d'interfaccia sul simulatore. Corsa completa delle sessioni perché il caricamento la esige.
Estendi il programma di verifica alle partite che comprendono battaglie nate dalla campagna, con invarianti nuovi ciascuno col proprio mutante: che nessuna forza si perda o si duplichi nel passaggio fra i due piani; che un gruppo annientato sparisca dalla mappa e uno che ripiega sopravviva ridotto; che una battaglia in sospeso blocchi ciò che deve bloccare e nient'altro; che l'esito di una battaglia rigiocata dal giornale sia identico.
Il banco deve generare partite che comprendano battaglie e non soltanto renderle possibili: riporta quante battaglie si producono, con quale esito, e quante nascono da imboscate.
Ogni cancello nuovo va visto fallire una volta di proposito, con l'uscita riportata. I casi nuovi del giornale rispettano la catena dei campioni, committati nella stessa modifica.
Sulla macchina
Il MacBook ha un M5 Pro e ventiquattro gigabyte. Ricorri a sottoagenti in parallelo dove due parti non dipendono l'una dall'altra. Le corse che invocano lo stesso ambiente di compilazione si ostacolano e vanno tenute in sequenza. Le misure di tempo si prendono da sole.
Che cosa non devi fare
Non inventare regole che i documenti già stabiliscono: cercale.
Non dichiarare risolto nulla che tu non abbia visto funzionare su una partita giocata attraverso l'interfaccia del simulatore.
Non forzare il passaggio alla schermata di battaglia: avviene per scelta del giocatore.
Non introdurre estrazioni del caso nella risoluzione della battaglia.
Non toccare il corpo a corpo, le soglie di disingaggio o alcun valore del combattimento, che il titolare ha già accettato.
Non introdurre termini nuovi nel vocabolario chiuso.
Non costruire stagioni, opere, stanchezza, manutenzione, patria, risorse.
Non toccare la versione di marketing, i certificati, i profili o gli identificatori di pacchetto.
Se una prescrizione di questo incarico contraddice un documento consolidato, prevale il consolidato: dichiaralo citando documento e punto.
Il caricamento
Carica la build al termine. Il titolare deve poter giocare per la prima volta una partita intera, dalla mappa alla battaglia e ritorno.
Incrementa la versione dei valori se cambiano regole che incidono sul modo in cui una partita in corso si svolgerebbe, e dichiara la valutazione. Verifica che i salvataggi incompatibili si dichiarino invece di fallire in silenzio. Verifica per interfaccia di programmazione che la build sia valida, sul treno più alto, assegnata al gruppo di test, e che il registro concordi con i server nei due versi.
Nella nota per il titolare, in linguaggio non tecnico e in questo ordine: come si arriva a una battaglia partendo dalla mappa; che cosa deve fare per aprirla; con che cosa combatte; che cosa succede alle sue forze quando finisce, sia vincendo sia perdendo; e che cosa cambia se la battaglia nasce da un'imboscata.
Il versionamento
Ramo dedicato, fusione del solo verde, spinta di principale e del ramo dedicato, cancellazione del ramo fuso. Verifica al termine che principale locale e remoto coincidano, riportando il comando che lo accerta.
Al termine
Registra nel registro delle decisioni la forma del passaggio fra i due piani, il modo in cui i due giornali si toccano, la realizzazione del vantaggio dell'imboscante, e ogni decisione presa dove i documenti tacevano. Registra fra i valori provvisori i numeri introdotti. Registra gli scostamenti nuovi e chiudi quelli superati.
Resoconto in registro tecnico, con nomi reali e comandi. Ogni numero porta lo strumento che lo ha prodotto; nessun numero a mente; i totali pareggiano le righe. Ciò che non hai verificato va dichiarato tale nel punto in cui compare. Elenca ciò che hai fatto senza che fosse chiesto e ciò che era chiesto e non hai fatto.
Metti in testa al resoconto due cose: l'elenco delle regole che hai trovato nei documenti con il loro riferimento, e le frasi vere che il giocatore sentirà quando una battaglia si innesca, quando la apre, e quando torna in campagna a battaglia conclusa.
Archivia il resoconto verbatim in Incarichi/, verifica che il file esista e non sia vuoto, e aggiorna l'indice.
