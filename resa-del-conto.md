# Perché perdi, e che cosa non va nel mio modo di lavorare

Documento di lavoro. Due parti: la risposta alla domanda sulla fanteria pesante, e la resa del conto sul metodo.

---

# Parte prima — Perché la tua fanteria pesante arriva al contatto più malridotta

## La risposta in una riga

Nelle build che hai giocato, i tiratori avversari avevano la tua fanteria pesante come bersaglio **migliore** del campo, e i tuoi avevano la loro come bersaglio **peggiore**. Il divario si forma per intero prima che le due pesanti si tocchino, e non è recuperabile perché non nasce dal contatto.

## La ricostruzione, giro per giro

Ho rigiocato lo scontro con i valori e i mazzi della build 8, cioè quelli con cui hai giocato, registrando ogni singolo colpo. Le due fanterie pesanti hanno 1400 punti di consistenza per parte (due reparti da cinque atomi).

| giro | che cosa succede | la tua pesante | la loro pesante |
|---|---|---|---|
| 4 | i loro tiratori la colpiscono da 5 celle, **efficace**, 109 punti | −109 | intatta |
| 5 | stessa cosa | −109 (tot. 218) | intatta |
| 6 | stessa cosa, più forte | −237 (tot. 455) | intatta |
| 7 | i tuoi tiratori arrivano a tiro: **poco efficace**, 69 punti | −250 (tot. 705) | −69 |
| 8 | | −109 (tot. 814) | −158 |
| 9 | | −109 (tot. 923) | −288 |
| 10–12 | comincia la mischia | | |

Al momento in cui le due pesanti si incontrano, la tua ha perso **923 punti su 1400, cioè due terzi**; la loro ne ha persi **288, cioè un quinto**. Da lì nessuna manovra recupera, e hai ragione: non c'è manovra che recuperi due terzi di un reparto.

Il divario è tutto di tiro. Nell'intera battaglia la tua pesante prende 923 punti dai tiratori, la loro 342.

## Perché accadeva

Le frecce saturano. La tua fanteria pesante portava la protezione contro la perforazione, che contro le frecce non serve; la loro portava quella contro la saturazione, che serve. In numeri: i loro tiratori rendevano **0,78** contro la tua pesante e i tuoi **0,43** contro la loro — quasi il doppio.

Il programma che comanda l'avversario sceglie il bersaglio ordinandolo per efficacia. Non è che «capiti» di colpire la tua pesante: è il bersaglio più redditizio che ha in campo, e ci va ogni turno da quando entra a tiro. I tuoi tiratori, per la stessa regola, non scelgono mai la loro pesante.

**Questo è già corretto nella build 9, che non hai ancora giocato.** Nelle ricostruzioni con i mazzi attuali la tua fanteria pesante prende **zero** danni da tiro prima del contatto.

---

## Ma c'è dell'altro, e pesa di più

Ho poi tolto ogni differenza: mazzi identici alle due parti, stesso ufficiale, stessa condotta. Restava solo la struttura del gioco. Risultato:

- quando muovi per primo tu, **perdi tu**;
- quando muove per primo l'avversario, **perde l'avversario**.

Non è una tendenza: è successo in tutte e otto le configurazioni che ho provato, in entrambi i versi.

**Lo scenario che giochi ti mette sempre a muovere per primo.** Hai giocato tutte le partite dal lato penalizzato.

### Come funziona, in parole

Dentro un giro l'ordine è: agisci tu, agisce l'avversario, poi si risolvono i combattimenti corpo a corpo. Quindi **l'avversario ha sempre l'ultima parola prima che si scambino i colpi**.

Se mandi un reparto al contatto, lui ha un turno intero per portarne addosso altri due prima che si risolva alcunché. Se è lui a mandare un reparto al contatto, lo scambio si risolve subito e tu puoi rispondere solo al giro dopo, quando i colpi sono già stati dati.

Si vede nei numeri della stessa battaglia a mazzi identici:

- **muovendo per secondo**: al primo giro di mischia la tua pesante ha addosso un nemico, la loro ne ha addosso due. La tua infligge 209 punti e ne prende 60.
- **muovendo per primo**: la tua pesante ne prende 160 e ne infligge 120.

Lo stesso reparto, contro lo stesso reparto, con la stessa armatura. Cambia solo chi ha mosso per primo.

## Concentrare contro manovrare

Hai chiesto se concentrare il fuoco batta il manovrare. Ho scritto una condotta che imita la tua — non ingaggia mai per prima con la pesante, cerca il due e tre contro uno, tira al bersaglio più vicino invece che al più adatto, avanza con i reparti leggeri per attirare — e l'ho messa contro il programma che concentra.

Su otto configurazioni, **la condotta non ha mai cambiato chi perde. L'ordine dei turni lo ha deciso tutte le volte.** La manovra ha migliorato il bilancio delle perdite in alcuni casi (in uno la tua pesante prende 377 punti contro i 1030 della loro) senza mai ribaltare l'esito.

**Ti devo un avvertimento onesto**: quella condotta l'ho scritta io, ed è un'imitazione povera del tuo modo di giocare. Se perde, la misura dice che *la mia imitazione* perde. Non dice che manovrare sia impossibile.

Quello che invece posso affermare con certezza, perché non dipende dalla mia imitazione: **con mazzi identici, ufficiali identici e condotta identica, chi muove per primo perde sempre.**

### La risposta alla tua domanda di fondo

Non è vero che la posizione non conta: concentrarsi in tre contro uno paga circa due volte e mezzo. Quello che il gioco punisce non è manovrare, è **prendere l'iniziativa**. Chi si impegna per primo consegna all'altro l'ultima parola.

Ma è grave lo stesso, e per una ragione che ti riguarda direttamente: attirare, ingannare, tendere una trappola, tendere un'imboscata sono tutte cose che richiedono di impegnarsi per primi. Il gioco chiede posizione e poi penalizza chi si muove per ottenerla.

## Un difetto da guardare, che non ho corretto

Il documento di progetto dice, al punto 9.4.1, che chi attendeva riceve la prima mossa — ed è scritto come un premio. La misura dice che è una penalità, e sistematica. Delle due l'una: o la regola non fa quel che si voleva, o l'intenzione va riesaminata.

Non l'ho toccata, come da incarico. È la cosa più importante emersa, e va decisa sapendo che cosa si sta decidendo.

---

# Parte seconda — La resa del conto

## La contraddizione: hai ragione, ed è peggio di una contraddizione

Le due affermazioni non erano una vera e una falsa. Erano **misurate in due condizioni diverse**, e io le ho accostate come se fossero confrontabili.

- «Con mazzi identici lo squilibrio restava uguale o peggiore»: misurato con i **vantaggi nascosti accesi**. In quella condizione il numero che chiamavo «vittorie» conta solo **quale dei due programmi si arrende per primo**, perché quello che comanda la tua parte è impostato per arrendersi a metà delle perdite e quello avversario a cinque sesti. Quel numero non ha mai misurato l'equilibrio. Non era falso: era privo di significato, e non me ne sono accorto.
- «Da sette a uno a quattro pari»: misurato con i **vantaggi spenti**, confrontando tre mazzi candidati a parità di tutto il resto. Questo confronto è valido.

Quindi: **la correzione dei mazzi è reale e ha funzionato.** L'affermazione che le composizioni non fossero il motore veniva da una misura rotta. Lo squilibrio che resta non sono i mazzi: è l'ordine dei turni.

Aggiungo una cosa che non mi hai contestato ma che devo dire io: quel confronto sta su **otto battaglie per scenario**. Da sette a uno a quattro pari sono tre battaglie che cambiano lato. L'ho presentato come un risultato solido. Non lo è.

## Le soglie di resa: hai ragione sulla sostanza, il meccanismo però è un altro

**Dove la tua obiezione non regge**, e te lo devo dire perché mi hai chiesto di guardare e non di darmi torto: la soglia non si misura sullo scarto fra i due eserciti, si misura sulle **tue perdite rispetto a quello che hai impegnato**. In uno scontro pari sanguinano entrambi, e la soglia si raggiunge lo stesso. Nelle misure, oggi, **tutte** le battaglie simulate finiscono per resa. La condizione si presenta, eccome.

**Dove hai ragione, e conta di più**: quelle tarature non c'entrano nulla con il divario della fanteria pesante. Quel divario si forma fra il quarto e il nono giro, per tiro, quando nessuna delle due parti ha perso abbastanza da pensare al ritiro. Le ho elencate fra le cause delle tue sconfitte. Non lo sono.

E c'è un danno che ho fatto e che non avevo visto: rendendo raggiungibile la soglia della tua parte e lasciando più alta quella avversaria, ho fatto sì che nel simulatore **la tua parte si arrenda sempre per prima** — e chi si arrende è lo sconfitto. Ho rotto la mia stessa misura principale. Nel gioco vero la soglia la usa solo l'avversario, quindi la taratura non ti danneggia mentre giochi; ha danneggiato quello che ti ho riferito.

## I centosessantadue duelli: prima una precisazione, poi la sostanza

La regola del disingaggio **entra in funzione**, e sempre. Quello che non accade mai è un'altra cosa: **nessun primo contatto distrugge nulla**. Tutti e centosessantadue finiscono con i due reparti che si sfilano.

Che cosa comporta, e che avrei dovuto dire:

1. **Nessun primo contatto è mai decisivo.** Le battaglie si decidono sui secondi contatti, dove nessuna soglia opera più, e sul tiro.
2. Le soglie per tipo di truppa distinguono **la durata**, non l'esito: guardia scelta otto giri, fanteria pesante cinque, fanteria leggera due. Ma nessuno muore. Il documento vuole «una fanteria pesante che regge quasi fino allo sterminio e una fanteria leggera che si sfila presto» come due strumenti diversi: differiscono in quanto durano, mai in come finiscono.
3. In pratica: **la tua fanteria pesante non può vincere una mischia. Può solo sopravvivere a una.** È probabilmente parte del motivo per cui, come dici, dal contatto in poi nessuna manovra recupera. Ci sono passato sopra.

Non l'ho corretto.

## Che cosa hanno in comune i difetti che non ho trovato

Le tessere del deck ad altezza zero. L'ingresso in campo dell'avversario mai annunciato. La ritirata riuscita raccontata come annientamento. L'ordine dei turni che decide tutto.

Nessuno dei quattro è una risposta sbagliata. Sono tutti una situazione **mai costruita**. E tutti stanno nel punto in cui due cose che avevo provato separatamente si incontrano.

- Ho provato che ogni elemento *ha un'etichetta*, non che si *raggiunga*.
- Ho provato che ogni evento *ha un modello di annuncio*, non che venga *emesso* durante una partita.
- Ho provato che la regola della ritirata *produce una ritirata*, non *come finiscono davvero le battaglie*.
- Ho provato ogni regola da sola, mai l'ordine in cui i turni si succedono.

La ragione di fondo è una sola: **le mie prove le scrivo nello stesso momento e con la stessa testa con cui scrivo il codice.** Ne ereditano i punti ciechi per costruzione. Possono solo confermare quello che avevo già in mente.

Quello che i difetti li ha trovati è stato: giocare, e misurare. Due cose che guardano il risultato senza sapere in anticipo che cosa cercano.

## Sul numero delle prove

Hai ragione e non ho attenuanti. Centoquindici prove che non hanno mai messo insieme una resa, un'evacuazione totale e un mazzo vuoto sono centoquindici prove che verificano quello che avevo in mente. Il numero misura quanto ho scritto, non quanto è coperto. Smetto di citarlo come se significasse qualcosa.

Il caso più netto è di questa sessione. Il mio strumento di misura l'ho costruito per rispondere alle domande che mi ero già posto — chi vince, quante volte. La tua domanda chiedeva un altro strumento: la ricostruzione colpo per colpo, che ho dovuto scrivere adesso. E c'era una verifica di una riga che avrebbe smascherato tutto: **scambiare l'ordine dei turni e guardare se il risultato si ribalta.** Si ribalta completamente. Non l'ho mai fatta.

## Che cosa cambio

Nel collaudo:

1. **Prove su battaglie intere, non su singole regole.** Giocare partite e verificare che l'esito rispetti certe condizioni, invece di verificare che ogni regola faccia quel che dice.
2. **Un censimento degli annunci**: giocare una partita completa, elencare quali tipi di evento si sono davvero verificati, confrontarli con quelli che esistono. Avrebbe trovato l'ingresso avversario muto in un secondo.
3. **Enumerare le condizioni di fine** invece di sceglierne a mano qualcuna. Avrebbe trovato la ritirata scambiata per annientamento.
4. **Per ogni misura, prima di fidarmene, provare a farla muovere**: cambiare la cosa che dovrebbe cambiarla e vedere se si muove. Se non si muove, non misura quello che credo.

Nel riferire:

5. **La risposta per prima, in una riga.** Poi il caso concreto. L'aggregato solo se aggiunge qualcosa.
6. **Nessun numero senza una frase che dica che cosa avrebbe dovuto valere per concludere il contrario.**
7. Quando una misura è presa in condizioni che la rendono priva di significato, **dirlo invece di riportarla**.

Scrivo per chi conosce già la risposta perché scrivo mentre ce l'ho in testa. È lo stesso difetto delle prove, nell'altra forma.
