#!/usr/bin/env python3
"""Sceglie e rimpicciolisce le schermate dell'esplorazione (incarico 27, quarta parte).

Gli allegati PNG esportati dai fasci dei risultati (`xcresulttool export attachments`, in
`Applicazione/build/esplorazione-corse/allegati-<corsa>/` con il loro `manifest.json`) sono a piena
risoluzione. Qui si sceglie una schermata per ciascuna delle schermate chiave di ogni corsa, la si
riduce con `sips` (lato lungo al più 900 punti) e la si copia nella cartella dei prodotti, restando
sotto il tetto dichiarato di megabyte. I fascicoli grezzi non si consegnano.

Uso: python3 scripts/scegli-schermate-esplorazione.py <cartella delle corse> <cartella di destinazione> [tetto in MB]
"""
import json, pathlib, subprocess, sys

corse = pathlib.Path(sys.argv[1]); meta = pathlib.Path(sys.argv[2]); tetto = float(sys.argv[3]) if len(sys.argv) > 3 else 15.0
meta.mkdir(parents=True, exist_ok=True)
CHIAVE = ["avvio", "impostazioni", "apprendimento-dei-segnali", "battaglia-apertura", "battaglia-dopo-il-piazzamento",
          "battaglia-pannello-della-cella", "resoconto-della-battaglia", "mappa-piccola", "pannello-gruppo-piccola",
          "designazione-marcia-piccola", "divisione-piccola", "registro-piccola", "mappa-media", "mappa-grande",
          "battaglia-di-campagna", "resoconto-di-campagna", "ripiegamento", "mappa-piccola-al-ritorno"]
totale = 0.0; scelte = 0
for cartella in sorted(corse.glob("allegati-*")):
    corsa = cartella.name.removeprefix("allegati-")
    manifesto = cartella / "manifest.json"
    if not manifesto.exists():
        continue
    voci = []
    for prova in json.loads(manifesto.read_text()):
        for a in prova.get("attachments", []):
            nome = a.get("suggestedHumanReadableName") or a.get("exportedFileName", "")
            voci.append((nome, cartella / a.get("exportedFileName", "")))
    for chiave in CHIAVE:
        candidati = [(n, f) for n, f in voci if f.suffix.lower() == ".png" and f"-{chiave}" in n and "-dopo-" not in n]
        if not candidati:
            continue
        nome, sorgente = candidati[0]
        destinazione = meta / f"{corsa}--{chiave}.png"
        subprocess.run(["sips", "-Z", "900", str(sorgente), "--out", str(destinazione)], capture_output=True)
        if destinazione.exists():
            mb = destinazione.stat().st_size / 1e6
            if totale + mb > tetto:
                destinazione.unlink(); continue
            totale += mb; scelte += 1
print(f"schermate scelte: {scelte}, {totale:.1f} MB (somma di questo script), in {meta}")
