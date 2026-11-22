#!/bin/zsh
# Cancello: sul simulatore su cui stanno per girare le prove d'interfaccia VoiceOver deve essere SPENTO.
#
# Perché esiste (incarico 30). Il pilota della sessione da tester accende VoiceOver sul simulatore; se
# la sessione finisce senza spegnerlo, VoiceOver resta acceso anche a pilota uscito. Con VoiceOver acceso
# il tocco semplice di XCUITest mette soltanto a fuoco l'elemento e non lo attiva: le prove d'interfaccia
# falliscono tutte, e il fallimento sembra un difetto dell'app («si apre la patria» non vero dopo il tocco
# su «Nuovo regno»). È accaduto: `FumoRegnoTest` rossa sul simulatore su cui il pilota era appena uscito,
# verde appena spento VoiceOver. Il pilota ora lo spegne da sé all'uscita; questo cancello rifiuta lo
# stato sbagliato comunque sia nato, in pochi secondi, dichiarando la causa e il rimedio.
#
# Uso: scripts/controlla-voiceover-spento.sh <UDID del simulatore>
set -euo pipefail

UDID="${1:?manca l'UDID del simulatore}"
# Lo stato si legge dalle preferenze dell'apparecchio, che rispondono solo ad apparecchio acceso: se è
# spento lo si accende, come farebbe comunque xcodebuild un momento dopo.
if ! xcrun simctl list devices | grep "$UDID" | grep -q "(Booted)"; then
  xcrun simctl boot "$UDID" 2>/dev/null || true
  xcrun simctl bootstatus "$UDID" -b >/dev/null
fi
# La chiave manca finché VoiceOver non è mai stato acceso: vale come spento.
VALORE="$(xcrun simctl spawn "$UDID" defaults read com.apple.Accessibility VoiceOverTouchEnabled 2>/dev/null || echo 0)"
if [ "$VALORE" = "1" ]; then
  echo "RIFIUTATO: VoiceOver è acceso sul simulatore $UDID."
  echo "  Con VoiceOver acceso il tocco delle prove d'interfaccia mette a fuoco e non attiva: fallirebbero tutte."
  echo "  Lo ha lasciato acceso una sessione del pilota finita senza spegnerlo. Rimedio: dare al pilota"
  echo "  {\"azione\": \"vo_spegni\"} prima di {\"azione\": \"fine\"}, oppure riavviare il pilota e uscirne:"
  echo "  dall'incarico 30 lo spegne da sé all'uscita."
  exit 1
fi
echo "  VoiceOver spento sul simulatore $UDID"
