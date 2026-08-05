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

# ============================================================================
# CONTROLLO PREVENTIVO DELLE VERSIONI — PRIMA DI QUALUNQUE ALTRA OPERAZIONE.
# La versione di marketing SALE SOLTANTO: TestFlight propone ai dispositivi
# l'ultima build della versione più alta, quindi caricare una versione
# all'indietro rende invisibili tutte le build successive (è già accaduto:
# treno 1.0 accidentale sopra 0.2.0, build 3 e 4 mai proposte come
# aggiornamento). Questo controllo NON è aggirabile: nessuna opzione,
# nessuna variabile d'ambiente lo salta.
# ============================================================================
echo "== Controllo preventivo: la versione non torna mai indietro =="
VERSIONE=$(grep -E '^\s*MARKETING_VERSION:' "$RADICE/Applicazione/project.yml" \
  | sed -E 's/.*"([^"]+)".*/\1/')
eval $ASC GET "'/v1/preReleaseVersions?filter[app]=$APP_ID&limit=200'" \
  | python3 -c "
import json, sys

def segmenti(v):
    return tuple(int(p) for p in v.split('.'))

nuova = '$VERSIONE'
presenti = [i['attributes']['version'] for i in json.load(sys.stdin)['data']]
massima = max(presenti, key=segmenti) if presenti else None
if massima is not None and segmenti(nuova) < segmenti(massima):
    print(f'RIFIUTATO: la versione {nuova} è inferiore alla più alta già su TestFlight ({massima}); TestFlight propone il treno più alto e questa build resterebbe invisibile ai dispositivi.')
    sys.exit(1)
print(f'versione da caricare: {nuova}; più alta già presente: {massima or \"nessuna\"} — si procede')
"

# ============================================================================
# CONTROLLO PREVENTIVO DELLA NOTA PER I TESTER.
# App Store Connect rifiuta whatsNew oltre i 4000 CARATTERI (non byte) con un
# 409, e lo fa DOPO che la build è stata caricata: la build resta buona ma
# arriva ai tester senza nota, e occorre accorgersene e riallegarla a mano.
# È già accaduto due volte (build 7 e build 12) con la regola scritta nella
# memoria di infrastruttura e dimenticata da chi la stava applicando: una
# regola si può dimenticare, un controllo no. Qui si ferma prima di compilare.
# ============================================================================
echo "== Controllo preventivo: la nota per i tester sta nel limite =="
python3 - "$RADICE/note-di-rilascio.txt" <<'PY'
import pathlib, sys
percorso = pathlib.Path(sys.argv[1])
if not percorso.exists():
    print(f"RIFIUTATO: manca {percorso}"); sys.exit(1)
testo = percorso.read_text(encoding="utf-8")
LIMITE = 4000
if len(testo) > LIMITE:
    print(f"RIFIUTATO: la nota per i tester ha {len(testo)} caratteri e il limite di "
          f"App Store Connect è {LIMITE}. Il caricamento andrebbe a buon fine ma la "
          f"nota verrebbe rifiutata dopo, e la build arriverebbe ai tester senza. "
          f"Accorciare di almeno {len(testo) - LIMITE} caratteri e rilanciare.")
    sys.exit(1)
print(f"nota di {len(testo)} caratteri su {LIMITE}: si procede")
PY

echo "== Numero di build: massimo su tutto l'account più uno =="
ULTIMO=$(eval $ASC GET "'/v1/builds?filter[app]=$APP_ID&limit=200'" \
  | python3 -c "import json,sys; d=json.load(sys.stdin)['data']; print(max((int(b['attributes']['version']) for b in d), default=0))")
NUOVO=$((ULTIMO + 1))
echo "massimo: $ULTIMO -> nuovo: $NUOVO"

# ============================================================================
# CONTROLLO PREVENTIVO DELLA NOTA PER IL TITOLARE.
# È il documento su cui il titolare si forma il giudizio sul lavoro, ed era
# l'unico che nessuno rileggeva: due commit su trentanove e quattro affermazioni
# false su quattro alla verifica dell'esame critico. La nota di rilascio, stesso
# destinatario e quattordici commit su trentanove, è coerente per una sola
# ragione — che il caricamento si ferma se manca. Qui la stessa protezione.
# ============================================================================
echo "== Controllo preventivo: la nota per il titolare =="
python3 "$RADICE/scripts/controlla-nota-titolare.py"

echo "== Collaudo COMPLETO prima del caricamento (pacchetto, ospitate, interfaccia) =="
# Un solo elenco di ciò che «tutto» significa, condiviso con l'integrazione
# continua. Si ferma al primo fallimento: `set -e` lo propaga.
"$RADICE/scripts/collaudo-completo.sh"

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
