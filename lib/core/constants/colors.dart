import 'package:flutter/material.dart';

// ============================================================================
// BRAND COLORS (Legacy - kept for backward compatibility)
// ============================================================================
const miqraPrimary = Color(0xFF14B4A0); // Turquoise (primary actions)
const miqraCoral = Color(0xFFFF8A65); // Coral (secondary actions)
const miqraGold = Color(0xFFFFB627); // Gold (highlights, rewards)
const miqraSand = Color(0xFFFFF8F0); // Sand (warm backgrounds)
const miqraText = Color(0xFF2D3436); // Dark text (deprecated - use MiqraColors.textPrimary)

// ============================================================================
// SEMANTIC COLOR SYSTEM
// ============================================================================
/// Miqra Semantic Colors
///
/// Based on Notion/Apple design principles:
/// - Semantic naming (purpose over appearance)
/// - Clear text hierarchy
/// - Accessible contrast ratios
/// - Minimal color palette
///
/// Usage:
/// ```dart
/// Text('Hello', style: TextStyle(color: MiqraColors.textPrimary))
/// Container(color: MiqraColors.bgSecondary)
/// ```
class MiqraColors {
  // ========== TEXT COLORS (3-level hierarchy) ==========

  /// Primary text - Headlines, important content
  /// WCAG AAA compliant (contrast ratio > 7:1)
  static const textPrimary = Color(0xFF2D3436);

  /// Secondary text - Body text, descriptions
  /// WCAG AA compliant (contrast ratio > 4.5:1)
  static const textSecondary = Color(0xFF636E72);

  /// Tertiary text - Labels, placeholders, disabled text
  /// Subtle but readable
  static const textTertiary = Color(0xFFB2BEC3);

  /// Text on colored backgrounds (inverse)
  static const textInverse = Color(0xFFFFFFFF);

  /// Text on Miqra Primary color
  static const textOnPrimary = Color(0xFFFFFFFF);

  // ========== BACKGROUND COLORS ==========

  /// Primary background - Main content area
  static const bgPrimary = Color(0xFFFFFFFF);

  /// Secondary background - Alternating rows, subtle sections
  static const bgSecondary = Color(0xFFFAFAFA);

  /// Tertiary background - Disabled states, inactive elements
  static const bgTertiary = Color(0xFFF5F5F5);

  /// Sand background - Warm, calm feeling (streak cards, special sections)
  static const bgSand = miqraSand;

  // ========== SURFACE COLORS (Cards, Sheets) ==========

  /// Default surface - Cards, modals, dialogs
  static const surface = Color(0xFFFFFFFF);

  /// Surface hover/pressed state
  static const surfaceHover = Color(0xFFF8F9FA);

  /// Surface with elevation (subtle)
  static const surfaceElevated = Color(0xFFFFFFFF);

  // ========== BORDER COLORS ==========

  /// Light border - Default dividers, card borders
  static const borderLight = Color(0xFFE8ECEF);

  /// Medium border - Emphasized borders
  static const borderMedium = Color(0xFFDFE6E9);

  /// Dark border - Strong emphasis
  static const borderDark = Color(0xFFB2BEC3);

  // ========== BRAND/ACTION COLORS ==========

  /// Primary action - Main CTAs, links, active states
  static const primary = miqraPrimary;

  /// Primary hover/pressed state
  static const primaryHover = Color(0xFF12A293);

  /// Primary light - Subtle backgrounds for primary elements
  static const primaryLight = Color(0xFFE0F7F4);

  /// Secondary action - Alternative CTAs
  static const secondary = miqraCoral;

  /// Secondary hover/pressed state
  static const secondaryHover = Color(0xFFFF7556);

  /// Secondary light - Subtle backgrounds for secondary elements
  static const secondaryLight = Color(0xFFFFEBE6);

  // ========== ACCENT COLORS ==========

  /// Gold accent - Rewards, achievements, highlights
  static const accent = miqraGold;

  /// Gold light - Subtle backgrounds for accent elements
  static const accentLight = Color(0xFFFFF5E0);

  // ========== STATUS COLORS ==========

  /// Success - Positive feedback, completed states
  static const success = miqraPrimary;

  /// Success light background
  static const successLight = Color(0xFFE0F7F4);

  /// Warning - Attention needed, caution
  static const warning = miqraGold;

  /// Warning light background
  static const warningLight = Color(0xFFFFF5E0);

  /// Error - Destructive actions, errors
  static const error = Color(0xFFFF6B6B);

  /// Error light background
  static const errorLight = Color(0xFFFFE5E5);

  /// Info - Informational messages
  static const info = Color(0xFF74B9FF);

  /// Info light background
  static const infoLight = Color(0xFFE8F4FF);

  // ========== QURAN-SPECIFIC COLORS ==========

  /// Quran text color (Arabic)
  static const quranText = Color(0xFF000000);

  /// Quran translation text
  static const quranTranslation = Color(0xFF2E3A46);

  /// Quran transliteration text (brown tone)
  static const quranTransliteration = Color(0xFF4E1F0A);

  /// Surah header decoration (orange)
  static const surahDecoration = Color(0xFFE56115);

  /// Ayah badge background
  static const ayahBadge = Color(0xFFFFFFFF);

  /// Ayah badge text
  static const ayahBadgeText = Color(0xFF2D3436);

  // ========== SPECIAL COLORS ==========

  /// Overlay - Modals, sheets backdrop
  static const overlay = Color(0x80000000); // 50% black

  /// Overlay light - Subtle overlays
  static const overlayLight = Color(0x1A000000); // 10% black

  /// Shadow - Elevation shadows
  static const shadow = Color(0x0D000000); // 5% black

  /// Divider - Separator lines
  static const divider = borderLight;

  // ========== STREAK COLORS ==========

  /// Streak active day
  static const streakActive = miqraPrimary;

  /// Streak current day highlight
  static const streakToday = miqraGold;

  /// Streak inactive day
  static const streakInactive = Color(0xFFE8ECEF);

  // ========== OPACITY HELPERS ==========

  /// Creates a color with specified opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Primary with 10% opacity
  static Color get primarySubtle => primary.withOpacity(0.1);

  /// Secondary with 10% opacity
  static Color get secondarySubtle => secondary.withOpacity(0.1);

  /// Accent with 10% opacity
  static Color get accentSubtle => accent.withOpacity(0.1);
}

