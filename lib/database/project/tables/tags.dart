import 'package:drift/drift.dart';

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AssetTagLinks extends Table {
  TextColumn get assetId => text()();
  TextColumn get tagId => text()();
  @override
  Set<Column<Object>> get primaryKey => {assetId, tagId};
}
