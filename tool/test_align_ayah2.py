#!/usr/bin/env python3
"""Test alignment for surah 2 ayah 2 specifically."""

# Uthmani (from XML)
uthmani = "ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ فِيهِ هُدًى لِّلْمُتَّقِينَ"

# Indopak (from SQL)
indopak = "ذٰلِكَ الْكِتٰبُ لَا رَيْبَ ۛ فِيْهِ ۛ هُدًى لِّلْمُتَّقِيْنَۙ"

print("Uthmani:", uthmani)
print("Indopak:", indopak)
print()

# Find idghaam_no_ghunnah position in Uthmani
# Looking for "هُدًى لِّلْمُتَّقِينَ"
# Tanwin (ً) and Lam (ل)

print("Character positions in Uthmani:")
for i, char in enumerate(uthmani):
    marker = ""
    if char == 'ً':
        marker = " <-- TANWIN"
    elif char == 'ل' and i > 30:
        marker = " <-- LAM (idghaam)"
    print(f"{i:3d}: {repr(char)} U+{ord(char):04X}{marker}")

print("\nCharacter positions in Indopak:")
for i, char in enumerate(indopak):
    marker = ""
    if char == 'ً':
        marker = " <-- TANWIN"
    elif char == 'ل' and i > 30:
        marker = " <-- LAM (idghaam)"
    print(f"{i:3d}: {repr(char)} U+{ord(char):04X}{marker}")

# Find idghaam in Uthmani
uth_tanwin = uthmani.find('ً')
uth_lam = uthmani.find('ل', uth_tanwin)
print(f"\nUthmani idghaam: tanwin at {uth_tanwin}, lam at {uth_lam}")

# Find idghaam in Indopak
ind_tanwin = indopak.find('ً')
ind_lam = indopak.find('ل', ind_tanwin)
print(f"Indopak idghaam: tanwin at {ind_tanwin}, lam at {ind_lam}")

# Current tajwid data says: start=39, end=45 (Uthmani indices)
print(f"\nCurrent tajwid indices (Uthmani): start=39, end=45")
print(f"Uthmani text at 39-45: {repr(uthmani[39:45])}")

# What should it be in Indopak?
print(f"\nSuggested Indopak indices: start={ind_tanwin}, end={ind_lam + 1}")
print(f"Indopak text at {ind_tanwin}-{ind_lam + 1}: {repr(indopak[ind_tanwin:ind_lam + 1])}")

