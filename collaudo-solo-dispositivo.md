# Verifiche possibili soltanto su dispositivo

Elenco di ciò che il collaudo automatico non può accertare e che ogni prova su
dispositivo deve guardare per prima. Si consegna insieme alla build, perché chi
prova sappia dove il collaudo automatico si ferma. Nato dall'intervento correttivo
dopo la prima prova su dispositivo della fase B, in cui le prove erano verdi mentre
VoiceOver non agganciava elementi dichiarati: da allora la raggiungibilità
(ordine di lettura effettivo, cornici non degeneri, posizione nello schermo,
bersagli di almeno 44 punti) è provata in automatico da `RaggiungibilitaTest`,
e ciò che resta fuori è scritto qui.

## Che cosa il collaudo automatico ora accerta

- Ogni elemento del percorso di lettura ha etichetta, cornice non degenere e giace
  dentro lo schermo piccolo di riferimento, o in un contenitore scorrevole.
- L'ordine di lettura è quello dichiarato: celle, intestazione del deck, tessere,
  annullamento, azzeramento, resa, fine del turno (02 §2.8, RDA-49).
- Le voci del pannello agiscono dopo il congedo automatico dell'avviso e la
  schermata dello scontro non viene mai congedata (02 §9.2.1).
- Nel fumo d'interfaccia il tocco vero delle tessere seleziona davvero, attraverso
  il servizio di accessibilità reale del simulatore.

## Che cosa soltanto il dispositivo può dire

1. **La lettura come la pronuncia la voce.** Nelle prove ospitate il runtime di
   accessibilità non è caricato: ruoli, etichette derivate e frasi composte si
   verificano con una derivazione convenzionale. La frase intera che VoiceOver
   pronuncia su ogni elemento — nome, valore, tratti, suggerimento — va sentita.
2. **L'aggancio per scorrimenti e per esplorazione al tatto.** La geometria è
   provata; il gesto vero no. In particolare: tutte le tessere del deck e tutti i
   comandi globali si raggiungono a scorrimenti dalla prima cella all'ultimo
   comando, senza salti né elementi muti.
3. **Lo scorrimento automatico al fuoco.** Quando il fuoco arriva su una cella o
   una tessera fuori vista, la vista deve portarla dentro da sé, senza toccare il
   fuoco.
4. **Il fuoco alla chiusura del pannello.** Dopo l'attivazione di una voce, il
   fuoco deve ritrovarsi sulla cella d'origine dell'unità; nelle prove si osserva
   il guardiano del fuoco, non il fuoco vero di VoiceOver.
5. **La coda degli annunci.** Ordine, interruzioni, lingua dichiarata e convivenza
   con i suoni si giudicano solo a orecchio, con la voce e la velocità di chi gioca.
6. **L'aptica.** Il simulatore non ha il motore: distinguibilità delle famiglie
   ritmiche, passi d'intensità e sincronia col suono sono materia esclusiva del
   dispositivo (e su iPad lo strato non esiste: 00 §5.1).
7. **I gesti di sistema.** Tocco magico a due dita, gesto di fuga, rotori
   personalizzati (presenza delle voci e salto effettivo): non simulabili nelle
   prove ospitate.
8. **I caratteri molto grandi.** Con le taglie d'accessibilità la colonna del deck
   deve restare integra e la griglia cedere spazio; oltre una certa taglia il
   comportamento va osservato sul dispositivo.

## Che cosa provare per primo, dopo la build precedente (lo scontro)

1. **La lunghezza delle voci di designazione.** È la novità che rischia di più, ed
   è cresciuta ancora. La voce di tiro dice nome, lettera, efficacia, vicinanza e —
   se il bersaglio non è isolato — accerchiamento; quella di ingaggio dice nome,
   lettera, posizione, efficacia, eventuale accerchiamento e SEMPRE la risposta
   attesa. Il collaudo accerta contenuto e ordine (`DesignazioneBersaglioTest`), non
   quanto siano faticose da ascoltare in un pannello con più bersagli. Solo
   l'orecchio può dire se la frase sia diventata troppo lunga e se l'ordine —
   bersaglio, efficacia, ciò che infliggo, ciò che ricevo — sia quello giusto; se
   non lo è, si cambia in 02 §9.3.1 come modifica unica e globale. Da valutare in
   particolare se la risposta debba tacere quando è piena, cioè nella condizione
   ordinaria: oggi si annuncia sempre, per la ragione dichiarata in 01 §9.11.3.
2. **La distinguibilità dei termini nuovi.** Tre insiemi ormai: «stretto» e
   «circondato»; «a distanza», «ravvicinato» e «a ridosso»; «risposta piena»,
   «risposta di lato» e «nessuna risposta». Vanno sentiti alla velocità di lettura
   vera, dove parole simili si confondono — e i primi due termini della risposta
   condividono la parola d'apertura. Non sono confondibili sulla carta; se lo sono
   all'ascolto veloce, solo il dispositivo lo dice.
3. Dare ordini: attivare una propria truppa, scegliere una voce del pannello
   (tiro, ingaggio, designazione del movimento) e verificare che l'ordine venga
   eseguito e che si resti nello scontro, con il fuoco sulla cella dell'unità.
4. Raggiungere TUTTE le riserve del deck a scorrimenti, in ogni turno, e
   schierarle tutte.
5. Il resto come nella nota precedente: fuoco mai mosso da solo, informazioni
   mancanti, verbosità.


---

## La mappa di campagna — che cosa il collaudo non può dire

La prima unità della fase D aggiunge la mappa di campagna. Le prove automatiche vi
si applicano già per intero — ordine di lettura effettivo, cornici, bersagli di
almeno 44 punti, elementi mai ricreati, fuoco mai mosso da solo
(`MappaCampagnaAccessibileTest`) — e il programma di verifica ne sorveglia gli
invarianti su centosessanta giornate generate. Restano fuori le cose seguenti.

### La domanda su cui il progetto intero è costruito

**Una persona che non vede si fa un'immagine mentale della mappa?** Cioè: dopo
qualche giornata, sa DOVE stanno le cose — il proprio quartier generale, il bosco,
il fiume, la strada, i propri gruppi — senza doverle riesplorare ogni volta?

Il programma di verifica non può rispondere, e nessuna misura lo potrà mai. Può
dire quanti passi costa chiudere una giornata; non può dire se dopo dieci giornate
il giocatore abbia in testa una mappa o soltanto un elenco di caselle. La risposta
la dà soltanto il titolare, sul dispositivo, giocando. È la verifica più importante
di questa unità e va fatta per prima.

Un modo concreto per provarlo: dopo cinque o sei giornate, senza toccare lo
schermo, provare a dire ad alta voce dove si trova ciascuno dei propri gruppi, dove
sta il fiume e da che parte corre la strada. Poi verificare.

### Le altre verifiche che restano al dispositivo

1. **Il costo reale di un'operazione.** La misura dei passi usa un modello
   dichiarato: tre gesti per ordinare un gruppo con il salto diretto. Solo il
   dispositivo dice quanti gesti servano davvero, e se il modello vada corretto.
2. **Il salto diretto ai gruppi da muovere.** È un rotore personalizzato, e i
   rotori non sono simulabili nelle prove ospitate: vanno provati a mano, verificando
   che il giro sia completo, che non ripeta nessuno e che riparta dal primo.
3. **Le due azioni personalizzate nord e sud.** Che ci siano è provato; che siano
   comode da raggiungere con lo scorrimento verticale, no.
4. **La lunghezza dell'annuncio di casella.** Con occupante, quartier generale,
   terreno, strada e strettoia la frase può farsi lunga. Il livello sintetico tiene
   la sola identità di ciò che occupa; il normale dice tutto. Solo l'orecchio dice
   se il normale sia troppo, e se convenga tagliare prima.
5. **Il registro.** Le voci si leggono, e dalla seconda unità il salto al luogo del
   fatto è esercitabile: le voci degli ordini portano alla casella. Restano non
   attivabili le voci degli annullamenti, che non hanno luogo (RDA-67): vale la pena
   verificare che non sembrino un difetto e che il suggerimento che ne dà la ragione
   arrivi. Vale la pena verificare anche che, dopo qualche giornata, il registro
   resti percorribile: ogni ordine è una voce, e con dodici gruppi sono dodici voci
   al giorno.
6. **La chiusura della giornata.** Non ha segnale tattile né sonoro proprio, per la
   ragione dichiarata in RDA-64. Va verificato che non passi inosservata: se passa,
   la decisione si riapre.
7. **Le tre mappe.** Il quattro per quattro è minuscolo e serve a imparare; il sei
   per sei ha la strettoia; il dieci per dieci è il formato vero. Vale la pena
   provarle in quest'ordine.

### Aggiunta dopo l'accertamento sui numeri (build 12)

9. **L'annullamento che riapre la giornata.** Dai l'ordine all'ultimo gruppo, senti
   la giornata chiudersi, poi tocca Annulla. Devi sentire una frase che dice che si
   torna al giorno precedente e che il gruppo attende di nuovo. Verifica che sia
   distinguibile dall'annullamento ordinario. **Aggiornato alla seconda unità
   (RDA-73):** continuando ad annullare NON si torna più indietro di più giornate.
   Dopo aver ordinato o annullato qualcosa nella giornata nuova, l'annullamento
   dell'ordine che ha chiuso la precedente viene rifiutato con il termine «non si
   torna oltre la giornata in corso». Va verificato che il rifiuto si SENTA e che
   non si confonda con «niente da annullare», che è un motivo diverso.
10. **Che cosa si sente alla chiusura.** Sono due frasi: la conferma del tuo ordine
   e «Giornata conclusa: comincia il giorno N». Il collaudo fissa che siano quelle e
   in quell'ordine; se bastino a farti accorgere del cambio di giornata lo dici tu.

### Aggiunta della seconda unità della fase D (registro, annuncio, confine)

11. **Il contrasto del testo, ovunque e non solo nel registro.** Il difetto del
   registro era un testo agganciabile dalla voce e invisibile all'occhio, e la
   prova che ora lo impedisce misura i pixel disegnati, non le proprietà degli
   oggetti (`RegistroVisibileTest`). Vale però per il solo registro: le altre
   schermate non sono misurate così, perché su una griglia di caselle vuote la
   misura non direbbe nulla. Chi guarda lo schermo controlli che non esistano altri
   testi sbiaditi, in particolare dove un comando è disabilitato per ragioni di
   gioco — resa e fine turno in battaglia — dove il grigio è invece corretto.
12. **L'annuncio della casella durante la designazione di una marcia.** Il difetto
   riferito non è stato riprodotto (scostamento P12): sulla stringa che VoiceOver
   legge, la designazione contiene sempre l'annuncio di esplorazione per intero.
   Ciò che il collaudo non può accertare è come quella stringa venga PRONUNCIATA
   con VoiceOver realmente attivo, né se la condizione osservata dipendesse da uno
   stato che la riproduzione non ha raggiunto. Vale la pena rifare la prova sul
   dispositivo, su una casella con acqua della mappa media o grande, e riferire la
   frase esatta che si sente.
13. **Il rotore delle voci di registro non ancora consultate** (02 §7.3, 00 §10.2)
   NON esiste: la mappa offre due rotori soli, le proprie formazioni e i gruppi da
   muovere. Ora che il registro ha contenuto, l'assenza si sente. Vedi il resoconto
   per la collocazione.
