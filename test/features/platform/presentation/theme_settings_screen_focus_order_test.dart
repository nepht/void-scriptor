import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/presentation/theme_settings_screen.dart';

const _expectedLabels = [
  'System',
  'Void Purple',
  'Ink',
  'Ember',
  'Sage',
  'Rose',
  'Ocean',
];

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
  for (var i = 0; i < 16; i++) {
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
  testWidgets('Theme Settings follows WCAG 2.4.3 focus order', (tester) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ThemeSettingsScreen())),
    );
    await tester.pumpAndSettle();

    final stops = await _stops(tester);
    expect(stops, hasLength(7));
    expect(
      stops.map((stop) => stop.label).toList(),
      _expectedLabels,
      reason: 'Tab order must follow the visible theme controls.',
    );
    expect(
      stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
      isTrue,
      reason: 'Every focus stop must have a non-zero focus area.',
    );
    expect(stops[0].rect.top, lessThan(stops[1].rect.top));
    for (var i = 1; i < stops.length - 1; i++) {
      expect(
        stops[i].rect.left,
        lessThan(stops[i + 1].rect.left),
        reason: 'Accent chips must be reached left to right.',
      );
      expect(
        stops[i].rect.top,
        closeTo(stops[i + 1].rect.top, 1),
        reason: 'Accent chips share one horizontal row.',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
