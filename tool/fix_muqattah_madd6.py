#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fix missing madd_6 spans for muqatta'ah letters in ayat 1.

This script fixes:
- Surah 3, 29, 30, 31, 32: Add madd_6 for Mim in الۤمّۤ
- Surah 7: Add madd_6 for Shad in الۤمّۤصۤ
- Surah 13: Add madd_6 for Ra in الۤمّۤرٰۗ
- Surah 19: Add 5 madd_6 for كهيعص
- Surah 41-46: Add 2 madd_6 for حٰمۤ
"""

import json
import sys
from pathlib import Path

# Fix encoding for Windows console
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')


def fix_surah(file_path, surah_num, fixes):
    """Fix ayat 1 in a surah JSON file.
    
    Args:
        file_path: Path to JSON file
        surah_num: Surah number (for logging)
        fixes: List of madd_6 spans to add: [{"start": int, "end": int}, ...]
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Find ayat 1
        ayat_1 = None
        for verse in data['verses']:
            if verse['ayah'] == 1:
                ayat_1 = verse
                break
        
        if not ayat_1:
            print(f"  [WARNING] Surah {surah_num}: Ayah 1 not found!")
            return False
        
        # Get existing spans
        existing_spans = ayat_1.get('spans', [])
        
        # Check if fixes already exist
        existing_starts = {s['start'] for s in existing_spans if s.get('rule') == 'madd_6'}
        needed_fixes = [f for f in fixes if f['start'] not in existing_starts]
        
        if not needed_fixes:
            print(f"  [SKIP] Surah {surah_num}: All madd_6 already present")
            return True
        
        # Add new spans
        for fix in needed_fixes:
            existing_spans.append({
                "rule": "madd_6",
                "start": fix['start'],
                "end": fix['end']
            })
        
        # Sort spans by start position
        existing_spans.sort(key=lambda x: x['start'])
        
        # Update data
        ayat_1['spans'] = existing_spans
        
        # Save
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"  [OK] Surah {surah_num}: Added {len(needed_fixes)} madd_6 span(s)")
        return True
        
    except Exception as e:
        print(f"  [ERROR] Surah {surah_num}: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    project_root = Path(__file__).parent.parent
    tajwid_dir = project_root / "assets" / "data" / "tajwid"
    
    print("=" * 60)
    print("Fixing missing madd_6 spans for muqatta'ah letters")
    print("=" * 60)
    print()
    
    # Define fixes for each surah
    fixes_map = {
        # الۤمّۤ - Add madd_6 for Mim (start: 3, end: 6)
        3: [{"start": 3, "end": 6}],
        29: [{"start": 3, "end": 6}],
        30: [{"start": 3, "end": 6}],
        31: [{"start": 3, "end": 6}],
        32: [{"start": 3, "end": 6}],
        
        # الۤمّۤصۤ - Add madd_6 for Shad (start: 6, end: 8)
        7: [{"start": 6, "end": 8}],
        
        # الۤمّۤرٰۗ - Add madd_6 for Ra (start: 6, end: 8)
        13: [{"start": 6, "end": 8}],
        
        # كهيعص - Add 5 madd_6 spans
        19: [
            {"start": 0, "end": 2},  # كۤ
            {"start": 2, "end": 4},  # هٰ
            {"start": 4, "end": 6},  # يٰ
            {"start": 6, "end": 8},  # عۤ
            {"start": 8, "end": 10}, # صۤ
        ],
        
        # حٰمۤ - Add 2 madd_6 spans
        41: [{"start": 0, "end": 2}, {"start": 2, "end": 4}],
        42: [{"start": 0, "end": 2}, {"start": 2, "end": 4}],
        43: [{"start": 0, "end": 2}, {"start": 2, "end": 4}],
        44: [{"start": 0, "end": 2}, {"start": 2, "end": 4}],
        45: [{"start": 0, "end": 2}, {"start": 2, "end": 4}],
        46: [{"start": 0, "end": 2}, {"start": 2, "end": 4}],
    }
    
    success_count = 0
    total_count = len(fixes_map)
    
    for surah_num, fixes in sorted(fixes_map.items()):
        file_path = tajwid_dir / f"{surah_num:03d}.json"
        
        if not file_path.exists():
            print(f"  [ERROR] Surah {surah_num}: File not found: {file_path}")
            continue
        
        if fix_surah(file_path, surah_num, fixes):
            success_count += 1
    
    print()
    print("=" * 60)
    print(f"Done: {success_count}/{total_count} surahs fixed")
    print("=" * 60)


if __name__ == "__main__":
    main()

