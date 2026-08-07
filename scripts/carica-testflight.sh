#!/bin/zsh
# Caricamento su TestFlight con un solo comando, senza intervento manuale.
# Procedimento completo in memoria-infrastruttura.md. Nessun segreto in questo file:
# le credenziali vengono dal file locale di configurazione fuori dal versionamento.
set -euo pipefail

RADICE="$(cd "$(dirname "$0")/.." && pwd)"

# ============================================================================
# CONTROLLO PREVENTIVO DEL VERSIONAMENTO — PRIMA DI QUALUNQUE ALTRA OPERAZIONE.
# Una build non si carica se il suo codice non è già sul server remoto: la
# build distribuita deve sempre essere risalibile al codice che l'ha prodotta,
# e il remoto è l'unica copia che sopravvive al guasto della macchina locale
# (incarico 12, forma-dei-resoconti.md «Il versionamento: si spinge sempre»).
# Rende il rifiuto un fatto e non una prescrizione. È puramente locale: non
# chiede credenziali, e nessuna variabile d'ambiente lo salta.
# ============================================================================
echo "== Controllo preventivo: il ramo principale è spinto sul remoto =="
git -C "$RADICE" fetch origin --quiet || echo "  avviso: fetch del remoto fallito; confronto con l'ultimo stato noto"
NONSPINTI=$(git -C "$RADICE" rev-list --count origin/principale..HEAD 2>/dev/null || echo 999)
if [ "$NONSPINTI" != "0" ]; then
  echo "RIFIUTATO: $NONSPINTI commit locali non sono su origin/principale."
  echo "  La build sarebbe prodotta da codice non spinto. Esegui 'git push origin principale' prima di caricare."
  exit 1
fi
echo "  principale locale e origin/principale coincidono: si procede"

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

echo "== Numero di build: massimo su tutto l'account più uno =="
ULTIMO=$(eval $ASC GET "'/v1/builds?filter[app]=$APP_ID&limit=200'" \
  | python3 -c "import json,sys; d=json.load(sys.stdin)['data']; print(max((int(b['attributes']['version']) for b in d), default=0))")
NUOVO=$((ULTIMO + 1))
echo "massimo: $ULTIMO -> nuovo: $NUOVO"

# ============================================================================
# CONTROLLO PREVENTIVO DEI DOCUMENTI CONSEGNATI A CHI USA IL GIOCO.
# Un solo comando per tutti: `scripts/controlla-note.py` porta la tabella di
# quale documento è protetto da quali controlli. Prima erano due protezioni
# diverse in due posti diversi — la nota per i tester controllata solo nella
# LUNGHEZZA dentro questo script, la nota per il titolare controllata a fondo
# altrove — e la differenza non era visibile da nessuna parte: la nota per i
# tester è partita con la build 14 descrivendo la build precedente.
# ============================================================================
echo "== Controllo preventivo: i documenti consegnati =="
python3 "$RADICE/scripts/controlla-note.py"

# ============================================================================
# CONTROLLO PREVENTIVO DELLA CORRISPONDENZA CON APP STORE CONNECT.
# È l'unica catena del progetto che nessun controllo interno può verificare, e il
# 2026-08-05 se ne è avuta la prova: la build 13 esisteva sui server e nessun
# documento la registrava. Qui si rifiuta se il registro e i server divergono, in
# entrambi i versi; la riga della build nuova la scrive lo script alla fine, così
# che il passo umano — quello che è mancato — non esista più.
# ============================================================================
echo "== Controllo preventivo: registro delle build e App Store Connect =="
python3 "$RADICE/scripts/controlla-build.py"

# ============================================================================
# CONTROLLO PREVENTIVO DELLA CORSA SEPARATA DELLE SESSIONI COMPLETE.
# Le 144 sessioni di campagna per l'interfaccia sono state spostate fuori dal
# collaudo di ogni caricamento (RDA-83, S11); qui restano le 24 del sottoinsieme.
# Perché lo spostamento non sia una perdita di protezione, il caricamento esige
# che la corsa separata (scripts/esegui-sessioni-complete.sh) abbia lasciato un
# esito FRESCO: presente, di successo, e non più vecchio dell'ultimo commit che ha
# toccato il codice. È il controllo di freschezza delle note applicato a un
# artefatto diverso, e rifiuterebbe un esito vero ma vecchio.
# ============================================================================
echo "== Controllo preventivo: freschezza della corsa separata delle sessioni complete =="
python3 "$RADICE/scripts/controlla-sessioni.py"

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

echo "== Registrazione della build nel registro =="
python3 "$RADICE/scripts/controlla-build.py" --appendi "$NUOVO"

echo "== Fatto: build $NUOVO caricata =="
