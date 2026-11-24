# Gli annunci, prima e dopo

Prodotta da `tabella.py` dalle misure grezze (`misure-grezze/*.jsonl`). In ogni cella: per quanto la voce ha detto l'annuncio, e se l'ha detto intero. «Prima» è il codice della build 32 (06dee59), «dopo» quello di questo incarico, entrambi nella copia strumentata che aggiunge il solo registro. I blocchi presa, subita, azzeramento, richiamo e conclusione sono rimisurati sul codice della build (`e19b47b`, file `dopo-finale-*.jsonl`, che prevalgono); gli altri sul commit precedente dell'applicazione (`e9f702e`), che ne differisce soltanto per l'attesa al ritorno in patria (`git diff e9f702e e19b47b -- Applicazione/Sorgenti Codice/Sources`). La velocità di VoiceOver è quella predefinita del simulatore (50 per cento).

## Annunci che accompagnano uno spostamento del fuoco o un cambio di schermata

| Quando | Annuncio (caratteri) | iPhone prima | iPhone dopo | iPad prima | iPad dopo |
|---|---|---|---|---|---|
| regno · comincia l'inverno | «Comincia l'inverno dell'anno 1. Entrate: monete di bronzo 200, uomini 24, metalli 30, mate…» (175) | 0.01 s interrotto | 14.18 s intero | 0.00 s interrotto | 14.18 s intero |
| regno · addestramento ordinato dalla scelta del reparto | «Addestramento mirato ordinato per 8 atomi di fanteria pesante di Lupo: pronto in primavera…» (91) | 0.75 s interrotto | 5.53 s intero | 0.77 s interrotto | 5.52 s intero |
| regno · scelta impedita rifiutata | «Non si può ordinare: mancano monete di bronzo.» (46) | 0.77 s interrotto | 3.06 s intero | 0.77 s interrotto | 3.06 s intero |
| regno · comincia la primavera | «Comincia la primavera dell'anno 2. Il riporto ha tolto: monete di bronzo 73, uomini 24, me…» (206) | 0.00 s interrotto | 15.07 s intero | 0.06 s interrotto | 15.07 s intero |
| regno · apertura della campagna dal regno | «Campagna aperta sul fronte del guado» (36) | 0.80 s interrotto | 2.32 s intero | 0.78 s interrotto | 2.32 s intero |
| regno · apertura della campagna dal regno | «Mappa Guado, 4 righe per 4 caselle. Il tuo quartier generale è in riga 4, casella 2» (83) | 6.29 s intero | 6.27 s intero | 6.33 s intero | 6.27 s intero |
| regno · apertura della campagna dal regno | «Anno 2, primavera, mancano 89 giornate all'inverno. Giorno 1. Nessun gruppo ha ancora agit…» (99) | 7.97 s intero | 7.92 s intero | 8.06 s intero | 7.91 s intero |
| mappa · entra nel fronte | «Mappa Guado, 4 righe per 4 caselle. Il tuo quartier generale è in riga 4, casella 2» (83) | 0.78 s interrotto | 6.26 s intero | 0.00 s interrotto | 6.27 s intero |
| mappa · entra nel fronte | «Anno 2, primavera, mancano 89 giornate all'inverno. Giorno 1. Nessun gruppo ha ancora agit…» (99) | 7.93 s intero | 7.93 s intero | 0.79 s interrotto | 7.93 s intero |
| mappa · marcia: destinazione da scegliere | «Scegli la casella di destinazione e attivala per dare l'ordine di marcia. Il gruppo rester…» (163) | 0.73 s interrotto | 8.97 s intero | 0.78 s interrotto | 8.96 s intero |
| mappa · marcia revocata | «Lupo: marcia revocata, persi 0 giorni» (37) | 0.79 s interrotto | 3.26 s intero | 0.78 s interrotto | 3.26 s intero |
| mappa · presidio ordinato | «Corvo presidia in riga 4, casella 2» (35) | 0.79 s interrotto | 2.85 s intero | 0.78 s interrotto | 2.85 s intero |
| mappa · divisione compiuta | «Nuovo gruppo Lince in riga 3, casella 4» (39) | 0.79 s interrotto | 3.03 s intero | 0.78 s interrotto | 3.03 s intero |
| mappa · riunione compiuta | «Falco riunito in riga 4, casella 4» (34) | 0.79 s interrotto | 3.19 s intero | 0.77 s interrotto | 3.19 s intero |
| mappa · esplorazione compiuta | «Orso ha esplorato la zona attorno a riga 4, casella 1» (53) | 0.79 s interrotto | 3.76 s intero | 0.78 s interrotto | 3.76 s intero |
| scontro · apertura dello scontro | «Battaglia su WarSense, 10 righe per 10 celle. Il campo è campo aperto, ostacolo» (79) | 0.02 s interrotto | 6.00 s intero | 0.77 s interrotto | 6.00 s intero |
| scontro · movimento: destinazione da scegliere | «Scegli la cella di destinazione e attivala per confermare» (57) | 0.79 s interrotto | 3.34 s intero | 0.78 s interrotto | 3.34 s intero |
| scontro · evacuazione che conclude lo scontro | «Unità evacuata: costa 52» (24) | 0.77 s interrotto | 2.54 s intero | 0.78 s interrotto | 2.54 s intero |
| scontro · evacuazione che conclude lo scontro | «La battaglia è conclusa: la ritirata è compiuta» (47) | 3.13 s intero | 3.12 s intero | 3.13 s intero | 3.13 s intero |
| battaglia · la battaglia aperta dalla casella | «Battaglia su WarSense, 10 righe per 10 celle. Il campo è campo aperto» (69) | 0.78 s interrotto | 5.04 s intero | 0.77 s interrotto | 5.06 s intero |
| battaglia · la battaglia aperta dalla casella | «Entra in campo fanteria leggera A avversaria in riga 1, cella 5» (63) | 4.33 s intero | 4.22 s intero | 4.26 s intero | 4.22 s intero |
| battaglia · la battaglia aperta dalla casella | «Turno 2, agisce l'avversario» (28) | 2.22 s intero | 2.21 s intero | 2.20 s intero | 2.20 s intero |
| battaglia · la battaglia aperta dalla casella | «Turno 3, agisce l'avversario» (28) | 2.13 s intero | 2.18 s intero | 2.19 s intero | 2.19 s intero |
| battaglia · la battaglia aperta dalla casella | «Turno 3, tocca a te» (19) | 1.53 s intero | 1.53 s intero | 1.57 s intero | 1.51 s intero |
| battaglia · evacuazione che conclude la battaglia | «Unità evacuata: costa 60» (24) | 0.79 s interrotto | 2.55 s intero | 0.78 s interrotto | 2.55 s intero |
| battaglia · evacuazione che conclude la battaglia | «La battaglia è conclusa: la ritirata è compiuta» (47) | 3.14 s intero | 3.13 s intero | 3.13 s intero | 3.13 s intero |
| battaglia · ritorno sulla mappa dopo la battaglia | «Battaglia persa in riga 1, casella 2» (36) | 0.77 s interrotto | 2.62 s intero | 0.77 s interrotto | 2.63 s intero |
| conclusione · giornata chiusa (3) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | superato dal gioco | superato dal gioco | superato dal gioco | superato dal gioco |
| conclusione · giornata chiusa (3) | «È arrivato l'inverno: la campagna è conclusa, senza vincitore» (61) | 0.00 s interrotto | 4.25 s intero | 0.00 s interrotto | 4.24 s intero |
| presa · giornata chiusa (4) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | superato dal gioco | — | superato dal gioco |
| presa · giornata chiusa (4) | «Campagna conclusa: il quartier generale avversario è caduto. Hai vinto» (70) | — | 4.57 s intero | — | 4.57 s intero |
| subita · giornata chiusa (4) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | superato dal gioco | — | superato dal gioco |
| subita · giornata chiusa (4) | «Campagna conclusa: il tuo quartier generale è caduto. Hai perso» (63) | — | 4.19 s intero | — | 4.19 s intero |
| richiamo · richiamo compiuto | «Campagna conclusa: hai richiamato l'esercito in patria. Conta come perduta» (74) | — | 4.90 s intero | — | 4.91 s intero |

## Annunci che non spostano il fuoco

| Quando | Annuncio (caratteri) | iPhone prima | iPhone dopo | iPad prima | iPad dopo |
|---|---|---|---|---|---|
| regno · resta in patria (riga attivata) | «Corvo resta in patria.» (22) | 1.55 s intero | 1.55 s intero | 1.55 s intero | 1.55 s intero |
| regno · torna al fronte (riga attivata) | «Corvo parte per il fronte.» (26) | 1.80 s intero | 1.82 s intero | 1.81 s intero | 1.81 s intero |
| regno · leva ordinata | «Leva di fanteria leggera ordinata: pronta in primavera.» (55) | 3.42 s intero | 3.41 s intero | 3.41 s intero | 3.42 s intero |
| regno · spesa annullata | «Leva di fanteria leggera: ordine annullato, risorse restituite.» (63) | 4.26 s intero | 4.26 s intero | 4.26 s intero | 4.26 s intero |
| mappa · marcia ordinata sulla casella | «Lupo marcia verso riga 3, casella 3, 2 giorni al termine» (56) | 4.22 s intero | 4.21 s intero | 4.22 s intero | 4.22 s intero |
| mappa · ultimo ordine annullato | «Ultimo ordine annullato» (23) | 1.61 s intero | 1.61 s intero | 1.61 s intero | 1.61 s intero |
| mappa · giornata chiusa dal comando | «Giornata chiusa. 2 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | 6.80 s intero | 6.79 s intero | 6.79 s intero | 6.79 s intero |
| mappa · giornata chiusa dal comando | «Giornata conclusa: comincia il giorno 2» (39) | 2.76 s intero | 2.76 s intero | 2.76 s intero | 2.76 s intero |
| mappa · tocco magico sulla mappa | «Anno 2, primavera, mancano 88 giornate all'inverno. Giorno 2. Nessun gruppo ha ancora agit…» (99) | 7.85 s intero | 7.85 s intero | 7.85 s intero | 7.84 s intero |
| scontro · piazzamento confermato | «Piazzato: costa 50, restano 310» (31) | 3.92 s intero | 3.92 s intero | 3.93 s intero | 3.93 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Turno 1, agisce l'avversario» (28) | 2.18 s intero | 2.17 s intero | 2.18 s intero | 2.17 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria leggera A avversaria in riga 1, cella 5» (63) | 4.22 s intero | 4.23 s intero | 4.23 s intero | 4.22 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria leggera B avversaria in riga 1, cella 6» (63) | 4.06 s intero | 4.07 s intero | 4.07 s intero | 4.05 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria leggera C avversaria in riga 1, cella 4» (63) | 4.36 s intero | 4.35 s intero | 4.36 s intero | 4.37 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria pesante D avversaria in riga 1, cella 7» (63) | 4.35 s intero | 4.36 s intero | 4.34 s intero | 4.35 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entra in campo fanteria pesante E avversaria in riga 1, cella 3» (63) | 3.99 s intero | 3.99 s intero | 4.01 s intero | 3.99 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Entrano in campo tiratori F avversari in riga 1, cella 8» (56) | 3.94 s intero | 3.94 s intero | 3.93 s intero | 3.94 s intero |
| scontro · turno chiuso, il turno dell'avversario | «Turno 2, tocca a te» (19) | 1.54 s intero | 1.54 s intero | 1.54 s intero | 1.55 s intero |
| scontro · movimento compiuto sulla cella | «Spostato in riga 9, cella 4: costa 52, restano 278» (50) | 6.13 s intero | 5.99 s intero | 6.00 s intero | 6.00 s intero |
| scontro · resa dichiarata | «Resa dichiarata: comincia la tua ritirata combattuta» (52) | 3.46 s intero | 3.44 s intero | 3.51 s intero | 3.44 s intero |
| battaglia · marcia verso il nemico ordinata | «Corvo marcia verso riga 1, casella 2, 1 giorno al termine» (57) | 4.23 s intero | 4.19 s intero | 4.26 s intero | 4.19 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Giornata chiusa. 1 gruppo non aveva agito e resta fermo: ne è stata conservata una traccia…» (114) | 6.55 s intero | 6.50 s intero | 6.50 s intero | 6.51 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Corvo è arrivato in riga 1, casella 2» (37) | 2.61 s intero | 2.53 s intero | 2.54 s intero | 2.54 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Imboscata scattata in riga 1, casella 2» (39) | 2.89 s intero | 2.89 s intero | 2.89 s intero | 2.90 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Battaglia in sospeso da imboscata in riga 1, casella 2» (54) | 3.55 s intero | 3.51 s intero | 3.53 s intero | 3.51 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Rifornimento di Corvo interrotto in riga 1, casella 2» (53) | 3.46 s intero | 3.48 s intero | 3.50 s intero | 3.48 s intero |
| battaglia · giornata chiusa, la battaglia che nasce | «Giornata conclusa: comincia il giorno 2» (39) | 2.75 s intero | 2.76 s intero | 2.80 s intero | 2.76 s intero |
| conclusione · giornata chiusa (cambio di stagione) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | 6.98 s intero | 7.00 s intero | 7.00 s intero | 7.00 s intero |
| conclusione · giornata chiusa (cambio di stagione) | «Giornata conclusa: comincia il giorno 2» (39) | 2.77 s intero | 2.76 s intero | 2.78 s intero | 2.76 s intero |
| conclusione · giornata chiusa (cambio di stagione) | «Nuova stagione: estate» (22) | 1.96 s intero | 1.96 s intero | 2.01 s intero | 1.96 s intero |
| conclusione · giornata chiusa (2) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | 7.00 s intero | 7.00 s intero | 7.02 s intero | 7.01 s intero |
| conclusione · giornata chiusa (2) | «Giornata conclusa: comincia il giorno 3» (39) | 2.74 s intero | 2.76 s intero | 2.74 s intero | 2.76 s intero |
| conclusione · giornata chiusa (2) | «Nuova stagione: autunno» (23) | 1.97 s intero | 1.93 s intero | 1.94 s intero | 1.93 s intero |
| mappa · divisione incompleta rifiutata | «Scegli almeno un reparto da staccare e almeno uno da tenere» (59) | — | 3.22 s intero | — | 3.22 s intero |
| presa · giornata chiusa (1) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.00 s intero | — | 7.00 s intero |
| presa · giornata chiusa (1) | «Formazione avversaria avvistata in riga 4, casella 3» (52) | — | 3.76 s intero | — | 3.76 s intero |
| presa · giornata chiusa (1) | «Occupi il quartier generale avversario, in riga 1, casella 2: se lo tieni sarà preso fra 3…» (99) | — | 6.53 s intero | — | 6.53 s intero |
| presa · giornata chiusa (1) | «Giornata conclusa: comincia il giorno 2» (39) | — | 2.75 s intero | — | 2.75 s intero |
| presa · giornata chiusa (2) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 6.98 s intero | — | 7.00 s intero |
| presa · giornata chiusa (2) | «Formazione avversaria avvistata in riga 3, casella 3» (52) | — | 3.46 s intero | — | 3.46 s intero |
| presa · giornata chiusa (2) | «Tieni il quartier generale avversario: sarà preso fra 2 giornate» (64) | — | 3.95 s intero | — | 3.95 s intero |
| presa · giornata chiusa (2) | «Giornata conclusa: comincia il giorno 3» (39) | — | 2.75 s intero | — | 2.75 s intero |
| presa · giornata chiusa (3) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.04 s intero | — | 7.00 s intero |
| presa · giornata chiusa (3) | «Formazione avversaria avvistata in riga 3, casella 2» (52) | — | 3.45 s intero | — | 3.47 s intero |
| presa · giornata chiusa (3) | «Tieni il quartier generale avversario: sarà preso fra 1 giornata» (64) | — | 3.95 s intero | — | 3.93 s intero |
| presa · giornata chiusa (3) | «Rifornimento di Falco interrotto in riga 3, casella 1» (53) | — | 3.53 s intero | — | 3.55 s intero |
| presa · giornata chiusa (3) | «Giornata conclusa: comincia il giorno 4» (39) | — | 3.07 s intero | — | 3.08 s intero |
| subita · giornata chiusa (1) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.00 s intero | — | 7.00 s intero |
| subita · giornata chiusa (1) | «L'avversario occupa il tuo quartier generale, in riga 4, casella 2: se non lo scacci sarà …» (110) | — | 7.27 s intero | — | 7.27 s intero |
| subita · giornata chiusa (1) | «Giornata conclusa: comincia il giorno 2» (39) | — | 2.76 s intero | — | 2.76 s intero |
| subita · giornata chiusa (2) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.01 s intero | — | 7.01 s intero |
| subita · giornata chiusa (2) | «Il tuo quartier generale è ancora occupato: sarà preso fra 2 giornate» (69) | — | 4.23 s intero | — | 4.23 s intero |
| subita · giornata chiusa (2) | «Giornata conclusa: comincia il giorno 3» (39) | — | 2.75 s intero | — | 2.76 s intero |
| subita · giornata chiusa (3) | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.01 s intero | — | 7.00 s intero |
| subita · giornata chiusa (3) | «Il tuo quartier generale è ancora occupato: sarà preso fra 1 giornata» (69) | — | 4.22 s intero | — | 4.22 s intero |
| subita · giornata chiusa (3) | «Giornata conclusa: comincia il giorno 4» (39) | — | 3.08 s intero | — | 3.08 s intero |
| azzeramento · giornata chiusa, l'occupazione comincia | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.00 s intero | — | 7.00 s intero |
| azzeramento · giornata chiusa, l'occupazione comincia | «Formazione avversaria avvistata in riga 4, casella 3» (52) | — | 3.77 s intero | — | 3.76 s intero |
| azzeramento · giornata chiusa, l'occupazione comincia | «Occupi il quartier generale avversario, in riga 1, casella 2: se lo tieni sarà preso fra 3…» (99) | — | 6.53 s intero | — | 6.52 s intero |
| azzeramento · giornata chiusa, l'occupazione comincia | «Giornata conclusa: comincia il giorno 2» (39) | — | 2.75 s intero | — | 2.75 s intero |
| azzeramento · tocco magico con un'occupazione in corso | «Anno 1, primavera, mancano 88 giornate all'inverno. Giorno 2. Nessun gruppo ha ancora agit…» (166) | — | 11.97 s intero | — | 11.97 s intero |
| azzeramento · marcia che lascia il quartier generale | «Corvo marcia verso riga 1, casella 3, 1 giorno al termine» (57) | — | 4.17 s intero | — | 4.17 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Giornata chiusa. 4 gruppi non avevano agito e restano fermi: ne è stata conservata una tra…» (118) | — | 7.03 s intero | — | 7.02 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Corvo è arrivato in riga 1, casella 3» (37) | — | 2.54 s intero | — | 2.53 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Formazione avversaria avvistata in riga 3, casella 3» (52) | — | 3.45 s intero | — | 3.47 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Non occupi più il quartier generale avversario: il conteggio si azzera» (70) | — | 4.08 s intero | — | 4.09 s intero |
| azzeramento · giornata chiusa dopo aver lasciato (1) | «Giornata conclusa: comincia il giorno 3» (39) | — | 2.75 s intero | — | 2.76 s intero |
| richiamo · richiamo impedito | «L'esercito non si può richiamare: Corvo ha il rifornimento tagliato in riga 2, casella 2» (88) | — | 5.36 s intero | — | 5.36 s intero |

## Riassunto

| | iPhone prima | iPhone dopo | iPad prima | iPad dopo |
|---|---|---|---|---|
| Con spostamento: interi su detti | 9 su 28 | 31 su 31 | 8 su 28 | 31 su 31 |
| Senza spostamento: interi su detti | 33 su 33 | 68 su 68 | 33 su 33 | 68 su 68 |

## Voce al 90 per cento

Misurata soltanto dopo. Per ogni annuncio: quanto dura al 50 per cento (mediana delle volte intere, dello stesso testo o, se cambia solo un numero, del testo a meno dei numeri), quanto è durato al 90, e il rapporto. Detto per intero se è durato almeno tre quarti di quanto dovrebbe, con il rapporto ricavato dalle righe che non spostano il fuoco (mediana: iPhone 3.45, iPad 3.45). Un annuncio tagliato avrebbe un rapporto più alto.

| Quando | Annuncio (caratteri) | sposta il fuoco | iPhone: 50 → 90 (rapporto) | iPad: 50 → 90 (rapporto) |
|---|---|---|---|---|
| comincia l'inverno, voce al 90 per cento | «Comincia l'inverno dell'anno 1. Entrate: monete di bronzo 20…» (175) | sì | 14.18 → 4.05 s (3.50) intero | 14.18 → 4.04 s (3.51) intero |
| addestramento ordinato, voce al 90 per cento | «Addestramento mirato ordinato per 8 atomi di fanteria pesant…» (91) | sì | 5.53 → 1.59 s (3.47) intero | 5.53 → 1.57 s (3.52) intero |
| leva ordinata, voce al 90 per cento | «Leva di fanteria leggera ordinata: pronta in primavera.» (55) | no | 3.42 → 0.99 s (3.45) intero | 3.42 → 0.99 s (3.45) intero |
| apertura della campagna, voce al 90 per cento | «Campagna aperta sul fronte del guado» (36) | sì | 2.32 → 0.68 s (3.41) intero | 2.32 → 0.68 s (3.41) intero |
| apertura della campagna, voce al 90 per cento | «Mappa Guado, 4 righe per 4 caselle. Il tuo quartier generale…» (83) | sì | 6.27 → 1.82 s (3.45) intero | 6.27 → 1.84 s (3.41) intero |
| apertura della campagna, voce al 90 per cento | «Anno 1, primavera, mancano 89 giornate all'inverno. Giorno 1…» (99) | sì | 7.92 → 2.29 s (3.46) intero | 7.92 → 2.30 s (3.44) intero |
| giornata chiusa, voce al 90 per cento | «Giornata chiusa. 5 gruppi non avevano agito e restano fermi:…» (118) | no | 7.00 → 2.02 s (3.47) intero | 7.00 → 2.00 s (3.50) intero |
| giornata chiusa, voce al 90 per cento | «Giornata conclusa: comincia il giorno 2» (39) | no | 2.76 → 0.81 s (3.41) intero | 2.76 → 0.81 s (3.41) intero |

## Gli annunci della build 32 tagliati che il sistema dava per riusciti

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

## Dove arriva il fuoco

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
