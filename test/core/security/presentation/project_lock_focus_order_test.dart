import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/presentation/project_lock_screen.dart';

/// First visible non-icon text inside [context]; falls back to the enclosing
/// TextField's decoration label, then to the widget type.
String _labelOf(BuildContext context) {
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
  if (label.isNotEmpty) return label;
  // Check the icon-button branch first: the suffix IconButton is rendered
  // inside the TextField subtree, so a field-first lookup would mislabel it.
  if (context.findAncestorWidgetOfExactType<IconButton>() != null) {
    return 'icon:visibility-toggle';
  }
  final fieldLabel = context
      .findAncestorWidgetOfExactType<TextField>()
      ?.decoration
      ?.labelText;
  if (fieldLabel != null && fieldLabel.trim().isNotEmpty) {
    return 'field:${fieldLabel.trim()}';
  }
  return 'widget:${context.widget.runtimeType}';
}

Future<List<({String label, Rect rect})>> _stops(
  WidgetTester tester, {
  int max = 8,
}) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < max; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) break;
    final object = focusContext.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    final key =
        '${rect.left.toStringAsFixed(1)}|${rect.top.toStringAsFixed(1)}|'
        '${rect.width.toStringAsFixed(1)}|${rect.height.toStringAsFixed(1)}';
    if (!seen.add(key)) break;
    stops.add((label: _labelOf(focusContext), rect: rect));
  }
  return stops;
}

void main() {
  testWidgets('ProjectLockScreen locks WCAG 2.4.3 focus order '
      '(3 stops: passphrase field -> visibility toggle -> Buka Proyek)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectLockScreen(
          projectName: 'Fixture Project',
          onUnlock: (passphrase) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final stops = await _stops(tester);

    expect(stops, hasLength(3), reason: 'focus stop count');
    expect(stops.map((s) => s.label).toList(), const [
      'field:Passphrase',
      'icon:visibility-toggle',
      'Buka Proyek',
    ], reason: 'focus order labels');

    final field = stops[0].rect;
    final toggle = stops[1].rect;
    final submit = stops[2].rect;
    for (final rect in [field, toggle, submit]) {
      expect(rect.width, greaterThan(0), reason: 'focus area width');
      expect(rect.height, greaterThan(0), reason: 'focus area height');
    }

    // Stop 0 -> 1: same input row, Tab moves left-to-right (suffix icon
    // sits right of the text field).
    expect((field.top - toggle.top).abs(), lessThan(64));
    expect(field.left, lessThan(toggle.left));

    // Stop 1 -> 2: the primary action sits below the input row, so Tab
    // moves top-to-bottom.
    expect(submit.top, greaterThan(toggle.top));

    expect(tester.takeException(), isNull);
  });
}
