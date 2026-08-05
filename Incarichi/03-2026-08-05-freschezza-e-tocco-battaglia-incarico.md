# Incarico — Freschezza della nota di rilascio, chiarimento sulla build 13, il tocco in battaglia, e le sessioni complete nel collaudo

Documento operativo per una sessione di Claude Code nella cartella di progetto. Da consegnare come primo messaggio della sessione. Non richiede altre istruzioni. Archivialo in Incarichi/ prima di cominciare.

Lo stato di partenza è il ramo principale ai commit 6b0caf8, 770fcfb, d9a5c82, 2d3c546, f3c8288, eccff63, 26a19e3, 1ae39cf, con collaudo verde a 232 prove del pacchetto, 53 ospitate e 8 d'interfaccia, e la build 14 su App Store Connect.

## La freschezza della nota di rilascio

L'osservazione posta in chiusura della sessione precedente è accolta e diventa il primo intervento di questa.

È la terza volta che lo stesso errore si paga: un documento destinato a chi usa il gioco, protetto da un controllo che ne verifica la forma e non l'attualità, parte descrivendo qualcosa di diverso da ciò che la build contiene. È accaduto con la nota per il titolare, corretto due sessioni fa; è appena accaduto con note-di-rilascio.txt, che al primo caricamento descriveva la build precedente perché il controllo esistente ne verifica la lunghezza e non la freschezza.

Estendi a note-di-rilascio.txt il controllo di freschezza già realizzato in scripts/controlla-nota-titolare.py, cioè la verifica che la nota sia stata aggiornata rispetto all'ultimo commit del codice che ne cambia il contenuto. Non duplicare il codice: se il controllo è generalizzabile ai due documenti, generalizzalo, e dichiara quale forma hai scelto.

Il controllo va agganciato al caricamento e deve rifiutare, non avvertire. Fallo fallire almeno una volta di proposito, con una nota stantia, e riporta l'uscita.

Verifica inoltre se esistano altri documenti consegnati a chi usa il gioco, o altri artefatti prodotti dal caricamento, protetti da un controllo di sola forma. Se ne trovi, elencali senza correggerli.

## Il chiarimento sulla build 13

La build 13 esiste su App Store Connect, caricata il 5 agosto 2026 alle 00:50:41 con scarto di sette ore rispetto al riferimento universale, e nessun documento del progetto la registra. Il resoconto della sessione precedente e esame-critico.md al punto 4.1 affermavano entrambi che l'ultima build fosse la 12.

È la prima discrepanza accertata fra ciò che i documenti dichiarano e ciò che risulta effettivamente sui server di Apple, e riguarda l'unica catena del progetto che nessun controllo interno può verificare.

Accerta e riporta: quali build esistono su App Store Connect, con data di caricamento, versione, stato e treno di appartenenza, lette per interfaccia di programmazione; quale commit corrisponde a ciascuna, se ricostruibile dalla cronologia del versionamento o dai numeri incorporati nell'archivio; e se la 13 sia stata prodotta da una sessione di lavoro, da un caricamento manuale, da un tentativo interrotto o da altra causa.

Se la causa non è accertabile, dichiaralo e non riempirlo con la spiegazione più plausibile.

Verifica poi se esista, o sia costruibile a costo contenuto, un controllo che confronti lo stato registrato nei documenti con quello letto per interfaccia di programmazione, e che rifiuti quando divergono. Se lo è, realizzalo e fallo fallire una volta. Se non lo è, dichiara perché.

Correggi infine i documenti che riportano il dato sbagliato, compreso esame-critico.md al punto 4.1, con l'annotazione di quando e perché la correzione è avvenuta.

## Il tocco diretto sulla griglia di battaglia

È l'ultimo scostamento aperto della famiglia S10 e va chiuso, perché finché la griglia di battaglia non risponde al dito nessuna sessione di battaglia potrà mai passare per l'interfaccia, e resterebbe fuori dalla verifica proprio la metà del gioco che i tester stanno usando.

Lo stato dell'indagine è il seguente. Sulla mappa di campagna il fenomeno è spiegato e chiuso: la cornice riportata dall'accessibilità per una casella fuori dalla porzione visibile è la sua posizione nel contenuto e non sullo schermo, il dito non dispone dello scorrimento automatico che la voce ha, e dopo un solo scorrimento il tocco funziona. In battaglia lo stesso rimedio non funziona: otto tentativi per due vie di scorrimento e il tocco non schiera. Sono già state escluse, con la relativa sonda, l'ipotesi del riconoscitore e quella di delaysContentTouches.

Le due griglie condividono la base VistaACaselle e lo stesso riconoscitore. La differenza è quindi stretta e va isolata prima di formulare rimedi: elenca ciò che distingue le due schermate per quanto riguarda la catena che porta dal tocco all'elemento, cioè gerarchia delle viste, contenitore scorrevole, presenza di elementi sovrapposti, momento in cui gli elementi accessibili vengono costruiti, e stato della schermata al momento del tocco. Riporta l'elenco prima di intervenire, perché è ciò che rende l'indagine ripetibile.

Prima di ogni ipotesi nuova, elenca quelle già escluse e con quale prova.

Quando la causa è isolata, correggi con una prova che fallisca prima, e verifica che il comportamento del fuoco resti quello prescritto e che nessuna prova esistente dipendesse dal comportamento vecchio.

Se la causa non risultasse isolabile in questa sessione, non indebolire nulla per chiudere il punto: aggiorna S10 con ciò che hai escluso, con quale sonda, e con l'elenco delle differenze isolate, che è comunque un avanzamento.

Resta inoltre non verificata e non realizzata la conseguenza possibile già segnalata, cioè che l'esplorazione al tatto possa trovare sopra i comandi una casella lì non disegnata. Richiede il servizio di accessibilità reale, quindi non va indagata qui: verifica soltanto che sia iscritta correttamente in collaudo-solo-dispositivo.md con la portata che avrebbe su RaggiungibilitaTest.

## Le sessioni complete nel collaudo di ogni caricamento

Decisione del titolare del progetto: le sessioni complete restano nel collaudo di ogni caricamento. Sette minuti sono un costo accettabile e non vanno spostati in una corsa separata.

Fa' quindi passare per l'interfaccia l'intero insieme delle sessioni generate, e non le tre attuali, entro il vincolo che la griglia di battaglia risponda al dito: se la sezione 3 non si chiude, includi tutte le sessioni di campagna e dichiara che quelle di battaglia restano fuori per quella ragione.

Isola e riporta il costo della singola sessione, che nella sessione precedente non era stato misurato, e il costo complessivo del collaudo prima e dopo l'intervento.

Verifica che l'aggiunta non introduca intermittenza: una prova che fallisce una volta su venti è peggio di una prova assente, perché insegna a rieseguire invece che a guardare. Se emerge intermittenza, non mascherarla con ripetizioni automatiche: riportala e isolane la condizione.

## Che cosa non devi fare

Non estendere il perimetro del gioco: nessuna marcia di più giorni, nessuna revoca, nessuna marcia forzata, nessun rifornimento, nessuna stagione, nessun avversario sulla mappa, nessuna risoluzione di fine giornata, nessun passaggio dalla campagna alla battaglia.

Non intervenire sul corpo a corpo. Non tarare alcun valore.

Non introdurre cancelli sui documenti normativi: la decisione presa resta in vigore e i consolidati verranno riallineati in una sessione dedicata.

Non aggiungere canali di collaudo che esistano soltanto per il collaudo: ciò che una prova legge deve essere ciò che il gioco produce.

Non indebolire una prova per farla passare e non mascherare l'intermittenza con ripetizioni. Uno scostamento dichiarato vale più di una prova verde che non verifica.

Non toccare la versione di marketing. Non creare bersagli firmabili, identificatori di pacchetto o profili nuovi. Non creare, revocare o modificare alcun certificato.

## Vincoli non rinegoziabili

La carta dei principi prevale su tutto, e al suo interno prevale il numero più basso. Il principio 1 prevale su qualunque altra considerazione.

Nessuna stringa nel codice e nessun numero di gioco fuori dai file di dati.

Ogni prova è intestata alla regola numerata che verifica. Il collaudo dei confini fra i moduli resta attivo. Il collaudo completo resta la sola definizione di tutto e passa da scripts/collaudo-completo.sh.

Ogni invariante conserva il proprio mutante e la prova che ne pretende l'esistenza per ciascuno non va indebolita.

Riproduci prima, correggi poi. Ogni controllo introdotto va visto fallire almeno una volta prima di essere considerato attivo.

Prima di adottare alternative a quanto stabilito, consulta il registro delle decisioni architetturali.

Lavora sul ramo dedicato e porta sul ramo principale soltanto ciò che è completo e verde.

Piena delega e nessuna domanda fino al resoconto finale, salvo credenziali mancanti e operazioni che potrebbero incidere su certificati esistenti.

## Il caricamento

Se le sezioni 1, 2 e 4 sono chiuse e l'intero collaudo è verde, carica la build e verifica per interfaccia di programmazione che risulti valida, sul treno più alto e assegnata al gruppo di test. La sezione 3 non è condizione per il caricamento.

Verifica che entrambi i controlli sulle note, quello sulla nota per il titolare e quello nuovo sulla nota di rilascio, accettino i documenti prodotti in questa sessione, e che la nota di rilascio allegata descriva la build che stai caricando e non la precedente.

## Al termine

Resoconto in registro tecnico, con nomi reali di file, tipi, funzioni, prove e identificativi di commit, senza semplificazioni per lettori non tecnici e senza preamboli. Ogni affermazione fattuale porta il proprio riferimento verificabile; quelle prive vanno marcate come non verificate nel punto in cui compaiono. Nessun numero preso dalla memoria.

Deve riportare: la forma scelta per il controllo di freschezza sulle due note, l'uscita del rifiuto provocato, e l'elenco degli altri artefatti protetti da controlli di sola forma; l'elenco completo delle build esistenti su App Store Connect con data, versione, stato e treno, la corrispondenza con i commit dove ricostruibile, la causa accertata o dichiarata inaccertabile della build 13, e se il controllo di corrispondenza fra documenti e server sia stato realizzato o perché no; l'elenco delle differenze isolate fra le due griglie nella catena dal tocco all'elemento, le ipotesi escluse con la relativa sonda, e la causa trovata con la prova che falliva, oppure lo stato aggiornato di S10; il numero di sessioni complete passate per l'interfaccia, il costo della singola sessione, il costo del collaudo prima e dopo, ed eventuale intermittenza con la sua condizione; versione, numero di build e stato su App Store Connect, oppure la ragione per cui non hai caricato.

Non porre domande prima di quel momento.
