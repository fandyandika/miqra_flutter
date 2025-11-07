#!/usr/bin/env python3
"""
Fix indices for Surah 2 Ayah 1 by adjusting for Bismillah offset.

The Uthmani data includes Bismillah at the start of surah 2 ayah 1,
but our SQL data doesn't. We need to subtract the Bismillah offset
from all indices for surah 2 ayah 1.
"""

import json
import sys
from pathlib import Path

def calculate_bismillah_offset():
    """
    Calculate the length of Bismillah text.
    Bismillah: "بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ "
    """
    bismillah = "بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ "
    return len(bismillah)

def get_surah2_ayah1_text(sql_path):
    """Extract surah 2 ayah 1 text from SQL file."""
    with open(sql_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line.startswith('INSERT INTO'):
                continue
            
            # Find VALUES keyword
            values_index = line.find('VALUES')
            if values_index == -1:
                continue
            
            # Extract values part
            values_part = line[values_index + 6:].strip()
            if not values_part.startswith('(') or not values_part.endswith(');'):
                continue
            
            # Remove parentheses and semicolon
            values_content = values_part[1:-2]
            
            # Parse values manually
            values = _parse_sql_values(values_content)
            if len(values) < 6:
                continue
            
            sura_id = int(values[1])
            verse_id = int(values[2])
            
            if sura_id == 2 and verse_id == 1:
                ayah_text = values[3]
                # Remove BOM if present
                if ayah_text and len(ayah_text) > 0 and ord(ayah_text[0]) == 0xFEFF:
                    ayah_text = ayah_text[1:]
                return ayah_text.strip()
    
    return None

def _parse_sql_values(values_content):
    """Parse SQL VALUES string, respecting quoted strings."""
    result = []
    current = []
    in_quotes = False
    escape_next = False
    
    for char in values_content:
        if escape_next:
            current.append(char)
            escape_next = False
            continue
        
        if char == '\\':
            escape_next = True
            current.append(char)
            continue
        
        if char == '"':
            in_quotes = not in_quotes
            current.append(char)
            continue
        
        if char == ',' and not in_quotes:
            result.append("".join(current))
            current = []
            continue
        
        current.append(char)
    
    if current:
        result.append("".join(current))
    
    # Remove quotes from string values
    for i in range(len(result)):
        value = result[i].strip()
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1]
            value = value.replace('""', '"')
            result[i] = value
    
    return result

def fix_surah2_ayah1(tajwid_path, sql_path, output_path):
    """Fix indices for surah 2 ayah 1 by adjusting for Bismillah offset."""
    
    # Load tajwid data
    with open(tajwid_path, 'r', encoding='utf-8') as f:
        tajwid_data = json.load(f)
    
    # Get actual text from SQL
    actual_text = get_surah2_ayah1_text(sql_path)
    if not actual_text:
        print("Error: Could not find surah 2 ayah 1 in SQL file", file=sys.stderr)
        return False
    
    print(f"Actual text from SQL: {actual_text}")
    print(f"Text length: {len(actual_text)} characters")
    
    # Calculate Bismillah offset
    bismillah_offset = calculate_bismillah_offset()
    print(f"Bismillah offset: {bismillah_offset} characters")
    
    # Find ayah 1 in tajwid data
    ayah_1 = None
    for verse in tajwid_data['verses']:
        if verse['ayah'] == 1:
            ayah_1 = verse
            break
    
    if not ayah_1:
        print("Error: Ayah 1 not found in tajwid data")
        return False
    
    print(f"\nOriginal spans for ayah 1: {len(ayah_1['spans'])} spans")
    for span in ayah_1['spans']:
        print(f"  {span['rule']}: {span['start']}-{span['end']}")
    
    # Adjust indices
    adjusted_spans = []
    for span in ayah_1['spans']:
        original_start = span['start']
        original_end = span['end']
        
        # Subtract Bismillah offset
        new_start = original_start - bismillah_offset
        new_end = original_end - bismillah_offset
        
        # Validate new indices
        if new_start < 0:
            print(f"Warning: Adjusted start {new_start} is negative for rule {span['rule']}")
            continue
        
        if new_end > len(actual_text):
            print(f"Warning: Adjusted end {new_end} exceeds text length {len(actual_text)} for rule {span['rule']}")
            continue
        
        if new_end <= new_start:
            print(f"Warning: Invalid range {new_start}-{new_end} for rule {span['rule']}")
            continue
        
        # Extract text at adjusted position for verification
        span_text = actual_text[new_start:new_end]
        print(f"  Adjusted {span['rule']}: {new_start}-{new_end} (was {original_start}-{original_end}) -> '{span_text}'")
        
        adjusted_spans.append({
            'rule': span['rule'],
            'start': new_start,
            'end': new_end
        })
    
    # Update tajwid data
    ayah_1['spans'] = adjusted_spans
    
    # Save updated data
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(tajwid_data, f, ensure_ascii=False, indent=2)
    
    print(f"\n✓ Fixed {len(adjusted_spans)} spans for surah 2 ayah 1")
    print(f"✓ Saved to {output_path}")
    
    return True

def main():
    project_root = Path(__file__).parent.parent
    tajwid_path = project_root / "assets" / "data" / "tajwid" / "002.json"
    sql_path = project_root / "assets" / "data" / "quran" / "quran-indonesia.sql"
    output_path = tajwid_path  # Overwrite original
    
    if not tajwid_path.exists():
        print(f"Error: Tajwid file not found: {tajwid_path}")
        return 1
    
    if not sql_path.exists():
        print(f"Error: SQL file not found: {sql_path}")
        return 1
    
    print("=" * 60)
    print("Fix Surah 2 Ayah 1 Indices")
    print("=" * 60)
    print()
    
    success = fix_surah2_ayah1(str(tajwid_path), str(sql_path), str(output_path))
    
    if success:
        print("\n" + "=" * 60)
        print("Fix complete!")
        print("=" * 60)
        return 0
    else:
        return 1

if __name__ == "__main__":
    sys.exit(main())

