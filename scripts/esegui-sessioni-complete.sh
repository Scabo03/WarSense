#!/bin/zsh
# La CORSA SEPARATA delle sessioni complete (decisione del titolare 2026-08-06,
# RDA-83, S11).
#
# Perché esiste. Le 144 sessioni di campagna giocate PER L'INTERFACCIA costano
# 1258,6 secondi — venti minuti e cinquanta — cioè tre volte la stima di sette
# minuti su cui la decisione di tenerle nel collaudo di ogni caricamento era stata
# presa. Il titolare, informato del numero vero, le ha spostate qui. Il collaudo di
# ogni caricamento tiene il solo sottoinsieme di 24 sessioni.
#
# Non dipende da ALCUNA credenziale (nessuna chiamata ad App Store Connect): gira in
# integrazione continua o a mano, una volta al giorno. Lascia un esito scritto in
# `esiti-sessioni-complete/esito.json`, con la data, il commit su cui è girata e
# l'esito; il caricamento lo esige fresco (scripts/controlla-sessioni.py).
#
# Le 32 sessioni di BATTAGLIA entrano qui al livello a cui passano — il MOTORE,
# headless — perché per l'interfaccia sarebbero dell'ordine delle dodici ore
# (130 322 comandi a 0,3362 s l'uno, S11): l'interfaccia resta aperta in S11.
#
# Uso: scripts/esegui-sessioni-complete.sh
set -uo pipefail
RADICE="$(cd "$(dirname "$0")/.." && pwd)"
ESITI="$RADICE/esiti-sessioni-complete"
mkdir -p "$ESITI"
ARTEFATTO="$ESITI/esito.json"
COMMIT=$(git -C "$RADICE" rev-parse HEAD)
DATA=$(date -u +%Y-%m-%dT%H:%M:%SZ)

scrivi_esito() {  # $1 = esito ; $2 = dettaglio
  cat > "$ARTEFATTO" <<JSON
{
 "data": "$DATA",
 "commit": "$COMMIT",
 "esito": "$1",
 "dettaglio": "$2"
}
JSON
  echo "  esito scritto in ${ARTEFATTO#$RADICE/}: $1"
}

fallito=0

echo "== 1/2 Sessioni complete di CAMPAGNA per l'interfaccia (144) =="
if [ -n "${WARSENSE_SIMULATORE:-}" ]; then
  DEST="id=$WARSENSE_SIMULATORE"
else
  UDID=$(xcrun simctl list devices available --json | python3 -c '
import json, sys
elenco = json.load(sys.stdin)["devices"]; cand = []
for runtime, app in elenco.items():
    if "iOS" not in runtime: continue
    for a in app:
        if a.get("isAvailable") and "iPhone" in a.get("name", ""):
            cand.append((runtime, a["name"], a["udid"]))
if not cand:
    sys.stderr.write("RIFIUTATO: nessun simulatore iPhone disponibile.\n"); sys.exit(1)
cand.sort(); sys.stderr.write(f"simulatore: {cand[-1][1]} ({cand[-1][0]})\n"); print(cand[-1][2])
')
  DEST="id=$UDID"
fi
( cd "$RADICE/Applicazione" && xcodegen generate )
if WARSENSE_SESSIONI_COMPLETE=1 xcodebuild test \
    -project "$RADICE/Applicazione/WarSense.xcodeproj" -scheme WarSense \
    -destination "$DEST" \
    -only-testing:WarSenseTest/SessioniPerInterfacciaTest \
    -derivedDataPath "$RADICE/Applicazione/build/sessioni-complete" -quiet; then
  echo "  campagna per l'interfaccia (144): VERDE"
else
  echo "  campagna per l'interfaccia: ROSSA"; fallito=1
fi

echo "== 2/2 Sessioni complete HEADLESS: campagna e 32 di BATTAGLIA (Motore) =="
# `SessioniCompleteTest` gira il programma di verifica fuori dal fumo (fumo:false):
# 144 sessioni di campagna e 32 di battaglia nel Motore, e pretende zero violazioni
# di passo e di sessione in entrambe (voci violazioni_nelle_sessioni_di_*).
if ( cd "$RADICE/Codice" && swift test --filter SessioniCompleteTest ); then
  echo "  headless (campagna + 32 battaglia): VERDE"
else
  echo "  headless: ROSSO"; fallito=1
fi

if [ "$fallito" -eq 0 ]; then
  scrivi_esito "successo" "144 campagna per interfaccia + headless completo con 32 battaglia al Motore (S11)"
  echo "== Corsa separata: SUCCESSO =="
  exit 0
else
  scrivi_esito "fallimento" "una o piu' parti rosse: vedi l'uscita sopra"
  echo "== Corsa separata: FALLIMENTO =="
  exit 1
fi
