#!/bin/zsh
# Cancello dei simboli d'archetipo (RDA-97, principio 1). Rifiuta lo stato sbagliato
# invece di affidarlo a una prescrizione scritta, come impone questo progetto:
#
#   ogni archetipo di `archetipi.json` deve avere UN simbolo `<archetipo>.symbolset`
#   in `Immagini.xcassets`, e ogni `.symbolset` deve corrispondere a un archetipo.
#
# È la biiezione archetipi <-> simboli, nei due versi: un archetipo senza simbolo e
# un simbolo orfano sono entrambi rifiutati. Il verso «archetipo senza simbolo» è
# controllato anche dalla prova ospitata `SimboliDegliArchetipiTest`; questo cancello
# aggiunge il verso «simbolo orfano», che a runtime non è enumerabile dal catalogo.
#
# Si ferma al primo disallineamento e restituisce un codice diverso da zero.
# Uso: ./scripts/verifica-simboli.sh
set -euo pipefail

RADICE="$(cd "$(dirname "$0")/.." && pwd)"
ARCHETIPI="$RADICE/Codice/Sources/Contenuti/Valori/archetipi.json"
XCASSETS="$RADICE/Applicazione/Risorse/Immagini.xcassets"

python3 - "$ARCHETIPI" "$XCASSETS" <<'PY'
import json, sys, pathlib

archetipi_json, xcassets = sys.argv[1], sys.argv[2]
dati = json.load(open(archetipi_json, encoding="utf-8"))
archetipi = {e["identificatore"] for e in dati}

simboli = set()
for d in sorted(pathlib.Path(xcassets).glob("*.symbolset")):
    nome = d.name[: -len(".symbolset")]
    simboli.add(nome)
    contents = d / "Contents.json"
    svg = d / f"{nome}.svg"
    if not contents.is_file():
        sys.stderr.write(f"RIFIUTATO: «{d.name}» non ha Contents.json\n"); sys.exit(1)
    if not svg.is_file():
        sys.stderr.write(f"RIFIUTATO: «{d.name}» non ha il file «{nome}.svg»\n"); sys.exit(1)

senza_simbolo = sorted(archetipi - simboli)
orfani = sorted(simboli - archetipi)
if senza_simbolo:
    sys.stderr.write("RIFIUTATO: archetipi senza simbolo (aggiungere <id>.symbolset): "
                     + ", ".join(senza_simbolo) + "\n"); sys.exit(1)
if orfani:
    sys.stderr.write("RIFIUTATO: simboli orfani (nessun archetipo corrispondente): "
                     + ", ".join(orfani) + "\n"); sys.exit(1)

print(f"Simboli d'archetipo: biiezione verificata su {len(archetipi)} archetipi "
      + "(" + ", ".join(sorted(archetipi)) + ")")
PY
