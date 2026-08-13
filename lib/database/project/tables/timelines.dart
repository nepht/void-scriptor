import 'package:drift/drift.dart';

class Timelines extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get sceneId => text()();
  RealColumn get durationSeconds => real()();
  IntColumn get frameRate => integer().withDefault(const Constant(30))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
