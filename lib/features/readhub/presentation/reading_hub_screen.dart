import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../quran/providers/last_read_providers.dart';
import '../../quran/providers/surah_providers.dart';
import '../../reading/providers/reading_providers.dart';
import '../../settings/providers/reader_settings_providers.dart';

class ReadingHubScreen extends ConsumerWidget {
  const ReadingHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastReadAsync = ref.watch(lastReadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baca Qur\'an'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LastReadCard(lastReadAsync: lastReadAsync),
            const SizedBox(height: 16),
            _StatsCard(),
            const SizedBox(height: 16),
            _ModeButtons(),
          ],
        ),
      ),
    );
  }
}

class _LastReadCard extends ConsumerWidget {
  final AsyncValue<dynamic> lastReadAsync;

  const _LastReadCard({required this.lastReadAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terakhir Dibaca',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: miqraText,
              ),
            ),
            const SizedBox(height: 12),
            lastReadAsync.when(
              data: (lastRead) {
                if (lastRead == null) {
                  return const Text(
                    'Belum ada bacaan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }

                final surahMeta = ref.watch(surahMetaProvider(lastRead.surah));
                final surahName = surahMeta?.nameLatin ?? 'Surah ${lastRead.surah}';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$surahName ayat ${lastRead.ayah}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: miqraText,
                            ),
                          ),
                        ),
                        if (lastRead.mode == 'focus')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: miqraCoral.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Mode: Fokus',
                              style: TextStyle(
                                fontSize: 12,
                                color: miqraCoral,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (lastRead.mode == 'focus') {
                            context.go('/read/focus?surah=${lastRead.surah}&ayah=${lastRead.ayah}');
                          } else {
                            context.go('/read/surah/${lastRead.surah}?ayat=${lastRead.ayah}');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: miqraPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Lanjutkan'),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text(
                'Belum ada bacaan',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(todayReadingStatsProvider);
    final settingsAsync = ref.watch(readerSettingsProvider);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistik',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: miqraText,
              ),
            ),
            const SizedBox(height: 12),
            statsAsync.when(
              data: (stats) {
                final settings = settingsAsync.valueOrNull;
                final dailyTarget = settings?.dailyTargetAyat ?? 5;
                final targetProgress = dailyTarget > 0
                    ? (stats.totalAyat / dailyTarget).clamp(0.0, 1.0)
                    : 0.0;
                
                return Column(
                  children: [
                    _StatItem(label: 'Hasanat Hari Ini', value: '${stats.totalHasanat}'),
                    const SizedBox(height: 8),
                    _StatItem(label: 'Streak', value: '0 hari'),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Target Hari Ini',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            Text(
                              '${stats.totalAyat}/$dailyTarget ayat',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: miqraText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: targetProgress,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(miqraPrimary),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Column(
                children: [
                  _StatItem(label: 'Hasanat Hari Ini', value: '0'),
                  const SizedBox(height: 8),
                  _StatItem(label: 'Streak', value: '0 hari'),
                  const SizedBox(height: 8),
                  _StatItem(label: 'Target Hari Ini', value: '0/5 ayat'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
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

class _ModeButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModeButton(
          icon: '📚',
          label: 'Baca per Surah',
          color: miqraPrimary,
          onTap: () => context.go('/read/surah'),
        ),
        const SizedBox(height: 12),
        _ModeButton(
          icon: '🎯',
          label: 'Baca per Ayat (Fokus)',
          color: miqraCoral,
          onTap: () => context.go('/read/focus'),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color),
          ],
        ),
      ),
    );
  }
}

