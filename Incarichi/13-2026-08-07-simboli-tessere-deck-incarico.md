Incarico — I simboli delle tessere del deck
Che cos'è questo documento
È il primo messaggio di una sessione nuova, che non conserva memoria delle precedenti. Contiene tutto il contesto necessario e non richiede altre istruzioni. Leggilo per intero prima di eseguire qualunque comando. Archivialo verbatim in Incarichi/ prima di cominciare, verifica che il file esista e non sia vuoto dopo averlo scritto, e aggiungi la riga corrispondente all'indice.
Leggi inoltre, prima di cominciare, forma-dei-resoconti.md, il registro delle decisioni architetturali con particolare attenzione alle voci sul deck a riquadri e sulla sigla testuale, e i documenti consolidati sul progetto del gioco e sull'accessibilità per quanto riguarda archetipi, assetti e deck.
Che cos'è il progetto
WarSense è un videogioco gestionale e strategico militare a turni, in Swift puro per iOS e iPadOS, la cui priorità assoluta e non negoziabile è la completa utilizzabilità senza vedere lo schermo, tramite VoiceOver. Il gioco è però pensato anche per giocatori ipovedenti che usano VoiceOver come supporto e non come unico canale, e per giocatori vedenti: ciò che si vede e ciò che si sente devono coincidere.
I documenti consolidati sono la carta dei principi non negoziabili, il progetto del gioco, l'accessibilità, i dati e l'architettura tecnica. La carta prevale su tutto, e al suo interno prevale il numero più basso: il principio 1, cioè la parità di accesso per chi non vede, prevale su qualunque altra considerazione. I consolidati sono fermi a prima della fase D e il riallineamento avverrà in una sessione dedicata.
A che punto è
Esiste un gioco funzionante distribuito su TestFlight, versione di marketing 1.1.0, build 18, versione dei valori 0.7.0. Il ramo principale è a b11b2a8, albero pulito, allineato con il remoto.
Il deck è stato rifatto in una sessione recente: è una riga sola che scorre lateralmente, con tessere a riquadro di circa sessantacinque per cinquantasei punti, contenenti al centro un segnaposto testuale, cioè la sigla dell'archetipo di una o due lettere, il nome scritto in piccolo, e due quadratini negli angoli inferiori con il numero di atomi e il volume. La sigla è iscritta fra i valori provvisori proprio perché destinata a essere sostituita dai simboli grafici, ed è questa sessione a sostituirla.
Che cosa devi ottenere
Il titolare vuole simboli grafici veri al posto delle sigle, curati e ben fatti, prodotti interamente dentro la sessione senza che lui debba procurarsi nulla dall'esterno e senza alcunché a pagamento.
I simboli devono rappresentare l'archetipo in modo immediatamente riconoscibile, nella direzione indicata dal titolare: oggetti che dicono il mestiere del reparto, per esempio un'arma, un arco, uno scudo, la testa di un cavallo, e simili. Non ritratti di truppe, non scene, non illustrazioni: segni netti che si leggano a cinquanta punti di lato.
Come vanno realizzati
Come forme vettoriali descritte in file di testo, nello stesso formato con cui sono fatti i simboli di sistema, scritte a mano nella sessione. Si ridimensionano senza perdita, pesano poco, e non richiedono di scaricare nulla.
Non recuperare librerie, pacchetti di icone, insiemi di simboli o risorse grafiche dalla rete, e non installare strumenti a questo scopo. Un simbolo scaricato porta con sé una licenza da verificare e il progetto non ne ha bisogno; la ricerca di strumenti consumerebbe inoltre la sessione senza produrre le tessere. Se ritieni che il risultato non sia raggiungibile scrivendo le forme a mano, dichiaralo e fermati invece di aggirare il vincolo.
Disegnali in una forma sola che prenda il colore da fuori, e non con colori scritti dentro il simbolo. Il colore non deve portare informazione da solo: due simboli che si distinguano per il colore sono inutili a chi vede poco, e il progetto ha giocatori ipovedenti fra i destinatari dichiarati. Se due archetipi si somigliano, devono distinguersi per la forma.
Verifica che ciascun simbolo resti leggibile alla dimensione reale della tessera, in chiaro e in scuro, e con il contrasto aumentato. Riporta come l'hai verificato.
Gli assetti misti, che vanno accertati prima di disegnare
Il gioco prevede reparti di assetto misto, che si annunciano con il nome dell'assetto e mai con l'elenco dei loro componenti, perché enumerare la composizione renderebbe ogni voce del deck una frase lunga e impraticabile da scorrere. Quella regola riguarda la voce; per il simbolo la questione non è mai stata affrontata.
Accerta, prima di disegnare alcunché, quanti assetti esistano effettivamente nei file di dati, quali siano, e se il loro numero sia chiuso o cresca con le fasi storiche e le acquisizioni. Riporta l'elenco con la fonte.
Poi decidi e dichiara come il simbolo si comporta per un assetto misto, scegliendo la strada che il numero accertato rende sostenibile. Se gli assetti sono pochi e chiusi, disegna un simbolo proprio per ciascuno. Se sono molti o aperti, adotta una regola di composizione che non richieda un disegno nuovo per ogni combinazione, per esempio il simbolo dell'archetipo prevalente con un segno che dichiari la mistione, e realizzala come regola e non come elenco. Dichiara la scelta con la ragione e registrala.
Vale in ogni caso che il simbolo non deve tentare di rappresentare la composizione: ciò che vale per la voce vale per il segno, e un riquadro di cinquanta punti che mostrasse tre cose diverse non sarebbe leggibile.
Che cosa non deve cambiare
L'annuncio della tessera resta esattamente quello di oggi: archetipo o nome di assetto, numero di atomi, volume, e l'indicazione di rinforzo quando ricorre. Verificalo con una prova che confronti l'etichetta prima e dopo la modifica.
Il simbolo è decorazione visiva e non deve essere leggibile dalla sintesi vocale in alcuna forma, come già la sigla che sostituisce. L'elemento accessibile della tessera resta uno solo. Lo stesso vale per i due quadratini negli angoli.
La geometria della tessera e l'altezza della banda del deck non cambiano: il deck resta una riga sola e la griglia conserva l'altezza minima garantita, che è la correzione di un difetto grave e non va toccata. Se un simbolo non entra nello spazio disponibile, si rimpicciolisce il simbolo e non si allarga la tessera.
L'altezza riservata alla tessera resta quella del suo stato più lungo: selezionare una tessera non deve farla crescere né spingere in giù ciò che le sta sotto.
Ogni tessera deve continuare a superare la prova di raggiungibilità dal proprio centro, e a rispettare la dimensione minima toccabile.
Come si lavora in questo progetto
In questo progetto le regole scritte vengono disattese sistematicamente, mentre i controlli che rifiutano non lo sono mai. Un requisito nuovo non si introduce scrivendolo in un documento, si introduce con qualcosa che rifiuta. Un cancello che non si è mai visto rifiutare non è un cancello e va fatto fallire di proposito.
Qui il controllo naturale è che ogni archetipo abbia il proprio simbolo e che nessun simbolo resti orfano: realizzalo in modo che un archetipo aggiunto senza simbolo non compili o faccia fallire una prova, e fallo fallire una volta di proposito togliendo un simbolo. È la stessa forma di protezione già usata per la copertura del formato di salvataggio.
Valgono inoltre: piena delega e nessuna domanda fino al resoconto finale, salvo credenziali mancanti e operazioni che potrebbero incidere su certificati esistenti; non lasciare parti a metà; nessuna stringa nel codice e nessun numero di gioco fuori dai file di dati; ogni prova intestata alla regola numerata che verifica; nessun canale che esista soltanto per il collaudo; nessuna prova indebolita per farla passare.
Se una qualunque prescrizione di questo incarico contraddice un documento consolidato, prevale il consolidato: dichiara la contraddizione citando documento e punto, e comportati secondo il consolidato. Se un rimando è irrisolvibile, o se una condizione ammette più letture, segnalalo prima di cominciare e non dopo aver scelto in silenzio.
Come impiegare la macchina
La macchina è un MacBook Pro con processore Silicon M5 Pro e ventiquattro gigabyte di memoria, e va usata per intero. Ricorri a sottoagenti in parallelo ogni volta che due parti del lavoro non dipendono l'una dall'altra, e a più simulatori in parallelo quando servono più corse indipendenti. Se non è possibile tenere attivi due simulatori identici, usane uno di telefono e uno di tavoletta.
Il disegno dei simboli è lavoro indipendente simbolo per simbolo e si presta al parallelismo: usalo.
Le misure di tempo non si prendono mai in parallelo e vanno dichiarate prese in isolamento.
Il versionamento
Si lavora sul ramo dedicato, si committa, si fonde sul principale soltanto ciò che è completo e verde, e si spinge sempre sul remoto, tanto il principale quanto il ramo dedicato. La spinta è obbligatoria prima di chiudere la sessione, e a maggior ragione se un caricamento su TestFlight è avvenuto. I rami fusi si cancellano. Verifica e dichiara al termine che il principale locale e quello remoto coincidono, riportando il comando che lo accerta.
Che cosa non devi fare
Non scaricare, installare o recuperare dalla rete alcuna libreria grafica, insieme di icone o risorsa visiva, e non installare strumenti a questo scopo.
Non introdurre colori che portino informazione, e non distinguere due archetipi per il colore.
Non rendere leggibili dalla sintesi vocale i simboli, le sigle o i quadratini.
Non cambiare l'annuncio della tessera.
Non modificare la geometria della tessera, l'altezza della banda del deck o l'altezza minima garantita alla griglia.
Non introdurre archetipi nuovi: l'elenco è chiuso a nove.
Non introdurre termini nuovi nel vocabolario chiuso: se ne servisse uno, dichiaralo e fermati.
Non estendere il perimetro del gioco: nessuna marcia di più giorni, nessuna revoca, nessuna marcia forzata, nessun rifornimento, nessuna stagione, nessun avversario sulla mappa, nessuna risoluzione di fine giornata, nessun passaggio dalla campagna alla battaglia.
Non intervenire sul corpo a corpo e non tarare alcun valore di gioco.
Non intervenire sulla cornice riportata dall'accessibilità né sulla prova di raggiungibilità.
Non toccare la versione di marketing. Non creare bersagli firmabili, identificatori di pacchetto o profili nuovi. Non creare, revocare o modificare alcun certificato.
Il caricamento
Se il lavoro è chiuso e l'intero collaudo è verde, carica la build: il titolare deve poter vedere le tessere nella forma nuova e verificare che l'annuncio non sia cambiato.
Valuta e dichiara esplicitamente se la versione dei valori vada incrementata: se cambia soltanto la rappresentazione visiva e nessuna regola incide sul modo in cui una partita in corso si svolgerebbe, dichiara che non si incrementa e perché. La valutazione non va lasciata per omissione.
Verifica per interfaccia di programmazione che la build risulti caricata e valida, sul treno più alto e assegnata al gruppo di test, e che il registro delle build concordi con i server in entrambi i versi. Verifica che il cancello sull'esito della corsa separata delle sessioni complete sia soddisfatto e che quello sulla spinta non rifiuti.
Rigenera le due note. Nella nota per il titolare dichiara in linguaggio non tecnico che le sigle sono state sostituite dai simboli, che cosa rappresenta ciascuno, e che l'annuncio a voce non è cambiato.
Al termine
Togli la sigla testuale dall'elenco dei valori provvisori, poiché non è più un segnaposto, e registra nel registro delle decisioni architetturali la forma dei simboli e la regola adottata per gli assetti misti.
Resoconto in registro tecnico, con i nomi reali di file, tipi, funzioni, prove, comandi e identificativi di commit, senza analogie esplicative, senza preamboli e senza semplificazioni per lettori non tecnici.
Metti in testa al resoconto l'elenco dei nove archetipi con la descrizione in parole del simbolo assegnato a ciascuno, e l'esito dell'accertamento sugli assetti. È il dato su cui il titolare giudicherà, e deve poterlo leggere senza guardare lo schermo.
Ogni numero porta lo strumento che lo ha prodotto. Nessun numero calcolato a mente. Rifà l'aritmetica di ogni tabella e verifica che i totali pareggino le righe.
Ciò che non hai verificato va dichiarato non verificato nel punto in cui compare. Elenca separatamente ciò che hai fatto e che l'incarico non chiedeva, e ciò che l'incarico chiedeva e non hai fatto, anche se una delle due liste è vuota.
Archivia il resoconto verbatim in Incarichi/ accanto a questo incarico, verifica che il file esista e non sia vuoto dopo averlo scritto, e aggiungi la riga corrispondente all'indice.
