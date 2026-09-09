import 'package:flutter/material.dart';

import 'void_palette.dart';
import 'void_theme.dart';
import 'void_theme_presets.dart';

/// Opsi tema Void Scriptor: kombinasi mode kecerahan (light/dark) dan
/// keluarga warna aksen (preset).
enum VoidThemeVariant {
  voidPurple(VoidPalette.dark, VoidPalette.light),
  ink(VoidThemePresets.darkInk, VoidThemePresets.lightInk),
  ember(VoidThemePresets.darkEmber, VoidThemePresets.lightEmber),
  sage(VoidThemePresets.darkSage, VoidThemePresets.lightSage),
  rose(VoidThemePresets.darkRose, VoidThemePresets.lightRose),
  ocean(VoidThemePresets.darkOcean, VoidThemePresets.lightOcean);

  const VoidThemeVariant(this.darkPalette, this.lightPalette);

  final VoidPalette darkPalette;
  final VoidPalette lightPalette;

  /// Kombinasi kecerahan terang dari preset ini.
  ThemeData get lightTheme => VoidTheme.buildLight(lightPalette);

  /// Kombinasi kecerahan gelap dari preset ini.
  ThemeData get darkTheme => VoidTheme.buildDark(darkPalette);
}
