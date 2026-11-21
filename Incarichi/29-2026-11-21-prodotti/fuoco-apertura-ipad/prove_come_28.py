#!/usr/bin/env python3
"""Riproduce la sequenza dell'incarico 28 (esiti-ipad-battaglia-percorsi-sbagliati, passi 1-3 e 7-10):
VoiceOver spento, app chiusa, dati dell'app azzerati (primo avvio), avvio, VoiceOver acceso, attivazione
immediata del comando. Uso: prove_come_28.py <cartella del pilota> <udid> <prove> [modo]
"""
import json
import pathlib
import shutil
import subprocess
import sys
import time

CARTELLA = pathlib.Path(sys.argv[1])
UDID = sys.argv[2]
PROVE = int(sys.argv[3])
MODO = sys.argv[4] if len(sys.argv) > 4 else None


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


contenitore = pathlib.Path(subprocess.check_output(
    ["xcrun", "simctl", "get_app_container", UDID, "com.scabo.warsense", "data"], text=True).strip())
for i in range(PROVE):
    cmd({"azione": "vo_spegni", "ascolto": 0.3})
    cmd({"azione": "termina", "ascolto": 0.3})
    for nome in ("Valori", "Testi", "Partite"):
        shutil.rmtree(contenitore / "Documents" / nome, ignore_errors=True)
    avvio = {"azione": "avvia", "ascolto": 0.3}
    if MODO:
        avvio["argomenti"] = ["-diagnosiModo", MODO]
    cmd(avvio)
    cmd({"azione": "vo_accendi", "ascolto": 0.5})
    e = cmd({"azione": "attiva", "etichetta": "Nuovo scontro di prova", "tipo": "pulsante", "ascolto": 8})
    print(json.dumps({"prova": i + 1, "modo": MODO or "attuale", "fuoco_prima": e.get("fuoco"),
                      "ascoltate": e.get("ascoltate"), "dopo": e.get("dopo")}, ensure_ascii=False), flush=True)
