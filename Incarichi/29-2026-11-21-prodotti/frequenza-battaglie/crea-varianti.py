#!/usr/bin/env python3
"""Crea le copie temporanee dei valori per le varianti della misura della frequenza (incarico 29).
Uso: python3 crea-varianti.py <cartella dei valori del gioco> <cartella di destinazione>"""
import copy, hashlib, json, pathlib, shutil, sys
src, base = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])

def variante(nome, modifica):
    dst = base / nome
    shutil.copytree(src, dst)
    modifica(dst)
    man = json.loads((dst / 'manifest.json').read_text())
    for f in man['impronte']:
        man['impronte'][f] = hashlib.sha256((dst / f).read_bytes()).hexdigest()
    (dst / 'manifest.json').write_text(json.dumps(man, indent=1, sort_keys=True))

def json_modifica(file, **kw):
    def m(d):
        c = json.loads((d / file).read_text()); c.update(kw)
        (d / file).write_text(json.dumps(c, indent=1))
    return m

def raggio3(d):
    json_modifica('conoscenza-campagna.json', raggio_osservazione=3)(d)
    r = json.loads((d / 'ricognizione-campagna.json').read_text()); r['raggio_esplorazione'] += 1
    (d / 'ricognizione-campagna.json').write_text(json.dumps(r, indent=1))

def secondo_armato(d):
    sc = json.loads((d / 'scenari-campagna.json').read_text())
    for v in sc.values():
        armati = [g for g in v['gruppi_avversario'] if g.get('categoria', 'armato') == 'armato']
        occupate = {(g['riga'], g['colonna']) for g in v['gruppi_avversario'] + v['gruppi_giocatore']}
        primo = armati[0]
        for dr, dc in [(0, 1), (0, -1), (1, 0), (1, 1), (1, -1), (0, 2), (0, -2)]:
            c = (primo['riga'] + dr, primo['colonna'] + dc)
            if c[1] >= 1 and c not in occupate:
                nuovo = copy.deepcopy(primo); nuovo['riga'], nuovo['colonna'] = c
                v['gruppi_avversario'].append(nuovo); break
    (d / 'scenari-campagna.json').write_text(json.dumps(sc, indent=1, ensure_ascii=False))

variante('aggressivita-300', json_modifica('condotta-campagna.json', aggressivita=300))
variante('aggressivita-700', json_modifica('condotta-campagna.json', aggressivita=700))
variante('difesa-150', json_modifica('condotta-campagna.json', difesa_quartier_generale=150, minaccia_rifornimento=75))
variante('raggio-3', raggio3)
variante('due-armati-avversari', secondo_armato)
