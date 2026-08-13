import 'package:drift/drift.dart';

class SceneContinuityChanges extends Table {
  TextColumn get id => text()();
  TextColumn get sceneId => text()();
  TextColumn get targetAssetId => text()();
  TextColumn get changeType => text()();
  TextColumn get beforeState => text().withDefault(const Constant(''))();
  TextColumn get afterState => text().withDefault(const Constant(''))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
