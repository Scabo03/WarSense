#!/bin/zsh
# L'esplorazione completa dell'interfaccia con VoiceOver (incarico 27, quarta parte).
#
# NON fa parte del collaudo di ogni caricamento: esegue lo schema WarSenseEsplorazione, che lo
# schema WarSense del collaudo non contiene. Rieseguibile: compila una volta, poi gira le
# configurazioni richieste su simulatori RISERVATI a WarSense (scripts/simulatore-warsense.sh),
# più d'uno in parallelo, e raccoglie i prodotti in testo e in PNG.
#
# Uso: scripts/esplora-interfaccia.sh [cartella dei prodotti]
#   ESPLORA_CONFIGURAZIONI  elenco di «apparecchio:orientamento:testo[:ampiezza]», per esempio
#                           "iphone:verticale:predefinito:completa ipad:orizzontale:grande:ridotta"
#                           ampiezza «completa» (predefinita): tutti i percorsi, campagna sui tre
#                           formati; «ridotta»: avvio, impostazioni, apprendimento, battaglia e
#                           campagna sulla mappa piccola; «formati»: campagna sulle mappe media e
#                           grande (predefinito: le otto combinazioni complete)
#   ESPLORA_PROVE           elenco di -only-testing (predefinito: tutta la classe)
#   ESPLORA_PARALLELI       quante corse insieme (predefinito 4)
set -uo pipefail
RADICE="$(cd "$(dirname "$0")/.." && pwd)"
PRODOTTI="${1:-$RADICE/Incarichi/27-2026-11-20-prodotti/esplorazione}"
LAVORO="$RADICE/Applicazione/build/esplorazione-corse"
DERIVATI="$RADICE/Applicazione/build/esplorazione"
CONFIG="${ESPLORA_CONFIGURAZIONI:-iphone:verticale:predefinito iphone:orizzontale:predefinito iphone:verticale:grande iphone:orizzontale:grande ipad:verticale:predefinito ipad:orizzontale:predefinito ipad:verticale:grande ipad:orizzontale:grande}"
PARALLELI="${ESPLORA_PARALLELI:-4}"
mkdir -p "$PRODOTTI" "$LAVORO"

echo "== Generazione del progetto e compilazione per le prove (una volta) =="
( cd "$RADICE/Applicazione" && xcodegen generate ) || exit 1
UNO=$("$RADICE/scripts/simulatore-warsense.sh" iphone)
xcodebuild build-for-testing -project "$RADICE/Applicazione/WarSense.xcodeproj" -scheme WarSenseEsplorazione \
  -destination "id=$UNO" -derivedDataPath "$DERIVATI" -quiet || exit 1

# Un simulatore dedicato per ogni corsa parallela: iphone 1..n, ipad 1..n.
corsa() {  # $1 apparecchio, $2 orientamento, $3 testo, $4 istanza, $5 ampiezza
  local nome="$1-$2-$3"
  local udid=$("$RADICE/scripts/simulatore-warsense.sh" "$1" "$4")
  # Ogni corsa parte da un'installazione nuova: nessuna partita salvata da corse precedenti.
  xcrun simctl boot "$udid" >/dev/null 2>&1; xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1
  xcrun simctl uninstall "$udid" com.scabo.warsense >/dev/null 2>&1
  local classe="WarSenseEsplorazione/EsplorazioneInterfacciaTest"
  local prove="${ESPLORA_PROVE:--only-testing:$classe}"
  if [ "${5:-completa}" = "ridotta" ] && [ -z "${ESPLORA_PROVE:-}" ]; then
    prove="-only-testing:$classe/test_1_avvio_impostazioni_apprendimento -only-testing:$classe/test_2_battaglia_nuova_ripresa_e_resoconto -only-testing:$classe/test_3_campagna_mappa_piccola"
  elif [ "${5:-completa}" = "formati" ] && [ -z "${ESPLORA_PROVE:-}" ]; then
    prove="-only-testing:$classe/test_4_campagna_mappa_media -only-testing:$classe/test_5_campagna_mappa_grande"
  fi
  [ "${5:-completa}" != "completa" ] && nome="$nome-${5}"
  local risultati="$LAVORO/$nome.xcresult"
  rm -rf "$risultati"
  local t0=$(date +%s)
  TEST_RUNNER_ESPLORA_ORIENTAMENTO="$2" TEST_RUNNER_ESPLORA_TESTO="$3" \
  xcodebuild test-without-building -project "$RADICE/Applicazione/WarSense.xcodeproj" -scheme WarSenseEsplorazione \
    -destination "id=$udid" -derivedDataPath "$DERIVATI" -resultBundlePath "$risultati" \
    ${=prove} > "$LAVORO/$nome.log" 2>&1
  local uscita=$?
  echo "$nome ampiezza=${5:-completa} uscita=$uscita durata=$(( $(date +%s) - t0 ))s simulatore=$udid" | tee -a "$LAVORO/tempi.txt"
  grep "^ESPLORA|" "$LAVORO/$nome.log" | sed 's/^ESPLORA|//' > "$PRODOTTI/rilievi-$nome.jsonl"
  mkdir -p "$LAVORO/allegati-$nome"
  xcrun xcresulttool export attachments --path "$risultati" --output-path "$LAVORO/allegati-$nome" >/dev/null 2>&1
}

echo "== Corse: $CONFIG =="
: > "$LAVORO/tempi.txt"
typeset -A istanze
attive=0
for c in ${=CONFIG}; do
  parti=(${(s.:.)c})
  app=$parti[1]
  istanze[$app]=$(( ${istanze[$app]:-0} + 1 ))
  corsa "$app" "$parti[2]" "$parti[3]" "${istanze[$app]}" "${parti[4]:-completa}" &
  attive=$(( attive + 1 ))
  if [ $attive -ge $PARALLELI ]; then wait; attive=0; istanze=(); fi
done
wait
cp "$LAVORO/tempi.txt" "$PRODOTTI/tempi-delle-corse.txt"
echo "== Fatto: rilievi in $PRODOTTI, allegati in $LAVORO/allegati-* =="
