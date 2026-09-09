// Kontrak multi-preset warna tema (6 keluarga aksen x light/dark).
//
// Kebutuhan Choi: tema tidak monoton — penulis memilih warna sesuai selera,
// pilihan tersimpan lintas sesuai (bullet berikutnya), default tetap Void
// Purple. Bullet ini: palet preset valid, aksen unik antar keluarga, dan
// kontras teks WCAG di SEMUA palet (regresi putih-di-putih tidak boleh
// terulang di preset mana pun).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/design_system/theme/void_palette.dart';
import 'package:void_scriptor/design_system/theme/void_theme_presets.dart';
import 'package:void_scriptor/design_system/theme/void_theme_variant.dart';

double _linearChannel(double c) {
  final x = c / 255.0;
  return x <= 0.03928
      ? x / 12.92
      : math.pow((x + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(Color c) =>
    0.2126 * _linearChannel(c.r * 255.0) +
    0.7152 * _linearChannel(c.g * 255.0) +
    0.0722 * _linearChannel(c.b * 255.0);

double _contrastRatio(Color a, Color b) {
  final l1 = _luminance(a), l2 = _luminance(b);
  final lighter = l1 > l2 ? l1 : l2, darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('VoidThemeVariant', () {
    test('menyediakan 6 keluarga aksen, default voidPurple', () {
      expect(VoidThemeVariant.values.length, 6);
      expect(VoidThemeVariant.values.first, VoidThemeVariant.voidPurple);
      expect(
        VoidThemeVariant.values.map((v) => v.name),
        containsAll(['voidPurple', 'ink', 'ember', 'sage', 'rose', 'ocean']),
      );
    });

    test('setiap preset punya aksen unik antar keluarga (light & dark)', () {
      final lightPrimaries = VoidThemeVariant.values
          .map((v) => v.lightPalette.primary.toARGB32())
          .toSet();
      final darkPrimaries = VoidThemeVariant.values
          .map((v) => v.darkPalette.primary.toARGB32())
          .toSet();
      expect(
        lightPrimaries.length,
        6,
        reason: 'aksen light harus unik antar keluarga',
      );
      expect(
        darkPrimaries.length,
        6,
        reason: 'aksen dark harus unik antar keluarga',
      );
    });

    test('SEMUA palet preset lulus kontras teks WCAG (>=7:1 textPrimary)', () {
      for (final variant in VoidThemeVariant.values) {
        for (final palette in [variant.lightPalette, variant.darkPalette]) {
          final ratio = _contrastRatio(palette.textPrimary, palette.background);
          expect(
            ratio,
            greaterThanOrEqualTo(7.0),
            reason:
                '${variant.name}: kontras textPrimary vs background '
                '${ratio.toStringAsFixed(2)}:1 — wajib >= 7:1 (AAA) agar '
                'tidak ada lagi teks putih-di-atas-putih',
          );
        }
      }
    });

    test(
      'buildLight/buildDark memasang palette + textTheme preset masing2',
      () {
        final light = VoidThemeVariant.ember.lightTheme;
        expect(
          light.extension<VoidPalette>()?.primary,
          VoidThemePresets.lightEmber.primary,
        );
        expect(
          light.textTheme.titleLarge?.color,
          VoidThemePresets.lightEmber.textPrimary,
        );

        final dark = VoidThemeVariant.sage.darkTheme;
        expect(
          dark.extension<VoidPalette>()?.primary,
          VoidThemePresets.darkSage.primary,
        );
        expect(
          dark.textTheme.titleLarge?.color,
          VoidThemePresets.darkSage.textPrimary,
        );
      },
    );
  });
}
