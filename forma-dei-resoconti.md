# Forma dei resoconti di sessione

File di memoria permanente del progetto. Ogni sessione che debba consegnare un resoconto legge questo file prima di scriverlo. Sostituisce ogni prescrizione precedente sulla materia.

## La regola in vigore

**Il resoconto di sessione si scrive per un lettore tecnico.** Nomi reali di tipi, protocolli, file, funzioni, prove e obiettivi. Firme modificate e punti di chiamata toccati, dichiarati. Le modifiche descritte in termini di che cosa è cambiato, dove, e quale invariante o requisito ne risulta coperto. Nessuna perifrasi al posto di un termine tecnico, nessuna analogia esplicativa, nessuna semplificazione. Niente preamboli, niente riepilogo di ciò che è stato chiesto, nessuna formula di cortesia.

## La regola revocata, e perché

Fino alla seconda unità della fase D valeva la prescrizione opposta: resoconti scritti per una persona priva di competenze tecniche. **È revocata e non va più seguita.**

Nasceva da un'estensione impropria. Il titolare del progetto non ha competenze informatiche, ma i resoconti non li legge lui direttamente: li legge un modello che li verifica e li distilla. Scriverli semplificati fa perdere precisione due volte, in uscita e in ricostruzione.

Chi trovasse la regola vecchia citata in un incarico o in un documento più antico di questo file: prevale questo file.

## Che cosa NON cambia

Due regole restano in vigore, perché riguardano il rigore e non il registro linguistico.

1. **Nessun numero senza l'enunciato di ciò che dimostra**, e ogni numero proveniente dal blocco di riepilogo stampato dal programma di verifica, non dalla memoria (RDA-71). Un numero che compaia nel resoconto e non in quella sezione va dichiarato come calcolato a mano nel punto stesso in cui è scritto.
2. **Ciò che non è stato verificato va dichiarato non verificato**, esplicitamente e nel punto in cui compare.

## L'unico artefatto che resta in linguaggio non tecnico

La nota destinata al titolare del progetto e ai tester, cioè `note-di-rilascio.txt`. Resta soggetta al limite di lunghezza registrato in `memoria-infrastruttura.md` (regola 4, sotto i 4000 caratteri) e imposto dal controllo preventivo dentro `scripts/carica-testflight.sh`.

Vi si affiancano, con la stessa disciplina, i documenti scritti per il titolare quando un incarico li chiede: `nota-per-il-titolare-*.md`, `esposizione-delle-scelte.md`, `resa-del-conto.md`.

---

## Come si risponde, oltre che come si scrive (aggiunto il 2026-08-06)

Le cinque voci che seguono nascono da errori commessi, non da principi astratti. Ciascuna riporta l'episodio che l'ha prodotta, perché una regola senza il suo caso si dimentica prima.

1. **Lo stato dell'esecuzione si verifica sulle FINESTRE DI COMANDO aperte, non su un elenco di nomi di programma.** Alla domanda «cosa c'è ancora in background» ho risposto «niente» dopo aver cercato cinque nomi (`xcodebuild`, `swift-frontend`, `simctl`, `collaudo-completo`, `StrumentoVerifica`) e non averli trovati, mentre una finestra era viva da quasi sei ore: conteneva un ciclo `until … do sleep 20; done` in attesa di un file che non sarebbe mai cambiato. Nessuno dei cinque nomi vi compariva. Il controllo giusto enumera le finestre e ne legge lo stato; l'elenco di nomi risponde a una domanda diversa da quella posta.

2. **Ogni numero porta il nome dello strumento che lo ha prodotto**, nei resoconti e nelle risposte. Un numero contato a mano, calcolato a mente o ricordato va marcato come tale NEL PUNTO in cui compare, non in una nota generale. Vale già per i numeri del programma di verifica (RDA-71); da qui in avanti vale per tutti, compresi i conteggi delle prove, i tempi e le somme.

3. **Un incarico con un riferimento irrisolvibile, una contraddizione interna o una premessa che i documenti non confermano si segnala PRIMA di cominciare**, citando documento e punto. È già accaduto tre volte: RDA-61 (l'incarico contraddiceva 01 §5.6.0.6), RDA-77 (l'incarico dava per non documentato un termine che 01 §5.6.8.1 contiene), e i rimandi a «sezione N» in incarichi le cui intestazioni non portano numeri. Nei primi due casi la contestazione è avvenuta; nel terzo no, e il silenzio è l'errore.

4. **Quando una risposta e uno stato osservabile si contraddicono, si dichiara la contraddizione**, non si riporta soltanto il ramo che si è verificato. Se il controllo dice una cosa e la riga di stato ne dice un'altra, la risposta corretta nomina entrambe e dice quale non è stata verificata.

5. **Ciò che non è stato verificato si dichiara non verificato nel punto in cui compare**, e ciò che non si ricorda si dichiara non ricordato anziché ricostruito. Uno scostamento dichiarato vale più di un'affermazione tornante.

### Avvertenza su queste stesse voci

Una regola scritta in un file di memoria è una PRESCRIZIONE, ed è la forma di protezione che in questo progetto viene disattesa con regolarità, mentre i controlli che rifiutano non lo sono mai — è il risultato che `esame-critico.md` ha misurato e il criterio da cui nascono i cancelli. Queste cinque voci valgono quindi come promemoria e non come garanzia. **Nessuna di esse va considerata un problema risolto**, e chi le legge non deve trattarle come tali: finché non esiste un controllo che rifiuti lo stato sbagliato, il problema è aperto e queste righe sono soltanto un appunto.
