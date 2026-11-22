# Il regno: piano di costruzione per tappe

Documento di lavoro dell'incarico 30 (2026-11-22). Non è un consolidato: registra come si intende costruire ciò che i consolidati già prescrivono, in quale ordine e con quali dipendenze. Le scelte di gioco che i documenti non risolvono stanno, separate, in `Proposte/domande-per-il-titolare-sul-regno.md`; le decisioni tecniche prese per la prima tappa stanno nel registro delle decisioni architetturali (RDA-162 e seguenti).

Convenzioni di rinvio: quelle del documento 05 (01 §n, 02 §n, 03 §n, A §n per il documento 05, MC §n per `modalita-a-campioni.md`, RDA-nn).

## 1. Che cosa prescrivono i documenti, per materia

| materia | punti |
|---|---|
| perimetro del regno, canale astratto della ricchezza | 01 §1.3, §1.3.1, §5.5 |
| le cinque risorse, la moneta, il riporto | 01 §5.5.1–5.5.1.5; 02 §4.4.1.4; 03 §4.4.1–4.4.2; direzione dei nodi 2-3 §8–§11 |
| ciò che alimenta le risorse | 01 §2.6 («le vittorie in campagna alimentano le risorse del regno»); decisioni della fase due, ECO-09; MC §8.1 |
| stagioni, inverno, quattro schermate | 01 §5.9–5.9.4; 02 §6.5.2, §8.7–8.7.3; A §2.3, §3.5, §6.2; RDA-39 |
| annuncio del costo e riquadro delle riserve | 01 §5.9.1.5; 02 §8.7–8.7.2 |
| reclutamento, addestramento, miglioramenti, deperibilità, mantenimento | 01 §4.12–4.14.1, §5.4.2; 03 §4.4.3, §6.3; decisioni della fase due §1.32 |
| assetti, totali, resti, riordino | 01 §4.7–4.11, §5.6.8.1; A §2.4 |
| acquisizioni, tetti d'epoca, soglia distribuita, passaggio di fase | 01 §2.5–2.8.2.2, §3.2.3; 03 §4.7; A §3.6, §7.7 |
| opere permanenti | 01 §5.5.2, §5.14.2–5.15; 03 §4.4.5, §4.5 |
| manutenzione e riparazione delle macchine | 01 §5.7.1, §12.2, §12.3; 02 §4.4; 03 §4.9.2 |
| voci acquistabili fuori dall'inverno | 01 §5.5.1.4, §5.5.1.4.1; RDA-29 |
| patria, architettura dei luoghi, registro della patria | 01 §5.6.10–5.6.10.3, §5.17, §5.17.1; 02 §6.5.4, §6.6, §6.7; A §9.3 |
| inverno degli avversari, simmetria, apporto informativo, governo | 01 §5.9.1.6–5.9.1.8, §14.1, §14.6, §14.7; A §5.3, §5.4; 03 §6.7 |
| il regno nella modalità a campioni | MC §1.3, §8; 00 contesto e §12.2 |
| conclusione della campagna | 01 §5.14.2, §5.14.3.2–5.14.3.4; A §2.11, §9.3 |
| ordine di costruzione | A §15.6 (fase E, il regno e l'inverno: «un anno intero giocabile»), §15.7 (fase F, il mondo) |

Ciò che i documenti NON dicono, e che il piano tratta come domanda o come valore provvisorio: quanto valga la rendita e quanto l'esito (domanda 1); quante giornate duri una stagione (domanda 2); come si chiuda la campagna che l'inverno interrompe (domanda 3); la resa della campagna (domanda 4); il mantenimento dei reparti ordinari e che cosa accade a chi non si mantiene (domanda 5); che cosa facciano scorte e derrate (domanda 6).

## 2. Il modello: uno strato sopra la campagna

2.1 **Tre strati, tre giornali che si toccano.** Oggi esistono due strati, ciascuno con Motore, Sessione e giornale propri: la battaglia (`StatoBattaglia`, `SessioneBattaglia`) e il fronte (`StatoCampagna`, `SessioneCampagna`), e il giornale del fronte riceve l'esito della battaglia come riga autosufficiente (`battagliaConclusa`). Il regno è il terzo strato, costruito con la stessa disciplina: `StatoRegno`, `MotoreRegno`, `SessioneRegno`, un giornale proprio nello slot del regno, e la campagna dell'anno in uno slot annidato; il giornale del regno riceve l'esito della campagna come riga autosufficiente (`campagnaConclusa`), così che rigiocarlo riproduca il regno senza rileggere i file della campagna. È l'articolazione di A §2.3 (`StatoPartita` con regno, mondo, fronti, battaglia, inverno) realizzata per slot annidati anziché in un unico valore: la scelta e il suo costo sono in RDA-162.

2.2 **Lo stato del regno** (A §2.4; nella prima tappa ne esiste la parte segnata): calendario — anno, momento dell'anno (stagione operativa oppure inverno con la stazione corrente fra le quattro) ✔; le cinque risorse con i saldi ✔; la base del riporto ✔; le forze militari ✔ (forma della modalità, punto 2.4); i lavori ordinati con il momento in cui sono pronti ✔ (nella prima tappa: le sole leve); l'esito della campagna dell'anno ✔; il registro della patria ✔; la fase storica e il materiale monetario ✔ (ferma all'arcaica); acquisizioni e tetti; miglioramenti e mantenimento; opere; il mondo (regni avversari, fronti, territori).

2.3 **I comandi del regno** (A §3.5; ✔ nella prima tappa): apri la campagna su un fronte ✔; (la conclusione della campagna non è un comando: è l'esito iscritto nel giornale) ✔; attendi l'inverno ✔; ordina lavoro — nella prima tappa la leva ✔; prosegui alla stazione successiva ✔; recluta fuori inverno, scorte, riparazione; addestra o migliora; mantieni miglioramento; acquisisci; ordina opera; assegna truppe a fortezza; conferma del passaggio di fase. Annullamento e azzeramento delle spese sono operazioni del giornale (A §6.4, 00 §13.8) ✔.

2.4 **Le due modalità.** Il regno è identico nelle due modalità e cambiano soltanto le voci militari (01 §1.2, MC §1.3). Nel modello questo è una sola cucitura:

- comune, e mai dipendente dalla modalità: calendario, risorse, bilancio, riporto, stazioni, voci con costo e momento in cui sono pronte, annuncio del costo sulla riserva, registro, acquisizioni e tetti, opere, governo avversario;
- della modalità: la forma delle **forze** (`ForzeDelRegno`, tipo somma: nella modalità a sciami le formazioni con i loro reparti di atomi; nella modalità a campioni l'organico dei combattenti e gli eroi, con infortuni e recuperi, MC §6.2, §7.7, §8.4) e i **ganci d'effetto** delle voci militari (A §7.7: insieme chiuso definito dal Motore). Una voce del file dei valori dichiara costo, durata e un gancio: `recluta_reparto` (archetipo, atomi) per gli sciami; per i campioni i ganci si aggiungeranno (`recluta_combattente` con classe, sottoclasse, arma, equipaggiamento; `migliora_persona`; `migliora_istituzione`: MC §8.2) senza toccare il resto. Lo stesso vale per ciò che il regno consegna a una campagna (le forze che partono) e ciò che ne riceve (i superstiti): è la forma delle forze a deciderlo, non il regno.

Ne discende la regola di costruzione: nessuna funzione del Motore del regno fuori dai ganci militari nomina archetipi, atomi, reparti o gruppi. Un controllo del collaudo la fa rispettare (cancello 3 della prima tappa).

2.5 **Il calendario.** L'anno conta tre stagioni operative di uguale numero di giornate e l'inverno, che non ha giornate ma quattro stazioni (01 §5.9, §5.9.1.2). Il numero di giornate per stagione è un valore del file `regno.json`, provvisorio (domanda 2). Il fronte conserva il proprio calendario in giornate (01 §5.6.9.1): la campagna dell'anno nasce con il calendario che il regno le dichiara e si ferma da sé chiusa l'ultima giornata d'autunno.

## 3. Le tappe

Ogni tappa ha un perimetro chiuso, consegna qualcosa che si gioca attraverso l'interfaccia e che pilota e tester verificano con VoiceOver, e dichiara le dipendenze. L'ordine proposto è quello della numerazione; dove un ordine diverso è possibile lo dice la riga delle dipendenze.

### Tappa 1 — L'anno del regno (questa sessione, build 31)

**Perimetro.** La patria come schermata propria, con la data, il riquadro delle riserve, le forze, il registro. Il calendario dell'anno. La campagna dell'anno, aperta dalla patria su uno dei tre fronti esistenti, con le forze del regno al posto delle forze fisse dello scenario; la sua conclusione nel minimo (sezione 4); l'esito che arriva al regno e la dichiarazione di conclusione. L'inverno con le quattro stazioni: il bilancio che nasce dalla rendita e dall'esito, una sola specie di voce — la leva, cioè il reclutamento di un reparto —, l'annuncio del costo sulla riserva, l'impossibilità dichiarata con la risorsa che manca, annullamento e azzeramento delle spese. La primavera: il riporto al dieci per cento, le reclute che raggiungono l'esercito come gruppo nuovo al quartier generale, i caduti che non tornano.

**Che cosa si gioca di nuovo.** Dall'avvio, «Nuovo regno». In patria si sente la data e si percorrono riserve e forze; si apre la campagna scegliendo il fronte; la campagna si gioca com'è oggi, e in più dichiara la stagione; finisce quando una parte resta senza gruppi armati o quando arriva l'inverno; la dichiarazione di conclusione dice com'è finita e che cosa torna in patria; in patria comincia l'inverno, con il bilancio; si ordinano leve finché le risorse bastano; alla quarta stazione si prosegue alla primavera, e la campagna nuova parte con i superstiti e con le reclute.

**Verifica.** Pacchetto: regole del regno, giornale e ripresa, rigiocatura identica, invarianti con il mutante. Ospitate: la patria (ordine di lettura, formato degli annunci, fuoco fermo dopo una spesa, gesto di fuga, testo alla dimensione massima). Interfaccia e sessioni complete: un anno intero attraverso l'interfaccia. Pilota e tester con VoiceOver su iPhone e iPad: un anno fino alla seconda primavera.

**Dipendenze.** Nessuna tappa. Poggia su campagna e battaglia esistenti.

**Che cosa non contiene, dichiarato.** Le notizie fra una stazione e l'altra (tappa 3); le linguette per durata, perché esiste una sola durata (tappa 2); il mantenimento (tappa 2); gli avversari come regno: ogni primavera il fronte ripropone le forze avversarie del suo scenario (tappa 3); la scelta di quali forze mandare e di come comporle in patria: partono tutte, composte come sono tornate (tappa 2); più campagne o più fronti nello stesso anno (il mondo).

**Domande da cui dipende la forma definitiva** (costruita su valori provvisori e sulla lettura minima dei documenti): 1, 2, 3.

### Tappa 2 — Addestrare, migliorare, mantenere; le durate

**Perimetro.** Le voci dell'inverno diventano di durata diversa: reclutamento con addestramento, miglioramento mirato di un reparto esistente (01 §4.13), mantenimento dei miglioramenti che altrimenti si perdono (01 §4.14), e il costo di mantenimento come freno (01 §4.14.1, 03 §6.3). Con le durate entrano le linguette ordinate per durata (01 §5.9.1.3, RDA-39), la dichiarazione di quando un lavoro sarà pronto (01 §5.9.1.4) e gli arrivi differiti: ciò che matura in estate o in autunno raggiunge il quartier generale a campagna aperta (01 §5.2.1, §5.17.1). Gli assetti e il riordino (01 §4.7–4.11): reclutare per assetti, totali per archetipo con i resti, azione di riordino sulla mappa; i nomi dei gruppi che restano gli stessi da un anno all'altro; la scelta di quali forze mandare al fronte.

**Che cosa si gioca.** Un inverno in cui ordinare alla prima o alla quarta stazione cambia quando la cosa arriva; un reparto migliorato che in battaglia rende di più e che l'inverno dopo va mantenuto o decade; le truppe che arrivano a campagna aperta.

**Verifica.** Come la tappa 1, più una prova d'interfaccia sull'arrivo a campagna aperta e sul reparto migliorato in battaglia.

**Dipendenze.** Tappa 1. **Domande:** 5 (mantenimento dei reparti ordinari). Tocca i valori dei reparti in battaglia: la versione dei valori sale (03 §9.2.1).

### Tappa 3 — L'inverno degli avversari

**Perimetro.** Il regno avversario con le stesse cinque risorse e le stesse regole (01 §5.9.1.8); il governo, terzo organo dell'avversario (A §5.3), che d'inverno spende come il giocatore, per comandi ordinari; le forze che il fronte gli trova davanti in primavera sono quelle che il suo regno ha — è la decisione del titolare del 22 novembre, RDA-163; la difficoltà generale che agisce sulle sue risorse (01 §14.1, A §5.4). L'apporto informativo fra una stazione e l'altra (01 §5.9.1.6, §5.9.1.7): fondo minimo vago, precisione che cresce, mai certezza; nella modalità a campioni la deroga di MC §3.

**Che cosa si gioca.** Le notizie fra le stazioni, che danno alle quattro schermate la loro ragione; un avversario che dopo una sconfitta torna più debole e dopo un inverno ben speso più forte.

**Verifica.** Banco del regno a due governi su più anni, con le metriche di partita lunga (03 §6.3, §6.7); pilota e tester sulle notizie d'inverno. Ripetere la misura della frequenza delle battaglie: è qui che la proposta dell'incarico 29 trova la sua leva.

**Dipendenze.** Tappa 1; tappa 2 per le voci che il governo compra. Può precedere la tappa 2 se il governo compra soltanto leve.

### Tappa 4 — Le tre voci fuori dall'inverno e la riparazione delle macchine

**Perimetro.** Il riporto diventa spendibile durante l'anno nelle tre voci di 01 §5.5.1.4.1: avvio del reclutamento con arrivo differito, scorte e derrate, riparazione delle macchine. Lo stato di manutenzione delle macchine — efficiente, logora, guasta —, il degrado, la prova di guasto estratta col seme e dichiarata prima come possibilità (01 §5.7.1, §12.2, §12.3; 02 §4.4), l'azione di manutenzione sulla mappa (01 §5.6.8.1), le riparazioni d'inverno e quelle brevi. La segnalazione, nell'informazione di stato, che in patria c'è qualcosa da vedere (01 §5.6.10.3).

**Che cosa si gioca.** Una macchina che si logora marciando, la possibilità di guasto annunciata, la riparazione ordinata dalla patria a campagna aperta.

**Dipendenze.** Tappa 1 (riporto); tappa 2 (arrivi differiti). Introduce il caso fuori dallo scontro: il seme della partita entra nello stato. **Domande:** 6 (scorte e derrate). Punto aperto MC §11.10 per la modalità a campioni: non va deciso di iniziativa.

### Tappa 5 — Le acquisizioni e il passaggio di fase

**Perimetro.** I cinque ambiti e le acquisizioni di 01 §2.8.2.1 con costi, durate, prerequisiti ed effetti tipizzati (A §7.7); i tetti d'epoca e l'ambito che si chiude (01 §2.6.2.1); la soglia distribuita, senza alcun quadro che la dichiari (01 §2.6.2.2); il riquadro del passaggio di fase con la conferma, il cambio d'ambiente sonoro e la moneta che cambia nome (01 §2.6.3.1, §5.5.1.3); gli archetipi che si sbloccano e la piattaforma trainata che diventa obsoleta (01 §3.2); le truppe vecchie che restano quelle che sono (01 §2.8.1).

**Che cosa si gioca.** Un ambito che arriva in fondo e lo dice; il riquadro del passaggio; il primo reparto di tipo nuovo, raro in mezzo a un esercito d'epoca precedente.

**Dipendenze.** Tappa 2 (durate, addestramento del nuovo); tappa 3 perché gli avversari progrediscano con gli stessi tetti (01 §14.6). Il mutamento del mondo attorno al regno (01 §2.6.4) appartiene al mondo.

### Tappa 6 — Le opere permanenti

**Perimetro.** Fortezza, torre di osservazione, magazzino avanzato, ponte, guado attrezzato, palizzata, vie di accesso (01 §5.14.2–5.15): ordinate d'inverno nella prima linguetta su una casella di territorio controllato, con gli effetti sulla mappa del fronte (quartier generale secondo, zona di rifornimento, conoscenza, costo di attraversamento, strada impressa) e sull'apporto informativo (torri).

**Dipendenze.** Tappa 2 (durate lunghissime); tappa 3 (apporto informativo, e perché l'avversario costruisca e si venga a saperlo); e, fuori dal regno, la conclusione completa della campagna e il possesso dei territori: «quando una campagna si conclude con successo in un certo territorio, in quel territorio si possono ordinare nell'inverno successivo» (01 §5.14.2). Senza un esito territoriale non c'è dove costruire: è l'ultima tappa per questa ragione.

### Fuori dal regno, per memoria

- **Il completamento della campagna**: presa del quartier generale, resa, e le correzioni emerse dall'incarico 29 (battaglie che al banco non si concludono, squilibrio delle vittorie fra le mappe, virgola delle azioni d'ingaggio). Un incarico successivo.
- **Il mondo** (A §15.7): più campagne e più fronti con lo scarto massimo, la schermata delle campagne, il regno lontano e la sua specializzazione, il mutamento del mondo al passaggio di fase. Quando esisterà, le tre campagne di prova dell'avvio spariscono: la campagna si aprirà soltanto dalla patria.
- **Le voci militari della modalità a campioni**: `Proposte/classi-dei-campioni.md` ne è la proposta; si costruiscono con la modalità.

## 4. La conclusione della campagna, nel minimo

Realizzata nella tappa 1 soltanto quanto basta a far arrivare un esito al regno e a renderlo provabile, e dichiarata come tale (RDA-164).

**Che cosa c'è.** Una campagna aperta dal regno si conclude in due modi: (a) per annientamento, quando al ritorno da una battaglia una delle due parti non ha più gruppi armati sul fronte: vince l'altra; (b) per l'arrivo dell'inverno, chiusa l'ultima giornata d'autunno: senza vincitore, le forze rientrano. Conclusa la campagna, ogni comando è respinto con il medesimo motivo; l'esito — modo, vincitore, giornate, battaglie vinte e perse, superstiti — passa al regno.

**Che cosa manca rispetto ai documenti.** La presa del quartier generale, che è la conclusione ordinaria (01 §5.14.3.2); la resa della campagna (01 §5.14.3.3 la nomina, nessun punto la definisce: domanda 4); le conseguenze territoriali della conclusione (01 §5.14.2, A §9.3: possesso del territorio, opere ordinabili, fortezza che passa di mano, 01 §5.14.3.4); la sorte delle opere da campo, che non esistono ancora (01 §5.14.1.2); un vincitore per la campagna che l'inverno interrompe, se il titolare lo vorrà (domanda 3). Le tre campagne di prova dell'avvio restano senza conclusione, com'erano: la regola vale soltanto per la campagna che dichiara un calendario.

## 5. Le decisioni tecniche della prima tappa

Registrate nel registro delle decisioni architetturali (`Fondamenta/registro-decisioni-architetturali.md`): RDA-162 (il regno come terzo strato, con giornale proprio e slot annidati); RDA-163 (nessun gruppo armato avversario aggiunto agli scenari: decisione del titolare); RDA-164 (la conclusione minima della campagna); RDA-165 (il bilancio: rendita, premi, riporto calcolato sull'entrata dell'anno per analogia con RDA-14); RDA-166 (le forze: formazioni che tornano come sono, reclute come gruppo nuovo al quartier generale; la cucitura delle due modalità); RDA-167 (la patria: schermata, formato degli annunci di costo, vocabolario delle risorse e della moneta); RDA-168 (la scala dei termini di probabilità confermata per il meteo: decisione del titolare); RDA-169 (il banco del regno, la sonda dei suoi invarianti, la misura della frequenza ripetuta); RDA-170 (le versioni alla build 31); RDA-171 (VoiceOver spento sul simulatore del collaudo); RDA-172 (la voce che restava indietro chiudendo le giornate in fila: la coda degli annunci). Dove la costruzione si scosta dai documenti o li legge in un modo fra più possibili: `registro-scostamenti.md`, S28. I valori provvisori stanno in `valori-provvisori.md`.
