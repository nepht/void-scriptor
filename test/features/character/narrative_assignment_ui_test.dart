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

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

/// Backlog `character-roles-support` phase_one UI slice: edit narrative role,
/// importance and POV in the Character Workspace with a visible story context
/// (novel selection). Persistence ground truth is read back through the
/// production repository after a real close/reopen cycle.
void main() {
  // Real characters live in `characters` keyed by assetId; story assets carry
  // type 'story' (CreateStoryService contract) — the same wire token the
  // narrative card uses for its novel picker.
  Future<void> seedNovels(ProjectDatabase db, List<String> novels) async {
    final now = DateTime.now();
    for (final novel in novels) {
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
  }

  Future<(ProjectPackage, ProjectSession, String)> seed(
    WidgetTester tester,
    String name, {
    required List<String> novels,
  }) async {
    late Directory root;
    late ProjectPackage package;
    late ProjectSession session;
    late String characterId;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('narr-ui-$name-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Narrative UI $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      final repo = CharacterRepositoryImpl(
        database: session.database,
        projectId: package.projectId,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      );
      final character = await repo.createCharacter(name: 'Qowner');
      characterId = character.assetId;
      await seedNovels(session.database, novels);
    });
    return (package, session, characterId);
  }

  Future<void> pumpWorkspace(
    WidgetTester tester,
    ProjectPackage package,
    ProjectSession session,
    String characterId, {
    Size size = const Size(1280, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(
            () => _FakeProjectSessionController(session),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
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
    'renders narrative assignment editing with visible novel context',
    (tester) async {
      final (package, session, characterId) = await seed(
        tester,
        'render',
        novels: const ['First Novel', 'Second Novel'],
      );
      await pumpWorkspace(tester, package, session, characterId);

      // Card + novel picker show the project's novels (story context), not a
      // bare UUID. Open the dropdown to prove every novel is listed.
      expect(find.text('Narrative Assignment'), findsOneWidget);
      await tester.tap(find.text('First Novel'));
      await tester.pumpAndSettle();
      expect(find.text('First Novel'), findsWidgets);
      expect(find.text('Second Novel'), findsOneWidget);
      await tester.tap(find.text('Second Novel').last);
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is DropdownButton<String> && w.value == 'novel-second-novel',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );

  testWidgets(
    'saving roles/importance/POV persists per novel and survives close/reopen',
    (tester) async {
      final (package, session, characterId) = await seed(
        tester,
        'save',
        novels: const ['First Novel'],
      );
      await pumpWorkspace(tester, package, session, characterId);

      // Select role chips + importance + POV via their dropdowns, then Save.
      await tester.tap(find.text('Protagonist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Antagonist'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<NarrativeImportance>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Major').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<NarrativePov>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes').last);
      await tester.pumpAndSettle();
      final saveBtn = find.descendant(
        of: find.byType(NarrativeAssignmentCard),
        matching: find.widgetWithText(FilledButton, 'Save'),
      );
      await tester.ensureVisible(saveBtn.last);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn.last);
      await tester.pumpAndSettle();

      // Ground truth: close and reopen the database, read through the
      // production repository. Real IO needs runAsync inside testWidgets.
      final saved = await tester.runAsync(() async {
        final dbPath = package.databaseFile.path;
        await session.database.close();
        final reopened = await ProjectDatabaseService().open(dbPath);
        addTearDown(reopened.close);
        return NarrativeAssignmentRepository(
          database: reopened,
          projectId: package.projectId,
        ).getAssignment(
          novelWorkspaceId: 'novel-first-novel',
          characterId: characterId,
        );
      });
      expect(saved, isNotNull);
      expect(saved!.roles, {
        NarrativeRole.protagonist,
        NarrativeRole.antagonist,
      });
      expect(saved.importance, NarrativeImportance.major);
      expect(saved.pov, NarrativePov.yes);
    },
    skip: !Platform.isWindows,
  );

  testWidgets(
    'saving with no roles removes the assignment (default-unspecified contract)',
    (tester) async {
      final (package, session, characterId) = await seed(
        tester,
        'clear',
        novels: const ['First Novel'],
      );
      // Pre-save assignments for BOTH novels. The edited novel's row must
      // disappear on Save; the other novel's row must stay. A missed tap can
      // never pass vacuously because the edited row really exists first.
      final repo = NarrativeAssignmentRepository(
        database: session.database,
        projectId: package.projectId,
      );
      for (final novel in const {'novel-first-novel', 'novel-other-novel'}) {
        await repo.saveAssignment(
          NarrativeAssignment(
            novelWorkspaceId: novel,
            characterId: characterId,
            roles: const {NarrativeRole.protagonist},
            importance: NarrativeImportance.unspecified,
            pov: NarrativePov.unspecified,
          ),
        );
      }

      // Taller surface keeps the card's Save button on-screen for a real
      // hit-tested tap.
      await pumpWorkspace(
        tester,
        package,
        session,
        characterId,
        size: const Size(1280, 1400),
      );
      // Deselect the only role: the assignment becomes empty.
      await tester.tap(find.text('Protagonist'));
      await tester.pumpAndSettle();
      final saveBtn = find.descendant(
        of: find.byType(NarrativeAssignmentCard),
        matching: find.widgetWithText(FilledButton, 'Save'),
      );
      await tester.ensureVisible(saveBtn.last);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn.last);
      await tester.pumpAndSettle();

      final opened = await tester.runAsync(() async {
        final reopened = await ProjectDatabaseService().open(
          package.databaseFile.path,
        );
        addTearDown(reopened.close);
        return reopened;
      });
      final reopenedRepo = NarrativeAssignmentRepository(
        database: opened!,
        projectId: package.projectId,
      );
      // The edited novel has no row.
      expect(
        await reopenedRepo.getAssignment(
          novelWorkspaceId: 'novel-first-novel',
          characterId: characterId,
        ),
        isNull,
      );
      // The other novel's row stays intact: clearing never leaks.
      expect(
        await reopenedRepo.getAssignment(
          novelWorkspaceId: 'novel-other-novel',
          characterId: characterId,
        ),
        isNotNull,
      );
    },
    skip: !Platform.isWindows,
  );
}
