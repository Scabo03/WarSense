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

## Che cosa provare per primo, dopo questa build

1. **La lunghezza delle voci di designazione.** È la novità che rischia di più.
   La voce di tiro dice ora nome, lettera, efficacia, vicinanza e — se il bersaglio
   non è isolato — accerchiamento; quella di ingaggio dice nome, lettera, posizione,
   efficacia e accerchiamento. Il collaudo accerta il contenuto e l'ordine
   (`DesignazioneBersaglioTest`), non quanto siano faticose da ascoltare in un
   pannello con più bersagli. Solo l'orecchio può dire se la frase sia diventata
   troppo lunga e se l'ordine — bersaglio, efficacia, modificatori — sia quello
   giusto; se non lo è, si cambia in 02 §9.3.1 come modifica unica e globale.
2. **La distinguibilità dei termini nuovi.** «Stretto» e «circondato» da una parte,
   «a distanza», «ravvicinato» e «a ridosso» dall'altra: vanno sentiti alla velocità
   di lettura vera, dove parole simili si confondono. Non sono confondibili sulla
   carta; lo sono all'ascolto veloce solo il dispositivo lo dice.
3. Dare ordini: attivare una propria truppa, scegliere una voce del pannello
   (tiro, ingaggio, designazione del movimento) e verificare che l'ordine venga
   eseguito e che si resti nello scontro, con il fuoco sulla cella dell'unità.
4. Raggiungere TUTTE le riserve del deck a scorrimenti, in ogni turno, e
   schierarle tutte.
5. Il resto come nella nota precedente: fuoco mai mosso da solo, informazioni
   mancanti, verbosità.
