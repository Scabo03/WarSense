# Valori provvisori in attesa di taratura

Documento di lavoro della fase 5. Ogni numero introdotto per far funzionare il codice, in attesa della taratura con le simulazioni. Un valore provvisorio che non risulti da questo elenco è un difetto (incarico fase 5, sezione 3). Nessun numero di gioco vive nel codice: tutti stanno nei file di `Codice/Sources/Contenuti/Valori/`.

Convenzione: PROVVISORIO = da tarare con le simulazioni o da fissare in sede di definizione dei valori; FISSATO = deciso dai consolidati, non si tocca qui.

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
- `maggiorazione_vicinanza_massima` (0.6): quanto il tiro rende di più alla minima distanza rispetto al limite della gittata (01 §9.10.1, 03 §5.15). PROVVISORIO; grandezza critica 03 §6.10, prima misura.
- `fascia_vicinanza_lontano_fino` (0.33) e `fascia_vicinanza_ravvicinato_fino` (0.66): soglie delle tre fasce descrittive della vicinanza, sulla prossimità che vale zero al limite della gittata e uno alla minima distanza (01 §9.10.1, 02 §4.4.5, 03 §5.15). PROVVISORIE: divisione in terzi, scelta perché con la gittata sei dei tiratori assegna due distanze a ciascuna fascia.
- `passo_accerchiamento` (0.15): passo della maggiorazione di accerchiamento, composto col quadrato dei concorrenti eccedenti il primo (01 §9.10.2, 03 §5.16). Ne risultano 1,15 con due concorrenti, 1,60 con tre e 2,35 con quattro. PROVVISORIO; grandezza critica 03 §6.10, seconda misura.
- `concorrenti_massimi` (4): tetto dei concorrenti conteggiati (01 §9.10.2, 03 §5.16). PROVVISORIO, ancorato al «tre o quattro» del titolare.
- `resa_contro_secondo_bersaglio` (0.5): il malus del secondo bersaglio, espresso come resa conservata (01 §9.11, 03 §5.17). Contro il primo la resa è piena, dal terzo non c'è risposta: non esistono altre voci, perché il numero massimo di nemici cui si risponde è una regola e non un valore. PROVVISORIO. Vincolo di validazione: strettamente fra zero e uno.

PROPOSTA DI REVISIONE NON APPLICATA, dalla misura dell'effetto congiunto (03 §6.10.1 e §6.10.2): con il limite dei bersagli in vigore, `passo_accerchiamento` a 0.15 porta tre assalitori ad annientare il bersaglio in un solo giro. Proposto 0.08 (dà 1,08 a due concorrenti, 1,32 a tre, 1,72 a quattro). Non applicato: i valori sono taratura e la scelta è del titolare.

## caratteristiche-campo.json

- `campo_aperto` senza modificatori: neutro per costruzione.
- `terreno_rotto` con `coefficiente_costo_movimento` 1.3: PROVVISORIO — 03 §5.12.

## minimi.json — FISSATI

Tutti a 1, come impone 00 §13.6 (minimo di uno dove il troncamento darebbe zero); l'elenco dei casi è 03 §8.2.

## ufficiali.json — PROVVISORI

I cinque parametri di carattere dei due ufficiali di prova (propensione all'attacco, tolleranza alle perdite, tendenza all'accerchiamento, propensione all'imboscata, propensione alla ritirata). Grandezza critica 03 §6.5: il carattere determina la frequenza effettiva degli scontri, taratura con le simulazioni.

## vantaggi-nascosti.json

- Ritirata avversaria dalla sola ultima riga: FISSATO — 01 §13.2.
- Riduzione della propensione alla ritirata avversaria (0.3): PROVVISORIO — «molto bassa» di 01 §13.2, misura da tarare (03 §7).
- `annientamento_simultaneo_al_giocatore` (vero): FISSATO — 01 §15.2.5, decisione del titolare. Non è una misura ma un interruttore: acceso, sconfitto è l'avversario; spento, l'esito torna al giocatore ed è la forma in cui la Verifica misura il caso reale (05 §12.5, RDA-57).

## scenari.json — PROVVISORI

Composizione dei mazzi dello scontro di prova, ostacoli, ufficiale assegnato: numeri di lavoro per la fase B, senza pretesa di equilibrio.

## aptica.json e suoni.json

Intensità, nitidezze e tempi dei pattern e suoni generati: PROVVISORI come resa, FISSATA la struttura (famiglie ritmiche e assegnazioni di 02 §11.7.1). Da raffinare con i ritorni dei tester.

## Soglia del tattico (formula, non numero)

La soglia di resa del tattico è tolleranza alle perdite divisa per la propensione effettiva alla ritirata: struttura nel codice, numeri nei file (01 §12.1, RDA-46).

MISURA dall'accertamento sugli esiti degli scontri: con l'`ufficiale_prova` di fabbrica (tolleranza 0,5, propensione 0,5) la soglia vale 1,0 delle forze impiegate GIÀ SENZA il vantaggio nascosto, e 3,33 con esso. L'avversario non può quindi arrendersi in nessuna partita, e ogni battaglia si chiude per annientamento o per resa del giocatore. Non è il vantaggio nascosto a produrlo, sono i valori di carattere: la taratura di 03 §6.5 va condotta sapendolo, e il rapporto tolleranza/propensione va portato sotto l'unità perché la resa avversaria sia raggiungibile. Registrato anche in 03 §7.4. Prova che lo fissa: `AccertamentoScontriTest.test_01_13_2_peso_misurato_della_propensione_alla_ritirata_ridotta`.

## Numeri di struttura (non di gioco, quindi nel codice per 05 §0.4)

- Fattore di scala della virgola fissa: 1000 (`Scalato.fattore`, RDA-44).
- Passo delle istantanee: 200 righe di giornale (05 §6.2, dichiarato numero di struttura).
- Versione dello schema del giornale: 2 (`Fondazione.schemaCorrente`; la 2 dalla prima tranche di semplificazioni: il comando di tiro non trasporta più il proiettile).
