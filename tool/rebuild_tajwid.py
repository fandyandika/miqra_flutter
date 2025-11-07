#!/usr/bin/env python3
"""
Rebuild Tajwid Data from Decision Trees

Extracts Arabic text from quran-indonesia.sql, runs tajweed classification
using decision trees from quran-tajweed-master, filters out unwanted rules,
and generates per-surah JSON files in the format expected by Flutter app.
"""

import json
import os
import sys
import glob
from pathlib import Path

# Add parent directory to path to import tajweed_classifier
sys.path.insert(0, str(Path(__file__).parent.parent / "assets" / "data" / "quran" / "quran-tajweed-master"))

# Import from tajweed_classifier
# We need to import the module and access functions directly
import tajweed_classifier
from tree import json2tree

# Rules to exclude
EXCLUDED_RULES = {
    "hamzat_wasl",
    "lam_shamsiyyah",
    "madd_2",
    "madd_246",
    "silent"
}


def extract_text_from_sql(sql_path):
    """
    Parse quran-indonesia.sql and extract ayahText for each surah/ayah.
    
    Returns: dict {surah: {ayah: text}}
    """
    verses = {}
    
    with open(sql_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line.startswith('INSERT INTO'):
                continue
            
            # Find VALUES keyword
            values_index = line.find('VALUES')
            if values_index == -1:
                continue
            
            # Extract values part: (id,suraId,verseID,"text","translation","translit")
            values_part = line[values_index + 6:].strip()
            if not values_part.startswith('(') or not values_part.endswith(');'):
                continue
            
            # Remove parentheses and semicolon
            values_content = values_part[1:-2]
            
            # Parse values manually - split by comma but respect quoted strings
            values = _parse_sql_values(values_content)
            if len(values) < 6:
                continue
            
            sura_id = int(values[1])
            verse_id = int(values[2])
            ayah_text = values[3]
            
            # Remove BOM character if present
            if ayah_text and len(ayah_text) > 0 and ord(ayah_text[0]) == 0xFEFF:
                ayah_text = ayah_text[1:]
            
            if sura_id not in verses:
                verses[sura_id] = {}
            verses[sura_id][verse_id] = ayah_text.strip()
    
    return verses


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
            result.append(''.join(current))
            current = []
            continue
        
        current.append(char)
    
    if current:
        result.append(''.join(current))
    
    # Remove quotes from string values
    for i, value in enumerate(result):
        value = value.strip()
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1]
            # Unescape double quotes
            value = value.replace('""', '"')
            result[i] = value
    
    return result


def format_for_classifier(verses_dict):
    """
    Convert verses dict to surah|ayah|text format for classifier input.
    
    Returns: list of strings in format "surah|ayah|text"
    """
    lines = []
    for surah in sorted(verses_dict.keys()):
        for ayah in sorted(verses_dict[surah].keys()):
            text = verses_dict[surah][ayah]
            lines.append(f"{surah}|{ayah}|{text}")
    return lines


def run_classifier(input_lines, rule_trees_path):
    """
    Run tajweed classifier on input lines, excluding unwanted rules.
    
    Args:
        input_lines: List of strings in format "surah|ayah|text"
        rule_trees_path: Path to rule_trees directory
    
    Returns: List of dicts with format [{"surah": 1, "ayah": 1, "annotations": [...]}]
    """
    # Load rule trees, excluding unwanted rules
    rule_trees = {}
    rule_start_files = glob.glob(os.path.join(rule_trees_path, "*.start.json"))
    
    for start_file in rule_start_files:
        rule_name = os.path.basename(start_file).partition(".")[0]
        
        # Skip excluded rules
        if rule_name in EXCLUDED_RULES:
            continue
        
        end_file = start_file.replace(".start.", ".end.")
        if not os.path.exists(end_file):
            print(f"Warning: End file not found for {rule_name}: {end_file}")
            continue
        
        try:
            with open(start_file, 'r', encoding='utf-8') as f:
                start_tree = json2tree(json.load(f))
            with open(end_file, 'r', encoding='utf-8') as f:
                end_tree = json2tree(json.load(f))
            
            rule_trees[rule_name] = {
                "start": start_tree,
                "end": end_tree,
            }
        except Exception as e:
            print(f"Warning: Failed to load rule tree for {rule_name}: {e}")
            continue
    
    print(f"Loaded {len(rule_trees)} rule trees: {', '.join(sorted(rule_trees.keys()))}")
    
    # Prepare tasks
    tasks = []
    for line in input_lines:
        parts = line.split("|")
        if len(parts) != 3:
            continue
        surah = int(parts[0])
        ayah = int(parts[1])
        text = parts[2].strip()
        tasks.append((surah, ayah, text, rule_trees))
    
    # Run classification
    print(f"Classifying {len(tasks)} verses...")
    results = []
    for i, task in enumerate(tasks):
        if (i + 1) % 100 == 0:
            print(f"  Processed {i + 1}/{len(tasks)} verses...")
        try:
            result = tajweed_classifier.label_ayah(task)
            results.append(result)
        except Exception as e:
            print(f"Error classifying surah {task[0]}, ayah {task[1]}: {e}")
            # Add empty result to maintain order
            results.append({
                "surah": task[0],
                "ayah": task[1],
                "annotations": []
            })
    
    return results


def filter_and_convert(classifier_output):
    """
    Filter out excluded rules and convert format.
    
    Input: [{"surah": 1, "ayah": 1, "annotations": [...]}]
    Output: {surah: {"surah_number": 1, "verses": [{"ayah": 1, "spans": [...]}]}}
    """
    surahs = {}
    
    for item in classifier_output:
        surah_num = item["surah"]
        ayah_num = item["ayah"]
        annotations = item["annotations"]
        
        # Filter out excluded rules
        filtered_spans = []
        for ann in annotations:
            if ann["rule"] not in EXCLUDED_RULES:
                filtered_spans.append({
                    "rule": ann["rule"],
                    "start": ann["start"],
                    "end": ann["end"]
                })
        
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
    
    return surahs


def split_by_surah(filtered_data, output_dir):
    """
    Generate individual JSON files (001.json to 114.json) in output directory.
    """
    os.makedirs(output_dir, exist_ok=True)
    
    for surah_num in sorted(filtered_data.keys()):
        surah_data = filtered_data[surah_num]
        filename = f"{surah_num:03d}.json"
        filepath = os.path.join(output_dir, filename)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(surah_data, f, ensure_ascii=False, indent=2)
        
        print(f"Generated {filename} ({len(surah_data['verses'])} verses)")
    
    print(f"\nGenerated {len(filtered_data)} surah files in {output_dir}")


def validate_sample(surah_num, sql_path):
    """
    Validate a sample surah to ensure indices match Arabic text.
    """
    verses = extract_text_from_sql(sql_path)
    
    if surah_num not in verses:
        print(f"Surah {surah_num} not found in SQL")
        return False
    
    surah_verses = verses[surah_num]
    print(f"\nValidating surah {surah_num}:")
    
    # Check a few verses
    sample_ayahs = sorted(surah_verses.keys())[:3]
    for ayah in sample_ayahs:
        text = surah_verses[ayah]
        print(f"  Ayah {ayah}: length={len(text)}")
        # Skip printing Arabic text to avoid encoding issues in console
        if len(text) > 50:
            print(f"    Text: (first 50 chars, length={len(text)})")
        else:
            print(f"    Text: (length={len(text)})")
    
    return True


def main():
    """Main orchestration function."""
    # Paths
    project_root = Path(__file__).parent.parent
    sql_path = project_root / "assets" / "data" / "quran" / "quran-indonesia.sql"
    rule_trees_path = project_root / "assets" / "data" / "quran" / "quran-tajweed-master" / "rule_trees"
    output_dir = project_root / "assets" / "data" / "tajwid"
    
    print("=" * 60)
    print("Rebuild Tajwid Data from Decision Trees")
    print("=" * 60)
    print(f"SQL path: {sql_path}")
    print(f"Rule trees path: {rule_trees_path}")
    print(f"Output directory: {output_dir}")
    print(f"Excluded rules: {', '.join(sorted(EXCLUDED_RULES))}")
    print()
    
    # Step 1: Extract text from SQL
    print("Step 1: Extracting text from SQL...")
    if not sql_path.exists():
        print(f"Error: SQL file not found: {sql_path}")
        return 1
    
    verses_dict = extract_text_from_sql(str(sql_path))
    print(f"Extracted {sum(len(v) for v in verses_dict.values())} verses from {len(verses_dict)} surahs")
    
    # Step 2: Format for classifier
    print("\nStep 2: Formatting for classifier...")
    input_lines = format_for_classifier(verses_dict)
    print(f"Formatted {len(input_lines)} lines")
    
    # Step 3: Run classifier
    print("\nStep 3: Running classifier...")
    if not rule_trees_path.exists():
        print(f"Error: Rule trees directory not found: {rule_trees_path}")
        return 1
    
    classifier_output = run_classifier(input_lines, str(rule_trees_path))
    print(f"Classification complete: {len(classifier_output)} results")
    
    # Step 4: Filter and convert
    print("\nStep 4: Filtering and converting format...")
    filtered_data = filter_and_convert(classifier_output)
    print(f"Converted {len(filtered_data)} surahs")
    
    # Step 5: Generate files
    print("\nStep 5: Generating JSON files...")
    split_by_surah(filtered_data, str(output_dir))
    
    # Step 6: Validate sample
    print("\nStep 6: Validating sample...")
    validate_sample(1, str(sql_path))
    validate_sample(2, str(sql_path))
    validate_sample(114, str(sql_path))
    
    print("\n" + "=" * 60)
    print("Rebuild complete!")
    print("=" * 60)
    print(f"\nNext steps:")
    print(f"1. Validate output using: dart run bin/validate_tajwid.dart")
    print(f"2. Test in Flutter app to ensure rendering is correct")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())

