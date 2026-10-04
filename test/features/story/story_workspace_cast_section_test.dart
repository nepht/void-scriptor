import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';
import 'package:void_scriptor/features/workspaces/application/narrative_assignment_repository.dart';
import 'package:void_scriptor/features/workspaces/application/story_cast_loader.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

/// Wiring sprint Task 1: novel-side cast view. The Novel Workspace Cast
/// section lists the novel's characters with their narrative roles from the
/// story's perspective, backed by the same `character_narrative_assignments`
/// store the Character Workspace edits. Ground truth = real project database
/// (create → save assignments → pump screen → assert), Windows-only because
/// the project session opens a real SQLite file.
void main() {
  Future<void> seedNovel(ProjectDatabase db, String id, String name) async {
    final now = DateTime.now();
    await db
        .into(db.assets)
        .insert(
          AssetsCompanion.insert(
            id: id,
            projectId: 'story',
            name: name,
            type: 'story',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.stories)
        .insert(
          StoriesCompanion.insert(assetId: id, projectId: 'story', title: name),
        );
  }

  /// Creates the novel plus one character per map entry. A null value means
  /// the character exists but holds no assignment for this novel. All
  /// disk/SQLite I/O runs inside runAsync: the default fake-async zone never
  /// pumps real completions and would hang the test (run140 lesson).
  Future<ProjectSession> seed(
    WidgetTester tester,
    String name, {
    required Map<String, (Set<NarrativeRole>, NarrativeImportance)?>
    assignments,
  }) async {
    late ProjectSession session;
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('story-cast-$name-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Story Cast $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      final repo = CharacterRepositoryImpl(
        database: session.database,
        projectId: package.projectId,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      );
      await seedNovel(session.database, 'novel-first', 'First Novel');
      final repository = NarrativeAssignmentRepository(
        database: session.database,
        projectId: package.projectId,
      );
      for (final entry in assignments.entries) {
        final character = await repo.createCharacter(name: entry.key);
        final value = entry.value;
        if (value != null) {
          final (roles, importance) = value;
          await repository.saveAssignment(
            NarrativeAssignment(
              novelWorkspaceId: 'novel-first',
              characterId: character.assetId,
              roles: roles,
              importance: importance,
            ),
          );
        }
      }
    });
    return session;
  }

  Future<void> pumpCast(WidgetTester tester, ProjectSession session) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1280,
            height: 900,
            child: StoryWorkspaceScreen(
              storyId: 'novel-first',
              activeSection: 'Cast',
              loadCast: (novelWorkspaceId) => StoryCastLoader(
                database: session.database,
                projectId: session.manifest.id,
              ).load(novelWorkspaceId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'cast section lists novel characters with narrative roles in importance order',
    (tester) async {
      final session = await seed(
        tester,
        'render',
        assignments: {
          'Qowner': ({NarrativeRole.protagonist}, NarrativeImportance.major),
          'Antagonis Uji': (
            {NarrativeRole.antagonist},
            NarrativeImportance.supporting,
          ),
          'Figuran': null,
        },
      );
      await pumpCast(tester, session);

      expect(find.text('CAST'), findsOneWidget);
      expect(find.text('Qowner'), findsOneWidget);
      expect(find.text('Protagonist'), findsOneWidget);
      expect(find.text('Antagonis Uji'), findsOneWidget);
      expect(find.text('Antagonist'), findsOneWidget);
      // Characters without an assignment for THIS novel stay hidden.
      expect(find.text('Figuran'), findsNothing);
      // Importance order: major protagonist row above the antagonist row.
      final protagonistTop = tester.getTopLeft(find.text('Qowner')).dy;
      final antagonistTop = tester.getTopLeft(find.text('Antagonis Uji')).dy;
      expect(protagonistTop, lessThan(antagonistTop));
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );

  testWidgets('cast section shows explicit empty state without assignments', (
    tester,
  ) async {
    final session = await seed(tester, 'empty', assignments: const {});
    await pumpCast(tester, session);

    expect(find.text('CAST'), findsOneWidget);
    expect(find.text('No cast assigned to this novel yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: !Platform.isWindows);
}
