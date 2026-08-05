# Incarico — Sessioni complete nel collaudo, manifest dei testi, conteggio delle prove, e la cella che non entra

Documento operativo per una sessione di Claude Code nella cartella di progetto. Da consegnare come primo messaggio della sessione. Non richiede altre istruzioni. Archivialo verbatim in Incarichi/ prima di cominciare.

## Stato di partenza, e sua verifica prima di iniziare

Lo stato di partenza atteso è il ramo principale ai commit 5fefd77, e35b61a, c4f7fe8, cd3e7a9, 3bc7b3d, con collaudo verde a 232 prove del pacchetto di cui una saltata, 55 ospitate e 8 d'interfaccia, e nessuna build caricata dopo la 14. Questi numeri provengono dal resoconto della sessione precedente e non sono stati verificati indipendentemente.

Prima di toccare qualunque cosa, verifica che il ramo sia davvero a quei commit, che il collaudo completo sia verde, e che build-caricate.md risulti allineato con App Store Connect. Se una qualunque delle tre condizioni non regge, fermati, dichiara la discrepanza e non procedere oltre finché non è chiarita. È già accaduto che una build esistesse sui server senza che alcun documento la registrasse, e la disciplina nata da quell\'episodio è che una divergenza si dichiara prima di lavorarci sopra.

Se una qualunque prescrizione di questo incarico contraddice un documento consolidato, prevale il consolidato. Non seguire la lettera dell\'incarico contro una regola scritta: dichiara la contraddizione nel resoconto citando documento e punto, e comportati secondo il consolidato. È già accaduto due volte che un incarico contenesse una premessa errata, e in entrambi i casi la condotta corretta è stata questa.

## Le sessioni complete, che vengono prima di tutto

La sezione è stata rinviata due sessioni di seguito: nella prima è stata consegnata con tre sole sessioni passate per l\'interfaccia, nella seconda non è stata aperta affatto. Viene quindi per prima e non per ultima, e nessuna altra sezione di questo incarico va cominciata prima che questa sia chiusa e verde.

La decisione del titolare del progetto è che le sessioni complete restino nel collaudo di ogni caricamento. Il costo in tempo non è un argomento e non va riaperto: sette minuti sono accettabili.

Fa\' passare per l\'interfaccia l\'intero insieme delle sessioni generate, campagna e battaglia, e non un campione. La griglia di battaglia risponde ora al tocco diretto per la stessa porta dell\'attivazione assistiva, quindi il vincolo che escludeva le sessioni di battaglia è caduto.

L\'ostacolo dichiarato dalla sessione precedente è che le sessioni del banco usano collocazioni arbitrarie mentre l\'apertura di una campagna ammette soltanto i tre scenari dichiarati, e che manca l\'inizializzatore per lo scenario di campagna. La sessione precedente afferma che non si tratti di un canale di collaudo ma del completamento di un\'interfaccia esistente. Verifica che sia vero prima di realizzarlo: se il completamento serve soltanto al collaudo, allora è un canale di collaudo e non va aggiunto, e in tal caso dichiaralo e trova un\'altra via. Se serve comunque al gioco, realizzalo e dichiara a che cosa servirà.

Riporta quante sessioni complete passano ora per l\'interfaccia e su quante generate, con il numero prodotto da uno strumento e non contato a mano. Isola e riporta inoltre il costo della singola sessione, che non è stato misurato in nessuna delle due sessioni precedenti benché richiesto in entrambe, e il costo complessivo del collaudo prima e dopo l\'intervento.

Verifica che l\'aggiunta non introduca intermittenza. Una prova che fallisce una volta su venti è peggio di una prova assente, perché insegna a rieseguire invece che a guardare. Se emerge intermittenza, non mascherarla con ripetizioni automatiche: riportala e isolane la condizione.

## Il manifest dei testi

È oggi l\'unico artefatto di contenuto che nessuna prova verifica, mentre quello dei valori è protetto. Le impronte vengono lette dal caricatore dei testi e mai confrontate.

Chiudi il punto, con la prova modellata su quella già esistente per i valori, e con il caricamento dei testi che confronta davvero le impronte che già legge. Trattandosi di una modifica al caricamento dei testi, verifica che nessuna schermata smetta di funzionare quando un\'impronta non corrisponde: il rifiuto deve essere dichiarato e non produrre una schermata rotta o un errore muto.

Fa\' fallire la prova almeno una volta di proposito, alterando un file di testo senza rigenerare il manifest, e riporta l\'uscita.

Verifica inoltre che il controllo non sia vacuo. Se il manifest viene rigenerato dallo stesso comando che esegue la prova, le impronte coincideranno sempre e il controllo non rifiuterà mai nulla. La domanda giusta da porsi è quella che il progetto ha già pagato tre volte: rifiuterebbe un artefatto vero ma vecchio. Se la risposta è no, il controllo va rifatto, non dichiarato attivo.

## Il conteggio delle prove riportato nei resoconti

Nell\'ultima sessione una sonda diagnostica priva di asserzioni era stata committata per errore ed era finita conteggiata fra le prove d\'interfaccia di un resoconto precedente. La correzione spontanea è stata la condotta giusta; la condizione che l\'ha resa possibile va tolta.

Il conteggio delle prove va prodotto da uno strumento e non letto a occhio dall\'esecutore, e deve contare le prove che asseriscono qualcosa, escludendo per costruzione ciò che non asserisce. Se ciò non è realizzabile a costo contenuto, realizza almeno un controllo che rifiuti la presenza nel collaudo di prove prive di asserzioni, e fallo fallire una volta reintroducendo una sonda.

Nessun numero del resoconto va letto a memoria o a occhio: ciascuno proviene da uno strumento, e per ciascuno va dichiarato quale.

## La cella della zona arretrata che non entra nella porzione visibile

Resta aperto in S10 che una cella della zona arretrata non entri interamente nella porzione visibile nemmeno con la disposizione ferma, e che scorrere non basti. Non è accertato se dipenda dalla sola geometria.

Accertalo. Riporta le misure: dimensione del contenuto, dimensione della porzione visibile, posizione della cella, quanto ne resta fuori, e in quali formati e taglie di carattere accessibili il fenomeno si presenta. Se dipende dalla geometria, dichiara quale vincolo geometrico lo produce e quale sarebbe la portata di un rimedio, senza realizzarlo. Se dipende da altro, isola la causa.

Il fenomeno riguarda il gioco e non soltanto il collaudo, perché una cella che non entra è una cella che il dito non può raggiungere. Non intervenire però sulla cornice riportata dall\'accessibilità: quel rimedio tocca la prova di raggiungibilità ed è sospeso in attesa che il titolare verifichi sul dispositivo che cosa accada realmente esplorando al tatto.

## Che cosa non devi fare

Non estendere il perimetro del gioco: nessuna marcia di più giorni, nessuna revoca, nessuna marcia forzata, nessun rifornimento, nessuna stagione, nessun avversario sulla mappa, nessuna risoluzione di fine giornata, nessun passaggio dalla campagna alla battaglia.

Non intervenire sul corpo a corpo. Non tarare alcun valore.

Non intervenire sulla cornice riportata dall\'accessibilità né sulla prova di raggiungibilità, per la ragione della sezione 4.

Non introdurre cancelli sui documenti normativi: la decisione di riallineare i consolidati in una sessione dedicata resta in vigore e non va riaperta.

Non aggiungere canali che esistano soltanto per il collaudo: ciò che una prova legge deve essere ciò che il gioco produce.

Non indebolire una prova per farla passare e non mascherare l\'intermittenza con ripetizioni automatiche. Uno scostamento dichiarato vale più di una prova verde che non verifica.

Non toccare la versione di marketing, che sale soltanto e soltanto su richiesta esplicita del titolare. Non creare bersagli firmabili, identificatori di pacchetto o profili nuovi. Non creare, revocare o modificare alcun certificato, per nessuna ragione.

## Vincoli non rinegoziabili

La carta dei principi prevale su tutto, e al suo interno prevale il numero più basso. Il principio 1 prevale su qualunque altra considerazione.

Nessuna stringa nel codice e nessun numero di gioco fuori dai file di dati. I valori non ancora tarati portano il contrassegno di provvisorietà e sono elencati nel file dedicato.

Ogni prova è intestata alla regola numerata che verifica. Il collaudo dei confini fra i moduli resta attivo. Il collaudo completo resta la sola definizione di tutto e passa da scripts/collaudo-completo.sh.

Ogni invariante conserva il proprio mutante, e la prova che ne pretende l\'esistenza per ciascuno non va indebolita.

Riproduci prima, correggi poi: per ogni difetto va scritta una prova che fallisca sul codice attuale. Ogni controllo introdotto va visto fallire almeno una volta prima di essere considerato attivo, perché un cancello che non si è mai visto rifiutare non è un cancello.

Misura prima, tara poi: ogni valore cambiato va riportato con il numero di prima, quello di dopo e la misura che giustifica il passaggio.

Prima di adottare alternative a quanto stabilito, consulta il registro delle decisioni architetturali.

Lavora sul ramo dedicato e porta sul ramo principale soltanto ciò che è completo e verde.

Piena delega e nessuna domanda fino al resoconto finale, salvo credenziali mancanti e operazioni che potrebbero incidere su certificati esistenti.

Non lasciare parti a metà. Se la capacità della sessione non basta a portare una sezione fino alla sua prova superata, fermati al confine dell\'ultima sezione conclusa e verde e dichiara da dove si riprende. La sezione 1 non è rinviabile: se la sessione può chiuderne una sola, chiude quella.

## Il caricamento

Se la sezione 1 è chiusa e l\'intero collaudo è verde, carica la build e verifica per interfaccia di programmazione che risulti davvero caricata e valida, sul treno più alto e assegnata al gruppo di test. Il tocco diretto sulla griglia di battaglia e la correzione della tessera che cresce non sono ancora arrivati sui dispositivi, e il titolare deve poterli provare.

Verifica che i controlli sulle note accettino i documenti prodotti, che la nota di rilascio descriva la build che stai caricando e non quella precedente, e che il registro delle build caricate risulti allineato con il server in entrambi i versi.

Dichiara esplicitamente la valutazione sulla versione dei valori: se nessuna regola che incide su una partita in corso è cambiata, scrivi che non si incrementa e perché. La valutazione non va lasciata per omissione.

Nella nota per il titolare dichiara, in linguaggio non tecnico, le tre cose che deve provare sul dispositivo e in quest\'ordine: il piazzamento di un reparto dopo aver selezionato una tessera, in particolare sulle celle della fila più arretrata, perché è la cosa che era rotta ed è stata corretta; il tocco diretto su una casella della mappa grande che stia fuori dalla parte visibile, perché il dito non scorre da solo; e che cosa accade esplorando al tatto sopra la zona dei comandi, perché potrebbe trovarvi una casella che lì non è disegnata.

## Al termine

Resoconto in registro tecnico, con i nomi reali di file, tipi, funzioni, prove e identificativi di commit, senza analogie esplicative, senza preamboli e senza semplificazioni per lettori non tecnici. Ogni affermazione fattuale porta il proprio riferimento verificabile; quelle prive vanno marcate come non verificate nel punto in cui compaiono. Nessun numero senza l\'enunciato di ciò che dimostra, nessun numero preso dalla memoria, e per ciascun numero va dichiarato lo strumento che lo ha prodotto.

Dichiara separatamente e senza attenuazioni ciò che non hai fatto, ciò che hai trovato e non hai corretto, e ciò su cui non hai raggiunto certezza. Registra gli scostamenti nuovi nel registro degli scostamenti e aggiorna quelli chiusi.

Archivia il resoconto verbatim in Incarichi/ accanto a questo incarico. I resoconti già archiviati non si modificano mai, nemmeno per correggere un dato risultato sbagliato: la correzione si scrive altrove.
