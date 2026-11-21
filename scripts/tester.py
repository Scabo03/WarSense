#!/usr/bin/env python3
"""Il TESTER della sessione interattiva (incarico 28, seconda parte).

Gioca una partita con VoiceOver acceso attraverso il pilota (`SessioneInterattivaTest`), un passo
alla volta: ascolta ciò che VoiceOver pronuncia, legge l'albero essenziale, decide il passo
successivo. Non conosce lo stato del gioco se non per ciò che si sente e si vede: le etichette delle
caselle, gli annunci, l'informazione di stato del tocco magico. Canali usati: servizio VoiceOver delle
prove (lettura), comandi da tastiera di VoiceOver (rotori: scelta e salto), doppio tocco sintetico
sull'elemento (attivazione, solo in verticale), doppio tocco a due dita (tocco magico).

Uso: python3 scripts/tester.py <cartella del pilota> <formato: piccola|media|grande> [giornate massime]
Scrive il diario in <cartella>/diario-<formato>.jsonl e stampa un riassunto.
"""
import json
import pathlib
import re
import sys
import time

CARTELLA = pathlib.Path(sys.argv[1])
FORMATO = sys.argv[2]
GIORNATE = int(sys.argv[3]) if len(sys.argv) > 3 else 30
DIARIO = CARTELLA / f"diario-{FORMATO}.jsonl"

PANNELLO = {
    "marcia": "Marcia: scegli la casella sulla mappa", "presidio": "Presidia: resta fermo in guardia",
    "sosta": "Sosta con raccolta: resta fermo e raccogli provviste", "esplora": "Esplora la zona",
    "apri": "Apri la battaglia", "chiudi": "Chiudi il pannello",
}


def _esiti():
    f = CARTELLA / "esiti.jsonl"
    if not f.exists():
        return []
    out = []
    for r in f.read_text(encoding="utf-8").splitlines():
        try:
            out.append(json.loads(r))
        except json.JSONDecodeError:
            pass
    return out


def cmd(c, attesa=180):
    fc = CARTELLA / "comandi.jsonl"
    n = len(fc.read_text(encoding="utf-8").splitlines()) + 1 if fc.exists() else 1
    c = dict(c, n=n)
    with fc.open("a", encoding="utf-8") as f:
        f.write(json.dumps(c, ensure_ascii=False) + "\n")
    limite = time.time() + attesa
    while time.time() < limite:
        for e in _esiti():
            if e.get("n") == n:
                return e
        time.sleep(0.25)
    return {"n": n, "errore": "nessun esito"}


def diario(tipo, **dati):
    with DIARIO.open("a", encoding="utf-8") as f:
        f.write(json.dumps(dict(tipo=tipo, ora=time.strftime("%H:%M:%S"), **dati), ensure_ascii=False) + "\n")


def sentito(e):
    return " | ".join(e.get("ascoltate", [])) or e.get("dopo", "")


def tasto(t, mod=("control", "option"), ascolto=1.0):
    return cmd({"azione": "tasto", "tasto": t, "modificatori": list(mod), "ascolto": ascolto})


def attiva(**chi):
    e = cmd(dict({"azione": "attiva", "ascolto": chi.pop("ascolto", 2.0)}, **chi))
    diario("attiva", chi=chi, fuoco=e.get("fuoco"), sentito=sentito(e), errore=e.get("errore"))
    return e


def albero():
    return cmd({"azione": "albero", "ascolto": 0.2}).get("albero", [])


def etichette():
    return [re.sub(r" \[.*$", "", r) for r in albero()]


def tocco_magico():
    e = cmd({"azione": "multi_tocco", "tocchi": 2, "dita": 2, "ascolto": 3.0})
    s = sentito(e)
    diario("tocco_magico", sentito=s)
    return s


def scegli_rotore(nome, massimo=16):
    for _ in range(massimo):
        if nome in sentito(tasto("destra", ("control", "option", "command"), 0.8)):
            return True
    return False


def prossimo_nel_rotore(su=False):
    return sentito(tasto("su" if su else "giu", ("control", "option", "command"), 1.2))


# ---------------------------------------------------------------- la battaglia

def battaglia():
    diario("battaglia_aperta", sentito=sentito(cmd({"azione": "parla", "ascolto": 3})))
    for turno in range(1, 25):
        nomi = etichette()
        if "Resoconto della battaglia" in nomi:
            break
        # 1. Schieramento: la prima tessera con esemplari, poi la prima cella valida, fino a tre volte.
        for _ in range(3):
            tessere = [r for r in albero() if "esemplar" in r and "=" in r]
            if not tessere:
                break
            nome = re.sub(r" \[.*$", "", tessere[0])
            attiva(etichetta=nome)
            if not scegli_rotore("Celle valide"):
                break
            cella = prossimo_nel_rotore()
            m = re.match(r"(riga \d+, cella \d+)", cella)
            if not m:
                break
            attiva(prefisso=m.group(1) + ",")
        # 2. Attacco: ogni proprio reparto con azione, dal suo pannello, ingaggia o tira se può.
        if scegli_rotore("Tuoi reparti da muovere"):
            visti = set()
            for _ in range(6):
                s = prossimo_nel_rotore()
                m = re.match(r"(riga \d+, cella \d+)", s)
                if not m or m.group(1) in visti:
                    break
                visti.add(m.group(1))
                attiva(prefisso=m.group(1) + ",")
                voci = etichette()
                scelta = next((v for v in voci if v.startswith("Ingaggia") or v.startswith("Tira su")), None)
                attiva(etichetta=scelta or PANNELLO["chiudi"], tipo="pulsante")
        # 3. Resa se la battaglia si allunga, altrimenti fine del turno.
        if turno >= 14 and "Dichiara la resa" in etichette():
            attiva(etichetta="Dichiara la resa", tipo="pulsante", ascolto=3)
        else:
            attiva(etichetta="Fine del turno", tipo="pulsante", ascolto=4)
        diario("turno", numero=turno, stato=tocco_magico())
    resoconto = cmd({"azione": "giro", "ascolto": 0.5, "con_schermata": True, "nome": f"{FORMATO}-resoconto-{int(time.time())}"})
    diario("resoconto", pronunce=resoconto.get("pronunce"))
    attiva(etichetta="Torna all'inizio", tipo="pulsante", ascolto=3)
    # Il ripiegamento, se lo sconfitto ha più caselle: la prima voce del pannello.
    voci = etichette()
    if "Scegli dove ripiegare" in voci:
        v = next((v for v in voci if v.startswith("In riga ")), None)
        if v:
            attiva(etichetta=v, tipo="pulsante", ascolto=3)
    diario("ritorno_in_campagna", stato=tocco_magico())


# ---------------------------------------------------------------- la campagna

def armato(etichetta):
    return ("tuo " in etichetta or "tua " in etichetta) and "ricognizione" not in etichetta and "non armata" not in etichetta


def giornata(numero):
    stato = tocco_magico()
    diario("giornata", numero=numero, stato=stato)
    m = re.search(r"[Bb]attaglia in sospeso in riga (\d+), casella (\d+)", stato)
    if m or "battaglia in sospeso" in stato:
        if m:
            attiva(contiene=f"riga {m.group(1)}, casella {m.group(2)},")
        if PANNELLO["apri"] in etichette():
            attiva(etichetta=PANNELLO["apri"], tipo="pulsante", ascolto=4)
            battaglia()
            return "battaglia"
        attiva(etichetta=PANNELLO["chiudi"], tipo="pulsante")
    ordinati = 0
    gia = set()
    for _ in range(14):
        attesa = [n for n in etichette() if re.search(r"riga \d+, casella \d+", n)
                  and ", in attesa" in n and ("tuo " in n or "tua " in n)]
        attesa = [n for n in attesa if re.search(r"riga \d+, casella \d+", n).group(0) not in gia]
        if not attesa:
            break
        s = attesa[0]
        m = re.search(r"riga (\d+), casella (\d+)", s)
        r, c = int(m.group(1)), int(m.group(2))
        gia.add(m.group(0))
        nord = next((n for n in etichette() if f"riga {r - 1}, casella {c}," in n), "")
        attiva(contiene=f"riga {r}, casella {c},")
        voci = etichette()
        if PANNELLO["apri"] in voci:
            # La battaglia in sospeso si apre dal pannello del gruppo che vi è coinvolto: l'informazione
            # di stato la dichiara, ma il servizio VoiceOver delle prove tronca le pronunce a 64 caratteri.
            attiva(etichetta=PANNELLO["apri"], tipo="pulsante", ascolto=4)
            battaglia()
            return "battaglia"
        if armato(s) and nord and "tuo " not in nord and "tua " not in nord \
                and PANNELLO["marcia"] in voci and ordinati % 2 == 0:
            attiva(etichetta=PANNELLO["marcia"], tipo="pulsante")
            esito = sentito(attiva(contiene=f"riga {r - 1}, casella {c},", ascolto=2.5))
            if "marcia verso" not in esito:
                diario("osservazione_tester", testo="marcia non confermata", sentito=esito)
        elif PANNELLO["esplora"] in voci:
            esito = sentito(attiva(etichetta=PANNELLO["esplora"], tipo="pulsante"))
        elif PANNELLO["presidio"] in voci:
            esito = sentito(attiva(etichetta=PANNELLO["presidio"], tipo="pulsante"))
        elif PANNELLO["sosta"] in voci:
            esito = sentito(attiva(etichetta=PANNELLO["sosta"], tipo="pulsante"))
        else:
            esito = sentito(attiva(etichetta=PANNELLO["chiudi"], tipo="pulsante"))
        ordinati += 1
        if "comincia il giorno" in esito:
            break  # l'ultimo ordine ha chiuso la giornata
    return f"ordinati {ordinati}"


def main():
    if len(sys.argv) > 4 and sys.argv[4] == "riprendi":
        attiva(etichetta="Riprendi la campagna in corso", tipo="pulsante", ascolto=4)
    else:
        attiva(etichetta=f"Nuova campagna, mappa {FORMATO}", tipo="pulsante", ascolto=4)
    diario("inizio", formato=FORMATO, pronunce=cmd({"azione": "giro", "ascolto": 0.5}).get("pronunce"))
    for g in range(1, GIORNATE + 1):
        esito = giornata(g)
        diario("fine_giornata", numero=g, esito=esito)
        nomi = etichette()
        miei_armati = [n for n in nomi if re.search(r"riga \d+, casella \d+", n) and armato(n)]
        if not miei_armati:
            diario("conclusione", motivo="nessun gruppo armato del giocatore sulla mappa", giornata=g)
            break
    diario("fine", stato=tocco_magico())
    print(f"diario: {DIARIO}")


if __name__ == "__main__":
    main()
