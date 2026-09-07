// Journey proof for step 145.25: a live project session, a character
// selected through the shared selectionProvider (the same provider Explorer
// writes), must resolve through WorkspaceResolver into the live
// CharacterWorkspaceScreen with repository-loaded data. Selection mutation
// (not a constructor override) is the production path under test.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

void main() {
  testWidgets(
    'resolver journey: selectionProvider mutation opens live character workspace',
    (tester) async {
      late final Directory root;
      late final ProjectSession session;
      late final String characterId;
      late final String characterName;

      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('s25-resolver-');
        final package = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Resolver Journey');
        session = await ProjectSessionManager().open(package);

        final repo = CharacterRepositoryImpl(
          database: session.database,
          projectId: package.projectId,
          paths: ProjectPaths(rootDirectory: root.parent),
        );
        final character = await repo.createCharacter(name: 'Qowner');
        characterId = character.assetId;
        characterName = character.displayName;
      });
      addTearDown(() => root.delete(recursive: true));
      addTearDown(session.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(
              () => _FakeProjectSessionController(session),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
        ),
      );
      await tester.pumpAndSettle();

      // Selection starts empty: resolver must show the overview.
      expect(find.text('Novel Workspace'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WorkspaceResolver)),
      );
      expect(container.read(selectionProvider), isNull);

      // Mutate the shared selection provider exactly like Explorer does.
      container
          .read(selectionProvider.notifier)
          .select(
            SelectionModel(
              assetId: characterId,
              assetType: AssetType.character,
              projectId: session.manifest.id,
            ),
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Character Workspace opens through the resolver with live data.
      expect(find.byType(CharacterWorkspaceScreen), findsOneWidget);
      expect(find.text(characterName), findsWidgets);
      expect(find.text('Character Identity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
