import 'package:flutter/material.dart';

import '../../design_system/theme/void_theme_variant.dart';

/// Mode kecerahan tema aplikasi yang dapat dipilih pengguna.
///
/// `system` mengikuti tema OS, sedangkan `light`/`dark` memaksa
/// tampilan terang/gelap terlepas dari pengaturan sistem.
enum AppThemeMode {
  system,
  light,
  dark;

  ThemeMode get themeMode => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}

/// Keluarga warna aksen yang dapat dipilih pengguna (regardless of light/dark).
///
/// Nama harus identik dengan [VoidThemeVariant] — dipisah agar layer core
/// tidak bergantung pada layer design_system.
enum VoidThemeAccent {
  voidPurple,
  ink,
  ember,
  sage,
  rose,
  ocean;

  /// Preset design-system untuk aksen ini (name-based, tanpa import cycles).
  VoidThemeVariant get variant =>
      VoidThemeVariant.values.firstWhere((v) => v.name == name);
}
