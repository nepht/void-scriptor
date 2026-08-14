import 'package:drift/drift.dart';

class VfxAssets extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get visualBehavior => text().withDefault(const Constant(''))();
  TextColumn get colorPalette => text().withDefault(const Constant(''))();
  @override
  Set<Column<Object>> get primaryKey => {assetId};
}

class VfxBehaviorProfiles extends Table {
  TextColumn get vfxId => text()();
  TextColumn get originBehavior => text().withDefault(const Constant(''))();
  TextColumn get movementBehavior => text().withDefault(const Constant(''))();
  TextColumn get dissipationBehavior =>
      text().withDefault(const Constant(''))();
  TextColumn get environmentalInteraction =>
      text().withDefault(const Constant(''))();
  RealColumn get defaultDurationSeconds => real().nullable()();
  BoolColumn get emitsLight => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {vfxId};
}

class VfxStates extends Table {
  TextColumn get id => text()();
  TextColumn get vfxId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get referenceSetId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class VfxTimelineClips extends Table {
  TextColumn get id => text()();
  TextColumn get sceneId => text()();
  TextColumn get vfxAssetId => text()();
  RealColumn get startSeconds => real()();
  RealColumn get durationSeconds => real()();
  TextColumn get stateId => text().nullable()();
  TextColumn get attachedInstanceId => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class VfxKeyframes extends Table {
  TextColumn get id => text()();
  TextColumn get clipId => text()();
  RealColumn get timeSeconds => real()();
  TextColumn get property => text()();
  RealColumn get value => real()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
