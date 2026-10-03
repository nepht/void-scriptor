import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/presentation/create_product_wizard_screen.dart';

const _expectedLabels = ['Cancel', 'Next'];

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
  return label.isEmpty ? 'widget:${context.widget.runtimeType}' : label;
}

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < 8; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) break;
    final object = context.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    final key = '${rect.left}|${rect.top}|${rect.width}|${rect.height}';
    if (!seen.add(key)) break;
    stops.add((label: _labelOf(context), rect: rect));
  }
  return stops;
}

void main() {
  testWidgets(
    'Create Product Wizard follows the measured WCAG 2.4.3 focus order',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(home: CreateProductWizardScreen()),
      );
      await tester.pumpAndSettle();

      final stops = await _stops(tester);
      expect(stops, hasLength(2));
      expect(
        stops.map((stop) => stop.label).toList(),
        _expectedLabels,
        reason: 'Tab order must follow the visible action order.',
      );
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Every focus stop must have a non-zero focus area.',
      );
      expect(
        stops[0].rect.left,
        lessThan(stops[1].rect.left),
        reason: 'The two actions are read left to right.',
      );
      expect(
        stops[0].rect.top,
        closeTo(stops[1].rect.top, 1),
        reason: 'The two actions share one horizontal row.',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
