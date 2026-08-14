import 'dart:io';

import 'package:drift/drift.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/assets/application/asset_search_service.dart';
import 'package:void_scriptor/features/assets/domain/asset_search_query.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';

void main() {
  test('parser understands type tag and favorite syntax', () {
    final query = const SearchQueryParser().parse(
      'type:weapon tag:void favorite:true void sword',
    );
    expect(query.types, {AssetType.weapon});
    expect(query.tags, {'void'});
    expect(query.favoriteOnly, isTrue);
    expect(query.text, 'void sword');
  });

  test('parser normalizes tag casing and ignores unknown fields', () {
    final query = const SearchQueryParser().parse('tag: VOID foo:bar');
    expect(query.tags, {'void'});
    expect(query.text, 'foo:bar');
  });

  test('in-memory search ranks exact name before contains and tags', () async {
    final service = InMemoryAssetSearchService(const [
      SearchableAsset(
        id: 'tagged',
        projectId: 'p1',
        name: 'Blade Archive',
        type: AssetType.weapon,
        tags: {'void'},
      ),
      SearchableAsset(
        id: 'contains',
        projectId: 'p1',
        name: 'Void Sword Reference',
        type: AssetType.weapon,
      ),
      SearchableAsset(
        id: 'exact',
        projectId: 'p1',
        name: 'Void Sword',
        type: AssetType.weapon,
      ),
    ]);
    final results = await service.search(
      const AssetSearchQuery(text: 'void sword'),
    );
    expect(results.map((result) => result.asset.id).toList(), [
      'exact',
      'contains',
      'tagged',
    ]);
  });

  test('asset metadata and normalized tags survive database restart', () async {
    final root = await Directory.systemTemp.createTemp('s19-assets-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final dbPath = (await paths.database('p1')).path;
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final first = await service.open(dbPath);
    await first
        .into(first.assets)
        .insert(
          AssetsCompanion.insert(
            id: 'asset-1',
            projectId: 'p1',
            name: 'Void Sword',
            type: 'weapon',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            favorite: const Value(true),
            lastOpenedAt: Value(DateTime.utc(2026, 1, 2)),
          ),
        );
    await first
        .into(first.tags)
        .insert(
          TagsCompanion.insert(id: 'tag-void', projectId: 'p1', name: 'void'),
        );
    await first
        .into(first.assetTagLinks)
        .insert(
          AssetTagLinksCompanion.insert(assetId: 'asset-1', tagId: 'tag-void'),
        );
    await first.close();
    final second = await service.open(dbPath);
    addTearDown(second.close);
    final asset = await (second.select(
      second.assets,
    )..where((row) => row.id.equals('asset-1'))).getSingle();
    final tags = await (second.select(
      second.tags,
    )..where((row) => row.id.equals('tag-void'))).getSingle();
    expect(asset.favorite, isTrue);
    expect(asset.lastOpenedAt?.toUtc(), DateTime.utc(2026, 1, 2));
    expect(tags.name, 'void');
    expect(second.schemaVersion, 35);
  });
}
