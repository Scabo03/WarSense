# Resoconto — L'élite storica di ciascuna fase, e le chiusure del corpo a corpo (incarico 11)

## Esito della verifica sugli archetipi (il cancello d'apertura)

**Superato: `guardia_elite` è uno dei nove dell'elenco chiuso, NON un archetipo di realizzazione. La sessione è proseguita.** Prove:

- Provenienza (git). Tutti e nove gli archetipi compaiono per la prima volta in `Codice/Sources/Contenuti/Valori/archetipi.json` nello STESSO commit `24458a0` (2026-08-02, «Modulo Dati»), verificato con `git log --reverse -S '"identificatore":"<id>"'` per ciascuno. Solo 3 commit hanno mai toccato `archetipi.json` (creazione + le due sessioni 10 e 11 sulle soglie): l'elenco degli identificatori non è mai stato allungato né accorciato dopo la creazione.
- Elenco chiuso (consolidati). `01 §3.2` (riga 109) elenca gli otto archetipi provvisori e nomina esplicitamente «guardia d'élite» come terzo. `01 §3.2.3` (riga 111): «l'elenco definitivo … conta nove archetipi. Ai otto del punto 3.2 si aggiunge la macchina da tiro» (RDA-28). Quindi i nove = gli otto di §3.2 (guardia d'élite compresa) + `macchina_tiro`.

I nove archetipi come risultano oggi dai dati (`archetipi.json`), tutti da `24458a0`: fanteria_leggera, fanteria_pesante, guardia_elite, tiratori, cavalleria_ricognizione, cavalleria_manovrata, piattaforma_trainata, macchina_assedio, macchina_tiro. Sono nove.

## Le due élite storiche, con le fonti

Individuate fra i nove esistenti, fondate sulla ricerca in cartella (`Fondamenta/04-riferimenti-storici.md`, il documento dedicato; `Deep research/tema-*.md`). Riferimenti verificabili riga per riga.

| fase | archetipo | fonte (citazione verificabile) |
|---|---|---|
| antica | `guardia_elite` (guardia d'élite / guardia scelta) | `01 §3.3:117` «la fanteria d'élite di tipo spartano e la guardia scelta di tipo persiano sono entrambe guardia d'élite»; `04:1175` «Gli Immortali: corpo scelto di 10.000, mantenuto a pieno organico»; `04:2279` la disciplina «come pratica di un solo popolo»; `04:2751` «Agoge spartana … documentato» |
| arcaica | `piattaforma_trainata` (il carro dei *maryannu*) | `04:607` «la corazza metallica è oggetto da principe, non da reparto»; `04:609` «La fase arcaica non ha una fanteria corazzata: ha individui corazzati»; `04:216`/`3122` maryannu ~10%, il carro «arma da urto mobile … arma di stato palaziale»; `04:642` il carro «richiedeva addestramento specializzato» |

L'indizio del titolare (poche corazze di bronzo a fronte delle molte in cuoio) è CONFERMATO dalla ricerca, ma con conclusione opposta a una fanteria pesante corazzata: nell'età del bronzo il metallo è «oggetto da principe» e l'élite combattente è l'aristocrazia sul carro, protetta di cuoio. Gli Immortali persiani, l'altra suggestione, sono la variante persiana della guardia d'élite (élite ANTICA), non arcaica. Caveat dichiarati dalla ricerca stessa: l'addestramento istituzionale del fante è «novità terminale» della fase antica (`04:2759`), e il tempo d'addestramento dell'uomo del carro non è quantificato (`04:962`, solo il requisito lo è). Le due élite sono archetipi DIVERSI, e la piattaforma è arcaica ma datata in antica: la condizione varia con la fase, quindi la rappresentazione è stata estesa.

## La rappresentazione archetipo-fase (RDA-92)

La battaglia non aveva concetto di fase (nessun passaggio campagna-battaglia). Aggiunti: enum `Fase` (arcaica/antica) in `Dati/Valori.swift`; `DefinizioneArchetipo.eliteFase: Fase?`; `ScenarioBattaglia.fase` e `StatoBattaglia.fase` (nell'impronta canonica, `Impronta.swift`). L'élite senza soglia è la coppia `eliteFase == stato.fase`, letta in `MotoreBattaglia.risolvi` e nella validazione di `.disingaggiaSuOrdine`. Non è una tabella a doppia entrata: un campo per archetipo (`elite_fase`) e uno per battaglia (`fase`), combinati per uguaglianza; la formula unica resta nel codice, i valori nei dati. Il caricatore rifiuta due archetipi élite della stessa fase (`errore.dati.elite_di_fase_duplicata`, cancello nuovo). `guardia_elite` riceve una soglia di banda 0,9 come ripiego per le fasi in cui non è élite (PROVVISORIA, non esercitata: antica-solo); `piattaforma_trainata` conserva 0,12 ed è élite solo in arcaica. La `fase` è una proprietà DICHIARATIVA dello scenario, non un ponte dalla campagna; assente nei salvataggi anteriori, la fabbrica assume l'antica. In antica il comportamento accettato dall'incarico 10 è invariato (guardia_elite élite, piattaforma 0,12): le misure della mischia in antica non cambiano.

Cancelli: `DisingaggioElitarioTest.test_incarico11_l_elite_dipende_dalla_fase` (piattaforma NON si sfila in arcaica, si sfila in antica; VISTO fallire di proposito nella logica del test — le due fasi danno esiti opposti) e `test_incarico11_l_elite_e_una_coppia_archetipo_fase_unica`.

## Le cinque decisioni del titolare

**D1 — La soglia non si dichiara (RDA-93, modifica voluta di 01 §9.8.1).** Verificato che oggi la soglia non è annunciata (`CostruttoreAnnunci.contenutoCella` non la legge). La prescrizione 01 §9.8.1 (soglia leggibile, da dichiarare) è ROVESCIATA per volontà del titolare, come modifica voluta e non svista, registrata in RDA-93 e S14. Cancello: `DesignazioneBersaglioTest.test_incarico11_l_elite_e_annunciata_e_la_soglia_no` accerta che l'annuncio di un reparto non contenga la soglia in alcuna forma (né 900, né 0,9).

**D2 — I nomi bastano a distinguere le tre fasce (verificato, dichiarato).** Poiché la soglia non si annuncia, chi ascolta distingue le fasce dal solo nome, che il gioco già dichiara: `tiratori`, `piattaforma trainata`, `macchina da tiro` dicono il tiro → fascia bassa (si sfila presto); `fanteria leggera`, `cavalleria ricognizione`, `cavalleria manovrata` dicono il tipo leggero/mobile → media; `fanteria pesante`, `macchina d'assedio` dicono il peso → alta. I nomi bastano per le tre fasce. Nessun annuncio nuovo per le fasce (l'élite, che il nome non sempre rende riconoscibile — la piattaforma arcaica —, ha l'annuncio proprio, D3).

**D3 — Il reparto élite è annunciato (RDA-94).** `CostruttoreAnnunci.contenutoCella` annuncia, per il reparto élite della fase corrente (proprio o avversario, prima di ingaggiare), il testo `battaglia.reparto_elite` = «reparto scelto: per l'addestramento superiore resta ai tuoi ordini anche in mischia». Testo nei file, manifest rigenerato; non è termine del vocabolario chiuso (02 §4.4.5 elenca stati, non tratti). La ragione comunicata è l'addestramento superiore, non la meccanica, e non la soglia. Cancello: `DesignazioneBersaglioTest.test_incarico11_l_elite_e_annunciata_e_la_soglia_no` (l'annuncio compare per l'élite, non per un reparto ordinario).

**D4 — Regola del secondo contatto confermata, interruttore rimosso (RDA-95).** `soglia_al_secondo_contatto` rimosso da `ParametriCombattimento`, da `combattimento.json`, dal Motore; la regola (01 §9.8.3) vale sempre. Rimossa la sezione di misura `secondo_contatto` dal programma di verifica. Cancello: `MisuraMischiaTest.test_incarico11_il_secondo_contatto_combatte_fino_alla_dispersione` (una coppia già staccata non si sfila più, uno dei due è distrutto).

**D5 — Scorrimento anticipato della mappa accettato (RDA-96, S12).** Trasformato da scostamento aperto (S12) in costo dichiarato e accettato, con la ragione del titolare. Nessun codice toccato.

## Le cose piccole rimaste indietro

- **Formato quindici.** Verificato: il gioco (Applicazione) non usa mai il formato `quindici` (solo gli scenari di verifica lo usano). `PartitaCorrente` legge un unico scenario di prova (`cento`). Instanziare `quindici` in una prova d'INTERFACCIA richiederebbe un'iniezione di scenario che servirebbe SOLO al collaudo, ed è vietata (nessun canale di sola misura). Perciò l'aggancio NON è stato aggiunto. Il formato è verificato al Motore (`scontro_quindici`, `SessioniCompleteTest` headless); la disposizione della griglia è generica ed è provata sul formato `cento`; la resa a quattro per quattro dell'interfaccia resta verificabile solo a mano su dispositivo. Dichiarato in S14.
- **Intermittenza delle sessioni complete.** Misurata in isolamento: **25 esecuzioni parallele** di `VerificaTest/SessioniCompleteTest` (comando `xcrun xctest -XCTest VerificaTest/SessioniCompleteTest <bundle>`, `xargs -P 8`), tutte con codice di uscita 0 e zero fallimenti (25 su 25 con «0 failures»). Numero dichiarato sufficiente e motivato: il test è deterministico (nessuna estrazione del caso, RDA-59), quindi ogni intermittenza sarebbe ambientale; 25 esecuzioni indipendenti a varianza nulla la escludono. Nessuna intermittenza emersa.
- **Altezza minima della griglia.** Verificato il valore IMPOSTO dal controllo (quello che protegge): `SchermataBattaglia.altezzaMinimaGriglia = 120`, vincolo `scorrimento.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)` (identico `SchermataMappaCampagna.altezzaMinimaMappa = 120`). Il minimo imposto è **120 punti**. Un resoconto anteriore aveva accostato a questo la porzione visibile MISURATA, che è un risultato e non il minimo imposto: la grandezza che protegge è 120.

## Versione dei valori e salvataggi

Valutazione esplicita (richiesta): la versione dei valori VA incrementata, da 0.6.0 a **0.7.0**, `versioni_compatibili` = `["0.7.0"]`. Cambia il reparto élite (piattaforma élite in arcaica) e il formato dello stato (campo `fase`): un salvataggio 0.6.0 rigiocato ricostruirebbe uno stato diverso. È dichiarato incompatibile e la ripresa lo rifiuta con `salvataggioIncompatibile` invece di aprirlo (cancello `SalvataggioBuildDistribuitaTest`). Impronte e copioni d'oro rigenerati a 0.7.0 (`RigenerazioneOroTest`).

## Collaudo e caricamento

Collaudo del pacchetto verde: **250 prove**, 1 saltata, 0 fallimenti (`swift test`). Prove d'interfaccia sul simulatore incluse (`scripts/collaudo-completo.sh`).

<!-- SEZIONE CARICAMENTO DA COMPLETARE -->

## Registrazioni

ADR: RDA-92 (due élite e rappresentazione archetipo-fase, con fonti), RDA-93 (soglia non dichiarata, modifica voluta di 01 §9.8.1), RDA-94 (annuncio del reparto élite), RDA-95 (secondo contatto confermato, interruttore rimosso), RDA-96 (scorrimento anticipato accettato). Scostamenti: S14 (le divergenze dell'incarico 11) e S12 aggiornato ad accettato. Valori provvisori: la banda di ripiego 0,9 di guardia_elite, l'assegnazione `elite_fase`, la rimozione del flag, la versione 0.7.0.

## Aritmetica

Il conteggio delle prove (250) viene dal riepilogo di `swift test`. Il conteggio delle esecuzioni delle sessioni (25 su 25 verdi) viene dal conteggio dei file di log con «0 failures». Le citazioni della ricerca sono trascrizioni con numero di riga, verificabili aprendo il file. Nessuna somma a mente.

## Che cosa ho fatto e l'incarico non chiedeva

- Ho aggiunto un cancello di caricamento nuovo (`errore.dati.elite_di_fase_duplicata`): il caricatore rifiuta due archetipi élite della stessa fase, per rendere impossibile lo stato sbagliato.

## Che cosa l'incarico chiedeva e non ho fatto

- La prova d'interfaccia del formato `quindici` non è realizzata, per la ragione dichiarata (l'aggancio servirebbe solo al collaudo ed è vietato); dichiarato come e perché il formato è comunque verificato altrove.

## Che cosa non ho toccato

Non ho introdotto alcun archetipo nuovo (l'elenco resta chiuso a nove). Non ho ritarato soglie, coefficienti o valori del combattimento (guardia_elite conserva in antica il comportamento accettato). Non ho annunciato la soglia né alcuna grandezza di quanto manchi a cedere. Non ho introdotto termini nel vocabolario chiuso. Non ho corretto lo scorrimento anticipato. Non ho riaperto decisioni prese. Non ho esteso il perimetro (la `fase` è proprietà dichiarativa dello scenario, non un ponte campagna-battaglia). Non sono intervenuto sulla cornice dell'accessibilità né sulla prova di raggiungibilità. Non ho toccato la versione di marketing né alcun certificato.
