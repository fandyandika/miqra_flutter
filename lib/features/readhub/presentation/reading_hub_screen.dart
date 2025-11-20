import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../quran/providers/last_read_providers.dart';
import '../../quran/providers/surah_providers.dart';
import '../../reading/providers/reading_providers.dart';
import '../../reading/presentation/manual_reading_log_sheet.dart';

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
        padding: const EdgeInsets.all(16),
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
            if (lastReadAsync.valueOrNull != null) const SizedBox(height: 16),

            // Action Buttons
            ElevatedButton(
              onPressed: () => context.go('/read/surah'),
              style: ElevatedButton.styleFrom(
                backgroundColor: miqraPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Baca Qur\'an',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/read/focus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: miqraCoral,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Baca Fokus',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
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
              label: const Text(
                'Catat Manual',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: miqraGold, width: 2),
                foregroundColor: miqraGold,
              ),
            ),
            const SizedBox(height: 24),

            // Mini Stats Cards
            Row(
              children: [
                Expanded(
                  child: _MiniStatsCard(
                    label: 'Hasanat Harian',
                    value: statsAsync.when(
                      data: (stats) => '${stats.totalHasanat}',
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    icon: Icons.stars,
                    color: miqraGold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStatsCard(
                    label: 'Total Ayat Dibaca',
                    value: statsAsync.when(
                      data: (stats) => '${stats.totalAyat}',
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    icon: Icons.book,
                    color: miqraPrimary,
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

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showReadingOptions(context, lastRead),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: miqraPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history, color: miqraPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terakhir Dibaca',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'QS. $surahName - ${lastRead.ayah}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: miqraText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatsCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
