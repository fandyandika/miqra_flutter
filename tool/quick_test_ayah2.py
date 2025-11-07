#!/usr/bin/env python3
"""Quick test: Convert surah 2 ayah 2 only."""

import json
import sys

# Test data
uthmani = "ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ فِيهِ هُدًى لِّلْمُتَّقِينَ"
indopak = "ذٰلِكَ الْكِتٰبُ لَا رَيْبَ ۛ فِيْهِ ۛ هُدًى لِّلْمُتَّقِيْنَۙ"
uth_start = 39
uth_end = 45

def score_char(c1, c2):
    if c1 == c2:
        return 2
    code1, code2 = ord(c1), ord(c2)
    if 0x0600 <= code1 <= 0x06FF and 0x0600 <= code2 <= 0x06FF:
        b1 = c1 if (code1 < 0x064B or code1 > 0x065F) else ''
        b2 = c2 if (code2 < 0x064B or code2 > 0x065F) else ''
        if b1 and b2 and b1 == b2:
            return 1
    return -1

def nw_align(u, i):
    n, m = len(u), len(i)
    gap = 1
    M = [[0] * (m + 1) for _ in range(n + 1)]
    for x in range(1, n + 1):
        M[x][0] = M[x-1][0] - gap
    for y in range(1, m + 1):
        M[0][y] = M[0][y-1] - gap
    for x in range(1, n + 1):
        for y in range(1, m + 1):
            M[x][y] = max(
                M[x-1][y-1] + score_char(u[x-1], i[y-1]),
                M[x-1][y] - gap,
                M[x][y-1] - gap
            )
    align = []
    x, y = n, m
    while x > 0 or y > 0:
        if x > 0 and y > 0 and M[x][y] == M[x-1][y-1] + score_char(u[x-1], i[y-1]):
            align.append((x-1, y-1))
            x -= 1
            y -= 1
        elif x > 0 and M[x][y] == M[x-1][y] - gap:
            x -= 1
        else:
            y -= 1
    return {ux: iy for ux, iy in align if score_char(u[ux], i[iy]) > 0}

mapping = nw_align(uthmani, indopak)

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

print(f"Uthmani: {uth_start}-{uth_end} -> {repr(uthmani[uth_start:uth_end])}")
print(f"Indopak: {indo_start}-{indo_end}")
if indo_start is not None and indo_end is not None:
    print(f"Indopak text: {repr(indopak[indo_start:indo_end])}")

