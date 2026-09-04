import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

void main() {
  testWidgets('project overview creates a novel from title input', (
    tester,
  ) async {
    String? createdTitle;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProjectOverview(
            onCreateNovel: (title) async {
              createdTitle = title;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Create Novel'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.bySemanticsLabel('Novel title'),
      'Void Cube Saga',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(createdTitle, 'Void Cube Saga');
    expect(find.text('Novel created.'), findsOneWidget);
  });
}
