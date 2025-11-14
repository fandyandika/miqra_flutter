import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/surah_model.dart';

Future<SurahData> loadSurahFromAsset(int surahNumber) async {
  try {
    // Load from SQL format (single file with all surahs, includes Arabic + Translation)
    final sqlPath = 'assets/data/quran/quran-indonesia.sql';
    final sqlRaw = await rootBundle.loadString(sqlPath);

    // Load merged surah metadata (names/types/counts) - optional, fallback to hardcoded names
    String? metaRaw;
    try {
      final metaPath = 'assets/data/metadata/surah_meta_merge.json';
      metaRaw = await rootBundle.loadString(metaPath);
    } catch (_) {
      // Metadata file not found or error loading - will use fallback names
      metaRaw = null;
    }
    
    return compute(_parseSurahFromSQL, {'sql': sqlRaw, 'number': surahNumber, 'meta': metaRaw});
  } catch (e, stackTrace) {
    throw Exception('Failed to load surah $surahNumber: $e\n$stackTrace');
  }
}

SurahData _parseSurahFromSQL(Map<String, dynamic> data) {
  final sqlContent = data['sql'] as String;
  final surahNumber = data['number'] as int;
  final metaRaw = data['meta'] as String?;
  
  // Parse SQL INSERT statements line by line
  // Format: INSERT INTO quran_id (id, suraId, verseID, ayahText, indoText, readText ) VALUES (0,1,1,"...", "...", "...");
  final lines = sqlContent.split('\n');
  final verses = <Verse>[];
  
  for (final line in lines) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('INSERT INTO')) continue;
    
    // Find VALUES keyword and extract the values part
    final valuesIndex = trimmed.indexOf('VALUES');
    if (valuesIndex == -1) continue;
    
    // Extract the part after VALUES: (id,suraId,verseID,"text","translation","translit")
    final valuesPart = trimmed.substring(valuesIndex + 6).trim(); // +6 for "VALUES"
    if (!valuesPart.startsWith('(') || !valuesPart.endsWith(');')) continue;
    
    // Remove parentheses and semicolon
    final valuesContent = valuesPart.substring(1, valuesPart.length - 2);
    
    // Parse values manually - split by comma but respect quoted strings
    final values = _parseSQLValues(valuesContent);
    if (values.length < 6) continue;
    
    final suraId = int.tryParse(values[1]) ?? 0;
    if (suraId != surahNumber) continue;
    
    final verseId = int.tryParse(values[2]) ?? 0;
    var ayahText = values[3];
    final indoText = values[4];
    final readText = values.length > 5 ? values[5] : '';
    
    // Remove BOM character if present
    if (ayahText.isNotEmpty && ayahText.codeUnitAt(0) == 0xFEFF) {
      ayahText = ayahText.substring(1);
    }
    
    verses.add(Verse(
      ayah: verseId,
      textAr: ayahText.trim(),
      textId: indoText.trim(),
      textTranslit: readText.trim().isNotEmpty ? readText.trim() : null,
    ));
  }
  
  // Sort by ayah number
  verses.sort((a, b) => a.ayah.compareTo(b.ayah));
  
  if (verses.isEmpty) {
    throw Exception('Surah $surahNumber not found in SQL data');
  }

  // Prefer name_id from merged metadata for Latin name
  final latinNameFromMeta = _lookupLatinNameFromMeta(metaRaw, surahNumber);
  
  return SurahData(
    surahNumber: surahNumber,
    nameArabic: _getArabicName(surahNumber),
    nameLatin: latinNameFromMeta ?? _getLatinName(surahNumber),
    verses: verses,
  );
}

String? _lookupLatinNameFromMeta(String? metaRaw, int surahNumber) {
  if (metaRaw == null || metaRaw.isEmpty) return null;
  try {
    final decoded = json.decode(metaRaw) as Map<String, dynamic>;
    final surahs = decoded['surahs'] as List<dynamic>?;
    if (surahs == null) return null;
    for (final item in surahs) {
      final m = item as Map<String, dynamic>;
      if ((m['surah'] as num?)?.toInt() == surahNumber) {
        final nameId = m['name_id'] as String?;
        if (nameId != null && nameId.trim().isNotEmpty) {
          return nameId.trim();
        }
        break;
      }
    }
  } catch (_) {}
  return null;
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
  
  // Add last value
  if (current.isNotEmpty) {
    result.add(current.toString());
  }
  
  // Remove quotes from string values
  for (var i = 0; i < result.length; i++) {
    var value = result[i].trim();
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
      // Unescape double quotes
      value = value.replaceAll('""', '"');
      result[i] = value;
    }
  }
  
  return result;
}

String _getArabicName(int surahNumber) {
  // Map surah numbers to Arabic names
  const names = {
    1: 'الفاتحة',
    2: 'البقرة',
    3: 'آل عمران',
  };
  return names[surahNumber] ?? 'الفاتحة';
}

String _getLatinName(int surahNumber) {
  // Minimal Latin names (fallback only)
  const names = {
    1: 'Al-Fatihah',
    2: 'Al-Baqarah',
    3: "Ali 'Imran",
  };
  return names[surahNumber] ?? 'Al-Fatihah';
}

