# Stato dell'avanzamento — scrittura del codice

Documento di lavoro della fase 5. Aggiornato al termine di ogni fase e prima della chiusura di ogni sessione. Scritto per chi arriva senza memoria di quanto accaduto.

## Dove sono le cose

- Il codice è in `Codice/`: pacchetto SwiftPM con i bersagli di 05 §1.2. I documenti di progetto sono in `Fondamenta/`. Il repository git è alla radice, ramo `principale`.
- Comandi: `cd Codice && swift test` (tutto il collaudo), `swift run Verifica` (scheletro del programma di verifica), `swift build`.
- Documenti gemelli di questo: `valori-provvisori.md` e `registro-scostamenti.md`, alla radice.

## Fasi dell'ordine di costruzione (05 §15)

### Fase A — Fondamenta: CONCLUSA

Esito del criterio di uscita (05 §15.2, «una battaglia si gioca da collaudo, senza interfaccia, con giornale riproducibile»): **superato**. 40 prove, 0 fallimenti. La prova `test_criterio_di_uscita_battaglia_completa_con_giornale_riproducibile` gioca uno scontro intero (schieramento, avanzata, ingaggi, mischie, annientamento) attraverso la Sessione e verifica che la riapertura dal giornale produca la stessa impronta canonica. `RiproduzioneOroTest` riapplica un giornale registrato e committato contro l'impronta attesa.

Costruito:
- **Dati**: `Scalato` (virgola fissa per mille, RDA-44), SHA-256 in Swift puro, tipi dei valori, caricatore con impronte e versione locale derivata (RDA-45), testi da cartella sostituibile con copia di lavoro (vedi scostamento S1), vocabolario chiuso come tavola dedicata, validazione con rapporto a chiavi.
- **Motore**: griglia esagonale (righe pari sfalsate a est, distanza cubica), stato di battaglia completo (05 §2.7), i nove comandi di battaglia con validazione a motivi chiusi (i tre motivi di cella di 01 §8.9 più i motivi di comando), formule uniche (costo per profondità 01 §8.6, efficacia offesa-protezione 01 §9.9, danno), turni e giri con primo turno maggiorato e riporto non composto, mischie simultanee con evento aggregato, disingaggio a soglia con memoria delle coppie, due gittate, munizioni, resa e ritirata combattuta, imboscata (vantaggio, sconto, opacità di un turno), impronta canonica, interrogazioni con vista filtrata.
- **Sessione**: attore per slot, giornale JSONL (fondazione, comandi di entrambe le parti, marcatori di inizio turno), scrittura confermata prima dell'esito, istantanee atomiche ogni 200 righe e a ogni turno, annullamento e azzeramento per riscrittura atomica con ricostruzione, ripresa con eventi soppressi, rifiuto dei salvataggi incompatibili, recupero dalla riga finale corrotta.
- **Collaudo**: 18 prove del Motore intestate alla regola che verificano, 7 della Sessione, 10 dei Dati (comprese le 4 della catena dei testi esterni), 3 dei confini (dipendenze fra bersagli, stringhe nel codice, divieto di virgola mobile nel Motore), riproduzione d'oro.
- **Contenuti**: valori di fabbrica con i nove archetipi e due formati (`cento`, `quindici`), tutti i numeri provvisori (vedi `valori-provvisori.md`); testi italiani: annunci, plurali, vocabolario chiuso, chiavi d'errore.

La prova prescritta dalla sezione 2 dell'incarico (catena dei testi esterni) è stata eseguita per prima, il primo giorno: esito positivo, con l'insidia della cache dei Bundle documentata e aggirata (scostamento S1).

### Fase B — Lo scontro accessibile: NON COMINCIATA

L'infrastruttura è montata e provata (vedi memoria-infrastruttura.md): progetto applicativo in Applicazione/ (xcodegen, firma manuale sul certificato riusato, schermata provvisoria accessibile), caricamento su TestFlight con un solo comando (scripts/carica-testflight.sh, build 1 caricata), integrazione continua su GitHub, bersaglio Segnali creato con compilazione condizionale (RDA-48) e nucleo dei canali già collaudato.

Da dove partire:
1. Sostituire la schermata provvisoria con la Presentazione vera (UIKit programmatico, RDA-02) dentro Applicazione/Sorgenti.
2. Completare Segnali: realizzazioni di piattaforma dietro i blocchi condizionali (aptica pronta, suoni, coda annunci con lingua), tabella di 02 §11.7.1.
3. Griglia come contenitore di elementi accessibili persistenti (05 §10.1, RDA-03), ordine di lettura 02 §2.8, deck, pannello della cella, annullamento/azzeramento, rotori 02 §7.2, verbosità, impostazioni, schermata di apprendimento segnali, resoconto di fine battaglia (01 §15.3.1).
4. Tattico avversario di prima stesura nel Motore (deterministico, parametri ufficiale da `ufficiali.json` da creare).
5. Prove XCUITest del fuoco (05 §14.4, regole a–e di 05 §10.3).
Criterio di uscita: scontro completo giocabile solo con VoiceOver, consegnato ai tester via TestFlight (00 §16.3). Punto di arresto: nessun lavoro della fase D prima del ritorno dei tester; la fase C è parallela a quell'attesa.

### Fasi C–G: NON COMINCIATE

La fase C ha già lo scheletro dell'eseguibile `Verifica` e la forma degli scenari (`ScenarioBattaglia` è Codable proprio per gli scenari dichiarativi di 05 §12.2).

## Intervento correttivo della revisione del titolare (dopo la fase A)

Applicato l'incarico di intervento sulle chiusure: la base delle perdite per la resa e per ogni soglia di battaglia è ora costituita dalle sole forze effettivamente impiegate sul campo, come contatore cumulativo che cresce a ogni piazzamento (consolidato 01 alla versione 3.2, punti 10.2 e 10.2.1; registro RDA-46; nel codice il campo dello stato si chiama forzeImpegnate). Il divieto di fuoco amico è diventato regola dichiarata (01 punto 9.6.2, RDA-47) con prova di persistenza dedicata. L'imposizione della battaglia che consuma la giornata è confermata per iscritto sotto RDA-25. Collaudo a 44 prove, tutte verdi; la riproduzione d'oro è rimasta valida perché nello scontro registrato l'intero mazzo scende in campo e le due basi coincidono.

## Avvertenze per chi riprende

- Il guidatore tattico dentro `SessioneBattagliaTest.giocaBattagliaCompleta` è un attrezzo di prova, non il tattico avversario: quello va scritto nel Motore (05 §5.3).
- La riproduzione d'oro si rigenera SOLO con revisione esplicita: aggiornare insieme `giornale.jsonl` e `impronta.txt` in `Codice/Tests/SessioneTest/RiproduzioneOro/` e dichiararlo nel commit.
- Il manifest dei valori contiene le impronte reali dei file: chi modifica un file di valori di fabbrica deve rigenerare le impronte (script Python inline usato in fase A, vedi cronologia git) altrimenti la versione diventa localmente derivata anche in fabbrica.
- `Parte` vive in Dati ed è riesportata dal Motore (`@_exported import enum Dati.Parte` in Esagoni.swift).
