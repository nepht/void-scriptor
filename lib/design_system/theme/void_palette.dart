import 'package:flutter/material.dart';

/// Palet warna Void Scriptor sebagai [ThemeExtension], sehingga dapat
/// beralih antara tema gelap dan terang lewat `Theme.of(context)`.
///
/// Migrasi dari `VoidColors` (static const): pemakai kini membaca
/// `context.palette.<field>` alih-alih `VoidColors.<field>`.
@immutable
class VoidPalette extends ThemeExtension<VoidPalette> {
  const VoidPalette({
    required this.background,
    required this.backgroundSecondary,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceHover,
    required this.panel,
    required this.panelSecondary,
    required this.border,
    required this.borderSoft,
    required this.divider,
    required this.primary,
    required this.primaryBright,
    required this.primaryDark,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  // Background
  final Color background;
  final Color backgroundSecondary;

  // Surfaces
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceHover;

  // Panels
  final Color panel;
  final Color panelSecondary;

  // Borders
  final Color border;
  final Color borderSoft;
  final Color divider;

  // Accent
  final Color primary;
  final Color primaryBright;
  final Color primaryDark;
  final Color secondary;

  // Typography
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;

  // Status
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  static const transparent = Colors.transparent;
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  /// Palet tema gelap (nilai identik dengan `VoidColors` lama).
  static const VoidPalette dark = VoidPalette(
    background: Color(0xFF090A0F),
    backgroundSecondary: Color(0xFF0E1017),
    surface: Color(0xFF12141D),
    surfaceElevated: Color(0xFF171A25),
    surfaceHover: Color(0xFF1D2030),
    panel: Color(0xFF10121A),
    panelSecondary: Color(0xFF151823),
    border: Color(0xFF272A38),
    borderSoft: Color(0xFF1D202C),
    divider: Color(0xFF202330),
    primary: Color(0xFF8B5CF6),
    primaryBright: Color(0xFFA78BFA),
    primaryDark: Color(0xFF6D3DEB),
    secondary: Color(0xFF6366F1),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFFB7BBC8),
    textMuted: Color(0xFF777C8F),
    textDisabled: Color(0xFF505466),
    success: Color(0xFF31C48D),
    warning: Color(0xFFF4B740),
    danger: Color(0xFFF05252),
    info: Color(0xFF3F83F8),
  );

  /// Palet tema terang (nilai identik dengan `VoidColorsLight` lama).
  static const VoidPalette light = VoidPalette(
    background: Color(0xFFF6F7FB),
    backgroundSecondary: Color(0xFFEDEFF6),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF1F2F8),
    surfaceHover: Color(0xFFE7E9F2),
    panel: Color(0xFFF8F9FC),
    panelSecondary: Color(0xFFF0F1F7),
    border: Color(0xFFD5D8E4),
    borderSoft: Color(0xFFE3E5EE),
    divider: Color(0xFFE6E8F0),
    primary: Color(0xFF8B5CF6),
    primaryBright: Color(0xFF7C3AED),
    primaryDark: Color(0xFF6D3DEB),
    secondary: Color(0xFF6366F1),
    textPrimary: Color(0xFF171923),
    textSecondary: Color(0xFF4A4E60),
    textMuted: Color(0xFF85899C),
    textDisabled: Color(0xFFB4B8C6),
    success: Color(0xFF0E9F6E),
    warning: Color(0xFFC27803),
    danger: Color(0xFFE02424),
    info: Color(0xFF1A56DB),
  );

  @override
  VoidPalette copyWith({
    Color? background,
    Color? backgroundSecondary,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceHover,
    Color? panel,
    Color? panelSecondary,
    Color? border,
    Color? borderSoft,
    Color? divider,
    Color? primary,
    Color? primaryBright,
    Color? primaryDark,
    Color? secondary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return VoidPalette(
      background: background ?? this.background,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      panel: panel ?? this.panel,
      panelSecondary: panelSecondary ?? this.panelSecondary,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      divider: divider ?? this.divider,
      primary: primary ?? this.primary,
      primaryBright: primaryBright ?? this.primaryBright,
      primaryDark: primaryDark ?? this.primaryDark,
      secondary: secondary ?? this.secondary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  VoidPalette lerp(VoidPalette? other, double t) {
    if (other is! VoidPalette) return this;
    return VoidPalette(
      background: Color.lerp(background, other.background, t)!,
      backgroundSecondary:
          Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelSecondary: Color.lerp(panelSecondary, other.panelSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSoft: Color.lerp(borderSoft, other.borderSoft, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryBright: Color.lerp(primaryBright, other.primaryBright, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}
