# La verifica attraverso l'interfaccia, con VoiceOver, della seconda tappa del regno (incarico 31)

Stato di questo file: scritto man mano che le corse finiscono. Ciò che non è ancora stato eseguito è dichiarato tale nel punto in cui compare.

## Canale e strumenti

Canale: il pilota dell'incarico 28 (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`, `test_sessione_da_tester`, schema `WarSenseEsplorazione`), che gira sul simulatore con VoiceOver acceso e legge i comandi da `comandi.jsonl`. Lo guidano:

- `percorsi-seconda-tappa.py` (questa cartella): i percorsi a controlli, nove blocchi — `partenza`, `mappa`, `inverno`, `estate`, `reclute`, `mantenimento`, `voce`, `orizzontale`, `testo` —; per ogni controllo scrive blocco, atteso, trovato ed esito in `controlli.jsonl`. Gli attesi vengono dalle prove ospitate `PatriaTest` e `SecondaTappaDelRegnoTest` e dai testi di `Annunci.strings`; dove un numero è calcolato a mano dalle regole (il riporto dopo le spese di un percorso) il guidatore lo dice nel nome del controllo o in un commento accanto.
- `scripts/tester.py <cartella> <formato> <giornate> regno due-anni [opzioni]`: il tester dell'incarico 28, esteso per giocare DUE anni del regno a orecchio (opzioni `tieni=`, `solo=`, `tieni2=`, `solo2=`, `addestra=`); il modo a un anno dell'incarico 30 resta com'era.
- `corri.sh` (questa cartella): un comando per apparecchio. Copia l'albero di lavoro in `Applicazione/build/pilota-31/albero`, vi genera il progetto e compila app e pilota in `Applicazione/build/pilota-31/derivati` (il progetto Xcode del repo e `Applicazione/build/collaudo` non si toccano), accende il simulatore, disinstalla l'app, accende il pilota e il servitore degli appunti, guida, spegne VoiceOver, ferma il pilota, esegue `scripts/controlla-voiceover-spento.sh` e spegne il simulatore se l'aveva acceso lui. Rifiuta l'istanza 1 (il primo iPhone e il primo iPad sono del collaudo).

### Come si rilancia

```
Incarichi/31-2026-11-23-prodotti/verifica-con-voiceover/corri.sh percorsi iphone      # secondo iPhone, tutti i blocchi
Incarichi/31-2026-11-23-prodotti/verifica-con-voiceover/corri.sh percorsi ipad        # secondo iPad, tutti i blocchi
Incarichi/31-2026-11-23-prodotti/verifica-con-voiceover/corri.sh percorsi iphone inverno voce      # soltanto alcuni blocchi
Incarichi/31-2026-11-23-prodotti/verifica-con-voiceover/corri.sh tester iphone 3 tester-due-anni piccola 3 regno due-anni tieni=Cervo
Incarichi/31-2026-11-23-prodotti/verifica-con-voiceover/corri.sh tester ipad 3 tester-due-anni media 3 regno due-anni tieni=Cervo
```

Ogni comando ricompila da sé se ciò da cui dipendono app e pilota è cambiato (l'impronta è del contenuto di `Applicazione/Sorgenti`, `Applicazione/Risorse`, `Applicazione/Esplorazione`, `Applicazione/project.yml`, `Codice/Sources`, `Codice/Package.swift`, non del commit), e alla partenza scrive in `<apparecchio>/compilazione.txt` il commit, lo stato dell'albero e l'impronta. I controlli e i diari si scrivono direttamente in questa cartella, una riga alla volta.

### Che cosa è stato aggiunto al pilota, e perché

- **La pronuncia intera.** Il servizio VoiceOver delle prove (`XCUIVoiceOverService`) restituisce ogni pronuncia troncata a 64 caratteri: oltre quel punto stanno la coda di ogni riga delle forze (dove va la formazione), il tratto («Pulsante», «Intestazione»), il suggerimento, e la coda degli annunci lunghi — cioè quasi tutto ciò che questa tappa aggiunge. VoiceOver ha un comando che copia negli appunti l'ultima cosa detta (da tastiera Control, Opzione, Maiuscole, C): il pilota lo dà con `typeKey`, e gli appunti del simulatore li legge il lato Mac con `xcrun simctl pbpaste` (`scripts/interattivo.py <cartella> --appunti <udid>`, che risponde al pilota per file). Accertato dal vivo sul secondo iPhone: toccata la riga di Cervo, il servizio dà «Cervo, formazione non armata: 4 atomi di fanteria leggera. Parte» e gli appunti «Cervo, formazione non armata: 4 atomi di fanteria leggera. Parte per il fronte Pulsante Attiva per scegliere se parte per il fronte o resta in patria». Ciò che si copia è il testo che VoiceOver ha in pronuncia nell'istante della copia, per intero dal primo istante (una copia a 1,9 s dall'arrivo del fuoco su una voce che ne richiede una decina a essere detta la dà già tutta). Dopo ogni copia VoiceOver accoda «copiato negli appunti»: il pilota lo riconosce e lo toglie.
- **Il limite della copia.** La copia è un comando da tastiera dato a VoiceOver mentre parla, e altera ciò che sta dicendo: con le copie accese, all'apertura della campagna l'annuncio della mappa («Mappa Guado, 4 righe per 4 caselle…») non è comparso fra le pronunce, mentre senza copie compare e dura 6,2 s. Inoltre a ogni copia il pilota non ascolta per quasi un secondo. Per questo il guidatore di norma ASCOLTA soltanto (una lettura ogni quarto di secondo) e chiede la pronuncia intera dove serve: nelle letture di una schermata ferma (elemento per elemento) e sugli annunci che non stanno in 64 caratteri. Le misure dei tempi (blocco `voce`) si fanno senza copie.
- **Gli istanti.** Ogni ascolto riporta in `ascoltate_t` l'istante in cui ciascuna pronuncia è comparsa, e `doppio_tocco_s` quanto è durato il doppio tocco: servono a dire per quanto un annuncio è rimasto la pronuncia corrente.
- **Tipo e tratti.** `elementi` dà per ogni elemento il tipo (pulsante o testo) e i tratti d'accessibilità che l'istantanea di XCUITest porta (proprietà `traits` di `XCElementSnapshot`, non pubblica: il pilota la legge soltanto se l'oggetto risponde): serve a dire che una riga è un comando e che una linguetta è un'intestazione.
- **`quiete`**: l'ascolto finisce quando la voce tace da tanti secondi; **`sonda`**: elenca proprietà e metodi del servizio VoiceOver e dell'istantanea (è così che si è trovato `traits`; `XCUIVoiceOverOutput` ha la sola `utterance`).

## Le corse, e su quale app è girata ciascuna

Simulatori iOS 27.0, Xcode 27.2 (27B52), macOS 27.0.1: «WarSense iPhone Air · 2» 76DF33B6…, «WarSense iPad Pro 13 · 2» 8D3583DB…, «WarSense iPhone Air · 3» E2C6F42C…, «WarSense iPad Pro 13 · 3» 75A249BF…. Il primo iPhone e il primo iPad non sono stati toccati.

| corsa | cartella | app compilata da | stato |
|---|---|---|---|
| percorsi, iPhone 2, cinque blocchi | `messa-a-punto/iphone-percorsi-su-c3b5e2a/` | `c3b5e2a` (02:26:45 del 24 novembre) | MESSA A PUNTO, non esito finale: finita, 81 controlli, 74 ok e 7 NO (riepilogo del guidatore in `guidatore.log`), 1164 s |
| percorsi, iPad 2 | `messa-a-punto/ipad-percorsi-su-88d4874-interrotta/` | `88d4874` (02:31:10; sorgenti di app identici a `c3b5e2a`) | messa a punto, fermata da me a metà: il blocco `inverno` vi è caduto per un errore del guidatore (un nome di variabile che copriva una funzione), poi corretto |
| tester, iPhone 3 e iPad 3 | `messa-a-punto/iphone-tester-su-88d4874-interrotto/`, `messa-a-punto/ipad-tester-su-88d4874-interrotto/` | `88d4874` | messa a punto, fermati da me al primo anno quando il commit sotto verifica è diventato `b0a15f2` |
| percorsi e tester, prima partenza delle definitive | `messa-a-punto/iphone-su-b0a15f2-interrotta-dal-limite-d-uso/`, `messa-a-punto/ipad-su-b0a15f2-interrotta-dal-limite-d-uso/` | `b0a15f2` (02:48:36), più il pilota esteso allora non committato | INTERROTTE: partite alle 02:52, fermate alle 03:01 dal limite d'uso della sessione, a metà del terzo blocco; dati parziali conservati |
| **percorsi, iPhone 2, nove blocchi** | `iphone/` | **`dd7b8ef`** (07:23:04): il codice dell'app è quello di `b0a15f2`, col pilota esteso committato | **DEFINITIVA, finita**: 106 controlli, 94 ok, 12 NO (11 su reperti dichiarati, 1 altro), 2058 s |
| **percorsi, iPad 2, nove blocchi** | `ipad/` | **`dd7b8ef`** | **DEFINITIVA, finita**: 105 controlli, 90 ok, 15 NO (11 su reperti dichiarati, 4 altri), 2066 s |
| **tester, due anni, guado, iPhone 3** | `iphone/tester-due-anni/` | **`dd7b8ef`** | **DEFINITIVA, finita**: due anni interi, 479 righe di diario, nessun errore, 2859 s |
| **tester, due anni, istmo, iPad 3** | `ipad/tester-due-anni/` | **`dd7b8ef`** | **DEFINITIVA, finita**: due anni interi, 479 righe di diario, nessun errore, 2849 s |

Le quattro corse definitive le ha rilanciate la sessione principale alle 07:22 del 24 novembre, dopo l'interruzione, con `corri.sh` com'era; le sezioni di questo file fino a «Che cosa NON si guida» sono del sotto-agente che ha costruito lo strumentario, e la sezione «Le corse definitive» in fondo è della sessione. `git status --short` al momento della copia è in `iphone/compilazione.txt`: di ciò da cui dipendono app e pilota nulla è modificato rispetto al commit `dd7b8ef`, che differisce da `b0a15f2` per il solo pilota (`git diff --stat b0a15f2 dd7b8ef -- Applicazione/Sorgenti Codice/Sources`: vuoto).

## Che cosa si è sentito nella corsa di messa a punto sull'iPhone (app di `c3b5e2a`)

Da `messa-a-punto/iphone-percorsi-su-c3b5e2a/controlli.jsonl`; i conteggi per blocco sono quelli del riepilogo del guidatore. Vale come messa a punto: gli esiti finali sono quelli delle corse su `b0a15f2`, più sotto quando saranno finite.

- **partenza**, 16 su 16. Fuoco d'apertura sul titolo. La patria letta per intero, 19 elementi tutti confrontati sulla pronuncia intera; di ogni riga delle forze VoiceOver dice nome, categoria, reparti, destinazione, «Pulsante» e il suggerimento: «Corvo, gruppo armato: 6 atomi di fanteria leggera. Parte per il fronte Pulsante Attiva per scegliere se parte per il fronte o resta in patria». Attivata la riga di Cervo: «Cervo resta in patria.», che resta l'ultima cosa detta; la riga diventa «… Resta in patria»; spostando il fuoco, avanti «Apri la campagna Pulsante», indietro la riga con la destinazione nuova. Riattivata: «Cervo parte per il fronte.». Tenuti in patria Corvo, Lupo e Falco, ciascuno confermato a voce: «Apri la campagna» apre la scelta del fronte, e scelto il fronte si sente «nessun gruppo armato da mandare»; nessuna campagna si apre.
- **mappa**, 10 su 10. Partiti Lupo, Falco e Orso: «riga 4, casella 2, tuo Lupo, in attesa, composta da 18 atomi di fanteria leggera, 8 atomi di fanteria pesante, tuo quartier generale, strada battuta», Falco in riga 4 casella 3, Orso in riga 4 casella 4; nessuna casella nomina Corvo o Cervo. Tornati in patria a campagna aperta le righe sono testo. Misura della voce: la conferma della chiusura (118 caratteri) dura 6,75 s, cioè 17,5 caratteri al secondo.
- **inverno**, 29 su 34. L'annuncio per intero: «Comincia l'inverno dell'anno 1. Entrate: monete di bronzo 200, uomini 24, metalli 30, materiale da costruzione 30, animali 12. Mantenimento dell'esercito: monete di bronzo 27.». La prima schermata letta per intero (33 elementi), col mantenimento subito dopo le riserve e 193 monete; le tre linguette dette «Intestazione», raggiunte in ordine dal rotore delle intestazioni, col tratto d'intestazione nell'istantanea. La scelta del reparto letta per intero coi costi (75, 225 impedita, 100, 300 impedita, 150, 37, 50 su 193). La conferma per intero: «Addestramento mirato ordinato per 8 atomi di fanteria pesante di Lupo: pronto in primavera.»; il fuoco torna sulla voce; restano 93 monete. Le stagioni schermata per schermata (cavalleria, pesante, leggera: estate, primavera, primavera; estate, estate, primavera; lo stesso; autunno, estate, estate). La leva alla quarta: «Leva di fanteria leggera ordinata: pronta in estate.». La primavera per intero: «Comincia la primavera dell'anno 2. Il riporto ha tolto: monete di bronzo 43, uomini 18, metalli 27, materiale da costruzione 30, animali 12. Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, e raggiunge il quartier generale in estate, a campagna aperta. Lupo ha ora 8 atomi di fanteria pesante con addestramento mirato.».
- **reclute**, 8 su 9. «Leva di fanteria leggera ordinata: pronta in primavera.»; la primavera per intero: «… Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, ed entra sul fronte in primavera, al quartier generale.»; la riga «Lince, gruppo armato, reclute dell'inverno: 6 atomi di fanteria leggera. Entra sul fronte in primavera, al quartier generale»; sulla mappa sei formazioni; il registro della campagna: «Giorno 1: Lince è arrivata dalla patria in riga 2, casella 2 Pulsante Attiva per portare il fuoco sul luogo del fatto».
- **mantenimento**, 11 su 12. Due addestramenti (Lupo e Corvo), 18 monete; in primavera «con addestramento mirato»; il secondo inverno le righe dicono «…, da mantenere entro l'inverno»; la scelta del mantenimento: «Corvo: 6 atomi di fanteria leggera con addestramento mirato. Costa: monete di bronzo 6 su 191.», «Lupo: 8 atomi di fanteria pesante con addestramento mirato. Costa: monete di bronzo 8 su 191.»; pagato per Lupo: «Mantenimento dell'addestramento mirato ordinato per 8 atomi di fanteria pesante con addestramento mirato di Lupo: pronto in primavera.» e la riga «…, mantenimento pagato»; la terza primavera: «… Corvo ha 6 atomi di fanteria leggera senza più addestramento mirato, per mancato mantenimento.», Corvo tornato com'era, Lupo ancora «con addestramento mirato».
- **I sette falliti.** Sei sono il controllo «voce» (vedi sotto). Il settimo: toccata la scelta impedita, il rifiuto «Non si può ordinare: mancano monete di bronzo.» non è comparso fra le pronunce lette; in quel passo il pilota copiava negli appunti. Nella corsa di messa a punto sull'iPad, col solo ascolto, il rifiuto compare a 0,26 s ed è sostituito a 0,78 s dalla rilettura della voce.

## Difetti e osservazioni riferiti

Tre reperti, riferiti e NON corretti né aggirati nei guidatori. Nei `controlli.jsonl` le righe che li riguardano portano il campo `reperto` (1, 2 o 3) e `reperto_detto`, e conservano l'esito vero: un «NO» con quel campo cade su un difetto riferito, non su un errore del guidatore. Il criterio è il nome del controllo (`reperto_del_controllo` nel guidatore); nelle corse partite prima che il campo esistesse è stato aggiunto dopo con lo stesso criterio, senza toccare atteso, trovato ed esito.

### Metodo, e che cosa è misurato e che cosa no

- **Misurato**: quale pronuncia è quella corrente di VoiceOver e quando cambia. Il pilota la legge dal servizio `XCUIVoiceOverService` ogni 0,25 s (`ascoltate`, con gli istanti in `ascoltate_t`, in secondi dall'inizio dell'ascolto, che comincia quando il doppio tocco è tornato; `doppio_tocco_s` è la durata del doppio tocco). «Superato dopo al più X s» è `doppio_tocco_s` più l'istante della prima pronuncia diversa: un limite superiore di quanto l'annuncio è rimasto la pronuncia corrente. Il testo intero degli annunci è letto dagli appunti di VoiceOver (vedi sopra).
- **Misurato**: la velocità della voce. La conferma della chiusura di una giornata non è seguita da spostamenti del fuoco, e il fatto successivo («Giornata conclusa: comincia il giorno 2») parte quando VoiceOver notifica che la conferma è conclusa: 118 caratteri in 6,75 s sull'iPhone e in 6,71 s sull'iPad, cioè 17,5 e 17,6 caratteri al secondo (controllo «misura» del blocco `mappa`).
- **NON udito**: il simulatore non dà l'audio. Che l'annuncio superato sia stato troncato a voce è una deduzione da tre fatti misurati — la pronuncia corrente cambia dopo uno-due secondi; l'annuncio ne richiede molti di più; la coda degli annunci del gioco, che avanza soltanto alla notifica di annuncio concluso, avanza prima del tempo quando la schermata cambia — e dalla regola documentata di VoiceOver per gli annunci a priorità predefinita (interrompibili da una pronuncia nuova). Va accertato a orecchio su un apparecchio.
- **Ricavato dal codice, non misurato**: dove nasce (sotto).
- **Misurato anche sull'app della build 31** (`confronto-build-31/`): che per l'inverno e la primavera l'annuncio fosse già superato allora. Prima letto nel sorgente (`git show ade0ce9:Applicazione/Sorgenti/SchermataPatria.swift`: `esegui` chiama `partita.esegui` e poi `portaIlFuocoInTesta()`), poi misurato: vedi «Il confronto con la build 31» qui sotto.

### Reperto 1 — gli annunci superati dallo spostamento del fuoco (difetto)

Quando un annuncio è accompagnato da uno spostamento del fuoco, la lettura dell'elemento su cui il fuoco va lo sostituisce come pronuncia corrente dopo uno-due secondi. Il controllo «voce», aggiunto da me (non è fra i punti dell'incarico), chiede che un annuncio non sia superato prima del tempo che serve a dirlo, contato a 25 caratteri al secondo, cioè più in fretta di quanto VoiceOver parli.

Misure delle corse di messa a punto (app di `c3b5e2a` e `88d4874`; dati grezzi in `messa-a-punto/iphone-percorsi-su-c3b5e2a/controlli.jsonl` e `messa-a-punto/ipad-percorsi-su-88d4874-interrotta/controlli.jsonl`, campi `ascoltate`, `istanti`, `doppio_tocco_s`, `superata_dopo_al_piu_s`; i passi del pilota in `esiti-della-sessione-del-pilota.jsonl` accanto). In queste il pilota copiava negli appunti durante l'ascolto degli annunci lunghi: valgono come conferma, le misure pulite sono quelle del blocco `voce`.

| annuncio | caratteri | superato dopo al più | da che cosa |
|---|---|---|---|
| l'inverno, con l'entrata e il mantenimento | 175 | 2,0 s (iPhone), 1,52 s (iPad) | «Anno 1, inverno, schermata 1 di 4» (il fuoco in testa alla data) |
| la primavera con Lince in estate e il miglioramento | 342 | 2,47 s (iPhone) | «Anno 2, primavera» |
| la primavera con Lince in primavera | 270 | 1,5 s (iPhone), 1,52 s (iPad) | «Anno 2, primavera» |
| la conferma dell'addestramento mirato | 91 | 2,34 s (iPhone) | la rilettura della voce su cui il fuoco torna |
| la conferma del mantenimento dell'addestramento | 134 | 1,62 s (iPhone) | la rilettura della voce |
| il rifiuto della scelta impedita | 46 | 1,29 s (iPad, solo ascolto: compare a 0,26 s, sostituito a 0,78 s) | la rilettura della voce |

Gli annunci che non spostano il fuoco restano: «Cervo resta in patria.» e «Leva di fanteria leggera ordinata: pronta in primavera.» sono l'ultima cosa detta alla fine dell'ascolto (controlli «a: la conferma resta l'ultima cosa detta» e «d: la leva ordinata alla prima schermata…»).

La coda del gioco (misurato, blocco `mappa`, senza copie): all'apertura della campagna «Campagna aperta sul fronte del guado» (36 caratteri, due secondi a dirla) compare a 0,26 s e a 1,04 s cede il posto a «Mappa Guado, 4 righe per 4 caselle…», che `CodaAnnunci` manda soltanto quando il sistema notifica concluso il primo; «Mappa Guado…» (83 caratteri) resta poi 6,2 s.

Dove nasce (ricavato dal codice, non toccato): `SchermataPatria.esegui` consegna gli eventi al punto dei segnali, che pubblica l'annuncio, e subito dopo chiama `portaIlFuocoInTesta()` (`UIAccessibility.post(.screenChanged, …)`); `scegliIlBersaglio` fa `Fuoco.sposta(a: origine, perche: .schermataChiusa)` e poi ordina, e l'annuncio dell'ordine o del rifiuto arriva insieme alla lettura dell'elemento su cui il fuoco torna. Gli annunci sono pubblicati a priorità predefinita (`PuntoSegnali.accoda`).

Che cosa tocca di questa tappa: in coda all'annuncio dell'inverno stanno il mantenimento prelevato e i reparti sciolti; in coda a quello della primavera le reclute con dove e quando entrano, i miglioramenti dati e quelli perduti; la conferma e il rifiuto della scelta del reparto sono nuovi. L'informazione resta sulla schermata — la riga del mantenimento subito dopo le riserve, le righe delle forze, i lavori ordinati, il registro della patria —: manca la conferma a voce.

#### Il confronto con la build 31 (misurato)

App compilata dal codice della build 31 (`git archive 7ef91fd` in una copia sotto `Applicazione/build/pilota-31/build-31/`, col pilota esteso di questo incarico al posto del suo; 12 s di compilazione, `date +%s`), sul quarto iPhone di WarSense (87AB2F55…), senza copie negli appunti. Dati grezzi in `confronto-build-31/misura.jsonl`, i passi del pilota accanto.

| passo | pronunce e istanti | che cosa dice |
|---|---|---|
| «Attendi l'inverno» | «Comincia l'inverno dell'anno 1. Entrate: monete di bronzo 200, u…» a 0 s, «Anno 1, inverno, schermata 1 di 4» a 1,04 s; doppio tocco 0,54 s | l'annuncio dell'inverno era superato dopo al più 1,58 s anche nella build 31 |
| «Prosegui alla primavera» | «Comincia la primavera dell'anno 2. Il riporto ha tolto: monete d…» a 0 s, «Anno 2, primavera» a 1,02 s; doppio tocco 0,40 s | l'annuncio della primavera era superato dopo al più 1,42 s |
| «Leva di fanteria leggera.» | «Leva di fanteria leggera ordinata: pronta in primavera.» a 0 s, nessun'altra pronuncia negli 8 s d'ascolto | senza spostamento del fuoco l'annuncio resta |
| «fronte del guado, mappa 4 per 4» | «Campagna aperta sul fronte del guado» a 0,26 s, «Mappa Guado…» a 1,04 s, lo stato a 7,2 s | la coda avanza allo stesso modo |
| «Chiudi la giornata» | «Giornata chiusa. 6 gruppi…» a 0,26 s, «Giornata conclusa: comincia il giorno 2» a 6,92 s | 118 caratteri in 6,66 s: 17,7 caratteri al secondo |

Per l'inverno e la primavera il reperto non nasce dunque in questa tappa; la tappa vi ha aggiunto, in coda agli annunci, le cose nuove, e il caso della scelta del reparto.

### Reperto 2 — dove entrano le reclute di primavera (osservazione)

Riga e annuncio dicono «Entra sul fronte in primavera, al quartier generale». Sul guado, partite le cinque formazioni, Lince compare in riga 2, casella 2 (acqua, strada battuta): a due caselle dal proprio quartier generale (riga 4, casella 2) e a una da quello avversario (riga 1, casella 2). Misurato: albero della mappa e registro della campagna («Giorno 1: Lince è arrivata dalla patria in riga 2, casella 2»), controlli «d: sulla mappa, alla prima giornata…» e «d: il registro della campagna annota…» del blocco `reclute`. Ricavato dal codice: è la regola di `MotoreCampagna.casellaDiArrivo` — la casella libera più vicina al quartier generale, a parità di distanza nell'ordine di lettura —, e fra le libere a distanza 2 la (2,2) precede la (3,1) e la (3,3). I due controlli passano (verificano che Lince ci sia, col suo nome, e che il registro dica la casella in cui sta); portano `reperto: 2`.

### Reperto 3 — «Apri la campagna» senza armati che partano (osservazione)

Con tutti i gruppi armati tenuti in patria «Apri la campagna» apre comunque la scelta del fronte; il rifiuto «nessun gruppo armato da mandare» arriva dopo aver scelto il fronte, e nessuna campagna si apre. Misurato (blocco `partenza`, controllo «b: con tutti gli armati in patria si sente…», campo `come`). La rilettura di «Apri la campagna», su cui il fuoco torna alla chiusura del pannello, segue il rifiuto dopo al più 1,91 s sull'iPhone e 1,38 s sull'iPad (31 caratteri: 1,8 s a dirli alla velocità misurata; il controllo «voce» corrispondente, che conta a 25 caratteri al secondo, passa). Il controllo passa e porta `reperto: 3`.

## Che cosa NON si guida, e si dichiara

- Il gesto di fuga (nessuna API; il tasto Esc non arriva come `accessibilityPerformEscape`): la scelta del reparto si chiude con «Chiudi il pannello», il gesto lo copre `SecondaTappaDelRegnoTest`.
- L'attivazione in orizzontale (incarichi 28 e 30): in orizzontale si legge soltanto.
- L'audio: il simulatore non dà la voce da sentire; che un annuncio sia interrotto a metà lo si deduce dagli istanti delle pronunce e dalla coda del gioco, non lo si ascolta.
- Lo scioglimento dei reparti per denaro insufficiente: coi valori di fabbrica non si produce (27 monete di mantenimento su 200 di rendita). Non guidato con VoiceOver; lo coprono le prove ospitate (`SecondaTappaDelRegnoTest`). Via onesta vista e non percorsa: i valori messi a punto nel file `Documents/Valori/regno.json` dell'app (00 §15.4), come fa la prova ospitata.
- Il nome di un gruppo avversario al primo e al secondo anno: l'interfaccia non lo dice mai (la casella dice «formazione avversaria», senza nome: `CostruttoreAnnunciCampagna`), e nei diari del tester non compare alcun nome avversario. Non coperto.

## Le corse definitive (app di `dd7b8ef`, cioè il codice di `b0a15f2`)

Scritta dalla sessione principale dai file di questa cartella: `iphone/controlli.jsonl`, `ipad/controlli.jsonl`, i due `guidatore.log`, i due diari del tester, i quattro `tempi.txt`.

### I percorsi a controlli

| blocco | iPhone 2 | iPad 2 | che cosa cade |
|---|---|---|---|
| partenza | 16 su 16 | 16 su 16 | |
| mappa | 10 su 10 | 10 su 10 | |
| inverno | 30 su 34 | 30 su 34 | i quattro controlli «voce» (reperto 1) |
| estate | 8 su 9 | 8 su 9 | la riga in patria di una formazione già arrivata (osservazione 4, qui sotto) |
| reclute | 8 su 9 | 8 su 9 | un controllo «voce» (reperto 1) |
| mantenimento | 11 su 13 | 11 su 13 | due controlli «voce» (reperto 1) |
| voce | 2 su 6 | 2 su 6 | le quattro misure senza copie degli annunci superati (reperto 1) |
| orizzontale | 3 su 3 | 1 su 3 | sull'iPad, un artefatto del pilota (sotto) |
| testo | 6 su 6 | 4 su 5 | sull'iPad, lo stesso artefatto |
| **in tutto** | **94 su 106** | **90 su 105** | |

Sull'iPad il blocco `testo` ha un controllo in meno che sull'iPhone: lo dice il conteggio del guidatore, e non ne ho cercato la ragione.

**Le misure pulite del reperto 1** (blocco `voce`, senza copie negli appunti; «al più», doppio tocco compreso):

| annuncio | iPhone 2 | iPad 2 | sostituito da |
|---|---|---|---|
| l'inverno, con l'entrata e il mantenimento | 1,45 s | 1,48 s | «Anno 1, inverno, schermata 1 di 4» |
| la primavera | 1,45 s | 1,48 s | «Anno 2, primavera» |
| la conferma dell'addestramento mirato | 1,44 s | 1,47 s | la rilettura della voce su cui il fuoco torna |
| il rifiuto della scelta impedita | 1,30 s | 1,31 s | la rilettura della voce |
| la conferma di una leva, che non sposta il fuoco | resta fino alla fine dell'ascolto | resta | — |
| all'apertura della campagna, il primo annuncio in coda (36 caratteri) | cede dopo 0,76 s | 0,79 s | «Mappa Guado, 4 righe per 4 caselle…» |

Negli altri blocchi, dove il pilota copia negli appunti mentre ascolta, gli stessi annunci sono superati dopo al più 1,2–1,75 s.

**I quattro «NO» fuori dai reperti dichiarati.**

- *Osservazione 4 — la riga in patria di una formazione già arrivata* (iPhone e iPad, blocco `estate`). Lince, ordinata alla quarta schermata, arriva al quartier generale il primo giorno dell'estate, e la mappa e il registro lo dicono. Tornati in patria a campagna aperta, la sua riga dice ancora «Lince, gruppo armato, reclute dell'inverno: 6 atomi di fanteria leggera. Raggiunge il quartier generale in estate, a campagna aperta», come di un fatto a venire. Ricavato dal codice: a campagna aperta il regno non sa nulla del fronte finché la campagna non si conclude, e la riga legge lo stato del regno. Il controllo è marcato «osservazione» dal guidatore e porta esito «NO».
- *Un artefatto del pilota, non dell'app* (soltanto iPad, tre controlli: due in `orizzontale`, uno in `testo`). In tre letture di una schermata intera una o due posizioni, su 19 o 32, portano al posto dell'etichetta dell'elemento la pronuncia «Tastiera visibile»: è VoiceOver che annuncia la tastiera quando il pilota gli dà da tastiera il comando di copia. Ogni altra posizione coincide con l'atteso; le stesse letture passano per intero sull'iPad in verticale a dimensione ordinaria (blocco `partenza`, 19 elementi su 19) e sull'iPhone in orizzontale e a testo massimo. Le posizioni colpite cambiano da una lettura all'altra (la dodicesima, la quindicesima, la dodicesima e la sedicesima).

### Il tester a orecchio, due anni

Lo stesso copione sui due apparecchi: iPhone 3 sul fronte del guado, iPad 3 sul fronte dell'istmo. 479 righe di diario ciascuno, nessuna con un errore; 2859 s e 2849 s di partita.

- **Primo anno.** In patria le cinque formazioni col loro nome; Cervo tenuta in patria («Cervo resta in patria.»); aperta la campagna, sulla mappa ci sono le altre quattro e non Cervo. Le giornate chiuse una per una fino all'inverno; «Nuova stagione: estate» alla chiusura della trentesima e «Nuova stagione: autunno» alla sessantesima; la campagna si conclude con l'inverno, senza battaglie. D'inverno: «Mantenimento dell'esercito: monete di bronzo 27» nell'annuncio e la riga nella prima schermata; le tre intestazioni; la scelta impedita per i 18 atomi di fanteria leggera di Lupo («Costa: monete di bronzo 225 su 193», e attivandola «Non si può ordinare: mancano monete di bronzo.»); l'addestramento mirato ordinato per i 12 atomi di cavalleria di Falco (150 su 193); alla quarta schermata «Leva di fanteria leggera ordinata: pronta in estate.».
- **Secondo anno.** Ogni nome è rimasto alla sua formazione (il tester confronta le righe delle forze fra una primavera e l'altra). Falco «con addestramento mirato» in patria e sulla mappa. Alla chiusura della trentesima giornata: «Nuova stagione: estate» e poi «Lince è arrivata dalla patria in riga 3, casella 2» sul guado, «in riga 5, casella 3» sull'istmo; da quel momento le formazioni sulla mappa sono cinque. Il secondo inverno: mantenimento 29; la scelta del mantenimento dell'addestramento offre il solo Falco (12 su 184), pagato. Alla terza primavera i nomi sono ancora gli stessi.
- **Che cosa il tester non fa**: non combatte (la sua condotta chiude le giornate, e in due anni non incontra una battaglia: «battaglie: 0» nei due anni); non tiene in patria una formazione armata; non lascia scadere un addestramento. Queste cose le coprono i percorsi a controlli (blocchi `partenza`, `mantenimento`) e le prove ospitate.

### Schermate

`schermate/`: sei PNG presi dal pilota con VoiceOver acceso, dopo le corse, sul secondo iPhone e sul secondo iPad: la patria in primavera, la prima schermata dell'inverno (il mantenimento dopo le riserve, le forze, la prima intestazione), la scelta del reparto coi sette costi e le due scelte impedite.
