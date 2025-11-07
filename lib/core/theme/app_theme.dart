import 'package:flutter/material.dart';
import '../constants/colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: miqraPrimary,
      primary: miqraPrimary,
      secondary: miqraCoral,
      background: miqraSand,
    ),
    scaffoldBackgroundColor: miqraSand,
    fontFamily: 'Roboto',
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: miqraText, displayColor: miqraText),
  );
}

