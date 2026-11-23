#!/bin/zsh
# Prepara la prova dal vivo dei salvataggi della build 31 (incarico 31): esporta in una cartella di lavoro
# esclusa da git il codice della build 31 (7ef91fd) e quello sotto prova (il commit dato, predefinito HEAD),
# e ne compila app e pilota. Uso: prepara.sh <udid di un simulatore di WarSense> [commit sotto prova]
set -euo pipefail
RADICE="$(cd "$(dirname "$0")/../../.." && pwd)"
UDID="$1"
SOTTO_PROVA="${2:-HEAD}"
L="$RADICE/Applicazione/build-interattivo/migrazione-31"
rm -rf "$L/build-31" "$L/candidata"
mkdir -p "$L/build-31" "$L/candidata"
git -C "$RADICE" archive 7ef91fd | tar -x -C "$L/build-31"
git -C "$RADICE" archive "$SOTTO_PROVA" | tar -x -C "$L/candidata"
git -C "$RADICE" rev-parse --short "$SOTTO_PROVA" > "$L/candidata/COMMIT"
for copia in build-31 candidata; do
  ( cd "$L/$copia/Applicazione" && xcodegen generate >/dev/null )
  t0=$(date +%s)
  xcodebuild build-for-testing -project "$L/$copia/Applicazione/WarSense.xcodeproj" -scheme WarSenseEsplorazione \
    -destination "id=$UDID" -derivedDataPath "$L/$copia/derivati" -quiet
  echo "compilata $copia in $(( $(date +%s) - t0 )) s"
done
