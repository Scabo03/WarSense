#!/bin/zsh
# Il simulatore RISERVATO a WarSense: stampa l'identificativo (UDID) dell'iPhone o
# dell'iPad dedicato, e lo CREA da sé se manca (incarico 27).
#
# Perché esiste. Fino all'incarico 26 il collaudo e la corsa delle sessioni
# prendevano «il primo iPhone disponibile», che sulla macchina del titolare può
# essere lo stesso che sta usando un altro progetto: due corse sullo stesso
# apparecchio falliscono insieme senza alcun fallimento di asserzione (accertato
# all'incarico 21), e una corsa di WarSense può disturbare il lavoro altrui.
# Gli apparecchi dedicati hanno un nome che dichiara a chi appartengono e stanno
# sul runtime iOS più recente installato; nessun comando qui agisce su
# apparecchi che non siano di WarSense.
#
# Uso:   scripts/simulatore-warsense.sh [iphone|ipad] [n]
#        n (facoltativo, da 2 in su) dà un apparecchio dedicato in più, per le
#        corse in parallelo: «WarSense iPhone Air · 2», e così via.
# Per imporre un apparecchio diverso restano le variabili d'ambiente:
#        WARSENSE_SIMULATORE       (iPhone)
#        WARSENSE_SIMULATORE_IPAD  (iPad)
set -euo pipefail
TIPO="${1:-iphone}"
ISTANZA="${2:-1}"

case "$TIPO" in
  iphone) IMPOSTO="${WARSENSE_SIMULATORE:-}" ;;
  ipad)   IMPOSTO="${WARSENSE_SIMULATORE_IPAD:-}" ;;
  *) echo "RIFIUTATO: tipo di apparecchio sconosciuto «$TIPO» (iphone o ipad)" >&2; exit 2 ;;
esac
if [ -n "$IMPOSTO" ]; then
  echo "simulatore imposto dall'ambiente: $IMPOSTO" >&2
  echo "$IMPOSTO"
  exit 0
fi

ELENCO_SIMULATORI="$(xcrun simctl list --json devices runtimes devicetypes)" \
python3 - "$TIPO" "$ISTANZA" <<'PY'
import json, os, subprocess, sys
tipo, istanza = sys.argv[1], int(sys.argv[2])
modelli = {
    # Il modello di riferimento delle misure geometriche del progetto (incarichi
    # 07-08: «iPhone Air») e l'iPad su cui le stesse misure sono state ripetute.
    "iphone": ("WarSense iPhone Air", ["com.apple.CoreSimulator.SimDeviceType.iPhone-Air"]),
    "ipad": ("WarSense iPad Pro 13", ["com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB",
                                       "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5"]),
}
nome, tipi_ammessi = modelli[tipo]
if istanza > 1:
    nome = "%s · %d" % (nome, istanza)
d = json.loads(os.environ["ELENCO_SIMULATORI"])
def versione(r):
    return tuple(int(p) for p in r["version"].split("."))
disponibili = {t["identifier"] for t in d["devicetypes"]}
tipi = [t for t in tipi_ammessi if t in disponibili]
if not tipi:
    sys.stderr.write("RIFIUTATO: nessuno dei modelli %s esiste in questo Xcode.\n" % tipi_ammessi); sys.exit(1)
# Il runtime più recente che SUPPORTA il modello. Un'immagine può avere, accanto al runtime
# generale, runtime della stessa versione legati a un solo apparecchio (per esempio
# «iOS-27-2-iPhone19-4» sull'immagine xcode-27): a parità di versione si preferisce il generale,
# e un runtime che non supporta il modello si scarta (corse 44823308857 e 44825949262, incarico 27).
def supporta(r):
    elenco = r.get("supportedDeviceTypes")
    return True if elenco is None else any(x.get("identifier") in tipi for x in elenco)
def generale(r):
    import re
    return 1 if re.search(r"SimRuntime\.iOS-[0-9]+-[0-9]+$", r.get("identifier", "")) else 0
runtime = [r for r in d["runtimes"] if r.get("isAvailable") and "SimRuntime.iOS-" in r.get("identifier", "") and supporta(r)]
if not runtime:
    sys.stderr.write("RIFIUTATO: nessun runtime iOS disponibile per %s.\n" % tipi); sys.exit(1)
recente = max(runtime, key=lambda r: (versione(r), generale(r)))
for a in d["devices"].get(recente["identifier"], []):
    if a.get("name") == nome and a.get("isAvailable"):
        sys.stderr.write("simulatore dedicato: %s (%s) %s\n" % (nome, recente["name"], a["udid"]))
        print(a["udid"]); sys.exit(0)
scelto = next(t for t in tipi if any(x.get("identifier") == t for x in recente.get("supportedDeviceTypes", [{"identifier": t}])))
udid = subprocess.run(["xcrun", "simctl", "create", nome, scelto, recente["identifier"]],
                      check=True, capture_output=True, text=True).stdout.strip()
sys.stderr.write("simulatore dedicato CREATO: %s (%s) %s\n" % (nome, recente["name"], udid))
print(udid)
PY
