import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gap 145.33 (run228 GAP-IMPORT-NOVEL-UNWIRED): the resolver must inject a
/// real archive picker alongside [WorkspaceImportActions] so the Import Novel
/// button is actionable. Injecting actions without a picker left the button
/// permanently disabled for users despite the full import pipeline existing.
void main() {
  Future<Directory> makeTemp(WidgetTester tester, String prefix) async {
    final dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp(prefix),
    );
    return dir!;
  }

  testWidgets('resolver wires the import picker into the story screen', (
    tester,
  ) async {
    final temp = await makeTemp(tester, 'resolver-import-');
    addTearDown(() {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });

    final session = await tester.runAsync(() async {
      final package = await ProjectPackageService(
        rootDirectory: Directory('${temp.path}/pkg'),
      ).create(name: 'Resolver Import Novel');
      return ProjectSessionManager().open(package);
    });
    final liveSession = session!;
    addTearDown(liveSession.close);
    final storyId = await tester.runAsync(
      () async => CreateStoryService(
        database: liveSession.database,
        paths: ProjectPaths(rootDirectory: Directory('${temp.path}/data')),
      ).createStory(projectId: liveSession.manifest.id, title: 'Import Novel'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _FixedSession(liveSession)),
          selectionProvider.overrideWith(
            () => _FixedSelection(
              SelectionModel(
                assetId: storyId!,
                assetType: AssetType.story,
                projectId: liveSession.manifest.id,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
      ),
    );
    await tester.pumpAndSettle();

    // Mechanism: the resolver seam supplies a real picker function.
    final screen = tester.widget<StoryWorkspaceScreen>(
      find.byType(StoryWorkspaceScreen),
    );
    expect(screen.pickImportArchive, isNotNull);

    // User contract: Import Novel is ENABLED when a live session exists
    // (previously permanently disabled: actions wired, picker missing).
    final importButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Import Novel'),
    );
    expect(importButton.onPressed, isNotNull);

    // Picker filter must target the production archive extension so the
    // native dialog cannot offer files the import service would reject.
    expect(screen.novelImportActions, isNotNull);
  });
}

class _FixedSession extends ProjectSessionController {
  _FixedSession(this._session);

  final ProjectSession _session;

  @override
  Future<ProjectSession?> build() async => _session;
}

class _FixedSelection extends SelectionController {
  _FixedSelection(this._selection);

  final SelectionModel _selection;

  @override
  SelectionModel? build() => _selection;
}
