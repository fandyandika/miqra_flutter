import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/quran_providers.dart';
import '../data/models/surah_model.dart';
import '../data/models/tajwid_model_v2.dart';
import '../data/tajwid/tajwid_rules.dart';
import '../../auth/providers/auth_providers.dart';

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key});

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
          title: const Text('البقرة', textDirection: TextDirection.rtl),
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
        itemCount: surah.verses.length,
        cacheExtent: 500,
        itemBuilder: (context, i) {
          final v = surah.verses[i];
          final spans = tajwidEnabled 
              ? tajwidSurah.getSpansForAyah(v.ayah)
              : <TajwidSpan>[];
          // Selang-seling warna background
          final isEven = i % 2 == 0;
          return RepaintBoundary(
            child: Container(
              color: isEven ? Colors.transparent : Colors.grey[50],
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
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
                            text: _buildTajwidTextSpanSafe(v.textAr, spans, tajwidEnabled),
                          ),
                        ),
                      ),
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
                        padding: const EdgeInsets.only(top: 4, left: 24, right: 8),
                        child: Text(
                          v.textTranslit!,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            height: 1.3,
                            color: Colors.grey[600],
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
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
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
                          text: _buildTajwidTextSpanSafe(v.textAr, <TajwidSpan>[], tajwidEnabled),
                        ),
                      ),
                    ),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
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
                          text: _buildTajwidTextSpanSafe(v.textAr, <TajwidSpan>[], tajwidEnabled),
                        ),
                      ),
                    ),
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
      fontSize: 28,
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
          fontSize: 28,
          height: 1.5,
          letterSpacing: 0,
          color: Colors.black87,
        ),
      );
    }
  }
}




