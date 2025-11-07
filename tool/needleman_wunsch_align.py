#!/usr/bin/env python3
"""
Needleman-Wunsch Sequence Alignment for Uthmani-Indopak Mapping

This script implements Needleman-Wunsch algorithm to accurately align
Uthmani and Indopak texts and create mapping table for indices conversion.
"""

import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, List, Tuple, Optional

def parse_uthmani_xml(xml_path: str) -> Dict[int, Dict[int, str]]:
    """Parse Uthmani XML file. Returns: {surah: {ayah: text}}"""
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
    """Parse Indopak SQL file. Returns: {surah: {ayah: text}}"""
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

def get_base_char(char: str) -> str:
    """Get base Arabic character, removing diacritics."""
    code = ord(char)
    # Base Arabic characters (0600-06FF)
    if 0x0600 <= code <= 0x06FF:
        # Check if it's a base character (not combining mark)
        if code < 0x064B or code > 0x065F:
            return char
    return ''

def score_char(char1: str, char2: str) -> int:
    """
    Score function for character matching.
    Returns: 2 for exact match, 1 for base char match, -1 for mismatch
    """
    if char1 == char2:
        return 2  # Exact match
    
    base1 = get_base_char(char1)
    base2 = get_base_char(char2)
    
    if base1 and base2 and base1 == base2:
        return 1  # Base character match (ignore diacritics)
    
    return -1  # Mismatch

def needleman_wunsch(uthmani: str, indopak: str, gap_penalty: int = 1) -> Dict[int, int]:
    """
    Needleman-Wunsch global alignment algorithm.
    
    Returns: {uthmani_index: indopak_index} mapping
    """
    n, m = len(uthmani), len(indopak)
    
    # Initialize scoring matrix
    M = [[0] * (m + 1) for _ in range(n + 1)]
    
    # Initialize first row and column (gap penalties)
    for i in range(1, n + 1):
        M[i][0] = M[i-1][0] - gap_penalty
    for j in range(1, m + 1):
        M[0][j] = M[0][j-1] - gap_penalty
    
    # Fill scoring matrix
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            match_score = M[i-1][j-1] + score_char(uthmani[i-1], indopak[j-1])
            delete_score = M[i-1][j] - gap_penalty
            insert_score = M[i][j-1] - gap_penalty
            M[i][j] = max(match_score, delete_score, insert_score)
    
    # Traceback to get alignment
    alignment = []
    i, j = n, m
    
    while i > 0 or j > 0:
        if i > 0 and j > 0 and M[i][j] == M[i-1][j-1] + score_char(uthmani[i-1], indopak[j-1]):
            # Match or mismatch
            alignment.append((i-1, j-1))
            i -= 1
            j -= 1
        elif i > 0 and M[i][j] == M[i-1][j] - gap_penalty:
            # Delete (gap in indopak)
            i -= 1
        else:
            # Insert (gap in uthmani)
            j -= 1
    
    # Create mapping (only for matches, not gaps)
    mapping = {}
    for uth_idx, indo_idx in alignment:
        # Only map if characters are similar enough
        if score_char(uthmani[uth_idx], indopak[indo_idx]) > 0:
            mapping[uth_idx] = indo_idx
    
    return mapping

def create_mapping_table(uthmani_data: Dict, indopak_data: Dict) -> Dict[str, Dict[int, int]]:
    """
    Create mapping table for all surahs/ayahs.
    
    Returns: {"surah_ayah": {uthmani_index: indopak_index}}
    """
    mapping_table = {}
    total = 0
    
    for surah_num in sorted(uthmani_data.keys()):
        if surah_num not in indopak_data:
            continue
        
        for ayah_num in sorted(uthmani_data[surah_num].keys()):
            if ayah_num not in indopak_data[surah_num]:
                continue
            
            uthmani_text = uthmani_data[surah_num][ayah_num]
            indopak_text = indopak_data[surah_num][ayah_num]
            
            key = f"{surah_num}_{ayah_num}"
            mapping = needleman_wunsch(uthmani_text, indopak_text)
            mapping_table[key] = mapping
            
            total += 1
            if total <= 10 or (surah_num <= 3 and ayah_num <= 3):
                print(f"Surah {surah_num} Ayah {ayah_num}: {len(mapping)} mapping points", file=sys.stdout)
    
    return mapping_table

def convert_indices(uth_start: int, uth_end: int, mapping: Dict[int, int]) -> Optional[Tuple[int, int]]:
    """
    Convert Uthmani indices to Indopak indices using mapping.
    
    Returns: (indopak_start, indopak_end) or None if cannot convert
    """
    # Find closest mapped indices
    indo_start = None
    indo_end = None
    
    # Find start: get closest mapped index <= uth_start
    for uth_idx in sorted(mapping.keys()):
        if uth_idx <= uth_start:
            indo_start = mapping[uth_idx]
        else:
            break
    
    # Find end: get closest mapped index >= uth_end
    for uth_idx in sorted(mapping.keys(), reverse=True):
        if uth_idx >= uth_end:
            indo_end = mapping[uth_idx]
        else:
            break
    
    if indo_start is not None and indo_end is not None and indo_end > indo_start:
        return (indo_start, indo_end)
    
    return None

def main():
    project_root = Path(__file__).parent.parent
    xml_path = project_root / "assets" / "data" / "quran" / "quran-uthmani.xml"
    sql_path = project_root / "assets" / "data" / "quran" / "quran-indonesia.sql"
    output_path = project_root / "assets" / "data" / "quran" / "uthmani_indopak_mapping.json"
    
    print("=" * 60, file=sys.stdout)
    print("Needleman-Wunsch Alignment: Uthmani -> Indopak", file=sys.stdout)
    print("=" * 60, file=sys.stdout)
    print(file=sys.stdout)
    
    # Parse files
    print("Parsing Uthmani XML...", file=sys.stdout)
    uthmani_data = parse_uthmani_xml(str(xml_path))
    print(f"Loaded {len(uthmani_data)} surahs", file=sys.stdout)
    
    print("Parsing Indopak SQL...", file=sys.stdout)
    indopak_data = parse_indopak_sql(str(sql_path))
    print(f"Loaded {len(indopak_data)} surahs", file=sys.stdout)
    
    # Create mapping table
    print("\nCreating mapping table using Needleman-Wunsch...", file=sys.stdout)
    mapping_table = create_mapping_table(uthmani_data, indopak_data)
    print(f"\nGenerated {len(mapping_table)} mappings", file=sys.stdout)
    
    # Save mapping table
    print(f"\nSaving mapping to {output_path}...", file=sys.stdout)
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(mapping_table, f, ensure_ascii=False, indent=2)
    
    print("✓ Mapping table saved!", file=sys.stdout)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

