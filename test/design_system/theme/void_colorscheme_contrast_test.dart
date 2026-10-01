// Kontras slot ColorScheme global (WCAG 2.2 - 1.4.3).
//
// Gap yang ditutup file ini: VoidTheme.buildDark/buildLight memasang
// onPrimary/onSecondary/onError sebagai Colors.white statis. Semua tombol
// Flutter mentah (FilledButton/ElevatedButton tanpa style) di 70+ layar
// mewarisi slot itu, sehingga label putih di atas hue aksen terang preset gelap
// hanya mencapai 2.33-2.62:1.
//
// Fix 2026-10-01: slot tersebut memakai onAccentForeground() dari
// void_palette.dart, yang memilih hitam/putih by luminance.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/design_system/theme/void_theme_variant.dart';

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

void main() {
  group('ColorScheme onXxx slot contrast (WCAG 1.4.3 AA)', () {
    for (final variant in VoidThemeVariant.values) {
      for (final mode in ['light', 'dark']) {
        final theme = mode == 'dark' ? variant.darkTheme : variant.lightTheme;
        final scheme = theme.colorScheme;

        for (final slot in [
          ('onPrimary', scheme.primary, scheme.onPrimary),
          ('onSecondary', scheme.secondary, scheme.onSecondary),
          ('onError', scheme.error, scheme.onError),
        ]) {
          testWidgets(
            '${variant.name}/$mode ${slot.$1}: >= $aaTextThreshold:1 vs ${slot.$1.replaceAll("on", "")}',
            (tester) async {
              final ratio = _contrastRatio(slot.$3, slot.$2);
              expect(
                ratio,
                greaterThanOrEqualTo(aaTextThreshold),
                reason:
                    '${variant.name}/$mode: ${slot.$3.toARGB32().toRadixString(16)} '
                    'di atas ${slot.$2.toARGB32().toRadixString(16)} = '
                    '${ratio.toStringAsFixed(2)}:1',
              );
            },
          );
        }
      }
    }
  });
}
