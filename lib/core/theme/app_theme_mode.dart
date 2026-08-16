import 'package:flutter/material.dart';

/// Tema tampilan aplikasi yang dapat dipilih pengguna.
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
