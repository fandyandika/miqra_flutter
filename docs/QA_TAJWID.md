# Tajwid QA Documentation

## Overview

This document outlines the QA process for validating tajwid rendering in the Miqra Flutter app.

## Running the Validator

### Command

```bash
dart run bin/validate_tajwid.dart
```

### What It Does

1. Loads script JSON (from `assets/data/quran/quran-indonesia.sql` parsed data)
2. Loads tajwid JSON (from `assets/data/tajwid/NNN.json`)
3. For each ayah:
   - Computes UTF-16 length of `text_ar`
   - Validates each span: `0 <= start < end <= length`
4. Prints summary and exits with code 1 if any invalid spans found

### Expected Output

```
Validating surah 001...
Validation Summary:
  Total spans: 25
  Invalid spans: 0
  Valid spans: 25

✓ All spans valid

002_282.json not found, skipping...

✓ All validations passed
```

## Visual Checks

### Al-Fatihah (Surah 001)

**Test Steps:**
1. Launch app
2. Navigate to Reader screen (should load Al-Fatihah by default)
3. Toggle Tajwid button ON
4. Verify each verse displays colored spans

**Expected Results:**
- [ ] Verse 1: Grey highlights on hamzat_wasl positions (7-8, 15-16, 28-29)
- [ ] Verse 1: Orange highlights on lam_shamsiyyah (16-17, 29-30)
- [ ] Verse 1: Primary color (teal) on madd_2 (24-25)
- [ ] Verse 1: Green highlights on madd_246 (35-36)
- [ ] All 7 verses display correctly
- [ ] Text remains intact (no character separation)
- [ ] Colors match tajwidPalette

**Screenshot Placeholder:**
- [ ] Screenshot: Al-Fatihah with tajwid enabled
- [ ] Screenshot: Al-Fatihah with tajwid disabled (baseline)

### Al-Baqarah:282 (Surah 002, Ayah 282)

**Test Steps:**
1. Navigate to Al-Baqarah (if implemented)
2. Scroll to verse 282
3. Toggle Tajwid button ON
4. Verify spans render correctly

**Expected Results:**
- [ ] Long verse renders without performance issues
- [ ] All spans are within text bounds
- [ ] Colors applied correctly
- [ ] Text integrity maintained

**Screenshot Placeholder:**
- [ ] Screenshot: Al-Baqarah:282 with tajwid enabled

## Pass/Fail Gates

### Gate 1: Validator Passes
- ✅ All spans validated (exit code 0)
- ❌ Any invalid spans found (exit code 1)

### Gate 2: Visual Rendering
- ✅ All colors match palette
- ✅ Text integrity maintained (assert passes)
- ✅ No character separation
- ❌ Any rendering issues

### Gate 3: Performance
- ✅ Smooth scrolling
- ✅ No lag when toggling tajwid
- ❌ Performance degradation

### Gate 4: Error Handling
- ✅ Graceful fallback when tajwid file missing
- ✅ App continues to function without tajwid
- ❌ App crashes on missing file

## Test Checklist

- [ ] Run validator: `dart run bin/validate_tajwid.dart`
- [ ] Visual check: Al-Fatihah with tajwid ON
- [ ] Visual check: Al-Fatihah with tajwid OFF
- [ ] Verify text integrity (assert passes)
- [ ] Verify color accuracy
- [ ] Test toggle functionality
- [ ] Test translation toggle (should still work)
- [ ] Performance test: scroll through all verses
- [ ] Error test: remove tajwid file, verify graceful fallback

## Notes

- Indices are UTF-16 based (Dart String indices)
- Tajwid is styling-only: never mutates original text
- Assert ensures: `joined_text == original_text_ar`

