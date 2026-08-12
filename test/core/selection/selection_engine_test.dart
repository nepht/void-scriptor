import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';

void main() {
  test('selection engine selects and clears a typed asset', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(selectionProvider.notifier);

    controller.select(
      const SelectionModel(
        assetId: 'qowner-1',
        assetType: AssetType.character,
        projectId: 'project-1',
      ),
    );
    expect(container.read(selectionProvider)?.assetId, 'qowner-1');
    expect(container.read(selectionProvider)?.assetType, AssetType.character);

    controller.clear();
    expect(container.read(selectionProvider), isNull);
  });

  test('selection model equality supports stable rebuild decisions', () {
    const first = SelectionModel(
      assetId: 'weapon-1',
      assetType: AssetType.weapon,
      projectId: 'project-1',
    );
    const second = SelectionModel(
      assetId: 'weapon-1',
      assetType: AssetType.weapon,
      projectId: 'project-1',
    );
    expect(first, second);
  });
}
