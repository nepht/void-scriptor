import 'package:drift/drift.dart';

/// Publish records (Step 36.13).
class PublishRecords extends Table {
  TextColumn get id => text()();
  TextColumn get channel => text()();
  TextColumn get version => text()();
  TextColumn get state => text()();
  TextColumn get checksum => text()();
  TextColumn get changelog => text().withDefault(const Constant(''))();
  DateTimeColumn get publishedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
