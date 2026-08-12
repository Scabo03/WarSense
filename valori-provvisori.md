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

- `costo_giorni_base` (1): PROVVISORIO. Il costo base in giorni dello scatto fra due caselle adiacenti (01 §5.6.3.1). Con l'incarico 14 non è più il costo intero: vi si sommano i pesi qui sotto, e la stessa casella costa da uno a tre giorni secondo il terreno. Il minimo di uno è FISSATO da 00 §13.6 e imposto dal caricatore. Decisione architetturale: RDA-75, RDA-99.
- `peso_terreno_partenza` (aperto 0, bosco 1, acqua 1): PROVVISORIO. Il peso della natura della casella DI PARTENZA (01 §5.6.3.2). Scelti così: il terreno aperto è la condizione ordinaria e non aggiunge nulla; lasciare un bosco o un guado costa un giorno in più, perché districarsi dal fondo difficile rallenta la partenza quanto l'arrivo lo rallenta. Da tarare giocando (01 §16.3).
- `peso_terreno_arrivo` (aperto 0, bosco 1, acqua 2): PROVVISORIO. Il peso della natura della casella DI ARRIVO, distinto da quello di partenza perché il costo grava sul tragitto reale (01 §5.6.3.2). Entrare nell'acqua è il più oneroso (due giorni in più), entrare in un bosco uno; l'aperto nulla. I pesi di partenza e di arrivo NON sono uguali: entrare in una casella pesa più che lasciarla.
- `peso_strada_arrivo` (nessuna 0, sterrata 0, battuta -1, lastricata -1): PROVVISORIO. L'effetto del tipo di strada della casella di arrivo (01 §5.5.3, §5.14.4). Le strade ACCORCIANO il tempo: la battuta e la lastricata tolgono un giorno, la sterrata non ancora (da distinguere in taratura), nessuna strada nulla. Il costo non scende comunque sotto uno (saturazione nel Motore, 00 §13.6): una strada su terreno aperto resta un giorno, una strada che attraversa l'acqua — il guado — dimezza la fatica dell'acqua. Da tarare giocando.
- `costo_strettoia` (1): PROVVISORIO. Il costo fisso aggiuntivo dell'attraversare la strettoia (01 §5.1.3, §5.6.3.2), applicato quando la casella di arrivo è la strettoia. Un giorno in più. Da tarare.
- `posizioni_visive` (9): FISSATO da 01 §5.6.3.4, che stabilisce «nove posizioni disposte a quadrato dentro la casella». Non si tara: è geometria del progetto. Vive nei dati e non nel codice perché nessun numero di gioco vive fuori dai file (00 §13.1).
- `soglia_volume_per_giorno_aggiuntivo` (250): PROVVISORIO. Il volume oltre il quale la colonna spende un giorno in più (01 §5.6.3.2, quinto fattore); i giorni aggiuntivi sono il volume del gruppo diviso questa soglia, per troncamento. Formula nel codice (`MotoreCampagna.costoInGiorni`), coefficiente qui (00 §13.1). Scelta così che le tre composizioni di misura — 60, 292, 696 di volume — diano rispettivamente zero, uno e due giorni aggiuntivi, cioè una gamma osservabile. Il minimo di uno è FISSATO (è un divisore) e imposto dal caricatore. Da tarare giocando (01 §16.3). Introdotto con l'incarico 15 (composizione e volume); decisione architetturale RDA-103.

Il VOLUME della colonna, quinto fattore di 01 §5.6.3.2, con l'incarico 15 AGISCE: `MotoreCampagna.costoInGiorni` legge il volume del gruppo che occupa la casella di partenza — somma sui reparti di atomi per `volume_per_atomo`, la STESSA grandezza del volume di battaglia (01 §3.4.4) — e vi somma il volume diviso la soglia qui sopra, senza spostare il punto di calcolo (RDA-75, RDA-99, RDA-103). Il rinvio di `impatto-marcia-lunga.md` §1 è così superato.

### Rifornimento (incarico 16) — NESSUN valore nuovo, e il perché

L'incarico 16 realizza la catena, il taglio, le zone, l'autonomia e la sosta (01 §5.2.2), e NON introduce alcun numero di gioco. È voluto e coerente col rinvio di sopra: la MAGNITUDINE del malus della mancanza di provviste (di quanto scendano punti vita e capacità offensiva del reparto) e l'AUTONOMIA (i giorni di viveri portati) restano da determinare come il documento 03 le registra, e introdurle senza il codice di battaglia che le mette alla prova significherebbe inventare numeri. Ciò che questa unità realizza è la MECCANICA, non i suoi pesi:

- Il numero massimo di turni senza provviste (2) e di sosta dovuta (2) NON sono valori da tarare: sono la regola di 01 §5.2.2.4 («oltre il secondo turno non si prosegue», «la sosta imposta è di due turni»), fissati, imposti dagli invarianti `rifornimento_fuori_intervallo` e sorvegliati.
- Il raggio della zona (distanza di Čebyšëv al più uno, cioè le nove caselle) è geometria della regola (01 §5.2.2.6), non un valore.
- Il malus del digiuno agisce sui PARAMETRI del reparto (punti vita, capacità offensiva) e MAI sul volume: il campo `turniSenzaProvviste` è predisposto e conta i turni, ma la sua traduzione in una riduzione dei parametri è materia dell'unità che congiungerà campagna e battaglia. Predisposto, non alimentato, come `turniMarciaForzata`.
- Le `forze_nemiche` e le `strutture_di_rifornimento` negli scenari di `campagne.json` sono CONTENUTO (dati minimi per provare taglio e zona), non valori da tarare, come le posizioni dei gruppi.

La versione dei valori NON sale (resta 0.9.0): nessun file di `Contenuti/Valori` cambia, e una campagna in corso, riaperta con questa build, si comporta ESATTAMENTE come prima, perché in gioco reale `forzeNemiche` e `struttureDiRifornimento` sono vuote (l'avversario e le opere non sono costruiti) e nessun gruppo risulta mai tagliato. Lo schema del giornale resta 4 e i salvataggi restano compatibili (RDA-107). La regola del titolare è rispettata: le versioni non si toccano di propria iniziativa, sale solo il numero di build.

### conoscenza-campagna.json — PROVVISORI (incarico 17, blocco 1)

Gli stati di conoscenza (01 §5.3, RDA-110). Due numeri, entrambi dichiarati e rimandati dal documento 03 alla realizzazione, ora introdotti col contrassegno di provvisorietà:

- `raggio_osservazione` (1): il raggio in caselle (distanza ortogonale) entro cui una formazione conferma la conoscenza — uno significa la propria casella e le adiacenti. PROVVISORIO (03 §4.8.2, che rimandava il raggio di osservazione dei gruppi alla realizzazione). Da tarare con la portata degli esploratori, quando esisteranno.
- `soglia_confermato_in_avvistato` (2): i turni dopo i quali il confermato decade in avvistato (03 §4.8.1). PROVVISORIO; il vincolo di direzione del documento 03 è che il decadimento «morda, perché la certezza resti rara»: due turni è una scelta che morde presto, da rivedere giocando. Almeno uno, o il confermato decadrebbe nel turno stesso in cui si osserva (imposto dal caricatore).

La versione dei valori NON è ancora salita in questo blocco (resta 0.9.0), perché il blocco 1 non è caricabile da solo: non c'è nulla da scoprire finché l'avversario non esiste. La sessione che chiude un blocco giocabile (l'avversario che si muove) incrementerà la versione dei valori per tutti i numeri di campagna introdotti da allora, questi due compresi.

### condotta-campagna.json — PROVVISORI (incarico 18, l'avversario)

Il CARATTERE dell'avversario di campagna (01 §12.1, §14.3, RDA-111): i pesi da cui discendono le sue scelte, tutti nei dati e nessuno nel codice (00 §13.1). Nessuno è un tiro di dado: sono i coefficienti di una valutazione deterministica. L'ORDINE del comportamento è quello dei pesi in diminuzione, ed è ciò che il titolare deve poter leggere guardando l'avversario giocare.

- `difesa_quartier_generale` (600): peso della difesa del proprio quartier generale quando una formazione nota del giocatore vi è entro la soglia. Il più alto: minacciato il proprio quartier generale, ripiega a difenderlo. PROVVISORIO.
- `minaccia_rifornimento` (300): peso del mettersi ALLE SPALLE di una formazione nota, da dove se ne taglia il rifornimento (01 §5.2.2). PROVVISORIO.
- `aggressivita` (100): peso dell'avanzata verso il quartier generale del giocatore, aggirando le formazioni note; è la propensione a cercare lo scontro (01 §6.1.3). PROVVISORIO — è la manopola che 01 §6.1.3 dichiara decidere «molto più di prima» la frequenza degli scontri, da tarare con le simulazioni.
- `soglia_difesa_quartier_generale` (3): la distanza in caselle entro cui una formazione nota accende la difesa. PROVVISORIO; almeno uno, o la difesa non si accenderebbe mai (imposto dal caricatore, `errore.dati.condotta_incoerente`).

L'aggiramento (01 §5.13) NON è un peso ma un tratto costante dell'avanzata: la distanza-obiettivo si misura aggirando le formazioni note. Il carattere è UNO solo per ora, non sdoppiato per ufficiale né fra campagna e battaglia (03 §6.5.2, rinviato): quando gli ufficiali di campagna esisteranno, questi pesi diverranno i loro parametri. Misura dal banco (`swift run StrumentoVerifica`, incarico 18): due scenari con avversario, `tagli_da_avversario_in_totale` 19, `aggiramenti_in_totale` 5, `distanza_minima_avversario_dal_qg_giocatore` 0, con `violazioni_trovate_in_totale` 0.

### La versione dei valori sale a 0.10.0 (incarico 18)

Con l'avversario che si muove il primo blocco giocabile della campagna esiste, e la versione dei valori sale da 0.9.0 a **0.10.0**, come la sessione del blocco 1 aveva annunciato: raccoglie tutti i numeri di campagna introdotti da allora — il raggio di osservazione e la soglia di decadimento (`conoscenza-campagna.json`, incarico 17) e ora il carattere dell'avversario (`condotta-campagna.json`) — più il nuovo file di dati. L'incremento è dovuto e non discrezionale (regola del titolare: le versioni salgono su istruzione, e questo incarico la dà esplicitamente). I salvataggi 0.9.0 e 0.8.0 restano dichiarati COMPATIBILI (`versioni_compatibili`): una campagna salvata prima di questa build non ha gruppi avversari nel proprio scenario, sicché ripresa con questa build si comporta esattamente come prima (l'avversario non muove ciò che non esiste) e i suoi comandi si riapplicano identici; lo schema del giornale resta 4. Un salvataggio con versione o schema davvero incompatibili si dichiara e si rifiuta invece di fallire in silenzio (`SessioneCampagna.ErroreSessione.salvataggioIncompatibile`/`schemaIncompatibile`, prove in `SessioneCampagnaTest`). I valori di BATTAGLIA non cambiano.

### formati-mappa.json — FISSATI

Le dimensioni dei tre formati: quattro per quattro, sei per sei, dieci per dieci. FISSATI da 01 §5.1, che li dichiara «tre formati fissi». Non sono taratura e non si toccano qui. Stanno nei dati e non nel codice perché il codice non deve conoscere alcuna dimensione, non perché siano da tarare.

Discrepanza aperta e non chiusa: 01 §5.14.5.1 nomina anche un formato otto per otto. Vedi il registro degli scostamenti, S5.

### Mappe/*.json — CONTENUTO, non valori

Terreni, strade, strettoie e posizioni dei quartier generali delle tre mappe di prova non sono valori di bilanciamento ma contenuto (05 §7.6, «le mappe sono contenuto, non codice»). Non si tarano: si disegnano. Le tre di questa unità servono a percorrere i tre formati e non pretendono di essere mappe definitive; ciascun fronte ne richiederà almeno cinque (01 §5.6.9).

### nomi-gruppi.json — CONTENUTO

Le ventiquattro chiavi dei nomi dei gruppi (dodici con l'incarico 15, che introduce la divisione: ogni divisione consuma un nome, e i nomi non si riusano). Non sono valori: sono l'elenco chiuso e prevedibile che 01 §5.6.0.4 richiede. Il numero è capienza, non taratura: nulla impedisce di allungarlo, e la validazione respinge un elenco più corto del numero di gruppi che uno scenario chiede. Il tetto pratico che la lista impone al numero di gruppi CREATI è lo scostamento S16, in tensione con 01 §5.6.0.1.

### Scenari/Campagne/campagne.json — PARAMETRI DI MISURA, non valori di gioco

`giornate_generate` (40) e `gruppi_per_la_misura_dei_passi` (da 1 a 8) governano quanto a lungo il programma di verifica generi giornate e su quali conteggi di gruppi misuri il costo di chiusura. Come i parametri dei banchi di scontro, non entrano in alcuna formula del Motore: cambiarli cambia la misura, non il gioco.

La `composizione` dei gruppi negli scenari (incarico 15) è CONTENUTO, non valore da tarare, come le posizioni: gli atomi per archetipo dichiarano di che cosa un gruppo è fatto. Le tre fasce usate negli scenari di misura e nelle campagne giocabili (`scenari-campagna.json`) — fanteria leggera 6; leggera 18 più pesante 8; pesante 24 più cavalleria manovrata 12 — danno volumi 60, 292, 696, scelti per esercitare i tre gradini del giorno aggiuntivo alla soglia provvisoria di 250. Il `volume_per_atomo` di ciascun archetipo resta PROVVISORIO in `archetipi.json`.

### Il modello dei passi — DICHIARATO, non tarato

La misura del costo di chiusura di una giornata usa un modello dichiarato in `BancoCampagna`: con il salto diretto ordinare un gruppo costa tre passi (salto, attivazione della casella, scelta della voce); senza il salto, al posto del salto occorrono gli scorrimenti che separano le due caselle nell'ordine di lettura. Non è un valore di gioco e non risiede nei file dei valori: è l'unità di misura, e come tale va discussa, non tarata. Se la prova su dispositivo mostrasse che il costo reale di un'operazione è diverso, si corregge il modello e si rilegge la misura.

### Sigle degli archetipi sulla tessera del deck — RIMOSSE, sostituite dai simboli (RDA-97)

Le sigle di una o due lettere sono state **rimosse** (incarico 13, RDA-97): non erano un segnaposto definitivo e i simboli grafici veri le hanno sostituite. Ogni archetipo ha ora il proprio simbolo vettoriale monocromo nel formato dei simboli di sistema (`Immagini.xcassets/<archetipo>.symbolset`), decorazione visiva mai annunciata come già la sigla. Le chiavi `deck.sigla.<archetipo>` non esistono più nei testi, e il pacchetto `en.lproj` — che conteneva SOLTANTO le sigle inglesi — è stato eliminato (i simboli sono indipendenti dalla lingua). Non è più un valore provvisorio.

### Soglie di disingaggio a tre fasce, logoramento e secondo contatto — PROVVISORI (incarico 10)

Introdotti dall'incarico 10 dopo la misura del corpo a corpo (incarico 09), giustificati da una misura di separazione ma non ancora tarati sul gioco reale con i tester; restano PROVVISORI finché il titolare non li conferma provando le battaglie.

- `archetipi.json`, campo `soglia_disingaggio`, **tre fasce** (RDA-87): bassa **0,12** (`tiratori`, `piattaforma_trainata`, `macchina_tiro`); media **0,6** (`fanteria_leggera`, `cavalleria_ricognizione`, `cavalleria_manovrata`); alta **0,9** (`fanteria_pesante`, `macchina_assedio`). La chiave è ASSENTE per `guardia_elite` (reparto elitario, RDA-88): non è un valore, è l'assenza della soglia. Misura di separazione: `mischia_fasce` di `swift run StrumentoVerifica` dà mediana 1 / 4 / 8 scambi per bassa / media / alta.
- `combattimento.json`, `coefficiente_logoramento_soglia` = **0,5** (RDA-90): coefficiente della formula unica `sogliaDisingaggioEffettiva`. Zero lo disattiva. PROVVISORIO.

### Élite storiche e ripiego di banda (incarico 11)

- `archetipi.json`, `elite_fase` (RDA-92): élite antica `guardia_elite = antica`, élite arcaica `piattaforma_trainata = arcaica`, fondate sulla ricerca storica (fonti in RDA-92). Non sono numeri di taratura ma un'assegnazione storica; restano rivedibili dal titolare, non provvisori nel senso della taratura.
- `archetipi.json`, `guardia_elite.soglia_disingaggio` = **0,9**: banda di RIPIEGO per le fasi in cui la guardia d'élite non è élite. PROVVISORIA e non esercitata (`guardia_elite` è antica-solo per la ricerca, quindi sempre élite in gioco); il comportamento accettato in antica — soglia assente — è invariato.
- L'interruttore `soglia_al_secondo_contatto` è RIMOSSO (RDA-95, decisione del titolare): non è più un valore provvisorio.

La versione dei valori è salita a **0.8.0** (incarico 14): incremento dovuto, non discrezionale, perché i pesi del costo in giorni cambiano il modo in cui una partita in corso di CAMPAGNA si svolgerebbe (una marcia costa ora più giorni). Le partite di campagna precedenti sono comunque già rifiutate dallo schema (`FondazioneCampagna.schemaCorrente` da 2 a 3), che morde prima della versione dei valori; il bump della versione documenta il cambiamento e vale per l'intero fascio dei valori. I valori di BATTAGLIA non cambiano. (Era 0.7.0 dall'incarico 13/RDA-92: cambiava il reparto élite e il formato dello stato. Era 0.6.0 dall'incarico 10, RDA-91.)

### I valori della ricognizione — PROVVISORI (incarico 19, RDA-117)

Il rischio della ricognizione è deterministico e i suoi pesi vivono nei dati (`ricognizione-campagna.json`), mai nel codice (00 §13.1). Tutti PROVVISORI, da tarare giocando; nessuna simulazione li giustifica ancora come equilibrio, il banco mostra solo che esercitano i fenomeni.

- `raggio_esplorazione` = **2** (deve essere maggiore del raggio di osservazione ordinario, 1, o esplorare non rivelerebbe nulla di nuovo; validato dal caricatore).
- `insidiosita_base` = **2**; `peso_profondita` = **1** (per casella di distanza dal proprio quartier generale); `peso_nemici_vicini` = **2** (per gruppo armato avversario); `raggio_nemici_vicini` = **2**.
- `soglia_mani_vuote` = **2**, `soglia_notati` = **5** (devono valere `0 < mani_vuote < notati`, o le fasce si sovrappongono; validate). Il margine `competenza − insidiosità`: `≥ 0` riuscita, `≥ −2` a mani vuote, `≥ −5` notati, sotto perduti.
- Le COMPETENZE degli esploratori, i CARICHI e le SOGLIE di protezione delle formazioni non armate vivono negli scenari (`GruppoIniziale`), non in un file di valori: sono dati di scenario, provvisori nei banchi di verifica (`campagne.json`, scenario `ricognizione_imboscate_pianura`).

### La versione dei valori sale a 0.11.0 (incarico 19, RDA-120)

La ricognizione, le imboscate e le azioni contro le non armate aggiungono numeri di campagna (`ricognizione-campagna.json`) e cambiano la risoluzione di fine giornata: la versione dei valori sale da 0.10.0 a **0.11.0**, su istruzione esplicita dell'incarico (regola del titolare: le versioni salgono su istruzione). Lo schema del giornale di campagna sale da 4 a **5**: un giornale 4, rigiocato con queste regole, produrrebbe un registro diverso — l'arrivo di un proprio gruppo ne esce (RDA-120) — sicché non si riapre e lo si DICHIARA incompatibile (`FondazioneCampagna.schemaCorrente` = 5; prova in `SessioneCampagnaTest`). `versioni_compatibili` = **["0.8.0", "0.9.0", "0.10.0"]**: i salvataggi di BATTAGLIA di quelle versioni si riaprono identici (i valori di battaglia non cambiano); i salvataggi di CAMPAGNA di quelle versioni sono già rifiutati dallo schema, che morde prima. Un salvataggio con versione o schema davvero incompatibili si dichiara e si rifiuta invece di fallire in silenzio (`SalvataggioBuildDistribuitaTest`). I valori di BATTAGLIA non cambiano.

### L'imboscata come ordine che si rinnova: NESSUN nuovo numero di gioco (incarico 21, RDA-122/123/124)

La versione dei valori RESTA **0.11.0**: l'incarico 21 cambia una REGOLA (l'imboscata consuma l'azione e si rinnova; l'occultamento per retrocessione della conoscenza; la scoperta riservata alla ricognizione), non i NUMERI. Valutazione dichiarata, non lasciata per omissione:
- L'occultamento riusa il `raggio_osservazione` (1) e la `soglia_confermato_in_avvistato` (2) già esistenti (`conoscenza-campagna.json`): un ricordo fresco retrocede al limite dell'avvistato, cioè a `soglia_confermato_in_avvistato` turni. Nessun numero nuovo.
- La scoperta riusa interamente i valori della ricognizione (`ricognizione-campagna.json`, RDA-117): un'esplorazione riuscita rivela l'area. La «insidiosità dell'imboscata» che l'incarico nomina NON è un dato a sé: un appostato conta già come nemico armato vicino (`peso_nemici_vicini` = 2), sicché un agguato rende la zona più insidiosa da esplorare senza un numero nuovo.
- La TATTICA d'agguato della condotta avversaria (un armato che non guadagna avanzando e ha una formazione nota ADIACENTE si apposta) usa la sola ADIACENZA (relazione della griglia, distanza 1), non una soglia tarabile: è la forma MINIMA e provvisoria con cui si avvia la tattica rinviata in S18/S19, e la sua eventuale soglia e il suo raggio restano da tarare col gioco. Nessun valore di gioco nel codice oltre l'adiacenza strutturale.

Lo schema del giornale di campagna RESTA **5**: la rimozione della revoca dell'imboscata (RDA-122) non tocca alcun salvataggio distribuito — quel comando è nato nell'incarico 19, mai rilasciato (i tester hanno la build 22, l'avversario). I salvataggi della build 22 (schema 5) restano compatibili.

### Il raggio di osservazione, perché l'avversario si manifesti (incarico 22, RDA-125)

Numeri cambiati, con quelli di prima e la misura che li giustifica (banco, `Corsa.avvistamenti`, `test_incarico_22_il_banco_genera_e_misura_gli_avvistamenti`, quaranta giornate):

- `conoscenza-campagna.json`, `raggio_osservazione`: **1 → 2**. A raggio 1, su una mappa di cento caselle, il giocatore vedeva quasi nulla e l'avversario non entrava mai nel suo campo. Misura sullo scenario `pianura_contro_avversario` (dieci per dieci): avvistamenti per partita **3 → 14**, giornata del primo avvistamento **10 → 8**, porzione di mappa osservata **32% → 43%**. Sugli altri scenari con avversario: `guado_contro_avversario` **7 → 11**, `ricognizione_imboscate_pianura` **5 → 19**. Il 43% osservato sulla pianura conferma che l'informazione resta INCOMPLETA: l'avversario si manifesta, non è sempre visibile. PROVVISORIO.
- `ricognizione-campagna.json`, `raggio_esplorazione`: **2 → 3**. Cambiato PER VINCOLO, non per taratura autonoma: il caricatore esige `raggio_esplorazione > raggio_osservazione` (errore `ricognizione_incoerente`), o l'esplorazione non rivelerebbe nulla oltre la vista ordinaria. Sale del minimo che conserva la relazione. PROVVISORIO.

**Valutazione della versione dei valori — RESTA 0.11.0.** Dichiarata, non lasciata per omissione. La regola del titolare è che le versioni salgono su ISTRUZIONE, e questo incarico non ne dà una; il raggio è un valore PROVVISORIO, la sua taratura è esattamente ciò per cui i valori provvisori esistono. Nessuna incompatibilità di salvataggio: il raggio vive nei VALORI (`conoscenza-campagna.json`, `ricognizione-campagna.json`), non nel giornale; lo schema del giornale di campagna RESTA **5** (nessun fatto nuovo, nessuna forma nuova del registro), sicché un salvataggio della build 23 si riapre con la build 24 e da lì in avanti osserva semplicemente una fascia più larga. I valori di BATTAGLIA non cambiano. La versione dei Testi RESTA **0.1.1** benché sia stata aggiunta la chiave `casella.composizione`: l'aggiunta non toglie né muta alcun testo esistente, e la rigenerazione delle impronte la registra senza bump (`rigenera-impronte.py`, «invariata»).

### Lo scenario iniziale della campagna: le tre categorie per parte (incarico 23, RDA-128)

Lo scenario giocabile `scenari-campagna.json` schierava SOLTANTO gruppi armati del giocatore, senza avversario né ricognizione né non armate — il difetto per cui gli esploratori non esistevano in partita e il nemico non si incontrava. Ora, per ciascuno dei tre formati, schiera le tre categorie per ENTRAMBE le parti. Numeri di prima → di ora (gruppi per parte, `scenari-campagna.json`):

- **`campagna_piccola`** (guado 4×4): giocatore **2 armati → 2 armati + 1 ricognizione + 1 non armata (4)**; avversario **0 → 1 armato + 1 ricognizione + 1 non armata (3)**.
- **`campagna_media`** (istmo 6×6): giocatore **3 armati → 3 armati + 1 ricognizione + 1 non armata (5)**; avversario **0 → 3 (1+1+1)**.
- **`campagna_grande`** (pianura 10×10): giocatore **5 armati → 5 armati + 1 ricognizione + 1 non armata (7)**; avversario **0 → 3 (1+1+1)**.

*Criterio:* ogni parte schiera almeno un gruppo per categoria su ogni mappa; il giocatore conserva la sua forza armata di prima (identica, e nello stesso ordine, sicché `gruppiOrdinati[0]` non si sposta) e vi aggiunge un esploratore e una non armata; l'avversario ne schiera uno per categoria presso il proprio quartier generale. *Valori delle formazioni nuove, PROVVISORI:* ricognizione `competenza` = **5**; non armata `carico` = **4**, `soglia_protezione` = **2**; composizioni piccole (`fanteria_leggera` 3 atomi per gli esploratori, 4 per le non armate). Lo scenario è un DATO, non un valore tarato: la versione dei valori RESTA **0.11.0**; nessuna incompatibilità di salvataggio (lo schema del giornale non cambia). Impronte dei Contenuti rigenerate (solo l'impronta di `scenari-campagna.json` cambia; `manifest.json` dei Valori resta a 21 file, versione 0.11.0 invariata; `rigenera-impronte.py --verifica` coerente).

## Il modello dello scontro nato dalla campagna (incarico 24)

La campagna non dichiara con quale cornice una battaglia si combatte; `PonteCampagnaBattaglia.Modello` la fornisce, letta dallo scenario di prova (`scenari.json`). PROVVISORI, non tarati (non toccano il combattimento, che il titolare ha accettato):

- **formato del campo** = `cento` (griglia 10×10, tre righe di piazzamento).
- **terreno (caratteristica)** = `campo_aperto`.
- **protezione dei reparti** = `anti_saturazione` (la campagna non porta la protezione, che in battaglia è scelta allo schieramento; qui un difetto uniforme).
- **fase storica** = assente → la fabbrica assume l'antica; **ufficiale avversario** = il primo dei dati (`ufficiale_prova`).

Da tarare quando la campagna porterà questi dati (terreno della casella contesa, protezione della composizione, fase del fronte). Il vantaggio dell'imboscante è invece già tarato sul lato battaglia (`FormatoBattaglia.turniVantaggioImboscante`, `scontoImboscante`) e non è provvisorio.

Versione dei valori RESTA **0.11.0** (valutazione dichiarata): non si introducono valori tarati nuovi — il modello è la cornice minima provvisoria. Versione del giornale di CAMPAGNA sale da 5 a **6** (regole di fine giornata cambiate: il contatto armato ora innesca una battaglia; i salvataggi v5 si dichiarano incompatibili). Versione della battaglia (`Fondazione.schemaCorrente`) RESTA 2 (il formato di battaglia non cambia). Versione dei Testi RESTA **0.1.1** (chiavi nuove aggiunte — `pannello.apri_battaglia`, `campagna.battaglia_in_sospeso`, `campagna.battaglia_innescata[_imboscata]`, `campagna.battaglia_vinta`/`_persa`, `registro.battaglia_innescata`/`_vinta`/`_persa`, `campagna.battaglia_non_apribile` — ma il manifest dei testi porta le impronte per file, sicché la sincronizzazione non è la trappola del manifest a sola versione+lingue; impronte rigenerate).
