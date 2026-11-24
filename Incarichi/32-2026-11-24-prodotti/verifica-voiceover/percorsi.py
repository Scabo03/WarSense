#!/usr/bin/env python3
"""I percorsi a controlli dell'incarico 32, con VoiceOver acceso, attraverso il pilota (SessioneInterattivaTest).

Ogni percorso gioca l'interfaccia come chi ascolta — un comando alla volta, le pronunce intere di VoiceOver — e su ciò
che sente e trova fa i propri controlli, ciascuno con il proprio esito in una riga del diario. I percorsi che vogliono
le formazioni in un punto preciso mettono a punto gli scenari nella cartella Documenti dell'app, come farebbe chi tara
dall'iPad (00 §15.4): nessun canale esiste per il solo collaudo.

Uso: percorsi.py <cartella del pilota> <udid> <iphone|ipad> <uscita.jsonl> [percorsi…]
Percorsi: reclute rifiuto presa subita richiamo battaglia.
"""
import json
import pathlib
import re
import subprocess
import sys
import time

CARTELLA, UDID, APPARECCHIO = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
USCITA = pathlib.Path(sys.argv[4])
APP = "com.scabo.warsense"
TUTTI = ["reclute", "rifiuto", "presa", "subita", "richiamo", "battaglia"]
PERCORSO = ""
conto = {"si": 0, "no": 0}
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


def scrivi(tipo, **dati):
    with USCITA.open("a", encoding="utf-8") as f:
        f.write(json.dumps(dict(apparecchio=APPARECCHIO, percorso=PERCORSO, tipo=tipo, ora=time.strftime("%H:%M:%S"), **dati),
                           ensure_ascii=False) + "\n")


def controlla(che_cosa, esito, **dati):
    conto["si" if esito else "no"] += 1
    scrivi("controllo", che_cosa=che_cosa, esito=bool(esito), **dati)
    print(("  si  " if esito else "  NO  ") + che_cosa + ("" if esito else "   " + json.dumps(dati, ensure_ascii=False)[:400]), flush=True)


def albero():
    return [re.sub(r" \[.*$", "", r) for r in cmd({"azione": "albero", "ascolto": 0.2}).get("albero", [])]


def sentito(e):
    piene = [x.get("testo", "") for x in e.get("intere", []) if x.get("testo")]
    return piene + e.get("ascoltate", [])


def attiva(ascolto=5, **chi):
    e = cmd(dict({"azione": "attiva", "ascolto": ascolto, "intere": "ogni"}, **chi))
    scrivi("attiva", chi=chi, sentito=sentito(e), pronunce=e.get("ascoltate"), fuoco=e.get("dopo"), errore=e.get("errore"))
    return e


def puls(nome, ascolto=5):
    return attiva(ascolto, etichetta=nome, tipo="pulsante")


def detto(e, frase):
    """Vero se una pronuncia comincia come la frase: il servizio VoiceOver può troncare a 64 caratteri."""
    return any(p.startswith(frase[:60]) or frase in p for p in sentito(e))


def avvia():
    cmd({"azione": "termina", "ascolto": 0.3})
    cmd({"azione": "avvia", "ascolto": 2.5})
    cmd({"azione": "vo_accendi", "ascolto": 1.5})


def contenitore():
    r = subprocess.run(["xcrun", "simctl", "get_app_container", UDID, APP, "data"], capture_output=True, text=True, timeout=60)
    return pathlib.Path(r.stdout.strip()) if r.returncode == 0 else None


def valori_di_fabbrica():
    cmd({"azione": "termina", "ascolto": 0.3})
    c = contenitore()
    if c:
        (c / "Documents" / "Valori" / "manifest.json").unlink(missing_ok=True)


def sul_guado(giocatore, avversario):
    """Le formazioni dove il percorso le vuole sulla mappa del guado, un regno nuovo e la sua campagna aperta."""
    valori_di_fabbrica()
    avvia()
    cmd({"azione": "termina", "ascolto": 0.3})
    f = contenitore() / "Documents" / "Valori" / "scenari-campagna.json"
    d = json.loads(f.read_text(encoding="utf-8"))

    def reparto(atomi):
        return [{"archetipo": "fanteria_leggera", "atomi": atomi}]
    s = d["campagna_piccola"]
    s["gruppi_giocatore"] = [{"riga": r, "colonna": c, "composizione": reparto(6)} for r, c in giocatore]
    s["gruppi_avversario"] = [{"riga": r, "colonna": c, "composizione": reparto(6)} for r, c in avversario]
    f.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")
    avvia()
    puls("Nuovo regno", 4)
    puls("Apri la campagna", 3)
    return puls("fronte del guado, mappa 4 per 4", 22)


def etichetta_di(riga, casella):
    return next((n for n in albero() if n.startswith(f"riga {riga}, casella {casella},")), "")


def stato():
    e = cmd({"azione": "multi_tocco", "tocchi": 2, "dita": 2, "etichetta": "Registro della campagna", "tipo": "pulsante",
             "ascolto": 24, "quiete": 4, "intere": "ogni"})
    scrivi("tocco_magico", sentito=sentito(e), errore=e.get("errore"))
    return e


def chiudi_giornata(ascolto=34):
    e = cmd({"azione": "attiva", "etichetta": "Chiudi la giornata", "tipo": "pulsante", "ascolto": ascolto, "quiete": 5, "intere": "ogni"})
    scrivi("giornata_chiusa", sentito=sentito(e), pronunce=e.get("ascoltate"), errore=e.get("errore"))
    return e


# ------------------------------------------------------------------------------------------ i percorsi
def reclute():
    """S29q (b) e (d): le reclute entrano lontano dal nemico, l'annuncio e la patria dicono la casella vera."""
    valori_di_fabbrica()
    avvia()
    puls("Nuovo regno", 4)
    puls("Attendi l'inverno", 20)
    attiva(6, prefisso="Leva di fanteria leggera", tipo="pulsante")
    for k in (2, 3, 4):
        puls(f"Prosegui alla schermata {k} di 4", 3)
    e = puls("Prosegui alla primavera", 30)
    controlla("la primavera annuncia che cosa entra", detto(e, "Comincia la primavera dell'anno 2"), sentito=sentito(e))
    righe = [n for n in albero() if "reclute dell'inverno" in n]
    controlla("in patria la riga delle reclute dice dove entrano", any("quartier generale o nella casella libera più vicina" in r for r in righe), righe=righe)
    puls("Apri la campagna", 3)
    e = puls("fronte del guado, mappa 4 per 4", 40)
    arrivo = next((m for p in sentito(e) for m in [re.search(r"(\w+) è arrivat[oa] dalla patria in riga (\d+), casella (\d+)", p)] if m), None)
    controlla("all'apertura si annuncia l'arrivo con la casella", arrivo is not None, sentito=sentito(e))
    if arrivo:
        nome, r, c = arrivo.group(1), arrivo.group(2), arrivo.group(3)
        controlla("la casella annunciata è quella della mappa", nome in etichetta_di(r, c), etichetta=etichetta_di(r, c))
        controlla("la casella è la più lontana dal quartier generale avversario fra le più vicine al proprio: riga 3, casella 1",
                  (r, c) == ("3", "1"), casella=(r, c))
        e = puls("Torna in patria", 6)
        riga = next((n for n in albero() if n.startswith(nome + ",")), "")
        controlla("in patria la riga dice la casella vera, e non parla al futuro", riga.endswith(f"Sul fronte, in riga {r}, casella {c}"), riga=riga)
        altre = [n for n in albero() if re.match(r"^\w+, (gruppo armato|formazione)", n)]
        controlla("ogni formazione dice dov'è sul fronte", all("Sul fronte, in riga" in n for n in altre), righe=altre)
        registro = puls("Registro della patria", 4)
        scrivi("registro_della_patria", voci=albero()[:14], sentito=sentito(registro))


def rifiuto():
    """S29q (c): senza un gruppo armato la scelta del fronte non si apre, e il motivo si sente subito."""
    valori_di_fabbrica()
    avvia()
    puls("Nuovo regno", 4)
    for nome in ("Corvo", "Lupo", "Falco"):
        attiva(4, prefisso=nome + ",", tipo="pulsante")
    e = puls("Apri la campagna", 8)
    nomi = albero()
    controlla("la scelta del fronte non si apre", "Su quale fronte?" not in nomi, albero=nomi[:20])
    controlla("si sente subito perché", any("gruppo armato" in p for p in sentito(e)), sentito=sentito(e))
    controlla("il fuoco resta sul comando", (e.get("dopo") or "").startswith("Apri la campagna") or "gruppo armato" in (e.get("dopo") or ""), fuoco=e.get("dopo"))
    attiva(4, prefisso="Corvo,", tipo="pulsante")
    puls("Apri la campagna", 4)
    controlla("con un gruppo armato la scelta si apre", "Su quale fronte?" in albero())


def presa():
    """Il giocatore occupa, tiene, prende: ogni passo si sente, sulla casella, nello stato, nella dichiarazione e in patria."""
    sul_guado([(1, 2), (4, 1), (3, 1), (2, 1), (1, 1)], [(4, 4)])
    attesi = ["Occupi il quartier generale avversario, in riga 1, casella 2: se lo tieni sarà preso fra 3 giornate",
              "Tieni il quartier generale avversario: sarà preso fra 2 giornate",
              "Tieni il quartier generale avversario: sarà preso fra 1 giornata"]
    for k, atteso in enumerate(attesi):
        e = chiudi_giornata()
        controlla("si sente «%s»" % atteso, detto(e, atteso), sentito=sentito(e))
        giornate = "1 giornata" if k == 2 else f"{3 - k} giornate"
        controlla(f"la casella dice «occupato, sarà preso fra {giornate}»", f"quartier generale avversario, occupato, sarà preso fra {giornate}" in etichetta_di(1, 2),
                  etichetta=etichetta_di(1, 2))
    s = stato()
    controlla("lo stato lo dice in coda", any(p.rstrip(".").endswith("Occupi il quartier generale avversario, sarà preso fra 1 giornata") for p in sentito(s)), sentito=sentito(s))
    e = chiudi_giornata()
    controlla("si sente che è caduto e che si è vinto", detto(e, "Campagna conclusa: il quartier generale avversario è caduto. Hai vinto"), sentito=sentito(e))
    nomi = albero()
    controlla("la dichiarazione di conclusione lo dice", any(n.startswith("Vittoria: il quartier generale avversario sul fronte del guado è caduto") for n in nomi), nomi=nomi[:10])
    cmd({"azione": "schermata", "nome": f"presa-dichiarazione-{APPARECCHIO}", "ascolto": 0.3})
    puls("Torna in patria", 6)
    controlla("la patria dice che la campagna è vinta", any(n == "Campagna sul fronte del guado vinta" for n in albero()), nomi=albero()[:12])


def subita():
    """L'avversario prende il quartier generale del giocatore, che è lontano e non lo osserva: il giocatore lo sa sempre."""
    sul_guado([(1, 4), (2, 4), (1, 3), (2, 3), (1, 1)], [(4, 2)])
    e = chiudi_giornata()
    controlla("si sente che il proprio quartier generale è occupato",
              detto(e, "L'avversario occupa il tuo quartier generale, in riga 4, casella 2: se non lo scacci sarà preso fra 3 giornate"), sentito=sentito(e))
    controlla("la casella lo dice, con la formazione avversaria e senza «inesplorato»",
              "formazione avversaria" in etichetta_di(4, 2) and "tuo quartier generale, occupato, sarà preso fra 3 giornate" in etichetta_di(4, 2)
              and "inesplorato" not in etichetta_di(4, 2), etichetta=etichetta_di(4, 2))
    puls("Registro della campagna", 4)
    nomi = albero()
    controlla("è nel registro col giorno e col luogo", any("l'avversario occupa il tuo quartier generale in riga 4, casella 2" in n for n in nomi), nomi=nomi[:8])
    attiva(4, contiene="l'avversario occupa il tuo quartier generale")
    controlla("attivata la voce del registro si torna sulla mappa, sulla casella", "Chiudi la giornata" in albero())
    s = stato()
    controlla("lo stato lo dice in coda", any("Il tuo quartier generale è occupato, sarà preso fra 3 giornate" in p for p in sentito(s)), sentito=sentito(s))
    for giornate in ("2 giornate", "1 giornata"):
        e = chiudi_giornata()
        controlla(f"si sente che mancano {giornate}", detto(e, f"Il tuo quartier generale è ancora occupato: sarà preso fra {giornate}"), sentito=sentito(e))
    e = chiudi_giornata()
    controlla("si sente che è caduto e che si è perso", detto(e, "Campagna conclusa: il tuo quartier generale è caduto. Hai perso"), sentito=sentito(e))
    nomi = albero()
    controlla("la dichiarazione lo dice, e i superstiti rientrano tutti",
              any(n.startswith("Sconfitta: il tuo quartier generale sul fronte del guado è caduto") for n in nomi)
              and any(n == "Rientrano in patria: 5 formazioni" for n in nomi), nomi=nomi[:10])
    puls("Torna in patria", 6)
    controlla("la patria dice che la campagna è perduta", any(n == "Campagna sul fronte del guado perduta" for n in albero()), nomi=albero()[:12])


def richiamo():
    """Il richiamo impedito, col suo perché, la rinuncia, e il richiamo compiuto."""
    sul_guado([(2, 2), (4, 4), (4, 1), (3, 4), (1, 4)], [(3, 2)])
    comando = next((n for n in albero() if n.startswith("Richiama l'esercito in patria")), "")
    controlla("l'etichetta dice perché non si può, chi e dove",
              comando == "Richiama l'esercito in patria, adesso non si può: Corvo ha il rifornimento tagliato in riga 2, casella 2", etichetta=comando)
    e = attiva(9, prefisso="Richiama l'esercito in patria")
    controlla("attivato, ripete il perché", detto(e, "L'esercito non si può richiamare: Corvo ha il rifornimento tagliato in riga 2, casella 2"), sentito=sentito(e))
    controlla("e non apre nulla", "Conferma il richiamo" not in albero())
    sul_guado([(4, 2), (4, 3), (4, 4), (4, 1), (3, 1)], [(1, 2)])
    e = attiva(12, prefisso="Richiama l'esercito in patria")
    controlla("quando si può chiede conferma e dice la conseguenza",
              "Richiamare l'esercito in patria?" in albero() and any(n.startswith("La campagna si conclude e conta come perduta") for n in albero()), sentito=sentito(e))
    e = puls("Rinuncia", 5)
    controlla("la rinuncia lascia la campagna aperta e riporta il fuoco sul comando",
              "Chiudi la giornata" in albero() and (e.get("dopo") or "").startswith("Richiama l'esercito in patria"), fuoco=e.get("dopo"))
    attiva(5, prefisso="Richiama l'esercito in patria")
    e = puls("Conferma il richiamo", 18)
    controlla("si sente che la campagna è conclusa e conta come perduta",
              detto(e, "Campagna conclusa: hai richiamato l'esercito in patria. Conta come perduta"), sentito=sentito(e))
    nomi = albero()
    controlla("la dichiarazione lo dice, e rientrano tutti",
              any(n.startswith("Hai richiamato l'esercito dal fronte del guado") for n in nomi) and any(n == "Rientrano in patria: 5 formazioni" for n in nomi), nomi=nomi[:10])
    cmd({"azione": "schermata", "nome": f"richiamo-dichiarazione-{APPARECCHIO}", "ascolto": 0.3})
    puls("Torna in patria", 6)
    controlla("la patria lo dice", any(n == "Campagna sul fronte del guado perduta: esercito richiamato in patria" for n in albero()), nomi=albero()[:12])


def posto(etichetta):
    m = re.match(r"^riga (\d+), cella (\d+)", etichetta)
    return (int(m.group(1)), int(m.group(2))) if m else None


def vicino_al_nemico(mio):
    """Vero se un reparto avversario è a due celle o meno: si aspetta che venga a contatto, e al turno dopo il pannello
    offre l'ingaggio. Avanzando ancora, ingaggerebbe lui."""
    io = posto(mio)
    nemici = [posto(n) for n in albero() if re.match(r"^riga \d+, cella \d+, .*avversari[ao]", n)]
    return any(abs(n[0] - io[0]) + max(0, abs(n[1] - io[1]) - abs(n[0] - io[0]) // 2) <= 2 for n in nemici if n)


def battaglia():
    """Una battaglia della campagna: il fuoco in testa all'apertura, la virgola nelle azioni d'ingaggio, il congedo che dice
    dove porta, il ritorno sulla mappa."""
    valori_di_fabbrica()
    avvia()
    cmd({"azione": "termina", "ascolto": 0.3})
    f = contenitore() / "Documents" / "Valori" / "scenari-campagna.json"
    d = json.loads(f.read_text(encoding="utf-8"))
    s = d["campagna_piccola"]
    s["gruppi_giocatore"] = [{"riga": 2, "colonna": 2, "composizione": [{"archetipo": "fanteria_leggera", "atomi": 12}]},
                             {"riga": 4, "colonna": 4, "composizione": [{"archetipo": "fanteria_leggera", "atomi": 3}], "categoria": "ricognizione", "competenza": 5}]
    s["gruppi_avversario"] = [{"riga": 1, "colonna": 2, "composizione": [{"archetipo": "fanteria_leggera", "atomi": 3}]}]
    f.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")
    avvia()
    puls("Nuova campagna, mappa piccola", 14)
    attiva(3, prefisso="riga 2, casella 2")
    puls("Marcia: scegli la casella sulla mappa", 4)
    attiva(6, prefisso="riga 1, casella 2")
    for _ in range(6):
        e = chiudi_giornata(24)
        if any("attaglia in sospeso" in p for p in sentito(e)):
            break
    mio = next((n for n in albero() if re.match(r"^riga \d+, casella \d+, tu(o|a) \w+, (?!formazione)", n)), "")
    attiva(3, prefisso=re.match(r"^riga \d+, casella \d+", mio).group(0))
    e = puls("Apri la battaglia", 12)
    controlla("all'apertura il fuoco va sull'intestazione del deck", any(p.startswith("Riserve da schierare") for p in e.get("ascoltate", [])), pronunce=e.get("ascoltate"))
    ingaggi, frasi = [], []
    for turno in range(16):
        nomi = albero()
        if "Resoconto della battaglia" in nomi:
            break
        tessera = next((n for n in cmd({"azione": "albero", "ascolto": 0.2}).get("albero", []) if "esemplar" in n and "=" in n and "0 esemplari" not in n), None)
        if tessera:
            attiva(2, etichetta=re.sub(r" \[.*$", "", tessera))
            valide = [n for n in albero() if re.search(r", libera, costa \d+, restano \d+$", n)]
            if valide:
                # la cella più avanzata
                scelta = min(valide, key=lambda n: int(re.search(r"riga (\d+)", n).group(1)))
                attiva(4, prefisso=re.match(r"^riga \d+, cella \d+", scelta).group(0))
        mio = next((n for n in albero() if re.match(r"^riga \d+, cella \d+, tu(o|a|oi|e) ", n)), None)
        if mio:
            attiva(3, prefisso=re.match(r"^riga \d+, cella \d+", mio).group(0))
            voci = albero()
            trovate = [v for v in voci if v.startswith("Ingaggia") or v.startswith("Tira su")]
            ingaggi += trovate
            if trovate:
                e = puls(trovate[0], 8)
                frasi += sentito(e)
            elif "Scegli la destinazione sulla griglia" in voci and not vicino_al_nemico(mio):
                puls("Scegli la destinazione sulla griglia", 3)
                mete = [n for n in albero() if re.search(r", libera, costa \d+, restano \d+$", n)]
                if mete:
                    scelta = min(mete, key=lambda n: int(re.search(r"riga (\d+)", n).group(1)))
                    attiva(4, prefisso=re.match(r"^riga \d+, cella \d+", scelta).group(0))
                else:
                    attiva(3, prefisso=re.match(r"^riga \d+, cella \d+", mio).group(0))
            elif "Chiudi il pannello" in voci:
                puls("Chiudi il pannello", 2)
        if "Resoconto della battaglia" in albero():
            break
        e = puls("Fine del turno", 10)
        frasi += sentito(e)
    controlla("le azioni d'ingaggio si offrono con la virgola fra riga e cella", bool(ingaggi) and all(re.search(r"riga \d+, cella \d+", v) for v in ingaggi), ingaggi=ingaggi[:6])
    senza = [p for p in ingaggi + frasi + albero() if re.search(r"riga \d+ (cella|casella) \d+", p)]
    controlla("nessuna frase ha «riga 1 cella 2» senza la virgola", not senza, senza=senza[:4])
    nomi = albero()
    controlla("la battaglia si conclude col resoconto", "Resoconto della battaglia" in nomi, nomi=nomi[:10])
    controlla("il congedo dice «Torna sulla mappa»", "Torna sulla mappa" in nomi and "Torna all'inizio" not in nomi, nomi=nomi[-6:])
    e = puls("Torna sulla mappa", 8)
    controlla("si torna sulla mappa, e si sente com'è andata", any(p.startswith("Battaglia vinta") or p.startswith("Battaglia persa") for p in sentito(e)), sentito=sentito(e))


PERCORSI = dict(reclute=reclute, rifiuto=rifiuto, presa=presa, subita=subita, richiamo=richiamo, battaglia=battaglia)
USCITA.parent.mkdir(parents=True, exist_ok=True)
for nome in sys.argv[5:] or TUTTI:
    PERCORSO = nome
    print("== " + nome, flush=True)
    t0 = time.time()
    try:
        PERCORSI[nome]()
    except Exception as errore:  # un percorso caduto non ferma gli altri: si dichiara
        controlla("il percorso arriva in fondo", False, errore=repr(errore))
    scrivi("durata", secondi=round(time.time() - t0))
valori_di_fabbrica()
print(f"controlli: {conto['si']} su {conto['si'] + conto['no']}", flush=True)
scrivi("fine", controlli_riusciti=conto["si"], controlli=conto["si"] + conto["no"])
