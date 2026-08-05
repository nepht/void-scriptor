// Void Scriptor Theme System — v1.0.0
// 6 palet themes with SemanticColors (mutable, not const).
// ThemePicker in TopBar; onModeChanged → ThemeStorage.save (PERSIST).

import 'package:flutter/material.dart';

class VoidTheme {
  // --- Light Theme ---
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF6C3483),
        scaffoldBackgroundColor: const Color(0xFFF5F0FA),
      );

  // --- Dark Theme ---
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6C3483),
        scaffoldBackgroundColor: const Color(0xFF1A1025),
      );
}

// --- Semantic Colors (MUTABLE — do not use const) ---
class SemanticColors {
  static Color primary = const Color(0xFF6C3483);
  static Color secondary = const Color(0xFFD4A017);
  static Color accent = const Color(0xFF9B59B6);
  static Color background = const Color(0xFFF5F0FA);
  static Color surface = const Color(0xFFFFFFFF);
  static Color error = const Color(0xFFE74C3C);
  static Color success = const Color(0xFF27AE60);
  static Color warning = const Color(0xFFF39C12);
}

// --- 6 Theme Palettes ---
enum VoidPalette {
  purpleGold,
  midnightEmber,
  forestDeep,
  oceanDepth,
  crimsonShadow,
  silverFrost,
}
