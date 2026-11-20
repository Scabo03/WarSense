Incarico 27 — Check-up dello strumentario, documenti allineati alle decisioni nuove, chiusura dell’incarico 26, ed esplorazione completa dell’interfaccia con VoiceOver

Che cos’è questo documento

È il primo messaggio di una sessione nuova. Leggilo per intero prima di eseguire qualunque comando. Archivialo verbatim in Incarichi con il numero 27 e aggiorna l’indice. Leggi poi forma-dei-resoconti.md e memoria-infrastruttura.md. Le parti sono quattro e vanno eseguite in quest’ordine: il check-up, i documenti, la chiusura dell’incarico 26 con la build 28, l’esplorazione.

Il progetto in breve

WarSense è un gestionale strategico militare a turni in Swift puro per iOS e iPadOS, utilizzabile per intero senza vedere lo schermo tramite VoiceOver. La carta dei principi in Fondamenta prevale su tutto. Il titolare non ha competenze tecniche; i tester sono persone non vedenti che provano su TestFlight.

Lo stato di partenza, da verificare e non dare per buono

Il lavoro è fermo da metà agosto. Il principale è a f7b2941, con la build 27 su TestFlight, versione di marketing 1.1.0 e versione dei valori 0.11.0. Il ramo partite-fino-alla-fine, a 08ef4bf e spinto, contiene l’incarico 26 non concluso: la battaglia sbilanciata corretta e verde al pacchetto, il tasto per chiudere la giornata con la diagnostica, due prove d’interfaccia nuove compilate ma mai viste passare. Nel frattempo sulla macchina sono cambiati macOS, ora Golden Gate, e Xcode, e probabilmente altri strumenti. Prima di toccare qualunque cosa accerta che locale e remoto coincidano su entrambi i rami e che l’albero di lavoro sia pulito. Se trovi altro, fermati e dichiaralo.

I numeri del registro delle decisioni e del registro degli scostamenti sono già usati fino a RDA-140 e S26 sul ramo dell’incarico 26, anche se il principale si ferma prima. Ogni registrazione nuova di questa sessione prende il primo numero libero su qualunque ramo, mai un numero già usato altrove.

Convivenza con gli altri progetti

Sulla stessa macchina il titolare tiene spesso aperti altri progetti in parallelo, con le loro sessioni di Code e i loro simulatori. Non devi disturbarli in alcun modo. Lavora soltanto dentro questa cartella. Non spegnere, azzerare, cancellare o riavviare simulatori che non siano stati creati per WarSense, e non usare mai comandi che agiscono su tutti i simulatori insieme. Non chiudere finestre che non siano di WarSense. Non terminare processi che non hai avviato tu. Non cambiare impostazioni globali della macchina, compreso lo Xcode selezionato per tutto il sistema: se ti serve uno Xcode diverso, indicalo ai tuoi comandi senza cambiare la selezione globale. Non aggiornare in blocco strumenti condivisi: aggiorna soltanto ciò che usa WarSense, e dichiaralo. Tieni i prodotti di compilazione dentro la cartella del progetto. Lo stesso vale per qualunque automazione che agisca sullo schermo. Stasera WarSense è l’unico progetto in esecuzione, quindi l’esplorazione finale può usare a fondo l’applicazione Simulator e più simulatori di WarSense in parallelo; le regole qui sopra restano comunque valide.

Prima parte: il check-up

Inventario. Riporta le versioni effettive di macOS, degli Xcode installati e di quello selezionato, di Swift, dei runtime dei simulatori, di xcodegen, di Python, di gh e di Claude Code, e scrivile in un file nella cartella dell’incarico. Confrontale con quelle con cui il progetto è stato costruito ad agosto, che ricavi dalla memoria di infrastruttura e dalla storia dei commit.

Simulatori dedicati. Oggi il collaudo e la corsa delle sessioni scelgono il primo iPhone disponibile, che può essere lo stesso che sta usando un altro progetto. Crea un iPhone e un iPad riservati a WarSense, con un nome che lo dichiari, sul runtime più recente. Fai in modo che tutti gli script li usino in modo predefinito e li creino da sé se mancano. Lascia la variabile che permette di imporne uno diverso. Il cambiamento va visto funzionare su una corsa vera.

Collaudo di partenza. Sul principale, senza modificare nulla, esegui il collaudo completo e la corsa completa delle sessioni con lo strumentario nuovo, e riportane l’esito. Distingui con cura ciò che fallisce per lo strumentario nuovo da ciò che falliva già. Elenca le avvertenze nuove del compilatore anche se non bloccano.

Aggiornamento. Su un ramo dedicato, check-up-strumentario, porta il progetto allo strumentario nuovo. Correggi ciò che il nuovo Xcode o il nuovo Swift rompono o deprecano. Aggiorna xcodegen e la configurazione del progetto, se serve. Aggiorna l’integrazione continua perché giri su un’immagine compatibile con lo Xcode attuale, e verificane l’esito reale sull’ultimo invio. Verifica che il metodo di caricamento su TestFlight usato dallo script sia ancora supportato, e se non lo è migralo al metodo attuale. In questa parte nessuna modifica alle regole del gioco, ai valori, ai testi o al comportamento: se una correzione ne richiede una, fermati su quel punto e dichiaralo. Non alzare il requisito minimo di sistema né la versione del linguaggio senza una decisione del titolare: se conviene farlo, proponilo nel resoconto con la ragione.

Firma e distribuzione, in sola lettura. Accerta la scadenza del certificato di distribuzione in uso e quella del profilo di WarSense. Accerta che la chiave di App Store Connect funzioni e che il registro delle build concordi ancora con i server di Apple. Valgono per intero i vincoli sui certificati della memoria di infrastruttura: nessun certificato si crea, si revoca o si modifica.

Automazioni. Sulla macchina il titolare ha attivato nuove possibilità di automazione. Accerta quali canali hai davvero a disposizione per guidare e osservare l’app sul simulatore oltre alle prove d’interfaccia classiche. In particolare verifica il servizio VoiceOver delle prove d’interfaccia, XCUIDevice.voiceOverService, che da iOS 27 permette di accendere VoiceOver, spostarne il fuoco e leggere ciò che pronuncia. Verifica anche gli strumenti del simulatore, le verifiche di accessibilità automatiche di Xcode e l’eventuale controllo dello schermo. Prova ciascun canale con una prova minima sui simulatori di WarSense, e riporta che cosa funziona, che cosa no e perché. L’esplorazione della quarta parte si regge su questo accertamento.

Chiusura della prima parte. Quando collaudo completo e corsa delle sessioni sono verdi sul ramo dedicato, fondi su principale, spingi, cancella il ramo e verifica che principale locale e remoto coincidano.

Seconda parte: i documenti e i file allineati alle decisioni del titolare

Su un ramo dedicato, documenti-decisioni-novembre, applica le decisioni che seguono, prese dal titolare fra il 18 e il 20 novembre. Non è il riallineamento dei consolidati, che resta una sessione a sé: applica soltanto queste decisioni, con una versione nuova di ogni documento toccato e la nota delle novità in testa, come d’uso. Verifica che nessun punto esistente le contraddica senza essere stato riformulato, e registra ciò che va registrato.

Le due modalità di battaglia. Il gioco è uno solo, con due modalità di battaglia: a sciami sulla griglia esagonale, com’è oggi, e a campioni su due linee. La modalità si sceglie all’inizio della partita e vale per il regno e per tutte le campagne. Il regno è identico nelle due modalità; cambiano soltanto le voci militari, cioè reparti e assetti nell’una, combattenti ed eroi nell’altra. Le due modalità sono presentate alla pari, come due stili di combattimento. Entrambe sono tenute per intero alla carta, e il gioco non presenta mai la modalità a campioni come la versione per chi non vede: il motivo per cui alcuni la preferiranno è il carico mentale della griglia, non l’accesso. Le provano entrambe anche i tester.

Campagne e fronti. La campagna diventa il termine più ampio: è la guerra contro un regno nemico, in un’area che confina con il regno del giocatore. Dentro una campagna ci sono più fronti, cioè zone, chiamati per punti di riferimento e direzioni cardinali, per esempio fronte nord o fronte del guado. Nella modalità a sciami ogni fronte ha la propria mappa a caselle. Nella modalità a campioni il fronte non ha mappa: ogni scontro avviene in un luogo proprio, non esistono aggiramenti né logistica dei rifornimenti, e la decisione strategica è come distribuire combattenti ed eroi fra fronti e campagne. Oggi i punti 5.6.9 e 5.6.10 del documento 01 usano i termini al contrario, fronte per il regno nemico e campagna o località per la zona con la sua mappa. Riscrivili con i termini nuovi e riassegna in modo coerente ogni regola che ne dipende: il calendario, la distanza massima di due settimane fra calendari, il blocco, il limite di regni nemici per anno, il numero di mappe richieste, l’architettura dei luoghi. Dichiara per ciascuna a quale livello si applica ora. Nei testi del gioco non cambiare nulla su questo punto in questa sessione: elenca invece in un file ogni testo rivolto al giocatore in cui campagna o fronte compaiono con il significato vecchio, per una decisione successiva. I nomi interni del codice non si toccano.

L’informazione nella modalità a campioni. È molto più spostata verso la certezza: le notizie sugli avversari si acquisiscono facilmente e sono in gran parte certe e prevedibili, perché l’imprevedibilità di questa modalità sta nelle probabilità dello scontro. È una deroga voluta al punto 5.9.1.7 del documento 01 per questa sola modalità; nella modalità a sciami la regola resta com’è.

Il caso. Esiste soltanto dentro lo scontro a campioni, con un seme dichiarato per ogni scontro e ogni probabilità annunciata prima della decisione, con i termini chiusi che il documento 02 riserva alle probabilità. Regno, campagne, fronti, avversario e battaglia a sciami restano deterministici: riscrivi il punto 12.1 del documento 01 con questo ambito.

La carta dei principi, versione 1.3. Resta una sola per tutto il gioco. Il punto 12.2 diventa: le unità sono definite per funzione e mai per popolo; nella modalità a sciami sono archetipi con tratti, nella modalità a campioni classi e sottoclassi con armamento ed equipaggiamento. Il principio 7 si estende allo scontro a due linee e alle schermate di campagne e fronti. L’introduzione descrive le due modalità. Riformula ogni altro punto che presuppone una sola modalità, per esempio quelli su celle e griglia, dichiarando che valgono per la modalità a sciami. Correggi anche il riferimento superato alla versione del documento 03.

La modalità a campioni, lo scontro. Le due linee sono elenchi e non geometria. Il turno di un combattente è alla maniera di Kingdoms and Lords: esce dalla propria posizione, colpisce e torna al suo posto, senza occupare spazio né manovrare. I formati crescono con la progressione: due contro due senza linee, tre contro tre con due davanti e uno dietro, cinque contro cinque con tre davanti e due dietro. Fra i combattenti della prima linea ci sono i varchi. Per colpire in corpo a corpo un combattente della seconda linea si passa sempre dal varco che gli corrisponde, fiancheggiato da due combattenti della prima linea; il centrale copre entrambi i varchi. Il pedaggio è automatico e non è una scelta: chi attraversa un varco subisce la reazione dei due che lo fiancheggiano, a ogni incursione e senza limite per giro. La reazione è una frazione fissa dell’attacco pieno corrente del difensore e non subisce altri modificatori. La frazione è inversa al peso, circa un terzo per il pesante e circa la metà per il leggero, e vale zero per i tiratori, che in prima linea non reagiscono. Il tetto sta sul singolo difensore e mai sulla coppia. Se uno dei due fiancheggiatori è caduto reagisce solo il superstite; se sono caduti entrambi, o hanno entrambi reazione zero, il varco è libero. Prima della conferma il gioco dichiara il pedaggio vero e completo, e rende riconoscibile un difensore a reazione zero. Il tiro raggiunge soltanto la prima linea finché il varco è difeso, e passa alla seconda attraverso un varco indifeso; le munizioni sono illimitate. Una posizione lasciata libera si può occupare spendendo il turno di chi si sposta. Ciascuno si sposta una sola volta per giro, ma può occupare subito un posto appena lasciato libero da un altro nello stesso giro, e lo spostamento fra le due linee è libero. Chi perde l’intera prima linea entra in uno stato terminale da cui esce solo riposizionando.

La modalità a campioni, salute, ferite e morte. C’è una soglia sola, al venti per cento della vita totale: sotto la soglia il danno inflitto cala di circa un quarto o poco più, e il calo si trasferisce da sé alla reazione. Gli infortuni sono di tre gradi, lieve, medio e grave. Tengono il campione fuori per un numero di scontri successivi crescente con la gravità, contato in scontri combattuti e non in tempo di gioco, e la battaglia in corso prosegue normalmente. I meccanismi sono due. Il primo è la caduta a zero: sotto il dieci per cento, infortunio grave sicuro; fra il dieci e il venti, se a portarlo a zero è un critico, metà delle volte morte e metà infortunio grave; sopra il venti, una scala unica, per esempio un infortunio medio. Il secondo è il critico subito restando in piedi: infortunio medio fra il quaranta e l’ottanta per cento, lieve con circa tre probabilità su dieci sopra l’ottanta. La scala va scritta come una funzione unica della percentuale di vita al momento del colpo, con le soglie come valori nei file, e i dettagli si tarano con il simulatore. Il salto netto al venti per cento è voluto. Lo stato di pericolo mortale si dichiara in anticipo con un termine chiuso, e deve sempre esistere la via per sottrarre il campione all’esposizione. La percentuale di critico va tenuta più bassa di quanto verrebbe istintivo: l’accoppiamento giusto deve continuare a vincere quasi sempre, e il caso decide di quanto e a che prezzo.

La modalità a campioni, combattenti ed eroi. Classi e sottoclassi hanno la struttura di Dungeons and Dragons ma non il suo contenuto fantastico, più armamento ed equipaggiamento. Sono tre assi separati e mai profili preconfezionati: classe e sottoclasse sono insiemi di coefficienti, arma ed equipaggiamento sono oggetti con i propri coefficienti, e una formula sola li compone, secondo il punto 13.3 della carta. Resta l’accoppiamento fra offesa e protezione dei punti 3.3.1 e 3.3.2 del documento 01. Armamento ed equipaggiamento si fissano al reclutamento e non cambiano mai. Nessun nome proprio e nessuna storia scritta: ogni combattente ha un identificativo stabile, unico e mai riusato, più un titolo funzionale di due o tre parole. Il titolo entra nel vocabolario chiuso con il genere dichiarato, e le frasi che lo contengono sono scritte intere, secondo il punto 14.2 della carta. Al posto della storia c’è un registro delle imprese che il gioco produce da sé: scontri combattuti, ferite gravi sopravvissute, avversari abbattuti, pericoli corsi. Un veterano che muore lascia qualcosa, per esempio un titolo o una reputazione che si eredita. Gli eroi sono campioni speciali: pochi e unici, combattono nelle stesse linee, si ottengono in modo speciale, per esempio sconfiggendo un comandante nemico di rilievo. Sono più forti o hanno una capacità propria, e dopo l’impiego hanno un tempo di recupero contato in scontri.

La modalità a campioni, il regno. Gli scontri producono ciò che si spende nel regno, e ciò che si compra nel regno muove le capacità dei campioni. I miglioramenti vanno per l’ottanta per cento sulla persona, cioè addestramento, resistenza e percentuali. Il restante venti va sull’istituzione, speso soprattutto in ciò che riduce il divario fra veterani e nuovi arrivati, cioè il livello di partenza dei reclutati e la velocità di guarigione. C’è un tetto ai miglioramenti per campione. I campioni che si tengono sono più di quanti se ne schierano, e il tetto all’organico si tara insieme alla durata degli infortuni.

La modalità a campioni, ciò che è scartato e da non riproporre: un tetto agli ordini o all’energia per giornata; lore e biografie; il cambio di equipaggiamento; il limite di una reazione per giro; le munizioni limitate. Nella modalità a sciami è scartata anche una rassegna delle costruzioni del regno, perché l’informazione arriva dove serve, all’apertura dello scontro.

La modalità a campioni, le note per la taratura. Misura il tasso di morte facendo giocare a una delle due parti un tattico deliberatamente indebolito, perché il giocatore che conta è quello che sbaglia. Misura le morti ogni cento scontri come distribuzione e non come media. Conta la mortalità nella sola fascia in cui la regola si applica. Verifica presto quanto vale un colpo pieno rispetto al dieci per cento della vita: se lo supera, la fascia fra dieci e venti non si applica quasi mai. Verifica che la composizione non abbia una soluzione unica, per esempio sempre pesanti ai lati e leggero al centro.

La modalità a campioni, ciò che resta aperto e non è di questa sessione. L’elenco delle classi e sottoclassi lo proporrà Code in una sessione successiva, il più possibile coerente con la ricerca storica del documento 04. Il titolare suggerisce per esempio l’eroe sul carro come alto nobile della fase arcaica, e le élite della modalità a sciami come combattenti normali della modalità a due linee. Ritiene questa modalità perfino più vicina alla realtà storica: va verificato. Restano aperti anche i fatti che entrano nel registro delle imprese e i numeri dell’organico e degli infortuni. Dove scrivere la modalità, in un documento proprio o dentro i consolidati, lo decidi tu, motivando la scelta.

Il vocabolario. Lo stato di conoscenza avvistato diventa osservato, nei documenti e nei testi del gioco: per esempio osservato, tre turni fa. Resta invece formazione avversaria avvistata, dove si è visto davvero un nemico. Rendi impossibile che il termine vecchio sopravviva come stato di conoscenza, con un controllo che lo rifiuti e che hai visto fallire almeno una volta, e rigenera le impronte del manifest dei testi nel modo previsto.

Il file CLAUDE.md. Crea nella radice del repo un CLAUDE.md, che le sessioni di Code leggono da sé all’avvio, così gli incarichi futuri non devono ripetere il contesto. Deve essere breve e contenere soltanto ciò che vale per ogni sessione:

che cos’è il progetto e chi è il titolare;
dove stanno i documenti e quale prevale, e che la cartella documenti vecchi non si legge;
le regole di lavoro stabili: piena delega, quando ci si può fermare, il criterio dei cancelli che rifiutano, la verifica su partite giocate attraverso l’interfaccia, nessuna stringa nel codice e nessun numero fuori dai file di dati, riprodurre prima di correggere e misurare prima di tarare, nessun canale per il solo collaudo, nessuna prova indebolita;
le regole di infrastruttura su certificati, versioni, numero di build, rami e spinta obbligatoria;
la convivenza con gli altri progetti e i simulatori dedicati;
il divieto di parlare di sicurezza e privacy;
la forma della consegna descritta più avanti in questo incarico.
Per i dettagli rinvia a forma-dei-resoconti.md e a memoria-infrastruttura.md senza copiarli. Se trovi regole che si contraddicono fra quei file, segnalalo invece di sceglierne una.

Chiusura della seconda parte. Collaudo completo verde, fusione su principale, spinta, ramo cancellato, coincidenza fra locale e remoto verificata.

Terza parte: la chiusura dell’incarico 26 e la build 28

Soltanto se le prime due parti sono chiuse e verdi. Porta il ramo partite-fino-alla-fine sopra il principale aggiornato. Riesegui le due prove d’interfaccia nuove e vedile passare. Misura la durata di quella che gioca le partite intere sui tre formati, e decidi con la misura in mano se sta nel collaudo di ogni caricamento o nella corsa separata. Falla fallire una volta di proposito su un blocco costruito, e riportane l’uscita. Registra la decisione sull’esito della prova. La nota per il titolare sul ramo afferma già che il collaudo gioca le partite fino in fondo: deve essere vera quando la build esce, altrimenti va riscritta, e deve citare anche il cambio da avvistato a osservato. Esegui il collaudo completo e la corsa delle sessioni, poi carica la build 28 con lo script. Verifica su App Store Connect che sia valida, sul treno più alto e nel gruppo di test, e che il registro concordi. Poi fondi su principale, spingi, cancella il ramo e verifica la coincidenza fra locale e remoto. Dichiara la valutazione sulle versioni dei valori e dello schema del giornale.

Quarta parte: l’esplorazione completa dell’interfaccia

Si fa alla fine, sul principale definitivo, quindi con la build 28 se è uscita. È la prima volta che le prove possono usare VoiceOver, e il titolare vuole approfittarne per confermare ciò che funziona e scoprire debolezze e imperfezioni.

Esplora l’intera interfaccia, dalla prima schermata alle battaglie: menu, impostazioni, apprendimento dei segnali, battaglia nuova e ripresa di una battaglia salvata, campagna sui tre formati, mappa, comandi dei gruppi, marce, ricognizione, imboscate, tasto per chiudere la giornata, passaggio alla battaglia, deck, piazzamento, azioni e designazione, resoconto di fine battaglia, ritorno in campagna, ripiegamento.

Ogni schermata va percorsa due volte. La prima con VoiceOver acceso, elemento per elemento, registrando nell’ordine ciò che VoiceOver pronuncia. Verifica che ogni elemento visibile e attivabile sia raggiungibile, abbia un’etichetta comprensibile e il tratto giusto, che l’ordine di lettura sia quello dichiarato nei documenti, che dopo ogni azione arrivi l’annuncio previsto, e che il fuoco non si sposti da solo. La seconda senza VoiceOver, attivando ogni tasto e controllando che faccia ciò che deve, con una schermata per ogni stato. Poi confronta i due giri: ciò che si sente e ciò che si vede devono coincidere. Ripeti tutto su iPhone e su iPad, in verticale e in orizzontale, con il testo predefinito e con il testo più grande. Dove un gesto non si può guidare, per esempio il rotore o il tocco magico, dichiaralo invece di simularlo.

In questa parte non correggere nulla: registra soltanto. Per ogni osservazione scrivi:

la schermata;
che cosa ci si aspettava secondo i documenti;
che cosa si è visto o sentito;
la gravità: bloccante, seria o imperfezione;
i passi per ripeterla.
Aggiungi un elenco separato di ciò che hai confermato funzionare. Se un difetto blocca un percorso, registralo e prosegui da un’altra strada. L’impianto dell’esplorazione resta committato e rieseguibile, fuori dal collaudo di ogni caricamento.

Che cosa consegnare e come

Chi esamina il tuo lavoro legge direttamente il repo remoto, quindi la consegna funziona così.

Tutto ciò che produci va committato e spinto: codice, documenti, resoconto e prodotti dell’esplorazione. Nulla che serva all’esame può restare solo sulla macchina.

Nel resoconto non descrivere ciò che si legge nel repo. Per ogni modifica basta una riga con il commit e il percorso; nessuna parafrasi dei documenti modificati.

Spiega invece per intero ciò che dal repo non si vede:

che cosa è successo durante l’esecuzione;
che cosa hai visto e sentito sul simulatore;
i fallimenti, anche quelli poi risolti, e le intermittenze;
lo stato su App Store Connect;
le versioni della macchina;
i tempi;
le decisioni che hai preso da solo, e perché;
ciò che non sei riuscito a fare.

I prodotti delle prove si consegnano come testo, in una cartella dedicata all’incarico: esiti esportati in testo o JSON, le trascrizioni di ciò che VoiceOver pronuncia, il file delle osservazioni, e una selezione di schermate in PNG, al massimo una ventina di megabyte in tutto. Non committare i fascicoli grezzi dei risultati.

In coda al resoconto, separati: ciò che hai fatto senza che fosse chiesto, ciò che era chiesto e non hai fatto, e i tempi spesi in compilazione, collaudo, simulatore, caricamento ed esplorazione. Il resoconto si archivia in Incarichi con il numero 27, in registro tecnico.

Il messaggio finale nel terminale, quello che il titolare vede, contiene soltanto: se la build 28 è uscita, il commit finale del principale, i rami spinti, e i percorsi del resoconto e della cartella dei prodotti.

Come lavorare

Piena delega, e nessuna domanda fino al resoconto finale, salvo credenziali mancanti e operazioni che potrebbero toccare certificati. Fermarsi prima della fine è ammesso solo se la capacità della sessione si sta esaurendo davvero: va dichiarato con il dato che lo mostra, lasciando tutto committato e spinto sul ramo in corso. La priorità è l’ordine delle parti. Se l’esplorazione non ci sta per intero, si ferma alla fine di una schermata e lo dichiara. Usa pure sottoagenti e più simulatori di WarSense in parallelo dove due parti non dipendono l’una dall’altra. Le misure di tempo però si prendono da sole, e due compilazioni sullo stesso ambiente restano in sequenza. Restano in vigore le regole della memoria di infrastruttura su versione di marketing, numero di build, identificatori e spinta obbligatoria.
