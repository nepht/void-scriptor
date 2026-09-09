// Contrass regression: typography styles harus mengikuti palet tema aktif.
//
// Bug: VoidTypography hardcode VoidColors.textPrimary (warna tema gelap,
// 0xFFF5F5F7) sehingga pada tema terang teks render putih-di-atas-putih
// (terverifikasi di Android emulator, system light mode, 2026-09-09).
//
// Kontrak setelah fix:
// 1. VoidTypography TIDAK lagi mengunci warna (null) — warna datang dari
//    cascade DefaultTextStyle yang dipimpin ThemeData.textTheme.
// 2. VoidTheme.light memasang textTheme dengan tinta dari VoidPalette.light.
// 3. VoidTheme.dark memasang textTheme dengan tinta dari VoidPalette.dark.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/design_system/theme/void_palette.dart';
import 'package:void_scriptor/design_system/theme/void_theme.dart';
import 'package:void_scriptor/design_system/typography/void_typography.dart';

void main() {
  group('VoidTheme textTheme contrast', () {
    test('VoidTypography tidak mengunci warna (cascade-friendly)', () {
      expect(VoidTypography.displayLarge.color, isNull);
      expect(VoidTypography.displayMedium.color, isNull);
      expect(VoidTypography.headingLarge.color, isNull);
      expect(VoidTypography.headingMedium.color, isNull);
      expect(VoidTypography.title.color, isNull);
      expect(VoidTypography.body.color, isNull);
      expect(VoidTypography.label.color, isNull);
      expect(VoidTypography.caption.color, isNull);
    });

    test('light theme memakai tinta palet terang (bukan tinta gelap)', () {
      final theme = VoidTheme.light;
      expect(
        theme.textTheme.titleLarge?.color,
        VoidPalette.light.textPrimary,
        reason: 'textPrimary light = 0xFF171923 (tinta gelap di atas putih)',
      );
      expect(
        theme.textTheme.titleLarge?.color,
        isNot(VoidPalette.dark.textPrimary),
        reason: 'REGRESI BUG: tinta 0xFFF5F5F7 di tema terang = putih di putih',
      );
    });

    test('dark theme memakai tinta palet gelap', () {
      final theme = VoidTheme.dark;
      expect(
        theme.textTheme.titleLarge?.color,
        VoidPalette.dark.textPrimary,
        reason: 'textPrimary dark = 0xFFF5F5F7',
      );
    });

    test('textTheme menutup slot inti (display/body/caption)', () {
      final theme = VoidTheme.light;
      expect(theme.textTheme.displayLarge, isNotNull);
      expect(theme.textTheme.displayMedium, isNotNull);
      expect(theme.textTheme.bodyMedium, isNotNull);
      expect(theme.textTheme.bodySmall, isNotNull);
      expect(theme.textTheme.labelLarge, isNotNull);
    });
  });
}
