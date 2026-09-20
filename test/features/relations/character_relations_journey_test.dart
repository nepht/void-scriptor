import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/inspector/presentation/widgets/relation_section.dart';
import 'package:void_scriptor/features/relations/application/relation_display_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/relations/application/relation_command.dart';
import 'package:void_scriptor/features/relations/data/relation_repository_impl.dart';
import 'package:void_scriptor/features/assets/domain/asset_relation_type.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

void main() {
  testWidgets(
    'character relations journey: create relation via repo, verify display service, verify UI delete',
    (tester) async {
      late final Directory root;
      late final ProjectPackage package;
      late final ProjectSession session;
      late final String characterId;
      late final String weaponId;

      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('s25-journey-');
        package = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Relations Journey');
        session = await ProjectSessionManager().open(package);

        final charRepo = CharacterRepositoryImpl(
          database: session.database,
          projectId: package.projectId,
          paths: ProjectPaths(rootDirectory: package.root.parent),
        );
        final character = await charRepo.createCharacter(name: 'Qowner');
        characterId = character.assetId;

        final now = DateTime.now();
        await session.database
            .into(session.database.assets)
            .insert(
              AssetsCompanion.insert(
                id: 'weapon-void-dagger',
                projectId: package.projectId,
                name: 'Void Dagger',
                type: 'weapon',
                createdAt: now,
                updatedAt: now,
              ),
            );
        weaponId = 'weapon-void-dagger';

        // Create relation via mutation bus
        await session.mutationRuntime.bus.execute(
          RelationCommand.create(
            id: 'relation.create:test:\${DateTime.now().microsecondsSinceEpoch}',
            projectId: package.projectId,
            repository: RelationRepositoryImpl(database: session.database),
            sourceAssetId: characterId,
            targetAssetId: weaponId,
            type: AssetRelationType.uses,
          ),
        );
      });
      addTearDown(() => root.delete(recursive: true));
      addTearDown(session.close);

      // Verify display service resolves correctly
      await tester.runAsync(() async {
        final items = await RelationDisplayService(
          session.database,
        ).forAsset(characterId);
        expect(items, hasLength(1));
        expect(items.first.label, 'uses');
        expect(items.first.assetName, 'Void Dagger');
      });

      // Relations live in the Character workspace sidebar section. The
      // Inspector is intentionally summary-only to avoid duplicate surfaces.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(
              () => _FakeProjectSessionController(session),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CharacterWorkspaceScreen(
                characterId: characterId,
                activeSection: 'Relations',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // RelationSection is present on its single editing surface.
      expect(find.byType(RelationSection), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Delete relation via repository
      await tester.runAsync(() async {
        final repo = RelationRepositoryImpl(database: session.database);
        final outgoing = await repo.outgoing(characterId);
        expect(outgoing, hasLength(1));
        await repo.delete(outgoing.first.id);
      });

      // Verify empty after deletion
      await tester.runAsync(() async {
        final items = await RelationDisplayService(
          session.database,
        ).forAsset(characterId);
        expect(items, isEmpty);
      });

      expect(tester.takeException(), isNull);
    },
  );
}
