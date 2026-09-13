import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:void_scriptor/features/references/domain/reference_models.dart';
import 'package:void_scriptor/features/references/presentation/reference_library_screen.dart';

void main() {
  const references = [
    ReferenceModel(
      id: 'face',
      projectId: 'p',
      ownerAssetId: 'qowner',
      type: ReferenceType.face,
      source: ReferenceSource.imported,
      name: 'Master Face',
      filePath: 'missing/master.png',
      priority: 100,
      primary: true,
      enabled: true,
    ),
    ReferenceModel(
      id: 'hair',
      projectId: 'p',
      ownerAssetId: 'qowner',
      type: ReferenceType.hair,
      source: ReferenceSource.generated,
      name: 'Combat Hair',
      filePath: 'missing/hair.png',
      priority: 90,
      primary: false,
      enabled: true,
    ),
  ];

  testWidgets(
    'reference library renders responsive cards and missing-file state',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReferenceLibraryScreen(references: references)),
      );
      expect(find.text('Reference Library'), findsOneWidget);
      expect(find.text('★ PRIMARY'), findsOneWidget);
      expect(find.text('Reference file missing'), findsNWidgets(2));
      await tester.enterText(find.byType(TextField), 'combat');
      await tester.pump();
      expect(find.text('Combat Hair'), findsOneWidget);
      expect(find.text('Master Face'), findsNothing);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('missing reference exposes repair action', (tester) async {
    ReferenceModel? repaired;
    await tester.pumpWidget(
      MaterialApp(
        home: ReferenceLibraryScreen(
          references: references,
          onRepair: (reference) async => repaired = reference,
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Repair').first);
    await tester.pump();
    expect(repaired?.id, 'face');
  });

  testWidgets('import dialog returns validated draft on narrow layout', (
    tester,
  ) async {
    ReferenceImportDraft? submitted;
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ReferenceLibraryScreen(
          onImport: (draft) async => submitted = draft,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Import reference'));
    await tester.pumpAndSettle();
    expect(find.text('Import Reference'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Source file path'),
      '/tmp/face.png',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Master Face',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pumpAndSettle();
    expect(submitted?.sourcePath, '/tmp/face.png');
    expect(submitted?.name, 'Master Face');
    expect(tester.takeException(), isNull);
  });

  testWidgets('import dialog shows validation feedback for empty fields', (
    tester,
  ) async {
    ReferenceImportDraft? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: ReferenceLibraryScreen(
          references: references,
          onImport: (draft) async => submitted = draft,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Import reference'));
    await tester.pumpAndSettle();
    expect(find.text('Import Reference'), findsOneWidget);

    // vs-hunt-20260913-references REF-BUG-3: submitting empty required
    // fields must surface a visible reason, not silently no-op.
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pump();
    expect(find.text('Import Reference'), findsOneWidget);
    expect(submitted, isNull);
    expect(find.text('Source file path is required.'), findsOneWidget);
    expect(find.text('Name is required.'), findsOneWidget);

    // Filling the field clears its own error on the next submit attempt.
    await tester.enterText(
      find.widgetWithText(TextField, 'Source file path'),
      '/tmp/face.png',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pump();
    expect(find.text('Source file path is required.'), findsNothing);
    expect(find.text('Name is required.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Face A');
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pumpAndSettle();
    expect(submitted?.sourcePath, '/tmp/face.png');
    expect(submitted?.name, 'Face A');
    expect(tester.takeException(), isNull);
  });
}
