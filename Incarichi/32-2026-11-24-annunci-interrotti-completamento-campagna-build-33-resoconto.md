# Incarico 32 — resoconto

`P/` sta per `Incarichi/32-2026-11-24-prodotti/`.

## In testa

@@IN_TESTA@@

## Lo stato di partenza, verificato

`git rev-parse principale origin/principale`: `06dee59` entrambi; `git status --short` vuoto; un solo ramo remoto. Valori 0.15.0 (`Codice/Sources/Contenuti/Valori/manifest.json`); schemi 2, 9 e 2 (`grep schemaCorrente`); ultimo RDA 182, ultimo scostamento S29q. Tutto come l'incarico lo dichiara. App Store Connect, per API: build 32 `VALID`, treno 1.1.0.

## Le versioni della macchina

macOS 27.0.1 (26A434), Xcode 27.2 (27B52), Swift 6.4.2, xcodegen 2.45.4, Python 3.9.6; Apple M5 Pro, 15 processori. Simulatori iOS 27.0 (24A434), tutti di WarSense: iPhone Air C86CB490… e iPad Pro 13 D01FE19F… per il collaudo; iPhone 76DF33B6…, E2C6F42C…, 87AB2F55…, 4CD3DC60… e iPad 8D3583DB…, 75A249BF…, 1DF852F1…, 2B3AB121… per il pilota e il tester. Nessun simulatore, processo o finestra altrui toccato. Nessun sotto-agente usato.

## Per ogni punto: il commit e la prova

| punto dell'incarico | commit | prove |
|---|---|---|
| L'annuncio interrotto (S29q, a) | `84f95f9`, `805e42e`, `35127d2`, `e9f702e` | `CodaAnnunciTest`; `ConfiniTest` (`test_00_5_3_…`, `test_02_5_5_1_…`); `OsservazioniTesterTest.test_02_5_5_1_…`; `PannelloAzioniTest.test_02_5_7_…`; `PassaggioBattagliaInterfacciaTest.test_02_2_9_…` (due); `PatriaTest`; la misura col pilota (sotto) |
| Le reclute lontano dal nemico (S29q, b) | `a3e0215` | `ArriviDallaPatriaTest` (`test_01_5_2_1_1_…`), `SecondaTappaDelRegnoTest.test_01_5_2_1_1_…`, percorso «reclute» (iPhone e iPad); banco rifatto |
| Il rifiuto prima della scelta del fronte (S29q, c) | `a3e0215` | `SecondaTappaDelRegnoTest.test_incarico_31_chi_parte_…`, percorso «rifiuto» |
| La riga in patria (S29q, d) | `a3e0215` | `TraduttoreRegnoSecondaTappaTest`, `SecondaTappaDelRegnoTest.test_incarico_31_le_reclute_…`, percorso «reclute» |
| La presa del quartier generale | `5cc47d8`, `be20580`, `9a0ae50` | `PresaDelQuartierGeneraleTest` (29), `InvariantiCampagnaTest` (mutanti dei tre invarianti nuovi), `CompletamentoDellaCampagnaTest` di Sessione (6) e ospitate (5), `TraduttoreCampagnaTest`, `CampagnaDelRegnoTest`, percorsi «presa» e «subita», tester |
| La resa della campagna | `5cc47d8` | le stesse; `CompatibilitaGiornaleTest` (righe 41–43 dei campioni); percorso «richiamo», tester |
| Le battaglie che non finiscono | `c8a3d50`, `c264837` | `TatticoPiazzamentoTest`, `StalloDellaBattagliaTest`; i due banchi |
| Lo squilibrio fra le mappe | `5cc47d8` (i difetti), `c264837`, `805e42e` (gli strumenti) | `BudgetDelPrimoTurnoTest`, `UnitaEvacuateTest`; duelli, banchi, proposte |
| La virgola | `f3c2c9a` | `PosizioneNelleFrasiTest` (cancello), percorso «battaglia» |
| Il congedo del resoconto | `f3c2c9a` | `PassaggioBattagliaInterfacciaTest.test_incarico_25_…`, percorso «battaglia» |
| Le tre campagne senza battaglie vinte | — (spiegate, sotto) | traccia sul codice della build 32 |
| Le versioni e i salvataggi | `c264837` | `SalvataggiBuild32Test` (8); la prova dal vivo (`P/salvataggi-build-32/`, 12 controlli su 12) |

Ogni prova e ogni cancello nuovo si è visto fallire, con la mutazione e l'uscita in `P/cancelli-visti-fallire/`.

## Gli annunci: i tempi prima e dopo, per annuncio e per apparecchio

Strumento: `P/annunci/misura-annunci.py` sulla copia strumentata dell'app (aggiunge il solo registro), `P/annunci/tabella.py` per la tabella; dati grezzi in `P/annunci/misure-grezze/`. «Prima» è `06dee59`, «dopo» il codice di questo incarico (`e9f702e`). Ogni cella: per quanto la voce ha detto l'annuncio, e se l'ha detto intero. Le vie considerate e la loro misura: `P/annunci/scelta-della-via/README.md`; la scelta e il perché: RDA-183.

### Riassunto

| | iPhone prima | iPhone dopo | iPad prima | iPad dopo |
|---|---|---|---|---|
| Con spostamento: interi su detti | 9 su 28 | 28 su 34 | 8 su 28 | 28 su 34 |
| Senza spostamento: interi su detti | 33 su 33 | 70 su 73 | 33 su 33 | 70 su 73 |

### Annunci che accompagnano uno spostamento del fuoco o un cambio di schermata

| Quando | Annuncio (caratteri) | iPhone prima | iPhone dopo | iPad prima | iPad dopo |
|---|---|---|---|---|---|
| regno · comincia l'inverno | «Comincia l'inverno dell'anno 1. Entrate: monete di bronzo 200, uomini 24, metalli 30, mate…» (175) | 0.01 s interrotto | 14.17 s intero | 0.00 s interrotto | 14.17 s intero |
| regno · addestramento ordinato dalla scelta del reparto | «Addestramento mirato ordinato per 8 atomi di fanteria pesante di Lupo: pronto in primavera…» (91) | 0.75 s interrotto | 5.52 s intero | 0.77 s interrotto | 5.51 s intero |
| regno · scelta impedita rifiutata | «Non si può ordinare: mancano monete di bronzo.» (46) | 0.77 s interrotto | 3.05 s intero | 0.77 s interrotto | 3.05 s intero |
| regno · comincia la primavera | «Comincia la primavera dell'anno 2. Il riporto ha tolto: monete di bronzo 73, uomini 24, me…» (206) | 0.00 s interrotto | 15.07 s intero | 0.06 s interrotto | 15.07 s intero |
| regno · apertura della campagna dal regno | «Campagna aperta sul fronte del guado» (36) | 0.80 s interrotto | 2.32 s intero | 0.78 s interrotto | 2.30 s intero |
| regno · apertura della campagna dal regno | «Mappa Guado, 4 righe per 4 caselle. Il tuo quartier generale è in riga 4, casella 2» (83) | 6.29 s intero | 6.27 s intero | 6.33 s intero | 6.28 s intero |
| regno · apertura della campagna dal regno | «Anno 2, primavera, mancano 89 giornate all'inverno. Giorno 1. Nessun gruppo ha ancora agit…» (99) | 7.97 s intero | 8.10 s intero | 8.06 s intero | 8.34 s intero |
| mappa · entra nel fronte | «Mappa Guado, 4 righe per 4 caselle. Il tuo quartier generale è in riga 4, casella 2» (83) | 0.78 s interrotto | 6.27 s intero | 0.00 s interrotto | 6.26 s intero |
| mappa · entra nel fronte | «Anno 2, primavera, mancano 89 giornate all'inverno. Giorno 1. Nessun gruppo ha ancora agit…» (99) | 7.93 s intero | 7.93 s intero | 0.79 s interrotto | 7.93 s intero |
| mappa · marcia: destinazione da scegliere | «Scegli la casella di destinazione e attivala per dare l'ordine di marcia. Il gruppo rester…» (163) | 0.73 s interrotto | 9.75 s intero | 0.78 s interrotto | 9.18 s intero |
| mappa · marcia revocata | «Lupo: marcia revocata, persi 0 giorni» (37) | 0.79 s interrotto | 3.25 s intero | 0.78 s interrotto | 3.26 s intero |
| mappa · presidio ordinato | «Corvo presidia in riga 4, casella 2» (35) | 0.79 s interrotto | 2.85 s intero | 0.78 s interrotto | 2.85 s intero |
| mappa · divisione compiuta | «Nuovo gruppo Lince in riga 3, casella 4» (39) | 0.79 s interrotto | 3.03 s intero | 0.78 s interrotto | 3.03 s intero |
| mappa · riunione compiuta | «Falco riunito in riga 4, casella 4» (34) | 0.79 s interrotto | 3.20 s intero | 0.77 s interrotto | 3.18 s intero |
| mappa · esplorazione compiuta | «Orso ha esplorato la zona attorno a riga 4, casella 1» (53) | 0.79 s interrotto | 3.75 s intero | 0.78 s interrotto | 3.76 s intero |
| scontro · apertura dello scontro | «Battaglia su WarSense, 10 righe per 10 celle. Il campo è campo aperto, ostacolo» (79) | 0.02 s interrotto | 6.34 s intero | 0.77 s interrotto | 5.92 s intero |
| scontro · movimento: destinazione da scegliere | «Scegli la cella di destinazione e attivala per confermare» (57) | 0.79 s interrotto | 3.34 s intero | 0.78 s interrotto | 3.34 s intero |
| scontro · evacuazione che conclude lo scontro | «Unità evacuata: costa 52» (24) | 0.77 s interrotto | 2.53 s intero | 0.78 s interrotto | 2.53 s intero |
| scontro · evacuazione che conclude lo scontro | «La battaglia è conclusa: la ritirata è compiuta» (47) | 3.13 s intero | 3.12 s intero | 3.13 s intero | 3.13 s intero |
| battaglia · la battaglia aperta dalla casella | «Battaglia su WarSense, 10 righe per 10 celle. Il campo è campo aperto» (69) | 0.78 s interrotto | 5.05 s intero | 0.77 s interrotto | 5.06 s intero |
| battaglia · la battaglia aperta dalla casella | «Entra in campo fanteria leggera A avversaria in riga 1, cella 5» (63) | 4.33 s intero | 4.22 s intero | 4.26 s intero | 4.21 s intero |
| battaglia · la battaglia aperta dalla casella | «Turno 2, agisce l'avversario» (28) | 2.22 s intero | 2.21 s intero | 2.20 s intero | 2.20 s intero |
| battaglia · la battaglia aperta dalla casella | «Turno 3, agisce l'avversario» (28) | 2.13 s intero | 2.19 s intero | 2.19 s intero | 2.19 s intero |
| battaglia · la battaglia aperta dalla casella | «Turno 3, tocca a te» (19) | 1.53 s intero | 1.51 s intero | 1.57 s intero | 1.51 s intero |
| battaglia · evacuazione che conclude la battaglia | «Unità evacuata: costa 60» (24) | 0.79 s interrotto | 2.84 s intero | 0.78 s interrotto | 1.44 s interrotto |
| battaglia · evacuazione che conclude la battaglia | «La battaglia è conclusa: la ritirata è compiuta» (47) | 3.14 s intero | nessuna voce | 3.13 s intero | 3.05 s intero |
| battaglia · ritorno sulla mappa dopo la battaglia | «Battaglia persa in riga 1, casella 2» (36) | 0.77 s interrotto | 2.62 s intero | 0.77 s interrotto | 2.62 s intero |
| conclusione · giornata chiusa (3) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | superato dal gioco | superato dal gioco | superato dal gioco | superato dal gioco |
| conclusione · giornata chiusa (3) | «È arrivato l'inverno: la campagna è conclusa, senza vincitore» (61) | 0.00 s interrotto | 4.24 s intero | 0.00 s interrotto | 4.23 s intero |
| richiamo · richiamo compiuto | «Campagna conclusa: hai richiamato l'esercito in patria. Conta come perduta» (74) | — | 4.93 s intero | — | 5.10 s intero |
| velocita · comincia l'inverno, voce al 90 per cento | «Comincia l'inverno dell'anno 1. Entrate: monete di bronzo 200, uomini 24, metalli 30, mate…» (175) | — | 4.05 s interrotto | — | 4.05 s interrotto |
| velocita · addestramento ordinato, voce al 90 per cento | «Addestramento mirato ordinato per 8 atomi di fanteria pesante di Lupo: pronto in primavera…» (91) | — | 1.57 s interrotto | — | 1.57 s interrotto |
| velocita · apertura della campagna, voce al 90 per cento | «Campagna aperta sul fronte del guado» (36) | — | 0.68 s interrotto | — | 0.68 s interrotto |
| velocita · apertura della campagna, voce al 90 per cento | «Mappa Guado, 4 righe per 4 caselle. Il tuo quartier generale è in riga 4, casella 2» (83) | — | 1.82 s interrotto | — | 1.84 s interrotto |
| velocita · apertura della campagna, voce al 90 per cento | «Anno 1, primavera, mancano 89 giornate all'inverno. Giorno 1. Nessun gruppo ha ancora agit…» (99) | — | 2.29 s interrotto | — | 2.30 s interrotto |

### Annunci che non spostano il fuoco

| Quando | Annuncio (caratteri) | iPhone prima | iPhone dopo | iPad prima | iPad dopo |
|---|---|---|---|---|---|
| regno · resta in patria (riga attivata) | «Corvo resta in patria.» (22) | 1.55 s intero | 1.55 s intero | 1.55 s intero | 1.55 s intero |
| regno · torna al fronte (riga attivata) | «Corvo parte per il fronte.» (26) | 1.80 s intero | 1.80 s intero | 1.81 s intero | 1.82 s intero |
| regno · leva ordinata | «Leva di fanteria leggera ordinata: pronta in primavera.» (55) | 3.42 s intero | 3.41 s intero | 3.41 s intero | 3.41 s intero |
| regno · spesa annullata | «Leva di fanteria leggera: ordine annullato, risorse restituite.» (63) | 4.26 s intero | 4.26 s intero | 4.26 s intero | 4.26 s intero |
| mappa · marcia ordinata sulla casella | «Lupo marcia verso riga 3, casella 3, 2 giorni al termine» (56) | 4.22 s intero | 4.21 s intero | 4.22 s intero | 4.21 s intero |
| mappa · ultimo ordine annullato | «Ultimo ordine annullato» (23) | 1.61 s intero | 1.61 s intero | 1.61 s intero | 1.61 s intero |
| mappa · giornata chiusa dal comando | «Giornata chiusa. 2 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | 6.80 s intero | 6.80 s intero | 6.79 s intero | 6.79 s intero |
| mappa · giornata chiusa dal comando | «Giornata conclusa: comincia il giorno 2» (39) | 2.76 s intero | 2.76 s intero | 2.76 s intero | 2.76 s intero |
| mappa · tocco magico sulla mappa | «Anno 2, primavera, mancano 88 giornate all'inverno. Giorno 2. Nessun gruppo ha ancora agit…» (99) | 7.85 s intero | 7.85 s intero | 7.85 s intero | 7.84 s intero |
| scontro · piazzamento confermato | «Piazzato: costa 50, restano 310» (31) | 3.92 s intero | 3.92 s intero | 3.93 s intero | 3.93 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Turno 1, agisce l'avversario» (28) | 2.18 s intero | 2.18 s intero | 2.18 s intero | 2.18 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria leggera A avversaria in riga 1, cella 5» (63) | 4.22 s intero | 4.23 s intero | 4.23 s intero | 4.23 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria leggera B avversaria in riga 1, cella 6» (63) | 4.06 s intero | 4.07 s intero | 4.07 s intero | 4.07 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria leggera C avversaria in riga 1, cella 4» (63) | 4.36 s intero | 4.36 s intero | 4.36 s intero | 4.38 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria pesante D avversaria in riga 1, cella 7» (63) | 4.35 s intero | 4.34 s intero | 4.34 s intero | 4.34 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria pesante E avversaria in riga 1, cella 3» (63) | 3.99 s intero | 4.01 s intero | 4.01 s intero | 4.01 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entrano in campo tiratori F avversari in riga 1, cella 8» (56) | 3.94 s intero | 3.94 s intero | 3.93 s intero | 3.94 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Turno 2, tocca a te» (19) | 1.54 s intero | 1.55 s intero | 1.54 s intero | 1.53 s intero |
| scontro · movimento compiuto sulla cella | «Spostato in riga 9, cella 4: costa 52, restano 278» (50) | 6.13 s intero | 5.99 s intero | 6.00 s intero | 5.99 s intero |
| scontro · resa dichiarata | «Resa dichiarata: comincia la tua ritirata combattuta» (52) | 3.46 s intero | 3.44 s intero | 3.51 s intero | 3.44 s intero |
| battaglia · marcia verso il nemico ordinata | «Corvo marcia verso riga 1, casella 2, 1 giorno al termine» (57) | 4.23 s intero | 4.20 s intero | 4.26 s intero | 4.19 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Giornata chiusa. 1 gruppo non aveva agito e resta fermo: ne è stata conservata una traccia…» (114) | 6.55 s intero | 6.51 s intero | 6.50 s intero | 6.50 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Corvo è arrivato in riga 1, casella 2» (37) | 2.61 s intero | 2.54 s intero | 2.54 s intero | 2.54 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Imboscata scattata in riga 1, casella 2» (39) | 2.89 s intero | 2.89 s intero | 2.89 s intero | 2.89 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Battaglia in sospeso da imboscata in riga 1, casella 2» (54) | 3.55 s intero | 3.51 s intero | 3.53 s intero | 3.51 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Rifornimento di Corvo interrotto in riga 1, casella 2» (53) | 3.46 s intero | 3.48 s intero | 3.50 s intero | 3.48 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Giornata conclusa: comincia il giorno 2» (39) | 2.75 s intero | 2.75 s intero | 2.80 s intero | 2.75 s intero |
| conclusione · giornata chiusa (cambio di stagione) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | 6.98 s intero | 7.00 s intero | 7.00 s intero | 7.00 s intero |
| conclusione · giornata chiusa (cambio di stagione) | «Giornata conclusa: comincia il giorno 2» (39) | 2.77 s intero | 2.75 s intero | 2.78 s intero | 2.75 s intero |
| conclusione · giornata chiusa (cambio di stagione) | «Nuova stagione: estate» (22) | 1.96 s intero | 1.95 s intero | 2.01 s intero | 1.97 s intero |
| conclusione · giornata chiusa (2) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | 7.00 s intero | 7.00 s intero | 7.02 s intero | 7.01 s intero |
| conclusione · giornata chiusa (2) | «Giornata conclusa: comincia il giorno 3» (39) | 2.74 s intero | 2.76 s intero | 2.74 s intero | 2.76 s intero |
| conclusione · giornata chiusa (2) | «Nuova stagione: autunno» (23) | 1.97 s intero | 1.92 s intero | 1.94 s intero | 1.92 s intero |
| mappa · divisione incompleta rifiutata | «Scegli almeno un reparto da staccare e almeno uno da tenere» (59) | — | 3.22 s intero | — | 3.22 s intero |
| presa · giornata chiusa (1) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.00 s intero | — | 7.00 s intero |
| presa · giornata chiusa (1) | «Formazione avversaria avvistata in riga 4, casella 3» (52) | — | 3.77 s intero | — | 3.77 s intero |
| presa · giornata chiusa (1) | «Occupi il quartier generale avversario, in riga 1, casella 2: se lo tieni sarà preso fra 3…» (99) | — | 6.53 s intero | — | 6.53 s intero |
| presa · giornata chiusa (1) | «Giornata conclusa: comincia il giorno 2» (39) | — | 2.75 s intero | — | 2.75 s intero |
| presa · giornata chiusa (2) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.00 s intero | — | 7.00 s intero |
| presa · giornata chiusa (2) | «Formazione avversaria avvistata in riga 3, casella 3» (52) | — | 3.47 s intero | — | 3.47 s intero |
| presa · giornata chiusa (2) | «Tieni il quartier generale avversario: sarà preso fra 2 giornate» (64) | — | 3.95 s intero | — | 3.96 s intero |
| presa · giornata chiusa (2) | «Giornata conclusa: comincia il giorno 3» (39) | — | 2.75 s intero | — | 2.75 s intero |
| presa · giornata chiusa (3) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.00 s intero | — | 6.99 s intero |
| presa · giornata chiusa (3) | «Formazione avversaria avvistata in riga 3, casella 2» (52) | — | 3.47 s intero | — | 3.58 s intero |
| presa · giornata chiusa (3) | «Tieni il quartier generale avversario: sarà preso fra 1 giornata» (64) | — | 3.95 s intero | — | 3.93 s intero |
| presa · giornata chiusa (3) | «Rifornimento di Falco interrotto in riga 3, casella 1» (53) | — | 3.53 s intero | — | 3.54 s intero |
| presa · giornata chiusa (3) | «Giornata conclusa: comincia il giorno 4» (39) | — | 3.07 s intero | — | 3.06 s intero |
| presa · giornata chiusa (4) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | superato dal gioco | — | superato dal gioco |
| presa · giornata chiusa (4) | «Campagna conclusa: il quartier generale avversario è caduto. Hai vinto» (70) | — | 4.59 s intero | — | 4.57 s intero |
| subita · giornata chiusa (1) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.00 s intero | — | 7.00 s intero |
| subita · giornata chiusa (1) | «L'avversario occupa il tuo quartier generale, in riga 4, casella 2: se non lo scacci sarà …» (110) | — | 7.26 s intero | — | 7.26 s intero |
| subita · giornata chiusa (1) | «Giornata conclusa: comincia il giorno 2» (39) | — | 2.75 s intero | — | 2.75 s intero |
| subita · giornata chiusa (2) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.00 s intero | — | 7.00 s intero |
| subita · giornata chiusa (2) | «Il tuo quartier generale è ancora occupato: sarà preso fra 2 giornate» (69) | — | 4.23 s intero | — | 4.23 s intero |
| subita · giornata chiusa (2) | «Giornata conclusa: comincia il giorno 3» (39) | — | 2.76 s intero | — | 2.75 s intero |
| subita · giornata chiusa (3) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.00 s intero | — | 6.99 s intero |
| subita · giornata chiusa (3) | «Il tuo quartier generale è ancora occupato: sarà preso fra 1 giornata» (69) | — | 4.22 s intero | — | 4.22 s intero |
| subita · giornata chiusa (3) | «Giornata conclusa: comincia il giorno 4» (39) | — | 3.07 s intero | — | 3.08 s intero |
| subita · giornata chiusa (4) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | superato dal gioco | — | superato dal gioco |
| subita · giornata chiusa (4) | «Campagna conclusa: il tuo quartier generale è caduto. Hai perso» (63) | — | 4.18 s intero | — | 4.18 s intero |
| azzeramento · giornata chiusa, l'occupazione comincia | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.00 s intero | — | 7.00 s intero |
| azzeramento · giornata chiusa, l'occupazione comincia | «Formazione avversaria avvistata in riga 4, casella 3» (52) | — | 3.76 s intero | — | 3.76 s intero |
| azzeramento · giornata chiusa, l'occupazione comincia | «Occupi il quartier generale avversario, in riga 1, casella 2: se lo tieni sarà preso fra 3…» (99) | — | 6.53 s intero | — | 6.52 s intero |
| azzeramento · giornata chiusa, l'occupazione comincia | «Giornata conclusa: comincia il giorno 2» (39) | — | 2.75 s intero | — | 2.75 s intero |
| azzeramento · tocco magico con un'occupazione in corso | «Anno 1, primavera, mancano 88 giornate all'inverno. Giorno 2. Nessun gruppo ha ancora agit…» (166) | — | 11.96 s intero | — | 11.96 s intero |
| azzeramento · marcia che lascia il quartier generale | «Corvo marcia verso riga 1, casella 3, 1 giorno al termine» (57) | — | 4.16 s intero | — | 4.16 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Giornata chiusa. 4 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.02 s intero | — | 7.02 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Corvo è arrivato in riga 1, casella 3» (37) | — | 2.53 s intero | — | 2.53 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Formazione avversaria avvistata in riga 3, casella 3» (52) | — | 3.46 s intero | — | 3.46 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Non occupi più il quartier generale avversario: il conteggio si azzera» (70) | — | 4.09 s intero | — | 4.07 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Giornata conclusa: comincia il giorno 3» (39) | — | 2.74 s intero | — | 2.74 s intero |
| richiamo · richiamo impedito | «L'esercito non si può richiamare: Corvo ha il rifornimento tagliato in riga 2, casella 2» (88) | — | 5.35 s intero | — | 5.36 s intero |
| velocita · leva ordinata, voce al 90 per cento | «Leva di fanteria leggera ordinata: pronta in primavera.» (55) | — | 0.98 s interrotto | — | 0.98 s interrotto |
| velocita · giornata chiusa, voce al 90 per cento | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 2.01 s interrotto | — | 2.01 s interrotto |
| velocita · giornata chiusa, voce al 90 per cento | «Giornata conclusa: comincia il giorno 2» (39) | — | 0.81 s interrotto | — | 0.81 s interrotto |

### Dove arriva il fuoco

L'ultimo elemento che riceve il fuoco in ciascun passo che lo sposta o cambia schermata.

| Quando | iPhone prima | iPhone dopo | iPad prima | iPad dopo |
|---|---|---|---|---|
| regno · comincia l'inverno | Anno 1, inverno, schermata 1 di 4 | Anno 1, inverno, schermata 1 di 4 | Anno 1, inverno, schermata 1 di 4 | Anno 1, inverno, schermata 1 di 4 |
| regno · addestramento ordinato dalla scelta del reparto | Addestramento mirato. Si sceglie il reparto. Acc | Addestramento mirato. Si sceglie il reparto. Acc | Addestramento mirato. Si sceglie il reparto. Acc | Addestramento mirato. Si sceglie il reparto. Acc |
| regno · scelta impedita rifiutata | Addestramento mirato. Si sceglie il reparto. Acc | Addestramento mirato. Si sceglie il reparto. Acc | Addestramento mirato. Si sceglie il reparto. Acc | Addestramento mirato. Si sceglie il reparto. Acc |
| regno · comincia la primavera | Anno 2, primavera | Anno 2, primavera | Anno 2, primavera | Anno 2, primavera |
| regno · apertura della campagna dal regno | Torna in patria | riga 3, casella 2, tuo Cervo, formazione non arm | riga 3, casella 2, tuo Cervo, formazione non arm | riga 3, casella 2, tuo Cervo, formazione non arm |
| mappa · torna in patria | Entra nel fronte del guado | Entra nel fronte del guado | Torna all'inizio | Entra nel fronte del guado |
| mappa · entra nel fronte | riga 3, casella 2, tuo Cervo, formazione non arm | riga 3, casella 2, tuo Cervo, formazione non arm | riga 1, casella 1, inesplorato | riga 3, casella 2, tuo Cervo, formazione non arm |
| mappa · marcia: destinazione da scegliere | riga 4, casella 3, tuo Lupo, in attesa, composta | riga 4, casella 3, tuo Lupo, in attesa, composta | riga 4, casella 3, tuo Lupo, in attesa, composta | riga 4, casella 3, tuo Lupo, in attesa, composta |
| mappa · marcia revocata | riga 4, casella 3, tuo Lupo, ha agito, composta  | riga 4, casella 3, tuo Lupo, ha agito, composta  | riga 4, casella 3, tuo Lupo, ha agito, composta  | riga 4, casella 3, tuo Lupo, ha agito, composta  |
| mappa · presidio ordinato | riga 4, casella 2, tuo Corvo, ha agito, composta | riga 4, casella 2, tuo Corvo, ha agito, composta | riga 4, casella 2, tuo Corvo, ha agito, composta | riga 4, casella 2, tuo Corvo, ha agito, composta |
| mappa · divisione compiuta | riga 1, casella 1, inesplorato | riga 4, casella 4, tuo Falco, ha agito, composta | riga 1, casella 1, inesplorato | riga 4, casella 4, tuo Falco, ha agito, composta |
| mappa · riunione compiuta | riga 4, casella 4, tuo Falco, ha agito, composta | riga 4, casella 4, tuo Falco, ha agito, composta | riga 4, casella 4, tuo Falco, ha agito, composta | riga 4, casella 4, tuo Falco, ha agito, composta |
| mappa · esplorazione compiuta | riga 4, casella 1, tuo Orso, formazione di ricog | riga 4, casella 1, tuo Orso, formazione di ricog | riga 4, casella 1, tuo Orso, formazione di ricog | riga 4, casella 1, tuo Orso, formazione di ricog |
| scontro · apertura dello scontro | Riserve da schierare | Riserve da schierare | Riserve da schierare | Riserve da schierare |
| scontro · movimento: destinazione da scegliere | riga 10, cella 4, tua fanteria leggera A, bersag | riga 10, cella 4, tua fanteria leggera A, bersag | riga 10, cella 4, tua fanteria leggera A, bersag | riga 10, cella 4, tua fanteria leggera A, bersag |
| scontro · evacuazione che conclude lo scontro | Perdite inflitte: 0 punti | Perdite inflitte: 0 punti | riga 9, cella 4, libera | Resoconto della battaglia |
| battaglia · la battaglia aperta dalla casella | riga 1, cella 2, libera | Riserve da schierare | riga 1, cella 2, libera | Riserve da schierare |
| battaglia · evacuazione che conclude la battaglia | Scariche residue dei tuoi tiratori: 0 | Scariche residue dei tuoi tiratori: 0 | riga 10, cella 5, libera | Resoconto della battaglia |
| battaglia · ritorno sulla mappa dopo la battaglia | riga 1, casella 2, formazione avversaria, quarti | riga 2, casella 2, tuo Corvo, ha agito, senza pr | riga 1, casella 2, formazione avversaria, quarti | riga 2, casella 2, tuo Corvo, ha agito, senza pr |
| conclusione · giornata chiusa (3) | Campagna conclusa | Campagna conclusa | Campagna conclusa | Campagna conclusa |
| mappa · divisione aperta dal pannello | — | Dividi Falco | — | Dividi Falco |
| presa · ritorno in patria dopo la presa | — | Anno 1, primavera | — | Anno 1, primavera |
| subita · ritorno in patria dopo la caduta | — | Anno 1, primavera | — | Anno 1, primavera |
| richiamo · richiamo compiuto | — | Campagna conclusa | — | Campagna conclusa |
| richiamo · ritorno in patria dopo il richiamo | — | Registro della patria | — | Anno 1, primavera |
| velocita · comincia l'inverno, voce al 90 per cento | — | Anno 1, inverno, schermata 1 di 4 | — | Anno 1, inverno, schermata 1 di 4 |
| velocita · addestramento ordinato, voce al 90 per cento | — | Addestramento mirato. Si sceglie il reparto. Acc | — | Addestramento mirato. Si sceglie il reparto. Acc |
| velocita · apertura della campagna, voce al 90 per cento | — | riga 3, casella 2, tuo Cervo, formazione non arm | — | riga 3, casella 2, tuo Cervo, formazione non arm |

«—» vale per i passi misurati soltanto dopo: le cose nuove di questo incarico, e le prove a voce veloce. «Superato dal gioco» è la conferma della chiusura che conclude la campagna, superata per scelta dall'annuncio della conclusione (A §11.6, S30e), prima e dopo.

## Le battaglie che non finiscono, la frequenza, lo squilibrio: prima e dopo

Strumenti: `StrumentoVerifica` (`--frequenza-battaglie 200 --giornate-massime 730`, `--regno 200 --anni 5`, `--duelli`, e gli stessi con `--tattico-pari`), poi `P/tabelle.py`. Dati grezzi: `P/frequenza-battaglie/`, `P/banco-del-regno/`, `P/squilibrio/`. «Prima» è il codice della build 32.

### 1. Le battaglie che non finiscono

| misura |  | partite o anni | fermi su una battaglia che non finisce | causa | con violazioni |
|---|---|---|---|---|---|
| frequenza (730 giornate) | prima | 1200 | 33 | selezione_alternata: 33 | 0 |
| frequenza (730 giornate) | dopo | 1800 | 0 | — | 0 |
| frequenza (730 giornate) | pari | 1800 | 0 | — | 0 |
| banco del regno (5 anni) | prima | 1829 | 78 | selezione_alternata: 78 | 0 |
| banco del regno (5 anni) | dopo | 3000 | 0 | — | 0 |
| banco del regno (5 anni) | pari | 3000 | 0 | — | 0 |

### 2. La frequenza delle battaglie

| condotta | mappa |  | partite | battaglie | ogni 10 giornate | prima battaglia (mediana) | senza battaglie | avversario senza armati | giocatore senza armati | al limite | ferme |
|---|---|---|---|---|---|---|---|---|---|---|---|
| competente | piccola (guado) | prima | 200 | 398 | 0,038 | 18 | 13 | 10 | 52 | 137 | 1 |
| competente | piccola (guado) | dopo | 200 | 847 | 0,102 | 18 | 12 | 97 | 1 | 102 | 0 |
| competente | media (istmo) | prima | 200 | 1357 | 0,104 | 68,5 | 116 | 0 | 0 | 175 | 25 |
| competente | media (istmo) | dopo | 200 | 2674 | 0,183 | 69 | 105 | 0 | 0 | 200 | 0 |
| competente | grande (pianura lunga) | prima | 200 | 245 | 0,019 | 55,5 | 120 | 16 | 0 | 177 | 7 |
| competente | grande (pianura lunga) | dopo | 200 | 122 | 0,010 | 57 | 116 | 32 | 0 | 168 | 0 |
| prudente | piccola (guado) | prima | 200 | 200 | 0,014 | 4 | 0 | 0 | 0 | 200 | 0 |
| prudente | piccola (guado) | dopo | 200 | 400 | 0,027 | 4 | 0 | 0 | 0 | 200 | 0 |
| prudente | media (istmo) | prima | 200 | 415 | 0,028 | 11 | 0 | 0 | 0 | 200 | 0 |
| prudente | media (istmo) | dopo | 200 | 200 | 0,014 | 11 | 0 | 0 | 0 | 200 | 0 |
| prudente | grande (pianura lunga) | prima | 200 | 0 | 0,000 | — | 200 | 0 | 0 | 200 | 0 |
| prudente | grande (pianura lunga) | dopo | 200 | 0 | 0,000 | — | 200 | 0 | 0 | 200 | 0 |
| mirata | piccola (guado) | dopo | 200 | 31218 | 4,159 | 10 | 0 | 100 | 0 | 100 | 0 |
| mirata | media (istmo) | dopo | 200 | 524 | 0,036 | 20 | 0 | 0 | 0 | 200 | 0 |
| mirata | grande (pianura lunga) | dopo | 200 | 714 | 0,508 | 15 | 0 | 191 | 0 | 9 | 0 |

### 3. Lo squilibrio fra le mappe: le battaglie vinte dal giocatore

In ogni cella: le battaglie vinte su quelle giocate e, dopo il punto e virgola, le sole COMBATTUTE, cioè quelle in cui almeno una delle due parti ha perso un atomo. Le altre si concludono coi reparti intatti: prima, perché una parte era annientata al suo primo comando (il difetto del budget del primo turno); dopo, perché i due schieramenti non possono incontrarsi e l'avversario si ritira (lo stallo, 01 §10.7.1).



Campagne di prova (misura della frequenza, 200 partite per cella, 730 giornate):


| condotta | mappa | prima | dopo | pari |
|---|---|---|---|---|
| competente | piccola (guado) | 7 su 398 (1,8%); combattute 7 su 398 (1,8%) | 123 su 847 (14,5%); combattute 123 su 650 (18,9%) | 163 su 450 (36,2%); combattute 163 su 450 (36,2%) |
| competente | media (istmo) | 1307 su 1357 (96,3%); combattute 0 su 0 (—) | 2583 su 2674 (96,6%); combattute 59 su 150 (39,3%) | 2646 su 2701 (98,0%); combattute 70 su 125 (56,0%) |
| competente | grande (pianura lunga) | 16 su 245 (6,5%); combattute 16 su 78 (20,5%) | 33 su 122 (27,0%); combattute 33 su 122 (27,0%) | 44 su 106 (41,5%); combattute 44 su 106 (41,5%) |
| prudente | piccola (guado) | 0 su 200 (0,0%); combattute 0 su 200 (0,0%) | 0 su 400 (0,0%); combattute 0 su 400 (0,0%) | 0 su 200 (0,0%); combattute 0 su 200 (0,0%) |
| prudente | media (istmo) | 393 su 415 (94,7%); combattute 0 su 0 (—) | 0 su 200 (0,0%); combattute 0 su 200 (0,0%) | 0 su 200 (0,0%); combattute 0 su 200 (0,0%) |
| prudente | grande (pianura lunga) | 0 su 0 (—); combattute 0 su 0 (—) | 0 su 0 (—); combattute 0 su 0 (—) | 0 su 0 (—); combattute 0 su 0 (—) |
| mirata | piccola (guado) | non giocata | 100 su 31218 (0,3%); combattute 100 su 700 (14,3%) | 263 su 363 (72,5%); combattute 263 su 363 (72,5%) |
| mirata | media (istmo) | non giocata | 201 su 524 (38,4%); combattute 1 su 324 (0,3%) | 201 su 428 (47,0%); combattute 1 su 228 (0,4%) |
| mirata | grande (pianura lunga) | non giocata | 169 su 714 (23,7%); combattute 169 su 713 (23,7%) | 198 su 435 (45,5%); combattute 198 su 435 (45,5%) |


Campagne del regno (banco del regno, 200 partite di 5 anni per condotta):


| condotta | mappa | prima | dopo | pari |
|---|---|---|---|---|
| competente | guado | 115 su 716 (16,1%); combattute 115 su 605 (19,0%) | 124 su 585 (21,2%); combattute 124 su 581 (21,3%) | 185 su 497 (37,2%); combattute 185 su 497 (37,2%) |
| competente | istmo | 289 su 305 (94,8%); combattute 0 su 0 (—) | 183 su 280 (65,4%); combattute 30 su 127 (23,6%) | 177 su 248 (71,4%); combattute 28 su 98 (28,6%) |
| competente | pianura lunga | 16 su 178 (9,0%); combattute 16 su 119 (13,4%) | 36 su 224 (16,1%); combattute 36 su 224 (16,1%) | 48 su 183 (26,2%); combattute 48 su 183 (26,2%) |
| prudente | guado | 66 su 529 (12,5%); combattute 66 su 529 (12,5%) | 200 su 1130 (17,7%); combattute 200 su 1130 (17,7%) | 200 su 664 (30,1%); combattute 200 su 664 (30,1%) |
| prudente | istmo | 695 su 740 (93,9%); combattute 0 su 0 (—) | 0 su 1069 (0,0%); combattute 0 su 1069 (0,0%) | 0 su 735 (0,0%); combattute 0 su 735 (0,0%) |
| prudente | pianura lunga | 0 su 1116 (0,0%); combattute 0 su 196 (0,0%) | 0 su 201 (0,0%); combattute 0 su 201 (0,0%) | 0 su 135 (0,0%); combattute 0 su 135 (0,0%) |
| mirata | guado | non giocata | 284 su 1383 (20,5%); combattute 284 su 1140 (24,9%) | 333 su 725 (45,9%); combattute 333 su 725 (45,9%) |
| mirata | istmo | non giocata | 277 su 1244 (22,3%); combattute 42 su 976 (4,3%) | 332 su 962 (34,5%); combattute 94 su 724 (13,0%) |
| mirata | pianura lunga | non giocata | 268 su 1131 (23,7%); combattute 268 su 1113 (24,1%) | 262 su 616 (42,5%); combattute 262 su 616 (42,5%) |


Le campagne del regno vinte e perse dal giocatore (le altre le interrompe l'inverno; «prima», in 78 anni, la partita si fermava):


| condotta | mappa | prima | dopo | pari |
|---|---|---|---|---|
| competente | guado | 40,7% vinte, 0,0% perse | 40,5% vinte, 25,2% perse | 44,4% vinte, 22,8% perse |
| competente | istmo | 0,0% vinte, 0,0% perse | 3,0% vinte, 2,1% perse | 2,4% vinte, 2,1% perse |
| competente | pianura lunga | 5,9% vinte, 0,0% perse | 10,2% vinte, 4,2% perse | 10,8% vinte, 4,8% perse |
| prudente | guado | 19,8% vinte, 0,0% perse | 60,1% vinte, 0,0% perse | 60,1% vinte, 0,3% perse |
| prudente | istmo | 0,0% vinte, 0,0% perse | 0,0% vinte, 0,0% perse | 0,0% vinte, 0,0% perse |
| prudente | pianura lunga | 0,0% vinte, 0,0% perse | 0,0% vinte, 0,0% perse | 0,0% vinte, 0,0% perse |
| mirata | guado | non giocata | 85,9% vinte, 0,0% perse | 99,7% vinte, 0,0% perse |
| mirata | istmo | non giocata | 82,6% vinte, 0,0% perse | 98,5% vinte, 0,0% perse |
| mirata | pianura lunga | non giocata | 82,3% vinte, 0,0% perse | 78,4% vinte, 0,0% perse |

I duelli fra i gruppi degli scenari e il banco del regno, anno per anno: sezioni 4 e 6 di `P/tabelle.md`.

**La causa delle battaglie che non finivano.** In tutte e 111 la stessa: `TatticoBattaglia.comandoDiPiazzamento` alternava la selezione di due elementi non piazzabili (la diagnosi di ciascuna è nel campo `diagnosi` dei dati «prima», `DiagnosiBattaglia`). Corretta quella (`c8a3d50`), lo stallo fra schieramenti che non possono incontrarsi (`5cc47d8`) e le due forme trovate con le composizioni proposte (`c264837`: una colonna fermata da un proprio reparto, un tattico che provava un passo solo), non ne resta nessuna: zero su 1800 partite e 3000 anni, coi due tattici.

**Lo squilibrio.** La causa è doppia. Tre difetti, corretti: il budget del primo turno (RDA-187), per cui sulla mappa media della build 32 **nessuna battaglia è mai stata combattuta**, tutte si chiudevano al primo comando coi reparti intatti; le unità evacuate perdute (RDA-188); lo stallo (RDA-189). E una parte che dipende dalle composizioni: il gruppo di 24 fanti pesanti e 12 cavalieri, solo gruppo armato dell'avversario sulla mappa media, non può fare un passo in battaglia. Non ho cambiato nulla: proposte con l'effetto misurato in `P/tabelle.md` (sezione 5) e RDA-191; nessuna aggiunge gruppi avversari.

**Le proposte, in breve** (la sezione 5 di `P/tabelle.md` ha tutto):

In breve. Le prime tre colonne: battaglie COMBATTUTE vinte dalla condotta competente nelle campagne di prova, fra parentesi quadre col tattico che non si arrende, e quante battaglie si sono concluse senza che nessuno perdesse un uomo. Le altre tre: campagne del regno vinte dalla condotta mirata. L'ultima: battaglie che non si concludono.


| variante | piccola | media | grande | guado | istmo | pianura lunga | ferme |
|---|---|---|---|---|---|---|---|
| 0-com-e-oggi | 18,9% [36,2%]; 197 senza perdite | 39,3% [56,0%]; 2524 senza perdite | 27,0% [41,5%] | 85,9% | 82,6% | 82,3% | 0 |
| 1-12P-6C | 18,9% [36,2%]; 197 senza perdite | 23,4% [50,3%]; 8 senza perdite | 12,2% [30,1%]; 4 senza perdite | 69,7% | 90,7% | 79,0% | 0 |
| 2-16P-8C | 18,9% [36,2%]; 197 senza perdite | 32,2% [51,5%]; 718 senza perdite | 25,4% [57,3%] | 84,1% | 73,1% | 91,3% | 0 |
| 3-avversario-18L-8P | 18,9% [36,2%]; 197 senza perdite | 18,4% [32,3%]; 1 senza perdite | 12,2% [30,1%]; 4 senza perdite | 65,2% | 71,0% | 84,7% | 0 |
| 4-12P-12P-6C-6C | 18,9% [36,2%]; 197 senza perdite | 7,2% [22,9%]; 327 senza perdite | 8,7% [22,9%]; 5 senza perdite | 83,2% | 66,8% | 83,8% | 0 |
| esce-chi-attacca | 18,9% [36,2%]; 197 senza perdite | 39,3% [56,0%]; 2524 senza perdite | 27,0% [41,5%] | 83,2% | 4,5% | 78,1% | 0 |
| tetto-al-passo | 18,9% [36,2%]; 197 senza perdite | 23,2% [47,7%]; 3 senza perdite | 26,3% [39,8%] | 84,7% | 48,5% | 82,0% | 0 |

**Le tre campagne vinte per annientamento senza una battaglia vinta** (semi 123, 173, 190, guado, condotta competente). Rigiocate sul codice della build 32, con la traccia di ogni battaglia: il giocatore perde tre battaglie perché dichiara la resa, e nella terza l'avversario, che avanza sul ritirante, finisce senza un atomo mentre il giocatore esce con due, quattro e un atomo. Lo sconfitto è chi si ritira (01 §15.2.2), ma l'avversario non ha più gruppi armati, e la campagna è vinta per annientamento: è la regola di 01 §15.2.3.1, non un difetto. Sul codice nuovo quei tre anni finiscono con la presa del quartier generale del giocatore; undici anni su 3000 si chiudono ancora così, tutti con il tattico del banco che si arrende a metà delle perdite, e nessuno col tattico che non si arrende.

## La verifica attraverso l'interfaccia, con VoiceOver

@@VERIFICA@@

## Che cosa è successo durante l'esecuzione

1. **Le vie degli annunci.** Prima di scegliere, una copia di laboratorio con le vie una accanto all'altra (`P/annunci/scelta-della-via/`): la priorità alta è la sola che dice l'annuncio per intero, subito, e poi l'elemento per intero. Quattro tentativi scartati perché ritardano di 5,3 secondi gli annunci che non spostano il fuoco.
2. **Un errore nello strumento, all'inizio**: `strumenta.sh` non strumentava la nuova `pubblica`, e le prime corse «dopo» non registravano nulla; rifatte con un'espressione regolare su ogni `UIAccessibility.post(.announcement…)`. L'abbinamento fra annuncio e tratto di voce è stato riscritto (il primo tratto che finisce all'istante della conclusione notificata, entro 0,4 s; intero se finisce da sé ed è durato almeno tre quarti del più lungo). Il guidatore ereditava da un blocco all'altro i valori messi a punto: ora li riporta alla fabbrica a ogni blocco.
3. **Uno strumento di sistema ha bloccato i simulatori**: all'inizio della sessione `lldb`/`sample` ha aperto un dialogo di autorizzazione di macOS che ha fermato i simulatori accesi. Chiuso il dialogo, non li ho più usati.
4. **Un comando rifiutato**: `rm -f misure/*` dal controllo di sicurezza; non l'ho aggirato, ho usato cartelle nuove e non ho tolto nulla.
5. **Il banco ha trovato i miei difetti**. La prima stesura della presa lasciava le occupazioni dopo la conclusione della campagna (`occupazione_incoerente` al banco): `concludi` le azzera. La sonda degli invarianti e il banco avevano la stessa cecità sugli evacuati, e per questo il difetto non si vedeva: il banco ora li conta per proprio conto. Il primo criterio dello stallo, «nessuno può agire», teneva conto degli spostamenti laterali e lasciava battaglie aperte: sostituito dal criterio della distanza, poi affiancato da «nessuno può più avvicinarsi».
6. **Le proposte hanno trovato una terza causa**: misurando la composizione a quattro reparti, 27 e 37 anni si fermavano («attesa reciproca»). Due cause: il tattico provava un passo solo (corretta), e una colonna fermata dal proprio reparto di testa (corretta). Dopo, zero.
7. **I commit `5cc47d8` e `f3c2c9a`** sono stati spinti prima di rieseguire l'intera suite sull'albero; la suite intera è stata rieseguita verde subito dopo, al commit `c264837` (604 prove del pacchetto, 0 fallite).
8. **Le mutazioni hanno trovato un buco**: «perdere la battaglia non azzera» sopravviveva, perché il caso dell'occupante battuto che non può ripiegare non era provato. Aggiunta la prova, la mutazione muore.
9. **Una prova ospitata rossa** dopo la correzione del fuoco (`PatriaTest`, la dichiarazione di conclusione prende ora il fuoco da sé e la prova azzerava il registro troppo presto): la prova adesso pretende il fuoco sul titolo, non è stata indebolita.
10. **La misura ha trovato due volte che la mia correzione non bastava.** La prima stesura del resoconto chiedeva il fuoco alla cella e poi al titolo quattro decimi dopo: sull'iPhone il fuoco restava su «Perdite inflitte: 0 punti». Ora un comando del pannello si esegue prima di chiedere il fuoco, che non va alla cella se il comando ha concluso la battaglia o la campagna. La seconda: la battaglia si annunciava alla fine del caricamento, e una volta su quattro sull'iPhone usciva 20 millisecondi prima della richiesta del fuoco, a priorità predefinita, e spariva. Ora si annuncia alla comparsa, come la mappa.
11. **Una misura sotto carico non vale**: con dieci simulatori accesi insieme al collaudo, i tratti di voce si allungavano e un annuncio risultava senza voce pur essendo concluso con successo. Le misure della tabella sono di una macchina con al più quattro simulatori; il punto 10 è stato trovato da quella sotto carico, e confermato da quella buona.
12. **Il tester ha richiesto più corse.** Su iPhone il pilota è caduto una volta su un elemento che XCUITest non sapeva toccare («unable to compute coordinates», fotogramma infinito) appena tornati dalla battaglia: ora lo dichiara, e il tester riprova. Il tester del richiamo è ripartito quattro volte per errori miei di guida (andava a contatto con un gruppo circondato dai propri; oscillava fra due caselle; non vedeva il nemico e restava fermo; non riportava indietro chi era rimasto tagliato): le corse scartate sono in `Applicazione/build-interattivo/lab-32/scartati/`, che non si consegna.
13. **Un controllo sbagliato, non il gioco**: il percorso «subita» e il punto 02 §6.5.1.4 aspettavano «L'avversario occupa il tuo quartier generale, sarà preso…», la frase dello stato è «Il tuo quartier generale è occupato, sarà preso…». Corretti il controllo e il documento.
14. **Il fuoco al ritorno in patria** dopo la dichiarazione di conclusione è finito una volta su sei sull'iPhone su «Registro della patria»: ora attende quello del sistema. Trovato nei dati della misura, non nel compito.
15. **Il tester ha preso il quartier generale in una battaglia che nessuno ha combattuto**: «Perdite tue: 0 punti su 3360 impegnati. Perdite inflitte: 0 punti». È il caso dichiarato in S30c: sull'istmo l'avversario, ingombrante, si ritira.

## Le versioni: la valutazione

**Valori: 0.16.0**, con la 0.15.0 fra le compatibili (RDA-190). **Schemi: battaglia 2, campagna 9, regno 2, fermi.** Una riga nuova del giornale di campagna (`richiamoDellEsercito`) che nessun giornale esistente contiene; nessuna riga esistente cambia significato. Le partite salvate con la build 32 si riaprono: una campagna in corso prosegue con le regole con cui è nata (i giornali non contengono né gli arrivi né le occupazioni, che si ricalcolano), la prossima campagna del regno ha le regole nuove, uno scontro chiuso dal difetto del primo turno torna da giocare. Le note lo dicono. Verificato in due modi: con giornali e istantanee scritti dal codice della build 32 (`SalvataggiBuild32Test`) e dal vivo, con l'app di `06dee59` e la nuova installata sopra (`P/salvataggi-build-32/`, 12 controlli su 12).

## Le decisioni prese da solo, e perché

1. **La priorità alta soltanto per gli annunci che accompagnano uno spostamento** (RDA-183), e una finestra di due secondi dall'ultima richiesta del fuoco. Alternative misurate e scartate con il perché.
2. **La chiusura in cui si entra nel quartier generale non conta**, e otto altre letture della presa che il testo della decisione non contiene (RDA-184): la contesa non conta e non azzera; l'occupante battuto azzera anche restando; occupano i soli armati; preso resta preso; la presa precede l'inverno nella stessa chiusura; le battaglie in sospeso altrove non si combattono più; nella caduta simultanea vince il giocatore, come nell'annientamento simultaneo.
3. **Le regole della presa viaggiano con la campagna** (`RegoleDiCampagna` nello scenario), e le campagne di prova non ne dichiarano: senza un calendario e una patria non hanno una fine, e la decisione non le nomina (S30a).
4. **Nello stallo se ne va sempre l'avversario** (RDA-189). Misurata l'alternativa, chi attacca: sull'istmo le campagne vinte passerebbero dall'82,6% al 4,5%, e il giocatore che attacca resterebbe in una battaglia da cui si esce soltanto arrendendosi.
5. **Il budget del primo turno corregge RDA-140** (RDA-187), e per questo i valori salgono a 0.16.0 con la 0.15.0 compatibile. Non ho dichiarato incompatibili gli scontri salvati: chi ne aveva uno chiuso da quel difetto lo ritrova da giocare.
6. **Gli evacuati tornano in campagna** (RDA-188). L'incarico chiedeva la causa dello squilibrio: questa ne è una delle cause, ed era contraria a 01 §10.4.
7. **L'annientamento simultaneo della campagna legge il vantaggio nascosto dal file** (`9a0ae50`): S28f lo lasciava alla conclusione definitiva, che è questa.
8. **I dieci rifacimenti del tester e del pilota non si consegnano**: sono guida sbagliata, non prove.

## Modifiche, per commit

@@MODIFICHE@@

## Ciò che ho fatto senza che fosse chiesto

- Il fuoco in testa alla battaglia e alla divisione aperte dal pannello, al resoconto, alla dichiarazione di conclusione, e il comando dato da un pannello che si esegue prima di chiedere il fuoco (`805e42e`, `35127d2`): trovato dalla misura.
- La battaglia che si annuncia alla comparsa (`e9f702e`) e il ritorno in patria che attende il sistema: idem.
- `sciamiEvacuati`, il costo del ritiro che non eccede un turno, il tattico che prova ogni passo che avvicina, le altre due forme dello stallo: cause dello squilibrio e delle battaglie senza fine.
- Le alternative misurate (chi attacca esce dallo stallo; il tetto al costo del passo) e quattro composizioni proposte, oltre a quella richiesta.
- L'annientamento simultaneo della campagna nel file dei vantaggi nascosti (S28f).
- Il pilota non cade più su un elemento non toccabile (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`); il tester ha due modi nuovi (`scripts/tester.py`).
- Lo strumento di verifica: `--tattico-pari`, `--duelli`, il conto delle battaglie che nessuno combatte.

## Ciò che era chiesto e non ho fatto

- **Nulla di ciò che l'incarico chiede è rimasto fuori**, con questa precisazione: per i duelli e le composizioni proposte ho conservato i conti per cella, non i dati grezzi di ogni partita, perché pesano e la corsa è deterministica e ripetibile con un comando (`P/squilibrio/proposte.py`).
- La coalescenza degli annunci di fondo per contenuto (A §11.6), che l'incarico non chiede: resta da costruire (S30f).

## Scoperto, cioè non automatizzato, con le vie tentate

- **La velocità della voce, per il giudizio a orecchio.** Il pilota misura i tratti, non l'ascolto: che un annuncio si capisca al 90 per cento lo dicono i tester.
- **Un apparecchio vero.** Le misure sono sui simulatori; che su un iPhone la finestra di due secondi basti non si può dire da qui. La scelta di una finestra larga è per questo.
- **Il caso di due fortezze** è provato sul Motore e nei segnali, non nell'interfaccia: nessuna fortezza esiste nel gioco (S30b).
- **Una presa subita dal tester**, cioè l'avversario che prende il quartier generale giocando da sé: è provata dal percorso «subita» (con le formazioni messe dai dati) e dal banco, non da una partita giocata interamente dall'avversario contro il tester.

## App Store Connect

@@ASC@@

## Tempi

@@TEMPI@@

## Integrazione continua

@@CI@@

