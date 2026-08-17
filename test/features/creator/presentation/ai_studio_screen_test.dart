import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/presentation/ai_studio_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('renders AI Studio header and sections', (tester) async {
    await tester.pumpWidget(wrap(const AiStudioScreen()));

    expect(find.text('AI STUDIO'), findsOneWidget);
    expect(find.text('AI Control Level'), findsOneWidget);
    expect(find.text('Context Layers'), findsOneWidget);
    expect(find.text('Action Modes'), findsOneWidget);
    expect(find.text('Cost Guard'), findsOneWidget);
  });

  testWidgets('no overflow at narrow width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const AiStudioScreen()));

    expect(tester.takeException(), isNull);
    expect(find.text('AI STUDIO'), findsOneWidget);
  });

  testWidgets('no overflow at desktop width', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const AiStudioScreen()));

    expect(tester.takeException(), isNull);
    expect(find.text('Action Modes'), findsOneWidget);
  });
}
