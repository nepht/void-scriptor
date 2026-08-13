import 'package:drift/drift.dart';

class PromptTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get target => text()();
  TextColumn get content => text()();
  BoolColumn get builtIn => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}
