#!/usr/bin/env python3
"""Cancello sulla corrispondenza fra il registro delle build e App Store Connect.

Perché esiste. La catena fra il progetto e i server di Apple è l'unica che nessun
controllo interno poteva verificare, e il 2026-08-05 se ne è avuta la prova: la
build 13 esisteva sui server e nessun documento del progetto la registrava. Non
era un errore di misura: era un caricamento che nessuno aveva scritto.

Che cosa fa. Legge i numeri di build da `build-caricate.md`, legge quelli presenti
su App Store Connect per interfaccia di programmazione, e RIFIUTA se i due insiemi
non coincidono — in entrambi i versi, perché una riga di registro senza build sui
server è un errore quanto una build senza riga.

Dove gira. Soltanto al caricamento, perché chiede le credenziali di App Store
Connect, che non esistono nell'integrazione continua né devono esistervi
(memoria-infrastruttura). Non è quindi un cancello a ogni modifica: è il cancello
del momento in cui la divergenza conta.

Uso:
    python3 scripts/controlla-build.py             # verifica
    python3 scripts/controlla-build.py --appendi N # registra la build N appena caricata
"""
import datetime
import json
import pathlib
import re
import subprocess
import sys

RADICE = pathlib.Path(__file__).resolve().parent.parent
REGISTRO = RADICE / "build-caricate.md"
APP = "6797306323"


def rifiuta(messaggio):
    print(f"RIFIUTATO: {messaggio}")
    sys.exit(1)


def registrate():
    if not REGISTRO.exists():
        rifiuta(f"manca {REGISTRO.name}: senza registro non esiste modo di accorgersi "
                "di un caricamento che nessuno ha scritto.")
    numeri = set()
    for riga in REGISTRO.read_text(encoding="utf-8").splitlines():
        trovato = re.match(r"^\|\s*(\d+)\s*\|", riga)
        if trovato:
            numeri.add(int(trovato.group(1)))
    if not numeri:
        rifiuta(f"{REGISTRO.name} non contiene alcuna riga di build: il registro è vuoto "
                "e il controllo sarebbe vacuo.")
    return numeri


def suiServer():
    esito = subprocess.run(
        ["python3", str(RADICE / "scripts" / "asc_api.py"), "GET",
         f"/v1/builds?filter[app]={APP}&limit=200"],
        capture_output=True, text=True)
    if esito.returncode != 0:
        rifiuta("App Store Connect non risponde, quindi la corrispondenza non è "
                f"verificabile:\n{esito.stderr[-1500:]}")
    try:
        dati = json.loads(esito.stdout)["data"]
    except Exception:
        rifiuta(f"risposta di App Store Connect illeggibile: {esito.stdout[:400]}")
    return {int(b["attributes"]["version"]): b["attributes"]["uploadedDate"] for b in dati}


def verifica():
    nostre = registrate()
    loro = suiServer()
    soloSuiServer = sorted(set(loro) - nostre)
    soloNelRegistro = sorted(nostre - set(loro))
    if soloSuiServer:
        dettaglio = ", ".join(f"{n} (caricata {loro[n]})" for n in soloSuiServer)
        rifiuta(f"su App Store Connect esistono build che {REGISTRO.name} non registra: "
                f"{dettaglio}.\nÈ accaduto una volta con la build 13, e nessuno se ne era "
                "accorto per due sessioni. Aggiungere la riga e accertare da dove viene.")
    if soloNelRegistro:
        rifiuta(f"{REGISTRO.name} registra build che su App Store Connect non esistono: "
                f"{soloNelRegistro}. O la riga è sbagliata, o la build è stata rimossa.")
    print(f"registro e App Store Connect concordano: {len(nostre)} build, "
          f"la più alta è la {max(nostre)}")


def appendi(numero):
    loro = suiServer()
    if numero not in loro:
        rifiuta(f"la build {numero} non risulta su App Store Connect: non la registro.")
    quando = datetime.datetime.fromisoformat(loro[numero]).astimezone(
        datetime.timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
    versione = re.search(r'MARKETING_VERSION:\s*"([^"]+)"',
                         (RADICE / "Applicazione" / "project.yml").read_text(encoding="utf-8"))
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"],
                            cwd=RADICE, capture_output=True, text=True).stdout.strip()
    riga = (f"| {numero} | {quando} | {versione.group(1) if versione else '?'} | "
            f"`{commit}` | scritta dallo script al caricamento |\n")
    testo = REGISTRO.read_text(encoding="utf-8")
    if re.search(rf"^\|\s*{numero}\s*\|", testo, re.MULTILINE):
        print(f"la build {numero} è già registrata: nulla da fare")
        return
    # Si appende in coda all'ultima riga di tabella, che è dove la tabella finisce.
    righe = testo.splitlines(keepends=True)
    ultima = max(i for i, r in enumerate(righe) if re.match(r"^\|\s*\d+\s*\|", r))
    righe.insert(ultima + 1, riga)
    REGISTRO.write_text("".join(righe), encoding="utf-8")
    print(f"build {numero} registrata in {REGISTRO.name}")


def main():
    if "--appendi" in sys.argv:
        appendi(int(sys.argv[sys.argv.index("--appendi") + 1]))
        return 0
    verifica()
    return 0


if __name__ == "__main__":
    sys.exit(main())
