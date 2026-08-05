# Incarico — Tocco diretto, impianto di prova sul simulatore, e i tre cancelli mancanti

Documento operativo per una sessione di Claude Code nella cartella di progetto. Da consegnare come primo messaggio della sessione. Non richiede altre istruzioni.

Presuppone consegnato esame-critico.md. Leggilo per intero prima di cominciare: questo incarico ne discende e ne dà per acquisiti i risultati.

## Il criterio che governa l'intera sessione

L'esame critico ha stabilito un fatto che vale più di ogni altro suo risultato. In questo progetto le regole scritte vengono disattese sistematicamente, mentre i controlli che rifiutano non lo sono mai. Il contrasto interno che lo dimostra è fra note-di-rilascio.txt, coerente e con quattordici commit su trentanove perché carica-testflight.sh rifiuta il caricamento se manca, e nota-per-il-titolare-mappa.md, errata in quattro affermazioni su quattro e ferma a due commit su trentanove, protetta soltanto da una prescrizione scritta.

Ne discende il criterio di questa sessione: ogni requisito che introduci va imposto da qualcosa che rifiuta, non da qualcosa che raccomanda. Una prescrizione aggiunta a un documento non è un intervento; è un intervento un controllo che fallisce, uno script che si ferma con codice diverso da zero, un tipo che non compila. Quando ti trovi davanti a due modi di garantire una cosa, scegli sempre quello che rende impossibile lo stato sbagliato anziché quello che lo vieta.

## Ordine di esecuzione e criterio di arresto

Le sezioni vanno eseguite nell'ordine in cui compaiono, perché ciascuna dipende dalla precedente: senza tocco diretto nessuna prova automatica può esercitare il gioco, e senza cancelli le prove nuove non girerebbero comunque.

Se la capacità della sessione non basta a completarle tutte, fermati al confine dell'ultima sezione conclusa e verde, e dichiara da dove si riprende. Non lasciare sezioni a metà. Non comprimere le sezioni finali per arrivare in fondo.

## I tre cancelli, che vengono prima di tutto

Sono i più economici e sono la condizione perché il resto abbia effetto.

Il collaudo completo come cancello. Oggi .github/workflows/collaudo.yml e scripts/carica-testflight.sh eseguono soltanto swift test sul pacchetto, cioè 217 prove su 261; le 42 ospitate e le 2 d'interfaccia non sono cancello per nulla, in contraddizione con 05 §14.1, e memoria-infrastruttura.md riga 95 descrive la situazione come una protezione. Estendi entrambi all'esecuzione dell'intero insieme, prove ospitate e d'interfaccia comprese, con il caricamento che si interrompe se una qualsiasi fallisce. Correggi la riga della memoria di infrastruttura. Verifica il cancello facendolo fallire di proposito una volta.

La codifica del giornale. CompatibilitaGiornaleTest protegge ComandoBattaglia e ComandoCampagna con uno switch esaustivo, ma per VoceGiornale legge l'insieme dei casi dai campioni e lo confronta con un letterale scritto a mano: un caso nuovo privo di campione non compare, l'uguaglianza regge e la prova passa. stato-avanzamento.md riga 219 attribuisce alla prova una protezione che su quel tipo non esercita. Portala alla stessa forma degli altri due, con lo switch esaustivo che non compila se un caso viene aggiunto senza il proprio campione. Va fatto ora e non alla prossima unità, perché impatto-marcia-lunga.md §7 e RDA-76 stabiliscono che la revoca della marcia introdurrà un caso nuovo proprio lì, e quel passaggio è ciò che rende irrecuperabili i salvataggi.

La nota per il titolare. È il documento su cui si forma il giudizio del titolare sul lavoro, ed è l'unico che nessuno rilegge. Rigenerala perché corrisponda al codice attuale, correggendo le quattro affermazioni errate individuate dall'esame critico, e mettila dietro un cancello della stessa natura di quello che protegge la nota di rilascio: il caricamento si interrompe se la nota manca, se non è stata aggiornata nel commit in cui il comportamento che descrive è cambiato, o se contiene riferimenti a gesti, comandi o schermate che il codice non espone. La forma esatta del controllo la scegli tu, con il vincolo che debba rifiutare e non avvertire. Se non riesci a rendere verificabile automaticamente l'intero contenuto, rendi verificabile la parte che riguarda gesti, comandi e nomi delle schermate, e dichiara che cosa resta fuori.

Conserva inoltre in cartella, da ora in avanti, gli incarichi ricevuti e i resoconti prodotti, in una sottocartella dedicata. L'esame critico non ha potuto confrontare il richiesto con il realizzato se non su sei casi, ricostruiti da fonti di parte, perché di incarichi e resoconti non resta traccia. Predisponi la sottocartella e collocavi questo incarico come primo elemento.

## Il tocco diretto

Le caselle di entrambe le griglie rispondono all'attivazione del servizio di accessibilità e non a un tocco diretto sullo schermo. Il difetto è noto, registrato e mai corretto, e ha due conseguenze: chi usa il gioco senza tecnologia assistiva non può toccare nulla, e nessuna prova automatica può esercitare il gioco, perché una prova d'interfaccia tocca a dito e non attiva elementi accessibili.

Correggi su entrambi i piani insieme, mappa di campagna e griglia di battaglia, poiché il meccanismo è lo stesso e correggerne uno solo lascerebbe i due piani divergenti.

Il requisito è che ogni elemento interattivo risponda sia al tocco diretto sia all'attivazione da tecnologia assistiva, producendo il medesimo effetto e il medesimo annuncio, e che il percorso di codice sia uno solo. Il documento 02 §2.11 stabilisce che nessuna informazione sia raggiungibile soltanto per esplorazione al tatto e nessuna soltanto a scorrimenti: la simmetria vale anche qui.

Riproduci prima e correggi poi: la prova che deve fallire sul codice attuale è un tocco diretto su una casella che non produce l'effetto che l'attivazione accessibile produce. Verifica che il comportamento del fuoco resti quello prescritto, cioè che non si sposti mai in modo non richiesto, perché è il requisito che si rompe più facilmente e più silenziosamente quando si tocca lo strato degli eventi.

Verifica infine che nessuna prova esistente passasse solo grazie al comportamento vecchio.

## L'impianto di prova sul simulatore

Costruisci un impianto di prove d'interfaccia che eserciti il gioco attraverso l'interfaccia reale sul simulatore, cioè che tocchi, legga ciò che l'interfaccia espone, e verifichi.

Oggi le due prove d'interfaccia esistenti non esercitano il gioco, e lo dichiarano nei propri commenti. L'impianto nuovo le sostituisce nel ruolo.

Il servizio di accessibilità con sintesi vocale non è disponibile in questo ambiente, e non va simulato né finto: ciò che l'impianto può verificare è quanto segue, e questo va verificato.

Che ogni elemento interattivo esista, sia raggiungibile, e porti nome, ruolo, valore e azioni.

Che l'ordine di lettura dichiarato sia quello effettivo, elemento per elemento, e non dedotto dalla geometria.

Che il fuoco non si sposti mai in modo non richiesto dopo un'azione, in nessuna delle schermate.

Che ogni etichetta esposta sia completa e priva di segnaposto irrisolti o di chiavi di testo non risolte.

Che nessuna schermata si blocchi, e che da ogni schermata si possa tornare indietro.

Che l'annuncio prodotto dall'interfaccia coincida con quello che il motore prescrive per quello stato, cioè che i due piani non divergano.

Che una partita giocata dall'inizio alla fine attraverso l'interfaccia produca lo stesso stato del motore che produce la medesima sequenza di comandi applicata direttamente. È la verifica più importante dell'impianto, perché è l'unica che colleghi ciò che il giocatore fa a ciò che il gioco è.

Dichiara esplicitamente, in un punto del documento di collaudo, che cosa questo impianto non può verificare: la comprensibilità di una frase, l'orientabilità di una mappa, e ogni giudizio che richieda l'ascolto. Quelle restano nell'elenco delle verifiche possibili solo su dispositivo e non vanno mai dichiarate coperte.

## Le partite simulate

Estendi il programma di verifica perché generi e giochi diverse centinaia di sessioni complete, di campagna e di battaglia, in modo deterministico e riproducibile, e non soltanto giornate isolate come oggi.

Una sessione di campagna è una campagna condotta dal primo giorno fino a un criterio di arresto dichiarato. Una sessione di battaglia è uno scontro condotto dallo schieramento alla conclusione. Le sequenze vanno generate su tutta l'estensione dei parametri disponibili, non su configurazioni comode: tutti i formati di mappa, il numero di gruppi da uno al massimo consentito, disposizioni raccolte e disperse, e per le battaglie le composizioni di mazzo che i copioni esistenti non producono.

Gli invarianti già sorvegliati vanno applicati a tutte le sessioni generate. Ciascuno conserva il proprio mutante, e la prova che pretende l'esistenza di un mutante per ciascuno non va indebolita: è il presidio che impedisce alla copertura di restringersi in silenzio.

Aggiungi gli invarianti che soltanto una sessione completa può violare, cioè quelli che riguardano l'accumularsi dello stato e non il singolo passo. Individuali tu e dichiara il criterio con cui li hai scelti.

Fa' passare almeno una parte delle sessioni generate attraverso l'interfaccia anziché direttamente per il motore, se il costo in tempo lo consente. Sono le uniche prove del progetto che percorrerebbero l'intera catena. Se il costo non lo consente, dichiara la misura del costo e quante sessioni sarebbero sostenibili.

Ogni numero destinato al resoconto proviene dal blocco di riepilogo stampato dal programma, e i totali sono sommati dal programma con una prova che li pareggia con le righe di dettaglio.

## Che cosa non devi fare

Non estendere il perimetro del gioco: nessuna marcia di più giorni, nessuna revoca, nessuna marcia forzata, nessun rifornimento, nessuna stagione, nessun avversario sulla mappa, nessuna risoluzione di fine giornata, nessun passaggio dalla campagna alla battaglia. Questa sessione costruisce strumenti e chiude cancelli.

Non intervenire sul corpo a corpo.

Non tarare alcun valore.

Non riscrivere i documenti di progetto. Le sole modifiche documentali ammesse sono la correzione della riga errata della memoria di infrastruttura, la correzione della riga 219 dello stato dell'avanzamento, la rigenerazione della nota per il titolare, e le annotazioni nei registri.

Non simulare il servizio di accessibilità né dichiarare verificato ciò che richiede l'ascolto.

Non toccare la versione di marketing. Non creare bersagli firmabili, identificatori di pacchetto o profili nuovi. Non creare, revocare o modificare alcun certificato.

## Vincoli non rinegoziabili

La carta dei principi prevale su tutto, e al suo interno prevale il numero più basso. Il principio 1 prevale su qualunque altra considerazione.

Nessuna stringa nel codice e nessun numero di gioco fuori dai file di dati.

Ogni prova è intestata alla regola numerata che verifica. Il collaudo dei confini fra i moduli resta attivo.

Riproduci prima, correggi poi: per ogni difetto una prova che fallisca sul codice attuale, e la correzione è compiuta quando quella prova passa.

Ogni controllo introdotto in questa sessione va visto fallire almeno una volta prima di essere considerato attivo. Un cancello che non si è mai visto rifiutare non è un cancello.

Prima di adottare alternative a quanto stabilito, consulta il registro delle decisioni architetturali.

Lavora sul ramo dedicato e porta sul ramo principale soltanto ciò che è completo e verde.

Piena delega e nessuna domanda fino al resoconto finale, salvo credenziali mancanti e operazioni che potrebbero incidere su certificati esistenti.

## Il caricamento

Se le sezioni 3, 4 e 5 sono chiuse e l'intero insieme delle prove è verde, carica la build e verifica per interfaccia di programmazione che risulti valida, sul treno più alto e assegnata al gruppo di test. La sezione 6 non è condizione per il caricamento. Se una fra le sezioni 3, 4 e 5 resta aperta, non caricare e dichiara che cosa manca.

## Al termine

Resoconto in registro tecnico, con nomi reali di file, tipi, funzioni, prove e identificativi di commit, senza semplificazioni per lettori non tecnici e senza preamboli. Ogni affermazione fattuale porta il proprio riferimento verificabile; quelle che non lo portano vanno marcate come non verificate nel punto in cui compaiono. Nessun numero preso dalla memoria.

Deve riportare: i tre cancelli introdotti, con la prova che ciascuno è stato visto rifiutare e in quale condizione; che cosa il cancello sulla nota per il titolare verifica e che cosa resta fuori dalla sua portata; la causa per cui gli elementi non rispondevano al tocco diretto, la correzione, e la prova che falliva prima; l'esito della verifica sul comportamento del fuoco dopo l'intervento e se qualche prova esistente dipendesse dal comportamento vecchio; la composizione dell'impianto d'interfaccia, che cosa verifica ciascuna prova e a quale requisito è intestata, e l'enunciato esplicito di ciò che non può verificare; il numero di sessioni complete generate per campagna e per battaglia, l'estensione dei parametri coperti, gli invarianti aggiunti con il criterio della loro scelta, e l'esito; se e quante sessioni siano passate per l'interfaccia e a quale costo in tempo; versione, numero di build e stato su App Store Connect.

Non porre domande prima di quel momento.
