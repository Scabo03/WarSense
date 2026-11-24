#!/usr/bin/env python3
"""Il TESTER della sessione interattiva (incarico 28, seconda parte).

Gioca una partita con VoiceOver acceso attraverso il pilota (`SessioneInterattivaTest`), un passo
alla volta: ascolta ciò che VoiceOver pronuncia, legge l'albero essenziale, decide il passo
successivo. Non conosce lo stato del gioco se non per ciò che si sente e si vede: le etichette delle
caselle, gli annunci, l'informazione di stato del tocco magico. Canali usati: servizio VoiceOver delle
prove (lettura), comandi da tastiera di VoiceOver (rotori: scelta e salto), doppio tocco sintetico
sull'elemento (attivazione, solo in verticale), doppio tocco a due dita (tocco magico).

Uso: python3 scripts/tester.py <cartella del pilota> <formato: piccola|media|grande> [giornate massime]
Scrive il diario in <cartella>/diario-<formato>.jsonl e stampa un riassunto.

Con «regno» come quarto argomento (incarico 30) il tester gioca UN ANNO DEL REGNO: dall'avvio apre un
regno nuovo, legge la patria, apre la campagna sul fronte del formato scelto, la gioca — le prime
<giornate> giornate muovendo i gruppi, le altre chiudendole col comando, e combattendo ogni battaglia
che nasce — finché la campagna si conclude; ascolta la dichiarazione di conclusione, torna in patria,
passa l'inverno ordinando le leve che può pagare, annulla una spesa, percorre le quattro schermate e
arriva alla primavera, dove apre la campagna dell'anno nuovo e conta le proprie formazioni sulla mappa.
  python3 scripts/tester.py <cartella> <formato> <giornate giocate muovendo i gruppi> regno [opzioni]

Con l'opzione «due-anni» (incarico 31) il tester gioca DUE ANNI DEL REGNO usando ciò che la seconda tappa
ha portato: in primavera sceglie chi parte e chi resta in patria attivando le righe delle forze; gioca la
campagna fino alla conclusione; d'inverno ascolta il mantenimento, ordina un addestramento mirato dalla
scelta del reparto (toccando prima una scelta impedita, se c'è), e alla quarta schermata ordina una leva,
che sarà pronta in estate; nella seconda primavera rilegge le forze e confronta i nomi con quelli del primo
anno; nella seconda campagna ascolta, alla chiusura che apre l'estate, l'arrivo delle reclute dalla patria;
nel secondo inverno paga il mantenimento dell'addestramento; nella terza primavera rilegge le forze.
  python3 scripts/tester.py <cartella> <formato> <giornate> regno due-anni [tieni=Cervo] [solo=Corvo]
      [tieni2=…] [solo2=Falco] ["addestra=Falco: 12"] [contatto] …
Con «presa» (incarico 32) il tester gioca UNA CAMPAGNA DEL REGNO per prendere il quartier generale avversario (01
§5.18.3): manda avanti i gruppi armati più forti («colonne=1» quanti), che entrano nella casella del quartier generale,
combatte le battaglie che nascono, tiene la casella e ascolta le giornate che mancano finché la campagna si conclude; poi
legge la dichiarazione di conclusione e torna in patria.
  python3 scripts/tester.py <cartella> <formato> <giornate massime> regno presa [colonne=1] [resa]
Con «richiamo» (incarico 32) gioca una campagna del regno fino a un contatto col nemico, ascolta il comando di richiamo che
dichiara perché non si può dare (01 §5.18.2, 02 §6.5.5), si ritira dalla battaglia, e appena si può richiama l'esercito:
prima rinuncia, poi conferma; legge la dichiarazione di conclusione e torna in patria.
  python3 scripts/tester.py <cartella> <formato> <giornate massime> regno richiamo resa

«tieni=» le formazioni da tenere in patria il primo anno (separate da virgola); «solo=» la sola che parte;
«tieni2=» e «solo2=» lo stesso per il secondo anno; «addestra=» l'inizio della scelta del reparto da
addestrare (altrimenti la più costosa che lascia di che pagare la leva della quarta schermata).
"""
import json
import os
import pathlib
import re
import sys
import time

CARTELLA = pathlib.Path(sys.argv[1])
FORMATO = sys.argv[2]
GIORNATE = int(sys.argv[3]) if len(sys.argv) > 3 else 30
# Opzioni (dal quinto argomento in poi): «resa» = in battaglia si dichiara la resa appena è
# disponibile (lo sconfitto sopravvive e ripiega: il percorso del ripiegamento); «tutti» = ogni gruppo
# armato marcia verso nord quando può, per cercare il contatto (altrimenti uno su due); «contatto»
# (incarico 30) = ogni gruppo armato marcia verso la formazione armata avversaria che la mappa mostra,
# scegliendo fra le caselle raggiungibili la più vicina a quella, ed entrandovi quando è raggiungibile.
OPZIONI = set(sys.argv[5:])
# Le opzioni con un valore («tieni=Cervo»), per i due anni del regno (incarico 31).
PARAMETRI = dict(o.split("=", 1) for o in sys.argv[5:] if "=" in o)
# Il diario si scrive una riga alla volta: di norma accanto ai comandi del pilota; chi lancia il tester può
# farlo scrivere altrove (fra i prodotti dell'incarico), perché un'interruzione non lo perda.
DIARIO = pathlib.Path(os.environ.get("TESTER_DIARIO") or CARTELLA / f"diario-{FORMATO}.jsonl")
# Il possessivo che dichiara una formazione propria, nelle quattro forme accordate (02 §4.6).
PROPRIO = re.compile(r"\btu(o|a|oi|e) ")

# I fronti del regno, per formato di mappa (incarico 30): la voce con cui si sceglie comincia così.
FRONTE = {"piccola": "fronte del guado", "media": "fronte dell'istmo", "grande": "fronte della pianura lunga"}

PANNELLO = {
    "marcia": "Marcia: scegli la casella sulla mappa", "presidio": "Presidia: resta fermo in guardia",
    "sosta": "Sosta con raccolta: resta fermo e raccogli provviste", "esplora": "Esplora la zona",
    "apri": "Apri la battaglia", "chiudi": "Chiudi il pannello",
}


def _esiti():
    f = CARTELLA / "esiti.jsonl"
    if not f.exists():
        return []
    out = []
    for r in f.read_text(encoding="utf-8").splitlines():
        try:
            out.append(json.loads(r))
        except json.JSONDecodeError:
            pass
    return out


def cmd(c, attesa=180):
    fc = CARTELLA / "comandi.jsonl"
    n = len(fc.read_text(encoding="utf-8").splitlines()) + 1 if fc.exists() else 1
    c = dict(c, n=n)
    with fc.open("a", encoding="utf-8") as f:
        f.write(json.dumps(c, ensure_ascii=False) + "\n")
    limite = time.time() + attesa
    while time.time() < limite:
        for e in _esiti():
            if e.get("n") == n:
                return e
        time.sleep(0.25)
    return {"n": n, "errore": "nessun esito"}


def diario(tipo, **dati):
    with DIARIO.open("a", encoding="utf-8") as f:
        f.write(json.dumps(dict(tipo=tipo, ora=time.strftime("%H:%M:%S"), **dati), ensure_ascii=False) + "\n")


def sentito(e):
    return " | ".join(e.get("ascoltate", [])) or e.get("dopo", "")


def tasto(t, mod=("control", "option"), ascolto=1.0):
    return cmd({"azione": "tasto", "tasto": t, "modificatori": list(mod), "ascolto": ascolto})


def attiva(**chi):
    e = cmd(dict({"azione": "attiva", "ascolto": chi.pop("ascolto", 2.0)}, **chi))
    diario("attiva", chi=chi, fuoco=e.get("fuoco"), sentito=sentito(e), errore=e.get("errore"))
    return e


def albero():
    return cmd({"azione": "albero", "ascolto": 0.2}).get("albero", [])


def etichette():
    return [re.sub(r" \[.*$", "", r) for r in albero()]


def tocco_magico():
    # Il gesto su un elemento concreto: sull'iPad l'applicazione e la sua finestra non hanno coordinate
    # calcolabili per un tocco a più dita, e per VoiceOver il tocco magico vale ovunque.
    nomi = etichette()
    if PANNELLO["chiudi"] in nomi and not any(n in nomi for n in ("Registro della campagna", "Fine del turno")):
        attiva(etichetta=PANNELLO["chiudi"], tipo="pulsante")  # un pannello rimasto aperto copre la mappa
        nomi = etichette()
    bersaglio = next((n for n in ("Registro della campagna", "Fine del turno", "Chiudi la giornata") if n in nomi), None)
    if not bersaglio:
        # Senza un pulsante visibile il tocco a due dita fa cadere il pilota (coordinate non calcolabili).
        diario("osservazione_tester", testo="tocco magico non eseguito: nessun bersaglio visibile")
        return ""
    c = {"etichetta": bersaglio, "tipo": "pulsante"}
    e = cmd(dict({"azione": "multi_tocco", "tocchi": 2, "dita": 2, "ascolto": 3.0}, **c))
    s = sentito(e)
    diario("tocco_magico", sentito=s)
    return s


def scegli_rotore(nome, massimo=16):
    for _ in range(massimo):
        if nome in sentito(tasto("destra", ("control", "option", "command"), 0.8)):
            return True
    return False


def prossimo_nel_rotore(su=False):
    return sentito(tasto("su" if su else "giu", ("control", "option", "command"), 1.2))


# ---------------------------------------------------------------- la battaglia

def evacua():
    """Dopo la resa (ritirata combattuta, 01 §10.4): ogni proprio reparto che il pannello lascia evacuare
    esce dal campo; gli altri restano. Le forze evacuate tornano sulla mappa e ripiegano (01 §10.6)."""
    propri = [re.search(r"riga \d+, cella \d+", n).group(0) for n in etichette()
              if re.search(r"riga \d+, cella \d+, tu(o|a|oi|e) ", n)]
    for cella in propri[:6]:
        attiva(contiene=cella + ",")
        voci = etichette()
        v = next((v for v in voci if v.startswith("Evacua questa unità")), None)
        if v:
            e = attiva(etichetta=v, tipo="pulsante", ascolto=3)
            diario("evacuazione", cella=cella, sentito=sentito(e))
        else:
            attiva(etichetta=PANNELLO["chiudi"], tipo="pulsante")


def battaglia():
    diario("battaglia_aperta", sentito=sentito(cmd({"azione": "parla", "ascolto": 3})))
    # Le tessere del deck come l'albero le espone, col loro valore (incarico 31): il reparto che in patria
    # ha ricevuto un miglioramento lo dichiara in coda al valore («…, addestramento mirato»).
    diario("tessere_del_deck", righe=[r for r in albero() if "esemplar" in r and "=" in r])
    ritirata = False
    for turno in range(1, 25):
        nomi = etichette()
        if "Resoconto della battaglia" in nomi:
            break
        # 1. Schieramento: la prima tessera con esemplari, poi la prima cella valida, fino a tre volte.
        #    Con una tessera scelta le celle valide dichiarano in testa costo e residuo.
        for _ in range(3):
            tessere = [r for r in albero() if "esemplar" in r and "=" in r and "0 esemplari" not in r]
            if not tessere:
                break
            nome = re.sub(r" \[.*$", "", tessere[0])
            attiva(etichetta=nome)
            # Dalla versione 2.8 di 02 §3.3 la cella comincia dalla posizione e chiude col costo.
            valide = [n for n in etichette() if re.search(r", libera, costa \d+, restano \d+$", n)]
            m = re.search(r"riga \d+, cella \d+", valide[0]) if valide else None
            if not m:
                attiva(etichetta=nome)  # toglie la scelta
                break
            attiva(contiene=m.group(0) + ",")
        # 2. Attacco: ogni proprio reparto dal suo pannello ingaggia o tira se può, altrimenti avanza.
        #    Con «resa» i reparti restano nelle righe arretrate, da cui si evacuano dopo la resa.
        propri = [re.search(r"riga \d+, cella \d+", n).group(0) for n in etichette()
                  if re.search(r"riga \d+, cella \d+, tu(o|a|oi|e) ", n)]
        if "resa" in OPZIONI:
            propri = []
            if ritirata:
                evacua()
        for cella in propri[:4]:
            attiva(contiene=cella + ",")
            voci = etichette()
            scelta = next((v for v in voci if v.startswith("Ingaggia") or v.startswith("Tira su")), None)
            if scelta:
                attiva(etichetta=scelta, tipo="pulsante")
            elif "Scegli la destinazione sulla griglia" in voci:
                attiva(etichetta="Scegli la destinazione sulla griglia", tipo="pulsante")
                mete = [n for n in etichette() if re.search(r", libera, costa \d+, restano \d+$", n)]
                # la meta più avanzata (riga più bassa) fra quelle raggiungibili
                mete.sort(key=lambda n: int(re.search(r"riga (\d+)", n).group(1)))
                if mete:
                    attiva(contiene=re.search(r"riga \d+, cella \d+", mete[0]).group(0) + ",")
                else:
                    attiva(contiene=cella + ",")
            else:
                attiva(etichetta=PANNELLO["chiudi"], tipo="pulsante")
        # 3. Resa se la battaglia si allunga, altrimenti fine del turno.
        if "resa" in OPZIONI:
            if not ritirata and turno >= 2 and "Dichiara la resa" in etichette():
                e = attiva(etichetta="Dichiara la resa", tipo="pulsante", ascolto=3)
                diario("resa", turno=turno, sentito=sentito(e))
                if "Resa dichiarata" in sentito(e):
                    ritirata = True
                    evacua()
            if "Resoconto della battaglia" in etichette():
                break
            attiva(etichetta="Fine del turno", tipo="pulsante", ascolto=4)
        elif turno >= 14 and "Dichiara la resa" in etichette():
            e = attiva(etichetta="Dichiara la resa", tipo="pulsante", ascolto=3)
            diario("resa", turno=turno, sentito=sentito(e))
            if "Resoconto della battaglia" in etichette():
                break
            attiva(etichetta="Fine del turno", tipo="pulsante", ascolto=4)
        else:
            attiva(etichetta="Fine del turno", tipo="pulsante", ascolto=4)
        diario("turno", numero=turno, stato=tocco_magico())
    resoconto = cmd({"azione": "giro", "ascolto": 0.5, "con_schermata": True, "nome": f"{FORMATO}-resoconto-{int(time.time())}"})
    diario("resoconto", pronunce=resoconto.get("pronunce"))
    # Il congedo dice dove porta: «Torna sulla mappa» dalla build 33, «Torna all'inizio» prima (incarico 32).
    congedo = next((n for n in ("Torna sulla mappa", "Torna all'inizio") if n in etichette()), "Torna sulla mappa")
    diario("congedo", voce=congedo)
    attiva(etichetta=congedo, tipo="pulsante", ascolto=3)
    # Il ripiegamento, se lo sconfitto ha più caselle: la prima voce del pannello.
    voci = etichette()
    if "Campagna conclusa" in voci:
        # La battaglia ha concluso la campagna del regno (incarico 30): al posto della mappa c'è la
        # dichiarazione di conclusione, che il chiamante ascolta.
        diario("ritorno_in_campagna", stato="campagna conclusa: dichiarazione di conclusione")
        return
    if "Scegli dove ripiegare" in voci:
        caselle = [v for v in voci if v.startswith("In riga ")]
        diario("ripiegamento_proposto", caselle=caselle)
        if caselle:
            e = attiva(etichetta=caselle[0], tipo="pulsante", ascolto=3)
            diario("ripiegamento_scelto", casella=caselle[0], sentito=sentito(e))
    diario("ritorno_in_campagna", stato=tocco_magico())


# ---------------------------------------------------------------- la campagna

def armato(etichetta):
    # «tuo», «tua», «tuoi», «tue»: le frasi si accordano al genere del nome del gruppo (incarico 29).
    return bool(PROPRIO.search(etichetta)) and "ricognizione" not in etichetta and "non armata" not in etichetta


def giornata(numero):
    stato = tocco_magico()
    diario("giornata", numero=numero, stato=stato)
    m = re.search(r"[Bb]attaglia in sospeso in riga (\d+), casella (\d+)", stato)
    if m or "battaglia in sospeso" in stato:
        if m:
            attiva(contiene=f"riga {m.group(1)}, casella {m.group(2)},")
        if PANNELLO["apri"] in etichette():
            attiva(etichetta=PANNELLO["apri"], tipo="pulsante", ascolto=4)
            battaglia()
            return "battaglia"
        attiva(etichetta=PANNELLO["chiudi"], tipo="pulsante")
    ordinati = 0
    gia = set()
    for _ in range(14):
        attesa = [n for n in etichette() if re.search(r"riga \d+, casella \d+", n)
                  and ", in attesa" in n and PROPRIO.search(n)]
        attesa = [n for n in attesa if re.search(r"riga \d+, casella \d+", n).group(0) not in gia]
        if not attesa:
            break
        s = attesa[0]
        m = re.search(r"riga (\d+), casella (\d+)", s)
        r, c = int(m.group(1)), int(m.group(2))
        gia.add(m.group(0))
        tutte = etichette()
        nord = next((n for n in tutte if f"riga {r - 1}, casella {c}," in n), "")
        meta = (r - 1, c)
        if "tutti" in OPZIONI:
            # Con «tutti» il gruppo armato cerca il contatto: una casella vicina con il quartier generale
            # o una formazione armata avversaria ha la precedenza sulla marcia verso nord.
            for dr, dc in ((-1, 0), (0, -1), (0, 1), (1, 0)):
                n = next((x for x in tutte if f"riga {r + dr}, casella {c + dc}," in x), "")
                if n and not PROPRIO.search(n) and \
                        ("quartier generale avversario" in n or "formazione avversaria" in n):
                    nord, meta = n, (r + dr, c + dc)
                    break
        attiva(contiene=f"riga {r}, casella {c},")
        voci = etichette()
        if "contatto" in OPZIONI and armato(s) and PANNELLO["marcia"] in voci:
            # La formazione ARMATA avversaria è quella che la mappa chiama «formazione avversaria»
            # (le altre due categorie hanno il proprio nome): vi si marcia sopra, o il più vicino possibile.
            bersagli = [(int(a), int(b)) for a, b in
                        re.findall(r"riga (\d+), casella (\d+), (?:[^\n]*?, )?formazione avversaria", "\n".join(tutte))]
            if bersagli:
                attiva(etichetta=PANNELLO["marcia"], tipo="pulsante")
                mete = []
                for n in etichette():
                    m2 = re.match(r"riga (\d+), casella (\d+), .*raggiungibile in (\d+) giorn", n)
                    if m2:
                        rr, cc, gg = int(m2.group(1)), int(m2.group(2)), int(m2.group(3))
                        distanza = min(abs(rr - br) + abs(cc - bc) for br, bc in bersagli)
                        mete.append((distanza, gg, rr, cc))
                if mete:
                    distanza, giorni, rr, cc = min(mete)
                    esito = sentito(attiva(contiene=f"riga {rr}, casella {cc},", ascolto=2.5))
                    diario("marcia", da=f"riga {r}, casella {c}", verso=f"riga {rr}, casella {cc}",
                           distanza_dal_nemico=distanza, sentito=esito)
                    ordinati += 1
                    if "comincia il giorno" in esito:
                        break
                    continue
                attiva(contiene=f"riga {r}, casella {c},")  # nessuna meta: si toglie la designazione
                attiva(contiene=f"riga {r}, casella {c},")
                voci = etichette()
        if PANNELLO["apri"] in voci:
            # La battaglia in sospeso si apre dal pannello del gruppo che vi è coinvolto: l'informazione
            # di stato la dichiara, ma il servizio VoiceOver delle prove tronca le pronunce a 64 caratteri.
            attiva(etichetta=PANNELLO["apri"], tipo="pulsante", ascolto=4)
            battaglia()
            return "battaglia"
        if armato(s) and nord and not PROPRIO.search(nord) \
                and PANNELLO["marcia"] in voci and (ordinati % 2 == 0 or "tutti" in OPZIONI):
            attiva(etichetta=PANNELLO["marcia"], tipo="pulsante")
            esito = sentito(attiva(contiene=f"riga {meta[0]}, casella {meta[1]},", ascolto=2.5))
            diario("marcia", da=f"riga {r}, casella {c}", verso=f"riga {meta[0]}, casella {meta[1]}", sentito=esito)
            if "marcia verso" not in esito:
                diario("osservazione_tester", testo="marcia non confermata", sentito=esito)
        elif PANNELLO["esplora"] in voci:
            esito = sentito(attiva(etichetta=PANNELLO["esplora"], tipo="pulsante"))
        elif PANNELLO["presidio"] in voci:
            esito = sentito(attiva(etichetta=PANNELLO["presidio"], tipo="pulsante"))
        elif PANNELLO["sosta"] in voci:
            esito = sentito(attiva(etichetta=PANNELLO["sosta"], tipo="pulsante"))
        else:
            esito = sentito(attiva(etichetta=PANNELLO["chiudi"], tipo="pulsante"))
        ordinati += 1
        if "comincia il giorno" in esito:
            break  # l'ultimo ordine ha chiuso la giornata
    return f"ordinati {ordinati}"


# ---------------------------------------------------------------- il regno (incarico 30)

def anno_del_regno():
    """Un anno del regno, dall'avvio alla seconda primavera, con VoiceOver acceso."""
    e = attiva(etichetta="Nuovo regno", tipo="pulsante", ascolto=5)
    diario("patria", fuoco=e.get("dopo"), pronunce=cmd({"azione": "giro", "ascolto": 0.5}).get("pronunce"))
    attiva(etichetta="Apri la campagna", tipo="pulsante", ascolto=3)
    e = attiva(prefisso=FRONTE[FORMATO], tipo="pulsante", ascolto=6)
    diario("campagna_aperta", fronte=FRONTE[FORMATO], sentito=sentito(e), stato=tocco_magico())

    def conclusa():
        return "Campagna conclusa" in etichette()

    # 1. Le prime giornate muovendo i gruppi, come nelle campagne di prova.
    giorno = 0
    for g in range(1, GIORNATE + 1):
        if conclusa():
            break
        giorno = g
        diario("fine_giornata", numero=g, esito=giornata(g))
    # 2. Le altre chiuse col comando, finché la campagna si conclude; ogni battaglia si combatte.
    battaglie = 0
    for _ in range(140):
        if conclusa():
            break
        giorno += 1
        e = attiva(etichetta="Chiudi la giornata", tipo="pulsante", ascolto=3)
        s = sentito(e)
        diario("giornata_chiusa", numero=giorno, sentito=s, errore=e.get("errore"))
        if "battaglia in sospeso" in s or "Battaglia" in s or e.get("errore"):
            esito = giornata(giorno)
            diario("fine_giornata", numero=giorno, esito=esito)
            if esito == "battaglia":
                battaglie += 1
    if not conclusa():
        diario("osservazione_tester", testo="la campagna non si è conclusa nelle giornate giocate", giornate=giorno)
        return
    # 3. La dichiarazione di conclusione.
    dichiarazione = cmd({"azione": "giro", "ascolto": 0.5, "con_schermata": True, "nome": f"{FORMATO}-conclusione"})
    diario("dichiarazione_di_conclusione", pronunce=dichiarazione.get("pronunce"), giornate=giorno, battaglie=battaglie)
    e = attiva(etichetta="Torna in patria", tipo="pulsante", ascolto=4)
    diario("ritorno_in_patria", fuoco=e.get("dopo"), etichette=[n for n in etichette() if not n.startswith("gruppo")][:14])
    # 4. L'inverno: le leve che si possono pagare, una per volta, sentendo l'annuncio di ciascuna.
    e = attiva(etichetta="Attendi l'inverno", tipo="pulsante", ascolto=6)
    diario("inverno", sentito=sentito(e), fuoco=e.get("dopo"),
           riserve=[n for n in etichette() if re.match(r"^(monete di bronzo|uomini|metalli|materiale da costruzione|animali): \d+$", n)])
    leve = 0
    for _ in range(12):
        ordinabili = [n for n in etichette() if n.startswith("Leva di") and "Costa:" in n
                      and "Non si può ordinare" not in n]
        if not ordinabili:
            break
        nome = ordinabili[leve % len(ordinabili)].split(".")[0] + "."
        e = attiva(contiene=nome, tipo="pulsante", ascolto=3.5)
        s = sentito(e)
        diario("leva", voce=nome, sentito=s)
        if "ordinata" not in s:
            diario("osservazione_tester", testo="leva non confermata", sentito=s)
            break
        leve += 1
    impedite = [n for n in etichette() if n.startswith("Leva di") and "Non si può ordinare" in n]
    diario("voci_impedite", voci=impedite)
    if impedite:
        e = attiva(contiene=impedite[0].split(".")[0] + ".", tipo="pulsante", ascolto=3.5)
        diario("leva_impedita", sentito=sentito(e))
    e = attiva(etichetta="Annulla l'ultima spesa", tipo="pulsante", ascolto=3.5)
    diario("annullamento", sentito=sentito(e))
    lavori = [n for n in etichette() if n.startswith("Leva di") and "Costa" not in n]
    diario("lavori_ordinati", voci=lavori)
    for stazione in (2, 3, 4):
        e = attiva(etichetta=f"Prosegui alla schermata {stazione} di 4", tipo="pulsante", ascolto=3.5)
        diario("stazione", numero=stazione, sentito=sentito(e))
    e = attiva(etichetta="Prosegui alla primavera", tipo="pulsante", ascolto=7)
    nomi = etichette()
    diario("primavera", sentito=sentito(e), fuoco=e.get("dopo"),
           riserve=[n for n in nomi if re.match(r"^(monete di bronzo|uomini|metalli|materiale da costruzione|animali): \d+$", n)],
           # Dall'incarico 31 ogni riga delle forze comincia dal nome della formazione.
           forze=[n for n in nomi if RIGA_FORZE.match(n) or n.startswith("gruppo armato") or n.startswith("formazione")])
    cmd({"azione": "schermata", "nome": f"{FORMATO}-seconda-primavera", "ascolto": 0.3})
    # 5. La campagna dell'anno nuovo: le formazioni del regno, reclute comprese, sono sulla mappa.
    attiva(etichetta="Apri la campagna", tipo="pulsante", ascolto=3)
    attiva(prefisso=FRONTE[FORMATO], tipo="pulsante", ascolto=6)
    proprie = [n for n in etichette() if re.search(r"riga \d+, casella \d+", n) and PROPRIO.search(n)]
    diario("seconda_campagna", formazioni_sulla_mappa=len(proprie), etichette=proprie, stato=tocco_magico())


# ---------------------------------------------------------------- i due anni del regno (incarico 31)

# Una riga delle forze in patria: il nome, la categoria, i reparti, e dove va la formazione.
RIGA_FORZE = re.compile(r"^(\w+), (gruppo armato|formazione di ricognizione|formazione non armata)"
                        r"(, reclute dell'inverno)?: (.*)\. ([^.]+)$")
RISERVA = re.compile(r"^(monete di bronzo|uomini|metalli|materiale da costruzione|animali): \d+$")


def sentito_intero(e):
    """Ciò che si è sentito dopo un'azione: le pronunce intere lette dagli appunti (il servizio VoiceOver
    delle prove tronca a 64 caratteri), poi quelle troncate."""
    piene = [x.get("testo", "") for x in e.get("intere", []) if x.get("testo")]
    return " | ".join(piene + e.get("ascoltate", [])) or e.get("dopo", "")


def attiva_e_ascolta(**chi):
    """Come `attiva`, chiedendo al pilota anche la pronuncia intera di ciò che VoiceOver dice dopo."""
    e = cmd(dict({"azione": "attiva", "ascolto": chi.pop("ascolto", 3.5), "intere": "ogni"}, **chi))
    diario("attiva", chi=chi, fuoco=e.get("fuoco"), sentito=sentito_intero(e), errore=e.get("errore"))
    return e


def letta_per_intero():
    """La schermata letta dall'inizio alla fine, con le pronunce intere dove gli appunti le danno."""
    e = cmd({"azione": "giro", "ascolto": 0.3, "intere": True}, attesa=900)
    piene, troncate = e.get("pronunce_intere", []), e.get("pronunce", [])
    return [(piene[i] if i < len(piene) and piene[i] else t) for i, t in enumerate(troncate)]


def forze_in_patria():
    """Le righe delle forze come la patria le espone: nome, categoria, reparti, dove va."""
    righe = []
    for n in etichette():
        m = RIGA_FORZE.match(n)
        if m and not any(r["riga"] == n for r in righe):
            righe.append({"nome": m.group(1), "categoria": m.group(2), "reclute": bool(m.group(3)),
                          "reparti": m.group(4), "dove": m.group(5), "riga": n})
    return righe


def reparti_di(testo):
    """I reparti nominati in una riga: archetipo -> atomi."""
    out = {}
    for atomi, archetipo in re.findall(r"(\d+) atomi di ([a-z ]+?)(?= con |,|$)", testo):
        out[archetipo] = out.get(archetipo, 0) + int(atomi)
    return out


def confronta_i_nomi(prima, dopo):
    """I nomi non scorrono (incarico 31): ogni formazione che c'era e c'è ancora ha la stessa categoria,
    nessun tipo di reparto nuovo e mai più atomi di prima. Era il difetto della build 31: dopo la perdita
    di un gruppo «Corvo» diventava la formazione che era «Lupo». Restituisce i nomi scorsi."""
    di_prima = {f["nome"]: f for f in prima}
    scorsi = []
    for f in dopo:
        p = di_prima.get(f["nome"])
        if not p:
            continue
        a, b = reparti_di(p["reparti"]), reparti_di(f["reparti"])
        if p["categoria"] != f["categoria"] or any(k not in a or v > a[k] for k, v in b.items()):
            scorsi.append({"nome": f["nome"], "prima": p["riga"], "dopo": f["riga"]})
    return scorsi


def scegli_chi_parte(anno):
    """In primavera, prima di aprire la campagna: attivando le righe delle forze tiene in patria o manda
    al fronte ciascuna formazione, secondo le opzioni, e ascolta la conferma di ogni scelta."""
    solo = PARAMETRI.get("solo" if anno == 1 else "solo2")
    tieni = PARAMETRI.get("tieni", "") if anno == 1 else PARAMETRI.get("tieni2", PARAMETRI.get("tieni", ""))
    tieni = [x for x in tieni.split(",") if x]
    for f in forze_in_patria():
        if f["reclute"]:
            continue  # le reclute entrano come la loro riga dichiara
        vuole = (f["nome"] == solo) if solo else (f["nome"] not in tieni)
        if vuole != f["dove"].startswith("Part"):
            e = attiva_e_ascolta(prefisso=f["nome"] + ",", tipo="pulsante")
            ora = next((r for r in forze_in_patria() if r["nome"] == f["nome"]), {})
            diario("destinazione", anno=anno, nome=f["nome"], al_fronte=vuole, sentito=sentito_intero(e),
                   riga=ora.get("riga"))
    diario("chi_parte", anno=anno, forze=[f["riga"] for f in forze_in_patria()])


def formazioni_sulla_mappa():
    return [n for n in etichette() if re.search(r"riga \d+, casella \d+", n) and PROPRIO.search(n)]


def giorno_dallo_stato():
    """Il giorno della campagna come lo dice l'informazione di stato (tocco magico, pronuncia intera)."""
    if "Registro della campagna" not in etichette():
        return None
    e = cmd({"azione": "multi_tocco", "tocchi": 2, "dita": 2, "etichetta": "Registro della campagna",
             "tipo": "pulsante", "ascolto": 3.0, "intere": "ogni"})
    s = sentito_intero(e)
    diario("tocco_magico", sentito=s)
    m = re.search(r"Giorno (\d+)\.", s)
    return int(m.group(1)) if m else None


def campagna_dell_anno(anno):
    """La campagna di un anno: le prime giornate muovendo i gruppi, le altre chiuse col comando; la
    chiusura che apre una stagione si ascolta a lungo, perché è lì che arrivano dalla patria le reclute
    ordinate tardi; poi la dichiarazione di conclusione e il ritorno in patria. Falso se non si conclude."""
    attiva_e_ascolta(etichetta="Apri la campagna", tipo="pulsante", ascolto=3)
    e = attiva_e_ascolta(prefisso=FRONTE[FORMATO], tipo="pulsante", ascolto=8)
    diario("campagna_aperta", anno=anno, fronte=FRONTE[FORMATO], sentito=sentito_intero(e),
           formazioni_sulla_mappa=formazioni_sulla_mappa())

    def conclusa():
        return "Campagna conclusa" in etichette()

    if "Torna in patria" not in etichette() and not conclusa():
        diario("osservazione_tester", testo="la campagna non si è aperta", anno=anno, sentito=sentito_intero(e))
        return False
    battaglie = 0
    for g in range(1, GIORNATE + 1):
        if conclusa():
            break
        esito = giornata(g)
        diario("fine_giornata", numero=g, esito=esito)
        if esito == "battaglia":
            battaglie += 1
    giorno = None
    for _ in range(170):
        if conclusa():
            break
        if giorno is None or giorno in (28, 58):
            giorno = giorno_dallo_stato() or giorno
        if giorno is not None and giorno % 30 == 0 and giorno < 90:
            # La chiusura che apre l'estate o l'autunno: si ascolta finché la voce tace.
            e = cmd({"azione": "attiva", "etichetta": "Chiudi la giornata", "tipo": "pulsante", "ascolto": 45,
                     "quiete": 11, "intere": "ogni"})
            s = sentito_intero(e)
            diario("stagione_nuova", anno=anno, chiusa_la_giornata=giorno, sentito=s, pronunce=e.get("ascoltate"),
                   istanti=e.get("ascoltate_t"), formazioni_sulla_mappa=formazioni_sulla_mappa())
        else:
            e = attiva(etichetta="Chiudi la giornata", tipo="pulsante", ascolto=3)
            s = sentito(e)
            diario("giornata_chiusa", numero=giorno, sentito=s, errore=e.get("errore"))
        giorno = giorno + 1 if giorno is not None and "Giornata chiusa" in s else None
        if "battaglia in sospeso" in s or "Battaglia" in s or e.get("errore"):
            esito = giornata(giorno or 0)
            diario("fine_giornata", numero=giorno, esito=esito)
            if esito == "battaglia":
                battaglie += 1
            giorno = None
    if not conclusa():
        diario("osservazione_tester", testo="la campagna non si è conclusa nelle giornate giocate", anno=anno)
        return False
    cmd({"azione": "schermata", "nome": f"{FORMATO}-conclusione-anno-{anno}", "ascolto": 0.3})
    diario("dichiarazione_di_conclusione", anno=anno, pronunce=letta_per_intero(), battaglie=battaglie)
    e = attiva_e_ascolta(etichetta="Torna in patria", tipo="pulsante", ascolto=4)
    diario("ritorno_in_patria", anno=anno, fuoco=e.get("dopo"), forze=[f["riga"] for f in forze_in_patria()])
    return True


def costo_in_monete(voce):
    m = re.search(r"Costa: monete di bronzo (\d+) su (\d+)", voce)
    return (int(m.group(1)), int(m.group(2))) if m else None


def scelte_del_reparto():
    out = []
    for n in etichette():
        if re.match(r"^\w+: \d+ atomi di ", n) and n not in out:
            out.append(n)
    return out


def inverno_dei_due_anni(anno):
    """L'inverno con le cose nuove: il mantenimento che il gioco preleva e dichiara; il mantenimento
    dell'addestramento per chi lo porta; al primo inverno l'addestramento mirato dalla scelta del reparto
    (dopo aver toccato una scelta impedita, se c'è) e, alla quarta schermata, una leva che sarà pronta in
    estate; poi la primavera. Restituisce le forze lette in primavera."""
    e = attiva_e_ascolta(etichetta="Attendi l'inverno", tipo="pulsante", ascolto=10)
    nomi = etichette()
    diario("inverno", anno=anno, sentito=sentito_intero(e), fuoco=e.get("dopo"),
           riserve=[n for n in nomi if RISERVA.match(n)],
           mantenimento=[n for n in nomi if n.startswith("Mantenimento dell'esercito") or "reparto sciolto" in n
                         or n.startswith("Il denaro non è bastato")],
           linguette=[n for n in nomi if n in ("Lavori lunghi", "Lavori di media durata", "Lavori brevi")],
           forze=[f["riga"] for f in forze_in_patria()])
    # Chi porta un miglioramento lo conserva soltanto se lo si mantiene (01 §4.14): lo si paga a tutti.
    for _ in range(8):
        if not any("da mantenere entro l'inverno" in f["riga"] for f in forze_in_patria()):
            break
        attiva_e_ascolta(prefisso="Mantenimento dell'addestramento mirato.", tipo="pulsante", ascolto=3)
        scelte = scelte_del_reparto()
        diario("scelta_del_mantenimento", anno=anno, scelte=scelte)
        pagabili = [s for s in scelte if "Non si può ordinare" not in s]
        if not pagabili:
            if PANNELLO["chiudi"] in etichette():
                attiva(etichetta=PANNELLO["chiudi"], tipo="pulsante")
            break
        e = attiva_e_ascolta(prefisso=pagabili[0].split(" Costa:")[0], tipo="pulsante", ascolto=8)
        diario("mantenimento_dell_addestramento", anno=anno, scelta=pagabili[0], sentito=sentito_intero(e),
               forze=[f["riga"] for f in forze_in_patria() if "addestramento" in f["riga"]])
        if "ordinato" not in sentito_intero(e):
            break
    if anno == 1:
        leva = next((n for n in nomi if n.startswith("Leva di fanteria leggera.")), "")
        costo_leva = (costo_in_monete(leva) or (0, 0))[0]
        attiva_e_ascolta(prefisso="Addestramento mirato.", tipo="pulsante", ascolto=3)
        diario("scelta_del_reparto", anno=anno, pronunce=letta_per_intero())
        scelte = scelte_del_reparto()
        impedite = [s for s in scelte if "Non si può ordinare" in s]
        if impedite:
            e = attiva_e_ascolta(prefisso=impedite[0].split(" Non si può")[0], tipo="pulsante", ascolto=6)
            diario("scelta_impedita", scelta=impedite[0], sentito=sentito_intero(e),
                   riserve=[n for n in etichette() if RISERVA.match(n)])
            attiva_e_ascolta(prefisso="Addestramento mirato.", tipo="pulsante", ascolto=3)
            scelte = scelte_del_reparto()
        pagabili = [(costo_in_monete(s), s) for s in scelte if "Non si può ordinare" not in s and costo_in_monete(s)]
        voluta = PARAMETRI.get("addestra")
        scelta = next((s for _, s in pagabili if voluta and s.startswith(voluta)), None)
        if scelta is None and pagabili:
            # La più costosa che lasci di che pagare la leva della quarta schermata.
            con_la_leva = [(c, s) for c, s in pagabili if c[1] - c[0] >= costo_leva]
            scelta = max(con_la_leva or pagabili, key=lambda x: x[0][0])[1]
        if scelta:
            e = attiva_e_ascolta(prefisso=scelta.split(" Costa:")[0], tipo="pulsante", ascolto=8)
            dopo = cmd({"azione": "avanti", "ascolto": 0.3, "intere": True})
            qui = cmd({"azione": "indietro", "ascolto": 0.3, "intere": True})
            ora = etichette()
            diario("addestramento_mirato", scelta=scelta, sentito=sentito_intero(e),
                   fuoco_dopo={"indietro": qui.get("pronunce_intere") or qui.get("pronunce"),
                               "avanti": dopo.get("pronunce_intere") or dopo.get("pronunce")},
                   riserve=[n for n in ora if RISERVA.match(n)],
                   forze=[f["riga"] for f in forze_in_patria() if "addestramento" in f["riga"]],
                   lavori=[n for n in ora if n.startswith("Addestramento mirato per")])
        elif PANNELLO["chiudi"] in etichette():
            attiva(etichetta=PANNELLO["chiudi"], tipo="pulsante")
    for stazione in (2, 3, 4):
        e = attiva_e_ascolta(etichetta=f"Prosegui alla schermata {stazione} di 4", tipo="pulsante", ascolto=3.5)
        leve = []
        for n in etichette():
            if n.startswith("Leva di") and "Costa" in n and n not in leve:
                leve.append(n)
        diario("stazione", anno=anno, numero=stazione, sentito=sentito_intero(e), leve=leve)
    if anno == 1:
        if any(n.startswith("Leva di fanteria leggera.") and "Non si può ordinare" not in n for n in etichette()):
            e = attiva_e_ascolta(prefisso="Leva di fanteria leggera.", tipo="pulsante", ascolto=5)
            diario("leva_alla_quarta_schermata", sentito=sentito_intero(e),
                   lavori=[n for n in etichette() if n.startswith("Leva di") and "Costa" not in n])
        else:
            diario("osservazione_tester", testo="alla quarta schermata la leva di fanteria leggera non si può ordinare")
    e = attiva_e_ascolta(etichetta="Prosegui alla primavera", tipo="pulsante", ascolto=10)
    forze = forze_in_patria()
    diario("primavera", anno=anno + 1, sentito=sentito_intero(e), fuoco=e.get("dopo"),
           riserve=[n for n in etichette() if RISERVA.match(n)], forze=[f["riga"] for f in forze])
    cmd({"azione": "schermata", "nome": f"{FORMATO}-primavera-anno-{anno + 1}", "ascolto": 0.3})
    return forze


def due_anni_del_regno():
    """Due anni del regno, dall'avvio alla terza primavera, con VoiceOver acceso."""
    e = attiva_e_ascolta(etichetta="Nuovo regno", tipo="pulsante", ascolto=5)
    diario("patria", anno=1, fuoco=e.get("dopo"), pronunce=letta_per_intero())
    forze = {1: forze_in_patria()}
    for anno in (1, 2):
        scegli_chi_parte(anno)
        if not campagna_dell_anno(anno):
            return
        forze[anno + 1] = inverno_dei_due_anni(anno)
        scorsi = confronta_i_nomi(forze[anno], forze[anno + 1])
        diario("nomi", dalla_primavera=anno, alla_primavera=anno + 1,
               prima=[f["riga"] for f in forze[anno]], dopo=[f["riga"] for f in forze[anno + 1]], scorsi=scorsi,
               esito="ogni nome è rimasto alla sua formazione" if not scorsi else "NOMI SCORSI")
    scorsi = confronta_i_nomi(forze[1], forze[3])
    diario("nomi", dalla_primavera=1, alla_primavera=3, scorsi=scorsi,
           esito="ogni nome è rimasto alla sua formazione" if not scorsi else "NOMI SCORSI")


# ---------------------------------------------------------------- la presa e il richiamo (incarico 32)

QG_AVVERSARIO = "quartier generale avversario"
RICHIAMA = "Richiama l'esercito in patria"


def caselle():
    """Le caselle della mappa come si leggono: (riga, casella) -> il resto dell'etichetta."""
    out = {}
    for n in etichette():
        m = re.match(r"^riga (\d+), casella (\d+), (.*)$", n)
        if m:
            out.setdefault((int(m.group(1)), int(m.group(2))), m.group(3))
    return out


def atomi_in(etichetta):
    return sum(int(x) for x in re.findall(r"(\d+) atomi di", etichetta))


def proprie_armate(mappa):
    """I gruppi armati propri: casella -> etichetta, dal più forte."""
    mie = {c: e for c, e in mappa.items() if PROPRIO.match(e) and "ricognizione" not in e and "non armata" not in e}
    return sorted(mie.items(), key=lambda x: -atomi_in(x[1]))


def apri_la_campagna_del_regno():
    e = attiva_e_ascolta(etichetta="Nuovo regno", tipo="pulsante", ascolto=5)
    diario("patria", anno=1, fuoco=e.get("dopo"), forze=[f["riga"] for f in forze_in_patria()])
    attiva_e_ascolta(etichetta="Apri la campagna", tipo="pulsante", ascolto=3)
    e = attiva_e_ascolta(prefisso=FRONTE[FORMATO], tipo="pulsante", ascolto=20)
    diario("campagna_aperta", fronte=FRONTE[FORMATO], sentito=sentito_intero(e), pronunce=e.get("ascoltate"),
           formazioni_sulla_mappa=formazioni_sulla_mappa())
    return "Chiudi la giornata" in etichette()


def conclusa():
    return "Campagna conclusa" in etichette()


def combatti_se_serve(mappa):
    """La battaglia in sospeso, se c'è, aperta dal pannello del gruppo che vi è coinvolto e combattuta. Vero se si è
    combattuto. La campagna è bloccata: il pannello di ogni altro gruppo dice dove (02 §6.5)."""
    for c, e in proprie_armate(mappa) + [(c, e) for c, e in mappa.items() if PROPRIO.match(e) and not armato(e)]:
        attiva(contiene=f"riga {c[0]}, casella {c[1]},")
        voci = etichette()
        if PANNELLO["apri"] in voci:
            e = attiva_e_ascolta(etichetta=PANNELLO["apri"], tipo="pulsante", ascolto=6)
            diario("battaglia_aperta_dal_pannello", casella=c, sentito=sentito_intero(e), fuoco=e.get("dopo"))
            battaglia()
            return True
        if PANNELLO["chiudi"] in voci:
            attiva(etichetta=PANNELLO["chiudi"], tipo="pulsante")
        else:
            break
    return False


def marcia_verso(da, meta, evita):
    """La marcia di un gruppo verso una casella: fra quelle raggiungibili la più vicina alla meta, poi la meno
    lontana in giornate; mai in una casella con una formazione avversaria che non sia la meta."""
    attiva(contiene=f"riga {da[0]}, casella {da[1]},")
    if PANNELLO["marcia"] not in etichette():
        if PANNELLO["chiudi"] in etichette():
            attiva(etichetta=PANNELLO["chiudi"], tipo="pulsante")
        return None
    attiva(etichetta=PANNELLO["marcia"], tipo="pulsante", ascolto=3)
    mete = []
    for c, e in caselle().items():
        m = re.search(r"raggiungibile in (\d+) giorn", e)
        if m and (c == meta or ("formazione avversaria" not in e and c not in evita)):
            mete.append((abs(c[0] - meta[0]) * 2 + abs(c[1] - meta[1]), int(m.group(1)), c))
    if not mete or min(mete)[2] == da:
        attiva(contiene=f"riga {da[0]}, casella {da[1]},")  # nessuna meta: si toglie la designazione
        return None
    _, giorni, c = min(mete)
    e = attiva_e_ascolta(contiene=f"riga {c[0]}, casella {c[1]},", ascolto=4)
    diario("marcia", da=da, verso=c, giorni=giorni, sentito=sentito_intero(e))
    return c


def chiudi_la_giornata(numero, ascolta_tutto):
    """Chiude la giornata col comando e ascolta: tutto, finché la voce tace, quando c'è da sentire qualcosa."""
    c = {"azione": "attiva", "etichetta": "Chiudi la giornata", "tipo": "pulsante", "ascolto": 4}
    if ascolta_tutto:
        c.update(ascolto=45, quiete=6, intere="ogni")
    e = cmd(c)
    s = sentito_intero(e)
    diario("giornata_chiusa", numero=numero, sentito=s, pronunce=e.get("ascoltate"), errore=e.get("errore"))
    return s


def dichiarazione_e_ritorno(nome):
    """La dichiarazione di conclusione letta per intero, e il ritorno in patria."""
    cmd({"azione": "schermata", "nome": f"{FORMATO}-{nome}-conclusione", "ascolto": 0.3})
    pronunce = letta_per_intero()
    diario("dichiarazione_di_conclusione", pronunce=pronunce)
    e = attiva_e_ascolta(etichetta="Torna in patria", tipo="pulsante", ascolto=6)
    nomi = etichette()
    diario("ritorno_in_patria", fuoco=e.get("dopo"), sentito=sentito_intero(e),
           campagna=[n for n in nomi if n.startswith("Campagna sul")], forze=[f["riga"] for f in forze_in_patria()])
    cmd({"azione": "schermata", "nome": f"{FORMATO}-{nome}-patria", "ascolto": 0.3})
    return pronunce


def presa_del_quartier_generale():
    if not apri_la_campagna_del_regno():
        diario("osservazione_tester", testo="la campagna non si è aperta")
        return
    colonne = int(PARAMETRI.get("colonne", "1"))
    battaglie = 0
    for g in range(1, GIORNATE + 1):
        if conclusa():
            break
        mappa = caselle()
        suo = next((c for c, e in mappa.items() if QG_AVVERSARIO in e), None)
        armate = proprie_armate(mappa)
        diario("giornata", numero=g, armate=[(c, e) for c, e in armate], quartier_generale_avversario=suo,
               sua_etichetta=mappa.get(suo))
        # Con una battaglia in sospeso ogni altro comando è bloccato: la si combatte per prima.
        if any("battaglia in sospeso" in e for e in mappa.values()) and combatti_se_serve(mappa):
            battaglie += 1
            continue
        for c, e in armate[:colonne]:
            if c == suo or ", in attesa" not in e or suo is None:
                continue  # chi è sul quartier generale lo tiene: la chiusura lo lascia fermo
            marcia_verso(c, suo, evita=set())
            if conclusa():
                break
        if conclusa():
            break
        mappa = caselle()
        interessa = any("occupato" in e for e in mappa.values()) or any(
            abs(c[0] - suo[0]) <= 1 and abs(c[1] - suo[1]) <= 1 for c, _ in proprie_armate(mappa)) if suo else False
        s = chiudi_la_giornata(g, interessa)
        if "ccup" in s or "Tieni il quartier generale" in s or "cade" in s or "caduto" in s:
            diario("presa", numero=g, sentito=s, casella=caselle().get(suo))
            if not conclusa():
                tocco = cmd({"azione": "multi_tocco", "tocchi": 2, "dita": 2, "etichetta": "Registro della campagna",
                             "tipo": "pulsante", "ascolto": 18, "quiete": 4, "intere": "ogni"})
                diario("tocco_magico", sentito=sentito_intero(tocco))
        if not conclusa() and ("attaglia" in s or "mboscata" in s):
            if combatti_se_serve(caselle()):
                battaglie += 1
    if not conclusa():
        diario("osservazione_tester", testo="il quartier generale non è stato preso nelle giornate giocate", battaglie=battaglie)
        return
    pronunce = dichiarazione_e_ritorno("presa")
    preso = any("quartier generale avversario" in p and "caduto" in p for p in pronunce)
    diario("esito", quartier_generale_preso=preso, battaglie=battaglie)
    print("QUARTIER GENERALE PRESO" if preso else "campagna conclusa, ma non per la presa", flush=True)


def comando_di_richiamo():
    return next((n for n in etichette() if n.startswith(RICHIAMA)), None)


def richiamo_dell_esercito():
    if not apri_la_campagna_del_regno():
        diario("osservazione_tester", testo="la campagna non si è aperta")
        return
    impedito = None
    for g in range(1, GIORNATE + 1):
        if conclusa():
            diario("osservazione_tester", testo="la campagna si è conclusa prima del richiamo")
            return
        comando = comando_di_richiamo()
        diario("comando_di_richiamo", numero=g, etichetta=comando)
        if comando and "adesso non si può" in comando:
            # Attivato, dichiara il perché e non apre nulla.
            e = attiva_e_ascolta(prefisso=RICHIAMA, tipo="pulsante", ascolto=9)
            diario("richiamo_impedito", etichetta=comando, sentito=sentito_intero(e), pannello="Conferma il richiamo" in etichette())
            impedito = comando
        elif impedito:
            break
        mappa = caselle()
        if any("battaglia in sospeso" in e for e in mappa.values()) and combatti_se_serve(mappa):
            continue
        armate = proprie_armate(mappa)
        nemico = [c for c, e in mappa.items() if "formazione avversaria" in e]
        if nemico and not impedito:
            # La formazione più piccola va a contatto, per mettersi in un punto da cui il richiamo non si può dare.
            piccola = min((x for x in armate if ", in attesa" in x[1]), key=lambda x: atomi_in(x[1]), default=None)
            if piccola:
                marcia_verso(piccola[0], nemico[0], evita=set())
        if conclusa():
            continue
        s = chiudi_la_giornata(g, True)
        if "attaglia" in s or "mboscata" in s:
            diario("battaglia_nata", numero=g, sentito=s)
    comando = comando_di_richiamo()
    diario("comando_di_richiamo", etichetta=comando, impedito_prima=impedito)
    if not comando or "adesso non si può" in comando:
        diario("osservazione_tester", testo="il richiamo non è mai stato possibile", etichetta=comando)
        return
    # Prima si rinuncia, e la campagna continua.
    e = attiva_e_ascolta(etichetta=RICHIAMA, tipo="pulsante", ascolto=10)
    diario("pannello_del_richiamo", sentito=sentito_intero(e), pronunce=e.get("ascoltate"), voci=[n for n in etichette()][:8])
    e = attiva_e_ascolta(etichetta="Rinuncia", tipo="pulsante", ascolto=4)
    diario("richiamo_rinunciato", sentito=sentito_intero(e), fuoco=e.get("dopo"), conclusa=conclusa())
    attiva_e_ascolta(etichetta=RICHIAMA, tipo="pulsante", ascolto=4)
    e = cmd({"azione": "attiva", "etichetta": "Conferma il richiamo", "tipo": "pulsante", "ascolto": 20, "quiete": 5, "intere": "ogni"})
    diario("richiamo_confermato", sentito=sentito_intero(e), pronunce=e.get("ascoltate"), istanti=e.get("ascoltate_t"))
    if not conclusa():
        diario("osservazione_tester", testo="dopo la conferma la campagna non è conclusa")
        return
    pronunce = dichiarazione_e_ritorno("richiamo")
    richiamato = any("richiamato l'esercito" in p for p in pronunce)
    diario("esito", esercito_richiamato=richiamato, impedito_prima=impedito)
    print("ESERCITO RICHIAMATO" if richiamato else "campagna conclusa, ma non per il richiamo", flush=True)


def main():
    if len(sys.argv) > 4 and sys.argv[4] == "regno":
        if "presa" in OPZIONI:
            presa_del_quartier_generale()
            diario("fine", stato="presa")
        elif "richiamo" in OPZIONI:
            richiamo_dell_esercito()
            diario("fine", stato="richiamo")
        elif "due-anni" in OPZIONI:
            due_anni_del_regno()
            diario("fine", stato="due anni del regno")
        else:
            anno_del_regno()
            diario("fine", stato="anno del regno")
        print(f"diario: {DIARIO}")
        return
    if len(sys.argv) > 4 and sys.argv[4] == "riprendi":
        attiva(etichetta="Riprendi la campagna in corso", tipo="pulsante", ascolto=4)
    else:
        attiva(etichetta=f"Nuova campagna, mappa {FORMATO}", tipo="pulsante", ascolto=4)
    diario("inizio", formato=FORMATO, pronunce=cmd({"azione": "giro", "ascolto": 0.5}).get("pronunce"))
    for g in range(1, GIORNATE + 1):
        esito = giornata(g)
        diario("fine_giornata", numero=g, esito=esito)
        nomi = etichette()
        miei_armati = [n for n in nomi if re.search(r"riga \d+, casella \d+", n) and armato(n)]
        if not miei_armati:
            diario("conclusione", motivo="nessun gruppo armato del giocatore sulla mappa", giornata=g)
            break
    diario("fine", stato=tocco_magico())
    print(f"diario: {DIARIO}")


if __name__ == "__main__":
    main()
