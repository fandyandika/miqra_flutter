#!/usr/bin/env python3
"""Final conversion script - generates accurate tajwid JSON files."""

import json
import sys
import xml.etree.ElementTree as ET
import difflib
from pathlib import Path

EXCLUDED = {"hamzat_wasl", "lam_shamsiyyah", "madd_2", "madd_246", "silent"}

def main():
    pr = Path(__file__).parent.parent
    xp = pr / "assets" / "data" / "quran" / "quran-uthmani.xml"
    sp = pr / "assets" / "data" / "quran" / "quran-indonesia.sql"
    tp = pr / "assets" / "data" / "quran" / "quran-tajweed-master" / "output" / "tajweed.hafs.uthmani-pause-sajdah.json"
    od = pr / "assets" / "data" / "tajwid"
    
    # Parse XML
    print("Parsing XML...", file=sys.stderr)
    tree = ET.parse(str(xp))
    root = tree.getroot()
    ud = {}
    for sura in root.findall('sura'):
        sn = int(sura.get('index'))
        ud[sn] = {}
        for aya in sura.findall('aya'):
            an = int(aya.get('index'))
            txt = aya.get('text', '')
            if sn not in (1, 9) and an == 1:
                b = aya.get('bismillah')
                if b:
                    txt = b + ' ' + txt
            ud[sn][an] = txt
    
    # Parse SQL
    print("Parsing SQL...", file=sys.stderr)
    id_ = {}
    with open(str(sp), 'r', encoding='utf-8') as f:
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
            vs = []
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
                    vs.append("".join(c))
                    c = []
                    continue
                c.append(ch)
            if c:
                vs.append("".join(c))
            for i in range(len(vs)):
                v = vs[i].strip()
                if v.startswith('"') and v.endswith('"'):
                    v = v[1:-1]
                    v = v.replace('""', '"')
                    vs[i] = v
            if len(vs) < 6:
                continue
            sid = int(vs[1])
            vid = int(vs[2])
            at = vs[3]
            if at and len(at) > 0 and ord(at[0]) == 0xFEFF:
                at = at[1:]
            if sid not in id_:
                id_[sid] = {}
            id_[sid][vid] = at.strip()
    
    # Load tajwid
    print("Loading tajwid...", file=sys.stderr)
    with open(str(tp), 'r', encoding='utf-8') as f:
        tj = json.load(f)
    
    # Convert
    print("Converting...", file=sys.stderr)
    surahs = {}
    tc = 0
    
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
        
        # Align
        m = difflib.SequenceMatcher(None, ut, it, autojunk=False)
        mp = {}
        for tag, i1, i2, j1, j2 in m.get_opcodes():
            if tag in ('equal', 'replace'):
                for k in range(min(i2 - i1, j2 - j1)):
                    mp[i1 + k] = j1 + k
        
        # Convert spans
        fs = []
        for a in anns:
            if a["rule"] in EXCLUDED:
                continue
            
            # Convert indices
            us = a["start"]
            ue = a["end"]
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
                fs.append({"rule": a["rule"], "start": is_, "end": ie})
                tc += 1
        
        if sn not in surahs:
            surahs[sn] = {"surah_number": sn, "verses": []}
        
        surahs[sn]["verses"].append({"ayah": an, "spans": fs})
        
        if (idx + 1) % 1000 == 0:
            print(f"  {idx + 1}/{len(tj)}", file=sys.stderr)
    
    # Save
    import os
    os.makedirs(str(od), exist_ok=True)
    
    print("Saving files...", file=sys.stderr)
    for sn in sorted(surahs.keys()):
        sd = surahs[sn]
        sd["verses"].sort(key=lambda v: v["ayah"])
        
        fn = f"{sn:03d}.json"
        fp = od / fn
        
        with open(str(fp), 'w', encoding='utf-8') as f:
            json.dump(sd, f, ensure_ascii=False, indent=2)
        
        if sn <= 3:
            ts = sum(len(v["spans"]) for v in sd["verses"])
            print(f"  {fn}: {len(sd['verses'])} verses, {ts} spans", file=sys.stderr)
    
    print(f"Done: {len(surahs)} surahs, {tc} spans converted", file=sys.stderr)

if __name__ == "__main__":
    main()

