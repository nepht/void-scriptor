import 'package:drift/drift.dart';

class NovelCharacterLinks extends Table {
  TextColumn get linkId => text()();
  TextColumn get projectId => text()();
  TextColumn get novelWorkspaceId => text()();
  TextColumn get characterWorkspaceId => text()();
  TextColumn get characterId => text()();
  TextColumn get linkMode => text()();
  TextColumn get role => text()();
  TextColumn get visibility => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {linkId};
}
