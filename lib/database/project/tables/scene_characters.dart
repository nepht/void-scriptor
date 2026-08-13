import 'package:drift/drift.dart';

class SceneCharacters extends Table {
  TextColumn get id => text()();
  TextColumn get sceneId => text()();
  TextColumn get characterId => text()();
  TextColumn get modeId => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('participant'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
