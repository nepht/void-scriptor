import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/presentation/marketplace_workspace_screen.dart';

const _expected = [
  'Discover',
  'AI Agents',
  'Workflows',
  'Prompts',
  'Templates',
  'My Library',
];

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final out = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < 10; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) break;
    final object = context.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    if (!seen.add('${rect.top}|${rect.left}')) break;
    var label = '?';
    void visit(Element element) {
      if (label != '?') return;
      final widget = element.widget;
      if (widget is Icon) return;
      if (widget is Text && widget.data?.trim().isNotEmpty == true) {
        label = widget.data!.trim();
        return;
      }
      element.visitChildren(visit);
    }

    visit(context as Element);
    out.add((label: label, rect: rect));
  }
  return out;
}

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const MaterialApp(home: MarketplaceWorkspaceScreen()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('wide menu tabs in declared order', (tester) async {
    await _pump(tester, const Size(1536, 1024));
    final stops = await _stops(tester);
    expect(stops.map((stop) => stop.label).toList(), _expected);
    for (var i = 1; i < stops.length; i++) {
      expect(stops[i].rect.top, greaterThan(stops[i - 1].rect.top));
    }
  });

  testWidgets('compact menu keeps the same keyboard order', (tester) async {
    await _pump(tester, const Size(390, 844));
    final stops = await _stops(tester);
    expect(stops.map((stop) => stop.label).toList(), _expected);
    expect(
      stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
      isTrue,
    );
  });
}
