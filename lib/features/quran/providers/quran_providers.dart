import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/parsers/quran_parser.dart';
import '../data/parsers/tajwid_parser.dart';
import '../data/parsers/tajwid_parser_v2.dart';
import '../data/models/surah_model.dart';
import '../data/models/tajwid_model.dart';
import '../data/models/tajwid_model_v2.dart';

final translationVisibleProvider = StateProvider<bool>((_) => true);
final tajwidVisibleProvider = StateProvider<bool>((_) => false);
final tajwidEnabledProvider = StateProvider<bool>((_) => false);

final alFatihahProvider = FutureProvider<SurahData>((ref) async {
  return loadSurahFromAsset(1);
});

final surahProvider = FutureProvider.family<SurahData, int>((ref, surahNumber) async {
  return loadSurahFromAsset(surahNumber);
});

final tajwidDataProvider = FutureProvider.family<TajwidData, int>((ref, surahNumber) async {
  return loadTajwidFromAsset(surahNumber);
});

final tajwidSurahProvider = FutureProvider.family<TajwidSurah, int>((ref, surahNumber) async {
  return loadTajwid(surahNumber);
});

