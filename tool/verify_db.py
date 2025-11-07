#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Verify miqra_tajwid.db data against accurate JSON files.

This script:
1. Opens the SQLite database
2. Queries tajwid spans for sample surahs/ayahs
3. Compares with accurate JSON data (Indopak indices)
4. Reports any mismatches
"""

import sqlite3
import json
import sys
from pathlib import Path

# Fix encoding for Windows console
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def verify_db():
    project_root = Path(__file__).parent.parent
    db_path = project_root / "assets" / "data" / "quran" / "miqra_tajwid.db"
    json_dir = project_root / "assets" / "data" / "tajwid"
    sql_path = project_root / "assets" / "data" / "quran" / "quran-indonesia.sql"
    
    print("=" * 60)
    print("Verifying miqra_tajwid.db against accurate JSON data")
    print("=" * 60)
    print()
    
    if not db_path.exists():
        print(f"[ERROR] Database not found: {db_path}")
        return False
    
    # Connect to DB
    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()
    except Exception as e:
        print(f"[ERROR] Failed to open database: {e}")
        return False
    
    # Check tables
    print("Checking database structure...")
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = [row[0] for row in cursor.fetchall()]
    print(f"  Tables found: {', '.join(tables)}")
    
    # Check if tajwid_spans table exists
    if 'tajwid_spans' not in tables:
        print("[ERROR] Table 'tajwid_spans' not found!")
        conn.close()
        return False
    
    # Get schema
    cursor.execute("PRAGMA table_info(tajwid_spans)")
    columns = cursor.fetchall()
    print(f"  tajwid_spans columns: {[col[1] for col in columns]}")
    print()
    
    # Test cases: surah/ayah with known accurate indices
    test_cases = [
        (2, 2, "idghaam_no_ghunnah", 42, 48),  # Surah 2 Ayah 2 - known accurate
        (2, 1, "madd_6", None, None),  # Surah 2 Ayah 1 - should have madd_6
        (3, 1, "madd_6", 1, 3),  # Surah 3 Ayah 1 - known accurate (was 40-42 in Uthmani)
        (1, 7, "madd_6", 87, 89),  # Surah 1 Ayah 7 - known accurate
    ]
    
    print("Verifying sample data...")
    print()
    
    all_match = True
    mismatches = []
    
    for surah_num, ayah_num, expected_rule, expected_start, expected_end in test_cases:
        # Query DB
        query = """
            SELECT start_idx, end_idx_excl, rule_key 
            FROM tajwid_spans 
            WHERE suraId=? AND verseID=?
            ORDER BY start_idx
        """
        cursor.execute(query, (surah_num, ayah_num))
        db_spans = cursor.fetchall()
        
        # Load JSON
        json_file = json_dir / f"{surah_num:03d}.json"
        if not json_file.exists():
            print(f"[WARNING] JSON file not found: {json_file}")
            continue
        
        with open(json_file, 'r', encoding='utf-8') as f:
            json_data = json.load(f)
        
        json_ayah = next((v for v in json_data['verses'] if v['ayah'] == ayah_num), None)
        json_spans = json_ayah['spans'] if json_ayah else []
        
        # Find matching rule
        db_span = next((s for s in db_spans if s[2] == expected_rule), None)
        json_span = next((s for s in json_spans if s['rule'] == expected_rule), None)
        
        print(f"Surah {surah_num} Ayah {ayah_num} - Rule: {expected_rule}")
        
        if db_span:
            db_start, db_end, db_rule = db_span
            print(f"  DB:     start={db_start}, end={db_end}")
        else:
            print(f"  DB:     NOT FOUND")
            db_start, db_end = None, None
        
        if json_span:
            json_start, json_end = json_span['start'], json_span['end']
            print(f"  JSON:   start={json_start}, end={json_end}")
        else:
            print(f"  JSON:   NOT FOUND")
            json_start, json_end = None, None
        
        # Compare
        if expected_start is not None and expected_end is not None:
            if db_start == expected_start and db_end == expected_end:
                print(f"  [OK] DB matches expected (Indopak accurate)")
            elif db_start is None or db_end is None:
                print(f"  [MISSING] DB rule not found! Expected: {expected_start}-{expected_end}")
                all_match = False
                mismatches.append((surah_num, ayah_num, expected_rule, db_start, db_end, expected_start, expected_end))
            else:
                print(f"  [MISMATCH] DB mismatch! Expected: {expected_start}-{expected_end}")
                all_match = False
                mismatches.append((surah_num, ayah_num, expected_rule, db_start, db_end, expected_start, expected_end))
        
        if db_start is not None and db_end is not None:
            if json_start == db_start and json_end == db_end:
                print(f"  [OK] DB matches JSON")
            else:
                print(f"  [MISMATCH] DB differs from JSON!")
                all_match = False
                if (surah_num, ayah_num, expected_rule) not in [(m[0], m[1], m[2]) for m in mismatches]:
                    mismatches.append((surah_num, ayah_num, expected_rule, db_start, db_end, json_start, json_end))
        
        print()
    
    # Check text alignment - verify DB uses Indopak text
    print("Checking if DB uses Indopak text...")
    try:
        cursor.execute("SELECT ayahText FROM quran_id WHERE suraId=2 AND verseID=2")
        db_text = cursor.fetchone()
        
        if db_text:
            db_text_str = db_text[0]
            # Get Indopak text from SQL
            indopak_text = None
            with open(sql_path, 'r', encoding='utf-8') as f:
                for line in f:
                    if 'suraId, verseID' in line and '2,2' in line:
                        # Parse SQL to get ayahText
                        values_start = line.find('VALUES')
                        if values_start != -1:
                            values_part = line[values_start + 6:].strip()
                            if values_part.startswith('(') and values_part.endswith(');'):
                                values_content = values_part[1:-2]
                                # Simple parsing - get 4th value (ayahText)
                                values = []
                                current = []
                                in_quotes = False
                                escape_next = False
                                for ch in values_content:
                                    if escape_next:
                                        current.append(ch)
                                        escape_next = False
                                        continue
                                    if ch == '\\':
                                        escape_next = True
                                        current.append(ch)
                                        continue
                                    if ch == '"' and (not current or current[-1] != '\\'):
                                        in_quotes = not in_quotes
                                    if ch == ',' and not in_quotes:
                                        values.append("".join(current))
                                        current = []
                                    else:
                                        current.append(ch)
                                if current:
                                    values.append("".join(current))
                                # Remove quotes
                                for i in range(len(values)):
                                    v = values[i].strip()
                                    if v.startswith('"') and v.endswith('"'):
                                        values[i] = v[1:-1].replace('""', '"')
                                if len(values) >= 4:
                                    indopak_text = values[3]
                                    if indopak_text and ord(indopak_text[0]) == 0xFEFF:
                                        indopak_text = indopak_text[1:]
                                    break
            
            if indopak_text:
                if db_text_str == indopak_text:
                    print(f"  [OK] DB text matches Indopak SQL")
                else:
                    print(f"  [MISMATCH] DB text differs from Indopak!")
                    print(f"    DB length: {len(db_text_str)}")
                    print(f"    Indopak length: {len(indopak_text)}")
                    print(f"    First 50 chars DB: {db_text_str[:50]}")
                    print(f"    First 50 chars Indopak: {indopak_text[:50]}")
                    all_match = False
    except Exception as e:
        print(f"  [WARNING] Could not check text: {e}")
    
    conn.close()
    
    print()
    print("=" * 60)
    if all_match:
        print("[PASS] VERIFICATION PASSED: DB data matches accurate JSON (Indopak)")
    else:
        print("[FAIL] VERIFICATION FAILED: DB data has mismatches")
        if mismatches:
            print("\nMismatches found:")
            for m in mismatches:
                print(f"  Surah {m[0]} Ayah {m[1]} Rule {m[2]}:")
                print(f"    DB: {m[3]}-{m[4]}, Expected: {m[5]}-{m[6]}")
    print("=" * 60)
    
    return all_match

if __name__ == "__main__":
    import sys
    success = verify_db()
    sys.exit(0 if success else 1)

