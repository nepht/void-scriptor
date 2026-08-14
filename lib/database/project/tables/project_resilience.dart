import 'package:drift/drift.dart';

class ExternalFiles extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get absolutePath => text()();
  TextColumn get contentHash => text().nullable()();
  BoolColumn get available => boolean().withDefault(const Constant(true))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProjectBackups extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get type => text()();
  TextColumn get relativePath => text()();
  IntColumn get schemaVersion => integer()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CacheEntries extends Table {
  TextColumn get key => text()();
  TextColumn get relativePath => text()();
  TextColumn get cacheType => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAccessedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {key};
}

class TrashEntries extends Table {
  TextColumn get id => text()();
  TextColumn get originalPath => text()();
  TextColumn get trashPath => text()();
  TextColumn get entityId => text().nullable()();
  DateTimeColumn get deletedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProjectMigrationHistory extends Table {
  TextColumn get id => text()();
  IntColumn get fromVersion => integer()();
  IntColumn get toVersion => integer()();
  TextColumn get appVersion => text()();
  DateTimeColumn get migratedAt => dateTime()();
  BoolColumn get successful => boolean()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
