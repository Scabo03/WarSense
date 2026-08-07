#!/bin/zsh
# L'INTERO collaudo del progetto, in un solo comando e in un solo posto.
#
# Perché esiste. Fino al 2026-08-05 il collaudo era eseguito da due luoghi
# (`.github/workflows/collaudo.yml` e `scripts/carica-testflight.sh`) e in
# entrambi si fermava a `swift test`, cioè alle prove del pacchetto: le prove
# ospitate e quelle d'interfaccia non erano cancello per nulla, né in
# integrazione continua né prima di un caricamento. Sono precisamente le prove
# che vivono al livello in cui i difetti riferiti dal titolare si sono
# manifestati (esame-critico.md §3.4). 05 §14.1 prescrive che TUTTO giri a ogni
# modifica; questo script è la sola sede in cui quel «tutto» è definito, e i due
# chiamanti lo invocano invece di elencare i propri passi.
#
# Si ferma al primo fallimento e restituisce un codice diverso da zero.
# Uso: ./scripts/collaudo-completo.sh
set -euo pipefail

RADICE="$(cd "$(dirname "$0")/.." && pwd)"

echo "== 0/3 Cancello dei simboli d'archetipo (biiezione archetipi <-> simboli, RDA-97) =="
# Rifiuta prima di ogni altra cosa un archetipo senza simbolo o un simbolo orfano:
# è più economico del collaudo intero e coglie il disallineamento alla radice.
"$RADICE/scripts/verifica-simboli.sh"

echo "== 1/3 Collaudo del pacchetto (Motore, Dati, Sessione, Segnali, Verifica, Confini) =="
# Nessuna pipe: con `set -o pipefail` il fallimento si propaga comunque, ma senza
# pipe l'uscita del collaudo arriva intera a chi legge.
( cd "$RADICE/Codice" && swift test )

echo "== 2/3 Generazione del progetto applicativo dalla sua sorgente di verità =="
# `project.yml` è la sorgente di verità (memoria-infrastruttura, «Progetto
# applicativo»): il collaudo gira su ciò che quel file descrive, non su un
# `.xcodeproj` eventualmente andato alla deriva.
( cd "$RADICE/Applicazione" && xcodegen generate )

echo "== 3/3 Prove ospitate e d'interfaccia sul simulatore =="
# Il simulatore non si sceglie per nome, che varia fra le macchine e fra le
# versioni di Xcode: si prende il primo iPhone disponibile. `WARSENSE_SIMULATORE`
# permette di imporne uno.
if [ -n "${WARSENSE_SIMULATORE:-}" ]; then
  DESTINAZIONE="id=$WARSENSE_SIMULATORE"
else
  UDID=$(xcrun simctl list devices available --json | python3 -c '
import json, sys
elenco = json.load(sys.stdin)["devices"]
candidati = []
for runtime, apparecchi in elenco.items():
    if "iOS" not in runtime:
        continue
    for a in apparecchi:
        if a.get("isAvailable") and "iPhone" in a.get("name", ""):
            candidati.append((runtime, a["name"], a["udid"]))
if not candidati:
    sys.stderr.write("RIFIUTATO: nessun simulatore iPhone disponibile.\n")
    sys.exit(1)
candidati.sort()
sys.stderr.write(f"simulatore scelto: {candidati[-1][1]} ({candidati[-1][0]})\n")
print(candidati[-1][2])
')
  DESTINAZIONE="id=$UDID"
fi

# Il fascio di risultati serve al conteggio delle prove dall'ESECUTORE (sessione
# 06): i numeri riportati nei resoconti venivano da uno scanner Python, perché
# `-quiet` sopprime le righe per bersaglio. Il fascio conserva il conteggio vero,
# che `scripts/conta-prove.sh` legge con xcresulttool.
RISULTATI="${WARSENSE_RISULTATI:-$RADICE/Applicazione/build/collaudo-risultati.xcresult}"
rm -rf "$RISULTATI"
# Le 144 sessioni complete per l'interfaccia (test_00_3_9) sono ESCLUSE: costano
# venti minuti e cinquanta e girano nella sola corsa separata (RDA-83, S11). Resta
# test_00_3_1, il sottoinsieme di 24. L'esclusione è per NOME e non per variabile
# d'ambiente, perché xcodebuild non propaga l'ambiente della shell al simulatore.
xcodebuild test \
  -project "$RADICE/Applicazione/WarSense.xcodeproj" \
  -scheme WarSense \
  -destination "$DESTINAZIONE" \
  -derivedDataPath "${WARSENSE_DERIVATI:-$RADICE/Applicazione/build/collaudo}" \
  -resultBundlePath "$RISULTATI" \
  -skip-testing:WarSenseTest/SessioniPerInterfacciaTest/test_00_3_9_ogni_configurazione_completa_giocata_al_dito \
  -quiet

echo "== Conteggio delle prove ospitate e d'interfaccia, dall'esecutore =="
# Non si sopprime più il conteggio: viene dal fascio di risultati dell'esecutore,
# non da uno scanner. Non fatale: un conteggio non estratto non ferma il collaudo.
"$RADICE/scripts/conta-prove.sh" "$RISULTATI" || echo "  (conteggio non estratto)"

echo "== Collaudo completo: tutto verde =="
