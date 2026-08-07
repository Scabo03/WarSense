Incarico — Sistemazione del versionamento e pulizia del repository
Documento operativo per una sessione di Claude Code nella cartella di progetto. Da consegnare come primo messaggio della sessione. Archivialo verbatim in Incarichi/ prima di cominciare, verifica che il file esista e non sia vuoto dopo averlo scritto, e aggiungi la riga corrispondente all'indice.
Questa è una sessione di sola manutenzione del versionamento. Non modificare codice, prove, dati, testi o documenti consolidati. Non caricare alcuna build. Non toccare versioni né certificati. Se individui un difetto del gioco mentre lavori, dichiaralo e non correggerlo.
Perché esiste
Le sessioni precedenti hanno committato e fuso sul ramo principale senza mai spingere sul server remoto, dichiarandolo ogni volta e coerentemente fra loro, perché nessun incarico l'aveva chiesto. Il risultato è che il codice che ha prodotto le build distribuite su TestFlight esiste soltanto sulla macchina locale. È un fatto irripetibile: se quella macchina si guasta, le build restano sui server di Apple e nessuno può più risalire al codice che le ha prodotte.
Sono inoltre rimasti sul locale numerosi rami di lavoro già fusi, che le sessioni precedenti avevano lasciato in piedi per indicazione del titolare. L'indicazione è ora rovesciata: vanno rimossi.
Che cosa devi ottenere
Accerta e riporta lo stato del versionamento prima di toccare alcunché: quale sia il server remoto configurato, se esista e sia raggiungibile, di quanti commit il ramo principale locale sia avanti rispetto a quello remoto, e quali rami esistano in locale e in remoto. Riporta ciascun dato con il comando che lo produce.
Spingi il ramo principale sul server remoto. Verifica dopo la spinta che il ramo locale e quello remoto coincidano esattamente, riportando il comando che lo accerta. Se la spinta fallisce per una ragione qualunque, dichiarala e non proseguire oltre finché non è chiarita: è il punto per cui questa sessione esiste e non va aggirato.
Verifica che tutte le etichette e i riferimenti che il progetto usa siano anch'essi sul remoto, se ne esistono.
Elenca i rami di lavoro locali. Per ciascuno accerta se sia interamente contenuto nel ramo principale, cioè se non contenga alcun commit che il principale non abbia, e riporta l'esito ramo per ramo con il comando che lo produce. Cancella quelli interamente contenuti. Non cancellare alcun ramo che contenga anche un solo commit non presente sul principale: dichiaralo e lascialo dove sta, spiegando che cosa contiene.
Verifica se esistano commit locali su rami non fusi, lavoro non committato, o file esclusi dal versionamento che dovrebbero invece esservi. Riporta l'esito.
Verifica che nulla di ciò che non deve stare nel repository vi sia finito, in particolare credenziali, chiavi, profili di firma, artefatti di compilazione e cartelle di uscita del collaudo. Se qualcosa di simile risulta versionato, dichiaralo e non rimuoverlo di iniziativa, perché rimuovere qualcosa dalla storia è un'operazione che il titolare deve autorizzare.
Verifica infine che il file di esclusione del repository copra quanto serve, e integralo se mancano voci evidenti, dichiarando quali hai aggiunto.
La regola nuova, da rendere permanente
Da questo momento vale in ogni sessione: si lavora sul ramo dedicato, si committa, si fonde sul principale soltanto ciò che è completo e verde, e si spinge sempre, tanto il principale quanto il ramo dedicato. La spinta non è facoltativa e non si rinvia alla sessione successiva. Se un caricamento su TestFlight è avvenuto, la spinta è obbligatoria prima di chiudere la sessione. I rami già fusi si cancellano quando non servono più.
Scrivi questa regola in forma-dei-resoconti.md, che è il file di memoria permanente del progetto, integrandolo senza cancellare quanto già contiene, e riporta le righe aggiunte.
Dichiara inoltre se esista un modo di rendere la spinta un controllo che rifiuta anziché una prescrizione scritta, per esempio un rifiuto dello script di caricamento quando il ramo principale locale è avanti rispetto al remoto. In questo progetto le prescrizioni vengono disattese e i controlli che rifiutano no. Se il controllo è realizzabile a costo contenuto, realizzalo e fallo fallire almeno una volta di proposito, riportando l'uscita del rifiuto. Se non lo è, dichiara perché e non forzarlo.
Che cosa non devi fare
Non modificare codice, prove, dati, testi o documenti consolidati. L'unica scrittura ammessa fuori dal versionamento è quella a forma-dei-resoconti.md, all'indice degli incarichi, all'eventuale file di esclusione, e all'eventuale controllo sulla spinta.
Non riscrivere la storia del repository in alcuna forma, non fondere alcunché, non spostare commit.
Non cancellare rami che contengano lavoro non presente sul principale.
Non rimuovere dalla storia file già versionati, nemmeno se non dovrebbero esserci.
Non caricare alcuna build, non toccare le versioni, non toccare alcun certificato.
Non correggere alcun difetto del gioco che dovessi individuare: dichiaralo e fermati.
Al termine
Resoconto in registro tecnico, con i nomi reali di rami, comandi e identificativi di commit, senza preamboli e senza semplificazioni per lettori non tecnici. Ogni numero e ogni esito porta il comando che lo produce.
Dichiara esplicitamente lo stato finale: che il principale locale e quello remoto coincidono, quali rami sono stati cancellati, quali sono stati conservati e perché, e che cosa resta non allineato se qualcosa resta.
Elenca separatamente ciò che hai fatto e che l'incarico non chiedeva, e ciò che l'incarico chiedeva e non hai fatto, anche se una delle due liste è vuota.
Committa e spingi il lavoro di questa sessione, applicando da subito la regola che essa introduce.
Archivia il resoconto verbatim in Incarichi/ accanto a questo incarico, verifica che il file esista e non sia vuoto dopo averlo scritto, e aggiungi la riga corrispondente all'indice.
