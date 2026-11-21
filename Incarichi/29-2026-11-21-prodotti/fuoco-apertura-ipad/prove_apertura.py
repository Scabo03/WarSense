#!/usr/bin/env python3
"""Prove ripetute dell'apertura della battaglia col pilota (incarico 29, osservazione 3).

Uso: prove_apertura.py <cartella del pilota> <prove> [schema]
schema: lista separata da virgole fra «nuovo», «riprendi», «nuovo_senza_riavvio».
Per ogni prova: (eventualmente) chiude e riapre l'app, attiva il comando e ascolta 8 s; scrive una
riga JSON con ciò che VoiceOver ha detto, nell'ordine, e dove è rimasto.
"""
import json
import pathlib
import sys
import time

CARTELLA = pathlib.Path(sys.argv[1])
PROVE = int(sys.argv[2])
SCHEMA = (sys.argv[3] if len(sys.argv) > 3 else "nuovo,riprendi").split(",")


def esiti():
    f = CARTELLA / "esiti.jsonl"
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
        for e in esiti():
            if e.get("n") == n:
                return e
        time.sleep(0.25)
    return {"n": n, "errore": "nessun esito"}


uscita = CARTELLA / "prove-apertura.jsonl"
for i in range(PROVE):
    tipo = SCHEMA[i % len(SCHEMA)]
    if tipo != "nuovo_senza_riavvio":
        cmd({"azione": "termina", "ascolto": 0.5})
        modo = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--modo=")), None)
        avvio = {"azione": "avvia", "ascolto": 2}
        if modo:
            avvio["argomenti"] = ["-diagnosiModo", modo]
        cmd(avvio)
        if "--senza-pausa" not in sys.argv:
            cmd({"azione": "attendi", "secondi": 1.5, "ascolto": 0.5})
    etichetta = "Riprendi lo scontro in corso" if tipo == "riprendi" else "Nuovo scontro di prova"
    t0 = time.time()
    e = cmd({"azione": "attiva", "etichetta": etichetta, "tipo": "pulsante", "ascolto": 8})
    riga = {"prova": i + 1, "tipo": tipo, "modo": next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--modo=")), "attuale"), "t_mac": round(t0, 3), "fuoco_prima": e.get("fuoco"),
            "ascoltate": e.get("ascoltate"), "dopo": e.get("dopo"), "errore": e.get("errore")}
    with uscita.open("a", encoding="utf-8") as f:
        f.write(json.dumps(riga, ensure_ascii=False) + "\n")
    print(json.dumps(riga, ensure_ascii=False))
    if tipo == "nuovo_senza_riavvio":
        # Torna all'avvio senza riavviare: non c'è un'uscita dalla battaglia, quindi si riavvia comunque.
        cmd({"azione": "termina", "ascolto": 0.5})
        cmd({"azione": "avvia", "ascolto": 2})
