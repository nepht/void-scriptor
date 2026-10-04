import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/automation/automation_rule.dart';
import 'package:void_scriptor/features/workflow/presentation/automation_center_screen.dart';

/// WCAG 2.4.3 (Focus Order) contract for `RuleEditorScreen`
/// (`lib/features/workflow/presentation/automation_center_screen.dart`).
///
/// The editor owns a workflow-id `TextField` plus a `Save rule` `FilledButton`
/// that only materialises once the draft is complete. That makes the focus
/// chain state-dependent, which is precisely what 2.4.3 has to pin: the tab
/// order must stay reading-order once the action appears, reverse traversal
/// must not fall out of the chain, and no control may occupy a zero-area
/// focus rect.
///
/// Ground truth measured with a temporary tab-traversal probe on
/// Flutter 3.44.9, viewport 1536x1024, devicePixelRatio 1.0:
/// * empty draft -> 1 stop, `Save rule` absent;
/// * complete draft -> 2 stops, field at Rect.fromLTRB(12, 36, 1524, 60)
///   and `Save rule` at Rect.fromLTRB(12, 84, 1524, 124).

const Size _viewport = Size(1536, 1024);

/// Geometry of a focused control in global coordinates.
Rect _rectOf(FocusNode node) {
  final ctx = node.context;
  final box = ctx?.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return Rect.zero;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Stable per-stop identity. Keyed by geometry so a re-ordered or resized
/// control changes the key and fails the contract instead of passing silently.
String _stopKey(FocusNode node) {
  final rect = _rectOf(node);
  return '${rect.left.toInt()}x${rect.top.toInt()}|'
      '${rect.width.toInt()}x${rect.height.toInt()}';
}

/// Label for a focused control.
///
/// A focused `TextField` puts its focus node on a `Focus` widget that sits
/// *below* `EditableText`, so the typed value is only reachable by walking up.
/// A `FilledButton` carries its label on a descendant `Text`. Both directions
/// are searched, descendants first.
String _labelOf(FocusNode node) {
  final ctx = node.context;
  if (ctx == null) return '<no-context>';

  final descendants = <String>[];
  final queue = <BuildContext>[ctx];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    final widget = current.widget;
    if (widget is Text) {
      final data = widget.data;
      if (data != null && data.trim().isNotEmpty) {
        descendants.add(data.trim());
      }
    }
    current.visitChildElements(queue.add);
  }
  if (descendants.isNotEmpty) return descendants.first;

  EditableText? editable;
  ctx.visitAncestorElements((element) {
    if (element.widget is EditableText) {
      editable = element.widget as EditableText;
      return false;
    }
    return true;
  });
  if (editable != null) {
    final value = editable!.controller.text.trim();
    return value.isEmpty ? '<empty-field>' : value;
  }
  return '<non-text>';
}

/// Walks the focus chain until a geometry repeats, returning each stop.
Future<List<({String label, Rect rect, String key})>> collectStops(
  WidgetTester tester, {
  int maxStops = 12,
}) async {
  final seen = <String>{};
  final stops = <({String label, Rect rect, String key})>[];
  for (var i = 0; i < maxStops; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final node = FocusManager.instance.primaryFocus;
    expect(node, isNotNull, reason: 'Tab must always land on a focus node.');
    final key = _stopKey(node!);
    if (!seen.add(key)) break;
    stops.add((label: _labelOf(node), rect: _rectOf(node), key: key));
  }
  return stops;
}

Widget _wrap(RuleEditorScreen child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('WCAG 2.4.3 focus order on RuleEditorScreen', () {
    testWidgets('empty draft exposes exactly one stop and no save action', (
      tester,
    ) async {
      tester.view
        ..physicalSize = _viewport
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          RuleEditorScreen(
            validatorRules: const {'field': true},
            onSave: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('editor-save')),
        findsNothing,
        reason: 'Save rule must stay absent while the draft is incomplete.',
      );

      final stops = await collectStops(tester);
      expect(
        stops,
        hasLength(1),
        reason:
            'The empty draft has only the workflow-id field in the tab '
            'chain, but got ${stops.map((s) => s.label).toList()}.',
      );
      expect(
        stops.single.rect.width,
        greaterThan(0),
        reason: 'Focus area must be non-zero.',
      );
      expect(stops.single.rect.height, greaterThan(0));
    });

    testWidgets(
      'complete draft exposes field then Save rule in reading order',
      (tester) async {
        tester.view
          ..physicalSize = _viewport
          ..devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _wrap(
            RuleEditorScreen(
              validatorRules: const {'field': true},
              onSave: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('editor-workflow')),
          'wf-focus-order',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('editor-save')),
          findsOneWidget,
          reason: 'Save rule must appear once the draft is complete.',
        );

        final stops = await collectStops(tester);
        expect(
          stops,
          hasLength(2),
          reason:
              'The complete draft has exactly field + save in the tab '
              'chain, but got ${stops.map((s) => s.label).toList()}.',
        );

        final field = stops.firstWhere((s) => s.label == 'wf-focus-order');
        final save = stops.firstWhere((s) => s.label == 'Save rule');
        expect(
          field.rect.top,
          lessThan(save.rect.top),
          reason: 'Workflow ID field must sit above Save rule (reading order).',
        );
        expect(
          field.rect.left,
          save.rect.left,
          reason: 'Both controls are full width, so left edges must align.',
        );
        for (final stop in stops) {
          expect(stop.rect.width, greaterThan(0));
          expect(stop.rect.height, greaterThan(0));
        }
      },
    );

    testWidgets('tab from the field reaches Save rule next', (tester) async {
      tester.view
        ..physicalSize = _viewport
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          RuleEditorScreen(
            validatorRules: const {'field': true},
            onSave: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editor-workflow')));
      await tester.enterText(
        find.byKey(const Key('editor-workflow')),
        'wf-forward',
      );
      await tester.pumpAndSettle();

      expect(_labelOf(FocusManager.instance.primaryFocus!), 'wf-forward');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        _labelOf(FocusManager.instance.primaryFocus!),
        'Save rule',
        reason: 'Forward traversal from the field must land on Save rule.',
      );
    });

    testWidgets('reverse traversal from Save rule returns to the field', (
      tester,
    ) async {
      tester.view
        ..physicalSize = _viewport
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      AutomationRule? saved;
      await tester.pumpWidget(
        _wrap(
          RuleEditorScreen(
            validatorRules: const {'field': true},
            onSave: (rule) => saved = rule,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('editor-workflow')),
        'wf-reverse',
      );
      await tester.pumpAndSettle();
      expect(saved, isNull, reason: 'Traversing focus must never save.');

      // Focus the field explicitly, then walk forward onto Save rule.
      await tester.tap(find.byKey(const Key('editor-workflow')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_labelOf(FocusManager.instance.primaryFocus!), 'Save rule');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(
        _labelOf(FocusManager.instance.primaryFocus!),
        'wf-reverse',
        reason:
            'Reverse traversal must return to the field, not escape the '
            'chain.',
      );
      expect(saved, isNull);
    });

    testWidgets('save action still carries the entered workflow id', (
      tester,
    ) async {
      tester.view
        ..physicalSize = _viewport
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      AutomationRule? saved;
      await tester.pumpWidget(
        _wrap(
          RuleEditorScreen(
            validatorRules: const {'field': true},
            onSave: (rule) => saved = rule,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('editor-workflow')),
        'wf-submit',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.workflowId, 'wf-submit');
    });
  });
}
