#!/usr/bin/env python3
"""
Align Uthmani and Indopak using difflib (simpler and more reliable).

This script uses Python's built-in difflib for sequence alignment,
which is simpler and more reliable than manual Needleman-Wunsch.
"""

import json
import sys
import xml.etree.ElementTree as ET
import difflib
from pathlib import Path
from typing import Dict, List

EXCLUDED_RULES = {
    "hamzat_wasl",
    "lam_shamsiyyah",
    "madd_2",
    "madd_246",
    "silent"
}

def parse_uthmani_xml(xml_path: str) -> Dict[int, Dict[int, str]]:
    """Parse Uthmani XML."""
    tree = ET.parse(xml_path)
    root = tree.getroot()
    surahs = {}
    for sura in root.findall('sura'):
        surah_num = int(sura.get('index'))
        surahs[surah_num] = {}
        for aya in sura.findall('aya'):
            ayah_num = int(aya.get('index'))
            text = aya.get('text', '')
            if surah_num not in (1, 9) and ayah_num == 1:
                bismillah = aya.get('bismillah')
                if bismillah:
                    text = bismillah + ' ' + text
            surahs[surah_num][ayah_num] = text
    return surahs

def parse_indopak_sql(sql_path: str) -> Dict[int, Dict[int, str]]:
    """Parse Indopak SQL."""
    surahs = {}
    with open(sql_path, 'r', encoding='utf-8') as f:
        for line in f:
            if not line.strip().startswith('INSERT INTO'):
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
            if ayah_text and len(ayah_text) > 0 and ord(ayah_text[0]) == 0xFEFF:
                ayah_text = ayah_text[1:]
            if sura_id not in surahs:
                surahs[sura_id] = {}
            surahs[sura_id][verse_id] = ayah_text.strip()
    return surahs

def _parse_sql_values(values_content: str) -> List[str]:
    """Parse SQL VALUES."""
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

def align_with_difflib(uthmani: str, indopak: str) -> Dict[int, int]:
    """
    Align texts using difflib.SequenceMatcher.
    
    Returns: {uthmani_index: indopak_index}
    """
    matcher = difflib.SequenceMatcher(None, uthmani, indopak, autojunk=False)
    mapping = {}
    
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == 'equal' or tag == 'replace':
            # Map matching characters
            for k in range(min(i2 - i1, j2 - j1)):
                mapping[i1 + k] = j1 + k
    
    return mapping

def convert_indices(uth_start: int, uth_end: int, mapping: Dict[int, int]) -> tuple:
    """Convert Uthmani indices to Indopak."""
    if not mapping:
        return None
    
    # Find closest mapped indices
    indo_start = None
    for uth_idx in sorted(mapping.keys()):
        if uth_idx <= uth_start:
            indo_start = mapping[uth_idx]
        else:
            break
    
    indo_end = None
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
    uthmani_tajwid_path = project_root / "assets" / "data" / "quran" / "quran-tajweed-master" / "output" / "tajweed.hafs.uthmani-pause-sajdah.json"
    output_dir = project_root / "assets" / "data" / "tajwid"
    
    print("=" * 60)
    print("Generate Accurate Indopak Tajwid (using difflib)")
    print("=" * 60)
    print()
    
    # Parse
    print("Parsing texts...")
    uthmani_data = parse_uthmani_xml(str(xml_path))
    indopak_data = parse_indopak_sql(str(sql_path))
    print(f"Uthmani: {len(uthmani_data)} surahs")
    print(f"Indopak: {len(indopak_data)} surahs")
    
    # Load tajwid
    print("\nLoading Uthmani tajwid...")
    with open(uthmani_tajwid_path, 'r', encoding='utf-8') as f:
        uthmani_tajwid = json.load(f)
    print(f"Loaded {len(uthmani_tajwid)} entries")
    
    # Convert
    surahs = {}
    total_converted = 0
    total_skipped = 0
    
    print("\nConverting tajwid data...")
    for idx, entry in enumerate(uthmani_tajwid):
        surah_num = entry["surah"]
        ayah_num = entry["ayah"]
        annotations = entry["annotations"]
        
        # Get texts
        if surah_num not in uthmani_data or ayah_num not in uthmani_data[surah_num]:
            continue
        if surah_num not in indopak_data or ayah_num not in indopak_data[surah_num]:
            continue
        
        uthmani_text = uthmani_data[surah_num][ayah_num]
        indopak_text = indopak_data[surah_num][ayah_num]
        
        # Align
        mapping = align_with_difflib(uthmani_text, indopak_text)
        
        # Convert spans
        filtered_spans = []
        for ann in annotations:
            if ann["rule"] in EXCLUDED_RULES:
                continue
            
            converted = convert_indices(ann["start"], ann["end"], mapping)
            if converted:
                filtered_spans.append({
                    "rule": ann["rule"],
                    "start": converted[0],
                    "end": converted[1]
                })
                total_converted += 1
            else:
                total_skipped += 1
        
        if surah_num not in surahs:
            surahs[surah_num] = {
                "surah_number": surah_num,
                "verses": []
            }
        
        surahs[surah_num]["verses"].append({
            "ayah": ayah_num,
            "spans": filtered_spans
        })
        
        if (idx + 1) % 1000 == 0:
            print(f"  Processed {idx + 1}/{len(uthmani_tajwid)} entries...")
    
    # Save
    print("\nGenerating JSON files...")
    import os
    os.makedirs(output_dir, exist_ok=True)
    
    for surah_num in sorted(surahs.keys()):
        surah_data = surahs[surah_num]
        surah_data["verses"].sort(key=lambda v: v["ayah"])
        
        filename = f"{surah_num:03d}.json"
        filepath = output_dir / filename
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(surah_data, f, ensure_ascii=False, indent=2)
        
        total_spans = sum(len(v["spans"]) for v in surah_data["verses"])
        if surah_num <= 3:
            print(f"  {filename}: {len(surah_data['verses'])} verses, {total_spans} spans")
    
    print(f"\n✓ Generated {len(surahs)} surah files")
    print(f"✓ Converted {total_converted} spans")
    if total_skipped > 0:
        print(f"⚠ Skipped {total_skipped} spans")
    
    print("\n" + "=" * 60)
    print("Complete!")
    print("=" * 60)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

