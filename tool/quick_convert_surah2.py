#!/usr/bin/env python3
"""Quick convert surah 2 only - test version."""

import json
import sys
import xml.etree.ElementTree as ET
import difflib
from pathlib import Path

EXCLUDED = {"hamzat_wasl", "lam_shamsiyyah", "madd_2", "madd_246", "silent"}

# Paths
pr = Path(__file__).parent.parent
xp = pr / "assets" / "data" / "quran" / "quran-uthmani.xml"
sp = pr / "assets" / "data" / "quran" / "quran-indonesia.sql"
tp = pr / "assets" / "data" / "quran" / "quran-tajweed-master" / "output" / "tajweed.hafs.uthmani-pause-sajdah.json"
output_file = pr / "assets" / "data" / "tajwid" / "002.json"
log_file = pr / "surah2_convert.log"

with open(log_file, 'w', encoding='utf-8') as log:
    log.write("Starting surah 2 conversion...\n")
    
    # Parse XML for surah 2
    log.write("Parsing XML...\n")
    tree = ET.parse(str(xp))
    root = tree.getroot()
    uthmani_verses = {}
    for sura in root.findall('sura'):
        if int(sura.get('index')) == 2:
            for aya in sura.findall('aya'):
                an = int(aya.get('index'))
                txt = aya.get('text', '')
                if an == 1:
                    b = aya.get('bismillah')
                    if b:
                        txt = b + ' ' + txt
                uthmani_verses[an] = txt
            break
    log.write(f"Found {len(uthmani_verses)} Uthmani verses\n")
    
    # Parse SQL for surah 2
    log.write("Parsing SQL...\n")
    indopak_verses = {}
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
            # Simple parsing
            vs = []
            c = []
            iq = False
            for ch in vc:
                if ch == '"' and (not c or c[-1] != '\\'):
                    iq = not iq
                if ch == ',' and not iq:
                    vs.append("".join(c))
                    c = []
                else:
                    c.append(ch)
            if c:
                vs.append("".join(c))
            # Clean quotes
            for i in range(len(vs)):
                v = vs[i].strip()
                if v.startswith('"') and v.endswith('"'):
                    vs[i] = v[1:-1].replace('""', '"')
            if len(vs) < 6:
                continue
            try:
                sid = int(vs[1])
                if sid != 2:
                    continue
                vid = int(vs[2])
                at = vs[3]
                if at and ord(at[0]) == 0xFEFF:
                    at = at[1:]
                indopak_verses[vid] = at.strip()
            except:
                continue
    log.write(f"Found {len(indopak_verses)} Indopak verses\n")
    
    # Load tajwid for surah 2
    log.write("Loading tajwid...\n")
    with open(str(tp), 'r', encoding='utf-8') as f:
        all_tajwid = json.load(f)
    surah2_tajwid = [e for e in all_tajwid if e["surah"] == 2]
    log.write(f"Found {len(surah2_tajwid)} tajwid entries\n")
    
    # Convert
    log.write("Converting...\n")
    verses = []
    total_converted = 0
    
    for entry in surah2_tajwid:
        an = entry["ayah"]
        anns = entry["annotations"]
        
        if an not in uthmani_verses or an not in indopak_verses:
            continue
        
        ut = uthmani_verses[an]
        it = indopak_verses[an]
        
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
                total_converted += 1
        
        verses.append({"ayah": an, "spans": fs})
        
        if an <= 3:
            log.write(f"  Ayah {an}: {len(fs)} spans\n")
    
    # Save
    surah_data = {
        "surah_number": 2,
        "verses": sorted(verses, key=lambda v: v["ayah"])
    }
    
    with open(str(output_file), 'w', encoding='utf-8') as f:
        json.dump(surah_data, f, ensure_ascii=False, indent=2)
    
    total_spans = sum(len(v["spans"]) for v in surah_data["verses"])
    log.write(f"\nDone: {len(verses)} verses, {total_spans} spans, {total_converted} converted\n")
    
    # Show sample
    ayah2 = next((v for v in verses if v["ayah"] == 2), None)
    if ayah2:
        log.write(f"\nSample - Ayah 2:\n")
        for s in ayah2["spans"]:
            log.write(f"  {s['rule']}: {s['start']}-{s['end']}\n")

print(f"Conversion complete! Check {log_file}")

