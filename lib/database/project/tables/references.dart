import 'package:drift/drift.dart';

class References extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get ownerAssetId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get source => text()();
  TextColumn get name => text()();
  TextColumn get filePath => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  BoolColumn get primaryReference =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get contentHash => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
