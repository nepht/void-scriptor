import 'package:drift/drift.dart';

class StoryScenes extends Table {
  TextColumn get id => text()();
  TextColumn get storyId => text()();
  TextColumn get chapterId => text()();
  TextColumn get title => text()();
  TextColumn get summary => text().withDefault(const Constant(''))();
  TextColumn get sceneType => text().withDefault(const Constant('standard'))();
  IntColumn get sceneNumber => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  RealColumn get estimatedDurationSeconds => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
