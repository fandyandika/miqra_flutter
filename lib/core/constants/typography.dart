import 'package:flutter/material.dart';

/// Miqra Typography System
///
/// Based on Apple HIG and Notion design principles:
/// - Clear hierarchy with limited font sizes
/// - Consistent line heights (1.2-1.4)
/// - Negative letter-spacing for large text
/// - Inter font family throughout
///
/// Usage:
/// ```dart
/// Text('Hello', style: MiqraTextStyles.headline)
/// ```
class MiqraTextStyles {
  // Display (Hero text, large headings)
  static const display = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  // Title Level 1 (Screen headers, page titles)
  static const title1 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );

  // Title Level 2 (Section headers)
  static const title2 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );

  // Headline (Card titles, prominent labels)
  static const headline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  // Body (Main content, readable text)
  static const body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
  );

  // Body Bold (Emphasized body text)
  static const bodyBold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  // Caption (Labels, metadata, secondary information)
  static const caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0,
  );

  // Caption Bold (Emphasized captions)
  static const captionBold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );

  // Label (Tiny text, footnotes, timestamps)
  static const label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.1,
  );

  // Label Bold (Emphasized tiny text)
  static const labelBold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.1,
  );

  // Button Text (For buttons and CTAs)
  static const button = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0,
  );

  // Quran-specific text styles

  // Arabic Quran text (large, readable)
  static const quranArabic = TextStyle(
    fontFamily: 'IndopakNastaleeq',
    fontSize: 30,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  // Arabic Quran text (compact for lists)
  static const quranArabicCompact = TextStyle(
    fontFamily: 'IndopakNastaleeq',
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
  );

  // Transliteration (italic, readable)
  static const transliteration = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.3,
    fontStyle: FontStyle.italic,
  );

  // Translation (readable body text)
  static const translation = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Surah name (Arabic decorative)
  static const surahNameArabic = TextStyle(
    fontFamily: 'QuranCommon',
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Bismillah (decorative)
  static const bismillah = TextStyle(
    fontFamily: 'QuranCommon',
    fontSize: 34,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
}
