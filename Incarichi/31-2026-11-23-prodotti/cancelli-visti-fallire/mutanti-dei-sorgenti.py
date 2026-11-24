#!/usr/bin/env python3
"""I MUTANTI DEI SORGENTI dell'incarico 31.

Le prove nuove del pacchetto sono cancelli: ciascuna deve fallire quando la regola che sorveglia è
violata NEL CODICE, non soltanto in un passo costruito apposta. Questo script lo fa vedere: esporta
il pacchetto del commit corrente in una copia (dentro `Codice/.build/`, ignorata da git), vi applica
un mutante alla volta — una riga dei sorgenti cambiata —, esegue le prove del regno e della seconda
tappa, annota quali falliscono e con quale messaggio, e ripristina la riga. Prima di tutti esegue le
stesse prove sulla copia intatta, che devono passare.

I sorgenti del repo non vengono toccati: i mutanti vivono soltanto nella copia.

Uso: python3 mutanti-dei-sorgenti.py > mutanti-dei-sorgenti.txt
"""
import pathlib
import re
import shutil
import subprocess
import sys
import time

RADICE = pathlib.Path(__file__).resolve().parents[3]
COPIA = RADICE / "Codice" / ".build" / "mutanti-31"
PACCHETTO = COPIA / "Codice"
FILTRO = "Regno|ArriviDallaPatria|MiglioramentoInBattaglia"
TEMPO_MASSIMO = 900

MUTANTI = [
    ("la quota di mantenimento senza il minimo",
     "Sources/Motore/ForzeDelRegno.swift",
     "        max(valori.quotaMinima, Int(valori.quotaPerMisura.applicato(a: Int64(reparto.atomi))))",
     "        Int(valori.quotaPerMisura.applicato(a: Int64(reparto.atomi)))"),
    ("se il denaro non basta si scioglie per primo il reparto più anziano",
     "Sources/Motore/ForzeDelRegno.swift",
     "if scelto == nil || leva >= scelto!.leva { scelto = (f, r, leva) }",
     "if scelto == nil || leva <= scelto!.leva { scelto = (f, r, leva) }"),
    ("il mantenimento dichiarato e non prelevato",
     "Sources/Motore/MotoreRegno.swift",
     "        stato.riserve = stato.riserve - prelievo",
     "        stato.riserve = stato.riserve - Riserve()"),
    ("il lavoro compiuto alla prima stazione di una stagione è dato per la stagione dopo",
     "Sources/Motore/MotoreRegno.swift",
     "            if compiuto <= inizio { return stagione }",
     "            if compiuto < inizio { return stagione }"),
    ("il nome libero cercato sempre dall'inizio della lista",
     "Sources/Motore/ForzeDelRegno.swift",
     "            let indice = (posizione + passo) % nomi.count",
     "            let indice = passo % nomi.count"),
    ("chi parte si può cambiare a campagna aperta",
     "Sources/Motore/MotoreRegno.swift",
     "            case .aperta: return .nonValido(.campagnaAperta)\n"
     "            case .conclusa: return .nonValido(.campagnaGiaCondotta)\n"
     "            case .nonAperta: break\n"
     "            }\n"
     "            guard stato.forze.conosce(unita: unita) else { return .nonValido(.unitaIgnota) }",
     "            case .aperta: break\n"
     "            case .conclusa: return .nonValido(.campagnaGiaCondotta)\n"
     "            case .nonAperta: break\n"
     "            }\n"
     "            guard stato.forze.conosce(unita: unita) else { return .nonValido(.unitaIgnota) }"),
    ("il miglioramento che nessuno ha mantenuto resta",
     "Sources/Motore/ForzeDelRegno.swift",
     "                formazioni[f].composizione[r] = reparto.con(miglioramento: nil)",
     "                formazioni[f].composizione[r] = reparto"),
    ("il reparto addestrato colpisce come gli altri",
     "Sources/Motore/MotoreBattaglia.swift",
     "            base = miglioramento.capacitaOffensiva.applicato(a: base)",
     "            _ = miglioramento.capacitaOffensiva.applicato(a: base)"),
    ("la formazione tenuta in patria parte lo stesso",
     "Sources/Motore/PonteRegnoCampagna.swift",
     "        var formazioni = tutte.filter { $0.parteConLaCampagna && $0.arrivo == nil }",
     "        var formazioni = tutte.filter { $0.arrivo == nil }"),
    ("l'arrivo programmato un giorno dopo l'inizio della stagione",
     "Sources/Motore/PonteRegnoCampagna.swift",
     "giorno: posizione * calendario.giornatePerStagione + 1, nome: formazione.nome,",
     "giorno: posizione * calendario.giornatePerStagione + 2, nome: formazione.nome,"),
    ("chi nasce sul fronte può prendere un nome che il regno tiene",
     "Sources/Motore/MotoreCampagna.swift",
     "            if !riservati.contains(nome) { return (indice, nome) }",
     "            if riservati.count >= 0 { return (indice, nome) }"),
    ("le reclute entrano al quartier generale anche se è occupato",
     "Sources/Motore/MotoreCampagna.swift",
     "        return griglia.tutteLeCaselle\n            .filter { !occupate.contains($0) }\n            .min {",
     "        return griglia.tutteLeCaselle\n            .filter { _ in occupate.count >= 0 }\n            .min {"),
    ("i superstiti sul campo perdono il miglioramento",
     "Sources/Motore/PonteCampagnaBattaglia.swift",
     "                perSpecie[Specie(archetipo: sciame.archetipo, miglioramento: sciame.miglioramento,\n"
     "                                 leva: sciame.leva), default: 0] += Int(atomi)",
     "                perSpecie[Specie(archetipo: sciame.archetipo, miglioramento: nil,\n"
     "                                 leva: sciame.leva), default: 0] += Int(atomi)"),
    ("gli arrivi mai giunti si perdono con la fine della campagna",
     "Sources/Motore/PonteRegnoCampagna.swift",
     "        for arrivo in stato.arriviInAttesa ?? [] {\n            superstiti.append(",
     "        for arrivo in (stato.arriviInAttesa ?? []).prefix(0) {\n            superstiti.append("),
    ("due lavori sullo stesso reparto nello stesso inverno",
     "Sources/Motore/MotoreRegno.swift",
     "                guard !stato.lavori.contains(where: { $0.bersaglio == bersaglio }) else {",
     "                guard !stato.lavori.contains(where: { $0.bersaglio == bersaglio && $0.bersaglio == nil }) else {"),
    ("l'annuncio delle reclute di primavera dice che entrano con l'inverno",
     "Sources/Segnali/SignificatiRegno.swift",
     '            return testi.frase("regno.reclute_in_primavera", soggetto: nome, reparti).testo',
     '            return testi.frase("regno.reclute_con_l_inverno", soggetto: nome, reparti).testo'),
    ("l'arrivo consegnato il giorno dopo quello dichiarato",
     "Sources/Motore/MotoreCampagna.swift",
     "            guard arrivo.giorno <= stato.giorno, let casella = casellaDiArrivo(stato) else {",
     "            guard arrivo.giorno < stato.giorno, let casella = casellaDiArrivo(stato) else {"),
    ("chi è ancora in arrivo non raggiunge le altre con l'inverno",
     "Sources/Motore/ForzeDelRegno.swift",
     "            nuova.arrivo = nil\n            return nuova",
     "            nuova.arrivo = formazione.arrivo\n            return nuova"),
    ("la formazione tenuta in patria sparisce al rientro delle altre",
     "Sources/Motore/ForzeDelRegno.swift",
     "            if !formazione.parteConLaCampagna {\n                esito.append(formazione)\n",
     "            if !formazione.parteConLaCampagna {\n                _ = formazione\n"),
    ("l'addestramento mirato costa come per un solo atomo",
     "Sources/Motore/MotoreRegno.swift",
     "        guard let bersaglio, let misura = stato.forze.misura(di: bersaglio) else { return nil }\n"
     "        return costo(di: voce, misura: misura)",
     "        guard let bersaglio, let misura = stato.forze.misura(di: bersaglio) else { return nil }\n"
     "        return costo(di: voce, misura: min(misura, 1))"),
    ("nella campagna di un regno l'avversario prende i primi nomi liberi, come prima della correzione",
     "Sources/Motore/ScenarioCampagna.swift",
     "        let dalFondo = !riservati.isEmpty",
     "        let dalFondo = false && !riservati.isEmpty"),
]


def esegui_le_prove():
    """Esegue le prove filtrate nella copia. Restituisce (uscita, durata, testo)."""
    inizio = time.time()
    try:
        esito = subprocess.run(["swift", "test", "-j", "5", "--filter", FILTRO], cwd=PACCHETTO,
                               capture_output=True, text=True, timeout=TEMPO_MASSIMO)
        uscita, testo = esito.returncode, esito.stdout + esito.stderr
    except subprocess.TimeoutExpired as scaduto:
        uscita = -1
        testo = (scaduto.stdout or b"").decode("utf-8", "replace") if isinstance(scaduto.stdout, bytes) \
            else (scaduto.stdout or "")
        testo += "\nTEMPO MASSIMO SUPERATO"
    return uscita, int(time.time() - inizio), re.sub(r"\x1b\[[0-9;]*m", "", testo)


def riassumi(testo):
    """(prove avviate, prove passate, nomi delle fallite, messaggi d'errore, errori di compilazione).
    Si contano le righe dei singoli casi e non i totali di ogni fascio di prove: un fascio che si
    interrompe per un errore fatale non stampa il proprio totale, e i casi avviati lo dicono lo stesso."""
    avviate = len(re.findall(r"Test Case '-\[\S+ \S+\]' started", testo))
    passate = len(re.findall(r"Test Case '-\[\S+ \S+\]' passed", testo))
    fallite = sorted(set(re.findall(r"Test Case '-\[(\S+ \S+)\]' failed", testo)))
    errori = [riga.split("/Codice/", 1)[-1] for riga in testo.splitlines() if "error: -[" in riga]
    compilazione = [riga.split("/Codice/", 1)[-1] for riga in testo.splitlines()
                    if re.search(r"\.swift:\d+:\d+: error:", riga)]
    return avviate, passate, fallite, errori, compilazione


def main():
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=RADICE,
                            capture_output=True, text=True).stdout.strip()
    sporco = subprocess.run(["git", "status", "--short", "--", "Codice/Sources", "Codice/Tests"], cwd=RADICE,
                            capture_output=True, text=True).stdout.strip()
    if COPIA.exists():
        shutil.rmtree(COPIA)
    COPIA.mkdir(parents=True)
    archivio = subprocess.run(["git", "archive", "HEAD", "Codice"], cwd=RADICE, capture_output=True)
    subprocess.run(["tar", "-x", "-C", str(COPIA)], input=archivio.stdout, check=True)

    print("I MUTANTI DEI SORGENTI — incarico 31")
    print(f"pacchetto: esportazione del commit {commit} (git archive HEAD Codice); "
          f"sorgenti e prove del repo {'PULITI' if not sporco else 'CON MODIFICHE NON COMMITTATE'}")
    print(f"prove eseguite a ogni mutante: swift test -j 5 --filter '{FILTRO}'")
    print()

    uscita, durata, testo = esegui_le_prove()
    avviate, passate, fallite, _, compilazione = riassumi(testo)
    print(f"SENZA MUTANTI: uscita {uscita}, {avviate} prove avviate, {passate} passate, {len(fallite)} fallite, "
          f"{durata} s (comprende la prima compilazione della copia)")
    if uscita != 0:
        print("  la copia intatta non passa: non si prosegue")
        for riga in (compilazione or testo.splitlines()[-20:]):
            print("  " + riga[:400])
        sys.exit(1)
    print()

    uccisi = sopravvissuti = non_applicati = non_compilati = 0
    for numero, (nome, percorso, vecchio, nuovo) in enumerate(MUTANTI, 1):
        file = PACCHETTO / percorso
        originale = file.read_text(encoding="utf-8")
        print(f"MUTANTE {numero}: {nome}")
        print(f"  file: Codice/{percorso}")
        if originale.count(vecchio) != 1:
            print(f"  NON APPLICATO: la riga da cambiare compare {originale.count(vecchio)} volte")
            non_applicati += 1
            print()
            continue
        for riga in vecchio.split("\n"):
            print(f"  - {riga.strip()}")
        for riga in nuovo.split("\n"):
            print(f"  + {riga.strip()}")
        file.write_text(originale.replace(vecchio, nuovo), encoding="utf-8")
        try:
            uscita, durata, testo = esegui_le_prove()
        finally:
            file.write_text(originale, encoding="utf-8")
        avviate, passate, fallite, errori, compilazione = riassumi(testo)
        if uscita == 0:
            sopravvissuti += 1
            print(f"  SOPRAVVISSUTO: uscita 0, {avviate} prove avviate, {passate} passate, nessuna fallita, {durata} s")
        elif not fallite and compilazione:
            non_compilati += 1
            print(f"  NON COMPILA: uscita {uscita}, {durata} s")
            for riga in compilazione[:3]:
                print("    " + riga[:400])
        else:
            uccisi += 1
            print(f"  UCCISO: uscita {uscita}, {avviate} prove avviate, {passate} passate, {len(fallite)} fallite, {durata} s")
            if avviate > passate + len(fallite):
                print(f"    ({avviate - passate - len(fallite)} prove avviate e mai concluse: un fascio di prove "
                      "si è interrotto per un errore fatale)")
            for prova in fallite[:14]:
                print(f"    fallita: {prova}")
            if len(fallite) > 14:
                print(f"    … e altre {len(fallite) - 14}")
            for riga in errori[:2]:
                print("    " + riga[:520])
            if "TEMPO MASSIMO SUPERATO" in testo:
                print("    (tempo massimo superato)")
        print()
        sys.stdout.flush()

    print(f"IN TUTTO: {len(MUTANTI)} mutanti, {uccisi} uccisi, {sopravvissuti} sopravvissuti, "
          f"{non_compilati} che non compilano, {non_applicati} non applicati")


if __name__ == "__main__":
    main()
