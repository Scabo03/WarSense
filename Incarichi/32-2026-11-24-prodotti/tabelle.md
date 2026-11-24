# Tabelle prima e dopo (incarico 32)

Prodotte da `tabelle.py` sui dati grezzi di questa cartella. «Prima» è il codice della build 32 (06dee59, valori 0.15.0), «dopo» quello dell'incarico 32 (valori 0.16.0), «pari» è «dopo» col tattico del giocatore del banco che non si arrende a metà delle perdite.


## 1. Le battaglie che non finiscono

| misura |  | partite o anni | fermi su una battaglia che non finisce | causa | con violazioni |
|---|---|---|---|---|---|
| frequenza (730 giornate) | prima | 1200 | 33 | selezione_alternata: 33 | 0 |
| frequenza (730 giornate) | dopo | 1800 | 0 | — | 0 |
| frequenza (730 giornate) | pari | 1800 | 0 | — | 0 |
| banco del regno (5 anni) | prima | 1829 | 78 | selezione_alternata: 78 | 0 |
| banco del regno (5 anni) | dopo | 3000 | 0 | — | 0 |
| banco del regno (5 anni) | pari | 3000 | 0 | — | 0 |


## 2. La frequenza delle battaglie

| condotta | mappa |  | partite | battaglie | ogni 10 giornate | prima battaglia (mediana) | senza battaglie | avversario senza armati | giocatore senza armati | al limite | ferme |
|---|---|---|---|---|---|---|---|---|---|---|---|
| competente | piccola (guado) | prima | 200 | 398 | 0,038 | 18 | 13 | 10 | 52 | 137 | 1 |
| competente | piccola (guado) | dopo | 200 | 847 | 0,102 | 18 | 12 | 97 | 1 | 102 | 0 |
| competente | media (istmo) | prima | 200 | 1357 | 0,104 | 68,5 | 116 | 0 | 0 | 175 | 25 |
| competente | media (istmo) | dopo | 200 | 2674 | 0,183 | 69 | 105 | 0 | 0 | 200 | 0 |
| competente | grande (pianura lunga) | prima | 200 | 245 | 0,019 | 55,5 | 120 | 16 | 0 | 177 | 7 |
| competente | grande (pianura lunga) | dopo | 200 | 122 | 0,010 | 57 | 116 | 32 | 0 | 168 | 0 |
| prudente | piccola (guado) | prima | 200 | 200 | 0,014 | 4 | 0 | 0 | 0 | 200 | 0 |
| prudente | piccola (guado) | dopo | 200 | 400 | 0,027 | 4 | 0 | 0 | 0 | 200 | 0 |
| prudente | media (istmo) | prima | 200 | 415 | 0,028 | 11 | 0 | 0 | 0 | 200 | 0 |
| prudente | media (istmo) | dopo | 200 | 200 | 0,014 | 11 | 0 | 0 | 0 | 200 | 0 |
| prudente | grande (pianura lunga) | prima | 200 | 0 | 0,000 | — | 200 | 0 | 0 | 200 | 0 |
| prudente | grande (pianura lunga) | dopo | 200 | 0 | 0,000 | — | 200 | 0 | 0 | 200 | 0 |
| mirata | piccola (guado) | dopo | 200 | 31218 | 4,159 | 10 | 0 | 100 | 0 | 100 | 0 |
| mirata | media (istmo) | dopo | 200 | 524 | 0,036 | 20 | 0 | 0 | 0 | 200 | 0 |
| mirata | grande (pianura lunga) | dopo | 200 | 714 | 0,508 | 15 | 0 | 191 | 0 | 9 | 0 |


## 3. Lo squilibrio fra le mappe: le battaglie vinte dal giocatore

In ogni cella: le battaglie vinte su quelle giocate e, dopo il punto e virgola, le sole COMBATTUTE, cioè quelle in cui almeno una delle due parti ha perso un atomo. Le altre si concludono coi reparti intatti: prima, perché una parte era annientata al suo primo comando (il difetto del budget del primo turno); dopo, perché i due schieramenti non possono incontrarsi e l'avversario si ritira (lo stallo, 01 §10.7.1).



Campagne di prova (misura della frequenza, 200 partite per cella, 730 giornate):


| condotta | mappa | prima | dopo | pari |
|---|---|---|---|---|
| competente | piccola (guado) | 7 su 398 (1,8%); combattute 7 su 398 (1,8%) | 123 su 847 (14,5%); combattute 123 su 650 (18,9%) | 163 su 450 (36,2%); combattute 163 su 450 (36,2%) |
| competente | media (istmo) | 1307 su 1357 (96,3%); combattute 0 su 0 (—) | 2583 su 2674 (96,6%); combattute 59 su 150 (39,3%) | 2646 su 2701 (98,0%); combattute 70 su 125 (56,0%) |
| competente | grande (pianura lunga) | 16 su 245 (6,5%); combattute 16 su 78 (20,5%) | 33 su 122 (27,0%); combattute 33 su 122 (27,0%) | 44 su 106 (41,5%); combattute 44 su 106 (41,5%) |
| prudente | piccola (guado) | 0 su 200 (0,0%); combattute 0 su 200 (0,0%) | 0 su 400 (0,0%); combattute 0 su 400 (0,0%) | 0 su 200 (0,0%); combattute 0 su 200 (0,0%) |
| prudente | media (istmo) | 393 su 415 (94,7%); combattute 0 su 0 (—) | 0 su 200 (0,0%); combattute 0 su 200 (0,0%) | 0 su 200 (0,0%); combattute 0 su 200 (0,0%) |
| prudente | grande (pianura lunga) | 0 su 0 (—); combattute 0 su 0 (—) | 0 su 0 (—); combattute 0 su 0 (—) | 0 su 0 (—); combattute 0 su 0 (—) |
| mirata | piccola (guado) | non giocata | 100 su 31218 (0,3%); combattute 100 su 700 (14,3%) | 263 su 363 (72,5%); combattute 263 su 363 (72,5%) |
| mirata | media (istmo) | non giocata | 201 su 524 (38,4%); combattute 1 su 324 (0,3%) | 201 su 428 (47,0%); combattute 1 su 228 (0,4%) |
| mirata | grande (pianura lunga) | non giocata | 169 su 714 (23,7%); combattute 169 su 713 (23,7%) | 198 su 435 (45,5%); combattute 198 su 435 (45,5%) |


Campagne del regno (banco del regno, 200 partite di 5 anni per condotta):


| condotta | mappa | prima | dopo | pari |
|---|---|---|---|---|
| competente | guado | 115 su 716 (16,1%); combattute 115 su 605 (19,0%) | 124 su 585 (21,2%); combattute 124 su 581 (21,3%) | 185 su 497 (37,2%); combattute 185 su 497 (37,2%) |
| competente | istmo | 289 su 305 (94,8%); combattute 0 su 0 (—) | 183 su 280 (65,4%); combattute 30 su 127 (23,6%) | 177 su 248 (71,4%); combattute 28 su 98 (28,6%) |
| competente | pianura lunga | 16 su 178 (9,0%); combattute 16 su 119 (13,4%) | 36 su 224 (16,1%); combattute 36 su 224 (16,1%) | 48 su 183 (26,2%); combattute 48 su 183 (26,2%) |
| prudente | guado | 66 su 529 (12,5%); combattute 66 su 529 (12,5%) | 200 su 1130 (17,7%); combattute 200 su 1130 (17,7%) | 200 su 664 (30,1%); combattute 200 su 664 (30,1%) |
| prudente | istmo | 695 su 740 (93,9%); combattute 0 su 0 (—) | 0 su 1069 (0,0%); combattute 0 su 1069 (0,0%) | 0 su 735 (0,0%); combattute 0 su 735 (0,0%) |
| prudente | pianura lunga | 0 su 1116 (0,0%); combattute 0 su 196 (0,0%) | 0 su 201 (0,0%); combattute 0 su 201 (0,0%) | 0 su 135 (0,0%); combattute 0 su 135 (0,0%) |
| mirata | guado | non giocata | 284 su 1383 (20,5%); combattute 284 su 1140 (24,9%) | 333 su 725 (45,9%); combattute 333 su 725 (45,9%) |
| mirata | istmo | non giocata | 277 su 1244 (22,3%); combattute 42 su 976 (4,3%) | 332 su 962 (34,5%); combattute 94 su 724 (13,0%) |
| mirata | pianura lunga | non giocata | 268 su 1131 (23,7%); combattute 268 su 1113 (24,1%) | 262 su 616 (42,5%); combattute 262 su 616 (42,5%) |


Le campagne del regno vinte e perse dal giocatore (le altre le interrompe l'inverno; «prima», in 78 anni, la partita si fermava):


| condotta | mappa | prima | dopo | pari |
|---|---|---|---|---|
| competente | guado | 40,7% vinte, 0,0% perse | 40,5% vinte, 25,2% perse | 44,4% vinte, 22,8% perse |
| competente | istmo | 0,0% vinte, 0,0% perse | 3,0% vinte, 2,1% perse | 2,4% vinte, 2,1% perse |
| competente | pianura lunga | 5,9% vinte, 0,0% perse | 10,2% vinte, 4,2% perse | 10,8% vinte, 4,8% perse |
| prudente | guado | 19,8% vinte, 0,0% perse | 60,1% vinte, 0,0% perse | 60,1% vinte, 0,3% perse |
| prudente | istmo | 0,0% vinte, 0,0% perse | 0,0% vinte, 0,0% perse | 0,0% vinte, 0,0% perse |
| prudente | pianura lunga | 0,0% vinte, 0,0% perse | 0,0% vinte, 0,0% perse | 0,0% vinte, 0,0% perse |
| mirata | guado | non giocata | 85,9% vinte, 0,0% perse | 99,7% vinte, 0,0% perse |
| mirata | istmo | non giocata | 82,6% vinte, 0,0% perse | 98,5% vinte, 0,0% perse |
| mirata | pianura lunga | non giocata | 82,3% vinte, 0,0% perse | 78,4% vinte, 0,0% perse |


## 4. I duelli fra i gruppi armati degli scenari

Un gruppo contro l'altro, coi due tattici del banco, le due parti e i due ordini. «Immobili» sono i reparti in campo che non possono fare nemmeno un passo con il volume di un turno. L = fanteria leggera, P = fanteria pesante, C = cavalleria manovrata.


| giocatore | avversario | agisce per primo | prima | dopo | pari |
|---|---|---|---|---|---|
| 18L+8P | 18L+8P | avversario | avversario, turno 17 (ritirata compiuta); restano 0 e 5 | avversario, turno 17 (ritirata compiuta); restano 4 e 5 | giocatore, turno 18 (ritirata compiuta); restano 3 e 3 |
| 18L+8P | 18L+8P | giocatore | avversario, turno 13 (ritirata compiuta); restano 0 e 8 | avversario, turno 13 (ritirata compiuta); restano 7 e 8 | giocatore, turno 27 (ritirata compiuta); restano 1 e 2 |
| 24P+12C | 18L+8P | avversario | avversario, turno 1 (annientamento); restano 36 e 26 | giocatore, turno 18 (annientamento); restano 30 e 0 | giocatore, turno 18 (annientamento); restano 30 e 0 |
| 24P+12C | 18L+8P | giocatore | avversario, turno 1 (annientamento); restano 36 e 26 | giocatore, turno 19 (annientamento); restano 30 e 0 | giocatore, turno 19 (annientamento); restano 30 e 0 |
| 6L | 18L+8P | avversario | avversario, turno 7 (ritirata compiuta); restano 0 e 24 | avversario, turno 7 (ritirata compiuta); restano 1 e 24 | avversario, turno 8 (annientamento); restano 0 e 24 |
| 6L | 18L+8P | giocatore | avversario, turno 7 (ritirata compiuta); restano 0 e 24 | avversario, turno 7 (ritirata compiuta); restano 1 e 24 | avversario, turno 8 (annientamento); restano 0 e 24 |
| 18L+8P | 24P+12C | avversario | giocatore, turno 1 (annientamento); restano 26 e 36 | avversario, turno 12 (ritirata compiuta); restano 8 e 32 | avversario, turno 19 (annientamento); restano 0 e 30 |
| 18L+8P | 24P+12C | giocatore | giocatore, turno 1 (annientamento); restano 26 e 36 | avversario, turno 11 (ritirata compiuta); restano 8 e 32 | avversario, turno 18 (annientamento); restano 0 e 30 |
| 24P+12C | 24P+12C | avversario | giocatore, turno 1 (annientamento); restano 36 e 36 | giocatore, turno 4 (ritirata compiuta); restano 36 e 36 | giocatore, turno 4 (ritirata compiuta); restano 36 e 36 |
| 24P+12C | 24P+12C | giocatore | avversario, turno 1 (annientamento); restano 36 e 36 | giocatore, turno 4 (ritirata compiuta); restano 36 e 36 | giocatore, turno 4 (ritirata compiuta); restano 36 e 36 |
| 6L | 24P+12C | avversario | giocatore, turno 1 (annientamento); restano 6 e 36 | avversario, turno 10 (annientamento); restano 0 e 35 | avversario, turno 10 (annientamento); restano 0 e 35 |
| 6L | 24P+12C | giocatore | giocatore, turno 1 (annientamento); restano 6 e 36 | avversario, turno 9 (annientamento); restano 0 e 35 | avversario, turno 9 (annientamento); restano 0 e 35 |
| 18L+8P | 6L | avversario | giocatore, turno 8 (ritirata compiuta); restano 24 e 0 | giocatore, turno 9 (ritirata compiuta); restano 24 e 1 | giocatore, turno 9 (ritirata compiuta); restano 24 e 1 |
| 18L+8P | 6L | giocatore | giocatore, turno 8 (ritirata compiuta); restano 24 e 0 | giocatore, turno 9 (ritirata compiuta); restano 24 e 1 | giocatore, turno 9 (ritirata compiuta); restano 24 e 1 |
| 24P+12C | 6L | avversario | avversario, turno 1 (annientamento); restano 36 e 6 | giocatore, turno 9 (annientamento); restano 35 e 0 | giocatore, turno 9 (annientamento); restano 35 e 0 |
| 24P+12C | 6L | giocatore | avversario, turno 1 (annientamento); restano 36 e 6 | giocatore, turno 10 (annientamento); restano 35 e 0 | giocatore, turno 10 (annientamento); restano 35 e 0 |
| 6L | 6L | avversario | avversario, turno 12 (ritirata compiuta); restano 0 e 2 | avversario, turno 12 (ritirata compiuta); restano 2 e 2 | giocatore, turno 26 (ritirata compiuta); restano 0 e 0 |
| 6L | 6L | giocatore | avversario, turno 12 (ritirata compiuta); restano 0 e 2 | avversario, turno 12 (ritirata compiuta); restano 2 e 2 | giocatore, turno 26 (ritirata compiuta); restano 0 e 0 |


## 5. Le proposte, con l'effetto misurato

Nessun file del gioco cambia. Le composizioni: `squilibrio/proposte.py` misura copie dei valori; la variante 0 è il gioco com'è. Le due alternative di regola (`squilibrio/alternative/`): il codice dell'incarico con la modifica del file `modifica.patch` accanto ai numeri. In ogni cella le battaglie vinte dal giocatore e, dopo il punto e virgola, le sole combattute; fra parentesi quadre lo stesso col tattico del giocatore che non si arrende a metà delle perdite.


Campagne di prova, 200 partite per cella:


| variante | condotta | piccola (guado) | media (istmo) | grande (pianura lunga) |
|---|---|---|---|---|
| 0-com-e-oggi | competente | 14,5% di 847; 18,9% di 650 [36,2% di 450; 36,2% di 450] | 96,6% di 2674; 39,3% di 150 [98,0% di 2701; 56,0% di 125] | 27,0% di 122; 27,0% di 122 [41,5% di 106; 41,5% di 106] |
| 0-com-e-oggi | mirata | 0,3% di 31218; 14,3% di 700 [72,5% di 363; 72,5% di 363] | 38,4% di 524; 0,3% di 324 [47,0% di 428; 0,4% di 228] | 23,7% di 714; 23,7% di 713 [45,5% di 435; 45,5% di 435] |
| 1-12P-6C | competente | 14,5% di 847; 18,9% di 650 [36,2% di 450; 36,2% di 450] | 22,5% di 200; 23,4% di 192 [50,3% di 169; 50,3% di 169] | 11,9% di 176; 12,2% di 172 [30,1% di 133; 30,1% di 133] |
| 1-12P-6C | mirata | 0,3% di 31218; 14,3% di 700 [72,5% di 363; 72,5% di 363] | 35,8% di 472; 36,0% di 470 [65,2% di 310; 65,2% di 310] | 7,8% di 2021; 16,6% di 954 [29,5% di 549; 29,5% di 549] |
| 2-16P-8C | competente | 14,5% di 847; 18,9% di 650 [36,2% di 450; 36,2% di 450] | 84,9% di 923; 32,2% di 205 [90,5% di 876; 51,5% di 171] | 25,4% di 130; 25,4% di 130 [57,3% di 124; 57,3% di 124] |
| 2-16P-8C | mirata | 0,3% di 31218; 14,3% di 700 [72,5% di 363; 72,5% di 363] | 36,2% di 519; 17,5% di 401 [49,1% di 407; 28,4% di 289] | 26,2% di 627; 26,4% di 621 [48,3% di 404; 48,3% di 404] |
| 3-avversario-18L-8P | competente | 14,5% di 847; 18,9% di 650 [36,2% di 450; 36,2% di 450] | 18,3% di 213; 18,4% di 212 [32,3% di 167; 32,3% di 167] | 11,9% di 176; 12,2% di 172 [30,1% di 133; 30,1% di 133] |
| 3-avversario-18L-8P | mirata | 0,3% di 31218; 14,3% di 700 [72,5% di 363; 72,5% di 363] | 8,7% di 1557; 23,4% di 580 [44,2% di 455; 44,2% di 455] | 7,8% di 2021; 16,6% di 954 [29,5% di 549; 29,5% di 549] |
| 4-12P-12P-6C-6C | competente | 14,5% di 847; 18,9% di 650 [36,2% di 450; 36,2% di 450] | 62,2% di 550; 7,2% di 223 [64,6% di 370; 22,9% di 170] | 8,4% di 143; 8,7% di 138 [22,9% di 109; 22,9% di 109] |
| 4-12P-12P-6C-6C | mirata | 0,3% di 31218; 14,3% di 700 [72,5% di 363; 72,5% di 363] | 30,2% di 602; 30,2% di 602 [46,8% di 427; 46,8% di 427] | 23,7% di 714; 23,7% di 713 [45,5% di 435; 45,5% di 435] |
| esce-chi-attacca | competente | 14,5% di 847; 18,9% di 650 [36,2% di 450; 36,2% di 450] | 96,6% di 2674; 39,3% di 150 [96,4% di 2613; 56,0% di 125] | 27,0% di 122; 27,0% di 122 [41,5% di 106; 41,5% di 106] |
| esce-chi-attacca | mirata | 0,3% di 31218; 14,3% di 700 [72,5% di 363; 72,5% di 363] | 0,1% di 23512; 7,9% di 382 [0,1% di 28038; 11,1% di 289] | 23,7% di 714; 23,7% di 713 [45,5% di 435; 45,5% di 435] |
| tetto-al-passo | competente | 14,5% di 847; 18,9% di 650 [36,2% di 450; 36,2% di 450] | 22,9% di 201; 23,2% di 198 [47,7% di 172; 47,7% di 172] | 26,3% di 118; 26,3% di 118 [39,8% di 103; 39,8% di 103] |
| tetto-al-passo | mirata | 0,3% di 31218; 14,3% di 700 [72,5% di 363; 72,5% di 363] | 8,9% di 1823; 31,0% di 525 [45,6% di 439; 45,6% di 439] | 23,7% di 714; 23,7% di 713 [45,5% di 435; 45,5% di 435] |


Campagne del regno, 200 partite di 5 anni per condotta — le battaglie:


| variante | condotta | guado | istmo | pianura lunga |
|---|---|---|---|---|
| 0-com-e-oggi | competente | 21,2% di 585; 21,3% di 581 [37,2% di 497; 37,2% di 497] | 65,4% di 280; 23,6% di 127 [71,4% di 248; 28,6% di 98] | 16,1% di 224; 16,1% di 224 [26,2% di 183; 26,2% di 183] |
| 0-com-e-oggi | prudente | 17,7% di 1130; 17,7% di 1130 [30,1% di 664; 30,1% di 664] | 0,0% di 1069; 0,0% di 1069 [0,0% di 735; 0,0% di 735] | 0,0% di 201; 0,0% di 201 [0,0% di 135; 0,0% di 135] |
| 0-com-e-oggi | mirata | 20,5% di 1383; 24,9% di 1140 [45,9% di 725; 45,9% di 725] | 22,3% di 1244; 4,3% di 976 [34,5% di 962; 13,0% di 724] | 23,7% di 1131; 24,1% di 1113 [42,5% di 616; 42,5% di 616] |
| 1-12P-6C | competente | 17,1% di 614; 17,2% di 612 [31,7% di 517; 31,7% di 517] | 18,6% di 172; 18,8% di 170 [31,5% di 149; 31,5% di 149] | 2,1% di 243; 2,1% di 243 [11,5% di 156; 11,5% di 156] |
| 1-12P-6C | prudente | 22,2% di 1196; 22,2% di 1196 [30,1% di 664; 30,1% di 664] | 4,6% di 1470; 10,0% di 669 [22,1% di 602; 22,1% di 602] | 24,9% di 265; 24,9% di 265 [24,8% di 266; 24,8% di 266] |
| 1-12P-6C | mirata | 15,5% di 1488; 17,2% di 1338 [35,3% di 761; 35,3% di 761] | 27,6% di 965; 28,8% di 924 [48,3% di 718; 48,3% di 718] | 15,6% di 1650; 17,6% di 1466 [31,7% di 817; 31,7% di 817] |
| 2-16P-8C | competente | 23,1% di 602; 23,2% di 600 [37,1% di 523; 37,1% di 523] | 35,0% di 217; 15,1% di 166 [46,2% di 156; 33,9% di 127] | 10,9% di 211; 10,9% di 211 [29,5% di 176; 29,5% di 176] |
| 2-16P-8C | prudente | 21,1% di 1260; 21,1% di 1260 [33,4% di 598; 33,4% di 598] | 15,8% di 1268; 15,8% di 1268 [10,0% di 668; 10,0% di 668] | 0,0% di 335; 0,0% di 335 [0,0% di 134; 0,0% di 134] |
| 2-16P-8C | mirata | 21,9% di 1288; 24,4% di 1155 [46,8% di 705; 46,8% di 705] | 22,5% di 1065; 19,9% di 1024 [38,7% di 865; 36,1% di 830] | 24,4% di 1215; 25,3% di 1172 [41,9% di 711; 41,9% di 711] |
| 3-avversario-18L-8P | competente | 17,3% di 614; 17,3% di 612 [31,5% di 517; 31,5% di 517] | 12,0% di 166; 12,0% di 166 [29,1% di 148; 29,1% di 148] | 2,9% di 238; 2,9% di 238 [9,9% di 151; 9,9% di 151] |
| 3-avversario-18L-8P | prudente | 22,2% di 1196; 22,2% di 1196 [27,4% di 730; 27,4% di 730] | 6,6% di 2045; 10,6% di 1270 [22,1% di 602; 22,1% di 602] | 16,5% di 399; 16,5% di 399 [24,8% di 266; 24,8% di 266] |
| 3-avversario-18L-8P | mirata | 14,4% di 1490; 16,4% di 1313 [34,0% di 800; 34,0% di 800] | 17,8% di 1298; 18,0% di 1285 [39,0% di 856; 39,0% di 856] | 16,2% di 1678; 18,7% di 1451 [34,6% di 769; 34,6% di 769] |
| 4-12P-12P-6C-6C | competente | 22,1% di 587; 22,1% di 587 [37,4% di 506; 37,4% di 506] | 8,1% di 211; 6,7% di 208 [23,9% di 142; 16,3% di 129] | 10,1% di 199; 10,2% di 196 [22,0% di 150; 22,0% di 150] |
| 4-12P-12P-6C-6C | prudente | 17,7% di 1131; 17,7% di 1131 [30,1% di 664; 30,1% di 664] | 0,0% di 1135; 0,0% di 1135 [0,0% di 735; 0,0% di 735] | 0,0% di 201; 0,0% di 201 [0,0% di 135; 0,0% di 135] |
| 4-12P-12P-6C-6C | mirata | 20,9% di 1304; 23,0% di 1185 [43,1% di 771; 43,1% di 771] | 19,1% di 1176; 12,8% di 1061 [34,2% di 926; 29,6% di 865] | 22,3% di 1177; 22,6% di 1163 [43,8% di 605; 43,8% di 605] |
| esce-chi-attacca | competente | 21,2% di 585; 21,3% di 581 [37,2% di 497; 37,2% di 497] | 65,4% di 280; 23,6% di 127 [71,4% di 248; 28,6% di 98] | 16,1% di 224; 16,1% di 224 [26,2% di 183; 26,2% di 183] |
| esce-chi-attacca | prudente | 17,7% di 1130; 17,7% di 1130 [30,1% di 664; 30,1% di 664] | 0,0% di 1069; 0,0% di 1069 [0,0% di 735; 0,0% di 735] | 0,0% di 201; 0,0% di 201 [0,0% di 135; 0,0% di 135] |
| esce-chi-attacca | mirata | 21,0% di 1308; 23,0% di 1198 [44,1% di 760; 44,1% di 760] | 0,5% di 2876; 1,1% di 1235 [2,0% di 3850; 6,6% di 1160] | 17,5% di 1345; 17,7% di 1328 [32,4% di 615; 32,4% di 615] |
| tetto-al-passo | competente | 21,9% di 581; 22,0% di 577 [35,3% di 487; 35,3% di 487] | 6,2% di 177; 6,4% di 172 [24,2% di 124; 24,2% di 124] | 18,4% di 206; 18,4% di 206 [25,0% di 172; 25,0% di 172] |
| tetto-al-passo | prudente | 17,7% di 1130; 17,7% di 1130 [30,1% di 664; 30,1% di 664] | 0,0% di 1000; 0,0% di 1000 [0,0% di 735; 0,0% di 735] | 0,0% di 201; 0,0% di 201 [0,0% di 135; 0,0% di 135] |
| tetto-al-passo | mirata | 23,2% di 1203; 23,9% di 1168 [45,2% di 739; 45,2% di 739] | 9,0% di 1702; 10,3% di 1500 [17,8% di 1283; 17,8% di 1283] | 22,3% di 1163; 23,4% di 1106 [44,1% di 499; 44,1% di 499] |


Le stesse — le campagne vinte e perse:


| variante | condotta | guado | istmo | pianura lunga |
|---|---|---|---|---|
| 0-com-e-oggi | competente | 40,5% vinte, 25,2% perse [44,4% vinte, 22,8% perse] | 3,0% vinte, 2,1% perse [2,4% vinte, 2,1% perse] | 10,2% vinte, 4,2% perse [10,8% vinte, 4,8% perse] |
| 0-com-e-oggi | prudente | 60,1% vinte, 0,0% perse [60,1% vinte, 0,3% perse] | 0,0% vinte, 0,0% perse [0,0% vinte, 0,0% perse] | 0,0% vinte, 0,0% perse [0,0% vinte, 0,0% perse] |
| 0-com-e-oggi | mirata | 85,9% vinte, 0,0% perse [99,7% vinte, 0,0% perse] | 82,6% vinte, 0,0% perse [98,5% vinte, 0,0% perse] | 82,3% vinte, 0,0% perse [78,4% vinte, 0,0% perse] |
| 1-12P-6C | competente | 33,3% vinte, 28,2% perse [39,0% vinte, 21,6% perse] | 6,0% vinte, 3,0% perse [8,4% vinte, 4,5% perse] | 1,2% vinte, 8,7% perse [2,7% vinte, 8,7% perse] |
| 1-12P-6C | prudente | 79,9% vinte, 0,0% perse [60,1% vinte, 0,0% perse] | 39,8% vinte, 0,0% perse [39,8% vinte, 0,0% perse] | 19,8% vinte, 0,0% perse [19,8% vinte, 0,0% perse] |
| 1-12P-6C | mirata | 69,7% vinte, 0,0% perse [79,0% vinte, 0,9% perse] | 90,7% vinte, 0,0% perse [99,4% vinte, 0,0% perse] | 79,0% vinte, 0,0% perse [78,1% vinte, 0,0% perse] |
| 2-16P-8C | competente | 39,6% vinte, 24,9% perse [41,4% vinte, 23,1% perse] | 2,1% vinte, 3,6% perse [4,8% vinte, 3,0% perse] | 9,0% vinte, 4,8% perse [9,0% vinte, 5,7% perse] |
| 2-16P-8C | prudente | 79,9% vinte, 0,0% perse [60,1% vinte, 0,0% perse] | 59,9% vinte, 0,0% perse [20,1% vinte, 0,0% perse] | 0,0% vinte, 0,0% perse [0,0% vinte, 0,0% perse] |
| 2-16P-8C | mirata | 84,1% vinte, 0,0% perse [97,0% vinte, 0,0% perse] | 73,1% vinte, 0,0% perse [99,7% vinte, 0,0% perse] | 91,3% vinte, 0,0% perse [89,5% vinte, 0,0% perse] |
| 3-avversario-18L-8P | competente | 34,2% vinte, 27,6% perse [38,4% vinte, 22,2% perse] | 4,5% vinte, 3,3% perse [7,2% vinte, 4,2% perse] | 2,1% vinte, 8,4% perse [2,7% vinte, 8,4% perse] |
| 3-avversario-18L-8P | prudente | 79,9% vinte, 0,0% perse [60,1% vinte, 0,0% perse] | 40,1% vinte, 0,0% perse [39,8% vinte, 0,0% perse] | 19,8% vinte, 0,0% perse [19,8% vinte, 0,0% perse] |
| 3-avversario-18L-8P | mirata | 65,2% vinte, 0,3% perse [78,7% vinte, 1,2% perse] | 71,0% vinte, 0,0% perse [99,4% vinte, 0,0% perse] | 84,7% vinte, 0,0% perse [80,2% vinte, 0,0% perse] |
| 4-12P-12P-6C-6C | competente | 39,3% vinte, 21,0% perse [42,9% vinte, 19,8% perse] | 2,4% vinte, 3,9% perse [3,6% vinte, 4,8% perse] | 4,8% vinte, 5,4% perse [6,3% vinte, 6,0% perse] |
| 4-12P-12P-6C-6C | prudente | 60,1% vinte, 0,0% perse [60,1% vinte, 0,3% perse] | 0,0% vinte, 0,0% perse [0,0% vinte, 0,0% perse] | 0,0% vinte, 0,0% perse [0,0% vinte, 0,0% perse] |
| 4-12P-12P-6C-6C | mirata | 83,2% vinte, 2,4% perse [99,7% vinte, 0,0% perse] | 66,8% vinte, 3,9% perse [94,9% vinte, 4,5% perse] | 83,8% vinte, 1,2% perse [77,8% vinte, 0,0% perse] |
| esce-chi-attacca | competente | 40,5% vinte, 25,2% perse [44,4% vinte, 22,8% perse] | 3,0% vinte, 2,1% perse [2,4% vinte, 2,1% perse] | 10,2% vinte, 4,2% perse [10,8% vinte, 4,8% perse] |
| esce-chi-attacca | prudente | 60,1% vinte, 0,0% perse [60,1% vinte, 0,3% perse] | 0,0% vinte, 0,0% perse [0,0% vinte, 0,0% perse] | 0,0% vinte, 0,0% perse [0,0% vinte, 0,0% perse] |
| esce-chi-attacca | mirata | 83,2% vinte, 0,0% perse [99,4% vinte, 0,0% perse] | 4,5% vinte, 1,8% perse [22,2% vinte, 5,4% perse] | 78,1% vinte, 0,0% perse [59,5% vinte, 0,0% perse] |
| tetto-al-passo | competente | 40,8% vinte, 24,0% perse [44,4% vinte, 20,7% perse] | 4,2% vinte, 3,6% perse [4,8% vinte, 2,7% perse] | 11,4% vinte, 3,9% perse [9,9% vinte, 6,6% perse] |
| tetto-al-passo | prudente | 60,1% vinte, 0,0% perse [60,1% vinte, 0,3% perse] | 0,0% vinte, 0,0% perse [0,0% vinte, 0,0% perse] | 0,0% vinte, 0,0% perse [0,0% vinte, 0,0% perse] |
| tetto-al-passo | mirata | 84,7% vinte, 0,0% perse [99,4% vinte, 0,0% perse] | 48,5% vinte, 11,7% perse [65,9% vinte, 33,2% perse] | 82,0% vinte, 0,3% perse [65,2% vinte, 0,3% perse] |


## 6. Il banco del regno

| condotta | fronte |  | anni | battaglie | vinti per annientamento | persi per annientamento | vinti per presa | persi per presa | inverno | fermi | giornate (mediana) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| competente | guado | prima | 290 | 716 | 118 | 0 | 0 | 0 | 124 | 48 | 68 |
| competente | guado | dopo | 333 | 585 | 102 | 0 | 33 | 84 | 114 | 0 | 35 |
| competente | istmo | prima | 266 | 305 | 0 | 0 | 0 | 0 | 245 | 21 | 90 |
| competente | istmo | dopo | 334 | 280 | 0 | 0 | 10 | 7 | 317 | 0 | 90 |
| competente | pianura lunga | prima | 273 | 178 | 16 | 0 | 0 | 0 | 248 | 9 | 90 |
| competente | pianura lunga | dopo | 333 | 224 | 32 | 0 | 2 | 14 | 285 | 0 | 90 |
| prudente | guado | prima | 333 | 529 | 66 | 0 | 0 | 0 | 267 | 0 | 90 |
| prudente | guado | dopo | 333 | 1130 | 200 | 0 | 0 | 0 | 133 | 0 | 23 |
| prudente | istmo | prima | 334 | 740 | 0 | 0 | 0 | 0 | 334 | 0 | 90 |
| prudente | istmo | dopo | 334 | 1069 | 0 | 0 | 0 | 0 | 334 | 0 | 90 |
| prudente | pianura lunga | prima | 333 | 1116 | 0 | 0 | 0 | 0 | 333 | 0 | 90 |
| prudente | pianura lunga | dopo | 333 | 201 | 0 | 0 | 0 | 0 | 333 | 0 | 90 |
| mirata | guado | dopo | 333 | 1383 | 216 | 0 | 70 | 0 | 47 | 0 | 25 |
| mirata | istmo | dopo | 334 | 1244 | 9 | 0 | 267 | 0 | 58 | 0 | 44 |
| mirata | pianura lunga | dopo | 333 | 1131 | 222 | 0 | 52 | 0 | 59 | 0 | 33 |
