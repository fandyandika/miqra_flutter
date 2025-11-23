import 'package:flutter/material.dart';

/// Miqra Spacing System
///
/// Based on 8pt grid system (Apple, Notion, Linear standard):
/// - All spacing values are multiples of 4 or 8
/// - Creates consistent visual rhythm
/// - Makes layouts predictable and harmonious
///
/// Usage:
/// ```dart
/// SizedBox(height: MiqraSpacing.md)
/// Padding(padding: MiqraSpacing.screenPadding)
/// ```
class MiqraSpacing {
  // Base spacing values (8pt grid)
  static const double xxs = 4.0; // Micro spacing (tight elements)
  static const double xs = 8.0; // Extra small (minimal gap)
  static const double sm = 12.0; // Small (compact spacing)
  static const double md = 16.0; // Medium (default spacing)
  static const double lg = 24.0; // Large (section spacing)
  static const double xl = 32.0; // Extra large (major sections)
  static const double xxl = 48.0; // Hero spacing (landing sections)

  // Edge insets presets for common use cases

  /// Default screen padding (16px all sides)
  static const EdgeInsets screenPadding = EdgeInsets.all(md);

  /// Horizontal screen padding only (16px left/right)
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(
    horizontal: md,
  );

  /// Vertical screen padding only (16px top/bottom)
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(
    vertical: md,
  );

  /// Card padding (16px all sides)
  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  /// Card padding compact (12px all sides)
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(sm);

  /// List item padding (horizontal: 16px, vertical: 12px)
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  /// List item padding compact (horizontal: 16px, vertical: 8px)
  static const EdgeInsets listItemPaddingCompact = EdgeInsets.symmetric(
    horizontal: md,
    vertical: xs,
  );

  /// Button padding (horizontal: 24px, vertical: 12px)
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  /// Button padding compact (horizontal: 16px, vertical: 8px)
  static const EdgeInsets buttonPaddingCompact = EdgeInsets.symmetric(
    horizontal: md,
    vertical: xs,
  );

  /// Icon button padding (8px all sides)
  static const EdgeInsets iconButtonPadding = EdgeInsets.all(xs);

  /// Modal/Bottom sheet padding (16px horizontal, 24px vertical)
  static const EdgeInsets modalPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );

  /// Section spacing (24px top/bottom between major sections)
  static const EdgeInsets sectionSpacing = EdgeInsets.symmetric(
    vertical: lg,
  );

  // Border radius constants (for consistency)

  /// Small border radius (8px)
  static const BorderRadius radiusSmall = BorderRadius.all(
    Radius.circular(8.0),
  );

  /// Medium border radius (12px) - Default for cards/buttons
  static const BorderRadius radiusMedium = BorderRadius.all(
    Radius.circular(12.0),
  );

  /// Large border radius (16px) - For hero elements
  static const BorderRadius radiusLarge = BorderRadius.all(
    Radius.circular(16.0),
  );

  /// Extra large border radius (24px) - For modals
  static const BorderRadius radiusXLarge = BorderRadius.all(
    Radius.circular(24.0),
  );

  /// Circular (pill shape)
  static const BorderRadius radiusCircular = BorderRadius.all(
    Radius.circular(999.0),
  );

  // Common gap values for Flex widgets (Row/Column)

  /// Vertical gap (Column children)
  static Widget get gapXS => const SizedBox(height: xs);
  static Widget get gapSM => const SizedBox(height: sm);
  static Widget get gapMD => const SizedBox(height: md);
  static Widget get gapLG => const SizedBox(height: lg);
  static Widget get gapXL => const SizedBox(height: xl);

  /// Horizontal gap (Row children)
  static Widget get gapHorizontalXS => const SizedBox(width: xs);
  static Widget get gapHorizontalSM => const SizedBox(width: sm);
  static Widget get gapHorizontalMD => const SizedBox(width: md);
  static Widget get gapHorizontalLG => const SizedBox(width: lg);
  static Widget get gapHorizontalXL => const SizedBox(width: xl);

  // Divider/Separator thickness

  /// Thin divider (1px)
  static const double dividerThin = 1.0;

  /// Medium divider (2px)
  static const double dividerMedium = 2.0;
}
