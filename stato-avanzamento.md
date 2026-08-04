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

### Fase B — Lo scontro accessibile: CONCLUSA (in attesa della distribuzione ai tester)

Criterio di uscita (05 §15.3, «scontro completo giocabile solo con VoiceOver, consegnato ai tester»): la parte realizzativa è compiuta e provata; il gruppo di tester «WarLab» ha accesso automatico a ogni build caricata (verificato via API), quindi la consegna è compiuta con il caricamento stesso. Collaudo: 58 prove del pacchetto più 12 fra ospitate e interfaccia sul simulatore, tutte verdi. Storia dei treni di versione (dettagli e regole in memoria-infrastruttura.md): build 1–2 sul treno accidentale «1.0», build 3–4 sullo «0.2.0» (mai proposte come aggiornamento perché sotto l'1.0), build 5 — identica alla 4 — sull'«1.1.0», che è la build buona; da lì la versione sale soltanto e il caricamento è protetto da un controllo preventivo.

#### Intervento correttivo dopo la prima prova su dispositivo (build 4, versione 0.2.0)

La prova del titolare su dispositivo con VoiceOver ha trovato due difetti bloccanti nella build 3, entrambi riprodotti con una prova che falliva, corretti, e coperti:

1. **Il pannello delle azioni riportava alla schermata iniziale.** L'avviso di sistema si congeda da solo al tocco di una voce; `chiudiPannello` congedava allora la schermata dello scontro stessa (per chi ascolta, indistinguibile da un riavvio). Corretto: il congedo colpisce soltanto un pannello ancora presentato; la sequenza reale del tocco è riprodotta da `PannelloAzioniTest` (precisazione P5).
2. **Elementi del deck non agganciabili.** Vincoli insoddisfacibili nella colonna sotto la griglia: il risolutore schiacciava ad altezza zero elementi variabili (l'intermittenza osservata). Il deck è stato rifatto a tessere-riquadro in riga scorrevole con identità, esemplari e costo dichiarati, distinte dai comandi globali; la griglia cede spazio alla colonna (RDA-50, scostamento S3).

Il collaudo ora accerta la raggiungibilità reale e non la sola dichiarazione: `LettoreAccessibilita` più `RaggiungibilitaTest` sul formato di schermo piccolo, fumo d'interfaccia con tocco vero (RDA-51); ciò che resta accertabile solo su dispositivo è dichiarato in `collaudo-solo-dispositivo.md`, da consegnare con ogni build. Versione dei testi a 0.1.1 (chiavi nuove del deck; la compatibilità dei salvataggi si valuta sui valori, non sui testi).

Osservazione registrata e volutamente non affrontata: le celle della griglia appaiono più grandi del necessario (da riesaminare con i ritorni dei tester, insieme alla forma del pannello di RDA-49).

#### Prima tranche di semplificazioni dopo la prova su dispositivo (build 6, versione 1.1.0)

Il titolare ha portato a termine uno scontro intero su dispositivo con VoiceOver e ha giudicato lo scontro troppo macchinoso; ne è discesa una tranche di cinque semplificazioni decise, recepite nei consolidati (01 → 3.3, 02 → 2.2, 03 → 2.1) e realizzate:

1. **Gittata unica** (01 §3.4.1): via la doppia gittata e i suoi termini; portata binaria, resa piena entro la gittata; grandezza 03 §6.4 ridefinita.
2. **Proiettile del reparto** (01 §3.3.1): nessuna scelta di munizione al tiro; l'accoppiamento offesa-protezione resta e l'annuncio qualitativo pure. Il comando di tiro non trasporta più il proiettile: schema del giornale a 2, campioni e i due ori rigenerati con revisione esplicita (attrezzo `RigenerazioneOroTest`, solo con `RIGENERA_ORO`).
3. **Lettere dei reparti** (01 §9.4.3, RDA-53): assegnate in ordine di piazzamento per parte, mai riusate, nello stato e nell'impronta; annunciate dopo il nome e disegnate nella cella; nel pannello i bersagli si designano per nome e lettera.
4. **Volume avversario soppresso** (01 §9.3.7): gli annunci delle azioni avversarie non portano numeri di volume; in compenso l'ingresso in campo delle forze avversarie ora si annuncia con nome e lettera, come 02 §8.2.1 già chiedeva e la fase B non faceva.
5. **Esiti in fasce** (01 §9.7.2, RDA-52): stallo più quattro fasce per direzione, soglie provvisorie al 10 e 30 per cento in combattimento.json; mai numeri di danno negli annunci; la consistenza del reparto resta interrogabile sulla cella.

In più: l'azione di spostamento non si offre quando nessuna destinazione è raggiungibile (02 §9.5, provata anche nel pannello ospitato) e il manifest dei testi porta le impronte dei file (RDA-54), così i testi nuovi raggiungono le installazioni esistenti senza toccare versioni. Collaudo: 65 prove del pacchetto (una saltata: la rigenerazione degli ori) più 11 ospitate e 1 d'interfaccia, tutte verdi.

#### Accertamento sugli esiti degli scontri e due modificatori di posizione (build 7, versione 1.1.0)

Il titolare ha giocato tre scontri sulla build 6, vincendo il primo e perdendo i due successivi, e ha chiesto prima di accertare perché gli scontri vadano come vanno, poi di introdurre due modificatori. L'ordine è stato rispettato: l'accertamento è stato concluso e riferito prima di toccare le regole.

**Accertamento: nessun difetto.** Quattordici prove nuove, in due file costruiti in modo diverso l'uno dall'altro (`AccertamentoScontriTest`, `AccertamentoSecondaProvaTest`), accertano per esecuzione e non per ispezione: il verso dell'accoppiamento proiettile-protezione e arma-protezione (il poco adatto riduce, su tutta la matrice degli archetipi); che la protezione di chi colpisce non entri nel danno che infligge (contro-prova del verso); che scambiare tutte le protezioni scambi tutti gli esiti; la simmetria fra le parti su tutta la matrice e su uno scontro intero giocato due volte a parti scambiate; la cumulatività dei danni di più attaccanti, per somma, per invarianza rispetto all'ordine degli ingaggi e per decrescita togliendo un attaccante alla volta. Tutto regge. Le cause degli esiti osservati sono nei valori e in un fatto strutturale, misurati e riportati nel resoconto di sessione e in `valori-provvisori.md`: i mazzi dello scenario di prova assegnano protezioni non speculari, sicché la fanteria pesante del giocatore è il bersaglio migliore del campo per i tiratori avversari (97 punti contro 53 a parità d'ogni altra cosa, prima dei modificatori); il reparto accerchiato combatte a piena capacità in CIASCUN contatto, quindi tre contro uno infliggevano 258 punti a giro e ne subivano 416.

**Unica asimmetria trovata**, e non registrata fra i vantaggi nascosti perché va contro il giocatore: nell'annientamento simultaneo è sempre il giocatore a risultare sconfitto, per l'ordine di un'enumerazione. Fissata da una prova, non cambiata: la decisione spetta al titolare (registro degli scostamenti, P6).

**I due modificatori** (01 → 3.4 con la nuova sezione 9.10, 02 → 2.3, 03 → 2.2). Vicinanza nel tiro: il danno cresce linearmente al calare della distanza, nullo al limite della gittata e massimo alla minima; nessuna scelta al momento del tiro, la distanza è conseguenza della posizione. Accerchiamento: il danno cresce col quadrato dei concorrenti eccedenti il primo, con tetto nei dati; i concorrenti si ricavano dalla SOLA posizione — a contatto, adiacenti, o con il bersaglio entro la gittata — sicché i tiratori concorrono e l'insieme non dipende né dalle azioni già compiute né dall'ordine dei danni, restando coerente con la risoluzione simultanea. La maggiorazione va a chi stringe e mai a chi è stretto. Entrambi valgono per le due parti, provato a parti scambiate. Annuncio: due insiemi nuovi del vocabolario chiuso (a distanza/ravvicinato/a ridosso; stretto/circondato), nella voce di designazione del bersaglio e senza alcuna cifra; ordine fisso chiuso in 02 §9.3.1, e l'efficacia entra anche nella voce di ingaggio come 02 §9.2.1 già prescriveva (precisazione P7).

Effetto misurato sullo scontro osservato: tre contro uno passa da 258 a 413 punti inflitti a giro, contro 416 subiti. Il divario è quasi chiuso ma non lo è: il resto è taratura (03 §6.10) oppure una decisione sulla resa indivisa dell'accerchiato, che è del titolare.

I due ori sono stati rigenerati con revisione esplicita: entrambi conservano esito, vincitore, durata e sequenza dei comandi, e cambiano le sole cifre delle perdite nella direzione che l'accerchiamento prevede (primo oro: perdite del giocatore da 288 a 317, avversario annientato in 7 giri in entrambi i casi; oro delle riserve: perdite inflitte da 162 a 126, perché il reparto stretto da due pesanti cade prima e colpisce meno). Collaudo: 94 prove del pacchetto (una saltata: la rigenerazione degli ori) più 18 ospitate e 1 d'interfaccia, tutte verdi.

**Decisione attesa dal titolare (una sola).** La versione dei valori è rimasta a 0.1.0 come la regola impone (si cambia solo su sua istruzione), ma le regole del combattimento sono cambiate: uno scontro salvato con la build 6 si riaprirebbe quindi senza essere rifiutato e proseguirebbe con danni diversi da quelli visti. La nota per i tester dice di cominciare uno scontro nuovo; se il titolare vuole il rifiuto esplicito che il principio 15 prevede, basta la sua istruzione a portare la versione dei valori a 0.2.0.

#### Limite dei bersagli simultanei, annientamento simultaneo, versione dei valori (build 8, versione 1.1.0)

Quattro interventi decisi dal titolare (01 → 3.5, 02 → 2.4, 03 → 2.3, 05 → 1.1; RDA-55, RDA-56, RDA-57; P6 chiuso, P7 già registrato).

**1. Un reparto risponde ad al massimo due nemici** (nuova sezione 01 §9.11). Al primo a piena resa, al secondo con la resa ridotta dal malus dei dati (`resa_contro_secondo_bersaglio`, 0,5 provvisorio), dal terzo in poi per nulla: chi arriva terzo colpisce senza essere colpito. I posti si contano sull'ORDINE DI ARRIVO del contatto, che l'elenco `contatti` conserva per costruzione — vi si appende all'ingaggio e se ne rimuove senza riordinare — quindi si ricavano dal solo stato, si leggono una volta sola dallo stato d'ingresso del giro e non dipendono dall'ordine di applicazione dei danni. La successione nei posti liberati è automatica e gratuita: rimuovere un contatto fa scorrere in avanti i successivi, sicché il terzo diventa secondo e poi primo, con UNA SOLA regola valida per entrambi i posti (01 §9.11.2). Il caso «nessuna risposta» non calcola alcun danno anziché calcolarne uno nullo, che sarebbe risalito al minimo di 00 §13.6 (RDA-56). Undici prove in `LimiteBersagliTest`.

**Conseguenza sull'impronta** (RDA-55): l'ordine di arrivo è ora stato di gioco, quindi la codifica canonica serializza i contatti nel loro ordine e non più riordinati per identificatore — due stati che differiscono solo per quell'ordine si comportano diversamente e non possono avere la stessa impronta. Criterio generale scritto in 05 §2.9.

**2. Annientamento simultaneo** (nuovo 01 §15.2.5, RDA-57). Fra le due strade previste dal titolare si è scelta l'assegnazione e non la parità: la parità contraddice 01 §15.2.2 e avrebbe obbligato a rifare resoconto, ritorno in campagna (15.4–15.6, che presuppongono un vincitore) e registrazioni, mentre l'assegnazione tocca una riga. Sconfitto è l'avversario; la regola è iscritta fra i vantaggi nascosti (01 §13.2, 03 §7.2) e vive nei dati come interruttore, disattivabile dalla Verifica (05 §12.5). Tre prove: esito assegnato, interruttore spento, annientamento di una sola parte invariato.

**3. Versione dei valori a 0.2.0**, con `versioni_compatibili` alla sola 0.2.0: i salvataggi della build 7 sono ora rifiutati con la dichiarazione prevista da 00 §15.2. Regola generale che ne discende, scritta in 03 §9.2.1, richiamata in 05 §7.2 e in testa alla memoria di infrastruttura (regola 5, che prima diceva l'opposto): **la versione dei valori si incrementa ogni volta che cambia una regola che incide sul modo in cui una partita in corso si svolgerebbe**, non solo quando cambia la forma dei file. Criterio pratico: se una partita salvata prima, riaperta dopo, proseguirebbe diversamente, la versione sale. La versione di marketing resta discrezionale del titolare; quella dei testi pure, perché le impronte del suo manifest bastano al rinfresco.

**4. Misura dell'effetto congiunto e proposta non applicata** (03 §6.10.1–6.10.3). Sulla configurazione di riferimento — assalitori di fanteria pesante identici contro una fanteria pesante, un giro — il rapporto fra inflitto e subito è: con il passo di accerchiamento attuale 0,15 → 1,00 / 1,53 / 3,07 / 3,07 a uno, due, tre, quattro assalitori, con il bersaglio ANNIENTATO in un solo giro già a tre; con il solo limite e nessuna maggiorazione → 1,00 / 1,33 / 2,00 / 2,67, e il bersaglio sopravvive al primo giro fino a quattro. Il limite da solo produce quindi già la progressione voluta, regolare nel numero degli assalitori; la maggiorazione, scelta quando l'accerchiato restituiva ancora la resa piena a ciascuno, ora vi si somma e rende risolutivo il triplo contatto, che su griglia esagonale si ottiene senza fatica. **Proposta: passo di accerchiamento da 0,15 a 0,08** (1,08 / 1,32 / 1,72). NON applicata: i valori sono taratura e la scelta è del titolare. Annotata in 03 §6.10.2 e in `valori-provvisori.md`.

Ori rigenerati con revisione esplicita. Primo oro: stesso esito e stesso vincitore (avversario annientato), durata da 7 a 8 giri e giornale da 39 a 44 righe, perdite del giocatore da 317 a 308 — la mischia si risolve diversamente, quindi il copione guidato impartisce qualche ordine in più. Oro delle riserve: esito, durata e comandi identici, perdite inflitte da 126 a 108, perché il reparto solitario del giocatore, stretto da due pesanti, risponde a piena resa a uno solo dei due. Entrambi i vecchi giornali erano diventati inapribili, l'uno per comando non più valido e l'altro per versione incompatibile: il rifiuto della versione è esso stesso la prova che l'intervento 3 funziona.

Collaudo: 107 prove del pacchetto (una saltata, la rigenerazione degli ori) più 21 ospitate e 1 d'interfaccia, tutte verdi.

Da affrontare in seguito, annotato senza realizzarlo né progettarlo (osservazione del titolare): una persona cieca dalla nascita avrebbe grosse difficoltà se non conoscesse bene i rotori; il problema è di apprendimento, non di quantità di opzioni. Serve una **prima battaglia guidata** che insegni i rotori e i gesti mentre si gioca.

Costruito nella fase B:
- Campioni committati del giornale con prova di compatibilità (ogni caso di comando; i casi nuovi entrano nei campioni nella stessa modifica).
- Tattico avversario deterministico nel Motore (ufficiali.json, vantaggi-nascosti.json), pompato dalla Sessione; prove dei casi d'angolo delle mischie (contatti multipli, disingaggi doppi) con la precisazione P4; secondo oro con riserve nel mazzo a copertura della base delle perdite (RDA-46).
- Segnali: traduttore eventi-annunci collaudato per contenuto, coda annunci con lingua, aptica da file con motore mantenuto pronto, suoni generati per famiglia ritmica, assegnazioni di 02 §11.7.1.
- La battaglia accessibile in Applicazione/Sorgenti: griglia di elementi persistenti aggiornati sul posto (RDA-03), ordine di lettura dichiarato (02 §2.8 più RDA-49), deck, pannello della cella, designazione sulla griglia (scostamento S2), rotori del campo, tocco magico per lo stato, cambio riga con segnale, annullamento/azzeramento, resoconto (7 voci applicabili), impostazioni, apprendimento dei segnali, avvio con ripresa e rifiuto dei salvataggi incompatibili.
- Prove del fuoco automatiche (identità degli elementi, registro del guardiano del fuoco), prove degli annunci per contenuto (testa fissa, ordine con selezione, verbosità, vocabolario), fumo d'interfaccia; confini estesi alla Presentazione.

### Fase C — Verifica sugli scontri: NON COMINCIATA

Da dove partire: l'eseguibile Verifica ha lo scheletro; `ScenarioBattaglia` è già Codable per gli scenari dichiarativi (05 §12.2) e il tattico è riusabile per far giocare le due parti. Servono: lettura degli scenari da cartella, corse ripetute con semi e configurazioni agli estremi delle forbici (00 §13.2.4), metriche di battaglia di 03 §6.1, 6.2, 6.4, 6.6 in uscita CSV/JSON riproducibile (05 §12.6), fumo nel collaudo (05 §14.7). PUNTO DI ARRESTO: dopo la C ci si ferma; la fase D non comincia prima del ritorno dei tester, in nessun caso.

### Vecchio elenco della fase B (superato, conservato per riferimento)

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
- Il manifest dei valori contiene le impronte reali dei file: chi modifica un file di valori di fabbrica deve rigenerare le impronte (script Python inline usato in fase A, vedi cronologia git) altrimenti la versione diventa localmente derivata anche in fabbrica. Lo stesso vale per il manifest dei testi (RDA-54). Le VERSIONI dei due manifest non si toccano mai di propria iniziativa: solo su istruzione del titolare.
- L'accerchiamento di 01 §9.10.2 dà finalmente un effetto meccanico alla `tendenza_accerchiamento` degli ufficiali, che oggi governa soltanto l'ordine delle celle di piazzamento: il tattico non cerca ancora l'accerchiamento e non evita di esserne vittima. Non è stato toccato in questa tranche perché l'incarico non lo chiedeva; è il primo posto dove guardare quando si vorrà rendere l'avversario più competente.
- `Parte` vive in Dati ed è riesportata dal Motore (`@_exported import enum Dati.Parte` in Esagoni.swift).
