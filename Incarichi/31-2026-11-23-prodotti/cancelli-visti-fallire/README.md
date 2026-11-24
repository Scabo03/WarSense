# I cancelli visti fallire di proposito (incarico 31)

La regola del progetto: ogni cancello nuovo si vede fallire una volta di proposito, con l'uscita riportata. Qui sta l'uscita. Ogni file dice da sé il comando che l'ha prodotto.

| che cosa rifiuta | come è stato fatto fallire | file | esito |
|---|---|---|---|
| Il caricatore dei valori del regno: durate, linguette, mantenimento, miglioramenti, stazioni per stagione, lista dei nomi | dieci copie della cartella dei valori, ciascuna con un solo guasto, date allo strumento di verifica | `caricatore-del-regno-visto-rifiutare.txt` | dieci rifiuti su dieci, ciascuno con la chiave e la voce colpevole. Il rifiuto per `stazioni_per_stagione` nominava una voce innocente: corretto (`3d74e93`) e rieseguito |
| La ripresa di un regno salvato con la build 31 (schema 1) | la prova `SalvataggioRegnoBuild31Test`, su un giornale vero scritto dal codice di `41cccff`, eseguita togliendo la lettura dello schema prima dell'apertura | `regno-della-build-31-senza-la-lettura-dello-schema.txt` | senza la protezione: errore `fondazioneMancante` e file troncato a 0 byte al posto di 2895. Con la protezione: `schemaIncompatibile`, file intatto |
| La sonda degli invarianti del regno, ventitré codici | un passo costruito apposta per ciascun codice, dentro le prove (`BancoRegnoTest`) | le righe stampate dalle prove: «SONDA-REGNO invarianti=13 mutanti_riferiti=13», «SONDA-REGNO-31 invarianti=10 mutanti_riferiti=10» | ventitré su ventitré riferiti col proprio codice; uno specchio esaustivo impone che ogni violazione futura abbia il suo mutante |
| Le prove nuove del pacchetto per le regole della tappa | ventuno mutanti dei SORGENTI, una riga cambiata alla volta in una copia del pacchetto esportata dal commit `b0a15f2`, e le 157 prove del regno e della seconda tappa eseguite a ogni mutante | `mutanti-dei-sorgenti.py`, `mutanti-dei-sorgenti.txt` | ventuno uccisi su ventuno, nessun sopravvissuto; senza mutanti le 157 prove passano. 343 s. Un mutante (il quattordicesimo) interrompe un fascio di prove con un errore fatale: il file lo dichiara |
| Lo stato della campagna in cui l'avversario prende i primi nomi liberi | la prova nuova `ArriviDallaPatriaTest.test_incarico_31_A_l_avversario_porta_gli_stessi_nomi_ogni_anno_e_le_reclute_non_li_ereditano`, scritta prima di cambiare la regola ed eseguita sul codice di `88d4874` | `nomi-fra-gli-anni-prima-della-correzione.txt` | quindici asserzioni fallite sui tre fronti. Vedi la nota in fondo a quel file: l'interfaccia non pronuncia mai il nome di un gruppo avversario, sicché non era un difetto udibile |
| Due cancelli che c'erano già, e che hanno colto due difetti della sessione | nessun mutante: sono falliti da sé alla prima esecuzione dell'intera suite | `due-cancelli-che-hanno-colto-difetti-della-sessione.txt` | `AccordoDiGenereTest` (una chiave di frase non scritta per esteso nel traduttore del regno) e il mutante dell'incarico 30 per l'entrata non conservata (assorbito per errore nell'invariante nuovo del mantenimento): corretto il codice, non i cancelli |
| Il limite di lunghezza della nota per i tester | nessun mutante: aggiunti i limiti noti, `controlla-note.py` ha rifiutato la nota a 4027 caratteri su 4000 | l'uscita è nel resoconto dell'incarico | accorciata; ora 3921 |

## Che cosa i mutanti dei sorgenti non coprono

- Le prove ospitate e quelle d'interfaccia: i mutanti girano sul solo pacchetto, senza simulatore. Che le prove ospitate della seconda tappa mordano lo dice soltanto il fatto che, cambiati i testi e i numeri della patria, cinque prove col tocco sono fallite finché non sono state adeguate.
- Le regole senza una riga propria da cambiare: per esempio la formazione rimasta vuota che sparisce, o l'impronta che distingue i campi nuovi. Le loro prove esistono e passano; non sono state viste fallire.
- Un mutante dice che ALMENO una prova coglie la riga cambiata, non che ogni prova che la riguarda lo faccia.

## Una correzione allo script, da dichiarare

Alla prima corsa lo script contava le prove eseguite prendendo il totale del fascio più grande (80) invece della somma: il numero era sbagliato, gli esiti no. Ora conta i casi avviati, passati e falliti, e dichiara quando un fascio si interrompe. Il file consegnato è quello della corsa definitiva, con ventuno mutanti.
