Incarico — Chiusura del lavoro su ricognizione, formazioni non armate e imboscate

Sessione nuova senza memoria delle precedenti. Non c'è nulla di nuovo da costruire: questo incarico chiude un lavoro già fatto e fermo a metà strada.

Archivia questo documento verbatim in Incarichi/ prima di cominciare, verifica che il file esista e non sia vuoto, e aggiorna l'indice.

Prima di cominciare leggi soltanto forma-dei-resoconti.md e il resoconto dell'incarico precedente in Incarichi/, che descrive esattamente il lavoro da chiudere e dove si è fermato. Non aprire altra documentazione se non ti serve per correggere qualcosa di specifico.

Lo stato di partenza

Il ramo principale è a 26d061e, locale e remoto coincidenti. Il lavoro sta in nove commit sul ramo dedicato ricognizione-non-armate-imboscate, dichiarati verdi al livello del pacchetto.

La sessione precedente ha esaurito la propria capacità e si è fermata prima delle corse lunghe. Non sono state eseguite: le prove d'interfaccia sul simulatore, la corsa completa delle sessioni, il caricamento della build, la fusione sul principale e la spinta.

Il punto che va verificato per primo: il codice dell'interfaccia, cioè la schermata della mappa di campagna e il costruttore degli annunci, è stato modificato ma non è mai stato compilato. Non si sa se compili.

Che cosa devi fare

Compila per prima cosa, prima di qualunque corsa lunga, perché è la cosa che può essere rotta e va scoperta subito.

Poi esegui il collaudo completo, comprese le prove d'interfaccia sul simulatore, e la corsa completa delle sessioni, che il cancello del caricamento esige.

Se qualcosa fallisce, correggilo. Il perimetro della correzione è quello del lavoro già fatto: sistema ciò che non compila o non passa, senza aggiungere funzioni, senza cambiare decisioni prese e senza estendere il gioco. Se un fallimento rivelasse un problema di progettazione e non un errore da correggere, dichiaralo e fermati su quel punto invece di inventare una soluzione.

Quando tutto è verde, carica la build, poi fondi il ramo dedicato sul principale, spingi entrambi e cancella il ramo fuso.

Sul caricamento

Incrementa il numero di build. La versione dei valori è già stata portata a 0.11.0 dal lavoro precedente: verifica che sia corretta e dichiara la valutazione invece di lasciarla per omissione.

Verifica per interfaccia di programmazione che la build risulti caricata e valida, sul treno più alto, assegnata al gruppo di test, e che il registro delle build concordi con i server nei due versi. Verifica che i cancelli sulle note, sulla corsa delle sessioni e sulla spinta non rifiutino.

La nota per il titolare è già pronta in nota-per-il-titolare-ricognizione.md: verifica che descriva la build che stai caricando e che superi il proprio controllo, e correggila se non lo fa. Deve dire in linguaggio non tecnico che ora esistono gli esploratori e come si ordina loro di esplorare, che cosa può andare storto, come si tende un'imboscata e come si capisce che è scattata, che cosa sono le formazioni non armate e che cosa si può fare loro, e che le formazioni avversarie hanno ora un proprio segno sulla mappa. Il titolare nella build precedente ha cercato l'esplorazione che non esisteva ancora: la nota deve impedire che accada di nuovo.

Una cosa da verificare e riportare, non da correggere

Il banco ha registrato che i sabotaggi tentati dagli esploratori falliscono trentanove volte su quaranta. Verifica se quel rapporto discenda dalla soglia di protezione delle formazioni e dalla competenza degli esploratori come sono tarate nei dati, oppure se nasconda un difetto, per esempio una competenza che non viene letta o una soglia sempre troppo alta.

Riporta l'esito con i numeri. Se è taratura, non toccarla: i valori sono provvisori e li deciderà il titolare giocando. Se è un difetto, correggilo e dichiaralo.

Il collaudo e la macchina

Tutte le prove del pacchetto, tutte quelle d'interfaccia sul simulatore, e la corsa completa delle sessioni. Nient'altro: non aggiungere prove nuove se non per coprire una correzione che dovessi fare.

Il MacBook ha un M5 Pro e ventiquattro gigabyte. Le corse sono indipendenti fra loro: mandale in parallelo dove puoi, ricorrendo a più simulatori e a sottoagenti. È un invito e non un obbligo, e vale per il lavoro, non per le misure di tempo, che si prendono da sole.

Che cosa non devi fare

Non costruire nulla di nuovo, non aggiungere funzioni, non riaprire decisioni prese.

Non tarare valori di gioco.

Non indebolire una prova per farla passare né mascherare un'intermittenza con ripetizioni automatiche.

Non toccare la versione di marketing, i certificati, i profili o gli identificatori di pacchetto.

Non fondere sul principale nulla che non sia completo e verde.

Se una prescrizione di questo incarico contraddice un documento consolidato, prevale il consolidato: dichiaralo citando documento e punto.

Il versionamento

Fusione del solo verde, spinta di principale e del ramo dedicato, cancellazione del ramo fuso. Verifica al termine che principale locale e remoto coincidano, riportando il comando che lo accerta.

Al termine

Resoconto breve, in registro tecnico, con i nomi reali e i comandi. Deve dire: se l'interfaccia compilava, che cosa hai dovuto correggere e perché, l'esito delle corse, l'esito della verifica sui sabotaggi, e lo stato finale del versionamento e della build.

Ogni numero porta lo strumento che lo ha prodotto. Ciò che non hai verificato va dichiarato tale nel punto in cui compare. Elenca ciò che hai fatto senza che fosse chiesto e ciò che era chiesto e non hai fatto.

Riporta in coda quanto tempo è andato in compilazione, corse del collaudo, corse del simulatore e caricamento.

Archivia il resoconto verbatim in Incarichi/, verifica che il file esista e non sia vuoto, e aggiorna l'indice.
