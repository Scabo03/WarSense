#!/usr/bin/env python3
"""Il lato Mac del pilota della sessione da tester (incarico 28, seconda parte).

Il pilota (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`) gira sul simulatore e legge
i comandi da `<cartella>/comandi.jsonl`; questo script ne aggiunge uno, attende il suo esito in
`<cartella>/esiti.jsonl` e lo stampa in forma breve. Un comando è un oggetto JSON con «azione» e i
suoi parametri, per esempio {"azione": "attiva", "etichetta": "Impostazioni", "tipo": "pulsante"}.

Uso:
  python3 scripts/interattivo.py <cartella> '<comando JSON>' [secondi di attesa]
  python3 scripts/interattivo.py <cartella> --pronto [secondi]   attende che il pilota sia acceso
  python3 scripts/interattivo.py <cartella> --appunti <udid>     serve al pilota gli appunti del simulatore

Gli appunti (incarico 31). Il servizio VoiceOver delle prove tronca ogni pronuncia a 64 caratteri. Il
pilota dà a VoiceOver il comando che copia negli appunti l'ultima cosa detta, per intero, e chiede di
leggerli lasciando un file `appunti/richiesta-<k>` nella cartella: questo servitore li legge con
`xcrun simctl pbpaste <udid>`, risponde in `appunti/risposta-<k>.txt` e li svuota, sicché una copia
non riuscita dà una risposta vuota e non quella di prima. Finisce da sé quando il pilota finisce.
"""
import json
import os
import pathlib
import subprocess
import sys
import time


def esiti(cartella):
    f = cartella / "esiti.jsonl"
    if not f.exists():
        return []
    righe = []
    for riga in f.read_text(encoding="utf-8").splitlines():
        try:
            righe.append(json.loads(riga))
        except json.JSONDecodeError:
            pass
    return righe


def breve(e):
    parti = [f"#{e.get('n')} {e.get('azione')}"]
    for k in ("elemento", "errore", "stato_app", "fuoco", "prima"):
        if k in e:
            parti.append(f"{k}: {e[k]}")
    if "pronunce" in e:
        parti.append(f"pronunce ({len(e['pronunce'])}): " + " | ".join(e["pronunce"]))
    if "ascoltate" in e:
        parti.append("ascoltate: " + " | ".join(e["ascoltate"]))
    if "dopo" in e:
        parti.append(f"dopo: {e['dopo']}")
    if "schermata" in e:
        parti.append(f"schermata: {e['schermata']}")
    if "albero" in e:
        parti.append("albero:\n    " + "\n    ".join(e["albero"]))
    parti.append(f"[{e.get('durata_azione_s', '')} s, vo {e.get('vo_acceso')}]")
    return "\n  ".join(parti)


def pilota_finito(cartella):
    """Vero se il pilota ha finito: ha scritto «fine» o «inerzia», oppure il suo processo non c'è più."""
    if any(e.get("azione") in ("fine", "inerzia") for e in esiti(cartella)):
        return True
    f = cartella / "pilota.pid"
    if f.exists():
        try:
            os.kill(int(f.read_text().strip()), 0)
        except (ValueError, ProcessLookupError):
            return True
        except PermissionError:
            pass
    return False


def servi_appunti(cartella, udid):
    """Serve al pilota gli appunti del simulatore, una richiesta alla volta, finché il pilota non finisce."""
    appunti = cartella / "appunti"
    appunti.mkdir(parents=True, exist_ok=True)
    servite, ultimo_controllo = 0, time.time()
    while True:
        richieste = sorted(appunti.glob("richiesta-*"), key=lambda p: int(p.name.split("-")[1]))
        for richiesta in richieste:
            k = richiesta.name.split("-")[1]
            try:
                testo = subprocess.run(["xcrun", "simctl", "pbpaste", udid], capture_output=True, text=True, timeout=10).stdout
                subprocess.run(["xcrun", "simctl", "pbcopy", udid], input="", text=True, timeout=10)
            except subprocess.TimeoutExpired:
                testo = ""
            provvisorio = appunti / f".risposta-{k}"
            provvisorio.write_text(testo, encoding="utf-8")
            provvisorio.rename(appunti / f"risposta-{k}.txt")
            richiesta.unlink(missing_ok=True)
            servite += 1
        if time.time() - ultimo_controllo > 4:
            ultimo_controllo = time.time()
            if pilota_finito(cartella):
                break
        time.sleep(0.03)
    print(f"appunti: {servite} richieste servite")
    return 0


def main():
    cartella = pathlib.Path(sys.argv[1])
    cartella.mkdir(parents=True, exist_ok=True)
    if sys.argv[2] == "--appunti":
        return servi_appunti(cartella, sys.argv[3])
    if sys.argv[2] == "--pronto":
        limite = time.time() + float(sys.argv[3] if len(sys.argv) > 3 else 300)
        while time.time() < limite:
            if any(e.get("azione") == "pronto" for e in esiti(cartella)):
                print("pilota pronto")
                return 0
            time.sleep(1)
        print("pilota NON pronto")
        return 1
    comando = json.loads(sys.argv[2])
    attesa = float(sys.argv[3] if len(sys.argv) > 3 else 120)
    file_comandi = cartella / "comandi.jsonl"
    gia = file_comandi.read_text(encoding="utf-8").splitlines() if file_comandi.exists() else []
    comando["n"] = len(gia) + 1
    with file_comandi.open("a", encoding="utf-8") as f:
        f.write(json.dumps(comando, ensure_ascii=False) + "\n")
    limite = time.time() + attesa
    while time.time() < limite:
        for e in esiti(cartella):
            if e.get("n") == comando["n"]:
                print(breve(e))
                return 0
        time.sleep(0.3)
    print(f"#{comando['n']} {comando.get('azione')}: NESSUN ESITO in {attesa:.0f} s")
    return 1


if __name__ == "__main__":
    sys.exit(main())
