#!/usr/bin/env python3
"""Simple test to verify Python works."""

import sys
import json
from pathlib import Path

print("Python is working!", file=sys.stderr)
print("Testing file operations...", file=sys.stderr)

# Test reading a file
pr = Path(__file__).parent.parent
fp = pr / "assets" / "data" / "tajwid" / "002.json"

try:
    with open(fp, 'r', encoding='utf-8') as f:
        data = json.load(f)
    print(f"Successfully read {fp}", file=sys.stderr)
    print(f"File has {len(data['verses'])} verses", file=sys.stderr)
    
    # Find ayah 2
    for v in data['verses']:
        if v['ayah'] == 2:
            print(f"Ayah 2 has {len(v['spans'])} spans", file=sys.stderr)
            for s in v['spans']:
                print(f"  {s['rule']}: {s['start']}-{s['end']}", file=sys.stderr)
            break
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)

print("All tests passed!", file=sys.stderr)

