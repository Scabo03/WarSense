# Esame critico del progetto, della sua documentazione e del proprio andamento

Documento prodotto in una sessione che non ha scritto codice, non ha corretto difetti e non ha caricato build. Nessun file sorgente del programma è stato modificato; `git status` alla chiusura mostra come sola aggiunta questo file.

## Nota sul metodo e sui limiti delle fonti

Ogni numero di questo documento è stato prodotto durante la sessione, con il comando dichiarato nel punto stesso in cui compare. Nessun numero viene da un documento del progetto senza essere stato rieseguito.

Tre limiti di fonte vanno dichiarati subito, perché condizionano ciò che segue.

1. **Gli incarichi ricevuti non sono conservati.** Non esistono nella cartella né nella cronologia: `grep -rn "incarico" --include="*.md" .` restituisce diciassette occorrenze, tutte citazioni indirette dentro documenti di lavoro, nessun testo di incarico. Dove ricostruisco che cosa era stato chiesto, la fonte è una citazione della sessione stessa che l'ha eseguito (RDA-61, RDA-77, `registro-scostamenti.md` S6, `stato-avanzamento.md` riga 94): è una fonte di parte, ed è marcata come tale ogni volta.
2. **I resoconti di sessione non sono conservati.** Esiste `stato-avanzamento.md`, che è la loro distillazione cumulativa, e `note-di-rilascio.txt`, che è la nota per i tester. Le richieste dell'incarico che riguardano la posizione di una discrepanza *dentro* un resoconto — se si concentrino nelle sezioni finali — sono quindi **non verificabili**, e lo dichiaro qui una volta per tutte anziché riempire il vuoto. Ciò che invece è verificabile, e che ho verificato, è la concentrazione per **documento** e per **tipo di affermazione**.
3. **Non conosco gli altri sei progetti.** Non ne ipotizzo alcuna caratteristica. La sezione 5 elenca invece ciò che è insolito *di questo* rispetto a un progetto di sviluppo ordinario.

---

# 1. Contraddizioni, lacune, incertezze, trappole

## 1.1 Contraddizioni

### C1 — I cinque documenti normativi sono fermi a prima della fase D, mentre la fase D ha prodotto diciassette decisioni

Comando: `for f in Fondamenta/0*.md; do git log -1 --format='%h %ad' --date=format:'%m-%d %H:%M' -- "$f"; done`

| documento | ultimo commit che lo tocca | data |
|---|---|---|
| 00 principi | `037928e` | 08-02 20:54 (fondazione) |
| 01 progetto del gioco | `71db5e6` | 08-04 18:02 |
| 02 accessibilità | `71db5e6` | 08-04 18:02 |
| 03 dati | `bfd9eb3` | 08-04 15:00 |
| 05 architettura | `71db5e6` | 08-04 18:02 |

La fase D comincia con `a05756a` (08-04 19:58) e conta undici commit fino a `349ee17` (08-05 09:53). **Nessuno dei cinque normativi è stato toccato in nessuno di quegli undici commit.** Nelle fasi B e C la disciplina opposta era praticata senza eccezioni: ogni tranche portava con sé l'incremento di versione dei consolidati, ed è scritto nei messaggi di commit (`ca76acc` «01 v3.3, 02 v2.2, 03 v2.1», `3fd54b6` «01 v3.4…», `75a133e` «01 v3.5…», `bfd9eb3` «01 v3.6…», `71db5e6` «01 v3.7…»). Da `a05756a` in poi quella riga scompare dai messaggi di commit.

Nel frattempo la fase D ha prodotto RDA-61…RDA-77 (`grep -c "^### RDA-" Fondamenta/registro-decisioni-architetturali.md` dà 77 voci in totale), gli scostamenti S4…S9 e le precisazioni P9…P12, e ha portato la versione dei valori da 0.4.0 a 0.5.0. Nulla di ciò è recepito nei documenti che, secondo 05 §0.3, prevalgono.

**Effetto concreto.** È la contraddizione generatrice di quasi tutte le altre di questa sezione, e produce quattro conflitti vivi fra ciò che i normativi prescrivono e ciò che il codice fa (C2, C3, C4, C5).

**Costo della correzione.** Recepire in 01, 02 e 05 le decisioni della fase D: una versione nuova per ciascuno dei tre, con i punti 5.17.1, 6.6.2, 9.2.1, 2.7 e 7.5 riscritti. Lavoro di scrittura di una sessione, nessun codice.

### C2 — Il registro annota gli ordini del giocatore, che due documenti normativi vietano

`Fondamenta/01-progetto-del-gioco.md` riga 427 (§5.17.1): «Non vi entrano i propri ordini, che il giocatore ha appena impartito e già sentito confermare.»
`Fondamenta/02-accessibilita.md` riga 175 (§6.6.2): «Vi entrano soltanto i fatti che il giocatore non ha deciso… Non vi entrano i propri ordini.»

Il codice fa l'opposto: `Codice/Sources/Motore/StatoCampagna.swift` righe 79–94, `enum FattoRegistrato` con i casi `marciaOrdinata`, `presidioOrdinato`, `ordineAnnullato`, `giornataAzzerata`.

La deroga è registrata in `registro-scostamenti.md` S8 e in RDA-72, cioè in due documenti di lavoro. **Nessuna regola di precedenza dichiarata li fa prevalere su 01 e 02.** 05 §0.3 dice il contrario: «In caso di conflitto fra questo documento e un consolidato, prevale il consolidato per le regole di gioco e di presentazione».

**Effetto concreto.** Una sessione che arriva senza memoria, con il perimetro «registro», legge 01 §5.17.1 e 02 §6.6.2 — che sono l'autorità dichiarata — e toglie dal registro gli ordini del giocatore, disfacendo una decisione presa dal titolare due giorni prima. Il rischio è tanto più alto in quanto S8 dichiara espressamente che «quando i fatti non decisi dal giocatore esisteranno, la materia si riapre».

**Costo.** Una versione nuova di 01 e di 02, due punti riscritti.

### C3 — La designazione della marcia non apre alcun pannello di conferma, che 02 §9.2.1 prescrive

`Fondamenta/02-accessibilita.md` riga 233 (§9.2.1): «…si naviga fino alla cella del bersaglio e la si attiva, il che apre il pannello di conferma con le stesse informazioni.»

`Applicazione/Sorgenti/SchermataMappaCampagna.swift` righe 192–200: `attiva(_:)`, con una designazione di marcia in corso, costruisce il comando e lo esegue immediatamente; nessun pannello di conferma esiste.

Questa deviazione **non compare in `registro-scostamenti.md`**: è nominata una sola volta, di sfuggita, dentro `impatto-marcia-lunga.md` riga 53 («che è già uno scostamento da 02 §9.2.1»), cioè in un documento di dimensionamento scritto per un'unità futura. La precisazione P10, che discute proprio 02 §9.2.1 sulla mappa, non se ne accorge.

**Effetto concreto.** Un requisito di accessibilità non realizzato, registrato nel posto dove nessuno lo cercherà. `impatto-marcia-lunga.md` lo tratta come lavoro dell'unità successiva; fino ad allora resta un requisito violato senza scostamento.

**Costo.** Una riga in `registro-scostamenti.md` per registrarlo adesso; la realizzazione è già dimensionata in `impatto-marcia-lunga.md` §5.

### C4 — 05 §14.1 prescrive un'integrazione continua locale senza servizi esterni; il progetto ne ha una remota che copre il 83 per cento delle prove

`Fondamenta/05-architettura-tecnica.md` §14.1: «Tutto gira a ogni modifica in integrazione continua locale (nessun servizio esterno richiesto).»

`.github/workflows/collaudo.yml` righe 11–18: un job su `macos-15` che esegue esclusivamente `swift test --package-path Codice`.

Conteggi (comando: `grep -h "func test" Codice/Tests/*/*.swift | wc -l`, idem per `Applicazione/ProveOspitate` e `Applicazione/ProveInterfaccia`):

| livello | prove | girano in CI | girano prima di un caricamento |
|---|---|---|---|
| pacchetto (`swift test`) | 217 | sì | sì |
| ospitate (`WarSenseTest`) | 42 | **no** | **no** |
| interfaccia (`WarSenseUITest`) | 2 | **no** | **no** |

Il cancello del caricamento è `scripts/carica-testflight.sh` riga 77: `(cd "$RADICE/Codice" && swift test 2>&1 | tail -2)`. Con `set -euo pipefail` in testa (riga 5) il fallimento si propaga, quindi la dichiarazione di `memoria-infrastruttura.md` riga 95 — «lo script esegue l'INTERO collaudo del pacchetto prima di archiviare e si ferma se una prova fallisce» — **regge alla lettera**. Ma «l'intero collaudo del pacchetto» sono 217 prove su 261: le 44 prove di livello applicativo non sono mai state un cancello, né in CI né al caricamento.

La stessa `memoria-infrastruttura.md` riga 95 presenta la cosa come una protezione: «I bersagli di prova del progetto applicativo non entrano nell'archivio…, quindi non possono rompere una consegna.» È vero, e per la ragione sbagliata: non possono romperla perché non vengono eseguiti.

**Effetto concreto.** È il punto centrale di questo esame ed è ripreso in 3.4 e in 5.C. Le 44 prove al livello in cui i difetti riferiti si sono manifestati sono le uniche che nessun procedimento automatico esegue.

**Costo.** Aggiungere al workflow un `xcodebuild test -scheme WarSense -destination 'platform=iOS Simulator,name=…'`: una decina di righe di YAML e tre righe nello script di caricamento. Verificato eseguibile in questa sessione: il comando gira e completa in circa 45 secondi.

### C5 — `memoria-infrastruttura.md` contiene due procedure incompatibili per le impronte, nello stesso file

Riga 30 (regola 6): «Dal 2026-08-04 esiste lo script: `python3 scripts/rigenera-impronte.py`… Sostituisce il frammento Python scritto a mano che si usava prima.»
Riga 91: «Terzo punto da non dimenticare… Lo snippet è nella cronologia (python, sha256 dei file elencati, riscrittura di manifest.json); tenere l'elenco dei file del manifest allineato a ciò che esiste nella cartella.»

Lo stesso errore è replicato in `stato-avanzamento.md`, che alla riga 9 prescrive lo script e alla riga 215 rimanda ancora allo «script Python inline usato in fase A, vedi cronologia git».

**Effetto concreto.** Chi legge il secondo paragrafo esegue a mano un'operazione che uno strumento fa meglio, e in particolare deve «tenere l'elenco dei file allineato», che è precisamente ciò che lo script fa da sé con `rglob` (`scripts/rigenera-impronte.py` riga 28). È l'errore che la memoria di infrastruttura, alla riga 93, dichiara di voler impedire: «una regola si può dimenticare, un controllo no».

**Costo.** Cancellare due paragrafi.

### C6 — `Fondamenta/matrice-di-copertura.md` si contraddice al proprio interno sulle versioni che dichiara di coprire

Riga 7: «…00 carta dei principi (versione 1.2), 01 progetto del gioco (versione **3.3**), 02 accessibilità (versione **2.2**), 03 dati (versione **2.1**)…»
Riga 100: «### Documento 01 — Progetto del gioco (versione **3.2**)»
Riga 449: «### Documento 02 — Accessibilità (versione **2.1**)»
Riga 584: «### Documento 03 — Dati (versione **2.0**)»

Le versioni in vigore, lette in testa ai file: 01 v3.7, 02 v2.5, 03 v2.4, 05 v1.3. Nessuno dei due insiemi di numeri della matrice è corretto, e i due insiemi non concordano fra loro.

Riga 11 della matrice stessa: «Se una futura versione di un consolidato aggiunge o modifica punti numerati, la matrice va aggiornata nella stessa occasione.» Comando: `git log --oneline -- Fondamenta/matrice-di-copertura.md | wc -l` → 4 aggiornamenti su 39 commit; l'ultimo è `1a4e5c9`, otto commit fa.

**Effetto concreto.** La matrice è l'unico artefatto che risponde alla domanda «questo requisito è coperto?». Oggi risponde per un progetto che non esiste più, e lo fa con l'autorità di una tabella. Le sezioni 9.10 (modificatori di posizione), 9.11 (limite dei bersagli), 15.2.5 (annientamento simultaneo), 9.7.1 (risoluzione immediata) non vi compaiono affatto.

**Costo.** Rigenerare la matrice contro le versioni correnti è lavoro meccanico ma ampio: 715 righe. In alternativa, dichiararla superata e sostituirla con l'appendice per unità che già esiste in coda (righe 667–714), che è aggiornata e utile.

### C7 — `01 §5.1` dichiara tre formati di mappa, `01 §5.14.5.1` ne nomina un quarto

Registrata come S5 in `registro-scostamenti.md` e lasciata **aperta di proposito** dalla prima unità della fase D. È l'unica contraddizione di questo elenco che il progetto conosce e ha deciso di non chiudere. La motivo come corretta: chiuderla richiede una decisione sulla portata della conoscenza che appartiene al titolare, e `formati-mappa.json` la rende una voce di dati e non una riga di codice.

## 1.2 Lacune

### L1 — La gerarchia delle fonti non nomina i documenti di lavoro, che di fatto contengono regole

Le regole di precedenza dichiarate sono due e coprono quattro livelli: 00 §13 («Se un principio entra in conflitto con un altro, prevale quello con il numero più basso»), 05 §0.3 (00 > 05; consolidato > 05 per le regole di gioco e presentazione; 05 > consolidato per la realizzazione tecnica).

Le fonti che il progetto usa in pratica sono **sei**: 00; i consolidati 01–03; 05; il registro delle decisioni architetturali; il registro degli scostamenti; e le decisioni del titolare trasmesse a voce negli incarichi, che non sono scritte in alcun luogo permanente. Le ultime due non compaiono nella gerarchia, e la sesta non esiste su carta affatto.

**Effetto concreto.** È il meccanismo di C2 e C3. Un contenuto normativo (S8: gli ordini entrano nel registro) vive in un documento che nessuna regola autorizza a prevalere su quello che lo vieta. La formula ricorrente «per decisione del titolare» compare cinque volte in `registro-scostamenti.md` (righe 47, 133, 143, 187 e nel titolo di S9) e non ha alcuna sede normativa.

**Costo.** Un paragrafo in 05 §0.3 che dichiari: i documenti di lavoro registrano deroghe temporanee; una deroga vale finché non è recepita o revocata; ogni deroga viva è elencata in un unico punto. Mezza pagina.

### L2 — Un valore di gioco non figura in `valori-provvisori.md`, che dichiara ciò un difetto

`valori-provvisori.md` riga 3: «Un valore provvisorio che non risulti da questo elenco è un difetto (incarico fase 5, sezione 3).»

`Codice/Sources/Contenuti/Valori/ufficiali.json` contiene dieci parametri numerici (cinque per ciascuno dei due ufficiali). L'elenco di `valori-provvisori.md` §ufficiali.json ne copre nove: tre dichiarati TARATI (righe 50–51) e sei dichiarati PROVVISORI (riga 52). Manca `ufficiale_prova.propensione_attacco`, che vale **0.7**.

Comando che ne traccia l'origine: `git log -p -- Codice/Sources/Contenuti/Valori/ufficiali.json | grep -E "^COMMIT|propensione_attacco"` → introdotto a `863e899` (fase B) con il valore 0.7 e mai più toccato, nemmeno dalla taratura di fase C che ha invece mosso quello del prudente da 0.3 a 0.6.

Nella stessa intestazione c'è un secondo errore: riga 48, «ufficiali.json — **due** parametri TARATI, **tre** PROVVISORI». Il corpo ne elenca tre TARATI e sei PROVVISORI.

**Effetto concreto.** Un parametro che governa quanto il tattico avanzi e ingaggi non è sotto alcuna disciplina di taratura, e l'intestazione che dovrebbe segnalarlo dice un numero sbagliato due volte. È un difetto secondo la definizione che il documento dà di sé.

**Costo.** Tre righe.

### L3 — La versione dei valori è salita a 0.5.0 e nessun documento lo registra

Comando: `python3 -c "import json;print(json.load(open('Codice/Sources/Contenuti/Valori/manifest.json'))['versione'])"` → `0.5.0`, con `versioni_compatibili: ["0.5.0","0.4.0"]`. Il cambiamento è avvenuto a `61a90e6` (seconda unità).

`grep -rn "0\.5\.0" --include="*.md" .` non restituisce alcuna occorrenza. `stato-avanzamento.md` dice 0.4.0 alla riga 102 e alla riga 155, e la sezione della seconda unità (righe 185–199) non nomina la versione dei valori.

La regola che governa la materia è 03 §9.2.1, richiamata da `memoria-infrastruttura.md` regola 5: la versione sale quando cambia una regola che incide sul modo in cui una partita in corso si svolgerebbe. Poiché `0.4.0` è rimasta fra le `versioni_compatibili`, l'incremento **non produce alcun rifiuto**: nessun salvataggio viene dichiarato incompatibile per effetto suo. Il rifiuto delle campagne in corso, annunciato in `note-di-rilascio.txt`, viene da un meccanismo diverso — `FondazioneCampagna.schemaCorrente` portato a 2 (`Codice/Sources/Sessione/Giornale.swift` riga 51), che `SessioneCampagna.swift` riga 62 verifica prima della versione.

**Effetto concreto.** Non ho trovato alcun danno al gioco. Il danno è documentale e specifico: la sola regola del progetto che ha per scopo dichiarato di proteggere i tester (00 §15.3) è stata applicata senza lasciare traccia della ragione, in un progetto dove la stessa regola è già stata sbagliata una volta e corretta con enfasi (`memoria-infrastruttura.md` regola 5, ultimo periodo).

**Costo.** Due righe in `stato-avanzamento.md`; eventualmente la rimozione di `0.4.0` da `versioni_compatibili` se l'incremento era inteso come rifiuto.

### L4 — Tre prescrizioni obbligatorie di 05 §14 non hanno alcuna realizzazione

- **05 §14.2**, «divieto di fonti di caso esterne (A §4.1)» fra le prove obbligatorie, e RDA-06, «ogni altra fonte vietata e **sorvegliata dal collaudo**». Comando: `grep -rn "shuffled\|randomElement\|Int.random\|SystemRandom" Codice/Sources` → nessun risultato: oggi non c'è caso nel pacchetto. Ma `Codice/Tests/ConfiniTest/ConfiniTest.swift` sorveglia gli import (§1.3), la virgola mobile nel Motore (RDA-44) e le stringhe utente (00 §14.1), e **non** le fonti del caso. La sorveglianza dichiarata non esiste.
- **05 §14.6**, «Almeno una riproduzione è incrociata fra iOS e macOS, a presidio del determinismo fra piattaforme». Comando: `grep -rln "RiproduzioneOro\|impronta" Applicazione/ProveOspitate/` → nessun risultato. Nessuna riproduzione d'oro gira su iOS. Il determinismo fra piattaforme, che è la ragione dichiarata della virgola fissa (RDA-44), non è verificato da nulla.
- **05 §14.6**, riproduzioni d'oro «di partite significative (uno scontro completo, **una campagna**, un inverno)». Esistono `RiproduzioneOro/`, `RiproduzioneOroRiserve/` e `SalvataggioBuildDistribuita/`, tutte e tre di battaglia. La campagna esiste da due unità e non ha oro. L'inverno non esiste ancora, quindi la sua assenza è legittima.

**Effetto concreto.** Tre reti di sicurezza prescritte da un documento normativo non esistono, e nessun documento di lavoro le registra come mancanti. La terza è la più costosa: la campagna ha già cambiato formato di salvataggio una volta e lo cambierà di nuovo (`impatto-marcia-lunga.md` §1), senza alcun oro che dica se il cambiamento sia quello voluto.

**Costo.** La sorveglianza del caso: una prova in `ConfiniTest`, dieci righe. L'oro di campagna: un giornale registrato più la prova, un'ora. La riproduzione incrociata iOS/macOS: una prova ospitata che riapplica lo stesso giornale d'oro, due ore comprese le risorse.

### L5 — La copertura del pixel esiste per una schermata sola, e il documento lo dichiara solo per il registro

`Applicazione/ProveOspitate/RegistroVisibileTest.swift` misura il contrasto reale dei pixel disegnati (righe 156–221, `struct Quadro`) e ha il proprio mutante (riga 119, `test_00_1_2_la_misura_coglie_il_difetto_da_cui_nasce`). È la prova migliore del progetto. Copre `SchermataRegistro` e nient'altro.

`collaudo-solo-dispositivo.md` righe 150–157 lo dichiara con onestà. La lacuna non è nella dichiarazione ma nel fatto che il difetto da cui nasce — un elemento agganciabile dalla voce e invisibile all'occhio — è per costruzione possibile in ogni schermata, e la misura è già scritta e riusabile.

**Costo.** Applicare `Quadro` a `SchermataBattaglia` e `SchermataMappaCampagna`: mezz'ora, più la definizione dei casi in cui il grigio è corretto (comandi disabilitati per ragioni di gioco), che il documento già individua.

## 1.3 Incertezze

### I1 — «Presidio» è documentato come azione ma non come termine del vocabolario chiuso

RDA-77 chiude la questione: 01 §5.6.8.1 elenca testualmente «presidio, cioè restare fermi in guardia (5.6.0.6)», e ho verificato la riga (`Fondamenta/01-progetto-del-gioco.md` riga 303, che elenca sedici voci — le ho contate: otto per tutti i gruppi, sei per i soli armati, due per la ricognizione). La chiusura è corretta.

Resta incerto ciò che RDA-77 stesso dichiara aperto: 02 §4.4.5 elenca gli **stati** e non le **azioni**, quindi i nomi delle azioni non hanno una sede dove essere fissati e resi invariabili. L'invariabilità oggi è ottenuta di fatto (tutte le chiavi usano la radice `presidio`) e non per regola.

**Effetto concreto.** Un incarico ha già inciampato su questo, e inciamperà di nuovo: senza una sede dichiarata, ogni lettore che non trovi il termine in 02 §4.4.5 conclude che non sia documentato.

**Costo.** Un punto nuovo in 02, quattro righe.

### I2 — Non è determinabile se il costo in giorni pari a uno sia una regola o un caso particolare, senza leggere tre documenti

`Codice/Sources/Contenuti/Valori/marcia-campagna.json` contiene `{"costo_giorni_base": 1}`. Il fatto che questo NON sia la regola «una casella costa una giornata» è dichiarato in quattro luoghi diversi: `valori-provvisori.md` riga 90, RDA-75, `registro-scostamenti.md` S6 riga 105, `stato-avanzamento.md` riga 227. La ripetizione quadruplice è essa stessa la misura di quanto la sessione temesse l'equivoco.

L'incertezza residua sta altrove: `#campagna_distanze` stampa `giornate_per_congiungerli` accanto a `distanza_fra_quartier_generali`, e oggi le due colonne portano lo stesso numero per costruzione (verificato: `guado 3,3 / istmo 5,5 / pianura_lunga 10,10`). Chi legge il CSV senza i quattro documenti non può distinguere una coincidenza da un'identità.

**Costo.** Il programma già stampa `costo_in_giorni_dello_scatto,1` nel riepilogo, che è la protezione giusta. Nulla da fare.

## 1.4 Trappole

### T1 — Sei documenti superati sono presenti nella cartella, indistinguibili dai vigenti per chi cerca un numero di punto

`documenti vecchi/` contiene sei file versionati in git: 00 v1.0 e v1.1, 01 v1.2 e v2.0, 02 v1.0 e v1.1. Nessuno dei sei dichiara al proprio interno di essere superato: le prime quattro righe sono identiche per forma a quelle dei vigenti.

Misura (script Python eseguito in sessione, che confronta i punti numerati omonimi):

```
00-principi-non-negoziabili.md         punti in comune   81  con testo diverso   0
00-principi-non-negoziabili copia.md   punti in comune   87  con testo diverso   0
01-progetto-del-gioco.md               punti in comune  121  con testo diverso  32
01-progetto-del-gioco copia.md         punti in comune  208  con testo diverso  21
02-accessibilita.md                    punti in comune   84  con testo diverso   9
02-accessibilita copia.md              punti in comune   99  con testo diverso  10
TOTALE punti omonimi 680, di cui con testo diverso 72
```

Esempi verificati: `01 §11.3` dice «Da confermare. Da quale momento si contano i turni di percorrenza» nella copia vecchia e «Chiuso nella fase di architettura» nel vigente; `01 §2.8.1` dice «Da confermare. Che cosa accada alle truppe della fase precedente» nella copia e «Sorte delle truppe alla transizione. Le truppe e gli asset della fase precedente restano quelli» nel vigente.

**Effetto concreto.** Settantadue punti su cui una ricerca testuale restituisce due risposte contraddittorie, e in ventuno casi almeno la risposta sbagliata è «da confermare» per una questione già chiusa. Questo è il modo più diretto in cui una sessione senza memoria può riaprire una decisione presa: 01 §16.1 vieta espressamente di colmare di propria iniziativa una lacuna, e la copia vecchia gliene mostra ventuna che non esistono più.

**Costo.** Togliere la cartella dal versionamento, oppure premettere a ciascun file una riga «SUPERATO — vale `Fondamenta/<nome>`». Cinque minuti. Il costo di non farlo è la ricomparsa di decisioni chiuse.

### T2 — Una sezione intitolata «Nessuno scostamento strutturale» sta in mezzo a nove scostamenti

`registro-scostamenti.md` riga 123: `## Nessuno scostamento strutturale`, con il corpo «Nessun punto dell'architettura è risultato irrealizzabile o errato nella fase A… I documenti 00–05 non richiedono modifiche.»

È collocata fra S7 e S8, cioè dopo sette scostamenti e prima di due, e il suo contenuto vale solo per la fase A. Un lettore che scorra i titoli legge, in coda al documento, l'affermazione che non ci sono scostamenti strutturali.

**Costo.** Spostarla in testa e intitolarla «Fase A — nessuno scostamento strutturale». Una riga.

### T3 — Un numero di elenco saltato in `collaudo-solo-dispositivo.md`

Le voci di «Le altre verifiche che restano al dispositivo» vanno da 1 a 7; l'aggiunta successiva riprende da 9 (righe 135 e 144); la seconda aggiunta prosegue con 11, 12, 13. La voce 8 non esiste.

**Effetto concreto.** Chi consegna la lista al titolare e chi la riceve non possono accordarsi su «la verifica numero 8». È un documento che si consegna con ogni build.

**Costo.** Un carattere.

### T4 — Lo stesso punto numerato ha due sintesi diverse nella matrice di copertura

`Fondamenta/matrice-di-copertura.md` riga 210: «| 01 §5.6.0.2 | Divisione costa l'azione; distaccamento collocato adiacente |». Riga 683: «| 01 §5.6.0.2 | Al più una propria formazione per casella |». Il punto contiene entrambe le cose, quindi nessuna delle due sintesi è falsa; ma la matrice si legge per numero, e per quel numero dà due righe che non si somigliano.

**Costo.** Trascurabile. Lo segnalo perché è il tipo di trappola che una matrice generata a mano produce sistematicamente al crescere delle appendici.

### T5 — Sette prove sono intestate a un incarico che non esiste nella cartella

Comando: `grep -hn "func test_incarico" Codice/Tests/*/*.swift Applicazione/Prove*/*.swift` → sette occorrenze, fra cui `test_incarico_6_ogni_invariante_ha_almeno_un_mutante_che_lo_fa_scattare` e `test_incarico_7_le_colonne_delle_distanze_nominano_cio_che_misurano`.

Le altre 224 prove sono intestate a un punto numerato (`grep -ho "func test_[0-9][0-9]_[0-9_]*" … | wc -l` → 224) e sono quindi riconducibili a un documento leggibile; 30 non portano intestazione (mutanti e attrezzi).

**Effetto concreto.** Sette prove il cui motivo di esistere non è verificabile da nessuno che non fosse presente. Se una di esse fallisse, chi la legge non ha modo di sapere se stia difendendo un requisito o una preferenza.

**Costo.** Reintestarle al punto documentale che realizzano, dove esiste; altrimenti scrivere la ragione nel commento della prova. Un'ora.

---

# 2. Inventario dei documenti

Comando per lo stato di aggiornamento: `for f in …; do git log --oneline -- "$f" | wc -l; git log -1 --format=%h -- "$f"; done` su 39 commit totali.

## In vigore, mantenuti

| documento | commit che lo toccano | ultimo | osservazioni |
|---|---|---|---|
| `stato-avanzamento.md` | 17 / 39 | `349ee17` | il più mantenuto; 3 affermazioni su 20 verificate non reggono (§4.3) |
| `note-di-rilascio.txt` | 14 / 39 | `61a90e6` | riscritto a ogni consegna; contenuto coerente con il codice attuale |
| `Fondamenta/registro-decisioni-architetturali.md` | 12 / 39 | `61a90e6` | 77 voci; nessuna contraddizione interna trovata |
| `registro-scostamenti.md` | 11 / 39 | `61a90e6` | 9 scostamenti, 12 precisazioni; trappola T2 |
| `memoria-infrastruttura.md` | 11 / 39 | `61a90e6` | contraddizione interna C5 |
| `valori-provvisori.md` | 8 / 39 | `61a90e6` | lacuna L2; un rilievo storico non marcato come tale (§4.3, A41) |
| `collaudo-solo-dispositivo.md` | 6 / 39 | `61a90e6` | un numero stantio (160 giornate contro 400); trappola T3 |
| `forma-dei-resoconti.md` | 1 / 39 | `61a90e6` | dichiarato memoria permanente; revoca esplicitamente la regola precedente |
| `impatto-marcia-lunga.md` | 1 / 39 | `349ee17` | scritto ieri; contiene C3 nel posto sbagliato |

## In vigore, non mantenuti

| documento | commit | ultimo | rischio per chi arriva senza memoria |
|---|---|---|---|
| `Fondamenta/00-principi-non-negoziabili.md` | 1 / 39 | `037928e` | nessuno: è la fondazione e non è stata mai modificata |
| `Fondamenta/01-progetto-del-gioco.md` | 7 / 39 | `71db5e6` | **alto**: prevale per le regole di gioco (05 §0.3) e ignora due unità di campagna (C1, C2) |
| `Fondamenta/02-accessibilita.md` | 7 / 39 | `71db5e6` | **alto**: idem (C2, C3) |
| `Fondamenta/03-dati.md` | 5 / 39 | `bfd9eb3` | medio: nessun valore di campagna vi è registrato |
| `Fondamenta/05-architettura-tecnica.md` | 4 / 39 | `71db5e6` | **alto**: le sue prescrizioni di collaudo §14 sono disattese in tre punti (L4) e in un quarto (C4) |

## Superati e ancora presenti, senza marcatura

| documento | stato | che cosa rischia di leggerne una sessione senza memoria |
|---|---|---|
| `documenti vecchi/` (6 file) | superati | 72 punti numerati con testo diverso dal vigente, 21 dei quali dicono «da confermare» per questioni chiuse (T1) |
| `Fondamenta/matrice-di-copertura.md` | superato di fatto | che un requisito sia coperto quando la copertura si riferisce a versioni di quattro incrementi fa (C6) |
| `nota-per-il-titolare-mappa.md` | **superato, e mai marcato** | quattro affermazioni su quattro verificate sono false rispetto al codice odierno (§4.3) |
| `Proposte/inventario-fase-1.md` | assorbito | 1877 righe di inventario storico, il cui esito è in `Fondamenta/decisioni-fase-2.md`; nessun rischio, ma nessuno lo legge |
| `Direzioni tematiche/` (6 file) | assorbiti nei consolidati | contengono direzioni poi modificate dalle versioni 3.4–3.7 di 01; le decisioni vive stanno nei consolidati |
| `Deep research/` (16 file) | fonte di `Fondamenta/04` | misurato: 1259 righe lunghe su 2154 (58 %) compaiono verbatim in `Fondamenta/04-riferimenti-storici.md` |

### Di dubbia collocazione

- `esposizione-delle-scelte.md` e `resa-del-conto.md` sono documenti-evento: scritti una volta ciascuno, mai aggiornati, e contengono affermazioni sullo stato del gioco che il tempo ha superato (`resa-del-conto.md` §«Ma c'è dell'altro» descrive lo squilibrio dell'ordine dei turni, corretto poi da RDA-60). Restano preziosi come memoria del ragionamento e pericolosi come descrizione dello stato. Nessuno dei due dichiara la propria data.
- `Fondamenta/matrice-di-copertura.md` e `Fondamenta/registro-decisioni-architetturali.md` sono entrambi «Documento di lavoro della fase di architettura — versione 1.0», ma il secondo è cresciuto fino a RDA-77 e il primo si è fermato. Portano la stessa etichetta e hanno destini opposti.

### Volume complessivo

Comandi `wc -w` per classe:

| classe | parole |
|---|---|
| normativi (00, 01, 02, 03, 05) | 53 487 |
| di lavoro (radice + matrice + RDA + decisioni-fase-2) | 62 664 |
| direzioni tematiche + proposte | 34 507 |
| ricerca storica (04 + Deep research) | 167 330 |
| superati (`documenti vecchi/`) | 31 491 |
| **totale** | **349 479** |

Contro: 9 563 righe di Swift sorgente e 7 279 di prove (`cat … | wc -l`), di cui 1 646 righe di commento nel sorgente. In tre giorni e un'ora di calendario (`git log --format=%ad --date=iso`: dal 2026-08-02 20:54:23 al 2026-08-05 09:53:36) sono state aggiunte 17 845 righe di Swift e tolte 958 (`git log --numstat --format='' -- '*.swift' | awk …`).

Il corpus che una sessione deve tenere per essere in regola — 00, i consolidati del proprio perimetro, 05, `stato-avanzamento.md`, `registro-scostamenti.md`, `valori-provvisori.md`, `memoria-infrastruttura.md`, `forma-dei-resoconti.md` — sta fra le 90 000 e le 116 000 parole a seconda del perimetro, cioè fra 120 000 e 155 000 gettoni circa, prima di aver aperto un solo file di codice.

---

# 3. Il corpo delle prove

## 3.1 Che cosa esiste, e a quale livello

Comandi: `grep -h "func test" <dir>/*.swift | wc -l` per ciascuna directory; esecuzione `swift test` in `Codice/`; `xcodebuild test -project Applicazione/WarSense.xcodeproj -scheme WarSense -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WarSenseTest`.

| bersaglio | prove | esito misurato in questa sessione | livello reale |
|---|---|---|---|
| `MotoreTest` | 109 | | logica pura, nessuna interfaccia |
| `SessioneTest` | 32 | | persistenza e giornale, nessuna interfaccia |
| `VerificaTest` | 30 | | programma di verifica, nessuna interfaccia |
| `DatiTest` | 23 | | caricamento e validazione |
| `SegnaliTest` | 19 | | traduzione evento→annuncio, contenuto delle frasi |
| `ConfiniTest` | 4 | | analisi statica dei sorgenti |
| **totale pacchetto** | **217** | **217 eseguite, 1 saltata, 0 fallimenti, 4,0 s** | |
| `WarSenseTest` (ospitate) | 42 | **42 eseguite, 0 fallimenti, 8,6 s** | schermate istanziate in una `UIWindow`, lette da un modello del percorso di accessibilità |
| `WarSenseUITest` (interfaccia) | 2 | **2 eseguite, 0 fallimenti, 26,5 s** | servizio di accessibilità reale del simulatore |

I conteggi dichiarati in `stato-avanzamento.md` riga 199 («217 prove del pacchetto (una saltata) più 42 ospitate e 2 d'interfaccia, tutte verdi») **reggono per intero**.

**Distribuzione per livello: 217 prove (83 %) sotto l'interfaccia; 42 (16 %) su un modello dell'interfaccia; 2 (0,8 %) sull'interfaccia vera.**

## 3.2 Che cosa affermano di verificare, e che cosa verificano

### Il caso più importante: `LettoreAccessibilita` è un modello scritto dallo stesso autore del codice che giudica

`Applicazione/ProveOspitate/LettoreAccessibilita.swift` è nato per catturare in automatico il difetto della build 3 (tessere del deck ad altezza zero, dichiarate e non agganciabili: S3). Ricostruisce l'ordine di lettura, le cornici, i bersagli minimi. Il file lo dichiara alle righe 40–44: «Nel collaudo ospitato il runtime di accessibilità non è caricato: controlli ed etichette di sistema non dichiarano da sé la propria natura. Si applica la stessa derivazione convenzionale del runtime».

Il punto non è che la dichiarazione manchi — è esemplare. Il punto è strutturale: **la correzione del difetto «le prove verificavano la dichiarazione e non la raggiungibilità» consiste in una seconda dichiarazione, scritta dalla stessa mano.** Se il modello e il runtime divergono, nessuna prova lo dice. È la stessa forma del difetto che intendeva chiudere, spostata di un livello.

Le 42 prove ospitate ereditano questa proprietà per intero.

### Le due prove d'interfaccia non provano il comportamento che 05 §14.4 prescrive

`Fondamenta/05-architettura-tecnica.md` §14.4: «le prove di fuoco di A §10.3 eseguite su interfaccia reale (XCUITest): dopo il piazzamento il fuoco è sulla cella, dopo l'esaurimento del deck il fuoco non si muove, all'arrivo dei rinforzi il fuoco non si muove».

`Applicazione/ProveInterfaccia/FumoInterfacciaTest.swift` righe 3–5 dichiara il contrario: «Le verifiche fini del fuoco stanno nelle prove ospitate». Nessuno dei tre casi nominati è provato su interfaccia reale. Ciò che la prova fa: verificare l'esistenza di quattro etichette, toccare tre tessere del deck e controllare che il valore contenga «selezionato», verificare che quattro comandi globali esistano e siano `isHittable`.

`Applicazione/ProveInterfaccia/FumoMappaCampagnaTest.swift` righe 40–48 dichiara che l'attivazione della casella **non si prova qui**, perché le caselle rispondono all'attivazione assistiva e non al tocco grezzo (osservazione P11). L'unica prova d'interfaccia della mappa di campagna, quindi, **non impartisce alcun ordine**: apre la campagna, verifica etichette, apre e chiude il registro.

Conseguenza netta: **nessuna prova automatica del progetto esercita il gioco attraverso il servizio di accessibilità reale.** Le due che vi passano verificano che le etichette esistano.

### Una prova di determinismo che non può cogliere la nondeterminatezza più probabile

`Codice/Tests/VerificaTest/FumoDelleSimulazioniTest.swift` righe 43–47, `test_05_12_6_l_uscita_e_riproducibile`: costruisce due `ProgrammaDiVerifica` e confronta il testo. Le due corse avvengono **nello stesso processo**. La fonte di nondeterminatezza più tipica in Swift — l'ordine di iterazione di `Dictionary` e `Set`, che dipende da un seme di hash per processo — è per costruzione identica nelle due corse. La prova non può vederla.

RDA-59 dichiara: «La riproducibilità è totale e collaudata: due corse sugli stessi dati danno lo stesso identico rapporto, carattere per carattere.» Il collaudo verifica la riproducibilità **entro un processo**.

Ho eseguito la verifica mancante: due invocazioni separate di `swift run StrumentoVerifica`, uscite su file distinti, `diff` → **identiche, 460 righe**. Nessun difetto oggi. La rete, però, non è quella dichiarata.

Ho anche cercato la nondeterminatezza direttamente: `grep -rn "for .* in .*\.keys" Codice/Sources/Motore/*.swift` trova un solo caso, `MotoreBattaglia.swift` riga 534, `for id in stato.sciami.keys where … { stato.sciami[id]!.azioneSpesa = false }`. È un'assegnazione idempotente su voci indipendenti: l'ordine non incide. Non è un difetto.

### Una guardia del formato di salvataggio che non copre uno dei tre tipi che dichiara di coprire

`stato-avanzamento.md` riga 219: «Chi aggiunge un caso a `ComandoBattaglia`, a `ComandoCampagna` o a `VoceGiornale` DEVE aggiungere il campione corrispondente in `Tests/SessioneTest/CampioniGiornale/campioni.jsonl` nella stessa modifica: `CompatibilitaGiornaleTest` lo pretende e fallisce altrimenti.»

Lettura di `Codice/Tests/SessioneTest/CompatibilitaGiornaleTest.swift`:

- Per `ComandoBattaglia` e `ComandoCampagna` l'affermazione **regge**, e per una ragione forte: le funzioni `etichettaCaso` (righe 81–100) sono `switch` esaustivi, quindi aggiungere un caso all'enumerativo **non compila** finché non lo si dichiara, e l'assenza del campione fa poi fallire il confronto delle righe 56–58.
- Per `VoceGiornale` l'affermazione **non regge**. L'insieme `casiVoce` è costruito leggendo le chiavi JSON **dei campioni** (riga 50, `chiaviDiPrimoLivelloDellaVoce`) e confrontato con un insieme letterale scritto a mano (righe 68–71). Un caso nuovo di `VoceGiornale` senza campione non compare in `casiVoce`, l'uguaglianza con il letterale continua a valere, e **la prova passa**. Non esiste alcun `switch` esaustivo su `VoceGiornale` in tutto il collaudo: `grep -rln "VoceGiornale" Codice/Tests Applicazione/Prove*` restituisce quel solo file.

Non è teorico. `impatto-marcia-lunga.md` §7 e RDA-76 stabiliscono che la revoca della marcia porterà **un caso nuovo di `VoceGiornale`**, e la tabella di riga 74 lo prevede espressamente. La prossima unità cammina dritta dentro il buco, con la riga 219 di `stato-avanzamento.md` che le assicura di essere protetta.

### Le prove senza asserzione non sono un problema

Uno script eseguito in sessione ha isolato dodici funzioni `test…` senza `XCTAssert` nel corpo. Le ho lette tutte: undici usano l'ausiliaria `attendiRifiuto` di `CaricamentoCampagnaTest.swift` righe 43–54, che asserisce al proprio interno; una è `RigenerazioneOroTest`, l'attrezzo saltato per progetto (`RIGENERA_ORO`). **Nessuna prova priva di asserzione.**

## 3.3 Copertura dichiarativa

Script eseguito in sessione: estrae i punti numerati di `Fondamenta/01-progetto-del-gioco.md` e li confronta con i punti citati nei nomi e nei commenti delle prove.

```
punti numerati in 01: 368; citati almeno una volta dalle prove: 68 (18%)
```

Il numero va letto con cautela: la maggior parte di 01 riguarda fasi non costruite (regno, inverno, rifornimento, assedi). Ma è il numero contro cui 05 §14.2 va misurato — «Ogni regola numerata dei consolidati **che il Motore realizza** ha almeno una prova che la cita per numero» — e la matrice di copertura, che sarebbe lo strumento per stabilire quale sia il denominatore giusto, è superata (C6). **Oggi il progetto non ha modo di dire quanta parte di ciò che ha costruito sia coperta.**

Verifica opposta, e questa riesce bene: script eseguito in sessione che estrae tutte le citazioni della forma `NN §x.y.z` da documenti, sorgenti e prove e le risolve contro i punti dei documenti citati.

```
citazioni totali: 2544
citazioni non risolte: 9  (tutte della forma "00 §11", "00 §13"… cioè rinvii a un principio intero)
```

**Nessun riferimento incrociato rotto in 2544 citazioni.** È un risultato notevole e va detto: l'ipotesi «trappole per riferimenti sbagliati» è smentita dai dati per i documenti normativi.

## 3.4 A quale livello si manifestano i difetti noti

Ho censito i difetti significativi documentati e chi li ha trovati per primo. Fonti nella colonna di destra.

| # | difetto | trovato da | riferimento |
|---|---|---|---|
| 1 | il pannello delle azioni congedava la schermata dello scontro | titolare, su dispositivo | S3/P5, `stato-avanzamento.md` r. 33–35 |
| 2 | tessere del deck ad altezza zero, dichiarate e non agganciabili | titolare, su dispositivo | S3, `stato-avanzamento.md` r. 36 |
| 3 | treno di versione 1.0 accidentale: build 3 e 4 mai proposte | titolare, su dispositivo | `memoria-infrastruttura.md` «Terzo problema» |
| 4 | ingresso in campo dell'avversario mai annunciato | sessione, durante la tranche di semplificazioni | `stato-avanzamento.md` r. 49 |
| 5 | annientamento simultaneo sempre a sfavore del giocatore | accertamento chiesto dal titolare | P6, `stato-avanzamento.md` r. 60 |
| 6 | fanteria pesante bersaglio migliore del campo | misura, su domanda del titolare | `resa-del-conto.md` parte prima |
| 7 | soglia di resa dell'avversario irraggiungibile | misura (fase C) | `valori-provvisori.md` r. 50, 03 §10.6 |
| 8 | ritirata riuscita raccontata come annientamento | **programma di verifica** | P8 |
| 9 | l'ordine dei turni decide l'esito in 21 casi su 24 | misura, su domanda del titolare | RDA-60, `stato-avanzamento.md` r. 92 |
| 10 | nota per i tester oltre i 4000 caratteri | rifiuto dell'API, due volte | `memoria-infrastruttura.md` «Quarto problema» |
| 11 | il registro non aveva contenuto | chi ha usato il gioco | S8 |
| 12 | il testo del registro invisibile (contrasto 1,68:1) | sessione, misurando i pixel | S8, `note-di-rilascio.txt` |
| 13 | l'ordine che chiudeva la giornata non si annullava | accertamento sui numeri chiesto dal titolare | RDA-70, `stato-avanzamento.md` r. 179 |
| 14 | disingaggio valutato nello scambio immediato | **il collaudo**, a cascata su fixture | `stato-avanzamento.md` r. 96 |

**Verdetto sulla premessa dell'incarico.** La premessa è quasi vera e va corretta in un punto. Su quattordici difetti, il collaudo automatico ne ha trovato **uno** (il n. 14) — e l'ha trovato come **rete di regressione durante una modifica voluta**, non come scoperta. Il programma di verifica ne ha trovato **uno** (il n. 8) e ha reso visibili i n. 6, 7 e 9 quando gli è stata posta la domanda giusta. I restanti nove vengono dal titolare che gioca, da chi usa il gioco, o da un rifiuto esterno.

**Verdetto sulla causa proposta dall'incarico.** Sì: le prove operano quasi interamente sotto il livello in cui i difetti si manifestano, ed è misurabile. Ma la formulazione va precisata, perché la spiegazione corretta è più stretta e più utile:

- I difetti 1, 2, 11, 12 si manifestano al livello dell'**interfaccia reale**, dove il progetto ha 2 prove su 261 e nessuna di esse esercita il gioco.
- I difetti 6, 7, 8, 9 si manifestano al livello della **partita intera**, cioè nella composizione di regole ciascuna delle quali è provata per conto proprio. `resa-del-conto.md` righe 122–135 lo aveva già diagnosticato con precisione («Sono tutti una situazione mai costruita… tutti stanno nel punto in cui due cose che avevo provato separatamente si incontrano») e aveva proposto quattro rimedi al §«Che cosa cambio». Ho verificato quali siano stati realizzati: il n. 3 («enumerare le condizioni di fine») e il n. 4 («per ogni misura, provare a farla muovere») lo sono — il secondo è visibile in `stato-avanzamento.md` riga 92, dove la misura viene mossa dimezzando un mazzo prima di fidarsene. Il n. 1 («prove su battaglie intere, non su singole regole») e il n. 2 («un censimento degli annunci») **non lo sono**: nessuna prova gioca una partita intera verificando proprietà dell'esito, e nessuna enumera gli eventi effettivamente emessi in una partita contro quelli esistenti.
- I difetti 3 e 10 si manifestano **fuori dal programma**, su App Store Connect, e sono gli unici due per i quali il progetto ha costruito un controllo che li impedisce di ripetersi (`scripts/carica-testflight.sh` righe 25–70). Sono anche gli unici due che non si sono ripetuti.

---

# 4. La storia, sessione per sessione

## 4.1 Ricostruzione

Fonte: `git log --format='%h|%ad|%s' --date=format:'%Y-%m-%d %H:%M'`, 39 commit dal 2026-08-02 20:54 al 2026-08-05 09:53.

| unità di lavoro | commit | che cosa è stato consegnato | esito noto |
|---|---|---|---|
| Fondazione | `037928e` | documenti di progetto delle fasi 1-4 | — |
| Fase A | `78ac42d`→`029886b` | pacchetto, Dati, Motore, Sessione, giornale, impronta; 40 prove | criterio di uscita superato |
| Revisione del titolare | `0690b58` | perdite sulle sole forze impiegate, divieto di fuoco amico | 44 prove |
| Infrastruttura | `e5f561a`, `8f3f10c` | progetto applicativo, firma, TestFlight, CI | build 1 |
| Fase B | `5709e05`→`cc82bf1` | scontro accessibile completo | 58 prove; **build 3 con due difetti bloccanti** |
| Correttivo dispositivo | `d939bf0` | P5, RDA-50, `LettoreAccessibilita`, `RaggiungibilitaTest` | build 4 |
| Rimessa in ordine versioni | `8789f73`, `8edf8ec`, `e21974f` | regole delle versioni, controllo preventivo | build 5 |
| Semplificazioni | `ca76acc` | cinque semplificazioni (01 v3.3) | build 6; **65 prove** |
| Accertamento scontri | `3fd54b6`, `dd67ee5` | 14 prove nuove, due modificatori (01 v3.4) | build 7; **94 prove**; nota rifiutata (>4000 car.) |
| Limite bersagli | `75a133e` | 01 v3.5, RDA-55/56/57 | build 8; 107 prove |
| Fase C | `bfd9eb3` | programma di verifica, prima taratura (01 v3.6, 03 v2.4) | build 9; 115 prove; **P8 trovato dalla misura** |
| Risoluzione immediata | `71db5e6` | 01 v3.7, RDA-60 | build 10; 115 prove |
| Fase D unità 1 | `123c7a9`→`0d6f43d` | mappa di campagna navigabile | build 11; **189 prove**; quattro numeri sbagliati nel resoconto |
| Accertamento numeri | `fe52cb0`→`3e58fcb` | S6, S7, RDA-70/71; controllo sulla nota | build 12; **204 prove** |
| Fase D unità 2 | `61a90e6`, `6c2829d` | registro, annuncio, confine, costo in giorni | **217 prove**; nota rifiutata di nuovo |
| Dimensionamento | `349ee17` | `impatto-marcia-lunga.md` | — |

Densità: 39 commit e 17 845 righe di Swift aggiunte in 61 ore di calendario.

## 4.2 Divergenze fra richiesto e realizzato

Questo elenco è più corto di quanto dovrebbe, e la ragione è la prima delle mie conclusioni: **gli incarichi non sono conservati, quindi il confronto è possibile solo dove una sessione ha citato l'incarico nel proprio lavoro.** Tutte le voci che seguono hanno per fonte la sessione esecutrice, e sono marcate come **non verificabili in modo indipendente**.

| # | richiesto | realizzato | valutazione |
|---|---|---|---|
| R1 | «la giornata si chiude su comando del giocatore» (RDA-61, citazione dell'incarico) | chiusura automatica, nessun comando di fine giornata | **divergenza volontaria e corretta**: 01 §5.6.0.6 dice il contrario per iscritto, l'incarico vieta di riaprire decisioni prese, 05 §0.3 fa prevalere il consolidato. Dichiarata al titolare in `nota-per-il-titolare-mappa.md` righe 113–122, con il costo del cambio d'idea («mezz'ora»). |
| R2 | «"presidiare" non figura nei documenti» (RDA-77, citazione dell'incarico) | conservato «presidio» | **premessa dell'incarico smentita**: verificata da me, 01 §5.6.8.1 riga 303 contiene «presidio, cioè restare fermi in guardia». Contestazione documentata e giusta. |
| R3 | l'ordine dei propri reparti non contava prima della modifica (presunzione dell'incarico, `stato-avanzamento.md` r. 94) | misurato: contava già, 5 casi su 6 | **presunzione dell'incarico corretta con una misura**. |
| R4 | «dodici cose che non devono mai accadere» (numero proveniente dall'incarico, S6 r. 113) | quindici invarianti nel codice, due senza mutante | **la divergenza è stata riportata nel resoconto come se fosse un risultato**. È il caso più diagnostico di tutto il corpus: vedi §5.A. |
| R5 | «ridurre a un solo percorso» l'annuncio della casella (P12) | ridotto, ma il difetto riferito non era lì | **eseguito alla lettera pur avendo accertato che la premessa non reggeva.** La sessione lo dichiara: «ed è stata comunque eseguita la riduzione a un solo percorso che l'incarico chiedeva». |
| R6 | correggere il registro (unità 2) | corretto, e in più corretto un difetto di contrasto che nessuno aveva chiesto | **consegna maggiore della richiesta**, e il di più è la cosa migliore dell'unità. |

Su sei confronti possibili, **quattro** vedono l'incarico contenere una premessa o un numero sbagliato (R1, R2, R3, R4). In tre casi su quattro la sessione l'ha rilevato e contestato con prove; in uno (R4) l'ha riportato come proprio risultato.

## 4.3 Divergenze fra realizzato e dichiarato

Ho verificato **47 affermazioni fattuali** prese dai documenti di lavoro, ciascuna rieseguendo la misura o leggendo il codice. **Trentatré reggono, quattordici no.** Elenco delle quattordici, con la verifica che le smentisce.

| # | dove | affermazione | verifica |
|---|---|---|---|
| D1 | `stato-avanzamento.md` r. 102, 155 | «Versione dei valori a 0.4.0» | il manifest dice `0.5.0` dal commit `61a90e6`; nessun documento registra il passaggio (L3) |
| D2 | `stato-avanzamento.md` r. 219 | «Chi aggiunge un caso a … `VoceGiornale` DEVE aggiungere il campione: `CompatibilitaGiornaleTest` lo pretende e fallisce altrimenti» | per `VoceGiornale` la prova non fallisce: confronto con un insieme letterale, nessuno `switch` esaustivo (§3.2) |
| D3 | `stato-avanzamento.md` r. 215 | «script Python inline usato in fase A, vedi cronologia git» | contraddetto dalla riga 9 dello stesso documento (C5) |
| D4 | `stato-avanzamento.md` r. 199 e passim | i conteggi delle prove compaiono senza la dichiarazione che `forma-dei-resoconti.md` §«Che cosa NON cambia» punto 1 impone per i numeri non provenienti dal blocco stampato | i conteggi vengono dall'esecutore del collaudo; la dichiarazione manca (P20) |
| D5 | `collaudo-solo-dispositivo.md` r. 87 | «il programma di verifica ne sorveglia gli invarianti su **centosessanta** giornate generate» | `#campagna_riepilogo` stampa `giornate_generate_in_totale,400`. Il numero era già stantio nel commit `fe52cb0` che ha stabilito il 400, ed è sopravvissuto a un secondo aggiornamento del file (`61a90e6`) |
| D6 | `nota-per-il-titolare-mappa.md` r. 68 | «Per adesso [il registro] contiene solo l'apertura delle giornate» | `FattoRegistrato` non ha più `giornataAperta` e ha quattro casi di ordini (S8) |
| D7 | `nota-per-il-titolare-mappa.md` r. 108 | «Le voci del registro non si attivano» | `SchermataRegistro.swift` righe 91–102: le voci con luogo sono `UIButton` che portano il fuoco sulla casella |
| D8 | `nota-per-il-titolare-mappa.md` r. 73 | «Continuando ad annullare si torna indietro di più giornate» | il confine è stato ripristinato (S9, RDA-73): oltre la giornata in corso l'annullamento è rifiutato |
| D9 | `nota-per-il-titolare-mappa.md` r. 64 | «costa 15 gesti con il salto e 109 senza» | la riga corrispondente (`pianura_lunga,raccolti,5`) oggi vale 15 e **106** |
| D10 | `memoria-infrastruttura.md` r. 91 | «Lo snippet è nella cronologia… tenere l'elenco dei file allineato» | superato dalla regola 6 dello stesso file (C5) |
| D11 | `valori-provvisori.md` r. 48 | «ufficiali.json — due parametri TARATI, tre PROVVISORI» | il corpo ne elenca tre e sei, e un decimo parametro non è elencato affatto (L2) |
| D12 | `valori-provvisori.md` r. 76 | «con l'`ufficiale_prova` di fabbrica (tolleranza 0,5, propensione 0,5)…» | i dati odierni sono 0,4 e 0,8 (`ufficiali.json`); il paragrafo è un rilievo storico non marcato come tale, in un elenco che descrive lo stato corrente |
| D13 | `Fondamenta/matrice-di-copertura.md` r. 7 | «01 versione 3.3, 02 versione 2.2, 03 versione 2.1» | 3.7, 2.5, 2.4 (C6) |
| D14 | `Fondamenta/matrice-di-copertura.md` r. 100, 449, 584 | «01 versione 3.2 / 02 versione 2.1 / 03 versione 2.0» | contraddicono l'intestazione dello stesso documento e i file reali (C6) |

### Le trentatré che reggono

Le elenco per specie, perché il fatto che reggano è a sua volta un dato.

- **Conteggi del collaudo**: 217 prove / 1 saltata / 0 fallimenti; 42 ospitate; 2 d'interfaccia. Eseguiti in sessione. ✔
- **Numeri della campagna**: `invarianti_sorvegliati,15`; `giornate_generate_in_totale,400`; `ordini_impartiti_in_totale,2440`; `ordini_a_gruppi_senza_alcuna_destinazione,217`; `violazioni_trovate_in_totale,0`; `costo_in_giorni_dello_scatto,1`. Da `swift run StrumentoVerifica`. ✔
- **Numeri di S6, riverificati nel commit d'origine**. Ho creato un worktree su `3298e86`, eseguito il programma di quella versione e confrontato:
  - «dieci giornate per attraversare la mappa grande»: la sezione `#campagna_attraversamento` di allora stampa `pianura_lunga,dieci,10,10,10`, cioè `distanza_in_caselle` = 10 e `giornate` = 10. ✔ E i nomi delle due colonne erano davvero quelli che S6 dice. ✔
  - «il programma non produceva alcun conteggio di caselle di bordo»: la sezione `#campagna_caselle_raggiungibili` di allora ha la sola colonna `caselle_sotto_quattro` (13, 21, 37) e nessuna colonna di bordo. ✔
  - «il bordo geometrico vale dodici, venti e trentasei; le caselle con meno di quattro uscite tredici, ventuno e trentasette»: la sezione odierna `#campagna_uscite_libere` stampa `caselle_di_bordo` 12/20/36 e `con_meno_di_quattro_uscite` 13/21/37. ✔
  - «quindici gesti contro centonove, riga `pianura_lunga,5`»: al commit `3298e86` quella riga vale `pianura_lunga,5,15,109,94`. ✔ **Il numero era esatto.**
  - «centosessanta giornate e quattrocentoquaranta ordini»: le quattro righe di allora danno 40+40+40+40 = 160 e 80+120+200+40 = 440. ✔ Le somme fatte a mente erano corrette, come S6 dichiara.
  - «centottantanove prove del pacchetto, trentuno ospitate, due d'interfaccia»: conteggio sui sorgenti di quel commit → 189 / 31 / 2. ✔
- **Affermazioni strutturali sul codice**: `@_exported import enum Dati.Parte` in `Esagoni.swift` r. 90 ✔; `VoceGiornale.annullamentoCampagna` porta il confine ✔; `usciteLibere` rinominata ✔; `vociDiCasella` ha esattamente due punti di chiamata, entrambi in `CostruttoreAnnunciCampagna.swift` (r. 59 e 123) ✔; `tendenzaAccerchiamento` è letta in un solo punto, `TatticoBattaglia.swift` r. 109, e governa solo l'ordine delle celle di piazzamento ✔; `FondazioneCampagna.schemaCorrente` = 2 ✔; `Cella` è definita in un solo posto ✔; il pacchetto non espone `Verifica` come eseguibile ✔.
- **Impronte dei manifest**: script eseguito in sessione che ricalcola SHA-256 di ogni file di contenuto e confronta con i manifest → 18 file di valori e 3 di testi, **nessuna divergenza**. La regola 6 della memoria di infrastruttura è rispettata. ✔
- **Guardie che esistono e funzionano**: `campagna_riepilogo` con la prova che ne pareggia i totali col dettaglio (`FumoDelleSimulazioniTest` r. 68) ✔; ciascuno dei quindici invarianti ha il proprio mutante e una prova lo pretende (`InvariantiCampagnaTest`, 15 funzioni `test_mutante_…` più `test_incarico_6_ogni_invariante_ha_almeno_un_mutante…`) ✔; il confine dell'annullamento sopravvive alla ripresa (`AnnullamentoGiornataTest` r. 203) ✔; `carica-testflight.sh` si ferma davvero se una prova fallisce, per `set -euo pipefail` ✔.
- **Riferimenti incrociati**: 2544 citazioni, 0 rotte. ✔
- **Determinismo fra processi**: due corse separate, 460 righe identiche. ✔

### Dove le discrepanze si concentrano

Questa è la parte che l'incarico chiede e che i dati permettono di stabilire. Non ho potuto misurare la posizione dentro un resoconto (i resoconti non esistono più). Ho misurato la concentrazione per documento e per tipo.

**Per documento** (affermazioni verificate / non reggono):

| documento | verificate | non reggono | quota |
|---|---|---|---|
| `nota-per-il-titolare-mappa.md` | 4 | 4 | **100 %** |
| `Fondamenta/matrice-di-copertura.md` | 2 | 2 | **100 %** |
| `valori-provvisori.md` | 4 | 2 | 50 % |
| `collaudo-solo-dispositivo.md` | 2 | 1 | 50 % |
| `memoria-infrastruttura.md` | 4 | 1 | 25 % |
| `stato-avanzamento.md` | 20 | 4 | 20 % |
| `registro-scostamenti.md` | 11 | 0 | **0 %** |

**La concentrazione è netta e va nella direzione opposta a quella che ci si aspetterebbe.** Il documento più tecnico e più denso di numeri — `registro-scostamenti.md`, che contiene S6, cioè l'autocritica sui numeri — regge per intero, e regge anche a una riverifica eseguita nel commit d'origine. Il documento che sbaglia su tutto è quello scritto in linguaggio semplice per il titolare.

**Per tipo di affermazione**: sette delle quattordici sono **numeri**; tre sono **descrizioni del comportamento corrente** in prosa non tecnica; due sono **istruzioni di procedura superate**; una è un'affermazione su **che cosa una prova garantisce**; una è una **voce mancante da un registro che dichiara di essere completo**.

**Per momento**: nessuna delle quattordici è stata introdotta da un errore di misura. Undici su quattordici sono **affermazioni che erano vere quando furono scritte** e che nessuno ha riverificato quando il mondo è cambiato sotto di esse. Le tre che erano false all'origine sono D2 (la guardia su `VoceGiornale`), D11 (i due numeri dell'intestazione di `valori-provvisori.md`) e D14 (le versioni interne della matrice).

**Questo è il risultato empirico centrale di questo esame.** Il progetto non ha un problema di misura: ha un problema di *manutenzione differenziale*. I documenti che una sessione riapre a ogni unità restano veri; i documenti che nessuno riapre marciscono; e il documento che nessuno riapre mai è precisamente quello che il titolare legge.

## 4.4 Prescrizioni verificate

Ho verificato **30 prescrizioni** (obblighi scritti nei documenti) contro la loro realizzazione. **Quindici eseguite pienamente, quattro in parte, nove non eseguite, due non eseguite ma dichiarate come scostamento.**

Eseguite: confini fra bersagli, divieto di stringhe utente nel codice, divieto di virgola mobile nel Motore, regole di dipendenza, validazione dei file di fabbrica e respinte volute, fumo delle simulazioni nel collaudo, programma di verifica separato, rigenerazione delle impronte, versione di marketing ferma, blocco unico dei numeri (RDA-71), annullamento e azzeramento per ogni budget, chiusura automatica della giornata contro la lettera dell'incarico, salvataggi versionati e rifiutati, scenari dichiarativi sostituibili, uniformità fra i due piani.

In parte: troncamento e minimi provati per esempio e non «per proprietà» come 05 §14.2 prescrive; riproduzioni d'oro senza quella di campagna; la prova «elementi non ricreati dopo un annullamento» esiste come ospitata e non d'interfaccia, e per la sola mappa; i tre formati realizzati con il quarto in sospeso (S5).

Non eseguite: C4 (CI locale che copre tutto), L4 in tre punti (sorveglianza delle fonti del caso, riproduzione incrociata iOS/macOS, oro di campagna), C3 (pannello di conferma), C6 (aggiornamento della matrice), L2 (elenco completo dei valori provvisori), C2 (divieto degli ordini nel registro), D4 (dichiarazione dei numeri non provenienti dal blocco).

Dichiarate come scostamento: S4 (mappe in albero piatto invece che per fronte), S2 (designazione pendente nella schermata invece che nello stato). **Sono le due sole deviazioni per le quali il progetto ha fatto tutto ciò che la propria disciplina prescrive.**

---

# 5. Ipotesi sulla causa

Ne ho formulate otto prima di valutarne una. Per ciascuna: che cosa la sosterrebbe, che cosa la smentirebbe, e che cosa la ricerca ha trovato.

## A — La forma degli incarichi

**Enunciato.** Gli incarichi contengono premesse di fatto e numeri che la sessione non è chiamata a verificare, e che il resoconto restituisce come propri risultati.

**Prova a sostegno.** Ci sarebbe se si trovassero casi in cui un errore del resoconto ha per origine il testo dell'incarico. **Trovata, e in forma esplicita.** `registro-scostamenti.md` riga 113: «Gli invarianti sorvegliati erano quindici, non dodici: **avevo contato le voci dell'incarico invece dei casi dell'enumerativo**». L'incarico prescriveva dodici invarianti; il codice ne realizza quindici; il resoconto ha riportato dodici. Poi: R1 (l'incarico contraddiceva 01 §5.6.0.6), R2 (l'incarico affermava che «presidio» non fosse documentato: verificato falso da me), R3 (l'incarico presumeva che l'ordine dei reparti non contasse: smentito dalla misura), R5 (l'incarico chiedeva una riduzione fondata su un difetto non riproducibile, ed è stata eseguita lo stesso).

Quattro su sei confronti disponibili vedono l'incarico contenere una premessa o un numero sbagliato.

**Prova a smentita.** Ci sarebbe se le discrepanze si distribuissero uniformemente anche dove nessun incarico è coinvolto. **Trovata in parte**: undici delle quattordici discrepanze del §4.3 nascono da manutenzione mancata, non da incarichi.

**Esito.** **Sostenuta per gli errori di dichiarazione più gravi, insufficiente per la maggioranza.** L'ipotesi spiega bene il caso peggiore — il numero sbagliato che nessuno aveva contestato — e male il resto. Il meccanismo preciso vale la pena di enunciarlo: un incarico che contiene una quantità («dodici cose che non devono mai accadere») trasforma il resoconto in una conferma della richiesta invece che in una misura della consegna. È l'unica delle otto ipotesi che indichi una leva fuori dalla mia portata.

## B — La struttura della documentazione consente di citare una regola invece di verificarla

**Enunciato.** Il corpus è così esteso e così ben indicizzato per numero che citare un punto costa niente e verificarlo costa molto, e la citazione passa per verifica.

**Prova a sostegno.** Ci sarebbe se si trovassero citazioni copiose ma sbagliate. **Non trovata: smentita dai dati.** 2544 citazioni `NN §x.y.z` nei documenti, nei sorgenti e nelle prove, e **nessuna punta a un punto inesistente**. Le citazioni sono corrette. Ho controllato a campione anche il contenuto (01 §5.6.8.1 elenca davvero sedici azioni e le ho contate; 01 §5.17.1 dice davvero ciò che S8 gli attribuisce; 02 §9.2.1 prescrive davvero il pannello di conferma).

**Prova a smentita.** Trovata come sopra.

**Esito.** **Smentita nella forma proposta.** Il problema non è che le citazioni siano false: è che sono corrette e **il documento citato è vecchio** (C1). Una citazione corretta a 01 §5.17.1 oggi porta a una regola che il codice viola per decisione presa. L'ipotesi va riformulata così, e in questa forma è sostenuta.

## C — La collocazione delle prove

**Enunciato.** Le prove stanno sotto il livello in cui i difetti si manifestano.

**Prova a sostegno.** Ci sarebbe se il censimento dei difetti mostrasse che il collaudo non ne trova, e la distribuzione delle prove mostrasse perché. **Trovata, e misurata due volte.** 217 prove su 261 (83 %) sotto l'interfaccia; 2 (0,8 %) sull'interfaccia reale, e nessuna di quelle due esercita il gioco. Su quattordici difetti significativi il collaudo ne ha trovato uno, come rete di regressione.

E il fatto decisivo che nessun documento registra: **le 44 prove di livello applicativo non girano in integrazione continua né prima di un caricamento** (C4). Non sono un cancello per nulla.

**Prova a smentita.** Ci sarebbe se i difetti si fossero manifestati al livello dove le prove sono dense. Non trovata: nessuno dei quattordici è un errore di regola isolata, che è ciò che 109 prove del `MotoreTest` verificano.

**Esito.** **Fortemente sostenuta**, con una precisazione che la rafforza: il difetto non è che le prove *manchino* al livello giusto, ma che il progetto abbia *creduto* di averle. `LettoreAccessibilita` e le 42 prove ospitate sono state costruite proprio per chiudere quel livello; sono un modello dell'interfaccia scritto dalla stessa mano che scrive l'interfaccia, e non girano automaticamente. `collaudo-solo-dispositivo.md` esiste appunto per elencare ciò che resta scoperto, ed è onesto — ma è un elenco di cose da fare a mano, in un progetto che ha dimostrato di saper trasformare una regola in un controllo quando ci tiene (`carica-testflight.sh`).

## D — La dimensione o la struttura del lavoro per sessione

**Enunciato.** Il resoconto si scrive quando la finestra è più carica e la memoria del proprio operato meno accessibile, quindi le discrepanze si concentrano alla fine.

**Prova a sostegno.** Ci sarebbe se le discrepanze fossero nelle sezioni finali dei resoconti o nelle sessioni più lunghe. **Non verificabile**: i resoconti non sono conservati (§0, limite 2). Non riempio il vuoto.

Ciò che ho potuto misurare è un surrogato: se l'ipotesi valesse, le discrepanze dovrebbero concentrarsi nei documenti scritti per ultimi in una sessione. Il risultato **va nella direzione opposta**: `registro-scostamenti.md`, che è il documento più tecnico e più tardivo, regge 11 affermazioni su 11; `nota-per-il-titolare-mappa.md`, che è scritto per il titolare e non è più stato riaperto, sbaglia 4 su 4.

**Esito.** **Non verificabile nella forma proposta; il surrogato disponibile non la sostiene.** Ciò che il surrogato sostiene è un'ipotesi diversa, la G.

## E — Caratteristiche di questo dominio

**Enunciato.** Il criterio di correttezza è una frase pronunciata e non un valore calcolato, quindi ogni requisito è verificabile solo per constatazione umana.

**Prova a sostegno.** Ci sarebbe se i difetti si concentrassero dove il criterio è una frase. **Trovata in parte.** I difetti 1, 2, 11, 12 riguardano tutti la resa percettiva (un elemento non agganciabile, un testo invisibile, un registro senza contenuto). `collaudo-solo-dispositivo.md` elenca otto verifiche possibili solo sul dispositivo, e la prima è «la lettura come la pronuncia la voce».

**Prova a smentita.** Ci sarebbe se difetti gravi si trovassero anche dove il criterio è numerico. **Trovata, e pesante.** I difetti 6, 7, 8, 9 sono tutti numerici e tutti scoperti tardi: la soglia di resa dell'avversario valeva 1,0 delle forze impiegate, cioè era irraggiungibile, ed è stata scoperta in fase C; l'ordine dei turni decideva l'esito in 21 casi su 24 e nessuna prova lo aveva mai chiesto. `resa-del-conto.md` riga 141 lo dice con esattezza: «C'era una verifica di una riga che avrebbe smascherato tutto: scambiare l'ordine dei turni e guardare se il risultato si ribalta… Non l'ho mai fatta.»

**Esito.** **Parzialmente sostenuta, e insufficiente da sola.** Il dominio spiega perché una classe di difetti non sia automatizzabile; non spiega perché la classe automatizzabile sia stata scoperta con lo stesso ritardo. E soprattutto: il progetto ha inventato il rimedio giusto (misurare i pixel disegnati, `RegistroVisibileTest`) e l'ha applicato a una schermata sola.

## F — L'autorità citabile della carta dei principi

**Enunciato.** Un corpus vincolante e citabile offre un'autorità cui appellarsi al posto di una verifica.

**Prova a sostegno.** Ci sarebbe se si trovassero decisioni giustificate da una citazione senza misura. **Cercata e non trovata nella forma forte.** Al contrario, il corpus mostra il comportamento opposto in punti visibili: RDA-61 sceglie contro la lettera dell'incarico e argomenta; RDA-77 verifica la premessa dell'incarico e la smentisce con la riga esatta; P12 misura la stringa su tutte le caselle di tre mappe e tre livelli di verbosità prima di dichiarare non riprodotto un difetto riferito; `valori-provvisori.md` riga 7 stabilisce che «un valore si toglie da questo elenco soltanto quando una sua misura esiste ed è riportata nel documento 03; non si toglie mai perché è parso ragionevole», e la disciplina è rispettata in nove casi su dieci (L2 è il decimo).

**Prova a smentita.** Trovata come sopra.

**Esito.** **Smentita.** Vale la pena dirlo chiaramente perché è un'ipotesi che suona bene: il progetto non usa i principi come scudo. Li usa come vincolo, e in almeno tre occasioni documentate ha scelto contro la comodità per rispettarli.

## G — Manutenzione differenziale della documentazione

**Enunciato.** I documenti che una sessione deve riaprire per fare il proprio lavoro restano veri; quelli che nessuno deve riaprire marciscono; e la marcatura è invisibile perché nessun documento dichiara la propria data di validità.

**Prova a sostegno.** Ci sarebbe se la quota di affermazioni false correlasse con la frequenza di aggiornamento. **Trovata, con correlazione netta.**

| documento | commit che lo toccano su 39 | affermazioni false su verificate |
|---|---|---|
| `registro-scostamenti.md` | 11 | 0 / 11 |
| `stato-avanzamento.md` | 17 | 4 / 20 |
| `memoria-infrastruttura.md` | 11 | 1 / 4 |
| `collaudo-solo-dispositivo.md` | 6 | 1 / 2 |
| `valori-provvisori.md` | 8 | 2 / 4 |
| `Fondamenta/matrice-di-copertura.md` | 4 | 2 / 2 |
| `nota-per-il-titolare-mappa.md` | 2 | 4 / 4 |

E la conferma strutturale, che è la più grave: i cinque documenti normativi non sono stati toccati in nessuno degli undici commit della fase D (C1), mentre nelle fasi B e C ogni tranche li incrementava.

**Prova a smentita.** Ci sarebbe se documenti poco toccati risultassero veri. `forma-dei-resoconti.md` e `impatto-marcia-lunga.md` hanno un commit ciascuno e reggono — ma sono di ieri: non hanno ancora avuto il tempo di marcire. `Fondamenta/00` ha un commit su 39 e regge, perché è la fondazione e nulla l'ha mai contraddetta.

**Esito.** **Fortemente sostenuta.** È l'ipotesi con il sostegno quantitativo più forte, ed è quella che rende conto della distribuzione osservata.

## H — Asimmetria fra ciò che il titolare può controllare e ciò che viene mantenuto

**Enunciato.** Il titolare non legge il codice e non esegue le prove. Ciò che può controllare è: il gioco sul dispositivo, i numeri di un resoconto, e i documenti scritti per lui. Il progetto mantiene con cura i documenti che servono a sé (registro degli scostamenti, decisioni architetturali, avanzamento) e non mantiene quelli che servono a lui.

**Prova a sostegno.** Ci sarebbe se i documenti destinati al titolare fossero i più stantii. **Trovata, ed è il risultato più netto di questo esame.** `nota-per-il-titolare-mappa.md`: due commit su trentanove, mai aggiornato dopo `fe52cb0`, quattro affermazioni su quattro false rispetto al codice odierno — e in testa reca «Da leggere prima di provare la build nuova». Il titolare che oggi seguisse quell'invito leggerebbe che il registro contiene solo le aperture di giornata (falso), che le voci non si attivano (falso), che si può annullare all'indietro senza fine (falso), e un numero che il programma non produce più (106 contro 109).

Per contrasto, `note-di-rilascio.txt` — l'altro documento destinato al titolare e ai tester — ha **quattordici** commit su trentanove, è riscritto a ogni consegna, ed è coerente con il codice. La differenza fra i due non è il destinatario: è che uno **ha un cancello che lo obbliga** (`scripts/carica-testflight.sh` righe 55–70 rifiutano il caricamento se la nota manca o è troppo lunga) e l'altro no.

**Prova a smentita.** Ci sarebbe se anche i documenti interni fossero stantii. Non trovata: `registro-scostamenti.md` regge 11 su 11.

**Esito.** **Fortemente sostenuta**, e complementare alla G: la G dice *che* la manutenzione è differenziale, la H dice *in quale direzione* la differenza cade, e la direzione è la peggiore possibile per la fiducia.

---

# 6. Conclusioni

## 6.1 Che cosa spiega l'andamento osservato

La spiegazione che rende conto sia dei fallimenti sia dei risultati ha tre componenti, e nessuna delle tre da sola basta.

**Prima componente — la manutenzione differenziale, e la direzione in cui cade (ipotesi G e H, sostegno quantitativo forte).**

Undici delle quattordici affermazioni false che ho trovato erano vere quando furono scritte. Il progetto non sbaglia le misure: `registro-scostamenti.md` regge undici affermazioni su undici, comprese quelle di S6 che ho riverificato eseguendo il programma nel commit d'origine, e tutte e sei erano esatte. Il progetto sbaglia a **rileggere ciò che ha scritto quando il mondo cambia**, e sbaglia in modo sistematicamente orientato: i documenti che deve riaprire per lavorare restano veri, quelli che il titolare legge no.

Questo spiega direttamente la discrepanza che l'incarico chiede di spiegare. Il titolare valuta il lavoro su ciò che può controllare. Ciò che può controllare è il gioco sul dispositivo e i documenti scritti per lui. Il primo è quasi sempre giusto (217+42+2 prove verdi, impronte allineate, determinismo verificato fra processi, invarianti con mutanti). I secondi sono al 100 % di errore su quanto ho potuto verificare. **La sfiducia è calibrata sull'unico campione che il titolare può esaminare, ed è un campione avvelenato.**

**Seconda componente — le prove stanno sotto il livello dei difetti, e per giunta non sono un cancello (ipotesi C, sostegno forte).**

Su quattordici difetti significativi il collaudo automatico ne ha trovato uno, come rete di regressione durante una modifica voluta. Il livello in cui si manifestano — interfaccia reale e partita intera — è coperto da 2 prove su 261, nessuna delle quali esercita il gioco, e da un modello dell'interfaccia scritto dalla stessa mano che scrive l'interfaccia. E le 44 prove che vivono a quel livello **non girano in integrazione continua né prima di un caricamento**: `.github/workflows/collaudo.yml` e `scripts/carica-testflight.sh` eseguono entrambi solo `swift test` sul pacchetto.

Questo spiega perché il titolare trovi giocando difetti che il collaudo dichiara assenti, e perché ciò accada ripetutamente pur crescendo il numero delle prove da 40 a 217.

**Terza componente — gli incarichi trasportano fatti che nessuno verifica, e non sono conservati (ipotesi A, sostegno puntuale ma sul caso peggiore).**

Su sei confronti fra richiesto e realizzato, quattro vedono l'incarico contenere una premessa o un numero sbagliato. In tre casi la sessione l'ha rilevato e contestato con prove (R1, R2, R3) — ed è esattamente il «rovescio» che l'incarico chiede di spiegare insieme al resto. Nel quarto (R4) l'ha riportato come proprio risultato, ed è l'errore che ha innescato tutta la crisi di fiducia. E poiché gli incarichi non sono conservati, **quel confronto non può essere rifatto da nessuno**: né io né una sessione futura possiamo dire quante altre volte sia accaduto.

## 6.2 Perché il risultato è altalenante e non uniformemente scadente

Perché le tre componenti agiscono su assi diversi, e su un asse il progetto è forte.

Quando una sessione **misura**, misura bene: `RegistroVisibileTest` misura i pixel disegnati anziché le proprietà degli oggetti e ha il proprio mutante; `InvariantiCampagnaTest` pretende che ciascuno dei quindici invarianti abbia un mutante e la prova è stata vista fallire togliendone uno; P12 confronta la stringa su tutte le caselle di tre mappe in tre livelli di verbosità prima di dichiarare non riprodotto un difetto riferito; RDA-73 colloca il confine dell'annullamento nel giornale con la ragione corretta, che lo stato ricostruito non lo conserverebbe; RDA-77 verifica la premessa dell'incarico e la smentisce con la riga esatta; `stato-avanzamento.md` riga 92 muove una misura dimezzando un mazzo prima di fidarsene.

Quando una sessione **rilegge**, rilegge male, perché nulla la obbliga a rileggere. Le due cose stanno nello stesso commit: `61a90e6` ha prodotto contemporaneamente la prova che misura i pixel (eccellente) e ha lasciato indietro `nota-per-il-titolare-mappa.md` con quattro affermazioni divenute false (pessimo). Non sono due sessioni di qualità diversa: è la stessa sessione che fa bene ciò per cui ha uno strumento e male ciò per cui ha solo una regola.

Questa è la generalizzazione che il progetto stesso ha già scritto due volte e non ha generalizzato: `memoria-infrastruttura.md` riga 93, «una regola si può dimenticare, un controllo no», e il messaggio di commit `3e58fcb`, «È la stessa lezione dell'accertamento sui numeri di questa sessione». In entrambi i casi la lezione è stata applicata al caso singolo (la lunghezza della nota; il blocco `campagna_riepilogo`) e mai alla classe.

## 6.3 Che cosa è insolito di questo progetto rispetto a uno ordinario

Non conosco gli altri sei e non ne ipotizzo nulla. Elenco ciò che è insolito qui, e segnalo quali tratti potrebbero produrre l'effetto osservato.

1. **Il rapporto fra prosa e codice.** 349 479 parole di documentazione contro 16 842 righe di Swift, cioè circa 21 parole per riga. Anche escludendo la ricerca storica restano 182 149 parole, cioè 11 per riga. *Potenzialmente causale*: il corpus minimo che una sessione deve tenere per essere in regola supera le 120 000 gettoni prima di aprire un file di codice.
2. **La densità temporale.** L'intero progetto ha 61 ore di calendario e 39 commit; 17 845 righe di Swift aggiunte. *Potenzialmente causale*: la manutenzione differenziale ha bisogno di tempo per essere notata, e qui la documentazione invecchia in ore.
3. **Il criterio di accettazione ultimo non è calcolabile.** `collaudo-solo-dispositivo.md` riga 91 lo dichiara: «Una persona che non vede si fa un'immagine mentale della mappa?… Il programma di verifica non può rispondere, e nessuna misura lo potrà mai.» *Potenzialmente causale*, ma insufficiente da sola (§5.E).
4. **Il committente è l'unico collaudatore al livello che conta.** `00 §16.3` prevede tester non vedenti reali; il gruppo esiste su TestFlight ma i ritorni documentati vengono dal titolare e da «chi ha usato il gioco» (S8). *Potenzialmente causale*: ogni difetto di quel livello arriva come lamentela e non come prova rossa.
5. **Sei fonti di autorità di cui una non è scritta.** §L1. *Potenzialmente causale*: le decisioni prese a voce dal titolare non hanno una sede, e quindi ogni sessione le trova solo se qualcuno le ha ricopiate in un documento di lavoro.
6. **I documenti superati restano nella cartella e sono versionati.** 72 punti numerati con due risposte contraddittorie. *Potenzialmente causale*, e finora non ha ancora prodotto un danno che io possa documentare.
7. **La documentazione è il prodotto principale in volume, ma non è collaudata.** Il codice ha 261 prove; la documentazione ne ha zero. L'unico controllo automatico che tocca un documento è quello sulla lunghezza di `note-di-rilascio.txt`, ed è anche l'unico documento non tecnico che regge. *Fortemente causale*: è la spiegazione di 6.2 in una riga.

## 6.4 Che cosa resta inspiegato

Lo dichiaro tale e non lo riempio.

- **Se le discrepanze si concentrino nelle sezioni finali dei resoconti o nelle sessioni più lunghe.** I resoconti non sono conservati. Il surrogato che ho potuto misurare (concentrazione per documento) va nella direzione opposta, ma non è la stessa domanda.
- **Quante affermazioni false siano state consegnate e mai scoperte prima di questa sessione.** Ne ho trovate quattordici verificandone quarantasette. Non ho verificato tutto il corpus: 47 su un corpus di 182 149 parole di documentazione operativa è un campione, e l'ho scelto privilegiando le affermazioni verificabili in modo meccanico. **Il tasso trovato — 14 su 47, cioè il 30 % — non va generalizzato**, perché il campione è distorto verso ciò che si poteva controllare.
- **Se il difetto riferito su P12 esistesse.** La sessione che l'ha cercato ha misurato la stringa esatta che VoiceOver legge, su tutte le caselle di tre mappe e nei tre livelli di verbosità, con zero divergenze, e ha dichiarato che resta possibile che la condizione dipendesse da uno stato non raggiunto. Non ho nulla da aggiungere: la ricerca era condotta bene e la conclusione onesta.
- **Perché la disciplina di incrementare i consolidati sia stata praticata senza eccezioni per cinque tranche e abbandonata di colpo all'inizio della fase D.** Il fatto è misurato (C1) e la data è precisa (`a05756a`, 08-04 19:58). La causa non è nei dati: potrebbe essere la forma degli incarichi di fase D, la percezione che la campagna fosse ancora sperimentale, o la semplice omissione. Non lo so.
- **Se il progetto sia davvero peggiore delle proprie premesse.** L'incarico chiede di non assumerlo. I dati che ho raccolto non lo sostengono nella forma in cui è posto: il codice regge alle verifiche, le prove sono verdi, le impronte allineate, il determinismo verificato, gli invarianti mutati, e le sei affermazioni numeriche di S6 riverificate nel commit d'origine erano tutte esatte. Ciò che è peggiore delle premesse è la **documentazione destinata al titolare**, ed è peggiore in modo misurato. La premessa dell'incarico va quindi ristretta, non respinta: non «questo progetto produce lavoro peggiore», ma «questo progetto produce **resoconti al titolare** peggiori di quanto il lavoro sottostante meriti».

---

# 7. Conseguenze operative

Elenco di interventi possibili con la portata stimata. Senza programma, senza priorità, senza ordinamento.

**Sulla documentazione destinata al titolare**
- Marcare `nota-per-il-titolare-mappa.md` come superata, o riscriverla per la build corrente. Mezz'ora.
- Introdurre in ogni documento non tecnico una riga di validità («vale per la build N»), che renda visibile la marcatura invece di lasciarla dedurre. Un'ora per tutti.
- Estendere il cancello che già esiste per `note-di-rilascio.txt` (rifiuto al caricamento) a un controllo che verifichi che ogni `nota-per-il-titolare-*.md` sia stata toccata nello stesso commit del codice che descrive. Due ore.

**Sulla gerarchia delle fonti**
- Aggiungere a 05 §0.3 il rango dei documenti di lavoro e la disciplina delle deroghe: una deroga vale finché non è recepita o revocata, ed esiste un elenco unico delle deroghe vive. Mezza pagina.
- Recepire in 01 e 02 la deroga S8 (registro degli ordini), oppure revocarla. Una versione nuova per ciascuno.
- Registrare in `registro-scostamenti.md` la mancanza del pannello di conferma della marcia (C3), oggi nominata solo in `impatto-marcia-lunga.md`. Dieci righe.

**Sui documenti superati**
- Togliere `documenti vecchi/` dal versionamento, o premettere a ciascun file una riga di superamento. Cinque minuti.
- Dichiarare superata `Fondamenta/matrice-di-copertura.md`, oppure rigenerarla contro 01 v3.7 / 02 v2.5 / 03 v2.4 / 05 v1.3. La seconda strada è lavoro meccanico su 715 righe.

**Sul collaudo**
- Aggiungere al workflow di integrazione continua e allo script di caricamento l'esecuzione di `WarSenseTest` e `WarSenseUITest`. Verificato eseguibile in questa sessione: circa dieci righe di YAML, tre nello script, 45 secondi di corsa.
- Colmare le tre prescrizioni di 05 §14 non realizzate: sorveglianza delle fonti del caso in `ConfiniTest` (dieci righe), riproduzione d'oro di campagna (un'ora), riproduzione incrociata iOS/macOS (due ore).
- Chiudere il buco di `CompatibilitaGiornaleTest` su `VoceGiornale` con uno `switch` esaustivo, come già esiste per i due tipi di comando. Venti righe; da fare prima dell'unità che introdurrà la revoca, che aggiungerà un caso.
- Estendere la misura del contrasto di `RegistroVisibileTest` alle altre due schermate. Mezz'ora più la definizione dei casi in cui il grigio è corretto.
- Realizzare i due rimedi di `resa-del-conto.md` mai realizzati: prove su partite intere con proprietà dell'esito, e censimento degli eventi effettivamente emessi in una partita contro quelli esistenti. Il secondo avrebbe trovato in un secondo l'ingresso avversario muto, e oggi il codice ha il materiale per farlo (`Significati.swift`, `SignificatiCampagna.swift`).

**Sui valori e sui numeri**
- Iscrivere `ufficiale_prova.propensione_attacco` in `valori-provvisori.md` e correggere l'intestazione che dichiara «due TARATI, tre PROVVISORI». Tre righe.
- Registrare in `stato-avanzamento.md` il passaggio della versione dei valori a 0.5.0 con la ragione, e decidere se `0.4.0` debba restare fra le compatibili. Due righe più una decisione.
- Correggere «centosessanta giornate» in `collaudo-solo-dispositivo.md` riga 87, e la numerazione che salta la voce 8. Due caratteri.
- Estendere `campagna_riepilogo` — o affiancargli un blocco analogo — ai conteggi delle prove, oggi l'unica classe di numeri del resoconto che nessun programma stampa e che `forma-dei-resoconti.md` obbliga quindi a dichiarare a mano. Un'ora, e toglie l'ultima categoria di numeri presi dalla memoria.

**Sugli incarichi**
- Conservare gli incarichi nella cartella, versionati. È l'intervento più economico dell'elenco e il solo che renda possibile, in futuro, l'esame che questa sessione ha potuto fare solo per un sesto. Costo: nulla.
