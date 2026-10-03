import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workflow/presentation/workflow_editor_screen.dart';
import 'package:void_scriptor/workflow/workflow_validation.dart';

WorkflowValidationService _service() => WorkflowValidationService(
  knownCommands: const {'manual.noop'},
  commandCapabilities: const {'manual.noop': {}},
);

Future<List<({String key, Rect rect})>> _stops(WidgetTester tester) async {
  final out = <({String key, Rect rect})>[];
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
    final key =
        context.widget.key?.toString() ?? context.widget.runtimeType.toString();
    out.add((key: key, rect: rect));
  }
  return out;
}

Future<void> _pump(WidgetTester tester, {bool complete = false}) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: WorkflowEditorScreen(
        validationService: _service(),
        defaultCommandType: 'manual.noop',
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (complete) {
    await tester.enterText(find.byKey(const Key('editor-id')), 'flow');
    await tester.enterText(find.byKey(const Key('editor-steps')), 'step');
    await tester.pump();
  }
}

void main() {
  group('Workflow Editor — kontrak focus order 2.4.3', () {
    testWidgets('1. field traversal mengikuti urutan visual', (tester) async {
      await _pump(tester);
      final stops = await _stops(tester);
      expect(stops.length, 3);
      expect(stops[0].rect.top, lessThan(stops[1].rect.top));
      expect(stops[1].rect.top, lessThan(stops[2].rect.top));
    });

    testWidgets(
      '2. Save muncul setelah draft valid dan menjadi stop terakhir',
      (tester) async {
        await _pump(tester, complete: true);
        expect(find.byKey(const Key('editor-save')), findsOneWidget);
        final stops = await _stops(tester);
        expect(stops.length, 4);
        expect(stops[3].rect.top, greaterThan(stops[2].rect.top));
      },
    );
  });
}
