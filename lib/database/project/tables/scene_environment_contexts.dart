import 'package:drift/drift.dart';

class SceneEnvironmentContexts extends Table {
  TextColumn get sceneId => text()();
  TextColumn get environmentId => text()();
  TextColumn get zoneId => text().nullable()();
  TextColumn get weatherProfileId => text().nullable()();
  TextColumn get lightingProfileId => text().nullable()();
  TextColumn get continuityStateId => text().nullable()();
  TextColumn get timePreset => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {sceneId};
}
