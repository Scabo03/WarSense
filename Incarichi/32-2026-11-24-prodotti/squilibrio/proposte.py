#!/usr/bin/env python3
"""Le composizioni PROPOSTE al titolare al posto del gruppo di ventiquattro fanti pesanti e dodici cavalieri, che in
battaglia non può avanzare, misurate con gli stessi strumenti del resto: non cambia nessun file del gioco. Per ogni
variante fa una copia dei valori di fabbrica, vi cambia i soli numeri della variante, ed esegue la misura della
frequenza (200 partite per cella, 730 giornate) e il banco del regno (200 partite di 5 anni per condotta), coi due
tattici del banco e con quello del giocatore che non si arrende a metà delle perdite.

Uso, dalla radice del repository, con StrumentoVerifica compilato in release (`swift build -c release` in Codice/):
    python3 Incarichi/32-2026-11-24-prodotti/squilibrio/proposte.py <cartella di lavoro per le copie dei valori>
Scrive in squilibrio/proposte/<variante>/: i riepiloghi dello strumento e il conto di ogni cella («in breve»). Le corse
sono deterministiche: i dati grezzi, che pesano, si riottengono rieseguendo questo file.
"""
import json
import pathlib
import shutil
import subprocess
import sys

RADICE = pathlib.Path(__file__).resolve().parents[3]
VALORI = RADICE / "Codice/Sources/Contenuti/Valori"
STRUMENTO = RADICE / "Codice/.build/release/StrumentoVerifica"
USCITA = pathlib.Path(__file__).resolve().parent / "proposte"
P, C, L = "fanteria_pesante", "cavalleria_manovrata", "fanteria_leggera"


def composizione(*reparti):
    return [{"archetipo": a, "atomi": n} for a, n in reparti]


# nome della variante: (il gruppo armato dell'avversario sulla mappa media, il gruppo del giocatore)
VARIANTI = {
    "0-com-e-oggi": (None, None),
    "1-12P-6C": (composizione((P, 12), (C, 6)), composizione((P, 12), (C, 6))),
    "2-16P-8C": (composizione((P, 16), (C, 8)), composizione((P, 16), (C, 8))),
    "3-avversario-18L-8P": (composizione((L, 18), (P, 8)), composizione((P, 12), (C, 6))),
    "4-12P-12P-6C-6C": (composizione((P, 12), (P, 12), (C, 6), (C, 6)), composizione((P, 12), (P, 12), (C, 6), (C, 6))),
}


def valori_della_variante(nome, base):
    """Una copia dei valori di fabbrica con le due composizioni della variante, e nient'altro di diverso."""
    cartella = base / nome
    if cartella.exists():
        shutil.rmtree(cartella)
    shutil.copytree(VALORI, cartella)
    avversario, giocatore = VARIANTI[nome]
    scenari = json.loads((VALORI / "scenari-campagna.json").read_text(encoding="utf-8"))
    regno = json.loads((VALORI / "regno.json").read_text(encoding="utf-8"))
    cambi = 0

    def e_il_gruppo_pesante(voce):
        return any(r["archetipo"] == C for r in voce["composizione"])

    if avversario:
        for gruppo in scenari["campagna_media"]["gruppi_avversario"]:
            if e_il_gruppo_pesante(gruppo):
                gruppo["composizione"] = avversario
                cambi += 1
    if giocatore:
        for chiave in ("campagna_media", "campagna_grande"):
            for gruppo in scenari[chiave]["gruppi_giocatore"]:
                if e_il_gruppo_pesante(gruppo):
                    gruppo["composizione"] = giocatore
                    cambi += 1
        for formazione in regno["forze_iniziali"]:
            if e_il_gruppo_pesante(formazione):
                formazione["composizione"] = giocatore
                cambi += 1
    attesi = (1 if avversario else 0) + (3 if giocatore else 0)
    assert cambi == attesi, (nome, cambi, attesi)
    (cartella / "scenari-campagna.json").write_text(json.dumps(scenari, indent=1), encoding="utf-8")
    (cartella / "regno.json").write_text(json.dumps(regno, indent=1), encoding="utf-8")
    return cartella


def main():
    base = pathlib.Path(sys.argv[1])
    base.mkdir(parents=True, exist_ok=True)
    for nome in VARIANTI:
        valori = valori_della_variante(nome, base)
        for suffisso, opzione in (("", []), ("-tattico-pari", ["--tattico-pari"])):
            for strumento, argomenti, dati in (
                    ("frequenza", ["--frequenza-battaglie", "200", "--giornate-massime", "730"], "frequenza-battaglie.jsonl"),
                    ("regno", ["--regno", "200", "--anni", "5"], "banco-del-regno.jsonl")):
                lavoro = base / f"uscita-{nome}-{strumento}{suffisso}"
                if lavoro.exists():
                    shutil.rmtree(lavoro)
                subprocess.run([str(STRUMENTO), "--valori", str(valori), *argomenti, *opzione, "--uscita", str(lavoro)],
                               check=True, stdout=subprocess.DEVNULL)
                meta = USCITA / nome
                meta.mkdir(parents=True, exist_ok=True)
                for file in lavoro.iterdir():
                    if file.suffix == ".txt":
                        shutil.copy(file, meta / f"{file.stem}{suffisso}{file.suffix}")
                # Della misura della frequenza si conserva il conto di ogni cella.
                if strumento == "frequenza":
                    with open(lavoro / dati, encoding="utf-8") as f, \
                            open(meta / f"frequenza-in-breve{suffisso}.txt", "w", encoding="utf-8") as u:
                        u.write("condotta|formato|partite|battaglie|vinte|perse|ferme|violazioni|vinte_senza_perdite|"
                                "perse_senza_perdite\n")
                        conti = {}
                        for riga in f:
                            r = json.loads(riga)
                            c = conti.setdefault((r["condotta"], r["formato"]), [0] * 8)
                            c[0] += 1
                            c[1] += r["battaglie"]
                            c[2] += r["vinte"]
                            c[3] += r["perse"]
                            c[4] += r["fine"] == "ferma"
                            c[5] += bool(r["violazioni"])
                            c[6] += r["vinte_senza_perdite"]
                            c[7] += r["perse_senza_perdite"]
                        for k, c in conti.items():
                            u.write("|".join([*k, *map(str, c)]) + "\n")
                # Del banco del regno si conservano, per ogni anno, i soli campi della tabella.
                if strumento == "regno":
                    with open(lavoro / dati, encoding="utf-8") as f, \
                            open(meta / f"banco-del-regno-in-breve{suffisso}.txt", "w", encoding="utf-8") as u:
                        u.write("condotta|fronte|anni|battaglie|vinte|perse|campagne_vinte|campagne_perse|inverno|ferme|violazioni|"
                                "vinte_senza_perdite|perse_senza_perdite\n")
                        conti = {}
                        for riga in f:
                            r = json.loads(riga)
                            k = (r["condotta"], r["fronte"])
                            c = conti.setdefault(k, [0] * 11)
                            c[0] += 1
                            c[1] += r["battaglie"]
                            c[2] += r["vinte"]
                            c[3] += r["perse"]
                            c[4] += r.get("vincitore") == "giocatore"
                            c[5] += r.get("vincitore") == "avversario"
                            c[6] += r["conclusione"] == "inverno"
                            c[7] += r["conclusione"] == "ferma"
                            c[8] += bool(r["violazioni"])
                            c[9] += r["vinte_senza_perdite"]
                            c[10] += r["perse_senza_perdite"]
                        for k, c in conti.items():
                            u.write("|".join([*k, *map(str, c)]) + "\n")
        print(nome, "fatta", flush=True)


if __name__ == "__main__":
    main()
