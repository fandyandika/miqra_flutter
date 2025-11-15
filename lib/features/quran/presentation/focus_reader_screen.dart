import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/focus_reader_providers.dart';
import '../providers/surah_providers.dart';
import '../data/models/surah_model.dart';
import '../data/last_read_service.dart';
import '../../bookmark/presentation/bookmark_save_sheet.dart';
import '../../settings/providers/reader_settings_providers.dart';
import '../../settings/presentation/reader_settings_sheet.dart';
import '../../settings/data/reader_settings_hive.dart';
import '../../reading/providers/reading_providers.dart';
import '../../reading/data/today_reading_stats_model.dart';

class FocusReaderScreen extends ConsumerStatefulWidget {
  const FocusReaderScreen({
    super.key,
    this.surahNumber,
    this.initialAyah,
  });

  final int? surahNumber;
  final int? initialAyah;

  @override
  ConsumerState<FocusReaderScreen> createState() => _FocusReaderScreenState();
}

class _FocusReaderScreenState extends ConsumerState<FocusReaderScreen> {
  // Track last logged position to avoid double logging
  int? _lastLoggedSurah;
  int? _lastLoggedAyah;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePosition();
    });
  }

  Future<void> _initializePosition() async {
    final controller = ref.read(focusReaderControllerProvider.notifier);
    final lastRead = LastReadService.getLastRead();
    
    int surah = widget.surahNumber ?? 1;
    int ayah = widget.initialAyah ?? 1;

    if (widget.surahNumber == null && widget.initialAyah == null) {
      if (lastRead != null && lastRead.mode == 'focus') {
        surah = lastRead.surah;
        ayah = lastRead.ayah;
      }
    }

    final surahMeta = ref.read(surahMetaProvider(surah));
    final totalAyat = surahMeta?.ayahCount ?? 7;
    final settings = ref.read(readerSettingsOnceProvider);
    
    controller.setPosition(surah, ayah, totalAyat);
    controller.updateDailyStats(0, settings.dailyTargetAyat);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(focusReaderControllerProvider);
    final surahMeta = ref.watch(surahMetaProvider(state.surahNumber));
    final ayahAsync = ref.watch(focusAyahProvider((surah: state.surahNumber, ayah: state.ayahNumber)));

    final settings = ref.watch(readerSettingsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Baca Fokus'),
            if (surahMeta != null)
              Text(
                '${surahMeta.nameLatin} - Ayat ${state.ayahNumber}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: const ReaderSettingsSheet(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ayahAsync.when(
                data: (verse) => settings.when(
                  data: (settings) => GestureDetector(
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: BookmarkSaveSheet(
                            verse: verse,
                            surahNumber: state.surahNumber,
                          ),
                        ),
                      );
                    },
                    child: _AyahCard(verse: verse, settings: settings),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => GestureDetector(
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: BookmarkSaveSheet(
                            verse: verse,
                            surahNumber: state.surahNumber,
                          ),
                        ),
                      );
                    },
                    child: _AyahCard(verse: verse),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error: $e'),
                ),
              ),
            ),
          ),
          settings.when(
            data: (settings) => _FocusBottomBar(
              state: state,
              settings: settings,
              onPrev: () {
                HapticFeedback.lightImpact();
                ref.read(focusReaderControllerProvider.notifier).prevAyah();
                _savePosition();
              },
              onNext: () async {
                HapticFeedback.lightImpact();
                final controller = ref.read(focusReaderControllerProvider.notifier);
                final currentState = ref.read(focusReaderControllerProvider);
                
                // Only proceed if we can move forward
                if (currentState.ayahNumber < currentState.totalAyatInSurah) {
                  controller.nextAyah();
                  _savePosition();
                  
                  // Auto-log reading session
                  final newState = ref.read(focusReaderControllerProvider);
                  await _logReadingSession(newState.surahNumber, newState.ayahNumber);
                }
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => _FocusBottomBar(
              state: state,
              settings: null,
              onPrev: () {
                HapticFeedback.lightImpact();
                ref.read(focusReaderControllerProvider.notifier).prevAyah();
                _savePosition();
              },
              onNext: () async {
                HapticFeedback.lightImpact();
                final controller = ref.read(focusReaderControllerProvider.notifier);
                final currentState = ref.read(focusReaderControllerProvider);
                
                // Only proceed if we can move forward
                if (currentState.ayahNumber < currentState.totalAyatInSurah) {
                  controller.nextAyah();
                  _savePosition();
                  
                  // Auto-log reading session
                  final newState = ref.read(focusReaderControllerProvider);
                  await _logReadingSession(newState.surahNumber, newState.ayahNumber);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _savePosition() {
    final state = ref.read(focusReaderControllerProvider);
    LastReadService.saveLastRead(state.surahNumber, state.ayahNumber, 'focus');
  }

  /// Logs reading session for a single ayah (auto-logging in focus mode).
  Future<void> _logReadingSession(int surahNumber, int ayahNumber) async {
    // Guard: Only log if this is a new position
    if (_lastLoggedSurah == surahNumber && _lastLoggedAyah == ayahNumber) {
      return;
    }

    try {
      final service = ref.read(readingSessionServiceProvider);
      await service.logSession(
        surahNumber: surahNumber,
        ayahStart: ayahNumber,
        ayahEnd: ayahNumber,
        readingMode: 'focus',
      );

      // Update last logged position
      _lastLoggedSurah = surahNumber;
      _lastLoggedAyah = ayahNumber;

      // Invalidate stats to refresh
      ref.invalidate(todayReadingStatsProvider);
    } catch (e) {
      // Silently fail - don't interrupt user experience
      // Could add analytics/logging here if needed
    }
  }
}

class _AyahCard extends StatelessWidget {
  final Verse verse;
  final ReaderSettings? settings;

  const _AyahCard({required this.verse, this.settings});

  double _getArabicFontSize() {
    if (settings == null) return 28;
    switch (settings!.fontSizeLevel) {
      case 0:
        return 24;
      case 1:
        return 28;
      case 2:
        return 32;
      default:
        return 28;
    }
  }

  double _getTextFontSize() {
    if (settings == null) return 16;
    switch (settings!.fontSizeLevel) {
      case 0:
        return 14;
      case 1:
        return 16;
      case 2:
        return 18;
      default:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arabic text
            Text(
              verse.textAr,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'IndopakNastaleeq',
                fontSize: _getArabicFontSize(),
                height: 1.5,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            // Transliteration
            if (verse.textTranslit != null && (settings == null || settings!.showTransliteration))
              Text(
                verse.textTranslit!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: _getTextFontSize(),
                  height: 1.3,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (verse.textTranslit != null && (settings == null || settings!.showTransliteration))
              const SizedBox(height: 16),
            // Translation
            if (settings == null || settings!.showTranslation)
              Text(
                verse.textId,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: _getTextFontSize(),
                  height: 1.4,
                  color: const Color(0xFF2E3A46),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FocusBottomBar extends ConsumerWidget {
  final FocusReaderState state;
  final ReaderSettings? settings;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _FocusBottomBar({
    required this.state,
    this.settings,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(todayReadingStatsProvider);
    final settingsValue = settings ?? ref.watch(readerSettingsProvider).valueOrNull;
    final dailyTarget = settingsValue?.dailyTargetAyat ?? state.dailyTargetAyat;
    
    final stats = statsAsync.valueOrNull ?? TodayReadingStats.empty();
    final progress = dailyTarget > 0
        ? (stats.totalAyat / dailyTarget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target hari ini: ${stats.totalAyat}/$dailyTarget ayat',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF14B4A0)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: state.ayahNumber > 1 ? onPrev : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Sebelumnya'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              Text(
                '${state.ayahNumber}/${state.totalAyatInSurah}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: state.ayahNumber < state.totalAyatInSurah ? onNext : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Selanjutnya'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

