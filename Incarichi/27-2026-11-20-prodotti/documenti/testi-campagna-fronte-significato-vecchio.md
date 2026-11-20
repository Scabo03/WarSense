# Testi rivolti al giocatore con «campagna» o «fronte» nel significato vecchio — per una decisione successiva

Incarico 27, seconda parte. Dal 2026-11-20 (documento 01, punto 5.6.9, versione 3.8) la **campagna** è la guerra contro un regno nemico e il **fronte** è una zona dentro la campagna, con la propria mappa nella modalità a sciami. Fino ad allora era il contrario: la campagna era la zona giocata sulla propria mappa, con il proprio calendario e il proprio registro, e il fronte il teatro di un regno nemico. Per decisione del titolare, in questa sessione i testi del gioco NON si cambiano su questo punto: qui sotto c'è l'elenco, per decidere dopo. I nomi interni del codice non si toccano.

Fonte: inventario per `grep` su tutti i testi del gioco (`Codice/Sources/Contenuti/Testi/it.lproj/Annunci.strings`, `Annunci.stringsdict`, `Vocabolario.strings`), sui file dei valori con campi mostrati al giocatore e sulla nota per i tester, con la verifica che `Applicazione/Sorgenti` non contenga testi (solo chiavi). Le righe si riferiscono al principale prima della seconda parte dell'incarico 27.

## «Fronte»

Nessuna occorrenza in alcun testo rivolto al giocatore (stringhe, `.stringsdict`, file dei valori, note per i tester).

## «Campagna» — testi del gioco (`Annunci.strings`)

| riga | chiave | testo | dove si sente | significato |
|---|---|---|---|---|
| 177 | `significato.vincolo_campagna` | «Vincolo fra le campagne» | schermata «Suoni e vibrazioni del gioco» (significato 15 di 02 §11.7.1) | VECCHIO: è lo scarto massimo di due settimane fra i calendari, che ora è fra i FRONTI aperti. Oggi nessun evento emette il segnale; compare solo nella schermata d'apprendimento |
| 277 | `registro.titolo` | «Registro della campagna» | titolo del registro | VECCHIO: è il registro della zona giocata, cioè del fronte |
| 281 | `registro.apri` | «Registro della campagna» | pulsante sulla mappa | VECCHIO, come sopra |
| 324 | `campagna.slot_incompatibile` | «La campagna salvata appartiene a valori di versione %@ e questa versione usa %@: non può essere aperta» | annuncio alla ripresa | AMBIGUO: oggi il salvataggio contiene una sola zona su una mappa; regge col significato nuovo solo se il salvataggio sarà inteso come la guerra intera |
| 325 | `campagna.slot_schema_incompatibile` | «La campagna salvata è stata scritta in un formato precedente e non può essere aperta. Comincia una campagna nuova» | annuncio alla ripresa | AMBIGUO, come sopra; «Comincia una campagna nuova» rimanda ai pulsanti delle righe 386–388 |
| 386 | `avvio.nuova_campagna_piccola` | «Nuova campagna, mappa piccola» | menu d'avvio | VECCHIO: la campagna è identificata da un formato di mappa, che ora appartiene al fronte |
| 387 | `avvio.nuova_campagna_media` | «Nuova campagna, mappa media» | menu d'avvio | VECCHIO, come sopra |
| 388 | `avvio.nuova_campagna_grande` | «Nuova campagna, mappa grande» | menu d'avvio | VECCHIO, come sopra |
| 389 | `avvio.riprendi_campagna` | «Riprendi la campagna in corso» | menu d'avvio, se c'è un salvataggio | COMPATIBILE con riserva: «riprendere la guerra in corso» regge anche col significato nuovo; la riserva è quella delle righe 324–325 |

## «Campagna» — nota per i tester (`note-di-rilascio.txt`, allegata a TestFlight)

| riga | testo | significato |
|---|---|---|
| 1 | «…tornando dalla battaglia, la campagna si bloccava in modo irreversibile…» | VECCHIO: la partita sulla mappa e il suo calendario |
| 3 | «Una campagna già bloccata non si recupera…» | VECCHIO |
| 5 | «…e la campagna riprende il giorno dopo» | VECCHIO: il calendario della mappa |

La nota per i tester è riscritta a ogni build: quella della build 28 è scritta nella terza parte di questo incarico.

## Fuori dai testi, ma visibile al giocatore

Il nome di cartella `campagna-di-prova` (`Applicazione/Sorgenti/PartitaCampagna.swift`, riga 29) non è un testo del gioco, ma il giocatore lo vede nell'app File, perché l'`Info.plist` dichiara `LSSupportsOpeningDocumentsInPlace` e `UIFileSharingEnabled`. La ripresa della partita lo cerca per nome: rinominarlo renderebbe irraggiungibili i salvataggi esistenti.

## Le prove che citano questi testi alla lettera

Le prove d'interfaccia cercano i pulsanti per etichetta: «Nuova campagna, mappa piccola» in `ProveInterfaccia/EsploratoriAvversarioTest.swift` (riga 28), `ImpiantoInterfacciaTest.swift` (62, 188), `FumoMappaCampagnaTest.swift` (14); «Registro della campagna» in `ImpiantoInterfacciaTest.swift` (131, 170, 222) e `FumoMappaCampagnaTest.swift` (26, 53). Chi cambierà i testi dovrà cambiare insieme queste prove.
