import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/animations.dart';
import '../../../shared/widgets/miqra_components.dart';
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
  late ConfettiController _confettiController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePosition();
      _setupTargetListener();
      _startTimer();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    final controller = ref.read(focusReaderControllerProvider.notifier);
    controller.startTimer();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final state = ref.read(focusReaderControllerProvider);
      if (state.sessionStartTime != null) {
        final elapsed = DateTime.now().difference(state.sessionStartTime!);
        controller.updateElapsedTime(elapsed);
      }
    });
  }

  void _setupTargetListener() {
    ref.listen<AsyncValue<TodayReadingStats>>(
      todayReadingStatsProvider,
      (prev, next) {
        final settings = ref.read(readerSettingsProvider).valueOrNull;
        if (settings == null) return;
        if (!next.hasValue) return;

        final stats = next.value!;
        final prevStats = prev?.valueOrNull;

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
            Text('Baca Fokus', style: MiqraTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            if (surahMeta != null)
              Text(
                '${surahMeta.nameLatin} - Ayat ${state.ayahNumber}',
                style: MiqraTextStyles.label.copyWith(color: MiqraColors.textSecondary),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _TopStatsBar(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Pilih Surah',
            onPressed: () => _showSurahSelector(context),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Batalkan log terakhir',
            onPressed: () => _undoLastLog(context),
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
              _GoalTracker(),
              Expanded(
                child: SingleChildScrollView(
                  padding: MiqraSpacing.screenPadding,
                  child: ayahAsync.when(
                    data: (verse) => settings.when(
                      data: (settings) => MiqraAnimations.scaleIn(
                        child: GestureDetector(
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
                      ),
                      loading: () => const MiqraLoading(),
                      error: (_, __) => _AyahCard(verse: verse),
                    ),
                    loading: () => const MiqraLoading(),
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
                  onNext: () => _handleNext(),
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
                  onNext: () => _handleNext(),
                ),
              ),
            ],
          ),
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
                miqraPrimary,
                miqraCoral,
                miqraGold,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext() async {
    HapticFeedback.lightImpact();
    final controller = ref.read(focusReaderControllerProvider.notifier);
    final currentState = ref.read(focusReaderControllerProvider);

    if (currentState.isLogging) return;

    // Check if reached end of surah
    if (currentState.ayahNumber >= currentState.totalAyatInSurah) {
      await _showNextSurahDialog(context);
      return;
    }

    // Check if already logged
    final alreadyLogged = currentState.lastLoggedSurah == currentState.surahNumber &&
        currentState.lastLoggedAyah == currentState.ayahNumber;

    if (alreadyLogged) {
      controller.nextAyah();
      _savePosition();
    } else {
      controller.nextAyah();
      _savePosition();

      final newState = ref.read(focusReaderControllerProvider);
      await _logReadingSession(newState.surahNumber, newState.ayahNumber);
    }
  }

  Future<void> _showNextSurahDialog(BuildContext context) async {
    final currentState = ref.read(focusReaderControllerProvider);
    if (currentState.surahNumber >= 114) {
      // Reached end of Quran
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🎉 Alhamdulillah!'),
          content: const Text('Anda telah mencapai akhir Al-Qur\'an. Semoga menjadi amal yang diterima.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
      return;
    }

    final nextSurahNumber = currentState.surahNumber + 1;
    final nextSurahMeta = ref.read(surahMetaProvider(nextSurahNumber));

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Surah Selesai! 🎉'),
        content: Text(
          'Lanjut ke ${nextSurahMeta?.nameLatin ?? "surah berikutnya"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MiqraColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final controller = ref.read(focusReaderControllerProvider.notifier);
      controller.changeSurah(nextSurahNumber, nextSurahMeta?.ayahCount ?? 7);
      _savePosition();
    }
  }

  Future<void> _showSurahSelector(BuildContext context) async {
    final allSurahs = ref.read(surahMetaListProvider).valueOrNull ?? [];

    if (!mounted) return;
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: MiqraSpacing.screenPadding,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: MiqraColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Pilih Surah', style: MiqraTextStyles.headline),
              MiqraSpacing.gapMD,
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: allSurahs.length,
                  separatorBuilder: (_, __) => MiqraSpacing.gapXS,
                  itemBuilder: (context, index) {
                    final surah = allSurahs[index];
                    return MiqraAnimations.staggeredItem(
                      index: index,
                      child: MiqraCard(
                        onTap: () => Navigator.pop(context, surah.number),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: MiqraColors.primarySubtle,
                                borderRadius: MiqraSpacing.radiusSmall,
                              ),
                              child: Center(
                                child: Text(
                                  '${surah.number}',
                                  style: MiqraTextStyles.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: MiqraColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            MiqraSpacing.gapHorizontalSM,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    surah.nameLatin,
                                    style: MiqraTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${surah.ayahCount} ayat',
                                    style: MiqraTextStyles.caption.copyWith(
                                      color: MiqraColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      final controller = ref.read(focusReaderControllerProvider.notifier);
      final surahMeta = ref.read(surahMetaProvider(selected));
      controller.changeSurah(selected, surahMeta?.ayahCount ?? 7);
      _savePosition();
    }
  }

  Future<void> _undoLastLog(BuildContext context) async {
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
      try {
        await ref.read(readingSessionServiceProvider).deleteLastSession();
        ref.invalidate(todayReadingStatsProvider);

        final controller = ref.read(focusReaderControllerProvider.notifier);
        controller.resetLastLogged();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Log terakhir dibatalkan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membatalkan log: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _savePosition() {
    final state = ref.read(focusReaderControllerProvider);
    LastReadService.saveLastRead(state.surahNumber, state.ayahNumber, 'focus');
  }

  Future<void> _logReadingSession(int surahNumber, int ayahNumber) async {
    final controller = ref.read(focusReaderControllerProvider.notifier);
    final currentState = ref.read(focusReaderControllerProvider);

    if (currentState.isLogging) return;
    if (currentState.lastLoggedSurah == surahNumber &&
        currentState.lastLoggedAyah == ayahNumber) {
      return;
    }

    controller.setLogging(true);

    try {
      final service = ref.read(readingSessionServiceProvider);
      await service.logSession(
        surahNumber: surahNumber,
        ayahStart: ayahNumber,
        ayahEnd: ayahNumber,
        readingMode: 'focus',
      );

      controller.setLastLogged(surahNumber, ayahNumber);
      HapticFeedback.lightImpact();

      ref.invalidate(todayReadingStatsProvider);
      ref.invalidate(streakSummaryProvider);
    } catch (e) {
      // Silently fail
    } finally {
      controller.setLogging(false);
    }
  }

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
    return MiqraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            verse.textAr,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'IndopakNastaleeq',
              fontSize: _getArabicFontSize(),
              height: 1.5,
              color: MiqraColors.textPrimary,
            ),
          ),
          MiqraSpacing.gapLG,
          if (verse.textTranslit != null && (settings == null || settings!.showTransliteration)) ...[
            Text(
              verse.textTranslit!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: _getTextFontSize(),
                height: 1.3,
                fontWeight: FontWeight.w400,
                color: MiqraColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            MiqraSpacing.gapMD,
          ],
          if (settings == null || settings!.showTranslation)
            Text(
              verse.textId,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: _getTextFontSize(),
                height: 1.4,
                fontWeight: FontWeight.w400,
                color: MiqraColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

class _TopStatsBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusReaderControllerProvider);
    final statsAsync = ref.watch(todayReadingStatsProvider);
    final stats = statsAsync.valueOrNull;

    return Container(
      padding: MiqraSpacing.cardPadding,
      decoration: BoxDecoration(
        color: MiqraColors.bgSecondary,
        border: Border(
          bottom: BorderSide(color: MiqraColors.borderLight, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            emoji: '⏱️',
            value: _formatDuration(state.elapsedTime),
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
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
          style: MiqraTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: MiqraColors.textPrimary,
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

        return MiqraAnimations.scaleIn(
          child: Container(
            margin: MiqraSpacing.screenPadding,
            padding: MiqraSpacing.cardPadding,
            decoration: BoxDecoration(
              color: reachedTarget
                  ? Colors.green.withOpacity(0.1)
                  : MiqraColors.primarySubtle,
              borderRadius: MiqraSpacing.radiusMedium,
              border: Border.all(
                color: reachedTarget ? Colors.green : MiqraColors.primary,
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
                      style: MiqraTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: reachedTarget ? Colors.green : MiqraColors.textPrimary,
                      ),
                    ),
                    if (reachedTarget)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: MiqraSpacing.radiusSmall,
                        ),
                        child: Text(
                          '+${stats.totalAyat - dailyTarget}',
                          style: MiqraTextStyles.label.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Text(
                        '$remaining tersisa',
                        style: MiqraTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: MiqraColors.textPrimary,
                        ),
                      ),
                  ],
                ),
                MiqraSpacing.gapXS,
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: MiqraColors.bgTertiary,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    reachedTarget ? Colors.green : MiqraColors.primary,
                  ),
                  minHeight: 8,
                  borderRadius: MiqraSpacing.radiusSmall,
                ),
                MiqraSpacing.gapXS,
                Text(
                  '${stats.totalAyat} / $dailyTarget ayat',
                  style: MiqraTextStyles.label.copyWith(
                    color: MiqraColors.textSecondary,
                  ),
                ),
              ],
            ),
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

  int _calculateRealHasanat(WidgetRef ref) {
    // Get the actual verse text
    final ayahAsync = ref.watch(focusAyahProvider((surah: state.surahNumber, ayah: state.ayahNumber)));

    if (!ayahAsync.hasValue) return 550; // fallback

    final verse = ayahAsync.value!;
    // Remove whitespace and diacritics, count Arabic letters
    final arabicText = verse.textAr.replaceAll(RegExp(r'\s+'), '');
    final letterCount = arabicText.length;

    // Each letter = 10 hasanat
    return letterCount * 10;
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

    final realHasanat = _calculateRealHasanat(ref);
    final canGoNext = !state.isLogging;

    return Container(
      padding: MiqraSpacing.cardPadding,
      decoration: BoxDecoration(
        color: reachedTarget
            ? Colors.green.withOpacity(0.05)
            : MiqraColors.bgPrimary,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reachedTarget) ...[
                Text(
                  'Target harian tercapai 🎉',
                  style: MiqraTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stats.totalAyat} ayat dibaca hari ini',
                  style: MiqraTextStyles.label.copyWith(
                    color: MiqraColors.textSecondary,
                  ),
                ),
              ] else ...[
                Text(
                  'Target hari ini: ${stats.totalAyat}/$dailyTarget ayat',
                  style: MiqraTextStyles.label.copyWith(
                    color: MiqraColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: reachedTarget ? 1.0 : progress.clamp(0.0, 1.0),
                backgroundColor: MiqraColors.bgTertiary,
                valueColor: AlwaysStoppedAnimation<Color>(
                  reachedTarget ? Colors.green : MiqraColors.primary,
                ),
                borderRadius: MiqraSpacing.radiusSmall,
              ),
            ],
          ),
          MiqraSpacing.gapMD,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: state.ayahNumber > 1 ? onPrev : null,
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: MiqraColors.bgSecondary,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MiqraColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text(
                      'Selesai',
                      style: MiqraTextStyles.button.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canGoNext)
                    Text(
                      '+$realHasanat',
                      style: MiqraTextStyles.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: MiqraColors.accent,
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                  IconButton(
                    onPressed: canGoNext ? onNext : null,
                    icon: const Icon(Icons.arrow_forward),
                    style: IconButton.styleFrom(
                      backgroundColor: MiqraColors.bgSecondary,
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
