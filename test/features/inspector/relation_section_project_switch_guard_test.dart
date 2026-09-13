import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/inspector/presentation/widgets/relation_section.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/relations/data/relation_repository_impl.dart';

/// Regression coverage for vs-hunt-20260913-inspector INS-BUG-04:
/// RelationSection captured its project session BEFORE awaiting the Add
/// Relation dialog and then wrote through that stale handle. If the user
/// switched projects while the dialog was open, the confirmed relation
/// landed in the PREVIOUS project's database — the exact cross-project
/// write class hunt-run157 BUG-04 closed inside SupportRelationshipSection
/// (_actionSessionStillCurrent + identical-database guard) but never here.
///
/// Contract under test: re-validate the active session after the dialog
/// await; if the project changed, abort the write entirely (no row in A,
/// no row in B).
///
/// Harness note (Windows): every dart:io / real-DB await must run inside
/// `tester.runAsync`; the fake-async test zone never completes them.
class _MutableSessionController extends ProjectSessionController {
  _MutableSessionController(this.initial);
  final ProjectSession initial;
  @override
  Future<ProjectSession?> build() async => initial;
}

void main() {
  Future<void> seedAsset(ProjectDatabase db, String id, String name) async {
    final now = DateTime.now();
    await db
        .into(db.assets)
        .insert(
          AssetsCompanion.insert(
            id: id,
            projectId: id,
            name: name,
            type: 'character',
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<ProjectSession> openSession(Directory root, String name) async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: name);
    return ProjectSessionManager().open(package);
  }

  testWidgets(
    'adding a relation while the project switches away aborts the write',
    (tester) async {
      late ProjectSession sessionA;
      late ProjectSession sessionB;

      await tester.runAsync(() async {
        final rootA = await Directory.systemTemp.createTemp('rel-guard-a-');
        final rootB = await Directory.systemTemp.createTemp('rel-guard-b-');
        addTearDown(() => rootA.delete(recursive: true));
        addTearDown(() => rootB.delete(recursive: true));
        sessionA = await openSession(rootA, 'Relation Guard A');
        sessionB = await openSession(rootB, 'Relation Guard B');
        addTearDown(sessionA.database.close);
        addTearDown(sessionB.database.close);
        await seedAsset(sessionA.database, 'char-src', 'Qowner');
        await seedAsset(sessionA.database, 'char-tgt', 'Byte');
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
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 900,
                child: RelationSection(assetId: 'char-src'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the Add Relation dialog (triggers real asset queries).
      await tester.runAsync(() async {
        await tester.tap(find.text('Add Relation'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      });
      expect(find.text('Create Relation'), findsOneWidget);

      // Pick the target character and a relation type.
      await tester.runAsync(() async {
        await tester.tap(find.text('Target asset'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Byte · character').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      });

      // The project switches while the dialog is still open.
      controllers.single.state = AsyncData<ProjectSession?>(sessionB);
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.text('Create Relation'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      });

      // Ground truth: project A must NOT contain the relation — the user
      // confirmed after leaving A, so the stale write must abort...
      final repoA = RelationRepositoryImpl(database: sessionA.database);
      final outA = await tester.runAsync(() => repoA.outgoing('char-src'));
      // ...and project B must not gain it either.
      final repoB = RelationRepositoryImpl(database: sessionB.database);
      final outB = await tester.runAsync(() => repoB.outgoing('char-src'));
      expect(outB, isEmpty);
      expect(outA, isEmpty);
    },
  );
}
