# Canali per guidare e osservare l'app sul simulatore — accertamento (incarico 27)

Ogni canale è stato provato con una prova minima sul simulatore dedicato «WarSense iPhone Air» (C86CB490-B9AE-48E8-BC1B-FDD2C52274B4, iOS 27.0), con Xcode 27.2. Le sonde stanno in `Applicazione/Esplorazione/SondaCanaliTest.swift`, bersaglio `WarSenseEsplorazione`, schema omonimo: lo schema `WarSense` del collaudo non le esegue. L'uscita integrale della corsa è in `sonde-iphone.txt` accanto a questo file.

## 1. `XCUIDevice.voiceOverService` (iOS 27) — FUNZIONA, con un limite

Dove sta: nel framework `XCUIAutomation` (non in `XCTest`), intestazioni `XCUIVoiceOverService.h`, `XCUIVoiceOverOutput.h`, `XCUIVoiceOverServiceError.h`. In Swift i metodi si chiamano con il nome diretto e lanciano: `enable()`, `disable()`, `isEnabled`, `moveForward()`, `moveBackward()`, `currentSpeech()`, `moveIn()`, `moveOut()`; i quattro di navigazione restituiscono `XCUIVoiceOverService.Output` con la sola proprietà `utterance` (accertato con `swiftc -typecheck` contro l'SDK del simulatore: la forma `__moveForward()` è rifiutata come rinominata).

Esito della sonda `test_sonda_1_servizio_voiceover` (uscita stampata dalla prova):
- `enable()` riesce in 3,44 s; `isEnabled` passa da `false` a `true`; `disable()` lo riporta a `false`.
- `currentSpeech()` subito dopo l'accensione: «WarSense».
- `moveForward()` percorre la schermata d'avvio nell'ordine, 0,51–0,52 s a passo: «Riprendi lo scontro in corso Pulsante», «Riprendi la campagna in corso Pulsante», «Nuovo scontro di prova Pulsante», «Nuova campagna, mappa piccola Pulsante», «Nuova campagna, mappa media Pulsante», «Nuova campagna, mappa grande Pulsante», «Impostazioni Pulsante», «Suoni e vibrazioni del gioco Pulsante». Il tratto («Pulsante») è pronunciato nella lingua del simulatore (it-IT).
- Oltre l'ultimo elemento `moveForward()` NON segnala la fine: restituisce di nuovo l'ultima pronuncia, e ci mette 2,29–2,30 s invece di 0,5. La fine di una schermata va quindi riconosciuta dalla pronuncia che si ripete.
- `moveBackward()` torna all'elemento precedente («Impostazioni Pulsante»).
- `moveIn()` e `moveOut()` FALLISCONO: errore 3 di `AXVoiceOverAutomationErrorDomain`, «moveIn() requires VoiceOver Navigation Style to be set to Groups». Lo stile di navigazione per gruppi non è stato impostato: i contenitori si percorrono in modo piatto con `moveForward()`.
- Il servizio restituisce ciò che VoiceOver pronuncia quando il FUOCO arriva su un elemento. Non espone gli annunci (`UIAccessibility.post(.announcement)`) come flusso a sé: se ne vede un riflesso solo quando coincidono con `currentSpeech()`.

## 2. Attivazione con VoiceOver acceso — FUNZIONA (doppio tocco sintetico)

Il servizio non ha un comando di attivazione. Con VoiceOver acceso, `XCUIApplication.doubleTap()` attiva l'elemento che ha il fuoco: la sonda `test_sonda_2_attivazione_col_doppio_tocco` porta il fuoco su «Nuova campagna, mappa piccola», fa il doppio tocco, e la mappa si apre (la casella «riga 1, casella 1» compare entro 10 s). Pronuncia corrente subito dopo: «Giorno 1. Nessun gruppo ha ancora agito, sono 4».

È il canale che mancava: le caselle e le celle sono elementi sintetici senza riconoscitori di gesto, che rispondono all'attivazione della tecnologia assistiva e non al tocco grezzo (lo dichiara `FumoMappaCampagnaTest`); con VoiceOver acceso il doppio tocco le raggiunge come le raggiunge il giocatore.

NON guidabili con questo servizio (dichiarati, non simulati): il rotore, il tocco magico (doppio tocco a due dita), lo strofinio (gesto di uscita), lo scorrimento a tre dita, l'esplorazione al tatto, le azioni personalizzate scelte con scorrimento verticale.

## 3. Verifiche di accessibilità automatiche di Xcode — FUNZIONANO

`XCUIApplication.performAccessibilityAudit(for: .all)` gira sulla schermata d'avvio (sonda `test_sonda_3_verifica_automatica_di_accessibilita`) e restituisce 7 rilievi, tutti di tipo «Text clipped» (codice 131072), sui sette pulsanti con testo lungo: «Nuova campagna, mappa media», «Riprendi lo scontro in corso», «Suoni e vibrazioni del gioco», «Nuova campagna, mappa piccola», «Nuovo scontro di prova», «Nuova campagna, mappa grande», «Riprendi la campagna in corso». La sonda raccoglie i rilievi senza fallire; il giudizio sui rilievi spetta all'esplorazione.

## 4. Strumenti del simulatore (`xcrun simctl`) — FUNZIONANO, ad apparecchio acceso

- Con Xcode 27.2, `xcodebuild test` SPEGNE il simulatore alla fine della corsa: subito dopo le sonde l'apparecchio era «Shutdown» e ogni comando `simctl` sull'apparecchio rispondeva «Unable to lookup in current state: Shutdown» (codice 405). Va acceso con `xcrun simctl boot` (o `bootstatus -b`).
- `simctl io <udid> screenshot`: schermata PNG 1260×2736 pixel (iPhone Air, scala 3).
- `simctl ui <udid> content_size`: lettura («large») e impostazione fino a `accessibility-extra-extra-extra-large`, poi ripristino a `large`.
- `simctl ui <udid> appearance`: «light».
- `simctl status_bar <udid> override --time 9:41` e `clear`: riusciti.
- `simctl spawn <udid> defaults read -g AppleLanguages`: `("it-IT","en-IT")`; `AppleLocale`: `it_IT`.
- `simctl launch <udid> com.scabo.warsense`: riuscito.

## 5. L'applicazione Simulator e il controllo dello schermo — NON DISPONIBILI

- Xcode 27.2 NON contiene l'applicazione Simulator: non esiste `Contents/Developer/Applications/`, e `find /Applications/Xcode.app/Contents -name "*.app"` non trova alcun pacchetto (nemmeno Accessibility Inspector o Instruments); `mdfind -onlyin /Applications` non trova `com.apple.iphonesimulator`. `open -a Simulator` risponde «Unable to find application named 'Simulator'». I simulatori girano quindi senza finestra, e l'esplorazione non può «usare a fondo l'applicazione Simulator», come l'incarico prevedeva.
- Il processo da cui lavora la sessione ha l'accesso d'assistenza di macOS (`System Events` → `UI elements enabled` = `true`), ma senza l'applicazione Simulator non c'è finestra su cui agire.
- In questa sessione di Claude Code non esiste alcuno strumento di controllo dello schermo (nessuno strumento `computer-use`, nessuno strumento per attivarlo: la ricerca degli strumenti differiti non ne restituisce).

## 6. Orientamento

`XCUIDevice.shared.orientation` è il canale per l'orizzontale nelle prove d'interfaccia; `simctl` non ruota l'apparecchio. Lo usa l'esplorazione (quarta parte), che ne riporta l'esito.

## Conseguenza per l'esplorazione

L'esplorazione si regge su: servizio VoiceOver per la lettura nell'ordine (primo giro), doppio tocco per l'attivazione con VoiceOver acceso, tocco ordinario e interrogazione dell'albero d'accessibilità di XCUITest per il secondo giro, `performAccessibilityAudit` sulle schermate, `simctl` per la taglia del testo e le schermate, `XCUIDevice.orientation` per l'orizzontale. Non si possono guidare il rotore, il tocco magico, lo strofinio e lo stile di navigazione per gruppi.
