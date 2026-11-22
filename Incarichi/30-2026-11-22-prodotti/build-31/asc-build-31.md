# Build 31 su App Store Connect — verifica per API (incarico 30)

Comando: `RADICE_SCRIPTS=scripts python3 Incarichi/30-2026-11-22-prodotti/build-31/verifica_asc.py 31`, con le credenziali di `~/Developer/private_keys/scabo_deploy.env` (`GET /v1/builds?filter[app]=6797306323&limit=3&sort=-uploadedDate&include=preReleaseVersion`, `/v1/builds/<id>/buildBetaDetail`, `/v1/builds/<id>/betaBuildLocalizations`, `/v1/apps/6797306323/betaGroups`). L'uscita è in `verifica-asc-uscita.txt`:

| build | stato | caricata | scaduta | treno |
|---|---|---|---|---|
| 31 | VALID | 2026-11-22T14:35:32-08:00 | False | 1.1.0 |
| 30 | VALID | 2026-11-21T12:42:06-08:00 | False | 1.1.0 |
| 29 | VALID | 2026-11-21T05:05:58-08:00 | False | 1.1.0 |

Build 31, dettaglio beta: internalBuildState IN_BETA_TESTING, externalBuildState READY_FOR_BETA_SUBMISSION, autoNotifyEnabled True.
Nota per i tester (it): 3969 caratteri; uguale a note-di-rilascio.txt: True
Gruppo «WarLab»: interno True, hasAccessToAllBuilds True

`controlla-build.py`: «registro e App Store Connect concordano: 31 build, la più alta è la 31».

Riga del registro scritta dallo script: `| 31 | 2026-11-22 22:35:32 | 1.1.0 | `7ef91fd` | scritta dallo script al caricamento |`.

Il caricamento (`scripts/carica-testflight.sh` da `principale` a `7ef91fd`, col collaudo interno sul quarto iPhone di WarSense imposto con `WARSENSE_SIMULATORE`): uscita 0 in 581 s (`date +%s` attorno allo script); registro filtrato in `caricamento-31.txt`.

Dopo il caricamento le note di rilascio hanno ricevuto una frase in più (i nomi dei gruppi che si riassegnano a ogni campagna) e sono state riallegate con `scripts/nota-testflight.sh 31`; la verifica ripetuta è in `verifica-asc-dopo-la-nota-aggiornata.txt`: nota di 3995 caratteri, uguale a `note-di-rilascio.txt`, tutto il resto invariato.
