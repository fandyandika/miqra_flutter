# Tajwid Validator

## Usage

Run the validator to check tajwid span indices against actual Quran text:

```bash
dart run bin/validate_tajwid.dart
```

This will:
1. Validate `assets/data/tajwid/001.json` against `assets/data/quran/quran-indonesia.sql`
2. Optionally validate `assets/data/tajwid/002_282.json` if present

## Direct Tool Usage

You can also run the validator tool directly:

```bash
dart tool/tajwid_validator.dart <tajwid_json> [sql_path]
```

Examples:
```bash
# Validate with SQL text
dart tool/tajwid_validator.dart assets/data/tajwid/001.json assets/data/quran/quran-indonesia.sql

# Validate structure only (no SQL)
dart tool/tajwid_validator.dart assets/data/tajwid/001.json
```

## Validation Rules

- Checks UTF-16 indices: `0 <= start < end <= text.length`
- Validates against actual `text_ar` from SQL if provided
- Exits with code 1 if any invalid spans found
- Prints summary with total/invalid/valid span counts

