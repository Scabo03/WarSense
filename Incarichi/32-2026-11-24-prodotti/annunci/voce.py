"""I tratti di voce di VoiceOver su un simulatore, dal registro unificato del sistema (incarico 32).

Il servizio VoiceOver delle prove dà la pronuncia «dell'elemento a fuoco», non ciò che la voce sta dicendo:
con un annuncio a priorità alta restituisce già l'elemento mentre la voce dice ancora l'annuncio. Il registro
di sistema del simulatore dice invece quando la VOCE parla: VoiceOver (processo `vot`) e il suo sintetizzatore
(`MauiAUSP`) vi scrivono quando una sintesi comincia («[IdleTimerAssertion] acquired», «Synthesis request
received»), quando la coda audio si svuota da sé perché il testo è finito («AudioQueue underflow», subito
prima di «[IdleTimerAssertion] released») e quando viene lasciata prima («released» senza svuotamento). Da qui
i tratti VERI: inizio, fine, durata, e se la fine è naturale («intera») o no («troncata»). Il testo non vi
compare: lo dà il registro della copia strumentata dell'app (chi ha pubblicato che cosa, e quando).

Uso da riga di comando: voce.py <udid> <inizio> <fine>   (secondi dall'epoca)
"""
import datetime
import re
import subprocess
import sys

PREDICATO = ('(process == "vot" OR process == "MauiAUSP") AND '
             '(subsystem == "com.apple.Accessibility" OR subsystem == "com.apple.Accessibiliy.TextToSpeech")')


def eventi(udid, inizio, fine):
    formato = "%Y-%m-%d %H:%M:%S"
    a = datetime.datetime.fromtimestamp(int(inizio)).strftime(formato)
    b = datetime.datetime.fromtimestamp(int(fine) + 1).strftime(formato)
    r = subprocess.run(["xcrun", "simctl", "spawn", udid, "log", "show", "--start", a, "--end", b, "--style", "compact",
                        "--info", "--debug", "--predicate", PREDICATO], capture_output=True, text=True, timeout=180)
    fuori = []
    for riga in r.stdout.splitlines():
        m = re.match(r"^(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d{3}) +\S+ +(\S+?)\[", riga)
        if not m:
            continue
        t = datetime.datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S.%f").timestamp()
        if "[IdleTimerAssertion] acquired" in riga:
            fuori.append((t, "presa"))
        elif "[IdleTimerAssertion] released" in riga:
            fuori.append((t, "lasciata"))
        elif "AudioQueue underflow" in riga:
            fuori.append((t, "svuotata"))
    return fuori


def tratti(udid, inizio, fine):
    """I tratti di voce fra i due istanti: [{inizio, fine, modo}], con modo «intera», «troncata» o «in corso»."""
    fuori, corrente, svuotata = [], None, None
    for t, k in eventi(udid, inizio, fine):
        if k == "presa":
            if corrente:
                corrente.update(fine=t, modo="troncata")
                fuori.append(corrente)
            corrente, svuotata = dict(inizio=t), None
        elif k == "svuotata":
            svuotata = t
        elif k == "lasciata" and corrente:
            naturale = svuotata is not None and t - svuotata < 0.4
            corrente.update(fine=t, modo="intera" if naturale else "troncata")
            fuori.append(corrente)
            corrente, svuotata = None, None
    if corrente:
        corrente.update(fine=None, modo="in corso")
        fuori.append(corrente)
    return fuori


if __name__ == "__main__":
    for x in tratti(sys.argv[1], float(sys.argv[2]), float(sys.argv[3])):
        print("%.2f  %s  %s" % (x["inizio"], ("%.2f s" % (x["fine"] - x["inizio"])) if x["fine"] else "…", x["modo"]))
