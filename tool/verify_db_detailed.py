#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Detailed DB verification - check all spans and rule names."""

import sqlite3
import json
import sys
from pathlib import Path

# Fix encoding for Windows console
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def verify_detailed():
    project_root = Path(__file__).parent.parent
    db_path = project_root / "assets" / "data" / "quran" / "miqra_tajwid.db"
    json_dir = project_root / "assets" / "data" / "tajwid"
    
    print("=" * 60)
    print("Detailed DB Verification")
    print("=" * 60)
    print()
    
    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()
    
    # Check all rule names in DB
    print("Checking rule names in DB...")
    cursor.execute("SELECT DISTINCT rule_key FROM tajwid_spans ORDER BY rule_key")
    db_rules = [row[0] for row in cursor.fetchall()]
    print(f"  DB rules: {', '.join(db_rules)}")
    print()
    
    # Check JSON rules
    print("Checking rule names in JSON...")
    json_rules = set()
    for i in range(1, 4):
        json_file = json_dir / f"{i:03d}.json"
        if json_file.exists():
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                for verse in data['verses']:
                    for span in verse['spans']:
                        json_rules.add(span['rule'])
    print(f"  JSON rules: {', '.join(sorted(json_rules))}")
    print()
    
    # Check Surah 2 Ayah 2 - all spans
    print("Surah 2 Ayah 2 - All spans comparison:")
    cursor.execute("""
        SELECT start_idx, end_idx_excl, rule_key 
        FROM tajwid_spans 
        WHERE suraId=2 AND verseID=2
        ORDER BY start_idx
    """)
    db_spans = cursor.fetchall()
    
    json_file = json_dir / "002.json"
    with open(json_file, 'r', encoding='utf-8') as f:
        json_data = json.load(f)
    json_ayah = next((v for v in json_data['verses'] if v['ayah'] == 2), None)
    json_spans = json_ayah['spans'] if json_ayah else []
    
    print(f"  DB spans ({len(db_spans)}):")
    for s in db_spans:
        print(f"    {s[2]}: {s[0]}-{s[1]}")
    
    print(f"  JSON spans ({len(json_spans)}):")
    for s in json_spans:
        print(f"    {s['rule']}: {s['start']}-{s['end']}")
    print()
    
    # Check Surah 3 Ayah 1 - all spans
    print("Surah 3 Ayah 1 - All spans comparison:")
    cursor.execute("""
        SELECT start_idx, end_idx_excl, rule_key 
        FROM tajwid_spans 
        WHERE suraId=3 AND verseID=1
        ORDER BY start_idx
    """)
    db_spans = cursor.fetchall()
    
    json_file = json_dir / "003.json"
    with open(json_file, 'r', encoding='utf-8') as f:
        json_data = json.load(f)
    json_ayah = next((v for v in json_data['verses'] if v['ayah'] == 1), None)
    json_spans = json_ayah['spans'] if json_ayah else []
    
    print(f"  DB spans ({len(db_spans)}):")
    for s in db_spans:
        print(f"    {s[2]}: {s[0]}-{s[1]}")
    
    print(f"  JSON spans ({len(json_spans)}):")
    for s in json_spans:
        print(f"    {s['rule']}: {s['start']}-{s['end']}")
    print()
    
    # Count total spans
    print("Total spans count:")
    cursor.execute("SELECT COUNT(*) FROM tajwid_spans")
    db_total = cursor.fetchone()[0]
    print(f"  DB total: {db_total}")
    
    json_total = 0
    for i in range(1, 115):
        json_file = json_dir / f"{i:03d}.json"
        if json_file.exists():
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                for verse in data['verses']:
                    json_total += len(verse['spans'])
    print(f"  JSON total: {json_total}")
    print()
    
    conn.close()

if __name__ == "__main__":
    verify_detailed()

