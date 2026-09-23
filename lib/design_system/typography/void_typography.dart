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

  // Desktop shell and Character Overview typography contract.
  static const appBrand = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
  static const brandSubtitle = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w400,
  );
  static const topNavigation = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  static const sidebarTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
  static const sidebarItem = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );
  static const breadcrumb = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );
  static const primaryTab = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );
  static const activePrimaryTab = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
  static const secondaryTab = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
  static const panelTitle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
  static const smallPanelLabel = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w500,
  );
  static const characterName = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w600,
  );
  static const characterSubtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );
  static const metadataLabel = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w600,
  );
  static const metadataValue = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w400,
  );
  static const conceptTitle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
  static const conceptBody = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w400,
  );
  static const paletteLabel = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w500,
  );
  static const hexValue = TextStyle(fontSize: 8, fontWeight: FontWeight.w400);
  static const accessoryName = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.w500,
  );
  static const accessorySubtitle = TextStyle(
    fontSize: 7,
    fontWeight: FontWeight.w400,
  );
  static const closeUpLabel = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.w500,
  );
  static const inspectorTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
  static const inspectorSectionTitle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
  static const inspectorProperty = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w400,
  );
  static const tags = TextStyle(fontSize: 9, fontWeight: FontWeight.w500);
  static const quickNotes = TextStyle(fontSize: 9, fontWeight: FontWeight.w400);
  static const prompt = TextStyle(fontSize: 9, fontWeight: FontWeight.w400);
  static const actionButton = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w500,
  );
  static const statusBar = TextStyle(fontSize: 10, fontWeight: FontWeight.w400);
}
