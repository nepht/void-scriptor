import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';

void main() {
  late ProviderContainer container;
  late SelectionController controller;
  setUp(() {
    container = ProviderContainer();
    controller = container.read(selectionProvider.notifier);
  });
  tearDown(() => container.dispose());

  test('switching domains restores the last selected asset, not the first', () {
    controller.select(
      const SelectionModel(
        assetId: 'novel-2',
        assetType: AssetType.story,
        projectId: 'p1',
      ),
    );
    controller.selectWorkspace(
      projectId: 'p1',
      type: AssetType.character,
      availableAssetIds: ['character-1', 'character-2'],
    );
    controller.select(
      const SelectionModel(
        assetId: 'character-2',
        assetType: AssetType.character,
        projectId: 'p1',
      ),
    );
    controller.selectWorkspace(
      projectId: 'p1',
      type: AssetType.environment,
      availableAssetIds: ['world-1'],
    );
    controller.selectWorkspace(
      projectId: 'p1',
      type: AssetType.story,
      availableAssetIds: ['novel-1', 'novel-2'],
    );
    expect(container.read(selectionProvider)?.assetId, 'novel-2');
    controller.selectWorkspace(
      projectId: 'p1',
      type: AssetType.character,
      availableAssetIds: ['character-1', 'character-2'],
    );
    expect(container.read(selectionProvider)?.assetId, 'character-2');
  });

  test('remembered ids never cross project boundaries', () {
    controller.select(
      const SelectionModel(
        assetId: 'second',
        assetType: AssetType.story,
        projectId: 'p1',
      ),
    );
    controller.selectWorkspace(
      projectId: 'p2',
      type: AssetType.story,
      availableAssetIds: ['first', 'second'],
    );
    expect(container.read(selectionProvider)?.assetId, 'first');
    expect(container.read(selectionProvider)?.projectId, 'p2');
  });

  test(
    'deleted selections fall back safely and empty workspaces clear selection',
    () {
      controller.select(
        const SelectionModel(
          assetId: 'deleted',
          assetType: AssetType.story,
          projectId: 'p1',
        ),
      );
      controller.selectWorkspace(
        projectId: 'p1',
        type: AssetType.story,
        availableAssetIds: ['remaining'],
      );
      expect(container.read(selectionProvider)?.assetId, 'remaining');
      controller.selectWorkspace(
        projectId: 'p1',
        type: AssetType.story,
        availableAssetIds: [],
      );
      expect(container.read(selectionProvider), isNull);
    },
  );
}
