import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/bible/presentation/project_bible_workspace_screen.dart';

void main() {
  testWidgets('Project Bible renders responsive sections on desktop', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProjectBibleWorkspaceScreen()),
    );
    await tester.pump();

    expect(find.text('PROJECT BIBLE'), findsOneWidget);
    expect(find.text('Universe Overview'), findsOneWidget);
    expect(find.text('Canon Rules'), findsOneWidget);
    expect(find.text('Canon Conflicts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Project Bible stacks sections on narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: ProjectBibleWorkspaceScreen()),
    );
    await tester.pump();

    expect(find.text('PROJECT BIBLE'), findsOneWidget);
    expect(find.text('Worldbuilding'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
