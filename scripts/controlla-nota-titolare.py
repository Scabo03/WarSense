#!/usr/bin/env python3
"""Cancello sulla nota per il titolare: rifiuta, non avverte.

Perché esiste. `nota-per-il-titolare-mappa.md` è il documento su cui il titolare
si forma il giudizio sul lavoro, e alla verifica dell'esame critico (§4.3, D6–D9)
aveva quattro affermazioni false su quattro: due commit su trentanove, mai
rilette. `note-di-rilascio.txt` ha lo stesso destinatario, quattordici commit su
trentanove ed è coerente — per una ragione sola: `carica-testflight.sh` rifiuta
il caricamento se manca o se supera il limite. Questo script porta la stessa
protezione all'altro documento.

Che cosa rifiuta, in ordine:

1. ESISTENZA — nessuna `nota-per-il-titolare-*.md` nella cartella, o vuota.
2. VOCABOLARIO — un nome fra virgolette basse «...» che il codice non espone:
   ogni nome citato deve essere il valore di una chiave dei cataloghi di testo
   (comandi, voci di pannello, annunci, titoli di schermata) oppure un gesto
   dichiarato qui sotto, il cui metodo deve esistere nei sorgenti.
3. MISURE — un numero della nota che il programma di verifica non produce più.
   Le misure si dichiarano in coda alla nota, in un commento, e devono comparire
   nel corpo: il controllo le confronta con una corsa vera del programma.
4. CIFRE NON DICHIARATE — un numero di due cifre o più nel corpo che non
   provenga da una misura dichiarata né dall'elenco delle grandezze di struttura.
5. FRESCHEZZA — la nota più vecchia dell'ultimo commit che ha toccato il codice.
   È il controllo che avrebbe impedito tutte e quattro le affermazioni false: non
   erano errori di misura, erano affermazioni divenute false sotto la nota.

CHE COSA RESTA FUORI DALLA SUA PORTATA, e va dichiarato invece che taciuto: le
affermazioni di COMPORTAMENTO in prosa — «il registro contiene ciò che avviene»,
«continuando ad annullare si torna indietro» — non sono riducibili a un nome né a
un numero, e nessun controllo automatico le giudica. Su quelle agisce soltanto il
punto 5, che obbliga a rileggerle ogni volta che il codice cambia.

Uso:
    python3 scripts/controlla-nota-titolare.py                 # tutti i controlli
    python3 scripts/controlla-nota-titolare.py --solo-vocabolario
"""
import pathlib
import re
import subprocess
import sys

RADICE = pathlib.Path(__file__).resolve().parent.parent
TESTI = RADICE / "Codice" / "Sources" / "Contenuti" / "Testi" / "it.lproj"
SORGENTI = [RADICE / "Applicazione" / "Sorgenti", RADICE / "Codice" / "Sources"]

# I gesti di sistema non sono stringhe di catalogo: sono metodi. Ogni gesto che la
# nota può nominare sta qui con il metodo che lo realizza, e il metodo deve
# esistere nei sorgenti. Toglierlo dal codice fa rifiutare la nota che lo nomina.
GESTI = {
    "tocco magico": "accessibilityPerformMagicTap",
    "gesto di fuga": "accessibilityPerformEscape",
}

# Le grandezze di struttura che la nota può nominare senza che siano misure: sono
# nei dati, non nel rapporto del programma di verifica.
CIFRE_DI_STRUTTURA = {
    "4": "lato della mappa piccola (formati-mappa.json)",
    "6": "lato della mappa media (formati-mappa.json)",
    "10": "lato della mappa grande (formati-mappa.json)",
}


def rifiuta(messaggio):
    print(f"RIFIUTATO: {messaggio}")
    sys.exit(1)


def note():
    trovate = sorted(RADICE.glob("nota-per-il-titolare-*.md"))
    if not trovate:
        rifiuta("non esiste alcuna nota-per-il-titolare-*.md nella cartella di progetto. "
                "È il documento su cui il titolare giudica il lavoro e non può mancare.")
    return trovate


def catalogo():
    """Ogni valore che il gioco può mostrare o pronunciare, dai file dei testi."""
    valori = set()
    for percorso in sorted(TESTI.glob("*.strings")):
        testo = percorso.read_text(encoding="utf-8")
        for _, valore in re.findall(r'^"([^"]+)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;',
                                    testo, re.MULTILINE):
            valori.add(valore.replace('\\"', '"'))
    if not valori:
        rifiuta(f"nessun testo caricato da {TESTI}: il catalogo è vuoto e il "
                "controllo del vocabolario sarebbe vacuo.")
    return valori


def espressione(valore):
    """Il valore del catalogo come espressione: i segnaposto valgono per qualunque
    riempimento, perché la nota cita la frase e non l'occorrenza."""
    pezzi = re.split(r"%(?:\d+\$)?(?:@|lld|ld|d|u|f)", valore)
    return re.compile("^" + ".+?".join(re.escape(p) for p in pezzi) + "$", re.IGNORECASE)


def simboli_dei_sorgenti():
    trovati = set()
    for radice in SORGENTI:
        for percorso in radice.rglob("*.swift"):
            trovati.update(re.findall(r"\b[A-Za-z_][A-Za-z0-9_]*\b",
                                      percorso.read_text(encoding="utf-8")))
    return trovati


def controlla_vocabolario(percorsi):
    valori = catalogo()
    espressioni = [espressione(v) for v in valori]
    simboli = simboli_dei_sorgenti()
    citati = 0
    for percorso in percorsi:
        testo = percorso.read_text(encoding="utf-8")
        for nome in re.findall(r"«([^»]+)»", testo):
            citati += 1
            # Il markdown va a capo dove gli pare: una frase citata può spezzarsi su
            # due righe senza che sia una frase diversa.
            pulito = " ".join(nome.split())
            if pulito.lower() in GESTI:
                metodo = GESTI[pulito.lower()]
                if metodo not in simboli:
                    rifiuta(f"{percorso.name} nomina il gesto «{pulito}», ma il codice "
                            f"non contiene più {metodo}.")
                continue
            if pulito in valori:
                continue
            if any(e.match(pulito) for e in espressioni):
                continue
            rifiuta(f"{percorso.name} nomina «{pulito}», che il codice non espone: "
                    "non è il valore di alcuna chiave dei testi né un gesto dichiarato. "
                    "O il nome è cambiato, o la nota descrive una cosa che non esiste.")
    if citati == 0:
        rifiuta("la nota non cita alcun nome fra «...»: il controllo del vocabolario "
                "sarebbe vacuo, e una nota che non nomina nulla non descrive nulla.")
    print(f"vocabolario: {citati} nomi citati, tutti esposti dal codice")


def misure_dichiarate(testo):
    """Le misure in coda alla nota:
    <!-- misura: <sezione> | <chiave riga> | <colonna>=<valore> ... -->"""
    dichiarate = []
    for riga in re.findall(r"<!--\s*misura:(.+?)-->", testo, re.DOTALL):
        pezzi = [p.strip() for p in riga.split("|")]
        if len(pezzi) != 3:
            rifiuta(f"misura malformata nella nota: «{riga.strip()}». "
                    "Forma attesa: sezione | chiave della riga | colonna=valore ...")
        sezione, chiave, coppie = pezzi
        valori = {}
        for coppia in coppie.split():
            if "=" not in coppia:
                rifiuta(f"misura malformata: «{coppia}» non è colonna=valore")
            colonna, valore = coppia.split("=", 1)
            valori[colonna] = valore
        dichiarate.append((sezione, chiave, valori))
    return dichiarate


def rapporto_del_programma():
    esito = subprocess.run(["swift", "run", "StrumentoVerifica"],
                           cwd=RADICE / "Codice", capture_output=True, text=True)
    if esito.returncode != 0:
        rifiuta("il programma di verifica non è eseguibile, quindi le misure della "
                f"nota non sono controllabili:\n{esito.stderr[-2000:]}")
    sezioni = {}
    nome = None
    for riga in esito.stdout.splitlines():
        if riga.startswith("#"):
            nome = riga[1:].strip()
            sezioni[nome] = {"intestazione": None, "righe": []}
        elif nome and riga.strip():
            campi = riga.split(",")
            if sezioni[nome]["intestazione"] is None:
                sezioni[nome]["intestazione"] = campi
            else:
                sezioni[nome]["righe"].append(campi)
    return sezioni


def controlla_misure(percorsi):
    dichiarate = []
    for percorso in percorsi:
        dichiarate += [(percorso, *m) for m in misure_dichiarate(
            percorso.read_text(encoding="utf-8"))]
    if not dichiarate:
        print("misure: nessuna dichiarata")
        return set()
    sezioni = rapporto_del_programma()
    attesi = set()
    for percorso, sezione, chiave, valori in dichiarate:
        if sezione not in sezioni:
            rifiuta(f"{percorso.name} cita la sezione «{sezione}», che il programma "
                    "di verifica non stampa più.")
        intestazione = sezioni[sezione]["intestazione"]
        campi_chiave = chiave.split(",")
        righe = [r for r in sezioni[sezione]["righe"]
                 if r[:len(campi_chiave)] == campi_chiave]
        if len(righe) != 1:
            rifiuta(f"{percorso.name}: la chiave «{chiave}» individua {len(righe)} righe "
                    f"nella sezione «{sezione}»; ne serve esattamente una.")
        riga = righe[0]
        corpo = percorso.read_text(encoding="utf-8")
        for colonna, valore in valori.items():
            if colonna not in intestazione:
                rifiuta(f"{percorso.name}: la colonna «{colonna}» non esiste più nella "
                        f"sezione «{sezione}». Colonne attuali: {', '.join(intestazione)}")
            effettivo = riga[intestazione.index(colonna)]
            if effettivo != valore:
                rifiuta(f"{percorso.name} dichiara {colonna}={valore} per «{chiave}», "
                        f"ma il programma di verifica stampa {effettivo}. "
                        "Il numero della nota non è più quello misurato.")
            if not re.search(rf"(?<!\d){re.escape(valore)}(?!\d)", corpo):
                rifiuta(f"{percorso.name} dichiara la misura {colonna}={valore} ma non la "
                        "scrive nel corpo: la dichiarazione non protegge nulla.")
            attesi.add(valore)
    print(f"misure: {len(dichiarate)} dichiarate, tutte pari a ciò che il programma stampa")
    return attesi


def controlla_cifre(percorsi, attesi):
    ammesse = set(attesi) | set(CIFRE_DI_STRUTTURA)
    for percorso in percorsi:
        corpo = re.sub(r"<!--.*?-->", "", percorso.read_text(encoding="utf-8"), flags=re.DOTALL)
        for numero in re.findall(r"(?<![\w.])(\d{2,})(?![\w.])", corpo):
            if numero not in ammesse:
                rifiuta(f"{percorso.name} contiene il numero {numero}, che non proviene "
                        "da alcuna misura dichiarata né da una grandezza di struttura. "
                        "Un numero che nessuno riverifica è il modo in cui questa nota "
                        "è già invecchiata una volta: dichiaralo con un commento "
                        "<!-- misura: sezione | riga | colonna=valore --> oppure toglilo.")
    print("cifre: nessun numero non dichiarato nel corpo")


def ultimo_commit(percorsi):
    esito = subprocess.run(["git", "log", "-1", "--format=%H %ct", "--"] +
                           [str(p) for p in percorsi],
                           cwd=RADICE, capture_output=True, text=True)
    uscita = esito.stdout.strip()
    if not uscita:
        return None, 0
    sha, quando = uscita.split()
    return sha, int(quando)


def controlla_freschezza(percorsi):
    sha_nota, quando_nota = ultimo_commit(percorsi)
    sha_codice, quando_codice = ultimo_commit(SORGENTI)
    if sha_nota is None:
        rifiuta("la nota per il titolare non è mai stata committata: non esiste modo "
                "di stabilire se descriva il codice che si sta per caricare.")
    if quando_codice > quando_nota:
        rifiuta("la nota per il titolare è più vecchia dell'ultimo commit che ha "
                f"toccato il codice.\n  nota:   {sha_nota[:7]}\n  codice: {sha_codice[:7]}\n"
                "Rileggila contro il comportamento attuale e committala nella stessa "
                "modifica. È il controllo che avrebbe impedito le quattro affermazioni "
                "false trovate dall'esame critico: non erano errori di misura, erano "
                "affermazioni divenute false sotto una nota che nessuno rileggeva.")
    print(f"freschezza: la nota ({sha_nota[:7]}) non è più vecchia del codice "
          f"({sha_codice[:7]})")


def main():
    solo_vocabolario = "--solo-vocabolario" in sys.argv
    percorsi = note()
    for percorso in percorsi:
        if not percorso.read_text(encoding="utf-8").strip():
            rifiuta(f"{percorso.name} è vuota.")
    print(f"note trovate: {', '.join(p.name for p in percorsi)}")
    controlla_vocabolario(percorsi)
    if solo_vocabolario:
        print("(modo --solo-vocabolario: misure, cifre e freschezza non controllate)")
        return 0
    attesi = controlla_misure(percorsi)
    controlla_cifre(percorsi, attesi)
    controlla_freschezza(percorsi)
    print("la nota per il titolare regge a tutti i controlli: si procede")
    return 0


if __name__ == "__main__":
    sys.exit(main())
