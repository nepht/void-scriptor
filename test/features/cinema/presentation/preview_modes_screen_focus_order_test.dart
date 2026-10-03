import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/presentation/preview_modes_screen.dart';

/// Kontrak WCAG 2.4.3 (Focus Order) untuk Preview Modes Screen.
///
/// Layar ini menampilkan lima ChoiceChip di dalam satu Wrap. Kontrak mengunci
/// jumlah stop fokus, urutan label, dan geometri posisinya (satu baris, kiri ke
/// kanan, area fokus non-zero).
void main() {
  testWidgets('mengunci urutan fokus Preview Modes Screen', (tester) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: PreviewModesScreen())),
    );

    final stops = <({String label, Rect rect})>[];
    final seenRects = <String>{};
    for (var i = 0; i < 20; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focus = FocusManager.instance.primaryFocus;
      final object = focus?.context?.findRenderObject();
      if (object is! RenderBox || !object.hasSize) continue;
      final rect = object.localToGlobal(Offset.zero) & object.size;
      final rectKey = '${rect.left},${rect.top},${rect.width},${rect.height}';
      if (!seenRects.add(rectKey)) break;
      stops.add((label: _nearestTextLabel(tester, rect), rect: rect));
    }

    // Jumlah stop fokus: lima chip, tidak ada stop tambahan dari AppBar.
    expect(stops, hasLength(5));
    expect(
      stops.map((stop) => stop.label),
      equals(<String>[
        'Storyboard',
        'Animatic',
        'Low Quality',
        'Real-Time',
        'Final Preview',
      ]),
    );

    // Area fokus tidak nol pada setiap stop.
    for (final stop in stops) {
      expect(stop.rect.width, greaterThan(0));
      expect(stop.rect.height, greaterThan(0));
    }

    // Kelima chip berada pada satu baris Wrap: koordinat top sama.
    final rowTop = stops.first.rect.top;
    for (final stop in stops) {
      expect(stop.rect.top, rowTop);
    }

    // Urutan fokus mengikuti urutan visual kiri ke kanan (bukan urutan baca
    // terbalik atau acak).
    for (var i = 1; i < stops.length; i++) {
      expect(stops[i].rect.left, greaterThan(stops[i - 1].rect.left));
    }

    // Baris chip berada di bawah AppBar dan tidak keluar dari viewport.
    expect(stops.first.rect.top, greaterThan(0));
    expect(stops.last.rect.right, lessThan(1536));

    expect(tester.takeException(), isNull);
  });
}

String _nearestTextLabel(WidgetTester tester, Rect focusRect) {
  var nearest = '';
  var distance = double.infinity;
  for (final element in find.byType(Text).evaluate()) {
    final text = element.widget as Text;
    final object = element.renderObject;
    if (object is! RenderBox || !object.hasSize) continue;
    final rect = object.localToGlobal(Offset.zero) & object.size;
    final center = rect.center;
    final d =
        (center.dx - focusRect.center.dx).abs() +
        (center.dy - focusRect.center.dy).abs();
    if (d < distance) {
      distance = d;
      nearest = text.data ?? '';
    }
  }
  return nearest;
}
