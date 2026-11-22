#!/usr/bin/env python3
"""I percorsi di verifica del regno (incarico 30), guidati col pilota dell'incarico 28 con VoiceOver acceso.

Il pilota (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`) gira sul simulatore e legge i
comandi da <cartella>/comandi.jsonl; questo guidatore li scrive uno alla volta, legge l'esito (ciò che
VoiceOver ha detto, l'albero di accessibilità) e registra per ogni controllo l'atteso, il trovato e
l'esito in <cartella>/controlli.jsonl. Le pronunce restituite dal servizio VoiceOver delle prove si
troncano a 64 caratteri: i confronti sulle pronunce valgono sul loro inizio, quelli sull'albero sul testo intero.

Uso: python3 percorsi-regno.py <cartella del pilota> <udid> <apparecchio: iphone|ipad> [blocchi...]
Blocchi: patria, inverno, campagna, testo (predefiniti: tutti, in quest'ordine).
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
BLOCCHI = sys.argv[4:] or ["patria", "inverno", "campagna", "testo"]
CONTROLLI = CARTELLA / "controlli.jsonl"
TRONCA = 56  # le pronunce si confrontano sul loro inizio: il servizio le tronca a 64 caratteri


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
    print(("ok  " if esito else "NO  ") + nome + " — " + str(trovato)[:260], flush=True)


def attiva(**chi):
    return cmd(dict({"azione": "attiva", "ascolto": chi.pop("ascolto", 3.0)}, **chi))


def avvia_pulito():
    cmd({"azione": "termina", "ascolto": 0.3})
    cmd({"azione": "avvia", "ascolto": 2})
    cmd({"azione": "vo_accendi", "ascolto": 1})


def tocco_magico(bersaglio):
    e = cmd({"azione": "multi_tocco", "tocchi": 2, "dita": 2, "etichetta": bersaglio, "tipo": "pulsante", "ascolto": 4})
    return sentito(e)


def giro(nome=None):
    c = {"azione": "giro", "ascolto": 0.5}
    if nome:
        c.update(con_schermata=True, nome=f"{APPARECCHIO}-{nome}")
    return cmd(c, attesa=600).get("pronunce", [])


def in_ordine(pronunce, attese):
    """Vero se le pronunce cominciano, nell'ordine, come le attese (confronto sull'inizio)."""
    if len(pronunce) < len(attese):
        return False
    return all(p.startswith(a[:TRONCA]) for p, a in zip(pronunce, attese))


def schermata(nome):
    cmd({"azione": "schermata", "nome": f"{APPARECCHIO}-{nome}", "ascolto": 0.3})


FORZE = ["gruppo armato: 6 atomi di fanteria leggera",
         "gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante",
         "gruppo armato: 24 atomi di fanteria pesante, 12 atomi di cavalleria manovrata",
         "formazione di ricognizione: 3 atomi di fanteria leggera",
         "formazione non armata: 4 atomi di fanteria leggera"]
LEGGERA = "Leva di fanteria leggera. Costa: monete di bronzo 30 su 220, uomini 6 su 26, metalli 3 su 33. 6 atomi, pronta in primavera."
PESANTE = "Leva di fanteria pesante. Costa: monete di bronzo 64 su 220, uomini 8 su 26, metalli 16 su 33. 8 atomi, pronta in primavera."
CAVALLERIA = "Leva di cavalleria manovrata. Costa: monete di bronzo 72 su 220, uomini 6 su 26, metalli 6 su 33, animali 6 su 13. 6 atomi, pronta in primavera."


# ------------------------------------------------------------------------------------------ la patria
def blocco_patria():
    avvia_pulito()
    nomi = albero()
    controlla("avvio: «Nuovo regno» è la prima voce dopo il titolo", nomi[:2] == ["WarSense", "Nuovo regno"]
              or (nomi[:1] == ["WarSense"] and "Nuovo regno" in nomi[:3]), ["WarSense", "(Riprendi il regno)", "Nuovo regno"], nomi[:4])
    e = attiva(etichetta="Nuovo regno", tipo="pulsante", ascolto=6)
    controlla("patria: il fuoco d'apertura va al titolo", e.get("dopo", "").startswith("Patria"),
              "Patria, intestazione", sentito(e))
    pronunce = giro("patria-primavera")
    attese = ["Patria", "Anno 1, primavera", "Nessuna campagna aperta quest'anno", "Riserve",
              "monete di bronzo: 20", "uomini: 2", "metalli: 3", "materiale da costruzione: 3", "animali: 1",
              "Forze"] + FORZE + ["Apri la campagna", "Attendi l'inverno", "Registro della patria", "Torna all'inizio"]
    controlla("patria: VoiceOver la legge in ordine — data, campagna, riserve voce per voce, forze, comandi",
              in_ordine(pronunce, attese) and len(pronunce) == len(attese), attese, pronunce)
    s = tocco_magico("Registro della patria")
    controlla("patria: il tocco magico dice la data e la campagna dell'anno",
              "Anno 1, primavera. Nessuna campagna aperta quest'anno" in s,
              "Anno 1, primavera. Nessuna campagna aperta quest'anno", s)


# ------------------------------------------------------------------------------------------ l'inverno
def blocco_inverno():
    nomi = albero()
    if "Attendi l'inverno" not in nomi:
        avvia_pulito()
        attiva(etichetta="Nuovo regno", tipo="pulsante", ascolto=6)
    e = attiva(etichetta="Attendi l'inverno", tipo="pulsante", ascolto=7)
    s = sentito(e)
    controlla("inverno: l'arrivo si annuncia con l'entrata dell'anno",
              "Comincia l'inverno dell'anno 1. Entrate: monete di bronzo 200" in s,
              "Comincia l'inverno dell'anno 1. Entrate: monete di bronzo 200, uomini 24, …", s)
    controlla("inverno: è una schermata nuova, il fuoco va in testa alla data",
              e.get("dopo", "").startswith("Anno 1, inverno, schermata 1 di 4"), "Anno 1, inverno, schermata 1 di 4", e.get("dopo"))
    nomi = albero()
    controlla("inverno: il bilancio nasce dalla rendita — le riserve dopo l'entrata",
              all(x in nomi for x in ["monete di bronzo: 220", "uomini: 26", "metalli: 33", "materiale da costruzione: 33", "animali: 13"]),
              ["monete di bronzo: 220", "uomini: 26", "metalli: 33", "materiale da costruzione: 33", "animali: 13"],
              [n for n in nomi if ": " in n and n.split(": ")[-1].isdigit()])
    controlla("inverno: ogni voce dice quanto costa su quanto se ne possiede, per le sole risorse che consuma",
              all(x in nomi for x in [LEGGERA, PESANTE, CAVALLERIA]), [LEGGERA, PESANTE, CAVALLERIA],
              [n for n in nomi if n.startswith("Leva di") and "Costa" in n])
    pronunce = giro("inverno-prima-schermata")
    attese = ["Patria", "Anno 1, inverno, schermata 1 di 4", "Quest'anno nessuna campagna", "Riserve",
              "monete di bronzo: 220", "uomini: 26", "metalli: 33", "materiale da costruzione: 33", "animali: 13",
              "Forze"] + FORZE + ["Lavori da ordinare", LEGGERA, PESANTE, CAVALLERIA, "Lavori ordinati",
              "Nessun lavoro ordinato in questo inverno", "Annulla l'ultima spesa", "Azzera le spese di questa schermata",
              "Prosegui alla schermata 2 di 4", "Registro della patria", "Torna all'inizio"]
    controlla("inverno: VoiceOver legge la schermata in ordine, fino all'ultimo comando",
              in_ordine(pronunce, attese) and len(pronunce) == len(attese), attese, pronunce)

    # Una spesa: l'annuncio, la riserva che scende, il fuoco che resta sulla voce.
    e = attiva(contiene="Leva di fanteria pesante.", tipo="pulsante", ascolto=4)
    s = sentito(e)
    controlla("spesa: l'ordine si annuncia con quando sarà pronto",
              "Leva di fanteria pesante ordinata: pronta in primavera" in s,
              "Leva di fanteria pesante ordinata: pronta in primavera.", s)
    controlla("spesa: il fuoco resta sulla voce appena ordinata",
              e.get("dopo", "").startswith("Leva di fanteria pesante.") or "Leva di fanteria pesante ordinata" in e.get("dopo", ""),
              "Leva di fanteria pesante. Costa: … (la voce stessa, aggiornata)", e.get("dopo"))
    nomi = albero()
    controlla("spesa: la riserva scende e la voce dichiara il costo sulla riserva nuova",
              "monete di bronzo: 156" in nomi and "metalli: 17" in nomi
              and any(n.startswith("Leva di fanteria pesante. Costa: monete di bronzo 64 su 156, uomini 8 su 18, metalli 16 su 17.") for n in nomi),
              ["monete di bronzo: 156", "metalli: 17", "Leva di fanteria pesante. Costa: monete di bronzo 64 su 156, uomini 8 su 18, metalli 16 su 17. …"],
              [n for n in nomi if n.startswith("monete") or n.startswith("metalli") or n.startswith("Leva di fanteria pesante.")])
    controlla("spesa: il lavoro ordinato entra in elenco",
              "Leva di fanteria pesante, pronta in primavera" in nomi and "Nessun lavoro ordinato in questo inverno" not in nomi,
              "Leva di fanteria pesante, pronta in primavera", [n for n in nomi if "pronta in primavera" in n and "Costa" not in n])

    # La seconda leva pesante consuma i metalli: la terza non si può ordinare, e la voce lo dice prontamente.
    attiva(contiene="Leva di fanteria pesante.", tipo="pulsante", ascolto=3)
    nomi = albero()
    impedita = [n for n in nomi if n.startswith("Leva di fanteria pesante. Non si può ordinare: mancano metalli.")]
    controlla("impossibilità: la voce la dichiara prontamente, con la risorsa che manca",
              bool(impedita), "Leva di fanteria pesante. Non si può ordinare: mancano metalli. Costa: …",
              [n for n in nomi if n.startswith("Leva di fanteria pesante.")])
    e = attiva(contiene="Leva di fanteria pesante.", tipo="pulsante", ascolto=4)
    s = sentito(e)
    controlla("impossibilità: ordinandola si sente il motivo, e nulla cambia",
              "Non si può ordinare: mancano metalli" in s and "metalli: 1" in albero(),
              "Non si può ordinare: mancano metalli.", s)

    # Annullamento, azzeramento, e i due a vuoto.
    e = attiva(etichetta="Annulla l'ultima spesa", tipo="pulsante", ascolto=4)
    s = sentito(e)
    controlla("annullamento: ritira l'ultima spesa e lo dice",
              "Leva di fanteria pesante: ordine annullato, risorse restituite" in s and "metalli: 17" in albero(),
              "Leva di fanteria pesante: ordine annullato, risorse restituite.", s)
    e = attiva(etichetta="Azzera le spese di questa schermata", tipo="pulsante", ascolto=4)
    s = sentito(e)
    controlla("azzeramento: ritira tutte le spese della schermata e dice quante",
              "Spese della schermata azzerate: 1 ordine ritirato" in s and "metalli: 33" in albero(),
              "Spese della schermata azzerate: 1 ordine ritirato", s)
    e = attiva(etichetta="Annulla l'ultima spesa", tipo="pulsante", ascolto=4)
    controlla("annullamento a vuoto: lo dice invece di confermare",
              "Nessuna spesa da annullare in questa schermata" in sentito(e),
              "Nessuna spesa da annullare in questa schermata", sentito(e))
    e = attiva(etichetta="Azzera le spese di questa schermata", tipo="pulsante", ascolto=4)
    controlla("azzeramento a vuoto: lo dice invece di confermare",
              "Nessuna spesa da azzerare in questa schermata" in sentito(e),
              "Nessuna spesa da azzerare in questa schermata", sentito(e))

    # Le quattro schermate e la primavera.
    attiva(contiene="Leva di fanteria leggera.", tipo="pulsante", ascolto=3)
    voci_prima = [n for n in albero() if n.startswith("Leva di") and "Costa" in n]
    for stazione in (2, 3, 4):
        e = attiva(etichetta=f"Prosegui alla schermata {stazione} di 4", tipo="pulsante", ascolto=4)
        s = sentito(e)
        nomi = albero()
        controlla(f"stazione {stazione}: si annuncia, e la schermata ha le stesse voci",
                  f"Inverno, schermata {stazione} di 4" in s and f"Anno 1, inverno, schermata {stazione} di 4" in nomi
                  and [n for n in nomi if n.startswith("Leva di") and "Costa" in n] == voci_prima
                  and "Leva di fanteria leggera, pronta in primavera" in nomi,
                  f"Inverno, schermata {stazione} di 4", s)
    schermata("inverno-quarta-schermata")
    e = attiva(etichetta="Prosegui alla primavera", tipo="pulsante", ascolto=8)
    s = sentito(e)
    controlla("primavera: si annuncia con ciò che il riporto ha tolto e i lavori pronti",
              "Comincia la primavera dell'anno 2. Il riporto ha tolto: monete di" in s,
              "Comincia la primavera dell'anno 2. Il riporto ha tolto: monete di bronzo 170, … Leva di fanteria leggera: è pronta.", s)
    controlla("primavera: è una schermata nuova, il fuoco va in testa alla data",
              e.get("dopo", "").startswith("Anno 2, primavera"), "Anno 2, primavera", e.get("dopo"))
    nomi = albero()
    armati = [n for n in nomi if n.startswith("gruppo armato: ")]
    controlla("primavera: avanza un decimo dell'entrata, e le reclute sono una formazione nuova",
              "monete di bronzo: 20" in nomi and "uomini: 2" in nomi and len(armati) == 4
              and armati[-1] == "gruppo armato: 6 atomi di fanteria leggera",
              ["monete di bronzo: 20", "uomini: 2", "quattro gruppi armati, l'ultimo di 6 atomi di fanteria leggera"],
              [n for n in nomi if n.startswith("monete") or n.startswith("uomini")] + armati)
    schermata("patria-seconda-primavera")
    # Il registro della patria: i fatti che il giocatore non ha deciso, dal più recente.
    attiva(etichetta="Registro della patria", tipo="pulsante", ascolto=4)
    pronunce = giro("registro-della-patria")
    attese = ["Registro della patria", "Anno 2, primavera: Leva di fanteria leggera è pronta",
              "Anno 2, primavera: comincia la primavera; il riporto ha tolto ciò che eccedeva",
              "Anno 1, inverno: comincia l'inverno e arriva l'entrata dell'anno", "Chiudi il registro"]
    controlla("registro della patria: i fatti dal più recente, ciascuno con l'anno e la stagione",
              in_ordine(pronunce, attese) and len(pronunce) == len(attese), attese, pronunce)
    attiva(etichetta="Chiudi il registro", tipo="pulsante", ascolto=3)


# ------------------------------------------------------------------------------------------ la campagna
def blocco_campagna():
    nomi = albero()
    if "Apri la campagna" not in nomi:
        avvia_pulito()
        attiva(etichetta="Nuovo regno", tipo="pulsante", ascolto=6)
        nomi = albero()
    anno = next((re.match(r"Anno (\d+), primavera", n).group(1) for n in nomi if re.match(r"Anno \d+, primavera", n)), "1")
    attiva(etichetta="Apri la campagna", tipo="pulsante", ascolto=3)
    nomi = albero()
    fronti = ["fronte del guado, mappa 4 per 4", "fronte dell'istmo, mappa 6 per 6", "fronte della pianura lunga, mappa 10 per 10"]
    controlla("campagna: la scelta del fronte, una voce per fronte con la mappa",
              "Su quale fronte?" in nomi and all(f in nomi for f in fronti), ["Su quale fronte?"] + fronti,
              [n for n in nomi if "fronte" in n.lower()])
    e = attiva(etichetta="fronte del guado, mappa 4 per 4", tipo="pulsante", ascolto=8)
    s = sentito(e)
    nomi = albero()
    propri = [n for n in nomi if re.search(r"riga \d+, casella \d+, tu(o|a|oi|e) ", n)]
    controlla("campagna: si entra nella mappa del fronte con le forze del regno",
              len(propri) >= 5 and "Torna in patria" in nomi and "Torna all'inizio" not in nomi,
              "almeno cinque formazioni proprie sulla mappa, e il comando «Torna in patria»",
              propri + [n for n in nomi if n.startswith("Torna")])
    s = tocco_magico("Registro della campagna")
    controlla("campagna: l'informazione di stato comincia dalla data, con quanto manca all'inverno",
              f"Anno {anno}, primavera, mancano 89 giornate all'inverno. Giorno 1." in s,
              f"Anno {anno}, primavera, mancano 89 giornate all'inverno. Giorno 1. …", s)
    schermata("mappa-del-fronte")
    # Una giornata chiusa dal comando, poi il ritorno in patria: la data è quella del fronte.
    e = attiva(etichetta="Chiudi la giornata", tipo="pulsante", ascolto=6)
    controlla("campagna: la giornata si chiude", "Giornata chiusa" in sentito(e) or "comincia il giorno 2" in sentito(e),
              "Giornata chiusa … comincia il giorno 2", sentito(e))
    e = attiva(etichetta="Torna in patria", tipo="pulsante", ascolto=5)
    nomi = albero()
    controlla("campagna: tornati in patria, la data è quella del fronte e il comando è «Entra nel fronte»",
              f"Anno {anno}, primavera, giorno 2 di 90" in nomi and "Campagna aperta sul fronte del guado" in nomi
              and "Entra nel fronte del guado" in nomi and "Attendi l'inverno" not in nomi,
              [f"Anno {anno}, primavera, giorno 2 di 90", "Campagna aperta sul fronte del guado", "Entra nel fronte del guado"],
              [n for n in nomi if n.startswith("Anno") or "fronte" in n or "inverno" in n])
    controlla("campagna: il fuoco torna sul comando da cui si era entrati",
              e.get("dopo", "").startswith("Entra nel fronte del guado"), "Entra nel fronte del guado, pulsante", e.get("dopo"))
    schermata("patria-con-campagna-aperta")
    # Chiusa e riaperta l'app, il regno si riprende con la campagna aperta allo stesso giorno.
    cmd({"azione": "termina", "ascolto": 0.3})
    cmd({"azione": "avvia", "ascolto": 2})
    nomi = albero()
    controlla("ripresa: l'avvio offre «Riprendi il regno» in testa", nomi[:3] == ["WarSense", "Riprendi il regno", "Nuovo regno"],
              ["WarSense", "Riprendi il regno", "Nuovo regno"], nomi[:4])
    attiva(etichetta="Riprendi il regno", tipo="pulsante", ascolto=6)
    nomi = albero()
    controlla("ripresa: il regno ritrova la campagna aperta allo stesso giorno",
              f"Anno {anno}, primavera, giorno 2 di 90" in nomi and "Entra nel fronte del guado" in nomi,
              [f"Anno {anno}, primavera, giorno 2 di 90", "Entra nel fronte del guado"],
              [n for n in nomi if n.startswith("Anno") or "fronte" in n])


# ------------------------------------------------------------------------------------------ il testo massimo
def blocco_testo():
    """La patria d'inverno alla dimensione del testo più grande: VoiceOver la legge per intero, e le schermate
    mostrano che nulla esce dal bordo."""
    subprocess.run(["xcrun", "simctl", "ui", UDID, "content_size", "accessibility-extra-extra-extra-large"], check=False)
    try:
        avvia_pulito()
        attiva(etichetta="Nuovo regno", tipo="pulsante", ascolto=6)
        schermata("testo-massimo-patria")
        attiva(etichetta="Attendi l'inverno", tipo="pulsante", ascolto=6)
        pronunce = giro("testo-massimo-inverno")
        attese = ["Patria", "Anno 1, inverno, schermata 1 di 4", "Quest'anno nessuna campagna", "Riserve",
                  "monete di bronzo: 220", "uomini: 26", "metalli: 33", "materiale da costruzione: 33", "animali: 13",
                  "Forze"] + FORZE + ["Lavori da ordinare", LEGGERA, PESANTE, CAVALLERIA, "Lavori ordinati",
                  "Nessun lavoro ordinato in questo inverno", "Annulla l'ultima spesa", "Azzera le spese di questa schermata",
                  "Prosegui alla schermata 2 di 4", "Registro della patria", "Torna all'inizio"]
        controlla("testo massimo: VoiceOver legge la patria d'inverno per intero, fino all'ultimo comando",
                  in_ordine(pronunce, attese) and len(pronunce) == len(attese), attese, pronunce)
        e = attiva(contiene="Leva di fanteria leggera.", tipo="pulsante", ascolto=4)
        controlla("testo massimo: la leva si ordina anche a testo massimo",
                  "Leva di fanteria leggera ordinata: pronta in primavera" in sentito(e),
                  "Leva di fanteria leggera ordinata: pronta in primavera.", sentito(e))
        schermata("testo-massimo-inverno-dopo-la-spesa")
    finally:
        subprocess.run(["xcrun", "simctl", "ui", UDID, "content_size", "large"], check=False)


def main():
    t0 = time.time()
    for blocco in BLOCCHI:
        print(f"== blocco {blocco} ({APPARECCHIO}) ==", flush=True)
        {"patria": blocco_patria, "inverno": blocco_inverno, "campagna": blocco_campagna, "testo": blocco_testo}[blocco]()
    righe = [json.loads(r) for r in CONTROLLI.read_text(encoding="utf-8").splitlines()] if CONTROLLI.exists() else []
    print(f"controlli: {len(righe)}, ok {sum(1 for r in righe if r['esito'] == 'ok')}, NO {sum(1 for r in righe if r['esito'] != 'ok')}; "
          f"durata {time.time() - t0:.0f} s")


if __name__ == "__main__":
    main()
