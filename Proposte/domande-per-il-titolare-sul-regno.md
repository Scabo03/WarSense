# Il regno: le domande per il titolare

Documento di lavoro dell'incarico 30 (2026-11-22), compagno di `Proposte/piano-del-regno.md`.

Qui stanno soltanto le scelte di gioco che i documenti non risolvono. Per ciascuna: il punto dei documenti che la solleva, le opzioni, la raccomandazione con il suo motivo, e che cosa fa intanto la build 31. Nessuna di queste domande ha fermato il lavoro: dove serviva una risposta per costruire, la prima tappa usa la lettura più stretta di ciò che è scritto e valori provvisori, che si cambiano nei file senza rifare nulla.

Prima di scriverle ho cercato la risposta nei documenti 00, 01, 02, 03, 05, nel documento della modalità a campioni, nel registro delle decisioni, nel registro degli scostamenti, nelle decisioni della fase due e nelle direzioni tematiche. Ciò che era già deciso non è qui: per esempio che il mantenimento costa poco (decisioni della fase due, 1.32), che il bottino non esiste e che le vittorie alimentano le risorse (ECO-09), che il regno non ha una fine (05, 2.11).

**Chiuse il 2026-11-23 (incarico 31).** Il titolare ha risposto a tutte e sei. Sotto ciascuna domanda sta la decisione, con il documento e il punto in cui è scritta e con lo stato della costruzione; il testo delle domande resta com'era il 22 novembre. Le sei decisioni sono registrate insieme nel registro delle decisioni architetturali, voce RDA-173. In breve: 1, opzione A adesso e C quando la campagna avrà un esito territoriale; 2, opzione B; 3, opzione A; 4, opzione B; 5, opzione A con lo scioglimento dei reparti reclutati per ultimi; 6, opzione A.

---

## 1. Da dove vengono le risorse, e quanto pesa come è andata la guerra

**Che cosa dicono i documenti.** La ricchezza del regno «arriva da un canale astratto che non si gestisce» (01, 1.3.1). «Le vittorie in campagna alimentano le risorse del regno» (01, 2.6). Nella modalità a campioni «gli scontri producono ciò che si spende nel regno» (modalità a campioni, 8.1). Nessun punto dice in che proporzione, né se conti la campagna vinta, la singola battaglia vinta, o tutte e due; né se una sconfitta tolga qualcosa oltre agli uomini perduti.

**Le opzioni.**

- A. Una rendita fissa ogni anno, uguale comunque vada, più un premio per ogni battaglia vinta e un premio più grande per la campagna vinta. Chi perde non paga nulla: ha già perso gli uomini.
- B. Nessuna rendita: tutto viene dalle vittorie.
- C. Come A, ma il premio della campagna vinta non è una tantum: alza la rendita degli anni seguenti, perché il territorio preso continua a rendere.

**La raccomandazione: A adesso, C quando esisteranno i territori.** B fa della prima sconfitta una spirale, perché chi perde non può ricostruire e perde ancora; i documenti dicono che il gioco rinuncia proprio a questo (01, 1.3.1: «una sconfitta poteva costare vent'anni a uno Stato»). C è la forma più coerente con le opere che si costruiscono «in territorio conquistato» (01, 5.14.2), ma richiede che la campagna abbia un esito territoriale, che oggi non ha. Il premio per battaglia tiene uguale il regno nelle due modalità, come vogliono i documenti: nella modalità a campioni gli scontri sono la sola cosa che produce.

**Che cosa fa la build 31.** L'opzione A, con numeri provvisori: ogni inverno arriva la rendita; ogni battaglia vinta aggiunge un decimo della rendita, la campagna vinta ne aggiunge metà.

**Decisione del titolare (2026-11-23): A adesso, C quando la campagna avrà un esito territoriale.** Ogni inverno arriva una rendita fissa, uguale comunque sia andata, più un premio per ogni battaglia vinta e un premio più grande per la campagna vinta; chi perde non paga nulla in più. Quando la campagna avrà un esito territoriale, la campagna vinta non darà più un premio una tantum ma alzerà la rendita degli anni seguenti. Scritta in: documento 01 (versione 3.11), punti 5.5.1.6 e 5.5.1.6.1, con i rinvii in 1.3.1 e 2.6; documento 03 (versione 2.8), punto 4.4.6. Costruita: la prima parte sì, dalla build 31, e i numeri restano tarabili nei file; la rendita accresciuta no, perché attende l'esito territoriale della campagna.

---

## 2. Quante giornate dura una stagione

**Che cosa dicono i documenti.** «L'anno ha un ritmo fisso e prevedibile» e d'inverno non si conduce campagna (01, 5.9). Nessun punto dice quante giornate durino primavera, estate e autunno.

**Perché conta.** È il numero che decide quanta campagna sta in un anno, e quindi ogni quanto arriva l'inverno, cioè la parte nuova del gioco. La misura dell'incarico 29 dà i termini: sulle mappe di oggi una partita che arriva alla fine ci arriva, nel caso mediano, fra la quarantaduesima e la cinquantacinquesima giornata, e la prima battaglia nasce, nel caso mediano, fra la diciottesima e la sessantottesima secondo la mappa (condotta competente; numeri dello strumento di misura della frequenza, tabelle in `Incarichi/29-2026-11-21-prodotti/frequenza-battaglie/tabelle.md`).

**Le opzioni.**

- A. Venti giornate per stagione, sessanta l'anno. L'inverno arriva presto; sulla mappa grande l'anno finisce attorno alla prima battaglia.
- B. Trenta giornate per stagione, novanta l'anno. Una campagna sulla mappa piccola o media ha il tempo di decidersi; sulla grande resta tempo dopo il primo scontro.
- C. Sessanta giornate per stagione, centottanta l'anno. Più vicino a una stagione di guerra vera, ma con le battaglie rare come sono oggi vuol dire molte giornate vuote prima di ogni inverno.

**La raccomandazione: B.** È il numero più piccolo che lascia concludere una campagna sulle mappe che esistono. Va riguardato quando gli avversari avranno il loro regno e le loro forze, perché la frequenza delle battaglie cambierà.

**Che cosa fa la build 31.** Trenta giornate per stagione. Il numero sta in un file e si cambia senza toccare il programma.

**Decisione del titolare (2026-11-23): B.** Trenta giornate per stagione, novanta l'anno, come nella build 31. Scritta in: documento 01 (versione 3.11), punto 5.9.5, con il rinvio in 5.9; documento 03 (versione 2.8), punto 4.11.2. Costruita: sì, dalla build 31; il numero non è più provvisorio.

---

## 3. La campagna che l'inverno interrompe

**Che cosa dicono i documenti.** D'inverno «le operazioni si fermano, si resta in patria» (01, 5.9). Le opere da campo «decadono con la campagna» (01, 5.14.1.2) e la fortezza espugnata torna operativa «dall'anno successivo» (01, 5.14.3.4): la campagna, dunque, non scavalca l'inverno. Ma nessun punto dice come si chiuda quella che l'inverno coglie a metà, quando nessuno ha preso il quartier generale dell'altro.

**Le opzioni.**

- A. Senza vincitore. Ciascuno rientra con ciò che gli resta, e nessun territorio cambia padrone.
- B. Riprende in primavera dalle stesse posizioni, come se l'inverno fosse una pausa.
- C. Vince ai punti chi è più avanti: chi ha vinto più battaglie, o chi è più vicino al quartier generale dell'altro.

**La raccomandazione: A.** È la sola che non aggiunge regole e che rispetta «si resta in patria». B contraddice i due punti citati sopra, e fa dell'inverno un intervallo, che i documenti escludono espressamente (01, 5.9.1: «non è un intervallo fra due campagne»). C introduce un vincitore designato da un calcolo, che il gioco ha già rifiutato per la battaglia (01, 15.2.4).

**Che cosa fa la build 31.** L'opzione A.

**Decisione del titolare (2026-11-23): A.** La campagna che l'inverno interrompe si chiude senza vincitore: ciascuno rientra con ciò che gli resta, e nessun territorio cambia padrone. Scritta in: documento 01 (versione 3.11), punto 5.18.1, dentro il nuovo punto 5.18 che raccoglie le vie di conclusione della campagna. Costruita: sì, dalla build 31.

---

## 4. Ritirare l'esercito prima dell'inverno

**Che cosa dicono i documenti.** A chi attacca una fortezza «restano le altre due vie della resa e dell'annientamento» (01, 5.14.3.3): la resa è dunque uno dei modi in cui una campagna finisce. Nessun punto la definisce per la campagna; la resa che i documenti descrivono è quella della battaglia (01, sezione 10).

**Le opzioni.**

- A. Il giocatore può richiamare l'esercito in patria quando vuole: la campagna finisce come perduta, i superstiti tornano tutti.
- B. Come A, ma soltanto se nessun suo gruppo ha il rifornimento tagliato o è a contatto col nemico: ci si ritira finché si può, non quando si è già presi.
- C. Nessuna resa della campagna: finisce soltanto per quartier generale, annientamento o inverno.

**La raccomandazione: B.** Senza una resa, chi ha perso lo scontro decisivo deve giocare a vuoto fino all'inverno; con la resa libera, ritirarsi non costa mai nulla. La condizione di B usa regole che esistono già e fa del ritirarsi in tempo una decisione, com'è per la battaglia (01, 6.1.2).

**Che cosa fa la build 31.** Niente: la resa della campagna non è costruita. Appartiene al completamento della campagna.

**Decisione del titolare (2026-11-23): B.** Il giocatore può richiamare l'esercito in patria prima dell'inverno soltanto se nessun suo gruppo ha il rifornimento tagliato o è a contatto con il nemico. La campagna conta come perduta, e i superstiti tornano tutti. Scritta in: documento 01 (versione 3.11), punto 5.18.2, con il rinvio in 5.14.3.3. Costruita: no; si costruisce con il completamento della campagna, non nell'incarico 31. Prima di costruirla resta da precisare che cosa valga come contatto con il nemico sul piano di campagna, e a quale livello valga il richiamo quando una campagna avrà più fronti (documento 01, punto 16.8).

---

## 5. Il mantenimento dei reparti

**Che cosa dicono i documenti.** I miglioramenti «si perdono se non mantenuti», e mantenere «costa poco» (01, 4.14). Il costo di mantenimento è «l'unico freno automatico all'accumulo di forze», perché «un esercito numeroso paga una quota che uno piccolo non paga e tenere in piedi reparti inutilizzati ha quindi un prezzo» (01, 4.14.1). Non è detto se questa quota la paghino anche i reparti che non hanno alcun miglioramento, né se si paghi da sé o sia una voce che il giocatore sceglie, né che cosa accada a un reparto per cui non si paga.

**Le opzioni.**

- A. Ogni reparto ha una quota annua, che il gioco preleva da sé all'inizio dell'inverno e dichiara nella prima schermata. I miglioramenti sono voci a parte: chi non le paga li perde, il reparto resta.
- B. Pagano soltanto i miglioramenti. I reparti senza miglioramenti non costano nulla.
- C. Tutto è una voce che il giocatore sceglie, reparto per reparto; il reparto non mantenuto si scioglie.

**La raccomandazione: A.** Con B un esercito grande e mai migliorato non pagherebbe nulla, e il freno di cui parla il punto 4.14.1 non esisterebbe. C mette nell'inverno un elenco da ripercorrere ogni anno, che è ciò che le decisioni della fase due volevano evitare (1.32: un mantenimento pesante «trasformerebbe l'inverno in manutenzione»). Resta da decidere, con A, che cosa accade se il denaro non basta: propongo che il gioco lo dichiari e sciolga per primi i reparti reclutati per ultimi.

**Che cosa fa la build 31.** Niente: il mantenimento arriva con la seconda tappa.

**Decisione del titolare (2026-11-23): A, con l'aggiunta proposta nella raccomandazione.** Ogni reparto ha una quota annua piccola, che il gioco preleva da sé all'inizio dell'inverno e dichiara nella prima schermata. I miglioramenti sono voci a parte: chi non li paga li perde, ma il reparto resta. Se il denaro non basta, il gioco lo dichiara e scioglie per primi i reparti reclutati per ultimi. Scritta in: documento 01 (versione 3.11), punti 4.14.1.1 (la quota, e lo scioglimento se il denaro non basta) e 4.14.1.2 (i miglioramenti), con 4.14.1 e 16.4 aggiornati; documento 03 (versione 2.8), punto 6.3.1. Costruita: si costruisce nella seconda tappa del regno, cioè con l'incarico 31; l'esito è nel resoconto di quell'incarico.

---

## 6. A che cosa servono scorte e derrate

**Che cosa dicono i documenti.** Fra le tre voci che si comprano in patria fuori dall'inverno ci sono «le scorte e le derrate» (01, 5.5.1.4.1), e le risorse in più trovano sempre dove essere spese, «in derrate e scorte» fra l'altro (01, 2.6.5). Ma il cibo non è una risorsa del bilancio (01, 5.5.1.1) e il rifornimento dei gruppi è automatico (01, 5.2.2, 5.6.5). Nessun punto dice che cosa faccia, in gioco, una scorta comprata.

**Le opzioni.**

- A. Allungano l'autonomia: i gruppi che partono dal quartier generale portano più giorni di viveri.
- B. Attenuano la privazione: chi ha il rifornimento tagliato patisce meno, o deve fermarsi meno.
- C. Sono un deposito al quartier generale, che per un certo numero di giornate vale come zona di rifornimento anche se la via dalla patria è tagliata.

**La raccomandazione: A.** Tocca una grandezza che esiste e che si annuncia già in giorni, senza aggiungere una regola. B rende meno leggibile il taglio del rifornimento, che oggi ha effetti fissi e imparabili. C somiglia troppo al magazzino avanzato, che è un'opera e si paga con un inverno di lavoro.

**Che cosa fa la build 31.** Niente: le voci fuori dall'inverno arrivano con la quarta tappa.

**Decisione del titolare (2026-11-23): A.** Scorte e derrate allungano l'autonomia: i gruppi che partono dal quartier generale portano più giorni di viveri. Scritta in: documento 01 (versione 3.11), punto 5.6.5.2, con i rinvii in 2.6.5 e 5.5.1.4.1; documento 03 (versione 2.8), punto 4.3.3. Costruita: no; si costruisce con la quarta tappa del regno. Prima di costruirla resta da precisare di quanti giorni e per quanto valga un acquisto (documento 01, punto 16.8).
