import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/assets/domain/asset_relation_type.dart';
import 'package:void_scriptor/features/bible/presentation/project_bible_workspace_screen.dart';
import 'package:void_scriptor/features/character/application/create_character_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/relations/application/create_relation_service.dart';
import 'package:void_scriptor/features/relations/data/relation_repository_impl.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;

  @override
  Future<ProjectSession?> build() async => session;
}

/// Step 145.27 Core Worldbuilding Reduction - Relationship Map UI slice.
/// The Project Bible workspace must expose a RELATIONSHIP MAP section that
/// reads the live session and renders character-to-character relations with
/// resolved names instead of raw ids.
void main() {
  Future<ProjectSession> seed(WidgetTester tester, String name) async {
    late Directory root;
    late ProjectPackage package;
    late ProjectSession session;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('relmap-ui-$name-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'RelMap UI $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
    });
    return session;
  }

  Future<void> pumpBible(
    WidgetTester tester,
    ProjectSession session, {
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
        child: const MaterialApp(home: ProjectBibleWorkspaceScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('RELATIONSHIP MAP renders resolved relation rows from the live session', (tester) async {
    final session = await seed(tester, 'resolve');
    late ProjectDatabase db;
    await tester.runAsync(() async {
      db = session.database;
      final paths = ProjectPaths(rootDirectory: session.package.root);
      final raka = await CreateCharacterService(
        database: db,
        paths: paths,
      ).create(projectId: session.manifest.id, name: 'Raka');
      final sinta = await CreateCharacterService(
        database: db,
        paths: paths,
      ).create(projectId: session.manifest.id, name: 'Sinta');
      await CreateRelationService(
        RelationRepositoryImpl(database: db),
      ).call(
        projectId: session.manifest.id,
        sourceId: raka,
        targetId: sinta,
        type: AssetRelationType.enemyOf,
      );
    });

    await pumpBible(tester, session);

    expect(find.text('RELATIONSHIP MAP'), findsOneWidget);
    expect(find.text('Raka'), findsOneWidget);
    expect(find.text('Sinta'), findsOneWidget);
    expect(find.text('enemy_of'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RELATIONSHIP MAP shows an empty hint when no relations exist', (tester) async {
    final session = await seed(tester, 'empty');

    await pumpBible(tester, session);

    expect(find.text('RELATIONSHIP MAP'), findsOneWidget);
    expect(find.text('Belum ada relasi karakter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
