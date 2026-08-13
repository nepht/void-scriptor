import 'package:drift/drift.dart';

class StoryChapters extends Table {
  TextColumn get id => text()();
  TextColumn get storyId => text()();
  TextColumn get arcId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get summary => text().withDefault(const Constant(''))();
  IntColumn get chapterNumber => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
