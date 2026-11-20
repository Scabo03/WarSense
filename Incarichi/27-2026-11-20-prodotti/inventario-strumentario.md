# Inventario dello strumentario — incarico 27 (2026-11-20)

Ogni versione porta lo strumento che l'ha prodotta. «Agosto» è lo strumentario con cui è stata costruita la build 27 (caricata il 2026-08-12) e con cui l'incarico 26 ha lavorato fino al 2026-08-13.

## Macchina

| voce | oggi (2026-11-20) | fonte di oggi | agosto | fonte di agosto |
|---|---|---|---|---|
| hardware | MacBook Pro, Apple M5 Pro, 24 GB | `system_profiler SPHardwareDataType` | lo stesso (incarico 26 lo dichiara) | `Incarichi/26-…-incarico.md` |
| macOS | 27.0.1, build 26A434 (Darwin 27.0.0); il titolare la chiama «Golden Gate» | `sw_vers`, `uname -a` | build 25F80, cioè macOS 26.5 (Tahoe) | `BuildMachineOSBuild` nell'`Info.plist` dell'app della build 27, in `Applicazione/build/WarSense.xcarchive` (archivio del 2026-08-12). La corrispondenza 25F80 → 26.5 è DEDOTTA dalla lettera della build (F = 26.5), non letta |
| Xcode installati | uno solo: `/Applications/Xcode.app`, 27.2 (27B52), data del pacchetto 2026-10-30 | `defaults read …/Info CFBundleShortVersionString`, `…/version ProductBuildVersion`, `stat` | 26.6 (17F113) | `DTXcode = 2660`, `DTXcodeBuild = 17F113` nell'`Info.plist` dell'app della build 27 |
| Xcode selezionato | `/Applications/Xcode.app/Contents/Developer` (non toccato) | `xcode-select -p` | non registrato; lo stesso percorso è l'unico citato | — |
| SDK iOS | iphoneos27.2 (24B8118), iphonesimulator27.2 | `xcodebuild -showsdks`, `xcrun simctl runtime match list` | iphoneos26.5 (23F81a) | `DTSDKName`, `DTSDKBuild` della build 27 |
| Swift | 6.4.2 (swiftlang-6.4.2.1.9, clang-2100.4.1.1) | `swift --version` | 6.3.3 (swiftlang-6.3.3.1.3, clang-2100.1.1.101) | intestazione dei `.swiftmodule` in `Codice/.build/arm64-apple-macosx/debug/Modules/` del 2026-08-12 (`strings`), prima che questa sessione cancellasse quella cartella |
| runtime dei simulatori | iOS 27.0 (24A434) e iOS 26.5 (23F77). L'SDK 27.2 preferisce il runtime 24B8118 (iOS 27.2), NON installato | `xcrun simctl runtime list`, `xcrun simctl runtime match list` | iOS 26.5 | gli incarichi 23–25 usano l'iPhone Air 9731754C…, che sta sul runtime 26.5 |
| CoreSimulator | 1174.21 | `xcrun simctl --version` | non registrato | — |
| simulatori dedicati | «WarSense iPhone Air» (C86CB490-B9AE-48E8-BC1B-FDD2C52274B4) e «WarSense iPad Pro 13» (D01FE19F-2594-4B94-98A0-E3F2486DAD1F) su iOS 27.0, creati in questa sessione; in più «WarSense iPhone Air (iOS 26.5, diagnosi)» (9359AE93-F0AE-40AE-973E-2B9F2D545B92) creato per una diagnosi | `xcrun simctl list devices` | nessuno: il collaudo prendeva «il primo iPhone disponibile» | `scripts/collaudo-completo.sh` a f7b2941 |
| applicazione Simulator | ASSENTE: Xcode 27.2 non contiene `Contents/Developer/Applications/` né alcun pacchetto `.app` | `find /Applications/Xcode.app/Contents -name "*.app"` (nessun risultato), `mdfind -onlyin /Applications` | presente in Xcode 26 (`Contents/Developer/Applications/Simulator.app`) | conoscenza generale di Xcode 26, non verificata su questa macchina ad agosto |
| xcodegen | 2.45.4 (Homebrew, installato il 2026-07-06) | `xcodegen --version`, `stat /opt/homebrew/Cellar/xcodegen/2.45.4` | 2.45.4: l'installazione è anteriore ad agosto e non è stata cambiata | data della cartella in `Cellar` |
| xcodegen disponibile | Homebrew (indice locale) 2.46.0; ultima pubblicata 2.48.0 (2026-11-19) | `brew info --json=v2 xcodegen`, API delle release di XcodeGen | — | — |
| Python | 3.9.6, `/usr/bin/python3` → Xcode (`xcrun -f python3` = `/Applications/Xcode.app/Contents/Developer/usr/bin/python3`); `cryptography` 49.0.0 (usata da `scripts/asc_api.py`) | `python3 --version`, `python3 -c "import cryptography"` | non registrato | — |
| gh | NON installato | `which gh` | nessuna traccia d'uso nei resoconti né negli script | `grep` su `Incarichi/` e `scripts/` |
| Claude Code | 2.1.329 | `claude --version` | non registrato | — |
| Homebrew | 6.0.12 | `brew --version` | non registrato | — |
| altool | 27.10.4 (2.2), riscritto: documenta `--upload-package` con `--api-key` e `--api-issuer`; `--upload-app` ancora accettato | `xcrun altool --version`, `--help`, prova con un file inesistente | la versione di Xcode 26.6 (non registrata) | — |

## Integrazione continua

| voce | prima dell'incarico 27 | dall'incarico 27 | fonte |
|---|---|---|---|
| immagine | `macos-15` | `xcode-27` (macOS 27.0.1, immagine 20261104.0337.1; Xcode 27.2 27B52 presente, predefinito 27.1) | `.github/workflows/collaudo.yml`; `images/macos/xcode-27-arm64-Readme.md` di actions/runner-images |
| Xcode | il predefinito dell'immagine | 27.2 per percorso (`DEVELOPER_DIR`) | idem |
| xcodegen | `brew install xcodegen` (versione corrente di Homebrew) | 2.45.4 fissata, archivio della release con impronta SHA-256 verificata | idem |
| `actions/checkout` | v4 (Node 20, segnalato come deprecato dall'esecutore) | v5 | annotazione della corsa 31589551593 |
| esito | ROSSO a ogni invio dal 2026-08-07 (ultima verde: 349ee17, 2026-08-05); 30 corse rosse e 14 verdi fra le ultime 44 | vedi il resoconto | API pubblica di GitHub Actions; i registri di agosto sono SCADUTI (HTTP 410) |

## Firma e distribuzione (sola lettura)

| voce | valore | fonte |
|---|---|---|
| certificato di distribuzione JJ47RUK3DJ | «Apple Distribution: Luca Scabini», serie 16A3013ECFFC07C71BE107D8E7C22CE7, scade 2027-05-30T11:45:13Z | `GET /v1/certificates/JJ47RUK3DJ` |
| chiave privata del certificato | presente e valida nel portachiavi (impronta 0C2A8106F7C0914380CA467EAC40E1C9179995AA, la stessa di memoria-infrastruttura); nel portachiavi ci sono altre due identità «Apple Distribution: Luca Scabini» (serie 7799AFB6…, scade 2027-05-15; serie 23265A33…, scade 2027-04-15), di altre applicazioni, non usate da WarSense | `security find-identity -v -p codesigning`, `security find-certificate -a -Z -p` + `openssl x509` |
| profilo «match AppStore com.scabo.warsense» (3JN94477B2) | ACTIVE, IOS_APP_STORE, UUID 7a12d714-6ecb-4d91-811f-ea2e532d10b4, scade 2027-05-30T11:45:13Z; installato in entrambe le cartelle dei profili | `GET /v1/profiles/3JN94477B2`; `security cms -D` sul file del profilo |
| chiave di App Store Connect | funziona (MGW9GC97HV) | tutte le chiamate qui sopra |
| registro delle build | concorda con i server: 27 build, la più alta è la 27 | `python3 scripts/controlla-build.py` |
| build 23–27 | tutte VALID e tutte SCADUTE (`expired: true`): la 27 è scaduta il 2026-11-10 | `GET /v1/builds?filter[app]=6797306323&sort=-uploadedDate` |
| gruppo di test | «WarLab», interno, `hasAccessToAllBuilds: true` | `GET /v1/apps/6797306323/betaGroups` |
