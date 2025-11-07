import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/tajwid_model_v2.dart';

/// Loads tajwid data from JSON asset.
/// 
/// Path format: assets/data/tajwid/NNN.json where NNN is surah number (001, 002, etc.)
Future<TajwidSurah> loadTajwid(int surahNumber) async {
  try {
    final surahNumStr = surahNumber.toString().padLeft(3, '0');
    final path = 'assets/data/tajwid/$surahNumStr.json';
    final raw = await rootBundle.loadString(path);
    return compute(_parseTajwid, raw);
  } catch (e, stackTrace) {
    throw Exception('Failed to load tajwid for surah $surahNumber: $e\n$stackTrace');
  }
}

TajwidSurah _parseTajwid(String raw) {
  final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
  return TajwidSurah.fromJson(json);
}

