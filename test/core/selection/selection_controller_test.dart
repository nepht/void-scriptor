import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';

void main() {
  test('selection controller selects, replaces, and clears an asset', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    const first = SelectionModel(
      assetId: 'asset-1',
      assetType: AssetType.character,
      projectId: 'project-1',
    );
    const second = SelectionModel(
      assetId: 'asset-2',
      assetType: AssetType.weapon,
      projectId: 'project-1',
    );
    final controller = container.read(selectionProvider.notifier);

    expect(container.read(selectionProvider), isNull);
    controller.select(first);
    expect(container.read(selectionProvider), first);
    controller.select(second);
    expect(container.read(selectionProvider), second);
    controller.clear();
    expect(container.read(selectionProvider), isNull);
  });
}
