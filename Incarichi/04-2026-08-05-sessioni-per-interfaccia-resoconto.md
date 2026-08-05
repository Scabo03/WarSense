# Resoconto — Le sessioni di campagna passano per l'interfaccia

Commit: `9574a25` (sessioni per l'interfaccia), `1ce8a5e` (fusione), `17e4c11` (incarico archiviato). Ramo di lavoro `sessioni-per-interfaccia`.

## 0. Verifica dello stato di partenza

Le tre condizioni sono state verificate prima di toccare qualunque cosa.

- **Ramo e commit**: `git log --oneline -6` su `principale` dà `3bc7b3d`, `cd3e7a9`, `c4f7fe8`, `e35b61a`, `5fefd77` — i cinque attesi — e `git status --short` non riporta modifiche.
- **Collaudo**: `./scripts/collaudo-completo.sh` è uscito con **0**; l'esecutore riporta 232 prove del pacchetto con una saltata e zero fallimenti.
- **Registro delle build**: `scripts/controlla-build.py` risponde «registro e App Store Connect concordano: 14 build, la più alta è la 14», uscita 0.

Nessuna discrepanza. Nessuna prescrizione dell'incarico è risultata in contrasto con un documento consolidato.

## 1. Le sessioni complete per l'interfaccia — chiusa per la campagna, non per la battaglia

**Che cosa passa ora per l'interfaccia.** `SessioniPerInterfacciaTest.test_00_3_1_ogni_sessione_generata_giocata_al_dito_da_lo_stesso_stato` gioca **144 sessioni su 144 generate**, toccando le caselle, e confronta ciascuna con la corsa del Motore sulla medesima configurazione: stessa impronta e stesso numero di ordini, altrimenti fallisce. Il numero è **stampato dalla prova** (riga `MISURA sessioni per interfaccia`) e non contato a mano.

**L'elenco e la condotta hanno una definizione sola.** `BancoSessioniCampagna.configurazioni(mappe:formati:gruppiMassimi:)` produce la lista che il banco gioca nel Motore e che questa prova gioca al dito; `BancoSessioniCampagna.prossimoOrdine(stato:vista:condotta:)` produce l'ordine per entrambi. Ciò che la prova aggiunge è la sola traduzione dell'ordine in tocchi.

Non è una precauzione teorica: **la prima stesura teneva due condotte separate** — il gruppo scelto con `gruppiOrdinati` da un lato e con `prossimoGruppoInAttesa` dall'altro — e le impronte divergevano appena i gruppi erano più d'uno (`guado con 2 gruppi, raccolti, avanti`: 8 ordini per parte, impronte `c8255a57…` e `4005b577…`). La condotta è stata estratta in un punto solo e la divergenza è sparita.

**L'inizializzatore per scenario NON è un canale di collaudo, e la premessa è stata verificata prima di realizzarlo**, come l'incarico chiedeva. `Fondamenta/01-progetto-del-gioco.md` §5.6.9 (riga 305) stabilisce che le campagne aperte contemporaneamente sono in genere più d'una, ciascuna su una mappa propria, con almeno cinque mappe per fronte; §5.6.10 (riga 313) fa entrare nella mappa dalla schermata delle campagne scegliendo una località. La schermata aprirà quindi la campagna scelta a partire dal **suo** scenario, non da uno di tre formati fissi — e le tre `Taglia` sono «le tre campagne di prova», come il commento nel codice già dichiarava. `PartitaCampagna.init(nuova:scenario:)` è dunque la forma che il gioco richiede; `init(nuova:taglia:)` vi delega.

**`Verifica` è ora un prodotto del pacchetto**, dipendenza del solo bersaglio `WarSenseTest`. Il confine di 05 §1.3 resta intero: la Presentazione non la importa e `ConfiniTest.test_05_1_3_confini_della_presentazione` lo sorveglia; i bersagli di prova non entrano nell'archivio (`memoria-infrastruttura.md`, «Progetto applicativo»).

**I costi, tutti da strumento.**

| grandezza | valore | strumento |
|---|---|---|
| sessioni per l'interfaccia | 144 su 144 generate | riga `MISURA` stampata dalla prova |
| ordini impartiti al dito | 3744 | idem |
| durata delle sole sessioni | **1258,6 s** | idem |
| costo per sessione | **8,741 s** | idem |
| costo per ordine | **0,3362 s** | idem |
| collaudo, parte simulatore, PRIMA | 121,701 s | `IDETestOperationsObserverDebug: … elapsed` |
| collaudo, parte simulatore, DOPO | **1363,688 s** | idem |
| collaudo, parte pacchetto | 30,497 s (era 30,477) | esecutore `swift test` |

Una misura isolata su sottoinsieme dichiarato (24 sessioni, 1–2 gruppi) aveva dato 34,4 s, 1,433 s per sessione e 0,2389 s per ordine: il costo per ordine cresce con il numero di gruppi, perché cresce il costo di ciascuna attesa di stato.

**Il costo va riportato senza attenuarlo: venti minuti e cinquanta secondi, non sette.** La decisione di tenere le sessioni nel collaudo di ogni caricamento non è stata riaperta e resta in vigore; il numero su cui fu presa era però un terzo di quello vero, e il titolare deve saperlo per poterla confermare o rivedere.

**Intermittenza: nessuna osservata.** La prova è stata eseguita tre volte in questa sessione — due complete e una su sottoinsieme — sempre con lo stesso esito. Tre esecuzioni **non** sono una misura di intermittenza a una parte su venti: il dato è insufficiente e va detto così. Ciò che riduce strutturalmente il rischio è che la prova non contiene attese a tempo fisso: ogni passo attende una CONDIZIONE (`impronta` cambiata, avviso presentato, avviso congedato) con un tetto, e un tetto raggiunto fallisce invece di proseguire.

**Le sessioni di BATTAGLIA non passano per l'interfaccia.** Registrato come **S11**. Il banco ne genera 32 per 130 322 comandi complessivi (voce `comandi_nelle_sessioni_di_battaglia` del blocco `#sessioni_riepilogo`); al costo per ordine misurato di 0,3362 s sono **dell'ordine delle dodici ore**. Servirebbe inoltre un traduttore da comando a tocchi per tutti e nove i casi di `ComandoBattaglia`, contro i due della campagna. Non è stato scritto. È l'unica parte della sezione 1 che resta aperta.

## 2. Che cosa NON ho fatto

- **Il manifest dei testi (sezione 2 dell'incarico): non aperta.** Resta l'unico artefatto di contenuto che nessuna prova verifica; `Testi.carica` legge il campo `impronte` e non lo confronta.
- **Il conteggio delle prove (sezione 3): non realizzato come strumento.** Vedi sotto per ciò che ho comunque misurato e per il motivo per cui il controllo ingenuo non va installato.
- **La cella che non entra (sezione 4): non aperta.** S10 resta com'era.

La ragione è la capacità della sessione, non una valutazione di merito: la sola sezione 1 ha richiesto tre esecuzioni da venti minuti ciascuna. L'incarico prescrive di fermarsi al confine dell'ultima sezione conclusa e verde, e che la sezione 1 non è rinviabile: è quella che ho chiuso.

## 3. Il conteggio delle prove: numeri da strumento, e perché il controllo ingenuo non va installato

Conteggio prodotto da uno scanner Python eseguito in sessione, che scompone i sorgenti in funzioni `test…` e cerca in ciascuna un'asserzione:

| bersaglio | funzioni `test` | segnalate prive di asserzione |
|---|---|---|
| pacchetto | **232** | 11 |
| ospitate | **56** | 3 |
| interfaccia | **8** | 0 |

Il conteggio del pacchetto coincide esattamente con quello dell'esecutore (232), il che convalida lo scanner come contatore.

**Le quattordici segnalazioni sono però quasi tutte false.** Dieci di `CaricamentoCampagnaTest` asseriscono dentro l'ausiliaria `attendiRifiuto`; `AnnuncioDiCasellaTest` dentro `accertaCheLaDesignazioneConservi`; `CatenaInterfacciaMotoreTest` e `SessioniPerInterfacciaTest` dentro `giocaEConfronta` e `giocaTutte`. Una sola è genuinamente priva di asserzioni ed è `RigenerazioneOroTest`, che è l'attrezzo saltato per progetto.

**Ne segue che il controllo ingenuo non va installato come cancello**: rifiuterebbe tredici prove legittime. Un controllo corretto deve seguire le chiamate alle ausiliarie, e non è un lavoro di espressioni regolari. La sezione 3 resta quindi aperta, e questa è la ragione tecnica.

## 4. Ciò su cui non ho raggiunto certezza

- Se l'intermittenza esista a frequenze basse: tre esecuzioni non lo dicono.
- Se il costo per ordine cresca linearmente con i gruppi o in altro modo: ho due punti (0,2389 s con 1–2 gruppi, 0,3362 s sull'insieme fino a 12) e due punti non definiscono una curva.

## 5. Perché non ho caricato

L'incarico condiziona il caricamento alla chiusura della sezione 1. La sezione 1 è chiusa per la campagna e **non** per la battaglia (S11), quindi non ho caricato. `MARKETING_VERSION` resta `1.1.0`, la versione dei valori `0.5.0`, l'ultima build su App Store Connect è la **14**, invariata. Nessun certificato, profilo o identificatore creato, revocato o modificato.

**Valutazione sulla versione dei valori, dichiarata e non lasciata per omissione:** non si incrementa. Il criterio è 03 §9.2.1 — la versione sale quando cambia una regola che incide sul modo in cui una partita in corso si svolgerebbe. In questa sessione non è cambiato alcun file di `Contenuti/Valori/`, né alcuna formula del Motore: le modifiche riguardano il banco di verifica, un inizializzatore della Presentazione e le prove. Una partita salvata prima proseguirebbe identica.

`note-di-rilascio.txt` e `nota-per-il-titolare-mappa.md` non sono state rigenerate, perché non c'è build da descrivere; il controllo di freschezza le rifiuterà entrambe al prossimo caricamento finché non lo saranno, ed è il comportamento voluto.

## 6. Da dove si riprende

1. **S11**: le sessioni di battaglia per l'interfaccia, con il numero delle dodici ore da guardare in faccia prima di cominciare.
2. **Il manifest dei testi**, che nessuna prova verifica.
3. **Il conteggio delle prove**, con un controllo che segua le ausiliarie.
4. **S10**, la cella della zona arretrata che non entra nella porzione visibile.
