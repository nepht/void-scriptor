import 'package:drift/drift.dart';

/// Studio members (Step 37.15).
class StudioMembers extends Table {
  TextColumn get userId => text()();
  TextColumn get studioId => text()();
  TextColumn get role => text()();
  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {userId};
}

/// Audit events (Step 37.15).
class AuditEvents extends Table {
  TextColumn get id => text()();
  TextColumn get actor => text()();
  TextColumn get action => text()();
  TextColumn get target => text()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
