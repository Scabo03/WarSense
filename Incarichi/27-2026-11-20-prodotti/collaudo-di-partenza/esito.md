# Collaudo di partenza — principale f7b2941, senza modifiche, con lo strumentario nuovo

Corsa locale del 2026-11-20, 20:51–20:55: `scripts/collaudo-completo.sh` e poi `scripts/esegui-sessioni-complete.sh`, in sequenza, sul commit f7b2941 con l'albero pulito, `WARSENSE_SIMULATORE` = «WarSense iPhone Air» (C86CB490…, iOS 27.0) — la variabile esisteva già a f7b2941, quindi nessun file del principale è stato toccato. Prodotti di compilazione cancellati prima della corsa (`Applicazione/build/collaudo`, `Applicazione/build/sessioni-complete`, `Codice/.build`), così che tutto fosse compilato dallo strumentario nuovo.

## Esito

| passo | esito | numeri (strumento) |
|---|---|---|
| 0/3 cancello dei simboli | verde | `scripts/verifica-simboli.sh` |
| 0b/3 cancello delle impronte | verde | `rigenera-impronte.py --verifica` |
| 1/3 pacchetto | VERDE | 336 eseguite, 0 fallite, 1 saltata, in 6 fasci (somma delle righe «Test Suite '<fascio>.xctest' passed» di `swift test`, calcolata dallo script `conta-pacchetto.py` di questa sessione): VerificaTest 68, SessioneTest 39 (1 saltata), SegnaliTest 22, MotoreTest 175, DatiTest 28, ConfiniTest 4 |
| 2/3 `xcodegen generate` | verde | xcodegen 2.45.4 |
| 3/3 ospitate e interfaccia | ROSSO (uscita 65) | `xcresulttool get test-results summary`: 11 prove registrate, 0 passate, 11 fallite |
| corsa delle sessioni, 1/2 (144 per l'interfaccia) | ROSSA | stesso arresto |
| corsa delle sessioni, 2/2 (headless) | VERDE | `SessioniCompleteTest` |
| durate | collaudo 186 s, sessioni 46 s | `date +%s` attorno a ciascuno script |

## Che cosa falliva, e perché

Tutto il rosso ha UNA causa, ed è dello strumentario nuovo: l'app non parte. Dal registro dell'app ospite (`StandardOutputAndStandardError.txt` del fascio): «Application failed to launch: UIScene life cycle is required for apps built with this SDK». Il rapporto d'arresto (`WarSense-2026-11-20-205407.ips`) ha `EXC_BREAKPOINT` in `___UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption_block_invoke` (UIKitCore). L'app creava la finestra in `AppDelegate` senza dichiarare scene; con l'SDK di iOS 27 non è più ammesso. Le prove ospitate cadono tutte insieme («The test runner crashed before establishing connection: WarSense»), le prove d'interfaccia una per una («com.scabo.warsense crashed»): sono le 10 di `WarSenseUITest` più la voce unica del fascio `WarSenseTest`.

## Che cosa falliva già (strumentario di agosto)

Riprodotto in integrazione continua con lo strumentario della build 27 (`riferimento-agosto-esito.txt`): su f7b2941, Xcode 26.6 (17F113), Swift 6.3.3, iPhone Air iOS 26.5, il collaudo esce con 65, 81 prove passate su 83. Falliscono `AnnunciEFuocoTest/test_00_11_1_elementi_persistenti_e_fuoco_mai_mosso_senza_richiesta` e `AnnunciEFuocoTest/test_00_11_3_esaurimento_del_deck_senza_spostare_il_fuoco`. Sulla macchina del titolare ad agosto le stesse prove passavano (83 su 83, resoconto 25): è una corsa nei tempi che si manifesta sulla macchina più lenta dell'integrazione continua, ed è con ogni probabilità il rosso di tutte le corse dal 2026-08-07 — i cui registri sono scaduti (HTTP 410), sicché per le corse di agosto è una deduzione e non una lettura.

## Le avvertenze del compilatore

Nessuna avvertenza nuova. L'insieme delle avvertenze uniche (file, riga, messaggio) del collaudo di partenza è CONTENUTO per intero in quello della corsa con lo strumentario di agosto: 64 uniche oggi, tutte presenti ad agosto (`avvertenze-strumentario-novembre.txt`, `avvertenze-strumentario-agosto.txt`; confronto con `comm` sulle righe normalizzate). Con lo strumentario nuovo SPARISCONO tre avvertenze di SwiftPM («'Motore' is missing a dependency on 'Dati'», «'Sessione' is missing a dependency on 'Dati'», «'Sessione' is missing a dependency on 'Motore'»). Le 64 si dividono così (conteggio dello script `avvertenze.py`): 53 «no 'async' operations occur within 'await' expression», 2 «variable … was never mutated», 1 «found 7 file(s) which are unhandled» (risorse di prova di SessioneTest), 1 «immutable value 'repartiStaccati' was never used», 1 «'traitCollectionDidChange' was deprecated in iOS 17.0» (`TesseraDeck.swift:130`), 1 «main actor-isolated static property 'schermoPiccolo' … this is an error in the Swift 6 language mode» (`MappaCampagnaAccessibileTest.swift:19`, bersaglio di prova in modo Swift 5). Non è un'avvertenza del compilatore ma va detto: l'obbligo delle scene non era annunciato da nessuna avvertenza di compilazione, né con Xcode 26.6 né con Xcode 27.2.
