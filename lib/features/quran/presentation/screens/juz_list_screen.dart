import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/surah_providers.dart';
import '../../data/models/surah_meta_model.dart';

class JuzListScreen extends ConsumerWidget {
  const JuzListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahListAsync = ref.watch(surahMetaListProvider);

    return surahListAsync.when(
      data: (surahs) {
        final juzList = _buildJuzList(surahs);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: juzList.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            return _JuzTile(juzItem: juzList[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  List<_JuzItem> _buildJuzList(List<SurahMeta> surahs) {
    final juzMap = <int, List<_JuzSegmentWithSurah>>{};

    for (final surah in surahs) {
      for (final segment in surah.juzSegments) {
        juzMap.putIfAbsent(segment.juz, () => []).add(
          _JuzSegmentWithSurah(
            segment: segment,
            surah: surah,
          ),
        );
      }
    }

    final juzList = <_JuzItem>[];

    for (int juz = 1; juz <= 30; juz++) {
      final segments = juzMap[juz] ?? [];
      if (segments.isEmpty) continue;

      segments.sort((a, b) {
        if (a.surah.number != b.surah.number) {
          return a.surah.number.compareTo(b.surah.number);
        }
        return a.segment.startAyah.compareTo(b.segment.startAyah);
      });

      final first = segments.first;
      final last = segments.last;

      juzList.add(_JuzItem(
        juz: juz,
        startSurah: first.surah.number,
        startSurahName: first.surah.nameLatin,
        startAyah: first.segment.startAyah,
        endSurah: last.surah.number,
        endSurahName: last.surah.nameLatin,
        endAyah: last.segment.endAyah,
      ));
    }

    return juzList;
  }
}

class _JuzSegmentWithSurah {
  final JuzSegment segment;
  final SurahMeta surah;

  _JuzSegmentWithSurah({
    required this.segment,
    required this.surah,
  });
}

class _JuzItem {
  final int juz;
  final int startSurah;
  final String startSurahName;
  final int startAyah;
  final int endSurah;
  final String endSurahName;
  final int endAyah;

  _JuzItem({
    required this.juz,
    required this.startSurah,
    required this.startSurahName,
    required this.startAyah,
    required this.endSurah,
    required this.endSurahName,
    required this.endAyah,
  });
}

class _JuzTile extends StatelessWidget {
  final _JuzItem juzItem;

  const _JuzTile({required this.juzItem});

  @override
  Widget build(BuildContext context) {
    final rangeText = juzItem.startSurah == juzItem.endSurah
        ? '${juzItem.startSurahName} (${juzItem.startAyah} → ${juzItem.endAyah})'
        : '${juzItem.startSurahName} (${juzItem.startAyah}) → ${juzItem.endSurahName} (${juzItem.endAyah})';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: miqraPrimary.withOpacity(0.1),
        child: Text(
          '${juzItem.juz}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: miqraPrimary,
          ),
        ),
      ),
      title: Text(
        'Juz ${juzItem.juz}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(rangeText),
      onTap: () {
        context.go('/read/surah/${juzItem.startSurah}?ayat=${juzItem.startAyah}&juz=${juzItem.juz}');
      },
    );
  }
}

