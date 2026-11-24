#!/usr/bin/env python3
"""Ogni prova aggiunta o rinominata sul ramo dell'incarico 32 si è vista fallire? Per ogni funzione di prova che il diff
aggiunge, cerca nelle uscite di questa cartella una riga in cui QUELLA prova è fallita: una prova che vi compare come
passata non conta.

Uso: controlla.py [commit di partenza, 06dee59 se non si dice] [commit d'arrivo, HEAD]
"""
import pathlib
import re
import subprocess
import sys

QUI = pathlib.Path(__file__).resolve().parent
RADICE = QUI.parents[2]
DA, A = (sys.argv + ["06dee59", "HEAD"])[1:3] if len(sys.argv) > 2 else (sys.argv[1] if len(sys.argv) > 1 else "06dee59", "HEAD")
diff = subprocess.run(["git", "diff", DA, A, "--", "Codice/Tests", "Applicazione/ProveOspitate", "Applicazione/ProveInterfaccia"],
                      cwd=RADICE, capture_output=True, text=True, check=True).stdout
nomi = sorted(set(re.findall(r"^\+[ \t]*func (test\w+)", diff, re.M)))
uscite = "\n".join(p.read_text(encoding="utf-8", errors="replace") for p in sorted(QUI.glob("*.txt")))
# un fallimento si legge in due forme: la riga dell'esito, o la riga dell'asserzione che è fallita
mancano = [n for n in nomi if not re.search(re.escape(n) + r"\](' failed|\s*:)", uscite)]
print("prove aggiunte o rinominate: %d; viste fallire: %d" % (len(nomi), len(nomi) - len(mancano)))
for n in mancano:
    print("NON VISTA FALLIRE:", n)
