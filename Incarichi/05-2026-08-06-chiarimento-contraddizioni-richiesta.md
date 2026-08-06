# Richiesta di chiarimento — Contraddizioni e imprecisioni della sessione precedente

Documento operativo per una sessione di Claude Code nella cartella di progetto. Da consegnare come primo messaggio della sessione. Archivialo verbatim in Incarichi/ prima di rispondere.

Questa non è una richiesta di lavoro. È una richiesta di chiarimento su affermazioni già fatte. Non modificare codice, prove, script, dati o documenti, con la sola eccezione dichiarata nella parte finale sulle memorie. Se mentre rispondi individui un difetto, dichiaralo e non correggerlo: la correzione sarà oggetto di un incarico proprio, e correggere mentre si spiega rende impossibile distinguere ciò che era vero prima da ciò che hai cambiato dopo.

Rispondi punto per punto, nell'ordine in cui sono scritti, senza preamboli e senza formule di cortesia.

## Che cosa non torna, e va chiarito

Primo. Alla domanda se qualcosa fosse in esecuzione hai risposto di no, elencando cinque nomi cercati e non trovati, e nello stesso momento la riga di stato dichiarava una finestra di comando ancora in esecuzione. Le due affermazioni non possono valere insieme.

Elenca ogni finestra di comando che risulta ancora aperta: quale comando contiene, con che riga esatta è stata lanciata, quando, se il processo corrispondente sia vivo o concluso, e con quale codice di uscita se è concluso. Se una finestra risulta aperta ma vuota, dillo e spiega che cosa la tiene aperta.

Poi rispondi a questa domanda, che è quella che conta: il controllo che hai eseguito cercava cinque nomi di programma, non la presenza di attività. Un comando con un nome diverso da quei cinque sarebbe passato inosservato. Dichiara se sia così. Se lo è, dichiara qual è invece il controllo che risponde davvero alla domanda posta, e da questo momento usa quello. Un controllo che verifica una forma anziché il fatto è precisamente la classe di errore che questo progetto ha già pagato tre volte con i documenti consegnati, ed è la ragione per cui esiste il criterio dei cancelli.

Secondo. Nell'incarico che hai ricevuto per la sessione precedente le sezioni portavano un numero, e nel corpo del testo alcuni rimandi puntavano a quei numeri. Nella copia effettivamente incollata nel terminale i numeri delle sezioni erano assenti, mentre i rimandi nel corpo li citavano ancora: almeno tre riferimenti puntavano quindi a sezioni che nel testo ricevuto non esistevano.

Dichiara se te ne sei accorto. Se te ne sei accorto e non l'hai segnalato, dichiara perché. Se non te ne sei accorto, dichiara come hai risolto quei rimandi, cioè se hai dedotto a quali sezioni si riferissero e su quale base, oppure se li hai semplicemente attraversati senza fermarti. La domanda non è retorica e non serve a rimproverarti: serve a sapere se un rimando rotto in un incarico produca un silenzio o una segnalazione, perché nel primo caso ogni incarico futuro va scritto diversamente.

La regola per il futuro è questa, e vale da subito. Un incarico che contenga un riferimento irrisolvibile, una contraddizione interna, o una premessa che i documenti non confermano, va segnalato prima di cominciare e non dopo. È già accaduto due volte che un incarico contenesse una premessa errata, e in entrambi i casi la condotta corretta è stata contestarla con il riferimento documentale in mano.

Terzo. Riporta i numeri della sessione precedente ciascuno con lo strumento che lo ha prodotto e il comando esatto che lo stampa: quante sessioni complete passano ora per l'interfaccia e su quante generate, il costo della singola sessione, il costo complessivo del collaudo prima e dopo l'intervento, e i conteggi delle prove del pacchetto, ospitate e d'interfaccia. Per ciascuno dichiara se provenga da uno strumento o sia stato contato a mano. I numeri contati a mano vanno marcati come tali nel punto in cui compaiono.

Se un numero richiesto dall'incarico non è stato misurato, dillo. Il costo della singola sessione era stato richiesto in tre incarichi consecutivi e non risulta misurato in nessuno dei primi due: dichiara se sia stato misurato in quello appena concluso, e con quale strumento.

Quarto. Dichiara lo stato del caricamento su TestFlight. Se la build è stata caricata, dichiara quale numero di build, a che ora, verificata come, e se il registro delle build caricate e i server di Apple concordino in entrambi i versi. Se non è stata caricata, dichiaralo esplicitamente e spiega perché, dato che l'incarico lo prevedeva alla condizione che la sezione sulle sessioni complete fosse chiusa e il collaudo verde, condizione che a quanto affermi si è verificata.

Quinto. Dichiara lo stato delle quattro questioni di impianto che l'incarico chiedeva di chiudere, una per una e senza attenuazioni: le sessioni complete per l'interfaccia, il manifest dei testi, il conteggio delle prove prodotto da uno strumento, e la cella della zona arretrata che non entra nella porzione visibile. Per ciascuna: chiusa, aperta, o parzialmente chiusa con che cosa resta fuori. Per quelle chiuse con un controllo nuovo, dichiara se il controllo sia stato visto rifiutare almeno una volta e riporta l'uscita del rifiuto.

Sesto. Elenca tutto ciò che nella sessione precedente hai fatto e che l'incarico non chiedeva, e tutto ciò che l'incarico chiedeva e che non hai fatto. Entrambe le liste, anche se vuote, vanno scritte esplicitamente.

## Le memorie

Aggiorna il file di memoria del progetto perché quanto segue valga in ogni sessione futura senza doverlo riscrivere in ogni incarico. Se un file di memoria di progetto non esiste, crealo; se esiste, integralo senza cancellare quanto già contiene, e riporta nel resoconto il percorso del file e le righe aggiunte.

Le voci da scrivere. Che a una domanda sullo stato dell'esecuzione si risponde verificando le finestre di comando aperte e non un elenco di nomi di programma. Che ogni numero riferito in un resoconto o in una risposta porta il nome dello strumento che lo ha prodotto, e che i numeri contati a mano o ricordati vanno marcati come tali nel punto in cui compaiono. Che un incarico con un riferimento irrisolvibile, una contraddizione interna o una premessa non confermata dai documenti va segnalato prima di cominciare, citando documento e punto. Che quando una risposta e uno stato osservabile si contraddicono, si dichiara la contraddizione invece di riportare soltanto il ramo che si è verificato. Che ciò che non è stato verificato si dichiara non verificato nel punto in cui compare, e che uno scostamento dichiarato vale più di un'affermazione tornante.

Insieme alle voci, scrivi nello stesso file questa avvertenza. Una regola scritta in un file di memoria è una prescrizione, ed è la forma di protezione che in questo progetto viene disattesa con regolarità, mentre i controlli che rifiutano non lo sono mai. Queste voci valgono quindi come promemoria e non come garanzia, e nessuna di esse va considerata un problema risolto.

Per ciascuna delle cinque voci, dichiara nel resoconto se esista o possa esistere un controllo che rifiuti lo stato sbagliato anziché vietarlo. Dove esiste, dichiara qual è. Dove non esiste, dichiara che cosa sarebbe e quanto costerebbe, senza realizzarlo.

## Che cosa non devi fare

Non modificare codice, prove, script, dati o documenti consolidati. L'unica scrittura ammessa è quella al file di memoria richiesta sopra.

Non correggere alcun difetto che dovessi individuare rispondendo: dichiaralo e fermati.

Non compilare, non eseguire il collaudo, non caricare nulla, salvo quanto serva a rispondere a una domanda specifica di questo documento, e in tal caso dichiara che cosa hai eseguito e perché.

Non cancellare i rami di lavoro locali già fusi: restano dove sono.

Non riaprire alcuna decisione presa e non proporre alternative a quanto stabilito.

Non attenuare, non giustificare e non premettere considerazioni generali alle risposte. Dove la risposta è che hai sbagliato, la risposta è che hai sbagliato.

## Come rispondere

In registro tecnico, con i nomi reali di file, tipi, funzioni, prove, comandi e identificativi di commit. Nessuna semplificazione per lettori non tecnici, nessuna analogia esplicativa, nessun preambolo.

Ogni affermazione fattuale porta il proprio riferimento verificabile. Ogni numero porta lo strumento che lo ha prodotto, comprese le risposte a questo documento. Ciò che non sei in condizione di verificare va dichiarato non verificato nel punto in cui compare, e ciò che non ricordi va dichiarato non ricordato anziché ricostruito.

Archivia questa richiesta e la tua risposta verbatim in Incarichi/. Le risposte già archiviate non si modificano mai: le correzioni si scrivono altrove.
