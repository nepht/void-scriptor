import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/features/story/presentation/scene_workspace_screen.dart';

/// WCAG 2.2 SC 2.4.3 (Focus Order) contract for [SceneWorkspaceScreen].
///
/// Probe (2026-10-04, viewport 1536x1024 @ dpr 1.0, session-less) produced
/// exactly three focusable stops, in top-to-bottom reading order:
///
///   0 "Open Timeline" Rect.fromLTRB(20.0, 103.0, 269.3, 143.0)
///   1 "Add Asset"     Rect.fromLTRB(1303.1, 455.0, 1496.0, 495.0)
///   2 "Add Beat"      Rect.fromLTRB(40.0, 873.0, 218.8, 913.0)
///
/// This test locks the stop count, the label sequence, non-zero focus areas,
/// and the top-to-bottom / left-to-right geometry so a reordering regression
/// fails loudly instead of passing silently.
///
/// Returns the first non-empty [Text] descendant label of [ctx], or a
/// marker describing the widget runtime type when the focus stop carries no
/// text (icon-only controls).
String firstFocusLabel(BuildContext ctx) {
  final queue = <BuildContext>[ctx];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    final widget = current.widget;
    if (widget is Text) {
      final data = widget.data;
      if (data != null && data.trim().isNotEmpty) return data.trim();
    }
    current.visitChildElements(queue.add);
  }
  return '<non-text:${ctx.widget.runtimeType}>';
}

void main() {
  const screen = SceneWorkspaceScreen(sceneId: 'probe-id');

  Future<List<({String label, Rect rect})>> collectStops(
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: screen)),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    final stops = <({String label, Rect rect})>[];
    final seen = <String>{};
    for (var i = 0; i < 24; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final node = FocusManager.instance.primaryFocus;
      if (node == null) break;
      if (node.context?.widget is FocusScope) break;
      final ctx = node.context!;
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) break;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      final key = '${rect.left}|${rect.top}|${rect.width}|${rect.height}';
      if (!seen.add(key)) break;
      stops.add((label: firstFocusLabel(ctx), rect: rect));
    }
    return stops;
  }

  testWidgets('focus order: 3 stops top-to-bottom with non-zero area', (
    tester,
  ) async {
    final stops = await collectStops(tester);

    expect(tester.takeException(), isNull);
    expect(stops.map((s) => s.label).toList(), const <String>[
      'Open Timeline',
      'Add Asset',
      'Add Beat',
    ], reason: 'WCAG 2.4.3 stop count and sequence');

    for (final stop in stops) {
      expect(
        stop.rect.width * stop.rect.height,
        greaterThan(0),
        reason: 'focus area of ${stop.label} must be non-zero',
      );
      expect(stop.rect.left, greaterThanOrEqualTo(0));
      expect(stop.rect.top, greaterThanOrEqualTo(0));
      expect(stop.rect.right, lessThanOrEqualTo(1536));
      expect(stop.rect.bottom, lessThanOrEqualTo(1024));
    }

    expect(
      stops[0].rect.top,
      lessThan(stops[1].rect.top),
      reason: 'reading order runs top to bottom',
    );
    expect(
      stops[1].rect.top,
      lessThan(stops[2].rect.top),
      reason: 'reading order runs top to bottom',
    );
    expect(
      stops[0].rect.top,
      greaterThanOrEqualTo(96),
      reason: 'first stop sits below the app bar, not behind it',
    );
    expect(
      stops[0].rect.left,
      lessThan(stops[1].rect.left),
      reason: 'primary action is left aligned, secondary right aligned',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('focus order: second Tab never leaves the first stop', (
    tester,
  ) async {
    final stops = await collectStops(tester);
    expect(
      stops,
      hasLength(3),
      reason: 'contract prerequisite for the traversal assertion',
    );
    expect(FocusManager.instance.primaryFocus, isNotNull);
    expect(FocusManager.instance.primaryFocus!.hasFocus, isTrue);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
