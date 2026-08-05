# Resoconto — Catena intera, tocco sintetizzato, sessioni complete

Commit, dal più vecchio: `6b0caf8` (catena), `770fcfb` (tocco sintetizzato e nota), `d9a5c82` (fusione), `2d3c546` (build 14), `f3c8288` (sessioni complete), `eccff63` (fusione), `26a19e3` (documenti). Ramo di lavoro `catena-e-sessioni-complete`, fuso due volte senza avanzamento veloce.

Collaudo alla chiusura, da `./scripts/collaudo-completo.sh`: **232 prove del pacchetto (una saltata), 53 ospitate, 8 d'interfaccia, zero fallimenti.**

## 1. La catena intera: il motivo non era un rifiuto

**Che cosa bloccava.** Nessun rifiuto. Il ciclo della prova attendeva `azioneSpesa == true` sul gruppo appena ordinato: condizione **falsa per costruzione** quando l'ordine è quello che chiude la giornata, perché la chiusura automatica azzera le azioni nello stesso passo (01 §5.6.0.6). L'attesa non poteva terminare.

Misurato con una sonda in processo su `campagna_piccola`: il primo ordine porta `gruppo-1` da riga 4 casella 2 a riga 3 casella 2 con `azioneSpesa` a vero; il secondo porta `gruppo-2` da riga 4 casella 3 a riga 3 casella 3, il giorno da 1 a 2, e `azioneSpesa` resta **falso** per sei letture consecutive a 200 ms. La prova attende ora che cambi l'**impronta** dello stato, che è vero per ogni comando applicato.

**Il sospetto sul costo in giorni era infondato.** La stessa sonda mostra `comandoDiMarcia` produrre `.marcia(gruppo-1, riga 3 casella 2, giorni: 1)` e l'anteprima dare `valido`. Nessun comando è stato respinto in nessun momento.

**Per quale via il motivo è stato reso leggibile.** Il rifiuto era annunciato e non registrato: il giornale porta i comandi validi (05 §6.1) e un ordine respinto non vi lascia nulla. `PuntoSegnali.annunciPronunciati` conserva ora ciò che il punto ha detto, dentro `accoda(_:interrompente:)`, che è il solo imbuto di ogni annuncio — nel luogo che lo produce e non in un canale nuovo. Tetto di struttura a cinquecento voci (05 §0.4). Serve anche a 00 §6.4. Coperto da `test_05_3_2_un_ordine_respinto_lascia_traccia_negli_annunci`, vista fallire togliendo la riga di registrazione.

**Perché la traccia era necessaria e non accessoria.** Senza di essa il confronto delle impronte passerebbe anche con metà degli ordini respinti: un comando rifiutato non entra nel giornale, e i due percorsi riapplicherebbero entrambi i soli comandi accettati, concordi.

## 2. La forma della prova, e perché non passa se un anello viene tolto

`CatenaInterfacciaMotoreTest.test_00_3_1_una_campagna_giocata_al_dito_da_lo_stesso_stato_del_motore`, sui tre formati, con criterio di arresto dichiarato (fino al quarto giorno).

| anello | pretesto | visto fallire con | messaggio |
|---|---|---|---|
| 1 tocco e risoluzione | ogni tocco vero, e i comandi del giornale pareggiano con i tocchi | `elemento(sotto:)` che restituisce `nil` | «il dito non conferma la destinazione Cella(riga: 3, colonna: 2)» |
| 2 nessun ordine respinto in silenzio | nessun termine di `MotivoNonValidoCampagna.allCases` fra gli annunci | costo in giorni falsato di uno | «nessuna marcia nella sequenza» |
| 3 il comando è del Motore | la marcia porta la casella toccata e il costo prescritto | marcia dirottata su un'altra casella valida | «manda il gruppo in … mentre il dito ha toccato …» |
| 4 applicazione | stessa impronta, calendario e registro riapplicando senza interfaccia | — backstop | — |
| 5 elementi mai ricreati | identità di oggetto invariata per tutta la partita | — backstop | — |

L'anello 3 è stato rafforzato in corso d'opera: senza il confronto con la casella toccata la prova sarebbe passata anche se l'interfaccia avesse mandato il gruppo su una casella diversa da quella toccata, purché valida, perché il giornale avrebbe portato quella sbagliata e i due percorsi l'avrebbero riapplicata entrambi.

Anelli 4 e 5 non sono stati falsificati singolarmente: sono la rete che raccoglie ciò che gli altri lasciassero passare, e ogni loro falsificazione che ho saputo costruire viene intercettata prima dagli anelli 1–3. **Dichiarato come tale e non contato fra i falsificati.**

## 3. Il tocco sintetizzato su griglia scorrevole

**Ipotesi escluse, con la prova.**

| ipotesi | esito | prova |
|---|---|---|
| il riconoscitore non riceve il tocco | esclusa (sessione precedente) | sonda in processo: `finestra.hitTest` sul centro della cella di riga 8 restituisce `VistaGriglia` e `elemento(sotto:)` la risolve |
| `delaysContentTouches` trattiene il tocco | esclusa (sessione precedente) | portato a falso, nessun cambiamento, modifica ritirata |
| la cornice fuori vista | **confermata per la mappa** | sonda XCUITest sulla mappa grande |

**Il meccanismo, dimostrato.** La cornice che il servizio di accessibilità riporta per una casella fuori dalla porzione visibile del contenitore è la sua posizione nel **contenuto**, non sullo schermo. Sulla mappa grande la casella del proprio gruppo riportava cornice a y=592 con i comandi globali a y=623 — dunque superava anche il filtro «dentro la finestra e sopra i comandi» — e il tocco non apriva nulla; dopo **un solo scorrimento** la cornice passava a y=475 e il tocco apriva il pannello. Il dito, a differenza della voce, non ha scorrimento automatico verso l'elemento (00 §10.4). **Il punto è chiuso come conseguenza nota per la mappa di campagna**, non come difetto.

**Il caso della battaglia non coincide, o non del tutto.** Con il medesimo rimedio — otto tentativi con scorrimenti sulla finestra e otto con scorrimenti dentro la griglia — il tocco non schiera. La differenza è ora stretta: due griglie scorrevoli, stesso riconoscitore, stessa base `VistaACaselle`, e la mappa risponde mentre la battaglia no. Resta in S10.

**Conseguenza possibile sul gioco, non realizzata e NON VERIFICATA.** Se la cornice riportata è la posizione nel contenuto anche per gli elementi fuori vista, l'esplorazione al tatto (00 §8.3) potrebbe trovare sopra la colonna dei comandi una casella che lì non è disegnata. Richiede VoiceOver reale e non è osservabile qui. Il rimedio sarebbe riportare la cornice soltanto per gli elementi dentro la porzione visibile; la portata non è nulla, perché `RaggiungibilitaTest` pretende cornici non degeneri per ogni elemento del percorso e andrebbe riformulato. Iscritto in `collaudo-solo-dispositivo.md`.

## 4. Le sessioni complete

Da `#sessioni_riepilogo`, blocco stampato dal programma:

| voce | valore |
|---|---|
| sessioni_di_campagna_giocate | 144 |
| giornate_giocate_nelle_sessioni | 1728 |
| ordini_impartiti_nelle_sessioni | 11232 |
| violazioni_nelle_sessioni_di_campagna | 0 |
| gruppi_minimo / massimo | 1 / 12 |
| mappe_percorse / disposizioni / condotte | 3 / 2 / 2 |
| sessioni_di_battaglia_giocate | 32 |
| sessioni_di_battaglia_concluse | 24 |
| comandi_nelle_sessioni_di_battaglia | 130322 |
| sessioni_di_battaglia_con_riserve_rimaste | 8 |
| violazioni_nelle_sessioni_di_battaglia | 0 |
| invarianti_di_sessione campagna / battaglia | 4 / 3 |

**Estensione dei parametri.** Campagna: tutti e tre i formati; gruppi da uno al massimo che la mappa consente, fino a dodici; disposizioni raccolte e sparpagliate; due condotte deterministiche opposte nella scelta della destinazione. Battaglia: quattro composizioni di mazzo — pari, abbondante contro pieno, minimo contro pieno, un solo archetipo — per due primi occupanti, due ufficiali e imboscata accesa e spenta. `test_05_12_3_l_estensione_dei_parametri_e_quella_dichiarata` impedisce che si restringa in silenzio, e pretende che almeno una sessione lasci forze in riserva.

**Il criterio con cui gli invarianti di sessione sono stati scelti.** Sono di sessione le proprietà che **non si possono enunciare guardando un solo passo**: richiedono di confrontare la fine con l'inizio, oppure una sequenza intera con un'altra. Ogni candidato è stato provato contro il criterio; quelli che si riducevano a una proprietà di transizione sono rimasti in `SondaInvariantiCampagna`.

Campagna: calendario monotono sull'intera sessione; conservazione dei gruppi; corrispondenza fra registro accumulato e ordini impartiti; rigiocatura della sequenza dalla fabbrica. Battaglia: monotonia del giro; lettere mai riusate (01 §9.4.3 è proprietà della storia, e nello stato una lettera libera e una mai usata sono indistinguibili); rigiocatura.

**Restano fuori, dichiarati:** il confine dell'annullamento dopo annullamenti e riprese, e la rigiocatura del giornale con le istantanee cancellate. Sono proprietà della Sessione su disco; il banco vive nel Motore ed è sincrono per costruzione (05 §12.1, RDA-58). Le coprono `AnnullamentoGiornataTest` e `SessioneCampagnaTest`.

**Ciascuno ha il proprio mutante** e `test_05_12_4_ogni_invariante_di_sessione_ha_almeno_un_mutante` pretende che nessuno ne resti privo, per entrambe le sonde. Gli invarianti di passo non sono stati toccati e la loro prova non è stata indebolita. Visto fallire anche su un difetto vero: portando `MotoreCampagna` ad avanzare di due giorni alla chiusura, le sessioni riportano `calendario_non_monotono`.

**Sessioni passate per l'interfaccia: tre**, una per formato, dentro `CatenaInterfacciaMotoreTest`. **Costo misurato:** la classe intera, tre prove comprese le tre sessioni, gira in 9,2 s sul simulatore; il costo della singola sessione **non è stato isolato**. A quel ritmo le 144 sessioni di campagna costerebbero dell'ordine dei sette minuti, che il collaudo completo non può assorbire a ogni caricamento: le sessioni per l'interfaccia restano quindi tre, e le 176 restano al Motore.

## 5. Caricamento

Build **14**, versione di marketing **1.1.0** (non toccata), versione dei valori 0.5.0 (non toccata). Verificato via API: `processingState VALID`, treno `1.1.0` che è il più alto, gruppo `WarLab` con `hasAccessToAllBuilds` vero, quindi assegnazione automatica.

**Correzione a un dato riportato due volte.** La build **13** esisteva già, caricata il 2026-08-05T00:50:41-07:00, e nessun documento la registra: il resoconto della sessione precedente ed `esame-critico.md` §4.1 dicono entrambi che l'ultima era la 12. Da dove venga non è accertato.

`note-di-rilascio.txt` è stata riscritta dopo il caricamento e riallegata con `scripts/nota-testflight.sh 14`: quella allegata al primo colpo descriveva la build precedente. Il controllo sulla nota di rilascio verifica la lunghezza, non la freschezza — a differenza di quello sulla nota per il titolare.

`nota-per-il-titolare-mappa.md` rigenerata e accettata dal proprio controllo: sedici nomi citati tutti esposti dal codice, una misura pari a quella stampata, nessuna cifra non dichiarata, freschezza in regola.

## 6. Da dove si riprende

1. **S10**: il tocco sintetizzato sulla griglia di battaglia.
2. La marcia di più giorni, dimensionata in `impatto-marcia-lunga.md`, che chiede prima la risoluzione di fine giornata.
