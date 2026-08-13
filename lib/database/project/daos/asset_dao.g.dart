// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_dao.dart';

// ignore_for_file: type=lint
mixin _$AssetDaoMixin on DatabaseAccessor<ProjectDatabase> {
  $AssetsTable get assets => attachedDatabase.assets;
  $AssetTagsTable get assetTags => attachedDatabase.assetTags;
  $AssetRelationsTable get assetRelations => attachedDatabase.assetRelations;
  $TagsTable get tags => attachedDatabase.tags;
  $AssetTagLinksTable get assetTagLinks => attachedDatabase.assetTagLinks;
  $AssetCollectionsTable get assetCollections =>
      attachedDatabase.assetCollections;
  $AssetCollectionItemsTable get assetCollectionItems =>
      attachedDatabase.assetCollectionItems;
  AssetDaoManager get managers => AssetDaoManager(this);
}

class AssetDaoManager {
  final _$AssetDaoMixin _db;
  AssetDaoManager(this._db);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db.attachedDatabase, _db.assets);
  $$AssetTagsTableTableManager get assetTags =>
      $$AssetTagsTableTableManager(_db.attachedDatabase, _db.assetTags);
  $$AssetRelationsTableTableManager get assetRelations =>
      $$AssetRelationsTableTableManager(
        _db.attachedDatabase,
        _db.assetRelations,
      );
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$AssetTagLinksTableTableManager get assetTagLinks =>
      $$AssetTagLinksTableTableManager(_db.attachedDatabase, _db.assetTagLinks);
  $$AssetCollectionsTableTableManager get assetCollections =>
      $$AssetCollectionsTableTableManager(
        _db.attachedDatabase,
        _db.assetCollections,
      );
  $$AssetCollectionItemsTableTableManager get assetCollectionItems =>
      $$AssetCollectionItemsTableTableManager(
        _db.attachedDatabase,
        _db.assetCollectionItems,
      );
}
