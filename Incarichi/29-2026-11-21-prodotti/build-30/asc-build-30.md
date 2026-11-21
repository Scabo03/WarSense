# Build 30 su App Store Connect — verifica per API (incarico 29)

Comandi: `RADICE_SCRIPTS=scripts python3 Incarichi/29-2026-11-21-prodotti/build-30/verifica_asc.py 30` (con le credenziali di `~/Developer/private_keys/scabo_deploy.env`: `GET /v1/builds?filter[app]=6797306323&limit=3&sort=-uploadedDate&include=preReleaseVersion`, `/v1/builds/<id>/buildBetaDetail`, `/v1/builds/<id>/betaBuildLocalizations`, `/v1/apps/6797306323/betaGroups`); `python3 scripts/controlla-build.py`. Il 2026-11-21 alle 21:43, subito dopo il caricamento.

| build | stato | caricata | scaduta | treno |
|---|---|---|---|---|
| 30 | VALID | 2026-11-21T12:42:06-08:00 | False | 1.1.0 |
| 29 | VALID | 2026-11-21T05:05:58-08:00 | False | 1.1.0 |
| 28 | VALID | 2026-11-20T14:03:12-08:00 | False | 1.1.0 |

Build 30, dettaglio beta: internalBuildState IN_BETA_TESTING, externalBuildState READY_FOR_BETA_SUBMISSION, autoNotifyEnabled True.
Nota per i tester (it): 2930 caratteri; uguale a note-di-rilascio.txt: True
Gruppo «WarLab»: interno True, hasAccessToAllBuilds True

`controlla-build.py`: «registro e App Store Connect concordano: 30 build, la più alta è la 30».

Riga del registro scritta dallo script: `| 30 | 2026-11-21 20:42:06 | 1.1.0 | `402a9b1` | scritta dallo script al caricamento |`.

Il caricamento (`scripts/carica-testflight.sh` da `principale` a 402a9b1): uscita 0 in 546 s (`date +%s` attorno allo script); registro filtrato in `caricamento-30.txt`, il registro intero era fuori da `Applicazione/build` e quindi è sopravvissuto alla cancellazione della cartella.
