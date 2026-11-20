# WarSense — regole per ogni sessione

Le sessioni di Claude Code leggono questo file da sé all'avvio. Contiene soltanto ciò che vale per OGNI sessione; i dettagli stanno in `forma-dei-resoconti.md` e `memoria-infrastruttura.md`, da leggere per intero prima di scrivere un resoconto o di toccare compilazione, firma, repository o TestFlight.

## Il progetto e il titolare

WarSense è un gestionale strategico militare a turni in Swift puro per iOS e iPadOS, utilizzabile per intero senza vedere lo schermo, con VoiceOver. Un solo gioco, due modalità di battaglia: a sciami sulla griglia esagonale e a campioni su due linee. Il titolare decide e non ha competenze tecniche: i resoconti li legge un modello che li verifica; a lui sono destinate soltanto le note scritte per lui. I tester sono persone non vedenti che provano le build su TestFlight.

## I documenti

- `Fondamenta/00-principi-non-negoziabili.md`, la carta dei principi, PREVALE su tutto. Poi i documenti di progetto in `Fondamenta/` (01 gioco, 02 accessibilità, 03 dati, 04 riferimenti storici, 05 architettura tecnica, `modalita-a-campioni.md`), il registro delle decisioni `Fondamenta/registro-decisioni-architetturali.md` e, nella radice, `registro-scostamenti.md`. Se un incarico contraddice un documento consolidato prevale il consolidato, salvo decisione esplicita del titolare: si dichiara citando documento e punto.
- `Incarichi/`: ogni incarico e ogni resoconto, archiviati verbatim con l'indice in `Incarichi/README.md`. La numerazione non si riusa; lo stesso vale per i numeri RDA e S, che prendono il primo libero su QUALUNQUE ramo.
- La cartella `documenti vecchi/` NON si legge.

## Le regole di lavoro stabili

- Piena delega fino al resoconto finale, senza domande, salvo credenziali mancanti e operazioni che potrebbero toccare certificati.
- Ci si ferma prima della fine solo se la capacità della sessione si sta esaurendo davvero, dichiarandolo con il dato che lo mostra e lasciando tutto committato e spinto sul ramo in corso.
- Contano i cancelli che RIFIUTANO, non le prescrizioni scritte: ogni regola nuova che conta diventa un controllo che rifiuta lo stato sbagliato, e ogni cancello nuovo si vede fallire una volta di proposito, con l'uscita riportata.
- Si verifica su partite giocate attraverso l'interfaccia, non soltanto sul Motore.
- Nessuna stringa rivolta al giocatore nel codice (i testi stanno in `Codice/Sources/Contenuti/Testi/`), nessun numero di gioco fuori dai file di dati (`Codice/Sources/Contenuti/Valori/`).
- Riprodurre prima di correggere; misurare prima di tarare.
- Nessun canale che esista per il solo collaudo.
- Nessuna prova indebolita per farla passare.
- Ogni numero porta lo strumento che l'ha prodotto; ciò che non è verificato si dichiara non verificato nel punto in cui compare (`forma-dei-resoconti.md`).
- Non si parla di sicurezza né di privacy: nessuna analisi, avvertenza o proposta su questi temi. Le regole operative sulle chiavi e le credenziali di `memoria-infrastruttura.md` restano in vigore.

## Infrastruttura (dettagli in `memoria-infrastruttura.md`)

- Certificati: MAI crearne, revocarne o modificarne, di nessun tipo; niente firma automatica con `-allowProvisioningUpdates`. I profili si possono ricreare via API.
- Versioni: la versione di marketing (`MARKETING_VERSION` in `Applicazione/project.yml`) sale soltanto e si cambia solo su richiesta esplicita del titolare. La versione dei valori sale quando cambia una regola che incide su una partita in corso (regola 5); quella dei testi resta ferma. Le impronte dei manifest si rigenerano con `python3 scripts/rigenera-impronte.py` a ogni modifica dei Contenuti.
- Numero di build: lo ricava `scripts/carica-testflight.sh` (massimo sull'account più uno), mai a mano. Dopo ogni caricamento si verifica su App Store Connect: valida, sul treno più alto, nel gruppo di test, registro `build-caricate.md` concorde.
- Rami: si lavora su un ramo dedicato, si fonde su `principale` soltanto ciò che è completo e verde, si cancellano i rami fusi.
- Spinta obbligatoria: `principale` e il ramo dedicato si spingono sempre; chiusa la sessione, `git rev-parse principale` deve essere uguale a `git rev-parse origin/principale`.

## Convivenza con gli altri progetti

Sulla stessa macchina girano spesso altri progetti, con le loro sessioni e i loro simulatori: non vanno disturbati. Si lavora soltanto dentro questa cartella e i prodotti di compilazione restano qui (`Applicazione/build/`, `Codice/.build/`). Non si spengono, azzerano, cancellano o riavviano simulatori che non siano di WarSense; nessun comando che agisca su tutti i simulatori insieme; non si chiudono finestre altrui né si terminano processi non propri; non si cambiano impostazioni globali della macchina, compreso lo Xcode selezionato (uno Xcode diverso si indica ai comandi con `DEVELOPER_DIR`); non si aggiornano in blocco strumenti condivisi. I simulatori di WarSense sono «WarSense iPhone Air» e «WarSense iPad Pro 13»: `scripts/simulatore-warsense.sh iphone|ipad` li trova o li crea sul runtime iOS più recente, e ogni script li usa in modo predefinito (`WARSENSE_SIMULATORE` e `WARSENSE_SIMULATORE_IPAD` ne impongono altri).

## La forma della consegna

Chi esamina il lavoro legge il repo remoto.

- Tutto ciò che si produce si committa e si spinge: codice, documenti, resoconto e prodotti delle prove. Nulla che serva all'esame resta solo sulla macchina.
- Il resoconto, in registro tecnico, si archivia in `Incarichi/` con il numero dell'incarico. Non descrive ciò che si legge nel repo: per ogni modifica una riga con il commit e il percorso, nessuna parafrasi dei documenti modificati. Spiega invece per intero ciò che dal repo non si vede: che cosa è successo durante l'esecuzione, che cosa si è visto e sentito sul simulatore, i fallimenti anche risolti e le intermittenze, lo stato su App Store Connect, le versioni della macchina, i tempi, le decisioni prese da soli e perché, ciò che non si è riusciti a fare.
- I prodotti delle prove si consegnano come testo, in una cartella dedicata all'incarico: esiti in testo o JSON, trascrizioni, osservazioni e una selezione di schermate PNG, al massimo una ventina di megabyte; mai i fascicoli grezzi dei risultati.
- In coda al resoconto, separati: ciò che si è fatto senza che fosse chiesto, ciò che era chiesto e non è stato fatto, i tempi per compilazione, collaudo, simulatore, caricamento ed esplorazione.
- Il messaggio finale nel terminale contiene soltanto: se la build è uscita, il commit finale del principale, i rami spinti, e i percorsi del resoconto e della cartella dei prodotti.

## Contraddizioni segnalate, non risolte

- `forma-dei-resoconti.md` («La regola in vigore») vuole le modifiche descritte nel resoconto «in termini di che cosa è cambiato, dove, e quale invariante o requisito ne risulta coperto»; la forma della consegna qui sopra (incarico 27) vuole per ogni modifica una sola riga con commit e percorso, senza parafrasi. Le due regole non sono state conciliate: la decisione spetta al titolare.
