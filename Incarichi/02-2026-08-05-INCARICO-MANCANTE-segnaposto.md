# Segnaposto — l'incarico della sessione 02 manca dal disco

**Questo non è l'incarico della sessione 02.** È un segnaposto che dichiara che
il file `02-2026-08-05-catena-e-sessioni-complete-incarico.md` **non esiste**
nella cartella, benché sia trattato come archiviato.

## Che cosa manca

Il file `Incarichi/02-2026-08-05-catena-e-sessioni-complete-incarico.md` non è
presente. Il resoconto della stessa sessione,
`02-2026-08-05-catena-e-sessioni-complete-resoconto.md`, è presente e completo.
È l'unico caso, su tutti gli incarichi e resoconti citati nei documenti, in cui
un file dichiarato archiviato è assente — verificato con il comando riportato nel
resoconto della sessione 06.

## Per quale causa

La sessione 02 non scrisse mai il file. Come la richiesta di chiarimento del
2026-08-06 ha accertato (`05-2026-08-06-chiarimento-contraddizioni-risposta.md`,
punto sull'incarico 02), una catena di comandi si interruppe **prima** del
comando che avrebbe scritto l'incarico verbatim. Il testo non fu quindi mai
depositato.

## Chi lo dà per archiviato, e perché «a torto»

Non è la prosa del resoconto della sessione 02 a dichiararlo archiviato: quel
resoconto non contiene alcuna affermazione di archiviazione (verificato con
`grep -niE "indice|README|deposit|elenco|archivi|verbatim" sul resoconto 02`,
zero righe). A darlo per archiviato è **l'indice**: la riga 02 di
`Incarichi/README.md` lo presenta come collegamento
`[incarico](02-2026-08-05-catena-e-sessioni-complete-incarico.md)`, e quella riga
fu aggiunta proprio dal commit del resoconto della sessione 02, `1ae39cf`
(`git log -S` sulla stringa del nome file lo conferma). L'indice afferma dunque
l'esistenza di un file che non fu mai scritto: è la stessa specie di divergenza
fra un registro e ciò che davvero esiste che ha prodotto il caso della build 13
e il registro delle build (RDA-82).

## Che cosa NON si fa qui

Il testo dell'incarico della sessione 02 esiste altrove e verrà reinserito dal
titolare al proprio nome, `02-2026-08-05-catena-e-sessioni-complete-incarico.md`.
Non è ricostruito, non è riscritto a memoria, non ne è inventata una versione:
una ricostruzione avrebbe l'aspetto di una fonte senza averne il valore
(`Incarichi/README.md`, «Regola»). Questo segnaposto porta un nome distinto
apposta per non occupare quel nome canonico e non ostacolare il reinserimento.
Quando l'incarico vero sarà depositato, questo segnaposto va rimosso.
