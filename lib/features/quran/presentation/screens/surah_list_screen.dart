import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../providers/surah_providers.dart';
import '../../data/models/surah_meta_model.dart';
import '../../utils/quran_font_helper.dart';

class SurahListScreen extends ConsumerWidget {
  const SurahListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahListAsync = ref.watch(surahMetaListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Surah'),
      ),
      body: Column(
        children: [
          const _SearchBar(),
          Expanded(
            child: surahListAsync.when(
              data: (surahs) => _SurahListView(surahs: surahs),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      ref.read(surahSearchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Cari surah (latin/arab)…',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }
}

class _SurahListView extends ConsumerWidget {
  final List<SurahMeta> surahs;

  const _SurahListView({required this.surahs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredSurahListProvider);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _SurahTile(item: filtered[index]);
      },
    );
  }
}

class _SurahTile extends StatelessWidget {
  final SurahMeta item;

  const _SurahTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isMakkiyah = item.type == 'Makkiyah';
    final badgeColor = isMakkiyah ? miqraPrimary : miqraCoral;
    final surahNameLigature = QuranFontHelper.getSurahNameLigature(item.number);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: miqraPrimary.withOpacity(0.1),
        child: Text(
          '${item.number}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: miqraPrimary,
          ),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              item.nameLatin,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            surahNameLigature.isNotEmpty 
                ? surahNameLigature 
                : 'surah${item.number.toString().padLeft(3, '0')}',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: 'SurahName',
              fontSize: 36,
              height: 1.2,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor, width: 1),
                ),
                child: Text(
                  item.type,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.ayahCount} ayat',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          if (item.nameTranslationId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.nameTranslationId,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        context.go('/read/surah/${item.number}');
      },
    );
  }
}

