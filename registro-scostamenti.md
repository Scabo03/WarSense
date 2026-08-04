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

## Nessuno scostamento strutturale

Nessun punto dell'architettura è risultato irrealizzabile o errato nella fase A: i confini dei bersagli, il giornale con istantanee, l'impronta canonica, la virgola fissa e la catena dei testi esterni funzionano come dichiarato. I documenti 00–05 non richiedono modifiche.
