#!/usr/bin/env python3
"""Generate accurate tajwid for surah 2 only (for testing)."""

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

def parse_uthmani_xml(xml_path: str, surah_num: int) -> Dict[int, str]:
    """Parse Uthmani XML for specific surah."""
    tree = ET.parse(xml_path)
    root = tree.getroot()
    verses = {}
    for sura in root.findall('sura'):
        if int(sura.get('index')) == surah_num:
            for aya in sura.findall('aya'):
                ayah_num = int(aya.get('index'))
                text = aya.get('text', '')
                if surah_num not in (1, 9) and ayah_num == 1:
                    bismillah = aya.get('bismillah')
                    if bismillah:
                        text = bismillah + ' ' + text
                verses[ayah_num] = text
            break
    return verses

def parse_indopak_sql(sql_path: str, surah_num: int) -> Dict[int, str]:
    """Parse Indopak SQL for specific surah."""
    verses = {}
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
            if sura_id != surah_num:
                continue
            verse_id = int(values[2])
            ayah_text = values[3]
            if ayah_text and len(ayah_text) > 0 and ord(ayah_text[0]) == 0xFEFF:
                ayah_text = ayah_text[1:]
            verses[verse_id] = ayah_text.strip()
    return verses

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

def align_texts(uthmani: str, indopak: str) -> Dict[int, int]:
    """Align using difflib."""
    matcher = difflib.SequenceMatcher(None, uthmani, indopak, autojunk=False)
    mapping = {}
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag in ('equal', 'replace'):
            for k in range(min(i2 - i1, j2 - j1)):
                mapping[i1 + k] = j1 + k
    return mapping

def convert_indices(uth_start: int, uth_end: int, mapping: Dict[int, int]) -> tuple:
    """Convert Uthmani indices to Indopak."""
    if not mapping:
        return None
    indo_start = None
    for ux in sorted(mapping.keys()):
        if ux <= uth_start:
            indo_start = mapping[ux]
        else:
            break
    indo_end = None
    for ux in sorted(mapping.keys(), reverse=True):
        if ux >= uth_end:
            indo_end = mapping[ux]
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
    output_file = project_root / "assets" / "data" / "tajwid" / "002.json"
    
    surah_num = 2
    
    print("=" * 60)
    print(f"Generate Accurate Tajwid for Surah {surah_num}")
    print("=" * 60)
    print()
    
    # Parse texts
    print("Parsing texts...")
    uthmani_verses = parse_uthmani_xml(str(xml_path), surah_num)
    indopak_verses = parse_indopak_sql(str(sql_path), surah_num)
    print(f"Uthmani: {len(uthmani_verses)} verses")
    print(f"Indopak: {len(indopak_verses)} verses")
    
    # Load Uthmani tajwid for surah 2
    print("\nLoading Uthmani tajwid...")
    with open(uthmani_tajwid_path, 'r', encoding='utf-8') as f:
        uthmani_tajwid = json.load(f)
    
    surah_2_tajwid = [e for e in uthmani_tajwid if e["surah"] == surah_num]
    print(f"Found {len(surah_2_tajwid)} tajwid entries for surah {surah_num}")
    
    # Convert
    print("\nConverting tajwid data...")
    verses = []
    total_converted = 0
    
    for entry in surah_2_tajwid:
        ayah_num = entry["ayah"]
        annotations = entry["annotations"]
        
        if ayah_num not in uthmani_verses or ayah_num not in indopak_verses:
            continue
        
        uthmani_text = uthmani_verses[ayah_num]
        indopak_text = indopak_verses[ayah_num]
        
        # Align
        mapping = align_texts(uthmani_text, indopak_text)
        
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
        
        verses.append({
            "ayah": ayah_num,
            "spans": filtered_spans
        })
        
        if ayah_num <= 3:
            print(f"  Ayah {ayah_num}: {len(filtered_spans)} spans")
    
    # Save
    surah_data = {
        "surah_number": surah_num,
        "verses": sorted(verses, key=lambda v: v["ayah"])
    }
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(surah_data, f, ensure_ascii=False, indent=2)
    
    total_spans = sum(len(v["spans"]) for v in surah_data["verses"])
    print(f"\n✓ Generated {output_file}")
    print(f"✓ {len(surah_data['verses'])} verses, {total_spans} spans")
    print(f"✓ Converted {total_converted} spans")
    
    # Show sample for ayah 2
    ayah_2 = next((v for v in verses if v["ayah"] == 2), None)
    if ayah_2:
        print(f"\nSample - Ayah 2:")
        for span in ayah_2["spans"]:
            print(f"  {span['rule']}: {span['start']}-{span['end']}")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

