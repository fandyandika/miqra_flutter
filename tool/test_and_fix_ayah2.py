#!/usr/bin/env python3
"""Test alignment and fix surah 2 ayah 2 directly."""

import json
import difflib
from pathlib import Path

# Texts
uthmani = "ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ فِيهِ هُدًى لِّلْمُتَّقِينَ"
indopak = "ذٰلِكَ الْكِتٰبُ لَا رَيْبَ ۛ فِيْهِ ۛ هُدًى لِّلْمُتَّقِيْنَۙ"

# Uthmani indices
uth_start = 39
uth_end = 45

# Align
matcher = difflib.SequenceMatcher(None, uthmani, indopak, autojunk=False)
mapping = {}

for tag, i1, i2, j1, j2 in matcher.get_opcodes():
    if tag in ('equal', 'replace'):
        for k in range(min(i2 - i1, j2 - j1)):
            mapping[i1 + k] = j1 + k

# Convert
indo_start = None
for ux in sorted(mapping.keys()):
    if ux <= uth_start:
        indo_start = mapping[ux]
    else:
        break

indo_end = None
for ux in sorted(mapping.keys(), reverse=True):
    if ux >= uth_end:
        indo_end = mapping[ux]
    else:
        break

print(f"Uthmani {uth_start}-{uth_end}: {repr(uthmani[uth_start:uth_end])}")
print(f"Indopak {indo_start}-{indo_end}: {repr(indopak[indo_start:indo_end]) if indo_start is not None and indo_end is not None else 'N/A'}")

# Update JSON
pr = Path(__file__).parent.parent
fp = pr / "assets" / "data" / "tajwid" / "002.json"

with open(fp, 'r', encoding='utf-8') as f:
    data = json.load(f)

for v in data['verses']:
    if v['ayah'] == 2:
        for s in v['spans']:
            if s['rule'] == 'idghaam_no_ghunnah':
                if indo_start is not None and indo_end is not None:
                    s['start'] = indo_start
                    s['end'] = indo_end
                    print(f"Updated: {indo_start}-{indo_end}")
                break
        break

with open(fp, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"Saved to {fp}")

