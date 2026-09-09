import 'package:flutter/material.dart';

/// Tipografi Void Scriptor.
///
/// Kontrak warna (regresi putih-di-atas-putih, 2026-09-09): style di sini
/// TIDAK mengunci `color` — tinta diambil dari cascade `DefaultTextStyle`
/// yang dipimpin `ThemeData.textTheme` (dipasang dari `VoidPalette` aktif,
/// lihat `VoidTheme`). Menulis warna di sini akan mematahkan tema terang.
abstract final class VoidTypography {
  static const displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const displayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const title = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const label = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);

  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
}
