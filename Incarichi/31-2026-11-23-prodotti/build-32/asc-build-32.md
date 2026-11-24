# Build 32 su App Store Connect — verifica per API (incarico 31)

Comando: `RADICE_SCRIPTS=scripts python3 Incarichi/31-2026-11-23-prodotti/build-32/verifica_asc.py 32`, con le credenziali di `~/Developer/private_keys/scabo_deploy.env` caricate nell'ambiente e mai stampate; lo script è quello dell'incarico 30, copiato qui. Uscita intera in `verifica-asc-uscita.txt`, presa alle 08:29 del 24 novembre 2026, un minuto dopo la fine del caricamento.

| build | stato | caricata | scaduta | treno |
|---|---|---|---|---|
| 32 | VALID | 2026-11-23T23:27:15-08:00 | False | 1.1.0 |
| 31 | VALID | 2026-11-22T14:35:32-08:00 | False | 1.1.0 |
| 30 | VALID | 2026-11-21T12:42:06-08:00 | False | 1.1.0 |

Build 32, dettaglio beta: internalBuildState IN_BETA_TESTING, externalBuildState READY_FOR_BETA_SUBMISSION, autoNotifyEnabled True.
Nota per i tester (it): 3993 caratteri; uguale a `note-di-rilascio.txt`: True (il file ne conta 3994 col ritorno a capo finale).
Gruppo «WarLab»: interno True, hasAccessToAllBuilds True.

`scripts/controlla-build.py`, dopo il caricamento: «registro e App Store Connect concordano: 32 build, la più alta è la 32».

Riga del registro scritta dallo script: `| 32 | 2026-11-24 07:27:15 | 1.1.0 | `7033195` | scritta dallo script al caricamento |`.

Il caricamento (`scripts/carica-testflight.sh` da `principale` a `7033195`): uscita 0 in 610 s (`date +%s` attorno al comando), col collaudo completo ripetuto dentro (143 prove fra ospitate e d'interfaccia, 143 passate) sul simulatore primario di WarSense. Registro filtrato in `caricamento-32.txt`.

Il codice della build: `7033195` ha gli stessi sorgenti del pacchetto e dell'applicazione di `b0a15f2` (`git diff --stat b0a15f2 7033195 -- Codice/Sources Applicazione/Sorgenti`: vuoto).

Firma: manuale (`CODE_SIGN_STYLE: Manual` in `Applicazione/project.yml`, `signingStyle` `manual` in `Applicazione/ExportOptions.plist`); lo script non contiene `-allowProvisioningUpdates` (`grep -c`: 0). Nessun certificato e nessun profilo creato, revocato o modificato in questa sessione.

Non verificato: l'installazione della build su un apparecchio da TestFlight.
