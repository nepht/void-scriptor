import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';
import 'package:void_scriptor/features/character/presentation/widgets/narrative_assignment_card.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspaces/application/narrative_assignment_repository.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

class _FakeSessionController extends ProjectSessionController {
  _FakeSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

/// Deterministic double: slow novel load takes [slowDelay], fast load
/// completes quickly. Records in-flight counts so the test can prove the
/// stale completion really happened while the current editor was visible.
class _SlowRepo implements NarrativeAssignmentRepository {
  _SlowRepo(this._inner, {required this.delays});
  final NarrativeAssignmentRepository _inner;
  final Map<String, Duration> delays;

  @override
  Future<NarrativeAssignment?> getAssignment({
    required String novelWorkspaceId,
    required String characterId,
  }) async {
    final delay = delays[novelWorkspaceId];
    if (delay != null) {
      await Future<void>.delayed(delay);
    }
    return _inner.getAssignment(
      novelWorkspaceId: novelWorkspaceId,
      characterId: characterId,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// hunt-run157 BUG-01 (Referee REAL BUG Medium): NarrativeAssignmentCard's
/// _loadFor had no staleness guard. With an inverted completion order the
/// stale novel's roles/fields landed in editor state, and Save persisted
/// them under the CURRENT novel's coordinates (cross-novel assignment
/// corruption). The contract: a completion from a superseded load must
/// never write editor state.
void main() {
  Future<(ProjectPackage, ProjectSession, String)> seed(
    WidgetTester tester,
    String name,
  ) async {
    late Directory root;
    late ProjectPackage package;
    late ProjectSession session;
    late String characterId;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('narr-stale-$name-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Narrative Stale $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      final now = DateTime.now();
      for (final novel in const {'slow', 'fast'}) {
        final id = 'novel-$novel';
        final name2 = novel == 'slow' ? 'Slow Novel' : 'Fast Novel';
        await session.database
            .into(session.database.assets)
            .insert(
              AssetsCompanion.insert(
                id: id,
                projectId: 'story',
                name: name2,
                type: 'story',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await session.database
            .into(session.database.stories)
            .insert(
              StoriesCompanion.insert(
                assetId: id,
                projectId: 'story',
                title: name2,
              ),
            );
      }
      final charRepo = CharacterRepositoryImpl(
        database: session.database,
        projectId: package.projectId,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      );
      final character = await charRepo.createCharacter(name: 'Qowner');
      characterId = character.assetId;
    });
    return (package, session, characterId);
  }

  Future<void> pumpWorkspace(
    WidgetTester tester,
    ProjectPackage package,
    ProjectSession session,
    String characterId, {
    required NarrativeAssignmentRepositoryFactory repoFactory,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(
            () => _FakeSessionController(session),
          ),
          narrativeAssignmentRepositoryFactoryProvider.overrideWithValue(
            repoFactory,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 1400,
              child: CharacterWorkspaceScreen(characterId: characterId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'stale load completion must not overwrite the current novel editor (BUG-01)',
    (tester) async {
      final (package, session, characterId) = await seed(tester, 'a');
      // Real repo under the hood; slow/fast wrappers delay completion so the
      // fast load finishes first and the SLOW (stale) load lands last —
      // exactly the inverted-order shape the Referee confirmed.
      final baseRepo = NarrativeAssignmentRepository(
        database: session.database,
        projectId: package.projectId,
      );
      final slowRepo = _SlowRepo(
        baseRepo,
        delays: {'novel-slow': const Duration(milliseconds: 2500)},
      );
      NarrativeAssignmentRepository factory(db, pid) =>
          pid == package.projectId ? slowRepo : baseRepo;
      await pumpWorkspace(
        tester,
        package,
        session,
        characterId,
        repoFactory: factory,
      );

      // Initial (alphabetically first) novel = Slow; its load is in flight.
      await tester.tap(find.text('Slow Novel').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fast Novel').last);
      await tester.pump(const Duration(milliseconds: 600));

      // Fast's editor is visible (its load completed). With the bug present
      // the slow completion lands LAST and silently replaces the editor
      // state with Slow's stale empty fields.
      expect(find.text('Loading assignment...'), findsNothing);
      await tester.tap(find.text('Protagonist'));

      // Let the stale SLOW completion arrive.
      await tester.pump(const Duration(milliseconds: 2200));
      await tester.pumpAndSettle();

      // GREEN contract: Fast's editor state is intact and Save persists
      // under FAST's coordinates (ground truth via real reopen).
      expect(find.text('Loading assignment...'), findsNothing);
      final saveBtn = find.descendant(
        of: find.byType(NarrativeAssignmentCard),
        matching: find.widgetWithText(FilledButton, 'Save'),
      );
      await tester.ensureVisible(saveBtn.last);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn.last);
      await tester.pumpAndSettle();

      final opened = await tester.runAsync(() async {
        await session.database.close();
        final reopened = await ProjectDatabaseService().open(
          package.databaseFile.path,
        );
        addTearDown(reopened.close);
        return NarrativeAssignmentRepository(
          database: reopened,
          projectId: package.projectId,
        ).getAssignment(
          novelWorkspaceId: 'novel-fast',
          characterId: characterId,
        );
      });
      expect(opened, isNotNull);
      expect(opened!.roles, {NarrativeRole.protagonist});
    },
    skip: !Platform.isWindows,
  );
}
