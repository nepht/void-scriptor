import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_import_service.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_import_options_dialog.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester,
    Future<String?> Function() loadRepresentation,
    ValueChanged<WorkspaceImportOptions?> onPopped, {
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                final options = await showWorkspaceImportOptionsDialog(
                  context: context,
                  loadRepresentation: loadRepresentation,
                );
                onPopped(options);
              },
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets(
    'shows archive representation and locks confirm until explicit collision choice',
    (tester) async {
      WorkspaceImportOptions? popped;
      await openDialog(
        tester,
        () async => 'embedded_snapshot',
        (o) => popped = o,
      );

      // Archive-declared representation is surfaced before deciding.
      expect(find.text('Embedded snapshot'), findsOneWidget);

      final confirmBefore = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Import'),
      );
      expect(confirmBefore.onPressed, isNull);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      final confirmAfter = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Import'),
      );
      expect(confirmAfter.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!.collisionChoice, WorkspaceImportCollisionChoice.skip);
    },
  );

  testWidgets('unknown representation renders honestly as unknown', (
    tester,
  ) async {
    await openDialog(tester, () async => null, (_) {});

    expect(find.text('Not declared'), findsOneWidget);
  });

  testWidgets('load failure renders honest error and keeps confirm disabled', (
    tester,
  ) async {
    await openDialog(tester, () => Future.error('corrupt'), (_) {});

    expect(find.text('Failed to read the archive.'), findsOneWidget);
    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Import'),
    );
    expect(confirm.onPressed, isNull);
  });
}
