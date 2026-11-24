# Dove arriva il fuoco (RDA-192)

Il blocco «fuoco» di `misura-annunci.py`: regno nuovo, campagna, richiamo, dichiarazione di conclusione, ritorno in patria, ripetuti sulla copia strumentata con VoiceOver acceso. Ogni riga porta gli istanti in cui il gioco chiede il fuoco («chiesti», con l'elemento e dove sta) e quelli in cui VoiceOver mette a fuoco un elemento («fuochi»). `conta-fuoco.py <cartella…>` li conta.

| cartella | che cosa |
|---|---|
| `corsa-1` | il codice di `e19b47b` (attesa di 0,4 s, nessuna conferma); corsa interrotta dopo quattro giri |
| `corsa-2` | lo stesso, col giro rapido (`FUOCO_VOLTE=15`), interrotta quando se ne è visto l'andamento |
| `corsa-3` | `prima`: `e19b47b`; `dopo`: lo stesso con la conferma, prima stesura (conta ogni elemento, anche in viaggio); sullo stesso carico, sei simulatori |
| `corsa-4` | la conferma e la patria riportata in testa prima di coprirla: l'ipotesi scartata |
| `corsa-5` | `subito`: la conferma definitiva e la richiesta al congedo, che è il codice scelto; `unsecondo`: la stessa con un secondo di attesa |

Giro lento (`FUOCO_LENTO=1`): ogni volta da capo, coi tempi d'ascolto interi; è il giro in cui il difetto si vede.

Il conto (`conta-fuoco.py corsa-1 … corsa-5`):

    == corsa-1
      ipad               dichiarazione       4 volte,  4 giuste, 0 rinnovate
      ipad               ritorno in patria   4 volte,  4 giuste, 0 rinnovate
      iphone             dichiarazione       5 volte,  5 giuste, 0 rinnovate
      iphone             ritorno in patria   4 volte,  1 giuste, 0 rinnovate; finite su «Registro della patria» 3
    == corsa-2
      ipad               dichiarazione      12 volte, 12 giuste, 0 rinnovate
      ipad               ritorno in patria  12 volte, 12 giuste, 0 rinnovate
      iphone             dichiarazione      12 volte, 12 giuste, 0 rinnovate
      iphone             ritorno in patria  12 volte, 12 giuste, 0 rinnovate
    == corsa-3
      dopo-ipad          dichiarazione       8 volte,  8 giuste, 0 rinnovate
      dopo-ipad          ritorno in patria   8 volte,  8 giuste, 0 rinnovate
      dopo-iphone        dichiarazione      16 volte, 16 giuste, 0 rinnovate
      dopo-iphone        ritorno in patria  16 volte, 16 giuste, 8 rinnovate
      prima-ipad         dichiarazione       8 volte,  8 giuste, 0 rinnovate
      prima-ipad         ritorno in patria   8 volte,  8 giuste, 0 rinnovate
      prima-iphone       dichiarazione      16 volte, 16 giuste, 0 rinnovate
      prima-iphone       ritorno in patria  16 volte,  9 giuste, 0 rinnovate; finite su «Registro della patria» 7
    == corsa-4
      scorsa-iphone      dichiarazione       8 volte,  8 giuste, 0 rinnovate
      scorsa-iphone      ritorno in patria   8 volte,  8 giuste, 8 rinnovate
    == corsa-5
      subito-iphone      dichiarazione      10 volte, 10 giuste, 0 rinnovate
      subito-iphone      ritorno in patria  10 volte, 10 giuste, 4 rinnovate
      unsecondo-iphone   dichiarazione      10 volte, 10 giuste, 0 rinnovate
      unsecondo-iphone   ritorno in patria  10 volte, 10 giuste, 0 rinnovate
