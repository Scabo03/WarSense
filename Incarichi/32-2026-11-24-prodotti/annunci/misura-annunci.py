#!/usr/bin/env python3
"""La misura degli annunci, prima e dopo la correzione dell'incarico 32.

Guida il pilota (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`) sul simulatore con VoiceOver acceso,
passo per passo, e per ogni annuncio che il gioco pubblica dice: quando lo pubblica e con quale priorità, quando
la voce comincia a dirlo, per quanto lo dice, se lo dice fino in fondo, e che cosa il sistema notifica alla
conclusione. Tre fonti, abbinate per istante:
  - il registro della COPIA STRUMENTATA dell'app (`Registro.swift`, applicato da `strumenta.sh` a una copia del
    codice: aggiunge soltanto righe di registro, non cambia ciò che il gioco fa, e non entra nel gioco);
  - i tratti di voce di VoiceOver, dal registro di sistema del simulatore (`voce.py`);
  - le pronunce lette dal pilota (`ascoltate`), come le misure dell'incarico 31.

Uso: misura-annunci.py <cartella del pilota> <udid> <apparecchio> <prima|dopo> <uscita.jsonl> [blocchi…]
Blocchi: regno, mappa, scontro, battaglia, conclusione.
Una riga JSON per passo: `passo`, `sposta` (vero se il passo sposta il fuoco o cambia schermata), `annunci`.
"""
import importlib.util
import json
import pathlib
import re
import subprocess
import sys
import time

QUI = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("voce", QUI / "voce.py")
voce = importlib.util.module_from_spec(spec)
spec.loader.exec_module(voce)

CARTELLA, UDID, APPARECCHIO, VERSIONE = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
USCITA = pathlib.Path(sys.argv[5])
TUTTI = ["regno", "mappa", "scontro", "battaglia", "conclusione"]
BLOCCHI = sys.argv[6:] or TUTTI
APP = "com.scabo.warsense"
BLOCCO = ""

# ------------------------------------------------------------------------------------------ il canale
_letti, _esiti, _prossimo = 0, {}, None


def _leggi():
    global _letti
    f = CARTELLA / "esiti.jsonl"
    if not f.exists():
        return
    with f.open("rb") as h:
        h.seek(_letti)
        pezzo = h.read()
    fine = pezzo.rfind(b"\n")
    if fine < 0:
        return
    for riga in pezzo[:fine].split(b"\n"):
        try:
            e = json.loads(riga.decode("utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError):
            continue
        _esiti[e.get("n")] = e
    _letti += fine + 1


def cmd(c, attesa=300):
    global _prossimo
    fc = CARTELLA / "comandi.jsonl"
    if _prossimo is None:
        _prossimo = len(fc.read_text(encoding="utf-8").splitlines()) + 1 if fc.exists() else 1
    n = _prossimo
    _prossimo += 1
    with fc.open("a", encoding="utf-8") as f:
        f.write(json.dumps(dict(c, n=n), ensure_ascii=False) + "\n")
    limite = time.time() + attesa
    while time.time() < limite:
        _leggi()
        if n in _esiti:
            return _esiti[n]
        time.sleep(0.05)
    return {"n": n, "errore": "nessun esito"}


def contenitore():
    r = subprocess.run(["xcrun", "simctl", "get_app_container", UDID, APP, "data"], capture_output=True, text=True, timeout=60)
    return pathlib.Path(r.stdout.strip()) if r.returncode == 0 else None


_cont, _riletto = None, 0


def registro(da_capo=False):
    """Le righe nuove del registro della copia strumentata: (istante, testo)."""
    global _cont, _riletto
    if _cont is None:
        _cont = contenitore()
    if _cont is None:
        return []
    f = _cont / "Documents" / "lab.log"
    if not f.exists():
        return []
    testo = f.read_text(encoding="utf-8", errors="replace")
    nuovo = testo[0 if da_capo else _riletto:]
    _riletto = len(testo)
    righe = []
    for r in nuovo.splitlines():
        m = re.match(r"^(\d+\.\d+) (.*)$", r)
        if m:
            righe.append((float(m.group(1)), m.group(2)))
        elif righe:
            righe[-1] = (righe[-1][0], righe[-1][1] + "\n" + r)
    return righe


def albero():
    return [re.sub(r" \[.*$", "", r) for r in cmd({"azione": "albero", "ascolto": 0.2}).get("albero", [])]


def etichetta_con(prefisso):
    return next((n for n in albero() if n.startswith(prefisso)), None)


# ------------------------------------------------------------------------------------------ la misura
def abbina(pubblicati, tratti):
    """A ciascun annuncio pubblicato il tratto di voce che gli corrisponde. Il sistema notifica all'app quando
    VoiceOver ha concluso un annuncio: il tratto è il primo che finisce in quell'istante (entro quattro decimi),
    anche se è durato zero — l'annuncio sostituito prima di cominciare. Senza la notifica, il primo tratto non
    ancora assegnato che comincia dopo la pubblicazione. `pubblicati` porta (istante, testo, priorità, istante
    della conclusione o None)."""
    fuori, presi = [], set()
    for t, _, _, c in pubblicati:
        scelta = None
        if c is not None:
            candidati = [(x["inizio"], i) for i, x in enumerate(tratti)
                         if i not in presi and x["fine"] and x["inizio"] >= t - 0.12 and abs(x["fine"] - c) <= 0.4]
            if candidati:
                scelta = min(candidati)[1]
        if scelta is None and c is None:
            scelta = next((i for i, x in enumerate(tratti) if i not in presi and x["inizio"] >= t - 0.12), None)
        if scelta is not None:
            presi.add(scelta)
        fuori.append(tratti[scelta] if scelta is not None else None)
    return fuori


def quiete(limite=60):
    """Attende che la coda degli annunci sia vuota: ogni annuncio pubblicato è stato concluso, e da un secondo e
    mezzo non ne esce un altro. Senza, un passo misurerebbe gli annunci del precedente."""
    fine = time.time() + limite
    while time.time() < fine:
        pubblicati, conclusi, ultimo = 0, 0, 0.0
        for istante, riga in registro(da_capo=True):
            if riga.startswith("AVVIO"):
                pubblicati, conclusi = 0, 0
            elif riga.startswith("PUBBLICA"):
                pubblicati += 1
                ultimo = istante
            elif riga.startswith("CONCLUSO"):
                conclusi += 1
                ultimo = istante
        if conclusi >= pubblicati and time.time() - ultimo > 1.5:
            return
        time.sleep(0.5)


def misura(passo, comandi, sposta, nota=None):
    """Esegue i comandi e misura gli annunci che il gioco pubblica dopo l'ULTIMO. I precedenti preparano."""
    for c in comandi[:-1]:
        cmd(c)
    quiete()
    registro()
    prima = time.time()
    e = cmd(comandi[-1])
    time.sleep(0.4)
    fine = time.time()
    time.sleep(1.2)  # il registro di sistema arriva con un istante di ritardo
    righe = registro()
    pubblicati, conclusi, fuochi = [], [], []
    for t, r in righe:
        m = re.match(r"^PUBBLICA (\S+) \((\d+)\) «(.*)»$", r, re.S)
        if m:
            pubblicati.append((t, m.group(3), m.group(1)))
            continue
        m = re.match(r"^CONCLUSO riuscito=(\S+) «(.*)»$", r, re.S)
        if m:
            conclusi.append((t, m.group(2), m.group(1)))
            continue
        m = re.match(r"^FUOCO «(.*)»$", r, re.S)
        if m:
            fuochi.append([round(t - prima, 2), m.group(1)])
    tr = voce.tratti(UDID, prima - 1, fine + 1)
    fine_di = lambda t, testo: next((c for c in conclusi if c[1] == testo and c[0] >= t), None)
    assegnati = abbina([(t, testo, pr, (fine_di(t, testo) or [None])[0]) for t, testo, pr in pubblicati], tr)
    annunci = []
    for (t, testo, priorita), x in zip(pubblicati, assegnati):
        caratteri = len(testo)
        durata = round(x["fine"] - x["inizio"], 2) if x and x["fine"] else None
        concluso = fine_di(t, testo)
        # Detto per intero: la voce finisce da sé, e dura almeno i sei decimi di ciò che serve alla velocità
        # misurata nell'incarico 31 (17,5 caratteri al secondo) — il minimo che esclude uno svuotamento.
        intero = bool(x and x["modo"] == "intera" and durata is not None and durata >= 0.6 * caratteri / 17.5)
        annunci.append({
            "testo": testo, "caratteri": caratteri, "priorita": priorita, "pubblicato_a": round(t - prima, 2),
            "voce_comincia_dopo": round(x["inizio"] - t, 2) if x else None,
            "voce_durata": durata, "voce_modo": x["modo"] if x else "nessuna voce", "detto_per_intero": intero,
            "concluso_dopo": round(concluso[0] - t, 2) if concluso else None,
            "concluso_riuscito": concluso[2] if concluso else None})
    riga = {"apparecchio": APPARECCHIO, "versione": VERSIONE, "blocco": BLOCCO, "passo": passo, "sposta": sposta,
            "annunci": annunci, "fuochi": fuochi, "pronunce": e.get("ascoltate"), "istanti": e.get("ascoltate_t"),
            "tratti": [[round(x["inizio"] - prima, 2), round(x["fine"] - x["inizio"], 2) if x["fine"] else None, x["modo"]] for x in tr if x["inizio"] >= prima - 0.2],
            "errore": e.get("errore"), "nota": nota, "ora": time.strftime("%H:%M:%S")}
    with USCITA.open("a", encoding="utf-8") as f:
        f.write(json.dumps(riga, ensure_ascii=False) + "\n")
    print(f"{BLOCCO} · {passo}" + (f" — ERRORE {e.get('errore')}" if e.get("errore") else ""), flush=True)
    for a in annunci:
        print("     %-9s %6s s %-9s %-5s «%s» (%d)" % (a["priorita"], a["voce_durata"], a["voce_modo"],
              "INTERO" if a["detto_per_intero"] else "no", a["testo"][:70].replace("\n", " "), a["caratteri"]), flush=True)
    return riga


def att(ascolto=6.0, **chi):
    return dict({"azione": "attiva", "ascolto": ascolto}, **chi)


def puls(nome, ascolto=6.0):
    return att(ascolto, etichetta=nome, tipo="pulsante")


def avvia(argomenti=None):
    cmd({"azione": "termina", "ascolto": 0.3})
    cmd({"azione": "avvia", "ascolto": 2.0})
    cmd({"azione": "vo_accendi", "ascolto": 1.0})
    global _cont
    _cont = None
    registro()


def valori_di_fabbrica():
    """I valori della copia in Documenti tornano quelli di fabbrica: tolto il manifest, l'app li ricopia all'avvio
    (00 §15.4). Serve a un blocco che segue uno che li ha messi a punto."""
    global _cont
    cmd({"azione": "termina", "ascolto": 0.3})
    _cont = contenitore()
    if _cont:
        (_cont / "Documents" / "Valori" / "manifest.json").unlink(missing_ok=True)


def caselle_proprie():
    """Le caselle coi propri gruppi: nome -> prefisso dell'etichetta («riga 4, casella 3»)."""
    fuori = {}
    for n in albero():
        m = re.match(r"^(riga \d+, casella \d+), tu(?:o|a|oi|e) (\w+), (.*)$", n)
        if m:
            fuori[m.group(2)] = m.group(1)
    return fuori


# ------------------------------------------------------------------------------------------ i blocchi
def blocco_regno():
    valori_di_fabbrica()
    avvia()
    cmd(puls("Nuovo regno", 4))
    misura("resta in patria (riga attivata)", [att(6, prefisso="Corvo,", tipo="pulsante")], False)
    misura("torna al fronte (riga attivata)", [att(6, prefisso="Corvo,", tipo="pulsante")], False)
    misura("comincia l'inverno", [puls("Attendi l'inverno", 22)], True)
    misura("leva ordinata", [att(7, prefisso="Leva di fanteria leggera", tipo="pulsante")], False)
    misura("spesa annullata", [puls("Annulla l'ultima spesa", 6)], False)
    misura("addestramento ordinato dalla scelta del reparto", [att(4, prefisso="Addestramento mirato.", tipo="pulsante"),
                                                              att(16, prefisso="Lupo: 8 atomi", tipo="pulsante")], True)
    misura("scelta impedita rifiutata", [att(4, prefisso="Addestramento mirato.", tipo="pulsante"),
                                         att(13, prefisso="Falco: 24 atomi", tipo="pulsante")], True)
    for k in (2, 3, 4):
        cmd(puls(f"Prosegui alla schermata {k} di 4", 2.5))
    misura("comincia la primavera", [puls("Prosegui alla primavera", 30)], True)
    misura("apertura della campagna dal regno", [puls("Apri la campagna", 3), puls("fronte del guado, mappa 4 per 4", 30)], True)


def blocco_mappa():
    """Sulla campagna aperta dal regno nel blocco precedente, oppure su una nuova."""
    if "Chiudi la giornata" not in albero():
        valori_di_fabbrica()
        avvia()
        cmd(puls("Nuovo regno", 4))
        cmd(puls("Apri la campagna", 3))
        cmd(puls("fronte del guado, mappa 4 per 4", 12))
    misura("torna in patria", [puls("Torna in patria", 4)], True)
    misura("entra nel fronte", [att(24, prefisso="Entra nel fronte", tipo="pulsante")], True)
    c = caselle_proprie()
    misura("marcia: destinazione da scegliere", [att(3, prefisso=c.get("Lupo", "riga 4, casella 3")), puls("Marcia: scegli la casella sulla mappa", 20)], True)
    libera = next((n for n in albero() if "raggiungibile in" in n), None)
    if libera:
        misura("marcia ordinata sulla casella", [att(9, prefisso=re.match(r"^riga \d+, casella \d+", libera).group(0))], False)
    c = caselle_proprie()
    misura("marcia revocata", [att(3, prefisso=c.get("Lupo", "riga 4, casella 3")), puls("Revoca la marcia", 3), puls("Conferma la revoca", 14)], True)
    misura("presidio ordinato", [att(3, prefisso=c.get("Corvo", "riga 4, casella 2")), puls("Presidia: resta fermo in guardia", 14)], True)
    misura("divisione incompleta rifiutata", [att(3, prefisso=c.get("Falco", "riga 4, casella 4")), puls("Dividi: scegli i reparti da staccare", 3),
                                              att(6, prefisso="Colloca in riga", tipo="pulsante")], False)
    misura("divisione compiuta", [att(1.5, contiene="fanteria pesante", tipo="pulsante"), att(18, prefisso="Colloca in riga", tipo="pulsante")], True)
    c = caselle_proprie()
    altro = next((n for n in albero() if n.startswith("Riunisci")), None)
    if "Falco" in c:
        cmd(att(3, prefisso=c["Falco"]))
        altro = etichetta_con("Riunisci")
        if altro:
            misura("riunione compiuta", [puls(altro, 16)], True)
        else:
            cmd(puls("Chiudi il pannello", 2))
    misura("esplorazione compiuta", [att(3, prefisso=c.get("Orso", "riga 4, casella 1")), puls("Esplora la zona", 14)], True)
    misura("ultimo ordine annullato", [puls("Annulla l'ultima operazione", 6)], False)
    misura("giornata chiusa dal comando", [puls("Chiudi la giornata", 20)], False)
    misura("tocco magico sulla mappa", [{"azione": "multi_tocco", "tocchi": 2, "dita": 2, "etichetta": "Registro della campagna", "tipo": "pulsante", "ascolto": 14}], False)


def blocco_scontro():
    valori_di_fabbrica()
    avvia()
    misura("apertura dello scontro", [puls("Nuovo scontro di prova", 22)], True)
    misura("elemento del deck selezionato", [att(3, prefisso="fanteria leggera")], False)
    misura("piazzamento confermato", [att(8, prefisso="riga 10, cella 4")], False)
    misura("turno chiuso, il turno dell'avversario", [puls("Fine del turno", 40)], False)
    cmd(att(2, prefisso="fanteria leggera"))  # l'elemento del mazzo resta selezionato: lo si deseleziona
    misura("movimento: destinazione da scegliere", [att(3, prefisso="riga 10, cella 4"), puls("Scegli la destinazione sulla griglia", 14)], True)
    misura("movimento compiuto sulla cella", [att(8, prefisso="riga 9, cella 4")], False)
    for _ in range(3):
        cmd(puls("Fine del turno", 6))
        quiete()
        if "Resoconto della battaglia" in albero():
            break
    misura("resa dichiarata", [puls("Dichiara la resa", 10)], False)
    for _ in range(6):
        nomi = albero()
        if "Resoconto della battaglia" in nomi:
            break
        mio = next((n for n in nomi if re.match(r"^riga \d+, cella \d+, tu(o|a|oi|e) ", n)), None)
        if not mio:
            break
        prefisso = re.match(r"^riga \d+, cella \d+", mio).group(0)
        cmd(att(3, prefisso=prefisso))
        evacua = etichetta_con("Evacua questa unità")
        if evacua:
            r = misura("evacuazione che conclude lo scontro", [puls(evacua, 22)], True)
            if "Resoconto della battaglia" in albero():
                break
        else:
            cmd(puls("Chiudi il pannello", 2))
            misura("turno chiuso in ritirata", [puls("Fine del turno", 25)], False)


def prepara_i_documenti(scenari=None, regno=None):
    """I valori messi a punto nei Documenti dell'app (00 §15.4), come farebbe chi tara dall'iPad: un nemico a
    contatto, un anno corto. Si scrivono ad app terminata; il manifest non cambia, sicché la copia resta."""
    global _cont
    cmd({"azione": "termina", "ascolto": 0.3})
    _cont = contenitore()
    valori = _cont / "Documents" / "Valori"
    if scenari:
        f = valori / "scenari-campagna.json"
        d = json.loads(f.read_text(encoding="utf-8"))
        scenari(d)
        f.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")
    if regno:
        f = valori / "regno.json"
        d = json.loads(f.read_text(encoding="utf-8"))
        regno(d)
        f.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")


def blocco_battaglia():
    """Una battaglia nata dalla campagna: il nemico accanto, un solo gruppo armato per parte."""
    def vicino(d):
        s = d["campagna_piccola"]
        # Il nemico sta sul proprio quartier generale, minacciato da vicino: la sua condotta lo tiene lì.
        s["gruppi_giocatore"] = [{"riga": 2, "colonna": 2, "composizione": [{"archetipo": "fanteria_leggera", "atomi": 6}]},
                                 {"riga": 4, "colonna": 4, "composizione": [{"archetipo": "fanteria_leggera", "atomi": 3}], "categoria": "ricognizione", "competenza": 5}]
        s["gruppi_avversario"] = [{"riga": 1, "colonna": 2, "composizione": [{"archetipo": "fanteria_leggera", "atomi": 3}]}]
    valori_di_fabbrica()
    avvia()
    prepara_i_documenti(scenari=vicino)
    avvia()
    cmd(puls("Nuova campagna, mappa piccola", 14))
    cmd(att(3, prefisso="riga 2, casella 2"))
    cmd(puls("Marcia: scegli la casella sulla mappa", 4))
    misura("marcia verso il nemico ordinata", [att(9, prefisso="riga 1, casella 2")], False)
    for k in range(6):
        r = misura("giornata chiusa, la battaglia che nasce" if k == 0 else f"giornata chiusa ({k + 1})", [puls("Chiudi la giornata", 22)], False)
        if any("Battaglia in sospeso" in a["testo"] for a in r["annunci"]):
            break
    c = caselle_proprie()
    dove = next((p for n, p in c.items() if n != "Orso" and etichetta_con(p)), "riga 1, casella 2")
    cmd(att(3, prefisso=dove))
    misura("la battaglia aperta dalla casella", [puls("Apri la battaglia", 26)], True)
    cmd(att(3, prefisso="fanteria leggera"))
    cmd(att(5, prefisso="riga 10, cella 5"))
    for _ in range(14):
        nomi = albero()
        if "Resoconto della battaglia" in nomi:
            break
        if "Dichiara la resa" in nomi:
            cmd(puls("Dichiara la resa", 4))
            mio = next((n for n in albero() if re.match(r"^riga \d+, cella \d+, tu(o|a|oi|e) ", n)), None)
            if mio:
                cmd(att(3, prefisso=re.match(r"^riga \d+, cella \d+", mio).group(0)))
                evacua = etichetta_con("Evacua questa unità")
                if evacua:
                    misura("evacuazione che conclude la battaglia", [puls(evacua, 22)], True)
                    continue
                if etichetta_con("Chiudi il pannello"):
                    cmd(puls("Chiudi il pannello", 2))
        cmd(puls("Fine del turno", 8))
    nomi = albero()
    congedo = next((n for n in ("Torna sulla mappa", "Torna alla mappa", "Torna all'inizio") if n in nomi), None)
    if congedo and "Resoconto della battaglia" in nomi:
        r = misura("ritorno sulla mappa dopo la battaglia", [puls(congedo, 26)], True)
        if "Scegli dove ripiegare" in albero():
            voce_r = etichetta_con("In riga")
            misura("ripiegamento scelto", [puls(voce_r, 26)], True)


def blocco_conclusione():
    """La campagna del regno che si conclude con l'inverno: un anno di tre giornate."""
    valori_di_fabbrica()
    avvia()
    prepara_i_documenti(regno=lambda d: d.update(giornate_per_stagione=1))
    avvia()
    cmd(puls("Nuovo regno", 4))
    cmd(puls("Apri la campagna", 3))
    cmd(puls("fronte del guado, mappa 4 per 4", 14))
    for k in range(8):
        r = misura("giornata chiusa (cambio di stagione)" if k == 0 else f"giornata chiusa ({k + 1})", [puls("Chiudi la giornata", 22)], k >= 2)
        if any("conclus" in a["testo"] and "campagna" in a["testo"].lower() for a in r["annunci"]) or etichetta_con("Conclusione della campagna"):
            break


BLOCCHI_NOTI = dict(regno=blocco_regno, mappa=blocco_mappa, scontro=blocco_scontro, battaglia=blocco_battaglia, conclusione=blocco_conclusione)
USCITA.parent.mkdir(parents=True, exist_ok=True)
for b in BLOCCHI:
    BLOCCO = b
    t0 = time.time()
    try:
        BLOCCHI_NOTI[b]()
    except Exception as errore:  # un blocco caduto non ferma gli altri: si dichiara
        print(f"BLOCCO {b} CADUTO: {errore!r}", flush=True)
        with USCITA.open("a", encoding="utf-8") as f:
            f.write(json.dumps({"apparecchio": APPARECCHIO, "versione": VERSIONE, "blocco": b, "passo": "BLOCCO CADUTO", "errore": repr(errore), "annunci": []}, ensure_ascii=False) + "\n")
    print(f"== blocco {b}: {time.time() - t0:.0f} s", flush=True)
print("FINITO", flush=True)
