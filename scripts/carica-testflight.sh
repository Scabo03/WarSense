#!/bin/zsh
# Caricamento su TestFlight con un solo comando, senza intervento manuale.
# Procedimento completo in memoria-infrastruttura.md. Nessun segreto in questo file:
# le credenziali vengono dal file locale di configurazione fuori dal versionamento.
set -euo pipefail

RADICE="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${WARSENSE_CONFIG:-$HOME/Developer/private_keys/scabo_deploy.env}"
source "$CONFIG"
export APP_STORE_CONNECT_API_KEY_ID APP_STORE_CONNECT_API_KEY_ISSUER_ID APP_STORE_CONNECT_API_KEY_PATH
export API_PRIVATE_KEYS_DIR="$(dirname "$APP_STORE_CONNECT_API_KEY_PATH")"

APP_ID="6797306323"   # WarSense su App Store Connect
ASC="python3 $RADICE/scripts/asc_api.py"

echo "== Numero di build: ultimo su TestFlight più uno =="
ULTIMO=$(eval $ASC GET "'/v1/builds?filter[app]=$APP_ID&sort=-uploadedDate&limit=1'" \
  | python3 -c "import json,sys; d=json.load(sys.stdin)['data']; print(d[0]['attributes']['version'] if d else 0)")
NUOVO=$((ULTIMO + 1))
echo "ultimo: $ULTIMO -> nuovo: $NUOVO"

echo "== Collaudo del pacchetto prima del caricamento =="
(cd "$RADICE/Codice" && swift test 2>&1 | tail -2)

echo "== Generazione del progetto e archivio =="
(cd "$RADICE/Applicazione" && xcodegen generate)
CARTELLA_BUILD="$RADICE/Applicazione/build"
rm -rf "$CARTELLA_BUILD"
xcodebuild -project "$RADICE/Applicazione/WarSense.xcodeproj" -scheme WarSense \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$CARTELLA_BUILD/WarSense.xcarchive" \
  CURRENT_PROJECT_VERSION="$NUOVO" archive -quiet

echo "== Esportazione firmata =="
xcodebuild -exportArchive -archivePath "$CARTELLA_BUILD/WarSense.xcarchive" \
  -exportOptionsPlist "$RADICE/Applicazione/ExportOptions.plist" \
  -exportPath "$CARTELLA_BUILD/esportazione" -quiet

echo "== Caricamento su TestFlight =="
xcrun altool --upload-app -f "$CARTELLA_BUILD/esportazione/WarSense.ipa" -t ios \
  --apiKey "$APP_STORE_CONNECT_API_KEY_ID" --apiIssuer "$APP_STORE_CONNECT_API_KEY_ISSUER_ID"

echo "== Nota di rilascio (attende l'elaborazione della build) =="
"$RADICE/scripts/nota-testflight.sh" "$NUOVO" || \
  echo "Nota non ancora allegata: rieseguire scripts/nota-testflight.sh $NUOVO quando la build risulta elaborata."

echo "== Fatto: build $NUOVO caricata =="
