Resoconto — Divisione, riunione, rifornimento e le impronte che si dichiarano (incarico 16)

> Nota di continuazione (2026-08-08). Questo resoconto è stato COMPLETATO col blocco quattro (rifornimento) in una sessione successiva, ripresa dal ramo `incarico-16-rifornimento`. Le sezioni dei blocchi 0 e 3 restano come scritte; sono aggiunte la sezione del blocco 4, i numeri del rifornimento, e sono aggiornate le sezioni «Ambito», «I numeri», «Ciò che… non è stato fatto», «Da dove si riprende», «Non verificato» e «Tempi».

## Le frasi vere che il giocatore sente

Termini risolti da `it.lproj/Annunci.strings`/`.stringsdict` e `Vocabolario.strings`, con valori d'esempio; il plurale è del meccanismo di sistema.

Dividendo un gruppo. Sul pannello del gruppo la voce «Dividi: scegli i reparti da staccare» apre la schermata di divisione. Lì, in testa, «Dividi Corvo»; poi una riga per reparto, ciascuna una frase compatta: «6 atomi di fanteria leggera, da tenere», «20 atomi di fanteria pesante, da staccare» — attivarla commuta fra tenere e staccare; poi le caselle dove collocare il distaccamento: «Colloca in riga 2, casella 1». Attivata una destinazione con una scelta valida, la divisione parte e il giocatore sente «Nuovo gruppo Lupo in riga 2, casella 1». Attivarla con nessun reparto staccato, o tutti, non divide e lo dichiara: «Scegli almeno un reparto da staccare e almeno uno da tenere».

Riunendo un gruppo. Sul pannello, una voce per ciascun gruppo proprio adiacente: «Riunisci con Lupo». Attivandola, «Corvo riunito in riga 2, casella 2» — il maggiore dei due conserva nome e casella.

Provando su un gruppo in marcia lunga. La divisione e la riunione non si offrono; e se un giornale manomesso le chiedesse, il gruppo è dichiarato inchiodato.

Quando il rifornimento si interrompe. A fine giornata, se una forza nemica è alle spalle della colonna, il giocatore sente «Rifornimento di Corvo interrotto in riga 5, casella 5», con un richiamo tattile (`rifornimento_interrotto`). Attivando la casella, dopo il nome del gruppo sente subito «senza provviste, primo giorno» — il rifornimento è la PRIMA anomalia dell'occupante. Il gruppo può ancora agire: il taglio non paralizza.

Al secondo giorno di taglio. «Corvo in sosta di rifornimento in riga 5, casella 5», con lo stesso richiamo tattile. Ora Corvo DEVE fermarsi: se il giocatore prova a marciarlo, sente il rifiuto «il gruppo deve rifornirsi». Il primo turno di sosta è dedicato al rifornimento; il secondo è usabile per un'azione che non sia marcia.

Quando riprende. Esaurita la sosta, «Rifornimento di Corvo ripreso in riga 5, casella 5» — annuncio a voce, senza richiamo tattile proprio (il tetto dei significati è chiuso), perché è buona notizia e non chiede attenzione. Il gruppo semplicemente rifornito non si annuncia più.

In zona di rifornimento. Una casella nelle nove attorno a una struttura dichiara, in coda, «in zona di rifornimento». Un gruppo lì è rifornito comunque, anche col nemico alle spalle.

Nell'informazione di stato e nel rotore. L'informazione di stato aggiunge in coda, quando ce ne sono, «…, 2 senza rifornimento»; e il rotore «Gruppi senza rifornimento» salta ai gruppi che patiscono il taglio. Nessun termine NUOVO è stato aggiunto al vocabolario chiuso: gli stati usano le chiavi `rifornimento.*` già riservate (scostamento S17).

## Ambito effettivo della sessione, e perché

L'incarico chiedeva due materie: la divisione e la riunione, e il rifornimento con il taglio. La prima sessione ha tolto la perdita di tempo delle impronte (blocco zero), costruito la divisione e la riunione con la loro schermata (blocco tre) fino alla prova sul simulatore, e si è fermata al confine del blocco tre senza caricare, come l'incarico consente. La sessione di continuazione (2026-08-08) ha costruito il rifornimento — catena, taglio, zone, autonomia e sosta (blocco quattro) — e ha chiuso l'incarico caricando la build. Ciò che segue è il resoconto delle due sessioni insieme, per materia.

## Blocco 0 — Le impronte dei Contenuti si dichiarano (RDA-105)

Commit `7579470`.

Scelta la via del FALLIMENTO CHE SI DICHIARA e non dell'auto-rigenerazione, che renderebbe vacuo il controllo `test_05_7_2_testi_di_fabbrica_coincidono_con_le_impronte` e non proteggerebbe chi corre `swift test` da solo (RDA-105).

- `scripts/rigenera-impronte.py --verifica`: nuova modalità che confronta i file col manifest SENZA scrivere ed esce 1 dichiarando in chiaro causa, file divergenti e comando. Vista fallire di proposito: appesa una riga di prova a `Vocabolario.strings`, uscita 1 con «RIFIUTATO: un file di Contenuti è cambiato senza rigenerare le impronte. Esegui `python3 scripts/rigenera-impronte.py`…»; ripristinato, uscita 0.
- `scripts/collaudo-completo.sh`: passo 0b, esegue `--verifica` PRIMA delle prove del pacchetto.
- `ErroreDati: CustomStringConvertible` che, per la chiave d'impronta, nomina file e script SENZA spazi (00 §14.1 vieta le stringhe con spazi nei Sorgenti, come per i codici degli invarianti); prova nuova `test_05_7_2_l_errore_di_impronta_dichiara_il_comando_che_la_rigenera`.

Il controllo resta un rifiuto e non è vacuo: `test_05_7_2_*_respinto` prova che `Testi.carica` respinge ancora una copia divergente.

## Blocco 3 — Divisione e riunione (RDA-106)

Commit `5defc74`.

Comandi. `ComandoCampagna.divisione(gruppo:repartiStaccati:a:)` e `.riunione(gruppo:con:)`, casi nuovi che passano per la catena di `CompatibilitaGiornaleTest` (specchio `SpecieDiComandoCampagna` esteso; due campioni committati nella stessa modifica, numeri 21 e 22 di `campioni.jsonl`, ricodifica byte per byte verificata). Motivi nuovi in `MotivoNonValidoCampagna`: `gruppoInchiodato`, `divisioneImpropria`, `riunioneImpropria`, `nomiEsauriti`. Eventi nuovi in `EventoCampagna`: `gruppoDiviso`, `gruppiRiuniti` (annuncio immediato, non registro — 01 §5.17.1, RDA-104), con significato `.conferma` in `SignificatiCampagna`.

Applicazione (`MotoreCampagna.applica`). La divisione toglie i reparti staccati (per indice, reparti interi) dall'origine, che spende l'azione, e crea il distaccamento nella casella adiacente con id e nome nuovi e azione GIÀ SPESA. La riunione determina il maggiore per `volume` (a parità l'id minore), che conserva nome/id/casella; l'assorbito si rimuove; la composizione è l'unione, il maggiore per primo; l'azione spesa del risultante è l'OR delle due. L'inchiodamento (marcia lunga) è controllato PRIMA dell'azione spesa in `valida`, così che il giocatore senta `gruppoInchiodato` e non `azioneGiaSpesa`.

Denominazione e schermata. Nomi da 12 a 24 in `nomi-gruppi.json` con i termini in `Vocabolario.strings`; i nomi non si riusano (contatore monotòno). `SchermataDivisione` è un `UIViewController` — elenco di elementi accessibili (uno per reparto, uno per casella di destinazione), ogni riga una frase compatta, nessuna tabella a caselle né trascinamento (02 §10.3). La riunione non ha schermata: voci di pannello «Riunisci con ⟨nome⟩» via `VistaCampagna.gruppiRiunibili`. La sequenza e il costo (k+3 tocchi per staccare k reparti, pari a chi vede) sono in RDA-106.

Invarianti nuovi con mutante (`SondaInvariantiCampagna`): `divisione_non_conserva` (la somma multiinsieme dei reparti dell'origine e del distaccamento eguaglia il gruppo di prima) e `guadagno_azione` (nessun gruppo diviso o riunito guadagna una giornata; non si controlla quando la transizione ha chiuso la giornata e azzerato l'azione — difetto trovato e corretto durante la corsa del banco, non a tavolino). Il banco `BancoCampagna.corri` genera divisioni e riunioni con regole fisse sul giorno; la `Corsa` porta `divisioni`/`riunioni`; il riepilogo `divisioni_in_totale`/`riunioni_in_totale`.

Difetti latenti scoperti e corretti. La prova `test_incarico_6_molte_giornate_generate` pretendeva `giornate == giornateGenerate`: con le marce di più gruppi generate ora, l'ultima applicazione chiude più giornate a cascata (01 §5.6.11) e il conto le oltrepassa; corretto a `>=`. La prova `test_01_5_16` pretendeva che il pannello offrisse solo marcia, presidio e chiusura: ora il primo gruppo ha un vicino proprio e la voce «Riunisci con» compare; aggiornata.

## Blocco 4 — Rifornimento, taglio, zone, autonomia e sosta (RDA-107, RDA-108, RDA-109)

La geometria del taglio (RDA-107). `MotoreCampagna.caselleAlleSpalle` ricava le sei caselle alle spalle — tre colonne per due righe, la occupata e la retrostante — e la direzione del retro viene dal quartier generale REALE della parte del gruppo (`mappa.quartierGenerale(di:)`), mai dall'assunzione che i due quartier generali siano allineati. È l'errore che un'unità precedente aveva commesso, corretto qui: la prova `test_5_2_2_2_la_direzione_viene_dal_quartier_generale_reale` mostra i due versi opposti per giocatore e avversario sulla stessa casella. Le due condizioni di bordo (ultima riga verso il proprio quartier generale, colonna di bordo) cadono da sé filtrando le caselle inesistenti, ciascuna con la sua prova. `rifornimentoTagliato` è vero se una forza nemica cade in quelle caselle; `inZonaDiRifornimento` copre le nove caselle attorno a una struttura (RDA-108), e in zona il taglio non ha effetto — la zona vince.

Il dato minimo, non l'avversario né le opere. `StatoCampagna` porta `forzeNemiche` e `struttureDiRifornimento` come insiemi di caselle ferme; `ScenarioCampagna` li porta come campi OPZIONALI la cui codifica li OMETTE quando vuoti, sicché il campione del giornale `fondazioneCampagna` resta byte per byte identico (verificato: `CompatibilitaGiornaleTest` verde senza toccare il campione) e nessuno schema salta. Le campagne giocabili non ne dichiarano; solo gli scenari di verifica. L'avversario, la sua condotta, le sue mosse e le opere NON sono costruiti.

La macchina a stati (RDA-109). Tre campi sul gruppo, tutti in [0,2]: `turniSenzaProvviste`, `sostaDovuta`, `turniMarciaForzata` (quest'ultimo SEPARATO e non alimentato). `valutaITagliDiRifornimento`, passo di `risolviFineGiornata` DOPO l'avanzamento delle marce (così una marcia compiuta si valuta all'arrivo), applica la precedenza sosta → zona → taglio: in sosta scala un giorno e, esaurita, torna rifornito azzerando i turni; tagliato accumula un turno, al primo interrompe, al secondo impone la sosta di due. Finché `sostaDovuta > 0` la marcia è vietata (`deveRifornirsi`); il primo turno di sosta vieta anche il presidio (dedicato al rifornimento). `sostaConRaccolta` è l'azione esistente (01 §5.6.8.1), non una voce nuova: ordinata di propria iniziativa da un gruppo digiuno, fissa i giorni di sosta pari ai turni digiunati (autonomia). Il malus del digiuno agisce sui parametri del reparto e MAI sul volume: `turniSenzaProvviste` conta i turni, la sua traduzione in riduzione dei parametri è materia dell'unità che congiungerà campagna e battaglia — predisposto, non alimentato, come la marcia forzata. Nessun valore di gioco introdotto (valori-provvisori.md, §Rifornimento).

Registro, segnali, vocabolario. Tre `FattoRegistrato` (interrotto, sosta imposta, ripresa) — fatti non decisi, annotati col giorno e il salto al luogo; la sosta VOLONTARIA è un ordine e non si annota. Tre `EventoCampagna` con annuncio; il taglio e la sosta imposta portano lo stesso significato `rifornimento_interrotto` (tetto chiuso, 02 §11.5), la ripresa nessuno. Vocabolario: gli stati usano le chiavi `rifornimento.*` già riservate; il termine della sosta resta «in sosta di rifornimento» (scostamento S17). Interrogazioni: `statoDiRifornimento`, `vociDiCasella` col rifornimento come prima anomalia dell'occupante e la zona in coda, `informazioneDiStato` col conto dei gruppi senza rifornimento, il rotore `caselleGruppiSenzaRifornimento`.

Invarianti e banco. Cinque invarianti nuovi con mutante: `rifornimento_fuori_intervallo`, `marcia_forzata_inattesa`, `sosta_elusa_marciando`, `zona_tagliata`, `taglio_da_casella_non_prescritta`. La sonda ricava la geometria delle spalle e delle zone PER CONTO PROPRIO, senza chiamare il Motore, così che un suo errore non le sfugga. Il banco `BancoCampagna` inietta forze e strutture negli scenari di `campagne.json` (due nuovi: `rifornimento_taglio`, `rifornimento_zona`) e la condotta genera i fenomeni: un gruppo tagliato presidia perché il taglio maturi, un gruppo digiuno ogni tanto sosta di propria iniziativa. Quattordici prove nuove del Motore (`RifornimentoTest`).

## I numeri, dal programma di verifica

Da `swift run StrumentoVerifica`, sezione `campagna_riepilogo` (blocco unico, RDA-71; nessun numero a mente):

- **violazioni_trovate_in_totale: 0** (nessun invariante violato in 480+ giornate generate su 12 scenari).
- **invarianti_sorvegliati: 29** (erano 24; +`rifornimento_fuori_intervallo`, +`marcia_forzata_inattesa`, +`sosta_elusa_marciando`, +`zona_tagliata`, +`taglio_da_casella_non_prescritta`).
- **divisioni_in_totale: 53**; **riunioni_in_totale: 61** (invariati: i due scenari nuovi hanno gruppi a un solo reparto e non si dividono).
- Fenomeni del rifornimento, GENERATI dal banco (non solo resi possibili): **tagli_in_totale: 26**, **soste_imposte_in_totale: 14** (di due turni), **soste_volontarie_in_totale: 12** (di un turno), **riprese_in_totale: 26**, **passaggi_in_zona_in_totale: 5**, **strutture_isolate_in_totale: 1**.

Collaudo. `swift test`: 303 prove, 1 saltata, 0 fallite. `scripts/collaudo-completo.sh`: tutto verde, dal cancello dei simboli e delle impronte alle prove ospitate e d'interfaccia sul simulatore — l'esecutore (xcresulttool) conta 73 prove ospitate e d'interfaccia, 73 passate, 0 fallite.

Deviazione dichiarata sulle sessioni complete. L'incarico chiedeva di NON eseguire le sessioni complete. Ma il caricamento ha un cancello di freschezza sulla corsa separata di quelle sessioni (144 d'interfaccia più 32 di battaglia, escluse dal collaudo per costo — RDA-83, S11) che RIFIUTA una build il cui codice è più recente dell'ultimo esito registrato, e la memoria d'infrastruttura vieta di scavalcare o accorciare quei cancelli. Fra la prescrizione dell'incarico e il controllo consolidato prevale il consolidato (regola dell'incarico stesso): la corsa separata è stata eseguita UNA volta sul codice attuale per sbloccare il caricamento. Le mie modifiche non toccano le sessioni giocabili (senza forze nemiche non c'è taglio), sicché l'esito resta verde come il sottoinsieme del collaudo. Includono le prove nuove del rifornimento (`RifornimentoTest`, 14 del Motore) e gli invarianti coi loro mutanti; la catena del giornale ha il campione nuovo numero 23 (`sostaConRaccolta`), ricodifica byte per byte verificata; il rotore nuovo «Gruppi senza rifornimento» è verificato dalla prova d'interfaccia dei rotori.

## Ambiguità segnalate (prima di cominciare)

1. «Un gruppo in marcia lunga è inchiodato e non può dividersi né riunirsi.» I consolidati NON contengono una regola esplicita: 01 §5.6.3.5 stabilisce che un gruppo in marcia lunga «è di fatto immobile … e non può sfilarsi se non perdendo i giorni già spesi», ma non nomina divisione e riunione come vietate. Realizzato il divieto sulla base di quell'immobilità, con il motivo dedicato `gruppoInchiodato`; segnalato che la regola è implicita.
2. Il tetto pratico ai gruppi dalla lista chiusa dei nomi è in tensione con 01 §5.6.0.1 («non esiste alcun tetto»): scostamento S16, realizzato allargando la lista e respingendo con `nomiEsauriti`.
3. (Blocco quattro) Il termine della sosta. L'incarico dice «in sosta di rifornimento, con i giorni di sosta dovuti»; il vocabolario chiuso già consolidato fissa «in sosta di rifornimento» (chiave riservata `rifornimento.in_sosta`). Prevale il consolidato, come l'incarico stesso prescrive: usate le chiavi `rifornimento.*` esistenti, nessun termine nuovo. Scostamento S17.
4. (Blocco quattro) La direzione del «dietro». L'incarico avverte di ricavarla dalla posizione REALE del quartier generale e non da un'assunzione. Fatto: `caselleAlleSpalle` legge `mappa.quartierGenerale(di: gruppo.parte)`, benché `CaricatoreCampagna.valida` fissi oggi il quartier generale del giocatore all'ultima riga; se quella geometria cambiasse, il taglio resterebbe corretto (RDA-107, prova coi due versi opposti).
5. (Blocco quattro) La provabilità senza avversario. L'incarico chiede di rendere provabile il taglio «collocando forze nemiche negli scenari di verifica come dati minimi, dichiarati come minimo per provare la regola, non l'avversario». Fatto così: `forzeNemiche`/`struttureDiRifornimento`, insiemi di caselle ferme, opzionali negli scenari, assenti nelle campagne giocabili.

## Ciò che è stato fatto e l'incarico non chiedeva

- Ampliata la lista dei nomi da 12 a 24 (necessaria perché la divisione consuma nomi che non si riusano). [Blocco 3]
- (Blocco 4) Corretto un vuoto PREESISTENTE del vocabolario: cinque termini `comando.non_valido.*` mancavano da `Vocabolario.strings` — `gruppo_inchiodato`, `divisione_impropria`, `riunione_impropria`, `nomi_esauriti` (del blocco tre) e `deve_rifornirsi` (del blocco quattro). La prova `test_02_4` che li pretende falliva su quei cinque; aggiunti tutti, con la copertura estesa anche agli stati di rifornimento. Segnalato perché quattro dei cinque non erano di questa materia.

## Ciò che l'incarico chiedeva e non è stato fatto

- Il MALUS numerico del digiuno sui parametri del reparto (di quanto scendano punti vita e capacità offensiva) NON è realizzato: è predisposto il conteggio (`turniSenzaProvviste`) ma non la sua traduzione in una riduzione, che appartiene all'unità di congiunzione campagna-battaglia. Dichiarato in valori-provvisori.md e in RDA-109; l'incarico stesso chiedeva di predisporre la separazione e alimentare solo il contatore, non di costruire il malus. Coerente.
- Il contatore della marcia forzata (`turniMarciaForzata`) è predisposto e non alimentato, come chiesto.

## Da dove si riprende

Ramo `incarico-16-rifornimento`, fuso su `principale` a valle del collaudo verde. L'incarico 16 è CHIUSO: blocchi 0, 3, 4 realizzati, build caricata. La prossima unità naturale è la congiunzione campagna-battaglia, che darà corpo al malus del digiuno (oggi solo contato) e alla marcia forzata (oggi solo predisposta); i loro valori entreranno allora in `Contenuti/Valori`, e la versione dei valori salirà per quel motivo.

## Non verificato, dichiarato

- L'effetto reale su chi ascolta — l'annuncio del rifornimento interrotto, della sosta, della ripresa, e la zona in coda alla casella — con VoiceOver su dispositivo non è provato: è verificato il contenuto e il percorso nel Motore e nel traduttore, non l'ascolto su ferro. Spetta ai tester (il titolare provi in particolare l'interruzione del rifornimento, oltre a divisione e riunione).
- La versione dei valori NON è stata incrementata (resta 0.9.0), ed è la scelta giusta: nessun file di `Contenuti/Valori` è cambiato e una campagna in corso si comporta identica (forze nemiche e strutture vuote in gioco reale). Lo schema del giornale resta 4, i salvataggi restano compatibili. Sale solo il numero di build (regola del titolare).
- La versione dei TESTI resta 0.1.1 benché siano state aggiunte chiavi nuove (annunci del rifornimento, voci di registro, rotore, stato, e i cinque termini `comando.non_valido.*` che mancavano). Verificato che NON scatta la trappola dei testi (memoria-infrastruttura, «REGOLE DELLE VERSIONI»): i testi sono compilati NEL fascio dell'app (`Bundle.module`), non consegnati fuori banda e versionati, sicché ogni nuova build porta con sé le chiavi nuove — le installazioni dei tester le ricevono con la build. Le chiavi sono additive: nessun salvataggio le referenzia, e i testi si risolvono a schermo dal fascio corrente. Il manifest dei testi traccia i FILE per impronta (rigenerate), non le singole chiavi; l'impronta di `Annunci.strings` e `Vocabolario.strings` è aggiornata. Nessun bump di propria iniziativa (regola del titolare).

## Tempi (presi in flusso, non in isolamento — dichiarati tali)

Le misure di tempo dell'incarico si prendono in isolamento; queste sono wall-clock del flusso ordinario e vanno lette come ordini di grandezza.

- Prove del pacchetto (`swift test`): la corsa piena dura ~46 s (303 prove); eseguita molte volte durante lo sviluppo dei due blocchi.
- Corsa del simulatore (prove ospitate e d'interfaccia): dentro `collaudo-completo.sh`, eseguito più volte a fine blocco quattro (più `xcodegen` e la costruzione dell'app; una corsa piena è nell'ordine di 5-6 minuti).
- Blocco quattro (rifornimento): la parte più lunga della sessione di continuazione è stata la geometria del taglio con le prove dedicate, la macchina a stati della sosta e il banco con la condotta che genera i fenomeni; gli invarianti e i loro mutanti sono seguiti. Il vuoto dei cinque termini di vocabolario si è manifestato come cinque prove rosse (`test_02_4`) e si è chiuso subito.
- Caricamento: una corsa di `carica-testflight.sh` a valle del collaudo verde; numero di build ricavato da TestFlight, versioni non toccate.
