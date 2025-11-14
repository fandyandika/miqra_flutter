import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/parsers/surah_meta_parser.dart';
import '../data/models/surah_meta_model.dart';

final surahMetaListProvider = FutureProvider<List<SurahMeta>>((ref) async {
  return loadSurahMeta();
});

final surahSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final filteredSurahListProvider =
    Provider.autoDispose<List<SurahMeta>>((ref) {
  final surahListAsync = ref.watch(surahMetaListProvider);
  final searchQuery = ref.watch(surahSearchQueryProvider);

  return surahListAsync.when(
    data: (surahs) {
      if (searchQuery.isEmpty) {
        return surahs;
      }

      final queryLower = searchQuery.toLowerCase();
      return surahs.where((surah) {
        return surah.nameLatin.toLowerCase().contains(queryLower) ||
            surah.nameArabic.contains(searchQuery) ||
            surah.nameTranslationId.toLowerCase().contains(queryLower);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final surahSearchDebounceProvider = StateProvider<Timer?>((ref) => null);

final surahMetaProvider = Provider.family<SurahMeta?, int>((ref, surahNumber) {
  final surahListAsync = ref.watch(surahMetaListProvider);
  return surahListAsync.when(
    data: (surahs) {
      if (surahNumber < 1 || surahNumber > 114) return null;
      return surahs[surahNumber - 1];
    },
    loading: () => null,
    error: (_, __) => null,
  );
});


