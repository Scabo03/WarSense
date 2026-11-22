# Il banco del regno (incarico 30)

- Strumento: `BancoRegno` e `SondaInvariantiRegno` (`Codice/Sources/Verifica/BancoRegno.swift`), da riga di comando:
  `cd Codice && swift build -c release --product StrumentoVerifica && .build/release/StrumentoVerifica --regno 200 --anni 5 --uscita <cartella>`. Durata della corsa: 5 s (`date +%s`).
- Dati grezzi: `banco-del-regno.jsonl`, una riga per anno giocato (1786). Riepilogo dello strumento: `banco-del-regno.txt`. Tabelle: `tabelle.md`, prodotte da `python3 riassumi.py banco-del-regno.jsonl`; nessun numero è calcolato a mano.
- Metodo: 200 partite di cinque anni per ciascuna delle due condotte della misura della frequenza delle battaglie (competente e prudente, `Incarichi/29-2026-11-21-prodotti/frequenza-battaglie/README.md`). Il fronte ruota col seme e con l'anno. La campagna dell'anno si gioca fino alla conclusione (annientamento o inverno); una battaglia che al banco non si conclude entro 400 giri ferma la partita, e l'anno si registra «ferma». D'inverno si ordinano leve, a turno fra le tre voci, finché le risorse bastano; poi le quattro stazioni e la primavera. Dopo ogni transizione la sonda controlla i tredici invarianti.
- Valori: 0.14.0, novanta giornate operative (i valori provvisori di `valori-provvisori.md`).
