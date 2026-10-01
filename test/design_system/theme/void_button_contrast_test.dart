// Kontras label tombol VoidButton di SEMUA preset tema (WCAG 2.2 - 1.4.3).
//
// Gap yang ditutup file ini: void_theme_variant_test.dart hanya menguji
// textPrimary vs background (>=7:1). Itu tidak menangkap kegagalan yang paling
// terlihat: VoidButton melabeli tombol dengan Colors.white di KEDUA mode,
// tanpa cabang dark/light. Setiap preset gelap (darkInk/darkEmber/darkSage/
// darkRose/darkOcean) memakai hue terang, jadi putih di atasnya jauh di bawah
// ambang 4.5:1.
//
// Audit 2026-10-01 (skill wcag-audit-patterns, scripts/contrast_audit.py):
//   darkInk 2.62:1 | darkEmber 2.49:1 | darkSage 2.33:1
//   darkRose 2.38:1 | darkOcean 2.53:1  -> semua FAIL 1.4.3 Level AA
//
// Test ini membaca style ForegroundButton yang BENAR-BENAR dirender widget,
// bukan helper lokal, supaya regresi tidak bisa lolos dengan menyalin logika.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/design_system/theme/void_theme_variant.dart';
import 'package:void_scriptor/design_system/widgets/void_button.dart';

/// Ambang WCAG 2.2 success criterion 1.4.3 Contrast (Minimum), Level AA.
const aaTextThreshold = 4.5;

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

/// Pasangan warna yang benar-benar dirender VoidButton untuk sebuah tema.
Future<({Color fg, Color bg})> _renderedPair(
  WidgetTester tester,
  ThemeData theme,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: VoidButton(label: 'Continue', onPressed: () {}),
      ),
    ),
  );
  final button = tester.widget<FilledButton>(find.byType(FilledButton));
  const state = <WidgetState>{};
  return (
    fg: button.style?.foregroundColor?.resolve(state) ?? Colors.black,
    bg: button.style?.backgroundColor?.resolve(state) ?? Colors.white,
  );
}

void main() {
  group('VoidButton label contrast (WCAG 1.4.3 AA)', () {
    for (final variant in VoidThemeVariant.values) {
      for (final mode in ['light', 'dark']) {
        final theme = mode == 'dark' ? variant.darkTheme : variant.lightTheme;

        testWidgets(
          '${variant.name}/$mode: label tombol >= $aaTextThreshold:1 vs latar',
          (tester) async {
            final pair = await _renderedPair(tester, theme);
            final ratio = _contrastRatio(pair.fg, pair.bg);
            expect(
              ratio,
              greaterThanOrEqualTo(aaTextThreshold),
              reason:
                  '${variant.name}/$mode: label '
                  '${pair.fg.toARGB32().toRadixString(16)} di atas '
                  '${pair.bg.toARGB32().toRadixString(16)} = '
                  '${ratio.toStringAsFixed(2)}:1. Butuh '
                  '$aaTextThreshold:1 untuk WCAG 1.4.3 Level AA.',
            );
          },
        );
      }
    }

    testWidgets('foreground dipilih by luminance, bukan Colors.white statis', (
      tester,
    ) async {
      // Guard akar masalah: kalau pemilihan foreground ever kembali ke
      // Colors.white hardcoded, test ini gagal di 5 preset gelap. voidPurple
      // dark sengaja dikecualikan: primary #7C3AED + putih = 5.70:1 sudah
      // lulus, jadi tidak membuktikan apa pun.
      final lightPresets = ['ink', 'ember', 'sage', 'rose', 'ocean'];
      for (final variant in VoidThemeVariant.values) {
        if (!lightPresets.contains(variant.name)) continue;
        final pair = await _renderedPair(tester, variant.darkTheme);
        expect(
          pair.fg,
          isNot(Colors.white),
          reason:
              '${variant.name}/dark memakai primary terang '
              '${pair.bg.toARGB32().toRadixString(16)}; label putih di atasnya '
              'tidak terbaca. VoidButton harus memilih foreground by luminance.',
        );
      }
    });
  });
}
