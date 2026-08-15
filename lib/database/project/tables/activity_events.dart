import 'package:drift/drift.dart';

/// Collaboration activity events (Step 29.15).
class ActivityEvents extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get actorId => text()();
  TextColumn get kind => text()();
  TextColumn get payload => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
