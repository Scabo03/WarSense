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
