// WCAG 2.2 — 2.4.3 Focus Order contract for MultiverseGraphScreen (Fase 72).
//
// Probe evidence (test/features/multiverse/presentation/_probe_focus_test.dart,
// viewport 1536x1024, devicePixelRatio 1.0):
//   STOP 0: "Back"   (8, 8, 40x40)      inside BackButton (4,4,52x52)
//   STOP 1: "Slider" (105, 72, 1391x48) == Slider rect (105,72)-(1496,120)
//   STOP 2: repeated rect (8, 8, 40x40) -> traversal wraps to the first stop.
//
// The screen itself contributes one body control (the Zoom Slider); the
// AppBar's automatic BackButton is the second interactive element, so the
// traversal is exactly two unique stops before it wraps.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/features/multiverse/presentation/multiverse_graph_screen.dart';

typedef FocusStop = ({String label, Rect rect});

const _expectedLabels = ['Back', 'Slider'];

Rect _rectOf(FocusNode node) {
  final ctx = node.context;
  final box = ctx?.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return Rect.zero;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Label of a focus stop: first non-Icon descendant [Text], else the nearest
/// [Tooltip] message (searched downward, then upward — IconButton wraps its
/// focus node outside its own Tooltip), else the nearest ancestor that is a
/// known interactive widget, else the widget type.
String _labelOf(FocusNode node) {
  final ctx = node.context;
  if (ctx == null) return '<no-context>';
  final texts = <String>[];
  final tooltips = <String>[];
  final queue = <BuildContext>[ctx];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    final widget = current.widget;
    if (widget is Icon) continue;
    if (widget is Text) {
      final data = widget.data;
      if (data != null && data.trim().isNotEmpty) texts.add(data.trim());
    }
    if (widget is Tooltip && widget.message != null) {
      tooltips.add(widget.message!.trim());
    }
    current.visitChildElements(queue.add);
  }
  if (texts.isNotEmpty) return texts.first;
  if (tooltips.isNotEmpty) return tooltips.first;
  ctx.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is Tooltip && widget.message != null) {
      tooltips.add(widget.message!.trim());
      return false;
    }
    return true;
  });
  if (tooltips.isNotEmpty) return tooltips.first;
  var type = '';
  ctx.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is Slider ||
        widget is IconButton ||
        widget is ButtonStyleButton ||
        widget is Switch ||
        widget is Checkbox) {
      type = widget.runtimeType.toString();
      return false;
    }
    return true;
  });
  if (type.isNotEmpty) return type;
  return 'widget:${ctx.widget.runtimeType}';
}

Future<List<FocusStop>> _collectStops(
  WidgetTester tester,
  Widget screen,
) async {
  tester.view
    ..physicalSize = const Size(1536, 1024)
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final navKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navKey,
      home: const Scaffold(body: Text('seed')),
    ),
  );
  await tester.pumpAndSettle();
  navKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => screen));
  await tester.pumpAndSettle();

  final stops = <FocusStop>[];
  final seen = <String>{};
  for (var i = 0; i < 12; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final node = FocusManager.instance.primaryFocus;
    if (node == null) break;
    final rect = _rectOf(node);
    final key =
        '${rect.left.toInt()}x${rect.top.toInt()}|'
        '${rect.width.toInt()}x${rect.height.toInt()}';
    final isRepeat = !seen.add(key);
    stops.add((label: _labelOf(node), rect: rect));
    if (isRepeat) break;
  }
  return stops;
}

void main() {
  testWidgets('MultiverseGraphScreen: Tab order is Back then Zoom Slider, '
      'top-to-bottom with non-zero focus areas', (tester) async {
    final stops = await _collectStops(tester, const MultiverseGraphScreen());
    expect(tester.takeException(), isNull);

    // The screen rendered before traversal starts.
    expect(find.text('Multiverse Graph'), findsOneWidget);
    expect(find.text('Zoom'), findsOneWidget);

    // 1) Stop count: 2 unique stops + 1 wrap-around repeat.
    expect(
      stops.length,
      3,
      reason: 'expected 2 unique stops + 1 repeat, got $stops',
    );
    final unique = stops.sublist(0, stops.length - 1);
    expect(unique, hasLength(2));
    expect(
      stops.last.rect,
      stops.first.rect,
      reason: 'traversal must wrap back to the first stop',
    );

    // 2) Locked label order.
    expect(
      unique.map((stop) => stop.label).toList(),
      _expectedLabels,
      reason: 'Tab order must follow the visible action order.',
    );

    // 3) Locked focus areas, both non-zero, and the measured geometry.
    for (final stop in unique) {
      expect(stop.rect, isNot(Rect.zero), reason: '${stop.label} focus area');
      expect(stop.rect.width, greaterThan(0));
      expect(stop.rect.height, greaterThan(0));
    }
    expect(
      unique[0].rect,
      const Rect.fromLTWH(8, 8, 40, 40),
      reason: 'BackButton focus area',
    );
    expect(
      unique[1].rect,
      const Rect.fromLTWH(105, 72, 1391, 48),
      reason: 'Zoom Slider focus area',
    );

    // 4) Reading order: AppBar back button sits above and left of the
    //    body slider (top-to-bottom, left-to-right).
    expect(unique[0].rect.top, lessThan(unique[1].rect.top));
    expect(unique[0].rect.left, lessThan(unique[1].rect.left));

    // 5) Each stop maps to a real affordance on screen.
    expect(find.byType(BackButton), findsOneWidget);
    final back = tester.getRect(find.byType(BackButton));
    final s0 = unique[0].rect;
    expect(
      s0.left >= back.left &&
          s0.top >= back.top &&
          s0.right <= back.right &&
          s0.bottom <= back.bottom,
      isTrue,
      reason: 'back=$back stop=$s0',
    );
    expect(find.byType(Slider), findsOneWidget);
    final slider = tester.getRect(find.byType(Slider));
    final s1 = unique[1].rect;
    expect(
      s1.left >= slider.left &&
          s1.top >= slider.top &&
          s1.right <= slider.right &&
          s1.bottom <= slider.bottom,
      isTrue,
      reason: 'slider=$slider stop=$s1',
    );
  });
}
