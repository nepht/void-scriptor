import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/assets/domain/asset_relation_type.dart';
import 'package:void_scriptor/features/bible/application/create_faction_service.dart';
import 'package:void_scriptor/features/bible/presentation/project_bible_workspace_screen.dart';
import 'package:void_scriptor/features/character/application/create_character_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/relations/application/create_relation_service.dart';
import 'package:void_scriptor/features/relations/data/relation_repository_impl.dart';

/// vs-hunt-20260914-bible-ui BUI-BUG-03 (Referee: REAL BUG, Medium).
/// The FACTIONS and RELATIONSHIP MAP sections reload only on a
/// null -> non-null session transition. On a direct project A -> project B
/// switch (both non-null), the retained state keeps displaying project A's
/// rows under project B. This reproduces that exact mechanism with two
/// disposable temp projects and a switchable session controller — no
/// user data involved.
class _SwitchableSessionController extends ProjectSessionController {
  _SwitchableSessionController(this.session);

  ProjectSession session;

  @override
  Future<ProjectSession?> build() async => session;

  void switchTo(ProjectSession next) {
    session = next;
    state = AsyncValue.data(next);
  }
}

void main() {
  Future<ProjectSession> seed(
    WidgetTester tester,
    String name, {
    String? faction,
    String? relationBetween,
  }) async {
    late Directory root;
    late ProjectPackage package;
    late ProjectSession session;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('bible-xproj-$name-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Bible XProj $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      final db = session.database;
      final paths = ProjectPaths(rootDirectory: package.root);
      if (faction != null) {
        await const CreateFactionService().create(
          db,
          projectId: session.manifest.id,
          name: faction,
        );
      }
      if (relationBetween != null) {
        final a = await CreateCharacterService(
          database: db,
          paths: paths,
        ).create(projectId: session.manifest.id, name: '$relationBetween-A');
        final b = await CreateCharacterService(
          database: db,
          paths: paths,
        ).create(projectId: session.manifest.id, name: '$relationBetween-B');
        await CreateRelationService(RelationRepositoryImpl(database: db)).call(
          projectId: session.manifest.id,
          sourceId: a,
          targetId: b,
          type: AssetRelationType.enemyOf,
        );
      }
    });
    return session;
  }

  Future<_SwitchableSessionController> pumpSwitchable(
    WidgetTester tester,
    ProjectSession session,
  ) async {
    final controller = _SwitchableSessionController(session);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [projectSessionProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: ProjectBibleWorkspaceScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets(
    'FACTIONS and RELATIONSHIP MAP drop project A rows after a direct '
    'project A -> project B session switch (BUI-BUG-03)',
    (tester) async {
      final sessionA = await seed(
        tester,
        'A',
        faction: 'Menara A',
        relationBetween: 'ProyekA',
      );
      final sessionB = await seed(tester, 'B');

      final controller = await pumpSwitchable(tester, sessionA);

      // Precondition: project A rows are visible in both sections.
      expect(find.text('FACTIONS'), findsOneWidget);
      expect(find.text('Menara A'), findsOneWidget);
      expect(find.text('ProyekA-A'), findsOneWidget);
      expect(find.text('ProyekA-B'), findsOneWidget);

      // Direct A -> B switch: the production path keeps the same route and
      // rebuilds the session provider with the newly opened project.
      controller.switchTo(sessionB);
      await tester.pumpAndSettle();

      // After the switch the workspace must belong to project B: an empty
      // faction list and an empty relation map, with no project A residue.
      expect(find.text('Belum ada faksi'), findsOneWidget);
      expect(find.text('Belum ada relasi karakter'), findsOneWidget);
      expect(find.text('Menara A'), findsNothing);
      expect(find.text('ProyekA-A'), findsNothing);
      expect(find.text('ProyekA-B'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
