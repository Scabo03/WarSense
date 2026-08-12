Incarico — La campagna si blocca dopo la battaglia, e il ripiegamento dello sconfitto
Sessione nuova senza memoria delle precedenti. Archivia questo documento verbatim in Incarichi/ prima di cominciare, verifica che il file esista e non sia vuoto, e aggiorna l'indice.
Prima di cominciare leggi forma-dei-resoconti.md e il resoconto dell'incarico precedente in Incarichi/, che ha costruito il passaggio fra i due piani. Del documento di progetto leggi i punti sulla conclusione della battaglia e il ritorno in campagna, sulla ritirata combattuta, sul perimetro della giornata e sulla chiusura automatica del turno, e la regola del taglio per la definizione di direzione retrostante. Non aprire altro se non ti serve per un punto specifico.
Ramo principale a 304b0d8, allineato con il remoto, build 26 su TestFlight.
Questa sessione va portata fino al caricamento e non si ferma in mezzo. Fermarsi è ammesso soltanto se la capacità della sessione si sta esaurendo davvero, e va dichiarato con il dato che lo mostra. Hai piena delega fino al resoconto finale e non devi chiedere conferme.
Il difetto bloccante, riferito dal titolare giocando la build 26
Al ritorno dalla battaglia il proprio gruppo vincitore resta nella casella dov'era, ma in uno stato che non è né agito né in attesa: la giornata non si chiude perché il gruppo risulta non avere agito, e nello stesso tempo non c'è modo di farlo agire. La campagna resta bloccata in modo irreversibile e la partita è perduta.
È l'osservazione di una partita reale e va trattata come dato. Ha la precedenza su tutto il resto di questo incarico.
Perché il collaudo non l'ha visto, e che cosa va cambiato nel modo di provare
La prova d'interfaccia scritta nella sessione precedente accerta che le forze tornino in campagna con l'esito giusto, e si ferma lì. Nessuna prova prosegue oltre il ritorno fino alla giornata successiva, e il difetto sta esattamente in quello spazio.
È la stessa classe di errore che il progetto ha già pagato più volte: un controllo che verifica la forma e non l'effetto. La correzione del modo di provare è parte non facoltativa di questo incarico.
Ogni prova che riguarda il ritorno dalla battaglia deve proseguire almeno fino alla chiusura della giornata successiva e all'apertura di quella dopo, verificando che il gioco resti giocabile. Realizza una prova d'interfaccia che apra la partita come la apre il giocatore, porti due gruppi a contatto, apra e combatta la battaglia, torni in campagna, e da lì prosegua per almeno due giornate intere ordinando i gruppi e vedendo le giornate chiudersi. Falla fallire sul codice attuale prima di correggere e riporta l'uscita.
Aggiungi inoltre un invariante, con il proprio mutante, che pretenda che in nessun momento esista un gruppo che non abbia agito e al quale non sia disponibile alcuna azione. Uno stato del genere è un blocco irreversibile e va reso impossibile, non evitato per disciplina. Verifica che l'invariante colga il difetto attuale prima della correzione.
La regola che il titolare stabilisce
Il gruppo che ha combattuto spende la giornata combattendo. Vale per entrambe le parti: nessun gruppo reduce da una battaglia compie altro quel giorno, e la giornata si chiude di conseguenza.
Il gruppo sconfitto che non sia stato annientato ripiega di una casella all'indietro, e il giocatore sceglie subito quale, a battaglia appena conclusa. All'indietro significa verso il proprio quartier generale, secondo la stessa definizione di direzione retrostante già usata dalla regola del taglio del rifornimento: non introdurre una seconda nozione di direzione.
Il gruppo vincitore normalmente resta nella casella contesa. Fa eccezione il caso in cui abbia vinto perché l'avversario si è ritirato prima di lui, cioè entrambi hanno chiamato ritirata e lui l'ha chiamata dopo: in quel caso ripiega anch'esso e sceglie dove, con le stesse regole dello sconfitto.
Il gruppo annientato sparisce dalla mappa e non ripiega.
Casi limite da chiudere e dichiarare, senza chiedere: che cosa accade se in direzione del proprio quartier generale non esiste alcuna casella disponibile, perché si è al bordo della mappa o perché le caselle sono occupate. Decidi, dichiara la scelta con la sua ragione e registrala. Ogni casella deve continuare a contenere al più una formazione per parte, come già stabilito.
Che cosa il giocatore sente
La scelta della casella di ripiegamento avviene a battaglia conclusa e va offerta in forma praticabile ascoltando: le caselle disponibili si annunciano ciascuna come elemento a sé, in una frase compatta, e si sceglie attivandola. Nessuna tabella, nessun trascinamento.
Il giocatore deve capire, tornando sulla mappa, che il proprio gruppo ha speso la giornata combattendo e che non gli resta altro da fare quel giorno. Dichiara la frase con cui lo capisce.
Non introdurre termini nuovi nel vocabolario chiuso. Se ne servisse uno, dichiaralo e fermati su quel punto, non sull'intera sessione.
Il collaudo
Prove del pacchetto sempre. Prove d'interfaccia sul simulatore, comprese quelle nuove descritte sopra. Corsa completa delle sessioni perché il caricamento la esige.
Il banco deve generare partite che comprendano battaglie e proseguano per molte giornate dopo la loro conclusione, non partite che si fermano alla battaglia. Riporta quante giornate in media una partita prosegue dopo la prima battaglia: se è zero o quasi, il banco non sta esercitando il caso che ha bloccato il titolare.
Ogni cancello nuovo va visto fallire una volta di proposito, con l'uscita riportata. I casi nuovi del giornale rispettano la catena dei campioni, committati nella stessa modifica.
Sulla macchina
Il MacBook ha un M5 Pro e ventiquattro gigabyte. Ricorri a sottoagenti in parallelo dove due parti non dipendono l'una dall'altra. Le corse che invocano lo stesso ambiente di compilazione vanno tenute in sequenza. Le misure di tempo si prendono da sole.
Che cosa non devi fare
Non tappare il blocco impedendo che lo stato si produca in un caso particolare: va reso impossibile per costruzione e sorvegliato da un invariante.
Non introdurre una seconda nozione di direzione retrostante.
Non dichiarare risolto nulla che tu non abbia visto funzionare su una partita giocata attraverso l'interfaccia del simulatore, proseguita oltre il ritorno dalla battaglia.
Non toccare il corpo a corpo, le soglie di disingaggio o alcun valore del combattimento.
Non introdurre estrazioni del caso.
Non introdurre termini nuovi nel vocabolario chiuso.
Non costruire stagioni, opere, stanchezza, manutenzione, patria, risorse.
Non toccare la versione di marketing, i certificati, i profili o gli identificatori di pacchetto.
Se una prescrizione di questo incarico contraddice un documento consolidato, prevale il consolidato: dichiaralo citando documento e punto.
Il caricamento
Carica la build al termine. Il titolare ha una campagna bloccata e non può giocare finché non arriva.
Incrementa la versione dei valori se cambiano regole che incidono sul modo in cui una partita in corso si svolgerebbe, e dichiara la valutazione. Verifica per interfaccia di programmazione che la build sia valida, sul treno più alto, assegnata al gruppo di test, e che il registro concordi con i server nei due versi.
Nella nota per il titolare, in linguaggio non tecnico: che il blocco dopo la battaglia è corretto; che il gruppo che combatte spende la giornata; che lo sconfitto ripiega di una casella verso il proprio quartier generale e come si sceglie quale; e che cosa accade al vincitore.
Il versionamento
Ramo dedicato, fusione del solo verde, spinta di principale e del ramo dedicato, cancellazione del ramo fuso. Verifica al termine che principale locale e remoto coincidano, riportando il comando che lo accerta.
Al termine
Registra nel registro delle decisioni: la causa vera del blocco; la regola del ripiegamento con i casi limite chiusi; l'invariante che rende impossibile un gruppo senza azioni disponibili. Registra gli scostamenti nuovi.
Resoconto in registro tecnico, con nomi reali e comandi. Ogni numero porta lo strumento che lo ha prodotto; nessun numero a mente; i totali pareggiano le righe. Ciò che non hai verificato va dichiarato tale nel punto in cui compare. Elenca ciò che hai fatto senza che fosse chiesto e ciò che era chiesto e non hai fatto.
Metti in testa al resoconto la causa vera del blocco in forma diretta, e le frasi che il giocatore sentirà tornando dalla battaglia e scegliendo dove ripiegare.
Archivia il resoconto verbatim in Incarichi/, verifica che il file esista e non sia vuoto, e aggiorna l'indice.
