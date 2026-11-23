#!/usr/bin/env python3
"""I salvataggi della build 31 e l'app nuova (incarico 31).

Due tempi, sullo stesso simulatore, col pilota dell'incarico 28 e VoiceOver acceso:

  prima  — gira il pilota COSTRUITO DAL COMMIT DELLA BUILD 31 (7ef91fd), che installa l'app della build 31:
           un regno portato al primo inverno con una leva ordinata; una campagna piccola portata al terzo
           giorno con un ordine dato; uno scontro di prova con una riserva piazzata. Di ciascuno si registra
           ciò che la schermata espone, e del giornale del regno la lunghezza e l'impronta. L'app si chiude.
  dopo   — gira il pilota costruito dal codice dell'incarico 31, che installa l'app nuova SOPRA la vecchia (i
           dati restano): l'avvio deve offrire le tre riprese; «Riprendi il regno» deve DICHIARARE che il regno
           è di un formato precedente e non aprirlo, lasciando il suo giornale com'era (lo schema del giornale
           del regno è passato da 1 a 2); la campagna e lo scontro devono riaprirsi esponendo esattamente ciò
           che esponevano, e proseguire; «Nuovo regno» deve aprire un regno nuovo.

Uso: python3 migrazione.py prima|dopo <cartella del pilota> <cartella degli esiti> <udid>
"""
import hashlib
import json
import pathlib
import re
import subprocess
import sys
import time

TEMPO = sys.argv[1]
CARTELLA = pathlib.Path(sys.argv[2])
ESITI = pathlib.Path(sys.argv[3])
UDID = sys.argv[4]
ESITI.mkdir(parents=True, exist_ok=True)
STATO = ESITI / "stato-con-la-build-31.json"
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


def giornale_del_regno():
    """Lunghezza e impronta del giornale del regno nel contenitore dei dati dell'app sul simulatore."""
    contenitore = subprocess.run(["xcrun", "simctl", "get_app_container", UDID, "com.scabo.warsense", "data"],
                                 capture_output=True, text=True).stdout.strip()
    f = pathlib.Path(contenitore) / "Documents" / "Partite" / "regno" / "giornale.jsonl"
    if not f.exists():
        return {"esiste": False}
    dati = f.read_bytes()
    prima_riga = dati.split(b"\n")[0].decode("utf-8", "replace")
    schema = re.search(r'"versione_schema":(\d+)', prima_riga)
    return {"esiste": True, "byte": len(dati), "sha256": hashlib.sha256(dati).hexdigest(),
            "righe": dati.count(b"\n"), "schema": int(schema.group(1)) if schema else None}


def avvia():
    cmd({"azione": "termina", "ascolto": 0.3})
    cmd({"azione": "avvia", "ascolto": 2})
    cmd({"azione": "vo_accendi", "ascolto": 1})


def prima():
    avvia()
    nomi = albero()
    controlla("build 31: l'avvio offre il regno", "Nuovo regno" in nomi and "Nuova campagna, mappa piccola" in nomi,
              "«Nuovo regno» e «Nuova campagna, mappa piccola» presenti", [n for n in nomi if n.startswith("Nuov")])
    # Il regno: primo inverno, una leva ordinata.
    attiva(etichetta="Nuovo regno", tipo="pulsante", ascolto=5)
    attiva(etichetta="Attendi l'inverno", tipo="pulsante", ascolto=6)
    e = attiva(contiene="Leva di fanteria leggera. Costa", ascolto=4)
    regno = [n for n in albero() if not n.startswith("Vertical scroll bar")]
    controlla("build 31: il regno è al primo inverno con una leva ordinata",
              "Anno 1, inverno, schermata 1 di 4" in regno and "Leva di fanteria leggera, pronta in primavera" in regno,
              "«Anno 1, inverno, schermata 1 di 4» e «Leva di fanteria leggera, pronta in primavera»",
              [n for n in regno if n.startswith("Anno") or n.startswith("Leva di fanteria leggera,")] + [sentito(e)])
    cmd({"azione": "schermata", "nome": "regno-con-la-build-31", "ascolto": 0.3})
    attiva(etichetta="Torna all'inizio", tipo="pulsante", ascolto=4)
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
    controlla("build 31: la campagna è al terzo giorno", any("Giorno 3" in s for s in stato_campagna), "Giorno 3. …", stato_campagna)
    cmd({"azione": "schermata", "nome": "campagna-con-la-build-31", "ascolto": 0.3})
    attiva(etichetta="Torna all'inizio", tipo="pulsante", ascolto=4)
    # Lo scontro: una riserva piazzata.
    attiva(etichetta="Nuovo scontro di prova", tipo="pulsante", ascolto=8)
    attiva(etichetta="fanteria leggera", ascolto=2.5)
    valide = [n for n in albero() if re.match(r"riga \d+, cella \d+, libera, costa \d+, restano \d+$", n)]
    m = re.match(r"(riga \d+, cella \d+),", valide[0])
    attiva(contiene=m.group(1) + ",", ascolto=3)
    scontro = celle(albero())
    piazzata = [n for n in scontro if "tua fanteria leggera A" in n]
    controlla("build 31: nello scontro una riserva è piazzata", len(piazzata) == 1, "una cella con «tua fanteria leggera A»", piazzata)
    cmd({"azione": "schermata", "nome": "scontro-con-la-build-31", "ascolto": 0.3})
    cmd({"azione": "termina", "ascolto": 0.3})
    giornale = giornale_del_regno()
    controlla("build 31: il giornale del regno è sul disco, di schema 1", giornale.get("schema") == 1,
              "un giornale di schema 1", giornale)
    STATO.write_text(json.dumps({"regno": regno, "giornale_del_regno": giornale, "campagna": campagna,
                                 "stato_campagna": stato_campagna, "scontro": scontro},
                                ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"registrato: {len(campagna)} caselle della campagna, {len(scontro)} celle dello scontro")


def dopo():
    atteso = json.loads(STATO.read_text(encoding="utf-8"))
    cmd({"azione": "avvia", "ascolto": 3})
    cmd({"azione": "vo_accendi", "ascolto": 1})
    nomi = albero()
    attese = ["Riprendi il regno", "Nuovo regno", "Riprendi lo scontro in corso", "Riprendi la campagna in corso"]
    controlla("app nuova: l'avvio offre il regno e le tre riprese", all(x in nomi for x in attese), attese,
              [n for n in nomi if n.startswith("Nuovo regno") or n.startswith("Riprendi")])
    # Il regno della build 31: dichiarato di un formato precedente, non aperto, e il suo giornale intatto.
    e = attiva(etichetta="Riprendi il regno", tipo="pulsante", ascolto=6)
    detto = sentito(e)
    frase = "Il regno salvato è di un formato precedente e non può essere aperto"
    controlla("app nuova: «Riprendi il regno» dichiara che il regno è di un formato precedente",
              frase[:60] in detto, frase + " (le pronunce si troncano a 64 caratteri)", detto)
    nomi = albero()
    controlla("app nuova: il regno incompatibile non si apre — si resta all'avvio",
              "Nuovo regno" in nomi and "Patria" not in nomi, "l'avvio, senza la patria",
              [n for n in nomi if n in ("Patria", "Nuovo regno", "Riprendi il regno")])
    giornale = giornale_del_regno()
    controlla("app nuova: il giornale del regno rifiutato resta byte per byte com'era",
              giornale == atteso["giornale_del_regno"], atteso["giornale_del_regno"], giornale)
    cmd({"azione": "schermata", "nome": "regno-della-build-31-rifiutato", "ascolto": 0.3})
    e = attiva(etichetta="Riprendi la campagna in corso", tipo="pulsante", ascolto=6)
    campagna = caselle(albero())
    controlla("app nuova: la campagna della build 31 si riapre, e la mappa espone esattamente ciò che esponeva",
              campagna == atteso["campagna"] and len(campagna) > 0,
              f"{len(atteso['campagna'])} caselle identiche",
              f"{len(campagna)} caselle; diverse: {[(a, b) for a, b in zip(atteso['campagna'], campagna) if a != b][:3]}; sentito: {sentito(e)}")
    stato = tocco_magico("Registro della campagna")
    controlla("app nuova: l'informazione di stato è la stessa", stato == atteso["stato_campagna"], atteso["stato_campagna"], stato)
    cmd({"azione": "schermata", "nome": "campagna-riaperta-con-l-app-nuova", "ascolto": 0.3})
    e = attiva(etichetta="Chiudi la giornata", tipo="pulsante", ascolto=5)
    stato = tocco_magico("Registro della campagna")
    controlla("app nuova: la campagna riaperta prosegue — la giornata si chiude e comincia il quarto giorno",
              any("Giorno 4" in s for s in stato), "Giorno 4. …", stato + [sentito(e)])
    attiva(etichetta="Torna all'inizio", tipo="pulsante", ascolto=4)
    e = attiva(etichetta="Riprendi lo scontro in corso", tipo="pulsante", ascolto=8)
    scontro = celle(albero())
    controlla("app nuova: lo scontro della build 31 si riapre, e la griglia espone esattamente ciò che esponeva",
              scontro == atteso["scontro"] and len(scontro) > 0,
              f"{len(atteso['scontro'])} celle identiche",
              f"{len(scontro)} celle; diverse: {[(a, b) for a, b in zip(atteso['scontro'], scontro) if a != b][:3]}; sentito: {sentito(e)}")
    cmd({"azione": "schermata", "nome": "scontro-riaperto-con-l-app-nuova", "ascolto": 0.3})
    # Un regno nuovo si apre, sullo stesso apparecchio, al posto di quello che non si può riaprire.
    # Si riparte dall'avvio chiudendo e riaprendo l'app: nella prima corsa il guidatore cercava sulla
    # schermata di battaglia un «Torna all'inizio» che lì non c'è, e i due controlli che seguono erano
    # falliti per questo (`prima-corsa/`).
    avvia()
    attiva(etichetta="Nuovo regno", tipo="pulsante", ascolto=6)
    nomi = albero()
    controlla("app nuova: «Nuovo regno» apre la patria, con le formazioni che portano il loro nome",
              "Patria" in nomi and any(n.startswith("Corvo, gruppo armato: ") for n in nomi),
              "«Patria» e una riga che comincia con «Corvo, gruppo armato: »",
              [n for n in nomi if n == "Patria" or n.startswith("Corvo")])
    giornale = giornale_del_regno()
    controlla("app nuova: il regno nuovo ha il giornale di schema 2", giornale.get("schema") == 2, "schema 2", giornale)
    cmd({"azione": "schermata", "nome": "regno-nuovo-con-l-app-nuova", "ascolto": 0.3})
    cmd({"azione": "termina", "ascolto": 0.3})


if __name__ == "__main__":
    t0 = time.time()
    {"prima": prima, "dopo": dopo}[TEMPO]()
    righe = [json.loads(r) for r in CONTROLLI.read_text(encoding="utf-8").splitlines()] if CONTROLLI.exists() else []
    righe = [r for r in righe if r["tempo"] == TEMPO]
    print(f"{TEMPO}: controlli {len(righe)}, ok {sum(1 for r in righe if r['esito'] == 'ok')}, NO {sum(1 for r in righe if r['esito'] != 'ok')}; durata {time.time() - t0:.0f} s")
