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

/// Session controller whose emitted session can be swapped mid-test to
/// simulate a project switch while an edit dialog await is in flight.
class _MutableSessionController extends ProjectSessionController {
  _MutableSessionController(this.initial);
  final ProjectSession initial;
  @override
  Future<ProjectSession?> build() async => initial;
}

/// Regression coverage for hunt-20260909 BUG-04: the Support Relationship
/// section captures its [NarrativeAssignmentRepository] (bound to the
/// entry session's database + projectId) BEFORE awaiting the edit dialog.
/// If the user switches projects while the dialog is open, the section
/// survives (only its rows reload) and the confirmed edit is still written
/// into the PREVIOUS project's database — a silent write into a project the
/// user already left.
///
/// Contract under test: re-validate the session identity after the dialog
/// await; if the project changed, abort the write entirely.
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

  Widget inspectorTree(String characterId) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1280,
        height: 900,
        child: CharacterInspector(characterId: characterId),
      ),
    ),
  );

  testWidgets(
    'editing support while the project switches away aborts the write',
    (tester) async {
      late ProjectPackage packageA;
      late ProjectSession sessionA;
      late ProjectSession sessionB;
      String aId = '';
      String bId = '';
      final repositoryA = ValueNotifier<NarrativeAssignmentRepository?>(null);
      final repositoryB = ValueNotifier<NarrativeAssignmentRepository?>(null);

      await tester.runAsync(() async {
        final rootA = await Directory.systemTemp.createTemp('support-guard-a-');
        final rootB = await Directory.systemTemp.createTemp('support-guard-b-');
        addTearDown(() => rootA.delete(recursive: true));
        addTearDown(() => rootB.delete(recursive: true));

        packageA = await ProjectPackageService(
          rootDirectory: rootA,
        ).create(name: 'Support Guard A');
        sessionA = await ProjectSessionManager().open(packageA);
        sessionB = await ProjectSessionManager().open(
          await ProjectPackageService(
            rootDirectory: rootB,
          ).create(name: 'Support Guard B'),
        );
        addTearDown(sessionA.database.close);
        addTearDown(sessionB.database.close);

        repositoryA.value = NarrativeAssignmentRepository(
          database: sessionA.database,
          projectId: packageA.projectId,
        );
        repositoryB.value = NarrativeAssignmentRepository(
          database: sessionB.database,
          projectId: sessionB.manifest.id,
        );

        final repo = CharacterRepositoryImpl(
          database: sessionA.database,
          projectId: packageA.projectId,
          paths: ProjectPaths(rootDirectory: packageA.root.parent),
        );
        final a = await repo.createCharacter(name: 'Qowner');
        final b = await repo.createCharacter(name: 'Byte');
        await seedNovel(sessionA.database, 'First Novel');
        aId = a.assetId;
        bId = b.assetId;
        await repositoryA.value!.saveSupport(
          SupportRelationship(
            sourceCharacterId: aId,
            supportedId: bId,
            storyNovelWorkspaceId: 'novel-first-novel',
            type: SupportType.mentor,
          ),
        );
      });

      final controllers = <_MutableSessionController>[];
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
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
      await tester.pumpAndSettle();

      expect(find.text('Byte'), findsOneWidget);

      // Open the edit dialog for the existing mentor row (the tap triggers
      // the dialog's real asset queries — runAsync required).
      await tester.runAsync(() async {
        await tester.tap(find.text('Byte'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      });
      expect(find.text('Edit Support'), findsOneWidget);

      // Change the type so a completed write is detectable in the database.
      await tester.runAsync(() async {
        await tester.tap(find.text('Mentor'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Protector').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      });

      // The project switches while the edit dialog is still open.
      controllers.single.state = AsyncData<ProjectSession?>(sessionB);
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.text('Save Support'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      });

      // Ground truth: project A's row must be untouched (still mentor). The
      // user edited in A but confirmed the dialog after switching to B, so
      // the write context no longer matches what the user sees.
      final rowsA = (await tester.runAsync(
        () => repositoryA.value!.listSupports(aId),
      ))!;
      expect(rowsA, hasLength(1));
      expect(rowsA.single.type, SupportType.mentor);

      // Project B never gains the row either.
      final rowsB = (await tester.runAsync(
        () => repositoryB.value!.listSupports(aId),
      ))!;
      expect(rowsB, isEmpty);
    },
  );
}
