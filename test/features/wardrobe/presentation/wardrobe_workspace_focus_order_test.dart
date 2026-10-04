import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/features/wardrobe/presentation/wardrobe_workspace_screen.dart';

// WCAG 2.2 2.4.3 (Focus Order) contract for [WardrobeWorkspaceScreen].
//
// The screen renders a [WardrobeHeader] with two icon actions (history,
// overflow menu) above a read-only detail body. The contract locks the
// number of keyboard stops, their labels, their left-to-right order in
// the header band, and a non-zero focus rectangle for every stop.

String _labelOf(Element context) {
  String? text;
  String? icon;
  void visit(Element element) {
    final widget = element.widget;
    if (widget is Icon) {
      icon ??= 'icon:0x${widget.icon!.codePoint.toRadixString(16)}';
      return;
    }
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      text ??= widget.data!.trim();
      return;
    }
    element.visitChildren(visit);
  }

  visit(context);
  return text ?? icon ?? 'widget:${context.widget.runtimeType}';
}

({String label, Rect rect}) _focusSnapshot() {
  final context = FocusManager.instance.primaryFocus!.context! as Element;
  final object = context.findRenderObject();
  final rect = object is RenderBox && object.hasSize
      ? object.localToGlobal(Offset.zero) & object.size
      : Rect.zero;
  return (label: _labelOf(context), rect: rect);
}

/// Presses Tab until the focus rectangle repeats (traversal wrapped around)
/// and reports how the walk ended: `repeat` = wrapped on a seen rectangle,
/// `null-focus` = focus left the tree.
Future<({List<({String label, Rect rect})> stops, String ended})> _collectStops(
  WidgetTester tester,
) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < 14; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 50));
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) {
      return (stops: stops, ended: 'null-focus');
    }
    final snapshot = _focusSnapshot();
    final rect = snapshot.rect;
    final key = '${rect.left}|${rect.top}|${rect.width}|${rect.height}';
    if (!seen.add(key)) {
      return (stops: stops, ended: 'repeat');
    }
    stops.add(snapshot);
  }
  return (stops: stops, ended: 'max-stops');
}

void main() {
  testWidgets(
    'WardrobeWorkspaceScreen locks focus order: 2 header actions, left-to-right (2.4.3)',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WardrobeWorkspaceScreen(wardrobeId: 'ward-1'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final walk = await _collectStops(tester);

      // 1. Stop count: exactly two interactive stops, and the walk really
      // wrapped around instead of being truncated by the iteration cap.
      expect(
        walk.stops,
        hasLength(2),
        reason:
            'expected 2 focus stops, got ${walk.stops.length}: '
            '${walk.stops.map((stop) => stop.label).toList()}',
      );
      expect(
        walk.ended,
        'repeat',
        reason: 'traversal must wrap on a seen rect',
      );

      // 2. Labels: history action first, overflow-menu action second.
      expect(walk.stops.map((stop) => stop.label).toList(), <String>[
        'icon:0x${Icons.history.codePoint.toRadixString(16)}',
        'icon:0x${Icons.more_horiz.codePoint.toRadixString(16)}',
      ]);

      // 3. Position property: same header row, strictly left-to-right.
      final first = walk.stops[0].rect;
      final second = walk.stops[1].rect;
      expect(first.left, lessThan(second.left));
      expect(first.top, moreOrLessEquals(second.top));
      expect(first.top, inInclusiveRange(0, 160));

      // 4. Every focus target has a non-zero focusable area.
      for (final stop in walk.stops) {
        expect(stop.rect.width * stop.rect.height, greaterThan(0));
      }

      expect(tester.takeException(), isNull);
    },
  );
}
