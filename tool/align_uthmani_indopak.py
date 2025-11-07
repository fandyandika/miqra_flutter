#!/usr/bin/env python3
"""
Align Uthmani and Indopak texts to create mapping table for indices conversion.

This script:
1. Parses quran-uthmani.xml (Uthmani text)
2. Parses quran-indonesia.sql (Indopak text)
3. Aligns texts using character-based matching
4. Generates mapping table: Uthmani index -> Indopak index
5. Saves mapping to JSON file for use in tajwid conversion
"""

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, List, Tuple, Optional

def parse_uthmani_xml(xml_path: str) -> Dict[int, Dict[int, str]]:
    """
    Parse Uthmani XML file.
    
    Returns: {surah: {ayah: text}}
    """
    tree = ET.parse(xml_path)
    root = tree.getroot()
    
    surahs = {}
    for sura in root.findall('sura'):
        surah_num = int(sura.get('index'))
        surahs[surah_num] = {}
        
        for aya in sura.findall('aya'):
            ayah_num = int(aya.get('index'))
            text = aya.get('text', '')
            
            # For surah != 1,9, ayah 1, include bismillah if present
            if surah_num not in (1, 9) and ayah_num == 1:
                bismillah = aya.get('bismillah')
                if bismillah:
                    text = bismillah + ' ' + text
            
            surahs[surah_num][ayah_num] = text
    
    return surahs

def parse_indopak_sql(sql_path: str) -> Dict[int, Dict[int, str]]:
    """
    Parse Indopak SQL file.
    
    Returns: {surah: {ayah: text}}
    """
    surahs = {}
    
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
            ayah_text = values[3]
            
            # Remove BOM if present
            if ayah_text and len(ayah_text) > 0 and ord(ayah_text[0]) == 0xFEFF:
                ayah_text = ayah_text[1:]
            
            if sura_id not in surahs:
                surahs[sura_id] = {}
            
            surahs[sura_id][verse_id] = ayah_text.strip()
    
    return surahs

def _parse_sql_values(values_content: str) -> List[str]:
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

def normalize_text(text: str) -> str:
    """
    Normalize text for alignment by removing diacritics and special marks.
    Keeps only base Arabic characters and spaces.
    """
    # Remove diacritics (combining marks)
    normalized = ''
    for char in text:
        # Keep base Arabic characters (0600-06FF), spaces, and some punctuation
        code = ord(char)
        if (0x0600 <= code <= 0x06FF) or char == ' ' or char in 'ۛۙۚ':
            normalized += char
    
    return normalized

def align_texts(uthmani_text: str, indopak_text: str) -> Dict[int, int]:
    """
    Align Uthmani and Indopak texts using dynamic programming approach.
    
    Returns: {uthmani_index: indopak_index}
    """
    # Use a simpler approach: find common subsequences
    # Map each significant character position
    
    mapping = {}
    
    # Extract base characters with their positions
    uthmani_chars = []
    for i, char in enumerate(uthmani_text):
        code = ord(char)
        if (0x0600 <= code <= 0x06FF) or char == ' ':
            uthmani_chars.append((i, char))
    
    indopak_chars = []
    for i, char in enumerate(indopak_text):
        code = ord(char)
        if (0x0600 <= code <= 0x06FF) or char == ' ':
            indopak_chars.append((i, char))
    
    # Align by matching base characters
    uth_idx = 0
    indo_idx = 0
    
    while uth_idx < len(uthmani_chars) and indo_idx < len(indopak_chars):
        uth_pos, uth_char = uthmani_chars[uth_idx]
        indo_pos, indo_char = indopak_chars[indo_idx]
        
        # Try to match
        if uth_char == indo_char:
            # Exact match
            mapping[uth_pos] = indo_pos
            uth_idx += 1
            indo_idx += 1
        else:
            # Try to find match in next few characters
            found = False
            for j in range(indo_idx, min(indo_idx + 5, len(indopak_chars))):
                if uthmani_chars[uth_idx][1] == indopak_chars[j][1]:
                    mapping[uth_pos] = indopak_chars[j][0]
                    uth_idx += 1
                    indo_idx = j + 1
                    found = True
                    break
            
            if not found:
                # Skip this character
                uth_idx += 1
    
    return mapping

def create_mapping_table(uthmani_data: Dict, indopak_data: Dict) -> Dict[str, Dict[int, int]]:
    """
    Create mapping table for all surahs/ayahs.
    
    Returns: {"surah_ayah": {uthmani_index: indopak_index}}
    """
    mapping_table = {}
    
    for surah_num in sorted(uthmani_data.keys()):
        if surah_num not in indopak_data:
            continue
        
        for ayah_num in sorted(uthmani_data[surah_num].keys()):
            if ayah_num not in indopak_data[surah_num]:
                continue
            
            uthmani_text = uthmani_data[surah_num][ayah_num]
            indopak_text = indopak_data[surah_num][ayah_num]
            
            key = f"{surah_num}_{ayah_num}"
            mapping = align_texts(uthmani_text, indopak_text)
            mapping_table[key] = mapping
            
            if surah_num <= 3 and ayah_num <= 3:
                print(f"Surah {surah_num} Ayah {ayah_num}:", file=sys.stdout)
                print(f"  Uthmani length: {len(uthmani_text)}", file=sys.stdout)
                print(f"  Indopak length: {len(indopak_text)}", file=sys.stdout)
                print(f"  Mapping points: {len(mapping)}", file=sys.stdout)
                if len(mapping) > 0:
                    sample = list(mapping.items())[:3]
                    print(f"  Sample: {sample}", file=sys.stdout)
    
    return mapping_table

def convert_indices_using_mapping(
    uthmani_indices: List[Tuple[int, int]], 
    mapping: Dict[int, int]
) -> List[Tuple[int, int]]:
    """
    Convert Uthmani indices to Indopak indices using mapping table.
    
    Args:
        uthmani_indices: List of (start, end) tuples
        mapping: {uthmani_index: indopak_index}
    
    Returns:
        List of (start, end) tuples in Indopak
    """
    converted = []
    
    for start, end in uthmani_indices:
        # Find closest mapped indices
        indopak_start = None
        indopak_end = None
        
        # Find start
        for uth_start in sorted(mapping.keys()):
            if uth_start <= start:
                indopak_start = mapping[uth_start]
            else:
                break
        
        # Find end
        for uth_end in sorted(mapping.keys(), reverse=True):
            if uth_end >= end:
                indopak_end = mapping[uth_end]
            else:
                break
        
        if indopak_start is not None and indopak_end is not None:
            converted.append((indopak_start, indopak_end))
    
    return converted

def main():
    project_root = Path(__file__).parent.parent
    xml_path = project_root / "assets" / "data" / "quran" / "quran-uthmani.xml"
    sql_path = project_root / "assets" / "data" / "quran" / "quran-indonesia.sql"
    output_path = project_root / "assets" / "data" / "quran" / "uthmani_indopak_mapping.json"
    
    print("=" * 60)
    print("Align Uthmani and Indopak Texts")
    print("=" * 60)
    print()
    
    # Parse files
    print("Parsing Uthmani XML...")
    uthmani_data = parse_uthmani_xml(str(xml_path))
    print(f"Loaded {len(uthmani_data)} surahs")
    
    print("Parsing Indopak SQL...")
    indopak_data = parse_indopak_sql(str(sql_path))
    print(f"Loaded {len(indopak_data)} surahs")
    
    # Create mapping table
    print("\nCreating mapping table...")
    mapping_table = create_mapping_table(uthmani_data, indopak_data)
    print(f"Generated {len(mapping_table)} mappings")
    
    # Save mapping table
    print(f"\nSaving mapping to {output_path}...")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(mapping_table, f, ensure_ascii=False, indent=2)
    
    print("✓ Mapping table saved!")
    print("\nNext: Update convert_uthmani_tajwid.py to use this mapping table")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

