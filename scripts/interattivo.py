#!/usr/bin/env python3
"""Il lato Mac del pilota della sessione da tester (incarico 28, seconda parte).

Il pilota (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`) gira sul simulatore e legge
i comandi da `<cartella>/comandi.jsonl`; questo script ne aggiunge uno, attende il suo esito in
`<cartella>/esiti.jsonl` e lo stampa in forma breve. Un comando è un oggetto JSON con «azione» e i
suoi parametri, per esempio {"azione": "attiva", "etichetta": "Impostazioni", "tipo": "pulsante"}.

Uso:
  python3 scripts/interattivo.py <cartella> '<comando JSON>' [secondi di attesa]
  python3 scripts/interattivo.py <cartella> --pronto [secondi]   attende che il pilota sia acceso
"""
import json
import pathlib
import sys
import time


def esiti(cartella):
    f = cartella / "esiti.jsonl"
    if not f.exists():
        return []
    righe = []
    for riga in f.read_text(encoding="utf-8").splitlines():
        try:
            righe.append(json.loads(riga))
        except json.JSONDecodeError:
            pass
    return righe


def breve(e):
    parti = [f"#{e.get('n')} {e.get('azione')}"]
    for k in ("elemento", "errore", "stato_app", "fuoco", "prima"):
        if k in e:
            parti.append(f"{k}: {e[k]}")
    if "pronunce" in e:
        parti.append(f"pronunce ({len(e['pronunce'])}): " + " | ".join(e["pronunce"]))
    if "ascoltate" in e:
        parti.append("ascoltate: " + " | ".join(e["ascoltate"]))
    if "dopo" in e:
        parti.append(f"dopo: {e['dopo']}")
    if "schermata" in e:
        parti.append(f"schermata: {e['schermata']}")
    if "albero" in e:
        parti.append("albero:\n    " + "\n    ".join(e["albero"]))
    parti.append(f"[{e.get('durata_azione_s', '')} s, vo {e.get('vo_acceso')}]")
    return "\n  ".join(parti)


def main():
    cartella = pathlib.Path(sys.argv[1])
    cartella.mkdir(parents=True, exist_ok=True)
    if sys.argv[2] == "--pronto":
        limite = time.time() + float(sys.argv[3] if len(sys.argv) > 3 else 300)
        while time.time() < limite:
            if any(e.get("azione") == "pronto" for e in esiti(cartella)):
                print("pilota pronto")
                return 0
            time.sleep(1)
        print("pilota NON pronto")
        return 1
    comando = json.loads(sys.argv[2])
    attesa = float(sys.argv[3] if len(sys.argv) > 3 else 120)
    file_comandi = cartella / "comandi.jsonl"
    gia = file_comandi.read_text(encoding="utf-8").splitlines() if file_comandi.exists() else []
    comando["n"] = len(gia) + 1
    with file_comandi.open("a", encoding="utf-8") as f:
        f.write(json.dumps(comando, ensure_ascii=False) + "\n")
    limite = time.time() + attesa
    while time.time() < limite:
        for e in esiti(cartella):
            if e.get("n") == comando["n"]:
                print(breve(e))
                return 0
        time.sleep(0.3)
    print(f"#{comando['n']} {comando.get('azione')}: NESSUN ESITO in {attesa:.0f} s")
    return 1


if __name__ == "__main__":
    sys.exit(main())
