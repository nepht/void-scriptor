import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/assets/application/asset_repository.dart';
import 'package:void_scriptor/features/assets/domain/asset_search_query.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';

void main() {
  test('repository normalizes and replaces tags without duplicates', () async {
    final repository = InMemoryAssetRepository();
    await repository.saveAsset(
      const SearchableAsset(
        id: 'a',
        projectId: 'p',
        name: 'Void',
        type: AssetType.character,
      ),
    );
    await repository.replaceTags('a', [' Void ', 'void', 'COMBAT']);
    expect(await repository.tagsFor('a'), ['void', 'combat']);
  });

  test('repository bulk tags multiple assets atomically', () async {
    final repository = InMemoryAssetRepository();
    await repository.saveAsset(
      const SearchableAsset(
        id: 'a',
        projectId: 'p',
        name: 'A',
        type: AssetType.character,
      ),
    );
    await repository.saveAsset(
      const SearchableAsset(
        id: 'b',
        projectId: 'p',
        name: 'B',
        type: AssetType.weapon,
      ),
    );
    await repository.addTagToAssets(['a', 'b'], ' Void ');
    expect(await repository.tagsFor('a'), ['void']);
    expect(await repository.tagsFor('b'), ['void']);
  });

  test('favorite and opened state are persisted in repository model', () async {
    final repository = InMemoryAssetRepository();
    await repository.saveAsset(
      const SearchableAsset(
        id: 'a',
        projectId: 'p',
        name: 'A',
        type: AssetType.character,
      ),
    );
    await repository.setFavorite('a', true);
    await repository.markOpened('a', DateTime.utc(2026, 2, 3));
    final asset = await repository.getAsset('a');
    expect(asset?.favorite, isTrue);
    expect(asset?.lastOpenedAt, DateTime.utc(2026, 2, 3));
  });

  test('collection can contain assets and smart query is preserved', () async {
    final repository = InMemoryAssetRepository();
    await repository.createCollection(
      const AssetCollectionModel(
        id: 'c',
        projectId: 'p',
        name: 'Void Weapons',
        isSmart: true,
        query: 'type:weapon tag:void',
      ),
    );
    await repository.addToCollection('c', 'weapon-1');
    expect((await repository.getCollection('c'))?.assetIds, ['weapon-1']);
    expect(
      (await repository.getCollection('c'))?.query,
      'type:weapon tag:void',
    );
  });
}
