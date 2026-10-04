// WCAG 2.2 — 2.4.3 Focus Order contract for MergePreviewScreen (Fase 70).
//
// Probe evidence (test/features/multiverse/presentation/_probe_focus_test.dart,
// viewport 1536x1024, dpr 1.0):
//   STOP 0: "Back"    (8, 8, 40x40)
//   STOP 1: "Confirm Merge" (20, 310, 1496x40)
//   STOP 2: repeated rect (8, 8) -> traversal wraps back to the first stop.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/features/multiverse/presentation/merge_preview_screen.dart';

typedef FocusStop = ({String label, Rect rect});

Rect _rectOf(FocusNode node) {
  final ctx = node.context;
  final box = ctx?.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return Rect.zero;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Label of a focus stop: first non-Icon descendant [Text], else the nearest
/// [Tooltip] message (searched downward, then upward — IconButton wraps its
/// focus node outside its own Tooltip).
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
  testWidgets('MergePreviewScreen: Tab order is Back then Confirm Merge, '
      'top-to-bottom with non-zero focus areas', (tester) async {
    final stops = await _collectStops(
      tester,
      const MergePreviewScreen(onConfirmMerge: _noop),
    );
    expect(tester.takeException(), isNull);

    // The last stop in the list is the repeated wrap-around rect.
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

    // 1) Locked label order.
    expect(unique.map((stop) => stop.label).toList(), [
      'Back',
      'Confirm Merge',
    ]);

    // 2) Locked focus areas, both non-zero.
    for (final stop in unique) {
      expect(stop.rect, isNot(Rect.zero), reason: '${stop.label} focus area');
      expect(stop.rect.width, greaterThan(0));
      expect(stop.rect.height, greaterThan(0));
    }

    // 3) Focus area positions: top-left Back button, primary action below
    //    and to its right (top-to-bottom, left-to-right reading order).
    expect(unique[0].rect.left, 8);
    expect(unique[0].rect.top, 8);
    expect(unique[0].rect.width, 40);
    expect(unique[0].rect.height, 40);
    expect(unique[1].rect.top, greaterThan(unique[0].rect.top));
    expect(unique[1].rect.left, greaterThan(unique[0].rect.left));
    expect(unique[1].rect.width, greaterThan(1000));

    // 4) Each stop maps to a real affordance on screen: the stop's focus
    //    area sits inside the affordance's own render box (the focus node
    //    is one level deeper than the affordance widget).
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
    final confirm = find.widgetWithText(FilledButton, 'Confirm Merge');
    expect(confirm, findsOneWidget);
    final confirmRect = tester.getRect(confirm);
    final s1 = unique[1].rect;
    expect(
      s1.left >= confirmRect.left &&
          s1.top >= confirmRect.top &&
          s1.right <= confirmRect.right &&
          s1.bottom <= confirmRect.bottom,
      isTrue,
      reason: 'confirm=$confirmRect stop=$s1',
    );
  });
}

void _noop() {}
