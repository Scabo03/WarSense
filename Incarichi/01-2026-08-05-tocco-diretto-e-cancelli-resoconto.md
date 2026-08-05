# Resoconto — Tocco diretto, impianto di prova sul simulatore, tre cancelli

Commit della sessione, dal più vecchio: `4d53578`, `c480b99`, `40c55a9` (fusione sul ramo `principale`), `fbaaae1`. Ramo di lavoro `tocco-diretto-e-cancelli`, fuso senza avanzamento veloce.

Collaudo alla chiusura, da `./scripts/collaudo-completo.sh`: **218 prove del pacchetto (una saltata), 50 ospitate, 8 d'interfaccia, zero fallimenti.** Conteggi ottenuti con `grep -h "func test" <cartella>/*.swift | wc -l` e confermati dall'esecutore.

**Non è stata caricata alcuna build.** La sezione 5 non è chiusa; l'incarico prescrive di non caricare in quel caso. Nessuna versione di marketing toccata, nessun certificato, nessun profilo, nessun identificatore.

**La sezione 6 non è stata cominciata.** Vedi in coda.

---

## 1. I tre cancelli, e la condizione in cui ciascuno è stato visto rifiutare

### 1.1 Il collaudo completo

`scripts/collaudo-completo.sh` è ora la sola sede in cui «tutto il collaudo» è definito: prove del pacchetto, `xcodegen generate`, prove ospitate e d'interfaccia sul simulatore. Lo invocano `.github/workflows/collaudo.yml` e `scripts/carica-testflight.sh`, che prima elencavano ciascuno i propri passi e si fermavano entrambi a `swift test`. Il simulatore non si sceglie per nome: lo script prende il primo iPhone disponibile (`xcrun simctl list devices available --json`), e `WARSENSE_SIMULATORE` permette di imporne uno.

**Visto rifiutare.** Guastando `RaggiungibilitaTest` (atteso `100 + 1 + vociDeck + 5` invece di `+ 4`), lo script si è fermato con **codice di uscita 65** e la riga `Failing tests: RaggiungibilitaTest.test_02_2_8_l_ordine_di_lettura_e_quello_dichiarato_ed_e_completo()`. Guasto rimosso con `git checkout`.

**Non verificato:** che il workflow giri su `macos-15`. Ho verificato in locale il comando che il workflow esegue, non il workflow. Il passo `brew install xcodegen` e la disponibilità di un simulatore sul corridore restano da vedere alla prima integrazione.

Corretta `memoria-infrastruttura.md` riga 95, che presentava come protezione il fatto che i bersagli di prova dell'applicazione non potessero rompere una consegna: non potevano perché non venivano eseguiti. Corretta anche la descrizione dei passi dello script alla riga 52.

### 1.2 La codifica del giornale (RDA-79)

`CompatibilitaGiornaleTest` lega ciascuno dei tre tipi del formato di salvataggio — `VoceGiornale`, `ComandoBattaglia`, `ComandoCampagna` — a uno specchio privo di valori associati e quindi `CaseIterable`, con due funzioni totali ed esaustive per coppia: `specie(di:)` dal tipo vero allo specchio, `esemplare(di:)` dallo specchio al tipo vero.

**Visto rifiutare, anello per anello**, aggiungendo `case revocaMarcia(gruppo: Int)` a `VoceGiornale`:

1. `specie(di:)` → `CompatibilitaGiornaleTest.swift:65:9: error: switch must be exhaustive`.
2. Aggiunto il caso allo specchio: `esemplare(di:)` → `CompatibilitaGiornaleTest.swift:81:9: error: switch must be exhaustive`.
3. Costruito l'esemplare: la prova fallisce con `XCTAssertEqual failed … un caso di VoceGiornale è privo di campione`.

Due anelli su tre sono errori di compilazione. Caso finto rimosso, `Giornale.swift` ripristinato con `git checkout`.

**Correzione a `esame-critico.md`, che su questo punto era troppo generoso.** L'esame aveva concluso che per `ComandoBattaglia` e `ComandoCampagna` la protezione fosse forte grazie allo `switch` esaustivo di `etichettaCaso`. Non lo era: l'esaustività obbligava a NOMINARE il caso nuovo, non a dargli un campione, e l'insieme atteso restava un letterale scritto a mano. **La prova non esercitava la protezione su nessuno dei tre tipi.** Corretta la riga 219 di `stato-avanzamento.md`, che ora dichiara anche che cosa non faceva.

### 1.3 La nota per il titolare (RDA-80)

`nota-per-il-titolare-mappa.md` rigenerata sul comportamento attuale. Le quattro affermazioni false individuate dall'esame critico sono corrette: il registro contiene ora gli ordini e non le sole aperture di giornata; le voci con un luogo si attivano e portano il fuoco sulla casella; l'annullamento non risale oltre la giornata in corso; il numero dei gesti è 106 e non 109.

`scripts/controlla-nota-titolare.py` rifiuta il caricamento in quattro condizioni, tutte viste rifiutare:

| controllo | condizione provata | messaggio |
|---|---|---|
| esistenza | nota spostata fuori dalla cartella | «non esiste alcuna nota-per-il-titolare-\*.md» |
| vocabolario | «Attiva per portare il fuoco…» spezzata su due righe; «su comando del giocatore» citata fra virgolette basse | «nomina «…», che il codice non espone» |
| misure | `senza_il_salto=109`, cioè il numero che la nota vecchia portava | «dichiara senza_il_salto=109 …, ma il programma di verifica stampa 106» |
| cifre | «dopo 12 giornate» | «contiene il numero 12, che non proviene da alcuna misura dichiarata» |
| freschezza | nota non ancora committata dopo le modifiche al codice | «la nota è più vecchia dell'ultimo commit che ha toccato il codice» |

**Che cosa il cancello verifica.** (a) Che la nota esista e non sia vuota. (b) Che ogni nome citato fra virgolette basse sia il valore di una chiave dei cataloghi `Annunci.strings` o `Vocabolario.strings` — con i segnaposto trattati come riempimento qualunque — oppure uno dei gesti dichiarati nello script, il cui metodo (`accessibilityPerformMagicTap`, `accessibilityPerformEscape`) deve esistere nei sorgenti. Sedici nomi citati oggi, tutti risolti. (c) Che ogni misura dichiarata in coda alla nota coincida con ciò che `swift run StrumentoVerifica` stampa **adesso**, e che il valore compaia nel corpo. (d) Che nessun numero di due cifre o più compaia nel corpo senza provenire da una misura dichiarata o dall'elenco delle grandezze di struttura. (e) Che la nota non sia più vecchia dell'ultimo commit che ha toccato `Applicazione/Sorgenti` o `Codice/Sources`.

**Che cosa resta fuori dalla sua portata, e non va taciuto.** Le affermazioni di COMPORTAMENTO in prosa — «il registro contiene ciò che avviene», «annullando si riapre la giornata» — non sono riducibili a un nome né a un numero, e nessun controllo automatico le giudica. Su quelle agisce il solo controllo di freschezza, che obbliga a rileggerle a ogni modifica del codice: ed è precisamente il controllo che avrebbe impedito tutte e quattro le affermazioni false, perché nessuna era un errore di misura e tutte erano affermazioni divenute false sotto una nota che nessuno rileggeva. Nota di disegno: le modifiche alle sole PROVE non fanno scattare la freschezza, perché non cambiano il comportamento che la nota descrive.

Il controllo del solo vocabolario gira anche in integrazione continua; gli altri tre al caricamento, dove la nota viene consegnata.

### 1.4 Gli incarichi conservati

`Incarichi/` con il `README.md` che ne fissa la regola, l'incarico di questa sessione verbatim e questo resoconto.

---

## 2. Il tocco diretto

**Causa.** Le caselle di entrambe le griglie erano elementi accessibili sintetici (`UIAccessibilityElement`) dentro una `UIView` priva di qualunque riconoscitore di gesto. Rispondevano ad `accessibilityActivate`, cioè al doppio tocco della tecnologia assistiva, e a nient'altro. L'osservazione era registrata come P11 dal 2026-08-04, con il rimedio già indicato e mai realizzato.

**Correzione.** `Applicazione/Sorgenti/VistaACaselle.swift`, base condivisa da cui `VistaGriglia` e `VistaMappa` ora ereditano. Il riconoscitore risolve il punto nell'elemento la cui `accessibilityFrameInContainerSpace` lo contiene e ne invoca `accessibilityActivate()` — esattamente il metodo che la tecnologia assistiva invoca. Non esiste un secondo ramo da tenere allineato: le due porte sono la stessa porta. La base è una sola per i due piani, quindi la divergenza che P11 temeva non è scrivibile.

La differenza rispetto al rimedio che P11 proponeva (chiamare `attiva(_:)` sulla schermata) è deliberata ed è registrata in RDA-78: quella forma avrebbe lasciato due percorsi paralleli, cioè una regola scritta al posto di uno stato reso impossibile.

RDA-78 registra anche la delimitazione rispetto a 02 §2.12, che esclude dalla prima versione l'esplorazione libera a tocco diretto: quella riceve i tocchi grezzi per ANNUNCIARE ciò che il dito attraversa ed è una modalità di lettura; qui il tocco ATTIVA, come su qualunque controllo, e `TesseraDeck` lo faceva già dalla fase B nel verso opposto. La voce esiste perché è il punto su cui una sessione futura potrebbe citare 02 §2.12 per disfare la correzione.

**La prova che falliva prima.** `ToccoDirettoTest.test_02_2_11_le_due_griglie_hanno_un_percorso_per_il_tocco_diretto`. Non usa alcuna interfaccia nuova: interroga `isUserInteractionEnabled` e `gestureRecognizers`. Con il riconoscitore disinstallato fallisce su **entrambi i piani**, con i due messaggi distinti «mappa di campagna: nessun riconoscitore di tocco» e «griglia di battaglia: nessun riconoscitore di tocco».

**Il fuoco.** `ToccoDirettoTest.test_00_11_1_dopo_un_ordine_al_dito_gli_elementi_restano_e_il_fuoco_non_si_muove`: dopo un presidio ordinato al dito gli elementi hanno la stessa identità di oggetto (nessuna ricreazione, 05 §10.1, RDA-03) e il registro del guardiano non contiene alcun `.schermataAperta`, cioè nessuno spostamento che riporterebbe la voce all'inizio. Verde.

**Prove esistenti dipendenti dal comportamento vecchio: nessuna.** Le 42 prove ospitate e le 2 d'interfaccia preesistenti passano tutte dopo l'intervento. `FumoMappaCampagnaTest` conteneva un commento che dichiarava di non provare l'attivazione perché le caselle non rispondevano al tocco grezzo: il commento è ora superato, la prova no.

Le sette prove nuove di `ToccoDirettoTest` coprono, con lo stesso corpo sui due piani: l'esistenza del percorso, l'equivalenza dei due pannelli, la casella vuota che non attiva nulla, il margine della vista che non attiva nulla, il fuoco dopo un ordine al dito, e — prova generale — che ogni elemento dichiarato sia risolvibile dal punto del proprio centro, sicché un elemento futuro raggiungibile da una porta sola fallisca senza che nessuno debba ricordarsene.

---

## 3. L'impianto di prova sul simulatore — consegnato incompleto

### Che cosa verifica, prova per prova

`Applicazione/ProveInterfaccia/ImpiantoInterfacciaTest.swift`, sei prove attraverso il servizio di accessibilità reale:

| prova | requisito | che cosa verifica |
|---|---|---|
| `test_00_2_3_ogni_elemento_esposto_ha_nome_ed_e_raggiungibile` | 00 §2.3, 00 §1.2 | nessun elemento senza nome; nessun comando dichiarato e non colpibile |
| `test_02_2_8_ogni_elemento_dichiarato_esiste_nell_albero_dell_accessibilita` | 02 §2.8 | le sedici caselle e i quattro comandi globali esistono davvero nell'albero che la tecnologia assistiva vede |
| `test_00_14_2_nessuna_etichetta_porta_segnaposto_o_chiavi_non_risolte` | 00 §14.2, 00 §9.1 | nessuna etichetta o valore con `%@`, `%d`, `%lld`, `%1$`, né con la forma di una chiave di testo |
| `test_02_6_7_da_ogni_schermata_si_torna_indietro` | 02 §6.7, P5 | registro aperto e chiuso; pannello aperto AL TOCCO DIRETTO e chiuso senza congedare la schermata; ritorno all'avvio |
| `test_01_5_6_un_ordine_dato_al_dito_arriva_al_gioco` | 01 §5.6, 01 §5.16.1, S8 | si tocca la casella del gruppo, si sceglie il presidio, lo stato del gruppo cambia e il registro annota il fatto |
| `test_00_11_1_dopo_un_ordine_la_schermata_resta_e_gli_elementi_no_spariscono` | 00 §11.1, RDA-03 | la schermata non viene sostituita; al più una etichetta cambia |

`Applicazione/ProveOspitate/CatenaInterfacciaMotoreTest.swift`, una prova: `test_00_9_1_l_etichetta_esposta_coincide_con_quella_che_il_motore_prescrive` — per ciascuno dei tre formati e per ogni casella, l'`accessibilityLabel` dell'elemento è identica a quella che `CostruttoreAnnunciCampagna` ricava dallo stato del Motore. È il controllo che i due piani non divergano.

### Che cosa l'impianto NON può verificare

Enunciato nell'intestazione della classe e in `collaudo-solo-dispositivo.md`, voci 14–17: la pronuncia; il fuoco vero di VoiceOver (osservabile solo come «la schermata non è stata sostituita», che è condizione necessaria e non sufficiente); la comprensibilità di una frase e l'orientabilità della mappa; l'aptica e i suoni.

### Le due verifiche che l'incarico chiedeva e che NON sono state consegnate

Registrate come scostamento **S10**, con le sonde e ciò che resta ignoto.

**La catena intera.** Una partita giocata dall'interfaccia contro la stessa sequenza applicata direttamente. Scritta in quattro forme, mai verde. Fatto misurato: `VistaACaselle.attivaAlTocco` sulla casella di destinazione di una marcia designata restituisce `true`, quindi l'elemento è risolto e `accessibilityActivate` invocato, ma lo stato del gruppo non risulta speso entro cinque secondi. Le stesse marce ordinate con `PartitaCampagna.esegui` funzionano. Il sospetto — che lo stato conservato dalla schermata sia più vecchio di quello della Sessione quando `comandoDiMarcia` calcola il costo in giorni, e che il comando venga respinto per `costoNonPrescritto` — **non è stato accertato** e non va riportato come se lo fosse. Il primo passo per chi riprende è leggere il motivo del rifiuto, che `eseguiComando` oggi annuncia e non registra.

**Il tocco sintetizzato su una griglia scorrevole.** Escluso con sonda in processo che il riconoscitore sia in causa: `finestra.hitTest` sul centro della cella di riga 8 restituisce `VistaGriglia` e `elemento(sotto:)` la risolve. Escluso `delaysContentTouches`, portato a falso senza effetto e poi ritirato perché nessuna prova lo giustificava. Resta ignoto perché un tocco XCUITest su una cella dentro la porzione visibile di una griglia scorrevole non produca l'effetto, mentre lo produce sulla mappa quattro per quattro, che scorrevole non è.

**Emerso per strada, e vero.** La cornice che il servizio di accessibilità riporta per una casella fuori dalla porzione visibile è la sua posizione nel contenuto, non sullo schermo: sulla mappa grande il centro della casella del proprio gruppo cade dove è disegnato un comando globale, e `hitTest` vi restituisce un `UIButton`. Il dito, a differenza della voce, non ha scorrimento automatico. Non viola 02 §2.11 — tutto resta raggiungibile in entrambi i modi — ma è un'asimmetria di comodità da provare sul dispositivo, ed è entrata in `collaudo-solo-dispositivo.md`.

**Un limite misurato e dichiarato invece che aggirato.** `XCUIApplication.descendants` non restituisce l'ordine di lettura: percorre la gerarchia delle viste e ignora `accessibilityElements`. Sulla mappa piccola i quattro comandi globali compaiono agli indici 6–9, prima delle sedici caselle agli indici 10–25, mentre l'ordine dichiarato li mette in coda. L'ordine effettivo resta verificato dalle prove ospitate, che leggono `accessibilityElements`; l'impianto d'interfaccia verifica la completezza dell'albero, che le ospitate non possono verificare.

**Le due prove sono state tolte, non adattate fino a passare.** Una prova che passa senza verificare è peggio di una prova assente, perché la sua assenza almeno si vede.

---

## 4. Le partite simulate — non cominciate

Sesta sezione dell'incarico. Non aperta. L'incarico prescriveva di non comprimere le sezioni finali per arrivare in fondo e di fermarsi al confine dell'ultima sezione conclusa: mi sono fermato lì.

## 5. Da dove si riprende

1. **S10, prima cosa mancante**: la catena intera. Leggere il motivo del rifiuto in `SchermataMappaCampagna.eseguiComando`, che oggi lo annuncia e non lo registra.
2. **S10, seconda cosa mancante**: il tocco sintetizzato su griglia scorrevole.
3. **Sezione 6 dell'incarico**: le partite simulate, intatta.

## 6. Stato su App Store Connect

Nessun caricamento. `MARKETING_VERSION` resta `1.1.0` in `Applicazione/project.yml`, non toccata. Versione dei valori `0.5.0`, non toccata. Ultima build su TestFlight: la 12, invariata da questa sessione. Nessun certificato, profilo o identificatore creato, revocato o modificato.
