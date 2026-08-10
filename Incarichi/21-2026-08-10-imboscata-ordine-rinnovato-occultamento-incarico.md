Incarico — L'imboscata come ordine che si rinnova e come cosa che non si vede, e la chiusura del lavoro sospeso

Sessione nuova senza memoria delle precedenti. Archivia questo documento verbatim in Incarichi/ prima di cominciare, verifica che il file esista e non sia vuoto, e aggiorna l'indice.

Prima di cominciare leggi soltanto forma-dei-resoconti.md e i resoconti degli incarichi 19 e 20 in Incarichi/, che descrivono il lavoro fatto e il punto in cui si è fermato. Del documento di progetto leggi i punti sull'imboscata e sull'informazione incompleta; del documento di accessibilità i punti sugli stati di conoscenza e sul fatto che il gioco non dichiari mai il falso. Non aprire altro.

Lo stato di partenza

Ramo principale a 26d061e, locale e remoto coincidenti. Il lavoro su ricognizione, formazioni non armate e imboscate sta in dodici commit non fusi sul ramo ricognizione-non-armate-imboscate. Nessuna build caricata da quel lavoro: i tester hanno ancora la 22.

Il collaudo d'interfaccia e la corsa separata delle sessioni sono verdi. Il collaudo del pacchetto non termina, per la ragione accertata dalla sessione precedente: nel banco, quando il giocatore mette tutti i propri gruppi in agguato, resta concluso per sempre mentre l'avversario conserva gruppi liberi, e il ciclo interno lo muove per giornate senza fine. Il Motore è sano; il difetto è la non terminazione.

Le due decisioni del titolare

Prima. L'imboscata cessa di essere uno stato che dura e diventa un ordine che si rinnova. Ogni giornata il giocatore ordina esplicitamente al gruppo di restare appostato, e quell'ordine consuma l'azione di quel gruppo per quella giornata. Quando tutti i gruppi hanno agito, appostati compresi, la giornata si chiude da sé come sempre.

L'imboscata figura già nell'elenco chiuso delle azioni di giornata: non è una voce nuova, cambia natura. Registra la modifica come voluta e non come correzione di una svista.

Questa decisione scioglie anche il blocco del banco, perché un gruppo appostato consuma l'azione e la giornata non può più riaprirsi all'infinito. Verifica che sia davvero così e che le prove che esigono molte giornate su quegli scenari tornino a passare. Se dopo la modifica restasse un caso di non terminazione, dichiaralo con lo scenario che lo produce invece di aggiungere un freno che lo nasconda.

Seconda. Un gruppo che si apposta non deve essere visibile a chi gli passa vicino, altrimenti l'imboscata non funziona: l'avversario vedrebbe il quadrato fermo e semplicemente non entrerebbe.

La forma è però precisa e va rispettata alla lettera, perché il gioco non dichiara mai il falso e questa regola non ammette eccezioni. Il gruppo appostato non diventa invisibile: è la conoscenza che l'altra parte ha di quella casella a retrocedere da confermato. L'altra parte conserva un ricordo più vecchio, che non contiene il gruppo perché nel frattempo si è nascosto. Chi vi entra non trova una casella che dichiarava il vuoto, ma una casella di cui non aveva più notizia certa. È vero, e produce l'effetto voluto.

Realizzalo così e non come un'eccezione alla visibilità. Dichiara esplicitamente come hai evitato che il gioco affermi il falso in qualunque momento della sequenza, compreso l'istante in cui il gruppo si apposta mentre l'altra parte lo sta osservando.

Il solo modo di scoprire un'imboscata pendente sono le formazioni di ricognizione, alle condizioni già realizzate per l'esplorazione: la riuscita discende dalla competenza degli esploratori contro l'insidiosità, senza alcuna estrazione del caso, e il tentativo può risolversi anche con gli esploratori notati o perduti. Scoperta l'imboscata, la posizione del gruppo appostato è rivelata e il fatto entra nel registro.

Tutto questo vale simmetricamente per l'avversario, che tende imboscate che il giocatore non vede e nelle quali può cadere. Verifica che la simmetria sia reale e che l'avversario, che decide sulla propria memoria, si comporti di conseguenza: deve poter entrare in una casella di cui non ha notizia certa, e deve poterne stare alla larga se i suoi esploratori vi hanno scoperto qualcosa.

Che cosa il giocatore sente

Il gruppo appostato si annuncia come tale al proprietario, con il termine già chiuso nel vocabolario. Non introdurre termini nuovi: se ne servisse uno, dichiaralo e fermati su quel punto.

L'ordine di appostarsi va offerto ogni giornata al gruppo che sta fermo, e il giocatore deve capire che è un ordine da ripetere e non uno stato che prosegue da sé. Dichiara la frase con cui lo capisce.

L'imboscata scoperta dai propri esploratori entra nel registro, con il luogo, ed è attivabile. Lo stesso vale per l'imboscata propria che scatta.

Il collaudo

Estendi il programma di verifica: il banco deve generare imboscate scoperte dagli esploratori, imboscate non scoperte in cui si cade, e giornate in cui tutti i gruppi di una parte sono appostati. Riporta la frequenza di ciascun fenomeno.

Aggiungi invarianti con il proprio mutante: che una partita termini sempre entro un numero dichiarato di giornate; che nessuna parte riceva mai un'informazione che il proprio stato di conoscenza non contiene; che un gruppo appostato consumi l'azione ogni giornata; che il gioco non dichiari mai il falso su una casella in cui si trova un gruppo appostato.

Ogni cancello nuovo va visto fallire una volta di proposito, con l'uscita riportata. I casi nuovi del giornale rispettano la catena dei campioni, committati nella stessa modifica.

La chiusura del lavoro sospeso

Quando il pacchetto è verde, esegui il collaudo completo comprese le prove d'interfaccia e la corsa separata delle sessioni, poi carica la build, fondi il ramo sul principale, spingi entrambi e cancella il ramo fuso.

Incrementa il numero di build e valuta la versione dei valori, dichiarando la valutazione invece di lasciarla per omissione. Verifica per interfaccia di programmazione che la build sia valida, sul treno più alto, assegnata al gruppo di test, e che il registro delle build concordi con i server nei due versi.

Riscrivi la nota per il titolare perché descriva la build che carichi. Deve dire in linguaggio non tecnico: che ora esistono gli esploratori e come si ordina loro di esplorare, e che cosa può andare storto; che l'imboscata va ordinata ogni giorno e consuma l'azione del gruppo; che un gruppo appostato non è visibile all'avversario, e che il solo modo di scoprire un'imboscata nemica sono i propri esploratori; che cosa sono le formazioni non armate e che cosa si può fare loro; e che le formazioni avversarie hanno ora un proprio segno sulla mappa, distinto per forma e non per colore. Il titolare nella build precedente ha cercato l'esplorazione che non esisteva: la nota deve impedire che accada di nuovo.

Sulla macchina

Il MacBook ha un M5 Pro e ventiquattro gigabyte. Le corse sono indipendenti fra loro: mandale in parallelo dove puoi, ricorrendo a più simulatori e a sottoagenti. È un invito e non un obbligo, e vale per il lavoro, non per le misure di tempo, che si prendono da sole.

Questa sessione va portata fino al caricamento. Fermarsi prima è ammesso soltanto se la capacità si sta esaurendo davvero, e va dichiarato con il dato che lo mostra e non con una valutazione di opportunità.

Che cosa non devi fare

Non far dichiarare al gioco alcunché di falso, in nessun istante e per nessuna delle due parti.

Non rendere il gruppo appostato invisibile per eccezione alla visibilità: la via è la conoscenza che retrocede.

Non introdurre alcuna estrazione del caso nella scoperta delle imboscate.

Non nascondere una non terminazione con un freno: se resta, va dichiarata con lo scenario che la produce.

Non costruire stagioni, opere, stanchezza, manutenzione, passaggio alla battaglia, patria.

Non tarare valori di gioco: i sabotaggi che falliscono trentanove volte su quaranta sono taratura accertata e li deciderà il titolare giocando.

Non introdurre termini nuovi nel vocabolario chiuso.

Non toccare la versione di marketing, i certificati, i profili o gli identificatori di pacchetto.

Non fondere sul principale nulla che non sia completo e verde.

Se una prescrizione di questo incarico contraddice un documento consolidato, prevale il consolidato: dichiaralo citando documento e punto.

Il versionamento

Ramo dedicato, fusione del solo verde, spinta di principale e del ramo dedicato, cancellazione del ramo fuso. Verifica al termine che principale locale e remoto coincidano, riportando il comando che lo accerta.

Al termine

Registra nel registro delle decisioni: l'imboscata come ordine che si rinnova e consuma l'azione, come modifica voluta; la retrocessione della conoscenza come forma dell'occultamento, con la ragione per cui non viola la veridicità; la scoperta dell'imboscata riservata alla ricognizione. Registra fra i valori provvisori i numeri introdotti, l'insidiosità dell'imboscata compresa. Registra gli scostamenti nuovi e chiudi quelli superati.

Resoconto in registro tecnico, con nomi reali e comandi. Ogni numero porta lo strumento che lo ha prodotto; nessun numero a mente; i totali pareggiano le righe. Ciò che non hai verificato va dichiarato tale nel punto in cui compare. Elenca ciò che hai fatto senza che fosse chiesto e ciò che era chiesto e non hai fatto.

Riporta in coda quanto tempo è andato in compilazione, corse del collaudo, corse del simulatore e caricamento.

Metti in testa al resoconto le frasi vere che il giocatore sentirà ordinando un'imboscata, quando i suoi esploratori ne scoprono una, e quando la sua imboscata scatta.

Archivia il resoconto verbatim in Incarichi/, verifica che il file esista e non sia vuoto, e aggiorna l'indice.
