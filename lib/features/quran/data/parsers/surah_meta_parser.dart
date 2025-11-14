import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/surah_meta_model.dart';

Future<List<SurahMeta>> loadSurahMeta() async {
  try {
    final rawJson = await rootBundle.loadString(
      'assets/data/derived/surah_meta_merge.json',
    );
    return compute(_parseSurahMeta, rawJson);
  } catch (e) {
    throw Exception('Failed to load surah metadata: $e');
  }
}

List<SurahMeta> _parseSurahMeta(String rawJson) {
  final envelope = SurahMetaEnvelope.fromJson(
    json.decode(rawJson) as Map<String, dynamic>,
  );

  if (envelope.surahs.length != 114) {
    throw Exception(
      'Expected 114 surahs, got ${envelope.surahs.length}',
    );
  }

  final sorted = [...envelope.surahs]
    ..sort((a, b) => a.number.compareTo(b.number));

  // Assert sequence
  for (var i = 0; i < sorted.length; i++) {
    if (sorted[i].number != i + 1) {
      throw Exception(
        'Surah number mismatch at index $i: expected ${i + 1}, got ${sorted[i].number}',
      );
    }
  }

  return sorted;
}


