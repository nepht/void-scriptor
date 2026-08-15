import 'package:drift/drift.dart';

/// Persists unresolved sync conflicts (Step 29.9).
class SyncConflicts extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get entityKey => text()();
  TextColumn get baseJson => text()();
  TextColumn get oursJson => text()();
  TextColumn get theirsJson => text()();
  TextColumn get resolution => text().nullable()(); // keepOurs / keepTheirs / manual
  DateTimeColumn get createdAt => dateTime()();
}
