import 'package:flutter/material.dart';

import 'void_focus_ring.dart';
import 'void_palette.dart';

/// Pembangun tema Void Scriptor.
///
/// Kontras (regresi 2026-09-09): `textTheme` dipasang dari [palette] aktif
/// sehingga tinta teks selalu kontras terhadap latar tema — tidak ada lagi
/// warna hardcode tema gelap pada tema terang.
abstract final class VoidTheme {
  /// Tema gelap identitas Void (default). Dipertahankan agar pemakai lama
  /// `VoidTheme.dark`/`VoidTheme.light` tetap berfungsi.
  static ThemeData get dark => buildDark(VoidPalette.dark);
  static ThemeData get light => buildLight(VoidPalette.light);

  /// Pasangan tinta [VoidPalette.textPrimary] ke slot textTheme inti.
  static TextTheme textThemeFrom(VoidPalette palette) {
    final ink = palette.textPrimary;
    final inkSecondary = palette.textSecondary;
    final inkMuted = palette.textMuted;
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: ink,
      ),
      displayMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: ink,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 15, height: 1.45, color: ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: inkSecondary),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: inkMuted),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: inkSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: inkMuted,
      ),
    );
  }

  static ThemeData buildDark(VoidPalette palette) {
    final scheme = ColorScheme.dark(
      primary: palette.primary,
      secondary: palette.secondary,
      surface: palette.surface,
      error: palette.danger,
      onPrimary: onAccentForeground(palette.primary),
      onSecondary: onAccentForeground(palette.secondary),
      onSurface: palette.textPrimary,
      onError: onAccentForeground(palette.danger),
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      extensions: [palette],
      scaffoldBackgroundColor: palette.background,
      dividerColor: palette.divider,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,

      // Fokus tombol: cincin luar via `side`, cincin dalam via painter.
      filledButtonTheme: FilledButtonThemeData(
        style: _voidFocusButtonStyle(palette),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceElevated,
        hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.primary),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: palette.border),
        ),
        textStyle: TextStyle(color: palette.textPrimary, fontSize: 12),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(10),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return palette.textMuted;
          }
          return palette.border;
        }),
      ),
    );
  }

  static ThemeData buildLight(VoidPalette palette) {
    final scheme = ColorScheme.light(
      primary: palette.primary,
      secondary: palette.secondary,
      surface: palette.surface,
      error: palette.danger,
      onPrimary: onAccentForeground(palette.primary),
      onSecondary: onAccentForeground(palette.secondary),
      onSurface: palette.textPrimary,
      onError: onAccentForeground(palette.danger),
    );

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: scheme,
      extensions: [palette],
      scaffoldBackgroundColor: palette.background,
      dividerColor: palette.divider,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      textTheme: textThemeFrom(palette),

      // Fokus tombol: cincin luar via `side`, cincin dalam via painter.
      filledButtonTheme: FilledButtonThemeData(
        style: _voidFocusButtonStyle(palette),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceElevated,
        hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.primary),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: palette.border),
        ),
        textStyle: TextStyle(color: palette.textPrimary, fontSize: 12),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(10),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return palette.textMuted;
          }
          return palette.border;
        }),
      ),
    );
  }
}

/// Fokus keyboard harus terlihat (WCAG 2.2 - 2.4.7 Focus Visible, dan
/// 1.4.11 Non-text Contrast >= 3:1).
///
/// Default Material 3 tidak menyediakan apa pun untuk ini: pada state
/// focused yang berubah hanya `overlayColor` `onPrimary.withOpacity(0.1)`,
/// dan `ButtonStyleButton` tidak menggambar outline fokus. Probe piksel
/// 2026-10-01 mengukur perubahan 1.19-1.32:1 di 12 kombinasi preset x mode,
/// jauh di bawah 3:1.
///
/// Cincin dua nada dipakai karena satu warna tidak mungkin cukup: `primary`
/// duduk di luminansi menengah sehingga kandidat token apa pun gagal minimal
/// di satu sisi (terbaik `textPrimary` 15.46:1 vs background tetapi 2.11:1 vs
/// fill). Cincin luar menempel ke halaman, cincin dalam menempel ke fill.
ButtonStyle _voidFocusButtonStyle(VoidPalette palette) {
  return ButtonStyle(
    side: WidgetStateProperty.resolveWith((states) {
      if (!states.contains(WidgetState.focused)) return null;
      return BorderSide(
        color: focusRingOuter(palette),
        width: focusRingWidth,
      );
    }),
    // Slot painter tidak ada di ButtonStyle; slot yang tersedia adalah
    // `foregroundBuilder` (ButtonLayerBuilder), fungsi yang menerima state
    // tombol lalu mengembalikan Widget. Cincin dalam digambar lewat
    // CustomPaint di atas isi tombol.
    foregroundBuilder: (BuildContext context, Set<WidgetState> states,
        Widget? child) {
      if (!states.contains(WidgetState.focused)) return child!;
      return CustomPaint(
        foregroundPainter: VoidFocusRingPainter(
          innerColor: focusRingInner(palette),
        ),
        child: child,
      );
    },
  );
}
