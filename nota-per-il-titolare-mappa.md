# La mappa di campagna: che cosa puoi fare e come

Nota breve, senza termini tecnici. Da leggere prima di provare la build nuova.

Questa nota sta dietro un controllo che rifiuta il caricamento se non è aggiornata,
se nomina un comando che il gioco non ha o se contiene un numero che il programma
di verifica non produce più. Nella versione precedente conteneva quattro cose
false, e nessuna era un errore di misura: erano affermazioni diventate false sotto
una nota che nessuno rileggeva. Adesso non si può caricare senza rileggerla.

Convenzione di questa nota: le virgolette basse racchiudono soltanto ciò che il
gioco dice o mostra davvero, e il controllo pretende che ogni nome così citato
esista nel gioco; le virgolette alte sono citazioni di altra natura.

## Che cos'è cambiato in questa build

Tre cose, e nessuna tocca lo scontro. **È la prima build che ti arriva con il
tocco diretto**: le due precedenti correzioni sono state fatte e provate, ma non
erano ancora salite sui dispositivi.

**Le caselle si toccano con il dito.** Fino a ieri le caselle della mappa — e
anche le celle della griglia di battaglia — rispondevano soltanto al doppio tocco
di VoiceOver. Chi guardava lo schermo senza VoiceOver acceso non poteva ordinare
nulla, su nessuno dei due piani. Ora rispondono a tutt'e due, e per la stessa
strada: toccare una casella con il dito fa esattamente ciò che fa attivarla con la
voce, non una cosa simile. Se noti una differenza fra le due, è un difetto e voglio
saperlo.

**Il registro e l'annullamento sono quelli della build precedente**, descritti qui
sotto perché la nota vecchia li descriveva ancora come erano due build fa.

**Una cosa da sapere sul dito, sulle mappe grandi e sullo scontro.** Quando la
griglia è più grande dello schermo, il dito può toccare soltanto ciò che è
davvero in vista: per raggiungere una casella più in basso bisogna prima far
scorrere la griglia. La voce invece ci arriva da sé, perché quando il cursore si
sposta su una casella fuori vista è il gioco a portarla in vista. Non è un
difetto, ma è un'asimmetria fra i due modi: dimmi se giocando la senti come
scomoda, perché in quel caso si può fare qualcosa.

**Il collaudo automatico ora gira tutto prima di ogni caricamento.** Prima ne
girava una parte, e la parte che non girava era proprio quella che prova
l'interfaccia. Non cambia nulla per te mentre giochi; cambia che i difetti come
quelli che mi hai segnalato hanno adesso una rete.

## Dalla schermata iniziale

Trovi tre voci per la campagna:

- «Nuova campagna, mappa piccola» — quattro caselle per quattro. Minuscola, si
  gira in pochi gesti. È quella con cui conviene cominciare.
- «Nuova campagna, mappa media» — sei per sei. C'è un fiume che la taglia in due
  e un passaggio obbligato in mezzo.
- «Nuova campagna, mappa grande» — dieci per dieci. È il formato vero delle
  campagne importanti.

E, se ne hai una aperta, «Riprendi la campagna in corso». Cominciarne una nuova
sostituisce quella aperta; lo scontro salvato, invece, resta dov'è e non c'entra
nulla: le due cose vivono in due posti separati.

## Come ci si muove

Esattamente come in battaglia, e non è un caso: è la regola che i due piani si
guidino allo stesso modo. Lo scorrimento a destra e a sinistra percorre la riga e
prosegue nella riga dopo; per andare a nord o a sud ci sono due sole voci nelle
azioni. Non ci sono diagonali: una casella ha al massimo quattro vicine.

Ogni casella ti dice, in quest'ordine: dove sei (riga e casella), che cosa c'è di
tuo, se c'è un quartier generale, com'è il terreno, se c'è una strada, se è una
strettoia. Quello che non c'è non si annuncia: una casella normale e vuota dice
soltanto dove si trova.

## Come si dà un ordine

Attivi la casella di un tuo gruppo — con la voce, o toccandola con il dito. Si apre
un pannello con due voci:

- «Marcia: scegli la casella sulla mappa» — poi vai sulla casella dove vuoi andare
  e la attivi. Se cambi idea, il «gesto di fuga» annulla.
- «Presidia: resta fermo in guardia» — il gruppo resta fermo in guardia.

Stare fermi è un ordine come un altro, non un non fare. Serve, perché la giornata
si chiude solo quando tutti i gruppi hanno ricevuto un ordine.

## Le tre cose che ti fanno risparmiare tempo

1. **Il «tocco magico» a due dita** ti dice a che punto sei: che giorno è e quanti
   gruppi hanno già agito sul totale. Funziona sempre e non ti fa perdere il posto.
2. **Il rotore dei gruppi da muovere** salta direttamente al prossimo gruppo che
   attende un ordine, e ripassa in giro finché ce ne sono. Non è una comodità: con
   più di tre gruppi, senza, la mappa diventa impraticabile. La misura dice che su
   una mappa grande con cinque gruppi raccolti presso il quartier generale chiudere
   una giornata costa 15 gesti con il salto e 106 senza.
3. **Il «Registro della campagna»**, il primo comando sotto la mappa. Elenca ciò che
   è successo, dal più recente al più vecchio, una frase per voce, con il giorno
   dentro la frase. Vi entrano gli ordini che hai dato — marcia e presidio, con il
   gruppo e la casella — e gli annullamenti. Finché non hai fatto nulla dichiara
   «Il registro non contiene ancora alcun fatto» invece di presentarsi muto. Si
   chiude con «Chiudi il registro».

**Le voci del registro si attivano**, e attivandole il cursore si porta sulla
casella dove il fatto è avvenuto: il suggerimento lo dice, «Attiva per portare il
fuoco sul luogo del fatto». Fanno eccezione le voci degli annullamenti, che non
hanno un luogo: quelle dicono «Questa voce non riguarda un luogo della mappa» e non
si attivano.

## L'annullamento, e fin dove arriva

Ci sono «Annulla l'ultima operazione» e «Azzera lo schieramento del turno», come in
battaglia. Dentro la giornata in corso puoi annullare tutto, compreso l'ordine che
ha chiuso la giornata precedente: se lo ritiri subito, la giornata si riapre e il
giorno torna indietro, e il gioco te lo dice con una frase apposita.

Quello che **non** puoi più fare è risalire a una giornata ancora prima. Se nella
giornata nuova hai già fatto qualcosa — dato un ordine oppure annullato — il gioco
rifiuta dicendo «non si torna oltre la giornata in corso». L'azzeramento segue la
stessa regola.

Nella prima versione della mappa si poteva annullare a ritroso senza fine, fino
all'inizio della campagna: era troppo, ed è stato tolto per tua decisione. Quando ci
saranno l'avversario e le risoluzioni di fine giornata, tornare indietro dopo che la
giornata si è chiusa equivarrebbe a rifare la prova sapendo com'è andata.

## Che cosa conviene provare per primo

**La domanda più importante è sempre la stessa: dopo cinque o sei giornate, sai dove
sono le cose?** Non se riesci a trovarle riesplorando, ma se ce le hai in testa: dove
sta il tuo quartier generale, da che parte corre la strada, dove passa il fiume,
dove hai lasciato ciascun gruppo.

Un modo per provarlo: dopo qualche giornata, senza toccare lo schermo, prova a
dire ad alta voce dove si trova ciascuno dei tuoi gruppi e da che parte va la
strada. Poi controlla.

Questa domanda il programma di verifica non può risponderla, e non potrà mai. Può
dirmi quanti gesti costa una giornata, e me lo dice; non può dirmi se una mappa si
è formata nella tua testa. Sei tu l'unico che può.

## Le altre cose da guardare

1. **Il dito e la voce devono fare la stessa cosa.** È la novità di questa build.
   Prova a dare lo stesso ordine nei due modi e dimmi se qualcosa cambia: il testo
   che senti, dove resta il cursore, che cosa compare nel registro.
2. **Comincia dalla mappa piccola**, poi la media, poi la grande.
3. **Il salto ai gruppi da muovere**: verifica che li passi tutti, che non ne
   ripeta nessuno e che riparta dal primo quando ha finito il giro.
4. **La lunghezza degli annunci di casella**: sulla mappa media, dove ci sono
   fiume, boschi, strada e strettoia, la frase può farsi lunga. Se lo è troppo, il
   livello sintetico nelle impostazioni tiene solo l'essenziale — dimmi se è quello
   giusto o se va tagliato diversamente.
5. **La chiusura della giornata**: quando dai l'ordine all'ultimo gruppo, la
   giornata si chiude da sé e il giorno avanza. L'ho lasciata senza suono e senza
   vibrazione propri, perché arriva sempre subito dopo il segnale di conferma
   dell'ordine. Se ti sfugge, dimmelo: si cambia.
6. **Il registro dopo qualche giornata**: ci trovi ciò che ti serve, e nell'ordine
   giusto? Con molti gruppi diventa una voce per ordine, e vorrei sapere se resti
   percorribile.

## Una cosa che ho deciso io e che potresti volere diversa

L'incarico della prima mappa diceva che la giornata si chiude “su comando del
giocatore”. Il documento di progetto dice invece, per iscritto, che si chiude da sé
quando tutti i gruppi hanno agito e che un comando di fine giornata non esiste. Ho
seguito il documento, perché è una decisione già presa, e ho letto la frase
dell'incarico come “si chiude per effetto dei tuoi ordini, mai per iniziativa del
programma” — che è vero: nessun gruppo fa niente da solo.

Se volevi davvero un pulsante “chiudi la giornata”, è mezz'ora di lavoro. Dimmelo.

<!-- misura: campagna_passi_per_giornata | pianura_lunga,raccolti,5 | con_il_salto=15 senza_il_salto=106 -->
