#!/bin/zsh
# La verifica con VoiceOver della seconda tappa del regno (incarico 31): UN COMANDO PER APPARECCHIO.
#
# Compila l'app e il pilota (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`) da una COPIA
# dell'albero di lavoro, presa nel momento in cui parte, dentro `Applicazione/build/pilota-31/`: il
# progetto Xcode del repo non si rigenera e il collaudo, che lavora in `Applicazione/build/collaudo`,
# non si tocca. Poi accende il simulatore, vi installa l'app da zero, accende il pilota, guida i
# percorsi o il tester, spegne VoiceOver, ferma il pilota, controlla che VoiceOver sia spento e
# spegne il simulatore se l'aveva acceso lui. I prodotti in testo finiscono accanto a questo script.
#
# Uso:
#   corri.sh percorsi <iphone|ipad> [blocchi…]
#       i percorsi a controlli (`percorsi-seconda-tappa.py`) sul SECONDO apparecchio di quel tipo
#       (PILOTA_ISTANZA ne impone un altro, dal secondo in su); prodotti in <tipo>/
#   corri.sh tester <iphone|ipad> <istanza> <nome> <argomenti di scripts/tester.py dopo la cartella…>
#       il tester (`scripts/tester.py`) sull'apparecchio indicato; prodotti in <tipo>/<nome>/
#   corri.sh compila
#       soltanto la copia e la compilazione (le altre due la fanno da sé, una volta per codice)
#   corri.sh pilota <iphone|ipad> <istanza> <nome>     accende il pilota e stampa la sua cartella,
#   corri.sh chiudi <iphone|ipad> <istanza> <nome>     per i passi a mano con scripts/interattivo.py
#
# Convivenza: soltanto i simulatori di WarSense, e MAI il primo iPhone né il primo iPad, che sono
# del collaudo: l'istanza 1 è rifiutata. Nessun comando agisce su tutti i simulatori; si spegne
# soltanto ciò che questo script ha acceso (lo annota in `accesi-da-me.txt`).
set -uo pipefail
QUI="$(cd "$(dirname "$0")" && pwd)"
RADICE="$(cd "$QUI/../../.." && pwd)"
LAVORO="$RADICE/Applicazione/build/pilota-31"
ALBERO="$LAVORO/albero"
DERIVATI="$LAVORO/derivati"
APP="com.scabo.warsense"
# Ciò da cui dipendono l'app e il pilota: se cambia, si ricompila.
SORGENTI=(Applicazione/Sorgenti Applicazione/Risorse Applicazione/Esplorazione Applicazione/project.yml Codice/Sources Codice/Package.swift)

ora() { date +%s }

rifiuta_il_primo() {  # $1 istanza
  if [[ "$1" != <2-> ]]; then
    echo "RIFIUTATO: istanza «$1». Il primo iPhone e il primo iPad di WarSense sono del collaudo: qui si usa dal secondo in su."
    return 1
  fi
}

udid_di() { "$RADICE/scripts/simulatore-warsense.sh" "$1" "$2" 2>/dev/null }

# L'impronta di ciò da cui dipendono app e pilota: il CONTENUTO di quei percorsi (i file tracciati
# con la loro impronta, più ciò che l'albero di lavoro vi cambia), non il commit. Un commit che tocca
# soltanto documenti o prodotti non fa ricompilare, e non sostituisce i prodotti di compilazione sotto
# i piloti che stanno girando.
firma() {
  ( cd "$RADICE" && { git ls-files -s -- $SORGENTI; git status --porcelain -- $SORGENTI; git diff HEAD -- $SORGENTI; } \
      | shasum -a 256 | cut -d' ' -f1 )
}

# La copia dell'albero e la compilazione, una volta per codice. Chi arriva mentre un altro compila
# aspetta, e trova poi la compilazione già fatta.
compila() {
  mkdir -p "$LAVORO"
  local atteso=0
  until mkdir "$LAVORO/.compilazione-in-corso" 2>/dev/null; do
    sleep 2; atteso=$(( atteso + 2 ))
    if [ $atteso -gt 1200 ]; then
      echo "RIFIUTATO: un'altra compilazione tiene $LAVORO/.compilazione-in-corso da più di 1200 s"; return 1
    fi
  done
  local esito=0 nuova="$(firma)"
  if [ -f "$LAVORO/firma.txt" ] && [ "$(cat "$LAVORO/firma.txt")" = "$nuova" ] \
     && ls "$DERIVATI"/Build/Products/*.xctestrun >/dev/null 2>&1; then
    echo "== compilazione già fatta per questo codice: $(head -1 "$LAVORO/compilazione.txt")"
    # Il commit può essere avanzato senza toccare ciò da cui dipendono app e pilota: lo si annota.
    local adesso="$(git -C "$RADICE" rev-parse --short HEAD)"
    if ! grep -q "commit $adesso" "$LAVORO/compilazione.txt"; then
      echo "anche al commit $adesso ($(date '+%Y-%m-%d %H:%M:%S')) ciò da cui dipendono app e pilota ha la stessa impronta: nessuna ricompilazione" >> "$LAVORO/compilazione.txt"
    fi
  else
    echo "== copia dell'albero di lavoro e compilazione (app e pilota) =="
    local t0=$(ora)
    mkdir -p "$ALBERO/Applicazione" "$ALBERO/Codice"
    rsync -a --delete --exclude '.build' "$RADICE/Codice/" "$ALBERO/Codice/" || esito=1
    for d in Sorgenti Risorse Esplorazione ProveInterfaccia ProveOspitate; do
      rsync -a --delete "$RADICE/Applicazione/$d/" "$ALBERO/Applicazione/$d/" || esito=1
    done
    cp "$RADICE/Applicazione/project.yml" "$ALBERO/Applicazione/project.yml" || esito=1
    local commit="$(git -C "$RADICE" rev-parse --short HEAD)" ramo="$(git -C "$RADICE" branch --show-current)"
    local stato="$(git -C "$RADICE" status --short)"
    if [ $esito -eq 0 ]; then ( cd "$ALBERO/Applicazione" && xcodegen generate --quiet ) || esito=1; fi
    if [ $esito -eq 0 ]; then
      xcodebuild build-for-testing -project "$ALBERO/Applicazione/WarSense.xcodeproj" -scheme WarSenseEsplorazione \
        -destination "id=$(udid_di iphone 2)" -derivedDataPath "$DERIVATI" -quiet > "$LAVORO/compilazione.log" 2>&1 || esito=1
    fi
    if [ $esito -eq 0 ]; then
      echo "$nuova" > "$LAVORO/firma.txt"
      {
        echo "commit $commit, ramo $ramo, righe di «git status --short»: $(print -r -- "$stato" | grep -c .), compilato in $(( $(ora) - t0 )) s (date +%s) il $(date '+%Y-%m-%d %H:%M:%S')"
        echo "«git status --short» al momento della copia:"
        print -r -- "$stato"
        echo "impronta di ciò da cui dipendono app e pilota ($SORGENTI): $nuova"
        echo "$(xcodebuild -version | tr '\n' ' ')"
      } > "$LAVORO/compilazione.txt"
      echo "== compilato: $(head -1 "$LAVORO/compilazione.txt")"
    else
      echo "COMPILAZIONE FALLITA: $LAVORO/compilazione.log"; tail -30 "$LAVORO/compilazione.log" 2>/dev/null
    fi
  fi
  rmdir "$LAVORO/.compilazione-in-corso"
  return $esito
}

acceso() { xcrun simctl list devices | grep "$1" | grep -q "(Booted)" }

accendi() {  # $1 udid
  if ! acceso "$1"; then
    xcrun simctl boot "$1" && echo "$1" >> "$LAVORO/accesi-da-me.txt"
  fi
  xcrun simctl bootstatus "$1" -b >/dev/null 2>&1
}

spegni() {  # $1 udid: soltanto se l'ha acceso questo script
  if [ "${PILOTA_TIENI_ACCESO:-0}" = "1" ]; then return 0; fi
  if [ -f "$LAVORO/accesi-da-me.txt" ] && grep -q "$1" "$LAVORO/accesi-da-me.txt"; then
    xcrun simctl shutdown "$1" 2>/dev/null
    grep -v "$1" "$LAVORO/accesi-da-me.txt" > "$LAVORO/accesi-da-me.tmp"; mv "$LAVORO/accesi-da-me.tmp" "$LAVORO/accesi-da-me.txt"
    echo "  simulatore $1 spento"
  else
    echo "  simulatore $1 lasciato com'era: non l'aveva acceso questo script"
  fi
}

# Accende il pilota su un simulatore, con l'app installata da zero (nessun regno di corse precedenti).
pilota_su() {  # $1 udid, $2 cartella
  local udid="$1" cartella="$2"
  mkdir -p "$cartella"
  rm -f "$cartella/comandi.jsonl" "$cartella/esiti.jsonl"; rm -rf "$cartella/pilota.xcresult"
  xcrun simctl uninstall "$udid" "$APP" >/dev/null 2>&1
  xcrun simctl ui "$udid" content_size large >/dev/null 2>&1
  TEST_RUNNER_INTERATTIVO_CARTELLA="$cartella" TEST_RUNNER_INTERATTIVO_INERZIA="${PILOTA_INERZIA:-1800}" \
  nohup xcodebuild test-without-building -project "$ALBERO/Applicazione/WarSense.xcodeproj" -scheme WarSenseEsplorazione \
    -destination "id=$udid" -derivedDataPath "$DERIVATI" -resultBundlePath "$cartella/pilota.xcresult" \
    -only-testing:WarSenseEsplorazione/SessioneInterattivaTest/test_sessione_da_tester > "$cartella/pilota.log" 2>&1 &
  echo $! > "$cartella/pilota.pid"
  python3 "$RADICE/scripts/interattivo.py" "$cartella" --pronto "${PILOTA_ATTESA:-420}" || return 1
  # Il servitore degli appunti: dà al pilota la pronuncia INTERA di VoiceOver, che il servizio delle
  # prove tronca a 64 caratteri. Finisce da sé col pilota; chiudi_pilota lo ferma comunque.
  rm -rf "$cartella/appunti"
  nohup python3 "$RADICE/scripts/interattivo.py" "$cartella" --appunti "$udid" > "$cartella/appunti.log" 2>&1 &
  echo $! > "$cartella/appunti.pid"
}

# Spegne VoiceOver, ferma il pilota, riporta il testo alla dimensione predefinita e l'apparecchio in
# verticale, e controlla col cancello che VoiceOver sia spento. Se il pilota era caduto lasciandolo
# acceso, lo riaccende per il tempo di spegnerlo.
chiudi_pilota() {  # $1 udid, $2 cartella
  local udid="$1" cartella="$2" pid n=0
  pid="$(cat "$cartella/pilota.pid" 2>/dev/null)"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    python3 "$RADICE/scripts/interattivo.py" "$cartella" '{"azione": "orientamento", "verso": "verticale", "ascolto": 0.2}' 60 >/dev/null
    python3 "$RADICE/scripts/interattivo.py" "$cartella" '{"azione": "vo_spegni", "ascolto": 0.2}' 60 >/dev/null
    python3 "$RADICE/scripts/interattivo.py" "$cartella" '{"azione": "termina", "ascolto": 0.2}' 60 >/dev/null
    python3 "$RADICE/scripts/interattivo.py" "$cartella" '{"azione": "fine"}' 60 >/dev/null
    while kill -0 "$pid" 2>/dev/null && [ $n -lt 120 ]; do sleep 1; n=$(( n + 1 )); done
  fi
  local servitore="$(cat "$cartella/appunti.pid" 2>/dev/null)"
  if [ -n "$servitore" ] && kill -0 "$servitore" 2>/dev/null; then
    sleep 5; kill -0 "$servitore" 2>/dev/null && kill "$servitore" 2>/dev/null
  fi
  xcrun simctl ui "$udid" content_size large >/dev/null 2>&1
  if ! "$RADICE/scripts/controlla-voiceover-spento.sh" "$udid"; then
    echo "  VoiceOver era rimasto acceso: si riaccende il pilota per spegnerlo"
    local rimedio="$cartella-rimedio"
    pilota_su "$udid" "$rimedio" >/dev/null
    python3 "$RADICE/scripts/interattivo.py" "$rimedio" '{"azione": "vo_accendi", "ascolto": 0.5}' 90 >/dev/null
    python3 "$RADICE/scripts/interattivo.py" "$rimedio" '{"azione": "vo_spegni", "ascolto": 0.2}' 60 >/dev/null
    python3 "$RADICE/scripts/interattivo.py" "$rimedio" '{"azione": "fine"}' 60 >/dev/null
    sleep 8
    "$RADICE/scripts/controlla-voiceover-spento.sh" "$udid"
  fi
}

consegna() {  # $1 cartella del pilota, $2 cartella dei prodotti
  mkdir -p "$2"
  [ -f "$1/comandi.jsonl" ] && cp "$1/comandi.jsonl" "$2/comandi-della-sessione-del-pilota.jsonl"
  [ -f "$1/esiti.jsonl" ] && cp "$1/esiti.jsonl" "$2/esiti-della-sessione-del-pilota.jsonl"
  return 0
}

case "${1:-}" in
  compila)
    compila ;;

  percorsi)
    tipo="${2:?manca l'apparecchio: iphone o ipad}"; shift 2
    istanza="${PILOTA_ISTANZA:-2}"
    rifiuta_il_primo "$istanza" || exit 2
    t0=$(ora)
    compila || exit 1
    t1=$(ora)
    udid="$(udid_di "$tipo" "$istanza")"
    [ -n "$udid" ] || { echo "RIFIUTATO: nessun simulatore di WarSense «$tipo» $istanza"; exit 2; }
    cartella="$LAVORO/corse/$tipo-$istanza-percorsi"; prodotti="$QUI/$tipo"
    echo "== percorsi su $tipo $istanza ($udid) =="
    accendi "$udid"
    pilota_su "$udid" "$cartella" || { echo "il pilota non è partito: $cartella/pilota.log"; tail -20 "$cartella/pilota.log"; exit 1; }
    t2=$(ora)
    # I controlli e l'uscita del guidatore si scrivono DIRETTAMENTE fra i prodotti, man mano, perché
    # un'interruzione non li perda. Rilanciando soltanto alcuni blocchi si tolgono prima le righe di
    # quei blocchi; rilanciando tutto, tutte.
    mkdir -p "$prodotti"
    # La nota di compilazione si copia ALLA PARTENZA: dice su quale app gira questa corsa, anche se
    # mentre gira un'altra corsa ricompila perché i sorgenti sono cambiati.
    cp "$LAVORO/compilazione.txt" "$prodotti/compilazione.txt"
    if [ $# -eq 0 ]; then
      rm -f "$prodotti/controlli.jsonl"
    else
      python3 -c 'import json, pathlib, sys
f = pathlib.Path(sys.argv[1])
if f.exists():
    tenute = [r for r in f.read_text(encoding="utf-8").splitlines() if r.strip() and json.loads(r).get("blocco") not in sys.argv[2:]]
    f.write_text("".join(r + "\n" for r in tenute), encoding="utf-8")' "$prodotti/controlli.jsonl" "$@"
    fi
    echo "== $(date '+%Y-%m-%d %H:%M:%S') percorsi su $tipo $istanza ($udid), blocchi: ${*:-tutti}; $(head -1 "$LAVORO/compilazione.txt")" >> "$prodotti/guidatore.log"
    PERCORSI_CONTROLLI="$prodotti/controlli.jsonl" python3 "$QUI/percorsi-seconda-tappa.py" "$cartella" "$udid" "$tipo" "$@" 2>&1 \
      | tee -a "$prodotti/guidatore.log"
    t3=$(ora)
    chiudi_pilota "$udid" "$cartella"; vo=$?
    spegni "$udid"
    t4=$(ora)
    consegna "$cartella" "$prodotti/sessione-del-pilota-$(date +%d-%H%M)"
    echo "$(date '+%Y-%m-%d %H:%M:%S') percorsi $tipo $istanza ($udid), blocchi ${*:-tutti}: compilazione $(( t1 - t0 )) s, avvio del pilota $(( t2 - t1 )) s, percorsi $(( t3 - t2 )) s, chiusura $(( t4 - t3 )) s (date +%s); VoiceOver spento: $([ $vo -eq 0 ] && echo sì || echo NO)" \
      | tee -a "$prodotti/tempi.txt"
    ;;

  tester)
    tipo="${2:?manca l'apparecchio}"; istanza="${3:?manca l'istanza}"; nome="${4:?manca il nome della corsa}"; shift 4
    rifiuta_il_primo "$istanza" || exit 2
    t0=$(ora)
    compila || exit 1
    udid="$(udid_di "$tipo" "$istanza")"
    [ -n "$udid" ] || { echo "RIFIUTATO: nessun simulatore di WarSense «$tipo» $istanza"; exit 2; }
    cartella="$LAVORO/corse/$tipo-$istanza-$nome"; prodotti="$QUI/$tipo/$nome"
    echo "== tester «$nome» su $tipo $istanza ($udid): $@ =="
    accendi "$udid"
    pilota_su "$udid" "$cartella" || { echo "il pilota non è partito: $cartella/pilota.log"; tail -20 "$cartella/pilota.log"; exit 1; }
    # Il diario si scrive DIRETTAMENTE fra i prodotti, una riga alla volta, perché un'interruzione non lo perda.
    mkdir -p "$prodotti"
    rm -f "$prodotti/diario-$1.jsonl"
    python3 "$RADICE/scripts/interattivo.py" "$cartella" '{"azione": "avvia", "ascolto": 2}' 120 >/dev/null
    python3 "$RADICE/scripts/interattivo.py" "$cartella" '{"azione": "vo_accendi", "ascolto": 1}' 120 >/dev/null
    cp "$LAVORO/compilazione.txt" "$prodotti/compilazione.txt"
    t1=$(ora)
    TESTER_DIARIO="$prodotti/diario-$1.jsonl" python3 "$RADICE/scripts/tester.py" "$cartella" "$@" 2>&1 | tee "$prodotti/tester.log"
    t2=$(ora)
    chiudi_pilota "$udid" "$cartella"; vo=$?
    spegni "$udid"
    consegna "$cartella" "$prodotti"
    echo "$(date '+%Y-%m-%d %H:%M:%S') tester «$nome» $tipo $istanza ($udid), argomenti «$*»: avvio $(( t1 - t0 )) s, partita $(( t2 - t1 )) s, chiusura $(( $(ora) - t2 )) s (date +%s); VoiceOver spento: $([ $vo -eq 0 ] && echo sì || echo NO)" \
      | tee -a "$prodotti/tempi.txt"
    ;;

  pilota)
    tipo="${2:?manca l'apparecchio}"; istanza="${3:?manca l'istanza}"; nome="${4:?manca il nome}"
    rifiuta_il_primo "$istanza" || exit 2
    compila || exit 1
    udid="$(udid_di "$tipo" "$istanza")"
    cartella="$LAVORO/corse/$tipo-$istanza-$nome"
    accendi "$udid"
    pilota_su "$udid" "$cartella" || { tail -20 "$cartella/pilota.log"; exit 1; }
    echo "cartella del pilota: $cartella"
    echo "simulatore: $udid"
    ;;

  chiudi)
    tipo="${2:?manca l'apparecchio}"; istanza="${3:?manca l'istanza}"; nome="${4:?manca il nome}"
    rifiuta_il_primo "$istanza" || exit 2
    udid="$(udid_di "$tipo" "$istanza")"
    chiudi_pilota "$udid" "$LAVORO/corse/$tipo-$istanza-$nome"
    spegni "$udid"
    ;;

  *)
    sed -n '2,25p' "$0"; exit 2 ;;
esac
