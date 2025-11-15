import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/quran_providers.dart';
import '../providers/surah_providers.dart';
import '../providers/last_read_providers.dart';
import '../data/models/surah_model.dart';
import '../data/models/surah_meta_model.dart';
import '../data/models/tajwid_model_v2.dart';
import '../data/tajwid/tajwid_rules.dart';
import '../data/last_read_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../utils/quran_font_helper.dart';
import '../../bookmark/presentation/bookmark_save_sheet.dart';
import '../../settings/presentation/reader_settings_sheet.dart';
import '../../reading/presentation/manual_reading_log_sheet.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    this.surahNumber = 1,
    this.initialAyah,
    this.juzNumber,
  });

  final int surahNumber;
  final int? initialAyah;
  final int? juzNumber;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToInitialAyah = false;
  
  // Konstanta untuk posisi header surah (mudah diubah)
  static const double _headerCircleWidth = 40.0;
  static const double _headerAyahFontSize = 10.0;
  static const double _headerAyahLabelFontSize = 7.0;
  static const double _headerSymbolFontSize = 7.5;
  
  // Base offset untuk portrait mode (mudah diubah)
  static const double _headerAyahOffsetXPortrait = -54.0; // Geser nomor ayat horizontal
  static const double _headerAyahOffsetY = 0.0; // Geser nomor ayat vertical
  static const double _headerSymbolOffsetXPortrait = 54.0; // Geser symbol horizontal
  static const double _headerSymbolOffsetY = -1.0; // Geser symbol vertical
  
  // Base screen width untuk scaling (typical phone width)
  static const double _baseScreenWidth = 360.0;
  
  // Helper method untuk responsive offset X (ayah)
  static double _getAyahOffsetX(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (orientation == Orientation.landscape) {
      // Scale berdasarkan lebar layar (adjust ratio sesuai kebutuhan)
      return _headerAyahOffsetXPortrait * (screenWidth / _baseScreenWidth);
    }
    return _headerAyahOffsetXPortrait;
  }
  
  // Helper method untuk responsive offset X (symbol)
  static double _getSymbolOffsetX(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (orientation == Orientation.landscape) {
      // Scale berdasarkan lebar layar (mirror dari ayah offset)
      return _headerSymbolOffsetXPortrait * (screenWidth / _baseScreenWidth);
    }
    return _headerSymbolOffsetXPortrait;
  }
  
  // Helper method untuk responsive font size
  static double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final orientation = MediaQuery.of(context).orientation;
    
    if (orientation == Orientation.landscape) {
      // Font size bisa sedikit lebih kecil di landscape
      return baseSize * 0.95;
    }
    return baseSize;
  }

  // Helper method untuk konversi angka ke Arabic numerals
  static String _toArabicNumerals(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) => arabicNumerals[int.parse(digit)]).join();
  }

  // Helper method untuk menambahkan nomor ayat di akhir TextSpan
  TextSpan _addAyahNumberToTextSpan(TextSpan textSpan, int ayahNumber) {
    final arabicAyahNumber = _toArabicNumerals(ayahNumber);
    final open = QuranFontHelper.getAyahOpen1();
    final close = QuranFontHelper.getAyahClose1();
    final ayahNumberSpan = TextSpan(
      text: '$open$arabicAyahNumber$close', // angka Arab dibungkus glyph ayah_open1/ayah_close1
      style: const TextStyle(
        fontFamily: 'QuranCommon',
        fontSize: 20, // ukuran lebih kecil agar nyaman dilihat
        height: 1.5,
        letterSpacing: 0,
        color: Colors.black87,
      ),
    );

    final children = <InlineSpan>[];
    if (textSpan.text != null) {
      children.add(TextSpan(text: textSpan.text, style: textSpan.style));
    }
    if (textSpan.children != null) {
      children.addAll(textSpan.children!);
    }
    // Jarak spasi sebelum marker - seimbang: tidak mepet dengan symbol, tidak terlalu jauh dari huruf
    children.add(const TextSpan(text: '   ')); // 3 spasi untuk jarak yang seimbang
    children.add(ayahNumberSpan);
    return TextSpan(children: children);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToAyah(int ayahIndex) {
    if (_hasScrolledToInitialAyah) return;
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (_hasScrolledToInitialAyah) return;

      final itemHeight = 150.0;
      final targetOffset = ayahIndex * itemHeight;
      
      if (targetOffset <= _scrollController.position.maxScrollExtent) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _hasScrolledToInitialAyah = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showTranslation = ref.watch(translationVisibleProvider);
    final tajwidEnabled = ref.watch(tajwidEnabledProvider);
    
    // Juz mode
    if (widget.juzNumber != null) {
      return _buildJuzMode(context, ref, showTranslation, tajwidEnabled);
    }
    
    // Normal surah mode
    final asyncSurah = ref.watch(surahProvider(widget.surahNumber));
    final surahMeta = ref.watch(surahMetaProvider(widget.surahNumber));
    
    final lastRead = ref.watch(lastReadOnceProvider);
    final targetAyah = widget.initialAyah ?? 
        (lastRead != null && lastRead.surah == widget.surahNumber ? lastRead.ayah : null);
    
    if (targetAyah != null && !_hasScrolledToInitialAyah) {
      final ayahIndex = targetAyah - 1;
      if (asyncSurah.hasValue) {
        _scrollToAyah(ayahIndex);
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          actions: [
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
            IconButton(
              onPressed: () => ref.read(tajwidEnabledProvider.notifier).state = !tajwidEnabled,
              icon: Icon(tajwidEnabled ? Icons.color_lens : Icons.color_lens_outlined),
              tooltip: 'Tajwid',
            ),
            IconButton(
              onPressed: () => ref.read(translationVisibleProvider.notifier).state = !showTranslation,
              icon: const Icon(Icons.translate),
              tooltip: 'Toggle translation',
            ),
            // Manual reading log button (only in surah mode, not juz mode)
            if (widget.juzNumber == null)
              IconButton(
                icon: const Icon(Icons.checklist),
                tooltip: 'Catat bacaan',
                onPressed: () {
                  final surah = asyncSurah.valueOrNull;
                  if (surah == null) return;
                  
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: ManualReadingLogSheet(
                        surahNumber: widget.surahNumber,
                        maxAyat: surah.verses.length,
                      ),
                    ),
                  );
                },
              ),
            // Sign Out button (sementara - nanti akan dipindah ke profile)
            IconButton(
              onPressed: () async {
                try {
                  final auth = ref.read(authRepositoryProvider);
                  await auth.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sign out gagal: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
            ),
          ],
        ),
        body: asyncSurah.when(
          data: (surah) => _content(context, ref, surah, surahMeta, showTranslation, tajwidEnabled),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, stackTrace) => Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Failed to load: $e', textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('$stackTrace', style: const TextStyle(fontSize: 10), textAlign: TextAlign.left),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJuzMode(BuildContext context, WidgetRef ref, bool showTrans, bool tajwidEnabled) {
    final juzSegmentsAsync = ref.watch(juzSegmentsProvider(widget.juzNumber!));
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Juz ${widget.juzNumber}'),
          actions: [
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
            IconButton(
              onPressed: () => ref.read(tajwidEnabledProvider.notifier).state = !tajwidEnabled,
              icon: Icon(tajwidEnabled ? Icons.color_lens : Icons.color_lens_outlined),
              tooltip: 'Tajwid',
            ),
            IconButton(
              onPressed: () => ref.read(translationVisibleProvider.notifier).state = !showTrans,
              icon: const Icon(Icons.translate),
              tooltip: 'Toggle translation',
            ),
          ],
        ),
        body: juzSegmentsAsync.when(
          data: (segments) => _JuzReaderContent(
            segments: segments,
            showTrans: showTrans,
            tajwidEnabled: tajwidEnabled,
            onLongPress: (verse, surahNumber) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: BookmarkSaveSheet(
                    verse: verse,
                    surahNumber: surahNumber,
                  ),
                ),
              );
            },
            onTap: (surahNumber, ayah) {
              LastReadService.saveLastRead(surahNumber, ayah, 'juz');
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, stackTrace) => Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Failed to load juz: $e', textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, SurahData surah, SurahMeta? surahMeta, bool showTrans, bool tajwidEnabled) {
    final asyncTajwid = ref.watch(tajwidSurahProvider(widget.surahNumber));
    
    return asyncTajwid.when(
      data: (tajwidSurah) {
        final showBismillah = QuranFontHelper.shouldShowBismillah(surah.surahNumber);
        final showHeader = QuranFontHelper.shouldShowSurahHeader(surah.surahNumber);
        
        // Calculate item count: header (always if showHeader), bismillah (if showBismillah), verses
        int itemCount = surah.verses.length;
        if (showHeader) itemCount += 1;
        if (showBismillah) itemCount += 1;
        
        return ListView.builder(
        padding: EdgeInsets.zero,
          itemCount: itemCount,
        cacheExtent: 500,
        itemBuilder: (context, i) {
            int currentIndex = i;
            
            // Item pertama: Surah header (selalu muncul jika showHeader)
            if (showHeader && currentIndex == 0) {
              return SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.only(top: 4, bottom: 0),
                  color: Colors.white,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background header pattern
                      FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            QuranFontHelper.getSurahHeader(),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'QuranCommon',
                              fontFamilyFallback: const ['IndopakNastaleeq'],
                              fontSize: 100,
                              height: 1.5,
                              color: const Color(0xFFE56115),
                            ),
                          ),
                        ),
                      ),
                      // Content overlay
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Kiri: Jumlah ayat (di tengah lingkaran kiri)
                            SizedBox(
                              width: _headerCircleWidth,
                              child: Transform.translate(
                                offset: Offset(_getAyahOffsetX(context), _headerAyahOffsetY),
                                child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${surahMeta?.ayahCount ?? surah.verses.length}',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: _getResponsiveFontSize(context, _headerAyahFontSize),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        height: 1.0,
                                      ),
                                    ),
                                    Transform.translate(
                                      offset: const Offset(0, 0),
                                      child: Text(
                                        'Ayat',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: _getResponsiveFontSize(context, _headerAyahLabelFontSize),
                                          color: Colors.black,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ),
                              ),
                            ),
                            // Tengah: Nama surah + arti
                            Expanded(
                              child: Transform.translate(
                                offset: const Offset(0, -2),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      surahMeta?.nameLatin ?? surah.nameLatin,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: Colors.black,
                                        height: 1.5,
                                      ),
                                    ),
                                    if (surahMeta?.nameTranslationId != null && surahMeta!.nameTranslationId.isNotEmpty)
                                      Transform.translate(
                                        offset: const Offset(0, -2),
                                        child: Text(
                                          '(${surahMeta.nameTranslationId})',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: Colors.black,
                                            height: 1.0,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Kanan: Simbol Makkah/Madinah (di tengah lingkaran kanan)
                            SizedBox(
                              width: _headerCircleWidth,
                              child: Transform.translate(
                                offset: Offset(_getSymbolOffsetX(context), _headerSymbolOffsetY),
                                child: Center(
                                  child: Text(
                                    (surahMeta?.type == 'Makkiyah' || surahMeta == null)
                                        ? QuranFontHelper.getMakkahSymbol()
                                        : QuranFontHelper.getMadinahSymbol(),
                                    style: TextStyle(
                                      fontFamily: 'QuranCommon',
                                      fontFamilyFallback: const ['IndopakNastaleeq'],
                                      fontSize: _getResponsiveFontSize(context, _headerSymbolFontSize),
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Item kedua: Bismillah (hanya jika showBismillah)
            if (showBismillah && currentIndex == 1) {
              return Transform.translate(
                offset: const Offset(0, -8),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(top: 0, bottom: 4),
                  child: Text(
                    QuranFontHelper.getBismillah(),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'QuranCommon',
                      fontFamilyFallback: const ['IndopakNastaleeq'],
                      fontSize: 34,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
              );
            }
            
            // Adjust index untuk verses
            // Jika ada header dan bismillah: index 0=header, 1=bismillah, 2+=verses
            // Jika ada header saja: index 0=header, 1+=verses
            // Jika ada bismillah saja: index 0=bismillah, 1+=verses (tidak terjadi karena header selalu true)
            int verseIndex;
            if (showHeader && showBismillah) {
              verseIndex = currentIndex - 2; // Skip header and bismillah
            } else if (showHeader) {
              verseIndex = currentIndex - 1; // Skip header only
            } else {
              verseIndex = currentIndex; // No skip (shouldn't happen)
            }
            
            // Pastikan verseIndex valid
            if (verseIndex < 0 || verseIndex >= surah.verses.length) {
              return const SizedBox.shrink();
            }
            
            final v = surah.verses[verseIndex];
          final spans = tajwidEnabled 
              ? tajwidSurah.getSpansForAyah(v.ayah)
              : <TajwidSpan>[];
          // Selang-seling warna background
            final isEven = verseIndex % 2 == 0;
          return RepaintBoundary(
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
                      verse: v,
                      surahNumber: surah.surahNumber,
                    ),
                  ),
                );
              },
              child: InkWell(
                onTap: () {
                  LastReadService.saveLastRead(surah.surahNumber, v.ayah, 'surah');
                },
            child: Container(
              color: isEven ? Colors.transparent : Colors.grey[50],
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arabic text (lebih masuk ke pinggir kanan)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 0),
                          child: RichText(
                            textAlign: TextAlign.right,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            text: _addAyahNumberToTextSpan(
                              _buildTajwidTextSpanSafe(v.textAr, spans, tajwidEnabled),
                              v.ayah,
                          ),
                        ),
                      ),
                      ),
                      SizedBox(width: 6),
                      // Ayah number badge dengan logo (sejajar dengan text latin)
                      Container(
                        margin: const EdgeInsets.only(left: 0, top: 0),
                        width: 28,
                        height: 28,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/data/image/logoayat.svg',
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                            ),
                            Text(
                              '${v.ayah}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (v.textTranslit != null)
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, left: 24, right: 8),
                        child: Text(
                          v.textTranslit!,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            height: 1.3,
                            color: const Color(0xFF4E1F0A),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  if (showTrans)
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, left: 24, right: 8),
                        child: Text(
                          v.textId,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            height: 1.4,
                              color: Color(0xFF2E3A46),
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
        },
      );
      },
      loading: () => ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: surah.verses.length,
        itemBuilder: (context, i) {
          final v = surah.verses[i];
          // Selang-seling warna background
          final isEven = i % 2 == 0;
          return Container(
            color: isEven ? Colors.transparent : Colors.grey[50],
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Arabic text (lebih masuk ke pinggir kanan)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: RichText(
                          textAlign: TextAlign.right,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          text: _addAyahNumberToTextSpan(
                            _buildTajwidTextSpanSafe(v.textAr, <TajwidSpan>[], tajwidEnabled),
                            v.ayah,
                        ),
                      ),
                    ),
                    ),
                    SizedBox(width: 6),
                    // Ayah number badge dengan logo (sejajar dengan text latin)
                    Container(
                      margin: const EdgeInsets.only(left: 0, top: 4),
                      width: 28,
                      height: 28,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/data/image/logoayat.svg',
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                          Text(
                            '${v.ayah}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      error: (e, _) => ListView.builder(
        // Fail softly: render without tajwid if file missing
        padding: EdgeInsets.zero,
        itemCount: surah.verses.length,
        itemBuilder: (context, i) {
          final v = surah.verses[i];
          // Selang-seling warna background
          final isEven = i % 2 == 0;
          return Container(
            color: isEven ? Colors.transparent : Colors.grey[50],
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Arabic text (lebih masuk ke pinggir kanan)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: RichText(
                          textAlign: TextAlign.right,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          text: _addAyahNumberToTextSpan(
                            _buildTajwidTextSpanSafe(v.textAr, <TajwidSpan>[], tajwidEnabled),
                            v.ayah,
                        ),
                      ),
                    ),
                    ),
                    SizedBox(width: 6),
                    // Ayah number badge dengan logo (sejajar dengan text latin)
                    Container(
                      margin: const EdgeInsets.only(left: 0, top: 4),
                      width: 28,
                      height: 28,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/data/image/logoayat.svg',
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                          Text(
                            '${v.ayah}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  TextSpan _buildTajwidTextSpan(String textAr, List<TajwidSpan> spans, bool enabled) {
    const baseStyle = TextStyle(
      fontFamily: 'IndopakNastaleeq',
      fontSize: 30,
      height: 1.5,
      letterSpacing: 0,
      color: Colors.black87,
    );

    if (!enabled || spans.isEmpty) {
      return TextSpan(text: textAr, style: baseStyle);
    }

    // Sort spans by start position
    final sorted = [...spans]..sort((a, b) => a.start.compareTo(b.start));
    
    final textSpans = <TextSpan>[];
    int lastPos = 0;
    final buffer = StringBuffer();
    
    for (final span in sorted) {
      final start = span.start.clamp(0, textAr.length);
      final end = span.end.clamp(0, textAr.length);
      
      if (end <= start) continue;
      
      // Handle overlap: only process the part that hasn't been processed yet
      final actualStart = start > lastPos ? start : lastPos;
      if (actualStart >= end) continue; // Skip if fully overlapped
      
      // Add text before span (if any)
      if (actualStart > lastPos) {
        final beforeText = textAr.substring(lastPos, actualStart);
        buffer.write(beforeText);
        textSpans.add(TextSpan(text: beforeText, style: baseStyle));
      }
      
      // Add colored span text (only the non-overlapped part)
      final spanText = textAr.substring(actualStart, end);
      buffer.write(spanText);
      final color = tajwidPalette[span.rule] ?? Colors.red;
      textSpans.add(TextSpan(
        text: spanText,
        style: baseStyle.copyWith(color: color),
      ));
      
      lastPos = end;
    }
    
    // Add remaining text
    if (lastPos < textAr.length) {
      final remainingText = textAr.substring(lastPos);
      buffer.write(remainingText);
      textSpans.add(TextSpan(text: remainingText, style: baseStyle));
    }
    
    // Assert: joined text equals original
    assert(buffer.toString() == textAr, 
        'TextSpan concatenation mismatch: expected "${textAr}", got "${buffer.toString()}"');
    
    return TextSpan(children: textSpans);
  }

  /// Safe wrapper for _buildTajwidTextSpan with error handling.
  /// Falls back to plain text if tajwid rendering fails.
  TextSpan _buildTajwidTextSpanSafe(String textAr, List<TajwidSpan> spans, bool enabled) {
    try {
      return _buildTajwidTextSpan(textAr, spans, enabled);
    } catch (e) {
      // Fallback to plain text on error
      return TextSpan(
        text: textAr,
        style: const TextStyle(
          fontFamily: 'IndopakNastaleeq',
          fontSize: 34,
          height: 1.5,
          letterSpacing: 0,
          color: Colors.black87,
        ),
      );
    }
  }

}

class _JuzReaderContent extends ConsumerWidget {
  final List<JuzSurahSegment> segments;
  final bool showTrans;
  final bool tajwidEnabled;
  final void Function(Verse verse, int surahNumber) onLongPress;
  final void Function(int surahNumber, int ayah) onTap;

  const _JuzReaderContent({
    required this.segments,
    required this.showTrans,
    required this.tajwidEnabled,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Calculate total item count
    int totalItems = 0;
    final segmentData = <_SegmentData>[];
    
    for (final segment in segments) {
      final surahAsync = ref.watch(surahProvider(segment.surahNumber));
      final tajwidAsync = ref.watch(tajwidSurahProvider(segment.surahNumber));
      
      final showBismillah = QuranFontHelper.shouldShowBismillah(segment.surahNumber);
      
      final itemCount = surahAsync.when(
        data: (surah) {
          final verseCount = segment.endAyah - segment.startAyah + 1;
          return 1 + (showBismillah ? 1 : 0) + verseCount;
        },
        loading: () => 0,
        error: (_, __) => 0,
      );
      
      segmentData.add(_SegmentData(
        segment: segment,
        surahAsync: surahAsync,
        tajwidAsync: tajwidAsync,
        showBismillah: showBismillah,
        itemCount: itemCount,
        startIndex: totalItems,
      ));
      
      totalItems += itemCount;
    }
    
    // Check if all data is loaded
    final allLoaded = segmentData.every((data) => data.surahAsync.hasValue);
    
    if (!allLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: totalItems,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        // Find which segment this index belongs to
        for (final data in segmentData) {
          if (index >= data.startIndex && index < data.startIndex + data.itemCount) {
            final localIndex = index - data.startIndex;
            
            // Item 0: Surah header
            if (localIndex == 0) {
              return data.surahAsync.when(
                data: (_) => _buildSurahHeader(context, data.segment.surahMeta),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            }
            
            // Item 1: Bismillah (if needed)
            if (data.showBismillah && localIndex == 1) {
              return _buildBismillah();
            }
            
            // Items 2+: Verses
            final verseIndex = data.showBismillah ? localIndex - 2 : localIndex - 1;
            final ayahNumber = data.segment.startAyah + verseIndex;
            
            if (ayahNumber > data.segment.endAyah) {
              return const SizedBox.shrink();
            }
            
            return data.surahAsync.when(
              data: (surah) {
                final verse = surah.verses.firstWhere(
                  (v) => v.ayah == ayahNumber,
                  orElse: () => throw Exception('Ayah $ayahNumber not found'),
                );
                
                return data.tajwidAsync.when(
                  data: (tajwidSurah) {
                    final spans = tajwidEnabled 
                        ? tajwidSurah.getSpansForAyah(ayahNumber)
                        : <TajwidSpan>[];
                    
                    return _buildVerseTile(
                      context,
                      verse,
                      spans,
                      data.segment.surahNumber,
                      showTrans,
                      tajwidEnabled,
                      (index - (data.showBismillah ? 2 : 1)) % 2 == 0,
                      onLongPress,
                      onTap,
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => _buildVerseTile(
                    context,
                    verse,
                    <TajwidSpan>[],
                    data.segment.surahNumber,
                    showTrans,
                    false,
                    (index - (data.showBismillah ? 2 : 1)) % 2 == 0,
                    onLongPress,
                    onTap,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          }
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSurahHeader(BuildContext context, SurahMeta surahMeta) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.only(top: 4, bottom: 0),
        color: Colors.white,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FittedBox(
              fit: BoxFit.fitWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  QuranFontHelper.getSurahHeader(),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'QuranCommon',
                    fontFamilyFallback: const ['IndopakNastaleeq'],
                    fontSize: 100,
                    height: 1.5,
                    color: const Color(0xFFE56115),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    child: Transform.translate(
                      offset: const Offset(0, 0),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${surahMeta.ayahCount}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                height: 1.0,
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, 0),
                              child: const Text(
                                'Ayat',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  color: Colors.black,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Transform.translate(
                      offset: const Offset(0, -2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            surahMeta.nameLatin,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Colors.black,
                              height: 1.5,
                            ),
                          ),
                          if (surahMeta.nameTranslationId.isNotEmpty)
                            Transform.translate(
                              offset: const Offset(0, -2),
                              child: Text(
                                '(${surahMeta.nameTranslationId})',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Colors.black,
                                  height: 1.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Transform.translate(
                      offset: const Offset(0, 0),
                      child: Center(
                        child: Text(
                          (surahMeta.type == 'Makkiyah')
                              ? QuranFontHelper.getMakkahSymbol()
                              : QuranFontHelper.getMadinahSymbol(),
                          style: const TextStyle(
                            fontFamily: 'QuranCommon',
                            fontFamilyFallback: ['IndopakNastaleeq'],
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBismillah() {
    return Transform.translate(
      offset: const Offset(0, -8),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(top: 0, bottom: 4),
        child: Text(
          QuranFontHelper.getBismillah(),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'QuranCommon',
            fontFamilyFallback: const ['IndopakNastaleeq'],
            fontSize: 34,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildVerseTile(
    BuildContext context,
    Verse verse,
    List<TajwidSpan> spans,
    int surahNumber,
    bool showTrans,
    bool tajwidEnabled,
    bool isEven,
    void Function(Verse, int) onLongPress,
    void Function(int, int) onTap,
  ) {
    return RepaintBoundary(
      child: GestureDetector(
        onLongPress: () => onLongPress(verse, surahNumber),
        child: InkWell(
          onTap: () => onTap(surahNumber, verse.ayah),
          child: Container(
            color: isEven ? Colors.transparent : Colors.grey[50],
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: RichText(
                          textAlign: TextAlign.right,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          text: _addAyahNumberToTextSpan(
                            _buildTajwidTextSpanSafe(verse.textAr, spans, tajwidEnabled),
                            verse.ayah,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      margin: const EdgeInsets.only(left: 0, top: 0),
                      width: 28,
                      height: 28,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/data/image/logoayat.svg',
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                          Text(
                            '${verse.ayah}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (verse.textTranslit != null)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, left: 24, right: 8),
                      child: Text(
                        verse.textTranslit!,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          height: 1.3,
                          color: const Color(0xFF4E1F0A),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                if (showTrans)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, left: 24, right: 8),
                      child: Text(
                        verse.textId,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          height: 1.4,
                          color: Color(0xFF2E3A46),
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

  TextSpan _buildTajwidTextSpanSafe(String textAr, List<TajwidSpan> spans, bool enabled) {
    try {
      return _buildTajwidTextSpan(textAr, spans, enabled);
    } catch (e) {
      return TextSpan(
        text: textAr,
        style: const TextStyle(
          fontFamily: 'IndopakNastaleeq',
          fontSize: 34,
          height: 1.5,
          letterSpacing: 0,
          color: Colors.black87,
        ),
      );
    }
  }

  TextSpan _buildTajwidTextSpan(String textAr, List<TajwidSpan> spans, bool enabled) {
    const baseStyle = TextStyle(
      fontFamily: 'IndopakNastaleeq',
      fontSize: 30,
      height: 1.5,
      letterSpacing: 0,
      color: Colors.black87,
    );

    if (!enabled || spans.isEmpty) {
      return TextSpan(text: textAr, style: baseStyle);
    }

    final sorted = [...spans]..sort((a, b) => a.start.compareTo(b.start));
    final textSpans = <TextSpan>[];
    int lastPos = 0;

    for (final span in sorted) {
      final start = span.start.clamp(0, textAr.length);
      final end = span.end.clamp(0, textAr.length);
      if (end <= start) continue;
      final actualStart = start > lastPos ? start : lastPos;
      if (actualStart >= end) continue;

      if (actualStart > lastPos) {
        final beforeText = textAr.substring(lastPos, actualStart);
        textSpans.add(TextSpan(text: beforeText, style: baseStyle));
      }

      final spanText = textAr.substring(actualStart, end);
      final color = tajwidPalette[span.rule] ?? Colors.red;
      textSpans.add(TextSpan(
        text: spanText,
        style: baseStyle.copyWith(color: color),
      ));

      lastPos = end;
    }

    if (lastPos < textAr.length) {
      final remainingText = textAr.substring(lastPos);
      textSpans.add(TextSpan(text: remainingText, style: baseStyle));
    }

    return TextSpan(children: textSpans);
  }

  TextSpan _addAyahNumberToTextSpan(TextSpan textSpan, int ayahNumber) {
    final arabicAyahNumber = _toArabicNumerals(ayahNumber);
    final open = QuranFontHelper.getAyahOpen1();
    final close = QuranFontHelper.getAyahClose1();
    final ayahNumberSpan = TextSpan(
      text: '$open$arabicAyahNumber$close',
      style: const TextStyle(
        fontFamily: 'QuranCommon',
        fontSize: 20,
        height: 1.5,
        letterSpacing: 0,
        color: Colors.black87,
      ),
    );

    final children = <InlineSpan>[];
    if (textSpan.text != null) {
      children.add(TextSpan(text: textSpan.text, style: textSpan.style));
    }
    if (textSpan.children != null) {
      children.addAll(textSpan.children!);
    }
    children.add(const TextSpan(text: '   '));
    children.add(ayahNumberSpan);
    return TextSpan(children: children);
  }

  String _toArabicNumerals(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) => arabicDigits[int.parse(digit)]).join();
  }
}

class _SegmentData {
  final JuzSurahSegment segment;
  final AsyncValue<SurahData> surahAsync;
  final AsyncValue<TajwidSurah> tajwidAsync;
  final bool showBismillah;
  final int itemCount;
  final int startIndex;

  _SegmentData({
    required this.segment,
    required this.surahAsync,
    required this.tajwidAsync,
    required this.showBismillah,
    required this.itemCount,
    required this.startIndex,
  });
}




