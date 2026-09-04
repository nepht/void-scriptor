import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/character/application/create_character_service.dart';
import 'package:void_scriptor/features/character/presentation/character_controller.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

void main() {
  late Directory root;
  late String projectId;
  late String characterId;
  late ProviderContainer container;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('void-recovery-unit-');
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Recovery Unit');
    projectId = package.projectId;
    container = ProviderContainer(
      overrides: [
        projectPathsProvider.overrideWithValue(
          ProjectPaths(rootDirectory: root),
        ),
      ],
    );
    await container.read(projectSessionProvider.future);
    await container
        .read(projectSessionProvider.notifier)
        .openProject(projectId);
    final session = container.read(projectSessionProvider).value!;
    characterId = await CreateCharacterService(
      database: session.database,
      paths: ProjectPaths(rootDirectory: root),
    ).create(projectId: projectId, name: 'Arka');
    // Mount the reactive recovery, mirroring the wired shell.
    container.listen(explorerCatalogRecoveryProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    try {
      await root.delete(recursive: true);
    } catch (_) {}
  });

  test(
    'restores the remembered selection when the focused catalog arrives',
    () async {
      final controller = container.read(selectionProvider.notifier);
      // Session memory: the user last selected the character here.
      controller.select(
        SelectionModel(
          assetId: characterId,
          assetType: AssetType.character,
          projectId: projectId,
        ),
      );
      // Leave for the novel workspace...
      controller.selectWorkspace(
        projectId: projectId,
        type: AssetType.story,
        availableAssetIds: const ['novel-1'],
      );
      expect(container.read(selectionProvider)?.assetType, AssetType.story);
      // ...then navigate back while the character catalog is loading.
      container.invalidate(characterControllerProvider(projectId));
      controller.focusWorkspace(
        projectId: projectId,
        type: AssetType.character,
      );
      expect(container.read(selectionProvider), isNull);

      // The catalog finishes loading; the remembered character must be
      // restored without another user tap.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(container.read(selectionProvider)?.assetType, AssetType.character);
      expect(container.read(selectionProvider)?.assetId, characterId);
    },
  );

  test('a late catalog completion never overrides the user pick', () async {
    final controller = container.read(selectionProvider.notifier);
    // Navigate to the novel workspace while its catalog is loading.
    container.invalidate(storyExplorerProvider(projectId));
    controller.focusWorkspace(projectId: projectId, type: AssetType.story);

    // The user picks the character meanwhile.
    controller.select(
      SelectionModel(
        assetId: characterId,
        assetType: AssetType.character,
        projectId: projectId,
      ),
    );

    // The story catalog completes; it must not steal the selection.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(container.read(selectionProvider)?.assetId, characterId);
    expect(container.read(selectionProvider)?.assetType, AssetType.character);
  });
}
