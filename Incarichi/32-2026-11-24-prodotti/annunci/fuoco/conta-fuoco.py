#!/usr/bin/env python3
"""Dove arriva il fuoco fra la campagna richiamata, la dichiarazione di conclusione e la patria, contato sui dati grezzi
del blocco «fuoco» di `misura-annunci.py` (copia strumentata, VoiceOver acceso). Giusto: l'ultimo elemento che riceve il
fuoco è quello che il gioco chiede. Rinnovata: la richiesta del gioco è stata fatta due volte (RDA-192).

Uso: conta-fuoco.py <cartella…>   Nomi dei file: <variante>-<apparecchio>-<simulatore>.jsonl
"""
import collections
import glob
import json
import os
import sys

for cartella in sys.argv[1:]:
    conti = collections.OrderedDict()
    for percorso in sorted(glob.glob(os.path.join(cartella, "*.jsonl"))):
        variante = os.path.basename(percorso)[:-6].rsplit("-", 1)[0]
        with open(percorso, encoding="utf-8") as h:
            for riga in h:
                d = json.loads(riga)
                passo = "dichiarazione" if d["passo"].startswith("richiamo compiuto") else "ritorno in patria" if d["passo"].startswith("ritorno in patria") else None
                if passo is None or d.get("errore"):
                    continue
                atteso = "Campagna conclusa" if passo == "dichiarazione" else "Anno 1, primavera"
                ultimo = (d["fuochi"] or [[0, "—"]])[-1][1]
                c = conti.setdefault((variante, passo), collections.Counter())
                c["volte"] += 1
                c["giuste"] += ultimo.startswith(atteso)
                c["rinnovate"] += len(d.get("chiesti", [])) > 1
                if not ultimo.startswith(atteso):
                    c["finite su «%s»" % ultimo] += 1
    print("==", os.path.basename(cartella.rstrip("/")))
    for (variante, passo), c in conti.items():
        storte = "; ".join("%s %d" % (k, v) for k, v in c.items() if k.startswith("finite"))
        print("  %-18s %-18s %2d volte, %2d giuste, %d rinnovate%s" % (variante, passo, c["volte"], c["giuste"], c["rinnovate"], "; " + storte if storte else ""))
