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

## Certificato riusato e archivio dei certificati

Certificato di distribuzione riusato: «Apple Distribution: Luca Scabini», identificativo App Store Connect JJ47RUK3DJ, serie 16A3013ECFFC07C71BE107D8E7C22CE7, scadenza 30 maggio 2027. È lo stesso già in uso dalle applicazioni scabopdf, click-trivia e lumarlounge. La sua chiave privata è nel portachiavi di accesso di questa macchina (impronta 0C2A8106F7C0914380CA467EAC40E1C9179995AA). L'archivio dei certificati esistente è il repository `https://github.com/Scabo03/scabopdf-certs.git` (gestito con fastlane match dalle altre applicazioni, parola d'ordine nel file di configurazione locale): NON crearne un altro. Questa applicazione non vi aggiunge nulla: riusa il certificato e ha profili propri creati via API.

## Profili creati per questa applicazione

Un solo profilo: «match AppStore com.scabo.warsense», tipo App Store, identificativo 3JN94477B2, creato via API con il certificato JJ47RUK3DJ, installato in `~/Library/MobileDevice/Provisioning Profiles/` e in `~/Library/Developer/Xcode/UserData/Provisioning Profiles/` (file `7a12d714-6ecb-4d91-811f-ea2e532d10b4.mobileprovision`). Se serve ricrearlo o reinstallarlo: `POST /v1/profiles` con pacchetto JC242KLHHW e certificato JJ47RUK3DJ, poi salvare il contenuto decodificato nelle due cartelle. Nessun certificato di sviluppo e nessun profilo di sviluppo: le prove su dispositivo le esegue il titolare via cavo con i propri mezzi.

## Come si carica una build su TestFlight (un solo comando)

```
./scripts/carica-testflight.sh
```

Che cosa fa, nell'ordine: legge le credenziali dal file di configurazione locale; ricava il numero di build interrogando TestFlight (ultimo numero più uno: la regola dei numeri di build, nessuno la aggiorna a mano); esegue l'intero collaudo del pacchetto (`swift test` in `Codice/`) e si ferma se fallisce; rigenera il progetto Xcode con `xcodegen generate` da `Applicazione/project.yml`; archivia (`xcodebuild archive`, configurazione Release, firma manuale con il certificato riusato e il profilo di cui sopra); esporta il pacchetto ipa (`xcodebuild -exportArchive` con `Applicazione/ExportOptions.plist`); carica con `xcrun altool` autenticato con la chiave API; attende l'elaborazione e allega la nota per i tester leggendola da `note-di-rilascio.txt` (se l'attesa scade: `./scripts/nota-testflight.sh <numero>` più tardi).

Numero di VERSIONE (quello di marketing): unica sorgente di verità in `Applicazione/project.yml`, voce `MARKETING_VERSION`. Si cambia lì e da nessun'altra parte. Numero di BUILD: mai scritto a mano, sempre ricavato da TestFlight dallo script.

## Progetto applicativo

`Applicazione/project.yml` è la sorgente di verità del progetto Xcode; `WarSense.xcodeproj` è generato (`xcodegen generate`) ed è comunque versionato per comodità di chi apre Xcode. Requisito minimo iOS 17 (dal documento di architettura), universale iPhone e iPad. Il pacchetto Swift con tutta la logica sta in `Codice/`; il modulo Segnali compila su ogni piattaforma con le parti di sistema dietro compilazione condizionale (registro delle decisioni, RDA-48). La schermata attuale è provvisoria (nome e versione, leggibile da VoiceOver) e viene sostituita nella fase B.

## Dichiarazione sulla crittografia

In `Applicazione/project.yml`, fra le proprietà dell'Info.plist: `ITSAppUsesNonExemptEncryption: false`. Dichiara che l'applicazione non usa cifratura soggetta a controlli sull'esportazione: la domanda sulla conformità non viene posta a ogni caricamento e le build diventano disponibili senza quel passaggio manuale. Se un giorno entrasse della crittografia non esente, quella voce va aggiornata prima del caricamento.

## Integrazione continua

`.github/workflows/collaudo.yml`: a ogni invio sul ramo `principale` e su ogni richiesta di integrazione, compila il pacchetto ed esegue l'intero collaudo, comprese le prove dei confini fra i moduli. NON carica su TestFlight e non firma nulla: il caricamento resta un atto deliberato, eseguito in locale con lo script. Le credenziali non esistono nel repository né nelle impostazioni remote.

## Che cosa deve fare il titolare su App Store Connect

Dopo ogni caricamento: la build compare in TestFlight dopo l'elaborazione (minuti). Per renderla disponibile ai tester: TestFlight → gruppo di tester (interno: disponibile subito; esterno: prima build soggetta a revisione di Apple) → aggiungere la build al gruppo. La nota «cosa provare» è già allegata dallo script.

## Problemi già incontrati e soluzioni

Primo caricamento respinto dalla convalida di Apple con quattro errori: icona mancante (iPhone e iPad), chiave `CFBundleIconName` assente, orientamenti incompleti per il multitasking di iPad. Soluzione: catalogo risorse `Applicazione/Risorse/Immagini.xcassets` con icona singola 1024×1024 (segnaposto blu, da sostituire con l'icona vera), impostazione `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`, e i quattro orientamenti completi in `UISupportedInterfaceOrientations`. Con queste correzioni il caricamento è andato a buon fine (build 1).

La cache dei Bundle dei testi e le altre questioni di codice stanno in `registro-scostamenti.md`; questo file resta dedicato a infrastruttura, firma e distribuzione. Ogni problema nuovo di questa materia va aggiunto qui con la sua soluzione.
