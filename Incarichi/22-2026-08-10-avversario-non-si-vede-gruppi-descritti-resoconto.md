Resoconto — Perché l'avversario non si vede, e che cosa i gruppi dichiarano di sé (incarico 22)

## In testa: che cosa causava le due osservazioni del titolare

Una causa sola, per entrambe: `raggio_osservazione` = 1 in `conoscenza-campagna.json`. Su una mappa di cento caselle (dieci per dieci) un gruppo che osserva solo entro un passo ortogonale vede quasi nulla, e l'avversario — che si muove per corsie diverse dalla propria (aggiramento, RDA-114) — non entrava mai nel suo campo. Non era assente, era invisibile.

Prima osservazione (portare un gruppo al quartier generale nemico senza mai avvistare l'avversario): con raggio 1, misurato dal banco (`BancoCampagna.Corsa.avvistamenti`, prova `InvariantiCampagnaTest.test_incarico_22_il_banco_genera_e_misura_gli_avvistamenti`, quaranta giornate), sullo scenario `pianura_contro_avversario` il giocatore avvistava **3** formazioni avversarie in tutta la partita, la prima alla giornata **10**, osservando il **32%** della mappa. Con `raggio_osservazione` = 2: **14** avvistamenti, il primo alla giornata **8**, **43%** osservato. Sugli altri scenari con avversario, prima → dopo: `guado_contro_avversario` **7 → 11**, `ricognizione_imboscate_pianura` **5 → 19**. Il 43% osservato sulla pianura mostra che l'informazione resta INCOMPLETA: l'avversario si manifesta, non è sempre visibile.

Seconda osservazione (interrogando il proprio quartier generale, un «avvistato» di cinque turni mentre la partita era al giorno dieci): NON era un avvistamento di nemico, e NON era il falso. Il numero «avvistato, N turni» è lo STATO DI CONOSCENZA della casella (`StatoConoscenza.avvistato(turni:)`, testo `conoscenza.avvistato` = «avvistato, %#@turni@»), cioè da quanti turni il giocatore non osserva più quella casella — invecchiata perché s'era allontanato dal proprio quartier generale. È l'unica grandezza del gioco che produce un numero di turni; l'occupante avversario (`casella.occupante_avversario*`) non porta mai turni e compare solo dove la conoscenza è `confermato`. Il gioco non dichiarava il falso: diceva, veramente, che la sua conoscenza di casa propria era vecchia di quei turni. La stessa causa (raggio piccolo) lasciava quasi tutta la mappa perennemente «avvistata» e prestava quella parola all'equivoco. Con il raggio più ampio molte meno caselle restano vecchie.

Esito dichiarato prima di intervenire (RDA-125): non un difetto del codice (l'avvistamento nasce solo dove il giocatore osserva), non la condotta (l'avversario incrocia il giocatore, semplicemente non lo si vedeva) — la TARATURA del raggio. Correzione applicata nella stessa sessione.

## Accertamento

L'avvistamento avversario è prodotto in `MotoreCampagna` solo per gli arrivi avversari su caselle `osservata(_, da: .giocatore, stato:)` (`for arrivo in arriviAvversari where osservata(...) { eventi.append(.formazioneAvversariaAvvistata(...)) }`), e la voce d'annuncio dell'occupante avversario (`VistaCampagna.vociDiCasella`) compare solo dove la conoscenza è `confermato`. Non esiste percorso per cui un avvistamento compaia senza una formazione realmente osservata: verificato per lettura del codice e reso invariante (sotto, `avvistamento_senza_formazione`). Il «numero di turni» è prodotto unicamente dallo stato di conoscenza `avvistato`, mai dall'occupante avversario: verificato per lettura di `frase(di: .conoscenza)` e `frase(di: .occupanteAvversario)` in `CostruttoreAnnunciCampagna`, e dell'unica `frase` che consuma `conoscenza.avvistato` con l'argomento dei turni.

Misura della porzione di mappa osservata e degli avvistamenti: campi nuovi di `BancoCampagna.Corsa` (`avvistamenti`, `primoAvvistamento`, `gapMedioAvvistamenti`, `caselleOsservate`, `caselleTotali`), popolati lungo la corsa (`caselleOsservateUnione.formUnion(motore.caselleOsservate(da: .giocatore, stato:))` a ogni giornata; il conteggio degli eventi `formazioneAvversariaAvvistata` in `contaFenomeni`). Riportati a ogni corsa (`FENOMENI-22` in `test_incarico_22_il_banco_genera_e_misura_gli_avvistamenti`). Numeri prima/dopo raccolti eseguendo la prova con `raggio_osservazione` a 1 e a 2 (i valori intermedi sono nel corpo, sopra).

## Correzione: la taratura del raggio (RDA-125, valori-provvisori)

- `conoscenza-campagna.json`, `raggio_osservazione`: **1 → 2**.
- `ricognizione-campagna.json`, `raggio_esplorazione`: **2 → 3**. Cambiato per VINCOLO, non per taratura autonoma: il caricatore esige `raggio_esplorazione > raggio_osservazione` (errore `errore.dati.ricognizione_incoerente`), o l'esplorazione non rivelerebbe nulla oltre la vista ordinaria. Sale del minimo che conserva la relazione.
- Impronte dei Contenuti rigenerate (`scripts/rigenera-impronte.py`): `Valori/manifest.json` 21 file, versione **0.11.0 invariata**.

Prove aggiornate alla nuova taratura: `ConoscenzaTest.test_5_3_si_conferma_l_osservato_e_l_inesplorato_e_ignoto` (una casella a distanza ortogonale due è ora `confermato`; una a distanza tre `inesplorato`); `RicognizioneImboscateTest.test_01_5_4_esplorazione_riuscita_rivela_la_zona` (l'esplorazione rivela a distanza tre, oltre il raggio ordinario di due). L'invariante dell'avvistamento avvenuto (sotto) non ha reso rosso il fumo perché quest'ultimo tronca a quattro giornate: gestito con `partitaCompleta`.

## Che cosa i gruppi dichiarano di sé (RDA-126)

Categoria: già dichiarata dall'incarico 19, per le proprie con la chiave d'occupante secondo la categoria (`casella.occupante_proprio`/`_ricognizione`/`_non_armata`), per le avversarie con `casella.occupante_avversario*`, e con il marcatore di FORMA sulla mappa uguale per le due parti (`»` ricognizione, `≈` non armata, nulla l'armato ordinario). Verificato che il segno delle PROPRIE formazioni porta già il marcatore di categoria (`segno(di: .occupante)` in `CostruttoreAnnunciCampagna`): nessuna modifica di mappa necessaria per la categoria.

Composizione (nuova, per le SOLE proprie formazioni): voce nuova `VistaCampagna.VoceDiCasella.composizionePropria([Reparto])`, prodotta da `vociDiCasella` DOPO tutte le voci di testa (compresa la categoria dell'occupante avversario co-locato), sicché il livello sintetico la taglia per prima dalla coda (`contenutoCasella` in `CostruttoreAnnunciCampagna`, che interrompe alla prima voce non di testa nel sintetico). L'annuncio riusa la frase «N atomi di <archetipo>» della divisione (`divisione.reparto`, dallo stringsdict) unita in elenco dietro la chiave nuova `casella.composizione` = «composta da %@»: NESSUN termine nuovo del vocabolario chiuso. Non esiste per le avversarie (di cui non si dichiara il volume, 02 §6.4.1). Non ha segno di mappa (`segno(di: .composizionePropria)` = `nil`): un numero di atomi non ha forma; la regola «il segno coincide con l'annuncio» riguarda le tre categorie, già distinte (scostamento S22). Firme toccate: aggiunto il caso all'enumerativo `VoceDiCasella` (Motore) e ai due `switch` esaustivi `frase(di:)` e `segno(di:)` (Applicazione) — il compilatore impone la copertura (RDA-74).

Prova d'interfaccia nuova `AnnuncioDiCasellaTest.test_incarico_22_la_propria_formazione_dichiara_la_composizione`: il livello normale e il dettagliato dichiarano la composizione, il sintetico la tace. La struttura dei tagli dalla coda regge (`test_00_9_5_la_verbosita_taglia_dalla_coda_e_mai_la_testa_fissa`).

## Il collaudo: i due cancelli nuovi (RDA-127)

Due invarianti nuovi in `SondaInvariantiCampagna`, aggiunti a `codiciNoti`, ciascuno col mutante in `InvariantiCampagnaTest.tavolaDeiMutanti` (guardia `test_incarico_6_ogni_invariante_ha_almeno_un_mutante_che_lo_fa_scattare`):

- `nessun_avvistamento_in_partita`: in una partita INTERA contro l'avversario il giocatore deve avvistare almeno una formazione avversaria. `controllaAvvistamentoAvvenuto(avvistamenti:conAvversario:)` riceve il conteggio dall'esterno (lo produce il banco), come `controllaTerminazione`. Il banco lo applica solo se `partitaCompleta` (nuovo parametro di `corri`, preimpostato a vero; `ProgrammaDiVerifica` lo pone a `false` nel fumo, che tronca a quattro giornate — il primo avvistamento arriva fra la giornata cinque e la otto, sicché una corsa troncata può legittimamente non averlo ancora avuto; scostamento S22).
- `avvistamento_senza_formazione`: a un avvistamento dichiarato deve corrispondere una formazione avversaria realmente su quella casella osservata. In `controllaRegistro` la voce `formazioneAvversariaAvvistata` è ora distinta dalle altre due (`formazioneStudiata`, `direzioneDedotta`): se la casella non è osservata è `registro_rivela_ignoto` (già esistente); se è osservata ma priva di avversario in `dopo` è `avvistamento_senza_formazione`. Il banco chiama `controllaRegistro` anche dopo il turno del GIOCATORE (prima solo dopo l'avversario), perché la cascata di fine giornata e i suoi avvistamenti possono chiudersi sull'ultimo comando del giocatore.

Cancelli visti scattare (con l'uscita): il mutante di `nessun_avvistamento_in_partita` produce `["nessun_avvistamento_in_partita"]`, quello di `avvistamento_senza_formazione` produce `["avvistamento_senza_formazione:riga=4:casella=4"]`; prove dedicate `test_incarico_22_il_cancello_del_nessun_avvistamento_scatta_e_tace` e `test_incarico_22_il_cancello_dell_avvistamento_senza_formazione_scatta_e_tace` (scatta con l'input guasto, tace con quello sano). La guardia dei mutanti pareggia: ogni codice di `codiciNoti` ha un mutante che lo fa scattare.

Numeri del collaudo, con lo strumento:

- Prove del pacchetto (`swift test`, cartella `Codice`): **334** eseguite, **1** saltata (le 144 sessioni, che girano a parte), **0** fallite.
- Prove ospitate e d'interfaccia sul simulatore (`scripts/collaudo-completo.sh`, conteggio da `xcresulttool summary`): **74** eseguite — **66** `WarSenseTest`, **8** `WarSenseUITest` — **74** passate, **0** fallite, **0** saltate.
- Sessioni complete (`scripts/esegui-sessioni-complete.sh`): 1/2 le 144 configurazioni di CAMPAGNA per l'interfaccia (test parametrizzato unico, `sessioni-complete-risultati.xcresult`, esito Passed da `xcresulttool` — total 1, failed 0); 2/2 le sessioni HEADLESS di campagna e le 32 di battaglia (`SessioniCompleteTest`, passate). Lo script conclude «Corsa separata: SUCCESSO». Nessuna violazione.

## Le note

`nota-per-il-titolare-avversario-visibile.md` (nuova): in linguaggio non tecnico, che cosa non funzionava (raggio piccolo) e che cosa cambia (l'avversario si manifesta); che il «avvistato» al quartier generale non era un nemico ma l'età della propria conoscenza; che ogni gruppo dichiara categoria e — le proprie — composizione; che cosa controllare per dire se l'avversario ora si incontra. `note-di-rilascio.txt` riscritta per la build nuova (3294 caratteri su 4000). Controllo delle note (`scripts/controlla-note.py`): vocabolario 27 nomi citati tutti esposti dal codice; nessun numero di due cifre non dichiarato; freschezza e misure verificate al caricamento.

## Versione e versionamento

Valutazione della versione dei valori, dichiarata (valori-provvisori): RESTA **0.11.0**. La regola del titolare è che le versioni salgono su istruzione, e questo incarico non ne dà una; il raggio è un valore PROVVISORIO, la cui taratura è ciò per cui i valori provvisori esistono. Nessuna incompatibilità di salvataggio: il raggio vive nei valori, non nel giornale; lo schema del giornale di campagna RESTA 5. La versione dei Testi RESTA **0.1.1** benché aggiunta la chiave `casella.composizione` (l'aggiunta non muta alcun testo esistente; impronte «invariata»). Versione di marketing, certificati, profili, identificatori di pacchetto: non toccati.

## Il caricamento

Build **24** caricata (`scripts/carica-testflight.sh`, «UPLOAD SUCCEEDED with no errors»). Numero di build = massimo su tutto l'account più uno: `massimo: 23 -> nuovo: 24` (query ASC `/v1/builds`). Tutti i controlli preventivi verdi prima dell'archivio: ramo spinto, versione che non torna indietro, note che reggono, registro e ASC concordi (23 build), corsa separata delle sessioni fresca (girata su 2a0e9c1). Nota di rilascio allegata alla build 24 (`nota-testflight.sh`), build registrata in `build-caricate.md`.

Verifica per interfaccia di programmazione (`scripts/asc_api.py`, `/v1/builds?filter[app]=6797306323&sort=-version&include=preReleaseVersion,betaGroups`): la build 24 è VALIDA (`processingState` = VALID, `expired` = false), sul treno più alto (`preReleaseVersion` = **1.1.0**, la stessa della 23, ed è la build più alta del treno), assegnata a un gruppo di test (`betaGroups` = 1). Registro e ASC concordano NEI DUE VERSI (`scripts/controlla-build.py`): «registro e App Store Connect concordano: 24 build, la più alta è la 24». Versione di marketing 1.1.0 non toccata.

## Il versionamento

Ramo dedicato `avversario-visibile-gruppi-descritti`, fuso su `principale` con avanzamento veloce (solo verde), spinti entrambi; ramo cancellato dopo la fusione (`git branch -d`, che ha accettato la cancellazione perché fuso: «Deleted branch … (was 2a0e9c1)»), anche sul remoto. `principale` locale e remoto coincidono, accertato dopo l'ultima spinta: `git rev-parse principale` e `git rev-parse origin/principale` restituiscono lo stesso SHA (l'uscita è riportata nel resoconto della sessione al titolare; la spinta dell'ultimo commit — questo resoconto — precede l'accertamento).

## Registri toccati

`Fondamenta/registro-decisioni-architetturali.md`: RDA-125 (taratura del raggio), RDA-126 (categoria e composizione), RDA-127 (i due cancelli). `valori-provvisori.md`: sezione del raggio con i numeri prima/dopo e la valutazione della versione. `registro-scostamenti.md`: S22 (l'ipotesi giusta nella causa ma non nei due corni della seconda osservazione; dove sta la composizione; niente segno per la composizione; il cancello morde sulle partite intere). `Incarichi/README.md`: riga 22 aggiornata al resoconto.

## Fatto senza che fosse chiesto

- `controllaRegistro` esteso al turno del giocatore (oltre a quello dell'avversario) nel banco: gli avvistamenti della cascata di fine giornata innescata dal giocatore non erano altrimenti sorvegliati dal cancello `avvistamento_senza_formazione`.
- `raggio_esplorazione` alzato a 3 come conseguenza VINCOLATA del raggio di osservazione a 2 (il caricatore lo esige), non come taratura scelta.

## Chiesto e non fatto

Nulla di quanto l'incarico prescrive è stato omesso. La condotta avversaria non è stata modificata perché l'accertamento ha mostrato che non è la causa (l'avversario incrocia il giocatore; era la vista a mancare): l'incarico autorizzava a correggerla «se» fosse la causa, e non lo era — dichiarato coi numeri.
