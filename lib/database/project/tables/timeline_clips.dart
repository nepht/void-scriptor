import 'package:drift/drift.dart';

class TimelineClips extends Table {
  TextColumn get id => text()();
  TextColumn get timelineId => text()();
  TextColumn get trackId => text()();
  TextColumn get clipType => text()();
  TextColumn get label => text()();
  RealColumn get startSeconds => real()();
  RealColumn get durationSeconds => real()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
