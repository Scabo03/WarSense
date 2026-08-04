# Memoria di infrastruttura, firma e distribuzione

File di memoria permanente del progetto. Ogni sessione futura che tocchi compilazione, firma, repository o TestFlight legge questo file prima di fare qualunque cosa. Istruzioni operative: chi legge fra sei mesi carica una build senza chiedere nulla a nessuno.

## Coordinate del progetto

Nome dell'applicazione: WarSense. Identificativo del pacchetto: com.scabo.warsense. Squadra Apple: D2KQYQ8YU8 (Luca Scabini). Applicazione su App Store Connect: già creata, identificativo interno 6797306323; identificativo di pacchetto registrato JC242KLHHW (universale). Repository remoto: https://github.com/Scabo03/WarSense.git, ramo `principale`. Le credenziali GitHub sono nel portachiavi di sistema (utente Scabo03): `git push` funziona senza configurare nulla.

## Dove stanno le chiavi e come si leggono

Cartella locale, FUORI dal repository: `~/Developer/private_keys/`. Contiene la chiave p8 di App Store Connect (`AuthKey_MGW9GC97HV.p8`) e il file di configurazione `scabo_deploy.env`, che valorizza le variabili d'ambiente usate dagli script: identificativo della chiave, identificativo dell'emittente, percorso della chiave. Gli script la leggono da lì (variabile `WARSENSE_CONFIG` per indicare un percorso diverso). Il contenuto di quei file non si copia MAI dentro il repository, in nessuna forma, nemmeno cifrata. Il file `.gitignore` esclude per sicurezza `*.p8`, `*.env`, `*.mobileprovision` e `private_keys/`.

## VINCOLO ASSOLUTO SUI CERTIFICATI — LEGGERE PRIMA DI QUALUNQUE COMANDO DI FIRMA

Il limite di certificati dell'account è al massimo. Di conseguenza, senza eccezione alcuna:

- NON revocare mai alcun certificato, per nessuna ragione.
- NON creare mai un certificato nuovo, di alcun tipo (né distribuzione né sviluppo).
- NON eseguire mai: `fastlane match nuke` (di qualunque variante), `fastlane match` senza `readonly` se potrebbe generare certificati, `fastlane cert`, comandi dell'API di App Store Connect `DELETE /v1/certificates/...` o `POST /v1/certificates`, revoche dal portale sviluppatori, opzioni di Xcode che promettano di «revocare e rigenerare» o «risolvere i problemi di firma» creando certificati (in particolare la firma automatica con `-allowProvisioningUpdates`, che può tentare di creare certificati: non usarla).
- I PROFILI di distribuzione sono cosa diversa dai certificati e si possono creare e ricreare liberamente (`POST /v1/profiles`).
- In caso di dubbio su che cosa farebbe un comando: non eseguirlo e chiedere.

## REGOLE DELLE VERSIONI E DELLE BUILD — LEGGERE PRIMA DI QUALUNQUE CARICAMENTO

1. **La versione di marketing SALE SOLTANTO e non torna mai indietro**, per nessuna ragione e in nessuna circostanza. Si modifica esclusivamente su richiesta esplicita del titolare del progetto, e in nessun altro caso: non per riordinare, non per allinearla a una fase di sviluppo, non per coerenza con altri numeri, non di propria iniziativa. Unica sorgente di verità: `MARKETING_VERSION` in `Applicazione/project.yml`. Nessun procedimento automatico la tocca, la ricava o la deduce.
2. **Il numero di build si ricava automaticamente** dallo script di caricamento come massimo su TUTTO l'account più uno: è crescente su tutti i treni di versione e **non riparte mai** con una versione nuova. Mai scriverlo a mano.
3. **Perché la regola 1 esiste**: TestFlight propone ai dispositivi come aggiornamento l'ultima build della versione PIÙ ALTA, non l'ultima caricata. Abbassare la versione rende invisibili tutte le build successive, che restano raggiungibili soltanto scendendo a mano nell'elenco delle build precedenti. È precisamente l'errore commesso in questo progetto: il treno accidentale «1.0» (build 1 e 2) sopra lo 0.2.0 ha reso invisibili come aggiornamento le build correttive 3 e 4.
4. **Il caricamento è protetto**: `scripts/carica-testflight.sh` interroga App Store Connect PRIMA di qualunque altra operazione e rifiuta con motivo, senza opzioni per aggirarlo, ogni versione inferiore alla più alta già presente (la parità è ammessa: è il caso normale delle build correttive sullo stesso treno, dove sale solo il numero di build). Il rifiuto è stato provato sul campo il 2026-08-03 (versione 0.3.0 simulata: fermato prima del collaudo, codice d'uscita 1).
5. **Le versioni dei dati** (manifest dei valori e manifest dei testi) seguono la stessa disciplina: si cambiano solo su istruzione esplicita del titolare. ENTRAMBI i manifest portano le impronte dei file (per i testi dal 2026-08-03, RDA-54): è il cambiamento delle impronte a far rinfrescare la copia in Documenti, quindi chi modifica un file in `Contenuti/Valori/` o in `Contenuti/Testi/` DEVE rigenerare le impronte del rispettivo manifest nella stessa modifica (script Python inline, sha256 dei file elencati), a versione ferma. Dimenticarlo significa installazioni con dati o testi stantii.

## Stato di fatto su App Store Connect (aggiornato 2026-08-03)

Convivono tre treni di versione, e NON vanno razionalizzati: la storia è questa. Ordine di caricamento: build 1 e 2 sul treno «1.0» (versione mai scelta: letterale scritto dal generatore per l'assenza dei riferimenti nell'Info.plist); build 3 e 4 sul treno «0.2.0» (la versione voluta della fase B, che però, essendo inferiore a 1.0, non veniva proposta come aggiornamento); build 5 sul treno «1.1.0», identica alla 4 nel contenuto, caricata per riportare gli aggiornamenti sopra il treno accidentale. **La build buona è l'ultima del treno più alto** (dalla 5 in poi); i treni «1.0» e «0.2.0» sono storia congelata: non si riusano, non si cancellano, non si «sistemano». La versione «1.0» non verrà mai più usata: da 1.1.0 si sale soltanto.

## Certificato riusato e archivio dei certificati

Certificato di distribuzione riusato: «Apple Distribution: Luca Scabini», identificativo App Store Connect JJ47RUK3DJ, serie 16A3013ECFFC07C71BE107D8E7C22CE7, scadenza 30 maggio 2027. È lo stesso già in uso dalle applicazioni scabopdf, click-trivia e lumarlounge. La sua chiave privata è nel portachiavi di accesso di questa macchina (impronta 0C2A8106F7C0914380CA467EAC40E1C9179995AA). L'archivio dei certificati esistente è il repository `https://github.com/Scabo03/scabopdf-certs.git` (gestito con fastlane match dalle altre applicazioni, parola d'ordine nel file di configurazione locale): NON crearne un altro. Questa applicazione non vi aggiunge nulla: riusa il certificato e ha profili propri creati via API.

## Profili creati per questa applicazione

Un solo profilo: «match AppStore com.scabo.warsense», tipo App Store, identificativo 3JN94477B2, creato via API con il certificato JJ47RUK3DJ, installato in `~/Library/MobileDevice/Provisioning Profiles/` e in `~/Library/Developer/Xcode/UserData/Provisioning Profiles/` (file `7a12d714-6ecb-4d91-811f-ea2e532d10b4.mobileprovision`). Se serve ricrearlo o reinstallarlo: `POST /v1/profiles` con pacchetto JC242KLHHW e certificato JJ47RUK3DJ, poi salvare il contenuto decodificato nelle due cartelle. Nessun certificato di sviluppo e nessun profilo di sviluppo: le prove su dispositivo le esegue il titolare via cavo con i propri mezzi.

## Come si carica una build su TestFlight (un solo comando)

```
./scripts/carica-testflight.sh
```

Prima di lanciarlo: aggiornare `note-di-rilascio.txt` (la nota per i tester viene letta da lì al momento del caricamento). La versione di marketing NON si tocca: vale la regola 1 in testa a questo file.

Che cosa fa, nell'ordine: legge le credenziali dal file di configurazione locale; **controllo preventivo delle versioni** — interroga App Store Connect e rifiuta con motivo, prima di qualunque altra operazione e senza possibilità di aggiramento, una `MARKETING_VERSION` inferiore alla più alta già presente (regole 3 e 4 in testa al file); ricava il numero di build (massimo su tutto l'account più uno); esegue l'intero collaudo del pacchetto (`swift test` in `Codice/`) e si ferma se fallisce; rigenera il progetto Xcode con `xcodegen generate` da `Applicazione/project.yml`; archivia (`xcodebuild archive`, configurazione Release, firma manuale con il certificato riusato e il profilo di cui sopra); esporta il pacchetto ipa (`xcodebuild -exportArchive` con `Applicazione/ExportOptions.plist`); carica con `xcrun altool` autenticato con la chiave API; attende l'elaborazione e allega la nota per i tester leggendola da `note-di-rilascio.txt` (se l'attesa scade: `./scripts/nota-testflight.sh <numero>` più tardi).

Numero di VERSIONE (quello di marketing): unica sorgente di verità in `Applicazione/project.yml`, voce `MARKETING_VERSION`; disciplina nella sezione delle regole in testa al file. ATTENZIONE tecnica: perché il valore arrivi davvero al pacchetto, l'Info.plist deve dichiarare i RIFERIMENTI e mai valori letterali: `CFBundleShortVersionString: $(MARKETING_VERSION)` e `CFBundleVersion: $(CURRENT_PROJECT_VERSION)` nelle proprietà info di project.yml. Senza, il generatore scrive «1.0» fisso: è così che nacque il treno accidentale delle build 1 e 2.

Numero di BUILD: mai scritto a mano, sempre ricavato dallo script come massimo su tutto l'account più uno, crescente su tutti i treni. Il `CURRENT_PROJECT_VERSION: 1` in project.yml è un segnaposto che lo script sovrascrive a ogni archivio: non aggiornarlo mai a mano. Non lanciare mai due caricamenti in parallelo: il numero si calcola all'inizio e collidrebbe.

VERIFICA DOPO OGNI CARICAMENTO, sempre: build, treno di versione ed elaborazione si controllano dall'esterno con

```
source ~/Developer/private_keys/scabo_deploy.env && export APP_STORE_CONNECT_API_KEY_ID APP_STORE_CONNECT_API_KEY_ISSUER_ID APP_STORE_CONNECT_API_KEY_PATH
python3 scripts/asc_api.py GET "/v1/builds?filter[app]=6797306323&limit=3&include=preReleaseVersion"
```

Non fidarsi dell'esito del solo caricamento: l'errore del treno di versione si vede soltanto da qui.

## Progetto applicativo

`Applicazione/project.yml` è la sorgente di verità del progetto Xcode; `WarSense.xcodeproj` è generato (`xcodegen generate`) ed è comunque versionato per comodità di chi apre Xcode. Requisito minimo iOS 17 (dal documento di architettura), universale iPhone e iPad. Il pacchetto Swift con tutta la logica sta in `Codice/`; il modulo Segnali compila su ogni piattaforma con le parti di sistema dietro compilazione condizionale (registro delle decisioni, RDA-48). Dalla fase B l'applicazione contiene lo scontro accessibile completo; i bersagli di prova del progetto (ospitate e interfaccia) si eseguono con lo schema di test e non entrano nell'archivio.

## Dichiarazione sulla crittografia

In `Applicazione/project.yml`, fra le proprietà dell'Info.plist: `ITSAppUsesNonExemptEncryption: false`. Dichiara che l'applicazione non usa cifratura soggetta a controlli sull'esportazione: la domanda sulla conformità non viene posta a ogni caricamento e le build diventano disponibili senza quel passaggio manuale. Se un giorno entrasse della crittografia non esente, quella voce va aggiornata prima del caricamento.

## Integrazione continua

`.github/workflows/collaudo.yml`: a ogni invio sul ramo `principale` e su ogni richiesta di integrazione, compila il pacchetto ed esegue l'intero collaudo, comprese le prove dei confini fra i moduli. NON carica su TestFlight e non firma nulla: il caricamento resta un atto deliberato, eseguito in locale con lo script. Le credenziali non esistono nel repository né nelle impostazioni remote.

## Che cosa deve fare il titolare su App Store Connect

Dopo ogni caricamento: la build compare in TestFlight dopo l'elaborazione (minuti). Il gruppo attuale «WarLab» è interno con accesso automatico a tutte le build (`hasAccessToAllBuilds: true`, verificato via API il 2026-08-03): ogni build caricata gli arriva DA SÉ, con notifica automatica ai tester — nessuna assegnazione manuale. Solo per eventuali gruppi futuri senza accesso automatico (o esterni, con prima build soggetta a revisione di Apple) serve aggiungere la build al gruppo a mano. La nota «cosa provare» è già allegata dallo script.

## Problemi già incontrati e soluzioni

Primo caricamento respinto dalla convalida di Apple con quattro errori: icona mancante (iPhone e iPad), chiave `CFBundleIconName` assente, orientamenti incompleti per il multitasking di iPad. Soluzione: catalogo risorse `Applicazione/Risorse/Immagini.xcassets` con icona singola 1024×1024 (segnaposto blu, da sostituire con l'icona vera), impostazione `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`, e i quattro orientamenti completi in `UISupportedInterfaceOrientations`. Con queste correzioni il caricamento è andato a buon fine (build 1).

Secondo problema (fase B): la versione di marketing non arrivava al pacchetto. Il generatore di progetto scrive nell'Info.plist valori LETTERALI («1.0» e «1») se le chiavi di versione non sono dichiarate esplicitamente come riferimenti; il numero di build passava (perché imposto dallo script alla riga di comando), la versione no, e le build finivano sul treno «1.0». Soluzione: le due chiavi con i riferimenti `$(MARKETING_VERSION)` e `$(CURRENT_PROJECT_VERSION)` nelle proprietà info di project.yml, e la verifica del treno dall'esterno dopo ogni caricamento (comando qui sopra). Verificata con la build 3, correttamente su 0.2.0.

Terzo problema (seguito diretto del secondo): quella correzione, ripristinando la versione voluta 0.2.0 SOTTO il treno accidentale «1.0», mandò la versione all'indietro. La sessione che la applicò dichiarò il treno «1.0» «bruciato» credendo la convivenza innocua; ignorava che TestFlight propone come aggiornamento l'ultima build della versione più alta, sicché le build correttive 3 e 4 non venivano mai proposte ai dispositivi (restavano visibili solo scendendo a mano nell'elenco delle build precedenti — così le ha trovate il titolare). Soluzione (2026-08-03): versione portata a 1.1.0 con la build 5, regole delle versioni in testa a questo file, e controllo preventivo non aggirabile dentro lo script di caricamento, provato sul campo con un rifiuto reale.

Terzo punto da non dimenticare (non un errore, una regola): ogni volta che si aggiunge o si modifica un file in `Codice/Sources/Contenuti/Valori/` va rigenerato il manifest con le impronte, altrimenti il gioco deriva una versione locale marcata anche per la fabbrica. Lo snippet è nella cronologia (python, sha256 dei file elencati, riscrittura di manifest.json); tenere l'elenco dei file del manifest allineato a ciò che esiste nella cartella.

Quarto problema (build 7): la nota per i tester è stata rifiutata con `409 ENTITY_ERROR.ATTRIBUTE.INVALID.TOO_LONG` su `whatsNew`. App Store Connect accetta al massimo 4000 caratteri per quel campo; la nota ne aveva 4160. Il caricamento della build NON ne risente — era già andato a buon fine — e lo script lo dice, indicando di rieseguire `./scripts/nota-testflight.sh <numero>` più tardi. Soluzione applicata: nota accorciata a circa 3400 caratteri e riallegata con quel comando. Regola pratica: prima di caricare, `wc -m note-di-rilascio.txt` e restare sotto i 4000; conviene stare abbondantemente sotto, perché il limite è sui caratteri e non sui byte.

Nota di protezione già attiva: lo script esegue l'INTERO collaudo del pacchetto prima di archiviare e si ferma se una prova fallisce; non aggirarlo mai. I bersagli di prova del progetto applicativo non entrano nell'archivio (lo schema li dichiara solo per la fase di test), quindi non possono rompere una consegna.

La cache dei Bundle dei testi e le altre questioni di codice stanno in `registro-scostamenti.md`; questo file resta dedicato a infrastruttura, firma e distribuzione. Ogni problema nuovo di questa materia va aggiunto qui con la sua soluzione.
