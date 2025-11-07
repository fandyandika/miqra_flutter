#!/usr/bin/env python3
"""Direct fix for surah 2 ayah 2 using difflib."""

import difflib
import json
from pathlib import Path

# Texts
uthmani = "ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ فِيهِ هُدًى لِّلْمُتَّقِينَ"
indopak = "ذٰلِكَ الْكِتٰبُ لَا رَيْبَ ۛ فِيْهِ ۛ هُدًى لِّلْمُتَّقِيْنَۙ"

# Uthmani indices from tajwid data
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

# Write result to file
result_file = Path(__file__).parent.parent / "test_result.txt"
with open(result_file, 'w', encoding='utf-8') as f:
    f.write(f"Uthmani: {uthmani}\n")
    f.write(f"Indopak: {indopak}\n\n")
    f.write(f"Uthmani span {uth_start}-{uth_end}: {repr(uthmani[uth_start:uth_end])}\n")
    f.write(f"Mapping points: {len(mapping)}\n")
    f.write(f"Indopak span: {indo_start}-{indo_end}\n")
    if indo_start is not None and indo_end is not None:
        f.write(f"Indopak text: {repr(indopak[indo_start:indo_end])}\n")

# Update JSON
project_root = Path(__file__).parent.parent
tajwid_path = project_root / "assets" / "data" / "tajwid" / "002.json"

with open(tajwid_path, 'r', encoding='utf-8') as f:
    tajwid_data = json.load(f)

for verse in tajwid_data['verses']:
    if verse['ayah'] == 2:
        for span in verse['spans']:
            if span['rule'] == 'idghaam_no_ghunnah':
                if indo_start is not None and indo_end is not None:
                    span['start'] = indo_start
                    span['end'] = indo_end
                break
        break

with open(tajwid_path, 'w', encoding='utf-8') as f:
    json.dump(tajwid_data, f, ensure_ascii=False, indent=2)

print(f"Result saved to {result_file}")
print(f"Updated {tajwid_path}")

