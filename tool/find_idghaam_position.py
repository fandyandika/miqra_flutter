#!/usr/bin/env python3
"""
Find correct position for idghaam_no_ghunnah in surah 2 ayah 2.
"""

import sys
from pathlib import Path

def get_surah2_ayah2_text(sql_path):
    """Extract surah 2 ayah 2 text from SQL file."""
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
            
            if sura_id == 2 and verse_id == 2:
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

def find_idghaam_no_ghunnah(text):
    """
    Find idghaam_no_ghunnah positions.
    Idghaam_no_ghunnah occurs when:
    - Nun sukun (نْ) or tanwin (ًٌٍ) is followed by Lam (ل) or Ra (ر)
    """
    positions = []
    
    # Look for tanwin (ًٌٍ) followed by Lam (ل) or Ra (ر)
    tanwin_chars = ['ً', 'ٌ', 'ٍ']
    
    for i in range(len(text) - 1):
        # Check if current char is tanwin
        if text[i] in tanwin_chars:
            # Look ahead for Lam or Ra (skip diacritics)
            j = i + 1
            while j < len(text):
                char = text[j]
                # Skip diacritics (combining marks)
                if ord(char) >= 0x064B and ord(char) <= 0x065F:
                    j += 1
                    continue
                # Check for Lam or Ra
                if char == 'ل' or char == 'ر':
                    # Found idghaam_no_ghunnah
                    # Start from tanwin, end at Lam/Ra (inclusive)
                    start = i
                    end = j + 1
                    positions.append((start, end, text[start:end]))
                    break
                # If we hit a space or other character, stop
                if char == ' ' or (ord(char) >= 0x0600 and ord(char) <= 0x06FF):
                    break
                j += 1
        
        # Also check for Nun sukun (نْ) followed by Lam or Ra
        if text[i] == 'ن':
            # Check if next char is sukun (ْ)
            if i + 1 < len(text) and text[i + 1] == 'ْ':
                # Look ahead for Lam or Ra
                j = i + 2
                while j < len(text):
                    char = text[j]
                    # Skip diacritics
                    if ord(char) >= 0x064B and ord(char) <= 0x065F:
                        j += 1
                        continue
                    # Check for Lam or Ra
                    if char == 'ل' or char == 'ر':
                        start = i
                        end = j + 1
                        positions.append((start, end, text[start:end]))
                        break
                    if char == ' ' or (ord(char) >= 0x0600 and ord(char) <= 0x06FF):
                        break
                    j += 1
    
    return positions

def main():
    project_root = Path(__file__).parent.parent
    sql_path = project_root / "assets" / "data" / "quran" / "quran-indonesia.sql"
    
    if not sql_path.exists():
        print(f"Error: SQL file not found: {sql_path}")
        return 1
    
    text = get_surah2_ayah2_text(str(sql_path))
    if not text:
        print("Error: Could not find surah 2 ayah 2 in SQL file")
        return 1
    
    print(f"Text: {text}")
    print(f"Length: {len(text)} characters")
    print()
    
    # Show character breakdown
    print("Character breakdown:")
    for i, char in enumerate(text):
        char_name = ""
        if char == 'ً':
            char_name = " (tanwin fatha)"
        elif char == 'ٌ':
            char_name = " (tanwin damma)"
        elif char == 'ٍ':
            char_name = " (tanwin kasra)"
        elif char == 'ل':
            char_name = " (Lam)"
        elif char == 'ر':
            char_name = " (Ra)"
        elif char == 'ن':
            char_name = " (Nun)"
        elif char == 'ْ':
            char_name = " (sukun)"
        print(f"  {i:3d}: {repr(char)} U+{ord(char):04X}{char_name}")
    
    print()
    print("Searching for idghaam_no_ghunnah...")
    positions = find_idghaam_no_ghunnah(text)
    
    if positions:
        print(f"\nFound {len(positions)} idghaam_no_ghunnah occurrence(s):")
        for start, end, span_text in positions:
            print(f"  Position: {start}-{end}")
            print(f"  Text: {repr(span_text)}")
            print(f"  Context: ...{text[max(0, start-5):start]}[{span_text}]{text[end:min(len(text), end+5)]}...")
            print()
    else:
        print("\nNo idghaam_no_ghunnah found in text")
        print("\nManual check:")
        # Look for "هُدًى لِّلْمُتَّقِيْنَ"
        if "هُدًى" in text:
            idx = text.find("هُدًى")
            print(f"  Found 'هُدًى' at position {idx}")
            # Find the tanwin
            tanwin_pos = idx + text[idx:].find('ً')
            print(f"  Tanwin (ً) at position {tanwin_pos}")
            # Find Lam after tanwin
            if "لِّلْمُتَّقِيْنَ" in text:
                lam_idx = text.find("لِّلْمُتَّقِيْنَ")
                print(f"  Found 'لِّلْمُتَّقِيْنَ' at position {lam_idx}")
                print(f"  Suggested span: {tanwin_pos}-{lam_idx + 1}")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

