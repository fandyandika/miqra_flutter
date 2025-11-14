import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/quran_providers.dart';
import '../data/models/surah_model.dart';
import '../data/models/tajwid_model_v2.dart';
import '../data/tajwid/tajwid_rules.dart';
import '../../auth/providers/auth_providers.dart';
import '../utils/quran_font_helper.dart';

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key});
  
  // Konstanta untuk posisi header surah (mudah diubah)
  static const double _headerCircleWidth = 40.0;
  static const double _headerAyahFontSize = 10.0;
  static const double _headerAyahLabelFontSize = 10.0;
  static const double _headerSymbolFontSize = 8.5;
  
  // Base offset untuk portrait mode (mudah diubah)
  static const double _headerAyahOffsetXPortrait = -54.0; // Geser nomor ayat horizontal
  static const double _headerAyahOffsetY = 0.0; // Geser nomor ayat vertical
  static const double _headerSymbolOffsetXPortrait = 54.0; // Geser symbol horizontal
  static const double _headerSymbolOffsetY = -3.0; // Geser symbol vertical
  
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Load surah 2 (Al-Baqarah) for testing tajwid
    final asyncSurah = ref.watch(surahProvider(2));
    final showTranslation = ref.watch(translationVisibleProvider);
    final tajwidEnabled = ref.watch(tajwidEnabledProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          actions: [
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
          data: (surah) => _content(context, ref, surah, showTranslation, tajwidEnabled),
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

  Widget _content(BuildContext context, WidgetRef ref, SurahData surah, bool showTrans, bool tajwidEnabled) {
    final asyncTajwid = ref.watch(tajwidSurahProvider(surah.surahNumber));
    
    return asyncTajwid.when(
      data: (tajwidSurah) => ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: surah.verses.length + (QuranFontHelper.shouldShowBismillah(surah.surahNumber) ? 1 : 0),
        cacheExtent: 500,
        itemBuilder: (context, i) {
          // Tampilkan bismillah sebagai item pertama
          if (QuranFontHelper.shouldShowBismillah(surah.surahNumber) && i == 0) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
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
                                        '${surah.verses.length}',
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
                                  offset: const Offset(0, 0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        surah.nameLatin,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          color: Colors.black,
                                          height: 1.5,
                                        ),
                                      ),
                                      if (QuranFontHelper.getSurahTranslation(surah.surahNumber).isNotEmpty)
                                        Transform.translate(
                                          offset: const Offset(0, -2),
                                          child: Text(
                                            '(${QuranFontHelper.getSurahTranslation(surah.surahNumber)})',
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
                                      QuranFontHelper.getSurahType(surah.surahNumber) == 'makkah'
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
                ),
                Transform.translate(
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
                ),
              ],
            );
          }
          
          // Adjust index untuk verses jika ada bismillah
          final verseIndex = QuranFontHelper.shouldShowBismillah(surah.surahNumber) ? i - 1 : i;
          final v = surah.verses[verseIndex];
          final spans = tajwidEnabled 
              ? tajwidSurah.getSpansForAyah(v.ayah)
              : <TajwidSpan>[];
          // Selang-seling warna background
          final isEven = verseIndex % 2 == 0;
          return RepaintBoundary(
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
          );
        },
      ),
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




