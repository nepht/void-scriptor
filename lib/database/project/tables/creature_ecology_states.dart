import 'package:drift/drift.dart';

class CreatureEcologyStates extends Table {
  TextColumn get creatureId => text()();
  TextColumn get speciesId => text()();
  TextColumn get genomeJson => text()();
  TextColumn get phenotypeJson => text()();
  TextColumn get needsJson => text()();
  TextColumn get lineageId => text().nullable()();
  IntColumn get simulationTick => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {creatureId};
}
