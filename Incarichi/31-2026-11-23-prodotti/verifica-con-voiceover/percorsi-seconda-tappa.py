#!/usr/bin/env python3
"""I percorsi di verifica della SECONDA TAPPA DEL REGNO (incarico 31), guidati col pilota dell'incarico 28
con VoiceOver acceso, sul modello di `Incarichi/30-2026-11-22-prodotti/verifica-con-voiceover/percorsi-regno.py`.

Il pilota (`Applicazione/Esplorazione/SessioneInterattivaTest.swift`) gira sul simulatore e legge i comandi
da <cartella>/comandi.jsonl; questo guidatore li scrive uno alla volta, legge l'esito e registra per ogni
controllo il blocco, l'atteso, il trovato e l'esito in <cartella>/controlli.jsonl.

Uso: python3 percorsi-seconda-tappa.py <cartella del pilota> <udid> <apparecchio: iphone|ipad> [blocchi...]
Blocchi (predefiniti: tutti, in quest'ordine):
  partenza      la patria in primavera: i nomi, dove va ciascuna formazione, la riga che è un comando col suo
                suggerimento, chi resta e chi riparte col fuoco fermo, nessuna campagna senza un armato
  mappa         sulla mappa i gruppi hanno i nomi delle formazioni partite, chi è rimasto non c'è
  inverno       l'annuncio col mantenimento, la prima schermata che lo dichiara, le linguette come
                intestazioni, la scelta del reparto (anche impedita), le stagioni schermata per schermata,
                la leva ordinata alla quarta, la primavera
  estate        il reparto migliorato sulla mappa; trenta chiusure, e l'arrivo dalla patria con l'estate
  reclute       le reclute pronte in primavera: annuncio, riga in patria, registro della campagna
  mantenimento  il secondo inverno: da mantenere, mantenimento pagato, e chi non lo paga lo perde
  voce          una misura, senza copie negli appunti: per quanto un annuncio resta la pronuncia corrente
                quando lo accompagna uno spostamento del fuoco
  orizzontale   la patria in primavera e d'inverno, e la scelta del reparto, lette in orizzontale
  testo         le stesse alla dimensione del testo più grande, con le schermate

CHE COSA SI SENTE, E COME. Il servizio VoiceOver delle prove (`XCUIVoiceOverService`) tronca ogni pronuncia
a 64 caratteri. Dall'incarico 31 il pilota legge anche la PRONUNCIA INTERA: dà a VoiceOver il comando che
copia negli appunti l'ultima cosa detta (Control, Opzione, Maiuscole, C), e gli appunti del simulatore li
legge il lato Mac (`scripts/interattivo.py --appunti`, con `xcrun simctl pbpaste`). La pronuncia intera
di un elemento porta l'etichetta fino in fondo, il tratto («Pulsante», «Intestazione») e il suggerimento;
quella di un annuncio, l'annuncio fino in fondo. Dove gli appunti non rispondono si confronta l'inizio.

Campi del pilota: «fuoco» è ciò che VoiceOver dice toccando l'elemento, prima del doppio tocco; «ascoltate»
le pronunce nuove nell'ascolto dopo l'azione, con gli istanti in «ascoltate_t»; «intere» le pronunce intere
lette dagli appunti; «dopo» l'ultima cosa detta. Dove sta il fuoco dopo un'azione lo si legge spostandolo
avanti e indietro (la rilettura).
"""
import json
import os
import pathlib
import re
import subprocess
import sys
import time

CARTELLA = pathlib.Path(sys.argv[1])
UDID = sys.argv[2]
APPARECCHIO = sys.argv[3]
TUTTI = ["partenza", "mappa", "inverno", "estate", "reclute", "mantenimento", "voce", "orizzontale", "testo"]
BLOCCHI = sys.argv[4:] or TUTTI
# I controlli si scrivono uno alla volta, appena fatti: di norma accanto ai comandi del pilota; il
# lanciatore (`corri.sh`) li fa scrivere direttamente fra i prodotti, perché un'interruzione non li perda.
CONTROLLI = pathlib.Path(os.environ.get("PERCORSI_CONTROLLI") or CARTELLA / "controlli.jsonl")
TRONCA = 62  # dove manca la pronuncia intera si confronta l'inizio: il servizio tronca a 64 caratteri
# Quanto in fretta VoiceOver può dire un annuncio, per eccesso: la misura sulla mappa (blocco «mappa»)
# dà fra 13 e 17 caratteri al secondo alla velocità predefinita del 50%.
VELOCITA_MASSIMA = 25.0
BLOCCO = ""


# ------------------------------------------------------------------------------------------ il canale
_letti = 0
_esiti = {}
_prossimo = None


def _leggi_esiti():
    """Legge le righe nuove di esiti.jsonl, da dove era arrivato."""
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
        _leggi_esiti()
        if n in _esiti:
            return _esiti[n]
        time.sleep(0.1)
    return {"n": n, "errore": "nessun esito"}


def intere(e):
    """Le pronunce intere che un esito porta, nell'ordine in cui sono state lette dagli appunti."""
    return [x.get("testo", "") for x in e.get("intere", []) if x.get("testo")]


def sentito(e):
    """Tutto ciò che si è sentito dopo un'azione: le pronunce intere, poi quelle troncate, poi l'ultima."""
    return " || ".join(intere(e) + e.get("ascoltate", []) + [e.get("dopo", "")])


def albero():
    return [re.sub(r" \[.*$", "", r) for r in cmd({"azione": "albero", "ascolto": 0.2}).get("albero", [])]


def elementi(**filtro):
    return cmd(dict({"azione": "elementi", "ascolto": 0.2}, **filtro)).get("elementi", [])


def senza_doppi(nomi):
    """L'albero riporta ogni pulsante due volte (il pulsante e la sua scritta): per confrontare un ORDINE
    si tolgono le ripetizioni consecutive."""
    out = []
    for n in nomi:
        if not out or out[-1] != n:
            out.append(n)
    return out


# I REPERTI RIFERITI (incarico 31): difetti e osservazioni dell'app trovati da questi percorsi, riferiti e non
# corretti. I controlli che li riguardano portano il campo «reperto» con il numero, e conservano l'esito
# vero: un «NO» con quel campo cade su un difetto riferito, non su un errore del guidatore.
REPERTI = {
    1: "annunci superati dallo spostamento del fuoco",
    2: "le reclute di primavera entrano lontano dal quartier generale che riga e annuncio dichiarano",
    3: "«Apri la campagna» senza armati che partano fa scegliere il fronte prima di rifiutare",
}


def reperto_del_controllo(nome):
    """Il reperto che un controllo riguarda, dal suo nome: è il criterio con cui il campo si scrive."""
    if nome.startswith("voce"):
        return 1
    if nome.startswith("d: sulla mappa, alla prima giornata") or nome.startswith("d: il registro della campagna annota"):
        return 2
    if nome.startswith("b: con tutti gli armati in patria si sente"):
        return 3
    return None


def controlla(nome, esito, atteso, trovato, **altro):
    riga = dict(apparecchio=APPARECCHIO, blocco=BLOCCO, controllo=nome, esito="ok" if esito else "NO",
                atteso=atteso, trovato=trovato, ora=time.strftime("%H:%M:%S"), **altro)
    if reperto_del_controllo(nome):
        riga["reperto"] = reperto_del_controllo(nome)
        riga["reperto_detto"] = "difetto riferito: " + REPERTI[riga["reperto"]]
    with CONTROLLI.open("a", encoding="utf-8") as f:
        f.write(json.dumps(riga, ensure_ascii=False) + "\n")
    print(("ok  " if esito else "NO  ") + nome + " — " + str(trovato)[:300], flush=True)
    return bool(esito)


def attiva(**chi):
    """Tocco, poi doppio tocco, poi l'ascolto. Di norma si ascolta soltanto (una lettura ogni quarto di
    secondo): basta agli annunci che stanno in 64 caratteri, e non perde quelli che durano poco. Con
    intere="ogni" ogni pronuncia nuova si legge anche per intero dagli appunti: serve agli annunci lunghi,
    e costa quasi un secondo di ascolto cieco a ogni copia."""
    c = {"azione": "attiva", "ascolto": chi.pop("ascolto", 3.0), "intere": chi.pop("intere", None)}
    if c["intere"] is None:
        del c["intere"]
    return cmd(dict(c, **chi))


def come_sentito(e, testo):
    """Come si è sentito un annuncio dopo un'azione: «intero» se lo si è letto fino in fondo (dagli appunti,
    o dal servizio se sta in 64 caratteri), «inizio» se il servizio ne ha dato soltanto l'inizio troncato,
    nulla se non lo si è sentito."""
    dette = e.get("ascoltate", [])
    if testo in intere(e) or testo in dette:
        return "intero"
    if len(testo) > 64 and testo[:64] in dette:
        return "inizio"
    return None


def avanti():
    e = cmd({"azione": "avanti", "ascolto": 0.3, "intere": True})
    return (e.get("pronunce_intere") or [""])[0] or (e.get("pronunce") or [""])[0]


def indietro():
    e = cmd({"azione": "indietro", "ascolto": 0.3, "intere": True})
    return (e.get("pronunce_intere") or [""])[0] or (e.get("pronunce") or [""])[0]


def rilettura():
    """Dove sta il fuoco: lo si sposta avanti (l'elemento che segue) e indietro (l'elemento su cui stava)."""
    dopo = avanti()
    qui = indietro()
    return qui, dopo


def giro(nome=None):
    """La schermata letta dall'inizio alla fine: le pronunce troncate e, accanto, quelle intere."""
    c = {"azione": "giro", "ascolto": 0.3, "intere": True}
    if nome:
        c.update(con_schermata=True, nome=f"{APPARECCHIO}-{nome}")
    e = cmd(c, attesa=900)
    return e.get("pronunce", []), e.get("pronunce_intere", [])


def schermata(nome):
    cmd({"azione": "schermata", "nome": f"{APPARECCHIO}-{nome}", "ascolto": 0.2})


def avvia_pulito():
    cmd({"azione": "termina", "ascolto": 0.3})
    cmd({"azione": "avvia", "ascolto": 2})
    cmd({"azione": "vo_accendi", "ascolto": 1})


def regno_nuovo():
    avvia_pulito()
    return attiva(etichetta="Nuovo regno", tipo="pulsante", ascolto=5)


def tocco_magico(bersaglio):
    e = cmd({"azione": "multi_tocco", "tocchi": 2, "dita": 2, "etichetta": bersaglio, "tipo": "pulsante",
             "ascolto": 4, "intere": "ogni"})
    return sentito(e)


def confronta(troncate, piene, attese):
    """Confronta una lettura con le pronunce attese, elemento per elemento: sulla pronuncia intera dove
    gli appunti l'hanno data, sull'inizio (62 caratteri) dove no. Restituisce l'esito, quante sono state
    confrontate per intero e le differenze."""
    differenze, per_intero = [], 0
    for i, attesa in enumerate(attese):
        piena = piene[i] if i < len(piene) else ""
        tronca = troncate[i] if i < len(troncate) else ""
        if piena:
            per_intero += 1
            if piena != attesa:
                differenze.append({"posto": i + 1, "atteso": attesa, "trovato": piena})
        elif not (tronca and attesa.startswith(tronca[:TRONCA]) and tronca.startswith(attesa[:TRONCA])):
            differenze.append({"posto": i + 1, "atteso": attesa, "trovato": tronca, "solo_inizio": True})
    if len(troncate) != len(attese):
        differenze.append({"lunghezza_attesa": len(attese), "lunghezza_trovata": len(troncate),
                           "in_piu": troncate[len(attese):]})
    return not differenze, per_intero, differenze


def controlla_lettura(nome, troncate, piene, attese):
    ok, per_intero, differenze = confronta(troncate, piene, attese)
    return controlla(nome, ok, attese, piene if any(piene) else troncate,
                     confrontate_per_intero=per_intero, elementi=len(attese), differenze=differenze)


def vita_della_pronuncia(e, testo):
    """Quanto a lungo, AL PIÙ, una pronuncia è rimasta quella corrente: dal doppio tocco che l'ha provocata
    alla prima pronuncia diversa venuta dopo. Nulla se nell'ascolto nessuna l'ha seguita."""
    dette, istanti = e.get("ascoltate", []), e.get("ascoltate_t", [])
    for i, detta in enumerate(dette):
        if detta and testo.startswith(detta[:TRONCA]):
            if i + 1 < len(dette):
                return round(e.get("doppio_tocco_s", 0) + istanti[i + 1], 2), dette[i + 1]
            return None, None
    return -1, None


def controlla_la_voce(nome, e, testo):
    """UN CONTROLLO AGGIUNTO (non è fra i punti dell'incarico): un annuncio non deve essere superato da
    un'altra pronuncia prima del tempo che serve a dirlo. Il simulatore non dà l'audio; il servizio dice
    però quale pronuncia è quella corrente e quando cambia, e la coda degli annunci del gioco avanza
    soltanto quando VoiceOver notifica che l'annuncio in corso è concluso."""
    serve = round(len(testo) / VELOCITA_MASSIMA, 1)
    limite, successiva = vita_della_pronuncia(e, testo)
    if limite == -1:
        return controlla(nome, False, f"l'annuncio «{testo[:60]}…» fra le pronunce dell'ascolto", sentito(e))
    ok = limite is None or limite >= serve
    return controlla(nome, ok,
                     f"nessun'altra pronuncia prima di {serve} s: l'annuncio ha {len(testo)} caratteri, e a "
                     f"{VELOCITA_MASSIMA:.0f} caratteri al secondo, più in fretta di quanto VoiceOver parli, servono {serve} s",
                     "resta la pronuncia corrente fino alla fine dell'ascolto" if limite is None
                     else f"dopo al più {limite} s (doppio tocco compreso) la pronuncia corrente è «{successiva}»",
                     caratteri=len(testo), secondi_necessari=serve, superata_dopo_al_piu_s=limite,
                     ascoltate=e.get("ascoltate"), istanti=e.get("ascoltate_t"), doppio_tocco_s=e.get("doppio_tocco_s"))


# ------------------------------------------------------------------------------------------ gli attesi
SUGGERIMENTO = "Attiva per scegliere se parte per il fronte o resta in patria"
ORDINE = ["Corvo", "Lupo", "Falco", "Orso", "Cervo"]
FORZE = {
    "Corvo": "Corvo, gruppo armato: 6 atomi di fanteria leggera",
    "Lupo": "Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante",
    "Falco": "Falco, gruppo armato: 24 atomi di fanteria pesante, 12 atomi di cavalleria manovrata",
    "Orso": "Orso, formazione di ricognizione: 3 atomi di fanteria leggera",
    "Cervo": "Cervo, formazione non armata: 4 atomi di fanteria leggera",
}
# Ciò che la casella della mappa dice di ciascuna formazione dopo il nome (categoria e reparti).
SULLA_MAPPA = {
    "Corvo": "in attesa, composta da 6 atomi di fanteria leggera",
    "Lupo": "in attesa, composta da 18 atomi di fanteria leggera, 8 atomi di fanteria pesante",
    "Falco": "in attesa, composta da 24 atomi di fanteria pesante, 12 atomi di cavalleria manovrata",
    "Orso": "formazione di ricognizione, in attesa, composta da 3 atomi di fanteria leggera",
    "Cervo": "formazione non armata, in attesa, composta da 4 atomi di fanteria leggera",
    "Lince": "in attesa, composta da 6 atomi di fanteria leggera",
}
FRONTE = "fronte del guado, mappa 4 per 4"


def riga(nome, al_fronte=True, forze=FORZE):
    return forze[nome] + (". Parte per il fronte" if al_fronte else ". Resta in patria")


def comandi_della_primavera():
    return ["Apri la campagna Pulsante", "Attendi l'inverno Pulsante", "Registro della patria Pulsante",
            "Torna all'inizio Pulsante"]


def patria_in_primavera(anno=1, riserve=(20, 2, 3, 3, 1), righe=None):
    """La patria in primavera come VoiceOver la dice, per intero: ogni riga delle forze è un comando col
    suo suggerimento."""
    righe = righe or [riga(n) for n in ORDINE]
    return (["Patria Intestazione", f"Anno {anno}, primavera", "Nessuna campagna aperta quest'anno",
             "Riserve Intestazione"] + riserve_lette(riserve) + ["Forze Intestazione"]
            + [r + " Pulsante " + SUGGERIMENTO for r in righe] + comandi_della_primavera())


def riserve_lette(r):
    return [f"monete di bronzo: {r[0]}", f"uomini: {r[1]}", f"metalli: {r[2]}",
            f"materiale da costruzione: {r[3]}", f"animali: {r[4]}"]


MANTENIMENTO = "Mantenimento dell'esercito, prelevato all'inizio dell'inverno: monete di bronzo 27"
ANNUNCIO_INVERNO = ("Comincia l'inverno dell'anno {anno}. Entrate: monete di bronzo 200, uomini 24, metalli 30, "
                    "materiale da costruzione 30, animali 12. Mantenimento dell'esercito: monete di bronzo 27.")
CAVALLERIA = "Leva di cavalleria manovrata. Costa: monete di bronzo 72 su {d}, uomini 6 su {u}, metalli 6 su {m}, animali 6 su {a}. 6 atomi, pronta in {s}."
PESANTE = "Leva di fanteria pesante. Costa: monete di bronzo 64 su {d}, uomini 8 su {u}, metalli 16 su {m}. 8 atomi, pronta in {s}."
LEGGERA = "Leva di fanteria leggera. Costa: monete di bronzo 30 su {d}, uomini 6 su {u}, metalli 3 su {m}. 6 atomi, pronta in {s}."
ADDESTRAMENTO = "Addestramento mirato. Si sceglie il reparto. Accresce la capacità offensiva del reparto, pronto in primavera."
MANTIENI_NESSUNO = "Mantenimento dell'addestramento mirato. Nessun reparto disponibile. Conserva il miglioramento del reparto per un altro anno, pronto in primavera."
MANTIENI = "Mantenimento dell'addestramento mirato. Si sceglie il reparto. Conserva il miglioramento del reparto per un altro anno, pronto in primavera."
LINGUETTE = ["Lavori lunghi", "Lavori di media durata", "Lavori brevi"]
# Quando è pronta una leva ordinata a ciascuna schermata (01 §5.9.1.3–5.9.1.4): cavalleria, pesante, leggera.
STAGIONI = {1: ("estate", "primavera", "primavera"), 2: ("estate", "estate", "primavera"),
            3: ("estate", "estate", "primavera"), 4: ("autunno", "estate", "estate")}


def voci_dell_inverno(schermata_n, r):
    s = STAGIONI[schermata_n]
    return [CAVALLERIA.format(d=r[0], u=r[1], m=r[2], a=r[4], s=s[0]),
            PESANTE.format(d=r[0], u=r[1], m=r[2], s=s[1]),
            LEGGERA.format(d=r[0], u=r[1], m=r[2], s=s[2])]


def prima_schermata_dell_inverno(anno=1, r=(193, 26, 33, 33, 13)):
    """La prima schermata dell'inverno come VoiceOver la dice, per intero (regno nuovo, nessuna spesa)."""
    cavalleria, pesante, leggera = voci_dell_inverno(1, r)
    return (["Patria Intestazione", f"Anno {anno}, inverno, schermata 1 di 4", "Quest'anno nessuna campagna",
             "Riserve Intestazione"] + riserve_lette(r) + [MANTENIMENTO, "Forze Intestazione"]
            + [riga(n) for n in ORDINE]
            + ["Lavori da ordinare Intestazione",
               "Lavori lunghi Intestazione", cavalleria + " Pulsante",
               "Lavori di media durata Intestazione", pesante + " Pulsante",
               "Lavori brevi Intestazione", leggera + " Pulsante", ADDESTRAMENTO + " Pulsante",
               MANTIENI_NESSUNO + " Pulsante",
               "Lavori ordinati Intestazione", "Nessun lavoro ordinato in questo inverno",
               "Annulla l'ultima spesa Pulsante", "Azzera le spese di questa schermata Pulsante",
               "Prosegui alla schermata 2 di 4 Pulsante", "Registro della patria Pulsante",
               "Torna all'inizio Pulsante"])


# La scelta del reparto al primo inverno: dodici monete e mezza per atomo, troncate (peso 2,5 sul denaro).
SCELTE = [
    "Corvo: 6 atomi di fanteria leggera. Costa: monete di bronzo 75 su 193.",
    "Lupo: 18 atomi di fanteria leggera. Non si può ordinare: mancano monete di bronzo. Costa: monete di bronzo 225 su 193.",
    "Lupo: 8 atomi di fanteria pesante. Costa: monete di bronzo 100 su 193.",
    "Falco: 24 atomi di fanteria pesante. Non si può ordinare: mancano monete di bronzo. Costa: monete di bronzo 300 su 193.",
    "Falco: 12 atomi di cavalleria manovrata. Costa: monete di bronzo 150 su 193.",
    "Orso: 3 atomi di fanteria leggera. Costa: monete di bronzo 37 su 193.",
    "Cervo: 4 atomi di fanteria leggera. Costa: monete di bronzo 50 su 193.",
]


def scelta_letta(titolo, scelte):
    return ([titolo + " Intestazione", "Per quale reparto?"] + [s + " Pulsante" for s in scelte]
            + ["Chiudi il pannello Pulsante"])


def senza_barre(troncate, piene):
    """A testo grande iOS espone a VoiceOver, dopo l'ultimo elemento, la propria barra di scorrimento
    («Vertical scroll bar, N pages»: il simulatore è in inglese). È un elemento di sistema, non del gioco:
    lo si toglie dal confronto e lo si restituisce a parte."""
    barre = [t for t in troncate if "scroll bar" in t]
    tenute = [i for i, t in enumerate(troncate) if "scroll bar" not in t]
    return [troncate[i] for i in tenute], [piene[i] if i < len(piene) else "" for i in tenute], barre


# ------------------------------------------------------------------------------------------ gli attrezzi
def destinazioni():
    """Dove va ciascuna formazione, letto dalle righe della patria."""
    out = {}
    for n in albero():
        m = re.match(r"^(\w+), .*\. (Parte per il fronte|Resta in patria)$", n)
        if m:
            out[m.group(1)] = m.group(2) == "Parte per il fronte"
    return out


def destina(nome, al_fronte):
    """Porta una formazione dove la si vuole, attivandone la riga se occorre. Restituisce l'esito
    dell'attivazione, o nulla se era già lì."""
    if destinazioni().get(nome) == al_fronte:
        return None
    return attiva(prefisso=nome + ",", tipo="pulsante", ascolto=3)


def gruppi_propri(nomi):
    """Le formazioni proprie sulla mappa: nome -> (riga, casella, ciò che la casella dice dopo il nome)."""
    out = {}
    for n in nomi:
        m = re.match(r"^riga (\d+), casella (\d+), tu(?:o|a|oi|e) (\w+), (.*)$", n)
        if m:
            out[m.group(3)] = (int(m.group(1)), int(m.group(2)), m.group(4))
    return out


def apri_la_campagna(ascolto=9, intere="ogni"):
    """«Apri la campagna», poi il fronte del guado. Restituisce l'esito della scelta del fronte."""
    attiva(etichetta="Apri la campagna", tipo="pulsante", ascolto=2.5)
    return attiva(etichetta=FRONTE, tipo="pulsante", ascolto=ascolto, intere=intere)


def fino_alla_schermata(n, da=1):
    for stazione in range(da + 1, n + 1):
        attiva(etichetta=f"Prosegui alla schermata {stazione} di 4", tipo="pulsante", ascolto=2.5)


def ordina_per(voce_prefisso, scelta_prefisso, ascolto=6, intere="ogni"):
    """Apre la scelta del reparto dalla voce e sceglie. Restituisce l'esito della scelta."""
    attiva(prefisso=voce_prefisso, tipo="pulsante", ascolto=2.5)
    return attiva(prefisso=scelta_prefisso, tipo="pulsante", ascolto=ascolto, intere=intere)


def in_patria_in_primavera(nomi):
    return "Apri la campagna" in nomi and any(re.match(r"^Anno \d+, primavera$", n) for n in nomi)


# ------------------------------------------------------------------------------------------ partenza
def blocco_partenza():
    """Punti a e b: i nomi, dove va ciascuna formazione, la riga che è un comando col suggerimento, chi
    resta e chi riparte, il fuoco che non si muove, nessuna campagna senza un gruppo armato che parta."""
    e = regno_nuovo()
    controlla("patria: il fuoco d'apertura va al titolo", e.get("dopo", "").startswith("Patria"),
              "Patria Intestazione", sentito(e))
    troncate, piene = giro("patria-primavera")
    attese = patria_in_primavera()
    controlla_lettura("a: la patria in primavera letta per intero — data, campagna, riserve, le cinque formazioni "
                      "ciascuna col proprio nome e con dove va, i comandi", troncate, piene, attese)
    righe_dette = [p for p in piene if re.match(r"^(Corvo|Lupo|Falco|Orso|Cervo), ", p)]
    controlla("a: di ogni riga delle forze VoiceOver dice il nome, la categoria, i reparti, dove va, che è un "
              "pulsante, e il suggerimento", righe_dette == [riga(n) + " Pulsante " + SUGGERIMENTO for n in ORDINE],
              [riga(n) + " Pulsante " + SUGGERIMENTO for n in ORDINE], righe_dette)
    nomi = albero()
    controlla("a: nell'albero ogni formazione ha il proprio nome e dice dove va",
              all(riga(n) in nomi for n in ORDINE), [riga(n) for n in ORDINE],
              [n for n in nomi if " atomi di " in n])
    tipi = {x["etichetta"]: (x.get("tipo"), x.get("nomi_dei_tratti")) for x in elementi(contiene=" atomi di ")
            if x.get("tipo") != "testo" or x["etichetta"] not in [riga(n) for n in ORDINE]}
    controlla("a: in primavera, prima di aprire la campagna, ogni riga è un comando (tipo e tratto dell'istantanea)",
              all(tipi.get(riga(n), ("", []))[0] == "pulsante" and "pulsante" in (tipi.get(riga(n), ("", []))[1] or [])
                  for n in ORDINE),
              {riga(n): ["pulsante", ["pulsante"]] for n in ORDINE}, {k: list(v) for k, v in tipi.items()})

    # Cervo resta in patria: la conferma, la riga, il fuoco.
    e = attiva(prefisso="Cervo,", tipo="pulsante", ascolto=5, pausa_fuoco=1.0, fuoco_intero=True)
    controlla("a: toccata, la riga di Cervo si legge col suggerimento prima di attivarla",
              e.get("fuoco_intero") == riga("Cervo") + " Pulsante " + SUGGERIMENTO,
              riga("Cervo") + " Pulsante " + SUGGERIMENTO, e.get("fuoco_intero") or e.get("fuoco"))
    controlla("a: attivata, VoiceOver dice «Cervo resta in patria.»",
              "Cervo resta in patria." in intere(e) or "Cervo resta in patria." in e.get("ascoltate", []),
              "Cervo resta in patria.", sentito(e))
    controlla("a: la conferma resta l'ultima cosa detta — nessuna pronuncia la supera",
              e.get("dopo") == "Cervo resta in patria.", "Cervo resta in patria.", e.get("dopo"),
              ascoltate=e.get("ascoltate"), istanti=e.get("ascoltate_t"))
    nomi = albero()
    controlla("a: la riga diventa «… Resta in patria»", riga("Cervo", False) in nomi and riga("Cervo") not in nomi,
              riga("Cervo", False), [n for n in nomi if n.startswith("Cervo,")])
    qui, dopo = rilettura()
    controlla("a: il fuoco resta sulla riga — avanti il comando che segue, indietro la riga, con la destinazione nuova",
              dopo.startswith("Apri la campagna") and qui == riga("Cervo", False) + " Pulsante " + SUGGERIMENTO,
              ["Apri la campagna Pulsante (avanti)", riga("Cervo", False) + " Pulsante " + SUGGERIMENTO + " (indietro)"],
              [dopo, qui])
    schermata("patria-cervo-resta")
    e = attiva(prefisso="Cervo,", tipo="pulsante", ascolto=5)
    nomi = albero()
    controlla("a: riattivata, VoiceOver dice «Cervo parte per il fronte.» e la riga torna «… Parte per il fronte»",
              ("Cervo parte per il fronte." in intere(e) or "Cervo parte per il fronte." in e.get("ascoltate", []))
              and riga("Cervo") in nomi, ["Cervo parte per il fronte.", riga("Cervo")],
              [sentito(e)] + [n for n in nomi if n.startswith("Cervo,")])
    qui, dopo = rilettura()
    controlla("a: anche dopo la seconda attivazione il fuoco è sulla riga",
              dopo.startswith("Apri la campagna") and qui == riga("Cervo") + " Pulsante " + SUGGERIMENTO,
              ["Apri la campagna Pulsante (avanti)", riga("Cervo") + " Pulsante " + SUGGERIMENTO + " (indietro)"],
              [dopo, qui])

    # Tutti gli armati in patria: la campagna non si apre, e il gioco dice perché.
    dette = []
    for nome in ("Corvo", "Lupo", "Falco"):
        e = attiva(prefisso=nome + ",", tipo="pulsante", ascolto=4)
        dette.append(sentito(e))
    nomi = albero()
    controlla("b: i tre gruppi armati tenuti in patria, ciascuno confermato a voce",
              all(f"{n} resta in patria." in d for n, d in zip(("Corvo", "Lupo", "Falco"), dette))
              and all(riga(n, False) in nomi for n in ("Corvo", "Lupo", "Falco")),
              ["Corvo resta in patria.", "Lupo resta in patria.", "Falco resta in patria."], dette)
    schermata("patria-armati-in-patria")
    e1 = attiva(etichetta="Apri la campagna", tipo="pulsante", ascolto=3)
    nomi = albero()
    pannello = "Su quale fronte?" in nomi
    e = attiva(etichetta=FRONTE, tipo="pulsante", ascolto=8) if pannello else e1
    nomi = albero()
    controlla("b: con tutti gli armati in patria si sente «nessun gruppo armato da mandare»",
              "nessun gruppo armato da mandare" in intere(e) + e.get("ascoltate", []),
              "nessun gruppo armato da mandare", sentito(e),
              come=("«Apri la campagna» apre la scelta del fronte; scelto il fronte, il rifiuto" if pannello
                    else "«Apri la campagna» rifiuta subito, senza la scelta del fronte"))
    controlla("b: nessuna campagna si apre — si resta in patria, con «Apri la campagna» ancora da premere",
              "Apri la campagna" in nomi and "Torna in patria" not in nomi
              and "Nessuna campagna aperta quest'anno" in nomi and not any(n.startswith("Entra nel") for n in nomi),
              ["Apri la campagna", "Nessuna campagna aperta quest'anno", "nessun «Torna in patria»"],
              [n for n in senza_doppi(nomi) if "campagna" in n.lower() or n.startswith("Torna") or n.startswith("Entra")])
    controlla_la_voce("voce: il rifiuto «nessun gruppo armato da mandare» non è superato prima di poter essere detto",
                      e, "nessun gruppo armato da mandare")


# ------------------------------------------------------------------------------------------ mappa
def blocco_mappa():
    """Punto c, prima parte: sulla mappa i gruppi hanno i nomi delle formazioni; chi è rimasto in patria
    non c'è. Partono Lupo, Falco e Orso; restano Corvo e Cervo."""
    if not in_patria_in_primavera(albero()):
        regno_nuovo()
    for nome, al_fronte in (("Corvo", False), ("Lupo", True), ("Falco", True), ("Orso", True), ("Cervo", False)):
        destina(nome, al_fronte)
    dove = destinazioni()
    controlla("c: la scelta di chi parte è quella voluta — Lupo, Falco e Orso al fronte, Corvo e Cervo in patria",
              dove == {"Corvo": False, "Lupo": True, "Falco": True, "Orso": True, "Cervo": False},
              {"Corvo": False, "Lupo": True, "Falco": True, "Orso": True, "Cervo": False}, dove)
    troncate, piene = giro("patria-chi-parte")
    righe = [riga(n, n in ("Lupo", "Falco", "Orso")) for n in ORDINE]
    controlla_lettura("c: la patria letta per intero dice di ciascuna formazione dove va",
                      troncate, piene, patria_in_primavera(righe=righe))
    e = apri_la_campagna(ascolto=10, intere=None)
    nomi = albero()
    propri = gruppi_propri(nomi)
    controlla("c: sulla mappa ci sono le formazioni partite, col nome che hanno in patria e con i loro reparti",
              {k: v[2].split(", tuo quartier")[0].split(", strada")[0].split(", bosco")[0] for k, v in propri.items()}
              == {n: SULLA_MAPPA[n] for n in ("Lupo", "Falco", "Orso")},
              {n: SULLA_MAPPA[n] for n in ("Lupo", "Falco", "Orso")}, {k: list(v) for k, v in propri.items()})
    controlla("c: chi è rimasto in patria sulla mappa non c'è",
              not any("Corvo" in n or "Cervo" in n for n in nomi) and "Torna in patria" in nomi,
              "nessuna casella nomina Corvo o Cervo", [n for n in nomi if "Corvo" in n or "Cervo" in n])
    controlla("campagna: all'apertura si sentono la campagna aperta, la mappa e lo stato",
              any(a.startswith("Campagna aperta sul fronte del guado") for a in e.get("ascoltate", []))
              and any(a.startswith("Mappa Guado, 4 righe per 4 caselle") for a in e.get("ascoltate", [])),
              ["Campagna aperta sul fronte del guado", "Mappa Guado, 4 righe per 4 caselle. Il tuo quartier generale è in riga 4, casella 2", "Anno 1, primavera, mancano 89 giornate all'inverno. Giorno 1. …"],
              e.get("ascoltate"), istanti=e.get("ascoltate_t"))
    if "Lupo" in propri:
        r, c, _ = propri["Lupo"]
        e = cmd({"azione": "tocca", "prefisso": f"riga {r}, casella {c},", "ascolto": 1.5, "intere": "fine"})
        detta = (intere(e) or [e.get("dopo", "")])[-1]
        controlla("c: toccata la casella, VoiceOver dice il nome della formazione e i suoi reparti",
                  detta.startswith(f"riga {r}, casella {c}, tuo Lupo, {SULLA_MAPPA['Lupo']}"),
                  f"riga {r}, casella {c}, tuo Lupo, {SULLA_MAPPA['Lupo']} …", detta)
    s = tocco_magico("Registro della campagna")
    controlla("campagna: il tocco magico dice la data e quanti gruppi ci sono — tre",
              "Anno 1, primavera, mancano 89 giornate all'inverno. Giorno 1. Nessun gruppo ha ancora agito, sono 3" in s,
              "Anno 1, primavera, mancano 89 giornate all'inverno. Giorno 1. Nessun gruppo ha ancora agito, sono 3", s)
    schermata("mappa-chi-parte")

    # LA MISURA DELLA VOCE. La conferma della chiusura è interrompente; il fatto che la segue («Giornata
    # conclusa: comincia il giorno 2») parte quando VoiceOver notifica che la conferma è conclusa. Il tempo
    # fra le due è quello che VoiceOver impiega a dire la conferma, e dà i caratteri al secondo.
    e = attiva(etichetta="Chiudi la giornata", tipo="pulsante", ascolto=16, quiete=11, intere=None)
    dette, istanti = e.get("ascoltate", []), e.get("ascoltate_t", [])
    conferma = "Giornata chiusa. 3 gruppi non avevano agito e restano fermi: ne è stata conservata una traccia accanto al salvataggio."
    i = next((k for k, d in enumerate(dette) if d.startswith("Giornata chiusa.")), None)
    j = next((k for k, d in enumerate(dette) if d.startswith("Giornata conclusa: comincia il giorno 2")), None)
    durata = round(istanti[j] - istanti[i], 2) if i is not None and j is not None else None
    controlla("misura: quanto VoiceOver impiega a dire la conferma della chiusura (118 caratteri), e i caratteri al secondo",
              durata is not None and durata > 0, "«Giornata chiusa. …» e poi «Giornata conclusa: comincia il giorno 2»",
              {"secondi": durata, "caratteri": len(conferma),
               "caratteri_al_secondo": round(len(conferma) / durata, 1) if durata else None},
              ascoltate=dette, istanti=istanti)

    # Tornati in patria a campagna aperta, le righe sono testo e dicono dove sta ciascuna formazione.
    e = attiva(etichetta="Torna in patria", tipo="pulsante", ascolto=4)
    nomi = albero()
    controlla("c: tornati in patria la campagna è aperta e la data è quella del fronte",
              "Anno 1, primavera, giorno 2 di 90" in nomi and "Entra nel fronte del guado" in nomi,
              ["Anno 1, primavera, giorno 2 di 90", "Entra nel fronte del guado"],
              [n for n in senza_doppi(nomi) if n.startswith("Anno") or "fronte" in n])
    tipi = {x["etichetta"]: x.get("tipo") for x in elementi(contiene=" atomi di ")}
    controlla("c: a campagna aperta le righe delle forze sono testo, non comandi, e dicono ancora dove va ciascuna",
              all(tipi.get(r) == "testo" for r in righe), {r: "testo" for r in righe}, tipi)


# ------------------------------------------------------------------------------------------ inverno
def blocco_inverno():
    """Punti e, f, g (prima parte) e h (l'ordine): l'annuncio dell'inverno col mantenimento, la prima
    schermata che lo dichiara, le linguette, la scelta del reparto, le stagioni che cambiano con la
    schermata, la leva ordinata alla quarta, la primavera con ciò che ne nasce."""
    regno_nuovo()
    e = attiva(etichetta="Attendi l'inverno", tipo="pulsante", ascolto=12, intere="ogni")
    annuncio = ANNUNCIO_INVERNO.format(anno=1)
    controlla("e: l'annuncio dell'inverno porta l'entrata e il mantenimento (pronuncia intera)",
              annuncio in intere(e), annuncio, intere(e) or e.get("ascoltate"))
    controlla("inverno: è una schermata nuova, il fuoco va in testa alla data",
              e.get("dopo", "").startswith("Anno 1, inverno, schermata 1 di 4"), "Anno 1, inverno, schermata 1 di 4",
              e.get("dopo"))
    controlla_la_voce("voce: l'annuncio dell'inverno non è superato prima di poter essere detto", e, annuncio)
    troncate, piene = giro("inverno-prima-schermata")
    attese = prima_schermata_dell_inverno()
    controlla_lettura("e, f: la prima schermata dell'inverno letta per intero, fino all'ultimo comando",
                      troncate, piene, attese)
    letta = [p or t for p, t in zip(piene + [""] * len(troncate), troncate)]
    posto = next((i for i, x in enumerate(letta) if x.startswith("Mantenimento dell'esercito, prelevato")), -1)
    controlla("e: la prima schermata dichiara il mantenimento subito dopo le riserve, prima delle forze",
              posto > 0 and letta[posto - 1] == "animali: 13" and letta[posto] == MANTENIMENTO
              and letta[posto + 1] == "Forze Intestazione",
              ["animali: 13", MANTENIMENTO, "Forze Intestazione"], letta[max(0, posto - 1):posto + 2])
    nomi = albero()
    controlla("e: le riserve sono già diminuite del mantenimento — 193 monete al primo inverno",
              all(x in nomi for x in riserve_lette((193, 26, 33, 33, 13))), riserve_lette((193, 26, 33, 33, 13)),
              [n for n in nomi if re.match(r"^[a-z' ]+: \d+$", n)])
    intestazioni = [x for x in letta if x.endswith(" Intestazione")]
    controlla("f: le tre linguette, in quest'ordine, VoiceOver le dice intestazioni",
              [x for x in intestazioni if x[:-len(" Intestazione")] in LINGUETTE] == [x + " Intestazione" for x in LINGUETTE],
              [x + " Intestazione" for x in LINGUETTE], intestazioni)
    sotto = {}
    corrente = None
    for x in letta:
        if x.endswith(" Intestazione"):
            corrente = x[:-len(" Intestazione")]
        elif corrente in LINGUETTE and x.endswith(" Pulsante"):
            sotto.setdefault(corrente, []).append(x.split(".")[0])
    controlla("f: sotto ciascuna linguetta stanno le sue voci — la cavalleria fra i lunghi, la fanteria pesante "
              "fra i medi, la leggera, l'addestramento e il suo mantenimento fra i brevi",
              sotto == {"Lavori lunghi": ["Leva di cavalleria manovrata"], "Lavori di media durata": ["Leva di fanteria pesante"],
                        "Lavori brevi": ["Leva di fanteria leggera", "Addestramento mirato", "Mantenimento dell'addestramento mirato"]},
              {"Lavori lunghi": ["Leva di cavalleria manovrata"], "Lavori di media durata": ["Leva di fanteria pesante"],
               "Lavori brevi": ["Leva di fanteria leggera", "Addestramento mirato", "Mantenimento dell'addestramento mirato"]},
              sotto)
    tratti = {x["etichetta"]: x.get("nomi_dei_tratti") for x in elementi(prefisso="Lavori ")}
    controlla("f: l'istantanea dà alle tre linguette il tratto d'intestazione",
              all("intestazione" in (tratti.get(x) or []) for x in LINGUETTE),
              {x: ["testo statico", "intestazione"] for x in LINGUETTE}, tratti)
    # Due schermate: toccato, l'elemento viene portato in vista (la lettura finisce in fondo alla colonna).
    cmd({"azione": "tocca", "prefisso": "Mantenimento dell'esercito, prelevato", "ascolto": 0.5})
    schermata("inverno-mantenimento")
    cmd({"azione": "tocca", "etichetta": "Lavori lunghi", "ascolto": 0.5})
    schermata("inverno-linguette")

    # Il rotore delle intestazioni: dal titolo, un salto dopo l'altro.
    cmd({"azione": "tocca", "etichetta": "Patria", "tipo": "testo", "ascolto": 0.5})
    scelto, rotori = False, []
    for _ in range(10):
        r = cmd({"azione": "tasto", "tasto": "destra", "modificatori": ["control", "option", "command"], "ascolto": 0.8})
        rotori.append(r.get("dopo", ""))
        if "Intestazioni" in r.get("dopo", ""):
            scelto = True
            break
    salti = []
    if scelto:
        for _ in range(9):
            r = cmd({"azione": "tasto", "tasto": "giu", "modificatori": ["control", "option", "command"], "ascolto": 0.8})
            salti.append(r.get("dopo", ""))
            if "non trovata" in r.get("dopo", ""):
                break
    attesi = ["Riserve Intestazione", "Forze Intestazione", "Lavori da ordinare Intestazione"] \
        + [x + " Intestazione" for x in LINGUETTE] + ["Lavori ordinati Intestazione"]
    controlla("f: il rotore delle intestazioni salta dal titolo alle intestazioni della schermata, linguette comprese, in ordine",
              scelto and salti[:len(attesi)] == attesi, attesi, salti, rotori=rotori)

    # La scelta del reparto.
    e = attiva(prefisso="Addestramento mirato.", tipo="pulsante", ascolto=4)
    controlla("g: la voce apre la scelta del reparto, e il fuoco va al suo titolo",
              e.get("dopo", "").startswith("Addestramento mirato. Intestazione"), "Addestramento mirato. Intestazione",
              sentito(e))
    troncate, piene = giro("scelta-del-reparto")
    controlla_lettura("g: la scelta letta per intero — titolo, domanda, una voce per reparto col costo sulla riserva "
                      "(e l'impedimento in testa dove il denaro non basta), il congedo",
                      troncate, piene, scelta_letta("Addestramento mirato.", SCELTE))
    # Una scelta impedita: si può toccare, e il gioco dice che cosa manca.
    e = attiva(prefisso="Falco: 24 atomi di fanteria pesante.", tipo="pulsante", ascolto=7)
    rifiuto = "Non si può ordinare: mancano monete di bronzo."
    nomi = albero()
    controlla("g: toccata una scelta che il denaro non copre, si sente «Non si può ordinare: mancano monete di bronzo.»",
              rifiuto in intere(e) + e.get("ascoltate", []), rifiuto, sentito(e))
    controlla("g: il rifiuto non cambia nulla — 193 monete, nessun lavoro ordinato, e si è di nuovo in patria",
              "monete di bronzo: 193" in nomi and "Nessun lavoro ordinato in questo inverno" in nomi
              and "Per quale reparto?" not in nomi,
              ["monete di bronzo: 193", "Nessun lavoro ordinato in questo inverno"],
              [n for n in nomi if n.startswith("monete") or "lavoro" in n or n == "Per quale reparto?"])
    qui, dopo = rilettura()
    controlla("g: dopo il rifiuto il fuoco è sulla voce da cui si era partiti",
              qui == ADDESTRAMENTO + " Pulsante" and dopo.startswith("Mantenimento dell'addestramento mirato."),
              [ADDESTRAMENTO + " Pulsante (indietro)", "Mantenimento dell'addestramento mirato. … (avanti)"], [qui, dopo])
    controlla_la_voce("voce: il rifiuto della scelta impedita non è superato prima di poter essere detto", e, rifiuto)
    # La scelta buona: gli 8 atomi di fanteria pesante di Lupo.
    e = ordina_per("Addestramento mirato.", "Lupo: 8 atomi di fanteria pesante.", ascolto=9)
    conferma = "Addestramento mirato ordinato per 8 atomi di fanteria pesante di Lupo: pronto in primavera."
    controlla("g: scelto il reparto si sente «Addestramento mirato ordinato per 8 atomi di fanteria pesante di Lupo: "
              "pronto in primavera.»", come_sentito(e, conferma) is not None, conferma, intere(e) + e.get("ascoltate", []),
              sentito_per=come_sentito(e, conferma))
    qui, dopo = rilettura()
    controlla("g: il fuoco torna sulla voce da cui si era partiti",
              qui == ADDESTRAMENTO + " Pulsante" and dopo.startswith("Mantenimento dell'addestramento mirato."),
              [ADDESTRAMENTO + " Pulsante (indietro)", "Mantenimento dell'addestramento mirato. … (avanti)"], [qui, dopo])
    nomi = albero()
    lupo = "Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante, addestramento mirato in corso. Parte per il fronte"
    controlla("g: la riga di Lupo dice «…, addestramento mirato in corso», il lavoro è in elenco, restano 93 monete",
              lupo in nomi and "Addestramento mirato per 8 atomi di fanteria pesante di Lupo, pronto in primavera" in nomi
              and "monete di bronzo: 93" in nomi,
              [lupo, "Addestramento mirato per 8 atomi di fanteria pesante di Lupo, pronto in primavera", "monete di bronzo: 93"],
              [n for n in nomi if n.startswith("Lupo,") or n.startswith("Addestramento mirato per") or n.startswith("monete")])
    controlla_la_voce("voce: la conferma dell'addestramento non è superata prima di poter essere detta", e, conferma)
    schermata("inverno-dopo-l-addestramento")
    # Lo stesso reparto non si addestra due volte nello stesso inverno.
    attiva(prefisso="Addestramento mirato.", tipo="pulsante", ascolto=2.5)
    nomi = albero()
    scelte = [n for n in senza_doppi(nomi) if re.match(r"^\w+: \d+ atomi di ", n)]
    controlla("g: riaperta la scelta, il reparto già in addestramento non c'è più, e i costi sono sulla riserva nuova",
              len(scelte) == 6 and not any(s.startswith("Lupo: 8 atomi di fanteria pesante") for s in scelte)
              and "Corvo: 6 atomi di fanteria leggera. Costa: monete di bronzo 75 su 93." in scelte,
              "sei scelte, senza «Lupo: 8 atomi di fanteria pesante», con «Corvo: … Costa: monete di bronzo 75 su 93.»", scelte)
    e = attiva(etichetta="Chiudi il pannello", tipo="pulsante", ascolto=3)
    qui, dopo = rilettura()
    controlla("g: chiuso il pannello senza scegliere, il fuoco torna sulla voce",
              qui == ADDESTRAMENTO + " Pulsante", ADDESTRAMENTO + " Pulsante", [qui, dopo])

    # Le schermate: il mantenimento lo dichiara soltanto la prima; le stagioni cambiano con la schermata.
    r = (93, 26, 33, 33, 13)
    nomi = albero()
    controlla("f: alla prima schermata la cavalleria è pronta in estate, la pesante e la leggera in primavera",
              all(v in nomi for v in voci_dell_inverno(1, r)), voci_dell_inverno(1, r),
              [n for n in senza_doppi(nomi) if n.startswith("Leva di") and "Costa" in n])
    for stazione in (2, 3, 4):
        e = attiva(etichetta=f"Prosegui alla schermata {stazione} di 4", tipo="pulsante", ascolto=3)
        nomi = albero()
        controlla(f"f: schermata {stazione} — si annuncia, e le leve dicono la stagione di questa schermata "
                  f"({', '.join(STAGIONI[stazione])})",
                  f"Inverno, schermata {stazione} di 4" in intere(e) + e.get("ascoltate", [])
                  and f"Anno 1, inverno, schermata {stazione} di 4" in nomi
                  and all(v in nomi for v in voci_dell_inverno(stazione, r)),
                  [f"Inverno, schermata {stazione} di 4"] + voci_dell_inverno(stazione, r),
                  [sentito(e)] + [n for n in senza_doppi(nomi) if n.startswith("Leva di") and "Costa" in n])
        if stazione == 2:
            controlla("e: nella seconda schermata la riga del mantenimento non c'è più",
                      not any(n.startswith("Mantenimento dell'esercito, prelevato") for n in nomi)
                      and [x for x in senza_doppi(nomi) if x in LINGUETTE] == LINGUETTE,
                      "nessuna riga «Mantenimento dell'esercito, prelevato …», e le tre linguette",
                      [n for n in senza_doppi(nomi) if n.startswith("Mantenimento dell'esercito") or n in LINGUETTE])
            attiva(etichetta="Registro della patria", tipo="pulsante", ascolto=3)
            troncate, piene = giro("registro-della-patria-inverno")
            controlla_lettura("e: il registro della patria annota il mantenimento prelevato",
                              troncate, piene,
                              ["Registro della patria Intestazione",
                               "Anno 1, inverno: prelevato il mantenimento dell'esercito, monete di bronzo 27",
                               "Anno 1, inverno: comincia l'inverno e arriva l'entrata dell'anno",
                               "Chiudi il registro Pulsante"])
            attiva(etichetta="Chiudi il registro", tipo="pulsante", ascolto=2.5)
    # Alla quarta schermata la leva di fanteria leggera è pronta in estate: arriverà a campagna aperta.
    e = attiva(prefisso="Leva di fanteria leggera.", tipo="pulsante", ascolto=5)
    nomi = albero()
    controlla("h: la leva ordinata alla quarta schermata si conferma «pronta in estate», ed entra in elenco così",
              "Leva di fanteria leggera ordinata: pronta in estate." in intere(e) + e.get("ascoltate", [])
              and "Leva di fanteria leggera, pronta in estate" in nomi and "monete di bronzo: 63" in nomi,
              ["Leva di fanteria leggera ordinata: pronta in estate.", "Leva di fanteria leggera, pronta in estate", "monete di bronzo: 63"],
              [sentito(e)] + [n for n in nomi if "pronta in estate" in n and "Costa" not in n or n.startswith("monete")])
    schermata("inverno-quarta-schermata")
    e = attiva(etichetta="Prosegui alla primavera", tipo="pulsante", ascolto=14, intere="ogni")
    # Il riporto: di ciascuna risorsa avanza un decimo dell'entrata (01 §5.5.1.4); le cifre che seguono sono
    # CALCOLATE A MANO da quella regola e dalle spese di questo percorso (100 monete, poi 30, 6 uomini, 3 metalli).
    annuncio = ("Comincia la primavera dell'anno 2. Il riporto ha tolto: monete di bronzo 43, uomini 18, metalli 27, "
                "materiale da costruzione 30, animali 12. Lince nasce dalle reclute dell'inverno, con 6 atomi di "
                "fanteria leggera, e raggiunge il quartier generale in estate, a campagna aperta. Lupo ha ora 8 atomi "
                "di fanteria pesante con addestramento mirato.")
    controlla("g, h: l'annuncio della primavera dice il riporto, le reclute che arriveranno in estate a campagna "
              "aperta, e il reparto che ha ora l'addestramento mirato (pronuncia intera)",
              annuncio in intere(e), annuncio, intere(e) or e.get("ascoltate"))
    controlla("primavera: è una schermata nuova, il fuoco va in testa alla data",
              e.get("dopo", "").startswith("Anno 2, primavera"), "Anno 2, primavera", e.get("dopo"))
    controlla_la_voce("voce: l'annuncio della primavera non è superato prima di poter essere detto", e, annuncio)
    troncate, piene = giro("patria-seconda-primavera")
    forze = dict(FORZE, Lupo="Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante con addestramento mirato")
    lince = "Lince, gruppo armato, reclute dell'inverno: 6 atomi di fanteria leggera. Raggiunge il quartier generale in estate, a campagna aperta"
    controlla_lettura("c, g, h: la patria della seconda primavera — gli stessi nomi nello stesso ordine, Lupo «con "
                      "addestramento mirato», e Lince che «Raggiunge il quartier generale in estate, a campagna aperta»",
                      troncate, piene,
                      patria_in_primavera(anno=2, righe=[riga(n, forze=forze) for n in ORDINE] + [lince]))
    attiva(etichetta="Registro della patria", tipo="pulsante", ascolto=3)
    troncate, piene = giro("registro-della-patria-primavera")
    controlla_lettura("registro della patria: i fatti dal più recente, con le reclute, il miglioramento e il mantenimento",
                      troncate, piene,
                      ["Registro della patria Intestazione",
                       "Anno 2, primavera: Lupo ha ora 8 atomi di fanteria pesante con addestramento mirato",
                       "Anno 2, primavera: Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, e raggiunge il quartier generale in estate, a campagna aperta",
                       "Anno 2, primavera: comincia la primavera; il riporto ha tolto ciò che eccedeva",
                       "Anno 1, inverno: prelevato il mantenimento dell'esercito, monete di bronzo 27",
                       "Anno 1, inverno: comincia l'inverno e arriva l'entrata dell'anno",
                       "Chiudi il registro Pulsante"])
    attiva(etichetta="Chiudi il registro", tipo="pulsante", ascolto=2.5)


# ------------------------------------------------------------------------------------------ estate
def prepara_la_seconda_primavera():
    """Senza controlli: un regno nuovo portato alla seconda primavera con l'addestramento mirato a Lupo e
    la leva di fanteria leggera ordinata alla quarta schermata. Serve a rilanciare «estate» da solo."""
    regno_nuovo()
    attiva(etichetta="Attendi l'inverno", tipo="pulsante", ascolto=3)
    ordina_per("Addestramento mirato.", "Lupo: 8 atomi di fanteria pesante.", ascolto=3)
    fino_alla_schermata(4)
    attiva(prefisso="Leva di fanteria leggera.", tipo="pulsante", ascolto=3)
    attiva(etichetta="Prosegui alla primavera", tipo="pulsante", ascolto=4)


def blocco_estate():
    """Punti h e i: il reparto migliorato sulla casella della mappa; trenta chiusure di giornata, e con
    la trentunesima l'estate e Lince che arriva dalla patria."""
    nomi = albero()
    if not ("Anno 2, primavera" in nomi and any(n.startswith("Lince, gruppo armato, reclute dell'inverno") for n in nomi)):
        prepara_la_seconda_primavera()
    e = apri_la_campagna(ascolto=6, intere=None)
    nomi = albero()
    propri = gruppi_propri(nomi)
    controlla("h: alla prima giornata Lince non è sulla mappa — ci sono le cinque formazioni di sempre, coi loro nomi",
              sorted(propri) == sorted(ORDINE), sorted(ORDINE), sorted(propri))
    lupo = propri.get("Lupo", (0, 0, ""))
    controlla("i: la casella di Lupo dichiara il reparto migliorato — «… 8 atomi di fanteria pesante con addestramento mirato»",
              "composta da 18 atomi di fanteria leggera, 8 atomi di fanteria pesante con addestramento mirato" in lupo[2],
              "tuo Lupo, in attesa, composta da 18 atomi di fanteria leggera, 8 atomi di fanteria pesante con addestramento mirato",
              list(lupo))
    if lupo[0]:
        e = cmd({"azione": "tocca", "prefisso": f"riga {lupo[0]}, casella {lupo[1]},", "ascolto": 1.5, "intere": "fine"})
        detta = (intere(e) or [e.get("dopo", "")])[-1]
        controlla("i: toccata la casella, VoiceOver dice «con addestramento mirato» (pronuncia intera)",
                  "8 atomi di fanteria pesante con addestramento mirato" in detta,
                  f"riga {lupo[0]}, casella {lupo[1]}, tuo Lupo, … 8 atomi di fanteria pesante con addestramento mirato …", detta)
    schermata("mappa-reparto-migliorato")
    # Ventinove chiusure: comincia il giorno 30. Ogni chiusura si conferma a voce («Giornata chiusa.»).
    chiuse, rifiutate = 0, []
    for _ in range(29):
        e = attiva(etichetta="Chiudi la giornata", tipo="pulsante", ascolto=1.5, intere=None)
        s = sentito(e)
        if "Giornata chiusa" in s:
            chiuse += 1
        else:
            rifiutate.append(s)
            if "battaglia" in s.lower():
                break
    s = tocco_magico("Registro della campagna")
    controlla("h: dopo ventinove chiusure il tocco magico dice il giorno 30, ultimo della primavera",
              "Anno 2, primavera, mancano 60 giornate all'inverno. Giorno 30." in s,
              "Anno 2, primavera, mancano 60 giornate all'inverno. Giorno 30. …", s, chiusure_confermate=chiuse,
              non_confermate=rifiutate)
    # La trentesima chiusura apre la trentunesima giornata: l'estate, e l'arrivo dalla patria.
    e = attiva(etichetta="Chiudi la giornata", tipo="pulsante", ascolto=45, quiete=11)
    dette = intere(e) + e.get("ascoltate", [])
    arrivo = next((re.match(r"^Lince è arrivata dalla patria in riga (\d+), casella (\d+)$", d) for d in dette
                   if re.match(r"^Lince è arrivata dalla patria in riga (\d+), casella (\d+)$", d)), None)
    controlla("h: aperta la trentunesima giornata si sentono «Giornata conclusa: comincia il giorno 31», «Nuova "
              "stagione: estate» e «Lince è arrivata dalla patria in riga …, casella …»",
              "Giornata conclusa: comincia il giorno 31" in dette and "Nuova stagione: estate" in dette and arrivo is not None,
              ["Giornata conclusa: comincia il giorno 31", "Nuova stagione: estate", "Lince è arrivata dalla patria in riga …, casella …"],
              e.get("ascoltate"), intere=intere(e), istanti=e.get("ascoltate_t"))
    nomi = albero()
    propri = gruppi_propri(nomi)
    lince = propri.get("Lince")
    controlla("h: Lince è sulla mappa, nella casella che l'annuncio ha detto, e attende una decisione",
              lince is not None and arrivo is not None and (lince[0], lince[1]) == (int(arrivo.group(1)), int(arrivo.group(2)))
              and lince[2].startswith(SULLA_MAPPA["Lince"]),
              f"riga {arrivo.group(1) if arrivo else '…'}, casella {arrivo.group(2) if arrivo else '…'}, tua Lince, {SULLA_MAPPA['Lince']}",
              list(lince) if lince else sorted(propri))
    schermata("mappa-con-l-arrivo")
    attiva(etichetta="Registro della campagna", tipo="pulsante", ascolto=3)
    troncate, piene = giro("registro-della-campagna-arrivo")
    voci = [p or t for p, t in zip(piene + [""] * len(troncate), troncate)]
    atteso = f"Giorno 31: Lince è arrivata dalla patria in riga {arrivo.group(1)}, casella {arrivo.group(2)}" if arrivo else "Giorno 31: Lince è arrivata dalla patria in riga …, casella …"
    controlla("h: il registro della campagna annota la stagione nuova e l'arrivo, col luogo",
              any(v.startswith(atteso) for v in voci) and any(v.startswith("Giorno 31: nuova stagione, estate") for v in voci),
              [atteso, "Giorno 31: nuova stagione, estate"], voci[:8])
    attiva(etichetta="Chiudi il registro", tipo="pulsante", ascolto=2.5)
    e = attiva(etichetta="Torna in patria", tipo="pulsante", ascolto=4)
    nomi = albero()
    controlla("h: tornati in patria la data è quella del fronte — estate, giorno 31",
              "Anno 2, estate, giorno 31 di 90" in nomi, "Anno 2, estate, giorno 31 di 90",
              [n for n in senza_doppi(nomi) if n.startswith("Anno")])
    riga_lince = next((n for n in nomi if n.startswith("Lince,")), "")
    controlla("osservazione: che cosa dice la riga di Lince in patria dopo che è arrivata sul fronte",
              "Raggiunge il quartier generale in estate" not in riga_lince,
              "una riga che non parli più dell'arrivo come di un fatto a venire", riga_lince)


# ------------------------------------------------------------------------------------------ reclute
def blocco_reclute():
    """Punto d: le reclute pronte in primavera dichiarano dove e come entrano — nell'annuncio, nella riga
    in patria, e sulla mappa nel registro della campagna."""
    regno_nuovo()
    attiva(etichetta="Attendi l'inverno", tipo="pulsante", ascolto=3)
    e = attiva(prefisso="Leva di fanteria leggera.", tipo="pulsante", ascolto=5)
    controlla("d: la leva ordinata alla prima schermata si conferma «pronta in primavera», e la conferma resta "
              "l'ultima cosa detta",
              "Leva di fanteria leggera ordinata: pronta in primavera." in intere(e) + e.get("ascoltate", [])
              and e.get("dopo") == "Leva di fanteria leggera ordinata: pronta in primavera.",
              "Leva di fanteria leggera ordinata: pronta in primavera.", sentito(e))
    qui, dopo = rilettura()
    controlla("d: dopo la spesa il fuoco resta sulla voce, che si rilegge col costo sulla riserva nuova",
              qui == LEGGERA.format(d=163, u=20, m=30, s="primavera") + " Pulsante" and dopo.startswith("Addestramento mirato."),
              [LEGGERA.format(d=163, u=20, m=30, s="primavera") + " Pulsante (indietro)", "Addestramento mirato. … (avanti)"],
              [qui, dopo])
    fino_alla_schermata(4)
    e = attiva(etichetta="Prosegui alla primavera", tipo="pulsante", ascolto=14, intere="ogni")
    annuncio = ("Comincia la primavera dell'anno 2. Il riporto ha tolto: monete di bronzo 143, uomini 18, metalli 27, "
                "materiale da costruzione 30, animali 12. Lince nasce dalle reclute dell'inverno, con 6 atomi di "
                "fanteria leggera, ed entra sul fronte in primavera, al quartier generale.")
    controlla("d: l'annuncio della primavera dice che Lince nasce dalle reclute ed entra sul fronte in primavera, "
              "al quartier generale (pronuncia intera)", annuncio in intere(e), annuncio, intere(e) or e.get("ascoltate"))
    controlla_la_voce("voce: l'annuncio della primavera con le reclute non è superato prima di poter essere detto", e, annuncio)
    troncate, piene = giro("patria-primavera-con-le-reclute")
    lince = "Lince, gruppo armato, reclute dell'inverno: 6 atomi di fanteria leggera. Entra sul fronte in primavera, al quartier generale"
    controlla_lettura("c, d: la patria della seconda primavera — i nomi di prima, e Lince che «Entra sul fronte in "
                      "primavera, al quartier generale»", troncate, piene,
                      patria_in_primavera(anno=2, righe=[riga(n) for n in ORDINE] + [lince]))
    attiva(etichetta="Registro della patria", tipo="pulsante", ascolto=3)
    troncate, piene = giro()
    controlla_lettura("d: il registro della patria annota la nascita di Lince, con dove e quando entra",
                      troncate, piene,
                      ["Registro della patria Intestazione",
                       "Anno 2, primavera: Lince nasce dalle reclute dell'inverno, con 6 atomi di fanteria leggera, ed entra sul fronte in primavera, al quartier generale",
                       "Anno 2, primavera: comincia la primavera; il riporto ha tolto ciò che eccedeva",
                       "Anno 1, inverno: prelevato il mantenimento dell'esercito, monete di bronzo 27",
                       "Anno 1, inverno: comincia l'inverno e arriva l'entrata dell'anno",
                       "Chiudi il registro Pulsante"])
    attiva(etichetta="Chiudi il registro", tipo="pulsante", ascolto=2.5)
    e = apri_la_campagna(ascolto=24, intere=None)
    nomi = albero()
    propri = gruppi_propri(nomi)
    lince = propri.get("Lince")
    controlla("d: sulla mappa, alla prima giornata, ci sono le cinque formazioni e Lince, ciascuna col suo nome",
              sorted(propri) == sorted(ORDINE + ["Lince"]) and lince is not None and lince[2].startswith(SULLA_MAPPA["Lince"]),
              sorted(ORDINE + ["Lince"]), {k: list(v) for k, v in propri.items()})
    controlla("osservazione: che cosa si sente all'apertura della campagna in cui entrano le reclute",
              True, "la campagna aperta, la mappa, lo stato; l'arrivo di Lince se il gioco lo annuncia",
              e.get("ascoltate"), intere=intere(e), istanti=e.get("ascoltate_t"))
    schermata("mappa-con-le-reclute")
    attiva(etichetta="Registro della campagna", tipo="pulsante", ascolto=3)
    troncate, piene = giro("registro-della-campagna-reclute")
    voci = [p or t for p, t in zip(piene + [""] * len(troncate), troncate)]
    atteso = f"Giorno 1: Lince è arrivata dalla patria in riga {lince[0]}, casella {lince[1]}" if lince else "Giorno 1: Lince è arrivata dalla patria in riga …, casella …"
    controlla("d: il registro della campagna annota «Giorno 1: Lince è arrivata dalla patria in riga …, casella …», "
              "nella casella in cui Lince sta", any(v.startswith(atteso) for v in voci), atteso, voci)
    attiva(etichetta="Chiudi il registro", tipo="pulsante", ascolto=2.5)


# ------------------------------------------------------------------------------------------ mantenimento
def blocco_mantenimento():
    """Punto g, seconda parte: l'inverno dopo il miglioramento va mantenuto; pagato, resta; non pagato,
    la primavera dice che lo si è perduto. Due reparti addestrati, uno mantenuto e uno no."""
    regno_nuovo()
    attiva(etichetta="Attendi l'inverno", tipo="pulsante", ascolto=3)
    e1 = ordina_per("Addestramento mirato.", "Lupo: 8 atomi di fanteria pesante.", ascolto=4)
    e2 = ordina_per("Addestramento mirato.", "Corvo: 6 atomi di fanteria leggera.", ascolto=4, intere=None)
    nomi = albero()
    controlla("g: due addestramenti ordinati nello stesso inverno, ciascuno confermato a voce — restano 18 monete "
              "(193 meno 100 meno 75: calcolato a mano)",
              come_sentito(e1, "Addestramento mirato ordinato per 8 atomi di fanteria pesante di Lupo: pronto in primavera.") is not None
              and come_sentito(e2, "Addestramento mirato ordinato per 6 atomi di fanteria leggera di Corvo: pronto in primavera.") is not None
              and "monete di bronzo: 18" in nomi,
              ["Addestramento mirato ordinato per 8 atomi di fanteria pesante di Lupo: pronto in primavera.",
               "Addestramento mirato ordinato per 6 atomi di fanteria leggera di Corvo: pronto in primavera.", "monete di bronzo: 18"],
              intere(e1) + e1.get("ascoltate", []) + intere(e2) + e2.get("ascoltate", []) + [n for n in nomi if n.startswith("monete")],
              sentito_per=[come_sentito(e1, "Addestramento mirato ordinato per 8 atomi di fanteria pesante di Lupo: pronto in primavera."),
                           come_sentito(e2, "Addestramento mirato ordinato per 6 atomi di fanteria leggera di Corvo: pronto in primavera.")])
    controlla_la_voce("voce: la conferma dell'addestramento di Corvo (ascolto semplice) non è superata prima di poter essere detta",
                      e2, "Addestramento mirato ordinato per 6 atomi di fanteria leggera di Corvo: pronto in primavera.")
    fino_alla_schermata(4)
    e = attiva(etichetta="Prosegui alla primavera", tipo="pulsante", ascolto=14, intere="ogni")
    detto = " ".join(intere(e))
    controlla("g: la primavera dice che i due reparti hanno ora l'addestramento mirato (pronuncia intera)",
              "Lupo ha ora 8 atomi di fanteria pesante con addestramento mirato." in detto
              and "Corvo ha ora 6 atomi di fanteria leggera con addestramento mirato." in detto,
              ["… Lupo ha ora 8 atomi di fanteria pesante con addestramento mirato.", "… Corvo ha ora 6 atomi di fanteria leggera con addestramento mirato."],
              intere(e) or e.get("ascoltate"))
    forze = dict(FORZE, Corvo="Corvo, gruppo armato: 6 atomi di fanteria leggera con addestramento mirato",
                 Lupo="Lupo, gruppo armato: 18 atomi di fanteria leggera, 8 atomi di fanteria pesante con addestramento mirato")
    nomi = albero()
    controlla("g: in primavera le righe dicono «con addestramento mirato»",
              riga("Corvo", forze=forze) in nomi and riga("Lupo", forze=forze) in nomi,
              [riga("Corvo", forze=forze), riga("Lupo", forze=forze)],
              [n for n in nomi if n.startswith("Corvo,") or n.startswith("Lupo,")])
    # Il secondo inverno, senza campagna.
    e = attiva(etichetta="Attendi l'inverno", tipo="pulsante", ascolto=12, intere="ogni")
    controlla("e: anche il secondo inverno si annuncia col mantenimento (pronuncia intera)",
              ANNUNCIO_INVERNO.format(anno=2) in intere(e), ANNUNCIO_INVERNO.format(anno=2), intere(e) or e.get("ascoltate"))
    nomi = albero()
    da_mantenere = {n: riga(n, forze={n: forze[n] + ", da mantenere entro l'inverno"}) for n in ("Corvo", "Lupo")}
    controlla("g: l'inverno dopo, le righe dei due reparti dicono «…, da mantenere entro l'inverno»",
              all(v in nomi for v in da_mantenere.values()), list(da_mantenere.values()),
              [n for n in nomi if n.startswith("Corvo,") or n.startswith("Lupo,")])
    controlla("g: la voce del mantenimento ha ora reparti su cui agire — «Si sceglie il reparto.»",
              MANTIENI in nomi, MANTIENI, [n for n in senza_doppi(nomi) if n.startswith("Mantenimento dell'addestramento")])
    e = attiva(prefisso="Mantenimento dell'addestramento mirato.", tipo="pulsante", ascolto=4)
    troncate, piene = giro("scelta-del-mantenimento")
    # 191 monete: le 18 riportate, più le 200 della rendita, meno le 27 del mantenimento (calcolato a mano).
    controlla_lettura("g: la scelta del mantenimento letta per intero — i due reparti migliorati, col costo sulla riserva",
                      troncate, piene,
                      scelta_letta("Mantenimento dell'addestramento mirato.",
                                   ["Corvo: 6 atomi di fanteria leggera con addestramento mirato. Costa: monete di bronzo 6 su 191.",
                                    "Lupo: 8 atomi di fanteria pesante con addestramento mirato. Costa: monete di bronzo 8 su 191."]))
    e = attiva(prefisso="Lupo: 8 atomi di fanteria pesante con addestramento mirato.", tipo="pulsante", ascolto=9, intere="ogni")
    conferma = "Mantenimento dell'addestramento mirato ordinato per 8 atomi di fanteria pesante con addestramento mirato di Lupo: pronto in primavera."
    nomi = albero()
    pagato = riga("Lupo", forze={"Lupo": forze["Lupo"] + ", mantenimento pagato"})
    controlla("g: pagato il mantenimento si sente la conferma, e la riga di Lupo dice «…, mantenimento pagato»",
              come_sentito(e, conferma) is not None and pagato in nomi and da_mantenere["Corvo"] in nomi,
              [conferma, pagato, da_mantenere["Corvo"]],
              intere(e) + e.get("ascoltate", []) + [n for n in nomi if n.startswith("Corvo,") or n.startswith("Lupo,")],
              sentito_per=come_sentito(e, conferma))
    qui, dopo = rilettura()
    controlla("g: il fuoco torna sulla voce del mantenimento",
              qui == MANTIENI + " Pulsante", MANTIENI + " Pulsante", [qui, dopo])
    controlla_la_voce("voce: la conferma del mantenimento non è superata prima di poter essere detta", e, conferma)
    schermata("inverno-mantenimento-pagato")
    fino_alla_schermata(4)
    e = attiva(etichetta="Prosegui alla primavera", tipo="pulsante", ascolto=14, intere="ogni")
    detto = " ".join(intere(e))
    perduto = "Corvo ha 6 atomi di fanteria leggera senza più addestramento mirato, per mancato mantenimento."
    controlla("g: senza mantenimento la primavera dice che Corvo lo ha perduto, e di Lupo non lo dice (pronuncia intera)",
              perduto in detto and "Lupo ha 8 atomi di fanteria pesante senza più" not in detto,
              "… " + perduto, intere(e) or e.get("ascoltate"))
    nomi = albero()
    controlla("g: nella terza primavera Corvo è tornato com'era, Lupo ha ancora l'addestramento mirato, e i nomi "
              "sono quelli del primo anno",
              riga("Corvo") in nomi and riga("Lupo", forze=forze) in nomi
              and [n.split(",")[0] for n in senza_doppi(nomi) if " atomi di " in n and ". " in n] == ORDINE,
              [riga("Corvo"), riga("Lupo", forze=forze)] + ORDINE,
              [n for n in senza_doppi(nomi) if " atomi di " in n])
    schermata("patria-terza-primavera")


# ------------------------------------------------------------------------------------------ voce
def blocco_voce():
    """UNA MISURA, SENZA COPIE NEGLI APPUNTI: per quanto un annuncio resta la pronuncia corrente quando lo
    accompagna uno spostamento del fuoco (l'inverno e la primavera, che portano il fuoco in testa alla
    data; la scelta del reparto, che lo riporta sulla voce), a confronto con un annuncio che non sposta
    nulla (la leva). La copia dà a VoiceOver un comando da tastiera e altera ciò che sta dicendo — con le
    copie accese, all'apertura della campagna l'annuncio della mappa non è comparso —: qui il pilota ascolta
    soltanto, una lettura ogni quarto di secondo. In coda, la coda degli annunci del gioco all'apertura
    della campagna: il secondo annuncio parte soltanto quando VoiceOver notifica concluso il primo."""
    regno_nuovo()
    e = attiva(etichetta="Attendi l'inverno", tipo="pulsante", ascolto=12)
    controlla_la_voce("voce, senza copie: l'annuncio dell'inverno non è superato prima di poter essere detto",
                      e, ANNUNCIO_INVERNO.format(anno=1))
    attiva(prefisso="Addestramento mirato.", tipo="pulsante", ascolto=2.5)
    e = attiva(prefisso="Falco: 24 atomi di fanteria pesante.", tipo="pulsante", ascolto=8)
    controlla_la_voce("voce, senza copie: il rifiuto della scelta impedita non è superato prima di poter essere detto",
                      e, "Non si può ordinare: mancano monete di bronzo.")
    e = ordina_per("Addestramento mirato.", "Lupo: 8 atomi di fanteria pesante.", ascolto=10, intere=None)
    controlla_la_voce("voce, senza copie: la conferma dell'addestramento non è superata prima di poter essere detta",
                      e, "Addestramento mirato ordinato per 8 atomi di fanteria pesante di Lupo: pronto in primavera.")
    e = attiva(prefisso="Leva di fanteria leggera.", tipo="pulsante", ascolto=8)
    controlla_la_voce("voce, senza copie: la conferma di una leva, che non sposta il fuoco, resta la pronuncia corrente",
                      e, "Leva di fanteria leggera ordinata: pronta in primavera.")
    fino_alla_schermata(4)
    e = attiva(etichetta="Prosegui alla primavera", tipo="pulsante", ascolto=16)
    # Il testo atteso serve qui per la sua lunghezza: senza copie se ne sente l'inizio (64 caratteri). Le
    # cifre del riporto sono calcolate a mano come nel blocco «inverno» (100 monete, poi 30, 6 uomini, 3 metalli).
    controlla_la_voce("voce, senza copie: l'annuncio della primavera non è superato prima di poter essere detto", e,
                      "Comincia la primavera dell'anno 2. Il riporto ha tolto: monete di bronzo 43, uomini 18, metalli 27, "
                      "materiale da costruzione 30, animali 12. Lince nasce dalle reclute dell'inverno, con 6 atomi di "
                      "fanteria leggera, ed entra sul fronte in primavera, al quartier generale. Lupo ha ora 8 atomi di "
                      "fanteria pesante con addestramento mirato.")
    e = apri_la_campagna(ascolto=14, intere=None)
    dette, istanti = e.get("ascoltate", []), e.get("ascoltate_t", [])
    primo = "Campagna aperta sul fronte del guado"
    i = dette.index(primo) if primo in dette else None
    durata = round(istanti[i + 1] - istanti[i], 2) if i is not None and i + 1 < len(dette) else None
    controlla("misura, senza copie: all'apertura della campagna, dopo quanto il primo annuncio in coda («Campagna "
              "aperta sul fronte del guado», 36 caratteri) cede il posto al successivo — che il gioco manda soltanto "
              "quando VoiceOver notifica concluso il primo",
              durata is not None, "«Campagna aperta sul fronte del guado», poi l'annuncio successivo della coda",
              {"secondi_fra_il_primo_e_il_successivo": durata, "caratteri_del_primo": len(primo),
               "successivo": dette[i + 1] if durata is not None else None},
              ascoltate=dette, istanti=istanti, doppio_tocco_s=e.get("doppio_tocco_s"))


# ------------------------------------------------------------------------------------------ orizzontale
def blocco_orizzontale():
    """La patria in primavera e d'inverno, e la scelta del reparto, con l'apparecchio in orizzontale:
    VoiceOver le legge nello stesso ordine e per intero. Soltanto la LETTURA: in orizzontale il pilota non
    sa attivare nulla (incarichi 28 e 30), e l'attivazione la copre col tocco vero `FumoRegnoTest`."""
    regno_nuovo()
    cmd({"azione": "orientamento", "verso": "orizzontale", "ascolto": 2.5})
    try:
        troncate, piene = giro("patria-primavera-orizzontale")
        controlla_lettura("orizzontale: la patria in primavera letta per intero, nello stesso ordine",
                          troncate, piene, patria_in_primavera())
    finally:
        cmd({"azione": "orientamento", "verso": "verticale", "ascolto": 2})
    attiva(etichetta="Attendi l'inverno", tipo="pulsante", ascolto=4)
    cmd({"azione": "orientamento", "verso": "orizzontale", "ascolto": 2.5})
    try:
        troncate, piene = giro("inverno-orizzontale")
        controlla_lettura("orizzontale: la prima schermata dell'inverno letta per intero — mantenimento, linguette, voci",
                          troncate, piene, prima_schermata_dell_inverno())
    finally:
        cmd({"azione": "orientamento", "verso": "verticale", "ascolto": 2})
    attiva(prefisso="Addestramento mirato.", tipo="pulsante", ascolto=3)
    cmd({"azione": "orientamento", "verso": "orizzontale", "ascolto": 2.5})
    try:
        troncate, piene = giro("scelta-del-reparto-orizzontale")
        controlla_lettura("orizzontale: la scelta del reparto letta per intero",
                          troncate, piene, scelta_letta("Addestramento mirato.", SCELTE))
    finally:
        cmd({"azione": "orientamento", "verso": "verticale", "ascolto": 2})
    attiva(etichetta="Chiudi il pannello", tipo="pulsante", ascolto=2.5)


# ------------------------------------------------------------------------------------------ testo
def blocco_testo():
    """Le stesse schermate alla dimensione del testo più grande: VoiceOver le legge per intero, la scelta
    del reparto si usa, e le schermate mostrano se una riga esce dal bordo o è tagliata."""
    subprocess.run(["xcrun", "simctl", "ui", UDID, "content_size", "accessibility-extra-extra-extra-large"], check=False)
    try:
        regno_nuovo()
        troncate, piene = giro("testo-massimo-patria-primavera")
        troncate, piene, barre = senza_barre(troncate, piene)
        controlla_lettura("testo massimo: la patria in primavera letta per intero", troncate, piene, patria_in_primavera())
        e = attiva(prefisso="Cervo,", tipo="pulsante", ascolto=4)
        controlla("testo massimo: la riga di una formazione si attiva — «Cervo resta in patria.»",
                  "Cervo resta in patria." in intere(e) + e.get("ascoltate", []), "Cervo resta in patria.", sentito(e))
        schermata("testo-massimo-patria-cervo-resta")
        attiva(prefisso="Cervo,", tipo="pulsante", ascolto=3)
        attiva(etichetta="Attendi l'inverno", tipo="pulsante", ascolto=4)
        troncate, piene = giro("testo-massimo-inverno")
        troncate, piene, barre2 = senza_barre(troncate, piene)
        controlla_lettura("testo massimo: la prima schermata dell'inverno letta per intero", troncate, piene,
                          prima_schermata_dell_inverno())
        if barre or barre2:
            controlla("osservazione: a testo massimo VoiceOver legge in coda la barra di scorrimento di sistema",
                      len(barre) <= 1 and len(barre2) <= 1, "al più una per schermata, dopo l'ultimo comando", barre + barre2)
        cmd({"azione": "tocca", "prefisso": "Mantenimento dell'esercito, prelevato", "ascolto": 0.5})
        schermata("testo-massimo-inverno-mantenimento")
        cmd({"azione": "tocca", "etichetta": "Lavori lunghi", "ascolto": 0.5})
        schermata("testo-massimo-inverno-linguette")
        attiva(prefisso="Addestramento mirato.", tipo="pulsante", ascolto=3)
        troncate, piene = giro("testo-massimo-scelta-del-reparto")
        troncate, piene, _ = senza_barre(troncate, piene)
        controlla_lettura("testo massimo: la scelta del reparto letta per intero", troncate, piene,
                          scelta_letta("Addestramento mirato.", SCELTE))
        e = attiva(prefisso="Lupo: 8 atomi di fanteria pesante.", tipo="pulsante", ascolto=7, intere="ogni")
        nomi = albero()
        controlla("testo massimo: la scelta si attiva — l'addestramento di Lupo è ordinato e restano 93 monete",
                  come_sentito(e, "Addestramento mirato ordinato per 8 atomi di fanteria pesante di Lupo: pronto in primavera.") is not None
                  and "monete di bronzo: 93" in nomi,
                  ["Addestramento mirato ordinato per 8 atomi di fanteria pesante di Lupo: pronto in primavera.", "monete di bronzo: 93"],
                  intere(e) + e.get("ascoltate", []) + [n for n in nomi if n.startswith("monete")])
        cmd({"azione": "tocca", "prefisso": "Lupo, gruppo armato", "ascolto": 0.5})
        schermata("testo-massimo-inverno-dopo-l-addestramento")
    finally:
        subprocess.run(["xcrun", "simctl", "ui", UDID, "content_size", "large"], check=False)


FUNZIONI = {"partenza": blocco_partenza, "mappa": blocco_mappa, "inverno": blocco_inverno, "estate": blocco_estate,
            "reclute": blocco_reclute, "mantenimento": blocco_mantenimento, "voce": blocco_voce,
            "orizzontale": blocco_orizzontale,
            "testo": blocco_testo}


def main():
    global BLOCCO
    t0 = time.time()
    tempi = {}
    for blocco in BLOCCHI:
        if blocco not in FUNZIONI:
            print(f"blocco sconosciuto: {blocco} (blocchi: {', '.join(TUTTI)})")
            return 2
        BLOCCO = blocco
        print(f"== blocco {blocco} ({APPARECCHIO}) ==", flush=True)
        inizio = time.time()
        try:
            FUNZIONI[blocco]()
        except Exception as errore:  # un blocco caduto non ferma gli altri: lo si registra come controllo fallito
            controlla(f"{blocco}: il blocco è arrivato in fondo", False, "nessun errore del guidatore", repr(errore))
        tempi[blocco] = round(time.time() - inizio)
    righe = [json.loads(r) for r in CONTROLLI.read_text(encoding="utf-8").splitlines()] if CONTROLLI.exists() else []
    print("== riepilogo ==")
    for blocco in BLOCCHI:
        sue = [r for r in righe if r.get("blocco") == blocco]
        no = [r for r in sue if r["esito"] != "ok"]
        print(f"{blocco}: controlli {len(sue)}, ok {len(sue) - len(no)}, NO {len(no)} "
              f"(su difetti riferiti {sum(1 for r in no if r.get('reperto'))}, altri {sum(1 for r in no if not r.get('reperto'))}), "
              f"{tempi.get(blocco, 0)} s")
    no = [r for r in righe if r["esito"] != "ok"]
    print(f"controlli: {len(righe)}, ok {len(righe) - len(no)}, NO {len(no)} "
          f"(su difetti riferiti {sum(1 for r in no if r.get('reperto'))}, altri {sum(1 for r in no if not r.get('reperto'))}); "
          f"durata {time.time() - t0:.0f} s (time.time del guidatore)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
