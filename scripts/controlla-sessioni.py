#!/usr/bin/env python3
"""Cancello sulla freschezza dell'esito della corsa separata delle sessioni complete.

Perché esiste. Le 144 sessioni di campagna giocate per l'interfaccia costano venti
minuti e cinquanta secondi e sono state spostate fuori dal collaudo di ogni
caricamento (decisione del titolare 2026-08-06, RDA-83, S11). Perché lo spostamento
non sia una perdita di protezione, la corsa separata
(`scripts/esegui-sessioni-complete.sh`) lascia un esito scritto, e questo cancello
RIFIUTA il caricamento se quell'esito:
  - manca (la corsa non è mai stata eseguita, o l'esito è stato rimosso);
  - dichiara un fallimento;
  - è più vecchio dell'ultimo commit che ha toccato il codice.

È il controllo di freschezza delle note (`controlla-note.py`, RDA-80/81) applicato a
un artefatto diverso, e la domanda che deve superare è la stessa: rifiuterebbe un
esito VERO ma VECCHIO. Sì — un esito girato su un commit che il codice ha poi
superato è respinto, perché non dice nulla sul codice che si sta per caricare. È
l'errore già commesso tre volte: un cancello che verifica la forma e non
l'attualità non protegge nulla.

Gira soltanto al caricamento, come gli altri controlli preventivi; non chiede
credenziali. Uso: python3 scripts/controlla-sessioni.py
"""
import json
import pathlib
import subprocess
import sys

RADICE = pathlib.Path(__file__).resolve().parent.parent
ARTEFATTO = RADICE / "esiti-sessioni-complete" / "esito.json"
SORGENTI = [RADICE / "Applicazione" / "Sorgenti", RADICE / "Codice" / "Sources"]


def rifiuta(messaggio):
    print(f"RIFIUTATO: {messaggio}")
    sys.exit(1)


def istante_del_commit(sha):
    esito = subprocess.run(["git", "show", "-s", "--format=%ct", sha],
                           cwd=RADICE, capture_output=True, text=True)
    if esito.returncode != 0 or not esito.stdout.strip():
        return None
    return int(esito.stdout.strip())


def ultimo_commit_del_codice():
    esito = subprocess.run(["git", "log", "-1", "--format=%H %ct", "--"] +
                           [str(p) for p in SORGENTI],
                           cwd=RADICE, capture_output=True, text=True)
    uscita = esito.stdout.strip()
    if not uscita:
        return None, 0
    sha, quando = uscita.split()
    return sha, int(quando)


def main():
    if not ARTEFATTO.exists():
        rifiuta(f"manca {ARTEFATTO.relative_to(RADICE)}: la corsa separata delle sessioni "
                "complete non è mai stata eseguita su questa copia, o il suo esito è stato "
                "rimosso. Eseguire scripts/esegui-sessioni-complete.sh prima di caricare.")
    try:
        esito = json.loads(ARTEFATTO.read_text(encoding="utf-8"))
    except Exception:
        rifiuta(f"{ARTEFATTO.name} non è JSON leggibile: l'esito è illeggibile.")
    if esito.get("esito") != "successo":
        rifiuta(f"l'ultima corsa separata dichiara «{esito.get('esito')}»: "
                f"{esito.get('dettaglio', '')}. Non si carica su una corsa fallita.")
    commit = esito.get("commit")
    quando_esito = istante_del_commit(commit) if commit else None
    if quando_esito is None:
        rifiuta(f"l'esito cita il commit «{commit}», che non è nella cronologia: "
                "l'esito non è collocabile nel tempo del codice, e non prova nulla sul "
                "codice che si sta per caricare.")
    sha_codice, quando_codice = ultimo_commit_del_codice()
    if quando_codice > quando_esito:
        rifiuta("l'esito della corsa separata è più vecchio dell'ultimo commit che ha "
                f"toccato il codice.\n  esito girato su: {commit[:7]}\n"
                f"  codice a:        {sha_codice[:7]}\n"
                "Rieseguire scripts/esegui-sessioni-complete.sh sul codice attuale. È lo "
                "stesso controllo di freschezza delle note, applicato alle sessioni complete: "
                "un esito vero ma vecchio non protegge nulla.")
    print(f"corsa separata delle sessioni complete: esito «successo», girata su "
          f"{commit[:7]}, codice a {sha_codice[:7]} (data {esito.get('data')})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
