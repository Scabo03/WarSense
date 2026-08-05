# Stato dell'avanzamento — scrittura del codice

Documento di lavoro della fase 5. Aggiornato al termine di ogni fase e prima della chiusura di ogni sessione. Scritto per chi arriva senza memoria di quanto accaduto.

## Dove sono le cose

- Il codice è in `Codice/`: pacchetto SwiftPM con i bersagli di 05 §1.2. I documenti di progetto sono in `Fondamenta/`. Il repository git è alla radice, ramo `principale`.
- Comandi: `cd Codice && swift test` (tutto il collaudo), `swift run StrumentoVerifica` (programma di verifica: scontri e campagna), `swift build`. Le prove ospitate e d'interfaccia si eseguono dal progetto applicativo con lo schema di test.
- Dopo QUALUNQUE modifica a un file in `Contenuti/Valori/` o `Contenuti/Testi/`: `python3 scripts/rigenera-impronte.py`, nella stessa modifica. Senza, le installazioni esistenti restano con dati stantii (memoria di infrastruttura, regola 6). Lo script non tocca mai le versioni.
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

#### Risoluzione immediata dei contatti (build 10, versione 1.1.0)

Il titolare ha deciso di intervenire sulla SEQUENZA e non sull'ordine dei turni, che resta intatto (01 §9.4.1). Un contatto si risolve ora nell'istante in cui si forma, e poi a ogni giro nuovo finché dura (01 → 3.7 §9.7.1, 02 → 2.5 §8.9, 05 → 1.3 §3.9, RDA-60).

**Misura prima e dopo, sulle stesse ventiquattro configurazioni** (mazzi identici o comparabili, ogni combinazione di ufficiali, entrambi i primi occupanti, vantaggi spenti): sconfitto uguale al primo occupante in **21 casi su 24 prima**, in **13 su 24 dopo**. Tredici su ventiquattro è il valore atteso dal caso: la penalità sistematica è sparita. Prima di fidarsi della misura si è verificato che sappia muoversi, dando a una parte un mazzo dimezzato: la misura la vede perdere anche dal lato che altrimenti vince.

**Ordine dei propri reparti**: misurato, cambia l'esito in 5 casi su 6 e ribalta chi perde in 3. Da correggere una presunzione dell'incarico: l'ordine contava GIÀ prima della modifica, nella stessa misura (5 su 6), attraverso tiro e movimento; ciò che è nuovo è che ora conta anche in mischia.

**Sotto-decisione presa in corso d'opera** (RDA-60, 01 §9.8.5): la soglia di disingaggio non si valuta nello scambio immediato ma solo a inizio giro. La prima realizzazione la valutava sempre, e un reparto poteva ritrarsi nello stesso turno in cui gli era stato ordinato di attaccare — che 01 §9.8.2 esclude. L'ha fatto emergere il collaudo, cadendo a cascata su fixture che presupponevano contatti stabili.

**Riformulate le regole che presupponevano la simultaneità**: i posti in mischia (01 §9.11.1) e gli insiemi dei concorrenti (01 §9.10.2.3) si leggono ora all'apertura di CIASCUNA risoluzione, non una volta per giro; dentro una risoluzione la simultaneità resta intera. Aggiunto 01 §9.11.1.1: il posto di un reparto può cambiare fra una risoluzione e l'altra. L'impronta canonica non cambia struttura ma tutti i valori sì.

**Il corpo a corpo continua a non decidere**: nessuno dei 162 duelli uno contro uno si chiude con la dispersione, esattamente come prima. La modifica non ha toccato quel quadro. Riportato e non corretto, come da incarico: è materia di una decisione a sé.

Ori rigenerati: stesso esito e stesso vincitore in entrambi, battaglie più corte (da 8 a 6 giri e da 7 a 6), che è ciò che la risoluzione immediata prevede. Versione dei valori a 0.4.0. Collaudo: 115 prove del pacchetto (una saltata) più 21 ospitate e 1 d'interfaccia.

Da affrontare in seguito, annotato senza realizzarlo né progettarlo (osservazione del titolare): una persona cieca dalla nascita avrebbe grosse difficoltà se non conoscesse bene i rotori; il problema è di apprendimento, non di quantità di opzioni. Serve una **prima battaglia guidata** che insegni i rotori e i gesti mentre si gioca.

Costruito nella fase B:
- Campioni committati del giornale con prova di compatibilità (ogni caso di comando; i casi nuovi entrano nei campioni nella stessa modifica).
- Tattico avversario deterministico nel Motore (ufficiali.json, vantaggi-nascosti.json), pompato dalla Sessione; prove dei casi d'angolo delle mischie (contatti multipli, disingaggi doppi) con la precisazione P4; secondo oro con riserve nel mazzo a copertura della base delle perdite (RDA-46).
- Segnali: traduttore eventi-annunci collaudato per contenuto, coda annunci con lingua, aptica da file con motore mantenuto pronto, suoni generati per famiglia ritmica, assegnazioni di 02 §11.7.1.
- La battaglia accessibile in Applicazione/Sorgenti: griglia di elementi persistenti aggiornati sul posto (RDA-03), ordine di lettura dichiarato (02 §2.8 più RDA-49), deck, pannello della cella, designazione sulla griglia (scostamento S2), rotori del campo, tocco magico per lo stato, cambio riga con segnale, annullamento/azzeramento, resoconto (7 voci applicabili), impostazioni, apprendimento dei segnali, avvio con ripresa e rifiuto dei salvataggi incompatibili.
- Prove del fuoco automatiche (identità degli elementi, registro del guardiano del fuoco), prove degli annunci per contenuto (testa fissa, ordine con selezione, verbosità, vocabolario), fumo d'interfaccia; confini estesi alla Presentazione.

### Fase C — Verifica sugli scontri: CONCLUSA (build 9)

Criterio di uscita (05 §15.4, «programma di verifica sugli scontri e prima taratura dei valori di battaglia sui numeri, non a impressione»): **superato**. PUNTO DI ARRESTO RISPETTATO: la fase D non è cominciata e non comincia prima del ritorno dei tester.

**Il programma.** Libreria `Verifica` più guscio `StrumentoVerifica` (RDA-58): `swift run StrumentoVerifica`, con `--valori`, `--scenari`, `--uscita`, `--fumo`. Non contiene alcuna regola propria: fa agire il tattico del Motore su ENTRAMBE le parti — condotta pari per costruzione — e applica i comandi del Motore. Dove serviva una grandezza non esposta, la soglia di resa del tattico, è stata esposta dal Motore e non riscritta altrove. Scenari dichiarativi in `Contenuti/Scenari` (tre scontri più i parametri dei banchi), sostituibili senza ricompilare, con assi di un insieme chiuso; un asse ignoto è respinto in caricamento. La variazione viene dagli ESTREMI delle forbici e non dai semi, perché la battaglia non ha alcuna estrazione del caso (RDA-59): due corse sugli stessi dati danno lo stesso identico rapporto, e il collaudo lo verifica. Uscita CSV a sezioni, su schermo o in cartella. Fumo delle simulazioni dentro il collaudo (05 §14.7).

**Nove sezioni di misura:** versione dei valori; esiti per configurazione; riepilogo per scenario e per stato dei vantaggi (modo, durata, vittorie, scarto, soglia); soglie di resa per ufficiale e parte; redditività delle composizioni; bersagli di schieramento reparto per reparto; pesi dei modificatori isolati; curva del tiro per distanza con le fasce; progressione dell'accerchiamento; duelli di ogni archetipo contro ogni altro.

**Un difetto trovato dalla misura e corretto** (scostamento P8, 01 §15.2.3.1): il ritirante che evacuava tutto senza riserve nel mazzo vedeva la propria ritirata riuscita raccontata come annientamento, perché la condizione di annientamento era verificata per prima e senza guardare alla resa. Il vincitore non cambiava, il modo annunciato sì. Non era emerso prima perché scatta solo col mazzo vuoto, e il copione d'oro delle riserve lascia riserve di proposito.

**Una regola cambiata dalla taratura** (01 → 3.6): la curva del tiro va ora da una resa RIDOTTA al limite della gittata a una molto accresciuta alla minima distanza; prima non riduceva mai. Ne discende la riformulazione di 01 §9.9.3, che diceva che i modificatori non riducono mai la resa.

**Sette valori tarati sui numeri** (03 → 2.4, sezione 10 nuova con le misure): i due estremi della curva del tiro, il passo dell'accerchiamento, due parametri di carattere dell'ufficiale ordinario, la propensione all'attacco del prudente, la riduzione della propensione alla ritirata avversaria, e le composizioni dei due mazzi. Ciascuno con la misura che lo giustifica, in `valori-provvisori.md` e in 03 §5.15.1, §5.16.1, §5.18.1, §6.5.1, §7.4.1.

**Restano da tarare** e non sono tarabili ora: il costo dell'ammassamento oltre il secondo assalitore (03 §6.10.3), che chiede fianchi da scoprire e quindi la fase D; lo sbilanciamento del formato minore (03 §6.9), che chiede scenari realistici di quel formato; i tre parametri di carattere che governano imboscata e accerchiamento (03 §6.5.2); il margine di convenienza della ritirata (03 §6.2), il costo di mantenimento (§6.3) e tutte le grandezze di campagna, che presuppongono il piano che non esiste.

Collaudo: 115 prove del pacchetto (una saltata: la rigenerazione degli ori) più 21 ospitate e 1 d'interfaccia.

### Vecchio elenco della fase B (superato, conservato per riferimento)

L'infrastruttura è montata e provata (vedi memoria-infrastruttura.md): progetto applicativo in Applicazione/ (xcodegen, firma manuale sul certificato riusato, schermata provvisoria accessibile), caricamento su TestFlight con un solo comando (scripts/carica-testflight.sh, build 1 caricata), integrazione continua su GitHub, bersaglio Segnali creato con compilazione condizionale (RDA-48) e nucleo dei canali già collaudato.

Da dove partire:
1. Sostituire la schermata provvisoria con la Presentazione vera (UIKit programmatico, RDA-02) dentro Applicazione/Sorgenti.
2. Completare Segnali: realizzazioni di piattaforma dietro i blocchi condizionali (aptica pronta, suoni, coda annunci con lingua), tabella di 02 §11.7.1.
3. Griglia come contenitore di elementi accessibili persistenti (05 §10.1, RDA-03), ordine di lettura 02 §2.8, deck, pannello della cella, annullamento/azzeramento, rotori 02 §7.2, verbosità, impostazioni, schermata di apprendimento segnali, resoconto di fine battaglia (01 §15.3.1).
4. Tattico avversario di prima stesura nel Motore (deterministico, parametri ufficiale da `ufficiali.json` da creare).
5. Prove XCUITest del fuoco (05 §14.4, regole a–e di 05 §10.3).
Criterio di uscita: scontro completo giocabile solo con VoiceOver, consegnato ai tester via TestFlight (00 §16.3). Punto di arresto: nessun lavoro della fase D prima del ritorno dei tester; la fase C è parallela a quell'attesa.

### Fase D — La campagna singola: COMINCIATA, seconda unità conclusa

Criterio di uscita della fase (05 §15.5, «una campagna su una mappa, con battaglie vere, giocabile e riproducibile»): **non ancora raggiunto**, e non lo sarà finché non esisteranno rifornimento, conoscenza, imboscata, avversario e innesco della battaglia. Questa è la PRIMA UNITÀ di quella fase, e si è chiusa da sola.

#### Unità 1 — La mappa di campagna navigabile (build 11, versione 1.1.0)

Il ritorno dei tester sullo scontro non ha prodotto modifiche: il punto di arresto è caduto e la fase D si è aperta. L'unità realizza la mappa percorribile e comprensibile senza vedere lo schermo, e nient'altro: l'elenco di ciò che resta fuori è nella matrice di copertura, in coda.

**Che cosa esiste ora.** Mappa a caselle quadrate con adiacenza ortogonale e senza diagonali, nei tre formati di 01 §5.1 (quattro, sei, dieci), le cui dimensioni stanno in `formati-mappa.json` e non nel codice. Tre mappe dichiarative in `Valori/Mappe/` con terreno (aperto, bosco, acqua), tipo di strada (nessuna, sterrata, battuta, lastricata), strettoia facoltativa e i due quartier generali. Gruppi propri in numero libero, con nome proprio da un elenco chiuso, che dichiarano il proprio stato con il vocabolario ridotto a ciò che esiste — «in attesa», «ha agito». Giornata a un'azione per gruppo, con due sole azioni delle sedici di 01 §5.6.8.1: marcia di una casella adiacente e presidio. Informazione di stato al tocco magico, salto diretto al prossimo gruppo in attesa, registro degli eventi con voci che dichiarano il giorno. Ingresso dalla schermata iniziale con tre voci, una per formato.

**La decisione più delicata: il giornale.** Il giornale è anche il formato di salvataggio, e la campagna vi aggiunge tre casi nuovi. Nell'ordine, e prima di toccare nulla: si è fissata la codifica dei casi esistenti (nomi dei casi di voce e di comando, ricodifica byte per byte dei campioni committati) e si è aggiunta la riapertura, dal percorso reale, di un salvataggio della build distribuita a battaglia IN CORSO. Entrambe verdi PRIMA dell'aggiunta e rieseguite dopo: la codifica sintetizzata usa il nome del caso e non la sua posizione, quindi aggiungere non sposta nulla. Non è servito incrementare la versione del formato né rifiutare alcuna partita. La campagna vive inoltre in uno slot proprio, e una prova accerta che il salvataggio di battaglia continui a riaprirsi sulla stessa impronta (RDA-66).

**Versione dei valori: valutata e lasciata a 0.4.0.** Il criterio è 03 §9.2.1: la versione sale quando cambia una regola che incide sul modo in cui una partita in corso si svolgerebbe. Nessuna regola della battaglia è stata toccata, e nessuna campagna in corso può esistere, essendo la prima. I file nuovi entrano nel manifest con le proprie impronte, a versione ferma; le impronte si rigenerano ora con `scripts/rigenera-impronte.py`.

**Il programma di verifica esteso, in due mestieri distinti.** Gli INVARIANTI: `SondaInvariantiCampagna`, che vive fuori dal Motore e riceve dall'esterno ciò che giudica, proprio perché una prova possa darle in pasto un caso guasto (RDA-69). Sorveglia quindici condizioni — gruppo in due caselle, due gruppi in una casella, gruppo fuori mappa, azione spesa due volte, azione ordinata e non registrata, gruppo che agisce da sé, salto che dimentica o ripete o propone chi ha già agito, giorno fermo o all'indietro alla chiusura, giorno avanzato senza chiusura, azioni non azzerate, movimento non adiacente, casella percorribile irraggiungibile, registro fuori ordine. Il numero lo stampa il programma (`invarianti_sorvegliati` nel riepilogo) e una prova pretende che ciascuno abbia il proprio mutante: nella prima stesura ne dichiaravo dodici e due erano privi di mutante, senza che nulla lo rilevasse (scostamento S6).

Le MISURE, che nessuna taratura ha seguito: passi per chiudere una giornata con e senza il salto diretto; giornate per attraversare la mappa nei tre formati; caselle raggiungibili in una giornata.

**Che cosa il programma di verifica NON può dire**, ed è iscritto in `collaudo-solo-dispositivo.md`: se una persona che non vede si faccia un'immagine mentale della mappa, cioè se sappia dove sono le cose senza riesplorarle. È la domanda su cui il progetto è costruito e la risponde soltanto il titolare, sul dispositivo.

**Punti chiusi**, ciascuno con la ragione nel registro delle decisioni: RDA-61 (la giornata si chiude da sé: l'incarico diceva «su comando del giocatore», 01 §5.6.0.6 dice il contrario, e ha prevalso il consolidato), RDA-62 (la mappa riusa la cella della battaglia; il termine parlato è «casella»), RDA-63 (il quartier generale è geografia della mappa e occupa il posto delle opere nell'annuncio), RDA-64 (la chiusura della giornata non aggiunge un sedicesimo significato tattile), RDA-65 (il nome del gruppo è una chiave nello stato, non un indice), RDA-66 (casi nuovi nel giornale esistente, slot separati), RDA-67 (le voci di registro senza luogo non sono attivabili e lo dichiarano), RDA-68 (all'apertura il fuoco va al primo gruppo in attesa), RDA-69 (la sonda degli invarianti sta fuori dal Motore). Più due precisazioni, P9 e P10, e uno scostamento di percorso, S4.

**Un punto lasciato APERTO di proposito** (scostamento S5): 01 §5.1 dichiara tre formati, ma 01 §5.14.5.1 ne nomina un quarto, l'otto per otto, «il più frequente fra i formati minori». La discrepanza riguarda la portata della conoscenza, che è fuori perimetro; chiuderla senza il codice che la mette alla prova costerebbe, lasciarla aperta no. Aggiungere un formato è comunque una voce in un file di dati e nessuna riga di programma.

Collaudo: 189 prove del pacchetto (una saltata: la rigenerazione degli ori) più 31 ospitate e 1 d'interfaccia, tutte verdi.

#### Accertamento sui numeri riportati e correzione dell'annullamento (build 12, versione 1.1.0)

Il titolare ha sottoposto a controllo aritmetico tre numeri del resoconto della prima unità. L'accertamento e le sue conseguenze sono in `registro-scostamenti.md`, S6 e S7; qui il sunto.

**I numeri.** «Dieci giornate per attraversare la mappa grande» era misurato e giusto: sulla `pianura_lunga` i due quartier generali non stanno sulla stessa colonna, quindi la distanza vale dieci e non nove, e il programma lo stampa in una colonna che il resoconto aveva omesso. «Tredici caselle di bordo su sedici» e «trentasette su cento» erano numeri misurati di una grandezza DIVERSA da quella con cui li avevo nominati: il programma contava le caselle con meno di quattro uscite libere, non quelle di bordo, e le due differiscono di una casella — quella interna a nord del quartier generale, dove la misura colloca l'unico gruppo. Nessun difetto del gioco: nessuna casella è irraggiungibile, e una prova del Motore lo fissa insieme alla differenza fra le due grandezze. Nel corso della verifica è emerso un quarto numero sbagliato che nessuno aveva contestato: gli invarianti sorvegliati erano quindici e ne dichiaravo dodici, e due di essi non avevano alcun mutante.

**La protezione (RDA-71).** Il programma stampa ora `campagna_riepilogo`, il blocco unico da cui il resoconto copia i numeri, con i totali sommati dal programma; una prova pareggia quei totali con le righe di dettaglio. Le grandezze omonime hanno colonne distinte: `caselle_di_bordo` e `caselle_interne` sono geometria, `con_meno_di_quattro_uscite` e `di_cui_interne` dipendono dai gruppi. Una prova pretende che ogni invariante abbia il proprio mutante, ed è stata vista fallire togliendone uno.

**La generazione estesa (S7).** Da quattro scenari a dieci, da quattro conteggi di gruppi (1, 2, 3, 5) a otto (fino a dodici), con gruppi sparpagliati e stipati; la corsa conta ora gli ordini impartiti a gruppi senza alcuna destinazione, che prima non erano mai capitati e non c'era modo di accorgersene. Esito: 400 giornate, 2440 ordini, 217 dei quali in stipamento, ZERO violazioni. La copertura è cresciuta e non è emerso nulla.

**Il difetto vero, che il controllo sui numeri ha fatto trovare (RDA-70).** Annullare l'ordine che chiudeva la giornata era impossibile: l'operazione veniva rifiutata e il giorno restava avanzato. Era l'ordine più esposto all'errore — lo si impartisce per muovere un gruppo e se ne ottiene per soprammercato un cambio di giornata non richiesto — ed era l'unico irreversibile, contro 00 §13.8. Riprodotto con una prova rossa, corretto, e provato: annullando si torna indietro anche di più giornate, un ordine per volta, e il giornale rigiocato dopo l'annullamento dà lo stesso stato anche cancellando le istantanee. La riapertura si annuncia con una frase propria. Quando lo stratega avversario esisterà, il punto di conferma di 05 §6.5 dovrà tornare a mordere: il posto dove imporlo è dichiarato nel codice.

**Che cosa sente il giocatore alla chiusura della giornata**, fissato da una prova e non descritto a memoria: due frasi, «Corvo presidia in riga 4, casella 2» e «Giornata conclusa: comincia il giorno 2», più il segnale di conferma dell'ordine. La chiusura non ha segnale proprio (RDA-64) e non ha frase propria: la racconta l'apertura.

Collaudo alla fine della prima unità: 204 prove del pacchetto (una saltata) più 31 ospitate e 2 d'interfaccia, tutte verdi.

#### Seconda unità — registro, annuncio, confine dell'annullamento, costo in giorni

Nata da due difetti riferiti da chi ha usato il gioco e da tre decisioni del titolare.

**Registro** (`FattoRegistrato`, `SchermataRegistro`, `TraduttoreEventiCampagna.voceDiRegistro`). I fatti annotati sono ora `marciaOrdinata`, `presidioOrdinato`, `ordineAnnullato`, `giornataAzzerata`; `giornataAperta` è soppresso, perché il giorno è una proprietà di ciascuna voce e non una voce a sé. Deroga dichiarata a 01 §5.17.1, che escludeva gli ordini del giocatore (scostamento S8, RDA-72). Le voci prive di luogo sono `UILabel` con tratto di testo statico e non più pulsanti disabilitati: il colore dello stato inattivo dava un contrasto di 1,68 contro 1 sul fondo di sistema, cioè un elemento agganciabile dalla voce e invisibile all'occhio. Prova di classe che misura i PIXEL, non le proprietà: `RegistroVisibileTest`, con il proprio mutante.

**Annuncio di casella** (`VistaCampagna.vociDiCasella`, RDA-74). Le caratteristiche della casella hanno un elenco solo, da cui derivano sia la frase sia i segni disegnati: la divergenza fra il piano sonoro e quello visivo è ora impedita dal compilatore. Le frasi del registro hanno un solo autore, il traduttore dei Segnali. Il difetto riferito sull'annuncio in designazione non è stato riprodotto: vedi P12.

**Confine dell'annullamento** (`SessioneCampagna.ordineDentroIlConfine`, RDA-73, S9). Annullamento pieno dentro la giornata; l'ordine che ha chiuso la precedente è annullabile finché nella giornata nuova non è accaduto nulla; oltre, rifiuto con termine proprio. Il confine vive nel giornale (`VoceGiornale.annullamentoCampagna`) e non nello stato, perché lo stato si ricostruisce riapplicando i comandi e il confine sparirebbe alla ripresa.

**Costo in giorni** (`ValoriMarcia`, `MotoreCampagna.costoInGiorni`, `ComandoCampagna.marcia(gruppo:a:giorni:)`, RDA-75). Valore esplicito nei dati, oggi uno; il comando lo trasporta; `FondazioneCampagna.schemaCorrente` sale a 2. L'identità fra una casella e una giornata non è una regola: è il caso particolare che quel valore produce, ed è dichiarato tale.

**Misure** (`BancoCampagna.Disposizione`, `misuraDistanzaFraQuartierGenerali`). Il costo di chiusura di una giornata si misura da uno a dodici gruppi, sui tre formati, con i gruppi raccolti presso il quartier generale e sparpagliati. La sezione `campagna_attraversamento` è ora `campagna_distanze`, con `distanza_fra_quartier_generali` accanto a `distanza_massima_fra_due_caselle`; `campagna_caselle_raggiungibili` è `campagna_uscite_libere` e l'interrogazione `caselleRaggiungibiliInUnaGiornata` è `usciteLibere`, perché il nome presupponeva l'identità casella-giornata.

Collaudo alla fine della seconda unità: 217 prove del pacchetto (una saltata) più 42 ospitate e 2 d'interfaccia, tutte verdi.

#### Sessione degli strumenti e dei cancelli (nessun perimetro di gioco toccato)

Non è un'unità della fase D: non aggiunge regole, non tara valori, non estende il gioco. Chiude tre cancelli, corregge il tocco diretto e costruisce l'impianto di prova sul simulatore. Nasce da `esame-critico.md`, che aveva stabilito il fatto su cui la sessione è costruita: in questo progetto le regole scritte vengono disattese e i controlli che rifiutano no.

**I tre cancelli.** `scripts/collaudo-completo.sh` è ora la sola definizione di «tutto il collaudo» — pacchetto, ospitate, interfaccia — e la invocano sia `.github/workflows/collaudo.yml` sia `scripts/carica-testflight.sh`; prima entrambi si fermavano a `swift test` e le 44 prove di livello applicativo non erano cancello per nulla. `CompatibilitaGiornaleTest` lega i tre tipi del formato di salvataggio a uno specchio `CaseIterable` con due funzioni esaustive, sicché un caso nuovo non compila finché non se ne dichiara la specie e non se ne costruisce l'esemplare, e la prova poi fallisce finché il campione manca (RDA-79). `scripts/controlla-nota-titolare.py` rifiuta il caricamento se la nota per il titolare manca, nomina qualcosa che il codice non espone, porta un numero che il programma di verifica non produce più, o è più vecchia dell'ultimo commit del codice (RDA-80). Ciascuno dei tre è stato visto rifiutare prima di essere considerato attivo.

**Il tocco diretto (RDA-78, P11 chiuso).** `VistaACaselle` è la base condivisa da `VistaGriglia` e `VistaMappa`: il riconoscitore risolve il punto nell'elemento e ne invoca `accessibilityActivate()`, cioè la stessa porta della tecnologia assistiva. Nessun secondo ramo da tenere allineato; la divergenza fra i due piani non è scrivibile. Prova rossa prima della correzione: `ToccoDirettoTest.test_02_2_11_le_due_griglie_hanno_un_percorso_per_il_tocco_diretto`, su entrambi i piani.

**L'impianto d'interfaccia, consegnato INCOMPLETO.** `ImpiantoInterfacciaTest` (sei prove) esercita il gioco attraverso il servizio di accessibilità vero; `CatenaInterfacciaMotoreTest` accerta che l'etichetta esposta coincida con quella che il Motore prescrive. Mancano due verifiche che l'incarico chiedeva, e mancano dichiarate: la catena intera e il tocco sintetizzato su una griglia scorrevole. Che cosa è stato escluso, che cosa è emerso e che cosa resta ignoto è in `registro-scostamenti.md`, S10. **Chi riprende comincia da lì.**

**Le partite simulate non sono state cominciate.** Erano la sesta sezione dell'incarico e non è stata aperta, per non consegnarla a metà.

Collaudo alla fine della sessione: 218 prove del pacchetto (una saltata), 50 ospitate, 8 d'interfaccia, tutte verdi.

### Fasi E–G: NON COMINCIATE

La fase C ha già lo scheletro dell'eseguibile `Verifica` e la forma degli scenari (`ScenarioBattaglia` è Codable proprio per gli scenari dichiarativi di 05 §12.2).

## Intervento correttivo della revisione del titolare (dopo la fase A)

Applicato l'incarico di intervento sulle chiusure: la base delle perdite per la resa e per ogni soglia di battaglia è ora costituita dalle sole forze effettivamente impiegate sul campo, come contatore cumulativo che cresce a ogni piazzamento (consolidato 01 alla versione 3.2, punti 10.2 e 10.2.1; registro RDA-46; nel codice il campo dello stato si chiama forzeImpegnate). Il divieto di fuoco amico è diventato regola dichiarata (01 punto 9.6.2, RDA-47) con prova di persistenza dedicata. L'imposizione della battaglia che consuma la giornata è confermata per iscritto sotto RDA-25. Collaudo a 44 prove, tutte verdi; la riproduzione d'oro è rimasta valida perché nello scontro registrato l'intero mazzo scende in campo e le due basi coincidono.

## Avvertenze per chi riprende

- Il guidatore tattico dentro `SessioneBattagliaTest.giocaBattagliaCompleta` è un attrezzo di prova, non il tattico avversario: quello vive nel Motore (05 §5.3) e il programma di verifica lo usa per entrambe le parti.
- Il programma di verifica si lancia con `swift run StrumentoVerifica` (NON `swift run Verifica`: `Verifica` è la libreria, RDA-58). Prima di tarare qualunque valore si esegue una corsa e si legge la misura; nessun valore si cambia a occhio.
- La frequenza di vittoria delle due parti si legge sulle sole corse a VANTAGGI SPENTI: accesi, lo scarto misura quanto valgono i vantaggi, che è un'asimmetria voluta (03 §7.4.2).
- La riproduzione d'oro si rigenera SOLO con revisione esplicita: aggiornare insieme `giornale.jsonl` e `impronta.txt` in `Codice/Tests/SessioneTest/RiproduzioneOro/` e dichiararlo nel commit.
- Il manifest dei valori contiene le impronte reali dei file: chi modifica un file di valori di fabbrica deve rigenerare le impronte (script Python inline usato in fase A, vedi cronologia git) altrimenti la versione diventa localmente derivata anche in fabbrica. Lo stesso vale per il manifest dei testi (RDA-54). Le VERSIONI dei due manifest non si toccano mai di propria iniziativa: solo su istruzione del titolare.
- L'accerchiamento di 01 §9.10.2 dà finalmente un effetto meccanico alla `tendenza_accerchiamento` degli ufficiali, che oggi governa soltanto l'ordine delle celle di piazzamento: il tattico non cerca ancora l'accerchiamento e non evita di esserne vittima. Non è stato toccato in questa tranche perché l'incarico non lo chiedeva; è il primo posto dove guardare quando si vorrà rendere l'avversario più competente.
- `Parte` vive in Dati ed è riesportata dal Motore (`@_exported import enum Dati.Parte` in Esagoni.swift).
- La campagna e la battaglia condividono `Cella` e il giornale, e NIENT'ALTRO: griglie, stati, comandi, motori, sessioni e schermate sono distinti (`*Campagna`). Gli slot di partita sono cartelle diverse.
- Chi aggiunge un caso a `ComandoBattaglia`, a `ComandoCampagna` o a `VoceGiornale` DEVE aggiungere il campione corrispondente in `Tests/SessioneTest/CampioniGiornale/campioni.jsonl` nella stessa modifica. Non è una raccomandazione: `CompatibilitaGiornaleTest` lega ciascuno dei tre tipi a uno specchio `CaseIterable` con due funzioni esaustive, sicché **il caso nuovo non compila** finché non se ne dichiara la specie e non se ne costruisce l'esemplare, e la prova poi **fallisce** finché il campione manca. Fino al 2026-08-05 la prova non esercitava questa protezione su nessuno dei tre tipi: confrontava i casi trovati nei campioni con un letterale scritto a mano, e un caso senza campione mancava da entrambi gli insiemi lasciandoli uguali. Nessun caso si rinomina né si sposta: la codifica usa il nome del caso come chiave, e rinominarne uno rende illeggibili i giornali già scritti.
- Il giornale dichiara la propria natura dalla prima riga: `fondazione` per uno scontro, `fondazioneCampagna` per una campagna. `Giornale.apri` accetta entrambe; ciascuna Sessione legge la propria.
- La sonda degli invarianti di campagna riceve dall'esterno ciò che giudica (stato, transizione, sequenza del salto, adiacenza) proprio perché le prove possano darle un caso guasto. Chi la modifica conservi quella forma, altrimenti i mutanti non sono più scrivibili (RDA-69).
- Il dimensionamento dell'unità successiva — la marcia di più giorni — è in `impatto-marcia-lunga.md`: che cosa regge senza modifiche, che cosa va rifatto, quale portata ha sul formato di salvataggio. La conclusione operativa è che la risoluzione di fine giornata va costruita PRIMA della marcia lunga e non insieme.
- Gli INCARICHI ricevuti e i resoconti consegnati si conservano in `Incarichi/`, versionati e verbatim. Prima del 2026-08-05 non se ne conservava traccia, e `esame-critico.md` ha dovuto dichiarare non verificabile il confronto fra richiesto e realizzato.
- Il COLLAUDO COMPLETO si esegue con `./scripts/collaudo-completo.sh`, che è anche il cancello del caricamento e dell'integrazione continua. `swift test` da solo copre 218 prove su 276.
- La regola sulla FORMA DEI RESOCONTI di sessione è in `forma-dei-resoconti.md`, che è memoria permanente: si scrivono per un lettore tecnico, e la prescrizione opposta è revocata. Richiamata anche in `memoria-infrastruttura.md`.
- Il REGISTRO della campagna vive nello stato, che si ricostruisce riapplicando i comandi del giornale: un fatto che l'annullamento deve poter lasciare dietro di sé — l'annullamento stesso — non può stare nel solo stato, e ha una voce propria nel giornale (RDA-73). Chi aggiungerà altri fatti che sopravvivono a un troncamento faccia lo stesso.
- Il CONFINE dell'annullamento si legge dal giornale e non dallo stato, per la stessa ragione. Chi lo tocca esegua `AnnullamentoGiornataTest`, che contiene la prova della sopravvivenza alla ripresa.
- Ciò che una casella DICHIARA sta in `VistaCampagna.vociDiCasella` e in nessun altro posto: chi aggiunge una caratteristica la aggiunge lì, e il compilatore lo obbliga a darle sia una frase sia un segno disegnato (RDA-74).
- Il COSTO IN GIORNI dello scatto vale uno e viene dai dati. Non è una regola: è una semplificazione provvisoria (RDA-75, `valori-provvisori.md`). Nessuna sessione futura la citi come decisione presa per rifiutarne la modifica.
