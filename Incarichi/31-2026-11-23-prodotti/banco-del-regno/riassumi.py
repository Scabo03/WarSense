#!/usr/bin/env python3
"""Tabelle del banco del regno dalle righe grezze (incarico 30, esteso dall'incarico 31 con il
mantenimento, i miglioramenti, gli arrivi a campagna aperta e le formazioni tenute in patria).
Nessun numero è calcolato a mano.

Uso: python3 riassumi.py banco-del-regno.jsonl
"""
import collections
import json
import statistics
import sys

righe = [json.loads(r) for r in open(sys.argv[1], encoding="utf-8")]


def mediana(xs):
    return statistics.median(xs) if xs else "-"


def per_cento(n, d):
    return f"{100 * n / d:.1f}%" if d else "-"


print(f"anni giocati: {len(righe)}; partite: {len({(r['condotta'], r['seme']) for r in righe})}; "
      f"anni con violazioni: {sum(1 for r in righe if r['violazioni'])}; "
      f"anni con proposte avversarie respinte: {sum(1 for r in righe if r['proposte_avversarie_respinte'])}")
print()
print("## Come finisce la campagna dell'anno, per condotta e fronte")
print()
print("| condotta | fronte | anni | annientamento vinta | annientamento persa | inverno | ferma al banco | con almeno una battaglia | battaglie per anno (media) | giornate (mediana) |")
print("|---|---|---|---|---|---|---|---|---|---|")
chiavi = sorted({(r["condotta"], r["fronte"]) for r in righe})
for condotta, fronte in chiavi + [(c, "tutti") for c in sorted({r["condotta"] for r in righe})]:
    g = [r for r in righe if r["condotta"] == condotta and (fronte == "tutti" or r["fronte"] == fronte)]
    n = len(g)
    conclusioni = collections.Counter(r["conclusione"] for r in g)
    vinte = sum(1 for r in g if r["conclusione"] == "annientamento" and r.get("vincitore") == "giocatore")
    perse = sum(1 for r in g if r["conclusione"] == "annientamento" and r.get("vincitore") == "avversario")
    print(f"| {condotta} | {fronte} | {n} | {vinte} ({per_cento(vinte, n)}) | "
          f"{perse} ({per_cento(perse, n)}) | {conclusioni.get('inverno', 0)} ({per_cento(conclusioni.get('inverno', 0), n)}) | "
          f"{conclusioni.get('ferma', 0)} ({per_cento(conclusioni.get('ferma', 0), n)}) | "
          f"{sum(1 for r in g if r['battaglie'] > 0)} ({per_cento(sum(1 for r in g if r['battaglie'] > 0), n)}) | "
          f"{sum(r['battaglie'] for r in g) / n:.2f} | {mediana([r['giornate'] for r in g])} |")
print()
print("Valori del campo `conclusione`:", dict(collections.Counter(r["conclusione"] for r in righe)))
print()
print("## Le forze e il bilancio d'anno in anno (anni conclusi, cioè non fermi al banco)")
print()
print("| condotta | anno | anni | atomi partiti (mediana) | atomi rientrati (mediana) | atomi reclutati (mediana) | leve ordinate (mediana) | formazioni partite (mediana) | entrata in denaro (mediana) | denaro riportato (mediana) |")
print("|---|---|---|---|---|---|---|---|---|---|")
for condotta in sorted({r["condotta"] for r in righe}):
    for anno in sorted({r["anno"] for r in righe}):
        g = [r for r in righe if r["condotta"] == condotta and r["anno"] == anno and r["conclusione"] != "ferma"]
        if not g:
            continue
        print(f"| {condotta} | {anno} | {len(g)} | {mediana([r['atomi_partiti'] for r in g])} | {mediana([r['atomi_rientrati'] for r in g])} | "
              f"{mediana([r['atomi_reclutati'] for r in g])} | {mediana([r['leve_ordinate'] for r in g])} | "
              f"{mediana([r['formazioni_partite'] for r in g])} | {mediana([r['entrata']['denaro'] for r in g])} | "
              f"{mediana([r['riportato']['denaro'] for r in g])} |")
print()
print("## Le partite che arrivano al quinto anno")
print()
for condotta in sorted({r["condotta"] for r in righe}):
    partite = collections.defaultdict(list)
    for r in righe:
        if r["condotta"] == condotta:
            partite[r["seme"]].append(r)
    intere = sum(1 for anni in partite.values() if len(anni) == 5 and anni[-1]["conclusione"] != "ferma")
    ferme = sum(1 for anni in partite.values() if anni[-1]["conclusione"] == "ferma")
    print(f"- {condotta}: {len(partite)} partite; {intere} giocano cinque anni interi; {ferme} si fermano su una battaglia "
          f"che al banco non si conclude (anno della fermata: {dict(sorted(collections.Counter(a[-1]['anno'] for a in partite.values() if a[-1]['conclusione'] == 'ferma').items()))})")
print()
print("## La seconda tappa: mantenimento, miglioramenti, arrivi, formazioni in patria (anni conclusi)")
print()
print("| condotta | anno | anni | mantenimento in denaro (mediana) | anni con reparti sciolti | miglioramenti ordinati (somma) | mantenimenti di miglioramenti ordinati (somma) | formazioni di reclute nate in primavera (mediana) | anni con arrivi a campagna aperta | anni con formazioni tenute in patria |")
print("|---|---|---|---|---|---|---|---|---|---|")
for condotta in sorted({r["condotta"] for r in righe}):
    for anno in sorted({r["anno"] for r in righe}):
        g = [r for r in righe if r["condotta"] == condotta and r["anno"] == anno and r["conclusione"] != "ferma"]
        if not g:
            continue
        print(f"| {condotta} | {anno} | {len(g)} | {mediana([r['mantenimento'] for r in g])} | "
              f"{sum(1 for r in g if r['reparti_sciolti'] > 0)} | {sum(r['miglioramenti_ordinati'] for r in g)} | "
              f"{sum(r['mantenimenti_ordinati'] for r in g)} | {mediana([r['formazioni_di_reclute'] for r in g])} | "
              f"{sum(1 for r in g if r['arrivi_a_campagna_aperta'] > 0)} | {sum(1 for r in g if r['tenute_in_patria'] > 0)} |")
print()
print("Codici di violazione osservati:", dict(collections.Counter(v for r in righe for v in r["violazioni"])))
