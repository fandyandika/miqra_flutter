import 'dart:io';
import 'dart:convert';

/// Converts letter-counts.json to CSV format for Supabase import.
/// 
/// Input: assets/data/derived/letter-counts.json
/// Output: letter_counts.csv (project root)
void main() async {
  const inputPath = 'assets/data/derived/letter-counts.json';
  const outputPath = 'letter_counts.csv';

  try {
    final jsonData = await _readJsonFile(inputPath);
    final csvRows = _convertToCsvRows(jsonData);
    await _writeCsvFile(outputPath, csvRows);
    
    print('✓ Successfully converted $inputPath to $outputPath');
    print('  Generated ${csvRows.length} rows (including header)');
  } catch (e, stackTrace) {
    print('✗ Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

/// Reads and parses JSON file.
Future<Map<String, dynamic>> _readJsonFile(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw Exception('File not found: $path');
  }

  final content = await file.readAsString();
  return jsonDecode(content) as Map<String, dynamic>;
}

/// Converts JSON data to CSV rows.
/// 
/// Returns list of CSV rows (first row is header).
List<String> _convertToCsvRows(Map<String, dynamic> jsonData) {
  final data = jsonData['data'] as Map<String, dynamic>?;
  if (data == null) {
    throw Exception('Missing "data" key in JSON');
  }

  // Parse entries and convert to list
  final entries = <_LetterCountEntry>[];
  for (final entry in data.entries) {
    final key = entry.key;
    final value = entry.value;
    
    if (value is! int) {
      throw Exception('Invalid value type for key $key: expected int, got ${value.runtimeType}');
    }

    final parts = key.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid key format: $key (expected "surah:ayah")');
    }

    final surahNumber = int.tryParse(parts[0]);
    final ayahNumber = int.tryParse(parts[1]);

    if (surahNumber == null || ayahNumber == null) {
      throw Exception('Invalid number format in key $key');
    }

    entries.add(_LetterCountEntry(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      lettersCount: value,
    ));
  }

  // Sort by surah_number, then ayah_number
  entries.sort((a, b) {
    if (a.surahNumber != b.surahNumber) {
      return a.surahNumber.compareTo(b.surahNumber);
    }
    return a.ayahNumber.compareTo(b.ayahNumber);
  });

  // Build CSV rows
  final rows = <String>[];
  rows.add('surah_number,ayah_number,letters_count'); // Header

  for (final entry in entries) {
    rows.add('${entry.surahNumber},${entry.ayahNumber},${entry.lettersCount}');
  }

  return rows;
}

/// Writes CSV rows to file.
Future<void> _writeCsvFile(String path, List<String> rows) async {
  final file = File(path);
  await file.writeAsString(rows.join('\n'));
}

/// Represents a single letter count entry.
class _LetterCountEntry {
  final int surahNumber;
  final int ayahNumber;
  final int lettersCount;

  _LetterCountEntry({
    required this.surahNumber,
    required this.ayahNumber,
    required this.lettersCount,
  });
}

