import 'dart:convert';
import 'dart:io';

/// Validates tajwid spans against script text.
/// 
/// Checks UTF-16 indices: 0 <= start < end <= text.length
/// 
/// Usage: dart tool/tajwid_validator.dart <tajwid_json> [sql_path]
/// If sql_path provided, validates against actual text_ar from SQL.
/// Otherwise, validates structure only.
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart tool/tajwid_validator.dart <tajwid_json> [sql_path]');
    exit(1);
  }

  final tajwidPath = args[0];
  final sqlPath = args.length > 1 ? args[1] : null;

  try {
    final tajwidFile = File(tajwidPath);

    if (!await tajwidFile.exists()) {
      print('Error: Tajwid file not found: $tajwidPath');
      exit(1);
    }

    final tajwidJson = json.decode(await tajwidFile.readAsString()) as Map<String, dynamic>;
    final tajwidVerses = tajwidJson['verses'] as List;
    final surahNumber = tajwidJson['surah_number'] as int;

    // Parse SQL if provided
    Map<int, String>? verseTexts;
    if (sqlPath != null) {
      final sqlFile = File(sqlPath);
      if (await sqlFile.exists()) {
        verseTexts = _parseSQLForSurah(await sqlFile.readAsString(), surahNumber);
      }
    }

    int totalSpans = 0;
    int invalidSpans = 0;
    final errors = <String>[];

    for (final tajwidVerse in tajwidVerses) {
      final ayahNum = tajwidVerse['ayah'] as int;
      final spans = tajwidVerse['spans'] as List;

      String? textAr;
      int? textLength;

      if (verseTexts != null && verseTexts.containsKey(ayahNum)) {
        textAr = verseTexts[ayahNum];
        textLength = textAr?.length;
      }

      for (final span in spans) {
        totalSpans++;
        final start = span['start'] as int;
        final end = span['end'] as int;
        final rule = span['rule'] as String;

        // Basic structure validation
        if (start < 0) {
          errors.add('Ayah $ayahNum, rule $rule: start=$start is negative');
          invalidSpans++;
          continue;
        }

        if (end <= start) {
          errors.add('Ayah $ayahNum, rule $rule: invalid range start=$start, end=$end (end must be > start)');
          invalidSpans++;
          continue;
        }

        // Validate against actual text if available
        if (textLength != null) {
          if (start >= textLength) {
            errors.add('Ayah $ayahNum, rule $rule: start=$start out of bounds (length=$textLength)');
            invalidSpans++;
            continue;
          }

          if (end > textLength) {
            errors.add('Ayah $ayahNum, rule $rule: end=$end out of bounds (length=$textLength)');
            invalidSpans++;
            continue;
          }
        }
      }
    }

    print('Validation Summary:');
    print('  Surah: $surahNumber');
    print('  Total spans: $totalSpans');
    print('  Invalid spans: $invalidSpans');
    print('  Valid spans: ${totalSpans - invalidSpans}');
    if (verseTexts != null) {
      print('  Validated against actual text: Yes');
    } else {
      print('  Validated against actual text: No (structure only)');
    }

    if (errors.isNotEmpty) {
      print('\nErrors:');
      for (final error in errors) {
        print('  - $error');
      }
    }

    if (invalidSpans > 0) {
      exit(1);
    }

    print('\n✓ All spans valid');
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

Map<int, String> _parseSQLForSurah(String sqlContent, int surahNumber) {
  final result = <int, String>{};
  final lines = sqlContent.split('\n');

  for (final line in lines) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('INSERT INTO')) continue;

    final valuesIndex = trimmed.indexOf('VALUES');
    if (valuesIndex == -1) continue;

    final valuesPart = trimmed.substring(valuesIndex + 6).trim();
    if (!valuesPart.startsWith('(') || !valuesPart.endsWith(');')) continue;

    final valuesContent = valuesPart.substring(1, valuesPart.length - 2);
    final values = _parseSQLValues(valuesContent);
    if (values.length < 6) continue;

    final suraId = int.tryParse(values[1]) ?? 0;
    if (suraId != surahNumber) continue;

    final verseId = int.tryParse(values[2]) ?? 0;
    var ayahText = values[3];

    // Remove BOM if present
    if (ayahText.isNotEmpty && ayahText.codeUnitAt(0) == 0xFEFF) {
      ayahText = ayahText.substring(1);
    }

    result[verseId] = ayahText.trim();
  }

  return result;
}

List<String> _parseSQLValues(String valuesContent) {
  final result = <String>[];
  var current = StringBuffer();
  var inQuotes = false;
  var escapeNext = false;

  for (var i = 0; i < valuesContent.length; i++) {
    final char = valuesContent[i];

    if (escapeNext) {
      current.write(char);
      escapeNext = false;
      continue;
    }

    if (char == '\\') {
      escapeNext = true;
      current.write(char);
      continue;
    }

    if (char == '"') {
      inQuotes = !inQuotes;
      current.write(char);
      continue;
    }

    if (char == ',' && !inQuotes) {
      result.add(current.toString());
      current.clear();
      continue;
    }

    current.write(char);
  }

  if (current.isNotEmpty) {
    result.add(current.toString());
  }

  // Remove quotes from string values
  for (var i = 0; i < result.length; i++) {
    var value = result[i].trim();
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
      value = value.replaceAll('""', '"');
      result[i] = value;
    }
  }

  return result;
}

