#!/usr/bin/env python3
"""I salvataggi della build 30 si riaprono con la build 31? (incarico 30)

Due tempi, sullo stesso simulatore, col pilota dell'incarico 28 e VoiceOver acceso:

  prima  — gira il pilota COSTRUITO DAL COMMIT DELLA BUILD 30 (402a9b1), che installa l'app della build 30:
           una campagna piccola portata al terzo giorno con un ordine dato, e uno scontro di prova con una
           riserva piazzata; di ciascuno si registra ciò che la schermata espone (l'albero di accessibilità,
           senza le cornici) e l'informazione di stato. L'app si chiude con le due partite in corso.
  dopo   — gira il pilota costruito dal codice corrente, che installa l'app nuova SOPRA la vecchia (i dati
           restano): l'avvio deve offrire le due riprese; ripresa la campagna, la schermata deve esporre
           esattamente ciò che esponeva, e la giornata deve potersi chiudere; ripreso lo scontro, lo stesso.

Uso: python3 migrazione.py prima|dopo <cartella del pilota> <cartella degli esiti>
"""
import json
import pathlib
import re
import sys
import time

TEMPO = sys.argv[1]
CARTELLA = pathlib.Path(sys.argv[2])
ESITI = pathlib.Path(sys.argv[3])
ESITI.mkdir(parents=True, exist_ok=True)
STATO = ESITI / "stato-con-la-build-30.json"
CONTROLLI = ESITI / "controlli.jsonl"


def esiti():
    f = CARTELLA / "esiti.jsonl"
    out = []
    if f.exists():
        for r in f.read_text(encoding="utf-8").splitlines():
            try:
                out.append(json.loads(r))
            except json.JSONDecodeError:
                pass
    return out


def cmd(c, attesa=240):
    fc = CARTELLA / "comandi.jsonl"
    n = len(fc.read_text(encoding="utf-8").splitlines()) + 1 if fc.exists() else 1
    c = dict(c, n=n)
    with fc.open("a", encoding="utf-8") as f:
        f.write(json.dumps(c, ensure_ascii=False) + "\n")
    limite = time.time() + attesa
    while time.time() < limite:
        for e in esiti():
            if e.get("n") == n:
                return e
        time.sleep(0.25)
    return {"n": n, "errore": "nessun esito"}


def sentito(e):
    return " || ".join(e.get("ascoltate", [])) + " || " + e.get("dopo", "")


def albero():
    return [re.sub(r" \[.*$", "", r) for r in cmd({"azione": "albero", "ascolto": 0.2}).get("albero", [])]


def attiva(**chi):
    return cmd(dict({"azione": "attiva", "ascolto": chi.pop("ascolto", 3.0)}, **chi))


def tocco_magico(bersaglio):
    e = cmd({"azione": "multi_tocco", "tocchi": 2, "dita": 2, "etichetta": bersaglio, "tipo": "pulsante", "ascolto": 4})
    return [a for a in e.get("ascoltate", [])][-1:] or [e.get("dopo", "")]


def controlla(nome, esito, atteso, trovato):
    riga = dict(tempo=TEMPO, controllo=nome, esito="ok" if esito else "NO", atteso=atteso, trovato=trovato,
                ora=time.strftime("%H:%M:%S"))
    with CONTROLLI.open("a", encoding="utf-8") as f:
        f.write(json.dumps(riga, ensure_ascii=False) + "\n")
    print(("ok  " if esito else "NO  ") + nome + " — " + str(trovato)[:300], flush=True)


def caselle(nomi):
    return [n for n in nomi if re.match(r"riga \d+, casella \d+", n)]


def celle(nomi):
    return [n for n in nomi if re.match(r"riga \d+, cella \d+", n)]


def avvia():
    cmd({"azione": "termina", "ascolto": 0.3})
    cmd({"azione": "avvia", "ascolto": 2})
    cmd({"azione": "vo_accendi", "ascolto": 1})


def prima():
    avvia()
    nomi = albero()
    controlla("build 30: l'avvio non conosce il regno", "Nuovo regno" not in nomi and "Nuova campagna, mappa piccola" in nomi,
              "nessun «Nuovo regno»; «Nuova campagna, mappa piccola» presente", [n for n in nomi if n.startswith("Nuov")])
    # La campagna: un ordine dato, poi due giornate chiuse.
    attiva(etichetta="Nuova campagna, mappa piccola", tipo="pulsante", ascolto=6)
    attesa = [n for n in caselle(albero()) if ", in attesa" in n and re.search(r", tu[oa] ", n)]
    primo = re.match(r"riga \d+, casella \d+", attesa[0]).group(0)
    attiva(contiene=primo + ",", ascolto=2.5)
    e = attiva(etichetta="Presidia: resta fermo in guardia", tipo="pulsante", ascolto=3)
    for _ in range(2):
        attiva(etichetta="Chiudi la giornata", tipo="pulsante", ascolto=5)
    campagna = caselle(albero())
    stato_campagna = tocco_magico("Registro della campagna")
    controlla("build 30: la campagna è al terzo giorno", any("Giorno 3" in s for s in stato_campagna), "Giorno 3. …", stato_campagna)
    cmd({"azione": "schermata", "nome": "campagna-con-la-build-30", "ascolto": 0.3})
    attiva(etichetta="Torna all'inizio", tipo="pulsante", ascolto=4)
    # Lo scontro: una riserva piazzata.
    attiva(etichetta="Nuovo scontro di prova", tipo="pulsante", ascolto=8)
    attiva(etichetta="fanteria leggera", ascolto=2.5)
    valide = [n for n in albero() if re.match(r"riga \d+, cella \d+, libera, costa \d+, restano \d+$", n)]
    m = re.match(r"(riga \d+, cella \d+),", valide[0])
    attiva(contiene=m.group(1) + ",", ascolto=3)
    scontro = celle(albero())
    piazzata = [n for n in scontro if "tua fanteria leggera A" in n]
    controlla("build 30: nello scontro una riserva è piazzata", len(piazzata) == 1, "una cella con «tua fanteria leggera A»", piazzata)
    cmd({"azione": "schermata", "nome": "scontro-con-la-build-30", "ascolto": 0.3})
    STATO.write_text(json.dumps({"campagna": campagna, "stato_campagna": stato_campagna, "scontro": scontro},
                                ensure_ascii=False, indent=1), encoding="utf-8")
    cmd({"azione": "termina", "ascolto": 0.3})
    print(f"registrato: {len(campagna)} caselle della campagna, {len(scontro)} celle dello scontro")


def dopo():
    atteso = json.loads(STATO.read_text(encoding="utf-8"))
    cmd({"azione": "avvia", "ascolto": 3})
    cmd({"azione": "vo_accendi", "ascolto": 1})
    nomi = albero()
    controlla("build 31: l'avvio offre il regno e le due riprese",
              all(x in nomi for x in ["Nuovo regno", "Riprendi lo scontro in corso", "Riprendi la campagna in corso"]),
              ["Nuovo regno", "Riprendi lo scontro in corso", "Riprendi la campagna in corso"],
              [n for n in nomi if n.startswith("Nuovo regno") or n.startswith("Riprendi")])
    e = attiva(etichetta="Riprendi la campagna in corso", tipo="pulsante", ascolto=6)
    campagna = caselle(albero())
    controlla("build 31: la campagna della build 30 si riapre, e la mappa espone esattamente ciò che esponeva",
              campagna == atteso["campagna"] and len(campagna) > 0,
              f"{len(atteso['campagna'])} caselle identiche",
              f"{len(campagna)} caselle; diverse: {[(a, b) for a, b in zip(atteso['campagna'], campagna) if a != b][:3]}; sentito: {sentito(e)}")
    stato = tocco_magico("Registro della campagna")
    controlla("build 31: l'informazione di stato è la stessa", stato == atteso["stato_campagna"], atteso["stato_campagna"], stato)
    cmd({"azione": "schermata", "nome": "campagna-riaperta-con-la-build-31", "ascolto": 0.3})
    e = attiva(etichetta="Chiudi la giornata", tipo="pulsante", ascolto=5)
    stato = tocco_magico("Registro della campagna")
    controlla("build 31: la campagna riaperta prosegue — la giornata si chiude e comincia il quarto giorno",
              any("Giorno 4" in s for s in stato), "Giorno 4. …", stato + [sentito(e)])
    attiva(etichetta="Torna all'inizio", tipo="pulsante", ascolto=4)
    e = attiva(etichetta="Riprendi lo scontro in corso", tipo="pulsante", ascolto=8)
    scontro = celle(albero())
    controlla("build 31: lo scontro della build 30 si riapre, e la griglia espone esattamente ciò che esponeva",
              scontro == atteso["scontro"] and len(scontro) > 0,
              f"{len(atteso['scontro'])} celle identiche",
              f"{len(scontro)} celle; diverse: {[(a, b) for a, b in zip(atteso['scontro'], scontro) if a != b][:3]}; sentito: {sentito(e)}")
    cmd({"azione": "schermata", "nome": "scontro-riaperto-con-la-build-31", "ascolto": 0.3})
    cmd({"azione": "termina", "ascolto": 0.3})


if __name__ == "__main__":
    t0 = time.time()
    {"prima": prima, "dopo": dopo}[TEMPO]()
    righe = [json.loads(r) for r in CONTROLLI.read_text(encoding="utf-8").splitlines()] if CONTROLLI.exists() else []
    righe = [r for r in righe if r["tempo"] == TEMPO]
    print(f"{TEMPO}: controlli {len(righe)}, ok {sum(1 for r in righe if r['esito'] == 'ok')}, NO {sum(1 for r in righe if r['esito'] != 'ok')}; durata {time.time() - t0:.0f} s")
