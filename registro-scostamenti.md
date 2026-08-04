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

## P6 — Punto aperto: chi è sconfitto quando l'annientamento è simultaneo

Emerso dall'accertamento sugli esiti degli scontri (build 6), non da una prova fallita: è il solo punto in cui le due parti non sono trattate allo stesso modo.

**Che cosa non è normato.** 01 §15.2.3 chiude la battaglia «quando uno dei due è stato annientato» e 01 §15.2.2 esclude gli esiti in parità, ma nessuno dei due punti dice che cosa accada quando l'ultimo reparto di ciascuna parte cade nel medesimo giro di mischia — caso raggiungibile, e reso un poco più probabile dall'accerchiamento di 01 §9.10.2, che accresce i danni.

**Come si comporta oggi.** La verifica delle condizioni di chiusura esamina le due parti in ordine fisso e dichiara sconfitta la prima che si trova senza nulla in campo e senza nulla nel mazzo: essendo il giocatore il primo dell'ordine, in caso di annientamento simultaneo risulta sempre sconfitto lui. Il comportamento è deterministico e riproducibile, ma discende dall'ordine di un'enumerazione e non da una decisione di progetto.

**Che cosa si è fatto e che cosa no.** Si è fissato il comportamento con una prova dedicata (`AccertamentoScontriTest.test_01_15_2_3_annientamento_simultaneo_esito_deterministico_e_dichiarato`), così che non possa cambiare in silenzio. NON si è cambiato quale parte risulti sconfitta: scegliere fra il giocatore, l'avversario e una terza via è una decisione di progetto che spetta al titolare, e prenderla qui significherebbe deciderla al suo posto. Non è stata registrata fra i vantaggi nascosti di 01 §13.2 perché va contro il giocatore e non a suo favore.

**Che cosa serve dal titolare.** Una riga in 01 §15.2.3 che dichiari l'esito del caso simultaneo. Fino ad allora vale il comportamento fissato dalla prova.

## P7 — Precisazione: l'efficacia entra anche nella voce di ingaggio

02 §9.2.1 prescrive che, per le azioni con bersaglio, la voce del pannello annunci «il bersaglio con nome e lettera, l'efficacia e ogni costo». Fino alla versione 2.2 dei testi la sola voce di tiro dichiarava l'efficacia; quella di ingaggio dava nome, lettera e posizione, e non l'efficacia — pur valendo per la mischia il medesimo accoppiamento offesa-protezione (01 §9.9.2). Realizzazione: le due voci hanno ora lo stesso ordine fisso di informazioni, chiuso in 02 §9.3.1. Non è uno scostamento dall'architettura ma il colmarne un'omissione, ed è stato fatto nella stessa tranche dei due modificatori perché tocca le medesime frasi.

## Nessuno scostamento strutturale

Nessun punto dell'architettura è risultato irrealizzabile o errato nella fase A: i confini dei bersagli, il giornale con istantanee, l'impronta canonica, la virgola fissa e la catena dei testi esterni funzionano come dichiarato. I documenti 00–05 non richiedono modifiche.
