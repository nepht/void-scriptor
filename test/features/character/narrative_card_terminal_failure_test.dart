import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';
import 'package:void_scriptor/features/character/presentation/widgets/narrative_assignment_card.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspaces/application/narrative_assignment_repository.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

class _FakeSessionController extends ProjectSessionController {
  _FakeSessionController(this.session);
  final ProjectSession? session;
  @override
  Future<ProjectSession?> build() async => session;
}

/// Failing double: every load throws (deterministic infrastructure failure).
class _AlwaysFailingRepo implements NarrativeAssignmentRepository {
  int loadAttempts = 0;

  @override
  Future<NarrativeAssignment?> getAssignment({
    required String novelWorkspaceId,
    required String characterId,
  }) async {
    loadAttempts++;
    throw StateError('disk unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Delegating double whose load failure is toggleable; successes delegate to
/// the real repository so the Retry path exercises real persistence.
class _FlakyRepo implements NarrativeAssignmentRepository {
  _FlakyRepo(this._inner, {this.failNextLoads = 0});
  final NarrativeAssignmentRepository _inner;
  int failNextLoads;

  @override
  Future<NarrativeAssignment?> getAssignment({
    required String novelWorkspaceId,
    required String characterId,
  }) async {
    if (failNextLoads > 0) {
      failNextLoads--;
      throw StateError('transient disk failure');
    }
    return _inner.getAssignment(
      novelWorkspaceId: novelWorkspaceId,
      characterId: characterId,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Deterministic fake that keeps the options list populated while the
/// session is null — the exact BUG-09 window (session vanished between a
/// successful provider build and a novel pick), staged without timing.
class _OptionsWithoutSessionController extends ProjectSessionController {
  @override
  Future<ProjectSession?> build() async => null;
}

/// hunt-run157 BUG-08 (Referee REAL BUG Low) + BUG-09: a failed assignment
/// load left the card rendering the error line AND an eternal
/// "Loading assignment..." (the error branch never set
/// _loadedForCurrentNovel), with no retry control; a vanished session left
/// the card stuck on "Loading assignment..." silently. Contract: a failed
/// load is a terminal state that REPLACES the editor with an explicit error
/// and a Retry control; a Retry performs a real reload; a missing session
/// surfaces an explicit error instead of a silent eternal loading state.
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
      root = await Directory.systemTemp.createTemp('narr-fail-$name-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Narrative Fail $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      final now = DateTime.now();
      await session.database
          .into(session.database.assets)
          .insert(
            AssetsCompanion.insert(
              id: 'novel-1',
              projectId: 'story',
              name: 'Novel One',
              type: 'story',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await session.database
          .into(session.database.stories)
          .insert(
            StoriesCompanion.insert(
              assetId: 'novel-1',
              projectId: 'story',
              title: 'Novel One',
            ),
          );
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
    String characterId, {
    ProjectSession? session,
    NarrativeAssignmentRepositoryFactory? repoFactory,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (session != null)
            projectSessionProvider.overrideWith(
              () => _FakeSessionController(session),
            ),
          if (repoFactory != null)
            narrativeAssignmentRepositoryFactoryProvider.overrideWithValue(
              repoFactory,
            ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 1400,
              child: CharacterWorkspaceScreen(
                characterId: characterId,
                activeSection: 'Story',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'failed load shows terminal error with Retry, not eternal loading (BUG-08)',
    (tester) async {
      final (package, session, characterId) = await seed(tester, 'a');
      final repo = _AlwaysFailingRepo();
      await pumpWorkspace(
        tester,
        characterId,
        session: session,
        repoFactory: (database, projectId) => repo,
      );

      expect(find.textContaining('Could not load assignment'), findsOneWidget);
      // The defect: the editor branch never opens, but the loading line is
      // still rendered forever alongside the error, with no retry control.
      expect(find.text('Loading assignment...'), findsNothing);
      expect(find.widgetWithText(FilterChip, 'Protagonist'), findsNothing);
      final retry = find.widgetWithText(ActionChip, 'Retry');
      expect(retry, findsOneWidget);
      // Failed state is terminal: retry re-runs the load through the real
      // repository path (still failing here, so attempts must increment).
      final before = repo.loadAttempts;
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(repo.loadAttempts, greaterThan(before));
      // package/session teardown asserted via addTearDown above.
      expect(package.projectId, isNotEmpty);
    },
  );

  testWidgets('Retry performs a real reload and restores the editor (BUG-08)', (
    tester,
  ) async {
    final (package, session, characterId) = await seed(tester, 'b');
    final real = NarrativeAssignmentRepository(
      database: session.database,
      projectId: package.projectId,
    );
    final repo = _FlakyRepo(real, failNextLoads: 1);
    await pumpWorkspace(
      tester,
      characterId,
      session: session,
      repoFactory: (database, projectId) => repo,
    );

    expect(find.textContaining('Could not load assignment'), findsOneWidget);
    // Editor is hidden while not loaded: no role chips from the card.
    expect(find.widgetWithText(FilterChip, 'Protagonist'), findsNothing);
    final retry = find.widgetWithText(ActionChip, 'Retry');
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not load assignment'), findsNothing);
    // Editor is restored: role chips and Save are interactive again.
    expect(find.widgetWithText(FilterChip, 'Protagonist'), findsOneWidget);
  });

  testWidgets(
    'missing session surfaces an explicit error instead of silent eternal loading (BUG-09)',
    (tester) async {
      final (_, _, characterId) = await seed(tester, 'c');
      // BUG-09 window staged deterministically: the options provider holds a
      // populated list (as if built while the session existed) but the
      // session is gone when the pick's load runs. The card's auto-pick
      // fires, _loadFor sees a null session, and the old code returned
      // silently into an eternal "Loading assignment..." state. The card is
      // mounted directly because the full workspace screen itself requires a
      // live session to render.
      await tester.binding.setSurfaceSize(const Size(1280, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(
              () => _OptionsWithoutSessionController(),
            ),
            narrativeNovelOptionsProvider.overrideWith(
              (ref) => Future.value(const [
                NarrativeNovelOption(id: 'novel-1', name: 'Novel One'),
              ]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 1400,
                child: NarrativeAssignmentCard(characterId: characterId),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Loading assignment...'), findsNothing);
      expect(find.textContaining('No project session'), findsOneWidget);
    },
  );
}
