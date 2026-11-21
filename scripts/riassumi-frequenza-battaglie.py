#!/usr/bin/env python3
"""Riassume i dati grezzi della misura della frequenza delle battaglie (incarico 29).

I dati grezzi li produce lo strumento di verifica:
  cd Codice && swift build -c release --product StrumentoVerifica
  .build/release/StrumentoVerifica --frequenza-battaglie 200 --giornate-massime 730 --uscita <cartella>
che scrive <cartella>/frequenza-battaglie.jsonl, una riga JSON per partita.

Uso: python3 scripts/riassumi-frequenza-battaglie.py <file.jsonl> [<file.jsonl> ...]
Stampa, per ciascun file, una tabella Markdown per formato e condotta. Ogni numero è calcolato qui,
dalle righe del file: nessuno è scritto a mano.
"""
import json
import pathlib
import statistics
import sys

ORDINE_FORMATI = ["campagna_piccola", "campagna_media", "campagna_grande"]
NOMI = {"campagna_piccola": "piccola", "campagna_media": "media", "campagna_grande": "grande"}
FINESTRA = 120  # le giornate della sessione da tester, per il confronto


def mediana(v):
    return statistics.median(v) if v else None


def fmt(x, cifre=2):
    if x is None:
        return "–"
    if isinstance(x, float):
        return f"{x:.{cifre}f}".replace(".", ",")
    return str(x)


def fmt_mediana(x):
    """Le mediane sono giornate: intere quando lo sono, altrimenti con un decimale (media dei due centrali)."""
    if x is None:
        return "–"
    return str(int(x)) if float(x).is_integer() else f"{x:.1f}".replace(".", ",")


def per_cento(n, tot):
    return f"{100 * n / tot:.0f}%" if tot else "–"


def riassumi(righe):
    celle = {}
    for r in righe:
        celle.setdefault((r["formato"], r["condotta"]), []).append(r)
    out = []
    out.append("| formato | condotta | partite | battaglie ogni 10 giornate | nelle prime 120 giornate, ogni 10 | battaglie per partita: media; mediana; massimo | prima battaglia, giornata mediana | partite senza battaglie | durata fino alla fine naturale, mediana | finite in modo naturale | fine: avversario senza armati | fine: giocatore senza armati | fine: limite | ferme su una battaglia non conclusa | partite con invarianti violati |")
    out.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for formato in ORDINE_FORMATI:
        for condotta in ("competente", "prudente"):
            g = celle.get((formato, condotta), [])
            if not g:
                continue
            n = len(g)
            giornate = sum(r["giornate"] for r in g)
            battaglie = sum(r["battaglie"] for r in g)
            # Nelle prime 120 giornate: le battaglie nate entro la 120ª giornata, sulle giornate giocate entro quella soglia.
            b120 = sum(sum(1 for d in r["giornate_delle_battaglie"] if d <= FINESTRA) for r in g)
            g120 = sum(min(r["giornate"], FINESTRA) for r in g)
            prime = [r["prima_battaglia"] for r in g if r.get("prima_battaglia") is not None]
            naturali = [r for r in g if r["fine"] in ("avversario_senza_armati", "giocatore_senza_armati")]
            fini = {k: sum(1 for r in g if r["fine"] == k) for k in ("avversario_senza_armati", "giocatore_senza_armati", "limite", "ferma")}
            out.append("| " + " | ".join([
                NOMI.get(formato, formato), condotta, str(n),
                fmt(battaglie * 10 / giornate if giornate else 0.0, 3),
                fmt(b120 * 10 / g120 if g120 else 0.0, 3),
                f"{fmt(battaglie / n)}; {fmt_mediana(mediana([r['battaglie'] for r in g]))}; {max(r['battaglie'] for r in g)}",
                fmt_mediana(mediana(prime)),
                f"{sum(1 for r in g if r['battaglie'] == 0)} ({per_cento(sum(1 for r in g if r['battaglie'] == 0), n)})",
                fmt_mediana(mediana([r["giornate"] for r in naturali])),
                f"{len(naturali)} ({per_cento(len(naturali), n)})",
                str(fini["avversario_senza_armati"]), str(fini["giocatore_senza_armati"]),
                str(fini["limite"]), str(fini["ferma"]),
                str(sum(1 for r in g if r.get("violazioni"))),
            ]) + " |")
    return "\n".join(out)


VALORI = pathlib.Path(__file__).resolve().parent.parent / "Codice" / "Sources" / "Contenuti" / "Valori"


def quartier_generali_avversari():
    """La casella del quartier generale avversario per formato, letta dagli scenari e dalle mappe del gioco."""
    scenari = json.loads((VALORI / "scenari-campagna.json").read_text(encoding="utf-8"))
    out = {}
    for formato, scenario in scenari.items():
        mappa = json.loads((VALORI / "Mappe" / (scenario["mappa"].replace("_", "-") + ".json")).read_text(encoding="utf-8"))
        qg = mappa["quartier_generali"]["avversario"]
        out[formato] = (qg["riga"], qg["colonna"])
    return out


def dove_si_fermano(righe):
    """Le partite ferme su una battaglia non conclusa: dove stava la battaglia (dal motivo registrato)."""
    import re
    qg = quartier_generali_avversari()
    conti = {}
    for r in righe:
        if r["fine"] != "ferma":
            continue
        m = re.search(r"casella=(\d+),(\d+):imboscata=(true|false)", r.get("motivo_ferma") or "")
        if not m:
            luogo, imboscata = "altro motivo", "–"
        else:
            casella = (int(m.group(1)), int(m.group(2)))
            luogo = ("casella del quartier generale avversario" if casella == qg.get(r["formato"])
                     else "altra casella della prima riga" if casella[0] == 1 else "altrove")
            imboscata = "sì" if m.group(3) == "true" else "no"
        chiave = (NOMI.get(r["formato"], r["formato"]), r["condotta"], luogo, imboscata)
        conti[chiave] = conti.get(chiave, 0) + 1
    if not conti:
        return "Nessuna partita ferma."
    out = ["| formato | condotta | dove | da imboscata | partite |", "|---|---|---|---|---|"]
    ordine = {n: i for i, n in enumerate(NOMI.values())}
    for chiave in sorted(conti, key=lambda k: (ordine.get(k[0], 9), k[1], k[2], k[3])):
        out.append("| " + " | ".join(chiave) + f" | {conti[chiave]} |")
    return "\n".join(out)


def main():
    for percorso in sys.argv[1:]:
        p = pathlib.Path(percorso)
        righe = [json.loads(l) for l in p.read_text(encoding="utf-8").splitlines() if l.strip()]
        print(f"### {p.parent.name} — {len(righe)} partite ({p.name})\n")
        print(riassumi(righe))
        print()
        print(f"Le partite ferme su una battaglia non conclusa, per luogo della battaglia ({p.parent.name}):\n")
        print(dove_si_fermano(righe))
        print()


if __name__ == "__main__":
    main()
