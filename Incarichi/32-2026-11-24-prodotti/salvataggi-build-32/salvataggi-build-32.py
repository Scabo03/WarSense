#!/usr/bin/env python3
"""La prova dal vivo dei salvataggi della build 32 (incarico 32, terza parte): sullo stesso simulatore, con l'app compilata
dal commit 06dee59 si cominciano un regno con la campagna aperta, una campagna di prova e uno scontro, e si prosegue
qualche giornata; poi si installa sopra l'app nuova, senza toglierla, e si riprendono i tre salvataggi.

Uso: salvataggi-build-32.py <cartella del pilota> <udid> scrivi|rileggi <stato.json> <diario.jsonl>
"""
import json
import pathlib
import re
import subprocess
import sys
import time

CARTELLA, UDID, VERBO = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
STATO, DIARIO = pathlib.Path(sys.argv[4]), pathlib.Path(sys.argv[5])
APP = "com.scabo.warsense"
_letti, _esiti, _prossimo = 0, {}, None
conto = {"si": 0, "no": 0}


def _leggi():
    global _letti
    f = CARTELLA / "esiti.jsonl"
    if not f.exists():
        return
    with f.open("rb") as h:
        h.seek(_letti)
        pezzo = h.read()
    fine = pezzo.rfind(b"\n")
    if fine < 0:
        return
    for riga in pezzo[:fine].split(b"\n"):
        try:
            e = json.loads(riga.decode("utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError):
            continue
        _esiti[e.get("n")] = e
    _letti += fine + 1


def cmd(c, attesa=300):
    global _prossimo
    fc = CARTELLA / "comandi.jsonl"
    if _prossimo is None:
        _prossimo = len(fc.read_text(encoding="utf-8").splitlines()) + 1 if fc.exists() else 1
    n = _prossimo
    _prossimo += 1
    with fc.open("a", encoding="utf-8") as f:
        f.write(json.dumps(dict(c, n=n), ensure_ascii=False) + "\n")
    limite = time.time() + attesa
    while time.time() < limite:
        _leggi()
        if n in _esiti:
            return _esiti[n]
        time.sleep(0.05)
    return {"n": n, "errore": "nessun esito"}


def scrivi(tipo, **dati):
    with DIARIO.open("a", encoding="utf-8") as f:
        f.write(json.dumps(dict(fase=VERBO, tipo=tipo, ora=time.strftime("%H:%M:%S"), **dati), ensure_ascii=False) + "\n")


def controlla(che_cosa, esito, **dati):
    conto["si" if esito else "no"] += 1
    scrivi("controllo", che_cosa=che_cosa, esito=bool(esito), **dati)
    print(("  si  " if esito else "  NO  ") + che_cosa + ("" if esito else "   " + json.dumps(dati, ensure_ascii=False)[:300]), flush=True)


def albero():
    return [re.sub(r" \[.*$", "", r) for r in cmd({"azione": "albero", "ascolto": 0.2}).get("albero", [])]


def attiva(ascolto=4, **chi):
    e = cmd(dict({"azione": "attiva", "ascolto": ascolto}, **chi))
    scrivi("attiva", chi=chi, sentito=e.get("ascoltate"), errore=e.get("errore"))
    return e


def puls(nome, ascolto=4):
    return attiva(ascolto, etichetta=nome, tipo="pulsante")


def avvia():
    cmd({"azione": "termina", "ascolto": 0.3})
    cmd({"azione": "avvia", "ascolto": 2.5})
    cmd({"azione": "vo_accendi", "ascolto": 1.5})


def caselle(prefisso):
    return sorted({n for n in albero() if re.match(prefisso, n)})


def giornali():
    r = subprocess.run(["xcrun", "simctl", "get_app_container", UDID, APP, "data"], capture_output=True, text=True, timeout=60)
    base = pathlib.Path(r.stdout.strip())
    out = {}
    for f in sorted(base.rglob("giornale.jsonl")):
        prima = f.read_text(encoding="utf-8").splitlines()[0]
        m = re.search(r'"versione_valori":"([^"]+)"', prima)
        out[str(f.relative_to(base))] = {"righe": sum(1 for _ in f.open(encoding="utf-8")), "valori": m.group(1) if m else None}
    return out


if VERBO == "scrivi":
    avvia()
    puls("Nuovo regno", 4)
    puls("Apri la campagna", 3)
    puls("fronte del guado, mappa 4 per 4", 10)
    attiva(3, prefisso="riga 4, casella 4")
    puls("Presidia: resta fermo in guardia", 4)
    for _ in range(3):
        puls("Chiudi la giornata", 6)
    regno = caselle(r"^riga \d+, casella \d+,")
    puls("Torna in patria", 4)
    patria = [n for n in albero() if re.match(r"^\w+, (gruppo armato|formazione)", n)]
    avvia()
    puls("Nuova campagna, mappa piccola", 10)
    for _ in range(2):
        puls("Chiudi la giornata", 6)
    campagna = caselle(r"^riga \d+, casella \d+,")
    avvia()
    puls("Nuovo scontro di prova", 10)
    attiva(3, prefisso="fanteria leggera")
    attiva(5, prefisso="riga 10, cella 4")
    puls("Fine del turno", 25)
    scontro = caselle(r"^riga \d+, cella \d+, (tua|tuo|tuoi|tue|fanteria|tiratori|cavalleria)")
    cmd({"azione": "termina", "ascolto": 0.5})
    g = giornali()
    STATO.write_text(json.dumps(dict(regno=regno, patria=patria, campagna=campagna, scontro=scontro, giornali=g), ensure_ascii=False, indent=1), encoding="utf-8")
    scrivi("scritto", caselle_del_regno=len(regno), caselle_della_campagna=len(campagna), reparti_dello_scontro=len(scontro), giornali=g)
    print("scritti:", {k: len(v) for k, v in (("regno", regno), ("campagna", campagna), ("scontro", scontro))}, json.dumps(g), flush=True)
else:
    prima = json.loads(STATO.read_text(encoding="utf-8"))
    scrivi("giornali_prima_di_aprire", giornali=giornali())
    avvia()
    nomi = albero()
    controlla("l'avvio offre di riprendere il regno, la campagna e lo scontro",
              "Riprendi il regno" in nomi and "Riprendi la campagna in corso" in nomi and any(n.startswith("Riprendi lo scontro") for n in nomi), avvio=nomi[:14])
    puls("Riprendi il regno", 6)
    nomi = albero()
    controlla("il regno si riapre in patria", any(n.startswith("Entra nel fronte") for n in nomi), nomi=nomi[:12])
    righe = [n for n in nomi if re.match(r"^\w+, (gruppo armato|formazione)", n)]
    controlla("le formazioni sono quelle, e dicono dove sono adesso", len(righe) == len(prima["patria"]) and all("Sul fronte, in riga" in n or "Resta in patria" in n for n in righe), righe=righe)
    attiva(12, prefisso="Entra nel fronte", tipo="pulsante")
    ora = caselle(r"^riga \d+, casella \d+,")
    controlla("la campagna del regno è dov'era", ora == prima["regno"], diverse=sorted(set(ora) ^ set(prima["regno"]))[:6])
    controlla("il richiamo si offre anche qui", any(n.startswith("Richiama l'esercito in patria") for n in albero()))
    e = puls("Chiudi la giornata", 12)
    controlla("e la giornata si chiude", any("Giornata chiusa" in p for p in e.get("ascoltate", [])), sentito=e.get("ascoltate"))
    avvia()
    puls("Riprendi la campagna in corso", 8)
    ora = caselle(r"^riga \d+, casella \d+,")
    controlla("la campagna di prova è dov'era", ora == prima["campagna"], diverse=sorted(set(ora) ^ set(prima["campagna"]))[:6])
    controlla("e non ha il richiamo", not any(n.startswith("Richiama l'esercito") for n in albero()))
    e = puls("Chiudi la giornata", 12)
    controlla("e la giornata si chiude", any("Giornata chiusa" in p for p in e.get("ascoltate", [])), sentito=e.get("ascoltate"))
    avvia()
    attiva(8, prefisso="Riprendi lo scontro", tipo="pulsante")
    ora = caselle(r"^riga \d+, cella \d+, (tua|tuo|tuoi|tue|fanteria|tiratori|cavalleria)")
    controlla("lo scontro è dov'era", ora == prima["scontro"], diverse=sorted(set(ora) ^ set(prima["scontro"]))[:6])
    e = puls("Fine del turno", 25)
    controlla("e il turno si chiude", not e.get("errore"), sentito=e.get("ascoltate"))
    cmd({"azione": "termina", "ascolto": 0.5})
    g = giornali()
    scrivi("giornali_dopo", giornali=g)
    controlla("i giornali restano quelli, scritti coi valori 0.15.0, e proseguono",
              all(v["valori"] == "0.15.0" and v["righe"] > prima["giornali"][k]["righe"] for k, v in g.items() if k in prima["giornali"] and "regno/giornale" not in k.lower()),
              prima=prima["giornali"], dopo=g)
    print(f"controlli: {conto['si']} su {conto['si'] + conto['no']}", flush=True)
