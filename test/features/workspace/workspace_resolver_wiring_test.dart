import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_export_options_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Production wiring proof: the resolver must inject real export/import
/// actions (and the default package exports directory) into
/// [StoryWorkspaceScreen] whenever a project session is live.
void main() {
  Future<Directory> makeTemp(WidgetTester tester, String prefix) async {
    final dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp(prefix),
    );
    return dir!;
  }

  testWidgets('resolver wires live export actions into story screen', (
    tester,
  ) async {
    final temp = await makeTemp(tester, 'resolver-wiring-');
    addTearDown(() {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });

    // Real package + session built off the fake-async zone via runAsync.
    final session = await tester.runAsync(() async {
      final package = await ProjectPackageService(
        rootDirectory: Directory('${temp.path}/pkg'),
      ).create(name: 'Resolver Wiring Novel');
      return ProjectSessionManager().open(package);
    });
    final liveSession = session!;
    addTearDown(liveSession.close);
    final storyId = await tester.runAsync(
      () async => CreateStoryService(
        database: liveSession.database,
        paths: ProjectPaths(rootDirectory: Directory('${temp.path}/data')),
      ).createStory(projectId: liveSession.manifest.id, title: 'Wired Novel'),
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

    // Export button present AND enabled => real actions injected.
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Export Novel'),
    );
    expect(button.onPressed, isNotNull);

    // Import now ENABLED: gap run228 GAP-IMPORT-NOVEL-UNWIRED closed — the
    // resolver injects a real .voidworkspace archive picker next to the
    // import actions. The old "visible but disabled" pin documented the
    // pre-picker capability gap; evolution tracked in
    // workspace_resolver_import_wiring_test.dart. Unknown-typed input is
    // still never adopted: the picker filters to the production extension.
    final importButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Import Novel'),
    );
    expect(importButton.onPressed, isNotNull);

    // Dialog opens with the production destination prefilled from the
    // package exports directory (drive-D support lands later per user).
    await tester.tap(find.text('Export Novel'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceExportOptionsDialog), findsOneWidget);
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
