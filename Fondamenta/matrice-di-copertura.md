# Matrice di copertura

Documento di lavoro della fase di architettura — versione 1.0

## 0. Che cosa contiene e come si usa

Ogni requisito numerato dei quattro documenti consolidati — 00 carta dei principi (versione 1.2), 01 progetto del gioco (versione 3.3), 02 accessibilità (versione 2.2), 03 dati (versione 2.1) — in relazione con il punto del documento di architettura (05, versione 1.0, citato come "A") che vi provvede.

Dove un requisito non richiede alcuna provvidenza architetturale, la cosa è dichiarata espressamente con la ragione, mai lasciata come omissione: una riga assente sarebbe indistinguibile da una dimenticanza, una riga che dichiara l'assenza di necessità no. I rinvii "RDA-nn" puntano al registro delle decisioni architetturali.

La matrice si legge per documento; l'ordine delle righe segue la numerazione dei punti. Se una futura versione di un consolidato aggiunge o modifica punti numerati, la matrice va aggiornata nella stessa occasione.

### Documento 00 — Carta dei principi (versione 1.2)

| Requisito | Sintesi | Provvidenza |
|---|---|---|
| 00 §1.1 | Accessibilità VoiceOver prevale su ogni altra considerazione | A §9.1, A §14.4, A §15.1 |
| 00 §1.2 | Parità piena: stessa informazione, stesse operazioni, stessa certezza | A §3.2, A §9.4, A §10.11 |
| 00 §1.3 | Funzione non accessibile non entra nel gioco | A §14.4, A §15.3 |
| 00 §1.4 | Esempio: fascia di schieramento interrogabile, non solo colorata | A §9.4, A §10.6 |
| 00 §1.5 | Esempio: niente tabelle a caselle che moltiplicano le operazioni | A §10.12 |
| 00 §2.1 | Swift puro, strumenti nativi, nessun motore esterno | A §1.1 |
| 00 §2.2 | Ragione: superficie grafica unica è muta per VoiceOver | Nessuna provvidenza architetturale necessaria — motivazione del punto 2.1 (realizzato da A §1.1) |
| 00 §2.3 | Ogni elemento interattivo con nome, ruolo, valore, azioni | A §10.1, A §14.4 |
| 00 §2.4 | Celle di griglia e mappa sono elementi accessibili | A §10.1 |
| 00 §3.1 | Stato completo più comandi discreti, esito deterministico | A §2.1, A §3.1 |
| 00 §3.2 | Logica senza schermo, interfaccia senza regole | A §1.2, A §1.5, A §9.5 |
| 00 §3.3 | Confine logica-interfaccia rigoroso, mai attraversato | A §1.3, A §9.5, A §14.5 |
| 00 §3.4 | Dal confine dipendono salvataggio, rete, verifica, annullamento, rigiocatura | A §1.3, A §6.1, A §6.4, A §12.1, A §13.1, A §13.2 |
| 00 §3.5 | Salvataggio automatico a ogni azione, requisito di base | A §1.4, A §6.1 |
| 00 §4.1 | Gioco a turni, nessun limite di tempo | A §1.6 |
| 00 §4.2 | Nessuna prontezza richiesta, nessuna scadenza reale | A §1.6 |
| 00 §4.3 | Durate riformulate come quantità (esempio imboscata) | A §2.7, A §3.9 |
| 00 §4.4 | Riformulazione applicata a ogni meccanica futura | Nessuna provvidenza architetturale necessaria — regola di metodo per la progettazione futura |
| 00 §5.1 | Motore aptico assente su iPad, non aggirabile | A §11.3 |
| 00 §5.2 | Ogni segnale aptico ha controparte sonora o testuale | A §11.3, A §14.4 |
| 00 §5.3 | Un punto centrale unico decide i canali | A §1.2, A §11.1 |
| 00 §5.4 | Vocabolario aptico fondato su ritmo e durata | A §11.4 |
| 00 §5.5 | Pattern aptici in file di dati separato | A §7.5, A §11.3 |
| 00 §5.6 | Risparmio energetico e motore aptico mantenuto pronto | A §11.4 |
| 00 §6.1 | Contenuti verbali restano testo letto da VoiceOver | A §10.7, A §11.6 |
| 00 §6.2 | Nessuna narrazione registrata sostituisce gli annunci | A §11.5 |
| 00 §6.3 | Audio prodotto per suoni brevi e ambienti | A §11.5 |
| 00 §6.4 | Informazione affidata a suono recuperabile come testo | A §10.13, A §11.5 |
| 00 §7.1 | Linguaggio di interazione identico sui due piani | A §10.1, A §10.5, A §10.9 (dettaglio 02 §2) |
| 00 §7.2 | Unica differenza: quattro oppure sei celle vicine | A §10.5 |
| 00 §7.3 | Nessun reimparare passando da un piano all'altro | Nessuna provvidenza architetturale necessaria — motivazione del punto 7.1 |
| 00 §7.4 | Navigazione: righe a scorrimento, direzioni nelle azioni, pannello cella | A §10.2, A §10.4, A §10.5 |
| 00 §7.5 | Azioni personalizzate mai oltre cinque voci | A §10.5 |
| 00 §8.1 | Nessun trascinamento come manipolazione, mai | A §3.4, A §10.4 |
| 00 §8.2 | Schema universale: seleziona, naviga, conferma | A §3.4, A §10.4 |
| 00 §8.3 | Esplorazione al tatto distinta e pienamente sfruttata | A §10.11 |
| 00 §9.1 | Ogni informazione visiva dichiarata a voce | A §3.2, A §9.4 |
| 00 §9.2 | Validità, costi, budget, affidabilità, posizione fuoco sempre dichiarati | A §2.6.1, A §3.1, A §3.2, A §10.9 |
| 00 §9.3 | Esempio: annuncio di cella con costo e residuo | Nessuna provvidenza architetturale necessaria — esempio illustrativo di 9.2 (realizzato da A §3.2) |
| 00 §9.4 | Vocabolario chiuso, fisso, identico in tutto il gioco | A §3.2, A §8.4 |
| 00 §9.5 | Tre livelli di verbosità con priorità fissa | A §8.5, A §10.8 |
| 00 §10.1 | Tutto raggiungibile anche a scorrimenti | A §10.11 |
| 00 §10.2 | Rotore dedicato per ogni insieme consultato ripetutamente | A §9.4, A §10.6 |
| 00 §10.3 | Rotori come principale strumento di parità | Nessuna provvidenza architetturale necessaria — motivazione del punto 10.2 |
| 00 §10.4 | Griglia ingrandibile e scorrevole, bersagli minimi, fuoco trascina vista | A §10.10, A §10.11 |
| 00 §11.1 | Il fuoco resta dove l'utente lo lascia | A §10.1, A §10.3 |
| 00 §11.2 | Imposizione esplicita contro il comportamento predefinito del sistema | A §10.1, A §10.3 |
| 00 §11.3 | Esempi vincolanti: piazzamento, esaurimento deck, valore aggiornato | A §10.3, A §14.4 |
| 00 §11.4 | Cambiamenti annunciati senza rubare il fuoco | A §10.3, A §10.7 |
| 00 §11.5 | Ordine di lettura dichiarato elemento per elemento | A §10.2 |
| 00 §11.6 | Cambio di riga segnalato con aptica, suono, numero | A §11.2, A §11.3 |
| 00 §12.1 | Nessun riferimento storico diretto nel gioco | Nessuna provvidenza architetturale necessaria — regola di contenuto esaurita dal consolidato 01 |
| 00 §12.2 | Unità come archetipi funzionali con tratti modificatori | A §7.5 (archetipi.json, assetti.json) |
| 00 §12.3 | Fedeltà storica nei parametri, non nei nomi | Nessuna provvidenza architetturale necessaria — criterio di contenuto, materia dei consolidati 03 e 04 |
| 00 §12.4 | Portate e autonomie in celle e turni | A §7.3, 03 §9 |
| 00 §12.5 | Nessuna scala reale dichiarata per i formati | Nessuna provvidenza architetturale necessaria — regola di contenuto esaurita dai consolidati 01 e 03 |
| 00 §12.6 | Corretti i rapporti, calibrazione reiterata nel documento 03 | A §12.4, 03 §6 |
| 00 §13.1 | Valori in file esterni, nessun pannello interno | A §7.1, A §7.9 |
| 00 §13.2 | Valori come rapporti e coefficienti su base di fase | A §7.3 |
| 00 §13.2.1 | Intervalli documentali conservati come forbici di differenziazione | A §7.3 |
| 00 §13.2.2 | Valore variabile = intervallo più regola di variazione | A §7.3 |
| 00 §13.2.3 | Variazioni solo per causa dichiarata; partenze fissate una volta | A §7.3, A §7.5 (regni.json, 03 §3.1) |
| 00 §13.2.4 | Le simulazioni provano gli estremi degli intervalli | A §12.3 |
| 00 §13.3 | Formula unica più coefficiente, mai tabelle a doppia entrata | A §7.4 |
| 00 §13.4 | Decimali nei file, interi al giocatore | A §2.2 |
| 00 §13.5 | Arrotondamento unico: troncamento per difetto ovunque | A §2.2, A §14.2 |
| 00 §13.6 | Minimo di uno dove il troncamento darebbe zero | A §2.2, A §7.8, A §14.2 |
| 00 §13.7 | Grandezze di base grandi per rendere irrilevanti i decimali | Nessuna provvidenza architetturale necessaria — scelta di taratura dei valori, esaurita dal consolidato 03 |
| 00 §13.8 | Ogni budget richiede annullamento e azzeramento | A §6.4, A §6.5 |
| 00 §14.1 | Testi fuori dal codice dal primo giorno | A §8.1, A §14.5 |
| 00 §14.2 | Annunci come frasi intere con segnaposto | A §8.2 |
| 00 §14.3 | Plurali gestiti dal meccanismo di localizzazione | A §8.2 |
| 00 §14.4 | Ogni testo dichiara la propria lingua | A §8.3 |
| 00 §14.5 | Vocabolario chiuso localizzato come termini fissi | A §8.4 |
| 00 §15.1 | Ogni salvataggio registra la versione dei dati | A §2.3, A §6.6 |
| 00 §15.2 | Salvataggio incompatibile dichiarato e non aperto | A §6.6 |
| 00 §15.3 | Nessuna perdita di partita inspiegata per i tester | A §6.8 |
| 00 §15.4 | File di dati copiati in posizione visibile da File | A §7.1, A §7.9 |
| 00 §16.1 | Programma di verifica separato, senza interfaccia, con percentuali | A §12.1, A §12.6, A §14.7 |
| 00 §16.2 | Le simulazioni misurano i margini non percepibili | A §12.4 |
| 00 §16.3 | Tester non vedenti coinvolti dal primo prototipo | A §15.3, A §15.9 |
| 00 §16.4 | Prima un singolo scontro completo, poi la campagna | A §15.1 |

### Documento 01 — Progetto del gioco (versione 3.2)

| Requisito | Sintesi | Provvidenza |
|---|---|---|
| 01 §1.1 | Gioco a turni, singolo giocatore, predisposto al multiplayer locale | A §1.4, A §5.1, A §13.1 |
| 01 §1.2 | Due piani: campagna a caselle, battaglia esagonale | A §2.6, A §2.7 |
| 01 §1.3 | Gestione del regno esclusivamente militare | A §2.4 (perimetro dello stato del regno) |
| 01 §1.3.1 | Economia astratta, limite dal bilancio non dalla popolazione | Nessuna provvidenza architetturale necessaria — costo dichiarato e accettato |
| 01 §1.4 | Nessun limite di tempo reale, vincoli solo quantitativi | A §1.6 |
| 01 §1.5 | Progressione per fasi; prima versione arcaica e antica | A §2.4, A §7.5 (fasi.json) |
| 01 §2.1 | Otto fasi previste, solo due nella prima versione | Nessuna provvidenza architetturale necessaria — orizzonte di progettazione, non requisito realizzativo |
| 01 §2.2 | Nomi propri del gioco, mai popoli o periodi storici | A §8.1 (testi fuori dal codice) |
| 01 §2.3 | Fase arcaica: orizzonte tarda età del bronzo | A §7.5 (fasi.json) più 03 §9 |
| 01 §2.4 | Fase antica: orizzonte da ferro maturo | A §7.5 (fasi.json) più 03 §9 |
| 01 §2.5 | La transizione cambia la forma, non le prestazioni | Nessuna provvidenza architetturale necessaria — principio attuato dai punti 2.5.1–2.6 |
| 01 §2.5.1 | Parametri invarianti fra fasi; protezione cala e si diffonde | A §7.3 (basi di fase e intervalli) più 03 §9 |
| 01 §2.5.2 | Cambiano separazioni e sostituzioni, non i numeri | A §7.7, A §2.4 (effetti tipizzati delle acquisizioni) |
| 01 §2.5.3 | Rischio: progressione senza numeri difficile da percepire | Nessuna provvidenza architetturale necessaria — rischio dichiarato, risolto da 2.6 e 2.6.4 |
| 01 §2.5.4 | Macchine da tiro: unica differenza per presenza | A §7.7 (gancio sblocca archetipo), A §2.4 |
| 01 §2.6 | Acquisizioni una alla volta, finanziate dalle vittorie | A §2.4, A §3.5 (comando acquisisci), A §7.5 (acquisizioni.json) |
| 01 §2.6.1 | Ragione documentale della soglia non unica | Nessuna provvidenza architetturale necessaria — motivazione documentale |
| 01 §2.6.2 | Soglia distribuita: minimo di acquisizioni in ambiti diversi | A §2.4 (tetti d'epoca per ambito) più 03 §9 |
| 01 §2.6.2.1 | Tetto d'epoca per ambito, chiusura comunicata positivamente | A §2.4, A §3.2 (validazione) |
| 01 §2.6.2.2 | Vietato quadro esplicito della soglia e catalogo futuro | Nessuna provvidenza architetturale necessaria — impostazione respinta, nessuna schermata da realizzare |
| 01 §2.6.3 | Dichiarazione unica del passaggio; i tetti si innalzano | A §3.6 (conferma del riquadro), A §2.4 |
| 01 §2.6.3.1 | Riquadro narrativo con conferma, cambio tema, non richiamabile | A §3.6, A §9.3, A §11.5 |
| 01 §2.6.3.2 | Primo sblocco senza numeri che salgono | Nessuna provvidenza architetturale necessaria — constatazione motivazionale |
| 01 §2.6.4 | Il passaggio muta mondo, avversari e campagne | A §2.5, A §5.3 |
| 01 §2.6.5 | Ritardare il passaggio è strategia legittima | A §3.5 (spese sempre possibili), A §2.4 |
| 01 §2.6.6 | Si cresce insieme; divario di forma, non di livello | A §5.3, A §5.4 |
| 01 §2.7 | Ordine delle acquisizioni documentato, ogni capacità costa | A §7.5 (acquisizioni.json: ordinamenti e costi) |
| 01 §2.7.1 | Insieme degli archetipi variabile con il progredire | A §7.7 (sblocca archetipo), A §2.4 |
| 01 §2.8 | L'avversario progredisce a sua volta | A §5.3 (governo avversario) |
| 01 §2.8.1 | Truppe della fase precedente restano com'erano | A §2.4 (totali per archetipo persistenti) |
| 01 §2.8.1.1 | Materiale nuovo prima raro, poi comune | Nessuna provvidenza architetturale necessaria — conseguenza percettiva della regola 2.8.1 |
| 01 §2.8.1.2 | La non conversione impedisce il rinvio dominante | Nessuna provvidenza architetturale necessaria — motivazione di equilibrio |
| 01 §2.8.2 | Cinque ambiti di avanzamento; numeri nel documento 03 | A §2.4, A §7.5 (acquisizioni.json) più 03 §9 |
| 01 §2.8.2.1 | Elenco acquisizioni per ambito e ordine di sblocco | A §7.5 (acquisizioni.json) |
| 01 §2.8.2.2 | Nomi funzionali; costi e prerequisiti nei dati | A §7.5, A §8.1 |
| 01 §3.1 | Archetipi per funzione con tratti modificatori | A §7.5 (archetipi.json) |
| 01 §3.2 | Otto archetipi provvisori, sblocco e obsolescenza progressivi | A §7.5, A §7.7 |
| 01 §3.2.3 | Nove archetipi definitivi; macchina da tiro distinta | A §7.5 (archetipi.json), A §7.7 |
| 01 §3.2.1 | Cavalleria mobile, non d'urto; inseguimento confinato al campo | A §7.4 (formula danno), A §7.5 (coefficienti) |
| 01 §3.2.2 | I varchi li produce il disingaggio | Nessuna provvidenza architetturale necessaria — rinvio illustrativo al punto 3.4.2 |
| 01 §3.3 | Tratti distinguono varianti senza moltiplicare archetipi | A §7.5 (archetipi.json) |
| 01 §3.3.1 | Proiettile unico e fisso per reparto (v3.3); due tipi nel mondo | A §7.4 (accoppiamento), A §7.5 |
| 01 §3.3.2 | Due protezioni opposte; scelta in patria premiata sul campo | A §7.4 (danno per accoppiamento offesa-protezione) |
| 01 §3.3.3 | Protezione pesante rara in arcaica, diffusa in antica | A §7.5 più 03 §9 |
| 01 §3.4 | Parametri minimi obbligatori di ogni archetipo | A §7.5 (archetipi.json), A §7.8 (completezza validata) |
| 01 §3.4.1 | Gittata unica e resa unica (v3.3); portata binaria | A §7.5, A §12.4 (metrica 03 §6.4 ridefinita) |
| 01 §3.4.2 | Tendenza al disingaggio propria di ogni archetipo | A §7.5, A §2.7 |
| 01 §3.4.3 | Munizioni limitate, tiro deciso a ogni turno | A §2.7, A §7.5 |
| 01 §3.4.4 | Volume parametro unico per costo e velocità | A §7.5, A §2.6.2 (volume derivato) |
| 01 §3.4.5 | Costo e volume incorporano il seguito | A §7.5 più 03 §9 |
| 01 §3.5 | Misure in celle e turni, scala interna | A §7.3 (forma delle voci) |
| 01 §3.6 | Ogni reparto occupa sempre una sola cella | A §2.7 (griglia con al più uno sciame) |
| 01 §4.1 | Sciame: raggruppamento di atomi, puro o misto | A §2.7, A §7.5 (assetti.json) |
| 01 §4.1.1 | Assetto misto deciso e addestrato in patria | A §2.4 (assetti sbloccati), A §7.5 |
| 01 §4.1.2 | Ragione documentale delle formazioni miste | Nessuna provvidenza architetturale necessaria — motivazione documentale |
| 01 §4.2 | Serbatoio di punti vita; efficacia dagli atomi presenti | A §2.7, A §7.4 |
| 01 §4.3 | Troncamento per difetto con minimo di un atomo | A §2.2, A §14.2 |
| 01 §4.3.1 | Modello a consumo progressivo mantenuto per ascoltabilità | Nessuna provvidenza architetturale necessaria — costo dichiarato e accettato |
| 01 §4.3.2 | Nessuna rottura improvvisa, fuga o inseguimento di campagna | Nessuna provvidenza architetturale necessaria — esclusione di meccaniche, nulla da realizzare |
| 01 §4.4 | Una cella, un solo sciame occupante | A §2.7 |
| 01 §4.5 | Armi combinate per adiacenza o assetto misto | A §2.7, A §7.5 (assetti.json) |
| 01 §4.5.1 | Sciame misto annunciato con nome proprio | A §8.2 più 02 (annunci) |
| 01 §4.6 | Sistema unico degli sciami per tutti i formati | A §2.7, A §7.5 (formato-battaglia.json) |
| 01 §4.7 | Assetti ammessi: taglia e composizione decise in patria | A §7.5 (assetti.json), A §2.4 |
| 01 §4.8 | Riorganizzazione: ripartizione dei totali negli assetti | A §3.3 (riordino degli assetti), A §2.4 |
| 01 §4.8.1 | Assetto misto attinge a più totali insieme | A §2.4 (resti), A §3.3 più 02 (schermata di redistribuzione) |
| 01 §4.9 | Stato conserva totali per archetipo e sciami separatamente | A §2.4, A §2.6.2 |
| 01 §4.10 | Resti contabilizzati, non schierabili, rientro automatico | A §2.4 (resti) |
| 01 §4.11 | Nessuna identità fra battaglie; raggruppamento automatico minimo | A §2.4 |
| 01 §4.12 | Reintegro solo con reclutamento in patria | A §3.5 (recluta) |
| 01 §4.13 | Miglioramenti: addestramenti mirati d'inverno | A §3.5 (addestra o migliora), A §2.4 |
| 01 §4.14 | Miglioramenti deperibili; mantenimento economico | A §2.4 (stato di mantenimento), A §3.5 (mantieni miglioramento) |
| 01 §4.14.1 | Mantenimento unico freno all'accumulo: taratura consapevole | A §12.4 (metrica 03 §6.3) |
| 01 §5.1 | Mappa quadrata, tre formati, adiacenza ortogonale | A §7.6, A §2.6 |
| 01 §5.1.1 | Assedi senza formato dedicato: piazzaforte su casella | A §7.6 (città e piazzeforti) |
| 01 §5.1.2 | Caselle boscose, acqua diffusa, mappa interamente percorribile | A §7.6 (terreno, boschi, acqua) |
| 01 §5.1.3 | Al più una strettoia, annunciata, costo fisso | A §7.6, A §7.8 (validazione) |
| 01 §5.2 | Tre categorie di formazioni sulla mappa | A §2.6.2 (categoria del gruppo) |
| 01 §5.2.1 | Quartier generale perno della campagna | A §7.6 (posizioni dei quartier generali), A §2.6 |
| 01 §5.2.2 | Rifornimento per catene proprie; tratto patria-QG automatico | A §2.6.2 (condizione di rifornimento derivata) |
| 01 §5.2.2.1 | La linea è condizione dello spazio, non convogli | A §2.6.2 (derivata, mai memorizzata) |
| 01 §5.2.2.2 | Regola del taglio: sei caselle retrostanti | A §2.6.2, A §14.2 (casi di bordo) |
| 01 §5.2.2.3 | La scorreria in profondità non taglia | Nessuna provvidenza architetturale necessaria — conseguenza voluta della regola 5.2.2.2 |
| 01 §5.2.2.4 | Taglio: malus, massimo due turni, soste dovute | A §2.6.2 (contatori e sosta dovuta), A §3.8 |
| 01 §5.2.2.5 | Malus cumulabili, conteggi e rimedi distinti | A §2.6.2, A §7.8 (vincolo inter-valore) |
| 01 §5.2.2.6 | Fortezza e magazzino: zona di rifornimento di nove caselle | A §2.6.2 (derivazione dalle strutture) |
| 01 §5.2.2.7 | Fortezza isolata rifornisce finché posseduta | A §2.6.2 |
| 01 §5.2.3 | Catena bersaglio prezioso, senza lavoro giornaliero di scorta | Nessuna provvidenza architetturale necessaria — considerazione strategica, nessuna regola nuova |
| 01 §5.3 | Stati di conoscenza a vocabolario chiuso per casella | A §2.6.1, A §8.4 |
| 01 §5.4 | Ricognizione costosa soprattutto in rischio | A §3.3 (esplorazione), A §2.6.1 |
| 01 §5.4.1 | Gli esploratori non innescano mai battaglie | A §3.3 (risoluzione sulla mappa di campagna) |
| 01 §5.4.2 | Esploratori con competenza differenziata, personale formato | A §2.6.2 (competenza degli esploratori) |
| 01 §5.4.3 | Ragione del costo in rischio | Nessuna provvidenza architetturale necessaria — motivazione |
| 01 §5.5 | Perimetro della gestione del regno | Nessuna provvidenza architetturale necessaria — punto di riepilogo dei punti seguenti |
| 01 §5.5.1 | Cinque risorse distinte e non sovrapposte | A §2.4 (cinque risorse con saldi) |
| 01 §5.5.1.1 | Cibo escluso dal bilancio, affidato agli automatismi | Nessuna provvidenza architetturale necessaria — esclusione motivata, nessuna meccanica |
| 01 §5.5.1.2 | Animali contesi fra impieghi concorrenti | Nessuna provvidenza architetturale necessaria — tensione voluta, esito dei costi (03) |
| 01 §5.5.1.3 | Moneta cambia materiale per fase, non valore | A §2.4 (materiale monetario), A §7.5 (fasi.json) |
| 01 §5.5.1.4 | Riporto massimo dieci per cento, spendibile in voci brevi | A §2.4 più 03 §9 (quota) |
| 01 §5.5.1.4.1 | Tre sole voci acquistabili fuori dall'inverno | A §3.5 (spesa breve fuori inverno) |
| 01 §5.5.1.5 | Il surplus va trasformato o svanisce | Nessuna provvidenza architetturale necessaria — conseguenza della regola 5.5.1.4 |
| 01 §5.5.2 | Installazioni = opere permanenti; capacità come funzioni del regno | A §2.4, A §2.5, A §7.5 (opere.json) |
| 01 §5.5.3 | Rete stradale con logica; strade fuori mappa | A §7.6, A §7.8 (validazione città-strada) |
| 01 §5.6 | Turno = giornata; un'azione per gruppo | A §3.8, A §2.6.2 |
| 01 §5.6.0 | Gruppo: oggetto con composizione, volume, velocità | A §2.6.2 |
| 01 §5.6.0.1 | Formazione libera dei gruppi, nessun tetto | A §3.3 (divisione e riunione) |
| 01 §5.6.0.2 | Divisione costa l'azione; distaccamento collocato adiacente | A §3.3 (divisione con collocamento) |
| 01 §5.6.0.3 | Riunione gratuita; eredita l'azione già spesa | A §3.3 (riunione gratuita) |
| 01 §5.6.0.4 | Nomi propri stabili assegnati dal gioco | A §2.6.2, A §7.5 (nomi-gruppi.json) |
| 01 §5.6.0.5 | Ogni azione consuma l'intera giornata | A §3.3, A §2.6.2 (azione spesa) |
| 01 §5.6.0.6 | Chiusura automatica; stare fermi è un'azione | A §3.8 |
| 01 §5.6.1 | La marcia è una delle azioni, non l'unica | A §3.3 (ordina marcia) |
| 01 §5.6.2 | Ritmo illustrativo che discende dalle regole | Nessuna provvidenza architetturale necessaria — esempio illustrativo senza valore normativo |
| 01 §5.6.3 | Velocità della colonna funzione del volume complessivo | A §2.6.2, A §7.4 (giorni di marcia) |
| 01 §5.6.3.1 | Spostamento per casella singola, in uno o più giorni | A §7.4, A §2.6.2 (marcia lunga) |
| 01 §5.6.3.2 | Costo in giorni da partenza, arrivo, strada, volume | A §7.4, A §7.5 (terreni-e-strade.json) più 03 |
| 01 §5.6.3.3 | Marcia lunga senza stato intermedio; revoca con perdita | A §2.6.2, A §3.3 (revoca marcia gratuita) |
| 01 §5.6.3.4 | Nove posizioni visive derivate dai giorni | A §9.2, A §2.6.2 (giorni compiuti e totali) |
| 01 §5.6.3.5 | Immobilità dichiarata prima della conferma; nessuna imboscata implicita | A §3.2 (anteprima delle conseguenze), A §2.6.2 |
| 01 §5.6.4 | Marcia forzata: tetto e logoramento più che proporzionale | A §3.3, A §2.6.2 (contatori) più 03 |
| 01 §5.6.4.1 | Effetti: scatto compresso o seconda casella | A §3.3 (secondo scatto) |
| 01 §5.6.4.2 | Secondo scatto esplicito, mai decaduto in silenzio | A §3.3 (impiega/rinuncia), A §2.6.2, A §14.2 |
| 01 §5.6.4.3 | Il secondo scatto consuma una sola unità del tetto | A §2.6.2 (contatori di marcia forzata) |
| 01 §5.6.4.4 | Riposo rimuove i malus della marcia forzata | A §3.3 (riposo) |
| 01 §5.6.4.5 | Marcia forzata espone alle imboscate; vantaggio fisso | A §12.4 (metrica 03 §6.6) |
| 01 §5.6.5 | Autonomia in giorni; sosta con raccolta automatica | A §2.6.2 (provviste residue), A §3.3 (sosta con raccolta) |
| 01 §5.6.5.1 | Catena via ordinaria, sosta conseguenza dell'interruzione | Nessuna provvidenza architetturale necessaria — chiarimento del rapporto fra regole |
| 01 §5.6.6 | Questione della via ordinaria risolta | Nessuna provvidenza architetturale necessaria — nota di risoluzione |
| 01 §5.6.7 | Animali seguono automaticamente la logica delle razioni | Nessuna provvidenza architetturale necessaria — semplificazione dichiarata, nessuna meccanica separata |
| 01 §5.6.8 | Perimetro della giornata risolto altrove | Nessuna provvidenza architetturale necessaria — punto di riepilogo |
| 01 §5.6.8.1 | Elenco chiuso delle sedici azioni di giornata | A §3.3 (elenco dei comandi corrispondente) |
| 01 §5.6.9 | Campagne multiple per fronte; massimo due regni nemici | A §2.3 (fino a quattro campagne), A §2.5 (fronti, cinque mappe) |
| 01 §5.6.9.1 | Calendari propri; scarto massimo due settimane, blocco | A §2.6 (data propria, blocco per scarto massimo) |
| 01 §5.6.9.2 | Chiusura del turno e conteggio gruppi per campagna | A §3.8, A §2.6 |
| 01 §5.6.9.3 | Campagna bloccata dichiara ragione; avviso preventivo | A §2.6, A §10.7 (annunci) |
| 01 §5.6.10 | Navigazione a tre livelli: patria, campagne, mappa | A §9.3, A §10.9 (gesto di fuga) |
| 01 §5.6.10.1 | Schermata campagne sede dell'informazione di stato complessiva | A §9.3 (schermata delle campagne) |
| 01 §5.6.10.2 | Riferimenti temporali: date e scarti per schermata | A §9.4, A §2.6 (data propria) |
| 01 §5.6.10.3 | Patria mai obbligata, novità segnalate | A §9.3, A §9.4 |
| 01 §5.6.11 | Ordine di risoluzione della giornata chiuso | A §3.8 |
| 01 §5.7 | Stanchezza a due fonti; sensibilità per archetipo | A §2.6.2, A §7.5 più 03 §9 |
| 01 §5.7.1 | Manutenzione a tre stati; guasto probabilistico; riparazioni | A §2.6.2, A §4.2 (prova di guasto), A §3.3 |
| 01 §5.7.2 | Nessuna stanchezza ordinaria: questione estinta | Nessuna provvidenza architetturale necessaria — nota di chiusura, nessuna regola nuova |
| 01 §5.8 | Approvvigionamento agisce sui parametri, mai sul budget | A §2.6.2, A §2.7 (applicazione all'apertura della battaglia) |
| 01 §5.9 | Inverno obbligatorio, campagne ferme, gestione in patria | A §2.3 (Inverno nello stato), A §3.5 |
| 01 §5.9.1 | Inverno parte della partita e sede della gestione | A §3.5, A §9.3 (stazioni invernali) |
| 01 §5.9.1.1 | Quattro schermate separate da apporti informativi progressivi | A §2.3, A §3.5 (prosegui alla stazione successiva), A §9.3 |
| 01 §5.9.1.2 | Risorse spendibili per tutto l'inverno | A §2.3 (decisioni già prese), A §3.5 |
| 01 §5.9.1.3 | Schermate identiche, linguette ordinate per durata | A §9.3 (linguette per durata) |
| 01 §5.9.1.4 | Ordinamento per durata; dichiarato quando sarà pronto | A §3.5 (dichiarazione del momento di completamento), A §2.4 |
| 01 §5.9.1.5 | Costo su riserva; annuncio solo dell'impossibilità; riquadro riserve | A §3.2, A §10.12 |
| 01 §5.9.1.6 | Informazioni solo su strutture, mai su addestramento | A §3.5 (apporto informativo prodotto dal Motore) |
| 01 §5.9.1.7 | Fondo minimo di voci; precisione crescente, mai certezza | A §3.5, A §12.4 (metrica 03 §6.7) |
| 01 §5.9.1.8 | Simmetria di risorse e tetti con gli avversari | A §2.5, A §5.3 |
| 01 §5.9.2 | Stagioni intermedie: solo probabilità meteo diverse | A §7.5 (meteo.json per stagione) |
| 01 §5.9.3 | Il meteo resta nel perimetro del caso | A §4.2 |
| 01 §5.9.4 | Geografia e meteo influenzano la battaglia solo via caratteristica | A §2.7 (caratteristica unica del campo) |
| 01 §5.10 | Contro formazioni non armate: sabotaggio o studio | A §3.3 (sabotaggio, studio approfondito) |
| 01 §5.10.2 | Sabotaggio e studio: risoluzioni deterministiche chiuse | A §3.3, A §4.2 (caso confinato) |
| 01 §5.10.1 | Esploratori osservano movimenti e deducono itinerari | A §2.6.1 (sorgenti di conoscenza) |
| 01 §5.11 | Imboscata: azione di posizione che scatta all'ingresso | A §3.3, A §2.6.2 (ordine di imboscata), A §3.8 |
| 01 §5.11.1 | Nessuna menzogna: casella semplicemente non confermata | A §2.6.1 (mai dichiarato il falso) |
| 01 §5.11.2 | Vantaggio: turni extra e sconto, nessuna penalità subita | A §2.7 (turni di vantaggio), A §3.9 |
| 01 §5.11.3 | L'imboscata ha un costo proprio in tempo e rifornimenti | Nessuna provvidenza architetturale necessaria — costo emergente dalle regole esistenti |
| 01 §5.12 | Costruzione di alcune macchine in caselle boscose | A §3.3 (costruzione di macchina in casella boscosa) |
| 01 §5.13 | Aggiramento consentito: sfilarsi senza ingaggiarsi | Nessuna provvidenza architetturale necessaria — assenza voluta di ingaggio obbligato |
| 01 §5.14 | Due specie di opere sulla mappa di campagna | A §7.5 (opere.json), A §2.6 |
| 01 §5.14.1 | Opere da campo: azione di un gruppo, vantaggi difensivi | A §3.3 (costruzione di opera da campo), A §2.6 |
| 01 §5.14.1.1 | Le opere da campo non passano al nemico | A §2.6 (stato delle caselle) |
| 01 §5.14.1.2 | Le opere da campo decadono con la campagna | A §2.6 (vita legata alla campagna) |
| 01 §5.14.2 | Opere permanenti ordinate d'inverno su territorio controllato | A §3.5 (ordina lavoro), A §2.5 |
| 01 §5.14.3 | Fortezza: secondo QG, conoscenza, dispiegamento, macchine | A §2.6.1 (copertura), A §3.5 (assegna truppe a fortezza) |
| 01 §5.14.3.1 | Guarnigione minima automatica; presidio serio richiede truppe | A §3.5 più 03 (malus) |
| 01 §5.14.3.2 | Due quartieri generali: conquistarne uno non basta | A §2.6 (stato di possesso e opere) |
| 01 §5.14.3.3 | Asimmetria voluta e non compensata | Nessuna provvidenza architetturale necessaria — scelta di equilibrio dichiarata |
| 01 §5.14.3.4 | Fortezza espugnata neutralizzata fino a fine campagna | A §2.6 (opere permanenti e loro stato) |
| 01 §5.14.3.5 | Valore della fortezza dipende dal presidio: taratura | A §12.4 (metrica 03 §6.8) |
| 01 §5.14.3.6 | Assedio della fortezza segue integralmente la sezione 8 bis | A §4.4 (sortita), A §2.6.2 (zona di rifornimento) |
| 01 §5.14.4 | Vie impresse: la strada agisce sui giorni di marcia | A §2.5 (vie impresse), A §7.4 |
| 01 §5.14.4.1 | Modificazioni permanenti nello stato; la casella dichiara la strada | A §2.5, A §7.6 (vivono nello stato, non nel file) |
| 01 §5.14.5 | Portata della conoscenza per righe e formati | A §2.6.1 (limiti di riga e di formato) |
| 01 §5.14.5.1 | Frequenza dei formati di mappa | A §7.6 (mappe come contenuto) |
| 01 §5.14.5.2 | Sbilanciamento dei formati minori: taratura | A §12.4 (metrica 03 §6.9) |
| 01 §5.14.6 | Torri: informazione invernale cumulativa e conoscenza in campagna | A §2.6.1, A §3.5 (apporto informativo) |
| 01 §5.14.7 | Distruzione delle opere permanenti: una giornata dedicata | A §3.3 (distruzione di opera permanente nemica) |
| 01 §5.14.8 | Ponte, guado, magazzino, palizzata: condizioni di terreno | A §7.5 (opere.json), A §7.6 |
| 01 §5.15 | Magazzino con disciplina comune; ricognizione esente dal taglio | A §3.5, A §2.6.2 (categoria) più 03 (costi) |
| 01 §5.16 | Orientamento: informazione di stato, salto diretto, dichiarazione | A §10.9, A §10.6 (rotore gruppi da muovere), A §9.4 |
| 01 §5.16.1 | Stati del gruppo a vocabolario chiuso | A §2.6.2, A §8.4 |
| 01 §5.16.2 | Gruppo con scatto residuo: annuncio motivato | A §10.6, A §10.7 |
| 01 §5.17 | Registro cronologico per campagna e per patria | A §2.6 (registri), A §10.13 |
| 01 §5.17.1 | Nel registro solo i fatti non decisi dal giocatore | A §3.7 (annotazione dei soli fatti non decisi) |
| 01 §6.1 | La compresenza non obbliga a combattere | A §3.3 (imposizione come comando esplicito) |
| 01 §6.1.1 | Basta la volontà di uno per imporre lo scontro | A §3.3 (imposizione, accettazione) |
| 01 §6.1.2 | Rifiutare richiede vedere arrivare; chi è lento accetta | Nessuna provvidenza architetturale necessaria — conseguenza voluta delle regole esistenti |
| 01 §6.1.3 | Frequenza degli scontri dal carattere degli ufficiali: taratura | A §12.4 (metrica 03 §6.5) |
| 01 §6.2 | La battaglia si apre quando il giocatore decide | A §3.6 (apertura come comando), A §3.3 |
| 01 §6.3 | Battaglia in sospeso preclude le attività della campagna | A §2.6 (battaglie in sospeso), A §3.2 |
| 01 §6.3.1 | Blocco all'accettazione; lo stallo consuma rifornimenti | A §2.6, A §3.8 |
| 01 §6.4 | Durante il blocco nulla avanza per nessuno | A §2.6 (stato di blocco) |
| 01 §6.5 | Scopo: affrontare la battaglia con il tempo necessario | Nessuna provvidenza architetturale necessaria — motivazione, attuata da A §6 |
| 01 §6.6 | Ripresa esatta a battaglia iniziata, interazione compresa | A §6.3, A §2.7 (stato dell'interazione nello stato) |
| 01 §6.7 | La resa è l'uscita da una battaglia persa | Nessuna provvidenza architetturale necessaria — chiarimento di ruolo di regola esistente |
| 01 §6.8 | Battaglie contemporanee: il giocatore sceglie l'ordine | A §2.6 (battaglie in sospeso con forze), A §3.3 |
| 01 §6.9 | Dirottamento dei superstiti: unica attività eccezionale | A §3.3 (dirottamento dei superstiti) |
| 01 §6.10 | I dirottati arrivano come rinforzi in turni successivi | A §7.4 (formula arrivo rinforzi), A §2.7 |
| 01 §7.1 | Griglia esagonale con punta in alto, righe orizzontali | A §10.1, A §10.2 (ordine ovest-est) |
| 01 §7.2 | Formati da quindici a cento celle | A §7.5 (formato-battaglia.json) |
| 01 §7.3 | Numerazione delle righe dalle retrovie avversarie | A §2.7 (griglia) |
| 01 §7.3.1 | Basi fisse e contrapposte, geografia stabile | A §2.7 (due basi in posizione fissa) |
| 01 §7.3.2 | Fortificazione mobile: capacità sbloccabile, non arcaica | A §7.5 (acquisizioni.json) |
| 01 §7.4 | Caratteristica unica del campo, dichiarata all'apertura | A §2.7, A §7.5 (caratteristiche-campo.json) |
| 01 §7.4.1 | Ragione: carico informativo del terreno per cella | Nessuna provvidenza architetturale necessaria — motivazione |
| 01 §7.4.2 | Le caselle di campagna cessano di essere intercambiabili | Nessuna provvidenza architetturale necessaria — conseguenza voluta |
| 01 §7.5 | Ostacoli minori: limiti, non interattivi, annunciati | A §2.7 (ostacoli), A §10.1 (celle non interattive annunciate) |
| 01 §7.5.1 | Le mura sfuggono al limite; contrappeso nelle macchine | A §2.7, A §7.6 (piazzeforti) |
| 01 §7.6 | Presenza di ostacoli dichiarata all'apertura | A §3.7 (eventi), A §10.7 |
| 01 §7.7 | Informazione completa su ciò che è in campo | A §2.7 (griglia interamente visibile) |
| 01 §7.7.1 | Sorpresa via deck trattenuto, non celle nascoste | A §2.7 (deck), A §3.7 (arrivo rinforzi nel deck) |
| 01 §7.7.2 | Rinuncia all'inganno sul campo per ascoltabilità | Nessuna provvidenza architetturale necessaria — costo dichiarato e accettato |
| 01 §8.1 | Nessuna fase di schieramento separata: unico flusso | A §3.9 |
| 01 §8.1.1 | Deck attingibile sempre, costo dalla stessa grandezza | A §3.4 (piazza), A §7.4 |
| 01 §8.1.2 | Il piazzamento consuma l'azione del turno | A §3.9 |
| 01 §8.1.3 | Turni dell'imboscante: turni di battaglia ordinari | A §3.9 |
| 01 §8.2 | Vincolo duplice: volume rigenerato e profondità massima | A §2.7 (budget), A §7.4 |
| 01 §8.2.1 | Zona di piazzamento: due o tre righe arretrate | A §7.5 (formato-battaglia.json), A §3.2 (validazione) |
| 01 §8.2.2 | Costo crescente con la profondità | A §7.4 |
| 01 §8.3 | Interfaccia a deck: selezione, navigazione, conferma | A §3.4, A §10.2 |
| 01 §8.4 | Conferme ripetute; esaurimento con deselezione senza fuoco | A §3.4, A §10.3 |
| 01 §8.5 | Budget unico per piazzamento e movimento | A §2.7, A §7.4 |
| 01 §8.6 | Formula unica: profondità proporzionale più coefficiente d'archetipo | A §7.4 |
| 01 §8.7 | Stessa formula per il ritiro verso le retrovie | A §7.4 |
| 01 §8.8 | Costi interi, troncamento per difetto, minimo uno | A §2.2 |
| 01 §8.9 | Dichiarazione cella per cella; tre soli motivi negativi | A §3.2 (motivi del tipo chiuso), A §10.4 |
| 01 §8.10 | Annullamento e azzeramento obbligatori | A §6.4 |
| 01 §8.11 | Schieramento proposto applicabile e modificabile | A §3.6 (scelta dello schieramento proposto) |
| 01 §8b.1 | Piazzaforte: elemento su casella della mappa ordinaria | A §7.6 (città e piazzeforti) |
| 01 §8b.2 | L'assedio si combatte; mura come ostacolo | A §2.7 (ostacoli) |
| 01 §8b.3 | Macchine pronte dalla patria o costruite in campagna | A §3.3 (costruzione di macchina) |
| 01 §8b.4 | Seconda via: scontro campale davanti alla piazzaforte | A §2.6 (stato di possesso) |
| 01 §8b.5 | Blocco: malus e sortita dopo alcuni turni | A §4.4 |
| 01 §8b.5.1 | Sortita deterministica a soglia; annuncio di imminenza | A §4.4 più 03 (soglia nei dati) |
| 01 §8b.6 | Il blocco costringe a uscire, non prende | Nessuna provvidenza architetturale necessaria — chiarimento di scopo |
| 01 §8b.7 | Rinuncia all'assedio logistico storico | Nessuna provvidenza architetturale necessaria — costo dichiarato e accettato |
| 01 §9.1 | Combattimento a turni e deterministico | A §4.1, A §4.2 |
| 01 §9.2 | Ossatura stabilita; calcolo del danno rinviato | A §7.4 più 03 (taratura) |
| 01 §9.2.1 | Vincoli: determinismo, formula unica, valori nei dati | A §4.1, A §7.4 |
| 01 §9.3 | Budget rigenerato; primo turno maggiorato | A §2.7, A §3.9, A §7.5 (capacità di volume) |
| 01 §9.3.1 | Maggiorazione per entrambi, senza eccezioni | A §3.9 |
| 01 §9.3.2 | Sorpresa: turni consecutivi extra più sconto | A §3.9, A §2.7 (turni di vantaggio residui) |
| 01 §9.3.2.1 | Sequenza dell'imboscata; opacità di un solo turno | A §2.7 (stato di opacità), A §14.2 |
| 01 §9.3.2.2 | Motivazione della delimitazione dell'opacità | Nessuna provvidenza architetturale necessaria — motivazione |
| 01 §9.3.3 | Riporto del volume entro il dieci per cento | A §2.7 (riporto), A §7.5 (riporti) |
| 01 §9.3.4 | Riporto calcolato sul budget di base, non composto | A §2.7 |
| 01 §9.3.5 | Deck utilizzabile per tutta la battaglia: riserve vere | A §2.7 (deck), A §3.4 |
| 01 §9.3.6 | Costo sempre ordinario; due sole eccezioni dichiarate | A §7.4, A §3.2 |
| 01 §9.4 | Informazione completa per tutta la durata | A §2.7 |
| 01 §9.4.1 | Agisce per primo chi occupava la casella | A §3.9 |
| 01 §9.4.3 | Lettera stabile per reparto, mai riusata, anche a schermo (v3.3) | A §10.1, A §10.7; stato nel Motore |
| 01 §9.3.7 | Volume avversario mai comunicato (v3.3) | A §10.7 |
| 01 §9.7.2 | Esiti in fasce descrittive con soglie nei dati (v3.3) | A §3.7 (eventi), A §10.7; soglie in 03 §5.14 |
| 01 §9.4.2 | Cella a occupante unico confermata; basi non occupabili | A §2.7 |
| 01 §9.5 | Reparti a contatto fuori controllo fino al disimpegno | A §2.7 (contatti in corso), A §3.9 |
| 01 §9.5.0 | Nessun attacco automatico; un'azione per reparto | A §3.4, A §10.4 (azioni dichiarate) |
| 01 §9.5.0.1 | Ingaggio gratuito: il volume paga solo movimento | A §3.4 (ordina ingaggio) |
| 01 §9.5.0.2 | Volume e azione: due limiti su grandezze diverse | Nessuna provvidenza architetturale necessaria — chiarimento dei vincoli già previsti |
| 01 §9.5.0.3 | Spostamento di una o due celle al massimo | A §3.4 (muovi di una o due celle) |
| 01 §9.5.1 | Nessun ufficiale del giocatore, ordini mai mediati | Nessuna provvidenza architetturale necessaria — assenza di meccanica |
| 01 §9.5.2 | Ragione documentale della perdita di controllo | Nessuna provvidenza architetturale necessaria — motivazione documentale |
| 01 §9.5.3 | Riserva significativa; a contatto non si estrae | Nessuna provvidenza architetturale necessaria — conseguenza voluta |
| 01 §9.6 | Tiro deciso a ogni turno, mai automatico | A §3.4 (ordina tiro) |
| 01 §9.6.1 | Munizioni non reintegrate; il reparto resta in campo | A §2.7, A §3.7 (evento munizioni esaurite) |
| 01 §9.6.2 | Nessun fuoco amico: il tiro colpisce solo avversari | A §3.2 (validazione del bersaglio), A §14.2 (prova dedicata) |
| 01 §9.7 | Mischia continua con perdite reciproche per turno | A §3.9 (risoluzione simultanea delle mischie) |
| 01 §9.7.1 | Annuncio complessivo a inizio turno; dettaglio per cella | A §3.9 (evento aggregato), A §10.7 |
| 01 §9.8 | Disingaggio a soglia proporzionale alla consistenza d'ingresso | A §2.7 (consistenza d'ingresso), A §3.9 |
| 01 §9.8.1 | Soglia per tipo di truppa, dichiarata al giocatore | A §7.5 più 03 §9, A §9.4 |
| 01 §9.8.2 | Ritrazione di una cella; controllo dal turno successivo | A §3.9 (applica i disingaggi) |
| 01 §9.8.3 | Secondo contatto fra stessi reparti senza soglia | A §2.7 (memoria dei disingaggi), A §14.2 |
| 01 §9.8.4 | Disingaggio come finestra; reazioni a catena | Nessuna provvidenza architetturale necessaria — conseguenza voluta |
| 01 §9.9 | Danno da accoppiamento munizione-protezione, formula unica | A §7.4 |
| 01 §9.9.1 | Annuncio qualitativo; modello sottostante graduato | A §3.2, A §8.4 |
| 01 §9.9.2 | Stesso meccanismo di accoppiamento in mischia | A §7.4 |
| 01 §10.1 | La resa apre la ritirata combattuta | A §3.4 (dichiara resa), A §2.7 |
| 01 §10.2 | Resa dopo soglia minima, accorciata dalle perdite | A §3.2 più A §12.4 (metrica 03 §6.1) |
| 01 §10.2.1 | Base delle perdite: sole forze impiegate sul campo | A §2.7 (contatore nello stato), A §3.2, A §14.2 |
| 01 §10.3 | Prosegue fino alla riga di soglia | A §2.7 (riga di soglia) |
| 01 §10.4 | Volume per ritirare gli arretrati e sbarrare | A §3.4 (ritira unità), A §7.4 |
| 01 §10.4.1 | I reparti a contatto non si ritirano | A §3.2 (motivo di non ammissibilità) |
| 01 §10.5 | Riga interamente occupata = barriera per costruzione | Nessuna provvidenza architetturale necessaria — proprietà geometrica della griglia esagonale |
| 01 §10.6 | Evacuati ricompaiono in casella arretrata | A §3.6 (collocamento delle forze superstiti) |
| 01 §10.7 | Ritirata avversaria limitata: vantaggio nascosto | A §5.5 (vantaggi-nascosti.json) |
| 01 §10.8 | Ogni ritirata avversaria è annunciata | A §3.7 (eventi), A §10.7 |
| 01 §10.9 | Margine di convenienza della resa: misurare con simulazioni | A §12.4 (metrica 03 §6.2) |
| 01 §10.10 | Soglia minima di turni: taratura critica | A §12.4 (metrica 03 §6.1) |
| 01 §10.11 | La ritirata costa la battaglia, non l'esercito | Nessuna provvidenza architetturale necessaria — costo dichiarato e accettato |
| 01 §11.1 | Superstiti dirottati arrivano come rinforzi successivi | A §7.4, A §2.7 (indicazione di rinforzo) |
| 01 §11.2 | Turno di arrivo da formula unica, senza tabelle | A §7.4 (formula arrivo dei rinforzi) |
| 01 §11.3 | Percorrenza contata dall'inizio della seconda battaglia | A §7.4 |
| 01 §11.4 | Stima annunciata come intervallo con margine dichiarato | A §3.2 (anteprima) |
| 01 §11.5 | Rinforzi nel deck; annuncio, suono, fuoco fermo | A §3.7, A §11.3, A §14.4 |
| 01 §11.6 | Rinforzo annunciato; primo dispiegamento a costo dimezzato | A §2.7, A §7.4 |
| 01 §11.7 | Dimezzamento: troncamento con minimo di uno | A §2.2 |
| 01 §11.8 | Rinforzi nella zona ordinaria, nessun ingresso speciale | A §2.7 (deck), A §3.2 (vincoli di profondità) |
| 01 §11.9 | Rinforzi possibili anche durante la ritirata combattuta | Nessuna provvidenza architetturale necessaria — combinazione di regole esistenti |
| 01 §12.1 | Combattimento e avversario deterministici | A §4.1, A §4.3 |
| 01 §12.2 | Caso solo su meteo e guasti delle macchine | A §4.2 |
| 01 §12.3 | Il probabilistico annunciato come tale, termini fissi | A §8.4, A §4.4 |
| 01 §12.4 | Le imboscate non sono casuali | A §4.3, A §5.2 (propensione all'imboscata) |
| 01 §12.5 | Costi accettati del perimetro del caso | Nessuna provvidenza architetturale necessaria — costo dichiarato e accettato |
| 01 §13.1 | Vantaggi nascosti raccolti e noti alla Verifica | A §5.5, A §12.5 |
| 01 §13.2 | Vantaggi attuali: limiti alla ritirata avversaria | A §5.5 (vantaggi-nascosti.json) |
| 01 §13.3 | Ogni nuovo vantaggio va aggiunto all'elenco | A §5.5 (procedura di aggiunta) |
| 01 §14.1 | Difficoltà nelle impostazioni, agisce su risorse | A §5.4, A §9.3 (impostazioni) |
| 01 §14.2 | Ufficiali diversi per comportamento a parità di livello | A §5.2 |
| 01 §14.3 | Stessa intelligenza, cinque parametri di carattere | A §5.2, A §7.5 (ufficiali.json) |
| 01 §14.6 | Avversari progrediscono entro le forbici; stessi tetti | A §5.3, A §7.3 (intervalli e variazioni) |
| 01 §14.6.1 | Regno lontano specializzato sull'ambito debole del giocatore | A §5.6, A §2.5 |
| 01 §14.6.2 | Fissazione legata alla distanza dal passaggio di fase | A §5.6 |
| 01 §14.6.3 | Specializzazione immutabile una volta fissata | A §5.6, A §2.5 (fissata e immutabile) |
| 01 §14.6.4 | Nessuna eccezione alla simmetria dei tetti | Nessuna provvidenza architetturale necessaria — chiarimento, nessuna eccezione da realizzare |
| 01 §14.6.5 | Ricognizione di lungo periodo sulla specializzazione | A §2.6.1 (scala degli stati di conoscenza) |
| 01 §14.7 | L'inverno vale anche per gli avversari | A §5.3 (governo e spese invernali) |
| 01 §14.4 | Difficoltà e carattere: due assi non mescolati | A §5.4 |
| 01 §14.5 | Parità informativa: ufficiale presentato, carattere percepibile | A §5.2 (presentazione con nome e reputazione), A §10.7 |
| 01 §15.1 | In battaglia nessun consumo di risorse di campagna | Nessuna provvidenza architetturale necessaria — separazione dei piani, nessuna meccanica da realizzare |
| 01 §15.2 | Solo superstiti e perdite; nessun prigioniero | Nessuna provvidenza architetturale necessaria — esclusione di meccanica |
| 01 §15.2.1 | Rinuncia alla cattura in massa documentata | Nessuna provvidenza architetturale necessaria — costo dichiarato e accettato |
| 01 §15.2.2 | Sconfitto chi si ritira per primo; nessuna parità | A §2.7, A §3.7 (esito) |
| 01 §15.2.3 | Due sole conclusioni: ritirata esaurita o annientamento | A §2.7, A §3.7 |
| 01 §15.2.4 | Sconfitta dichiarata, non calcolata | Nessuna provvidenza architetturale necessaria — motivazione e costo dichiarato |
| 01 §15.3 | Resoconto di chiusura con le informazioni utili | A §3.7 (destinazione resoconto), A §9.3 |
| 01 §15.3.1 | Contenuto e ordine fisso del resoconto, voci accessibili | A §9.3 (resoconto di fine battaglia), A §8.5 |
| 01 §15.4 | Collocazione dei superstiti; il vincitore sceglie primo | A §3.6 (collocamento delle forze superstiti) |
| 01 §15.5 | Solo il vincitore può restare nella casella | A §3.6, A §3.2 (validazione) |
| 01 §15.6 | Gli evacuati si collocano in casella arretrata | A §3.6 |
| 01 §15.7 | Totali aggiornati; raggruppamento automatico nell'assetto minimo | A §2.4 |
| 01 §15.8 | Senza altre battaglie, la campagna riprende | Nessuna provvidenza architetturale necessaria — ripresa del corso ordinario, nessuna regola nuova |
| 01 §16.1 | Calcolo del danno rinviato per scelta | Nessuna provvidenza architetturale necessaria — rinvio dichiarato alla taratura (03) |
| 01 §16.2 | Elenco dei punti chiusi nella fase di architettura | Nessuna provvidenza architetturale necessaria — punto di solo riepilogo |
| 01 §16.3 | Grandezze da stabilire in sede di valori | A §7.3, A §12.4 più 03 |
| 01 §16.4 | Grandezze da tarare con le simulazioni | A §12.3, A §12.4 |
| 01 §16.5 | Elenco degli impianti mantenuti per scelta | Nessuna provvidenza architetturale necessaria — riepilogo di costi dichiarati |
| 01 §16.6 | Nessuna differenza fra battaglia in marcia e schierata | Nessuna provvidenza architetturale necessaria — costo dichiarato e accettato |

### Documento 02 — Accessibilità (versione 2.1)

| Requisito | Sintesi | Provvidenza |
|---|---|---|
| 02 §1.1 | Parità di informazione e di costo delle azioni | Nessuna provvidenza architetturale necessaria — principio trasversale attuato dall'intera sezione A §10 |
| 02 §1.2 | Parità come uguale costo di accesso, non mera raggiungibilità | Nessuna provvidenza architetturale necessaria — motivazione del principio di parità |
| 02 §1.3 | Ogni elemento comprensibile anche atterrandovi direttamente | A §10.1 |
| 02 §2.1 | Modello di navigazione unico sui due piani | A §10.1, A §10.5 |
| 02 §2.2 | Griglia esagonale a punta in alto, righe orizzontali | A §10.1 |
| 02 §2.3 | Mappa di campagna a caselle quadrate, quattro vicini | A §10.1 |
| 02 §2.4 | Scorrimento orizzontale percorre la riga e prosegue | A §10.2 |
| 02 §2.5 | Direzioni restanti come azioni personalizzate | A §10.5 |
| 02 §2.6 | Mai più di cinque azioni personalizzate | A §10.5 |
| 02 §2.7 | Azioni personalizzate solo navigazione; pannello per agire | A §10.5, A §10.4 |
| 02 §2.8 | Ordine di lettura esplicito: celle, deck, comandi globali | A §10.2, A §14.4 |
| 02 §2.9 | Fuoco iniziale sull'intestazione del deck | A §10.2 |
| 02 §2.10 | Zona di schieramento adiacente al deck, coincidenza preservata | A §10.2 |
| 02 §2.11 | Tutto raggiungibile sia al tatto sia a scorrimenti | A §10.11 |
| 02 §2.12 | Esplorazione libera a tocco diretto, solo proposta futura | Nessuna provvidenza architetturale necessaria — esclusa dalla prima versione (02 §17.3) |
| 02 §3.1 | Testa fissa obbligatoria dell'annuncio di cella | A §8.5 |
| 02 §3.2 | Senza selezione: riga, cella, contenuto | A §8.5, A §10.7 |
| 02 §3.3 | Con selezione: disponibilità e motivo prima della posizione | A §3.2, A §8.5 |
| 02 §3.4 | Numero di riga sempre annunciato, ripetizione voluta | A §8.5 |
| 02 §3.5 | Tre soli motivi di non disponibilità, termini chiusi | A §3.2, A §8.4 più 01 §8.9 |
| 02 §3.5.2 | Annunci di piazzamento identici in ogni turno | A §3.2 più 01 §8.1 |
| 02 §3.5.1 | Mura annunciate col termine chiuso degli ostacoli | A §8.4 |
| 02 §3.6 | Annuncio di costo e residuo prima della conferma | A §3.2 |
| 02 §3.7 | Celle di ostacolo annunciate e non interattive | A §10.1 |
| 02 §3.7.1 | Sciame misto annunciato col nome, mai coi componenti | A §8.5 |
| 02 §3.7.2 | Portata binaria: a portata, fuori portata (v2.2) | A §8.4, A §10.4 |
| 02 §3.7.3 | Munizioni dichiarate fra le informazioni di stato | A §8.5, A §8.4 |
| 02 §3.8 | Ordine del contenuto scelto una volta, globale | A §8.5 |
| 02 §3.8.1 | Ordine registrato delle informazioni dopo la testa fissa | A §8.5, A §10.7 |
| 02 §3.9 | Tre livelli di verbosità, tagli solo dalla coda | A §8.5, A §10.8 |
| 02 §3.10 | Cella vuota in sintetico: poche parole | A §8.5 |
| 02 §4.1 | Vocabolario chiuso, termini fissi senza varianti | A §8.4, A §14.3 |
| 02 §4.2 | Stati di conoscenza: inesplorato, presunto, avvistato, confermato | A §8.4, A §2.6.1 |
| 02 §4.3 | Motivi di non disponibilità: troppo avanzata, occupata, ostacolo | A §3.2, A §8.4 |
| 02 §4.4 | Tre stati di manutenzione; tre termini di imminenza sortita | A §8.4, A §4.4 |
| 02 §4.4.1 | Vocabolario esteso ai nuovi insiemi delle regole | A §8.4 |
| 02 §4.4.1.1 | Stati di un gruppo sulla mappa, termini brevi | A §8.4, A §2.6.2 |
| 02 §4.4.1.2 | Stati di rifornimento; condizione ordinaria non menzionata | A §8.4, A §2.6.2 |
| 02 §4.4.1.3 | Efficacia qualitativa: efficace oppure poco efficace | A §8.4 |
| 02 §4.4.1.4 | Moneta variabile per fase, posizione e funzione fisse | A §8.2 |
| 02 §4.4.2 | Caratteristica del campo dichiarata all'apertura, poi richiamabile | A §2.7, A §10.9 |
| 02 §4.4.3 | Il vocabolario non dichiara mai il falso | A §2.6.1 |
| 02 §4.4.4 | Opacità da imboscata annunciata come eccezione unica | A §2.7 |
| 02 §4.4.5 | Termini chiusi di tutti gli insiemi, vincolanti | A §8.4, A §14.3 |
| 02 §4.5 | Termini localizzati come termini fissi, anche in inglese | A §8.4 |
| 02 §5.1 | Il fuoco non si sposta mai senza richiesta | A §10.3, A §10.1 |
| 02 §5.2 | Dopo il piazzamento il fuoco resta sulla cella | A §10.3, A §14.4 |
| 02 §5.3 | Esaurimento del deck: deselezione annunciata, fuoco fermo | A §10.3 |
| 02 §5.4 | Rinforzi annunciati con suono dedicato, senza spostare fuoco | A §10.3, A §3.7 |
| 02 §5.5 | Ogni cambiamento rilevante annunciato senza rubare fuoco | A §10.3, A §10.7 |
| 02 §5.6 | La battaglia si apre solo per scelta del giocatore | A §3.6, A §3.3 |
| 02 §6.1 | Stato di una riga verificato scorrendone le celle | A §10.2 |
| 02 §6.2 | Riga piena come barriera, coincidenza da preservare | Nessuna provvidenza architetturale necessaria — motivazione geometrica fondata sulle regole di gioco |
| 02 §6.3 | Cambio di riga segnalato con impulso tattile e sonoro | A §11.2, A §11.3 |
| 02 §6.4 | Informazione di stato della battaglia con gesto fisso | A §10.9, A §9.4 |
| 02 §6.5 | Stato della campagna dichiarato; comandi bloccati motivati | A §10.9, A §9.4 |
| 02 §6.5.1 | Dichiarare quanti gruppi hanno agito nel turno | A §9.4, A §10.9 |
| 02 §6.5.1.3 | Formato chiuso dello stato, ordine fisso, tagli dalla coda | A §10.9, A §8.5 |
| 02 §6.5.1.1 | Tre strati di orientamento che non si duplicano | A §10.9, A §10.6 |
| 02 §6.5.1.2 | Marce lunghe e scatti residui dichiarati a parte | A §10.9, A §2.6.2 |
| 02 §6.5.4 | Tre livelli: patria, campagne, mappa di campagna | A §9.3, A §10.9 |
| 02 §6.5.4.1 | Schermata delle campagne per fronti e località | A §9.3, A §9.4 |
| 02 §6.5.4.2 | Campagna bloccata si dichiara appena vi si entra | A §2.6, A §3.7 |
| 02 §6.5.4.3 | Riferimenti temporali in alto su tutti i livelli | A §2.6, A §9.4 |
| 02 §6.5.4.4 | Gesti di risalita e passaggio chiusi al 6.7 | Nessuna provvidenza architetturale necessaria — rinvio interno al punto 6.7 |
| 02 §6.6 | Registro: voci accessibili singole, dal più recente | A §10.13, A §3.7 |
| 02 §6.6.1 | Registro come recupero testuale degli annunci persi | A §11.5 |
| 02 §6.6.2 | Nel registro solo i fatti non decisi dal giocatore | A §3.7 |
| 02 §6.5.2 | Stato dichiara stagione e sospensione invernale | A §10.9, A §2.3 |
| 02 §6.5.3 | Gruppo in imboscata annuncia il proprio stato | A §8.4, A §2.6.2 |
| 02 §6.7 | Tre gesti fissi identici in tutto il gioco | A §10.9 |
| 02 §7.1 | Rotori come principale strumento di parità | A §10.6 |
| 02 §7.2 | Elenco confermato dei rotori del campo di battaglia | A §10.6, A §9.4 |
| 02 §7.3 | Elenco confermato dei rotori della mappa di campagna | A §10.6, A §9.4 |
| 02 §7.3.1 | Rotore dei gruppi inattivi come contropartita necessaria | Nessuna provvidenza architetturale necessaria — motivazione del rotore del punto 7.3 |
| 02 §7.4 | Rotori trasversali; ordine interno deterministico e fisso | A §10.6 |
| 02 §8.1 | Deck sotto la griglia, selezione e conferma, nessun trascinamento | A §3.4, A §10.2 |
| 02 §8.2 | Elemento del deck: assetto, atomi, volume, rinforzo | A §8.5 |
| 02 §8.2.1 | Ingresso di riserve avversarie annunciato senza rubare fuoco | A §3.7, A §10.3 |
| 02 §8.3 | Conferme successive senza riselezionare l'elemento | A §3.4, A §10.3 |
| 02 §8.4 | Annullamento e azzeramento obbligatori, subito dopo il deck | A §6.4, A §10.2 |
| 02 §8.5 | Comandi distanziati dal bordo inferiore, altezza piena | A §10.2 |
| 02 §8.6 | Schieramento proposto come comodità, non parità | A §3.6 |
| 02 §8.7 | Ogni voce dichiara costo su riserva posseduta | A §10.12, A §3.2 |
| 02 §8.7.1 | Solo l'impossibilità si annuncia, con la risorsa mancante | A §10.12, A §3.2 |
| 02 §8.7.2 | Riquadro delle riserve navigabile voce per voce | A §10.12 |
| 02 §8.7.3 | Quattro schermate invernali identiche, linguette per durata | A §9.3, A §3.5 |
| 02 §8.8 | Disponibilità di ingaggio dichiarata con i bersagli raggiungibili | A §10.4, A §3.2 |
| 02 §8.9 | Mischia annunciata in una sola comunicazione aggregata | A §3.9, A §10.7 |
| 02 §9.1 | Operazioni a due celle: unità, bersaglio, pannello | A §10.4 |
| 02 §9.2 | Sequenza chiusa al punto 9.2.1 | Nessuna provvidenza architetturale necessaria — rinvio interno al punto 9.2.1 |
| 02 §9.2.1 | Due vie equivalenti: elenco bersagli oppure designazione | A §10.4, A §3.4 |
| 02 §9.3 | Tiro esplicito; bersagli a portata con nome, lettera, efficacia (v2.2) | A §10.4, A §3.2 |
| 02 §9.5 | Azione impossibile in ogni sua forma non offerta (v2.2) | A §10.4 |
| 02 §6.4.1 | Il volume avversario non compare in alcuna forma (v2.2) | A §10.7 |
| 02 §8.9.1 | Esiti dei combattimenti in fasce chiuse, mai numeri (v2.2) | A §10.7, A §11.1 |
| 02 §9.4 | Reparto impegnato: termine chiuso, nessun comando inefficace | A §10.4, A §8.4 |
| 02 §10.1 | Griglia mai compressa sotto le dimensioni minime | A §10.10, A §10.11 |
| 02 §10.2 | Griglia ingrandibile e scorrevole, fuoco che trascina vista | A §10.10 |
| 02 §10.3 | Nessuna tabella: ogni riga un elemento in frase | A §10.12 |
| 02 §11.1 | Nessuna informazione solo tattile: sempre controparte | A §11.3 |
| 02 §11.2 | Un solo punto centrale decide i canali | A §11.1 |
| 02 §11.3 | Tavolozza: nitidezza, intensità, ritmi fino a cinque impulsi | A §11.4, A §7.5 |
| 02 §11.4 | Ritmo identifica il genere; intensità e nitidezza graduano | A §11.4 |
| 02 §11.5 | Tetto di dodici-quindici significati nella prima versione | A §11.3 |
| 02 §11.6 | Ritmo affidabile ovunque; intensità e nitidezza subordinate | Nessuna provvidenza architetturale necessaria — motivazione della regola 11.4 |
| 02 §11.7 | Assegnazione chiusa al punto 11.7.1 | Nessuna provvidenza architetturale necessaria — rinvio interno al punto 11.7.1 |
| 02 §11.7.1 | Cinque famiglie, quindici significati, eventi esclusi con suono | A §11.3, A §7.5 |
| 02 §11.8 | Pattern in file di dati, modificabili senza ricompilare | A §7.5 |
| 02 §11.9 | Motore aptico mantenuto pronto; risparmio energetico gestito | A §11.4 |
| 02 §12.1 | Vocabolario sonoro parallelo, stesse famiglie del tattile | A §11.5, A §7.5 |
| 02 §12.2 | Suoni brevi senza parole; ambiente per fase storica | A §11.5 |
| 02 §12.3 | Nessuna narrazione registrata; legge VoiceOver | A §11.5 |
| 02 §12.4 | Ogni suono recuperabile anche in forma testuale | A §11.5, A §10.13 |
| 02 §13.1 | Schermata per riascoltare ogni segnale col significato | A §9.3 |
| 02 §13.2 | Unico modo di apprendere il linguaggio dei segnali | Nessuna provvidenza architetturale necessaria — motivazione del punto 13.1 |
| 02 §14.1 | Impostazione del livello di verbosità | A §10.8 |
| 02 §14.2 | Canali tattile e sonoro attivabili indipendentemente | A §11.3 |
| 02 §14.3 | Impostazioni della prima versione; preferenze locali all'apparecchio | A §10.8, A §9.3 |
| 02 §15.1 | Nessuna stringa nel codice, dal primo giorno | A §8.1, A §14.5 |
| 02 §15.2 | Annunci come frasi intere con segnaposto | A §8.2 |
| 02 §15.3 | Plurali dal meccanismo di localizzazione del sistema | A §8.2 |
| 02 §15.4 | Ogni testo dichiara la propria lingua | A §8.3 |
| 02 §16.1 | Tester non vedenti reali dal primo prototipo | A §15.9, A §15.3 |
| 02 §16.2 | La prova in prima persona è insufficiente | Nessuna provvidenza architetturale necessaria — motivazione del punto 16.1 |
| 02 §16.3 | Primo prototipo: un singolo scontro completo | A §15.1, A §15.3 |
| 02 §17.1 | Riepilogo delle chiusure dei punti da definire | Nessuna provvidenza architetturale necessaria — punto di riepilogo (chiusure registrate in A §16.1) |
| 02 §17.2 | Riepilogo delle conferme dei punti da confermare | Nessuna provvidenza architetturale necessaria — punto di riepilogo (A §16.1) |
| 02 §17.2.1 | Verifica del tetto tattile: quindici significati assegnati | Nessuna provvidenza architetturale necessaria — esito di verifica già recepito al punto 11.7.1 |
| 02 §17.3 | Esplorazione libera esclusa dalla prima versione | Nessuna provvidenza architetturale necessaria — esclusione dichiarata dalla prima versione |

### Documento 03 — Dati (versione 2.0)

| Requisito | Sintesi | Provvidenza |
|---|---|---|
| 03 §1.1 | Valori in file separati, modificabili senza ricompilare | A §7.1, A §7.9 |
| 03 §1.2 | Valori come rapporti e coefficienti su base di fase | A §7.3 |
| 03 §1.3 | Intervalli conservati con regola di variazione | A §7.3 |
| 03 §1.4 | Valore si muove solo per causa dichiarata | A §7.3, A §7.7 |
| 03 §1.5 | Formula unica più coefficienti, vietate tabelle doppie | A §7.4 |
| 03 §1.6 | Decimali nei file, interi troncati con minimo mostrati | A §2.2 |
| 03 §1.7 | Grandezze di base grandi, decimali quasi irrilevanti | Nessuna provvidenza architetturale necessaria — criterio di taratura; l'aritmetica intera è già provvista da A §2.2 |
| 03 §1.8 | Simulazioni provano gli estremi degli intervalli | A §12.3 |
| 03 §2.1 | Nessuna scala reale, scala interna sui rapporti storici | A §7.3; nessuna provvidenza ulteriore necessaria — criterio di calibrazione |
| 03 §2.2 | Contano i rapporti fra grandezze, calibrazione reiterata | A §7.3, A §12.3 |
| 03 §2.3 | Portate e autonomie in celle e turni | A §7.3; nessuna provvidenza ulteriore necessaria — regola di espressione delle unità |
| 03 §3.1 | Differenze fra regni fissate una volta sola | A §7.5 (regni.json), A §5 |
| 03 §3.2 | Da determinare quali grandezze differiscano fra regni | Nessuna provvidenza architetturale necessaria — grandezza da tarare; contenitore provvisto da A §7.5 (regni.json), misura da A §12 |
| 03 §4.1.1 | Costo in giorni dello scatto fra caselle | A §7.5 (terreni-e-strade.json), A §7.4 |
| 03 §4.1.2 | Pesi di casella di partenza e di arrivo | A §7.5 (terreni-e-strade.json), A §7.4 |
| 03 §4.1.3 | Costo fisso di transito della strettoia | A §7.5 (terreni-e-strade.json), A §7.6 |
| 03 §4.1.4 | Effetto del miglioramento delle vie su percorrenze | A §7.3, A §7.7 |
| 03 §4.2.1 | Tetto di due o tre turni di marcia forzata | Nessuna provvidenza architetturale necessaria — decisione di progetto; contenitore da A §7.5, contatori nello stato da A §2.6.2 |
| 03 §4.2.2 | Curva di logoramento più che proporzionale | A §7.4, A §7.5 |
| 03 §4.2.3 | Entità dei malus e quota rimossa dal riposo | A §7.5, A §2.6.2 |
| 03 §4.3.1 | Malus da mancanza provviste più marcati della marcia | A §7.5, A §7.8 |
| 03 §4.3.2 | Differenze di autonomia per volume di formazione | A §7.5, A §2.6.2 |
| 03 §4.4.1 | Riporto risorse fissato al dieci per cento | Nessuna provvidenza architetturale necessaria — decisione di progetto già fissata; contenitore da A §7.5 |
| 03 §4.4.2 | Progressione dei materiali monetari per fase | A §7.5 (fasi.json) |
| 03 §4.4.3 | Costo dell'addestramento, decisione di progetto | Nessuna provvidenza architetturale necessaria — grandezza da tarare; contenitore da A §7.5, misura da A §12 |
| 03 §4.4.4 | Durate dei lavori invernali e linguette | A §7.5 (opere.json) |
| 03 §4.4.5 | Costi in risorse delle opere permanenti | A §7.5 (opere.json) |
| 03 §4.5.1 | Guarnigione minima della fortezza e malus | A §7.5 (opere.json) |
| 03 §4.5.2 | Vantaggi in combattimento delle opere da campo | A §7.5 (opere.json), A §7.7 |
| 03 §4.5.3 | Peso delle torri sull'apporto informativo invernale | A §7.5 (opere.json), A §12.4 |
| 03 §4.6.1 | Distanza di avviso prima del blocco fra campagne | A §7.5, A §2.6 |
| 03 §4.7.1 | Condizione che fissa la specializzazione del regno lontano | A §7.5, A §5.6 |
| 03 §4.7.2 | Tetti d'epoca per ambito e fase | A §7.5 |
| 03 §4.7.3 | Minimi di acquisizioni e ambiti della soglia distribuita | Nessuna provvidenza architetturale necessaria — grandezza da tarare; contenitore da A §7.5, misura da A §12.2 (partita lunga) |
| 03 §4.7.4 | Costi, durate e prerequisiti delle acquisizioni | A §7.5 (acquisizioni.json), A §7.7 |
| 03 §4.8.1 | Turni di decadimento da confermato ad avvistato | A §7.5, A §2.6.1 |
| 03 §4.8.2 | Raggio di osservazione e portata di esplorazione | A §7.5, A §2.6.1, A §2.6.2 |
| 03 §4.8.3 | Soglie di competenza per sabotaggio e protezione | A §7.5, A §3.3 |
| 03 §4.8.4 | Parametri deterministici degli esiti sfavorevoli di ricognizione | A §7.5, A §4.2 |
| 03 §4.9.1 | Moltiplicatori di apertura battaglia e sensibilità stanchezza | A §7.5 (archetipi.json), A §7.4 |
| 03 §4.9.2 | Passi di degrado manutenzione e probabilità di guasto | A §7.5, A §4.2 |
| 03 §4.10.1 | Soglia in turni della sortita e termini imminenza | A §7.5, A §4.4 |
| 03 §4.11.1 | Probabilità meteo per stagione ed effetti sulla marcia | A §7.5 (meteo.json), A §4.2 |
| 03 §5.1 | Penalità di avanzamento per archetipo con formula unica | A §7.5 (archetipi.json), A §7.4 |
| 03 §5.2 | Capacità di volume per turno, primo turno maggiorato | A §7.5 (formato-battaglia.json) |
| 03 §5.3 | Costo aggiuntivo dello spostamento di due celle | A §7.5, A §3.4 |
| 03 §5.4 | Coefficienti di munizioni, armi, protezioni con formula | A §7.5 (archetipi.json), A §7.4 |
| 03 §5.5 | Frazione di danno dell'arma poco adatta | A §7.5, A §7.4 |
| 03 §5.6 | Portate di mischia, tiro e artiglieria in celle | A §7.5 (archetipi.json) |
| 03 §5.7 | Dotazione di munizioni per archetipo, non reintegrabile | A §7.5 (archetipi.json) |
| 03 §5.8 | Soglie di disingaggio come proporzione della consistenza | A §7.5 (archetipi.json), A §2.7 |
| 03 §5.9 | Turni di vantaggio dell'imboscante e sconto piazzamento | A §7.5, A §2.7 |
| 03 §5.10 | Riporto di volume fra turni al dieci per cento | A §7.5 (formato-battaglia.json), A §2.7 |
| 03 §5.11 | Formula del turno di arrivo dei rinforzi | A §7.4, A §7.5 |
| 03 §5.12 | Modificatori delle caratteristiche del campo su ganci tipizzati | A §7.5 (caratteristiche-campo.json), A §7.7 |
| 03 §5.13 | Capacità di volume per formato, ordine fisso | A §7.5 (formato-battaglia.json), A §3.9 |
| 03 §6.1 | Soglia minima di turni prima della resa | A §12.4, A §12.2 (scontro singolo) |
| 03 §6.2 | Margine di convenienza della ritirata combattuta | A §12.4, A §12.2 (scontro singolo) |
| 03 §6.3 | Costo di mantenimento come freno all'accumulo | A §12.4, A §12.2 (partita lunga) |
| 03 §6.4 | Ampiezza della fascia in cui il tiro uccide | A §12.4, A §12.2 (scontro singolo) |
| 03 §6.5 | Carattere degli ufficiali e frequenza degli scontri | A §12.4, A §12.2, A §7.5 (ufficiali.json) |
| 03 §6.6 | Rapporto volume-profondità e peso della sorpresa | A §12.4, A §12.2 |
| 03 §6.7 | Precisione dell'apporto informativo invernale | A §12.4, A §12.2 (partita lunga) |
| 03 §6.8 | Peso effettivo della fortezza in campagna difensiva | A §12.4, A §12.2 (campagna) |
| 03 §6.9 | Sbilanciamento dei formati di mappa minori | A §12.4, A §12.2 |
| 03 §7.1 | Vantaggi nascosti noti al programma di verifica | A §5.5, A §12.5 |
| 03 §7.2 | Vantaggi stabiliti: ritirata avversaria limitata e rara | A §5.5, A §7.5 (vantaggi-nascosti.json) |
| 03 §7.3 | Ogni nuovo vantaggio va registrato qui e altrove | A §5.5 |
| 03 §8.1 | Minimo dichiarato dove il troncamento può dare zero | A §2.2, A §7.8 |
| 03 §8.2 | Casi individuati di minimo obbligatorio | A §2.2, A §7.8, A §7.5 (minimi.json) |
| 03 §9.1 | Collocazione dei file: fabbrica, Documenti, ripiego dichiarato | A §7.1 |
| 03 §9.2 | Manifest dei valori con versione e compatibilità | A §7.2, A §6.6 |
| 03 §9.3 | Forma delle voci: base, coefficiente, intervallo con variazione | A §7.3, A §7.4 |
| 03 §9.4 | Elenco dei file dei valori e corrispondenze | A §7.5, A §7.6 |
| 03 §9.5 | Testi: pacchetti per lingua, vocabolario chiuso, manifest | A §8.1, A §8.2, A §8.3, A §8.4, A §8.6 |
| 03 §9.6 | Scenari di verifica dichiarativi con soglie di accettazione | A §12.2, A §12.6 |

---

## Aggiornamento della prima unità della fase D — la mappa navigabile

I requisiti che questa unità realizza, con il punto del codice che vi provvede e la prova che lo verifica. Le righe assenti da questo elenco NON sono dimenticanze: sono i requisiti della campagna che questa unità lascia deliberatamente fuori, elencati per intero in coda.

| Requisito | Sintesi | Realizzazione | Prova |
|---|---|---|---|
| 01 §5.1 | Caselle quadrate, adiacenza ortogonale, quattro vicini, tre formati | `GrigliaCampagna`, `formati-mappa.json` | `RegoleCampagnaTest` (adiacenza, bordi, formati) |
| 01 §5.1.2 | Qualificazione delle caselle; mappa interamente percorribile | `TerrenoCasella`, `MappaCampagna.terreno` | `RegoleCampagnaTest.test_01_5_1_2_*` |
| 01 §5.1.3 | Strettoia, al più una, non in ogni mappa | `DefinizioneMappa.strettoia`, validazione | `RegoleCampagnaTest`, `CaricamentoCampagnaTest` |
| 01 §5.2.1 | Quartier generale, perno della mappa | `MappaCampagna.quartierGenerale` | `RegoleCampagnaTest.test_01_5_14_3_2_*` |
| 01 §5.5.3 | Rete stradale con tipi diversi di strada | `TipoStrada`, dichiarata per casella | `RegoleCampagnaTest.test_01_5_1_2_la_casella_dichiara_*` |
| 01 §5.6 | Un'azione al giorno per gruppo | `MotoreCampagna.valida` | `RegoleCampagnaTest.test_01_5_6_*` |
| 01 §5.6.0.1 | Numero dei gruppi libero, nessun tetto | `ScenarioCampagna.gruppiGiocatore` | `BancoCampagna` (da 1 a 8 gruppi) |
| 01 §5.6.0.4 | Nome proprio breve e stabile da lista chiusa | `Gruppo.nome`, `nomi-gruppi.json` (RDA-65) | `RegoleCampagnaTest`, `TraduttoreCampagnaTest` |
| 01 §5.6.0.5 | Ogni azione consuma l'intera giornata del gruppo | `MotoreCampagna.applica` | `RegoleCampagnaTest.test_01_5_6_0_5_*` |
| 01 §5.6.0.6 | Chiusura automatica; stare fermi è un'azione | `chiudiLaGiornataSeServe`, `.presidio` (RDA-61) | `RegoleCampagnaTest`, `MappaCampagnaAccessibileTest` |
| 01 §5.6.0.2 | Al più una propria formazione per casella | validazione della marcia | `RegoleCampagnaTest.test_01_5_6_0_2_*` |
| 01 §5.6.3.1 | Nessun percorso di più caselle in un turno | `.marcia` su casella adiacente | `RegoleCampagnaTest.test_01_5_6_3_1_*` |
| 01 §5.14.4.1 | Il tipo di strada fa parte di ciò che la casella dichiara | `CostruttoreAnnunciCampagna` | `MappaCampagnaAccessibileTest` |
| 01 §5.16 | Tre strati di orientamento | stato, salto, dichiarazione del gruppo | `RegoleCampagnaTest`, banco delle misure |
| 01 §5.16.1 | Stati del gruppo, vocabolario chiuso | `StatoGruppo` ridotto a due termini | `RegoleCampagnaTest`, `TraduttoreCampagnaTest` |
| 01 §5.17 | Registro cronologico dei fatti non decisi | `VoceRegistro`, `SchermataRegistro` | `RegoleCampagnaTest`, `MappaCampagnaAccessibileTest` |
| 02 §2.3 | Quattro vicini: est, ovest, nord, sud | `GrigliaCampagna.vicini` | `RegoleCampagnaTest` |
| 02 §2.5 | Due azioni personalizzate sulla mappa | `azioniDirezione` | `MappaCampagnaAccessibileTest.test_02_2_5_*` |
| 02 §2.8 | Ordine di lettura dichiarato | `view.accessibilityElements` | `MappaCampagnaAccessibileTest.test_02_2_8_*` |
| 02 §3.8.1 | Ordine registrato dopo la testa fissa (RDA-63) | `contenutoCasella` | `MappaCampagnaAccessibileTest` |
| 02 §6.5.1.3 | Formato dell'informazione di stato | `informazioneDiStato` | `RegoleCampagnaTest.test_02_6_5_1_3_*` |
| 02 §6.6 | Registro come elenco di voci con salto al luogo (RDA-67) | `SchermataRegistro` | `MappaCampagnaAccessibileTest.test_02_6_6_*` |
| 02 §6.7 | Tocco magico e gesto di fuga (P10) | `accessibilityPerformMagicTap`, `...Escape` | solo dispositivo per i gesti reali |
| 02 §7.3 | Rotori della mappa, per gli insiemi che esistono | `montaRotori` | `MappaCampagnaAccessibileTest.test_02_7_3_*` |
| 02 §9.2.1 | Sequenza a due caselle con designazione | designazione della marcia | `MappaCampagnaAccessibileTest` |
| 02 §9.5 | Azione impossibile non offerta | `esisteDestinazione` | `MappaCampagnaAccessibileTest.test_01_5_16_*` |
| 05 §2.6 | Stato di campagna: data, mappa, gruppi, registro | `StatoCampagna` | `RegoleCampagnaTest` |
| 05 §2.9 | Impronta canonica | `StatoCampagna.impronta()` | `RegoleCampagnaTest.test_05_2_9_*` |
| 05 §3.3 | Comandi di campagna dall'elenco chiuso di 01 §5.6.8.1 | `ComandoCampagna` (due delle sedici voci) | `CompatibilitaGiornaleTest` |
| 05 §6.1–6.5 | Giornale, istantanee, ripresa, annullamento, azzeramento | `SessioneCampagna` | `SessioneCampagnaTest` |
| 05 §6.6 | Salvataggi versionati | ripresa con rifiuto dichiarato | `SessioneCampagnaTest.test_00_15_2_*` |
| 05 §7.6 | Mappe come file dichiarativi (S4) | `Valori/Mappe/`, `CaricatoreCampagna` | `CaricamentoCampagnaTest` |
| 05 §7.8 | Validazione con rapporto a chiavi | `CaricatoreCampagna.valida` | `CaricamentoCampagnaTest` (undici respinte volute) |
| 05 §10.1 | Elementi persistenti aggiornati sul posto | `ElementoCasella` | `MappaCampagnaAccessibileTest.test_00_11_1_*` |
| 05 §12.2 | Scenari di verifica dichiarativi | `Scenari/Campagne/campagne.json` | `InvariantiCampagnaTest` |
| 05 §12.4 | Metriche riportate dal programma di verifica | quattro sezioni di campagna | `FumoDelleSimulazioniTest` |

### Che cosa questa unità lascia fuori, e dove sta scritto

Rifornimento e regola del taglio (01 §5.2.2), autonomia e sosta con raccolta (01 §5.6.5), stanchezza e manutenzione (01 §5.7), marcia lunga e costo in giorni (01 §5.6.3), marcia forzata e secondo scatto (01 §5.6.4), divisione e riunione (01 §5.6.0.2–0.3), riordino degli assetti (01 §4.8), conoscenza e ricognizione (01 §5.3, §5.4), imboscata (01 §5.11), opere da campo e permanenti (01 §5.14), sabotaggio e studio approfondito (01 §5.10.2), aggiramento (01 §5.13), innesco e rifiuto della battaglia (01 §6), piazzeforti e assedi (01 §8 bis), stagioni e meteo (01 §5.9), regno e inverno (01 §5.5, §5.9.1), campagne contemporanee e architettura a tre livelli (01 §5.6.9, §5.6.10), avversario sulla mappa (05 §5.3, lo stratega).

Ne discendono per conseguenza, e restano anch'essi fuori: gli stati del gruppo diversi da «in attesa» e «ha agito» (02 §4.4.5), gli stati di conoscenza (02 §4.2), i rotori di 02 §7.3 diversi dai due realizzati, le voci del registro diverse dall'apertura della giornata, e la coerenza fra città e strade richiesta da 05 §7.8, poiché le città appartengono alle unità che le rendono utili.
