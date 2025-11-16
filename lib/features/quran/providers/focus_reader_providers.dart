import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/parsers/quran_parser.dart';
import '../data/models/surah_model.dart';
import '../data/models/surah_meta_model.dart';
import '../providers/surah_providers.dart';

class FocusReaderState {
  final int surahNumber;
  final int ayahNumber;
  final int totalAyatInSurah;
  final int todayReadCount;
  final int dailyTargetAyat;
  final int? lastLoggedSurah;
  final int? lastLoggedAyah;
  final bool isLogging;

  const FocusReaderState({
    required this.surahNumber,
    required this.ayahNumber,
    required this.totalAyatInSurah,
    required this.todayReadCount,
    required this.dailyTargetAyat,
    this.lastLoggedSurah,
    this.lastLoggedAyah,
    this.isLogging = false,
  });

  FocusReaderState copyWith({
    int? surahNumber,
    int? ayahNumber,
    int? totalAyatInSurah,
    int? todayReadCount,
    int? dailyTargetAyat,
    int? lastLoggedSurah,
    int? lastLoggedAyah,
    bool? isLogging,
  }) {
    return FocusReaderState(
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      totalAyatInSurah: totalAyatInSurah ?? this.totalAyatInSurah,
      todayReadCount: todayReadCount ?? this.todayReadCount,
      dailyTargetAyat: dailyTargetAyat ?? this.dailyTargetAyat,
      lastLoggedSurah: lastLoggedSurah ?? this.lastLoggedSurah,
      lastLoggedAyah: lastLoggedAyah ?? this.lastLoggedAyah,
      isLogging: isLogging ?? this.isLogging,
    );
  }
}

class FocusReaderController extends StateNotifier<FocusReaderState> {
  FocusReaderController() : super(const FocusReaderState(
    surahNumber: 1,
    ayahNumber: 1,
    totalAyatInSurah: 7,
    todayReadCount: 0,
    dailyTargetAyat: 5,
    lastLoggedSurah: null,
    lastLoggedAyah: null,
    isLogging: false,
  ));

  void setPosition(int surah, int ayah, int totalAyat) {
    state = state.copyWith(
      surahNumber: surah,
      ayahNumber: ayah,
      totalAyatInSurah: totalAyat,
    );
  }

  void nextAyah() {
    if (state.ayahNumber < state.totalAyatInSurah) {
      state = state.copyWith(ayahNumber: state.ayahNumber + 1);
    }
  }

  void prevAyah() {
    if (state.ayahNumber > 1) {
      state = state.copyWith(ayahNumber: state.ayahNumber - 1);
    }
  }

  void updateDailyStats(int todayReadCount, int dailyTarget) {
    state = state.copyWith(
      todayReadCount: todayReadCount,
      dailyTargetAyat: dailyTarget,
    );
  }

  void setLastLogged(int surah, int ayah) {
    state = state.copyWith(
      lastLoggedSurah: surah,
      lastLoggedAyah: ayah,
    );
  }

  void resetLastLogged() {
    state = state.copyWith(
      lastLoggedSurah: null,
      lastLoggedAyah: null,
    );
  }

  void setLogging(bool isLogging) {
    state = state.copyWith(isLogging: isLogging);
  }
}

final focusReaderControllerProvider =
    StateNotifierProvider<FocusReaderController, FocusReaderState>((ref) {
  return FocusReaderController();
});

final focusAyahProvider = FutureProvider.family<Verse, ({int surah, int ayah})>((ref, params) async {
  final surahData = await loadSurahFromAsset(params.surah);
  final verse = surahData.verses.firstWhere(
    (v) => v.ayah == params.ayah,
    orElse: () => throw Exception('Ayah ${params.ayah} not found in surah ${params.surah}'),
  );
  return verse;
});

final focusSurahMetaProvider = Provider.family<SurahMeta?, int>((ref, surahNumber) {
  return ref.watch(surahMetaProvider(surahNumber));
});

