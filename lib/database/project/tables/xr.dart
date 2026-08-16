import 'package:drift/drift.dart';

/// XR sessions (Step 41.13).
class XrSessions extends Table {
  TextColumn get id => text()();
  TextColumn get state => text()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Spatial anchors (Step 41.14).
class SpatialAnchors extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get contentId => text()();
  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get z => real()();

  @override
  Set<Column> get primaryKey => {id};
}
