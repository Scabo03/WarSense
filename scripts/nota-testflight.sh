#!/bin/zsh
# Allega la nota per i tester (note-di-rilascio.txt) alla build indicata.
# La build deve prima risultare elaborata da TestFlight: questo attende fino a
# dieci minuti e poi rinuncia; si può rieseguire in ogni momento.
set -euo pipefail

RADICE="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${WARSENSE_CONFIG:-$HOME/Developer/private_keys/scabo_deploy.env}"
source "$CONFIG"
export APP_STORE_CONNECT_API_KEY_ID APP_STORE_CONNECT_API_KEY_ISSUER_ID APP_STORE_CONNECT_API_KEY_PATH

APP_ID="6797306323"
NUMERO_BUILD="${1:?numero di build richiesto}"
NOTA="$(cat "$RADICE/note-di-rilascio.txt")"

RADICE_SCRIPTS="$RADICE/scripts" python3 - "$APP_ID" "$NUMERO_BUILD" "$NOTA" << 'EOF'
import json, sys, time, os
sys.path.insert(0, os.environ["RADICE_SCRIPTS"])
from asc_api import chiama
app, numero, nota = sys.argv[1], sys.argv[2], sys.argv[3]
build = None
for _ in range(20):  # fino a dieci minuti
    d = chiama("GET", f"/v1/builds?filter[app]={app}&filter[version]={numero}&limit=1")
    if d["data"]:
        build = d["data"][0]
        if build["attributes"]["processingState"] in ("VALID", "PROCESSING"):
            break
    time.sleep(30)
if not build:
    print("build non ancora visibile")
    sys.exit(1)
ident = build["id"]
loc = chiama("GET", f"/v1/builds/{ident}/betaBuildLocalizations")
if loc["data"]:
    chiama("PATCH", f"/v1/betaBuildLocalizations/{loc['data'][0]['id']}",
           {"data": {"type": "betaBuildLocalizations", "id": loc["data"][0]["id"],
                     "attributes": {"whatsNew": nota}}})
else:
    chiama("POST", "/v1/betaBuildLocalizations",
           {"data": {"type": "betaBuildLocalizations",
                     "attributes": {"whatsNew": nota, "locale": "it"},
                     "relationships": {"build": {"data": {"type": "builds", "id": ident}}}}})
print("nota allegata alla build", numero)
EOF
