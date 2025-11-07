import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/tajwid_model.dart';

Future<TajwidData> loadTajwidFromAsset(int surahNumber) async {
  try {
    final path = 'assets/data/quran/tajweedcpfair/surah_$surahNumber.json';
    final raw = await rootBundle.loadString(path);
    return compute(_parseTajwid, raw);
  } catch (e, stackTrace) {
    throw Exception('Failed to load tajwid for surah $surahNumber: $e\n$stackTrace');
  }
}

TajwidData _parseTajwid(String raw) {
  final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
  return TajwidData.fromJson(json);
}

