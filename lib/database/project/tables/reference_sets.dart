import 'package:drift/drift.dart';

class ReferenceSets extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get ownerAssetId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get defaultSet => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ReferenceSetItems extends Table {
  TextColumn get referenceSetId => text()();
  TextColumn get referenceId => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {referenceSetId, referenceId};
}
