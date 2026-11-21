# Ciò che la sessione da tester ha confermato funzionare — incarico 28, seconda parte

Ogni voce cita ciò che VoiceOver ha pronunciato (pilota, servizio VoiceOver delle prove; le pronunce sono troncate dal servizio a 64 caratteri) e dove. Codice della build 29, iOS 27.0, verticale e testo predefinito salvo dove detto.

## Battaglia (scontro di prova, iPad; e battaglia nata in campagna, iPhone)
- **Schieramento:** scelta la tessera («fanteria leggera 5 atomi, volume 50, 3 esemplari»), le celle dichiarano in testa la validità: «troppo avanzata, riga 1, cella 1» oppure «costa 50, restano 310, riga 10, cella 1» (02 §3.3). Il bersaglio non valido è rifiutato col motivo («troppo avanzata») e il fuoco resta; il piazzamento si annuncia («Piazzato: costa 50, restano 310»).
- **Annullamento e azzeramento:** «Ultima operazione annullata», anche ripetuto (il secondo annulla la scelta della tessera, che è un comando a sé); «Schieramento del turno azzerato».
- **Fine del turno:** «Turno 1, agisce l'avversario», poi gli eventi avversari («Entra in campo fanteria leggera A avversario in riga 1, cella 5», «fanteria leggera C avversario si sposta in riga 2, cella 3»).
- **Designazione del movimento:** il pannello del proprio reparto («Azioni per riga 10, cella 5») offre «Scegli la destinazione sulla griglia»; avviata la designazione («Scegli la cella di destinazione e attivala per confermare») le celle dicono «bersaglio non valido» oppure costo e residuo; la destinazione non valida non muove nulla, quella valida annuncia «Spostato in riga 8, cella 5: costa 158, restano 172». Chiuso il pannello, il fuoco torna sulla cella del reparto.
- **Chiusura e riapertura dell'app a metà azione:** riprendendo lo scontro, il piazzamento («occupata, riga 10, cella 5, tuo fanteria pesante A») e la tessera scelta («tiratori… selezionato») ci sono ancora.
- **Rotazione a metà azione:** in orizzontale VoiceOver legge tutti i 109 elementi fino a «Fine del turno»; tornati in verticale la scelta della tessera è ancora lì.
- **Taglia del testo cambiata a partita in corso** (al massimo, dal Mac): VoiceOver legge di nuovo tutti i 109 elementi fino a «Fine del turno».
- **Resoconto:** nella battaglia nata in campagna, conclusa per annientamento dopo 14 turni, VoiceOver legge il resoconto intero: «Sconfitta: è stato annientato», «Durata: 14 turni», «Perdite tue: 600 punti su 600 impegnati», «Perdite inflitte: 150 punti», «Unità evacuate: 0», «Scariche residue dei tuoi tiratori: 0», «Riserve mai schierate: 0», «Torna all'inizio».

## Campagna (iPhone e iPad)
- **Apertura:** «Mappa Guado, 4 righe per 4 caselle…», «Giorno 1. Nessun gruppo ha ancora agito, sono 4»; il fuoco sul primo gruppo che attende.
- **Ordini:** il pannello si annuncia («Avviso! Azioni per Orso in riga 4, casella 1»); «Orso presidia in riga 4, casella 1»; «Lupo marcia verso riga 3, casella 3, 2 giorni al termine»; «Falco ha esplorato la zona attorno a riga 4, casella 4»; l'ultimo ordine chiude la giornata («Giornata conclusa: comincia il giorno 2»).
- **Il tasto «Chiudi la giornata» corretto:** con un gruppo ordinato e tre fermi, «Giornata chiusa. 3 gruppi non avevano agito e restano fermi…» e «Giornata conclusa: comincia il giorno 2», fuoco fermo sul tasto; l'annullamento subito dopo è rifiutato col motivo, perché l'avversario ha mosso: «non si torna oltre la giornata in corso».
- **Comando ripetuto:** dopo il presidio la casella dice «ha agito» e il pannello offre soltanto la riunione e la chiusura.
- **Designazione della marcia a metà:** sopravvive alla rotazione; la destinazione non valida è rifiutata col motivo («non adiacente»); chiudendo e riaprendo l'app la designazione si perde, l'ordine già dato resta, e il fuoco atterra sul primo gruppo che attende.
- **Battaglia nata in campagna e ritorno:** aperta dal pannello del gruppo coinvolto («Apri la battaglia»), fuoco sull'intestazione del deck, avversario per primo; dopo il resoconto e «Torna all'inizio», la campagna riprende: «Giorno 9. Nessun gruppo ha ancora agito, sono 3».
- **Tocco magico** (doppio tocco a due dita, guidato dal vivo): l'informazione di stato della campagna e quella della battaglia («Volume residuo 330, turno 5, avversari fino alla riga 1»).
- **Rotori da tastiera:** i sei rotori della mappa, e il salto «Gruppi da muovere» da Corvo a Lupo a Falco.

## Con Device Hub (gesti a un dito, eventi di sistema; `../device-hub/trascrizione.md`)
- **Impostazioni:** il doppio tocco su «Impostazioni» le apre, con il fuoco sull'intestazione; il doppio tocco su «Chiudi il pannello» le chiude e il fuoco torna su «Impostazioni Pulsante». È l'osservazione 6 dell'incarico 27 corretta, vista anche con questo canale.
- **Pannello del gruppo:** il doppio tocco sulla casella di Lupo apre «Azioni per Lupo in riga 1, casella 3»; il doppio tocco su «Chiudi il pannello» lo chiude e il fuoco torna sulla casella di Lupo.
- **Colpetti:** a destra «riga 1, casella 4, formazione non armata avversaria, bosco…», a sinistra di nuovo Lupo, in giù «Vai a sud» (le azioni personalizzate della casella).
- **Etichette intere**, lette dall'albero che Device Hub espone, senza il taglio a 64 caratteri: per esempio «riga 1, casella 3, tuo Lupo, in attesa, in sosta di rifornimento, formazione di ricognizione avversaria, composta da 18 atomi di fanteria leggera, 8 atomi di fanteria pesante».
