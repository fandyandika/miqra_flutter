#!/usr/bin/env python3
"""Fix surah 2 ayah 2 idghaam_no_ghunnah position."""

import json
import sys
from pathlib import Path

# Uthmani text (from XML)
uthmani = "ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ فِيهِ هُدًى لِّلْمُتَّقِينَ"

# Indopak text (from SQL)
indopak = "ذٰلِكَ الْكِتٰبُ لَا رَيْبَ ۛ فِيْهِ ۛ هُدًى لِّلْمُتَّقِيْنَۙ"

# Uthmani indices from tajwid data
uth_start = 39
uth_end = 45

print("Uthmani text:")
print(f"  Full: {uthmani}")
print(f"  Length: {len(uthmani)}")
print(f"  Span {uth_start}-{uth_end}: {repr(uthmani[uth_start:uth_end])}")

print("\nIndopak text:")
print(f"  Full: {indopak}")
print(f"  Length: {len(indopak)}")

# Find "هُدًى لِّلْمُتَّقِيْنَ" in both
print("\nFinding idghaam_no_ghunnah (tanwin + Lam):")

# In Uthmani
uth_huda = uthmani.find("هُدًى")
uth_lam = uthmani.find("ل", uth_huda)
print(f"  Uthmani: 'هُدًى' at {uth_huda}, Lam at {uth_lam}")

# In Indopak
ind_huda = indopak.find("هُدًى")
ind_lam = indopak.find("ل", ind_huda)
print(f"  Indopak: 'هُدًى' at {ind_huda}, Lam at {ind_lam}")

# Find tanwin position
uth_tanwin = uthmani.find('ً', uth_huda)
ind_tanwin = indopak.find('ً', ind_huda)
print(f"  Uthmani tanwin: {uth_tanwin}")
print(f"  Indopak tanwin: {ind_tanwin}")

# Calculate offset
# Uthmani span 39-45 should map to Indopak
# Let's find what's at 39-45 in Uthmani and find equivalent in Indopak

print(f"\nMapping calculation:")
print(f"  Uthmani 39-45 covers: {repr(uthmani[39:45])}")

# Find this substring in Indopak (approximately)
# The idghaam is at tanwin to Lam
ind_start = ind_tanwin
ind_end = ind_lam + 1

print(f"  Suggested Indopak span: {ind_start}-{ind_end}")
print(f"  Indopak text at span: {repr(indopak[ind_start:ind_end])}")

# Update JSON
project_root = Path(__file__).parent.parent
tajwid_path = project_root / "assets" / "data" / "tajwid" / "002.json"

with open(tajwid_path, 'r', encoding='utf-8') as f:
    tajwid_data = json.load(f)

for verse in tajwid_data['verses']:
    if verse['ayah'] == 2:
        for span in verse['spans']:
            if span['rule'] == 'idghaam_no_ghunnah':
                print(f"\nUpdating:")
                print(f"  Old: {span['start']}-{span['end']}")
                span['start'] = ind_start
                span['end'] = ind_end
                print(f"  New: {span['start']}-{span['end']}")
                break
        break

with open(tajwid_path, 'w', encoding='utf-8') as f:
    json.dump(tajwid_data, f, ensure_ascii=False, indent=2)

print(f"\n✓ Updated {tajwid_path}")

