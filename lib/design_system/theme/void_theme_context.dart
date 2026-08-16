import 'package:flutter/material.dart';

import 'void_palette.dart';

/// Getter nyaman untuk membaca palet tema aktif dari [BuildContext].
///
/// Pemakaian: `final p = context.palette; p.background; p.textPrimary; ...`
extension VoidThemeContext on BuildContext {
  VoidPalette get palette =>
      Theme.of(this).extension<VoidPalette>() ?? VoidPalette.dark;
}
