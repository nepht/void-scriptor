import 'package:drift/drift.dart';

/// Metaverse worlds (Step 42.13).
class MetaverseWorlds extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Metaverse zones (Step 42.14).
class MetaverseZones extends Table {
  TextColumn get id => text()();
  TextColumn get worldId => text()();
  TextColumn get regionId => text()();
  TextColumn get name => text()();
  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get z => real()();

  @override
  Set<Column> get primaryKey => {id};
}
