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
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

/// Backlog `character-roles-support` phase_one acceptance: "UI handles empty/
/// loading/error states, long names, narrow layouts and enlarged text".
///
/// The narrative assignment card was only exercised at desktop width
/// (1280x900, narrative_assignment_ui_test.dart). These tests pin the two
/// missing boundaries: a narrow 390x844 phone surface and 2.0 text scale —
/// both must render without RenderFlex overflow (tester.takeException).
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
      root = await Directory.systemTemp.createTemp('narr-narrow-$name-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Narrative Narrow $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      final repo = CharacterRepositoryImpl(
        database: session.database,
        projectId: package.projectId,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      );
      final character = await repo.createCharacter(name: 'Qowner');
      characterId = character.assetId;
      final now = DateTime.now();
      await session.database
          .into(session.database.assets)
          .insert(
            AssetsCompanion.insert(
              id: 'novel-long',
              projectId: 'story',
              name: 'A Very Long Novel Title That Must Never Overflow The Card',
              type: 'story',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await session.database
          .into(session.database.stories)
          .insert(
            StoriesCompanion.insert(
              assetId: 'novel-long',
              projectId: 'story',
              title:
                  'A Very Long Novel Title That Must Never Overflow The Card',
            ),
          );
    });
    return (package, session, characterId);
  }

  Future<void> pumpWorkspace(
    WidgetTester tester,
    ProjectPackage package,
    ProjectSession session,
    String characterId, {
    required Size size,
    TextScaler? textScaler,
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: textScaler ?? TextScaler.noScaling),
            child: child!,
          ),
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
    'narrative assignment card renders without overflow at 390x844',
    (tester) async {
      final (package, session, characterId) = await seed(tester, 'narrow');
      await pumpWorkspace(
        tester,
        package,
        session,
        characterId,
        size: const Size(390, 844),
      );

      expect(find.text('Narrative Assignment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );

  testWidgets(
    'narrative assignment card renders without overflow at 2.0 text scale',
    (tester) async {
      final (package, session, characterId) = await seed(tester, 'textscale');
      await pumpWorkspace(
        tester,
        package,
        session,
        characterId,
        size: const Size(1280, 900),
        textScaler: const TextScaler.linear(2.0),
      );

      expect(find.text('Narrative Assignment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    skip: !Platform.isWindows,
  );
}
