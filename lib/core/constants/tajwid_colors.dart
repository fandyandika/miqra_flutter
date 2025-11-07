import 'package:flutter/material.dart';
import '../../features/quran/data/tajwid/tajwid_rules.dart';

Color getTajwidColor(String rule) {
  return tajwidPalette[rule] ?? Colors.red; // Debug color for unknown rules
}

