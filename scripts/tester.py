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
"""
import json
import pathlib
import re
import sys
import time

CARTELLA = pathlib.Path(sys.argv[1])
FORMATO = sys.argv[2]
GIORNATE = int(sys.argv[3]) if len(sys.argv) > 3 else 30
# Opzioni (dal quinto argomento in poi): «resa» = in battaglia si dichiara la resa appena è
# disponibile (lo sconfitto sopravvive e ripiega: il percorso del ripiegamento); «tutti» = ogni gruppo
# armato marcia verso nord quando può, per cercare il contatto (altrimenti uno su due).
OPZIONI = set(sys.argv[5:])
DIARIO = CARTELLA / f"diario-{FORMATO}.jsonl"
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
    attiva(etichetta="Torna all'inizio", tipo="pulsante", ascolto=3)
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
           forze=[n for n in nomi if n.startswith("gruppo armato") or n.startswith("formazione")])
    cmd({"azione": "schermata", "nome": f"{FORMATO}-seconda-primavera", "ascolto": 0.3})
    # 5. La campagna dell'anno nuovo: le formazioni del regno, reclute comprese, sono sulla mappa.
    attiva(etichetta="Apri la campagna", tipo="pulsante", ascolto=3)
    attiva(prefisso=FRONTE[FORMATO], tipo="pulsante", ascolto=6)
    proprie = [n for n in etichette() if re.search(r"riga \d+, casella \d+", n) and PROPRIO.search(n)]
    diario("seconda_campagna", formazioni_sulla_mappa=len(proprie), etichette=proprie, stato=tocco_magico())


def main():
    if len(sys.argv) > 4 and sys.argv[4] == "regno":
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
