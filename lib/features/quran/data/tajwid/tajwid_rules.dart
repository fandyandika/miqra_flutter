import 'package:flutter/material.dart';

/// Tajwid rule constants.
/// 
/// Indices are UTF-16 based (Dart String indices).
/// Styling-only: never mutate the original text.
class TajwidRule {
  static const String madd6 = 'madd_6';
  static const String idghaamNoGhunnah = 'idghaam_no_ghunnah';
  static const String ghunnah = 'ghunnah';
  static const String ikhfa = 'ikhfa';
  static const String ikhfaShafawi = 'ikhfa_shafawi';
  static const String iqlab = 'iqlab';
  static const String qalqalah = 'qalqalah';
  static const String maddMunfasil = 'madd_munfasil';
  static const String maddMuttasil = 'madd_muttasil';
  static const String idghaamGhunnah = 'idghaam_ghunnah';
  static const String idghaamMutajanisayn = 'idghaam_mutajanisayn';
  static const String idghaamMutaqaribayn = 'idghaam_mutaqaribayn';
  static const String idghaamShafawi = 'idghaam_shafawi';
}

/// Tajwid color palette matching standard tajwid color scheme.
///
/// Color mapping based on standard tajwid categorization:
/// - Blue/Cyan: Iqlab, Madd Muttasil
/// - Dark Blue: Qalqalah
/// - Purple/Magenta: Ghunnah, Idghaam dengan Ghunnah, Madd Lazim
/// - Green: Ikhfa
/// - Red: Idghaam tanpa Ghunnah
final Map<String, Color> tajwidPalette = {
  // Purple/Magenta - Ghunnah & Idghaam dengan Ghunnah & Madd Lazim
  TajwidRule.ghunnah: const Color(0xFF9C27B0), // Purple
  TajwidRule.idghaamGhunnah: const Color(0xFF9C27B0), // Purple
  TajwidRule.idghaamMutajanisayn: const Color(0xFF9C27B0), // Purple
  TajwidRule.idghaamMutaqaribayn: const Color(0xFF9C27B0), // Purple
  TajwidRule.idghaamShafawi: const Color(0xFF9C27B0), // Purple
  TajwidRule.madd6: const Color(0xFF9C27B0), // Purple (Madd Lazim)
  
  // Blue/Cyan - Iqlab & Madd Muttasil
  TajwidRule.iqlab: const Color(0xFF00BCD4), // Cyan
  TajwidRule.maddMuttasil: const Color(0xFF00BCD4), // Cyan
  
  // Dark Blue - Qalqalah
  TajwidRule.qalqalah: const Color(0xFF1976D2), // Dark Blue
  
  // Green - Ikhfa
  TajwidRule.ikhfa: const Color(0xFF4CAF50), // Green
  TajwidRule.ikhfaShafawi: const Color(0xFF4CAF50), // Green
  
  // Red - Idghaam tanpa Ghunnah
  TajwidRule.idghaamNoGhunnah: const Color(0xFFF44336), // Red
  
  // Purple - Madd Munfasil (keep same as madd_6 for consistency)
  TajwidRule.maddMunfasil: const Color(0xFF9C27B0), // Purple
};

