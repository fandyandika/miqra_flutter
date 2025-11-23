import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/utils/animations.dart';
import '../../../../shared/widgets/miqra_components.dart';
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
              loading: () => const MiqraLoading(),
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
      padding: MiqraSpacing.screenPadding,
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
      padding: MiqraSpacing.listPadding,
      itemCount: filtered.length,
      separatorBuilder: (context, index) => MiqraSpacing.gapXS,
      itemBuilder: (context, index) {
        return MiqraAnimations.staggeredItem(
          index: index,
          child: _SurahTile(item: filtered[index]),
        );
      },
    );
  }
}

class _SurahTile extends StatelessWidget {
  final SurahMeta item;

  const _SurahTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final surahNameLigature = QuranFontHelper.getSurahNameLigature(item.number);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: miqraSand,
        borderRadius: MiqraSpacing.radiusSmall,
        border: Border.all(
          color: MiqraColors.borderLight,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: MiqraSpacing.radiusSmall,
          onTap: () {
            context.go('/read/surah/${item.number}');
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo ayat di tengah vertikal
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 6),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/data/image/logoayat.svg',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                      Text(
                        '${item.number}',
                        style: MiqraTextStyles.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.nameLatin,
                        style: MiqraTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (item.nameTranslationId.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${item.nameTranslationId} | ${item.ayahCount} Ayat',
                          style: MiqraTextStyles.caption.copyWith(
                            color: MiqraColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ] else ...[
                        const SizedBox(height: 3),
                        Text(
                          '${item.ayahCount} Ayat',
                          style: MiqraTextStyles.caption.copyWith(
                            color: MiqraColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
                // Download button dengan SVG
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      // TODO: Implement download audio functionality
                      // Audio path: assets/data/audio/mishari_rashid/
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 7, top: 7, bottom: 7, right: 0),
                             child: SvgPicture.asset(
                               'assets/icons/download.svg',
                               width: 18,
                               height: 18,
                               colorFilter: ColorFilter.mode(
                                 MiqraColors.textSecondary,
                                 BlendMode.srcIn,
                               ),
                             ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

