import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// Regression for the cross-project stale-selection bug observed during the
/// 145.44 repeat journey: the Inspector kept showing a Saga character UUID
/// after switching to another project, until a new selection was made.
void main() {
  test(
    'opening a different project releases the previous project selection',
    () async {
      final root = await Directory.systemTemp.createTemp('void-selreset-');
      final container = ProviderContainer(
        overrides: [
          projectPathsProvider.overrideWithValue(
            ProjectPaths(rootDirectory: root),
          ),
        ],
      );
      try {
        final first = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Saga Copy');
        final second = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Tes Novel');
        final controller = container.read(projectSessionProvider.notifier);
        await controller.open(first.projectId);
        container
            .read(selectionProvider.notifier)
            .select(
              SelectionModel(
                assetId: 'legacy-character-uuid',
                assetType: AssetType.character,
                projectId: first.projectId,
              ),
            );
        expect(
          container.read(selectionProvider)?.assetId,
          'legacy-character-uuid',
        );

        await controller.open(second.projectId);

        expect(
          container.read(selectionProvider),
          isNull,
          reason:
              'a selection from the previous project must not survive a '
              'project switch; the Inspector would render a foreign UUID '
              'against the new project database',
        );
      } finally {
        await container.read(projectSessionProvider.notifier).closeProject();
        container.dispose();
        if (await root.exists()) await root.delete(recursive: true);
      }
    },
  );

  test('closing the active project releases its selection', () async {
    final root = await Directory.systemTemp.createTemp('void-selreset-');
    final container = ProviderContainer(
      overrides: [
        projectPathsProvider.overrideWithValue(
          ProjectPaths(rootDirectory: root),
        ),
      ],
    );
    try {
      final project = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Solo');
      final controller = container.read(projectSessionProvider.notifier);
      await controller.open(project.projectId);
      container
          .read(selectionProvider.notifier)
          .select(
            SelectionModel(
              assetId: 'character-1',
              assetType: AssetType.character,
              projectId: project.projectId,
            ),
          );
      expect(container.read(selectionProvider), isNotNull);

      await controller.closeProject();

      expect(
        container.read(selectionProvider),
        isNull,
        reason:
            'without an active project session no asset selection can be '
            'resolved; the Inspector must fall back to the empty state',
      );
    } finally {
      await container.read(projectSessionProvider.notifier).closeProject();
      container.dispose();
      if (await root.exists()) await root.delete(recursive: true);
    }
  });
}
