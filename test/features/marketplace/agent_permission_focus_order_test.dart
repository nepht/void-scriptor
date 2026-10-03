import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/presentation/agent_permission_screen.dart';

Future<List<Rect>> _stops(WidgetTester tester) async {
  final stops = <Rect>[];
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
    stops.add(rect);
  }
  return stops;
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: AgentPermissionScreen(onAllowAll: () {}, onDenyOptional: () {}),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('permission controls follow tile order then actions', (
    tester,
  ) async {
    await _pump(tester);
    final stops = await _stops(tester);

    expect(stops, hasLength(3));
    expect(find.text('Allow All'), findsOneWidget);
    expect(find.text('Deny Optional'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(stops[0].left, greaterThan(1400));
    expect(stops[1].top, greaterThan(stops[0].top));
    expect(stops[2].top, stops[1].top);
    expect(stops[1].left, lessThan(stops[2].left));
    expect(stops.every((rect) => rect.width > 0 && rect.height > 0), isTrue);
  });
}
