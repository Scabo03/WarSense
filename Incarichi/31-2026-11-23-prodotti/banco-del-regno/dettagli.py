#!/usr/bin/env python3
"""Conteggi di dettaglio del banco del regno dalle righe grezze (incarico 31), a complemento di
`riassumi.py`: dove e quando si vincono le campagne, dove le partite si fermano, e i totali delle cose
nuove della seconda tappa. Nessun numero è calcolato a mano.

Uso: python3 dettagli.py banco-del-regno.jsonl
"""
import collections
import json
import statistics
import sys

righe = [json.loads(r) for r in open(sys.argv[1], encoding="utf-8")]
condotte = sorted({r["condotta"] for r in righe})

print("## Le campagne vinte per annientamento, per condotta, anno e fronte")
print()
print("| condotta | anno | fronte | campagne vinte | formazioni partite | atomi partiti (min–mediana–max) | battaglie, vinte, perse (i casi) | giornata della conclusione (min–mediana–max) |")
print("|---|---|---|---|---|---|---|---|")
for condotta in condotte:
    vinte = [r for r in righe if r["condotta"] == condotta and r.get("vincitore") == "giocatore"]
    for anno, fronte in sorted({(r["anno"], r["fronte"]) for r in vinte}):
        g = [r for r in vinte if r["anno"] == anno and r["fronte"] == fronte]
        atomi = [r["atomi_partiti"] for r in g]
        giornate = [r["giornate"] for r in g]
        formazioni = sorted(collections.Counter(r["formazioni_partite"] for r in g).items())
        casi = sorted(collections.Counter((r["battaglie"], r["vinte"], r["perse"]) for r in g).items())
        print(f"| {condotta} | {anno} | {fronte} | {len(g)} | "
              f"{', '.join(f'{k} ({v})' for k, v in formazioni)} | "
              f"{min(atomi)}–{statistics.median(atomi)}–{max(atomi)} | "
              f"{'; '.join(f'{b}, {v}, {p} ({n})' for (b, v, p), n in casi)} | "
              f"{min(giornate)}–{statistics.median(giornate)}–{max(giornate)} |")
print()
print("Campagne perse per annientamento:", sum(1 for r in righe if r.get("vincitore") == "avversario"))
print()
print("## Gli anni giocati al quinto anno, per condotta e fronte")
print()
for condotta in condotte:
    conto = collections.Counter((r["fronte"], r["conclusione"]) for r in righe
                                if r["condotta"] == condotta and r["anno"] == 5)
    print(f"- {condotta}: " + "; ".join(f"{f} {c}: {n}" for (f, c), n in sorted(conto.items())))
print()
print("## Le partite ferme su una battaglia che al banco non si conclude")
print()
ferme = [r for r in righe if r["conclusione"] == "ferma"]
print(f"- in tutto: {len(ferme)}")
for (condotta, fronte), n in sorted(collections.Counter((r["condotta"], r["fronte"]) for r in ferme).items()):
    print(f"- {condotta}, {fronte}: {n}")
print()
print("## Le cose nuove della seconda tappa, in tutto")
print()
conclusi = [r for r in righe if r["conclusione"] != "ferma"]
print(f"- anni conclusi: {len(conclusi)} su {len(righe)}")
print(f"- mantenimento prelevato, in monete (anni conclusi): minimo {min(r['mantenimento'] for r in conclusi)}, "
      f"mediana {statistics.median(r['mantenimento'] for r in conclusi)}, massimo {max(r['mantenimento'] for r in conclusi)}")
print(f"- anni con almeno un reparto sciolto: {sum(1 for r in righe if r['reparti_sciolti'] > 0)}")
print(f"- miglioramenti ordinati: {sum(r['miglioramenti_ordinati'] for r in righe)}; "
      f"mantenimenti di miglioramenti ordinati: {sum(r['mantenimenti_ordinati'] for r in righe)}")
print(f"- anni con almeno un arrivo a campagna aperta: {sum(1 for r in righe if r['arrivi_a_campagna_aperta'] > 0)}")
tenute = collections.Counter((r["condotta"], r["anno"]) for r in righe if r["tenute_in_patria"] > 0)
print(f"- anni con almeno una formazione tenuta in patria: {sum(tenute.values())} "
      f"({'; '.join(f'{c} anno {a}: {n}' for (c, a), n in sorted(tenute.items()))})")
print(f"- battaglie: {sum(r['battaglie'] for r in righe)} in {sum(1 for r in righe if r['battaglie'] > 0)} anni con almeno una battaglia")
