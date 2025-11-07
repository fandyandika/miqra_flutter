#!/usr/bin/env python3
"""Test adjustment logic for surah 3 ayah 1."""

from convert_uthmani_tajwid import adjust_indices_for_bismillah, calculate_bismillah_offset

# Test surah 3 ayah 1
surah_num = 3
ayah_num = 1
spans = [
    {"rule": "madd_6", "start": 40, "end": 42},
    {"rule": "madd_6", "start": 42, "end": 44}
]

print(f"Testing surah {surah_num} ayah {ayah_num}")
print(f"Bismillah offset: {calculate_bismillah_offset()}")
print(f"Original spans: {spans}")

adjusted = adjust_indices_for_bismillah(surah_num, ayah_num, spans)
print(f"Adjusted spans: {adjusted}")

# Test surah 1 ayah 1 (should not adjust)
print("\nTesting surah 1 ayah 1 (should not adjust)")
spans_surah1 = [{"rule": "madd_6", "start": 40, "end": 42}]
adjusted_surah1 = adjust_indices_for_bismillah(1, 1, spans_surah1)
print(f"Original: {spans_surah1}")
print(f"Adjusted: {adjusted_surah1}")

