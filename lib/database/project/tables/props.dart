import 'package:drift/drift.dart';

class Props extends Table {
  TextColumn get assetId => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get function => text().withDefault(const Constant(''))();
  BoolColumn get storyCritical =>
      boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {assetId};
}

class PropSpecifications extends Table {
  TextColumn get propId => text()();
  RealColumn get widthCm => real().nullable()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get depthCm => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get material => text().withDefault(const Constant(''))();
  TextColumn get color => text().withDefault(const Constant(''))();
  @override
  Set<Column<Object>> get primaryKey => {propId};
}

class PropStates extends Table {
  TextColumn get id => text()();
  TextColumn get propId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get referenceSetId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
