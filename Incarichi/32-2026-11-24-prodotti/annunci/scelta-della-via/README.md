# La scelta della via (incarico 32, prima parte)

Le vie per dire per intero un annuncio che accompagna uno spostamento del fuoco, misurate una accanto all'altra in una copia di laboratorio dell'app sull'iPhone simulato con VoiceOver acceso. La copia (`Lab.swift`, che non è mai entrato nel gioco) sceglie la via da un argomento di avvio e registra ogni annuncio pubblicato e concluso, ogni fuoco chiesto e arrivato. I tratti di voce («VOCE») vengono dal registro di sistema del simulatore, con `voce.py`; le pronunce («voce») dal pilota.

Le prove: K1 l'inverno (annuncio di 175 caratteri, 14,2 s, più il fuoco su «Anno 1, inverno…»); K3 la conferma di un addestramento dalla scelta del reparto (91 caratteri); K4 il rifiuto di una scelta impedita (46); K8 una leva ordinata, senza spostamento del fuoco (55).

| via | che cosa fa | K1 | K3 | K4 | K8 (senza spostamento) |
|---|---|---|---|---|---|
| S0 | priorità predefinita (build 32) | tagliato a 0,79 s | tagliato a 0,77 s | tagliato a 0,77 s | intero, 3,42 s |
| S1 | priorità alta | intero 14,17 s, poi l'elemento per intero | intero 5,52 s, poi l'elemento | intero 3,06 s, poi l'elemento | intero, 3,41 s |
| S2 | priorità bassa | non detto | tagliato a 0,77 s | tagliato a 0,77 s | intero, ma 5,32 s dopo |
| S3 | trattenuto finché il fuoco è arrivato, poi priorità bassa | intero, dopo la lettura dell'elemento (4,1 s) | intero, dopo 8,8 s di lettura | intero, dopo 8,7 s di lettura | intero, ma 5,32 s dopo |
| S4 | trattenuto finché il fuoco è arrivato, poi priorità predefinita | intero, ma taglia l'elemento dopo 0,15 s | idem | idem | intero, 3,42 s |
| S7 | attributo di accodamento della sintesi | non detto | tagliato a 0,75 s | tagliato a 0,77 s | intero, ma 5,34 s dopo |
| S8 | il testo come argomento della notifica di cambio di schermata | detto per 1,9 s | non detto (l'elemento sì) | non detto (l'elemento sì) | non detto |
| S9 | l'elemento che riceve il fuoco porta il testo | detto, 17,4 s con l'elemento in una frase sola | non detto | non detto | non detto |

S8 e S9 raccolgono l'annuncio della stessa azione nella notifica: funzionano soltanto dove l'elemento che riceve il fuoco è un'etichetta e l'annuncio uno, e tolgono la voce agli annunci che non spostano il fuoco, salvo una seconda strada per loro. La via scelta è S1 limitata agli annunci che accompagnano uno spostamento (RDA-183): gli altri restano a priorità predefinita.

File: `confronto-vie-iphone-1.txt` (S0, S1, S2; S3 e S4 interrotte da un riavvio del pilota e rifatte) e `confronto-vie-iphone-2.txt` (S3, S4, S7, S8, S9).
