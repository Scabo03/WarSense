Resoconto — Le partite devono arrivare alla fine (incarico 26) — SIGILLO INTERMEDIO

## Avvertenza: questa sessione è SIGILLATA a metà, non conclusa

L'ora concessa è passata e il titolare ha chiesto di chiudere pulito ciò che c'è e finire il resto in una sessione successiva. Il lavoro sta sul ramo dedicato `partite-fino-alla-fine`, committato e spinto; `principale` NON è stato toccato e la build NON è stata caricata (resta la 27). Ciò che segue distingue con cura ciò che è fatto e verde da ciò che è scritto ma non ancora verificato verde.

## In testa (come chiede l'incarico): quante partite, quante alla fine, quali blocchi

La prova nuova `test_incarico_26_le_partite_arrivano_alla_fine_su_ogni_formato` gioca **tre partite intere, una per formato** (piccola, media, grande), attraverso l'interfaccia vera. **Blocco trovato al primo giro:** sul formato `campagna_media`, giorno 18, la giornata non si chiudeva in 80 ordini. **Che cosa era:** NON un blocco del gioco. La prova sceglieva per un gruppo un ordine di marcia che il gioco RIFIUTAVA — un gruppo che DEVE rifornirsi non può marciare né presidiare (01 §5.2.2.4) — e lo ripeteva senza ripiegare su un'azione valida; il gruppo non concludeva mai e la giornata non si chiudeva. L'asserzione che il PANNELLO offra sempre un'azione era invece PASSATA: il gruppo aveva un'azione valida (la sosta con raccolta, sempre valida per un non-agito, per l'invariante della giocabilità dell'incarico 25) — la prova non la sceglieva. È un difetto della PROVA, non del gioco. Corretto: la prova ordina ora la prima azione VALIDA (marcia verso il nemico se vale, altrimenti presidio, altrimenti sosta con raccolta), sicché avanza sempre. **Quante arrivano alla fine: NON ancora riconfermato** dopo la correzione della prova (vedi «Rimane da fare»): la prima corsa fu interrotta perché il ciclo bloccato la faceva durare oltre venti minuti; la seconda corsa, con la prova corretta, è stata interrotta dall'ora scaduta prima di riportare l'esito. **La prova NON ha riprodotto il blocco del titolare** (dichiarato esplicitamente, come l'incarico esige): il solo arresto trovato era un difetto della prova.

## Ciò che è FATTO e VERDE (committato sul ramo)

### 1. La battaglia sbilanciata che non si concludeva — CORRETTA (RDA-140, S26c)

**Causa vera:** l'annientamento (01 §15.2.3) contava viva una parte finché il deck aveva un esemplare, anche una riserva troppo grande per il budget e quindi mai schierabile (01 §8.6). Senza sciami in campo e con una riserva non piazzabile, la parte non era mai annientata; il tattico perdente non dichiara resa; nessuna via chiudeva lo scontro — turni all'infinito, e nel percorso di campagna non c'è tetto ai giri (un candidato forte del secondo blocco del titolare, bloccato nella schermata di battaglia). **Correzione per costruzione:** `MotoreBattaglia.haRiserveSchierabili` confronta il volume di uno sciame di ciascun elemento del deck col budget massimo residuo (`budgetMassimoResiduo` = base + tetto del riporto, o il budget del primo turno); una riserva che lo eccede non tiene viva la parte, che è quindi annientata (01 §15.2.3, via prevista). Nessun valore del combattimento toccato: cambia solo il criterio di «parte vuota» (`MotoreBattaglia.swift`, le due condizioni a §15.2.3). **Invariante col mutante:** `SondaInvariantiCampagna.controllaConclusioneBattaglia` (`battaglia_non_conclusa_nel_limite`), in `codiciNoti` e `tavolaDeiMutanti`. **Visto fallire di proposito:** `test_incarico_26_la_battaglia_sbilanciata_si_conclude` col criterio riportato alla forma pre-correzione dà «non conclusa entro 300 giri (giro=301)» e l'invariante scatta `battaglia_non_conclusa_nel_limite:giri=301:limite=300`; verde con la correzione. **Prove del pacchetto: 337 eseguite, 1 saltata, 0 fallite** (`swift test`; era 336, +1 la prova di riproduzione).

### 2. Il tasto per chiudere la giornata — FATTO, pacchetto e app compilano (RDA-138, S26d)

Decisione del titolare che rovescia la regola d'architettura (la giornata si chiudeva solo da sé), registrata come modifica VOLUTA con la sua motivazione: il titolare non può restare bloccato da un difetto in una partita in corso. `MotoreCampagna.chiudiLaGiornataForzata` chiude quale che sia lo stato dei gruppi (marca spesa la giornata dei non-agiti, poi lascia proseguire la cascata). `SessioneCampagna.chiudiGiornata` la iscrive nel giornale (caso nuovo `giornataChiusaDalGiocatore`, schema 7→8, dichiarato incompatibile; campione committato in `CampioniGiornale/campioni.jsonl`; specchio in `CompatibilitaGiornaleTest`) sicché sopravvive al riavvio. Sulla mappa (`SchermataMappaCampagna`) è il pulsante «Chiudi la giornata», sempre fra i comandi globali, annunciato con significato di conferma, senza rubare il fuoco (nessun `Fuoco.sposta`). La chiusura automatica RESTA e non è tolta. **Prove del pacchetto verdi** (incluso `SessioneTest` 39, `CompatibilitaGiornaleTest`). Verde di compilazione dell'app confermato (`build-for-testing`).

### 3. La registrazione diagnostica, accanto al salvataggio — FATTA (RDA-139)

`SessioneCampagna.chiudiGiornata` ritorna una `DiagnosticaChiusura`: per ogni gruppo non-agito (di ENTRAMBE le parti, il quadro completo), numero, nome, parte, stato dichiarato, e le azioni disponibili (o NESSUNA, il blocco colto sul fatto). `PartitaCampagna.chiudiGiornata` la scrive in `diagnostica-giornata-N.json` nello slot di campagna, accanto a `giornale.jsonl`, con scrittura atomica, quando la giornata non si sarebbe chiusa da sé. Si recupera mandando indietro la cartella dello slot: il file viaggia col salvataggio. Non è un canale del collaudo — lo scrive il gioco vero.

## Ciò che è SCRITTO ma NON ancora verificato verde (committato, da riprendere)

- **La prova che gioca le partite intere** (`test_incarico_26_le_partite_arrivano_alla_fine_su_ogni_formato`) e **la prova del tasto** (`test_incarico_26_il_tasto_chiude_la_giornata_e_scrive_la_diagnostica`): compilano (`TEST BUILD SUCCEEDED`), ma non le ho VISTE passare dopo le ultime correzioni. La prova del tasto ha rivelato che la diagnostica conta i non-agiti di entrambe le parti (7 = 4 giocatore + 3 avversario): asserzione corretta di conseguenza, non riprovata. La prova delle partite intere: driver corretto, non riprovata verde.
- **Durata e collocazione della prova nuova:** la prima corsa (col difetto del driver) durò oltre 20 minuti; la seconda è stata interrotta. La proposta — da confermare a misura presa — è di collocarla nella CORSA SEPARATA delle sessioni, non nel collaudo di ogni caricamento, per la sua durata; l'incarico chiede di misurare e proporre, e la misura non è ancora presa pulita.

## Rimane da fare (prossima sessione)

1. Rieseguire sul simulatore le due prove d'interfaccia nuove; vederle verdi; MISURARE la durata della prova delle partite intere; decidere la collocazione (collaudo o corsa separata) con la misura in mano; vedere fallire di proposito la prova nuova su un blocco costruito, con l'uscita riportata (l'incarico lo chiede per ogni cancello nuovo — per la conclusione della battaglia è fatto, per le partite intere no).
2. RDA-141: registrare l'esito della prova nuova (blocco trovato = difetto della prova, non del gioco; il blocco del titolare non riprodotto).
3. Collaudo completo verde; corsa completa delle sessioni; caricare la build; verifica ASC (valida, treno più alto, gruppo di test, registro concorde nei due versi); riga in `build-caricate.md`.
4. Fondere il ramo su `principale` SOLO se verde; spingere; cancellare il ramo; `git rev-parse partite-fino-alla-fine` (spinto) e a fusione `principale` locale == remoto.
5. Valutazione delle versioni dichiarata (S26d): valori RESTANO 0.11.0 (nessun valore dei dati toccato), schema del giornale 7→8 dichiara l'incompatibilità dei salvataggi in corso. Da confermare al caricamento.

## Documenti già consegnati

`nota-per-il-titolare-partite-fino-alla-fine.md` (linguaggio non tecnico: il tasto e dove sta, la traccia e come mandarla indietro, i blocchi corretti, le partite giocate fino in fondo dal collaudo). `note-di-rilascio.txt` (2373 caratteri). RDA-138/139/140 in `registro-decisioni-architetturali.md`. S26a-d in `registro-scostamenti.md`. Incarico archiviato verbatim; indice aggiornato (riga «resoconto in corso», da finalizzare).

## Ciò che ho fatto senza che fosse chiesto

Aggiunto `registraChiusura` in `SessioneCampagna.chiudiGiornata` perché i marcatori della chiusura forzata finiscano nel giornale (il confine dell'annullamento non perde l'apertura della giornata nuova). Registrata la diagnostica dei non-agiti di ENTRAMBE le parti, non del solo giocatore, per il quadro completo a chi indaga.
