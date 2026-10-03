import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinematic_production/presentation/cinematic_production_workspace_screen.dart';

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
    final key = '${rect.top}|${rect.left}';
    if (!seen.add(key)) break;
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

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: CinematicProductionWorkspaceScreen(
        onImportAudio: () {},
        onOpenValidation: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('focus order exposes only the two workspace actions', (
    tester,
  ) async {
    await _pump(tester);
    final stops = await _stops(tester);

    expect(stops.map((stop) => stop.label).toList(), [
      'Import Audio',
      'Validation Center',
    ]);
    expect(stops[0].rect.left, lessThan(stops[1].rect.left));
    expect(stops[0].rect.top, stops[1].rect.top);
    expect(
      stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
      isTrue,
    );
  });
}
