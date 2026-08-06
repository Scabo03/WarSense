# Resoconto — Misura del corpo a corpo (incarico 09)

## Tabella per accoppiamento — turni per la distruzione accanto ai turni per scattare la soglia

Legenda. Ogni cella è `Tσ/Td` del **bersaglio** (colonna), sotto l'**attaccante** (riga),
a **soglia di disingaggio disattivata**. `Tσ` = `turni_soglia_bersaglio`: lo scambio in cui il
bersaglio raggiunge la PROPRIA soglia di disingaggio reale (quello in cui, a soglia attiva, si
sfilerebbe). `Td` = `turni_distruzione_bersaglio`: lo scambio in cui il bersaglio è distrutto.
`0` significa «non avviene»: `0/0` = il bersaglio non raggiunge mai la propria soglia né viene
distrutto, cioè vince lui e l'attaccante cade prima. Uno «scambio» è una risoluzione di mischia:
il primo è l'ingaggio, che si risolve all'istante (01 §9.7.1); i successivi sono le risoluzioni
d'inizio giro (01 §9.7). Abbreviazioni: `c.man` cavalleria_manovrata, `c.ric`
cavalleria_ricognizione, `f.leg` fanteria_leggera, `f.pes` fanteria_pesante, `guar`
guardia_elite, `m.ass` macchina_assedio, `m.tir` macchina_tiro, `piat` piattaforma_trainata,
`tira` tiratori.

Numeri prodotti da `StrumentoVerifica`, sezione `mischia_accoppiamenti` (colonne
`turni_soglia_bersaglio`, `turni_distruzione_bersaglio`, `vincitore`), comando
`swift run -c release StrumentoVerifica --senza-campagna --uscita <dir>`; le due matrici sono la
riscrittura meccanica (script Python su `mischia_accoppiamenti.csv`, nessun ricalcolo) delle 162
righe. Le sezioni della mischia sono identiche sotto la corsa completa `swift run -c release
StrumentoVerifica --uscita <dir>` (verificato con `diff`).

### Protezione anti_saturazione — Tσ / Td del bersaglio (riga = attaccante, col = bersaglio)

| att\ber | c.man | c.ric | f.leg | f.pes | guar | m.ass | m.tir | piat | tira |
|---|---|---|---|---|---|---|---|---|---|
| **c.man** | 3/16 | 2/6 | 2/8 | 0/0 | 0/0 | 0/0 | 2/11 | 2/11 | 1/5 |
| **c.ric** | 0/0 | 4/29 | 4/0 | 0/0 | 0/0 | 0/0 | 4/0 | 6/0 | 2/13 |
| **f.leg** | 4/0 | 2/9 | 2/20 | 0/0 | 0/0 | 0/0 | 3/18 | 3/0 | 2/7 |
| **f.pes** | 2/6 | 1/4 | 1/5 | 5/14 | 0/0 | 2/0 | 1/6 | 2/5 | 1/4 |
| **guar** | 2/5 | 1/3 | 1/4 | 4/8 | 8/13 | 2/0 | 1/6 | 2/4 | 1/3 |
| **m.ass** | 1/2 | 1/2 | 1/2 | 2/3 | 3/4 | 1/10 | 1/3 | 1/3 | 1/2 |
| **m.tir** | 0/0 | 5/23 | 5/0 | 0/0 | 0/0 | 0/0 | 5/64 | 8/0 | 3/15 |
| **piat** | 5/0 | 3/10 | 3/22 | 0/0 | 0/0 | 0/0 | 3/20 | 4/28 | 2/8 |
| **tira** | 0/0 | 9/0 | 0/0 | 0/0 | 0/0 | 0/0 | 8/0 | 0/0 | 3/41 |

### Protezione anti_perforazione — Tσ / Td del bersaglio (riga = attaccante, col = bersaglio)

| att\ber | c.man | c.ric | f.leg | f.pes | guar | m.ass | m.tir | piat | tira |
|---|---|---|---|---|---|---|---|---|---|
| **c.man** | 2/14 | 2/6 | 2/8 | 0/0 | 0/0 | 3/0 | 2/10 | 2/10 | 1/5 |
| **c.ric** | 0/0 | 3/23 | 3/0 | 0/0 | 0/0 | 0/0 | 3/0 | 4/0 | 2/10 |
| **f.leg** | 3/0 | 2/8 | 2/16 | 0/0 | 0/0 | 0/0 | 2/13 | 3/16 | 1/6 |
| **f.pes** | 2/9 | 2/5 | 2/7 | 6/19 | 0/0 | 3/0 | 2/9 | 2/8 | 1/5 |
| **guar** | 2/6 | 1/4 | 1/5 | 4/9 | 11/16 | 2/0 | 2/7 | 2/5 | 1/4 |
| **m.ass** | 2/5 | 1/4 | 1/4 | 4/7 | 6/9 | 2/19 | 1/6 | 2/5 | 1/3 |
| **m.tir** | 0/0 | 5/37 | 5/0 | 0/0 | 0/0 | 0/0 | 5/64 | 8/0 | 3/16 |
| **piat** | 5/0 | 3/12 | 3/0 | 0/0 | 0/0 | 0/0 | 3/20 | 4/28 | 2/8 |
| **tira** | 0/0 | 7/0 | 0/0 | 0/0 | 0/0 | 0/0 | 6/0 | 0/0 | 3/33 |

### Vincitore del duello a soglia disattivata (`A` = attaccante, `B` = bersaglio, `=` reciproca)

Protezione anti_saturazione a sinistra, anti_perforazione a destra: le due tabelle coincidono
salvo `f.leg`→`piat` e `piat`→`f.leg`. Colonna `vincitore` della sezione `mischia_accoppiamenti`.

| att\ber | c.man | c.ric | f.leg | f.pes | guar | m.ass | m.tir | piat | tira |
|---|---|---|---|---|---|---|---|---|---|
| **c.man** | = | A | A | B | B | B | A | A | A |
| **c.ric** | B | = | B | B | B | B | B | B | A |
| **f.leg** | B | A | = | B | B | B | A | B/A | A |
| **f.pes** | A | A | A | = | B | B | A | A | A |
| **guar** | A | A | A | A | = | B | A | A | A |
| **m.ass** | A | A | A | A | A | = | A | A | A |
| **m.tir** | B | A | B | B | B | B | = | B | A |
| **piat** | B | A | A/B | B | B | B | A | = | A |
| **tira** | B | B | B | B | B | B | B | B | = |

Lettura del confronto, per ciascun accoppiamento (il confronto `Tσ` contro `Td` è la grandezza
richiesta). Dove entrambi sono positivi, `Tσ < Td` sempre: il bersaglio raggiunge la propria
soglia di disingaggio **prima** di poter essere distrutto. Sulla diagonale (stesso archetipo,
duello simmetrico): `f.pes` vs `f.pes` `5/14`, `guar` vs `guar` `8/13`, `m.tir` vs `m.tir`
`5/64`, `tira` vs `tira` `3/41`, `c.man` vs `c.man` `3/16`. Dove `Td = 0` con `Tσ > 0` (es.
`c.ric`→`f.leg` `4/0`) il bersaglio raggiunge la soglia ma non viene mai distrutto perché
l'attaccante cade prima. Dove `Tσ = 0` (le 47 celle `0/…` con vincitore `B`) il bersaglio vince il
duello senza mai raggiungere la propria soglia. Quando `Tσ` e `Td` sono entrambi positivi, `Tσ` è
SEMPRE strettamente minore di `Td` (verificato su tutte le righe): non esiste un accoppiamento in
cui la soglia scatti dopo la distruzione o insieme a essa. Il conteggio: in **115** accoppiamenti
su **162** la soglia scatta
STRETTAMENTE prima della distruzione (`accoppiamenti_soglia_scatta_prima_della_distruzione`,
blocco `mischia_riepilogo`); il divario `Td − Tσ` ha minimo 1, mediana 5, massimo 59
(`divario_soglia_distruzione_*`).

---

## Come è stata presa la misura

Strumento: il programma di verifica `StrumentoVerifica` (bersaglio SwiftPM, RDA-10), che gioca
sugli stessi binari del gioco (Motore, tattico del Motore, esiti del Motore). Nessuna regola
nuova vive nella misura. Comando canonico:
`cd Codice && swift run -c release StrumentoVerifica --senza-campagna --uscita <dir>`. Produce fra
gli altri i file `mischia_accoppiamenti.csv`, `mischia_fotografia.csv`,
`mischia_modificatori_congiunti.csv`, `provenienza_perdite.csv`, `mischia_riepilogo.csv`. Il
blocco unico dei numeri destinati al resoconto è `mischia_riepilogo`; la prova
`MisuraMischiaTest.test_incarico09_il_riepilogo_mischia_pareggia_con_le_righe_di_dettaglio`
pareggia ogni suo totale con le righe di dettaglio (RDA-71). Ogni cifra citata qui viene da quel
blocco, salvo quelle esplicitamente dichiarate come riscrittura o aggregazione della sezione di
dettaglio.

Codice aggiunto, tutto nel bersaglio `Verifica`, commit `f9bbea3`:
`Sources/Verifica/MisuraMischia.swift` (estensione di `BanchiDiMisura` con `corseMischia` /
`CorsaMischia` / `mischiaAccerchiata` / `MischiaAccerchiata`, e il tipo `ProvenienzaBattaglia`);
`Sources/Verifica/ValoriVariati.swift` (aggiunto `SostituzioneInElenco`, `disingaggioDisattivato`,
la variante `carica(base:sostituendo:inElenco:)`); `Sources/Verifica/ProgrammaDiVerifica.swift`
(`sezioniMischia`, `provenienzaDiTutteLeBattaglie`, `riepilogoMischia`);
`Tests/VerificaTest/MisuraMischiaTest.swift` (6 prove). Nessuna modifica a Motore, Dati, Contenuti
o ai file di dati. Nessun canale che esista soltanto per la misura: la provenienza legge la
variazione di `StatoBattaglia.perditeSubite` (RDA-46) e gli eventi `EventoBattaglia.sciameDisfatto`
che il gioco produce.

### Come è realizzata la disattivazione della soglia

È un parametro dello scenario del programma di verifica, mai stato del Motore né canale che il
gioco possa attraversare. `ValoriVariati.disingaggioDisattivato` è una `SostituzioneInElenco` che
porta il campo `soglia_disingaggio` a `1.0` in OGNI elemento di `archetipi.json`, dentro una
cartella di valori **temporanea** derivata da quella di fabbrica; la cartella passa dal caricatore
vero (`CaricatoreValori.carica`) con la sua validazione (05 §7.8), che ammette la soglia
nell'intervallo `(0, 1]`: `1.0` è l'estremo ammesso, un valore maggiore verrebbe respinto. A
`1.0` il ramo di disingaggio in `MotoreBattaglia.risolvi` (guardia
`perdite*1000/ingresso >= soglia`) non scatta mai, perché uno sciame vivo ha sempre
`serbatoio > 0` e quindi `perdite/ingresso < 1`, e chi arriva a `serbatoio = 0` è già stato
rimosso da `applicaDanno` prima del controllo. Il Motore non ha ricevuto alcun parametro nuovo: la
disattivazione è interamente nei valori derivati, e la fabbrica su disco resta intatta (verificato
da `test_incarico09_disingaggio_disattivato_porta_la_soglia_a_uno`, che rilegge la fabbrica e ne
ritrova le soglie originali, tutte minori di 1). La misura era quindi realizzabile senza toccare
il Motore, e non è stato toccato.

Regime dei numeri. La **fotografia** (primo punto) è presa a **soglia attiva**, cioè con i valori
di fabbrica, che è il regime del gioco distribuito. La **crux** (secondo punto), la **distruzione**
(terzo) e i **modificatori congiunti** (quinto) sono presi a **soglia disattivata**. `Tσ`, pur
osservato a soglia disattivata, usa la soglia REALE di ciascun archetipo, passata a parte a
`corseMischia(soglieReali:)` perché a soglia disattivata i valori del Motore la portano a 1,0 e
non la si potrebbe più leggere dallo stato.

Convenzione dell'accoppiamento. Come nei duelli esistenti (`BanchiDiMisura.duelli`), i due reparti
di ogni corsa hanno la STESSA protezione, e la protezione è un asse a due valori: gli accoppiamenti
sono 2 × 9 × 9 = 162. La protezione del bersaglio è ciò che determina l'efficacia della mischia
dell'attaccante (01 §9.9); la protezione dell'attaccante determina ciò che l'attaccante subisce.
Nessun accoppiamento è un buco: `test_incarico09_ogni_accoppiamento_fra_tipi_di_reparto_compare`
verifica che tutte e 162 le terne compaiano.

---

## Primo — la fotografia di ciò che accade oggi (soglia attiva)

Sezione `mischia_fotografia`; conteggi dal blocco `mischia_riepilogo`.

- Accoppiamenti generati: **162** (`accoppiamenti_totali`).
- Finiscono per **disingaggio**: **154** (`fotografia_disingaggio`).
- Finiscono per **distruzione**: **8** — di cui `disfatta_bersaglio` **4**
  (`fotografia_disfatta_bersaglio`), `disfatta_attaccante` **4**
  (`fotografia_disfatta_attaccante`), `disfatta_reciproca` **0**. Tutti e 8 coinvolgono
  `macchina_assedio` (righe `disfatta_*` di `mischia_fotografia.csv`): `macchina_assedio` che
  distrugge `cavalleria_manovrata`, `cavalleria_ricognizione`, `fanteria_leggera`, `tiratori`
  entro il secondo scambio; e gli stessi quattro reparti che, attaccando `macchina_assedio`,
  cadono per la sua contromischia (`disfatta_attaccante`).
- Ancora **in corso al tetto** quando la corsa si chiude: **0** (`fotografia_tetto`).
- Durata di un contatto, in scambi (l'ingaggio conta 1): minimo **2**, mediana **2**, massimo
  **11**, media **2** (aritmetica intera troncata) — `contatto_scambi_minimo/mediana/massimo/media`.
- Frazione della consistenza iniziale persa dal reparto che si disingaggia, all'atto in cui si
  sfila, in millesimi: minimo **202**, mediana **377**, massimo **916**, media **422**
  (`disingaggio_perdite_permille_*`). Il massimo 916‰ è la coppia `macchina_assedio` ↔
  `piattaforma_trainata` (riga di `mischia_fotografia.csv`): chi si sfila perde il 91,6% nei due
  scambi che precedono il disingaggio d'inizio giro, perché lo scambio di `macchina_assedio` è
  enorme; il minimo 202‰ è `tiratori` vs `tiratori`.

Nota sulla premessa dell'incarico. L'incarico riporta una misura precedente per cui «162 duelli su
162 finiscono per disingaggio, nessuno per distruzione». Non ho ritrovato il testo di quella misura
in `registro-scostamenti.md`, negli `Incarichi/`, né in `valori-provvisori.md`: lo dichiaro non
verificato alla fonte. Il numero 162 coincide con 2 × 9 × 9, cioè con l'insieme che
`BanchiDiMisura.duelli` genera. La misura di oggi dà **154/162** per disingaggio e **8/162** per
distruzione: la premessa è quindi quasi esatta ma non del tutto, e gli 8 casi di distruzione sono
tutti di `macchina_assedio`, il cui singolo scambio a piena consistenza supera il serbatoio dei
reparti più leggeri prima che il controllo del disingaggio possa operare (che è d'inizio giro, cioè
dal secondo scambio: 01 §9.8.2).

---

## Secondo — la crux, per accoppiamento (soglia disattivata)

I quattro numeri per accoppiamento sono nella sezione `mischia_accoppiamenti`, righe (colonne
`inflitto_primo_scambio`, `inflitto_primo_scambio_permille_bersaglio`, `soglia_bersaglio_permille`,
`turni_soglia_bersaglio`, `turni_distruzione_bersaglio`, `soglia_scatta_prima`, `divario`). La
tabella in testa ne dà `Tσ` e `Td`; il danno per turno come frazione della consistenza del
bersaglio è `inflitto_primo_scambio_permille_bersaglio` (danno del primo scambio, a piena
consistenza, in millesimi del serbatoio d'ingresso del bersaglio). Esempi (anti_saturazione):
`fanteria_pesante`→`fanteria_pesante` infligge 152 su 700 = 217‰ per scambio, soglia del bersaglio
600‰, `Tσ = 5`, `Td = 14`; `guardia_elite`→`guardia_elite` 177 su 750 = 236‰, soglia 800‰,
`Tσ = 8`, `Td = 13`.

Il confronto `Tσ` contro `Td`, dichiarato per ogni accoppiamento nella tabella in testa, è
riassunto dal blocco: **115/162** accoppiamenti hanno la soglia che scatta strettamente prima
della distruzione (`accoppiamenti_soglia_scatta_prima_della_distruzione`), con divario minimo 1,
mediano 5, massimo 59. I restanti 47 sono tutti e soli i casi in cui il bersaglio non raggiunge mai
la propria soglia perché vince il duello (`Tσ = 0`, vincitore `bersaglio`); non esiste alcun
accoppiamento in cui la soglia scatti nello stesso scambio della distruzione o dopo (verificato).

---

## Terzo — i casi che oggi non si verificano mai (soglia disattivata)

Rifatte le stesse corse per accoppiamento con la soglia disattivata (parametro dello scenario di
verifica, come sopra). Conteggi dal blocco `mischia_riepilogo`, colonna `vincitore` di
`mischia_accoppiamenti`:

- Bersaglio distrutto (vince l'attaccante): **72** (`distruzione_bersaglio_conteggio`).
- Attaccante distrutto (vince il bersaglio): **72** (`distruzione_attaccante_conteggio`).
- Distruzione reciproca: **18** (`distruzione_reciproca_conteggio`) — sono i 9 accoppiamenti sulla
  diagonale per 2 protezioni.
- Ancora al tetto (`tettoScambiMischia` = 1200): **0** (`distruzione_tetto_conteggio`).

La prova `test_incarico09_il_riepilogo_mischia_pareggia_con_le_righe_di_dettaglio` pareggia la
somma di questi quattro con le 162 righe; la prova
`test_incarico09_soglia_disattivata_nessun_disingaggio` accerta che a soglia disattivata nessuna
corsa finisca per disingaggio e nessuna resti al tetto.

Distinzione dei due difetti opposti che l'incarico chiede di separare. **Zero** accoppiamenti
restano al tetto: la distruzione è sempre raggiungibile entro il tetto, quindi il difetto «si
infliggono così poche perdite che nessuna mischia potrebbe concludersi comunque» NON si dà — la
mischia PUÒ concludersi per distruzione, in un numero di scambi finito e misurato (matrice `Td`).
Ciò che a soglia attiva non la fa concludere è che la soglia scatta prima (115/162 strettamente
prima; nei restanti la distruzione avviene ma per un solo scambio così violento da precedere o
pareggiare il momento della soglia). Non traggo la conseguenza sul rimedio: è decisione del
titolare.

---

## Quarto — il quadro d'insieme (provenienza delle perdite)

Perimetro dichiarato di «tutte le battaglie generate»: le **80** battaglie che il programma gioca —
48 scontri (i 3 scenari di `scontro-*.json`, tutte le configurazioni, sotto i due regimi dei
vantaggi nascosti come nel resto del rapporto) più le 32 sessioni complete di battaglia
(`composizioniDiMazzo` × primo occupante × 2 ufficiali × imboscata). Sezione `provenienza_perdite`,
una riga per battaglia; totali dal blocco `mischia_riepilogo`.

- Battaglie generate: **80** (`battaglie_generate_totali`).
- Perdite totali: **193862** punti vita (`perdite_totali`); da **tiro** 65204 = **336‰**
  (`perdite_da_tiro_totali`, `perdite_da_tiro_permille`); da **mischia** 128658 = **663‰**
  (`perdite_da_mischia_totali`, `perdite_da_mischia_permille`). I due millesimi non sommano a 1000
  perché troncati per difetto; i due totali interi sommano a `perdite_totali` (pareggio nella
  prova). I totali sommano le perdite di entrambe le parti; la sezione di dettaglio ha le colonne
  per parte (`perdite_tiro_giocatore/avversario`, `perdite_mischia_giocatore/avversario`).
- Battaglie concluse senza che alcun contatto abbia prodotto una distruzione: **19**
  (`battaglie_senza_distruzione_in_mischia`); con almeno una distruzione in mischia: **61**
  (`battaglie_con_distruzione_in_mischia`).

Ripartizione per famiglia (aggregata dallo script Python su `provenienza_perdite.csv`, NON dal
blocco di riepilogo; il totale coincide con il blocco per costruzione e per la prova di pareggio):
scontri 48 battaglie (tutte concluse), tiro 49110 = 365‰, mischia 85375 = 634‰, 7 senza
distruzione in mischia; sessioni 32 battaglie (24 concluse, 8 non concluse entro `giri_massimi`),
tiro 16094 = 271‰, mischia 43283 = 728‰, 12 senza distruzione in mischia.

Osservazione (non un rimedio). Nelle battaglie intere la mischia è la fonte MAGGIORE delle perdite
(663‰ complessivo) e produce distruzioni in 61 battaglie su 80: il fatto che «nessuna mischia si
concluda con una distruzione» vale per il duello isolato uno-contro-uno (154/162 per disingaggio),
non per la battaglia, dove più assalitori concentrati distruggono grazie ai due modificatori (punto
quinto). Riporto il dato; non deduco che cosa cambiare.

---

## Quinto — i due modificatori, misurati insieme (soglia disattivata)

Sezione `mischia_modificatori_congiunti`: da 1 a 4 assalitori identici
(`fanteria_pesante`, protezione `anti_saturazione`) contro un bersaglio identico. Misura la
maggiorazione di accerchiamento (01 §9.10.2) e il limite dei bersagli simultanei (01 §9.11)
insieme, mai presi congiuntamente prima.

| assalitori | coeff. accerchiamento ‰ | inflitto 1° giro | subito 1° giro | rapporto ‰ | scambi per distruggere | bersaglio giù al 1° giro |
|---|---|---|---|---|---|---|
| 1 | 1000 | 243 | 243 | 1000 | 14 | no |
| 2 | 1080 | 557 | 287 | 1940 | 3 | no |
| 3 | 1320 | 700 | 242 | 2892 | 2 | sì |
| 4 | 1720 | 700 | 197 | 3553 | 1 | sì |

Lettura. I due lavorano nella stessa direzione e si sommano: crescendo gli assalitori il
coefficiente di accerchiamento sale (1000→1720‰), l'inflitto al bersaglio sale (243→700), mentre il
subito dagli assalitori smette di crescere dopo il secondo e poi CALA (287→242→197), perché dal
terzo posto in mischia il bersaglio non risponde più (limite dei bersagli) e perché il bersaglio
muore prima. L'esito del contatto passa da **14 scambi** per distruggere il bersaglio uno-contro-uno
a **1 scambio** con quattro assalitori (`accerchiamento_scambi_distruzione_uno_assalitore` = 14,
`accerchiamento_scambi_distruzione_massimo_assalitori` = 1). La prova
`test_incarico09_accerchiamento_e_limite_bersagli_si_sommano` è il cancello: rifiuta lo stato in cui
il coefficiente non cresce o gli scambi per distruggere non calano con gli assalitori.

---

## Che cosa mostrano i numeri (senza rimedio)

Dichiaro ciò che i numeri mostrano, non che cosa andrebbe cambiato. (1) Nel duello isolato la
soglia di disingaggio scatta prima della distruzione in 115 accoppiamenti su 162, con divario
mediano 5 scambi; e la distruzione è sempre raggiungibile a soglia disattivata (0 al tetto): il
motivo per cui i duelli finiscono per disingaggio non è che le perdite siano troppo poche, ma che
la soglia le precede. (2) La fanteria pesante contro la fanteria pesante si sfila a `Tσ = 5` e
sarebbe distrutta solo a `Td = 14`: nel duello non può vincere, solo sopravvivere sfilandosi. (3)
Nella battaglia intera, però, la mischia è la fonte maggiore delle perdite (663‰) e distrugge in 61
battaglie su 80, tramite l'accerchiamento che comprime la distruzione da 14 a 1 scambio. La scelta
fra alzare il danno della mischia, alzare le soglie, cambiarne il calcolo o intervenire altrove è
del titolare, e non la presento come conseguenza tecnica dei numeri.

---

## Contraddizioni, letture, buchi, e ciò che non è verificato

- La premessa «162/162 per disingaggio» dell'incarico: non ritrovata alla fonte scritta (dichiarato
  non verificato); la misura di oggi dà 154/162, con 8 distruzioni tutte di `macchina_assedio`.
- «Turno» è stato inteso come «scambio di mischia»: l'ingaggio (risoluzione immediata) è lo scambio
  1, ogni risoluzione d'inizio giro è uno scambio successivo. Il confronto `Tσ`/`Td` e tutti i
  turni sono nella stessa unità, quindi confrontabili; la corrispondenza con i «turni» di giocatore
  (due turni per giro) non è stata riportata come colonna.
- La ripartizione per famiglia della provenienza (§ quarto) è aggregata dallo script Python sulla
  sezione di dettaglio, non stampata nel blocco di riepilogo: dichiarata come tale nel punto in cui
  compare. I soli totali complessivi vengono dal blocco.
- Nessun accoppiamento fra tipi di reparto è un buco: tutte e 162 le terne compaiono (prova
  dedicata). Non esistono coppie non provate da dichiarare.
- Nessun numero richiesto dall'incarico è risultato non ottenibile senza modificare il gioco: la
  disattivazione della soglia era ottenibile come valori derivati, e lo è stata.

## Aritmetica

Ogni totale del resoconto viene dal blocco `mischia_riepilogo`, sommato dal programma e pareggiato
con le righe di dettaglio dalla prova
`test_incarico09_il_riepilogo_mischia_pareggia_con_le_righe_di_dettaglio` (RDA-71). Le celle delle
matrici sono trascrizione riga-per-riga di `mischia_accoppiamenti.csv` via script; la ripartizione
per famiglia è aggregazione via script di `provenienza_perdite.csv`. Nessuna somma è stata fatta a
mente.

## Che cosa ho fatto e l'incarico non chiedeva

- Ho misurato la provenienza delle perdite anche sui 48 scontri del banco, oltre che sulle 32
  sessioni di battaglia, per coprire «tutte le battaglie generate» senza omissioni; ho dato la
  ripartizione per famiglia oltre al totale.
- Ho reso la disattivazione della soglia una capacità generale di `ValoriVariati`
  (`SostituzioneInElenco`: sostituzione di un campo in ogni elemento di un file-elenco), riusabile
  per future misure, anziché un accorgimento locale.

## Che cosa l'incarico chiedeva e non ho fatto

- Nessuna voce: i cinque punti sono tutti prodotti dal programma, con blocco di riepilogo e prova di
  pareggio. (Elenco dichiarato non vuoto solo se emergesse un'omissione; qui è vuoto.)

## Che cosa non ho toccato

Non ho corretto, tarato o modificato alcuna formula, coefficiente, soglia o file di dati. Non ho
toccato il Motore, i Dati, i Contenuti. Non ho aggiunto al gioco alcun canale di sola misura. Non
ho esteso il perimetro del gioco. Non sono intervenuto sull'accessibilità né sulla prova di
raggiungibilità. Non ho caricato alcuna build, non ho toccato versioni né certificati. Non ho
riaperto decisioni prese (ordine dei turni, risoluzione immediata del contatto, limite dei bersagli,
perdita di controllo del reparto ingaggiato, assenza di fuoco amico).

## Stato del ramo

Ramo dedicato `misura-corpo-a-corpo`, commit `f9bbea3`. Suite intera verde: 242 prove XCTest, 1
saltata, 0 fallimenti (`swift test`); erano 236 prima di questa sessione. Portato su `principale`
solo a suite verde.
