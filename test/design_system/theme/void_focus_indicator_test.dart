// Fokus keyboard harus terlihat (WCAG 2.2 - 2.4.7 Focus Visible Level AA,
// dan 1.4.11 Non-text Contrast: indikator fokus butuh >= 3:1).
//
// Gap yang ditutup file ini: VoidTheme tidak memasang `filledButtonTheme`
// sama sekali, sehingga tombol memakai default Material 3. Di
// filled_button.dart (SDK) default itu HANYA overlayColor
// `onPrimary.withOpacity(0.1)` pada state focused - tidak ada focus ring.
// Probe piksel 2026-10-01 mengukur delta hanya 1.19-1.32:1 di 12 kombinasi
// preset x mode: fokus praktis tidak terlihat.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/design_system/theme/void_palette.dart';
import 'package:void_scriptor/design_system/theme/void_theme_variant.dart';
import 'package:void_scriptor/design_system/widgets/void_button.dart';

const focusIndicatorThreshold = 3.0;

double _lin(double c) {
  final x = c / 255.0;
  return x <= 0.03928
      ? x / 12.92
      : math.pow((x + 0.055) / 1.055, 2.4).toDouble();
}

double _lum(Color c) =>
    0.2126 * _lin(c.r * 255.0) +
    0.7152 * _lin(c.g * 255.0) +
    0.0722 * _lin(c.b * 255.0);

double _ratio(Color a, Color b) {
  final l1 = _lum(a), l2 = _lum(b);
  final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

String _hex(Color? c) {
  if (c == null) return '<null>';
  final v =
      (c.r * 255).round() << 16 |
      (c.g * 255).round() << 8 |
      (c.b * 255).round();
  return '#${v.toRadixString(16).padLeft(6, '0')}';
}

Future<Color> _pixelAt(GlobalKey key, Offset local) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final w = image.width;
  final x = local.dx.round().clamp(0, w - 1);
  final y = local.dy.round().clamp(0, image.height - 1);
  final i = (y * w + x) * 4;
  return Color.fromARGB(
    255,
    data!.getUint8(i),
    data.getUint8(i + 1),
    data.getUint8(i + 2),
  );
}

void main() {
  for (final variant in VoidThemeVariant.values) {
    for (final mode in ['dark', 'light']) {
      testWidgets('${variant.name}/$mode: focus ring >= 3:1 & terlihat', (
        tester,
      ) async {
        final theme = mode == 'dark' ? variant.darkTheme : variant.lightTheme;
        final key = GlobalKey();

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: RepaintBoundary(
              key: key,
              child: Scaffold(
                body: Center(
                  child: VoidButton(label: 'Simpan', onPressed: () {}),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Warna ring yang benar-benar diresolusi theme untuk state focused.
        final ctx = tester.element(find.byType(FilledButton));
        final themeStyle = FilledButtonTheme.of(ctx).style;
        final ring = themeStyle?.side?.resolve({WidgetState.focused});

        expect(
          ring,
          isNotNull,
          reason:
              '${variant.name}/$mode: theme tidak memasang focus ring '
              'untuk FilledButton; fokus hanya mengandalkan overlay M3 '
              '(terukur 1.19-1.32:1).',
        );

        final ratio = _ratio(ring!.color, theme.scaffoldBackgroundColor);
        expect(
          ratio,
          greaterThanOrEqualTo(focusIndicatorThreshold),
          reason:
              '${variant.name}/$mode: ring ${_hex(ring.color)} vs '
              'background ${_hex(theme.scaffoldBackgroundColor)} = '
              '${ratio.toStringAsFixed(2)}:1',
        );

        // Bukti ring benar-benar digambar DAN kontrasnya memadai, diukur
        // dari piksel hasil render - bukan dari config theme saja.
        final btn = tester.getRect(find.byType(FilledButton));
        final outerEdge = Offset(btn.left + 1, btn.center.dy);

        // Cincin dalam: pas di tengah cincin luar (lebar 3px).
        final innerEdge = Offset(btn.left + focusRingWidth + 1, btn.center.dy);

        Color? idleOuter = const Color(0xFF000000);
        Color? focusedOuter = const Color(0xFF000000);
        Color? focusedInner = const Color(0xFF000000);
        await tester.runAsync(() async {
          idleOuter = await _pixelAt(key, outerEdge);
        });

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        await tester.runAsync(() async {
          focusedOuter = await _pixelAt(key, outerEdge);
          focusedInner = await _pixelAt(key, innerEdge);
        });

        final bg = theme.scaffoldBackgroundColor;
        final drawnRatio = _ratio(focusedOuter!, bg);
        // ignore: unnecessary_non_null_assertion

        expect(
          idleOuter,
          isNot(equals(focusedOuter)),
          reason:
              '${variant.name}/$mode: piksel tepi tombol tidak berubah '
              'saat fokus - cincin luar tidak digambar.',
        );
        expect(
          drawnRatio,
          greaterThanOrEqualTo(focusIndicatorThreshold),
          reason:
              '${variant.name}/$mode: cincin luar yang benar-benar '
              'dirender ${_hex(focusedOuter)} vs background ${_hex(bg)} = '
              '${drawnRatio.toStringAsFixed(2)}:1',
        );
        expect(
          focusedInner,
          isNot(equals(focusedOuter)),
          reason:
              '${variant.name}/$mode: cincin dalam tidak digambar '
              '(sama dengan cincin luar ${_hex(focusedOuter)}) - '
              'cincin dalam akan hilang di atas fill primary.',
        );
      });
    }
  }
}
