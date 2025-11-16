import 'package:flutter/material.dart';
import '../constants/colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: miqraPrimary,
      primary: miqraPrimary,
      secondary: miqraCoral,
      background: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Inter', // Default body font
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: miqraText, displayColor: miqraText)
        .copyWith(
          // Heading styles use Inter (w600-w700 for emphasis)
          displayLarge: base.textTheme.displayLarge?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
          displayMedium: base.textTheme.displayMedium?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
          displaySmall: base.textTheme.displaySmall?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
          titleSmall: base.textTheme.titleSmall?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
          // Body styles use Inter (w400-w500 for readability)
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          bodySmall: base.textTheme.bodySmall?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          // Label styles use Inter (w500-w600 for visibility)
          labelLarge: base.textTheme.labelLarge?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
          labelMedium: base.textTheme.labelMedium?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
          labelSmall: base.textTheme.labelSmall?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
  );
}

