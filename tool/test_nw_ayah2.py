#!/usr/bin/env python3
"""Test Needleman-Wunsch for surah 2 ayah 2 specifically."""

# Uthmani (from XML)
uthmani = "ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ فِيهِ هُدًى لِّلْمُتَّقِينَ"

# Indopak (from SQL)
indopak = "ذٰلِكَ الْكِتٰبُ لَا رَيْبَ ۛ فِيْهِ ۛ هُدًى لِّلْمُتَّقِيْنَۙ"

def get_base_char(char: str) -> str:
    """Get base Arabic character."""
    code = ord(char)
    if 0x0600 <= code <= 0x06FF:
        if code < 0x064B or code > 0x065F:
            return char
    return ''

def score_char(char1: str, char2: str) -> int:
    if char1 == char2:
        return 2
    base1 = get_base_char(char1)
    base2 = get_base_char(char2)
    if base1 and base2 and base1 == base2:
        return 1
    return -1

def needleman_wunsch(uthmani: str, indopak: str, gap_penalty: int = 1):
    n, m = len(uthmani), len(indopak)
    
    # Initialize matrix
    M = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(1, n + 1):
        M[i][0] = M[i-1][0] - gap_penalty
    for j in range(1, m + 1):
        M[0][j] = M[0][j-1] - gap_penalty
    
    # Fill matrix
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            match = M[i-1][j-1] + score_char(uthmani[i-1], indopak[j-1])
            delete = M[i-1][j] - gap_penalty
            insert = M[i][j-1] - gap_penalty
            M[i][j] = max(match, delete, insert)
    
    # Traceback
    alignment = []
    i, j = n, m
    while i > 0 or j > 0:
        if i > 0 and j > 0 and M[i][j] == M[i-1][j-1] + score_char(uthmani[i-1], indopak[j-1]):
            alignment.append((i-1, j-1))
            i -= 1
            j -= 1
        elif i > 0 and M[i][j] == M[i-1][j] - gap_penalty:
            i -= 1
        else:
            j -= 1
    
    # Create mapping
    mapping = {}
    for uth_idx, indo_idx in alignment:
        if score_char(uthmani[uth_idx], indopak[indo_idx]) > 0:
            mapping[uth_idx] = indo_idx
    
    return mapping

# Test
print("Uthmani:", uthmani)
print("Indopak:", indopak)
print()

mapping = needleman_wunsch(uthmani, indopak)
print(f"Mapping: {len(mapping)} points")
print(f"Sample: {list(mapping.items())[:10]}")

# Test conversion for idghaam_no_ghunnah (Uthmani 39-45)
uth_start = 39
uth_end = 45

# Find closest mapped indices
indo_start = None
indo_end = None

for uth_idx in sorted(mapping.keys()):
    if uth_idx <= uth_start:
        indo_start = mapping[uth_idx]
    else:
        break

for uth_idx in sorted(mapping.keys(), reverse=True):
    if uth_idx >= uth_end:
        indo_end = mapping[uth_idx]
    else:
        break

print(f"\nUthmani span {uth_start}-{uth_end}: {repr(uthmani[uth_start:uth_end])}")
print(f"Converted to Indopak: {indo_start}-{indo_end}")
if indo_start is not None and indo_end is not None:
    print(f"Indopak text: {repr(indopak[indo_start:indo_end])}")

