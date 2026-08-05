# Registro degli scostamenti dalla realizzazione

Documento di lavoro della fase 5. I punti in cui la realizzazione ha mostrato che l'architettura non funzionava come previsto, con che cosa è successo, che cosa si è fatto invece e perché. Le decisioni realizzative minute che l'architettura non copriva, ma che non la contraddicono, sono registrate come precisazioni.

## S1 — Cache dei Bundle: caricamento dei testi per copia di lavoro

**Che cosa è successo.** L'architettura prevede il caricamento dei testi con `Bundle(path:)` dalla cartella sostituibile in Documenti (05 §8.1, RDA-09). La prova sul campo del primo giorno (`CatenaTestiEsterniTest`, prova 4) ha mostrato che il sistema memorizza i Bundle per percorso: dopo la sostituzione dei file sullo stesso percorso, un nuovo `Bundle` restituisce ancora i testi vecchi.

**Che cosa si è fatto.** Il modulo Dati carica i testi attraverso una copia di lavoro a percorso unico per sessione (`Testi.carica`): la cartella di lingua viene copiata in una posizione temporanea irripetibile e il Bundle si costruisce lì. La sostituzione dei file resta pienamente efficace alla successiva apertura dello slot, come 05 §7.9 già prevede.

**Perché non tocca i documenti.** Il comportamento dichiarato da 05 §7.9 e §8.1 (caricamento per sessione, valori e testi fissi fino alla chiusura dello slot) resta esattamente vero; la copia di lavoro è il meccanismo che lo rende vero. Nessuna versione da incrementare.

## P1 — Precisazione: disingaggio senza cella libera

01 §9.8.2 prescrive la ritrazione di una cella verso le proprie retrovie ma non dice che cosa accada se nessuna delle due celle arretrate è libera e percorribile. Realizzazione: il reparto resta ingaggiato e la mischia continua; il disingaggio riproverà al giro successivo se lo spazio si libera. Le due celle candidate sono provate in ordine fisso, prima verso ovest poi verso est (`Griglia.celleArretrate`). Deterministica, senza regola nuova per il giocatore. Da riportare nel documento 01 se in fase di consolidamento futuro si vorrà la regola esplicita.

## P2 — Precisazione: momento della prova di ripresa incompatibile

00 §15.2 impone di dichiarare e non aprire. Realizzazione: `SessioneBattaglia(riprendi:)` lancia `salvataggioIncompatibile(attesa:trovata:)` con le due versioni, che la Presentazione annuncerà con la chiave dedicata. La compatibilità si valuta sulla versione base al netto del suffisso locale (RDA-45), come 05 §6.6 prevede.

## P3 — Precisazione: marcatori di inizio turno per entrambe le parti

In fase A un'unica Sessione serve entrambe le parti (il collaudo guida anche l'avversario). Il giornale registra un marcatore di inizio turno per ciascuna parte, e l'azzeramento di una parte risale al marcatore di quella parte. Quando il tattico avversario diventerà una sorgente interna (fase B), i marcatori della parte avversaria faranno da punto di conferma per il giocatore, come 05 §6.5 prevede («inizio delle azioni avversarie»).

## P4 — Precisazione: chi si disingaggia lascia l'intera mischia

01 §9.8.2 norma la ritrazione del reparto che si disingaggia, ma non il caso dei contatti multipli: un reparto ingaggiato da due avversari che supera la soglia in uno dei contatti. Realizzazione (fase B): la ritrazione chiude tutti i contatti del reparto che si ritrae, e ogni coppia coinvolta entra nella memoria dei disingaggi e nel divieto di un turno (01 §9.8.2, §9.8.3). La lettura opposta — ritrarsi da una mischia restando dentro un'altra — avrebbe prodotto mischie a distanza prive di senso. La modifica ha cambiato la dinamica del primo copione d'oro, che conteneva davvero un contatto multiplo: la riproduzione è stata rigenerata con revisione esplicita, come la procedura prescrive (05 §14.6). Coperta da prove dedicate (CasiAngoloMischiaTest).

## S2 — La designazione pendente è stato di presentazione, non di partita

05 §2.7 colloca «la designazione di bersaglio in corso» nello stato di battaglia. Nella realizzazione della fase B la designazione (la scelta della destinazione sulla griglia dopo l'apertura del pannello) vive nella schermata: nessun comando viene emesso finché la scelta non è confermata, e una chiusura dell'applicazione a metà designazione riprende dalla cella dell'unità, senza perdere nulla di giocato. Ragione: mettere nel giornale uno stato che non muta la partita avrebbe sporcato la sequenza dei comandi (RDA-05) per conservare un'intenzione, non una scelta. La selezione dal deck, che invece è un comando, resta nello stato e sopravvive alla ripresa come 01 §6.6 chiede. Se le prove con i tester mostrassero che la perdita della designazione alla ripresa disorienta, la materia si riapre; per ora il documento 05 §2.7 va letto con questa precisazione.

## S3 — Il collaudo del fuoco accertava la dichiarazione, non la raggiungibilità

**Che cosa è successo.** La prima prova su dispositivo della fase B ha trovato elementi del deck che VoiceOver non agganciava, con le prove del fuoco e degli annunci verdi. Causa tecnica: la colonna sotto la griglia aveva vincoli insoddisfacibili (altezza della griglia imposta al 55 per cento più minimi obbligatori dei comandi), e il risolutore schiacciava ad altezza zero elementi arbitrari — nelle riproduzioni, i tiratori e la fanteria pesante, in modo variabile fra una risoluzione e l'altra, che è esattamente l'intermittenza osservata dal titolare. Le prove verificavano esistenza, identità ed etichette degli elementi, mai la geometria né il percorso di lettura effettivo: la dichiarazione, non la raggiungibilità.

**Che cosa si è fatto.** Un lettore dell'ordine di lettura effettivo (`LettoreAccessibilita` nelle prove ospitate) ricostruisce il percorso come lo risolve la tecnologia assistiva e accerta, per ogni elemento: presenza nel percorso, etichetta, cornice non degenere, posizione dentro lo schermo piccolo di riferimento o dentro un contenitore scorrevole, bersagli di almeno 44 punti. Prove intestate a 00 §1.2 e 02 §2.8 (`RaggiungibilitaTest`); il fumo d'interfaccia esercita il tocco vero delle tessere attraverso il servizio di accessibilità reale. Ciò che nemmeno così è accertabile è dichiarato in `collaudo-solo-dispositivo.md`, consegnato con la build (RDA-51). Limite dichiarato: nelle prove ospitate il runtime di accessibilità non è caricato, quindi ruoli ed etichette derivate si valutano con la derivazione convenzionale; la pronuncia reale resta al dispositivo.

**Perché non tocca i documenti.** 05 §14.4 chiede prove automatiche del comportamento accessibile; lo scostamento riguarda il come, non il se. La forma del deck che ne è seguita è registrata come RDA-50.

## P5 — Precisazione: l'avviso di sistema si congeda da solo

Il pannello della cella è l'avviso di sistema (RDA-49). Al tocco di una voce l'avviso si congeda DA SOLO, e la chiusura della voce corre a congedo già avvenuto o in corso: un congedo incondizionato dentro `chiudiPannello` colpiva allora la schermata dello scontro stessa, riportando all'avvio — per chi ascolta, indistinguibile da un riavvio dell'applicazione (il primo difetto bloccante della prova su dispositivo). Regola realizzativa: la chiusura del pannello congeda soltanto un pannello ancora presentato e non già in congedo; altrimenti ripristina direttamente fuoco e azione. La sequenza reale del tocco è riprodotta da `PannelloAzioniTest` (02 §9.2.1).

## P6 — CHIUSO: chi è sconfitto quando l'annientamento è simultaneo

Aperto dall'accertamento sugli esiti degli scontri (build 6), chiuso dal titolare nella tranche successiva.

**Che cosa non era normato.** 01 §15.2.3 chiudeva la battaglia «quando uno dei due è stato annientato» e 01 §15.2.2 escludeva la parità, ma nessuno dei due diceva che cosa accada quando l'ultimo reparto di ciascuna parte cade nel medesimo giro. La realizzazione lo risolveva per l'ordine di un'enumerazione, e sempre a sfavore del giocatore.

**Come è stato chiuso.** Il titolare ha stabilito che l'annientamento simultaneo non può risolversi a sfavore del giocatore. Fra le due strade previste — un esito di parità oppure l'assegnazione — si è scelta l'assegnazione, perché la parità avrebbe contraddetto 01 §15.2.2 e obbligato a rifare resoconto, ritorno in campagna e registrazioni, mentre l'assegnazione tocca una riga di regola. La regola è ora 01 §15.2.5, è iscritta fra i vantaggi nascosti (01 §13.2, 03 §7.2) e vive nei dati come interruttore disattivabile dal programma di verifica (RDA-57). Coperta da tre prove: l'esito assegnato, l'interruttore spento, e l'annientamento di una sola parte lasciato invariato.

## P7 — Precisazione: l'efficacia entra anche nella voce di ingaggio

02 §9.2.1 prescrive che, per le azioni con bersaglio, la voce del pannello annunci «il bersaglio con nome e lettera, l'efficacia e ogni costo». Fino alla versione 2.2 dei testi la sola voce di tiro dichiarava l'efficacia; quella di ingaggio dava nome, lettera e posizione, e non l'efficacia — pur valendo per la mischia il medesimo accoppiamento offesa-protezione (01 §9.9.2). Realizzazione: le due voci hanno ora lo stesso ordine fisso di informazioni, chiuso in 02 §9.3.1. Non è uno scostamento dall'architettura ma il colmarne un'omissione, ed è stato fatto nella stessa tranche dei due modificatori perché tocca le medesime frasi.

## P8 — Difetto trovato dal programma di verifica: la ritirata riuscita raccontata come annientamento

**Che cosa è successo.** La prima corsa del programma di verifica della fase C ha mostrato righe incoerenti: battaglie chiuse per annientamento in cui la parte annientata aveva perduto meno punti vita di quanti ne avesse impegnati, e ne aveva evacuati alcuni. La sonda ha chiarito: il ritirante che evacua TUTTO e non ha più riserve nel mazzo resta senza nulla in campo e senza nulla nel mazzo, e la condizione di annientamento — verificata per prima e senza guardare alla resa — risultava vera.

**Perché è un difetto e non una scelta.** 01 §15.2.3 riserva l'annientamento al caso in cui «nessuno dei due si ritira». Il vincitore non cambiava, ma il MODO sì, e il modo è ciò che il resoconto di fine battaglia annuncia al giocatore (01 §15.3.1): una ritirata riuscita, cioè l'esito migliore che una battaglia perduta consenta, veniva raccontata come una disfatta totale. Il difetto non era emerso prima perché scatta soltanto quando il ritirante ha anche il mazzo vuoto: il secondo copione d'oro, che pure si chiude per resa, lascia riserve nel mazzo di proposito.

**Che cosa si è fatto.** Dichiarata la resa, la conclusione è ora governata dalla sola ritirata combattuta e il modo è sempre la ritirata compiuta. Aggiunta la condizione, prima non normata, in cui è l'AVANZANTE a restare senza nulla: la ritirata è riuscita e lo sconfitto resta chi si è ritirato, per 01 §15.2.2. Recepito in 01 §15.2.3.1; due prove dedicate, una per ciascuno dei due casi.

**Che cosa insegna.** È il primo difetto che il collaudo non aveva trovato e la misura sì. Le prove verificavano ciascuna regola per conto proprio; il programma di verifica ha fatto interagire resa, evacuazione e mazzo vuoto in una configurazione che nessuna prova aveva composto. È esattamente il motivo per cui 00 §16.1 vuole la misura accanto al collaudo.

## S4 — Le mappe stanno in `Valori/Mappe/` e non in `mappe/<fronte>/`

**Che cosa è successo.** 05 §7.5 colloca le mappe in `mappe/<fronte>/<mappa>.json`. I fronti sono la materia della fase F (05 §15.7): non esistono, e inventarne uno per contenere tre mappe di prova avrebbe significato scegliere adesso una struttura che quella fase deve poter decidere.

**Che cosa si è fatto.** Le mappe stanno in `Valori/Mappe/<mappa>.json`, un albero piatto. Il caricatore legge tutti i file della cartella, quale che sia il loro nome, e la mappa dichiara il proprio identificatore: introdurre il livello del fronte richiederà di leggere una cartella in più, non di cambiare la forma dei file né lo stato.

**Perché non tocca i documenti.** 05 §7.6, che descrive che cosa una mappa dichiara, è rispettato per intero. Il solo percorso cambia, e cambierà ancora quando i fronti esisteranno.

## S5 — Discrepanza sui formati di mappa, NON chiusa

**Che cosa è successo.** 01 §5.1 dichiara «tre formati fissi»: quattro per quattro, sei per sei, dieci per dieci. Ma 01 §5.14.5 e §5.14.5.1, scritti a proposito della conoscenza conferita da fortezze e torri, nominano un formato OTTO per otto e lo dicono «il più frequente fra i formati minori».

**Che cosa si è fatto.** Nulla, di proposito. Questa unità realizza i tre formati di 01 §5.1, che è il punto che definisce la mappa; l'otto per otto compare soltanto in un punto che riguarda la portata della conoscenza, materia esclusa dal perimetro. Le dimensioni stanno nei dati e non nel codice: aggiungere un quarto formato è una voce in `formati-mappa.json` e nessuna riga di programma.

**Perché resta aperta.** Chiuderla richiederebbe di decidere se i formati siano tre o quattro, e la decisione appartiene al titolare insieme alla disciplina della conoscenza. Lasciarla aperta non costa nulla; chiuderla senza il codice che la mette alla prova costerebbe.

## P9 — Precisazione: il registro si apre da un comando globale e non da un gesto

02 §6.7 chiude i gesti fissi a tre — tocco magico, gesto di fuga, rotore delle campagne attive — e nessuno dei tre apre il registro; 02 §6.6 descrive il registro ma non dice da dove vi si entri. Realizzazione: il registro è il primo dei comandi globali che seguono le caselle nell'ordine di lettura, cioè si raggiunge a scorrimenti come l'annullamento e l'azzeramento. Non si è aggiunto alcun gesto, perché i tre di 02 §6.7 sono chiusi, né alcuna azione personalizzata, perché quelle contengono soltanto spostamenti di navigazione (02 §2.7). Da riportare in 02 §6.6 se una versione futura vorrà la regola esplicita.

## P10 — Precisazione: sulla mappa il gesto di fuga senza designazione risale di un livello

02 §6.7 dà al gesto di fuga il compito di risalire «dal pannello alla griglia, dalla mappa alla schermata delle campagne, da questa alla patria»; 02 §9.2.1 gli dà anche quello di annullare una designazione in corso. Sulla mappa i due compiti convivono. Realizzazione: con una designazione in corso il gesto la annulla e non risale; senza designazione risale. Poiché la schermata delle campagne non esiste ancora (fase F), risalire significa in questa unità tornare alla schermata iniziale. La precedenza data all'annullamento è la stessa che 02 §9.2.1 stabilisce per la battaglia.

## P11 — Osservazione: le griglie rispondono all'attivazione assistiva, non al tocco grezzo

**Che cosa si è visto.** Il fumo d'interfaccia della mappa, scritto in questa unità, ha tentato di ordinare a un gruppo toccandone la casella e non ci è riuscito. La causa: le caselle della mappa — e, allo stesso modo, le celle della griglia di battaglia fin dalla fase B — sono elementi accessibili sintetici dentro una vista che non ha alcun riconoscitore di gesto. Rispondono ad `accessibilityActivate`, cioè al doppio tocco della tecnologia assistiva, e non a un tocco grezzo.

**Perché non è un difetto di questa unità.** La mappa si comporta esattamente come la griglia di battaglia, ed è ciò che il principio 7 richiede; il percorso su cui il gioco è costruito è quello assistivo, ed è provato per identità nelle prove ospitate, dove `attiva(_:)` è la stessa porta che l'attivazione assistiva apre.

**Perché va comunque registrato.** Con VoiceOver spento, nessuna delle due griglie è operabile al tocco. 02 §1.3 dichiara che il gioco è pensato anche per giocatori ipovedenti che usano VoiceOver come SUPPORTO: per costoro VoiceOver è attivo e il percorso funziona. Resta però il caso di chi giocasse a VoiceOver spento, che oggi non può ordinare nulla su nessuno dei due piani. È una condizione preesistente alla campagna, riguarda entrambe le griglie e la sua eventuale correzione va fatta sui due piani insieme, mai su uno solo: sarebbe altrimenti la disparità fra i piani che il principio 7 vieta. Non è stata toccata in questa unità perché il perimetro non la comprende.

**Che cosa costerebbe.** Un riconoscitore di tocco su ciascuna vista di griglia che risolva il punto nella cella e chiami la stessa `attiva(_:)`. Nessun cambiamento di regole, nessun cambiamento di stato, nessuna conseguenza sugli annunci.

**CHIUSO il 2026-08-05 (RDA-78).** Corretto sui due piani insieme, come questa voce prescriveva. La realizzazione differisce dal rimedio qui indicato in un punto, e in meglio: il riconoscitore non chiama `attiva(_:)` — che sarebbe stato un secondo ramo da tenere allineato al primo — ma risolve il punto nell'ELEMENTO e ne invoca `accessibilityActivate()`, cioè esattamente il metodo che la tecnologia assistiva invoca. Il percorso è uno solo per costruzione e non per disciplina. Il riconoscitore vive in `VistaACaselle`, base condivisa da `VistaGriglia` e `VistaMappa`: la divergenza fra i due piani che questa voce temeva non è scrivibile. La prova che falliva prima è `ToccoDirettoTest.test_02_2_11_le_due_griglie_hanno_un_percorso_per_il_tocco_diretto`, rossa su entrambi i piani con il riconoscitore disinstallato.

## S6 — Il resoconto della prima unità conteneva tre numeri non misurati, e uno era sbagliato

**Che cosa è successo.** Il titolare ha sottoposto a controllo aritmetico tre numeri del resoconto della prima unità della fase D. L'accertamento ha stabilito questo, e va scritto senza attenuarlo.

*«Dieci giornate per attraversare la mappa grande»* — misurato, e giusto. Il programma stampa `distanza_fra_quartier_generali` accanto a `giornate_per_congiungerli` (le colonne si chiamavano `distanza_in_caselle` e `giornate`, e sono state rinominate perché nominassero la grandezza che stampano), e sulla mappa `pianura_lunga` la distanza vale dieci e non nove, perché i due quartier generali non stanno sulla stessa colonna (riga 10 colonna 6 e riga 1 colonna 5: nove righe più una colonna). La conclusione «una casella costa una giornata» è quindi sostenuta dai numeri del programma, riga per riga — ma NON è una regola stabilita dall'unità: è il caso particolare prodotto dal costo in giorni pari a uno, ed è dichiarato tale in `valori-provvisori.md` e in RDA-75. Il programma stampa ora quel costo nel proprio riepilogo (`costo_in_giorni_dello_scatto`), così che chi legge la riga sappia da dove viene. Il difetto stava nella SCRITTURA: il resoconto citava la colonna delle giornate e ometteva quella delle distanze, cioè proprio la colonna che la giustificava, e senza di essa il numero sembrava contraddire la frase che gli seguiva.

*«Tredici caselle di bordo su sedici»* e *«trentasette su cento»* — numeri misurati, ma di una grandezza DIVERSA da quella con cui erano stati nominati. Il programma non produceva alcun conteggio di caselle di bordo: produceva la colonna `caselle_sotto_quattro`, cioè le caselle da cui si esce verso meno di quattro caselle libere. Le due grandezze differiscono di esattamente una casella in ciascun formato, ed è sempre la casella INTERNA a nord del quartier generale, dove la misura colloca l'unico gruppo: ha quattro vicine e tre uscite, perché la casella del gruppo non è disponibile (01 §5.6.0.2). Il bordo geometrico vale dodici, venti e trentasei; le caselle con meno di quattro uscite valgono tredici, ventuno e trentasette.

**Che cosa NON è successo.** Non è un difetto del programma. Nessuna casella è irraggiungibile: la sonda degli invarianti percorre ogni mappa da ogni casella e non ne trova alcuna esclusa. La casella in questione si raggiunge e si percorre come ogni altra e si annuncia come ogni altra; una prova dedicata la fa raggiungere da un secondo gruppo. Il ragionamento del titolare — due errori indipendenti non cadono entrambi su un interno diminuito di uno — era giusto e ha individuato una causa sistematica reale: la causa è che una casella interna vicina a un gruppo entra ogni volta in quel conteggio, non che venga classificata male dal codice.

**Che cosa si è fatto.** Nel codice, nulla che riguardi il gioco. Nel programma di verifica, le due grandezze hanno ora colonne distinte e nomi che non si possono scambiare, e una prova del Motore fissa che differiscano di una casella e quale sia. Il resto è RDA-71: i numeri del resoconto si prendono da un blocco che il programma stampa.

**Gli altri numeri di quel resoconto, verificati uno per uno.** «Quindici gesti contro centonove»: misurati, riga `pianura_lunga,5` della sezione dei passi. «Centosessanta giornate e quattrocentoquaranta ordini»: le righe per scenario erano misurate, le due somme le avevo fatte a mente — corrette, ma non misurate. «Centottantanove prove del pacchetto, trentuno ospitate, due d'interfaccia»: lette dall'esecutore del collaudo, non dal programma di verifica. **«Dodici cose che non devono mai accadere»: sbagliato.** Gli invarianti sorvegliati erano quindici, non dodici: avevo contato le voci dell'incarico invece dei casi dell'enumerativo. E la frase che seguiva — «per ciascuno dei dodici ho scritto anche la prova che lo viola» — era falsa due volte, perché due invarianti su quindici non avevano alcun mutante. Ora ne hanno tutti uno, e una prova lo pretende.

## S7 — La generazione delle giornate non copriva né i gruppi molti né lo stipamento

**Che cosa è successo.** Le centosessanta giornate generate della prima unità venivano da quattro scenari con uno, due, tre e cinque gruppi: quattro conteggi su quattro, nessuno sopra cinque, tutti con i gruppi raccolti presso il quartier generale. Gli invarianti che si rompono quando i gruppi sono molti e sparpagliati non erano quindi provati. Inoltre nessuna corsa aveva mai incontrato un gruppo privo di destinazioni: il caso dello stipamento, in cui l'azione di marcia non si offre affatto (02 §9.5), non era mai stato esercitato, e non c'era modo di accorgersene perché nessuna colonna lo contava.

**Che cosa si è fatto.** Sei scenari nuovi, fino a dodici gruppi, sparpagliati sulla mappa grande e stipati sulle due minori — dodici gruppi su sedici caselle è il caso limite. La corsa conta ora gli ordini impartiti a gruppi senza alcuna destinazione, così che «non è mai successo» sia un numero e non un'assenza. Due prove impediscono che si torni indietro: la distribuzione deve toccare almeno sei conteggi diversi e comprendere almeno un caso con otto o più gruppi, e lo stipamento deve risultare esercitato.

**Esito.** Quattrocento giornate, duemilaquattrocentoquaranta ordini, duecentodiciassette dei quali a gruppi senza alcuna destinazione: **zero violazioni**. La copertura è cresciuta e non è emerso nulla. Va detto così com'è: la generazione estesa non ha trovato difetti, e questo non dimostra che non ve ne siano, ma soltanto che questi invarianti reggono anche dove prima non erano stati messi alla prova.

## Nessuno scostamento strutturale

Nessun punto dell'architettura è risultato irrealizzabile o errato nella fase A: i confini dei bersagli, il giornale con istantanee, l'impronta canonica, la virgola fissa e la catena dei testi esterni funzionano come dichiarato. I documenti 00–05 non richiedono modifiche.

## S8 — Il registro annota gli ordini del giocatore, in deroga dichiarata a 01 §5.17.1

**Che cosa dicevano i documenti.** 01 §5.17.1 e 02 §6.6.2 stabiliscono che nel registro entrino soltanto i fatti che il giocatore non ha deciso, e che «non vi entrano i propri ordini, che il giocatore ha appena impartito e già sentito confermare».

**Che cosa è successo.** Applicata alla lettera dentro il perimetro della prima unità, quella regola produce un registro VUOTO di fatti: le mosse avversarie, il rifornimento interrotto, l'imboscata scattata, il completamento di una marcia lunga e il cambio di stagione appartengono tutti a unità successive. La prima unità l'aveva riempito con l'unico fatto rimasto, l'apertura della giornata, e ne era uscito un elenco di sole voci di calendario: un elemento per giornata che dichiarava di essere una giornata nuova, senza alcun contenuto e senza alcun luogo cui saltare. Chi ha usato il gioco lo ha riferito come «il registro non ha contenuto».

**Che cosa si è fatto, e per decisione di chi.** Per decisione del titolare il registro annota, in questa unità, ciò che nel perimetro AVVIENE: gli ordini impartiti ai gruppi — marcia con gruppo, casella di partenza e casella di arrivo; presidio con gruppo e casella — e gli annullamenti. Il criterio di accettazione è quello che 01 §5.17 dichiara come ragione del registro: «senza il registro ogni annuncio che passa mentre il giocatore fa altro è perduto, mentre chi guarda ha il riquadro davanti e vi torna con lo sguardo». Un registro vuoto non lo soddisfa.

**Perché è uno scostamento e non una precisazione.** Contraddice una regola scritta, non colma un vuoto. Va letto come deroga limitata al perimetro attuale: quando i fatti non decisi dal giocatore esisteranno, la materia si riapre e 01 §5.17.1 andrà o confermato — togliendo allora gli ordini dal registro — o modificato con una versione nuova del documento 01. La decisione e la sua ragione sono in RDA-72.

## S9 — Il confine dell'annullamento alla giornata, tolto e rimesso

**Che cosa dichiarava l'architettura.** 05 §6.5 elenca la chiusura della giornata di campagna fra i punti di conferma oltre i quali l'annullamento non retrocede, con la ragione dichiarata in 05 §6.4: «finché l'avversario non ha agito».

**Che cosa aveva fatto la sessione precedente, e perché.** Aveva trovato un difetto reale: l'ordine impartito all'ultimo gruppo — quello la cui conferma chiude la giornata — era l'unico che non si potesse ritirare, e il giorno restava avanzato. Contro 00 §13.8, che prevale su 05. La correzione aveva però rimosso il punto di conferma per intero, rendendo l'annullamento illimitato all'indietro, un ordine per volta, fino al principio della campagna. La giustificazione era che oggi la chiusura incrementa un contatore e nient'altro, e che non c'è nulla di giocato da disfare (RDA-70).

**Che cosa fa questa sessione, e per decisione di chi.** Il titolare ha stabilito che il confine torni ADESSO e non quando l'avversario comparirà. La ragione: l'annullamento dopo la chiusura, in presenza di mosse avversarie e di risoluzioni di fine giornata, equivale alla prova a rovescio e vanifica l'informazione imperfetta, l'imboscata e il valore della ricognizione, che sono l'impianto su cui poggia buona parte del piano di campagna; e una libertà concessa e poi tolta costa al giocatore più di una libertà mai concessa, mentre le abitudini di gioco si stanno formando adesso.

**Che cosa NON si è ripristinato.** Il comportamento della build 11, in cui l'ordine dato all'ultimo gruppo era irreversibile. Quel comportamento rendeva irreversibile un ordine per la sua POSIZIONE nella sequenza e non per la sua natura, in violazione di 00 §13.8. L'ordine che chiude la giornata si annulla, e annullarlo riapre la giornata appena chiusa.

**Il confine realizzato.** Annullamento pieno dentro la giornata in corso; l'ordine che ha chiuso la precedente è annullabile finché nella giornata nuova non è accaduto nulla, né un ordine né un annullamento; oltre quel punto il rifiuto è dichiarato con il proprio termine del vocabolario chiuso. L'azzeramento segue la stessa regola. La forma esatta e la ragione per cui il confine deve stare nel giornale e non nello stato sono in RDA-73.

**L'annotazione lasciata nel codice.** La nota che diceva «quando lo stratega avversario esisterà, il punto di conferma tornerà a mordere, e il posto dove imporlo è questa funzione» è stata sostituita: il codice rimanda ora a RDA-73 e a questo scostamento, che è il luogo dove chi arriva dopo cerca la storia di una decisione.

## P12 — Il difetto riferito sull'annuncio della casella in designazione non è stato riprodotto

**Che cosa era stato riferito.** Che durante la designazione della casella di destinazione di una marcia l'annuncio della casella candidata omettesse il contenuto e le caratteristiche che la stessa casella dichiara in esplorazione, e che una casella con acqua, designata, dichiarasse soltanto riga e casella.

**Che cosa è stato misurato.** L'artefatto che VoiceOver pronuncia per una casella è l'`accessibilityLabel` del suo `ElementoCasella`, che la schermata scrive in `aggiorna(con:)` chiamando `CostruttoreAnnunciCampagna.etichettaCasella(_:designazione:)`. Quel metodo è l'unico punto che lo produce, ed esiste un solo punto di chiamata. Il confronto è stato eseguito su tutte le caselle delle tre mappe e nei tre livelli di verbosità, nelle due modalità: la designazione contiene sempre, in coda, l'annuncio di esplorazione per intero, e vi antepone la disponibilità o il motivo, come 02 §3.3 prescrive. Zero divergenze. La stessa verifica sulla griglia di battaglia, fra esplorazione e designazione della destinazione di un movimento, dà anch'essa zero divergenze.

**Che cosa se ne conclude, senza attenuarlo.** Il difetto non è riproducibile nel testo dell'annuncio, e ciò che è stato misurato non è uno strumento indiretto ma la stringa stessa che la tecnologia assistiva legge. Non è però una smentita di chi lo ha riferito: resta possibile che la condizione dipenda da uno stato che la riproduzione non ha raggiunto, o che il fatto osservato fosse un altro. Ciò che era in mio potere fare l'ho fatto: la prova di classe esiste (`AnnuncioDiCasellaTest`), copre entrambi i piani e fallirebbe se una voce sparisse; ed è stata comunque eseguita la riduzione a un solo percorso che l'incarico chiedeva, perché i percorsi paralleli c'erano davvero — non nel testo dell'annuncio, ma fra il piano sonoro e quello visivo (RDA-74) e fra le due sedi che componevano le frasi del registro.

**Che cosa resta non verificato.** Il comportamento con VoiceOver realmente attivo su dispositivo. È dichiarato in `collaudo-solo-dispositivo.md`.

## S10 — L'impianto d'interfaccia è consegnato incompleto, e queste sono le due cose che gli mancano

**Che cosa è stato consegnato.** `ImpiantoInterfacciaTest` (sei prove, servizio di accessibilità reale del simulatore) e `CatenaInterfacciaMotoreTest` (una prova, stesso processo dell'applicazione). Esercitano il gioco: `test_01_5_6_un_ordine_dato_al_dito_arriva_al_gioco` tocca la casella di un gruppo, sceglie il presidio dal pannello che il tocco ha aperto, e accerta che lo stato del gruppo cambi e che il registro annoti il fatto con il giorno e il luogo. Prima di RDA-78 nessuna prova d'interfaccia poteva farlo.

**Prima cosa mancante: la catena intera — CHIUSA il 2026-08-05, e la causa non era quella supposta.**

La prova è ora `CatenaInterfacciaMotoreTest.test_00_3_1_una_campagna_giocata_al_dito_da_lo_stesso_stato_del_motore`, verde sui tre formati.

*Che cosa bloccava davvero.* Nessun rifiuto. Il ciclo della prova attendeva `azioneSpesa == true` sul gruppo appena ordinato, condizione che è FALSA per costruzione quando l'ordine è quello che chiude la giornata: la chiusura automatica azzera le azioni nello stesso passo (01 §5.6.0.6), sicché l'attesa non poteva terminare. Misurato con una sonda in processo: il secondo ordine su `campagna_piccola` porta il gruppo da riga 4 casella 3 a riga 3 casella 3 e il giorno da 1 a 2, con `azioneSpesa` a falso subito dopo. La prova attende ora che cambi l'IMPRONTA dello stato, che è vero per ogni comando applicato.

*Il sospetto sul costo in giorni era infondato.* La stessa sonda mostra `comandoDiMarcia` produrre `.marcia(gruppo-1, riga 3 casella 2, giorni: 1)` e l'anteprima dare `valido`. Nessun comando è mai stato respinto. Il sospetto era stato formulato senza il motivo in mano e non va ripetuto: si legge il motivo, poi si conclude.

**Conseguenza che resta, e vale oltre la prova.** Il rifiuto di un comando era ANNUNCIATO e non registrato: il giornale porta i comandi validi (05 §6.1) e un ordine respinto non vi lascia nulla. Nessuno — né una prova né il titolare — poteva sapere che cosa il gioco avesse rifiutato durante una partita. `PuntoSegnali.annunciPronunciati` conserva ora ciò che il punto ha detto, nel luogo che lo produce e non in un canale nuovo, con un tetto di struttura di cinquecento voci. Serve anche a 00 §6.4. La prova della catena lo usa per pretendere che nessun ordine sia stato respinto in silenzio: senza quel controllo il confronto delle impronte passerebbe anche con metà degli ordini respinti, perché entrambi i percorsi riapplicherebbero i soli comandi accettati. Coperto da `test_05_3_2_un_ordine_respinto_lascia_traccia_negli_annunci`, vista fallire togliendo la registrazione.

**Seconda cosa mancante: il tocco sintetizzato su una griglia scorrevole — un difetto vero trovato e corretto, la prova ancora assente (2026-08-05).**

*Le differenze fra le due schermate, isolate prima di ogni ipotesi.* Sonda in processo su finestra 420×912, entrambe le griglie. **Identici:** la catena delle viste (`VistaX < UIScrollView < UIView < UIDropShadowView < UITransitionView < UIWindow`), i riconoscitori (uno sulla vista, otto sullo scorrevole), il numero di elementi e di `accessibilityElements` (cento e cento), lo zoom (1,0), lo scostamento iniziale (zero), il momento di costruzione (una volta all'apertura). **Diversi:** l'altezza della porzione visibile — mappa 547,3 punti, battaglia **439,7**, cioè 108 in meno, occupati dalla colonna del deck che in campagna non esiste; il contenuto — mappa 664×664, battaglia 696×584; e ciò che è disegnato sotto la porzione visibile — in campagna un `UIButton` dei comandi globali, in battaglia una `TesseraDeck`.

*Il difetto trovato, e corretto.* Selezionare una tessera del deck ne faceva crescere il valore di una riga, perché vi si aggiunge il termine «selezionato» (02 §8.2): la tessera passava da 112 a **130** punti di altezza, la colonna del deck cresceva di diciotto e la griglia — che le cede spazio (RDA-50, S3) — perdeva altrettanto di porzione visibile. Misurato: l'intestazione del deck passa da y=515,7 a y=497,7 per la sola selezione; la cella di riga 8 colonna 1 ha il centro a y=502, ed era dentro la porzione visibile prima e fuori dopo, mentre la cornice riportata dall'accessibilità restava (44, 472, 60, 60) perché è la posizione nel CONTENUTO. **Chi toccava dove la cella era annunciata non toccava la cella, e accadeva esattamente nel passo fra il selezionare e il piazzare.** Non è un difetto di collaudo: è un difetto del gioco, e sul piano dove i tester stanno giocando.

*La correzione.* `TesseraDeck` riserva l'altezza del proprio stato più lungo con un'etichetta invisibile che porta il valore come sarebbe da selezionata (`valoreDiRiserva`, prodotto da `CostruttoreAnnunci.valoreElementoDeck(indice:comeSelezionato:)`). L'altezza riservata è quella che servirà e non una costante, sicché si adatta alle taglie d'accessibilità; il testo disegnato continua a dire quanto la voce annuncia, e una prova lo pretende. Prove rosse prima della correzione: `StabilitaDellaDisposizioneTest.test_00_1_2_selezionare_una_tessera_non_muove_la_griglia` (porzione visibile da 421,7 a 439,7) e `test_02_8_2_la_tessera_non_cambia_altezza_quando_e_selezionata` (da 130 a 112 punti).

*Ipotesi escluse, con la prova.* (a) Il riconoscitore: `hitTest` restituisce `VistaGriglia` ed `elemento(sotto:)` risolve. (b) `delaysContentTouches`: portato a falso senza effetto, modifica ritirata. (c) La cornice fuori vista per SOLO scorrimento: esclusa per la battaglia, dove scorrere non bastava — ed è così che si è arrivati alla disposizione che si muove.

*Che cosa resta aperto.* Nemmeno con la disposizione ferma il tocco sintetizzato da XCUITest riesce a schierare: una cella della zona arretrata non entra INTERAMENTE nella porzione visibile — la sua cornice sconfina sotto la colonna del deck — e sei tentativi di scorrimento non ne portano alcuna interamente in vista. Se ciò dipenda soltanto dalla geometria della griglia da cento celle su schermo piccolo, o da altro, **non è accertato**.

**Perché è registrato qui e non nascosto in una prova indebolita.** Le due prove sono state tolte, non adattate fino a passare. Una prova che passa senza verificare è peggio di una prova assente, perché la sua assenza almeno si vede.

**Che cosa NON è stato dichiarato coperto.** L'ordine di lettura attraverso XCUITest: misurato che `XCUIApplication.descendants` percorre la gerarchia delle viste e ignora `accessibilityElements` — sulla mappa piccola i comandi globali compaiono agli indici 6–9, prima delle sedici caselle. L'ordine effettivo resta verificato dalle prove ospitate, che leggono `accessibilityElements`, e l'impianto d'interfaccia verifica invece la COMPLETEZZA dell'albero.
