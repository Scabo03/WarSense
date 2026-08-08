Resoconto — L'avversario che si muove sulla mappa di campagna (incarico 18)

> Blocco 2 dell'incarico grande dell'avversario (il blocco 1, gli stati di conoscenza, era l'incarico 17). Questa sessione costruisce l'avversario che si muove: la condotta deterministica, l'informazione incompleta simmetrica, l'occultamento, l'annuncio, il giornale, il banco e il caricamento. Portata fino in fondo, build caricata.

## Le frasi vere che il giocatore sentirà

Scoprendo una formazione avversaria. Portando una propria formazione accanto a un gruppo avversario, la casella di quel gruppo — che così diventa **confermato** per il giocatore — dichiara, dopo la testa fissa «riga N, casella M», l'occupante avversario: **«formazione avversaria»**. Senza nome, senza volume (02 §6.4.1), senza il suo stato d'azione. Su una casella che il giocatore NON osserva la formazione non compare affatto: vi si legge solo lo stato di conoscenza (inesplorato, o avvistato coi turni), che tace ciò che non si vede. Quando invece l'avversario si SPOSTA dentro l'osservazione del giocatore, questo lo sente annunciare in modo proattivo: **«Formazione avversaria avvistata in riga N, casella M»** (sintetico: «Avversario in riga N, casella M»); la stessa voce resta nel registro — **«Giorno D: formazione avversaria avvistata in riga N, casella M»** — attivabile per portare il fuoco sul luogo.

Subendo un taglio di rifornimento. Quando un gruppo avversario si porta alle spalle di una colonna del giocatore, alla chiusura della giornata questi sente **«Rifornimento di ⟨gruppo⟩ interrotto in riga N, casella M»** (sintetico: «⟨gruppo⟩ senza rifornimento»), col richiamo tattile dedicato del rifornimento; nel registro **«Giorno D: rifornimento di ⟨gruppo⟩ interrotto in riga N, casella M»**. Restando tagliato, il turno dopo **«⟨gruppo⟩ costretto alla sosta di rifornimento»**. Sono le stesse frasi del rifornimento dell'incarico 16, ma ora prodotte da qualcuno che si mette apposta alle spalle.

## Che cosa l'avversario cerca di fare

Guardandolo muoversi, il titolare deve poterne leggere le intenzioni, in quest'ordine (i pesi in diminuzione dei valori di fabbrica, `condotta-campagna.json`):

1. **Difende il proprio quartier generale.** Se una formazione nota del giocatore è entro tre caselle dal suo quartier generale, ripiega a difenderlo (peso 600).
2. **Minaccia il rifornimento.** Altrimenti cerca di mettersi ALLE SPALLE di una formazione nota del giocatore, cioè nelle caselle da cui se ne taglia il rifornimento (peso 300).
3. **Avanza verso il quartier generale del giocatore, aggirando.** Altrimenti punta il quartier generale del giocatore, misurando la distanza AGGIRANDO le formazioni note (un cammino che le tratta come ostacoli): una formazione che gli sbarra la via diretta lo fa girare intorno anziché ammassarvisi — l'aggiramento di 01 §5.13, voluto (peso 100, l'aggressività).

In assenza di guadagno presidia; tenuto fermo dal taglio si ferma con la sosta di raccolta, come il giocatore. Decide SOLTANTO su ciò che osserva (le caselle confermate), mai sullo stato reale della mappa; ed è interamente deterministico: nessuna estrazione del caso, parità risolte a favore del presidio e poi per l'ordine di lettura della casella. Due partite identiche restano identiche. L'aggressività è la manopola provvisoria da tarare (01 §6.1.3).

---

## La condotta e la sua cecità (RDA-111, RDA-114)

`CondottaAvversaria.prossimoComando(vista:)` (nuovo file `Motore/CondottaAvversaria.swift`) decide, per il gruppo avversario di id minore che attende (l'ordine interno fisso di 01 §5.6.11), assegnando a ogni mossa candidata — il presidio e ogni marcia valida — un punteggio intero, somma pesata delle tre spinte sopra, e scegliendo il massimo. L'avanzata usa `distanzeAggirando`, un percorso in ampiezza sulla griglia che tratta le formazioni note come ostacoli.

La cecità è resa impossibile da un controllo e non da una disciplina (incarico 18). La condotta riceve SOLTANTO una `VistaAvversario`, valore autosufficiente che NON contiene alcun riferimento allo `StatoCampagna`: vi stanno i propri gruppi per intero, la mappa (geografia pubblica), i due quartier generali, i volumi precalcolati, e `formazioniGiocatoreNote: Set<Cella>` — SOLTANTO le caselle in cui l'avversario osserva ora una formazione del giocatore. Le posizioni non osservate non sono nel grafo degli oggetti: la condotta non può accedervi. La vista calcola per conto proprio costi e validità delle proprie marce senza toccare lo stato: `MotoreCampagna.costoInGiorni` e `caselleAlleSpalle` sono stati fattorizzati in NUCLEI PURI STATICI (funzione della sola geografia e del volume) che tanto il Motore quanto la vista chiamano. L'UNICO punto in cui lo stato reale si legge è `MotoreCampagna.vistaAvversario`, e solo per calcolare l'insieme osservato.

## L'integrazione nel turno e nel giornale (RDA-111, RDA-42)

`SessioneCampagna.esegui` applica il comando del giocatore, poi — se il giocatore ha concluso e l'avversario ha gruppi in attesa — chiama `svolgiTurnoAvversario` (statico, perché lo usa anche l'inizializzatore di ripresa, nonisolated): finché nessun gruppo del giocatore attende e uno avversario sì, la condotta decide un comando che si appende al giornale come `.comandoCampagna(parte: .avversario, …)` e si applica dallo STESSO percorso del giocatore (`motore.applica`). L'ultimo comando avversario chiude la giornata (`chiudiLaGiornataSeServe`), che si risolve e ne apre una nuova; se questa si apre coi soli gruppi del giocatore in marcia lunga, l'avversario torna a muovere. Nessuna seconda via: i comandi avversari passano dallo stesso `giornale.appendi` + `motore.applica` (RDA-42, la ripresa li riapplica senza reinterrogare l'avversario). La ripresa (`init(riprendi:)`) completa un turno avversario interrotto a metà.

Il confine dell'annullamento torna a mordere (RDA-115, restringe RDA-73/S9): chiusa la giornata con l'avversario che ha agito, l'ordine del giocatore che l'ha chiusa non è più annullabile (si scrive il marcatore `risoluzioneGiornata` quando la chiusura ha compiuto una marcia OPPURE l'avversario ha agito); `ultimoOrdine` trova l'ultimo ordine DEL GIOCATORE saltando i comandi avversari che lo seguono. L'annullamento dentro il proprio turno resta pieno.

## La simmetria delle regole (RDA-112)

Verificate ed eliminate le due asimmetrie residue del periodo senza avversario. `costoInGiorni` riceve ora la `parte` e legge il volume della colonna che marcia (era fisso su `.giocatore`): l'avversario paga il proprio volume. `rifornimentoTagliato` usa `caselleOstili(a:)` — i gruppi della parte opposta più, per il solo giocatore, le forze ferme dello scenario (era `stato.forzeNemiche`, ostile al solo giocatore): il rifornimento dell'avversario si taglia mettendosi alle SUE spalle. Due invarianti che presupponevano il giocatore resi simmetrici: `due_gruppi_stessa_casella` conta ora PER PARTE (la compresenza di 01 §6.1 è ammessa), `taglio_da_casella_non_prescritta` è relativo alla parte. Il rifornimento dell'avversario si aggiorna con le stesse regole ma i suoi fatti NON entrano nel registro del giocatore. Nessuna asimmetria introdotta: i vantaggi nascosti di 01 §13.2 sono di battaglia e non si replicano.

## L'occultamento, l'annuncio, il registro, il rotore (RDA-115)

`VistaCampagna.vociDiCasella` aggiunge `.occupanteAvversario` SOLO dove la conoscenza del giocatore è confermato e una formazione avversaria è lì. Nel Motore, `avanzaLeMarce` valuta gli avvistamenti DOPO che tutte le marce si sono compiute, sulle posizioni SETTLATE (non a metà del giro, che dipenderebbe dall'ordine degli id: un gruppo del giocatore nato da divisione ha id maggiore dell'avversario — difetto trovato e corretto durante la costruzione): una marcia avversaria compiutasi diventa un `formazioneAvversariaAvvistata` — nuovo `EventoCampagna` e nuovo `FattoRegistrato` — solo se il giocatore la osserva. `valutaITagliDiRifornimento` annuncia e annota i fatti di rifornimento del SOLO giocatore. `SessioneCampagna` passa tutti gli eventi del turno per `motore.proiettaPerIlGiocatore` (ultima difesa) prima di consegnarli. Nuovo rotore `rotore.formazioni_avversarie_note` (`VistaCampagna.caselleFormazioniAvversarieNote`, in `SchermataMappaCampagna`). L'informazione di stato di campagna (02 §6.5.1.3) NON riceve voci nuove: il suo formato chiuso non prevede le formazioni avversarie, che sono materia del rotore §7.3; nulla vi è aggiunto.

Il vocabolario chiuso non riceve TERMINI nuovi: le stringhe aggiunte — `casella.occupante_avversario`, `campagna.formazione_avvistata`, `registro.formazione_avvistata`, `rotore.formazioni_avversarie_note`, `errore.dati.condotta_incoerente` — sono modelli di frase ed etichette composti da termini già esistenti, gemelli di quelli di battaglia; non stati nuovi del vocabolario di 02 §4.2/§4.4.5. Nessun sedicesimo significato tattile (02 §11.5): l'avvistamento si annuncia a voce. Interpretazione dichiarata all'inizio e non contestata.

## I dati e la versione (RDA-113, valori-provvisori)

`ScenarioCampagna.gruppiAvversario`, gemello di `gruppiGiocatore`, omesso dalla codifica se vuoto: gli scenari e i salvataggi scritti prima restano identici al byte, lo schema del giornale resta 4, i campioni del giornale non si muovono (`CompatibilitaGiornaleTest` verde, nessun caso di comando nuovo). Nuovo file dati `condotta-campagna.json` col carattere provvisorio (aggressivita 100, minaccia_rifornimento 300, difesa_quartier_generale 600, soglia_difesa_quartier_generale 3), validato dal caricatore (soglia almeno uno, `errore.dati.condotta_incoerente`). La versione dei valori sale da 0.9.0 a **0.10.0** (istruzione esplicita dell'incarico), raccogliendo i numeri di campagna dal blocco 1 (raggio, soglia) e il carattere. `versioni_compatibili` = ["0.8.0", "0.9.0"]: i salvataggi precedenti (senza avversario) si riaprono identici; uno con versione o schema davvero incompatibili si dichiara e si rifiuta (`SalvataggioBuildDistribuitaTest.test_00_15…` verde).

## Gli invarianti nuovi e il banco (dal programma di verifica)

Due invarianti nuovi col mutante (visti fallire di proposito, `InvariantiCampagnaTest.tavolaDeiMutanti` + guardia `test_incarico_6_ogni_invariante_ha_almeno_un_mutante`): **`registro_rivela_ignoto`** (nessun fatto nuovo del registro su casella non osservata o su gruppo avversario) e **`vista_avversaria_rivela_ignoto`** (ogni casella nella vista è davvero osservata e ospita un gruppo del giocatore). La cecità della condotta è mostrata anche da una prova differenziale (`CondottaAvversariaTest.test_01_5_11_1_una_posizione_del_giocatore_non_osservata_non_cambia_la_decisione`): due stati che differiscono solo per una posizione non osservata danno la stessa mossa. Il determinismo «stesso giornale, stesse mosse» e la ripresa dal disco sono provati con la Sessione reale (`AvversarioCampagnaTest`). La simmetria «l'avversario non viola le regole del giocatore» è coperta dagli invarianti di stato che iterano tutti i gruppi, dai due invarianti resi party-aware, e dalla prova che una partita intera contro l'avversario produce zero violazioni.

Il banco genera partite intere contro l'avversario (`BancoCampagna.corri` pompa l'avversario dopo il giocatore) su due scenari nuovi in `campagne.json` (guado e pianura) e riporta i fenomeni che contano. **Numeri dal blocco di riepilogo di `swift run StrumentoVerifica`** (RDA-71): `invarianti_sorvegliati` **33** (erano 31: +registro_rivela_ignoto, +vista_avversaria_rivela_ignoto); `violazioni_trovate_in_totale` **0**; `scenari_con_avversario` **2**; `gruppi_avversari_in_totale` **5**; `tagli_da_avversario_in_totale` **19** (tagli del giocatore realmente causati dalle mosse dell'avversario); `aggiramenti_in_totale` **5** (gruppi avversari distinti portatisi oltre la linea del giocatore); `distanza_minima_avversario_dal_qg_giocatore` **0** (un avversario ha raggiunto il quartier generale del giocatore).

## Il collaudo

- Prove del pacchetto: **`swift test` 315 prove, 0 fallite, 1 saltata** (erano 307; +5 `CondottaAvversariaTest`, +3 `AvversarioCampagnaTest`; `InvariantiCampagnaTest` da 25 a 27 casi). Durata ~48 s.
- Il cancello del rotore è stato visto fallire di proposito: `MappaCampagnaAccessibileTest.test_02_7_3_i_rotori_della_mappa_sono_quelli_realizzati` è fallito nel primo collaudo completo perché l'elenco atteso non conteneva il rotore nuovo (uscita: «Failing tests: …i_rotori_della_mappa_sono_quelli_realizzati», TEST FAILED), poi aggiornato all'elenco con il rotore delle formazioni avversarie note.

## Ciò che ho fatto senza che fosse chiesto

- Fattorizzato `costoInGiorni` e `caselleAlleSpalle` in nuclei puri statici: serviva alla cecità della vista, ma è una semplificazione che rende il costo indipendente dallo stato per costruzione.
- Corretto il difetto di ordine degli avvistamenti (valutati sulle posizioni settlate anziché a metà del giro): non richiesto in quanto tale, ma senza di esso l'invariante `registro_rivela_ignoto` scattava sulle partite generate dal banco con divisioni del giocatore.

## Ciò che era chiesto e non ho fatto (e perché)

- Le formazioni avversarie STANTIE («avvistato, N turni fa» di una formazione che si è spostata) non sono mostrate: la memoria di conoscenza è per casella e non porta le posizioni nemiche; la deduzione dell'itinerario e il «presunto» sono rinviati al blocco della ricognizione da 01 §5.10.1 e RDA-110. Dichiarato all'inizio e in S18. In questo blocco le formazioni sono note solo dove confermate.
- Il carattere non è sdoppiato per ufficiale né fra campagna e battaglia (03 §6.5.2, rinviato): un carattere unico provvisorio.
- Nessuna delle materie che l'incarico chiedeva di NON costruire (ricognizione, esploratori, formazioni non armate, sabotaggio, imboscate, passaggio alla battaglia, ecc.) è stata costruita oltre il minimo per rendere provabile l'avversario.

## Non verificato, dichiarato

- L'effetto reale su chi ascolta con VoiceOver su DISPOSITIVO — l'annuncio dell'avvistamento, l'occupante avversario, il rotore nuovo, il taglio causato dall'avversario — non è provato: sono verificati contenuto e percorso nel Motore, nelle prove ospitate sul simulatore e nelle prove d'interfaccia, non l'ascolto su ferro (`collaudo-solo-dispositivo.md`).
- I quattro numeri del carattere (aggressivita, minaccia, difesa, soglia) sono provvisori e non tarati: nessuna simulazione li giustifica ancora come equilibrio di gioco; il banco mostra solo che l'avversario esercita i fenomeni.

## Il caricamento (build 22)

Corsa completa delle sessioni verde prima del caricamento (`esegui-sessioni-complete.sh`, esito «successo»: 144 sessioni di campagna per l'interfaccia + `SessioniCompleteTest` al Motore). Collaudo completo dentro il cancello di `carica-testflight.sh` verde: `swift test` 315 prove (0 fallite, 1 saltata) e **73 prove ospitate e d'interfaccia** dall'esecutore (73 passate, 0 fallite; il conteggio è invariato rispetto alla build 21 perché nessuna prova d'interfaccia è stata aggiunta, solo aggiornato l'elenco atteso dei rotori).

Il cancello dei documenti è stato visto rifiutare di proposito: al primo tentativo `carica-testflight.sh` è uscito con 1 perché `controlla-note.py` ha rifiutato la nota per il titolare — «`nota-per-il-titolare-avversario.md` nomina «Rifornimento di ⟨gruppo⟩ interrotto», che il codice non espone» — la citazione fra «...» era troncata e non coincideva con il valore intero della chiave `campagna.rifornimento_interrotto`. Corretta alla frase intera (e tolti i segni ⟨⟩, regola della build 21), il caricamento è andato a buon fine.

Build **22** caricata su TestFlight («UPLOAD SUCCEEDED with no errors»), nota di rilascio allegata, registrata in `build-caricate.md`. La versione di marketing resta 1.1.0, i certificati, i profili e gli identificatori non toccati; solo il numero di build è salito, assegnato dal treno più alto dell'account (21 → 22). Verifica per interfaccia di programmazione (`asc_api.py`, App Store Connect):

- `processingState` = **VALID**, `expired` = false;
- treno `preReleaseVersion` = **1.1.0**, il più alto (il controllo preventivo dichiara «versione da caricare 1.1.0; più alta già presente 1.1.0»);
- gruppo di test **WarLab** (interno, `hasAccessToAllBuilds` = true): la build gli è disponibile;
- il registro concorda con i server nei due versi (`controlla-build.py`: «registro e App Store Connect concordano: 22 build, la più alta è la 22»).

Salvataggi incompatibili: la dichiarazione invece del fallimento silenzioso è verificata (`SalvataggioBuildDistribuitaTest.test_00_15…`, verde con la versione 0.10.0); una campagna 0.9.0 (senza avversario) si riapre identica.

## Tempi (wall-clock, ordini di grandezza)

- Analisi iniziale (lettura dei consolidati 01/02/03 e del RDA limitatamente alle voci richieste, e del codice di campagna), con tre esplorazioni in parallelo per la documentazione e la mappatura del banco: la parte più lunga prima di scrivere codice, servita a segnalare le interpretazioni all'inizio.
- Costruzione (Motore, condotta e vista, Sessione, occultamento, dati, testi, invarianti, banco, prove): il grosso del lavoro; un difetto (ordine degli avvistamenti) trovato e corretto durante il collaudo del banco.
- Compilazioni del pacchetto (`swift build`): pochi secondi ciascuna, incrementali.
- Corse del collaudo del pacchetto (`swift test`): **~47-48 s** per corsa (315 prove), eseguite più volte.
- Corse del simulatore: il collaudo completo (`collaudo-completo.sh`) **~5-6 minuti** per corsa (prove ospitate e d'interfaccia, ~157 s la sola fase di test più la compilazione dell'app), eseguito una volta a metà lavoro e una dentro il cancello del caricamento; la corsa completa delle sessioni **~9 minuti**.
- Caricamento: il primo tentativo respinto in pochi secondi al cancello dei documenti; il secondo, completo, **~8-9 minuti** (collaudo dentro il cancello, archiviazione, esportazione firmata, caricamento su TestFlight ~1,5 minuti dei quali).
