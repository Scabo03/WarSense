# Build caricate su TestFlight

Registro delle build. Esiste perché la catena fra il progetto e i server di Apple
è l'unica che nessun controllo interno poteva verificare, e il 2026-08-05 se ne è
avuta la prova: la **build 13** era su App Store Connect e nessun documento del
progetto la registrava — `esame-critico.md` §4.1 e il resoconto della sessione
precedente dicevano entrambi che l'ultima fosse la 12.

**Le righe si aggiungono da sé.** `scripts/carica-testflight.sh` appende qui la
riga a caricamento riuscito, e `scripts/controlla-build.py` rifiuta il caricamento
successivo se questo registro e App Store Connect non concordano. Non si scrive a
mano: il passo umano è precisamente quello che è mancato.

**La colonna del commit.** Per le build da 1 a 13 è RICOSTRUITA dal confronto fra
l'istante di caricamento letto per interfaccia di programmazione e la cronologia
del versionamento: è l'ultimo commit precedente il caricamento, che è ciò da cui
lo script produce l'archivio. Non è una registrazione dell'epoca e non va usata
come tale. Dalla 14 in poi la riga è scritta dallo script al momento stesso.

| build | caricata (UTC) | treno | commit | come si sa |
|---|---|---|---|---|
| 1 | 2026-08-02 20:48:12 | 1.0 | `0690b58` | ricostruita |
| 2 | 2026-08-03 07:14:51 | 1.0 | `d5cfb44` | ricostruita |
| 3 | 2026-08-03 07:19:06 | 0.2.0 | `d5cfb44` | ricostruita |
| 4 | 2026-08-03 09:37:58 | 0.2.0 | `ac87d1c` | ricostruita |
| 5 | 2026-08-03 14:02:46 | 1.1.0 | `8edf8ec` | ricostruita |
| 6 | 2026-08-03 14:47:53 | 1.1.0 | `e21974f` | ricostruita |
| 7 | 2026-08-04 11:34:52 | 1.1.0 | `3fd54b6` | ricostruita |
| 8 | 2026-08-04 12:22:56 | 1.1.0 | `75a133e` | ricostruita |
| 9 | 2026-08-04 13:02:33 | 1.1.0 | `bfd9eb3` | ricostruita |
| 10 | 2026-08-04 16:05:03 | 1.1.0 | `71db5e6` | ricostruita |
| 11 | 2026-08-04 18:30:31 | 1.1.0 | `3298e86` | ricostruita |
| 12 | 2026-08-04 20:23:41 | 1.1.0 | `f16e409` | ricostruita |
| 13 | 2026-08-05 07:50:41 | 1.1.0 | `6c2829d` | ricostruita, e **accertata**: vedi sotto |
| 14 | 2026-08-05 12:03:51 | 1.1.0 | `d9a5c82` | ricostruita |
| 15 | 2026-08-06 08:58:48 | 1.1.0 | `2b8e87a` | scritta dallo script al caricamento |
| 16 | 2026-08-06 13:46:47 | 1.1.0 | `020d10e` | scritta dallo script al caricamento |
| 17 | 2026-08-06 19:27:36 | 1.1.0 | `bcf34e4` | scritta dallo script al caricamento |
| 18 | 2026-08-06 21:15:54 | 1.1.0 | `cf610ae` | scritta dallo script al caricamento |
| 19 | 2026-08-07 08:10:38 | 1.1.0 | `33f8246` | scritta dallo script al caricamento |
| 20 | 2026-08-07 10:49:54 | 1.1.0 | `15f30a2` | scritta dallo script al caricamento |
| 21 | 2026-08-08 10:27:48 | 1.1.0 | `33599e0` | scritta dallo script al caricamento |
| 22 | 2026-08-08 18:10:21 | 1.1.0 | `566f713` | scritta dallo script al caricamento |
| 23 | 2026-08-10 11:52:52 | 1.1.0 | `86e442d` | scritta dallo script al caricamento |
| 24 | 2026-08-10 14:04:49 | 1.1.0 | `2a0e9c1` | scritta dallo script al caricamento |
| 25 | 2026-08-11 10:46:22 | 1.1.0 | `e231690` | scritta dallo script al caricamento |
| 26 | 2026-08-12 07:43:48 | 1.1.0 | `984452d` | scritta dallo script al caricamento |

## La build 13, accertata

Non è un'ipotesi. Il campo `whatsNew` della build 13, letto per interfaccia di
programmazione, è **identico** al contenuto di `note-di-rilascio.txt` al commit
`61a90e6` (3547 caratteri contro 3548, la differenza è l'a capo finale che
l'interfaccia non conserva). Quel testo è quello scritto dalla seconda unità della
fase D, e l'unico procedimento che lo alleghi a una build è
`scripts/carica-testflight.sh`, che lo legge dal file al momento del caricamento.

Ne segue che la build 13 fu prodotta e caricata dallo script, durante la sessione
della seconda unità, fra il commit `6c2829d` (09:47 ora locale) e `349ee17`
(09:53): il caricamento risulta alle 09:50:41 locali. **Quella sessione caricò e
non lo scrisse in alcun documento**, né nel messaggio di commit, né in
`stato-avanzamento.md`, né in `memoria-infrastruttura.md`.

Non è un caricamento manuale, non è un tentativo interrotto — la build risulta
`VALID` e non scaduta — e non è opera di un altro procedimento, perché nessun
altro allega quella nota.
