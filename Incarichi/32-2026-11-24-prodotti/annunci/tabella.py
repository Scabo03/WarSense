#!/usr/bin/env python3
"""La tabella degli annunci, prima e dopo, dalle misure grezze (`misura-annunci.py`).

Rilegge le righe JSON e riabbina da capo annunci e tratti di voce (la stessa regola del pilota: il tratto di un
annuncio è il primo che finisce quando il sistema ne notifica la conclusione), sicché la tabella discende dai
dati grezzi e non da ciò che il pilota ha stampato. Detto per intero: il tratto finisce da sé (la coda audio si
svuota) ed è durato almeno i tre quarti di ciò che lo stesso annuncio dura al più nelle misure — o, se intero non
lo si sente mai, i sei decimi di quanto serve alla velocità misurata (17,5 caratteri al secondo). La notifica del
sistema («concluso, riuscito») NON decide: nelle misure della build 32 dice «riuscito» anche di annunci tagliati
dopo 0,00-0,06 s (quattro per apparecchio, elencati in coda alla tabella).

Le misure a voce veloce (blocco `velocita`, 90 per cento) stanno in una tabella a parte e fuori dal riassunto: non
hanno un «prima», e le durate non si confrontano con quelle a 50 per cento se non attraverso il rapporto fra le due,
che si ricava dalle righe che il fuoco non lo spostano. La regola è la stessa: tre quarti della durata intera.

Uso: tabella.py <uscita.md> <file.jsonl>…
"""
import collections
import json
import re
import statistics
import sys

righe = []
for f in sys.argv[2:]:
    with open(f, encoding="utf-8") as h:
        for r in h:
            d = json.loads(r)
            if d.get("annunci"):
                righe.append(d)


def abbina(d):
    tratti = [(a, (a + b) if b is not None else None, m) for a, b, m in d["tratti"]]
    presi = set()
    for a in d["annunci"]:
        t = a["pubblicato_a"]
        c = t + a["concluso_dopo"] if a["concluso_dopo"] is not None else None
        scelta = None
        if c is not None:
            cand = [(x[0], i) for i, x in enumerate(tratti) if i not in presi and x[1] is not None and x[0] >= t - 0.12 and abs(x[1] - c) <= 0.4]
            if cand:
                scelta = min(cand)[1]
        if scelta is None and c is None:
            scelta = next((i for i, x in enumerate(tratti) if i not in presi and x[0] >= t - 0.12), None)
        if scelta is None:
            a["detto"], a["modo"] = None, "nessuna voce"
        else:
            presi.add(scelta)
            x = tratti[scelta]
            a["detto"] = round(x[1] - x[0], 2) if x[1] is not None else None
            a["modo"] = x[2]


for d in righe:
    abbina(d)
    # Un passo che conclude la campagna porta a un'altra schermata: i suoi annunci stanno fra quelli che accompagnano
    # uno spostamento, anche dove il guidatore non lo dichiarava (blocchi presa e subita).
    d["sposta"] = d["sposta"] or any(a["testo"].startswith("Campagna conclusa") for a in d["annunci"])
    for a in d["annunci"]:
        a["veloce"] = d["blocco"] == "velocita"
durata_intera = collections.defaultdict(float)
for d in righe:
    for a in d["annunci"]:
        if a["modo"] == "intera" and not a["veloce"] and a["detto"] and a["concluso_riuscito"] == "true" and a["detto"] >= 0.6 * a["caratteri"] / 17.5 and a["detto"] <= 2.2 * a["caratteri"] / 17.5 + 1:
            durata_intera[a["testo"]] = max(durata_intera[a["testo"]], a["detto"])


def intero(a):
    if a["modo"] != "intera" or a["detto"] is None:
        return False
    if a["veloce"]:
        return a["atteso"] is not None and a["detto"] >= 0.75 * a["atteso"]
    serve = durata_intera.get(a["testo"])
    return a["detto"] >= (0.75 * serve if serve else 0.6 * a["caratteri"] / 17.5)


# La voce veloce: ogni annuncio ha la stessa durata a 50 per cento divisa per il rapporto fra le due velocità, e il
# rapporto è la mediana di quelli delle righe che non spostano il fuoco, apparecchio per apparecchio.
def senza_numeri(testo):
    return re.sub(r"\d+", "0", testo)


lente = collections.defaultdict(list)
for d in righe:
    for a in d["annunci"]:
        if not a["veloce"] and d["versione"] == "dopo" and intero(a):
            lente[a["testo"]].append(a["detto"])
            lente[senza_numeri(a["testo"])].append(a["detto"])


def durata_lenta(testo):
    uguali = lente.get(testo) or lente.get(senza_numeri(testo))
    return statistics.median(uguali) if uguali else None


rapporti = collections.defaultdict(list)
for d in righe:
    for a in d["annunci"]:
        if a["veloce"] and a["detto"] and durata_lenta(a["testo"]):
            a["lenta"] = durata_lenta(a["testo"])
            a["rapporto"] = a["lenta"] / a["detto"]
            if not d["sposta"]:
                rapporti[d["apparecchio"]].append(a["rapporto"])
for d in righe:
    for a in d["annunci"]:
        a["atteso"] = a["lenta"] / statistics.median(rapporti[d["apparecchio"]]) if a.get("rapporto") else None


# Superato dal GIOCO e non da VoiceOver: la conferma della chiusura che conclude la campagna, che l'annuncio della
# conclusione supera per scelta (A §11.6, RDA-172): il successivo è pubblicato mentre il primo comincia.
def superato_dal_gioco(d, k):
    a = d["annunci"]
    return (not intero(a[k]) and k + 1 < len(a) and a[k]["testo"].startswith("Giornata chiusa")
            and "conclusa" in a[k + 1]["testo"] and a[k + 1]["pubblicato_a"] - a[k]["pubblicato_a"] <= 0.1)


# chiave: (blocco, passo, posizione dell'annuncio nel passo)
tavola = collections.OrderedDict()
for d in righe:
    for k, a in enumerate(d["annunci"]):
        chiave = (d["blocco"], d["passo"], k)
        voce = tavola.setdefault(chiave, {"sposta": d["sposta"], "celle": {}, "testo": None})
        voce["celle"].setdefault((d["apparecchio"], d["versione"]), []).append((a, d))
        if voce["testo"] is None:
            voce["testo"] = a["testo"]

colonne = [("iphone", "prima"), ("iphone", "dopo"), ("ipad", "prima"), ("ipad", "dopo")]


def cella(elenco):
    if not elenco:
        return "—"
    a, d = elenco[-1]
    if superato_dal_gioco(d, d["annunci"].index(a)):
        return "superato dal gioco"
    if a["modo"] == "nessuna voce" or a["detto"] is None:
        return "nessuna voce" if a["modo"] == "nessuna voce" else "in corso"
    ritardo = a["voce_comincia_dopo"]
    return "%.2f s %s" % (a["detto"], "intero" if intero(a) else "interrotto")


with open(sys.argv[1], "w", encoding="utf-8") as f:
    f.write("# Gli annunci, prima e dopo\n\nProdotta da `tabella.py` dalle misure grezze (`misure-grezze/*.jsonl`). In ogni cella: per quanto la voce ha detto l'annuncio, e se l'ha detto intero. «Prima» è il codice della build 32 (06dee59), «dopo» quello della build (c5bcb09), entrambi nella copia strumentata che aggiunge il solo registro. La velocità di VoiceOver è quella predefinita del simulatore (50 per cento).\n")
    for titolo, vuole in (("Annunci che accompagnano uno spostamento del fuoco o un cambio di schermata", True), ("Annunci che non spostano il fuoco", False)):
        f.write("\n## " + titolo + "\n\n| Quando | Annuncio (caratteri) | iPhone prima | iPhone dopo | iPad prima | iPad dopo |\n|---|---|---|---|---|---|\n")
        for (blocco, passo, k), v in tavola.items():
            if v["sposta"] != vuole or blocco == "velocita":
                continue
            testi = {a["testo"] for e in v["celle"].values() for a, _ in e}
            t = v["testo"]
            f.write("| %s · %s | «%s» (%d)%s | %s |\n" % (blocco, passo, t.replace("\n", " ").replace("|", "/")[:90] + ("…" if len(t) > 90 else ""), len(t),
                    "" if len(testi) == 1 else " — testi diversi fra le corse", " | ".join(cella(v["celle"].get(c)) for c in colonne)))
    f.write("\n## Riassunto\n\n| | iPhone prima | iPhone dopo | iPad prima | iPad dopo |\n|---|---|---|---|---|\n")
    for titolo, vuole in (("Con spostamento: interi su detti", True), ("Senza spostamento: interi su detti", False)):
        celle = []
        for c in colonne:
            tutti = [e[-1][0] for k, v in tavola.items() if v["sposta"] == vuole and k[0] != "velocita" for cc, e in v["celle"].items()
                     if cc == c and not superato_dal_gioco(e[-1][1], e[-1][1]["annunci"].index(e[-1][0]))]
            celle.append("%d su %d" % (sum(1 for a in tutti if intero(a)), len(tutti)))
        f.write("| %s | %s |\n" % (titolo, " | ".join(celle)))
    f.write("\n## Voce al 90 per cento\n\nMisurata soltanto dopo. Per ogni annuncio: quanto dura al 50 per cento (mediana delle volte intere, dello stesso testo o, se cambia solo un numero, del testo a meno dei numeri), quanto è durato al 90, e il rapporto. Detto per intero se è durato almeno tre quarti di quanto dovrebbe, con il rapporto ricavato dalle righe che non spostano il fuoco (mediana: iPhone %s, iPad %s). Un annuncio tagliato avrebbe un rapporto più alto.\n\n| Quando | Annuncio (caratteri) | sposta il fuoco | iPhone: 50 → 90 (rapporto) | iPad: 50 → 90 (rapporto) |\n|---|---|---|---|---|\n"
            % tuple("%.2f" % statistics.median(rapporti[x]) if rapporti.get(x) else "—" for x in ("iphone", "ipad")))
    for (blocco, passo, k), v in tavola.items():
        if blocco != "velocita":
            continue
        celle = []
        for ap in ("iphone", "ipad"):
            e = v["celle"].get((ap, "dopo"))
            if not e or not e[-1][0].get("rapporto"):
                celle.append("—")
                continue
            a = e[-1][0]
            celle.append("%.2f → %.2f s (%.2f) %s" % (a["lenta"], a["detto"], a["rapporto"], "intero" if intero(a) else "interrotto"))
        f.write("| %s | «%s» (%d) | %s | %s |\n" % (passo, v["testo"].replace("\n", " ").replace("|", "/")[:60] + ("…" if len(v["testo"]) > 60 else ""), len(v["testo"]), "sì" if v["sposta"] else "no", " | ".join(celle)))
    f.write("\n## Gli annunci della build 32 tagliati che il sistema dava per riusciti\n\nPerché la notifica di conclusione non decide da sola: la voce li ha detti per il tempo della seconda colonna, e la notifica dice «riuscito».\n\n| Apparecchio | Detto | Quando | Caratteri |\n|---|---|---|---|\n")
    for d in righe:
        for a in d["annunci"]:
            if d["versione"] == "prima" and a["detto"] is not None and a["concluso_riuscito"] == "true" and not intero(a):
                f.write("| %s | %.2f s | %s · %s | %d |\n" % (d["apparecchio"], a["detto"], d["blocco"], d["passo"], a["caratteri"]))
    # Dove arriva il fuoco, nei passi che lo spostano: l'ultimo elemento che lo riceve.
    f.write("\n## Dove arriva il fuoco\n\nL'ultimo elemento che riceve il fuoco in ciascun passo che lo sposta o cambia schermata.\n\n"
            "| Quando | iPhone prima | iPhone dopo | iPad prima | iPad dopo |\n|---|---|---|---|---|\n")
    arrivi = collections.OrderedDict()
    for percorso in sys.argv[2:]:
        with open(percorso, encoding="utf-8") as h:
            for r in h:
                d = json.loads(r)
                if d.get("sposta") and "fuochi" in d:
                    chiave = (d["blocco"], d["passo"])
                    arrivi.setdefault(chiave, {})[(d["apparecchio"], d["versione"])] = (d["fuochi"] or [[0, "—"]])[-1][1][:48]
    for (blocco, passo), celle in arrivi.items():
        f.write("| %s · %s | %s |\n" % (blocco, passo, " | ".join(celle.get(c, "—").replace("|", "/") for c in colonne)))
print(open(sys.argv[1], encoding="utf-8").read())
