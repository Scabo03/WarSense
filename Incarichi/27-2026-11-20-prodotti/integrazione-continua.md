# Integrazione continua — le corse dell'incarico 27

Fonte: API di GitHub Actions (`/repos/Scabo03/WarSense/actions/runs`, `/actions/runs/<id>/jobs`, `/actions/jobs/<id>/logs` con le credenziali del portachiavi). I numeri delle prove vengono dai registri delle corse: la riga dell'esecutore (`scripts/conta-prove.sh`, `xcresulttool summary`) e la somma dei fasci di `swift test` (script `conta-pacchetto.py` dell'incarico 27).

## Prima dell'incarico 27

Fra le ultime 44 corse del flusso `collaudo`: 14 verdi e 30 rosse. L'ultima verde è 349ee17 (2026-08-05 07:53 UTC); dal 2026-08-07 05:01 UTC (e33f6cc) tutte rosse, sempre nel passo «Collaudo completo», con l'annotazione «Process completed with exit code 65». I registri di agosto non si leggono più: HTTP 410 (scaduti). Immagine `macos-15`, `actions/checkout@v4` (annotazione: Node 20 deprecato).

## Corsa di riferimento con lo strumentario di agosto

Corsa 44807311981, ramo temporaneo `riferimento-agosto` (f7b2941 più il solo file del flusso `.github/workflows/riferimento-agosto.yml`), immagine `macos-26` (macOS 26.7.2, 25G332), Xcode 26.6 (17F113), Swift 6.3.3, xcodegen 2.46.0 da Homebrew dell'esecutore, iPhone Air iOS 26.5. Uscita del collaudo 65; prove ospitate e d'interfaccia 83, 81 passate, 2 fallite: `AnnunciEFuocoTest/test_00_11_1_elementi_persistenti_e_fuoco_mai_mosso_senza_richiesta` e `AnnunciEFuocoTest/test_00_11_3_esaurimento_del_deck_senza_spostare_il_fuoco` (RDA-143). Durata del passo del collaudo: 20:01:29–20:16:19 UTC. Il ramo temporaneo resta spinto: contiene un commit che non è sul principale, e la regola dei rami (forma-dei-resoconti) ne vieta la cancellazione.

## Sull'immagine nuova, prima della fusione

Corsa 44813874295, evento `pull_request` della richiesta n. 1 (`check-up-strumentario` → `principale`, commit d061164), immagine `xcode-27` (macOS 27.0.1, immagine 20261104.0337.1), Xcode 27.2 (27B52) per percorso, Swift 6.4.2, xcodegen 2.45.4 dalla release con impronta verificata. **VERDE.** Il simulatore dedicato non esisteva sull'esecutore e lo script lo ha creato: «simulatore dedicato CREATO: WarSense iPhone Air (iOS 27.2) 78205458-DD1C-48C6-8C0D-0E21B36A05BA». Pacchetto: 336 eseguite, 0 fallite, 1 saltata, in 6 fasci. Ospitate e interfaccia: 83 eseguite, 83 passate (WarSenseTest 73, WarSenseUITest 10). Controllo dei documenti consegnati: verde. Passo del collaudo 20:43:31–21:00:44 UTC (17 min 13 s, calcolato a mano dagli orari dei passi).

## Dopo le fusioni sul principale

Gli esiti delle corse sugli invii al principale sono riportati nel resoconto dell'incarico 27.
