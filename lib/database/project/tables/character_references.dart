import 'package:drift/drift.dart';

class CharacterReferences extends Table {
  TextColumn get id => text()();
  TextColumn get characterId => text()();
  TextColumn get type => text()();
  TextColumn get filePath => text()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  BoolColumn get primaryReference =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AssetRelations extends Table {
  TextColumn get id => text()();
  TextColumn get sourceAssetId => text()();
  TextColumn get targetAssetId => text()();
  TextColumn get relationType => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
