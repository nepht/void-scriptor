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

/// Wiring slice: the novel-side Cast section must surface each character's
/// description (biography + personality) — not just a name/role — and each
/// row must be able to open the SAME character workspace (two-way novel ↔
/// character link). Ground truth = real project database, Windows-only like
/// the existing cast section tests.
void main() {
  Future<(ProjectSession, String)> seed(
    WidgetTester tester,
    String name, {
    required String biography,
    required String personality,
  }) async {
    late ProjectSession session;
    late String nyxId;
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('cast-open-$name-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Cast Open $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      final now = DateTime.now();
      await session.database
          .into(session.database.assets)
          .insert(
            AssetsCompanion.insert(
              id: 'novel-first',
              projectId: session.manifest.id,
              name: 'First Novel',
              type: 'story',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await session.database
          .into(session.database.stories)
          .insert(
            StoriesCompanion.insert(
              assetId: 'novel-first',
              projectId: session.manifest.id,
              title: 'First Novel',
            ),
          );
      final repo = CharacterRepositoryImpl(
        database: session.database,
        projectId: session.manifest.id,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      );
      final character = await repo.createCharacter(name: 'Nyx');
      nyxId = character.assetId;
      await repo.updateCharacter(
        (await repo.getCharacter(nyxId))!.copyWith(
          biography: biography,
          personality: personality,
        ),
      );
      await NarrativeAssignmentRepository(
        database: session.database,
        projectId: session.manifest.id,
      ).saveAssignment(
        NarrativeAssignment(
          novelWorkspaceId: 'novel-first',
          characterId: nyxId,
          roles: {NarrativeRole.protagonist},
          importance: NarrativeImportance.major,
        ),
      );
    });
    return (session, nyxId);
  }

  Future<void> pumpCast(
    WidgetTester tester,
    ProjectSession session, {
    void Function(String characterId)? onTapCharacter,
  }) async {
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
              onTapCharacter: onTapCharacter,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'cast rows show the character description from the profile',
    (tester) async {
      final (session, _) = await seed(
        tester,
        'desc',
        biography: 'Penjaga menara kutub selatan.',
        personality: 'Diam, tapi menimbang setiap kata.',
      );
      await pumpCast(tester, session);

      expect(find.text('Nyx'), findsOneWidget);
      expect(
        find.textContaining('Penjaga menara kutub selatan.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Diam, tapi menimbang setiap kata.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );

  testWidgets(
    'tapping a cast row opens the same character workspace',
    (tester) async {
      final (session, nyxId) = await seed(
        tester,
        'open',
        biography: 'Pembuat gerbang es.',
        personality: 'Keras kepala.',
      );

      final opened = <String>[];
      await pumpCast(tester, session, onTapCharacter: opened.add);
      await tester.tap(find.text('Nyx'));
      await tester.pump();

      expect(opened, [nyxId]);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );
}
