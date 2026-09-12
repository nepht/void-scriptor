import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_import_service.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_export_service.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_export_actions.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_export_options_dialog.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_import_actions.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_import_options_dialog.dart';

/// Real filesystem/SQLite work must run inside [WidgetTester.runAsync]; the
/// widget-test zone is fake-async and hangs on platform I/O.
void main() {
  Future<({ProjectPackage package, NovelCharacterLinkRepository links})>
  makeFixture(WidgetTester tester, Directory root, String name) async {
    final result = await tester.runAsync(() async {
      final package = await ProjectPackageService(
        rootDirectory: Directory('${root.path}/$name'),
      ).create(name: name);
      final db = await ProjectDatabaseService().open(package.databaseFile.path);
      addTearDown(db.close);
      return (
        package: package,
        links: NovelCharacterLinkRepository(
          database: db,
          projectId: package.projectId,
        ),
      );
    });
    return result!;
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required Directory exportDirectory,
    WorkspaceExportActions? exportActions,
    WorkspaceImportActions? importActions,
    Future<File?> Function()? pickImportArchive,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1200,
              child: StoryWorkspaceScreen(
                storyId: 'novel-1',
                exportDirectory: exportDirectory,
                novelExportActions: exportActions,
                novelImportActions: importActions,
                pickImportArchive: pickImportArchive,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Directory> makeTemp(WidgetTester tester, String prefix) async {
    final dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp(prefix),
    );
    return dir!;
  }

  testWidgets('novel io buttons absent when actions are not wired', (
    tester,
  ) async {
    final temp = await makeTemp(tester, 'story-io-off-');
    addTearDown(() => temp.delete(recursive: true));

    await pumpScreen(tester, exportDirectory: temp);

    expect(find.text('Export Novel'), findsNothing);
    expect(find.text('Import Novel'), findsNothing);
  });

  /// Recording doubles: the widget-test zone is fake-async and must not run
  /// real zip I/O. Real end-to-end export/import is proven in
  /// workspace_actions_test.dart (plain Dart, real filesystem).
  late WorkspaceExportOptions? recordedExport;
  late WorkspaceImportCollisionChoice? recordedImportChoice;
  late String? peekedRepresentation;

  late WorkspaceExportActions exportDouble;
  late WorkspaceImportActions importDouble;

  void installDoubles({
    required ProjectPackage package,
    required NovelCharacterLinkRepository links,
    String? representationToPeek,
  }) {
    recordedExport = null;
    recordedImportChoice = null;
    peekedRepresentation = null;
    exportDouble = _RecordingExportActions(
      package: package,
      links: links,
      onRun: (options) => recordedExport = options,
    );
    importDouble = _RecordingImportActions(
      package: package,
      links: links,
      representation: representationToPeek,
      onPeek: (value) => peekedRepresentation = value,
      onRun: (choice) => recordedImportChoice = choice,
    );
  }

  testWidgets('novel export button carries the explicit choice into actions', (
    tester,
  ) async {
    final temp = await makeTemp(tester, 'story-io-export-');
    addTearDown(() => temp.delete(recursive: true));
    final source = await makeFixture(tester, temp, 'project-a');
    installDoubles(package: source.package, links: source.links);

    await pumpScreen(
      tester,
      exportDirectory: Directory('${temp.path}/out'),
      exportActions: exportDouble,
    );

    expect(find.text('Export Novel'), findsOneWidget);
    await tester.tap(find.text('Export Novel'));
    await tester.pumpAndSettle();

    // Dialog demands an explicit representation before enabling Export.
    final confirmBefore = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Export'),
    );
    expect(confirmBefore.onPressed, isNull);

    await tester.tap(find.text('Reference manifest'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Export'));
    await tester.pumpAndSettle();

    expect(recordedExport, isNotNull);
    expect(
      recordedExport!.characterRepresentation,
      WorkspaceCharacterRepresentation.referenceManifest,
    );
    expect(find.textContaining('Novel workspace diekspor'), findsOneWidget);
  });

  testWidgets(
    'import flow surfaces the declared representation before any mutation',
    (tester) async {
      final temp = await makeTemp(tester, 'story-io-import-');
      addTearDown(() => temp.delete(recursive: true));
      final target = await makeFixture(tester, temp, 'target-project');
      const declared = 'embedded_snapshot';
      installDoubles(
        package: target.package,
        links: target.links,
        representationToPeek: declared,
      );
      final archive = File('${temp.path}/fake.voidworkspace');

      await pumpScreen(
        tester,
        exportDirectory: Directory('${temp.path}/unused-out'),
        importActions: importDouble,
        // Peek runs BEFORE the dialog opens, mirroring production order.
        pickImportArchive: () async {
          peekedRepresentation = await importDouble.peekCharacterRepresentation(
            archive,
          );
          return archive;
        },
      );

      await tester.tap(find.text('Import Novel'));
      await tester.pumpAndSettle();

      // Archive-declared representation surfaced before deciding.
      expect(peekedRepresentation, declared);
      expect(find.text('Embedded snapshot'), findsOneWidget);

      final confirmBefore = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Import'),
      );
      expect(confirmBefore.onPressed, isNull);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();

      expect(recordedImportChoice, WorkspaceImportCollisionChoice.skip);
      expect(find.textContaining('Novel workspace diimpor'), findsOneWidget);
    },
  );

  testWidgets('novel io buttons lock while an export archive is running', (
    tester,
  ) async {
    final temp = await makeTemp(tester, 'story-io-busy-');
    addTearDown(() => temp.delete(recursive: true));
    final source = await makeFixture(tester, temp, 'busy-project');

    // Gated double: run() stays pending until released, simulating zip I/O.
    final release = Completer<void>();
    var runs = 0;
    final gated = _GatedExportActions(
      package: source.package,
      links: source.links,
      onRun: () => runs++,
      release: release.future,
    );

    await pumpScreen(
      tester,
      exportDirectory: Directory('${temp.path}/out'),
      exportActions: gated,
    );

    final exportButton = find.widgetWithText(OutlinedButton, 'Export Novel');

    await tester.tap(exportButton.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reference manifest'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Export'));
    await tester.pump();

    // While the archive write is in flight the trigger must be locked...
    expect(tester.widget<OutlinedButton>(exportButton.first).onPressed, isNull);
    // ...so a second tap cannot start a parallel export.
    await tester.tap(exportButton.first);
    await tester.pump();
    expect(runs, 1);

    release.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Novel workspace diekspor'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(exportButton.first).onPressed,
      isNotNull,
    );
    expect(runs, 1);
  });
}

class _GatedExportActions extends WorkspaceExportActions {
  const _GatedExportActions({
    required super.package,
    required super.links,
    required this.onRun,
    required this.release,
  });

  final VoidCallback onRun;
  final Future<void> release;

  @override
  Future<File> run(
    String novelWorkspaceId,
    WorkspaceExportOptions options, {
    required Directory destination,
  }) {
    onRun();
    return release.then((_) => File('${destination.path}/gated.voidworkspace'));
  }
}

class _RecordingExportActions extends WorkspaceExportActions {
  const _RecordingExportActions({
    required super.package,
    required super.links,
    required this.onRun,
  });

  final ValueChanged<WorkspaceExportOptions> onRun;

  @override
  Future<File> run(
    String novelWorkspaceId,
    WorkspaceExportOptions options, {
    required Directory destination,
  }) {
    onRun(options);
    return Future.value(File('${destination.path}/recorded.voidworkspace'));
  }
}

class _RecordingImportActions extends WorkspaceImportActions {
  const _RecordingImportActions({
    required super.package,
    required super.links,
    required this.representation,
    required this.onPeek,
    required this.onRun,
  });

  final String? representation;
  final ValueChanged<String?> onPeek;
  final ValueChanged<WorkspaceImportCollisionChoice> onRun;

  @override
  Future<String?> peekCharacterRepresentation(File archive) async =>
      representation;

  @override
  Future<WorkspaceArchivePreflight> preflightArchive(File archive) async {
    onPeek(representation);
    return WorkspaceArchivePreflight(
      sourceFile: archive,
      bytes: Uint8List(0),
      decoded: Archive(),
      manifest: {'characterRepresentation': representation},
    );
  }

  @override
  Future<WorkspaceRestoreResult> run(
    File archive,
    WorkspaceImportOptions options, {
    String? expectedWorkspaceId,
    WorkspaceArchivePreflight? preflight,
  }) {
    onRun(options.collisionChoice);
    return Future.value(
      const WorkspaceRestoreResult(
        workspaceId: 'novel-1',
        restoredLinkCount: 3,
      ),
    );
  }
}
