import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/assets/application/asset_pagination.dart';
import 'package:void_scriptor/features/assets/domain/asset_search_query.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';

void main() {
  List<SearchableAsset> assets(int count) => List.generate(
    count,
    (i) => SearchableAsset(
      id: 'asset-$i',
      projectId: 'project-1',
      name: 'Asset $i',
      type: AssetType.character,
    ),
  );

  test('asset pagination uses page size 80 and grows on loadMore', () {
    final controller = AssetPaginationController(source: assets(200));

    expect(AssetPaginationController.pageSize, 80);
    expect(controller.visibleCount, 80);
    expect(controller.hasMore, isTrue);
    expect(controller.items.length, 80);

    controller.loadMore();
    expect(controller.visibleCount, 160);
    expect(controller.hasMore, isTrue);

    controller.loadMore();
    expect(controller.visibleCount, 200);
    expect(controller.hasMore, isFalse);
  });

  test('loadMore stops at source length without overshoot', () {
    final controller = AssetPaginationController(source: assets(10));
    expect(controller.visibleCount, 10);
    expect(controller.hasMore, isFalse);

    controller.loadMore();
    expect(controller.visibleCount, 10);
  });

  test('replacing the source resets pagination to the first page', () {
    final controller = AssetPaginationController(source: assets(200));
    controller.loadMore();
    controller.loadMore();
    expect(controller.visibleCount, 200);

    controller.replaceSource(assets(300));
    expect(controller.visibleCount, 80);
    expect(controller.hasMore, isTrue);
  });

  test('empty source reports no items and no more pages', () {
    final controller = AssetPaginationController(source: const []);
    expect(controller.items, isEmpty);
    expect(controller.hasMore, isFalse);
  });
}
