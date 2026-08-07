# Resoconto — I simboli delle tessere del deck (incarico 13)

## I nove archetipi e il simbolo assegnato

Elenco degli archetipi (`Codice/Sources/Contenuti/Valori/archetipi.json`, nove `identificatore`) con la descrizione in parole del simbolo. Ogni simbolo è una silhouette monocroma piena, distinta dalle altre per la FORMA e non per il colore.

1. `fanteria_leggera` («fanteria leggera») — una **lancia**: asta verticale con punta a foglia.
2. `fanteria_pesante` («fanteria pesante») — uno **scudo** araldico (heater): bordo superiore ampio, fianchi che rientrano a punta in basso.
3. `guardia_elite` («guardia scelta») — un **elmo crestato** di profilo (corinzio): calotta con feritoia per gli occhi e cresta/pennacchio arcuato sopra.
4. `tiratori` («tiratori») — un **arco con freccia incoccata**: arco a mezzaluna aperto a destra, corda, freccia orizzontale con punta a destra e cocca a sinistra.
5. `cavalleria_ricognizione` («cavalleria da ricognizione») — una **testa di cavallo** di profilo, rivolta a sinistra, con orecchie e criniera.
6. `cavalleria_manovrata` («cavalleria manovrata») — **due lance incrociate** a X (saltire), con punta di lancia all'estremità superiore di ciascuna.
7. `piattaforma_trainata` («piattaforma trainata») — un **affusto su ruota**: ruota con mozzo, barra orizzontale (la piattaforma) sopra, timone di traino diagonale in basso a destra.
8. `macchina_assedio` («macchina d'assedio») — un **ariete sotto tettoia**: tetto a spiovente, trave orizzontale con testa d'ariete sporgente a destra, gambe di sostegno.
9. `macchina_tiro` («macchina da tiro») — una **catapulta**: telaio ad A, braccio di lancio diagonale verso l'alto a destra, proiettile in cima.

## Esito dell'accertamento sugli assetti

- **Archetipi: nove, chiusi** (`archetipi.json`, lista di nove oggetti con `identificatore`).
- **Assetti misti: NON istanziati nel modello di battaglia.** `ElementoDeck` e `Sciame` (`Codice/Sources/Motore/StatoBattaglia.swift`) portano un solo `archetipo: IdentificatoreDati` più la `protezione: TipoProtezione`: sono monotipo. Nessun file di dati definisce un assetto misto; nessuna tessera del deck ha oggi più di un archetipo. La parola «assetto» nei commenti del Motore designa la configurazione monotipo (archetipo + protezione + taglia), non una mistione.
- **Il numero degli assetti è APERTO**, non chiuso: 01 §4.7 dichiara «un insieme di assetti ammessi», ciascuno con taglia e composizione, che cresce con le combinazioni (01 §4.8); l'assetto misto è concetto consolidato (01 §4.1, §4.7, §4.8.1; 02 §3.7.1) ma non realizzato.
- **Regola del simbolo per l'assetto misto** (RDA-97): poiché gli archetipi sono pochi e chiusi si disegna un simbolo proprio per ciascuno; poiché gli assetti sono aperti, per un assetto misto varrà — quando il modello lo preveda — il simbolo dell'archetipo PREVALENTE con un segno di mistione, come REGOLA imperniata sul prevalente e non come elenco di disegni per combinazione. Vale 02 §3.7.1 per il segno come per la voce: il simbolo non rappresenta la composizione. La regola è dichiarata e registrata ma NON resa nel codice, perché il modello non prevede ancora l'assetto misto (nessun campo di composizione, nessun archetipo prevalente): renderla ora sarebbe un canale che esiste solo per il collaudo. `CostruttoreAnnunci.nomeSimboloElementoDeck` restituisce già l'archetipo dell'elemento, oggi sempre puro.

Fonte: `archetipi.json` (nove `identificatore`); `Codice/Sources/Motore/StatoBattaglia.swift` (`ElementoDeck` righe 51-56, `Sciame` righe 13-48); `Fondamenta/01-progetto-del-gioco.md` §4.7, §4.8, §4.8.1; `Fondamenta/02-accessibilita.md` §3.7.1, §8.2.

## Formato dei simboli

Nove `.symbolset` in `Applicazione/Risorse/Immagini.xcassets`, uno per archetipo, ciascuno nominato con l'`identificatore` dell'archetipo. Ogni `.svg` è scritto a mano nel formato del template SF Symbols: `viewBox="0 0 100 100"`; gruppo `Guides` con le sei linee `Capline-S/M/L` e `Baseline-S/M/L`; gruppo `Symbols` con le nove varianti `{Ultralight,Regular,Black}-{S,M,L}` che condividono un solo `<path>` di glifo (la silhouette è piena e non varia col peso). `guardia_elite` e `piattaforma_trainata` usano `fill-rule="evenodd"` (feritoia dell'elmo; mozzo della ruota); gli altri `nonzero`. Il formato è stato validato per `actool` iterando sulle diagnostiche (mancava `Baseline-S`, poi `Capline-S`); il caricamento del catalogo compila senza errori (`xcodebuild build` su `platform=iOS Simulator,name=iPhone 17`, `** BUILD SUCCEEDED **`).

Le forme sono state disegnate in parallelo: otto sottoagenti hanno prodotto in contemporanea il path del rispettivo glifo su una tela 100×100; `guardia_elite`, il cui primo path era illeggibile, è stato ridisegnato a mano fra tre candidati con la feritoia dell'elmo. La rifinitura è avvenuta rasterizzando i path su host (`AppKit.NSImage(data:)` legge l'SVG) e ispezionando le silhouette a 100, 46 e 32 punti.

## Il cancello (biiezione archetipi ↔ simboli)

Il controllo che rifiuta, non la prescrizione scritta, nei due versi:

- Verso «archetipo senza simbolo»: `Applicazione/ProveOspitate/SimboliDegliArchetipiTest.swift`, `test_principio_1_ogni_archetipo_ha_il_proprio_simbolo` carica da `archetipi.json` i nove `identificatore` e pretende `UIImage(named: id, in: Bundle(for: TesseraDeck.self), compatibleWith: nil) != nil` per ciascuno.
- Entrambi i versi (compreso «simbolo orfano», non enumerabile a runtime dal catalogo compilato): `scripts/verifica-simboli.sh`, cancello di script che confronta i nove `identificatore` con i `*.symbolset` di `Immagini.xcassets` e rifiuta al primo disallineamento; è passo 0 di `scripts/collaudo-completo.sh`.
- **Visto rifiutare di proposito**, poi ripristinato: rimosso `guardia_elite.symbolset` → «RIFIUTATO: archetipi senza simbolo: guardia_elite» (uscita 1); aggiunto un `orfano_finto.symbolset` estraneo → «RIFIUTATO: simboli orfani: orfano_finto» (uscita 1); ripristinato → «biiezione verificata su 9 archetipi» (uscita 0).

## L'annuncio non cambia

Etichetta e valore della tessera restano l'uscita di `CostruttoreAnnunci.nomeElementoDeck`/`valoreElementoDeck` (funzioni NON toccate). `Applicazione/ProveOspitate/StabilitaDellaDisposizioneTest.swift`, `test_02_8_2_l_annuncio_della_tessera_non_cambia_col_ridisegno` è stato modificato per confrontare `tessera.accessibilityLabel` e `accessibilityValue` con l'uscita del costruttore (`XCTAssertEqual`, prima=dopo), verificare che il valore contenga atomi e volume disegnati, e che il simbolo sia disegnato (`simboloDisegnatoPerProva != nil`). Il simbolo è un'immagine, non un testo: non può comparire nell'annuncio.

## Leggibilità (chiaro, scuro, contrasto aumentato)

`SimboliDegliArchetipiTest.test_00_1_4_ogni_simbolo_si_disegna_a_dimensione_reale_in_chiaro_scuro_e_contrasto` disegna ogni simbolo caricato via `UIImage(named:)` al lato reale del riquadro (`TesseraDeck.latoSimbolo` = 32 punti), tinto con `UIColor.label.resolvedColor(with:)` in `UITraitCollection(userInterfaceStyle: .light)`, `.dark`, e `UITraitCollection(accessibilityContrast: .high)`, e pretende che il render abbia inchiostro (almeno un pixel con alfa > 0). Superata nel collaudo. La riconoscibilità delle nove forme a 32 punti in chiaro e scuro, su sfondo del colore reale della tessera (`secondarySystemBackground`, ~#F2F2F7 chiaro / ~#1C1C1E scuro), è stata verificata rasterizzando su host i path effettivi dei `.symbolset` committati e ispezionando il montaggio: le nove forme sono distinte e leggibili nei due temi. Il contrasto aumentato non altera la forma (silhouette piena) e rende la tinta `.label` più netta.

## Modifiche al codice

- `Applicazione/Sorgenti/TesseraDeck.swift`: `etichettaSigla: UILabel` → `vistaSimbolo: UIImageView` (`contentMode = .scaleAspectFit`, riquadro fisso `latoSimbolo = 32` centrato fra nome e quadratini, reso `.alwaysTemplate`, tinto `isSelected ? tintColor : .label`). `aggiorna(... sigla: String ...)` → `aggiorna(... simbolo: UIImage? ...)`. `siglaDisegnataPerProva: String?` → `simboloDisegnatoPerProva: UIImage?`. `latoSimbolo` reso interno per la prova. Geometria invariata (65×56, altezza fissa).
- `Applicazione/Sorgenti/CostruttoreAnnunci.swift`: `siglaElementoDeck(indice:) -> String` → `nomeSimboloElementoDeck(indice:) -> String`, che restituisce `elemento.archetipo` (l'`identificatore`, cioè il nome dell'asset).
- `Applicazione/Sorgenti/SchermataBattaglia.swift`: in `aggiorna(con:)` la tessera riceve `simbolo: UIImage(named: costruttore.nomeSimboloElementoDeck(indice: tessera.tag))`; aggiunto `costruttorePerProva` per la prova dell'annuncio.

## Testi e manifest

- Chiavi `deck.sigla.<archetipo>` rimosse da `Codice/Sources/Contenuti/Testi/it.lproj/Annunci.strings`.
- `Codice/Sources/Contenuti/Testi/en.lproj/Annunci.strings` — che conteneva SOLTANTO le nove sigle inglesi — eliminato con la cartella `en.lproj` (i simboli sono indipendenti dalla lingua).
- Manifest dei testi rigenerato con `python3 scripts/rigenera-impronte.py` (impronta di `it.lproj/Annunci.strings` aggiornata, `en.lproj/Annunci.strings` tolta; versione 0.1.1 invariata, come impone lo script). Il cancello `Codice/Tests/DatiTest/CaricamentoTest.swift` sul manifest dei testi è verde nel collaudo.

## Documenti

- `valori-provvisori.md`: la voce «Sigle degli archetipi sulla tessera del deck» è marcata RIMOSSA (rimando a RDA-97), non è più un valore provvisorio.
- `Fondamenta/registro-decisioni-architetturali.md`: aggiunta la Parte sedicesima e RDA-97, con la forma dei simboli, l'accertamento sugli assetti, la regola dell'assetto misto, il cancello e il suo fallimento visto, l'annuncio invariato, la leggibilità e le conseguenze sul codice.
- Le due note rigenerate: `note-di-rilascio.txt` (tester) e `nota-per-il-titolare-simboli.md` (che sostituisce `nota-per-il-titolare-mischia.md`, rimossa). La nota per il titolare dichiara che le sigle sono sostituite dai simboli, che cosa rappresenta ciascuno, e che l'annuncio a voce non è cambiato. Superano `scripts/controlla-note.py` (lunghezza 1919/4000 caratteri per la nota di rilascio; nove nomi citati fra «...», tutti valori del catalogo dei testi; nessun numero a due cifre non dichiarato).

## Collaudo

`scripts/collaudo-completo.sh` (simulatore iPhone 17), tutto verde:
- Passo 0, cancello dei simboli: «biiezione verificata su 9 archetipi».
- Passo 1, pacchetto `swift test`: «Executed 250 tests, with 1 test skipped and 0 failures» (blocco di riepilogo di `swift test`, «All tests passed» 2026-08-07 09:33).
- Passo 3, prove ospitate e d'interfaccia (`xcodebuild test`, `SessioniPerInterfacciaTest/test_00_3_9` escluso per `-skip-testing`): «70 prove eseguite — 70 passate, 0 fallite, 0 saltate; esito Passed» (riepilogo di `scripts/conta-prove.sh` via xcresulttool: WarSenseTest = 62, WarSenseUITest = 8).

Corsa separata delle sessioni complete (`scripts/esegui-sessioni-complete.sh`, uscita 0): «144 campagna per interfaccia + headless completo con 32 battaglia al Motore (S11)», esito «successo» su `33f8246` (`esiti-sessioni-complete/esito.json`, gitignorato). Cancello `scripts/controlla-sessioni.py`: «esito «successo», girata su 33f8246, codice a 33f8246» (uscita 0). Il caricamento (`scripts/carica-testflight.sh`) ha rieseguito l'intero collaudo prima dell'archivio, verde.

## Versionamento

- Commit del codice sul ramo `simboli-deck`: `33f8246`.
- Fusione su `principale` in avanti veloce (`git merge --ff-only simboli-deck`), niente commit di fusione.
- Spinta: `git push origin principale` (`b11b2a8..33f8246`) e `git push origin simboli-deck`.
- Dopo il caricamento: commit `24d3996` (registro `build-caricate.md`, build 19) e il commit di questo resoconto, entrambi su `principale` e spinti.
- Ramo `simboli-deck` cancellato locale e remoto dopo la fusione (`git branch -d`, che rifiuta i non fusi).
- Stato finale: `git rev-parse principale` = `git rev-parse origin/principale` (riportato in coda alla sessione, valori uguali).

## Caricamento

Build **19** caricata su TestFlight con `scripts/carica-testflight.sh` (uscita 0). Cancelli preventivi tutti superati: spinta (`principale` locale = `origin/principale`), versione (1.1.0, non torna indietro), documenti (nota di rilascio 1919/4000 caratteri, freschezza documento 33f8246 = codice 33f8246, vocabolario nove nomi, cifre a posto), registro build vs App Store Connect, freschezza della corsa separata. Numero di build: massimo sull'account 18 → 19. `altool`: «UPLOAD SUCCEEDED with no errors», Delivery UUID `22239e4f-3db4-4988-badf-a46a8225b193`. Nota allegata alla build 19 (`scripts/nota-testflight.sh`), build 19 registrata in `build-caricate.md` (`scripts/controlla-build.py --appendi`).

Verifica per interfaccia di programmazione (App Store Connect, `scripts/asc_api.py`):
- `processingState` = **VALID**, `expired` = false (`GET /v1/builds?filter[version]=19`).
- Treno (`preReleaseVersion`) = **1.1.0** IOS, che è il PIÙ ALTO su App Store Connect (treni presenti: 0.2.0, 1.0, 1.1.0 — `GET /v1/preReleaseVersions`).
- Assegnata al gruppo di test **WarLab** (interno) — `betaGroups`, un gruppo.
- Registro build concorde coi server NEI DUE VERSI: «registro e App Store Connect concordano: 19 build, la più alta è la 19» (`scripts/controlla-build.py`, uscita 0).
- Cancello sulla corsa separata delle sessioni complete: soddisfatto (uscita 0). Cancello sulla spinta: non rifiuta (`principale` locale = `origin/principale`).

## Versione dei valori

NON incrementata: resta 0.7.0 (`Codice/Sources/Contenuti/Valori/manifest.json`). Cambia soltanto la rappresentazione visiva della tessera; l'annuncio, il modello dello stato (`ElementoDeck`, `Sciame`, il giornale) e i valori sono invariati, quindi nessuna regola incide su come una partita in corso si svolgerebbe, e non ricorre il criterio di incremento di RDA-92/RDA-91. I salvataggi della build 18 restano compatibili (`versioni_compatibili: ["0.7.0"]`).

## Ciò che non è stato verificato

- La resa dei simboli su DISPOSITIVO reale con VoiceOver attivo non è stata verificata (il collaudo automatico gira su simulatore); la parità sonoro/visivo e la mutezza del simbolo alla voce sono verificate dal collaudo, la RESA GRAFICA su dispositivo la giudicherà il titolare sulla build.
- La leggibilità col contrasto aumentato è verificata come «il simbolo disegna inchiostro» (prova) e per ragionamento (silhouette piena, tinta più netta); non è stata ispezionata visivamente una cattura in contrasto aumentato su dispositivo.

## Fatto, che l'incarico non chiedeva

- Eliminazione della cartella `en.lproj` (l'incarico chiedeva di togliere la sigla dai valori provvisori; la rimozione del pacchetto inglese, che conteneva solo le sigle, ne è la conseguenza per non lasciare un file orfano).
- Aggiunta di `costruttorePerProva` a `SchermataBattaglia` per rendere il confronto dell'annuncio prima/dopo un'uguaglianza esatta e non solo un contenimento.

## Chiesto, che non è stato fatto

- La regola del simbolo per l'assetto misto è dichiarata e registrata ma NON resa nel codice, perché il modello di battaglia non prevede l'assetto misto: renderla sarebbe un canale solo per il collaudo (motivato sopra e in RDA-97). L'incarico chiedeva di «realizzarla come regola»: è realizzata come regola dichiarata sull'archetipo prevalente, non come meccanismo attivo su dati che non esistono.
