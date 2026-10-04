import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_export_options_dialog.dart';

/// WCAG 2.2 - 2.4.3 Focus Order audit for the Novel workspace export dialog.
///
/// The dialog offers three character representations, a Cancel action, and a
/// confirm action that stays locked until a representation is chosen. This
/// contract locks the keyboard traversal a mouse user never has to notice:
/// which controls are reachable by Tab, in which order, whether a hidden or
/// disabled control silently occupies a stop, and that no stop is given a
/// zero-area focus rect.
///
/// Measured at 1536x1024, devicePixelRatio 1.0, before any representation is
/// chosen (Export locked, therefore not a traversal stop):
///
///   Tab 1 radio group "Reference manifest"  L=504.0 T=380.0 W=528.0 H=100.0
///   Tab 2 Cancel                            L=782.8 T=688.0 W=108.6 H=40.0
///   Tab 3 wraps back to the radio group
///
/// After arrowDown selects "Embedded snapshot", the ring gains the now-enabled
/// confirm action and re-entering the ring resumes on the SELECTED tile:
///
///   Tab 1 "Embedded snapshot"  L=504.0 T=480.0 W=528.0 H=80.0
///   Tab 2 Cancel               L=782.8 T=688.0 W=108.6 H=40.0
///   Tab 3 Export               L=899.4 T=688.0 W=132.6 H=40.0
///
/// Shift+Tab walks the same ring backwards: Cancel, radio group, Cancel, ...
/// The three representations are reached by arrow keys inside the group, not
/// by Tab, which is the correct 2.4.3 shape for a single-choice control.
///
/// Evidence: docs/evidence/wcag-2.2-audit-login-screen-2026-09-30.md

const Size _desktopViewport = Size(1536, 1024);
const int _maxStops = 12;

/// Human-readable label of the focused control: the first non-Icon Text in the
/// focused subtree, falling back to the widget type when icon-only.
String _focusLabel(BuildContext context) {
  var label = '';
  void visit(Element element) {
    if (label.isNotEmpty) return;
    final widget = element.widget;
    if (widget is Icon) return;
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      label = widget.data!.trim();
      return;
    }
    element.visitChildren(visit);
  }

  visit(context as Element);
  return label.isEmpty ? 'widget:${context.widget.runtimeType}' : label;
}

/// Global focus rect of the currently focused control, in logical pixels.
Rect _focusRect() {
  final object = FocusManager.instance.primaryFocus?.context
      ?.findRenderObject();
  if (object is! RenderBox || !object.hasSize) return Rect.zero;
  return object.localToGlobal(Offset.zero) & object.size;
}

Future<({String label, Rect rect})> _stopAfter(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
  final context = FocusManager.instance.primaryFocus?.context;
  expect(context, isNotNull, reason: 'focus must never be dropped');
  return (label: _focusLabel(context!), rect: _focusRect());
}

/// Walks the focus ring by Tab until it repeats a rect, returning every stop in
/// order. A repeated rect marks wrap-around, which is where the ring closes.
Future<List<({String label, Rect rect})>> _traceTabRing(
  WidgetTester tester,
) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < _maxStops; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) break;
    final rect = _focusRect();
    if (!seen.add('${rect.left}|${rect.top}|${rect.width}|${rect.height}')) {
      break;
    }
    stops.add((label: _focusLabel(context), rect: rect));
  }
  return stops;
}

Future<void> _shiftTab(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

bool _confirmActionEnabled(WidgetTester tester) {
  final action = find.ancestor(
    of: find.text('Export'),
    matching: find.byType(FilledButton),
  );
  expect(action, findsOneWidget);
  return tester.widget<FilledButton>(action).onPressed != null;
}

Future<void> _openDialog(WidgetTester tester) async {
  tester.view.physicalSize = _desktopViewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const WorkspaceExportOptionsDialog(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.byType(WorkspaceExportOptionsDialog), findsOneWidget);
}

/// Tab once onto the group, then choose the second representation.
Future<void> _chooseSecondRepresentation(WidgetTester tester) async {
  await _stopAfter(tester, LogicalKeyboardKey.tab);
  await _stopAfter(tester, LogicalKeyboardKey.arrowDown);
  expect(_confirmActionEnabled(tester), isTrue);
}

/// Leaves focus unscoped so the next Tab re-enters the ring from its start.
Future<void> _reenterRing(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

void main() {
  group('WorkspaceExportOptionsDialog focus order (WCAG 2.4.3)', () {
    testWidgets('the dialog offers three representations as one group', (
      tester,
    ) async {
      await _openDialog(tester);

      final tiles = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString().startsWith('RadioListTile'),
      );
      expect(tiles, findsNWidgets(3));

      // A single Tab reaches the group; the three options are not Tab stops.
      final group = await _stopAfter(tester, LogicalKeyboardKey.tab);
      expect(group.label, 'Reference manifest');
    });

    testWidgets('Tab order before a choice is radio group then Cancel', (
      tester,
    ) async {
      await _openDialog(tester);
      expect(_confirmActionEnabled(tester), isFalse);

      final stops = await _traceTabRing(tester);

      expect(stops.map((stop) => stop.label).toList(), <String>[
        'Reference manifest',
        'Cancel',
      ]);
      expect(stops, hasLength(2));
    });

    testWidgets('the locked confirm action is not a Tab stop', (tester) async {
      await _openDialog(tester);
      expect(_confirmActionEnabled(tester), isFalse);

      final stops = await _traceTabRing(tester);

      expect(
        stops.map((stop) => stop.label),
        isNot(contains('Export')),
        reason: 'a disabled control must not consume a Tab stop',
      );
    });

    testWidgets('Tab order after a choice is group, Cancel, then Export', (
      tester,
    ) async {
      await _openDialog(tester);
      await _chooseSecondRepresentation(tester);
      await _reenterRing(tester);

      final stops = await _traceTabRing(tester);

      expect(stops.map((stop) => stop.label).toList(), <String>[
        'Embedded snapshot',
        'Cancel',
        'Export',
      ]);
      expect(stops, hasLength(3));
    });

    testWidgets('arrow keys walk every representation and enable confirm', (
      tester,
    ) async {
      await _openDialog(tester);
      expect(_confirmActionEnabled(tester), isFalse);

      final first = await _stopAfter(tester, LogicalKeyboardKey.tab);
      expect(first.label, 'Reference manifest');
      expect(_confirmActionEnabled(tester), isFalse);

      final second = await _stopAfter(tester, LogicalKeyboardKey.arrowDown);
      expect(second.label, 'Embedded snapshot');
      expect(_confirmActionEnabled(tester), isTrue);

      final third = await _stopAfter(tester, LogicalKeyboardKey.arrowDown);
      expect(third.label, 'Fork');
      expect(_confirmActionEnabled(tester), isTrue);

      // The group wraps, so no representation is unreachable by keyboard.
      final wrapped = await _stopAfter(tester, LogicalKeyboardKey.arrowDown);
      expect(wrapped.label, 'Reference manifest');
    });

    testWidgets('Shift+Tab walks the same ring backwards', (tester) async {
      await _openDialog(tester);

      expect(
        (await _traceTabRing(tester)).map((stop) => stop.label).toList(),
        <String>['Reference manifest', 'Cancel'],
      );

      await _reenterRing(tester);

      final backwards = <String>[];
      for (var i = 0; i < 2; i++) {
        await _shiftTab(tester);
        final context = FocusManager.instance.primaryFocus?.context;
        expect(context, isNotNull);
        backwards.add(_focusLabel(context!));
      }

      expect(backwards, <String>['Cancel', 'Reference manifest']);
    });

    testWidgets('content stop sits above the action row, left to right', (
      tester,
    ) async {
      await _openDialog(tester);
      await _chooseSecondRepresentation(tester);
      await _reenterRing(tester);

      final stops = await _traceTabRing(tester);
      expect(stops, hasLength(3));

      final content = stops.first;
      final actions = stops.skip(1).toList();

      // The choice group sits strictly above the action row.
      expect(actions.first.rect.top, greaterThan(content.rect.top));
      for (final action in actions) {
        expect(
          action.rect.top,
          greaterThanOrEqualTo(content.rect.bottom),
          reason: 'the action row must start below the choice group',
        );
      }

      // Actions run left to right in their declared order.
      expect(actions[0].rect.left, lessThan(actions[1].rect.left));
    });

    testWidgets('every stop has a non-zero focus rect', (tester) async {
      await _openDialog(tester);
      await _chooseSecondRepresentation(tester);
      await _reenterRing(tester);

      final stops = await _traceTabRing(tester);
      expect(stops, isNotEmpty);
      for (final stop in stops) {
        expect(stop.rect.width, greaterThan(0), reason: stop.label);
        expect(stop.rect.height, greaterThan(0), reason: stop.label);
      }
    });

    testWidgets('focus stays inside the dialog and never drops to null', (
      tester,
    ) async {
      await _openDialog(tester);
      await _chooseSecondRepresentation(tester);

      for (var i = 0; i < 8; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(
          FocusManager.instance.primaryFocus?.context,
          isNotNull,
          reason: 'Tab must never leave the ring without a target',
        );
      }

      expect(find.byType(WorkspaceExportOptionsDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
