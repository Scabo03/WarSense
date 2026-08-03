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

## Nessuno scostamento strutturale

Nessun punto dell'architettura è risultato irrealizzabile o errato nella fase A: i confini dei bersagli, il giornale con istantanee, l'impronta canonica, la virgola fissa e la catena dei testi esterni funzionano come dichiarato. I documenti 00–05 non richiedono modifiche.
