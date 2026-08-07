Resoconto — Divisione e riunione dei gruppi, e le impronte che si dichiarano (incarico 16)

## Le frasi vere che il giocatore sente

Termini risolti da `it.lproj/Annunci.strings`/`.stringsdict` e `Vocabolario.strings`, con valori d'esempio; il plurale è del meccanismo di sistema.

Dividendo un gruppo. Sul pannello del gruppo la voce «Dividi: scegli i reparti da staccare» apre la schermata di divisione. Lì, in testa, «Dividi Corvo»; poi una riga per reparto, ciascuna una frase compatta: «6 atomi di fanteria leggera, da tenere», «20 atomi di fanteria pesante, da staccare» — attivarla commuta fra tenere e staccare; poi le caselle dove collocare il distaccamento: «Colloca in riga 2, casella 1». Attivata una destinazione con una scelta valida, la divisione parte e il giocatore sente «Nuovo gruppo Lupo in riga 2, casella 1». Attivarla con nessun reparto staccato, o tutti, non divide e lo dichiara: «Scegli almeno un reparto da staccare e almeno uno da tenere».

Riunendo un gruppo. Sul pannello, una voce per ciascun gruppo proprio adiacente: «Riunisci con Lupo». Attivandola, «Corvo riunito in riga 2, casella 2» — il maggiore dei due conserva nome e casella.

Provando su un gruppo in marcia lunga. La divisione e la riunione non si offrono; e se un giornale manomesso le chiedesse, il gruppo è dichiarato inchiodato.

Quando il rifornimento si interrompe e riprende. NON REALIZZATO in questa sessione. Il rifornimento con la regola del taglio, le zone, l'autonomia e la sosta (il blocco quattro) non è stato costruito: non esistono frasi da riportare, e nessun termine è stato aggiunto al vocabolario chiuso. Vedi «Da dove si riprende».

## Ambito effettivo della sessione, e perché

L'incarico chiedeva due materie: la divisione e la riunione, e il rifornimento con il taglio. Prima è stata tolta la perdita di tempo delle impronte (blocco zero). Poi è stata costruita la divisione e la riunione con la loro schermata (blocco tre), fino alla prova sul simulatore superata. La sessione si è fermata al confine del blocco tre, come l'incarico consente («Se ti fermi a un confine di blocco senza chiudere la sessione, non caricare e dichiaralo»). Il rifornimento (blocco quattro) NON è stato iniziato: nessuna riga di codice parziale lo riguarda. La build NON è stata caricata, perché il lavoro non è chiuso.

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

## I numeri, dal programma di verifica

Da `swift run StrumentoVerifica`, sezione `campagna_riepilogo` (blocco unico, RDA-71; nessun numero a mente):

- **violazioni_trovate_in_totale: 0** (nessun invariante violato in 400+ giornate generate su 10 scenari).
- **invarianti_sorvegliati: 24** (erano 22; +`divisione_non_conserva`, +`guadagno_azione`).
- **divisioni_in_totale: 53**; **riunioni_in_totale: 61** (il banco le GENERA, non le rende soltanto possibili).

Collaudo. `swift test`: 287 prove, 1 saltata, 0 fallite. `scripts/collaudo-completo.sh`: tutto verde; l'esecutore (xcresulttool) conta 73 prove ospitate e d'interfaccia, 73 passate, 0 fallite. Include la prova nuova `test_01_5_6_0_2_la_schermata_di_divisione_stacca_un_reparto_e_divide`, che percorre la schermata sul simulatore.

## Ambiguità segnalate (prima di cominciare)

1. «Un gruppo in marcia lunga è inchiodato e non può dividersi né riunirsi.» I consolidati NON contengono una regola esplicita: 01 §5.6.3.5 stabilisce che un gruppo in marcia lunga «è di fatto immobile … e non può sfilarsi se non perdendo i giorni già spesi», ma non nomina divisione e riunione come vietate. Realizzato il divieto sulla base di quell'immobilità, con il motivo dedicato `gruppoInchiodato`; segnalato che la regola è implicita.
2. Il tetto pratico ai gruppi dalla lista chiusa dei nomi è in tensione con 01 §5.6.0.1 («non esiste alcun tetto»): scostamento S16, realizzato allargando la lista e respingendo con `nomiEsauriti`.

## Ciò che è stato fatto e l'incarico non chiedeva

- Ampliata la lista dei nomi da 12 a 24 (necessaria perché la divisione consuma nomi che non si riusano).

## Ciò che l'incarico chiedeva e non è stato fatto

- Rifornimento e taglio (blocco quattro), per intero: la regola del taglio con le sei caselle alle spalle e le due condizioni di bordo, la direzione ricavata dal quartier generale proprio, gli effetti (malus, due turni, sosta uno-due), le zone di rifornimento (nove caselle), l'autonomia e la sosta con raccolta, i due conteggi distinti (provviste e marcia forzata), gli stati di rifornimento del vocabolario chiuso, l'informazione di stato, il rotore dei gruppi senza rifornimento, l'annuncio della casella con il rifornimento come prima anomalia, il banco che genera tagli, soste e riprese, i relativi invarianti.
- Caricamento della build, incremento della versione dei valori, note per il titolare: non effettuati, perché il lavoro non è chiuso.

## Da dove si riprende

Ramo `incarico-15-divisione-rifornimento`, fuso su `principale` fino al commit del resoconto. Si riprende dal blocco quattro (rifornimento e taglio). La divisione e la riunione, e la composizione col volume su cui il taglio poggia (il taglio legge la posizione dei gruppi e del quartier generale), esistono e sono verdi. Traccia per il blocco quattro: `MotoreCampagna.risolviFineGiornata` ha già i commenti-segnaposto dei passi futuri, fra cui `valutaITagliDiRifornimento`; il caricatore `CaricatoreCampagna.valida` FISSA `qg.avversario.riga == 1` e `qg.giocatore.riga == formato.righe`, ma la direzione del «dietro» va comunque ricavata da `mappa.quartierGeneraleGiocatore` e non da questa geometria (l'incarico lo avverte).

## Non verificato, dichiarato

- L'effetto reale su chi ascolta della schermata di divisione con VoiceOver su dispositivo non è stato provato: è verificato il contenuto delle righe e il percorso nelle prove ospitate sul simulatore, non l'ascolto su ferro. Spetta ai tester.
- La versione dei valori NON è stata incrementata (resta 0.9.0): non c'è caricamento, e 0.9.0 non è distribuita (la build viva è la 20, a 0.8.0), sicché non c'è collisione. Un caricamento futuro dovrà incrementarla.

## Tempi (presi in flusso, non in isolamento — dichiarati tali)

Le misure di tempo dell'incarico si prendono in isolamento; queste sono wall-clock del flusso ordinario e vanno lette come ordini di grandezza.

- Compilazioni e prove del pacchetto (`swift build`/`swift test`): la corsa piena delle prove del pacchetto dura ~45,6 s (287 prove); eseguita una decina di volte durante lo sviluppo, per un totale nell'ordine di 7-8 minuti, la maggior parte in compilazione incrementale e nelle prove.
- Corsa del simulatore (prove ospitate e d'interfaccia): 154,4 s la sola fase di test del simulatore (`IDETestOperationsObserver`), dentro una corsa piena di `collaudo-completo.sh` eseguita UNA volta per il blocco tre (più `xcodegen` e la costruzione dell'app, per un totale nell'ordine di 5-6 minuti).
- Caricamento: nessuno (0), perché il lavoro non è chiuso.
- La parte più lunga del lavoro è stata il blocco tre (divisione, riunione, schermata, catena del giornale, invarianti, banco); il blocco zero è stato breve.
