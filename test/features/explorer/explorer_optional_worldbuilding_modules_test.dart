import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/explorer/application/project_sidebar_module_preferences.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

void main() {
  testWidgets(
    'romance project hides factions until user enables it and sidebar destinations work',
    (tester) async {
      final root = await tester.runAsync(
        () => Directory.systemTemp.createTemp('void-romance-modules-'),
      );
      final paths = ProjectPaths(rootDirectory: root!);
      final package = await tester.runAsync(
        () => ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Romance project'),
      );
      final session = await tester.runAsync(
        () => ProjectSessionManager().open(package!),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(() async {
          await session!.close();
          if (root.existsSync()) await root.delete(recursive: true);
        });
      });
      await tester.runAsync(() async {
        final service = CreateStoryService(
          database: session!.database,
          paths: paths,
        );
        final storyId = await service.createStory(
          projectId: package!.projectId,
          title: 'A Quiet Spring',
        );
        await (session.database.update(session.database.stories)
              ..where((row) => row.assetId.equals(storyId)))
            .write(const StoriesCompanion(genre: Value('School romance')));
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => _FixedSession(session!)),
            projectPathsProvider.overrideWithValue(paths),
            projectSidebarModulePreferencesServiceProvider.overrideWithValue(
              _MemoryModulePreferencesService(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  ExplorerPanel(),
                  Expanded(child: WorkspaceResolver()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Configure sidebar modules'), findsOneWidget);
      expect(find.text('Factions'), findsNothing);
      expect(find.text('Relationship Map'), findsNothing);
      expect(find.text('Weapons'), findsNothing);

      await tester.tap(find.byTooltip('Configure sidebar modules'));
      await tester.pumpAndSettle();
      expect(
        find.text('Suggested by genre; you remain in control.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(CheckboxListTile, 'Factions'), findsNothing);
      expect(
        find.widgetWithText(CheckboxListTile, 'Relationship Map'),
        findsNothing,
      );
      expect(find.widgetWithText(CheckboxListTile, 'Weapons'), findsOneWidget);
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Weapons'));
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Weapons'),
        80,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Weapons'), findsOneWidget);
      expect(find.text('Factions'), findsNothing);
      expect(find.text('Relationship Map'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FixedSession extends ProjectSessionController {
  _FixedSession(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

class _MemoryModulePreferencesService
    extends ProjectSidebarModulePreferencesService {
  ProjectSidebarModulePreferences value = const ProjectSidebarModulePreferences(
    factions: false,
    relationshipMap: true,
  );

  @override
  Future<ProjectSidebarModulePreferences> load({
    required package,
    required database,
    required String projectId,
  }) async => value;

  @override
  Future<void> save(
    package,
    ProjectSidebarModulePreferences preferences,
  ) async {
    value = preferences;
  }
}
