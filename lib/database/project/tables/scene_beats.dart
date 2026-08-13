import 'package:drift/drift.dart';

class SceneBeats extends Table {
  TextColumn get id => text()();
  TextColumn get sceneId => text()();
  TextColumn get beatType => text().withDefault(const Constant('action'))();
  TextColumn get content => text()();
  RealColumn get startSecond => real().nullable()();
  RealColumn get durationSeconds => real().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
