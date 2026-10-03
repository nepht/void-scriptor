import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/presentation/performance_preview_screen.dart';

void main() {
  testWidgets('mengunci urutan fokus Performance Preview', (tester) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: PerformancePreviewScreen())),
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
      final label = _nearestTextLabel(tester, rect);
      stops.add((label: label, rect: rect));
    }

    expect(stops, hasLength(5));
    expect(
      stops.map((stop) => stop.label),
      equals(<String>[
        'High Quality Hair',
        'Heavy VFX',
        'Ray Tracing',
        'High Resolution Shadows',
        'Crowd Detail',
      ]),
    );
    for (final stop in stops) {
      expect(stop.rect.width, greaterThan(0));
      expect(stop.rect.height, greaterThan(0));
    }
    for (var i = 1; i < stops.length; i++) {
      expect(stops[i].rect.top, greaterThan(stops[i - 1].rect.top));
    }
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
    final candidateDistance = (rect.center - focusRect.center).distance;
    if (candidateDistance < distance) {
      distance = candidateDistance;
      nearest = text.data ?? '';
    }
  }
  return nearest;
}
