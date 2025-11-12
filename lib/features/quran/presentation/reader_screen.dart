import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quran_providers.dart';
import '../data/models/surah_model.dart';
import '../data/models/tajwid_model_v2.dart';
import '../data/tajwid/tajwid_rules.dart';

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
            )
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: surah.verses.length,
        cacheExtent: 500,
        itemBuilder: (context, i) {
          final v = surah.verses[i];
          final spans = tajwidEnabled 
              ? tajwidSurah.getSpansForAyah(v.ayah)
              : <TajwidSpan>[];
          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ayah number badge
                      Container(
                        margin: const EdgeInsets.only(left: 8, top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${v.ayah}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      // Arabic text
                      Expanded(
                        child: RichText(
                          textAlign: TextAlign.right,
                          text: _buildTajwidTextSpanSafe(v.textAr, spans, tajwidEnabled),
                        ),
                      ),
                    ],
                  ),
              if (v.textTranslit != null)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      v.textTranslit!,
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
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      v.textId,
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: surah.verses.length,
        itemBuilder: (context, i) {
          final v = surah.verses[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ayah number badge
                    Container(
                      margin: const EdgeInsets.only(left: 8, top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${v.ayah}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    // Arabic text
                    Expanded(
                      child: RichText(
                        textAlign: TextAlign.right,
                        text: _buildTajwidTextSpanSafe(v.textAr, <TajwidSpan>[], tajwidEnabled),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: surah.verses.length,
        itemBuilder: (context, i) {
          final v = surah.verses[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ayah number badge
                    Container(
                      margin: const EdgeInsets.only(left: 8, top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${v.ayah}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    // Arabic text
                    Expanded(
                      child: RichText(
                        textAlign: TextAlign.right,
                        text: _buildTajwidTextSpanSafe(v.textAr, <TajwidSpan>[], tajwidEnabled),
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
      // Log error but don't crash - fallback to plain text
      debugPrint('Tajwid rendering error for text (length: ${textAr.length}): $e');
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




