#!/usr/bin/env python3
"""Sintesi dei rilievi dell'esplorazione con VoiceOver (incarico 27, quarta parte).

Legge i file `rilievi-<configurazione>.jsonl` scritti da `scripts/esplora-interfaccia.sh` (una
riga JSON per rilievo, prodotta dalla prova `EsplorazioneInterfacciaTest`) e scrive, nella stessa
cartella, `sintesi-automatica.md`: per ogni schermata e configurazione ciò che la prova ha misurato,
e l'elenco dei SEGNALI da esaminare (non giudizi: le osservazioni con gravità le scrive chi esamina).

Uso: python3 scripts/sintetizza-esplorazione.py <cartella dei rilievi>
"""
import collections, json, pathlib, sys

cartella = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
rilievi = []
for f in sorted(cartella.glob("rilievi-*.jsonl")):
    for riga in f.read_text(encoding="utf-8").splitlines():
        riga = riga.strip()
        if riga:
            try:
                rilievi.append(json.loads(riga))
            except json.JSONDecodeError:
                pass

configurazioni = sorted({r.get("configurazione", "?") for r in rilievi})
schermate = []
for r in rilievi:
    s = r.get("schermata")
    if s and s not in schermate:
        schermate.append(s)

out = ["# Sintesi automatica dell'esplorazione", "",
       f"Rilievi letti: {len(rilievi)} (conteggio di questo script), configurazioni: {', '.join(configurazioni)}.", ""]

segnali = collections.defaultdict(list)
for s in schermate:
    out.append(f"## {s}")
    out.append("")
    out.append("| configurazione | pronunce | atterraggio del fuoco | elementi nell'albero | verifica automatica | in vista, non sentiti | sentiti, non nell'albero |")
    out.append("|---|---|---|---|---|---|---|")
    for c in configurazioni:
        voce = [r for r in rilievi if r.get("schermata") == s and r.get("configurazione") == c and r.get("giro") == "voiceover" and "pronunce" in r]
        vista = [r for r in rilievi if r.get("schermata") == s and r.get("configurazione") == c and r.get("giro") == "vista" and "elementi" in r]
        if not voce and not vista:
            continue
        v = voce[-1] if voce else {}
        w = vista[-1] if vista else {}
        nonSentiti = w.get("in_vista_ma_non_sentiti", [])
        nonVisti = w.get("sentiti_ma_non_nell_albero", [])
        verifica = w.get("verifica_automatica", [])
        out.append(f"| {c} | {v.get('numero_pronunce', '–')}{' (troncato)' if v.get('troncato') else ''} | {str(v.get('atterraggio_del_fuoco', '–'))[:60]} | {w.get('numero_elementi', '–')} | {len(verifica)} | {len(nonSentiti)} | {len(nonVisti)} |")
        for x in verifica:
            segnali[(s, "verifica automatica")].append(f"{c}: {x}")
        for x in nonSentiti:
            segnali[(s, "in vista ma non sentito")].append(f"{c}: «{x}»")
        for x in nonVisti:
            segnali[(s, "sentito ma non nell'albero")].append(f"{c}: «{x}»")
        for x in w.get("etichette_come_chiavi", []):
            segnali[(s, "etichetta che sembra una chiave")].append(f"{c}: «{x}»")
        if w.get("controlli_senza_etichetta"):
            segnali[(s, "controlli senza etichetta")].append(f"{c}: {w['controlli_senza_etichetta']}")
        piccoli = [e for e in w.get("elementi", []) if e.get("tipo") in ("pulsante", "cella", "interruttore", "cursore", "segmenti")
                   and e.get("sullo_schermo") and not e.get("bersaglio_almeno_44")]
        if piccoli:
            segnali[(s, "bersagli sotto i 44 punti")].append(f"{c}: {len(piccoli)}, per esempio «{piccoli[0].get('etichetta')}» {piccoli[0].get('cornice')}")
        fuori = [e for e in w.get("elementi", []) if e.get("tipo") in ("pulsante", "interruttore") and not e.get("sullo_schermo")]
        if fuori:
            segnali[(s, "pulsanti fuori dallo schermo")].append(f"{c}: {', '.join('«'+str(e.get('etichetta'))+'»' for e in fuori[:6])}")
        if voce:
            p = voce[-1].get("pronunce", [])
            doppie = [x for x, n in collections.Counter(p).items() if n > 1]
            if doppie:
                segnali[(s, "pronunce ripetute")].append(f"{c}: {', '.join('«'+d[:60]+'»' for d in doppie[:4])}")
    out.append("")

azioni = [r for r in rilievi if "azione" in r]
out.append("## Le azioni")
out.append("")
out.append("| configurazione | schermata | azione | esito | fuoco prima | subito dopo | dopo 1,5 s | fuoco mosso da solo |")
out.append("|---|---|---|---|---|---|---|---|")
for r in azioni:
    mosso = r.get("fuoco_mosso_da_solo")
    out.append(f"| {r.get('configurazione')} | {r.get('schermata')} | {r.get('azione')} | {r.get('esito', r.get('comparso', ''))} | {str(r.get('fuoco_prima_dell_attivazione', ''))[:50]} | {str(r.get('pronuncia_subito_dopo', ''))[:60]} | {str(r.get('pronuncia_dopo_1_5_s', ''))[:60]} | {mosso if mosso is not None else ''} |")
    if r.get("esito") == "elemento non trovato":
        segnali[(r.get("schermata"), "elemento da attivare non trovato")].append(f"{r.get('configurazione')}: {r.get('azione')}")
    if mosso:
        segnali[(r.get("schermata"), "pronuncia cambiata senza input dopo l'azione")].append(
            f"{r.get('configurazione')}: {r.get('azione')} — «{str(r.get('pronuncia_subito_dopo'))[:70]}» → «{str(r.get('pronuncia_dopo_1_5_s'))[:70]}»")
out.append("")

eventi = [r for r in rilievi if "evento" in r]
out.append("## Eventi del percorso")
out.append("")
for r in eventi:
    out.append(f"- {r.get('configurazione')} — {r.get('schermata')}: {r.get('evento')} {r.get('dettaglio', '')} {r.get('giornate', '')}")
out.append("")

out.append("## Segnali da esaminare")
out.append("")
for (s, tipo), voci in segnali.items():
    out.append(f"### {s} — {tipo} ({len(voci)})")
    for v in voci[:40]:
        out.append(f"- {v}")
    if len(voci) > 40:
        out.append(f"- … e altri {len(voci) - 40}")
    out.append("")

(cartella / "sintesi-automatica.md").write_text("\n".join(out), encoding="utf-8")
print(f"sintesi scritta: {cartella / 'sintesi-automatica.md'} ({len(rilievi)} rilievi, {len(segnali)} gruppi di segnali)")
