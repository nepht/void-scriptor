import 'package:drift/drift.dart';

class Wardrobes extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get primaryMaterial => text().withDefault(const Constant(''))();
  TextColumn get fabric => text().withDefault(const Constant(''))();
  TextColumn get fit => text().withDefault(const Constant(''))();
  TextColumn get style => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {assetId};
}
