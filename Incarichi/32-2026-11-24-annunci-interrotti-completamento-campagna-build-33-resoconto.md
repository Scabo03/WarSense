# Incarico 32 — resoconto

`P/` sta per `Incarichi/32-2026-11-24-prodotti/`.

## In testa

- **La build 33 è uscita**, compilata da `c5bcb09` (caricata da `d2cc8a8`), valida su App Store Connect e nel gruppo WarLab, con la nota allegata. Il primo tentativo si è fermato nel collaudo che lo script rifà prima di archiviare: una prova intermittente che falliva anche sulla build 32, corretta.
- **Gli annunci che accompagnano un cambio di schermata o di fuoco si dicono per intero.** Prima se ne sentiva per intero 9 su 28 sull'iPhone e 8 su 28 sull'iPad; dopo, gli stessi 28 e i 3 nuovi: 31 su 31 sui due apparecchi. Gli annunci che non spostano il fuoco restano interi (33 su 33 prima, 68 su 68 dopo). La via: priorità alta soltanto per quelli che accompagnano uno spostamento, misurata contro altre sette (RDA-183). La tabella per annuncio e per apparecchio è più sotto.
- **Il fuoco arriva dove il gioco lo chiede.** Lo ha mostrato la ripetizione: al ritorno in patria sull'iPhone, sul codice che credevo corretto, era sbagliato 7 volte su 16; ora mai (RDA-192).
- **La presa del quartier generale e il richiamo dell'esercito sono costruiti**, con gli annunci per le due parti, l'avversario che usa la regola e se ne difende, e gli invarianti. Il tester con VoiceOver ha preso un quartier generale e richiamato l'esercito, su iPhone e su iPad.
- **Le battaglie che non finiscono sono zero** su 1800 partite e 3000 anni (erano 33 e 78); la causa era una sola, più tre forme di stallo trovate strada facendo.
- **Lo squilibrio fra le mappe è spiegato**: sulla mappa media della build 32 nessuna battaglia è stata mai combattuta, per un difetto corretto; resta una parte che dipende dalle composizioni, e per quella ho solo proposto numeri, misurati.
- **Le partite salvate con la build 32 si riaprono**: valori 0.16.0 con la 0.15.0 compatibile, schemi fermi.
- **Le decisioni da prendere dal titolare**: quale delle proposte per lo stallo sulla mappa media, e se tre giornate per la presa vanno bene.

## Lo stato di partenza, verificato

`git rev-parse principale origin/principale`: `06dee59` entrambi; `git status --short` vuoto; un solo ramo remoto. Valori 0.15.0 (`Codice/Sources/Contenuti/Valori/manifest.json`); schemi 2, 9 e 2 (`grep schemaCorrente`); ultimo RDA 182, ultimo scostamento S29q. Tutto come l'incarico lo dichiara. App Store Connect, per API: build 32 `VALID`, treno 1.1.0.

## Le versioni della macchina

macOS 27.0.1 (26A434), Xcode 27.2 (27B52), Swift 6.4.2, xcodegen 2.45.4, Python 3.9.6; Apple M5 Pro, 15 processori. Simulatori iOS 27.0 (24A434), tutti di WarSense: iPhone Air C86CB490… e iPad Pro 13 D01FE19F… per il collaudo; iPhone 76DF33B6…, E2C6F42C…, 87AB2F55…, 4CD3DC60… e iPad 8D3583DB…, 75A249BF…, 1DF852F1…, 2B3AB121… per il pilota e il tester. Nessun simulatore, processo o finestra altrui toccato. Nessun sotto-agente usato.

## Per ogni punto: il commit e la prova

| punto dell'incarico | commit | prove |
|---|---|---|
| L'annuncio interrotto (S29q, a) | `84f95f9`, `805e42e`, `35127d2`, `e9f702e`, `c5bcb09` | `CodaAnnunciTest` (13); `ConfiniTest` (`test_00_5_3_…`, `test_02_5_5_1_…`); `ConfermaDelFuocoTest` (6); `OsservazioniTesterTest.test_02_5_5_1_…`; `PannelloAzioniTest.test_02_5_7_…`; `PassaggioBattagliaInterfacciaTest.test_02_2_9_…` (due); `PatriaTest`; la misura col pilota e il conto del fuoco (sotto) |
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

Le 95 prove nuove o rifatte del ramo (`git diff 06dee59..HEAD`), salvo il generatore delle fixture, si sono viste fallire: lo dice, nome per nome, il controllo di `P/cancelli-visti-fallire/`, dove sta la mutazione e l'uscita. Il controllo che lo diceva prima contava anche le prove passate: con quello giusto ne mancavano venti (punto 9 dell'esecuzione).

## Gli annunci: i tempi prima e dopo, per annuncio e per apparecchio

Strumento: `P/annunci/misura-annunci.py` sulla copia strumentata dell'app (aggiunge il solo registro), `P/annunci/tabella.py` per la tabella; dati grezzi in `P/annunci/misure-grezze/`. «Prima» è `06dee59`, «dopo» il codice della build (`c5bcb09`), misurato per intero, undici blocchi, sull'iPhone e sull'iPad. Ogni cella: per quanto la voce ha detto l'annuncio, e se l'ha detto intero. Le vie considerate e la loro misura: `P/annunci/scelta-della-via/README.md`; la scelta e il perché: RDA-183.

### Riassunto

| | iPhone prima | iPhone dopo | iPad prima | iPad dopo |
|---|---|---|---|---|
| Con spostamento: interi su detti | 9 su 28 | 31 su 31 | 8 su 28 | 31 su 31 |
| Senza spostamento: interi su detti | 33 su 33 | 68 su 68 | 33 su 33 | 68 su 68 |

### Annunci che accompagnano uno spostamento del fuoco o un cambio di schermata

| Quando | Annuncio (caratteri) | iPhone prima | iPhone dopo | iPad prima | iPad dopo |
|---|---|---|---|---|---|
| regno · comincia l'inverno | «Comincia l'inverno dell'anno 1. Entrate: monete di bronzo 200, uomini 24, metalli 30, mate…» (175) | 0.01 s interrotto | 14.18 s intero | 0.00 s interrotto | 14.17 s intero |
| regno · addestramento ordinato dalla scelta del reparto | «Addestramento mirato ordinato per 8 atomi di fanteria pesante di Lupo: pronto in primavera…» (91) | 0.75 s interrotto | 5.53 s intero | 0.77 s interrotto | 5.52 s intero |
| regno · scelta impedita rifiutata | «Non si può ordinare: mancano monete di bronzo.» (46) | 0.77 s interrotto | 3.05 s intero | 0.77 s interrotto | 3.06 s intero |
| regno · comincia la primavera | «Comincia la primavera dell'anno 2. Il riporto ha tolto: monete di bronzo 73, uomini 24, me…» (206) | 0.00 s interrotto | 15.07 s intero | 0.06 s interrotto | 15.07 s intero |
| regno · apertura della campagna dal regno | «Campagna aperta sul fronte del guado» (36) | 0.80 s interrotto | 2.32 s intero | 0.78 s interrotto | 2.32 s intero |
| regno · apertura della campagna dal regno | «Mappa Guado, 4 righe per 4 caselle. Il tuo quartier generale è in riga 4, casella 2» (83) | 6.29 s intero | 6.28 s intero | 6.33 s intero | 6.26 s intero |
| regno · apertura della campagna dal regno | «Anno 2, primavera, mancano 89 giornate all'inverno. Giorno 1. Nessun gruppo ha ancora agit…» (99) | 7.97 s intero | 7.92 s intero | 8.06 s intero | 7.92 s intero |
| mappa · entra nel fronte | «Mappa Guado, 4 righe per 4 caselle. Il tuo quartier generale è in riga 4, casella 2» (83) | 0.78 s interrotto | 6.27 s intero | 0.00 s interrotto | 6.27 s intero |
| mappa · entra nel fronte | «Anno 2, primavera, mancano 89 giornate all'inverno. Giorno 1. Nessun gruppo ha ancora agit…» (99) | 7.93 s intero | 7.92 s intero | 0.79 s interrotto | 7.94 s intero |
| mappa · marcia: destinazione da scegliere | «Scegli la casella di destinazione e attivala per dare l'ordine di marcia. Il gruppo rester…» (163) | 0.73 s interrotto | 8.95 s intero | 0.78 s interrotto | 8.96 s intero |
| mappa · marcia revocata | «Lupo: marcia revocata, persi 0 giorni» (37) | 0.79 s interrotto | 3.26 s intero | 0.78 s interrotto | 3.26 s intero |
| mappa · presidio ordinato | «Corvo presidia in riga 4, casella 2» (35) | 0.79 s interrotto | 2.85 s intero | 0.78 s interrotto | 2.86 s intero |
| mappa · divisione compiuta | «Nuovo gruppo Lince in riga 3, casella 4» (39) | 0.79 s interrotto | 3.04 s intero | 0.78 s interrotto | 3.02 s intero |
| mappa · riunione compiuta | «Falco riunito in riga 4, casella 4» (34) | 0.79 s interrotto | 3.19 s intero | 0.77 s interrotto | 3.19 s intero |
| mappa · esplorazione compiuta | «Orso ha esplorato la zona attorno a riga 4, casella 1» (53) | 0.79 s interrotto | 3.76 s intero | 0.78 s interrotto | 3.76 s intero |
| scontro · apertura dello scontro | «Battaglia su WarSense, 10 righe per 10 celle. Il campo è campo aperto, ostacolo» (79) | 0.02 s interrotto | 6.00 s intero | 0.77 s interrotto | 6.00 s intero |
| scontro · movimento: destinazione da scegliere | «Scegli la cella di destinazione e attivala per confermare» (57) | 0.79 s interrotto | 3.34 s intero | 0.78 s interrotto | 3.34 s intero |
| scontro · evacuazione che conclude lo scontro | «Unità evacuata: costa 52» (24) | 0.77 s interrotto | 2.54 s intero | 0.78 s interrotto | 2.54 s intero |
| scontro · evacuazione che conclude lo scontro | «La battaglia è conclusa: la ritirata è compiuta» (47) | 3.13 s intero | 3.13 s intero | 3.13 s intero | 3.13 s intero |
| battaglia · la battaglia aperta dalla casella | «Battaglia su WarSense, 10 righe per 10 celle. Il campo è campo aperto» (69) | 0.78 s interrotto | 5.05 s intero | 0.77 s interrotto | 5.06 s intero |
| battaglia · la battaglia aperta dalla casella | «Entra in campo fanteria leggera A avversaria in riga 1, cella 5» (63) | 4.33 s intero | 4.21 s intero | 4.26 s intero | 4.22 s intero |
| battaglia · la battaglia aperta dalla casella | «Turno 2, agisce l'avversario» (28) | 2.22 s intero | 2.21 s intero | 2.20 s intero | 2.20 s intero |
| battaglia · la battaglia aperta dalla casella | «Turno 3, agisce l'avversario» (28) | 2.13 s intero | 2.18 s intero | 2.19 s intero | 2.18 s intero |
| battaglia · la battaglia aperta dalla casella | «Turno 3, tocca a te» (19) | 1.53 s intero | 1.52 s intero | 1.57 s intero | 1.52 s intero |
| battaglia · evacuazione che conclude la battaglia | «Unità evacuata: costa 60» (24) | 0.79 s interrotto | 2.55 s intero | 0.78 s interrotto | 2.55 s intero |
| battaglia · evacuazione che conclude la battaglia | «La battaglia è conclusa: la ritirata è compiuta» (47) | 3.14 s intero | 3.13 s intero | 3.13 s intero | 3.13 s intero |
| battaglia · ritorno sulla mappa dopo la battaglia | «Battaglia persa in riga 1, casella 2» (36) | 0.77 s interrotto | 2.62 s intero | 0.77 s interrotto | 2.62 s intero |
| conclusione · giornata chiusa (3) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | superato dal gioco | superato dal gioco | superato dal gioco | superato dal gioco |
| conclusione · giornata chiusa (3) | «È arrivato l'inverno: la campagna è conclusa, senza vincitore» (61) | 0.00 s interrotto | 4.25 s intero | 0.00 s interrotto | 4.24 s intero |
| presa · giornata chiusa (4) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | superato dal gioco | — | superato dal gioco |
| presa · giornata chiusa (4) | «Campagna conclusa: il quartier generale avversario è caduto. Hai vinto» (70) | — | 4.57 s intero | — | 4.57 s intero |
| subita · giornata chiusa (4) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | superato dal gioco | — | superato dal gioco |
| subita · giornata chiusa (4) | «Campagna conclusa: il tuo quartier generale è caduto. Hai perso» (63) | — | 4.19 s intero | — | 4.19 s intero |
| richiamo · richiamo compiuto | «Campagna conclusa: hai richiamato l'esercito in patria. Conta come perduta» (74) | — | 4.89 s intero | — | 4.89 s intero |

### Annunci che non spostano il fuoco

| Quando | Annuncio (caratteri) | iPhone prima | iPhone dopo | iPad prima | iPad dopo |
|---|---|---|---|---|---|
| regno · resta in patria (riga attivata) | «Corvo resta in patria.» (22) | 1.55 s intero | 1.55 s intero | 1.55 s intero | 1.56 s intero |
| regno · torna al fronte (riga attivata) | «Corvo parte per il fronte.» (26) | 1.80 s intero | 1.82 s intero | 1.81 s intero | 1.81 s intero |
| regno · leva ordinata | «Leva di fanteria leggera ordinata: pronta in primavera.» (55) | 3.42 s intero | 3.42 s intero | 3.41 s intero | 3.42 s intero |
| regno · spesa annullata | «Leva di fanteria leggera: ordine annullato, risorse restituite.» (63) | 4.26 s intero | 4.26 s intero | 4.26 s intero | 4.26 s intero |
| mappa · marcia ordinata sulla casella | «Lupo marcia verso riga 3, casella 3, 2 giorni al termine» (56) | 4.22 s intero | 4.21 s intero | 4.22 s intero | 4.22 s intero |
| mappa · ultimo ordine annullato | «Ultimo ordine annullato» (23) | 1.61 s intero | 1.61 s intero | 1.61 s intero | 1.61 s intero |
| mappa · giornata chiusa dal comando | «Giornata chiusa. 2 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | 6.80 s intero | 6.80 s intero | 6.79 s intero | 6.76 s intero |
| mappa · giornata chiusa dal comando | «Giornata conclusa: comincia il giorno 2» (39) | 2.76 s intero | 2.75 s intero | 2.76 s intero | 2.75 s intero |
| mappa · tocco magico sulla mappa | «Anno 2, primavera, mancano 88 giornate all'inverno. Giorno 2. Nessun gruppo ha ancora agit…» (99) | 7.85 s intero | 7.84 s intero | 7.85 s intero | 7.85 s intero |
| scontro · piazzamento confermato | «Piazzato: costa 50, restano 310» (31) | 3.92 s intero | 3.92 s intero | 3.93 s intero | 3.91 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Turno 1, agisce l'avversario» (28) | 2.18 s intero | 2.17 s intero | 2.18 s intero | 2.18 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria leggera A avversaria in riga 1, cella 5» (63) | 4.22 s intero | 4.22 s intero | 4.23 s intero | 4.22 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria leggera B avversaria in riga 1, cella 6» (63) | 4.06 s intero | 4.06 s intero | 4.07 s intero | 4.06 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria leggera C avversaria in riga 1, cella 4» (63) | 4.36 s intero | 4.36 s intero | 4.36 s intero | 4.37 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria pesante D avversaria in riga 1, cella 7» (63) | 4.35 s intero | 4.36 s intero | 4.34 s intero | 4.35 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria pesante E avversaria in riga 1, cella 3» (63) | 3.99 s intero | 4.00 s intero | 4.01 s intero | 4.00 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entrano in campo tiratori F avversari in riga 1, cella 8» (56) | 3.94 s intero | 3.93 s intero | 3.93 s intero | 3.94 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Turno 2, tocca a te» (19) | 1.54 s intero | 1.55 s intero | 1.54 s intero | 1.54 s intero |
| scontro · movimento compiuto sulla cella | «Spostato in riga 9, cella 4: costa 52, restano 278» (50) | 6.13 s intero | 6.00 s intero | 6.00 s intero | 6.00 s intero |
| scontro · resa dichiarata | «Resa dichiarata: comincia la tua ritirata combattuta» (52) | 3.46 s intero | 3.44 s intero | 3.51 s intero | 3.44 s intero |
| battaglia · marcia verso il nemico ordinata | «Corvo marcia verso riga 1, casella 2, 1 giorno al termine» (57) | 4.23 s intero | 4.19 s intero | 4.26 s intero | 4.19 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Giornata chiusa. 1 gruppo non aveva agito e resta fermo: ne è stata conservata una traccia…» (114) | 6.55 s intero | 6.50 s intero | 6.50 s intero | 6.50 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Corvo è arrivato in riga 1, casella 2» (37) | 2.61 s intero | 2.54 s intero | 2.54 s intero | 2.53 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Imboscata scattata in riga 1, casella 2» (39) | 2.89 s intero | 2.89 s intero | 2.89 s intero | 2.90 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Battaglia in sospeso da imboscata in riga 1, casella 2» (54) | 3.55 s intero | 3.51 s intero | 3.53 s intero | 3.51 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Rifornimento di Corvo interrotto in riga 1, casella 2» (53) | 3.46 s intero | 3.47 s intero | 3.50 s intero | 3.48 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Giornata conclusa: comincia il giorno 2» (39) | 2.75 s intero | 2.74 s intero | 2.80 s intero | 2.76 s intero |
| conclusione · giornata chiusa (cambio di stagione) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | 6.98 s intero | 6.99 s intero | 7.00 s intero | 7.00 s intero |
| conclusione · giornata chiusa (cambio di stagione) | «Giornata conclusa: comincia il giorno 2» (39) | 2.77 s intero | 2.76 s intero | 2.78 s intero | 2.76 s intero |
| conclusione · giornata chiusa (cambio di stagione) | «Nuova stagione: estate» (22) | 1.96 s intero | 1.97 s intero | 2.01 s intero | 1.97 s intero |
| conclusione · giornata chiusa (2) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | 7.00 s intero | 6.99 s intero | 7.02 s intero | 7.00 s intero |
| conclusione · giornata chiusa (2) | «Giornata conclusa: comincia il giorno 3» (39) | 2.74 s intero | 2.75 s intero | 2.74 s intero | 2.76 s intero |
| conclusione · giornata chiusa (2) | «Nuova stagione: autunno» (23) | 1.97 s intero | 1.91 s intero | 1.94 s intero | 1.92 s intero |
| mappa · divisione incompleta rifiutata | «Scegli almeno un reparto da staccare e almeno uno da tenere» (59) | — | 3.22 s intero | — | 3.21 s intero |
| presa · giornata chiusa (1) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.00 s intero | — | 7.00 s intero |
| presa · giornata chiusa (1) | «Formazione avversaria avvistata in riga 4, casella 3» (52) | — | 3.76 s intero | — | 3.76 s intero |
| presa · giornata chiusa (1) | «Occupi il quartier generale avversario, in riga 1, casella 2: se lo tieni sarà preso fra 3…» (99) | — | 6.53 s intero | — | 6.52 s intero |
| presa · giornata chiusa (1) | «Giornata conclusa: comincia il giorno 2» (39) | — | 2.75 s intero | — | 2.75 s intero |
| presa · giornata chiusa (2) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.00 s intero | — | 7.00 s intero |
| presa · giornata chiusa (2) | «Formazione avversaria avvistata in riga 3, casella 3» (52) | — | 3.47 s intero | — | 3.46 s intero |
| presa · giornata chiusa (2) | «Tieni il quartier generale avversario: sarà preso fra 2 giornate» (64) | — | 3.96 s intero | — | 3.95 s intero |
| presa · giornata chiusa (2) | «Giornata conclusa: comincia il giorno 3» (39) | — | 2.75 s intero | — | 2.75 s intero |
| presa · giornata chiusa (3) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 6.99 s intero | — | 7.00 s intero |
| presa · giornata chiusa (3) | «Formazione avversaria avvistata in riga 3, casella 2» (52) | — | 3.46 s intero | — | 3.46 s intero |
| presa · giornata chiusa (3) | «Tieni il quartier generale avversario: sarà preso fra 1 giornata» (64) | — | 3.94 s intero | — | 3.94 s intero |
| presa · giornata chiusa (3) | «Rifornimento di Falco interrotto in riga 3, casella 1» (53) | — | 3.54 s intero | — | 3.54 s intero |
| presa · giornata chiusa (3) | «Giornata conclusa: comincia il giorno 4» (39) | — | 3.08 s intero | — | 3.08 s intero |
| subita · giornata chiusa (1) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 6.99 s intero | — | 7.00 s intero |
| subita · giornata chiusa (1) | «L'avversario occupa il tuo quartier generale, in riga 4, casella 2: se non lo scacci sarà …» (110) | — | 7.26 s intero | — | 7.26 s intero |
| subita · giornata chiusa (1) | «Giornata conclusa: comincia il giorno 2» (39) | — | 2.75 s intero | — | 2.76 s intero |
| subita · giornata chiusa (2) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 6.99 s intero | — | 7.00 s intero |
| subita · giornata chiusa (2) | «Il tuo quartier generale è ancora occupato: sarà preso fra 2 giornate» (69) | — | 4.23 s intero | — | 4.24 s intero |
| subita · giornata chiusa (2) | «Giornata conclusa: comincia il giorno 3» (39) | — | 2.75 s intero | — | 2.76 s intero |
| subita · giornata chiusa (3) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.01 s intero | — | 7.00 s intero |
| subita · giornata chiusa (3) | «Il tuo quartier generale è ancora occupato: sarà preso fra 1 giornata» (69) | — | 4.22 s intero | — | 4.22 s intero |
| subita · giornata chiusa (3) | «Giornata conclusa: comincia il giorno 4» (39) | — | 3.08 s intero | — | 3.08 s intero |
| azzeramento · giornata chiusa, l'occupazione comincia | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.00 s intero | — | 7.00 s intero |
| azzeramento · giornata chiusa, l'occupazione comincia | «Formazione avversaria avvistata in riga 4, casella 3» (52) | — | 3.77 s intero | — | 3.77 s intero |
| azzeramento · giornata chiusa, l'occupazione comincia | «Occupi il quartier generale avversario, in riga 1, casella 2: se lo tieni sarà preso fra 3…» (99) | — | 6.53 s intero | — | 6.53 s intero |
| azzeramento · giornata chiusa, l'occupazione comincia | «Giornata conclusa: comincia il giorno 2» (39) | — | 2.75 s intero | — | 2.75 s intero |
| azzeramento · tocco magico con un'occupazione in corso | «Anno 1, primavera, mancano 88 giornate all'inverno. Giorno 2. Nessun gruppo ha ancora agit…» (166) | — | 11.96 s intero | — | 11.96 s intero |
| azzeramento · marcia che lascia il quartier generale | «Corvo marcia verso riga 1, casella 3, 1 giorno al termine» (57) | — | 4.17 s intero | — | 4.17 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Giornata chiusa. 4 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.02 s intero | — | 7.02 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Corvo è arrivato in riga 1, casella 3» (37) | — | 2.53 s intero | — | 2.54 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Formazione avversaria avvistata in riga 3, casella 3» (52) | — | 3.47 s intero | — | 3.46 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Non occupi più il quartier generale avversario: il conteggio si azzera» (70) | — | 4.09 s intero | — | 4.08 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Giornata conclusa: comincia il giorno 3» (39) | — | 2.75 s intero | — | 2.74 s intero |
| richiamo · richiamo impedito | «L'esercito non si può richiamare: Corvo ha il rifornimento tagliato in riga 2, casella 2» (88) | — | 5.40 s intero | — | 5.38 s intero |

### Voce al 90 per cento

Misurata soltanto dopo. Per ogni annuncio: quanto dura al 50 per cento (mediana delle volte intere, dello stesso testo o, se cambia solo un numero, del testo a meno dei numeri), quanto è durato al 90, e il rapporto. Detto per intero se è durato almeno tre quarti di quanto dovrebbe, con il rapporto ricavato dalle righe che non spostano il fuoco (mediana: iPhone 3.45, iPad 3.45). Un annuncio tagliato avrebbe un rapporto più alto.

| Quando | Annuncio (caratteri) | sposta il fuoco | iPhone: 50 → 90 (rapporto) | iPad: 50 → 90 (rapporto) |
|---|---|---|---|---|
| comincia l'inverno, voce al 90 per cento | «Comincia l'inverno dell'anno 1. Entrate: monete di bronzo 20…» (175) | sì | 14.18 → 4.05 s (3.50) intero | 14.18 → 4.05 s (3.50) intero |
| addestramento ordinato, voce al 90 per cento | «Addestramento mirato ordinato per 8 atomi di fanteria pesant…» (91) | sì | 5.53 → 1.57 s (3.52) intero | 5.53 → 1.57 s (3.52) intero |
| leva ordinata, voce al 90 per cento | «Leva di fanteria leggera ordinata: pronta in primavera.» (55) | no | 3.42 → 0.99 s (3.45) intero | 3.42 → 0.99 s (3.45) intero |
| apertura della campagna, voce al 90 per cento | «Campagna aperta sul fronte del guado» (36) | sì | 2.32 → 0.68 s (3.41) intero | 2.32 → 0.68 s (3.41) intero |
| apertura della campagna, voce al 90 per cento | «Mappa Guado, 4 righe per 4 caselle. Il tuo quartier generale…» (83) | sì | 6.27 → 1.84 s (3.41) intero | 6.27 → 1.84 s (3.41) intero |
| apertura della campagna, voce al 90 per cento | «Anno 1, primavera, mancano 89 giornate all'inverno. Giorno 1…» (99) | sì | 7.92 → 2.30 s (3.44) intero | 7.92 → 2.30 s (3.44) intero |
| giornata chiusa, voce al 90 per cento | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi:…» (118) | no | 7.00 → 2.01 s (3.48) intero | 7.00 → 2.02 s (3.47) intero |
| giornata chiusa, voce al 90 per cento | «Giornata conclusa: comincia il giorno 2» (39) | no | 2.75 → 0.81 s (3.40) intero | 2.75 → 0.81 s (3.40) intero |

### Gli annunci della build 32 tagliati che il sistema dava per riusciti

Perché la notifica di conclusione non decide da sola: la voce li ha detti per il tempo della seconda colonna, e la notifica dice «riuscito».

| Apparecchio | Detto | Quando | Caratteri |
|---|---|---|---|
| iphone | 0.01 s | regno · comincia l'inverno | 175 |
| iphone | 0.00 s | regno · comincia la primavera | 206 |
| iphone | 0.02 s | scontro · apertura dello scontro | 79 |
| iphone | 0.00 s | conclusione · giornata chiusa (3) | 61 |
| ipad | 0.00 s | regno · comincia l'inverno | 175 |
| ipad | 0.06 s | regno · comincia la primavera | 206 |
| ipad | 0.00 s | mappa · entra nel fronte | 83 |
| ipad | 0.00 s | conclusione · giornata chiusa (3) | 61 |

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
| scontro · evacuazione che conclude lo scontro | Perdite inflitte: 0 punti | Resoconto della battaglia | riga 9, cella 4, libera | Resoconto della battaglia |
| battaglia · la battaglia aperta dalla casella | riga 1, cella 2, libera | Riserve da schierare | riga 1, cella 2, libera | Riserve da schierare |
| battaglia · evacuazione che conclude la battaglia | Scariche residue dei tuoi tiratori: 0 | Resoconto della battaglia | riga 10, cella 5, libera | Resoconto della battaglia |
| battaglia · ritorno sulla mappa dopo la battaglia | riga 1, casella 2, formazione avversaria, quarti | riga 2, casella 2, tuo Corvo, ha agito, senza pr | riga 1, casella 2, formazione avversaria, quarti | riga 2, casella 2, tuo Corvo, ha agito, senza pr |
| conclusione · giornata chiusa (3) | Campagna conclusa | Campagna conclusa | Campagna conclusa | Campagna conclusa |
| mappa · divisione aperta dal pannello | — | Dividi Falco | — | Dividi Falco |
| presa · ritorno in patria dopo la presa | — | Anno 1, primavera | — | Anno 1, primavera |
| subita · ritorno in patria dopo la caduta | — | Anno 1, primavera | — | Anno 1, primavera |
| richiamo · richiamo compiuto | — | Campagna conclusa | — | Campagna conclusa |
| richiamo · ritorno in patria dopo il richiamo | — | Anno 1, primavera | — | Anno 1, primavera |
| velocita · comincia l'inverno, voce al 90 per cento | — | Anno 1, inverno, schermata 1 di 4 | — | Anno 1, inverno, schermata 1 di 4 |
| velocita · addestramento ordinato, voce al 90 per cento | — | Addestramento mirato. Si sceglie il reparto. Acc | — | Addestramento mirato. Si sceglie il reparto. Acc |
| velocita · apertura della campagna, voce al 90 per cento | — | riga 3, casella 2, tuo Cervo, formazione non arm | — | riga 3, casella 2, tuo Cervo, formazione non arm |

«—» vale per i passi misurati soltanto dopo: le cose nuove di questo incarico, e le prove a voce veloce. «Superato dal gioco» è la conferma della chiusura che conclude la campagna, superata per scelta dall'annuncio della conclusione (A §11.6, S30e), prima e dopo.

### Il fuoco al ritorno in patria (RDA-192)

Il conto (`conta-fuoco.py corsa-1 … corsa-5`):

    == corsa-1
      ipad               dichiarazione       4 volte,  4 giuste, 0 rinnovate
      ipad               ritorno in patria   4 volte,  4 giuste, 0 rinnovate
      iphone             dichiarazione       5 volte,  5 giuste, 0 rinnovate
      iphone             ritorno in patria   4 volte,  1 giuste, 0 rinnovate; finite su «Registro della patria» 3
    == corsa-2
      ipad               dichiarazione      12 volte, 12 giuste, 0 rinnovate
      ipad               ritorno in patria  12 volte, 12 giuste, 0 rinnovate
      iphone             dichiarazione      12 volte, 12 giuste, 0 rinnovate
      iphone             ritorno in patria  12 volte, 12 giuste, 0 rinnovate
    == corsa-3
      dopo-ipad          dichiarazione       8 volte,  8 giuste, 0 rinnovate
      dopo-ipad          ritorno in patria   8 volte,  8 giuste, 0 rinnovate
      dopo-iphone        dichiarazione      16 volte, 16 giuste, 0 rinnovate
      dopo-iphone        ritorno in patria  16 volte, 16 giuste, 8 rinnovate
      prima-ipad         dichiarazione       8 volte,  8 giuste, 0 rinnovate
      prima-ipad         ritorno in patria   8 volte,  8 giuste, 0 rinnovate
      prima-iphone       dichiarazione      16 volte, 16 giuste, 0 rinnovate
      prima-iphone       ritorno in patria  16 volte,  9 giuste, 0 rinnovate; finite su «Registro della patria» 7
    == corsa-4
      scorsa-iphone      dichiarazione       8 volte,  8 giuste, 0 rinnovate
      scorsa-iphone      ritorno in patria   8 volte,  8 giuste, 8 rinnovate
    == corsa-5
      subito-iphone      dichiarazione      10 volte, 10 giuste, 0 rinnovate
      subito-iphone      ritorno in patria  10 volte, 10 giuste, 4 rinnovate
      unsecondo-iphone   dichiarazione      10 volte, 10 giuste, 0 rinnovate
      unsecondo-iphone   ritorno in patria  10 volte, 10 giuste, 0 rinnovate

## Le battaglie che non finiscono, la frequenza, lo squilibrio: prima e dopo

Strumenti: `StrumentoVerifica` (`--frequenza-battaglie 200 --giornate-massime 730`, `--regno 200 --anni 5`, `--duelli`, e gli stessi con `--tattico-pari`), poi `P/tabelle.py`. Dati grezzi: `P/frequenza-battaglie/`, `P/banco-del-regno/`, `P/squilibrio/`. «Prima» è il codice della build 32. I totali non coincidono per due motivi: la condotta mirata al quartier generale, che prima non c'era, vi aggiunge 600 partite e 1000 anni; e una partita che si ferma non prosegue, per cui «prima» il banco ha giocato 1829 anni su 2000. I dati grezzi «dopo» sono stati rifatti sul codice di `e19b47b` e coincidono byte per byte (`cmp`) con quelli qui; da allora il Motore, i Dati, i Contenuti, la Sessione e il programma di verifica non sono cambiati (`git diff e19b47b HEAD -- Codice/Sources/Motore …`: vuoto).

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

**La causa delle battaglie che non finivano.** In tutte e 111 (33 partite e 78 anni) la stessa: `TatticoBattaglia.comandoDiPiazzamento` alternava la selezione di due elementi non piazzabili (la diagnosi di ciascuna è nel campo `diagnosi` dei dati «prima», `DiagnosiBattaglia`). Corretta quella (`c8a3d50`), lo stallo fra schieramenti che non possono incontrarsi (`5cc47d8`) e le due forme trovate con le composizioni proposte (`c264837`: una colonna fermata da un proprio reparto, un tattico che provava un passo solo), non ne resta nessuna: zero su 1800 partite e 3000 anni, coi due tattici.

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

**Le tre campagne vinte per annientamento senza una battaglia vinta** (semi 123, 173, 190, guado, condotta competente). Rigiocate sul codice della build 32, con la traccia di ogni battaglia (`P/banco-del-regno/tre-semi/traccia.txt`, prodotta da `StrumentoVerifica` con la modifica accanto): in ciascuna il giocatore perde tre battaglie, otto su nove perché si ritira dopo la resa, una — la seconda del seme 173 — per il difetto del primo turno, con ventiquattro fanti pesanti intatti dati per annientati. Nella terza l'avversario, che avanza sul ritirante, finisce senza un atomo mentre al giocatore ne restano due, quattro e uno. Lo sconfitto è chi si ritira (01 §15.2.2), ma l'avversario non ha più gruppi armati, e la campagna è vinta per annientamento: è la regola di 01 §15.2.3.1. Non era un difetto la conclusione; lo erano due delle cose che vi portavano, il primo turno (RDA-187) e le unità evacuate perdute (RDA-188). Sul codice nuovo quei tre anni finiscono con la presa del quartier generale del giocatore; undici anni su 3000 si chiudono ancora così, tutti con il tattico del banco che si arrende a metà delle perdite, e nessuno col tattico che non si arrende.

## La verifica attraverso l'interfaccia, con VoiceOver

Codice: `c5bcb09` (`finale5`, copia non strumentata; compilata dal commit e poi ferma). Nessuna delle sei corse consegnate (due apparecchi, percorsi e due modi del tester) ha avuto errori di guida.

**Percorsi a controlli** (`P/verifica-voiceover/percorsi.py`, diari in `percorsi/`, schermate in `schermate/`), con VoiceOver acceso: 45 controlli su 45 sull'iPhone, 45 su 45 sull'iPad, in sei percorsi — reclute (S29q b e d), rifiuto (S29q c), presa, subita, richiamo, battaglia. Alcuni percorsi mettono a punto gli scenari nella cartella Documenti, come fa chi tara dall'iPad. Su `e19b47b` la battaglia aveva dato 5 su 6, perché il percorso guardava la griglia col pannello aperto, e rifatta 6 su 6: quelle corse non si consegnano, quelle di ora sono in una volta sola.

**Tester** (`scripts/tester.py`, valori di fabbrica, VoiceOver acceso, diari in `P/verifica-voiceover/tester/`), una partita per modo e per apparecchio:

- `regno media presa`, istmo, venti giornate di gioco e tredici minuti e mezzo di orologio, uguale su iPhone e iPad: cinque marce, una battaglia, che il tester apre e conduce quattro turni e che si conclude in stallo («Vittoria: l'avversario si è ritirato», «Perdite tue: 0 punti su 3360 impegnati», «Perdite inflitte: 0 punti»: S30c), poi il quartier generale avversario tenuto tre giornate e preso. La dichiarazione: «Vittoria: il quartier generale avversario sul fronte dell'istmo è caduto», «Rientrano in patria: 5 formazioni», «Premi che si aggiungono alla rendita dell'anno: monete di bronzo 120, uomini 14, metalli 18, …».
- `regno media richiamo resa`, istmo, sei giornate, uguale su iPhone e iPad: il comando prima impedito («L'esercito non si può richiamare: Corvo ha il rifornimento tagliato in riga 2, casella 3»), poi offerto; una rinuncia («Rinuncia», e il fuoco torna sul comando); la conferma; la dichiarazione («Hai richiamato l'esercito dal fronte dell'istmo: la campagna conta come perduta», «Rientrano in patria: 5 formazioni», «Nessun premio: quest'inverno arriva la sola rendita»); la patria («Campagna sul fronte dell'istmo perduta: esercito richiamato in patria»). Al ritorno in patria il fuoco è su «Anno 1, primavera» in tutte e quattro le partite.

**Salvataggi** (`P/salvataggi-build-32/`): con l'app di `06dee59` si scrivono un regno a campagna aperta, una campagna di prova e uno scontro; con la nuova installata sopra si riprendono. 12 controlli su 12, sull'iPhone, con l'app di `e19b47b`: differisce da quella della build per la sola conferma del fuoco.

**Annunci e fuoco**: undici blocchi della misura, sull'iPhone e sull'iPad, sul codice della build. 31 su 31 gli annunci che accompagnano uno spostamento e 68 su 68 gli altri, sui due apparecchi; nei sessanta passi che chiedono il fuoco arriva sempre dove il gioco l'ha chiesto, e in uno la richiesta si è rinnovata (il ritorno in patria, iPhone).

## Che cosa è successo durante l'esecuzione

**Gli annunci**

1. Prima di scegliere la via ho costruito una copia di laboratorio con otto vie, compresa quella di partenza (`P/annunci/scelta-della-via/README.md`). La priorità alta è la sola che dice l'annuncio per intero e subito, e poi legge l'elemento per intero. Priorità bassa, attesa del fuoco a priorità bassa e attributo di accodamento ritardano di 5,3 secondi gli annunci che non spostano il fuoco; l'attesa a priorità predefinita taglia l'elemento dopo 0,15 secondi; il testo messo nella notifica o nell'elemento si sente soltanto in parte.
2. La misura ha trovato due volte che la mia correzione non bastava. La prima stesura del resoconto chiedeva il fuoco alla cella e poi al titolo: sull'iPhone restava su «Perdite inflitte: 0 punti»; ora un comando del pannello si esegue prima di chiedere il fuoco (`35127d2`). La battaglia si annunciava alla fine del caricamento, e sull'iPhone, una volta su quattro, usciva 20 millisecondi prima della richiesta del fuoco e spariva; ora si annuncia alla comparsa (`e9f702e`).
3. **Il terzo difetto l'hanno trovato i diari del tester, non le misure**, e la mia correzione precedente non valeva nulla. Tornando in patria, sull'iPhone, il fuoco era su «Attendi l'inverno»; alla dichiarazione di conclusione, sull'iPad, su «Nessun premio…». `e19b47b` diceva di averlo corretto attendendo il sistema, e la bozza di questo resoconto lo ripeteva. Riprodotto apposta (`P/annunci/fuoco/`): su quel codice il ritorno in patria sull'iPhone finisce su «Registro della patria» 7 volte su 16, sull'iPad mai su 8, e in un giro più rapido mai su 12: senza la ripetizione sembrava raro. Corretto con la conferma (RDA-192, `c5bcb09`). Un'ipotesi sulla causa è stata smentita dai dati (la notifica del sistema che arriva dopo quella del gioco: il fuoco si muove 0,77 s dopo la richiesta del gioco, non dopo), un'altra provata e scartata (la patria scorsa in basso): la causa non è accertata.
4. **Due volte la prova o lo strumento mi ha smentito.** Nel commit `ac8c39e` avevo reso «intere» cinque righe a voce veloce che la tabella dava per interrotte, usando come criterio la notifica del sistema: è inaffidabile — dice «riuscito» di otto annunci della build 32 tagliati dopo 0,00–0,06 s — e l'ho tolta; le righe veloci stanno in una tabella a parte e si giudicano con la stessa regola delle altre, sul rapporto fra le durate (`10dd1f5`). E la bozza di questo resoconto diceva che la copia misurata era quella finale: era quella di un commit prima.
5. Altri errori nello strumento: `strumenta.sh` non strumentava la nuova `pubblica` e le prime corse non registravano nulla; l'abbinamento fra annuncio e tratto di voce è stato riscritto; il guidatore ereditava da un blocco all'altro i valori messi a punto. Con dieci simulatori accesi insieme al collaudo i tratti di voce si allungano e un annuncio concluso con successo può non avere voce: una misura sotto carico non vale. Con sette, la corsa dei percorsi fatta per le sole schermate ha fallito otto controlli su 41, gli stessi sui due apparecchi e tutti d'ascolto: non si consegna, e le schermate vengono dalla corsa finale.

**Il gioco**

6. Il banco ha trovato i miei difetti. La prima stesura della presa lasciava le occupazioni dopo la conclusione (`occupazione_incoerente`). La sonda degli invarianti e il banco avevano la stessa cecità sugli evacuati, e per questo il difetto non si vedeva: il banco ora li conta per proprio conto. Il primo criterio dello stallo, «nessuno può agire», contava gli spostamenti laterali e lasciava battaglie aperte.
7. Le proposte hanno trovato due forme di stallo in più: misurando la composizione a quattro reparti, alcune partite del banco si fermavano (il conto esatto non si è conservato). Il tattico provava un passo solo, e una colonna restava fermata dal proprio reparto di testa: corrette. Dopo, zero.
8. Le tre campagne coi semi 123, 173 e 190: la spiegazione che avevo scritto diceva che il giocatore perde le tre battaglie perché si arrende. La traccia, rigenerata per consegnarla, dice che una su nove, la seconda del seme 173, la perde per il difetto del primo turno: l'ho corretta in RDA-191 e qui.

**Le prove**

9. Le mutazioni hanno trovato **quattro prove deboli**, fra le nuove. «Perdere la battaglia non azzera» sopravviveva: mancava il caso dell'occupante battuto che non può ripiegare. Poi, controllando una per una le prove nuove contro le uscite conservate — il primo controllo cercava il nome in un file qualunque, e contava anche le prove passate: con quello stretto ne mancavano 20 — altre tre: «chi occupa lo tiene» passava senza la regola, perché nessuno scenario offriva un guadagno altrove; «un esploratore non lo richiama» perché la corsa decideva prima; «il passo di un'occupazione non si annulla» perché l'avversario della prova agiva e sigillava lui la chiusura. Rafforzate, e viste fallire. Due mutazioni della conferma del fuoco sono sopravvissute perché il codice aveva due rami inutili: li ho tolti.
10. Una prova ospitata rossa dopo la correzione del fuoco (`PatriaTest`): la prova adesso pretende il fuoco sul titolo, non è stata indebolita. Due prove nuove portavano nel nome un punto che non esiste o parla d'altro (`test_02_8_2_2`, `test_03_4_8_4`): rinominate.
11. I commit `5cc47d8` e `f3c2c9a` sono stati spinti prima di rieseguire l'intera suite; la suite intera è stata rieseguita verde subito dopo, a `c264837` (604 prove del pacchetto).

12. **Il primo caricamento si è fermato da sé**: nel collaudo che lo script rifà prima di archiviare è fallita una prova passata nelle tre corse precedenti, `MappaCampagnaAccessibileTest.test_02_9_2_1_…`. Ripetuta duecento volte fallisce cinque volte, e quattro su duecento sul codice della build 32: non è mia, è una gara della prova, che chiude da sé il pannello della casella e non attende che sia chiuso prima di controllare che non ce ne siano. Ora lo attende (300 ripetizioni su 300 passate), e fallisce ancora quando la marcia apre davvero un pannello (`P/cancelli-visti-fallire/marcia-senza-pannello*.txt`). Per la stessa ragione ho reso le prove della conferma del fuoco insensibili a una macchina lenta.

**La guida dei simulatori**

13. `lldb`/`sample`, all'inizio, ha aperto un dialogo di autorizzazione di macOS che ha fermato i simulatori accesi: chiuso il dialogo, non li ho più usati. `rm -f misure/*` è stato rifiutato dal controllo dei permessi della sessione: non l'ho aggirato, ho usato cartelle nuove. Per fermare una corsa di misura ho usato un filtro che prendeva soltanto l'inizio della riga di comando e non ha fermato quella vecchia: per una ventina di secondi otto processi miei hanno scritto agli stessi piloti; fermati uno per uno, la corsa è ripartita e quei dati sono scartati.
14. Il tester ha richiesto più corse. Su iPhone il pilota è caduto una volta su un elemento che XCUITest non sa toccare («unable to compute coordinates»): ora lo dichiara e il tester riprova. Il tester del richiamo è ripartito quattro volte per errori di guida miei. Le corse scartate sono in `Applicazione/build-interattivo/lab-32/scartati/`, che non si consegna.
15. Un controllo sbagliato, non il gioco: il percorso «subita» e 02 §6.5.1.4 aspettavano la frase dell'annuncio anche nello stato. Corretti il controllo e il documento. E il percorso «battaglia» guardava la griglia col pannello aperto, che la copre: il controllo sulla virgola nelle azioni d'ingaggio è fallito finché non l'ho corretto.
16. Il tester ha preso il quartier generale in una battaglia che nessuno ha combattuto («Perdite tue: 0 punti su 3360 impegnati. Perdite inflitte: 0 punti»): è il caso dichiarato in S30c, sull'istmo l'avversario, ingombrante, si ritira.

## Le versioni: la valutazione

**Valori: 0.16.0**, con la 0.15.0 fra le compatibili (RDA-190). **Schemi: battaglia 2, campagna 9, regno 2, fermi.** Una riga nuova del giornale di campagna (`richiamoDellEsercito`) che nessun giornale esistente contiene; nessuna riga esistente cambia significato. Le partite salvate con la build 32 si riaprono: una campagna in corso prosegue con le regole con cui è nata (i giornali non contengono né gli arrivi né le occupazioni, che si ricalcolano), la prossima campagna del regno ha le regole nuove, uno scontro chiuso dal difetto del primo turno torna da giocare. Le note lo dicono. Verificato in due modi: con giornali e istantanee scritti dal codice della build 32 (`SalvataggiBuild32Test`) e dal vivo, con l'app di `06dee59` e la nuova installata sopra (`P/salvataggi-build-32/`, 12 controlli su 12).

## Le decisioni prese da solo, e perché

1. **La priorità alta soltanto per gli annunci che accompagnano uno spostamento** (RDA-183), e una finestra di due secondi dall'ultima richiesta del fuoco. Alternative misurate e scartate con il perché.
2. **La chiusura in cui si entra nel quartier generale non conta**, e sette altre letture della presa che il testo della decisione non contiene (RDA-184): la contesa non conta e non azzera; l'occupante battuto azzera anche restando; occupano i soli armati; preso resta preso; la presa precede l'inverno nella stessa chiusura; le battaglie in sospeso altrove non si combattono più; nella caduta simultanea vince il giocatore, come nell'annientamento simultaneo.
3. **Le regole della presa viaggiano con la campagna** (`RegoleDiCampagna` nello scenario), e le campagne di prova non ne dichiarano: senza un calendario e una patria non hanno una fine, e la decisione non le nomina (S30a).
4. **Nello stallo se ne va sempre l'avversario** (RDA-189). Misurata l'alternativa, chi attacca: sull'istmo le campagne vinte passerebbero dall'82,6% al 4,5%, e il giocatore che attacca resterebbe in una battaglia da cui si esce soltanto arrendendosi.
5. **Il budget del primo turno corregge RDA-140** (RDA-187), e per questo i valori salgono a 0.16.0 con la 0.15.0 compatibile. Gli scontri salvati non sono dichiarati incompatibili: chi ne aveva uno chiuso da quel difetto lo ritrova da giocare.
6. **Gli evacuati tornano in campagna** (RDA-188). L'incarico chiedeva la causa dello squilibrio: questa ne è una, ed era contraria a 01 §10.4.
7. **L'annientamento simultaneo della campagna legge il vantaggio nascosto dal file** (`9a0ae50`): S28f lo lasciava alla conclusione definitiva, che è questa.
8. **La conferma del fuoco** (RDA-192) è una regola nuova sull'accessibilità che l'incarico non chiedeva: senza, il ritorno in patria sarebbe rimasto sbagliato quasi una volta su due sull'iPhone, e 02 §5.7 affermava il contrario.
9. **Le corse del pilota e del tester che hanno avuto un errore di guida non si consegnano**; quelle consegnate sono del codice della build.

## Modifiche, per commit

| commit | che cosa |
|---|---|
| `e9686a9` | l'incarico archiviato verbatim, l'indice |
| `c8a3d50` | il tattico che non alterna più la selezione (`TatticoBattaglia.comandoDiPiazzamento`); la diagnosi delle battaglie (`DiagnosiBattaglia`); i dati «prima» |
| `84f95f9` | gli annunci: `CodaAnnunci`, `PuntoSegnali`, i tre traduttori, le schermate; due cancelli |
| `a3e0215` | S29q b, c, d: `MappaCampagna`, `MotoreCampagna`, `SituazioneDelFronte`, `SchermataPatria`, testi |
| `5cc47d8` | la presa e il richiamo (`PresaDelQuartierGenerale`, condotta, sessione, segnali, schermate, invarianti); budget del primo turno, evacuati, prima forma dello stallo |
| `f3c2c9a` | la virgola (`PosizioneNelleFrasiTest`), il congedo del resoconto |
| `c264837` | le altre due forme dello stallo; valori 0.16.0; le prove dei salvataggi della build 32 |
| `805e42e` | il fuoco in testa alle schermate che si aprono; il conto delle battaglie che nessuno combatte; le tabelle; il tester della presa e del richiamo |
| `be20580`, `9a0ae50` | la caduta simultanea e l'annientamento simultaneo letti dal vantaggio nascosto; le mutazioni viste fallire |
| `d0fa34b` | i documenti: 01 3.12, 02 2.11, 03 2.9, 05 1.9, RDA-183…191, S30, valori provvisori, matrice |
| `35127d2`, `e9f702e`, `e19b47b` | il fuoco dai pannelli; la battaglia alla comparsa; il ritorno in patria (quest'ultima, ritirata da `c5bcb09`) |
| `ac8c39e`, `10dd1f5` | la misura degli annunci, le prove rafforzate, la traccia dei tre semi, i diari |
| `c5bcb09` | la conferma del fuoco (RDA-192): il codice della build |
| `bb1a69b`, `13c73d8`, `4af4dca` | la tornata finale sul codice della build, le note, il controllo delle prove viste fallire, gli esiti del collaudo |
| `d2cc8a8` | la prova della marcia senza pannello; il commit da cui è uscita la build |
| `932aaa2` e seguenti | il registro della build 33, i prodotti del caricamento, le prove insensibili a una macchina lenta, il resoconto |

## Ciò che ho fatto senza che fosse chiesto

- Il fuoco in testa alla battaglia e alla divisione aperte dal pannello, al resoconto, alla dichiarazione di conclusione; il comando dato da un pannello che si esegue prima di chiedere il fuoco; la battaglia che si annuncia alla comparsa; la conferma della richiesta di fuoco (`805e42e`, `35127d2`, `e9f702e`, `c5bcb09`): trovati dalla misura e dai diari.
- `sciamiEvacuati`, il costo del ritiro che non eccede un turno, il tattico che prova ogni passo che avvicina, le altre due forme dello stallo: cause dello squilibrio e delle battaglie senza fine.
- Le due alternative di regola misurate (chi attacca esce dallo stallo; un reparto può sempre fare un passo) accanto alle composizioni proposte: l'incarico chiedeva di proporre numeri.
- L'annientamento simultaneo della campagna letto dal file dei vantaggi nascosti (S28f).
- Il pilota non cade più su un elemento non toccabile (`SessioneInterattivaTest`); il tester ha due modi nuovi (`scripts/tester.py`).
- Lo strumento di verifica: `--tattico-pari`, `--duelli`, il conto delle battaglie che nessuno combatte. Nella misura degli annunci, il blocco «fuoco» e le schermate nei percorsi a controlli.
- Tre prove nuove rafforzate e due rinominate, e due rami di codice tolti perché le mutazioni li mostravano inutili.

## Ciò che era chiesto e non ho fatto

- **Nulla di ciò che l'incarico chiede è rimasto fuori**, con questa precisazione: per le composizioni proposte e le due alternative di regola ho conservato i conti per cella e non i dati grezzi di ogni partita, perché pesano e la corsa è deterministica e ripetibile con un comando (`P/squilibrio/proposte.py`; le modifiche delle alternative in `P/squilibrio/alternative/`).
- La coalescenza degli annunci di fondo per contenuto (A §11.6), che l'incarico non chiede: resta da costruire (S30f).
- Il conto delle partite che si fermavano con la composizione a quattro reparti prima delle ultime due correzioni: non conservato.

## Scoperto, cioè non automatizzato, con le vie tentate

- **Perché VoiceOver applichi la richiesta di fuoco su un altro elemento** (RDA-192): non accertato. Le vie tentate: la patria riportata in testa prima di coprirla, la richiesta subito, dopo 0,4 s e dopo un secondo, l'istante e il posto dell'elemento nel registro della copia strumentata. La conferma rimedia senza saperlo. Il caso della dichiarazione di conclusione sull'iPad, visto una volta dal tester, non si è riprodotto (32 volte su 32 giusta).
- **Quando la richiesta si rinnova si sente per 0,8 secondi l'elemento sbagliato**, poi il titolo: 4 volte su 10 al ritorno in patria sull'iPhone simulato. Le altre schermate non sono state contate con il blocco «fuoco».
- **Un apparecchio vero.** Le misure sono sui simulatori: che sull'iPhone la finestra di due secondi basti, e quanto spesso la richiesta si rinnovi, non si può dire da qui.
- **La voce a 90 per cento, a orecchio.** Il pilota misura quanto dura ciascun tratto e se finisce da sé; che l'annuncio si capisca lo dicono i tester.
- **Il caso di due fortezze** è provato sul Motore e nei segnali, non nell'interfaccia: nessuna fortezza esiste nel gioco (S30b).
- **Una presa subita giocata per intero dall'avversario contro il tester**: è provata dal percorso «subita», con le formazioni messe dai dati, dal banco e dalle prove ospitate, non da una partita del tester.

## App Store Connect

Build **33**, caricata il 25 novembre 2026 alle 00:51 (API: `2026-11-24T15:51:37-08:00`), stato `VALID`, non scaduta, treno 1.1.0 che è il più alto sull'account; codice `c5bcb09`, commit caricato `d2cc8a8` (dopo `c5bcb09` soltanto prove, documenti e prodotti). Nota per i tester allegata, 3218 caratteri, identica a `note-di-rilascio.txt`. Gruppo `WarLab`, interno, con accesso a tutte le build: `IN_BETA_TESTING`. `scripts/controlla-build.py`: registro e App Store Connect concordano, 33 build. In `P/build-33/` la verifica per API e il registro condensato dei due tentativi. Nessun certificato toccato, nessun `-allowProvisioningUpdates`.

## Tempi

Tempi d'orologio, da `time`, dai registri e dai diari (gli strumenti sono nei punti indicati).

| che cosa | tempo |
|---|---|
| compilazione del pacchetto in release (`swift build -c release`) | 27 s |
| compilazione della copia del pacchetto con le prove | 10 s |
| copie di laboratorio dell'app (`prepara.sh`, incrementali) | 2–14 s ciascuna |
| archivio, firma ed esportazione della build 33 | 1 min 40 s |
| `swift test` intero (607 prove passate, 3 saltate) | 42 s |
| collaudo completo (`scripts/collaudo-completo.sh`) | 437, 413 e 409 s, più i due del caricamento (418 e circa 414 s) |
| sessioni complete (`scripts/esegui-sessioni-complete.sh`) | 558 e 517 s |
| banchi: frequenza su 1800 partite, regno su 3000 anni | 9,7 e 3,7 s |
| banchi: proposte, sette varianti coi due tattici | 2 min 32 s |
| mutazioni | pacchetto 8–10 s, ospitate 17–25 s ciascuna |
| simulatore: misura degli annunci, undici blocchi, due apparecchi insieme | 45 min (due volte) |
| simulatore: misura del fuoco, cinque corse | circa 45 min in tutto |
| simulatore: percorsi a controlli, sei percorsi, due apparecchi insieme | 22 min |
| simulatore: tester della presa; del richiamo | 13 min 25 s; 6 min 30 s |
| caricamento (secondo tentativo, dallo script) | 13 min, di cui 4 s di trasferimento e 4 min di elaborazione |
| esplorazione (documenti, resoconti, copia di laboratorio, riproduzioni) | non misurata a parte: dal primo commit, 15:32, al primo commit di codice, 16:39 |
| sessione intera | dalle 15:31 del 24 novembre alle 2 circa del 25 |

## Integrazione continua

`collaudo.yml`, a ogni invio sul ramo `principale`, immagine `xcode-27`. Letto dall'API pubblica di GitHub (`/repos/…/actions/runs`), che senza credenziali concede sessanta richieste l'ora: le ho esaurite una volta.

| commit | esito | durata |
|---|---|---|
| `06dee59` (incarico 31, partenza) | verde | — |
| `4af4dca` (fusione di questo incarico) | **rosso**, uscita 65 nel passo del collaudo | 35 min |
| `d2cc8a8` (il commit da cui è uscita la build) | verde | 36 min |
| `31b1ebf` (prodotti del caricamento, prove insensibili a una macchina lenta, resoconto; il commit che segue aggiunge soltanto questa riga) | verde | 30 min |

La prova fallita su `4af4dca` non la so: i registri chiedono credenziali (l'API risponde 403, `gh` non è installato) e non ne ho cercate altrove. L'ipotesi è la stessa prova intermittente che ha fermato il caricamento locale — `MappaCampagnaAccessibileTest.test_02_9_2_1_…`, 5 fallimenti su 200 sulla mia macchina, e più probabile su una più lenta — corretta in `d2cc8a8`; resta un'ipotesi.
