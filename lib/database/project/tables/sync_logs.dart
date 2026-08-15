import 'package:drift/drift.dart';

/// Records cloud sync operations (Step 29.6).
class SyncLogs extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get kind => text()(); // pull / push / sync
  TextColumn get status => text()(); // syncing / synced / error / conflict
  TextColumn get message => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
}
