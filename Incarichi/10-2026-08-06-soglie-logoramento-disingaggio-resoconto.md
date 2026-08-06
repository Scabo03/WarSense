# Resoconto — Le soglie di disingaggio, il logoramento e il reparto elitario (incarico 10)

## Tabella 1 — Assegnazione dei nove archetipi alle fasce

Valori nei dati (`archetipi.json`, campo `soglia_disingaggio`), PROVVISORI (`valori-provvisori.md`). Ordinamento reciproco per crescente tenuta in mischia: più il reparto è da distanza o mobile, prima si sfila; più è pesante, più regge; l'elitario mai.

| fascia | soglia | archetipi | comportamento |
|---|---|---|---|
| bassa | 0,12 | `tiratori`, `piattaforma_trainata`, `macchina_tiro` | si sfilano quasi subito (reparti da tiro e distanza) |
| media | 0,6 | `fanteria_leggera`, `cavalleria_ricognizione`, `cavalleria_manovrata` | si sfilano a metà strada |
| alta | 0,9 | `fanteria_pesante`, `macchina_assedio` | non si sfilano quasi mai (pesanti) |
| elitario | assente (nil) | `guardia_elite` | non si sfila MAI da sé; l'unico che si disingaggia su ordine |

Misura della separazione, sezione `mischia_fasce` di `StrumentoVerifica` (colonna `scatta_mediana`): la soglia scatta in mediana dopo **1 / 4 / 8** scambi per bassa / media / alta; l'elitario a 0 accoppiamenti (mai). Divario ≥ 2 scambi fra fasce adiacenti. Cancello: `MisuraMischiaTest.test_incarico10_le_fasce_di_disingaggio_restano_separate`, visto fallire appiattendo la media sulla bassa.

## Tabella 2 — Turni-soglia del bersaglio, PRIMA → DOPO, per accoppiamento

Prodotta da `StrumentoVerifica`, sezione `mischia_accoppiamenti`, colonna `turni_soglia_bersaglio`, protezione `anti_saturazione` (matrice riga = attaccante, colonna = bersaglio; `·` = non scatta, cioè il bersaglio vince senza raggiungere la propria soglia o — per l'elitario — non ne ha). PRIMA = valori del commit 89fd913 (soglie vecchie, nessun coefficiente); DOPO = valori nuovi. Le corse PRIMA sono state prodotte con `StrumentoVerifica --valori <cartella>` su una cartella derivata da 89fd913 con i due campi nuovi neutri. Riscrittura meccanica (script Python) delle 162 righe di ciascuna corsa.

| att\ber | c.man | c.ric | f.leg | f.pes | guar | m.ass | m.tir | piat | tira |
|---|---|---|---|---|---|---|---|---|---|
| **c.man** | 3→6 | 2→4 | 2→4 | ·→· | ·→· | ·→· | 2→1 | 2→1 | 1→1 |
| **c.ric** | ·→· | 4→10 | 4→· | ·→· | ·→· | ·→· | 4→3 | 6→2 | 2→1 |
| **f.leg** | 4→· | 2→5 | 2→7 | ·→· | ·→· | ·→· | 3→2 | 3→1 | 2→1 |
| **f.pes** | 2→3 | 1→2 | 1→3 | 5→11 | ·→· | 2→· | 1→1 | 2→1 | 1→1 |
| **guar** | 2→3 | 1→2 | 1→2 | 4→7 | 8→· | 2→· | 1→1 | 2→1 | 1→1 |
| **m.ass** | 1→2 | 1→1 | 1→1 | 2→3 | 3→· | 1→8 | 1→1 | 1→1 | 1→1 |
| **m.tir** | ·→· | 5→11 | 5→· | ·→· | ·→· | ·→· | 5→3 | 8→3 | 3→2 |
| **piat** | ·→· | 3→6 | 3→8 | ·→· | ·→· | ·→· | 3→2 | 4→2 | 2→1 |
| **tira** | ·→· | 9→· | ·→· | ·→· | ·→· | ·→· | 8→4 | ·→3 | 3→2 |

Abbreviazioni: `c.man` cavalleria_manovrata, `c.ric` cavalleria_ricognizione, `f.leg` fanteria_leggera, `f.pes` fanteria_pesante, `guar` guardia_elite, `m.ass` macchina_assedio, `m.tir` macchina_tiro, `piat` piattaforma_trainata, `tira` tiratori.

Letture. La colonna `guar` è ora TUTTA `·`: l'elitario non raggiunge mai la propria soglia perché non ne ha (RDA-88). I bersagli pesanti reggono molto più a lungo: `f.pes` vs `f.pes` passa da 5 a 11 scambi, `m.ass` vs `m.ass` da 1 a 8. I bersagli da tiro si sfilano prima (verso 1–3 scambi). **I turni-distruzione a soglia disattivata NON cambiano in alcuno dei 162 accoppiamenti** (verificato dallo script: 0 su 162): la taratura ha spostato il momento del disingaggio, non la capacità di distruggere, che dipende dal danno e non dalle soglie. Il divario fra i turni-soglia e i turni-distruzione, che l'incarico 09 aveva misurato, si legge accostando questa matrice ai turni-distruzione invariati della sezione `mischia_accoppiamenti`.

---

## Come si è lavorato

Strumento della misura: `StrumentoVerifica` (bersaglio SwiftPM). Comando delle sezioni della mischia: `cd Codice && swift run -c release StrumentoVerifica --senza-campagna --uscita <dir>`. Sezioni nuove di questa sessione: `mischia_fasce` (separazione delle fasce) e `secondo_contatto` (esame congiunto). Blocco unico `mischia_riepilogo`, pareggiato con le righe di dettaglio da `MisuraMischiaTest.test_incarico09_il_riepilogo_mischia_pareggia_con_le_righe_di_dettaglio` (RDA-71). Ogni numero citato viene da quel blocco o dalle sezioni di dettaglio nominate.

Commit dell'implementazione: `9007b96` sul ramo dedicato `soglie-e-logoramento`, merge su `principale` in `bcf34e4`. Collaudo verde: 249 prove del pacchetto (erano 242), 1 saltata, 0 fallimenti (`swift test`), più le prove ospitate e d'interfaccia sul simulatore (`scripts/collaudo-completo.sh`, exit 0).

## Che cosa è stato realizzato

**Ritaratura sulle tre fasce** (RDA-87). Tabella 1. Valori nei dati, PROVVISORI.

**Assenza di soglia per l'elitario** (RDA-88). `DefinizioneArchetipo.sogliaDisingaggio` è `Scalato?`; la chiave `soglia_disingaggio` è omessa per il solo `guardia_elite`. Assente = elitario: il ramo di disingaggio in `MotoreBattaglia.risolvi` salta lo sciame a soglia nil. La rappresentazione precedente ammetteva solo un valore in (0,1] e non l'assenza: dichiarato e realizzato come assenza leggibile (nil), non come valore estremo. Cancello `DisingaggioElitarioTest.test_incarico10_l_elitario_non_si_sfila_mai_automaticamente` (l'elitario supera il 25% delle perdite restando ingaggiato e prosegue fino alla distruzione senza sfilarsi), visto fallire dando all'elitario una soglia.

**Disingaggio su ordine** (RDA-89). `ComandoBattaglia.disingaggiaSuOrdine(sciame:)`, valido solo per l'elitario (soglia nil) a contatto e con una cella arretrata libera; respinto per ogni altro reparto e per l'elitario non impegnato, sicché la schermata non lo offre mai. Applicazione: `eseguiRitrazione`, comune al disingaggio automatico. Voce di pannello in `SchermataBattaglia.apriPannello`, condizionata a `motore.valida(...)`; testo `pannello.disingaggia` = «Disingaggia dalla mischia» (annuncio, non termine del vocabolario chiuso); evento riusato `.disingaggio`, quindi l'annuncio scatta senza nuovo lavoro sui Segnali. Nuovo caso in `ComandoBattaglia` con lo specchio in `CompatibilitaGiornaleTest` e il campione nel giornale d'oro (RDA-79). Cancelli: `DisingaggioElitarioTest.test_incarico10_disingaggio_su_ordine_solo_elitario_a_contatto` (Motore) e `PannelloAzioniTest.test_incarico10_il_disingaggio_su_ordine_non_si_offre_a_reparto_ordinario` (interfaccia). Il tattico non usa l'azione: resta strumento del giocatore.

Eccezione dichiarata e coerente, iscritta in RDA-89 perché nessuna revisione la tolga: la perdita di controllo (01 §9.5) nasce dal fatto che le truppe antiche a contatto non obbedivano; la truppa scelta è quella che obbedisce anche in mischia, quindi l'eccezione è coerente con la ragione della regola, non una deroga.

**Coefficiente di logoramento** (RDA-90). Formula unica `MotoreBattaglia.sogliaDisingaggioEffettiva(base:sciame:consistenzaIngresso:)` = base × (1 − coeff × (1 − integrità)), integrità = consistenza d'ingresso nel contatto sulla consistenza piena. Coefficiente `coefficiente_logoramento_soglia` = 0,5 nei dati, PROVVISORIO. Non si applica all'elitario (soglia nil). Cancello `DisingaggioElitarioTest.test_incarico10_il_logoramento_abbassa_la_soglia_del_reparto_gia_logorato`.

## L'esame congiunto con la regola del secondo contatto (misurato, non deciso)

Realizzazione della misura (RDA-91): la regola del secondo contatto (01 §9.8.3) è resa condizionata dall'interruttore `soglia_al_secondo_contatto` nei dati (booleano, PROVVISORIO, FALSO = comportamento distribuito, la regola presente); a vero la soglia opera anche al secondo contatto, con il coefficiente di logoramento. Il gioco onora l'interruttore: non è un canale di sola misura. Cancello `MisuraMischiaTest.test_incarico10_l_interruttore_del_secondo_contatto_cambia_il_disingaggio`, che vede entrambi gli stati (regola presente: si combatte fino alla dispersione; regola tolta: il reparto si sfila di nuovo).

Misura di quanto la regola è esercitata (sezioni `provenienza_perdite` e `secondo_contatto`; conteggi dal blocco `mischia_riepilogo`).

- **Oggi** (soglie vecchie, nessun coefficiente, regola presente): `reingaggi_totali` = **136** su 80 battaglie generate, in **55** battaglie (`battaglie_con_almeno_un_reingaggio`); `disingaggi_automatici_totali` = **275**. La regola era molto esercitata.
- **Dopo** (soglie nuove, coefficiente attivo, regola presente): `reingaggi_totali` = **101**, `disingaggi_automatici_totali` = **208**. Le soglie alte fanno sfilare meno i pesanti, che è la causa della spola: i reingaggi calano già per la sola ritaratura.
- **Esame congiunto** (sezione `secondo_contatto`, sulle 32 sessioni complete di battaglia, coefficiente attivo). Regola PRESENTE: 34 reingaggi, 67 disingaggi, 36 distruzioni in mischia, 24 su 32 concluse. Regola TOLTA: 36 reingaggi, 76 disingaggi, 32 distruzioni in mischia, 24 su 32 concluse.

Che cosa mostrano. Con la regola tolta i disingaggi salgono (76 contro 67, perché una coppia già staccata può sfilarsi di nuovo) e le distruzioni in mischia calano (32 contro 36, perché si sfila invece di combattere fino alla morte); i reingaggi restano quasi uguali (36 contro 34) e le battaglie concludono nella stessa misura (24 su 32 in entrambe). **Nessuna delle due è manifestamente rotta**: con la regola presente un reparto già staccato combatte fino alla dispersione ma non fa la spola; con la regola tolta si sfila di nuovo, con la soglia abbassata dal logoramento, ma non resta bloccato in mischia. La scelta fra conservare entrambe, il solo coefficiente, o la sola regola è del titolare; questi sono i numeri. Non la traggo io.

## Le altre misure, rifatte sui valori nuovi (prima accanto a dopo)

Blocco `mischia_riepilogo`. PRIMA = commit 89fd913 (via `--valori`); DOPO = valori nuovi.

| voce | PRIMA | DOPO |
|---|---|---|
| duelli per disingaggio (`fotografia_disingaggio`) | 154 | 146 |
| duelli per distruzione (disfatta bersaglio/attaccante/reciproca) | 4 / 4 / 0 | 7 / 7 / 2 |
| durata contatto, scambi massimi (`contatto_scambi_massimo`) | 11 | 16 |
| perdite di chi si sfila, mediana permille (`disingaggio_perdite_permille_mediana`) | 377 | 502 |
| accoppiamenti soglia prima della distruzione (`accoppiamenti_soglia_scatta_prima_della_distruzione`) | 115 | 96 |
| perdite da tiro / mischia, permille (`perdite_da_tiro_permille` / `perdite_da_mischia_permille`) | 336 / 663 | 325 / 674 |
| battaglie senza distruzione in mischia (`battaglie_senza_distruzione_in_mischia`) | 19 | 17 |
| accerchiamento, scambi per distruggere 1 assalitore → massimo (`accerchiamento_scambi_distruzione_uno_assalitore` / `_massimo_assalitori`) | 14 → 1 | 14 → 1 |

Letture. I duelli che finiscono per distruzione RADDOPPIANO (da 8 a 16 su 162): le mischie possono ora concludersi con la distruzione, che era l'intento. Chi si sfila ha perso in mediana il 50,2% invece del 37,7%: i reparti reggono di più prima di cedere. Il peso congiunto di accerchiamento e limite dei bersagli è invariato (14 scambi 1v1 → 1 scambio con quattro assalitori): la taratura delle soglie non lo tocca, come previsto. La ripartizione tiro/mischia resta dominata dalla mischia (674 permille), spostata di poco.

## Verifica che la ritaratura non abbia rotto altro

Sezione `scontri` (48 scontri del banco). **Nessuna battaglia non conclusa** (0 su 48). **Nessuna oltre il tetto**: giri massimi 17, il tetto è 80/60. **Vantaggio di chi muove per primo INVARIATO**: su tutti e 48 gli scontri il primo occupante vince nel 43% dei casi PRIMA e nel 41% DOPO (calcolato dallo script sulla colonna `sconfitto` di `scontri.csv`, PRIMA da 89fd913, DOPO dai valori nuovi); era già intorno alla metà — anzi lievemente sotto — e resta dov'era. La taratura non ha spostato nessuna delle tre grandezze.

## Che cosa dichiarare al giocatore

- **La soglia non è dichiarata fra le informazioni del reparto**, oggi. Verificato: `CostruttoreAnnunci.contenutoCella` non legge `sogliaDisingaggio`; nessun annuncio di stato la riporta. NON realizzato in questa sessione, per prescrizione dell'incarico (dichiarare senza realizzare). Registrato come scostamento S13.
- **Le due condizioni «non si sfila mai» (elitario) e «può sfilarsi su ordine» non sono comunicate prima dell'ingaggio.** Oggi il giocatore sente lo stato di un reparto (nome, lettera, `controllo.impegnato`, munizioni, atomi in verbosità dettagliata) ma non la soglia né la condizione elitaria. Renderle percepibili NON richiede termini nuovi del vocabolario chiuso — la soglia è un numero o una fascia, l'elitario è il nome del reparto — ma richiede di aggiungerle a `contenutoCella`, lavoro di un incarico proprio. Registrato in S13. Nessun termine è stato aggiunto al vocabolario chiuso in questa sessione.

## La versione dei valori e i salvataggi incompatibili

Versione dei valori da 0.5.0 a **0.6.0** (`Contenuti/Valori/manifest.json`), `versioni_compatibili` ridotte a `["0.6.0"]`. Valutazione esplicita: le regole della mischia cambiano come una partita in corso si svolgerebbe (i disingaggi automatici sono diversi), quindi un salvataggio 0.4.0/0.5.0 rigiocato con le regole nuove ricostruirebbe uno stato sbagliato. Tali salvataggi sono dichiarati incompatibili e la ripresa li RIFIUTA con `ErroreSessione.salvataggioIncompatibile` invece di aprirli in silenzio (00 §15.2). Cancello nuovo `SalvataggioBuildDistribuitaTest.test_00_15_un_salvataggio_di_versione_incompatibile_si_dichiara`. Copioni d'oro e salvataggio della build distribuita rigenerati a 0.6.0 (`RigenerazioneOroTest`, esteso per rigenerare anche il prefisso a battaglia in corso).

## Il caricamento

Build **17** caricata su TestFlight con `scripts/carica-testflight.sh` (exit 0; UPLOAD SUCCEEDED, Delivery UUID 3b6e9a45-3a84-445e-acd5-217690b05222). Cancelli preventivi superati nell'ordine: versione di marketing (1.1.0, non toccata, pari alla più alta — si procede); note (`controlla-note.py`: lunghezza 2709/4000, misure pari al tool, cifre a posto, freschezza al commit); registro build concorde; sessioni complete fresche («successo» su `bcf34e4`); collaudo completo verde (pacchetto + interfaccia). La corsa separata delle sessioni complete è stata rieseguita sul codice nuovo prima del caricamento (`scripts/esegui-sessioni-complete.sh`, esito «successo», commit `bcf34e4`).

Verifica per interfaccia di programmazione (`scripts/asc_api.py`, sola lettura), presa in isolamento dopo il caricamento:

- `GET /v1/builds?filter[app]=6797306323&sort=-version&include=preReleaseVersion`: build **17** stato **VALID**, treno **1.1.0** (il più alto), non scaduta.
- `scripts/controlla-build.py`: «registro e App Store Connect concordano: 17 build, la più alta è la 17» — il registro `build-caricate.md` concorda con i server in entrambi i versi.
- `GET /v1/betaGroups`: gruppo **WarLab**, interno, `hasAccessToAllBuilds` vero — la build 17 gli arriva da sé, nessuna assegnazione manuale (`memoria-infrastruttura.md`).

Le due note sono rigenerate: `note-di-rilascio.txt` (allegata alla build 17, 2709 caratteri) e `nota-per-il-titolare-mischia.md` (rinominata da `nota-per-il-titolare-mappa.md`), che dichiara in linguaggio non tecnico che cosa provare: i pesanti reggono più a lungo dei tiratori prima di sfilarsi, le mischie possono concludersi con la distruzione, la guardia scelta si ritira dal contatto su ordine.

Certificati e profili non toccati; nessun `-allowProvisioningUpdates`; la versione di marketing non toccata.

## Registrazioni

Registrato nel registro delle decisioni architetturali: RDA-87 (tre fasce e ordinamento), RDA-88 (assenza di soglia per l'elitario), RDA-89 (disingaggio su ordine, con la ragione della coerenza), RDA-90 (coefficiente di logoramento), RDA-91 (esame congiunto e versione dei valori). Registrati fra i valori provvisori: le tre soglie di fascia, il coefficiente di logoramento, l'interruttore del secondo contatto. Registrato come scostamento S13: le modifiche a 01 §9.5/§9.8/§9.8.3 e la soglia non dichiarata al giocatore.

## Aritmetica

Ogni totale del confronto viene dal blocco `mischia_riepilogo`, pareggiato con le righe di dettaglio dalla prova RDA-71. Le celle delle due matrici sono trascrizione riga-per-riga di `mischia_accoppiamenti.csv` (PRIMA e DOPO) via script. I conteggi di reingaggi e disingaggi vengono dal blocco (`reingaggi_totali`, `disingaggi_automatici_totali`), pareggiati con le righe di `provenienza_perdite` dalla stessa prova. Il vantaggio del primo occupante (43% / 41%) è aggregazione via script della colonna `sconfitto` di `scontri.csv`, dichiarata come tale. Nessuna somma a mente.

## Che cosa ho fatto e l'incarico non chiedeva

- Ho ricostruito i valori PRIMA (soglie di 89fd913 con i due campi nuovi neutri) per produrre il confronto per accoppiamento e il vantaggio del primo occupante sullo STESSO strumento, invece di citare i numeri del resoconto 09.
- Ho esteso `RigenerazioneOroTest` perché rigeneri anche il salvataggio della build distribuita (prefisso a battaglia in corso del primo oro), che altrimenti sarebbe rimasto a 0.4.0 e incompatibile.
- Ho aggiunto il cancello dell'incompatibilità dichiarata dei salvataggi, che prima non esisteva come prova.

## Che cosa l'incarico chiedeva e non ho fatto

- La prova d'interfaccia del caso POSITIVO del disingaggio su ordine (l'azione COMPARE per l'elitario a contatto) non è realizzata in interfaccia, perché il deck dello scenario di prova non contiene `guardia_elite` e `PartitaCorrente(nuova:)` non permette d'iniettare uno scenario. Il caso positivo è coperto al Motore (`DisingaggioElitarioTest`, la validazione ammette l'azione solo per l'elitario a contatto) e la voce del pannello è offerta se e solo se `motore.valida` è valido; l'interfaccia prova il caso negativo (nessun reparto ordinario riceve l'azione). Dichiarato non coperto in interfaccia per il caso positivo.

## Che cosa non ho toccato

Non ho toccato la versione di marketing (1.1.0). Non ho creato bersagli firmabili, identificatori di pacchetto o profili nuovi. Non ho creato, revocato o modificato alcun certificato. Non ho indebolito la meccanica del disingaggio né l'ho resa costosa (il disingaggio su ordine è gratuito). Non ho esteso l'eccezione ad alcun reparto diverso dall'elitario. Non ho introdotto estrazioni del caso né tabelle a doppia entrata. Non ho riaperto decisioni prese (ordine dei turni, risoluzione immediata, limite dei bersagli, assenza di fuoco amico, annuncio in fasce). Non ho esteso il perimetro del gioco. Non sono intervenuto sulla cornice riportata dall'accessibilità né sulla prova di raggiungibilità.
