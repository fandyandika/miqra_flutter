import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../constants/spacing.dart';

/// Miqra App Theme
///
/// Modern, minimalist theme based on:
/// - Apple Human Interface Guidelines
/// - Notion design system
/// - WhatsApp clarity principles
///
/// Features:
/// - Flat design (minimal shadows)
/// - Clear typography hierarchy
/// - Consistent spacing (8pt grid)
/// - Semantic colors
ThemeData buildAppTheme() {
  return ThemeData(
    // ========== MATERIAL 3 ==========
    useMaterial3: true,

    // ========== COLOR SCHEME ==========
    colorScheme: ColorScheme.light(
      primary: MiqraColors.primary,
      onPrimary: MiqraColors.textOnPrimary,
      secondary: MiqraColors.secondary,
      onSecondary: MiqraColors.textOnPrimary,
      error: MiqraColors.error,
      onError: MiqraColors.textInverse,
      surface: MiqraColors.surface,
      onSurface: MiqraColors.textPrimary,
      surfaceContainerHighest: MiqraColors.bgSecondary,
      outline: MiqraColors.borderLight,
      outlineVariant: MiqraColors.borderMedium,
    ),

    // ========== SCAFFOLD ==========
    scaffoldBackgroundColor: MiqraColors.bgPrimary,

    // ========== TYPOGRAPHY ==========
    fontFamily: 'Inter',
    textTheme: TextTheme(
      // Display (Hero text)
      displayLarge: MiqraTextStyles.display,
      displayMedium: MiqraTextStyles.display.copyWith(fontSize: 28),
      displaySmall: MiqraTextStyles.display.copyWith(fontSize: 24),

      // Headlines
      headlineLarge: MiqraTextStyles.title1,
      headlineMedium: MiqraTextStyles.title2,
      headlineSmall: MiqraTextStyles.headline,

      // Titles
      titleLarge: MiqraTextStyles.title2,
      titleMedium: MiqraTextStyles.headline,
      titleSmall: MiqraTextStyles.captionBold,

      // Body
      bodyLarge: MiqraTextStyles.body,
      bodyMedium: MiqraTextStyles.body,
      bodySmall: MiqraTextStyles.caption,

      // Labels
      labelLarge: MiqraTextStyles.button,
      labelMedium: MiqraTextStyles.caption,
      labelSmall: MiqraTextStyles.label,
    ),

    // ========== APP BAR ==========
    appBarTheme: AppBarTheme(
      elevation: 0, // Flat design
      scrolledUnderElevation: 0, // No shadow when scrolled
      centerTitle: true,
      backgroundColor: MiqraColors.bgPrimary,
      foregroundColor: MiqraColors.textPrimary,
      titleTextStyle: MiqraTextStyles.headline.copyWith(
        color: MiqraColors.textPrimary,
      ),
      iconTheme: IconThemeData(
        color: MiqraColors.textPrimary,
        size: 24,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    // ========== CARD ==========
    cardTheme: CardTheme(
      elevation: 0, // Flat design (Notion-style)
      shape: RoundedRectangleBorder(
        borderRadius: MiqraSpacing.radiusMedium,
        side: BorderSide(
          color: MiqraColors.borderLight,
          width: 1,
        ),
      ),
      color: MiqraColors.surface,
      margin: EdgeInsets.zero, // Control margin manually
      clipBehavior: Clip.antiAlias,
    ),

    // ========== BUTTONS ==========
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0, // Flat design
        backgroundColor: MiqraColors.primary,
        foregroundColor: MiqraColors.textOnPrimary,
        disabledBackgroundColor: MiqraColors.bgTertiary,
        disabledForegroundColor: MiqraColors.textTertiary,
        padding: MiqraSpacing.buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: MiqraSpacing.radiusMedium,
        ),
        textStyle: MiqraTextStyles.button,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor: MiqraColors.primary,
        disabledForegroundColor: MiqraColors.textTertiary,
        padding: MiqraSpacing.buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: MiqraSpacing.radiusMedium,
        ),
        side: BorderSide(
          color: MiqraColors.primary,
          width: 1.5,
        ),
        textStyle: MiqraTextStyles.button,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MiqraColors.primary,
        disabledForegroundColor: MiqraColors.textTertiary,
        padding: MiqraSpacing.buttonPaddingCompact,
        shape: RoundedRectangleBorder(
          borderRadius: MiqraSpacing.radiusMedium,
        ),
        textStyle: MiqraTextStyles.button,
      ),
    ),

    // ========== INPUT FIELDS ==========
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MiqraColors.bgSecondary,
      contentPadding: EdgeInsets.symmetric(
        horizontal: MiqraSpacing.md,
        vertical: MiqraSpacing.sm,
      ),
      // Borders
      border: OutlineInputBorder(
        borderRadius: MiqraSpacing.radiusMedium,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: MiqraSpacing.radiusMedium,
        borderSide: BorderSide(
          color: MiqraColors.borderLight,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: MiqraSpacing.radiusMedium,
        borderSide: BorderSide(
          color: MiqraColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: MiqraSpacing.radiusMedium,
        borderSide: BorderSide(
          color: MiqraColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: MiqraSpacing.radiusMedium,
        borderSide: BorderSide(
          color: MiqraColors.error,
          width: 2,
        ),
      ),
      // Text styles
      labelStyle: MiqraTextStyles.body.copyWith(
        color: MiqraColors.textSecondary,
      ),
      hintStyle: MiqraTextStyles.body.copyWith(
        color: MiqraColors.textTertiary,
      ),
      errorStyle: MiqraTextStyles.caption.copyWith(
        color: MiqraColors.error,
      ),
    ),

    // ========== BOTTOM NAVIGATION BAR ==========
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      backgroundColor: MiqraColors.surface,
      selectedItemColor: MiqraColors.primary,
      unselectedItemColor: MiqraColors.textTertiary,
      selectedLabelStyle: MiqraTextStyles.label,
      unselectedLabelStyle: MiqraTextStyles.label,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    // ========== DIVIDER ==========
    dividerTheme: DividerThemeData(
      color: MiqraColors.divider,
      thickness: MiqraSpacing.dividerThin,
      space: MiqraSpacing.md,
    ),

    // ========== ICON ==========
    iconTheme: IconThemeData(
      color: MiqraColors.textPrimary,
      size: 24,
    ),

    // ========== LIST TILE ==========
    listTileTheme: ListTileThemeData(
      contentPadding: MiqraSpacing.listItemPadding,
      iconColor: MiqraColors.textPrimary,
      textColor: MiqraColors.textPrimary,
      titleTextStyle: MiqraTextStyles.body,
      subtitleTextStyle: MiqraTextStyles.caption.copyWith(
        color: MiqraColors.textSecondary,
      ),
    ),

    // ========== TAB BAR ==========
    tabBarTheme: TabBarTheme(
      labelColor: MiqraColors.primary,
      unselectedLabelColor: MiqraColors.textSecondary,
      labelStyle: MiqraTextStyles.bodyBold,
      unselectedLabelStyle: MiqraTextStyles.body,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: MiqraColors.primary,
          width: 2,
        ),
      ),
    ),

    // ========== SNACKBAR ==========
    snackBarTheme: SnackBarThemeData(
      backgroundColor: MiqraColors.textPrimary,
      contentTextStyle: MiqraTextStyles.body.copyWith(
        color: MiqraColors.textInverse,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: MiqraSpacing.radiusMedium,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),

    // ========== DIALOG ==========
    dialogTheme: DialogTheme(
      elevation: 0,
      backgroundColor: MiqraColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: MiqraSpacing.radiusLarge,
      ),
      titleTextStyle: MiqraTextStyles.title2.copyWith(
        color: MiqraColors.textPrimary,
      ),
      contentTextStyle: MiqraTextStyles.body.copyWith(
        color: MiqraColors.textSecondary,
      ),
    ),

    // ========== BOTTOM SHEET ==========
    bottomSheetTheme: BottomSheetThemeData(
      elevation: 0,
      backgroundColor: MiqraColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MiqraSpacing.lg),
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    // ========== CHIP ==========
    chipTheme: ChipThemeData(
      backgroundColor: MiqraColors.bgSecondary,
      selectedColor: MiqraColors.primaryLight,
      disabledColor: MiqraColors.bgTertiary,
      labelStyle: MiqraTextStyles.caption,
      padding: EdgeInsets.symmetric(
        horizontal: MiqraSpacing.sm,
        vertical: MiqraSpacing.xxs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: MiqraSpacing.radiusSmall,
      ),
    ),

    // ========== FLOATING ACTION BUTTON ==========
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: MiqraColors.primary,
      foregroundColor: MiqraColors.textOnPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: MiqraSpacing.radiusMedium,
      ),
    ),
  );
}

