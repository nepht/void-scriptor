import 'package:flutter/material.dart';

/// Palet warna tema terang (light mode) untuk Void Scriptor.
///
/// Aksen (ungu) tetap sama dengan tema gelap agar identitas visual
/// konsisten; hanya warna permukaan/teks/latar yang dibalik.
abstract final class VoidColorsLight {
  // Background
  static const background = Color(0xFFF6F7FB);
  static const backgroundSecondary = Color(0xFFEDEFF6);

  // Surfaces
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF1F2F8);
  static const surfaceHover = Color(0xFFE7E9F2);

  // Panels
  static const panel = Color(0xFFF8F9FC);
  static const panelSecondary = Color(0xFFF0F1F7);

  // Borders
  static const border = Color(0xFFD5D8E4);
  static const borderSoft = Color(0xFFE3E5EE);
  static const divider = Color(0xFFE6E8F0);

  // Typography
  static const textPrimary = Color(0xFF171923);
  static const textSecondary = Color(0xFF4A4E60);
  static const textMuted = Color(0xFF85899C);
  static const textDisabled = Color(0xFFB4B8C6);
}
