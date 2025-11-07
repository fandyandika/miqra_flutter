#!/usr/bin/env python3
"""
Fix idghaam_no_ghunnah position for surah 2 ayah 2.
"""

import json
import sys
from pathlib import Path

def get_surah2_ayah2_text(sql_path):
    """Extract surah 2 ayah 2 text from SQL file."""
    with open(sql_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line.startswith('INSERT INTO'):
                continue
            
            values_index = line.find('VALUES')
            if values_index == -1:
                continue
            
            values_part = line[values_index + 6:].strip()
            if not values_part.startswith('(') or not values_part.endswith(');'):
                continue
            
            values_content = values_part[1:-2]
            values = _parse_sql_values(values_content)
            if len(values) < 6:
                continue
            
            sura_id = int(values[1])
            verse_id = int(values[2])
            
            if sura_id == 2 and verse_id == 2:
                ayah_text = values[3]
                if ayah_text and len(ayah_text) > 0 and ord(ayah_text[0]) == 0xFEFF:
                    ayah_text = ayah_text[1:]
                return ayah_text.strip()
    
    return None

def _parse_sql_values(values_content):
    """Parse SQL VALUES string."""
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
    
    for i in range(len(result)):
        value = result[i].strip()
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1]
            value = value.replace('""', '"')
            result[i] = value
    
    return result

def find_idghaam_position(text):
    """
    Find idghaam_no_ghunnah position.
    Look for tanwin (ً) followed by Lam (ل).
    """
    # Find "هُدًى لِّلْمُتَّقِيْنَ"
    # Tanwin is in "هُدًى"
    # Lam is in "لِّلْمُتَّقِيْنَ"
    
    # Find tanwin position
    tanwin_pos = -1
    for i in range(len(text)):
        if text[i] == 'ً':  # Tanwin fatha
            tanwin_pos = i
            break
    
    if tanwin_pos == -1:
        return None, None
    
    # Find Lam after tanwin (skip space and diacritics)
    lam_pos = -1
    for i in range(tanwin_pos + 1, len(text)):
        if text[i] == 'ل':  # Lam
            lam_pos = i
            break
    
    if lam_pos == -1:
        return None, None
    
    # Idghaam_no_ghunnah typically covers from tanwin to Lam (inclusive)
    # But we need to check what makes sense visually
    # Usually: start at tanwin, end after Lam
    start = tanwin_pos
    end = lam_pos + 1  # Include the Lam
    
    return start, end

def main():
    project_root = Path(__file__).parent.parent
    tajwid_path = project_root / "assets" / "data" / "tajwid" / "002.json"
    sql_path = project_root / "assets" / "data" / "quran" / "quran-indonesia.sql"
    
    # Get text
    text = get_surah2_ayah2_text(str(sql_path))
    if not text:
        print("Error: Could not find surah 2 ayah 2 in SQL file")
        return 1
    
    print(f"Text: {text}")
    print(f"Length: {len(text)}")
    
    # Find position
    start, end = find_idghaam_position(text)
    if start is None or end is None:
        print("Error: Could not find idghaam_no_ghunnah position")
        return 1
    
    print(f"\nFound idghaam_no_ghunnah at: {start}-{end}")
    print(f"Text at position: {repr(text[start:end])}")
    print(f"Context: ...{text[max(0, start-5):start]}[{text[start:end}]{text[end:min(len(text), end+5)]}...")
    
    # Load and update JSON
    with open(tajwid_path, 'r', encoding='utf-8') as f:
        tajwid_data = json.load(f)
    
    # Find ayah 2
    for verse in tajwid_data['verses']:
        if verse['ayah'] == 2:
            # Update idghaam_no_ghunnah span
            for span in verse['spans']:
                if span['rule'] == 'idghaam_no_ghunnah':
                    print(f"\nUpdating span:")
                    print(f"  Old: {span['start']}-{span['end']}")
                    print(f"  New: {start}-{end}")
                    span['start'] = start
                    span['end'] = end
                    break
            break
    
    # Save
    with open(tajwid_path, 'w', encoding='utf-8') as f:
        json.dump(tajwid_data, f, ensure_ascii=False, indent=2)
    
    print(f"\n✓ Updated {tajwid_path}")
    return 0

if __name__ == "__main__":
    sys.exit(main())

