# Incarico 30 — resoconto

`P/` sta per `Incarichi/30-2026-11-22-prodotti/`.

## In testa

- Build 31: uscita. Su App Store Connect, per API: `VALID`, non scaduta, caricata il 2026-11-22T14:35:32-08:00, treno 1.1.0, in prova interna, gruppo «WarLab» con accesso a tutte le build, nota allegata e identica a `note-di-rilascio.txt` (riallegata dopo un'aggiunta: vedi «App Store Connect»); `build-caricate.md` concorde.
- Commit finale di `principale`: quello che porta questo resoconto (il numero è nel messaggio finale della sessione, perché un commit non può citare sé stesso); commit della build: `7ef91fd`. Rami spinti: `principale`; `incarico-30` fuso e cancellato, locale e remoto.
- Il piano: `Proposte/piano-del-regno.md`. Le domande per il titolare: `Proposte/domande-per-il-titolare-sul-regno.md` (sei). La proposta delle classi dei campioni: `Proposte/classi-dei-campioni.md`.
- Prima tappa costruita: «l'anno del regno». Dalla patria si apre la campagna dell'anno su uno dei tre fronti, la campagna ha un calendario e si conclude (annientamento o inverno), l'esito arriva in patria con una dichiarazione, l'inverno porta un bilancio e quattro schermate in cui ordinare leve, la primavera applica il riporto e manda le reclute al fronte.
- Verificata con il collaudo (430 casi passati e 2 saltati nel pacchetto, 137 prove fra ospitate e interfaccia, tutte passate), le sessioni complete (144 campagne attraverso l'interfaccia e le sessioni al Motore, verdi sul codice della build), il pilota e il tester con VoiceOver su iPhone e iPad, il banco del regno (1786 anni, nessuna violazione) e la riapertura dal vivo dei salvataggi della build 30.
- Il tester con VoiceOver ha trovato un difetto che la tappa rendeva ordinario: chiudendo le giornate in fila la voce restava indietro, fino a 17 giornate sull'iPhone e a 18 sull'iPad, e sull'iPad la conferma di una leva non è stata sentita. Corretto (RDA-172), ripetuto dal vivo.
- Versioni: valori 0.14.0, schema del giornale di campagna 9 e di battaglia 2, testi 0.1.1, tutti fermi; giornale del regno, nuovo, schema 1. I salvataggi della build 30 si riaprono: provato dal vivo.
- Lasciato com'era, come chiesto: le battaglie che al banco non si concludono (col regno il 26,4% degli anni della condotta competente sul fronte del guado), lo sbilanciamento delle vittorie fra le mappe, la virgola nelle azioni d'ingaggio.

## Lo stato di partenza, verificato

`git rev-parse principale origin/principale`: `2a86f6e` entrambi; `git status --short`: vuoto. Valori 0.14.0 (`Codice/Sources/Contenuti/Valori/manifest.json`), schema del giornale di campagna 9 (`FondazioneCampagna.schemaCorrente`), ultimo RDA 161 e ultimo scostamento S27h (`grep` sui due registri, e sui rami remoti: soltanto `principale`). App Store Connect, per API prima del caricamento: build 30 `VALID`, non scaduta, caricata il 2026-11-21T12:42:06-08:00, treno 1.1.0; sotto, la 29 e la 28. Collaudo del pacchetto sul commit di partenza: `swift test` verde in 61 s (`date +%s`).

## Le versioni della macchina

macOS 27.0.1 (26A434), Xcode 27.2 (27B52), Swift 6.4.2, xcodegen 2.45.4, Python 3.9.6; Apple M5 Pro, 15 processori (`sysctl`). Simulatori iOS 27.0 (24A434), tutti di WarSense: «WarSense iPhone Air» C86CB490…, «· 2» 76DF33B6…, «· 3» E2C6F42C…, «· 4» 87AB2F55…, «WarSense iPad Pro 13» D01FE19F…. Nessun simulatore altrui era acceso quando ho guardato (`xcrun simctl list devices booted`: soltanto i nostri); non ho spento, azzerato né creato nulla che non fosse nostro, e Device Hub non è stato aperto. A fine sessione ho controllato col cancello che VoiceOver fosse spento sui quattro simulatori di WarSense rimasti accesi e li ho spenti uno per uno.

## Che cosa c'è di nuovo da giocare

Dall'avvio, «Nuovo regno» (e «Riprendi il regno» se ce n'è uno), in testa alle voci di prova, che restano. La patria: data, campagna dell'anno, riserve voce per voce, forze, comandi, registro. «Apri la campagna» chiede il fronte (guado, istmo, pianura lunga: le tre mappe esistenti) e apre la mappa con le forze del regno; l'informazione di stato comincia dalla data e dice quante giornate mancano all'inverno; «Torna in patria» lascia la mappa a campagna aperta. La campagna si conclude quando una parte resta senza gruppi armati o chiusa la novantesima giornata; la dichiarazione di conclusione dice modo, durata, battaglie, rientro e premi. «Attendi l'inverno»: entrata dell'anno, quattro schermate, tre leve con il costo sulla riserva e l'impossibilità dichiarata, annullamento e azzeramento fino al cambio di schermata. «Prosegui alla primavera»: riporto, reclute come gruppo armato nuovo, anno nuovo.

## Come è stata verificata

**Pacchetto.** `RegnoTest` (11), `CampagnaDelRegnoTest` (16), `SessioneRegnoTest` con la riproduzione d'oro di due anni, `CaricamentoRegnoTest` (7), `TraduttoreRegnoTest` (11), `BancoRegnoTest` (5), `CodaAnnunciTest` (6), più le estensioni di `CompatibilitaGiornaleTest`, `AccordoDiGenereTest` e `ConfiniTest`.

**Ospitate.** `PatriaTest` (7): ordine di lettura, costo sulla riserva, fuoco fermo dopo la spesa, impossibilità, annullamento e azzeramento, quattro schermate e primavera, campagna aperta dalla patria e ritorno, conclusione per inverno con stagioni di una giornata, esito riportato alla ripresa. `AnnoDelRegnoTest` (2): un anno intero coi valori veri attraverso le schermate, battaglie comprese — l'esecutore stampa «ANNO-DEL-REGNO-30 fronte=guado conclusione=annientamento vincitore=giocatore giornate=17 battaglie=2 vinte=1 perse=1 formazioni_partite=5 rientrate=4 leve=6 formazioni_anno_2=5» —, e la battaglia di una campagna del regno ripresa dopo un riavvio a battaglia aperta, dai tre slot annidati («RIPRESA-BATTAGLIA-DEL-REGNO-30 giorno=11 casella=riga 1 casella 2 sconfitto=giocatore dopo=campagna ancora aperta»). `TestoDinamicoTest`: patria in primavera e d'inverno e dichiarazione di conclusione alla dimensione massima.

**Interfaccia, col tocco vero.** `FumoRegnoTest` (2): patria, inverno, leva, annullamento, quattro schermate, primavera, scelta del fronte, mappa e ritorno; e in orizzontale a testo massimo l'inverno percorso fino all'ultimo comando con una leva ordinata.

**Il pilota con VoiceOver, iPhone e iPad** (`P/verifica-con-voiceover/`, guidatore `percorsi-regno.py`). Tre corse. La prima (patria, inverno, campagna; app di `affb882`): 31 controlli su 34 sull'iPhone e 32 sull'iPad, in 332 s ciascuna; i tre falliti erano miei controlli scritti male. La seconda (cinque blocchi): 36 e 37 su 39, in 486 e 487 s; falliti i due controlli dell'attivazione in orizzontale, che il pilota non sa fare, e sull'iPhone la lettura a testo massimo, dove VoiceOver legge in coda la barra di scorrimento di sistema. La terza, sull'app della build (`ade0ce9`), coi controlli dell'orizzontale ridotti alla lettura e la barra di sistema registrata come osservazione: 39 su 39 sull'iPhone e 38 su 38 sull'iPad, in 495 e 497 s. Che cosa si è sentito, blocco per blocco, è nel README della cartella; in breve: fuoco d'apertura sul titolo; l'ordine di lettura della patria in primavera e d'inverno, in verticale, in orizzontale e a testo massimo; l'arrivo dell'inverno annunciato con l'entrata e il fuoco in testa alla data; il costo sulla riserva; dopo una spesa il fuoco che resta sulla voce (accertato spostandolo avanti e indietro: avanti la voce che segue, indietro la voce ordinata col costo sulla riserva nuova); l'impossibilità detta in testa alla voce e a voce quando la si ordina; annullamento e azzeramento, anche a vuoto; le quattro schermate; la primavera con il riporto e il gruppo delle reclute; il registro della patria; la scelta del fronte; il tocco magico sulla mappa con la data; il ritorno in patria col fuoco sul comando d'ingresso; la ripresa del regno a campagna aperta. Sulle schermate (`P/verifica-con-voiceover/schermate/`, venti): a testo massimo sull'iPhone la voce di una leva va a capo su nove righe (contate a occhio sulla schermata) e resta dentro lo schermo; in orizzontale la colonna scorre e nulla esce dal bordo.

**Il tester con VoiceOver** (`scripts/tester.py <cartella> <formato> <giornate> regno tutti`: un anno dall'avvio alla seconda primavera). Prima della correzione di RDA-172 (app di `affb882`): iPhone, fronte del guado, dodici giornate muovendo i gruppi e 78 chiuse col tasto, 2165 s; iPad, fronte dell'istmo, otto e 82, 1811 s; un terzo iPhone, guado, trenta e 60, 3872 s. Nessuna battaglia in nessuna delle tre campagne: tutte concluse dall'inverno. Sui due iPhone l'anno si è chiuso a orecchio; sull'iPad no, per il ritardo della voce (sezione seguente). Dopo la correzione (app di `ade0ce9`), stessi parametri: iPhone 2091 s, iPad 1851 s, anno chiuso a orecchio su entrambi — dichiarazione letta riga per riga, inverno annunciato, quattro leve confermate a voce, l'impossibilità detta, una spesa annullata, quattro schermate, primavera, sei formazioni sulla mappa dell'anno nuovo.

**Un anno con una battaglia, con VoiceOver.** In cinque campagne — tre prima della correzione, due dopo — il tester non ne aveva incontrate: muove gli armati verso nord, e i gruppi che arrivano nella riga del quartier generale nemico restano senza rifornimento e non marciano oltre. Ho aggiunto l'opzione `contatto` (marcia verso la formazione armata avversaria che la mappa dichiara) e rigiocato l'anno sull'iPad con l'app della build (`piccola 25 regno contatto`, 3573 s). Al diciassettesimo giorno il gruppo più debole, sei atomi di fanteria leggera, entra nella casella del quartier generale nemico; la battaglia si apre («Entra in campo fanteria leggera A avversaria in riga 1, cella 5 | Entra in campo fanteria pesante B avversaria in riga 1, cella 6»), dura nove turni e il resoconto dice «Sconfitta: è stato annientato», «Perdite tue: 600 punti su 600 impegnati», «Perdite inflitte: 150 punti». Si torna sulla mappa al giorno 18, a campagna aperta. A fine autunno la dichiarazione dice «Battaglie vinte: 0. Battaglie perse: 1», «Rientrano in patria: 4 formazioni», «Nessun premio: quest'inverno arriva la sola rendita»; poi l'inverno con quattro leve confermate a voce e la primavera, dove il gruppo caduto non c'è. Ritardo della voce: 1 per tutte le 65 chiusure.

**Visto in quella corsa, già dichiarato come limite (RDA-166, S28l), e ora scritto nelle note.** Dopo la perdita di un gruppo i nomi scorrono: nell'anno nuovo «Corvo» è la formazione che era «Lupo» (18 atomi di fanteria leggera, 8 di pesante), «Lupo» quella che era «Falco», «Falco» è la ricognizione, «Orso» la formazione non armata, «Cervo» il gruppo delle reclute. Il regno conserva le formazioni senza nome e le dispone nell'ordine sulle caselle dello scenario. Per chi gioca a orecchio il nome è l'identità del gruppo: si corregge nella seconda tappa, quando il regno conserverà le formazioni coi loro nomi.

**Osservato, non toccato.** Il congedo del resoconto di una battaglia di campagna si chiama «Torna all'inizio» e riporta sulla mappa: è così dalle campagne di prova, e nel regno suona ancora meno giusto.

**Il banco del regno** e la misura ripetuta: più sotto.

**I salvataggi della build 30** (`P/salvataggi-build-30/`): più sotto, alle versioni.

**I cancelli visti rifiutare** (`P/cancelli-visti-fallire/README.md`): il confine della modalità, i campioni del giornale, l'accordo di genere sulla categoria nuova, il caricatore dei valori del regno con quattro file guasti, la sonda coi tredici mutanti, la regola della coda degli annunci, VoiceOver acceso sul simulatore del collaudo.

## Che cosa è successo durante l'esecuzione

In ordine di tempo, compreso ciò che è stato risolto.

1. **Errori di compilazione voluti dai cancelli.** I casi nuovi di `EventoCampagna`, `FattoRegistrato` e `VoceGiornale` non compilavano finché Segnali, Verifica e lo specchio di `CompatibilitaGiornaleTest` non li trattavano; le sei righe campione del regno le ho generate con una prova temporanea, poi tolta, e aggiunte a `campioni.jsonl`.
2. **Una mia attesa sbagliata** in `RegnoTest`, corretta prima di eseguire: la seconda leva pesante manca di denaro e di metalli insieme.
3. **Il primo collaudo completo si è fermato in 53 s** su `AccordoDiGenereTest`: in `SchermataPatria.swift` due chiamate a `frase(` senza virgola fra loro facevano leggere all'espressione regolare del cancello una chiave non letterale. Cambiato il mio codice, non il cancello.
4. **Il banco del regno cadeva** (uscita 133, `Motore/MotoreCampagna.swift:545: Precondition failed: comando.di.campagna.non.valido.applicato`) con tre partite o più. Causa: chiusa l'ultima giornata d'autunno la campagna era conclusa, e il ciclo dell'avversario dello strumento di misura applicava ancora una proposta senza convalidarla. Corretto lo strumento, che ora convalida come la Sessione e conta le proposte respinte: zero in tutte le misure.
5. **Il secondo collaudo completo, verde con 133 prove in 329 s, non valeva**: era partito mentre scrivevo ancora la parte da riga di comando del banco. Lo ha mostrato il quarto (punto 10).
6. **La sessione si è interrotta una volta** per il limite d'uso, coi due piloti appena avviati: fermati col comando di fine, tutto committato e spinto (`187e1aa`), poi ripresa.
7. **La prima corsa dei percorsi con VoiceOver** ha dato 31 e 32 controlli su 34: i tre falliti erano controlli scritti male (l'albero riporta ogni pulsante due volte; la pronuncia si tronca a 64 caratteri e il mio confronto ne voleva 66). Corretti, corsa ripetuta.
8. **In orizzontale il pilota legge ma non attiva.** Il doppio tocco sintetico sull'elemento non arriva; ho provato anche il doppio tocco in un punto qualsiasi e il comando da tastiera di VoiceOver (Control, Opzione, Spazio): nessun effetto. L'attivazione in orizzontale la copre `FumoRegnoTest` col tocco vero, senza VoiceOver.
9. **`FumoRegnoTest` rossa sul simulatore su cui il pilota era appena uscito**: dopo il tocco su «Nuovo regno» la patria non si apriva. Prima ipotesi, sbagliata: un difetto dell'installazione migrata dalla build 30 (era lo stesso simulatore). Lo stesso gesto col pilota apriva la patria. Causa: il pilota aveva lasciato VoiceOver acceso, e col lettore acceso il tocco semplice mette a fuoco e non attiva. Ne sono nati il cancello `scripts/controlla-voiceover-spento.sh` e lo spegnimento all'uscita del pilota (RDA-171). Il cancello ha poi rifiutato per davvero, in 2 s, il collaudo lanciato sul quarto iPhone, dove VoiceOver era rimasto acceso da un incarico precedente.
10. **Il quarto collaudo completo si è fermato in 61 s** su `ConfiniTest.test_00_14_1_nessuna_stringa_di_testo_utente_nel_codice`: il riepilogo da riga di comando in `Verifica/BancoRegno.swift` interpolava espressioni con spazi dentro stringhe letterali. Corretto calcolando i valori prima; l'uscita dello strumento sulla misura intera è identica byte per byte a quella già nei prodotti (`cmp`). Era nel codice committato da `3f870d8`.
11. **Le note di rilascio rifiutate a 4001 caratteri su 4000** da `scripts/controlla-note.py`, dopo l'aggiunta di un paragrafo; accorciate a 3970.
12. **La voce che restava indietro** (RDA-172), trovata dal tester: più sotto.

Nessuna intermittenza osservata: nessuna prova è passata a una seconda esecuzione dopo aver fallito alla prima a codice invariato.

## La voce che restava indietro (RDA-172)

Il tester aspetta l'inverno chiudendo le giornate col tasto, una ogni dieci secondi circa. Sull'iPhone, dopo 78 chiusure, la campagna chiudeva la novantesima giornata e la voce diceva «Giornata conclusa: comincia il giorno 74»; sull'iPad, dopo 82, «comincia il giorno 73». Misura di `P/verifica-con-voiceover/ritardo-della-voce.py` sui diari (giorno che comincia dopo la chiusura meno giorno annunciato): il ritardo parte da 1 e cresce fino a 17 sull'iPhone e a 18 sull'iPad, una giornata ogni quattro o cinque chiusure. Sull'iPad il ritardo è entrato in patria: la lettura della dichiarazione ha restituito annunci vecchi del fronte al posto delle sue righe; premuto «Attendi l'inverno» si è sentito «Rifornimento di Falco interrotto in riga 2, casella 4 | Giornata conclusa: comincia il giorno 81»; la conferma della leva non è arrivata nei tre secondi e mezzo d'ascolto, il tester l'ha data per non confermata e ha poi premuto «Annulla l'ultima spesa», che ha ritirato proprio quella leva: in primavera cinque formazioni, nessuna recluta. Sull'iPhone la lettura della dichiarazione è durata 76,6 s, abbastanza perché la coda si esaurisse: l'inverno è arrivato con il suo annuncio, quattro leve confermate a voce, l'impossibilità («Non si può ordinare: mancano monete di bronzo, mancano uomini.»), un annullamento, le quattro schermate, la primavera, e nella campagna nuova sei formazioni, fra cui «tua Lince … composta da 6 atomi di fanteria leggera, 6 atomi di fanteria leggera, 8 atomi di fanteria pesante».

Causa, correzione e prove sono in RDA-172. Dal vivo con l'app corretta: una chiusura ascoltata per sedici secondi dà «Giornata chiusa. 5 gruppi non avevano agito e restano fermi: …» e poi «Giornata conclusa: comincia il giorno 2»; tre chiusure con un secondo d'ascolto ciascuna, poi sedici secondi: «Giornata chiusa…» e «comincia il giorno 5», che è il giorno vero. Il tester ha rigiocato l'anno intero sui due apparecchi con l'app corretta: il ritardo misurato dallo stesso script resta 1 per tutte le chiusure (78 sull'iPhone, 82 sull'iPad), cioè la voce sta dicendo la giornata appena chiusa.

| corsa | chiusure col tasto | ritardo massimo, in giornate |
|---|---|---|
| iPhone, prima | 78 | 17 |
| iPad, prima | 82 | 18 |
| terzo iPhone, prima | 60 | 14 |
| iPhone, dopo | 78 | 1 |
| iPad, dopo | 82 | 1 |

Il difetto non nasce in questo incarico: il tasto e la coda sono quelli della build 30. Il regno lo rende ordinario, e per questo l'ho corretto qui.

## La conclusione della campagna nel minimo: che cosa manca rispetto ai documenti

Esiste: annientamento (una parte senza gruppi armati al ritorno da una battaglia; se nessuna delle due ne ha, vince il giocatore) e inverno (chiusa l'ultima giornata d'autunno e risolte le battaglie nate da quella chiusura, nessun vincitore), per le sole campagne che dichiarano un calendario. Manca: la presa del quartier generale (01 §5.14.3.2); la resa della campagna e il ritiro prima dell'inverno (01 §5.14.3.3 la nomina, nessun punto la definisce: domanda 4); le conseguenze territoriali (01 §5.14.2, A §9.3); le opere da campo che cadono con la campagna; un vincitore per la campagna che l'inverno interrompe (domanda 3); la regola dell'annientamento simultaneo letta dal file dei vantaggi nascosti (oggi è nel Motore, S28f). Le campagne di prova restano senza stagioni e senza conclusione. RDA-164, S28f, `Proposte/piano-del-regno.md` §4.

## Il banco del regno e la misura della frequenza ripetuta

**La misura della frequenza delle battaglie**, ripetuta perché la tappa tocca il Motore della campagna (`P/frequenza-battaglie/`): 1200 partite, dati grezzi identici byte per byte a quelli dell'incarico 29 (`cmp`: nessuna differenza; `shasum -a 256`: d2e2002b608282802aec36269b40aa4f0c08df5bfb03bb99173da79ae5fca567 per entrambi), riepilogo identico (`diff`), 8 s. Ripetuta di nuovo dopo la correzione del riepilogo del banco (punto 10 dell'esecuzione): ancora identica.

**Il banco del regno** (`P/banco-del-regno/`; `StrumentoVerifica --regno 200 --anni 5`, 5 s; tabelle da `riassumi.py`): 400 partite, 1786 anni giocati su 2000, nessun errore, nessuna violazione dei tredici invarianti, nessuna proposta avversaria respinta.

| condotta | fronte | anni | vinta per annientamento | persa | inverno | ferma al banco | con almeno una battaglia | battaglie per anno |
|---|---|---|---|---|---|---|---|---|
| competente | guado | 284 | 104 (36,6%) | 0 | 105 (37,0%) | 75 (26,4%) | 239 (84,2%) | 2,20 |
| competente | istmo | 246 | 0 | 0 | 232 (94,3%) | 14 (5,7%) | 80 (32,5%) | 1,06 |
| competente | pianura lunga | 265 | 11 (4,2%) | 0 | 247 (93,2%) | 7 (2,6%) | 89 (33,6%) | 0,64 |
| prudente | guado | 330 | 0 | 0 | 317 (96,1%) | 13 (3,9%) | 250 (75,8%) | 0,76 |
| prudente | istmo | 331 | 0 | 0 | 331 (100%) | 0 | 331 (100%) | 2,25 |
| prudente | pianura lunga | 330 | 0 | 0 | 327 (99,1%) | 3 (0,9%) | 261 (79,1%) | 0,79 |
| competente | tutti | 795 | 115 (14,5%) | 0 | 584 (73,5%) | 96 (12,1%) | 408 (51,3%) | 1,33 |
| prudente | tutti | 991 | 0 | 0 | 975 (98,4%) | 16 (1,6%) | 842 (85,0%) | 1,27 |

Che cosa dicono. La campagna dell'anno finisce quasi sempre con l'inverno (1559 anni su 1786). Il giocatore non perde mai una campagna per annientamento. Le forze crescono d'anno in anno, perché l'avversario non ha un inverno (mediana degli atomi alla partenza, anni conclusi: competente 75, 101, 109, 125, 138,5; prudente 75, 101, 101, 121, 121): è il difetto atteso finché non esiste il regno avversario (tappa 3), e lo dice la nota. 112 anni si fermano su una battaglia che al banco non si conclude entro 400 giri, 96 della condotta competente, 75 delle quali sul guado: il regno porta su quel fronte le forze dello scenario medio, e il reperto dell'incarico 29 vi diventa frequente. Delle 200 partite competenti 104 giocano cinque anni interi; delle prudenti 184. Non corretto: l'incarico lo lascia a un incarico successivo.

## App Store Connect

`scripts/carica-testflight.sh` da `principale` a `7ef91fd`, col collaudo interno sul quarto iPhone (`WARSENSE_SIMULATORE`), perché sul primo giocava ancora il tester: uscita 0 in 581 s (`date +%s` attorno allo script). I controlli preventivi: principale spinto; versione 1.1.0 non inferiore alla più alta; numero di build 30 → 31; note (3970 caratteri, fresche su `ade0ce9`, 65 nomi citati tutti esposti dal codice, nessuna cifra non dichiarata, nessuna prova chiesta al titolare); registro e App Store Connect concordi a 30 build; sessioni complete fresche su `ade0ce9`; collaudo completo verde (137 prove). `altool`: «UPLOAD SUCCEEDED with no errors», 1 956 866 byte. Registro filtrato in `P/build-31/caricamento-31.txt`.

Verifica per API dopo il caricamento (`P/build-31/verifica_asc.py`, uscita in `verifica-asc-uscita.txt`):

| build | stato | caricata | scaduta | treno |
|---|---|---|---|---|
| 31 | VALID | 2026-11-22T14:35:32-08:00 | False | 1.1.0 |
| 30 | VALID | 2026-11-21T12:42:06-08:00 | False | 1.1.0 |
| 29 | VALID | 2026-11-21T05:05:58-08:00 | False | 1.1.0 |

Build 31: `internalBuildState IN_BETA_TESTING`, `externalBuildState READY_FOR_BETA_SUBMISSION`, `autoNotifyEnabled True`. Nota per i tester (it): 3969 caratteri, uguale a `note-di-rilascio.txt`. Gruppo «WarLab»: interno, `hasAccessToAllBuilds True`. `controlla-build.py`: «registro e App Store Connect concordano: 31 build, la più alta è la 31». Riga del registro: `| 31 | 2026-11-22 22:35:32 | 1.1.0 | `7ef91fd` | scritta dallo script al caricamento |`. Nessun certificato né profilo toccato.

**La nota aggiornata dopo il caricamento.** Il diario dell'anno con la battaglia ha mostrato i nomi dei gruppi che scorrono da un anno all'altro: l'ho scritto nelle note di rilascio (ora 3996 caratteri) e nella nota per il titolare, committate su `principale`, e ho riallegato la nota alla build 31 con `scripts/nota-testflight.sh 31`. Verifica per API ripetuta (`P/build-31/verifica-asc-dopo-la-nota-aggiornata.txt`): build 31 `VALID`, stesso treno e stesso stato di prova; nota per i tester di 3995 caratteri, uguale a `note-di-rilascio.txt`; registro e App Store Connect concordi a 31 build.

## Le versioni: la valutazione

Valori 0.14.0, fermi. Il criterio di 03 §9.2.1 chiede se una partita salvata prima, riaperta dopo, proseguirebbe diversamente: le partite che esistono sono scontri e campagne di prova; il Motore della battaglia non è toccato; quello della campagna cambia soltanto dove è dichiarato un calendario, che nessuna campagna salvata dichiara; `regno.json` è una voce nuova che nessuna partita esistente legge. La coda degli annunci (RDA-172) è Segnali e Presentazione: nessuna regola del Motore. `versioni_compatibili` invariato; impronte dei due manifest rigenerate. Schema del giornale di campagna 9 e di battaglia 2, fermi: le tre righe nuove sono del giornale del regno, che nasce con lo schema 1, e i campi nuovi di stato e scenario di campagna si omettono quando assenti. Testi 0.1.1, fermi. Versione di marketing 1.1.0, non toccata. RDA-170.

**Verificato dal vivo** (`P/salvataggi-build-30/`): sul secondo iPhone, app disinstallata; l'app e il pilota compilati dal commit della build 30 (`402a9b1`, esportato con `git archive` in `Applicazione/build-interattivo/`, cartella esclusa da git, e tolto a fine sessione: nell'app non c'è `regno.json`) lasciano una campagna piccola al terzo giorno, con un ordine dato, e uno scontro con una riserva piazzata; il pilota del codice nuovo installa l'app sopra, e l'avvio offre «Nuovo regno» con le due riprese; la mappa espone le stesse 16 caselle e la stessa informazione di stato, la giornata si chiude e comincia il giorno 4; la griglia espone le stesse 100 celle. Otto controlli, otto «ok»; 126 s e 82 s. Sullo stesso apparecchio un regno nuovo si apre, e `Documents/Valori/regno.json` c'è dopo il primo avvio dell'app nuova. Non verificato: un salvataggio di build più vecchie della 30; un'installazione vera da TestFlight su un apparecchio.

## Le decisioni prese da solo, e perché

1. **La prima tappa è «l'anno del regno»**, non un regno più ricco con un anno più corto: chiude il primo anello (campagna, esito, bilancio, spesa, effetto in primavera) con una sola specie di voce, e tutto il resto del piano vi si appoggia.
2. **Il regno come terzo strato** con giornale e slot propri, non dentro `StatoCampagna` né nello `StatoPartita` unico di A §2.3 (RDA-162, S28a): le campagne di prova e i loro salvataggi restano identici.
3. **La conclusione minima è annientamento più inverno** (RDA-164): è la fine che il gioco già riconosce di fatto, e con l'inverno dà a ogni campagna una fine certa.
4. **Il bilancio è rendita più premi delle vittorie**, e il riporto si calcola sull'entrata dell'anno (RDA-165, S28g, S28h): chi perde o non combatte ha comunque un inverno da giocare. Tutto in valori provvisori (`valori-provvisori.md`), tre dei quali dipendono dalle domande 1–3.
5. **Le forze tornano come sono e le reclute formano un gruppo nuovo** (RDA-166): nessuna regola nuova sulla mappa, la riunione resta una scelta del giocatore.
6. **L'avvio resta, con il regno in testa** (S28c): togliere scontri e campagne di prova non era chiesto.
7. **La proposta delle classi l'ha scritta un sotto-agente** mentre costruivo, e l'ho poi riletta per intero verificando a campione venti citazioni del documento 04 e tutti i rinvii agli altri documenti; le altre citazioni del 04, circa duecento, non le ho verificate una per una, e la proposta lo dice in testa. Ho aggiunto il punto 6.7, che raccorda le voci proposte al regno costruito.
8. **Ho corretto la coda degli annunci** (RDA-172) benché non fosse chiesto e benché il difetto fosse della build 30: senza, la tappa non era giocabile a orecchio per chi aspetta l'inverno chiudendo le giornate, che secondo il banco è il caso ordinario.
9. **Ho aggiunto il cancello di VoiceOver** (RDA-171) invece di una nota nel resoconto: lo stato sbagliato si è prodotto due volte: una in questa sessione, e una lasciata da un incarico precedente, che il cancello stesso ha scoperto.
10. **Non ho toccato la battaglia**, dove «Fine del turno» premuto in fila può produrre lo stesso accumulo di annunci: non l'ho misurato, e una regola nuova su un piano che i tester usano da mesi non si introduce senza misura.
11. **Le note** dicono ai tester la cosa nota e non corretta (le battaglie che possono non concludersi, con la resa come uscita), perché col regno la incontreranno più spesso.

## Modifiche, per commit

- `1c426fc` — `Incarichi/30-2026-11-22-…-incarico.md` (verbatim), `Incarichi/README.md`.
- `6040be7` — `Proposte/piano-del-regno.md`, `Proposte/domande-per-il-titolare-sul-regno.md`.
- `8d2b51a` — il regno nel pacchetto: `Codice/Sources/Dati/ValoriRegno.swift`, `Genere.swift`; `Codice/Sources/Motore/{StatoRegno,MotoreRegno,ForzeDelRegno,PonteRegnoCampagna,ImprontaRegno}.swift`; il calendario e la conclusione in `Motore/{StatoCampagna,ComandiCampagna,MotoreCampagna,ImprontaCampagna,ScenarioCampagna}.swift`; `Codice/Sources/Sessione/{SessioneRegno,Giornale,SessioneCampagna}.swift`; `Codice/Sources/Segnali/{SignificatiRegno,SignificatiCampagna,PuntoSegnali}.swift`; `Codice/Sources/Verifica/InvariantiCampagna.swift`; `Codice/Sources/Contenuti/Valori/regno.json` e manifest; `Contenuti/Testi/it.lproj/{Annunci.strings,Annunci.stringsdict,Vocabolario.strings}` e manifest; prove in `Codice/Tests/{DatiTest,MotoreTest,SessioneTest,SegnaliTest,ConfiniTest}/` (file nuovi: `CaricamentoRegnoTest`, `RegnoTest`, `CampagnaDelRegnoTest`, `SessioneRegnoTest`, `TraduttoreRegnoTest`, `RiproduzioneOroRegno/`).
- `3f870d8` — la patria: `Applicazione/Sorgenti/{SchermataPatria,PartitaRegno}.swift` (nuovi), `{PartitaCampagna,SchermataMappaCampagna,SchermataRegistro,SchermateContorno,Servizi,CostruttoreAnnunciCampagna}.swift`; `Codice/Sources/Motore/InterrogazioniCampagna.swift`; `Codice/Sources/Verifica/{BancoRegno,MisuraFrequenzaBattaglie}.swift`; `Codice/Sources/StrumentoVerifica/main.swift`; `Codice/Tests/VerificaTest/BancoRegnoTest.swift`; `Applicazione/ProveOspitate/{PatriaTest,TestoDinamicoTest}.swift`.
- `affb882` — `Applicazione/ProveOspitate/AnnoDelRegnoTest.swift`, `Applicazione/ProveInterfaccia/FumoRegnoTest.swift`.
- `187e1aa` — commit dell'interruzione: `P/verifica-con-voiceover/percorsi-regno.py`, `Proposte/classi-dei-campioni.md` (bozza).
- `3826c45` — `Fondamenta/registro-decisioni-architetturali.md` (RDA-162–168), `Fondamenta/{02-accessibilita,03-dati,05-architettura-tecnica}.md`, `valori-provvisori.md`, `registro-scostamenti.md` (S27b chiuso), `nota-per-il-titolare-frequenza-delle-battaglie.md`, `nota-per-il-titolare-genere-testo-marcia-e-correzioni.md`, `Proposte/classi-dei-campioni.md` (rivista).
- `574c6d0` — `scripts/controlla-voiceover-spento.sh` (nuovo), `scripts/collaudo-completo.sh`, `scripts/tester.py`, `Applicazione/Esplorazione/SessioneInterattivaTest.swift`, `Applicazione/ProveInterfaccia/FumoRegnoTest.swift`, `registro-scostamenti.md` (S28), `P/{cancelli-visti-fallire,salvataggi-build-30,banco-del-regno,frequenza-battaglie}/`.
- `ded7f33` — `Fondamenta/registro-decisioni-architetturali.md` (RDA-169–171), `Proposte/piano-del-regno.md`, `note-di-rilascio.txt`, `nota-per-il-titolare-il-regno-prima-tappa.md`.
- `c0eca7f` — `Applicazione/ProveOspitate/{AnnoDelRegnoTest,PassaggioBattagliaInterfacciaTest}.swift`, `P/verifica-con-voiceover/percorsi-regno.py`.
- `9797591` — `Codice/Sources/Verifica/BancoRegno.swift`; README dei prodotti; note rilette.
- `ade0ce9` — `Codice/Sources/Segnali/{CodaAnnunci,PuntoSegnali,SignificatiCampagna}.swift`, `Applicazione/Sorgenti/SchermataMappaCampagna.swift`, `Codice/Tests/SegnaliTest/CodaAnnunciTest.swift`, `Fondamenta/registro-decisioni-architetturali.md` (RDA-172), `Fondamenta/05-architettura-tecnica.md`, note.
- `7ef91fd` — il commit della build: `P/verifica-con-voiceover/` (percorsi, tester prima della correzione, `ritardo-della-voce.py`), `P/collaudo/`.
- `54e2b16` — `build-caricate.md` (riga 31), `P/build-31/`, `P/verifica-con-voiceover/` (corse dopo la correzione, README, schermate), `scripts/tester.py` (opzione `contatto`), `Incarichi/README.md`, questo resoconto nella prima stesura.
- `752277c` — `note-di-rilascio.txt`, `nota-per-il-titolare-il-regno-prima-tappa.md` (i nomi dei gruppi), `P/verifica-con-voiceover/ipad/dopo-la-correzione/` (l'anno con la battaglia), resoconto.
- commit finale — `P/build-31/` (la verifica ripetuta dopo la nota riallegata), questo resoconto nella stesura definitiva.

## Ciò che ho fatto senza che fosse chiesto

- La correzione della coda degli annunci (RDA-172): `CodaAnnunci`, la conferma della chiusura e la conclusione della campagna interrompenti.
- Il cancello di VoiceOver sul simulatore del collaudo e lo spegnimento all'uscita del pilota (RDA-171).
- La prova dal vivo della riapertura dei salvataggi della build 30, con l'app compilata dal suo commit.
- Il banco del regno e la sonda dei suoi tredici invarianti (RDA-169); la convalida delle proposte dell'avversario nello strumento di misura.
- La prova d'interfaccia in orizzontale a testo massimo e la prova della ripresa di una battaglia del regno dopo un riavvio.
- Le versioni 1.7 del documento 05, 2.9 del 02 e 2.7 del 03.
- La decisione del titolare sui gruppi avversari scritta anche in testa alla nota dell'incarico 29, oltre che nel registro.
- Lo script che misura il ritardo della voce dai diari del tester (`P/verifica-con-voiceover/ritardo-della-voce.py`) e l'opzione `contatto` del tester.

## Ciò che era chiesto e non ho fatto

- Nulla dell'incarico è rimasto non fatto. Con riserve dichiarate: (a) con VoiceOver il tester ha combattuto e perso una battaglia dentro un anno del regno, ma non ha vinto una campagna per annientamento (ultima voce della sezione seguente); (b) la proposta delle classi è rivista a campione e non citazione per citazione; (c) i valori del bilancio e del calendario sono provvisori e attendono le risposte alle domande.

## Scoperto, cioè non automatizzato, con le vie tentate

- **Il gesto di fuga con VoiceOver**: nessuna API lo produce e il tasto Esc non arriva come `accessibilityPerformEscape` (già dell'incarico 29). Coperto nelle ospitate (`PatriaTest`).
- **L'attivazione con VoiceOver in orizzontale**: tre vie tentate (punto 8 dell'esecuzione). Coperta col tocco vero senza VoiceOver; la lettura in orizzontale con VoiceOver è verificata.
- **La pronuncia vera**, l'aptica e i suoni: il simulatore non li dà; restano in `collaudo-solo-dispositivo.md`. In particolare non ho modo di sentire se un annuncio interrompente taglia la frase a metà in modo sgradevole: il servizio restituisce il testo, non l'audio.
- **A testo massimo sull'iPhone** VoiceOver legge, dopo l'ultimo comando della patria, la barra di scorrimento di sistema («Vertical scroll bar, 8 pages»: in inglese perché il simulatore è in inglese). È l'elemento che iOS espone per i contenuti lunghi; c'era già nelle schermate dell'apprendimento (prodotti dell'incarico 29). Non toccato.
- **Nessun cancello automatico** protegge la scelta di rendere interrompente la conferma della chiusura della giornata: sta nella Presentazione e la vede soltanto la corsa col tester (RDA-172).
- **Una campagna del regno VINTA con VoiceOver**, cioè la conclusione per annientamento, la dichiarazione coi premi e il bilancio che ne nasce: non raggiunta dal tester (ha combattuto e perso una battaglia, vedi «Il tester con VoiceOver»). Coperta nelle ospitate da `AnnoDelRegnoTest`, che vince per annientamento attraverso le schermate e ordina sei leve con l'entrata accresciuta dai premi.

## Tempi

Dove non è detto altro lo strumento è `date +%s` attorno al comando.

| che cosa | tempo |
|---|---|
| **Compilazione.** Pacchetto in rilascio per lo strumento di verifica (`swift build -c release`, tempo stampato da SwiftPM) | 17,7 s e 19,8 s |
| App e pilota (`xcodebuild build-for-testing`, schema dell'esplorazione), quattro volte | 10–12 s ciascuna |
| App e pilota della build 30 dal suo commit | 11 s |
| **Collaudo.** `swift test` sul commit di partenza; dopo le due correzioni | 61 s; 57 s e 55 s |
| Collaudo completo: fermato dal cancello del genere; verde su codice non definitivo (133 prove); rifiutato da VoiceOver acceso; fermato da `ConfiniTest`; verde su `9797591` (137); verde su `ade0ce9` (137) | 53 s; 329 s; 2 s; 61 s; 378 s; 380 s |
| Sessioni complete: su `ded7f33`; su `9797591`; su `ade0ce9` | 565 s; non misurata (il file dei tempi è stato sovrascritto dalla corsa successiva); 536 s, di cui 522,7 s la prova delle 144 campagne (dall'esecutore) |
| Prove singole sul simulatore, compilazione compresa: `AnnoDelRegnoTest`; `FumoRegnoTest` | 31 s e 63 s; 59 s, 63 s, 63 s |
| **Simulatore, con VoiceOver.** Percorsi, per apparecchio: prima, seconda, terza corsa | 332 s; 486–487 s; 495–497 s |
| Il tester, un anno: iPhone e iPad prima della correzione; terzo iPhone; iPhone e iPad dopo; iPad con la battaglia | 2165 s e 1811 s; 3872 s; 2091 s e 1851 s; 3573 s |
| La riapertura dei salvataggi della build 30: prima e dopo (stampati dal guidatore) | 126 s e 82 s |
| **Misure.** Frequenza delle battaglie, 1200 partite; banco del regno, 1786 anni | 8 s; 5 s |
| **Caricamento.** `scripts/carica-testflight.sh`, dal primo controllo alla riga del registro | 581 s |
| **Esplorazione e scrittura.** Lettura dei documenti, piano, domande, costruzione, registri, resoconto | non misurati. Dai commit: primo alle 17:11, commit della build alle 23:26 del 22 novembre, con un'interruzione per il limite d'uso fra le 18:21 e la ripresa |

## Integrazione continua

Corse sugli invii al `principale` (API pubblica di GitHub Actions; `collaudo.yml` gira soltanto lì). 44948094047 su `2a86f6e`, l'ultimo invio dell'incarico 29, il cui esito quel resoconto dichiarava di non aver visto: VERDE (2026-11-21, 20:47:04Z–21:04:09Z). 45077742930 su `7ef91fd`, il commit della build 31: VERDE (22:26:36Z–22:43:10Z), col cancello nuovo di VoiceOver nel collaudo. 45080049053 su `54e2b16`, il primo invio di chiusura (registro della build, prodotti, resoconto): VERDE (22:51:39Z–23:10:16Z). 45084954650 su `752277c` (note aggiornate, anno con la battaglia): in corso quando ho guardato, alle 23:46Z. La corsa sull'ultimo invio, che porta soltanto questo resoconto e la verifica ripetuta della nota, parte dopo: il suo esito non l'ho visto.
