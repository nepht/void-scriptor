import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/assets/application/drift_asset_repository.dart';
import 'package:void_scriptor/features/assets/application/asset_repository.dart';
import 'package:void_scriptor/features/assets/domain/asset_search_query.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';

void main() {
  test(
    'Drift repository round-trips asset favorite, recent, tags, and collection',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's19-drift-repository-',
      );
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final dbPath = (await paths.database('p')).path;
      await ProjectDatabaseService().create(dbPath);
      final database = await ProjectDatabaseService().open(dbPath);
      addTearDown(database.close);
      final repository = DriftAssetRepository(database);
      await repository.saveAsset(
        const SearchableAsset(
          id: 'weapon',
          projectId: 'p',
          name: 'Void Sword',
          type: AssetType.weapon,
        ),
      );
      await repository.replaceTags('weapon', ['VOID', 'combat']);
      await repository.setFavorite('weapon', true);
      await repository.markOpened('weapon', DateTime.utc(2026, 3, 4));
      await repository.createCollection(
        const AssetCollectionModel(id: 'c', projectId: 'p', name: 'Favorites'),
      );
      await repository.addToCollection('c', 'weapon');
      final asset = await repository.getAsset('weapon');
      final collection = await repository.getCollection('c');
      expect(asset?.favorite, isTrue);
      expect(asset?.tags, {'void', 'combat'});
      expect(asset?.lastOpenedAt?.toUtc(), DateTime.utc(2026, 3, 4));
      expect(collection?.assetIds, ['weapon']);
    },
  );
}
