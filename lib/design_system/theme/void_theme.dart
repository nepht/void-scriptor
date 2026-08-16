import 'package:flutter/material.dart';

import '../colors/void_colors.dart';
import '../colors/void_colors_light.dart';

abstract final class VoidTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: VoidColors.primary,
      secondary: VoidColors.secondary,
      surface: VoidColors.surface,
      error: VoidColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: VoidColors.textPrimary,
      onError: Colors.white,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: VoidColors.background,
      dividerColor: VoidColors.divider,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VoidColors.surfaceElevated,
        hintStyle: const TextStyle(color: VoidColors.textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VoidColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VoidColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VoidColors.primary),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: VoidColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: VoidColors.border),
        ),
        textStyle: const TextStyle(color: VoidColors.textPrimary, fontSize: 12),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(10),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return VoidColors.textMuted;
          }
          return VoidColors.border;
        }),
      ),
    );
  }

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: VoidColors.primary,
      secondary: VoidColors.secondary,
      surface: VoidColorsLight.surface,
      error: VoidColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: VoidColorsLight.textPrimary,
      onError: Colors.white,
    );

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: VoidColorsLight.background,
      dividerColor: VoidColorsLight.divider,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VoidColorsLight.surfaceElevated,
        hintStyle: const TextStyle(
          color: VoidColorsLight.textMuted,
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VoidColorsLight.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VoidColorsLight.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VoidColors.primary),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: VoidColorsLight.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: VoidColorsLight.border),
        ),
        textStyle: const TextStyle(
          color: VoidColorsLight.textPrimary,
          fontSize: 12,
        ),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(10),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return VoidColorsLight.textMuted;
          }
          return VoidColorsLight.border;
        }),
      ),
    );
  }
}
