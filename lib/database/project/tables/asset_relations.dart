import 'package:drift/drift.dart';

class AssetRelations extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().withDefault(const Constant(''))();
  TextColumn get sourceAssetId => text()();
  TextColumn get targetAssetId => text()();
  TextColumn get relationType => text()();
  TextColumn get relationOrigin =>
      text().withDefault(const Constant('manual'))();
  DateTimeColumn get createdAt => dateTime().withDefault(
    Constant(DateTime.fromMillisecondsSinceEpoch(0)),
  )();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
