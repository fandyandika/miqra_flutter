import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
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
import '../../streak/providers/streak_providers.dart';
import '../../../core/constants/colors.dart';

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
  // Confetti controller for target celebration
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePosition();
      _setupTargetListener();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _setupTargetListener() {
    // Listen for target completion
    ref.listen<AsyncValue<TodayReadingStats>>(
      todayReadingStatsProvider,
      (prev, next) {
        final settings = ref.read(readerSettingsProvider).valueOrNull;
        if (settings == null) return;
        if (!next.hasValue) return;

        final stats = next.value!;
        final prevStats = prev?.valueOrNull;

        // Trigger confetti if just reached target
        if (prevStats != null &&
            prevStats.totalAyat < settings.dailyTargetAyat &&
            stats.totalAyat >= settings.dailyTargetAyat) {
          _confettiController.play();
          _showTargetReachedDialog();
        }
      },
    );
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _TopStatsBar(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Batalkan log terakhir',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Batalkan Log?'),
                  content: const Text('Hapus log bacaan terakhir?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Ya, Hapus'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref.read(readingSessionServiceProvider).deleteLastSession();
                  ref.invalidate(todayReadingStatsProvider);

                  // Reset last logged position in controller
                  final controller = ref.read(focusReaderControllerProvider.notifier);
                  controller.resetLastLogged();

                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Log terakhir dibatalkan'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Gagal membatalkan log: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Pengaturan',
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
      body: Stack(
        children: [
          Column(
            children: [
              // Goal Tracker (below top stats bar)
              _GoalTracker(),
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
              onDone: () {
                Navigator.of(context).pop();
              },
              onNext: () async {
                HapticFeedback.lightImpact();
                final controller = ref.read(focusReaderControllerProvider.notifier);
                final currentState = ref.read(focusReaderControllerProvider);
                
                // Guard: prevent action if already logging
                if (currentState.isLogging) return;
                
                // Only proceed if we can move forward
                if (currentState.ayahNumber < currentState.totalAyatInSurah) {
                  // Check if this ayah was already logged
                  final alreadyLogged = currentState.lastLoggedSurah == currentState.surahNumber &&
                      currentState.lastLoggedAyah == currentState.ayahNumber;
                  
                  if (alreadyLogged) {
                    // Just move to next ayah without logging
                    controller.nextAyah();
                    _savePosition();
                  } else {
                    // Move to next ayah and log
                    controller.nextAyah();
                    _savePosition();
                    
                    // Auto-log reading session
                    final newState = ref.read(focusReaderControllerProvider);
                    await _logReadingSession(newState.surahNumber, newState.ayahNumber);
                  }
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
              onDone: () {
                Navigator.of(context).pop();
              },
              onNext: () async {
                HapticFeedback.lightImpact();
                final controller = ref.read(focusReaderControllerProvider.notifier);
                final currentState = ref.read(focusReaderControllerProvider);
                
                // Guard: prevent action if already logging
                if (currentState.isLogging) return;
                
                // Only proceed if we can move forward
                if (currentState.ayahNumber < currentState.totalAyatInSurah) {
                  // Check if this ayah was already logged
                  final alreadyLogged = currentState.lastLoggedSurah == currentState.surahNumber &&
                      currentState.lastLoggedAyah == currentState.ayahNumber;
                  
                  if (alreadyLogged) {
                    // Just move to next ayah without logging
                    controller.nextAyah();
                    _savePosition();
                  } else {
                    // Move to next ayah and log
                    controller.nextAyah();
                    _savePosition();
                    
                    // Auto-log reading session
                    final newState = ref.read(focusReaderControllerProvider);
                    await _logReadingSession(newState.surahNumber, newState.ayahNumber);
                  }
                }
              },
            ),
          ),
            ],
          ),
          // Confetti widget for target celebration
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                miqraPrimary, // Color(0xFF14B4A0)
                miqraCoral,   // Color(0xFFFF8A65)
                miqraGold,    // Color(0xFFFFB627)
              ],
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
    final controller = ref.read(focusReaderControllerProvider.notifier);
    final currentState = ref.read(focusReaderControllerProvider);
    
    // Guard: prevent double logging
    if (currentState.isLogging) return;
    if (currentState.lastLoggedSurah == surahNumber && 
        currentState.lastLoggedAyah == ayahNumber) {
      return;
    }

    // Set logging flag
    controller.setLogging(true);

    try {
      final service = ref.read(readingSessionServiceProvider);
      await service.logSession(
        surahNumber: surahNumber,
        ayahStart: ayahNumber,
        ayahEnd: ayahNumber,
        readingMode: 'focus',
      );

      // Update last logged position in controller
      controller.setLastLogged(surahNumber, ayahNumber);

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Invalidate stats to refresh
      ref.invalidate(todayReadingStatsProvider);
      ref.invalidate(streakSummaryProvider);
    } catch (e) {
      // Silently fail - don't interrupt user experience
      // Could add analytics/logging here if needed
    } finally {
      // Clear logging flag
      controller.setLogging(false);
    }
  }

  /// Shows dialog when daily target is reached.
  void _showTargetReachedDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Target Tercapai!'),
        content: const Text(
          'Alhamdulillah, target harian kamu sudah terpenuhi. Lanjut membaca?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Selesai'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Continue reading - dialog closed, user can continue
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: miqraPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lanjut Baca'),
          ),
        ],
      ),
    );
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
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
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
                  fontWeight: FontWeight.w400,
                  color: miqraText,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopStatsBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(todayReadingStatsProvider);
    final readingTimeAsync = ref.watch(totalReadingTimeProvider);

    final stats = statsAsync.valueOrNull;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            emoji: '⏱️',
            value: readingTimeAsync.when(
              data: (duration) => _formatDuration(duration),
              loading: () => '...',
              error: (_, __) => '00:00',
            ),
          ),
          _StatItem(
            emoji: '📖',
            value: stats != null ? '${stats.totalAyat} ayat' : '0 ayat',
          ),
          _StatItem(
            emoji: '✨',
            value: stats != null ? _formatHasanat(stats.totalHasanat) : '0',
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  String _formatHasanat(int hasanat) {
    if (hasanat >= 1000) {
      return '${(hasanat / 1000).toStringAsFixed(1)}K';
    }
    return '$hasanat';
  }
}

class _StatItem extends StatelessWidget {
  final String emoji;
  final String value;

  const _StatItem({
    required this.emoji,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: miqraText,
          ),
        ),
      ],
    );
  }
}

class _GoalTracker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(todayReadingStatsProvider);
    final settingsAsync = ref.watch(readerSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final stats = statsAsync.valueOrNull ?? TodayReadingStats.empty();
        final dailyTarget = settings.dailyTargetAyat;
        final reachedTarget = stats.totalAyat >= dailyTarget && dailyTarget > 0;
        final progress = dailyTarget > 0
            ? (stats.totalAyat / dailyTarget).clamp(0.0, 1.0)
            : 0.0;
        final remaining = dailyTarget > 0 ? (dailyTarget - stats.totalAyat).clamp(0, dailyTarget) : 0;

        if (dailyTarget == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: reachedTarget 
                ? Colors.green.withValues(alpha: 0.1)
                : miqraPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: reachedTarget ? Colors.green : miqraPrimary,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    reachedTarget ? 'Goal Tercapai! 🎉' : 'Goal Hari Ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: reachedTarget ? Colors.green : miqraText,
                    ),
                  ),
                  if (reachedTarget)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${stats.totalAyat - dailyTarget}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Text(
                      '$remaining tersisa',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: miqraText,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  reachedTarget ? Colors.green : miqraPrimary,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                '${stats.totalAyat} / $dailyTarget ayat',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _FocusBottomBar extends ConsumerWidget {
  final FocusReaderState state;
  final ReaderSettings? settings;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onDone;

  const _FocusBottomBar({
    required this.state,
    this.settings,
    required this.onPrev,
    required this.onNext,
    this.onDone,
  });

  int _estimateHasanat(int surahNumber, int ayahNumber) {
    // Rough estimate: average ayah has ~50-60 letters
    // Hasanat = letters * 10, so average ~500-600 hasanat per ayah
    // Using 550 as average
    return 550;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(todayReadingStatsProvider);
    final settingsValue = settings ?? ref.watch(readerSettingsProvider).valueOrNull;
    final dailyTarget = settingsValue?.dailyTargetAyat ?? state.dailyTargetAyat;
    
    final stats = statsAsync.valueOrNull ?? TodayReadingStats.empty();
    final reachedTarget = stats.totalAyat >= dailyTarget && dailyTarget > 0;
    final progress = dailyTarget > 0
        ? (stats.totalAyat / dailyTarget).clamp(0.0, 1.0)
        : 0.0;

    final estimatedHasanat = _estimateHasanat(state.surahNumber, state.ayahNumber);
    final canGoNext = state.ayahNumber < state.totalAyatInSurah && !state.isLogging;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reachedTarget 
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              if (reachedTarget) ...[
                const Text(
                  'Target harian tercapai 🎉',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stats.totalAyat} ayat dibaca hari ini',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ] else ...[
                Text(
                  'Target hari ini: ${stats.totalAyat}/$dailyTarget ayat',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: reachedTarget ? 1.0 : progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  reachedTarget ? Colors.green : miqraPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button (icon only)
              IconButton(
                onPressed: state.ayahNumber > 1 ? onPrev : null,
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  padding: const EdgeInsets.all(16),
                ),
              ),
              // Done button (center, prominent)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: miqraPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // Next button with hasanat estimate (icon only)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canGoNext)
                    Text(
                      '+$estimatedHasanat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: miqraGold,
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                  IconButton(
                    onPressed: canGoNext ? onNext : null,
                    icon: const Icon(Icons.arrow_forward),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

