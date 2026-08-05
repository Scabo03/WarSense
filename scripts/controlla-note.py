#!/usr/bin/env python3
"""Cancello sui documenti consegnati a chi usa il gioco: rifiuta, non avverte.

## Perché esiste, e perché ora vale per due documenti

Tre volte lo stesso errore. `nota-per-il-titolare-mappa.md` aveva quattro
affermazioni false su quattro (esame-critico.md §4.3, D6–D9) perché nessuno la
rileggeva; è stata messa dietro un controllo il 2026-08-05. `note-di-rilascio.txt`
è partita con la build 14 descrivendo la build precedente, perché il controllo che
la proteggeva ne verificava la LUNGHEZZA e non l'ATTUALITÀ. Stesso destinatario,
stessa classe di errore, protezione diversa — e la differenza non era visibile da
nessuna parte.

## La forma scelta: una tabella che dichiara chi è protetto da che cosa

Il controllo non è duplicato e non è nemmeno «generalizzato» nel senso di applicare
tutto a tutti: `DOCUMENTI` elenca ciascun artefatto con l'insieme dei controlli cui
è soggetto. Una sola realizzazione per ciascun controllo, e la tabella rende
LEGGIBILE ciò che prima era invisibile — quale documento è protetto da che cosa.
Un artefatto nuovo consegnato senza riga in tabella è un artefatto senza cancello,
e si vede a colpo d'occhio.

I controlli:

- `esistenza`   — il file c'è e non è vuoto.
- `lunghezza`   — sta nel limite di App Store Connect per `whatsNew` (4000
                  caratteri, non byte). Rifiuta PRIMA di compilare: il rifiuto di
                  Apple arriva dopo il caricamento e lascia la build senza nota.
- `freschezza`  — il documento non è più vecchio dell'ultimo commit che ha toccato
                  il codice. È il controllo che avrebbe impedito tutti e tre gli
                  episodi: nessuno era un errore di misura, tutti erano affermazioni
                  divenute false sotto un documento che nessuno rileggeva.
- `vocabolario` — ogni nome citato fra virgolette basse esiste nel gioco.
- `misure`      — ogni numero dichiarato è quello che il programma di verifica
                  stampa adesso.
- `cifre`       — nessun numero di due cifre o più che non provenga da una misura
                  dichiarata o da una grandezza di struttura.

## Che cosa resta fuori dalla portata di TUTTI questi controlli

Le affermazioni di COMPORTAMENTO in prosa — «il registro contiene ciò che avviene»,
«continuando ad annullare si torna indietro» — non sono riducibili a un nome né a
un numero, e nessun controllo automatico le giudica. Su quelle agisce soltanto la
freschezza, che obbliga a rileggerle a ogni modifica del codice.

Uso:
    python3 scripts/controlla-note.py                 # tutti i controlli
    python3 scripts/controlla-note.py --senza-programma   # salta misure e freschezza
"""
import pathlib
import re
import subprocess
import sys

RADICE = pathlib.Path(__file__).resolve().parent.parent
TESTI = RADICE / "Codice" / "Sources" / "Contenuti" / "Testi" / "it.lproj"
SORGENTI = [RADICE / "Applicazione" / "Sorgenti", RADICE / "Codice" / "Sources"]

# ============================================================================
# LA TABELLA: chi è consegnato a chi usa il gioco, e da che cosa è protetto.
# Un artefatto consegnato che non compaia qui è un artefatto senza cancello.
# ============================================================================
DOCUMENTI = [
    {
        "modello": "note-di-rilascio.txt",
        "destinatario": "i tester, allegata alla build su TestFlight (whatsNew)",
        "controlli": {"esistenza", "lunghezza", "freschezza"},
    },
    {
        "modello": "nota-per-il-titolare-*.md",
        "destinatario": "il titolare, letta prima di provare la build",
        "controlli": {"esistenza", "vocabolario", "misure", "cifre", "freschezza"},
    },
]

LIMITE_WHATS_NEW = 4000

# I gesti di sistema non sono stringhe di catalogo: sono metodi. Ogni gesto che una
# nota può nominare sta qui con il metodo che lo realizza, e il metodo deve
# esistere nei sorgenti. Toglierlo dal codice fa rifiutare la nota che lo nomina.
GESTI = {
    "tocco magico": "accessibilityPerformMagicTap",
    "gesto di fuga": "accessibilityPerformEscape",
}

# Le grandezze di struttura che una nota può nominare senza che siano misure: sono
# nei dati, non nel rapporto del programma di verifica.
CIFRE_DI_STRUTTURA = {
    "4": "lato della mappa piccola (formati-mappa.json)",
    "6": "lato della mappa media (formati-mappa.json)",
    "10": "lato della mappa grande (formati-mappa.json)",
}


def rifiuta(messaggio):
    print(f"RIFIUTATO: {messaggio}")
    sys.exit(1)


# ---------------------------------------------------------------- i controlli

def controllo_esistenza(percorsi, modello):
    if not percorsi:
        rifiuta(f"non esiste alcun «{modello}» nella cartella di progetto. "
                "È un documento consegnato a chi usa il gioco e non può mancare.")
    for percorso in percorsi:
        if not percorso.read_text(encoding="utf-8").strip():
            rifiuta(f"{percorso.name} è vuota.")


def controllo_lunghezza(percorsi, _modello):
    for percorso in percorsi:
        quanti = len(percorso.read_text(encoding="utf-8"))
        if quanti > LIMITE_WHATS_NEW:
            rifiuta(f"{percorso.name} ha {quanti} caratteri e il limite di App Store "
                    f"Connect è {LIMITE_WHATS_NEW}. Il caricamento andrebbe a buon fine "
                    "ma la nota verrebbe rifiutata dopo, e la build arriverebbe ai tester "
                    f"senza. Accorciare di almeno {quanti - LIMITE_WHATS_NEW} caratteri.")
        print(f"  lunghezza: {percorso.name}, {quanti} caratteri su {LIMITE_WHATS_NEW}")


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


def controllo_vocabolario(percorsi, _modello):
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
        rifiuta("nessun nome citato fra «...»: il controllo del vocabolario sarebbe "
                "vacuo, e una nota che non nomina nulla non descrive nulla.")
    print(f"  vocabolario: {citati} nomi citati, tutti esposti dal codice")


def misure_dichiarate(testo):
    """Le misure in coda alla nota:
    <!-- misura: <sezione> | <chiave riga> | <colonna>=<valore> ... -->"""
    dichiarate = []
    for riga in re.findall(r"<!--\s*misura:(.+?)-->", testo, re.DOTALL):
        pezzi = [p.strip() for p in riga.split("|")]
        if len(pezzi) != 3:
            rifiuta(f"misura malformata: «{riga.strip()}». "
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


ATTESI_DALLE_MISURE = set()


def controllo_misure(percorsi, _modello):
    dichiarate = []
    for percorso in percorsi:
        dichiarate += [(percorso, *m) for m in misure_dichiarate(
            percorso.read_text(encoding="utf-8"))]
    if not dichiarate:
        print("  misure: nessuna dichiarata")
        return
    sezioni = rapporto_del_programma()
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
            ATTESI_DALLE_MISURE.add(valore)
    print(f"  misure: {len(dichiarate)} dichiarate, tutte pari a ciò che il programma stampa")


def controllo_cifre(percorsi, _modello):
    ammesse = set(ATTESI_DALLE_MISURE) | set(CIFRE_DI_STRUTTURA)
    for percorso in percorsi:
        corpo = re.sub(r"<!--.*?-->", "", percorso.read_text(encoding="utf-8"), flags=re.DOTALL)
        for numero in re.findall(r"(?<![\w.])(\d{2,})(?![\w.])", corpo):
            if numero not in ammesse:
                rifiuta(f"{percorso.name} contiene il numero {numero}, che non proviene "
                        "da alcuna misura dichiarata né da una grandezza di struttura. "
                        "Un numero che nessuno riverifica è il modo in cui questa nota "
                        "è già invecchiata una volta: dichiaralo con un commento "
                        "<!-- misura: sezione | riga | colonna=valore --> oppure toglilo.")
    print("  cifre: nessun numero non dichiarato nel corpo")


def ultimo_commit(percorsi):
    esito = subprocess.run(["git", "log", "-1", "--format=%H %ct", "--"] +
                           [str(p) for p in percorsi],
                           cwd=RADICE, capture_output=True, text=True)
    uscita = esito.stdout.strip()
    if not uscita:
        return None, 0
    sha, quando = uscita.split()
    return sha, int(quando)


def controllo_freschezza(percorsi, modello):
    sha_doc, quando_doc = ultimo_commit(percorsi)
    sha_codice, quando_codice = ultimo_commit(SORGENTI)
    if sha_doc is None:
        rifiuta(f"«{modello}» non è mai stato committato: non esiste modo di stabilire "
                "se descriva il codice che si sta per caricare.")
    if quando_codice > quando_doc:
        rifiuta(f"«{modello}» è più vecchio dell'ultimo commit che ha toccato il codice.\n"
                f"  documento: {sha_doc[:7]}\n  codice:    {sha_codice[:7]}\n"
                "Rileggilo contro il comportamento attuale e committalo nella stessa "
                "modifica. È il controllo che avrebbe impedito tutti e tre gli episodi "
                "noti: nessuno era un errore di misura, tutti erano affermazioni divenute "
                "false sotto un documento che nessuno rileggeva.")
    print(f"  freschezza: documento {sha_doc[:7]}, codice {sha_codice[:7]}")


CONTROLLI = {
    "esistenza": controllo_esistenza,
    "lunghezza": controllo_lunghezza,
    "vocabolario": controllo_vocabolario,
    "misure": controllo_misure,
    "cifre": controllo_cifre,
    "freschezza": controllo_freschezza,
}

# I controlli che hanno bisogno del programma di verifica o della cronologia:
# l'integrazione continua ne salta alcuni, il caricamento nessuno.
CHE_CHIEDONO_IL_PROGRAMMA = {"misure", "freschezza"}

# Le dipendenze fra controlli, dichiarate invece che implicite. `cifre` giudica
# ammissibili i numeri che `misure` ha riconosciuto: saltare `misure` e tenere
# `cifre` farebbe rifiutare numeri legittimi, ed è il primo errore che questa
# generalizzazione ha prodotto.
DIPENDE_DA = {"cifre": "misure"}

# L'ordine è quello della tabella e non quello del dizionario: prima l'esistenza,
# poi ciò che è a buon mercato, poi ciò che costa.
ORDINE = ["esistenza", "lunghezza", "vocabolario", "misure", "cifre", "freschezza"]


def main():
    salta = CHE_CHIEDONO_IL_PROGRAMMA if "--senza-programma" in sys.argv else set()
    for voce in DOCUMENTI:
        percorsi = sorted(RADICE.glob(voce["modello"]))
        print(f"{voce['modello']} → {voce['destinatario']}")
        for nome in ORDINE:
            if nome not in voce["controlli"]:
                continue
            dipendenza = DIPENDE_DA.get(nome)
            if nome in salta or (dipendenza is not None and dipendenza in salta):
                motivo = ("--senza-programma" if nome in salta
                          else f"dipende da «{dipendenza}», che è stato saltato")
                print(f"  {nome}: saltato ({motivo})")
                continue
            CONTROLLI[nome](percorsi, voce["modello"])
    print("i documenti consegnati reggono a tutti i controlli: si procede")
    return 0


if __name__ == "__main__":
    sys.exit(main())
