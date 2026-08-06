# Valori provvisori in attesa di taratura

Documento di lavoro della fase 5. Ogni numero introdotto per far funzionare il codice, in attesa della taratura con le simulazioni. Un valore provvisorio che non risulti da questo elenco è un difetto (incarico fase 5, sezione 3). Nessun numero di gioco vive nel codice: tutti stanno nei file di `Codice/Sources/Contenuti/Valori/`.

Convenzione: PROVVISORIO = da tarare con le simulazioni o da fissare in sede di definizione dei valori; FISSATO = deciso dai consolidati, non si tocca qui; TARATO = non più provvisorio, perché una misura del programma di verifica lo giustifica, con il rinvio alla misura.

Dalla fase C esiste il programma di verifica: `swift run StrumentoVerifica`. Un valore si toglie da questo elenco soltanto quando una sua misura esiste ed è riportata nel documento 03; non si toglie mai perché è parso ragionevole.

## archetipi.json — tutti PROVVISORI

Tutti i parametri dei nove archetipi: punti vita per atomo, capacità offensiva per atomo, gittata utile unica, volume per atomo, penalità di avanzamento, soglia di disingaggio, sensibilità alla stanchezza, dotazione munizioni, proiettile fisso e profili di offesa (mischia e tiro). Corrispondono a 03 §5.1, §5.4, §5.6, §5.7, §5.8 e 01 §3.4 (versione 3.3). Con la gittata unica (01 §3.4.1 v3.3) la gittata di ciascun tiratore è l'ex gittata di disturbo con resa piena (tiratori 6, piattaforma 4, macchina da tiro 8): PROVVISORIA, da tarare secondo 03 §6.4 ridefinita perché il tiro non domini distanze eccessive. Proiettili fissi assegnati (01 §3.3.1 v3.3): tiratori e piattaforma → leggero, macchina da tiro → pesante — PROVVISORI in attesa dei tratti (01 §3.3).

## offese-e-protezioni.json — PROVVISORI

I quattro coefficienti dei due profili di protezione (para_saturazione/para_perforazione per tipo). Vincolo strutturale rispettato: risposte opposte ai due assi (01 §3.3.2). Corrisponde a 03 §5.4.

## formato-battaglia.json

- `budget_volume_base` (300 / 120), `coefficiente_primo_turno` (1.2): PROVVISORI — 03 §5.2, l'esempio 120:100 di 01 §9.3 è dichiarato non normativo.
- `quota_riporto` (0.1): FISSATO — dieci per cento, 01 §9.3.3.
- `righe_di_piazzamento` (3 sul cento, 2 sul quindici): FISSATO — 01 §8.2.1.
- `righe_soglia_ritirata` (2 sul cento): FISSATO dall'esempio normato di 01 §10.3 (riga 8 su 10); 1 sul quindici: PROVVISORIO.
- `coefficiente_spostamento_doppio` (1.8): PROVVISORIO — 03 §5.3.
- `turni_vantaggio_imboscante` (3): PROVVISORIO — 03 §5.9, da tarare con 03 §6.6.
- `sconto_imboscante` (0.3): PROVVISORIO nell'ordine indicato dal titolare (trenta per cento, 01 §9.3.2); la misura esatta è di 03 §5.9.
- `soglia_minima_resa_turni` (4 / 3) e `accorciamento_resa_per_perdite` (0.5): PROVVISORI — grandezza critica 03 §6.1.

## combattimento.json — PROVVISORI

- `efficacia_minima` (0.15): frazione della munizione poco adatta, 03 §5.5.
- `soglia_poco_efficace` (0.5): confine dell'annuncio qualitativo, 01 §9.9.1.
- `fascia_perdite_lievi_fino` (0.10) e `fascia_perdite_significative_fino` (0.30): soglie delle fasce descrittive degli esiti (01 §9.7.2, 03 §5.14), proporzione del danno sulla consistenza del colpito prima dell'applicazione; sopra la seconda le perdite sono gravi, a zero nessuna perdita. PROVVISORIE, da riesaminare con i ritorni dei tester (RDA-52).
- `resa_tiro_al_limite` (0.7) e `resa_tiro_alla_minima_distanza` (2.4): i due estremi della curva del tiro (01 §9.10.1, 03 §5.15). TARATI in fase C — sostituiscono `maggiorazione_vicinanza_massima` (0.6), che non riduceva mai al limite. Misura: 03 §10.3 e §5.15.1. Criterio: contro un bersaglio ben scelto le perdite vanno da LIEVI al limite della gittata a GRAVI alla minima distanza; con i valori precedenti restavano significative a ogni distanza e la fascia annunciata non cambiava mai.
- `fascia_vicinanza_lontano_fino` (0.33) e `fascia_vicinanza_ravvicinato_fino` (0.66): soglie delle tre fasce descrittive della vicinanza, sulla prossimità che vale zero al limite della gittata e uno alla minima distanza (01 §9.10.1, 02 §4.4.5, 03 §5.15). PROVVISORIE: divisione in terzi, scelta perché con la gittata sei dei tiratori assegna due distanze a ciascuna fascia.
- `passo_accerchiamento` (0.08): passo della maggiorazione, composto col quadrato dei concorrenti eccedenti il primo (01 §9.10.2, 03 §5.16). Ne risultano 1,08 con due concorrenti, 1,32 con tre e 1,72 con quattro. TARATO in fase C, era 0.15. Misura: 03 §10.4 e §5.16.1, spazzata su sette valori. Criterio: tre assalitori non devono annientare in un solo giro, quattro possono; banda ammessa 0.04–0.12, scelto il punto di margine maggiore.
- `concorrenti_massimi` (4): tetto dei concorrenti conteggiati (01 §9.10.2, 03 §5.16). PROVVISORIO: il criterio della spazzata non lo tocca, perché a quattro assalitori il bersaglio cade comunque nel primo giro e il tetto non si distingue.
- `resa_contro_secondo_bersaglio` (0.5): il malus del secondo bersaglio, espresso come resa conservata (01 §9.11, 03 §5.17). Contro il primo la resa è piena, dal terzo non c'è risposta: non esistono altre voci, perché il numero massimo di nemici cui si risponde è una regola e non un valore. PROVVISORIO: nessun banco lo isola ancora, perché il suo effetto si vede solo dentro la progressione dell'accerchiamento, dove si somma al passo. Vincolo di validazione: strettamente fra zero e uno.

## caratteristiche-campo.json

- `campo_aperto` senza modificatori: neutro per costruzione.
- `terreno_rotto` con `coefficiente_costo_movimento` 1.3: PROVVISORIO — 03 §5.12.

## minimi.json — FISSATI

Tutti a 1, come impone 00 §13.6 (minimo di uno dove il troncamento darebbe zero); l'elenco dei casi è 03 §8.2.

## ufficiali.json — due parametri TARATI, tre PROVVISORI

- `ufficiale_prova.tolleranza_perdite` (0.4, era 0.5) e `propensione_ritirata` (0.8, era 0.5): TARATI in fase C. La soglia di resa è la prima divisa per la seconda e valeva l'unità intera, cioè la perdita di TUTTE le forze impiegate: irraggiungibile, e nessuna battaglia poteva chiudersi per resa. Ora vale mezzo. Misura: 03 §6.5.1 e §10.6.
- `ufficiale_prudente.propensione_attacco` (0.6, era 0.3): TARATO in fase C. Sotto la metà il tattico non avanza né ingaggia mai: due prudenti contrapposti restavano immobili e un quarto delle configurazioni non concludeva. Misura: 03 §6.5.1.
- Restano PROVVISORI: `tendenza_accerchiamento`, `propensione_imboscata` per entrambi, e `tolleranza_perdite`/`propensione_ritirata` del prudente. Nessun banco li misura ancora: imboscata e accerchiamento dell'avversario chiedono scenari che la fase D fornirà (03 §6.5.2).

## vantaggi-nascosti.json

- Ritirata avversaria dalla sola ultima riga: FISSATO — 01 §13.2.
- Riduzione della propensione alla ritirata avversaria (0.6, era 0.3): TARATA in fase C. Con 0.3 la soglia di resa dell'avversario superava il triplo delle forze impiegate: il vantaggio non rendeva rara la ritirata avversaria, la rendeva impossibile, che non è ciò che 01 §10.7 chiede. Con 0.6 vale poco più di otto decimi: rara e possibile. Misura: 03 §7.4.1 e §10.2.
- `annientamento_simultaneo_al_giocatore` (vero): FISSATO — 01 §15.2.5, decisione del titolare. Non è una misura ma un interruttore: acceso, sconfitto è l'avversario; spento, l'esito torna al giocatore ed è la forma in cui la Verifica misura il caso reale (05 §12.5, RDA-57).

## scenari.json — composizioni TARATE, il resto PROVVISORIO

Composizioni dei due mazzi: TARATE in fase C (03 §5.18.1, misura §10.5). La fanteria pesante di entrambe le parti porta ora protezione anti-saturazione; la differenza fra i mazzi sta nelle protezioni miste degli altri reparti. I punti vita esposti a un tiro efficace passano da 1400 contro 2300 a 400 contro 500, e la frequenza di vittoria a vantaggi spenti da sette contro uno a quattro contro quattro. Restano PROVVISORI ostacoli, taglie degli sciami e ufficiale assegnato.

## Scenari del programma di verifica (Contenuti/Scenari) — PROVVISORI

Tetti dei giri, assi dichiarati e soglie di accettazione dei tre scenari di misura. Non sono valori di gioco: cambiarli cambia la misura, non il gioco. La soglia dichiarata è lo scarto massimo fra le vittorie a vantaggi spenti, a 250 per mille per tutti e tre; con otto configurazioni la granularità è di 125 per mille e una soglia più stretta sarebbe soddisfacibile solo dal pareggio esatto (03 §10.9). Lo stesso vale per `banchi.json`, che dichiara le condizioni pari dei banchi controllati.

## aptica.json e suoni.json

Intensità, nitidezze e tempi dei pattern e suoni generati: PROVVISORI come resa, FISSATA la struttura (famiglie ritmiche e assegnazioni di 02 §11.7.1). Da raffinare con i ritorni dei tester.

## Soglia del tattico (formula, non numero)

La soglia di resa del tattico è tolleranza alle perdite divisa per la propensione effettiva alla ritirata: struttura nel codice, numeri nei file (01 §12.1, RDA-46).

MISURA dall'accertamento sugli esiti degli scontri: con l'`ufficiale_prova` di fabbrica (tolleranza 0,5, propensione 0,5) la soglia vale 1,0 delle forze impiegate GIÀ SENZA il vantaggio nascosto, e 3,33 con esso. L'avversario non può quindi arrendersi in nessuna partita, e ogni battaglia si chiude per annientamento o per resa del giocatore. Non è il vantaggio nascosto a produrlo, sono i valori di carattere: la taratura di 03 §6.5 va condotta sapendolo, e il rapporto tolleranza/propensione va portato sotto l'unità perché la resa avversaria sia raggiungibile. Registrato anche in 03 §7.4. Prova che lo fissa: `AccertamentoScontriTest.test_01_13_2_peso_misurato_della_propensione_alla_ritirata_ridotta`.

## Numeri di struttura (non di gioco, quindi nel codice per 05 §0.4)

- Fattore di scala della virgola fissa: 1000 (`Scalato.fattore`, RDA-44).
- Passo delle istantanee: 200 righe di giornale (05 §6.2, dichiarato numero di struttura).
- Versione dello schema del giornale: 2 (`Fondazione.schemaCorrente`; la 2 dalla prima tranche di semplificazioni: il comando di tiro non trasporta più il proiettile).

## Valori della campagna — prima unità della fase D

Questa unità introduce POCHISSIMI numeri, ed è voluto: le grandezze della campagna — costo in giorni dello scatto, pesi della casella di partenza e di arrivo, costo fisso della strettoia, effetto del tipo di strada, autonomia, malus della marcia forzata e della mancanza di provviste, decadimento della conoscenza (03 §4.1–4.9) — appartengono tutte a unità successive e restano da determinare come il documento 03 le registra. Introdurne uno adesso, senza il codice che lo mette alla prova, significherebbe inventare un numero. UNA eccezione, aggiunta nella seconda unità: il costo in giorni dello scatto, che non è un numero nuovo ma il valore esplicito di ciò che il codice già faceva implicitamente, ed è iscritto qui sotto.

### marcia-campagna.json — PROVVISORIO

- `costo_giorni_base` (1): PROVVISORIO. È il costo in giorni dello scatto fra due caselle adiacenti (01 §5.6.3.1). Il valore uno realizza il CASO PARTICOLARE della prima unità e non è una regola: 01 §5.6.3.2 stabilisce che sulla medesima grandezza agiscano, in un solo numero e senza regole che si sommino in modo opaco, la natura della casella di partenza e quella di arrivo con pesi distinti, il volume della colonna, il tipo di strada e il costo fisso della strettoia. Nessuno di quei fattori esiste ancora; quando esisteranno, questa voce si scomporrà nei loro pesi e il costo cesserà di valere uno. Da tarare in sede di definizione dei valori, insieme al resto di 01 §16.3 («il costo in giorni dello scatto per tipo di terreno e di strada, con i pesi rispettivi della casella di partenza e di arrivo»). Il minimo di uno è FISSATO da 00 §13.6 e imposto dal caricatore. Decisione architetturale: RDA-75.

### formati-mappa.json — FISSATI

Le dimensioni dei tre formati: quattro per quattro, sei per sei, dieci per dieci. FISSATI da 01 §5.1, che li dichiara «tre formati fissi». Non sono taratura e non si toccano qui. Stanno nei dati e non nel codice perché il codice non deve conoscere alcuna dimensione, non perché siano da tarare.

Discrepanza aperta e non chiusa: 01 §5.14.5.1 nomina anche un formato otto per otto. Vedi il registro degli scostamenti, S5.

### Mappe/*.json — CONTENUTO, non valori

Terreni, strade, strettoie e posizioni dei quartier generali delle tre mappe di prova non sono valori di bilanciamento ma contenuto (05 §7.6, «le mappe sono contenuto, non codice»). Non si tarano: si disegnano. Le tre di questa unità servono a percorrere i tre formati e non pretendono di essere mappe definitive; ciascun fronte ne richiederà almeno cinque (01 §5.6.9).

### nomi-gruppi.json — CONTENUTO

Le dodici chiavi dei nomi dei gruppi. Non sono valori: sono l'elenco chiuso e prevedibile che 01 §5.6.0.4 richiede. Il numero dodici è la sola scelta, ed è capienza, non taratura: nulla impedisce di allungarlo, e la validazione respinge un elenco più corto del numero di gruppi che uno scenario chiede.

### Scenari/Campagne/campagne.json — PARAMETRI DI MISURA, non valori di gioco

`giornate_generate` (40) e `gruppi_per_la_misura_dei_passi` (da 1 a 8) governano quanto a lungo il programma di verifica generi giornate e su quali conteggi di gruppi misuri il costo di chiusura. Come i parametri dei banchi di scontro, non entrano in alcuna formula del Motore: cambiarli cambia la misura, non il gioco.

### Il modello dei passi — DICHIARATO, non tarato

La misura del costo di chiusura di una giornata usa un modello dichiarato in `BancoCampagna`: con il salto diretto ordinare un gruppo costa tre passi (salto, attivazione della casella, scelta della voce); senza il salto, al posto del salto occorrono gli scorrimenti che separano le due caselle nell'ordine di lettura. Non è un valore di gioco e non risiede nei file dei valori: è l'unità di misura, e come tale va discussa, non tarata. Se la prova su dispositivo mostrasse che il costo reale di un'operazione è diverso, si corregge il modello e si rilegge la misura.

### Sigle degli archetipi sulla tessera del deck — SEGNAPOSTO, non forma definitiva

Le sigle di una o due lettere mostrate al centro della tessera del deck sono il **segnaposto testuale** dei simboli grafici, che non esistono ancora (RDA-85, incarico 08). Stanno nei testi come `deck.sigla.<archetipo>`: in italiano FL, FP, GE, TR, CR, CM, PT, MA, MT; in inglese (pacchetto `en.lproj`, non ancora caricabile) LI, HI, EG, SK, RC, MC, TP, SE, AR. Sono decorazione visiva, escluse dall'albero accessibile e mai annunciate. **Provvisorie per costruzione**: un lavoro successivo le sostituirà con simboli grafici, e finché ciò non avviene nessuna sessione deve scambiarle per la forma definitiva. Le lettere non sono un valore di gioco — sono un'abbreviazione del nome dell'archetipo — e vivono nei file dei testi, non nel codice.

### Soglie di disingaggio a tre fasce, logoramento e secondo contatto — PROVVISORI (incarico 10)

Introdotti dall'incarico 10 dopo la misura del corpo a corpo (incarico 09), giustificati da una misura di separazione ma non ancora tarati sul gioco reale con i tester; restano PROVVISORI finché il titolare non li conferma provando le battaglie.

- `archetipi.json`, campo `soglia_disingaggio`, **tre fasce** (RDA-87): bassa **0,12** (`tiratori`, `piattaforma_trainata`, `macchina_tiro`); media **0,6** (`fanteria_leggera`, `cavalleria_ricognizione`, `cavalleria_manovrata`); alta **0,9** (`fanteria_pesante`, `macchina_assedio`). La chiave è ASSENTE per `guardia_elite` (reparto elitario, RDA-88): non è un valore, è l'assenza della soglia. Misura di separazione: `mischia_fasce` di `swift run StrumentoVerifica` dà mediana 1 / 4 / 8 scambi per bassa / media / alta.
- `combattimento.json`, `coefficiente_logoramento_soglia` = **0,5** (RDA-90): coefficiente della formula unica `sogliaDisingaggioEffettiva`. Zero lo disattiva. PROVVISORIO.

### Élite storiche e ripiego di banda (incarico 11)

- `archetipi.json`, `elite_fase` (RDA-92): élite antica `guardia_elite = antica`, élite arcaica `piattaforma_trainata = arcaica`, fondate sulla ricerca storica (fonti in RDA-92). Non sono numeri di taratura ma un'assegnazione storica; restano rivedibili dal titolare, non provvisori nel senso della taratura.
- `archetipi.json`, `guardia_elite.soglia_disingaggio` = **0,9**: banda di RIPIEGO per le fasi in cui la guardia d'élite non è élite. PROVVISORIA e non esercitata (`guardia_elite` è antica-solo per la ricerca, quindi sempre élite in gioco); il comportamento accettato in antica — soglia assente — è invariato.
- L'interruttore `soglia_al_secondo_contatto` è RIMOSSO (RDA-95, decisione del titolare): non è più un valore provvisorio.

La versione dei valori è salita a **0.7.0** (RDA-92): incremento dovuto, non discrezionale, perché cambia il reparto élite e il formato dello stato (campo `fase`), che incidono su come una partita in corso si svolgerebbe. (Era 0.6.0 dall'incarico 10, RDA-91.)
