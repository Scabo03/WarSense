# Documento di progetto del gioco

Documento 01 di 05 — versione 3.3

Novità della versione 3.3, per decisione del titolare dopo la prima prova su dispositivo della fase B (prima tranche di semplificazioni; le modifiche sono volute e non vanno trattate come sviste): soppressa la doppia gittata — ogni reparto da tiro ha una sola gittata utile e una sola resa, e la disponibilità del bersaglio torna binaria (3.4.1, 9.6); la munizione diventa proprietà fissa e dichiarata del reparto e non si sceglie al momento del tiro, fermo restando l'accoppiamento fra offesa e protezione (3.3.1, 3.3.2, 9.9); ogni reparto riceve alla discesa in campo una lettera stabile per la designazione senza ambiguità (nuovo punto 9.4.3); l'annuncio degli esiti dei combattimenti abbandona i numeri di danno per fasce descrittive del vocabolario chiuso (9.7.1); il volume speso e residuo dell'avversario non è comunicato in alcuna forma (nuovo punto 9.3.7).

Novità della versione 3.2, per decisione del titolare in sede di revisione delle chiusure: la base di calcolo delle perdite ai fini della resa, della ritirata combattuta e di ogni soglia che dipende dalle perdite di battaglia è costituita dalle sole forze effettivamente impiegate sul campo, riserve del deck escluse (10.2, 10.2.1); il tiro colpisce soltanto avversari e non esiste fuoco amico in alcuna forma, regola dichiarata al nuovo punto 9.6.2. Tutte le altre chiusure della versione 3.1 sono state esaminate dal titolare e confermate.

Novità della versione 3.1, prodotta nella fase di architettura tecnica su delega del titolare: chiusura di tutti i punti contrassegnati come da confermare al punto 16.2 della versione 3.0. In particolare: sequenza delle acquisizioni e ambiti della soglia distribuita (2.8.2); elenco definitivo degli archetipi (3.2.3); installazioni e voci acquistabili fuori dall'inverno (5.5.1.4.1 e 5.5.2); elenco chiuso delle azioni di campagna (5.6.8.1); ordine di risoluzione della giornata (5.6.11); stanchezza e manutenzione (5.7, 5.7.1, 5.7.2); effetto dell'approvvigionamento (5.8); stagioni intermedie (5.9.2); sabotaggio e studio approfondito (5.10.2); magazzino, torri e ricognizione rispetto al taglio (5.15); assedio della fortezza (5.14.3.6); sortita resa deterministica (8b.5, 8b.5.1); base del riporto di volume (9.3.4); ordine dei turni in battaglia (9.4.1); cella a occupante unico confermata (9.4.2); conteggio e vincoli dei rinforzi (11.3, 11.8); resoconto di fine battaglia (15.3.1). Le motivazioni di ogni chiusura sono nel registro delle decisioni architetturali. Nessuna decisione della versione 3.0 è stata riaperta.

## Come leggere questo documento

Questo documento descrive il gioco: cosa succede, con quali regole, con quali conseguenze. Non descrive il programma, che è oggetto del documento di architettura tecnica, e non descrive come le informazioni vengono presentate a chi ascolta, che è oggetto del documento 02.

Va letto insieme alla carta dei principi non negoziabili, che prevale in caso di conflitto.

Ogni requisito è numerato per riferimento diretto. I punti contrassegnati come da confermare sono decisioni non ancora prese: vanno chiuse prima che la parte corrispondente venga realizzata, e nel frattempo nessun modello deve colmarle di propria iniziativa. I punti contrassegnati come proposta sono suggerimenti del redattore, non decisioni del titolare del progetto.

Questa versione recepisce, oltre alla scrematura dell'inventario dei fattori storici conclusa a valle della ricerca confluita nel documento 04, le direzioni di progettazione stabilite nella fase tre: struttura del turno di campagna, percezione del passaggio di fase, inverno, costruzioni e postazioni in campagna, rifornimento, combattimento e vantaggio della sorpresa. I punti contrassegnati come costo dichiarato e accettato registrano scelte che si discostano consapevolmente dal documentato: non sono sviste e non vanno corrette per aderenza storica. Il punto 16.5 ne raccoglie l'elenco.

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

2.6.2.1 Tetto d'epoca. In ciascun ambito esiste un limite proprio della fase storica in corso. Chi raggiunge l'acquisizione finale di un ambito non può andare oltre finché la fase non cambia, e avendo esaurito ciò che vi si poteva spendere sposta necessariamente le proprie risorse su altri ambiti. La soglia distribuita non è quindi una regola che il giocatore debba conoscere e rispettare per non restare bloccato: è una conseguenza di come è fatto il mondo. L'ambito che si chiude comunica inoltre un'informazione positiva, cioè che lì si è giunti in fondo, e non una porta che non si apre per ragioni ignote.

2.6.2.2 Impostazione espressamente respinta, da non reintrodurre. Non va aggiunto alcun quadro che dichiari in ogni momento quanti ambiti siano coperti e quanti manchino alla soglia, né alcun catalogo delle acquisizioni future con relativi costi. La comunicazione esplicita della soglia è stata valutata e scartata come artificiosa e favorevole al ragionamento esterno al gioco. Il tetto d'epoca ottiene lo stesso risultato senza chiedere al giocatore di leggere un regolamento.

2.6.3 Raggiunta la soglia distribuita, il gioco dichiara una volta sola l'ingresso nella fase successiva. La dichiarazione non è il momento in cui si ottengono le capacità, che restano legate alle singole acquisizioni, ma è il momento in cui i tetti d'epoca del punto 2.6.2.1 si innalzano: è la dichiarazione stessa a comunicare che gli ambiti chiusi hanno riaperto e quali. Da quel momento, e non prima, diventa possibile acquisire nuovi miglioramenti negli ambiti che avevano raggiunto il limite della fase precedente.

2.6.3.1 Il passaggio di fase è netto ed esplicito. Si annuncia con un riquadro narrativo che si chiude con un comando di conferma, con il cambio del tema musicale e dell'ambiente sonoro, e con la dichiarazione dei mutamenti che ne conseguono. Non essendovi alcun limite di tempo, la schermata resta finché il giocatore non la conferma. Il riquadro non è richiamabile in seguito: il registro degli eventi del punto 5.17 è la cronaca interna di una singola campagna, mentre il passaggio di fase riguarda il regno nel suo complesso.

2.6.3.2 È il primo momento del gioco in cui qualcosa si sblocca senza che alcun numero salga. Ciò soddisfa il vincolo del punto 2.5.3 senza reintrodurre per vie indirette l'aumento generalizzato delle prestazioni.

2.6.4 Il passaggio di fase non è però una formalità, perché muta il mondo attorno al regno. Gli avversari dispongono di capacità che prima non avevano; cambiano la geografia attorno al regno, i regni e gli Stati confinanti e i rivali, a rappresentare la progressione storica nell'arco dei secoli; si aprono campagne nuove da intraprendere o da subire. È questo che restituisce al passaggio di fase la sua nettezza percepibile, secondo il punto 2.5.3.

2.6.5 Ritardo volontario. Ritardare il passaggio di fase è una strategia legittima e non un errore. Le risorse eccedenti trovano sempre dove essere spese, cioè in derrate e scorte, fortificazioni in patria, fortificazione delle vie di comunicazione verso i vari fronti e reclutamento, e chi rinvia entra nell'epoca nuova più forte, ma con truppe e materiale ormai un poco datati. Il ritardo conserva quindi un vantaggio reale e paga un prezzo proprio, secondo i punti 2.8.1.2 e 5.5.1.5.

2.6.6 Principio generale della progressione. Si cresce tendenzialmente tutti insieme, ciascuno più specializzato in ambiti diversi. All'inizio di una fase nuova il giocatore non si trova mai arretrato di colpo di fronte ad avversari già perfettamente equipaggiati: il divario fra i regni è di forma e non di livello. È anche la ragione per cui il ritardo volontario non costituisce una trappola.

2.7 L'ordine delle acquisizioni non è arbitrario. Di sette innovazioni è documentato l'ordine esatto di comparsa, e la sequenza degli sblocchi si appoggia a quel dato. Ogni capacità nuova ha inoltre un prezzo documentato: il salto tecnologico storicamente si pagava, e si paga anche nel gioco.

2.7.1 Poiché le acquisizioni arrivano sgranate, l'insieme degli archetipi disponibili non è fisso per fase ma si allunga e si accorcia con il progredire del regno. Vedi il punto 3.2.

2.8 L'avversario progredisce anch'esso, e al passaggio di fase dispone di capacità nuove, secondo il punto 2.6.4.

2.8.1 Sorte delle truppe alla transizione. Le truppe e gli asset della fase precedente restano quelli che sono: non si convertono, non si aggiornano e non vanno congedati. Le truppe e gli asset di tipo nuovo si addestrano da capo, poco per volta. Anche gli avversari continuano ad avvalersi del materiale della fase precedente.

2.8.1.1 Conseguenza sulla percezione. All'inizio dell'epoca nuova il materiale nuovo è raro e prezioso, e col tempo diventa comune e ordinario. La prima formazione di tipo nuovo che si schiera si distingue perché è rara in mezzo a un esercito d'epoca precedente, non perché sia più potente: la differenza fra le epoche si sente nella disponibilità e non nella potenza, coerentemente con il punto 2.5.1.

2.8.1.2 Conseguenza sull'equilibrio. La regola impedisce che il rinvio del passaggio di fase diventi la strategia dominante. Se le truppe accumulate si convertissero, attendere sarebbe sempre la mossa migliore; restando com'erano, chi ha accumulato molto entra nell'epoca nuova con un esercito grande ma datato, che continua a costare mantenimento e a occupare il bilancio invernale necessario ad addestrare il nuovo.

2.8.2 Chiuso nella fase di architettura. Gli ambiti di avanzamento sono cinque, e valgono per tutte le fasi: armi e protezioni; montature e macchine; comando e trasmissione; logistica e vie; economia militare. La soglia distribuita del punto 2.6.2 richiede un numero minimo di acquisizioni compiute in un numero minimo di ambiti diversi; entrambi i numeri sono grandezze del documento 03 e si tarano con le simulazioni.

2.8.2.1 Le acquisizioni della prima versione, per ambito e in ordine di sblocco, appoggiate alla sequenza documentata delle sette innovazioni databili e agli intervalli delle non databili. Armi e protezioni: ferro come materiale ordinario (acquisibile nella fase arcaica); protezione diffusa e alleggerita (antica); fionda con proiettile di piombo (antica). Montature e macchine: cavalleria montata, che rende progressivamente obsoleta la piattaforma trainata (arcaica); sistema d'assedio integrato (antica); macchina da tiro a tensione e poi a torsione (antica, in quest'ordine). Comando e trasmissione: rete di stazioni e staffette (arcaica); segnali codificati (antica); catena di comando articolata (antica). Logistica e vie: carico animale migliorato (arcaica); macinatura in marcia (antica); fortificazione mobile da campo (antica, secondo il punto 7.3.2). Economia militare: corpo permanente mantenuto (arcaica); moneta coniata, che separa il mantenimento dalla paga (antica); addestramento istituzionale (antica). L'ultima acquisizione di ciascun ambito nella colonna della propria fase è il tetto d'epoca del punto 2.6.2.1.

2.8.2.2 I nomi delle acquisizioni sono designazioni funzionali e non nomi storici, in conformità al principio 12; costi, durate e prerequisiti risiedono nei file di dati. L'elenco si estende nelle fasi successive senza modificare la struttura.

## 3. Archetipi di unità

3.1 Nessuna unità è identificabile con una civiltà, un popolo o una formazione storica determinata. Le unità sono archetipi definiti per funzione, ai quali si applicano tratti modificatori.

3.2 Gli archetipi funzionali previsti nelle prime due fasi sono, in forma provvisoria: fanteria leggera, fanteria pesante d'urto, guardia d'élite, tiratori, cavalleria leggera da ricognizione, cavalleria manovrata, piattaforma mobile trainata, macchina d'assedio. L'elenco non è fisso per fase: gli archetipi si sbloccano progressivamente secondo il punto 2.6 e alcuni cessano di essere disponibili, come la piattaforma trainata, che diventa obsoleta.

3.2.3 Chiuso nella fase di architettura: l'elenco definitivo della prima versione conta nove archetipi. Ai otto del punto 3.2 si aggiunge la macchina da tiro, distinta dalla macchina d'assedio da contatto: quest'ultima esiste in forma rudimentale fin dalla fase arcaica, mentre la macchina da tiro compare soltanto con le acquisizioni corrispondenti della fase antica, ed è l'unico caso legittimo di differenza per presenza ai sensi del punto 2.5.4. La disponibilità di ciascun archetipo è governata dalle acquisizioni secondo i punti 2.7.1 e 2.8.2.1.

3.2.1 La cavalleria non è un'arma d'urto. In nessuna delle due fasi rompe frontalmente una fanteria schierata e in ordine, perché mancano staffe, lancia in resta e bardatura. È un'arma mobile: colpisce sui fianchi, si infila nei varchi aperti nella linea per raggiungere le retrovie, e avanza rapidamente in profondità quando l'avversario ripiega, allo scopo di massimizzare le perdite inflitte. Ne discende una forma ridotta di inseguimento, confinata al campo di battaglia, che non reintroduce l'inseguimento di campagna, escluso perché presupponeva la rottura improvvisa delle formazioni.

3.2.2 I varchi nella linea non sono un'ipotesi teorica: li produce il disingaggio dei reparti in mischia di cui al punto 3.4.2.

3.3 I tratti modificatori distinguono varianti dello stesso archetipo senza moltiplicare gli archetipi. Esempio di riferimento: la fanteria d'élite di tipo spartano e la guardia scelta di tipo persiano sono entrambe guardia d'élite, l'una con un tratto di tenuta in formazione, l'altra con un tratto di versatilità e capacità di tiro. Il giocatore può disporre di entrambe senza alcuna incongruenza, e questo è uno degli scopi dichiarati dell'impostazione per archetipi.

3.3.1 Proiettili. Esistono due tipi di proiettile: leggero, che satura, e pesante, che perfora. Dalla versione 3.3, per decisione del titolare: ogni reparto da tiro impiega UN solo tipo di proiettile, che è una sua proprietà fissa e dichiarata fra le informazioni del reparto. Il giocatore non sceglie la munizione al momento del tiro. Lo stesso vale per i reparti da mischia rispetto al tipo di arma: nessuna scelta d'arma al momento dell'azione.

3.3.2 Protezioni. Esistono due tipi di protezione che rispondono in modo opposto ai due proiettili: chi è protetto dalla saturazione è esposto alla perforazione, e viceversa. Non si tratta di una protezione migliore e di una peggiore. L'accoppiamento fra offesa e protezione resta e vale quanto prima: un reparto è efficace contro certe protezioni e poco efficace contro altre, e l'annuncio lo dichiara in forma qualitativa quando si designa un bersaglio (9.9.1). La decisione tattica sul campo è quale dei propri reparti mandare contro quel bersaglio; la scelta delle protezioni si compie in patria senza sapere che cosa si incontrerà, ed è l'unico punto del gioco in cui una decisione presa in patria viene premiata o punita sul campo.

3.3.3 Nella fase arcaica la protezione pesante è rara e costosa: non esiste fanteria corazzata, esistono singoli combattenti corazzati. Diventa diffusa soltanto nella fase antica. È una delle differenze concrete e percepibili fra le due fasi ai sensi del punto 2.5.2.

3.4 Ogni archetipo possiede, come minimo: punti vita per atomo, capacità offensiva, una gittata utile secondo il punto 3.4.1, coefficiente di volume, coefficiente di penalità di avanzamento, tendenza al disingaggio secondo il punto 3.4.2, sensibilità alla stanchezza o alla manutenzione, e per i reparti da tiro il tipo di proiettile impiegato secondo il punto 3.3.1 e una dotazione di munizioni secondo il punto 3.4.3. I valori risiedono nei file di dati secondo il principio 13.

3.4.1 Gittata unica. Dalla versione 3.3, per decisione del titolare: la distinzione fra gittata di disturbo e gittata di pericolosità è soppressa. Ogni arma da tiro possiede una sola gittata utile e una sola resa; entro la gittata il tiro rende per intero, oltre non è possibile. Sparisce ogni scelta connessa alla distanza al momento del tiro: la disponibilità di un bersaglio è binaria, a portata oppure fuori portata. Il peso della decisione di quando sparare resta intatto perché la dotazione è limitata e non reintegrabile (3.4.3): si decide se spendere una scarica ora o conservarla, non a quale distanza valga.

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

5.2.2 Rifornimento. Il rifornimento passa unicamente per le catene proprie ed è la via ordinaria: l'esercito dipende dal collegamento con le proprie basi, e la guerra è quindi una faccenda di linee da tenere e da tagliare. Il tratto fra la patria e il quartier generale è automatico e non si gestisce. Non esistono requisizione negoziata presso popolazioni amiche, esaurimento progressivo delle aree attraversate né vie d'acqua che spezzino il vincolo di autonomia.

5.2.2.1 La linea non è un percorso di caselle che il giocatore debba definire, né un insieme di convogli da muovere ogni giornata. La colonna si intende allungata all'indietro con la parte posteriore dedicata all'approvvigionamento, e ciò che conta è che alle sue spalle non vi siano forze nemiche: quella condizione rappresenta il fatto che la zona retrostante sia libera perché le risorse vi viaggino. Il rifornimento è quindi una condizione dello spazio e non lavoro giornaliero.

5.2.2.2 Regola del taglio. Si considerano le sei caselle poste dietro la colonna: le tre colonne centrate su quella occupata, prese sulla riga della colonna stessa e su quella immediatamente retrostante, dove retrostante significa dalla parte del proprio quartier generale. Se in una qualsiasi di quelle caselle si trovano forze nemiche, il rifornimento è tagliato. La regola vale ovunque si trovi la colonna e a qualunque profondità. Quando la colonna occupa l'ultima riga e dietro non esiste più mappa si considerano le sole caselle esistenti; quando occupa una colonna di bordo la fascia si restringe a due caselle anziché tre.

5.2.2.3 Conseguenza voluta. Un gruppo nemico spinto in profondità non taglia alcunché: il taglio si ottiene soltanto stando addosso alle spalle di chi marcia, in una posizione a sua volta rischiosa. La scorreria in profondità conserva altri scopi, come la distruzione delle opere minori, ma non questo.

5.2.2.4 Effetti del taglio. Interrotto il rifornimento, la colonna può proseguire, ma con malus significativi, ancor più marcati di quelli della marcia forzata, e per non più di due turni consecutivi. Trascorso un solo turno senza provviste occorre poi fermarsi un turno per rifornirsi; compiuti entrambi i turni consecutivi senza provviste occorre restare fermi due turni, il primo dedicato al rifornimento e il secondo utilizzabile anche per altra azione purché non si marci. Il taglio è quindi un'arma che fa perdere tempo e logora, non una che paralizza.

5.2.2.5 I malus della mancanza di provviste e quelli della marcia forzata si cumulano, e i rispettivi conteggi di turni consecutivi restano distinti. Il riposo che rimuove i malus della marcia forzata secondo il punto 5.6.4.4 non rimuove quelli della mancanza di provviste, che cessano soltanto con la sosta di rifornimento.

5.2.2.6 Zone di rifornimento. La fortezza e il magazzino avanzato di cui al punto 5.14 riforniscono automaticamente chi si trovi nella casella della struttura o in una delle otto che la circondano. Finché ci si trova in una di quelle nove caselle il taglio non produce effetto, poiché ci si sta comunque rifornendo presso la struttura. La struttura non muta la direzione da cui proviene il rifornimento: è semplicemente una zona nella quale il problema non si pone. Una colonna che ne attraversi le vicinanze rifà scorta senza doversi fermare.

5.2.2.7 Fortezza isolata. Finché è posseduta e non neutralizzata, la fortezza rifornisce chi le sta intorno anche se il territorio circostante è tornato in mano nemica, poiché il rifornimento dipende dalla prossimità alla struttura e non da un collegamento con la patria. Una fortezza isolata resta quindi un'isola funzionante, e per svuotarla occorre prenderla.

5.2.3 Conseguenza da tenere presente. La catena resta il bersaglio più prezioso della mappa per entrambi i contendenti, e tagliare i rifornimenti avversari è una mossa concreta in combinazione con l'imboscata del punto 5.11 e con l'aggiramento del punto 5.13. Poiché però la linea è una condizione e non un insieme di convogli, la protezione non comporta alcun lavoro giornaliero di scorta, e il carico di gestione resta quello di sapere chi si ha alle spalle.

5.3 L'informazione è incompleta. Ogni casella possiede uno stato di conoscenza espresso con il vocabolario chiuso definito nel documento 02: inesplorato, presunto, avvistato con il numero di turni trascorsi, confermato. Il vocabolario è fisso e non ammette sinonimi in alcun punto del gioco.

5.4 La ricognizione ha un costo, e il costo è soprattutto in rischio. Gli esploratori possono perdersi, tornare a mani vuote o farsi notare dall'avversario. Esplorare consuma inoltre risorse, quel tanto che basta perché non sia gratuito.

5.4.1 Resta fermo che gli esploratori non innescano mai una battaglia. Ciò che accade loro si risolve interamente sulla mappa di campagna e non conduce alla schermata di battaglia: un pugno di esploratori non è un esercito.

5.4.2 Gli esploratori hanno qualità e competenza differenziate. Sono personale formato secondo il punto 4.13, e il personale formato che si perde non si rimpiazza in un turno.

5.4.3 La ragione del costo in rischio è che, se scoprire non costasse nulla, il giocatore esplorerebbe tutto e la rarità della certezza di cui al punto 5.3 si svuoterebbe da sé. Un costo espresso in sole risorse sarebbe una leva debole, perché un regno ricco comprerebbe la certezza e uno povero resterebbe cieco.

5.5 Gestione del regno. Comprende risorse, installazioni militari, reclutamento, addestramento e miglioramento, logistica e rifornimenti, manutenzione delle macchine, organizzazione degli sciami secondo gli assetti.

5.5.1 Le risorse sono cinque e distinte: il denaro, gli uomini, i metalli, il materiale da costruzione, gli animali da sella e da tiro. Il denaro paga addestramento, mantenimento e ciò che non è materia; gli uomini sono il limite del reclutamento; i metalli fanno armi e protezioni e sono il collo di bottiglia che distingue un esercito pesante da uno leggero; il materiale da costruzione fa fortificazioni, strade e opere; gli animali fanno movimento, traino e ricognizione. Nessuna delle cinque si sovrappone a un'altra e nessuna serve a un ambito solo.

5.5.1.1 Il cibo e le derrate non figurano fra le risorse del bilancio: restano affidati agli automatismi della raccolta durante la sosta e della catena di rifornimento. Farne una risorsa del bilancio significherebbe governare la stessa materia con due sistemi diversi, uno in campagna e uno in patria.

5.5.1.2 Gli animali sono contesi fra impieghi concorrenti, cioè ricognizione, traino delle macchine e formazioni montate. La concorrenza è una delle tensioni volute del bilancio.

5.5.1.3 La moneta. Il denaro è rappresentato da monete il cui materiale diventa via via più pregiato con l'avanzare delle fasi storiche: bronzo o rame nella fase arcaica, un materiale migliore nella fase antica, argento nella fase classica, oro nelle fasi medievali. Quando cambia il metallo non si converte il valore: cambia il nome e il materiale, non la quantità. Il mutamento è quindi un segno d'epoca che non aumenta alcun numero, e si annuncia in mezza frase ogni volta che il giocatore consulta il bilancio.

5.5.1.4 Riporto. Di ciascuna risorsa può avanzare al massimo il dieci per cento; l'eccedenza non si conserva. Quanto avanza può essere speso in patria nel corso dell'anno, non per le opere maggiori ma per le voci brevi, e ciò che resta si somma al bilancio dell'inverno successivo. Non esistono meccaniche di stoccaggio, conservazione o mantenimento delle scorte.

5.5.1.4.1 Chiuso nella fase di architettura: le voci acquistabili in patria fuori dall'inverno sono tre e soltanto tre: l'avvio del reclutamento, con arrivo differito degli uomini; le scorte e le derrate; la riparazione delle macchine. Costruzioni, fortificazioni, addestramento, miglioramenti e acquisizioni restano materia esclusiva dell'inverno.

5.5.1.5 Conseguenza del riporto. Chi rinvia il passaggio di fase accumula forza sotto forma di cose comprate, non di risorse tenute da parte, poiché quelle si perdono oltre la quota. Il surplus deve trasformarsi in qualcosa entro l'inverno o svanisce.

5.5.2 Chiuso nella fase di architettura. Le installazioni militari del regno sono le opere permanenti della sezione 5 bis — fortezza, torre di osservazione, magazzino avanzato, ponte, guado attrezzato, palizzata di sbarramento — più le vie di comunicazione del punto 5.14.4. Non esistono edifici di patria da gestire come oggetti distinti: le capacità della patria, cioè reclutare, addestrare, migliorare e costruire macchine, sono funzioni del regno abilitate e limitate dalle acquisizioni della sezione 2, non da fabbricati. Le fortificazioni in patria nominate al punto 2.6.5 sono le medesime opere permanenti, ordinate sulle mappe dei territori propri a scopo difensivo. Le voci acquistabili fuori dall'inverno sono quelle del punto 5.5.1.4.1.

5.5.3 Strade. La mappa di campagna possiede una rete stradale, ed esistono tipi diversi di strada che influenzano il ritmo di marcia e la lunghezza della colonna. Le strade non sono decorative e seguono una logica: se sulla mappa esiste una città, almeno una strada vi conduce. Una strada non deve però necessariamente collegare due elementi visibili, poiché la mappa rappresenta una porzione di territorio: può proseguire fuori mappa senza che si sappia dove porti. Le strade che escono dalla mappa forniscono inoltre una via naturale di ingresso e di uscita per le forze avversarie.

5.6 Struttura del turno. Un turno di campagna corrisponde a una giornata. Ciascun gruppo dispone di un'azione al giorno, il che consente di muovere più gruppi contemporaneamente e in particolare di far lavorare gli esploratori mentre la colonna principale avanza più lentamente.

5.6.0 Il gruppo. Il gruppo è l'oggetto che dispone di un'azione al giorno. Non è un'etichetta organizzativa ma un oggetto dotato di una composizione, di un volume complessivo e quindi di una velocità propria, secondo il punto 5.6.3. Il numero dei gruppi è la grandezza che determina quanto pesi ogni giornata, in decisioni da prendere e in informazioni da ascoltare, e concorrono al totale anche le formazioni di ricognizione e quelle non armate.

5.6.0.1 Il modello è libero: il giocatore forma, divide e riunisce i propri gruppi quando vuole, e non esiste alcun tetto al numero di gruppi contemporaneamente attivi.

5.6.0.2 Divisione. Dividere costa l'azione della giornata. Nel momento in cui si divide, il giocatore sceglie che cosa staccare e colloca immediatamente il distaccamento in una delle caselle adiacenti: il distaccamento non nasce mai nella stessa casella del gruppo di origine, cosicché ogni casella contenga al massimo una formazione del giocatore e l'annuncio della casella resti di una frase sola. La divisione è l'azione del gruppo che si divide, e il distaccamento nasce avendo già agito, poiché il collocamento nella casella adiacente è a tutti gli effetti uno spostamento; diversamente staccare sarebbe un modo di guadagnare azioni. La divisione lavora su reparti interi e non sui singoli atomi, e nessuna delle due parti risultanti può restare vuota.

5.6.0.3 Riunione. Riunire due gruppi non costa l'azione, ma il gruppo risultante si considera avere già agito se almeno uno dei due vi confluiti aveva già agito. Senza questa regola un gruppo che ha già marciato potrebbe fondersi con uno fermo e rimettersi in marcia lo stesso giorno.

5.6.0.4 Denominazione. Ogni gruppo riceve alla nascita un nome proprio breve e stabile, che conserva per tutta la propria esistenza. Il gruppo che si divide conserva il proprio nome e il distaccamento ne riceve uno nuovo; il gruppo risultante da una riunione conserva il nome del maggiore dei due. Il nome lo assegna il gioco da una lista chiusa e prevedibile, non il giocatore: una schermata di immissione di testo dentro l'operazione più frequente della mappa sarebbe un'operazione lenta collocata sul percorso obbligato. I nomi sono unici almeno all'interno di ciascuna campagna. Un'eventuale ridenominazione facoltativa resta fuori dal percorso obbligato.

5.6.0.5 Perimetro della giornata. Ogni azione consuma l'intera giornata del gruppo che la compie, la marcia compresa. Un gruppo che costruisce non marcia, uno che marcia non costruisce, uno che si mette in imboscata non fa altro. È la regola che rende il turno annunciabile con una frase per gruppo.

5.6.0.6 Chiusura del turno. Il turno di campagna si chiude automaticamente quando tutti i gruppi hanno agito, e non esiste alcun comando di fine giornata. Stare fermi è a sua volta un'azione ordinabile e non un'omissione: si può ordinare a un gruppo di restare fermo per raccogliere risorse, per riordinarsi o per riposare. Un gruppo che non ha agito è quindi sempre un gruppo che attende una decisione.

5.6.1 Una giornata non è necessariamente una giornata di marcia. Marciare è una delle azioni possibili: se scelta, si indica la casella di destinazione; altrimenti il gruppo resta fermo o compie altro. La ragione è documentale, poiché circa metà delle giornate di una campagna storica non era di marcia, ed è vietato incorporare le soste nella velocità media, il che falserebbe insieme il ritmo e il raggio d'azione.

5.6.2 Ritmo che ne deriva, descritto a titolo illustrativo e senza valore normativo. Si marcia dal quartier generale finché le provviste reggono; ci si ferma per rifornirsi; si riparte; ci si arresta in una casella boscosa per costruire una macchina; si procede più lentamente portandosela dietro; si attacca. Il ritmo non va progettato: discende dalle regole già stabilite, cioè autonomia, valvola dell'accampamento, volume e costruzione in campagna.

5.6.3 Velocità della colonna. La velocità di spostamento non è una proprietà del reparto ma della colonna, e dipende dal volume complessivo di ciò che la compone, comprese le formazioni non armate e i carriaggi. Una colonna più voluminosa è più lunga, e una colonna più lunga percorre meno strada in una giornata.

5.6.3.1 Forma dello spostamento. Non esistono percorsi che attraversino più caselle in un turno. La casella resta l'unità dello spostamento: un gruppo entra in una casella adiacente impiegandovi uno o più giorni. La velocità si manifesta quindi come numero di giorni necessari a compiere lo scatto. La scelta è deliberata: un tragitto di più caselle obbligherebbe ad annunciare le caselle percorse e a interrompere la marcia a metà, mentre con la casella singola ogni fatto continua ad accadere dentro una casella e l'imboscata, l'aggiramento e il rifiuto della battaglia restano quelli stabiliti.

5.6.3.2 Il costo in giorni dipende dalla natura della casella di partenza e da quella della casella di arrivo, con pesi distinti e non necessariamente uguali fra le due, poiché il costo grava sul tragitto reale. Sulla medesima grandezza agiscono anche il volume della colonna, il tipo di strada e il costo fisso della strettoia, senza regole separate che si sommino in modo opaco.

5.6.3.3 Marcia lunga. Finché non ha completato i giorni necessari il gruppo resta nella casella di partenza: non esiste alcuno stato intermedio fra due caselle. Il gioco dichiara i giorni ancora mancanti. L'ordine di marcia si può revocare in qualunque momento, perdendo tutti i giorni già spesi.

5.6.3.4 Per chi vede, l'avanzamento è rappresentato collocando il segno del gruppo in una di nove posizioni disposte a quadrato dentro la casella, così che si veda l'esercito farsi strada verso il bordo della destinazione. Le nove posizioni sono la rappresentazione di uno stato che si misura in giorni e non una grandezza autonoma: la posizione si ricava dalla proporzione fra giorni compiuti e giorni totali, con il troncamento per difetto di cui al punto 13.5 della carta. Chi ascolta riceve la grandezza di origine, cioè i giorni.

5.6.3.5 Conseguenza. Un gruppo impegnato in una marcia di più giorni è di fatto immobile per tutta la durata di quella marcia e non può sfilarsi se non perdendo i giorni già spesi. Ciò dà forma concreta alla regola del punto 6.1.2 secondo cui chi è lento non può rifiutare la battaglia. Il gioco dichiara la conseguenza insieme al costo, prima della conferma, e non la lascia scoprire il giorno in cui qualcuno arriva. Essere raggiunti durante una marcia lunga non equivale però in alcun modo a subire un'imboscata: chi sopraggiunge non riceve alcun vantaggio di schieramento e la battaglia comincia come qualunque altra.

5.6.4 Marcia forzata. È possibile marciare a ritmo superiore al sostenibile, con un tetto di due o tre turni consecutivi e non oltre. Ciascun turno di marcia forzata accresce il logoramento in misura più che proporzionale, non lineare. Il tetto è decisione di progetto e non dato storico, poiché la durata massima sostenibile non è documentata per alcuna fase, e va annotato come tale nel documento 03.

5.6.4.1 Effetti. Se il gruppo avrebbe impiegato più di un turno per compiere lo scatto, la marcia forzata glielo fa compiere in quel turno. Se il gruppo avrebbe comunque impiegato un turno solo, esso raggiunge la casella di destinazione e da lì può compiere una seconda casella nello stesso turno, come premio per i rischi corsi.

5.6.4.2 Il secondo scatto non è automatico: il gruppo si ferma nella casella intermedia, si accerta che nulla di imprevisto vi sia accaduto, e il giocatore decide se impiegarlo o rinunciarvi con un'apposita azione esplicita. L'azione del gruppo non si considera chiusa finché lo scatto non è stato impiegato o non vi si è rinunciato: uno scatto disponibile non decade mai in silenzio. È l'unica azione del gioco che si compie in due momenti distinti dentro lo stesso turno, e ciò va dichiarato con chiarezza nell'annuncio.

5.6.4.3 Il secondo scatto appartiene alla medesima e unica attivazione e consuma una sola unità del tetto di cui al punto 5.6.4. Soltanto una nuova attivazione nel turno successivo conta come seconda attivazione consecutiva.

5.6.4.4 Riposo. Fra le azioni di sosta figura il riposo, che rimuove i malus derivanti dalla marcia forzata e non altri. È la contropartita del logoramento più che proporzionale e ne stabilisce il ritmo: due o tre giorni di corsa seguiti da una giornata di fermo. Il rapporto fra il riposo e la stanchezza ordinaria resta da stabilire insieme al punto 5.7.

5.6.4.5 Conseguenza registrata. La marcia forzata è anche il modo di cadere in un'imboscata più in fretta, poiché consente di entrare in una casella avendo percorso il doppio del previsto. Il vantaggio di chi tende l'imboscata è una quantità fissa che non dipende dalla velocità di chi arriva, ma va tarato sapendo che quella velocità può variare.

5.6.5 Autonomia. Una formazione trasporta un numero determinato di giorni di viveri. Raggiunto il limite, il giocatore dispone sempre della facoltà di fermarsi, accamparsi e raccogliere quanto serve nelle zone circostanti, in modo automatico: senza acquisti, senza accordi, senza esaurimento della casella e senza memoria sulla mappa. Il limite di autonomia non è quindi un muro: oltre il raggio non si muore, ci si ferma.

5.6.5.1 La sosta con raccolta automatica e la catena non sono due vie concorrenti ma un'unica cosa articolata: la catena è la via ordinaria secondo il punto 5.2.2, e la sosta con raccolta è ciò che si è costretti a fare quando la catena si interrompe, secondo il punto 5.2.2.4. Nessuna delle due risulta inutile e non occorre stabilire alcuna prevalenza ulteriore.

5.6.6 La questione di quale fra la catena e la sosta con raccolta automatica costituisca la via ordinaria è stata risolta ai punti 5.2.2 e 5.6.5.1: la catena è la norma, la sosta è la conseguenza della sua interruzione.

5.6.7 Gli animali seguono in automatico la stessa logica delle razioni umane. Non esiste distinzione fra la parte di razione che grava sempre e il foraggio che grava solo in assenza di pascolo, e il raggio d'azione non varia con la stagione.

5.6.8 La questione di che cosa si possa muovere e in quale misura in ciascun turno, e di come perimetrare la giornata rispetto alle azioni diverse dalla marcia, è stata risolta ai punti da 5.6.0 a 5.6.4.5. L'elenco completo delle azioni è chiuso al punto 5.6.8.1.

5.6.8.1 Chiuso nella fase di architettura: l'elenco delle azioni di giornata di un gruppo è chiuso e conta sedici voci. Per tutti i gruppi: marcia (5.6.1); marcia forzata, con l'eventuale secondo scatto e la rinuncia esplicita (5.6.4); sosta con raccolta automatica (5.6.5); riposo (5.6.4.4); riordino degli assetti, cioè la ripartizione degli atomi del gruppo negli assetti disponibili (4.8); manutenzione delle macchine (5.7.1); presidio, cioè restare fermi in guardia (5.6.0.6); divisione (5.6.0.2). Per i soli gruppi armati: imboscata (5.11); costruzione di opera da campo (5.14.1); costruzione di macchina in casella boscosa (5.12); distruzione di opera permanente nemica (5.14.7); sabotaggio (5.10.2); imposizione della battaglia nella casella condivisa (6.1.1). Per le sole formazioni di ricognizione: esplorazione (5.4); studio approfondito (5.10.2), e il sabotaggio alle condizioni del punto 5.10.2. Ogni azione consuma l'intera giornata secondo il punto 5.6.0.5. Non sono azioni, e non consumano la giornata: la riunione (5.6.0.3), la revoca di una marcia (5.6.3.3), l'accettazione di una battaglia imposta dall'avversario, l'apertura della battaglia in sospeso (6.2) e il dirottamento dei superstiti (6.9).

5.6.9 Campagne contemporanee. Le campagne aperte contemporaneamente sono in genere più d'una. Ciascun regno nemico ha un proprio fronte, e su ciascun fronte si possono combattere diverse località, anche più d'una nello stesso momento, ciascuna su una mappa propria; per ciascun fronte occorrono almeno cinque mappe diverse. In ciascun anno si può essere in guerra con un massimo di due regni nemici, quindi le campagne pendenti non superano le tre o quattro.

5.6.9.1 Ciascuna campagna ha il proprio calendario e avanza per conto proprio, ma le campagne pendenti non possono restare distanziate fra loro di più di due settimane. La campagna che raggiunge il vantaggio massimo si blocca: non vi si può più agire e tutto vi resta fermo finché le campagne rimaste indietro non sono state portate avanti a sufficienza. Il vincolo è anche il freno naturale che scoraggia il moltiplicare le località attive.

5.6.9.2 La chiusura automatica del turno di cui al punto 5.6.0.6 opera per campagna, e per campagna è anche il conteggio dei gruppi ancora da muovere.

5.6.9.3 Una campagna bloccata dichiara di esserlo appena vi si entra, indicando la ragione e quale campagna è rimasta indietro. Il gioco avvisa inoltre quando la distanza si avvicina al limite, così che il blocco non sopraggiunga di sorpresa a metà di una manovra.

5.6.10 Architettura dei luoghi. La navigazione è a tre livelli. La patria dispone di una propria sezione sempre disponibile ed è la schermata da cui si parte all'avvio; da lì si passa alla schermata delle campagne, articolata per fronti e, dentro ciascun fronte, per località attive; e solo allora si entra nella mappa di una campagna, con il proprio registro di cronaca, le caselle con le azioni possibili e i riferimenti temporali in alto, presenti anche in patria.

5.6.10.1 La schermata delle campagne è la sede dell'informazione di stato complessiva, poiché è l'unico punto in cui le campagne aperte si vedono tutte insieme: vi si dichiara quali hanno gruppi ancora da muovere, quale è bloccata e quale è rimasta indietro.

5.6.10.2 Riferimenti temporali. La mappa di una campagna mostra la data di quella campagna. La patria mostra la data più arretrata fra tutte le campagne aperte, poiché è quella che comanda, stabilendo di quanto si possano ancora spingere le altre prima che si blocchino. La schermata delle campagne mostra per ciascuna la propria data insieme allo scarto rispetto alle altre.

5.6.10.3 La patria non chiede mai di essere visitata per proseguire, ma è sempre raggiungibile. Che vi sia qualcosa da vedervi, cioè un lavoro completato, un arrivo o una decisione possibile, è segnalato nell'informazione di stato complessiva.

5.6.11 Ordine di risoluzione della giornata, chiuso nella fase di architettura. All'apertura della giornata il gioco estrae il meteo e aggiorna provviste, contatori e conoscenza. Il giocatore ordina quindi i propri gruppi in qualunque ordine; quando tutti hanno agito, agiscono i gruppi avversari, in un ordine interno fisso e deterministico. La giornata si chiude da sé secondo il punto 5.6.0.6, con le risoluzioni di fine giornata: avanzamento delle marce lunghe, scatto delle imboscate, valutazione dei tagli di rifornimento, completamenti di costruzione, invecchiamento e decadimento della conoscenza. Ciò che il giocatore apprende delle mosse avversarie passa esclusivamente dagli stati di conoscenza del punto 5.3 e dal registro del punto 5.17: l'ordine interno di risoluzione non gli comunica nulla che la ricognizione non gli abbia dato.

5.7 Stanchezza e manutenzione. Le formazioni umane e animali accumulano stanchezza; le macchine da guerra hanno uno stato di manutenzione che svolge la stessa funzione. Entrambi gli stati influenzano parzialmente l'efficacia in battaglia, con effetto su punti vita e capacità offensiva. Chiuso nella fase di architettura: la stanchezza ha due sole fonti, i malus della marcia forzata e quelli della mancanza di provviste. La marcia a ritmo sostenibile non logora: il ritmo sostenibile è tale per definizione, e una terza stanchezza ordinaria non esiste nella prima versione. Il riposo rimuove i malus della marcia forzata e null'altro (5.6.4.4); la sosta di rifornimento rimuove quelli della mancanza di provviste e null'altro (5.2.2.5). La sensibilità alla stanchezza propria di ciascun archetipo (3.4) è il coefficiente che modula quanto i malus del gruppo incidano su quel reparto. Gli effetti si applicano come moltiplicatori su punti vita e capacità offensiva all'apertura della battaglia; le entità risiedono nel documento 03 e si tarano con le simulazioni.

5.7.1 Manutenzione, chiusa nella fase di architettura. Ogni macchina ha uno di tre stati, espressi con i termini del vocabolario chiuso del documento 02: efficiente, con possibilità di guasto bassa; logora, con possibilità di guasto alta; guasta, cioè ferma e inutilizzabile finché riparata. Lo stato degrada con i giorni di movimento e con l'impiego in battaglia, secondo passi definiti nei dati. La prova di guasto è l'evento casuale del punto 12.2 e la sua probabilità dipende dallo stato. La riparazione avviene con l'azione di manutenzione del gruppo: da logora a efficiente ovunque; da guasta a efficiente soltanto presso il quartier generale o una fortezza propria. D'inverno, e nelle voci brevi fuori inverno del punto 5.5.1.4.1, le riparazioni riportano tutto a efficiente.

5.7.2 Il rapporto fra il riposo e la stanchezza ordinaria, lasciato aperto dalla direzione del primo nodo, è chiuso dal punto 5.7: non esistendo stanchezza ordinaria, il riposo non ha altro da rimuovere.

5.8 Lo stato di approvvigionamento influenza a sua volta l'efficacia in battaglia. Chiuso nella fase di architettura: agisce soltanto sui parametri delle unità, cioè punti vita e capacità offensiva, e mai sul budget di volume. Il budget rappresenta la capacità di manovra del comandante sul campo, non la freschezza delle truppe; farvi agire anche l'approvvigionamento conterebbe due volte la stessa privazione e renderebbe variabile la grandezza su cui si fondano tutti gli annunci di costo.

5.9 Stagioni. L'anno ha un ritmo fisso e prevedibile. D'inverno non si conduce campagna: le operazioni si fermano, si resta in patria e si dispone di più tempo e di un margine maggiore per costruzione, logistica, rifornimento, reclutamento, addestramento e miglioramento dei reparti. La pausa è obbligatoria e termina con l'inizio della primavera. La regola vale identicamente per gli avversari, che d'inverno svolgono le proprie attività.

5.9.1 L'inverno non è un intervallo fra due campagne ma una parte della partita in cui si vince o si perde: chi lo impiega meglio si presenta in primavera più avanti dell'altro. È inoltre la sede naturale della gestione del regno, che diventa così un modo di giocare distinto anziché un pannello da consultare mentre si pensa ad altro, ed è la stagione in cui si acquisiscono le capacità nuove di cui al punto 2.6.

5.9.1.1 Struttura dell'inverno. L'inverno si articola in quattro schermate consecutive, separate da apporti informativi intermedi e progressivi. La prima cade nei primi giorni ed è la sede delle decisioni iniziali e macroscopiche; la seconda dopo qualche settimana, ed è seguita da informazioni vaghe sugli avversari; la terza verso la metà, seguita da informazioni un poco più precise; la quarta riguarda le ultime settimane ed è seguita dalle informazioni più nitide. Dopo la quarta comincia la primavera, senza alcun riepilogo conclusivo.

5.9.1.2 Le quattro schermate non sono turni da giocare ma quattro momenti di decisione separati da notizie che arrivano. Il bilancio non si esaurisce necessariamente nella prima: le risorse restano disponibili per tutto l'inverno e il giocatore le distribuisce dove e quando vuole. Chi impegna tutto subito sceglie sapendo meno; chi tiene qualcosa da parte arriva all'ultima schermata sapendo di più ma con meno inverno davanti perché le cose lunghe maturino.

5.9.1.3 Struttura interna delle schermate. Ciascuna delle quattro contiene sempre tutto, senza eccezioni. Le voci sono ripartite in sottosezioni per linguette ordinate secondo la durata dei lavori: per prime le costruzioni permanenti lunghissime, poi quelle di durata intermedia, poi le più brevi. Nulla viene mai sottratto: se una cosa lunga viene avviata in una schermata avanzata, arriverà in estate, in autunno o nell'inverno successivo. La forma fissa è deliberata, poiché con voci che spariscono il giocatore dovrebbe imparare quattro schermate diverse anziché una sola ritrovata identica quattro volte.

5.9.1.4 L'ordinamento è per durata e non per tipo di cosa: il giocatore non cerca la costruzione perché è una costruzione, la cerca perché è lunga e va decisa adesso. Quando si ordina un lavoro il gioco dichiara quando sarà pronto e non quanto dura, poiché è quello il dato su cui si decide.

5.9.1.5 Annuncio del costo. Ogni voce dichiara non soltanto quanto costa ma anche la riserva complessiva di ciascuna risorsa impiegata, nella forma che dice quanto costa su quanto se ne possiede. Ciascuna voce dichiara soltanto le risorse che quel lavoro consuma effettivamente. L'esito non va annunciato quando è positivo: una voce acquistabile non dichiara di esserlo, mentre va annunciata prontamente l'impossibilità di acquistare con l'indicazione di quale risorsa manchi. Esiste inoltre un riquadro delle riserve, navigabile voce per voce, che raggruppa tutto ciò che si possiede in valore assoluto.

5.9.1.6 Apporto informativo. Le informazioni sugli avversari che si ricevono fra una schermata e l'altra riguardano strutture e costruzioni, e non riguardano in alcun caso l'addestramento e la ricerca. Unica eccezione è l'esercitazione avvistata, che può lasciare intravedere uno spiraglio circa una nuova macchina da guerra o un nuovo asset militare, senza dire quale. Il limite è fondato: costruzioni e fortificazioni sono cose fisiche che stanno in un luogo e richiedono uomini e materiali, mentre addestramento e ricerca avvengono dentro e non hanno segni esterni.

5.9.1.7 Esiste un fondo minimo di informazioni che arriva a chiunque, in forma vaga, per sentito dire e per voci corse. La penetrazione delle campagne, le conquiste, la ricognizione e il numero di torri di osservazione possedute su quel fronte rendono le informazioni progressivamente più precise e più attendibili, senza raggiungere mai la certezza piena. La taratura fine della progressione è delegata alla fase di realizzazione.

5.9.1.8 Simmetria. Gli avversari dispongono delle medesime cinque risorse e sono soggetti ai medesimi tetti d'epoca. La simmetria rende interpretabile ciò che fanno: sapendo che hanno le stesse risorse, la notizia che hanno costruito molto implica che abbiano speso meno altrove, e le informazioni invernali diventano indizi anziché notizie sciolte. Poiché i tetti valgono per tutti, nessuno può correre all'infinito in una sola direzione.

5.9.2 Chiuso nella fase di architettura. Nella prima versione le tre stagioni operative, cioè primavera, estate e autunno, differiscono soltanto per le probabilità degli eventi meteorologici, definite per stagione nei file di dati. Nessuna meccanica dedicata alle stagioni intermedie, come incendi estivi o nebbie autunnali, entra nella prima versione; la struttura dei dati ne prevede l'aggiunta futura senza modifiche al programma. La decisione attua il rinvio disposto dal titolare nella fase due senza lasciare la materia indefinita.

5.9.3 Le stagioni non sostituiscono il caso ma gli stanno accanto. Il meteo resta, insieme ai guasti, l'unico ambito in cui interviene il caso, secondo la sezione 12.

5.9.4 Geografia e meteo di campagna influenzano lo svolgimento delle battaglie soltanto attraverso la caratteristica unica del campo di cui al punto 7.4. Non esiste alcun altro canale di comunicazione fra i due piani.

5.10 Azioni contro formazioni non armate. Quando una formazione di ricognizione o un gruppo armato raggiunge la casella di una formazione non armata avversaria, non si apre alcuna battaglia. È possibile ordinare, a seconda della composizione della formazione che agisce, un sabotaggio oppure uno studio approfondito. Le regole sono chiuse al punto 5.10.2.

5.10.2 Chiuso nella fase di architettura. Il sabotaggio consuma l'azione della giornata e disperde la formazione non armata bersaglio, il cui carico è perduto. Compiuto da un gruppo armato riesce sempre; compiuto da esploratori riesce soltanto se la loro competenza raggiunge la soglia di protezione dichiarata della formazione bersaglio, altrimenti fallisce e gli esploratori si fanno notare, cioè la loro casella diventa avvistata per l'avversario. Lo studio approfondito è riservato alle formazioni di ricognizione, consuma l'azione e porta a confermato lo stato di conoscenza della formazione studiata: composizione, carico e direzione di marcia. Entrambe le risoluzioni sono deterministiche, poiché il caso resta confinato al perimetro della sezione 12; nessuna delle due apre mai una battaglia, secondo il punto 5.4.1.

5.10.1 Osservazione dei movimenti. Il compito degli esploratori non si limita alle formazioni non armate: essi osservano e studiano i movimenti dei gruppi armati, degli esploratori avversari e di ogni altra formazione. Se rilevano che una colonna avversaria si è mossa lungo una strada per due caselle consecutive, se ne deduce che stia seguendo quella strada fino alla destinazione o a una sua ramificazione.

5.11 Imboscata. L'imboscata è un'azione di posizione. Su qualunque casella della mappa il giocatore può collocare un proprio gruppo armato e assegnargli l'ordine di imboscata: il gruppo resta lì, narrativamente nascosto o comunque disposto. Se un gruppo armato avversario entra in quella casella, l'imboscata scatta.

5.11.1 L'imboscata non richiede alcuna menzogna del gioco. L'avversario non individua il gruppo appostato perché quella casella non è per lui confermata ai sensi del punto 5.3, il che è pienamente coerente con il vocabolario degli stati di conoscenza.

5.11.2 L'imboscata non è un tipo nuovo di battaglia. Chi la tende dispone del vantaggio già previsto dal punto 9.3.2, cioè di un numero maggiore di turni di gioco prima dell'arrivo avversario, unito a uno sconto sul costo di piazzamento durante quei turni. Chi la subisce non patisce alcuna penalizzazione: schiera normalmente e conserva la profondità piena.

5.11.3 L'imboscata ha un costo proprio: un gruppo appostato è fermo, consuma rifornimenti e non produce nulla, e se l'avversario cambia itinerario i turni impiegati sono perduti.

5.12 Costruzione in campagna. Alcune macchine da guerra, non tutte, possono essere costruite direttamente in campagna: un gruppo fermo in una casella qualificata come bosco o zona alberata può abbattere alberi e costruirla sul posto. Le restanti arrivano già pronte dalla patria al quartier generale secondo il punto 5.2.1.

5.13 Aggiramento. Due formazioni possono sfilarsi in caselle adiacenti senza ingaggiarsi. Una colonna avversaria può quindi oltrepassare l'esercito del giocatore e puntare su un obiettivo sguarnito. Questo comportamento è voluto ed è una possibilità tattica riconosciuta, non un difetto da correggere. Il punto era erroneamente numerato 5.11 nelle versioni precedenti, in duplicato con l'imboscata.

## 5 bis. Opere e postazioni sulla mappa di campagna

5.14 Le opere che si realizzano sulla mappa di campagna sono di due specie, distinte da chi le costruisce e da che cosa costano.

5.14.1 Opere da campo. Si costruiscono con l'azione di un gruppo che si ferma in una casella e vi lavora, e occupano una sola giornata, o al massimo due qualora conferiscano un vantaggio grande. Rinforzano o migliorano la postazione occupata: se il nemico sopraggiunge e ingaggia battaglia in quella casella, chi ha costruito il rinforzo e ancora lo occupa gode di vantaggi in combattimento.

5.14.1.1 Le opere da campo non passano mai in mano nemica: chi conquista la casella non eredita alcun vantaggio da ciò che vi trova. Senza chi le ha scavate e sa dove sono le cose, terra e legno non offrono alcun vantaggio a chi arriva.

5.14.1.2 Le opere da campo decadono con la campagna. Se in seguito si riapre un fronte di guerra sulla stessa mappa, non ci sono più. La regola chiude il problema dell'accumulo senza durate dichiarate né decadimento graduale, ed evita che la mappa risulti punteggiata di postazioni vecchie da annunciare a ogni passaggio.

5.14.2 Opere permanenti. Si ordinano d'inverno, appartengono alla prima linguetta del bilancio secondo il punto 5.9.1.3, e stanno su una casella di un territorio controllato. Quando una campagna si conclude con successo in un certo territorio, in quel territorio si possono ordinare nell'inverno successivo costruzioni di opere maggiori, che vi operano normalmente.

5.14.3 La fortezza. La fortezza costruita in territorio conquistato produce, nella campagna che si combatte su quella mappa, i seguenti effetti: vale come quartier generale, cosicché chi la possiede ne ha due; conferisce conoscenza piena del nemico secondo il punto 5.14.5; costituisce un centro da cui dispiegare truppe e in cui farle rientrare; consente di ospitare macchine da guerra già collocate verso il centro della mappa, senza doverle far percorrere l'intera mappa.

5.14.3.1 Al termine della costruzione la fortezza dispone di una guarnigione minima automatica, e il giocatore può assegnarle ulteriori truppe dalla patria. La guarnigione minima non basta da sola a respingere un assedio condotto seriamente: può resistere all'interno sospendendo l'assedio in attesa di rinforzi, subendo nel frattempo alcuni malus. Perché la fortezza tenga con sicurezza occorre lasciarvi truppe proprie, che smettono di essere disponibili altrove.

5.14.3.2 Poiché i quartieri generali diventano due, conquistare la fortezza non basta a concludere la campagna. La disciplina dei quartieri generali ordinari non è alterata: ciascuna parte ha il proprio in ultima riga, e la fortezza si aggiunge senza spostarlo.

5.14.3.3 L'asimmetria che ne deriva non va compensata. Chi ha costruito la fortezza ha diritto a un vantaggio sproporzionato, avendolo pagato con un inverno di lavoro; l'aggressore deve prendere due quartieri generali mentre ne rischia uno solo, e gli restano le altre due vie della resa e dell'annientamento. L'asimmetria non è peraltro una sorpresa, poiché le informazioni invernali riguardano strutture e costruzioni secondo il punto 5.9.1.6 e il nemico viene con ogni probabilità a saperlo durante l'inverno stesso.

5.14.3.4 Fortezza espugnata. Per tutta la durata della campagna in corso la fortezza espugnata resta neutralizzata: non può ospitare truppe né macchine e non conferisce più alcuna conoscenza. Chi l'ha perduta può riprendersela, ma essa resta neutralizzata fino al termine della campagna: la riconquista restituisce il presidio del luogo, non le funzioni dell'opera. Al termine della campagna appartiene a chi l'ha conquistata per ultimo, e dall'anno successivo torna pienamente operativa a suo favore.

5.14.3.5 Conseguenza da tenere presente in sede di taratura. All'aggressore basta espugnare la fortezza una volta per privarne il difensore per il resto della campagna, senza doverla tenere. Ne discende che il valore effettivo della fortezza in una campagna difensiva dipende quasi interamente da quanto la si presidia.

5.14.3.6 Chiuso nella fase di architettura: l'assedio della fortezza segue integralmente la sezione 8 bis, mura comprese. Resistere in attesa di rinforzi, secondo il punto 5.14.3.1, significa subire il blocco del punto 8b.5 senza sortire, con i malus della guarnigione minima; la fortezza resta zona di rifornimento per chi vi sta dentro secondo il punto 5.2.2.6. L'assalto resta sempre possibile per l'aggressore: la resistenza sospende l'assedio, non lo vieta.

5.14.4 Vie di accesso. L'affluenza più rapida dei gruppi armati alla fortezza non costituisce alcuna eccezione alle regole di marcia: si ottiene modificando la mappa di quel territorio, con l'introduzione di una via impressa nel terreno lungo il percorso che vi conduce, cioè una strada lastricata rapida dove già esisteva qualcosa, anche solo in alcune caselle, e almeno una strada battuta o sterrata dove non esisteva nulla. La strada agisce sulla stessa grandezza su cui agiscono il fondo stradale e il volume della colonna, cioè il numero di giorni di cui al punto 5.6.3.1.

5.14.4.1 Le modificazioni del territorio sono permanenti e non seguono la sorte del possesso: se la fortezza cambia padrone, dopo due anni esisterà una via rapida da entrambe le parti. Un giocatore che torni su una mappa già combattuta deve potersi accorgere che il terreno è cambiato senza doverlo dedurre misurando i giorni di marcia, e il tipo di strada fa quindi parte di ciò che la casella dichiara.

5.14.5 Portata della conoscenza conferita da fortezze e torri. La fortezza e la torre di osservazione conferiscono conoscenza piena del nemico nelle sei righe centrali della mappa e nelle due righe più prossime al proprio quartier generale, restando escluse le due righe più profonde del nemico, per le quali occorre comunque inviare esploratori. Il limite è ciò che impedisce all'opera di rendere inutile la ricognizione proprio nel settore da cui l'avversario schiera. Sui formati quattro per quattro e sei per sei la conoscenza è invece piena su tutta la mappa, in ragione delle dimensioni contenute e della posizione sopraelevata dell'opera; il formato otto per otto ricade nella disciplina del dieci per dieci.

5.14.5.1 Frequenza dei formati. Il quattro per quattro è molto raro, il sei per sei raro ma un poco meno, l'otto per otto è il più frequente fra i formati minori, e il dieci per dieci resta riservato alle campagne principali e più importanti.

5.14.5.2 Conseguenza da tenere presente in sede di taratura. Sui formati minori in cui il difensore possieda una fortezza o una torre, l'avversario non può tendergli imboscate né avvicinarsi senza essere visto. Sono le località più sbilanciate a favore di chi vi ha costruito, il che è temperato dalla rarità di quei formati e dalla possibilità di attaccare un'altra località dello stesso fronte.

5.14.6 Torri di osservazione. Accrescono il livello di informazione sul nemico durante l'inverno secondo il punto 5.9.1.7, e operano anche su mappe dove non esista alcuna fortezza, conferendovi la conoscenza di cui al punto 5.14.5. L'effetto informativo invernale è cumulativo per fronte: al crescere del numero di torri costruite su un fronte aumentano le informazioni disponibili su quel regno. Le torri restano utili anche sui fronti dove in quell'anno non si combatte. Sono l'unica voce del bilancio invernale che compra informazione anziché forza.

5.14.7 Le opere permanenti diverse dalla fortezza possono essere distrutte dal nemico, al costo di una giornata intera trascorsa in quella casella senza fare altro.

5.14.8 Altre opere permanenti. Il ponte, selezionabile soltanto su mappe che contengano un fiume o uno specchio d'acqua e soltanto sulle caselle interessate, annulla il costo di attraversamento dell'ostacolo. Il guado attrezzato è l'alternativa povera al ponte dove l'acqua è bassa, di costo minore e di effetto parziale. Il magazzino avanzato è un deposito che opera come zona di rifornimento secondo il punto 5.2.2.6. La palizzata di sbarramento, costruibile soltanto su una strettoia, ne accresce il costo di attraversamento per chi vi transiti contro la volontà di chi la possiede. Ogni opera è selezionabile soltanto dove il terreno presenti la condizione che la rende sensata.

5.15 Chiuso nella fase di architettura. Il magazzino avanzato segue la disciplina comune delle opere permanenti del punto 5.14.2: si ordina d'inverno su una casella di territorio conquistato, senza requisiti ulteriori di terreno; i costi risiedono nel documento 03. Che la torre di osservazione operi anche durante la campagna era già stabilito dal punto 5.14.6 ed è confermato. Le formazioni di ricognizione non sono soggette al taglio del rifornimento: vivono di autonomia e di raccolta automatica secondo il punto 5.6.5, poiché la regola del taglio è costruita sulle colonne e pochi uomini vivono del territorio; il costo della ricognizione resta il rischio, secondo il punto 5.4.

5.16 Orientamento del giocatore durante la giornata. Poiché il numero dei gruppi è libero secondo il punto 5.6.0.1, l'orientamento è affidato a tre strati che lavorano insieme senza duplicarsi. Il primo è l'informazione di stato, richiamabile in qualunque momento con un gesto fisso senza abbandonare la mappa, che dichiara la stagione, quanti gruppi hanno già agito sul totale, quanti sono impegnati in una marcia lunga, le battaglie in sospeso e dove si trovano, e l'eventuale presenza di gruppi con scatto di marcia forzata ancora disponibile. Il secondo è lo strumento di salto diretto al prossimo gruppo che non ha ancora agito, che non è una comodità accessoria ma la contropartita della struttura a un'azione per gruppo. Il terzo è la dichiarazione dello stato da parte del gruppo stesso, ogni volta che il giocatore lo incontra.

5.16.1 Gli stati di un gruppo sulla mappa di campagna appartengono al vocabolario chiuso di cui al punto 9.4 della carta e sono: gruppo che non ha ancora agito; gruppo che ha già agito; gruppo impegnato in una marcia lunga, con i giorni mancanti; gruppo appostato con ordine di imboscata, che va dichiarato perché non è deducibile dal fatto che sia fermo; gruppo che dispone ancora dello scatto di marcia forzata. A questi si aggiungono gli stati di rifornimento: gruppo senza provviste, con l'indicazione se si tratti del primo o del secondo turno consecutivo; gruppo in sosta di rifornimento, con i turni di sosta ancora dovuti; gruppo che si trova in una zona di rifornimento secondo il punto 5.2.2.6. Il gruppo rifornito, essendo la condizione ordinaria, non richiede menzione esplicita.

5.16.2 Un gruppo che ha compiuto una marcia forzata e dispone ancora dello scatto compare fra i gruppi da muovere pur avendo già marciato: il suo annuncio deve dirne la ragione e non limitarsi a segnalare che non ha ancora agito.

5.17 Registro degli eventi. Ogni campagna dispone di un proprio registro cronologico, e la patria del proprio. Vi si annota in ordine dal più recente al meno recente ciò che è avvenuto, comprese le azioni avversarie. Il registro non è una tabella né un blocco unico di testo: ogni voce è un elemento a sé che si annuncia in una frase compiuta, dichiara il giorno cui si riferisce, e consente di saltare al luogo del fatto. Senza il registro ogni annuncio che passa mentre il giocatore fa altro sarebbe perduto, mentre chi guarda ha il riquadro davanti e vi torna con lo sguardo.

5.17.1 Nel registro entrano soltanto i fatti che il giocatore non ha deciso: le mosse avversarie di cui abbia notizia, quanto riferiscono gli esploratori, l'arrivo di truppe e rifornimenti dalla patria, il completamento di una marcia lunga o di una costruzione, lo scatto di un'imboscata, l'interruzione del rifornimento, il cambio di stagione. Non vi entrano i propri ordini, che il giocatore ha appena impartito e già sentito confermare. Il completamento di un'opera in patria entra nel registro della patria e non in quello di una guerra.

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

8.1 Non esiste una fase di schieramento separata che si concluda dando inizio alla battaglia. Esiste un unico flusso di turni, dentro il quale si piazza e si manovra. Non esiste alcun limite di tempo: il vincolo è di quantità.

8.1.1 Il deck resta attingibile per tutta la durata della battaglia, secondo il punto 9.3.5, e far entrare un elemento nei turni avanzati costa quanto costerebbe muovere volume già in campo, poiché il costo passa dalla medesima grandezza.

8.1.2 L'unità appena piazzata ha con ciò consumato la propria azione di quel turno, come se si fosse mossa. Dal turno successivo agisce come qualunque altra: i reparti da tiro collocati subito cominciano quindi a tirare dal secondo turno.

8.1.3 Conseguenza. Non occorre stabilire come si alternino due schieramenti contrapposti, poiché non esistono due schieramenti ma soltanto l'ordine dei turni della battaglia. I turni in più di cui gode chi tende un'imboscata, secondo il punto 9.3.2, sono quindi turni di battaglia a tutti gli effetti, nei quali l'avversario non è ancora entrato in azione.

8.2 Il vincolo è duplice: una capacità di volume che si rigenera a ogni turno secondo il punto 9.3, e una profondità massima entro cui è consentito piazzare a partire dalle proprie retrovie.

8.2.1 La zona di piazzamento è costituita dall'ultima e dalla penultima riga dal proprio lato e, sulla griglia da dieci righe, anche dalla terza più arretrata. Poiché le righe sono numerate secondo il punto 7.3, essa corrisponde alle righe dieci, nove e otto per il giocatore e alle righe uno, due e tre per l'avversario. Sui formati minori la zona si riduce alle sole ultima e penultima riga.

8.2.2 Il costo del piazzamento cresce quanto più avanti si colloca l'elemento entro tali limiti, secondo la formula del punto 8.6.

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

8b.5 Blocco. Un esercito collocato davanti a una piazzaforte, finché resta in quella casella, impedisce alla posizione di ricevere risorse e le procura un lieve malus di efficacia. Trascorsi alcuni turni, si avvicina il momento in cui le forze assediate escono per tentare di rompere il blocco.

8b.5.1 Chiuso nella fase di architettura: la sortita è deterministica, come ogni scelta dell'avversario secondo il punto 12.1. Scatta al superamento di una soglia in turni che dipende dalla propensione dell'ufficiale assediato e dai malus accumulati; la soglia risiede nei dati. L'avvicinarsi della sortita è annunciato con i termini di imminenza del vocabolario chiuso, non con il linguaggio della probabilità, che il punto 12.3 riserva ai guasti.

8b.6 Il blocco non prende la piazzaforte: la costringe a uscire. Fornisce quindi al giocatore il modo di provocare lo scontro campale del punto 8b.4 anziché doverlo attendere. Non si introducono fame, esaurimento delle scorte o altri meccanismi di attesa.

8b.7 Costo dichiarato e accettato. La ricerca descrive l'assedio storico come processo logistico su scala di settimane o mesi, il cui esito si decideva su tempo, scorte e opere, e in cui l'assalto era semmai l'ultimo giorno. Il gioco vi rinuncia deliberatamente, e con esso al divario fra la presa con le macchine e la presa per fame.

## 9. Svolgimento della battaglia

9.1 Il combattimento è a turni e deterministico. Non intervengono dadi né esiti casuali nella risoluzione degli scontri.

9.2 L'ossatura del combattimento è stabilita ai punti da 9.5 a 9.9. Resta rinviato il calcolo puntuale del danno, cioè come capacità offensiva, numero di atomi presenti, archetipi coinvolti, adiacenza, gittata e stati di stanchezza, approvvigionamento e manutenzione concorrano a determinare le perdite. Nessun valore numerico di danno, punti vita, velocità o volume è stabilito in questo documento.

9.2.1 Resta però vincolante, e va imposto a monte, che la risoluzione sia deterministica secondo il punto 12.1, che impieghi una formula unica condivisa più coefficienti per archetipo secondo il punto 13.3 della carta, e che tutti i valori risiedano nei file di dati. La struttura è un requisito, i numeri sono materia di bilanciamento.

9.3 Budget di volume nel corso della battaglia. Il budget si rigenera a ogni turno. Il primo turno dispone di un budget maggiorato rispetto ai successivi, che riflette la disponibilità piena delle forze all'apertura dello scontro. A titolo puramente illustrativo, e senza alcun valore normativo, un rapporto del tipo centoventi al primo turno e cento nei turni successivi. I valori reali sono materia di bilanciamento e verranno stabiliti quando l'insieme delle unità sarà definito.

9.3.1 Il budget maggiorato del primo turno vale sempre e per entrambi i contendenti, senza eccezioni: riflette il fatto che all'apertura dello scontro le forze sono fresche e la discesa in campo è più agevole.

9.3.2 Vantaggio della sorpresa. Chi tende un'imboscata non riceve un budget maggiore: riceve un numero maggiore di turni consecutivi prima che le forze avversarie giungano sul campo, unito a uno sconto sul costo di piazzamento durante quei turni, dell'ordine del trenta per cento. Il vantaggio è quindi cumulativo nel tempo di gioco e non nel singolo turno, e resta una quantità e non una durata reale, in piena coerenza con il principio 4.

9.3.2.1 Chi subisce l'imboscata non patisce alcuna penalizzazione: schiera normalmente e conserva la profondità piena. La sequenza è la seguente: agisce per primo l'imboscante, con i propri turni consecutivi e con lo sconto; segue il turno di chi subisce, il quale non vede nulla dell'avversario; nel momento in cui comincia il turno successivo dell'imboscante tutto viene scoperto e si torna alla piena trasparenza del campo. L'opacità è quindi limitata a un turno soltanto.

9.3.2.2 Se chi subisce vedesse dove l'imboscante si è collocato, i turni in più si tramuterebbero in uno svantaggio, poiché servirebbero soltanto a scoprirne le posizioni in anticipo. La delimitazione a un turno solo è d'altra parte necessaria a chi ascolta, poiché un campo con informazione nascosta permanente sarebbe assai faticoso da seguire. La disparità non è fra i giocatori ma fra le due situazioni, ed è simmetrica: chiunque tenda un'imboscata ne gode, chiunque la subisca la patisce.

9.3.3 Conservazione del budget. Il volume non speso in un turno può essere conservato, ma entro il limite del dieci per cento del budget di quel turno, anche quando ne avanza di più. Accumulare per compiere in seguito una manovra più ampia è una scelta tattica legittima e voluta; il limite impedisce che l'inattività prolungata si trasformi in una manovra risolutiva.

9.3.4 Chiuso nella fase di architettura, adottando la soluzione già proposta perché è la più semplice da annunciare e da imparare: il tetto del dieci per cento si calcola sul budget di base del turno, e il volume riportato si somma al budget del turno successivo ma non genera a sua volta riporto. L'accumulo resta così limitato a un turno di profondità e la grandezza annunciata resta una sola.

9.3.5 Il deck resta utilizzabile per tutta la durata della battaglia. Forze non schierate all'apertura possono essere introdotte in campo in qualunque turno successivo, finché ve ne sono nel deck. Tenere riserve è quindi una scelta tattica vera.

9.3.6 Il costo di un piazzamento dal deck è sempre quello ordinario, calcolato secondo il punto 8.6 con il coefficiente di penalità di avanzamento applicato alla profondità della cella di destinazione. Non esiste alcuno sconto per i turni avanzati né alcuna maggiorazione. Le eccezioni a questa regola sono due e soltanto due: i rinforzi, di cui alla sezione 11, che pagano metà del costo ordinario ma non sono mai disponibili dall'inizio e intervengono solo in fase avanzata dello scontro; e lo sconto spettante a chi tende un'imboscata, di cui al punto 9.3.2, che si applica ai soli piazzamenti compiuti durante i suoi turni di vantaggio e non per l'intera durata della battaglia.

9.3.7 Il volume dell'avversario non si comunica, per decisione del titolare (versione 3.3). Il volume speso e residuo della parte avversaria non è informazione che il giocatore possa usare per decidere, e non compare in alcuna forma: né negli annunci, né a schermo, né in pannelli, riepiloghi, rotori o resoconti. Ciò non tocca la trasparenza del campo (7.7): le forze schierate restano tutte visibili e annunciabili.

9.4 L'informazione resta completa per tutta la durata dello scontro relativamente a ciò che è sceso in campo, secondo il punto 7.7.

9.4.1 Ordine dei turni, chiuso nella fase di architettura. Agisce per primo chi occupava per primo la casella in cui lo scontro avviene. La regola è unica per tutte le battaglie: nella battaglia da imboscata coincide con quanto già stabilito, poiché l'imboscante occupava la casella e in più dispone dei turni di vantaggio del punto 9.3.2; nella battaglia davanti a una piazzaforte il difensore la occupava e agisce per primo; nella battaglia imposta a un gruppo raggiunto, chi era fermo o in marcia nella casella agisce per primo. Chi arriva sceglie tempo e luogo dello scontro; chi attendeva riceve la prima mossa. Una regola sola, nessun caso speciale.

9.4.2 Chiuso nella fase di architettura, a conferma del punto 4.4: una cella ospita al più un solo sciame in ogni momento, le celle delle basi non sono occupabili, e non esiste alcun caso di più elementi combattenti nella medesima cella. La questione, lasciata aperta nei lavori precedenti, si estingue per costruzione.

9.4.3 Lettere dei reparti, per decisione del titolare (versione 3.3). Ogni reparto riceve una lettera nel momento in cui scende in campo, assegnata in ordine di piazzamento, rinforzi compresi. Serve a designarlo senza ambiguità nell'ascolto, e in particolare a scegliere quale reparto avversario battere con il tiro. La lettera identifica dentro il proprio schieramento: esistono una lettera A del giocatore e una lettera A avversaria, distinte dal fatto che l'annuncio dichiara già di chi è il reparto. Una lettera non si riusa quando il reparto che la portava esce dal campo, per nessuna ragione: chi ha imparato che B era un certo reparto deve poterne fidarsi fino alla fine dello scontro. La lettera appartiene al vocabolario chiuso, compare nell'annuncio del reparto in posizione fissa e compare anche a schermo, poiché ciò che si sente e ciò che si vede devono coincidere; forma e posizione dell'annuncio sono materia del documento 02.

9.5 Comando. Il giocatore comanda le proprie forze direttamente e in ogni turno, con una sola eccezione: i reparti corpo a corpo che ingaggiano lo scontro su suo ordine cessano di essere controllabili dal momento del contatto. Tornano controllabili quando il contatto finisce, cioè quando l'avversario è disfatto oppure quando il reparto si è disimpegnato secondo la propria tendenza al disingaggio di cui al punto 3.4.2. Chi combatte a distanza non è soggetto a tale vincolo e resta sempre controllabile, a meno che non venga assalito direttamente in corpo a corpo.

9.5.0 L'azione del reparto. Non esiste alcun attacco automatico, in nessun caso. Ogni reparto e ogni asset dispone di una azione per ciascun turno, che può consistere nel non fare nulla, nel muoversi, oppure nell'ingaggiare quando il bersaglio è a portata. La portata che rende disponibile l'ingaggio è diversa a seconda dell'archetipo: una è quella del corpo a corpo, altre sono quelle del tiro e dell'artiglieria. Poiché l'ingaggio si rende disponibile al ricorrere di una condizione, la sua disponibilità va dichiarata quando si incontra il reparto, insieme ai bersagli che consente di raggiungere.

9.5.0.1 L'ingaggio è gratuito e non consuma volume. Il volume paga soltanto il movimento e il piazzamento. La perdita di controllo è già di per sé la penalità dell'ingaggio, e sommarvi un costo continuo lo renderebbe una decisione quasi sempre sbagliata.

9.5.0.2 Volume e azione sono quindi due limiti distinti che agiscono su grandezze diverse: il numero di cose che si possono fare in un turno dipende dal numero di reparti in campo, poiché ciascuno ha una azione, mentre il volume determina quanto ingombro si può muovere e quanto avanti lo si può portare.

9.5.0.3 Lo spostamento è di una cella, oppure al massimo di due, e mai di più. Lo spostamento di due celle comporta il consueto costo aggiuntivo in volume.

9.5.1 Non esistono ufficiali dalla parte del giocatore: l'esecuzione degli ordini non fallisce e non è mediata. La regola del punto 9.5 riguarda la disponibilità del reparto, non l'affidabilità del comando.

9.5.2 La ragione documentale è che il problema del comando antico non era decidere ma farsi obbedire: un ordine impartito a truppe già in mischia non arrivava, e la riserva esisteva per conservare qualcuno cui poter ancora dare ordini.

9.5.3 Conseguenze volute. La riserva del punto 9.3.5 acquista il suo significato storico e mette in mano una decisione vera a ogni turno, cioè quanto impegnare e quanto tenere disponibile. In caso di ritirata, inoltre, i reparti a contatto non possono essere estratti: si salva chi era arretrato e si perde chi era impegnato, il che restituisce senza regole aggiuntive la differenza fra ripiegamento ordinato e ripiegamento impigliato.

9.6 Munizioni. Il tiro non è un automatismo. A ogni turno il giocatore decide se far tirare i reparti da lancio, la cui dotazione è limitata secondo il punto 3.4.3. La decisione è sostanziale perché le scariche non si reintegrano: spenderle subito o conservarle per una fase avanzata dello scontro è la scelta che conta, secondo la gittata unica del punto 3.4.1.

9.6.1 Le munizioni non si reintegrano durante la battaglia. Il reparto che le ha esaurite resta in campo e conserva la propria azione, ma può soltanto muoversi o ingaggiare in corpo a corpo. Le battaglie lunghe tendono quindi naturalmente a diventare battaglie di contatto, il che è coerente con il quadro storico. Il reintegro presso le proprie retrovie è stato valutato e rinviato: non fa parte della prima versione.

9.6.2 Il tiro non colpisce mai i propri, stabilito dal titolare in sede di revisione delle chiusure. I reparti da tiro colpiscono soltanto avversari e non esiste fuoco amico in alcuna forma. Battere un nemico impegnato in mischia con propri reparti è lecito e non comporta alcun rischio per i propri. Il principio è generale e vale in ogni punto in cui si producono perdite: nessuna regola del gioco può danneggiare le forze di chi la esegue per effetto di un'azione rivolta all'avversario. La regola è dichiarata perché nessuna revisione futura introduca il fuoco amico credendo di correggere una dimenticanza.

9.7 Risoluzione della mischia. La mischia è continua: a ogni turno i reparti a contatto si infliggono perdite reciproche, e il contatto prosegue finché uno dei due è distrutto oppure si disingaggia secondo il punto 9.8. Poiché i reparti impegnati sono fuori controllo, ciò avviene senza che il giocatore decida alcunché.

9.7.1 L'annuncio non è per singola mischia ma complessivo: all'inizio del turno il gioco riferisce in una sola comunicazione ordinata l'esito di tutti i contatti in corso, e il dettaglio di ciascuno resta consultabile atterrando sulla cella interessata. La mischia risolta in una volta sola al momento del contatto è stata valutata e scartata, poiché avrebbe ridotto la perdita di controllo a un turno e quindi a una formalità.

9.7.2 Esiti in fasce descrittive, per decisione del titolare (versione 3.3). L'annuncio dell'esito dei combattimenti — le mischie e il tiro — non riporta numeri di danno inflitto o subito, che sono anti-immersivi. Ogni esito si esprime con una scala graduata di fasce descrittive del vocabolario chiuso, che copre dallo stallo alle perdite lievi, significative e gravi, distinguendo fra perdite inflitte e subite. Le fasce discendono da soglie deterministiche calcolabili dal solo stato, che sono valori e risiedono nei file di dati (materia del documento 03). Resta invece disponibile, interrogando una cella, la consistenza attuale del reparto che la occupa: è un dato che serve a decidere se attaccarlo, ed è cosa diversa dal racconto dell'esito di uno scontro.

9.8 Disingaggio. Poiché il reparto ingaggiato è fuori controllo, il disingaggio non è una decisione del giocatore ma un evento che si verifica al superamento di una soglia di perdite, calcolata come proporzione della consistenza con cui il reparto è entrato in quel contatto e non come valore assoluto, così che la regola si comporti allo stesso modo con reparti grandi e piccoli.

9.8.1 La soglia è diversa a seconda del tipo di truppa: una fanteria pesante che regge quasi fino allo sterminio e una fanteria leggera che si sfila presto sono due strumenti diversi anche a parità di capacità offensiva. La soglia è quindi una caratteristica leggibile del reparto e va dichiarata fra le sue informazioni, altrimenti il giocatore la scoprirebbe soltanto perdendo.

9.8.2 Il reparto che si disingaggia si ritrae di una cella verso le proprie retrovie e torna sotto il controllo del giocatore dal turno successivo. Non vi è inseguimento per un turno soltanto; trascorso quel turno i due reparti possono ingaggiarsi nuovamente.

9.8.3 Se il nuovo contatto avviene fra due reparti che si erano già staccati in precedenza, non opera più alcuna soglia: il combattimento prosegue fino alla dispersione di uno dei due o di entrambi.

9.8.4 Conseguenze volute. Il disingaggio non è una via di fuga ma una finestra: il turno guadagnato serve soltanto se lo si impiega, arretrando il reparto, mandando altri a coprirlo o accettando che il secondo contatto sarà decisivo. Il reparto che si sfila libera inoltre l'avversario con cui era a contatto, il quale torna disponibile a ingaggiare altri: una linea che cede può quindi innescare una reazione a catena.

9.9 Offesa e protezione. Il danno si ricava da coefficienti abbinati fra il tipo di offesa del reparto — il suo proiettile fisso per il tiro, la sua arma per la mischia (3.3.1) — e il tipo di protezione del bersaglio, combinati da una formula unica, senza tabelle a doppia entrata, in applicazione del punto 13.3 della carta. L'offesa poco adatta al bersaglio non è inefficace: infligge una frazione ridotta del danno.

9.9.1 L'annuncio al giocatore è qualitativo e non numerico: dichiara se il reparto sia efficace o poco efficace contro il bersaglio designato. Il modello sottostante resta graduato. L'accoppiamento netto, con l'offesa inadatta resa del tutto inefficace, è stato valutato e scartato perché avrebbe reso possibile un esercito impossibile da ferire da lontano, rendendo irreversibili scelte di composizione compiute mesi prima sulla mappa di campagna.

9.9.2 Il medesimo meccanismo vale in mischia, dove il danno dipende dall'accoppiamento fra il tipo di arma impiegata e il tipo di protezione del bersaglio. Il tatticismo sul tipo di reparto e di arma da opporre a ciascun tipo di bersaglio è quindi il medesimo su tutto il campo, e il giocatore impara una regola sola anziché due.

## 10. Ritirata combattuta

10.1 In qualunque momento il giocatore può dichiarare la resa mediante un comando dedicato. La resa non conclude immediatamente lo scontro: apre una fase di ritirata combattuta.

10.2 La resa è disponibile solo dopo un numero minimo di turni trascorsi. Tale soglia si accorcia in funzione delle perdite subite, espresse come proporzione delle forze effettivamente impiegate sul campo e non come valore assoluto, così che la regola si comporti allo stesso modo su tutti i formati di scontro.

10.2.1 Base di calcolo, stabilita dal titolare in sede di revisione delle chiusure. Le forze effettivamente impiegate sono la somma delle forze con cui ciascun reparto è sceso in campo fino a quel momento; le riserve ancora nel deck non vi rientrano. Una battaglia perduta si riconosce e si chiude per quel che accade sul campo: un esercito che ha impegnato poco e perso quel poco può concludere presto, senza essere trattenuto dal peso di ciò che non ha mai schierato. Chi sceglie di impegnare altro, rinforzi compresi quando scendono in campo, accresce la base e con essa riallunga la soglia. La medesima base vale per la ritirata combattuta e per ogni altra soglia che dipenda dalle perdite subite in battaglia; resta distinta la soglia di disingaggio del punto 9.8, che per sua natura si calcola sulla consistenza con cui il singolo reparto è entrato nel contatto.

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

11.3 Chiuso nella fase di architettura, adottando la soluzione già proposta: i turni di percorrenza si contano dall'inizio della seconda battaglia. È la forma più semplice e più prevedibile, e l'unica in cui la stima annunciata al giocatore non dipende da un fatto già esaurito che egli non può più influenzare.

11.4 Al momento del dirottamento, effettuato dalla schermata di campagna, il giocatore riceve una stima del turno di arrivo con un margine di incertezza dichiarato, dell'ordine del venti per cento. La stima è annunciata come intervallo e mai come valore certo.

11.5 I rinforzi in arrivo non compaiono direttamente sul campo: entrano nel deck, con un annuncio di sintesi e un segnale sonoro dedicato. Il loro arrivo non sposta il fuoco, secondo il principio 11.

11.6 Ogni elemento giunto come rinforzo è annunciato come tale nel deck. Il suo primo dispiegamento ha costo dimezzato rispetto al normale, calcolato sul suo volume. Una volta in campo si comporta come qualunque altro sciame.

11.7 Il dimezzamento del costo è il primo caso concreto della regola di arrotondamento: la metà di un volume dispari produce un decimale, il troncamento per difetto lo abbassa, e su un elemento di volume basso potrebbe raggiungere lo zero. Si applica il minimo di uno del punto 13.6.

11.8 Chiuso nella fase di architettura: i rinforzi entrano nel deck secondo il punto 11.5 e da lì si piazzano nella propria zona di schieramento ordinaria del punto 8.2.1, soggetti ai normali vincoli di profondità. Nessuna zona d'ingresso speciale: il costo dimezzato del primo dispiegamento è l'intero vantaggio, e la regola dello schieramento resta una sola.

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

14.6 Gli avversari progrediscono. Le loro capacità crescono nel tempo e al passaggio di fase dispongono di quanto prima non avevano, secondo i punti 2.6.4 e 2.8. I loro valori si muovono dentro le rispettive forbici come effetto dei loro miglioramenti, secondo il punto 13.2.1 della carta. Sono soggetti ai medesimi tetti d'epoca del giocatore secondo il punto 5.9.1.8.

14.6.1 Il regno lontano. Esiste un regno lontano, già presente ed esistente nel mondo, di cui inizialmente si sa poco proprio in ragione della distanza. Man mano che il giocatore si espande sconfiggendo e conquistando i regni circostanti, quel regno si avvicina, diventa meglio conosciuto e se ne scopre la specializzazione militare, la quale si determina sull'ambito in cui il giocatore è più debole.

14.6.2 Il momento in cui la specializzazione si fissa non è un turno prestabilito ma dipende dalla distanza dal passaggio di fase: indicativamente dopo alcune acquisizioni finali raggiunte e quando altrettante ne mancano perché la fase scatti. Fissarla quando il profilo del giocatore è ormai formato ma restano acquisizioni da compiere significa che c'è ancora tempo perché egli colmi la lacuna da solo: la lezione resta possibile ma non è garantita, e deve poter accadere che arrivi tardi e serva a poco.

14.6.3 Una volta fissata, la specializzazione non si tocca più. Se si determinasse ogni volta sull'ambito più debole nell'istante della rivelazione, un giocatore attento se ne accorgerebbe dopo poche partite e capirebbe che il rivale gli è stato cucito addosso.

14.6.4 La regola non fa eccezione alla simmetria del punto 5.9.1.8: essa stabilisce in quale ambito quel regno sia forte, non che possa superare il tetto della propria epoca.

14.6.5 Conseguenza sulla ricognizione. Con la specializzazione ignota e la conoscenza che cresce con la vicinanza, la ricognizione acquista un oggetto di lungo periodo: non si esplora soltanto per sapere dove siano le truppe adesso, ma per sapere che tipo di guerra faccia un certo regno. Il dato si presta alla scala degli stati di conoscenza del punto 5.3, potendo essere presunto prima e confermato poi.

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

15.3 La battaglia si chiude con un resoconto: perdite subite, perdite inflitte all'avversario, e le altre informazioni utili a valutare l'esito. Il contenuto è chiuso al punto 15.3.1.

15.3.1 Chiuso nella fase di architettura. Il resoconto è un elenco di voci, ciascuna un elemento accessibile che si annuncia in una frase, in quest'ordine fisso: esito e modo di conclusione secondo il punto 15.2.3; durata in turni; perdite proprie, per archetipo, come atomi perduti su atomi schierati; perdite inflitte note, nella stessa forma; forze evacuate con la ritirata combattuta, se avvenuta; munizioni residue dei propri reparti da tiro; stato di stanchezza e manutenzione dei superstiti; conseguenze sulla campagna, cioè chi tiene la casella contesa e dove ricompaiono le forze secondo i punti 15.4, 15.5 e 15.6. I livelli di verbosità tagliano dalla coda, secondo la regola generale del documento 02.

15.4 Si torna quindi al piano di campagna, dove giocatore e avversario collocano le forze superstiti. Il vincitore sceglie per primo, lo sconfitto in seguito.

15.5 Il vincitore, e soltanto il vincitore, può scegliere di restare nella casella contesa. Chi si è ritirato arretra in una casella più indietro, secondo il punto 10.6.

15.6 Le forze evacuate con la ritirata combattuta ricadono sotto la limitazione del punto 10.6 e si collocano in una casella arretrata rispetto alla direzione di provenienza.

15.7 Il totale di atomi per archetipo si aggiorna con le perdite. La ridistribuzione negli assetti avviene secondo la sezione 4, e in assenza di scelta esplicita gli atomi si raggruppano nell'assetto più piccolo disponibile.

15.8 Se non vi sono altre battaglie in sospeso, i turni di campagna riprendono il loro corso normale.

---

## 16. Riepilogo dei punti aperti

16.1 Rinviato per scelta, non per omissione. Il calcolo puntuale del danno e tutti i valori numerici a esso collegati, punto 9.2. L'ossatura del combattimento è invece stabilita ai punti da 9.5 a 9.9 e non va riaperta. Chi riceve questo documento non deve colmare la lacuna di propria iniziativa.

16.2 Punti già contrassegnati come da confermare, tutti chiusi nella fase di architettura per delega del titolare. Sequenza di acquisizioni e ambiti della soglia distribuita: chiuso ai punti 2.8.2, 2.8.2.1 e 2.8.2.2. Elenco definitivo degli archetipi: chiuso al punto 3.2.3. Installazioni e voci fuori inverno: chiuso ai punti 5.5.2 e 5.5.1.4.1. Azioni di campagna: chiuso al punto 5.6.8.1. Stanchezza, manutenzione e rapporto con il riposo: chiuso ai punti 5.7, 5.7.1 e 5.7.2. Effetto dell'approvvigionamento: chiuso al punto 5.8. Stagioni intermedie: chiuso al punto 5.9.2. Sabotaggio e studio approfondito: chiuso al punto 5.10.2. Magazzino, torri e ricognizione rispetto al taglio: chiuso al punto 5.15. Base del riporto di volume: chiuso al punto 9.3.4. Ordine dei turni: chiuso al punto 9.4.1. Più elementi nella stessa cella: chiuso al punto 9.4.2. Ritiro di un reparto in mischia durante la ritirata combattuta: escluso, come già stabilito dal punto 10.4.1, che resta la regola. Conteggio dei turni dei rinforzi: chiuso al punto 11.3. Vincoli di ingresso dei rinforzi: chiuso al punto 11.8. Resoconto di fine battaglia: chiuso al punto 15.3.1. Assedio della fortezza: chiuso al punto 5.14.3.6. Le motivazioni e le alternative scartate sono nel registro delle decisioni architetturali.

16.3 Da stabilire in sede di definizione dei valori. Le differenze di partenza fra un regno e l'altro, che vanno fissate una volta sola e non riestratte a ogni partita, punto 13.2.3 della carta. Il tetto alla marcia forzata e il costo dell'addestramento, che sono decisioni di progetto e non dati storici e vanno annotati come tali. Il costo in giorni dello scatto per tipo di terreno e di strada, con i pesi rispettivi della casella di partenza e di arrivo, punto 5.6.3.2. I coefficienti di munizioni, armi e protezioni e la frazione di danno della munizione poco adatta, punti 9.9 e 9.9.2. Le soglie di disingaggio per tipo di truppa, punto 9.8.1. Il costo aggiuntivo dello spostamento di due celle, punto 9.5.0.3. La misura dello sconto di piazzamento dell'imboscante e il numero dei suoi turni di vantaggio, punto 9.3.2.

16.4 Da tarare con le simulazioni prima della pubblicazione. Il margine di convenienza della ritirata combattuta, punto 10.9. Il rapporto tra volume disponibile e profondità concessa, che determina quanto pesi il vantaggio della sorpresa. La soglia minima di turni prima della resa, che determina la durata di una battaglia perduta, punto 10.10. Il carattere degli ufficiali avversari, che determina la frequenza effettiva degli scontri, punto 6.1.3. Il costo di mantenimento dei miglioramenti, unico freno automatico all'accumulo di forze, punto 4.14.1. L'ampiezza della fascia entro cui il tiro uccide, punto 3.4.1. La precisione dell'apporto informativo invernale in funzione di ricognizione, penetrazione e torri, punto 5.9.1.7. Il peso della fortezza in una campagna difensiva, punto 5.14.3.5, e lo sbilanciamento dei formati minori, punto 5.14.5.2.

16.5 Impianti storicamente contestati e mantenuti per scelta, da non riaprire. Il modello di combattimento a consumo progressivo, punto 4.3.1. L'esclusione dei prigionieri, punto 15.2.1. La ritirata che costa la battaglia e non l'esercito, punto 10.11. Il campo di battaglia trasparente, punto 7.7.2. Il perimetro solo militare, punto 1.3.1. Il perimetro del caso, punto 12.5. L'equivalenza fra battaglia in marcia e battaglia schierata, punto 16.6. L'assedio combattuto anziché atteso, punto 8b.7.

16.6 Una battaglia è tale comunque sia cominciata: non esiste differenza fra l'essere colti in marcia e l'essere schierati. Costo dichiarato e accettato: la ricerca documenta che una fanteria pesante sorpresa in colonna perdeva dal doppio al quadruplo rispetto a una battaglia campale. La decisione è coerente con i punti 4.3.1 e 7.7. L'imboscata del punto 5.11 non ne risente, poiché il vantaggio di chi la tende è quello dello schieramento anticipato.
