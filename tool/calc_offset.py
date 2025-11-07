#!/usr/bin/env python3
"""Calculate text length and offset for surah 2 ayah 1."""

text = "الۤمّۤ ۚ"
bismillah = "بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ "

print(f"Text: {text}")
print(f"Text length: {len(text)}")
print(f"\nCharacter breakdown:")
for i, char in enumerate(text):
    print(f"  {i}: {repr(char)} (U+{ord(char):04X})")

print(f"\nBismillah: {bismillah}")
print(f"Bismillah length: {len(bismillah)}")

print(f"\nOriginal indices from Uthmani:")
print(f"  Span 1: start=40, end=42")
print(f"  Span 2: start=42, end=44")

print(f"\nAdjusted indices (subtract {len(bismillah)}):")
print(f"  Span 1: start={40 - len(bismillah)}, end={42 - len(bismillah)}")
print(f"  Span 2: start={42 - len(bismillah)}, end={44 - len(bismillah)}")

print(f"\nVerification:")
adjusted_start1 = 40 - len(bismillah)
adjusted_end1 = 42 - len(bismillah)
adjusted_start2 = 42 - len(bismillah)
adjusted_end2 = 44 - len(bismillah)

if 0 <= adjusted_start1 < len(text) and 0 <= adjusted_end1 <= len(text):
    print(f"  Span 1 text: {repr(text[adjusted_start1:adjusted_end1])}")
else:
    print(f"  Span 1: OUT OF BOUNDS")

if 0 <= adjusted_start2 < len(text) and 0 <= adjusted_end2 <= len(text):
    print(f"  Span 2 text: {repr(text[adjusted_start2:adjusted_end2])}")
else:
    print(f"  Span 2: OUT OF BOUNDS")

