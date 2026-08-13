import 'package:drift/drift.dart';

class AssetCollections extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get query => text().nullable()();
  BoolColumn get isSmart => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AssetCollectionItems extends Table {
  TextColumn get collectionId => text()();
  TextColumn get assetId => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {collectionId, assetId};
}
