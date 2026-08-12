// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_dao.dart';

// ignore_for_file: type=lint
mixin _$AssetDaoMixin on DatabaseAccessor<ProjectDatabase> {
  $AssetsTable get assets => attachedDatabase.assets;
  $AssetTagsTable get assetTags => attachedDatabase.assetTags;
  AssetDaoManager get managers => AssetDaoManager(this);
}

class AssetDaoManager {
  final _$AssetDaoMixin _db;
  AssetDaoManager(this._db);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db.attachedDatabase, _db.assets);
  $$AssetTagsTableTableManager get assetTags =>
      $$AssetTagsTableTableManager(_db.attachedDatabase, _db.assetTags);
}
