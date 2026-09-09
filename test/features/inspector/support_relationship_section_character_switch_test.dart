import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/inspector/presentation/inspectors/character_inspector.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspaces/application/narrative_assignment_repository.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

/// Regression coverage for the hunt-run157 referee observation: the Support
/// Relationship section State is instantiated without a key and only guards on
/// session id, so switching characters inside one project reuses the State and
/// renders the previous character's rows. Deleting such a stale row removes
/// the PREVIOUS character's data from the database.
///
/// Contract under test:
/// 1. Switching characters in place must never show the other character's
///    support rows.
/// 2. Deleting a row from character B's screen must never delete a row whose
///    source is character A (ground truth read back through the production
///    repository).
void main() {
  Future<void> seedNovel(ProjectDatabase db, String novel) async {
    final now = DateTime.now();
    final id = 'novel-${novel.toLowerCase().replaceAll(' ', '-')}';
    await db
        .into(db.assets)
        .insert(
          AssetsCompanion.insert(
            id: id,
            projectId: 'story',
            name: novel,
            type: 'story',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.stories)
        .insert(
          StoriesCompanion.insert(
            assetId: id,
            projectId: 'story',
            title: novel,
          ),
        );
  }

  Future<
    (
      ProjectPackage,
      ProjectSession,
      String,
      String,
      NarrativeAssignmentRepository,
    )
  >
  seed(WidgetTester tester, String name) async {
    late Directory root;
    late ProjectPackage package;
    late ProjectSession session;
    late String aId;
    late String bId;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('support-switch-$name-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Support Switch $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      final repo = CharacterRepositoryImpl(
        database: session.database,
        projectId: package.projectId,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      );
      aId = (await repo.createCharacter(name: 'Qowner')).assetId;
      bId = (await repo.createCharacter(name: 'Byte')).assetId;
      await seedNovel(session.database, 'First Novel');
    });
    final repository = NarrativeAssignmentRepository(
      database: session.database,
      projectId: package.projectId,
    );
    return (package, session, aId, bId, repository);
  }

  Widget inspectorTree(String characterId) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1280,
        height: 900,
        child: CharacterInspector(characterId: characterId),
      ),
    ),
  );

  Future<void> pumpInspector(
    WidgetTester tester,
    ProjectSession session,
    String characterId,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(
            () => _FakeProjectSessionController(session),
          ),
        ],
        child: inspectorTree(characterId),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'switching characters in place does not show the previous character rows',
    (tester) async {
      final (_, session, aId, bId, repository) = await seed(tester, 'stale');
      await repository.saveSupport(
        SupportRelationship(
          sourceCharacterId: aId,
          supportedId: bId,
          storyNovelWorkspaceId: 'novel-first-novel',
          type: SupportType.mentor,
        ),
      );

      await pumpInspector(tester, session, aId);
      expect(find.text('Byte'), findsOneWidget);

      // Same tree shape, different character: SupportRelationshipSection gets
      // an in-place widget update, so its State (and rows) would straddle
      // characters if the section only guards on session id.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(
              () => _FakeProjectSessionController(session),
            ),
          ],
          child: inspectorTree(bId),
        ),
      );
      await tester.pumpAndSettle();

      // Character B has no support relationships; A's row must be gone.
      expect(find.text('No support relationships yet'), findsOneWidget);
      expect(find.text('Byte'), findsNothing);
    },
  );

  testWidgets('deleting on character B screen never deletes character A row', (
    tester,
  ) async {
    final (_, session, aId, bId, repository) = await seed(tester, 'delete');
    await repository.saveSupport(
      SupportRelationship(
        sourceCharacterId: aId,
        supportedId: bId,
        storyNovelWorkspaceId: 'novel-first-novel',
        type: SupportType.mentor,
      ),
    );

    await pumpInspector(tester, session, aId);
    expect(find.text('Byte'), findsOneWidget);

    // Switch to B in place (section State reuses stale A rows pre-fix).
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(
            () => _FakeProjectSessionController(session),
          ),
        ],
        child: inspectorTree(bId),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to B in place. Pre-fix, the section reused its State and
    // rendered A's row with a live delete action on B's screen; deleting it
    // removed A's data under B's session. The section must show no
    // actionable row for B (B has none) and A's row must survive intact.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(
            () => _FakeProjectSessionController(session),
          ),
        ],
        child: inspectorTree(bId),
      ),
    );
    await tester.pumpAndSettle();

    // No stale row (and therefore no stale delete action) on B's screen.
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.text('No support relationships yet'), findsOneWidget);

    // Ground truth: A's support row is untouched after the switch.
    final aRows = (await tester.runAsync(() => repository.listSupports(aId)))!;
    expect(aRows, hasLength(1));
    expect(aRows.single.sourceCharacterId, aId);
    expect(aRows.single.supportedId, bId);
  });
}
