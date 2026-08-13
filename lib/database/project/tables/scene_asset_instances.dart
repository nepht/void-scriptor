import 'package:drift/drift.dart';

class SceneAssetInstances extends Table {
  TextColumn get id => text()();
  TextColumn get sceneId => text()();
  TextColumn get assetId => text()();
  TextColumn get assetType => text()();
  TextColumn get stateId => text().nullable()();
  TextColumn get parentInstanceId => text().nullable()();
  TextColumn get contextPriority =>
      text().withDefault(const Constant('normal'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SceneInstanceTransforms extends Table {
  TextColumn get instanceId => text()();
  RealColumn get positionX => real().withDefault(const Constant(0))();
  RealColumn get positionY => real().withDefault(const Constant(0))();
  RealColumn get positionZ => real().withDefault(const Constant(0))();
  RealColumn get rotationX => real().withDefault(const Constant(0))();
  RealColumn get rotationY => real().withDefault(const Constant(0))();
  RealColumn get rotationZ => real().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {instanceId};
}

class SceneInstanceProperties extends Table {
  TextColumn get id => text()();
  TextColumn get instanceId => text()();
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column<Object>> get primaryKey => {id};
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {instanceId, key},
  ];
}

class SceneContinuitySnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get sceneId => text()();
  TextColumn get instanceId => text()();
  TextColumn get snapshotData => text()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
