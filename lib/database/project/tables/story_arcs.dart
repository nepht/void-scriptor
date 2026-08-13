import 'package:drift/drift.dart';

class StoryArcs extends Table {
  TextColumn get id => text()();
  TextColumn get storyId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
