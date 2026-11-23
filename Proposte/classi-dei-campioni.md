# Le classi dei campioni — proposta

Bozza di lavoro del 2026-11-22 (incarico 30), rivista il 2026-11-23 (incarico 31). È una proposta e non una decisione: l'elenco delle classi resta una proposta finché la modalità non si costruisce. Sono decisi soltanto i tre punti a cui il titolare ha risposto il 23 novembre (punto 1.5), che stanno nel documento della modalità a campioni, versione 1.3. Non è un documento consolidato, non modifica nessun documento, e nulla di ciò che contiene è costruito.

**Revisione del 2026-11-23 (incarico 31): che cosa è cambiato e perché.** La prima stesura segnava tre cose come sue aggiunte, da decidere (punto 1.5). Il titolare ha deciso: accetta la B, cioè i coefficienti di incursione e di tenuta di linea; accetta la C, cioè lancia e arco per la guardia versatile; respinge la A, perché il tipo di protezione resta separato dal peso, come nella modalità a sciami (registro delle decisioni architetturali, RDA-174). Di conseguenza:

- B e C non sono più proposte. Sono scritte come decise, e sono tolte le vie d'uscita che valevano «se non si vogliono» (punti 1.5, 3.5, 5.2 e 5.3). Per la C la decisione nomina l'armamento; che chi lo porta reagisca resta lettura della proposta, e lo dico dove compare (punto 5.3; sezione 7, tensione 2).
- A è respinta, e con essa cade ciò che ne discendeva. Peso e tipo di protezione sono ora due attributi separati: il punto 3.3 è ritoccato e il 3.4 riscritto per intero. Ogni protezione dichiara l'uno e l'altro (punti 4.3 e 5.4), e l'elenco delle protezioni cambia: un oggetto nuovo nella fase arcaica, l'armatura di linea sdoppiata nella fase antica. Sono rifatte le combinazioni ammesse e ciò che «ne esce» (punti 4.4 e 5.5); sono ritoccati le righe delle armi che dicevano contro chi servono (punti 4.2 e 5.3), il lanciere (punto 4.1), le sottoclassi della fase antica (punto 5.2), gli eroi (punti 4.5 e 5.6), gli ordinamenti (punto 4.6), il riepilogo (punto 5.7) e i costi (punti 6.1, 6.4 e 6.7).
- Nella sezione 7 sono riscritti l'argomento del punto 7.1, l'osservazione sul punto aperto 11.8 (punto 7.2) e le tensioni 1, 2, 4, 8, 10 e 12; la tensione 3 ha una frase in più; sono nuove le tensioni 13 e 14, e i due punti aperti 11.11 e 11.12 del documento della modalità entrano nel punto 7.2. Nel punto 7.4 è riscritta la riga sulla memoria delle decisioni, e sono nuove le voci sulla lettura della revisione, sulla regola del materiale e sul tipo dell'armatura di lamiera.
- Fuori dalle tre decisioni, una frase del punto 6.2 è aggiornata: la domanda sul mantenimento, che dava per aperta, ha avuto risposta lo stesso 23 novembre.
- La sezione 2, sulla verifica storica dell'affermazione del titolare, non è toccata.

**Come è stata scritta e che cosa è stato verificato.** La bozza l'ha scritta un sotto-agente della sessione dell'incarico 30, che ha letto il documento 04 nei limiti dichiarati al punto 7.4 e ha ricontrollato per programma che ogni riga citata esista. La sessione l'ha poi riletta per intero e ha verificato: a campione, venti delle citazioni del 04 confrontando la riga del file con ciò che la bozza le fa dire (r. 136, 216, 607, 609, 714, 856, 907, 911, 968, 1190, 1289, 1930, 2062, 2119, 2129, 2587, 3150, 3346, 3651, 3669: tutte concordi); tutti i rinvii al documento della modalità a campioni (punti 1.3, 2.2, 2.3, 3.1, 4.3, 5.2–5.10, 6.1, 6.2, 7.1–7.7, 8.1–8.4, 9.1, 10.5, 11.1–11.10); i rinvii al documento 01 (2.5.1, 2.8.1, 2.8.2.1, 3.2.1, 3.3–3.3.3, 3.4.3, 3.4.5, 4.1.2, 4.3.1, 4.12–4.14, 5.5.1.2–5.5.1.4.1), a `decisioni-fase-2.md` (1.34, PRO-07, ECO-08, ECO-09, ECO-11–ECO-13) e ai valori (`archetipi.json`, campo `elite_fase`). NON verificate una per una le altre citazioni del 04, circa duecento: vale per esse il solo controllo del sotto-agente. Il punto 6.7, sul raccordo col regno costruito, è aggiunto dalla sessione.

**Che cosa ha verificato la revisione del 23 novembre.** La revisione l'ha scritta un fork della sessione dell'incarico 31. Ha letto sul file, riga per riga, i passi del 04 su cui poggiano i punti riscritti: nella parte II le righe 212–218 e 234–235 dei temi 1 e 2, le righe 466–482 e 493–524 del tema 5, l'intero inizio del tema 6 fino alla riga 646, e le righe 905–915 e 934–936 del tema 12; nella parte III le righe 1185–1190, 1238–1239 e 1289 dei temi 1 e 2, le righe 1691–1693 del tema 5, le righe 1806–1916 del tema 6 con le righe 1918, 1930, 1940 e 1944–1956, le righe 2113, 2249 e 2332 dei temi 8 e 9, le righe 2656–2668 del tema 12; nella parte IV le righe 3120–3130 e 3146–3150; nella parte VI le righe 3651, 3663 e 3669–3673. Ogni riga del 04 citata nel punto 3.4, nelle protezioni dei punti 4.3 e 5.4, nelle frasi ritoccate dei punti 4.1, 4.2, 5 e 5.3 e nelle parti riscritte della sezione 7 è fra queste, ed è stata confrontata con ciò che il testo le fa dire. Ha verificato inoltre: i due profili di protezione nei valori e il tipo nel codice (`offese-e-protezioni.json`, `TipoProtezione`, `ScenarioBattaglia.ElementoScenario`); i punti 2.5.1, 2.5.2, 2.8.1, 2.8.2.1, 3.2.1, 3.3–3.3.3, 5.5.1 e 9.9–9.9.2 del documento 01; il punto 4.4.1.3 del documento 02; i punti 1.28 e 1.34 e le voci PRO-01, PRO-02, PRO-03 e PRO-07 di `decisioni-fase-2.md`. NON ha riverificato le citazioni del 04 nei punti che non ha toccato, né le righe che i punti ritoccati citavano già e che non sono fra quelle elencate (per esempio 04 III T12 r. 2743–2745 e le fonti della fionda con piombo): per esse vale ciò che dice il capoverso qui sopra.

## 1. Che cos'è questo documento

1.1 **Scopo.** Il documento della modalità a campioni (`Fondamenta/modalita-a-campioni.md`, versione 1.3) tiene aperto al punto 11.1 l'elenco delle classi e delle sottoclassi, con armamento ed equipaggiamento. Chiede che l'elenco sia il più possibile coerente con la ricerca storica del documento 04; fino alla versione 1.2 chiedeva anche che si verificasse su quel documento se la modalità sia «perfino più vicina alla realtà storica», come il titolare ritiene. Questa bozza fa le due cose, per la fase arcaica e per la fase antica, e aggiunge le voci del regno con cui combattenti ed eroi si reclutano e si migliorano.

1.2 **Che cosa rispetta.** Nei rimandi, «modalità» seguito da un numero indica un punto del documento della modalità a campioni, e «carta» la carta dei principi, cioè il documento 00.

- Tre assi separati e mai profili preconfezionati: classe e sottoclasse, arma, equipaggiamento, composti da una formula sola (modalità 7.1; carta 13.3).
- L'accoppiamento fra offesa e protezione, con il tipo di protezione come attributo a sé, separato dal peso (modalità 7.2 e 7.2.1; documento 01, punti 3.3.1 e 3.3.2).
- Armamento ed equipaggiamento fissati al reclutamento, per sempre (modalità 7.3).
- Titoli funzionali di due o tre parole, senza nomi propri e senza storie, ciascuno con genere e numero dichiarati (modalità 7.4; documento 02, punto 4.6).
- Nessun riferimento a popoli, Stati, civiltà, periodi o formazioni riconoscibili nei nomi proposti (carta, principio 12; documento 01, punti 2.2 e 3.1). I riferimenti storici compaiono soltanto nelle righe «Fonte» e nella sezione 2, per orientare chi progetta.
- Reazione inversa al peso, tiratori a reazione zero, tiro sulla sola prima linea finché il varco è difeso, munizioni illimitate (modalità 5.6 e 5.8).
- Ciò che è scartato non è riproposto (modalità 9.1 e 9.3).
- Il regno identico nelle due modalità: cinque risorse, inverno, acquisizioni in cinque ambiti (modalità 1.3; documento 01, punti 5.5.1, 5.9 e 2.8.2.1).
- Le truppe della fase precedente restano quelle che sono (documento 01, punto 2.8.1).
- Le tre decisioni del titolare del 23 novembre 2026 (modalità 5.6.3, 7.2.1, 7.3.1, 7.8 e 9.3; punto 1.5).

1.3 **Che cosa non contiene.** Nessun numero tarato. Per ogni voce dice che cosa muove e in quale verso (più, meno), mai di quanto. Le sole frazioni che compaiono sono quelle che il documento della modalità ha già scritto.

1.4 **Come sono citate le fonti.** «04» è `Fondamenta/04-riferimenti-storici.md`, versione 1.0. Le parti sono indicate con il numero romano (II fase arcaica, III fase antica, IV transizione, V lacune, VI note per il progetto), i temi con «T» e il numero, il paragrafo con il suo titolo fra caporali, e le righe del file con «r.». Esempio: 04 II T6 «La protezione normale: la corazza a scaglie» r. 556–566. Dove una voce non ha appoggio nel 04 è scritto: «senza appoggio nel 04: scelta di progetto».

1.5 **Le tre aggiunte della prima stesura, e che cosa ne ha deciso il titolare il 23 novembre 2026.**

- A, respinta. La prima stesura proponeva che il tipo di protezione coincidesse con il peso. Il titolare lo ha respinto: il tipo di protezione resta separato dal peso, come nella modalità a sciami (modalità 7.2.1 e 9.3). È il punto 3.4, riscritto, con tutto ciò che ne discende.
- B, accettata. I due coefficienti che il documento della modalità non nominava, l'incursione e la tenuta di linea, sono decisi (modalità 7.8; punto 3.5). Restano proposta le voci che li portano e la misura.
- C, accettata. L'armamento doppio, lancia e arco, per la sola guardia versatile è deciso (modalità 7.3.1; punto 5.3). La decisione non dice se chi lo porta sia un tiratore: è un punto aperto (modalità 11.11; sezione 7, tensione 2).

## 2. La verifica storica dell'affermazione del titolare

2.1 **L'affermazione.** Il titolare «ritiene questa modalità perfino più vicina alla realtà storica» (modalità 11.1): lo scontro fra pochi campioni su due linee sarebbe più vicino al vero dello scontro fra sciami che si consumano poco per volta.

2.2 **Esito in breve.** L'affermazione regge per la fase arcaica, e in un senso preciso: il 04 mostra che in quella fase ciò che contava in guerra stava in pochi uomini e nei loro oggetti costosissimi, e una modalità che conta i combattenti uno per uno, ciascuno con le sue armi, gli somiglia più di una che conta atomi tutti uguali. Non regge nella forma generale. Il 04 non documenta in nessun punto una battaglia combattuta fra pochi campioni, né un duello che decida uno scontro. Per la fase arcaica dichiara di non sapere come si svolgesse il contatto. Per la fase antica descrive il contrario di ciò che il titolare ritiene: il valore passa dall'individuo alla relazione fra molti uomini in formazione, e lì la più vicina è la modalità a sciami. Quanto al difetto storico che il documento 01 dichiara per gli sciami, cioè il consumo progressivo, la modalità a campioni non è più fedele: è lontana in un altro modo. Consuma ancora poco per volta, uomo per uomo; non ha la rotta; e in più ha le munizioni illimitate.

2.3 **Dove il 04 gli dà ragione.**

1. *Nella fase arcaica ciò che conta sta in pochi uomini e nei loro oggetti.* «La fase arcaica non ha una fanteria corazzata: ha individui corazzati» (04 II T6 «Il rapporto fra protezione di metallo e protezione organica: la lista di bottino di Megiddo» r. 609); la corazza metallica è «oggetto da principe, non da reparto» (r. 607). La sintesi della ricerca: nella fase arcaica ciò che conta è concentrato in pochi oggetti, ciascuno carissimo e legato a un individuo o a un palazzo, e «lo Stato immobilizza ricchezza per avere pochi combattenti» (04 IV.6 «Il salto principale del tema, e dell'intera ricerca» r. 3346–3352).
2. *Il combattente con il suo corredo è già l'unità di conto delle fonti.* Negli inventari di palazzo il carro è contabilizzato come sistema di due uomini armati, con due corazze per registrazione, e carri e corazze sono distribuiti dal palazzo (04 II T12 «Gli inventari in lineare B» r. 934–936). L'equipaggio del carro ha ruoli diversi e complementari e «per natura» non è un raggruppamento omogeneo (04 I.4 r. 136). I testi distinguono sedici tipi di armatura (04 II T12 «Carro, cavalli e armature» r. 911).
3. *Premio e perdita si contano per persona.* Il premio individuale al merito è documentato in modo netto (04 II T12 «Retribuzione, leva e mantenimento» r. 968). Nella fase antica la perdita si concentra sul gruppo che è stato impegnato, quattrocento su settecento nel caso più noto, e «va contata per tipo e non per numero» (04 III T9 «La concentrazione delle perdite» r. 2263–2267; VI.5 r. 3719). Una modalità in cui perdere pochi uomini insostituibili pesa più del loro numero è da questa parte.
4. *Due linee, lo scudo davanti e il tiro dietro, sono documentate.* L'unità minima di un grande esercito della fase antica è la coppia di arciere e portascudo (04 III T1 «Impero neoassiro» r. 1190); una riga di portascudo con dietro righe di arcieri (04 III T2 «Spazio frontale per combattente» r. 1289); il sistema misto è attestato in due tradizioni indipendenti (04 III T6 «Il vantaggio della formazione serrata» r. 1940). Il documento 01 lo riconosce già al punto 4.1.2. Riserva: il 04 lo documenta come disposizione di masse, non di singoli, e i due esempi che porta cadono entrambi nella fase antica.

2.4 **Dove gli dà ragione solo in parte.**

5. *Uscire, colpire e tornare al proprio posto (modalità 5.2).* Somiglia al modello secondo cui il combattimento procede a impulsi, con avanzate nel contatto e arretramenti fuori misura (04 III T8 «Struttura del contatto: il modello a impulsi» r. 2062–2064); somiglia alla lettura del combattimento come duello a portata di lancia in una formazione fluida (r. 2074; III T2 r. 1359); ed è esattamente la condotta documentata delle truppe leggere che logorano una fanteria pesante (04 III T9 «La misura quantitativa» r. 2249). Ma il modello a impulsi «nasce sul mondo romano ed è esteso alle due fasi per analogia» (04 III T8 r. 2062) ed è in parte congetturale (04 III T8 r. 2064), e la lettura a duelli è uno dei due lati di un disaccordo che il 04 riporta e non risolve (04 III T8 «Il disaccordo sull'othismos» r. 2068–2076).
6. *Si muore di rado.* Nella fase antica il vincitore perde dal tre al dieci per cento e il vinto dal dieci al venti (04 I.1 r. 102; III T8 «Perdite — la verifica su Krentz» r. 2084–2088): la maggior parte di chi combatte torna. Una modalità in cui la morte è rara e la ferita frequente sta dalla parte giusta. Ma i tassi della modalità non sono tarati, e il 04 non ha alcun dato sui feriti: «il rapporto fra feriti e morti non è documentato» (04 III T8 «Morti e feriti» r. 2129). Le tre gravità degli infortuni (modalità 6.2) sono una scelta di gioco senza appoggio storico, né a favore né contro.
7. *Il crollo.* Chi perde l'intera prima linea entra in uno stato terminale (modalità 5.10): richiama il fatto che le perdite saltano quando la formazione si rompe (04 VI.3 r. 3651). Ma fino a quel momento ogni campione perde vita poco per volta, come lo sciame perde atomi. È lo stesso consumo progressivo che il documento 01 dichiara deviazione dal documentato per gli sciami (punto 4.3.1), portato alla scala dell'uomo.
8. *I corpi scelti della fase antica.* Esistono, e sono piccoli: unità di circa trecento uomini che ricorrono nelle fonti, una guardia reale di mille, un corpo reale permanente, un corpo di arcieri mantenuto tutto l'anno (04 III T1 r. 1149 e r. 1175; III T12 «L'esercito neo-assiro» r. 2827; III T12 «Arco composito, arcieri e frombolieri» r. 2715–2730). Se lo scontro a campioni si legge come lo scontro di questi soli, regge. Non sono però la guerra della fase.
9. *Le scaramucce.* Se lo scontro a campioni si legge come una scaramuccia fra pochi, e non come la battaglia, un appiglio c'è: il 04 dice che due eserciti potevano restare affrontati undici giorni «con sole scaramucce», e che la battaglia evitata era normale e non eccezionale (04 III T8 «La battaglia evitata» r. 2141; VI.3 r. 3655). Ma le nomina soltanto: non dice chi le combatteva, in quanti, né come.

2.5 **Dove gli dà torto.**

10. *Nessuno scontro fra pochi campioni è documentato.* Ho cercato nell'intero file le parole che lo indicherebbero (duello, campione, eroe, sfida) e letto i temi sulla battaglia delle due fasi: non c'è un solo caso. L'unico poema eroico che il 04 nomina è citato per essere escluso come fonte (04 III T8 r. 2131; VII.6 r. 3773). Gli eserciti che il 04 documenta sono di diecimila o ventimila uomini (04 II T1 «Dimensioni degli eserciti da campo» r. 166–176; I.1 r. 96), i carri sono centinaia o migliaia (04 II T6 «Il carro: che cosa era e perché sparisce» r. 630), i fanti sono quattro volte gli uomini dei carri (04 II T1 «Rapporto tra le armi» r. 212), e la spedizione più piccola che il 04 registra per la fase antica conta trecento uomini (04 III T1 «Atene» r. 1157).
11. *Per la fase arcaica il modo di combattere non è documentato.* «Nessuna fonte arcaica dice se il combattimento fosse continuo o intermittente» (04 II T8 «Struttura del contatto» r. 714; V.1 r. 3540). La funzione stessa del carro è contesa fra due posizioni che il 04 dichiara inconciliabili: piattaforme di tiro schierate a centinaia, poi sopraffatte da «fanterie a sciame», oppure strumento di ostentazione e ausilio della forza principale (04 II T6 r. 638–644). In nessuna delle due il carro è il mezzo di un duello. Quel che resta fermo è soltanto che è carissimo, che vuole terreno aperto e asciutto, e che è arma di uno Stato centralizzato (r. 644).
12. *Per la fase antica la ricerca descrive il contrario.* «La protezione smette di essere un oggetto e diventa una relazione» (04 IV.2 «La protezione da oggetto a relazione» r. 3150): si passa «da un sistema militare organizzato attorno a pochi oggetti costosissimi a un sistema organizzato attorno a molte relazioni economiche» (04 IV.6 r. 3346). La formazione ordinaria è profonda otto file e la più profonda di regola vince (04 III T6 r. 1930); ciò che la fonte antica loda è la struttura «e non il valore individuale» (04 III T11 «La catena spartana» r. 2587); e secondo la posizione verso cui pende oggi il consenso, che il 04 riporta senza sceglierla, il fante pesante tipico era un dilettante non addestrato (04 III T12 «L'addestramento dell'oplita» r. 2743–2745). Qui la modalità a sciami, che rappresenta reparti e formazioni, è la più vicina.
13. *Il momento che uccide è la rotta, e non c'è in nessuna delle due modalità.* La maggioranza dei morti del vinto cade dopo la rottura della linea (04 III T8 «Combattimento contro fuga» r. 2119); «il momento letale è la rotta, non lo scontro» (04 VI.3 r. 3651).
14. *Le munizioni illimitate allontanano.* «Un'unità da tiro antica non è una fonte continua di fuoco: è una scarica» (04 VI.3 r. 3669; III T5 «Munizioni» r. 1754). La modalità a sciami ha le munizioni limitate (documento 01, punto 3.4.3), quella a campioni no (modalità 5.8). È una scelta già presa, e le munizioni limitate sono fra le cose scartate e da non riproporre (modalità 9.1): la registro soltanto come voce del conto.

2.6 **I due suggerimenti del titolare.**

- *«L'eroe sul carro come alto nobile della fase arcaica».* Regge. Nella lista del bottino le sole due corazze di metallo e i due carri lavorati in oro sono dei due comandanti supremi, a fronte di duecento corsaletti di cuoio e di oltre novecento carri (04 II T6 r. 572–589 e r. 603–607); il carro è «il pezzo più caro della fase arcaica» (04 II T12 r. 907); il comando si esercita «per presenza» (04 II T11 «Che cosa se ne ricava» r. 856). Riserve: che cosa facesse il carro in battaglia è conteso (04 II T6 r. 638–644), a chi servisse la corazza di lamiera è conteso (04 II T6 «La protezione estrema» r. 554), e il tempo per addestrare l'uomo del carro non è documentato (04 II T12 «Addestramento» r. 962). Il 04 documenta dunque chi è l'alto nobile e che cosa possiede, non come combatte. La proposta lo traduce nell'eroe «signore del carro» (punto 4.5), che porta la sola protezione di lamiera della partita; la sua capacità propria è una scelta di progetto.
- *«Le élite della modalità a sciami come combattenti normali».* Regge, con una differenza fra le fasi. Le due élite degli sciami sono la piattaforma trainata nella fase arcaica e la guardia scelta nella fase antica (`Codice/Sources/Contenuti/Valori/archetipi.json`, campo `elite_fase`; resoconto dell'incarico 11). Nella fase arcaica chi combatte sul carro non è una rarità: è un ceto vicino al dieci per cento della popolazione dei villaggi soggetti, con protezione ordinaria di cuoio (04 II T1 r. 216; II T6 r. 607). Nella fase antica i corpi scelti sono quelli del punto 8 qui sopra. La differenza è questa: nella fase arcaica ciò che fa l'élite è un oggetto che si possiede, il carro; nella fase antica è un addestramento. Per questo nella proposta l'élite arcaica sta sull'asse dell'equipaggiamento (un arciere o un incursore con il carro per mezzo, punto 4.3) e l'élite antica sta sull'asse della classe (la classe «guardia», con i due tratti che il documento 01 le dà al punto 3.3 divenuti due sottoclassi, come prevede la carta al punto 12.2). Riserva: se i normali sono gli scelti, la modalità non mostra il grosso degli eserciti reali, che scelto non era (punto 12 qui sopra).

## 3. Come si legge l'elenco

3.1 **I tre assi (modalità 7.1).**

- *Classe e sottoclasse*: che cosa il combattente sa fare. La classe dice se combatte da lontano o da vicino; la sottoclasse dice con quale mestiere. Sono insiemi di coefficienti e non contengono né armi né protezioni.
- *Arma*: un oggetto, con i propri coefficienti.
- *Equipaggiamento*: due oggetti, ciascuno con i propri coefficienti. La protezione, che dichiara due cose separate, il peso e il tipo (punti 3.3 e 3.4), e che può mancare; e il mezzo, cioè il carro o la cavalcatura, che hanno soltanto alcuni.

Una formula sola li compone. Nessuna voce ne contiene un'altra: la classe ammette certe armi e certi equipaggiamenti, ma non li porta con sé.

3.2 **Il mezzo è un equipaggiamento e non una classe.** Le ragioni sono quattro. Primo, il 04 tratta carro e cavallo come oggetti: misurati, inventariati, tariffati, distribuiti dal palazzo (04 II T2 «Spazio occupato dai carri» r. 249–266; II T12 r. 905–909 e r. 917–936; III T12 «Cavalleria» r. 2672–2697), fino a dire che «il carro va trattato come oggetto, non come uomo» (04 VI.3 r. 3663). Secondo, il regno li paga con risorse diverse da quelle dell'uomo, cioè con gli animali. Terzo, il passaggio fra le fasi è la sostituzione di un oggetto con un altro, non di un uomo con un altro (04 IV.2 «Dal carro alla cavalleria e alla fanteria pesante» r. 3120–3130), e il documento 01 lo mette infatti fra le acquisizioni dell'ambito montature e macchine (punto 2.8.2.1). Quarto, le classi restano poche: lo stesso mestiere di arciere si esercita a piedi, sul carro e a cavallo. L'obiezione onesta è che combattere da un carro o da un cavallo richiedeva un addestramento specializzato di uomini e animali (04 II T6 r. 642): per questo il mezzo è ammesso soltanto a due sottoclassi, l'arciere e l'incursore, e come ogni altra cosa si fissa al reclutamento.

3.3 **Il peso discende dalla protezione.** È pesante chi porta una protezione ingombrante: molto metallo addosso, oppure uno scudo grande. È leggero chi porta una protezione leggera o nessuna. Né la classe, né l'arma, né il mezzo cambiano il peso. Il peso decide quanto si reagisce (modalità 5.6) e non dice altro: da che cosa si è coperti lo dice il tipo di protezione, che è un attributo a sé (punto 3.4; modalità 5.6.3). Le ragioni:

- nel 04 il peso è una misura degli oggetti e non degli uomini: la protezione di lamiera, la corazza a scaglie, il corredo del fante pesante, la corazza di cuoio hanno ciascuno il proprio peso misurato o stimato (04 II T6 r. 548; II T12 r. 911; III T6 «Il peso della panoplia oplitica» r. 1847–1861; III T6 «La protezione a scaglie» r. 1817);
- la regola della reazione chiama in causa il peso (modalità 5.6): se il peso stesse nella classe, l'equipaggiamento non conterebbe proprio dove la regola lo nomina;
- l'equipaggiamento non cambia mai (modalità 7.3), quindi il peso di un campione si impara una volta sola.

La classe decide però quali protezioni si possono portare (punti 4.4 e 5.5).

*Il tiratore.* Chi ha per arma un'arma da tiro è un tiratore: la sua reazione è zero qualunque protezione porti (modalità 5.6). Lo stato di tiratore discende quindi dall'arma, e prevale sul peso. Ogni campione ha così una di tre reazioni: pesante, circa un terzo; leggero, circa la metà; tiratore, zero.

3.4 **Il tipo di protezione è un attributo a sé, separato dal peso.** Deciso dal titolare il 23 novembre 2026, respingendo la proposta A della prima stesura, che lo leggeva nel peso (modalità 7.2.1 e 9.3). Vale ciò che vale nella modalità a sciami. Lì i tipi di protezione sono due, rispondono in modo opposto alle due offese e nessuno è migliore dell'altro (documento 01, punto 3.3.2); e il tipo è un tratto del reparto, che non discende dall'archetipo (documento 01, punto 3.3). Nel gioco costruito sono i due profili del file `Codice/Sources/Contenuti/Valori/offese-e-protezioni.json`, `anti_saturazione` e `anti_perforazione`, uno speculare all'altro; nel codice il tipo è `TipoProtezione`, e ogni elemento del deck lo dichiara accanto all'archetipo.

Qui è il secondo attributo che ogni oggetto di protezione dichiara, accanto al peso:

- *protegge dalla saturazione*: regge l'offesa che satura e cede a quella che perfora;
- *protegge dalla perforazione*: regge l'offesa che perfora e cede a quella che satura.

I due nomi vengono dalla frase del documento 01, «chi è protetto dalla saturazione è esposto alla perforazione, e viceversa», e servono a questa proposta: non sono termini chiusi. Negli sciami il tipo di protezione non ha un termine proprio: il gioco dichiara soltanto, quando si designa un bersaglio, se l'offesa è «efficace» o «poco efficace» (documento 01, punto 9.9.1; documento 02, punto 4.4.1.3). Qui varrebbe lo stesso: l'offesa che satura è «efficace» contro chi è protetto dalla perforazione e «poco efficace» contro chi è protetto dalla saturazione; l'offesa che perfora, il contrario. Se il tipo vada anche dichiarato con un termine suo è un punto aperto (modalità 11.12; sezione 7, tensione 10).

*Due attributi, quattro incroci.* Peso e tipo non si ricavano l'uno dall'altro: un pesante può essere protetto dall'una o dall'altra offesa, e così un leggero. Il peso dice quanto il combattente reagisce a chi attraversa il varco; il tipo dice che cosa conviene mandargli contro. Il prezzo è quello che la prima stesura dichiarava nel presentare questa via come alternativa: un attributo in più da annunciare e da ricordare per ogni combattente, e qualche oggetto senza riscontro nel 04.

*Come la proposta assegna il tipo agli oggetti: dal materiale.* Perché il tipo sia di un oggetto con un nome e non un'etichetta, e perché chi ascolta non debba imparare una tabella, la proposta usa una regola sola:

- ciò che è di metallo protegge dalla perforazione;
- ciò che non lo è — il cuoio, la tela, lo scudo grande e sottile — protegge dalla saturazione.

La lettura che la regge è che i due tipi siano due modi di proteggere. Il metallo è spesso e costa: ferma il colpo pesante dove copre, e ciò che lascia scoperto è alla portata dei molti colpi leggeri. Ciò che non è di metallo costa poco e copre molto: i colpi leggeri vi si fermano, quello pesante passa. Né l'uno né l'altro modo ha a che fare con il peso: si è pesanti per l'ingombro di uno scudo come per il metallo addosso, e leggeri con un corsaletto di cuoio come con un solo pezzo di bronzo sul petto.

Che cosa la sostiene.

- La distinzione fra le due offese è documentata e misurata: il proiettile leggero da lontano oppure quello più pesante a corta distanza «quando serve penetrare» è «la scelta tattica centrale del tiro antico» (04 II T5 «Confronto documentato fra tipi d'arma» r. 472–480), confermata dal lato delle munizioni (04 II T5 r. 495–506). E il 04 stesso lega le due protezioni alle due offese: «le due scelte, quella dell'attaccante e quella del difensore, sono la stessa scelta vista dai due lati» (04 II T6 «Efficacia sperimentale delle armi contro queste protezioni» r. 622–624).
- Per ciò che non è di metallo il 04 documenta tutte e due le metà del tipo. Il cuoio crudo protegge «meno da vicino», ma resta «efficace a distanza maggiore» (04 II T6 r. 618; VI.3 r. 3673). La corazza di tela ferma negli strati esterni la freccia tirata da quindici metri, e una fonte antica la dice penetrabile da colpi potenti (04 III T6 «Il lino: la protezione che compete con il bronzo» r. 1875 e r. 1880). Gli scudi che riparano dal tiro sono «grandi ma sottili» (04 III T6 r. 1940).
- Per il metallo il 04 documenta la metà che protegge, non senza riserve. La scaglia di bronzo impedisce la penetrazione di tutti i tipi di freccia a corta distanza, cioè là dove si tira la punta pesante (04 II T6 r. 617 e r. 622). Un millimetro di bronzo ferma il colpo di lancia portato dall'alto ma non quello portato dal basso (04 III T6 «Energie di penetrazione» r. 1897), e secondo un calcolo che il 04 dichiara ordine di grandezza non ferma la freccia pesante tirata da vicino (r. 1908–1910).
- Che l'offesa che satura trovi ciò che la protezione lascia scoperto ha due appigli. I molti proiettili leggeri «non perforano scudi né producono ferite immediatamente invalidanti ma», se sono abbastanza, «non hanno bisogno di farlo» (04 III T5 r. 1693). E la fanteria leggera che logorò una fanteria pesante la bersagliò sul «fianco destro scoperto, cioè quello non protetto dallo scudo» (04 III T9 r. 2249).
- La memoria delle decisioni dà per «assorbito dai due tipi di protezione» proprio il confronto fra il lino e il bronzo (`Fondamenta/decisioni-fase-2.md`, tabella dei fattori esclusi, voce PRO-07), e dice i due tipi di «disponibilità profondamente diversa» nella fase arcaica (punto 1.34). Con la regola del materiale il tipo che protegge dalla perforazione è quello che costa metallo, ed è raro finché il metallo è raro.

Che cosa non la sostiene. Il 04 non documenta due protezioni opposte: documenta una scala e una soglia di distanza. «La protezione non è un numero, è una curva»: la scaglia di bronzo ferma tutto da vicino, il cuoio crudo protegge poco da vicino e abbastanza da lontano (04 VI.3 r. 3673; II T6 r. 622). In particolare nessuna protezione documentata regge ciò che perfora e cede a ciò che satura: contro la protezione di metallo la freccia leggera non conta, e il 04 lo dice per tre percorsi indipendenti (04 III T6 r. 1912). Che il metallo sia esposto all'offesa che satura è quindi una regola di gioco. Discende dall'avere due tipi opposti, che è deciso (documento 01, punto 3.3.2), e la lettura «ciò che lascia scoperto» è soltanto il modo di dirla: senza appoggio nel 04: scelta di progetto. Vale per ogni oggetto di metallo dell'elenco, e lo ripeto a ciascuno.

L'assegnazione opposta. La prima stesura, attraverso il peso, dava al metallo la protezione dalla saturazione. Per la lamiera ha dalla sua le righe che qui fanno difetto: la freccia leggera non la passa (r. 1912), il colpo di lancia portato dal basso e la freccia pesante da vicino sì (r. 1897 e r. 1908). Ma obbligherebbe a dire che cuoio e tela proteggono dalla perforazione, contro ciò che il 04 riporta di ciascuno dei due (r. 618; r. 1875 e r. 1880), e lascerebbe quel tipo senza un solo oggetto documentato. Fra le due assegnazioni quella proposta contraddice il 04 soprattutto su una metà di un tipo, l'esposizione del metallo; l'altra su entrambe le metà dell'altro, per il cuoio come per la tela.

*Chi non porta protezione.* «Senza corazza» non è un oggetto e non ha un tipo: chi non porta protezione non è coperto né dall'una né dall'altra offesa, ed entrambe sono «efficaci» contro di lui. È una terza condizione, che la modalità a sciami non ha, perché lì ogni reparto ha uno dei due tipi. Con la proposta A non serviva: chi era leggero era per ciò stesso protetto da ciò che perfora. Separato il tipo dal peso, va decisa (sezione 7, tensione 1).

3.5 **Le parole usate per dire che cosa muove ogni voce.**

- *Vita*: quanta ne ha (modalità 6.1).
- *Attacco*: l'attacco pieno, che è la base tanto del danno quanto della reazione (modalità 5.6).
- *Offesa*: satura o perfora (documento 01, punto 3.3.1). La dà l'arma.
- *Portata*: tiro, che raggiunge la prima linea e la seconda soltanto da un varco indifeso (modalità 5.8); oppure corpo a corpo, che raggiunge la prima linea, e la seconda passando dal varco e pagando il pedaggio (modalità 5.4 e 5.5). La dà l'arma.
- *Peso*: pesante o leggero. Lo dà la protezione (punto 3.3). Decide la reazione.
- *Tipo di protezione*: dalla saturazione o dalla perforazione; nessuno per chi non porta protezione. Lo dà la protezione (punto 3.4). Decide se l'offesa che arriva è efficace o poco efficace.
- *Costo nel regno*: quali delle cinque risorse consuma (sezione 6).
- *Incursione* (decisa il 23 novembre 2026, modalità 7.8): quanto rende in più un colpo portato attraverso un varco. Traduce nelle due linee ciò che il documento 01 dice della cavalleria, che non rompe di fronte ma si infila nei varchi (punto 3.2.1).
- *Tenuta di linea* (decisa il 23 novembre 2026, modalità 7.8): una protezione in più finché i vicini di prima linea sono in piedi, che cade quando cadono. Traduce nelle due linee la protezione come relazione fra vicini.

Le percentuali, cioè il critico, non le tocca nessuna classe, arma o equipaggiamento dell'elenco: restano ai miglioramenti della persona (modalità 8.2). È una scelta per non moltiplicare le probabilità da annunciare (modalità 4.3 e 11.6). La sola eccezione è la capacità di un eroe (punto 5.6).

I due coefficienti sono decisi. Quali voci li portino, e in quale misura, resta proposta: qui l'incursione la porta l'incursore, e la cavalcatura la accresce; la tenuta di linea la porta la guardia di linea, e vale soltanto con un'armatura di linea (punti 4.1, 5.2 e 5.4).

3.6 **Il titolo.** Il titolo funzionale del combattente (modalità 7.4) è un termine intero, scelto dalla coppia di sottoclasse e mezzo: per esempio «arciere a piedi», «arciere su carro», «arciere a cavallo». Non si compone incollando la sottoclasse e il mezzo (carta 14.2). Arma e protezione si dichiarano come oggetti a parte. I nomi delle classi non sono titoli: servono a ordinare l'elenco, e se un giorno facessero da soggetto di una frase sarebbero «la classe», femminile singolare.

## 4. Fase arcaica

In questa fase la protezione pesante è rara e costosa: a piedi non esiste, e la porta soltanto chi sta su un carro (documento 01, punto 3.3.3; 04 II T6 r. 609). Quasi tutti sono leggeri. Il peso non dice più da che cosa si è coperti: i due tipi di protezione ci sono già fra i leggeri (punto 4.3), e che cosa portarsi dietro dipende da quali protezioni l'avversario ha reclutato, non da quanto pesa.

### 4.1 Classi e sottoclassi

**Classe da tiro**
- Linea: seconda. In prima linea non reagisce, e un varco fra due tiratori è libero (modalità 5.6.2).
- Peso: tiratore, reazione zero in ogni caso.
- Che cosa la distingue: poca vita; colpisce da lontano senza attraversare varchi e quindi senza pagare pedaggio.
- Fonte: 04 II T5 «L'arco composito esiste già» r. 440–446; II T6 r. 611 (cinquecentodue archi nel bottino).

Sottoclasse **arciere** — titoli «arciere a piedi» e «arciere su carro», maschile singolare
- Linea: seconda. Sul carro e con la corazza a scaglie regge anche la prima, ma senza reagire.
- Peso: tiratore. Protezione leggera; pesante soltanto sul carro.
- Che cosa lo distingue: l'attacco di tiro più alto. Costa tempo più che materia, perché l'arco richiede mesi e non si accelera con più mano d'opera; i suoi miglioramenti sono i primi a perdersi se non si mantengono.
- Fonte: 04 II T5 «Gittata dell'arco composito» r. 452–457 (circa sei mesi per un arco); II T1 r. 213 e II T6 r. 628 (il carro a due uomini porta un arciere); II T6 r. 634 e r. 640; II T2 «Spazio frontale per combattente» r. 235 (arcieri a piedi «sui fianchi o subito dietro»: ricostruzione che il 04 etichetta congetturale). Per la capacità che si perde senza esercizio: 04 III T12 r. 2701–2713, che è un dato della fase antica.

Sottoclasse **fromboliere** — titolo «fromboliere a piedi», maschile singolare
- Linea: seconda.
- Peso: tiratore. Protezione leggera.
- Che cosa lo distingue: attacco di tiro minore dell'arciere; è il combattente meno costoso di tutti, senza metallo e senza attese.
- Fonte: 04 II T5 «Fionda nella fase arcaica» r. 512–518 (l'arma è presente, con pietre e argilla; nessun piombo). Che sia l'arma più economica lo dice il 04 per la fase antica (IV.3 «La ghianda di piombo» r. 3248): per la fase arcaica è senza appoggio nel 04: scelta di progetto.

**Classe da mischia**
- Linea: prima, di norma.
- Peso: leggero o pesante secondo la protezione.
- Che cosa la distingue: esce, colpisce e torna (modalità 5.2); raggiunge la seconda linea passando dal varco; reagisce a chi attraversa un varco che fiancheggia.
- Fonte: 04 II T2 r. 234.

Sottoclasse **lanciere** — titolo «lanciere a piedi», maschile singolare
- Linea: prima.
- Peso: leggero. In questa fase a piedi non esiste protezione pesante.
- Che cosa lo distingue: vita media e l'attacco più alto fra chi sta a piedi. La sua arma perfora: è efficace contro chi è protetto dalla saturazione e poco efficace contro chi è protetto dalla perforazione, qualunque sia il peso (punto 3.4). In questa fase è l'arma giusta contro il corsaletto di cuoio, che è la protezione ordinaria (04 II T6 r. 607), e quella sbagliata contro il metallo. Il suo mestiere è anche custodire il varco: reagisce con la metà di un buon attacco, e la reazione non dipende dall'arma (sezione 7, tensione 12).
- Fonte: 04 II T2 r. 234 (fanteria leggermente protetta, a sostegno dei carri, sul terreno sfavorevole ai carri e a presidio); II T5 «Giavellotto nella fase arcaica» r. 522 (la lancia è arma da urto e non da lancio); II T1 r. 212.

Sottoclasse **incursore** — titoli «incursore a piedi» e «incursore su carro», maschile singolare
- Linea: a piedi, prima come custode del varco oppure seconda, da dove esce a colpire stando al riparo; sul carro, prima.
- Peso: leggero. Pesante soltanto sul carro con la corazza a scaglie.
- Che cosa lo distingue: meno vita del lanciere, attacco medio, e l'incursione. È la sola sottoclasse da mischia che al reclutamento sceglie fra un'arma che perfora e una che satura.
- Fonte: 04 II T6 r. 640 (fanterie armate di giavellotto, spada lunga e pochi pezzi essenziali di protezione: è uno dei due lati del disaccordo sul carro, non un fatto pacifico); II T6 r. 628 (sul carro a tre uomini il terzo è un lanciatore di giavellotto). L'incursione: senza appoggio nel 04 per questa fase: scelta di progetto.

### 4.2 Armi

«arco con frecce leggere» — maschile singolare
- Linea: si usa dalla seconda.
- Peso: chi lo porta è tiratore.
- Che cosa lo distingue: tiro; satura. Efficace contro chi non porta protezione e contro chi è protetto dalla perforazione; poco efficace contro il corsaletto di cuoio, che a distanza basta.
- Fonte: 04 II T5 «Confronto documentato fra tipi d'arma» r. 472–480; «Munizioni» r. 495–506 (le punte leggere sono quattro volte più numerose delle pesanti); per il cuoio, II T6 r. 618.

«arco con frecce pesanti» — maschile singolare
- Linea: si usa dalla seconda.
- Peso: chi lo porta è tiratore.
- Che cosa lo distingue: tiro; perfora. Meno colpi, ciascuno più pesante: è l'arma da tiro contro chi è protetto dalla saturazione, a cominciare dal corsaletto di cuoio, che da vicino protegge meno. Poco efficace contro il metallo.
- Fonte: 04 II T5 r. 475, r. 480 e r. 506 (le punte pesanti servono a perforare le protezioni); II T6 r. 617–618 (da vicino il cuoio protegge meno, e la scaglia di bronzo ferma ogni freccia). Il calcolo di 04 III T6 «Energie di penetrazione» r. 1908, secondo cui la freccia pesante da vicino passa un millimetro di bronzo, va invece contro la regola del materiale (punto 3.4); il 04 lo dichiara un ordine di grandezza e non un dato (r. 1910).

«fionda con pietre» — femminile singolare
- Linea: si usa dalla seconda.
- Peso: chi la porta è tiratore.
- Che cosa la distingue: tiro; satura; attacco minore dell'arco; non costa nulla al regno.
- Fonte: 04 II T5 r. 512–518. Che saturi e non perfori: senza appoggio nel 04: scelta di progetto.

«lancia» — femminile singolare
- Linea: prima.
- Peso: non lo cambia.
- Che cosa la distingue: corpo a corpo; perfora.
- Fonte: 04 II T5 r. 522; per l'effetto sulla protezione di metallo, 04 III T6 r. 1892–1897 (dato della fase antica: il colpo portato dall'alto non passa un millimetro di bronzo, quello portato dal basso sì). Con la regola del materiale la lancia è poco efficace contro il metallo: la prima metà del dato la appoggia, la seconda le va contro (punto 3.4).

«giavellotti» — maschile plurale
- Linea: prima o seconda.
- Peso: non lo cambiano.
- Che cosa li distingue: corpo a corpo da getto: chi li porta esce, lancia da vicino e torna (modalità 5.2), quindi reagisce secondo il peso e non è un tiratore. Perforano.
- Fonte: 04 II T6 r. 628 e r. 640 (esistenza); II T5 r. 520–522 (nessuna gittata documentata per questa fase). Che perforino è una scelta di progetto, appoggiata a due casi della fase antica in cui truppe leggere armate da getto piegano una fanteria pesante (04 III T9 r. 2249 e r. 2332); il 04 non classifica il giavellotto fra saturazione e perforazione.

«spada» — femminile singolare
- Linea: prima o seconda.
- Peso: non lo cambia.
- Che cosa la distingue: corpo a corpo; satura. È l'arma da mischia contro chi è protetto dalla perforazione e contro chi non porta protezione.
- Fonte: 04 II T6 r. 640 (esistenza della spada lunga). Che saturi: senza appoggio nel 04: scelta di progetto.

### 4.3 Equipaggiamenti

**Protezioni**

Ogni protezione dichiara due cose separate: il peso, da cui discende la reazione (punto 3.3), e il tipo, da cui discende l'accoppiamento con l'offesa (punto 3.4). Il tipo lo assegna la regola del materiale.

«senza corazza» — non è un oggetto: è l'assenza
- Linea: qualunque; di norma seconda.
- Peso: leggero.
- Tipo di protezione: nessuno. Entrambe le offese sono efficaci contro chi non porta protezione (punto 3.4; sezione 7, tensione 1).
- Che cosa la distingue: nessuna vita in più; nessun costo.
- Fonte: 04 II T2 r. 234; II T1 r. 218 (fanti leggeri e tiratori non sono nemmeno quantificati).

«corsaletto di cuoio» — maschile singolare
- Linea: qualunque.
- Peso: leggero.
- Tipo di protezione: dalla saturazione.
- Che cosa lo distingue: un poco di vita in più; nessun metallo. È la protezione ordinaria anche di chi sta sul carro.
- Fonte: 04 II T6 «La protezione normale: la corazza a scaglie» r. 556–562; r. 578 e r. 607 (duecento corsaletti di cuoio; la protezione ordinaria dei combattenti su carro è di cuoio). Per il tipo: r. 618 e VI.3 r. 3673 (il cuoio crudo protegge poco da vicino e abbastanza da lontano: regge il colpo leggero tirato da lontano e cede a quello pesante tirato da vicino, che è la distinzione stessa fra ciò che satura e ciò che perfora, 04 II T5 r. 480 e r. 506). È l'oggetto dell'elenco per cui il 04 documenta meglio entrambe le metà del tipo.

«pettorale di bronzo» — maschile singolare. Oggetto nuovo della revisione.
- Linea: qualunque; di norma prima.
- Peso: leggero.
- Tipo di protezione: dalla perforazione.
- Che cosa lo distingue: un solo pezzo spesso sul petto. La stessa vita in più del corsaletto di cuoio; un poco di metallo. È l'incrocio che la prima stesura non poteva avere: un leggero coperto da ciò che perfora.
- Fonte: 04 II T6 r. 640 (fanterie con «pochi pezzi essenziali di protezione»: è uno dei due lati del disaccordo sul carro, non un fatto pacifico, e il 04 non dice quali pezzi). L'oggetto, il suo nome e il suo tipo: senza appoggio nel 04: scelta di progetto.

«corazza a scaglie di bronzo» — femminile singolare
- Linea: prima, oppure seconda per un arciere su carro.
- Peso: pesante.
- Tipo di protezione: dalla perforazione.
- Che cosa la distingue: molta vita in più; costa molto metallo. È la protezione per cui il 04 documenta che la punta pesante tirata da vicino non passa. È ammessa soltanto a chi ha il carro.
- Fonte: 04 II T6 r. 560 (il tipo grande è destinato ai combattenti su carro) e r. 617 (ferma tutti i tipi di freccia a corta distanza); II T12 r. 911 (peso ricostruito e sedici tipi). Che ceda a ciò che satura non è nel 04, che dice anzi che ferma ogni freccia (r. 617; III T6 r. 1912): scelta di progetto. L'appiglio è che chi la porta sta su un carro, e una delle due letture del carro vuole che il tiro cercasse i cavalli (04 II T6 r. 640: linee di carri che tirano «con l'obiettivo di abbattere i cavalli avversari»).

«armatura di lamiera» — femminile singolare
- Linea: prima.
- Peso: pesante.
- Tipo di protezione: dalla perforazione.
- Che cosa la distingue: la più alta di tutta la partita, in entrambe le fasi (documento 01, punto 2.5.1). Soltanto per gli eroi.
- Fonte: 04 II T6 «La protezione estrema» r. 542–554; IV.2 r. 3146 (non si indossa da soli). Il tipo le viene dalla regola del materiale e ha qui l'appoggio più debole dell'elenco: copre dal collo alle ginocchia (r. 547), sicché «ciò che lascia scoperto» è quasi nulla: scelta di progetto (punto 7.4).

Non propongo uno scudo arcaico come oggetto: il 04 attesta gli scudi di questa fase soltanto di passaggio, nel perimetro di un campo e nello scudiero del carro, senza alcun dato (04 II T2 r. 276; II T11 r. 844; II T6 r. 628).

**Mezzo**

«carro» — maschile singolare
- Linea: qualunque.
- Peso: non lo cambia.
- Che cosa lo distingue: molta vita in più, perché chi combatte è portato e ha con sé un conducente; è il solo modo, in questa fase, di portare la protezione pesante. È l'oggetto più caro: animali, materiale da costruzione, uomini in più, mantenimento alto.
- Fonte: 04 II T2 r. 249–266; II T6 «Il carro» r. 626–644; II T12 r. 905–915 e r. 934–936; II T3 «Ritmo per tipo di unità» [R31] r. 336–342; VI.2 r. 3631 (caro tre volte).

### 4.4 Combinazioni ammesse

| Sottoclasse | Armi | Protezioni | Mezzo |
|---|---|---|---|
| arciere | arco con frecce leggere; arco con frecce pesanti | senza corazza; corsaletto di cuoio; pettorale di bronzo; con il carro anche corazza a scaglie di bronzo | nessuno; carro |
| fromboliere | fionda con pietre | senza corazza; corsaletto di cuoio | nessuno |
| lanciere | lancia | senza corazza; corsaletto di cuoio; pettorale di bronzo | nessuno |
| incursore | giavellotti; spada | senza corazza; corsaletto di cuoio; pettorale di bronzo; con il carro anche corazza a scaglie di bronzo | nessuno; carro |

Il fromboliere non porta metallo: resta il combattente che non ne costa (punto 4.1).

I due attributi della protezione, incrociati, nella fase arcaica:

| | protegge dalla saturazione | protegge dalla perforazione |
|---|---|---|
| leggero | corsaletto di cuoio | pettorale di bronzo |
| pesante | nessun oggetto in questa fase | corazza a scaglie di bronzo, soltanto sul carro; armatura di lamiera, soltanto per gli eroi |

A parte sta chi è senza corazza: leggero, senza tipo.

Ne esce che a piedi si è sempre leggeri, e che il pesante della fase arcaica è per forza un uomo sul carro oppure un eroe. Ne esce anche che è sempre un uomo coperto di metallo, e quindi protetto dalla perforazione: il pesante protetto dalla saturazione manca, e arriva nella fase antica, quando si diventa pesanti per lo scudo e non per il metallo (punto 5.4). A piedi i due tipi ci sono entrambi: scegliere fra corsaletto e pettorale è, in questa modalità, la scelta delle protezioni che si compie «in patria senza sapere che cosa si incontrerà» (documento 01, punto 3.3.2; punto 7.2).

### 4.5 Eroi

«signore del carro» — maschile singolare
- Chi è: l'alto nobile sul carro, come suggerisce il titolare. Un arciere o un incursore, con il carro e con l'armatura di lamiera.
- Linea: prima se incursore, seconda se arciere.
- Peso: pesante; tiratore se arciere.
- Tipo di protezione: dalla perforazione, come ogni protezione di metallo.
- Che cosa lo distingue: più vita e più attacco di qualunque combattente; la sola protezione di lamiera. Capacità propria, il comando per presenza: finché è in piedi, i compagni della sua stessa linea hanno un attacco un poco più alto.
- Recupero: lungo. L'appiglio è che carro e cavalli vanno rimessi in ordine: il 04 riporta che fino a quattro quinti di una forza di carri potesse trovarsi in riparazione, ma lo dichiara esso stesso valore da verificare prima dell'uso (04 II T12 r. 915).
- Fonte: 04 II T6 r. 572–589 e r. 607 (corazza di bronzo e carro lavorato in oro sono dei due comandanti supremi); II T11 r. 856 (comando per presenza); II T12 r. 907. La capacità propria: scelta di progetto ispirata a 04 II T11 r. 856.

«nobile corazzato» — maschile singolare. Proposto come secondo eroe, facoltativo.
- Chi è: l'individuo corazzato a piedi. Un lanciere con l'armatura di lamiera, senza mezzo.
- Linea: prima.
- Peso: pesante. È il solo pesante a piedi della fase.
- Tipo di protezione: dalla perforazione.
- Che cosa lo distingue: capacità propria, tiene il posto: sotto la soglia del venti per cento il suo danno non cala (deroga a modalità 6.1), e con esso non cala la sua reazione.
- Fonte: 04 II T6 r. 609 (individui corazzati) e r. 554 (se la corazza di lamiera servisse a piedi è conteso). La capacità propria: senza appoggio nel 04: scelta di progetto.

### 4.6 Ordinamenti, e la fine della fase

Dal più al meno, da tarare. Vita data dalla sottoclasse: lanciere, incursore, arciere, fromboliere. Vita data dalla protezione: armatura di lamiera, corazza a scaglie di bronzo, poi corsaletto di cuoio e pettorale di bronzo alla pari, senza corazza. Attacco: arciere e lanciere, poi incursore, poi fromboliere. Costo nel regno: carro, corazza a scaglie di bronzo, arco per il tempo che richiede, pettorale di bronzo per il poco metallo, e poi tutto il resto.

Il tipo di protezione non entra in nessun ordinamento: non c'è una protezione migliore e una peggiore (documento 01, punto 3.3.2). Per questo due protezioni dello stesso peso e di tipo opposto danno la stessa vita: se una ne desse di più, il tipo tornerebbe a essere una scala. Fra le due resta diverso il costo, perché il metallo si paga (sezione 7, tensione 14).

La cavalcatura si apre con l'acquisizione «cavalleria montata», che il documento 01 rende acquisibile già nella fase arcaica (punto 2.8.2.1): i primi combattenti a cavallo possono dunque comparire prima del passaggio di fase. Sono descritti nella sezione 5.

## 5. Fase antica

In questa fase la protezione pesante smette di essere di pochi: la si ottiene sommando elementi più leggeri, e la porta chi sta a piedi. Il massimo della protezione individuale non cresce: cala (documento 01, punto 2.5.1). Passare di fase non rende più forti: cambia chi può essere pesante, e a che prezzo. E nasce l'incrocio che alla fase arcaica mancava, il pesante protetto dalla saturazione: si diventa pesanti per lo scudo grande, e non più soltanto per il metallo (04 IV.2 r. 3148).

### 5.1 Che cosa resta e che cosa diventa obsoleto

- Restano come sono tutti i combattenti e gli eroi reclutati nella fase arcaica, con le loro armi e i loro equipaggiamenti: non si convertono e non si congedano (documento 01, punto 2.8.1; modalità 7.3).
- Restano reclutabili l'arciere a piedi, il fromboliere a piedi, il lanciere a piedi e l'incursore a piedi, con le armi del punto 4.2. L'arma individuale non cambia fra le fasi (04 III T5 «L'arma individuale non cambia» r. 1683–1689; IV.5 «Ciò che non cambia» r. 3318).
- Diventa obsoleto il carro, e con esso i due titoli «arciere su carro» e «incursore su carro» e la corazza a scaglie di bronzo, che era ammessa soltanto sul carro. Proposta: il carro resta reclutabile fino al passaggio di fase e poi non più; chi lo ha lo tiene. Il 04 dice il carro «progressivamente obsoleto nel corso della fase» (04 III T1 «Rapporto tra le armi» r. 1239) e lo dice sostituito da due cose nate in aree diverse, la cavalleria montata e la fanteria pesante in formazione (04 IV.2 r. 3124). Quando esattamente smetta di essere reclutabile è un punto aperto (sezione 7).
- L'armatura di lamiera resta agli eroi che già la portano. Nella fase antica nessuna protezione nuova la raggiunge.

### 5.2 Classi e sottoclassi nuove

**Classe guardia** — è l'élite degli sciami della fase antica, qui combattente normale
- Linea: prima.
- Peso: secondo la sottoclasse.
- Che cosa la distingue: è la classe addestrata. I suoi due tratti negli sciami, la tenuta in formazione e la versatilità con capacità di tiro (documento 01, punto 3.3), sono le sue due sottoclassi (carta 12.2).
- Fonte: 04 III T1 r. 1149 e r. 1175 (corpi scelti); III T12 «Agoge spartana ed efebia ateniese» r. 2751; III T12 r. 2827.

Sottoclasse **guardia di linea** — titolo «guardia di linea», femminile singolare
- Linea: prima; al centro copre due varchi.
- Peso: pesante.
- Tipo di protezione: quello dell'armatura di linea scelta al reclutamento, di tela oppure di bronzo (punto 5.4).
- Che cosa la distingue: molta vita e attacco alto; la tenuta di linea, decisa il 23 novembre 2026 (modalità 7.8). È la custode più salda del varco, benché reagisca con un terzo soltanto, perché quel terzo è di un attacco alto.
- Fonte: 04 III T6 «Il vantaggio della formazione serrata» r. 1918–1930; IV.2 r. 3148–3150 (ogni combattente è coperto per metà dallo scudo del vicino; quando la relazione si rompe le perdite saltano); III T8 r. 2113 (la formazione che non viene rotta subisce perdite quasi nulle); III T11 r. 2579–2587.

Sottoclasse **guardia versatile** — titolo «guardia versatile», femminile singolare
- Linea: prima o seconda.
- Peso: leggero.
- Tipo di protezione: quello della protezione leggera scelta al reclutamento, corsaletto di cuoio oppure pettorale di bronzo.
- Che cosa la distingue: porta lancia e arco, e a ogni turno colpisce da vicino oppure tira: l'armamento doppio è deciso (modalità 7.3.1). Vita media; ciascuno dei due attacchi è più basso di quello dello specialista; costa come due mestieri da mantenere. Con le due offese in mano ha sempre un'arma efficace contro chi ha davanti, qualunque protezione porti: è ciò che paga con i due attacchi più bassi. Che reagisca, perché non è un tiratore puro, è lettura della proposta e non è deciso (punto 5.3; sezione 7, tensione 2; modalità 11.11).
- Fonte: 04 III T1 r. 1175 (corpo scelto mantenuto a pieno organico); III T2 r. 1289 (portascudo con lancia corta davanti agli arcieri); III T5 r. 1691–1693 (punte leggerissime: uno stile di tiro a saturazione).

**Classe da mischia**, sottoclasse nuova

Sottoclasse **portatore di scudo** — titolo «portatore di scudo», maschile singolare
- Linea: prima.
- Peso: pesante, per l'ingombro dello scudo e non per il metallo.
- Tipo di protezione: dalla saturazione, sempre: porta soltanto lo scudo da riparo.
- Che cosa lo distingue: molta vita, attacco basso. Il suo scudo regge il tiro leggero e numeroso e cede a ciò che perfora. Tiene il varco difeso, così che il tiro avversario non passi alla seconda linea (modalità 5.8); ma la sua reazione, un terzo di un attacco basso, non ferma un'incursione. È il pesante a buon mercato.
- Fonte: 04 III T1 r. 1185–1190; III T2 r. 1289; III T6 r. 1940 («scudi grandi ma sottili»).

Il **lanciere a piedi** può ora portare l'una o l'altra delle due protezioni pesanti nuove, l'armatura di linea in tela e quella in bronzo: è il fante pesante ordinario, non addestrato, accanto alla guardia che lo è (04 III T12 r. 2743–2745).

**Titoli nuovi di sottoclassi già esistenti**, con la cavalcatura

«arciere a cavallo» — maschile singolare
- Linea: seconda.
- Peso: tiratore. Protezione leggera.
- Che cosa lo distingue: come l'arciere, con più vita e più costo.
- Fonte: 04 III T6 «La protezione a scaglie, ora misurabile» r. 1827 (una corazza leggera fatta apposta per il cavaliere arciere); III T6 «La cavalleria contro la fanteria» r. 1956 (arma da tiro montata); III T1 r. 1190.

«incursore a cavallo» — maschile singolare
- Linea: seconda, da dove esce quando un varco si apre.
- Peso: leggero. A cavallo non esiste protezione pesante.
- Che cosa lo distingue: l'incursione più alta di tutte e un attacco di fronte modesto. Paga il pedaggio come chiunque: contro una prima linea intatta non conviene mandarlo, contro un varco rimasto con un solo custode o con nessuno è il più pericoloso.
- Fonte: 04 III T6 r. 1944–1956 (non rompe di fronte la fanteria che tiene la formazione; è micidiale contro quella «disordinata, in fuga, o colta di fianco»); III T9 «I reparti di copertura e chi conduce l'inseguimento» r. 2332; IV.5 r. 3322.

### 5.3 Armi nuove

«fionda con piombo» — femminile singolare. Si apre con l'acquisizione «fionda con proiettile di piombo».
- Linea: si usa dalla seconda.
- Peso: chi la porta è tiratore.
- Che cosa la distingue: tiro; perfora; attacco maggiore della fionda con pietre. Dà al tiratore più povero un'arma contro chi è protetto dalla saturazione: il cuoio, la tela, lo scudo da riparo.
- Fonte: 04 III T5 «I confronti diretti di Senofonte» r. 1702–1713 (il piombo raddoppia la resa della fionda e la porta oltre l'arco); «Munizioni da fionda: la ghianda di piombo» r. 1758; IV.3 r. 3246–3248. Il 04 documenta un raddoppio di gittata; in questa modalità le distanze non esistono (carta 12.4), quindi che il piombo dia l'offesa che perfora è una scelta di progetto.

«lancia e arco» — maschile plurale. Armamento doppio, per la sola guardia versatile: deciso dal titolare il 23 novembre 2026 (modalità 7.3.1).
- Linea: prima o seconda.
- Peso: non lo cambia. Che chi lo porta non sia un tiratore, e quindi reagisca secondo il peso, è lettura della proposta: la decisione nomina l'armamento e non lo dice (modalità 11.11; sezione 7, tensione 2).
- Che cosa lo distingue: due attacchi, uno a turno: la lancia da vicino, che perfora, e l'arco con frecce leggere da lontano, che satura. Nessuna scelta di munizione: ciascuno dei due ha la sua offesa fissa (documento 01, punto 3.3.1). Quale offesa abbia ciascuno dei due attacchi resta proposta, come ogni altra arma dell'elenco.
- Fonte: documento 01, punto 3.3; 04 III T2 r. 1289. La regola di chi tira e combatte insieme non è nel documento della modalità: sezione 7.

### 5.4 Equipaggiamenti nuovi

**Protezioni**, aperte dall'acquisizione «protezione diffusa e alleggerita»

Come nella fase arcaica, ogni protezione dichiara il peso e il tipo, e il tipo lo assegna la regola del materiale (punto 3.4). L'armatura di linea della prima stesura è ora due oggetti, uguali per peso e opposti per tipo: è il confronto fra il lino e il bronzo, che la memoria delle decisioni dà per assorbito dai due tipi di protezione (`Fondamenta/decisioni-fase-2.md`, voce PRO-07). La prima stesura non lo proponeva perché, con il tipo letto nel peso, sarebbe stato una differenza di sola vita e di solo costo.

«armatura di linea in tela» — femminile singolare
- Linea: prima.
- Peso: pesante.
- Tipo di protezione: dalla saturazione.
- Che cosa la distingue: scudo grande, corazza di tela a strati, elmo e schinieri. Dà meno vita della corazza a scaglie di bronzo e della lamiera, e costa poco metallo: è la protezione pesante alla portata di chi sta a piedi. Senza un'armatura di linea la tenuta di linea non vale. Dico «tela» e non «lino» perché all'ascolto «lino» si confonde con «linea».
- Fonte: 04 III T6 «Il peso della panoplia oplitica» r. 1847–1861; «Il lino: la protezione che compete con il bronzo» r. 1865–1880 (la freccia tirata da quindici metri si ferma negli strati esterni; una fonte antica dice la corazza di lino penetrabile da colpi potenti; alcuni ritengono la ricostruzione sovradimensionata); III T12 «Costo della panoplia oplitica» r. 2656–2664 (il corredo essenziale vale un mese di salario di un artigiano); IV.2 r. 3148.

«armatura di linea in bronzo» — femminile singolare
- Linea: prima.
- Peso: pesante.
- Tipo di protezione: dalla perforazione.
- Che cosa la distingue: lo stesso corredo, con la corazza di bronzo al posto di quella di tela. La stessa vita dell'altra; molto più metallo, perché la corazza è il pezzo più caro del corredo. Anche con questa la tenuta di linea vale.
- Fonte: 04 III T6 r. 1847–1861; r. 1897 (un millimetro di bronzo ferma il colpo di lancia portato dall'alto, non quello portato dal basso); III T12 r. 2668 (il pezzo più caro). Che la scelta fra le due corazze sia esistita è documentato: per due secoli molti continuarono a scegliere il bronzo (r. 1882). Ma la ragione che il 04 riporta non appoggia il tipo: dal bronzo si sarebbe cercato qualcosa di diverso dalla resistenza ai colpi, cioè la resistenza alla compressione della mischia serrata. E che il bronzo ceda a ciò che satura non è nel 04, che dice il contrario per tre percorsi indipendenti (r. 1912). Il tipo di questo oggetto è quindi scelta di progetto. Sul peso il 04 dà due misure che non concordano: nella tabella dei pesi le due corazze pesano quasi lo stesso (r. 1851–1854), nel progetto sperimentale quella di lino pesa un terzo di quella di bronzo (r. 1874). In entrambi i casi il corredo resta pesante per lo scudo, che da solo pesa quanto la corazza o più (r. 1856–1857).

«scudo da riparo» — maschile singolare
- Linea: prima.
- Peso: pesante.
- Tipo di protezione: dalla saturazione.
- Che cosa lo distingue: grande e sottile, senza metallo. Molta vita. Lo porta soltanto il portatore di scudo.
- Fonte: 04 III T6 r. 1940 (scudi «grandi ma sottili», per riparare dal tiro); III T2 r. 1289.

Il «corsaletto di cuoio» e il «pettorale di bronzo» della fase arcaica restano, e sono le due protezioni leggere anche di questa fase: nella fase antica una corazza a scaglie di cuoio pesa un quarto della lamiera e si indossa da soli (04 III T6 r. 1817–1831).

**Mezzo**, aperto dall'acquisizione «cavalleria montata»

«cavalcatura» — femminile singolare
- Linea: seconda.
- Peso: non lo cambia.
- Che cosa la distingue: meno vita in più del carro; accresce l'incursione; non ammette protezione pesante. Costa animali e un mantenimento alto.
- Fonte: 04 III T12 «Cavalleria» r. 2672–2697 (il cavaliere costa circa dieci volte il fante pesante; il solo grano del cavallo poteva costare più della paga); III T6 r. 1948 (niente staffe, niente lancia in resta, niente bardatura). Che la cavalcatura non sia protetta segue r. 1948; un'altra riga del 04 parla invece di cavalli corazzati (III T1 r. 1238): non ho potuto conciliare le due.

### 5.5 Combinazioni ammesse nella fase antica

| Sottoclasse | Armi | Protezioni | Mezzo |
|---|---|---|---|
| arciere | arco con frecce leggere; arco con frecce pesanti | senza corazza; corsaletto di cuoio; pettorale di bronzo | nessuno; cavalcatura |
| fromboliere | fionda con pietre; fionda con piombo | senza corazza; corsaletto di cuoio | nessuno |
| lanciere | lancia | senza corazza; corsaletto di cuoio; pettorale di bronzo; armatura di linea in tela; armatura di linea in bronzo | nessuno |
| incursore | giavellotti; spada | senza corazza; corsaletto di cuoio; pettorale di bronzo | nessuno; cavalcatura |
| portatore di scudo | lancia | scudo da riparo | nessuno |
| guardia di linea | lancia | armatura di linea in tela; armatura di linea in bronzo | nessuno |
| guardia versatile | lancia e arco | corsaletto di cuoio; pettorale di bronzo | nessuno |

I due attributi della protezione, incrociati, nella fase antica:

| | protegge dalla saturazione | protegge dalla perforazione |
|---|---|---|
| leggero | corsaletto di cuoio | pettorale di bronzo |
| pesante | armatura di linea in tela; scudo da riparo | armatura di linea in bronzo |

A parte sta chi è senza corazza: leggero, senza tipo. Restano a chi già li porta la corazza a scaglie di bronzo e l'armatura di lamiera della fase arcaica (punto 5.1).

Ne esce che il pesante della fase antica è per forza un uomo a piedi nella prima linea, e che chi ha un mezzo è sempre leggero: il rovescio della fase arcaica. Ne esce anche che i quattro incroci ci sono tutti, e che il tipo di protezione si sceglie al reclutamento senza che il peso lo decida: per ogni sottoclasse, salvo il portatore di scudo e il fromboliere, che non portano metallo.

### 5.6 Eroi

«capo di linea» — maschile singolare
- Chi è: una guardia di linea, con lancia e una delle due armature di linea.
- Linea: prima.
- Peso: pesante.
- Tipo di protezione: quello dell'armatura con cui entra nell'organico, che non si sceglie: un eroe arriva già equipaggiato (punto 6.5).
- Che cosa lo distingue: più vita e più attacco di una guardia. Capacità propria, la linea salda: finché è in piedi e la prima linea è al completo, i compagni della prima linea subiscono più di rado un colpo critico. Quando la linea si rompe la capacità cade.
- Fonte: 04 III T11 r. 2579–2587 (ufficiali sotto altri ufficiali; capifila che comandano gli uomini dietro di loro); III T8 r. 2113 e VI.3 r. 3651 (perdite quasi nulle finché la formazione tiene). La capacità propria: scelta di progetto ispirata a queste righe.

«comandante della riserva» — maschile singolare
- Chi è: un incursore a cavallo.
- Linea: comincia lo scontro fuori dalle linee.
- Peso: leggero.
- Tipo di protezione: quello della protezione leggera con cui entra nell'organico.
- Che cosa lo distingue: capacità propria, la riserva: entra a occupare un posto rimasto libero senza che nessuno spenda il turno (deroga a modalità 5.9). È il solo modo di far entrare qualcuno a scontro cominciato.
- Fonte: 04 III T11 «La riserva: la vera risposta al problema del comando» r. 2633–2648 («la riserva non è un rinforzo: è un dispositivo di comando»; il comandante che si sgancia dopo aver caricato di persona); IV.3 «La riserva» r. 3262–3266. Il 04 colloca la riserva nell'ultimo secolo della fase (04 III T11 r. 2633): se lo si vuole rispettare, questo eroe si incontra soltanto dopo l'acquisizione «catena di comando articolata».

### 5.7 Riepilogo dei titoli

| Titolo | Genere e numero | Fase in cui si recluta | Linea | Reazione |
|---|---|---|---|---|
| arciere a piedi | maschile singolare | arcaica e antica | seconda | tiratore |
| arciere su carro | maschile singolare | arcaica | seconda | tiratore |
| arciere a cavallo | maschile singolare | dopo «cavalleria montata» | seconda | tiratore |
| fromboliere a piedi | maschile singolare | arcaica e antica | seconda | tiratore |
| lanciere a piedi | maschile singolare | arcaica e antica | prima | leggero; pesante con un'armatura di linea |
| incursore a piedi | maschile singolare | arcaica e antica | prima o seconda | leggero |
| incursore su carro | maschile singolare | arcaica | prima | leggero; pesante con la corazza a scaglie |
| incursore a cavallo | maschile singolare | dopo «cavalleria montata» | seconda | leggero |
| portatore di scudo | maschile singolare | antica | prima | pesante |
| guardia di linea | femminile singolare | antica | prima | pesante |
| guardia versatile | femminile singolare | antica | prima o seconda | leggero |
| signore del carro (eroe) | maschile singolare | arcaica | prima o seconda | pesante, o tiratore |
| nobile corazzato (eroe, facoltativo) | maschile singolare | arcaica | prima | pesante |
| capo di linea (eroe) | maschile singolare | antica | prima | pesante |
| comandante della riserva (eroe) | maschile singolare | antica | entra a scontro cominciato | leggero |

La tabella non ha una colonna per il tipo di protezione, e non può averla: il tipo non discende dal titolo ma dalla protezione scelta al reclutamento (punti 4.4 e 5.5). La sola eccezione è il portatore di scudo, che porta soltanto lo scudo da riparo ed è sempre protetto dalla saturazione. La colonna della reazione resta quella che era, perché il peso continua a discendere dalla protezione (punto 3.3).

I titoli usano due dei quattro generi; le frasi che li contengono vanno comunque scritte per tutti e quattro (documento 02, punto 4.6). Fra gli oggetti, «giavellotti» e «lancia e arco» sono maschile plurale; nessun termine proposto è femminile plurale. I tre oggetti nuovi della revisione sono «pettorale di bronzo», maschile singolare, e «armatura di linea in tela» e «armatura di linea in bronzo», femminile singolare.

## 6. Le voci del regno per reclutare e migliorare combattenti ed eroi

Il regno è lo stesso della modalità a sciami: cinque risorse, inverno, acquisizioni (modalità 1.3 e sezione 8). Cambiano soltanto le voci militari. Dove gli sciami hanno reparti e assetti, qui ci sono le voci che seguono; il posto degli assetti lo prende l'organico, cioè chi si tiene, chi si schiera e su quale fronte (modalità 2.3 e 8.4). Sono voci e relazioni, senza alcun costo.

### 6.1 Reclutare un combattente

Si scelgono sottoclasse, arma, protezione e mezzo fra le combinazioni ammesse, e restano quelli per sempre (modalità 7.3). Con la protezione si scelgono insieme, e una volta sola, il peso e il tipo di protezione (punti 3.3 e 3.4). L'avvio del reclutamento è una delle tre voci acquistabili fuori dall'inverno, con arrivo differito (documento 01, punto 5.5.1.4.1); l'addestramento è d'inverno (documento 01, punto 4.13).

- *Uomini.* Li consuma ogni reclutamento; di più il carro, che vuole un conducente, e chi ha un seguito. Il 04 documenta che si pagano le bocche e non le lance: il carro è contato come due uomini armati, il fante pesante è pagato per sé e per il servitore (04 II T12 r. 934; III T12 «Costo di una campagna» r. 2855; VI.5 r. 3715). Il documento 01 incorpora già il seguito nel costo (punto 3.4.5).
- *Denaro.* Paga la formazione iniziale e il mantenimento (documento 01, punto 5.5.1).
- *Metalli.* Li consuma la protezione di metallo, pesante o leggera che sia: moltissimi la corazza a scaglie di bronzo, molti l'armatura di linea in bronzo, pochi il pettorale di bronzo e l'armatura di linea in tela, nessuno lo scudo da riparo e il corsaletto di cuoio. Pochi le armi. Il documento 01 li dice il collo di bottiglia che distingue un esercito pesante da uno leggero (punto 5.5.1): con la regola del materiale distinguono piuttosto chi è protetto dalla perforazione da chi non lo è (sezione 7, tensione 14). Fonte: 04 II T12 «Metallo, cuoio e legname» r. 940–946 (la lega da guerra è cara perché il suo metallo raro viene da lontano); III T12 r. 2668.
- *Animali.* Li consuma il mezzo: la pariglia del carro con qualche capo di riserva, il cavallo della cavalcatura. Sono contesi con gli altri impieghi del regno (documento 01, punto 5.5.1.2). Fonte: 04 II T6 r. 599 e r. 632; II T12 «Il tariffario delle Leggi ittite» r. 886–887; III T12 r. 2687.
- *Materiale da costruzione.* Lo consuma il carro, che è un veicolo di legno. È una scelta di progetto per dare a questa risorsa una voce militare anche qui: il 04 dice soltanto che legname e stagionatura di casse e ruote non sono quantificati (04 II T12 r. 950).
- *Tempo.* L'arciere arriva più tardi degli altri, perché l'arco richiede mesi e non si accelera (04 II T5 r. 456; III T12 r. 2701–2703). Il gioco dichiara quando il lavoro sarà pronto, non quanto dura (documento 01, punto 5.9.1.4).

### 6.2 Migliorare la persona: l'ottanta per cento (modalità 8.2)

- *Addestramento*: alza l'attacco.
- *Resistenza*: alza la vita.
- *Percentuali*: muovono il critico.

Si comprano d'inverno, con il denaro, per un combattente alla volta, fino al tetto di quel combattente (modalità 8.3). Non sono permanenti: si perdono se non mantenuti, e mantenerli costa poco (documento 01, punto 4.14). Proposta: i miglioramenti dei tiratori si perdono per primi, perché il tiro è la capacità che il 04 documenta come deperibile (04 III T12 r. 2711; VI.5 r. 3711); e il mantenimento è più alto per chi ha un mezzo, perché gli animali mangiano tutto l'anno (04 III T12 r. 2697). Se oltre ai miglioramenti si mantenga anche il combattente in sé era una domanda aperta per il regno intero (`Proposte/domande-per-il-titolare-sul-regno.md`, domanda 5), e la proposta regge con l'una e con l'altra risposta. Il titolare ha risposto il 23 novembre 2026, nei termini della modalità a sciami: ogni reparto paga una quota annua piccola, e i miglioramenti sono voci a parte, che si perdono se non si pagano mentre il reparto resta. Quale sia qui l'unità che paga la quota non è scritto: per analogia sarebbe il combattente.

### 6.3 Migliorare l'istituzione: il venti per cento (modalità 8.2)

- *Livello di partenza dei reclutati.* Chi arriva dopo parte più vicino ai veterani. L'appiglio indiretto è il solo rapporto documentato sul costo di un addestramento, che riguarda un artigiano e non un combattente: addestrare costa i sei decimi di comprare già formato (04 II T12 r. 964; VI.5 r. 3717).
- *Velocità di guarigione.* Gli infortuni tengono fuori per meno scontri (modalità 6.2). Il 04 non ha dati sui feriti (III T8 r. 2129–2131): la voce è senza appoggio nel 04: scelta di progetto. Un appiglio per legarla a un'acquisizione c'è: fra le funzioni del campo fortificato di marcia sta il ricovero dei feriti (04 VI.4 r. 3697).

### 6.4 Le acquisizioni, e che cosa aprono qui

Le acquisizioni sono quelle del documento 01, punto 2.8.2.1, nei loro cinque ambiti. Fra parentesi la fase in cui il documento 01 le rende acquisibili.

Armi e protezioni
- *Ferro come materiale ordinario* (arcaica). Non rende più forte nessuna arma: il 04 dice che, se la posizione oggi prevalente fra gli studiosi è corretta, «il passaggio di fase non dovrebbe conferire un bonus di efficacia alle armi» (04 IV.7 «Il ferro fu decisivo in battaglia?» r. 3439; IV.2 «Il ferro» r. 3228–3230). Sposta il costo: armi e protezioni di metallo chiedono meno metalli e più denaro (04 VI.5 r. 3707).
- *Protezione diffusa e alleggerita* (antica). Apre le due armature di linea e lo scudo da riparo, e con essi la classe guardia, il portatore di scudo e la tenuta di linea.
- *Fionda con proiettile di piombo* (antica). Apre la fionda con piombo.

Montature e macchine
- *Cavalleria montata* (arcaica). Apre la cavalcatura e i due titoli a cavallo. Avvia l'obsolescenza del carro (punto 5.1).
- *Sistema d'assedio integrato*; *macchina da tiro a tensione e poi a torsione* (antica). In questa modalità non aprono nulla: le voci militari sono combattenti ed eroi (modalità 1.3). È una tensione, ripresa nella sezione 7.

Comando e trasmissione
- *Rete di stazioni e staffette* (arcaica). Può toccare la distribuzione dei campioni fra fronti e campagne (modalità 2.3), che è un punto aperto (modalità 11.7).
- *Segnali codificati* (antica). Nessuna voce propria in questa proposta.
- *Catena di comando articolata* (antica). Può essere la condizione per incontrare l'eroe «comandante della riserva» (punto 5.6).

Logistica e vie
- *Carico animale migliorato* (arcaica); *macinatura in marcia* (antica). In questa modalità non c'è logistica dei rifornimenti (modalità 2.2): non aprono nulla.
- *Fortificazione mobile da campo* (antica). Può alzare la velocità di guarigione (punto 6.3).

Economia militare
- *Corpo permanente mantenuto* (arcaica). Proposta: allarga l'organico che si può tenere (modalità 8.4) oppure rende meno caro mantenere i miglioramenti. Il 04 documenta sia il corpo permanente sia come finì quello degli arcieri, sciolto per bilancio e non per una sconfitta (04 III T12 r. 2715–2726 e r. 2827–2833; VI.1 r. 3619).
- *Moneta coniata* (antica). Nessuna voce propria in questa proposta: vale l'effetto comune alle due modalità (documento 01, punto 5.5.1.3).
- *Addestramento istituzionale* (antica). Alza il livello di partenza dei reclutati. Il 04 lo colloca alla fine estrema della fase (04 III T12 r. 2755–2759), come il documento 01, che ne fa l'ultima acquisizione del suo ambito.

### 6.5 Gli eroi: come si ottengono e come si recuperano

- *Come si ottiene.* Sconfiggendo un comandante nemico di rilievo (modalità 7.7). Proposta: la vittoria fa entrare nell'organico un eroe nuovo, già armato ed equipaggiato, del tipo proprio della fase. Il 04 dà l'immagine: il carro e la corazza del comandante vinto sono voci del bottino (04 II T6 r. 576–584), e nella fase antica al comandante spetta una quota abbondante delle spoglie (04 III T12 «Bottino, premi e coniazione» r. 2841). Non propongo il bottino come voce di bilancio: è già stato escluso (`Fondamenta/decisioni-fase-2.md`, voce ECO-09).
- *Che cosa non propongo.* Elevare a eroe un veterano consegnandogli le armi del vinto: sarebbe un cambio di equipaggiamento, che è scartato (modalità 7.3 e 9.1). Resta possibile, e lo lascio aperto, elevare un veterano senza cambiargli nulla, soltanto alzando il suo tetto: si legherebbe al registro delle imprese e a ciò che un veterano lascia morendo (modalità 7.5 e 7.6).
- *Come si recupera.* Dopo l'impiego l'eroe resta fuori per un numero di scontri (modalità 7.7). Proposta: una voce dell'istituzione accorcia il recupero, la stessa della guarigione oppure una propria; l'eroe sul carro recupera più lentamente degli altri (punto 4.5).
- *Il tetto.* L'eroe ha un tetto ai miglioramenti più alto di quello dei combattenti (modalità 7.7 e 8.3).

### 6.6 Ciò che il 04 offrirebbe e che non propongo, perché già escluso

La fornitura degli equipaggiamenti da un magazzino del palazzo, il prestito rotativo per l'animale, i mercenari a denaro, il costo del combattente che oscilla con la congiuntura: sono nel 04 (II T12 r. 936; III T12 r. 2691 e r. 2805–2809; VI.5 r. 3713–3721) e sono già esclusi (`Fondamenta/decisioni-fase-2.md`, voci ECO-12, ECO-13, ECO-11, ECO-08).

### 6.7 Come queste voci entrano nel regno che esiste (aggiunto dalla sessione)

La prima tappa del regno, costruita nell'incarico 30 per la sola modalità a sciami, tiene già separato ciò che è comune da ciò che è della modalità (`Proposte/piano-del-regno.md`, punto 2.4; RDA-166). Per la modalità a campioni ne discende, senza rifare nulla:

- *Le forze.* Il regno conserva oggi formazioni di reparti; nella modalità a campioni conserverà l'organico: per ciascun combattente l'identificativo, il titolo, la sottoclasse, l'arma, la protezione, il mezzo, i miglioramenti con il loro stato di mantenimento, l'infortunio e gli scontri che mancano al rientro; per gli eroi anche il recupero. È un caso in più della stessa forma (`ForzeDelRegno`), non un regno diverso.
- *I ganci d'effetto.* Una voce del regno dichiara costo, momento in cui è pronta e un gancio: oggi «recluta un reparto». Qui servono tre ganci, uno per ciascuna delle voci dei punti 6.1–6.3: recluta un combattente (con le quattro scelte del punto 6.1), migliora la persona, migliora l'istituzione. Le acquisizioni restano quelle comuni.
- *Il costo.* La formula del regno è una sola: per ogni risorsa, la misura di ciò che la voce dà, per la base della risorsa, per il peso della voce. Il costo di un combattente si ottiene sommando i pesi dei suoi quattro oggetti — sottoclasse, arma, protezione, mezzo —, risorsa per risorsa: la protezione di metallo porta il peso sui metalli, il mezzo sugli animali e sul materiale da costruzione. Qui «peso» è il coefficiente di costo della voce nel regno, non il peso del combattente del punto 3.3: sono due cose diverse con lo stesso nome, e va tenuto presente quando la modalità si costruisce. Il tempo dell'arco non è un costo: è il momento in cui il combattente è pronto. Non serve una tabella dei profili (carta 13.3), e ogni voce dell'elenco dichiara il proprio contributo una volta sola.
- *Il momento.* Nella prima tappa tutto ciò che si ordina d'inverno è pronto in primavera. L'arciere che «arriva più tardi» (punto 6.1) chiede le durate e gli arrivi differiti, che sono la seconda tappa del piano.
- *Ciò che la campagna riporta.* Oggi rientrano le formazioni con le perdite subite. Qui rientrerà l'organico con infortuni e recuperi; i caduti non rientrano.

## 7. Punti aperti e tensioni

### 7.1 Perché l'elenco non dà una soluzione unica (modalità 10.5)

La reazione è una frazione dell'attacco e non del solo peso: un portatore di scudo e una guardia di linea sono entrambi pesanti e custodiscono il varco in modo opposto, e un incursore leggero reagisce con la metà di un attacco soltanto medio. E chi sta al centro copre due varchi: è il posto dove l'avversario manderà l'offesa a cui quel combattente è esposto, e caduto lui si aprono a metà tutti e due i varchi (modalità 5.6.2).

Con il tipo di protezione separato dal peso l'argomento ha un grado di libertà in più. Due prime linee uguali per peso, e quindi per reazione, possono essere coperte l'una da ciò che satura e l'altra da ciò che perfora, o esserlo a metà; e una prima linea tutta dello stesso tipo è letta in anticipo dall'avversario, che manda l'offesa giusta. Poiché le armi e le protezioni dell'avversario si conoscono prima (modalità 3.1) e le proprie non si cambiano (modalità 7.3), né «pesanti ai lati e leggero al centro» né una linea tutta di un tipo è lo schieramento giusto contro ogni avversario. Il rovescio va guardato: se un tipo costa metallo e l'altro no (tensione 14), l'organico povero è tutto dello stesso tipo, e allora la soluzione unica potrebbe tornare dalla parte di chi attacca.

È un argomento e non una misura: va verificato con il programma, come il punto 10.5 chiede.

### 7.2 Punti aperti del documento della modalità che la proposta tocca

- *11.2, i fatti del registro delle imprese.* La proposta non ne dipende, salvo l'ipotesi lasciata aperta del veterano elevato (punto 6.5).
- *11.3, i numeri dell'organico e degli infortuni.* Li tocca in due modi: il carro e la cavalcatura consumano più uomini di un combattente a piedi, e l'acquisizione «corpo permanente mantenuto» potrebbe allargare l'organico.
- *11.5, la scala del critico sotto il quaranta per cento.* Non toccata. La capacità del «capo di linea» e quella del «nobile corazzato» lavorano però su critico e soglia, e andranno scritte insieme a quella scala.
- *11.6, i gradi del linguaggio della probabilità.* La proposta tiene le percentuali fuori dalle voci dell'elenco proprio per non allargare il bisogno di gradi. La capacità del «capo di linea» muove una probabilità e va annunciata con quei termini.
- *11.7, la giornata di un fronte e la distribuzione dei campioni.* Toccata soltanto dall'acquisizione «rete di stazioni e staffette».
- *11.8, la tensione con il punto 3.3.2 del documento 01.* Un'osservazione, non una decisione. Con il tipo di protezione separato dal peso la frase del documento 01 si applica a questa modalità quasi alla lettera: il tipo si sceglie al reclutamento, in patria, e resta quello (modalità 7.3). Cambia il momento in cui la scelta è premiata o punita. Lo schieramento si sceglie sapendo chi si ha di fronte (modalità 3.1); ma si può schierare soltanto chi si è reclutato, e quanti coperti dall'una e quanti dall'altra offesa reclutare si decide molto prima, senza sapere contro chi serviranno. La scelta «senza sapere» si sposta quindi dal singolo scontro all'organico. La decisione del 23 novembre non scioglie la tensione, che resta un punto aperto.
- *11.10, meteo e guasti.* Non toccato e non deciso. Segnalo soltanto che il carro è il solo oggetto della proposta a cui un guasto potrebbe applicarsi.
- *11.11, chi è un tiratore con l'armamento doppio.* Punto aperto nuovo della versione 1.3, nato dalla decisione sulla C: è la tensione 2 qui sotto.
- *11.12, i termini del peso e del tipo di protezione.* Punto aperto nuovo della versione 1.3, nato dalla decisione sulla A: è la tensione 10 qui sotto.

### 7.3 Tensioni trovate

1. *Due protezioni opposte contro una scala di protezioni.* Il documento 01 (punto 3.3.2) vuole due protezioni opposte, nessuna migliore. Il 04 documenta invece una scala e una soglia di distanza: il metallo ferma tutto da vicino, il cuoio protegge poco da vicino e abbastanza da lontano (04 VI.3 r. 3673). Negli sciami la tensione non si vede, perché la protezione è un'etichetta. Qui la protezione è un oggetto con un nome, e si vede. La proposta A la scioglieva mettendo l'opposizione nel peso, ed è respinta. La proposta rivista mette la differenza di qualità nella vita, come prima, e l'opposizione nel tipo, assegnato dal materiale (punto 3.4). Restano tre cose senza appoggio, e sono il prezzo che la prima stesura annunciava per questa via. (a) Che il metallo ceda a ciò che satura, contro 04 III T6 r. 1912. (b) Il «pettorale di bronzo», oggetto senza riscontro, che serve a dare un leggero protetto dalla perforazione (punto 4.3). (c) La condizione di chi non porta protezione, che non ha tipo ed è esposto a entrambe le offese: negli sciami non esiste. Per (c) l'alternativa è togliere «senza corazza» dall'elenco e dare a ogni combattente almeno la protezione più povera. Per l'insieme l'alternativa è fare del tipo un'etichetta scelta al reclutamento e slegata dall'oggetto, com'è di fatto negli sciami: nessun oggetto nuovo e nessuna regola del materiale, ma un corsaletto di cuoio che protegge dalla perforazione direbbe il contrario di ciò che il 04 riporta del cuoio (r. 618), e il tipo andrebbe dichiarato con un termine suo per ogni combattente (tensione 10). Come il tipo arrivi agli oggetti è, dopo la decisione, la scelta più importante da confermare.
2. *Chi è un tiratore.* Il documento della modalità dà reazione zero ai tiratori (5.6), ma non dice chi lo sia quando un combattente tira e combatte insieme. La decisione del 23 novembre copre espressamente una cosa sola: l'armamento doppio di lancia e arco esiste, per la guardia versatile (modalità 7.3.1). Non dice se chi lo porta reagisca, e il documento della modalità lo tiene come punto aperto (11.11). Resta quindi lettura della proposta, non decisa, tutto il resto: che sia tiratore chi ha soltanto un'arma da tiro; che chi porta lancia e arco reagisca secondo il peso; che i giavellotti siano corpo a corpo da getto e non tiro. La lettura opposta, che chiunque tiri abbia reazione zero, è altrettanto sostenibile anche dopo la decisione: toglierebbe alla guardia versatile la reazione e la renderebbe un varco aperto in prima linea, sicché l'armamento doppio varrebbe davvero soltanto dalla seconda. Il carro non solleva il problema: nella proposta chi sta sul carro o tira o lancia da vicino, e mai le due cose.
3. *Il pedaggio non si modifica.* La reazione «non subisce altri modificatori» (modalità 5.6). Carro e cavalcatura non possono quindi tradursi in un pedaggio ridotto, che sarebbe stata la traduzione più ovvia della mobilità. Per questo la mobilità è resa con l'incursione, che agisce sul colpo e non sul pedaggio. L'incursione è ora decisa, in questa forma (modalità 7.8).
4. *Un tiratore pesante non paga il suo peso.* Chi tira ha reazione zero comunque: per lui la protezione pesante ha soltanto vantaggi, salvo il costo. Con la proposta A c'era almeno l'esposizione a ciò che perfora a fare da contrappeso; separato il tipo dal peso, non c'è più. La proposta lo contiene ammettendo il tiratore pesante soltanto sul carro, cioè a un costo altissimo, e con un tipo solo: la corazza a scaglie di bronzo protegge dalla perforazione, sicché l'arciere pesante è esposto proprio al tiro che satura, che è l'arma più comune dei suoi pari. Va verificato in taratura.
5. *Le munizioni illimitate e l'assenza di distanze.* Tutto ciò che il 04 documenta sulle armi da tiro è gittata e dotazione: la graduatoria delle gittate, il raddoppio del piombo, la faretra che dura tre minuti, le munizioni da fionda che si fabbricano in campagna e quelle da arco no (04 III T5 r. 1709–1713 e r. 1754). Nessuna di queste differenze ha posto in una modalità senza distanze (carta 12.4) e con munizioni illimitate (modalità 5.8). Le armi da tiro si distinguono quindi soltanto per offesa, attacco e costo, e l'acquisizione del piombo ha dovuto ricevere un significato che il 04 non le dà.
6. *Acquisizioni senza voce.* Con il regno identico nelle due modalità, alcune acquisizioni non aprono nulla in questa (punto 6.4): quelle sulle macchine, cioè il sistema d'assedio e la macchina da tiro; due della logistica, il carico animale e la macinatura; i segnali; la moneta. Contano però per la soglia distribuita e per i tetti d'epoca (documento 01, punti 2.6.2 e 2.6.2.1): il giocatore potrebbe doverle acquisire senza riceverne nulla sul campo. Va deciso se dare loro un effetto, e quale.
7. *La risorsa uomini.* Un campione è un uomo; il regno conta gli uomini per un esercito. Se un combattente costa un uomo, la risorsa che è «il limite del reclutamento» (documento 01, punto 5.5.1) qui non limita nulla. Va deciso che cosa costa in uomini un campione. Un appiglio nel 04 c'è: l'élite è una quota piccola di una popolazione (04 II T1 r. 216), quindi un campione potrebbe costare la selezione, cioè molti uomini per uno scelto.
8. *Il formato a due contro due.* Senza linee non ci sono varchi (modalità 5.3): peso come reazione, incursione, tenuta di linea e portatore di scudo non hanno oggetto. Nel primo formato il peso non dice quindi nulla: da che cosa si è coperti lo dice il tipo di protezione, che vale in ogni formato. Ne seguono due cose. Finché si gioca due contro due, fra un corsaletto di cuoio e un'armatura di linea in tela la differenza è soltanto di vita e di costo. E i due coefficienti decisi il 23 novembre (modalità 7.8) non hanno ancora dove agire. Va deciso quali voci dell'elenco siano disponibili finché si gioca in quel formato.
9. *Quando il carro smette di essere reclutabile.* Il documento 01 dice che la cavalleria montata lo rende obsoleto «progressivamente» (punto 2.8.2.1). La proposta dice: fino al passaggio di fase. È una scelta fra più possibili.
10. *Un termine solo per il carro.* Negli sciami l'archetipo si chiama «piattaforma trainata»; qui l'oggetto è chiamato «carro», più breve da ascoltare. Il vocabolario chiuso non ammette due termini per la stessa cosa (carta 9.4; documento 02, punto 4.1): va scelto uno. Vanno inoltre decisi nel documento 02 i termini chiusi del peso («pesante», «leggero», «tiratore»), che oggi non esistono. E va deciso se il tipo di protezione abbia termini suoi (modalità 11.12). Negli sciami non ne ha: il gioco dichiara soltanto «efficace» o «poco efficace» quando si designa un bersaglio (documento 02, punto 4.4.1.3). Qui, separato dal peso, il tipo è una cosa in più da sapere di ogni combattente, proprio e avversario, prima di scegliere chi mandare contro chi. Con la regola del materiale il nome della protezione lo dice già — bronzo e lamiera da una parte, cuoio, tela e scudo dall'altra — e i due termini potrebbero non servire; con il tipo come etichetta slegata dall'oggetto servirebbero per forza (tensione 1).
11. *Chi sta in seconda linea e combatte da vicino.* La proposta dà per inteso che un combattente da mischia in seconda linea possa uscire a colpire come gli altri: il documento della modalità non lo dice e non lo nega (5.2, 5.4). Se non potesse, l'incursore a piedi e l'incursore a cavallo andrebbero ripensati.
12. *La reazione e l'accoppiamento.* La proposta legge «non subisce altri modificatori» (modalità 5.6) nel senso che nemmeno l'accoppiamento fra offesa e protezione tocca la reazione: chi attraversa il varco riceve la frazione dell'attacco del custode, qualunque arma abbia il custode e qualunque protezione porti chi passa. Da qui un tratto dei custodi del varco. La lancia del lanciere a piedi perfora, ed è poco efficace contro chi è protetto dalla perforazione; ma come custode il lanciere colpisce allo stesso modo chiunque passi, e nella fase arcaica custodisce il varco meglio di chiunque altro a piedi. Se invece l'accoppiamento valesse anche per la reazione, il tipo di protezione di chi fa l'incursione andrebbe scelto contro le armi dei custodi, e i custodi andrebbero scelti anche per l'arma: andrebbero ripensati gli uni e gli altri.
13. *La tenuta di linea e la protezione come relazione.* Fra i fattori che la memoria delle decisioni esclude c'è «Protezione come relazione», perché «dipendeva dagli ordini di densità, esclusi; e reggeva il collasso improvviso, già escluso con la limatura» (`Fondamenta/decisioni-fase-2.md`, tabella dei fattori esclusi, voce PRO-02). La tenuta di linea, decisa il 23 novembre per questa modalità (modalità 7.8), ne è la traduzione nelle due linee. I due motivi dell'esclusione qui non valgono: le due linee sono elenchi e non geometria, senza ordini di densità (modalità 5.1), e chi perde l'intera prima linea entra già in uno stato terminale (modalità 5.10). Lo segnalo perché la voce PRO-02 resti letta per quello che è, un'esclusione che riguarda gli sciami: il documento della modalità dice che lì nulla cambia.
14. *Il metallo paga il tipo e non il peso.* Con la regola del materiale tutto ciò che protegge dalla perforazione costa metalli, e ciò che protegge dalla saturazione ne costa poco o nulla. Il documento 01 dice i metalli «il collo di bottiglia che distingue un esercito pesante da uno leggero» (punto 5.5.1): qui distinguono piuttosto chi è coperto da ciò che perfora, e nella fase antica si può essere pesanti quasi senza metallo, con lo scudo da riparo o con l'armatura di linea in tela. Due conseguenze da guardare in taratura. I due tipi non sono una protezione migliore e una peggiore, ma uno costa e l'altro no: l'organico povero è tutto protetto dalla saturazione, e l'avversario lo sa in anticipo (modalità 3.1; punto 7.1). E l'acquisizione «ferro come materiale ordinario», che sposta il costo dai metalli al denaro (punto 6.4), diventa quella che rende accessibile il tipo raro. È coerente con la memoria delle decisioni, che vuole i due tipi con «disponibilità profondamente diversa» nella fase arcaica (`Fondamenta/decisioni-fase-2.md`, punto 1.34); ma è una conseguenza della regola del materiale, non della decisione del titolare, e va confermata con essa.

### 7.4 Ciò di cui non sono certo

- *Che cosa ho letto del 04.* Per intero la parte I; nelle parti II e III i temi 1, 2, 5, 6, 8, 9, 11 e 12; la parte IV salvo il punto IV.8; le parti V, VI e VII. Del tema 3 della parte II ho letto le sole righe 323–352. Nel resto del tema 3 e nei temi 4, 7, 10, 13 e 14 ho fatto soltanto ricerche per parola. L'affermazione che il 04 non documenti alcuno scontro fra campioni poggia su una ricerca per parola nell'intero file e sulla lettura dei temi indicati. Non ho aperto le sessioni tematiche della cartella `Deep research`, da cui il 04 è assemblato.
- *Le righe.* Ho ricontrollato sul file ogni riga citata. Non ho verificato le fonti che il 04 cita a sua volta.
- *Che cosa ha letto la revisione del 23 novembre.* Le due voci qui sopra sono della prima stesura e valgono per essa. La revisione ha letto del 04 soltanto i passi elencati in testa al documento, cioè quelli su cui poggiano i punti riscritti, e non ha riletto il resto. Nemmeno la revisione ha verificato le fonti che il 04 cita a sua volta.
- *Quattro incoerenze interne al 04, che la proposta attraversa.* Il terzo uomo del carro a tre è detto «lanciere» in una tabella (II T1 r. 214) e «lanciatore di giavellotto» nel testo (II T6 r. 628): ho seguito il testo, e non propongo un lanciere sul carro. I cavalli sono detti corazzati in una tabella (III T1 r. 1238) e privi di bardatura nel testo (III T6 r. 1948): ho seguito il testo. Il sistema di arciere e portascudo è detto «attestato in entrambe le fasi» (III T6 r. 1940), ma i due esempi che il paragrafo porta cadono nella fase antica: ho proposto il portatore di scudo soltanto in quella. La quarta è della revisione: la corazza di lino e quella di bronzo pesano quasi lo stesso nella tabella dei pesi (III T6 r. 1851–1854) e l'una un terzo dell'altra nel progetto sperimentale (III T6 r. 1874); non ho scelto, perché in entrambi i casi il corredo resta pesante per lo scudo (punto 5.4).
- *Le scelte di progetto presentate come tali.* L'offesa della fionda con pietre, della spada, dei giavellotti e del piombo; le capacità proprie dei quattro eroi; il materiale da costruzione come risorsa del carro; tutti gli ordinamenti. In nessuno di questi casi il 04 decide: al più orienta. I due coefficienti, che la prima stesura metteva in questo elenco, sono ora decisi dal titolare (modalità 7.8). La revisione ne aggiunge quattro: la regola del materiale, cioè che il metallo protegga dalla perforazione e ceda a ciò che satura; il «pettorale di bronzo»; la condizione senza tipo di chi non porta protezione; la parità di vita fra due protezioni dello stesso peso e di tipo opposto.
- *La regola del materiale.* È la scelta della revisione di cui sono meno certo, ed è quella da cui dipendono le altre. La decisione del titolare dice che il tipo di protezione è separato dal peso; non dice da dove il tipo venga. Ho scelto il materiale perché dà una regola sola da imparare all'ascolto e perché, fra le assegnazioni possibili, è quella che contraddice meno il 04 (punto 3.4). Ma fa coincidere il tipo con un'altra cosa, il materiale, e con esso il costo in metalli (tensione 14): se la separazione voluta dal titolare va intesa come piena, cioè con il tipo slegato da ogni altro attributo come negli sciami, la via giusta è l'etichetta scelta al reclutamento, con i suoi costi (tensione 1).
- *Il tipo dell'armatura di lamiera.* Per la regola del materiale protegge dalla perforazione. È la protezione che copre di più in tutta la partita, sicché che ceda a ciò che satura è, fra tutte le assegnazioni, quella con meno appiglio (punto 4.3). Darle l'altro tipo romperebbe però la regola del materiale proprio sull'oggetto degli eroi.
- *La lettura della memoria delle decisioni.* La prima stesura leggeva `decisioni-fase-2.md` (punto 1.34 e voce PRO-07) nel senso che la protezione pesante fosse uno dei due tipi, e ne faceva un appoggio alla proposta A: quella lettura è caduta con la proposta. Resta un fatto da sapere. Il punto 1.34 dice la distinzione fra i due tipi «netta fin dall'età arcaica, ma con disponibilità profondamente diversa», subito dopo aver detto rara e costosa la protezione pesante: lega cioè la rarità di uno dei due tipi alla protezione pesante, mentre la decisione del 23 novembre separa tipo e peso per questa modalità. La revisione conserva di 1.34 la disponibilità diversa — il tipo che protegge dalla perforazione costa metallo — e non il legame con il peso. Della voce PRO-07 usa soltanto la lettera: il confronto fra lino e bronzo «assorbito dai due tipi di protezione». Che 1.34 e PRO-07 vadano letti così è una lettura della revisione, come l'altra lo era della prima stesura.
- *Il secondo eroe della fase arcaica.* Il «nobile corazzato» ha l'appoggio più debole dell'elenco: la figura è documentata, il suo impiego a piedi è conteso, la capacità è inventata.
