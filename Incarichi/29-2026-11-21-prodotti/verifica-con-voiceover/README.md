# La verifica attraverso l'interfaccia, con VoiceOver (incarico 29)

Canale: il pilota dell'incarico 28 (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`, `test_sessione_da_tester`, schema `WarSenseEsplorazione`), che gira sul simulatore con VoiceOver acceso e legge i comandi da `comandi.jsonl`; lo guida `percorsi.py` (questa cartella), che per ogni controllo scrive atteso, trovato ed esito in `controlli.jsonl`. Lettura: `XCUIVoiceOverService` (la pronuncia restituita si tronca a 64 caratteri) e l'albero di accessibilità. Simulatori iOS 27.0: «WarSense iPhone Air» C86CB490…, «WarSense iPad Pro 13» D01FE19F…, «WarSense iPhone Air · 3» E2C6F42C… per la ripetuta con l'app corretta.

| cartella | app | blocchi | quando |
|---|---|---|---|
| `iphone/`, `ipad/` | costruita alle 20:29 dal codice di 9a83674 | battaglia, campagna (due corse: la prima con i controlli dell'osservazione 5 scritti male), blocco (due corse: la prima non marciava), testo, selezione | 20:31–21:14 |
| `iphone-app-corretta/` | costruita dopo e68e39d (leva corretta) | testo | dopo le 21:30 |
| `tester-iphone/` | come `iphone/` | `scripts/tester.py … piccola 6 nuova tutti`: una campagna piccola giocata dal tester dell'incarico 28, ogni armato verso nord | dalle 21:14 |

In ogni cartella: `controlli.jsonl` (gli esiti), `esiti.jsonl` (ogni passo del pilota: pronunce, fuoco prima e dopo, albero quando chiesto), `comandi.jsonl` (i comandi dati), `guidatore-*.log` (l'uscita del guidatore). `schermate/`: una selezione.

Che cosa NON si guida e si dichiara: il gesto di uscita (nessuna API; il tasto Esc non arriva come `accessibilityPerformEscape`); la pronuncia di VoiceOver dopo il doppio tocco sintetico (il servizio ripete la lettura della messa a fuoco); l'orizzontale.
