import 'package:drift/drift.dart';

class ReferenceVersions extends Table {
  TextColumn get id => text()();
  TextColumn get referenceId => text()();
  IntColumn get version => integer()();
  TextColumn get filePath => text()();
  TextColumn get contentHash => text().nullable()();
  TextColumn get changeNote => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CharacterIdentityProfilesV20 extends Table {
  TextColumn get characterId => text()();
  BoolColumn get faceLock => boolean().withDefault(const Constant(true))();
  BoolColumn get hairLock => boolean().withDefault(const Constant(true))();
  BoolColumn get bodyLock => boolean().withDefault(const Constant(true))();
  BoolColumn get colorLock => boolean().withDefault(const Constant(true))();
  BoolColumn get accessoryLock =>
      boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {characterId};
}

class PreservationLocks extends Table {
  TextColumn get id => text()();
  TextColumn get assetId => text()();
  TextColumn get type => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get instruction => text().withDefault(const Constant(''))();
  IntColumn get priority => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
