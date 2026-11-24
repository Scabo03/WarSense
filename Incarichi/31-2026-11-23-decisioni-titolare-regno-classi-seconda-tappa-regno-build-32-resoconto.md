# Incarico 31 — resoconto PROVVISORIO (sessione interrotta dal limite d'uso)

`P/` sta per `Incarichi/31-2026-11-23-prodotti/`. Questo file sostituisce il resoconto finché la sessione non riprende: dice dove il lavoro è fermo e che cosa resta. Il resoconto completo non è scritto.

## Perché è fermo

Il limite d'uso dell'account è stato raggiunto per la terza volta alle 03:01 del 24 novembre 2026 (`date`); le due precedenti alle 21:20 circa e alle 21:54 del 23. Il dato è l'avviso del servizio, non una misura mia. Tutto ciò che c'era su disco è committato e spinto sul ramo `incarico-31`.

## Stato

- **La build 32 NON è caricata.** `principale` è ancora a `41cccff`, uguale a `origin/principale`. Su TestFlight l'ultima build è la 31.
- **Ramo `incarico-31`.** Ultimo commit che tocca i sorgenti: `b0a15f2`. Le prime tre parti della seconda tappa sono costruite (nomi conservati e scelta di chi parte; mantenimento; durate, linguette, addestramento mirato, arrivi a campagna aperta). La quarta, assetti e riordino, non è costruita (S29l).
- **Decisioni del titolare del 23 novembre**: scritte nei documenti (RDA-173, RDA-174; 01 versione 3.11, 03 2.8, 02 2.10, 05 1.8, modalità a campioni 1.3). Proposta delle classi rivista: `Proposte/classi-dei-campioni.md`, riletta per intero dalla sessione.
- **Versioni**: valori 0.15.0 con 0.14.0 compatibile; giornale del regno a schema 2 (i regni della build 31 non si riaprono, e il gioco lo dichiara); campagna 9 e battaglia 2 fermi (RDA-181).

## Verificato su `b0a15f2`, con lo strumento

- `cd Codice && swift test`: uscita 0, 534 casi passati, nessuno fallito, 2 saltati, 67 s.
- `scripts/collaudo-completo.sh`: tutto verde, 143 prove fra ospitate e d'interfaccia (riepilogo dell'esecutore). La durata non l'ho letta.
- `scripts/esegui-sessioni-complete.sh`: partita alle 02:56; l'esito NON l'ho letto prima dell'interruzione: è in `esiti-sessioni-complete/esito.json` se la corsa è finita. Su `88d4874`, che differisce da `b0a15f2` per la sola regola dei nomi dell'avversario, collaudo completo verde in 464 s e sessioni verdi in 571 s.
- Banco del regno (`P/banco-del-regno/`): 1829 anni, nessuna violazione dei ventitré invarianti. Misura della frequenza (`P/frequenza-battaglie/`): dati grezzi identici byte per byte a quelli dell'incarico 29.
- Mutanti dei sorgenti (`P/cancelli-visti-fallire/mutanti-dei-sorgenti.txt`): alla prima corsa venti su venti uccisi; la corsa definitiva con ventuno era in esecuzione all'interruzione, e il file può essere incompleto.
- Salvataggi della build 31 dal vivo (`P/salvataggi-build-31/`): quindici controlli su quindici, sul commit `bb66d20`.

## Trovato e corretto in questa sessione

- Un regno della build 31 era trattato da file corrotto e troncato (`bb66d20`).
- Le reclute di ogni primavera ricevevano i nomi che l'anno prima erano dei gruppi nemici: ora l'avversario prende i nomi dal fondo della lista (`b0a15f2`, RDA-175).

## Trovato dalla verifica con VoiceOver e NON corretto

Misure del sotto-agente, ricevute per messaggio; i dati grezzi che ha fatto in tempo a scrivere sono in `P/verifica-con-voiceover/`. Non le ho ricontrollate.

1. Gli annunci che accompagnano uno spostamento del fuoco (inizio dell'inverno, primavera, conferma o rifiuto dopo la scelta di un reparto) sono superati dalla lettura dell'elemento dopo uno o due secondi. Misurato anche sull'app della build 31: non nasce in questa tappa.
2. Sul guado, a quartier generale occupato, le reclute entrano in riga 2, casella 2, accanto al quartier generale avversario: lo spareggio fra caselle alla stessa distanza è l'ordine di lettura.
3. Con tutti gli armati in patria il rifiuto di aprire la campagna arriva soltanto dopo la scelta del fronte.

## Che cosa resta, nell'ordine

1. Spegnere VoiceOver e i simulatori di WarSense dal secondo in su: il sotto-agente è stato fermato a corse definitive in corso e può averli lasciati accesi. Il simulatore primario era in uso alla corsa delle sessioni.
2. Rifare le corse definitive di pilota e tester su iPhone e iPad sull'app di `b0a15f2` (`P/verifica-con-voiceover/corri.sh`), e scriverne il README: quelle consegnate qui sono parziali.
3. Leggere l'esito delle sessioni e dei mutanti; scrivere `P/cancelli-visti-fallire/README.md` e lo scostamento S29q coi tre reperti.
4. Fondere su `principale`, spingere, `scripts/carica-testflight.sh`, verifica su App Store Connect, riga in `build-caricate.md`.
5. Il resoconto completo, l'esito dell'integrazione continua, la cancellazione del ramo fuso.

Le due note (`note-di-rilascio.txt`, `nota-per-il-titolare-il-regno-seconda-tappa.md`) sono scritte e passano `controlla-note.py --senza-programma`; dicono «il pilota e il tester», che sarà vero soltanto dopo il punto 2.
