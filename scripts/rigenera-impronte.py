#!/usr/bin/env python3
"""Rigenera le impronte dei manifest dei Valori e dei Testi (05 §7.2, RDA-54).

È il cambiamento delle impronte a far rinfrescare la copia in Documenti: chi
modifica un file di contenuto DEVE rieseguire questo script nella stessa
modifica, altrimenti le installazioni esistenti restano con dati stantii
(memoria di infrastruttura, regola 6). Le VERSIONI non si toccano mai qui:
si cambiano soltanto su istruzione del titolare.

Uso: python3 scripts/rigenera-impronte.py            rigenera i manifest
     python3 scripts/rigenera-impronte.py --verifica  controlla senza scrivere,
                                                      esce 1 se qualcosa diverge
"""
import hashlib
import json
import pathlib
import sys

RADICE = pathlib.Path(__file__).resolve().parent.parent
CONTENUTI = RADICE / "Codice" / "Sources" / "Contenuti"


def impronta(percorso):
    return hashlib.sha256(percorso.read_bytes()).hexdigest()


def elenca(cartella, estensioni):
    """Tutti i file di contenuto sotto la cartella, escluso il manifest."""
    trovati = []
    for percorso in sorted(cartella.rglob("*")):
        if not percorso.is_file():
            continue
        if percorso.name == "manifest.json":
            continue
        if percorso.suffix not in estensioni:
            continue
        trovati.append(percorso.relative_to(cartella).as_posix())
    return trovati


def aggiorna(cartella, estensioni):
    manifest_percorso = cartella / "manifest.json"
    manifest = json.loads(manifest_percorso.read_text(encoding="utf-8"))
    nomi = elenca(cartella, estensioni)
    manifest["impronte"] = {nome: impronta(cartella / nome) for nome in nomi}
    manifest_percorso.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1, sort_keys=True) + "\n",
        encoding="utf-8")
    print(f"{manifest_percorso.relative_to(RADICE)}: {len(nomi)} file, "
          f"versione {manifest['versione']} (invariata)")
    return nomi


def verifica(cartella, estensioni):
    """Confronta le impronte committate con i file, SENZA scrivere. Restituisce
    l'elenco dei file divergenti o assenti. È il controllo che il collaudo esegue
    per primo, così che un file di Contenuti cambiato senza rigenerare dichiari la
    causa PRIMA delle prove del pacchetto, invece di farle fallire in massa."""
    manifest_percorso = cartella / "manifest.json"
    manifest = json.loads(manifest_percorso.read_text(encoding="utf-8"))
    committate = manifest.get("impronte", {})
    presenti = set(elenca(cartella, estensioni))
    divergenti = []
    for nome in sorted(set(committate) | presenti):
        percorso = cartella / nome
        if nome not in committate:
            divergenti.append(f"{nome} (presente ma non nel manifest)")
        elif not percorso.is_file():
            divergenti.append(f"{nome} (nel manifest ma assente)")
        elif impronta(percorso) != committate[nome]:
            divergenti.append(f"{nome} (impronta divergente)")
    return divergenti


def main():
    if "--verifica" in sys.argv[1:]:
        tutte = []
        for cartella, estensioni in ((CONTENUTI / "Valori", {".json"}),
                                     (CONTENUTI / "Testi", {".strings", ".stringsdict"})):
            for nome in verifica(cartella, estensioni):
                tutte.append(f"{cartella.relative_to(RADICE)}/{nome}")
        if tutte:
            sys.stderr.write(
                "RIFIUTATO: un file di Contenuti è cambiato senza rigenerare le impronte.\n"
                "Esegui `python3 scripts/rigenera-impronte.py` e ricommitta.\n"
                "File divergenti:\n  " + "\n  ".join(tutte) + "\n")
            return 1
        print("Impronte dei Contenuti coerenti col manifest.")
        return 0
    aggiorna(CONTENUTI / "Valori", {".json"})
    aggiorna(CONTENUTI / "Testi", {".strings", ".stringsdict"})
    return 0


if __name__ == "__main__":
    sys.exit(main())
