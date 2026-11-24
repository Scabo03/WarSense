# Il banco del regno alla seconda tappa (incarico 31)

- Corsa sul codice del commit `c3b5e2a` del ramo `incarico-31` (albero dei sorgenti pulito: `git status --short -- Codice/Sources` vuoto). Una prima corsa, fatta a tappa non ancora chiusa e con l'addestramento mirato a 0,8 di peso, dava 1835 anni e nessuna violazione; i suoi numeri non sono conservati qui, perché il valore è cambiato (03 §4.4.3.1).
- Strumento: `BancoRegno` e `SondaInvariantiRegno` (`Codice/Sources/Verifica/BancoRegno.swift`), da riga di comando:
  `cd Codice && swift build -c release --product StrumentoVerifica && .build/release/StrumentoVerifica --regno 200 --anni 5 --uscita ../Incarichi/31-2026-11-23-prodotti/banco-del-regno`. Durata della corsa: 4 s (`date +%s` attorno al comando).
- Dati grezzi: `banco-del-regno.jsonl`, una riga per anno giocato (1829). Riepilogo dello strumento: `banco-del-regno.txt`. Tabelle: `tabelle.md`, da `python3 riassumi.py banco-del-regno.jsonl` (lo script dell'incarico 30 con una sezione in più per le cose della seconda tappa); `dettagli.md`, da `python3 dettagli.py banco-del-regno.jsonl`. Nessun numero di questo file è calcolato a mano: ciascuno sta in uno dei tre.
- Valori: 0.15.0, novanta giornate operative.
- Metodo: 200 partite di cinque anni per ciascuna delle due condotte della misura della frequenza delle battaglie (competente e prudente). Il fronte ruota col seme e con l'anno. La campagna dell'anno si gioca fino alla conclusione (annientamento o inverno); una battaglia che al banco non si conclude ferma la partita, e l'anno si registra «ferma».

## Che cosa è cambiato nella condotta del banco rispetto all'incarico 30

Nell'incarico 30 il banco ordinava le leve tutte alla prima schermata dell'inverno, a turno fra le tre voci, finché le risorse bastavano. Ora usa ciò che la seconda tappa aggiunge (RDA-182):

- in una partita su tre — i semi che divisi per tre danno resto due — tiene in patria la formazione non armata negli anni pari e la rimanda al fronte nei dispari;
- d'inverno, per prima cosa mantiene ciò che è già migliorato;
- poi, in ciascuna delle prime tre schermate, ordina una volta ogni voce che può pagare, e per le voci che si ordinano su un reparto sceglie il primo reparto che le ammette; nella quarta continua finché ne resta una che si può pagare.

Così i lavori cadono in schermate diverse, quelli lunghi ordinati tardi arrivano a campagna aperta, e i reparti ricevono e conservano l'addestramento mirato. I numeri di questa corsa e quelli dell'incarico 30 (`Incarichi/30-2026-11-22-prodotti/banco-del-regno/tabelle.md`) non misurano quindi la stessa condotta in patria: il confronto dice che cosa accade al regno con le regole e la condotta nuove, non quanto pesi ciascuna regola da sola.

## Che cosa dice la sonda

Nessuna violazione dei ventitré invarianti in 1829 anni, nessun errore, nessuna proposta dell'avversario respinta (`banco-del-regno.txt`; l'ultima riga di `tabelle.md` elenca i codici osservati: nessuno). I dieci invarianti nuovi sorvegliano i nomi unici e conservati, la formazione in patria che non cambia, la scelta di chi parte, il mantenimento conservato ed esatto, lo scioglimento soltanto se necessario e nell'ordine giusto, i miglioramenti secondo le voci ordinate, la stagione in cui un lavoro è pronto. Che ciascuno scatti quando lo si viola di proposito lo provano i mutanti di `BancoRegnoTest` («SONDA-REGNO invarianti=13 mutanti_riferiti=13» e «SONDA-REGNO-31 invarianti=10 mutanti_riferiti=10», stampati dalla prova).

## Come finisce la campagna dell'anno

Dalla prima tabella di `tabelle.md`. Su 1829 anni la campagna finisce con l'inverno in 1551, per annientamento in 200 — tutti vinti dal giocatore: nessuna campagna è persa — e in 78 la partita si ferma su una battaglia che al banco non si conclude. Nell'incarico 30 erano 1559, 115 e 112 su 1786.

- **La condotta prudente ora vince 66 campagne**, tutte al quinto anno sul guado, ogni volta con nove formazioni e 121 atomi alla partenza, tre battaglie di cui una vinta e due perse (`dettagli.md`). Nell'incarico 30 non ne vinceva alcuna. La lettura è che dopo quattro inverni le forze del regno sono cresciute mentre l'avversario è quello dello scenario, che non ha un inverno (S29m): non è una causa misurata, e il banco non la può isolare, perché quegli anni appartengono tutti alle partite in cui il fronte del quinto anno è il guado.
- **La condotta competente** vince 134 campagne, 118 sul guado e 16 sulla pianura lunga, in tutti e cinque gli anni; erano 115.
- **Le partite ferme** sono 78, tutte della condotta competente: 48 sul guado, 21 sull'istmo, 9 sulla pianura lunga. Erano 112. È il difetto noto dell'incarico 29, che l'incarico 31 lascia a un incarico successivo; che qui si presenti meno spesso non ha una causa accertata, perché regole e condotta in patria sono cambiate insieme.
- **Un fatto da guardare, non di questa tappa.** `dettagli.md` mostra campagne della condotta competente vinte per annientamento senza che il giocatore abbia vinto alcuna battaglia (i casi «3, 0, 3»: tre battaglie, nessuna vinta, tre perse). La regola della conclusione per annientamento è quella dell'incarico 30 (RDA-164), che questa tappa non tocca; il caso non è stato indagato.

## Le forze e il bilancio

Dalla seconda tabella di `tabelle.md`. Le forze crescono ancora d'anno in anno: mediana degli atomi alla partenza, negli anni conclusi, da 75 a 131 per la condotta competente e da 75 a 141 per la prudente. Le formazioni che partono sono di più — mediana da cinque a sette per la competente, da cinque a undici per la prudente —, perché le reclute di un inverno formano una formazione per ciascuna stagione in cui maturano.

## Le cose nuove della seconda tappa

Dalla quarta tabella di `tabelle.md` e da `dettagli.md`.

- **Il mantenimento.** La mediana del prelievo va da 27 monete al primo anno a 43 al quinto per la condotta competente e a 50 per la prudente; sugli anni conclusi il minimo è 12 e il massimo 62, su una rendita di 200. In nessun anno un reparto è stato sciolto: coi valori di fabbrica il denaro basta sempre, e lo scioglimento dei reparti reclutati per ultimi lo esercitano soltanto le prove (`SecondaTappaDelRegnoTest`, coi valori cambiati per la via dei Documenti, e le prove del pacchetto). Il freno all'accumulo, in questa misura, non frena: le forze crescono come prima.
- **I miglioramenti.** 194 addestramenti mirati ordinati e 217 mantenimenti in tutto. Sono pochi: la condotta del banco ordina le leve prima dell'addestramento, e con dodici monete e mezza per atomo ciò che resta dopo le leve raramente basta.
- **Gli arrivi a campagna aperta.** In 1379 anni almeno una formazione di reclute arriva in estate o in autunno; dal secondo anno accade in quasi tutti gli anni conclusi.
- **Le formazioni tenute in patria.** 151 anni: 66 al secondo anno e 66 al quarto per la condotta prudente, 15 e 4 per la competente (`dettagli.md`, che conta anche gli anni fermi). Il banco tiene in patria la formazione non armata, e soltanto se il regno ne ha ancora una.

## Che cosa questa misura non dice

Non misura il bilanciamento: i valori sono provvisori (`valori-provvisori.md`), e l'avversario non ha un inverno. Non dice quanto pesi ciascuna regola nuova, perché la condotta in patria è cambiata insieme alle regole. Non esercita lo scioglimento per denaro insufficiente. Le battaglie sono combattute dal tattico del banco per entrambe le parti, come nell'incarico 29.
