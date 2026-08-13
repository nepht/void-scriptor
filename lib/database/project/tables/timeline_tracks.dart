import 'package:drift/drift.dart';

class TimelineTracks extends Table {
  TextColumn get id => text()();
  TextColumn get timelineId => text()();
  TextColumn get trackType => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get muted => boolean().withDefault(const Constant(false))();
  BoolColumn get locked => boolean().withDefault(const Constant(false))();
  BoolColumn get visible => boolean().withDefault(const Constant(true))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
