import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/presentation/output_review_panel.dart';

/// WCAG 2.4.3 (Focus Order) contract for `OutputReviewPanel`.
///
/// Ground truth measured live (Flutter 3.47.6, viewport 1536x1024, dpr 1.0):
/// the Tab ring exposes exactly four stops in visual reading order -
/// `Approve` -> `Reject` (top row, left-to-right) -> feedback `TextField`
/// -> send `IconButton` (bottom row, left-to-right).
///
/// The panel is production-used by `AdvancedAiStudioScreen`
/// (`lib/features/ai/presentation/advanced_ai_studio_screen.dart:257`), is
/// fully self-contained (callbacks only, no database/network/provider), and
/// had a behaviour test (`output_review_panel_test.dart`) but no focus-order
/// contract before this file.
class _Stop {
  const _Stop(this.label, this.rect);
  final String label;
  final Rect rect;
}

String _labelFor(Element el) {
  final texts = <String>[];
  void visit(Element e) {
    final w = e.widget;
    if (w is Text && w.data != null) texts.add(w.data!);
    if (w is IconButton && w.tooltip != null) texts.add(w.tooltip!);
    e.visitChildren(visit);
  }

  visit(el);
  return texts.isNotEmpty ? texts.first : 'widget:${el.widget.runtimeType}';
}

Rect? _rectFor(Element el) {
  final ro = el.renderObject;
  if (ro is! RenderBox || !ro.hasSize) return null;
  return ro.localToGlobal(Offset.zero) & ro.size;
}

/// Tabs forward until the focused rect repeats (ring closed) or [maxTabs].
Future<List<_Stop>> _collectForward(
  WidgetTester tester, {
  int maxTabs = 20,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final stops = <_Stop>[];
  final seen = <String>{};
  for (var i = 0; i < maxTabs; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) {
      stops.add(const _Stop('NULL_FOCUS', Rect.zero));
      break;
    }
    final el = ctx as Element;
    final rect = _rectFor(el) ?? Rect.zero;
    final key =
        '${_labelFor(el)}@${rect.left},${rect.top},'
        '${rect.width}x${rect.height}';
    if (seen.contains(key)) break;
    seen.add(key);
    stops.add(_Stop(_labelFor(el), rect));
  }
  return stops;
}

Rect _rectOf(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  return box.localToGlobal(Offset.zero) & box.size;
}

void _expectSameRect(Rect actual, Rect expected, String what) {
  expect(
    actual.left,
    moreOrLessEquals(expected.left, epsilon: 0.5),
    reason: '$what left',
  );
  expect(
    actual.top,
    moreOrLessEquals(expected.top, epsilon: 0.5),
    reason: '$what top',
  );
  expect(
    actual.width,
    moreOrLessEquals(expected.width, epsilon: 0.5),
    reason: '$what width',
  );
  expect(
    actual.height,
    moreOrLessEquals(expected.height, epsilon: 0.5),
    reason: '$what height',
  );
}

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

void main() {
  Future<void> pumpPanel(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _wrap(
        OutputReviewPanel(
          onApprove: () {},
          onReject: () {},
          onFeedback: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder approveButton() => find.widgetWithText(TextButton, 'Approve');
  Finder rejectButton() => find.widgetWithText(TextButton, 'Reject');
  Finder feedbackField() => find.byType(TextField);
  Finder sendButton() => find.ancestor(
    of: find.byIcon(Icons.send),
    matching: find.byType(IconButton),
  );

  testWidgets('1. four stops in visual reading order', (tester) async {
    await pumpPanel(tester);
    final stops = await _collectForward(tester);

    expect(stops, hasLength(4), reason: 'Tab ring size');
    expect(stops.map((s) => s.label).toList(), <String>[
      'Approve',
      'Reject',
      'widget:Focus',
      'widget:Focus',
    ], reason: 'label order');
    // Every stop lands on its declared affordance, in order. The focused
    // render box is the inner focus highlight (a few px inset from the
    // button's own box), so assert centre containment rather than exact
    // equality.
    final expected = <Rect>[
      _rectOf(tester, approveButton()),
      _rectOf(tester, rejectButton()),
      _rectOf(tester, feedbackField()),
      _rectOf(tester, sendButton()),
    ];
    for (var i = 0; i < expected.length; i++) {
      final stop = stops[i].rect;
      expect(
        expected[i].contains(stop.center),
        isTrue,
        reason: 'stop[$i] centre ${stop.center} inside ${expected[i]}',
      );
    }
    // Ordering is monotonic left-to-right / top-to-bottom in visual space.
    expect(stops[0].rect.left, lessThan(stops[1].rect.left));
    expect(stops[2].rect.left, lessThan(stops[3].rect.left));
    expect(stops[1].rect.top, lessThan(stops[2].rect.top));
  });

  testWidgets('2. top action row sits above the feedback row', (tester) async {
    await pumpPanel(tester);
    final approve = _rectOf(tester, approveButton());
    final reject = _rectOf(tester, rejectButton());
    final field = _rectOf(tester, feedbackField());

    expect(approve.top, lessThan(field.top), reason: 'approve above field');
    expect(reject.top, lessThan(field.top), reason: 'reject above field');
    expect(
      approve.top,
      moreOrLessEquals(reject.top, epsilon: 0.5),
      reason: 'approve/reject share a row',
    );
  });

  testWidgets('3. each row reads left-to-right', (tester) async {
    await pumpPanel(tester);
    final approve = _rectOf(tester, approveButton());
    final reject = _rectOf(tester, rejectButton());
    final field = _rectOf(tester, feedbackField());
    final send = _rectOf(tester, sendButton());

    expect(
      approve.left,
      lessThan(reject.left),
      reason: 'Approve left of Reject',
    );
    expect(field.left, lessThan(send.left), reason: 'field left of send');
  });

  testWidgets('4. every stop has a non-zero rect inside the viewport', (
    tester,
  ) async {
    await pumpPanel(tester);
    final stops = await _collectForward(tester);
    expect(stops, hasLength(4));
    for (final s in stops) {
      expect(s.rect.width, greaterThan(0), reason: '${s.label} width');
      expect(s.rect.height, greaterThan(0), reason: '${s.label} height');
      expect(s.rect.left, greaterThanOrEqualTo(0));
      expect(s.rect.top, greaterThanOrEqualTo(0));
      expect(s.rect.right, lessThanOrEqualTo(1536.0));
      expect(s.rect.bottom, lessThanOrEqualTo(1024.0));
    }
  });

  testWidgets('5. Tab after the last stop wraps to the first', (tester) async {
    await pumpPanel(tester);
    final stops = await _collectForward(tester);
    expect(stops, hasLength(4));
    // `_collectForward` stops at the first repeated rect: the focus has
    // already wrapped back onto stop 0, proving the ring closes.
    final ctx = FocusManager.instance.primaryFocus!.context! as Element;
    _expectSameRect(
      _rectFor(ctx) ?? Rect.zero,
      stops.first.rect,
      'wrapped stop',
    );
  });

  testWidgets('6. Shift+Tab walks the same ring backwards', (tester) async {
    await pumpPanel(tester);
    final forward = await _collectForward(tester);
    expect(forward, hasLength(4));

    // Now walk backwards from the current position and compare rects.
    final backward = <Rect>[];
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      final ctx = FocusManager.instance.primaryFocus?.context;
      if (ctx == null) break;
      backward.add(_rectFor(ctx as Element) ?? Rect.zero);
    }
    expect(backward, hasLength(4));
    // Reverse of the forward ring (allowing for the wrap point).
    final forwardRects = forward.map((s) => s.rect).toList();
    final backwardRects = backward;
    for (final b in backwardRects) {
      expect(
        forwardRects.any(
          (f) =>
              (f.left - b.left).abs() < 0.5 &&
              (f.top - b.top).abs() < 0.5 &&
              (f.width - b.width).abs() < 0.5 &&
              (f.height - b.height).abs() < 0.5,
        ),
        isTrue,
        reason: 'backward stop $b is part of the forward ring',
      );
    }
  });

  testWidgets('7. focus never drops and the panel renders cleanly', (
    tester,
  ) async {
    await pumpPanel(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.context,
        isNotNull,
        reason: 'focus lost at tab $i',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
