#!/usr/bin/env python3
"""
Convert Uthmani Tajwid to Indopak using Needleman-Wunsch mapping table.

This script:
1. Loads mapping table from needleman_wunsch_align.py
2. Loads Uthmani tajwid data
3. Converts all indices using mapping table
4. Generates accurate Indopak tajwid JSON files
"""

import json
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Rules to exclude
EXCLUDED_RULES = {
    "hamzat_wasl",
    "lam_shamsiyyah",
    "madd_2",
    "madd_246",
    "silent"
}

def load_mapping_table(mapping_path: str) -> Dict[str, Dict[int, int]]:
    """Load mapping table from JSON file."""
    with open(mapping_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def load_uthmani_tajwid(uthmani_json_path: str) -> List[Dict]:
    """Load Uthmani tajwid data."""
    with open(uthmani_json_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def convert_indices(uth_start: int, uth_end: int, mapping: Dict[int, int]) -> Optional[Tuple[int, int]]:
    """
    Convert Uthmani indices to Indopak indices using mapping.
    
    Returns: (indopak_start, indopak_end) or None if cannot convert
    """
    if not mapping:
        return None
    
    # Find closest mapped indices
    indo_start = None
    indo_end = None
    
    # Find start: get closest mapped index <= uth_start
    for uth_idx in sorted(mapping.keys()):
        uth_idx_int = int(uth_idx)
        if uth_idx_int <= uth_start:
            indo_start = mapping[uth_idx]
        else:
            break
    
    # If no exact match, use interpolation
    if indo_start is None:
        # Find two closest points and interpolate
        sorted_keys = sorted([int(k) for k in mapping.keys()])
        if sorted_keys and sorted_keys[0] > uth_start:
            # Before first mapped point
            indo_start = mapping[str(sorted_keys[0])]
        elif sorted_keys:
            # After last mapped point - use last mapped value
            indo_start = mapping[str(sorted_keys[-1])]
    
    # Find end: get closest mapped index >= uth_end
    for uth_idx in sorted(mapping.keys(), reverse=True, key=int):
        uth_idx_int = int(uth_idx)
        if uth_idx_int >= uth_end:
            indo_end = mapping[uth_idx]
        else:
            break
    
    if indo_end is None:
        sorted_keys = sorted([int(k) for k in mapping.keys()], reverse=True)
        if sorted_keys and sorted_keys[0] < uth_end:
            indo_end = mapping[str(sorted_keys[0])]
        elif sorted_keys:
            indo_end = mapping[str(sorted_keys[-1])]
    
    if indo_start is not None and indo_end is not None:
        # Ensure valid range
        if indo_end > indo_start:
            return (int(indo_start), int(indo_end))
    
    return None

def convert_tajwid_data(
    uthmani_data: List[Dict],
    mapping_table: Dict[str, Dict[int, int]],
    output_dir: str
):
    """
    Convert tajwid data from Uthmani to Indopak using mapping table.
    """
    from pathlib import Path
    import os
    
    # Group by surah
    surahs = {}
    converted_count = 0
    skipped_count = 0
    
    for entry in uthmani_data:
        surah_num = entry["surah"]
        ayah_num = entry["ayah"]
        annotations = entry["annotations"]
        
        # Get mapping for this surah/ayah
        key = f"{surah_num}_{ayah_num}"
        mapping = mapping_table.get(key, {})
        
        if not mapping:
            skipped_count += 1
            continue
        
        # Filter and convert spans
        filtered_spans = []
        for ann in annotations:
            if ann["rule"] in EXCLUDED_RULES:
                continue
            
            uth_start = ann["start"]
            uth_end = ann["end"]
            
            # Convert indices
            converted = convert_indices(uth_start, uth_end, mapping)
            
            if converted:
                indo_start, indo_end = converted
                filtered_spans.append({
                    "rule": ann["rule"],
                    "start": indo_start,
                    "end": indo_end
                })
                converted_count += 1
            else:
                skipped_count += 1
        
        if surah_num not in surahs:
            surahs[surah_num] = {
                "surah_number": surah_num,
                "verses": []
            }
        
        surahs[surah_num]["verses"].append({
            "ayah": ayah_num,
            "spans": filtered_spans
        })
    
    # Sort verses by ayah number
    for surah_num in surahs:
        surahs[surah_num]["verses"].sort(key=lambda v: v["ayah"])
    
    # Generate files
    os.makedirs(output_dir, exist_ok=True)
    
    for surah_num in sorted(surahs.keys()):
        surah_data = surahs[surah_num]
        filename = f"{surah_num:03d}.json"
        filepath = os.path.join(output_dir, filename)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(surah_data, f, ensure_ascii=False, indent=2)
        
        total_spans = sum(len(v["spans"]) for v in surah_data["verses"])
        print(f"Generated {filename} ({len(surah_data['verses'])} verses, {total_spans} spans)", file=sys.stdout)
    
    print(f"\n✓ Generated {len(surahs)} surah files", file=sys.stdout)
    print(f"✓ Converted {converted_count} spans", file=sys.stdout)
    if skipped_count > 0:
        print(f"⚠ Skipped {skipped_count} spans (no mapping available)", file=sys.stdout)

def main():
    project_root = Path(__file__).parent.parent
    mapping_path = project_root / "assets" / "data" / "quran" / "uthmani_indopak_mapping.json"
    uthmani_json_path = project_root / "assets" / "data" / "quran" / "quran-tajweed-master" / "output" / "tajweed.hafs.uthmani-pause-sajdah.json"
    output_dir = project_root / "assets" / "data" / "tajwid"
    
    print("=" * 60, file=sys.stdout)
    print("Convert Tajwid: Uthmani -> Indopak", file=sys.stdout)
    print("=" * 60, file=sys.stdout)
    print(file=sys.stdout)
    
    # Check if mapping exists
    if not mapping_path.exists():
        print(f"Error: Mapping file not found: {mapping_path}", file=sys.stderr)
        print("Please run: python tool/needleman_wunsch_align.py first", file=sys.stderr)
        return 1
    
    # Load mapping table
    print("Loading mapping table...", file=sys.stdout)
    mapping_table = load_mapping_table(str(mapping_path))
    print(f"Loaded {len(mapping_table)} mappings", file=sys.stdout)
    
    # Load Uthmani tajwid data
    print("Loading Uthmani tajwid data...", file=sys.stdout)
    uthmani_data = load_uthmani_tajwid(str(uthmani_json_path))
    print(f"Loaded {len(uthmani_data)} entries", file=sys.stdout)
    
    # Convert and generate files
    print("\nConverting and generating files...", file=sys.stdout)
    convert_tajwid_data(uthmani_data, mapping_table, str(output_dir))
    
    print("\n" + "=" * 60, file=sys.stdout)
    print("Conversion complete!", file=sys.stdout)
    print("=" * 60, file=sys.stdout)
    print("\nValidate using: dart run bin/validate_tajwid.dart", file=sys.stdout)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

