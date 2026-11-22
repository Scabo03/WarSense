#!/usr/bin/env python3
"""Il ritardo della voce durante le chiusure in fila, dal diario del tester (incarico 30, RDA-172).

Per ogni pressione di «Chiudi la giornata» il tester annota ciò che VoiceOver ha detto nei tre secondi
successivi. Qui si confronta il giorno che l'annuncio «Giornata conclusa: comincia il giorno N» dichiara
con il giorno che comincia davvero dopo quella chiusura (le giornate giocate muovendo i gruppi, più le
chiusure fatte, più uno). Nessun numero è calcolato a mano.

Uso: python3 ritardo-della-voce.py <diario.jsonl> <giornate giocate muovendo i gruppi>
"""
import json
import re
import sys

righe = [json.loads(r) for r in open(sys.argv[1], encoding="utf-8")]
base = int(sys.argv[2])
chiusure = [r for r in righe if r["tipo"] == "giornata_chiusa"]
misure = []
for i, r in enumerate(chiusure, 1):
    m = re.findall(r"comincia il giorno (\d+)", r["sentito"])
    if m:
        misure.append((i, base + i + 1, int(m[-1])))
print(f"chiusure col tasto: {len(chiusure)}; con un giorno annunciato nell'ascolto: {len(misure)}; "
      f"dalle {chiusure[0]['ora']} alle {chiusure[-1]['ora']}" if chiusure else "nessuna chiusura")
print("| chiusura | giorno che comincia | giorno annunciato | ritardo in giornate |")
print("|---|---|---|---|")
scelte = [m for k, m in enumerate(misure) if k == 0 or k == len(misure) - 1 or m[0] % 10 == 0]
for i, vero, detto in scelte:
    print(f"| {i} | {vero} | {detto} | {vero - detto} |")
if misure:
    ritardi = [vero - detto for _, vero, detto in misure]
    print(f"ritardo massimo: {max(ritardi)} giornate; ritardo all'ultima chiusura misurata: {ritardi[-1]}")
