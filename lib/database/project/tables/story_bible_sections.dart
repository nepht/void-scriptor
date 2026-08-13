import 'package:drift/drift.dart';

class StoryBibleSections extends Table {
  TextColumn get id => text()();
  TextColumn get storyId => text()();
  TextColumn get sectionType => text()();
  TextColumn get title => text()();
  TextColumn get content => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
