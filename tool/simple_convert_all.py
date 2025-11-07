#!/usr/bin/env python3
"""Simple script to convert all tajwid using difflib - writes output directly."""

import json
import sys
import xml.etree.ElementTree as ET
import difflib
from pathlib import Path

EXCLUDED = {"hamzat_wasl", "lam_shamsiyyah", "madd_2", "madd_246", "silent"}

def parse_xml(xml_path):
    tree = ET.parse(xml_path)
    root = tree.getroot()
    data = {}
    for sura in root.findall('sura'):
        sn = int(sura.get('index'))
        data[sn] = {}
        for aya in sura.findall('aya'):
            an = int(aya.get('index'))
            txt = aya.get('text', '')
            if sn not in (1, 9) and an == 1:
                b = aya.get('bismillah')
                if b:
                    txt = b + ' ' + txt
            data[sn][an] = txt
    return data

def parse_sql(sql_path):
    data = {}
    with open(sql_path, 'r', encoding='utf-8') as f:
        for line in f:
            if not line.strip().startswith('INSERT INTO'):
                continue
            vi = line.find('VALUES')
            if vi == -1:
                continue
            vp = line[vi + 6:].strip()
            if not vp.startswith('(') or not vp.endswith(');'):
                continue
            vc = vp[1:-2]
            vs = _parse(vc)
            if len(vs) < 6:
                continue
            sid = int(vs[1])
            vid = int(vs[2])
            at = vs[3]
            if at and len(at) > 0 and ord(at[0]) == 0xFEFF:
                at = at[1:]
            if sid not in data:
                data[sid] = {}
            data[sid][vid] = at.strip()
    return data

def _parse(vc):
    r = []
    c = []
    iq = False
    en = False
    for ch in vc:
        if en:
            c.append(ch)
            en = False
            continue
        if ch == '\\':
            en = True
            c.append(ch)
            continue
        if ch == '"':
            iq = not iq
            c.append(ch)
            continue
        if ch == ',' and not iq:
            r.append("".join(c))
            c = []
            continue
        c.append(ch)
    if c:
        r.append("".join(c))
    for i in range(len(r)):
        v = r[i].strip()
        if v.startswith('"') and v.endswith('"'):
            v = v[1:-1]
            v = v.replace('""', '"')
            r[i] = v
    return r

def align(u, i):
    m = difflib.SequenceMatcher(None, u, i, autojunk=False)
    mp = {}
    for tag, i1, i2, j1, j2 in m.get_opcodes():
        if tag in ('equal', 'replace'):
            for k in range(min(i2 - i1, j2 - j1)):
                mp[i1 + k] = j1 + k
    return mp

def convert(us, ue, mp):
    if not mp:
        return None
    is_ = None
    for ux in sorted(mp.keys()):
        if ux <= us:
            is_ = mp[ux]
        else:
            break
    ie = None
    for ux in sorted(mp.keys(), reverse=True):
        if ux >= ue:
            ie = mp[ux]
        else:
            break
    if is_ is not None and ie is not None and ie > is_:
        return (is_, ie)
    return None

def main():
    pr = Path(__file__).parent.parent
    xp = pr / "assets" / "data" / "quran" / "quran-uthmani.xml"
    sp = pr / "assets" / "data" / "quran" / "quran-indonesia.sql"
    tp = pr / "assets" / "data" / "quran" / "quran-tajweed-master" / "output" / "tajweed.hafs.uthmani-pause-sajdah.json"
    od = pr / "assets" / "data" / "tajwid"
    
    # Write to file for debugging
    log = pr / "convert.log"
    with open(log, 'w', encoding='utf-8') as f:
        f.write("Starting conversion...\n")
        f.flush()
        
        # Parse
        f.write("Parsing XML...\n")
        f.flush()
        ud = parse_xml(str(xp))
        f.write(f"XML: {len(ud)} surahs\n")
        f.flush()
        
        f.write("Parsing SQL...\n")
        f.flush()
        id_ = parse_sql(str(sp))
        f.write(f"SQL: {len(id_)} surahs\n")
        f.flush()
        
        # Load tajwid
        f.write("Loading tajwid...\n")
        f.flush()
        with open(tp, 'r', encoding='utf-8') as tf:
            tj = json.load(tf)
        f.write(f"Tajwid: {len(tj)} entries\n")
        f.flush()
        
        # Convert
        surahs = {}
        tc = 0
        ts = 0
        
        f.write("Converting...\n")
        f.flush()
        
        for idx, e in enumerate(tj):
            sn = e["surah"]
            an = e["ayah"]
            anns = e["annotations"]
            
            if sn not in ud or an not in ud[sn]:
                continue
            if sn not in id_ or an not in id_[sn]:
                continue
            
            ut = ud[sn][an]
            it = id_[sn][an]
            
            mp = align(ut, it)
            
            fs = []
            for a in anns:
                if a["rule"] in EXCLUDED:
                    continue
                cv = convert(a["start"], a["end"], mp)
                if cv:
                    fs.append({"rule": a["rule"], "start": cv[0], "end": cv[1]})
                    tc += 1
                else:
                    ts += 1
            
            if sn not in surahs:
                surahs[sn] = {"surah_number": sn, "verses": []}
            
            surahs[sn]["verses"].append({"ayah": an, "spans": fs})
            
            if (idx + 1) % 1000 == 0:
                f.write(f"  {idx + 1}/{len(tj)}\n")
                f.flush()
        
        # Save
        import os
        os.makedirs(od, exist_ok=True)
        
        f.write("Saving files...\n")
        f.flush()
        
        for sn in sorted(surahs.keys()):
            sd = surahs[sn]
            sd["verses"].sort(key=lambda v: v["ayah"])
            
            fn = f"{sn:03d}.json"
            fp = od / fn
            
            with open(fp, 'w', encoding='utf-8') as of:
                json.dump(sd, of, ensure_ascii=False, indent=2)
            
            if sn <= 3:
                ts = sum(len(v["spans"]) for v in sd["verses"])
                f.write(f"  {fn}: {len(sd['verses'])} verses, {ts} spans\n")
        
        f.write(f"\nDone: {len(surahs)} surahs, {tc} converted, {ts} skipped\n")
    
    print(f"Conversion complete! Check {log}")

if __name__ == "__main__":
    main()

