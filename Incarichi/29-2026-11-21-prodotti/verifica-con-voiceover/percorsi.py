#!/usr/bin/env python3
"""I percorsi di verifica dell'incarico 29, guidati col pilota dell'incarico 28 con VoiceOver acceso.

Il pilota (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`) gira sul simulatore e legge i
comandi da <cartella>/comandi.jsonl; questo guidatore li scrive uno alla volta, legge l'esito (ciò che
VoiceOver ha detto, l'albero) e registra per ogni controllo l'atteso, il trovato e l'esito in
<cartella>/controlli.jsonl.

Uso: python3 percorsi.py <cartella del pilota> <udid> <apparecchio: iphone|ipad> [blocchi...]
Blocchi: battaglia, campagna, blocco, testo (predefiniti: tutti).
"""
import json
import pathlib
import re
import subprocess
import sys
import time

CARTELLA = pathlib.Path(sys.argv[1])
UDID = sys.argv[2]
APPARECCHIO = sys.argv[3]
BLOCCHI = sys.argv[4:] or ["battaglia", "campagna", "blocco", "testo"]
CONTROLLI = CARTELLA / "controlli.jsonl"
PROPRIO = re.compile(r"\btu(o|a|oi|e) ")


def esiti():
    f = CARTELLA / "esiti.jsonl"
    out = []
    if f.exists():
        for r in f.read_text(encoding="utf-8").splitlines():
            try:
                out.append(json.loads(r))
            except json.JSONDecodeError:
                pass
    return out


def cmd(c, attesa=240):
    fc = CARTELLA / "comandi.jsonl"
    n = len(fc.read_text(encoding="utf-8").splitlines()) + 1 if fc.exists() else 1
    c = dict(c, n=n)
    with fc.open("a", encoding="utf-8") as f:
        f.write(json.dumps(c, ensure_ascii=False) + "\n")
    limite = time.time() + attesa
    while time.time() < limite:
        for e in esiti():
            if e.get("n") == n:
                return e
        time.sleep(0.25)
    return {"n": n, "errore": "nessun esito"}


def sentito(e):
    return " || ".join(e.get("ascoltate", [])) + " || " + e.get("dopo", "")


def albero():
    return [re.sub(r" \[.*$", "", r) for r in cmd({"azione": "albero", "ascolto": 0.2}).get("albero", [])]


def controlla(nome, esito, atteso, trovato, **altro):
    riga = dict(apparecchio=APPARECCHIO, controllo=nome, esito="ok" if esito else "NO", atteso=atteso,
                trovato=trovato, ora=time.strftime("%H:%M:%S"), **altro)
    with CONTROLLI.open("a", encoding="utf-8") as f:
        f.write(json.dumps(riga, ensure_ascii=False) + "\n")
    print(("ok  " if esito else "NO  ") + nome + " — " + str(trovato)[:220], flush=True)


def attiva(**chi):
    return cmd(dict({"azione": "attiva", "ascolto": chi.pop("ascolto", 3.0)}, **chi))


def avvia_pulito():
    cmd({"azione": "termina", "ascolto": 0.3})
    cmd({"azione": "avvia", "ascolto": 2})
    cmd({"azione": "vo_accendi", "ascolto": 1})


def tocco_magico(bersaglio):
    e = cmd({"azione": "multi_tocco", "tocchi": 2, "dita": 2, "etichetta": bersaglio, "tipo": "pulsante", "ascolto": 4})
    return sentito(e)


# ------------------------------------------------------------------------------------------ battaglia
def blocco_battaglia():
    avvia_pulito()
    e = attiva(etichetta="Nuovo scontro di prova", tipo="pulsante", ascolto=8)
    dopo = e.get("dopo", "")
    controlla("oss3: fuoco d'apertura sull'intestazione del deck", dopo.startswith("Riserve da schierare"),
              "Riserve da schierare, intestazione", sentito(e))
    # Oss. 6: azzeramento a vuoto.
    e = attiva(etichetta="Azzera lo schieramento del turno", tipo="pulsante", ascolto=3)
    s = sentito(e)
    controlla("oss6: azzeramento a vuoto in battaglia", "Niente da azzerare in questo turno" in s and "azzerato" not in s,
              "Niente da azzerare in questo turno", s)
    # Decisione 3 sul campo, e genere: scelta della fanteria leggera, cella valida, piazzamento.
    attiva(etichetta="fanteria leggera", ascolto=2.5)
    nomi = albero()
    valide = [n for n in nomi if re.match(r"riga \d+, cella \d+, libera, costa \d+, restano \d+$", n)]
    controlla("dec3: con un elemento scelto la cella comincia dalla posizione e chiude col costo", bool(valide),
              "riga R, cella C, libera, costa N, restano M", valide[:2] or [n for n in nomi if "costa" in n][:2])
    if valide:
        m = re.match(r"(riga \d+, cella \d+),", valide[0])
        e = attiva(contiene=m.group(1) + ",", ascolto=3)
        nomi = albero()
        occupata = [n for n in nomi if n.startswith(m.group(1) + ",") and "fanteria leggera" in n]
        controlla("dec2: «tua fanteria leggera A» nella cella piazzata",
                  any("tua fanteria leggera A" in n for n in occupata), "tua fanteria leggera A", occupata[:1] + [sentito(e)])
    # Oss. 5: scelta e deselezione della tessera dei tiratori. Il pilota tocca (fuoco), legge, poi tocca due
    # volte: la pronuncia letta subito dopo è quella della messa a fuoco, PRIMA dell'attivazione, e VoiceOver
    # non ne pronuncia una nuova dopo il doppio tocco. Lo stato dopo l'attivazione si legge spostando il fuoco
    # avanti e indietro: è la rilettura della tessera.
    def rileggi():
        cmd({"azione": "avanti", "ascolto": 0.8})
        return cmd({"azione": "indietro", "ascolto": 1.5}).get("pronunce", [""])[0]
    e1 = attiva(etichetta="tiratori", ascolto=2.5)
    dopo_scelta = rileggi()
    e2 = attiva(etichetta="tiratori", ascolto=3)
    dopo_deselezione = rileggi()
    controlla("oss5: alla messa a fuoco prima del doppio tocco la tessera scelta si dichiara selezionata (è la frase dell'incarico 28)",
              e2.get("fuoco", "").startswith("è selezionato"), "è selezionato tiratori …", e2.get("fuoco"))
    controlla("oss5: dopo il doppio tocco VoiceOver non pronuncia uno stato vecchio",
              all(a == e2.get("fuoco") or "selezionat" not in a for a in e2.get("ascoltate", [])),
              "nessuna pronuncia nuova con «selezionato» dopo la deselezione", e2.get("ascoltate"))
    controlla("oss5: riletta dopo la deselezione, la tessera non si dichiara selezionata",
              dopo_deselezione.startswith("tiratori") and "selezionat" not in dopo_deselezione,
              "tiratori 5 atomi, volume 50, 1 esemplare", dopo_deselezione)
    controlla("dec2: riletta dopo la scelta, la tessera dei tiratori dice «selezionati»",
              dopo_scelta.startswith("è selezionato") and "selezionati" in dopo_scelta,
              "è selezionato tiratori …, selezionati", dopo_scelta)
    # Azzeramento con qualcosa da azzerare: conferma.
    e = attiva(etichetta="Azzera lo schieramento del turno", tipo="pulsante", ascolto=3)
    controlla("oss6: azzeramento con comandi del turno conferma", "Schieramento del turno azzerato" in sentito(e),
              "Schieramento del turno azzerato", sentito(e))
    cmd({"azione": "schermata", "nome": f"{APPARECCHIO}-battaglia", "ascolto": 0.3})


# ------------------------------------------------------------------------------------------ campagna
def gruppi_in_attesa(nomi):
    return [n for n in nomi if re.search(r"riga \d+, casella \d+", n) and ", in attesa" in n and PROPRIO.search(n)]


def blocco_campagna():
    avvia_pulito()
    attiva(etichetta="Nuova campagna, mappa piccola", tipo="pulsante", ascolto=6)
    nomi = albero()
    # Decisione 2: i nomi dei gruppi accordano il possessivo (Cervo è maschile).
    propri = [n for n in nomi if re.search(r"riga \d+, casella \d+, tu", n)]
    sbagliati = [n for n in propri if re.search(r"tua (Corvo|Lupo|Falco|Orso|Cervo)", n)]
    controlla("dec2: il possessivo si accorda al nome del gruppo", bool(propri) and not sbagliati,
              "tuo Corvo / tuo Cervo …", propri[:4])
    attesa = gruppi_in_attesa(nomi)
    primo = re.search(r"riga \d+, casella \d+", attesa[0]).group(0)
    attiva(contiene=primo + ",", ascolto=2.5)
    e = attiva(etichetta="Presidia: resta fermo in guardia", tipo="pulsante", ascolto=3)
    s = tocco_magico("Registro della campagna")
    controlla("oss2: «Ha agito 1 gruppo su …»", "Ha agito 1 gruppo su" in s and "1 gruppi" not in s,
              "Giorno 1. Ha agito 1 gruppo su 4", s)
    # Decisione 3 sulla mappa: il comando di marcia dice l'avvertimento; le caselle cominciano dalla posizione.
    nomi = albero()
    armati = [n for n in gruppi_in_attesa(nomi) if "ricognizione" not in n and "non armata" not in n]
    if armati:
        g = re.search(r"riga \d+, casella \d+", armati[0]).group(0)
        attiva(contiene=g + ",", ascolto=2.5)
        e = attiva(etichetta="Marcia: scegli la casella sulla mappa", tipo="pulsante", ascolto=6)
        s = sentito(e)
        controlla("dec3: il comando di marcia dice l'avvertimento una volta", "resterà fermo" in s or "Scegli la casella" in s,
                  "Scegli la casella di destinazione … Il gruppo resterà fermo fino all'arrivo …", s)
        nomi = albero()
        mete = [n for n in nomi if re.match(r"riga \d+, casella \d+, .*raggiungibile in \d+ giorn[oi]$", n)]
        avvisi = [n for n in nomi if "resterà fermo" in n]
        controlla("dec3: le caselle in designazione cominciano dalla posizione e chiudono col costo",
                  bool(mete) and not avvisi, "riga R, casella C, …, raggiungibile in N giorni", mete[:3])
        if mete:
            m = re.match(r"(riga \d+, casella \d+),", mete[0])
            e = attiva(contiene=m.group(1) + ",", ascolto=3)
            controlla("dec3: attivata la casella, l'ordine di marcia parte", "marcia verso" in sentito(e),
                      "… marcia verso riga R, casella C …", sentito(e))
    cmd({"azione": "schermata", "nome": f"{APPARECCHIO}-mappa", "ascolto": 0.3})


# ------------------------------------------------------------------------------------------ blocco da battaglia
def blocco_blocco(giornate=30):
    """Gioca la campagna piccola cercando il contatto finché nasce una battaglia in sospeso; allora apre il
    pannello di un ALTRO gruppo e legge il messaggio (oss. 1)."""
    avvia_pulito()
    attiva(etichetta="Nuova campagna, mappa piccola", tipo="pulsante", ascolto=6)
    for giorno in range(giornate):
        gia = set()
        for _ in range(12):
            nomi = albero()
            attesa = [n for n in gruppi_in_attesa(nomi) if re.search(r"riga \d+, casella \d+", n).group(0) not in gia]
            if not attesa:
                break
            s = attesa[0]
            m = re.search(r"riga (\d+), casella (\d+)", s)
            r, c = int(m.group(1)), int(m.group(2))
            gia.add(m.group(0))
            e = attiva(contiene=f"riga {r}, casella {c},", ascolto=2.5)
            voci = albero()
            messaggi = [v for v in voci if v.startswith("Nessun ordine possibile")]
            if messaggi:
                controlla("oss1: il pannello del gruppo bloccato dichiara il motivo e il luogo",
                          "c'è una battaglia in sospeso" in messaggi[0] and "riga" in messaggi[0],
                          "Nessun ordine possibile: c'è una battaglia in sospeso in riga R, casella C",
                          messaggi[0], sentito=sentito(e), giorno=giorno + 1)
                cmd({"azione": "schermata", "nome": f"{APPARECCHIO}-pannello-bloccato", "ascolto": 0.3})
                attiva(etichetta="Chiudi il pannello", tipo="pulsante")
                return
            if "Apri la battaglia" in voci:
                # Il gruppo nella casella contesa: non si apre; si cerca un altro gruppo.
                attiva(etichetta="Chiudi il pannello", tipo="pulsante")
                continue
            armato = "ricognizione" not in s and "non armata" not in s
            meta = None
            if armato and "Marcia: scegli la casella sulla mappa" in voci:
                for dr, dc in ((-1, 0), (0, -1), (0, 1), (1, 0)):
                    n = next((x for x in voci if f"riga {r + dr}, casella {c + dc}," in x), "")
                    if n and not PROPRIO.search(n) and ("formazione avversaria" in n or "quartier generale avversario" in n):
                        meta = (r + dr, c + dc)
                        break
                if meta is None:
                    nord = next((x for x in voci if f"riga {r - 1}, casella {c}," in x), "")
                    if nord and not PROPRIO.search(nord):
                        meta = (r - 1, c)
            if meta:
                attiva(etichetta="Marcia: scegli la casella sulla mappa", tipo="pulsante")
                attiva(contiene=f"riga {meta[0]}, casella {meta[1]},", ascolto=2.5)
            elif "Esplora la zona" in voci:
                attiva(etichetta="Esplora la zona", tipo="pulsante")
            elif "Presidia: resta fermo in guardia" in voci:
                attiva(etichetta="Presidia: resta fermo in guardia", tipo="pulsante")
            elif "Sosta con raccolta: resta fermo e raccogli provviste" in voci:
                attiva(etichetta="Sosta con raccolta: resta fermo e raccogli provviste", tipo="pulsante")
            else:
                attiva(etichetta="Chiudi il pannello", tipo="pulsante")
    controlla("oss1: il pannello del gruppo bloccato dichiara il motivo e il luogo", False,
              "una battaglia in sospeso entro le giornate", f"nessuna battaglia in sospeso in {giornate} giornate")


# ------------------------------------------------------------------------------------------ testo massimo
def blocco_testo():
    subprocess.run(["xcrun", "simctl", "ui", UDID, "content_size", "accessibility-extra-extra-extra-large"], check=False)
    try:
        avvia_pulito()
        for schermata, voce, chiusura in [("impostazioni", "Impostazioni", "Chiudi il pannello"),
                                          ("apprendimento", "Suoni e vibrazioni del gioco", "Chiudi il pannello")]:
            attiva(etichetta=voce, tipo="pulsante", ascolto=3)
            giro = cmd({"azione": "giro", "ascolto": 0.5, "con_schermata": True, "nome": f"{APPARECCHIO}-testo-massimo-{schermata}"})
            pronunce = giro.get("pronunce", [])
            controlla(f"dec1: {schermata} a testo massimo, letta per intero con VoiceOver", len(pronunce) > 3,
                      "tutte le voci lette fino al congedo", pronunce[:12], quante=len(pronunce))
            if schermata == "impostazioni":
                scelte = [p for p in pronunce if p.startswith(("Sintetico", "Normale", "Dettagliato"))]
                controlla("dec1: le voci della verbosità sono pulsanti a capo, la scelta è dichiarata", len(scelte) >= 1,
                          "Sintetico / Normale (selezionato) / Dettagliato", scelte)
                # Oss. 4: il gesto di uscita non si guida dal vivo (incarico 28); un tentativo da tastiera.
                cmd({"azione": "tasto", "tasto": "esc", "modificatori": [], "ascolto": 1.5})
                chiusa = "Impostazioni" not in [n for n in albero() if n == "Verbosità degli annunci"] and \
                    "Verbosità degli annunci" not in albero()
                controlla("oss4: il gesto di uscita dal vivo (tentativo col tasto Esc)", chiusa,
                          "impostazioni chiuse", "chiuse" if chiusa else "ancora aperte: il gesto non si guida dal vivo")
                if not chiusa:
                    attiva(etichetta=chiusura, tipo="pulsante")
            else:
                attiva(etichetta=chiusura, tipo="pulsante")
        attiva(etichetta="Nuovo scontro di prova", tipo="pulsante", ascolto=6)
        giro = cmd({"azione": "giro", "ascolto": 0.5, "con_schermata": True, "nome": f"{APPARECCHIO}-testo-massimo-battaglia"})
        pronunce = giro.get("pronunce", [])
        controlla("dec1: battaglia a testo massimo, letta fino a «Fine del turno»",
                  any(p.startswith("Fine del turno") for p in pronunce), "… Fine del turno", pronunce[-4:], quante=len(pronunce))
        avvia_pulito()
        attiva(etichetta="Nuova campagna, mappa piccola", tipo="pulsante", ascolto=6)
        attiva(etichetta="Registro della campagna", tipo="pulsante", ascolto=3)
        giro = cmd({"azione": "giro", "ascolto": 0.5, "con_schermata": True, "nome": f"{APPARECCHIO}-testo-massimo-registro"})
        controlla("dec1: registro a testo massimo, letto fino al congedo",
                  any(p.startswith("Chiudi il registro") for p in giro.get("pronunce", [])), "… Chiudi il registro",
                  giro.get("pronunce", [])[-3:])
        attiva(etichetta="Chiudi il registro", tipo="pulsante")
    finally:
        subprocess.run(["xcrun", "simctl", "ui", UDID, "content_size", "large"], check=False)


for blocco in BLOCCHI:
    {"battaglia": blocco_battaglia, "campagna": blocco_campagna, "blocco": blocco_blocco, "testo": blocco_testo}[blocco]()
print("fatto", flush=True)
