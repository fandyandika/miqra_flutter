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
/// - Purple/Magenta: Ghunnah & Idghaam dengan Ghunnah
/// - Blue gradient: Different shades for each Madd type
/// - Cyan: Iqlab
/// - Dark Blue: Qalqalah
/// - Green: Ikhfa
/// - Red: Idghaam tanpa Ghunnah
final Map<String, Color> tajwidPalette = {
  // Purple/Magenta - Ghunnah & Idghaam dengan Ghunnah
  TajwidRule.ghunnah: const Color(0xFF9C27B0), // Purple
  TajwidRule.idghaamGhunnah: const Color(0xFF9C27B0), // Purple
  TajwidRule.idghaamMutajanisayn: const Color(0xFF9C27B0), // Purple
  TajwidRule.idghaamMutaqaribayn: const Color(0xFF9C27B0), // Purple
  TajwidRule.idghaamShafawi: const Color(0xFF9C27B0), // Purple
  
  // Madd - Different colors for each type
  TajwidRule.madd6: const Color(0xFFE023E0), // Magenta (Madd Lazim - wajib, 6 harakat)
  TajwidRule.maddMuttasil: const Color(0xFF0DCDCD), // Teal (Madd Muttasil - wajib, dalam satu kata)
  TajwidRule.maddMunfasil: const Color(0xFF19B100), // Green (Madd Munfasil - jaiz, antar kata)
  
  // Cyan - Iqlab
  TajwidRule.iqlab: const Color(0xFF00BCD4), // Cyan
  
  // Dark Blue - Qalqalah (different shade from madd_6)
  TajwidRule.qalqalah: const Color(0xFF1565C0), // Darker Blue
  
  // Green - Ikhfa
  TajwidRule.ikhfa: const Color(0xFF4CAF50), // Green
  TajwidRule.ikhfaShafawi: const Color(0xFF4CAF50), // Green
  
  // Red - Idghaam tanpa Ghunnah
  TajwidRule.idghaamNoGhunnah: const Color(0xFFF44336), // Red
};

