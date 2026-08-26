import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_export_service.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_export_options_dialog.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester,
    ValueChanged<WorkspaceExportOptions?> onPopped,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                final options = await showWorkspaceExportOptionsDialog(
                  context: context,
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
    await tester.pumpAndSettle();
  }

  testWidgets(
    'lists all three ADR representations with confirm locked until explicit choice',
    (tester) async {
      WorkspaceExportOptions? popped;
      await openDialog(tester, (options) => popped = options);

      expect(find.text('Reference manifest'), findsOneWidget);
      expect(find.text('Embedded snapshot'), findsOneWidget);
      expect(find.text('Fork'), findsOneWidget);

      // No silent default: the export must not claim a representation the user
      // never chose.
      final confirmBefore = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Export'),
      );
      expect(confirmBefore.onPressed, isNull);

      await tester.tap(find.text('Embedded snapshot'));
      await tester.pumpAndSettle();

      final confirmAfter = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Export'),
      );
      expect(confirmAfter.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(FilledButton, 'Export'));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(
        popped!.characterRepresentation,
        WorkspaceCharacterRepresentation.embeddedSnapshot,
      );
    },
  );

  testWidgets('cancel pops without options', (tester) async {
    WorkspaceExportOptions? popped;
    await openDialog(tester, (options) => popped = options);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(popped, isNull);
  });

  testWidgets('switching selection changes the returned option', (
    tester,
  ) async {
    WorkspaceExportOptions? popped;
    await openDialog(tester, (options) => popped = options);

    await tester.tap(find.text('Fork'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reference manifest'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Export'));
    await tester.pumpAndSettle();

    expect(
      popped!.characterRepresentation,
      WorkspaceCharacterRepresentation.referenceManifest,
    );
  });
}
