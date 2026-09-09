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

class _StaticSessionController extends ProjectSessionController {
  _StaticSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

/// Regression coverage for hunt-20260909 BUG-03: editing a support
/// relationship whose coordinates change must be ATOMIC. The old
/// implementation removed the previous row and then saved the updated one
/// in two separate autocommit statements, so a failure at save time (the
/// realistic vector: any SQLite write error, staged here with a real
/// RAISE(ABORT) trigger on the INSERT) silently lost the original
/// relationship — the UI only showed an error snackbar.
///
/// Contract under test:
/// 1. Repository `replaceSupport` groups remove+insert in ONE transaction;
///    when the insert fails, the original row survives.
/// 2. The same holds through the production UI edit journey.
///
/// Harness note (Windows): every dart:io / real-DB await must run inside
/// `tester.runAsync`; the fake-async test zone never completes them.
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

  /// Stages a REAL SQLite write failure exactly at INSERT time (hunt BUG-03
  /// injection): the trigger aborts every INSERT on the support table while
  /// DELETE statements keep working — the old remove-then-save therefore
  /// committed the remove and lost the row, the transactional replace rolls
  /// both back. Scoped to the disposable test database.
  Future<void> injectInsertFailure(ProjectDatabase db) async {
    await db.customStatement(
      'CREATE TRIGGER support_insert_abort '
      'BEFORE INSERT ON character_support_relationships '
      'BEGIN SELECT RAISE(ABORT, \'injected insert failure\'); END',
    );
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

  testWidgets('repository replaceSupport rolls back when the insert fails', (
    tester,
  ) async {
    late ProjectPackage package;
    late ProjectSession session;
    String aId = '';

    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('support-atomic-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Support Atomic');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);

      final repository = NarrativeAssignmentRepository(
        database: session.database,
        projectId: package.projectId,
      );
      final repo = CharacterRepositoryImpl(
        database: session.database,
        projectId: package.projectId,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      );
      final a = await repo.createCharacter(name: 'Qowner');
      final b = await repo.createCharacter(name: 'Byte');
      await seedNovel(session.database, 'First Novel');
      // Two novels so the edit can legitimately move the relationship to a
      // different story (coordinate change).
      await seedNovel(session.database, 'Second Novel');
      await repository.saveSupport(
        SupportRelationship(
          sourceCharacterId: a.assetId,
          supportedId: b.assetId,
          storyNovelWorkspaceId: 'novel-first-novel',
          type: SupportType.mentor,
        ),
      );
      aId = a.assetId;
      await injectInsertFailure(session.database);
    });

    final repository = NarrativeAssignmentRepository(
      database: session.database,
      projectId: package.projectId,
    );
    final original = (await tester.runAsync(
      () => repository.listSupports(aId),
    ))!.single;

    final updated = SupportRelationship(
      sourceCharacterId: original.sourceCharacterId,
      supportedId: original.supportedId,
      storyNovelWorkspaceId: 'novel-second-novel',
      type: SupportType.protector,
    );

    // The INSERT inside the transaction fails; the remove must roll back.
    // (try/catch inside runAsync: the failure must be captured, not leaked
    // to the zone — expectLater cannot observe this real-async future.)
    Object? caught;
    await tester.runAsync(() async {
      try {
        await repository.replaceSupport(previous: original, updated: updated);
      } catch (error) {
        caught = error;
      }
    });
    expect(caught, isNotNull, reason: 'insert failure must propagate');

    // Atomicity contract: the remove of the original row must NOT be
    // committed when the save inside the same operation fails.
    final rowsAfter = (await tester.runAsync(
      () => repository.listSupports(aId),
    ))!;
    expect(rowsAfter, hasLength(1), reason: 'original row must survive');
    expect(rowsAfter.single.storyNovelWorkspaceId, 'novel-first-novel');
    expect(rowsAfter.single.type, SupportType.mentor);
  });

  testWidgets('failed edit save through the UI keeps the original row', (
    tester,
  ) async {
    late ProjectPackage package;
    late ProjectSession session;
    String aId = '';

    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('support-atomic-ui-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Support Atomic UI');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);

      final repository = NarrativeAssignmentRepository(
        database: session.database,
        projectId: package.projectId,
      );
      final repo = CharacterRepositoryImpl(
        database: session.database,
        projectId: package.projectId,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      );
      final a = await repo.createCharacter(name: 'Qowner');
      final b = await repo.createCharacter(name: 'Byte');
      await seedNovel(session.database, 'First Novel');
      await seedNovel(session.database, 'Second Novel');
      await repository.saveSupport(
        SupportRelationship(
          sourceCharacterId: a.assetId,
          supportedId: b.assetId,
          storyNovelWorkspaceId: 'novel-first-novel',
          type: SupportType.mentor,
        ),
      );
      aId = a.assetId;
      // Failure fires exactly when the confirmed edit is written.
      await injectInsertFailure(session.database);
    });

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(
            () => _StaticSessionController(session),
          ),
        ],
        child: inspectorTree(aId),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Byte'), findsOneWidget);

    // Open the edit dialog and move the relationship to the second novel
    // (coordinates change: the defensive remove-then-save branch).
    await tester.runAsync(() async {
      await tester.tap(find.text('Byte'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
    expect(find.text('Edit Support'), findsOneWidget);

    // The supported-character and story pickers are intentionally locked in
    // edit mode (coordinate changes are unreachable through the UI; the
    // repository test above covers that path), so the UI journey changes an
    // attribute (type) while the coordinates stay fixed; the staged trigger
    // then fails exactly at the INSERT of the confirmed edit.
    await tester.runAsync(() async {
      await tester.tap(find.text('mentor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('protector').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    await tester.runAsync(() async {
      await tester.tap(find.text('Save Support'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    // The failure must be surfaced, not swallowed.
    expect(
      find.textContaining('Failed to save support relationship'),
      findsOneWidget,
    );

    // Ground truth: the original relationship survives (atomic replace), it
    // was not silently lost by a committed remove.
    final rowsAfter = (await tester.runAsync(
      () => NarrativeAssignmentRepository(
        database: session.database,
        projectId: package.projectId,
      ).listSupports(aId),
    ))!;
    expect(rowsAfter, hasLength(1), reason: 'original row must survive');
    expect(rowsAfter.single.storyNovelWorkspaceId, 'novel-first-novel');
    expect(rowsAfter.single.type, SupportType.mentor);
  });
}
