# La verifica attraverso l'interfaccia, con VoiceOver (incarico 30)

Canale: il pilota dell'incarico 28 (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`, `test_sessione_da_tester`, schema `WarSenseEsplorazione`), che gira sul simulatore con VoiceOver acceso e legge i comandi da `comandi.jsonl`. Lettura: `XCUIVoiceOverService` (la pronuncia restituita si tronca a 64 caratteri) e l'albero di accessibilità. Lo guidano due programmi:

- `percorsi-regno.py` (questa cartella): i percorsi del regno a controlli, cinque blocchi — patria, inverno, campagna, orizzontale, testo massimo —; per ogni controllo scrive atteso, trovato ed esito in `controlli.jsonl`.
- `scripts/tester.py <cartella> <formato> <giornate> regno <opzioni>`: il tester dell'incarico 28 che gioca UN ANNO del regno, dall'avvio alla seconda primavera, decidendo soltanto su ciò che sente e che l'albero espone; scrive un diario.

Simulatori iOS 27.0: «WarSense iPhone Air» C86CB490…, «WarSense iPad Pro 13» D01FE19F…, «WarSense iPhone Air · 3» E2C6F42C….

## Le corse

| cartella | app | che cosa | esito |
|---|---|---|---|
| `iphone/prima-corsa/`, `ipad/prima-corsa/` | costruita da `affb882` | percorsi: patria, inverno, campagna | 31 e 32 controlli su 34: i tre falliti erano controlli scritti male (l'albero riporta ogni pulsante due volte; un confronto voleva 66 caratteri di una pronuncia che ne ha 64) |
| `iphone/seconda-corsa/`, `ipad/seconda-corsa/` | la stessa | percorsi, cinque blocchi | 36 e 37 su 39: in orizzontale la lettura è giusta ma il doppio tocco sintetico non attiva (due controlli); a testo massimo sull'iPhone VoiceOver legge in coda la barra di scorrimento di sistema (uno) |
| `iphone/tester-prima-della-correzione/`, `ipad/tester-prima-della-correzione/`, `iphone-3/` | la stessa | il tester: un anno (`piccola 12`, `media 8`, e sul terzo iPhone `piccola 30`, tutti con `regno tutti`) | la voce resta indietro: vedi sotto |
| `iphone/dopo-la-correzione/`, `ipad/dopo-la-correzione/` | costruita da `ade0ce9`, il codice della build 31 | il tester: un anno, gli stessi parametri; poi i percorsi, cinque blocchi (terza corsa) | anno giocato a orecchio sui due apparecchi; percorsi 39 su 39 e 38 su 38 |
| `ipad/dopo-la-correzione/diario-piccola.jsonl` | la stessa | il tester con l'opzione `contatto`, che marcia verso la formazione armata avversaria | vedi il resoconto dell'incarico |

In ogni cartella `controlli.jsonl` (o `controlli-terza-corsa.jsonl`) porta gli esiti e `guidatore*.log` l'uscita del guidatore; `comandi-della-sessione-del-pilota.jsonl` ed `esiti-della-sessione-del-pilota.jsonl` portano ogni passo del pilota (pronunce, fuoco, albero quando chiesto). `schermate/`: venti schermate scelte.

## Che cosa hanno sentito i percorsi (terza corsa, app della build 31)

- **Patria.** Fuoco d'apertura sul titolo; lettura in ordine: «Patria», «Anno 1, primavera», «Nessuna campagna aperta quest'anno», «Riserve», le cinque riserve una per una, «Forze», le cinque formazioni, i comandi. Il tocco magico: «Anno 1, primavera. Nessuna campagna aperta quest'anno».
- **Inverno.** «Comincia l'inverno dell'anno 1. Entrate: monete di bronzo 200, u…», poi il fuoco sulla data «Anno 1, inverno, schermata 1 di 4». Le riserve dopo l'entrata: 220, 26, 33, 33, 13. Ogni voce col costo sulla riserva. Ordinata una leva: «Leva di fanteria pesante ordinata: pronta in primavera.»; spostando il fuoco avanti e indietro, avanti «Leva di cavalleria manovrata…» e indietro «Leva di fanteria pesante. Costa: monete di bronzo 64 su 156…»: il fuoco era rimasto sulla voce, che si rilegge sulla riserva nuova. Alla terza leva pesante: «Non si può ordinare: mancano metalli.», e la voce lo dice in testa. Annullamento («…: ordine annullato, risorse restituite.»), azzeramento («Spese della schermata azzerate: 1 ordine ritirato»), e i due a vuoto («Nessuna spesa da annullare in questa schermata», «Nessuna spesa da azzerare in questa schermata»). Le quattro schermate, poi «Comincia la primavera dell'anno 2. Il riporto ha tolto: …» e il fuoco su «Anno 2, primavera»; quattro gruppi armati, l'ultimo di 6 atomi di fanteria leggera. Il registro della patria dal più recente.
- **Campagna.** «Su quale fronte?» con una voce per fronte e la sua mappa; sulla mappa sei formazioni proprie e «Torna in patria»; il tocco magico «Anno 2, primavera, mancano 89 giornate all'inverno. Giorno 1. …»; chiusa una giornata e tornati in patria, «Anno 2, primavera, giorno 2 di 90», «Campagna aperta sul fronte del guado», fuoco su «Entra nel fronte del guado»; chiusa e riaperta l'app, «Riprendi il regno» in testa e la campagna allo stesso giorno.
- **Orizzontale.** La patria in primavera e d'inverno, con una leva ordinata, lette nello stesso ordine fino all'ultimo comando. Soltanto la lettura: in orizzontale il pilota non attiva nulla (doppio tocco sull'elemento, doppio tocco in un punto, Control-Opzione-Spazio da tastiera: provati, senza effetto); l'attivazione in orizzontale la copre `FumoRegnoTest` col tocco vero.
- **Testo massimo.** La patria d'inverno letta per intero; una leva ordinata. Sull'iPhone, dopo l'ultimo comando, VoiceOver legge «Vertical scroll bar, 8 pages…»: la barra di scorrimento che iOS espone per i contenuti lunghi (in inglese perché il simulatore è in inglese). Registrata come osservazione, non toccata.

## La voce che restava indietro (RDA-172)

`ritardo-della-voce.py <diario> <giornate giocate muovendo i gruppi>` confronta, per ogni pressione di «Chiudi la giornata», il giorno che comincia davvero con quello che la voce annuncia nei tre secondi d'ascolto. Le tabelle sono accanto a ciascun diario (`ritardo-della-voce.md`).

| corsa | chiusure col tasto | ritardo massimo, in giornate |
|---|---|---|
| iPhone, prima | 78 | 17 |
| iPad, prima | 82 | 18 |
| terzo iPhone, prima | 60 | 14 |
| iPhone, dopo | 78 | 1 |
| iPad, dopo | 82 | 1 |

Prima della correzione il ritardo cresce di una giornata ogni quattro o cinque chiusure. Sull'iPad è entrato in patria: la lettura della dichiarazione di conclusione ha restituito annunci vecchi del fronte; premuto «Attendi l'inverno» si è sentito «Rifornimento di Falco interrotto in riga 2, casella 4 | Giornata conclusa: comincia il giorno 81»; la conferma della leva non è arrivata nell'ascolto, il tester l'ha data per non confermata e ha poi annullato l'ultima spesa, che era quella: in primavera nessuna recluta. Sui due iPhone la lettura della dichiarazione è durata abbastanza (76,6 secondi sul primo) perché la coda si esaurisse, e l'inverno si è giocato.

Dopo la correzione, sui due apparecchi: la dichiarazione letta riga per riga («Campagna conclusa», «L'inverno ha interrotto la campagna sul fronte …: nessun vincitore», «Durata: 90 giornate», «Battaglie vinte: 0. Battaglie perse: 0», «Rientrano in patria: 5 formazioni», «Nessun premio: quest'inverno arriva la sola rendita», «Torna in patria»); «Comincia l'inverno dell'anno 1. Entrate: …»; quattro leve ordinate, ciascuna confermata a voce; «Non si può ordinare: mancano monete di bronzo, mancano uomini.»; «Leva di cavalleria manovrata: ordine annullato, risorse restitui…»; le quattro schermate; «Comincia la primavera dell'anno 2. Il riporto ha tolto: …»; riserve 20, 2, 3, 3, 1; un gruppo armato nuovo con tre reparti (6 e 6 atomi di fanteria leggera, 8 di fanteria pesante); nella campagna dell'anno nuovo sei formazioni sulla mappa, fra cui «tua Lince … composta da 6 atomi di fanteria leggera, 6 atomi di fanteria leggera, 8 atomi di fanteria pesante».

## Che cosa NON si guida, e si dichiara

Il gesto di fuga (nessuna API; il tasto Esc non arriva come `accessibilityPerformEscape`); l'attivazione in orizzontale; la pronuncia vera, l'aptica e i suoni. Il campo «numero» delle righe `giornata_chiusa` dei diari conta i tentativi del tester, non il giorno del gioco: il giorno è nel testo sentito.
