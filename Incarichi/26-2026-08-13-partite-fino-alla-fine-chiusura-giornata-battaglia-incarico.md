Incarico — Le partite devono arrivare alla fine: prova che le gioca, tasto di chiusura della giornata, battaglia che non si conclude
Sessione nuova senza memoria delle precedenti. Archivia questo documento verbatim in Incarichi/ prima di cominciare, verifica che il file esista e non sia vuoto, e aggiorna l'indice.
Prima di cominciare leggi forma-dei-resoconti.md e i resoconti degli incarichi 24 e 25 in Incarichi/. Del documento di progetto leggi i punti sulla chiusura automatica del turno, sul perimetro della giornata e sulla conclusione della battaglia. Non aprire altro se non ti serve per un punto specifico.
Ramo principale a f7b2941, allineato con il remoto, build 27 su TestFlight.
Questa sessione va portata fino al caricamento e non si ferma in mezzo. Fermarsi è ammesso soltanto se la capacità della sessione si sta esaurendo davvero, e va dichiarato con il dato che lo mostra. Hai piena delega fino al resoconto finale e non devi chiedere conferme.
Il problema, detto senza attenuazioni
Il titolare ha incontrato, giocando la build 27, una seconda situazione in cui il gioco si ferma e non si va più avanti. Non ricorda quale fosse e non sa riprodurla. È il secondo blocco in due build.
Nessuna delle prove esistenti coglie questa classe di difetti, e la ragione è che nessuna gioca una partita intera fino alla sua conclusione naturale attraverso l'interfaccia. Le partite generate dal programma di verifica passano dal Motore e non dallo schermo, e costruiscono i propri scenari invece di aprire quello che il giocatore apre. Le prove d'interfaccia esistenti percorrono tratti brevi e si fermano poco dopo il punto che dovevano verificare.
È una lacuna degli incarichi precedenti e non una tua mancanza. Va colmata adesso, ed è la parte più importante di questa sessione.
Primo e principale: la prova che gioca le partite fino in fondo
Realizza una prova d'interfaccia che apra la partita di campagna esattamente come la apre il giocatore, e la giochi fino alla sua conclusione naturale, cioè finché la partita finisce per una delle vie previste, non per un numero di giornate deciso a tavolino.
Deve giocare attraverso l'interfaccia vera: impartire gli ordini dai pannelli, aprire le battaglie dal comando della casella, combatterle sulla schermata di battaglia, chiudere i resoconti, tornare in campagna, proseguire. Non deve iniettare stati né scorciatoie: ciò che la prova tocca deve essere ciò che il giocatore tocca.
Deve fallire se la partita si ferma, cioè se si raggiunge uno stato in cui nessuna azione è disponibile e la partita non è finita, o se un numero di giornate palesemente eccessivo passa senza che si concluda. Il fallimento deve dichiarare dove ci si è fermati e che cosa impediva di proseguire, non soltanto che ci si è fermati.
Falla girare su tutti e tre i formati di mappa e su più partite diverse, non una sola. Scegli quante e dichiara il criterio: devono essere abbastanza da esercitare percorsi diversi, comprese partite in cui il giocatore vince, in cui perde, in cui si combattono più battaglie, e in cui la battaglia nasce da un'imboscata.
Verifica prima di tutto se questa prova, scritta e messa a girare sul codice attuale, trovi il blocco che il titolare ha incontrato. Se lo trova, correggilo e riporta che cosa era. Se non lo trova, dillo esplicitamente e non dichiarare risolto ciò che non hai visto: la prova resta comunque, perché è la protezione che mancava.
Secondo: la battaglia che non si conclude
La sessione precedente ha segnalato di sua iniziativa che in una battaglia molto sbilanciata l'avversario tattico non conclude mai lo scontro, e non l'ha toccata. È un blocco della stessa specie, dentro la battaglia anziché dopo.
Riproducilo, accertane la causa e correggilo. Ogni battaglia deve concludersi in un numero finito di turni, per una delle vie previste. Aggiungi un invariante, con il proprio mutante, che pretenda la conclusione di ogni battaglia entro un limite dichiarato, e verifica che colga il difetto attuale prima della correzione.
Terzo: il tasto per chiudere la giornata, con la registrazione di ciò che lo rende necessario
Il titolare stabilisce che esista un comando esplicito per chiudere la giornata e proseguire. È una decisione sua che rovescia una regola chiusa in fase di architettura, secondo cui la giornata si chiude da sé e non esiste alcun comando di fine giornata: registrala come modifica voluta e non come correzione di una svista, con la motivazione, cioè che il titolare non può restare bloccato da un difetto in una partita in corso.
Il comando è sempre disponibile e raggiungibile, e chiude la giornata quale che sia lo stato dei gruppi. Deve essere annunciato e non deve rubare il fuoco.
Quando viene premuto in una situazione in cui la giornata avrebbe dovuto chiudersi da sé, il gioco registra il fatto: quali gruppi risultavano non aver agito, quale stato avevano, e quali azioni erano loro disponibili. La registrazione deve finire in un luogo che il titolare possa mandare indietro insieme al salvataggio, perché è l'unico modo di trasformare un blocco che non sa riprodurre in un dato utilizzabile.
Dichiara dove finisce quella registrazione e come si recupera. Non deve essere un canale che esiste solo per il collaudo: è diagnostica del gioco vero.
La chiusura automatica resta e non va tolta: il comando si aggiunge, non la sostituisce.
Il collaudo
Prove del pacchetto sempre. Prove d'interfaccia sul simulatore, comprese quelle nuove. Corsa completa delle sessioni perché il caricamento la esige.
Se la prova che gioca le partite intere richiede molto tempo, misura quanto e dichiaralo, e proponi dove collocarla fra il collaudo di ogni caricamento e la corsa separata, motivando. Non toglierla per ragioni di tempo senza dichiarare la scelta.
Ogni cancello nuovo va visto fallire una volta di proposito, con l'uscita riportata.
Sulla macchina
Il MacBook ha un M5 Pro e ventiquattro gigabyte. Ricorri a sottoagenti in parallelo dove due parti non dipendono l'una dall'altra. Le partite della prova nuova sono indipendenti fra loro e si prestano al parallelismo, con l'avvertenza che due corse sullo stesso ambiente di compilazione si ostacolano. Le misure di tempo si prendono da sole.
Che cosa non devi fare
Non usare il tasto di chiusura della giornata come rimedio ai blocchi: è una via d'uscita per il giocatore, non una correzione. Ogni blocco trovato va corretto alla radice.
Non far passare la prova nuova per scorciatoie che il giocatore non ha.
Non dichiarare risolto un blocco che non hai riprodotto.
Non introdurre estrazioni del caso.
Non toccare il corpo a corpo, le soglie di disingaggio o alcun valore del combattimento, salvo quanto serva a far concludere le battaglie sbilanciate, e in quel caso dichiara che cosa hai cambiato e perché.
Non introdurre termini nuovi nel vocabolario chiuso: se ne servisse uno, dichiaralo e fermati su quel punto.
Non costruire stagioni, opere, stanchezza, manutenzione, patria, risorse.
Non toccare la versione di marketing, i certificati, i profili o gli identificatori di pacchetto.
Se una prescrizione di questo incarico contraddice un documento consolidato, prevale il consolidato: dichiaralo citando documento e punto. Fa eccezione il tasto di chiusura della giornata, che è decisione del titolare contro una regola scritta e va eseguito come tale.
Il caricamento
Carica la build al termine.
Incrementa la versione dei valori se cambiano regole che incidono sul modo in cui una partita in corso si svolgerebbe, e dichiara la valutazione. Verifica per interfaccia di programmazione che la build sia valida, sul treno più alto, assegnata al gruppo di test, e che il registro concordi con i server nei due versi.
Nella nota per il titolare, in linguaggio non tecnico: che ora esiste un comando per chiudere la giornata e dove si trova; che se lo usa perché il gioco si era fermato, il gioco se ne accorge e ne conserva traccia, e come mandarla indietro; quali blocchi sono stati corretti; e che le partite vengono ora giocate fino in fondo dal collaudo.
Il versionamento
Ramo dedicato, fusione del solo verde, spinta di principale e del ramo dedicato, cancellazione del ramo fuso. Verifica al termine che principale locale e remoto coincidano, riportando il comando che lo accerta.
Al termine
Registra nel registro delle decisioni: il comando di chiusura della giornata come modifica voluta di una decisione presa, con la motivazione; la registrazione diagnostica e dove vive; la causa e la correzione della battaglia che non si concludeva; ogni blocco trovato dalla prova nuova.
Resoconto in registro tecnico, con nomi reali e comandi. Ogni numero porta lo strumento che lo ha prodotto; nessun numero a mente; i totali pareggiano le righe. Ciò che non hai verificato va dichiarato tale nel punto in cui compare. Elenca ciò che hai fatto senza che fosse chiesto e ciò che era chiesto e non hai fatto.
Metti in testa al resoconto: quante partite intere la prova nuova gioca, quante arrivano alla fine, quali blocchi ha trovato e che cosa erano.
Archivia il resoconto verbatim in Incarichi/, verifica che il file esista e non sia vuoto, e aggiorna l'indice. se non riesc a finire entro un'ora, cercad i chiudere e sigillare quello che hai fatto e fermarti pulito per poi riprendere in successivo momento
