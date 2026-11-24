#!/usr/bin/env python3
"""Le tabelle prima e dopo delle battaglie che non finiscono, della frequenza, dello squilibrio fra le mappe e del banco
del regno, dai dati grezzi di questa cartella. Non ha parametri: legge e scrive accanto a sé (`tabelle.md`).

  prima   dati del codice della build 32 (commit 06dee59, valori 0.15.0)
  dopo    dati del codice dell'incarico 32 (valori 0.16.0)
  pari    come «dopo», ma il tattico che al banco gioca per il giocatore non si arrende a metà delle perdite
"""
import collections
import json
import pathlib

QUI = pathlib.Path(__file__).resolve().parent
FORMATI = ("campagna_piccola", "campagna_media", "campagna_grande")
FRONTI = ("guado", "istmo", "pianura_lunga")
CONDOTTE = ("competente", "prudente", "mirata")
MAPPE = {"campagna_piccola": "piccola (guado)", "campagna_media": "media (istmo)", "campagna_grande": "grande (pianura lunga)",
         "guado": "guado", "istmo": "istmo", "pianura_lunga": "pianura lunga"}


def leggi(percorso):
    with open(QUI / percorso, encoding="utf-8") as f:
        return [json.loads(riga) for riga in f if riga.strip()]


def percento(parte, tutto):
    return "—" if not tutto else f"{100 * parte / tutto:.1f}%".replace(".", ",")


def mediana(valori):
    v = sorted(valori)
    if not v:
        return "—"
    m = len(v) // 2
    return str(v[m]) if len(v) % 2 else f"{(v[m - 1] + v[m]) / 2:g}".replace(".", ",")


def tabella(intestazione, righe):
    u = ["| " + " | ".join(intestazione) + " |", "|" + "---|" * len(intestazione)]
    u += ["| " + " | ".join(str(c) for c in r) + " |" for r in righe]
    return "\n".join(u) + "\n"


frequenza = {"prima": leggi("frequenza-battaglie/prima/frequenza-battaglie.jsonl"),
             "dopo": leggi("frequenza-battaglie/dopo/frequenza-battaglie.jsonl"),
             "pari": leggi("squilibrio/frequenza-tattico-pari/frequenza-battaglie.jsonl")}
regno = {"prima": leggi("banco-del-regno/prima/banco-del-regno.jsonl"),
         "dopo": leggi("banco-del-regno/dopo/banco-del-regno.jsonl"),
         "pari": leggi("squilibrio/banco-del-regno-tattico-pari/banco-del-regno.jsonl")}
testo = ["# Tabelle prima e dopo (incarico 32)\n",
         "Prodotte da `tabelle.py` sui dati grezzi di questa cartella. «Prima» è il codice della build 32 (06dee59, valori "
         "0.15.0), «dopo» quello dell'incarico 32 (valori 0.16.0), «pari» è «dopo» col tattico del giocatore del banco che "
         "non si arrende a metà delle perdite.\n"]

# ---------------------------------------------------------------- le battaglie che non finiscono
testo.append("\n## 1. Le battaglie che non finiscono\n")
righe = []
for misura, dati, chiave in (("frequenza (730 giornate)", frequenza, "fine"), ("banco del regno (5 anni)", regno, "conclusione")):
    for quando in ("prima", "dopo", "pari"):
        d = dati[quando]
        ferme = [r for r in d if r[chiave] == "ferma"]
        cause = collections.Counter((r.get("diagnosi") or {}).get("causa", "non diagnosticata") for r in ferme)
        righe.append((misura, quando, len(d), len(ferme), ", ".join(f"{c}: {n}" for c, n in cause.items()) or "—",
                      sum(bool(r["violazioni"]) for r in d)))
testo.append(tabella(("misura", "", "partite o anni", "fermi su una battaglia che non finisce", "causa", "con violazioni"), righe))

# ---------------------------------------------------------------- la frequenza
testo.append("\n## 2. La frequenza delle battaglie\n")
righe = []
for condotta in CONDOTTE:
    for formato in FORMATI:
        for quando in ("prima", "dopo"):
            g = [r for r in frequenza[quando] if r["condotta"] == condotta and r["formato"] == formato]
            if not g:
                continue
            giornate = sum(r["giornate"] for r in g)
            fine = collections.Counter(r["fine"] for r in g)
            prime = [r["prima_battaglia"] for r in g if r.get("prima_battaglia")]
            righe.append((condotta, MAPPE[formato], quando, len(g), sum(r["battaglie"] for r in g),
                          f"{10 * sum(r['battaglie'] for r in g) / giornate:.3f}".replace(".", ","), mediana(prime),
                          sum(r["battaglie"] == 0 for r in g), fine["avversario_senza_armati"], fine["giocatore_senza_armati"],
                          fine["limite"], fine["ferma"]))
testo.append(tabella(("condotta", "mappa", "", "partite", "battaglie", "ogni 10 giornate", "prima battaglia (mediana)",
                      "senza battaglie", "avversario senza armati", "giocatore senza armati", "al limite", "ferme"), righe))

# ---------------------------------------------------------------- lo squilibrio
testo.append("\n## 3. Lo squilibrio fra le mappe: le battaglie vinte dal giocatore\n")
testo.append("In ogni cella: le battaglie vinte su quelle giocate e, dopo il punto e virgola, le sole COMBATTUTE, cioè quelle in "
             "cui almeno una delle due parti ha perso un atomo. Le altre si concludono coi reparti intatti: prima, perché una "
             "parte era annientata al suo primo comando (il difetto del budget del primo turno); dopo, perché i due "
             "schieramenti non possono incontrarsi e l'avversario si ritira (lo stallo, 01 §10.7.1).\n\n")
senza = {"frequenza": leggi("squilibrio/prima-senza-perdite/frequenza-battaglie.jsonl"),
         "regno": leggi("squilibrio/prima-senza-perdite/banco-del-regno.jsonl")}


def cella_dello_squilibrio(g):
    v, p = sum(r["vinte"] for r in g), sum(r["perse"] for r in g)
    cv = v - sum(r["vinte_senza_perdite"] for r in g)
    cp = p - sum(r["perse_senza_perdite"] for r in g)
    if not g:
        return "non giocata"
    return f"{v} su {v + p} ({percento(v, v + p)}); combattute {cv} su {cv + cp} ({percento(cv, cv + cp)})"


for titolo, chiave, dati, luoghi, campo in (
        ("Campagne di prova (misura della frequenza, 200 partite per cella, 730 giornate):", "frequenza", frequenza, FORMATI, "formato"),
        ("Campagne del regno (banco del regno, 200 partite di 5 anni per condotta):", "regno", regno, FRONTI, "fronte")):
    righe = []
    for condotta in CONDOTTE:
        for luogo in luoghi:
            r_ = [condotta, MAPPE[luogo]]
            for insieme in (senza[chiave], dati["dopo"], dati["pari"]):
                r_.append(cella_dello_squilibrio([r for r in insieme if r["condotta"] == condotta and r[campo] == luogo]))
            righe.append(r_)
    testo.append("\n" + titolo + "\n\n")
    testo.append(tabella(("condotta", "mappa", "prima", "dopo", "pari"), righe))
righe = []
for condotta in CONDOTTE:
    for fronte in FRONTI:
        r_ = [condotta, MAPPE[fronte]]
        for insieme in (senza["regno"], regno["dopo"], regno["pari"]):
            g = [r for r in insieme if r["condotta"] == condotta and r["fronte"] == fronte]
            r_.append("non giocata" if not g else
                      f"{percento(sum(r.get('vincitore') == 'giocatore' for r in g), len(g))} vinte, "
                      f"{percento(sum(r.get('vincitore') == 'avversario' for r in g), len(g))} perse")
        righe.append(r_)
testo.append("\nLe campagne del regno vinte e perse dal giocatore (le altre le interrompe l'inverno; «prima», in 78 anni, la "
             "partita si fermava):\n\n")
testo.append(tabella(("condotta", "mappa", "prima", "dopo", "pari"), righe))

# ---------------------------------------------------------------- i duelli
testo.append("\n## 4. I duelli fra i gruppi armati degli scenari\n")
testo.append("Un gruppo contro l'altro, coi due tattici del banco, le due parti e i due ordini. «Immobili» sono i reparti in "
             "campo che non possono fare nemmeno un passo con il volume di un turno. L = fanteria leggera, P = fanteria "
             "pesante, C = cavalleria manovrata.\n\n")
duelli = {"prima": leggi("squilibrio/duelli-prima/duelli.jsonl"), "dopo": leggi("squilibrio/duelli-dopo/duelli.jsonl")}


def indice(dati, serie):
    return {(d["giocatore"], d["avversario"], d["primo"]): d for d in dati if d["serie"] == serie}


p, d, e = indice(duelli["prima"], "scenari"), indice(duelli["dopo"], "scenari"), indice(duelli["dopo"], "scenari_tattico_pari")


def esito(x):
    if x is None:
        return "—"
    vincitore = {"giocatore": "giocatore", "avversario": "avversario", None: "nessuno"}[x.get("vincitore")]
    return f"{vincitore}, turno {x['giri']} ({x['modo'].replace('_', ' ')}); restano {sum(x['atomiGiocatore'])} e {sum(x['atomiAvversario'])}"


righe = []
for k in sorted(d, key=lambda k: (k[1], k[0], k[2])):
    righe.append((k[0], k[1], k[2], esito(p.get(k)), esito(d[k]), esito(e.get(k))))
testo.append(tabella(("giocatore", "avversario", "agisce per primo", "prima", "dopo", "pari"), righe))

# ---------------------------------------------------------------- le proposte
testo.append("\n## 5. Le proposte, con l'effetto misurato\n")
testo.append("Nessun file del gioco cambia. Le composizioni: `squilibrio/proposte.py` misura copie dei valori; la variante 0 è il "
             "gioco com'è. Le due alternative di regola (`squilibrio/alternative/`): il codice dell'incarico con la modifica "
             "del file `modifica.patch` accanto ai numeri. In ogni cella le battaglie vinte dal giocatore e, dopo il punto e "
             "virgola, le sole combattute; fra parentesi quadre lo stesso col tattico del giocatore che non si arrende a metà "
             "delle perdite.\n\n")
cartelle = sorted((QUI / "squilibrio/proposte").iterdir()) + sorted((QUI / "squilibrio/alternative").iterdir())


def conti(percorso):
    with open(percorso, encoding="utf-8") as f:
        nomi = f.readline().rstrip("\n").split("|")
        return [dict(zip(nomi, riga.rstrip("\n").split("|"))) for riga in f if riga.strip()]


def cella_dei_conti(c):
    v, p, vs, ps = (int(c[k]) for k in ("vinte", "perse", "vinte_senza_perdite", "perse_senza_perdite"))
    u = f"{percento(v, v + p)} di {v + p}; {percento(v - vs, v + p - vs - ps)} di {v + p - vs - ps}"
    return u + (f"; FERME {c['ferme']}" if int(c["ferme"]) else "")


righe = []
for cartella in cartelle:
    r_ = [cartella.name]
    for formato in FORMATI:
        c, d = (next(x for x in conti(cartella / f"frequenza-in-breve{s}.txt") if x["condotta"] == "competente" and x["formato"] == formato)
                for s in ("", "-tattico-pari"))
        def combattute(x):
            v, p, vs, ps = (int(x[k]) for k in ("vinte", "perse", "vinte_senza_perdite", "perse_senza_perdite"))
            return percento(v - vs, v + p - vs - ps)
        senza_perdite = int(c["vinte_senza_perdite"]) + int(c["perse_senza_perdite"])
        r_.append(f"{combattute(c)} [{combattute(d)}]" + (f"; {senza_perdite} senza perdite" if senza_perdite else ""))
    for fronte in FRONTI:
        x = next(y for y in conti(cartella / "banco-del-regno-in-breve.txt") if y["condotta"] == "mirata" and y["fronte"] == fronte)
        r_.append(percento(int(x["campagne_vinte"]), int(x["anni"])))
    r_.append(sum(int(y["ferme"]) for s in ("", "-tattico-pari") for y in conti(cartella / f"frequenza-in-breve{s}.txt")
                  + conti(cartella / f"banco-del-regno-in-breve{s}.txt")))
    righe.append(r_)
testo.append("In breve. Le prime tre colonne: battaglie COMBATTUTE vinte dalla condotta competente nelle campagne di prova, fra "
             "parentesi quadre col tattico che non si arrende, e quante battaglie si sono concluse senza che nessuno perdesse "
             "un uomo. Le altre tre: campagne del regno vinte dalla condotta mirata. L'ultima: battaglie che non si concludono.\n\n")
testo.append(tabella(("variante", "piccola", "media", "grande", "guado", "istmo", "pianura lunga", "ferme"), righe))
testo.append("\n")

righe = []
for cartella in cartelle:
    for condotta in ("competente", "mirata"):
        r_ = [cartella.name, condotta]
        for formato in FORMATI:
            celle = [next(cella_dei_conti(c) for c in conti(cartella / f"frequenza-in-breve{s}.txt")
                          if c["condotta"] == condotta and c["formato"] == formato) for s in ("", "-tattico-pari")]
            r_.append(f"{celle[0]} [{celle[1]}]")
        righe.append(r_)
testo.append("Campagne di prova, 200 partite per cella:\n\n")
testo.append(tabella(("variante", "condotta", *(MAPPE[f] for f in FORMATI)), righe))
righe, righe_c = [], []
for cartella in cartelle:
    for condotta in CONDOTTE:
        r_, rc = [cartella.name, condotta], [cartella.name, condotta]
        for fronte in FRONTI:
            due = [next(c for c in conti(cartella / f"banco-del-regno-in-breve{s}.txt")
                        if c["condotta"] == condotta and c["fronte"] == fronte) for s in ("", "-tattico-pari")]
            r_.append(f"{cella_dei_conti(due[0])} [{cella_dei_conti(due[1])}]")
            rc.append(" ".join(("" if k == 0 else "[") + f"{percento(int(c['campagne_vinte']), int(c['anni']))} vinte, "
                      f"{percento(int(c['campagne_perse']), int(c['anni']))} perse" + ("" if k == 0 else "]")
                      for k, c in enumerate(due)))
        righe.append(r_)
        righe_c.append(rc)
testo.append("\nCampagne del regno, 200 partite di 5 anni per condotta — le battaglie:\n\n")
testo.append(tabella(("variante", "condotta", *(MAPPE[f] for f in FRONTI)), righe))
testo.append("\nLe stesse — le campagne vinte e perse:\n\n")
testo.append(tabella(("variante", "condotta", *(MAPPE[f] for f in FRONTI)), righe_c))

# ---------------------------------------------------------------- il banco del regno
testo.append("\n## 6. Il banco del regno\n")
righe = []
for condotta in CONDOTTE:
    for fronte in FRONTI:
        for quando in ("prima", "dopo"):
            g = [r for r in regno[quando] if r["condotta"] == condotta and r["fronte"] == fronte]
            if not g:
                continue
            modi = collections.Counter((r["conclusione"], r.get("vincitore")) for r in g)
            righe.append((condotta, MAPPE[fronte], quando, len(g), sum(r["battaglie"] for r in g),
                          modi[("annientamento", "giocatore")], modi[("annientamento", "avversario")],
                          modi[("presa", "giocatore")], modi[("presa", "avversario")],
                          modi[("inverno", None)], modi[("ferma", None)], mediana([r["giornate"] for r in g])))
testo.append(tabella(("condotta", "fronte", "", "anni", "battaglie", "vinti per annientamento", "persi per annientamento",
                      "vinti per presa", "persi per presa", "inverno", "fermi", "giornate (mediana)"), righe))

(QUI / "tabelle.md").write_text("\n".join(testo), encoding="utf-8")
print("tabelle.md", len("\n".join(testo)), "caratteri")
