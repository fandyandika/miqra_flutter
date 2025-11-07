#!/usr/bin/env python3
"""
Convert Uthmani Tajwid Data to Our Format

Converts tajweed.hafs.uthmani-pause-sajdah.json to our TajwidSurah format,
filtering out excluded rules and generating per-surah JSON files.
"""

import json
import os
from pathlib import Path

# Rules to exclude
EXCLUDED_RULES = {
    "hamzat_wasl",
    "lam_shamsiyyah",
    "madd_2",
    "madd_246",
    "silent"
}


def calculate_bismillah_offset():
    """
    Calculate the offset for Bismillah.
    Based on verified mapping: Uthmani index 40 -> Indopak index 1
    So offset = 40 - 1 = 39
    """
    return 39


def adjust_indices_for_bismillah(surah_num, ayah_num, spans, sql_path=None):
    """
    Adjust indices for surahs (except 1 and 9) ayah 1 by subtracting Bismillah offset.
    
    Args:
        surah_num: Surah number
        ayah_num: Ayah number
        spans: List of span dicts with 'start' and 'end'
        sql_path: Optional path to SQL file for validation
    
    Returns:
        Adjusted spans list
    """
    # Only adjust for surahs other than 1 and 9, ayah 1
    if surah_num in (1, 9) or ayah_num != 1:
        return spans
    
    bismillah_offset = calculate_bismillah_offset()
    adjusted_spans = []
    
    for span in spans:
        original_start = span["start"]
        original_end = span["end"]
        
        # Subtract Bismillah offset
        new_start = original_start - bismillah_offset
        new_end = original_end - bismillah_offset
        
        # Basic validation
        if new_start < 0:
            print(f"  Warning: Surah {surah_num} ayah {ayah_num}, rule {span['rule']}: "
                  f"adjusted start {new_start} is negative (original: {original_start})")
            # Skip this span
            continue
        
        if new_end <= new_start:
            print(f"  Warning: Surah {surah_num} ayah {ayah_num}, rule {span['rule']}: "
                  f"invalid range {new_start}-{new_end} (original: {original_start}-{original_end})")
            # Skip this span
            continue
        
        adjusted_spans.append({
            "rule": span["rule"],
            "start": new_start,
            "end": new_end
        })
    
    return adjusted_spans


def convert_uthmani_data(uthmani_json_path, output_dir, sql_path=None):
    """
    Convert Uthmani tajwid data to our format.
    
    Args:
        uthmani_json_path: Path to tajweed.hafs.uthmani-pause-sajdah.json
        output_dir: Directory to output JSON files
        sql_path: Optional path to SQL file for text length validation
    """
    print("=" * 60)
    print("Convert Uthmani Tajwid Data to Our Format")
    print("=" * 60)
    print(f"Input: {uthmani_json_path}")
    print(f"Output: {output_dir}")
    print(f"Excluded rules: {', '.join(sorted(EXCLUDED_RULES))}")
    print()
    
    # Load Uthmani data
    print("Loading Uthmani data...")
    with open(uthmani_json_path, 'r', encoding='utf-8') as f:
        uthmani_data = json.load(f)
    
    print(f"Loaded {len(uthmani_data)} entries")
    
    # Group by surah
    surahs = {}
    adjusted_count = 0
    for entry in uthmani_data:
        surah_num = entry["surah"]
        ayah_num = entry["ayah"]
        annotations = entry["annotations"]
        
        # Filter out excluded rules
        filtered_spans = []
        for ann in annotations:
            if ann["rule"] not in EXCLUDED_RULES:
                filtered_spans.append({
                    "rule": ann["rule"],
                    "start": ann["start"],
                    "end": ann["end"]
                })
        
        # Adjust indices for Bismillah (surah != 1,9 and ayah == 1)
        original_count = len(filtered_spans)
        original_spans = filtered_spans.copy() if filtered_spans else []
        filtered_spans = adjust_indices_for_bismillah(surah_num, ayah_num, filtered_spans, sql_path)
        
        # Check if adjustment happened (indices changed)
        if original_spans and filtered_spans:
            adjusted = False
            for orig, adj in zip(original_spans, filtered_spans):
                if orig["start"] != adj["start"] or orig["end"] != adj["end"]:
                    adjusted = True
                    break
            
            if adjusted:
                adjusted_count += 1
                if adjusted_count <= 10:  # Show first few adjustments
                    print(f"  Adjusted surah {surah_num} ayah {ayah_num}: "
                          f"{len(original_spans)} spans (e.g., {original_spans[0]['start']}-{original_spans[0]['end']} -> {filtered_spans[0]['start']}-{filtered_spans[0]['end']})")
        
        if surah_num not in surahs:
            surahs[surah_num] = {
                "surah_number": surah_num,
                "verses": []
            }
        
        surahs[surah_num]["verses"].append({
            "ayah": ayah_num,
            "spans": filtered_spans
        })
    
    if adjusted_count > 0:
        print(f"\nAdjusted {adjusted_count} ayahs for Bismillah offset")
    
    # Sort verses by ayah number
    for surah_num in surahs:
        surahs[surah_num]["verses"].sort(key=lambda v: v["ayah"])
    
    print(f"Converted {len(surahs)} surahs")
    
    # Generate files
    print("\nGenerating JSON files...")
    os.makedirs(output_dir, exist_ok=True)
    
    for surah_num in sorted(surahs.keys()):
        surah_data = surahs[surah_num]
        filename = f"{surah_num:03d}.json"
        filepath = os.path.join(output_dir, filename)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(surah_data, f, ensure_ascii=False, indent=2)
        
        # Count total spans
        total_spans = sum(len(v["spans"]) for v in surah_data["verses"])
        print(f"Generated {filename} ({len(surah_data['verses'])} verses, {total_spans} spans)")
    
    print(f"\nGenerated {len(surahs)} surah files in {output_dir}")
    
    # Show rules used
    print("\nRules found in data:")
    all_rules = set()
    for surah_data in surahs.values():
        for verse in surah_data["verses"]:
            for span in verse["spans"]:
                all_rules.add(span["rule"])
    
    print(f"  {', '.join(sorted(all_rules))}")
    
    # Show sample (surah 1)
    print("\nSample - Surah 1:")
    if 1 in surahs:
        surah_1 = surahs[1]
        for verse in surah_1["verses"]:
            if verse["spans"]:
                print(f"  Ayah {verse['ayah']}: {len(verse['spans'])} spans")
                for span in verse["spans"]:
                    print(f"    - {span['rule']} ({span['start']}-{span['end']})")
    
    print("\n" + "=" * 60)
    print("Conversion complete!")
    print("=" * 60)
    print("\nNote: Indices for surah != 1,9 ayah 1 have been adjusted for Bismillah offset.")
    print("Validate using: dart run bin/validate_tajwid.dart")


def main():
    """Main function."""
    project_root = Path(__file__).parent.parent
    uthmani_json_path = project_root / "assets" / "data" / "quran" / "quran-tajweed-master" / "output" / "tajweed.hafs.uthmani-pause-sajdah.json"
    sql_path = project_root / "assets" / "data" / "quran" / "quran-indonesia.sql"
    output_dir = project_root / "assets" / "data" / "tajwid"
    
    if not uthmani_json_path.exists():
        print(f"Error: Uthmani JSON file not found: {uthmani_json_path}")
        return 1
    
    sql_path_str = str(sql_path) if sql_path.exists() else None
    convert_uthmani_data(str(uthmani_json_path), str(output_dir), sql_path_str)
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())

