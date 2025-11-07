#!/usr/bin/env python3
"""Test if Python can write files."""

from pathlib import Path

pr = Path(__file__).parent.parent
test_file = pr / "python_test.txt"

with open(test_file, 'w', encoding='utf-8') as f:
    f.write("Python is working!\n")
    f.write("File write test successful\n")

print(f"Test file written to: {test_file}")

