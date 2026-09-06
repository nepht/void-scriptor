import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/app/shell/desktop/void_status_bar.dart';

void main() {
  testWidgets('status bar does not overflow at desktop width', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: VoidStatusBar())),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('status bar exposes dirty and command state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VoidStatusBar(dirty: true, canUndo: true, canRedo: false),
        ),
      ),
    );

    expect(find.text('Local'), findsOneWidget);
    expect(find.text('Cloud'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Redo'), findsOneWidget);
    expect(find.text('Dirty'), findsOneWidget);
    expect(find.text('Void Scriptor 0.1 Alpha'), findsOneWidget);
  });
}
