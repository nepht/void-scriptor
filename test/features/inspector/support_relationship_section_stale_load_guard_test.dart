import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/inspector/presentation/widgets/support_relationship_section.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspaces/application/narrative_assignment_repository.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

/// Session controller whose emitted session can be swapped while an
/// in-flight `_load()` await is still suspended — the exact gap
/// vs-hunt-20260913-inspector INS-BUG-06 claims (Referee: `_load()` awaits
/// `repository.listSupports` + `assetDao.getAllAssets` and calls `setState`
/// guarded only by `mounted`, so a project switch during the gap lets the
/// old project's data enter the new session's state).
class _MutableSessionController extends ProjectSessionController {
  _MutableSessionController(this.initial);
  final ProjectSession initial;
  @override
  Future<ProjectSession?> build() async => initial;
}

/// Contract pinned here (INS-BUG-06 verification, run281):
/// 1. A project switch that lands WHILE the first `_load()` is in flight
///    must end with the NEW project's rows rendered and the OLD project's
///    rows never displayed.
/// 2. A project that closes mid-load must leave the section in its
///    not-ready state, never showing the closed project's rows.
/// 3. Ground truth: neither project's database is mutated by the switch.
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

  /// Creates a disposable project with source character `sourceName`,
  /// support target `targetName`, and one mentor support row.
  Future<
    (ProjectPackage, ProjectSession, String, NarrativeAssignmentRepository)
  >
  seedProject(String dirPrefix, String projectName, String targetName) async {
    final root = await Directory.systemTemp.createTemp(dirPrefix);
    addTearDown(() => root.delete(recursive: true));
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: projectName);
    final session = await ProjectSessionManager().open(package);
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
    final source = await repo.createCharacter(name: 'Qowner');
    final target = await repo.createCharacter(name: targetName);
    await seedNovel(session.database, 'First Novel');
    await repository.saveSupport(
      SupportRelationship(
        sourceCharacterId: source.assetId,
        supportedId: target.assetId,
        storyNovelWorkspaceId: 'novel-first-novel',
        type: SupportType.mentor,
      ),
    );
    return (package, session, source.assetId, repository);
  }

  Widget inspectorTree(String characterId) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1280,
        height: 900,
        child: SupportRelationshipSection(assetId: characterId),
      ),
    ),
  );

  testWidgets(
    'in-flight support load from a closed project never renders its rows',
    (tester) async {
      late ProjectSession sessionA;
      late NarrativeAssignmentRepository repositoryA;
      String aId = '';

      await tester.runAsync(() async {
        final seeded = await seedProject(
          'stale-close-a-',
          'Stale Close A',
          'Byte',
        );
        sessionA = seeded.$2;
        aId = seeded.$3;
        repositoryA = seeded.$4;
      });

      final controllers = <_MutableSessionController>[];
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              projectSessionProvider.overrideWith(() {
                final controller = _MutableSessionController(sessionA);
                controllers.add(controller);
                return controller;
              }),
            ],
            child: inspectorTree(aId),
          ),
        );
        // The project closes in the same synchronous turn the widget is
        // attached: initState's _load() is guaranteed suspended on its
        // database await when the session goes away.
        controllers.single.state = const AsyncData<ProjectSession?>(null);
        await tester.pump();
        // Drain every in-flight fetch (stale A load included).
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      });

      // The detached section stays in its not-ready state (null-session
      // contract, hunt-run157 BUG-07): never the closed project's rows.
      expect(
        find.text('Byte'),
        findsNothing,
        reason:
            'stale _load() from a closed session must never render '
            'the previous project rows (INS-BUG-06)',
      );
      expect(find.text('Loading...'), findsWidgets);

      // Ground truth: the simulated close detached the session only; A's
      // data is untouched.
      final rowsA = (await tester.runAsync(
        () => repositoryA.listSupports(aId),
      ))!;
      expect(rowsA, hasLength(1));
      expect(rowsA.single.type, SupportType.mentor);
    },
  );

  testWidgets(
    'support load switched to another project mid-flight ends on the new '
    'project rows only',
    (tester) async {
      late ProjectSession sessionA;
      late ProjectSession sessionB;
      late NarrativeAssignmentRepository repositoryA;
      late NarrativeAssignmentRepository repositoryB;
      String aId = '';
      String bId = '';

      await tester.runAsync(() async {
        final seededA = await seedProject(
          'stale-switch-a-',
          'Stale Switch A',
          'Byte',
        );
        sessionA = seededA.$2;
        aId = seededA.$3;
        repositoryA = seededA.$4;
        final seededB = await seedProject(
          'stale-switch-b-',
          'Stale Switch B',
          'Sable',
        );
        sessionB = seededB.$2;
        bId = seededB.$3;
        repositoryB = seededB.$4;
      });

      final controllers = <_MutableSessionController>[];
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              projectSessionProvider.overrideWith(() {
                final controller = _MutableSessionController(sessionA);
                controllers.add(controller);
                return controller;
              }),
            ],
            child: inspectorTree(bId),
          ),
        );
        // Mid-first-load switch: A's load is suspended on its database
        // await; the provider now points at project B (whose own load will
        // race A's stale completion).
        controllers.single.state = AsyncData<ProjectSession?>(sessionB);
        await tester.pump();
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      });

      // After settling on B, the old project's target row must never be
      // displayed in B's section.
      expect(
        find.text('Byte'),
        findsNothing,
        reason:
            'project A stale load must not paint rows inside project B '
            '(INS-BUG-06)',
      );
      expect(find.text('Sable'), findsWidgets);

      // Ground truth: both projects keep exactly their own row.
      final rowsA = (await tester.runAsync(
        () => repositoryA.listSupports(aId),
      ))!;
      final rowsB = (await tester.runAsync(
        () => repositoryB.listSupports(bId),
      ))!;
      expect(rowsA, hasLength(1));
      expect(rowsB, hasLength(1));
    },
  );
}
