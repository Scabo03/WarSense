Resoconto — L'avversario, la ricognizione e l'informazione incompleta (incarico 17)

> Incarico grande in cinque blocchi, con ordine interno imposto: stati di conoscenza → avversario → ricognizione → formazioni non armate → imboscate. L'incarico stesso prevede che ci si fermi al confine di un blocco, verde, senza lasciare parti a metà. **Questa sessione ha costruito il blocco 1 (gli stati di conoscenza), la fondazione su cui tutto il resto poggia, e si è fermata lì.** Non ha caricato la build, perché il blocco 1 da solo non rende giocabile nulla di nuovo (non c'è niente da scoprire finché l'avversario non esiste), e il caricamento esige un blocco giocabile.

## Le frasi vere che il giocatore sentirà

Termini risolti dal vocabolario chiuso già riservato (`conoscenza.*`), col plurale di sistema per «avvistato».

Scoprendo una casella. Attivando una casella lontana, mai raggiunta dalle proprie formazioni, il giocatore sente per prima cosa, dopo la testa fissa «riga N, casella M», lo stato di conoscenza: «inesplorato». Attivando una casella entro il raggio di una propria formazione, quella è confermata e lo stato NON si annuncia — la certezza è la condizione ordinaria e tace (02 §3.8.1). Allontanando le formazioni, una casella già vista ma non più osservata, passato il tempo, dichiara «avvistato, N turni fa»: l'età vera dell'informazione, col plurale («un turno fa» / «N turni fa»). Il quarto stato, «presunto», ha il suo termine ma non si produce ancora: nascerà dalla deduzione dell'itinerario avversario (01 §5.10.1, blocco della ricognizione).

Che cosa l'avversario cerca di fare. NON REALIZZATO in questa sessione: l'avversario (blocco 2) non è costruito. Non c'è ancora nessuno che si muova, e perciò nessun comportamento da descrivere. Il blocco 1 prepara soltanto l'occhio con cui lo si vedrà.

## Blocco 1 — Gli stati di conoscenza (RDA-110)

Commit sul ramo `incarico-17-avversario-conoscenza`, fuso su `principale`.

Il modello. `StatoConoscenza` (inesplorato, presunto, avvistato coi turni, confermato) NON è un campo grezzo: si deriva dall'ETÀ dell'informazione — i turni dall'ultima osservazione — con `StatoConoscenza.da(eta:sogliaConfermato:)`. La memoria è PER PARTE (`StatoCampagna.conoscenza: [Parte: [Cella: Int]]`), perché l'agguato dipende dal fatto che una casella non sia confermata per l'AVVERSARIO (01 §5.11.1) e l'avversario decide sulla propria conoscenza: la simmetria è voluta. La memoria non entra nel giornale (si ricostruisce rigiocando, sicché lo schema resta 4 e i salvataggi restano compatibili) ma entra nell'impronta.

L'osservazione e il decadimento. La conoscenza CORRENTE — ciò che una formazione vede ora entro il raggio — si deriva dalle posizioni (`MotoreCampagna.conoscenza`/`osservata`): osservata ora = confermata. La memoria conserva solo ciò che non si osserva più e invecchia a ogni fine giornata (`invecchiaLaConoscenza`, nuovo passo di `risolviFineGiornata`, che colma il segnaposto già presente): ogni ricordo sale di un turno, poi le caselle osservate a fine giornata tornano a zero. Oltre la soglia il confermato decade in avvistato (03 §4.8.1). Raggio e soglia vengono dai dati (`conoscenza-campagna.json`, provvisori: raggio 1, soglia 2).

Il gioco non dichiara il falso (01 §12). La conoscenza è la prima voce di casella se diversa da confermato (02 §3.8.1), con l'età; il terreno resta geografia nota (la mappa si conosce), sicché il blocco 1 non nasconde nulla: nasconderà le formazioni avversarie il blocco che le costruisce. Due invarianti col mutante — `conoscenza_regredita_senza_tempo` (la memoria cambia solo alla chiusura della giornata) e `conoscenza_falsa` (nessuna età negativa, cioè conoscenza dal futuro). Quattro prove nuove del Motore (`ConoscenzaTest`).

## I numeri, dal programma di verifica e dal collaudo

- **invarianti_sorvegliati: 31** (erano 29; +`conoscenza_regredita_senza_tempo`, +`conoscenza_falsa`).
- **violazioni_trovate_in_totale: 0**.
- Collaudo completo verde: `swift test` 307 prove (0 fallite, 1 saltata); `collaudo-completo.sh` con le prove ospitate e d'interfaccia, 73 passate, 0 fallite. La modifica dell'annuncio (lo stato di conoscenza in testa alla casella) non rompe le prove d'interfaccia, che confrontano per contenimento e per prefisso, non per uguaglianza esatta.

## Ambiguità segnalate (prima di cominciare)

Segnalate nell'analisi iniziale, con la lettura scelta (le regole 03 §4.8 dichiarano queste grandezze e ne rimandano il numero alla realizzazione):
1. Raggio di osservazione (03 §4.8.2, deferito): regola minima e deterministica, raggio dai dati, provvisorio.
2. Decadimento (03 §4.8.1): realizzato il timer confermato→avvistato; NON inventato un timer avvistato→inesplorato (non specificato); il presunto rinviato alla deduzione §5.10.1.
3. Conoscenza per parte, per la simmetria dell'agguato (§5.11.1).
4. Turno avversario e giornale (§5.6.11): la predisposizione esiste (tutta la catena è già chiavettata su `Parte`), da usare nel blocco 2 senza costruire una seconda forma.
5. Carattere dell'avversario (03 §6.5.2): sdoppiamento campagna/battaglia rinviato, da introdurre col blocco 2.

## Ciò che l'incarico chiedeva e non è stato fatto (i blocchi 2–5)

Fermata dichiarata al confine del blocco 1. Restano, nell'ordine imposto:
- **Blocco 2 — l'avversario.** La predisposizione è pronta: `SessioneCampagna.esegui(_, parte:)` → `giornale.appendi(.comandoCampagna(parte:, comando:))` → `motore.valida/applica(..., parte:)` sono già chiavettati su `Parte`. Serve: (a) filare `parte` nei due punti che oggi fissano `.giocatore` (`MotoreCampagna.costoInGiorni:249`, e la creazione dei gruppi in `FabbricaCampagna.crea`); (b) far dichiarare allo scenario i gruppi avversari (`ScenarioCampagna` con un `gruppiAvversario` opzionale omesso-se-vuoto, come `forzeNemiche`); (c) la condotta deterministica (propensioni e valutazioni, nessun caso — 01 §12, §14.3: propensione_attacco/imboscata/accerchiamento, tolleranza_perdite, propensione_ritirata, nei dati col contrassegno di provvisorietà, carattere di campagna forse sdoppiato — 03 §6.5.2); (d) l'integrazione del turno: quando tutti i gruppi del giocatore hanno concluso, i gruppi avversari agiscono in ordine fisso, i loro comandi si appendono al giornale, poi la giornata si chiude (§5.6.11) — è il punto più delicato (giornale, riproduzione, confine dell'annullamento §5.6.11); (e) l'occultamento: le formazioni avversarie si annunciano solo dove note (conoscenza avvistato/confermato), invariante «nessuna informazione avversaria se non dagli stati di conoscenza e dal registro»; (f) banco che genera partite intere contro l'avversario, con tagli davvero prodotti dalle sue mosse.
- **Blocco 3 — la ricognizione.** Terza categoria (formazioni di ricognizione), azione di esplorazione, rischio DETERMINISTICO (competenza/distanza/presenza nemica — 03 §4.8.4; il caso resta confinato a meteo e guasti, §12); osservazione dei movimenti e deduzione dell'itinerario (§5.10.1 → presunto); non soggette al taglio.
- **Blocco 4 — le formazioni non armate.** Terza categoria non armata; sabotaggio (§5.10.2, riesce sempre se armato, se esploratori solo oltre la soglia di protezione, altrimenti si fanno notare) e studio approfondito (porta a confermato). Nessuna battaglia (§5.4.1).
- **Blocco 5 — le imboscate e l'aggiramento.** Ordine di imboscata (stato «in agguato», già nel vocabolario), scatto a fine giornata (`scattaLeImboscate`, segnaposto già presente in `risolviFineGiornata`); registrazione del vantaggio (§9.3.2) dichiarando che il passaggio alla battaglia lo raccoglierà; aggiramento (sfilarsi in caselle adiacenti senza ingaggio).

Categoria delle formazioni: aggiungere `categoria` a `Gruppo` e a `GruppoIniziale` (opzionale omesso-se-armato, per non muovere il campione del giornale) serve dal blocco 3; il blocco 2 può cavarsela con soli gruppi armati.

## Perché non si è caricato, e la versione

Il blocco 1 cambia l'annuncio della casella (nebbia di guerra) ma non aggiunge nulla di SCOPRIBILE: senza avversario, andare su una casella «inesplorato» non rivela niente (il terreno è geografia nota). Non è «qualcosa di nuovo giocabile» nel senso che l'incarico intende, e perciò non si carica (la condizione del caricamento è esplicita). La build viva sui tester resta la 21. La versione dei valori NON è salita (resta 0.9.0), benché sia stato aggiunto `conoscenza-campagna.json`: la sessione che chiuderà l'avversario — il primo blocco giocabile — incrementerà la versione dei valori per tutti i numeri di campagna introdotti da allora, questi due compresi. Nessuna versione toccata di propria iniziativa (regola del titolare).

## Da dove si riprende

Ramo `principale`, col blocco 1 fuso. La prossima sessione branca da `principale` e costruisce il blocco 2 (l'avversario) sulla predisposizione descritta sopra, poi carica appena l'avversario si muove ed è giocabile. La memoria di conoscenza per parte è già pronta a sostenere l'occultamento e l'agguato.

## Non verificato, dichiarato

- L'effetto reale su chi ascolta della nebbia di guerra (l'annuncio «inesplorato»/«avvistato, N turni fa») con VoiceOver su dispositivo non è provato: è verificato il contenuto e il percorso nel Motore e nelle prove ospitate sul simulatore, non l'ascolto su ferro. Non è comunque sui tester (build 21, senza blocco 1).
- I due valori (raggio 1, soglia 2) sono scelte provvisorie non tarate: nessuna simulazione le giustifica ancora, perché senza avversario non c'è banco che eserciti la conoscenza in modo significativo.

## Tempi (wall-clock del flusso, ordini di grandezza)

- Analisi iniziale (lettura dei consolidati 01 §5.2–5.13, §12, §14; 02 §3.8.1, §4.2, §7.3; 03 §4.8, §6.5; e della predisposizione dell'avversario nel codice), condotta con tre esplorazioni in parallelo: la parte più lunga prima di scrivere codice, ed è servita a segnalare le ambiguità e a trovare la predisposizione dell'avversario.
- Blocco 1: modello, valori, osservazione e decadimento, impronta, vocabolario, annuncio, invarianti, prove.
- Collaudo del pacchetto ~47 s (307 prove); collaudo completo col simulatore ~6 minuti, eseguito una volta a fine blocco.
- Caricamento: nessuno (blocco non giocabile da solo).
