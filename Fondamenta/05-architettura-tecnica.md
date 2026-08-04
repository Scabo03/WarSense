# Documento di architettura tecnica

Documento 05 di 05 — versione 1.3

Novità della versione 1.3, in conseguenza della risoluzione immediata dei contatti (01 §9.7.1): l'ordine di risoluzione del turno di battaglia è riscritto al punto 3.9. La simultaneità resta dentro ciascuna risoluzione e cade fra risoluzioni diverse dello stesso turno.

Novità della versione 1.2, alla realizzazione della fase C: il programma di verifica è una LIBRERIA più un guscio da riga di comando, perché il fumo delle simulazioni sia collaudabile come qualunque altro bersaglio (12.1, RDA-58); la variazione delle corse viene dagli assi dichiarati negli scenari e non dai semi, perché la battaglia non contiene alcuna estrazione del caso (12.3); gli scenari sono file dichiarativi con assi di un insieme chiuso (12.2).

Novità della versione 1.1, in conseguenza del limite dei bersagli simultanei di 01 §9.11: la codifica canonica dell'impronta serializza i contatti nell'ordine di arrivo e non riordinati, poiché quell'ordine è divenuto stato di gioco (2.9, RDA-55); il criterio di incremento della versione dei valori è dichiarato al punto 7.2 e sviluppato in 03 §9.2.1.

## 0. Come leggere questo documento

0.1 Questo documento descrive come il gioco è fatto dentro: moduli, stato, comandi, persistenza, presentazione, accessibilità realizzativa, dati esterni, programma di verifica, collaudo e ordine di costruzione. Non contiene codice, salvo brevi frammenti illustrativi dove servono a rendere inequivocabile una scelta di struttura. Non contiene regole di gioco nuove: dove una regola era lasciata aperta dai consolidati, la chiusura è registrata nel documento consolidato competente e nel registro delle decisioni architetturali, e qui se ne descrive soltanto la realizzazione.

0.2 Convenzioni di rinvio. I rinvii alla carta dei principi usano la forma 00 §P.n (esempio: 00 §11.3 è il punto 3 del principio 11). I rinvii agli altri consolidati usano la forma 01 §n, 02 §n, 03 §n. I rinvii interni usano la forma A §n. Il registro delle decisioni architetturali è citato come RDA-nn.

0.3 Gerarchia delle fonti. La carta dei principi prevale su questo documento; al suo interno prevale il numero più basso. In caso di conflitto fra questo documento e un consolidato, prevale il consolidato per le regole di gioco e di presentazione, prevale questo documento per la realizzazione tecnica.

0.4 Nessun valore numerico di gioco è stabilito qui. Dove compare una grandezza, la sua definizione e i suoi vincoli stanno nel documento 03 e il valore è materia di taratura. Gli unici numeri di questo documento sono numeri di struttura (numero di moduli, di file, di livelli), non di bilanciamento.

---

## 1. Quadro d'insieme

1.1 Piattaforma e strumenti. Applicazione universale per iOS e iPadOS, scritta in Swift puro con gli strumenti nativi di Apple (00 §2.1). Nessun motore di gioco, nessun ambiente multipiattaforma, nessuna libreria che disegni l'interfaccia. Requisito minimo di sistema: iOS 17, per disporre delle interfacce di annuncio con priorità e delle API aptiche mature; la scelta è rivedibile verso l'alto, mai verso il basso oltre la disponibilità delle API di accessibilità richieste. Distribuzione di sviluppo tramite TestFlight (00 contesto).

1.2 Organizzazione in pacchetto. Il progetto è un pacchetto SwiftPM con più bersagli, più il progetto applicativo Xcode che li assembla. I bersagli sono:

- **Dati** (libreria). Caricamento, validazione e interrogazione dei file dei valori e dei testi: schemi, versioni, forbici, coefficienti, mappe, vocabolario chiuso. Definisce i tipi dei valori e l'insieme chiuso dei ganci di effetto (A §7.7). Dipende soltanto da Foundation.
- **Motore** (libreria). Lo stato completo della partita, i comandi discreti, le regole, l'avversario, il calendario, il generatore del caso, la fabbrica del mondo iniziale (A §2.10). Dipende da Foundation e da Dati, da cui riceve i valori in forma già validata e tipizzata. Non importa UIKit, SwiftUI, CoreHaptics, AVFoundation, né alcun modulo di presentazione o di persistenza. È la logica di gioco di 00 §3.
- **Sessione** (libreria). L'orchestratore: possiede lo stato corrente, il giornale e le istantanee, consuma le sorgenti di comandi, fa agire l'avversario, consegna gli eventi (A §1.7). Dipende da Motore e Dati; non importa UIKit né Segnali.
- **Contenuti** (risorse). I file veri: valori, testi, mappe, pattern aptici, suoni, temi musicali. Nessun codice, solo risorse versionate (A §7, A §8).
- **Segnali** (libreria). Il punto centrale unico che riceve gli eventi di gioco in forma astratta e decide quali canali attivare: aptica, suono, annuncio (00 §5.3). Dipende da CoreHaptics, AVFoundation, UIKit (per gli annunci di accessibilità), da Dati (per i pattern e i testi) e da Motore per il solo tipo degli eventi.
- **Presentazione** (applicazione). Le schermate, gli elementi accessibili, i rotori, la gestione del fuoco. Dipende da Sessione, Motore, Dati, Segnali. Non contiene regole (00 §3.2).
- **Verifica** (eseguibile da riga di comando, macOS). Il programma di verifica del bilanciamento, separato dal gioco e senza interfaccia (00 §16.1). Dipende da Sessione, Motore e Dati; non dipende da Segnali né da Presentazione.

1.3 Regole di dipendenza, vincolanti e verificate dal collaudo (A §14.5): Dati importa soltanto Foundation; Motore importa soltanto Foundation e Dati; Sessione importa soltanto Motore, Dati e Foundation; Segnali non importa Sessione né Presentazione; Presentazione non importa Verifica; Verifica non importa Segnali né Presentazione. Nessun bersaglio fuori da Segnali e Presentazione importa un framework di interfaccia o di piattaforma. La violazione di una di queste regole è un difetto bloccante, perché da esse dipendono il salvataggio a ogni azione, la partita fra dispositivi, la rigiocatura e il programma di verifica (00 §3.4). Motivazione e alternative: RDA-01.

1.4 Flusso fondamentale. Ogni cosa che accade nel gioco segue un unico ciclo:

1. La Presentazione (o l'avversario, o il programma di verifica, o in futuro un dispositivo vicino) produce un **Comando**.
2. Il Motore lo **valida** contro lo stato corrente; l'esito è positivo con i costi dichiarati, oppure negativo con un motivo del vocabolario chiuso (A §3.2).
3. Se valido, il Motore lo **applica**: lo stato cambia in modo deterministico e viene restituito un elenco di **Eventi** astratti.
4. La persistenza **appende il comando al giornale** prima che gli effetti diventino visibili: questo è il salvataggio a ogni azione (00 §3.5, A §6.1).
5. La Presentazione aggiorna gli elementi accessibili sul posto, senza spostare il fuoco (00 §11.1), e inoltra gli eventi a **Segnali**, che decide i canali.

1.5 Nessun altro canale esiste. L'interfaccia non modifica mai lo stato direttamente, non calcola mai un costo, non decide mai una validità: chiede al Motore e presenta la risposta (00 §3.2). Il criterio pratico di revisione è al punto A §9.5.

1.6 Tempo reale. In nessun punto del programma esiste un temporizzatore che influisca sul gioco: nessun conto alla rovescia, nessuna scadenza, nessuna animazione bloccante (00 §4). Le animazioni sono decorative, interrompibili e prive di conseguenze sullo stato.

1.7 La Sessione. Un attore Swift, uno per slot di partita aperto, che è l'unico proprietario dello `StatoPartita` corrente e l'unico scrittore del giornale. La Sessione: riceve i comandi dalle sorgenti (`SorgenteComandi`, A §13.1) — la Presentazione per il giocatore, lo stratega, il tattico e il governo del Motore per l'avversario —; per ciascun comando esegue `valida`, appende la riga al giornale e ne attende la conferma di scrittura, poi esegue `applica` e consegna alla Presentazione il nuovo stato e gli eventi; se la scrittura fallisce, il comando non viene applicato e l'errore è dichiarato con un annuncio. L'elaborazione è seriale: un comando alla volta, nell'ordine di arrivo. È la Sessione a far agire l'avversario: dopo che tutti i gruppi del giocatore hanno agito interroga lo stratega finché la giornata non si chiude (A §3.8); nel turno avversario di battaglia interroga il tattico; al comando di avanzamento di stazione invernale interroga il governo (A §3.5). Le operazioni di annullamento e azzeramento (A §6.4), la ripresa (A §6.3) e la creazione della partita (A §2.10) appartengono alla Sessione. La Sessione distingue l'applicazione viva dalla riapplicazione: durante ripresa, annullamento e rigiocatura gli eventi prodotti da `applica` non raggiungono Segnali (A §6.3).

1.8 La Presentazione parla soltanto con la Sessione per mutare lo stato e con le interrogazioni del Motore, attraverso la Sessione, per leggerlo (A §9.4). Nessun altro oggetto detiene o duplica lo stato di gioco.

---

## 2. Il Motore: lo stato completo

2.1 Principi costruttivi. Lo stato è un valore (struct Swift), interamente `Codable`, privo di riferimenti a schermate, gesti, suoni o annunci (00 §3.2). Applicare lo stesso comando allo stesso stato produce sempre lo stesso stato e gli stessi eventi (00 §3.1). Tutto ciò che serve a riprendere la partita da qualunque interruzione sta nello stato: non esistono variabili di gioco fuori da esso (01 §6.6).

2.2 Tipi di base e aritmetica. Un unico tipo `Quantita` (intero) rappresenta ogni valore mostrato al giocatore o registrato nello stato. Un'unica funzione centrale realizza la regola di arrotondamento: troncamento per difetto, con minimo dichiarato per le grandezze in cui il troncamento potrebbe produrre zero (00 §13.5, 00 §13.6, 03 §8). Nessun altro punto del programma esegue arrotondamenti. Il collaudo verifica per proprietà che nessun percorso produca zero dove è dichiarato un minimo (A §14.2).

2.2.1 Virgola fissa. Nel Motore la virgola mobile è vietata, nello stato e nelle formule: i coefficienti decimali dei file (00 §13.4) vengono convertiti al caricamento in interi scalati su un fattore fisso dichiarato, e tutte le formule operano su interi. La ragione è il determinismo fra piattaforme: il Motore gira su iOS, su macOS nella Verifica e in futuro su due apparecchi in parallelo, e una divergenza di virgola mobile romperebbe impronte, riproduzioni d'oro e partita fra dispositivi (A §4.5). Il collaudo include una riproduzione d'oro incrociata fra iOS e macOS (A §14.6). Motivazione: RDA-44.

2.2.2 Il giorno è il turno. La giornata di campagna è il nome, interno alla finzione, del turno di campagna (01 §5.6): ogni grandezza espressa in giorni è espressa in turni, e nessuna grandezza del gioco è espressa in tempo reale, in conformità a 00 §12.4 e 00 §4.

2.3 Articolazione dello stato. `StatoPartita` contiene:

- **Intestazione**: versione dello schema di stato, versione dei file dei valori e dei testi con cui la partita è nata (00 §15.1, A §6.6), identificatore della partita.
- **Caso**: seme del generatore e contatore delle estrazioni (A §4.1).
- **Regno** (A §2.4).
- **Mondo** (A §2.5).
- **Campagne**: da zero a quattro campagne attive (01 §5.6.9), ciascuna con il proprio calendario, la propria mappa, i propri gruppi e il proprio registro (A §2.6).
- **Battaglia**: al più una battaglia in corso (A §2.7); le altre restano in sospeso come voci della campagna.
- **Inverno**: quando attivo, la stazione corrente fra le quattro e le decisioni già prese (01 §5.9.1.1).

2.4 Il regno. Contiene: le cinque risorse con i rispettivi saldi (01 §5.5.1); i totali di atomi per archetipo non assegnati a campagne, con i resti (01 §4.9, §4.10); gli assetti sbloccati (01 §4.7); le acquisizioni possedute e lo stato dei tetti d'epoca per ambito (01 §2.6.2.1); i miglioramenti attivi dei reparti con il loro stato di mantenimento (01 §4.13, §4.14); le opere ordinate e in corso con la data di completamento (01 §5.9.1.4); la fase storica corrente e il materiale monetario (01 §5.5.1.3).

2.5 Il mondo. Contiene: i regni avversari, ciascuno con le medesime cinque risorse, acquisizioni e tetti d'epoca (01 §5.9.1.8), il proprio elenco di ufficiali con i parametri di carattere (01 §14.3), le proprie opere; il regno lontano con lo stato della specializzazione, non ancora fissata oppure fissata e immutabile (01 §14.6.1–14.6.3); i fronti, ciascuno con almeno cinque mappe (01 §5.6.9), lo stato di possesso dei territori e le opere permanenti che vi insistono; le modificazioni permanenti del terreno, come le vie impresse (01 §5.14.4.1).

2.6 La campagna. Contiene: la data propria (01 §5.6.9.1); la mappa, come riferimento alla definizione nei Contenuti più lo stato mutevole delle caselle (opere da campo presenti, opere permanenti e loro stato, possesso); per ciascuna casella e per ciascun contendente lo **stato di conoscenza** con l'età dell'informazione (01 §5.3, A §2.6.1); i **gruppi** di entrambe le parti (A §2.6.2); le battaglie in sospeso con la casella e le forze coinvolte (01 §6.3); lo stato di blocco per scarto massimo (01 §5.6.9.1); il registro degli eventi della campagna (01 §5.17). La patria ha un proprio registro con la stessa forma (01 §5.17).

2.6.1 La conoscenza. Per ogni casella e per ogni parte: inesplorato, presunto, avvistato con il numero di turni trascorsi, confermato (01 §5.3). Lo stato confermato decade in avvistato dopo un numero di turni definito nei dati (03 §4.8.1); l'età dell'avvistamento cresce a ogni chiusura di giornata. Le sorgenti di conoscenza sono: la presenza propria (la casella occupata e quelle entro il raggio di osservazione del gruppo), l'azione di esplorazione degli esploratori, la copertura di fortezze e torri con i limiti di riga e di formato (01 §5.14.5). Il sottosistema non dichiara mai il falso (02 §4.4.3): un gruppo in imboscata è semplicemente non confermato per l'altra parte.

2.6.2 Il gruppo. Oggetto con identità e nome proprio stabile assegnato dal gioco (01 §5.6.0.4): composizione in sciami e in elementi non combattenti, volume complessivo derivato, provviste residue in giorni (01 §5.6.5), contatori di marcia forzata e di mancanza di provviste con la sosta dovuta (01 §5.6.4, §5.2.2.4–5.2.2.5), stato di manutenzione per ciascuna macchina (01 §5.7), azione della giornata spesa o no, marcia lunga in corso con i giorni compiuti e totali (01 §5.6.3.3), scatto di marcia forzata disponibile (01 §5.6.4.2), ordine di imboscata (01 §5.11), categoria (gruppo armato, formazione di ricognizione con la competenza degli esploratori, formazione non armata: 01 §5.2, §5.4.2). La condizione della linea di rifornimento non è memorizzata ma **derivata** a ogni valutazione dalle posizioni reali delle forze nemiche e delle strutture (01 §5.2.2.2, §5.2.2.6): essendo una condizione dello spazio, non può andare fuori sincronia. La valutazione usa le posizioni reali e non la vista filtrata dalla conoscenza, perché così la regola è scritta in 01 §5.2.2.2; l'annuncio dell'interruzione dichiara il solo fatto, senza indicare la casella del nemico, come stabilito nella direzione del quarto nodo: è un indizio vero e non una rivelazione. Gli stati che il gruppo dichiara sono quelli del vocabolario chiuso di 02 §4.4.5: senza provviste con il giorno, in sosta di rifornimento con i giorni dovuti, in zona di rifornimento.

2.7 La battaglia. Contiene: il formato e la mappa di provenienza; la caratteristica unica del campo (01 §7.4); gli ostacoli (01 §7.5); la griglia con al più uno sciame per cella (01 §4.4) e le due basi in posizione fissa (01 §7.3.1); i due deck con gli elementi disponibili e l'indicazione di rinforzo (01 §9.3.5, §11.5); per ciascuna parte il budget di volume del turno, il riporto (01 §9.3.3) e il numero del turno; i turni di vantaggio residui dell'imboscante e lo stato di opacità (01 §9.3.2.1); i contatti in corso, ciascuno con la consistenza d'ingresso dei due reparti (01 §9.8) e la memoria dei disingaggi già avvenuti fra le stesse coppie (01 §9.8.3); lo stato di ritirata combattuta con la riga di soglia (01 §10.3); l'elemento eventualmente selezionato nel deck e la designazione di bersaglio in corso (01 §6.6: anche lo stato dell'interazione si salva). Il marcatore di inizio turno per l'azzeramento non vive nello stato ma nel giornale (A §6.4, A §6.5).

2.8 Identità. Ogni oggetto con vita propria (gruppo, sciame, ufficiale, opera, campagna, voce di registro) ha un identificatore stabile assegnato dal Motore in modo deterministico (contatore nello stato, mai valori casuali né orologio). Gli identificatori compaiono nei comandi e nel giornale; i nomi leggibili stanno nei testi.

2.9 Impronta di stato. Il Motore calcola un'impronta dello stato con una codifica canonica dedicata, non con la codifica JSON generica: campi serializzati nell'ordine dichiarato dal tipo, interi a lunghezza fissa, opzionali con marcatore esplicito, insiemi ordinati per identificatore; sull'esito si calcola SHA-256. Gli ELENCHI il cui ordine è esso stesso un fatto di gioco si serializzano invece nel proprio ordine e non si riordinano: è il caso dei contatti di battaglia dalla versione 1.1, poiché l'ordine di arrivo decide chi riceve risposta piena, ridotta o nessuna (01 §9.11.1). Il criterio generale è che l'impronta deve distinguere due stati che si comportano in modo diverso; riordinare per canonicità un elenco significante li renderebbe indistinguibili, che è il difetto opposto a quello contro cui la canonicità esiste (RDA-55). La funzione è parte del Motore e ha collaudo proprio; le impronte si confrontano soltanto a parità di versione dello schema. Serve al collaudo (riproduzioni d'oro, A §14.6), alla futura partita fra dispositivi per rilevare le divergenze (A §13.1) e alla diagnosi dei salvataggi.

2.10 Nascita della partita. La fabbrica del mondo, nel Motore, costruisce lo `StatoPartita` iniziale come funzione pura dei valori caricati (regni, fronti, mappe, ufficiali: A §7.5) e del livello di difficoltà (A §5.4). La generazione del mondo non consuma alcuna estrazione del caso: le differenze fra i regni sono fissate nei dati una volta sola (00 §13.2.3, 03 §3.1) e il seme serve soltanto a meteo e guasti futuri (A §4.2). Il seme e l'identificatore della partita li fornisce la Sessione al momento della creazione, attingendo all'entropia di sistema, che le è consentita perché la Sessione non è il Motore; da quel momento entrambi vivono nello stato. La prima riga del giornale è l'atto di fondazione: versioni di schema, valori e testi, difficoltà, seme, identificatore. Stato iniziale ricostruito dalla fabbrica più comandi del giornale: questa è l'intera definizione di una partita (A §4.5).

2.11 Conclusione. Gli esiti di battaglia e di campagna vivono nello stato e sono dichiarati da eventi (A §3.7). I consolidati non definiscono una condizione di fine della partita a livello di regno nella prima versione: il regno è persistente e lo slot resta giocabile finché il giocatore non lo chiude. L'intestazione dello slot prevede comunque il marcatore di slot concluso: lo pone il giocatore chiudendo definitivamente la partita, o lo porrà una futura condizione di fine se il progetto la introdurrà; su uno slot concluso la Sessione rifiuta ogni comando e resta possibile la sola rigiocatura (A §13.2).

---

## 3. I comandi discreti

3.1 Protocollo. `Comando` è un tipo somma (enum) `Codable` con codifica stabile e versionata (A §13.1). Il Motore espone tre operazioni:

- `valida(comando, stato) -> Esito` — nessuna mutazione; restituisce ammissibilità, costi che verrebbero pagati e residui che ne conseguirebbero, oppure il motivo di non ammissibilità.
- `applica(comando, stato) -> (StatoPartita, [Evento])` — applica soltanto comandi validi; la validazione è rieseguita internamente e un comando non valido è un errore di programmazione, non un caso d'uso.
- `interroga(richiesta, stato) -> Risposta` — letture pure per la Presentazione (A §9.4).

3.2 Validazione e anteprima sono la stessa cosa. L'annuncio del costo prima della conferma, del residuo e del motivo di non disponibilità (00 §9.2, 02 §3.6) è la presentazione dell'esito di `valida`: un solo percorso di codice produce sia il controllo sia l'annuncio, e i due non possono divergere. I motivi di non ammissibilità sono un tipo chiuso che corrisponde uno a uno ai termini del vocabolario chiuso (02 §4.3 e insiemi collegati); non esistono motivi fuori vocabolario.

3.3 Comandi di campagna. L'elenco chiuso delle azioni di giornata è fissato in 01 §5.6.8.1 (chiusura di questa fase). I comandi corrispondenti: ordina marcia; ordina marcia forzata; impiega secondo scatto; rinuncia al secondo scatto; revoca marcia (gratuita, perde i giorni spesi: 01 §5.6.3.3); sosta con raccolta; riposo; riordino degli assetti; manutenzione delle macchine; imboscata; costruzione di opera da campo; costruzione di macchina in casella boscosa; distruzione di opera permanente nemica; sabotaggio; studio approfondito; esplorazione; presidio (restare fermi); divisione con collocamento del distaccamento; riunione (gratuita: 01 §5.6.0.3); imposizione della battaglia; accettazione della battaglia imposta; apertura della battaglia in sospeso (01 §6.2); dirottamento dei superstiti (01 §6.9). L'ingresso in una fortezza o al quartier generale è una marcia ordinaria e non ha comando proprio (01 §5.6.8.1). Consumano l'azione della giornata soltanto i comandi corrispondenti alle sedici azioni di 01 §5.6.8.1; non la consumano la revoca, la riunione, l'accettazione, l'apertura della battaglia e il dirottamento, e il secondo scatto con la sua rinuncia appartiene all'azione di marcia forzata già spesa (01 §5.6.4.3).

3.4 Comandi di battaglia: seleziona elemento del deck; deseleziona; piazza sull'esagono; muovi di una o due celle; ordina tiro sul bersaglio; ordina ingaggio in mischia; designa bersaglio e conferma (02 §9.2.1); dichiara resa (01 §10.1); ritira unità (durante la ritirata combattuta, 01 §10.4); termina il turno. L'annullamento e l'azzeramento **non** sono comandi: sono operazioni del giornale (A §6.4, RDA-05).

3.5 Comandi d'inverno e di regno: ordina lavoro (opera, con dichiarazione del momento di completamento: 01 §5.9.1.4); recluta; addestra o migliora reparto; mantieni miglioramento; acquisisci (01 §2.6); assegna truppe a fortezza; spesa breve fuori inverno (01 §5.5.1.4.1); prosegui alla stazione invernale successiva (le quattro schermate di 01 §5.9.1.1 avanzano soltanto per questo comando esplicito; fra una stazione e l'altra il Motore risolve le attività avversarie e produce l'apporto informativo).

3.6 Comandi di sistema che toccano lo stato: conferma del riquadro di passaggio di fase (01 §2.6.3.1); scelta dello schieramento proposto (01 §8.11); collocamento delle forze superstiti a fine battaglia (01 §15.4). La navigazione fra schermate non è un comando e non tocca lo stato, con l'unica eccezione dell'apertura della battaglia (01 §6.2), che è un comando perché muta la partita.

3.7 Eventi. `Evento` è un tipo chiuso e `Codable` che descrive un fatto in forma astratta: piazzamento confermato, elemento del deck esaurito, contatto avviato, esito di mischia, disingaggio, munizioni esaurite, rifornimento interrotto, marcia completata, imboscata scattata, sortita, cambio di stagione, passaggio di fase, blocco di campagna, arrivo di rinforzi nel deck, cambio di riga non incluso (è un fatto di navigazione, prodotto dalla Presentazione, non dal Motore). Gli eventi hanno tre destinazioni: gli annunci e i segnali tramite Segnali (A §11); il registro della campagna o della patria, dove il Motore stesso annota i soli fatti non decisi dal giocatore (01 §5.17.1); il resoconto di fine battaglia (01 §15.3.1).

3.8 Ordine di risoluzione della giornata di campagna (chiusura registrata in 01 §5.6.11): all'apertura della giornata il Motore estrae il meteo, aggiorna provviste, contatori e conoscenza; il giocatore ordina i propri gruppi in qualunque ordine; quando tutti i gruppi del giocatore hanno agito, agiscono i gruppi avversari in ordine deterministico; la giornata si chiude da sé (01 §5.6.0.6) con le risoluzioni di fine giornata: avanzamento delle marce lunghe, scatto delle imboscate, valutazione dei tagli, completamenti, decadimento della conoscenza. Ciò che il giocatore viene a sapere delle mosse avversarie passa esclusivamente dal sottosistema della conoscenza e dal registro.

3.9 Ordine di risoluzione del turno di battaglia, riscritto nella versione 1.3. Agisce per primo chi occupava per primo la casella dello scontro (chiusura registrata in 01 §9.4.1); l'imboscata è lo stesso ordine con i turni aggiuntivi e lo sconto (01 §9.3.2). I contatti si risolvono in due occasioni distinte (01 §9.7.1). La prima è l'istante in cui il contatto si forma: il Motore risolve QUEL contatto soltanto ed emette un evento che ne porta l'esito, come già fa per il tiro. La seconda è l'inizio di ciascun giro completo: il Motore risolve insieme tutte le mischie ancora in piedi, applica i disingaggi maturati — che si valutano soltanto qui, secondo 01 §9.8.5 — ed emette un unico evento aggregato. Gli annunci li costruisce Segnali da quegli eventi, poiché il Motore non conosce gli annunci (00 §3.2). Poi ciascuna parte, nel proprio turno, rigenera il budget con il riporto e spende azioni e volume; il turno di parte termina con il comando esplicito di fine turno.

3.9.1 Che cosa resta simultaneo. Dentro UNA risoluzione la simultaneità è intera: si calcolano tutti i danni di tutte le direzioni prima di applicarne uno solo, e i posti in mischia e gli insiemi dei concorrenti si leggono una volta sola dallo stato con cui la risoluzione si apre (01 §9.11.1, §9.10.2.3). Ciò che è caduto è la simultaneità FRA risoluzioni diverse dello stesso turno, ed è precisamente lo scopo della modifica: chi colpisce per primo colpisce prima. Ne discende che l'ordine in cui una parte muove i propri reparti conta, il che non è un effetto collaterale ma la profondità dichiarata da 01 §9.7.1.3.

---

## 4. Determinismo e perimetro del caso

4.1 Generatore. Un unico generatore deterministico con seme (algoritmo fissato nel Motore, indipendente dalla piattaforma) vive dentro lo stato: seme iniziale più contatore delle estrazioni. Nessun altro punto del programma genera numeri casuali; `SystemRandomNumberGenerator`, `Date`, e qualunque fonte esterna sono vietati nel Motore e il collaudo lo verifica (A §14.2).

4.2 Punti di estrazione. Il caso interviene in due soli punti, come da 01 §12.2: l'estrazione del meteo all'apertura della giornata di campagna e la prova di guasto delle macchine. Ogni estrazione è etichettata (scopo, giorno, oggetto) così che la riproduzione sia verificabile passo per passo.

4.3 Avversario senza caso. Le scelte dell'avversario discendono da propensioni e valutazioni, mai da estrazioni (01 §12.1). A parità di stato e di parametri, l'avversario fa sempre le stesse cose. Le situazioni di parità nelle sue valutazioni si risolvono con criteri d'ordine deterministici (identificatori, non casualità).

4.4 La sortita da piazzaforte bloccata è deterministica: una soglia in turni che dipende dalla propensione dell'ufficiale e dai malus accumulati (chiusura registrata in 01 §8b.5.1). L'annuncio ne dichiara l'avvicinarsi con termini di imminenza del vocabolario chiuso, senza usare il linguaggio della probabilità, che è riservato ai soli guasti (01 §12.3).

4.5 Riproducibilità. Stato iniziale, versione dei dati e giornale dei comandi determinano interamente la partita. È il fondamento comune di quattro funzioni: salvataggio e ripresa (A §6), rigiocatura (A §13.2), partita fra dispositivi (A §13.1) e riproduzioni d'oro del collaudo (A §14.6).

---

## 5. L'avversario

5.1 Collocazione. L'avversario vive nel Motore, perché il programma di verifica deve poterlo far giocare senza interfaccia (00 §16.1) e perché le sue mosse sono comandi come quelli del giocatore, validati dallo stesso percorso (A §3.1). Non ha accesso a informazioni negate dalla conoscenza: interroga lo stato attraverso la stessa vista filtrata per parte usata per il giocatore, salvo i vantaggi nascosti dichiarati (A §5.5).

5.2 Ufficiali. Ogni ufficiale è un insieme di parametri letti dai dati: propensione all'attacco, tolleranza alle perdite, tendenza all'accerchiamento o allo sfondamento, propensione all'imboscata, propensione alla ritirata (01 §14.3). Un'unica intelligenza, parametri diversi (01 §14.3). L'ufficiale è presentato prima della battaglia con nome e reputazione (01 §14.5).

5.3 Tre organi, stessa struttura: il **governo** decide le spese invernali e le acquisizioni del regno avversario, rispettando risorse e tetti d'epoca identici a quelli del giocatore (01 §5.9.1.8); lo **stratega** decide le mosse di campagna dei gruppi; il **tattico** decide i comandi di battaglia. Tutti e tre producono comandi ordinari e sono funzioni deterministiche di stato e parametri.

5.4 Difficoltà. Il livello generale agisce sulle risorse e sui margini del regno avversario alla generazione del mondo e nei bilanci, mai sul comportamento degli ufficiali (01 §14.4). I due assi non si mescolano.

5.5 Vantaggi nascosti. I vantaggi del giocatore (01 §13.2) risiedono in un file dei dati dedicato (A §7.5) letto tanto dal Motore quanto dal programma di verifica, che può disattivarli per misurare le probabilità reali (03 §7.1, A §12.5). Ogni vantaggio nuovo si aggiunge al file, a 01 §13 e a 03 §7.

5.6 Regno lontano. La specializzazione si fissa una volta sola, sull'ambito più debole del giocatore, al ricorrere della condizione di 01 §14.6.2, e da quel momento è immutabile nello stato (01 §14.6.3).

---

## 6. Persistenza

6.1 Giornale. Ogni partita ha un giornale: un file in appendice, una riga per voce. Le voci sono di due tipi: **comandi**, con progressivo, identificatore di parte e comando serializzato; **marcatori**, con progressivo e tipo (fondazione: A §2.10; inizio turno di battaglia; apertura giornata di campagna; punto di conferma: A §6.5). Anche i comandi dell'avversario vengono appesi, con il loro identificatore di parte: alla ripresa si riapplicano dal giornale senza reinterrogare l'avversario, così che una partita resti identica anche se i valori cambiano fra versioni compatibili (RDA-42). L'appendice avviene **prima** che l'esito del comando diventi visibile al giocatore: se il programma muore un istante dopo, la ripresa riproduce il comando e nulla è perduto. Questo, e soltanto questo, è il salvataggio automatico a ogni azione (00 §3.5): non esiste un "salva" separato, né un salvataggio a fine turno.

6.2 Istantanee. Ogni duecento voci di giornale — numero di struttura fissato nella Sessione, non valore di gioco — e a ogni confine significativo (apertura giornata, inizio turno di battaglia, apertura e chiusura di battaglia, stazione invernale, passaggio in secondo piano dell'applicazione) la Sessione scrive un'istantanea completa dello stato con l'indice del giornale a cui corrisponde. Le istantanee servono soltanto alla velocità: la verità è il giornale.

6.3 Ripresa. All'avvio si carica l'ultima istantanea valida e si riapplicano i comandi successivi del giornale. La ripresa restituisce esattamente il punto di interruzione, compresi lo schieramento in corso, il budget speso e l'elemento selezionato (01 §6.6), perché anche questi vivono nello stato (A §2.7). Durante la riapplicazione gli eventi prodotti da `applica` non raggiungono Segnali: nessun annuncio, suono o vibrazione ripete fatti già accaduti; vale lo stesso per l'annullamento e per la rigiocatura (A §1.7).

6.4 Annullamento e azzeramento. L'annullamento dell'ultima operazione ritira l'ultimo comando del giocatore dal giornale e ricostruisce lo stato dall'istantanea precedente riapplicando il resto. L'azzeramento ritira tutti i comandi del giocatore fino al marcatore competente del contesto: in battaglia, i piazzamenti e i movimenti dal marcatore di inizio turno (01 §8.10); nelle schermate di spesa, le spese dal punto di conferma di apertura; sulla mappa di campagna, gli ordini della giornata dal marcatore di apertura giornata, finché l'avversario non ha agito (00 §13.8 vale su ogni budget che si consuma). Il ritiro è una riscrittura atomica del giornale, con la stessa disciplina delle istantanee (A §6.8). Annullamento e azzeramento sono operazioni del giornale e non comandi, così che il giornale contenga soltanto le scelte effettive: la rigiocatura e la partita fra dispositivi vedono le mosse, non i ripensamenti (RDA-05). Entrambe le operazioni producono un annuncio dedicato di conferma, senza spostare il fuoco.

6.5 Punti di conferma. L'annullamento non retrocede mai oltre il più recente punto di conferma: fine del proprio turno di battaglia, chiusura della giornata di campagna, conferma di una spesa multipla, inizio delle azioni avversarie. I punti di conferma sono voci-marcatore del giornale (A §6.1).

6.6 Versionamento. Il giornale e ogni istantanea dichiarano tre versioni: schema dello stato, valori, testi (00 §15.1). All'apertura, un salvataggio con versione dei valori o dello schema incompatibile viene dichiarato tale e non aperto (00 §15.2), con un annuncio che nomina le versioni attese e trovate. La compatibilità è dichiarata dal manifest dei dati (A §7.2): una versione dei valori è compatibile solo se il manifest la elenca come tale rispetto a quella del salvataggio; in mancanza, incompatibile. La versione dei testi non blocca mai l'apertura.

6.7 Slot e posizioni. Le partite sono slot indipendenti, ciascuno una cartella (giornale, istantanee, intestazione) nella sandbox dell'applicazione. Le partite non stanno nella cartella visibile all'app File; vi stanno i dati e i testi (A §7.1).

6.8 Robustezza. Scritture atomiche (file temporaneo più sostituzione) per le istantanee; verifica di integrità riga per riga alla lettura del giornale, con troncamento all'ultima riga integra; un'istantanea corrotta fa scalare alla precedente. La perdita massima possibile è l'ultimo comando, mai la partita (00 §15.3).

---

## 7. I file dei valori

7.1 Collocazione. I Contenuti includono la copia di fabbrica. Al primo avvio, e a ogni aggiornamento che porti una versione più nuova, i file vengono copiati nella cartella Documenti dell'applicazione, visibile nell'app File (00 §15.4), in due alberi: `Valori/` e `Testi/`. Il programma carica da Documenti; se la validazione fallisce, carica la copia di fabbrica e lo dichiara con un annuncio, senza mai partire con dati misti.

7.2 Manifest. `Valori/manifest.json` dichiara: versione dei valori (semantica), elenco dei file con impronta, versioni di salvataggio compatibili (A §6.6), versione minima dello schema richiesta al programma. La versione si incrementa ogni volta che cambia una regola che incide sul modo in cui una partita in corso si svolgerebbe, e non soltanto quando cambia la forma dei file: il criterio, le sue ragioni e i casi esclusi stanno in 03 §9.2.1. Chi tocca una regola o un valore che entra in una formula del Motore incrementa la versione nella stessa modifica in cui rigenera le impronte.

7.2.1 Modalità di messa a punto. Il flusso di 00 §15.4 prevede che il tester modifichi i file direttamente su iPad, senza ricalcolare impronte né incrementare versioni. Quando le impronte non coincidono con il manifest ma la validazione dei contenuti riesce, il programma non torna alla fabbrica: deriva una versione locale marcata, composta dalla versione base più un suffisso calcolato dalle impronte correnti, la registra nei salvataggi e la dichiara con un annuncio all'apertura. La compatibilità dei salvataggi si valuta sulla versione base, con l'avvertenza dichiarata che i valori sono stati modificati localmente. Così la messa a punto resta possibile e ogni difetto segnalato resta riconducibile ai valori esatti con cui si è prodotto (RDA-45).

7.3 Forma delle voci. Ogni grandezza è espressa nella forma stabilita da 00 §13 e 03 §1: una **base di fase** per le grandezze fondamentali; **coefficienti** riferiti alla base per gli elementi (00 §13.2); dove la grandezza ammette variazione, un **intervallo** con la **regola di variazione**, cioè l'elenco delle cause dichiarate che ne spostano il valore e del passo di spostamento (00 §13.2.2, §13.2.3). Esempio di forma, puramente illustrativo della struttura e non dei numeri:

```json
"velocita_messaggeri": {
  "intervallo": [0.6, 1.4],
  "unita": "coefficiente su base di fase",
  "variazione": [{ "causa": "miglioramento_vie", "passo": 0.2 }]
}
```

7.4 Formule nel codice, coefficienti nei file. Le formule uniche condivise (costo di piazzamento per profondità, danno per accoppiamento offesa-protezione, giorni di marcia, arrivo dei rinforzi) sono struttura del gioco e vivono nel Motore, con collaudo dedicato; i file contengono soltanto coefficienti, basi, intervalli e minimi (00 §13.3). Nessuna tabella a doppia entrata è ammessa nei file, e la validazione la respinge.

7.5 Elenco dei file dei valori. La struttura completa, con la corrispondenza alle voci del documento 03, è registrata in 03 §9 (aggiornamento di questa fase). In sintesi: `fasi.json` (basi di fase, progressione monetaria), `archetipi.json` (parametri di 01 §3.4 come coefficienti), `assetti.json`, `acquisizioni.json` (ambiti, ordinamenti, costi, effetti tipizzati), `terreni-e-strade.json`, `meteo.json` (probabilità per stagione), `opere.json`, `caratteristiche-campo.json` (modificatori tipizzati), `ufficiali.json`, `regni.json` (differenze di partenza, fissate una volta sola: 03 §3.1), `vantaggi-nascosti.json`, `minimi.json`, `formato-battaglia.json` (capacità di volume, riporti, soglie), `nomi-gruppi.json`, `mappe/<fronte>/<mappa>.json`, `aptica.json` (00 §5.5), `suoni.json`.

7.6 Mappe. Ogni mappa è un file dichiarativo: formato, caselle con terreno, strade, boschi, acqua, strettoia (al più una: 01 §5.1.3), città e piazzeforti, uscite di strada fuori mappa, posizioni dei quartier generali. Le mappe sono contenuto, non codice; le modificazioni permanenti (vie impresse: 01 §5.14.4.1) vivono nello stato del mondo, non nel file.

7.7 Effetti tipizzati. Acquisizioni, caratteristiche del campo e opere dichiarano i propri effetti scegliendo da un insieme chiuso di **ganci** definiti dal Motore (esempio: "coefficiente sul costo di marcia", "sblocca archetipo", "sposta valore dentro la forbice per causa dichiarata"). Un file non può introdurre un effetto che il Motore non conosce: la validazione respinge i ganci ignoti. È il compromesso che tiene i valori fuori dal programma senza trasformare i file in un linguaggio di programmazione.

7.8 Validazione al caricamento. Il modulo Dati valida: schema e tipi; completezza (ogni archetipo ha tutti i parametri di 01 §3.4); coerenza degli intervalli (minimo non superiore al massimo); presenza dei minimi obbligatori dove il troncamento può dare zero (03 §8); coerenza delle mappe (se c'è una città, una strada vi conduce: 01 §5.5.3; al più una strettoia); completezza delle chiavi dei testi per ciascuna lingua rispetto agli insiemi richiesti (A §8.4), con ricaduta sulla copia di fabbrica quando il pacchetto in Documenti è incompleto; vincoli dichiarati dal documento 03 (esempio: malus di mancanza provviste più marcati di quelli di marcia forzata, 03 §4.3.1). Un fallimento produce un rapporto leggibile con il nome del file e della voce; i messaggi del rapporto sono anch'essi testi con chiave, risolti esclusivamente sulla copia di fabbrica dei testi, che è sempre presente e coperta dal collaudo: è il solo modo di parlare all'utente quando è proprio il pacchetto in Documenti a essere rotto (00 §14.1).

7.9 Sostituzione senza ricompilare. I file in Documenti si possono modificare anche direttamente su iPad (00 §15.4). I valori e i testi si caricano all'avvio del programma e all'apertura di uno slot, e restano fissi per l'intera sessione di gioco: nessuna rilettura avviene a partita aperta, così che nessun aggiornamento di massa di etichette possa investire una schermata mentre il fuoco vi si trova (00 §11.1). Per applicare una modifica si chiude lo slot e lo si riapre; al ritorno in primo piano la Sessione verifica il manifest e, se la versione è cambiata ed è incompatibile con lo slot aperto, sospende la partita con un annuncio e torna alla schermata degli slot, dove vale la regola dei salvataggi versionati (A §6.6).

---

## 8. I testi

8.1 Fuori dal programma. Nessuna stringa mostrata o annunciata vive nel codice, nemmeno provvisoriamente (00 §14.1). I testi stanno in `Testi/`, organizzati come pacchetti di localizzazione per lingua caricati a runtime tramite `Bundle(path:)`: la prima versione contiene `it.lproj`, la versione inglese aggiungerà `en.lproj` senza toccare il codice (00 §14.1).

8.2 Frasi intere, plurali di sistema. Ogni annuncio è una frase completa con segnaposto (00 §14.2), definita in `.strings`; le forme plurali usano `.stringsdict`, cioè il meccanismo di localizzazione del sistema (00 §14.3). Il formato `.strings`/`.stringsdict` è scelto proprio perché è quello che le API di Foundation sanno caricare da un bundle esterno con gestione automatica dei plurali; è testo semplice, modificabile dall'app File come i valori.

8.3 Lingua dichiarata. Ogni pacchetto di testi dichiara la propria lingua; ogni annuncio e ogni etichetta viene consegnato alla Presentazione e a Segnali come coppia testo-lingua, applicata come attributo di lingua dell'elemento accessibile o dell'annuncio (00 §14.4). Il meccanismo è unico e centrale: nessun testo può raggiungere la voce senza passare da lì.

8.4 Vocabolario chiuso. I termini del vocabolario chiuso (02 §4) vivono in un file dedicato del pacchetto testi, con chiavi stabili per insieme e per stato; sono localizzati come termini fissi (00 §14.5). Il codice usa soltanto le chiavi; il collaudo verifica che ogni motivo di validazione e ogni stato dichiarabile abbia il proprio termine in ogni lingua (A §14.4).

8.5 Ordine e verbosità. Per ciascun tipo di annuncio, il file dei testi dichiara le varianti dei tre livelli di verbosità; l'ordine di priorità delle informazioni è fisso e i livelli brevi tagliano le ultime voci, mai porzioni arbitrarie (00 §9.5). La testa fissa dell'annuncio di cella non è mai tagliata (02 §3.9).

8.6 Versione. `Testi/manifest.json` dichiara la versione dei testi; non blocca mai l'apertura dei salvataggi (A §6.6).

---

## 9. La presentazione

9.1 UIKit programmatico. Lo strato di presentazione è UIKit, senza storyboard, per tutte le schermate. La ragione è il principio 1: UIKit offre il controllo diretto e maturo di ciò da cui il progetto dipende — l'elenco ordinato degli elementi accessibili (`accessibilityElements`), i rotori personalizzati, lo spostamento esplicito del fuoco, l'aggiornamento degli elementi sul posto senza ricostruzione — mentre la ricostruzione dichiarativa delle viste di SwiftUI rende fragile proprio la stabilità del fuoco che 00 §11 impone. La scelta, le alternative esaminate e le condizioni di revisione: RDA-02.

9.2 Schema per schermata. Ogni schermata è un view controller con un presentatore: il presentatore interroga il Motore (A §9.4), costruisce un modello di presentazione (testi già risolti, elementi già ordinati) e lo consegna alla vista; le intenzioni dell'utente risalgono come comandi. Nessuna schermata conserva stato di gioco proprio: ciò che deve sopravvivere sta nello `StatoPartita` (A §2.7) o nelle preferenze (A §10.8).

9.3 Elenco delle schermate: avvio e slot di partita; patria (schermata di partenza: 01 §5.6.10); schermata delle campagne, articolata per fronti e località (01 §5.6.10.1); mappa di campagna con registro; battaglia con deck e comandi di annullamento e azzeramento; pannello della cella (A §10.4); resoconto di fine battaglia (01 §15.3.1); dichiarazione di conclusione della campagna, con l'esito e le conseguenze territoriali (01 §5.14.2, A §2.11); le quattro stazioni invernali con le linguette per durata (01 §5.9.1.3); riquadro narrativo del passaggio di fase (01 §2.6.3.1); impostazioni (02 §14); schermata di apprendimento dei segnali (02 §13).

9.4 Interrogazioni. Il Motore espone una vista di sola lettura per parte, filtrata dalla conoscenza (A §5.1): contenuto e stato di una casella o cella, esito di validazione per un comando ipotetico, insiemi per i rotori (celle valide, gruppi che non hanno agito, eccetera), informazione di stato della battaglia e della campagna (02 §6.4, §6.5), riserve e costi. La Presentazione non calcola mai un dato di gioco: se un'informazione non è ottenibile con un'interrogazione, si aggiunge l'interrogazione al Motore, non il calcolo all'interfaccia.

9.5 Criterio di revisione del confine. Regola pratica vincolante: nella Presentazione non possono comparire numeri di gioco letterali, formule su grandezze di gioco, né confronti fra quantità di gioco che decidano un esito. Ogni `if` su una quantità di gioco in Presentazione è un difetto da spostare nel Motore. Il collaudo statico lo sorveglia (A §14.5).

---

## 10. Accessibilità realizzativa

10.1 Griglie come contenitori di elementi persistenti. La griglia esagonale e la mappa di campagna sono ciascuna una vista contenitore che espone `accessibilityElements`: un oggetto elemento per cella, creato una volta per battaglia o campagna e **aggiornato sul posto** a ogni cambiamento (etichetta, valore, azioni). Gli elementi non vengono mai ricreati durante l'uso: la ricreazione è ciò che fa perdere il fuoco a VoiceOver, ed è vietata (00 §11.1, RDA-03). Ogni cella ha nome, ruolo, valore e azioni (00 §2.3, §2.4); le celle di ostacolo sono elementi non interattivi ma presenti e annunciati (02 §3.7).

10.2 Ordine di lettura esplicito. L'ordine è dichiarato elemento per elemento, mai dedotto dalla geometria (00 §11.5): celle da ovest a est e dall'alto in basso, poi il deck, poi annullamento e azzeramento (02 §2.8). All'apertura della battaglia il fuoco è sull'intestazione del deck (02 §2.9). I due comandi globali sono distanziati dal bordo inferiore e di altezza piena (02 §8.5).

10.3 Fuoco: regole operative. (a) Nessun aggiornamento di contenuto pubblica notifiche che riposizionano il fuoco; gli aggiornamenti avvengono sugli elementi esistenti. (b) L'apertura di un pannello sposta il fuoco al suo primo elemento con notifica esplicita; la chiusura lo riporta all'elemento di origine, memorizzato dalla Presentazione. (c) Dopo una conferma di piazzamento il fuoco resta sulla cella (00 §11.3). (d) L'esaurimento di un elemento del deck deseleziona senza spostare il fuoco, con annuncio (02 §5.3). (e) Ogni cambiamento di stato rilevante è annunciato senza rubare il fuoco (00 §11.4). Il collaudo di integrazione contiene una prova per ciascuna di queste regole (A §14.4).

10.4 Pannello della cella. L'attivazione di una cella apre il pannello con le azioni di gioco possibili (00 §7.4), ciascuna con costo ed effetto dichiarati dall'esito di validazione. Criterio di composizione: le azioni che l'oggetto non possiede o che il suo stato rende inefficaci non compaiono, come per un reparto impegnato (02 §9.4); le azioni possedute ma al momento non valide compaiono con il motivo del vocabolario chiuso, perché l'assenza silenziosa di un'azione conosciuta lascerebbe il giocatore a indovinare il perché (00 §9.1). La sequenza a due celle (unità poi bersaglio) segue 02 §9.2.1: scelta del bersaglio da elenco nel pannello oppure designazione sulla griglia, con annullamento esplicito e stato "in attesa di bersaglio" dichiarato.

10.5 Azioni personalizzate. Contengono soltanto spostamenti di navigazione (02 §2.7): quattro direzioni sul campo di battaglia, due sulla mappa di campagna (02 §2.5), mai più di cinque voci (00 §7.5).

10.6 Rotori. Un rotore personalizzato per ciascun insieme confermato in 02 §7 (aggiornamento di questa fase), alimentato dalle interrogazioni del Motore. I rotori trasversali (battaglie in sospeso, campagne attive) funzionano da qualunque schermata di campagna (02 §7.4). L'ordine interno di ciascun rotore è quello fissato da 02 §7.4 ed è realizzato dalle interrogazioni del Motore: è comportamento, non testo, e il pacchetto dei testi non può alterarlo.

10.7 Annunci. La divisione dei compiti è netta. Le **etichette e i valori degli elementi accessibili** — ciò che VoiceOver legge atterrando su una cella, una voce del deck, una riga di gestione — li costruisce la Presentazione, componendo i modelli del modulo Testi con gli esiti delle interrogazioni, al livello di verbosità attivo. Gli **annunci proattivi** — ciò che il gioco dice da sé al verificarsi di un evento — passano tutti da Segnali (A §11.6): l'ingresso di Segnali è l'evento astratto con i suoi dati minimi, e Segnali risolve modello, verbosità e lingua tramite il fornitore di preferenze ricevuto alla creazione, assegna la priorità (interrompente per gli esiti richiesti dall'utente, accodata per i fatti di fondo) e serializza la coda. L'aggregazione dei contenuti di gioco è già avvenuta nel Motore sotto forma di eventi aggregati (A §3.9): Segnali non aggrega mai contenuti di gioco.

10.8 Verbosità. I tre livelli (00 §9.5) sono una preferenza locale dell'apparecchio, non parte dello stato di partita; la leggono la Presentazione per le etichette e Segnali per gli annunci, dallo stesso fornitore di preferenze.

10.9 Gesti fissi (chiusura registrata in 02 §6.7): il gesto magico a due dita richiama l'informazione di stato del contesto (battaglia o campagna) senza abbandonare la griglia (02 §6.4); il gesto di fuga risale di un livello nell'architettura patria-campagne-mappa (02 §6.5.4.4); il passaggio diretto fra campagne avviene con il rotore delle campagne attive.

10.10 Scorrimento e ingrandimento. La griglia vive in una vista scorrevole e ingrandibile; tutte le celle restano raggiungibili a scorrimenti anche fuori dalla porzione visibile, e il fuoco su una cella non visibile fa scorrere la vista (00 §10.4). Le cornici accessibili si aggiornano a ogni cambiamento di geometria.

10.11 Esplorazione al tatto. Gli elementi hanno cornici reali e bersagli non inferiori alla dimensione minima raccomandata (00 §10.4); l'esplorazione al tatto funziona da sé per costruzione, senza codice dedicato. Nessuna informazione è raggiungibile soltanto al tatto né soltanto a scorrimenti (02 §2.11).

10.12 Schermate di gestione. Nessuna tabella a caselle: ogni riga è un unico elemento che si annuncia in una frase e apre il dettaglio (02 §10.3). Le voci di spesa dichiarano costo su riserva per le sole risorse consumate (02 §8.7); il riquadro delle riserve è un elenco navigabile (02 §8.7.2).

10.13 Registro degli eventi. Ogni voce è un elemento a sé, in ordine dal più recente, con il giorno; l'attivazione porta il fuoco sulla casella del fatto (02 §6.6).

---

## 11. Segnali: il punto centrale

11.1 Un solo punto del programma riceve gli eventi in forma astratta e decide i canali in base all'apparecchio e alle preferenze (00 §5.3). Nessun altro modulo nomina vibrazioni, suoni o annunci.

11.2 Ingresso. Segnali riceve: gli eventi del Motore (A §3.7) e i fatti di pura navigazione prodotti dalla Presentazione (cambio di riga: 00 §11.6). Ogni evento porta i dati minimi per costruire l'annuncio dal modello di testo.

11.3 Decisione dei canali. Per ciascun significato assegnato (02 §11.7.1): annuncio sempre; suono se il canale sonoro è attivo; aptica se il canale tattile è attivo **e** l'apparecchio dispone del motore aptico (00 §5.1). Ogni segnale aptico ha sempre la controparte sonora o testuale (00 §5.2); la tabella delle assegnazioni è in 02 §11.7.1 e i pattern in `aptica.json` (00 §5.5).

11.4 Aptica. CoreHaptics con motore mantenuto pronto per tutta la sessione di gioco, non acceso e spento a ogni evento (00 §5.6); rilevamento della modalità di risparmio energetico e degrado silenzioso al solo suono. I pattern sono costruiti prima di tutto sul ritmo, con intensità e nitidezza come sfumature interne alle famiglie (00 §5.4, 02 §11.4).

11.5 Suoni e ambienti. Suoni brevi e senza parole per esiti e cambi di stato (00 §6.3); ambiente sonoro e tema musicale per fase storica, dichiarati in `suoni.json` e cambiati al passaggio di fase (01 §2.6.3.1). Nessuna narrazione registrata sostituisce mai un annuncio (00 §6.2). Ogni informazione affidata a un suono è recuperabile in forma testuale, senza eccezioni (00 §6.4), e per ciascun significato il canale di recupero è dichiarato nella tabella di 02 §11.7.1 così com'è realizzato qui: sulla mappa di campagna il registro degli eventi (02 §6.6.1); in battaglia, che non ha registro, lo stato interrogabile della cella interessata e l'informazione di stato del tocco magico (02 §6.4). Il collaudo verifica la terna segnale-suono-testo per ogni significato (A §14.4).

11.6 Coda degli annunci. Una coda unica con priorità (A §10.7). Gli annunci con lingua dichiarata (A §8.3) usano gli attributi di annuncio del sistema; la coda non scarta mai un annuncio richiesto dall'utente. Per i fatti di fondo vale una politica di coalescenza dichiarata e mai temporale: un annuncio di fondo non ancora pronunciato viene sostituito, non affiancato, da un annuncio successivo che ne aggiorna il contenuto, e ciò che la coda comprime resta integralmente recuperabile nel registro (00 §6.4). Nessun annuncio decade per il passare del tempo reale (00 §4).

---

## 12. Il programma di verifica

12.1 Forma. Una libreria di misura più un eseguibile SwiftPM da riga di comando, per macOS, senza interfaccia (00 §16.1). La misura sta nella libreria e non nell'eseguibile perché il fumo delle simulazioni del punto 14.7 è collaudo a tutti gli effetti e deve poter importare ciò che misura (RDA-58). Legge gli stessi Contenuti del gioco, o una cartella di valori alternativa indicata a riga di comando, o una cartella di scenari alternativa; usa Motore e Dati identici al gioco, il che è garantito dal fatto che sono gli stessi bersagli compilati. Non contiene alcuna regola propria: fa agire il tattico del Motore su entrambe le parti e applica i comandi del Motore. Se una misura richiede una grandezza che il Motore non espone, la grandezza si espone dal Motore e non si riscrive qui.

12.2 Scenari. Tre famiglie: **scontro singolo** (due schieramenti su un formato, tattici contrapposti con parametri dati), **campagna** (una mappa, due strateghi), **partita lunga** (più anni con inverni, per il costo di mantenimento e la progressione). Gli scenari sono file dichiarativi riutilizzabili, così che una misura sia ripetibile. Realizzata nella fase C la prima famiglia: ogni scenario dichiara formato, caratteristica, ostacoli, i due mazzi, il tetto dei giri, le soglie di accettazione e gli ASSI lungo cui la misura si ripete. L'insieme degli assi è chiuso, come i ganci delle caratteristiche di campo del punto 7.7, e un asse ignoto è respinto in caricamento anziché ignorato in silenzio. Accanto agli scenari vive un file di parametri dei banchi di misura, che dichiara le condizioni pari in cui le misure controllate si prendono: non sono valori di gioco e non entrano in alcuna formula del Motore.

12.3 Estremi degli intervalli. Ogni campagna di misura prova gli estremi delle forbici e non una sola configurazione (00 §13.2.4), combinando gli estremi delle grandezze sotto esame con i valori centrali delle altre, più le combinazioni peggiori dichiarate nello scenario.

12.3.1 Sul piano di battaglia gli estremi sono l'UNICA sorgente di variazione, e non un complemento dei semi. La battaglia non contiene alcuna estrazione del caso (01 §12.1) e il tattico è deterministico: due corse sulla stessa configurazione danno lo stesso identico esito, e un seme non produrrebbe alcuna distribuzione. La configurazione prende quindi, nelle righe di uscita del punto 12.6, il posto che il seme occupa sul piano di campagna, dove meteo e guasti esistono.

12.4 Metriche. Il programma misura le grandezze del documento 03 §6, ciascuna con uno scenario dedicato: soglia minima di turni prima della resa (03 §6.1), margine di convenienza della ritirata (03 §6.2), costo di mantenimento come freno (03 §6.3), ampiezza della fascia in cui il tiro uccide (03 §6.4), frequenza degli scontri per carattere degli ufficiali (03 §6.5), rapporto volume-profondità e peso della sorpresa (03 §6.6), precisione dell'apporto informativo (03 §6.7), peso della fortezza in difesa (03 §6.8), sbilanciamento dei formati minori (03 §6.9), più le percentuali di esito per configurazione (00 §16.1) e i margini non percepibili giocando (00 §16.2).

12.5 Vantaggi nascosti. Il programma li legge da `vantaggi-nascosti.json` e li può attivare o disattivare per scenario, per misurare sia il gioco come è sia le probabilità reali sottostanti (01 §13.1, 03 §7.1).

12.6 Uscita. Righe CSV o JSON con: scenario, configurazione, seme, esito, durata, perdite, metriche dichiarate. Ogni riga è riproducibile: contiene ciò che serve a rigiocare la stessa simulazione. Le soglie di accettazione per ciascuna metrica si fissano in sede di taratura e vivono nello scenario, non nel codice.

12.7 Prestazioni. Il Motore, essendo un valore senza dipendenze, si presta all'esecuzione parallela di simulazioni indipendenti; il programma parallelizza per scenario e per seme. Nessun requisito di prestazione del gioco dipende però dalla Verifica.

---

## 13. Le due funzioni future

13.1 Partita fra dispositivi vicini. La partita amichevole sulla stessa rete locale, senza server (00 contesto), consiste nello scambio della sequenza di comandi (00 §3.4). Predisposizione realizzata fin d'ora: (a) il Motore consuma comandi da qualunque sorgente, e la sorgente avversaria è un protocollo `SorgenteComandi` di cui l'avversario interno è la prima implementazione; (b) la codifica dei comandi è stabile e versionata (A §3.1); (c) il determinismo totale (A §4) garantisce che due dispositivi che applicano la stessa sequenza restino identici, e l'impronta di stato (A §2.9) permette di accorgersi di una divergenza; (d) il seme del caso appartiene allo stato iniziale condiviso. La realizzazione futura aggiungerà il trasporto (la rete locale) e la stanza di avvio; nessun modulo esistente dovrà cambiare. Due avvertenze registrate (RDA-11): la trasmissione dei comandi all'altro apparecchio è differita ai punti di conferma (A §6.5), così che l'annullamento e l'azzeramento, che sono operazioni locali del giornale (A §6.4), non possano mai ritirare un comando già trasmesso; e durante il turno di opacità dell'imboscata i comandi dell'imboscante viaggiano comunque, applicati senza essere presentati, poiché la riservatezza fra giocatori amichevoli non è un requisito.

13.2 Rigiocatura. Una partita conclusa è il suo giornale più lo stato iniziale e la versione dei dati (A §4.5). Il Motore espone un `Riproduttore` che avanza e retrocede lungo il giornale producendo stati ed eventi; la Presentazione potrà montarvi sopra una consultazione in sola lettura con gli stessi elementi accessibili del gioco. La retrocessione usa le istantanee intermedie. Nessuna funzione del gioco può scrivere sul giornale di una partita conclusa.

---

## 14. Il collaudo automatico

14.1 Livelli: collaudo del Motore, collaudo dei Dati, collaudo di accessibilità, collaudo di integrazione, riproduzioni d'oro, più il fumo delle simulazioni. Tutto gira a ogni modifica in integrazione continua locale (nessun servizio esterno richiesto).

14.2 Collaudo del Motore. Ogni regola numerata dei consolidati che il Motore realizza ha almeno una prova che la cita per numero. Prove obbligatorie: determinismo (stesso giornale, stessa impronta di stato); troncamento e minimi per proprietà (00 §13.5, §13.6); divieto di fonti di caso esterne (A §4.1); chiusura del turno e conservazione dello scatto (01 §5.6.4.2); regola del taglio con i casi di bordo (01 §5.2.2.2); disingaggio e seconda mischia senza soglia (01 §9.8.3); sequenza dell'imboscata e ritorno della trasparenza (01 §9.3.2.1); validazione esaustiva (ogni comando non valido produce un motivo del tipo chiuso).

14.3 Collaudo dei Dati. Validazione dei file di fabbrica sempre verde; file volutamente malformati respinti con il rapporto giusto; coerenza fra vocabolario chiuso e tipi del Motore (ogni motivo e ogni stato ha il suo termine in ogni lingua); vincoli inter-valore del documento 03 (A §7.8).

14.4 Collaudo di accessibilità. Automatico e bloccante: ogni elemento interattivo ha etichetta, tratti e azioni; l'ordine di lettura delle griglie corrisponde alla specifica (02 §2.8); ogni evento ha il modello di annuncio nei tre livelli di verbosità e in ogni lingua; ogni segnale aptico assegnato ha controparte sonora e testuale (00 §5.2); le prove di fuoco di A §10.3 eseguite su interfaccia reale (XCUITest): dopo il piazzamento il fuoco è sulla cella, dopo l'esaurimento del deck il fuoco non si muove, all'arrivo dei rinforzi il fuoco non si muove.

14.5 Collaudo dei confini. Verifica statica delle dipendenze fra bersagli (A §1.3) e assenza di stringhe di testo utente nel codice (00 §14.1): una prova compila l'elenco delle stringhe letterali dei bersagli e fallisce se ne trova fuori dalle liste consentite (chiavi, identificatori).

14.6 Riproduzioni d'oro. Giornali registrati di partite significative (uno scontro completo, una campagna, un inverno) riapplicati a ogni modifica: l'impronta di stato finale deve coincidere. Almeno una riproduzione è incrociata fra iOS e macOS, a presidio del determinismo fra piattaforme (A §2.2.1). Quando una modifica di regole è voluta, la riproduzione si rigenera con revisione esplicita. È la rete di sicurezza del determinismo nel tempo. Una prova di interfaccia dedicata verifica che dopo un annullamento gli elementi accessibili non siano stati ricreati e il fuoco non si sia mosso (A §10.3, RDA-03).

14.7 Fumo delle simulazioni. Una corsa breve del programma di verifica (pochi scenari, semi fissi) fa parte del collaudo: garantisce che Motore e Dati restino simulabili senza interfaccia, che è un requisito e non un accessorio (00 §16.1).

---

## 15. Ordine di costruzione

15.1 Il primo traguardo è un singolo scontro completo, dalla schermata iniziale alla battaglia conclusa, perfettamente accessibile, portato ai tester prima di costruire il piano di campagna (00 §16.4, 02 §16.3). L'ordine che segue lo rispetta e ordina il resto per dipendenza.

15.2 Fase A — Fondamenta. Motore minimo: stato di battaglia, comandi di piazzamento e movimento, validazione con vocabolario chiuso, giornale e istantanee, generatore con seme. Dati minimi: manifest, archetipi, formato di battaglia, testi italiani. Collaudo dei livelli 14.2 e 14.3 attivo dal primo giorno. Criterio di uscita: una battaglia si gioca da collaudo, senza interfaccia, con giornale riproducibile.

15.3 Fase B — Lo scontro accessibile. Presentazione della battaglia: griglia, deck, pannello della cella, annullamento e azzeramento, rotori del campo, annunci con verbosità, Segnali con aptica e suoni, impostazioni, schermata di apprendimento dei segnali, resoconto finale, salvataggio e ripresa a metà scontro. Tattico avversario di prima stesura. Criterio di uscita: lo scontro completo giocabile solo con VoiceOver, consegnato ai tester via TestFlight (00 §16.3). Nessun lavoro della fase D comincia prima di questa consegna.

15.4 Fase C — Verifica. Programma di verifica sugli scontri: scenari, metriche di battaglia (03 §6.1, 6.2, 6.4, 6.6), estremi degli intervalli. Prima taratura dei valori di battaglia sui numeri, non a impressione (00 §16.1). Procede in parallelo al ritorno dei tester sulla fase B.

15.5 Fase D — La campagna singola. Mappa, gruppi e giornata, marcia e marcia forzata, rifornimento e taglio, conoscenza e ricognizione, imboscata, opere da campo, innesco e rifiuto della battaglia, registro, rotori di campagna, informazione di stato. Criterio di uscita: una campagna su una mappa, con battaglie vere, giocabile e riproducibile.

15.6 Fase E — Il regno e l'inverno. Patria, cinque risorse, quattro stazioni invernali, reclutamento e addestramento, miglioramenti e mantenimento, acquisizioni e tetti d'epoca, opere permanenti, apporto informativo, governo avversario simmetrico. Criterio di uscita: un anno intero giocabile.

15.7 Fase F — Il mondo. Fronti e campagne multiple con scarto massimo, schermata delle campagne, regno lontano e specializzazione, passaggio di fase con riquadro e cambio d'ambiente, scenari di verifica di partita lunga (03 §6.3, 6.5, 6.7, 6.8, 6.9). Criterio di uscita: la prima versione completa nelle sue parti.

15.8 Fase G — Rifinitura e lingua inglese. Taratura finale sui numeri della Verifica, pacchetto testi inglese, revisione di parità con i tester su tutto il flusso. La rigiocatura e la partita fra dispositivi restano fuori dalla prima versione; le loro predisposizioni sono collaudate (A §13).

15.9 In ogni fase i tester non vedenti sono coinvolti dal primo prototipo giocabile della fase, non alla fine (00 §16.3).

---

## 16. Chiusure dei punti aperti: dove sono registrate

16.1 Tutti i punti aperti elencati in 01 §16.2 e 02 §17.1–17.2 sono stati chiusi in questa fase. Le chiusure che incidono sul gioco sono registrate nei consolidati aggiornati (01 versione 3.1, 02 versione 2.1, 03 versione 2.0), ciascuna nel punto competente; le chiusure di natura tecnica sono realizzate in questo documento. Ogni chiusura, tecnica o di gioco, ha una voce nel registro delle decisioni architetturali con problema, opzioni, scelta, motivazione e conseguenze. L'elenco sintetico con i rinvii: RDA-13 fino a RDA-40; le decisioni tecniche sono RDA-01 fino a RDA-12 e, dalle verifiche di questa stessa fase, RDA-41 fino a RDA-45.

16.2 Le grandezze che le chiusure hanno introdotto senza fissarne il valore sono registrate nel documento 03 (aggiornamento di questa fase) e appartengono alla taratura: nessun valore numerico di gioco è stato stabilito in questa fase.
