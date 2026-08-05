# Valutazione di impatto: che cosa cambia quando il costo in giorni potrà superare uno

Documento di dimensionamento, scritto per l'unità successiva e non per questa. Nulla di quanto segue è realizzato. Il perimetro considerato è quello di 01 §5.6.3.1–§5.6.3.5: il gruppo resta nella casella di partenza per tutti i giorni necessari, senza stato intermedio; i giorni mancanti sono dichiarati; l'ordine è revocabile perdendo i giorni spesi; la conseguenza è dichiarata prima della conferma.

Oggi il costo esiste già come grandezza (`ValoriMarcia.costoGiorniBase`, `MotoreCampagna.costoInGiorni(da:a:stato:)`, `ComandoCampagna.marcia(gruppo:a:giorni:)`) e vale uno. Ciò che segue è ciò che manca perché possa valere due o più.

## Che cosa regge senza modifiche

**La firma del calcolo del costo.** `costoInGiorni(da:a:stato:)` prende già le due caselle e lo stato: i pesi della casella di partenza e di arrivo, il tipo di strada e il costo fisso della strettoia si leggono tutti da lì, e il volume della colonna dallo stato del gruppo. Nessun punto di chiamata si sposta.

**Il trasporto del costo nel comando.** `.marcia(gruppo:a:giorni:)` porta già il numero, e la validazione già pretende che coincida con quello prescritto. Un costo di tre viaggia oggi come viaggerà domani.

**La formazione del comando dalla Presentazione.** `VistaCampagna.comandoDiMarcia(per:a:)` è l'unico punto in cui il comando si costruisce, e vi mette il costo interrogando il Motore. La Presentazione non conosce il numero e non lo conoscerà.

**Il giornale come struttura.** Righe in appendice, istantanee ai confini, troncamento atomico, ripresa: nulla di ciò dipende dal costo. Il marcatore di apertura giornata e quello di annullamento restano quelli.

**La geometria.** `GrigliaCampagna`, l'adiacenza ortogonale, l'ordine di lettura, i rotori, l'impronta della mappa: il costo non li tocca. 01 §5.6.3.1 esclude esplicitamente i percorsi di più caselle, quindi non serve alcun calcolo di cammino.

**Gli invarianti della campagna.** Dei quindici sorvegliati, dodici restano validi alla lettera. Vedi sotto i tre che cadono.

## Che cosa va rifatto

### 1. Lo stato del gruppo — la modifica strutturalmente più pesante

`Gruppo` porta oggi `posizione` e `azioneSpesa`. Una marcia lunga richiede uno stato in corso: destinazione, giorni totali, giorni compiuti. Sono tre campi nuovi in un tipo che entra nell'impronta canonica e nelle istantanee.

Conseguenza sull'IMPRONTA: `Gruppo.codifica(in:)` cresce di tre campi, e ogni impronta esistente cambia. Le riproduzioni d'oro della campagna — se ne esisteranno — vanno rigenerate con revisione esplicita, come la procedura prescrive (05 §14.6).

Conseguenza sul FORMATO DI SALVATAGGIO: `StatoCampagna` è `Codable` e vive nelle istantanee. Tre campi aggiunti a `Gruppo` rendono illeggibili le istantanee precedenti. Le istantanee sono però rigenerabili dal giornale, e il costo vero è un altro: `FondazioneCampagna.schemaCorrente` va incrementato di nuovo, perché un giornale scritto quando la marcia era istantanea, rigiocato con la marcia lunga, produrrebbe una partita diversa. Le campagne in corso dei tester non si riaprono. È la seconda volta consecutiva: vale la pena avvertirli in anticipo, o accettare che la campagna resti materia sperimentale finché la fase D non si chiude.

### 2. `MotoreCampagna.applica` — la marcia non è più un'assegnazione

Oggi la marcia sposta il gruppo e spende l'azione. Con il costo maggiore di uno diventa: si registra l'ordine, si spende l'azione, e il gruppo NON si muove. Nasce un avanzamento che matura nella risoluzione di fine giornata (01 §5.6.11), che oggi non esiste: `chiudiLaGiornataSeServe` incrementa il contatore e azzera le azioni, e nient'altro. Va costruita la risoluzione di fine giornata, con dentro l'avanzamento delle marce lunghe, e va costruita in un punto solo perché vi entreranno poi imboscate, tagli di rifornimento e completamenti di costruzione.

Conseguenza sull'AZIONE DELLA GIORNATA: un gruppo in marcia lunga ha l'azione consumata ma non spesa dal giocatore (02 §6.5.1.2). `azioneSpesa` non basta più a distinguere i due casi, e la chiusura automatica della giornata — che oggi guarda `allSatisfy(azioneSpesa)` — deve considerare in marcia come già agito senza contarlo fra chi ha agito nell'informazione di stato.

### 3. Gli invarianti che cadono

- `giorno_non_avanzato` e `giorno_avanzato_senza_chiusura` restano validi.
- `azione_non_registrata` va riscritto: il gruppo in marcia lunga spende l'azione nel giorno dell'ordine e nei giorni successivi la ha consumata senza comando.
- `movimento_non_adiacente` va spostato: oggi verifica l'adiacenza fra la posizione prima e la destinazione del comando; con la marcia lunga il movimento avviene alla risoluzione e va verificato lì.
- Nuovo invariante obbligatorio: **nessuno stato intermedio**. Un gruppo in marcia lunga sta nella casella di partenza, mai fra due caselle, e i giorni compiuti non superano mai i giorni totali. È l'invariante che 01 §5.6.3.3 rende esplicito e che oggi non ha senso.
- Nuovo invariante: la revoca non lascia mai un gruppo con giorni spesi residui.

### 4. Il vocabolario degli stati del gruppo

`StatoGruppo` ha oggi due casi, `inAttesa` e `haAgito`. 02 §4.4.5 ne chiude cinque, e la marcia lunga ne porta uno: «in marcia, con i giorni mancanti». Il termine e il suo plurale esistono già nei testi (`gruppo.in_marcia` in Vocabolario.strings, con la voce plurale in `Annunci.stringsdict`, provata da `CatenaTestiEsterniTest`): fu scritto in fase A proprio per questo. Va aggiunto il caso all'enumerativo e collegato.

L'annuncio della casella cresce di conseguenza: `VistaCampagna.vociDiCasella` non cambia forma, perché lo stato del gruppo è già dentro `.occupante`.

### 5. Gli annunci e la dichiarazione preventiva

01 §5.6.3.5 pretende che la conseguenza sia dichiarata **prima della conferma**: che il gruppo resterà immobile per N giorni e non potrà sfilarsi se non perdendo i giorni spesi. Oggi la designazione della marcia esegue il comando all'attivazione della casella, senza pannello di conferma — che è già uno scostamento da 02 §9.2.1, dove l'attivazione del bersaglio «apre il pannello di conferma con le stesse informazioni». Con la marcia lunga quel pannello diventa obbligatorio, perché è il luogo dove la conseguenza si dichiara. È la modifica di presentazione più visibile.

L'annuncio della casella candidata durante la designazione deve inoltre dichiarare il costo in giorni, come in battaglia dichiara il volume e il residuo (02 §3.6). La chiave `casella.disponibile` diventa una frase con un segnaposto e un plurale.

### 6. Il registro e i Segnali

Il completamento di una marcia lunga è un fatto NON deciso dal giocatore (01 §5.17.1) e va nel registro: è il primo fatto di quella specie, ed è il momento in cui la deroga di RDA-72 va riesaminata. Ha inoltre un significato tattile già assegnato e oggi inutilizzato: 02 §11.7.1, significato 2, famiglia della navigazione, impulso singolo con nitidezza alta. Va collegato, non inventato.

### 7. La revoca

Comando nuovo (RDA-76), non un annullamento. Non consuma la giornata (01 §5.6.8.1), si aggiunge al giornale invece di troncarlo, e la conseguenza — la perdita di tutti i giorni spesi — va dichiarata prima della conferma.

### 8. Le misure

`misuraDistanzaFraQuartierGenerali` conta oggi le giornate contando le marce, il che vale solo perché il costo è uno: va riscritta leggendo il calendario. Il modello dei passi di `misuraPassi` non cambia, perché misura la navigazione e non il tempo. Nasce una misura nuova e importante: quante giornate costa attraversare la mappa al variare del terreno e del volume, che è la grandezza da tarare secondo 01 §16.3.

## Portata sul formato di salvataggio, in sintesi

| che cosa | portata |
|---|---|
| `ComandoCampagna.marcia` | nessuna: porta già i giorni |
| `VoceGiornale` | nessuna: nessun caso nuovo richiesto dalla marcia lunga; la revoca ne porterà uno |
| `Gruppo` (stato, impronta, istantanee) | tre campi nuovi; impronte tutte diverse; istantanee illeggibili ma rigenerabili |
| `FondazioneCampagna.schemaCorrente` | da incrementare: le campagne in corso non si riaprono |
| `StatoCampagna` | invariato nella forma, salvo ciò che deriva da `Gruppo` |

## Dimensionamento

L'intervento non è contenuto. Il grosso non è il costo in giorni — che esiste già ed è quasi gratuito — ma le due cose che si tirano dietro: **la risoluzione di fine giornata**, che oggi non esiste affatto e che è il luogo dove entreranno poi metà delle regole della campagna, e **il pannello di conferma della marcia**, che 02 §9.2.1 già prescrive e che oggi manca. Conviene trattarle come due unità distinte, e realizzare la risoluzione di fine giornata PRIMA della marcia lunga, con la marcia lunga come suo primo abitante: costruirle insieme significherebbe scrivere il meccanismo generale sulla misura del suo unico caso.
