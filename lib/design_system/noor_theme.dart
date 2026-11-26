import 'package:flutter/material.dart';

const ink = Color(0xFF183E37);
const warmWhite = Color(0xFFFFFBF1);
const paper = Color(0xFFFFFEF9);
const sage = Color(0xFFE4F0E8);
const outline = Color(0xFFCFDED3);

final _scheme = ColorScheme.fromSeed(seedColor: ink).copyWith(
  primary: ink,
  onPrimary: Colors.white,
  surface: warmWhite,
  onSurface: ink,
  onSurfaceVariant: const Color(0xFF465D55),
  outlineVariant: outline,
);

final noorTheme = ThemeData(
  colorScheme: _scheme,
  scaffoldBackgroundColor: warmWhite,
  visualDensity: VisualDensity.standard,
  appBarTheme: const AppBarTheme(
    backgroundColor: warmWhite,
    foregroundColor: ink,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
);
