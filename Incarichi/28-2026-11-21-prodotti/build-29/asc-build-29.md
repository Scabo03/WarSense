# Build 29 su App Store Connect — verifica per API (incarico 28)

Comandi: `python3 scripts/asc_api.py GET "/v1/builds?filter[app]=6797306323&limit=3&sort=-uploadedDate&include=preReleaseVersion"`, `GET /v1/builds/<id>/buildBetaDetail`, `GET /v1/builds/<id>/betaBuildLocalizations`, `GET /v1/apps/6797306323/betaGroups`; `python3 scripts/controlla-build.py`. Il 2026-11-21, subito dopo il caricamento.

| build | stato | caricata | scaduta | treno |
|---|---|---|---|---|
| 29 | VALID | 2026-11-21T05:05:58-08:00 | False | 1.1.0 |
| 28 | VALID | 2026-11-20T14:03:12-08:00 | False | 1.1.0 |
| 27 | VALID | 2026-08-12T03:52:02-07:00 | True | 1.1.0 |

Build 29, dettaglio beta: internalBuildState IN_BETA_TESTING, externalBuildState READY_FOR_BETA_SUBMISSION, autoNotifyEnabled True.
Nota per i tester (it): 2189 caratteri, uguale a `note-di-rilascio.txt` del commit b8abc93 salvo l'a capo finale.
Gruppo «WarLab»: interno, hasAccessToAllBuilds True.

`controlla-build.py`: «registro e App Store Connect concordano: 29 build, la più alta è la 29».

Il registro dell'esecuzione di `scripts/carica-testflight.sh` NON è conservato: lo avevo rediretto in `Applicazione/build/`, che lo script cancella per intero prima dell'archiviazione (riga `rm -rf "$CARTELLA_BUILD"`); restano l'uscita 0 e la durata, 592 s (`date +%s` attorno allo script), e la riga che lo script ha scritto in `build-caricate.md`.
