import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/constants/spacing.dart';
import '../../../shared/widgets/miqra_card.dart';
import '../../quran/providers/last_read_providers.dart';
import '../../quran/providers/surah_providers.dart';
import '../../reading/providers/reading_providers.dart';
import '../../reading/presentation/manual_reading_log_sheet.dart';

/// Reading Hub Screen - Central place for all reading actions.
///
/// Design System:
/// - Uses MiqraCard for all cards
/// - Uses MiqraIconCard for stats
/// - Uses MiqraTextStyles for typography
/// - Uses MiqraSpacing for gaps
/// - Theme handles button styles
class ReadingHubScreen extends ConsumerWidget {
  const ReadingHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastReadAsync = ref.watch(lastReadProvider);
    final statsAsync = ref.watch(todayReadingStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baca Qur\'an'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: MiqraSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Terakhir Dibaca Card
            lastReadAsync.when(
              data: (lastRead) {
                if (lastRead == null) return const SizedBox.shrink();
                return _LastReadCard(lastRead: lastRead);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if (lastReadAsync.valueOrNull != null) MiqraSpacing.gapMD,

            // Action Buttons (theme handles styling)
            ElevatedButton(
              onPressed: () => context.go('/read/surah'),
              child: const Text('Baca Qur\'an'),
            ),
            MiqraSpacing.gapSM,
            ElevatedButton(
              onPressed: () => context.go('/read/focus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MiqraColors.secondary,
              ),
              child: const Text('Baca Fokus'),
            ),
            MiqraSpacing.gapSM,
            OutlinedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: const ManualReadingLogSheet(
                      readingMode: 'manual',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_note),
              label: const Text('Catat Manual'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: MiqraColors.accent, width: 1.5),
                foregroundColor: MiqraColors.accent,
              ),
            ),
            MiqraSpacing.gapLG,

            // Mini Stats Cards (using MiqraIconCard)
            Row(
              children: [
                Expanded(
                  child: MiqraIconCard(
                    icon: Icons.stars,
                    iconColor: MiqraColors.accent,
                    title: 'Hasanat Harian',
                    value: statsAsync.when(
                      data: (stats) => '${stats.totalHasanat}',
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                  ),
                ),
                MiqraSpacing.gapHorizontalSM,
                Expanded(
                  child: MiqraIconCard(
                    icon: Icons.book,
                    iconColor: MiqraColors.primary,
                    title: 'Total Ayat Dibaca',
                    value: statsAsync.when(
                      data: (stats) => '${stats.totalAyat}',
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LastReadCard extends ConsumerWidget {
  final dynamic lastRead;

  const _LastReadCard({required this.lastRead});

  void _showReadingOptions(BuildContext context, dynamic lastRead) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.menu_book, color: miqraPrimary),
              title: const Text('Baca per Surah'),
              onTap: () {
                Navigator.pop(context);
                context.go('/read/surah/${lastRead.surah}?ayat=${lastRead.ayah}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.center_focus_strong, color: miqraCoral),
              title: const Text('Baca per Ayat (Fokus)'),
              onTap: () {
                Navigator.pop(context);
                context.go('/read/focus?surah=${lastRead.surah}&ayah=${lastRead.ayah}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark, color: miqraGold),
              title: const Text('Baca per Juz'),
              onTap: () {
                Navigator.pop(context);
                // Find juz for this surah/ayah
                // For now, navigate to surah browser
                context.go('/read/surah');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahMeta = ref.watch(surahMetaProvider(lastRead.surah));
    final surahName = surahMeta?.nameLatin ?? 'Surah ${lastRead.surah}';

    return MiqraCard(
      onTap: () => _showReadingOptions(context, lastRead),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MiqraColors.primarySubtle,
              borderRadius: MiqraSpacing.radiusSmall,
            ),
            child: Icon(Icons.history, color: MiqraColors.primary),
          ),
          MiqraSpacing.gapHorizontalSM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terakhir Dibaca',
                  style: MiqraTextStyles.label.copyWith(
                    color: MiqraColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'QS. $surahName - ${lastRead.ayah}',
                  style: MiqraTextStyles.headline.copyWith(
                    color: MiqraColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: MiqraColors.textTertiary),
        ],
      ),
    );
  }
}
