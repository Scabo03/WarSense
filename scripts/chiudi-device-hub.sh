#!/bin/sh
# Chiude Device Hub soltanto se gli unici simulatori accesi sono di WarSense.
# Chiudere Device Hub spegne TUTTI i simulatori accesi, e fa cadere le prove che vi girano (visto il
# 2026-11-21, incarico 28: alle 17:04:02 si sono spenti insieme i tre simulatori di WarSense). La
# convivenza vieta di spegnere i simulatori degli altri progetti e i comandi che agiscono su tutti i
# simulatori insieme (CLAUDE.md): con un simulatore altrui acceso, Device Hub resta aperto.
# Uso: scripts/chiudi-device-hub.sh
altri=$(xcrun simctl list devices booted | grep "(Booted)" | grep -v "^ *WarSense ")
if [ -n "$altri" ]; then
    echo "RIFIUTO: chiudere Device Hub spegnerebbe anche simulatori che non sono di WarSense:"
    echo "$altri"
    exit 2
fi
nostri=$(xcrun simctl list devices booted | grep -c "(Booted)")
if [ "$nostri" -gt 0 ]; then
    echo "Attenzione: si spengono anche $nostri simulatori di WarSense accesi, con le prove che vi girano."
fi
if pgrep -x DeviceHub >/dev/null; then
    osascript -e 'tell application id "com.apple.dt.Devices" to quit'
    echo "Device Hub chiuso."
else
    echo "Device Hub non era aperto."
fi
