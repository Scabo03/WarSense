Resoconto — Composizione dei gruppi e volume, e le quattro correzioni sulla marcia (incarico 15)

## Le frasi vere che il giocatore sente

Sono i termini risolti dal pacchetto `it.lproj/Annunci.strings` e `.stringsdict`, con valori d'esempio; il plurale è del meccanismo di sistema.

Ordinando una marcia. Portato il fuoco sulla casella di destinazione, durante la designazione, l'etichetta vocale della casella (`CostruttoreAnnunciCampagna.etichettaCasella`, ramo `.valido`, giunte con «, ») è: «raggiungibile in 2 giorni di marcia, il gruppo resterà fermo fino all'arrivo e non potrà sfilarsi senza perdere i giorni spesi, riga 3, casella 4, libera». Attivandola — che ora È l'ordine, senza pannello — il giocatore sente la conferma immediata: «Corvo marcia verso riga 3, casella 4, 2 giorni al termine». All'arrivo, alla risoluzione di fine giornata: «Corvo è arrivato in riga 3, casella 4»; e nel registro «Giorno 5: Corvo è arrivato in riga 3, casella 4».

Revocandola. Sul gruppo in marcia il pannello di conferma della revoca — l'unico rimasto — dichiara: «Revoca la marcia di Corvo. Perdi 2 giorni e il gruppo resta senza azione oggi.» Confermata, l'annuncio è «Corvo: marcia revocata, persi 2 giorni», e il registro porta «Giorno 5: Corvo revoca la marcia in riga 3, casella 4».

Dividendo un gruppo, riunendolo, e quando il rifornimento si interrompe e riprende. NON REALIZZATE in questa sessione. La divisione e la riunione (blocco 3) e il rifornimento con il taglio, le zone, l'autonomia e la sosta (blocco 4) non sono state costruite: non esistono frasi da riportare, e nessuna è stata aggiunta al vocabolario chiuso. Vedi «Ciò che l'incarico chiedeva e non è stato fatto».

## Ambito effettivo della sessione, e perché

L'incarico prescrive un ordine interno non indifferente: «Costruisci per prima la composizione dei gruppi e il volume». Quella è stata costruita per prima (blocco 1). Sono poi state eseguite le quattro correzioni del titolare sulla marcia (blocco 2). La sessione si è fermata al confine del blocco 2, come l'incarico consente («se la capacità della sessione non basta a portare un blocco fino alla sua prova superata ci si ferma al confine del blocco precedente dichiarando da dove si riprende»). La divisione e la riunione (blocco 3) e il rifornimento con il taglio (blocco 4) NON sono state iniziate: nessuna riga di codice parziale le riguarda. La build NON è stata caricata, perché il caricamento è condizionato dall'incarico all'essere «il lavoro chiuso e l'intero collaudo verde», e il lavoro non è chiuso.

## Blocco 1 — Composizione dei gruppi e volume

Commit `7e174b7`.

Tipi. `Motore/StatoCampagna.swift`: nuovo `Reparto { archetipo: IdentificatoreDati; atomi: Int }`; `Gruppo` acquista `var composizione: [Reparto]` (mai vuota) e la proprietà derivata `atomiTotali`. `Motore/ScenarioCampagna.swift`: `ScenarioCampagna.RepartoIniziale { archetipo; atomi }` e `GruppoIniziale.composizione: [RepartoIniziale]`.

Volume. `MotoreCampagna.volume(di gruppo: Gruppo) -> Int64` = somma sui reparti di `atomi × archetipi[archetipo].volumePerAtomo`. Non è un campo dello stato: derivarlo rende impossibile la divergenza dalla composizione. Accertamento sull'omonimia col volume di battaglia — ESITO: è la STESSA grandezza, non due omonime (01 §3.4.4: «il volume è il parametro unico … unico e stabile per archetipo»); si legge lo stesso campo `volume_per_atomo` che `MotoreBattaglia.volume(di sciame:)` usa. Ciò che è un'altra cosa, e conserva il proprio nome, è `BilancioVolume`, il budget di manovra della battaglia (01 §9.3): non entra in campagna. Registrato in RDA-103.

Costo della marcia. `MotoreCampagna.costoInGiorni(da:a:stato:)` — firma già definitiva (RDA-75, RDA-99) — legge il volume del gruppo che occupa la casella di partenza e vi somma `volume / soglia_volume_per_giorno_aggiuntivo` (troncamento), sulla medesima grandezza degli altri fattori. Il punto di calcolo non si sposta; `impatto-marcia-lunga.md` §1 è superato.

Dati. `marcia-campagna.json`: nuovo `soglia_volume_per_giorno_aggiuntivo: 250` (PROVVISORIO, `valori-provvisori.md`), rifiutato dal caricatore se minore di uno (`CaricatoreCampagna`, divisore). `scenari-campagna.json` e `Scenari/Campagne/campagne.json`: composizione iniettata per gruppo, in tre fasce di volume (fanteria leggera 6 → 60; leggera 18 + pesante 8 → 292; pesante 24 + cavalleria manovrata 12 → 696), che alla soglia danno zero, uno e due giorni aggiuntivi.

Rifiuti (cancelli visti fallire). `FabbricaCampagna.crea` acquista `archetipiNoti: Set<IdentificatoreDati>` e respinge `gruppoSenzaComposizione`, `repartoVuoto` (atomi ≤ 0) e `archetipoIgnoto` (prova `test_01_5_6_0_2_la_fabbrica_respinge_le_composizioni_non_valide`, `CostoDellaMarciaTest`); il caricatore respinge la soglia < 1 (`test_01_5_6_3_2_una_soglia_di_volume_minore_di_uno_e_respinta`).

Invarianti nuovi, ciascuno col mutante (`Verifica/InvariantiCampagna.swift`, `VerificaTest/InvariantiCampagnaTest.swift`): `gruppo_vuoto` (composizione vuota o reparto a atomi ≤ 0; mutante `test_mutante_un_gruppo_vuoto_viene_visto`) e `volume_incoerente` (volume riportato ≠ somma della composizione, con la tabella `volume_per_atomo` e i volumi riportati dall'esterno, come per la posizione visiva; mutante `test_mutante_un_volume_incoerente_viene_visto`). `SondaInvariantiCampagna.codiciNoti` passa da 20 a 22; la guardia di copertura `test_incarico_6_ogni_invariante_ha_almeno_un_mutante_che_lo_fa_scattare` pretende il mutante per entrambi, nei due versi.

Banco. `BancoCampagna.corri` chiama `controllaVolumi` a ogni passo e la `Corsa` porta `volumeMinimo`/`volumeMassimo`; `ProgrammaDiVerifica` aggiunge le colonne `volume_minimo`/`volume_massimo` alla sezione `campagna_invarianti` e le voci `volume_minimo/massimo_fra_gli_scenari` e `soglia_volume_per_giorno_aggiuntivo` al riepilogo.

Impronta e salvataggio. `Gruppo.codifica` (`ImprontaCampagna.swift`) include la composizione nell'ordine dichiarato dei reparti. `FondazioneCampagna.schemaCorrente` sale da 3 a 4: un giornale di versione 3, i cui gruppi non hanno composizione, non ha da dove leggere il volume e non si riapre (00 §15.2). Il campione `fondazioneCampagna` di `CampioniGiornale/campioni.jsonl` è stato rigenerato con la composizione, nella stessa modifica; `CompatibilitaGiornaleTest` verde. Versione dei valori da 0.8.0 a 0.9.0 (`Valori/manifest.json`, impronte rigenerate con `scripts/rigenera-impronte.py`); `0.8.0` conservata in `versioni_compatibili` perché nulla di battaglia è cambiato e i salvataggi di battaglia restano compatibili, mentre quelli di campagna li dichiara incompatibili il cancello dello schema (prova `SalvataggioBuildDistribuitaTest`, aggiornata perché la fixture della build distribuita è al valore compatibile e non a quello corrente).

## Blocco 2 — Le quattro correzioni del titolare sulla marcia

Commit `2cce19b`. Decisioni del titolare, eseguite come scritte, registrate in RDA-104.

Prima. `SchermataMappaCampagna.attiva`, ramo della designazione `.marcia`, esegue il comando direttamente (`Task { await eseguiComando(comando) }`) invece di aprire `apriPannelloConfermaMarcia`, metodo rimosso. Il pannello di conferma resta per la sola revoca (`apriPannelloConfermaRevoca`, invariato).

Seconda, e la ragione della differenza fra ciò che si vede e ciò che si sente. `CostruttoreAnnunciCampagna.etichettaCasella`, ramo `.valido`, aggiunge alla voce, dopo il costo (`casella.disponibile`), la conseguenza dell'inchiodamento (`casella.inchioda`). Ciò che si vede sulla voce dà destinazione e giorni; l'etichetta vocale aggiunge la conseguenza, perché chi vede riceve la stessa informazione dai nove pallini dell'avanzamento (01 §5.6.3.4) e chi ascolta no. È la parità per due vie diverse, coerente con 01 §5.6.3.5 (conseguenza dichiarata prima della conferma): l'attivazione è la conferma, la voce è la dichiarazione.

Terza. Il pannello di conferma resta per la sola revoca, dove `pannello.revoca_conferma` dichiara i giorni persi e la giornata spesa.

Quarta. Gli ordini di marcia e di presidio escono dal registro. `MotoreCampagna.applica` non chiama più `annota` per gli ordini; `FattoRegistrato` perde i casi `marciaOrdinata` e `presidioOrdinato` (con essi `casiDiRiferimento`, `chiaveTesto`, `luogo`, la codifica in `ImprontaCampagna`, il ramo in `SignificatiCampagna.voceDiRegistro`). Restano nel registro `marciaCompiuta` e `marciaRevocata`, oltre a `ordineAnnullato` e `giornataAzzerata`. Gli EVENTI `marciaOrdinata`/`presidioOrdinato` restano e fanno l'annuncio immediato della conferma. La sonda `SondaSessioneCampagna` cambia il controllo del registro da «voci = ordini + compimenti» a «voci = compimenti». Deroga S8 e previsione di RDA-101 dichiarate SUPERATE (`registro-scostamenti.md`, `registro-decisioni-architetturali.md`).

Testi. Rimossi `pannello.marcia_titolo`, `pannello.marcia_conferma_azione`, `pannello.marcia_conferma`, `registro.marcia_ordinata`, `registro.presidio_ordinato`; aggiunto `casella.inchioda`. Impronte dei testi rigenerate.

Prove riscritte per il comportamento nuovo, non indebolite: `MotoreTest/RegoleCampagnaTest` (il registro non annota gli ordini ma i compimenti), `SessioneTest/AnnullamentoGiornataTest` (fatto di giorno 1 = compimento), `VerificaTest/SessioniCompleteTest` (storia sana: voci = compimenti), le ospitate `MappaCampagnaAccessibileTest` (attivazione ordina diretto; la voce porta costo e inchiodamento; il registro contiene i compimenti col loro luogo, guidando la marcia al compimento con `presidiaFinoAlCompimento`), `AnnuncioDiCasellaTest` (la designazione aggiunge una o due voci, non una sola), `CatenaInterfacciaMotoreTest` e `SessioniPerInterfacciaTest` (l'attivazione ordina diretto), e l'interfaccia `ImpiantoInterfacciaTest` (l'ordine di presidio non compare nel registro).

Difetto latente scoperto e corretto. `CatenaInterfacciaMotoreTest.test_00_3_1` selezionava il prossimo gruppo con `!azioneSpesa`, che include un gruppo in marcia lunga (azione consumata dalla marcia, non dal giocatore): con i volumi diversi del blocco 1 le marce durano più giorni e un gruppo in marcia veniva scelto, offrendo la revoca e non il presidio. Corretto in `!haConclusoLaGiornata`, lo stesso criterio del salto e del rotore.

## I numeri, dal programma di verifica

Prodotti da `swift run StrumentoVerifica`, sezione `campagna_riepilogo` (blocco unico, RDA-71; nessun numero calcolato a mano):

- scenari_di_campagna_generati: 10; giornate_generate_in_totale: 400; ordini_impartiti_in_totale: 2044.
- marce_totali: 940; marce_lunghe_in_totale: 610; marce_compiute_in_totale: 590; revoche_in_totale: 315.
- **violazioni_trovate_in_totale: 0** (nessun invariante violato in 400 giornate generate).
- ordini_a_gruppi_senza_alcuna_destinazione: 360 (lo stipamento è esercitato).
- invarianti_sorvegliati: 22 (erano 20; +`gruppo_vuoto`, +`volume_incoerente`).
- volume_minimo_fra_gli_scenari: 60; volume_massimo_fra_gli_scenari: 696 (differiscono: il banco ha esercitato marce di volumi diversi, non le ha solo rese possibili); soglia_volume_per_giorno_aggiuntivo: 250.
- costo_in_giorni_dello_scatto_base: 1; posizioni_visive_della_marcia: 9; formati_di_mappa: 3; mappe_disponibili: 3; gruppi 1..12; disposizioni: 2.

Collaudo. `swift test`: 279 prove, 1 saltata, 0 fallite (il blocco di riepilogo XCTest). `scripts/collaudo-completo.sh`: tutto verde; conteggio dell'esecutore (xcresulttool) 72 prove ospitate e d'interfaccia, 72 passate, 0 fallite. `COLLAUDO6_EXIT=0`.

## Ambiguità segnalate (prima di cominciare, come l'incarico chiede)

1. «Il nome vive nello stato come chiave e non come indice». Lo stato tiene i gruppi in `[IdGruppo: Gruppo]`, chiave stabile e non indice d'array; il `nome` (`IdentificatoreDati`) è un'etichetta stabile e unica a sé. Entrambi sono chiavi e non indici; non si è ri-chiavizzato lo stato per nome, che avrebbe toccato l'impronta e il giornale senza vantaggio d'invariante. Letto così.
2. «turno» vs «giorno» negli stati di rifornimento: 02 §4.4.1.2 dice «turno», i termini chiusi di 02 §4.4.5 dicono «giorno». Non pertinente a questa sessione (il rifornimento non è realizzato); annotato per il blocco 4.
3. Geometria dei quartier generali: `CaricatoreCampagna.valida` FISSA `qg.avversario.riga == 1` e `qg.giocatore.riga == formato.righe`. La regola del taglio (blocco 4) dovrà ricavare «dietro» dalla posizione reale del proprio quartier generale e non da questa geometria, come l'incarico avverte. Annotato, non realizzato.

## Ciò che è stato fatto e l'incarico non chiedeva

- Corretto il difetto latente di selezione in `CatenaInterfacciaMotoreTest` (sopra), che i volumi diversi hanno reso attivo.

## Ciò che l'incarico chiedeva e non è stato fatto

- Divisione e riunione (blocco 3): comando di divisione, distaccamento in casella adiacente, denominazione, marcia lunga che impedisce divisione e riunione, sequenza di interazione udibile, invarianti (casella ≤ 1 formazione già esistente; somma dei gruppi dopo la divisione; nessun guadagno d'azione), campioni del giornale.
- Rifornimento e taglio (blocco 4): regola del taglio con le due condizioni di bordo, direzione dal proprio quartier generale, effetti, zone di rifornimento, autonomia e sosta con raccolta, i due conteggi distinti (provviste e marcia forzata), vocabolario chiuso degli stati di rifornimento, informazione di stato, rotori, annuncio della casella, banco che genera tagli e soste.
- Caricamento della build: non effettuato, perché il lavoro non è chiuso.

## Da dove si riprende

Ramo `incarico-15-composizione-rifornimento`, fuso su `principale` fino al commit del resoconto. Si riprende dal blocco 3 (divisione e riunione), poi il blocco 4 (rifornimento e taglio). La composizione e il volume, su cui entrambi poggiano, esistono e sono verdi.

## Non verificato, dichiarato

- L'effetto reale su chi ascolta delle etichette (`casella.inchioda` sulla voce di destinazione, il pannello di revoca) non è stato provato con VoiceOver su dispositivo: è verificato solo il contenuto delle etichette nelle prove ospitate. La prova sul dispositivo spetta ai tester.
- La taratura dei valori introdotti (`soglia_volume_per_giorno_aggiuntivo` = 250, le tre composizioni) non è stata misurata: sono PROVVISORI e scelti perché la gamma dei giorni aggiuntivi (0, 1, 2) sia osservabile, non perché una misura li giustifichi.
