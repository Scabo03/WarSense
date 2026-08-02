# Documento di progetto del gioco

Documento 01 di 05 — versione 1.2

## Come leggere questo documento

Questo documento descrive il gioco: cosa succede, con quali regole, con quali conseguenze. Non descrive il programma, che è oggetto del documento di architettura tecnica, e non descrive come le informazioni vengono presentate a chi ascolta, che è oggetto del documento 02.

Va letto insieme alla carta dei principi non negoziabili, che prevale in caso di conflitto.

Ogni requisito è numerato per riferimento diretto. I punti contrassegnati come da confermare sono decisioni non ancora prese: vanno chiuse prima che la parte corrispondente venga realizzata, e nel frattempo nessun modello deve colmarle di propria iniziativa. I punti contrassegnati come proposta sono suggerimenti del redattore, non decisioni del titolare del progetto.

---

## 1. Visione e struttura generale

1.1 Gioco gestionale e strategico militare a turni, per un solo giocatore contro avversari gestiti dal programma, con predisposizione a una futura partita amichevole tra dispositivi vicini.

1.2 Il gioco si articola su due piani distinti e collegati. Il piano di campagna è la gestione di un regno con vocazione militare, su mappa a caselle quadrate, con informazione incompleta e ricognizione. Il piano di battaglia è lo scontro tattico su griglia esagonale, a informazione completa.

1.3 La gestione del regno riguarda esclusivamente la sfera militare e ciò che la alimenta: risorse, installazioni militari, addestramento e reclutamento, logistica e rifornimenti, manutenzione, organizzazione delle truppe. Sono espressamente esclusi commercio, cultura, istruzione, politica interna, diplomazia interna e gestione ambientale.

1.4 Non esiste alcun limite di tempo reale in nessun punto del gioco, come stabilito dal principio 4. Ogni vincolo è espresso in quantità: numero di turni, di atomi, di volume, di risorse.

1.5 La progressione avviene per fasi storiche successive. La prima versione del gioco comprende la fase arcaica, la fase antica e la transizione tra le due.

## 2. Fasi storiche

2.1 Le fasi previste nell'arco completo del progetto sono otto: arcaica, antica, classica, medievale, storica, moderna, contemporanea classica, avanguardistica. Solo le prime due rientrano nella prima versione. Le restanti sei sono citate qui unicamente per dare orizzonte alla progettazione e non devono influenzare alcuna decisione realizzativa della prima versione.

2.2 Nessuna fase porta il nome di un popolo, di uno Stato o di un periodo storico riconoscibile. Le fasi sono designate con nomi propri del gioco, e i riferimenti storici che compaiono in questo documento servono solo a orientare chi progetta.

2.3 La fase arcaica corrisponde per parametri fisici e logistici a un orizzonte tecnologico da tarda età del bronzo: armi da mischia e da getto leggere, protezioni limitate, mobilità affidata a piattaforme trainate, assedio rudimentale, logistica di corto raggio, comando poco articolato.

2.4 La fase antica corrisponde a un orizzonte da ferro maturo: formazioni serrate, protezioni diffuse, tiro a distanza organizzato, cavalleria come arma manovrata, macchine da assedio meccaniche, logistica capace di sostenere colonne più grandi e più lontane.

2.5 La differenza percepibile tra le due fasi deve riguardare i parametri e non i nomi: portate maggiori, resistenza maggiore, autonomia maggiore, macchine più efficaci e più esigenti in manutenzione, sciami più numerosi sostenibili dalla stessa logistica.

2.6 Transizione tra fasi. Il passaggio alla fase successiva è governato da una soglia di progresso, raggiungibile soltanto attraverso la vittoria in numerose campagne complete. Le vittorie alimentano le risorse del regno, che finanziano progetti e ricerche, e il superamento della soglia porta il regno nella fase successiva sbloccando una manciata di tecnologie caratteristiche di quella fase. Lo stesso schema si ripete per tutte le transizioni successive.

2.7 La transizione è quindi progressiva nel suo accumulo e discreta nel suo effetto: il progresso si accumula campagna dopo campagna, lo sblocco avviene al superamento della soglia.

2.8 Da confermare. Che cosa accada alle truppe della fase precedente al momento dello sblocco, cioè se si convertano, se restino utilizzabili con svantaggio crescente o se debbano essere congedate. Se l'avversario progredisca in parallelo, con un proprio ritmo indipendente, o su una soglia propria. Quante e quali tecnologie compongano la manciata sbloccata nel passaggio dalla fase arcaica alla fase antica.

## 3. Archetipi di unità

3.1 Nessuna unità è identificabile con una civiltà, un popolo o una formazione storica determinata. Le unità sono archetipi definiti per funzione, ai quali si applicano tratti modificatori.

3.2 Gli archetipi funzionali previsti nelle prime due fasi sono, in forma provvisoria: fanteria leggera, fanteria pesante d'urto, guardia d'élite, tiratori, cavalleria leggera da ricognizione, cavalleria da urto, piattaforma mobile trainata, macchina d'assedio. Da confermare l'elenco definitivo e la sua ripartizione tra le due fasi.

3.3 I tratti modificatori distinguono varianti dello stesso archetipo senza moltiplicare gli archetipi. Esempio di riferimento: la fanteria d'élite di tipo spartano e la guardia scelta di tipo persiano sono entrambe guardia d'élite, l'una con un tratto di tenuta in formazione, l'altra con un tratto di versatilità e capacità di tiro. Il giocatore può disporre di entrambe senza alcuna incongruenza, e questo è uno degli scopi dichiarati dell'impostazione per archetipi.

3.4 Ogni archetipo possiede, come minimo: punti vita per atomo, capacità offensiva, gittata espressa in celle, coefficiente di volume, coefficiente di penalità di avanzamento, coefficiente di velocità di marcia, sensibilità alla stanchezza o alla manutenzione. I valori risiedono nei file di dati secondo il principio 13.

3.5 Poiché l'estensione reale di una cella varia con il formato dello scontro, gittate e autonomie sono espresse in celle e in turni, mai in unità di misura reali, come stabilito dal punto 12.4 della carta.

## 4. Sciami

4.1 L'unità operativa in battaglia è lo sciame. Uno sciame è un raggruppamento di atomi dello stesso archetipo, omogeneo per definizione: non esistono sciami misti.

4.2 Uno sciame possiede un serbatoio di punti vita complessivo pari alla somma dei punti vita dei suoi atomi. Il danno subito si sottrae dal serbatoio. Il numero di atomi ancora presenti si ricava dal serbatoio residuo, e l'efficacia dello sciame, cioè la sua capacità offensiva, dipende dal numero di atomi presenti.

4.3 La riduzione degli atomi in funzione del serbatoio residuo è una divisione, quindi ricade nella regola di troncamento per difetto del punto 13.5 della carta, con il minimo obbligatorio di uno del punto 13.6: uno sciame ancora in vita conserva sempre almeno un atomo. Uno sciame il cui serbatoio si esaurisce è disfatto e lascia il campo.

4.4 Una cella può essere occupata da un solo sciame. Questa regola nasce da un'esigenza di gioco e ne serve una seconda, dichiarata nel documento 02: una cella con un solo occupante si annuncia in poche parole, il che rende praticabile la scansione rapida di una riga.

4.5 Conseguenza da accettare consapevolmente: le armi combinate non esistono all'interno della cella, esistono per adiacenza. Un accostamento tra tiratori e fanteria pesante si ottiene disponendo i due sciami su celle vicine, non mescolandoli.

4.6 Il sistema degli sciami è unico per tutti i formati di scontro. Sulle griglie minori il numero di atomi per sciame scala verso il basso fino al limite di un solo atomo, che equivale di fatto all'unità singola. Regole, formule e annunci restano gli stessi in tutti i formati: non esistono due sistemi di combattimento.

4.7 Assetti. Per ogni archetipo esiste un insieme di assetti ammessi, cioè di taglie di sciame consentite, deciso in patria come scelta di organizzazione e addestramento. Esempio: per la fanteria leggera gli assetti cinque, venti e trenta.

4.8 Riorganizzazione. In campagna il giocatore ripartisce il proprio totale di atomi di un dato archetipo negli assetti disponibili. Con settanta fanti leggeri e assetti cinque, venti e trenta, sono ammesse fra le altre le combinazioni due sciami da trenta più due da cinque, oppure tre sciami da venti più due da cinque.

4.9 Lo stato di gioco conserva il totale di atomi per archetipo, e separatamente l'elenco degli sciami formati. Non conserva la sola somma degli sciami. È questa distinzione che rende possibile il punto seguente.

4.10 Resti. Gli atomi che avanzano da una ripartizione restano contabilizzati nel totale ma non sono schierabili, e narrativamente si considerano distaccati a servizi di guardia. Rientrano automaticamente tra i disponibili non appena il totale torna a coprire un assetto. Con settantatré fanti leggeri, tre restano fuori dalla schermata di redistribuzione; se il totale sale a settantacinque, tutti e settantacinque tornano ripartibili.

4.11 Uno sciame ridotto non conserva identità tra una battaglia e l'altra. A scontro concluso il totale di atomi per archetipo si aggiorna con le perdite, e il giocatore ridistribuisce liberamente ciò che resta. In assenza di una ridistribuzione esplicita, gli atomi si raggruppano automaticamente nell'assetto più piccolo disponibile.

4.12 Il reintegro dei totali avviene esclusivamente attraverso reclutamento e addestramento in patria, secondo le regole della sezione 5. Non esiste un reintegro sul campo.

## 5. Piano di campagna

5.1 La mappa di campagna è a caselle quadrate, in tre formati fissi: quattro per quattro per gli scontri di confine, sei per sei per situazioni geograficamente limitate come isole, penisole e assedi, dieci per dieci per la guerra aperta. L'adiacenza è ortogonale: quattro vicini per casella, senza diagonali.

5.2 Sulla mappa di campagna si muovono tre categorie di formazioni: gruppi armati, capaci di combattere; formazioni di ricognizione, cioè esploratori; formazioni non armate, cioè catene di approvvigionamento e simili.

5.3 L'informazione è incompleta. Ogni casella possiede uno stato di conoscenza espresso con il vocabolario chiuso definito nel documento 02: inesplorato, presunto, avvistato con il numero di turni trascorsi, confermato. Il vocabolario è fisso e non ammette sinonimi in alcun punto del gioco.

5.4 La ricognizione è priva di rischio di ingaggio: gli esploratori non innescano battaglie in alcun caso.

5.5 Gestione del regno. Comprende risorse, installazioni militari, reclutamento e addestramento, logistica e rifornimenti, manutenzione delle macchine, organizzazione degli sciami secondo gli assetti. Da confermare l'elenco definitivo delle risorse, delle installazioni e dei loro effetti.

5.6 Movimento e logistica. Le formazioni si spostano di casella in casella consumando rifornimenti. Una velocità di spostamento maggiore consuma più risorse e produce un accumulo di stanchezza maggiore.

5.7 Stanchezza e manutenzione. Le formazioni umane e animali accumulano stanchezza; le macchine da guerra hanno uno stato di manutenzione che svolge la stessa funzione. Entrambi gli stati influenzano parzialmente l'efficacia in battaglia, con effetto su punti vita e capacità offensiva. Da confermare l'entità dell'effetto e le condizioni di recupero.

5.8 Lo stato di approvvigionamento influenza a sua volta l'efficacia in battaglia. Da confermare se agisca anche sul budget di volume disponibile allo schieramento oppure soltanto sui parametri delle unità.

5.9 Meteo e geografia di campagna esistono come materia propria del piano di campagna e non influenzano lo svolgimento delle battaglie. Il meteo è l'unico ambito, insieme ai guasti, in cui interviene il caso, secondo la sezione 12.

5.10 Azioni contro formazioni non armate. Quando una formazione di ricognizione o un gruppo armato raggiunge la casella di una formazione non armata avversaria, non si apre alcuna battaglia. È possibile ordinare, a seconda della composizione della formazione che agisce, un sabotaggio oppure uno studio approfondito. Lo studio approfondito fornisce informazioni ulteriori, in particolare su movimenti non ancora individuati, e può creare le condizioni per un'imboscata. Da confermare le regole di risoluzione, i requisiti di composizione e le conseguenze precise.

5.11 Aggiramento. Due formazioni possono sfilarsi in caselle adiacenti senza ingaggiarsi. Una colonna avversaria può quindi oltrepassare l'esercito del giocatore e puntare su un obiettivo sguarnito. Questo comportamento è voluto ed è una possibilità tattica riconosciuta, non un difetto da correggere.

## 6. Innesco della battaglia e blocco della campagna

6.1 Una battaglia si innesca esclusivamente quando due gruppi armati contrapposti si trovano nella stessa casella della mappa di campagna. Nessun altro incontro la innesca.

6.2 L'evento non forza il passaggio alla schermata di battaglia. Nella casella interessata compare un comando che avvia lo scontro, e il passaggio avviene quando il giocatore lo decide.

6.3 Dal momento in cui una battaglia è in sospeso, ogni altra attività di quella campagna è preclusa. Il giocatore può operare liberamente in altre campagne, dove ha allocato altre risorse e altre truppe. La regola vale sempre e per chiunque.

6.4 Durante il blocco nulla avanza in quella campagna, né per il giocatore né per l'avversario: nessuna produzione, nessun movimento, nessun turno. Diversamente, il rinvio verrebbe punito dal trascorrere del tempo reale, in violazione del principio 4.

6.5 Lo scopo dichiarato di questo meccanismo è consentire al giocatore di chiudere l'applicazione e affrontare la battaglia quando dispone del tempo necessario per portarla a termine.

6.6 Se l'applicazione viene chiusa a battaglia iniziata, la ripresa avviene esattamente dal punto di interruzione, compreso lo stato dello schieramento in corso, il budget già speso e l'elemento eventualmente selezionato. Questo non richiede alcun meccanismo aggiuntivo ed è una conseguenza diretta del principio 3.

6.7 Poiché una battaglia in sospeso non può essere rifiutata, la resa di cui alla sezione 10 è la valvola che rende praticabile il blocco: garantisce che nessuna campagna possa restare bloccata senza uscita.

6.8 Battaglie contemporanee. Più battaglie possono innescarsi nello stesso turno della stessa campagna. In tal caso il giocatore sceglie quale affrontare per prima, e la scelta è essa stessa una decisione tattica, poiché ogni casella dichiara le truppe e le risorse che contiene.

6.9 In presenza di più battaglie in sospeso, e soltanto in quel caso, è consentita un'unica attività di campagna in via eccezionale: dirottare i superstiti della battaglia appena conclusa, vinta o persa, verso un'altra battaglia in sospeso. Nessun'altra attività è sbloccata.

6.10 I superstiti dirottati non possono partecipare dall'inizio del secondo scontro, poiché le battaglie sono nominalmente simultanee: arrivano come rinforzi in turni successivi, secondo la sezione 11.

## 7. Campo di battaglia

7.1 Il campo di battaglia è una griglia esagonale con esagoni orientati con la punta in alto. Le celle si dispongono quindi in righe orizzontali continue, e due dei sei vicini di ogni cella si trovano esattamente a est e a ovest. Questa scelta di orientamento è vincolante e discende dal modello di navigazione descritto nel documento 02.

7.2 I formati vanno da una quindicina di celle per gli scontri di confine fino a un massimo di cento celle, corrispondenti a dieci righe da dieci.

7.3 Le righe sono numerate a partire dalle retrovie del giocatore. La riga uno è la retrolinea più profonda dello schieramento avversario, la riga dieci quella del giocatore, secondo l'orientamento adottato nella sezione 10.

7.4 Il campo è di norma uniforme: nessun dislivello, nessun terreno differenziato, nessun effetto della geografia o del meteo di campagna.

7.5 Ostacoli. Alcuni campi possono contenere ostacoli, con i seguenti limiti vincolanti. Solo le griglie da cento celle possono contenerne. Gli ostacoli sono di carattere minore e non devono mai essere determinanti per l'esito: forniscono orientamento, varietà e una sfida accessoria. Nessun ostacolo può occupare più di quattro celle. Le celle occupate da un ostacolo non sono interattive e vengono annunciate immediatamente come tali. I campi con ostacoli restano pochi.

7.6 La presenza di ostacoli è dichiarata all'apertura della battaglia, così che il giocatore sappia di doverli cercare. La loro individuazione avviene esplorando la griglia.

7.7 A battaglia iniziata l'informazione è completa: tutte le forze in campo sono visibili e annunciabili, senza alcuna informazione nascosta.

## 8. Schieramento

8.1 Prima dell'inizio dello scontro il giocatore dispone le proprie forze. Non esiste alcun limite di tempo per farlo: il vincolo è di quantità.

8.2 Il vincolo è duplice: un budget di volume spendibile e una profondità massima di schieramento a partire dalle proprie retrovie.

8.3 Interfaccia a deck. Gli sciami disponibili compaiono in un elenco posto sotto la griglia. Si seleziona un elemento dall'elenco, si naviga fino alla cella e si conferma. Nessun trascinamento, secondo il principio 8.

8.4 Ogni conferma su una cella piazza un esemplare dell'elemento selezionato. Se l'elemento era l'ultimo del suo tipo, si esaurisce e si deseleziona automaticamente, con annuncio e senza spostamento del fuoco. Se ne restano altri, si possono piazzare su celle diverse con conferme successive.

8.5 Il budget di volume è unico e copre indifferentemente il piazzamento di forze nuove e lo spostamento di forze già in campo. Una sola valuta, una sola regola.

8.6 Il costo di un piazzamento o di uno spostamento dipende dal volume dell'elemento e dalla profondità della cella di destinazione, secondo una formula unica che combina la profondità, espressa in proporzione all'altezza della griglia, con il coefficiente di penalità di avanzamento proprio dell'archetipo. Non esiste alcuna tabella per archetipo e per riga e per formato, in applicazione del punto 13.3 della carta. La fanteria leggera ha coefficiente basso e cresce lentamente su molte righe; una macchina d'assedio ha coefficiente molto alto e diventa proibitiva già a poche righe di distanza dalle retrovie.

8.7 La medesima formula, applicata alla posizione di partenza anziché a quella di destinazione, governa il costo del ritiro di un'unità verso le retrovie durante la ritirata combattuta. Una formula sola per piazzamento, avanzamento e ripiegamento.

8.8 I costi mostrati al giocatore sono numeri interi, ottenuti per troncamento per difetto, con minimo di uno dove il troncamento potrebbe dare zero, secondo i punti 13.5 e 13.6 della carta.

8.9 Il giocatore non è tenuto a conoscere a memoria volumi e vincoli: è il gioco a dichiarare, cella per cella, se il piazzamento è possibile e a quale costo, e in caso negativo per quale motivo. Poiché una cella ospita un solo sciame secondo il punto 4.4, i motivi di non disponibilità sono tre e soltanto tre: profondità eccessiva rispetto al budget disponibile, cella già occupata, cella non interattiva perché parte di un ostacolo.

8.10 Sono obbligatori l'annullamento dell'ultima operazione e l'azzeramento completo dello schieramento, secondo il punto 13.8 della carta.

8.11 Uno schieramento proposto dal gioco, applicabile con una sola azione e poi modificabile, è previsto come comodità per qualunque giocatore. Non è una misura di parità e non va presentato come tale, poiché in assenza di limiti di tempo la parità è già garantita dalla natura quantitativa del vincolo.

## 9. Svolgimento della battaglia

9.1 Il combattimento è a turni e deterministico. Non intervengono dadi né esiti casuali nella risoluzione degli scontri.

9.2 Rinviato per scelta. Le regole di risoluzione del combattimento, cioè come si calcolano il danno inflitto e quello subito a partire da capacità offensiva, numero di atomi presenti, archetipi coinvolti, adiacenza, gittata e stati di stanchezza, approvvigionamento e manutenzione, non vengono fissate a tavolino in questa fase. Dipendono da quali e quanti tipi di asset militare risulteranno dalla documentazione storica raccolta e dalla successiva definizione architetturale, e verranno scritte quando quell'insieme sarà noto. Nessun valore numerico di danno, punti vita, velocità o volume è stabilito in questo documento.

9.2.1 Resta però vincolante, e va imposto a monte, che la risoluzione sia deterministica secondo il punto 12.1, che impieghi una formula unica condivisa più coefficienti per archetipo secondo il punto 13.3 della carta, e che tutti i valori risiedano nei file di dati. La struttura è un requisito, i numeri sono materia di bilanciamento.

9.3 Budget di volume nel corso della battaglia. Il budget si rigenera a ogni turno. Il primo turno dispone di un budget maggiorato rispetto ai successivi, che riflette la disponibilità piena delle forze all'apertura dello scontro. A titolo puramente illustrativo, e senza alcun valore normativo, un rapporto del tipo centoventi al primo turno e cento nei turni successivi. I valori reali sono materia di bilanciamento e verranno stabiliti quando l'insieme delle unità sarà definito.

9.3.1 Il budget maggiorato del primo turno vale sempre e per entrambi i contendenti, senza eccezioni: riflette il fatto che all'apertura dello scontro le forze sono fresche e la discesa in campo è più agevole.

9.3.2 Vantaggio della sorpresa. Chi tende un'imboscata non riceve un budget maggiore: riceve un numero maggiore di turni consecutivi prima che le forze avversarie giungano sul campo e cadano nell'imboscata. Il vantaggio è quindi cumulativo nel tempo di gioco e non nel singolo turno, e resta una quantità e non una durata reale, in piena coerenza con il principio 4. Chi subisce l'imboscata dispone di pochi turni prima del contatto, e schiera di conseguenza in modo sommario.

9.3.3 Conservazione del budget. Il volume non speso in un turno può essere conservato, ma entro il limite del dieci per cento del budget di quel turno, anche quando ne avanza di più. Accumulare per compiere in seguito una manovra più ampia è una scelta tattica legittima e voluta; il limite impedisce che l'inattività prolungata si trasformi in una manovra risolutiva.

9.3.4 Da confermare. Se il tetto del dieci per cento si calcoli sul budget di base del turno o sul budget effettivamente disponibile comprensivo di quanto riportato dal turno precedente, e se il volume riportato possa essere a sua volta riportato una seconda volta. La soluzione proposta è la più semplice: il tetto si calcola sul budget di base del turno e il volume riportato si somma ma non genera a sua volta riporto.

9.3.5 Il deck resta utilizzabile per tutta la durata della battaglia. Forze non schierate all'apertura possono essere introdotte in campo in qualunque turno successivo, finché ve ne sono nel deck. Tenere riserve è quindi una scelta tattica vera.

9.3.6 Il costo di un piazzamento dal deck è sempre quello ordinario, calcolato secondo il punto 8.6 con il coefficiente di penalità di avanzamento applicato alla profondità della cella di destinazione. Non esiste alcuno sconto per i turni avanzati né alcuna maggiorazione. L'unica eccezione a questa regola in tutto il gioco sono i rinforzi, di cui alla sezione 11, che pagano metà del costo ordinario ma in compenso non sono mai disponibili dall'inizio e intervengono solo in fase avanzata dello scontro.

9.4 L'informazione resta completa per tutta la durata dello scontro.

## 10. Ritirata combattuta

10.1 In qualunque momento il giocatore può dichiarare la resa mediante un comando dedicato. La resa non conclude immediatamente lo scontro: apre una fase di ritirata combattuta.

10.2 La resa è disponibile solo dopo un numero minimo di turni trascorsi. Tale soglia si accorcia in funzione delle perdite subite, espresse come proporzione delle forze iniziali e non come valore assoluto, così che la regola si comporti allo stesso modo su tutti i formati di scontro.

10.3 Durante la ritirata combattuta lo scontro prosegue finché le forze avversarie non raggiungono una riga di soglia prossima alle retrovie del giocatore. Esempio su griglia da dieci righe: la battaglia prosegue finché l'avversario non raggiunge la riga otto.

10.4 In questa fase il giocatore spende volume per ritirare unità dalle righe più arretrate, che sono salvate integralmente, e per spostare unità in avanti allo scopo di sbarrare l'avanzata avversaria e guadagnare turni. Il costo del ritiro dipende dalla riga di partenza secondo il punto 8.7: ritirare da una riga più avanzata costa più volume.

10.5 Sbarrare una traiettoria coincide con l'occupare interamente una riga. Su griglia esagonale i vicini di una cella appartengono alla sua riga e alle due adiacenti, quindi per superare una riga occorre necessariamente attraversarla, e una riga interamente occupata è per costruzione una barriera. Questa coincidenza è voluta e va preservata, perché rende l'operazione verificabile con la scansione di riga descritta nel documento 02.

10.6 Le forze evacuate ricompaiono sulla mappa di campagna in una casella arretrata rispetto alla direzione di provenienza, mai in una casella adiacente qualunque: una ritirata non può risolversi in un avanzamento.

10.7 L'avversario dispone a sua volta della ritirata, con due limitazioni permanenti che costituiscono un vantaggio nascosto del giocatore ai sensi della sezione 13: può ritirare unità soltanto dalla propria riga più arretrata, e la sua propensione alla ritirata è molto bassa. L'evento resta quindi possibile e costituisce una sfida quando accade, senza trasformare le campagne in inseguimenti interminabili.

10.8 Ogni ritirata avversaria è annunciata quando avviene, poiché diversamente le forze nemiche sparirebbero dal campo senza spiegazione.

10.9 Da misurare con le simulazioni. Il rapporto tra la soglia di riga, la soglia minima di turni e il budget di volume disponibile determina se la resa sia una scelta dolorosa o una via di fuga conveniente. Con un margine ampio e un budget generoso, un giocatore accorto dichiarerebbe la resa al primo turno utile evacuando quasi tutto, e la sconfitta cesserebbe di avere un costo. È una grandezza da tarare numericamente e non a impressione.

## 11. Rinforzi

11.1 I superstiti dirottati da una battaglia conclusa verso un'altra battaglia in sospeso arrivano come rinforzi in un turno successivo all'inizio del secondo scontro.

11.2 Il turno di arrivo è determinato da una formula unica che combina la distanza in caselle tra le due località, la durata della battaglia già conclusa e un coefficiente di velocità di marcia proprio dell'archetipo. Non si impiegano scaglioni né tabelle a doppia entrata, in applicazione del punto 13.3 della carta. Come effetto della formula, la fanteria leggera arriva prima delle macchine pesanti senza bisogno di regole aggiuntive.

11.3 Da confermare. Da quale momento si contano i turni di percorrenza: dall'inizio della seconda battaglia, che è la soluzione più semplice e più prevedibile e quella proposta, oppure sommando la durata della prima.

11.4 Al momento del dirottamento, effettuato dalla schermata di campagna, il giocatore riceve una stima del turno di arrivo con un margine di incertezza dichiarato, dell'ordine del venti per cento. La stima è annunciata come intervallo e mai come valore certo.

11.5 I rinforzi in arrivo non compaiono direttamente sul campo: entrano nel deck, con un annuncio di sintesi e un segnale sonoro dedicato. Il loro arrivo non sposta il fuoco, secondo il principio 11.

11.6 Ogni elemento giunto come rinforzo è annunciato come tale nel deck. Il suo primo dispiegamento ha costo dimezzato rispetto al normale, calcolato sul suo volume. Una volta in campo si comporta come qualunque altro sciame.

11.7 Il dimezzamento del costo è il primo caso concreto della regola di arrotondamento: la metà di un volume dispari produce un decimale, il troncamento per difetto lo abbassa, e su un elemento di volume basso potrebbe raggiungere lo zero. Si applica il minimo di uno del punto 13.6.

11.8 Da confermare. Se i rinforzi siano soggetti ai normali vincoli di profondità di schieramento, il che si presume, e da quale zona del campo entrino.

11.9 I rinforzi possono arrivare anche durante una ritirata combattuta, dove risultano particolarmente utili a coprire l'evacuazione.

## 12. Caso e determinismo

12.1 La risoluzione del combattimento è deterministica. Il comportamento dell'avversario è deterministico: le sue scelte discendono da propensioni e da valutazioni, non da tiri di dado. Un comportamento coerente si può imparare, un tiro di dado no, e questo giova tanto alla leggibilità del gioco quanto alla riproducibilità delle simulazioni.

12.2 Il caso interviene esclusivamente su eventi del mondo esterni alla decisione tattica: variazioni meteorologiche sul piano di campagna e guasti alle macchine da guerra, la cui probabilità dipende dallo stato di manutenzione.

12.3 Tutto ciò che è probabilistico deve essere annunciato come probabilità e mai presentato come certezza. Lo stato di manutenzione di una macchina dichiara a voce se la possibilità di guasto è alta o bassa, con termini appartenenti al vocabolario chiuso e sempre identici, poiché chi guarda dispone di un segnale di allarme visivo e chi ascolta deve ricevere la stessa informazione con lo stesso anticipo.

12.4 Le imboscate non sono un fatto casuale: derivano dalle informazioni acquisite e dalle propensioni dell'avversario, secondo la sezione 5.10 e la sezione 14.

## 13. Vantaggi nascosti del giocatore

13.1 Alcune regole avvantaggiano deliberatamente il giocatore per evitare che vincere risulti tedioso o interminabile. Sono nascoste al giocatore, non al progetto: vanno raccolte in un unico punto ed essere note al programma di verifica del bilanciamento, che diversamente misurerebbe probabilità irreali.

13.2 Vantaggi attualmente stabiliti: l'avversario può ritirare unità soltanto dalla propria riga più arretrata; la sua propensione alla ritirata è molto bassa.

13.3 Ogni vantaggio nascosto introdotto in seguito va aggiunto a questo elenco e al documento dei dati.

## 14. Avversario

14.1 Il livello di difficoltà generale si imposta nelle impostazioni del gioco e agisce sulle risorse e sui margini a disposizione dell'avversario.

14.2 Indipendentemente dal livello generale, i singoli ufficiali avversari differiscono per comportamento. Due battaglie contro ufficiali dello stesso regno possono quindi risultare diversamente impegnative.

14.3 Gli ufficiali non impiegano intelligenze diverse ma la stessa con parametri diversi: propensione all'attacco, tolleranza alle perdite, tendenza all'accerchiamento o allo sfondamento centrale, propensione all'imboscata, propensione alla ritirata.

14.4 Difficoltà generale e carattere dell'ufficiale non si sommano in modo opaco. La difficoltà generale regola risorse e margini, il carattere dell'ufficiale regola soltanto il comportamento. Il giocatore deve poter capire perché una battaglia è dura.

14.5 Parità informativa. Se un giocatore che guarda può intuire dal comportamento sulla mappa di avere di fronte un comandante prudente, chi ascolta deve poterlo sapere dai medesimi indizi. Ogni ufficiale è quindi presentato prima della battaglia con nome, reputazione e quanto è noto sul suo conto, e le sue mosse sono annunciate in modo che il carattere risulti percepibile.

## 15. Conclusione della battaglia e ritorno in campagna

15.1 Durante la battaglia non si consuma alcuna risorsa di campagna.

15.2 A scontro concluso esistono soltanto superstiti e perdite. Non esistono prigionieri come esito di battaglia. La cattura di forze avversarie è eventualmente possibile mediante azioni dal piano di campagna che non giungono allo scontro.

15.3 La battaglia si chiude con un resoconto: perdite subite, perdite inflitte all'avversario, e le altre informazioni utili a valutare l'esito. Da confermare il contenuto esatto del resoconto.

15.4 Si torna quindi al piano di campagna, dove giocatore e avversario collocano le forze superstiti. Il vincitore sceglie per primo, l'avversario in seguito.

15.5 Il vincitore, e soltanto il vincitore, può scegliere di restare nella casella contesa. Tutte le altre forze si collocano in una casella adiacente a quella dello scontro.

15.6 Le forze evacuate con la ritirata combattuta ricadono sotto la limitazione del punto 10.6 e si collocano in una casella arretrata rispetto alla direzione di provenienza.

15.7 Il totale di atomi per archetipo si aggiorna con le perdite. La ridistribuzione negli assetti avviene secondo la sezione 4, e in assenza di scelta esplicita gli atomi si raggruppano nell'assetto più piccolo disponibile.

15.8 Se non vi sono altre battaglie in sospeso, i turni di campagna riprendono il loro corso normale.

---

## 16. Riepilogo dei punti aperti

16.1 Rinviato per scelta, non per omissione. Le regole di risoluzione del combattimento e tutti i valori numerici a esse collegati, punto 9.2: dipendono dall'insieme degli asset militari che emergerà dalla documentazione storica e dalla definizione architetturale, e verranno scritti allora. Chi riceve questo documento non deve colmare la lacuna di propria iniziativa.

16.2 Da confermare prima delle parti corrispondenti. Sorte delle truppe della fase precedente e ritmo di progressione dell'avversario, punto 2.8. L'elenco definitivo degli archetipi, punto 3.2. Risorse e installazioni, punto 5.5. Entità e recupero di stanchezza e manutenzione, punto 5.7. Effetto dell'approvvigionamento sul budget di schieramento, punto 5.8. Regole di sabotaggio e studio approfondito, punto 5.10. Base di calcolo del riporto di budget, punto 9.3.4. Momento da cui contare i turni dei rinforzi, punto 11.3. Vincoli di ingresso dei rinforzi, punto 11.8. Contenuto del resoconto di fine battaglia, punto 15.3.

16.3 Da tarare con le simulazioni prima della pubblicazione. Il margine di convenienza della ritirata combattuta, punto 10.9. Il rapporto tra budget di schieramento iniziale e profondità concessa, che determina quanto pesi il vantaggio della sorpresa.
