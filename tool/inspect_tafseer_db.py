#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Inspect quran_tafseer.db structure and content.
Only inspection, no conversion.
"""

import sqlite3
import sys
from pathlib import Path

# Fix encoding for Windows console
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def inspect_db():
    project_root = Path(__file__).resolve().parent.parent
    db_path = project_root / "assets" / "data" / "tafsir" / "quran_tafseer.db"
    
    print("=" * 60)
    print("INSPECTING quran_tafseer.db")
    print("=" * 60)
    print(f"Database path: {db_path}")
    print()
    
    if not db_path.exists():
        print(f"[ERROR] Database not found: {db_path}")
        return
    
    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()
    except Exception as e:
        print(f"[ERROR] Failed to open database: {e}")
        return
    
    # 1. List all tables
    print("1. DATABASE TABLES:")
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = [row[0] for row in cursor.fetchall()]
    print(f"   Found {len(tables)} table(s): {', '.join(tables)}")
    print()
    
    # 2. Schema for each table
    for table in tables:
        print(f"2. TABLE: {table}")
        cursor.execute(f"PRAGMA table_info({table})")
        columns = cursor.fetchall()
        print(f"   Columns ({len(columns)}):")
        for col in columns:
            col_id, col_name, col_type, not_null, default_val, pk = col
            pk_str = " [PRIMARY KEY]" if pk else ""
            not_null_str = " NOT NULL" if not_null else ""
            default_str = f" DEFAULT {default_val}" if default_val else ""
            print(f"     - {col_name} ({col_type}){not_null_str}{default_str}{pk_str}")
        print()
        
        # 3. Row count
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        print(f"   Total rows: {count:,}")
        
        # 4. Sample data (first 3 rows)
        if count > 0:
            cursor.execute(f"SELECT * FROM {table} LIMIT 3")
            samples = cursor.fetchall()
            print(f"   Sample data (first 3 rows):")
            for i, row in enumerate(samples, 1):
                # Truncate long text fields
                row_display = []
                for val in row:
                    if isinstance(val, str) and len(val) > 100:
                        row_display.append(val[:100] + "...")
                    else:
                        row_display.append(val)
                print(f"     Row {i}: {row_display}")
        print()
        
        # 5. Check for unique/distinct values in key columns
        if count > 0:
            print(f"   Data distribution:")
            # Check for surah/ayah columns
            for col_info in columns:
                col_name = col_info[1]
                col_type = col_info[2].upper()
                
                if 'SURAH' in col_name.upper() or 'SURA' in col_name.upper():
                    cursor.execute(f"SELECT COUNT(DISTINCT {col_name}), MIN({col_name}), MAX({col_name}) FROM {table}")
                    distinct, min_val, max_val = cursor.fetchone()
                    print(f"     {col_name}: {distinct} distinct values, range: {min_val}-{max_val}")
                
                elif 'AYAH' in col_name.upper() or 'VERSE' in col_name.upper():
                    cursor.execute(f"SELECT COUNT(DISTINCT {col_name}), MIN({col_name}), MAX({col_name}) FROM {table}")
                    distinct, min_val, max_val = cursor.fetchone()
                    print(f"     {col_name}: {distinct} distinct values, range: {min_val}-{max_val}")
            
            # Check for rule/rule_key columns (tajwid)
            for col_info in columns:
                col_name = col_info[1]
                if 'RULE' in col_name.upper():
                    cursor.execute(f"SELECT COUNT(DISTINCT {col_name}) FROM {table}")
                    distinct = cursor.fetchone()[0]
                    if distinct > 0:
                        cursor.execute(f"SELECT DISTINCT {col_name} FROM {table} ORDER BY {col_name} LIMIT 10")
                        rules = [row[0] for row in cursor.fetchall()]
                        print(f"     {col_name}: {distinct} distinct values, samples: {', '.join(str(r) for r in rules[:10])}")
        print()
    
    # 6. Check if it contains tajwid data
    print("3. CHECKING FOR TAJWID DATA:")
    tajwid_keywords = ['tajwid', 'tajweed', 'rule', 'span', 'start', 'end']
    has_tajwid = False
    tajwid_tables = []
    
    for table in tables:
        cursor.execute(f"PRAGMA table_info({table})")
        columns = [col[1].lower() for col in cursor.fetchall()]
        column_names = [col[1] for col in cursor.fetchall()]
        
        # Check column names
        found_keywords = []
        for keyword in tajwid_keywords:
            if any(keyword in col for col in columns):
                found_keywords.append(keyword)
        
        if found_keywords:
            print(f"   [POTENTIAL] Table '{table}' has tajwid-related columns: {found_keywords}")
            print(f"              All columns: {column_names}")
            has_tajwid = True
            tajwid_tables.append(table)
        
        # Check sample data for tajwid rules
        if not has_tajwid:
            cursor.execute(f"SELECT * FROM {table} LIMIT 20")
            samples = cursor.fetchall()
            for row in samples:
                row_str = ' '.join(str(val) for val in row).lower()
                tajwid_rules = ['madd', 'ikhfa', 'ghunnah', 'qalqalah', 'idghaam', 'iqlab']
                found_rules = [rule for rule in tajwid_rules if rule in row_str]
                if found_rules:
                    print(f"   [POTENTIAL] Table '{table}' contains tajwid rule keywords: {found_rules}")
                    has_tajwid = True
                    tajwid_tables.append(table)
                    break
    
    if not has_tajwid:
        print("   [NOT FOUND] No tajwid data detected. This appears to be a tafsir-only database.")
    else:
        print(f"   [FOUND] Potential tajwid data in table(s): {', '.join(tajwid_tables)}")
    print()
    
    # 7. Check for tafsir data
    print("4. CHECKING FOR TAFSIR DATA:")
    tafsir_keywords = ['tafsir', 'tafseer', 'text', 'content', 'meaning']
    has_tafsir = False
    
    for table in tables:
        cursor.execute(f"PRAGMA table_info({table})")
        columns = [col[1].lower() for col in cursor.fetchall()]
        
        for keyword in tafsir_keywords:
            if any(keyword in col for col in columns):
                print(f"   [FOUND] Table '{table}' has tafsir-related columns")
                has_tafsir = True
                break
    
    if has_tafsir:
        print("   [CONFIRMED] Database contains tafsir data")
    print()
    
    conn.close()
    
    print("=" * 60)
    print("INSPECTION COMPLETE")
    print("=" * 60)
    print()
    print("SUMMARY:")
    print(f"  - Total tables: {len(tables)}")
    print(f"  - Has tajwid data: {has_tajwid}")
    print(f"  - Has tafsir data: {has_tafsir}")
    print("=" * 60)

if __name__ == "__main__":
    inspect_db()

