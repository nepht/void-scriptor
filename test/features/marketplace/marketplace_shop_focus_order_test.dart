import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/presentation/create_product_wizard_screen.dart';
import 'package:void_scriptor/features/marketplace/presentation/product_detail_screen.dart';

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < 6; i++) {
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
    stops.add((label: label, rect: rect));
  }
  return stops;
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('create product wizard keeps Cancel then Next left to right', (
    tester,
  ) async {
    _viewport(tester);
    await tester.pumpWidget(
      const MaterialApp(home: CreateProductWizardScreen()),
    );
    await tester.pumpAndSettle();

    final stops = await _stops(tester);
    expect(stops.map((stop) => stop.label).toList(), ['Cancel', 'Next']);
    expect(stops[0].rect.left, lessThan(stops[1].rect.left));
    expect(stops[0].rect.top, stops[1].rect.top);
    expect(
      stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
      isTrue,
    );
  });

  testWidgets('product detail keeps Install then Buy left to right', (
    tester,
  ) async {
    _viewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailScreen(onInstall: () {}, onBuy: () {}),
      ),
    );
    await tester.pumpAndSettle();

    final stops = await _stops(tester);
    expect(stops.map((stop) => stop.label).toList(), ['Install', 'Buy']);
    expect(stops[0].rect.left, lessThan(stops[1].rect.left));
    expect(stops[0].rect.top, stops[1].rect.top);
    expect(
      stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
      isTrue,
    );
  });
}
