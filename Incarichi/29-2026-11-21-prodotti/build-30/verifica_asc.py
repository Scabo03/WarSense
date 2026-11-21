"""Verifica per API della build caricata (incarico 29). Uso: RADICE_SCRIPTS=<repo>/scripts python3 verifica_asc.py <numero>"""
import os
import sys

sys.path.insert(0, os.environ["RADICE_SCRIPTS"])
from asc_api import chiama  # noqa: E402

APP = "6797306323"
numero = sys.argv[1]
d = chiama("GET", f"/v1/builds?filter[app]={APP}&limit=3&sort=-uploadedDate&include=preReleaseVersion")
versioni = {i["id"]: i["attributes"].get("version") for i in d.get("included", []) if i["type"] == "preReleaseVersions"}
print("| build | stato | caricata | scaduta | treno |")
print("|---|---|---|---|---|")
bersaglio = None
for b in d["data"]:
    a = b["attributes"]
    pre = b.get("relationships", {}).get("preReleaseVersion", {}).get("data") or {}
    print(f"| {a['version']} | {a['processingState']} | {a['uploadedDate']} | {a['expired']} | {versioni.get(pre.get('id'), '?')} |")
    if a["version"] == numero:
        bersaglio = b
if not bersaglio:
    print(f"build {numero} non trovata fra le ultime tre")
    sys.exit(1)
dettaglio = chiama("GET", f"/v1/builds/{bersaglio['id']}/buildBetaDetail")["data"]["attributes"]
print(f"\nBuild {numero}, dettaglio beta: internalBuildState {dettaglio.get('internalBuildState')}, "
      f"externalBuildState {dettaglio.get('externalBuildState')}, autoNotifyEnabled {dettaglio.get('autoNotifyEnabled')}.")
loc = chiama("GET", f"/v1/builds/{bersaglio['id']}/betaBuildLocalizations")["data"]
for l in loc:
    w = l["attributes"].get("whatsNew") or ""
    nota = open(os.path.join(os.environ["RADICE_SCRIPTS"], "..", "note-di-rilascio.txt"), encoding="utf-8").read()
    print(f"Nota per i tester ({l['attributes'].get('locale')}): {len(w)} caratteri; "
          f"uguale a note-di-rilascio.txt: {w.strip() == nota.strip()}")
gruppi = chiama("GET", f"/v1/apps/{APP}/betaGroups")["data"]
for g in gruppi:
    a = g["attributes"]
    print(f"Gruppo «{a.get('name')}»: interno {a.get('isInternalGroup')}, hasAccessToAllBuilds {a.get('hasAccessToAllBuilds')}")
