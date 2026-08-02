# Documento di progetto del gioco

Documento 01 di 05 — versione 2.0

## Come leggere questo documento

Questo documento descrive il gioco: cosa succede, con quali regole, con quali conseguenze. Non descrive il programma, che è oggetto del documento di architettura tecnica, e non descrive come le informazioni vengono presentate a chi ascolta, che è oggetto del documento 02.

Va letto insieme alla carta dei principi non negoziabili, che prevale in caso di conflitto.

Ogni requisito è numerato per riferimento diretto. I punti contrassegnati come da confermare sono decisioni non ancora prese: vanno chiuse prima che la parte corrispondente venga realizzata, e nel frattempo nessun modello deve colmarle di propria iniziativa. I punti contrassegnati come proposta sono suggerimenti del redattore, non decisioni del titolare del progetto.

Questa versione recepisce la scrematura dell'inventario dei fattori storici, conclusa a valle della ricerca confluita nel documento 04. I punti contrassegnati come costo dichiarato e accettato registrano scelte che si discostano consapevolmente dal documentato: non sono sviste e non vanno corrette per aderenza storica. Il punto 16.5 ne raccoglie l'elenco.

---

## 1. Visione e struttura generale

1.1 Gioco gestionale e strategico militare a turni, per un solo giocatore contro avversari gestiti dal programma, con predisposizione a una futura partita amichevole tra dispositivi vicini.

1.2 Il gioco si articola su due piani distinti e collegati. Il piano di campagna è la gestione di un regno con vocazione militare, su mappa a caselle quadrate, con informazione incompleta e ricognizione. Il piano di battaglia è lo scontro tattico su griglia esagonale, a informazione completa.

1.3 La gestione del regno riguarda esclusivamente la sfera militare e ciò che la alimenta: risorse, installazioni militari, addestramento e reclutamento, logistica e rifornimenti, manutenzione, organizzazione delle truppe. Sono espressamente esclusi commercio, cultura, istruzione, politica interna, diplomazia interna e gestione ambientale.

1.3.1 Costo dichiarato e accettato. I meccanismi che reggevano storicamente l'economia militare stanno quasi tutti oltre questo confine: il metallo del bronzo arrivava per commercio da grandi distanze, nella fase arcaica i combattenti si compensavano con la terra anziché con la paga, chi andava in guerra dipendeva da censo e demografia, e i rifornimenti lungo la strada si negoziavano con le popolazioni locali. La ricchezza del regno arriva quindi da un canale astratto che non si gestisce, e il limite al numero di uomini in armi è il bilancio e non la popolazione. Storicamente valeva il contrario, ed è la ragione per cui una sconfitta poteva costare vent'anni a uno Stato.

1.4 Non esiste alcun limite di tempo reale in nessun punto del gioco, come stabilito dal principio 4. Ogni vincolo è espresso in quantità: numero di turni, di atomi, di volume, di risorse.

1.5 La progressione avviene per fasi storiche successive. La prima versione del gioco comprende la fase arcaica, la fase antica e la transizione tra le due.

## 2. Fasi storiche

2.1 Le fasi previste nell'arco completo del progetto sono otto: arcaica, antica, classica, medievale, storica, moderna, contemporanea classica, avanguardistica. Solo le prime due rientrano nella prima versione. Le restanti sei sono citate qui unicamente per dare orizzonte alla progettazione e non devono influenzare alcuna decisione realizzativa della prima versione.

2.2 Nessuna fase porta il nome di un popolo, di uno Stato o di un periodo storico riconoscibile. Le fasi sono designate con nomi propri del gioco, e i riferimenti storici che compaiono in questo documento servono solo a orientare chi progetta.

2.3 La fase arcaica corrisponde per parametri fisici e logistici a un orizzonte tecnologico da tarda età del bronzo: armi da mischia e da getto leggere, protezioni limitate, mobilità affidata a piattaforme trainate, assedio rudimentale, logistica di corto raggio, comando poco articolato.

2.4 La fase antica corrisponde a un orizzonte da ferro maturo: formazioni serrate, protezioni diffuse e alleggerite, tiro a distanza organizzato, cavalleria come arma manovrata, macchine da assedio meccaniche, infrastruttura logistica più estesa lungo le direttrici di marcia.

2.5 La differenza percepibile tra le due fasi non consiste in un aumento generalizzato delle prestazioni. Passare da una fase all'altra non significa diventare più forti: significa che cambia la forma del mondo, cioè che non si fanno meglio le stesse cose ma si fanno cose diverse e si affrontano problemi diversi.

2.5.1 Non cambiano, e non devono cambiare, i parametri seguenti: la portata delle armi da tiro, l'autonomia della colonna, il ritmo di marcia, la razione, il tetto alla dimensione degli eserciti da campo. La protezione individuale massima non cresce ma cala, alleggerendosi e diffondendosi anziché irrobustirsi. Un impianto che aumentasse velocità, gittata e danno rappresenterebbe una transizione che non è mai avvenuta.

2.5.2 Cambiano invece le separazioni e le sostituzioni. Il ferro separa il costo del materiale da quello del lavoro qualificato. La moneta separa il mantenimento dalla paga, e un esercito pagato si scioglie quando finiscono i fondi anziché quando perde. I sistemi di trasmissione separano il movimento dell'informazione da quello della forza. La protezione smette di essere una proprietà dell'oggetto e diventa una relazione fra arma e bersaglio. La piattaforma trainata diventa obsoleta mentre nascono la cavalleria montata e la fanteria pesante in formazione.

2.5.3 Rischio dichiarato e accettato. Una progressione che non aumenta i numeri è più difficile da far percepire come ricompensa e più difficile da annunciare a voce di un valore che cresce. Il problema è reale ed è di competenza della definizione architetturale, che deve risolverlo senza reintrodurre per vie indirette l'aumento generalizzato delle prestazioni escluso dal punto 2.5.1. Il punto 2.6 ne risolve la parte principale.

2.5.4 Le macchine da tiro sono l'unica capacità che la fase antica possiede e la fase arcaica non possiede affatto, e restano quindi l'unico caso legittimo di differenza per presenza anziché per forma.

2.6 Transizione tra fasi. Non esiste una soglia unica che sblocchi in blocco un insieme di tecnologie. Le acquisizioni arrivano una alla volta e separatamente, e ciascuna cambia un aspetto determinato del modo di fare guerra o di rifornirsi. Le vittorie in campagna alimentano le risorse del regno, che finanziano le singole acquisizioni; queste si sviluppano e si addestrano nel tempo, secondo il punto 5.9 sull'inverno.

2.6.1 La ragione è documentale: le innovazioni storiche si addensano in due grappoli separati da quattro secoli e da mille chilometri, il ferro si diffonde con tre o quattro secoli di scarto fra aree contigue e senza alcuna data unica, e i salti maggiori sono istituzionali prima che tecnologici. Una soglia unica comprimerebbe processi distinti in un evento solo.

2.6.2 Soglia distribuita. Per entrare nella fase successiva non basta il numero complessivo di acquisizioni: occorre averne raggiunte un numero minimo in ambiti diversi. La regola impedisce che il regno corra in un solo ambito raggiungendo capacità della fase successiva e resti arretrato negli altri, dove varrebbe ancora la fase precedente.

2.6.3 Raggiunta la soglia distribuita, il gioco dichiara una volta sola l'ingresso nella fase successiva. La dichiarazione è un riconoscimento e non il momento in cui si ottengono le capacità: il peso della progressione sta sulle singole acquisizioni.

2.6.4 Il passaggio di fase non è però una formalità, perché muta il mondo attorno al regno. Gli avversari dispongono di capacità che prima non avevano; cambiano la geografia attorno al regno e i regni e gli Stati confinanti, a rappresentare la progressione storica nell'arco dei secoli. È questo che restituisce al passaggio di fase la sua nettezza percepibile, secondo il punto 2.5.3.

2.7 L'ordine delle acquisizioni non è arbitrario. Di sette innovazioni è documentato l'ordine esatto di comparsa, e la sequenza degli sblocchi si appoggia a quel dato. Ogni capacità nuova ha inoltre un prezzo documentato: il salto tecnologico storicamente si pagava, e si paga anche nel gioco.

2.7.1 Poiché le acquisizioni arrivano sgranate, l'insieme degli archetipi disponibili non è fisso per fase ma si allunga e si accorcia con il progredire del regno. Vedi il punto 3.2.

2.8 L'avversario progredisce anch'esso, e al passaggio di fase dispone di capacità nuove, secondo il punto 2.6.4.

2.8.1 Da confermare. Che cosa accada alle truppe della fase precedente al momento in cui il regno entra nella fase successiva, cioè se si convertano, se restino utilizzabili con svantaggio crescente o se debbano essere congedate. Quali acquisizioni compongano la sequenza del passaggio dalla fase arcaica alla fase antica, e quali ambiti concorrano alla soglia distribuita del punto 2.6.2.

## 3. Archetipi di unità

3.1 Nessuna unità è identificabile con una civiltà, un popolo o una formazione storica determinata. Le unità sono archetipi definiti per funzione, ai quali si applicano tratti modificatori.

3.2 Gli archetipi funzionali previsti nelle prime due fasi sono, in forma provvisoria: fanteria leggera, fanteria pesante d'urto, guardia d'élite, tiratori, cavalleria leggera da ricognizione, cavalleria manovrata, piattaforma mobile trainata, macchina d'assedio. L'elenco non è fisso per fase: gli archetipi si sbloccano progressivamente secondo il punto 2.6 e alcuni cessano di essere disponibili, come la piattaforma trainata, che diventa obsoleta.

3.2.1 La cavalleria non è un'arma d'urto. In nessuna delle due fasi rompe frontalmente una fanteria schierata e in ordine, perché mancano staffe, lancia in resta e bardatura. È un'arma mobile: colpisce sui fianchi, si infila nei varchi aperti nella linea per raggiungere le retrovie, e avanza rapidamente in profondità quando l'avversario ripiega, allo scopo di massimizzare le perdite inflitte. Ne discende una forma ridotta di inseguimento, confinata al campo di battaglia, che non reintroduce l'inseguimento di campagna, escluso perché presupponeva la rottura improvvisa delle formazioni.

3.2.2 I varchi nella linea non sono un'ipotesi teorica: li produce il disingaggio dei reparti in mischia di cui al punto 3.4.2.

3.3 I tratti modificatori distinguono varianti dello stesso archetipo senza moltiplicare gli archetipi. Esempio di riferimento: la fanteria d'élite di tipo spartano e la guardia scelta di tipo persiano sono entrambe guardia d'élite, l'una con un tratto di tenuta in formazione, l'altra con un tratto di versatilità e capacità di tiro. Il giocatore può disporre di entrambe senza alcuna incongruenza, e questo è uno degli scopi dichiarati dell'impostazione per archetipi.

3.3.1 Proiettili. I reparti da tiro dispongono di due tipi di proiettile: leggero, per saturare a distanza, e pesante, per perforare da vicino.

3.3.2 Protezioni. Corrispondentemente esistono due tipi di protezione che rispondono in modo opposto ai due proiettili: chi è protetto dalla saturazione è esposto alla perforazione, e viceversa. Non si tratta di una protezione migliore e di una peggiore. La scelta delle munizioni si compie osservando ciò che si ha di fronte; la scelta delle protezioni si compie in patria senza sapere che cosa si incontrerà, ed è l'unico punto del gioco in cui una decisione presa in patria viene premiata o punita sul campo.

3.3.3 Nella fase arcaica la protezione pesante è rara e costosa: non esiste fanteria corazzata, esistono singoli combattenti corazzati. Diventa diffusa soltanto nella fase antica. È una delle differenze concrete e percepibili fra le due fasi ai sensi del punto 2.5.2.

3.4 Ogni archetipo possiede, come minimo: punti vita per atomo, capacità offensiva, due gittate secondo il punto 3.4.1, coefficiente di volume, coefficiente di penalità di avanzamento, tendenza al disingaggio secondo il punto 3.4.2, sensibilità alla stanchezza o alla manutenzione, e per i reparti da tiro una dotazione di munizioni secondo il punto 3.4.3. I valori risiedono nei file di dati secondo il principio 13.

3.4.1 Due gittate. Ogni arma da tiro possiede una gittata di disturbo e una gittata di pericolosità, in rapporto documentato di circa uno a tre o uno a quattro. Entro la prima il tiro costringe, rallenta e infastidisce; solo entro la seconda uccide. Avvicinarsi cessa quindi di essere un automatismo e diventa una decisione. La fascia entro cui il tiro uccide deve restare stretta in sede di taratura, coerentemente con il dato per cui il tiro condizionava davvero solo l'ultimo tratto dell'avvicinamento: senza questo vincolo i reparti da tiro dominerebbero distanze alle quali storicamente non decidevano nulla.

3.4.2 Tendenza al disingaggio. Ogni archetipo possiede un parametro proprio che ne esprime la tendenza a staccarsi dalla mischia quando lo scontro volge al peggio. Esistono reparti più insistenti e reparti più tattici o più facilmente scoraggiati. Il parametro opera in combinazione con il punto 9.5 sul comando.

3.4.3 Munizioni. I reparti da tiro dispongono di una dotazione limitata: dopo un certo numero di turni di tiro le munizioni si esauriscono. L'unità del tiro antico era la scarica e non il fuoco continuo. Il giocatore decide a ogni turno se far tirare o no, e può quindi conservare scariche per una fase avanzata dello scontro.

3.4.4 Volume come parametro unico. Il volume è il parametro unico da cui dipendono tanto il costo di schieramento quanto la velocità di marcia della colonna, secondo il punto 5.6. Non esiste alcun coefficiente di velocità di marcia proprio dell'archetipo: gli uomini camminano tutti allo stesso modo, e ciò che è documentato per tipo è l'ingombro su strada. Per ciò che è schierabile in battaglia il volume è unico e stabile per archetipo.

3.4.5 Seguito incorporato. Il costo e il volume di ciascun archetipo incorporano il seguito di serventi e portatori, pari storicamente a circa un terzo della colonna. Il seguito esiste, pesa e allunga la colonna, ma non è un elemento separato e non comporta alcuna decisione. Senza questa incorporazione il costo delle campagne risulterebbe circa dimezzato rispetto al documentato, senza che nulla lo segnali.

3.5 Gittate e autonomie sono espresse in celle e in turni, mai in unità di misura reali, come stabilito dal punto 12.4 della carta. Non viene dichiarata alcuna scala reale per i formati: la scala è interna e fondata sui rapporti fra le misure storiche, secondo i punti 12.5 e 12.6 della carta.

3.6 Un reparto, gruppo o asset militare occupa sempre una sola casella o cella, qualunque sia il suo assetto. L'assetto ne modifica le statistiche, mai l'ingombro in celle.

## 4. Sciami

4.1 L'unità operativa in battaglia è lo sciame. Uno sciame è un raggruppamento di atomi conforme a uno degli assetti ammessi di cui al punto 4.7. Gli sciami possono essere puri, cioè composti da atomi di un solo archetipo, oppure misti, cioè composti secondo un assetto che prevede più archetipi.

4.1.1 Uno sciame misto non nasce da una mescolanza effettuata sul campo: è un assetto deciso, organizzato e addestrato in patria, e poi dispiegato in campagna come tale. Il giocatore può spedire in campagna sia reparti puri sia reparti misti, secondo le necessità.

4.1.2 La ragione documentale è che le formazioni caratterizzanti degli eserciti orientali, in entrambe le fasi, erano miste all'interno dell'unità minima: coppie di arciere e portascudo, file di arcieri dietro una fila di scudi, equipaggi con ruoli complementari. Non è un caso di frontiera ma il grosso di quegli eserciti.

4.2 Uno sciame possiede un serbatoio di punti vita complessivo pari alla somma dei punti vita dei suoi atomi. Il danno subito si sottrae dal serbatoio. Il numero di atomi ancora presenti si ricava dal serbatoio residuo, e l'efficacia dello sciame, cioè la sua capacità offensiva, dipende dal numero di atomi presenti.

4.3 La riduzione degli atomi in funzione del serbatoio residuo è una divisione, quindi ricade nella regola di troncamento per difetto del punto 13.5 della carta, con il minimo obbligatorio di uno del punto 13.6: uno sciame ancora in vita conserva sempre almeno un atomo. Uno sciame il cui serbatoio si esaurisce è disfatto e lascia il campo.

4.3.1 Costo dichiarato e accettato. Il modello a consumo progressivo è una deviazione consapevole dal documentato, che la ricerca dichiara espressamente mai accaduto: storicamente le perdite erano quasi nulle finché la formazione teneva, saltavano nell'istante della rottura, si concentravano sul reparto sfondato e il collasso sopraggiungeva quando le perdite erano ancora attorno al dieci o venti per cento. Il modello è conservato perché un gioco che si ascolta deve sapere in ogni momento a che punto si trova, e una battaglia che non dice quasi nulla per molti turni e poi si risolve in uno solo è illeggibile per chi non vede lo schermo. Le battaglie risulteranno di conseguenza più aritmetiche e meno drammatiche di come furono.

4.3.2 Non esiste rottura improvvisa della formazione, e di conseguenza non esistono la fuga, l'inseguimento di campagna e la conversione della sconfitta in disfatta. Una parte di quanto esse producevano rientra però per altre vie: il disingaggio del punto 3.4.2, l'inseguimento confinato al campo del punto 3.2.1 e l'impossibilità di ritirare i reparti a contatto del punto 10.4.1.

4.4 Una cella può essere occupata da un solo sciame. Questa regola nasce da un'esigenza di gioco e ne serve una seconda, dichiarata nel documento 02: una cella con un solo occupante si annuncia in poche parole, il che rende praticabile la scansione rapida di una riga.

4.5 Le armi combinate esistono in due forme: per adiacenza, disponendo due sciami su celle vicine, e all'interno della cella quando lo sciame è di assetto misto. Ciò che non esiste è la mescolanza estemporanea decisa sul campo: la composizione è sempre quella dell'assetto scelto in patria.

4.5.1 Uno sciame misto è annunciato con un nome proprio e non con l'elenco dei suoi componenti, altrimenti ogni voce del deck diventerebbe una frase lunga. Il vincolo è materia del documento 02 ma nasce qui.

4.6 Il sistema degli sciami è unico per tutti i formati di scontro. Sulle griglie minori il numero di atomi per sciame scala verso il basso fino al limite di un solo atomo, che equivale di fatto all'unità singola. Regole, formule e annunci restano gli stessi in tutti i formati: non esistono due sistemi di combattimento.

4.7 Assetti. Esiste un insieme di assetti ammessi, deciso in patria come scelta di organizzazione e addestramento. Un assetto dichiara due cose: la taglia dello sciame e la sua composizione. Esempio di assetto puro: fanteria leggera nelle taglie cinque, venti e trenta. Esempio di assetto misto: tiratori e portascudo in proporzione fissa, in una taglia determinata.

4.8 Riorganizzazione. In campagna il giocatore ripartisce i propri totali di atomi negli assetti disponibili. Con settanta fanti leggeri e assetti cinque, venti e trenta, sono ammesse fra le altre le combinazioni due sciami da trenta più due da cinque, oppure tre sciami da venti più due da cinque.

4.8.1 Un assetto misto attinge a più totali contemporaneamente. La ridistribuzione risulta quindi più macchinosa, e i resti di cui al punto 4.10 possono appartenere a più archetipi insieme. È una conseguenza da tenere presente nella progettazione della schermata di redistribuzione, che è materia del documento 02.

4.9 Lo stato di gioco conserva il totale di atomi per archetipo, e separatamente l'elenco degli sciami formati. Non conserva la sola somma degli sciami. È questa distinzione che rende possibile il punto seguente.

4.10 Resti. Gli atomi che avanzano da una ripartizione restano contabilizzati nel totale ma non sono schierabili, e narrativamente si considerano distaccati a servizi di guardia. Rientrano automaticamente tra i disponibili non appena il totale torna a coprire un assetto. Con settantatré fanti leggeri, tre restano fuori dalla schermata di redistribuzione; se il totale sale a settantacinque, tutti e settantacinque tornano ripartibili.

4.11 Uno sciame ridotto non conserva identità tra una battaglia e l'altra. A scontro concluso il totale di atomi per archetipo si aggiorna con le perdite, e il giocatore ridistribuisce liberamente ciò che resta. In assenza di una ridistribuzione esplicita, gli atomi si raggruppano automaticamente nell'assetto più piccolo disponibile.

4.12 Il reintegro dei totali avviene esclusivamente attraverso reclutamento e addestramento in patria, secondo le regole della sezione 5. Non esiste un reintegro sul campo.

4.13 Miglioramenti. Oltre al reclutamento, in patria è possibile sottoporre reparti già esistenti ad addestramenti mirati e più costosi che ne accrescono le prestazioni. Reclutamento, addestramento e miglioramento avvengono soltanto d'inverno, secondo il punto 5.9.

4.14 Deperibilità. I miglioramenti non sono permanenti e si perdono se non mantenuti, poiché alcune capacità, in particolare il tiro, si perdevano storicamente senza esercizio costante. Mantenere ciò che si possiede già costa però poco: il bilancio invernale resta quasi interamente disponibile per nuovi investimenti e per il miglioramento dei reparti esistenti.

4.14.1 Da tarare con attenzione. Il costo di mantenimento è l'unico freno automatico all'accumulo di forze presente nell'impianto, poiché un esercito numeroso paga una quota che uno piccolo non paga e tenere in piedi reparti inutilizzati ha quindi un prezzo. Non esistono altri freni: la taratura va condotta sapendolo.

## 5. Piano di campagna

5.1 La mappa di campagna è a caselle quadrate, in tre formati fissi: quattro per quattro per gli scontri di confine, sei per sei per situazioni geograficamente limitate come isole e penisole, dieci per dieci per la guerra aperta. L'adiacenza è ortogonale: quattro vicini per casella, senza diagonali.

5.1.1 Gli assedi non costituiscono un formato ridotto di mappa. Una piazzaforte è un elemento collocato su una casella della mappa ordinaria, e si prende secondo la sezione 8 bis.

5.1.2 Qualificazione delle caselle. Una casella può essere qualificata come bosco o zona alberata, il che abilita la costruzione di macchine sul posto secondo il punto 5.12. La mappa è interamente percorribile: non esistono caselle interdette. Pressoché ogni mappa contiene acqua diffusa sotto forma di fiumi, rigagnoli, stagni o sorgenti, anche non annunciati, così che il fabbisogno idrico non costituisca mai un vincolo di percorribilità.

5.1.3 Strettoie. Una mappa può contenere una strettoia, cioè un passaggio obbligato, e mai più di una; non tutte le mappe ne contengono. La casella interessata la annuncia chiaramente. La rarità è voluta: rende la strettoia memorabile e fa sì che, quando esiste, la sua posizione sia nota a entrambi i contendenti e diventi un elemento attorno a cui si ragiona anziché una sorpresa. Il transito costa una quantità fissa e non una penalità proporzionale.

5.2 Sulla mappa di campagna si muovono tre categorie di formazioni: gruppi armati, capaci di combattere; formazioni di ricognizione, cioè esploratori; formazioni non armate, cioè catene di approvvigionamento e simili.

5.2.1 Quartier generale. Ogni campagna dispone di un quartier generale, o accampamento principale, che è il punto di arrivo di truppe e asset militari inviati dalla patria e l'origine dei rifornimenti destinati ai gruppi armati. È il perno della mappa di campagna.

5.2.2 Rifornimento. Il rifornimento passa unicamente per le catene proprie. Il tratto fra la patria e il quartier generale è automatico e non si gestisce; ciò che il giocatore gestisce è la catena che va dal quartier generale ai propri gruppi armati. Non esistono requisizione negoziata presso popolazioni amiche, esaurimento progressivo delle aree attraversate né vie d'acqua che spezzino il vincolo di autonomia.

5.2.3 Conseguenza da tenere presente. Concentrando l'origine del rifornimento in un punto solo, la catena che ne parte diventa il bersaglio più prezioso della mappa per entrambi i contendenti, e tagliare i rifornimenti avversari diventa una mossa concreta in combinazione con l'imboscata del punto 5.11. La protezione dei convogli deve perciò risultare gestibile senza carico eccessivo, il che è materia del documento 02.

5.3 L'informazione è incompleta. Ogni casella possiede uno stato di conoscenza espresso con il vocabolario chiuso definito nel documento 02: inesplorato, presunto, avvistato con il numero di turni trascorsi, confermato. Il vocabolario è fisso e non ammette sinonimi in alcun punto del gioco.

5.4 La ricognizione ha un costo, e il costo è soprattutto in rischio. Gli esploratori possono perdersi, tornare a mani vuote o farsi notare dall'avversario. Esplorare consuma inoltre risorse, quel tanto che basta perché non sia gratuito.

5.4.1 Resta fermo che gli esploratori non innescano mai una battaglia. Ciò che accade loro si risolve interamente sulla mappa di campagna e non conduce alla schermata di battaglia: un pugno di esploratori non è un esercito.

5.4.2 Gli esploratori hanno qualità e competenza differenziate. Sono personale formato secondo il punto 4.13, e il personale formato che si perde non si rimpiazza in un turno.

5.4.3 La ragione del costo in rischio è che, se scoprire non costasse nulla, il giocatore esplorerebbe tutto e la rarità della certezza di cui al punto 5.3 si svuoterebbe da sé. Un costo espresso in sole risorse sarebbe una leva debole, perché un regno ricco comprerebbe la certezza e uno povero resterebbe cieco.

5.5 Gestione del regno. Comprende risorse, installazioni militari, reclutamento, addestramento e miglioramento, logistica e rifornimenti, manutenzione delle macchine, organizzazione degli sciami secondo gli assetti. Da confermare l'elenco definitivo delle risorse, delle installazioni e dei loro effetti.

5.5.1 Strade. La mappa di campagna possiede una rete stradale, ed esistono tipi diversi di strada che influenzano il ritmo di marcia e la lunghezza della colonna. Le strade non sono decorative e seguono una logica: se sulla mappa esiste una città, almeno una strada vi conduce. Una strada non deve però necessariamente collegare due elementi visibili, poiché la mappa rappresenta una porzione di territorio: può proseguire fuori mappa senza che si sappia dove porti. Le strade che escono dalla mappa forniscono inoltre una via naturale di ingresso e di uscita per le forze avversarie.

5.6 Struttura del turno. Un turno di campagna corrisponde a una giornata. Ciascun gruppo dispone di un'azione al giorno, il che consente di muovere più gruppi contemporaneamente e in particolare di far lavorare gli esploratori mentre la colonna principale avanza più lentamente.

5.6.1 Una giornata non è necessariamente una giornata di marcia. Marciare è una delle azioni possibili: se scelta, si indica la casella di destinazione; altrimenti il gruppo resta fermo o compie altro. La ragione è documentale, poiché circa metà delle giornate di una campagna storica non era di marcia, ed è vietato incorporare le soste nella velocità media, il che falserebbe insieme il ritmo e il raggio d'azione.

5.6.2 Ritmo che ne deriva, descritto a titolo illustrativo e senza valore normativo. Si marcia dal quartier generale finché le provviste reggono; ci si ferma per rifornirsi; si riparte; ci si arresta in una casella boscosa per costruire una macchina; si procede più lentamente portandosela dietro; si attacca. Il ritmo non va progettato: discende dalle regole già stabilite, cioè autonomia, valvola dell'accampamento, volume e costruzione in campagna.

5.6.3 Velocità della colonna. La velocità di spostamento non è una proprietà del reparto ma della colonna, e dipende dal volume complessivo di ciò che la compone, comprese le formazioni non armate e i carriaggi. Una colonna più voluminosa è più lunga, e una colonna più lunga percorre meno strada in una giornata.

5.6.4 Marcia forzata. È possibile marciare a ritmo superiore al sostenibile, con un tetto di due o tre turni consecutivi e non oltre. Ciascun turno di marcia forzata accresce il logoramento in misura più che proporzionale, non lineare. Il tetto è decisione di progetto e non dato storico, poiché la durata massima sostenibile non è documentata per alcuna fase, e va annotato come tale nel documento 03.

5.6.5 Autonomia. Una formazione trasporta un numero determinato di giorni di viveri. Raggiunto il limite, il giocatore dispone sempre della facoltà di fermarsi, accamparsi e raccogliere quanto serve nelle zone circostanti, in modo automatico: senza acquisti, senza accordi, senza esaurimento della casella e senza memoria sulla mappa. Il limite di autonomia non è quindi un muro: oltre il raggio non si muore, ci si ferma.

5.6.6 Da stabilire in sede di definizione dei valori. Quale fra la catena dal quartier generale e la sosta con raccolta automatica costituisca la via ordinaria di rifornimento e quale l'eccezione. In assenza di questa determinazione una delle due risulterebbe inutile.

5.6.7 Gli animali seguono in automatico la stessa logica delle razioni umane. Non esiste distinzione fra la parte di razione che grava sempre e il foraggio che grava solo in assenza di pascolo, e il raggio d'azione non varia con la stagione.

5.6.8 Da confermare. Che cosa esattamente si possa muovere e in quale misura in ciascun turno, e come perimetrare la giornata rispetto alle azioni diverse dalla marcia.

5.7 Stanchezza e manutenzione. Le formazioni umane e animali accumulano stanchezza; le macchine da guerra hanno uno stato di manutenzione che svolge la stessa funzione. Entrambi gli stati influenzano parzialmente l'efficacia in battaglia, con effetto su punti vita e capacità offensiva. Da confermare l'entità dell'effetto e le condizioni di recupero.

5.8 Lo stato di approvvigionamento influenza a sua volta l'efficacia in battaglia. Da confermare se agisca anche sul budget di volume disponibile allo schieramento oppure soltanto sui parametri delle unità.

5.9 Stagioni. L'anno ha un ritmo fisso e prevedibile. D'inverno non si conduce campagna: le operazioni si fermano, si resta in patria e si dispone di più tempo e di un margine maggiore per costruzione, logistica, rifornimento, reclutamento, addestramento e miglioramento dei reparti. La pausa è obbligatoria e termina con l'inizio della primavera. La regola vale identicamente per gli avversari, che d'inverno svolgono le proprie attività.

5.9.1 L'inverno non è un intervallo fra due campagne ma una parte della partita in cui si vince o si perde: chi lo impiega meglio si presenta in primavera più avanti dell'altro. È inoltre la sede naturale della gestione del regno, che diventa così un modo di giocare distinto anziché un pannello da consultare mentre si pensa ad altro, ed è la stagione in cui si acquisiscono le capacità nuove di cui al punto 2.6.

5.9.2 Da confermare. I caratteri e i coefficienti propri delle stagioni intermedie, per esempio incendi in estate e nebbia in autunno.

5.9.3 Le stagioni non sostituiscono il caso ma gli stanno accanto. Il meteo resta, insieme ai guasti, l'unico ambito in cui interviene il caso, secondo la sezione 12.

5.9.4 Geografia e meteo di campagna influenzano lo svolgimento delle battaglie soltanto attraverso la caratteristica unica del campo di cui al punto 7.4. Non esiste alcun altro canale di comunicazione fra i due piani.

5.10 Azioni contro formazioni non armate. Quando una formazione di ricognizione o un gruppo armato raggiunge la casella di una formazione non armata avversaria, non si apre alcuna battaglia. È possibile ordinare, a seconda della composizione della formazione che agisce, un sabotaggio oppure uno studio approfondito. Da confermare le regole di risoluzione, i requisiti di composizione e le conseguenze precise.

5.10.1 Osservazione dei movimenti. Il compito degli esploratori non si limita alle formazioni non armate: essi osservano e studiano i movimenti dei gruppi armati, degli esploratori avversari e di ogni altra formazione. Se rilevano che una colonna avversaria si è mossa lungo una strada per due caselle consecutive, se ne deduce che stia seguendo quella strada fino alla destinazione o a una sua ramificazione.

5.11 Imboscata. L'imboscata è un'azione di posizione. Su qualunque casella della mappa il giocatore può collocare un proprio gruppo armato e assegnargli l'ordine di imboscata: il gruppo resta lì, narrativamente nascosto o comunque disposto. Se un gruppo armato avversario entra in quella casella, l'imboscata scatta.

5.11.1 L'imboscata non richiede alcuna menzogna del gioco. L'avversario non individua il gruppo appostato perché quella casella non è per lui confermata ai sensi del punto 5.3, il che è pienamente coerente con il vocabolario degli stati di conoscenza.

5.11.2 L'imboscata non è un tipo nuovo di battaglia. Chi la tende dispone del vantaggio di schieramento già previsto dal punto 9.3.2, cioè di un numero maggiore di turni prima dell'arrivo avversario.

5.11.3 L'imboscata ha un costo proprio: un gruppo appostato è fermo, consuma rifornimenti e non produce nulla, e se l'avversario cambia itinerario i turni impiegati sono perduti.

5.12 Costruzione in campagna. Alcune macchine da guerra, non tutte, possono essere costruite direttamente in campagna: un gruppo fermo in una casella qualificata come bosco o zona alberata può abbattere alberi e costruirla sul posto. Le restanti arrivano già pronte dalla patria al quartier generale secondo il punto 5.2.1.

5.11 Aggiramento. Due formazioni possono sfilarsi in caselle adiacenti senza ingaggiarsi. Una colonna avversaria può quindi oltrepassare l'esercito del giocatore e puntare su un obiettivo sguarnito. Questo comportamento è voluto ed è una possibilità tattica riconosciuta, non un difetto da correggere.

## 6. Innesco della battaglia e blocco della campagna

6.1 La compresenza di due gruppi armati contrapposti nella stessa casella non obbliga a combattere. La battaglia può essere rifiutata, e due eserciti possono restare fronte a fronte senza attaccarsi. Il non combattimento è un esito normale e non un'eccezione: storicamente la battaglia campale avveniva solo quando entrambi i contendenti contavano di vincere.

6.1.1 È però sufficiente la volontà di uno dei due. Chi vuole combattere impone lo scontro; chi non vuole deve essersene andato prima. Lo stallo resta quindi possibile finché conviene a entrambi, e cessa non appena uno dei due cambia intenzione.

6.1.2 Conseguenze volute. Rifiutare significa muoversi in tempo, e quindi vedere arrivare l'avversario: la ricognizione della sezione 5.4 cessa di essere soltanto un modo di sapere dove sono le cose e diventa lo strumento con cui si evitano le battaglie che non si vogliono. Chi è lento non può rifiutare: una colonna carica di macchine non si sfila in tempo, per cui marciare su una piazzaforte è di per sé la decisione di accettare qualunque scontro capiti lungo la strada.

6.1.3 Da tarare con attenzione. La frequenza effettiva degli scontri dipende adesso in misura determinante dal carattere degli ufficiali avversari di cui al punto 14.3: se tutti aggressivi, il rifiuto resta teorico; se tutti prudenti, non si combatte più. La manopola esiste già e va tarata sapendo che decide molto più di prima.

6.2 L'accettazione della battaglia non forza il passaggio immediato alla schermata di battaglia. Nella casella interessata compare un comando che avvia lo scontro, e il passaggio avviene quando il giocatore lo decide.

6.3 Dal momento in cui una battaglia è stata accettata ed è quindi in sospeso, ogni altra attività di quella campagna è preclusa. Il giocatore può operare liberamente in altre campagne, dove ha allocato altre risorse e altre truppe. La regola vale sempre e per chiunque.

6.3.1 Il blocco scatta all'accettazione della battaglia e non alla compresenza nella casella. Fuori dalla battaglia la campagna continua a scorrere: due eserciti fermi uno di fronte all'altro consumano comunque rifornimenti, per cui lo stallo ha un costo.

6.4 Durante il blocco nulla avanza in quella campagna, né per il giocatore né per l'avversario: nessuna produzione, nessun movimento, nessun turno. Diversamente, il rinvio verrebbe punito dal trascorrere del tempo reale, in violazione del principio 4.

6.5 Lo scopo dichiarato di questo meccanismo è consentire al giocatore di chiudere l'applicazione e affrontare la battaglia quando dispone del tempo necessario per portarla a termine.

6.6 Se l'applicazione viene chiusa a battaglia iniziata, la ripresa avviene esattamente dal punto di interruzione, compreso lo stato dello schieramento in corso, il budget già speso e l'elemento eventualmente selezionato. Questo non richiede alcun meccanismo aggiuntivo ed è una conseguenza diretta del principio 3.

6.7 La resa di cui alla sezione 10 non è più la valvola che libera da una battaglia non voluta, poiché quella battaglia non è più obbligatorio iniziarla. È la via d'uscita da una battaglia che si sta perdendo.

6.8 Battaglie contemporanee. Più battaglie possono innescarsi nello stesso turno della stessa campagna. In tal caso il giocatore sceglie quale affrontare per prima, e la scelta è essa stessa una decisione tattica, poiché ogni casella dichiara le truppe e le risorse che contiene.

6.9 In presenza di più battaglie in sospeso, e soltanto in quel caso, è consentita un'unica attività di campagna in via eccezionale: dirottare i superstiti della battaglia appena conclusa, vinta o persa, verso un'altra battaglia in sospeso. Nessun'altra attività è sbloccata.

6.10 I superstiti dirottati non possono partecipare dall'inizio del secondo scontro, poiché le battaglie sono nominalmente simultanee: arrivano come rinforzi in turni successivi, secondo la sezione 11.

## 7. Campo di battaglia

7.1 Il campo di battaglia è una griglia esagonale con esagoni orientati con la punta in alto. Le celle si dispongono quindi in righe orizzontali continue, e due dei sei vicini di ogni cella si trovano esattamente a est e a ovest. Questa scelta di orientamento è vincolante e discende dal modello di navigazione descritto nel documento 02.

7.2 I formati vanno da una quindicina di celle per gli scontri di confine fino a un massimo di cento celle, corrispondenti a dieci righe da dieci.

7.3 Le righe sono numerate a partire dalle retrovie del giocatore. La riga uno è la retrolinea più profonda dello schieramento avversario, la riga dieci quella del giocatore, secondo l'orientamento adottato nella sezione 10.

7.3.1 Basi. Un accampamento sommariamente fortificato funge da quartier generale sul campo di battaglia. Le due basi occupano posizioni fisse e contrapposte: quella del giocatore nella riga in fondo, quella avversaria nella riga più lontana. La fissità è voluta, perché dà al campo una geografia stabile che chi ascolta memorizza una volta sola anziché ricostruirla a ogni battaglia.

7.3.2 La fortificazione mobile da campo, cioè l'accampamento trincerato ricostruito a ogni tappa, non appartiene alla fase arcaica e costituisce una delle capacità sbloccabili in patria secondo il punto 2.6.

7.4 Caratteristica del campo. Il luogo in cui si combatte determina una caratteristica unica valida per l'intero campo, dichiarata una sola volta all'apertura della battaglia. Nessuna cella dichiara un terreno proprio.

7.4.1 La scelta di una caratteristica unica anziché di un terreno cella per cella è deliberata: su un campo da cento celle il terreno per cella avrebbe il carico informativo più alto dell'intero progetto. La caratteristica unica conserva però il fatto storico decisivo, cioè che il campo si sceglieva prima di accettare battaglia.

7.4.2 Conseguenza voluta. In combinazione con il punto 6.1, le caselle della mappa di campagna cessano di essere intercambiabili: si può attendere, spostarsi e accettare lo scontro quando il terreno conviene.

7.5 Ostacoli. Alcuni campi possono contenere ostacoli. Gli ostacoli di carattere minore forniscono orientamento, varietà e una sfida accessoria, non occupano più di quattro celle, non sono interattivi e vengono annunciati immediatamente come tali; restano confinati alle griglie da cento celle e ai pochi campi che li prevedono.

7.5.1 Fa eccezione l'assedio. Le mura di una piazzaforte sono per definizione un ostacolo esteso e determinante per l'esito, e il limite generale del punto 7.5 non si applica a esse. Il contrappeso non è la riduzione dell'ostacolo ma la disponibilità delle macchine e delle opere mobili con cui affrontarlo, secondo la sezione 8 bis.

7.6 La presenza di ostacoli è dichiarata all'apertura della battaglia, così che il giocatore sappia di doverli cercare. La loro individuazione avviene esplorando la griglia.

7.7 A battaglia iniziata l'informazione è completa su ciò che è sceso in campo: tutte le forze presenti sulla griglia sono visibili e annunciabili, e nessuna cella nasconde alcunché.

7.7.1 Resta invece ignoto ciò che l'avversario trattiene nel proprio deck. La sorpresa esiste e passa per il trattenimento e il successivo dispiegamento di forze nei turni successivi, secondo il punto 9.3.5, cioè attraverso annunci espliciti anziché attraverso celle da riscoprire. Chi non vede non deve quindi riesplorare ripetutamente decine di celle in cerca di inganni.

7.7.2 Costo dichiarato e accettato. Circa due terzi degli scontri storici contengono inganno od occultamento all'interno del contatto. Il campo trasparente vi rinuncia deliberatamente, perché nascondere elementi su una griglia esplorata all'ascolto trasformerebbe ogni cella da risposta in domanda.

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

## 8 bis. Piazzeforti e assedi

8b.1 Una piazzaforte, città o fortezza è un elemento collocato su una casella della mappa di campagna ordinaria. Non esiste un formato di mappa dedicato all'assedio.

8b.2 L'assedio si combatte. Non esiste come attesa: non si prendono città per fame, non si passano turni in attesa che le scorte dell'assediato si esauriscano. Lo scontro avviene sul campo di battaglia ordinario, dove le mura costituiscono l'ostacolo di cui al punto 7.5.1.

8b.3 Macchine e opere. Le macchine d'assedio e le costruzioni mobili sono predisposte in patria e movimentate già pronte fino al quartier generale, oppure costruite in campagna nelle caselle boscose secondo il punto 5.12. All'apertura dell'assedio il giocatore dispone quindi già degli strumenti e non deve attendere di costruirli sul posto.

8b.4 Seconda via. Un assedio può risolversi anche senza assalto, mediante scontro diretto fra eserciti davanti alla piazzaforte: chi vince la prende quasi vuota.

8b.5 Blocco. Un esercito collocato davanti a una piazzaforte, finché resta in quella casella, impedisce alla posizione di ricevere risorse e le procura un lieve malus di efficacia. Trascorsi alcuni turni, cresce la probabilità che le forze assediate escano per tentare di rompere il blocco.

8b.6 Il blocco non prende la piazzaforte: la costringe a uscire. Fornisce quindi al giocatore il modo di provocare lo scontro campale del punto 8b.4 anziché doverlo attendere. Non si introducono fame, esaurimento delle scorte o altri meccanismi di attesa.

8b.7 Costo dichiarato e accettato. La ricerca descrive l'assedio storico come processo logistico su scala di settimane o mesi, il cui esito si decideva su tempo, scorte e opere, e in cui l'assalto era semmai l'ultimo giorno. Il gioco vi rinuncia deliberatamente, e con esso al divario fra la presa con le macchine e la presa per fame.

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

9.4 L'informazione resta completa per tutta la durata dello scontro relativamente a ciò che è sceso in campo, secondo il punto 7.7.

9.5 Comando. Il giocatore comanda le proprie forze direttamente e in ogni turno, con una sola eccezione: i reparti corpo a corpo che ingaggiano lo scontro su suo ordine cessano di essere controllabili dal momento del contatto. Tornano controllabili quando il contatto finisce, cioè quando l'avversario è disfatto oppure quando il reparto si è disimpegnato secondo la propria tendenza al disingaggio di cui al punto 3.4.2.

9.5.1 Non esistono ufficiali dalla parte del giocatore: l'esecuzione degli ordini non fallisce e non è mediata. La regola del punto 9.5 riguarda la disponibilità del reparto, non l'affidabilità del comando.

9.5.2 La ragione documentale è che il problema del comando antico non era decidere ma farsi obbedire: un ordine impartito a truppe già in mischia non arrivava, e la riserva esisteva per conservare qualcuno cui poter ancora dare ordini.

9.5.3 Conseguenze volute. La riserva del punto 9.3.5 acquista il suo significato storico e mette in mano una decisione vera a ogni turno, cioè quanto impegnare e quanto tenere disponibile. In caso di ritirata, inoltre, i reparti a contatto non possono essere estratti: si salva chi era arretrato e si perde chi era impegnato, il che restituisce senza regole aggiuntive la differenza fra ripiegamento ordinato e ripiegamento impigliato.

9.6 Munizioni. Il tiro non è un automatismo. A ogni turno il giocatore decide se far tirare i reparti da lancio, la cui dotazione è limitata secondo il punto 3.4.3. In combinazione con le due gittate del punto 3.4.1 la decisione è sostanziale: tirare subito alla distanza di disturbo, oppure conservare le scariche per la distanza a cui il tiro uccide.

## 10. Ritirata combattuta

10.1 In qualunque momento il giocatore può dichiarare la resa mediante un comando dedicato. La resa non conclude immediatamente lo scontro: apre una fase di ritirata combattuta.

10.2 La resa è disponibile solo dopo un numero minimo di turni trascorsi. Tale soglia si accorcia in funzione delle perdite subite, espresse come proporzione delle forze iniziali e non come valore assoluto, così che la regola si comporti allo stesso modo su tutti i formati di scontro.

10.3 Durante la ritirata combattuta lo scontro prosegue finché le forze avversarie non raggiungono una riga di soglia prossima alle retrovie del giocatore. Esempio su griglia da dieci righe: la battaglia prosegue finché l'avversario non raggiunge la riga otto.

10.4 In questa fase il giocatore spende volume per ritirare unità dalle righe più arretrate, che sono salvate integralmente, e per spostare unità in avanti allo scopo di sbarrare l'avanzata avversaria e guadagnare turni. Il costo del ritiro dipende dalla riga di partenza secondo il punto 8.7: ritirare da una riga più avanzata costa più volume.

10.4.1 I reparti a contatto non possono essere ritirati, poiché non sono controllabili secondo il punto 9.5. La ritirata salva chi era arretrato e non chi era impegnato.

10.5 Sbarrare una traiettoria coincide con l'occupare interamente una riga. Su griglia esagonale i vicini di una cella appartengono alla sua riga e alle due adiacenti, quindi per superare una riga occorre necessariamente attraversarla, e una riga interamente occupata è per costruzione una barriera. Questa coincidenza è voluta e va preservata, perché rende l'operazione verificabile con la scansione di riga descritta nel documento 02.

10.6 Le forze evacuate ricompaiono sulla mappa di campagna in una casella arretrata rispetto alla direzione di provenienza, mai in una casella adiacente qualunque: una ritirata non può risolversi in un avanzamento.

10.7 L'avversario dispone a sua volta della ritirata, con due limitazioni permanenti che costituiscono un vantaggio nascosto del giocatore ai sensi della sezione 13: può ritirare unità soltanto dalla propria riga più arretrata, e la sua propensione alla ritirata è molto bassa. L'evento resta quindi possibile e costituisce una sfida quando accade, senza trasformare le campagne in inseguimenti interminabili.

10.8 Ogni ritirata avversaria è annunciata quando avviene, poiché diversamente le forze nemiche sparirebbero dal campo senza spiegazione.

10.9 Da misurare con le simulazioni. Il rapporto tra la soglia di riga, la soglia minima di turni e il budget di volume disponibile determina se la resa sia una scelta dolorosa o una via di fuga conveniente. Con un margine ampio e un budget generoso, un giocatore accorto dichiarerebbe la resa al primo turno utile evacuando quasi tutto, e la sconfitta cesserebbe di avere un costo. È una grandezza da tarare numericamente e non a impressione.

10.10 La soglia minima di turni del punto 10.2 ha assunto un rilievo che prima non aveva, poiché determina la durata di una battaglia perduta. Vedi il punto 15.2.2: nessuno dei due contendenti vuole essere il primo a ritirarsi, e in assenza di rottura improvvisa delle formazioni due giocatori ostinati proseguirebbero fino all'annientamento reciproco. La taratura di questa soglia è quindi critica.

10.11 Costo dichiarato e accettato. Storicamente la ritirata era la fase più costosa della guerra, e le perdite maggiori si producevano durante e dopo di essa. Il gioco vi rinuncia deliberatamente: ritirarsi costa la battaglia, non l'esercito. L'entità del costo resta materia di bilanciamento secondo il punto 10.9.

## 11. Rinforzi

11.1 I superstiti dirottati da una battaglia conclusa verso un'altra battaglia in sospeso arrivano come rinforzi in un turno successivo all'inizio del secondo scontro.

11.2 Il turno di arrivo è determinato da una formula unica che combina la distanza in caselle tra le due località, la durata della battaglia già conclusa e il volume del distaccamento secondo il punto 3.4.4. Non si impiegano scaglioni né tabelle a doppia entrata, in applicazione del punto 13.3 della carta. Come effetto della formula, un distaccamento leggero arriva prima di uno carico di macchine senza bisogno di regole aggiuntive: l'effetto voluto resta identico, muta soltanto la grandezza che lo produce.

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

12.4 Le imboscate non sono un fatto casuale: derivano dalle informazioni acquisite, dalla previsione dell'itinerario avversario e dalle propensioni dell'avversario, secondo i punti 5.10.1 e 5.11 e la sezione 14.

12.5 Costi dichiarati e accettati del perimetro del caso. La probabilità di guasto vale per ciascuna macchina, quindi anche nella fase arcaica, dove storicamente una macchina o funzionava o veniva bruciata dal nemico e la manutenzione vera riguardava soltanto la macchina a molla ritorta, che compare tardi. Resta inoltre fuori dal gioco il fallimento del rifornimento, cioè il deposito trovato vuoto o guasto, che era il modo tipico in cui una campagna antica andava a rotoli.

## 13. Vantaggi nascosti del giocatore

13.1 Alcune regole avvantaggiano deliberatamente il giocatore per evitare che vincere risulti tedioso o interminabile. Sono nascoste al giocatore, non al progetto: vanno raccolte in un unico punto ed essere note al programma di verifica del bilanciamento, che diversamente misurerebbe probabilità irreali.

13.2 Vantaggi attualmente stabiliti: l'avversario può ritirare unità soltanto dalla propria riga più arretrata; la sua propensione alla ritirata è molto bassa.

13.3 Ogni vantaggio nascosto introdotto in seguito va aggiunto a questo elenco e al documento dei dati.

## 14. Avversario

14.1 Il livello di difficoltà generale si imposta nelle impostazioni del gioco e agisce sulle risorse e sui margini a disposizione dell'avversario.

14.2 Indipendentemente dal livello generale, i singoli ufficiali avversari differiscono per comportamento. Due battaglie contro ufficiali dello stesso regno possono quindi risultare diversamente impegnative.

14.3 Gli ufficiali non impiegano intelligenze diverse ma la stessa con parametri diversi: propensione all'attacco, tolleranza alle perdite, tendenza all'accerchiamento o allo sfondamento centrale, propensione all'imboscata, propensione alla ritirata. La propensione all'attacco ha assunto un peso maggiore da quando la battaglia può essere rifiutata, secondo il punto 6.1.3.

14.6 Gli avversari progrediscono. Le loro capacità crescono nel tempo e al passaggio di fase dispongono di quanto prima non avevano, secondo i punti 2.6.4 e 2.8. I loro valori si muovono dentro le rispettive forbici come effetto dei loro miglioramenti, secondo il punto 13.2.1 della carta.

14.7 L'inverno vale anche per gli avversari, che durante la pausa obbligatoria svolgono le proprie attività di costruzione, rifornimento e addestramento, secondo il punto 5.9.

14.4 Difficoltà generale e carattere dell'ufficiale non si sommano in modo opaco. La difficoltà generale regola risorse e margini, il carattere dell'ufficiale regola soltanto il comportamento. Il giocatore deve poter capire perché una battaglia è dura.

14.5 Parità informativa. Se un giocatore che guarda può intuire dal comportamento sulla mappa di avere di fronte un comandante prudente, chi ascolta deve poterlo sapere dai medesimi indizi. Ogni ufficiale è quindi presentato prima della battaglia con nome, reputazione e quanto è noto sul suo conto, e le sue mosse sono annunciate in modo che il carattere risulti percepibile.

## 15. Conclusione della battaglia e ritorno in campagna

15.1 Durante la battaglia non si consuma alcuna risorsa di campagna.

15.2 A scontro concluso esistono soltanto superstiti e perdite. Non esistono prigionieri come esito di battaglia. La cattura di forze avversarie è eventualmente possibile mediante azioni dal piano di campagna che non giungono allo scontro.

15.2.1 Costo dichiarato e accettato. La cattura in massa era l'esito documentato del collasso di un esercito antico ed è l'esito dominante del caso meglio documentato delle due fasi. Il gioco vi rinuncia deliberatamente.

15.2.2 Definizione dello sconfitto. Sconfitto è chi attiva per primo la ritirata, indipendentemente dalle perdite: si può perdere una battaglia avendo inflitto più danni di quanti se ne siano subiti. Non esistono esiti in parità.

15.2.3 La battaglia si conclude in due soli modi: all'esaurimento dei turni di ritirata a disposizione di chi l'ha dichiarata, secondo la sezione 10; oppure, se nessuno dei due si ritira, quando uno dei due è stato annientato.

15.2.4 La sconfitta è quindi una decisione dichiarata e non il risultato di un calcolo. La scelta è deliberata e serve a evitare che il gioco debba designare un vincitore con una regola arbitraria nei casi in cui nessuno dei due ceda. Il costo storico è che l'esito frequente dei grandi scontri antichi era invece l'indecisione con doppia rivendicazione, e che la vittoria netta non era il caso normale.

15.3 La battaglia si chiude con un resoconto: perdite subite, perdite inflitte all'avversario, e le altre informazioni utili a valutare l'esito. Da confermare il contenuto esatto del resoconto.

15.4 Si torna quindi al piano di campagna, dove giocatore e avversario collocano le forze superstiti. Il vincitore sceglie per primo, lo sconfitto in seguito.

15.5 Il vincitore, e soltanto il vincitore, può scegliere di restare nella casella contesa. Chi si è ritirato arretra in una casella più indietro, secondo il punto 10.6.

15.6 Le forze evacuate con la ritirata combattuta ricadono sotto la limitazione del punto 10.6 e si collocano in una casella arretrata rispetto alla direzione di provenienza.

15.7 Il totale di atomi per archetipo si aggiorna con le perdite. La ridistribuzione negli assetti avviene secondo la sezione 4, e in assenza di scelta esplicita gli atomi si raggruppano nell'assetto più piccolo disponibile.

15.8 Se non vi sono altre battaglie in sospeso, i turni di campagna riprendono il loro corso normale.

---

## 16. Riepilogo dei punti aperti

16.1 Rinviato per scelta, non per omissione. Le regole di risoluzione del combattimento e tutti i valori numerici a esse collegati, punto 9.2: dipendono dall'insieme degli asset militari che emergerà dalla documentazione storica e dalla definizione architetturale, e verranno scritti allora. Chi riceve questo documento non deve colmare la lacuna di propria iniziativa.

16.2 Da confermare prima delle parti corrispondenti. Sorte delle truppe della fase precedente e composizione della sequenza di acquisizioni, punto 2.8.1. L'elenco definitivo degli archetipi, punto 3.2. Risorse e installazioni, punto 5.5. Che cosa si possa muovere e in quale misura in ciascun turno, punto 5.6.8. Entità e recupero di stanchezza e manutenzione, punto 5.7. Effetto dell'approvvigionamento sul budget di schieramento, punto 5.8. Caratteri delle stagioni intermedie, punto 5.9.2. Regole di sabotaggio e studio approfondito, punto 5.10. Base di calcolo del riporto di budget, punto 9.3.4. Momento da cui contare i turni dei rinforzi, punto 11.3. Vincoli di ingresso dei rinforzi, punto 11.8. Contenuto del resoconto di fine battaglia, punto 15.3.

16.3 Da stabilire in sede di definizione dei valori. Quale fra la catena dal quartier generale e la sosta con raccolta automatica costituisca la via ordinaria di rifornimento, punto 5.6.6. Le differenze di partenza fra un regno e l'altro, che vanno fissate una volta sola e non riestratte a ogni partita, punto 13.2.3 della carta. Il tetto alla marcia forzata e il costo dell'addestramento, che sono decisioni di progetto e non dati storici e vanno annotati come tali.

16.4 Da tarare con le simulazioni prima della pubblicazione. Il margine di convenienza della ritirata combattuta, punto 10.9. Il rapporto tra budget di schieramento iniziale e profondità concessa, che determina quanto pesi il vantaggio della sorpresa. La soglia minima di turni prima della resa, che adesso determina la durata di una battaglia perduta, punto 10.10. Il carattere degli ufficiali avversari, che determina la frequenza effettiva degli scontri, punto 6.1.3. Il costo di mantenimento dei miglioramenti, unico freno automatico all'accumulo di forze, punto 4.14.1. L'ampiezza della fascia entro cui il tiro uccide, punto 3.4.1.

16.5 Impianti storicamente contestati e mantenuti per scelta, da non riaprire. Il modello di combattimento a consumo progressivo, punto 4.3.1. L'esclusione dei prigionieri, punto 15.2.1. La ritirata che costa la battaglia e non l'esercito, punto 10.11. Il campo di battaglia trasparente, punto 7.7.2. Il perimetro solo militare, punto 1.3.1. Il perimetro del caso, punto 12.5. L'equivalenza fra battaglia in marcia e battaglia schierata, punto 16.6. L'assedio combattuto anziché atteso, punto 8b.7.

16.6 Una battaglia è tale comunque sia cominciata: non esiste differenza fra l'essere colti in marcia e l'essere schierati. Costo dichiarato e accettato: la ricerca documenta che una fanteria pesante sorpresa in colonna perdeva dal doppio al quadruplo rispetto a una battaglia campale. La decisione è coerente con i punti 4.3.1 e 7.7. L'imboscata del punto 5.11 non ne risente, poiché il vantaggio di chi la tende è quello dello schieramento anticipato.
