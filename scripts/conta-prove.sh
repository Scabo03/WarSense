#!/bin/zsh
# Conteggio delle prove ospitate e d'interfaccia DALL'ESECUTORE (sessione 06).
#
# Perché esiste. I conteggi delle prove ospitate e d'interfaccia riportati nei
# resoconti venivano da uno scanner Python, non da chi le esegue: il collaudo
# girava con `-quiet`, che sopprime le righe per bersaglio, e il numero si
# ricostruiva a parte. Il conteggio del pacchetto viene già dall'esecutore
# (`swift test` stampa «Executed N tests»); questi due no. Qui il numero viene dal
# FASCIO DI RISULTATI che l'esecutore scrive (xcresulttool), non da uno scanner.
#
# Non risolve il PRIMO problema del conteggio (una sonda priva di asserzioni
# committata fra le prove): quello resta aperto, perché nessun controllo distingue
# una sonda da una prova che asserisce in un'ausiliaria senza rifiutare prove
# legittime (vedi resoconto 06 e 04 §3).
#
# Uso: scripts/conta-prove.sh <percorso .xcresult>
set -euo pipefail
RISULTATI="${1:?percorso del fascio .xcresult richiesto}"

xcrun xcresulttool get test-results summary --path "$RISULTATI" 2>/dev/null | python3 -c '
import json, sys
d = json.load(sys.stdin)
tot = d.get("totalTestCount"); pas = d.get("passedTests"); fal = d.get("failedTests")
sal = d.get("skippedTests"); esito = d.get("result")
print(f"  esecutore (xcresulttool summary): {tot} prove eseguite fra ospitate e "
      f"interfaccia — {pas} passate, {fal} fallite, {sal} saltate; esito {esito}")
'

# Ripartizione per bersaglio, best-effort dalle foglie dell'albero dei test.
xcrun xcresulttool get test-results tests --path "$RISULTATI" 2>/dev/null | python3 -c '
import json, sys
from collections import Counter
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
conteggio = Counter()
def foglie(nodo, bersaglio):
    tipo = nodo.get("nodeType")
    nome = nodo.get("name", "")
    if tipo in ("Unit test bundle", "UI test bundle", "Test Bundle", "Test Target"):
        bersaglio = nome
    figli = nodo.get("children", [])
    if tipo == "Test Case" or (not figli and tipo not in (None,) and "()" in nome or nome.startswith("test")):
        conteggio[bersaglio] += 1
        return
    for f in figli:
        foglie(f, bersaglio)
for radice in d.get("testNodes", []):
    foglie(radice, "?")
if conteggio:
    for bersaglio, n in sorted(conteggio.items()):
        print(f"    per bersaglio: {bersaglio} = {n}")
' 2>/dev/null || true
