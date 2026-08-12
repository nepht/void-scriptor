// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relation_dao.dart';

// ignore_for_file: type=lint
mixin _$RelationDaoMixin on DatabaseAccessor<ProjectDatabase> {
  $AssetRelationsTable get assetRelations => attachedDatabase.assetRelations;
  RelationDaoManager get managers => RelationDaoManager(this);
}

class RelationDaoManager {
  final _$RelationDaoMixin _db;
  RelationDaoManager(this._db);
  $$AssetRelationsTableTableManager get assetRelations =>
      $$AssetRelationsTableTableManager(
        _db.attachedDatabase,
        _db.assetRelations,
      );
}
